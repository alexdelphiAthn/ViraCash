{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDocumentosTrabajoCargaOrigenSql                        }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    SQL fijo y parametrizado para cargar documentos origen en documentos de  }
{    trabajo.                                                                  }
{******************************************************************************}
unit UniDataDocumentosTrabajoCargaOrigenSql;

interface

uses
  inLibDocumentosTrabajo;

function NormalizarLimiteDocumentosOrigen(ALimite: Integer): Integer;
// Las propuestas de traspaso solo entran en el listado si se pide: su
// tabla llega con el script de la distribución entre tiendas y, mientras no
// se aplique, el resto de los tipos tiene que seguir funcionando.
function SqlConsultarUltimosDocumentosOrigen(
  AIncluirPropuestasTraspaso: Boolean = False): string;
function SqlCabecerasRecientesDocumentosOrigen(
  AIncluirPropuestasTraspaso: Boolean = False): string;
function SqlExisteTablaPropuestasTraspaso: string;
function SqlDescripcionSkuDocumentoTrabajo(const ACampoSku: string): string;
function SqlTotalesUltimosDocumentosOrigen: string;
function SqlPrevisualizarLineasAlbaranVenta: string;
function SqlPrevisualizarLineasAlbaranCompra: string;
function SqlPrevisualizarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
function SqlBloquearDocumentoTrabajoCargaOrigen: string;
function SqlBloquearDocumentoOrigen(
  const ATipoDocumento: string): string;
function SqlContarLineasOrigenCargadas: string;
function SqlInsertarLineasOrigenAlbaranVenta: string;
function SqlInsertarLineasOrigenAlbaranCompra: string;
function SqlInsertarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
function SqlResumenCargaOrigenDocumento(
  const ATipoDocumento: string): string;
function SqlContarLineasOrigenSinSku(
  const ATipoDocumento: string): string;
procedure ValidarOrigenDocumentoTrabajo(
  const AOrigen: TDocumentoTrabajoOrigen);

implementation

uses
  System.SysUtils,
  inLibMsgVentas;

function NormalizarLimiteDocumentosOrigen(ALimite: Integer): Integer;
begin
  Result := ALimite;
  if Result <= 0 then
  begin
    Result := LIMITE_DOCUMENTOS_ORIGEN_DEFECTO;
  end;
  if Result > LIMITE_DOCUMENTOS_ORIGEN_MAXIMO then
  begin
    Result := LIMITE_DOCUMENTOS_ORIGEN_MAXIMO;
  end;
end;

function SqlLineaNumerica(const ACampo: string): string;
begin
  Result :=
    'CAST(NULLIF(TRIM(' + ACampo + '), '''') AS UNSIGNED)';
end;

function SqlCondicionArticuloFacturaCargable(
  const AAlias: string): string;
begin
  Result :=
    'UPPER(TRIM(' + AAlias + '.CODIGO_ART_FACLIN)) ' +
    'NOT IN (''ACUENTA'', ''ANTICIPO'')';
end;

function SqlCondicionLineaFacturaVenta(const AAlias: string): string;
begin
  Result :=
    SqlCondicionArticuloFacturaCargable(AAlias) +
    ' AND NULLIF(TRIM(' + AAlias +
    '.CODIGO_ART_FACLIN), '''') IS NOT NULL AND COALESCE(' +
    AAlias + '.CANTIDAD_FACLIN, 0) <> 0';
end;

function SqlCondicionMovimientoVenta(const AAlias: string): string;
begin
  Result :=
    'NULLIF(TRIM(' + AAlias + '.CODIGO_ART_MOV), '''') IS NOT NULL ' +
    'AND COALESCE(' + AAlias + '.CANTIDAD_MOV, 0) <> 0';
end;

function SqlSkuDirecto(const ACampoArticulo, ACampoSku: string): string;
begin
  Result :=
    'COALESCE((SELECT SK.CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus SK ' +
    ' WHERE SK.CODIGO_UNIDAD_SKU = NULLIF(TRIM(' + ACampoSku + '), '''') ' +
    '   AND SK.CODIGO_ART_SKU = ' + ACampoArticulo + ' ' +
    ' LIMIT 1), ' +
    '(SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '  FROM fza_articulos_skus SK ' +
    ' WHERE SK.CODIGO_ART_SKU = ' + ACampoArticulo + ' ' +
    '   AND SK.ESACTIVO_SKU = ''S'' HAVING COUNT(*) = 1))';
end;

// El SKU de la celda tiene la talla de la columna y los valores de fila
// (color) y de pestañas (copa) del SKU base de la línea.
function SqlCondicionSkuCelda(const ACampoArticulo, ACampoSkuBase,
  ACampoPivote: string): string;
begin
  Result :=
    'SK.CODIGO_ART_SKU = ' + ACampoArticulo + ' ' +
    'AND EXISTS (SELECT 1 FROM fza_atributos_sku SA ' +
    '         WHERE SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '           AND SA.ID_AV_SA = ' + ACampoPivote + ') ' +
    'AND NOT EXISTS (SELECT 1 ' +
    '         FROM fza_atributos_sku BASE ' +
    '         JOIN fza_atributos_valores FILA ' +
    '           ON FILA.ID_AV = BASE.ID_AV_SA ' +
    '          AND FILA.ID_VA_AV IN (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA IN (''F'', ''S'')) ' +
    '        WHERE BASE.CODIGO_UNIDAD_SKU_SA = ' + ACampoSkuBase + ' ' +
    '          AND NOT EXISTS (SELECT 1 FROM fza_atributos_sku DESTINO ' +
    '               WHERE DESTINO.CODIGO_UNIDAD_SKU_SA = ' +
    '                     SK.CODIGO_UNIDAD_SKU ' +
    '                 AND DESTINO.ID_AV_SA = BASE.ID_AV_SA))';
end;

function SqlSkuCelda(const ACampoArticulo, ACampoSkuBase,
  ACampoPivote: string): string;
var
  Condicion: string;
begin
  Condicion := SqlCondicionSkuCelda(
    ACampoArticulo, ACampoSkuBase, ACampoPivote);
  Result :=
    'COALESCE((SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '  FROM fza_articulos_skus SK WHERE ' + Condicion + ' ' +
    '   AND SK.ESACTIVO_SKU = ''S'' HAVING COUNT(*) = 1), ' +
    '(SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '  FROM fza_articulos_skus SK WHERE ' + Condicion + ' ' +
    ' HAVING COUNT(*) = 1))';
end;

function SqlDescripcionSkuDocumentoTrabajo(const ACampoSku: string): string;
begin
  Result :=
    '(SELECT GROUP_CONCAT(AV.AV ORDER BY COALESCE(VA.ORDEN_VA, 999), ' +
    'AV.ID_VA_AV, AV.ORDEN_AV, AV.ID_AV SEPARATOR '' / '') ' +
    '   FROM fza_atributos_sku SA ' +
    '   JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    '   JOIN fza_articulos_skus SK ' +
    '     ON SK.CODIGO_UNIDAD_SKU = SA.CODIGO_UNIDAD_SKU_SA ' +
    '   LEFT JOIN fza_variaciones_atributos VA ' +
    '     ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
    '    AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
    '  WHERE SA.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku + ')';
end;

