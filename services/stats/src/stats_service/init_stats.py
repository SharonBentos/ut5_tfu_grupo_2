"""Calcula y guarda las estadísticas de todas las películas en movie_stats.

Uso: python -m stats_service.init_stats
Es idempotente: cada ejecución reescribe una fila por película.
"""

from psycopg.types.json import Jsonb

from stats_service.calc import compute_stats
from stats_service.db import get_connection

UPSERT_SQL = """
INSERT INTO movie_stats (movie_id, rating_count, avg_rating, min_rating, max_rating,
                         median_rating, stddev_rating, score_distribution, updated_at)
VALUES (%(movie_id)s, %(rating_count)s, %(avg_rating)s, %(min_rating)s, %(max_rating)s,
        %(median_rating)s, %(stddev_rating)s, %(score_distribution)s, now())
ON CONFLICT (movie_id) DO UPDATE SET
    rating_count = EXCLUDED.rating_count,
    avg_rating = EXCLUDED.avg_rating,
    min_rating = EXCLUDED.min_rating,
    max_rating = EXCLUDED.max_rating,
    median_rating = EXCLUDED.median_rating,
    stddev_rating = EXCLUDED.stddev_rating,
    score_distribution = EXCLUDED.score_distribution,
    updated_at = now()
"""


def save_movie_stats(cur, movie_id: int) -> dict:
    cur.execute(
        "SELECT score FROM ratings WHERE movie_id = %s ORDER BY score",
        (movie_id,),
    )
    stats = compute_stats([float(r["score"]) for r in cur.fetchall()])
    cur.execute(
        UPSERT_SQL,
        {**stats, "movie_id": movie_id, "score_distribution": Jsonb(stats["score_distribution"])},
    )
    return stats


def init_all() -> int:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM movies ORDER BY id")
            movie_ids = [r["id"] for r in cur.fetchall()]
            for movie_id in movie_ids:
                save_movie_stats(cur, movie_id)
    return len(movie_ids)


if __name__ == "__main__":
    print(f"Estadísticas guardadas para {init_all()} películas")
