{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidos                                                }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de pedidos.                                                   }
{    Cabeceras y líneas de fza_pedidos, generación de albaranes e importación  }
{    PrestaShop.                                                               }
{******************************************************************************}
unit UniDataPedidos;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen, inLibUser,
  frxClass, frxDBSet,
  inLibPresta, frCoreClasses,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibVentasPantallaCrearAlbaran;

type
  // Datos que comparten los pasos de la creacion de un albaran desde
  // un pedido de venta.
  TContextoCreacionAlbaranPedido = record
    NumeroPedido: string;
    SeriePedido: string;
    NumeroAlbaran: string;
    SerieAlbaran: string;
    CodigoAlmacen: string;
    Usuario: string;
    AlbaranNuevo: TDatosAlbaranNuevoPedido;
  end;

  TdmPedidos = class(TdmBase)
    unqryPedidosLineas: TUniQuery;
    dsPedidosLineas: TDataSource;
    unqryLinPedido: TUniQuery;
    dsLinPedido: TDataSource;
    unqryEmpDataPedido: TUniQuery;
    unqryCliDataPedido: TUniQuery;
    unqryArtDataLinPedido: TUniQuery;
    unstrdprcCrearPedido: TUniStoredProc;
    unstrdprcGetContadorPedido: TUniStoredProc;
    unstrdprcGetContador: TUniStoredProc;
    unstrdprcCrearAlbaranInicio: TUniStoredProc;
    unstrdprcCrearAlbaranLinea:  TUniStoredProc;
    unstrdprcCrearAlbaranFin:    TUniStoredProc;
    fxdsPrintPed: TfrxDBDataset;
    fxdstPrintLinPed: TfrxDBDataset;
    unqryAlbaranes: TUniQuery;
    dsAlbaranes:    TDataSource;
    unqryMensajes: TUniQuery;
    dsMensajes:    TDataSource;
    unqryFormasPago: TUniQuery;
    dsFormasPago: TDataSource;
    unqryVendedores: TUniQuery;
    dsVendedores: TDataSource;
    unqryAlmacenesPed: TUniQuery;
    dsAlmacenesPed: TDataSource;
    unqryTarifas: TUniQuery;
    dsTarifas: TDataSource;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryTablaGAfterPost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterInsert(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforePost(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterPost(DataSet: TDataSet);
    procedure unqryPedidosLineasBeforeDelete(DataSet: TDataSet);
    procedure unqryPedidosLineasAfterDelete(DataSet: TDataSet);
  private
    procedure ValidarBorradoPedido(const ASerie, ANumero: string);
    procedure LineasPedidoDataChange(Sender: TObject; Field: TField);
  public
    // Contrato ColumnSKUcxGrid: rellena ATTR1..5_VALOR_PEDLIN y
    // NUM_ATRIBUTOS_PEDLIN troceando el SKU (CODIGO_UNIDAD_PEDLIN) de
    // cada linea que aun los tenga vacios (idempotente por linea).
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoPedido;
    procedure CalcularTotalesPedido;
    // Numero total de prendas (suma CANTIDAD_PEDLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasPedido: Double;
    procedure CopiarEmpresaaPedido(DataSet: TDataSet);
    procedure CopiarClienteaPedido(DataSet: TDataSet);
    function BuscarEmpresa(const ACodigo: string): Boolean;
    function BuscarAlmacen(const ACodigo: string): Boolean;
    function ClienteExiste(const ACodigo: string): Boolean;
    function BuscarCliente(const ACodigo: string): Boolean;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    procedure ActualizarImpuestosTarifaCabecera(
      const ACodigoTarifa: string);

    // Cantidades entregadas / pendientes
    procedure RecalcularEntregasLinea;

    // Crear albarán a partir de las cantidades entregadas pendientes.
    // ACodigoAlmacen: almacén (único) del que sale la mercancía; se fija
    // en las líneas que se añaden ahora, sobreescribiendo el almacén que
    // cada línea heredaba del pedido.
    // AAlbExistenteNum/AAlbExistenteSerie: si se indican, las líneas se
    // añaden a ese albarán existente en lugar de crear uno nuevo.
    // AAlbaranNuevo: serie, número, fecha y forma de pago del albarán
    // nuevo (diálogo común); no se usa al añadir a uno existente.
    function CrearAlbaranDesdePedido(out sNumeroAlb, sSerieAlb: string;
                                     aLineas: TList<TPair<string,
                                     Currency>>;
                                     const ACodigoAlmacen: string;
                                     const AAlbExistenteNum: string;
                                     const AAlbExistenteSerie: string;
                                     const AAlbaranNuevo:
                                       TDatosAlbaranNuevoPedido
                                    ): Boolean;

    // Importación PrestaShop
    // AOrigen: URL normalizada de la API de la tienda. Los pedidos
    // importados antes de guardar el origen cuentan para cualquier tienda.
    function ImportarPedidoPrestaShop(aOrder: TOrder;
      const AOrigen: string): Boolean;
    function ExistePedidoPrestaShop(
      const AOrigen, sIdPS: string): Boolean;
    function UltimoIdPedidoPrestaShop(const AOrigen: string): Int64;
    // Localiza el cliente del pedido PS por NIF/email; si no existe lo da de
    // alta y devuelve su CODIGO_CLI_CLI. Devuelve '0' solo si no hay datos.
    function ResolverCodigoCliente(aOrder: TOrder): string;
    // Localiza el articulo de una linea PS por EAN13/referencia; si no existe
    // crea articulo sin variacion + SKU + codigo de barras y devuelve el
    // CODIGO_ART_ART. Devuelve '' solo si no hay datos para crearlo.
    function ResolverCodigoArticulo(
      const oValidador: IArticulosValidador;
                                    const lp: TLineaPed): string;

    procedure OpenTables;
    // Override: abre las queries detalle del Mto de Pedidos tras
    // unqryTablaG. Invocada desde TfrmMtoGen.AbrirTablaPrincipalAsync
    // en el callback main thread. OpenTables delega aqui.
    procedure AbrirDetalles; override;
  private
    FCalculandoTotales: Boolean;
    FAplicandoDescuento: Boolean;
    procedure PrepararLineaAntesDeGuardar(DataSet: TDataSet);
    procedure AplicarEstadoLineaAntesDeGuardar(DataSet: TDataSet);
    procedure AplicarAuditoriaLineaAntesDeGuardar(DataSet: TDataSet);
    procedure AsignarNumeroLineaPedido(DataSet: TDataSet);
    procedure PersistirAlmacenCabecera;
    procedure ValidarAlmacenCabecera;
    procedure ValidarClienteCabecera;
    // Propone la serie PE de fza_empresas_series de la empresa emisora
    // en documentos nuevos sin numerar (al cambiar la empresa en el alta)
    procedure ProponerSerieEmpresa(const AEmpresa: string);
    procedure CopiarFormaPagoPedidoAAlbaran(const ASeriePed, ANumeroPed,
                                            ASerieAlb, ANumeroAlb: string;
                                            AForzar: Boolean);
    procedure RestarPdteServirPedido(const ASerie, ANumero,
                                     ALinea: string);
    // Devuelve el siguiente contador (PRC_GET_NEXT_CONT) del tipo indicado.
    function ObtenerContador(const sTipo: string): string;
    // Pasos de CrearAlbaranDesdePedido.
    function ContextoAlbaranDesdePedido(const ACodigoAlmacen: string;
      const AAlbaranNuevo: TDatosAlbaranNuevoPedido)
      : TContextoCreacionAlbaranPedido;
    procedure PrepararNumeracionAlbaranPedido(
      var AContexto: TContextoCreacionAlbaranPedido);
    procedure PrepararCabeceraAlbaranPedido(
      var AContexto: TContextoCreacionAlbaranPedido;
      const AAlbExistenteNum, AAlbExistenteSerie: string;
      var ANumeroAlb, ASerieAlb: string);
    procedure RefrescarTrasCrearAlbaranPedido(const ASerieAlb,
      ANumeroAlb: string; ATransPropia: Boolean);
  private
    // Conexion por la que salen la transaccion, los bloqueos y las
    // lecturas de la operacion: la misma que usan los datasets.
    function ConexionEscritura: TUniConnection;
  end;

implementation

uses
  inLibLineaSku,
  inLibTrazabilidadAlta, UniDataDescuentosVenta, UniDataPedidosAlbaranLotes,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataVendedoresRepositorio,
  System.Diagnostics, System.UITypes,
  UniDataAperturaConsultas,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio, JclDebug,
  inLibData, UniDataAlmacenesEmpresaRepositorio,
  inLibMsgArticulos, inLibMsgVentas, inLibErroresBBDD,
  UniDataNumeracionDocumentos,
  inLibDocumento, inLibDocumentoIntf, inLibLogIntf,
  inLibPedidosVentaPresentacionReglas,
  UniDataPedidosPrestaShopEscrituras,
  UniDataPedidosVentaFlujoEdicion, UniDataClientesRepositorio;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

procedure EjecutarInicioAlbaranPedido(
  AProcedimiento: TUniStoredProc;
  var AContexto: TContextoCreacionAlbaranPedido);
var
  oParams: TParams;
begin
  AProcedimiento.StoredProcName := 'PRC_PED_CREAR_ALBARAN_INICIO_OPCIONES';
  oParams := AProcedimiento.Params;
  oParams.Clear;
  oParams.CreateParam(ftString, 'p_NUMERO_PED', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_PED', ptInput);
  oParams.CreateParam(ftString, 'p_SERIE_NUEVA', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_MANUAL', ptInput);
  oParams.CreateParam(ftDate, 'p_FECHA', ptInput);
  oParams.CreateParam(ftString, 'p_ALMACEN', ptInput);
  oParams.CreateParam(ftString, 'p_FORMA_PAGO', ptInput);
  oParams.CreateParam(ftString, 'p_USUARIO', ptInput);
  oParams.CreateParam(ftString, 'p_NUMERO_ALB', ptOutput);
  oParams.CreateParam(ftString, 'p_SERIE_ALB', ptOutput);
  AProcedimiento.ParamByName('p_NUMERO_PED').AsString :=
    AContexto.NumeroPedido;
  AProcedimiento.ParamByName('p_SERIE_PED').AsString :=
    AContexto.SeriePedido;
  AProcedimiento.ParamByName('p_SERIE_NUEVA').AsString :=
    AContexto.AlbaranNuevo.Serie;
  AProcedimiento.ParamByName('p_NUMERO_MANUAL').AsString :=
    AContexto.AlbaranNuevo.NumeroManual;
  if AContexto.AlbaranNuevo.Fecha > 0 then
    AProcedimiento.ParamByName('p_FECHA').AsDate :=
      AContexto.AlbaranNuevo.Fecha
  else
    AProcedimiento.ParamByName('p_FECHA').Clear;
  AProcedimiento.ParamByName('p_ALMACEN').AsString :=
    AContexto.CodigoAlmacen;
  AProcedimiento.ParamByName('p_FORMA_PAGO').AsString :=
    AContexto.AlbaranNuevo.FormaPago;
  AProcedimiento.ParamByName('p_USUARIO').AsString := AContexto.Usuario;
  AProcedimiento.ExecProc;
  AContexto.NumeroAlbaran := AProcedimiento.ParamByName(
    'p_NUMERO_ALB').AsString;
  AContexto.SerieAlbaran := AProcedimiento.ParamByName(
    'p_SERIE_ALB').AsString;
end;

procedure EjecutarLineaAlbaranPedido(
  AProcedimiento: TUniStoredProc;
  const AContexto: TContextoCreacionAlbaranPedido;
  const ALinea: TPair<string, Currency>);
begin
  AProcedimiento.Params.Clear;
  AProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_ALB', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_ALB', ptInput);
  AProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_PED', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_PED', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_LINEA_PED', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_CANTIDAD', ptInput);
  AProcedimiento.Params.CreateParam(
    ftString, 'p_CODIGO_ALM', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
  AProcedimiento.ParamByName('p_NUMERO_ALB').AsString :=
    AContexto.NumeroAlbaran;
  AProcedimiento.ParamByName('p_SERIE_ALB').AsString :=
    AContexto.SerieAlbaran;
  AProcedimiento.ParamByName('p_NUMERO_PED').AsString :=
    AContexto.NumeroPedido;
  AProcedimiento.ParamByName('p_SERIE_PED').AsString :=
    AContexto.SeriePedido;
  AProcedimiento.ParamByName('p_LINEA_PED').AsString := ALinea.Key;
  AProcedimiento.ParamByName('p_CANTIDAD').AsCurrency := ALinea.Value;
  AProcedimiento.ParamByName('p_CODIGO_ALM').AsString :=
    AContexto.CodigoAlmacen;
  AProcedimiento.ParamByName('p_USUARIO').AsString := AContexto.Usuario;
  AProcedimiento.ExecProc;
end;

procedure BloquearAlbaranDestinoPedido(AConexion: TUniConnection;
  const AContexto: TContextoCreacionAlbaranPedido);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT ESTADO_ALB FROM fza_albaranes ' +
      'WHERE NUMERO_ALB = :NUMERO AND SERIE_ALB = :SERIE FOR UPDATE';
    Consulta.ParamByName('NUMERO').AsString := AContexto.NumeroAlbaran;
    Consulta.ParamByName('SERIE').AsString := AContexto.SerieAlbaran;
    Consulta.Open;
    if Consulta.IsEmpty or
       not SameText(Trim(Consulta.FieldByName('ESTADO_ALB').AsString),
         'ABIERTO') then
      raise Exception.Create(SErrorAlbaranVentaNoAbierto);
  finally
    FreeAndNil(Consulta);
  end;
end;

function ContarLineasAlbaranPedido(AConexion: TUniConnection;
  const AContexto: TContextoCreacionAlbaranPedido): Int64;
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS LINEAS FROM fza_albaranes_lineas ' +
      'WHERE NUMERO_ALB_ALBLIN = :NUMERO AND SERIE_ALB_ALBLIN = :SERIE';
    Consulta.ParamByName('NUMERO').AsString := AContexto.NumeroAlbaran;
    Consulta.ParamByName('SERIE').AsString := AContexto.SerieAlbaran;
    Consulta.Open;
    Result := Consulta.FieldByName('LINEAS').AsLargeInt;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure LimpiarCantidadesPedidoAlbaran(AConexion: TUniConnection;
  const AContexto: TContextoCreacionAlbaranPedido);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'UPDATE fza_pedidos_lineas SET CANTIDAD_A_ALBARANAR_PEDLIN = 0 ' +
      'WHERE NUMERO_PED_PEDLIN = :NUMERO AND SERIE_PED_PEDLIN = :SERIE';
    Consulta.ParamByName('NUMERO').AsString := AContexto.NumeroPedido;
    Consulta.ParamByName('SERIE').AsString := AContexto.SeriePedido;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure EjecutarLineasAlbaranPedido(
  AProcedimiento: TUniStoredProc;
  const AContexto: TContextoCreacionAlbaranPedido;
  ALineas: TList<TPair<string, Currency>>);
var
  Linea: TPair<string, Currency>;
begin
  for Linea in ALineas do
  begin
    if Linea.Value > 0 then
      EjecutarLineaAlbaranPedido(AProcedimiento, AContexto, Linea);
  end;
end;

procedure EjecutarFinAlbaranPedido(
  AProcedimiento: TUniStoredProc;
  const AContexto: TContextoCreacionAlbaranPedido);
begin
  AProcedimiento.Params.Clear;
  AProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_ALB', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_ALB', ptInput);
  AProcedimiento.Params.CreateParam(
    ftString, 'p_NUMERO_PED', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_PED', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
  AProcedimiento.ParamByName('p_NUMERO_ALB').AsString :=
    AContexto.NumeroAlbaran;
  AProcedimiento.ParamByName('p_SERIE_ALB').AsString :=
    AContexto.SerieAlbaran;
  AProcedimiento.ParamByName('p_NUMERO_PED').AsString :=
    AContexto.NumeroPedido;
  AProcedimiento.ParamByName('p_SERIE_PED').AsString :=
    AContexto.SeriePedido;
  AProcedimiento.ParamByName('p_USUARIO').AsString := AContexto.Usuario;
  AProcedimiento.ExecProc;
end;

{ TdmPedidos }

function TdmPedidos.ConexionEscritura: TUniConnection;
begin
  // Cada ventana de mantenimiento crea su propia conexion y reasigna a
  // ella los datasets (TdmBase.ReasignarConexion). La transaccion, los
  // SELECT ... FOR UPDATE y las lecturas de la operacion tienen que ir
  // por esa misma conexion: si salen por la conexion compartida, el
  // UPDATE del dataset acaba esperando un bloqueo que retiene el propio
  // programa desde otra conexion (MariaDB 1205, lock wait timeout).
  Result := nil;
  if Assigned(unqryTablaG) then
    Result := unqryTablaG.Connection;
  if not Assigned(Result) then
    Result := ConexionPrincipal;
end;

procedure TdmPedidos.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryTablaG.Connection           := ConexionPrincipal;
  unqryTablaG.BeforeDelete         := unqryTablaGBeforeDelete;
  unqryTablaG.AfterDelete := ConfirmarBorradoTransaccional;
  unqryTablaG.OnDeleteError := ErrorBorradoTransaccional;
  unqryTablaG.AfterPost            := unqryTablaGAfterPost;
  unqryTablaG.SQLRefresh.Text      :=
    'SELECT * FROM vi_pedidos ' +
    ' WHERE NUMERO_PED = :NUMERO_PED ' +
    '   AND SERIE_PED = :SERIE_PED';
  unqryPedidosLineas.Connection    := ConexionPrincipal;
  unqryPedidosLineas.BeforeDelete  := unqryPedidosLineasBeforeDelete;
  unqryPedidosLineas.AfterDelete   := unqryPedidosLineasAfterDelete;
  dsPedidosLineas.OnDataChange     := LineasPedidoDataChange;
  // Contrato ColumnSKUcxGrid (pedidos_columnas_sku.sql): los SQL del
  // dfm no conocen las columnas nuevas (SKU + ATTR1..5 + pivote); se
  // reescriben aqui COMPLETOS para no editar el dfm cableado.
  unqryPedidosLineas.SQLInsert.Text :=
    'INSERT INTO fza_pedidos_lineas ' +
    ' (PRECIO_SALIDA_PEDLIN, PORCENTAJE_DTO_PEDLIN, ' +
    '  PRECIO_DTO_PEDLIN, NUMERO_PED_PEDLIN, SERIE_PED_PEDLIN, ' +
    '  LINEA_PEDLIN, ' +
    '  IDLINEAPS_PEDLIN, IDPRODPS_PEDLIN, CODIGOPRODPS_PEDLIN, ' +
    '  IDATRIBPRODPS_PEDLIN, CODBAR_ART_PEDLIN, CODIGO_ART_PEDLIN, ' +
    '  CODIGO_FAM_PEDLIN, NOMBRE_FAM_PEDLIN, FECHA_ENTREGA_PEDLIN, ' +
    '  TIPO_CANTIDAD_ARTICULO_PEDLIN, ESIMP_INCL_TARIFA_PEDLIN, ' +
    '  TIPO_IVA_ARTICULO_PEDLIN, DESCRIPCION_ARTICULO_PEDLIN, ' +
    '  CODIGO_TAR_PEDLIN, CANTIDAD_PEDLIN, CANTIDAD_ENTREGADA_PEDLIN, ' +
    '  CANTIDAD_A_ALBARANAR_PEDLIN, CANTIDAD_PENDIENTE_PEDLIN, ' +
    '  ESENTREGADA_PEDLIN, ' +
    '  CODIGO_ALMACEN_PEDLIN, PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    '  PORCENTAJE_IVA_PEDLIN, PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
    '  TOTAL_PEDLIN, ' +
    '  CODIGO_UNIDAD_PEDLIN, ' +
    '  ATTR1_VALOR_PEDLIN, ATTR1_NOMBRE_PEDLIN, ' +
    '  ATTR2_VALOR_PEDLIN, ATTR2_NOMBRE_PEDLIN, ' +
    '  ATTR3_VALOR_PEDLIN, ATTR3_NOMBRE_PEDLIN, ' +
    '  ATTR4_VALOR_PEDLIN, ATTR4_NOMBRE_PEDLIN, ' +
    '  ATTR5_VALOR_PEDLIN, ATTR5_NOMBRE_PEDLIN, ' +
    '  NUM_ATRIBUTOS_PEDLIN, ID_AC_PIVOT_PEDLIN, ' +
    '  INSTANTE_MODIF, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES ' +
    ' (:PRECIO_SALIDA_PEDLIN, :PORCENTAJE_DTO_PEDLIN, ' +
    '  :PRECIO_DTO_PEDLIN, :NUMERO_PED_PEDLIN, :SERIE_PED_PEDLIN, ' +
    '  :LINEA_PEDLIN, ' +
    '  :IDLINEAPS_PEDLIN, :IDPRODPS_PEDLIN, :CODIGOPRODPS_PEDLIN, ' +
    '  :IDATRIBPRODPS_PEDLIN, :CODBAR_ART_PEDLIN, :CODIGO_ART_PEDLIN, ' +
    '  :CODIGO_FAM_PEDLIN, :NOMBRE_FAM_PEDLIN, :FECHA_ENTREGA_PEDLIN, ' +
    '  :TIPO_CANTIDAD_ARTICULO_PEDLIN, :ESIMP_INCL_TARIFA_PEDLIN, ' +
    '  :TIPO_IVA_ARTICULO_PEDLIN, :DESCRIPCION_ARTICULO_PEDLIN, ' +
    '  :CODIGO_TAR_PEDLIN, :CANTIDAD_PEDLIN, ' +
    '  :CANTIDAD_ENTREGADA_PEDLIN, :CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    '  :CANTIDAD_PENDIENTE_PEDLIN, :ESENTREGADA_PEDLIN, ' +
    '  :CODIGO_ALMACEN_PEDLIN, ' +
    '  :PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, :PORCENTAJE_IVA_PEDLIN, ' +
    '  :PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, :TOTAL_PEDLIN, ' +
    '  :CODIGO_UNIDAD_PEDLIN, ' +
    '  :ATTR1_VALOR_PEDLIN, :ATTR1_NOMBRE_PEDLIN, ' +
    '  :ATTR2_VALOR_PEDLIN, :ATTR2_NOMBRE_PEDLIN, ' +
    '  :ATTR3_VALOR_PEDLIN, :ATTR3_NOMBRE_PEDLIN, ' +
    '  :ATTR4_VALOR_PEDLIN, :ATTR4_NOMBRE_PEDLIN, ' +
    '  :ATTR5_VALOR_PEDLIN, :ATTR5_NOMBRE_PEDLIN, ' +
    '  :NUM_ATRIBUTOS_PEDLIN, :ID_AC_PIVOT_PEDLIN, ' +
    '  :INSTANTE_MODIF, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    '  :USUARIO_MODIF)';
  unqryPedidosLineas.SQLUpdate.Text :=
    'UPDATE fza_pedidos_lineas SET ' +
    '  PRECIO_SALIDA_PEDLIN = :PRECIO_SALIDA_PEDLIN, ' +
    '  PORCENTAJE_DTO_PEDLIN = :PORCENTAJE_DTO_PEDLIN, ' +
    '  PRECIO_DTO_PEDLIN = :PRECIO_DTO_PEDLIN, ' +
    '  NUMERO_PED_PEDLIN = :NUMERO_PED_PEDLIN, ' +
    '  SERIE_PED_PEDLIN = :SERIE_PED_PEDLIN, ' +
    '  LINEA_PEDLIN = :LINEA_PEDLIN, ' +
    '  IDLINEAPS_PEDLIN = :IDLINEAPS_PEDLIN, ' +
    '  IDPRODPS_PEDLIN = :IDPRODPS_PEDLIN, ' +
    '  CODIGOPRODPS_PEDLIN = :CODIGOPRODPS_PEDLIN, ' +
    '  IDATRIBPRODPS_PEDLIN = :IDATRIBPRODPS_PEDLIN, ' +
    '  CODBAR_ART_PEDLIN = :CODBAR_ART_PEDLIN, ' +
    '  CODIGO_ART_PEDLIN = :CODIGO_ART_PEDLIN, ' +
    '  CODIGO_FAM_PEDLIN = :CODIGO_FAM_PEDLIN, ' +
    '  NOMBRE_FAM_PEDLIN = :NOMBRE_FAM_PEDLIN, ' +
    '  FECHA_ENTREGA_PEDLIN = :FECHA_ENTREGA_PEDLIN, ' +
    '  TIPO_CANTIDAD_ARTICULO_PEDLIN = :TIPO_CANTIDAD_ARTICULO_PEDLIN, ' +
    '  ESIMP_INCL_TARIFA_PEDLIN = :ESIMP_INCL_TARIFA_PEDLIN, ' +
    '  TIPO_IVA_ARTICULO_PEDLIN = :TIPO_IVA_ARTICULO_PEDLIN, ' +
    '  DESCRIPCION_ARTICULO_PEDLIN = :DESCRIPCION_ARTICULO_PEDLIN, ' +
    '  CODIGO_TAR_PEDLIN = :CODIGO_TAR_PEDLIN, ' +
    '  CANTIDAD_PEDLIN = :CANTIDAD_PEDLIN, ' +
    '  CANTIDAD_ENTREGADA_PEDLIN = :CANTIDAD_ENTREGADA_PEDLIN, ' +
    '  CANTIDAD_A_ALBARANAR_PEDLIN = :CANTIDAD_A_ALBARANAR_PEDLIN, ' +
    '  CANTIDAD_PENDIENTE_PEDLIN = :CANTIDAD_PENDIENTE_PEDLIN, ' +
    '  ESENTREGADA_PEDLIN = :ESENTREGADA_PEDLIN, ' +
    '  CODIGO_ALMACEN_PEDLIN = :CODIGO_ALMACEN_PEDLIN, ' +
    '  PRECIO_VENTA_SIVA_ARTICULO_PEDLIN = ' +
    '    :PRECIO_VENTA_SIVA_ARTICULO_PEDLIN, ' +
    '  PORCENTAJE_IVA_PEDLIN = :PORCENTAJE_IVA_PEDLIN, ' +
    '  PRECIO_VENTA_CIVA_ARTICULO_PEDLIN = ' +
    '    :PRECIO_VENTA_CIVA_ARTICULO_PEDLIN, ' +
    '  TOTAL_PEDLIN = :TOTAL_PEDLIN, ' +
    '  CODIGO_UNIDAD_PEDLIN = :CODIGO_UNIDAD_PEDLIN, ' +
    '  ATTR1_VALOR_PEDLIN = :ATTR1_VALOR_PEDLIN, ' +
    '  ATTR1_NOMBRE_PEDLIN = :ATTR1_NOMBRE_PEDLIN, ' +
    '  ATTR2_VALOR_PEDLIN = :ATTR2_VALOR_PEDLIN, ' +
    '  ATTR2_NOMBRE_PEDLIN = :ATTR2_NOMBRE_PEDLIN, ' +
    '  ATTR3_VALOR_PEDLIN = :ATTR3_VALOR_PEDLIN, ' +
    '  ATTR3_NOMBRE_PEDLIN = :ATTR3_NOMBRE_PEDLIN, ' +
    '  ATTR4_VALOR_PEDLIN = :ATTR4_VALOR_PEDLIN, ' +
    '  ATTR4_NOMBRE_PEDLIN = :ATTR4_NOMBRE_PEDLIN, ' +
    '  ATTR5_VALOR_PEDLIN = :ATTR5_VALOR_PEDLIN, ' +
    '  ATTR5_NOMBRE_PEDLIN = :ATTR5_NOMBRE_PEDLIN, ' +
    '  NUM_ATRIBUTOS_PEDLIN = :NUM_ATRIBUTOS_PEDLIN, ' +
    '  ID_AC_PIVOT_PEDLIN = :ID_AC_PIVOT_PEDLIN, ' +
    '  INSTANTE_MODIF = :INSTANTE_MODIF, ' +
    '  INSTANTE_ALTA = :INSTANTE_ALTA, ' +
    '  USUARIO_ALTA = :USUARIO_ALTA, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE NUMERO_PED_PEDLIN = :Old_NUMERO_PED_PEDLIN ' +
    '  AND SERIE_PED_PEDLIN = :Old_SERIE_PED_PEDLIN ' +
    '  AND LINEA_PEDLIN = :Old_LINEA_PEDLIN';
  unqryPedidosLineas.SQLRefresh.Text :=
    'SELECT * FROM vi_pedidos_lineas ' +
    ' WHERE NUMERO_PED_PEDLIN = :NUMERO_PED_PEDLIN ' +
    '   AND SERIE_PED_PEDLIN = :SERIE_PED_PEDLIN ' +
    '   AND LINEA_PEDLIN = :LINEA_PEDLIN';
  unqryPedidosLineas.SQLLock.Text :=
    'SELECT * FROM fza_pedidos_lineas ' +
    ' WHERE NUMERO_PED_PEDLIN = :Old_NUMERO_PED_PEDLIN ' +
    '   AND SERIE_PED_PEDLIN = :Old_SERIE_PED_PEDLIN ' +
    '   AND LINEA_PEDLIN = :Old_LINEA_PEDLIN ' +
    ' FOR UPDATE';
  unqryLinPedido.Connection        := ConexionPrincipal;
  unqryEmpDataPedido.Connection    := ConexionPrincipal;
  unqryCliDataPedido.Connection    := ConexionPrincipal;
  unqryArtDataLinPedido.Connection := ConexionPrincipal;
  unstrdprcCrearPedido.Connection            := ConexionPrincipal;
  unstrdprcGetContadorPedido.Connection      := ConexionPrincipal;
  unstrdprcGetContador.Connection            := ConexionPrincipal;
  unstrdprcCrearAlbaranInicio.Connection     := ConexionPrincipal;
  unstrdprcCrearAlbaranLinea.Connection      := ConexionPrincipal;
  unstrdprcCrearAlbaranFin.Connection        := ConexionPrincipal;
  unqryPerfiles.Connection         := ConexionPrincipal;
  unqryAlbaranes.Connection        := ConexionPrincipal;
  unqryMensajes.Connection         := ConexionPrincipal;
  unqryFormasPago.Connection       := ConexionPrincipal;
  unqryVendedores := CrearConsultaVendedores(Self, ConexionPrincipal);
  dsVendedores := TDataSource.Create(Self);
  dsVendedores.DataSet := unqryVendedores;
  unqryAlmacenesPed.Connection     := ConexionPrincipal;
  unqryTarifas.Connection          := ConexionPrincipal;
  VigilarTotalMaximoLinea(unqryPedidosLineas, 'TOTAL_PEDLIN');
end;

procedure TdmPedidos.DesempaquetarAtributosLineas;
begin
  DesempaquetarAtributosLineasSku(unqryPedidosLineas, 'PEDLIN');
end;

procedure TdmPedidos.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryPedidosLineas) and unqryPedidosLineas.Active then
    unqryPedidosLineas.Close;
  if Assigned(unqryAlbaranes) and unqryAlbaranes.Active then
    unqryAlbaranes.Close;
  if Assigned(unqryMensajes) and unqryMensajes.Active then
    unqryMensajes.Close;
  if Assigned(unqryFormasPago) and unqryFormasPago.Active then
    unqryFormasPago.Close;
  if Assigned(unqryVendedores) and unqryVendedores.Active then
    unqryVendedores.Close;
  if Assigned(unqryAlmacenesPed) and unqryAlmacenesPed.Active then
    unqryAlmacenesPed.Close;
  if Assigned(unqryTarifas) and unqryTarifas.Active then
    unqryTarifas.Close;
  inherited;
end;

procedure TdmPedidos.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmPedidos.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesPed.Active) or
     (not SameText(unqryAlmacenesPed.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesPed.Close;
    unqryAlmacenesPed.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesPed.Open;
  end;
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_PED', 'CODIGO_ALM_PED');
end;

procedure TdmPedidos.AbrirDetalles;
const
  TAG = 'Pedidos.AbrirDetalles';
var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  AbrirConsultaConTiempo(
    unqryPedidosLineas, TAG, 'unqryPedidosLineas', RegistroLog);
  AbrirConsultaConTiempo(
    unqryAlbaranes, TAG, 'unqryAlbaranes', RegistroLog);
  AbrirConsultaConTiempo(
    unqryMensajes, TAG, 'unqryMensajes', RegistroLog);
  AbrirConsultaConTiempo(
    unqryFormasPago, TAG, 'unqryFormasPago', RegistroLog);
  AbrirConsultaConTiempo(
    unqryVendedores, TAG, 'unqryVendedores', RegistroLog);
  AbrirConsultaConTiempo(
    unqryAlmacenesPed, TAG, 'unqryAlmacenesPed', RegistroLog);
  AbrirConsultaConTiempo(
    unqryTarifas, TAG, 'unqryTarifas', RegistroLog);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmPedidos.unqryTablaGAfterInsert(DataSet: TDataSet);
var
  sSerie: string;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  inherited;
  FieldByName('FECHA_PED').AsDateTime := Date;
    if Trim(UbicacionSesion.Empresa) <> '' then
      FieldByName('CODIGO_EMP_PED').AsString := UbicacionSesion.Empresa
    else
      FieldByName('CODIGO_EMP_PED').AsString := '0';
    FieldByName('CODIGO_CLI_PED').Clear;
    FieldByName('TARIFA_ARTICULO_CLIENTE_PED').Clear;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_PED').Clear;
    FieldByName('NUMERO_PED').AsString     := '0';
    // Serie por defecto: buscar en fza_empresas_series para TIPO_DOC='PE'
    // (mismo criterio que compras); fallback historico 'A1'
    sSerie := ObtenerSerieDefecto(
      ConexionEscritura,
      UbicacionSesion.Empresa,
      CrearConfiguracionDocumento(
        tdPedido, sdVenta).TipoContador);
    if sSerie = '' then
      sSerie := 'A1';
    if FindField('SERIE_PED') <> nil then
      FieldByName('SERIE_PED').AsString    := sSerie;
    if FindField('ESTADO_PED') <> nil then
      FieldByName('ESTADO_PED').AsString   := 'ABIERTO';
    if FindField('ESCONSOLIDADO_PED') <> nil then
      FieldByName('ESCONSOLIDADO_PED').AsString := 'N';
    if Trim(UbicacionSesion.Empresa) <> '' then
      BuscarEmpresa(UbicacionSesion.Empresa);
  if FindField('CODIGO_ALM_PED') <> nil then
    FieldByName('CODIGO_ALM_PED').AsString := UbicacionSesion.Almacen;
  RefrescarAlmacenes(
    DataSet.FieldByName('CODIGO_EMP_PED').AsString);
end;

procedure TdmPedidos.unqryTablaGBeforePost(DataSet: TDataSet);
begin
  inherited;
  ValidarAlmacenCabecera;
  ValidarClienteCabecera;
  if (unqryTablaG.FieldByName('NUMERO_PED').AsString = '0') or
     (unqryTablaG.FieldByName('NUMERO_PED').AsString = '') then
    GetCodigoAutoPedido;
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'PED');
  CalcularTotalesPedido;
end;

procedure TdmPedidos.unqryTablaGAfterPost(DataSet: TDataSet);
begin
  inherited;
  PersistirAlmacenCabecera;
  // El vendedor no va en el SQL del DFM: se guarda aparte, si la base
  // trae la columna.
  GuardarVendedorRegistro(ConexionEscritura, DataSet, 'fza_pedidos',
    'CODIGO_VENDEDOR_PED', ['NUMERO_PED', 'SERIE_PED']);
end;

procedure TdmPedidos.ValidarBorradoPedido(const ASerie, ANumero: string);
var
  Consulta: TUniQuery;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := ConexionEscritura;
    Consulta.SQL.Text :=
      'SELECT ESTADO_PED FROM fza_pedidos ' +
      'WHERE SERIE_PED=:s AND NUMERO_PED=:n FOR UPDATE';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.Open;
    if Consulta.IsEmpty then
      Abort;
    if SameText(Trim(Consulta.FieldByName('ESTADO_PED').AsString),
      'PARCIAL') or SameText(
      Trim(Consulta.FieldByName('ESTADO_PED').AsString), 'ENTREGADO') then
      raise EValidacionBBDD.CreateFmt(SPedidoVentaConEntregasNoBorrable,
        [ASerie, ANumero]);
    Consulta.Close;
    Consulta.SQL.Text :=
      'SELECT CANTIDAD_ENTREGADA_PEDLIN FROM fza_pedidos_lineas ' +
      'WHERE SERIE_PED_PEDLIN=:s AND NUMERO_PED_PEDLIN=:n FOR UPDATE';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      if Consulta.Fields[0].AsFloat <> 0 then
        raise EValidacionBBDD.CreateFmt(SPedidoVentaConEntregasNoBorrable,
          [ASerie, ANumero]);
      Consulta.Next;
    end;
    Consulta.Close;
    Consulta.SQL.Text :=
      'SELECT NUMERO_ALB FROM fza_albaranes ' +
      'WHERE SERIE_PED_ALB=:s AND NUMERO_PED_ALB=:n LIMIT 1 FOR UPDATE';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.Open;
    if not Consulta.IsEmpty then
      raise EValidacionBBDD.CreateFmt(SPedidoVentaConEntregasNoBorrable,
        [ASerie, ANumero]);
    Consulta.Close;
    Consulta.SQL.Text :=
      'SELECT LINEA_ALBLIN FROM fza_albaranes_lineas ' +
      'WHERE SERIE_PED_ALBLIN=:s AND NUMERO_PED_ALBLIN=:n ' +
      'LIMIT 1 FOR UPDATE';
    Consulta.ParamByName('s').AsString := ASerie;
    Consulta.ParamByName('n').AsString := ANumero;
    Consulta.Open;
    if not Consulta.IsEmpty then
      raise EValidacionBBDD.CreateFmt(SPedidoVentaConEntregasNoBorrable,
        [ASerie, ANumero]);
  finally
    Consulta.Free;
  end;
end;

procedure TdmPedidos.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  q: TUniQuery;
  sSerie: string;
  sNumero: string;
begin
  inherited;
  sSerie  := DataSet.FieldByName('SERIE_PED').AsString;
  sNumero := DataSet.FieldByName('NUMERO_PED').AsString;
  if (sSerie = '') or (sNumero = '') then
  begin
    Abort;
  end;
  if not SolicitarConfirmacion(
    Format(SPreguntaBorrarPedidoVenta,
      [sSerie, sNumero])) then
  begin
    Abort;
  end;
  IniciarBorradoTransaccional;
  try
    ValidarBorradoPedido(sSerie, sNumero);
    RestarPdteServirPedido(sSerie, sNumero, '');
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      q.SQL.Text :=
        'DELETE FROM fza_pedidos_celdas ' +
        'WHERE SERIE_PED_PEDCEL=:s AND NUMERO_PED_PEDCEL=:n';
      q.ParamByName('s').AsString := sSerie;
      q.ParamByName('n').AsString := sNumero;
      q.ExecSQL;
      q.SQL.Text :=
        'DELETE FROM fza_pedidos_lineas ' +
        ' WHERE SERIE_PED_PEDLIN  = :s ' +
        '   AND NUMERO_PED_PEDLIN = :n';
      q.ParamByName('s').AsString := sSerie;
      q.ParamByName('n').AsString := sNumero;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  except
    RevertirBorradoTransaccional;
    raise;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasAfterInsert(DataSet: TDataSet);
begin
  inherited;
  InicializarLineaPedidoVenta(
    DataSet, unqryTablaG, IdentidadSesion.Usuario, Now);
end;

var
  // Instrumentacion temporal (bucle contador 07/07/2026): numero de
  // volcados de pila ya escritos en el log, para no inundarlo.
  iVolcadosPilaLineaVacia: Integer = 0;

// Linea sin identificar el articulo por ninguna via: ni codigo de
// articulo, ni SKU, ni codigo PrestaShop, ni codigo de barras.
function LineaPedidoVacia(ADataSet: TDataSet): Boolean;
  function CampoVacio(const ANombre: string): Boolean;
  var
    Campo: TField;
  begin
    Result := True;
    Campo := ADataSet.FindField(ANombre);
    if Campo <> nil then
      Result := Trim(Campo.AsString) = '';
  end;
begin
  Result := CampoVacio('CODIGO_ART_PEDLIN') and
            CampoVacio('CODIGO_UNIDAD_PEDLIN') and
            CampoVacio('CODIGOPRODPS_PEDLIN') and
            CampoVacio('CODBAR_ART_PEDLIN');
end;

// Instrumentacion TEMPORAL: vuelca la pila de llamadas al log para
// identificar QUIEN esta posteando lineas vacias en bucle (el sintoma
// del 07/07/2026: trio de contador repetido ~13 veces/segundo sin
// ningun INSERT y sin excepcion visible). Maximo 3 volcados por sesion.
procedure VolcarPilaPostLineaVacia(
  const ARegistroLog: IRegistroLog);
var
  Pila: TJclStackInfoList;
  Lineas: TStringList;
begin
  if (iVolcadosPilaLineaVacia < 3) and
     Assigned(ARegistroLog) then
  begin
    Inc(iVolcadosPilaLineaVacia);
    Lineas := TStringList.Create;
    try
      try
        Pila := JclCreateStackList(True, 0, nil);
        try
          Pila.AddToStrings(Lineas, True, True, True, True);
        finally
          FreeAndNil(Pila);
        end;
      except
        // La pila es diagnostico: si JclDebug falla, el aviso sale igual.
        on E: Exception do
          Lineas.Add('(no se pudo capturar la pila: ' + E.Message + ')');
      end;
      ARegistroLog.RegistrarAviso(
        'Post de linea de pedido VACIA rechazado. Pila del llamador:' +
        sLineBreak + Lineas.Text);
    finally
      FreeAndNil(Lineas);
    end;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasBeforePost(DataSet: TDataSet);
begin
  inherited;
  PrepararLineaAntesDeGuardar(DataSet);
end;

procedure TdmPedidos.PrepararLineaAntesDeGuardar(DataSet: TDataSet);
begin
  // Guarda ColumnSKUcxGrid (bucle 07/07/2026): un Post de linea sin
  // articulo no debe llegar a BBDD. Antes de esta guarda, cada intento
  // consumia contador en GetSiguienteLineaDocLibre y el reintento del
  // grid quemaba CONTADOR_LINEAS_PED en bucle (log 17:03 y 17:16).
  if LineaPedidoVacia(DataSet) then
  begin
    VolcarPilaPostLineaVacia(RegistroLog);
    // FZ-ISSUE-422: es una validacion esperada (aviso normal), no un
    // fallo del programa con pila y envio al soporte.
    raise EValidacionBBDD.Create(SErrorLineaPedidoSinArticulo);
  end;
  AsignarNumeroLineaPedido(DataSet);
  NormalizarArticuloSkuEnDataSet(ConexionEscritura, unqryPedidosLineas,
    'CODIGO_ART_PEDLIN', 'CODIGOPRODPS_PEDLIN', 'CODBAR_ART_PEDLIN');
  // FZ-ISSUE-430: la rejilla deja el código del modelo como unidad hasta
  // que se elige talla o color. Sin elegirlos, la unidad se vacía (como en
  // el albarán) y la línea no se graba hasta tener el SKU completo.
  NormalizarArticuloSkuEnDataSet(ConexionEscritura, unqryPedidosLineas,
    'CODIGO_ART_PEDLIN', 'CODIGO_UNIDAD_PEDLIN');
  ExigirSkuCompletoEnDataSet(ConexionEscritura, unqryPedidosLineas,
    'CODIGO_ART_PEDLIN', 'CODIGO_UNIDAD_PEDLIN', 'ID_AC_PIVOT_PEDLIN');
  RecalcularEntregasLinea;
  AplicarEstadoLineaAntesDeGuardar(DataSet);
  PrepararLineaFiscalVenta(CrearLecturasImpuestos(ConexionEscritura),
    unqryTablaG,
    unqryPedidosLineas, 'PED', 'PEDLIN', 'TOTAL_PEDLIN');
  AplicarAuditoriaLineaAntesDeGuardar(DataSet);
end;

procedure TdmPedidos.AplicarEstadoLineaAntesDeGuardar(
  DataSet: TDataSet);
var
  oEntrada: TEntradaEstadoLineaPedidoVenta;
  oEstado: TEstadoLineaPedidoVenta;
begin
  oEntrada := Default(TEntradaEstadoLineaPedidoVenta);
  oEntrada.Cantidad := DataSet.FieldByName('CANTIDAD_PEDLIN').AsFloat;
  if DataSet.FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
    oEntrada.CantidadEntregada := DataSet.FieldByName(
      'CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
  if DataSet.FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
    oEntrada.CantidadAAlbaranar := DataSet.FieldByName(
      'CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat;
  oEstado := CalcularEstadoLineaPedidoVenta(oEntrada);
  AplicarEstadoLineaPedidoVenta(DataSet, oEstado);
end;

procedure TdmPedidos.AplicarAuditoriaLineaAntesDeGuardar(
  DataSet: TDataSet);
begin
  if DataSet.FindField('USUARIO_MODIF') <> nil then
    DataSet.FieldByName('USUARIO_MODIF').AsString :=
      IdentidadSesion.Usuario;
  if DataSet.FindField('INSTANTE_MODIF') <> nil then
    DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  if DataSet.State = dsInsert then
  begin
    if (DataSet.FindField('USUARIO_ALTA') <> nil) and
       (DataSet.FieldByName('USUARIO_ALTA').AsString = '') then
      DataSet.FieldByName('USUARIO_ALTA').AsString :=
        IdentidadSesion.Usuario;
    if (DataSet.FindField('INSTANTE_ALTA') <> nil) and
       DataSet.FieldByName('INSTANTE_ALTA').IsNull then
      DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  end;
end;

procedure TdmPedidos.AsignarNumeroLineaPedido(DataSet: TDataSet);
var
  iNuevaLinea: Integer;
  sLinea: string;
  sNumero: string;
  sSerie: string;
begin
  if DataSet.FindField('LINEA_PEDLIN') <> nil then
  begin
    sLinea := Trim(DataSet.FieldByName('LINEA_PEDLIN').AsString);
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PED').AsString);
    sSerie  := Trim(unqryTablaG.FieldByName('SERIE_PED').AsString);
    if (sLinea = '') or (StrToIntDef(sLinea, 0) = 0) or
       ((DataSet.State = dsInsert) and
        LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
          LIN_PEDIDOS, sSerie, sNumero,
          sLinea)) then
    begin
      if (sNumero = '') or (sNumero = '0') or (sSerie = '') then
        raise Exception.Create(SErrorCabeceraPedidoSinGrabar);
      if DataSet.FindField('NUMERO_PED_PEDLIN') <> nil then
        DataSet.FieldByName('NUMERO_PED_PEDLIN').AsString := sNumero;
      if DataSet.FindField('SERIE_PED_PEDLIN') <> nil then
        DataSet.FieldByName('SERIE_PED_PEDLIN').AsString := sSerie;
      iNuevaLinea := GetSiguienteLineaDocLibre(
        CrearContadorLineasDocumento(ConexionEscritura),
        CONT_PEDIDOS, LIN_PEDIDOS, sSerie, sNumero);
      // El helper ya persiste CONTADOR_LINEAS_PED en BBDD dentro de su
      // propia transaccion. NO se toca unqryTablaG: el Edit anterior
      // dejaba la cabecera en edicion sin postear, y eso disparaba el
      // re-Post de cabecera + recarga del detalle en cada linea. Si la
      // copia en memoria queda desfasada no pasa nada: el helper toma
      // siempre MAX(LINEA_PEDLIN) como suelo.
      if iNuevaLinea = 0 then
        raise Exception.Create(Format(SErrorAsignarLineaPedido,
                                      [sSerie, sNumero]));
      DataSet.FieldByName('LINEA_PEDLIN').AsString :=
        Format('%.4d', [iNuevaLinea]);
    end;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasAfterPost(DataSet: TDataSet);
begin
  inherited;
  CalcularTotalesPedido;
end;

// FZ-ISSUE-442: al borrar una linea el pie seguia con su importe. La
// linea ya esta borrada en la base, asi que la cabecera se graba aqui
// salvo que el usuario la tuviera ya en edicion.
procedure TdmPedidos.unqryPedidosLineasAfterDelete(DataSet: TDataSet);
var
  bCabeceraEnEdicion: Boolean;
begin
  inherited;
  if unqryTablaG.Active and not unqryTablaG.IsEmpty then
  begin
    bCabeceraEnEdicion := unqryTablaG.State in dsEditModes;
    CalcularTotalesPedido;
    if (not bCabeceraEnEdicion) and
       (unqryTablaG.State in dsEditModes) then
      unqryTablaG.Post;
  end;
end;

procedure TdmPedidos.unqryPedidosLineasBeforeDelete(DataSet: TDataSet);
var
  sSerie: string;
  sNumero: string;
  sLinea: string;
begin
  inherited;
  sSerie  := DataSet.FieldByName('SERIE_PED_PEDLIN').AsString;
  sNumero := DataSet.FieldByName('NUMERO_PED_PEDLIN').AsString;
  sLinea  := DataSet.FieldByName('LINEA_PEDLIN').AsString;
  if (sSerie <> '') and (sNumero <> '') and (sLinea <> '') then
  begin
    RestarPdteServirPedido(sSerie, sNumero, sLinea);
  end;
end;

procedure TdmPedidos.RestarPdteServirPedido(const ASerie, ANumero,
                                            ALinea: string);
var
  q: TUniQuery;
  sFiltroLinea: string;
begin
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    sFiltroLinea := '';
    if Trim(ALinea) <> '' then
    begin
      sFiltroLinea := '   AND L.LINEA_PEDLIN = :l ';
    end;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      q.SQL.Text :=
        'UPDATE fza_articulos_stockactual STK ' +
        'JOIN ( ' +
        '  SELECT X.SKU_EFE AS SKU, X.ALM_EFE AS ALM, ' +
        '         SUM(X.PENDIENTE) AS PENDIENTE ' +
        '    FROM ( ' +
        '      SELECT COALESCE(NULLIF(CB.CODIGO_UNIDAD_CB, ''''), ' +
        '                    NULLIF(SREF.CODIGO_UNIDAD_SKU, ''''), ' +
        '                    NULLIF(SART.CODIGO_UNIDAD_SKU, ''''), ' +
        '                    NULLIF(L.CODIGOPRODPS_PEDLIN, ''''), ' +
        '                    NULLIF(L.CODIGO_ART_PEDLIN, '''')) AS SKU_EFE, ' +
        '             NULLIF(L.CODIGO_ALMACEN_PEDLIN, '''') AS ALM_EFE, ' +
        '             GREATEST(IFNULL(L.CANTIDAD_PEDLIN, 0) - ' +
        '                      IFNULL(L.CANTIDAD_ENTREGADA_PEDLIN, 0), ' +
        '                      0) AS PENDIENTE ' +
        '        FROM fza_pedidos_lineas L ' +
        '        LEFT JOIN ( ' +
        '          SELECT CODIGO_BARRAS_CB, ' +
        '                 MIN(CODIGO_UNIDAD_CB) AS CODIGO_UNIDAD_CB ' +
        '            FROM fza_codigos_barras ' +
        '           WHERE CODIGO_BARRAS_CB <> '''' ' +
        '           GROUP BY CODIGO_BARRAS_CB ' +
        '        ) CB ON CB.CODIGO_BARRAS_CB = L.CODBAR_ART_PEDLIN ' +
        '        LEFT JOIN fza_articulos_skus SREF ' +
        '          ON SREF.CODIGO_UNIDAD_SKU = L.CODIGOPRODPS_PEDLIN ' +
        '        LEFT JOIN ( ' +
        '          SELECT CODIGO_ART_SKU, ' +
        '                 MIN(CODIGO_UNIDAD_SKU) AS CODIGO_UNIDAD_SKU ' +
        '            FROM fza_articulos_skus ' +
        '           GROUP BY CODIGO_ART_SKU ' +
        '          HAVING COUNT(*) = 1 ' +
        '        ) SART ON SART.CODIGO_ART_SKU = L.CODIGO_ART_PEDLIN ' +
        '       WHERE L.SERIE_PED_PEDLIN  = :s ' +
        '         AND L.NUMERO_PED_PEDLIN = :n ' +
        sFiltroLinea +
        '    ) X ' +
        '   WHERE X.SKU_EFE IS NOT NULL ' +
        '     AND X.SKU_EFE <> '''' ' +
        '     AND X.ALM_EFE IS NOT NULL ' +
        '     AND X.ALM_EFE <> '''' ' +
        '     AND X.PENDIENTE > 0 ' +
        '   GROUP BY X.SKU_EFE, X.ALM_EFE ' +
        ') P ON P.SKU = STK.CODIGO_UNIDAD_STK ' +
        '   AND P.ALM = STK.CODIGO_ALM_STK ' +
        '   AND STK.LOTE_STK = '''' ' +
        '   SET STK.CANTIDAD_PTE_SERVIR_STK = ' +
        '       GREATEST(IFNULL(STK.CANTIDAD_PTE_SERVIR_STK, 0) - ' +
        '                P.PENDIENTE, 0), ' +
        '       STK.INSTANTE_MODIF = NOW()';
      q.ParamByName('s').AsString := ASerie;
      q.ParamByName('n').AsString := ANumero;
      if Trim(ALinea) <> '' then
      begin
        q.ParamByName('l').AsString := ALinea;
      end;
      q.ExecSQL;
    finally
      FreeAndNil(q);
    end;
  end;
end;

procedure TdmPedidos.RecalcularEntregasLinea;
var
  fCant, fEntr, fPend, fAAlbaranar: Double;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := unqryPedidosLineas.FieldByName(ANombre);
  end;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryPedidosLineas.FindField(ANombre);
  end;
begin
  fCant := FieldByName('CANTIDAD_PEDLIN').AsFloat;
    if FindField('CANTIDAD_ENTREGADA_PEDLIN') <> nil then
    begin
      fEntr := FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat;
      if fEntr > fCant then
      begin
        FieldByName('CANTIDAD_ENTREGADA_PEDLIN').AsFloat := fCant;
        fEntr := fCant;
      end;
      fPend := fCant - fEntr;
      if fPend < 0 then
        fPend := 0;
      if FindField('CANTIDAD_A_ALBARANAR_PEDLIN') <> nil then
      begin
        fAAlbaranar := FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat;
        if fAAlbaranar < 0 then
          fAAlbaranar := 0;
        if fAAlbaranar > fPend then
          fAAlbaranar := fPend;
        FieldByName('CANTIDAD_A_ALBARANAR_PEDLIN').AsFloat := fAAlbaranar;
      end;
      if FindField('CANTIDAD_PENDIENTE_PEDLIN') <> nil then
        FieldByName('CANTIDAD_PENDIENTE_PEDLIN').AsFloat := fPend;
      if FindField('ESENTREGADA_PEDLIN') <> nil then
      begin
        if fPend <= 0 then
          FieldByName('ESENTREGADA_PEDLIN').AsString := 'S'
        else
          FieldByName('ESENTREGADA_PEDLIN').AsString := 'N';
    end;
  end;
end;

procedure TdmPedidos.GetCodigoAutoPedido;
begin
  unstrdprcGetContadorPedido.Params.Clear;
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pserie', ptInput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pEMPRESA_CONTADOR', ptInput);
  unstrdprcGetContadorPedido.Params.CreateParam(
    ftString, 'pUSUARIOMODIF', ptInput);
  unstrdprcGetContadorPedido.ParamByName('pserie').AsString :=
    unqryTablaG.FieldByName('SERIE_PED').AsString;
  unstrdprcGetContadorPedido.ParamByName('ptipodoc').AsString :=
    CrearConfiguracionDocumento(tdPedido, sdVenta).TipoContador;
  unstrdprcGetContadorPedido.ParamByName('pUSUARIOMODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContadorPedido.ParamByName(
    'pEMPRESA_CONTADOR').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString;
  EjecutarContadorDocumento(unstrdprcGetContadorPedido);
  unqryTablaG.FieldByName('NUMERO_PED').AsString :=
    unstrdprcGetContadorPedido.ParamByName('pcont').AsString;
end;

// FZ-ISSUE-219: el Total de la linea se refresca al aceptar la cantidad
// o el precio, no solo al grabar (como FZ-202 en albaranes). El
// desempaquetado de atributos solo toca ATTR*, que aqui no cuentan.
procedure TdmPedidos.LineasPedidoDataChange(Sender: TObject;
  Field: TField);
begin
  if not FAplicandoDescuento then
  begin
    FAplicandoDescuento := True;
    try
      AplicarDescuentoLineaVenta(Field, 'PEDLIN');
      if EsCampoImporteLineaVenta(Field, 'PEDLIN') then
        RecalcularTotalLineaVenta(unqryPedidosLineas, 'PEDLIN',
          'TOTAL_PEDLIN');
    finally
      FAplicandoDescuento := False;
    end;
  end;
end;

procedure TdmPedidos.CalcularTotalesPedido;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      CalcularTotalesDocumentoVenta(
        CrearLecturasImpuestos(ConexionEscritura), unqryTablaG,
        unqryPedidosLineas, 'PED', 'TOTAL_PEDLIN',
        'TIPO_IVA_ARTICULO_PEDLIN', 'PORCENTAJE_IVA_PEDLIN');
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

function TdmPedidos.TotalPrendasPedido: Double;
begin
  Result := TotalPrendasLineasVenta(unqryPedidosLineas,
    'TIPO_IVA_ARTICULO_PEDLIN');
end;

function TdmPedidos.BuscarEmpresa(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_empresas ' +
                    ' WHERE CODIGO_EMP_EMP = :empresa';
      q.ParamByName('empresa').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        // CopiarEmpresaaPedido ya repropone la serie de la empresa
        CopiarEmpresaaPedido(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPedidos.BuscarAlmacen(const ACodigo: string): Boolean;
var
  qAlm: TUniQuery;
  sCodigo: string;
  sEmpresa: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if sCodigo <> '' then
  begin
    qAlm := TUniQuery.Create(nil);
    try
      qAlm.Connection := unqryTablaG.Connection;
      qAlm.SQL.Text :=
        'SELECT CODIGO_ALM_ALM, CODIGO_EMP_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_ALM_ALM = :alm ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S''';
      qAlm.ParamByName('alm').AsString := sCodigo;
      qAlm.Open;
      if not qAlm.IsEmpty then
      begin
        sEmpresa := qAlm.FieldByName('CODIGO_EMP_ALM').AsString;
        if sEmpresa <> '' then
          BuscarEmpresa(sEmpresa);
        if not (unqryTablaG.State in [dsEdit, dsInsert]) then
          unqryTablaG.Edit;
        if unqryTablaG.FindField('CODIGO_ALM_PED') <> nil then
          unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString := sCodigo;
        Result := True;
      end;
    finally
      FreeAndNil(qAlm);
    end;
  end;
end;

procedure TdmPedidos.ValidarAlmacenCabecera;
begin
  if (unqryTablaG.FindField('CODIGO_ALM_PED') <> nil) and
     (Trim(unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString) = '') then
  begin
    NotificarAdvertencia(SAvisoAlmacenSalidaPedidoObligatorio);
    Abort;
  end;
end;

procedure TdmPedidos.ValidarClienteCabecera;
var
  sCliente: string;
begin
  sCliente := '';
  if unqryTablaG.FindField('CODIGO_CLI_PED') <> nil then
    sCliente := Trim(unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString);
  if (sCliente = '') or (sCliente = '0') then
  begin
    NotificarAdvertencia(SAvisoClientePedidoObligatorio);
    Abort;
  end;
  if not ClienteExiste(sCliente) then
  begin
    NotificarAdvertencia(
      Format(SAvisoClientePedidoNoExiste, [sCliente]));
    Abort;
  end;
end;

procedure TdmPedidos.PersistirAlmacenCabecera;
var
  q: TUniQuery;
  sAlmacen: string;
  sNumero: string;
  sSerie: string;
begin
  if unqryTablaG.FindField('CODIGO_ALM_PED') <> nil then
  begin
    sAlmacen := Trim(unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString);
    sNumero  := Trim(unqryTablaG.FieldByName('NUMERO_PED').AsString);
    sSerie   := Trim(unqryTablaG.FieldByName('SERIE_PED').AsString);
    if (sAlmacen <> '') and (sNumero <> '') and (sSerie <> '') then
    begin
      q := TUniQuery.Create(nil);
      try
        q.Connection := unqryTablaG.Connection;
        q.SQL.Text :=
          'UPDATE fza_pedidos ' +
          '   SET CODIGO_ALM_PED = :alm ' +
          ' WHERE NUMERO_PED = :num ' +
          '   AND SERIE_PED = :ser';
        q.ParamByName('alm').AsString := sAlmacen;
        q.ParamByName('num').AsString := sNumero;
        q.ParamByName('ser').AsString := sSerie;
        q.ExecSQL;
      finally
        FreeAndNil(q);
      end;
    end;
  end;
end;

procedure TdmPedidos.ProponerSerieEmpresa(const AEmpresa: string);
var
  sSerie: string;
  sNumero: string;
begin
  if (unqryTablaG.State in [dsInsert, dsEdit]) then
  begin
    sNumero := Trim(unqryTablaG.FieldByName('NUMERO_PED').AsString);
    // Solo documentos nuevos sin numerar: un documento ya numerado
    // conserva su serie aunque se retoque la empresa
    if (sNumero = '') or (sNumero = '0') then
    begin
      sSerie := ObtenerSerieDefecto(
        ConexionEscritura,
        AEmpresa,
        CrearConfiguracionDocumento(
          tdPedido, sdVenta).TipoContador);
      if sSerie <> '' then
        unqryTablaG.FieldByName('SERIE_PED').AsString := sSerie;
    end;
  end;
end;

function TdmPedidos.BuscarCliente(const ACodigo: string): Boolean;
var
  q: TUniQuery;
  sCodigo: string;
begin
  Result := False;
  sCodigo := Trim(ACodigo);
  if (sCodigo <> '') and (sCodigo <> '0') then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text := 'SELECT * ' +
                    '  FROM fza_clientes ' +
                    ' WHERE CODIGO_CLI_CLI = :cliente';
      q.ParamByName('cliente').AsString := sCodigo;
      q.Open;
      if not q.IsEmpty then
      begin
        CopiarClienteaPedido(q);
        Result := True;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function TdmPedidos.ClienteExiste(const ACodigo: string): Boolean;
begin
  Result := ExisteClienteCodigo(unqryTablaG.Connection, ACodigo);
end;

procedure TdmPedidos.CopiarEmpresaaPedido(DataSet: TDataSet);
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_EMP_PED').AsString             :=
      DataSet.FindField('CODIGO_EMP_EMP').AsString;
    FindField('RAZON_SOCIAL_EMPRESA_PED').AsString   :=
      DataSet.FindField('RAZON_SOCIAL_EMP').AsString;
    FindField('NIF_EMPRESA_PED').AsString            :=
      DataSet.FindField('NIF_EMP').AsString;
    FindField('MOVIL_EMPRESA_PED').AsString          :=
      DataSet.FindField('MOVIL_EMP').AsString;
    FindField('EMAIL_EMPRESA_PED').AsString          :=
      DataSet.FindField('EMAIL_EMP').AsString;
    FindField('DIRECCION1_EMPRESA_PED').AsString     :=
      DataSet.FindField('DIRECCION1_EMP').AsString;
    FindField('DIRECCION2_EMPRESA_PED').AsString     :=
      DataSet.FindField('DIRECCION2_EMP').AsString;
    FindField('POBLACION_EMPRESA_PED').AsString      :=
      DataSet.FindField('POBLACION_EMP').AsString;
    FindField('PROVINCIA_EMPRESA_PED').AsString      :=
      DataSet.FindField('PROVINCIA_EMP').AsString;
    FindField('CODIGO_POSTAL_EMPRESA_PED').AsString  :=
      DataSet.FindField('CODIGO_POSTAL_EMP').AsString;
    FindField('NOMBRE_PAI_EMPRESA_PED').AsString     :=
      DataSet.FindField('NOMBRE_PAI_EMP').AsString;
    FindField('CODIGO_PAI_EMPRESA_PED').AsString     :=
      DataSet.FindField('CODIGO_PAI_EMP').AsString;
    FindField('GRUPO_ZONA_IVA_EMPRESA_PED').AsString :=
      DataSet.FindField('GRUPO_ZONA_IVA_EMP').AsString;
    FindField('ESRETENCIONES_EMPRESA_PED').AsString  :=
      DataSet.FindField('ESRETENCIONES_EMP').AsString;
  FindField('ESREGIMENESPECIALAGRICOLA_EMPRESA_PED').AsString :=
    DataSet.FindField('ESREGIMENESPECIALAGRICOLA_EMP').AsString;
  // La serie acompana a la empresa emisora (fza_empresas_series).
  // Cubre las dos rutas: codigo tecleado (BuscarEmpresa) y modal.
  ProponerSerieEmpresa(DataSet.FindField('CODIGO_EMP_EMP').AsString);
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'PED');
end;

procedure TdmPedidos.ActualizarImpuestosTarifaCabecera(
  const ACodigoTarifa: string);
var
  sTarifa: string;
begin
  sTarifa := Trim(ACodigoTarifa);
  if unqryTablaG.Active and (unqryTablaG.State in dsEditModes) then
  begin
    if sTarifa = '' then
      unqryTablaG.FieldByName(
        'ESIMP_INCL_TARIFA_CLIENTE_PED').Clear
    else
    begin
      if not unqryTarifas.Active then
        unqryTarifas.Open;
      if unqryTarifas.Locate('CODIGO_TAR_ARTTAR', sTarifa, []) then
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PED').AsString :=
          unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString
      else
        unqryTablaG.FieldByName(
          'ESIMP_INCL_TARIFA_CLIENTE_PED').Clear;
    end;
  end;
end;

procedure TdmPedidos.CopiarClienteaPedido(DataSet: TDataSet);
var
  sTarifa: string;
  function FindField(const ANombre: string): TField;
  begin
    Result := unqryTablaG.FindField(ANombre);
  end;
begin
  if (unqryTablaG.State <> dsEdit) and
     (unqryTablaG.State <> dsInsert) then
    unqryTablaG.Edit;
    FindField('CODIGO_CLI_PED').AsString                  :=
      DataSet.FindField('CODIGO_CLI_CLI').AsString;
    FindField('RAZON_SOCIAL_CLIENTE_FISCAL_PED').AsString :=
      DataSet.FindField('RAZON_SOCIAL_CLI').AsString;
    FindField('NIF_CLIENTE_PED').AsString                 :=
      DataSet.FindField('NIF_CLI').AsString;
    FindField('MOVIL_CLIENTE_FISCAL_PED').AsString        :=
      DataSet.FindField('MOVIL_CLI').AsString;
    FindField('EMAIL_CLIENTE_PED').AsString               :=
      DataSet.FindField('EMAIL_CLI').AsString;
    FindField('DIRECCION1_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('DIRECCION1_CLI').AsString;
    FindField('DIRECCION2_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('DIRECCION2_CLI').AsString;
    FindField('POBLACION_CLIENTE_FISCAL_PED').AsString    :=
      DataSet.FindField('POBLACION_CLI').AsString;
    FindField('PROVINCIA_CLIENTE_FISCAL_PED').AsString    :=
      DataSet.FindField('PROVINCIA_CLI').AsString;
    FindField('CODIGO_POSTAL_CLIENTE_FISCAL_PED').AsString:=
      DataSet.FindField('CODIGO_POSTAL_CLI').AsString;
    FindField('NOMBRE_PAI_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('NOMBRE_PAI_CLI').AsString;
    FindField('CODIGO_PAI_CLIENTE_FISCAL_PED').AsString   :=
      DataSet.FindField('CODIGO_PAI_CLI').AsString;
    FindField('ESIVA_RECARGO_CLIENTE_PED').AsString       :=
      DataSet.FindField('ESIVA_RECARGO_CLI').AsString;
    FindField('ESIVA_EXENTO_CLIENTE_PED').AsString        :=
      DataSet.FindField('ESIVA_EXENTO_CLI').AsString;
    FindField('ESREGIMENESPECIALAGRICOLA_CLIENTE_PED').AsString :=
      DataSet.FindField(
        'ESREGIMENESPECIALAGRICOLA_CLI').AsString;
    FindField('ESRETENCIONES_CLIENTE_PED').AsString       :=
      DataSet.FindField('ESRETENCIONES_CLI').AsString;
    FindField('ESINTRACOMUNITARIO_CLIENTE_PED').AsString  :=
      DataSet.FindField('ESINTRACOMUNITARIO_CLI').AsString;
    sTarifa := Trim(DataSet.FindField('TARIFA_ARTICULO_CLI').AsString);
    if sTarifa = '' then
      sTarifa := ParametrosCaja.TarifaDefecto;
    FindField('TARIFA_ARTICULO_CLIENTE_PED').AsString := sTarifa;
    ActualizarImpuestosTarifaCabecera(sTarifa);
  if (FindField('FORMA_PAGO_PED') <> nil) and
     (DataSet.FindField('CODIGO_FP_CLI') <> nil) and
     (Trim(DataSet.FindField('CODIGO_FP_CLI').AsString) <> '') then
    FindField('FORMA_PAGO_PED').AsString :=
      Trim(DataSet.FindField('CODIGO_FP_CLI').AsString);
  ProponerVendedorCliente(DataSet, unqryTablaG, 'CODIGO_VENDEDOR_PED');
  AplicarPorcentajesIvaVenta(
    CrearLecturasImpuestos(ConexionEscritura), unqryTablaG, 'PED');
end;

procedure TdmPedidos.CopiarFormaPagoPedidoAAlbaran(const ASeriePed,
                                                   ANumeroPed, ASerieAlb,
                                                   ANumeroAlb: string;
                                                   AForzar: Boolean);
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionEscritura;
    q.SQL.Text :=
      'UPDATE fza_albaranes A ' +
      '  JOIN fza_pedidos P ' +
      '    ON P.SERIE_PED = :sped ' +
      '   AND P.NUMERO_PED = :nped ' +
      '   SET A.FORMA_PAGO_ALB = NULLIF(P.FORMA_PAGO_PED, ''''), ' +
      '       A.INSTANTE_MODIF = NOW(), ' +
      '       A.USUARIO_MODIF = :u ' +
      ' WHERE A.SERIE_ALB = :salb ' +
      '   AND A.NUMERO_ALB = :nalb ' +
      '   AND TRIM(IFNULL(P.FORMA_PAGO_PED, '''')) <> '''' ' +
      '   AND (:forzar = ''S'' ' +
      '        OR TRIM(IFNULL(A.FORMA_PAGO_ALB, '''')) = '''')';
    q.ParamByName('sped').AsString := ASeriePed;
    q.ParamByName('nped').AsString := ANumeroPed;
    q.ParamByName('salb').AsString := ASerieAlb;
    q.ParamByName('nalb').AsString := ANumeroAlb;
    q.ParamByName('u').AsString := IdentidadSesion.Usuario;
    if AForzar then
      q.ParamByName('forzar').AsString := 'S'
    else
      q.ParamByName('forzar').AsString := 'N';
    q.ExecSQL;
  finally
    FreeAndNil(q);
  end;
end;




function TdmPedidos.CrearAlbaranDesdePedido(out sNumeroAlb, sSerieAlb: string;
                                            aLineas: TList<TPair<string,
                                            Currency>>;
                                            const ACodigoAlmacen: string;
                                            const AAlbExistenteNum: string;
                                            const AAlbExistenteSerie: string;
                                            const AAlbaranNuevo:
                                              TDatosAlbaranNuevoPedido)
                                            : Boolean;
var
  Contexto: TContextoCreacionAlbaranPedido;
  bTransPropia: Boolean;
  LineasAnteriores: Int64;
  sUltimaLinea: string;
begin
  Result := False;
  sNumeroAlb := '';
  sSerieAlb := '';
  if (aLineas <> nil) and (aLineas.Count > 0) then
  begin
    Contexto := ContextoAlbaranDesdePedido(ACodigoAlmacen, AAlbaranNuevo);
    if Trim(AAlbExistenteNum) = '' then
      PrepararNumeracionAlbaranPedido(Contexto);
    bTransPropia := not ConexionEscritura.InTransaction;
    if bTransPropia then
      ConexionEscritura.StartTransaction;
    try
      PrepararCabeceraAlbaranPedido(Contexto, AAlbExistenteNum,
        AAlbExistenteSerie, sNumeroAlb, sSerieAlb);
      LineasAnteriores := ContarLineasAlbaranPedido(
        ConexionEscritura, Contexto);
      sUltimaLinea := UltimaLineaAlbaranPedido(ConexionEscritura,
        Contexto.SerieAlbaran, Contexto.NumeroAlbaran);
      EjecutarLineasAlbaranPedido(
        unstrdprcCrearAlbaranLinea, Contexto, aLineas);
      if ContarLineasAlbaranPedido(ConexionEscritura, Contexto) <=
         LineasAnteriores then
        raise Exception.Create(SErrorPedidoVentaSinCantidadAlbaranar);
      // FZ-ISSUE-336: lote o serie por FEFO antes de los totales (el fin
      // recalcula el albarán) y salida de stock antes del commit.
      RepartirLotesAlbaranPedido(ConexionEscritura,
        Contexto.SerieAlbaran, Contexto.NumeroAlbaran, sUltimaLinea);
      EjecutarFinAlbaranPedido(unstrdprcCrearAlbaranFin, Contexto);
      CopiarDescuentosPedidoAlbaran(ConexionEscritura,
        Contexto.SerieAlbaran, Contexto.NumeroAlbaran, sUltimaLinea);
      GenerarMovimientosAlbaranPedido(Self, ConexionEscritura,
        Contexto.SerieAlbaran, Contexto.NumeroAlbaran);
      LimpiarCantidadesPedidoAlbaran(ConexionEscritura, Contexto);
      if bTransPropia then
        ConexionEscritura.Commit;
    except
      if bTransPropia then
        ConexionEscritura.Rollback;
      raise;
    end;
    Result := True;
    RefrescarTrasCrearAlbaranPedido(sSerieAlb, sNumeroAlb, bTransPropia);
  end;
end;

function TdmPedidos.ExistePedidoPrestaShop(
  const AOrigen, sIdPS: string): Boolean;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionEscritura;
    q.SQL.Text :=
      'SELECT 1 FROM fza_pedidos ' +
      ' WHERE IDPS_PED = :ID ' +
      '   AND (ORIGENPS_PED = :ORIGEN ' +
      '        OR COALESCE(ORIGENPS_PED, '''') = '''') ' +
      ' LIMIT 1';
    q.ParamByName('ID').AsString := sIdPS;
    q.ParamByName('ORIGEN').AsString := AOrigen;
    q.Open;
    Result := q.RecordCount > 0;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;

function TdmPedidos.ContextoAlbaranDesdePedido(
  const ACodigoAlmacen: string;
  const AAlbaranNuevo: TDatosAlbaranNuevoPedido)
  : TContextoCreacionAlbaranPedido;
begin
  Result := Default(TContextoCreacionAlbaranPedido);
  Result.NumeroPedido := unqryTablaG.FieldByName('NUMERO_PED').AsString;
  Result.SeriePedido := unqryTablaG.FieldByName('SERIE_PED').AsString;
  Result.CodigoAlmacen := ACodigoAlmacen;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.AlbaranNuevo := AAlbaranNuevo;
end;

// Solo para un albaran nuevo con serie elegida en el dialogo.
procedure TdmPedidos.PrepararNumeracionAlbaranPedido(
  var AContexto: TContextoCreacionAlbaranPedido);
begin
  if Trim(AContexto.AlbaranNuevo.Serie) <> '' then
    PrepararNumeracionDocumento(ConexionEscritura, dnAlbaranVenta,
      unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString,
      AContexto.AlbaranNuevo.Serie, AContexto.Usuario,
      AContexto.AlbaranNuevo.NumeroManual, RegistroLog,
      function(AMensaje: string): Boolean
      begin
        Result := SolicitarConfirmacion(AMensaje);
      end);
end;

// Dentro de la transaccion: bloquea el albaran existente o crea la
// cabecera del nuevo, y copia la forma de pago del pedido.
procedure TdmPedidos.PrepararCabeceraAlbaranPedido(
  var AContexto: TContextoCreacionAlbaranPedido;
  const AAlbExistenteNum, AAlbExistenteSerie: string;
  var ANumeroAlb, ASerieAlb: string);
begin
  if Trim(AAlbExistenteNum) <> '' then
  begin
    AContexto.NumeroAlbaran := AAlbExistenteNum;
    AContexto.SerieAlbaran := AAlbExistenteSerie;
    ANumeroAlb := AContexto.NumeroAlbaran;
    ASerieAlb := AContexto.SerieAlbaran;
    BloquearAlbaranDestinoPedido(ConexionEscritura, AContexto);
    CopiarFormaPagoPedidoAAlbaran(
      AContexto.SeriePedido, AContexto.NumeroPedido,
      AContexto.SerieAlbaran, AContexto.NumeroAlbaran, False);
  end
  else
  begin
    EjecutarInicioAlbaranPedido(
      unstrdprcCrearAlbaranInicio, AContexto);
    ANumeroAlb := AContexto.NumeroAlbaran;
    ASerieAlb := AContexto.SerieAlbaran;
    // La forma de pago elegida en el diálogo manda sobre la del pedido.
    if Trim(AContexto.AlbaranNuevo.FormaPago) = '' then
      CopiarFormaPagoPedidoAAlbaran(
        AContexto.SeriePedido, AContexto.NumeroPedido,
        AContexto.SerieAlbaran, AContexto.NumeroAlbaran, True);
  end;
end;

// Con transaccion propia el albaran ya esta confirmado: un fallo al
// refrescar solo se avisa. Con transaccion ajena se propaga.
procedure TdmPedidos.RefrescarTrasCrearAlbaranPedido(const ASerieAlb,
  ANumeroAlb: string; ATransPropia: Boolean);
begin
  try
    unqryPedidosLineas.Close;
    unqryPedidosLineas.Open;
    unqryAlbaranes.Close;
    unqryAlbaranes.Open;
    unqryTablaG.RefreshRecord;
  except
    on E: Exception do
    begin
      if not ATransPropia then
        raise;
      RegistroLog.RegistrarAviso('Albarán guardado sin refresco: ' +
        ASerieAlb + '/' + ANumeroAlb + '. ' + E.Message);
      NotificarAdvertencia(Format(SAvisoAlbaranPedidoCreadoSinRefresco,
        [ASerieAlb, ANumeroAlb, E.Message]));
    end;
  end;
end;

function TdmPedidos.UltimoIdPedidoPrestaShop(
  const AOrigen: string): Int64;
var
  q: TUniQuery;
begin
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionEscritura;
    q.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(IDPS_PED AS UNSIGNED)), 0) AS ULTIMO ' +
      '  FROM fza_pedidos ' +
      ' WHERE COALESCE(IDPS_PED, '''') <> '''' ' +
      '   AND (ORIGENPS_PED = :ORIGEN ' +
      '        OR COALESCE(ORIGENPS_PED, '''') = '''')';
    q.ParamByName('ORIGEN').AsString := AOrigen;
    q.Open;
    Result := q.FieldByName('ULTIMO').AsLargeInt;
    q.Close;
  finally
    FreeAndNil(q);
  end;
end;

function TdmPedidos.ObtenerContador(const sTipo: string): string;
begin
  unstrdprcGetContador.Params.Clear;
  unstrdprcGetContador.Params.CreateParam(
    ftString, 'ptipodoc', ptInput);
  unstrdprcGetContador.Params.CreateParam(
    ftString, 'pcont', ptOutput);
  unstrdprcGetContador.Params.CreateParam(
    ftString, 'pUSUARIO_MODIF', ptInput);
  unstrdprcGetContador.ParamByName('ptipodoc').AsString := sTipo;
  unstrdprcGetContador.ParamByName('pUSUARIO_MODIF').AsString :=
    IdentidadSesion.Usuario;
  unstrdprcGetContador.ExecProc;
  Result := unstrdprcGetContador.ParamByName('pcont').AsString;
end;

function TdmPedidos.ResolverCodigoCliente(aOrder: TOrder): string;
var
  q: TUniQuery;
  sNif, sEmail, sRazon: string;
  sDir1, sDir2, sPobl, sProv, sCP, sMovil, sOrden: string;
begin
  Result := '0';
  if aOrder <> nil then
  begin
  // Identificadores de busqueda: se prioriza el domicilio fiscal (Bil)
  sNif := aOrder.Vat_numberBil;
  if sNif = '' then
    sNif := aOrder.DniBil;
  if sNif = '' then
    sNif := aOrder.Vat_numberDel;
  if sNif = '' then
    sNif := aOrder.DniDel;
  sEmail := aOrder.custMail;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionEscritura;
    // 1) Buscar por NIF
    if sNif <> '' then
    begin
      q.SQL.Text :=
        'SELECT CODIGO_CLI_CLI FROM fza_clientes WHERE NIF_CLI = :nif LIMIT 1';
      q.ParamByName('nif').AsString := sNif;
      q.Open;
      if q.RecordCount > 0 then
        Result := q.Fields[0].AsString;
      q.Close;
    end;
    // 2) Si no hay match por NIF, buscar por email
    if (Result = '0') and (sEmail <> '') then
    begin
      q.SQL.Text :=
        'SELECT CODIGO_CLI_CLI FROM fza_clientes WHERE EMAIL_CLI = :ema ' +
        'LIMIT 1';
      q.ParamByName('ema').AsString := sEmail;
      q.Open;
      if q.RecordCount > 0 then
        Result := q.Fields[0].AsString;
      q.Close;
    end;
    // 3) Si sigue sin encontrarse, dar de alta el cliente nuevo
    if Result = '0' then
    begin
      // Datos del nuevo cliente (domicilio fiscal con fallback a envio)
      sRazon := aOrder.CompanyBil;
      if sRazon = '' then
        sRazon := Trim(aOrder.FirstnameBil + ' ' + aOrder.LastNameBil);
      if sRazon = '' then
        sRazon := aOrder.custName;
      sDir1 := aOrder.Address1Bil;
      if sDir1 = '' then
        sDir1 := aOrder.Address1Del;
      sDir2 := aOrder.Address2Bil;
      if sDir2 = '' then
        sDir2 := aOrder.Address2Del;
      sPobl := aOrder.CityBil;
      if sPobl = '' then
        sPobl := aOrder.CityDel;
      sProv := aOrder.NameStateBil;
      if sProv = '' then
        sProv := aOrder.NameStateDel;
      sCP := aOrder.PostcodeBil;
      if sCP = '' then
        sCP := aOrder.PostcodeDel;
      sMovil := aOrder.PhoneBil;
      if sMovil = '' then
        sMovil := aOrder.PhoneDel;
      // PRC_GET_NEXT_CONT respeta la transacción de la importación.
      Result := ObtenerContador('CL');
      sOrden := ObtenerContador('CO');
      q.SQL.Text :=
        'INSERT INTO fza_clientes (CODIGO_CLI_CLI, ORDEN_CLI, ' +
        ' RAZON_SOCIAL_CLI, NIF_CLI, EMAIL_CLI, MOVIL_CLI, ' +
        ' DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, ' +
        ' CODIGO_POSTAL_CLI, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:cod, :ord, :raz, :nif, :ema, :mov, ' +
        '        :dir1, :dir2, :pob, :prov, :cp, NOW(), :usu, :usu)';
      q.ParamByName('cod').AsString  := Result;
      q.ParamByName('ord').AsInteger := StrToIntDef(sOrden, 0);
      q.ParamByName('raz').AsString  := sRazon;
      q.ParamByName('nif').AsString  := sNif;
      q.ParamByName('ema').AsString  := sEmail;
      q.ParamByName('mov').AsString  := sMovil;
      q.ParamByName('dir1').AsString := sDir1;
      q.ParamByName('dir2').AsString := sDir2;
      q.ParamByName('pob').AsString  := sPobl;
      q.ParamByName('prov').AsString := sProv;
      q.ParamByName('cp').AsString   := sCP;
      q.ParamByName('usu').AsString  := IdentidadSesion.Usuario;
      q.Execute;
    end;
  finally
    FreeAndNil(q);
  end;
  end;
end;

function TdmPedidos.ResolverCodigoArticulo(
  const oValidador: IArticulosValidador;
  const lp: TLineaPed): string;
var
  res: TArtResolucionEntrada;
  q: TUniQuery;
  sOrden, sDesc: string;
  bTx: Boolean;
  Alta: TTrazabilidadAlta;
begin
  Result := '';
  // 1) Match: primero por EAN13, luego por referencia PS
  res := oValidador.ResolverCodigoBarras(lp.sCodEAN13);
  if (not res.Encontrado) and (lp.sRefProd <> '') then
    res := oValidador.Resolver(lp.sRefProd);
  if res.Encontrado then
    Result := res.CodigoArticulo
  else
  begin
    // 2) Alta rapida: articulo sin variacion + SKU + codigo de barras.
    //    PS no aporta familia, por lo que se numera con el contador 'AR'.
    //    El IVA por defecto es 'N' (Normal); revisar si fuera reducido.
    Result := ObtenerContador('AR');
    sOrden := ObtenerContador('AO');
    sDesc  := lp.sDescripcion;
    if sDesc = '' then
      sDesc := 'Articulo PrestaShop ' + Result;
    q := TUniQuery.Create(nil);
    try
      q.Connection := ConexionEscritura;
      // Las 3 altas (articulo + SKU + barras) deben ser atomicas entre si
      bTx := not ConexionEscritura.InTransaction;
      if bTx then
        ConexionEscritura.StartTransaction;
      try
        // Articulo padre (ESVARIACION_ART = 'N', IVA Normal por defecto)
        q.SQL.Text :=
          'INSERT INTO fza_articulos (CODIGO_ART_ART, ORDEN_ART, ' +
          ' ESACTIVO_ART, TIPO_ART, DESCRIPCION_ART, TIPO_IVA_ART, ' +
          ' ESACTIVO_FIJO_ART, TIPO_CANTIDAD_ART, ESVARIACION_ART, ' +
          ' ESTRAZABLE_ART, TIPO_TRAZABILIDAD_ART, ESCADUCIDAD_ART, ' +
          ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES (:cod, :ord, ''S'', ''ESTANDAR'', :des, ''N'', ' +
          '        ''N'', ''Uds'', ''N'', :traz, :modo, :cad, NOW(), ' +
          '        :usu, :usu)';
        // Sin familia en el pedido PrestaShop, nace sin trazabilidad.
        Alta := TrazabilidadAltaFamilia(TRAZABILIDAD_FAMILIA_NINGUNA);
        q.ParamByName('traz').AsString := Alta.ValorEsTrazable;
        q.ParamByName('modo').AsString := Alta.ValorModo;
        q.ParamByName('cad').AsString := Alta.ValorCaducidad;
        q.ParamByName('cod').AsString  := Result;
        q.ParamByName('ord').AsInteger := StrToIntDef(sOrden, 0);
        q.ParamByName('des').AsString  := sDesc;
        q.ParamByName('usu').AsString  := IdentidadSesion.Usuario;
        q.Execute;
        // SKU unico (sin variacion: CODIGO_VAR_SKU = '-')
        q.SQL.Text :=
          'INSERT INTO fza_articulos_skus (CODIGO_UNIDAD_SKU, ' +
          ' CODIGO_ART_SKU, CODIGO_VAR_SKU, ESACTIVO_SKU, ' +
          ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
          'VALUES (:cod, :cod, ''-'', ''S'', NOW(), :usu, :usu)';
        q.ParamByName('cod').AsString := Result;
        q.ParamByName('usu').AsString := IdentidadSesion.Usuario;
        q.Execute;
        // Codigo de barras (solo si la linea trae EAN13)
        if lp.sCodEAN13 <> '' then
        begin
          q.SQL.Text :=
            'INSERT INTO fza_codigos_barras (CODIGO_BARRAS_CB, ' +
            ' CODIGO_UNIDAD_CB, TIPO_CODIGO_CB, ESPRINCIPAL_CB, ' +
            ' INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
            'VALUES (:ean, :cod, ''EAN13'', ''S'', NOW(), :usu, :usu)';
          q.ParamByName('ean').AsString := lp.sCodEAN13;
          q.ParamByName('cod').AsString := Result;
          q.ParamByName('usu').AsString := IdentidadSesion.Usuario;
          q.Execute;
        end;
        if bTx then
          ConexionEscritura.Commit;
      except
        if bTx and ConexionEscritura.InTransaction then
          ConexionEscritura.Rollback;
        raise;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
end;

function ReservarNumeroPedidoPrestaShop(AConexion: TUniConnection;
  const AEmpresa, ASerie, AUsuario: string): string;
var
  Consulta: TUniQuery;
  Procedimiento: TUniStoredProc;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'INSERT INTO fza_contadores ' +
      '(TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, CON, NUM_DIGITOS_CON, ' +
      'ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, USUARIO_ALTA, ' +
      'USUARIO_MODIF) ' +
      'VALUES (''PE'', :EMPRESA, :SERIE, 1, 6, ''S'', ''N'', ' +
      'NOW(), :USUARIO, :USUARIO) ' +
      'ON DUPLICATE KEY UPDATE CON = CON';
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.ExecSQL;
  finally
    FreeAndNil(Consulta);
  end;
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := AConexion;
    Procedimiento.StoredProcName := 'PRC_GET_NEXT_CONTADOR';
    Procedimiento.Params.CreateParam(
      ftString, 'pTipoDoc', ptInput).AsString := 'PE';
    Procedimiento.Params.CreateParam(
      ftString, 'pEmpresa', ptInput).AsString := AEmpresa;
    Procedimiento.Params.CreateParam(
      ftString, 'pSerie', ptInput).AsString := ASerie;
    Procedimiento.Params.CreateParam(
      ftString, 'pUsuario', ptInput).AsString := AUsuario;
    Procedimiento.Params.CreateParam(ftString, 'pContador', ptOutput);
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('pContador').AsString;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TdmPedidos.ImportarPedidoPrestaShop(aOrder: TOrder;
  const AOrigen: string): Boolean;
var
  aCodArt: TArray<string>;
  i: Integer;
  oEntrada: TEntradaPedidoPrestaShop;
  oEscrituras: TPedidosPrestaShopEscrituras;
  oValidador: IArticulosValidador;
  sAlmacen: string;
  sCodigoCli: string;
  sEmpresa: string;
  sNumero: string;
  sSerie: string;
  TransaccionPropia: Boolean;
begin
  Result := False;
  if Assigned(aOrder) and
     not ExistePedidoPrestaShop(AOrigen, aOrder.idPedido) then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
    if sEmpresa = '' then
      sEmpresa := '0';
    sAlmacen := Trim(UbicacionSesion.Almacen);
    if sAlmacen = '' then
    begin
      NotificarAdvertencia(SAvisoAlmacenSalidaPedidoObligatorio);
      Abort;
    end;
    TransaccionPropia := not ConexionEscritura.InTransaction;
    if TransaccionPropia then
      ConexionEscritura.StartTransaction;
    try
      unqryTablaG.Insert;
      try
        unqryTablaG.FieldByName('FECHA_PED').AsDateTime := Date;
        if Assigned(unqryTablaG.FindField('ESTADO_PED')) then
          unqryTablaG.FieldByName('ESTADO_PED').AsString := 'IMPORTADO';
        unqryTablaG.FieldByName('CODIGO_EMP_PED').AsString := sEmpresa;
        if Assigned(unqryTablaG.FindField('CODIGO_ALM_PED')) then
          unqryTablaG.FieldByName('CODIGO_ALM_PED').AsString := sAlmacen;
        unqryTablaG.FieldByName('CODIGO_CLI_PED').AsString := '0';
        sSerie := unqryTablaG.FieldByName('SERIE_PED').AsString;
        sNumero := ReservarNumeroPedidoPrestaShop(ConexionEscritura,
          sEmpresa, sSerie, IdentidadSesion.Usuario);
      finally
        unqryTablaG.Cancel;
      end;
      sCodigoCli := ResolverCodigoCliente(aOrder);
      oValidador := TRepositorioArticulosValidador.Create(
        ConexionEscritura);
      SetLength(aCodArt, aOrder.LineasPedido.Count);
      for i := 0 to aOrder.LineasPedido.Count - 1 do
        aCodArt[i] := ResolverCodigoArticulo(
          oValidador,
          aOrder.LineasPedido[i]);
      oValidador := nil;
      oEntrada := Default(TEntradaPedidoPrestaShop);
      oEntrada.Pedido := aOrder;
      oEntrada.Origen := AOrigen;
      oEntrada.Numero := sNumero;
      oEntrada.Serie := sSerie;
      oEntrada.CodigoCliente := sCodigoCli;
      oEntrada.Empresa := sEmpresa;
      oEntrada.Almacen := sAlmacen;
      oEntrada.CodigosArticulo := aCodArt;
      oEscrituras := TPedidosPrestaShopEscrituras.Create(
        ConexionEscritura,
        IdentidadSesion.Usuario,
        RegistroLog);
      try
        oEscrituras.Ejecutar(oEntrada);
        if TransaccionPropia then
          ConexionEscritura.Commit;
        Result := True;
      finally
        FreeAndNil(oEscrituras);
      end;
    except
      if TransaccionPropia and ConexionEscritura.InTransaction then
        ConexionEscritura.Rollback;
      raise;
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmPedidos);
  ForceReferenceToClass(TdmPedidos);

end.
