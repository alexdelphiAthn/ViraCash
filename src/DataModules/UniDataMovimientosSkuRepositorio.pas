{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataMovimientosSkuRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       07/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Consulta el kardex de un SKU y ejecuta la reconstruccion global de stock. }
{******************************************************************************}
unit UniDataMovimientosSkuRepositorio;

interface

uses
  Uni, inLibMovimientosSkuPersistenciaIntf;

function CrearRepositorioMovimientosSkuUniDAC(
  AConexion: TUniConnection): IRepositorioMovimientosSku;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Data.DB,
  inLibPrestaShopColaSenal;

const
  SQL_MOVIMIENTOS_SKU =
    'SELECT m.NUMERO_MOV, m.FECHA_MOV, m.TIPO_DOC_MOV, ' +
    'm.SERIE_DOC_MOV, m.NUMERO_DOC_MOV, m.LINEA_MOV, ' +
    'm.CODIGO_ALM_MOV, m.CODIGO_ALM_CONTRA_MOV, m.TIPO_MOV, ' +
    'm.CANTIDAD_MOV, m.PRECIO_COSTE_UNITARIO_MOV, ' +
    'm.TOTAL_COSTE_MOV, m.PRECIO_MEDIO_MOV, m.ESACTIVO_MOV ' +
    'FROM fza_movimientos_almacen m ' +
    'WHERE m.CODIGO_UNIDAD_MOV = :SKU ' +
    'ORDER BY m.FECHA_MOV DESC, m.NUMERO_MOV DESC';

type
  TConsultaMovimientosSkuUniDAC = class(
    TInterfacedObject,
    IConsultaMovimientosSku)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioMovimientosSkuUniDAC = class(
    TInterfacedObject,
    IRepositorioMovimientosSku)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarMovimientos(
      const ACodigoSku: string): IConsultaMovimientosSku;
    function ReconstruirStock: string;
  end;

constructor TConsultaMovimientosSkuUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaMovimientosSkuUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaMovimientosSkuUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioMovimientosSkuUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioMovimientosSkuUniDAC.ConsultarMovimientos(
  const ACodigoSku: string): IConsultaMovimientosSku;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_MOVIMIENTOS_SKU;
    Consulta.ParamByName('SKU').AsString := ACodigoSku;
    Consulta.Open;
    Result := TConsultaMovimientosSkuUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioMovimientosSkuUniDAC.ReconstruirStock: string;
var
  Consulta: TUniQuery;
begin
  Result := '';
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := 'CALL PRC_RECALCULAR_STOCK()';
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('MENSAJE').AsString;
    if (not FConexion.InTransaction) and
       (not StartsText('ERROR', Result)) then
      SolicitarProcesadoPrestaShop;
  finally
    FreeAndNil(Consulta);
  end;
end;

function CrearRepositorioMovimientosSkuUniDAC(
  AConexion: TUniConnection): IRepositorioMovimientosSku;
begin
  Result := TRepositorioMovimientosSkuUniDAC.Create(AConexion);
end;

end.
