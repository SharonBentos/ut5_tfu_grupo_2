# UT5 – API de reseñas de películas (Event-Driven)

Trabajo final de la UT5 de Análisis y Diseño de Aplicaciones II – Grupo 2.

La aplicación evoluciona la arquitectura basada en servicios de la UT4 hacia una **arquitectura basada en eventos** (Event-Driven, topología de broker) sobre **Redis Streams**. Cada servicio es dueño de su base de datos y se integra con los demás publicando y consumiendo el evento `ReviewCreated`.

## Componentes

| Servicio | Instancias | Responsabilidad |
|---|---|---|
| `gateway` | 1 | NGINX: único punto de entrada (puerto 8080), autenticación, rate limiting |
| `reviews` | 3 | API REST de reseñas; guarda la reseña y el evento en la misma transacción (outbox) |
| `reviews-relay` | 3 | Outbox Relay: publica los eventos pendientes en el stream `resenas.events` |
| `reviews-db` | 1 | Base de Reseñas (películas, usuarios, calificaciones y tabla `outbox`) |
| `stats` | 3 | Servicio SOAP de estadísticas (con WSDL) |
| `stats-adapter` | 1 | Adaptador REST → SOAP: expone la consulta de estadísticas en JSON |
| `stats-consumer` | 3 | Proyector: consume `ReviewCreated` y recalcula las estadísticas |
| `stats-init` | 1 (una vez) | Calcula las estadísticas iniciales al levantar |
| `stats-db` | 1 | Base de Estadísticas |
| `users` | 3 | API REST de usuarios (requiere autenticación) |
| `users-consumer` | 3 | Proyector: consume `ReviewCreated` y actualiza los datos del usuario |
| `postgres` | 1 | Base de Usuarios |
| `redis` | 1 | Broker (Redis Streams con persistencia AOF) |

Patrones aplicados: Publisher-Subscriber, Transactional Outbox, Idempotent Consumer, Competing Consumers, Retry con backoff exponencial, Dead Letter Queue, Gatekeeper, Gateway Offloading, Rate Limiting y Health Endpoint Monitoring.

## Cómo levantarlo

Requisitos: Docker y Docker Compose.

```bash
cp .env.example .env          # en PowerShell: Copy-Item .env.example .env
docker compose up -d --build
docker compose ps             # todos "Up" o "healthy"; stats-init termina en "Exited (0)"
```

El archivo `.env` define el usuario y la contraseña del endpoint de usuarios (por defecto `admin` / `cambiar`). Sin él, el gateway no puede autenticar.

### Volver a los datos iniciales

Los scripts `init.sql` solo se ejecutan cuando el volumen de la base está vacío. Para borrar los datos de prueba y recargar los iniciales:

```bash
docker compose down -v        # borra los volúmenes (todas las reseñas creadas)
docker compose up -d --build
```

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
el evento queda pendiente para reintentar. El relay corre en tres instancias que no
publican el mismo evento gracias a `FOR UPDATE SKIP LOCKED`, y reintenta con
espera exponencial (2, 4, 8, 16 s, con tope de 30 s) cuando fallan Redis o la
base.

Un evento real tiene la siguiente forma:

```json
{
  "event_type": "ReviewCreated",
  "aggregate_id": "125",
  "payload": {
    "rating_id": 125,
    "movie_id": 12,
    "reviewer_id": 4,
    "score": 8.0,
    "comment": null,
    "created_at": "2026-11-09T10:08:12.923666+00:00"
  }
}
```

Variables principales:

```env
DATABASE_URL=postgresql://reviews:reviews@reviews-db:5432/reviews
REDIS_URL=redis://redis:6379/0
```

## Servicio de Estadísticas

`docker compose up -d --build` levanta su base propia (`stats-db`, con
`postgres/stats/init.sql`) y ejecuta una vez `stats-init`
(`python -m stats_service.init_stats`). `stats`, el servidor SOAP, recién
arranca cuando ese paso termina bien. `stats-consumer` lee `ReviewCreated` de
`resenas.events`, y `stats-adapter` traduce SOAP al JSON REST. Redis usa AOF
con el volumen `redis-data`.

```text
GET /api/stats/movies/{movie_id}/stats   (gateway -> stats-adapter -> SOAP)
```

`stats-consumer` corre en tres instancias dentro del mismo grupo de consumidores (`stats`), que se reparten los eventos (Competing Consumers). Es idempotente por `rating_id`. Si la base está caída, el evento queda pendiente y se reintenta; los eventos que no se pueden procesar se copian a `resenas.events.dlq` (cola de mensajes fallidos) con los campos `original_id` y `error`.

