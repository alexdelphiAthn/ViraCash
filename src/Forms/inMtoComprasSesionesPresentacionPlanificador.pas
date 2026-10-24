{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoComprasSesionesPresentacionPlanificador                  }
{    Tipo:       Adaptador VCL                                                 }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Implementa IPlanificadorDiferido sobre un TTimer. Aisla el unico          }
{    motivo por el que la sesion de compra necesitaba timers propios:          }
{    ejecutar una accion fuera del editor in-place del grid.                   }
{******************************************************************************}
unit inMtoComprasSesionesPresentacionPlanificador;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.ExtCtrls,
  inLibComprasSesionesPresentacionIntf;

type
  TPlanificadorDiferidoTimer = class(
    TInterfacedObject,
    IPlanificadorDiferido)
  private
    FTimer: TTimer;
    FAccion: TProc;
    procedure TiempoCumplido(ASender: TObject);
  public
    constructor Create(AIntervaloMs: Integer; const AAccion: TProc);
    destructor Destroy; override;
    procedure Rearmar;
    procedure Cancelar;
    function Armado: Boolean;
  end;

implementation

constructor TPlanificadorDiferidoTimer.Create(
  AIntervaloMs: Integer;
  const AAccion: TProc);
begin
  inherited Create;
  if not Assigned(AAccion) then
    raise EArgumentNilException.Create('AAccion');
  FAccion := AAccion;
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := False;
  if AIntervaloMs > 0 then
    FTimer.Interval := AIntervaloMs
  else
    FTimer.Interval := 1;
  FTimer.OnTimer := TiempoCumplido;
end;

destructor TPlanificadorDiferidoTimer.Destroy;
begin
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FTimer.OnTimer := nil;
  end;
  FreeAndNil(FTimer);
  FAccion := nil;
  inherited Destroy;
end;

procedure TPlanificadorDiferidoTimer.TiempoCumplido(ASender: TObject);
begin
  // Desarmar ANTES de ejecutar: la accion puede volver a rearmar el
  // planificador y ese rearme debe ganar.
  FTimer.Enabled := False;
  FAccion();
end;

procedure TPlanificadorDiferidoTimer.Rearmar;
begin
  FTimer.Enabled := False;
  FTimer.Enabled := True;
end;

procedure TPlanificadorDiferidoTimer.Cancelar;
begin
  FTimer.Enabled := False;
end;

function TPlanificadorDiferidoTimer.Armado: Boolean;
begin
  Result := FTimer.Enabled;
end;

end.
