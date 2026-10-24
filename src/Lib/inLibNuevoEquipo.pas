{******************************************************************************}
{                                                                              }
{  Modulo:       inLibNuevoEquipo                                              }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas y marca persistente del arranque para un equipo nuevo.             }
{******************************************************************************}
unit inLibNuevoEquipo;

interface

uses
  System.SysUtils;

type
  EContrasenaNuevoEquipoNoValida = class(EArgumentException);

const
  USUARIO_INICIAL_NUEVO_EQUIPO = 'Administrador';
  LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO = 128;

function EsConmutadorNuevoEquipo(const AParametro: string): Boolean;
function HayConmutadorNuevoEquipo(
  const AParametros: array of string): Boolean; overload;
function HayConmutadorNuevoEquipo: Boolean; overload;
function EsOrdenParametrosNuevoEquipoValido(
  const AParametros: array of string): Boolean; overload;
function EsOrdenParametrosNuevoEquipoValido: Boolean; overload;
function HayNuevoEquipoPendienteEnIni(
  const ARutaIni: string): Boolean;
function EsPerfilInstalacionDemoLocal(
  const AServidor, ABaseDatos, AUsuario: string;
  APuerto: Integer): Boolean;
procedure CompletarNuevoEquipoPendienteEnIni(
  const ARutaIni: string);
function EsContrasenaNuevoEquipoValida(
  const AContrasena: string): Boolean;
procedure ValidarContrasenaNuevoEquipo(
  const AContrasena: string);

implementation

uses
  System.Hash,
  System.IniFiles;

resourcestring
  SErrorRutaIniNuevoEquipoVacia =
    'La ruta del INI no puede estar vacía.';
  SErrorMarcaNuevoEquipoIniNoCompletada =
    'No se pudo completar la marca de nuevo equipo del INI.';
  SErrorContrasenaNuevoEquipoVacia =
    'La contrasena nueva no puede estar vacia.';
  SErrorContrasenaNuevoEquipoDemasiadoLarga =
    'La contrasena nueva no puede superar %d caracteres.';

const
  HASH_CONMUTADOR_NUEVO_EQUIPO =
    '62ADAE945FCEF2A505CC873F1824E1F5366C55D6E5C6E8C25AC658D3E70A5000';
  HASH_MARCA_NUEVO_EQUIPO_PENDIENTE =
    '6A2AD4C60DF8323807EF86E76441639360464882FBA0ADB0D61045F83CBAED37';
  SECCION_INSTALACION = 'Installation';
  CLAVE_NUEVO_EQUIPO_PENDIENTE = 'NewComputerPending';

function NormalizarConmutador(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));
  while (Result <> '') and CharInSet(Result[1], ['/', '-']) do
    Delete(Result, 1, 1);
end;

function EsConmutadorNuevoEquipo(const AParametro: string): Boolean;
var
  sOriginal: string;
  sParametro: string;
  sHash: string;
begin
  sOriginal := Trim(AParametro);
  Result := (sOriginal <> '') and
    CharInSet(sOriginal[1], ['/', '-']);
  if Result then
  begin
    sParametro := NormalizarConmutador(sOriginal);
    sHash := THashSHA2.GetHashString(sParametro);
    Result := SameText(sHash, HASH_CONMUTADOR_NUEVO_EQUIPO);
  end;
end;

function HayConmutadorNuevoEquipo(
  const AParametros: array of string): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := Low(AParametros);
  while (i <= High(AParametros)) and not Result do
  begin
    Result := EsConmutadorNuevoEquipo(AParametros[i]);
    Inc(i);
  end;
end;

function HayConmutadorNuevoEquipo: Boolean;
var
  i: Integer;
begin
  Result := False;
  i := 1;
  while (i <= ParamCount) and not Result do
  begin
    Result := EsConmutadorNuevoEquipo(ParamStr(i));
    Inc(i);
  end;
end;

function EsParametroPosicional(const AParametro: string): Boolean;
var
  sParametro: string;
begin
  sParametro := Trim(AParametro);
  Result := (sParametro <> '') and
    not CharInSet(sParametro[1], ['/', '-']);
