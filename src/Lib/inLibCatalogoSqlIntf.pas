{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos del catálogo de SQL sustituible mediante perfiles.              }
{******************************************************************************}
unit inLibCatalogoSqlIntf;

interface

uses
  System.SysUtils,
  inLibConexionPerfilIntf;

const
  CLAVE_PERFIL_CATALOGO_SQL = 'SQL_REPOSITORIOS';
  CLAVE_PERFIL_CATALOGO_SQL_POSTGRESQL =
    'SQL_REPOSITORIOS_POSTGRESQL';
  CLAVE_PERFIL_CATALOGO_SQL_SERVER =
    'SQL_REPOSITORIOS_SQLSERVER';

type
  EVarianteSqlMotorNoDisponible = class(Exception);
  TTipoSentenciaSql = (
    tssSelect,
    tssInsert,
    tssUpdate,
    tssDelete,
    tssCall);
  TOrigenSql = (
    osBase,
    osPerfil);
  TPoliticaEjecucionSql = (
    pesSoloBase,
    pesPerfilLecturaConFallback,
    pesPerfilEscrituraTransaccional);
  TDefinicionSql = record
    Repositorio: string;
    Operacion: string;
    SqlBase: string;
    Parametros: string;
    CamposResultado: string;
    TipoSentencia: TTipoSentenciaSql;
    Politica: TPoliticaEjecucionSql;
    Version: Integer;
    SqlPorMotor: array[TMotorBBDD] of string;
  end;
  TSqlResuelto = record
    Texto: string;
    TextoBase: string;
    ClavePerfil: string;
    MotivoSqlBase: string;
    Origen: TOrigenSql;
    Politica: TPoliticaEjecucionSql;
    Motor: TMotorBBDD;
  end;
  TResultadoValidacionSql = record
    EsValido: Boolean;
    Mensaje: string;
    Huella: string;
  end;
  TDefinicionesSql = array of TDefinicionSql;
  TProcedimientoEjecutarSql = reference to procedure(
    const ASql: string);
  ICatalogoSql = interface
    ['{E433B667-26D4-48F8-A16C-DCC47279640A}']
    function GetMotor: TMotorBBDD;
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
    property Motor: TMotorBBDD read GetMotor;
  end;
  IRegistroDefinicionesSql = interface
    ['{798B2939-93D6-42C9-A76B-5D3BDF3A37D2}']
    function Cantidad: Integer;
    function ObtenerDefiniciones: TDefinicionesSql;
  end;
  IRegistroIncidenciasSql = interface
    ['{4AE44E47-9BB6-43B6-A1E0-90097656C290}']
    procedure Registrar(
      const AClavePerfil, ACausa: string);
    function ObtenerUltimaCausa(
      const AClavePerfil: string): string;
  end;

function CrearDefinicionSql(
  const ARepositorio, AOperacion, ASqlBase,
  AParametros, ACamposResultado: string;
  ATipoSentencia: TTipoSentenciaSql;
  APolitica: TPoliticaEjecucionSql;
  AVersion: Integer = 1): TDefinicionSql;
function ClavePerfilSql(
  const ADefinicion: TDefinicionSql): string;
function ClavePerfilCatalogoSql(
  AMotor: TMotorBBDD): string;
function ConVarianteSqlMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD;
  const ASql: string): TDefinicionSql;
function TieneVarianteSqlMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD): Boolean;
function ObtenerSqlBaseMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD): string;
function NombrePoliticaEjecucionSql(
  APolitica: TPoliticaEjecucionSql): string;
function ResolverSqlBase(
  const ADefinicion: TDefinicionSql;
  const AMotivo: string = ''): TSqlResuelto;
function ResolverSqlBaseMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD;
  const AMotivo: string = ''): TSqlResuelto;

implementation

uses
  inLibConexionPerfil,
  inLibMsgConexion,
  inLibMsgSql;

