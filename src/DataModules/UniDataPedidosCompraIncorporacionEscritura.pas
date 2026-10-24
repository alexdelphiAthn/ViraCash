{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraIncorporacionEscritura                    }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                               }
{    Escritura atómica al incorporar pedidos en albaranes de compra.          }
{******************************************************************************}
unit UniDataPedidosCompraIncorporacionEscritura;

interface

uses
  Uni,
  inLibGridPivoteCompraTipos;

type
  TEscrituraIncorporacionAlbaranCompra = class
  private
    FAlmacen: string;
    FConexion: TUniConnection;
    FIdPvTemporada: Integer;
    FNumeroAlbaran: string;
    FNumeroPedido: string;
    FSerieAlbaran: string;
    FSeriePedido: string;
    FUsuario: string;
    function BloquearOrigenYDestino(out AMensaje: string): Boolean;
    function MaxLineaAlbaranCompra(
      AConn: TUniConnection;
      const ASerieAlbc, ANumAlbc: string): Integer;
    function ValidarDestino(out AMensaje: string): Boolean;
    function HayPendientes(out AMensaje: string): Boolean;
    function ValidarCeldas(
      const ACeldas: TArray<TCeldaARecibir>;
      out AMensaje: string): Boolean;
    procedure ConfigurarOrigenPendientes(AConsulta: TUniQuery);
    procedure ConfigurarOrigenLinea(AConsulta: TUniQuery);
    procedure ConfigurarInsercion(AConsulta: TUniQuery);
    procedure InsertarLinea(
      AOrigen, AEscritura: TUniQuery;
      const ALineaAlbaran, ALineaPedido, ACodigoSku: string;
      ACantidad: Double; const ACelda: TCeldaARecibir);
    procedure ActualizarCantidadRecibida(
      AConsulta: TUniQuery;
      const ALineaPedido: string;
      ACantidad: Double);
    procedure CerrarAlbaran;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ASeriePedido, ANumeroPedido, AAlmacen,
        ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
      AIdPvTemporada: Integer);
    function IncorporarPendientes(out AMensaje: string): Boolean;
    function IncorporarCeldas(
      const ACeldas: TArray<TCeldaARecibir>;
      out AMensaje: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,
  inLibMsgCompras,
  UniDataPedidosCompraAlbaranComun,
  UniDataPedidosCompraRecepcionLotes,
  inLibPrestaShopColaSenal;

function TEscrituraIncorporacionAlbaranCompra.MaxLineaAlbaranCompra(
  AConn: TUniConnection;
  const ASerieAlbc, ANumAlbc: string): Integer;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := AConn;
    q.SQL.Text :=
      'SELECT IFNULL(MAX(CAST(LINEA_ALBCLIN AS UNSIGNED)),0) AS MAXLIN ' +
      '  FROM fza_albaranes_compra_lineas ' +
      ' WHERE SERIE_ALBC_ALBCLIN  = :s ' +
      '   AND NUMERO_ALBC_ALBCLIN = :n';
    q.ParamByName('s').AsString := ASerieAlbc;
    q.ParamByName('n').AsString := ANumAlbc;
    q.Open;
    Result := q.FieldByName('MAXLIN').AsInteger;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;

constructor TEscrituraIncorporacionAlbaranCompra.Create(
  AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, AAlmacen,
    ASerieAlbaran, ANumeroAlbaran, AUsuario: string;
  AIdPvTemporada: Integer);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FSeriePedido := ASeriePedido;
  FNumeroPedido := ANumeroPedido;
  FAlmacen := AAlmacen;
  FSerieAlbaran := ASerieAlbaran;
  FNumeroAlbaran := ANumeroAlbaran;
  FUsuario := AUsuario;
  FIdPvTemporada := AIdPvTemporada;
end;

function TEscrituraIncorporacionAlbaranCompra.BloquearOrigenYDestino(
  out AMensaje: string): Boolean;
begin
  Result := BloquearPedidoCompra(
    FConexion, FSeriePedido, FNumeroPedido);
  if not Result then
    AMensaje := SErrorPedidoCompraNoActivoCrearAlbaran;
  if Result then
  begin
    Result := BloquearAlbaranCompra(
      FConexion, FSerieAlbaran, FNumeroAlbaran);
    if not Result then
      AMensaje := SErrorAlbaranCompraNoActivo;
  end;
end;

function TEscrituraIncorporacionAlbaranCompra.ValidarDestino(
  out AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := Trim(FAlmacen) <> '';
  if not Result then
    AMensaje := SErrorAlmacenPedidoCompraNoSeleccionado;
  if Result then
  begin
    Result := (Trim(FSerieAlbaran) <> '') and
      (Trim(FNumeroAlbaran) <> '');
    if not Result then
      AMensaje := SErrorAlbaranCompraDestinoNoSeleccionado;
  end;
end;

function TEscrituraIncorporacionAlbaranCompra.HayPendientes(
  out AMensaje: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_pedidos_compra_lineas L ' +
      'JOIN fza_pedidos_compra P ' +
      'ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
      'AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      'WHERE L.SERIE_PEDC_PEDCLIN = :SERIE ' +
      'AND L.NUMERO_PEDC_PEDCLIN = :NUMERO ' +
      'AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      'P.CODIGO_ALM_PEDC) = :ALMACEN ' +
      'AND L.CANTIDAD_PEDCLIN - ' +
      'IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN, 0) > 0';
    oConsulta.ParamByName('SERIE').AsString := FSeriePedido;
    oConsulta.ParamByName('NUMERO').AsString := FNumeroPedido;
    oConsulta.ParamByName('ALMACEN').AsString := FAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger > 0;
    if not Result then
      AMensaje := Format(SErrorPedidoCompraSinPendientesAlmacen,
        [FAlmacen, FSeriePedido, FNumeroPedido]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TEscrituraIncorporacionAlbaranCompra.ValidarCeldas(
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
var
  oCelda: TCeldaARecibir;
  dTotal: Double;
begin
  dTotal := 0;
  for oCelda in ACeldas do
  begin
    if SameText(oCelda.CodigoAlmacen, FAlmacen) and
      (oCelda.Cantidad > 0) then
      dTotal := dTotal + oCelda.Cantidad;
  end;
  Result := dTotal > 0;
  if not Result then
    AMensaje := Format(SErrorPedidoCompraSinCantidadesRecibir,
      [FAlmacen, FSeriePedido, FNumeroPedido]);
end;

procedure TEscrituraIncorporacionAlbaranCompra.ConfigurarOrigenPendientes(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'SELECT L.LINEA_PEDCLIN, L.CODIGO_ART_PEDCLIN, ' +
    'L.CODIGO_UNIDAD_PEDCLIN, L.REF_PRV_PEDCLIN, ' +
    'L.LOTE_PEDCLIN, L.CADUCIDAD_PEDCLIN, ' +
    'L.ID_AC_PIVOT_PEDCLIN, L.CODIGO_FAM_PEDCLIN, ' +
    'L.NOMBRE_FAM_PEDCLIN, L.DESCRIPCION_ARTICULO_PEDCLIN, ' +
    'L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
    'L.TIPO_IVA_ARTICULO_PEDCLIN, L.PORCENTAJE_IVA_PEDCLIN, ' +
    'IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') ' +
    'AS EXENTO_INTRACOM, L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
    'L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
    'L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN, 0) ' +
    'AS PENDIENTE FROM fza_pedidos_compra_lineas L ' +
    'JOIN fza_pedidos_compra P ' +
    'ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
    'AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
    'WHERE L.SERIE_PEDC_PEDCLIN = :SERIE ' +
    'AND L.NUMERO_PEDC_PEDCLIN = :NUMERO ' +
    'AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
    'P.CODIGO_ALM_PEDC) = :ALMACEN ' +
    'AND L.CANTIDAD_PEDCLIN - ' +
    'IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN, 0) > 0 ' +
    'ORDER BY L.LINEA_PEDCLIN';
end;

procedure TEscrituraIncorporacionAlbaranCompra.ConfigurarOrigenLinea(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'SELECT L.CODIGO_ART_PEDCLIN, L.CODIGO_UNIDAD_PEDCLIN, ' +
    'L.REF_PRV_PEDCLIN, L.ID_AC_PIVOT_PEDCLIN, ' +
    'L.LOTE_PEDCLIN, L.CADUCIDAD_PEDCLIN, ' +
    'L.CODIGO_FAM_PEDCLIN, L.NOMBRE_FAM_PEDCLIN, ' +
    'L.DESCRIPCION_ARTICULO_PEDCLIN, ' +
    'L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
    'L.TIPO_IVA_ARTICULO_PEDCLIN, L.PORCENTAJE_IVA_PEDCLIN, ' +
    'IFNULL(P.ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, ''N'') ' +
    'AS EXENTO_INTRACOM, L.PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
    'L.PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, ' +
    'L.CANTIDAD_PEDCLIN, L.CANTIDAD_RECIBIDA_PEDCLIN ' +
    'FROM fza_pedidos_compra_lineas L JOIN fza_pedidos_compra P ' +
    'ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
    'AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
    'WHERE L.SERIE_PEDC_PEDCLIN = :SERIE ' +
    'AND L.NUMERO_PEDC_PEDCLIN = :NUMERO ' +
    'AND L.LINEA_PEDCLIN = :LINEA';
end;

procedure TEscrituraIncorporacionAlbaranCompra.ConfigurarInsercion(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_albaranes_compra_lineas ' +
    '(NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
    'NUMERO_PEDC_ALBCLIN, SERIE_PEDC_ALBCLIN, LINEA_PEDC_ALBCLIN, ' +
    'CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, REF_PRV_ALBCLIN, ' +
    'ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
    'DESCRIPCION_ARTICULO_ALBCLIN, TIPO_CANTIDAD_ARTICULO_ALBCLIN, ' +
    'CANTIDAD_ALBCLIN, TOTAL_UNIDADES_ALBCLIN, ' +
    'TIPO_IVA_ARTICULO_ALBCLIN, PORCENTAJE_IVA_ALBCLIN, ' +
    'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, TOTAL_ALBCLIN, ' +
    'CODIGO_ALMACEN_ALBCLIN, ESFACTURADA_ALBCLIN, ' +
    'LOTE_ALBCLIN, FECHA_CADUCIDAD_ALBCLIN, INSTANTE_ALTA, ' +
    'USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:NALBARAN, :SALBARAN, :LALBARAN, :NPEDIDO, :SPEDIDO, ' +
    ':LPEDIDO, :ARTICULO, :SKU, :REFPRV, :PIVOTE, :FAMILIA, ' +
    ':NOMFAMILIA, :DESCRIPCION, :TIPOCANTIDAD, :CANTIDAD, :CANTIDAD, ' +
    ':TIPOIVA, :PORCENTAJEIVA, :PRECIO, :PRECIOCIVA, ' +
    ':CANTIDAD * :PRECIO, :ALMACEN, ''N'', :LOTE, :CADUCIDAD, ' +
    'NOW(), :USUARIO, NOW(), ' +
    ':USUARIO)';
end;

procedure TEscrituraIncorporacionAlbaranCompra.InsertarLinea(
  AOrigen, AEscritura: TUniQuery;
  const ALineaAlbaran, ALineaPedido, ACodigoSku: string;
  ACantidad: Double; const ACelda: TCeldaARecibir);
begin
  ConfigurarInsercion(AEscritura);
  AEscritura.ParamByName('NALBARAN').AsString := FNumeroAlbaran;
  AEscritura.ParamByName('SALBARAN').AsString := FSerieAlbaran;
  AEscritura.ParamByName('LALBARAN').AsString := ALineaAlbaran;
  AEscritura.ParamByName('NPEDIDO').AsString := FNumeroPedido;
  AEscritura.ParamByName('SPEDIDO').AsString := FSeriePedido;
  AEscritura.ParamByName('LPEDIDO').AsString := ALineaPedido;
  AEscritura.ParamByName('ARTICULO').AsString :=
    AOrigen.FieldByName('CODIGO_ART_PEDCLIN').AsString;
  AEscritura.ParamByName('SKU').AsString := ACodigoSku;
  AEscritura.ParamByName('REFPRV').AsString :=
    AOrigen.FieldByName('REF_PRV_PEDCLIN').AsString;
  if AOrigen.FieldByName('ID_AC_PIVOT_PEDCLIN').IsNull then
    AEscritura.ParamByName('PIVOTE').Clear
  else
    AEscritura.ParamByName('PIVOTE').AsInteger :=
      AOrigen.FieldByName('ID_AC_PIVOT_PEDCLIN').AsInteger;
  AEscritura.ParamByName('FAMILIA').AsString :=
    AOrigen.FieldByName('CODIGO_FAM_PEDCLIN').AsString;
  AEscritura.ParamByName('NOMFAMILIA').AsString :=
    AOrigen.FieldByName('NOMBRE_FAM_PEDCLIN').AsString;
  AEscritura.ParamByName('DESCRIPCION').AsString :=
    AOrigen.FieldByName('DESCRIPCION_ARTICULO_PEDCLIN').AsString;
  AEscritura.ParamByName('TIPOCANTIDAD').AsString :=
    AOrigen.FieldByName('TIPO_CANTIDAD_ARTICULO_PEDCLIN').AsString;
  AEscritura.ParamByName('CANTIDAD').AsFloat := ACantidad;
  if AOrigen.FieldByName('EXENTO_INTRACOM').AsString = 'S' then
  begin
    AEscritura.ParamByName('TIPOIVA').AsString := 'E';
    AEscritura.ParamByName('PORCENTAJEIVA').AsFloat := 0;
  end
  else
  begin
    AEscritura.ParamByName('TIPOIVA').AsString :=
      AOrigen.FieldByName('TIPO_IVA_ARTICULO_PEDCLIN').AsString;
    AEscritura.ParamByName('PORCENTAJEIVA').AsFloat :=
      AOrigen.FieldByName('PORCENTAJE_IVA_PEDCLIN').AsFloat;
  end;
  AEscritura.ParamByName('PRECIO').AsFloat :=
    AOrigen.FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN').AsFloat;
  AEscritura.ParamByName('PRECIOCIVA').AsFloat :=
    AOrigen.FieldByName('PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN').AsFloat;
  AEscritura.ParamByName('ALMACEN').AsString := FAlmacen;
  AEscritura.ParamByName('USUARIO').AsString := FUsuario;
  // FZ-ISSUE-434: el lote pedido al recibir manda sobre el de la línea
  // del pedido.
  if Trim(ACelda.Lote) <> '' then
  begin
    AEscritura.ParamByName('LOTE').AsString := Trim(ACelda.Lote);
    if ACelda.FechaCaducidad > 0 then
      AEscritura.ParamByName('CADUCIDAD').AsDate :=
        Trunc(ACelda.FechaCaducidad)
    else
    begin
      AEscritura.ParamByName('CADUCIDAD').DataType := ftDate;
      AEscritura.ParamByName('CADUCIDAD').Clear;
    end;
  end
  else
  begin
    AEscritura.ParamByName('LOTE').AsString :=
      AOrigen.FieldByName('LOTE_PEDCLIN').AsString;
    AEscritura.ParamByName('CADUCIDAD').Value :=
      AOrigen.FieldByName('CADUCIDAD_PEDCLIN').Value;
  end;
  AEscritura.ExecSQL;
end;

procedure TEscrituraIncorporacionAlbaranCompra.ActualizarCantidadRecibida(
  AConsulta: TUniQuery;
  const ALineaPedido: string;
  ACantidad: Double);
begin
  AConsulta.SQL.Text :=
    'UPDATE fza_pedidos_compra_lineas SET ' +
    'CANTIDAD_RECIBIDA_PEDCLIN = ' +
    'IFNULL(CANTIDAD_RECIBIDA_PEDCLIN, 0) + :CANTIDAD, ' +
    'USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
    'WHERE SERIE_PEDC_PEDCLIN = :SERIE ' +
    'AND NUMERO_PEDC_PEDCLIN = :NUMERO ' +
    'AND LINEA_PEDCLIN = :LINEA';
  AConsulta.ParamByName('CANTIDAD').AsFloat := ACantidad;
  AConsulta.ParamByName('USUARIO').AsString := FUsuario;
  AConsulta.ParamByName('SERIE').AsString := FSeriePedido;
  AConsulta.ParamByName('NUMERO').AsString := FNumeroPedido;
  AConsulta.ParamByName('LINEA').AsString := ALineaPedido;
  AConsulta.ExecSQL;
end;

procedure TEscrituraIncorporacionAlbaranCompra.CerrarAlbaran;
begin
  RegenerarMovimientosYCerrarAlbaranCompra(
    FConexion,
    FSerieAlbaran,
    FNumeroAlbaran,
    FSeriePedido,
    FNumeroPedido,
    FUsuario,
    FIdPvTemporada);
end;

function TEscrituraIncorporacionAlbaranCompra.IncorporarPendientes(
  out AMensaje: string): Boolean;
var
  EsTransaccionPropia: Boolean;
  iLineaAlbaran: Integer;
  oEscritura: TUniQuery;
  oOrigen: TUniQuery;
  sLineaAlbaran: string;
  sLineaPedido: string;
begin
  Result := False;
  if ValidarDestino(AMensaje) then
  begin
    EsTransaccionPropia := not FConexion.InTransaction;
    if EsTransaccionPropia then
      FConexion.StartTransaction;
    try
      if BloquearOrigenYDestino(AMensaje) and
         HayPendientes(AMensaje) and
         ValidarLotesRecepcionPedidoCompraUniDAC(FConexion, FSeriePedido,
           FNumeroPedido, FAlmacen, [], AMensaje) then
      begin
        iLineaAlbaran := MaxLineaAlbaranCompra(
          FConexion, FSerieAlbaran, FNumeroAlbaran);
        oOrigen := nil;
        oEscritura := nil;
        try
          oOrigen := TUniQuery.Create(nil);
          oEscritura := TUniQuery.Create(nil);
          oOrigen.Connection := FConexion;
          oEscritura.Connection := FConexion;
          ConfigurarOrigenPendientes(oOrigen);
          oOrigen.ParamByName('SERIE').AsString := FSeriePedido;
          oOrigen.ParamByName('NUMERO').AsString := FNumeroPedido;
          oOrigen.ParamByName('ALMACEN').AsString := FAlmacen;
          oOrigen.Open;
          while not oOrigen.Eof do
          begin
            Inc(iLineaAlbaran, 10);
            sLineaAlbaran := Format('%.4d', [iLineaAlbaran]);
            sLineaPedido :=
              oOrigen.FieldByName('LINEA_PEDCLIN').AsString;
            InsertarLinea(
              oOrigen,
              oEscritura,
              sLineaAlbaran,
              sLineaPedido,
              oOrigen.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString,
              oOrigen.FieldByName('PENDIENTE').AsFloat,
              Default(TCeldaARecibir));
            ActualizarCantidadRecibida(
              oEscritura,
              sLineaPedido,
              oOrigen.FieldByName('PENDIENTE').AsFloat);
            oOrigen.Next;
          end;
        finally
          FreeAndNil(oEscritura);
          FreeAndNil(oOrigen);
        end;
        CerrarAlbaran;
        AMensaje := Format(SInfoLineasIncorporadasAlbaranCompra,
          [FSerieAlbaran, FNumeroAlbaran]);
        Result := True;
      end;
      if EsTransaccionPropia then
      begin
        FConexion.Commit;
        if Result then
          SolicitarProcesadoPrestaShop;
      end;
    except
      if EsTransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  end;
end;

function TEscrituraIncorporacionAlbaranCompra.IncorporarCeldas(
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
var
  EsProcesable: Boolean;
  EsTransaccionPropia: Boolean;
  iInsertadas: Integer;
  iLineaAlbaran: Integer;
  oCelda: TCeldaARecibir;
  oEscritura: TUniQuery;
  oOrigen: TUniQuery;
  dCantidad: Double;
  dPendiente: Double;
  oPendientes: TDictionary<string, Double>;
  sLineaAlbaran: string;
begin
  Result := False;
  if ValidarDestino(AMensaje) and ValidarCeldas(ACeldas, AMensaje) then
  begin
    EsTransaccionPropia := not FConexion.InTransaction;
    if EsTransaccionPropia then
      FConexion.StartTransaction;
    try
      if BloquearOrigenYDestino(AMensaje) and
         ValidarLotesRecepcionPedidoCompraUniDAC(FConexion, FSeriePedido,
           FNumeroPedido, FAlmacen, ACeldas, AMensaje) then
      begin
        iInsertadas := 0;
        iLineaAlbaran := MaxLineaAlbaranCompra(
          FConexion, FSerieAlbaran, FNumeroAlbaran);
        oOrigen := nil;
        oEscritura := nil;
        oPendientes := nil;
        try
          oOrigen := TUniQuery.Create(nil);
          oEscritura := TUniQuery.Create(nil);
          oPendientes := TDictionary<string, Double>.Create;
          oOrigen.Connection := FConexion;
          oEscritura.Connection := FConexion;
          ConfigurarOrigenLinea(oOrigen);
          for oCelda in ACeldas do
          begin
            EsProcesable := SameText(oCelda.CodigoAlmacen, FAlmacen) and
              (oCelda.Cantidad > 0);
            if EsProcesable then
            begin
              oOrigen.Close;
              oOrigen.ParamByName('SERIE').AsString := FSeriePedido;
              oOrigen.ParamByName('NUMERO').AsString := FNumeroPedido;
              oOrigen.ParamByName('LINEA').AsString := oCelda.LineaPedido;
              oOrigen.Open;
              if not oOrigen.Eof then
              begin
                if not oPendientes.TryGetValue(
                  oCelda.LineaPedido, dPendiente) then
                begin
                  dPendiente :=
                    oOrigen.FieldByName('CANTIDAD_PEDCLIN').AsFloat -
                    oOrigen.FieldByName(
                      'CANTIDAD_RECIBIDA_PEDCLIN').AsFloat;
                  if dPendiente < 0 then
                    dPendiente := 0;
                end;
                dCantidad := oCelda.Cantidad;
                if dCantidad > dPendiente then
                  dCantidad := dPendiente;
                oPendientes.AddOrSetValue(
                  oCelda.LineaPedido, dPendiente - dCantidad);
                if dCantidad > 0 then
                begin
                  Inc(iLineaAlbaran, 10);
                  sLineaAlbaran := Format('%.4d', [iLineaAlbaran]);
                  InsertarLinea(
                    oOrigen,
                    oEscritura,
                    sLineaAlbaran,
                    oCelda.LineaPedido,
                    oCelda.CodigoSku,
                    dCantidad,
                    oCelda);
                  ActualizarCantidadRecibida(
                    oEscritura, oCelda.LineaPedido, dCantidad);
                  Inc(iInsertadas);
                end;
              end;
            end;
          end;
        finally
          FreeAndNil(oPendientes);
          FreeAndNil(oEscritura);
          FreeAndNil(oOrigen);
        end;
        if iInsertadas = 0 then
          AMensaje := SErrorIncorporarLineasAlbaranCompra
        else
        begin
          CerrarAlbaran;
          AMensaje := Format(
            SInfoLineasIncorporadasAlbaranCompraConCantidad,
            [FSerieAlbaran, FNumeroAlbaran, iInsertadas]);
          Result := True;
        end;
      end;
      if EsTransaccionPropia then
      begin
        FConexion.Commit;
        if Result then
          SolicitarProcesadoPrestaShop;
      end;
    except
      if EsTransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  end;
end;

end.

