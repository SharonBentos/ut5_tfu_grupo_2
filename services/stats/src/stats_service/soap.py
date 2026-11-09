"""Consulta de estadísticas por SOAP 1.1 (document/literal).

WSDL:      GET  /soap/estadisticas?wsdl
Operación: POST /soap/estadisticas  ->  ObtenerEstadisticasPelicula(movieId)

Lee la proyección guardada en movie_stats (pasos 2 y 3) y los datos de movies.
Faults: PeliculaNoEncontrada (Client), ProyeccionNoInicializada (Server),
PedidoInvalido (Client).
"""

import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

from fastapi import APIRouter, Request, Response

from stats_service.db import get_connection

TNS = "urn:ut5:stats"
SOAP_ENV = "http://schemas.xmlsoap.org/soap/envelope/"
XML_TYPE = "text/xml; charset=utf-8"

router = APIRouter()

WSDL = """<?xml version="1.0" encoding="UTF-8"?>
<definitions name="EstadisticasService" targetNamespace="urn:ut5:stats"
    xmlns="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:tns="urn:ut5:stats">
  <types>
    <xsd:schema targetNamespace="urn:ut5:stats" elementFormDefault="qualified">
      <xsd:complexType name="Pelicula">
        <xsd:sequence>
          <xsd:element name="id" type="xsd:int"/>
          <xsd:element name="title" type="xsd:string"/>
          <xsd:element name="year" type="xsd:int" nillable="true"/>
          <xsd:element name="director" type="xsd:string" nillable="true"/>
          <xsd:element name="genre" type="xsd:string" nillable="true"/>
        </xsd:sequence>
      </xsd:complexType>
      <xsd:complexType name="Puntaje">
        <xsd:sequence>
          <xsd:element name="score" type="xsd:int"/>
          <xsd:element name="count" type="xsd:int"/>
        </xsd:sequence>
      </xsd:complexType>
      <xsd:element name="ObtenerEstadisticasPelicula">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element name="movieId" type="xsd:int"/>
          </xsd:sequence>
        </xsd:complexType>
      </xsd:element>
      <xsd:element name="ObtenerEstadisticasPeliculaResponse">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element name="movie" type="tns:Pelicula"/>
            <xsd:element name="ratingCount" type="xsd:int"/>
            <xsd:element name="avgRating" type="xsd:double" nillable="true"/>
            <xsd:element name="minRating" type="xsd:double" nillable="true"/>
            <xsd:element name="maxRating" type="xsd:double" nillable="true"/>
            <xsd:element name="medianRating" type="xsd:double" nillable="true"/>
            <xsd:element name="stddevRating" type="xsd:double" nillable="true"/>
            <xsd:element name="scoreDistribution">
              <xsd:complexType>
                <xsd:sequence>
                  <xsd:element name="entry" type="tns:Puntaje" minOccurs="0" maxOccurs="unbounded"/>
                </xsd:sequence>
              </xsd:complexType>
            </xsd:element>
          </xsd:sequence>
        </xsd:complexType>
      </xsd:element>
      <xsd:element name="ErrorEstadisticas">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element name="codigo" type="xsd:string"/>
            <xsd:element name="movieId" type="xsd:int" minOccurs="0"/>
          </xsd:sequence>
        </xsd:complexType>
      </xsd:element>
    </xsd:schema>
  </types>
  <message name="ObtenerEstadisticasPeliculaRequest">
    <part name="parameters" element="tns:ObtenerEstadisticasPelicula"/>
  </message>
  <message name="ObtenerEstadisticasPeliculaResponse">
    <part name="parameters" element="tns:ObtenerEstadisticasPeliculaResponse"/>
  </message>
  <message name="ErrorEstadisticas">
    <part name="fault" element="tns:ErrorEstadisticas"/>
  </message>
  <portType name="EstadisticasPortType">
    <operation name="ObtenerEstadisticasPelicula">
      <input message="tns:ObtenerEstadisticasPeliculaRequest"/>
      <output message="tns:ObtenerEstadisticasPeliculaResponse"/>
      <fault name="ErrorEstadisticas" message="tns:ErrorEstadisticas"/>
    </operation>
  </portType>
  <binding name="EstadisticasBinding" type="tns:EstadisticasPortType">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <operation name="ObtenerEstadisticasPelicula">
      <soap:operation soapAction="urn:ut5:stats#ObtenerEstadisticasPelicula"/>
      <input><soap:body use="literal"/></input>
      <output><soap:body use="literal"/></output>
      <fault name="ErrorEstadisticas"><soap:fault name="ErrorEstadisticas" use="literal"/></fault>
    </operation>
  </binding>
  <service name="EstadisticasService">
    <port name="EstadisticasPort" binding="tns:EstadisticasBinding">
      <soap:address location="{location}"/>
    </port>
  </service>
</definitions>
"""