function SqlLineasResueltas(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT B.EMPRESA_DOCUMENTO, B.TIPO_DOCUMENTO, ' +
    '       B.SERIE_DOCUMENTO, B.NUMERO_DOCUMENTO, ' +
    '       B.LINEA_DOCUMENTO, B.ORDEN_LINEA, B.ORDEN_FILA, ' +
    '       B.ORDEN_PIVOTE, B.ORDEN_ALMACEN, B.CODIGO_ARTICULO, ' +
    '       B.CODIGO_SKU, B.CODIGO_ALMACEN, B.LOTE, ' +
    '       B.FECHA_CADUCIDAD, B.DESCRIPCION_ARTICULO, ' +
    '       COALESCE(' + SqlDescripcionSkuDocumentoTrabajo('B.CODIGO_SKU') +
    ', '''') AS DESCRIPCION_SKU, B.CANTIDAD ' +
    '  FROM (' + ASqlLineas + ') B';
end;

function SqlLineasElegibles(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT E.* FROM (' + SqlLineasResueltas(ASqlLineas) + ') E ' +
    ' WHERE NULLIF(TRIM(E.CODIGO_SKU), '''') IS NOT NULL';
end;

function SqlBloquearDocumentoTrabajoCargaOrigen: string;
begin
  Result :=
    'SELECT USUARIO_DTR, ESTADO_DTR, CODIGO_EMP_DTR ' +
    '  FROM fza_documentos_trabajo ' +
    ' WHERE ID_DTR = :ID_DTR FOR UPDATE';
end;

function SqlContarLineasOrigenCargadas: string;
begin
  Result :=
    'SELECT COUNT(*) AS LINEAS_CARGADAS ' +
    '  FROM fza_documentos_trabajo_lineas ' +
    ' WHERE ID_DTR_DTL = :ID_DTR ' +
    '   AND CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '   AND TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '   AND SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '   AND NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO';
end;

function SqlLineasAlbaranVentaBase(
  const AFiltroCabecera: string): string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_ALB AS EMPRESA_DOCUMENTO, ' +
    '       ''AV'' AS TIPO_DOCUMENTO, ' +
    '       H.SERIE_ALB AS SERIE_DOCUMENTO, ' +
    '       H.NUMERO_ALB AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_ALBLIN) AS LINEA_DOCUMENTO, ' +
    '       ' + SqlLineaNumerica('L.LINEA_ALBLIN') +
    ' AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       '''' AS ORDEN_ALMACEN, L.CODIGO_ART_ALBLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_ALBLIN', 'L.CODIGO_UNIDAD_ALBLIN') +
    '         AS CODIGO_SKU, ' +
    '       COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '                H.CODIGO_ALM_ALB, '''') AS CODIGO_ALMACEN, ' +
    '       COALESCE(L.LOTE_ALBLIN, '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_ALBLIN AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_ALBLIN AS CANTIDAD ' +
    '  FROM fza_albaranes H ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = H.SERIE_ALB ' +
    '   AND L.NUMERO_ALB_ALBLIN = H.NUMERO_ALB ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_celdas C ' +
    '         WHERE C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '           AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '           AND C.LINEA_ALBCEL = ' +
    SqlLineaNumerica('L.LINEA_ALBLIN') + ' ' +
    '           AND C.CANTIDAD_ALBCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_ALB, ''AV'', H.SERIE_ALB, H.NUMERO_ALB, ' +
    '       CONCAT(''C:'', L.LINEA_ALBLIN, '':'', C.ID_FILA_ALBCEL, ' +
    '              '':'', C.ID_AV_PIVOT_ALBCEL, '':'', ' +
    '              COALESCE(C.CODIGO_ALM_ALBCEL, '''')), ' +
    '       ' + SqlLineaNumerica('L.LINEA_ALBLIN') +
    ', C.ID_FILA_ALBCEL, ' +
    '       C.ID_AV_PIVOT_ALBCEL, COALESCE(C.CODIGO_ALM_ALBCEL, ''''), ' +
    '       L.CODIGO_ART_ALBLIN, ' +
    '       ' + SqlSkuCelda(
      'L.CODIGO_ART_ALBLIN', 'L.CODIGO_UNIDAD_ALBLIN',
      'C.ID_AV_PIVOT_ALBCEL') + ', ' +
    '       COALESCE(NULLIF(C.CODIGO_ALM_ALBCEL, ''''), ' +
    '                NULLIF(L.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '                H.CODIGO_ALM_ALB, ''''), ' +
    '       COALESCE(L.LOTE_ALBLIN, ''''), L.FECHA_CADUCIDAD_ALBLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBLIN, ''''), ' +
    '       C.CANTIDAD_ALBCEL ' +
    '  FROM fza_albaranes H ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = H.SERIE_ALB ' +
    '   AND L.NUMERO_ALB_ALBLIN = H.NUMERO_ALB ' +
    '  JOIN fza_albaranes_celdas C ' +
    '    ON C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '   AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '   AND C.LINEA_ALBCEL = ' +
    SqlLineaNumerica('L.LINEA_ALBLIN') + ' ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCEL <> 0';
end;

function SqlLineasAlbaranVentaResueltas: string;
begin
  Result := SqlLineasResueltas(SqlLineasAlbaranVentaBase(
    'H.CODIGO_EMP_ALB = :EMPRESA ' +
    'AND H.SERIE_ALB = :SERIE AND H.NUMERO_ALB = :NUMERO'));
end;

function SqlLineasAlbaranVenta: string;
begin
  Result := SqlLineasElegibles(SqlLineasAlbaranVentaBase(
    'H.CODIGO_EMP_ALB = :EMPRESA ' +
    'AND H.SERIE_ALB = :SERIE AND H.NUMERO_ALB = :NUMERO'));
end;

function SqlLineasAlbaranCompraBase(
  const AFiltroCabecera: string): string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_ALBC AS EMPRESA_DOCUMENTO, ' +
    '       ''AB'' AS TIPO_DOCUMENTO, ' +
    '       H.SERIE_ALBC AS SERIE_DOCUMENTO, ' +
    '       H.NUMERO_ALBC AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_ALBCLIN) AS LINEA_DOCUMENTO, ' +
    '       L.LINEA_ALBCLIN AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       '''' AS ORDEN_ALMACEN, L.CODIGO_ART_ALBCLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_ALBCLIN', 'L.CODIGO_UNIDAD_ALBCLIN') +
    '         AS CODIGO_SKU, ' +
    '       COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    '                H.CODIGO_ALM_ALBC, '''') AS CODIGO_ALMACEN, ' +
    '       COALESCE(L.LOTE_ALBCLIN, '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_ALBCLIN AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBCLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_ALBCLIN AS CANTIDAD ' +
    '  FROM fza_albaranes_compra H ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBCLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_compra_celdas C ' +
    '         WHERE C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '           AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '           AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    '           AND C.CANTIDAD_ALBCCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_ALBC, ''AB'', H.SERIE_ALBC, H.NUMERO_ALBC, ' +
    '       CONCAT(''C:'', L.LINEA_ALBCLIN, '':'', ' +
    '              C.ID_FILA_ALBC_ALBCCEL, '':'', ' +
    '              C.ID_AV_PIVOT_ALBCCEL), ' +
    '       L.LINEA_ALBCLIN, ' +
    '       C.ID_FILA_ALBC_ALBCCEL, C.ID_AV_PIVOT_ALBCCEL, '''', ' +
    '       L.CODIGO_ART_ALBCLIN, ' +
    '       ' + SqlSkuCelda(
      'L.CODIGO_ART_ALBCLIN', 'L.CODIGO_UNIDAD_ALBCLIN',
      'C.ID_AV_PIVOT_ALBCCEL') + ', ' +
    '       COALESCE(NULLIF(C.CODIGO_ALM_ALBCCEL, ''''), ' +
    '                NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    '                H.CODIGO_ALM_ALBC, ''''), ' +
    '       COALESCE(L.LOTE_ALBCLIN, ''''), L.FECHA_CADUCIDAD_ALBCLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_ALBCLIN, ''''), ' +
    '       C.CANTIDAD_ALBCCEL ' +
    '  FROM fza_albaranes_compra H ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC ' +
    '  JOIN fza_albaranes_compra_celdas C ' +
    '    ON C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '   AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '   AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCCEL <> 0';
end;

function SqlLineasAlbaranCompraResueltas: string;
begin
  Result := SqlLineasResueltas(SqlLineasAlbaranCompraBase(
    'H.CODIGO_EMP_ALBC = :EMPRESA ' +
    'AND H.SERIE_ALBC = :SERIE AND H.NUMERO_ALBC = :NUMERO'));
end;

function SqlLineasAlbaranCompra: string;
begin
  Result := SqlLineasElegibles(SqlLineasAlbaranCompraBase(
    'H.CODIGO_EMP_ALBC = :EMPRESA ' +
    'AND H.SERIE_ALBC = :SERIE AND H.NUMERO_ALBC = :NUMERO'));
end;

function SqlLineasConCeldasBase(const ATipoDocumento,
  ATablaCabecera, ACampoEmpresaCabecera, ACampoSerieCabecera,
  ACampoNumeroCabecera, ACampoAlmacenCabecera, ATablaLineas,
  ACampoSerieLineas, ACampoNumeroLineas, ACampoLinea,
  ACampoArticulo, ACampoSku, AExpresionAlmacenLinea,
  AExpresionLote, AExpresionCaducidad, AExpresionDescripcion,
  AExpresionCantidad, ATablaCeldas, ACampoSerieCeldas,
  ACampoNumeroCeldas, ACampoLineaCeldas, ACampoFilaCeldas,
  ACampoPivoteCeldas, AExpresionAlmacenCelda,
  ACampoCantidadCeldas, AFiltroCabecera: string): string;
var
  Almacen: string;
  AlmacenCelda: string;
  Articulo: string;
  Cantidad: string;
  Linea: string;
  Numero: string;
  Serie: string;
  Sku: string;
begin
  Almacen :=
    'COALESCE(NULLIF(TRIM(' + AExpresionAlmacenLinea + '), ''''), ' +
    'NULLIF(TRIM(H.' + ACampoAlmacenCabecera + '), ''''), '''')';
  Articulo := 'L.' + ACampoArticulo;
  Cantidad := AExpresionCantidad;
  Linea := 'L.' + ACampoLinea;
  Numero := 'H.' + ACampoNumeroCabecera;
  Serie := 'H.' + ACampoSerieCabecera;
  Sku := 'L.' + ACampoSku;
  Result :=
    'SELECT H.' + ACampoEmpresaCabecera + ' AS EMPRESA_DOCUMENTO, ' +
    '       ''' + ATipoDocumento + ''' AS TIPO_DOCUMENTO, ' +
    '       ' + Serie + ' AS SERIE_DOCUMENTO, ' +
    '       ' + Numero + ' AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', ' + Linea + ') AS LINEA_DOCUMENTO, ' +
    '       ' + SqlLineaNumerica(Linea) + ' AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       '''' AS ORDEN_ALMACEN, ' +
    '       ' + Articulo + ' AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(Articulo, Sku) + ' AS CODIGO_SKU, ' +
    '       ' + Almacen + ' AS CODIGO_ALMACEN, ' +
    '       ' + AExpresionLote + ' AS LOTE, ' +
    '       ' + AExpresionCaducidad + ' AS FECHA_CADUCIDAD, ' +
    '       ' + AExpresionDescripcion + ' AS DESCRIPCION_ARTICULO, ' +
    '       ' + Cantidad + ' AS CANTIDAD ' +
    '  FROM ' + ATablaCabecera + ' H ' +
    '  JOIN ' + ATablaLineas + ' L ' +
    '    ON L.' + ACampoSerieLineas + ' = ' + Serie + ' ' +
    '   AND L.' + ACampoNumeroLineas + ' = ' + Numero + ' ' +
    ' WHERE ' + AFiltroCabecera + ' ' +
    '   AND NULLIF(TRIM(' + Articulo + '), '''') IS NOT NULL ' +
    '   AND COALESCE(' + Cantidad + ', 0) <> 0 ';
  if Trim(ATablaCeldas) <> '' then
  begin
    AlmacenCelda :=
      'COALESCE(NULLIF(TRIM(' + AExpresionAlmacenCelda + '), ''''), ' +
      'NULLIF(TRIM(' + AExpresionAlmacenLinea + '), ''''), ' +
      'NULLIF(TRIM(H.' + ACampoAlmacenCabecera + '), ''''), '''')';
    Result := Result +
      '   AND NOT EXISTS (SELECT 1 FROM ' + ATablaCeldas + ' C ' +
      '         WHERE C.' + ACampoSerieCeldas + ' = ' + Serie + ' ' +
      '           AND C.' + ACampoNumeroCeldas + ' = ' + Numero + ' ' +
      '           AND CAST(NULLIF(TRIM(C.' + ACampoLineaCeldas +
      '), '''') AS UNSIGNED) = CAST(NULLIF(TRIM(' + Linea +
      '), '''') AS UNSIGNED) ' +
      '           AND C.' + ACampoCantidadCeldas + ' <> 0) ' +
      'UNION ALL ' +
      'SELECT H.' + ACampoEmpresaCabecera + ', ' +
      '       ''' + ATipoDocumento + ''', ' + Serie + ', ' + Numero + ', ' +
      '       CONCAT(''C:'', ' + Linea + ', '':'', ' +
      '              C.' + ACampoFilaCeldas + ', '':'', ' +
      '              C.' + ACampoPivoteCeldas + ', '':'', ' +
      '              COALESCE(' + AExpresionAlmacenCelda + ', '''')), ' +
      '       ' + SqlLineaNumerica(Linea) + ', ' +
      '       C.' + ACampoFilaCeldas + ', ' +
      '       C.' + ACampoPivoteCeldas + ', ' +
      '       COALESCE(' + AExpresionAlmacenCelda + ', ''''), ' +
      '       ' + Articulo + ', ' +
      '       ' + SqlSkuCelda(Articulo, Sku,
        'C.' + ACampoPivoteCeldas) + ', ' +
      '       ' + AlmacenCelda + ', ' + AExpresionLote + ', ' +
      '       ' + AExpresionCaducidad + ', ' +
      '       ' + AExpresionDescripcion + ', ' +
      '       C.' + ACampoCantidadCeldas + ' ' +
      '  FROM ' + ATablaCabecera + ' H ' +
      '  JOIN ' + ATablaLineas + ' L ' +
      '    ON L.' + ACampoSerieLineas + ' = ' + Serie + ' ' +
      '   AND L.' + ACampoNumeroLineas + ' = ' + Numero + ' ' +
      '  JOIN ' + ATablaCeldas + ' C ' +
      '    ON C.' + ACampoSerieCeldas + ' = ' + Serie + ' ' +
      '   AND C.' + ACampoNumeroCeldas + ' = ' + Numero + ' ' +
      '   AND CAST(NULLIF(TRIM(C.' + ACampoLineaCeldas +
      '), '''') AS UNSIGNED) = CAST(NULLIF(TRIM(' + Linea +
      '), '''') AS UNSIGNED) ' +
      ' WHERE ' + AFiltroCabecera + ' ' +
      '   AND NULLIF(TRIM(' + Articulo + '), '''') IS NOT NULL ' +
      '   AND C.' + ACampoCantidadCeldas + ' <> 0';
  end;
end;

function SqlLineasPedidoVentaBase(const AFiltro: string): string;
begin
  Result := SqlLineasConCeldasBase('PE', 'fza_pedidos',
    'CODIGO_EMP_PED', 'SERIE_PED', 'NUMERO_PED', 'CODIGO_ALM_PED',
    'fza_pedidos_lineas', 'SERIE_PED_PEDLIN',
    'NUMERO_PED_PEDLIN', 'LINEA_PEDLIN', 'CODIGO_ART_PEDLIN',
    'CODIGO_UNIDAD_PEDLIN', 'L.CODIGO_ALMACEN_PEDLIN', '''''',
    'NULL', 'COALESCE(L.DESCRIPCION_ARTICULO_PEDLIN, '''')',
    'L.CANTIDAD_PEDLIN', 'fza_pedidos_celdas',
    'SERIE_PED_PEDCEL', 'NUMERO_PED_PEDCEL', 'LINEA_PEDCEL',
    'ID_FILA_PEDCEL', 'ID_AV_PIVOT_PEDCEL', 'C.CODIGO_ALM_PEDCEL',
    'CANTIDAD_PEDCEL', AFiltro);
end;

function SqlLineasPresupuestoVentaBase(const AFiltro: string): string;
begin
  Result := SqlLineasConCeldasBase('PR', 'fza_presupuestos',
    'CODIGO_EMP_PRE', 'SERIE_PRE', 'NUMERO_PRE', 'CODIGO_ALM_PRE',
    'fza_presupuestos_lineas', 'SERIE_PRE_PRELIN',
    'NUMERO_PRE_PRELIN', 'LINEA_PRELIN', 'CODIGO_ART_PRELIN',
    'CODIGO_UNIDAD_PRELIN', 'L.CODIGO_ALMACEN_PRELIN', '''''',
    'NULL', 'COALESCE(L.DESCRIPCION_ARTICULO_PRELIN, '''')',
    'L.CANTIDAD_PRELIN', 'fza_presupuestos_celdas',
    'SERIE_PRE_PRECEL', 'NUMERO_PRE_PRECEL', 'LINEA_PRECEL',
    'ID_FILA_PRECEL', 'ID_AV_PIVOT_PRECEL', 'C.CODIGO_ALM_PRECEL',
    'CANTIDAD_PRECEL', AFiltro);
end;

function SqlLineasPedidoCompraBase(const AFiltro: string): string;
begin
  Result := SqlLineasConCeldasBase('PC', 'fza_pedidos_compra',
    'CODIGO_EMP_PEDC', 'SERIE_PEDC', 'NUMERO_PEDC',
    'CODIGO_ALM_PEDC', 'fza_pedidos_compra_lineas',
    'SERIE_PEDC_PEDCLIN', 'NUMERO_PEDC_PEDCLIN', 'LINEA_PEDCLIN',
    'CODIGO_ART_PEDCLIN', 'CODIGO_UNIDAD_PEDCLIN',
    'L.CODIGO_ALMACEN_PEDCLIN', '''''', 'NULL',
    'COALESCE(L.DESCRIPCION_ARTICULO_PEDCLIN, '''')',
    'L.CANTIDAD_PEDCLIN', 'fza_pedidos_compra_celdas',
    'SERIE_PEDC_PEDCCEL', 'NUMERO_PEDC_PEDCCEL',
    'LINEA_PEDC_PEDCCEL', 'ID_FILA_PEDC_PEDCCEL',
    'ID_AV_PIVOT_PEDCCEL', 'C.CODIGO_ALM_PEDCCEL',
    'CANTIDAD_PEDCCEL', AFiltro);
end;

function SqlLineasFacturaVentaBase(const AFiltro: string): string;
var
  Filtro: string;
begin
  Filtro := AFiltro +
    ' AND ' + SqlCondicionArticuloFacturaCargable('L');
  Result := SqlLineasConCeldasBase('FC', 'fza_facturas',
    'CODIGO_EMP_FAC', 'SERIE_FAC', 'NUMERO_FAC', 'CODIGO_ALM_FAC',
    'fza_facturas_lineas', 'SERIE_FAC_FACLIN',
    'NUMERO_FAC_FACLIN', 'LINEA_FACLIN', 'CODIGO_ART_FACLIN',
    'CODIGO_UNIDAD_FACLIN', 'L.CODIGO_ALM_FACLIN',
    'COALESCE(L.LOTE_FACLIN, '''')', 'L.FECHA_CADUCIDAD_FACLIN',
    'COALESCE(L.DESCRIPCION_ARTICULO_FACLIN, '''')',
    'L.CANTIDAD_FACLIN', '', '', '', '', '', '', '', '', Filtro);
end;

function SqlLineasFacturaCompraBase(const AFiltro: string): string;
begin
  Result := SqlLineasConCeldasBase('FP', 'fza_facturas_compra',
    'CODIGO_EMP_FACC', 'SERIE_FACC', 'NUMERO_FACC',
    'CODIGO_ALM_FACC', 'fza_facturas_compra_lineas',
    'SERIE_FACC_FACCLIN', 'NUMERO_FACC_FACCLIN', 'LINEA_FACCLIN',
    'CODIGO_ART_FACCLIN', 'CODIGO_UNIDAD_FACCLIN',
    'L.CODIGO_ALMACEN_FACCLIN', 'COALESCE(L.LOTE_FACCLIN, '''')',
    'L.FECHA_CADUCIDAD_FACCLIN',
    'COALESCE(L.DESCRIPCION_ARTICULO_FACCLIN, '''')',
    'L.CANTIDAD_FACCLIN', 'fza_facturas_compra_celdas',
    'SERIE_FACC_FACCCEL', 'NUMERO_FACC_FACCCEL',
    'LINEA_FACC_FACCCEL', 'ID_FILA_FACC_FACCCEL',
    'ID_AV_PIVOT_FACCCEL', 'C.CODIGO_ALM_FACCCEL',
    'CANTIDAD_FACCCEL', AFiltro);
end;

function SqlLineasDevolucionCompraBase(const AFiltro: string): string;
begin
  Result := SqlLineasConCeldasBase('DC', 'fza_devoluciones_compra',
    'CODIGO_EMP_DEVC', 'SERIE_DEVC', 'NUMERO_DEVC',
    'CODIGO_ALM_DEVC', 'fza_devoluciones_compra_lineas',
    'SERIE_DEVC_DEVCLIN', 'NUMERO_DEVC_DEVCLIN', 'LINEA_DEVCLIN',
    'CODIGO_ART_DEVCLIN', 'CODIGO_UNIDAD_DEVCLIN',
    'L.CODIGO_ALMACEN_DEVCLIN', 'COALESCE(L.LOTE_DEVCLIN, '''')',
    'L.FECHA_CADUCIDAD_DEVCLIN',
    'COALESCE(L.DESCRIPCION_ARTICULO_DEVCLIN, '''')',
    'L.CANTIDAD_DEVCLIN', 'fza_devoluciones_compra_celdas',
    'SERIE_DEVC_DEVCCEL', 'NUMERO_DEVC_DEVCCEL',
    'LINEA_DEVC_DEVCCEL', 'ID_FILA_DEVC_DEVCCEL',
    'ID_AV_PIVOT_DEVCCEL', 'C.CODIGO_ALM_DEVCCEL',
    'CANTIDAD_DEVCCEL', AFiltro);
end;

function SqlLineasVentaTpvBase: string;
var
  SkuFactura: string;
  SkuMovimiento: string;
begin
  SkuFactura := SqlSkuDirecto(
    'L.CODIGO_ART_FACLIN', 'L.CODIGO_UNIDAD_FACLIN');
  SkuMovimiento := SqlSkuDirecto(
    'M.CODIGO_ART_MOV', 'M.CODIGO_UNIDAD_MOV');
  Result :=
    'SELECT H.CODIGO_EMP_OPCAJA AS EMPRESA_DOCUMENTO, ' +
    '       ''VE'' AS TIPO_DOCUMENTO, ' +
    '       CAST(H.ID_OPCAJA AS CHAR) AS SERIE_DOCUMENTO, ' +
    '       CAST(H.ID_OPCAJA AS CHAR) AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''F:'', L.LINEA_FACLIN) AS LINEA_DOCUMENTO, ' +
    '       ' + SqlLineaNumerica('L.LINEA_FACLIN') +
    ' AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       '''' AS ORDEN_ALMACEN, ' +
    '       L.CODIGO_ART_FACLIN AS CODIGO_ARTICULO, ' +
    '       ' + SkuFactura + ' AS CODIGO_SKU, ' +
    '       COALESCE(NULLIF(L.CODIGO_ALM_FACLIN, ''''), ' +
    '                H.CODIGO_ALM_OPCAJA, '''') AS CODIGO_ALMACEN, ' +
    '       COALESCE(L.LOTE_FACLIN, '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_FACLIN AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_FACLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_FACLIN AS CANTIDAD ' +
    '  FROM fza_caja_operaciones H ' +
    '  JOIN fza_facturas_lineas L ' +
    '    ON L.SERIE_FAC_FACLIN = H.SERIE_FAC_OPCAJA ' +
    '   AND L.NUMERO_FAC_FACLIN = H.NUMERO_FAC_OPCAJA ' +
    ' WHERE H.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND H.ID_OPCAJA = CAST(:SERIE AS UNSIGNED) ' +
    '   AND CAST(H.ID_OPCAJA AS CHAR) = :NUMERO ' +
    '   AND H.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    '   AND ' + SqlCondicionLineaFacturaVenta('L') + ' ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_OPCAJA, ''VE'', ' +
    '       CAST(H.ID_OPCAJA AS CHAR), CAST(H.ID_OPCAJA AS CHAR), ' +
    '       CONCAT(''M:'', M.NUMERO_MOV), ' +
    '       CAST(M.LINEA_MOV AS UNSIGNED), 0, 0, '''', ' +
    '       M.CODIGO_ART_MOV, ' + SkuMovimiento + ', ' +
    '       M.CODIGO_ALM_MOV, COALESCE(M.LOTE_MOV, ''''), ' +
    '       M.FECHA_CADUCIDAD_MOV, ' +
    '       COALESCE(M.DESCRIPCION_ARTICULO_MOV, ''''), ' +
    '       M.CANTIDAD_MOV ' +
    '  FROM fza_caja_operaciones H ' +
    '  JOIN fza_movimientos_almacen M ' +
    '    ON M.CODIGO_EMP_MOV = H.CODIGO_EMP_OPCAJA ' +
    '   AND M.CODIGO_ALM_DOC_MOV = H.CODIGO_ALM_OPCAJA ' +
    '   AND M.CODIGO_CAJA_DOC_MOV = H.CODIGO_CAJA_OPCAJA ' +
    '   AND M.NUMERO_OPERACION_DOC_MOV = H.NUMERO_OPERACION_OPCAJA ' +
    ' WHERE H.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND H.ID_OPCAJA = CAST(:SERIE AS UNSIGNED) ' +
    '   AND CAST(H.ID_OPCAJA AS CHAR) = :NUMERO ' +
    '   AND H.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    '   AND M.TIPO_DOC_MOV = ''VE'' AND M.TIPO_MOV = ''S'' ' +
    '   AND M.ESACTIVO_MOV = ''S'' ' +
    '   AND ' + SqlCondicionMovimientoVenta('M') + ' ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_facturas_lineas F ' +
    '         WHERE F.SERIE_FAC_FACLIN = H.SERIE_FAC_OPCAJA ' +
    '           AND F.NUMERO_FAC_FACLIN = H.NUMERO_FAC_OPCAJA ' +
    '           AND ' + SqlCondicionLineaFacturaVenta('F') + ')';
end;

function SqlLineasTraspasoBase: string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_OPCAJA AS EMPRESA_DOCUMENTO, ' +
    '       ''TR'' AS TIPO_DOCUMENTO, ' +
    '       CAST(H.ID_OPCAJA AS CHAR) AS SERIE_DOCUMENTO, ' +
    '       CAST(H.ID_OPCAJA AS CHAR) AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''M:'', M.NUMERO_MOV) AS LINEA_DOCUMENTO, ' +
    '       CAST(M.LINEA_MOV AS UNSIGNED) AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       M.CODIGO_ALM_MOV AS ORDEN_ALMACEN, ' +
    '       M.CODIGO_ART_MOV AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'M.CODIGO_ART_MOV', 'M.CODIGO_UNIDAD_MOV') + ' AS CODIGO_SKU, ' +
    '       M.CODIGO_ALM_MOV AS CODIGO_ALMACEN, ' +
    '       COALESCE(M.LOTE_MOV, '''') AS LOTE, ' +
    '       M.FECHA_CADUCIDAD_MOV AS FECHA_CADUCIDAD, ' +
    '       COALESCE(M.DESCRIPCION_ARTICULO_MOV, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       M.CANTIDAD_MOV AS CANTIDAD ' +
    '  FROM fza_caja_operaciones H ' +
    '  JOIN fza_movimientos_almacen M ' +
    '    ON M.CODIGO_EMP_MOV = H.CODIGO_EMP_OPCAJA ' +
    '   AND M.CODIGO_ALM_DOC_MOV = H.CODIGO_ALM_OPCAJA ' +
    '   AND M.CODIGO_CAJA_DOC_MOV = H.CODIGO_CAJA_OPCAJA ' +
    '   AND M.NUMERO_OPERACION_DOC_MOV = H.NUMERO_OPERACION_OPCAJA ' +
    ' WHERE H.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND H.ID_OPCAJA = CAST(:SERIE AS UNSIGNED) ' +
    '   AND CAST(H.ID_OPCAJA AS CHAR) = :NUMERO ' +
    '   AND H.TIPO_OPERACION_OPCAJA IN (''TR'', ''TA'', ''AT'') ' +
    '   AND M.TIPO_DOC_MOV IN (''TR'', ''TA'', ''AT'') ' +
    '   AND M.TIPO_MOV = ''S'' AND M.ESACTIVO_MOV = ''S'' ' +
    '   AND NULLIF(TRIM(M.CODIGO_ART_MOV), '''') IS NOT NULL ' +
    '   AND COALESCE(M.CANTIDAD_MOV, 0) <> 0';
end;

function SqlLineasPeticionTraspasoBase: string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_TRSOL AS EMPRESA_DOCUMENTO, ' +
    '       ''TS'' AS TIPO_DOCUMENTO, H.SERIE_TRSOL AS SERIE_DOCUMENTO, ' +
    '       H.NUMERO_TRSOL AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_TRSOLLIN) AS LINEA_DOCUMENTO, ' +
    '       ' + SqlLineaNumerica('L.LINEA_TRSOLLIN') +
    ' AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       H.CODIGO_ALM_DESTINO_TRSOL AS ORDEN_ALMACEN, ' +
    '       L.CODIGO_ART_TRSOLLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_TRSOLLIN', 'L.CODIGO_UNIDAD_TRSOLLIN') +
    '         AS CODIGO_SKU, ' +
    '       H.CODIGO_ALM_DESTINO_TRSOL AS CODIGO_ALMACEN, ' +
    '       '''' AS LOTE, NULL AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_TRSOLLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_PEDIDA_TRSOLLIN AS CANTIDAD ' +
    '  FROM fza_traspasos_solicitudes H ' +
    '  JOIN fza_traspasos_solicitudes_lineas L ' +
    '    ON L.SERIE_TRSOL_TRSOLLIN = H.SERIE_TRSOL ' +
    '   AND L.NUMERO_TRSOL_TRSOLLIN = H.NUMERO_TRSOL ' +
    ' WHERE H.CODIGO_EMP_TRSOL = :EMPRESA ' +
    '   AND H.SERIE_TRSOL = :SERIE AND H.NUMERO_TRSOL = :NUMERO ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_TRSOLLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_PEDIDA_TRSOLLIN, 0) <> 0';
end;

// Las unidades van al almacén de destino de la propuesta. La empresa es la
// del almacén de origen; lo trasladado cuenta por lo realmente traspasado.
function SqlLineasPropuestaTraspasoBase: string;
begin
  Result :=
    'SELECT AO.CODIGO_EMP_ALM AS EMPRESA_DOCUMENTO, ' +
    '       ''PT'' AS TIPO_DOCUMENTO, ''PT'' AS SERIE_DOCUMENTO, ' +
    '       CAST(H.ID_TRPRO AS CHAR) AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''U:'', L.CODIGO_UNIDAD_TRPROLIN) AS LINEA_DOCUMENTO, ' +
    '       0 AS ORDEN_LINEA, 0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       H.CODIGO_ALM_DESTINO_TRPRO AS ORDEN_ALMACEN, ' +
    '       L.CODIGO_ART_TRPROLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_TRPROLIN', 'L.CODIGO_UNIDAD_TRPROLIN') +
    '         AS CODIGO_SKU, ' +
    '       H.CODIGO_ALM_DESTINO_TRPRO AS CODIGO_ALMACEN, ' +
    '       '''' AS LOTE, NULL AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_TRPROLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       CASE WHEN H.ESTADO_TRPRO IN (''TRASLADADO'', ' +
    '                                ''TRASLADADO PARCIAL'') ' +
    '            THEN L.CANTIDAD_TRASPASADA_TRPROLIN ' +
    '            ELSE L.CANTIDAD_TRPROLIN END AS CANTIDAD ' +
    '  FROM fza_traspasos_propuestas H ' +
    '  JOIN fza_almacenes AO ' +
    '    ON AO.CODIGO_ALM_ALM = H.CODIGO_ALM_ORIGEN_TRPRO ' +
    '  JOIN fza_traspasos_propuestas_lineas L ' +
    '    ON L.ID_TRPRO_TRPROLIN = H.ID_TRPRO ' +
    ' WHERE AO.CODIGO_EMP_ALM = :EMPRESA ' +
    '   AND :SERIE = ''PT'' ' +
    '   AND H.ID_TRPRO = CAST(:NUMERO AS UNSIGNED) ' +
    '   AND CAST(H.ID_TRPRO AS CHAR) = :NUMERO ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_TRPROLIN), '''') IS NOT NULL ' +
    '   AND CASE WHEN H.ESTADO_TRPRO IN (''TRASLADADO'', ' +
    '                                ''TRASLADADO PARCIAL'') ' +
    '            THEN L.CANTIDAD_TRASPASADA_TRPROLIN ' +
    '            ELSE L.CANTIDAD_TRPROLIN END <> 0';
end;

function SqlSkuCeldaSesion: string;
begin
  Result :=
    '(SELECT MIN(SK.CODIGO_UNIDAD_SKU) ' +
    '   FROM fza_articulos_skus SK ' +
    '  WHERE SK.CODIGO_ART_SKU = CASE ' +
    '          WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    '          THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    '          ELSE L.CODIGO_ART_TENTATIVO_SESLIN END ' +
    '    AND SK.ESACTIVO_SKU = ''S'' ' +
    '    AND EXISTS (SELECT 1 FROM fza_atributos_sku SP ' +
    '          WHERE SP.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '            AND SP.ID_AV_SA = C.ID_AV_PIVOT_SESCEL) ' +
    '    AND NOT EXISTS (SELECT 1 ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL ' +
    '           AND NOT EXISTS (SELECT 1 FROM fza_atributos_sku SF ' +
    '                 WHERE SF.CODIGO_UNIDAD_SKU_SA = ' +
    '                       SK.CODIGO_UNIDAD_SKU ' +
    '                   AND SF.ID_AV_SA = FA.ID_AV_SESFILAT)) ' +
    ' HAVING COUNT(*) = 1)';
