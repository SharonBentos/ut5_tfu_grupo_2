# UT5 - Reseñas

## Servicio de Reseñas

La API publica el alta de reseñas mediante:

```text
POST /api/reviews/movies/{movie_id}/reviews
```

El cuerpo acepta `reviewer_id`, `score` (entre 0 y 10) y `comment` opcional.
La respuesta es `201` cuando se crea la reseña y `409` si el usuario ya
reseñó esa película.

La API guarda la reseña y el evento `ReviewCreated` en `outbox` dentro de la
misma transacción. El relay publica los eventos pendientes en el stream
`resenas.events` de Redis y los marca como publicados. Si Redis está caído,
el evento queda pendiente para reintentar.

Un evento real de prueba tiene `rating_id: 3` y la siguiente forma:

```json
{
  "event_type": "ReviewCreated",
  "aggregate_id": "3",
  "payload": {
    "rating_id": 3,
    "movie_id": 3,
    "reviewer_id": 2,
    "score": 8.7,
    "comment": "Prueba por NGINX"
  }
}
```

Variables principales:

```env
DATABASE_URL=postgresql://reviews:reviews@reviews-db:5432/reviews
REDIS_URL=redis://redis:6379/0
```
