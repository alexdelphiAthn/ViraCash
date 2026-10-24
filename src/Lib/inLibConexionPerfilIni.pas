{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionPerfilIni                                       }
{    Tipo:       Infraestructura                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve el perfil de conexión y su credencial desde el INI, cifrada    }
{    con AES. El almacén de credenciales de Windows solo se lee, para        }
{    recuperar instalaciones anteriores: guarda por usuario de Windows y     }
{    su contenido no se puede copiar a otro equipo ni a otro usuario.       }
{******************************************************************************}
unit inLibConexionPerfilIni;

interface

uses
  inLibConexionPerfilIntf;

type
  TConfiguracionConexionResuelta = record
    Perfil: TPerfilConexion;
    ReferenciaCredencial: string;
    ReferenciaCredencialAnterior: string;
    Credencial: string;
    ProcedeDeFormatoLegado: Boolean;
  end;

function RutaPerfilConexionAplicacion(
  const ADirectorio: string): string;
function ReferenciaCredencialConexionPredeterminada(
  const AIdPerfil, ARutaIni: string): string;
function CargarConfiguracionConexionIni(
  const ARutaIni: string): TConfiguracionConexionResuelta;
procedure GuardarConfiguracionConexionIni(
  const ARutaIni: string;
  const AConfiguracion: TConfiguracionConexionResuelta);

implementation

uses
  System.Hash,
  System.IniFiles,
  System.StrUtils,
  System.SysUtils,
  inLibCifrado,
  inLibConfiguracionIni,
  inLibConexionPerfil,
  inLibCredencialesConexionWindows,
  inLibMsgConexion;

const
  PREFIJO_CREDENCIAL_BBDD = 'Factuzam/BBDD/';

function LeerBooleano(
  AIni: TCustomIniFile;
  const ASeccion, AClave: string;
  AValorPredeterminado: Boolean): Boolean;
var
  sValor: string;
begin
  sValor := LowerCase(Trim(AIni.ReadString(
    ASeccion,
    AClave,
    BoolToStr(AValorPredeterminado, True))));
  Result := MatchText(
    sValor,
    ['1', 'true', 'yes', 'si', 'sí', 'on']);
  if not Result and
     not MatchText(sValor, ['0', 'false', 'no', 'off']) then
    raise EConvertError.CreateFmt(
      SErrorValorPerfilNoBooleano,
      [ASeccion, AClave]);
end;

function LeerEntero(
  AIni: TCustomIniFile;
  const ASeccion, AClave: string;
  AValorPredeterminado: Integer): Integer;
var
  sValor: string;
begin
  sValor := Trim(AIni.ReadString(
    ASeccion,
    AClave,
    IntToStr(AValorPredeterminado)));
  if not TryStrToInt(sValor, Result) then
    raise EConvertError.CreateFmt(
      SErrorValorPerfilNoEntero,
      [ASeccion, AClave]);
end;

function NormalizarIdPerfil(
  const AValor: string): string;
var
  cCaracter: Char;
  i: Integer;
  sValor: string;
