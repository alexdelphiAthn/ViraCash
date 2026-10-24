{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRectificativasSql                                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fragmento SQL compartido para retirar de listados y agregados las         }
{    ventas anuladas o sustituidas. Antes vivía en inLibRectificativas;        }
{    el SQL pertenece a la capa de datos, no al dominio.                       }
{******************************************************************************}
unit UniDataRectificativasSql;

interface

function SQLExcluirVentaRetirada(
  const ACampoEmpresa, ACampoSerie, ACampoNumero: string): string;
// Retira el ticket que «Convertir en normal» sustituyó por una factura
// (relación SUSTITUYE) mientras esa factura siga vigente. Solo para
// libros y listados que leen fza_facturas, donde salen los dos documentos:
// en caja el ticket sigue siendo la venta cobrada (FZ-ISSUE-388).
function SQLExcluirTicketSustituido(
  const ACampoEmpresa, ACampoSerie, ACampoNumero: string): string;
// Unidades de un SKU ya devueltas de una venta (FZ-ISSUE-392): líneas en
// negativo de los documentos cuya operación de devolución (DV) referencia
// esa venta, sean rectificativas o devoluciones comerciales, salvo los
// anulados o cancelados. Subconsulta escalar, nunca NULL.
function SQLCantidadDevueltaVenta(
  const ACampoSerie, ACampoNumero, ACampoSku: string): string;

implementation

function SQLExcluirVentaRetirada(
  const ACampoEmpresa, ACampoSerie, ACampoNumero: string): string;
begin
  // La trazabilidad se conserva, pero la venta deja de intervenir.
  Result :=
    ' AND NOT EXISTS (' +
    ' SELECT 1 ' +
    ' FROM fza_facturas fa ' +
    ' WHERE fa.CODIGO_EMP_FAC = ' + ACampoEmpresa +
    '   AND fa.SERIE_FAC = ' + ACampoSerie +
    '   AND fa.NUMERO_FAC = ' + ACampoNumero +
    '   AND fa.FASE_FAC IN (''SIN_VERIF_ANULADA'', ' +
    '     ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' ) ' +
    ' AND NOT EXISTS (' +
    ' SELECT 1 ' +
    ' FROM fza_verifactu_cola va ' +
    ' WHERE va.SERIE_FAC_VFCOLA = ' + ACampoSerie +
    '   AND va.NUMERO_FAC_VFCOLA = ' + ACampoNumero +
    '   AND va.TIPO_OPERACION_VFCOLA = ''ANULACION'' ' +
    ' ) ' +
    ' AND NOT EXISTS (' +
    ' SELECT 1 ' +
    ' FROM fza_facturas fo ' +
    ' JOIN fza_facturas_relaciones fr ' +
    '   ON fr.SERIE_FAC_ORIGEN_FACREL = fo.SERIE_FAC ' +
    '  AND fr.NUMERO_FAC_ORIGEN_FACREL = fo.NUMERO_FAC ' +
    ' JOIN fza_facturas fs ' +
    '   ON fs.CODIGO_EMP_FAC = fo.CODIGO_EMP_FAC ' +
    '  AND fs.SERIE_FAC = fr.SERIE_FAC_FACREL ' +
    '  AND fs.NUMERO_FAC = fr.NUMERO_FAC_FACREL ' +
    ' WHERE fo.CODIGO_EMP_FAC = ' + ACampoEmpresa +
    '   AND fo.SERIE_FAC = ' + ACampoSerie +
    '   AND fo.NUMERO_FAC = ' + ACampoNumero +
    // FZ-ISSUE-373: también la NORMAL; la sustitutiva lleva los importes
    // completos y contar las dos duplica la venta.
    '   AND fo.FASE_FAC = ''RECTIFICADA'' ' +
    '   AND fr.TIPO_RELACION_FACREL = ''RECTIFICA'' ' +
    '   AND fs.TIPO_RECTIFICATIVA_FAC = ''S'' ' +
    ' ) ';
end;

function SQLExcluirTicketSustituido(
  const ACampoEmpresa, ACampoSerie, ACampoNumero: string): string;
begin
  // La factura lleva los mismos importes que el ticket: contar los dos
  // duplica la venta. Un borrador o una factura anulada no lo retiran.
  Result :=
    ' AND NOT EXISTS (' +
    ' SELECT 1 ' +
    ' FROM fza_facturas_relaciones ft ' +
    ' JOIN fza_facturas fn ' +
    '   ON fn.SERIE_FAC = ft.SERIE_FAC_FACREL ' +
    '  AND fn.NUMERO_FAC = ft.NUMERO_FAC_FACREL ' +
    ' WHERE ft.SERIE_FAC_ORIGEN_FACREL = ' + ACampoSerie +
    '   AND ft.NUMERO_FAC_ORIGEN_FACREL = ' + ACampoNumero +
    '   AND ft.TIPO_RELACION_FACREL = ''SUSTITUYE'' ' +
    '   AND fn.CODIGO_EMP_FAC = ' + ACampoEmpresa +
    '   AND COALESCE(fn.FASE_FAC, '''') NOT IN (''BORRADOR'', ' +
    '     ''ERROR_BORRADOR'', ''CANCELADA'', ''SIN_VERIF_ANULADA'', ' +
    '     ''VERIFACTU_ANULADA'', ''NOVERIFACTU_ANULADA'') ' +
    ' ) ';
end;

function SQLCantidadDevueltaVenta(
  const ACampoSerie, ACampoNumero, ACampoSku: string): string;
begin
  Result :=
    '(SELECT COALESCE(-SUM(dl.CANTIDAD_FACLIN), 0) ' +
    ' FROM fza_caja_operaciones dv ' +
    ' JOIN fza_facturas df ' +
    '   ON df.SERIE_FAC = dv.SERIE_FAC_OPCAJA ' +
    '  AND df.NUMERO_FAC = dv.NUMERO_FAC_OPCAJA ' +
    ' JOIN fza_facturas_lineas dl ' +
    '   ON dl.SERIE_FAC_FACLIN = df.SERIE_FAC ' +
    '  AND dl.NUMERO_FAC_FACLIN = df.NUMERO_FAC ' +
    ' WHERE dv.SERIE_REF_ORIGEN_OPCAJA = ' + ACampoSerie +
    '   AND dv.NUMERO_REF_ORIGEN_OPCAJA = ' + ACampoNumero +
    '   AND dv.TIPO_OPERACION_OPCAJA = ''DV'' ' +
    '   AND dl.CODIGO_UNIDAD_FACLIN = ' + ACampoSku +
    '   AND dl.CANTIDAD_FACLIN < 0 ' +
    '   AND COALESCE(df.FASE_FAC, '''') NOT IN (''CANCELADA'', ' +
    '     ''SIN_VERIF_ANULADA'', ''VERIFACTU_ANULADA'', ' +
    '     ''NOVERIFACTU_ANULADA''))';
end;

end.
