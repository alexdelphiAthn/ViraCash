{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataListasRegalos                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ventas Mayor - Lista de regalos PrestaShop: listas (fza_listas_regalos),  }
{    sus artículos (VI_LRG_LINEAS_ESTADO) y los regalos recibidos. Altas,      }
{    cantidades, entregas, anulaciones y cierre pasan por los procedimientos   }
{    PRC_LRG_*; la sincronización con la tienda, por                           }
{    inLibListasRegalosSincronizacion. Todo por la conexión de la ventana.     }
{******************************************************************************}
unit UniDataListasRegalos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibListasRegalos, inLibListasRegalosSincronizacion;

type
  TdmListasRegalos = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
  private
    FLineas: TUniQuery;
    FdsLineas: TDataSource;
    FRegalos: TUniQuery;
    FdsRegalos: TDataSource;
    procedure ConfigurarConsulta;
    procedure CrearDetalles;
    function CrearDetalle(const ASql: string; out AOrigen: TDataSource):
      TUniQuery;
    function Llamar(const ASql: string; const AValores: array of Variant;
      const ASalidas: string): TArray<Variant>;
    function ResolverSku(const ACodigoLeido: string): string;
    function PrecioSku(const ASku: string): Currency;
    procedure CrearLista(DataSet: TDataSet);
    procedure TablaGNewRecord(DataSet: TDataSet);
    procedure TablaGBeforeEdit(DataSet: TDataSet);
    procedure TablaGBeforePost(DataSet: TDataSet);
    procedure TablaGAfterPost(DataSet: TDataSet);
    procedure TablaGBeforeDelete(DataSet: TDataSet);
    procedure LineasBeforeEdit(DataSet: TDataSet);
    procedure LineasBeforePost(DataSet: TDataSet);
    procedure LineasAfterPost(DataSet: TDataSet);
  public
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    // Listas de la empresa de la sesión. AEstado: un ESTADO_LRG o ''
    // (todas). ATexto: código, clave web o parte de los titulares, del
    // homenajeado o del título.
    procedure AplicarFiltros(const AEstado, ATexto: string);
    function ListaAbierta: Boolean;
    function CodigoLista: string;
    procedure RefrescarLista;
    // ACodigoLeido: código de SKU o código de barras.
    function AgregarLinea(const ACodigoLeido: string;
      ACantidad: Integer): Integer;
    function CambiarCantidadLinea(ALinea, ACantidad: Integer): Integer;
    function EntregarRegalo(AId: Int64): Integer;
    function AnularRegalo(AId: Int64; const AMotivo: string): Integer;
    function Cerrar: TResultadoCierreLista;
    function Anular: Integer;
    // Recoge regalos web y publica en la tienda de appPrestaShopUrl.
    function Sincronizar: TInformeSincronizacionListas;
    property dsLineas: TDataSource read FdsLineas;
    property dsRegalos: TDataSource read FdsRegalos;
    property Lineas: TUniQuery read FLineas;
    property Regalos: TUniQuery read FRegalos;
  end;

implementation

uses
  System.Variants, inLibErroresBBDD, inLibMsgListasRegalos,
  inLibListasRegalosPrestaShop, UniDataListasRegalosSincronizacion;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