end;

function SqlLineasSesionCompraBase: string;
var
  Articulo: string;
begin
  Articulo :=
    'CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    'THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    'ELSE L.CODIGO_ART_TENTATIVO_SESLIN END';
  Result :=
    'SELECT H.CODIGO_EMP_SES AS EMPRESA_DOCUMENTO, ' +
    '       ''SE'' AS TIPO_DOCUMENTO, H.SERIE_SES AS SERIE_DOCUMENTO, ' +
    '       H.NUMERO_SES AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_SESLIN) AS LINEA_DOCUMENTO, ' +
    '       L.LINEA_SESLIN AS ORDEN_LINEA, 0 AS ORDEN_FILA, ' +
    '       0 AS ORDEN_PIVOTE, H.CODIGO_ALM_SES AS ORDEN_ALMACEN, ' +
    '       ' + Articulo + ' AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(Articulo, '''''') + ' AS CODIGO_SKU, ' +
    '       COALESCE(H.CODIGO_ALM_SES, '''') AS CODIGO_ALMACEN, ' +
    '       '''' AS LOTE, NULL AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_SESLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_ESCALAR_SESLIN AS CANTIDAD ' +
    '  FROM fza_compras_sesiones H ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = H.SERIE_SES ' +
    '   AND L.NUMERO_SES_SESLIN = H.NUMERO_SES ' +
    ' WHERE H.CODIGO_EMP_SES = :EMPRESA ' +
    '   AND H.SERIE_SES = :SERIE AND H.NUMERO_SES = :NUMERO ' +
    '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    '   AND NULLIF(TRIM(' + Articulo + '), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ESCALAR_SESLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_celdas C0 ' +
    '         WHERE C0.SERIE_SES_SESCEL = H.SERIE_SES ' +
    '           AND C0.NUMERO_SES_SESCEL = H.NUMERO_SES ' +
    '           AND C0.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
    '           AND C0.CANTIDAD_SESCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_SES, ''SE'', H.SERIE_SES, H.NUMERO_SES, ' +
    '       CONCAT(''C:'', L.LINEA_SESLIN, '':'', ' +
    '              C.ID_FILA_SES_SESCEL, '':'', ' +
    '              C.ID_AV_PIVOT_SESCEL, '':'', ' +
    '              COALESCE(C.CODIGO_ALM_SESCEL, '''')), ' +
    '       L.LINEA_SESLIN, C.ID_FILA_SES_SESCEL, ' +
    '       C.ID_AV_PIVOT_SESCEL, C.CODIGO_ALM_SESCEL, ' +
    '       ' + Articulo + ', ' + SqlSkuCeldaSesion + ', ' +
    '       COALESCE(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '                H.CODIGO_ALM_SES, ''''), ' +
    '       '''', NULL, COALESCE(L.DESCRIPCION_SESLIN, ''''), ' +
    '       C.CANTIDAD_SESCEL ' +
    '  FROM fza_compras_sesiones H ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = H.SERIE_SES ' +
    '   AND L.NUMERO_SES_SESLIN = H.NUMERO_SES ' +
    '  JOIN fza_compras_sesiones_celdas C ' +
    '    ON C.SERIE_SES_SESCEL = H.SERIE_SES ' +
    '   AND C.NUMERO_SES_SESCEL = H.NUMERO_SES ' +
    '   AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
    ' WHERE H.CODIGO_EMP_SES = :EMPRESA ' +
    '   AND H.SERIE_SES = :SERIE AND H.NUMERO_SES = :NUMERO ' +
    '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    '   AND NULLIF(TRIM(' + Articulo + '), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_SESCEL <> 0';
end;

function SqlClaveInventario: string;
begin
  Result :=
    'LEFT(SHA2(CONCAT_WS(CHAR(31), H.SERIE_INV, H.NUMERO_INV), ' +
    '256), 20)';
end;

function SqlLineasInventarioBase: string;
begin
  Result :=
    'SELECT H.CODIGO_EMP_INV AS EMPRESA_DOCUMENTO, ' +
    '       ''IN'' AS TIPO_DOCUMENTO, ' +
    '       H.CODIGO_ALM_INV AS SERIE_DOCUMENTO, ' +
    '       ' + SqlClaveInventario + ' AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.LINEA_INVLIN) AS LINEA_DOCUMENTO, ' +
    '       ' + SqlLineaNumerica('L.LINEA_INVLIN') +
    ' AS ORDEN_LINEA, ' +
    '       0 AS ORDEN_FILA, 0 AS ORDEN_PIVOTE, ' +
    '       H.CODIGO_ALM_INV AS ORDEN_ALMACEN, ' +
    '       L.CODIGO_ART_INVLIN AS CODIGO_ARTICULO, ' +
    '       ' + SqlSkuDirecto(
      'L.CODIGO_ART_INVLIN', 'L.CODIGO_UNIDAD_INVLIN') +
    '         AS CODIGO_SKU, ' +
    '       H.CODIGO_ALM_INV AS CODIGO_ALMACEN, ' +
    '       COALESCE(L.LOTE_INVLIN, '''') AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_INVLIN AS FECHA_CADUCIDAD, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_INVLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO, ' +
    '       L.CANTIDAD_FISICA_INVLIN AS CANTIDAD ' +
    '  FROM fza_inventarios H ' +
    '  JOIN fza_inventarios_lineas L ' +
    '    ON L.CODIGO_EMP_INVLIN = H.CODIGO_EMP_INV ' +
    '   AND L.CODIGO_ALM_INVLIN = H.CODIGO_ALM_INV ' +
    '   AND L.SERIE_INV_INVLIN = H.SERIE_INV ' +
    '   AND L.NUMERO_INV_INVLIN = H.NUMERO_INV ' +
    ' WHERE H.CODIGO_EMP_INV = :EMPRESA ' +
    '   AND H.CODIGO_ALM_INV = :SERIE ' +
    '   AND ' + SqlClaveInventario + ' = :NUMERO ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_INVLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_FISICA_INVLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_inventarios_celdas C ' +
    '         WHERE C.CODIGO_EMP_INVCEL = H.CODIGO_EMP_INV ' +
    '           AND C.CODIGO_ALM_INV_INVCEL = H.CODIGO_ALM_INV ' +
    '           AND C.SERIE_INV_INVCEL = H.SERIE_INV ' +
    '           AND C.NUMERO_INV_INVCEL = H.NUMERO_INV ' +
    '           AND ' + SqlLineaNumerica('C.LINEA_INVCEL') + ' = ' +
    SqlLineaNumerica('L.LINEA_INVLIN') + ' ' +
    '           AND C.CANTIDAD_INVCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT H.CODIGO_EMP_INV, ''IN'', H.CODIGO_ALM_INV, ' +
    '       ' + SqlClaveInventario + ', ' +
    '       CONCAT(''C:'', L.LINEA_INVLIN, '':'', ' +
    '              C.ID_FILA_INVCEL, '':'', C.ID_AV_PIVOT_INVCEL, ' +
    '              '':'', COALESCE(C.CODIGO_ALM_INVCEL, '''')), ' +
    '       ' + SqlLineaNumerica('L.LINEA_INVLIN') +
    ', C.ID_FILA_INVCEL, ' +
    '       C.ID_AV_PIVOT_INVCEL, C.CODIGO_ALM_INVCEL, ' +
    '       L.CODIGO_ART_INVLIN, ' +
    '       ' + SqlSkuCelda('L.CODIGO_ART_INVLIN',
      'L.CODIGO_UNIDAD_INVLIN', 'C.ID_AV_PIVOT_INVCEL') + ', ' +
    '       H.CODIGO_ALM_INV, COALESCE(L.LOTE_INVLIN, ''''), ' +
    '       L.FECHA_CADUCIDAD_INVLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_INVLIN, ''''), ' +
    '       C.CANTIDAD_INVCEL ' +
    '  FROM fza_inventarios H ' +
    '  JOIN fza_inventarios_lineas L ' +
    '    ON L.CODIGO_EMP_INVLIN = H.CODIGO_EMP_INV ' +
    '   AND L.CODIGO_ALM_INVLIN = H.CODIGO_ALM_INV ' +
    '   AND L.SERIE_INV_INVLIN = H.SERIE_INV ' +
    '   AND L.NUMERO_INV_INVLIN = H.NUMERO_INV ' +
    '  JOIN fza_inventarios_celdas C ' +
    '    ON C.CODIGO_EMP_INVCEL = H.CODIGO_EMP_INV ' +
    '   AND C.CODIGO_ALM_INV_INVCEL = H.CODIGO_ALM_INV ' +
    '   AND C.SERIE_INV_INVCEL = H.SERIE_INV ' +
    '   AND C.NUMERO_INV_INVCEL = H.NUMERO_INV ' +
    '   AND ' + SqlLineaNumerica('C.LINEA_INVCEL') + ' = ' +
    SqlLineaNumerica('L.LINEA_INVLIN') + ' ' +
    ' WHERE H.CODIGO_EMP_INV = :EMPRESA ' +
    '   AND H.CODIGO_ALM_INV = :SERIE ' +
    '   AND ' + SqlClaveInventario + ' = :NUMERO ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_INVLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_INVCEL <> 0';
end;

function SqlLineasSesionTarifasBase: string;
begin
  Result :=
    'SELECT :EMPRESA AS EMPRESA_DOCUMENTO, ' +
    '       ''TARC'' AS TIPO_DOCUMENTO, ' +
    '       CAST(H.CODIGO_TARC AS CHAR) AS SERIE_DOCUMENTO, ' +
    '       CAST(H.CODIGO_TARC AS CHAR) AS NUMERO_DOCUMENTO, ' +
    '       CONCAT(''L:'', L.ID_TARCLIN, '':'', ' +
    '              SK.CODIGO_UNIDAD_SKU) AS LINEA_DOCUMENTO, ' +
    '       L.ID_TARCLIN AS ORDEN_LINEA, 0 AS ORDEN_FILA, ' +
    '       0 AS ORDEN_PIVOTE, '''' AS ORDEN_ALMACEN, ' +
    '       L.CODIGO_ART_TARCLIN AS CODIGO_ARTICULO, ' +
    '       SK.CODIGO_UNIDAD_SKU AS CODIGO_SKU, ' +
    '       '''' AS CODIGO_ALMACEN, '''' AS LOTE, ' +
    '       NULL AS FECHA_CADUCIDAD, A.DESCRIPCION_ART AS ' +
    '         DESCRIPCION_ARTICULO, 0 AS CANTIDAD ' +
    '  FROM fza_tarifas_cambios H ' +
    '  JOIN fza_tarifas_cambios_lineas L ' +
    '    ON L.CODIGO_TARC_TARCLIN = H.CODIGO_TARC ' +
    '  JOIN fza_articulos_skus SK ' +
    '    ON SK.CODIGO_ART_SKU = L.CODIGO_ART_TARCLIN ' +
    '   AND SK.ESACTIVO_SKU = ''S'' ' +
    '   AND (NULLIF(TRIM(L.CODIGO_UNIDAD_SKU_TARCLIN), '''') IS NULL ' +
    '        OR SK.CODIGO_UNIDAD_SKU = L.CODIGO_UNIDAD_SKU_TARCLIN) ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TARCLIN ' +
    ' WHERE H.CODIGO_TARC = CAST(:SERIE AS UNSIGNED) ' +
    '   AND CAST(H.CODIGO_TARC AS CHAR) = :NUMERO';
end;

function SqlLineasPedidoVenta: string;
begin
  Result := SqlLineasElegibles(SqlLineasPedidoVentaBase(
    'H.CODIGO_EMP_PED = :EMPRESA AND H.SERIE_PED = :SERIE ' +
    'AND H.NUMERO_PED = :NUMERO'));
end;

function SqlLineasPresupuestoVenta: string;
begin
  Result := SqlLineasElegibles(SqlLineasPresupuestoVentaBase(
    'H.CODIGO_EMP_PRE = :EMPRESA AND H.SERIE_PRE = :SERIE ' +
    'AND H.NUMERO_PRE = :NUMERO'));
end;

function SqlLineasPedidoCompra: string;
begin
  Result := SqlLineasElegibles(SqlLineasPedidoCompraBase(
    'H.CODIGO_EMP_PEDC = :EMPRESA AND H.SERIE_PEDC = :SERIE ' +
    'AND H.NUMERO_PEDC = :NUMERO'));
end;

function SqlLineasFacturaVenta: string;
begin
  Result := SqlLineasElegibles(SqlLineasFacturaVentaBase(
    'H.CODIGO_EMP_FAC = :EMPRESA AND H.SERIE_FAC = :SERIE ' +
    'AND H.NUMERO_FAC = :NUMERO'));
end;

function SqlLineasFacturaCompra: string;
begin
  Result := SqlLineasElegibles(SqlLineasFacturaCompraBase(
    'H.CODIGO_EMP_FACC = :EMPRESA AND H.SERIE_FACC = :SERIE ' +
    'AND H.NUMERO_FACC = :NUMERO'));
end;

function SqlLineasDevolucionCompra: string;
begin
  Result := SqlLineasElegibles(SqlLineasDevolucionCompraBase(
    'H.CODIGO_EMP_DEVC = :EMPRESA AND H.SERIE_DEVC = :SERIE ' +
    'AND H.NUMERO_DEVC = :NUMERO'));
end;

function SqlLineasResueltasPedidoVenta: string;
begin
  Result := SqlLineasResueltas(SqlLineasPedidoVentaBase(
    'H.CODIGO_EMP_PED = :EMPRESA AND H.SERIE_PED = :SERIE ' +
    'AND H.NUMERO_PED = :NUMERO'));
end;

function SqlLineasResueltasPresupuestoVenta: string;
begin
  Result := SqlLineasResueltas(SqlLineasPresupuestoVentaBase(
    'H.CODIGO_EMP_PRE = :EMPRESA AND H.SERIE_PRE = :SERIE ' +
    'AND H.NUMERO_PRE = :NUMERO'));
end;

function SqlLineasResueltasPedidoCompra: string;
begin
  Result := SqlLineasResueltas(SqlLineasPedidoCompraBase(
    'H.CODIGO_EMP_PEDC = :EMPRESA AND H.SERIE_PEDC = :SERIE ' +
    'AND H.NUMERO_PEDC = :NUMERO'));
end;

function SqlLineasResueltasFacturaVenta: string;
begin
  Result := SqlLineasResueltas(SqlLineasFacturaVentaBase(
    'H.CODIGO_EMP_FAC = :EMPRESA AND H.SERIE_FAC = :SERIE ' +
    'AND H.NUMERO_FAC = :NUMERO'));
end;

function SqlLineasResueltasFacturaCompra: string;
begin
  Result := SqlLineasResueltas(SqlLineasFacturaCompraBase(
    'H.CODIGO_EMP_FACC = :EMPRESA AND H.SERIE_FACC = :SERIE ' +
    'AND H.NUMERO_FACC = :NUMERO'));
end;

function SqlLineasResueltasDevolucionCompra: string;
begin
  Result := SqlLineasResueltas(SqlLineasDevolucionCompraBase(
    'H.CODIGO_EMP_DEVC = :EMPRESA AND H.SERIE_DEVC = :SERIE ' +
    'AND H.NUMERO_DEVC = :NUMERO'));
end;

function SqlLineasElegiblesBase(const ASql: string): string;
begin
  Result := SqlLineasElegibles(ASql);
end;

function SqlLineasResueltasBase(const ASql: string): string;
begin
  Result := SqlLineasResueltas(ASql);
end;

function SqlInstanteOrden(const ACampoInstante,
  ACampoFecha: string): string;
begin
  Result :=
    'CASE WHEN ' + ACampoInstante + ' IS NULL ' +
    'OR ' + ACampoInstante + ' < ''1000-01-01 00:00:00'' ' +
    'THEN CAST(' + ACampoFecha + ' AS DATETIME) ' +
    'ELSE ' + ACampoInstante + ' END';
end;

procedure SqlTotalesCabeceraConCeldas(const ATablaLineas,
  ACampoSerieLineas, ACampoNumeroLineas, ACampoArticulo,
  AExpresionCantidad, ATablaCeldas, ACampoSerieCeldas,
  ACampoNumeroCeldas, ACampoLineaLineas, ACampoLineaCeldas,
  ACampoCantidadCeldas, AExpresionSerieCabecera,
  AExpresionNumeroCabecera, ACondicionAdicional: string;
  out ALineas, AUnidades: string);
var
  ExisteCeldas: string;
  FiltroCeldas: string;
  FiltroLineas: string;
begin
  FiltroLineas :=
    'L.' + ACampoSerieLineas + ' = ' + AExpresionSerieCabecera + ' ' +
    'AND L.' + ACampoNumeroLineas + ' = ' + AExpresionNumeroCabecera + ' ' +
    'AND NULLIF(TRIM(L.' + ACampoArticulo + '), '''') IS NOT NULL';
  if Trim(ACondicionAdicional) <> '' then
  begin
    FiltroLineas := FiltroLineas + ' AND ' + ACondicionAdicional;
  end;
  if Trim(ATablaCeldas) = '' then
  begin
    ALineas :=
      '(SELECT COALESCE(SUM(CASE WHEN COALESCE(' +
      AExpresionCantidad + ', 0) <> 0 THEN 1 ELSE 0 END), 0) ' +
      '   FROM ' + ATablaLineas + ' L WHERE ' + FiltroLineas + ')';
    AUnidades :=
      '(SELECT COALESCE(SUM(CASE WHEN COALESCE(' +
      AExpresionCantidad + ', 0) <> 0 THEN ' + AExpresionCantidad +
      ' ELSE 0 END), 0) FROM ' + ATablaLineas + ' L WHERE ' +
      FiltroLineas + ')';
  end
  else
  begin
    FiltroCeldas :=
      'C.' + ACampoSerieCeldas + ' = L.' + ACampoSerieLineas + ' ' +
      'AND C.' + ACampoNumeroCeldas + ' = L.' +
      ACampoNumeroLineas + ' AND ' +
      SqlLineaNumerica('C.' + ACampoLineaCeldas) + ' = ' +
      SqlLineaNumerica('L.' + ACampoLineaLineas) + ' AND C.' +
      ACampoCantidadCeldas + ' <> 0';
    ExisteCeldas :=
      'EXISTS (SELECT 1 FROM ' + ATablaCeldas + ' C WHERE ' +
      FiltroCeldas + ')';
    ALineas :=
      '(SELECT COALESCE(SUM(CASE WHEN ' + ExisteCeldas + ' THEN ' +
      '(SELECT COUNT(*) FROM ' + ATablaCeldas + ' C WHERE ' +
      FiltroCeldas + ') WHEN COALESCE(' + AExpresionCantidad +
      ', 0) <> 0 THEN 1 ELSE 0 END), 0) FROM ' + ATablaLineas +
      ' L WHERE ' + FiltroLineas + ')';
    AUnidades :=
      '(SELECT COALESCE(SUM(CASE WHEN ' + ExisteCeldas + ' THEN ' +
      '(SELECT COALESCE(SUM(C.' + ACampoCantidadCeldas + '), 0) ' +
      'FROM ' + ATablaCeldas + ' C WHERE ' + FiltroCeldas + ') ' +
      'WHEN COALESCE(' + AExpresionCantidad + ', 0) <> 0 THEN ' +
      AExpresionCantidad + ' ELSE 0 END), 0) FROM ' +
      ATablaLineas + ' L WHERE ' + FiltroLineas + ')';
  end;
