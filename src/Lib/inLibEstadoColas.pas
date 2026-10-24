{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEstadoColas                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Estado de cada cola compartido de forma segura entre hilo y UI.           }
{******************************************************************************}
unit inLibEstadoColas;

interface

uses
  inLibEstadoColasIntf, inLibParametrosIntf;

function CrearEstadoCola: IEstadoCola;
function HorasIncidenciasColas(const AParametros: IParametros): Integer;

implementation

uses
  System.SysUtils, System.SyncObjs, inLibMsgIntegraciones;

type
  TEstadoColaCompartido = class(TInterfacedObject, IEstadoCola)
  private
    FCerrojo: TCriticalSection;
    FEstado: TEstadoCola;
    FIncidenciaCiclo: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure IniciarCiclo;
    procedure Publicar(AActividad: TActividadCola; const AEvento: string);
    procedure FinalizarCiclo(const AIncidenciaPendiente: string;
      AHorasIncidencias: Integer);
    function Leer: TEstadoCola;
  end;

constructor TEstadoColaCompartido.Create;
begin
  inherited Create;
  FCerrojo := TCriticalSection.Create;
  FEstado.Instante := Now;
  FEstado.HorasIncidencias := cHorasIncidenciasColasDefecto;
  FEstado.UltimoEvento := SColaEsperandoPrimerCiclo;
end;

destructor TEstadoColaCompartido.Destroy;
begin
  FreeAndNil(FCerrojo);
  inherited;
end;

procedure TEstadoColaCompartido.IniciarCiclo;
begin
  FCerrojo.Acquire;
  try
    FIncidenciaCiclo := '';
  finally
    FCerrojo.Release;
  end;
end;

procedure TEstadoColaCompartido.Publicar(
  AActividad: TActividadCola; const AEvento: string);
begin
  FCerrojo.Acquire;
  try
    FEstado.Actividad := AActividad;
    FEstado.UltimoEvento := AEvento;
    FEstado.Instante := Now;
    if AActividad = acIncidencia then
    begin
      FIncidenciaCiclo := AEvento;
      FEstado.Incidencia := AEvento;
    end;
    if (AActividad = acCorrecta) and (FEstado.Incidencia <> '') then
      FEstado.Actividad := acIncidencia;
  finally
    FCerrojo.Release;
  end;
end;

procedure TEstadoColaCompartido.FinalizarCiclo(
  const AIncidenciaPendiente: string; AHorasIncidencias: Integer);
var
  sIncidenciaAnterior: string;
  bCambianHoras: Boolean;
begin
  FCerrojo.Acquire;
  try
    sIncidenciaAnterior := FEstado.Incidencia;
    bCambianHoras := FEstado.HorasIncidencias <> AHorasIncidencias;
    FEstado.HorasIncidencias := AHorasIncidencias;
    FEstado.Incidencia := AIncidenciaPendiente;
    if FIncidenciaCiclo <> '' then
      FEstado.Incidencia := FIncidenciaCiclo;
    if FEstado.Incidencia <> '' then
      FEstado.Actividad := acIncidencia
    else
      FEstado.Actividad := acCorrecta;
    if bCambianHoras or (sIncidenciaAnterior <> FEstado.Incidencia) or
       (FEstado.UltimoEvento = SColaEsperandoPrimerCiclo) then
    begin
      FEstado.Instante := Now;
      if FEstado.Incidencia <> '' then
        FEstado.UltimoEvento := FEstado.Incidencia
      else
        FEstado.UltimoEvento := Format(SColaSinIncidencias,
          [FEstado.HorasIncidencias]);
    end;
  finally
    FCerrojo.Release;
  end;
end;

function TEstadoColaCompartido.Leer: TEstadoCola;
begin
  FCerrojo.Acquire;
  try
    Result := FEstado;
  finally
    FCerrojo.Release;
  end;
end;

function CrearEstadoCola: IEstadoCola;
begin
  Result := TEstadoColaCompartido.Create;
end;

function HorasIncidenciasColas(const AParametros: IParametros): Integer;
begin
  Result := cHorasIncidenciasColasDefecto;
  if Assigned(AParametros) then
    Result := AParametros.GetInt(cParametroColasHorasIncidencias, Result);
  if Result <= 0 then
    Result := cHorasIncidenciasColasDefecto;
end;

end.
