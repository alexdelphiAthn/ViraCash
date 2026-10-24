{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopCierre                                        }
{    Tipo:       Caso de uso                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       15/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Coordina el cierre seguro del consumidor de la cola PrestaShop.           }
{******************************************************************************}
unit inLibPrestaShopCierre;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  TDecisionCierrePrestaShop = (
    dcpEsperar,
    dcpCerrarDeTodosModos,
    dcpCancelar);

  TConsultarDecisionCierrePrestaShop = reference to function:
    TDecisionCierrePrestaShop;

  ICierreColaPrestaShop = interface
    ['{88239B35-7025-45E5-8FDB-2CE7728E23CF}']
    function BloquearNuevasReclamaciones: Boolean;
    procedure CancelarCierre;
    procedure DetenerTrasTrabajoActual;
    procedure DetenerLiberandoTrabajoActual;
  end;

  TControlTrabajoPrestaShop = class
  private
    FExclusion: TCriticalSection;
    FLiberarTrabajo: Boolean;
    FReclamacionesBloqueadas: Boolean;
    FTrabajoActivo: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function BloquearNuevasReclamaciones: Boolean;
    procedure CancelarCierre;
    function DebeLiberarTrabajo: Boolean;
    procedure FinalizarTrabajo;
    function IntentarIniciarTrabajo: Boolean;
    function PermiteNuevasReclamaciones: Boolean;
    procedure SolicitarCerrarDeTodosModos;
    procedure SolicitarEsperar;
  end;

function IntentarCerrarColaPrestaShop(
  const ACola: ICierreColaPrestaShop;
  const AConsultarDecision: TConsultarDecisionCierrePrestaShop): Boolean;

implementation

function IntentarCerrarColaPrestaShop(
  const ACola: ICierreColaPrestaShop;
  const AConsultarDecision: TConsultarDecisionCierrePrestaShop): Boolean;
var
  oDecision: TDecisionCierrePrestaShop;
begin
  Result := True;
  if Assigned(ACola) and ACola.BloquearNuevasReclamaciones then
  begin
    if not Assigned(AConsultarDecision) then
    begin
      ACola.CancelarCierre;
      raise EArgumentNilException.Create('AConsultarDecision');
    end;
    try
      oDecision := AConsultarDecision();
      case oDecision of
        dcpEsperar:
          ACola.DetenerTrasTrabajoActual;
        dcpCerrarDeTodosModos:
          ACola.DetenerLiberandoTrabajoActual;
        dcpCancelar:
          begin
            ACola.CancelarCierre;
            Result := False;
          end;
      end;
    except
      ACola.CancelarCierre;
      raise;
    end;
  end;
end;

{ TControlTrabajoPrestaShop }

constructor TControlTrabajoPrestaShop.Create;
begin
  inherited Create;
  FExclusion := TCriticalSection.Create;
end;

destructor TControlTrabajoPrestaShop.Destroy;
begin
  FreeAndNil(FExclusion);
  inherited;
end;

function TControlTrabajoPrestaShop.BloquearNuevasReclamaciones: Boolean;
begin
  FExclusion.Acquire;
  try
    FReclamacionesBloqueadas := True;
    Result := FTrabajoActivo;
  finally
    FExclusion.Release;
  end;
end;

procedure TControlTrabajoPrestaShop.CancelarCierre;
begin
  FExclusion.Acquire;
  try
    FLiberarTrabajo := False;
    FReclamacionesBloqueadas := False;
  finally
    FExclusion.Release;
  end;
end;

function TControlTrabajoPrestaShop.DebeLiberarTrabajo: Boolean;
begin
  FExclusion.Acquire;
  try
    Result := FLiberarTrabajo and FTrabajoActivo;
  finally
    FExclusion.Release;
  end;
end;

procedure TControlTrabajoPrestaShop.FinalizarTrabajo;
begin
  FExclusion.Acquire;
  try
    FTrabajoActivo := False;
  finally
    FExclusion.Release;
  end;
end;

function TControlTrabajoPrestaShop.IntentarIniciarTrabajo: Boolean;
begin
  FExclusion.Acquire;
  try
    Result := not FReclamacionesBloqueadas;
    if Result then
      FTrabajoActivo := True;
  finally
    FExclusion.Release;
  end;
end;

function TControlTrabajoPrestaShop.PermiteNuevasReclamaciones: Boolean;
begin
  FExclusion.Acquire;
  try
    Result := not FReclamacionesBloqueadas;
  finally
    FExclusion.Release;
  end;
end;

procedure TControlTrabajoPrestaShop.SolicitarCerrarDeTodosModos;
begin
  FExclusion.Acquire;
  try
    FReclamacionesBloqueadas := True;
    FLiberarTrabajo := FTrabajoActivo;
  finally
    FExclusion.Release;
  end;
end;

procedure TControlTrabajoPrestaShop.SolicitarEsperar;
begin
  FExclusion.Acquire;
  try
    FReclamacionesBloqueadas := True;
    FLiberarTrabajo := False;
  finally
    FExclusion.Release;
  end;
end;

end.
