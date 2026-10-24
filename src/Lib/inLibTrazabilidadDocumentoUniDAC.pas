{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTrazabilidadDocumentoUniDAC                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Composición de la trazabilidad de un documento con líneas (F-LOTEC-016): }
{    lee los interruptores y crea los adaptadores UniDAC y el modal VCL de     }
{    lotes sobre la conexión del módulo de datos. El formulario solo añade     }
{    el documento actual, sus líneas y su lector.                              }
{******************************************************************************}
unit inLibTrazabilidadDocumentoUniDAC;

interface

uses
  System.Classes, Uni, inLibParametrosIntf, inLibAsignacionLoteLectura,
  inLibTrazabilidadDocumento;

type
  // Tabla de líneas y campos de su clave (series repetidas en el documento).
  TTablaLineasLote = record
    Sufijo: string;
    Tabla: string;
    CampoSerie: string;
    CampoNumero: string;
  end;

function TablaLineasLote(const ASufijo, ATabla, ACampoSerie,
  ACampoNumero: string): TTablaLineasLote;
// Con todo apagado devuelve la activación apagada y ningún adaptador (el
// formulario no configura nada). Las salidas de ventas eligen el lote en
// el modal (sin FEFO automático) y exigen la serie.
function DocumentoTrazabilidadUniDAC(AOwner: TComponent;
  AConexion: TUniConnection; const AParametros: IParametrosAplicacion;
  ASentido: TSentidoLoteLectura;
  const ATabla: TTablaLineasLote): TDocumentoTrazabilidad;

implementation

uses
  inLibTrazabilidad, inLibMensajesVcl, UniDataLotesRepositorio,
  inMtoModalSeleccionLote;

function TablaLineasLote(const ASufijo, ATabla, ACampoSerie,
  ACampoNumero: string): TTablaLineasLote;
begin
  Result.Sufijo := ASufijo;
  Result.Tabla := ATabla;
  Result.CampoSerie := ACampoSerie;
  Result.CampoNumero := ACampoNumero;
end;

function DocumentoTrazabilidadUniDAC(AOwner: TComponent;
  AConexion: TUniConnection; const AParametros: IParametrosAplicacion;
  ASentido: TSentidoLoteLectura;
  const ATabla: TTablaLineasLote): TDocumentoTrazabilidad;
begin
  Result := Default(TDocumentoTrazabilidad);
  if Assigned(AParametros) then
    Result.Activacion := TActivacionTrazabilidad.Leer(AParametros);
  if Result.Activacion.AlgunModoActivo then
  begin
    Result.Lectura := CrearLecturaTrazabilidadArticuloUniDAC(AConexion);
    Result.Repositorio := CrearRepositorioLotesUniDAC(AConexion);
    Result.Selector := CrearSelectorLotesVisual(AOwner, Result.Repositorio);
    Result.Sentido := ASentido;
    Result.Sufijo := ATabla.Sufijo;
    Result.Tabla := ATabla.Tabla;
    Result.CampoSerie := ATabla.CampoSerie;
    Result.CampoNumero := ATabla.CampoNumero;
    Result.ExigirSerieEnVenta := True;
    Result.DiasAvisoGeneral := AParametros.GetInt(
      PARAMETRO_CADUCIDAD_DIAS_AVISO, CADUCIDAD_DIAS_AVISO_DEFECTO);
    Result.Avisar :=
      procedure(const AMensaje: string)
      begin
        ShowMessage_fza(AMensaje);
      end;
  end;
end;

end.
