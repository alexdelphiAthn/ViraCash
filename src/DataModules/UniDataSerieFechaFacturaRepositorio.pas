{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataSerieFechaFacturaRepositorio                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del selector de serie y fecha de factura.             }
{******************************************************************************}
unit UniDataSerieFechaFacturaRepositorio;

interface

uses
  Uni, inLibSerieFechaFacturaPersistenciaIntf;

function CrearRepositorioSerieFechaFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioSerieFechaFactura;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_CONSULTAR_SERIES =
    'SELECT SERIES.SERIE_CON, ' +
    '       MAX(SERIES.DEFAULT_CON) AS DEFAULT_CON ' +
    '  FROM (SELECT SERIE_CON, DEFAULT_CON ' +
    '          FROM fza_contadores ' +
    '         WHERE TIPO_DOC_CON = ''FC'' ' +
    '           AND ESACTIVO_CON = ''S'' ' +
    '           AND EMPRESA_CON IN (:EMP, ''-'') ' +
    '         UNION ALL ' +
    '        SELECT EMPSER AS SERIE_CON, ''N'' AS DEFAULT_CON ' +
    '          FROM vi_empresas_series ' +
    '         WHERE CODIGO_EMP_EMPSER = :EMP ' +
    '           AND TIPO_DOC_EMPSER = ''FC'' ' +
    '           AND (SUBTIPO_EMPSER = ''NORMAL'' ' +
    '                OR IFNULL(SUBTIPO_EMPSER, '''') = '''') ' +
    '           AND (FECHA_DESDE_EMPSER IS NULL ' +
    '                OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
    '           AND (FECHA_HASTA_EMPSER IS NULL ' +
    '                OR FECHA_HASTA_EMPSER >= CURDATE())) SERIES ' +
    ' GROUP BY SERIES.SERIE_CON ' +
    ' ORDER BY DEFAULT_CON DESC, SERIES.SERIE_CON';
  SQL_OBTENER_SERIE_ALMACEN =
    'SELECT EMPSER FROM vi_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = ''FC'' ' +
    'AND CODIGO_ALM_EMPSER = :ALM ' +
    'AND (SUBTIPO_EMPSER = ''NORMAL'' ' +
    '     OR IFNULL(SUBTIPO_EMPSER, '''') = '''') ' +
    'AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
    'AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
    'ORDER BY CASE WHEN SUBTIPO_EMPSER = ''NORMAL'' THEN 0 ELSE 1 END, ' +
    'ESDEFECTO_EMPSER DESC, EMPSER ' +
    'LIMIT 1';

type
  TConsultaSeriesFacturaUniDAC = class(
    TInterfacedObject,
    IConsultaSeriesFactura)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioSerieFechaFacturaUniDAC = class(
    TInterfacedObject,
    IRepositorioSerieFechaFactura)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarSeries(
      const AEmpresa: string): IConsultaSeriesFactura;
    function ObtenerSerieAlmacen(
      const AEmpresa: string;
      const AAlmacen: string): string;
  end;

constructor TConsultaSeriesFacturaUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaSeriesFacturaUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaSeriesFacturaUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioSerieFechaFacturaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioSerieFechaFacturaUniDAC.ConsultarSeries(
  const AEmpresa: string): IConsultaSeriesFactura;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_CONSULTAR_SERIES;
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.Open;
    Result := TConsultaSeriesFacturaUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TRepositorioSerieFechaFacturaUniDAC.ObtenerSerieAlmacen(
  const AEmpresa: string;
  const AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_OBTENER_SERIE_ALMACEN;
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('EMPSER').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioSerieFechaFacturaUniDAC(
  AConexion: TUniConnection): IRepositorioSerieFechaFactura;
begin
  Result := TRepositorioSerieFechaFacturaUniDAC.Create(AConexion);
end;

end.
