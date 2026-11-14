{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasProformaValoracion                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Traduce las líneas de traspasos pendientes al modelo de simulación de    }
{    valoración (el mismo de inventarios) y convierte la simulación aceptada  }
{    en la valoración por movimiento que consume el repositorio.               }
{    Sin VCL, datasets ni persistencia.                                        }
{******************************************************************************}
unit inLibFacturasProformaValoracion;

interface

uses
  inLibFacturasProformaIntf,
  inLibInventariosRevalorizacion;

// Precio de partida de una línea TA: el PMP actual de la empresa emisora y,
// si no consta, el coste con el que salió el movimiento.
function PrecioBaseTraspaso(
  APrecioMedioEmpresa: Currency;
  ACosteMovimiento: Currency): Currency;
// Etiqueta visible de la línea: operación/línea del traspaso.
function EtiquetaLineaTraspaso(
  const ALinea: TLineaTraspasoPendiente): string;
// Clave con la que se valora la línea: su ClaveValoracion o, si no trae,
// el movimiento.
function ClaveValoracionLineaTraspaso(
  const ALinea: TLineaTraspasoPendiente): string;
function ConvertirLineasTraspasoARevalorizacion(
  const ALineas: TLineasTraspasoPendientes):
  TLineasBaseRevalorizacionInventario;
// Una entrada por línea presentada: las simuladas llevan el precio
// simulado y el resto su precio de partida.
function ConstruirValoracionTraspasos(
  const ALineas: TLineasTraspasoPendientes;
  const ASimulacion: TSimulacionRevalorizacionInventario):
  TValoracionTraspasos;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  inLibMargenVinculadas;

function PrecioBaseTraspaso(
  APrecioMedioEmpresa: Currency;
  ACosteMovimiento: Currency): Currency;
begin
  if APrecioMedioEmpresa > 0 then
    Result := APrecioMedioEmpresa
  else if ACosteMovimiento > 0 then
    Result := ACosteMovimiento
  else
    Result := 0;
end;

function EtiquetaLineaTraspaso(
  const ALinea: TLineaTraspasoPendiente): string;
begin
  Result := Trim(ALinea.NumeroOperacion);
  if Trim(ALinea.Linea) <> '' then
  begin
    if Result <> '' then
      Result := Result + '/';
    Result := Result + Trim(ALinea.Linea);
  end;
end;

function ClaveValoracionLineaTraspaso(
  const ALinea: TLineaTraspasoPendiente): string;
begin
  Result := ALinea.ClaveValoracion;
  if Trim(Result) = '' then
    Result := ALinea.NumeroMovimiento;
end;

function ConvertirLineasTraspasoARevalorizacion(
  const ALineas: TLineasTraspasoPendientes):
  TLineasBaseRevalorizacionInventario;
var
  iLinea: Integer;
begin
  SetLength(Result, Length(ALineas));
  for iLinea := 0 to High(ALineas) do
  begin
    Result[iLinea] := Default(TLineaBaseRevalorizacionInventario);
    Result[iLinea].Clave := ClaveValoracionLineaTraspaso(ALineas[iLinea]);
    Result[iLinea].Linea := EtiquetaLineaTraspaso(ALineas[iLinea]);
    Result[iLinea].CodigoArticulo := ALineas[iLinea].CodigoArticulo;
    Result[iLinea].CodigoUnidad := ALineas[iLinea].CodigoUnidad;
    Result[iLinea].Descripcion := ALineas[iLinea].Descripcion;
    Result[iLinea].CantidadTeorica := ALineas[iLinea].Cantidad;
    Result[iLinea].CantidadFisica := ALineas[iLinea].Cantidad;
    Result[iLinea].PrecioMedioActual := PrecioBaseTraspaso(
      ALineas[iLinea].PrecioMedioEmpresa,
      ALineas[iLinea].CosteMovimiento);
    Result[iLinea].PrecioMedioNuevoAnterior :=
      Result[iLinea].PrecioMedioActual;
    Result[iLinea].EsPrecioMedioCorregido := False;
    Result[iLinea].PrecioUltimaCompra :=
      ALineas[iLinea].PrecioUltimaCompra;
    Result[iLinea].AntiguedadMeses := ALineas[iLinea].AntiguedadMeses;
    Result[iLinea].PrecioVentaDestino :=
      ALineas[iLinea].PrecioVentaDestino;
    Result[iLinea].VentaDestinoACero := ALineas[iLinea].VentaACero;
    Result[iLinea].VentaDestinoSinLinea := ALineas[iLinea].VentaSinLinea;
  end;
end;

function ConstruirValoracionTraspasos(
  const ALineas: TLineasTraspasoPendientes;
  const ASimulacion: TSimulacionRevalorizacionInventario):
  TValoracionTraspasos;
var
  Indices: TDictionary<string, Integer>;
  iLinea: Integer;
  iIndice: Integer;
begin
  SetLength(Result, Length(ALineas));
  Indices := TDictionary<string, Integer>.Create;
  try
    for iLinea := 0 to High(ALineas) do
    begin
      Result[iLinea].NumeroMovimiento :=
        ClaveValoracionLineaTraspaso(ALineas[iLinea]);
      Result[iLinea].Precio := PrecioBaseTraspaso(
        ALineas[iLinea].PrecioMedioEmpresa,
        ALineas[iLinea].CosteMovimiento);
      Indices.AddOrSetValue(Result[iLinea].NumeroMovimiento, iLinea);
    end;
    for iLinea := 0 to High(ASimulacion.Lineas) do
    begin
      if Indices.TryGetValue(
           ASimulacion.Lineas[iLinea].Base.Clave, iIndice) then
        Result[iIndice].Precio :=
          ASimulacion.Lineas[iLinea].PrecioMedioNuevo;
    end;
    // Ni las simuladas ni las que se quedan a precio base pueden salir
    // por encima de lo que la tienda cobró por ellas.
    for iLinea := 0 to High(ALineas) do
    begin
      Result[iLinea].Precio := PrecioConTopeVenta(
        Result[iLinea].Precio, ALineas[iLinea].PrecioVentaDestino);
    end;
  finally
    FreeAndNil(Indices);
  end;
end;

end.
