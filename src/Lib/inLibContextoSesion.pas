{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContextoSesion                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementación sincronizada del contexto de sesión de la aplicación.      }
{******************************************************************************}
unit inLibContextoSesion;

interface

uses
  System.SyncObjs,
  inLibContextoSesionIntf;

type
  TContextoSesionAplicacion = class(
    TInterfacedObject,
    IContextoSesionAplicacion,
    IGestorContextoSesion,
    IFechaCajaSesion
  )
  private
    FBloqueo: TCriticalSection;
    FCerrandoAplicacion: Boolean;
    FIdentidad: TIdentidadSesion;
    FLogSesion: TLogSesionProc;
    FUbicacion: TUbicacionSesion;
    FDesfaseFechaCaja: TDateTime;
  protected
    function GetCerrandoAplicacion: Boolean;
    function GetIdentidad: TIdentidadSesion;
    function GetUbicacion: TUbicacionSesion;
    procedure LogSesion(const ATexto: string);
    property Identidad: TIdentidadSesion read GetIdentidad;
    property Ubicacion: TUbicacionSesion read GetUbicacion;
  public
    constructor Create(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion
    );
    destructor Destroy; override;
    procedure AsignarLogSesion(ALogSesion: TLogSesionProc);
    procedure MarcarCierreAplicacion;
    procedure EstablecerIdentidad(
      const AIdentidad: TIdentidadSesion
    ); virtual;
    procedure CambiarUbicacion(
      const AUbicacion: TUbicacionSesion
    ); virtual;
    function ObtenerFechaCaja: TDateTime;
    procedure EstablecerFechaCaja(AFecha: TDateTime);
  end;

implementation

uses
  System.SysUtils;

function TContextoSesionAplicacion.ObtenerFechaCaja: TDateTime;
begin
  FBloqueo.Enter;
  try
    Result := Now + FDesfaseFechaCaja;
  finally
    FBloqueo.Leave;
  end;
end;

procedure TContextoSesionAplicacion.EstablecerFechaCaja(AFecha: TDateTime);
begin
  FBloqueo.Enter;
  try
    FDesfaseFechaCaja := 0;
    if AFecha > 0 then
      FDesfaseFechaCaja := AFecha - Now;
  finally
    FBloqueo.Leave;
  end;
end;

constructor TContextoSesionAplicacion.Create(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
begin
  inherited Create;
  FBloqueo := TCriticalSection.Create;
  FCerrandoAplicacion := False;
  FIdentidad := AIdentidad;
  FLogSesion := nil;
  FUbicacion := AUbicacion;
end;

destructor TContextoSesionAplicacion.Destroy;
begin
  FBloqueo.Free;
  inherited;
end;

function TContextoSesionAplicacion.GetCerrandoAplicacion: Boolean;
begin
  FBloqueo.Acquire;
  try
    Result := FCerrandoAplicacion;
  finally
    FBloqueo.Release;
  end;
end;

function TContextoSesionAplicacion.GetIdentidad: TIdentidadSesion;
begin
  FBloqueo.Acquire;
  try
    Result := FIdentidad;
  finally
    FBloqueo.Release;
  end;
end;

function TContextoSesionAplicacion.GetUbicacion: TUbicacionSesion;
begin
  FBloqueo.Acquire;
  try
    Result := FUbicacion;
  finally
    FBloqueo.Release;
  end;
end;

procedure TContextoSesionAplicacion.LogSesion(const ATexto: string);
var
  LogActivo: TLogSesionProc;
begin
  FBloqueo.Acquire;
  try
    LogActivo := FLogSesion;
  finally
    FBloqueo.Release;
  end;
  if Assigned(LogActivo) then
    LogActivo(ATexto);
end;

procedure TContextoSesionAplicacion.AsignarLogSesion(
  ALogSesion: TLogSesionProc);
begin
  FBloqueo.Acquire;
  try
    FLogSesion := ALogSesion;
  finally
    FBloqueo.Release;
  end;
end;

procedure TContextoSesionAplicacion.MarcarCierreAplicacion;
begin
  FBloqueo.Acquire;
  try
    FCerrandoAplicacion := True;
  finally
    FBloqueo.Release;
  end;
end;

procedure TContextoSesionAplicacion.EstablecerIdentidad(
  const AIdentidad: TIdentidadSesion);
begin
  FBloqueo.Acquire;
  try
    FIdentidad := AIdentidad;
    FDesfaseFechaCaja := 0;
  finally
    FBloqueo.Release;
  end;
end;

procedure TContextoSesionAplicacion.CambiarUbicacion(
  const AUbicacion: TUbicacionSesion);
begin
  FBloqueo.Acquire;
  try
    FUbicacion := AUbicacion;
  finally
    FBloqueo.Release;
  end;
end;

end.
