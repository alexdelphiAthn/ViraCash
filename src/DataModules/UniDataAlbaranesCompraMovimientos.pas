{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesCompraMovimientos                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de los movimientos de almacén de albaranes de            }
{    compra. Implementa IMovimientosAlbaranCompra y se registra en la          }
{    fábrica del contrato en su initialization.                                }
{                                                                              }
{    Usa el procedimiento almacenado PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT,       }
{    que es el único que toca stock real (fza_articulos_stockactual). La       }
{    reversión borra los movimientos por (TIPO_DOC='AC' + SERIE + NUMERO)      }
{    y recalcula PMP + stock de los SKUs afectados vía                         }
{    SP_RECALCULAR_PMP_LOTE_ALMACEN.                                           }
{                                                                              }
{    Fuente de datos para los movimientos:                                     }
{      - fza_albaranes_compra_celdas si la línea tiene celdas con              }
{        cantidad > 0 (caso edición manual con tallas).                        }
{      - fza_albaranes_compra_lineas en caso contrario, una entrada por        }
{        línea con CANTIDAD_ALBCLIN (caso materialización de sesión).          }
{                                                                              }
{    Limitación conocida: ambos caminos asumen que el SKU de la línea          }
{    (CODIGO_UNIDAD_ALBCLIN) es el correcto. No resolvemos un SKU              }
{    distinto por celda; cuando se permita en un hito futuro habrá que         }
{    ampliar ResolverSkuCelda en el bucle de celdas.                           }
{******************************************************************************}
unit UniDataAlbaranesCompraMovimientos;
interface
uses
  Uni, inLibAlbaranesCompraMovimientosIntf, inLibTrazabilidad;
function CrearMovimientosAlbaranCompraUniDAC(
  AConexion: TUniConnection): IMovimientosAlbaranCompra; overload;
function CrearMovimientosAlbaranCompraUniDAC(AConexion: TUniConnection;
  const AActivacion: TActivacionTrazabilidad):
  IMovimientosAlbaranCompra; overload;
implementation
uses
  System.SysUtils, Data.DB, inLibDocumento, inLibDocumentoIntf,
  UniDataValoresAutomaticosRepositorio, inLibMsgCompras,
  UniDataAlbaranesCompraMovimientosSql,
  UniDataMovimientosAlmacenRecalculo, inLibRedondeo,
  UniDataMovimientosLote;
type
  TMovimientosAlbaranCompraUniDAC = class(
    TInterfacedObject,
    IMovimientosAlbaranCompra)
  private
    FConexion: TUniConnection;
    FActivacion: TActivacionTrazabilidad;
  public
    constructor Create(AConexion: TUniConnection;
      const AActivacion: TActivacionTrazabilidad);
    procedure GenerarDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
    procedure RevertirDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
  end;
function EstrategiaAlbaranCompra: IEstrategiaDocumento;
begin
  Result := CrearEstrategiaDocumento(
    CrearConfiguracionDocumento(tdAlbaran, sdCompra));
end;
// Carga empresa, instante y almacén de respaldo para los movimientos.
// El almacén de línea o celda siempre tiene prioridad.
procedure LeerCabeceraAlbaran(AConn: TUniConnection;
                              const ASerieAlbc, ANumAlbc: string;
                              out ACodigoEmp, ACodigoAlmCab: string;
                              out AInstanteMovimiento: TDateTime);
var
  q: TUniQuery;
begin
  ACodigoEmp    := '';
  ACodigoAlmCab := '';
  AInstanteMovimiento := Now;
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT CODIGO_EMP_ALBC, CODIGO_ALM_ALBC, ' +
      '       COALESCE(INSTANTE_MOVIMIENTO_ALBC, ' +
      '                CAST(FECHA_ALBC AS datetime), NOW()) ' +
      '         AS INSTANTE_MOVIMIENTO ' +
      '  FROM fza_albaranes_compra ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ParamByName('n').AsString := ANumAlbc;
    q.Open;
    if q.Eof then
      raise Exception.CreateFmt(SErrorAlbaranCompraMovimientosNoEncontrado,
        [ASerieAlbc, ANumAlbc]);
    ACodigoEmp    := q.FieldByName('CODIGO_EMP_ALBC').AsString;
    ACodigoAlmCab := q.FieldByName('CODIGO_ALM_ALBC').AsString;
    AInstanteMovimiento :=
      q.FieldByName('INSTANTE_MOVIMIENTO').AsDateTime;
  finally
    FreeAndNil(q);
  end;
