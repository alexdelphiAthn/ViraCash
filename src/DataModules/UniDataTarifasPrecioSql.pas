{******************************************************************************}
{  Módulo: UniDataTarifasPrecioSql                                              }
{  Tipo: Persistencia                                                         }
{  Fecha: 29/09/2026                                                           }
{  Selección común del precio vigente para documentos, caja y etiquetas.       }
{******************************************************************************}
unit UniDataTarifasPrecioSql;

interface

// Los argumentos son expresiones SQL fijas del llamador, nunca valores del
// usuario. Estos viajan como parámetros de la consulta que incluye el bloque.
function SqlSeleccionPrecioTarifa(const AArticulo, ASku, ATarifa,
  AFecha: string): string;

implementation

uses
  System.SysUtils;

const
  SQL_SELECCION_PRECIO_TARIFA =
    'SELECT PT.CODIGO_UNICO_ARTTAR ' +
    'FROM fza_articulos_tarifas PT ' +
    'JOIN fza_tarifas VT ' +
    'ON VT.CODIGO_TAR_ARTTAR = PT.CODIGO_TAR_ARTTAR ' +
    'AND VT.ESACTIVO_ARTTAR = ''S'' ' +
    'WHERE PT.CODIGO_ART_ARTTAR = {ARTICULO} ' +
    'AND PT.CODIGO_TAR_ARTTAR = {TARIFA} ' +
    'AND PT.ESACTIVO_ARTTAR = ''S'' ' +
    'AND (PT.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR PT.FECHA_DESDE_ARTTAR <= {FECHA}) ' +
    'AND (PT.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR PT.FECHA_HASTA_ARTTAR >= {FECHA}) ' +
    'AND (COALESCE(PT.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'OR PT.CODIGO_UNIDAD_ARTTAR = {SKU} ' +
    'OR (COALESCE(PT.CODIGO_UNIDAD_ARTTAR, '''') <> '''' ' +
    'AND LOCATE(''/*/'', PT.CODIGO_UNIDAD_ARTTAR) = 0 ' +
    'AND LEFT({SKU}, CHAR_LENGTH(PT.CODIGO_UNIDAD_ARTTAR) + 1) ' +
    '= CONCAT(PT.CODIGO_UNIDAD_ARTTAR, ''/'')) ' +
    'OR EXISTS (SELECT 1 FROM fza_atributos_sku ATS ' +
    'JOIN fza_atributos_valores TALLA ON TALLA.ID_AV = ATS.ID_AV_SA ' +
    'AND TALLA.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
    'AR452.CODIGO_ART_ART = {ARTICULO}) AND EJ452.EJE_VA = ''P'') ' +
    'WHERE ATS.CODIGO_UNIDAD_SKU_SA = {SKU} ' +
    'AND PT.CODIGO_UNIDAD_ARTTAR = ' +
    'CONCAT(PT.CODIGO_ART_ARTTAR, ''/*/'', TALLA.AV))) ' +
    'ORDER BY CASE ' +
    'WHEN PT.CODIGO_UNIDAD_ARTTAR = {SKU} AND {SKU} <> '''' THEN 0 ' +
    'WHEN LOCATE(''/*/'', PT.CODIGO_UNIDAD_ARTTAR) > 0 THEN 1 ' +
    'WHEN COALESCE(PT.CODIGO_UNIDAD_ARTTAR, '''') <> '''' THEN 2 ' +
    'ELSE 3 END, CHAR_LENGTH(PT.CODIGO_UNIDAD_ARTTAR) DESC, ' +
    // FZ-ISSUE-944: a igual concreción, un precio con fecha fin (periodo de
    // rebajas) gana al abierto mientras está vigente; si no, una sesión
    // normal aplicada el mismo día que empieza el periodo lo taparía.
    '(PT.FECHA_HASTA_ARTTAR IS NULL), ' +
    'PT.FECHA_DESDE_ARTTAR DESC, PT.CODIGO_UNICO_ARTTAR DESC LIMIT 1';

function SqlSeleccionPrecioTarifa(const AArticulo, ASku, ATarifa,
  AFecha: string): string;
begin
  // El comodín compara la talla registrada, sin convertir % o _ de los
  // códigos en comodines SQL. Los colores futuros quedan incluidos.
  Result := StringReplace(SQL_SELECCION_PRECIO_TARIFA,
    '{ARTICULO}', AArticulo, [rfReplaceAll]);
  Result := StringReplace(Result, '{SKU}', ASku, [rfReplaceAll]);
  Result := StringReplace(Result, '{TARIFA}', ATarifa, [rfReplaceAll]);
  Result := StringReplace(Result, '{FECHA}', AFecha, [rfReplaceAll]);
end;

end.
