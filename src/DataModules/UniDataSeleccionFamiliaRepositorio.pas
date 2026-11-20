{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataSeleccionFamiliaRepositorio                          }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del selector jerarquico de familias.                  }
{******************************************************************************}
unit UniDataSeleccionFamiliaRepositorio;

interface

uses
  Uni, inLibSeleccionFamiliaPersistenciaIntf;

function CrearRepositorioSeleccionFamiliaUniDAC(
  AConexion: TUniConnection): IRepositorioSeleccionFamilia;

function LeerRutaFamiliaUniDAC(AConexion: TUniConnection;
  const ACodigoFamilia: string): string;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_LISTAR_FAMILIAS =
    'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM, ' +
    'COALESCE(CODIGO_PADRE_FAM, '''') AS CODIGO_PADRE_FAM ' +
    'FROM fza_articulos_familias WHERE ESACTIVO_FAM = ''S'' ' +
    'ORDER BY ORDEN_FAM, NOMBRE_FAM_FAM';
  SQL_FILTRAR_FAMILIAS =
    'SELECT CODIGO_FAM_FAM, NOMBRE_FAM_FAM, ' +
    ''''' AS CODIGO_PADRE_FAM FROM fza_articulos_familias ' +
    'WHERE ESACTIVO_FAM = ''S'' ' +
    'AND (CODIGO_FAM_FAM LIKE :P OR NOMBRE_FAM_FAM LIKE :P) ' +
    'ORDER BY ORDEN_FAM, NOMBRE_FAM_FAM';

type
  TConsultaSeleccionFamiliaUniDAC = class(
    TInterfacedObject,
    IConsultaSeleccionFamilia)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    function DataSet: TDataSet;
    procedure AplicarFiltro(const AFiltro: string);
  end;

  TRepositorioSeleccionFamiliaUniDAC = class(
    TInterfacedObject,
    IRepositorioSeleccionFamilia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function CrearConsulta: IConsultaSeleccionFamilia;
  end;

constructor TConsultaSeleccionFamiliaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := AConexion;
end;

destructor TConsultaSeleccionFamiliaUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaSeleccionFamiliaUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

procedure TConsultaSeleccionFamiliaUniDAC.AplicarFiltro(
  const AFiltro: string);
begin
  FConsulta.Close;
  if AFiltro = '' then
  begin
    FConsulta.SQL.Text := SQL_LISTAR_FAMILIAS;
  end
  else
  begin
    FConsulta.SQL.Text := SQL_FILTRAR_FAMILIAS;
    FConsulta.ParamByName('P').AsString := '%' + AFiltro + '%';
  end;
  FConsulta.Open;
end;

constructor TRepositorioSeleccionFamiliaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioSeleccionFamiliaUniDAC.CrearConsulta:
  IConsultaSeleccionFamilia;
begin
  Result := TConsultaSeleccionFamiliaUniDAC.Create(FConexion);
end;

function CrearRepositorioSeleccionFamiliaUniDAC(
  AConexion: TUniConnection): IRepositorioSeleccionFamilia;
begin
  Result := TRepositorioSeleccionFamiliaUniDAC.Create(AConexion);
end;

function LeerRutaFamiliaUniDAC(AConexion: TUniConnection;
  const ACodigoFamilia: string): string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  if Trim(ACodigoFamilia) <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      Consulta.SQL.Text :=
        'WITH RECURSIVE RAMA AS ( ' +
        ' SELECT F.CODIGO_PADRE_FAM, 0 AS NIVEL, ' +
        '        CAST(COALESCE(NULLIF(F.NOMBRE_FAM_FAM, ''''), ' +
        '             F.CODIGO_FAM_FAM) AS CHAR(16000)) AS RUTA, ' +
        '        CAST(HEX(F.CODIGO_FAM_FAM) AS CHAR(16000)) AS VISITADAS ' +
        ' FROM fza_articulos_familias F WHERE F.CODIGO_FAM_FAM = :FAM ' +
        ' UNION ALL ' +
        ' SELECT P.CODIGO_PADRE_FAM, R.NIVEL + 1, ' +
        '        CONCAT(COALESCE(NULLIF(P.NOMBRE_FAM_FAM, ''''), ' +
        '               P.CODIGO_FAM_FAM), '' -> '', R.RUTA), ' +
        '        CONCAT(R.VISITADAS, '','', HEX(P.CODIGO_FAM_FAM)) ' +
        ' FROM RAMA R JOIN fza_articulos_familias P ' +
        '   ON P.CODIGO_FAM_FAM = R.CODIGO_PADRE_FAM ' +
        ' WHERE FIND_IN_SET(HEX(P.CODIGO_FAM_FAM), R.VISITADAS) = 0 ' +
        ') SELECT RUTA FROM RAMA ORDER BY NIVEL DESC LIMIT 1';
      Consulta.ParamByName('FAM').AsString := ACodigoFamilia;
      Consulta.Open;
      if not Consulta.IsEmpty then
        Result := Consulta.FieldByName('RUTA').AsString;
    finally
      Consulta.Free;
    end;
  end;
end;

end.
