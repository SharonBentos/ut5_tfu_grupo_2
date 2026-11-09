"""Consumidor de ReviewCreated para el servicio de Usuarios (Proyector de Reseñas U).

Uso: python -m users_service.consumer

Lee resenas.events con su propio grupo ("users"), así recibe todos los eventos
independientemente del grupo de Estadísticas (Publisher-Subscriber). Guarda una
copia de cada calificación en la base de Usuarios (tabla ratings), de donde
GET /users/{id} calcula rating_count y rating_average.

Mismo esquema que el consumidor de Estadísticas: idempotente por rating_id,
XACK recién después del commit, base caída = queda pendiente, eventos que no
se pueden procesar van a la cola de mensajes fallidos (resenas.events.dlq).
"""

import json
import logging
import os
import socket
import time

import psycopg
import redis

from users_service.db import get_connection

STREAM = os.getenv("USERS_STREAM", "resenas.events")
GROUP = os.getenv("USERS_GROUP", "users")
CONSUMER = os.getenv("USERS_CONSUMER", socket.gethostname())
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
CLAIM_IDLE_MS = int(os.getenv("USERS_CLAIM_IDLE_MS", "30000"))
BLOCK_MS = 5000
RETRY_SECONDS = 2
DLQ_STREAM = os.getenv("USERS_DLQ_STREAM", f"{STREAM}.dlq")
MAX_DELIVERIES = int(os.getenv("USERS_MAX_DELIVERIES", "3"))

log = logging.getLogger("users.consumer")
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
    """Devuelve True si la calificación era nueva, False si ya estaba guardada."""
    try:
        data = json.loads(fields["payload"])
        rating_id = int(data["rating_id"])
        movie_id = int(data["movie_id"])
        reviewer_id = int(data["reviewer_id"])
        score = float(data["score"])
        comment = data.get("comment")
        created_at = data.get("created_at")
    except (KeyError, ValueError, TypeError) as e:
        raise InvalidEvent(f"campos inválidos: {e}") from e

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM reviewers WHERE id = %s", (reviewer_id,))
            if cur.fetchone() is None:
                raise InvalidEvent(f"usuario {reviewer_id} inexistente")
            cur.execute(
                "INSERT INTO ratings (id, movie_id, reviewer_id, score, comment, created_at) "
                "VALUES (%s, %s, %s, %s, %s, COALESCE(%s::timestamptz, now())) "
                "ON CONFLICT (id) DO NOTHING",
                (rating_id, movie_id, reviewer_id, score, comment, created_at),
            )
            return cur.rowcount == 1


def send_to_dlq(msg_id: str, fields: dict, reason: str) -> None:
    """Copia el mensaje a la cola de fallidos y lo confirma en el stream original."""
    r.xadd(DLQ_STREAM, {**fields, "original_id": msg_id, "group": GROUP, "error": reason[:500]})
    r.xack(STREAM, GROUP, msg_id)
    log.error("%s enviado a %s: %s", msg_id, DLQ_STREAM, reason)


def deliveries(msg_id: str) -> int:
    """Cantidad de veces que Redis entregó el mensaje a este grupo."""
    info = r.xpending_range(STREAM, GROUP, min=msg_id, max=msg_id, count=1)
    return info[0]["times_delivered"] if info else 1


def handle(msg_id: str, fields: dict) -> None:
    """Procesa un mensaje y hace XACK.

    - Base caída (OperationalError): propaga sin confirmar; se reintenta y NO va a la DLQ.
    - Evento inválido: reintentar no lo arreglaría, va directo a la DLQ.
    - Error inesperado: queda pendiente y se reintenta; tras MAX_DELIVERIES entregas va a la DLQ.
    """
    if fields.get("event_type") != "ReviewCreated":
        log.info("%s ignorado (event_type=%s)", msg_id, fields.get("event_type"))
        r.xack(STREAM, GROUP, msg_id)
        return
    try:
        new = apply_event(fields)
    except (InvalidEvent, psycopg.DataError, psycopg.IntegrityError) as e:
        send_to_dlq(msg_id, fields, f"evento inválido: {e}")
        return
    except psycopg.OperationalError:
        raise
    except Exception as e:
        n = deliveries(msg_id)
        if n >= MAX_DELIVERIES:
            send_to_dlq(msg_id, fields, f"falló en {n} entregas: {e}")
        else:
            log.warning("%s falló (entrega %s de %s), queda pendiente: %s",
                        msg_id, n, MAX_DELIVERIES, e)
        return
    log.info("%s rating %s %s", msg_id, fields.get("aggregate_id"),
             "aplicado" if new else "duplicado, ignorado")
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
