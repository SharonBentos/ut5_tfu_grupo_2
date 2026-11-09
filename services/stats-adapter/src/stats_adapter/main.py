"""Adaptador REST -> SOAP.

GET /movies/{movie_id}/stats llama a ObtenerEstadisticasPelicula en el servicio
de Estadísticas (SOAP 1.1) y devuelve el mismo JSON que la UT4.
La URL del endpoint SOAP se configura con STATS_SOAP_URL.
"""

import os
import xml.etree.ElementTree as ET

import httpx
from fastapi import FastAPI, HTTPException, Path

SOAP_URL = os.getenv("STATS_SOAP_URL", "http://stats:8000/soap/estadisticas")
SOAP_TIMEOUT = float(os.getenv("STATS_SOAP_TIMEOUT", "10"))

SOAP_ENV = "http://schemas.xmlsoap.org/soap/envelope/"
TNS = "urn:ut5:stats"
XSI_NIL = "{http://www.w3.org/2001/XMLSchema-instance}nil"
NS = {"soap": SOAP_ENV, "tns": TNS}

app = FastAPI(
    title="Stats Adapter",
    description="Estadísticas por película en JSON (UT4), obtenidas por SOAP",
)


def build_request(movie_id: int) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<soap:Envelope xmlns:soap="{SOAP_ENV}" xmlns:tns="{TNS}">'
        "<soap:Body><tns:ObtenerEstadisticasPelicula>"
        f"<tns:movieId>{movie_id}</tns:movieId>"
        "</tns:ObtenerEstadisticasPelicula></soap:Body></soap:Envelope>"
    )


def _value(parent: ET.Element, name: str, cast):
    node = parent.find(f"tns:{name}", NS)
    if node is None or node.get(XSI_NIL) == "true" or node.text is None:
        return None
    return cast(node.text)


def to_ut4_json(resp: ET.Element) -> dict:
    movie = resp.find("tns:movie", NS)
    std = _value(resp, "stddevRating", float)
    entries = resp.findall("tns:scoreDistribution/tns:entry", NS)
    return {
        "movie": {
            "id": _value(movie, "id", int),
            "title": _value(movie, "title", str),
            "year": _value(movie, "year", int),
            "director": _value(movie, "director", str),
            "genre": _value(movie, "genre", str),
        },
        "rating_count": _value(resp, "ratingCount", int),
        "avg_rating": _value(resp, "avgRating", float),
        "min_rating": _value(resp, "minRating", float),
        "max_rating": _value(resp, "maxRating", float),
        "median_rating": _value(resp, "medianRating", float),
        "stddev": std,
        "stddev_rating": std,
        "score_distribution": {
            e.findtext("tns:score", namespaces=NS): int(e.findtext("tns:count", namespaces=NS))
            for e in entries
        },
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/movies/{movie_id}/stats", summary="Estadísticas de una película (vía SOAP)")
def movie_stats(movie_id: int = Path(..., ge=1, description="ID de la película")):
    try:
        r = httpx.post(
            SOAP_URL,
            content=build_request(movie_id).encode(),
            headers={
                "Content-Type": "text/xml; charset=utf-8",
                "SOAPAction": '"urn:ut5:stats#ObtenerEstadisticasPelicula"',
            },
            timeout=SOAP_TIMEOUT,
        )
        root = ET.fromstring(r.content)
    except httpx.HTTPError:
        raise HTTPException(status_code=503, detail="Servicio de estadísticas no disponible")
    except ET.ParseError:
        raise HTTPException(status_code=502, detail="Respuesta SOAP inválida")

    body = root.find("soap:Body", NS)
    fault = body.find("soap:Fault", NS) if body is not None else None
    if fault is not None:
        codigo = fault.findtext("detail/tns:ErrorEstadisticas/tns:codigo", namespaces=NS)
        if codigo == "PeliculaNoEncontrada":
            raise HTTPException(status_code=404, detail=f"Movie {movie_id} not found")
        if codigo == "ProyeccionNoInicializada":
            raise HTTPException(status_code=503, detail=fault.findtext("faultstring"))
        raise HTTPException(status_code=502, detail=fault.findtext("faultstring") or "SOAP Fault")

    resp = body.find("tns:ObtenerEstadisticasPeliculaResponse", NS) if body is not None else None
    if resp is None:
        raise HTTPException(status_code=502, detail="Respuesta SOAP inválida")
    return to_ut4_json(resp)
