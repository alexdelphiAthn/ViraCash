{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaPantallaHistoricos                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Graba perfiles de históricos dentro de una unidad de trabajo explícita.  }
{******************************************************************************}
unit inLibCajaPantallaHistoricos;

interface

uses
  inLibPerfilesUsuarioIntf,
  inLibCajaPantallaHistoricosIntf;

type
  TGrabadorPerfilesHistoricoCaja = class(
    TInterfacedObject,
    IGrabadorPerfilesHistoricoCaja)
  private
    FUnidadTrabajo: IUnidadTrabajoPerfilesCaja;
    FEscritor: IEscritorPerfilesUsuario;
  public
    constructor Create(
      const AUnidadTrabajo: IUnidadTrabajoPerfilesCaja;
      const AEscritor: IEscritorPerfilesUsuario);
    destructor Destroy; override;
    procedure Grabar(const APerfiles: TPerfilList);
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorUnidadTrabajoPerfilesCajaNoAsignada =
    'La unidad de trabajo de perfiles de Caja no está asignada.';
  SErrorEscritorPerfilesCajaNoAsignado =
    'El escritor de perfiles de Caja no está asignado.';

constructor TGrabadorPerfilesHistoricoCaja.Create(
  const AUnidadTrabajo: IUnidadTrabajoPerfilesCaja;
  const AEscritor: IEscritorPerfilesUsuario);
begin
  inherited Create;
  if not Assigned(AUnidadTrabajo) then
    raise Exception.Create(SErrorUnidadTrabajoPerfilesCajaNoAsignada);
  if not Assigned(AEscritor) then
    raise Exception.Create(SErrorEscritorPerfilesCajaNoAsignado);
  FUnidadTrabajo := AUnidadTrabajo;
  FEscritor := AEscritor;
end;

destructor TGrabadorPerfilesHistoricoCaja.Destroy;
begin
  FEscritor := nil;
  FUnidadTrabajo := nil;
  inherited;
end;

procedure TGrabadorPerfilesHistoricoCaja.Grabar(
  const APerfiles: TPerfilList);
begin
  FUnidadTrabajo.Iniciar;
  try
    FEscritor.GrabarPerfiles(APerfiles);
    FUnidadTrabajo.Confirmar;
  except
    FUnidadTrabajo.Revertir;
    raise;
  end;
end;

end.
