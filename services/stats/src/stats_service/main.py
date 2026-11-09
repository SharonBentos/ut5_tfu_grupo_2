import random
import time

import psutil
from datetime import datetime, timezone
from fastapi import FastAPI, HTTPException, Path, Request, Response
from pydantic import BaseModel
from fastapi.responses import JSONResponse
from stats_service.calc import compute_stats
from stats_service.db import get_connection, ping
from stats_service import cache, jobs 
from stats_service.soap import router as soap_router
import redis

app = FastAPI(
    title="Stats Service",
    description="Estadísticas agregadas de ratings por película (backend Postgres)",
)
app.include_router(soap_router)

_start_time = datetime.now(timezone.utc)


class HealthResponse(BaseModel):
    status: str
    cpu_percent: float
    timestamp: str
    uptime: float
    db: str


class MovieInfo(BaseModel):
    id: int
    title: str
    year: int | None = None
    director: str | None = None
    genre: str | None = None


class MovieStatsResponse(BaseModel):
    movie: MovieInfo
    rating_count: int
    avg_rating: float | None
    min_rating: float | None
    max_rating: float | None
    median_rating: float | None
    stddev: float | None
    stddev_rating: float | None
    score_distribution: dict[str, int]


@app.get("/")
async def root():
    return {"service": "stats", "message": "Hello World"}


@app.get(
    "/health",
    summary="Estado de salud del servicio",
    response_model=HealthResponse,
    responses={503: {"model": HealthResponse, "description": "Dependencia crítica caída"}},
)
async def health():
    uptime = (datetime.now(timezone.utc) - _start_time).total_seconds()
    db_ok = ping()
    body= HealthResponse(
        status="ok" if db_ok else "down",
        timestamp=datetime.now(timezone.utc).isoformat(),
        cpu_percent=psutil.cpu_percent(),
        uptime=uptime,
        db="ok" if db_ok else "down",
    )
    if not db_ok:
        return JSONResponse(status_code=503, content=body.dict())
    return body


@app.get(
    "/movies/{movie_id}/stats",
    response_model=MovieStatsResponse,
    summary="Estadísticas de una película",
    description=(
        "Dado un ID de película, devuelve estadísticas agregadas sobre sus reviews/ratings: "
        "cantidad, promedio, mínimo, máximo, mediana, desvío estándar y distribución de puntajes."
    ),
)
def movie_stats(
    response: Response,
    movie_id: int = Path(..., ge=1, description="ID de la película"),
):
    cached, cache_ok = cache.get_cached(movie_id)
    if cached is not None:
        response.headers["X-Cache"] = "HIT"
        return cached

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, title, year, director, genre FROM movies WHERE id = %s",
                (movie_id,),
            )
            movie_row = cur.fetchone()
            if movie_row is None:
                raise HTTPException(status_code=404, detail=f"Movie {movie_id} not found")

            movie = MovieInfo(
                id=movie_row["id"],
                title=movie_row["title"],
                year=movie_row["year"],
                director=movie_row["director"],
                genre=movie_row["genre"],
            )

            cur.execute(
                "SELECT score FROM ratings WHERE movie_id = %s ORDER BY score",
                (movie_id,),
            )
            scores: list[float] = [float(r["score"]) for r in cur.fetchall()]
            stats = compute_stats(scores)

            time.sleep(random.random() * 3)
            result = MovieStatsResponse(
                movie=movie,
                stddev=stats["stddev_rating"],
                **stats,
            )

            if cache_ok:
                cache.set_cached(movie_id, result.model_dump())
                response.headers["X-Cache"] = "MISS"
            else:
                response.headers["X-Cache"] = "BYPASS"
            return result



def _process_job(movie_id: int) -> dict:
    """Lo usa el hilo trabajador: reutiliza movie_stats, incluida la caché."""
    result = movie_stats(Response(), movie_id)
    return result if isinstance(result, dict) else result.model_dump()


@app.on_event("startup")
def _start_worker():
    jobs.start_worker(_process_job)


@app.post(
    "/movies/{movie_id}/stats/jobs",
    status_code=202,
    summary="Solicitar estadísticas de forma asíncrona",
)
def create_stats_job(
    request: Request,
    response: Response,
    movie_id: int = Path(..., ge=1, description="ID de la película"),
):
    try:
        job_id = jobs.create_job(movie_id)
    except redis.RedisError:
        raise HTTPException(status_code=503, detail="Cola de trabajos no disponible")

    prefix = request.headers.get("X-Forwarded-Prefix", "")
    location = f"{prefix}/jobs/{job_id}"
    response.headers["Location"] = location
    response.headers["Retry-After"] = "2"
    return {"job_id": job_id, "status": "pending", "status_url": location}


@app.get("/jobs/{job_id}", summary="Consultar el estado de un trabajo")
def get_stats_job(job_id: str, response: Response):
    try:
        job = jobs.get_job(job_id)
    except redis.RedisError:
        raise HTTPException(status_code=503, detail="Cola de trabajos no disponible")

    if job is None:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")
    if job["status"] in ("pending", "processing"):
        response.headers["Retry-After"] = "2"
    return job