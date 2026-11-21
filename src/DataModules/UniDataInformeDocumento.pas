{******************************************************************************}
{                                                                              }
{                       Módulo: UniDataInformeDocumento                        }
{                                Versión: 1.2.0                                }
{                              Fecha: 01/10/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit UniDataInformeDocumento;

interface

uses
  inLibMsgPresupuestos,
  System.Classes, Uni, frxDBSet, inLibDocumentoIntf;

type
  TDatosInformeDocumento = class(TComponent)
  private
    FCabecera: TUniQuery;
    FLineas: TUniQuery;
    FLineasHorizontales: TUniQuery;
    FImpuestos: TUniQuery;
    FDatosCabecera: TfrxDBDataset;
    FDatosLineas: TfrxDBDataset;
    FDatosLineasHorizontales: TfrxDBDataset;
    FDatosImpuestos: TfrxDBDataset;
    procedure ConfigurarCabecera(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarLineas(const AConfig: TConfiguracionDocumento);
    procedure ConfigurarImpuestos(const AConfig: TConfiguracionDocumento);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Abrir(AConexion: TUniConnection;
      const AConfig: TConfiguracionDocumento;
      const ASerie, ANumero: string; AHorizontal: Boolean = False);
    property Cabecera: TfrxDBDataset read FDatosCabecera;
    property Lineas: TfrxDBDataset read FDatosLineas;
    property LineasHorizontales: TfrxDBDataset read FDatosLineasHorizontales;
    // Desglose por tipo de IVA: solo los tipos con base o cuota.
    property Impuestos: TfrxDBDataset read FDatosImpuestos;
  end;

function SqlImpresionHorizontalCompra(const AConfig: TConfiguracionDocumento;
  AGuias: Boolean): string;
function SqlImpresionHorizontalSesion(AGuias: Boolean): string;

implementation

uses
  System.SysUtils, Data.DB, UniDataPropiedadesLineasDocumento,
  inLibPivoteVentaCalculo;

const
  SALTO_SQL = 'CHAR(13,10)';

constructor TDatosInformeDocumento.Create(AOwner: TComponent);
begin
  inherited;
  FCabecera := TUniQuery.Create(Self);
  FCabecera.ReadOnly := True;
  FLineas := TUniQuery.Create(Self);
  FLineas.ReadOnly := True;
  FLineasHorizontales := TUniQuery.Create(Self);
  FLineasHorizontales.ReadOnly := True;
  FImpuestos := TUniQuery.Create(Self);
  FImpuestos.ReadOnly := True;
  FDatosCabecera := TfrxDBDataset.Create(Self);
  FDatosCabecera.UserName := 'Cabecera';
  FDatosCabecera.DataSet := FCabecera;
  FDatosLineas := TfrxDBDataset.Create(Self);
  FDatosLineas.UserName := 'Lineas';
  FDatosLineas.DataSet := FLineas;
  FDatosLineasHorizontales := TfrxDBDataset.Create(Self);
  FDatosLineasHorizontales.UserName := 'LineasHorizontales';
  FDatosLineasHorizontales.DataSet := FLineasHorizontales;
  FDatosImpuestos := TfrxDBDataset.Create(Self);
  FDatosImpuestos.UserName := 'Impuestos';
  FDatosImpuestos.DataSet := FImpuestos;
end;

// Texto vacio como NULL, para que CONCAT_WS se salte el dato.
function SinVacio(const AExpresion: string): string;
begin
  Result := 'NULLIF(TRIM(' + AExpresion + '), '''')';
end;

// Bloque de direccion en varias lineas (sin huecos por datos vacios):
// direccion, CP y poblacion, provincia y pais, contacto y NIF.
function BloqueDireccion(const ASujeto, ANif, ASufijo: string): string;
  function Campo(const ANombre: string): string;
  begin
    Result := ANombre + '_' + ASujeto + ASufijo;
  end;
begin
  Result := 'COALESCE(CONCAT_WS(' + SALTO_SQL + ', ' +
    SinVacio('CONCAT_WS('' '', ' + Campo('DIRECCION1') + ', ' +
      Campo('DIRECCION2') + ')') + ', ' +
    SinVacio('CONCAT_WS('' '', ' + Campo('CODIGO_POSTAL') + ', ' +
      Campo('POBLACION') + ')') + ', ' +
    SinVacio('CONCAT_WS('' - '', ' + SinVacio(Campo('PROVINCIA')) +
      ', ' + SinVacio(Campo('NOMBRE_PAI')) + ')') + ', ' +
    SinVacio('CONCAT_WS('' · '', ' + SinVacio(Campo('MOVIL')) + ', ' +
      SinVacio(Campo('EMAIL')) + ')') + ', ' +
    'CONCAT(' + QuotedStr(SInformeNifDocumento) + ', ' +
      SinVacio('NIF_' + ANif + ASufijo) + ')), '''')';
end;

function SumaImpuesto(const APrefijo, ASufijo: string): string;
const
  TIPOS = 'NRSE';
var
  iTipo: Integer;
begin
  Result := '';
  for iTipo := 1 to Length(TIPOS) do
  begin
    if Result <> '' then
      Result := Result + ' + ';
    Result := Result + 'COALESCE(' + APrefijo + TIPOS[iTipo] +
      ASufijo + ', 0)';
  end;
end;

function HayRecargo(const ASufijo: string): string;
const
  TIPOS = 'NRSE';
var
  iTipo: Integer;
begin
  Result := '';
  for iTipo := 1 to Length(TIPOS) do
  begin
    if Result <> '' then
      Result := Result + ' OR ';
    Result := Result + 'COALESCE(TOTAL_RE' + TIPOS[iTipo] +
      ASufijo + ', 0) <> 0';
  end;
end;

procedure TDatosInformeDocumento.ConfigurarCabecera(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sTercero, sNif, sValidez, sFormaPago, sNotas: string;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sTercero := 'CLIENTE';
  if AConfig.Sentido = sdCompra then
    sTercero := 'PRV';
  sNif := sTercero;
  if (AConfig.TipoDocumento = tdPedido) and
     (AConfig.Sentido = sdVenta) then
    sTercero := 'CLIENTE_FISCAL';
  // Solo el presupuesto tiene fecha de validez.
  sValidez := '''''';
  if AConfig.TipoDocumento = tdPresupuesto then
    sValidez := 'COALESCE(CONCAT(' + QuotedStr(SInformeValidezDocumento) +
      ', DATE_FORMAT(FECHA_VALIDEZ' + sSufijo + ', ''%d/%m/%Y'')), '''')';
  sFormaPago := 'COALESCE((SELECT FP.DESCRIPCION_FORMA_PAGO_FP ' +
    'FROM fza_formas_pago FP WHERE FP.CODIGO_FP_FP = FORMA_PAGO' +
    sSufijo + '), FORMA_PAGO' + sSufijo + ', '''')';
  sNotas := 'COALESCE(CONCAT_WS(' + SALTO_SQL + ', ' +
    SinVacio('COMENTARIOS' + sSufijo) + ', ' +
    SinVacio('OBSERVACIONES' + sSufijo) + '), '''')';
  // Los alias anteriores se conservan: los formatos personalizados que
  // el usuario haya guardado siguen encontrando sus campos.
  FCabecera.SQL.Text :=
    'SELECT SERIE' + sSufijo + ' AS SERIE, NUMERO' + sSufijo +
    ' AS NUMERO, FECHA' + sSufijo + ' AS FECHA, ' +
    'RAZON_SOCIAL_EMPRESA' + sSufijo + ' AS EMPRESA, ' +
    'NIF_EMPRESA' + sSufijo + ' AS NIF_EMPRESA, ' +
    'DIRECCION1_EMPRESA' + sSufijo + ' AS DIRECCION_EMPRESA, ' +
    'POBLACION_EMPRESA' + sSufijo + ' AS POBLACION_EMPRESA, ' +
    BloqueDireccion('EMPRESA', 'EMPRESA', sSufijo) +
    ' AS BLOQUE_EMPRESA, ' +
    'RAZON_SOCIAL_' + sTercero + sSufijo + ' AS TERCERO, ' +
    'NIF_' + sNif + sSufijo + ' AS NIF_TERCERO, ' +
    'DIRECCION1_' + sTercero + sSufijo + ' AS DIRECCION_TERCERO, ' +
    'POBLACION_' + sTercero + sSufijo + ' AS POBLACION_TERCERO, ' +
    BloqueDireccion(sTercero, sNif, sSufijo) + ' AS BLOQUE_TERCERO, ' +
    'TOTAL_BASES' + sSufijo + ' AS BASES, TOTAL_IMPUESTOS' + sSufijo +
    ' AS IMPUESTOS, ' +
    SumaImpuesto('TOTAL_IVA', sSufijo) + ' AS TOTAL_IVA, ' +
    SumaImpuesto('TOTAL_RE', sSufijo) + ' AS RECARGO, (' +
    HayRecargo(sSufijo) + ') AS TIENE_RECARGO, ' +
    'TOTAL_RETENCION' + sSufijo + ' AS RETENCION, ' +
    'COALESCE(PORCENTAJE_RETENCION' + sSufijo +
    ', 0) AS PORCENTAJE_RETENCION, ' +
    'TOTAL_LIQUIDO' + sSufijo + ' AS TOTAL, COMENTARIOS' + sSufijo +
    ' AS COMENTARIOS, OBSERVACIONES' + sSufijo + ' AS OBSERVACIONES, ' +
    sNotas + ' AS NOTAS, ' +
    'FORMA_PAGO' + sSufijo + ' AS FORMA_PAGO, ' +
    sFormaPago + ' AS FORMA_PAGO_DESCRIPCION, ' +
    sValidez + ' AS VALIDEZ FROM ' +
    AConfig.TablaCabecera + ' WHERE SERIE' + sSufijo + ' = :SERIE ' +
    'AND NUMERO' + sSufijo + ' = :NUMERO';
end;

function PrecioLinea(const AConfig: TConfiguracionDocumento): string;
begin
  Result := 'PRECIO_VENTA_SIVA_ARTICULO';
  if AConfig.Sentido = sdCompra then
    Result := 'PRECIO_COMPRA_SIVA_ARTICULO';
  Result := Result + '_' + AConfig.PrefijoLineas;
end;

function SqlLineasImpresionCompra(
  const AConfig: TConfiguracionDocumento): string;
var
  Sufijo, Sku, Cantidad, Precio, Total, RefProveedor, Color, Lote,
    Caducidad, NumeroTalla: string;
begin
  Sufijo := '_' + AConfig.PrefijoLineas;
  Sku := 'L.CODIGO_UNIDAD' + Sufijo;
  Cantidad := 'COALESCE(L.CANTIDAD' + Sufijo + ', 0)';
  Precio := 'COALESCE(L.' + PrecioLinea(AConfig) + ', 0)';
  Total := 'COALESCE(L.TOTAL' + Sufijo + ', 0)';
  RefProveedor := 'COALESCE(NULLIF(TRIM(L.REF_PRV' + Sufijo +
    '), ''''), '''')';
  Color := 'COALESCE(VC.NOMBRE_ATB, NULLIF(VC.VALOR_AV, ''''), '''')';
  Lote := 'L.LOTE' + Sufijo;
  Caducidad := 'L.FECHA_CADUCIDAD' + Sufijo;
  if AConfig.TipoDocumento = tdPedido then
  begin
    Total := 'ROUND(' + Cantidad + ' * ' + Precio + ', 2)';
    RefProveedor := 'COALESCE(NULLIF(TRIM(L.REF_PRV_PEDCLIN), ''''), ' +
      '(SELECT NULLIF(TRIM(AP.REF_PROVEEDOR_AP), '''') ' +
      'FROM fza_articulos_proveedores AP JOIN fza_pedidos_compra PC ' +
      'ON PC.CODIGO_PRV_PEDC = AP.CODIGO_PRV_AP ' +
      'WHERE AP.CODIGO_ART_AP = L.CODIGO_ART_PEDCLIN ' +
      'AND PC.SERIE_PEDC = :SERIE AND PC.NUMERO_PEDC = :NUMERO ' +
      'LIMIT 1), '''')';
    Color := 'COALESCE(NULLIF(TRIM(L.COLOR_TEXTO_PEDCLIN), ''''), ' +
      'NULLIF(VC.NOMBRE_ATB, ''''), VC.VALOR_AV, '''')';
    Caducidad := 'L.CADUCIDAD_PEDCLIN';
  end;
  NumeroTalla := 'SUBSTRING_INDEX(' + Sku + ', ''/'', -1)';
  Result :=
    'SELECT L.' + AConfig.CampoSerieLinea + ' AS SERIE_DOC, ' +
    'L.' + AConfig.CampoNumeroLinea + ' AS NUMERO_DOC, ' +
    'L.LINEA' + Sufijo + ' AS LINEA, COALESCE(L.CODIGO_ART' + Sufijo +
    ', '''') AS CODIGO_ART, ' + Sku + ' AS SKU, ' +
    NumeroTalla + ' AS SUFIJO, ' +
    RefProveedor + ' AS REF_PRV, COALESCE(L.DESCRIPCION_ARTICULO' + Sufijo +
    ', L.CODIGO_ART' + Sufijo + ', '''') AS DESCRIPCION_BASE, ' +
    'L.DESCRIPCION_VARIACION' + Sufijo + ' AS VARIACION_TEXTO, ' +
    Color + ' AS COLOR_TEXTO, ' +
    'COALESCE(VC.CODIGO_ATB, '''') AS CODIGO_ATB_COLOR, ' +
    'COALESCE(L.TIPO_CANTIDAD_ARTICULO' + Sufijo +
    ', '''') AS TIPO_CANTIDAD, ' + Cantidad + ' AS CANTIDAD, ' +
    Precio + ' AS PRECIO_COMPRA, ' + Total + ' AS IMPORTE, ' +
    'L.PORCENTAJE_DTO' + Sufijo + ' AS DESCUENTO, ' +
    'L.PORCENTAJE_IVA' + Sufijo + ' AS IVA, ' +
    'L.CODIGO_ALMACEN' + Sufijo + ' AS CODIGO_ALM_ALBCLIN, ' +
    'COALESCE(' + Lote + ', '''') AS LOTE, ' + Caducidad +
    ' AS FECHA_CADUCIDAD, NULLIF(L.' + AConfig.CampoPivoteLinea +
    ', 0) AS ID_AC_PIVOT, ' +
    'COALESCE(V.AV, CASE WHEN EP.ID_ATB_VA IS NULL ' +
    'AND SK.CODIGO_UNIDAD_SKU IS NULL AND ' + Sku +
    ' REGEXP ''/[0-9]+([.,][0-9]+)?$'' THEN ' + NumeroTalla +
    ' END) AS TALLA_SKU, V.ORDEN_AV AS ORDEN_SKU ' +
    'FROM ' + AConfig.TablaLineas + ' L ' +
    'LEFT JOIN fza_articulos_skus SK ON SK.CODIGO_UNIDAD_SKU = ' + Sku +
    ' LEFT JOIN vi_variaciones_ejes EP ' +
    'ON EP.ID_VAR_VA = SK.CODIGO_VAR_SKU AND EP.EJE_VA = ''P'' ' +
    'LEFT JOIN fza_atributos_valores V ON V.ID_AV = (' +
    'SELECT SA.ID_AV_SA FROM fza_atributos_sku SA ' +
    'JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    'WHERE SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    'AND AV.ID_VA_AV = EP.ID_ATB_VA ORDER BY SA.ID_AV_SA LIMIT 1) ' +
    'LEFT JOIN vi_variaciones_ejes EF ' +
    'ON EF.ID_VAR_VA = SK.CODIGO_VAR_SKU AND EF.EJE_VA = ''F'' ' +
    'LEFT JOIN vi_atributos_sku_basico VC ' +
    'ON VC.CODIGO_UNIDAD_SKU = ' + Sku + ' AND VC.ID_VA_AV = EF.ID_ATB_VA ' +
    'WHERE L.' + AConfig.CampoSerieLinea + ' = :SERIE AND L.' +
    AConfig.CampoNumeroLinea + ' = :NUMERO';
end;

function CteTramosImpresion(out ACamposGuia, ARotulosLinea,
  ACantidades: string): string;
var
  Ancho, Campo, RotulosGuia: string;
  I: Integer;
begin
  Ancho := IntToStr(MAX_TALLAS_HORIZONTAL);
  ACamposGuia := '';
  ARotulosLinea := '';
  ACantidades := '';
  RotulosGuia := '';
  Result := ', SISTEMAS AS (' +
    'SELECT L.SISTEMA, MAX(L.ID_AC_PIVOT) AS ID_AC, ' +
    'MIN(L.CODIGO_ART) AS CODIGO_ART FROM LINEAS L GROUP BY L.SISTEMA' +
    '), TALLAS AS (' +
    'SELECT S.SISTEMA, V.AV AS TALLA, 0 AS BLOQUE, ACD.ORDEN_ACD AS ORDEN, ' +
    'ACD.ID_AV_ACD AS ID_AV FROM SISTEMAS S ' +
    'JOIN fza_atributos_conjuntos_det ACD ON ACD.ID_AC_ACD = S.ID_AC ' +
    'JOIN fza_atributos_valores V ON V.ID_AV = ACD.ID_AV_ACD UNION ALL ' +
    'SELECT D.SISTEMA, D.TALLA, 1, COALESCE(D.ORDEN, 2147483647), 0 ' +
    'FROM DETALLE D WHERE NULLIF(TRIM(D.TALLA), '''') IS NOT NULL' +
    '), POSICIONES AS (' +
    'SELECT SISTEMA, TALLA, ROW_NUMBER() OVER (PARTITION BY SISTEMA ' +
    'ORDER BY MIN(BLOQUE), COALESCE(MIN(CASE WHEN BLOQUE = 0 THEN ORDEN ' +
    'END), MIN(ORDEN)), MAX(ID_AV), CASE WHEN TALLA REGEXP ' +
    '''^[0-9]+([.,][0-9]+)?$'' THEN ' +
    'CAST(REPLACE(TALLA, '','', ''.'') AS DECIMAL(19,6)) END, TALLA) - 1 ' +
    'AS POSICION FROM TALLAS GROUP BY SISTEMA, TALLA' +
    '), TRAMOS AS (' +
    'SELECT SISTEMA, TALLA, POSICION DIV ' + Ancho + ' AS TRAMO, ' +
    'MOD(POSICION, ' + Ancho + ') + 1 AS COLUMNA ' +
    'FROM POSICIONES' +
    '), ROTULOS AS (' +
    'SELECT S.SISTEMA, S.ID_AC, ' +
    'COALESCE(AC.NOMBRE_AC, S.CODIGO_ART, '''') AS NOMBRE_AC, ' +
    'COALESCE(NULLIF(AC.NOMBRE_CORTO_AC, ''''), ' +
    'UPPER(LEFT(AC.NOMBRE_AC, 8)), ' +
    'CONCAT(''T'', ROW_NUMBER() OVER (ORDER BY S.SISTEMA))) AS CORTO ' +
    'FROM SISTEMAS S LEFT JOIN fza_atributos_conjuntos AC ' +
    'ON AC.ID_AC = S.ID_AC' +
    '), GUIAS_BASE AS (' +
    'SELECT R.ID_AC, T.SISTEMA, T.TRAMO, R.NOMBRE_AC, ' +
    'CASE WHEN COUNT(*) OVER (PARTITION BY T.SISTEMA) > 1 THEN ' +
    'CONCAT(LEFT(R.CORTO, 5), ''-'', T.TRAMO + 1) ' +
    'ELSE R.CORTO END AS CODIGO_GUIA';
  for I := 1 to MAX_TALLAS_HORIZONTAL do
  begin
    Campo := Format('T%.2d', [I]);
    RotulosGuia := RotulosGuia + ', MAX(CASE WHEN T.COLUMNA = ' +
      IntToStr(I) + ' THEN T.TALLA END) AS ' + Campo;
    ACamposGuia := ACamposGuia + ', G.' + Campo;
    ARotulosLinea := ARotulosLinea + ', MAX(G.' + Campo +
      ') AS ' + Format('R%.2d', [I]);
    ACantidades := ACantidades + ', SUM(CASE WHEN T.COLUMNA = ' +
      IntToStr(I) + ' THEN D.CANTIDAD ELSE 0 END) AS ' + Campo;
  end;
  Result := Result + RotulosGuia +
    ' FROM TRAMOS T JOIN ROTULOS R ON R.SISTEMA = T.SISTEMA ' +
    'GROUP BY R.ID_AC, T.SISTEMA, T.TRAMO, R.NOMBRE_AC, R.CORTO' +
    '), GUIAS AS (' +
    'SELECT G.ID_AC, G.SISTEMA, G.TRAMO, G.NOMBRE_AC, ' +
    'CASE WHEN COUNT(*) OVER (PARTITION BY G.CODIGO_GUIA) > 1 ' +
    'OR LEFT(G.CODIGO_GUIA, 1) = ''#'' THEN ' +
    'CONCAT(''#'', ROW_NUMBER() OVER (ORDER BY G.SISTEMA, G.TRAMO)) ' +
    'ELSE G.CODIGO_GUIA END AS NOMBRE_CORTO_AC' + ACamposGuia +
    ' FROM GUIAS_BASE G) ';
end;

function SelectGuiasImpresion(const ACamposGuia: string): string;
begin
  Result := 'SELECT G.ID_AC, G.NOMBRE_AC, G.NOMBRE_CORTO_AC, G.TRAMO' +
    ACamposGuia + ' FROM GUIAS G ORDER BY G.NOMBRE_AC, G.SISTEMA, G.TRAMO';
end;

function SqlImpresionHorizontalCompra(const AConfig: TConfiguracionDocumento;
  AGuias: Boolean): string;
var
  Cel, Cab, CamposGuia, RotulosLinea, Cantidades: string;
begin
  Cab := AConfig.PrefijoCabecera;
  Cel := Cab + 'CEL';
  // Se priorizan las celdas cuando explican toda la cantidad de la línea.
  // El importe acumulado reparte los céntimos incluso al cambiar de tramo.
  Result := 'WITH ORIGEN AS (' + SqlLineasImpresionCompra(AConfig) +
    '), LINEAS AS (' +
    'SELECT O.SERIE_DOC, O.NUMERO_DOC, O.LINEA, O.CODIGO_ART, O.SKU, ' +
    'O.REF_PRV, O.DESCRIPCION_BASE, O.VARIACION_TEXTO, O.COLOR_TEXTO, ' +
    'O.CODIGO_ATB_COLOR, O.TIPO_CANTIDAD, O.CANTIDAD, O.PRECIO_COMPRA, ' +
    'O.IMPORTE, O.DESCUENTO, O.IVA, O.CODIGO_ALM_ALBCLIN, O.LOTE, ' +
    'O.FECHA_CADUCIDAD, O.ID_AC_PIVOT, O.TALLA_SKU, O.ORDEN_SKU, ' +
    'COALESCE(CONCAT(''C'', ID_AC_PIVOT), ' +
    'CONCAT(''A'', COALESCE(CODIGO_ART, ''''))) AS SISTEMA, ' +
    'CASE WHEN SUFIJO = TALLA_SKU AND LOCATE(''/'', SKU) > 0 THEN ' +
    'LEFT(SKU, CHAR_LENGTH(SKU) - CHAR_LENGTH(SUFIJO) - 1) ' +
    'ELSE COALESCE(SKU, '''') END AS VARIANTE FROM ORIGEN O' +
    '), CELDAS AS (' +
    'SELECT L.LINEA, V.AV AS TALLA, MIN(V.ORDEN_AV) AS ORDEN, ' +
    'SUM(C.CANTIDAD_' + Cel + ') AS CANTIDAD ' +
    'FROM LINEAS L JOIN ' + AConfig.TablaCabecera + '_celdas C ' +
    'ON C.SERIE_' + Cab + '_' + Cel + ' = L.SERIE_DOC ' +
    'AND C.NUMERO_' + Cab + '_' + Cel + ' = L.NUMERO_DOC ' +
    'AND C.LINEA_' + Cab + '_' + Cel + ' = L.LINEA ' +
    'LEFT JOIN fza_atributos_valores V ON V.ID_AV = C.ID_AV_PIVOT_' + Cel +
    ' WHERE C.CANTIDAD_' + Cel + ' <> 0 GROUP BY L.LINEA, V.AV' +
    '), CELDAS_VALIDAS AS (' +
    'SELECT C.LINEA, C.TALLA, C.ORDEN, C.CANTIDAD, ' +
    'SUM(C.CANTIDAD) OVER (PARTITION BY C.LINEA ' +
    'ORDER BY C.ORDEN, C.TALLA ROWS UNBOUNDED PRECEDING) AS ACUMULADA ' +
    'FROM CELDAS C JOIN LINEAS L ON L.LINEA = C.LINEA ' +
    'JOIN (SELECT LINEA, SUM(CANTIDAD) AS CANTIDAD FROM CELDAS ' +
    'GROUP BY LINEA HAVING COUNT(*) = COUNT(NULLIF(TRIM(TALLA), ''''))) X ' +
    'ON X.LINEA = L.LINEA AND X.CANTIDAD = L.CANTIDAD ' +
    'WHERE L.CANTIDAD <> 0' +
    '), DETALLE AS (' +
    'SELECT L.LINEA, L.SISTEMA, C.TALLA, C.ORDEN, C.CANTIDAD, ' +
    '(CASE WHEN C.ACUMULADA = L.CANTIDAD THEN L.IMPORTE ' +
    'ELSE ROUND(L.IMPORTE * C.ACUMULADA / L.CANTIDAD, 2) END) - ' +
    '(CASE WHEN C.ACUMULADA - C.CANTIDAD = L.CANTIDAD THEN L.IMPORTE ' +
    'ELSE ROUND(L.IMPORTE * (C.ACUMULADA - C.CANTIDAD) / L.CANTIDAD, 2) ' +
    'END) AS IMPORTE FROM LINEAS L JOIN CELDAS_VALIDAS C ' +
    'ON C.LINEA = L.LINEA UNION ALL ' +
    'SELECT L.LINEA, L.SISTEMA, L.TALLA_SKU, L.ORDEN_SKU, ' +
    'L.CANTIDAD, L.IMPORTE FROM LINEAS L WHERE NOT EXISTS (' +
    'SELECT 1 FROM CELDAS_VALIDAS C WHERE C.LINEA = L.LINEA)' + ')';
  Result := Result + CteTramosImpresion(CamposGuia, RotulosLinea, Cantidades);
  if AGuias then
    Result := Result + SelectGuiasImpresion(CamposGuia)
  else
    Result := Result +
      'SELECT L.SERIE_DOC AS SERIE_ALBC, L.NUMERO_DOC AS NUMERO_ALBC, ' +
      'MIN(L.LINEA) AS LINEA_ALBC, L.CODIGO_ART, L.REF_PRV, ' +
      'COALESCE(NULLIF(L.REF_PRV, ''''), L.CODIGO_ART, '''') AS MODELO, ' +
      'CONCAT_WS(CHAR(1), L.REF_PRV, L.CODIGO_ART, L.DESCRIPCION_BASE) ' +
      'AS GRUPO_MODELO, ' +
      'L.DESCRIPCION_BASE, CONCAT(L.DESCRIPCION_BASE, ' +
      'CASE WHEN L.LOTE <> '''' THEN CONCAT(CHAR(10), ''Lote: '', L.LOTE) ' +
      'ELSE '''' END, COALESCE(CONCAT('' Cad.: '', ' +
      'DATE_FORMAT(L.FECHA_CADUCIDAD, ''%d/%m/%Y'')), '''')) AS DESCRIPCION, ' +
      'CASE WHEN T.TRAMO IS NULL THEN MAX(L.VARIACION_TEXTO) ELSE '''' ' +
      'END AS DETALLE, L.VARIANTE, MIN(L.SKU) AS CODIGO_UNIDAD, ' +
      'L.LOTE, L.FECHA_CADUCIDAD, L.COLOR_TEXTO, L.CODIGO_ATB_COLOR, ' +
      'L.ID_AC_PIVOT, MAX(G.NOMBRE_CORTO_AC) AS NOMBRE_CORTO_AC, ' +
      'MAX(G.NOMBRE_AC) AS NOMBRE_AC, L.TIPO_CANTIDAD, L.PRECIO_COMPRA, ' +
      '0 AS PRECIO_VENTA, SUM(D.CANTIDAD) AS TOTAL_UNIDADES, ' +
      'SUM(D.IMPORTE) AS TOTAL_LINEA, L.CODIGO_ALM_ALBCLIN, ' +
      'MAX(AL.CODIGO_EMP_ALM) AS CODIGO_EMP_ALM_ALBCLIN, ' +
      'MAX(AL.NOMBRE_ALM_ALM) AS NOMBRE_ALM_ALBCLIN, ' +
      'MAX(AL.DIRECCION_ALM) AS DIRECCION_ALM_ALBCLIN, ' +
      'MAX(AL.CODIGO_POSTAL_ALM) AS CODIGO_POSTAL_ALM_ALBCLIN, ' +
      'MAX(AL.POBLACION_ALM) AS POBLACION_ALM_ALBCLIN, ' +
      'MAX(AL.PROVINCIA_ALM) AS PROVINCIA_ALM_ALBCLIN, ' +
      'MAX(AL.TELEFONO_ALM) AS TELEFONO_ALM_ALBCLIN, ' +
      'MAX(AL.EMAIL_ALM) AS EMAIL_ALM_ALBCLIN' + RotulosLinea + Cantidades +
      ' FROM LINEAS L JOIN DETALLE D ON D.LINEA = L.LINEA ' +
      'LEFT JOIN TRAMOS T ON T.SISTEMA = D.SISTEMA AND T.TALLA = D.TALLA ' +
      'LEFT JOIN GUIAS G ON G.SISTEMA = T.SISTEMA AND G.TRAMO = T.TRAMO ' +
      'LEFT JOIN fza_almacenes AL ON AL.CODIGO_ALM_ALM = L.CODIGO_ALM_ALBCLIN ' +
      'GROUP BY L.SERIE_DOC, L.NUMERO_DOC, L.CODIGO_ART, L.REF_PRV, ' +
      'L.DESCRIPCION_BASE, L.VARIANTE, L.LOTE, L.FECHA_CADUCIDAD, ' +
      'L.COLOR_TEXTO, L.CODIGO_ATB_COLOR, L.ID_AC_PIVOT, ' +
      'L.TIPO_CANTIDAD, L.PRECIO_COMPRA, L.CODIGO_ALM_ALBCLIN, ' +
      'L.DESCUENTO, L.IVA, T.TRAMO, ' +
      'CASE WHEN T.TRAMO IS NULL THEN L.LINEA END ' +
      'ORDER BY MODELO, L.CODIGO_ART, L.DESCRIPCION_BASE, L.COLOR_TEXTO, ' +
      'L.VARIANTE, L.PRECIO_COMPRA, L.DESCUENTO, L.IVA, T.TRAMO, LINEA_ALBC';
end;

function SqlImpresionHorizontalSesion(AGuias: Boolean): string;
var
  CamposGuia, RotulosLinea, Cantidades: string;
begin
  Result :=
    'WITH LINEAS AS (' +
    'SELECT L.SERIE_SES_SESLIN AS SERIE_SES, ' +
    'L.NUMERO_SES_SESLIN AS NUMERO_SES, L.LINEA_SESLIN AS LINEA, ' +
    'L.CODIGO_ART_TENTATIVO_SESLIN AS CODIGO_ART, L.REF_PRV_SESLIN AS REF_PRV, ' +
    'L.DESCRIPCION_SESLIN AS DESCRIPCION, L.COLOR_TEXTO_SESLIN AS COLOR_TEXTO, ' +
    'L.CODIGO_ATB_COLOR_SESLIN AS CODIGO_ATB_COLOR, ' +
    'L.TIPO_CANTIDAD_SESLIN AS TIPO_CANTIDAD, S.CODIGO_ALM_SES AS ALMACEN, ' +
    'L.CANTIDAD_ESCALAR_SESLIN AS CANTIDAD_ESCALAR, ' +
    'L.PRECIO_COMPRA_SESLIN AS PRECIO_COMPRA, ' +
    'L.PRECIO_VENTA_SESLIN AS PRECIO_VENTA, NULLIF(L.ID_AC_PIVOT_SESLIN, 0) ' +
    'AS ID_AC_PIVOT, COALESCE(CONCAT(''C'', NULLIF(L.ID_AC_PIVOT_SESLIN, 0)), ' +
    'CONCAT(''A'', NULLIF(L.CODIGO_ART_TENTATIVO_SESLIN, '''')), ' +
    'CONCAT(''L'', L.LINEA_SESLIN)) AS SISTEMA ' +
    'FROM fza_compras_sesiones_lineas L JOIN fza_compras_sesiones S ' +
    'ON S.SERIE_SES = L.SERIE_SES_SESLIN AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    'WHERE L.SERIE_SES_SESLIN = :SERIE AND L.NUMERO_SES_SESLIN = :NUMERO' +
    '), DETALLE AS (' +
    'SELECT L.LINEA, L.SISTEMA, V.AV AS TALLA, V.ORDEN_AV AS ORDEN, ' +
    'COALESCE(NULLIF(C.CODIGO_ALM_SESCEL, ''''), L.ALMACEN) AS CODIGO_ALM, ' +
    'COALESCE(C.CANTIDAD_SESCEL, L.CANTIDAD_ESCALAR, 0) AS CANTIDAD, ' +
    'COALESCE(P.PRECIO_COMPRA_SESLINSKU, L.PRECIO_COMPRA) AS PRECIO_COMPRA, ' +
    'COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA) AS PRECIO_VENTA ' +
    'FROM LINEAS L LEFT JOIN fza_compras_sesiones_celdas C ' +
    'ON C.SERIE_SES_SESCEL = L.SERIE_SES AND C.NUMERO_SES_SESCEL = L.NUMERO_SES ' +
    'AND C.LINEA_SES_SESCEL = L.LINEA AND C.CANTIDAD_SESCEL <> 0 ' +
    'LEFT JOIN fza_atributos_valores V ON V.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
    'LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    'ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    'AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    'AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
    'AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
    'AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL)';
  Result := Result + CteTramosImpresion(CamposGuia, RotulosLinea, Cantidades);
  if AGuias then
    Result := Result + SelectGuiasImpresion(CamposGuia)
  else
    Result := Result +
      'SELECT L.SERIE_SES, L.NUMERO_SES, L.LINEA AS LINEA_SES, ' +
      'L.CODIGO_ART, L.REF_PRV, L.DESCRIPCION, L.COLOR_TEXTO, ' +
      'L.CODIGO_ATB_COLOR, L.TIPO_CANTIDAD, L.ID_AC_PIVOT, ' +
      'MAX(G.NOMBRE_AC) AS NOMBRE_AC, MAX(G.NOMBRE_CORTO_AC) AS NOMBRE_CORTO_AC, ' +
      'D.CODIGO_ALM, COALESCE(MAX(A.NOMBRE_ALM_ALM), D.CODIGO_ALM) AS NOMBRE_ALM, ' +
      'D.PRECIO_COMPRA, D.PRECIO_VENTA, SUM(D.CANTIDAD) AS TOTAL_UNIDADES, ' +
      'SUM(D.CANTIDAD * D.PRECIO_COMPRA) AS TOTAL_LINEA' + Cantidades +
      ' FROM LINEAS L JOIN DETALLE D ON D.LINEA = L.LINEA ' +
      'LEFT JOIN TRAMOS T ON T.SISTEMA = D.SISTEMA AND T.TALLA = D.TALLA ' +
      'LEFT JOIN GUIAS G ON G.SISTEMA = T.SISTEMA AND G.TRAMO = T.TRAMO ' +
      'LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = D.CODIGO_ALM ' +
      'GROUP BY L.SERIE_SES, L.NUMERO_SES, L.LINEA, L.CODIGO_ART, L.REF_PRV, ' +
      'L.DESCRIPCION, L.COLOR_TEXTO, L.CODIGO_ATB_COLOR, L.TIPO_CANTIDAD, ' +
      'L.ID_AC_PIVOT, D.CODIGO_ALM, D.PRECIO_COMPRA, D.PRECIO_VENTA, ' +
      'T.TRAMO ORDER BY L.LINEA, D.CODIGO_ALM, D.PRECIO_COMPRA, ' +
      'D.PRECIO_VENTA, T.TRAMO';
end;

// FROM ... WHERE de las celdas de talla (pivote) con cantidad de la
// linea L, con los valores de atributo en V.
function CeldasLinea(const AConfig: TConfiguracionDocumento): string;
var
  sCelda, sLineaCelda: string;
begin
  sCelda := AConfig.PrefijoCabecera + 'CEL';
  sLineaCelda := 'LINEA_' + sCelda;
  if AConfig.Sentido = sdCompra then
    sLineaCelda := 'LINEA_' + AConfig.PrefijoCabecera + '_' + sCelda;
  Result := ' FROM ' + AConfig.TablaCabecera + '_celdas C ' +
    'JOIN fza_atributos_valores V ON V.ID_AV = C.ID_AV_PIVOT_' +
    sCelda + ' WHERE C.SERIE_' + AConfig.PrefijoCabecera + '_' +
    sCelda + ' = L.' + AConfig.CampoSerieLinea +
    ' AND C.NUMERO_' + AConfig.PrefijoCabecera + '_' + sCelda +
    ' = L.' + AConfig.CampoNumeroLinea + ' AND C.' + sLineaCelda +
    ' = L.LINEA_' + AConfig.PrefijoLineas + ' AND C.CANTIDAD_' +
    sCelda + ' <> 0';
end;

// Cantidad con el formato del resto del documento: sin decimales si es
// entera y, si no, hasta dos con el separador decimal del equipo.
function CantidadCelda(const AConfig: TConfiguracionDocumento): string;
begin
  Result := 'REPLACE(TRIM(TRAILING ''.'' FROM TRIM(TRAILING ''0'' FROM ' +
    'CAST(ROUND(C.CANTIDAD_' + AConfig.PrefijoCabecera +
    'CEL, 2) AS CHAR))), ''.'', ' +
    QuotedStr(FormatSettings.DecimalSeparator) + ')';
end;

// Linea con varias tallas en celdas (rejilla de tallas en horizontal).
// Con una sola celda la talla ya va en el SKU de la linea.
function VariasTallas(const AConfig: TConfiguracionDocumento): string;
begin
  Result := '((SELECT COUNT(*)' + CeldasLinea(AConfig) + ') > 1)';
end;

// FZ-ISSUE-102: si el valor de atributo AAtributo es el color del SKU de
// la linea, el nombre de su color basico (como vi_atributos_sku_basico:
// articulo > conjunto > global) en vez del codigo (p. ej. "0908"); si no
// es un color o no tiene basico, el propio valor.
function NombreColorAtributo(const AConfig: TConfiguracionDocumento;
  const AAtributo: string): string;
begin
  Result := 'COALESCE((SELECT NULLIF(TRIM(VB.NOMBRE_ATB), '''') ' +
    'FROM vi_atributos_sku_basico VB WHERE VB.CODIGO_UNIDAD_SKU = ' +
    'L.CODIGO_UNIDAD_' + AConfig.PrefijoLineas + ' AND VB.ID_VA_AV = ' +
    '(SELECT E.ID_ATB_VA FROM VI_VARIACIONES_EJES E ' +
    'JOIN fza_articulos_skus SK ON SK.CODIGO_VAR_SKU = E.ID_VAR_VA ' +
    'WHERE SK.CODIGO_UNIDAD_SKU = VB.CODIGO_UNIDAD_SKU ' +
    'AND E.EJE_VA = ''F'') AND VB.VALOR_AV = ' +
    AAtributo + ' LIMIT 1), ' +
    AAtributo + ')';
end;

// Variante en el orden de atributos de la variacion (ATTR1..ATTR5, p. ej.
// color / talla). En una linea con varias tallas se omite el valor que
// es una de esas tallas: va en el desglose.
function VarianteLinea(const AConfig: TConfiguracionDocumento): string;
var
  sAtributo: string;
  iAtributo: Integer;
begin
  Result := 'CONCAT_WS('' / ''';
  for iAtributo := 1 to 5 do
  begin
    sAtributo := 'L.ATTR' + IntToStr(iAtributo) + '_VALOR_' +
      AConfig.PrefijoLineas;
    Result := Result + ', CASE WHEN ' + VariasTallas(AConfig) +
      ' AND EXISTS (SELECT 1' + CeldasLinea(AConfig) + ' AND V.AV = ' +
      sAtributo + ') THEN NULL ELSE NULLIF(TRIM(' +
      NombreColorAtributo(AConfig, sAtributo) + '), '''') END';
  end;
  Result := Result + ')';
  if AConfig.PrefijoLineas <> 'PEDLIN' then
    Result := 'COALESCE(NULLIF(' + Result + ', ''''), NULLIF(TRIM(' +
      'L.DESCRIPCION_VARIACION_' + AConfig.PrefijoLineas + '), ''''))';
end;

procedure TDatosInformeDocumento.ConfigurarLineas(
  const AConfig: TConfiguracionDocumento);
var
  sSufijo, sPrecio, sVariante, sTallas, sDetalle, sPropiedades: string;
  sDescuento, sModelo, sOrden, sTalla, sEsTalla: string;
begin
  sSufijo := '_' + AConfig.PrefijoLineas;
  sModelo := 'L.CODIGO_ART' + sSufijo;
  sOrden := 'LINEA' + sSufijo;
  if (AConfig.TipoDocumento = tdPedido) and
     (AConfig.Sentido = sdCompra) then
  begin
    sModelo := 'COALESCE((SELECT NULLIF(TRIM(AP.REF_PROVEEDOR_AP), ' +
      QuotedStr('') + ') FROM fza_articulos_proveedores AP ' +
      'JOIN fza_pedidos_compra PC ON PC.CODIGO_PRV_PEDC = ' +
      'AP.CODIGO_PRV_AP WHERE AP.CODIGO_ART_AP = L.CODIGO_ART_PEDCLIN ' +
      'AND PC.SERIE_PEDC = :SERIE AND PC.NUMERO_PEDC = :NUMERO ' +
      'LIMIT 1), L.CODIGO_ART_PEDCLIN)';
    // Los SKU con talla numerica terminan en /talla. El resto conserva
    // el orden de sus lineas; nunca se convierte texto de talla a cero.
    sTalla := 'SUBSTRING_INDEX(L.CODIGO_UNIDAD_PEDCLIN, ''/'', -1)';
    sEsTalla := 'L.CODIGO_UNIDAD_PEDCLIN REGEXP ' +
      QuotedStr('/[0-9]+([.,][0-9]+)?$');
    sOrden := 'MODELO, ARTICULO, CASE WHEN ' + sEsTalla +
      ' THEN LEFT(SKU, CHAR_LENGTH(SKU) - CHAR_LENGTH(' + sTalla +
      ')) ELSE ' + QuotedStr('') + ' END, CASE WHEN ' + sEsTalla +
      ' THEN CAST(REPLACE(' + sTalla + ', '','', ''.'') ' +
      'AS DECIMAL(12,3)) ELSE LINEA END, LINEA';
  end;
  sPrecio := PrecioLinea(AConfig);
  sDescuento := '';
  if AConfig.TipoDocumento = tdPresupuesto then
    sDescuento := 'COALESCE(PORCENTAJE_DTO_PRELIN, 0) AS ' +
      'PORCENTAJE_DTO, COALESCE(PRECIO_SALIDA_PRELIN / ' +
      '(CASE WHEN ESIMP_INCL_TARIFA_PRELIN = ''S'' THEN ' +
      '1 + COALESCE(PORCENTAJE_IVA_PRELIN, 0) / 100 ELSE 1 END), ' +
      sPrecio + ') AS PRECIO_ANTES_DTO, ';
  sVariante := VarianteLinea(AConfig);
  sPropiedades := 'NULL';
  if AConfig.Sentido = sdVenta then
    sPropiedades := SqlPropiedadesLinea('L.CODIGO_ART' + sSufijo,
      'L.CODIGO_UNIDAD' + sSufijo, AConfig.TipoDocumento = tdPresupuesto);
  // Desglose por talla solo si la linea lleva varias; con una, la talla
  // es la del SKU y el desglose repetiria (o contradiria) la variante.
  sTallas := '(CASE WHEN ' + VariasTallas(AConfig) +
    ' THEN (SELECT GROUP_CONCAT(CONCAT(V.AV, '': '', ' +
    CantidadCelda(AConfig) + ') ORDER BY V.ORDEN_AV, V.AV ' +
    'SEPARATOR '' / '')' + CeldasLinea(AConfig) + ') END)';
  // Descripcion y, debajo, variante y tallas solo si las hay.
  sDetalle := 'CONCAT_WS(' + SALTO_SQL + ', COALESCE(' +
    SinVacio('DESCRIPCION_ARTICULO' + sSufijo) + ', CODIGO_ART' +
    sSufijo + ', ''''), ' + SinVacio('CONCAT_WS('' · '', ' +
    SinVacio(sVariante) + ', ' + SinVacio(sTallas) + ')') + ', ' +
    sPropiedades + ')';
  FLineas.SQL.Text :=
    'SELECT LINEA' + sSufijo + ' AS LINEA, CODIGO_ART' + sSufijo +
    ' AS ARTICULO, CODIGO_UNIDAD' + sSufijo + ' AS SKU, ' +
    'CODIGO_ART' + sSufijo + ' AS CODIGO_ART, ' +
    'CODIGO_UNIDAD' + sSufijo + ' AS CODIGO_UNIDAD, ' +
    sModelo + ' AS MODELO, ' +
    'DESCRIPCION_ARTICULO' + sSufijo + ' AS DESCRIPCION, ' +
    sVariante + ' AS VARIACION, ' + sTallas + ' AS TALLAS, ' +
    sDetalle + ' AS DETALLE, ' +
    'COALESCE(TIPO_CANTIDAD_ARTICULO' + sSufijo + ', '''') AS UNIDAD, ' +
    'CANTIDAD' + sSufijo + ' AS CANTIDAD, ' + sPrecio +
    ' AS PRECIO, ' + sDescuento +
    'PORCENTAJE_IVA' + sSufijo + ' AS IVA, ' +
    'ROUND(CANTIDAD' + sSufijo + ' * ' + sPrecio +
    ', 2) AS TOTAL FROM ' + AConfig.TablaLineas + ' L' +
    ' WHERE ' + AConfig.CampoSerieLinea + ' = :SERIE AND ' +
    AConfig.CampoNumeroLinea + ' = :NUMERO ORDER BY ' + sOrden;
end;

procedure TDatosInformeDocumento.ConfigurarImpuestos(
  const AConfig: TConfiguracionDocumento);
const
  TIPOS: array[0..3] of Char = ('N', 'R', 'S', 'E');
var
  sSufijo, sSufijoLin, sBase, sNombre, sSql: string;
  iTipo: Integer;
begin
  sSufijo := '_' + AConfig.PrefijoCabecera;
  sSufijoLin := '_' + AConfig.PrefijoLineas;
  sSql := '';
  for iTipo := 0 to High(TIPOS) do
  begin
    case TIPOS[iTipo] of
      'N': sNombre := SInformeIvaNormalDocumento;
      'R': sNombre := SInformeIvaReducidoDocumento;
      'S': sNombre := SInformeIvaSuperreducidoDocumento;
    else
      sNombre := SInformeIvaExentoDocumento;
    end;
    // Usar el desglose guardado; líneas solo para documentos antiguos
    // cuyos campos nuevos aún no se hayan calculado.
    sBase := '(SELECT COALESCE(SUM(ROUND(L.CANTIDAD' + sSufijoLin +
      ' * L.' + PrecioLinea(AConfig) + ', 2)), 0) FROM ' +
      AConfig.TablaLineas + ' L WHERE L.' + AConfig.CampoSerieLinea +
      ' = :SERIE AND L.' + AConfig.CampoNumeroLinea + ' = :NUMERO ' +
      'AND COALESCE(NULLIF(L.TIPO_IVA_ARTICULO' + sSufijoLin +
      ', ''''), ''N'') = ''' + TIPOS[iTipo] + ''')';
    if sSql <> '' then
      sSql := sSql + ' UNION ALL ';
    sSql := sSql + 'SELECT ' + IntToStr(iTipo) + ' AS ORDEN, ' +
      QuotedStr(sNombre) + ' AS NOMBRE, COALESCE(PORCENTAJE_IVA' +
      TIPOS[iTipo] + sSufijo + ', 0) AS PORCENTAJE, COALESCE(TOTAL_BASEI_IVA' +
      TIPOS[iTipo] + sSufijo + ', ' + sBase + ')' +
      ' AS BASE, COALESCE(PORCENTAJE_RE' + TIPOS[iTipo] + sSufijo +
      ', 0) AS PORCENTAJE_RE, COALESCE(TOTAL_RE' + TIPOS[iTipo] +
      sSufijo + ', 0) AS CUOTA_RE, COALESCE(TOTAL_IVA' +
      TIPOS[iTipo] + sSufijo +
      ', 0) AS CUOTA FROM ' + AConfig.TablaCabecera +
      ' WHERE SERIE' + sSufijo + ' = :SERIE AND NUMERO' + sSufijo +
      ' = :NUMERO';
  end;
  FImpuestos.SQL.Text :=
    'SELECT NOMBRE, PORCENTAJE, BASE, CUOTA, PORCENTAJE_RE, CUOTA_RE ' +
    'FROM (' + sSql + ') T WHERE BASE <> 0 OR CUOTA <> 0 ' +
    'OR CUOTA_RE <> 0 ORDER BY ORDEN';
end;

procedure TDatosInformeDocumento.Abrir(AConexion: TUniConnection;
  const AConfig: TConfiguracionDocumento;
  const ASerie, ANumero: string; AHorizontal: Boolean);
var
  Consultas: TArray<TUniQuery>;
  oConsulta: TUniQuery;
begin
  FCabecera.Close;
  FLineas.Close;
  FLineasHorizontales.Close;
  FImpuestos.Close;
  ConfigurarCabecera(AConfig);
  ConfigurarLineas(AConfig);
  ConfigurarImpuestos(AConfig);
  Consultas := TArray<TUniQuery>.Create(FCabecera, FLineas, FImpuestos);
  if AHorizontal then
  begin
    FLineasHorizontales.SQL.Text := SqlImpresionHorizontalCompra(AConfig,
      False);
    Consultas := Consultas + [FLineasHorizontales];
  end;
  for oConsulta in Consultas do
  begin
    oConsulta.Connection := AConexion;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
  end;
  FCabecera.Open;
  if FCabecera.IsEmpty then
    raise Exception.Create(SErrorDocumentoImpresionNoExiste);
  FLineas.Open;
  FImpuestos.Open;
  if AHorizontal then
    FLineasHorizontales.Open;
end;

end.
