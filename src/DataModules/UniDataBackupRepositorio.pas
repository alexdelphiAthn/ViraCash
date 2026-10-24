{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataBackupRepositorio                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Implementa la persistencia MySQL para crear y restaurar copias.           }
{******************************************************************************}
unit UniDataBackupRepositorio;

interface

uses
  inLibBackupPersistenciaIntf;

function CrearFabricaPersistenciaBackupUniDAC:
  IFabricaPersistenciaBackup;

implementation

uses
  System.Classes, System.Generics.Collections, System.SysUtils,
  Uni, MySQLUniProvider,
  Core_Interfaces, Providers_MySQL, Providers_MySQL_Helpers,
  Backup.Types,
  inLibDBStructure,
  UniDataDBStructureRepositorio;

type
  TPersistenciaBackupBase = class(TInterfacedObject)
  private
    FConfiguracion: TConfiguracionConexionBackup;
    FConexion: TUniConnection;
  protected
    procedure Conectar(const ABaseDatos: string);
    function DelimitarIdentificador(const AIdentificador: string): string;
    property Configuracion: TConfiguracionConexionBackup
      read FConfiguracion;
    property Conexion: TUniConnection read FConexion;
  public
    constructor Create(
      const AConfiguracion: TConfiguracionConexionBackup);
    destructor Destroy; override;
  end;

  TPersistenciaCopiaBackupUniDAC = class(
    TPersistenciaBackupBase,
    IPersistenciaCopiaBackup)
  public
    procedure Preparar;
    function ObtenerServiciosLectura: TServiciosLecturaBBDD;
    function ObtenerServiciosSql: TServiciosSqlBBDD;
    function ObtenerFiltroTraducciones: string;
  end;

  TPersistenciaRestauracionBackupUniDAC = class(
    TPersistenciaBackupBase,
    IPersistenciaRestauracionBackup)
  public
    procedure PrepararDestino;
    procedure EjecutarSentencia(const ASentencia: string);
    procedure NormalizarBaseDatos;
    function ObtenerTablasConColacionNoValida: TArray<string>;
    procedure NormalizarTabla(const ANombreTabla: string);
    procedure ValidarEstructura;
  end;

  TFabricaPersistenciaBackupUniDAC = class(
    TInterfacedObject,
    IFabricaPersistenciaBackup)
  public
    function CrearCopia(
      const AConfiguracion: TConfiguracionConexionBackup):
      IPersistenciaCopiaBackup;
    function CrearRestauracion(
      const AConfiguracion: TConfiguracionConexionBackup):
      IPersistenciaRestauracionBackup;
  end;

constructor TPersistenciaBackupBase.Create(
  const AConfiguracion: TConfiguracionConexionBackup);
begin
  inherited Create;
  FConfiguracion := AConfiguracion;
  FConexion := TUniConnection.Create(nil);
  FConexion.Pooling := False;
end;

destructor TPersistenciaBackupBase.Destroy;
begin
  FreeAndNil(FConexion);
  inherited Destroy;
end;

procedure TPersistenciaBackupBase.Conectar(const ABaseDatos: string);
begin
  FConexion.ProviderName := 'MySQL';
  FConexion.Server := FConfiguracion.Host;
  FConexion.Port := FConfiguracion.Puerto;
  FConexion.Database := ABaseDatos;
  FConexion.Username := FConfiguracion.Usuario;
  FConexion.Password := FConfiguracion.Contrasena;
  FConexion.SpecificOptions.Values['MySQL.UseUnicode'] := 'True';
  FConexion.SpecificOptions.Values['MySQL.Charset'] := 'utf8mb4';
  FConexion.SpecificOptions.Values['ConnectionTimeout'] :=
    IntToStr(FConfiguracion.TimeoutConexionSeg);
  FConexion.LoginPrompt := False;
  FConexion.Connected := True;
end;

function TPersistenciaBackupBase.DelimitarIdentificador(
  const AIdentificador: string): string;
var
  sIdentificador: string;
begin
  sIdentificador := StringReplace(
    AIdentificador,
    '`',
    '``',
    [rfReplaceAll]);
  Result := '`' + sIdentificador + '`';
end;

