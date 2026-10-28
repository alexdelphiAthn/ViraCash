{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturasCompraMovimientos                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    FZ-ISSUE-752: movimientos de almacén de las compras directas a            }
{    terceros (autofactura y recibo REAGP) que no tienen albarán. Con          }
{    ESMUEVE_STOCK_FACC = 'S', el cierre da una entrada por línea (o por       }
{    celda) en su almacén, con lote y caducidad, vía                           }
{    PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT(_LOTE); la reapertura los borra        }
{    con PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC, que recalcula PMP y stock.    }
{    TIPO_DOC_MOV = 'FP' (FACTURA DE COMPRAS en fza_tipos_documentos): no      }
{    choca con los albaranes AC de la misma serie y número. El coste es el     }
{    del albarán de compra: precio neto de descuento, más IVA y recargo        }
{    solo si la empresa está en recargo de equivalencia.                       }
{                                                                              }
{    La transacción la gestiona el llamante.                                   }
{******************************************************************************}
unit UniDataFacturasCompraMovimientos;

interface

uses
  Uni, inLibTrazabilidad;

const
  TIPO_DOC_MOV_FACTURA_COMPRA = 'FP';

// Entradas de stock de la factura ASerie/ANumero. Falla si ya las tiene.
procedure GenerarMovimientosFacturaCompra(AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario: string;
  const AActivacion: TActivacionTrazabilidad);
// Borra las entradas de la factura y recalcula PMP y stock.
procedure RevertirMovimientosFacturaCompra(AConexion: TUniConnection;
  const ASerie, ANumero: string);
function FacturaCompraTieneMovimientos(AConexion: TUniConnection;
  const ASerie, ANumero: string): Boolean;
// Líneas que meterían stock y líneas de stock sin almacén efectivo.
procedure ContarLineasStockFacturaCompra(AConexion: TUniConnection;
  const ASerie, ANumero, AAlmacenCabecera: string;
  out ALineasStock, ALineasSinAlmacen: Integer);
// Consulta de la pestaña «Movimientos»: parámetros SERIE y NUMERO.
function SqlMovimientosFacturaCompra: string;

implementation

uses
  System.SysUtils, Data.DB, inLibDocumento,
  UniDataValoresAutomaticosRepositorio, inLibMsgCompras,
  UniDataMovimientosAlmacenRecalculo, inLibRedondeo,
  UniDataMovimientosLote;

