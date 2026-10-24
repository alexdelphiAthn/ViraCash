{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCredencialUsuarioIni                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Persiste la contraseña recordada del usuario mediante DPAPI y migra el    }
{    antiguo PasswordEn cifrado con AES.                                       }
{******************************************************************************}
unit inLibCredencialUsuarioIni;

interface

function CargarContrasenaUsuarioRecordada(
  const ARutaIni: string): string;
procedure GuardarContrasenaUsuarioRecordada(
  const ARutaIni: string;
  const AContrasena: string);
procedure EliminarContrasenaUsuarioRecordada(
  const ARutaIni: string);

implementation

uses
  System.IniFiles,
  System.SysUtils,
  inLibCifrado,
  inLibProteccionCredenciales;

resourcestring
  SErrorEscribirContrasenaProtegidaIni =
    'No se pudo escribir la contraseña protegida en el INI (%d/%d bytes).';
  SErrorVerificarContrasenaProtegidaIni =
    'No se pudo verificar la contraseña protegida del INI.';
  SErrorRetirarContrasenaLegadaIni =
    'No se pudo retirar PasswordEn del INI de usuario.';
  SErrorContrasenaRecordadaVacia =
    'La contraseña recordada no puede estar vacía.';
  SErrorBorrarContrasenaRecordadaIni =
    'No se pudo borrar la contraseña recordada del INI.';

const
  SECCION_USUARIO = 'UserInfo';
  CLAVE_CONTRASENA_LEGADA = 'PasswordEn';
  CLAVE_CONTRASENA_PROTEGIDA = 'PasswordDpapi';

procedure ComprobarRutaIni(const ARutaIni: string);
begin
  if Trim(ARutaIni) = '' then
  begin
    raise EArgumentException.Create(
      'La ruta del INI de usuario no puede estar vacía.');
  end;
end;

procedure ComprobarContrasenaProtegida(
  const AIni: TIniFile;
  const ADatoProtegido: string;
  const AContrasena: string);
var
  sGuardado: string;
begin
  sGuardado := AIni.ReadString(
    SECCION_USUARIO,
    CLAVE_CONTRASENA_PROTEGIDA,
    '');
  if sGuardado <> ADatoProtegido then
  begin
    raise EInOutError.CreateFmt(
      SErrorEscribirContrasenaProtegidaIni,
      [Length(sGuardado), Length(ADatoProtegido)]);
  end;
  if DesprotegerSecretoUsuario(sGuardado) <> AContrasena then
  begin
    raise EInOutError.Create(SErrorVerificarContrasenaProtegidaIni);
  end;
end;

procedure EliminarClaveLegada(const AIni: TIniFile);
begin
  AIni.DeleteKey(SECCION_USUARIO, CLAVE_CONTRASENA_LEGADA);
  AIni.UpdateFile;
  if AIni.ValueExists(SECCION_USUARIO, CLAVE_CONTRASENA_LEGADA) then
  begin
    raise EInOutError.Create(SErrorRetirarContrasenaLegadaIni);
  end;
end;

procedure GuardarContrasenaProtegida(
  const AIni: TIniFile;
  const AContrasena: string);
var
  sProtegido: string;
begin
  if AContrasena = '' then
  begin
    raise EArgumentException.Create(SErrorContrasenaRecordadaVacia);
  end;
  sProtegido := ProtegerSecretoUsuario(AContrasena);
  AIni.WriteString(
    SECCION_USUARIO,
    CLAVE_CONTRASENA_PROTEGIDA,
    sProtegido);
  AIni.UpdateFile;
  ComprobarContrasenaProtegida(
    AIni,
    sProtegido,
    AContrasena);
  EliminarClaveLegada(AIni);
end;

function DescifrarContrasenaLegada(
  const ADatoCifrado: string): string;
begin
  Result := DescifrarAES(ADatoCifrado);
  if (ADatoCifrado = '') or
    (CifrarAES(Result) <> ADatoCifrado) then
  begin
    raise EConvertError.Create(
      'PasswordEn no contiene una contraseña AES válida.');
  end;
end;

function CargarContrasenaUsuarioRecordada(
  const ARutaIni: string): string;
var
  oIni: TIniFile;
  sLegado: string;
  sProtegido: string;
begin
  ComprobarRutaIni(ARutaIni);
  Result := '';
  oIni := TIniFile.Create(ARutaIni);
  try
    sProtegido := oIni.ReadString(
      SECCION_USUARIO,
      CLAVE_CONTRASENA_PROTEGIDA,
      '');
    sLegado := oIni.ReadString(
      SECCION_USUARIO,
      CLAVE_CONTRASENA_LEGADA,
      '');
    if sProtegido <> '' then
    begin
      try
        Result := DesprotegerSecretoUsuario(sProtegido);
      except
        if sLegado = '' then
        begin
          raise;
        end;
        Result := DescifrarContrasenaLegada(sLegado);
        GuardarContrasenaProtegida(oIni, Result);
      end;
      if oIni.ValueExists(
        SECCION_USUARIO,
        CLAVE_CONTRASENA_LEGADA) then
      begin
        EliminarClaveLegada(oIni);
      end;
    end
    else if sLegado <> '' then
    begin
      Result := DescifrarContrasenaLegada(sLegado);
      GuardarContrasenaProtegida(oIni, Result);
    end;
  finally
    FreeAndNil(oIni);
  end;
end;

procedure GuardarContrasenaUsuarioRecordada(
  const ARutaIni: string;
  const AContrasena: string);
var
  oIni: TIniFile;
begin
  ComprobarRutaIni(ARutaIni);
  oIni := TIniFile.Create(ARutaIni);
  try
    GuardarContrasenaProtegida(oIni, AContrasena);
  finally
    FreeAndNil(oIni);
  end;
end;

procedure EliminarContrasenaUsuarioRecordada(
  const ARutaIni: string);
var
  oIni: TIniFile;
begin
  ComprobarRutaIni(ARutaIni);
  oIni := TIniFile.Create(ARutaIni);
  try
    oIni.DeleteKey(SECCION_USUARIO, CLAVE_CONTRASENA_PROTEGIDA);
    oIni.DeleteKey(SECCION_USUARIO, CLAVE_CONTRASENA_LEGADA);
    oIni.UpdateFile;
    if oIni.ValueExists(
        SECCION_USUARIO,
        CLAVE_CONTRASENA_PROTEGIDA) or
      oIni.ValueExists(
        SECCION_USUARIO,
        CLAVE_CONTRASENA_LEGADA) then
    begin
      raise EInOutError.Create(SErrorBorrarContrasenaRecordadaIni);
    end;
  finally
    FreeAndNil(oIni);
  end;
end;

end.
