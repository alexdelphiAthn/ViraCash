{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesMovimientos                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit inLibReparacionesMovimientos;

interface

type
  TMovimientoReparacion = record
    Reparacion: Int64;
    Anterior: Int64;
    Instante: TDateTime;
    Origen: string;
    Destino: string;
    Estado: string;
    Objeto: string;
    Agencia: string;
    Seguimiento: string;
    Incidencia: string;
    Usuario: string;
  end;

function ValidarMovimientoReparacion(
  const AMovimiento: TMovimientoReparacion): string;

implementation

uses
  System.SysUtils, System.StrUtils, inLibMsgReparaciones;

function ValidarMovimientoReparacion(
  const AMovimiento: TMovimientoReparacion): string;
begin
  Result := '';
  if AMovimiento.Reparacion <= 0 then
    Result := SInfoSinReparacion
  else if (AMovimiento.Instante <= 0) or
          (AMovimiento.Instante > Now + 1 / 1440) then
    Result := SMovimientoFechaInvalida
  else if (Trim(AMovimiento.Origen) = '') or
          (Trim(AMovimiento.Destino) = '') or
          (Trim(AMovimiento.Objeto) = '') then
    Result := SMovimientoDatosObligatorios
  else if not MatchStr(AMovimiento.Estado,
    ['ENVIADO', 'RECIBIDO', 'DEVUELTO', 'DEFECTUOSO', 'ANULADO']) then
    Result := SMovimientoEstadoInvalido
  else if MatchStr(AMovimiento.Estado,
    ['DEVUELTO', 'DEFECTUOSO', 'ANULADO']) and
    (Trim(AMovimiento.Incidencia) = '') then
    Result := SMovimientoMotivoObligatorio
  else if (Length(AMovimiento.Origen) > 100) or
          (Length(AMovimiento.Destino) > 100) or
          (Length(AMovimiento.Objeto) > 200) or
          (Length(AMovimiento.Agencia) > 100) or
          (Length(AMovimiento.Seguimiento) > 100) or
          (Length(AMovimiento.Incidencia) > 2000) then
    Result := SMovimientoTextoLargo;
end;

end.
