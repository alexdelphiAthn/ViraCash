{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparacionesPagadores                                    }
{    Tipo:       Librería                                                      }
{  Versión:       1.0.0                                                        }
{    Fecha:       31/10/2026                                                   }
{    Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reparto del trabajo entre titular y cliente de facturación.               }
{******************************************************************************}
unit inLibReparacionesPagadores;

interface

type
  TRepartoTrabajo = record
    Titular: Currency;
    Pagador: Currency;
  end;

function RepartirTrabajo(ATotal, AFranquicia: Currency;
  const ATitular, APagador: string): TRepartoTrabajo;

implementation

uses
  System.SysUtils, System.Math, inLibMsgReparaciones;

function RepartirTrabajo(ATotal, AFranquicia: Currency;
  const ATitular, APagador: string): TRepartoTrabajo;
var
  dTotal, dFranquicia: Currency;
begin
  Result := Default(TRepartoTrabajo);
  dTotal := SimpleRoundTo(ATotal, -2);
  dFranquicia := SimpleRoundTo(AFranquicia, -2);
  if (ATotal < 0) or (AFranquicia < 0) or (dFranquicia > dTotal) or
     (Trim(APagador) = '0') or
     ((AFranquicia > 0) and ((Trim(ATitular) = '') or
       (Trim(ATitular) = '0') or (Trim(APagador) = '') or
       SameText(Trim(ATitular), Trim(APagador)))) then
    raise EArgumentException.Create(SPagadorTrabajoNoValido);
  if (Trim(APagador) = '') or SameText(Trim(ATitular), Trim(APagador)) then
    Result.Titular := dTotal
  else
  begin
    Result.Titular := dFranquicia;
    Result.Pagador := dTotal - Result.Titular;
  end;
end;

end.