end;

function SqlRamaCabecera(const AAlias, ATipoDocumento,
  ATablaCabecera, AExpresionEmpresa,
  AExpresionSerie, AExpresionNumero, AExpresionSerieOrigen,
  AExpresionNumeroOrigen, AExpresionFecha, AExpresionInstante,
  AExpresionEstado, AExpresionTercero, AExpresionLineas,
  AExpresionUnidades, ACondicionEmpresa, AParametroLimite: string): string;
begin
  Result :=
    'SELECT ' + AAlias + '.* FROM (SELECT ' +
    '''' + ATipoDocumento + ''' AS TIPO_DOCUMENTO, ' +
    QuotedStr(DescripcionTipoDocumentoOrigen(ATipoDocumento)) +
    ' AS TIPO_DESCRIPCION, ' +
    AExpresionEmpresa + ' AS EMPRESA_DOCUMENTO, ' +
    AExpresionSerie + ' AS SERIE, ' +
    AExpresionNumero + ' AS NUMERO, ' +
    AExpresionSerieOrigen + ' AS SERIE_ORIGEN, ' +
    AExpresionNumeroOrigen + ' AS NUMERO_ORIGEN, ' +
    AExpresionFecha + ' AS FECHA, ' +
    AExpresionInstante + ' AS INSTANTE_ALTA, ' +
    AExpresionEstado + ' AS ESTADO, ' +
    AExpresionTercero + ' AS TERCERO, ' +
    AExpresionLineas + ' AS NUMERO_LINEAS, ' +
    AExpresionUnidades + ' AS TOTAL_UNIDADES ' +
    '  FROM ' + ATablaCabecera + ' H ' +
    ' WHERE (:TIPO_FILTRO = '''' OR ' +
    '        :TIPO_FILTRO = ''' + ATipoDocumento + ''') ' +
    '   AND ' + ACondicionEmpresa + ' ' +
    ' ORDER BY ' + SqlInstanteOrden(
      AExpresionInstante, AExpresionFecha) + ' DESC, ' +
    '          ' + AExpresionSerie + ', ' + AExpresionNumero + ' ' +
    ' LIMIT :' + AParametroLimite + ') ' + AAlias;
end;

function SqlCabecerasAlbaranesPedidos: string;
var
  Lineas: string;
  Unidades: string;
begin
  SqlTotalesCabeceraConCeldas('fza_albaranes_lineas',
    'SERIE_ALB_ALBLIN', 'NUMERO_ALB_ALBLIN', 'CODIGO_ART_ALBLIN',
    'L.CANTIDAD_ALBLIN', 'fza_albaranes_celdas',
    'SERIE_ALB_ALBCEL', 'NUMERO_ALB_ALBCEL', 'LINEA_ALBLIN',
    'LINEA_ALBCEL', 'CANTIDAD_ALBCEL', 'H.SERIE_ALB',
    'H.NUMERO_ALB', '', Lineas, Unidades);
  Result := SqlRamaCabecera('AV', 'AV', 'fza_albaranes',
    'H.CODIGO_EMP_ALB', 'H.SERIE_ALB',
    'H.NUMERO_ALB', 'H.SERIE_ALB', 'H.NUMERO_ALB', 'H.FECHA_ALB',
    'H.INSTANTE_ALTA', 'H.ESTADO_ALB',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_CLIENTE_ALB, ''''), ' +
    'H.CODIGO_CLI_ALB, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_ALB = :EMPRESA_AV', 'LIMITE_AV');

  SqlTotalesCabeceraConCeldas('fza_albaranes_compra_lineas',
    'SERIE_ALBC_ALBCLIN', 'NUMERO_ALBC_ALBCLIN',
    'CODIGO_ART_ALBCLIN', 'L.CANTIDAD_ALBCLIN',
    'fza_albaranes_compra_celdas', 'SERIE_ALBC_ALBCCEL',
    'NUMERO_ALBC_ALBCCEL', 'LINEA_ALBCLIN', 'LINEA_ALBC_ALBCCEL',
    'CANTIDAD_ALBCCEL', 'H.SERIE_ALBC', 'H.NUMERO_ALBC',
    '', Lineas, Unidades);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('AB', 'AB',
    'fza_albaranes_compra',
    'H.CODIGO_EMP_ALBC', 'H.SERIE_ALBC', 'H.NUMERO_ALBC',
    'H.SERIE_ALBC', 'H.NUMERO_ALBC', 'H.FECHA_ALBC',
    'H.INSTANTE_ALTA', 'H.ESTADO_ALBC',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_PRV_ALBC, ''''), ' +
    'H.CODIGO_PRV_ALBC, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_ALBC = :EMPRESA_AB', 'LIMITE_AB');

  SqlTotalesCabeceraConCeldas('fza_pedidos_lineas',
    'SERIE_PED_PEDLIN', 'NUMERO_PED_PEDLIN', 'CODIGO_ART_PEDLIN',
    'L.CANTIDAD_PEDLIN', 'fza_pedidos_celdas',
    'SERIE_PED_PEDCEL', 'NUMERO_PED_PEDCEL', 'LINEA_PEDLIN',
    'LINEA_PEDCEL', 'CANTIDAD_PEDCEL', 'H.SERIE_PED',
    'H.NUMERO_PED', '', Lineas, Unidades);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('PE', 'PE',
    'fza_pedidos', 'H.CODIGO_EMP_PED',
    'H.SERIE_PED', 'H.NUMERO_PED', 'H.SERIE_PED', 'H.NUMERO_PED',
    'H.FECHA_PED', 'H.INSTANTE_ALTA', 'H.ESTADO_PED',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_CLIENTE_FISCAL_PED, ''''), ' +
    'H.CODIGO_CLI_PED, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_PED = :EMPRESA_PE', 'LIMITE_PE');

  SqlTotalesCabeceraConCeldas('fza_pedidos_compra_lineas',
    'SERIE_PEDC_PEDCLIN', 'NUMERO_PEDC_PEDCLIN',
    'CODIGO_ART_PEDCLIN', 'L.CANTIDAD_PEDCLIN',
    'fza_pedidos_compra_celdas', 'SERIE_PEDC_PEDCCEL',
    'NUMERO_PEDC_PEDCCEL', 'LINEA_PEDCLIN', 'LINEA_PEDC_PEDCCEL',
    'CANTIDAD_PEDCCEL', 'H.SERIE_PEDC', 'H.NUMERO_PEDC',
    '', Lineas, Unidades);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('PC', 'PC',
    'fza_pedidos_compra', 'H.CODIGO_EMP_PEDC',
    'H.SERIE_PEDC', 'H.NUMERO_PEDC', 'H.SERIE_PEDC', 'H.NUMERO_PEDC',
    'H.FECHA_PEDC', 'H.INSTANTE_ALTA', 'H.ESTADO_PEDC',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_PRV_PEDC, ''''), ' +
    'H.CODIGO_PRV_PEDC, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_PEDC = :EMPRESA_PC', 'LIMITE_PC');

  SqlTotalesCabeceraConCeldas('fza_presupuestos_lineas',
    'SERIE_PRE_PRELIN', 'NUMERO_PRE_PRELIN', 'CODIGO_ART_PRELIN',
    'L.CANTIDAD_PRELIN', 'fza_presupuestos_celdas',
    'SERIE_PRE_PRECEL', 'NUMERO_PRE_PRECEL', 'LINEA_PRELIN',
    'LINEA_PRECEL', 'CANTIDAD_PRECEL', 'H.SERIE_PRE',
    'H.NUMERO_PRE', '', Lineas, Unidades);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('PR', 'PR',
    'fza_presupuestos', 'H.CODIGO_EMP_PRE',
    'H.SERIE_PRE', 'H.NUMERO_PRE', 'H.SERIE_PRE', 'H.NUMERO_PRE',
    'H.FECHA_PRE', 'H.INSTANTE_ALTA', 'H.ESTADO_PRE',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_CLIENTE_PRE, ''''), ' +
    'H.CODIGO_CLI_PRE, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_PRE = :EMPRESA_PR', 'LIMITE_PR');