procedure TPersistenciaCopiaBackupUniDAC.Preparar;
begin
  Conectar(Configuracion.BaseDatos);
  Conexion.ExecSQL(
    'SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
end;

function TPersistenciaCopiaBackupUniDAC.ObtenerServiciosLectura:
  TServiciosLecturaBBDD;
begin
  Result := CrearServiciosLecturaMySQL(
    Conexion,
    Configuracion.BaseDatos);
end;

function TPersistenciaCopiaBackupUniDAC.ObtenerServiciosSql:
  TServiciosSqlBBDD;
begin
  Result := CrearServiciosSqlMySQL;
end;

function TPersistenciaCopiaBackupUniDAC.
  ObtenerFiltroTraducciones: string;
var
  oConsulta: TUniQuery;
begin
  Result := '1 = 0';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := Conexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS TOTAL' +
      '  FROM INFORMATION_SCHEMA.COLUMNS' +
      ' WHERE TABLE_SCHEMA = DATABASE()' +
      '   AND TABLE_NAME = ''fza_traducciones''' +
      '   AND COLUMN_NAME = ''ESDESCARGADA_TRAD''';
    oConsulta.Open;
    if oConsulta.FieldByName('TOTAL').AsInteger > 0 then
    begin
      Result := '`ESDESCARGADA_TRAD` = ''S''';
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TPersistenciaRestauracionBackupUniDAC.PrepararDestino;
var
  sBaseDatos: string;
begin
  Conectar('information_schema');
  Conexion.ExecSQL(
    'SET NAMES utf8mb4 COLLATE utf8mb4_spanish_ci');
  Conexion.ExecSQL(
    'SET SESSION lock_wait_timeout = ' +
    IntToStr(Configuracion.TimeoutComandoSeg));
  sBaseDatos := DelimitarIdentificador(Configuracion.BaseDatos);
  Conexion.ExecSQL(
    'CREATE DATABASE IF NOT EXISTS ' + sBaseDatos +
    ' CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci');
  Conexion.ExecSQL(
    'ALTER DATABASE ' + sBaseDatos +
    ' CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci');
  Conexion.ExecSQL('USE ' + sBaseDatos);
end;

procedure TPersistenciaRestauracionBackupUniDAC.EjecutarSentencia(
  const ASentencia: string);
begin
  Conexion.ExecSQL(ASentencia);
end;

procedure TPersistenciaRestauracionBackupUniDAC.NormalizarBaseDatos;
begin
  Conexion.ExecSQL(
    'ALTER DATABASE ' +
    DelimitarIdentificador(Configuracion.BaseDatos) +
    ' CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci');
end;

function TPersistenciaRestauracionBackupUniDAC.
  ObtenerTablasConColacionNoValida: TArray<string>;
var
  oConsulta: TUniQuery;
  oTablas: TList<string>;
begin
  oTablas := TList<string>.Create;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := Conexion;
      oConsulta.SQL.Text :=
        'SELECT DISTINCT T.TABLE_NAME ' +
        '  FROM INFORMATION_SCHEMA.TABLES T ' +
        ' WHERE T.TABLE_SCHEMA = DATABASE() ' +
        '   AND T.TABLE_TYPE = ''BASE TABLE'' ' +
        '   AND ((T.TABLE_COLLATION IS NOT NULL ' +
        '     AND T.TABLE_COLLATION <> ''utf8mb4_spanish_ci'') ' +
        '     OR EXISTS (SELECT 1 ' +
        '          FROM INFORMATION_SCHEMA.COLUMNS C ' +
        '         WHERE C.TABLE_SCHEMA = T.TABLE_SCHEMA ' +
        '           AND C.TABLE_NAME = T.TABLE_NAME ' +
        '           AND C.CHARACTER_SET_NAME IS NOT NULL ' +
        '           AND (C.CHARACTER_SET_NAME <> ''utf8mb4'' ' +
        '             OR C.COLLATION_NAME <> ' +
        '                ''utf8mb4_spanish_ci''))) ' +
        ' ORDER BY T.TABLE_NAME';
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        oTablas.Add(
          oConsulta.FieldByName('TABLE_NAME').AsString);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    Result := oTablas.ToArray;
  finally
    FreeAndNil(oTablas);
  end;
end;

procedure TPersistenciaRestauracionBackupUniDAC.NormalizarTabla(
  const ANombreTabla: string);
begin
  Conexion.ExecSQL(
    'ALTER TABLE ' + DelimitarIdentificador(ANombreTabla) +
    ' CONVERT TO CHARACTER SET utf8mb4 ' +
    'COLLATE utf8mb4_spanish_ci');
end;

procedure TPersistenciaRestauracionBackupUniDAC.ValidarEstructura;
var
  oResultado: TDBStructureCheckResult;
begin
  oResultado := UniDataDBStructureRepositorio.TDBStructureChecker.Check(
    Conexion,
    Configuracion.BaseDatos);
  if not oResultado.IsOK then
  begin
    raise Exception.Create(oResultado.FormattedMessage);
  end;
end;

function TFabricaPersistenciaBackupUniDAC.CrearCopia(
  const AConfiguracion: TConfiguracionConexionBackup):
  IPersistenciaCopiaBackup;
begin
  Result := TPersistenciaCopiaBackupUniDAC.Create(AConfiguracion);
end;

function TFabricaPersistenciaBackupUniDAC.CrearRestauracion(
  const AConfiguracion: TConfiguracionConexionBackup):
  IPersistenciaRestauracionBackup;
begin
  Result := TPersistenciaRestauracionBackupUniDAC.Create(AConfiguracion);
end;

function CrearFabricaPersistenciaBackupUniDAC:
  IFabricaPersistenciaBackup;
begin
  Result := TFabricaPersistenciaBackupUniDAC.Create;
end;

end.