def _envelope(body: str) -> str:
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<soap:Envelope xmlns:soap="{SOAP_ENV}" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        f"<soap:Body>{body}</soap:Body></soap:Envelope>"
    )


def _fault(faultcode: str, codigo: str, mensaje: str, movie_id: int | None = None) -> Response:
    movie = f"<tns:movieId>{movie_id}</tns:movieId>" if movie_id is not None else ""
    body = (
        f"<soap:Fault><faultcode>soap:{faultcode}</faultcode>"
        f"<faultstring>{escape(mensaje)}</faultstring>"
        f'<detail><tns:ErrorEstadisticas xmlns:tns="{TNS}">'
        f"<tns:codigo>{codigo}</tns:codigo>{movie}</tns:ErrorEstadisticas></detail>"
        "</soap:Fault>"
    )
    # SOAP 1.1: todo Fault viaja con HTTP 500.
    return Response(_envelope(body), status_code=500, media_type=XML_TYPE)


def _el(name: str, value) -> str:
    if value is None:
        return f'<tns:{name} xsi:nil="true"/>'
    return f"<tns:{name}>{escape(str(value))}</tns:{name}>"


def _parse_movie_id(raw: bytes) -> int:
    root = ET.fromstring(raw)
    node = root.find(f"{{{SOAP_ENV}}}Body/{{{TNS}}}ObtenerEstadisticasPelicula/{{{TNS}}}movieId")
    if node is None or node.text is None:
        raise ValueError("falta ObtenerEstadisticasPelicula/movieId")
    return int(node.text.strip())


@router.get("/soap/estadisticas", include_in_schema=False)
def wsdl(request: Request):
    location = str(request.url.replace(query=""))
    return Response(WSDL.replace("{location}", escape(location)), media_type=XML_TYPE)


@router.post("/soap/estadisticas", include_in_schema=False)
async def obtener_estadisticas(request: Request):
    try:
        movie_id = _parse_movie_id(await request.body())
    except (ET.ParseError, ValueError) as e:
        return _fault("Client", "PedidoInvalido", f"Pedido SOAP inválido: {e}")

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT m.id, m.title, m.year, m.director, m.genre, s.movie_id AS stats_id, "
                "s.rating_count, s.avg_rating, s.min_rating, s.max_rating, s.median_rating, "
                "s.stddev_rating, s.score_distribution "
                "FROM movies m LEFT JOIN movie_stats s ON s.movie_id = m.id WHERE m.id = %s",
                (movie_id,),
            )
            row = cur.fetchone()

    if row is None:
        return _fault("Client", "PeliculaNoEncontrada", f"Movie {movie_id} not found", movie_id)
    if row["stats_id"] is None:
        return _fault(
            "Server", "ProyeccionNoInicializada",
            f"Estadísticas de la película {movie_id} sin inicializar", movie_id,
        )

    dist = sorted((int(k), v) for k, v in row["score_distribution"].items())
    entries = "".join(
        f"<tns:entry><tns:score>{k}</tns:score><tns:count>{v}</tns:count></tns:entry>"
        for k, v in dist
    )
    body = (
        f'<tns:ObtenerEstadisticasPeliculaResponse xmlns:tns="{TNS}">'
        "<tns:movie>"
        + _el("id", row["id"]) + _el("title", row["title"]) + _el("year", row["year"])
        + _el("director", row["director"]) + _el("genre", row["genre"])
        + "</tns:movie>"
        + _el("ratingCount", row["rating_count"]) + _el("avgRating", row["avg_rating"])
        + _el("minRating", row["min_rating"]) + _el("maxRating", row["max_rating"])
        + _el("medianRating", row["median_rating"]) + _el("stddevRating", row["stddev_rating"])
        + f"<tns:scoreDistribution>{entries}</tns:scoreDistribution>"
        "</tns:ObtenerEstadisticasPeliculaResponse>"
    )
    return Response(_envelope(body), media_type=XML_TYPE)