end;

function SqlCabecerasFacturas: string;
var
  Lineas: string;
  Unidades: string;
begin
  SqlTotalesCabeceraConCeldas('fza_facturas_lineas',
    'SERIE_FAC_FACLIN', 'NUMERO_FAC_FACLIN', 'CODIGO_ART_FACLIN',
    'L.CANTIDAD_FACLIN', '', '', '', 'LINEA_FACLIN', '', '',
    'H.SERIE_FAC', 'H.NUMERO_FAC',
    SqlCondicionArticuloFacturaCargable('L'),
    Lineas, Unidades);
  Result := SqlRamaCabecera('FC', 'FC',
    'fza_facturas', 'H.CODIGO_EMP_FAC',
    'H.SERIE_FAC', 'H.NUMERO_FAC', 'H.SERIE_FAC', 'H.NUMERO_FAC',
    'H.FECHA_FAC', 'H.INSTANTE_ALTA', 'H.FASE_FAC',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_CLIENTE_FAC, ''''), ' +
    'H.CODIGO_CLI_FAC, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_FAC = :EMPRESA_FC', 'LIMITE_FC');

  SqlTotalesCabeceraConCeldas('fza_facturas_compra_lineas',
    'SERIE_FACC_FACCLIN', 'NUMERO_FACC_FACCLIN',
    'CODIGO_ART_FACCLIN', 'L.CANTIDAD_FACCLIN',
    'fza_facturas_compra_celdas', 'SERIE_FACC_FACCCEL',
    'NUMERO_FACC_FACCCEL', 'LINEA_FACCLIN', 'LINEA_FACC_FACCCEL',
    'CANTIDAD_FACCCEL', 'H.SERIE_FACC', 'H.NUMERO_FACC',
    '', Lineas, Unidades);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('FP', 'FP',
    'fza_facturas_compra', 'H.CODIGO_EMP_FACC',
    'H.SERIE_FACC', 'H.NUMERO_FACC', 'H.SERIE_FACC', 'H.NUMERO_FACC',
    'H.FECHA_FACC', 'H.INSTANTE_ALTA', 'H.ESTADO_FACC',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_PRV_FACC, ''''), ' +
    'H.CODIGO_PRV_FACC, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_FACC = :EMPRESA_FP', 'LIMITE_FP');

  SqlTotalesCabeceraConCeldas('fza_devoluciones_compra_lineas',
    'SERIE_DEVC_DEVCLIN', 'NUMERO_DEVC_DEVCLIN',
    'CODIGO_ART_DEVCLIN', 'L.CANTIDAD_DEVCLIN',
    'fza_devoluciones_compra_celdas', 'SERIE_DEVC_DEVCCEL',
    'NUMERO_DEVC_DEVCCEL', 'LINEA_DEVCLIN', 'LINEA_DEVC_DEVCCEL',
    'CANTIDAD_DEVCCEL', 'H.SERIE_DEVC', 'H.NUMERO_DEVC',
    '', Lineas, Unidades);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('DC', 'DC',
    'fza_devoluciones_compra',
    'H.CODIGO_EMP_DEVC', 'H.SERIE_DEVC', 'H.NUMERO_DEVC',
    'H.SERIE_DEVC', 'H.NUMERO_DEVC', 'H.FECHA_DEVC',
    'H.INSTANTE_ALTA', 'H.ESTADO_DEVC',
    'COALESCE(NULLIF(H.RAZON_SOCIAL_PRV_DEVC, ''''), ' +
    'H.CODIGO_PRV_DEVC, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_DEVC = :EMPRESA_DC', 'LIMITE_DC');
end;

function SqlCabecerasOperacionesCaja: string;
var
  Lineas: string;
  Unidades: string;
begin
  Lineas :=
    '(SELECT CASE WHEN EXISTS (SELECT 1 FROM fza_facturas_lineas F ' +
    'WHERE F.SERIE_FAC_FACLIN = H.SERIE_FAC_OPCAJA AND ' +
    'F.NUMERO_FAC_FACLIN = H.NUMERO_FAC_OPCAJA AND ' +
    SqlCondicionLineaFacturaVenta('F') + ') THEN ' +
    '(SELECT COUNT(*) FROM fza_facturas_lineas F WHERE ' +
    'F.SERIE_FAC_FACLIN = H.SERIE_FAC_OPCAJA AND ' +
    'F.NUMERO_FAC_FACLIN = H.NUMERO_FAC_OPCAJA AND ' +
    SqlCondicionLineaFacturaVenta('F') + ') ELSE ' +
    '(SELECT COUNT(*) FROM fza_movimientos_almacen M WHERE ' +
    'M.CODIGO_EMP_MOV = H.CODIGO_EMP_OPCAJA AND ' +
    'M.CODIGO_ALM_DOC_MOV = H.CODIGO_ALM_OPCAJA AND ' +
    'M.CODIGO_CAJA_DOC_MOV = H.CODIGO_CAJA_OPCAJA AND ' +
    'M.NUMERO_OPERACION_DOC_MOV = H.NUMERO_OPERACION_OPCAJA AND ' +
    'M.TIPO_DOC_MOV = ''VE'' AND M.TIPO_MOV = ''S'' AND ' +
    'M.ESACTIVO_MOV = ''S'' AND ' +
    SqlCondicionMovimientoVenta('M') + ') END)';
  Unidades :=
    '(SELECT CASE WHEN EXISTS (SELECT 1 FROM fza_facturas_lineas F ' +
    'WHERE F.SERIE_FAC_FACLIN = H.SERIE_FAC_OPCAJA AND ' +
    'F.NUMERO_FAC_FACLIN = H.NUMERO_FAC_OPCAJA AND ' +
    SqlCondicionLineaFacturaVenta('F') + ') THEN ' +
    '(SELECT COALESCE(SUM(F.CANTIDAD_FACLIN), 0) FROM ' +
    'fza_facturas_lineas F WHERE F.SERIE_FAC_FACLIN = ' +
    'H.SERIE_FAC_OPCAJA AND F.NUMERO_FAC_FACLIN = ' +
    'H.NUMERO_FAC_OPCAJA AND ' +
    SqlCondicionLineaFacturaVenta('F') + ') ' +
    'ELSE (SELECT COALESCE(' +
    'SUM(M.CANTIDAD_MOV), 0) FROM fza_movimientos_almacen M WHERE ' +
    'M.CODIGO_EMP_MOV = H.CODIGO_EMP_OPCAJA AND ' +
    'M.CODIGO_ALM_DOC_MOV = H.CODIGO_ALM_OPCAJA AND ' +
    'M.CODIGO_CAJA_DOC_MOV = H.CODIGO_CAJA_OPCAJA AND ' +
    'M.NUMERO_OPERACION_DOC_MOV = H.NUMERO_OPERACION_OPCAJA AND ' +
    'M.TIPO_DOC_MOV = ''VE'' AND M.TIPO_MOV = ''S'' AND ' +
    'M.ESACTIVO_MOV = ''S'' AND ' +
    SqlCondicionMovimientoVenta('M') + ') END)';
  Result := SqlRamaCabecera('VE', 'VE',
    'fza_caja_operaciones', 'H.CODIGO_EMP_OPCAJA',
    'COALESCE(NULLIF(H.SERIE_FAC_OPCAJA, ''''), ' +
    'H.CODIGO_CAJA_OPCAJA)',
    'COALESCE(NULLIF(H.NUMERO_FAC_OPCAJA, ''''), ' +
    'H.NUMERO_OPERACION_OPCAJA)', 'CAST(H.ID_OPCAJA AS CHAR)',
    'CAST(H.ID_OPCAJA AS CHAR)', 'H.FECHA_OPERACION_OPCAJA',
    'H.INSTANTE_ALTA', '''GRABADA''',
    'COALESCE(H.CODIGO_CLI_OPCAJA, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_OPCAJA = :EMPRESA_VE AND ' +
    'H.TIPO_OPERACION_OPCAJA = ''VE''', 'LIMITE_VE');

  Lineas :=
    '(SELECT COUNT(*) FROM fza_movimientos_almacen M WHERE ' +
    'M.CODIGO_EMP_MOV = H.CODIGO_EMP_OPCAJA AND ' +
    'M.CODIGO_ALM_DOC_MOV = H.CODIGO_ALM_OPCAJA AND ' +
    'M.CODIGO_CAJA_DOC_MOV = H.CODIGO_CAJA_OPCAJA AND ' +
    'M.NUMERO_OPERACION_DOC_MOV = H.NUMERO_OPERACION_OPCAJA AND ' +
    'M.TIPO_DOC_MOV IN (''TR'', ''TA'', ''AT'') AND ' +
    'M.TIPO_MOV = ''S'' AND M.ESACTIVO_MOV = ''S'')';
  Unidades := StringReplace(Lineas, 'COUNT(*)',
    'COALESCE(SUM(M.CANTIDAD_MOV), 0)', []);
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('TR', 'TR',
    'fza_caja_operaciones', 'H.CODIGO_EMP_OPCAJA',
    'COALESCE(H.SERIE_FAC_OPCAJA, '''')',
    'COALESCE(H.NUMERO_FAC_OPCAJA, H.NUMERO_OPERACION_OPCAJA)',
    'CAST(H.ID_OPCAJA AS CHAR)', 'CAST(H.ID_OPCAJA AS CHAR)',
    'H.FECHA_OPERACION_OPCAJA', 'H.INSTANTE_ALTA', '''GRABADO''',
    'CONCAT(COALESCE(H.CODIGO_EMP_CONTRA_OPCAJA, ''''), '' / '', ' +
    'COALESCE(H.CODIGO_ALM_CONTRA_OPCAJA, ''''))', Lineas, Unidades,
    'H.CODIGO_EMP_OPCAJA = :EMPRESA_TR AND ' +
    'H.TIPO_OPERACION_OPCAJA IN (''TR'', ''TA'', ''AT'')', 'LIMITE_TR');
end;

function SqlCabecerasTraspasosSesiones: string;
var
  Lineas: string;
  Unidades: string;
begin
  Lineas :=
    '(SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L ' +
    'WHERE L.SERIE_TRSOL_TRSOLLIN = H.SERIE_TRSOL AND ' +
    'L.NUMERO_TRSOL_TRSOLLIN = H.NUMERO_TRSOL AND ' +
    'COALESCE(L.CANTIDAD_PEDIDA_TRSOLLIN, 0) <> 0)';
  Unidades := StringReplace(Lineas, 'COUNT(*)',
    'COALESCE(SUM(L.CANTIDAD_PEDIDA_TRSOLLIN), 0)', []);
  Result := SqlRamaCabecera('TS', 'TS',
    'fza_traspasos_solicitudes',
    'H.CODIGO_EMP_TRSOL', 'H.SERIE_TRSOL', 'H.NUMERO_TRSOL',
    'H.SERIE_TRSOL', 'H.NUMERO_TRSOL', 'H.FECHA_TRSOL',
    'H.INSTANTE_ALTA', 'H.ESTADO_TRSOL',
    'CONCAT(H.CODIGO_ALM_ORIGEN_TRSOL, '' / '', ' +
    'H.CODIGO_ALM_DESTINO_TRSOL)', Lineas, Unidades,
    'H.CODIGO_EMP_TRSOL = :EMPRESA_TS', 'LIMITE_TS');

  Lineas :=
    '((SELECT COUNT(*) FROM fza_compras_sesiones_lineas L ' +
    'WHERE L.SERIE_SES_SESLIN = H.SERIE_SES AND ' +
    'L.NUMERO_SES_SESLIN = H.NUMERO_SES AND ' +
    'L.TIPO_LINEA_SESLIN <> ''SERVICIO'' AND ' +
    'COALESCE(L.CANTIDAD_ESCALAR_SESLIN, 0) <> 0 AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_compras_sesiones_celdas C WHERE ' +
    'C.SERIE_SES_SESCEL = H.SERIE_SES AND ' +
    'C.NUMERO_SES_SESCEL = H.NUMERO_SES AND ' +
    'C.LINEA_SES_SESCEL = L.LINEA_SESLIN AND ' +
    'C.CANTIDAD_SESCEL <> 0)) + (SELECT COUNT(*) FROM ' +
    'fza_compras_sesiones_celdas C JOIN ' +
    'fza_compras_sesiones_lineas L ON ' +
    'L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL AND ' +
    'L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL AND ' +
    'L.LINEA_SESLIN = C.LINEA_SES_SESCEL WHERE ' +
    'C.SERIE_SES_SESCEL = H.SERIE_SES AND ' +
    'C.NUMERO_SES_SESCEL = H.NUMERO_SES AND ' +
    'L.TIPO_LINEA_SESLIN <> ''SERVICIO'' AND C.CANTIDAD_SESCEL <> 0))';
  Unidades :=
    '((SELECT COALESCE(SUM(L.CANTIDAD_ESCALAR_SESLIN), 0) FROM ' +
    'fza_compras_sesiones_lineas L WHERE ' +
    'L.SERIE_SES_SESLIN = H.SERIE_SES AND ' +
    'L.NUMERO_SES_SESLIN = H.NUMERO_SES AND ' +
    'L.TIPO_LINEA_SESLIN <> ''SERVICIO'' AND ' +
    'COALESCE(L.CANTIDAD_ESCALAR_SESLIN, 0) <> 0 AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_compras_sesiones_celdas C WHERE ' +
    'C.SERIE_SES_SESCEL = H.SERIE_SES AND ' +
    'C.NUMERO_SES_SESCEL = H.NUMERO_SES AND ' +
    'C.LINEA_SES_SESCEL = L.LINEA_SESLIN AND ' +
    'C.CANTIDAD_SESCEL <> 0)) + (SELECT COALESCE(' +
    'SUM(C.CANTIDAD_SESCEL), 0) FROM fza_compras_sesiones_celdas C ' +
    'JOIN fza_compras_sesiones_lineas L ON ' +
    'L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL AND ' +
    'L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL AND ' +
    'L.LINEA_SESLIN = C.LINEA_SES_SESCEL WHERE ' +
    'C.SERIE_SES_SESCEL = H.SERIE_SES AND ' +
    'C.NUMERO_SES_SESCEL = H.NUMERO_SES AND ' +
    'L.TIPO_LINEA_SESLIN <> ''SERVICIO'' AND ' +
    'C.CANTIDAD_SESCEL <> 0))';
  Result := Result + ' UNION ALL ' + SqlRamaCabecera('SE', 'SE',
    'fza_compras_sesiones', 'H.CODIGO_EMP_SES',
    'H.SERIE_SES', 'H.NUMERO_SES', 'H.SERIE_SES', 'H.NUMERO_SES',
    'H.FECHA_SES', 'H.INSTANTE_ALTA', 'H.ESTADO_SES',
    'COALESCE(H.CODIGO_PRV_SES, '''')', Lineas, Unidades,
    'H.CODIGO_EMP_SES = :EMPRESA_SE', 'LIMITE_SE');