const
  CAMPO_CODIGO = 'CODIGO_LRG';
  CAMPO_ESTADO = 'ESTADO_LRG';
  TARIFA_DEFECTO = 'PVP';
  PARAMETRO_TARIFA_PRESTASHOP = 'appPrestaShopTarifa';
  PARAMETRO_URL_PRESTASHOP = 'appPrestaShopUrl';

  SQL_SELECCION_LISTAS =
    'SELECT L.CODIGO_LRG, L.CODIGO_EMP_LRG, L.CODIGO_ALM_LRG, ' +
    '       L.CODIGO_CLI_LRG, L.TIPO_LRG, L.ESTADO_LRG, ' +
    '       L.CLAVE_PUBLICA_LRG, L.TITULO_LRG, L.NOMBRE_HOMENAJEADO_LRG, ' +
    '       L.NOMBRE_TITULARES_LRG, L.EMAIL_TITULARES_LRG, ' +
    '       L.MOVIL_TITULARES_LRG, L.MENSAJE_LRG, L.FECHA_EVENTO_LRG, ' +
    '       L.FECHA_CADUCIDAD_LRG, L.TIPO_ENTREGA_LRG, ' +
    '       L.ESPUBLICA_WEB_LRG, L.ESBUSCABLE_LRG, ' +
    '       L.PORCENTAJE_BONIFICACION_LRG, L.VERSION_LRG, ' +
    '       L.FECHA_CIERRE_LRG, L.TOTAL_REGALADO_LRG, ' +
    '       L.IMPORTE_BONIFICACION_LRG, L.OBSERVACIONES_LRG, ' +
    '       L.INSTANTE_ALTA, L.USUARIO_ALTA, L.INSTANTE_MODIF, ' +
    '       L.USUARIO_MODIF, ' +
    '       (SELECT COUNT(*) FROM fza_listas_regalos_lineas X ' +
    '         WHERE X.CODIGO_LRG_LRGLIN = L.CODIGO_LRG ' +
    '           AND X.ESACTIVO_LRGLIN = ''S'') AS NUMERO_LINEAS, ' +
    '       (SELECT COALESCE(SUM(R.IMPORTE_LRGREG), 0) ' +
    '          FROM fza_listas_regalos_regalos R ' +
    '         WHERE R.CODIGO_LRG_LRGREG = L.CODIGO_LRG ' +
    '           AND R.ESTADO_LRGREG = ''CONFIRMADO'') AS IMPORTE_REGALADO ' +
    '  FROM fza_listas_regalos L ';
  SQL_FILTRO_LISTAS =
    ' WHERE L.CODIGO_EMP_LRG = :EMPRESA ' +
    '   AND (:ESTADO = '''' OR L.ESTADO_LRG = :ESTADO) ' +
    '   AND (:TEXTO = '''' OR L.CODIGO_LRG = :TEXTO ' +
    '     OR L.CLAVE_PUBLICA_LRG = UPPER(:TEXTO) ' +
    '     OR L.NOMBRE_TITULARES_LRG LIKE :PATRON ' +
    '     OR L.NOMBRE_HOMENAJEADO_LRG LIKE :PATRON ' +
    '     OR L.TITULO_LRG LIKE :PATRON) ' +
    ' ORDER BY L.CODIGO_LRG DESC';
  // La ficha graba solo la cabecera editable; cada grabación sube la
  // versión para que la lista se vuelva a publicar. El alta la crea antes
  // PRC_LRG_CREAR (código y clave), así que también es un UPDATE.
  SQL_GRABAR_LISTA =
    'UPDATE fza_listas_regalos ' +
    '   SET CODIGO_CLI_LRG = NULLIF(:CODIGO_CLI_LRG, ''''), ' +
    '       TIPO_LRG = :TIPO_LRG, TITULO_LRG = :TITULO_LRG, ' +
    '       NOMBRE_HOMENAJEADO_LRG = :NOMBRE_HOMENAJEADO_LRG, ' +
    '       NOMBRE_TITULARES_LRG = :NOMBRE_TITULARES_LRG, ' +
    '       EMAIL_TITULARES_LRG = :EMAIL_TITULARES_LRG, ' +
    '       MOVIL_TITULARES_LRG = :MOVIL_TITULARES_LRG, ' +
    '       MENSAJE_LRG = :MENSAJE_LRG, ' +
    '       FECHA_EVENTO_LRG = :FECHA_EVENTO_LRG, ' +
    '       FECHA_CADUCIDAD_LRG = :FECHA_CADUCIDAD_LRG, ' +
    '       TIPO_ENTREGA_LRG = :TIPO_ENTREGA_LRG, ' +
    '       ESPUBLICA_WEB_LRG = :ESPUBLICA_WEB_LRG, ' +
    '       ESBUSCABLE_LRG = :ESBUSCABLE_LRG, ' +
    '       PORCENTAJE_BONIFICACION_LRG = :PORCENTAJE_BONIFICACION_LRG, ' +
    '       OBSERVACIONES_LRG = :OBSERVACIONES_LRG, ' +
    '       VERSION_LRG = VERSION_LRG + 1, ' +
    '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO_MODIF ' +
    ' WHERE CODIGO_LRG = %s ' +
    '   AND ESTADO_LRG = ''ABIERTA''';
  SQL_LINEAS =
    'SELECT E.CODIGO_LRG_LRGLIN, E.LINEA_LRGLIN, E.ORDEN_LRGLIN, ' +
    '       E.CODIGO_SKU_LRGLIN, E.CODIGO_ART_LRGLIN, E.DESCRIPCION_LRGLIN, ' +
    '       E.CANTIDAD_DESEADA_LRGLIN, E.CANTIDAD_REGALADA_LRGLIN, ' +
    '       E.CANTIDAD_PENDIENTE_LRGLIN, E.PRECIO_REFERENCIA_LRGLIN, ' +
    '       E.ESIMPRESCINDIBLE_LRGLIN, E.ESADMITE_OTRA_VARIANTE_LRGLIN, ' +
    '       E.OBSERVACIONES_LRGLIN, ' +
    '       CAST(NULL AS CHAR(100)) AS USUARIO_MODIF ' +
    '  FROM VI_LRG_LINEAS_ESTADO E ' +
    ' WHERE E.CODIGO_LRG_LRGLIN = :CODIGO_LRG ' +
    '   AND E.ESACTIVO_LRGLIN = ''S'' ' +
    ' ORDER BY E.ORDEN_LRGLIN, E.LINEA_LRGLIN';
  SQL_GRABAR_LINEA =
    'UPDATE fza_listas_regalos_lineas ' +
    '   SET ORDEN_LRGLIN = :ORDEN_LRGLIN, ' +
    '       ESIMPRESCINDIBLE_LRGLIN = :ESIMPRESCINDIBLE_LRGLIN, ' +
    '       ESADMITE_OTRA_VARIANTE_LRGLIN = ' +
    '         :ESADMITE_OTRA_VARIANTE_LRGLIN, ' +
    '       OBSERVACIONES_LRGLIN = :OBSERVACIONES_LRGLIN, ' +
    '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO_MODIF ' +
    ' WHERE CODIGO_LRG_LRGLIN = :Old_CODIGO_LRG_LRGLIN ' +
    '   AND LINEA_LRGLIN = :Old_LINEA_LRGLIN';
  SQL_REGALOS =
    'SELECT R.ID_LRGREG, R.INSTANTE_LRGREG, R.CANAL_LRGREG, ' +
    '       R.LINEA_LRGLIN_LRGREG, R.CODIGO_SKU_LRGREG, R.CANTIDAD_LRGREG, ' +
    '       R.IMPORTE_LRGREG, R.NOMBRE_REGALANTE_LRGREG, R.MENSAJE_LRGREG, ' +
    '       R.ESENTREGADO_LRGREG, R.FECHA_ENTREGA_LRGREG, R.ESTADO_LRGREG, ' +
    '       R.ESEXCEDENTE_LRGREG, R.MOTIVO_ANULACION_LRGREG, ' +
    '       COALESCE(CONCAT(R.SERIE_PED_LRGREG, ''/'', R.NUMERO_PED_LRGREG), ' +
    '         CONCAT(''PrestaShop '', R.IDPS_PEDIDO_LRGREG), ' +
    '         CONCAT(R.CODIGO_CAJA_LRGREG, '' '', R.NUMERO_OPCAJA_LRGREG)) ' +
    '         AS DOCUMENTO_REGALO ' +
    '  FROM fza_listas_regalos_regalos R ' +
    ' WHERE R.CODIGO_LRG_LRGREG = :CODIGO_LRG ' +
    ' ORDER BY R.ID_LRGREG DESC';
  SQL_SKU_LEIDO =
    'SELECT S.CODIGO_UNIDAD_SKU ' +
    '  FROM fza_articulos_skus S ' +
    ' WHERE S.CODIGO_UNIDAD_SKU = :CODIGO ' +
    'UNION ALL ' +
    'SELECT CB.CODIGO_UNIDAD_CB ' +
    '  FROM fza_codigos_barras CB ' +
    ' WHERE CB.CODIGO_BARRAS_CB = :CODIGO ' +
    ' LIMIT 1';
  // Precio de la tarifa web: el del SKU si lo tiene, si no el del artículo.
  SQL_PRECIO_SKU =
    'SELECT T.PRECIO_FINAL_ARTTAR ' +
    '  FROM fza_articulos_skus S ' +
    '  JOIN fza_articulos_tarifas T ' +
    '    ON T.CODIGO_ART_ARTTAR = S.CODIGO_ART_SKU ' +
    ' WHERE S.CODIGO_UNIDAD_SKU = :SKU ' +
    '   AND T.CODIGO_TAR_ARTTAR = :TARIFA ' +
    '   AND T.ESACTIVO_ARTTAR = ''S'' ' +
    '   AND (T.CODIGO_UNIDAD_ARTTAR = S.CODIGO_UNIDAD_SKU ' +
    '     OR COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''') ' +
    ' ORDER BY (T.CODIGO_UNIDAD_ARTTAR = S.CODIGO_UNIDAD_SKU) DESC ' +
    ' LIMIT 1';
  SQL_SUBIR_VERSION =
    'UPDATE fza_listas_regalos SET VERSION_LRG = VERSION_LRG + 1 ' +
    ' WHERE CODIGO_LRG = :CODIGO';

