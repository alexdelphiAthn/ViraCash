{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionVista                           }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Estado de vista explicito de la consulta de stock: articulo y SKU         }
{    activos mas las guardas de reentrada de los eventos de entrada. Sin       }
{    VCL, sin SQL: se prueba como estado puro.                                 }
{******************************************************************************}
unit inLibStockConsultaPresentacionVista;

interface

type
  TEstadoVistaStockConsulta = record
    CodigoArticulo: string;
    CodigoSku: string;
    VerCoste: Boolean;
    ActualizandoArticulo: Boolean;
    ResolviendoEntrada: Boolean;
    SilenciandoCambioVista: Boolean;
    procedure Limpiar;
    procedure FijarArticulo(const ACodigoArticulo, ACodigoSku: string);
    function HayArticulo: Boolean;
    function AdmiteResolverEntrada: Boolean;
    function AdmiteCambioTextoArticulo: Boolean;
    function AdmiteSeleccionCoincidencia: Boolean;
    function AdmiteCambioVista: Boolean;
    function ClaveUnidadColor(const AColor: string): string;
  end;

implementation

uses
  System.SysUtils;

procedure TEstadoVistaStockConsulta.Limpiar;
begin
  CodigoArticulo := '';
  CodigoSku := '';
  ActualizandoArticulo := False;
  ResolviendoEntrada := False;
  SilenciandoCambioVista := False;
end;

procedure TEstadoVistaStockConsulta.FijarArticulo(
  const ACodigoArticulo, ACodigoSku: string);
begin
  CodigoArticulo := ACodigoArticulo;
  CodigoSku := ACodigoSku;
end;

function TEstadoVistaStockConsulta.HayArticulo: Boolean;
begin
  Result := Trim(CodigoArticulo) <> '';
end;

// El texto del buscador solo se resuelve cuando ni la carga programada del
// articulo ni una resolucion previa estan en curso; asi un OnExit disparado
// por la propia carga no vuelve a entrar.
function TEstadoVistaStockConsulta.AdmiteResolverEntrada: Boolean;
begin
  Result := (not ActualizandoArticulo) and (not ResolviendoEntrada);
end;

function TEstadoVistaStockConsulta.AdmiteCambioTextoArticulo: Boolean;
begin
  Result := not ActualizandoArticulo;
end;

function TEstadoVistaStockConsulta.AdmiteSeleccionCoincidencia: Boolean;
begin
  Result := not ResolviendoEntrada;
end;

function TEstadoVistaStockConsulta.AdmiteCambioVista: Boolean;
begin
  Result := not SilenciandoCambioVista;
end;

// Clave ARTICULO/COLOR con la que se resuelve primero la foto propia del
// color y se recurre despues a la del articulo.
function TEstadoVistaStockConsulta.ClaveUnidadColor(
  const AColor: string): string;
begin
  Result := CodigoArticulo + '/' + AColor;
end;

end.
