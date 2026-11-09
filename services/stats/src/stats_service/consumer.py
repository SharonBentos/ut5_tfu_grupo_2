"""Consumidor de ReviewCreated (ReseñaCreada) desde Redis Streams.

Uso: python -m stats_service.consumer

Contrato del evento (lo publica reviews_service.outbox_relay en `resenas.events`):
    event_type=ReviewCreated  aggregate_id=<rating_id>
    payload=<JSON con rating_id, movie_id, reviewer_id, score, ...>
Ejemplo:
    XADD resenas.events * event_type ReviewCreated aggregate_id 125 payload '{"rating_id": 125, "movie_id": 10, "reviewer_id": 1, "score": 8.0}'

Cada mensaje guarda la calificación local y recalcula las estadísticas de la
película en una sola transacción; recién después del commit se hace XACK.
Si PostgreSQL falla, el mensaje queda pendiente y se reintenta.
"""

import json
import logging
import os
import socket
import time

import psycopg
import redis

from stats_service.db import get_connection
from stats_service.init_stats import save_movie_stats

STREAM = os.getenv("STATS_STREAM", "resenas.events")
GROUP = os.getenv("STATS_GROUP", "stats")
CONSUMER = os.getenv("STATS_CONSUMER", socket.gethostname())
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
CLAIM_IDLE_MS = int(os.getenv("STATS_CLAIM_IDLE_MS", "30000"))
BLOCK_MS = 5000
RETRY_SECONDS = 2

log = logging.getLogger("stats.consumer")
# El timeout del socket tiene que superar al bloqueo de XREADGROUP.
r = redis.Redis.from_url(REDIS_URL, decode_responses=True, socket_timeout=BLOCK_MS / 1000 + 5)


class InvalidEvent(Exception):
    pass


def ensure_group() -> None:
    try:
        r.xgroup_create(STREAM, GROUP, id="0", mkstream=True)
    except redis.ResponseError as e:
        if "BUSYGROUP" not in str(e):
            raise


def apply_event(fields: dict) -> bool:
    """Devuelve True si la reseña era nueva, False si ya estaba aplicada."""
    try:
        data = json.loads(fields["payload"])
        rating_id = int(data["rating_id"])
        movie_id = int(data["movie_id"])
        reviewer_id = int(data["reviewer_id"])
        score = float(data["score"])
    except (KeyError, ValueError, TypeError) as e:
        raise InvalidEvent(f"campos inválidos: {e}") from e

    with get_connection() as conn:
        with conn.cursor() as cur:
            # Bloquea la película: dos workers no recalculan la misma a la vez.
            cur.execute("SELECT id FROM movies WHERE id = %s FOR UPDATE", (movie_id,))
            if cur.fetchone() is None:
                raise InvalidEvent(f"película {movie_id} inexistente")
            cur.execute(
                "INSERT INTO ratings (id, movie_id, reviewer_id, score) "
                "VALUES (%s, %s, %s, %s) ON CONFLICT (id) DO NOTHING",
                (rating_id, movie_id, reviewer_id, score),
            )
            if cur.rowcount == 0:
                return False
            save_movie_stats(cur, movie_id)
    return True


def handle(msg_id: str, fields: dict) -> None:
    """Procesa un mensaje y hace XACK. Si falla la base, propaga sin confirmar."""
    if fields.get("event_type") != "ReviewCreated":
        log.info("%s ignorado (event_type=%s)", msg_id, fields.get("event_type"))
    else:
        try:
            new = apply_event(fields)
            log.info("%s rating %s %s", msg_id, fields.get("aggregate_id"),
                     "aplicado" if new else "duplicado, ignorado")
        except (InvalidEvent, psycopg.DataError, psycopg.IntegrityError) as e:
            # Reintentar no lo arreglaría: se descarta para no bloquear el stream.
            log.error("%s descartado: %s", msg_id, e)
    r.xack(STREAM, GROUP, msg_id)


def process(messages) -> None:
    for msg_id, fields in messages:
        handle(msg_id, fields)


def run() -> None:
    log.info("consumidor %s escuchando %s (grupo %s)", CONSUMER, STREAM, GROUP)
    need_group = True
    while True:
        try:
            if need_group:
                ensure_group()
                need_group = False
            # 1) Pendientes propios (mensajes que fallaron antes).
            _, pending = r.xreadgroup(GROUP, CONSUMER, {STREAM: "0"}, count=50)[0]
            process(pending)
            # 2) Pendientes de workers caídos.
            _, claimed, _ = r.xautoclaim(STREAM, GROUP, CONSUMER, CLAIM_IDLE_MS, "0-0", count=50)
            process(claimed)
            # 3) Mensajes nuevos.
            for _, messages in r.xreadgroup(GROUP, CONSUMER, {STREAM: ">"}, count=50, block=BLOCK_MS) or []:
                process(messages)
        except psycopg.OperationalError as e:
            log.warning("PostgreSQL no disponible, queda pendiente: %s", e)
            time.sleep(RETRY_SECONDS)
        except redis.ResponseError as e:
            if "NOGROUP" in str(e):
                # El grupo desapareció (p. ej. Redis sin persistencia): se recrea
                # desde "0"; lo ya aplicado se descarta por rating_id.
                log.warning("grupo %s inexistente, se recrea: %s", GROUP, e)
                need_group = True
            else:
                log.warning("Error de Redis: %s", e)
                time.sleep(RETRY_SECONDS)
        except redis.RedisError as e:
            log.warning("Redis no disponible: %s", e)
            time.sleep(RETRY_SECONDS)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    run()