procedure TdmListasRegalos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  ConfigurarConsulta;
  CrearDetalles;
end;

// SELECT con subconsultas: UniDAC no deduce la tabla, así que el UPDATE,
// el refresco y la clave son explícitos.
procedure TdmListasRegalos.ConfigurarConsulta;
begin
  unqryTablaG.SQL.Text := SQL_SELECCION_LISTAS + SQL_FILTRO_LISTAS;
  unqryTablaG.SQLUpdate.Text :=
    Format(SQL_GRABAR_LISTA, [':Old_CODIGO_LRG']);
  unqryTablaG.SQLInsert.Text := Format(SQL_GRABAR_LISTA, [':CODIGO_LRG']);
  unqryTablaG.SQLRefresh.Text := SQL_SELECCION_LISTAS +
    ' WHERE L.CODIGO_LRG = :CODIGO_LRG';
  unqryTablaG.SQLDelete.Clear;
  unqryTablaG.KeyFields := CAMPO_CODIGO;
  unqryTablaG.ReadOnly := False;
  unqryTablaG.Options.SetFieldsReadOnly := False;
  unqryTablaG.ParamByName('EMPRESA').AsString := '';
  unqryTablaG.ParamByName('ESTADO').AsString := ESTADO_LISTA_ABIERTA;
  unqryTablaG.ParamByName('TEXTO').AsString := '';
  unqryTablaG.ParamByName('PATRON').AsString := '%';
  unqryTablaG.OnNewRecord := TablaGNewRecord;
  unqryTablaG.BeforeEdit := TablaGBeforeEdit;
  unqryTablaG.BeforePost := TablaGBeforePost;
  unqryTablaG.AfterPost := TablaGAfterPost;
  unqryTablaG.BeforeDelete := TablaGBeforeDelete;
