{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataInventariosBusquedas                                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de las busquedas visuales de articulo y SKU del       }
{    mantenimiento de inventarios y del marcado del recuento remoto.           }
{******************************************************************************}
unit UniDataInventariosBusquedas;

interface

uses
  Uni,
  inLibInventariosAplicacionIntf;

function CrearBusquedasInventarioUniDAC(
  AConexion: TUniConnection): IBusquedasInventario;
function CrearRepositorioRecuentoRemotoInventarioUniDAC(
  AConexion: TUniConnection): IRepositorioRecuentoRemotoInventario;

implementation

uses
  System.SysUtils,
  Data.DB;

const
  SQL_BUSQUEDA_ARTICULOS_INVENTARIO =
    'SELECT'                                              + sLineBreak +
    '    v.CODIGO_ART_ART,'                               + sLineBreak +
    '    v.DESCRIPCION_ART,'                              + sLineBreak +
    '    v.DESCRIPCION_FAM,'                              + sLineBreak +
    '    pv.PV                       AS TEMPORADA,'       + sLineBreak +
    '    v.RAZON_SOCIAL_PROVEEDOR,'                       + sLineBreak +
    '    v.REF_PROVEEDOR,'                                + sLineBreak +
    '    v.PRECIO_ULT_COMPRA,'                            + sLineBreak +
    '    v.PRECIO_FINAL_ARTTAR,'                          + sLineBreak +
    '    v.TIPO_CANTIDAD_ART'                             + sLineBreak +
    'FROM vi_art_busquedas v'                             + sLineBreak +
    'LEFT JOIN fza_articulos_propiedades ap'              + sLineBreak +
    '       ON ap.CODIGO_ART_ART = v.CODIGO_ART_ART'      + sLineBreak +
    '      AND ap.CODIGO_PROP_ARTPROP = ''TEMPORADA'''    + sLineBreak +
    // Nivel articulo: evita duplicar el articulo por temporadas de color
    '      AND ap.CODIGO_UNIDAD_ARTPROP = '''''           + sLineBreak +
    'LEFT JOIN fza_propiedades_valores pv'                + sLineBreak +
    '       ON pv.ID_PV_ARTPROP = ap.ID_PV_ARTPROP'       + sLineBreak +
    'ORDER BY v.CODIGO_ART_ART';
  SQL_BUSQUEDA_SKUS_INVENTARIO =
    'SELECT SK.CODIGO_UNIDAD_SKU,'                         + sLineBreak +
    '       SK.CODIGO_ART_SKU,'                            + sLineBreak +
    '       A.DESCRIPCION_ART,'                            + sLineBreak +
    '       GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
    '                    AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS,' +
                                                             sLineBreak +
    '       IFNULL(STK.CANTIDAD_STK, 0) AS CANTIDAD_STK,'  + sLineBreak +
    '       IFNULL(STK.PRECIO_MEDIO_STK, 0) AS PRECIO_MEDIO_STK ' +
                                                             sLineBreak +
    '  FROM fza_articulos_skus SK'                         + sLineBreak +
    '  JOIN fza_articulos A'                               + sLineBreak +
    '    ON A.CODIGO_ART_ART = SK.CODIGO_ART_SKU'          + sLineBreak +
    '  LEFT JOIN ('                                        + sLineBreak +
    '       SELECT CODIGO_UNIDAD_STK,'                     + sLineBreak +
    '              SUM(CANTIDAD_STK) AS CANTIDAD_STK,'     + sLineBreak +
    '              CASE WHEN SUM(CANTIDAD_STK) <> 0'       + sLineBreak +
    '                   THEN SUM(VALOR_TOTAL_STK) / SUM(CANTIDAD_STK)' +
                                                             sLineBreak +
    '                   ELSE MAX(PRECIO_MEDIO_STK)'        + sLineBreak +
    '              END AS PRECIO_MEDIO_STK'                + sLineBreak +
    '         FROM fza_articulos_stockactual'              + sLineBreak +
    '        WHERE CODIGO_ALM_STK = :ALMACEN'              + sLineBreak +
    '        GROUP BY CODIGO_UNIDAD_STK'                   + sLineBreak +
    '       ) STK'                                         + sLineBreak +
    '    ON STK.CODIGO_UNIDAD_STK = SK.CODIGO_UNIDAD_SKU'  + sLineBreak +
    '  LEFT JOIN fza_atributos_sku SA'                     + sLineBreak +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU' + sLineBreak +
    '  LEFT JOIN fza_atributos_valores AV'                 + sLineBreak +
    '    ON AV.ID_AV = SA.ID_AV_SA'                        + sLineBreak +
    '  LEFT JOIN fza_variaciones_atributos VA'             + sLineBreak +
    '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU'              + sLineBreak +
    '   AND VA.ID_ATB_VA = AV.ID_VA_AV'                    + sLineBreak +
    ' WHERE COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'''      + sLineBreak +
    '   AND A.TIPO_ART = ''ESTANDAR'''                     + sLineBreak +
    ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU,'   + sLineBreak +
    '          A.DESCRIPCION_ART, STK.CANTIDAD_STK,'       + sLineBreak +
    '          STK.PRECIO_MEDIO_STK'                       + sLineBreak +
    ' ORDER BY SK.CODIGO_UNIDAD_SKU';
  SQL_MARCAR_ENVIO_RECUENTO =
    ' UPDATE fza_inventarios SET ESRECUENTO_REMOTO_INV = ''S'',' +
    '   INSTANTE_ENVIO_RECUENTO_INV = NOW(),' +
    '   ID_RECUENTO_REMOTO_INV = :ID' +
    ' WHERE CODIGO_EMP_INV = :E AND CODIGO_ALM_INV = :A' +
    '   AND SERIE_INV = :S AND NUMERO_INV = :N';
  SQL_MARCAR_RECOGIDA_RECUENTO =
    ' UPDATE fza_inventarios SET INSTANTE_RECOGIDA_RECUENTO_INV = NOW()' +
    ' WHERE CODIGO_EMP_INV = :E AND CODIGO_ALM_INV = :A' +
    '   AND SERIE_INV = :S AND NUMERO_INV = :N';

