{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMtoGenAplicacion                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina el guardado transaccional de un mantenimiento.                   }
{******************************************************************************}
unit inLibMtoGenAplicacion;

interface

uses
  inLibMtoGenAplicacionIntf;

function CrearCasoUsoGuardadoMtoGen(
  const AUnidadTrabajo: IUnidadTrabajoMtoGen): ICasoUsoGuardadoMtoGen;

implementation

uses
  System.SysUtils;

type
  TCasoUsoGuardadoMtoGen = class(
    TInterfacedObject,
    ICasoUsoGuardadoMtoGen)
  private
    FUnidadTrabajo: IUnidadTrabajoMtoGen;
  public
    constructor Create(const AUnidadTrabajo: IUnidadTrabajoMtoGen);
    function Ejecutar(const AGuardar: TProc): TResultadoGuardadoMtoGen;
  end;

function CrearCasoUsoGuardadoMtoGen(
  const AUnidadTrabajo: IUnidadTrabajoMtoGen): ICasoUsoGuardadoMtoGen;
begin
  Result := TCasoUsoGuardadoMtoGen.Create(AUnidadTrabajo);
end;

constructor TCasoUsoGuardadoMtoGen.Create(
  const AUnidadTrabajo: IUnidadTrabajoMtoGen);
begin
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  inherited Create;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TCasoUsoGuardadoMtoGen.Ejecutar(
  const AGuardar: TProc): TResultadoGuardadoMtoGen;
var
  EsPropia: Boolean;
begin
  if not Assigned(AGuardar) then
    raise EArgumentNilException.Create('AGuardar');
  Result := rgmAbortado;
  EsPropia := not FUnidadTrabajo.EstaActiva;
  if EsPropia then
    FUnidadTrabajo.Iniciar;
  try
    try
      AGuardar();
      if EsPropia then
        FUnidadTrabajo.Confirmar;
      Result := rgmGuardado;
    except
      on E: EAbort do
      begin
        if EsPropia and FUnidadTrabajo.EstaActiva then
          FUnidadTrabajo.Revertir;
      end;
    end;
  except
    if EsPropia and FUnidadTrabajo.EstaActiva then
      FUnidadTrabajo.Revertir;
    raise;
  end;
end;

end.
