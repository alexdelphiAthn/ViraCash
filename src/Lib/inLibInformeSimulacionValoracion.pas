{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInformeSimulacionValoracion                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara los datos del listado de una simulación de valoración: líneas    }
{    con precio de última compra, PMP y precio simulado, sin VCL ni datasets.  }
{    Lo comparten el informe FastReport y la hoja Excel.                       }
{******************************************************************************}
unit inLibInformeSimulacionValoracion;

interface

uses
  inLibInventariosRevalorizacion;

type
  TLineaInformeSimulacionValoracion = record
    Linea: string;
    CodigoArticulo: string;
    CodigoUnidad: string;
    Descripcion: string;
    Unidades: Currency;
    PrecioUltimaCompra: Currency;
    PrecioMedio: Currency;
    Simulada: Boolean;
    PrecioSimulado: Currency;
  end;

  TLineasInformeSimulacionValoracion =
    array of TLineaInformeSimulacionValoracion;

  TDatosInformeSimulacionValoracion = record
    Titulo: string;
    Identificacion: string;
    Operacion: string;
    // 'PMP almacén' en inventarios, 'PMP empresa' en traspasos.
    CaptionPrecioMedio: string;
    Fecha: TDateTime;
    Lineas: TLineasInformeSimulacionValoracion;
    NumeroLineasSimuladas: Integer;
    ValorAnterior: Currency;
    ValorSimulado: Currency;
    DiferenciaValor: Currency;
  end;

resourcestring
  SNombreHojaInformeValoracion = 'Valoración';
  SCaptionFechaInformeValoracion = 'Fecha:';
  SCaptionColLineaInformeValoracion = 'Línea';
  SCaptionColArticuloInformeValoracion = 'Artículo';
  SCaptionColSkuInformeValoracion = 'SKU';
  SCaptionColDescripcionInformeValoracion = 'Descripción';
  SCaptionColUnidadesInformeValoracion = 'Unidades';
  SCaptionColUltimaCompraInformeValoracion = 'P. última compra';
  SCaptionColPrecioMedioAlmacenInformeValoracion = 'PMP almacén';
  SCaptionColPrecioMedioEmpresaInformeValoracion = 'PMP empresa';
  SCaptionColPrecioSimuladoInformeValoracion = 'P. simulado';
  SCaptionColSimuladaInformeValoracion = 'Simulada';
  STextoSiInformeValoracion = 'Sí';
  SCaptionLineasSimuladasInformeValoracion = 'Líneas simuladas:';
  SCaptionValorAnteriorInformeValoracion = 'Valor anterior:';
  SCaptionValorSimuladoInformeValoracion = 'Valor simulado:';
  SCaptionDiferenciaInformeValoracion = 'Diferencia:';

// Clave con la que se relacionan las líneas base y las simuladas: la clave
// opaca del llamador o, si no la hay, el número de línea.
function ClaveLineaRevalorizacion(
  const ALinea: TLineaBaseRevalorizacionInventario): string;
// Lista todas las líneas presentadas; las incluidas en la simulación llevan
// el precio simulado. Título, identificación, operación, caption del PMP y
// fecha los rellena el llamador.
function ConstruirDatosInformeSimulacionValoracion(
  const ALineasBase: TLineasBaseRevalorizacionInventario;
  const ASimulacion: TSimulacionRevalorizacionInventario):
  TDatosInformeSimulacionValoracion;

implementation

uses
  System.SysUtils,
  System.Generics.Collections;

function ClaveLineaRevalorizacion(
  const ALinea: TLineaBaseRevalorizacionInventario): string;
begin
  Result := ALinea.Clave;
  if Result = '' then
    Result := ALinea.Linea;
end;

function ConstruirDatosInformeSimulacionValoracion(
  const ALineasBase: TLineasBaseRevalorizacionInventario;
  const ASimulacion: TSimulacionRevalorizacionInventario):
  TDatosInformeSimulacionValoracion;
var
  Indices: TDictionary<string, Integer>;
  iLinea: Integer;
  iIndice: Integer;
begin
  Result := Default(TDatosInformeSimulacionValoracion);
  SetLength(Result.Lineas, Length(ALineasBase));
  Indices := TDictionary<string, Integer>.Create;
  try
    for iLinea := 0 to High(ALineasBase) do
    begin
      Result.Lineas[iLinea].Linea := ALineasBase[iLinea].Linea;
      Result.Lineas[iLinea].CodigoArticulo :=
        ALineasBase[iLinea].CodigoArticulo;
      Result.Lineas[iLinea].CodigoUnidad :=
        ALineasBase[iLinea].CodigoUnidad;
      Result.Lineas[iLinea].Descripcion :=
        ALineasBase[iLinea].Descripcion;
      Result.Lineas[iLinea].Unidades :=
        ALineasBase[iLinea].CantidadFisica;
      Result.Lineas[iLinea].PrecioUltimaCompra :=
        ALineasBase[iLinea].PrecioUltimaCompra;
      Result.Lineas[iLinea].PrecioMedio :=
        ALineasBase[iLinea].PrecioMedioActual;
      Indices.AddOrSetValue(
        ClaveLineaRevalorizacion(ALineasBase[iLinea]), iLinea);
    end;
    for iLinea := 0 to High(ASimulacion.Lineas) do
    begin
      if Indices.TryGetValue(
           ClaveLineaRevalorizacion(ASimulacion.Lineas[iLinea].Base),
           iIndice) then
      begin
        Result.Lineas[iIndice].Simulada := True;
        Result.Lineas[iIndice].PrecioSimulado :=
          ASimulacion.Lineas[iLinea].PrecioMedioNuevo;
      end;
    end;
  finally
    FreeAndNil(Indices);
  end;
  Result.NumeroLineasSimuladas := ASimulacion.Resumen.NumeroLineas;
  Result.ValorAnterior := ASimulacion.Resumen.ValorAnterior;
  Result.ValorSimulado := ASimulacion.Resumen.ValorNuevo;
  Result.DiferenciaValor := ASimulacion.Resumen.DiferenciaValor;
end;

end.
