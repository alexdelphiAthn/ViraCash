{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContratoMtoGenHerencia                                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Agrupa los hooks heredables de TfrmMtoGen por orden de inherited.         }
{******************************************************************************}
unit inLibContratoMtoGenHerencia;

interface

uses
  inLibMtoGenAplicacionIntf;

type
  TFamiliaHookMtoGen = (
    fhmExtensionPrimero,
    fhmCoordinacion,
    fhmExtensionOpcional,
    fhmSustitucion);

function FamiliaHookMtoGen(AHook: THookMtoGen): TFamiliaHookMtoGen;
function OrdenFamiliaHookMtoGen(
  AFamilia: TFamiliaHookMtoGen): TOrdenInheritedHookMtoGen;

implementation

uses
  System.SysUtils;

function FamiliaHookMtoGen(AHook: THookMtoGen): TFamiliaHookMtoGen;
begin
  case AHook of
    hmgAplicarEtiquetas,
    hmgResetForm,
    hmgCargarPerfilesParticulares:
      Result := fhmExtensionPrimero;
    hmgCrearTablaPrincipal,
    hmgPrepararBusquedaExterna:
      Result := fhmCoordinacion;
    hmgRecogerPerfilesParticulares,
    hmgAplicarLayoutBusqueda,
    hmgTrasPrecarga,
    hmgTrasErrorPrecarga:
      Result := fhmExtensionOpcional;
    hmgResolverArticuloActivo,
    hmgDataSourcesFoto,
    hmgNombreCampoActivo,
    hmgContarHijosActivos,
    hmgDescripcionHijos,
    hmgRestriccionUsuario:
      Result := fhmSustitucion;
  else
    raise EArgumentOutOfRangeException.Create('AHook');
  end;
end;

function OrdenFamiliaHookMtoGen(
  AFamilia: TFamiliaHookMtoGen): TOrdenInheritedHookMtoGen;
begin
  case AFamilia of
    fhmExtensionPrimero:
      Result := oihPrimero;
    fhmCoordinacion:
      Result := oihObligatorio;
    fhmExtensionOpcional:
      Result := oihOpcional;
    fhmSustitucion:
      Result := oihNoAplicable;
  else
    raise EArgumentOutOfRangeException.Create('AFamilia');
  end;
end;

end.
