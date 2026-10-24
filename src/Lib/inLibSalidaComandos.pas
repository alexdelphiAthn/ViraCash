{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSalidaComandos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Escritura UTF-8 uniforme de resultados en stdout o stderr.                }
{******************************************************************************}
unit inLibSalidaComandos;

interface

function EscribirMensajeComando(
  const AMensaje: string;
  AEsError: Boolean
): Boolean;

implementation

uses
  System.SysUtils,
  Winapi.Windows;

const
  PROCESO_CONSOLA_PADRE = DWORD(-1);

function EsHandleValido(AHandle: THandle): Boolean;
begin
  Result := (AHandle <> 0) and
            (AHandle <> INVALID_HANDLE_VALUE);
end;

function ObtenerHandleSalida(
  AEsError: Boolean;
  out AConsolaAdjuntada: Boolean): THandle;
var
  iCanal: Cardinal;
begin
  if AEsError then
    iCanal := STD_ERROR_HANDLE
  else
    iCanal := STD_OUTPUT_HANDLE;
  AConsolaAdjuntada := False;
  Result := GetStdHandle(iCanal);
  if not EsHandleValido(Result) then
  begin
    AConsolaAdjuntada := AttachConsole(PROCESO_CONSOLA_PADRE);
    if AConsolaAdjuntada then
      Result := GetStdHandle(iCanal);
  end;
end;

function EscribirBytes(
  AHandle: THandle;
  const ABytes: TBytes): Boolean;
var
  iEscritos: Cardinal;
  iPosicion: Integer;
begin
  Result := True;
  iPosicion := 0;
  while Result and (iPosicion < Length(ABytes)) do
  begin
    iEscritos := 0;
    Result := WriteFile(
      AHandle,
      ABytes[iPosicion],
      Length(ABytes) - iPosicion,
      iEscritos,
      nil) and (iEscritos > 0);
    if Result then
      Inc(iPosicion, iEscritos);
  end;
end;

function EscribirMensajeComando(
  const AMensaje: string;
  AEsError: Boolean): Boolean;
var
  aTextoUtf8: TBytes;
  bConsolaAdjuntada: Boolean;
  hSalida: THandle;
  iEscritos: Cardinal;
  iModoConsola: Cardinal;
  sTexto: string;
begin
  OutputDebugString(PChar(AMensaje));
  bConsolaAdjuntada := False;
  hSalida := ObtenerHandleSalida(AEsError, bConsolaAdjuntada);
  try
    Result := EsHandleValido(hSalida);
    if Result then
    begin
      sTexto := AMensaje + sLineBreak;
      if GetConsoleMode(hSalida, iModoConsola) then
      begin
        iEscritos := 0;
        Result := WriteConsole(
          hSalida,
          PChar(sTexto),
          Length(sTexto),
          iEscritos,
          nil);
      end
      else
      begin
        aTextoUtf8 := TEncoding.UTF8.GetBytes(sTexto);
        Result := EscribirBytes(hSalida, aTextoUtf8);
      end;
    end;
  finally
    if bConsolaAdjuntada then
      FreeConsole;
  end;
end;

end.
