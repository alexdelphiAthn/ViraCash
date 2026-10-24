{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasPresentadorCabecera                              }
{    Tipo:       Presentador (sin VCL)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decide qué controles de la cabecera de factura quedan operativos.         }
{******************************************************************************}
unit inLibFacturasPresentadorCabecera;

interface

type
  TEdicionCabeceraFactura = (
    ecfNavegando,
    ecfInsertando,
    ecfEditando);
  TSituacionCabeceraFactura = record
    Edicion: TEdicionCabeceraFactura;
    SinVerifactu: Boolean;
  end;
  TControlesCabeceraFactura = record
    // Numero y serie solo se teclean en el alta.
    NumeroSerieEditables: Boolean;
    // Tarifa y canal de IVA se congelan en cuanto deja de ser un alta.
    BloquearTarifaCanal: Boolean;
    EnEdicion: Boolean;
    PuedeNuevaFactura: Boolean;
    PuedeRectificar: Boolean;
    PuedeConsolidar: Boolean;
    // En modo SIN el borrador se imprime aunque se este editando: al
    // pulsar Imprimir se graban antes los cambios pendientes.
    PuedeImprimir: Boolean;
    // Fuera de edicion mandan la fase fiscal y la consolidacion, no el
    // estado del dataset.
    RevisarFaseFiscal: Boolean;
  end;

function CrearSituacionCabeceraFactura(
  AEdicion: TEdicionCabeceraFactura;
  ASinVerifactu: Boolean): TSituacionCabeceraFactura;
function CalcularControlesCabeceraFactura(
  const ASituacion: TSituacionCabeceraFactura): TControlesCabeceraFactura;

implementation

function CrearSituacionCabeceraFactura(
  AEdicion: TEdicionCabeceraFactura;
  ASinVerifactu: Boolean): TSituacionCabeceraFactura;
begin
  Result := Default(TSituacionCabeceraFactura);
  Result.Edicion := AEdicion;
  Result.SinVerifactu := ASinVerifactu;
end;

function CalcularControlesCabeceraFactura(
  const ASituacion: TSituacionCabeceraFactura): TControlesCabeceraFactura;
begin
  Result := Default(TControlesCabeceraFactura);
  Result.NumeroSerieEditables := ASituacion.Edicion = ecfInsertando;
  Result.BloquearTarifaCanal := ASituacion.Edicion <> ecfInsertando;
  Result.EnEdicion := ASituacion.Edicion in [ecfInsertando, ecfEditando];
  Result.PuedeNuevaFactura := not Result.EnEdicion;
  Result.PuedeRectificar := not Result.EnEdicion;
  Result.PuedeConsolidar := not Result.EnEdicion;
  Result.PuedeImprimir := Result.EnEdicion and ASituacion.SinVerifactu;
  Result.RevisarFaseFiscal := not Result.EnEdicion;
end;

end.
