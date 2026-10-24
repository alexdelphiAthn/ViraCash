{******************************************************************************}
{                                                                              }
{  Módulo:       inLibErroresHttp                                              }
{    Tipo:       Librería                                                      }
{                                                                              }
{  Descripción:                                                                }
{    Clasifica fallos temporales del transporte HTTP. Con red intermitente     }
{    ningún fallo de transporte debe consumir intentos de las colas: solo     }
{    cuenta una respuesta válida del propio destino que rechace el envío.     }
{******************************************************************************}
unit inLibErroresHttp;

interface

uses
  System.SysUtils;

type
  EConexionHttpTemporal = class(Exception);
  // El llamador canceló la petición antes de recibir la respuesta. No es
  // un fallo del servidor: el servidor pudo procesarla o no.
  EPeticionHttpCancelada = class(Exception);

function EsFalloTemporalTransporteHttp(
  const AError: Exception): Boolean;
function EsEstadoHttpTemporal(
  AEstado: Integer): Boolean;

implementation

uses
  System.Net.HttpClient;

// Cualquier fallo de la capa HTTP es de transporte: conexión rechazada,
// DNS, timeout, corte a mitad de respuesta, cabeceras ilegibles o TLS.
// Se incluye TLS porque un portal cautivo que intercepta HTTPS se
// manifiesta como error de certificado. Un fallo permanente (p. ej. un
// certificado caducado) queda reintentándose sin descartar el envío:
// la red nunca debe hacer perder un envío. En la RTL de Delphi 13 las
// excepciones de cliente, petición y respuesta NO descienden de
// ENetHTTPException (heredan de ENetURI*Exception), así que se enumeran
// una a una. Una URI mal formada lanza ENetURIException, que no está en
// la lista. BaseException: TRESTRequest envuelve la causa real.
function EsFalloTemporalTransporteHttp(
  const AError: Exception): Boolean;
var
  oErrorBase: Exception;
begin
  Result := Assigned(AError);
  if Result then
  begin
    oErrorBase := AError.BaseException;
    Result := (oErrorBase is ENetHTTPException) or
              (oErrorBase is ENetHTTPClientException) or
              (oErrorBase is ENetHTTPRequestException) or
              (oErrorBase is ENetHTTPResponseException) or
              (oErrorBase is ENetHTTPCertificateException);
  end;
end;

// Estados que emiten proxies, balanceadores o el propio servicio cuando
// está saturado o en mantenimiento: la petición no se ha procesado.
function EsEstadoHttpTemporal(
  AEstado: Integer): Boolean;
begin
  Result := (AEstado = 408) or
            (AEstado = 429) or
            (AEstado = 502) or
            (AEstado = 503) or
            (AEstado = 504);
end;

end.