end;

function TdmListasRegalos.CrearDetalle(const ASql: string;
  out AOrigen: TDataSource): TUniQuery;
begin
  Result := TUniQuery.Create(Self);
  Result.Connection := unqryTablaG.Connection;
  Result.SQL.Text := ASql;
  AOrigen := TDataSource.Create(Self);
  AOrigen.DataSet := Result;
end;

procedure TdmListasRegalos.CrearDetalles;
begin
  FLineas := CrearDetalle(SQL_LINEAS, FdsLineas);
  FLineas.Name := 'unqryLineasLista';
  FLineas.SQLUpdate.Text := SQL_GRABAR_LINEA;
  FLineas.KeyFields := 'CODIGO_LRG_LRGLIN;LINEA_LRGLIN';
  FLineas.Options.SetFieldsReadOnly := False;
  FLineas.BeforeEdit := LineasBeforeEdit;
  FLineas.BeforePost := LineasBeforePost;
  FLineas.AfterPost := LineasAfterPost;
  FRegalos := CrearDetalle(SQL_REGALOS, FdsRegalos);
  FRegalos.Name := 'unqryRegalosLista';
  FRegalos.ReadOnly := True;
end;

procedure TdmListasRegalos.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  FLineas.Connection := unqryTablaG.Connection;
  FRegalos.Connection := unqryTablaG.Connection;
  FLineas.MasterSource := ADataSource;
  FRegalos.MasterSource := ADataSource;
