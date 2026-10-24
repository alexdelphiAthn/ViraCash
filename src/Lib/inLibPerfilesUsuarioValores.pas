{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPerfilesUsuarioValores                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura de valores de perfil sin dependencias de interfaz de usuario.     }
{******************************************************************************}
unit inLibPerfilesUsuarioValores;

interface

uses
  inLibPerfilesUsuarioIntf;

function GetPerfilSubKeyValueDef(
  var APerfil: TProfileDicc;
  ASubKey, ASubSubKey, AValorDefecto: string): string;
function GetPerfilValueTextDef(
  var APerfil: TProfileDicc;
  ASubKey: string;
  AValorDefecto: WideString): WideString;
function GetPerfilValueDef(
  var APerfil: TProfileDicc;
  ASubKey, AValorDefecto: string): string;

implementation

function GetPerfilSubKeyValueDef(
  var APerfil: TProfileDicc;
  ASubKey, ASubSubKey, AValorDefecto: string): string;
var
  oValor: TDictValue;
  sClave: string;
begin
  sClave := ASubKey + '_' + ASubSubKey;
  if APerfil.ContainsKey(sClave) then
  begin
    APerfil.TryGetValue(sClave, oValor);
    Result := oValor.sValue;
  end
  else
    Result := AValorDefecto;
end;

function GetPerfilValueTextDef(
  var APerfil: TProfileDicc;
  ASubKey: string;
  AValorDefecto: WideString): WideString;
var
  oValor: TDictValue;
begin
  Result := AValorDefecto;
  if Assigned(APerfil) and (APerfil.Count > 0) then
  begin
    APerfil.TrimExcess;
    if APerfil.ContainsKey(ASubKey) then
    begin
      APerfil.TryGetValue(ASubKey, oValor);
      Result := oValor.sValueText;
    end;
  end;
end;

function GetPerfilValueDef(
  var APerfil: TProfileDicc;
  ASubKey, AValorDefecto: string): string;
var
  oValor: TDictValue;
begin
  Result := AValorDefecto;
  if Assigned(APerfil) and APerfil.ContainsKey(ASubKey) then
  begin
    APerfil.TryGetValue(ASubKey, oValor);
    Result := oValor.sValue;
  end;
end;

end.