El contrato WSDL se puede consultar a través del gateway en `GET /api/stats/soap/estadisticas?wsdl`.

## Servicio de Usuarios

`users-consumer` (tres instancias) lee `ReviewCreated` con su propio grupo (`users`), así recibe todos los eventos independientemente de Estadísticas (Publisher-Subscriber). Guarda una copia de cada calificación en la base de Usuarios, de donde `GET /api/users/users/{id}` calcula `rating_count` y `rating_average`. Sigue el mismo esquema que el consumidor de Estadísticas (idempotencia, reintentos y cola de mensajes fallidos).

## Endpoints (a través del gateway, http://localhost:8080)

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/reviews/movies/{movie_id}/reviews` | Crear reseña. 201 creada, 404 película o usuario inexistente, 409 ya reseñada |
| GET | `/api/reviews/movies/{movie_id}/reviews` | Reseñas de una película |
| GET | `/api/reviews/reviews/{review_id}` | Reseña por ID |
| GET | `/api/reviews/users/{user_id}/reviews` | Reseñas de un usuario |
| GET | `/api/stats/movies/{movie_id}/stats` | Estadísticas de una película (gateway → adaptador REST → SOAP) |
| GET | `/api/stats/soap/estadisticas?wsdl` | Contrato WSDL del servicio SOAP |
| POST | `/api/stats/soap/estadisticas` | Operación SOAP `ObtenerEstadisticasPelicula` |
| GET | `/api/users/users/{user_id}` | Usuario con `rating_count` y `rating_average` (autenticación básica) |
| GET | `/gateway/health` | Estado del gateway |

## Cómo probarlo

Los ejemplos usan `curl` en bash. En PowerShell usar `curl.exe` y escapar las comillas del JSON: `-d '{\"reviewer_id\":4,\"score\":8}'`.

### Caso de uso principal: publicar una reseña

```bash
curl http://localhost:8080/api/stats/movies/12/stats
curl -u admin:cambiar http://localhost:8080/api/users/users/4
curl -X POST http://localhost:8080/api/reviews/movies/12/reviews -H "Content-Type: application/json" -d '{"reviewer_id":4,"score":8}'
# Unos segundos después, Estadísticas y Usuarios reflejan la reseña nueva
curl http://localhost:8080/api/stats/movies/12/stats
curl -u admin:cambiar http://localhost:8080/api/users/users/4
```

### SOAP

```bash
curl "http://localhost:8080/api/stats/soap/estadisticas?wsdl"
curl -X POST http://localhost:8080/api/stats/soap/estadisticas -H "Content-Type: text/xml; charset=utf-8" -d '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="urn:ut5:stats"><soap:Body><tns:ObtenerEstadisticasPelicula><tns:movieId>12</tns:movieId></tns:ObtenerEstadisticasPelicula></soap:Body></soap:Envelope>'
```

### Escenario A: cae la base de Estadísticas

```bash
docker compose stop stats-db
curl -X POST http://localhost:8080/api/reviews/movies/13/reviews -H "Content-Type: application/json" -d '{"reviewer_id":6,"score":7}'   # 201
curl -i http://localhost:8080/api/stats/movies/13/stats   # 503
docker compose start stats-db
curl http://localhost:8080/api/stats/movies/13/stats      # la reseña se aplicó al volver
```

### Escenario B: cae Redis (el broker)

```bash
docker compose stop redis
curl -X POST http://localhost:8080/api/reviews/movies/14/reviews -H "Content-Type: application/json" -d '{"reviewer_id":6,"score":9}'   # 201
docker compose logs reviews-relay --since 1m | grep reintento   # 2, 4, 8, 16, 30 s
docker compose start redis
curl http://localhost:8080/api/stats/movies/14/stats      # converge al volver Redis (hasta ~30 s)
```

### Escenario C: evento inválido → cola de mensajes fallidos

```bash
docker compose exec redis redis-cli XADD resenas.events '*' event_type ReviewCreated aggregate_id 999 payload '{"rating_id":999,"movie_id":555,"reviewer_id":1,"score":9}'
docker compose exec redis redis-cli XRANGE resenas.events.dlq - +
```

### Competing Consumers

```bash
for m in 15 16 17 18 19 20; do curl -s -o /dev/null -X POST http://localhost:8080/api/reviews/movies/$m/reviews -H "Content-Type: application/json" -d '{"reviewer_id":5,"score":7}'; done
docker compose logs stats-consumer | grep aplicado   # los eventos se reparten entre las 3 instancias
```
