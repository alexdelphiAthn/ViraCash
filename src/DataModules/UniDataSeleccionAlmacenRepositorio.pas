{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataSeleccionAlmacenRepositorio                          }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de los selectores de almacen para albaranes.          }
{******************************************************************************}
unit UniDataSeleccionAlmacenRepositorio;

interface

uses
  Uni, inLibSeleccionAlmacenPersistenciaIntf;

function CrearRepositorioSeleccionAlmacenUniDAC(
  AConexion: TUniConnection): IRepositorioSeleccionAlmacen;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_CONSULTAR_ALMACENES =
    'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM FROM fza_almacenes ' +
    'WHERE ESACTIVO_ALM = ''S'' ORDER BY NOMBRE_ALM_ALM';
  SQL_CONSULTAR_TEMPORADAS =
    'SELECT ID_PV_ARTPROP, PV FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = ''TEMPORADA'' AND ESACTIVO_PV = ''S'' ORDER BY PV';
  SQL_CONSULTAR_ALBARANES_VENTA =
    'SELECT NUMERO_ALB, SERIE_ALB, FECHA_ALB, ESTADO_ALB, ' +
    'TOTAL_LIQUIDO_ALB FROM fza_albaranes ' +
    'WHERE NUMERO_PED_ALB = :NP AND SERIE_PED_ALB = :SP ' +
    'AND ESTADO_ALB = ''ABIERTO'' ' +
    'ORDER BY FECHA_ALB DESC, NUMERO_ALB DESC';
  SQL_CONSULTAR_ALBARANES_COMPRA =
    'SELECT NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, ESTADO_ALBC, ' +
    'TOTAL_LIQUIDO_ALBC FROM fza_albaranes_compra ' +
    'WHERE NUMERO_PED_ALBC = :NP AND SERIE_PED_ALBC = :SP ' +
    'AND IFNULL(ESTADO_ALBC, '''') NOT IN (''FACTURADO'', ''CANCELADO'') ' +
    'ORDER BY FECHA_ALBC DESC, NUMERO_ALBC DESC';
  SQL_LISTAR_SERIES =
    'SELECT EMPSER FROM vi_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIP ' +
    'AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
    'AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
    'GROUP BY EMPSER ' +
    'ORDER BY MAX(ESDEFECTO_EMPSER) DESC, EMPSER';
  SQL_OBTENER_SERIE_ALMACEN =
    'SELECT EMPSER FROM vi_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP AND TIPO_DOC_EMPSER = :TIP ' +
    'AND CODIGO_ALM_EMPSER = :ALM ' +
    'AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= CURDATE()) ' +
    'AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= CURDATE()) ' +
    'ORDER BY ESDEFECTO_EMPSER DESC, EMPSER ' +
    'LIMIT 1';

type
  TConsultaSeleccionAlmacenUniDAC = class(
    TInterfacedObject,
    IConsultaSeleccionAlmacen)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioSeleccionAlmacenUniDAC = class(
    TInterfacedObject,
    IRepositorioSeleccionAlmacen)
  private
    FConexion: TUniConnection;
    function CrearConsulta(
      const ASql: string;
      const ANumeroPedido: string = '';
      const ASeriePedido: string = ''): IConsultaSeleccionAlmacen;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarAlmacenes: IConsultaSeleccionAlmacen;
    function ConsultarTemporadas: IConsultaSeleccionAlmacen;
    function ConsultarAlbaranesVenta(
      const ANumeroPedido: string;
      const ASeriePedido: string): IConsultaSeleccionAlmacen;
    function ConsultarAlbaranesCompra(
      const ANumeroPedido: string;
      const ASeriePedido: string): IConsultaSeleccionAlmacen;
    function ListarSeries(
      const AEmpresa: string;
      const ATipoDocumento: string): TSeriesSeleccionAlmacen;
    function ObtenerSerieAlmacen(
      const AEmpresa: string;
      const ATipoDocumento: string;
      const AAlmacen: string): string;
  end;

constructor TConsultaSeleccionAlmacenUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaSeleccionAlmacenUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaSeleccionAlmacenUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioSeleccionAlmacenUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioSeleccionAlmacenUniDAC.CrearConsulta(
  const ASql: string;
  const ANumeroPedido: string;
  const ASeriePedido: string): IConsultaSeleccionAlmacen;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    if ANumeroPedido <> '' then
    begin
      oConsulta.ParamByName('NP').AsString := ANumeroPedido;
      oConsulta.ParamByName('SP').AsString := ASeriePedido;
    end;
    oConsulta.Open;
    Result := TConsultaSeleccionAlmacenUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TRepositorioSeleccionAlmacenUniDAC.ConsultarAlmacenes:
  IConsultaSeleccionAlmacen;
begin
  Result := CrearConsulta(SQL_CONSULTAR_ALMACENES);
end;

function TRepositorioSeleccionAlmacenUniDAC.ConsultarTemporadas:
  IConsultaSeleccionAlmacen;
begin
  Result := CrearConsulta(SQL_CONSULTAR_TEMPORADAS);
end;

function TRepositorioSeleccionAlmacenUniDAC.ConsultarAlbaranesVenta(
  const ANumeroPedido: string;
  const ASeriePedido: string): IConsultaSeleccionAlmacen;
begin
  Result := CrearConsulta(
    SQL_CONSULTAR_ALBARANES_VENTA,
    ANumeroPedido,
    ASeriePedido);
end;

function TRepositorioSeleccionAlmacenUniDAC.ConsultarAlbaranesCompra(
  const ANumeroPedido: string;
  const ASeriePedido: string): IConsultaSeleccionAlmacen;
begin
  Result := CrearConsulta(
    SQL_CONSULTAR_ALBARANES_COMPRA,
    ANumeroPedido,
    ASeriePedido);
end;

function TRepositorioSeleccionAlmacenUniDAC.ListarSeries(
  const AEmpresa: string;
  const ATipoDocumento: string): TSeriesSeleccionAlmacen;
var
  iSerie: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_SERIES;
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.ParamByName('TIP').AsString := ATipoDocumento;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iSerie := Length(Result);
      SetLength(Result, iSerie + 1);
      Result[iSerie] := oConsulta.FieldByName('EMPSER').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioSeleccionAlmacenUniDAC.ObtenerSerieAlmacen(
  const AEmpresa: string;
  const ATipoDocumento: string;
  const AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Trim(AAlmacen) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SQL_OBTENER_SERIE_ALMACEN;
      oConsulta.ParamByName('EMP').AsString := AEmpresa;
      oConsulta.ParamByName('TIP').AsString := ATipoDocumento;
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
end;

function CrearRepositorioSeleccionAlmacenUniDAC(
  AConexion: TUniConnection): IRepositorioSeleccionAlmacen;
begin
  Result := TRepositorioSeleccionAlmacenUniDAC.Create(AConexion);
end;

end.