end;
procedure ActualizarArticulosProveedorDesdeAlbaranCompra(
                                               AConn: TUniConnection;
                                               const ASerieAlbc, ANumAlbc,
                                                     AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_proveedores ' +
      '  (CODIGO_PRV_AP, CODIGO_ART_AP, REF_PROVEEDOR_AP, ' +
      '   PRECIO_ULT_COMPRA_AP, FECHA_VALIDEZ_AP, ' +
      '   ESPROVEEDORPRINCIPAL_AP, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT X.CODIGO_PRV, X.CODIGO_ART, NULLIF(X.REF_PRV, ''''), ' +
      '       X.PRECIO, X.FECHA_ALBC, ' +
      '       CASE WHEN EXISTS ( ' +
      '              SELECT 1 FROM fza_articulos_proveedores AP2 ' +
      '               WHERE AP2.CODIGO_ART_AP = X.CODIGO_ART ' +
      '                 AND AP2.CODIGO_PRV_AP <> X.CODIGO_PRV ' +
      '                 AND AP2.ESPROVEEDORPRINCIPAL_AP = ''S'') ' +
      '            THEN ''N'' ELSE ''S'' END, ' +
      '       NOW(), :u1, NOW(), :u2 ' +
      '  FROM ( ' +
      '        SELECT A.CODIGO_PRV_ALBC AS CODIGO_PRV, ' +
      '               L.CODIGO_ART_ALBCLIN AS CODIGO_ART, ' +
      '               COALESCE(A.FECHA_ALBC, CURRENT_DATE) AS FECHA_ALBC, ' +
      '               COALESCE(TRIM(L.REF_PRV_ALBCLIN), '''') AS REF_PRV, ' +
      // FZ-ISSUE-381: precio del proveedor neto de descuento y sin
      // impuestos, igual para todas las empresas. El IVA y el recargo no
      // deducibles solo son coste de stock (PMP) de la empresa en recargo.
      '               (L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '(1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100)) * ' +
      '               CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
      '                      GREATEST(0, 1 - CASE ' +
      '                        WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 '
        +
      '                        THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
      'A.TOTAL_BRUTO_ALBC ' +
      '                        ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      '0) / 100 END) ' +
      '                    ELSE GREATEST(0, 1 - ' +
      'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '               END AS PRECIO ' +
      '          FROM fza_albaranes_compra_lineas L ' +
      '          JOIN fza_albaranes_compra A ' +
      '            ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '           AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '         WHERE L.SERIE_ALBC_ALBCLIN  = :s ' +
      '           AND L.NUMERO_ALBC_ALBCLIN = :n ' +
      '           AND COALESCE(TRIM(A.CODIGO_PRV_ALBC), '''') <> '''' ' +
      '           AND COALESCE(TRIM(A.CODIGO_PRV_ALBC), '''') <> ''0'' ' +
      '           AND COALESCE(TRIM(L.CODIGO_ART_ALBCLIN), '''') <> '''' ' +
      '           AND (IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                OR EXISTS ( ' +
      '                   SELECT 1 FROM fza_albaranes_compra_celdas C ' +
      '                    WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN '
        +
      '                      AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN '
        +
      '                      AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
      '                          = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
      '                      AND C.CANTIDAD_ALBCCEL > 0)) ' +
      '           AND NOT EXISTS ( ' +
      '                 SELECT 1 FROM fza_albaranes_compra_lineas L2 ' +
      '                  WHERE L2.SERIE_ALBC_ALBCLIN  = L.SERIE_ALBC_ALBCLIN ' +
      '                    AND L2.NUMERO_ALBC_ALBCLIN = L.NUMERO_ALBC_ALBCLIN '
        +
      '                    AND L2.CODIGO_ART_ALBCLIN  = L.CODIGO_ART_ALBCLIN ' +
      '                    AND (IFNULL(L2.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                         OR EXISTS ( ' +
      '                            SELECT 1 FROM fza_albaranes_compra_celdas ' +
      'C2 ' +
      '                             WHERE C2.SERIE_ALBC_ALBCCEL  = ' +
      'L2.SERIE_ALBC_ALBCLIN ' +
      '                               AND C2.NUMERO_ALBC_ALBCCEL = ' +
      'L2.NUMERO_ALBC_ALBCLIN ' +
      '                               AND CAST(C2.LINEA_ALBC_ALBCCEL AS ' +
      'UNSIGNED) ' +
      '                                   = CAST(L2.LINEA_ALBCLIN AS UNSIGNED) '
        +
      '                               AND C2.CANTIDAD_ALBCCEL > 0)) ' +
      '                    AND L2.LINEA_ALBCLIN > L.LINEA_ALBCLIN) ' +
      '       ) X ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_AP = IF(VALUES(FECHA_VALIDEZ_AP) >= ' +
      '    IFNULL(FECHA_VALIDEZ_AP, ''1000-01-01''), ' +
      '    VALUES(PRECIO_ULT_COMPRA_AP), PRECIO_ULT_COMPRA_AP), ' +
      '  REF_PROVEEDOR_AP = IF(VALUES(FECHA_VALIDEZ_AP) >= ' +
      '    IFNULL(FECHA_VALIDEZ_AP, ''1000-01-01''), ' +
      '    COALESCE(VALUES(REF_PROVEEDOR_AP), REF_PROVEEDOR_AP), ' +
      '    REF_PROVEEDOR_AP), ' +
      '  FECHA_VALIDEZ_AP = GREATEST(IFNULL(FECHA_VALIDEZ_AP, ' +
      '    ''1000-01-01''), VALUES(FECHA_VALIDEZ_AP)), ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u3';
    q.ParamByName('s').AsString  := ASerieAlbc;
    q.ParamByName('n').AsString  := ANumAlbc;
    q.ParamByName('u1').AsString := AUsuario;
    q.ParamByName('u2').AsString := AUsuario;
    q.ParamByName('u3').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure ActualizarCostesSkuDesdeAlbaranCompra(AConn: TUniConnection;
                                               const ASerieAlbc, ANumAlbc,
                                                     AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'INSERT INTO fza_articulos_skus_costes ' +
      '  (CODIGO_UNIDAD_SKU_SKUC, PRECIO_ULT_COMPRA_SKUC, ' +
      '   FECHA_ULT_COMPRA_SKUC, INSTANTE_ALTA, USUARIO_ALTA, ' +
      '   INSTANTE_MODIF, USUARIO_MODIF) ' +
      'SELECT X.CODIGO_SKU, X.PRECIO, X.FECHA_ALBC, ' +
      '       NOW(), :u1, NOW(), :u2 ' +
      '  FROM ( ' +
      '        SELECT L.CODIGO_UNIDAD_ALBCLIN AS CODIGO_SKU, ' +
      '               COALESCE(A.FECHA_ALBC, CURRENT_DATE) AS FECHA_ALBC, ' +
      // FZ-ISSUE-381: precio del proveedor neto de descuento y sin
      // impuestos, igual para todas las empresas. El IVA y el recargo no
      // deducibles solo son coste de stock (PMP) de la empresa en recargo.
      '               (L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '(1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100)) * ' +
      '               CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
      '                      GREATEST(0, 1 - CASE ' +
      '                        WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 '
        +
      '                        THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
      'A.TOTAL_BRUTO_ALBC ' +
      '                        ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      '0) / 100 END) ' +
      '                    ELSE GREATEST(0, 1 - ' +
      'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
      '               END AS PRECIO ' +
      '          FROM fza_albaranes_compra_lineas L ' +
      '          JOIN fza_albaranes_compra A ' +
      '            ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
      '           AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '         WHERE L.SERIE_ALBC_ALBCLIN  = :s ' +
      '           AND L.NUMERO_ALBC_ALBCLIN = :n ' +
      '           AND COALESCE(TRIM(L.CODIGO_UNIDAD_ALBCLIN), '''') <> '''' ' +
      '           AND (IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                OR EXISTS ( ' +
      '                   SELECT 1 FROM fza_albaranes_compra_celdas C ' +
      '                    WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN '
        +
      '                      AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN '
        +
      '                      AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
      '                          = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
      '                      AND C.CANTIDAD_ALBCCEL > 0)) ' +
      '           AND NOT EXISTS ( ' +
      '                 SELECT 1 FROM fza_albaranes_compra_lineas L2 ' +
      '                  WHERE L2.SERIE_ALBC_ALBCLIN  = L.SERIE_ALBC_ALBCLIN ' +
      '                    AND L2.NUMERO_ALBC_ALBCLIN = L.NUMERO_ALBC_ALBCLIN '
        +
      '                    AND L2.CODIGO_UNIDAD_ALBCLIN = ' +
      'L.CODIGO_UNIDAD_ALBCLIN ' +
      '                    AND (IFNULL(L2.CANTIDAD_ALBCLIN, 0) > 0 ' +
      '                         OR EXISTS ( ' +
      '                            SELECT 1 FROM fza_albaranes_compra_celdas ' +
      'C2 ' +
      '                             WHERE C2.SERIE_ALBC_ALBCCEL  = ' +
      'L2.SERIE_ALBC_ALBCLIN ' +
      '                               AND C2.NUMERO_ALBC_ALBCCEL = ' +
      'L2.NUMERO_ALBC_ALBCLIN ' +
      '                               AND CAST(C2.LINEA_ALBC_ALBCCEL AS ' +
      'UNSIGNED) ' +
      '                                   = CAST(L2.LINEA_ALBCLIN AS UNSIGNED) '
        +
      '                               AND C2.CANTIDAD_ALBCCEL > 0)) ' +
      '                    AND L2.LINEA_ALBCLIN > L.LINEA_ALBCLIN) ' +
      '       ) X ' +
      'ON DUPLICATE KEY UPDATE ' +
      '  PRECIO_ULT_COMPRA_SKUC = IF(VALUES(FECHA_ULT_COMPRA_SKUC) >= ' +
      '    IFNULL(FECHA_ULT_COMPRA_SKUC, ''1000-01-01''), ' +
      '    VALUES(PRECIO_ULT_COMPRA_SKUC), PRECIO_ULT_COMPRA_SKUC), ' +
      '  FECHA_ULT_COMPRA_SKUC = GREATEST(' +
      '    IFNULL(FECHA_ULT_COMPRA_SKUC, ''1000-01-01''), ' +
      '    VALUES(FECHA_ULT_COMPRA_SKUC)), ' +
      '  INSTANTE_MODIF = NOW(), USUARIO_MODIF = :u3';
    q.ParamByName('s').AsString  := ASerieAlbc;
    q.ParamByName('n').AsString  := ANumAlbc;
    q.ParamByName('u1').AsString := AUsuario;
    q.ParamByName('u2').AsString := AUsuario;
    q.ParamByName('u3').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure PrepararInsercionMovimiento(AConn: TUniConnection;
                                      AProcedimiento: TUniStoredProc);
begin
  AProcedimiento.Connection := AConn;
  AProcedimiento.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
  AProcedimiento.Params.Clear;
  AProcedimiento.Params.CreateParam(ftString, 'p_NUMERO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_TIPO_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_NRO_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_LINEA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString,
    'p_CODIGO_ALMACEN_CONTRA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_TIPO_MOVIMIENTO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_CANTIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_PRECIO_MEDIO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_TOTAL_COSTE_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_ALMACEN_DOC', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_NUMOP_DOC', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_CAJA_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODCLIENTE', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODARTICULO', ptInput);
end;
// Genera movimientos de entrada (TIPO_DOC_MOV='AC', TIPO_MOV='E') para
// todas las celdas con cantidad > 0 del albaran, o para sus lineas
// cuando no haya celdas. AConn debe estar viva; la transaccion la
// gestiona el llamante (este procedimiento no abre ni cierra
// transacciones).
procedure GenerarMovimientosDesdeAlbaranCompra(AConn: TUniConnection;
                                               const ASerieAlbc, ANumAlbc,
                                                     AUsuario: string;
  const AActivacion: TActivacionTrazabilidad);
var
  qSrc, qChk: TUniQuery;
  spIns: TUniStoredProc;
  spInsLote: TUniStoredProc;
  sCodigoEmp, sCodigoAlmCab, sCodigoAlm, sCodigoSku, sCodigoArt,
  sNumeroMov, sLinea, sTipoMov: string;
  dtInstanteMovimiento: TDateTime;
  iCount: Integer;
  rCantidad, rPrecio, rTotal: Double;
begin
  LeerCabeceraAlbaran(AConn, ASerieAlbc, ANumAlbc, sCodigoEmp, sCodigoAlmCab,
                      dtInstanteMovimiento);
  // Sanidad: bloquear doble generacion. Si ya hay movs del albaran, no
  // generamos otra vez. La reversion debe llamarse explicita antes.
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := AConn;
    qChk.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = :t ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n';
    qChk.ParamByName('t').AsString :=
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
    qChk.ParamByName('s').AsString := ASerieAlbc;
    qChk.ParamByName('n').AsString := ANumAlbc;
    qChk.Open;
    if qChk.FieldByName('N').AsInteger > 0 then
      raise Exception.CreateFmt(SErrorAlbaranCompraMovimientosYaGenerados,
                                [ASerieAlbc, ANumAlbc]);
  finally
    FreeAndNil(qChk);
  end;
  qSrc := TUniQuery.Create(nil);
  spIns := TUniStoredProc.Create(nil);
  spInsLote := TUniStoredProc.Create(nil);
  try
    qSrc.Connection := AConn;
    // Union de dos selects:
    //   A) Lineas SIN celdas con cantidad <> 0: un movimiento por linea.
    //   B) Celdas con cantidad <> 0: un movimiento por celda.
    // Asi cubrimos el flujo de materializacion (que solo escribe
    // lineas) y el de edicion manual con tallas (que escribe celdas).
    qSrc.SQL.Text := SqlOrigenMovimientosAlbaranCompra;
    qSrc.ParamByName('s1').AsString      := ASerieAlbc;
    qSrc.ParamByName('n1').AsString      := ANumAlbc;
    qSrc.ParamByName('alm_cab1').AsString := sCodigoAlmCab;
    qSrc.ParamByName('s2').AsString      := ASerieAlbc;
    qSrc.ParamByName('n2').AsString      := ANumAlbc;
    qSrc.ParamByName('alm_cab2').AsString := sCodigoAlmCab;
    qSrc.Open;
    PrepararInsercionMovimiento(AConn, spIns);
    iCount := 0;
    while not qSrc.Eof do
    begin
      sCodigoSku := qSrc.FieldByName('SKU').AsString;
      sCodigoArt := qSrc.FieldByName('ARTICULO').AsString;
      sCodigoAlm := qSrc.FieldByName('ALMACEN').AsString;
      rCantidad  := qSrc.FieldByName('CANTIDAD').AsFloat;
      rPrecio    := qSrc.FieldByName('PRECIO').AsFloat;
      // La línea negativa es una devolución al proveedor: sale al PMP.
      sTipoMov   := TipoMovimientoStockLinea(
        EstrategiaAlbaranCompra.TipoMovimientoStock, rCantidad);
      rCantidad  := Abs(rCantidad);
      // FZ-ISSUE-205: el coste valorado, a centimos como el documento.
      rTotal     := RedondearACentimos(rCantidad * rPrecio);
      // Lineas sin SKU no pueden mover stock; las saltamos. No es
      // fatal porque pueden ser lineas de servicio o lineas en
      // construccion. Lo mismo para sin almacen efectivo.
      if (sCodigoSku <> '') and (sCodigoAlm <> '') then
      begin
        sNumeroMov := ObtenerSiguienteContador(
          AConn, 'MV', AUsuario);
      // LINEA_ALBCLIN ya viene en formato '0010', '0020', etc. Lo
      // reusamos tal cual como LINEA_MOV.
      sLinea := qSrc.FieldByName('LINEA').AsString;
      spIns.ParamByName('p_NUMERO_MOV').AsString          := sNumeroMov;
      spIns.ParamByName('p_TIPO_DOC_MOV').AsString :=
        EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
      spIns.ParamByName('p_SERIE_DOC_MOV').AsString       := ASerieAlbc;
      spIns.ParamByName('p_NRO_DOC_MOV').AsString         := ANumAlbc;
      spIns.ParamByName('p_LINEA_MOV').AsString           := sLinea;
      spIns.ParamByName('p_CODIGO_EMPRESA_MOV').AsString  := sCodigoEmp;
      spIns.ParamByName('p_CODIGO_ALMACEN_MOV').AsString  := sCodigoAlm;
      spIns.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
      spIns.ParamByName('p_CODIGO_UNIDAD_MOV').AsString   := sCodigoSku;
      spIns.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := sTipoMov;
      spIns.ParamByName('p_CANTIDAD_MOV').AsFloat         := rCantidad;
      spIns.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat     := rPrecio;
      spIns.ParamByName('p_TOTAL_COSTE_MOV').AsFloat      := rTotal;
      spIns.ParamByName('p_USUARIO').AsString             := AUsuario;
      spIns.ParamByName('p_ALMACEN_DOC').AsString         := sCodigoAlm;
      spIns.ParamByName('p_NUMOP_DOC').AsString           := '';
      spIns.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
      spIns.ParamByName('p_CODCLIENTE').AsString          := '';
      spIns.ParamByName('p_CODARTICULO').AsString         := sCodigoArt;
      // F-LOTEC-013: con lote o serie, ..._INSERT_LOTE.
      EjecutarMovimientoConLote(spIns, spInsLote,
        qSrc.FieldByName('LOTE').AsString,
        FechaCaducidadMovimiento(qSrc), AActivacion);
        Inc(iCount);
      end;
      qSrc.Next;
    end;
    if iCount = 0 then
      raise Exception.CreateFmt(
        SErrorAlbaranCompraSinCantidadParaMovimientos,
        [ASerieAlbc, ANumAlbc]);
    ActualizarArticulosProveedorDesdeAlbaranCompra(AConn, ASerieAlbc,
      ANumAlbc, AUsuario);
    ActualizarCostesSkuDesdeAlbaranCompra(AConn, ASerieAlbc, ANumAlbc,
      AUsuario);
    FecharYEncolarMovimientosDocumento(
      AConn,
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock,
      ASerieAlbc,
      ANumAlbc,
      dtInstanteMovimiento,
      'ALBARAN_COMPRA',
      AUsuario);
  finally
    FreeAndNil(qSrc);
    FreeAndNil(spInsLote);
    FreeAndNil(spIns);
  end;
end;
procedure RevertirMovimientosDesdeAlbaranCompra(AConn: TUniConnection;
                                                 const ASerieAlbc, ANumAlbc,
                                                       AUsuario: string);
var
  qExec: TUniQuery;
begin
  qExec  := TUniQuery.Create(nil);
  try
    qExec.Connection  := AConn;
    qExec.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    qExec.ParamByName('t').AsString :=
      EstrategiaAlbaranCompra.TipoDocumentoMovimientoStock;
    qExec.ParamByName('s').AsString := ASerieAlbc;
    qExec.ParamByName('n').AsString := ANumAlbc;
    qExec.ExecSQL;
  finally
    FreeAndNil(qExec);
  end;
end;
constructor TMovimientosAlbaranCompraUniDAC.Create(
  AConexion: TUniConnection;
  const AActivacion: TActivacionTrazabilidad);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FActivacion := AActivacion;
end;
procedure TMovimientosAlbaranCompraUniDAC.GenerarDesdeAlbaran(
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  GenerarMovimientosDesdeAlbaranCompra(
    FConexion, ASerieAlbc, ANumAlbc, AUsuario, FActivacion);
end;
procedure TMovimientosAlbaranCompraUniDAC.RevertirDesdeAlbaran(
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  RevertirMovimientosDesdeAlbaranCompra(
    FConexion, ASerieAlbc, ANumAlbc, AUsuario);
end;
function CrearMovimientosAlbaranCompraUniDAC(
  AConexion: TUniConnection): IMovimientosAlbaranCompra;
begin
  Result := CrearMovimientosAlbaranCompraUniDAC(
    AConexion, ActivacionVigente);
end;

function CrearMovimientosAlbaranCompraUniDAC(AConexion: TUniConnection;
  const AActivacion: TActivacionTrazabilidad): IMovimientosAlbaranCompra;
begin
  Result := TMovimientosAlbaranCompraUniDAC.Create(AConexion, AActivacion);
end;
end.