end;

procedure TdmListasRegalos.AplicarFiltros(const AEstado, ATexto: string);
begin
  if unqryTablaG.Active then
    unqryTablaG.Close;
  unqryTablaG.ParamByName('EMPRESA').AsString := UbicacionSesion.Empresa;
  unqryTablaG.ParamByName('ESTADO').AsString := Trim(AEstado);
  unqryTablaG.ParamByName('TEXTO').AsString := Trim(ATexto);
  unqryTablaG.ParamByName('PATRON').AsString := '%' + Trim(ATexto) + '%';
  unqryTablaG.Open;
  if not FLineas.Active then
    FLineas.Open;
  if not FRegalos.Active then
    FRegalos.Open;
end;

function TdmListasRegalos.ListaAbierta: Boolean;
begin
  Result := unqryTablaG.Active and not unqryTablaG.IsEmpty and
    (unqryTablaG.FieldByName(CAMPO_ESTADO).AsString = ESTADO_LISTA_ABIERTA);
end;

function TdmListasRegalos.CodigoLista: string;
begin
  Result := '';
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
    Result := unqryTablaG.FieldByName(CAMPO_CODIGO).AsString;
end;

procedure TdmListasRegalos.RefrescarLista;
begin
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
    unqryTablaG.RefreshRecord;
  FLineas.Refresh;
  FRegalos.Refresh;
end;

procedure TdmListasRegalos.TablaGNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('CODIGO_EMP_LRG').AsString :=
    unqryTablaG.ParamByName('EMPRESA').AsString;
  DataSet.FieldByName('TIPO_LRG').AsString := TIPOS_LISTA[0];
  DataSet.FieldByName('ESTADO_LRG').AsString := ESTADO_LISTA_ABIERTA;
  DataSet.FieldByName('TIPO_ENTREGA_LRG').AsString := ENTREGAS_LISTA[0];
  DataSet.FieldByName('ESPUBLICA_WEB_LRG').AsString := 'S';
  DataSet.FieldByName('ESBUSCABLE_LRG').AsString := 'S';
  DataSet.FieldByName('PORCENTAJE_BONIFICACION_LRG').AsFloat := 0;
  DataSet.FieldByName('VERSION_LRG').AsInteger := 1;
end;

procedure TdmListasRegalos.TablaGBeforeEdit(DataSet: TDataSet);
begin
  if not ListaAbierta then
  begin
    NotificarInformacion(SResultadoListaNoAbierta);
    Abort;
  end;
end;

// El alta reserva código y clave con PRC_LRG_CREAR; luego el INSERT del
// dataset (un UPDATE) graba el resto de la cabecera.
procedure TdmListasRegalos.CrearLista(DataSet: TDataSet);
var
  aSalidas: TArray<Variant>;
  vFecha: Variant;
begin
  vFecha := Null;
  if not DataSet.FieldByName('FECHA_EVENTO_LRG').IsNull then
    vFecha := DataSet.FieldByName('FECHA_EVENTO_LRG').AsDateTime;
  aSalidas := Llamar('CALL PRC_LRG_CREAR(:EMPRESA, :ALMACEN, :CLIENTE, ' +
    ':TIPO, :TITULO, :HOMENAJEADO, :TITULARES, :FECHA, :USUARIO, ' +
    '@CODIGO_LRG, @CLAVE_LRG)', [
    DataSet.FieldByName('CODIGO_EMP_LRG').AsString,
    UbicacionSesion.Almacen,
    DataSet.FieldByName('CODIGO_CLI_LRG').AsString,
    DataSet.FieldByName('TIPO_LRG').AsString,
    DataSet.FieldByName('TITULO_LRG').AsString,
    DataSet.FieldByName('NOMBRE_HOMENAJEADO_LRG').AsString,
    DataSet.FieldByName('NOMBRE_TITULARES_LRG').AsString,
    vFecha, IdentidadSesion.Usuario], '@CODIGO_LRG, @CLAVE_LRG');
  DataSet.FieldByName(CAMPO_CODIGO).AsString := VarToStr(aSalidas[0]);
  DataSet.FieldByName('CLAVE_PUBLICA_LRG').AsString :=
    VarToStr(aSalidas[1]);
  DataSet.FieldByName('CODIGO_ALM_LRG').AsString := UbicacionSesion.Almacen;
  if Trim(DataSet.FieldByName('TITULO_LRG').AsString) = '' then
    DataSet.FieldByName('TITULO_LRG').AsString :=
      'Lista de ' + Trim(DataSet.FieldByName('NOMBRE_TITULARES_LRG').AsString);
