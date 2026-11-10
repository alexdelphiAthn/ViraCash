{******************************************************************************}
{                                                                              }
{  Módulo: inLibMeteorologiaCajaTarea                                          }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Consulta y presentación del tiempo diario de la tienda.        }
{******************************************************************************}
unit inLibMeteorologiaCajaTarea;

interface

uses
  System.SysUtils, inLibMeteorologiaCajaIntf, inLibLogIntf;

type
  IConsultaMeteorologiaCaja = interface
    ['{FD4501CC-238B-4123-BC5B-19EFEEFA1059}']
    function Obtener(out AParte: TPartesMeteorologiaCaja;
      out AError: string): Boolean;
    procedure Cancelar;
    function Cancelada: Boolean;
  end;

  TAccionMeteorologiaCancelable = reference to function(
    const ACancelar: TFunc<Boolean>): TPartesMeteorologiaCaja;

function IniciarConsultaMeteorologiaCaja(
  const AServicio: IServicioMeteorologiaCaja;
  const AUbicacion: TUbicacionMeteorologiaCaja;
  const ARegistro: IRegistroLog): IConsultaMeteorologiaCaja;

function IniciarTareaMeteorologiaCaja(
  const AAccion: TFunc<TPartesMeteorologiaCaja>;
  const ARegistro: IRegistroLog): IConsultaMeteorologiaCaja; overload;
function IniciarTareaMeteorologiaCaja(
  const AAccion: TAccionMeteorologiaCancelable;
  const ARegistro: IRegistroLog): IConsultaMeteorologiaCaja; overload;

implementation

uses
  System.Classes, System.Threading;

type
  ICompletarMeteorologiaCaja = interface(IConsultaMeteorologiaCaja)
    ['{DB0F373A-6B80-414F-8040-FC100FC8C946}']
    procedure Completar(const AParte: TPartesMeteorologiaCaja;
      const AError: string);
  end;

  TConsultaMeteorologiaCaja = class(TInterfacedObject,
    IConsultaMeteorologiaCaja, ICompletarMeteorologiaCaja)
  private
    FFinalizada: Boolean;
    FParte: TPartesMeteorologiaCaja;
    FError: string;
    FCancelada: Boolean;
  public
    function Obtener(out AParte: TPartesMeteorologiaCaja;
      out AError: string): Boolean;
    procedure Cancelar;
    function Cancelada: Boolean;
    procedure Completar(const AParte: TPartesMeteorologiaCaja;
      const AError: string);
  end;

function TConsultaMeteorologiaCaja.Obtener(
  out AParte: TPartesMeteorologiaCaja; out AError: string): Boolean;
begin
  TMonitor.Enter(Self);
  try
    Result := FFinalizada;
    AParte := FParte;
    AError := FError;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TConsultaMeteorologiaCaja.Cancelar;
begin
  TMonitor.Enter(Self);
  try
    FCancelada := True;
  finally
    TMonitor.Exit(Self);
  end;
end;

function TConsultaMeteorologiaCaja.Cancelada: Boolean;
begin
  TMonitor.Enter(Self);
  try
    Result := FCancelada;
  finally
    TMonitor.Exit(Self);
  end;
end;

procedure TConsultaMeteorologiaCaja.Completar(
  const AParte: TPartesMeteorologiaCaja; const AError: string);
begin
  TMonitor.Enter(Self);
  try
    FParte := AParte;
    FError := AError;
    FFinalizada := True;
  finally
    TMonitor.Exit(Self);
  end;
end;

function IniciarTareaMeteorologiaCaja(
  const AAccion: TAccionMeteorologiaCancelable;
  const ARegistro: IRegistroLog): IConsultaMeteorologiaCaja;
var
  oEstado: ICompletarMeteorologiaCaja;
  oTarea: ITask;
begin
  oEstado := TConsultaMeteorologiaCaja.Create;
  Result := oEstado;
  // El worker solo posee interfaces y datos. Cerrar caja no espera la red
  // ni deja callbacks que puedan acceder a un formulario ya destruido.
  oTarea := TTask.Run(
    procedure
    var
      rParte: TPartesMeteorologiaCaja;
      sError: string;
    begin
      rParte := nil;
      sError := '';
      try
        rParte := AAccion(
          function: Boolean
          begin
            Result := oEstado.Cancelada;
          end);
      except
        on E: Exception do
        begin
          sError := E.Message;
          ARegistro.RegistrarError('METEO: ' + sError);
        end;
      end;
      oEstado.Completar(rParte, sError);
    end);
end;

function IniciarTareaMeteorologiaCaja(
  const AAccion: TFunc<TPartesMeteorologiaCaja>;
  const ARegistro: IRegistroLog): IConsultaMeteorologiaCaja;
begin
  Result := IniciarTareaMeteorologiaCaja(
    function(const ACancelar: TFunc<Boolean>): TPartesMeteorologiaCaja
    begin
      Result := nil;
      if not ACancelar() then
        Result := AAccion();
    end, ARegistro);
end;

function IniciarConsultaMeteorologiaCaja(
  const AServicio: IServicioMeteorologiaCaja;
  const AUbicacion: TUbicacionMeteorologiaCaja;
  const ARegistro: IRegistroLog): IConsultaMeteorologiaCaja;
begin
  Result := IniciarTareaMeteorologiaCaja(
    function: TPartesMeteorologiaCaja
    begin
      SetLength(Result, 1);
      Result[0] := AServicio.ConsultarHoy(AUbicacion);
    end, ARegistro);
end;

end.
