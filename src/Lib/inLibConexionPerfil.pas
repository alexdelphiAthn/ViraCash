{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConexionPerfil                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Crea, interpreta y valida perfiles de conexión sin conocer adaptadores,   }
{    tecnologías de acceso ni credenciales.                                    }
{******************************************************************************}
unit inLibConexionPerfil;

interface

uses
  inLibConexionPerfilIntf;

function CrearConfiguracionPoolPredeterminada:
  TConfiguracionPoolConexion;
function CrearPerfilConexionPredeterminado(
  AMotor: TMotorBBDD): TPerfilConexion;
function IntentarParsearMotorBBDD(
  const AValor: string;
  out AMotor: TMotorBBDD): Boolean;
function NombreMotorBBDD(
  AMotor: TMotorBBDD): string;
function IntentarParsearModoSSLConexion(
  const AValor: string;
  out AModo: TModoSSLConexion): Boolean;
function NombreModoSSLConexion(
  AModo: TModoSSLConexion): string;
function ValidarPerfilConexion(
  const APerfil: TPerfilConexion;
  out AMotivo: string): Boolean;
function DescribirPerfilConexion(
  const APerfil: TPerfilConexion): string;
function ResolverCapacidadesMotorBBDD(
  AMotor: TMotorBBDD): TCapacidadesMotorBBDD;

implementation

uses
  System.SysUtils,
  inLibMsgConexion;

function NormalizarToken(
  const AValor: string): string;
var
  cCaracter: Char;
  i: Integer;
  sValor: string;
begin
  Result := '';
  sValor := LowerCase(Trim(AValor));
  for i := 1 to Length(sValor) do
  begin
    cCaracter := sValor[i];
    case cCaracter of
      ' ', #9, '-', '_':
        ;
    else
      Result := Result + cCaracter;
    end;
  end;
end;

function TextoSeguro(
  const AValor: string): string;
var
  i: Integer;
begin
  Result := Trim(AValor);
  for i := 1 to Length(Result) do
  begin
    if (Ord(Result[i]) < 32) or
       (Ord(Result[i]) = 127) then
      Result[i] := '?';
  end;
end;

procedure FallarValidacion(
  const AMensaje: string;
  out AMotivo: string);
begin
  AMotivo := AMensaje;
end;

function CrearConfiguracionPoolPredeterminada:
  TConfiguracionPoolConexion;
begin
  Result.Habilitado := False;
  Result.Validar := True;
  Result.MinimoConexiones := 0;
  Result.MaximoConexiones := 30;
  Result.TiempoEsperaSeg := 15;
  Result.TiempoVidaSeg := 300;
end;

function CrearPerfilConexionPredeterminado(
  AMotor: TMotorBBDD): TPerfilConexion;
begin
  Result.Motor := AMotor;
  Result.Servidor := 'localhost';
  Result.BaseDatos := '';
  Result.Usuario := '';
  Result.SSL := sslPreferido;
  Result.TimeoutConexionSeg := 15;
  Result.TimeoutComandoSeg := 30;
  Result.Pool := CrearConfiguracionPoolPredeterminada;
  Result.RutaCertificadoCA := '';
  Result.RutaCertificadoCliente := '';
  Result.RutaClavePrivada := '';
  case AMotor of
    mbMariaDB:
      begin
        Result.Id := 'mariadb';
        Result.Puerto := 3306;
        Result.Esquema := '';
        Result.SSL := sslDesactivado;
      end;
    mbPostgreSQL:
      begin
        Result.Id := 'postgresql';
        Result.Puerto := 5432;
        Result.Esquema := 'public';
      end;
    mbSQLServer:
      begin
        Result.Id := 'sqlserver';
        Result.Puerto := 1433;
        Result.Esquema := 'dbo';
      end;
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

function IntentarParsearMotorBBDD(
  const AValor: string;
  out AMotor: TMotorBBDD): Boolean;
var
  sValor: string;
begin
  sValor := NormalizarToken(AValor);
  Result := True;
  if (sValor = 'mariadb') or
     (sValor = 'maria') or
     (sValor = 'mysql') then
    AMotor := mbMariaDB
  else if (sValor = 'postgresql') or
          (sValor = 'postgres') or
          (sValor = 'pgsql') or
          (sValor = 'postgre') then
    AMotor := mbPostgreSQL
  else if (sValor = 'sqlserver') or
          (sValor = 'mssql') or
          (sValor = 'sqlsrv') then
    AMotor := mbSQLServer
  else
    Result := False;
