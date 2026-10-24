{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataGuiasRepositorio                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del constructor visual de guias.                      }
{******************************************************************************}
unit UniDataGuiasRepositorio;

interface

uses
  Uni, inLibGuiasPersistenciaIntf;

function CrearRepositorioGuiasUniDAC(
  AConexion: TUniConnection): IRepositorioGuias;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_CONSULTAR_GUIAS =
    'SELECT * FROM fza_informes_guias ' +
    'WHERE INFORME_INFGUI = :INF ' +
    'ORDER BY ORDEN_INFGUI, CODIGO_INFGUI';
  SQL_LISTAR_TABLAS =
    'SELECT TABLE_NAME FROM information_schema.TABLES ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_TYPE IN (''BASE TABLE'', ''VIEW'') ORDER BY TABLE_NAME';
  SQL_LISTAR_CAMPOS =
    'SELECT COLUMN_NAME FROM information_schema.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :TAB ' +
    'ORDER BY ORDINAL_POSITION';

type
  TNavegadorGuiasUniDAC = class(
    TInterfacedObject,
    INavegadorGuias)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioGuiasUniDAC = class(
    TInterfacedObject,
    IRepositorioGuias)
  private
    FConexion: TUniConnection;
    function ListarNombres(
      const ASql: string;
      const ACampo: string;
      const ATabla: string = ''): TNombresEsquemaGuias;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarGuias(
      const AInforme: string): INavegadorGuias;
    function ListarTablas: TNombresEsquemaGuias;
    function ListarCamposTabla(
      const ATabla: string): TNombresEsquemaGuias;
  end;

constructor TNavegadorGuiasUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TNavegadorGuiasUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TNavegadorGuiasUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioGuiasUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioGuiasUniDAC.ConsultarGuias(
  const AInforme: string): INavegadorGuias;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_GUIAS;
    oConsulta.ParamByName('INF').AsString := AInforme;
    oConsulta.Open;
    Result := TNavegadorGuiasUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TRepositorioGuiasUniDAC.ListarNombres(
  const ASql: string;
  const ACampo: string;
  const ATabla: string): TNombresEsquemaGuias;
var
  iNombre: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    if ATabla <> '' then
    begin
      oConsulta.ParamByName('TAB').AsString := ATabla;
    end;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iNombre := Length(Result);
      SetLength(Result, iNombre + 1);
      Result[iNombre] := oConsulta.FieldByName(ACampo).AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioGuiasUniDAC.ListarTablas: TNombresEsquemaGuias;
begin
  Result := ListarNombres(SQL_LISTAR_TABLAS, 'TABLE_NAME');
end;

function TRepositorioGuiasUniDAC.ListarCamposTabla(
  const ATabla: string): TNombresEsquemaGuias;
begin
  Result := ListarNombres(SQL_LISTAR_CAMPOS, 'COLUMN_NAME', ATabla);
end;

function CrearRepositorioGuiasUniDAC(
  AConexion: TUniConnection): IRepositorioGuias;
begin
  Result := TRepositorioGuiasUniDAC.Create(AConexion);
end;

end.