end;

procedure TdmListasRegalos.TablaGBeforePost(DataSet: TDataSet);
begin
  inherited unqryTablaGBeforePost(DataSet);
  if Trim(DataSet.FieldByName('NOMBRE_TITULARES_LRG').AsString) = '' then
    raise EValidacionBBDD.Create(SErrorListaSinTitulares);
  if DataSet.State = dsInsert then
    CrearLista(DataSet);
end;

// Releer: versión, totales y número de artículos los calcula la base.
procedure TdmListasRegalos.TablaGAfterPost(DataSet: TDataSet);
begin
  unqryTablaG.RefreshRecord;
end;

procedure TdmListasRegalos.TablaGBeforeDelete(DataSet: TDataSet);
begin
  NotificarInformacion(SInfoListaSinBorrado);
  Abort;
end;

procedure TdmListasRegalos.LineasBeforeEdit(DataSet: TDataSet);
begin
  if not ListaAbierta then
  begin
    NotificarInformacion(SResultadoListaNoAbierta);
    Abort;
  end;
end;

procedure TdmListasRegalos.LineasBeforePost(DataSet: TDataSet);
begin
  DataSet.FieldByName('USUARIO_MODIF').AsString :=
    Copy(IdentidadSesion.Usuario, 1, 100);
end;

procedure TdmListasRegalos.LineasAfterPost(DataSet: TDataSet);
begin
  Llamar(SQL_SUBIR_VERSION, [CodigoLista], '');
  unqryTablaG.RefreshRecord;
end;

// Ejecuta ASql con AValores en el orden de sus parámetros y devuelve las
// variables de sesión de ASalidas (p. ej. '@RESULTADO_LRG').
function TdmListasRegalos.Llamar(const ASql: string;
  const AValores: array of Variant; const ASalidas: string): TArray<Variant>;
var
  oConsulta: TUniQuery;
  i: Integer;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := ASql;
    for i := 0 to High(AValores) do
      // Un nulo sin tipo lo rechaza UniDAC: se envía como fecha nula.
      if VarIsNull(AValores[i]) then
      begin
        oConsulta.Params[i].DataType := ftDate;
        oConsulta.Params[i].Clear;
      end
      else
        oConsulta.Params[i].Value := AValores[i];
    if oConsulta.Params.FindParam('USUARIO') <> nil then
      oConsulta.ParamByName('USUARIO').AsString :=
        Copy(IdentidadSesion.Usuario, 1, 100);
    oConsulta.ExecSQL;
    if ASalidas <> '' then
    begin
      oConsulta.SQL.Text := 'SELECT ' + ASalidas;
      oConsulta.Open;
      SetLength(Result, oConsulta.FieldCount);
      for i := 0 to oConsulta.FieldCount - 1 do
        Result[i] := oConsulta.Fields[i].Value;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TdmListasRegalos.ResolverSku(const ACodigoLeido: string): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := SQL_SKU_LEIDO;
    oConsulta.ParamByName('CODIGO').AsString := Trim(ACodigoLeido);
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EValidacionBBDD.CreateFmt(SErrorSkuListaNoEncontrado,
        [Trim(ACodigoLeido)]);
    Result := oConsulta.Fields[0].AsString;
  finally
    oConsulta.Free;
  end;
end;

function TdmListasRegalos.PrecioSku(const ASku: string): Currency;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := SQL_PRECIO_SKU;
    oConsulta.ParamByName('SKU').AsString := ASku;
    oConsulta.ParamByName('TARIFA').AsString := ParametrosApp.GetString(
      PARAMETRO_TARIFA_PRESTASHOP, TARIFA_DEFECTO);
    oConsulta.Open;
    Result := 0;
    if not oConsulta.IsEmpty then
      Result := oConsulta.Fields[0].AsCurrency;
  finally
    oConsulta.Free;
  end;