end;

function EsOrdenParametrosNuevoEquipoValido(
  const AParametros: array of string): Boolean;
var
  i: Integer;
begin
  Result := True;
  if HayConmutadorNuevoEquipo(AParametros) then
  begin
    i := Low(AParametros) + 1;
    while (i <= High(AParametros)) and Result do
    begin
      Result := not EsParametroPosicional(AParametros[i]);
      Inc(i);
    end;
  end;
end;

function EsOrdenParametrosNuevoEquipoValido: Boolean;
var
  i: Integer;
begin
  Result := True;
  if HayConmutadorNuevoEquipo then
  begin
    i := 2;
    while (i <= ParamCount) and Result do
    begin
      Result := not EsParametroPosicional(ParamStr(i));
      Inc(i);
    end;
  end;
end;

procedure ComprobarRutaIni(const ARutaIni: string);
begin
  if Trim(ARutaIni) = '' then
  begin
    raise EArgumentException.Create(SErrorRutaIniNuevoEquipoVacia);
  end;
end;

function HayNuevoEquipoPendienteEnIni(
  const ARutaIni: string): Boolean;
var
  oIni: TIniFile;
  sMarca: string;
begin
  ComprobarRutaIni(ARutaIni);
  Result := False;
  if FileExists(ARutaIni) then
  begin
    oIni := TIniFile.Create(ARutaIni);
    try
      sMarca := Trim(oIni.ReadString(
        SECCION_INSTALACION,
        CLAVE_NUEVO_EQUIPO_PENDIENTE,
        ''));
      Result := sMarca <> '';
      if Result then
      begin
        Result := SameText(
          THashSHA2.GetHashString(sMarca),
          HASH_MARCA_NUEVO_EQUIPO_PENDIENTE);
      end;
    finally
      oIni.Free;
    end;
  end;
end;

function EsPerfilInstalacionDemoLocal(
  const AServidor, ABaseDatos, AUsuario: string;
  APuerto: Integer): Boolean;
begin
  { El puerto no se fija: el instalador usa 3306 y deja cambiarlo si ya esta
    ocupado, y las instalaciones antiguas se quedaron en 3310 o 3311. Lo que
    acota la marca es el perfil local completo mas su propio hash en el INI. }
  Result := SameText(Trim(AServidor), '127.0.0.1') and
    SameText(Trim(ABaseDatos), 'factuzam') and
    SameText(Trim(AUsuario), 'root') and
    (APuerto > 0);
end;

procedure CompletarNuevoEquipoPendienteEnIni(
  const ARutaIni: string);
var
  oIni: TIniFile;
begin
  ComprobarRutaIni(ARutaIni);
  oIni := TIniFile.Create(ARutaIni);
  try
    oIni.DeleteKey(
      SECCION_INSTALACION,
      CLAVE_NUEVO_EQUIPO_PENDIENTE);
    oIni.UpdateFile;
    if oIni.ValueExists(
         SECCION_INSTALACION,
         CLAVE_NUEVO_EQUIPO_PENDIENTE) then
    begin
      raise EInOutError.Create(SErrorMarcaNuevoEquipoIniNoCompletada);
    end;
  finally
    oIni.Free;
  end;
end;

function EsContrasenaNuevoEquipoValida(
  const AContrasena: string): Boolean;
begin
  Result := (AContrasena <> '') and
    (Length(AContrasena) <= LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO);
end;

procedure ValidarContrasenaNuevoEquipo(
  const AContrasena: string);
begin
  if AContrasena = '' then
  begin
    raise EContrasenaNuevoEquipoNoValida.Create(
      SErrorContrasenaNuevoEquipoVacia);
  end;
  if Length(AContrasena) > LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO then
  begin
    raise EContrasenaNuevoEquipoNoValida.CreateFmt(
      SErrorContrasenaNuevoEquipoDemasiadoLarga,
      [LONGITUD_MAXIMA_CONTRASENA_NUEVO_EQUIPO]);
  end;
end;

end.
