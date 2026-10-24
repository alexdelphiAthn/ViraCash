{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataTraspasoOpeRepositorio                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Lecturas UniDAC auxiliares de la operativa de traspasos.                  }
{******************************************************************************}
unit UniDataTraspasoOpeRepositorio;

interface

uses
  Uni, inLibTraspasoOpePersistenciaIntf;

function CrearRepositorioTraspasoOpeUniDAC(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;

implementation

uses
  System.SysUtils,
  UniDataRectificativasSql;

const
  SQL_VENTAS_REPOSICION_FACLIN =
    'SELECT v.CODIGO_ARTICULO, v.SKU, ' +
    '       MAX(v.DESCRIPCION) AS DESCRIPCION, ' +
    '       v.CODIGO_PROVEEDOR, v.NOMBRE_PROVEEDOR, ' +
    '       SUM(v.CANTIDAD) AS A_PEDIR, ' +
    '       COALESCE(sd.STOCK, 0) AS STOCK_DESTINO, ' +
    '       COALESCE(so.STOCK, 0) AS STOCK_ORIGEN ' +
    '  FROM ( ' +
    'SELECT fl.CODIGO_ART_FACLIN AS CODIGO_ARTICULO, ' +
    '       fl.CODIGO_UNIDAD_FACLIN AS SKU, ' +
    '       COALESCE(NULLIF(TRIM( ' +
    '         fl.DESCRIPCION_ARTICULO_FACLIN), ''''), ' +
    '         a.DESCRIPCION_ART, '''') AS DESCRIPCION, ' +
    '       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''), ' +
    '         ap.CODIGO_PRV_AP, '''') AS CODIGO_PROVEEDOR, ' +
    '       COALESCE(NULLIF(TRIM( ' +
    '         fl.RAZON_SOCIAL_PROVEEDOR_FACLIN), ''''), ' +
    '         NULLIF(TRIM(p.RAZON_SOCIAL_PRV), ''''), ' +
    '         NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''), ' +
    '         ap.CODIGO_PRV_AP, '''') AS NOMBRE_PROVEEDOR, ' +
    '       fl.CANTIDAD_FACLIN AS CANTIDAD ' +
    '  FROM ( ' +
    'SELECT CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    '       CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA, ' +
    '       MAX(FECHA_OPERACION_OPCAJA) ' +
    '         AS FECHA_OPERACION_OPCAJA, ' +
    '       MAX(SERIE_FAC_OPCAJA) AS SERIE_FAC_OPCAJA, ' +
    '       MAX(NUMERO_FAC_OPCAJA) AS NUMERO_FAC_OPCAJA ' +
    '  FROM fza_caja_operaciones ' +
    ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND CODIGO_ALM_OPCAJA = :ALMACEN_DESTINO ' +
    '   AND TIPO_OPERACION_OPCAJA = ''VE'' ' +
    '   AND FECHA_OPERACION_OPCAJA >= :DESDE ' +
    '   AND FECHA_OPERACION_OPCAJA < :HASTA ' +
    ' GROUP BY CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    '          CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA ' +
    '       ) o ' +
    '  JOIN fza_facturas_lineas fl ' +
    '    ON ((fl.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    '     AND fl.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    '     AND fl.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    '     AND fl.NUMERO_OPERACION_FACLIN = ' +
    '         o.NUMERO_OPERACION_OPCAJA) ' +
    '     OR (fl.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    '     AND fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA ' +
    '     AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA)) ' +
    '  LEFT JOIN fza_articulos a ' +
    '    ON a.CODIGO_ART_ART = fl.CODIGO_ART_FACLIN ' +
    '  LEFT JOIN fza_articulos_proveedores ap ' +
    '    ON ap.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN ' +
    '   AND ap.CODIGO_PRV_AP = COALESCE( ' +
    '       NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''), ' +
    '       (SELECT apx.CODIGO_PRV_AP ' +
    '          FROM fza_articulos_proveedores apx ' +
    '         WHERE apx.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN ' +
    '         ORDER BY CASE ' +
    '           WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '           THEN 0 ELSE 1 END, ' +
    '           apx.FECHA_VALIDEZ_AP DESC, apx.CODIGO_PRV_AP ' +
    '         LIMIT 1)) ' +
    '  LEFT JOIN fza_proveedores p ' +
    '    ON p.CODIGO_PRV_PRV = COALESCE( ' +
    '       NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''), ' +
    '       ap.CODIGO_PRV_AP) ' +
    ' WHERE COALESCE(fl.CANTIDAD_FACLIN, 0) > 0 ' +
    '   AND fl.TIPO_ARTICULO_FACLIN = ''ESTANDAR'' ' +
    '   AND NULLIF(TRIM(fl.CODIGO_UNIDAD_FACLIN), '''') IS NOT NULL ';

  SQL_VENTAS_REPOSICION_MOVIMIENTOS =
    ' UNION ALL ' +
    'SELECT m.CODIGO_ART_MOV AS CODIGO_ARTICULO, ' +
    '       sk.CODIGO_UNIDAD_SKU AS SKU, ' +
    '       COALESCE(NULLIF(TRIM( ' +
    '         m.DESCRIPCION_ARTICULO_MOV), ''''), ' +
    '         a.DESCRIPCION_ART, '''') AS DESCRIPCION, ' +
    '       COALESCE(ap.CODIGO_PRV_AP, '''') ' +
    '         AS CODIGO_PROVEEDOR, ' +
    '       COALESCE(NULLIF(TRIM(p.RAZON_SOCIAL_PRV), ''''), ' +
    '         ap.CODIGO_PRV_AP, '''') AS NOMBRE_PROVEEDOR, ' +
    '       m.CANTIDAD_MOV AS CANTIDAD ' +
    '  FROM ( ' +
    'SELECT CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    '       CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA, ' +
    '       MAX(FECHA_OPERACION_OPCAJA) ' +
    '         AS FECHA_OPERACION_OPCAJA, ' +
    '       MAX(SERIE_FAC_OPCAJA) AS SERIE_FAC_OPCAJA, ' +
    '       MAX(NUMERO_FAC_OPCAJA) AS NUMERO_FAC_OPCAJA ' +
    '  FROM fza_caja_operaciones ' +
    ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND CODIGO_ALM_OPCAJA = :ALMACEN_DESTINO ' +
    '   AND TIPO_OPERACION_OPCAJA = ''VE'' ' +
    '   AND FECHA_OPERACION_OPCAJA >= :DESDE ' +
    '   AND FECHA_OPERACION_OPCAJA < :HASTA ' +
    ' GROUP BY CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, ' +
    '          CODIGO_CAJA_OPCAJA, NUMERO_OPERACION_OPCAJA ' +
    '       ) o ' +
    '  JOIN fza_movimientos_almacen m ' +
    '    ON m.CODIGO_EMP_MOV = o.CODIGO_EMP_OPCAJA ' +
    '   AND m.CODIGO_ALM_DOC_MOV = o.CODIGO_ALM_OPCAJA ' +
    '   AND m.CODIGO_CAJA_DOC_MOV = o.CODIGO_CAJA_OPCAJA ' +
    '   AND m.NUMERO_OPERACION_DOC_MOV = ' +
    '       o.NUMERO_OPERACION_OPCAJA ' +
    '  LEFT JOIN fza_articulos_skus se ' +
    '    ON se.CODIGO_UNIDAD_SKU = ' +
    '       NULLIF(TRIM(m.CODIGO_UNIDAD_MOV), '''') ' +
    '   AND se.CODIGO_ART_SKU = m.CODIGO_ART_MOV ' +
    '  LEFT JOIN fza_articulos_skus sk ' +
    '    ON sk.CODIGO_UNIDAD_SKU = COALESCE( ' +
    '       se.CODIGO_UNIDAD_SKU, ' +
    '       (SELECT MIN(sku.CODIGO_UNIDAD_SKU) ' +
    '          FROM fza_articulos_skus sku ' +
    '         WHERE sku.CODIGO_ART_SKU = m.CODIGO_ART_MOV ' +
    '           AND sku.ESACTIVO_SKU = ''S'' ' +
    '        HAVING COUNT(*) = 1)) ' +
    '   AND sk.CODIGO_ART_SKU = m.CODIGO_ART_MOV ' +
    '  LEFT JOIN fza_articulos a ' +
    '    ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV ' +
    '  LEFT JOIN fza_articulos_proveedores ap ' +
    '    ON ap.CODIGO_ART_AP = m.CODIGO_ART_MOV ' +
    '   AND ap.CODIGO_PRV_AP = ( ' +
    '       SELECT apx.CODIGO_PRV_AP ' +
    '         FROM fza_articulos_proveedores apx ' +
    '        WHERE apx.CODIGO_ART_AP = m.CODIGO_ART_MOV ' +
    '        ORDER BY CASE ' +
    '          WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '          THEN 0 ELSE 1 END, ' +
    '          apx.FECHA_VALIDEZ_AP DESC, apx.CODIGO_PRV_AP ' +
    '        LIMIT 1) ' +
    '  LEFT JOIN fza_proveedores p ' +
    '    ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    ' WHERE m.TIPO_DOC_MOV = ''VE'' ' +
    '   AND m.TIPO_MOV = ''S'' ' +
    '   AND m.ESACTIVO_MOV = ''S'' ' +
    '   AND NULLIF(TRIM(m.CODIGO_ART_MOV), '''') IS NOT NULL ' +
    '   AND COALESCE(m.CANTIDAD_MOV, 0) <> 0 ' +
    '   AND sk.CODIGO_UNIDAD_SKU IS NOT NULL ' +
    '   AND NOT EXISTS ( ' +
    '       SELECT 1 FROM fza_facturas_lineas fxo ' +
    '        WHERE fxo.CODIGO_EMP_FACLIN = ' +
    '                  o.CODIGO_EMP_OPCAJA ' +
    '          AND fxo.CODIGO_ALM_FACLIN = ' +
    '                  o.CODIGO_ALM_OPCAJA ' +
    '          AND fxo.CODIGO_CAJA_FACLIN = ' +
    '                  o.CODIGO_CAJA_OPCAJA ' +
    '          AND fxo.NUMERO_OPERACION_FACLIN = ' +
    '                  o.NUMERO_OPERACION_OPCAJA ' +
    '          AND COALESCE(fxo.CANTIDAD_FACLIN, 0) > 0 ' +
    '          AND fxo.TIPO_ARTICULO_FACLIN = ''ESTANDAR'' ' +
    '          AND NULLIF(TRIM( ' +
    '                fxo.CODIGO_UNIDAD_FACLIN), '''') IS NOT NULL) ' +
    '   AND NOT EXISTS ( ' +
    '       SELECT 1 FROM fza_facturas_lineas fxf ' +
    '        WHERE fxf.CODIGO_EMP_FACLIN = ' +
    '                  o.CODIGO_EMP_OPCAJA ' +
    '          AND fxf.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA ' +
    '          AND fxf.NUMERO_FAC_FACLIN = ' +
    '                  o.NUMERO_FAC_OPCAJA ' +
    '          AND COALESCE(fxf.CANTIDAD_FACLIN, 0) > 0 ' +
    '          AND fxf.TIPO_ARTICULO_FACLIN = ''ESTANDAR'' ' +
    '          AND NULLIF(TRIM( ' +
    '                fxf.CODIGO_UNIDAD_FACLIN), '''') IS NOT NULL) ';

  SQL_VENTAS_REPOSICION_FIN =
    '       ) v ' +
    '  LEFT JOIN ( ' +
    'SELECT CODIGO_UNIDAD_STK, SUM(CANTIDAD_STK) AS STOCK ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALMACEN_DESTINO ' +
    ' GROUP BY CODIGO_UNIDAD_STK ' +
    '       ) sd ON sd.CODIGO_UNIDAD_STK = v.SKU ' +
    '  LEFT JOIN ( ' +
    'SELECT CODIGO_UNIDAD_STK, SUM(CANTIDAD_STK) AS STOCK ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALMACEN_ORIGEN ' +
    ' GROUP BY CODIGO_UNIDAD_STK ' +
    '       ) so ON so.CODIGO_UNIDAD_STK = v.SKU ' +
    ' GROUP BY v.CODIGO_ARTICULO, v.SKU, ' +
    '          v.CODIGO_PROVEEDOR, v.NOMBRE_PROVEEDOR, ' +
    '          sd.STOCK, so.STOCK ' +
    ' ORDER BY CASE WHEN v.CODIGO_PROVEEDOR = '''' ' +
    '               THEN 1 ELSE 0 END, ' +
    '          v.CODIGO_PROVEEDOR, v.CODIGO_ARTICULO, ' +
    '          COALESCE(( ' +
    'SELECT MIN(COALESCE(aab.ORDEN_AAB, acd.ORDEN_ACD, ' +
    '                    av.ORDEN_AV)) ' +
    '  FROM fza_articulos_skus sk ' +
    '  JOIN fza_atributos_sku sa ' +
    '    ON sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
    '  JOIN fza_atributos_valores av ' +
    '    ON av.ID_AV = sa.ID_AV_SA ' +
    '   AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
    '  LEFT JOIN fza_articulos_atributos_basicos aab ' +
    '    ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU ' +
    '   AND aab.ID_AV_AAB = av.ID_AV ' +
    '  LEFT JOIN fza_articulos_conjuntos_asign aca ' +
    '    ON aca.CODIGO_ART_ACA = sk.CODIGO_ART_SKU ' +
    '   AND aca.ID_VA_ACA = av.ID_VA_AV ' +
    '  LEFT JOIN fza_atributos_conjuntos_det acd ' +
    '    ON acd.ID_AC_ACD = aca.ID_AC_ACA ' +
    '   AND acd.ID_AV_ACD = av.ID_AV ' +
    ' WHERE sk.CODIGO_UNIDAD_SKU = v.SKU ' +
    '   AND sk.CODIGO_ART_SKU = v.CODIGO_ARTICULO ' +
    '       ), 2147483647), v.SKU, v.NOMBRE_PROVEEDOR';

type
  TRepositorioTraspasoOpeUniDAC = class(
    TInterfacedObject,
    IRepositorioTraspasoOpe)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarAlmacenesDestino(
      const AAlmacenPropio: string): TAlmacenesDestinoTraspaso;
    function ListarVentasReposicion(
      const AFiltro: TFiltroVentasReposicion): TLineasVentaReposicion;
  end;

constructor TRepositorioTraspasoOpeUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioTraspasoOpeUniDAC.ListarVentasReposicion(
  const AFiltro: TFiltroVentasReposicion): TLineasVentaReposicion;
var
  iLinea: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  if AFiltro.Desde >= AFiltro.Hasta then
    raise EArgumentException.Create('AFiltro.Desde/AFiltro.Hasta');
  if SameText(AFiltro.AlmacenDestino, AFiltro.AlmacenOrigen) then
    raise EArgumentException.Create('AFiltro.AlmacenOrigen');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_VENTAS_REPOSICION_FACLIN +
      SQLExcluirVentaRetirada(
        'o.CODIGO_EMP_OPCAJA',
        'o.SERIE_FAC_OPCAJA',
        'o.NUMERO_FAC_OPCAJA') +
      SQL_VENTAS_REPOSICION_MOVIMIENTOS +
      SQLExcluirVentaRetirada(
        'o.CODIGO_EMP_OPCAJA',
        'o.SERIE_FAC_OPCAJA',
        'o.NUMERO_FAC_OPCAJA') +
      SQL_VENTAS_REPOSICION_FIN;
    oConsulta.ParamByName('EMPRESA').AsString := AFiltro.Empresa;
    oConsulta.ParamByName('ALMACEN_DESTINO').AsString :=
      AFiltro.AlmacenDestino;
    oConsulta.ParamByName('ALMACEN_ORIGEN').AsString :=
      AFiltro.AlmacenOrigen;
    oConsulta.ParamByName('DESDE').AsDateTime := AFiltro.Desde;
    oConsulta.ParamByName('HASTA').AsDateTime := AFiltro.Hasta;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      Result[iLinea].CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ARTICULO').AsString;
      Result[iLinea].Sku := oConsulta.FieldByName('SKU').AsString;
      Result[iLinea].Descripcion :=
        oConsulta.FieldByName('DESCRIPCION').AsString;
      Result[iLinea].CodigoProveedor :=
        oConsulta.FieldByName('CODIGO_PROVEEDOR').AsString;
      Result[iLinea].NombreProveedor :=
        oConsulta.FieldByName('NOMBRE_PROVEEDOR').AsString;
      Result[iLinea].APedir :=
        oConsulta.FieldByName('A_PEDIR').AsFloat;
      Result[iLinea].StockDestino :=
        oConsulta.FieldByName('STOCK_DESTINO').AsFloat;
      Result[iLinea].StockOrigen :=
        oConsulta.FieldByName('STOCK_ORIGEN').AsFloat;
      Inc(iLinea);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioTraspasoOpeUniDAC.ListarAlmacenesDestino(
  const AAlmacenPropio: string): TAlmacenesDestinoTraspaso;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''ESTANDAR'' ' +
      '   AND CODIGO_ALM_ALM <> :PROPIO ' +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.ParamByName('PROPIO').AsString := AAlmacenPropio;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioTraspasoOpeUniDAC(
  AConexion: TUniConnection): IRepositorioTraspasoOpe;
begin
  Result := TRepositorioTraspasoOpeUniDAC.Create(AConexion);
end;

end.
