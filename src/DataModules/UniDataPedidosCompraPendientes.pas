{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraPendientes                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sincronización de pendientes y estado de pedidos de compra.              }
{******************************************************************************}
unit UniDataPedidosCompraPendientes;
interface
uses
  Uni, inLibPedidosCompraIntf;
function CrearPendientesPedidoCompraUniDAC(
  AConexion: TUniConnection): IPedidosCompraPendientes;
procedure RecalcularEstadoPedido(AConn: TUniConnection;
  const ASeriePedc, ANumPedc, AUsuario: string);
procedure GenerarPdteRecibirDesdePedidoInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, AUsuario: string);
procedure BorrarPdteRecibirDesdePedidoInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ALinea: string);
function CalcularPendienteTotalInterno(AConn: TUniConnection;
  const ASeriePedc, ANumPedc: string): Double;
implementation
uses
  System.SysUtils, Data.DB, DBAccess;
type
  TPedidosCompraPendientesUniDAC = class(
    TInterfacedObject, IPedidosCompraPendientes)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure GenerarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc, AUsuario: string);
    procedure BorrarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc: string;
      const ALinea: string = '');
    function CalcularPendienteTotal(
      const ASeriePedc, ANumPedc: string): Double;
  end;
// Recalcula ESTADO_PEDC en funcion de la cantidad pendiente total.
// Reglas:
//   * Pedido sin lineas o cancelado por el usuario: no se toca.
//   * Total recibido == total pedido (pendiente <= 0): RECIBIDO.
//   * Algo recibido pero no todo: PARCIAL.
//   * Nada recibido: ABIERTO.
procedure RecalcularEstadoPedido(AConn: TUniConnection;
                                  const ASeriePedc, ANumPedc,
                                        AUsuario: string);
var
  q: TUniQuery;
  rPedida, rRecibida: Double;
  sEstado, sEstadoActual: string;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(SUM(CANTIDAD_PEDCLIN),0)           AS PEDIDA, ' +
      '       IFNULL(SUM(CANTIDAD_RECIBIDA_PEDCLIN),0)  AS RECIBIDA ' +
      '  FROM fza_pedidos_compra_lineas ' +
      ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND NUMERO_PEDC_PEDCLIN = :n';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    rPedida   := q.FieldByName('PEDIDA').AsFloat;
    rRecibida := q.FieldByName('RECIBIDA').AsFloat;
    q.Close;
    q.SQL.Text :=
      'SELECT ESTADO_PEDC FROM fza_pedidos_compra ' +
      ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    if not q.Eof then
    begin
      sEstadoActual := UpperCase(Trim(
        q.FieldByName('ESTADO_PEDC').AsString));
      q.Close;
      // Un pedido cancelado por el usuario conserva su estado.
      if sEstadoActual <> 'CANCELADO' then
      begin
        if rPedida <= 0 then
          sEstado := 'ABIERTO'
        else if rRecibida + 0.000001 >= rPedida then
          sEstado := 'RECIBIDO'
        else if rRecibida > 0 then
          sEstado := 'PARCIAL'
        else
          sEstado := 'ABIERTO';
        if sEstado <> sEstadoActual then
        begin
          q.SQL.Text :=
            'UPDATE fza_pedidos_compra ' +
            '   SET ESTADO_PEDC    = :e, ' +
            '       USUARIO_MODIF  = :u, ' +
            '       INSTANTE_MODIF = NOW() ' +
            ' WHERE SERIE_PEDC = :s AND NUMERO_PEDC = :n';
          q.ParamByName('e').AsString := sEstado;
          q.ParamByName('u').AsString := AUsuario;
          q.ParamByName('s').AsString := ASeriePedc;
          q.ParamByName('n').AsString := ANumPedc;
          q.ExecSQL;
        end;
      end;
    end;
  finally
    FreeAndNil(q);
  end;
end;
procedure BorrarPdteRecibirDesdePedidoInterno(AConn: TUniConnection;
                                        const ASeriePedc, ANumPedc: string;
                                        const ALinea: string);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    if ALinea = '' then
    begin
      q.SQL.Text :=
        'DELETE FROM fza_articulos_pdte_recibir ' +
        ' WHERE SERIE_DOC_PDR  = :s ' +
        '   AND NUMERO_DOC_PDR = :n';
      q.ParamByName('s').AsString := ASeriePedc;
      q.ParamByName('n').AsString := ANumPedc;
    end
    else
    begin
      q.SQL.Text :=
        'DELETE FROM fza_articulos_pdte_recibir ' +
        ' WHERE SERIE_DOC_PDR  = :s ' +
        '   AND NUMERO_DOC_PDR = :n ' +
        '   AND LINEA_PDR      = :l';
      q.ParamByName('s').AsString  := ASeriePedc;
      q.ParamByName('n').AsString  := ANumPedc;
      q.ParamByName('l').AsInteger := StrToIntDef(ALinea, 0);
    end;
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;
procedure GenerarPdteRecibirDesdePedidoInterno(AConn: TUniConnection;
                                         const ASeriePedc, ANumPedc,
                                               AUsuario: string);
