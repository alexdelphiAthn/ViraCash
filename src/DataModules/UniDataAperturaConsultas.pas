{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAperturaConsultas                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Abre consultas UniDAC y registra el tiempo y resultado de la operación.   }
{******************************************************************************}
unit UniDataAperturaConsultas;

interface

uses
  Uni,
  inLibLogIntf;

procedure AbrirConsultaConTiempo(
  AConsulta: TUniQuery;
  const AEtiqueta, ANombre: string;
  const ARegistroLog: IRegistroLog);

implementation

uses
  System.SysUtils,
  System.Diagnostics;

procedure AbrirConsultaConTiempo(
  AConsulta: TUniQuery;
  const AEtiqueta, ANombre: string;
  const ARegistroLog: IRegistroLog);
var
  Cronometro: TStopwatch;
begin
  if not AConsulta.Active then
  begin
    Cronometro := TStopwatch.StartNew;
    try
      AConsulta.Open;
      ARegistroLog.RegistrarRendimiento(
        AEtiqueta,
        ANombre + ' OK',
        Cronometro.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        ARegistroLog.RegistrarRendimiento(
          AEtiqueta,
          ANombre + ' ERROR=' + E.Message,
          Cronometro.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

end.