const
  // Coste unitario de la línea: como SqlOrigenMovimientosAlbaranCompra.
  SQL_PRECIO_COSTE =
    '       CASE WHEN IFNULL(F.ESIVA_EXENTO_INTRACOMUNITARIO_FACC, ' +
    '''N'') <> ''S'' ' +
    '             AND IFNULL(F.ESIVA_RECARGO_COMPRAS_FACC, ''N'') = ''S'' ' +
    '            THEN L.PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN * ' +
    '              (1 + (IFNULL(L.PORCENTAJE_IVA_FACCLIN, 0) + ' +
    '                CASE IFNULL(L.TIPO_IVA_ARTICULO_FACCLIN, ''N'') ' +
    '                  WHEN ''N'' THEN IFNULL(F.PORCENTAJE_REN_FACC, 0) ' +
    '                  WHEN ''R'' THEN IFNULL(F.PORCENTAJE_RER_FACC, 0) ' +
    '                  WHEN ''S'' THEN IFNULL(F.PORCENTAJE_RES_FACC, 0) ' +
    '                  WHEN ''E'' THEN IFNULL(F.PORCENTAJE_REE_FACC, 0) ' +
    '                  ELSE 0 END) / 100) ' +
    '            ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN END * ' +
    '       CASE WHEN IFNULL(F.TOTAL_BRUTO_FACC, 0) > 0 THEN ' +
    '              GREATEST(0, 1 - CASE ' +
    '                WHEN IFNULL(F.TOTAL_DTO_COMERCIAL_FACC, 0) <> 0 ' +
    '                THEN IFNULL(F.TOTAL_DTO_COMERCIAL_FACC, 0) / ' +
    '                     F.TOTAL_BRUTO_FACC ' +
    '                ELSE IFNULL(F.PORCENTAJE_DTO_COMERCIAL_FACC, 0) / 100 ' +
    '              END) ' +
    '            ELSE GREATEST(0, 1 - ' +
    '              IFNULL(F.PORCENTAJE_DTO_COMERCIAL_FACC, 0) / 100) ' +
    '       END AS PRECIO, ';
  SQL_LINEAS_FACTURA =
    '  FROM fza_facturas_compra_lineas L ' +
    '  JOIN fza_facturas_compra F ' +
    '    ON F.SERIE_FACC  = L.SERIE_FACC_FACCLIN ' +
    '   AND F.NUMERO_FACC = L.NUMERO_FACC_FACCLIN ';
  SQL_CELDAS_LINEA =
    '         SELECT 1 FROM fza_facturas_compra_celdas C ' +
    '          WHERE C.SERIE_FACC_FACCCEL  = L.SERIE_FACC_FACCLIN ' +
    '            AND C.NUMERO_FACC_FACCCEL = L.NUMERO_FACC_FACCLIN ' +
    '            AND CAST(C.LINEA_FACC_FACCCEL AS UNSIGNED) ' +
    '                = CAST(L.LINEA_FACCLIN AS UNSIGNED) ' +
    '            AND C.CANTIDAD_FACCCEL <> 0';

// Una entrada por línea sin celdas y una por celda con cantidad.
function SqlOrigenMovimientos: string;
begin
  Result :=
    'SELECT L.LINEA_FACCLIN AS LINEA, L.CODIGO_UNIDAD_FACCLIN AS SKU, ' +
    '       L.CODIGO_ART_FACCLIN AS ARTICULO, L.LOTE_FACCLIN AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_FACCLIN AS FECHA_CADUCIDAD, ' +
    '       L.CANTIDAD_FACCLIN AS CANTIDAD, ' +
    SQL_PRECIO_COSTE +
    '       IFNULL(NULLIF(L.CODIGO_ALMACEN_FACCLIN, ''''), ' +
    '              F.CODIGO_ALM_FACC) AS ALMACEN ' +
    SQL_LINEAS_FACTURA +
    ' WHERE L.SERIE_FACC_FACCLIN  = :s1 ' +
    '   AND L.NUMERO_FACC_FACCLIN = :n1 ' +
    '   AND IFNULL(L.CANTIDAD_FACCLIN, 0) <> 0 ' +
    '   AND NOT EXISTS (' + SQL_CELDAS_LINEA + ') ' +
    'UNION ALL ' +
    'SELECT L.LINEA_FACCLIN, L.CODIGO_UNIDAD_FACCLIN, ' +
    '       L.CODIGO_ART_FACCLIN, L.LOTE_FACCLIN, ' +
    '       L.FECHA_CADUCIDAD_FACCLIN, C.CANTIDAD_FACCCEL, ' +
    SQL_PRECIO_COSTE +
    '       IFNULL(NULLIF(C.CODIGO_ALM_FACCCEL, ''''), ' +
    '         IFNULL(NULLIF(L.CODIGO_ALMACEN_FACCLIN, ''''), ' +
    '                F.CODIGO_ALM_FACC)) ' +
    SQL_LINEAS_FACTURA +
    '  JOIN fza_facturas_compra_celdas C ' +
    '    ON C.SERIE_FACC_FACCCEL  = L.SERIE_FACC_FACCLIN ' +
    '   AND C.NUMERO_FACC_FACCCEL = L.NUMERO_FACC_FACCLIN ' +
    '   AND CAST(C.LINEA_FACC_FACCCEL AS UNSIGNED) ' +
    '       = CAST(L.LINEA_FACCLIN AS UNSIGNED) ' +
    ' WHERE L.SERIE_FACC_FACCLIN  = :s2 ' +
    '   AND L.NUMERO_FACC_FACCLIN = :n2 ' +
    '   AND C.CANTIDAD_FACCCEL <> 0 ' +
    ' ORDER BY LINEA';
