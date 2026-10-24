{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataLibrosIvaSql                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Consultas del listado «Libros de IVA» (FZ-ISSUE-262). Una fila por        }
{    factura y tramo de IVA (N, R, S, E) con base, cuota y recargo             }
{    redondeados a céntimos:                                                   }
{    - Repercutido: fza_facturas (normales, simplificadas y rectificativas)   }
{      sin borradores, canceladas, anuladas ni facturas sustituidas.          }
{      Las ventas sin fase solo entran con pSINFASE = 'S' (SIF sin activar).  }
{    - Soportado: fza_facturas_compra grabadas salvo las canceladas.          }
{    Parámetros: pDESDE, pHASTA, pEMP (CSV de empresas), pLIB (CSV de         }
{    libros REP/SOP) y pSINFASE (S/N); los CSV vacíos no filtran.             }
{******************************************************************************}
unit UniDataLibrosIvaSql;

interface

function SqlEmpresasLibrosIva: string;
function SqlDetalleLibrosIva: string;
function SqlResumenLibrosIva: string;
// FZ-ISSUE-372: cuadro de liquidación por empresa.
function SqlLiquidacionLibrosIva: string;
// FZ-ISSUE-632: facturas del libro soportado sin n.º de fra. proveedor.
function SqlSoportadoSinNumeroProveedorLibrosIva: string;

implementation

uses
  UniDataRectificativasSql;

const
  CTramos =
    ' CROSS JOIN (SELECT 1 AS ORD, ''N'' AS TIPO ' +
    '   UNION ALL SELECT 2, ''R'' ' +
    '   UNION ALL SELECT 3, ''S'' ' +
    '   UNION ALL SELECT 4, ''E'') T ';

// Columna del tramo T.ORD: <Alias>.<Prefijo>{N|R|S|E}<Sufijo>.
function Tramo(const AAlias, APrefijo, ASufijo: string): string;
begin
  Result :=
    'CASE T.ORD ' +
    'WHEN 1 THEN ' + AAlias + '.' + APrefijo + 'N' + ASufijo + ' ' +
    'WHEN 2 THEN ' + AAlias + '.' + APrefijo + 'R' + ASufijo + ' ' +
    'WHEN 3 THEN ' + AAlias + '.' + APrefijo + 'S' + ASufijo + ' ' +
    'ELSE ' + AAlias + '.' + APrefijo + 'E' + ASufijo + ' END';
end;

function Importe(const AAlias, APrefijo, ASufijo: string): string;
begin
  Result := 'ROUND(COALESCE(' + Tramo(AAlias, APrefijo, ASufijo) +
    ', 0), 2)';
end;

