{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLineaComandos                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Funciones comunes para leer y normalizar la línea de comandos.            }
{******************************************************************************}
unit inLibLineaComandos;

interface

uses
  System.SysUtils;

function ObtenerParametrosLineaComandos: TArray<string>;
function NormalizarConmutador(const AParametro: string): string;
function EsParametroPerfilValido(const AParametro: string): Boolean;
function ObtenerValorConmutador(
  const AParametros: TArray<string>;
  const ANombre: string): string;

implementation

function ObtenerParametrosLineaComandos: TArray<string>;
var
  iIndice: Integer;
begin
  SetLength(Result, ParamCount);
  for iIndice := 1 to ParamCount do
  begin
    Result[iIndice - 1] := ParamStr(iIndice);
  end;
end;

function NormalizarConmutador(const AParametro: string): string;
begin
  Result := Trim(AParametro);
  while (Result <> '') and
        CharInSet(Result[1], ['/', '-']) do
  begin
    Delete(Result, 1, 1);
  end;
end;

function EsParametroPerfilValido(const AParametro: string): Boolean;
var
  sParametro: string;
begin
  sParametro := Trim(AParametro);
  Result := (sParametro <> '') and
            not CharInSet(sParametro[1], ['/', '-']) and
            SameText(ExtractFileName(sParametro), sParametro) and
            SameText(ExtractFileExt(sParametro), '.ini');
end;

function ObtenerValorConmutador(
  const AParametros: TArray<string>;
  const ANombre: string): string;
var
  iIndice: Integer;
  sNombre: string;
begin
  Result := '';
  sNombre := NormalizarConmutador(ANombre);
  iIndice := 0;
  while (Result = '') and (iIndice < High(AParametros)) do
  begin
    if SameText(
         NormalizarConmutador(AParametros[iIndice]),
         sNombre) then
    begin
      Result := Trim(AParametros[iIndice + 1]);
    end;
    Inc(iIndice);
  end;
end;

end.
