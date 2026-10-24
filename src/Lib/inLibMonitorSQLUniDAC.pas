{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMonitorSQLUniDAC                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servicio que procesa las trazas producidas por TUniSQLMonitor.            }
{******************************************************************************}
unit inLibMonitorSQLUniDAC;

interface

uses
  UniSQLMonitor,
  inLibMonitorSQLIntf;

type
  TServicioMonitorSQLUniDAC = class(
    TInterfacedObject,
    IServicioMonitorSQL,
    IReceptorEventosMonitorSQL
  )
  private
    FMonitor: TUniSQLMonitor;
    FRegistro: IRegistroMonitorSQL;
    FSQLStartMs: UInt64;
    FSQLActual: string;
    FSQLPendiente: Boolean;
    procedure VolcarPendiente(AOk: Boolean; const AError: string);
  public
    constructor Create(
      AMonitor: TUniSQLMonitor;
      const ARegistro: IRegistroMonitorSQL
    );
    procedure CerrarPendiente;
    procedure EstablecerActivo(AActivo: Boolean);
    procedure Invalidar;
    procedure ProcesarEvento(
      const ATexto: string;
      AEvento: TEventoMonitorSQL
    );
  end;

implementation

uses
  Winapi.Windows;

constructor TServicioMonitorSQLUniDAC.Create(
  AMonitor: TUniSQLMonitor;
  const ARegistro: IRegistroMonitorSQL);
begin
  inherited Create;
  FMonitor := AMonitor;
  FRegistro := ARegistro;
  FSQLPendiente := False;
end;

procedure TServicioMonitorSQLUniDAC.CerrarPendiente;
begin
  VolcarPendiente(True, '');
end;

procedure TServicioMonitorSQLUniDAC.EstablecerActivo(AActivo: Boolean);
begin
  if not AActivo then
    FSQLPendiente := False;
  if Assigned(FMonitor) then
    FMonitor.Active := AActivo;
  if Assigned(FRegistro) then
    FRegistro.EstablecerVisible(AActivo);
end;

procedure TServicioMonitorSQLUniDAC.Invalidar;
begin
  if Assigned(FMonitor) then
    FMonitor.Active := False;
  FSQLPendiente := False;
  FSQLActual := '';
  FMonitor := nil;
  if Assigned(FRegistro) then
    FRegistro.Invalidar;
  FRegistro := nil;
end;

procedure TServicioMonitorSQLUniDAC.VolcarPendiente(
  AOk: Boolean;
  const AError: string);
var
  TiempoMs: UInt64;
begin
  if FSQLPendiente then
  begin
    TiempoMs := GetTickCount64 - FSQLStartMs;
    // TUniSQLMonitor no proporciona RowsAffected en su evento.
    if Assigned(FRegistro) then
      FRegistro.RegistrarSQL(
        FSQLActual,
        Int64(TiempoMs),
        AOk,
        AError);
    FSQLPendiente := False;
  end;
end;

procedure TServicioMonitorSQLUniDAC.ProcesarEvento(
  const ATexto: string;
  AEvento: TEventoMonitorSQL);
begin
  if Assigned(FRegistro) and
     FRegistro.MonitorizacionActiva then
  begin
    case AEvento of
      emsEjecutar:
        begin
          if FSQLPendiente then
            VolcarPendiente(True, '');
          FSQLActual := ATexto;
          FSQLStartMs := GetTickCount64;
          FSQLPendiente := True;
          FRegistro.MostrarSQL(ATexto);
        end;
      emsFinalizar:
        VolcarPendiente(True, '');
      emsError:
        VolcarPendiente(False, ATexto);
    end;
  end
  else
    FSQLPendiente := False;
end;

end.
