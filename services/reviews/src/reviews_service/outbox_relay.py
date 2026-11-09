import json
import logging
import os
import time

import psycopg
import redis

from reviews_service.db import get_connection

LOGGER = logging.getLogger(__name__)
STREAM_NAME = "resenas.events"
POLL_INTERVAL_SECONDS = 2
INITIAL_RETRY_SECONDS = 2
MAX_RETRY_SECONDS = 30


def publish_pending_event(redis_client: redis.Redis) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, event_type, aggregate_id, payload
                FROM outbox
                WHERE published_at IS NULL
                ORDER BY created_at, id
                FOR UPDATE SKIP LOCKED
                LIMIT 1
                """
            )
            event = cur.fetchone()
            if event is None:
                return False

            redis_client.xadd(
                STREAM_NAME,
                {
                    "event_type": event["event_type"],
                    "aggregate_id": str(event["aggregate_id"]),
                    "payload": json.dumps(event["payload"]),
                },
            )
            cur.execute(
                """
                UPDATE outbox
                SET published_at = now(), attempts = attempts + 1
                WHERE id = %s
                """,
                (event["id"],),
            )
            return True


def run() -> None:
    logging.basicConfig(level=logging.INFO)
    redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
    redis_client = redis.Redis.from_url(redis_url, decode_responses=True)
    retry_delay = INITIAL_RETRY_SECONDS

    while True:
        try:
            published = publish_pending_event(redis_client)
            retry_delay = INITIAL_RETRY_SECONDS
            if not published:
                time.sleep(POLL_INTERVAL_SECONDS)
        except (psycopg.Error, redis.RedisError) as e:
            LOGGER.warning(
                "Outbox relay falló; reintento en %s s: %s",
                retry_delay,
                e,
            )
            time.sleep(retry_delay)
            retry_delay = min(retry_delay * 2, MAX_RETRY_SECONDS)


if __name__ == "__main__":
    run()