function SqlRepercutido: string;
begin
  Result :=
    'SELECT F.CODIGO_EMP_FAC AS EMPRESA, ' +
    '  COALESCE(E.RAZON_SOCIAL_EMP, F.RAZON_SOCIAL_EMPRESA_FAC, '''') ' +
    '    AS RAZON_SOCIAL_EMPRESA, ' +
    '  ''REP'' AS LIBRO, ' +
    '  F.FECHA_FAC AS FECHA, ' +
    '  F.SERIE_FAC AS SERIE, ' +
    '  F.NUMERO_FAC AS NUMERO, ' +
    '  F.TIPO_FAC AS TIPO_DOC, ' +
    '  COALESCE(F.NIF_CLIENTE_FAC, '''') AS NIF, ' +
    '  COALESCE(F.RAZON_SOCIAL_CLIENTE_FAC, '''') AS NOMBRE, ' +
    '  '''' AS DOC_EXTERNO, ' +
    '  T.ORD AS ORDEN_TIPO, ' +
    '  T.TIPO AS TIPO_IVA, ' +
    '  ' + Tramo('F', 'PORCENTAJE_IVA', '_FAC') + ' AS PORC_IVA, ' +
    '  ' + Importe('F', 'TOTAL_BASEI_IVA', '_FAC') + ' AS BASE, ' +
    '  ' + Importe('F', 'TOTAL_IVA', '_FAC') + ' AS CUOTA_IVA, ' +
    '  ' + Tramo('F', 'PORCENTAJE_RE', '_FAC') + ' AS PORC_RE, ' +
    '  ' + Importe('F', 'TOTAL_RE', '_FAC') + ' AS CUOTA_RE ' +
    'FROM fza_facturas F ' +
    CTramos +
    'LEFT JOIN fza_empresas E ON E.CODIGO_EMP_EMP = F.CODIGO_EMP_FAC ' +
    'WHERE F.FECHA_FAC >= :pDESDE ' +
    '  AND F.FECHA_FAC <= :pHASTA ' +
    '  AND (:pEMP = '''' OR FIND_IN_SET(F.CODIGO_EMP_FAC, :pEMP)) ' +
    '  AND (:pLIB = '''' OR FIND_IN_SET(''REP'', :pLIB)) ' +
    '  AND COALESCE(F.FASE_FAC, '''') NOT IN ' +
    '    (''BORRADOR'', ''ERROR_BORRADOR'', ''CANCELADA'') ' +
    // Sin fase: histórico emitido sin SIF o borrador pendiente con él.
    '  AND (COALESCE(F.FASE_FAC, '''') <> '''' OR :pSINFASE = ''S'') ' +
    SQLExcluirVentaRetirada('F.CODIGO_EMP_FAC', 'F.SERIE_FAC',
      'F.NUMERO_FAC') +
    // FZ-ISSUE-388: el ticket convertido en factura normal no se anota
    // además de la factura que lo sustituye.
    SQLExcluirTicketSustituido('F.CODIGO_EMP_FAC', 'F.SERIE_FAC',
      'F.NUMERO_FAC');
end;

function SqlSoportado: string;
begin
  Result :=
    'SELECT C.CODIGO_EMP_FACC, ' +
    '  COALESCE(E.RAZON_SOCIAL_EMP, ''''), ' +
    '  ''SOP'', ' +
    '  C.FECHA_FACC, ' +
    '  C.SERIE_FACC, ' +
    '  C.NUMERO_FACC, ' +
    '  ''COMPRA'', ' +
    '  COALESCE(C.NIF_PRV_FACC, ''''), ' +
    '  COALESCE(C.RAZON_SOCIAL_PRV_FACC, ''''), ' +
    // N.º de factura del proveedor: documento externo o, vacío, la
    // referencia que se teclea en la pantalla (FZ-ISSUE-389).
    '  COALESCE(NULLIF(TRIM(C.DOC_EXTERNO_FACC), ''''), ' +
    '    TRIM(C.REF_PROVEEDOR_FACC), ''''), ' +
    '  T.ORD, ' +
    '  T.TIPO, ' +
    '  ' + Tramo('C', 'PORCENTAJE_IVA', '_FACC') + ', ' +
    '  ' + Importe('C', 'TOTAL_BASEI_IVA', '_FACC') + ', ' +
    '  ' + Importe('C', 'TOTAL_IVA', '_FACC') + ', ' +
    '  ' + Tramo('C', 'PORCENTAJE_RE', '_FACC') + ', ' +
    '  ' + Importe('C', 'TOTAL_RE', '_FACC') + ' ' +
    'FROM fza_facturas_compra C ' +
    CTramos +
    'LEFT JOIN fza_empresas E ON E.CODIGO_EMP_EMP = C.CODIGO_EMP_FACC ' +
    'WHERE C.FECHA_FACC >= :pDESDE ' +
    '  AND C.FECHA_FACC <= :pHASTA ' +
    '  AND (:pEMP = '''' OR FIND_IN_SET(C.CODIGO_EMP_FACC, :pEMP)) ' +
    '  AND (:pLIB = '''' OR FIND_IN_SET(''SOP'', :pLIB)) ' +
    '  AND COALESCE(C.ESTADO_FACC, '''') <> ''CANCELADA'' ';
end;

// Filas con importe de ambos libros; el porcentaje de recargo solo se
// muestra si el tramo lleva recargo.
function SqlTramos: string;
begin
  Result :=
    'SELECT D.EMPRESA, D.RAZON_SOCIAL_EMPRESA, D.LIBRO, D.FECHA, ' +
    '  D.SERIE, D.NUMERO, D.TIPO_DOC, D.NIF, D.NOMBRE, D.DOC_EXTERNO, ' +
    '  D.ORDEN_TIPO, D.TIPO_IVA, D.PORC_IVA, D.BASE, D.CUOTA_IVA, ' +
    '  IF(D.CUOTA_RE = 0, 0, D.PORC_RE) AS PORC_RE, D.CUOTA_RE ' +
    'FROM (' + SqlRepercutido + ' UNION ALL ' + SqlSoportado + ') D ' +
    'WHERE D.BASE <> 0 OR D.CUOTA_IVA <> 0 OR D.CUOTA_RE <> 0';
end;

function SqlEmpresasLibrosIva: string;
begin
  Result :=
    'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP ' +
    'FROM fza_empresas ' +
    'ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, CODIGO_EMP_EMP';
end;

function SqlDetalleLibrosIva: string;
begin
  Result :=
    'SELECT L.EMPRESA, L.RAZON_SOCIAL_EMPRESA, L.LIBRO, L.FECHA, ' +
    '  CONCAT(L.SERIE, ''/'', L.NUMERO) AS DOCUMENTO, L.TIPO_DOC, ' +
    '  L.NIF, L.NOMBRE, L.DOC_EXTERNO, L.TIPO_IVA, L.PORC_IVA, ' +
    '  L.BASE, L.CUOTA_IVA, L.PORC_RE, L.CUOTA_RE, ' +
    '  L.BASE + L.CUOTA_IVA + L.CUOTA_RE AS TOTAL ' +
    'FROM (' + SqlTramos + ') L ' +
    'ORDER BY L.EMPRESA, L.LIBRO, L.FECHA, L.SERIE, L.NUMERO, ' +
    '  L.ORDEN_TIPO';
end;

function SqlResumenLibrosIva: string;
begin
  Result :=
    'SELECT L.EMPRESA, L.LIBRO, L.PORC_IVA, L.PORC_RE, ' +
    '  COUNT(DISTINCT CONCAT(L.SERIE, ''/'', L.NUMERO)) AS DOCUMENTOS, ' +
    '  SUM(L.BASE) AS BASE, SUM(L.CUOTA_IVA) AS CUOTA_IVA, ' +
    '  SUM(L.CUOTA_RE) AS CUOTA_RE, ' +
    '  SUM(L.BASE + L.CUOTA_IVA + L.CUOTA_RE) AS TOTAL ' +
    'FROM (' + SqlTramos + ') L ' +
    'GROUP BY L.EMPRESA, L.LIBRO, L.PORC_IVA, L.PORC_RE ' +
    'ORDER BY L.EMPRESA, L.LIBRO, L.PORC_IVA DESC, L.PORC_RE DESC';
end;

// FZ-ISSUE-372: una fila por empresa con el IVA y el recargo repercutidos
// y soportados del periodo. Resultado = repercutido (IVA + recargo) menos
// el IVA soportado deducible. La empresa acogida al recargo de
// equivalencia (ESIVA_RECARGO_COMPRAS_EMP) no liquida: su IVA y recargo
// soportados no son deducibles y el resultado queda a 0.
function SqlLiquidacionLibrosIva: string;
const
  CEnRecargo =
    'COALESCE(MAX(ER.ESIVA_RECARGO_COMPRAS_EMP), ''N'') = ''S''';
  CIvaRepercutido = 'SUM(IF(L.LIBRO = ''REP'', L.CUOTA_IVA, 0))';
  CReRepercutido = 'SUM(IF(L.LIBRO = ''REP'', L.CUOTA_RE, 0))';
  CIvaSoportado = 'SUM(IF(L.LIBRO = ''SOP'', L.CUOTA_IVA, 0))';