end;

function SqlMovimientosFacturaCompra: string;
begin
  Result :=
    'SELECT M.NUMERO_MOV, M.FECHA_MOV, M.LINEA_MOV, ' +
    '       M.CODIGO_ALM_MOV, M.NOMBRE_ALMACEN_ORIGEN, ' +
    '       M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, ' +
    '       LEFT(COALESCE(M.DESCRIPCION_ARTICULO_MOV, ' +
    '                     A.DESCRIPCION_ART), 100) ' +
    '         AS DESCRIPCION_ARTICULO_MOV, ' +
    '       M.TIPO_MOV, M.CANTIDAD_MOV, M.LOTE_MOV, ' +
    '       M.FECHA_CADUCIDAD_MOV, ' +
    '       M.PRECIO_MEDIO_MOV, M.TOTAL_COSTE_MOV ' +
    '  FROM vi_movimientos M ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
    ' WHERE M.TIPO_DOC_MOV = ''' + TIPO_DOC_MOV_FACTURA_COMPRA + ''' ' +
    '   AND M.SERIE_DOC_MOV  = :SERIE ' +
    '   AND M.NUMERO_DOC_MOV = :NUMERO ' +
    ' ORDER BY M.LINEA_MOV, M.NUMERO_MOV';
end;

function FacturaCompraTieneMovimientos(AConexion: TUniConnection;
  const ASerie, ANumero: string): Boolean;
var
  qChk: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := AConexion;
    qChk.SQL.Text :=
      'SELECT COUNT(*) AS N ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE TIPO_DOC_MOV   = :t ' +
      '   AND SERIE_DOC_MOV  = :s ' +
      '   AND NUMERO_DOC_MOV = :n ' +
      '   AND ESACTIVO_MOV   = ''S''';
    qChk.ParamByName('t').AsString := TIPO_DOC_MOV_FACTURA_COMPRA;
    qChk.ParamByName('s').AsString := ASerie;
    qChk.ParamByName('n').AsString := ANumero;
    qChk.Open;
    Result := qChk.FieldByName('N').AsInteger > 0;
  finally
    FreeAndNil(qChk);
  end;
end;

procedure ContarLineasStockFacturaCompra(AConexion: TUniConnection;
  const ASerie, ANumero, AAlmacenCabecera: string;
  out ALineasStock, ALineasSinAlmacen: Integer);
var
  qChk: TUniQuery;
begin
  qChk := TUniQuery.Create(nil);
  try
    qChk.Connection := AConexion;
    qChk.SQL.Text :=
      'SELECT COUNT(*) AS N, ' +
      '       SUM(CASE WHEN IFNULL(NULLIF(L.CODIGO_ALMACEN_FACCLIN, ' +
      '                  ''''), :alm) = '''' THEN 1 ELSE 0 END) ' +
      '         AS SIN_ALMACEN ' +
      '  FROM fza_facturas_compra_lineas L ' +
      ' WHERE L.SERIE_FACC_FACCLIN  = :s ' +
      '   AND L.NUMERO_FACC_FACCLIN = :n ' +
      '   AND IFNULL(L.CODIGO_UNIDAD_FACCLIN, '''') <> '''' ' +
      '   AND IFNULL(L.CANTIDAD_FACCLIN, 0) <> 0';
    qChk.ParamByName('alm').AsString := Trim(AAlmacenCabecera);
    qChk.ParamByName('s').AsString := ASerie;
    qChk.ParamByName('n').AsString := ANumero;
    qChk.Open;
    ALineasStock := qChk.FieldByName('N').AsInteger;
    ALineasSinAlmacen := qChk.FieldByName('SIN_ALMACEN').AsInteger;
  finally
    FreeAndNil(qChk);
  end;
end;

