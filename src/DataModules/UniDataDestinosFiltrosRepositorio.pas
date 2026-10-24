{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDestinosFiltrosRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de destinos disponibles para compartir filtros.       }
{******************************************************************************}
unit UniDataDestinosFiltrosRepositorio;

interface

uses
  Uni, inLibDestinosFiltrosPersistenciaIntf;

function CrearRepositorioDestinosFiltrosUniDAC(
  AConexion: TUniConnection): IRepositorioDestinosFiltros;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_CONSULTAR_USUARIOS =
    'SELECT USUARIO_USU AS USUARIO FROM fza_usuarios ' +
    'WHERE COALESCE(ESACTIVO_USU, ''S'') = ''S'' ' +
    'AND USUARIO_USU <> :USUARIOACTUAL ORDER BY USUARIO_USU';
  SQL_CONSULTAR_GRUPOS =
    'SELECT GRUPO_USUGRP AS GRUPO FROM fza_usuarios_grupos ' +
    'ORDER BY GRUPO_USUGRP';

type
  TResultadoDestinosFiltrosUniDAC = class(
    TInterfacedObject,
    IResultadoDestinosFiltros)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioDestinosFiltrosUniDAC = class(
    TInterfacedObject,
    IRepositorioDestinosFiltros)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarUsuarios(
      const AUsuarioActual: string): IResultadoDestinosFiltros;
    function ConsultarGrupos: IResultadoDestinosFiltros;
  end;

constructor TResultadoDestinosFiltrosUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoDestinosFiltrosUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoDestinosFiltrosUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioDestinosFiltrosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDestinosFiltrosUniDAC.ConsultarUsuarios(
  const AUsuarioActual: string): IResultadoDestinosFiltros;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_USUARIOS;
    oConsulta.ParamByName('USUARIOACTUAL').AsString := AUsuarioActual;
    oConsulta.Open;
    Result := TResultadoDestinosFiltrosUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TRepositorioDestinosFiltrosUniDAC.ConsultarGrupos:
  IResultadoDestinosFiltros;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_GRUPOS;
    oConsulta.Open;
    Result := TResultadoDestinosFiltrosUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function CrearRepositorioDestinosFiltrosUniDAC(
  AConexion: TUniConnection): IRepositorioDestinosFiltros;
begin
  Result := TRepositorioDestinosFiltrosUniDAC.Create(AConexion);
end;

end.
