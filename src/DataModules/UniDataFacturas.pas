{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataFacturas                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de facturas.                                                  }
{    Cabeceras y líneas de fza_facturas, series, recibos, abonos y procesos de }
{    cálculo.                                                                  }
{******************************************************************************}
unit UniDataFacturas;

interface

uses
  inLibRegistroPantallas,
  SysUtils, Classes,  DB,
   DBClient, Provider, frxClass, frxDBSet, inLibUser,
   System.StrUtils, Windows, System.Variants,
   MemDS, DBAccess, Uni,
   UniDataGen, frCoreClasses, inLibArticulosResolverIntf,
   inLibFacturasServiciosIntf, inLibLotesLineaDocumento;

procedure RevertirBorradoFactura(
  const AServicio: IServicioBorradoFactura);

type
  TdmFacturas = class(TdmBase)
    dsLinFac: TDataSource;
    dsFacPrint: TDataSource;
    dsLinFacPrint: TDataSource;
    dsSeries: TDataSource;
    fxdsPrintFac: TfrxDBDataset;
    fxdstPrintLinFac: TfrxDBDataset;
    unqryFacPrint: TUniQuery;
    unqryLinFacPrint: TUniQuery;
    unqrySeries: TUniQuery;
    unqryCliDataFac: TUniQuery;
    unqryArtDataLinFac: TUniQuery;
    unqryLinFac: TUniQuery;
    unstrdprcCrearFacturaAbono: TUniStoredProc;
    unstrdprcDuplicarFactura: TUniStoredProc;
    unstrdprcGetDataArticulo: TUniStoredProc;
    unstrdprcGetDataCliente: TUniStoredProc;
    dsFormasPago: TDataSource;
    unqryFormaPago: TUniQuery;
    dsVerifactuOpe: TDataSource;
    unqryVerifactuOpe: TUniQuery;
    dsRecibos: TDataSource;
    unqryRecibos: TUniQuery;
    dsRecibosPrint: TDataSource;
    fxdsRecibos: TfrxDBDataset;
    unqryRecibosPrint: TUniQuery;
    unstrdprcGetRecibos: TUniStoredProc;
    unqryIvas: TUniQuery;
    dsIvas: TDataSource;
    unqryEmpDataFac: TUniQuery;
    dsTarifas: TDataSource;
    unqryTarifas: TUniQuery;
    unstdGetContadorLinea: TUniStoredProc;
    unstdCalcularFactura: TUniStoredProc;
    dsSeriesEditCombo: TDataSource;
    unqrySeriesEditCombo: TUniQuery;
    unstrdprcGetContadorFactura: TUniStoredProc;
    unqryIvasTipos: TUniQuery;
    dsIvasTipos: TDataSource;
    dsFactura: TDataSource;
    dsPaisesCli: TDataSource;
    unqryPaisesCli: TUniQuery;
    unqryPaisesEmp: TUniQuery;
    dsPaisesEmp: TDataSource;
    dsConsolidacion: TDataSource;
    unqryConsolidacion: TUniQuery;
    dsErrores: TDataSource;
    unqryErrores: TUniQuery;
    unqryMovimientosFac: TUniQuery;
    dsMovimientosFac:    TDataSource;
    unqryAlmacenesFac:   TUniQuery;
    dsAlmacenesFac:      TDataSource;
    unqryEfectosVenta:   TUniQuery;
    dsEfectosVenta:      TDataSource;
    unqryPagosCajaFac:   TUniQuery;
    dsPagosCajaFac:      TDataSource;
    unqryVendedoresFac:  TUniQuery;
    dsVendedoresFac:     TDataSource;
    unstrdprcInsertarMovFac: TUniStoredProc;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryLinFacBeforeInsert(DataSet: TDataSet);
    procedure unqryFacBeforePost(DataSet: TDataSet);
    procedure unqryLinFacAfterPost(DataSet: TDataSet);
    procedure unqryFacAfterPost(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryLinFacAfterInsert(DataSet: TDataSet);
    procedure unqryLinFacBeforePost(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterDeleteTx(DataSet: TDataSet);
    // FZ-ISSUE-137: al refrescar la cabecera se vuelven a consultar los
    // detalles fiscales ya abiertos (el maestro no cambia de clave).
    procedure unqryTablaGAfterRefresh(DataSet: TDataSet);
    procedure unqryTablaGDeleteErrorTx(DataSet: TDataSet;
      E: EDatabaseError; var Action: TDataAction);
    procedure unqryLinFacAfterDelete(DataSet: TDataSet);
    procedure dsLinFacStateChange(Sender: TObject);
    procedure unqryLinFacBeforeEdit(DataSet: TDataSet);
private
    // Guarda de re-entrancia del BeforePost de la cabecera.
    FValidandoPost: Boolean;
    // Evita que los Post internos del motor disparen otro cálculo completo.
    FCalculandoFactura: Boolean;
    // Agrupa los cambios del editor y recalcula el documento una vez al Post.
    FRecalculoFacturaPendiente: Boolean;
    // True mientras DesempaquetarAtributosLineas postea lineas: cambio
    // puramente descriptivo que NO debe disparar numeracion, creacion
    // de articulos ni recalculos (cascada por linea al navegar).
    FDesempaquetandoAtributos: Boolean;
    FLotesLineas: TLotesLineasDocumento;
    // True mientras se graban los totales recalculados tras el Post de la
    // cabecera: ese segundo Post no vuelve a procesar la factura.
    FGrabandoTotalesTrasPost: Boolean;
    // FZ-ISSUE-322: True mientras PrepararCabeceraParaLineas graba la
    // cabecera antes de editar una línea (ver EsValidacionFiscalAplazable).
    FGrabandoCabeceraParaLineas: Boolean;
    // Vendedor de la cabecera (comisiones) antes del Post en curso: si
    // el Post lo cambia, las líneas que lo seguían pasan al nuevo.
    FVendedorAntesDePost: string;
    FRepositorio: IRepositorioFacturas;
    FArticulosResolver: IArticulosResolver;
    FValidadorFiscal: IValidadorFiscalFactura;
    FCalculador: ICalculadorFactura;
    FServicioBorrado: IServicioBorradoFactura;
    FCrearBorrado: TFabricaServicioBorradoFactura;
    FConexionBorrado: TUniConnection;
    FServicioEfectos: IServicioEfectosFactura;
    FAdvertenciasPendientes: TStringList;
    FOnResultadoOperacion: TResultadoOperacionFacturaEvent;
    FOnResultadoBorrado: TResultadoBorradoFacturaEvent;
    FOnAdvertencia: TAdvertenciaFacturaEvent;
    FOnValidacion: TValidacionFacturaEvent;
    FOnConfirmarBorrado: TConfirmarBorradoFacturaEvent;
    FOnNuevaFactura: TNotifyEvent;
    FOnSeriesCambiadas: TNotifyEvent;
    FOnLinFacEstado: TNotifyEvent;
    // Tipo de las facturas nuevas (NORMAL / SIMPLIFICADA); lo fija el
    // form al crear el DM (antes se leia del form en el AfterInsert).
    FTipoFacturaDefecto: string;
    // Copia a los parámetros de la query los valores de los campos del
    // maestro (MasterSource) que se llamen igual. UniDAC solo rellena
    // los parámetros al hacer scroll del maestro con el detail ya
    // abierto; en la apertura perezosa (pestañas lazy) la query se abre
    // después de posicionar el maestro y se quedaba con parámetros NULL
    // (pestañas Verifactu y Movimientos vacías).
    procedure RellenarParamsDesdeMaestro(AQry: TUniQuery);
    // Subsanación (fase SUBSANACION): la factura emitida se corrige con
    // su misma identidad, como en Caja: en la cabecera sólo los datos
    // del cliente y en las líneas sólo cantidades y precios, sin
    // insertar ni borrar líneas.
    function FacturaEnSubsanacion: Boolean;
    procedure ValidarCabeceraSubsanacion(DataSet: TDataSet);
    procedure ValidarLineaSubsanacion(DataSet: TDataSet);
    procedure ValidarEstructuraLineasSubsanacion(DataSet: TDataSet);
    // Ejecuta una validación de línea y, si falla, la muestra por
    // OnValidacion (aviso modal) en vez de dejar subir la excepción.
    procedure ComprobarLineaSubsanacion(DataSet: TDataSet;
      AValidacion: TDataSetNotifyEvent);
    procedure unqryLinFacBeforeDeleteSubsanacion(DataSet: TDataSet);
    // Comprobaciones comunes antes de insertar o editar una línea: la
    // cabecera grabada y con serie y número.
    procedure PrepararCabeceraParaLineas;
    // Vendedor para liquidar comisiones. Es opcional: el de la cabecera
    // (CODIGO_CAJERO_FAC) es el de toda la factura y cada línea guarda el
    // suyo (CODIGO_VENDEDOR_FACLIN), que es el que se liquida. La línea
    // nueva hereda el de la cabecera; al cambiarlo, lo siguen las líneas
    // sin vendedor y las que tenían el anterior, no las asignadas a otro.
    procedure AnotarCambioVendedor(ADataSet: TDataSet);
    procedure PropagarVendedorALineas;
    // Helpers de validacion de coherencia en el BeforePost de la cabecera.
    function UltimaFechaSerie(const ASerie, AEmpresa,
                              ANumero: string): TDateTime;
    function HayHuecoNumeracion(const ASerie, AEmpresa,
                                ANumero: string): Boolean;
    procedure ValidarOperacionVfactu;
    // Cuerpo real del BeforePost de la cabecera. Lo invoca el wrapper
    // unqryFacBeforePost dentro de la guarda de re-entrancia.
    procedure ValidarCabeceraBeforePost(DataSet: TDataSet);
    procedure RequerirServiciosFactura;
    procedure NotificarResultadoOperacion(
      const AResultado: TResultadoOperacionFactura);
    procedure NotificarResultadoBorrado(
      const AResultado: TResultadoBorradoFactura);
    procedure RegistrarAdvertencia(
      const AMensaje: string;
      ADiferir: Boolean);
    procedure NotificarAdvertenciasPendientes;
    procedure GuardarParametrosEDocFactura(ADataSet: TDataSet);
    procedure GuardarOpcionMovimientosFactura(ADataSet: TDataSet);
    procedure ProcesarFacturaPosteada(ADataSet: TDataSet);
    function FacturaPermiteRecalcularLineas: Boolean;
    // True si el borrador genera movimientos de stock al consolidar:
    // SIMPLIFICADA siempre; NORMAL solo con el check ESMUEVE_STOCK_FAC.
    // Si no los genera, el almacen de la factura es OPCIONAL.
    function FacturaGeneraMovimientos: Boolean;
    procedure EnlazarBorradoConexionEscritura;
public
    procedure ConfigurarServicios(
      const AServicios: TServiciosFactura);
    procedure GetCodigoAutoFactura;
    // Numero total de prendas (suma CANTIDAD_FACLIN de todas las lineas).
    // Se muestra en la pestana Totales; no se persiste en BBDD.
    function TotalPrendasFactura: Double;
    // Contrato ColumnSKUcxGrid: trocea CODIGO_UNIDAD_FACLIN en las
    // columnas reales ATTR1..5_VALOR_FACLIN + NUM_ATRIBUTOS_FACLIN para
    // que el modo Desglose/Tallas pinte Color/Talla. Idempotente por
    // comparacion (mismo criterio que TdmPedidos). No hace nada si la
    // migracion facturas_columnas_sku.sql no esta aplicada.
    procedure DesempaquetarAtributosLineas;
    procedure GetCodigoAutoCliente;
    procedure GetCodigoAutoEmpresa;
    procedure CrearCliente;
    procedure CrearEmpresa;
    procedure CalcularRetencionesEmpresa;
    procedure CrearTablaSeries(sEmpresa, sCliente:string; dtFecha:TDateTime);
    procedure CopiarEmpresaaFactura(DataSet:TDataSet);
    procedure CopiarClienteaFactura(DataSet:TDataSet);
    procedure CompletarClienteBorrador;
    procedure CopiarArticuloaLinea(DataSet:TDataSet);
    procedure MarcarRecalculoFacturaPendiente;
    procedure RecalcularDescuentosDocumento;
    function FormaPagoDefault:String;
    function TarifaDefault:string;
    function BuscarCliente(s: string):Boolean;
    procedure AsignarIVA(s:string; unqryT:TUniQuery);
    function GetCodigoGrupoIVAAGricola:String;
    function GetUserEmpresaDef:String;
    function CalcularFactura: TResultadoOperacionFactura;
    procedure RefrescarAlmacenes(const ACodigoEmpresa: string);
    function GetTipoIVA(sTipoIVA:string):Currency;
    function ExisteSerieEmpresa(sSerie,
                                sEmpresa,
                                sTipoDoc:string): Boolean;
    function GetSubtipoSerieEmpresa(sSerie,
                                    sEmpresa:string;
                                    dtFecha:TDateTime): string;
    procedure OpenTables;
    // Override: abre las queries lookup + la query de la pestaña detail
    // por defecto (LineasFactura). Las queries de las pestañas Recibos,
    // Verifactu/Consolidacion, Registro/Errores y MovimientosFac son
    // lazy: solo se abren al activarse esa pestaña (ver
    // TfrmMtoFacturasBase.PcDetailChange).
    procedure AbrirDetalles; override;
    // Carga perezosa de sub-pestañas detail de la ficha de factura.
    procedure AsegurarRecibosAbierta;
    procedure AsegurarEfectosVentaAbierta;
    procedure AsegurarConsolidacionAbierta;
    procedure AsegurarErroresAbierta;
    procedure AsegurarMovimientosFacAbierta;
    // Pagos con los que se liquido la operacion de caja de la
    // factura. Solo la abre la pantalla de simplificadas: una
    // factura normal se cobra con recibos, no en el TPV.
    procedure AsegurarPagosCajaFacAbierta;
    // Estampa la cuenta de la empresa (ingreso) elegida en los recibos de
    // la factura (serie/numero) despues de generarlos.
    procedure EstamparBancoRecibos(const ASerie, ANumero,
                                   ACodEmpban, AIban: string);
    // Cuenta de la empresa (ingreso) por defecto del cliente
    // (CODIGO_EMPBAN_CLI) para pre-seleccionarla en el modal de banco al
    // generar recibos. '' si no tiene.
    function GetBancoDefectoCliente(const ACodigoCli: string): string;
    function GenerarEfectosVenta(const ACodEmpban: string = '';
                                 const AIbanEmp: string = ''): Integer;
    function RegistrarCobroEfectoVenta(ANumEfecto: Integer;
      AFecha: TDateTime; AImporte: Double;
      const ATipo, AReferencia: string): Integer;
    function CambiarEstadoEfectoVenta(const AEstado: string): Boolean;
    // Borrador de abono (AAbono) o duplicado de la factura actual en la
    // serie y fecha elegidas; forma de pago vacia = la de la original.
    // Devuelve el numero asignado por el contador de la serie.
    function GenerarBorradorDesdeFacturaActual(AAbono: Boolean;
      const ASerie: string; AFecha: TDateTime;
      const AFormaPago: string): string;

    // Cablea los detalles (lineas, recibos, efectos, consolidacion,
    // errores, movimientos) al datasource de cabecera que aporta el
    // form. Antes DataModuleCreate lo tomaba del form directamente.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    property OnResultadoOperacion: TResultadoOperacionFacturaEvent
      read FOnResultadoOperacion write FOnResultadoOperacion;
    property OnResultadoBorrado: TResultadoBorradoFacturaEvent
      read FOnResultadoBorrado write FOnResultadoBorrado;
    property OnAdvertencia: TAdvertenciaFacturaEvent
      read FOnAdvertencia write FOnAdvertencia;
    // F-LOTEC-016: lote y serie de las líneas (solo con interruptores).
    procedure ConfigurarLotesLineas(const AConfig: TConfiguracionLotesLineas);
    function DocumentoLotes: TDocumentoLineaLote;
    // Botón de la columna Lote: vuelve a elegir el de la línea actual.
    procedure ElegirLoteLinea;
    property OnValidacion: TValidacionFacturaEvent
      read FOnValidacion write FOnValidacion;
    property OnConfirmarBorrado: TConfirmarBorradoFacturaEvent
      read FOnConfirmarBorrado write FOnConfirmarBorrado;
    property OnNuevaFactura: TNotifyEvent
      read FOnNuevaFactura write FOnNuevaFactura;
    property OnSeriesCambiadas: TNotifyEvent
      read FOnSeriesCambiadas write FOnSeriesCambiadas;
    property OnLinFacEstado: TNotifyEvent
      read FOnLinFacEstado write FOnLinFacEstado;
    property TipoFacturaDefecto: string
      read FTipoFacturaDefecto write FTipoFacturaDefecto;
  private
    // Conexion por la que salen la transaccion, los bloqueos y las
    // lecturas de la operacion: la misma que usan los datasets.
    function ConexionEscritura: TUniConnection;
  end;
implementation

uses
  inLibLineaSku,
  UniDataValoresAutomaticosRepositorio,

  System.Diagnostics,
  inLibFacturas,
  UniDataAlmacenesEmpresaRepositorio,
  inLibVerifactu,
  inLibDocumentoFiscal,
  inLibDocumento,
  inLibDocumentoIntf,
  inLibArticulosValidadorIntf,
  UniDataArticulosValidadorRepositorio,
  inLibLicenciaAplicacion,
  UniDataLicenciaAplicacionRepositorio,
  inLibVentasImpuestos,
  inLibContadorLineas,
  UniDataContadorLineasRepositorio,
  UniDataFacturasConfiguracion,
  inLibFacturasValidacionCabecera,
  inLibFacturasLineasEdicion,
  inLibFacturasValidacionFiscal,
  inLibFacturasValidacionDatos,
  inLibFacturasSubsanacionReglas,
  inLibFacturasValidacionUniDAC,
  inLibMsgFacturas, inLibMsgVentas, UniDataNumeracionDocumentos,
  UniDataVendedoresRepositorio;

{$R *.dfm}

procedure RevertirBorradoFactura(
  const AServicio: IServicioBorradoFactura);
begin
  if Assigned(AServicio) then
    AServicio.Revertir;
end;

procedure ForceReferenceToClass(C: TClass); begin end;

function TdmFacturas.ConexionEscritura: TUniConnection;
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

procedure TdmFacturas.ConfigurarServicios(
  const AServicios: TServiciosFactura);
begin
  FRepositorio := AServicios.Repositorio;
  FArticulosResolver := AServicios.ArticulosResolver;
  FValidadorFiscal := AServicios.ValidadorFiscal;
  FCalculador := AServicios.Calculador;
  FServicioBorrado := AServicios.Borrado;
  FCrearBorrado := AServicios.CrearBorrado;
  FConexionBorrado := nil;
  FServicioEfectos := AServicios.Efectos;
end;

// El dataset borra la cabecera por la conexion de la ventana: efectos,
// lineas, recibos y movimientos tienen que ir en esa misma transaccion,
// o la cabecera puede quedar borrada con el resto vivo (FZ-ISSUE-151).
procedure TdmFacturas.EnlazarBorradoConexionEscritura;
var
  oConexion: TUniConnection;
begin
  oConexion := ConexionEscritura;
  if Assigned(FCrearBorrado) and Assigned(oConexion) and
     (oConexion <> FConexionBorrado) then
  begin
    FServicioBorrado := FCrearBorrado(oConexion);
    FConexionBorrado := oConexion;
  end;
end;

procedure TdmFacturas.RequerirServiciosFactura;
begin
  if (not Assigned(FRepositorio)) or
     (not Assigned(FArticulosResolver)) or
     (not Assigned(FValidadorFiscal)) or
     (not Assigned(FCalculador)) or
     (not Assigned(FServicioBorrado)) or
     (not Assigned(FServicioEfectos)) then
  begin
    raise Exception.Create(
      'Los servicios de factura no están configurados');
  end;
end;

procedure TdmFacturas.NotificarResultadoOperacion(
  const AResultado: TResultadoOperacionFactura);
begin
  if Assigned(FOnResultadoOperacion) then
    FOnResultadoOperacion(AResultado);
end;

procedure TdmFacturas.NotificarResultadoBorrado(
  const AResultado: TResultadoBorradoFactura);
begin
  if Assigned(FOnResultadoBorrado) then
    FOnResultadoBorrado(AResultado);
end;

procedure TdmFacturas.RegistrarAdvertencia(
  const AMensaje: string;
  ADiferir: Boolean);
begin
  if ADiferir then
  begin
    FAdvertenciasPendientes.Add(AMensaje);
  end
  else if Assigned(FOnAdvertencia) then
  begin
    FOnAdvertencia(AMensaje);
  end;
end;

procedure TdmFacturas.NotificarAdvertenciasPendientes;
var
  Mensaje: string;
begin
  while FAdvertenciasPendientes.Count > 0 do
  begin
    Mensaje := FAdvertenciasPendientes[0];
    FAdvertenciasPendientes.Delete(0);
    if Assigned(FOnAdvertencia) then
      FOnAdvertencia(Mensaje);
  end;
end;

function  TdmFacturas.ExisteSerieEmpresa(sSerie,
                                         sEmpresa,
                                         sTipoDoc:string): Boolean;
begin
  RequerirServiciosFactura;
  Result := FRepositorio.ExisteSerieOtraEmpresa(
    sSerie,
    sEmpresa,
    sTipoDoc);
end;

// Fecha de la ultima factura ya emitida (no borrador) de la misma serie y
// empresa, excluyendo la actual. 0 si no hay ninguna.
function TdmFacturas.UltimaFechaSerie(const ASerie, AEmpresa,
  ANumero: string): TDateTime;
begin
  RequerirServiciosFactura;
  Result := FRepositorio.UltimaFechaSerie(
    ASerie,
    AEmpresa,
    ANumero);
end;

// True si entre la ultima factura de la serie y la actual queda un hueco de
// numeracion (la ley exige numeracion correlativa, ese numero debe cubrirse).
function TdmFacturas.HayHuecoNumeracion(const ASerie, AEmpresa,
  ANumero: string): Boolean;
begin
  RequerirServiciosFactura;
  Result := FRepositorio.HayHuecoNumeracion(
    ASerie,
    AEmpresa,
    ANumero);
end;

// Detecta incoherencias flagrantes entre el tipo de operacion Verifactu,
// el pais del cliente y el IVA de la factura.
procedure TdmFacturas.ValidarOperacionVfactu;
var
  Solicitud: TSolicitudValidacionFiscalFactura;
begin
  RequerirServiciosFactura;
  Solicitud.TipoOperacion :=
    unqryTablaG.FieldByName(
      'TIPO_OPER_VFACTU_FAC').AsString;
  Solicitud.CodigoPaisCliente :=
    unqryTablaG.FieldByName(
      'CODIGO_PAI_CLIENTE_FAC').AsString;
  Solicitud.NifCliente :=
    unqryTablaG.FieldByName(
      'NIF_CLIENTE_FAC').AsString;
  Solicitud.TotalImpuestos :=
    unqryTablaG.FieldByName(
      'TOTAL_IMPUESTOS_FAC').AsCurrency;
  try
    FValidadorFiscal.Validar(Solicitud);
  except
    on E: EValidacionFactura do
      if not EsValidacionFiscalAplazable(E.Campo,
               FGrabandoCabeceraParaLineas) then
        raise;
  end;
end;

function TdmFacturas.GetSubtipoSerieEmpresa(
  sSerie, sEmpresa: string;
  dtFecha: TDateTime): string;
var
  unqrySol: TUniQuery;
begin
  Result := '';
  if (sSerie <> '') and
     (sEmpresa <> '') then
  begin
    unqrySol := TUniQuery.Create(nil);
    try
      unqrySol.Connection := ConexionEscritura;
      unqrySol.SQL.Text :=
        'SELECT S.SUBTIPO_EMPSER ' +
        '  FROM fza_empresas_series S ' +
        ' INNER JOIN fza_empresas E ' +
        '    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_EMPSER ' +
        ' WHERE S.CODIGO_EMP_EMPSER = :EMPRESA ' +
        '   AND (S.EMPSER = :SERIE ' +
        '        OR (E.ESTOKENS_CALENDARIO_NATURAL_EMP = ''S'' ' +
        '        AND NULLIF(TRIM(S.SERIE_TOKENIZADA_EMPSER), '''') ' +
        '            IS NOT NULL ' +
        '        AND (LOCATE(BINARY ''yy'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0 ' +
        '          OR LOCATE(BINARY ''q'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0 ' +
        '          OR LOCATE(BINARY ''mm'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0 ' +
        '          OR LOCATE(BINARY ''dd'', BINARY ' +
        '             TRIM(S.SERIE_TOKENIZADA_EMPSER)) > 0) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''yyyy'', '''')) IN (0, 4) ' +
        // yy se cuenta fuera de los yyyy y no se mezcla con ellos
        '        AND CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ''yyyy'', '''')) - ' +
        '            CHAR_LENGTH(REPLACE(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ''yyyy'', ''''), ' +
        '            ''yy'', '''')) IN (0, 2) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ''yyyy'', ''''), ' +
        '            ''yy'', '''')) IN (0, 2, 4) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''q'', '''')) IN (0, 1) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''mm'', '''')) IN (0, 2) ' +
        '        AND CHAR_LENGTH(TRIM(S.SERIE_TOKENIZADA_EMPSER)) - ' +
        '            CHAR_LENGTH(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''dd'', '''')) IN (0, 2) ' +
        '        AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(' +
        '            TRIM(S.SERIE_TOKENIZADA_EMPSER), ' +
        '            ''yyyy'', CAST(YEAR(:FECHA) AS CHAR)), ' +
        '            ''yy'', DATE_FORMAT(:FECHA, ''%y'')), ' +
        '            ''mm'', DATE_FORMAT(:FECHA, ''%m'')), ' +
        '            ''dd'', DATE_FORMAT(:FECHA, ''%d'')), ' +
        '            ''q'', CAST(QUARTER(:FECHA) AS CHAR)) = :SERIE)) ' +
        '   AND (S.FECHA_DESDE_EMPSER IS NULL ' +
        '        OR S.FECHA_DESDE_EMPSER <= :FECHA) ' +
        '   AND (S.FECHA_HASTA_EMPSER IS NULL ' +
        '        OR S.FECHA_HASTA_EMPSER >= :FECHA) ' +
        ' LIMIT 1';
      unqrySol.ParamByName('SERIE').AsString := sSerie;
      unqrySol.ParamByName('EMPRESA').AsString := sEmpresa;
      unqrySol.ParamByName('FECHA').AsDateTime := dtFecha;
      unqrySol.Open;
      if not unqrySol.IsEmpty then
      begin
        Result := unqrySol.FieldByName(
          'SUBTIPO_EMPSER').AsString;
      end;
    finally
      FreeAndNil(unqrySol);
    end;
  end;
end;

function TdmFacturas.GetUserEmpresaDef:String;
var
  unqrySol:TUniQuery;
  sResul : String;
begin
  sResul := '';
  if ( ((unqryTablaG.State = dsEdit) or
        (unqryTablaG.State = dsInsert))
    ) then
  begin
    unqrySol := TUniQuery.Create(Self);
    unqrySol.Connection := ConexionEscritura;
    unqrySol.SQL.Text := 'SELECT EMPRESA_DEFECTO_USU ' +
                        '  FROM fza_usuarios ' +
                        ' WHERE USUARIO_USU = :Usuario ';
    unqrySol.ParamByName('Usuario').AsString := IdentidadSesion.Usuario;
    unqrySol.Open;
    if unqrySol.RecordCount <> 0 then
    begin
      sResul := unqrySol.FieldByName('EMPRESA_DEFECTO_USU').AsString;
    end;
    unqrySol.Close;
    FreeAndNil(unqrySol);
  end;
  Result := sResul;
end;

procedure TdmFacturas.CrearTablaSeries(sEmpresa,
                                       sCliente:string;
                                       dtFecha:TDateTime);
begin
  unqrySeriesEditCombo.Connection := ConexionEscritura;
  unqrySeriesEditCombo.SQL.Text :=
                'SELECT SERIE_CON_CLI AS SERIE_CON ' +
                '  FROM vi_clientes                              ' +
                ' WHERE (SERIE_CON_CLI IS NOT NULL      ' +
                '        AND SERIE_CON_CLI <> '''')     ' +
                '   AND CODIGO_CLI_CLI = :CLIENTE                ' +
                ' UNION                                          ' +
                'SELECT EMPSER AS SERIE_CON            ' +
                '  FROM vi_empresas_series                       ' +
                ' WHERE CODIGO_EMP_EMPSER = :EMPRESA          ' +
                '   AND TIPO_DOC_EMPSER = ''FC''               ' +
                '   AND (SUBTIPO_EMPSER = :SUBTIPO             ' +
                '        OR IFNULL(SUBTIPO_EMPSER, '''') = '''') ' +
                '   AND (FECHA_DESDE_EMPSER IS NULL            ' +
                '        OR FECHA_DESDE_EMPSER <= :FECHA)      ' +
                '   AND (FECHA_HASTA_EMPSER IS NULL            ' +
                '        OR FECHA_HASTA_EMPSER >= :FECHA)      ' +
                ' UNION                                          ' +
                'SELECT SERIE_CON AS SERIE_CON         ' +
                '  FROM vi_contadores                            ' +
                ' WHERE ESACTIVO_CON = ''S''                  ' +
                '   AND TIPO_DOC_CON = ''FC''                 ' +
                '   AND EMPRESA_CON = :EMPRESA              ';
  unqrySeriesEditCombo.Prepare;
  unqrySeriesEditCombo.Params.ParamByName('EMPRESA').AsSTring := sEmpresa;
  unqrySeriesEditCombo.Params.ParamByName('FECHA').AsDateTime := dtFecha;
  unqrySeriesEditCombo.Params.ParamByName('CLIENTE').AsString := sCliente;
  unqrySeriesEditCombo.Params.ParamByName('SUBTIPO').AsString :=
    FTipoFacturaDefecto;
  if unqrySeriesEditCombo.Active then
    unqrySeriesEditCombo.Close;
  unqrySeriesEditCombo.Open;
end;

procedure TdmFacturas.AsignarIVA(s:string; unqryT:TUniQuery);
begin
  CargarConfiguracionIvaFactura(Self, ConexionEscritura, s,
    unqryT.FieldByName('FECHA_FAC').AsDateTime, unqryT);
end;

function TdmFacturas.BuscarCliente(s: string):Boolean;
var
  unqrySol:TUniQuery;
begin
  unqrySol := TUniQuery.Create(Self);
  try
    unqrySol.Connection := ConexionEscritura;
    unqrySol.SQL.Text := 'SELECT * ' +
                         '  FROM fza_clientes ' +
                         ' WHERE CODIGO_CLI_CLI = :cliente';
    unqrySol.ParamByName('cliente').AsString := s;
    unqrySol.Open;
    if unqrySol.RecordCount = 0 then
    begin
      Result := False;
    end
    else
    begin
      CopiarClienteaFactura(unqrySol);
      Result := True;
    end;
    unqrySol.Close;
  finally
    FreeAndNil(unqrySol);
  end;
end;

procedure TdmFacturas.CompletarClienteBorrador;
var
  Consulta: TUniQuery;
begin
  if unqryTablaG.Active and not unqryTablaG.IsEmpty and
     SameText(unqryTablaG.FieldByName('FASE_FAC').AsString, 'BORRADOR')
  then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := ConexionEscritura;
      Consulta.SQL.Text :=
        'SELECT CODIGO_CLI_CLI, RAZON_SOCIAL_CLI, NIF_CLI, ' +
        'DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, PROVINCIA_CLI, ' +
        'CODIGO_POSTAL_CLI, NOMBRE_PAI_CLI, CODIGO_PAI_CLI, EMAIL_CLI ' +
        'FROM fza_clientes WHERE CODIGO_CLI_CLI = :CLIENTE';
      Consulta.ParamByName('CLIENTE').AsString :=
        unqryTablaG.FieldByName('CODIGO_CLI_FAC').AsString;
      Consulta.Open;
      if not Consulta.IsEmpty then
        CompletarIdentidadClienteBorrador(Consulta, unqryTablaG);
      if unqryTablaG.State in dsEditModes then
        unqryTablaG.Post;
    finally
      Consulta.Free;
    end;
  end;
end;

function TdmFacturas.CalcularFactura: TResultadoOperacionFactura;
var
  bReadOnlyLineas: Boolean;
begin
  Result := TResultadoOperacionFactura.Correcto;
  if not FCalculandoFactura then
  begin
    RequerirServiciosFactura;
    FCalculandoFactura := True;
    try
      if Assigned(unqryTablaG) and unqryTablaG.Active and
         Assigned(unqryLinFac) and unqryLinFac.Active then
      begin
        bReadOnlyLineas := unqryLinFac.ReadOnly;
        try
          if bReadOnlyLineas then
          begin
            unqryLinFac.ReadOnly := False;
          end;
          Result := FCalculador.Calcular(
            unqryTablaG,
            unqryLinFac,
            FacturaPermiteRecalcularLineas);
        finally
          unqryLinFac.ReadOnly := bReadOnlyLineas;
        end;
      end;
    finally
      FCalculandoFactura := False;
    end;
  end;
end;

procedure TdmFacturas.CalcularRetencionesEmpresa;
begin
  AplicarRetencionEmpresaFactura(Self, ConexionEscritura, unqryTablaG);
end;

procedure TdmFacturas.RecalcularDescuentosDocumento;
begin
  if unqryTablaG.State in dsEditModes then
    NotificarResultadoOperacion(CalcularFactura);
end;

procedure TdmFacturas.MarcarRecalculoFacturaPendiente;
begin
  FRecalculoFacturaPendiente := True;
end;

procedure TdmFacturas.CopiarArticuloaLinea(DataSet: TDataSet);
var
  bDtoVig: Boolean;
  sCodigoSku: string;
begin
  sCodigoSku := '';
  if DataSet.FindField('CODIGO_UNIDAD_SKU') <> nil then
    sCodigoSku := DataSet.FieldByName('CODIGO_UNIDAD_SKU').AsString
  else if DataSet.FindField('CODIGO_UNIDAD_ARTTAR') <> nil then
    sCodigoSku := DataSet.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString;
  bDtoVig := FArticulosResolver.DescuentoTarifaAplicable(
    unqryTablaG.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
    DataSet.FieldByName('CODIGO_ART_ART').AsString,
    sCodigoSku,
    unqryTablaG.FieldByName('FECHA_FAC').AsDateTime);
  CopiarArticuloSeleccionadoFactura(
    DataSet, dsLinFac.DataSet, unqryTablaG, bDtoVig);
end;

procedure TdmFacturas.CopiarClienteaFactura(DataSet:TDataSet);
var
  Resultado: TResultadoCopiaClienteFactura;
begin
  Resultado := CopiarClienteSeleccionadoFactura(DataSet, unqryTablaG);
  if Resultado.RequiereFormaPagoDefecto then
  begin
    unqryTablaG.FieldByName('FORMA_PAGO_FAC').AsString :=
      FormaPagoDefault;
  end;
  if Resultado.RequiereTarifaDefecto then
  begin
    unqryTablaG.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString := TarifaDefault;
  end;
  if (unqryTablaG.State = dsInsert) and
     (unqryTablaG.FieldByName(
       'TARIFA_ARTICULO_CLIENTE_FAC').AsString <> '') then
  begin
    unqryTarifas.Locate(
      'CODIGO_TAR_ARTTAR',
      unqryTablaG.FieldByName(
        'TARIFA_ARTICULO_CLIENTE_FAC').AsString, []);
    unqryTablaG.FieldByName(
      'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
      unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString;
  end;
  // La factura normal propone el vendedor asignado al cliente; en la
  // simplificada ese campo es el cajero que cerró el ticket.
  if SameText(FTipoFacturaDefecto, 'NORMAL') then
    ProponerVendedorCliente(DataSet, unqryTablaG, 'CODIGO_CAJERO_FAC');
  if Resultado.NotificarSeries and Assigned(FOnSeriesCambiadas) then
    FOnSeriesCambiadas(Self);
end;

procedure TdmFacturas.CopiarEmpresaaFactura(DataSet:TDataSet);
var
  Resultado: TResultadoCopiaEmpresaFactura;
begin
  Resultado := CopiarEmpresaSeleccionadaFactura(DataSet, unqryTablaG);
  if Resultado.CalcularRetenciones then
    CalcularRetencionesEmpresa;
  if Resultado.NotificarSeries and Assigned(FOnSeriesCambiadas) then
    FOnSeriesCambiadas(Self);
end;

procedure TdmFacturas.CrearCliente;
var
  Solicitud: TSolicitudClienteFactura;
begin
  RequerirServiciosFactura;
  Solicitud := CrearSolicitudClienteDesdeFactura(
    unqryTablaG, IdentidadSesion.Usuario);
  FRepositorio.GuardarCliente(Solicitud);
end;

procedure TdmFacturas.CrearEmpresa;
var
  Solicitud: TSolicitudEmpresaFactura;
begin
  RequerirServiciosFactura;
  Solicitud := CrearSolicitudEmpresaDesdeFactura(
    unqryTablaG, IdentidadSesion.Usuario);
  FRepositorio.GuardarEmpresa(Solicitud);
end;

procedure TdmFacturas.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FAdvertenciasPendientes := TStringList.Create;
  unqryPerfiles.Connection := ConexionPrincipal;
  ConfigurarPersistenciaCabeceraFactura(
    ConexionPrincipal,
    unqryTablaG);
  // Cierre de la transaccion del borrado (abierta en BeforeDelete)
  unqryTablaG.AfterDelete := unqryTablaGAfterDeleteTx;
  unqryTablaG.OnDeleteError := unqryTablaGDeleteErrorTx;
  unqryTablaG.AfterRefresh := unqryTablaGAfterRefresh;
  ConfigurarPersistenciaLineasFactura(
    ConexionPrincipal,
    unqryLinFac);
  // Guarda de estructura de líneas mientras la factura se subsana.
  unqryLinFac.BeforeDelete := unqryLinFacBeforeDeleteSubsanacion;
  unqrySeries.Connection := ConexionPrincipal;
  unqryIvas.Connection := ConexionPrincipal;
  unqryRecibos.Connection := ConexionPrincipal;
  unqryEmpDataFac.Connection := ConexionPrincipal;
  unqryCliDataFac.Connection := ConexionPrincipal;
  unqryArtDataLinFac.Connection := ConexionPrincipal;
  unqryTarifas.Connection := ConexionPrincipal;
  unqryFormaPago.Connection := ConexionPrincipal;
  unstrdprcGetContadorFactura.Connection := ConexionPrincipal;
  unstdGetContadorLinea.Connection := ConexionPrincipal;
  unstdCalcularFactura.Connection := ConexionPrincipal;
  unstrdprcGetDataCliente.Connection := ConexionPrincipal;
  unstrdprcGetRecibos.Connection := ConexionPrincipal;
  unqryRecibosPrint.Connection := ConexionPrincipal;
  unqrySeriesEditCombo.Connection := ConexionPrincipal;
  unqryIvasTipos.Connection := ConexionPrincipal;
  unqryPaisesEmp.Connection := ConexionPrincipal;
  unqryPaisesCli.Connection := ConexionPrincipal;
  unqryConsolidacion.Connection := ConexionPrincipal;
  unqryErrores.Connection := ConexionPrincipal;
  unqryMovimientosFac.Connection := ConexionPrincipal;
  unqryAlmacenesFac.Connection := ConexionPrincipal;
  unstrdprcInsertarMovFac.Connection := ConexionPrincipal;
  unqryEfectosVenta := TUniQuery.Create(Self);
  unqryEfectosVenta.Connection := ConexionPrincipal;
  unqryEfectosVenta.SQL.Text :=
    'SELECT * ' +
    '  FROM vi_efectos_venta ' +
    ' WHERE NUMERO_FAC_EFV = :NUMERO_FAC ' +
    '   AND SERIE_FAC_EFV  = :SERIE_FAC ' +
    ' ORDER BY NUMERO_EFV';
  unqryEfectosVenta.MasterFields := 'NUMERO_FAC;SERIE_FAC';
  unqryEfectosVenta.DetailFields := 'NUMERO_FAC_EFV;SERIE_FAC_EFV';
  dsEfectosVenta := TDataSource.Create(Self);
  dsEfectosVenta.DataSet := unqryEfectosVenta;
  // Los pagos cuelgan de la operacion de caja, no de la
  // factura: la cabecera guarda a que caja y operacion
  // pertenece. Los parametros se llaman igual que los campos
  // del maestro para que RellenarParamsDesdeMaestro los case.
  unqryPagosCajaFac := TUniQuery.Create(Self);
  unqryPagosCajaFac.Connection := ConexionPrincipal;
  unqryPagosCajaFac.SQL.Text :=
    'SELECT p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO, ' +
    '       p.CODIGO_CAJA_PAGO, p.SERIE_OPERACION_PAGO, ' +
    '       p.NUMERO_OPERACION_PAGO, ' +
    '       p.NUMERO_LINEA_PAGO, p.CODIGO_FP_CFP, ' +
    '       fp.DESCRIPCION_FORMA_PAGO_CFP, ' +
    '       p.IMPORTE_ENTREGADO_PAGO, p.IMPORTE_CAMBIO_PAGO, ' +
    '       p.CODIGO_DIVISA_PAGO, p.IMPORTE_DIVISA_PAGO, ' +
    '       p.REFERENCIA_FACPAG, p.OBSERVACIONES_PAGO ' +
    '  FROM fza_caja_pagos p ' +
    '  LEFT JOIN fza_caja_formas_pago fp ' +
    '    ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP ' +
    ' WHERE p.CODIGO_EMP_PAGO       = :CODIGO_EMP_FAC ' +
    '   AND p.CODIGO_ALM_PAGO       = :CODIGO_ALM_FAC ' +
    '   AND p.CODIGO_CAJA_PAGO      = :CODIGO_CAJA_FAC ' +
    '   AND p.NUMERO_OPERACION_PAGO = :NUMERO_OPERACION_FAC ' +
    ' ORDER BY p.NUMERO_LINEA_PAGO';
  unqryPagosCajaFac.MasterFields :=
    'CODIGO_EMP_FAC;CODIGO_ALM_FAC;CODIGO_CAJA_FAC;' +
    'NUMERO_OPERACION_FAC';
  unqryPagosCajaFac.ReadOnly := True;
  dsPagosCajaFac := TDataSource.Create(Self);
  dsPagosCajaFac.DataSet := unqryPagosCajaFac;
  unqryVendedoresFac := CrearConsultaVendedores(Self, ConexionPrincipal);
  dsVendedoresFac := TDataSource.Create(Self);
  dsVendedoresFac.DataSet := unqryVendedoresFac;
  // Los MasterSource de los detalles los cablea el form via
  // AsignarMaestroCabecera (el DM ya no busca dsTablaG en el form).
  VigilarTotalMaximoLinea(unqryLinFac, 'TOTAL_FACLIN');
end;

procedure TdmFacturas.AsignarMaestroCabecera(ADataSource: TDataSource);
begin
  inherited;
  unqryLinfac.MasterSource := ADataSource;
  unqryRecibos.MasterSource := ADataSource;
  unqryEfectosVenta.MasterSource := ADataSource;
  unqryConsolidacion.MasterSource := ADataSource;
  unqryErrores.MasterSource := ADataSource;
  unqryMovimientosFac.MasterSource := ADataSource;
  unqryPagosCajaFac.MasterSource := ADataSource;
end;

function TdmFacturas.FacturaPermiteRecalcularLineas: Boolean;
var
  oCampoFase: TField;
  sFase: string;
begin
  Result := True;
  oCampoFase := unqryTablaG.FindField(ffasefac);
  if oCampoFase <> nil then
  begin
    sFase := Trim(oCampoFase.AsString);
    Result := (sFase = '') or SameText(sFase, 'BORRADOR') or
              SameText(sFase, cFaseFacturaSubsanacion) or
              (SinVerifactuActivo(ParametrosApp) and
               SameText(sFase, cFaseFacturaSinVerifactu));
  end;
end;

procedure TdmFacturas.OpenTables;
begin
  // Delegar en AbrirDetalles para que el flujo (cronometro y logging)
  // sea unico independientemente de quien lo invoque.
  AbrirDetalles;
end;

procedure TdmFacturas.AbrirDetalles;
const
  TAG = 'Facturas.AbrirDetalles';

  procedure AbrirSiCerrada(qry: TUniQuery);
  begin
    if not qry.Active then
      qry.Open;
  end;

var
  sw: TStopwatch;
begin
  inherited;
  sw := TStopwatch.StartNew;
  // Lookups y pestaña por defecto. Las queries lazy (Recibos,
  // Consolidacion, Errores, MovimientosFac) se abren al activar su
  // sub-pestaña via AsegurarXxxAbierta.
  AbrirSiCerrada(unqryIvasTipos);
  AbrirSiCerrada(unqryVendedoresFac);
  RefrescarAlmacenes('');
  AbrirSiCerrada(unqryLinFac);
  AbrirSiCerrada(unqrySeries);
  AbrirSiCerrada(unqryIvas);
  AbrirSiCerrada(unqryFormaPago);
  AbrirSiCerrada(unqryVerifactuOpe);
  AbrirSiCerrada(unqryTarifas);
  AbrirSiCerrada(unqryPaisesCli);
  AbrirSiCerrada(unqryPaisesEmp);
  RegistroLog.RegistrarRendimiento(TAG, 'TOTAL', sw.ElapsedMilliseconds);
end;

procedure TdmFacturas.RefrescarAlmacenes(const ACodigoEmpresa: string);
var
  sEmpresa: string;
begin
  sEmpresa := Trim(ACodigoEmpresa);
  if (sEmpresa = '') and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
    sEmpresa := Trim(unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  if (not unqryAlmacenesFac.Active) or
     (not SameText(unqryAlmacenesFac.ParamByName('EMPRESA').AsString,
                   sEmpresa)) then
  begin
    unqryAlmacenesFac.Close;
    unqryAlmacenesFac.ParamByName('EMPRESA').AsString := sEmpresa;
    unqryAlmacenesFac.Open;
  end;
  // El almacen solo es obligatorio si el borrador genera movimientos de
  // stock: AjustarEmpresaAlmacenDataSet lanza excepcion si la empresa no
  // tiene ningun almacen activo, y una instalacion sin almacenes (solo
  // servicios) debe poder facturar sin el.
  if unqryTablaG.Active and
     (unqryTablaG.State in [dsInsert, dsEdit]) and
     FacturaGeneraMovimientos then
    AjustarEmpresaAlmacenDataSet(unqryTablaG.Connection, unqryTablaG,
      'CODIGO_EMP_FAC', 'CODIGO_ALM_FAC');
end;

procedure TdmFacturas.RellenarParamsDesdeMaestro(AQry: TUniQuery);
var
  oMaestro: TDataSet;
  oCampo:   TField;
  i:        Integer;
begin
  if (AQry.MasterSource <> nil) and
     (AQry.MasterSource.DataSet <> nil) then
  begin
    oMaestro := AQry.MasterSource.DataSet;
    if oMaestro.Active and (not oMaestro.IsEmpty) then
    begin
      for i := 0 to AQry.Params.Count - 1 do
      begin
        oCampo := oMaestro.FindField(AQry.Params[i].Name);
        if oCampo <> nil then
          AQry.Params[i].Value := oCampo.Value;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarRecibosAbierta;
var swQ: TStopwatch;
begin
  if not unqryRecibos.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryRecibos);
      unqryRecibos.Open;
      RegistroLog.RegistrarRendimiento('Facturas.Lazy', 'unqryRecibos OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryRecibos ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarEfectosVentaAbierta;
var swQ: TStopwatch;
begin
  if (unqryEfectosVenta <> nil) and (not unqryEfectosVenta.Active) then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryEfectosVenta);
      unqryEfectosVenta.Open;
      RegistroLog.RegistrarRendimiento('Facturas.Lazy', 'unqryEfectosVenta OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryEfectosVenta ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.EstamparBancoRecibos(const ASerie, ANumero,
                                           ACodEmpban, AIban: string);
begin
  RequerirServiciosFactura;
  FServicioEfectos.EstamparBancoRecibos(
    ASerie,
    ANumero,
    ACodEmpban,
    AIban);
end;

function TdmFacturas.GetBancoDefectoCliente(
  const ACodigoCli: string): string;
begin
  RequerirServiciosFactura;
  Result := FServicioEfectos.BancoDefectoCliente(ACodigoCli);
end;

function TdmFacturas.GenerarEfectosVenta(const ACodEmpban: string = '';
                                         const AIbanEmp: string = ''): Integer;
var
  ResultadoCalculo: TResultadoOperacionFactura;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    if unqryTablaG.State in [dsEdit, dsInsert] then
    begin
      ResultadoCalculo := CalcularFactura;
      NotificarResultadoOperacion(ResultadoCalculo);
      unqryTablaG.Post;
    end;
    RequerirServiciosFactura;
    Result := FServicioEfectos.Generar(
      unqryTablaG.FieldByName('SERIE_FAC').AsString,
      unqryTablaG.FieldByName('NUMERO_FAC').AsString,
      IdentidadSesion.Usuario,
      ACodEmpban,
      AIbanEmp);
    if Assigned(unqryEfectosVenta) then
    begin
      unqryEfectosVenta.Close;
      unqryEfectosVenta.Open;
    end;
  end;
end;

function TdmFacturas.RegistrarCobroEfectoVenta(ANumEfecto: Integer;
  AFecha: TDateTime; AImporte: Double;
  const ATipo, AReferencia: string): Integer;
begin
  Result := -1;
  if (unqryTablaG <> nil) and unqryTablaG.Active and
     (not unqryTablaG.IsEmpty) then
  begin
    RequerirServiciosFactura;
    Result := FServicioEfectos.RegistrarCobro(
      unqryTablaG.FieldByName('SERIE_FAC').AsString,
      unqryTablaG.FieldByName('NUMERO_FAC').AsString,
      IdentidadSesion.Usuario,
      ANumEfecto,
      AFecha,
      AImporte,
      ATipo,
      AReferencia);
    if Assigned(unqryEfectosVenta) then
    begin
      unqryEfectosVenta.Close;
      unqryEfectosVenta.Open;
    end;
  end;
end;

function TdmFacturas.CambiarEstadoEfectoVenta(
  const AEstado: string): Boolean;
begin
  Result := False;
  if (unqryEfectosVenta <> nil) and unqryEfectosVenta.Active and
     (not unqryEfectosVenta.IsEmpty) then
  begin
    RequerirServiciosFactura;
    Result := FServicioEfectos.CambiarEstado(
      unqryEfectosVenta.FieldByName('SERIE_FAC_EFV').AsString,
      unqryEfectosVenta.FieldByName('NUMERO_FAC_EFV').AsString,
      IdentidadSesion.Usuario,
      unqryEfectosVenta.FieldByName('NUMERO_EFV').AsInteger,
      AEstado);
    unqryEfectosVenta.Close;
    unqryEfectosVenta.Open;
  end;
end;

procedure TdmFacturas.AsegurarConsolidacionAbierta;
var swQ: TStopwatch;
begin
  if not unqryConsolidacion.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryConsolidacion);
      unqryConsolidacion.Open;
      RegistroLog.RegistrarRendimiento(
        'Facturas.Lazy', 'unqryConsolidacion OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryConsolidacion ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarErroresAbierta;
var swQ: TStopwatch;
begin
  if not unqryErrores.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryErrores);
      unqryErrores.Open;
      RegistroLog.RegistrarRendimiento('Facturas.Lazy', 'unqryErrores OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryErrores ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.unqryTablaGAfterRefresh(DataSet: TDataSet);

  procedure RefrescarDetalleAbierto(AQuery: TUniQuery);
  begin
    // Los cerrados se abrirán al mostrar su pestaña (carga perezosa).
    if Assigned(AQuery) and AQuery.Active then
    begin
      RellenarParamsDesdeMaestro(AQuery);
      AQuery.Refresh;
    end;
  end;

begin
  // El envío de la cola Verifactu graba la consolidación, el registro y
  // los movimientos sin cambiar la clave de la cabecera, así que el
  // maestro-detalle no los vuelve a consultar al refrescar.
  RefrescarDetalleAbierto(unqryConsolidacion);
  RefrescarDetalleAbierto(unqryErrores);
  RefrescarDetalleAbierto(unqryMovimientosFac);
end;

procedure TdmFacturas.AsegurarPagosCajaFacAbierta;
var swQ: TStopwatch;
begin
  if not unqryPagosCajaFac.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryPagosCajaFac);
      unqryPagosCajaFac.Open;
      RegistroLog.RegistrarRendimiento(
        'Facturas.Lazy', 'unqryPagosCajaFac OK',
        swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryPagosCajaFac ERROR=' + E.Message,
          swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.AsegurarMovimientosFacAbierta;
var swQ: TStopwatch;
begin
  if not unqryMovimientosFac.Active then
  begin
    swQ := TStopwatch.StartNew;
    try
      RellenarParamsDesdeMaestro(unqryMovimientosFac);
      unqryMovimientosFac.Open;
      RegistroLog.RegistrarRendimiento(
        'Facturas.Lazy', 'unqryMovimientosFac OK', swQ.ElapsedMilliseconds);
    except
      on E: Exception do
      begin
        RegistroLog.RegistrarRendimiento('Facturas.Lazy',
          'unqryMovimientosFac ERROR=' + E.Message, swQ.ElapsedMilliseconds);
        raise;
      end;
    end;
  end;
end;

procedure TdmFacturas.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FLotesLineas);
  FRepositorio := nil;
  FValidadorFiscal := nil;
  FCalculador := nil;
  FServicioBorrado := nil;
  FCrearBorrado := nil;
  FServicioEfectos := nil;
  FreeAndNil(FAdvertenciasPendientes);
  unqryLinFac.Close;
  unqryIvas.Close;
  unqryTarifas.Close;
  unqrySeries.Close;
  unqryFormaPago.Close;
  //unqryPerfiles.Close;
  unqryRecibos.Close;
  if Assigned(unqryEfectosVenta) then
    unqryEfectosVenta.Close;
  unqryPaisesEmp.Close;
  unqryPaisesCli.Close;
  unqryConsolidacion.Close;
  unqryErrores.Close;
  if Assigned(unqryMovimientosFac) and unqryMovimientosFac.Active then
    unqryMovimientosFac.Close;
  if Assigned(unqryAlmacenesFac) and unqryAlmacenesFac.Active then
    unqryAlmacenesFac.Close;
  if Assigned(unqryVendedoresFac) and unqryVendedoresFac.Active then
    unqryVendedoresFac.Close;
  FreeAndNil(dsEfectosVenta);
  FreeAndNil(unqryEfectosVenta);
  //unqrySeriesEditCombo.Close;
  //unqryCabIVA.Close;
  inherited;
end;

procedure TdmFacturas.dsLinFacStateChange(Sender: TObject);
begin
  inherited;
  // La conmutacion de columnas editables (s/IVA vs c/IVA) es UI pura:
  // la resuelve el form suscrito a OnLinFacEstado.
  if Assigned(FOnLinFacEstado) then
    FOnLinFacEstado(Sender);
end;

function TdmFacturas.FormaPagoDefault: String;
var
  sFormaPago: string;
   LocateSuccess: Boolean;
begin
  LocateSuccess := unqryFormaPago.Locate('ESDEFAULT_FORMA_PAGO_FP', 'S', []);
  sFormaPago := unqryFormaPago.FindField('CODIGO_FP_FP').AsString;
  if LocateSuccess then
    Result := sFormaPago
  else
    Result := '';
end;

function TdmFacturas.GetCodigoGrupoIVAAGricola: String;
var
  qryIVAAG : TUniQuery;
  sResul:String;
begin
  sResul := '';
  qryIVAAG := TUniQuery.Create(Self);
  try
    qryIVAAG.Connection := ConexionEscritura;
    qryIVAAG.SQL.Text := 'SELECT IVA_IVAGRP ' +
                        '  FROM vi_ivas_empresa ' +
                        ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = :pAGRICOLA ' +
                        '   AND CODIGO_EMP_EMP = :pEMPRESA ' +
                        '   AND FECHA_DESDE_IVA <= :pFECHA ' +
                        '   AND (FECHA_HASTA_IVA IS NULL ' +
                        '       OR FECHA_HASTA_IVA > :pFECHA)' +
                        ' LIMIT 1;';
    qryIVAAG.ParamByName('pAGRICOLA').AsString := 'S';
    qryIVAAG.ParamByName('pFECHA').AsDateTime :=
      unqryTablaG.FieldByName('FECHA_FAC').AsDateTime;
    qryIVAAG.ParamByName('pEMPRESA').AsString :=
      unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
    qryIVAAG.Open;
    if qryIVAAG.RecordCount > 0 then
      sResul := qryIVAAG.Fields[0].AsString
    else
    begin
      qryIVAAG.Close;
      qryIVAAG.SQL.Text := 'SELECT IVA_IVAGRP ' +
                          '  FROM vi_ivas_empresa ' +
                          ' WHERE ESIVAAGRICOLA_IVA_IVAGRP = :pAGRICOLA ' +
                          '   AND ESDEFAULT_IVA_IVAGRP = :pDEFAULT ' +
                          '   AND FECHA_DESDE_IVA <= :pFECHA ' +
                          '   AND ( FECHA_HASTA_IVA IS NULL ' +
                          '        OR FECHA_HASTA_IVA > :pFECHA)' +
                          ' LIMIT 1;';
      qryIVAAG.ParamByName('pAGRICOLA').AsString := 'S';
      qryIVAAG.ParamByName('pDEFAULT').AsString := 'S';
      qryIVAAG.ParamByName('pFECHA').AsDateTime :=
        unqryTablaG.FieldByName('FECHA_FAC').AsDateTime;
      qryIVAAG.Open;
      sResul := qryIVAAG.Fields[0].AsString;
    end;
    qryIVAAG.Close;
  finally
    FreeAndNil(qryIVAAG);
  end;
  Result := sResul;
end;

function TdmFacturas.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
  function FindField(const Nombre: string): TField;
  begin
    Result := unqryTablaG.FindField(Nombre);
  end;
begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
    1: fPorcen := FindField('PORCENTAJE_IVAR_FAC').AsCurrency;
    2: fPorcen := FindField('PORCENTAJE_IVAS_FAC').AsCurrency;
    3: fPorcen := FindField('PORCENTAJE_IVAE_FAC').AsCurrency;
    else
    begin
      RegistrarAdvertencia(SErrorTipoIvaFactura, False);
      fPorcen := unqryLinFac.FindField('PORCENTAJE_IVAN_FAC').AsCurrency;
      unqryLinFac.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := 'N';
    end;
  end;
  Result := fPorcen;
end;

procedure TdmFacturas.GetCodigoAutoFactura;
begin
  if (unqryTablaG.FindField('NUMERO_FAC').AsString = '0') then
  begin
    unstrdprcGetContadorFactura.Params.Clear;
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pserie', ptInput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'ptipodoc', ptInput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pcont', ptOutput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pEMPRESA_CONTADOR', ptInput);
    unstrdprcGetContadorFactura.Params.CreateParam(
      ftString, 'pUSUARIOMODIF', ptInput);
    unstrdprcGetContadorFactura.ParamByName('pserie').AsString :=
      unqryTablaG.FindField('SERIE_FAC').AsString;
    unstrdprcGetContadorFactura.ParamByName('ptipodoc').AsString :=
      CrearConfiguracionDocumento(tdFactura, sdVenta).TipoContador;
    unstrdprcGetContadorFactura.ParamByName('pUSUARIOMODIF').AsString :=
      IdentidadSesion.Usuario;
    unstrdprcGetContadorFactura.ParamByName(
      'pEMPRESA_CONTADOR').AsString :=
        unqryTablaG.FindField('CODIGO_EMP_FAC').AsString;
    EjecutarContadorDocumento(unstrdprcGetContadorFactura);
    unqryTablaG.FindField('NUMERO_FAC').AsString :=
      unstrdprcGetContadorFactura.ParamByName('pcont').AsString;
  end;
end;

function TdmFacturas.TotalPrendasFactura: Double;
begin
  Result := TotalPrendasLineasVenta(unqryLinFac,
    'TIPO_IVA_ARTICULO_FACLIN');
end;

procedure TdmFacturas.DesempaquetarAtributosLineas;
var
  bReadOnlyLineas: Boolean;
begin
  if unqryLinFac.Active and (not unqryLinFac.IsEmpty) and
     (unqryLinFac.FindField('ATTR1_VALOR_FACLIN') <> nil) and
     (unqryLinFac.FindField('NUM_ATRIBUTOS_FACLIN') <> nil) then
  begin
    FDesempaquetandoAtributos := True;
    bReadOnlyLineas := unqryLinFac.ReadOnly;
    if bReadOnlyLineas then
      unqryLinFac.ReadOnly := False;
    try
      DesempaquetarAtributosLineasSku(unqryLinFac, 'FACLIN');
    finally
      unqryLinFac.ReadOnly := bReadOnlyLineas;
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

procedure TdmFacturas.GetCodigoAutoCliente;
begin
  if (unqryTablaG.FindField('CODIGO_CLI_FAC').AsString = '0') then
  begin
    //bEsNuevoCliente := True;
//    Llamada antigua a unstrdprcGetContador:
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
//      ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
//      ParamByName('ptipodoc').AsString :=  'CL';
//      ExecProc;
      unqryTablaG.FindField('CODIGO_CLI_FAC').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionEscritura,
                                                   'CL',
                                                   IdentidadSesion.Usuario);
//    end;
  end;
end;

function TdmFacturas.TarifaDefault: string;
begin
  Result := ParametrosCaja.TarifaDefecto;
end;

procedure TdmFacturas.GuardarParametrosEDocFactura(ADataSet: TDataSet);
var
  Qry: TUniQuery;
  bCamposDisponibles: Boolean;
begin
  bCamposDisponibles :=
    (ADataSet.FindField('CODIGO_OFICINA_CONTABLE_FAC') <> nil) and
    (ADataSet.FindField('CODIGO_ORGANO_GESTOR_FAC') <> nil) and
    (ADataSet.FindField('CODIGO_UNIDAD_TRAMITADORA_FAC') <> nil) and
    (ADataSet.FindField('NOMBRE_PERSONA_CLIENTE_FAC') <> nil) and
    (ADataSet.FindField('APELLIDOS_PERSONA_CLIENTE_FAC') <> nil);
  if bCamposDisponibles and
     (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') and
     (Trim(ADataSet.FieldByName('SERIE_FAC').AsString) <> '') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := unqryTablaG.Connection;
      Qry.SQL.Text :=
        ' UPDATE fza_facturas ' +
        ' SET CODIGO_OFICINA_CONTABLE_FAC = :OFICINA, ' +
        '     CODIGO_ORGANO_GESTOR_FAC = :ORGANO, ' +
        '     CODIGO_UNIDAD_TRAMITADORA_FAC = :UNIDAD, ' +
        '     NOMBRE_PERSONA_CLIENTE_FAC = :NOMBRE_PERSONA, ' +
        '     APELLIDOS_PERSONA_CLIENTE_FAC = :APELLIDOS_PERSONA ' +
        ' WHERE NUMERO_FAC = :NUMERO ' +
        '   AND SERIE_FAC = :SERIE ';
      Qry.ParamByName('OFICINA').AsString :=
        ADataSet.FieldByName('CODIGO_OFICINA_CONTABLE_FAC').AsString;
      Qry.ParamByName('ORGANO').AsString :=
        ADataSet.FieldByName('CODIGO_ORGANO_GESTOR_FAC').AsString;
      Qry.ParamByName('UNIDAD').AsString :=
        ADataSet.FieldByName('CODIGO_UNIDAD_TRAMITADORA_FAC').AsString;
      Qry.ParamByName('NOMBRE_PERSONA').AsString :=
        ADataSet.FieldByName('NOMBRE_PERSONA_CLIENTE_FAC').AsString;
      Qry.ParamByName('APELLIDOS_PERSONA').AsString :=
        ADataSet.FieldByName('APELLIDOS_PERSONA_CLIENTE_FAC').AsString;
      Qry.ParamByName('NUMERO').AsString :=
        ADataSet.FieldByName('NUMERO_FAC').AsString;
      Qry.ParamByName('SERIE').AsString :=
        ADataSet.FieldByName('SERIE_FAC').AsString;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmFacturas.GuardarOpcionMovimientosFactura(ADataSet: TDataSet);
var
  Qry: TUniQuery;
begin
  if (ADataSet.FindField('ESMUEVE_STOCK_FAC') <> nil) and
     (Trim(ADataSet.FieldByName('NUMERO_FAC').AsString) <> '') and
     (Trim(ADataSet.FieldByName('SERIE_FAC').AsString) <> '') then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := unqryTablaG.Connection;
      Qry.SQL.Text :=
        'UPDATE fza_facturas ' +
        '   SET ESMUEVE_STOCK_FAC = :pMUEVE ' +
        ' WHERE NUMERO_FAC = :pNUMERO ' +
        '   AND SERIE_FAC = :pSERIE';
      Qry.ParamByName('pMUEVE').AsString :=
        ADataSet.FieldByName('ESMUEVE_STOCK_FAC').AsString;
      Qry.ParamByName('pNUMERO').AsString :=
        ADataSet.FieldByName('NUMERO_FAC').AsString;
      Qry.ParamByName('pSERIE').AsString :=
        ADataSet.FieldByName('SERIE_FAC').AsString;
      Qry.ExecSQL;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

procedure TdmFacturas.GetCodigoAutoEmpresa;
begin
  if unqryTablaG.FindField('CODIGO_EMP_FAC').AsString = '0' then
  begin
//    Llamada antigua a unstrdprcGetContador:
//    begin
//      Params.Clear;
//      Params.CreateParam(ftString, 'ptipodoc', ptInput);
//      Params.CreateParam(ftInteger, 'pcont', ptOutput);
//      Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
//      ParamByName('ptipodoc').AsString :=  'EM';
//      ParamByName('pUSUARIOMODIF').AsString := IdentidadSesion.Usuario;
//      ExecProc;
      unqryTablaG.FindField('CODIGO_EMP_FAC').AsString :=
                                                 ObtenerSiguienteContador(
                                                   ConexionEscritura,
                                                   'EM',
                                                   IdentidadSesion.Usuario);
//    end;
  end;
end;

function TdmFacturas.FacturaGeneraMovimientos: Boolean;
var
  bMueveStock: Boolean;
  sTipo: string;
begin
  Result := False;
  if unqryTablaG.Active and
     (unqryTablaG.FindField('TIPO_FAC') <> nil) then
  begin
    sTipo := unqryTablaG.FieldByName('TIPO_FAC').AsString;
    bMueveStock := False;
    if unqryTablaG.FindField('ESMUEVE_STOCK_FAC') <> nil then
    begin
      bMueveStock := SameText(
        unqryTablaG.FieldByName('ESMUEVE_STOCK_FAC').AsString,
        'S');
    end;
    Result := FacturaDebeGenerarMovimientos(
      sTipo,
      bMueveStock);
  end;
end;

procedure TdmFacturas.unqryFacAfterPost(DataSet: TDataSet);
begin
  inherited;
  if not FGrabandoTotalesTrasPost then
    ProcesarFacturaPosteada(DataSet);
end;

procedure TdmFacturas.ProcesarFacturaPosteada(ADataSet: TDataSet);
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not ConexionEscritura.InTransaction;
  if bTransaccionPropia then
    ConexionEscritura.StartTransaction;
  try
    try
      // El DFM es anterior a estos campos; se persisten expresamente.
      GuardarOpcionMovimientosFactura(ADataSet);
      PropagarVendedorALineas;
      NotificarResultadoOperacion(CalcularFactura);
      // El cálculo deja la cabecera en dsEdit con los totales nuevos. Se
      // graban ya: si se queda editando, el Refresh del navegador recarga
      // los registros de UniDAC por debajo y su Post escribe en un búfer
      // liberado (EAssertionFailed "DisposeBuf failed").
      if ADataSet.State = dsEdit then
      begin
        FGrabandoTotalesTrasPost := True;
        try
          if ADataSet.Modified then
            ADataSet.Post
          else
            ADataSet.Cancel;
        finally
          FGrabandoTotalesTrasPost := False;
        end;
      end;
      GuardarParametrosEDocFactura(ADataSet);
      if bTransaccionPropia and ConexionEscritura.InTransaction then
        ConexionEscritura.Commit;
    except
      if bTransaccionPropia and ConexionEscritura.InTransaction then
        ConexionEscritura.Rollback;
      raise;
    end;
  finally
    NotificarAdvertenciasPendientes;
  end;
end;

procedure TdmFacturas.unqryLinFacAfterDelete(DataSet: TDataSet);
begin
  inherited;
  NotificarResultadoOperacion(CalcularFactura);
end;

procedure TdmFacturas.unqryLinFacAfterInsert(DataSet: TDataSet);
var
  i: Integer;
  oCampo: TField;
  procedure InicializarTexto(const ANombreCampo: string);
  begin
    oCampo := unqryLinFac.FindField(ANombreCampo);
    if Assigned(oCampo) and oCampo.IsNull then
      oCampo.AsString := '';
  end;
begin
  inherited;
  AplicarValoresPorDefecto(
    ConexionEscritura,
    unqryLinFac,
    'fza_facturas_lineas');
  // Los modos comunes sincronizan estos campos al resolver el SKU. Esta
  // defensa cubre altas clasicas o programaticas que no pasan por ellos.
  oCampo := unqryLinFac.FindField('NUM_ATRIBUTOS_FACLIN');
  if Assigned(oCampo) and oCampo.IsNull then
    oCampo.AsInteger := 0;
  for i := 1 to 5 do
  begin
    InicializarTexto('ATTR' + IntToStr(i) + '_VALOR_FACLIN');
    InicializarTexto('ATTR' + IntToStr(i) + '_NOMBRE_FACLIN');
  end;
  // Limpiar nro de línea para que BeforePost llame al SP de contador
  unqryLinFac.FindField(fnrolin).AsString := '0';
  unqryLinFac.FindField(fporiva).AsCurrency := GetTipoIVA(
    unqryLinFac.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
  unqryLinFac.FieldByName(fimpcl).AsString :=
    unqryTablaG.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString;
end;

function TdmFacturas.FacturaEnSubsanacion: Boolean;
var
  oCampoFase: TField;
begin
  Result := False;
  if unqryTablaG.Active then
  begin
    oCampoFase := unqryTablaG.FindField(ffasefac);
    Result := (oCampoFase <> nil) and
      SameText(Trim(oCampoFase.AsString), cFaseFacturaSubsanacion);
  end;
end;

// Campo de datos modificado en la edición en curso (los blob no se
// comparan: no cambian en subsanación y su valor anterior no es fiable).
function CampoDatosModificado(ACampo: TField): Boolean;
begin
  Result := (ACampo.FieldKind = fkData) and (not ACampo.IsBlob) and
    (ACampo.DataSet.State = dsEdit) and
    (VarToStr(ACampo.OldValue) <> VarToStr(ACampo.Value));
end;

procedure TdmFacturas.ValidarCabeceraSubsanacion(DataSet: TDataSet);
var
  i: Integer;
begin
  // En subsanación la cabecera sólo admite cambios en los datos del
  // cliente (y lo que arrastran); el resto identifica el registro. Los
  // Post del recálculo de totales no son del usuario.
  if FacturaEnSubsanacion and (DataSet.State = dsEdit) and
     (not FCalculandoFactura) and (not FGrabandoTotalesTrasPost) then
  begin
    for i := 0 to DataSet.FieldCount - 1 do
      if CampoDatosModificado(DataSet.Fields[i]) and
         (not CampoCabeceraEditableEnSubsanacion(
            DataSet.Fields[i].FieldName)) then
        raise EValidacionFactura.Create(Format(
          SErrorSubsanacionCabeceraSoloCliente,
          [DataSet.Fields[i].DisplayName]), cvfNinguno);
  end;
end;

procedure TdmFacturas.ValidarLineaSubsanacion(DataSet: TDataSet);
var
  i: Integer;
begin
  // El recálculo de totales y el desempaquetado ATTR no tocan la
  // estructura. En subsanación sólo cambian cantidades y precios: no se
  // añaden líneas ni cambia lo que identifica cada una (artículo, SKU,
  // descripción, unidad o tipo de IVA). El stock se regenera al
  // registrar la subsanación.
  if FacturaEnSubsanacion and (not FCalculandoFactura) and
     (not FDesempaquetandoAtributos) then
  begin
    if DataSet.State = dsInsert then
      raise EValidacionFactura.Create(
        SErrorSubsanacionEstructuraLineas, cvfNinguno);
    for i := 0 to DataSet.FieldCount - 1 do
      if CampoLineaFijoEnSubsanacion(DataSet.Fields[i].FieldName) and
         CampoDatosModificado(DataSet.Fields[i]) then
        raise EValidacionFactura.Create(Format(
          SErrorSubsanacionLineaCampoFijo,
          [DataSet.Fields[i].DisplayName]), cvfNinguno);
  end;
end;

procedure TdmFacturas.ValidarEstructuraLineasSubsanacion(
  DataSet: TDataSet);
begin
  if FacturaEnSubsanacion and (not FCalculandoFactura) and
     (not FDesempaquetandoAtributos) then
    raise EValidacionFactura.Create(
      SErrorSubsanacionEstructuraLineas, cvfNinguno);
end;

procedure TdmFacturas.ComprobarLineaSubsanacion(DataSet: TDataSet;
  AValidacion: TDataSetNotifyEvent);
begin
  // FZ-ISSUE-128: igual que la cabecera en unqryFacBeforePost.
  try
    AValidacion(DataSet);
  except
    on E: EValidacionFactura do
    begin
      if not Assigned(FOnValidacion) then
        raise;
      FOnValidacion(E);
      Abort;
    end;
  end;
end;

procedure TdmFacturas.unqryLinFacBeforeDeleteSubsanacion(
  DataSet: TDataSet);
begin
  ComprobarLineaSubsanacion(DataSet, ValidarEstructuraLineasSubsanacion);
end;

procedure TdmFacturas.unqryLinFacBeforePost(DataSet: TDataSet);
var
  sNuevoNroLinea: string;
  iContadorBD: Integer;
  iNuevaLinea: Integer;
  sNumLin: string;
  sNumero: string;
  sSerie: string;
  function FieldByName(const Nombre: string): TField;
  begin
    Result := unqryLinFac.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := unqryLinFac.FindField(Nombre);
  end;
begin
  inherited;
  // Desempaquetado ATTR en curso: post descriptivo, sin logica de
  // numeracion ni fiscal.
  if not FDesempaquetandoAtributos then
  begin
  ComprobarLineaSubsanacion(DataSet, ValidarLineaSubsanacion);
  // Salvaguarda si la linea llega con un SKU/codigo de barras sin pasar
  // por el editor de articulo del formulario.
  NormalizarArticuloSkuEnDataSet(ConexionEscritura, unqryLinFac,
    'CODIGO_ART_FACLIN', 'CODIGO_UNIDAD_FACLIN');
  if FieldByName(fdesart).AsString = '' then
  begin
    DataSet.Cancel;
    Abort;
  end;
  // F-LOTEC-016: antes de los totales (una serie deja la línea en 1).
  if Assigned(FLotesLineas) then
    FLotesLineas.AntesDePostLinea(unqryLinFac, DocumentoLotes);
  sNumLin := Trim(FindField(fnrolin).AsString);
  sNumero := Trim(unqryTablaG.FieldByName(fnrofac).AsString);
  sSerie  := Trim(unqryTablaG.FieldByName(fseriefac).AsString);
  if (sNumLin = '0') or
     (sNumLin = '') or
     ((DataSet.State = dsInsert) and
      LineaDocExiste(CrearContadorLineasDocumento(ConexionEscritura),
        LIN_FACTURAS, sSerie, sNumero,
        sNumLin)) then
  begin
    iNuevaLinea := GetSiguienteLineaDocLibreSiguiente(
      CrearContadorLineasDocumento(ConexionEscritura),
      CONT_FACTURAS, LIN_FACTURAS, sSerie, sNumero);
    if iNuevaLinea > 0 then
      sNuevoNroLinea := Format('%.3d', [iNuevaLinea])
    else
    begin
      unstdGetContadorLinea.ParamByName('pnumfac').AsString := sNumero;
      unstdGetContadorLinea.ParamByName('pserie').AsString := sSerie;
      unstdGetContadorLinea.ExecProc;
      sNuevoNroLinea :=
        unstdGetContadorLinea.ParamByName('presul').AsString;
    end;
    FindField(fnrolin).AsString := sNuevoNroLinea;
    // Sincronizar el contador en el dataset de cabecera para que un
    // Post posterior de la cabecera no sobreescriba el valor correcto
    if unqryTablaG.FindField('CONTADOR_LINEAS_FAC') <> nil then
    begin
      iContadorBD := StrToIntDef(sNuevoNroLinea, 0) + 10;
      if unqryTablaG.State = dsBrowse then
        unqryTablaG.Edit;
      unqryTablaG.FieldByName('CONTADOR_LINEAS_FAC').AsString :=
        Format('%.3d', [iContadorBD]);
    end;
  end;
  // FZ-ISSUE-130: la línea nueva hereda el almacén de la cabecera
  // para que el stock se mueva donde indica el documento.
  if (DataSet.State = dsInsert) and
     (Trim(FieldByName('CODIGO_ALM_FACLIN').AsString) = '') then
    FieldByName('CODIGO_ALM_FACLIN').AsString :=
      Trim(unqryTablaG.FieldByName('CODIGO_ALM_FAC').AsString);
  // La línea nueva hereda el vendedor de la cabecera, si lo hay.
  if (DataSet.State = dsInsert) and
     (FindField('CODIGO_VENDEDOR_FACLIN') <> nil) and
     (unqryTablaG.FindField('CODIGO_CAJERO_FAC') <> nil) and
     (Trim(FieldByName('CODIGO_VENDEDOR_FACLIN').AsString) = '') and
     (Trim(unqryTablaG.FieldByName('CODIGO_CAJERO_FAC').AsString) <> '')
  then
    FieldByName('CODIGO_VENDEDOR_FACLIN').AsString :=
      Trim(unqryTablaG.FieldByName('CODIGO_CAJERO_FAC').AsString);
  if DataSet.State in [dsEdit, dsInsert] then
    ActualizarAuditoria(DataSet);
  end;
end;

procedure TdmFacturas.AnotarCambioVendedor(ADataSet: TDataSet);
var
  oCampo: TField;
begin
  // Solo una edición puede cambiarlo: en el alta aún no hay líneas y en
  // los Post internos (totales recalculados) el valor anterior coincide
  // con el actual, así que no se propaga dos veces.
  oCampo := ADataSet.FindField('CODIGO_CAJERO_FAC');
  if oCampo <> nil then
  begin
    if ADataSet.State = dsEdit then
      FVendedorAntesDePost := Trim(VarToStr(oCampo.OldValue))
    else
      FVendedorAntesDePost := Trim(oCampo.AsString);
  end;
end;

procedure TdmFacturas.PropagarVendedorALineas;
var
  bReadOnlyLineas: Boolean;
  oCampo: TField;
begin
  oCampo := unqryTablaG.FindField('CODIGO_CAJERO_FAC');
  if (oCampo <> nil) and unqryLinFac.Active and
     (unqryLinFac.State = dsBrowse) and
     (not SameText(FVendedorAntesDePost, Trim(oCampo.AsString))) then
  begin
    // Cambio descriptivo, como el desempaquetado ATTR: sus Post no
    // renumeran, no validan artículos y no recalculan importes.
    FDesempaquetandoAtributos := True;
    bReadOnlyLineas := unqryLinFac.ReadOnly;
    try
      if bReadOnlyLineas then
        unqryLinFac.ReadOnly := False;
      PropagarVendedorCabeceraALineas(
        unqryLinFac, FVendedorAntesDePost, oCampo.AsString);
      FVendedorAntesDePost := Trim(oCampo.AsString);
    finally
      unqryLinFac.ReadOnly := bReadOnlyLineas;
      FDesempaquetandoAtributos := False;
    end;
  end;
end;

procedure TdmFacturas.unqryTablaGBeforeDelete(DataSet: TDataSet);
var
  Serie: string;
  Numero: string;
  Fase: string;
  Resultado: TResultadoBorradoFactura;
  Confirmado: Boolean;
begin
  Serie := DataSet.FieldByName(fseriefac).AsString;
  Numero := DataSet.FieldByName(fnrofac).AsString;
  Fase := '';
  if DataSet.FindField(ffasefac) <> nil then
    Fase := DataSet.FieldByName(ffasefac).AsString;
  EnlazarBorradoConexionEscritura;
  RequerirServiciosFactura;
  Resultado := FServicioBorrado.Validar(Serie, Numero, Fase);
  if not Resultado.Permitido then
  begin
    NotificarResultadoBorrado(Resultado);
    Abort;
  end;
  Confirmado := False;
  if Assigned(FOnConfirmarBorrado) then
    Confirmado := FOnConfirmarBorrado(Serie, Numero);
  if not Confirmado then
  begin
    Abort;
  end;
  Resultado := FServicioBorrado.Preparar(Serie, Numero, Fase,
    IdentidadSesion.Usuario);
  if not Resultado.Permitido then
  begin
    NotificarResultadoBorrado(Resultado);
    Abort;
  end;
end;

procedure TdmFacturas.unqryTablaGAfterDeleteTx(DataSet: TDataSet);
begin
  if Assigned(FServicioBorrado) then
    FServicioBorrado.Confirmar;
end;

procedure TdmFacturas.unqryTablaGDeleteErrorTx(DataSet: TDataSet;
  E: EDatabaseError; var Action: TDataAction);
begin
  RevertirBorradoFactura(FServicioBorrado);
end;

procedure TdmFacturas.unqryTablaGAfterInsert(DataSet: TDataSet);
  function FieldByName(const Nombre: string): TField;
  begin
    Result := unqryTablaG.FieldByName(Nombre);
  end;
  function FindField(const Nombre: string): TField;
  begin
    Result := unqryTablaG.FindField(Nombre);
  end;
begin
  inherited;
    AplicarValoresPorDefecto(ConexionEscritura, unqryTablaG, 'fza_facturas');
//    FieldByName('NUMERO_FAC').AsString := '0';
//    FieldByName('CODIGO_CLI_FAC').AsString := '0';
//    FieldByName('CODIGO_EMP_FAC').AsString := '0';
    FieldByName('TARIFA_ARTICULO_CLIENTE_FAC').AsString := TarifaDefault;
    FieldByName('ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString :=
                         unqryTarifas.FieldByName('ESIMP_INCL_TAR').AsString;
    FieldByName('FECHA_FAC').AsDateTime := Trunc(Now);
    FieldByName('FORMA_PAGO_FAC').AsString := FormaPagoDefault;
    FieldByName('ESCONSOLIDADA_FAC').AsString := 'N';
    // Toda factura nace en borrador: editable y sin imprimir hasta
    // lanzarla a Verifactu (Consolidar)
    FieldByName('FASE_FAC').AsString := 'BORRADOR';
    // Tipo de factura segun el formulario (NORMAL / SIMPLIFICADA)
    FieldByName('TIPO_FAC').AsString := FTipoFacturaDefecto;
    // Ambas opciones nacen desactivadas; el usuario puede activarlas.
    FieldByName('ESDESCRIPCIONES_AMP_FAC').AsString := 'N';
    FieldByName('ESFECHADEENTREGA_FAC').AsString := 'N';
    // Una factura normal insertada a mano es venta directa y mueve stock.
    // Los flujos que parten de otro documento deben negarlo expresamente.
    if FindField('ESMUEVE_STOCK_FAC') <> nil then
    begin
      if SameText(FieldByName('TIPO_FAC').AsString, 'NORMAL') then
        FieldByName('ESMUEVE_STOCK_FAC').AsString := 'S'
      else
        FieldByName('ESMUEVE_STOCK_FAC').AsString := 'N';
    end;
    // Encadenar alta: lo resuelve el form via OnNuevaFactura (el DM ya
    // no invoca botones de la UI directamente).
    if Assigned(FOnNuevaFactura) then
      FOnNuevaFactura(Self);
    RefrescarAlmacenes(FieldByName('CODIGO_EMP_FAC').AsString);
    // Empresa sin almacenes activos (instalacion de solo servicios): la
    // factura no puede mover stock y el check nace desmarcado, dejando
    // el almacen como opcional.
    if (FindField('ESMUEVE_STOCK_FAC') <> nil) and
       unqryAlmacenesFac.Active and unqryAlmacenesFac.IsEmpty then
      FieldByName('ESMUEVE_STOCK_FAC').AsString := 'N';
end;

procedure TdmFacturas.unqryLinFacBeforeEdit(DataSet: TDataSet);
begin
  inherited;
  // Editar una línea existente está permitido en subsanación (cantidades
  // y precios): aquí no va la guarda de estructura de BeforeInsert.
  PrepararCabeceraParaLineas;
end;

procedure TdmFacturas.unqryLinFacBeforeInsert(DataSet: TDataSet);
begin
  inherited;
  // En subsanación no se añaden líneas (rejilla, lector o código).
  ComprobarLineaSubsanacion(DataSet, ValidarEstructuraLineasSubsanacion);
  PrepararCabeceraParaLineas;
end;

procedure TdmFacturas.PrepararCabeceraParaLineas;
begin
  // Verificar que la factura esté guardada antes de insertar líneas
  if not Assigned(unqryTablaG) then
    Abort;
  // Si la cabecera está en edición o inserción, grabarla primero
  if unqryTablaG.State in [dsInsert, dsEdit] then
  begin
    try
      FGrabandoCabeceraParaLineas := True;
      try
        unqryTablaG.Post;
      finally
        FGrabandoCabeceraParaLineas := False;
      end;
    except
      on E: EAbort do
      begin
        raise;
      end;
      on E: Exception do
      begin
        NotificarResultadoOperacion(
          TResultadoOperacionFactura.Error(
            Format(
              SErrorInsertarLineasCabeceraFactura,
              [E.Message])));
        Abort;
      end;
    end;
  end;
  // Verificar que exista un número de factura válido
  if (unqryTablaG.FieldByName('NUMERO_FAC').AsString = '') or
     (unqryTablaG.FieldByName('NUMERO_FAC').AsString = '0') or
     (unqryTablaG.FieldByName('SERIE_FAC').AsString = '') then
  begin
    NotificarResultadoOperacion(
      TResultadoOperacionFactura.Error(
        SErrorBorradorSinGrabarParaLineas));
    Abort;
  end;
end;

procedure TdmFacturas.ConfigurarLotesLineas(
  const AConfig: TConfiguracionLotesLineas);
begin
  FreeAndNil(FLotesLineas);
  if AConfig.Activacion.AlgunModoActivo then
    FLotesLineas := TLotesLineasDocumento.Create(AConfig);
end;

function TdmFacturas.DocumentoLotes: TDocumentoLineaLote;
begin
  Result.TipoDocumento := 'FV';
  Result.Serie := Trim(unqryTablaG.FieldByName('SERIE_FAC').AsString);
  Result.Numero := Trim(unqryTablaG.FieldByName('NUMERO_FAC').AsString);
  Result.CodigoAlmacen :=
    Trim(unqryTablaG.FieldByName('CODIGO_ALM_FAC').AsString);
end;

procedure TdmFacturas.ElegirLoteLinea;
begin
  if Assigned(FLotesLineas) and unqryLinFac.Active and
     not unqryLinFac.IsEmpty then
    FLotesLineas.ElegirLote(unqryLinFac, DocumentoLotes);
end;

procedure TdmFacturas.unqryLinFacAfterPost(DataSet: TDataSet);
begin
  inherited;
  // Los posts del desempaquetado ATTR no alteran importes: salir sin
  // efectos de negocio.
  if not FDesempaquetandoAtributos then
  begin
  if Assigned(FLotesLineas) then
    FLotesLineas.DespuesDePostLinea;
  if not FCalculandoFactura and FRecalculoFacturaPendiente then
  begin
    FRecalculoFacturaPendiente := False;
    NotificarResultadoOperacion(CalcularFactura);
  end;
  end;
end;

procedure TdmFacturas.unqryFacBeforePost(DataSet: TDataSet);
begin
  inherited;
  // Impide que un Post anidado deje los buffers de UniDAC a medio postear.
  if FValidandoPost then
    Abort;
  FAdvertenciasPendientes.Clear;
  FValidandoPost := True;
  try
    try
      ValidarCabeceraSubsanacion(DataSet);
      ValidarCabeceraBeforePost(DataSet);
      AnotarCambioVendedor(DataSet);
    except
      on E: EValidacionFactura do
      begin
        FAdvertenciasPendientes.Clear;
        if Assigned(FOnValidacion) then
        begin
          FOnValidacion(E);
          Abort;
        end
        else
        begin
          raise;
        end;
      end;
      on E: Exception do
      begin
        FAdvertenciasPendientes.Clear;
        raise;
      end;
    end;
  finally
    FValidandoPost := False;
  end;
end;

procedure TdmFacturas.ValidarCabeceraBeforePost(DataSet: TDataSet);
var
  bValidar: Boolean;
  Datos: TDatosValidacionCabeceraFactura;
  NumeroManual: string;
begin
  Datos := CrearDatosValidacionCabeceraFactura(unqryTablaG);
  Datos.SeriePerteneceOtraEmpresa := ExisteSerieEmpresa(
    Datos.Serie, unqryTablaG.FieldByName(fcodemp).AsString,
    CrearConfiguracionDocumento(tdFactura, sdVenta).TipoContador);
  ValidarIdentidadCabeceraFactura(Datos);
  bValidar := EsCabeceraFacturaValidable(Datos);
  if bValidar then
    ValidarOperacionVfactu;
  // La subsanación conserva la fecha de expedición: no se reordena la
  // cronología de la serie.
  Datos.ControlarCronologia :=
    bValidar and (not SinVerifactuActivo(ParametrosApp)) and
    (not SameText(Trim(Datos.Fase), cFaseFacturaSubsanacion));
  if Datos.ControlarCronologia and Datos.TieneFecha then
  begin
    Datos.UltimaFechaSerie := UltimaFechaSerie(Datos.Serie,
      unqryTablaG.FieldByName(fcodemp).AsString, Datos.Numero);
  end;
  ValidarCoherenciaCabeceraFactura(Datos);
  if FechaCabeceraFacturaEsFutura(Datos, Date) then
    RegistrarAdvertencia(SAvisoFechaBorradorFutura, True);
  if unqryTablaG.State in [dsEdit, dsInsert] then
  begin
    if (unqryTablaG.State = dsInsert) and
       ParametrosApp.Licencia.Comprobada and Datos.TieneFecha then
    begin
      ValidarLimiteDemoFacturas(
        ConexionEscritura, ParametrosApp.Licencia.Estado, Datos.Fecha);
    end;
    if unqryTablaG.State = dsInsert then
    begin
      NumeroManual := Datos.Numero;
      if NumeroManual = '0' then
        NumeroManual := '';
      PrepararNumeracionDocumento(ConexionEscritura, dnFactura,
        unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString,
        Datos.Serie, IdentidadSesion.Usuario, NumeroManual, RegistroLog,
        function(AMensaje: string): Boolean
        begin
          Result := SolicitarConfirmacion(AMensaje);
        end);
      if NumeroManual <> '' then
      begin
        unqryTablaG.FieldByName('NUMERO_FAC').AsString := NumeroManual;
        Datos.Numero := NumeroManual;
      end;
    end;
    if Datos.Numero = '0' then
      GetCodigoAutoFactura;
    // Un cliente de paso conserva el código 0. Solo el botón de alta
    // reserva un código y guarda el cliente en su tabla.
    if unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString = '0' then
      GetCodigoAutoEmpresa;
    Datos.Numero := unqryTablaG.FieldByName('NUMERO_FAC').AsString;
    ValidarNumeroCabeceraFactura(Datos);
    if bValidar and (unqryTablaG.State = dsInsert) and
       HayHuecoNumeracion(
         Datos.Serie,
         unqryTablaG.FieldByName(fcodemp).AsString,
         Datos.Numero) then
    begin
      RegistrarAdvertencia(
        Format(SAvisoHuecoNumeracionFactura, [Datos.Serie]), True);
    end;
    ActualizarAuditoria(DataSet);
  end;
end;

function TdmFacturas.GenerarBorradorDesdeFacturaActual(AAbono: Boolean;
  const ASerie: string; AFecha: TDateTime;
  const AFormaPago: string): string;
var
  oProc: TUniStoredProc;
  oConsulta: TUniQuery;
begin
  if AAbono then
    oProc := unstrdprcCrearFacturaAbono
  else
    oProc := unstrdprcDuplicarFactura;
  oProc.ParamByName('pidseriefactura').AsString :=
    unqryTablaG.FieldByName('SERIE_FAC').AsString;
  oProc.ParamByName('pidnumfactura').AsString :=
    unqryTablaG.FieldByName('NUMERO_FAC').AsString;
  oProc.ParamByName('pidcodigo_empresa').AsString :=
    unqryTablaG.FieldByName('CODIGO_EMP_FAC').AsString;
  oProc.ParamByName('pidseriefacturaabono').AsString := ASerie;
  oProc.ParamByName('pfechafacturaabono').AsDate := AFecha;
  oProc.ParamByName('pUSUARIO').AsString := IdentidadSesion.Usuario;
  oProc.ExecProc;
  Result := oProc.ParamByName('pidnumfacturaabono').AsString;
  if Trim(AFormaPago) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := ConexionEscritura;
      oConsulta.SQL.Text :=
        'UPDATE fza_facturas SET FORMA_PAGO_FAC = :FORMA_PAGO ' +
        ' WHERE SERIE_FAC = :SERIE AND NUMERO_FAC = :NUMERO ' +
        '   AND FASE_FAC = ''BORRADOR''';
      oConsulta.ParamByName('FORMA_PAGO').AsString := Trim(AFormaPago);
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := Result;
      oConsulta.Execute;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmFacturas);
  ForceReferenceToClass(TdmFacturas);
end.