function LeerFechaFactura(AConexion: TUniConnection;
  const ASerie, ANumero: string; out AEmpresa: string): TDateTime;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConexion;
    q.SQL.Text :=
      'SELECT CODIGO_EMP_FACC, ' +
      '       COALESCE(CAST(FECHA_FACC AS datetime), NOW()) AS FECHA ' +
      '  FROM fza_facturas_compra ' +
      ' WHERE SERIE_FACC = :s AND NUMERO_FACC = :n';
    q.ParamByName('s').AsString := ASerie;
    q.ParamByName('n').AsString := ANumero;
    q.Open;
    if q.Eof then
      raise Exception.CreateFmt(SErrorFacturaCompraMovimientosNoEncontrada,
        [ASerie, ANumero]);
    AEmpresa := q.FieldByName('CODIGO_EMP_FACC').AsString;
    Result := q.FieldByName('FECHA').AsDateTime;
  finally
    FreeAndNil(q);
  end;
end;

procedure PrepararInsercion(AConexion: TUniConnection;
  AProcedimiento: TUniStoredProc);
const
  CTexto: array[0..15] of string = ('p_NUMERO_MOV', 'p_TIPO_DOC_MOV',
    'p_SERIE_DOC_MOV', 'p_NRO_DOC_MOV', 'p_LINEA_MOV',
    'p_CODIGO_EMPRESA_MOV', 'p_CODIGO_ALMACEN_MOV',
    'p_CODIGO_ALMACEN_CONTRA_MOV', 'p_CODIGO_UNIDAD_MOV',
    'p_TIPO_MOVIMIENTO_MOV', 'p_USUARIO', 'p_ALMACEN_DOC', 'p_NUMOP_DOC',
    'p_CODIGO_CAJA_DOC_MOV', 'p_CODCLIENTE', 'p_CODARTICULO');
var
  iParametro: Integer;