end;

function NombreMotorBBDD(
  AMotor: TMotorBBDD): string;
begin
  case AMotor of
    mbMariaDB:
      Result := 'MariaDB';
    mbPostgreSQL:
      Result := 'PostgreSQL';
    mbSQLServer:
      Result := 'SQL Server';
  else
    Result := 'Desconocido';
  end;
end;

function IntentarParsearModoSSLConexion(
  const AValor: string;
  out AModo: TModoSSLConexion): Boolean;
var
  sValor: string;
begin
  sValor := NormalizarToken(AValor);
  Result := True;
  if (sValor = 'desactivado') or
     (sValor = 'deshabilitado') or
     (sValor = 'disabled') or
     (sValor = 'disable') or
     (sValor = 'off') or
     (sValor = 'none') or
     (sValor = 'no') or
     (sValor = 'false') then
    AModo := sslDesactivado
  else if (sValor = 'preferido') or
          (sValor = 'preferred') or
          (sValor = 'prefer') then
    AModo := sslPreferido
  else if (sValor = 'requerido') or
          (sValor = 'required') or
          (sValor = 'require') or
          (sValor = 'on') or
          (sValor = 'yes') or
          (sValor = 'si') or
          (sValor = 'true') then
    AModo := sslRequerido
  else if (sValor = 'verificarca') or
          (sValor = 'verifyca') or
          (sValor = 'ca') then
    AModo := sslVerificarCA
  else if (sValor = 'verificarcompleto') or
          (sValor = 'verifyfull') or
          (sValor = 'full') then
    AModo := sslVerificarCompleto
  else
    Result := False;
end;

function NombreModoSSLConexion(
  AModo: TModoSSLConexion): string;
begin
  case AModo of
    sslDesactivado:
      Result := 'desactivado';
    sslPreferido:
      Result := 'preferido';
    sslRequerido:
      Result := 'requerido';
    sslVerificarCA:
      Result := 'verificar-ca';
    sslVerificarCompleto:
      Result := 'verificar-completo';
  else
    Result := 'desconocido';
  end;
end;

function ValidarDatosBasePerfilConexion(
  const APerfil: TPerfilConexion;
  out AMotivo: string): Boolean;
begin
  AMotivo := '';
  if (Ord(APerfil.Motor) < Ord(Low(TMotorBBDD))) or
     (Ord(APerfil.Motor) > Ord(High(TMotorBBDD))) then
    FallarValidacion(SValidacionMotorBBDD, AMotivo)
  else if Trim(APerfil.Id) = '' then
    FallarValidacion(SValidacionIdPerfilConexion, AMotivo)
  else if Trim(APerfil.Servidor) = '' then
    FallarValidacion(SValidacionServidorConexion, AMotivo)
  else if (APerfil.Puerto < 1) or
          (APerfil.Puerto > 65535) then
    FallarValidacion(SValidacionPuertoConexion, AMotivo)
  else if Trim(APerfil.BaseDatos) = '' then
    FallarValidacion(SValidacionBaseDatosConexion, AMotivo)
  else if (APerfil.Motor in [mbPostgreSQL, mbSQLServer]) and
          (Trim(APerfil.Esquema) = '') then
    FallarValidacion(SValidacionEsquemaMotor, AMotivo)
  else if Trim(APerfil.Usuario) = '' then
    FallarValidacion(SValidacionUsuarioConexion, AMotivo)
  else if (Ord(APerfil.SSL) < Ord(Low(TModoSSLConexion))) or
          (Ord(APerfil.SSL) > Ord(High(TModoSSLConexion))) then
    FallarValidacion(SValidacionModoSSLConexion, AMotivo)
  else if APerfil.TimeoutConexionSeg <= 0 then
    FallarValidacion(SValidacionTimeoutConexion, AMotivo)
  else if APerfil.TimeoutComandoSeg <= 0 then
    FallarValidacion(SValidacionTimeoutComando, AMotivo);
  Result := AMotivo = '';
end;

function ValidarPoolPerfilConexion(
  const APerfil: TPerfilConexion;
  out AMotivo: string): Boolean;
