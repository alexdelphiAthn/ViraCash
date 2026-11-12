{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraAlbaranComun                              }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operaciones comunes para finalizar albaranes originados en pedidos.      }
{******************************************************************************}
unit UniDataPedidosCompraAlbaranComun;
interface
uses
  Uni;
function BloquearPedidoCompra(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido: string): Boolean;
function BloquearAlbaranCompra(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran: string): Boolean;
procedure RecalcularTotalesAlbaranCompra(AConn: TUniConnection;
  const ASerieAlbc, ANumAlbc, AUsuario: string);
procedure CerrarAlbaranCompra(AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string);
procedure AplicarTemporadaArticulosAlbaran(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
procedure FinalizarAlbaranCreado(AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
    ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
procedure RegenerarMovimientosYCerrarAlbaranCompra(
  AConn: TUniConnection;
  const ASerieAlbc, ANumAlbc, ASeriePedc, ANumPedc,
    AUsuario: string; AIdPvTemporada: Integer);
implementation
uses
  System.SysUtils, Data.DB, DBAccess,
  inLibAlbaranesCompraMovimientos,
  UniDataAlbaranesCompraMovimientos,
  UniDataPedidosCompraPendientes,
  UniDataPrestaShopEncolado;
function BloquearPedidoCompra(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT SERIE_PEDC FROM fza_pedidos_compra ' +
      ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n ' +
      '   AND IFNULL(ESTADO_PEDC, '''') NOT IN ' +
      '       (''CANCELADO'', ''RECIBIDO'', ''FACTURADO'') ' +
      ' FOR UPDATE';
    Consulta.ParamByName('s').AsString := ASeriePedido;
    Consulta.ParamByName('n').AsString := ANumeroPedido;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;
function BloquearAlbaranCompra(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran: string): Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT SERIE_ALBC FROM fza_albaranes_compra ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n ' +
      '   AND IFNULL(ESTADO_ALBC, '''') NOT IN ' +
      '       (''FACTURADO'', ''CANCELADO'') ' +
      ' FOR UPDATE';
    Consulta.ParamByName('s').AsString := ASerieAlbaran;
    Consulta.ParamByName('n').AsString := ANumeroAlbaran;
    Consulta.Open;
    Result := not Consulta.IsEmpty;
  finally
    FreeAndNil(Consulta);
  end;
end;
// FZ-ISSUE-207: mismos redondeos que el motor fiscal de la pantalla
// (CalcularTotalesDocumentoCompra): la base de cada linea, tras el
// descuento comercial, a centimos y sumada por tipo; la cuota de IVA y el
// recargo por tipo, a centimos. Antes se grababan sin redondear
// (1.470,3625) y el albaran creado desde un pedido no cuadraba al centimo.
function SqlTramoAlbaranCompra(const ATipo, ACampoRe: string): string;
begin
  Result :=
    '  SUM(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''' + ATipo +
    ''' THEN ROUND(L.TOTAL_ALBCLIN * GREATEST(0, 1 - ' +
    'IFNULL(H.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100), 2) ' +
    'ELSE 0 END) AS BASE_' + ATipo + ', ' +
    '  MAX(CASE WHEN L.TIPO_IVA_ARTICULO_ALBCLIN = ''' + ATipo +
    ''' THEN L.PORCENTAJE_IVA_ALBCLIN ELSE 0 END) AS PIVA_' + ATipo + ', ' +
    '  MAX(IFNULL(V.' + ACampoRe + ', 0)) AS PRE_' + ATipo + ', ';
end;

function SqlCuotasAlbaranCompra(const ATipo: string): string;
begin
  Result :=
    '  X.BASE_' + ATipo + ', ' +
    '  ROUND(X.BASE_' + ATipo + ' * X.PIVA_' + ATipo +
    ' / 100, 2) AS IVA_' + ATipo + ', ' +
    '  IF(X.APLICA_RE = 1, ROUND(X.BASE_' + ATipo + ' * X.PRE_' + ATipo +
    ' / 100, 2), 0) AS RE_' + ATipo + ', ';
end;

procedure RecalcularTotalesAlbaranCompra(AConn: TUniConnection;
                                  const ASerieAlbc, ANumAlbc,
                                        AUsuario: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'UPDATE fza_albaranes_compra C ' +
      '  JOIN ( ' +
      ' SELECT X.NUMERO, X.SERIE, X.BRUTO, X.NLIN, ' +
      SqlCuotasAlbaranCompra('N') +
      SqlCuotasAlbaranCompra('R') +
      SqlCuotasAlbaranCompra('S') +
      SqlCuotasAlbaranCompra('E') +
      '  X.BASE_N + X.BASE_R + X.BASE_S + X.BASE_E AS BASES ' +
      '   FROM ( ' +
      ' SELECT L.NUMERO_ALBC_ALBCLIN AS NUMERO, ' +
      '  L.SERIE_ALBC_ALBCLIN AS SERIE, ' +
      '  IFNULL(SUM(L.TOTAL_ALBCLIN), 0) AS BRUTO, ' +
      SqlTramoAlbaranCompra('N', 'PORCENTAJE_NORMAL_RE_IVA') +
      SqlTramoAlbaranCompra('R', 'PORCENTAJE_REDUCIDO_RE_IVA') +
      SqlTramoAlbaranCompra('S', 'PORCENTAJE_SUPERREDUCIDO_RE_IVA') +
      SqlTramoAlbaranCompra('E', 'PORCENTAJE_EXENTO_RE_IVA') +
      '  MAX(IFNULL(H.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') ' +
      '      <> ''S'' AND ' +
      '      IFNULL(H.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'') ' +
      '    AS APLICA_RE, ' +
      '  COUNT(*) AS NLIN ' +
      '   FROM fza_albaranes_compra_lineas L ' +
      '   JOIN fza_albaranes_compra H ' +
      '     ON H.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
      '    AND H.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
      '   LEFT JOIN fza_ivas V ON V.CODIGO_IVA = H.CODIGO_IVA_ALBC ' +
      '  WHERE L.NUMERO_ALBC_ALBCLIN = :n ' +
      '    AND L.SERIE_ALBC_ALBCLIN = :s ' +
      '  GROUP BY L.NUMERO_ALBC_ALBCLIN, L.SERIE_ALBC_ALBCLIN) X ' +
      '       ) T ' +
      '    ON T.NUMERO = C.NUMERO_ALBC ' +
      '   AND T.SERIE = C.SERIE_ALBC ' +
      '   SET C.TOTAL_BASEI_IVAN_ALBC = T.BASE_N, ' +
      '       C.TOTAL_BASEI_IVAR_ALBC = T.BASE_R, ' +
      '       C.TOTAL_BASEI_IVAS_ALBC = T.BASE_S, ' +
      '       C.TOTAL_BASEI_IVAE_ALBC = T.BASE_E, ' +
      '       C.TOTAL_IVAN_ALBC = T.IVA_N, ' +
      '       C.TOTAL_IVAR_ALBC = T.IVA_R, ' +
      '       C.TOTAL_IVAS_ALBC = T.IVA_S, ' +
      '       C.TOTAL_IVAE_ALBC = T.IVA_E, ' +
      '       C.TOTAL_REN_ALBC = T.RE_N, ' +
      '       C.TOTAL_RER_ALBC = T.RE_R, ' +
      '       C.TOTAL_RES_ALBC = T.RE_S, ' +
      '       C.TOTAL_REE_ALBC = T.RE_E, ' +
      '       C.TOTAL_BRUTO_ALBC = T.BRUTO, ' +
      '       C.TOTAL_DTO_COMERCIAL_ALBC = T.BRUTO - T.BASES, ' +
      '       C.TOTAL_DTO_FINANCIERO_ALBC = ROUND(T.BASES * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, 2), ' +
      '       C.TOTAL_BASES_ALBC = T.BASES, ' +
      '       C.TOTAL_RETENCION_ALBC = ROUND(T.BASES * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100, 2), ' +
      '       C.TOTAL_IMPUESTOS_ALBC = T.IVA_N + T.IVA_R + T.IVA_S + ' +
      'T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E, ' +
      '       C.TOTAL_LIQUIDO_ALBC = T.BASES + T.IVA_N + T.IVA_R + T.IVA_S + ' +
      'T.IVA_E + T.RE_N + T.RE_R + T.RE_S + T.RE_E - ROUND(T.BASES * ' +
      'IFNULL(C.PORCENTAJE_RETENCION_ALBC, 0) / 100, 2) - ROUND(T.BASES * ' +
      'IFNULL(C.PORCENTAJE_DTO_FINANCIERO_ALBC, 0) / 100, 2), ' +
      '       C.CONTADOR_LINEAS_ALBC = LPAD(T.NLIN * 10, 8, ''0''), ' +
      '       C.USUARIO_MODIF = :u, ' +
      '       C.INSTANTE_MODIF = NOW() ' +
      ' WHERE C.SERIE_ALBC = :s AND C.NUMERO_ALBC = :n';
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ParamByName('n').AsString := ANumAlbc;
    q.ParamByName('u').AsString := AUsuario;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure CerrarAlbaranCompra(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string);
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := AConexion;
    Query.SQL.Text :=
      'UPDATE fza_albaranes_compra ' +
      '   SET ESTADO_ALBC = ''CERRADO'', ' +
      '       USUARIO_MODIF = :u, INSTANTE_MODIF = NOW() ' +
      ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
    Query.ParamByName('s').AsString := ASerieAlbaran;
    Query.ParamByName('n').AsString := ANumeroAlbaran;
    Query.ParamByName('u').AsString := AUsuario;
    Query.ExecSQL;
  finally
    FreeAndNil(Query);
  end;
end;
procedure AplicarTemporadaArticulosAlbaran(
  AConexion: TUniConnection;
  const ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
var
  Query: TUniQuery;
begin
  if AIdPvTemporada > 0 then
  begin
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := AConexion;
      Query.SQL.Text :=
        'INSERT INTO fza_articulos_propiedades ' +
        '  (CODIGO_ART_ART, CODIGO_PROP_ARTPROP, ID_PV_ARTPROP, ' +
        '   VALOR_LIBRE_ARTPROP, INSTANTE_ALTA, USUARIO_ALTA) ' +
        'SELECT DISTINCT L.CODIGO_ART_ALBCLIN, ' +
        '       ''TEMPORADA'', :pv, NULL, NOW(), :u ' +
        '  FROM fza_albaranes_compra_lineas L ' +
        ' WHERE L.SERIE_ALBC_ALBCLIN = :s ' +
        '   AND L.NUMERO_ALBC_ALBCLIN = :n ' +
        '   AND L.CODIGO_ART_ALBCLIN IS NOT NULL ' +
        '   AND L.CODIGO_ART_ALBCLIN <> '''' ' +
        'ON DUPLICATE KEY UPDATE ID_PV_ARTPROP = :pv';
      Query.ParamByName('pv').AsInteger := AIdPvTemporada;
      Query.ParamByName('u').AsString := AUsuario;
      Query.ParamByName('s').AsString := ASerieAlbaran;
      Query.ParamByName('n').AsString := ANumeroAlbaran;
      Query.ExecSQL;
      if (Query.RowsAffected > 0) and
         PropiedadAfectaDescuentoPrestaShop(
           AConexion,
           'TEMPORADA',
           AUsuario) then
        EncolarTodosWebPrestaShop(
          AConexion,
          True,
          False,
          AUsuario);
    finally
      FreeAndNil(Query);
    end;
  end;
end;
procedure FinalizarAlbaranCreado(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ASerieAlbaran,
    ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
begin
  RecalcularTotalesAlbaranCompra(
    AConexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  inLibAlbaranesCompraMovimientos.
    GenerarMovimientosDesdeAlbaranCompra(
      CrearMovimientosAlbaranCompraUniDAC(AConexion),
      ASerieAlbaran, ANumeroAlbaran, AUsuario);
  CerrarAlbaranCompra(
    AConexion, ASerieAlbaran, ANumeroAlbaran, AUsuario);
  GenerarPdteRecibirDesdePedidoInterno(
    AConexion, ASeriePedido, ANumeroPedido, AUsuario);
  RecalcularEstadoPedido(
    AConexion, ASeriePedido, ANumeroPedido, AUsuario);
  AplicarTemporadaArticulosAlbaran(
    AConexion, ASerieAlbaran, ANumeroAlbaran,
    AUsuario, AIdPvTemporada);
end;
procedure RegenerarMovimientosYCerrarAlbaranCompra(AConn: TUniConnection;
                                  const ASerieAlbc, ANumAlbc,
                                        ASeriePedc, ANumPedc,
                                        AUsuario: string;
                                  AIdPvTemporada: Integer);
var
  qIns: TUniQuery;
begin
  RecalcularTotalesAlbaranCompra(AConn, ASerieAlbc, ANumAlbc, AUsuario);
  inLibAlbaranesCompraMovimientos.RevertirMovimientosDesdeAlbaranCompra(
    CrearMovimientosAlbaranCompraUniDAC(AConn),
    ASerieAlbc, ANumAlbc, AUsuario);
  inLibAlbaranesCompraMovimientos.GenerarMovimientosDesdeAlbaranCompra(
    CrearMovimientosAlbaranCompraUniDAC(AConn),
    ASerieAlbc, ANumAlbc, AUsuario);
  CerrarAlbaranCompra(AConn, ASerieAlbc, ANumAlbc, AUsuario);
  GenerarPdteRecibirDesdePedidoInterno(
    AConn, ASeriePedc, ANumPedc, AUsuario);
  RecalcularEstadoPedido(AConn, ASeriePedc, ANumPedc, AUsuario);
  if AIdPvTemporada > 0 then
  begin
    qIns := TUniQuery.Create(nil);
    try
      qIns.Connection := AConn;
      qIns.SQL.Text :=
        'UPDATE fza_albaranes_compra ' +
        '   SET ID_PV_TEMPORADA_ALBC = :pv ' +
        ' WHERE SERIE_ALBC = :s AND NUMERO_ALBC = :n';
      qIns.ParamByName('pv').AsInteger := AIdPvTemporada;
      qIns.ParamByName('s').AsString := ASerieAlbc;
      qIns.ParamByName('n').AsString := ANumAlbc;
      qIns.ExecSQL;
    finally
      FreeAndNil(qIns);
    end;
    AplicarTemporadaArticulosAlbaran(
      AConn, ASerieAlbc, ANumAlbc, AUsuario, AIdPvTemporada);
  end;
end;
end.
