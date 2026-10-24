{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMtoGenAplicacionIntf                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de aplicación comunes a los mantenimientos.                    }
{******************************************************************************}
unit inLibMtoGenAplicacionIntf;

interface

uses
  System.SysUtils, System.Variants;

type
  TResultadoGuardadoMtoGen = (
    rgmGuardado,
    rgmAbortado);

  IUnidadTrabajoMtoGen = interface
    ['{C4DA3785-31A6-475D-A253-EC72ED8123B0}']
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

  ICasoUsoGuardadoMtoGen = interface
    ['{5085E345-124B-40A8-9F8D-83154EF42014}']
    function Ejecutar(const AGuardar: TProc): TResultadoGuardadoMtoGen;
  end;

  TValorAltaRapidaMtoGen = record
    Campo: string;
    Valor: Variant;
    Opciones: string;
  end;

  TConfiguracionAltaRapidaMtoGen = record
    Tabla: string;
    CampoCodigo: string;
    CampoDescripcion: string;
    TipoDocumentoContador: string;
    Valores: TArray<TValorAltaRapidaMtoGen>;
  end;

  TResultadoAltaRapidaMtoGen = record
    Exito: Boolean;
    Codigo: string;
    Error: string;
  end;

  THookMtoGen = (
    hmgAplicarEtiquetas,
    hmgCrearTablaPrincipal,
    hmgResetForm,
    hmgCargarPerfilesParticulares,
    hmgRecogerPerfilesParticulares,
    hmgPrepararBusquedaExterna,
    hmgAplicarLayoutBusqueda,
    hmgResolverArticuloActivo,
    hmgDataSourcesFoto,
    hmgNombreCampoActivo,
    hmgContarHijosActivos,
    hmgDescripcionHijos,
    hmgTrasPrecarga,
    hmgTrasErrorPrecarga,
    hmgRestriccionUsuario);

  TOrdenInheritedHookMtoGen = (
    oihNoAplicable,
    oihPrimero,
    oihObligatorio,
    oihOpcional);

  TContratoHookMtoGen = record
    Nombre: string;
    OrdenInherited: TOrdenInheritedHookMtoGen;
    SeEjecutaEnHiloPrincipal: Boolean;
  end;

function ContratoHookMtoGen(AHook: THookMtoGen): TContratoHookMtoGen;

implementation

function ContratoHookMtoGen(AHook: THookMtoGen): TContratoHookMtoGen;
begin
  Result.Nombre := '';
  Result.OrdenInherited := oihNoAplicable;
  Result.SeEjecutaEnHiloPrincipal := True;
  case AHook of
    hmgAplicarEtiquetas:
    begin
      Result.Nombre := 'AplicarEtiquetas';
      Result.OrdenInherited := oihPrimero;
    end;
    hmgCrearTablaPrincipal:
    begin
      Result.Nombre := 'CrearTablaPrincipal';
      Result.OrdenInherited := oihObligatorio;
    end;
    hmgResetForm:
    begin
      Result.Nombre := 'ResetForm';
      Result.OrdenInherited := oihPrimero;
    end;
    hmgCargarPerfilesParticulares:
    begin
      Result.Nombre := 'CargarPerfilesParticulares';
      Result.OrdenInherited := oihPrimero;
    end;
    hmgRecogerPerfilesParticulares:
    begin
      Result.Nombre := 'RecogerPerfilesParticulares';
      Result.OrdenInherited := oihOpcional;
    end;
    hmgPrepararBusquedaExterna:
    begin
      Result.Nombre := 'PrepararBusquedaExterna';
      Result.OrdenInherited := oihObligatorio;
    end;
    hmgAplicarLayoutBusqueda:
    begin
      Result.Nombre := 'AplicarLayoutInstanciaBusqueda';
      Result.OrdenInherited := oihOpcional;
    end;
    hmgResolverArticuloActivo:
      Result.Nombre := 'ResolverArtSkuActivo';
    hmgDataSourcesFoto:
      Result.Nombre := 'DataSourcesParaFoto';
    hmgNombreCampoActivo:
      Result.Nombre := 'NombreCampoESACTIVO';
    hmgContarHijosActivos:
      Result.Nombre := 'ContarHijosActivos';
    hmgDescripcionHijos:
      Result.Nombre := 'DescripcionHijos';
    hmgTrasPrecarga:
    begin
      Result.Nombre := 'TrasPrecargaAsync';
      Result.OrdenInherited := oihOpcional;
    end;
    hmgTrasErrorPrecarga:
    begin
      Result.Nombre := 'TrasErrorPrecargaAsync';
      Result.OrdenInherited := oihOpcional;
    end;
    hmgRestriccionUsuario:
      Result.Nombre := 'SqlRestriccionUsuario';
  end;
end;

end.