end;

function SqlCabeceraInventario: string;
var
  Lineas: string;
  Unidades: string;
begin
  Lineas :=
    '(SELECT COALESCE(SUM(CASE WHEN EXISTS (SELECT 1 FROM ' +
    'fza_inventarios_celdas C WHERE C.CODIGO_EMP_INVCEL = ' +
    'H.CODIGO_EMP_INV AND C.CODIGO_ALM_INV_INVCEL = ' +
    'H.CODIGO_ALM_INV AND C.SERIE_INV_INVCEL = H.SERIE_INV AND ' +
    'C.NUMERO_INV_INVCEL = H.NUMERO_INV AND ' +
    SqlLineaNumerica('C.LINEA_INVCEL') + ' = ' +
    SqlLineaNumerica('L.LINEA_INVLIN') + ' AND ' +
    'C.CANTIDAD_INVCEL <> 0) THEN (SELECT COUNT(*) FROM ' +
    'fza_inventarios_celdas C WHERE C.CODIGO_EMP_INVCEL = ' +
    'H.CODIGO_EMP_INV AND C.CODIGO_ALM_INV_INVCEL = ' +
    'H.CODIGO_ALM_INV AND C.SERIE_INV_INVCEL = H.SERIE_INV AND ' +
    'C.NUMERO_INV_INVCEL = H.NUMERO_INV AND ' +
    SqlLineaNumerica('C.LINEA_INVCEL') + ' = ' +
    SqlLineaNumerica('L.LINEA_INVLIN') + ' AND ' +
    'C.CANTIDAD_INVCEL <> 0) WHEN ' +
    'COALESCE(L.CANTIDAD_FISICA_INVLIN, 0) <> 0 THEN 1 ELSE 0 END), 0) ' +
    'FROM fza_inventarios_lineas L WHERE L.CODIGO_EMP_INVLIN = ' +
    'H.CODIGO_EMP_INV AND L.CODIGO_ALM_INVLIN = H.CODIGO_ALM_INV AND ' +
    'L.SERIE_INV_INVLIN = H.SERIE_INV AND ' +
    'L.NUMERO_INV_INVLIN = H.NUMERO_INV)';
  Unidades :=
    '(SELECT COALESCE(SUM(CASE WHEN EXISTS (SELECT 1 FROM ' +
    'fza_inventarios_celdas C WHERE C.CODIGO_EMP_INVCEL = ' +
    'H.CODIGO_EMP_INV AND C.CODIGO_ALM_INV_INVCEL = ' +
    'H.CODIGO_ALM_INV AND C.SERIE_INV_INVCEL = H.SERIE_INV AND ' +
    'C.NUMERO_INV_INVCEL = H.NUMERO_INV AND ' +
    SqlLineaNumerica('C.LINEA_INVCEL') + ' = ' +
    SqlLineaNumerica('L.LINEA_INVLIN') + ' AND ' +
    'C.CANTIDAD_INVCEL <> 0) THEN (SELECT COALESCE(' +
    'SUM(C.CANTIDAD_INVCEL), 0) FROM fza_inventarios_celdas C WHERE ' +
    'C.CODIGO_EMP_INVCEL = H.CODIGO_EMP_INV AND ' +
    'C.CODIGO_ALM_INV_INVCEL = H.CODIGO_ALM_INV AND ' +
    'C.SERIE_INV_INVCEL = H.SERIE_INV AND ' +
    'C.NUMERO_INV_INVCEL = H.NUMERO_INV AND ' +
    SqlLineaNumerica('C.LINEA_INVCEL') + ' = ' +
    SqlLineaNumerica('L.LINEA_INVLIN') + ' AND ' +
    'C.CANTIDAD_INVCEL <> 0) WHEN ' +
    'COALESCE(L.CANTIDAD_FISICA_INVLIN, 0) <> 0 THEN ' +
    'L.CANTIDAD_FISICA_INVLIN ELSE 0 END), 0) FROM ' +
    'fza_inventarios_lineas L WHERE L.CODIGO_EMP_INVLIN = ' +
    'H.CODIGO_EMP_INV AND L.CODIGO_ALM_INVLIN = H.CODIGO_ALM_INV AND ' +
    'L.SERIE_INV_INVLIN = H.SERIE_INV AND ' +
    'L.NUMERO_INV_INVLIN = H.NUMERO_INV)';
  Result := SqlRamaCabecera('INV', 'IN',
    'fza_inventarios', 'H.CODIGO_EMP_INV',
    'H.SERIE_INV', 'H.NUMERO_INV', 'H.CODIGO_ALM_INV',
    SqlClaveInventario, 'H.FECHA_INV', 'H.INSTANTE_ALTA',
    'H.ESTADO_INV', 'COALESCE(H.DESCRIPCION_INV, H.CODIGO_ALM_INV)',
    Lineas, Unidades, 'H.CODIGO_EMP_INV = :EMPRESA_IN', 'LIMITE_IN');
