{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCredencialesConexionWindows                             }
{    Tipo:       Infraestructura                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Almacena las credenciales de conexión en el Administrador de             }
{    credenciales de Windows. Los perfiles solo conservan una referencia.     }
{******************************************************************************}
unit inLibCredencialesConexionWindows;

interface

function LeerCredencialConexionWindows(
  const AReferencia: string;
  out ACredencial: string): Boolean;
procedure GuardarCredencialConexionWindows(
  const AReferencia, AUsuario, ACredencial: string);
procedure EliminarCredencialConexionWindows(
  const AReferencia: string);

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.WinCred,
  inLibMsgConexion;

const
  ERROR_CREDENCIAL_NO_ENCONTRADA = 1168;

procedure ComprobarReferencia(
  const AReferencia: string);
begin
  if Trim(AReferencia) = '' then
    raise EArgumentException.Create(
      SErrorReferenciaCredencialObligatoria);
end;

function LeerCredencialConexionWindows(
  const AReferencia: string;
  out ACredencial: string): Boolean;
var
  oCredencial: PCREDENTIALW;
  iError: Cardinal;
begin
  ComprobarReferencia(AReferencia);
  ACredencial := '';
  oCredencial := nil;
  Result := CredReadW(
    PWideChar(AReferencia),
    CRED_TYPE_GENERIC,
    0,
    oCredencial);
  if not Result then
  begin
    iError := GetLastError;
    if iError <> ERROR_CREDENCIAL_NO_ENCONTRADA then
      raise EOSError.CreateFmt(
        SErrorLeerCredencialConexion,
        [iError]);
  end;
  if Result then
  begin
    try
      if (oCredencial.CredentialBlobSize mod SizeOf(Char)) <> 0 then
        raise EConvertError.Create(
          SErrorFormatoCredencialConexion);
      if oCredencial.CredentialBlobSize > 0 then
        SetString(
          ACredencial,
          PChar(oCredencial.CredentialBlob),
          oCredencial.CredentialBlobSize div SizeOf(Char));
    finally
      CredFree(oCredencial);
    end;
  end;
end;

procedure GuardarCredencialConexionWindows(
  const AReferencia, AUsuario, ACredencial: string);
var
  oCredencial: CREDENTIALW;
  sReferencia: string;
  sUsuario: string;
  sCredencial: string;
  iError: Cardinal;
begin
  ComprobarReferencia(AReferencia);
  sReferencia := AReferencia;
  sUsuario := AUsuario;
  sCredencial := ACredencial;
  ZeroMemory(@oCredencial, SizeOf(oCredencial));
  oCredencial.&Type := CRED_TYPE_GENERIC;
  oCredencial.TargetName := PWideChar(sReferencia);
  oCredencial.UserName := PWideChar(sUsuario);
  oCredencial.Persist := CRED_PERSIST_LOCAL_MACHINE;
  oCredencial.CredentialBlobSize :=
    Length(sCredencial) * SizeOf(Char);
  if oCredencial.CredentialBlobSize > 0 then
    oCredencial.CredentialBlob := PByte(PChar(sCredencial));
  if not CredWriteW(@oCredencial, 0) then
  begin
    iError := GetLastError;
    raise EOSError.CreateFmt(
      SErrorGuardarCredencialConexion,
      [iError]);
  end;
end;

procedure EliminarCredencialConexionWindows(
  const AReferencia: string);
var
  iError: Cardinal;
begin
  ComprobarReferencia(AReferencia);
  if not CredDeleteW(
           PWideChar(AReferencia),
           CRED_TYPE_GENERIC,
           0) then
  begin
    iError := GetLastError;
    if iError <> ERROR_CREDENCIAL_NO_ENCONTRADA then
      raise EOSError.CreateFmt(
        SErrorEliminarCredencialConexion,
        [iError]);
  end;
end;

end.