var
  q, qIns: TUniQuery;
  sSku, sArt, sAlm, sPrv, sEmp: string;
  rPendiente, rPrecio: Double;
  iLinea: Integer;
  dFechaPed, dFechaPrev: TDateTime;
  bFechaPrevNull: Boolean;
begin
  // Borramos todo lo que habia y reinsertamos. Mucho mas simple que un
  // diff y los pedidos no suelen tener mas de unas decenas de lineas.
  BorrarPdteRecibirDesdePedidoInterno(
    AConn, ASeriePedc, ANumPedc, '');
  q    := TUniQuery.Create(nil);
  qIns := TUniQuery.Create(nil);
  try
    dFechaPrev := 0;
    q.Connection    := AConn;
    qIns.Connection := AConn;
    q.SQL.Text :=
      'SELECT L.LINEA_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
      '       L.CODIGO_ART_PEDCLIN, ' +
      '       IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) AS ALM_EFE, ' +
      '       L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) AS ' +
      'PENDIENTE, ' +
      '       CASE WHEN IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') ' +
      '<> ''S'' ' +
      '             AND IFNULL(P.ESIVA_RECARGO_COMPRAS_PEDC, ''N'') = ''S'' ' +
      '            THEN L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN * ' +
      '              (1 + (IFNULL(L.PORCENTAJE_IVA_PEDCLIN, 0) + ' +
      '                CASE IFNULL(L.TIPO_IVA_ARTICULO_PEDCLIN, ''N'') ' +
      '                  WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) '
        +
      '                  WHEN ''R'' THEN ' +
      'IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
      '                  WHEN ''S'' THEN ' +
      'IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
      '                  WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) '
        +
      '                  ELSE 0 END) / 100) ' +
      '            ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN END * ' +
      '       CASE WHEN IFNULL(P.TOTAL_BRUTO_PEDC, 0) > 0 THEN ' +
      '              GREATEST(0, 1 - CASE ' +
      '                WHEN IFNULL(P.TOTAL_DTO_COMERCIAL_PEDC, 0) <> 0 ' +
      '                THEN IFNULL(P.TOTAL_DTO_COMERCIAL_PEDC, 0) / ' +
      'P.TOTAL_BRUTO_PEDC ' +
      '                ELSE IFNULL(P.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100 ' +
      'END) ' +
      '            ELSE GREATEST(0, 1 - ' +
      'IFNULL(P.PORCENTAJE_DTO_COMERCIAL_PEDC, 0) / 100) ' +
      '       END AS PRECIO, ' +
      '       P.CODIGO_PRV_PEDC, P.CODIGO_EMP_PEDC, ' +
      '       P.FECHA_PEDC, P.FECHA_PREVISTA_PEDC ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC  = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      '  LEFT JOIN fza_ivas V ON V.CODIGO_IVA = P.CODIGO_IVA_PEDC ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :n ' +
      '   AND L.CODIGO_UNIDAD_PEDCLIN IS NOT NULL ' +
      '   AND L.CODIGO_UNIDAD_PEDCLIN <> '''' ' +
      '   AND L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN,0) > 0';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    while not q.Eof do
    begin
      iLinea     := StrToIntDef(q.FieldByName('LINEA_PEDCLIN').AsString, 0);
      sSku       := q.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
      sArt       := q.FieldByName('CODIGO_ART_PEDCLIN').AsString;
      sAlm       := q.FieldByName('ALM_EFE').AsString;
      rPendiente := q.FieldByName('PENDIENTE').AsFloat;
      rPrecio    := q.FieldByName('PRECIO').AsFloat;
      sPrv       := q.FieldByName('CODIGO_PRV_PEDC').AsString;
      sEmp       := q.FieldByName('CODIGO_EMP_PEDC').AsString;
      // Fecha pedido: si la cabecera no tiene fecha, usamos hoy.
      if q.FieldByName('FECHA_PEDC').IsNull then
        dFechaPed := Date
      else
        dFechaPed := q.FieldByName('FECHA_PEDC').AsDateTime;
      bFechaPrevNull := q.FieldByName('FECHA_PREVISTA_PEDC').IsNull;
      if not bFechaPrevNull then
        dFechaPrev := q.FieldByName('FECHA_PREVISTA_PEDC').AsDateTime;
      // Defensa: sin almacen no podemos enganchar el compromiso a ningun
      // sitio. Saltamos esa linea — el usuario corrige y vuelve a grabar.
      if (sSku <> '') and (sAlm <> '') and (rPendiente > 0) then
      begin
        qIns.SQL.Text :=
          'INSERT INTO fza_articulos_pdte_recibir ' +
          '  (CODIGO_UNIDAD_PDR, CODIGO_ALM_PDR, ' +
          '   SERIE_DOC_PDR, NUMERO_DOC_PDR, LINEA_PDR, ' +
          '   CODIGO_ART_PDR, CODIGO_PRV_PDR, CODIGO_EMP_PDR, ' +
          '   CANTIDAD_PDR, PRECIO_COMPRA_PDR, FECHA_PEDIDO_PDR, ' +
          '   FECHA_PREVISTA_PDR, INSTANTE_ALTA, USUARIO_ALTA, ' +
          '   INSTANTE_MODIF, USUARIO_MODIF) ' +
          'VALUES (:sku, :alm, :s, :n, :l, :art, :prv, :emp, ' +
          '        :qty, :pre, :fped, :fprev, NOW(), :u, NOW(), :u) ' +
          'ON DUPLICATE KEY UPDATE ' +
          '  CANTIDAD_PDR        = :qty, ' +
          '  PRECIO_COMPRA_PDR   = :pre, ' +
          '  FECHA_PEDIDO_PDR    = :fped, ' +
          '  FECHA_PREVISTA_PDR  = :fprev, ' +
          '  INSTANTE_MODIF      = NOW(), ' +
          '  USUARIO_MODIF       = :u';
        qIns.ParamByName('sku').AsString := sSku;
        qIns.ParamByName('alm').AsString := sAlm;
        qIns.ParamByName('s').AsString := ASeriePedc;
        qIns.ParamByName('n').AsString := ANumPedc;
        qIns.ParamByName('l').AsInteger := iLinea;
        qIns.ParamByName('art').AsString := sArt;
        qIns.ParamByName('prv').AsString := sPrv;
        qIns.ParamByName('emp').AsString := sEmp;
        qIns.ParamByName('qty').AsFloat := rPendiente;
        qIns.ParamByName('pre').AsFloat := rPrecio;
        qIns.ParamByName('fped').AsDateTime := dFechaPed;
        if bFechaPrevNull then
          qIns.ParamByName('fprev').Clear
        else
          qIns.ParamByName('fprev').AsDateTime := dFechaPrev;
        qIns.ParamByName('u').AsString := AUsuario;
        qIns.ExecSQL;
      end;
      q.Next;
    end;
  finally
    FreeAndNil(q);
    FreeAndNil(qIns);
  end;
end;
function CalcularPendienteTotalInterno(AConn: TUniConnection;
                                 const ASeriePedc, ANumPedc: string): Double;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(SUM(CANTIDAD_PEDCLIN - ' +
      '              IFNULL(CANTIDAD_RECIBIDA_PEDCLIN,0)),0) AS PEND ' +
      '  FROM fza_pedidos_compra_lineas ' +
      ' WHERE SERIE_PEDC_PEDCLIN  = :s ' +
      '   AND NUMERO_PEDC_PEDCLIN = :n';
    q.ParamByName('s').AsString := ASeriePedc;
    q.ParamByName('n').AsString := ANumPedc;
    q.Open;
    Result := q.FieldByName('PEND').AsFloat;
  finally
    FreeAndNil(q);
  end;
end;
// Mayor numero de linea (LINEA_ALBCLIN) ya presente en un albaran de
// compra; 0 si no tiene lineas. Sirve para continuar la numeracion al
// incorporar lineas a un albaran existente.
constructor TPedidosCompraPendientesUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;
procedure TPedidosCompraPendientesUniDAC.
  GenerarPdteRecibirDesdePedido(
  const ASeriePedc, ANumPedc, AUsuario: string);
begin
  GenerarPdteRecibirDesdePedidoInterno(
    FConexion, ASeriePedc, ANumPedc, AUsuario);
end;
procedure TPedidosCompraPendientesUniDAC.
  BorrarPdteRecibirDesdePedido(
  const ASeriePedc, ANumPedc, ALinea: string);
begin
  BorrarPdteRecibirDesdePedidoInterno(
    FConexion, ASeriePedc, ANumPedc, ALinea);
end;
function TPedidosCompraPendientesUniDAC.CalcularPendienteTotal(
  const ASeriePedc, ANumPedc: string): Double;
begin
  Result := CalcularPendienteTotalInterno(
    FConexion, ASeriePedc, ANumPedc);
end;
function CrearPendientesPedidoCompraUniDAC(
  AConexion: TUniConnection): IPedidosCompraPendientes;
begin
  Result := TPedidosCompraPendientesUniDAC.Create(AConexion);
end;
end.