begin
  Result :=
    'SELECT L.EMPRESA, MAX(L.RAZON_SOCIAL_EMPRESA) ' +
    '    AS RAZON_SOCIAL_EMPRESA, ' +
    '  IF(' + CEnRecargo + ', ''S'', ''N'') AS ESRECARGO, ' +
    '  ' + CIvaRepercutido + ' AS IVA_REPERCUTIDO, ' +
    '  ' + CReRepercutido + ' AS RE_REPERCUTIDO, ' +
    '  ' + CIvaSoportado + ' AS IVA_SOPORTADO, ' +
    '  SUM(IF(L.LIBRO = ''SOP'', L.CUOTA_RE, 0)) AS RE_SOPORTADO, ' +
    '  IF(' + CEnRecargo + ', 0, ' + CIvaSoportado + ') ' +
    '    AS IVA_DEDUCIBLE, ' +
    '  IF(' + CEnRecargo + ', 0, ' + CIvaRepercutido + ' + ' +
    CReRepercutido + ' - ' + CIvaSoportado + ') AS RESULTADO ' +
    'FROM (' + SqlTramos + ') L ' +
    'LEFT JOIN fza_empresas ER ON ER.CODIGO_EMP_EMP = L.EMPRESA ' +
    'GROUP BY L.EMPRESA ' +
    'ORDER BY L.EMPRESA';
end;

// FZ-ISSUE-632: una fila por factura del libro soportado (mismas filas que
// el detalle) cuya columna «N.º fra. proveedor» saldría vacía.
function SqlSoportadoSinNumeroProveedorLibrosIva: string;
begin
  Result :=
    'SELECT L.EMPRESA, L.SERIE, L.NUMERO, ' +
    '  MAX(L.FECHA) AS FECHA, MAX(L.NOMBRE) AS NOMBRE ' +
    'FROM (' + SqlTramos + ') L ' +
    'WHERE L.LIBRO = ''SOP'' ' +
    '  AND L.DOC_EXTERNO = '''' ' +
    'GROUP BY L.EMPRESA, L.SERIE, L.NUMERO ' +
    'ORDER BY L.EMPRESA, MAX(L.FECHA), L.SERIE, L.NUMERO';
end;

end.