end;

function TdmListasRegalos.AgregarLinea(const ACodigoLeido: string;
  ACantidad: Integer): Integer;
var
  sSku: string;
begin
  sSku := ResolverSku(ACodigoLeido);
  Result := Llamar('CALL PRC_LRG_LINEA_AGREGAR(:LISTA, :SKU, :CANTIDAD, ' +
    ':PRECIO, :USUARIO, @LINEA_LRG, @RESULTADO_LRG)',
    [CodigoLista, sSku, ACantidad, PrecioSku(sSku)], '@RESULTADO_LRG')[0];
  RefrescarLista;
end;

function TdmListasRegalos.CambiarCantidadLinea(ALinea,
  ACantidad: Integer): Integer;
begin
  Result := Llamar('CALL PRC_LRG_LINEA_CANTIDAD(:LISTA, :LINEA, ' +
    ':CANTIDAD, :USUARIO, @RESULTADO_LRG)', [CodigoLista, ALinea, ACantidad],
    '@RESULTADO_LRG')[0];
  RefrescarLista;
end;

function TdmListasRegalos.EntregarRegalo(AId: Int64): Integer;
begin
  Result := Llamar('CALL PRC_LRG_REGALO_ENTREGAR(:ID, :USUARIO, ' +
    '@RESULTADO_LRG)', [AId], '@RESULTADO_LRG')[0];
  RefrescarLista;
end;

function TdmListasRegalos.AnularRegalo(AId: Int64;
  const AMotivo: string): Integer;
begin
  Result := Llamar('CALL PRC_LRG_REGALO_ANULAR(:ID, :MOTIVO, :USUARIO, ' +
    '@RESULTADO_LRG)', [AId, Copy(Trim(AMotivo), 1, 250)],
    '@RESULTADO_LRG')[0];
  RefrescarLista;
end;

function TdmListasRegalos.Cerrar: TResultadoCierreLista;
var
  aSalidas: TArray<Variant>;
begin
  aSalidas := Llamar('CALL PRC_LRG_CERRAR(:LISTA, :USUARIO, ' +
    '@TOTAL_LRG, @BONIFICACION_LRG, @RESULTADO_LRG)', [CodigoLista],
    '@TOTAL_LRG, @BONIFICACION_LRG, @RESULTADO_LRG');
  Result.Resultado := aSalidas[2];
  Result.TotalRegalado := 0;
  Result.Bonificacion := 0;
  if not VarIsNull(aSalidas[0]) then
    Result.TotalRegalado := aSalidas[0];
  if not VarIsNull(aSalidas[1]) then
    Result.Bonificacion := aSalidas[1];
  RefrescarLista;
end;

function TdmListasRegalos.Anular: Integer;
begin
  Result := Llamar('CALL PRC_LRG_ANULAR(:LISTA, :USUARIO, @RESULTADO_LRG)',
    [CodigoLista], '@RESULTADO_LRG')[0];
  RefrescarLista;
end;

function TdmListasRegalos.Sincronizar: TInformeSincronizacionListas;
var
  sUrl, sClave: string;
  oSincronizador: TSincronizadorListasRegalos;
begin
  sUrl := Trim(ParametrosApp.GetString(PARAMETRO_URL_PRESTASHOP, ''));
  sClave := Trim(ParametrosApp.GetString(PARAMETRO_CLAVE_LISTAS_REGALOS, ''));
  if (sUrl = '') or (sClave = '') then
    raise EValidacionBBDD.Create(SErrorListasPrestaShopSinConfigurar);
  oSincronizador := TSincronizadorListasRegalos.Create(
    CrearRepositorioSincronizacionListas(unqryTablaG.Connection,
      IdentidadSesion.Usuario),
    CrearApiListasRegalos(RaizTiendaPrestaShop(sUrl), sClave));
  try
    Result := oSincronizador.Ejecutar(UbicacionSesion.Empresa,
      OrigenListasPrestaShop(sUrl));
  finally
    oSincronizador.Free;
  end;
  RefrescarLista;
end;

initialization
  RegistrarDataModule(TdmListasRegalos);
end.
