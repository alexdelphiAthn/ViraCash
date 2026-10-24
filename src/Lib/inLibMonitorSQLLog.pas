{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMonitorSQLLog                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador entre el servicio de monitor SQL y el registro TLog.            }
{******************************************************************************}
unit inLibMonitorSQLLog;

interface

uses
  inLibLogIntf,
  inLibMonitorSQLIntf;

type
  TRegistroMonitorSQLLog = class(
    TInterfacedObject,
    IRegistroMonitorSQL
  )
  private
    FRegistroLog: IRegistroLog;
    FVisor: IVisorMonitorSQL;
    function GetMonitorizacionActiva: Boolean;
  public
    constructor Create(
      const ARegistroLog: IRegistroLog;
      const AVisor: IVisorMonitorSQL);
    procedure EstablecerVisible(AVisible: Boolean);
    procedure Invalidar;
    procedure RegistrarSQL(
      const ASQL: string;
      ATiempoMs: Int64;
      AOk: Boolean;
      const AError: string
    );
    procedure MostrarSQL(const ASQL: string);
  end;

implementation

constructor TRegistroMonitorSQLLog.Create(
  const ARegistroLog: IRegistroLog;
  const AVisor: IVisorMonitorSQL);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
  FVisor := AVisor;
end;

procedure TRegistroMonitorSQLLog.EstablecerVisible(AVisible: Boolean);
begin
  if Assigned(FVisor) then
    FVisor.EstablecerVisible(AVisible);
end;

procedure TRegistroMonitorSQLLog.Invalidar;
begin
  FVisor := nil;
  FRegistroLog := nil;
end;

function TRegistroMonitorSQLLog.GetMonitorizacionActiva: Boolean;
begin
  Result := Assigned(FRegistroLog) and
            FRegistroLog.ObtenerEvidencias.SQLActivo;
end;

procedure TRegistroMonitorSQLLog.RegistrarSQL(
  const ASQL: string;
  ATiempoMs: Int64;
  AOk: Boolean;
  const AError: string);
begin
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarSQL(
      ASQL,
      ATiempoMs,
      -1,
      AOk,
      AError);
end;

procedure TRegistroMonitorSQLLog.MostrarSQL(const ASQL: string);
begin
  if Assigned(FVisor) then
    FVisor.MostrarSQL(ASQL);
end;

end.