end;

function SqlCabeceraTarifas: string;
var
  Lineas: string;
begin
  Lineas :=
    '(SELECT COUNT(*) FROM fza_tarifas_cambios_lineas L JOIN ' +
    'fza_articulos_skus SK ON SK.CODIGO_ART_SKU = ' +
    'L.CODIGO_ART_TARCLIN AND SK.ESACTIVO_SKU = ''S'' AND ' +
    '(NULLIF(TRIM(L.CODIGO_UNIDAD_SKU_TARCLIN), '''') IS NULL OR ' +
    'SK.CODIGO_UNIDAD_SKU = L.CODIGO_UNIDAD_SKU_TARCLIN) WHERE ' +
    'L.CODIGO_TARC_TARCLIN = H.CODIGO_TARC)';
  Result := SqlRamaCabecera('TARC', 'TARC',
    'fza_tarifas_cambios',
    ':EMPRESA_TARC',
    '''''', 'CAST(H.CODIGO_TARC AS CHAR)',
    'CAST(H.CODIGO_TARC AS CHAR)', 'CAST(H.CODIGO_TARC AS CHAR)',
    'H.FECHA_TARC',
    'H.INSTANTE_ALTA', 'H.ESTADO_TARC',
    'CONCAT(COALESCE(H.CODIGO_TAR_ORIGEN_TARC, ''''), '' / '', ' +
    'H.CODIGO_TAR_DESTINO_TARC)', Lineas, '0',
    ':EMPRESA_TARC <> ''''', 'LIMITE_TARC');
end;

function SqlExisteTablaPropuestasTraspaso: string;
begin
  Result :=
    'SELECT COUNT(*) AS EXISTE ' +
    '  FROM information_schema.TABLES ' +
    ' WHERE TABLE_SCHEMA = DATABASE() ' +
    '   AND TABLE_NAME = ''fza_traspasos_propuestas''';
end;

function SqlCabeceraPropuestasTraspaso: string;
var
  Lineas: string;
  Unidades: string;
