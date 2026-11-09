import json
import psutil
import os
import redis
from datetime import datetime, timezone
from fastapi import FastAPI, HTTPException, Path
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse
from reviews_service.db import get_connection, ping

app = FastAPI(
    title="Reviews Service",
    description="Reviews/ratings de películas por usuario (backend Postgres)",
)

_start_time = datetime.now(timezone.utc)


class HealthResponse(BaseModel):
    status: str
    cpu_percent: float
    timestamp: str
    uptime: float
    db: str
    redis: str


class Review(BaseModel):
    id: int
    movie_id: int
    movie_title: str
    reviewer_id: int
    reviewer_username: str
    score: float
    comment: str | None = None
    created_at: str


class MovieReview(BaseModel):
    id: int
    reviewer_id: int
    reviewer_username: str
    score: float
    comment: str | None = None
    created_at: str

class ReviewCreate(BaseModel):
    reviewer_id: int
    score: float = Field(..., ge=0, le=10)
    comment: str | None = None


def _to_str(value) -> str:
    return value.isoformat() if not isinstance(value, str) else value


def _review_from_row(row) -> Review:
    return Review(
        id=row["id"],
        movie_id=row["movie_id"],
        movie_title=row["movie_title"],
        reviewer_id=row["reviewer_id"],
        reviewer_username=row["reviewer_username"],
        score=float(row["score"]),
        comment=row["comment"],
        created_at=_to_str(row["created_at"]),
    )


def _movie_review_from_row(row) -> MovieReview:
    return MovieReview(
        id=row["id"],
        reviewer_id=row["reviewer_id"],
        reviewer_username=row["reviewer_username"],
        score=float(row["score"]),
        comment=row["comment"],
        created_at=_to_str(row["created_at"]),
    )


REVIEW_SELECT = """
    SELECT
        r.id AS id,
        r.movie_id AS movie_id,
        m.title AS movie_title,
        r.reviewer_id AS reviewer_id,
        re.username AS reviewer_username,
        r.score AS score,
        r.comment AS comment,
        r.created_at AS created_at
    FROM ratings r
    JOIN movies m ON m.id = r.movie_id
    JOIN reviewers re ON re.id = r.reviewer_id
"""

MOVIE_REVIEW_SELECT = """
    SELECT
        r.id AS id,
        r.reviewer_id AS reviewer_id,
        re.username AS reviewer_username,
        r.score AS score,
        r.comment AS comment,
        r.created_at AS created_at
    FROM ratings r
    JOIN reviewers re ON re.id = r.reviewer_id
"""


@app.get("/")
async def root():
    return {"service": "reviews", "message": "Hello World"}


@app.get(
    "/health",
    summary="Estado de salud del servicio",
    response_model=HealthResponse,
    responses={503: {"model": HealthResponse, "description": "Dependencia crítica caída"}},
)
def health():
    uptime = (datetime.now(timezone.utc) - _start_time).total_seconds()
    db_ok = ping()
    redis_client = redis.Redis.from_url(
        os.getenv("REDIS_URL", "redis://redis:6379/0")
    )
    try:
        redis_client.ping()
        redis_status = "ok"
    except redis.RedisError:
        redis_status = "down"
    body = HealthResponse(
        status="ok" if db_ok else "down",
        timestamp=datetime.now(timezone.utc).isoformat(),
        cpu_percent=psutil.cpu_percent(),
        uptime=uptime,
        db="ok" if db_ok else "down",
        redis=redis_status,
    )
    if not db_ok:
        return JSONResponse(status_code=503, content=body.model_dump())
    return body

@app.post(
    "/movies/{movie_id}/reviews",
    status_code=201,
)
async def create_review(
    movie_id: int,
    review: ReviewCreate,
):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM movies WHERE id = %s", (movie_id,))
            if cur.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail=f"Movie {movie_id} not found",
            )
            cur.execute(
                "SELECT 1 FROM reviewers WHERE id = %s",
                (review.reviewer_id,),
            )
            if cur.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail=f"User {review.reviewer_id} not found",
                )
            cur.execute(
                """
                SELECT 1
                FROM ratings
                WHERE movie_id = %s AND reviewer_id = %s
                """,
                (movie_id, review.reviewer_id),
            )
            if cur.fetchone() is not None:
                raise HTTPException(
                    status_code=409,
                    detail="User already reviewed this movie",
                )
            cur.execute(
                """
                INSERT INTO ratings (movie_id, reviewer_id, score, comment)
                VALUES (%s, %s, %s, %s)
                RETURNING id, created_at
                """,
                (
                    movie_id,
                    review.reviewer_id,
                    review.score,
                    review.comment,
                ),
            )
            created = cur.fetchone()

            event_payload = {
                "rating_id": created["id"],
                "movie_id": movie_id,
                "reviewer_id": review.reviewer_id,
                "score": review.score,
                "comment": review.comment,
                "created_at": created["created_at"].isoformat(),
            }

            cur.execute(
                """
                INSERT INTO outbox (event_type, aggregate_id, payload)
                VALUES (%s, %s, %s::jsonb)
                """,
                (
                    "ReviewCreated",
                    created["id"],
                    json.dumps(event_payload),
                ),
            )

            return {
                "id": created["id"],
                "movie_id": movie_id,
                "reviewer_id": review.reviewer_id,
                "score": review.score,
                "comment": review.comment,
                "created_at": created["created_at"].isoformat(),
            }

@app.get(
    "/movies/{movie_id}/reviews",
    response_model=list[MovieReview],
    summary="Reviews de una película",
    description="Devuelve todas las reviews/ratings de una película dado su ID.",
)
async def movie_reviews(
    movie_id: int = Path(..., ge=1, description="ID de la película"),
):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM movies WHERE id = %s", (movie_id,))
            if cur.fetchone() is None:
                raise HTTPException(status_code=404, detail=f"Movie {movie_id} not found")

            cur.execute(
                MOVIE_REVIEW_SELECT + " WHERE r.movie_id = %s ORDER BY r.score DESC, r.id",
                (movie_id,),
            )
            return [_movie_review_from_row(r) for r in cur.fetchall()]


@app.get(
    "/reviews/{review_id}",
    response_model=Review,
    summary="Review por ID",
    description="Devuelve una review/rating dado su ID.",
)
async def get_review(
    review_id: int = Path(..., ge=1, description="ID de la review"),
):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(REVIEW_SELECT + " WHERE r.id = %s", (review_id,))
            row = cur.fetchone()
            if row is None:
                raise HTTPException(status_code=404, detail=f"Review {review_id} not found")
            return _review_from_row(row)


@app.get(
    "/users/{user_id}/reviews",
    response_model=list[Review],
    summary="Reviews de un usuario",
    description="Devuelve todas las reviews/ratings realizadas por un reviewer dado su ID.",
)
async def user_reviews(
    user_id: int = Path(..., ge=1, description="ID del usuario/reviewer"),
):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM reviewers WHERE id = %s", (user_id,))
            if cur.fetchone() is None:
                raise HTTPException(status_code=404, detail=f"User {user_id} not found")

            cur.execute(
                REVIEW_SELECT + " WHERE r.reviewer_id = %s ORDER BY r.created_at, r.id",
                (user_id,),
            )
            return [_review_from_row(r) for r in cur.fetchall()]