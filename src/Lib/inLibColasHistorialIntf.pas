{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColasHistorialIntf                                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Tipos compartidos por los historiales de comunicaciones de las colas.     }
{******************************************************************************}
unit inLibColasHistorialIntf;

interface

const
  CMaximoPeticionHistorial = 1048576;
  CMaximoRespuestaHistorial = 1048576;
  CMaximoMensajeHistorial = 8000;
  CMaximoRecursoHistorial = 1000;
  CMaximoTextoEstadoHistorial = 255;

type
  TResultadoComunicacionCola = (
    rccCorrecto,
    rccError
  );

function AcotarTextoHistorial(
  const ATexto: string;
  AMaximo: Integer): string;

implementation

uses
  System.SysUtils;

const
  CMarcaTruncado = '[TRUNCADO POR LIMITE DEL HISTORIAL]';

function AcotarTextoHistorial(
  const ATexto: string;
  AMaximo: Integer): string;
begin
  if AMaximo < Length(CMarcaTruncado) then
    raise EArgumentOutOfRangeException.Create('AMaximo');
  Result := ATexto;
  if Length(Result) > AMaximo then
  begin
    Result := Copy(ATexto, 1, AMaximo - Length(CMarcaTruncado));
    Result := Result + CMarcaTruncado;
  end;
end;

end.