type
  TResultadoConsultaInventarioUniDAC = class(
    TInterfacedObject,
    IResultadoConsultaInventario)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TBusquedasInventarioUniDAC = class(
    TInterfacedObject,
    IBusquedasInventario)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarArticulos: IResultadoConsultaInventario;
    function ConsultarSkus(
      const ACodigoAlmacen: string): IResultadoConsultaInventario;
  end;

  TRecuentoRemotoInventarioUniDAC = class(
    TInterfacedObject,
    IRepositorioRecuentoRemotoInventario)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure MarcarEnviado(
      const AClave: TClaveInventario; AIdRecuento: Int64);
    procedure MarcarRecogido(const AClave: TClaveInventario);
  end;

constructor TResultadoConsultaInventarioUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoConsultaInventarioUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoConsultaInventarioUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TBusquedasInventarioUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TBusquedasInventarioUniDAC.ConsultarArticulos:
  IResultadoConsultaInventario;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSQUEDA_ARTICULOS_INVENTARIO;
    oConsulta.Open;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
  Result := TResultadoConsultaInventarioUniDAC.Create(oConsulta);
end;

function TBusquedasInventarioUniDAC.ConsultarSkus(
  const ACodigoAlmacen: string): IResultadoConsultaInventario;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_BUSQUEDA_SKUS_INVENTARIO;
    oConsulta.ParamByName('ALMACEN').AsString := ACodigoAlmacen;
    oConsulta.Open;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
  Result := TResultadoConsultaInventarioUniDAC.Create(oConsulta);
end;

constructor TRecuentoRemotoInventarioUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRecuentoRemotoInventarioUniDAC.MarcarEnviado(
  const AClave: TClaveInventario; AIdRecuento: Int64);
begin
  FConexion.ExecSQL(
    SQL_MARCAR_ENVIO_RECUENTO,
    [IntToStr(AIdRecuento), AClave.Empresa, AClave.Almacen,
     AClave.Serie, AClave.Numero]);
end;

procedure TRecuentoRemotoInventarioUniDAC.MarcarRecogido(
  const AClave: TClaveInventario);
begin
  FConexion.ExecSQL(
    SQL_MARCAR_RECOGIDA_RECUENTO,
    [AClave.Empresa, AClave.Almacen, AClave.Serie, AClave.Numero]);
end;

function CrearBusquedasInventarioUniDAC(
  AConexion: TUniConnection): IBusquedasInventario;
begin
  Result := TBusquedasInventarioUniDAC.Create(AConexion);
end;

function CrearRepositorioRecuentoRemotoInventarioUniDAC(
  AConexion: TUniConnection): IRepositorioRecuentoRemotoInventario;
begin
  Result := TRecuentoRemotoInventarioUniDAC.Create(AConexion);
end;

end.