begin
  AMotivo := '';
  if APerfil.Pool.MinimoConexiones < 0 then
    FallarValidacion(SValidacionPoolMinimoNegativo, AMotivo)
  else if APerfil.Pool.MaximoConexiones < 0 then
    FallarValidacion(SValidacionPoolMaximoNegativo, AMotivo)
  else if APerfil.Pool.TiempoEsperaSeg < 0 then
    FallarValidacion(SValidacionPoolEsperaNegativa, AMotivo)
  else if APerfil.Pool.TiempoVidaSeg < 0 then
    FallarValidacion(SValidacionPoolVidaNegativa, AMotivo)
  else if APerfil.Pool.TiempoVidaSeg > (MaxInt div 1000) then
    FallarValidacion(SValidacionPoolVidaFueraDeRango, AMotivo)
  else if APerfil.Pool.Habilitado and
          (APerfil.Pool.MaximoConexiones = 0) then
    FallarValidacion(SValidacionPoolMaximoCero, AMotivo)
  else if APerfil.Pool.Habilitado and
          (APerfil.Pool.MinimoConexiones >
           APerfil.Pool.MaximoConexiones) then
    FallarValidacion(SValidacionPoolMinimoMayorMaximo, AMotivo)
  else if APerfil.Pool.Habilitado and
          (APerfil.Pool.TiempoEsperaSeg = 0) then
    FallarValidacion(SValidacionPoolEsperaCero, AMotivo);
  Result := AMotivo = '';
end;

function ValidarSslPerfilConexion(
  const APerfil: TPerfilConexion;
  out AMotivo: string): Boolean;
begin
  AMotivo := '';
  if (APerfil.SSL = sslDesactivado) and
     ((Trim(APerfil.RutaCertificadoCA) <> '') or
      (Trim(APerfil.RutaCertificadoCliente) <> '') or
      (Trim(APerfil.RutaClavePrivada) <> '')) then
    FallarValidacion(SValidacionCertificadosSinSSL, AMotivo)
  else if (APerfil.SSL in [sslVerificarCA, sslVerificarCompleto]) and
          (Trim(APerfil.RutaCertificadoCA) = '') then
    FallarValidacion(SValidacionCertificadoCA, AMotivo)
  else if (Trim(APerfil.RutaCertificadoCliente) = '') <>
          (Trim(APerfil.RutaClavePrivada) = '') then
    FallarValidacion(SValidacionCertificadoCliente, AMotivo);
  Result := AMotivo = '';
end;

function ValidarPerfilConexion(
  const APerfil: TPerfilConexion;
  out AMotivo: string): Boolean;
begin
  Result := ValidarDatosBasePerfilConexion(APerfil, AMotivo);
  if Result then
    Result := ValidarPoolPerfilConexion(APerfil, AMotivo);
  if Result then
    Result := ValidarSslPerfilConexion(APerfil, AMotivo);
end;

function DescribirPerfilConexion(
  const APerfil: TPerfilConexion): string;
var
  sEsquema: string;
begin
  sEsquema := '';
  if Trim(APerfil.Esquema) <> '' then
    sEsquema := Format(
      SDescripcionEsquemaConexion,
      [TextoSeguro(APerfil.Esquema)]);
  Result := Format(
    SDescripcionPerfilConexion,
    [TextoSeguro(APerfil.Id),
     NombreMotorBBDD(APerfil.Motor),
     TextoSeguro(APerfil.Servidor),
     APerfil.Puerto,
     TextoSeguro(APerfil.BaseDatos),
     sEsquema,
     NombreModoSSLConexion(APerfil.SSL)]);
end;

function ResolverCapacidadesMotorBBDD(
  AMotor: TMotorBBDD): TCapacidadesMotorBBDD;
begin
  Result.Motor := AMotor;
  Result.SoportaLimit := True;
  Result.SoportaInformationSchema := True;
  Result.SoportaProcedimientos := True;
  case AMotor of
    mbMariaDB:
      begin
        Result.SoportaEsquemas := False;
        Result.SoportaReturning := False;
        Result.SoportaJsonNativo := False;
        Result.SoportaSecuencias := False;
        Result.SoportaIdentity := False;
        Result.SoportaBloqueoSkipLocked := False;
      end;
    mbPostgreSQL:
      begin
        Result.SoportaEsquemas := True;
        Result.SoportaReturning := True;
        Result.SoportaJsonNativo := True;
        Result.SoportaSecuencias := True;
        Result.SoportaIdentity := True;
        Result.SoportaBloqueoSkipLocked := True;
      end;
    mbSQLServer:
      begin
        Result.SoportaEsquemas := True;
        Result.SoportaReturning := False;
        Result.SoportaJsonNativo := False;
        Result.SoportaSecuencias := True;
        Result.SoportaIdentity := True;
        Result.SoportaLimit := False;
        Result.SoportaBloqueoSkipLocked := False;
      end;
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

end.
