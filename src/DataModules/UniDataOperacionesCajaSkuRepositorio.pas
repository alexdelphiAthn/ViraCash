{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataOperacionesCajaSkuRepositorio                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Lectura UniDAC de operaciones de caja asociadas a un SKU.                }
{******************************************************************************}
unit UniDataOperacionesCajaSkuRepositorio;

interface

uses
  Uni, inLibOperacionesCajaSkuPersistenciaIntf;

function CrearRepositorioOperacionesCajaSkuUniDAC(
  AConexion: TUniConnection): IRepositorioOperacionesCajaSku;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_OPERACIONES_SKU =
    'SELECT X.TIPO_OPERACION, X.NUMERO_OPERACION, X.FECHA_OPERACION, ' +
    'CASE WHEN TRIM(COALESCE(X.SERIE_FACTURA, '''')) = '''' ' +
    'OR TRIM(COALESCE(X.NUMERO_FACTURA, '''')) IN ('''', ''0'') ' +
    'THEN '''' ELSE CONCAT(X.SERIE_FACTURA, ''/'', X.NUMERO_FACTURA) ' +
    'END AS FACTURA, X.DESCRIPCION_ARTICULO, X.PRECIO_VENTA, ' +
    'X.DESCUENTO, X.CODIGO_EMP_OPCAJA, X.CODIGO_ALM_OPCAJA, ' +
    'X.CODIGO_CAJA_OPCAJA, X.SERIE_FACTURA, X.NUMERO_FACTURA ' +
    'FROM (SELECT O.TIPO_OPERACION_OPCAJA AS TIPO_OPERACION, ' +
    'O.NUMERO_OPERACION_OPCAJA AS NUMERO_OPERACION, ' +
    'O.FECHA_OPERACION_OPCAJA AS FECHA_OPERACION, ' +
    'O.SERIE_FAC_OPCAJA AS SERIE_FACTURA, ' +
    'O.NUMERO_FAC_OPCAJA AS NUMERO_FACTURA, O.CODIGO_EMP_OPCAJA, ' +
    'O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
    'COALESCE(NULLIF(L.DESCRIPCION_ARTICULO_FACLIN, ''''), ' +
    'A.DESCRIPCION_ART, '''') AS DESCRIPCION_ARTICULO, ' +
    'L.PRECIO_VENTA_CIVA_ARTICULO_FACLIN AS PRECIO_VENTA, ' +
    'NULLIF(L.PORCENTAJE_DTO_FACLIN, 0) AS DESCUENTO ' +
    'FROM (SELECT CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    'CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA, ' +
    'TIPO_OPERACION_OPCAJA, ' +
    'MAX(FECHA_OPERACION_OPCAJA) AS FECHA_OPERACION_OPCAJA, ' +
    'MAX(SERIE_FAC_OPCAJA) AS SERIE_FAC_OPCAJA, ' +
    'MAX(NUMERO_FAC_OPCAJA) AS NUMERO_FAC_OPCAJA ' +
    'FROM fza_caja_operaciones ' +
    'WHERE TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'') ' +
    'GROUP BY CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    'CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA, ' +
    'TIPO_OPERACION_OPCAJA) O ' +
    'JOIN fza_facturas_lineas L ON ' +
    '((L.CODIGO_EMP_FACLIN = O.CODIGO_EMP_OPCAJA ' +
    'AND L.CODIGO_ALM_FACLIN = O.CODIGO_ALM_OPCAJA ' +
    'AND L.CODIGO_CAJA_FACLIN = O.CODIGO_CAJA_OPCAJA ' +
    'AND L.NUMERO_OPERACION_FACLIN = O.NUMERO_OPERACION_OPCAJA) ' +
    'OR (L.SERIE_FAC_FACLIN = O.SERIE_FAC_OPCAJA ' +
    'AND L.NUMERO_FAC_FACLIN = O.NUMERO_FAC_OPCAJA)) ' +
    'LEFT JOIN fza_articulos A ' +
    'ON A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    'WHERE L.CODIGO_UNIDAD_FACLIN = :SKU ' +
    'AND ((O.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    'AND COALESCE(L.CANTIDAD_FACLIN, 0) > 0) ' +
    'OR (O.TIPO_OPERACION_OPCAJA = ''DV'' ' +
    'AND COALESCE(L.CANTIDAD_FACLIN, 0) < 0)) ' +
    'UNION ALL ' +
    'SELECT O.TIPO_OPERACION_OPCAJA AS TIPO_OPERACION, ' +
    'O.NUMERO_OPERACION_OPCAJA AS NUMERO_OPERACION, ' +
    'O.FECHA_OPERACION_OPCAJA AS FECHA_OPERACION, ' +
    'O.SERIE_FAC_OPCAJA AS SERIE_FACTURA, ' +
    'O.NUMERO_FAC_OPCAJA AS NUMERO_FACTURA, O.CODIGO_EMP_OPCAJA, ' +
    'O.CODIGO_ALM_OPCAJA, O.CODIGO_CAJA_OPCAJA, ' +
    'COALESCE(NULLIF(A.DESCRIPCION_ART, ''''), ' +
    'O.CONCEPTO_GASTO_INGRESO_OPCAJA, '''') AS DESCRIPCION_ARTICULO, ' +
    'D.PRECIO_VENTA_DEP AS PRECIO_VENTA, ' +
    'CAST(NULL AS DECIMAL(19, 6)) AS DESCUENTO ' +
    'FROM fza_caja_operaciones O ' +
    'JOIN fza_depositos_cliente D ' +
    'ON D.ID_DEPOSITO_DEP = O.ID_DEPOSITO_OPCAJA ' +
    'LEFT JOIN fza_articulos A ' +
    'ON A.CODIGO_ART_ART = D.CODIGO_ART_DEP ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''DE'' ' +
    'AND D.CODIGO_UNIDAD_DEP = :SKU) X ' +
    'ORDER BY X.FECHA_OPERACION DESC, ' +
    'CAST(X.NUMERO_OPERACION AS UNSIGNED) DESC, X.TIPO_OPERACION';

type
  TConsultaOperacionesCajaSkuUniDAC = class(
    TInterfacedObject,
    IConsultaOperacionesCajaSku)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioOperacionesCajaSkuUniDAC = class(
    TInterfacedObject,
    IRepositorioOperacionesCajaSku)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarOperaciones(
      const ACodigoSku: string): IConsultaOperacionesCajaSku;
  end;

constructor TConsultaOperacionesCajaSkuUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaOperacionesCajaSkuUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaOperacionesCajaSkuUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioOperacionesCajaSkuUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioOperacionesCajaSkuUniDAC.ConsultarOperaciones(
  const ACodigoSku: string): IConsultaOperacionesCajaSku;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := SQL_OPERACIONES_SKU;
    Consulta.ParamByName('SKU').AsString := ACodigoSku;
    Consulta.Open;
    Result := TConsultaOperacionesCajaSkuUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function CrearRepositorioOperacionesCajaSkuUniDAC(
  AConexion: TUniConnection): IRepositorioOperacionesCajaSku;
begin
  Result := TRepositorioOperacionesCajaSkuUniDAC.Create(AConexion);
end;

end.