begin
  Lineas :=
    '(SELECT COUNT(*) FROM fza_traspasos_propuestas_lineas L ' +
    'WHERE L.ID_TRPRO_TRPROLIN = H.ID_TRPRO)';
  Unidades := StringReplace(Lineas, 'COUNT(*)',
    'COALESCE(SUM(CASE WHEN H.ESTADO_TRPRO IN (''TRASLADADO'', ' +
    '''TRASLADADO PARCIAL'') ' +
    'THEN L.CANTIDAD_TRASPASADA_TRPROLIN ' +
    'ELSE L.CANTIDAD_TRPROLIN END), 0)', []);
  Result := SqlRamaCabecera('PT', 'PT',
    'fza_traspasos_propuestas',
    '(SELECT AO.CODIGO_EMP_ALM FROM fza_almacenes AO ' +
    'WHERE AO.CODIGO_ALM_ALM = H.CODIGO_ALM_ORIGEN_TRPRO)',
    '''PT''', 'CAST(H.ID_TRPRO AS CHAR)',
    '''PT''', 'CAST(H.ID_TRPRO AS CHAR)',
    'DATE(H.INSTANTE_PROPUESTA_TRPRO)',
    'H.INSTANTE_ALTA', 'H.ESTADO_TRPRO',
    'CONCAT(H.CODIGO_ALM_ORIGEN_TRPRO, '' / '', ' +
    'H.CODIGO_ALM_DESTINO_TRPRO)', Lineas, Unidades,
    'EXISTS (SELECT 1 FROM fza_almacenes AE ' +
    'WHERE AE.CODIGO_ALM_ALM = H.CODIGO_ALM_ORIGEN_TRPRO ' +
    'AND AE.CODIGO_EMP_ALM = :EMPRESA_PT)', 'LIMITE_PT');
end;

function SqlCabecerasRecientesDocumentosOrigen(
  AIncluirPropuestasTraspaso: Boolean): string;
begin
  Result :=
    SqlCabecerasAlbaranesPedidos + ' UNION ALL ' +
    SqlCabecerasFacturas + ' UNION ALL ' +
    SqlCabecerasOperacionesCaja + ' UNION ALL ' +
    SqlCabecerasTraspasosSesiones + ' UNION ALL ' +
    SqlCabeceraInventario + ' UNION ALL ' +
    SqlCabeceraTarifas;
  if AIncluirPropuestasTraspaso then
    Result := Result + ' UNION ALL ' + SqlCabeceraPropuestasTraspaso;
end;

function SqlLineasTotalesUltimosAlbaranesVenta: string;
begin
  Result :=
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, ' +
    '       U.SERIE AS SERIE_DOCUMENTO, ' +
    '       U.NUMERO AS NUMERO_DOCUMENTO, L.CANTIDAD_ALBLIN AS CANTIDAD ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = U.SERIE ' +
    '   AND L.NUMERO_ALB_ALBLIN = U.NUMERO ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AV'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_celdas C ' +
    '         WHERE C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '           AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '           AND C.LINEA_ALBCEL = ' +
    SqlLineaNumerica('L.LINEA_ALBLIN') + ' ' +
    '           AND C.CANTIDAD_ALBCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, U.SERIE, U.NUMERO, ' +
    '       C.CANTIDAD_ALBCEL ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_lineas L ' +
    '    ON L.SERIE_ALB_ALBLIN = U.SERIE ' +
    '   AND L.NUMERO_ALB_ALBLIN = U.NUMERO ' +
    '  JOIN fza_albaranes_celdas C ' +
    '    ON C.SERIE_ALB_ALBCEL = L.SERIE_ALB_ALBLIN ' +
    '   AND C.NUMERO_ALB_ALBCEL = L.NUMERO_ALB_ALBLIN ' +
    '   AND C.LINEA_ALBCEL = ' +
    SqlLineaNumerica('L.LINEA_ALBLIN') + ' ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AV'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCEL <> 0';
end;

function SqlLineasTotalesUltimosAlbaranesCompra: string;
begin
  Result :=
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, ' +
    '       U.SERIE AS SERIE_DOCUMENTO, ' +
    '       U.NUMERO AS NUMERO_DOCUMENTO, L.CANTIDAD_ALBCLIN AS CANTIDAD ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = U.SERIE ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = U.NUMERO ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AB'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND COALESCE(L.CANTIDAD_ALBCLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_albaranes_compra_celdas C ' +
    '         WHERE C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '           AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '           AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    '           AND C.CANTIDAD_ALBCCEL <> 0) ' +
    'UNION ALL ' +
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, U.SERIE, U.NUMERO, ' +
    '       C.CANTIDAD_ALBCCEL ' +
    '  FROM ULTIMOS U ' +
    '  JOIN fza_albaranes_compra_lineas L ' +
    '    ON L.SERIE_ALBC_ALBCLIN = U.SERIE ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = U.NUMERO ' +
    '  JOIN fza_albaranes_compra_celdas C ' +
    '    ON C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '   AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '   AND C.LINEA_ALBC_ALBCCEL = L.LINEA_ALBCLIN ' +
    ' WHERE U.TIPO_DOCUMENTO = ''AB'' ' +
    '   AND NULLIF(TRIM(L.CODIGO_ART_ALBCLIN), '''') IS NOT NULL ' +
    '   AND C.CANTIDAD_ALBCCEL <> 0';
end;

function SqlTotalesUltimosDocumentosOrigen: string;
begin
  Result :=
    'SELECT U.TIPO_DOCUMENTO, U.EMPRESA_DOCUMENTO, ' +
    '       U.SERIE_ORIGEN AS SERIE_DOCUMENTO, ' +
    '       U.NUMERO_ORIGEN AS NUMERO_DOCUMENTO, U.NUMERO_LINEAS, ' +
    '       U.TOTAL_UNIDADES ' +
    '  FROM ULTIMOS U';
end;

function SqlConsultarUltimosDocumentosOrigen(
  AIncluirPropuestasTraspaso: Boolean): string;
begin
  Result :=
    'WITH CANDIDATOS AS (' +
    SqlCabecerasRecientesDocumentosOrigen(AIncluirPropuestasTraspaso) +
    '), ULTIMOS AS (SELECT C.* FROM CANDIDATOS C ' +
    ' ORDER BY ' + SqlInstanteOrden(
      'C.INSTANTE_ALTA', 'C.FECHA') + ' DESC, ' +
    '          C.TIPO_DOCUMENTO, C.SERIE, C.NUMERO ' +
    ' LIMIT :LIMITE_GLOBAL) ' +
    'SELECT D.TIPO_DOCUMENTO, D.TIPO_DESCRIPCION, ' +
    '       D.SERIE, D.NUMERO, D.SERIE_ORIGEN, D.NUMERO_ORIGEN, ' +
    '       D.FECHA, D.INSTANTE_ALTA, D.ESTADO, D.TERCERO, ' +
    '       COALESCE(T.NUMERO_LINEAS, 0) AS NUMERO_LINEAS, ' +
    '       COALESCE(T.TOTAL_UNIDADES, 0) AS TOTAL_UNIDADES ' +
    '  FROM ULTIMOS D ' +
    '  LEFT JOIN (' + SqlTotalesUltimosDocumentosOrigen + ') T ' +
    '    ON T.TIPO_DOCUMENTO = D.TIPO_DOCUMENTO ' +
    '   AND T.EMPRESA_DOCUMENTO = D.EMPRESA_DOCUMENTO ' +
    '   AND T.SERIE_DOCUMENTO = D.SERIE_ORIGEN ' +
    '   AND T.NUMERO_DOCUMENTO = D.NUMERO_ORIGEN ' +
    ' ORDER BY ' + SqlInstanteOrden(
      'D.INSTANTE_ALTA', 'D.FECHA') + ' DESC, ' +
    '          D.TIPO_DOCUMENTO, D.SERIE, D.NUMERO';
end;

function SqlPrevisualizar(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT X.LINEA_DOCUMENTO, X.CODIGO_ARTICULO, X.CODIGO_SKU, ' +
    '       X.CODIGO_ALMACEN, X.LOTE, X.FECHA_CADUCIDAD, ' +
    '       X.DESCRIPCION_ARTICULO, X.DESCRIPCION_SKU, X.CANTIDAD ' +
    '  FROM (' + ASqlLineas + ') X ' +
    ' ORDER BY X.ORDEN_LINEA, X.ORDEN_FILA, X.ORDEN_PIVOTE, ' +
    '          X.ORDEN_ALMACEN';
end;

function SqlPrevisualizarLineasAlbaranVenta: string;
begin
  Result := SqlPrevisualizar(SqlLineasAlbaranVentaResueltas);
end;

function SqlPrevisualizarLineasAlbaranCompra: string;
begin
  Result := SqlPrevisualizar(SqlLineasAlbaranCompraResueltas);
end;

function SqlInsertarLineasOrigen(const ASqlLineas: string): string;
begin
  Result :=
    'INSERT INTO fza_documentos_trabajo_lineas ' +
    '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    '   ORIGEN_DTL, CODIGO_EMP_ORIGEN_DTL, ' +
    '   TIPO_DOCUMENTO_ORIGEN_DTL, SERIE_DOCUMENTO_ORIGEN_DTL, ' +
    '   NUMERO_DOCUMENTO_ORIGEN_DTL, LINEA_DOCUMENTO_ORIGEN_DTL, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :ID_DTR, ' +
    '       LPAD(CAST(:PRIMERA_LINEA AS UNSIGNED) + ' +
    '         ROW_NUMBER() OVER (ORDER BY X.ORDEN_LINEA, X.ORDEN_FILA, ' +
    '           X.ORDEN_PIVOTE, X.ORDEN_ALMACEN) - 1, 8, ''0''), ' +
    '       X.CODIGO_ARTICULO, X.CODIGO_SKU, X.CODIGO_ALMACEN, ' +
    '       X.LOTE, X.FECHA_CADUCIDAD, X.DESCRIPCION_ARTICULO, ' +
    '       X.DESCRIPCION_SKU, 0, X.CANTIDAD, NOW(), ' +
    '       :ETIQUETA_ORIGEN, :EMPRESA, :TIPO_DOCUMENTO, :SERIE, ' +
    '       :NUMERO, X.LINEA_DOCUMENTO, NOW(), :USUARIO, :USUARIO ' +
    '  FROM (' + ASqlLineas + ') X ' +
    ' WHERE NOT EXISTS (SELECT 1 ' +
    '         FROM fza_documentos_trabajo_lineas D ' +
    '        WHERE D.ID_DTR_DTL = :ID_DTR ' +
    '          AND D.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '          AND D.TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '          AND D.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '          AND D.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO ' +
    '          AND D.LINEA_DOCUMENTO_ORIGEN_DTL = X.LINEA_DOCUMENTO) ' +
    ' ORDER BY X.ORDEN_LINEA, X.ORDEN_FILA, X.ORDEN_PIVOTE, ' +
    '          X.ORDEN_ALMACEN';
end;

function SqlInsertarLineasOrigenAlbaranVenta: string;
begin
  Result := SqlInsertarLineasOrigen(SqlLineasAlbaranVenta);
end;

function SqlInsertarLineasOrigenAlbaranCompra: string;
begin
  Result := SqlInsertarLineasOrigen(SqlLineasAlbaranCompra);
end;

function SqlLineasSegunTipo(const ATipoDocumento: string): string;
var
  TipoDocumento: string;
begin
  TipoDocumento := UpperCase(Trim(ATipoDocumento));
  if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA then
  begin
    Result := SqlLineasAlbaranVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA then
  begin
    Result := SqlLineasAlbaranCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PEDIDO_VENTA then
  begin
    Result := SqlLineasPedidoVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PRESUPUESTO_VENTA then
  begin
    Result := SqlLineasPresupuestoVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PEDIDO_COMPRA then
  begin
    Result := SqlLineasPedidoCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_FACTURA_VENTA then
  begin
    Result := SqlLineasFacturaVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_FACTURA_COMPRA then
  begin
    Result := SqlLineasFacturaCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_DEVOLUCION_COMPRA then
  begin
    Result := SqlLineasDevolucionCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_VENTA_TPV then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasVentaTpvBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_TRASPASO then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasTraspasoBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PETICION_TRASPASO then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasPeticionTraspasoBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PROPUESTA_TRASPASO then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasPropuestaTraspasoBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_SESION_COMPRA then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasSesionCompraBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_INVENTARIO then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasInventarioBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_SESION_TARIFAS then
  begin
    Result := SqlLineasElegiblesBase(SqlLineasSesionTarifasBase);
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlLineasResueltasSegunTipo(
  const ATipoDocumento: string): string;
var
  TipoDocumento: string;
begin
  TipoDocumento := UpperCase(Trim(ATipoDocumento));
  if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA then
  begin
    Result := SqlLineasAlbaranVentaResueltas;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA then
  begin
    Result := SqlLineasAlbaranCompraResueltas;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PEDIDO_VENTA then
  begin
    Result := SqlLineasResueltasPedidoVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PRESUPUESTO_VENTA then
  begin
    Result := SqlLineasResueltasPresupuestoVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PEDIDO_COMPRA then
  begin
    Result := SqlLineasResueltasPedidoCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_FACTURA_VENTA then
  begin
    Result := SqlLineasResueltasFacturaVenta;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_FACTURA_COMPRA then
  begin
    Result := SqlLineasResueltasFacturaCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_DEVOLUCION_COMPRA then
  begin
    Result := SqlLineasResueltasDevolucionCompra;
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_VENTA_TPV then
  begin
    Result := SqlLineasResueltasBase(SqlLineasVentaTpvBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_TRASPASO then
  begin
    Result := SqlLineasResueltasBase(SqlLineasTraspasoBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PETICION_TRASPASO then
  begin
    Result := SqlLineasResueltasBase(SqlLineasPeticionTraspasoBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_PROPUESTA_TRASPASO then
  begin
    Result := SqlLineasResueltasBase(SqlLineasPropuestaTraspasoBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_SESION_COMPRA then
  begin
    Result := SqlLineasResueltasBase(SqlLineasSesionCompraBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_INVENTARIO then
  begin
    Result := SqlLineasResueltasBase(SqlLineasInventarioBase);
  end
  else if TipoDocumento = TIPO_DOCUMENTO_ORIGEN_SESION_TARIFAS then
  begin
    Result := SqlLineasResueltasBase(SqlLineasSesionTarifasBase);
  end
  else
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlContarLineasOrigenSinSku(
  const ATipoDocumento: string): string;
begin
  Result :=
    'SELECT COUNT(*) AS LINEAS_SIN_SKU ' +
    '  FROM (' + SqlLineasResueltasSegunTipo(ATipoDocumento) + ') X ' +
    ' WHERE NULLIF(TRIM(X.CODIGO_SKU), '''') IS NULL';
end;

function SqlResumenCargaOrigen(const ASqlLineas: string): string;
begin
  Result :=
    'SELECT COUNT(*) AS LINEAS_ENCONTRADAS, ' +
    '       COALESCE(SUM(CASE WHEN EXISTS (SELECT 1 ' +
    '         FROM fza_documentos_trabajo_lineas D ' +
    '        WHERE D.ID_DTR_DTL = :ID_DTR ' +
    '          AND D.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '          AND D.TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '          AND D.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '          AND D.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO ' +
    '          AND D.LINEA_DOCUMENTO_ORIGEN_DTL = X.LINEA_DOCUMENTO) ' +
    '         THEN 1 ELSE 0 END), 0) AS LINEAS_OMITIDAS, ' +
    '       COALESCE(SUM(CASE WHEN NOT EXISTS (SELECT 1 ' +
    '         FROM fza_documentos_trabajo_lineas D ' +
    '        WHERE D.ID_DTR_DTL = :ID_DTR ' +
    '          AND D.CODIGO_EMP_ORIGEN_DTL = :EMPRESA ' +
    '          AND D.TIPO_DOCUMENTO_ORIGEN_DTL = :TIPO_DOCUMENTO ' +
    '          AND D.SERIE_DOCUMENTO_ORIGEN_DTL = :SERIE ' +
    '          AND D.NUMERO_DOCUMENTO_ORIGEN_DTL = :NUMERO ' +
    '          AND D.LINEA_DOCUMENTO_ORIGEN_DTL = X.LINEA_DOCUMENTO) ' +
    '         THEN X.CANTIDAD ELSE 0 END), 0) AS TOTAL_UNIDADES ' +
    '  FROM (' + ASqlLineas + ') X';
end;

procedure ValidarOrigenDocumentoTrabajo(
  const AOrigen: TDocumentoTrabajoOrigen);
var
  TipoDocumento: string;
begin
  if (Trim(AOrigen.Empresa) = '') or
     (Trim(AOrigen.TipoDocumento) = '') or
     (Trim(AOrigen.Serie) = '') or
     (Trim(AOrigen.Numero) = '') then
  begin
    raise EArgumentException.Create(SErrorDocumentoOrigenIncompleto);
  end;
  TipoDocumento := UpperCase(Trim(AOrigen.TipoDocumento));
  if not EsTipoDocumentoOrigenSoportado(TipoDocumento) then
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [AOrigen.TipoDocumento]);
  end;
end;

function SqlPrevisualizarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
begin
  Result := SqlPrevisualizar(
    SqlLineasResueltasSegunTipo(ATipoDocumento));
end;

function IntentarSqlBloqueoComercial(const ATipoDocumento: string;
  out ASql: string): Boolean;
begin
  Result := True;
  if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_ALBARAN_VENTA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_ALB, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_ALB END AS ESTADO ' +
      '  FROM fza_albaranes ' +
      ' WHERE CODIGO_EMP_ALB = :EMPRESA ' +
      '   AND SERIE_ALB = :SERIE AND NUMERO_ALB = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_ALBARAN_COMPRA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_ALBC, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_ALBC END AS ESTADO ' +
      '  FROM fza_albaranes_compra ' +
      ' WHERE CODIGO_EMP_ALBC = :EMPRESA ' +
      '   AND SERIE_ALBC = :SERIE AND NUMERO_ALBC = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_PEDIDO_VENTA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_PED, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_PED END AS ESTADO FROM fza_pedidos ' +
      ' WHERE CODIGO_EMP_PED = :EMPRESA AND SERIE_PED = :SERIE ' +
      '   AND NUMERO_PED = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_PRESUPUESTO_VENTA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_PRE, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_PRE END AS ESTADO FROM fza_presupuestos ' +
      ' WHERE CODIGO_EMP_PRE = :EMPRESA AND SERIE_PRE = :SERIE ' +
      '   AND NUMERO_PRE = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_PEDIDO_COMPRA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_PEDC, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_PEDC END AS ESTADO FROM fza_pedidos_compra ' +
      ' WHERE CODIGO_EMP_PEDC = :EMPRESA AND SERIE_PEDC = :SERIE ' +
      '   AND NUMERO_PEDC = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_FACTURA_VENTA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(FASE_FAC, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'WHEN UPPER(COALESCE(FASE_FAC, '''')) LIKE ''%ANULADA'' ' +
      'THEN ''CANCELADO'' ' +
      'ELSE FASE_FAC END AS ESTADO FROM fza_facturas ' +
      ' WHERE CODIGO_EMP_FAC = :EMPRESA AND SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_FACTURA_COMPRA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_FACC, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_FACC END AS ESTADO FROM fza_facturas_compra ' +
      ' WHERE CODIGO_EMP_FACC = :EMPRESA AND SERIE_FACC = :SERIE ' +
      '   AND NUMERO_FACC = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_DEVOLUCION_COMPRA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_DEVC, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_DEVC END AS ESTADO FROM fza_devoluciones_compra ' +
      ' WHERE CODIGO_EMP_DEVC = :EMPRESA AND SERIE_DEVC = :SERIE ' +
      '   AND NUMERO_DEVC = :NUMERO FOR UPDATE';
  end
  else
  begin
    Result := False;
  end;
end;

function IntentarSqlBloqueoOperativo(const ATipoDocumento: string;
  out ASql: string): Boolean;
begin
  Result := True;
  if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_VENTA_TPV then
  begin
    ASql :=
      'SELECT ''GRABADA'' AS ESTADO FROM fza_caja_operaciones ' +
      ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
      '   AND ID_OPCAJA = CAST(:SERIE AS UNSIGNED) ' +
      '   AND CAST(ID_OPCAJA AS CHAR) = :NUMERO ' +
      '   AND TIPO_OPERACION_OPCAJA = ''VE'' FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_TRASPASO then
  begin
    ASql :=
      'SELECT ''GRABADO'' AS ESTADO FROM fza_caja_operaciones ' +
      ' WHERE CODIGO_EMP_OPCAJA = :EMPRESA ' +
      '   AND ID_OPCAJA = CAST(:SERIE AS UNSIGNED) ' +
      '   AND CAST(ID_OPCAJA AS CHAR) = :NUMERO ' +
      '   AND TIPO_OPERACION_OPCAJA IN (''TR'', ''TA'', ''AT'') ' +
      ' FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_PETICION_TRASPASO then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_TRSOL, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_TRSOL END AS ESTADO ' +
      'FROM fza_traspasos_solicitudes ' +
      ' WHERE CODIGO_EMP_TRSOL = :EMPRESA AND SERIE_TRSOL = :SERIE ' +
      '   AND NUMERO_TRSOL = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_PROPUESTA_TRASPASO then
  begin
    // Una propuesta no aceptada también se puede cargar: sus unidades
    // siguen en el origen y hay que volver a decidir qué se hace con ellas.
    ASql :=
      'SELECT H.ESTADO_TRPRO AS ESTADO ' +
      '  FROM fza_traspasos_propuestas H ' +
      ' WHERE H.ID_TRPRO = CAST(:NUMERO AS UNSIGNED) ' +
      '   AND CAST(H.ID_TRPRO AS CHAR) = :NUMERO ' +
      '   AND :SERIE = ''PT'' AND :EMPRESA <> '''' FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_SESION_COMPRA then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_SES, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_SES END AS ESTADO FROM fza_compras_sesiones ' +
      ' WHERE CODIGO_EMP_SES = :EMPRESA AND SERIE_SES = :SERIE ' +
      '   AND NUMERO_SES = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_INVENTARIO then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_INV, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_INV END AS ESTADO FROM fza_inventarios H ' +
      ' WHERE H.CODIGO_EMP_INV = :EMPRESA ' +
      '   AND H.CODIGO_ALM_INV = :SERIE ' +
      '   AND ' + SqlClaveInventario + ' = :NUMERO FOR UPDATE';
  end
  else if ATipoDocumento = TIPO_DOCUMENTO_ORIGEN_SESION_TARIFAS then
  begin
    ASql :=
      'SELECT CASE WHEN UPPER(COALESCE(ESTADO_TARC, '''')) IN ' +
      '(''CANCELADA'', ''CANCELADO'', ''ANULADA'') THEN ''CANCELADO'' ' +
      'ELSE ESTADO_TARC END AS ESTADO FROM fza_tarifas_cambios ' +
      ' WHERE CODIGO_TARC = CAST(:SERIE AS UNSIGNED) ' +
      '   AND CAST(CODIGO_TARC AS CHAR) = :NUMERO ' +
      '   AND :EMPRESA <> '''' FOR UPDATE';
  end
  else
  begin
    Result := False;
  end;
end;

function SqlBloquearDocumentoOrigen(
  const ATipoDocumento: string): string;
var
  Encontrado: Boolean;
  TipoDocumento: string;
begin
  TipoDocumento := UpperCase(Trim(ATipoDocumento));
  Encontrado := IntentarSqlBloqueoComercial(TipoDocumento, Result);
  if not Encontrado then
  begin
    Encontrado := IntentarSqlBloqueoOperativo(TipoDocumento, Result);
  end;
  if not Encontrado then
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
end;

function SqlInsertarLineasDocumentoOrigen(
  const ATipoDocumento: string): string;
begin
  Result := SqlInsertarLineasOrigen(
    SqlLineasSegunTipo(ATipoDocumento));
end;

function SqlResumenCargaOrigenDocumento(
  const ATipoDocumento: string): string;
begin
  Result := SqlResumenCargaOrigen(
    SqlLineasSegunTipo(ATipoDocumento));
end;

end.