begin
  AProcedimiento.Connection := AConexion;
  AProcedimiento.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
  AProcedimiento.Params.Clear;
  // Mismo orden que la firma del procedimiento.
  for iParametro := 0 to 9 do
    AProcedimiento.Params.CreateParam(ftString, CTexto[iParametro],
      ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_CANTIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_PRECIO_MEDIO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_TOTAL_COSTE_MOV', ptInput);
  for iParametro := 10 to High(CTexto) do
    AProcedimiento.Params.CreateParam(ftString, CTexto[iParametro],
      ptInput);
end;

procedure AsignarMovimiento(AProcedimiento: TUniStoredProc;
  AOrigen: TDataSet; const ASerie, ANumero, AEmpresa, AUsuario,
  ANumeroMov: string);
var
  rCantidad, rPrecio: Double;
  sAlmacen: string;
begin
  rCantidad := AOrigen.FieldByName('CANTIDAD').AsFloat;
  rPrecio := AOrigen.FieldByName('PRECIO').AsFloat;
  sAlmacen := AOrigen.FieldByName('ALMACEN').AsString;
  AProcedimiento.ParamByName('p_NUMERO_MOV').AsString := ANumeroMov;
  AProcedimiento.ParamByName('p_TIPO_DOC_MOV').AsString :=
    TIPO_DOC_MOV_FACTURA_COMPRA;
  AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString := ASerie;
  AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString := ANumero;
  AProcedimiento.ParamByName('p_LINEA_MOV').AsString :=
    AOrigen.FieldByName('LINEA').AsString;
  AProcedimiento.ParamByName('p_CODIGO_EMPRESA_MOV').AsString := AEmpresa;
  AProcedimiento.ParamByName('p_CODIGO_ALMACEN_MOV').AsString := sAlmacen;
  AProcedimiento.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear;
  AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString :=
    AOrigen.FieldByName('SKU').AsString;
  // La línea negativa es una devolución al tercero: sale al PMP.
  AProcedimiento.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString :=
    TipoMovimientoStockLinea('E', rCantidad);
  AProcedimiento.ParamByName('p_CANTIDAD_MOV').AsFloat := Abs(rCantidad);
  AProcedimiento.ParamByName('p_PRECIO_MEDIO_MOV').AsFloat := rPrecio;
  AProcedimiento.ParamByName('p_TOTAL_COSTE_MOV').AsFloat :=
    RedondearACentimos(Abs(rCantidad) * rPrecio);
  AProcedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
  AProcedimiento.ParamByName('p_ALMACEN_DOC').AsString := sAlmacen;
  AProcedimiento.ParamByName('p_NUMOP_DOC').AsString := '';
  AProcedimiento.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
  AProcedimiento.ParamByName('p_CODCLIENTE').AsString := '';
  AProcedimiento.ParamByName('p_CODARTICULO').AsString :=
    AOrigen.FieldByName('ARTICULO').AsString;
end;

procedure GenerarMovimientosFacturaCompra(AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario: string;
  const AActivacion: TActivacionTrazabilidad);
var
  qSrc: TUniQuery;
  spIns, spInsLote: TUniStoredProc;
  sEmpresa: string;
  dtFecha: TDateTime;
  iCount: Integer;
begin
  dtFecha := LeerFechaFactura(AConexion, ASerie, ANumero, sEmpresa);
  if FacturaCompraTieneMovimientos(AConexion, ASerie, ANumero) then
    raise Exception.CreateFmt(SErrorFacturaCompraMovimientosYaGenerados,
      [ASerie, ANumero]);
  qSrc := TUniQuery.Create(nil);
  spIns := TUniStoredProc.Create(nil);
  spInsLote := TUniStoredProc.Create(nil);
  try
    qSrc.Connection := AConexion;
    qSrc.SQL.Text := SqlOrigenMovimientos;
    qSrc.ParamByName('s1').AsString := ASerie;
    qSrc.ParamByName('n1').AsString := ANumero;
    qSrc.ParamByName('s2').AsString := ASerie;
    qSrc.ParamByName('n2').AsString := ANumero;
    qSrc.Open;
    PrepararInsercion(AConexion, spIns);
    iCount := 0;
    while not qSrc.Eof do
    begin
      // Sin SKU (servicios) o sin almacén efectivo no hay stock.
      if (qSrc.FieldByName('SKU').AsString <> '') and
         (qSrc.FieldByName('ALMACEN').AsString <> '') then
      begin
        AsignarMovimiento(spIns, qSrc, ASerie, ANumero, sEmpresa, AUsuario,
          ObtenerSiguienteContador(AConexion, 'MV', AUsuario));
        EjecutarMovimientoConLote(spIns, spInsLote,
          qSrc.FieldByName('LOTE').AsString,
          FechaCaducidadMovimiento(qSrc), AActivacion);
        Inc(iCount);
      end;
      qSrc.Next;
    end;
    if iCount = 0 then
      raise Exception.CreateFmt(SErrorCompraDirectaSinLineasStock,
        [ASerie, ANumero]);
    FecharYEncolarMovimientosDocumento(AConexion,
      TIPO_DOC_MOV_FACTURA_COMPRA, ASerie, ANumero, dtFecha,
      'FACTURA_COMPRA', AUsuario);
  finally
    FreeAndNil(qSrc);
    FreeAndNil(spInsLote);
    FreeAndNil(spIns);
  end;
end;

procedure RevertirMovimientosFacturaCompra(AConexion: TUniConnection;
  const ASerie, ANumero: string);
var
  qExec: TUniQuery;
begin
  qExec := TUniQuery.Create(nil);
  try
    qExec.Connection := AConexion;
    qExec.SQL.Text :=
      'CALL PRC_FZA_MOVIMIENTOS_ALMACEN_DELETE_DOC(:t, :s, :n)';
    qExec.ParamByName('t').AsString := TIPO_DOC_MOV_FACTURA_COMPRA;
    qExec.ParamByName('s').AsString := ASerie;
    qExec.ParamByName('n').AsString := ANumero;
    qExec.ExecSQL;
  finally
    FreeAndNil(qExec);
  end;
end;

end.
