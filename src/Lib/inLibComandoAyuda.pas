{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComandoAyuda                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Reconoce la solicitud de ayuda y compone la ayuda de comandos públicos.   }
{******************************************************************************}
unit inLibComandoAyuda;

interface

uses
  System.SysUtils;

function EsComandoAyuda(const AParametros: TArray<string>): Boolean;
function CrearTextoAyudaComandos: string;

implementation

uses
  inLibLineaComandos,
  inLibMsgConfiguracion;

function EsParametroAyuda(const AParametro: string): Boolean;
var
  sParametro: string;
begin
  sParametro := NormalizarConmutador(AParametro);
  Result := SameText(sParametro, '?') or
            SameText(sParametro, 'help');
end;

function EsComandoAyuda(const AParametros: TArray<string>): Boolean;
begin
  Result := (Length(AParametros) = 1) and
            EsParametroAyuda(AParametros[0]);
  if not Result then
  begin
    Result := (Length(AParametros) = 2) and
              EsParametroPerfilValido(AParametros[0]) and
              EsParametroAyuda(AParametros[1]);
  end;
end;

function CrearTextoAyudaComandos: string;
begin
  Result := Format(
    SAyudaComandos,
    [
      SErrorSintaxisComandoCopiaSeguridad,
      SErrorSintaxisComandoImprimirFacturas,
      SErrorSintaxisComandoRecalculosStock
    ]);
end;

end.