begin
  Result := '';
  sValor := Trim(AValor);
  for i := 1 to Length(sValor) do
  begin
    cCaracter := sValor[i];
    if CharInSet(
         cCaracter,
         ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.']) then
      Result := Result + cCaracter
    else
      Result := Result + '_';
  end;
  if Result = '' then
    Result := 'predeterminado';
end;

function IdPerfilDesdeRuta(
  const ARutaIni: string): string;
begin
  Result := NormalizarIdPerfil(
    ChangeFileExt(ExtractFileName(ARutaIni), ''));
end;

function ReferenciaCredencialLegada(
  const AIdPerfil: string): string;
begin
  Result := PREFIJO_CREDENCIAL_BBDD +
    NormalizarIdPerfil(AIdPerfil);
end;

function ReferenciaCredencialConexionPredeterminada(
  const AIdPerfil, ARutaIni: string): string;
var
  sHuellaRuta: string;
  sRutaNormalizada: string;
begin
  sRutaNormalizada := UpperCase(ExpandFileName(ARutaIni));
  sHuellaRuta := THashSHA2.GetHashString(sRutaNormalizada);
  Result := PREFIJO_CREDENCIAL_BBDD +
    NormalizarIdPerfil(AIdPerfil) + '/' +
    LowerCase(Copy(sHuellaRuta, 1, 16));
end;

procedure ValidarReferenciaCredencial(
  const AReferencia: string);
begin
  if not StartsText(PREFIJO_CREDENCIAL_BBDD, AReferencia) then
    raise EArgumentException.Create(
      SErrorReferenciaCredencialAjena);
end;

function RutaPerfilConexionAplicacion(
  const ADirectorio: string): string;
begin
  Result := RutaIniAplicacion(ADirectorio);
end;

function CargarConfiguracionConexionIni(
  const ARutaIni: string): TConfiguracionConexionResuelta;
var
  bMigrarReferenciaPredeterminada: Boolean;
  oIni: TIniFile;
  eMotor: TMotorBBDD;
  eSSL: TModoSSLConexion;
  sMotor: string;
  sSSL: string;
  sClaveLegada: string;
  sReferenciaConfigurada: string;
  sReferenciaLegada: string;
  sMotivo: string;
begin
  if Trim(ARutaIni) = '' then
    raise EArgumentException.Create(
      SErrorRutaPerfilConexionObligatoria);
  Result := Default(TConfiguracionConexionResuelta);
  oIni := TIniFile.Create(ARutaIni);
  try
    sMotor := Trim(oIni.ReadString('ConnData', 'Motor', ''));
    if sMotor = '' then
      eMotor := mbMariaDB
    else if not IntentarParsearMotorBBDD(sMotor, eMotor) then
      raise EConvertError.CreateFmt(
        SErrorMotorBBDDNoSoportado,
        [sMotor]);
    Result.Perfil := CrearPerfilConexionPredeterminado(eMotor);
    Result.Perfil.Id := oIni.ReadString(
      'ConnData',
      'ProfileId',
      IdPerfilDesdeRuta(ARutaIni));
    Result.Perfil.Servidor := oIni.ReadString(
      'ConnData', 'HostName', '127.0.0.1');
    Result.Perfil.Puerto := LeerEntero(
      oIni,
      'ConnData',
      'Puerto',
      Result.Perfil.Puerto);
    Result.Perfil.BaseDatos := oIni.ReadString(
      'ConnData', 'Database', 'factuzam');
    Result.Perfil.Esquema := oIni.ReadString(
      'ConnData',
      'Schema',
      Result.Perfil.Esquema);
    Result.Perfil.Usuario := oIni.ReadString(
      'ConnData', 'User', 'root');
    sSSL := oIni.ReadString(
      'ConnData', 'SSLMode', 'desactivado');
    if not IntentarParsearModoSSLConexion(sSSL, eSSL) then
      raise EConvertError.CreateFmt(
        SErrorModoSSLNoSoportado,
        [sSSL]);
    Result.Perfil.SSL := eSSL;
    Result.Perfil.TimeoutConexionSeg := LeerEntero(
      oIni, 'ConnData', 'ConnectionTimeout', 5);
    Result.Perfil.TimeoutComandoSeg := LeerEntero(
      oIni, 'ConnData', 'CommandTimeout', 30);
    Result.Perfil.Pool.Habilitado := LeerBooleano(
      oIni, 'ConnData', 'Pooling', True);
    Result.Perfil.Pool.MinimoConexiones := LeerEntero(
      oIni, 'ConnData', 'PoolMin', 3);
    Result.Perfil.Pool.MaximoConexiones := LeerEntero(
      oIni, 'ConnData', 'PoolMax', 30);
    Result.Perfil.Pool.TiempoEsperaSeg := LeerEntero(
      oIni, 'ConnData', 'PoolWaitTimeout', 15);
    Result.Perfil.Pool.TiempoVidaSeg := LeerEntero(
      oIni, 'ConnData', 'PoolLifetime', 0);
    Result.Perfil.Pool.Validar := LeerBooleano(
      oIni, 'ConnData', 'PoolValidate', True);
    Result.Perfil.RutaCertificadoCA := oIni.ReadString(
      'ConnData', 'SSLCACert', '');
    Result.Perfil.RutaCertificadoCliente := oIni.ReadString(
      'ConnData', 'SSLCert', '');
    Result.Perfil.RutaClavePrivada := oIni.ReadString(
      'ConnData', 'SSLKey', '');
    sReferenciaLegada := ReferenciaCredencialLegada(
      Result.Perfil.Id);
    sReferenciaConfigurada := Trim(oIni.ReadString(
      'ConnData', 'CredentialRef', ''));
    bMigrarReferenciaPredeterminada :=
      (sReferenciaConfigurada = '') or
      SameText(sReferenciaConfigurada, sReferenciaLegada);
    if bMigrarReferenciaPredeterminada then
    begin
      Result.ReferenciaCredencial :=
        ReferenciaCredencialConexionPredeterminada(
          Result.Perfil.Id,
          ARutaIni);
    end
    else
      Result.ReferenciaCredencial := sReferenciaConfigurada;
    ValidarReferenciaCredencial(Result.ReferenciaCredencial);
    // El propio perfil es la fuente principal de la credencial: asi
    // se puede aprovisionar un equipo o un usuario copiando el INI. El
    // almacén de Windows solo se lee para recuperar instalaciones
    // anteriores; la siguiente escritura la lleva al perfil.
    sClaveLegada := Trim(oIni.ReadString(
      'ConnData', 'PasswordEn', ''));
    if sClaveLegada <> '' then
    begin
      Result.Credencial := DescifrarAES(sClaveLegada);
      if Result.Credencial = '' then
        raise EConvertError.Create(
          SErrorCredencialLegadaInvalida);
    end
    else if LeerCredencialConexionWindows(
              Result.ReferenciaCredencial,
              Result.Credencial) then
      Result.ProcedeDeFormatoLegado := True
    else if bMigrarReferenciaPredeterminada and
            not SameText(
              Result.ReferenciaCredencial,
              sReferenciaLegada) and
            LeerCredencialConexionWindows(
              sReferenciaLegada,
              Result.Credencial) then
    begin
      Result.ReferenciaCredencialAnterior :=
        sReferenciaLegada;
      Result.ProcedeDeFormatoLegado := True;
    end;
    if not ValidarPerfilConexion(Result.Perfil, sMotivo) then
      raise EArgumentException.Create(
        Format(SErrorPerfilConexionNoValido, [sMotivo]));
  finally
    oIni.Free;
  end;
end;

procedure GuardarConfiguracionConexionIni(
  const ARutaIni: string;
  const AConfiguracion: TConfiguracionConexionResuelta);
var
  oIni: TIniFile;
  sMotivo: string;
begin
  if Trim(ARutaIni) = '' then
    raise EArgumentException.Create(
      SErrorRutaPerfilConexionObligatoria);
  if not ValidarPerfilConexion(AConfiguracion.Perfil, sMotivo) then
    raise EArgumentException.Create(
      Format(SErrorPerfilConexionNoValido, [sMotivo]));
  ValidarReferenciaCredencial(AConfiguracion.ReferenciaCredencial);
  oIni := TIniFile.Create(ARutaIni);
  try
    oIni.WriteString(
      'ConnData', 'ProfileId', AConfiguracion.Perfil.Id);
    oIni.WriteString(
      'ConnData', 'Motor', NombreMotorBBDD(AConfiguracion.Perfil.Motor));
    oIni.WriteString(
      'ConnData', 'HostName', AConfiguracion.Perfil.Servidor);
    oIni.WriteInteger(
      'ConnData', 'Puerto', AConfiguracion.Perfil.Puerto);
    oIni.WriteString(
      'ConnData', 'Database', AConfiguracion.Perfil.BaseDatos);
    oIni.WriteString(
      'ConnData', 'Schema', AConfiguracion.Perfil.Esquema);
    oIni.WriteString(
      'ConnData', 'User', AConfiguracion.Perfil.Usuario);
    oIni.WriteString(
      'ConnData', 'SSLMode', NombreModoSSLConexion(AConfiguracion.Perfil.SSL));
    oIni.WriteInteger(
      'ConnData',
      'ConnectionTimeout',
      AConfiguracion.Perfil.TimeoutConexionSeg);
    oIni.WriteInteger(
      'ConnData',
      'CommandTimeout',
      AConfiguracion.Perfil.TimeoutComandoSeg);
    oIni.WriteBool(
      'ConnData', 'Pooling', AConfiguracion.Perfil.Pool.Habilitado);
    oIni.WriteInteger(
      'ConnData', 'PoolMin', AConfiguracion.Perfil.Pool.MinimoConexiones);
    oIni.WriteInteger(
      'ConnData', 'PoolMax', AConfiguracion.Perfil.Pool.MaximoConexiones);
    oIni.WriteInteger(
      'ConnData',
      'PoolWaitTimeout',
      AConfiguracion.Perfil.Pool.TiempoEsperaSeg);
    oIni.WriteInteger(
      'ConnData',
      'PoolLifetime',
      AConfiguracion.Perfil.Pool.TiempoVidaSeg);
    oIni.WriteBool(
      'ConnData', 'PoolValidate', AConfiguracion.Perfil.Pool.Validar);
    oIni.WriteString(
      'ConnData',
      'SSLCACert',
      AConfiguracion.Perfil.RutaCertificadoCA);
    oIni.WriteString(
      'ConnData',
      'SSLCert',
      AConfiguracion.Perfil.RutaCertificadoCliente);
    oIni.WriteString(
      'ConnData',
      'SSLKey',
      AConfiguracion.Perfil.RutaClavePrivada);
    oIni.WriteString(
      'ConnData',
      'CredentialRef',
      AConfiguracion.ReferenciaCredencial);
    // Una credencial vacía no se cifra: al releerla daría un
    // texto vacío y el perfil quedaría ilegible.
    if AConfiguracion.Credencial <> '' then
    begin
      oIni.WriteString(
        'ConnData',
        'PasswordEn',
        CifrarAES(AConfiguracion.Credencial));
      if oIni.ReadString('ConnData', 'PasswordEn', '') = '' then
        raise EInOutError.Create(
          SErrorGuardarCredencialIni);
    end
    else
    begin
      oIni.DeleteKey('ConnData', 'PasswordEn');
      if oIni.ValueExists('ConnData', 'PasswordEn') then
        raise EInOutError.Create(
          SErrorEliminarCredencialLegadaIni);
    end;
  finally
    oIni.Free;
  end;
  if (AConfiguracion.ReferenciaCredencialAnterior <> '') and
     not SameText(
       AConfiguracion.ReferenciaCredencialAnterior,
       AConfiguracion.ReferenciaCredencial) then
  begin
    EliminarCredencialConexionWindows(
      AConfiguracion.ReferenciaCredencialAnterior);
  end;
end;

end.