function CrearDefinicionSql(
  const ARepositorio, AOperacion, ASqlBase,
  AParametros, ACamposResultado: string;
  ATipoSentencia: TTipoSentenciaSql;
  APolitica: TPoliticaEjecucionSql;
  AVersion: Integer): TDefinicionSql;
var
  eMotor: TMotorBBDD;
begin
  Result := Default(TDefinicionSql);
  Result.Repositorio := ARepositorio;
  Result.Operacion := AOperacion;
  Result.SqlBase := ASqlBase;
  Result.Parametros := AParametros;
  Result.CamposResultado := ACamposResultado;
  Result.TipoSentencia := ATipoSentencia;
  Result.Politica := APolitica;
  Result.Version := AVersion;
  for eMotor := Low(TMotorBBDD) to High(TMotorBBDD) do
    Result.SqlPorMotor[eMotor] := '';
  Result.SqlPorMotor[mbMariaDB] := ASqlBase;
end;

function ClavePerfilSql(
  const ADefinicion: TDefinicionSql): string;
begin
  Result := 'SQL__' + ADefinicion.Repositorio + '__' +
    ADefinicion.Operacion;
end;

function ClavePerfilCatalogoSql(
  AMotor: TMotorBBDD): string;
begin
  case AMotor of
    mbMariaDB:
      Result := CLAVE_PERFIL_CATALOGO_SQL;
    mbPostgreSQL:
      Result := CLAVE_PERFIL_CATALOGO_SQL_POSTGRESQL;
    mbSQLServer:
      Result := CLAVE_PERFIL_CATALOGO_SQL_SERVER;
  else
    raise EArgumentOutOfRangeException.Create(
      SErrorMotorBBDDNoReconocido);
  end;
end;

function ConVarianteSqlMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD;
  const ASql: string): TDefinicionSql;
begin
  if Trim(ASql) = '' then
    raise EArgumentException.Create(SErrorTextoSqlVacio);
  Result := ADefinicion;
  Result.SqlPorMotor[AMotor] := ASql;
  if AMotor = mbMariaDB then
    Result.SqlBase := ASql;
end;

function TieneVarianteSqlMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD): Boolean;
begin
  Result := Trim(ADefinicion.SqlPorMotor[AMotor]) <> '';
end;

function ObtenerSqlBaseMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD): string;
begin
  if not TieneVarianteSqlMotor(ADefinicion, AMotor) then
    raise EVarianteSqlMotorNoDisponible.CreateFmt(
      SErrorVarianteSqlMotorNoDisponible,
      [ClavePerfilSql(ADefinicion), NombreMotorBBDD(AMotor)]);
  Result := ADefinicion.SqlPorMotor[AMotor];
end;

function NombrePoliticaEjecucionSql(
  APolitica: TPoliticaEjecucionSql): string;
begin
  case APolitica of
    pesSoloBase:
      Result := 'SOLO_BASE';
    pesPerfilLecturaConFallback:
      Result := 'PERFIL_LECTURA_FALLBACK';
    pesPerfilEscrituraTransaccional:
      Result := 'PERFIL_ESCRITURA_TRANSACCIONAL';
  else
    Result := '';
  end;
end;

function ResolverSqlBase(
  const ADefinicion: TDefinicionSql;
  const AMotivo: string): TSqlResuelto;
begin
  Result := ResolverSqlBaseMotor(
    ADefinicion,
    mbMariaDB,
    AMotivo);
end;

function ResolverSqlBaseMotor(
  const ADefinicion: TDefinicionSql;
  AMotor: TMotorBBDD;
  const AMotivo: string): TSqlResuelto;
begin
  Result := Default(TSqlResuelto);
  Result.TextoBase := ObtenerSqlBaseMotor(
    ADefinicion,
    AMotor);
  Result.Texto := Result.TextoBase;
  Result.ClavePerfil := ClavePerfilSql(ADefinicion);
  Result.MotivoSqlBase := AMotivo;
  Result.Origen := osBase;
  Result.Politica := ADefinicion.Politica;
  Result.Motor := AMotor;
end;

end.
