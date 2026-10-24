{******************************************************************************}
{                                                                              }
{  Módulo:       inLibProteccionCredenciales                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Protege secretos con DPAPI para el usuario actual de Windows.             }
{******************************************************************************}
unit inLibProteccionCredenciales;

interface

function ProtegerSecretoUsuario(const ASecreto: string): string;
function DesprotegerSecretoUsuario(const ADatoProtegido: string): string;

implementation

uses
  System.NetEncoding,
  System.SysUtils,
  Winapi.Windows;

resourcestring
  SErrorCredencialBase64Invalido =
    'La credencial protegida no tiene un Base64 válido.';
  SErrorCredencialOtroUsuarioWindows =
    'La credencial no pertenece a este usuario de Windows.';

const
  CRYPTPROTECT_UI_FORBIDDEN = $00000001;

type
  TBlobDatos = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PBlobDatos = ^TBlobDatos;

function CryptProtectData(
  pDataIn: PBlobDatos;
  szDataDescr: PWideChar;
  pOptionalEntropy: PBlobDatos;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PBlobDatos): BOOL; stdcall; external 'crypt32.dll';

function CryptUnprotectData(
  pDataIn: PBlobDatos;
  ppszDataDescr: PPWideChar;
  pOptionalEntropy: PBlobDatos;
  pvReserved: Pointer;
  pPromptStruct: Pointer;
  dwFlags: DWORD;
  pDataOut: PBlobDatos): BOOL; stdcall; external 'crypt32.dll';

procedure LimpiarBytes(var ADatos: TBytes);
begin
  if Length(ADatos) > 0 then
  begin
    FillChar(ADatos[0], Length(ADatos), 0);
  end;
  ADatos := nil;
end;

function CrearBlob(var ADatos: TBytes): TBlobDatos;
begin
  Result.cbData := Length(ADatos);
  Result.pbData := nil;
  if Result.cbData > 0 then
  begin
    Result.pbData := @ADatos[0];
  end;
end;

function CopiarBlob(const ABlob: TBlobDatos): TBytes;
begin
  SetLength(Result, ABlob.cbData);
  if ABlob.cbData > 0 then
  begin
    Move(ABlob.pbData^, Result[0], ABlob.cbData);
  end;
end;

procedure LiberarBlob(var ABlob: TBlobDatos);
begin
  if ABlob.pbData <> nil then
  begin
    FillChar(ABlob.pbData^, ABlob.cbData, 0);
    LocalFree(HLOCAL(ABlob.pbData));
  end;
  ABlob.cbData := 0;
  ABlob.pbData := nil;
end;

function ProtegerSecretoUsuario(const ASecreto: string): string;
var
  aEntrada: TBytes;
  aProtegido: TBytes;
  oEntrada: TBlobDatos;
  oSalida: TBlobDatos;
begin
  Result := '';
  if ASecreto <> '' then
  begin
    aEntrada := TEncoding.UTF8.GetBytes(ASecreto);
    oEntrada := CrearBlob(aEntrada);
    oSalida.cbData := 0;
    oSalida.pbData := nil;
    try
      if not CryptProtectData(
        @oEntrada,
        'ViraCash',
        nil,
        nil,
        nil,
        CRYPTPROTECT_UI_FORBIDDEN,
        @oSalida) then
      begin
        RaiseLastOSError;
      end;
      aProtegido := CopiarBlob(oSalida);
      try
        Result := TNetEncoding.Base64.EncodeBytesToString(aProtegido);
        Result := StringReplace(Result, #13, '', [rfReplaceAll]);
        Result := StringReplace(Result, #10, '', [rfReplaceAll]);
      finally
        LimpiarBytes(aProtegido);
      end;
    finally
      LiberarBlob(oSalida);
      LimpiarBytes(aEntrada);
    end;
  end;
end;

function DesprotegerSecretoUsuario(
  const ADatoProtegido: string): string;
var
  aEntrada: TBytes;
  aSalida: TBytes;
  oEntrada: TBlobDatos;
  oSalida: TBlobDatos;
  pDescripcion: PWideChar;
begin
  Result := '';
  if ADatoProtegido <> '' then
  begin
    try
      aEntrada := TNetEncoding.Base64.DecodeStringToBytes(
        ADatoProtegido);
    except
      on E: Exception do
      begin
        raise EConvertError.Create(SErrorCredencialBase64Invalido);
      end;
    end;
    oEntrada := CrearBlob(aEntrada);
    oSalida.cbData := 0;
    oSalida.pbData := nil;
    pDescripcion := nil;
    try
      if not CryptUnprotectData(
        @oEntrada,
        @pDescripcion,
        nil,
        nil,
        nil,
        CRYPTPROTECT_UI_FORBIDDEN,
        @oSalida) then
      begin
        raise EConvertError.Create(SErrorCredencialOtroUsuarioWindows);
      end;
      aSalida := CopiarBlob(oSalida);
      try
        Result := TEncoding.UTF8.GetString(aSalida);
      finally
        LimpiarBytes(aSalida);
      end;
    finally
      if pDescripcion <> nil then
      begin
        LocalFree(HLOCAL(pDescripcion));
      end;
      LiberarBlob(oSalida);
      LimpiarBytes(aEntrada);
    end;
  end;
end;

end.
