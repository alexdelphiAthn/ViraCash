{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReconexionAcotada                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pone un tope a la reconexión automática (LocalFailover) de UniDAC.        }
{******************************************************************************}
unit UniDataReconexionAcotada;

interface

uses
  Uni;

const
  // Lo que una operación insiste en reconectar tras perder la conexión:
  // cubre un corte breve de la red sin dejar esperando para siempre ni a la
  // ventana ni a un hilo de cola.
  CVentanaReconexionMs = 15000;

{ Con LocalFailover y sin manejador de OnConnectionLost, UniDAC reconecta y
  repite la operación, y si la reconexión falla lo vuelve a intentar sin
  límite. Sin internet contra un servidor remoto eso deja la operación
  colgada: el 29/09/2026 el hilo de la cola VeriFactu se quedó reconectando
  y el cierre de la aplicación, que espera a ese hilo, no terminaba nunca.
  Aquí se deja reintentar durante AVentanaMs; pasado ese tiempo, o si el
  hilo que hace la operación está terminando, se lanza el error.
  El manejador pertenece a la conexión y se libera con ella; llamarlo más
  de una vez sobre la misma conexión solo cambia la ventana. }
procedure AcotarReconexion(
  AConexion: TUniConnection;
  AVentanaMs: Cardinal = CVentanaReconexionMs);

implementation

uses
  System.Classes,
  System.SysUtils,
  DBAccess,
  MemData;

const
  CNombreManejador = 'ReconexionAcotada';

type
  TReconexionAcotada = class(TComponent)
  private
    FVentanaMs: UInt64;
    FInicio: UInt64;
    FUltimo: UInt64;
    procedure ConexionPerdida(
      Sender: TObject;
      Component: TComponent;
      ConnLostCause: TConnLostCause;
      var RetryMode: TRetryMode);
  end;

function HiloActualTerminando: Boolean;
begin
  // CheckTerminated lanza excepción en el hilo principal (hilo externo)
  Result := (not TThread.CurrentThread.ExternalThread) and
            TThread.CheckTerminated;
end;

procedure TReconexionAcotada.ConexionPerdida(
  Sender: TObject;
  Component: TComponent;
  ConnLostCause: TConnLostCause;
  var RetryMode: TRetryMode);
var
  iAhora: UInt64;
begin
  iAhora := TThread.GetTickCount64;
  // Un aviso que llega tras un rato sin ninguno es un corte nuevo: el
  // anterior terminó reconectando
  if (FInicio = 0) or (iAhora - FUltimo > FVentanaMs) then
    FInicio := iAhora;
  FUltimo := iAhora;
  if HiloActualTerminando or (iAhora - FInicio >= FVentanaMs) then
  begin
    RetryMode := rmRaise;
    // La siguiente operación vuelve a tener su ventana
    FInicio := 0;
  end;
end;

procedure AcotarReconexion(
  AConexion: TUniConnection;
  AVentanaMs: Cardinal);
var
  oManejador: TReconexionAcotada;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  oManejador := TReconexionAcotada(
    AConexion.FindComponent(CNombreManejador));
  if not Assigned(oManejador) then
  begin
    oManejador := TReconexionAcotada.Create(AConexion);
    oManejador.Name := CNombreManejador;
  end;
  oManejador.FVentanaMs := AVentanaMs;
  AConexion.OnConnectionLost := oManejador.ConexionPerdida;
end;

end.
