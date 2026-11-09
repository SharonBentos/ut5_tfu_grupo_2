# Pruebas manuales – Persona 2 (Estadísticas)

Prueba de la parte de la Persona 2 de la TFU 5: base de Estadísticas, consumidor de Redis Streams, servidor SOAP con WSDL y adaptador REST.

- **Código probado:** `origin/main` en `97f27a4` (incluye los PR #1 a #5 del fork).
- **Fecha:** 2026-11-09.
- **Entorno:** Docker 29.9.2, `postgres:16-alpine`, `redis:7-alpine`, imágenes construidas desde `services/stats` y `services/stats-adapter`.
- **Configuración:** contenedores temporales en una red propia, sin el Compose principal ni NGINX. Al final se eliminaron.

## Resumen

| # | Caso | Esperado | Resultado |
|---|---|---|---|
| 1 | Filas en `movie_stats` tras `init_stats` | 40 | ✅ 40 |
| 1 | Película 10 tras `init_stats` | 0 reseñas | ✅ `rating_count = 0` |
| 2 | Descarga del WSDL | HTTP 200 | ✅ 200, `text/xml`, 4064 bytes |
| 2 | Adaptador con película inexistente (999) | HTTP 404 | ✅ 404 `{"detail":"Movie 999 not found"}` |
| 3 | Evento `rating_id=125`, película 10, score 8 | 1 reseña, promedio 8 | ✅ `rating_count 1`, `avg_rating 8.0` |
| 3 | Reenvío del mismo evento | sigue en 1 | ✅ `rating_count 1`, consumidor: «duplicado, ignorado» |

No falló ningún caso.

## Preparación

Desde la raíz del repo:

```
$ docker build -q -t p2-stats services/stats
$ docker build -q -t p2-adapter services/stats-adapter
```

## 1. Base y estadísticas iniciales

```
$ docker network create p2-net

$ docker run -d --name p2-postgres --network p2-net -e POSTGRES_USER=stats -e POSTGRES_PASSWORD=stats -e POSTGRES_DB=stats -v "$PWD/postgres/stats/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" postgres:16-alpine

$ docker run -d --name p2-redis --network p2-net redis:7-alpine

$ docker exec p2-postgres psql -U stats -d stats -c "SELECT (SELECT count(*) FROM movies) AS peliculas, (SELECT count(*) FROM ratings) AS calificaciones;"
 peliculas | calificaciones 
-----------+----------------
        40 |            124
(1 row)

$ docker run --rm --network p2-net -e DATABASE_URL=postgresql://stats:stats@p2-postgres:5432/stats p2-stats python -m stats_service.init_stats
Estadísticas guardadas para 40 películas

$ docker exec p2-postgres psql -U stats -d stats -c "SELECT count(*) AS filas_estadisticas FROM movie_stats;" -c "SELECT movie_id, rating_count, avg_rating, score_distribution FROM movie_stats WHERE movie_id = 10;"
 filas_estadisticas 
--------------------
                 40
(1 row)

 movie_id | rating_count | avg_rating | score_distribution 
----------+--------------+------------+--------------------
       10 |            0 |            | {}
(1 row)
```

## 2. Consumidor, SOAP y adaptador

El servidor SOAP es el servicio `stats` (puerto 18100). El adaptador apunta a él con `STATS_SOAP_URL` (puerto 18101).

```
$ docker run -d --name p2-consumer --network p2-net -e DATABASE_URL=postgresql://stats:stats@p2-postgres:5432/stats -e REDIS_URL=redis://p2-redis:6379/0 -e PYTHONUNBUFFERED=1 p2-stats python -m stats_service.consumer

$ docker run -d --name p2-soap --network p2-net -p 127.0.0.1:18100:8000 -e DATABASE_URL=postgresql://stats:stats@p2-postgres:5432/stats -e REDIS_URL=redis://p2-redis:6379/0 p2-stats

$ docker run -d --name p2-adapter --network p2-net -p 127.0.0.1:18101:8000 -e STATS_SOAP_URL=http://p2-soap:8000/soap/estadisticas p2-adapter

$ docker logs p2-consumer
2026-11-09 03:33:09,198 INFO consumidor 2f8211bd74b6 escuchando resenas.events (grupo stats)

$ curl -s -o wsdl.xml -w 'HTTP %{http_code} %{content_type} %{size_download} bytes\n' 'http://localhost:18100/soap/estadisticas?wsdl'
HTTP 200 text/xml; charset=utf-8 4064 bytes

$ grep -o '<operation name="[^"]*"' wsdl.xml | sort -u; grep -o '<soap:address[^>]*>' wsdl.xml
<operation name="ObtenerEstadisticasPelicula"
<soap:address location="http://localhost:18100/soap/estadisticas"/>

$ curl -s -w '\nHTTP %{http_code}\n' http://localhost:18101/movies/999/stats
{"detail":"Movie 999 not found"}
HTTP 404
```

## 3. Evento `ReseñaCreada` y reenvío

Estado previo de la película 10, consultado por el adaptador:

```
$ curl -s http://localhost:18101/movies/10/stats
{"movie":{"id":10,"title":"El origen","year":2010,"director":"Christopher Nolan","genre":"Ciencia ficción"},"rating_count":0,"avg_rating":null,"min_rating":null,"max_rating":null,"median_rating":null,"stddev":null,"stddev_rating":null,"score_distribution":{}}
```

Primer envío:

```
$ docker exec p2-redis redis-cli XADD resenas.events '*' type ReseñaCreada rating_id 125 movie_id 10 reviewer_id 1 score 8
1794195202486-0

$ curl -s -w '\nHTTP %{http_code}\n' http://localhost:18101/movies/10/stats
{"movie":{"id":10,"title":"El origen","year":2010,"director":"Christopher Nolan","genre":"Ciencia ficción"},"rating_count":1,"avg_rating":8.0,"min_rating":8.0,"max_rating":8.0,"median_rating":8.0,"stddev":0.0,"stddev_rating":0.0,"score_distribution":{"8":1}}
HTTP 200
```

Reenvío del mismo evento:

```
$ docker exec p2-redis redis-cli XADD resenas.events '*' type ReseñaCreada rating_id 125 movie_id 10 reviewer_id 1 score 8
1794195204560-0

$ curl -s -w '\nHTTP %{http_code}\n' http://localhost:18101/movies/10/stats
{"movie":{"id":10,"title":"El origen","year":2010,"director":"Christopher Nolan","genre":"Ciencia ficción"},"rating_count":1,"avg_rating":8.0,"min_rating":8.0,"max_rating":8.0,"median_rating":8.0,"stddev":0.0,"stddev_rating":0.0,"score_distribution":{"8":1}}
HTTP 200

$ docker exec p2-postgres psql -U stats -d stats -c "SELECT count(*) AS calificaciones_pelicula_10 FROM ratings WHERE movie_id = 10;"
 calificaciones_pelicula_10 
----------------------------
                          1
(1 row)

$ docker exec p2-redis redis-cli XPENDING resenas.events stats
0

$ docker logs p2-consumer
2026-11-09 03:33:09,198 INFO consumidor 2f8211bd74b6 escuchando resenas.events (grupo stats)
2026-11-09 03:33:22,497 INFO 1794195202486-0 rating 125 aplicado
2026-11-09 03:33:24,570 INFO 1794195204560-0 rating 125 duplicado, ignorado
```

## Limpieza

```
$ rm -f wsdl.xml
$ docker rm -f p2-adapter p2-soap p2-consumer p2-redis p2-postgres
$ docker network rm p2-net
$ docker rmi p2-stats p2-adapter
```
