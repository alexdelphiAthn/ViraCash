{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCaja                                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de caja (TPV).                                                }
{    Operaciones, pagos, vales, depósitos y generación de facturas desde caja. }
{******************************************************************************}
unit UniDataCaja;

interface

uses
  System.SysUtils, inLibErroresBBDD, System.Classes, Vcl.ExtCtrls, Data.DB,
  Datasnap.Provider,
  Datasnap.DBClient, Uni, MemDS, DBAccess, system.Math, UniDataGen,
  system.StrUtils, inLibFaseCobro, Windows,
  inLibCajaDatosFactura, inLibCajaTipos, inLibContextoSesionIntf,
  inLibParametrosIntf, inLibTicketsCajaIntf, inLibPreviewTicket,
  inLibMovimientosAlmacenAplicacion, inLibLogIntf;

type
  TTipoRectificativaCaja = inLibCajaTipos.TTipoRectificativaCaja;
  TTratamientoMovimientosRectificativa =
    inLibCajaTipos.TTratamientoMovimientosRectificativa;
  TDatosCabeceraFactura =
    inLibCajaDatosFactura.TDatosCabeceraFactura;

  // FZ-ISSUE-255: la línea tal como estaba antes de un cambio del usuario,
  // para deshacerlo si no se confirma el total.
  TCopiaLineaCaja = record
    Valores: TArray<Variant>;
    Total: Currency;
    Campo: string;
    Valor: Variant;
  end;

  TSolicitudMovimientoAlmacenCaja = record
    Movimiento: TMovimientoAlmacenEscritura;
    CajaDocumento: string;
    AlmacenDocumento: string;
    NumeroOperacion: string;
    CodigoCliente: string;
    // F-LOTEC-015: lote o serie que sale o vuelve ('' sin lote).
    Lote: string;
    FechaCaducidad: TDate;
  end;

  TDatosLineaFactura = record
    Linea:               string;
    Articulo:            string;
    Sku:                 string;
    Descripcion:         string;
    DescripcionVariacion:string;
    Familia:             string;
    NombreFamilia:       string;
    TipoArticulo:        string;
    TipoCantidad:        string;
    Cantidad:            Double;
    Tarifa:              string;
    EsImpIncl:           string;
    PrecioSalida:        Currency;
    PorcDto:             Double;
    PrecioDto:           Currency;
    PrecioSIva:          Currency;
    PrecioCIva:          Currency;
    TipoIva:             string;
    PorcIva:             Double;
    TotalSIva:           Currency;
    TotalCIva:           Currency;
    CosteUnitario:       Currency;
    Vendedor:            string;
    // campos de depósito
    VieneDeDeposito:     string;   // 'S', 'A', ''
    AccionDeposito:      string;   // 'COBRAR', 'NUEVO_DEP', 'AUMENTAR_DEP', ...
    idDeposito:          string;
    PrecioOriginalDep:   Currency;
    CantidadDeposito:    Double;
    AnticipoPrevio:      Currency;
    // F-LOTEC-015: lote o serie de la línea (0 = sin caducidad).
    Lote:                string;
    FechaCaducidad:      TDate;
  end;

  // Apartados pendientes (cliente de Varios) que cuelgan de un ticket.
  TApartadoTicketCaja = record
    Encontrado: Boolean;
    CodigoCliente: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    NombreContacto: string;
    Prendas: Integer;
  end;

type
  TRellenarArticuloEvent  = function(ACodigo: string): Boolean of object;
  TRellenarAtributosEvent = procedure(ASku: string) of object;
  TOnUpdateTotalEvent =
                     procedure(Sender: TObject; NuevoTotal: Currency) of object;
  TRecalcularLineasEvent = procedure of object;
  // AOrden: primer atributo (1..5) que le falta a la línea para cerrar
  // su SKU.
  TAtributoPendienteEvent = procedure(AOrden: Integer) of object;

  TdmCajaOpe = class(TDataModule)
    cdsLineas:TClientDataSet;
    cdsCabecera:TClientDataSet;
    DataSetProviderLineas:TDataSetProvider;
    DataSetProviderCabecera:TDataSetProvider;
    dsCabecera:TDataSource;
    dsLineas:TDataSource;
    qryDefinicionArticulo: TUniQuery;
    qryVales: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure cdsLineasBeforeInsert(DataSet: TDataSet);
    procedure cdsLineasAfterInsert(DataSet: TDataSet);
    procedure cdsCabeceraAfterInsert(DataSet: TDataSet);
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure cdsLineasAfterDelete(DataSet: TDataSet);
  private
    FConexion: TUniConnection;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FOnRellenarArticulo:  TRellenarArticuloEvent;
    FOnRellenarAtributos: TRellenarAtributosEvent;
    FOnUpdateTotal: TOnUpdateTotalEvent;
    FOnRecalcularLineas: TRecalcularLineasEvent;
    FOnAtributoPendiente: TAtributoPendienteEvent;
    // F-LOTEC-015: validación del lote de la línea (solo con interruptores).
    FValidarLoteLinea: TProc<TDataSet>;
    // FZ-ISSUE-424: unidades de la línea frente al stock de la tienda.
    FValidarStockLinea: TProc<TDataSet>;
    // Serie/numero reales de la ultima factura grabada por
    // GrabarFacturaSimplificada. La cola y la rectificativa Verifactu los
    // necesitan fiables: cdsCabecera puede quedar con SERIE_FAC='0'.
    FUltSerieFacGrabada:  string;
    FUltNumeroFacGrabada: string;
    // Fallos de lo que se hace tras confirmar la venta (FZ-ISSUE-145).
    FAvisoTrasGrabacion: string;
    FContextoSesion: IContextoSesionAplicacion;
    FConfirmarContador: TFunc<string, Boolean>;
    FRegistroLog: IRegistroLog;
    FRepositorioTicketsCaja: TRepositoriosTicketsCaja;
    FPreviewTicket: IPreviewTicket;
    FObtenerEmpresaTotalLinea: TFunc<string>;
    FConfirmarTotalLinea: TFunc<string, Boolean>;
    function GetIdentidadSesion: TIdentidadSesion;
    function InsertarMovimientoAlmacen(
      AConsultaTransaccion: TUniQuery;
      const ASolicitud: TSolicitudMovimientoAlmacenCaja): string;
    procedure InsertarLineaFactura(
                        QryTrx:              TUniQuery;
                        // — identificación —
                        const ASerie:        string;
                        const ANro:          string;
                        const ALinea:        string;   // '0010', '0020'...
                        // — artículo —
                        const AArticulo:     string;
                        const ASku:          string;
                        const ADesc:         string;
                        const ADescVariacion:string;
                        const AFamilia:      string;
                        const ANombreFamilia:string;
                        // 'ESTANDAR', 'SERVICIO', 'KIT'
                        const ATipoArticulo: string;
                        const ATipoCantidad: string;   // 'Uds', 'Kg'...
                        ACantidad:           Double;
                        ACosteUnitario:      Currency;
                        // — tarifa y precios —
                        const ATarifa:       string;
                        AEsImpIncl:          string;   // 'S'/'N'
                        APrecioSalida:       Currency;
                        APorcDto:            Double;
                        APrecioDto:          Currency;
                        APrecioSIva:         Currency;
                        APrecioCIva:         Currency;
                        const ATipoIva:      string;   // 'N','R','S','E'
                        APorcIva:            Double;
                        ATotalSIva:          Currency;
                        ATotalCIva:          Currency;
                        // — vendedor —
                        const AVendedor:     string;
                        // — caja y trazabilidad —
                        const AEmpresa:      string;
                        const AAlmacen:      string;
                        const ACaja:         string;
                        ANumOperacion:       string;
                        // NUMERO_MOV de fza_movimientos_almacen
                        const ANumMovAlmacen:string;
                        const AUsuario:      string;
                        const ALote:         string = '';
                        AFechaCaducidad:     TDate = 0);
    procedure ConfigurarEstructuraLineas;
    procedure ConfigurarEstructuraCabecera;
    function GetTipoIVA(sTipoIVA: string): Currency;
    function CuadrarFacturaEnMemoria(dsCabecera, dsLineas: TDataSet): Boolean;
//    function ObtenerAlmacenDepositoEmpresa(const AEmpresa: string): string;
    procedure CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                        const AEmpresa, ACliente,
                                        AArticulo, ASku, AUsuario: string;
                                        APrecioVenta, AAnticipo: Currency;
                                        const AAlmacenOrigen,
                                              AAlmacenDestino: string;
                                        ACantidad: Double;
                                        ATipoIVA: string;
                                        APorcIVA: Currency;
                                        AEsImpIncl: string;
                                        const ACaja, ANumOperacion: string;
                                        AFechaOperacion: TDateTime;
                                        AEsApartado: Boolean;
                                        const AContacto: TContactoApartado;
                                        out IdGenerado: string;
                                        out ANumerosMovimiento:
                                          TArray<string>;
                                        AConStock: Boolean = True;
                                        const ALote: string = '';
                                        AFechaCaducidad: TDate = 0);
    procedure CerrarDepositoCliente(QryTrx: TUniQuery;
                                    const AIdDeposito, AEmpresa,
                                          AAlmacen, ACaja,
                                          AUsuario: string);
    procedure AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                       const AIdDeposito, AEmpresa,
                                             AAlmacen, ACaja,
                                             AUsuario: string;
                                       ANuevoAbono: Currency);
    procedure InsertarCabeceraFactura(
      AConsulta: TUniQuery;
      const ASerie, ANumero: string;
      AFecha: TDateTime;
      const ATipo, AFase: string;
      const AEmpresa: string;
      const ACabecera: TDatosCabeceraFactura;
      const ASerieAbono, ANumeroAbono: string;
      const AAlmacen, ACaja, ACajero: string;
      const ANumeroOperacion, AUsuario: string);
    procedure TransformarLineasParaCobroParcial(cdsLineas: TDataSet;
                                                DineroEntregado: Currency);
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const APreviewTicket: IPreviewTicket); reintroduce;
    procedure AsignarContextoSesion(
      const AContextoSesion: IContextoSesionAplicacion);
    // F-LOTEC-015: la caja la asigna con los interruptores; la llama el
    // BeforePost de cada línea (puede avisar y abortar).
    property ValidarLoteLinea: TProc<TDataSet> read FValidarLoteLinea
      write FValidarLoteLinea;
    // FZ-ISSUE-424: también en el BeforePost de cada línea (avisa o aborta).
    property ValidarStockLinea: TProc<TDataSet> read FValidarStockLinea
      write FValidarStockLinea;
    procedure AsignarRepositorioTicketsCaja(
      const ARepositorio: TRepositoriosTicketsCaja);
    // FZ-ISSUE-255: total máximo por línea de la empresa de la caja. La
    // pantalla pregunta al cambiar unidades, precio, descuento o total.
    procedure VigilarTotalMaximoLinea(
      const AObtenerEmpresa: TFunc<string>;
      const AConfirmar: TFunc<string, Boolean>);
    procedure DejarDeVigilarTotalMaximoLinea;
    function ConfirmarSubidaTotalLinea(
      ATotalAnterior, ATotalNuevo: Currency): Boolean;
    function CopiarLineaActual(const ACampoEditado: string): TCopiaLineaCaja;
    procedure RestaurarLineaActual(const ACopia: TCopiaLineaCaja);
    property IdentidadSesion: TIdentidadSesion read GetIdentidadSesion;
    property ConfirmarContador: TFunc<string, Boolean>
      read FConfirmarContador write FConfirmarContador;
    property Conexion: TUniConnection read FConexion;
    property RegistroLog: IRegistroLog read FRegistroLog write FRegistroLog;
    // Cuenta del cliente por fecha de operacion (lo mas antiguo arriba).
    // AIncluirCerrados anade el historico: depositos ya cerrados, solo
    // para consulta (VIENE_DE_DEPOSITO = 'H', no suman ni se cobran).
    function DeudaClienteOtrasTiendas(const ACliente: string): string;
    procedure CargarDepositosCliente(const ACodigoCliente: string;
      AIncluirCerrados: Boolean = False);
    function BuscarApartadoTicket(
      const ASerie, ANumero: string): TApartadoTicketCaja;
    procedure CargarApartadoTicket(const ASerie, ANumero: string);
    function GenerarSkuFinal(ArticuloBase: string): string;
    function BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                  var LabelDestino: String):Boolean;
    function GetTarifaDefault : string;
    function TarifaInicialCliente(const ATarifa: string): string;
    // Tarifa con la que se cobra lo que no tiene precio en ATarifa: la
    // tarifa por defecto de caja (vacío si ATarifa ya es esa).
    function TarifaRespaldo(const ATarifa: string): string;
    // La periódica automática es una capa sobre la de caja: caer a la de
    // caja es lo previsto y no se avisa (FZ-ISSUE-727).
    function EsTarifaPeriodicaAutomatica(const ATarifa: string): Boolean;
    // ATipoFactura: 'SIMPLIFICADA' (ticket) o 'NORMAL' (factura A4 del
    // botón F8). AFechaFactura > 0 sustituye la fecha del documento.
    function GrabarFacturaSimplificada(const AEmpresa,
                                       AAlmacen,
                                       ACaja,
                                       ASerieElegida: string;
                                     DatosCobro: TDatosFaseCobro;
                                     SerieGenerada: string;
                                     out NumeroGenerado: String;
                                     out ValeGenerado:String;
                                     const ATipoFactura: string =
                                                          'SIMPLIFICADA';
                                     AFechaFactura: TDateTime = 0;
                                     AFechaOperacion: TDateTime = 0;
                                     const ANumeroManual: string = '';
                                     ATipoRectificativa:
                                       TTipoRectificativaCaja = trcNinguna;
                                     const ASerieRectificada: string = '';
                                     const ANumeroRectificado: string = '';
                                     ATratamientoMovimientos:
                                       TTratamientoMovimientosRectificativa =
                                         tmrMantenerOriginales;
                                     const AMotivoDevolucion: string = '';
                                     const ASerieOrigenDevolucion:
                                       string = '';
                                     const ANumeroOrigenDevolucion:
                                       string = '';
                                     const AEmpresaOrigenDevolucion:
                                       string = '';
                                     const AAlmacenOrigenDevolucion:
                                       string = '';
                                     const AArqueosConfirmados:
                                       TArray<string> = nil;
                                     const APresupuestoEmpresa: string = '';
                                     const APresupuestoSerie: string = '';
                                     const APresupuestoNumero: string = ''):
                                       Boolean;
    property OnUpdateTotal: TOnUpdateTotalEvent read FOnUpdateTotal
                                                write FOnUpdateTotal;
    property OnRellenarArticulo:  TRellenarArticuloEvent
                                  read FOnRellenarArticulo
                                  write FOnRellenarArticulo;
    property OnRellenarAtributos: TRellenarAtributosEvent
                                  read FOnRellenarAtributos
                                  write FOnRellenarAtributos;
    property OnRecalcularLineas: TRecalcularLineasEvent
                                 read FOnRecalcularLineas
                                 write FOnRecalcularLineas;
    // Se avisa antes de rechazar el Post de una línea sin todos sus
    // atributos, para que la pantalla lleve el foco al que falta.
    property OnAtributoPendiente: TAtributoPendienteEvent
                                  read FOnAtributoPendiente
                                  write FOnAtributoPendiente;
    property UltSerieFacturaGrabada:  string read FUltSerieFacGrabada;
    property UltNumeroFacturaGrabada: string read FUltNumeroFacGrabada;
    property AvisoTrasGrabacion: string read FAvisoTrasGrabacion;
    // Mayor FECHA_FAC ya emitida en la serie (0 si aun no tiene tickets).
    // Soporta el control de fecha por serie (grabacion y fase de cobro).
    class function FechaUltimoTicketSerie(
                            AConexion: TUniConnection;
                            const AEmpresa, ASerie: string): TDateTime;
  end;

  function LeerCabecera(cdsCabecera:TDataset): TDatosCabeceraFactura;
  function LeerLineaActual(cdsLineas:TDataset): TDatosLineaFactura;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  UniDataReparacionesVentaTpv, inLibReparaciones,
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  System.Variants, inLibTotalMaximoLinea, UniDataTotalMaximoLinea,
  UniDataValoresAutomaticosRepositorio,
  UniDataCajaStockRepositorio,
     UniDataFaseCobroRepositorio,
     UniDataAlmacenesEmpresaRepositorio,
     inLibDevExp,
     inLibCajaOpePresentacion, inLibCajaVentaOperacion,
     inLibTrazabilidad, UniDataMovimientosLote,
     inLibFacturas,
     inLibVerifactu,
     inLibVerifactuCola,
     inLibFaseCobroCalculo,
     inLibEmisionFiscalIntf,
     inLibEmisionFiscal,
     UniDataVerifactuColaRepositorio,
     inLibGenerarTicketBD,
     UniDataTicketsCajaRepositorio,
     UniDataFacturasLecturas,
     inLibDocumentoFiscal,
     inLibLicenciaAplicacion,
     UniDataLicenciaAplicacionRepositorio,
     UniDataMovimientosAlmacenRecalculo,
     UniDataCajaCierreVenta, UniDataNumeracionDocumentos,
     UniDataTraspaso,
     inLibPrestaShopColaSenal,
     inLibCajaDepositos, inLibInformesCajaPersistenciaIntf,
     UniDataInformesCajaRepositorio, inLibTarifasPeriodicidad,
     UniDataTarifasPeriodicidadRepositorio,
     inLibRectificativas,
     UniDataRectificativasSql, UniDataArqueoPersistencia,
     inLibArqueoPersistencia,
     System.Generics.Collections,
     inLibEAN13,
  inLibMsgPresupuestos, inLibMsgCaja, inLibMsgFacturas, inLibCajaVentaIntf;

{$R *.dfm}

type
  TNuevoDepositoCaja = record
    Id: string;
    Empresa: string;
    Almacen: string;
    Cliente: string;
    Articulo: string;
    Sku: string;
    Precio: Currency;
    Cantidad: Double;
    Anticipo: Currency;
    TipoIva: string;
    PorcentajeIva: Currency;
    EsImpIncl: string;
    Caja: string;
    NumeroOperacion: string;
    Usuario: string;
    Contacto: TContactoApartado;
  end;
  TLineaTraspasoDevolucion = record
    Sku: string;
    Articulo: string;
    Cantidad: Double;
    Lote: string;
    FechaCaducidad: TDate;
  end;
  TGrabacionFacturaCaja = class
  private
    FArqueosConfirmados: TArray<string>;
    FDataModule: TdmCajaOpe;
    FServicioEmisionFiscal: IServicioEmisionFiscal;
    FDatosCobro: TDatosFaseCobro;
    FQuery: TUniQuery;
    FCabecera: TDatosCabeceraFactura;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FPresupuestoEmpresa: string;
    FPresupuestoSerie: string;
    FPresupuestoNumero: string;
    FSerieElegida: string;
    FSerieGenerada: string;
    FTipoFactura: string;
    FNumeroManual: string;
    FSerieRectificada: string;
    FNumeroRectificado: string;
    FFechaFactura: TDateTime;
    FFechaOperacion: TDateTime;
    FTipoRectificativa: TTipoRectificativaCaja;
    FTratamientoMovimientos:
      TTratamientoMovimientosRectificativa;
    FUsuario: string;
    // FZ-ISSUE-402: FUsuario es el cajero (empleado); la auditoría
    // (USUARIO_ALTA/MODIF) lleva el usuario de la sesión.
    FUsuarioSesion: string;
    FAlmacenDeposito: string;
    FNumeroFactura: string;
    FNumeroOperacion: string;
    FValeGenerado: string;
    FConceptoOperacion: string;
    FTipoRectificativaFiscal: string;
    FRequiereFactura: Boolean;
    FGenerarMovimientos: Boolean;
    FPersistencia: TPersistenciaCierreVentaCajaUniDAC;
    FTotalVentasNormales: Currency;
    FTotalDevolucionesNormales: Currency;
    FNumeroLineaPago: Integer;
    // Devoluciones: motivo, ticket de origen y traspaso automático
    FMotivoDevolucion: string;
    FSerieOrigenDevolucion: string;
    FNumeroOrigenDevolucion: string;
    FEmpresaOrigenDevolucion: string;
    FAlmacenOrigenDevolucion: string;
    FLineasTraspasoDev: TArray<TLineaTraspasoDevolucion>;
    FNumerosMovimientos: TArray<string>;
    // FZ-ISSUE-778: servicios que se dejan en préstamo (su orden se crea
    // ahora) y servicios de depósitos que se cierran (su orden ya existe).
    FServiciosDeposito: TLineasServicioVenta;
    FServiciosDesdeDeposito: TLineasServicioVenta;
    procedure CargarContexto;
    function AlmacenDeposito: string;
    function OperacionTieneNovedad: Boolean;
    procedure AtenderOperacionSinNovedad;
    procedure DeterminarSiRequiereFactura;
    procedure ValidarSolicitud;
    procedure ValidarDevolucionPendiente;
    procedure SumarDevolucionesLineas(
      ADevolver: TDictionary<string, Double>);
    procedure AjustarCobroParcial;
    procedure IniciarTransaccion;
    function ObtenerNumeroFactura: string;
    procedure CrearFacturaSiProcede;
    procedure InsertarLineaAnticipo(
      const ALinea: TDatosLineaFactura;
      AImporte: Currency);
    procedure ProcesarAnticipoPrevio(
      const ALinea: TDatosLineaFactura);
    procedure ProcesarNuevoDeposito(
      const ALinea: TDatosLineaFactura);
    function RegistrarOperacionVenta(
      const ALinea: TDatosLineaFactura): string;
    function RegistrarMovimientoVenta(
      const ALinea: TDatosLineaFactura;
      const ANumeroMovimiento, AEmpresaMovimiento,
        AAlmacenOrigen, ATipoMovimiento: string): Currency;
    procedure ProcesarVenta(
      const ALinea: TDatosLineaFactura);
    procedure ProcesarLineas;
    procedure AnotarServicioDeposito(const ALinea: TDatosLineaFactura;
      const AIdDeposito: string;
      var ALineas: TLineasServicioVenta);
    procedure CrearOrdenesReparacion;
    procedure SincronizarContadorLineas;
    procedure RegistrarTotalesVenta;
    procedure RegistrarFiscalmente;
    procedure RegistrarFormasPago;
    procedure RegistrarValesRecogidos;
    procedure EmitirVale;
    procedure LeerHerenciaValePadre(out ACaducidad: TDateTime;
      out ACliente: string);
    function HayDepositosPendientes: Boolean;
    procedure ConfirmarTransaccion;
    procedure ImprimirDocumentosDeposito;
    procedure LimpiarLineasSinImporte;
    procedure AnyadirAvisoTrasGrabacion(const AAviso: string);
    procedure AtenderTareasTrasConfirmar;
    procedure RevertirTransaccion;
    procedure RevertirTrasError(E: Exception; AConfirmando: Boolean);
    procedure EjecutarTransaccion;
    procedure RegistrarMovimientoCreado(
      const ANumeroMovimiento: string);
    procedure ProcesarRecalculoMovimientos;
    function EsDevolucionOtraTienda: Boolean;
    procedure GenerarCodigoBarrasTicket;
    procedure RegistrarLineaTraspasoDevolucion(
      const ALinea: TDatosLineaFactura);
    function ObtenerSerieDocumentoTraspaso(
      const AEmpresa, AAlmacen, ATipoDoc: string): string;
    function ObtenerCosteMedioSkuAlmacen(
      const ASku, AAlmacen: string): Currency;
    function RegistrarLineasTraspasoDevolucion(
      const AEmpresaOrigen, ATipoDocumento, ASerieDocumento,
        ANumeroDocumento, ANumeroOperacion: string): Currency;
    procedure GenerarTraspasoAutomaticoDevolucion;
  public
    constructor Create(
      ADataModule: TdmCajaOpe;
      ADatosCobro: TDatosFaseCobro;
      const AEmpresa, AAlmacen, ACaja, ASerieElegida,
      ASerieGenerada, ATipoFactura: string;
      AFechaFactura, AFechaOperacion: TDateTime;
      const ANumeroManual: string;
      ATipoRectificativa: TTipoRectificativaCaja;
      const ASerieRectificada, ANumeroRectificado: string;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa;
      const AMotivoDevolucion: string = '';
      const ASerieOrigenDevolucion: string = '';
      const ANumeroOrigenDevolucion: string = '';
      const AEmpresaOrigenDevolucion: string = '';
      const AAlmacenOrigenDevolucion: string = '';
      const AArqueosConfirmados: TArray<string> = nil;
  const APresupuestoEmpresa: string = '';
  const APresupuestoSerie: string = '';
  const APresupuestoNumero: string = '');
    destructor Destroy; override;
    function Ejecutar(
      out ANumeroGenerado, AValeGenerado: string): Boolean;
  end;

constructor TdmCajaOpe.Create(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const APreviewTicket: IPreviewTicket);
var
  ProveedorContexto: IProveedorContextoSesion;
begin
  if not Assigned(AParametrosApp) then
    raise Exception.Create(SErrorParametrosAplicacionCajaNoConfigurados);
  if not Assigned(AParametrosCaja) then
    raise Exception.Create(SErrorParametrosModuloCajaNoConfigurados);
  FConexion := AConexion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FPreviewTicket := APreviewTicket;
  FRepositorioTicketsCaja :=
    CrearRepositoriosTicketsCaja(AConexion);
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, ProveedorContexto) then
    FContextoSesion := ProveedorContexto.ContextoSesion;
  inherited Create(AOwner);
end;

procedure TdmCajaOpe.AsignarContextoSesion(
  const AContextoSesion: IContextoSesionAplicacion);
begin
  FContextoSesion := AContextoSesion;
end;

procedure TdmCajaOpe.AsignarRepositorioTicketsCaja(
  const ARepositorio: TRepositoriosTicketsCaja);
begin
  if Assigned(ARepositorio.Tickets) and
     Assigned(ARepositorio.Resguardos) and
     Assigned(ARepositorio.Recordatorios) then
    FRepositorioTicketsCaja := ARepositorio;
end;

procedure TdmCajaOpe.VigilarTotalMaximoLinea(
  const AObtenerEmpresa: TFunc<string>;
  const AConfirmar: TFunc<string, Boolean>);
begin
  FObtenerEmpresaTotalLinea := AObtenerEmpresa;
  FConfirmarTotalLinea := AConfirmar;
end;

function TdmCajaOpe.CopiarLineaActual(
  const ACampoEditado: string): TCopiaLineaCaja;
var
  i: Integer;
begin
  SetLength(Result.Valores, cdsLineas.FieldCount);
  for i := 0 to cdsLineas.FieldCount - 1 do
    Result.Valores[i] := cdsLineas.Fields[i].Value;
  Result.Total := cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency;
  Result.Campo := ACampoEditado;
  Result.Valor := Null;
  if cdsLineas.FindField(ACampoEditado) <> nil then
    Result.Valor := cdsLineas.FieldByName(ACampoEditado).Value;
end;

procedure TdmCajaOpe.RestaurarLineaActual(const ACopia: TCopiaLineaCaja);
var
  i: Integer;
begin
  if not (cdsLineas.State in dsEditModes) then
    cdsLineas.Edit;
  for i := 0 to High(ACopia.Valores) do
  begin
    if (cdsLineas.Fields[i].FieldKind = fkData) and
       (not cdsLineas.Fields[i].ReadOnly) then
      cdsLineas.Fields[i].Value := ACopia.Valores[i];
  end;
end;

procedure TdmCajaOpe.DejarDeVigilarTotalMaximoLinea;
begin
  FObtenerEmpresaTotalLinea := nil;
  FConfirmarTotalLinea := nil;
end;

// El máximo solo se lee de la BBDD cuando el total ha subido. Sin
// vigilancia configurada no hay límite.
function TdmCajaOpe.ConfirmarSubidaTotalLinea(
  ATotalAnterior, ATotalNuevo: Currency): Boolean;
begin
  Result := (not Assigned(FObtenerEmpresaTotalLinea)) or
            (not HaSubidoTotalLinea(ATotalAnterior, ATotalNuevo)) or
            ConfirmarTotalLinea(ATotalAnterior, ATotalNuevo,
              LeerTotalMaximoLinea(FConexion, FObtenerEmpresaTotalLinea(),
                cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString),
              function(const AMensaje: string): Boolean
              begin
                Result := FConfirmarTotalLinea(AMensaje);
              end);
end;

function TdmCajaOpe.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionCajaNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

function LeerCabecera(cdsCabecera:TDataset): TDatosCabeceraFactura;
begin
  Result := inLibCajaDatosFactura.LeerCabeceraFactura(cdsCabecera);
end;

function LeerLineaActual(cdsLineas:TDataset): TDatosLineaFactura;
  function FieldByName(const ANombre: string): TField;
  begin
    Result := cdsLineas.FieldByName(ANombre);
  end;
begin
  Result.Linea               := FieldByName('LINEA_FACLIN').AsString;
    Result.Articulo            := FieldByName('CODIGO_ART_FACLIN').AsString;
    Result.Sku                 := FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
    Result.Descripcion := FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
    // Result.DescripcionVariacion:=
    // FieldByName('DESCRIPCION_VARIACION_FACLIN').AsString;
    Result.Familia             := FieldByName('CODIGO_FAM_FACLIN').AsString;
    Result.NombreFamilia       := FieldByName('NOMBRE_FAM_FACLIN').AsString;
    Result.TipoArticulo        := FieldByName('TIPO_ARTICULO_FACLIN').AsString;
    Result.TipoCantidad        :=
      FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString;
    Result.Cantidad            := FieldByName('CANTIDAD_FACLIN').AsFloat;
    Result.Tarifa              := FieldByName('CODIGO_TAR_FACLIN').AsString;
    Result.EsImpIncl := FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString;
    Result.PrecioSalida := FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency;
    Result.PorcDto             := FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat;
    Result.PrecioDto           := FieldByName('PRECIO_DTO_FACLIN').AsCurrency;
    Result.PrecioSIva          :=
      FieldByName('PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency;
    Result.PrecioCIva          :=
      FieldByName('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency;
    Result.TipoIva := FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString;
    Result.PorcIva             := FieldByName('PORCENTAJE_IVA_FACLIN').AsFloat;
    Result.TotalSIva := FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency;
    Result.TotalCIva           := FieldByName('TOTAL_FACLIN').AsCurrency;
    Result.CosteUnitario       :=
      FieldByName('PRECIO_ULT_COMPRA_FACLIN').AsCurrency;
    Result.Vendedor := FieldByName('CODIGO_VENDEDOR_FACLIN').AsString;
    Result.VieneDeDeposito     := FieldByName('VIENE_DE_DEPOSITO').AsString;
    Result.AccionDeposito      := FieldByName('ACCION_DEPOSITO').AsString;
    Result.PrecioOriginalDep   := FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
    Result.CantidadDeposito    := FieldByName('CANTIDAD_DEPOSITO_DEP').AsFloat;
    Result.AnticipoPrevio      := FieldByName('ANTICIPO_PREVIO').AsCurrency;
  Result.IdDeposito          := FieldByName('ID_DEPOSITO_DEP').AsString;
  Result.Lote := Trim(FieldByName('LOTE_FACLIN').AsString);
  Result.FechaCaducidad := 0;
  if not FieldByName('FECHA_CADUCIDAD_FACLIN').IsNull then
    Result.FechaCaducidad :=
      Trunc(FieldByName('FECHA_CADUCIDAD_FACLIN').AsDateTime);
end;

// =============================================================================
// MÓDULO: GESTIÓN DE CUENTAS Y DEPÓSITOS DE CLIENTES
// =============================================================================
const
  SQL_DEPOSITOS_PENDIENTES_CAJA =
    'SELECT d.ID_DEPOSITO_DEP, ' +
    '       d.CODIGO_ART_DEP, ' +
    '       d.CODIGO_UNIDAD_DEP, d.LOTE_DEP, d.FECHA_CADUCIDAD_DEP, ' +
    '       d.CANTIDAD_PENDIENTE_DEP, ' +
    '       d.PRECIO_VENTA_DEP, ' +
    '       d.IMPORTE_ANTICIPO_DEP, ' +
    '       d.TIPO_IVA_DEP, ' +
    '       d.PORCENTAJE_IVA_DEP, ' +
    '       d.ESIMP_INCL_DEP, ' +
    '       d.FECHA_CREACION_DEP, ' +
    '       d.ESTADO_DEP, ' +
    '       a.DESCRIPCION_ART, ' +
    '       a.TIPO_ART, ' +
    '       a.TIPO_CANTIDAD_ART, ' +
    '       a.CODIGO_FAM_ART, ' +
    '       COALESCE(NULLIF(TRIM(fam.NOMBRE_FAM_FAM), ''''), ' +
    '                fam.DESCRIPCION_FAM) AS DESCRIPCION_FAM ' +
    '  FROM fza_depositos_cliente d ' +
    '  LEFT JOIN fza_articulos a ' +
    '    ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
    '  LEFT JOIN fza_articulos_familias fam ' +
    '    ON fam.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ';
  // Los apartados se localizan por cualquier ticket que les haya cobrado
  // algo: el de la entrega inicial (DE) o el de un abono posterior (CB).
  SQL_FILTRO_APARTADO_TICKET =
    ' d.ESAPARTADO_DEP = ''S'' ' +
    '   AND d.ESTADO_DEP = ''PENDIENTE'' ' +
    '   AND EXISTS (SELECT 1 ' +
    '                 FROM fza_caja_operaciones o ' +
    '                WHERE o.ID_DEPOSITO_OPCAJA = d.ID_DEPOSITO_DEP ' +
    '                  AND o.SERIE_FAC_OPCAJA = :SERIE ' +
    '                  AND o.NUMERO_FAC_OPCAJA = :NUMERO) ';

// Cuenta del cliente en orden cronologico de operacion (lo mas antiguo
// arriba). Con AIncluirCerrados entran tambien los depositos cerrados
// (historico), intercalados por fecha con los pendientes.
procedure ConfigurarConsultaDepositosCliente(
  AConsulta: TUniQuery;
  AConexion: TUniConnection;
  const ACodigoCliente: string;
  const AUbicacion: TUbicacionSesion;
  AIncluirCerrados: Boolean);
var
  sFiltroEstado: string;
begin
  sFiltroEstado := '   AND d.ESTADO_DEP = ''PENDIENTE'' ';
  if AIncluirCerrados then
    sFiltroEstado := '';
  AConsulta.Connection := AConexion;
  AConsulta.SQL.Text :=
    SQL_DEPOSITOS_PENDIENTES_CAJA +
    ' WHERE d.CODIGO_CLI_DEP = :CLI ' +
    '   AND d.CODIGO_EMP_DEP = :EMPRESA ' +
    '   AND d.CODIGO_ALM_DEP = :ALMACEN ' +
    '   AND d.CODIGO_CAJA_DEP = :CAJA ' +
    sFiltroEstado +
    ' ORDER BY d.FECHA_CREACION_DEP, d.ID_DEPOSITO_DEP';
  AConsulta.ParamByName('CLI').AsString := ACodigoCliente;
  AConsulta.ParamByName('EMPRESA').AsString := AUbicacion.Empresa;
  AConsulta.ParamByName('ALMACEN').AsString := AUbicacion.Almacen;
  AConsulta.ParamByName('CAJA').AsString := AUbicacion.Caja;
end;

// La prenda entró en el almacén de depósitos con un traspaso: si el
// artículo ya no existe, se trata igualmente como artículo con stock.
function TipoArticuloPrendaDeposito(const ATipoArticulo: string): string;
begin
  Result := Trim(ATipoArticulo);
  if Result = '' then
    Result := 'ESTANDAR';
end;

procedure IncorporarPrendaDeposito(
  AConsulta: TUniQuery;
  ALineas: TClientDataSet);
var
  sIdDeposito: string;
  dPrecioOriginal: Currency;
  dPorcentajeIva: Currency;
  dPrecioSinIva: Currency;
  dCantidadPendiente: Double;
begin
  sIdDeposito := AConsulta.FieldByName('ID_DEPOSITO_DEP').AsString;
  dPrecioOriginal :=
    AConsulta.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
  dPorcentajeIva :=
    AConsulta.FieldByName('PORCENTAJE_IVA_DEP').AsCurrency;
  dPrecioSinIva := CalcularImporteSinIvaDeposito(
    dPrecioOriginal,
    dPorcentajeIva);
  dCantidadPendiente :=
    AConsulta.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
  ALineas.Append;
  ALineas.FieldByName('ID_DEPOSITO_DEP').AsString := sIdDeposito;
  ALineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
    AConsulta.FieldByName('CODIGO_ART_DEP').AsString;
  ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
    AConsulta.FieldByName('CODIGO_UNIDAD_DEP').AsString;
  ALineas.FieldByName('LOTE_FACLIN').AsString :=
    AConsulta.FieldByName('LOTE_DEP').AsString;
  ALineas.FieldByName('FECHA_CADUCIDAD_FACLIN').Value :=
    AConsulta.FieldByName('FECHA_CADUCIDAD_DEP').Value;
  ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    AConsulta.FieldByName('DESCRIPCION_ART').AsString;
  // Sin el tipo, ProcesarVenta no genera la salida desde el almacén de
  // depósitos y la prenda se queda en su stock (FZ-ISSUE-078).
  ALineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString :=
    TipoArticuloPrendaDeposito(AConsulta.FieldByName('TIPO_ART').AsString);
  ALineas.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
    AConsulta.FieldByName('TIPO_CANTIDAD_ART').AsString;
  ALineas.FieldByName('CODIGO_FAM_FACLIN').AsString :=
    AConsulta.FieldByName('CODIGO_FAM_ART').AsString;
  ALineas.FieldByName('NOMBRE_FAM_FACLIN').AsString :=
    AConsulta.FieldByName('DESCRIPCION_FAM').AsString;
  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := dCantidadPendiente;
  ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString := 'S';
  ALineas.FieldByName('FECHA_DEPOSITO_DEP').AsString :=
    FormatDateTime(
      'dd/mm/yyyy hh:nn',
      AConsulta.FieldByName('FECHA_CREACION_DEP').AsDateTime);
  ALineas.FieldByName('ACCION_DEPOSITO').AsString := 'COBRAR';
  ALineas.FieldByName('ESMARCADA_DEP').AsString := 'N';
  ALineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
    AConsulta.FieldByName('TIPO_IVA_DEP').AsString;
  ALineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency :=
    dPorcentajeIva;
  ALineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
    AConsulta.FieldByName('ESIMP_INCL_DEP').AsString;
  ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
    dPrecioOriginal;
  ALineas.FieldByName(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := dPrecioOriginal;
  ALineas.FieldByName(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := dPrecioSinIva;
  ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
  ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
  ALineas.FieldByName('TOTAL_FACLIN').AsCurrency :=
    dPrecioOriginal * dCantidadPendiente;
  ALineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency :=
    dPrecioSinIva * dCantidadPendiente;
  ALineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency :=
    dPrecioOriginal;
  ALineas.FieldByName('ANTICIPO_PREVIO').AsCurrency :=
    AConsulta.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
  ALineas.Post;
end;

procedure IncorporarAnticipoDeposito(
  AConsulta: TUniQuery;
  ALineas: TClientDataSet);
var
  dAnticipo: Currency;
  dPorcentajeIva: Currency;
  dAnticipoSinIva: Currency;
begin
  dAnticipo := AConsulta.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
  dPorcentajeIva :=
    AConsulta.FieldByName('PORCENTAJE_IVA_DEP').AsCurrency;
  dAnticipoSinIva := CalcularImporteSinIvaDeposito(
    dAnticipo,
    dPorcentajeIva);
  ALineas.Append;
  ALineas.FieldByName('ID_DEPOSITO_DEP').AsString :=
    AConsulta.FieldByName('ID_DEPOSITO_DEP').AsString;
  ALineas.FieldByName('CODIGO_ART_FACLIN').AsString := 'ACUENTA';
  ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString := 'ACUENTA';
  ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    'Abono a cuenta ' +
    AConsulta.FieldByName('CODIGO_UNIDAD_DEP').AsString;
  ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString := 'A';
  ALineas.FieldByName('FECHA_DEPOSITO_DEP').AsString :=
    FormatDateTime(
      'dd/mm/yyyy hh:nn',
      AConsulta.FieldByName('FECHA_CREACION_DEP').AsDateTime);
  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := -1;
  ALineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString := 'SERVICIO';
  ALineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
    AConsulta.FieldByName('TIPO_IVA_DEP').AsString;
  ALineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency :=
    dPorcentajeIva;
  ALineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
    AConsulta.FieldByName('ESIMP_INCL_DEP').AsString;
  ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := dAnticipo;
  ALineas.FieldByName(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := dAnticipo;
  ALineas.FieldByName(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := dAnticipoSinIva;
  ALineas.FieldByName('TOTAL_FACLIN').AsCurrency := -dAnticipo;
  ALineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency :=
    -dAnticipoSinIva;
  ALineas.FieldByName('TIPO_CANTIDAD_ARTICULO_FACLIN').AsString :=
    'Uds';
  ALineas.Post;
end;

// La prenda cerrada entra con cantidad e importes a 0: el calculo de
// totales recorre todas las lineas y asi no suma. El precio y la cantidad
// reales quedan en PRECIO_ORIGINAL_DEP y CANTIDAD_HISTORICO_DEP.
procedure IncorporarPrendaCerrada(
  AConsulta: TUniQuery;
  ALineas: TClientDataSet);
begin
  ALineas.Append;
  ALineas.FieldByName('ID_DEPOSITO_DEP').AsString :=
    AConsulta.FieldByName('ID_DEPOSITO_DEP').AsString;
  ALineas.FieldByName('CODIGO_ART_FACLIN').AsString :=
    AConsulta.FieldByName('CODIGO_ART_DEP').AsString;
  ALineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString :=
    AConsulta.FieldByName('CODIGO_UNIDAD_DEP').AsString;
  ALineas.FieldByName('LOTE_FACLIN').AsString :=
    AConsulta.FieldByName('LOTE_DEP').AsString;
  ALineas.FieldByName('FECHA_CADUCIDAD_FACLIN').Value :=
    AConsulta.FieldByName('FECHA_CADUCIDAD_DEP').Value;
  ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    AConsulta.FieldByName('DESCRIPCION_ART').AsString;
  ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString := 'H';
  ALineas.FieldByName('ESMARCADA_DEP').AsString := 'N';
  ALineas.FieldByName('FECHA_DEPOSITO_DEP').AsString :=
    FormatDateTime(
      'dd/mm/yyyy hh:nn',
      AConsulta.FieldByName('FECHA_CREACION_DEP').AsDateTime);
  ALineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString :=
    AConsulta.FieldByName('TIPO_IVA_DEP').AsString;
  ALineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency :=
    AConsulta.FieldByName('PORCENTAJE_IVA_DEP').AsCurrency;
  ALineas.FieldByName('ESIMP_INCL_TARIFA_FACLIN').AsString :=
    AConsulta.FieldByName('ESIMP_INCL_DEP').AsString;
  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := 0;
  ALineas.FieldByName('CANTIDAD_HISTORICO_DEP').AsFloat :=
    AConsulta.FieldByName('CANTIDAD_PENDIENTE_DEP').AsFloat;
  ALineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency :=
    AConsulta.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
  ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := 0;
  ALineas.FieldByName(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
  ALineas.FieldByName(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
  ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
  ALineas.FieldByName('TOTAL_FACLIN').AsCurrency := 0;
  ALineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency := 0;
  ALineas.Post;
end;

// Cada fila entra en el orden de la consulta: el deposito pendiente como
// prenda (y su abono a cuenta justo debajo); el cerrado, como historico.
procedure IncorporarDepositoCliente(
  AConsulta: TUniQuery;
  ALineas: TClientDataSet);
begin
  if Trim(AConsulta.FieldByName('ESTADO_DEP').AsString) <> 'PENDIENTE' then
    IncorporarPrendaCerrada(AConsulta, ALineas)
  else
  begin
    IncorporarPrendaDeposito(AConsulta, ALineas);
    if AConsulta.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency > 0 then
      IncorporarAnticipoDeposito(AConsulta, ALineas);
  end;
end;

procedure IncorporarDepositosCliente(
  AConsulta: TUniQuery;
  ALineas: TClientDataSet;
  const ARecalcularLineas: TRecalcularLineasEvent);
begin
  ALineas.DisableControls;
  try
    while not AConsulta.Eof do
    begin
      IncorporarDepositoCliente(AConsulta, ALineas);
      AConsulta.Next;
    end;
  finally
    ALineas.EnableControls;
  end;
  if Assigned(ARecalcularLineas) then
    ARecalcularLineas;
end;

function TdmCajaOpe.DeudaClienteOtrasTiendas(
  const ACliente: string): string;
var
  Repositorio: IRepositorioInformesCaja;
  Cuenta: IRepositorioCuentaClientes;
  Resultado: IResultadoInformeCaja;
  Datos: TDataSet;
  Ubicacion: TUbicacionSesion;
begin
  Result := '';
  Ubicacion := FContextoSesion.Ubicacion;
  Repositorio := CrearRepositorioInformesCajaUniDAC(FConexion);
  if Supports(Repositorio, IRepositorioCuentaClientes, Cuenta) then
  begin
    Resultado := Cuenta.ConsultarCuentaClientes(ACliente, True);
    Datos := Resultado.DataSet;
    Result := DescribirDeudaOtrasTiendas(Datos,
      Ubicacion.Empresa, Ubicacion.Almacen);
  end;
end;

procedure TdmCajaOpe.CargarDepositosCliente(
  const ACodigoCliente: string;
  AIncluirCerrados: Boolean);
var
  oConsulta: TUniQuery;
  oUbicacion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionCajaNoConfigurado);
  oUbicacion := FContextoSesion.Ubicacion;
  oConsulta := TUniQuery.Create(nil);
  try
    ConfigurarConsultaDepositosCliente(
      oConsulta,
      FConexion,
      ACodigoCliente,
      oUbicacion,
      AIncluirCerrados);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      IncorporarDepositosCliente(
        oConsulta,
        cdsLineas,
        FOnRecalcularLineas);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmCajaOpe.BuscarApartadoTicket(
  const ASerie, ANumero: string): TApartadoTicketCaja;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TApartadoTicketCaja);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT d.CODIGO_CLI_DEP, ' +
      '       d.CODIGO_EMP_DEP, ' +
      '       d.CODIGO_ALM_DEP, ' +
      '       d.CODIGO_CAJA_DEP, ' +
      '       MAX(d.NOMBRE_CONTACTO_DEP) AS NOMBRE_CONTACTO_DEP, ' +
      '       COUNT(*) AS PRENDAS ' +
      '  FROM fza_depositos_cliente d ' +
      ' WHERE ' + SQL_FILTRO_APARTADO_TICKET +
      ' GROUP BY d.CODIGO_CLI_DEP, d.CODIGO_EMP_DEP, ' +
      '          d.CODIGO_ALM_DEP, d.CODIGO_CAJA_DEP ' +
      ' ORDER BY PRENDAS DESC ' +
      ' LIMIT 1';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result.Encontrado := not oConsulta.IsEmpty;
    if Result.Encontrado then
    begin
      Result.CodigoCliente :=
        oConsulta.FieldByName('CODIGO_CLI_DEP').AsString;
      Result.Empresa := oConsulta.FieldByName('CODIGO_EMP_DEP').AsString;
      Result.Almacen := oConsulta.FieldByName('CODIGO_ALM_DEP').AsString;
      Result.Caja := oConsulta.FieldByName('CODIGO_CAJA_DEP').AsString;
      Result.NombreContacto :=
        oConsulta.FieldByName('NOMBRE_CONTACTO_DEP').AsString;
      Result.Prendas := oConsulta.FieldByName('PRENDAS').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmCajaOpe.CargarApartadoTicket(const ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
  oUbicacion: TUbicacionSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionCajaNoConfigurado);
  oUbicacion := FContextoSesion.Ubicacion;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // Mismas líneas que la cuenta del cliente (F2): prenda a precio
    // completo y lo entregado a cuenta en negativo; el total es el resto.
    oConsulta.SQL.Text :=
      SQL_DEPOSITOS_PENDIENTES_CAJA +
      ' WHERE ' + SQL_FILTRO_APARTADO_TICKET +
      '   AND d.CODIGO_EMP_DEP = :EMPRESA ' +
      '   AND d.CODIGO_ALM_DEP = :ALMACEN ' +
      '   AND d.CODIGO_CAJA_DEP = :CAJA ' +
      ' ORDER BY d.FECHA_CREACION_DEP';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.ParamByName('EMPRESA').AsString := oUbicacion.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := oUbicacion.Almacen;
    oConsulta.ParamByName('CAJA').AsString := oUbicacion.Caja;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      IncorporarDepositosCliente(
        oConsulta,
        cdsLineas,
        FOnRecalcularLineas);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure InsertarDepositoPrestamo(
  AConexion: TUniConnection;
  const ADeposito: TNuevoDepositoCaja);
var
  oProcedimiento: TUniStoredProc;
begin
  // El préstamo suma su pendiente a TOTAL_DEUDA_CLI dentro del SP.
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := AConexion;
    oProcedimiento.StoredProcName := 'PRC_FZA_DEPOSITOS_INSERT';
    oProcedimiento.Prepare;
    oProcedimiento.ParamByName('p_ID_DEP').AsString := ADeposito.Id;
    oProcedimiento.ParamByName('p_EMP').AsString := ADeposito.Empresa;
    oProcedimiento.ParamByName('p_ALM_DEP').AsString := ADeposito.Almacen;
    oProcedimiento.ParamByName('p_CLI').AsString := ADeposito.Cliente;
    oProcedimiento.ParamByName('p_ART').AsString := ADeposito.Articulo;
    oProcedimiento.ParamByName('p_SKU').AsString := ADeposito.Sku;
    oProcedimiento.ParamByName('p_PRECIO').AsCurrency := ADeposito.Precio;
    oProcedimiento.ParamByName('p_CANTIDAD').AsFloat := ADeposito.Cantidad;
    oProcedimiento.ParamByName('p_ANTICIPO').AsCurrency :=
      ADeposito.Anticipo;
    oProcedimiento.ParamByName('p_TIPOIVA').AsString := ADeposito.TipoIva;
    oProcedimiento.ParamByName('p_PORCIVA').AsCurrency :=
      ADeposito.PorcentajeIva;
    oProcedimiento.ParamByName('p_IMPINCL').AsString := ADeposito.EsImpIncl;
    oProcedimiento.ParamByName('p_CAJA').AsString := ADeposito.Caja;
    oProcedimiento.ParamByName('p_NUMOP').AsString :=
      ADeposito.NumeroOperacion;
    oProcedimiento.ParamByName('p_USUARIO').AsString := ADeposito.Usuario;
    oProcedimiento.Execute;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

procedure InsertarDepositoApartado(
  AConexion: TUniConnection;
  const ADeposito: TNuevoDepositoCaja);
var
  oConsulta: TUniQuery;
begin
  // El apartado del cliente de Varios no genera deuda y se inserta dentro
  // de la transacción de la venta (el SP de préstamos hace su COMMIT).
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO fza_depositos_cliente ( ' +
      '  ID_DEPOSITO_DEP, CODIGO_EMP_DEP, CODIGO_ALM_DEP, ' +
      '  CODIGO_CLI_DEP, CODIGO_ART_DEP, CODIGO_UNIDAD_DEP, ' +
      '  ESTADO_DEP, ESAPARTADO_DEP, NOMBRE_CONTACTO_DEP, ' +
      '  TELEFONO_CONTACTO_DEP, PRECIO_VENTA_DEP, ' +
      '  CANTIDAD_PENDIENTE_DEP, IMPORTE_ANTICIPO_DEP, ' +
      '  TIPO_IVA_DEP, PORCENTAJE_IVA_DEP, ESIMP_INCL_DEP, ' +
      '  CODIGO_CAJA_DEP, NUMERO_OPERACION_DEP, ' +
      '  INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
      'VALUES ( ' +
      '  :ID, :EMPRESA, :ALMACEN, :CLIENTE, :ARTICULO, :SKU, ' +
      '  ''PENDIENTE'', ''S'', :NOMBRE, :TELEFONO, :PRECIO, ' +
      '  :CANTIDAD, :ANTICIPO, :TIPOIVA, :PORCIVA, :IMPINCL, ' +
      '  :CAJA, :NUMOP, NOW(), :USUARIO, NOW(), :USUARIO)';
    oConsulta.ParamByName('ID').AsString := ADeposito.Id;
    oConsulta.ParamByName('EMPRESA').AsString := ADeposito.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ADeposito.Almacen;
    oConsulta.ParamByName('CLIENTE').AsString := ADeposito.Cliente;
    oConsulta.ParamByName('ARTICULO').AsString := ADeposito.Articulo;
    oConsulta.ParamByName('SKU').AsString := ADeposito.Sku;
    oConsulta.ParamByName('NOMBRE').AsString :=
      Copy(ADeposito.Contacto.Nombre, 1, 100);
    oConsulta.ParamByName('TELEFONO').AsString :=
      Copy(ADeposito.Contacto.Telefono, 1, 30);
    oConsulta.ParamByName('PRECIO').AsCurrency := ADeposito.Precio;
    oConsulta.ParamByName('CANTIDAD').AsFloat := ADeposito.Cantidad;
    oConsulta.ParamByName('ANTICIPO').AsCurrency := ADeposito.Anticipo;
    oConsulta.ParamByName('TIPOIVA').AsString := ADeposito.TipoIva;
    oConsulta.ParamByName('PORCIVA').AsCurrency := ADeposito.PorcentajeIva;
    oConsulta.ParamByName('IMPINCL').AsString := ADeposito.EsImpIncl;
    oConsulta.ParamByName('CAJA').AsString := ADeposito.Caja;
    oConsulta.ParamByName('NUMOP').AsString := ADeposito.NumeroOperacion;
    oConsulta.ParamByName('USUARIO').AsString := ADeposito.Usuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure DescontarDeudaDeposito(
  AConsulta: TUniQuery;
  const ACliente: string;
  AImporte: Currency;
  AEsApartado: Boolean);
begin
  // Los apartados del cliente de Varios nunca sumaron deuda.
  if not AEsApartado then
  begin
    AConsulta.SQL.Text :=
      'UPDATE fza_clientes ' +
      'SET TOTAL_DEUDA_CLI = COALESCE(TOTAL_DEUDA_CLI, 0) - :IMPORTE ' +
      'WHERE CODIGO_CLI_CLI = :CLIENTE';
    AConsulta.ParamByName('IMPORTE').AsCurrency := AImporte;
    AConsulta.ParamByName('CLIENTE').AsString := ACliente;
    AConsulta.Execute;
  end;
end;

procedure TdmCajaOpe.CerrarDepositoCliente(QryTrx: TUniQuery;
                                           const AIdDeposito,
                                                 AEmpresa,
                                                 AAlmacen,
                                                 ACaja,
                                                 AUsuario: string);
var
  Consulta: TUniQuery;
  Cliente: string;
  DeudaAnterior: Currency;
  EsApartado: Boolean;
begin
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := QryTrx.Connection;
    Consulta.SQL.Text :=
      'SELECT CODIGO_CLI_DEP, ESAPARTADO_DEP, ' +
      '       (PRECIO_VENTA_DEP * ' +
      '        COALESCE(CANTIDAD_PENDIENTE_DEP, 1)) - ' +
      '       COALESCE(IMPORTE_ANTICIPO_DEP, 0) AS DEUDA_ANTERIOR ' +
      'FROM fza_depositos_cliente ' +
      'WHERE ID_DEPOSITO_DEP = :ID ' +
      'AND CODIGO_EMP_DEP = :EMPRESA ' +
      'AND CODIGO_ALM_DEP = :ALMACEN ' +
      'AND CODIGO_CAJA_DEP = :CAJA ' +
      'AND ESTADO_DEP = ''PENDIENTE'' ' +
      'FOR UPDATE';
    Consulta.ParamByName('ID').AsString := AIdDeposito;
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('CAJA').AsString := ACaja;
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      Cliente := Consulta.FieldByName('CODIGO_CLI_DEP').AsString;
      DeudaAnterior :=
        Consulta.FieldByName('DEUDA_ANTERIOR').AsCurrency;
      EsApartado := Consulta.FieldByName('ESAPARTADO_DEP').AsString = 'S';
      Consulta.Close;
      Consulta.SQL.Text :=
        'UPDATE fza_depositos_cliente ' +
        'SET ESTADO_DEP = ''CERRADO'', ' +
        '    USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
        'WHERE ID_DEPOSITO_DEP = :ID ' +
        'AND CODIGO_EMP_DEP = :EMPRESA ' +
        'AND CODIGO_ALM_DEP = :ALMACEN ' +
        'AND CODIGO_CAJA_DEP = :CAJA ' +
        'AND ESTADO_DEP = ''PENDIENTE''';
      Consulta.ParamByName('USUARIO').AsString := AUsuario;
      Consulta.ParamByName('ID').AsString := AIdDeposito;
      Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
      Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
      Consulta.ParamByName('CAJA').AsString := ACaja;
      Consulta.Execute;
      DescontarDeudaDeposito(Consulta, Cliente, DeudaAnterior, EsApartado);
    end
    else
      raise Exception.Create(SErrorOperacionCajaNoEncontrada);
  finally
    FreeAndNil(Consulta);
  end;
end;

function LeerLineasCobroParcial(
  ALineas: TDataSet): TArray<TLineaCobroParcial>;
var
  i: Integer;
begin
  SetLength(Result, 0);
  ALineas.First;
  while not ALineas.Eof do
  begin
    i := Length(Result);
    SetLength(Result, i + 1);
    Result[i].IdDeposito :=
      ALineas.FieldByName('ID_DEPOSITO_DEP').AsString;
    Result[i].VieneDeDeposito :=
      ALineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
    Result[i].AccionDeposito :=
      ALineas.FieldByName('ACCION_DEPOSITO').AsString;
    Result[i].Descripcion :=
      ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
    Result[i].Total :=
      ALineas.FieldByName('TOTAL_FACLIN').AsCurrency;
    Result[i].Cantidad :=
      ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
    Result[i].AnticipoPrevio :=
      ALineas.FieldByName('ANTICIPO_PREVIO').AsCurrency;
    Result[i].PorcentajeIva :=
      ALineas.FieldByName('PORCENTAJE_IVA_FACLIN').AsCurrency;
    ALineas.Next;
  end;
end;

procedure EscribirLineaCobroParcial(
  ALineas: TDataSet;
  const ALinea: TLineaCobroParcial);
begin
  ALineas.Edit;
  ALineas.FieldByName('ACCION_DEPOSITO').AsString :=
    ALinea.AccionDeposito;
  ALineas.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString :=
    ALinea.Descripcion;
  ALineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency :=
    ALinea.PrecioOriginal;
  ALineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
    ALinea.PrecioSalida;
  ALineas.FieldByName(
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency :=
    ALinea.PrecioConIva;
  ALineas.FieldByName(
    'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency :=
    ALinea.PrecioSinIva;
  // La línea de abono es una unidad con lo entregado; las prendas que
  // entran en depósito son las unidades que tenía la línea.
  if ALinea.Cantidad > 0 then
    ALineas.FieldByName('CANTIDAD_DEPOSITO_DEP').AsFloat := ALinea.Cantidad
  else
    ALineas.FieldByName('CANTIDAD_DEPOSITO_DEP').AsFloat := 1;
  ALineas.FieldByName('CANTIDAD_FACLIN').AsFloat := 1;
  ALineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat := 0;
  ALineas.FieldByName('PRECIO_DTO_FACLIN').AsCurrency := 0;
  ALineas.FieldByName('TOTAL_FACLIN').AsCurrency := ALinea.Total;
  ALineas.FieldByName('TOTAL_FAC_SIVA_FACLIN').AsCurrency :=
    ALinea.TotalSinIva;
  ALineas.Post;
end;

procedure AplicarLineasCobroParcial(
  ADataSet: TDataSet;
  const ALineas: TArray<TLineaCobroParcial>);
var
  i: Integer;
begin
  i := 0;
  ADataSet.First;
  while (not ADataSet.Eof) and (i <= High(ALineas)) do
  begin
    if ALineas[i].Eliminar then
      ADataSet.Delete
    else
    begin
      if ALineas[i].Modificada then
        EscribirLineaCobroParcial(ADataSet, ALineas[i]);
      ADataSet.Next;
    end;
    Inc(i);
  end;
end;

procedure TdmCajaOpe.TransformarLineasParaCobroParcial(
  cdsLineas: TDataSet;
  DineroEntregado: Currency);
var
  oLineas: TArray<TLineaCobroParcial>;
begin
  cdsLineas.DisableControls;
  try
    oLineas := LeerLineasCobroParcial(cdsLineas);
    TCalculadorCobroParcial.Transformar(oLineas, DineroEntregado);
    AplicarLineasCobroParcial(cdsLineas, oLineas);
  finally
    cdsLineas.EnableControls;
  end;
end;

function FechaCajaConHora(AFechaCaja: TDateTime): TDateTime;
begin
  if AFechaCaja > 0 then
    Result := AFechaCaja
  else
    Result := Now;
end;

function TdmCajaOpe.InsertarMovimientoAlmacen(
  AConsultaTransaccion: TUniQuery;
  const ASolicitud: TSolicitudMovimientoAlmacenCaja): string;
var
  uspMov: TUniStoredProc;
  uspMovLote: TUniStoredProc;
  QryFecha: TUniQuery;
  sNumeroMov: string;
begin
  uspMovLote := nil;
  sNumeroMov := Trim(ASolicitud.Movimiento.Numero);
  if sNumeroMov = '' then
    sNumeroMov := ObtenerSiguienteContador(
      FConexion,
      'MV',
      IdentidadSesion.Usuario);
  uspMov := TUniStoredProc.Create(nil);
  try
    uspMov.Connection := AConsultaTransaccion.Connection;
    uspMov.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    uspMov.Prepare;
    uspMov.ParamByName('p_NUMERO_MOV').AsString              := sNumeroMov;
    uspMov.ParamByName('p_TIPO_DOC_MOV').AsString            :=
      ASolicitud.Movimiento.TipoDocumento;
    uspMov.ParamByName('p_SERIE_DOC_MOV').AsString           :=
      ASolicitud.Movimiento.SerieDocumento;
    uspMov.ParamByName('p_NRO_DOC_MOV').AsString             :=
      ASolicitud.Movimiento.NumeroDocumento;
    uspMov.ParamByName('p_LINEA_MOV').AsString               :=
      ASolicitud.Movimiento.Linea;
    uspMov.ParamByName('p_CODIGO_EMPRESA_MOV').AsString      :=
      ASolicitud.Movimiento.Empresa;
    uspMov.ParamByName('p_CODIGO_ALMACEN_MOV').AsString      :=
      ASolicitud.Movimiento.Almacen;
    uspMov.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString     :=
      ASolicitud.CajaDocumento;
    if Trim(ASolicitud.Movimiento.AlmacenContrapartida) = '' then
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
    else
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').AsString :=
        ASolicitud.Movimiento.AlmacenContrapartida;
    uspMov.ParamByName('p_CODIGO_UNIDAD_MOV').AsString       :=
      ASolicitud.Movimiento.Unidad;
    uspMov.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString     :=
      ASolicitud.Movimiento.TipoMovimiento;
    uspMov.ParamByName('p_CANTIDAD_MOV').AsFloat             :=
      Abs(ASolicitud.Movimiento.Cantidad);
    uspMov.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency      :=
      ASolicitud.Movimiento.CosteUnitario;
    uspMov.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency       :=
      ASolicitud.Movimiento.CosteUnitario *
      Abs(ASolicitud.Movimiento.Cantidad);
    uspMov.ParamByName('p_USUARIO').AsString                 :=
      ASolicitud.Movimiento.Usuario;
    uspMov.ParamByName('p_ALMACEN_DOC').AsString             :=
      ASolicitud.AlmacenDocumento;
    uspMov.ParamByName('p_NUMOP_DOC').AsString               :=
      ASolicitud.NumeroOperacion;
    uspMov.ParamByName('p_CODCLIENTE').AsString              :=
      ASolicitud.CodigoCliente;
    uspMov.ParamByName('p_CODARTICULO').AsString             :=
      ASolicitud.Movimiento.Articulo;
    // F-LOTEC-015: con lote o serie (e interruptores), ..._INSERT_LOTE.
    uspMovLote := TUniStoredProc.Create(nil);
    EjecutarMovimientoConLote(uspMov, uspMovLote, ASolicitud.Lote,
      ASolicitud.FechaCaducidad);
    if ASolicitud.Movimiento.Fecha > 0 then
    begin
      QryFecha := TUniQuery.Create(nil);
      try
        QryFecha.Connection := AConsultaTransaccion.Connection;
        QryFecha.SQL.Text :=
          'UPDATE fza_movimientos_almacen ' +
          '   SET FECHA_MOV = :FECHA ' +
          ' WHERE NUMERO_MOV = :NUMERO';
        QryFecha.ParamByName('FECHA').AsDateTime :=
          FechaCajaConHora(ASolicitud.Movimiento.Fecha);
        QryFecha.ParamByName('NUMERO').AsString := sNumeroMov;
        QryFecha.Execute;
      finally
        FreeAndNil(QryFecha);
      end;
    end;
  finally
    FreeAndNil(uspMovLote);
    FreeAndNil(uspMov);
  end;
  Result := sNumeroMov;
end;

procedure TdmCajaOpe.AumentarAnticipoDeposito(QryTrx: TUniQuery;
                                              const AIdDeposito,
                                                    AEmpresa,
                                                    AAlmacen,
                                                    ACaja,
                                                    AUsuario: string;
                                              ANuevoAbono: Currency);
var
  Consulta: TUniQuery;
  Cliente: string;
  EsApartado: Boolean;
begin
  if ANuevoAbono > 0 then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := QryTrx.Connection;
      Consulta.SQL.Text :=
        'SELECT CODIGO_CLI_DEP, ESAPARTADO_DEP ' +
        'FROM fza_depositos_cliente ' +
        'WHERE ID_DEPOSITO_DEP = :ID ' +
        'AND CODIGO_EMP_DEP = :EMPRESA ' +
        'AND CODIGO_ALM_DEP = :ALMACEN ' +
        'AND CODIGO_CAJA_DEP = :CAJA ' +
        'AND ESTADO_DEP = ''PENDIENTE'' ' +
        'FOR UPDATE';
      Consulta.ParamByName('ID').AsString := AIdDeposito;
      Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
      Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
      Consulta.ParamByName('CAJA').AsString := ACaja;
      Consulta.Open;
      if not Consulta.IsEmpty then
      begin
        Cliente := Consulta.FieldByName('CODIGO_CLI_DEP').AsString;
        EsApartado :=
          Consulta.FieldByName('ESAPARTADO_DEP').AsString = 'S';
        Consulta.Close;
        Consulta.SQL.Text :=
          'UPDATE fza_depositos_cliente ' +
          'SET IMPORTE_ANTICIPO_DEP = ' +
          '    COALESCE(IMPORTE_ANTICIPO_DEP, 0) + :ABONO, ' +
          '    USUARIO_MODIF = :USUARIO, INSTANTE_MODIF = NOW() ' +
          'WHERE ID_DEPOSITO_DEP = :ID ' +
          'AND CODIGO_EMP_DEP = :EMPRESA ' +
          'AND CODIGO_ALM_DEP = :ALMACEN ' +
          'AND CODIGO_CAJA_DEP = :CAJA ' +
          'AND ESTADO_DEP = ''PENDIENTE''';
        Consulta.ParamByName('ABONO').AsCurrency := ANuevoAbono;
        Consulta.ParamByName('USUARIO').AsString := AUsuario;
        Consulta.ParamByName('ID').AsString := AIdDeposito;
        Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
        Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
        Consulta.ParamByName('CAJA').AsString := ACaja;
        Consulta.Execute;
        DescontarDeudaDeposito(
          Consulta, Cliente, ANuevoAbono, EsApartado);
      end
      else
        raise Exception.Create(SErrorOperacionCajaNoEncontrada);
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

procedure TdmCajaOpe.CrearNuevoDepositoCliente(QryTrx: TUniQuery;
                                               const AEmpresa,
                                                     ACliente,
                                                     AArticulo,
                                                     ASku,
                                                     AUsuario:    string;
                                               APrecioVenta,
                                               AAnticipo:         Currency;
                                               const AAlmacenOrigen,
                                                     AAlmacenDestino: string;
                                               ACantidad:         Double;
                                               ATipoIVA:          string;
                                               APorcIVA:          Currency;
                                               AEsImpIncl:        string;
                                               const ACaja,
                                               ANumOperacion: string;
                                               AFechaOperacion: TDateTime;
                                               AEsApartado: Boolean;
                                               const AContacto:
                                                 TContactoApartado;
                                               out IdGenerado: string;
                                               out ANumerosMovimiento:
                                                 TArray<string>;
                                               AConStock: Boolean;
                                               const ALote: string;
                                               AFechaCaducidad: TDate);
var
  NuevoIdDep: string;
  SolicitudMovimiento: TSolicitudMovimientoAlmacenCaja;
  Deposito: TNuevoDepositoCaja;
begin
  // Un servicio no lleva stock: el depósito no lo traspasa al almacén de
  // depósitos (FZ-ISSUE-779).
  SetLength(ANumerosMovimiento, 0);
  if AConStock then
  begin
    SetLength(ANumerosMovimiento, 2);
    SolicitudMovimiento := Default(TSolicitudMovimientoAlmacenCaja);
    SolicitudMovimiento.Movimiento.TipoDocumento := 'TR';
    SolicitudMovimiento.Movimiento.Linea := '0001';
    SolicitudMovimiento.Movimiento.Empresa := AEmpresa;
    SolicitudMovimiento.Movimiento.Almacen := AAlmacenOrigen;
    SolicitudMovimiento.Movimiento.AlmacenContrapartida := AAlmacenDestino;
    SolicitudMovimiento.Movimiento.Unidad := ASku;
    SolicitudMovimiento.Lote := ALote;
    SolicitudMovimiento.FechaCaducidad := AFechaCaducidad;
    SolicitudMovimiento.Movimiento.Articulo := AArticulo;
    SolicitudMovimiento.Movimiento.TipoMovimiento := 'S';
    SolicitudMovimiento.Movimiento.Cantidad := ACantidad;
    SolicitudMovimiento.Movimiento.Usuario := AUsuario;
    SolicitudMovimiento.Movimiento.Fecha := AFechaOperacion;
    SolicitudMovimiento.CajaDocumento := ACaja;
    SolicitudMovimiento.AlmacenDocumento := AAlmacenOrigen;
    SolicitudMovimiento.NumeroOperacion := ANumOperacion;
    SolicitudMovimiento.CodigoCliente := ACliente;
    ANumerosMovimiento[0] := InsertarMovimientoAlmacen(
      QryTrx, SolicitudMovimiento);
    // 1b. Entrada al almacén depósito
    SolicitudMovimiento := Default(TSolicitudMovimientoAlmacenCaja);
    SolicitudMovimiento.Movimiento.TipoDocumento := 'TR';
    SolicitudMovimiento.Movimiento.Linea := '0002';
    SolicitudMovimiento.Movimiento.Empresa := AEmpresa;
    SolicitudMovimiento.Movimiento.Almacen := AAlmacenDestino;
    SolicitudMovimiento.Movimiento.AlmacenContrapartida := AAlmacenOrigen;
    SolicitudMovimiento.Movimiento.Unidad := ASku;
    SolicitudMovimiento.Lote := ALote;
    SolicitudMovimiento.FechaCaducidad := AFechaCaducidad;
    SolicitudMovimiento.Movimiento.Articulo := AArticulo;
    SolicitudMovimiento.Movimiento.TipoMovimiento := 'E';
    SolicitudMovimiento.Movimiento.Cantidad := ACantidad;
    SolicitudMovimiento.Movimiento.Usuario := AUsuario;
    SolicitudMovimiento.Movimiento.Fecha := AFechaOperacion;
    SolicitudMovimiento.CajaDocumento := ACaja;
    SolicitudMovimiento.AlmacenDocumento := AAlmacenOrigen;
    SolicitudMovimiento.NumeroOperacion := ANumOperacion;
    SolicitudMovimiento.CodigoCliente := ACliente;
    ANumerosMovimiento[1] := InsertarMovimientoAlmacen(
      QryTrx, SolicitudMovimiento);
  end;
  // 2. Generar ID único para el depósito (lógica original)
  NuevoIdDep := 'DP' + FormatDateTime('yymmddhhnnsszzz',
    FechaCajaConHora(AFechaOperacion)) +
                RightStr(ASku, 3);  // máx 20 chars
  NuevoIdDep := Copy(NuevoIdDep, 1, 20); // Aseguramos longitud máxima
  IdGenerado := NuevoIdDep;
  Deposito := Default(TNuevoDepositoCaja);
  Deposito.Id := NuevoIdDep;
  Deposito.Empresa := AEmpresa;
  Deposito.Almacen := AAlmacenOrigen;
  Deposito.Cliente := ACliente;
  Deposito.Articulo := AArticulo;
  Deposito.Sku := ASku;
  Deposito.Precio := APrecioVenta;
  Deposito.Cantidad := ACantidad;
  Deposito.Anticipo := AAnticipo;
  Deposito.TipoIva := ATipoIVA;
  Deposito.PorcentajeIva := APorcIVA;
  Deposito.EsImpIncl := AEsImpIncl;
  Deposito.Caja := ACaja;
  Deposito.NumeroOperacion := ANumOperacion;
  Deposito.Usuario := AUsuario;
  Deposito.Contacto := AContacto;
  if AEsApartado then
    InsertarDepositoApartado(QryTrx.Connection, Deposito)
  else
    InsertarDepositoPrestamo(QryTrx.Connection, Deposito);
  QryTrx.SQL.Text := 'UPDATE fza_depositos_cliente SET LOTE_DEP=:LOTE,' +
    'FECHA_CADUCIDAD_DEP=:CADUCIDAD, FECHA_CREACION_DEP=:FECHA ' +
    'WHERE ID_DEPOSITO_DEP=:ID ' +
    'AND CODIGO_EMP_DEP=:EMP';
  QryTrx.ParamByName('ID').AsString := IdGenerado;
  QryTrx.ParamByName('EMP').AsString := AEmpresa;
  QryTrx.ParamByName('FECHA').AsDateTime :=
    FechaCajaConHora(AFechaOperacion);
  QryTrx.ParamByName('LOTE').AsString := ALote;
  QryTrx.ParamByName('CADUCIDAD').DataType := ftDate;
  if AFechaCaducidad > 0 then
    QryTrx.ParamByName('CADUCIDAD').AsDate := AFechaCaducidad
  else
    QryTrx.ParamByName('CADUCIDAD').Clear;
  QryTrx.Execute;
end;

class function TdmCajaOpe.FechaUltimoTicketSerie(
                          AConexion: TUniConnection;
                          const AEmpresa, ASerie: string): TDateTime;
var
  Qry: TUniQuery;
begin
  // Devuelve la mayor fecha de documento ya grabada en la serie indicada.
  // Si la serie todavia no tiene tickets devuelve 0 (no hay restriccion).
  Result := 0;
  if Trim(ASerie) <> '' then
  begin
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConexion;
      Qry.SQL.Text :=
        'SELECT MAX(FECHA_FAC) AS ULTIMA_FECHA ' +
        '  FROM fza_facturas ' +
        ' WHERE CODIGO_EMP_FAC = :EMP ' +
        '   AND SERIE_FAC      = :SERIE';
      Qry.ParamByName('EMP').AsString   := AEmpresa;
      Qry.ParamByName('SERIE').AsString := ASerie;
      Qry.Open;
      if not Qry.Fields[0].IsNull then
        Result := Qry.Fields[0].AsDateTime;
    finally
      FreeAndNil(Qry);
    end;
  end;
end;

constructor TGrabacionFacturaCaja.Create(
  ADataModule: TdmCajaOpe;
  ADatosCobro: TDatosFaseCobro;
  const AEmpresa, AAlmacen, ACaja, ASerieElegida,
  ASerieGenerada, ATipoFactura: string;
  AFechaFactura, AFechaOperacion: TDateTime;
  const ANumeroManual: string;
  ATipoRectificativa: TTipoRectificativaCaja;
  const ASerieRectificada, ANumeroRectificado: string;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa;
  const AMotivoDevolucion: string = '';
  const ASerieOrigenDevolucion: string = '';
  const ANumeroOrigenDevolucion: string = '';
  const AEmpresaOrigenDevolucion: string = '';
  const AAlmacenOrigenDevolucion: string = '';
  const AArqueosConfirmados: TArray<string> = nil;
  const APresupuestoEmpresa: string = '';
  const APresupuestoSerie: string = '';
  const APresupuestoNumero: string = '');
begin
  inherited Create;
  FPresupuestoEmpresa := APresupuestoEmpresa;
  FPresupuestoSerie := APresupuestoSerie;
  FPresupuestoNumero := APresupuestoNumero;
  FArqueosConfirmados := AArqueosConfirmados;
  FDataModule := ADataModule;
  FServicioEmisionFiscal := CrearServicioEmisionFiscal(
    FDataModule.FParametrosApp,
    FDataModule.FParametrosCaja,
    FDataModule.FConexion,
    CrearServicioVerifactuColaUniDAC(FDataModule.FConexion));
  FPersistencia := TPersistenciaCierreVentaCajaUniDAC.Create(
    FDataModule.FConexion,
    FDataModule.IdentidadSesion.Usuario);
  FDatosCobro := ADatosCobro;
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FSerieElegida := ASerieElegida;
  FSerieGenerada := ASerieGenerada;
  FTipoFactura := ATipoFactura;
  FFechaFactura := AFechaFactura;
  FFechaOperacion := FechaCajaConHora(AFechaOperacion);
  FNumeroManual := ANumeroManual;
  FTipoRectificativa := ATipoRectificativa;
  FSerieRectificada := ASerieRectificada;
  FNumeroRectificado := ANumeroRectificado;
  FTratamientoMovimientos := ATratamientoMovimientos;
  FMotivoDevolucion := AMotivoDevolucion;
  FSerieOrigenDevolucion := ASerieOrigenDevolucion;
  FNumeroOrigenDevolucion := ANumeroOrigenDevolucion;
  FEmpresaOrigenDevolucion := AEmpresaOrigenDevolucion;
  FAlmacenOrigenDevolucion := AAlmacenOrigenDevolucion;
  SetLength(FLineasTraspasoDev, 0);
  SetLength(FNumerosMovimientos, 0);
end;

destructor TGrabacionFacturaCaja.Destroy;
begin
  FServicioEmisionFiscal := nil;
  FreeAndNil(FQuery);
  FreeAndNil(FPersistencia);
  inherited;
end;

procedure TGrabacionFacturaCaja.CargarContexto;
begin
  FNumeroFactura := '0';
  FNumeroOperacion := '';
  FValeGenerado := '';
  FDataModule.FUltSerieFacGrabada := '';
  FDataModule.FUltNumeroFacGrabada := '';
  FDataModule.FAvisoTrasGrabacion := '';
  FUsuario := FDataModule.cdsCabecera.FieldByName(
    'CODIGO_CAJERO_FAC').AsString;
  FUsuarioSesion := Trim(FDataModule.IdentidadSesion.Usuario);
  if FUsuarioSesion = '' then
    FUsuarioSesion := FUsuario;
  case FTipoRectificativa of
    trcDiferencias:
      begin
        FConceptoOperacion := 'Rectificativa por diferencias';
        FTipoRectificativaFiscal := 'I';
      end;
    trcSustitutiva:
      begin
        FConceptoOperacion := 'Rectificativa sustitutiva';
        FTipoRectificativaFiscal := 'S';
      end;
  else
    begin
      FConceptoOperacion := '';
      FTipoRectificativaFiscal := '';
    end;
  end;
  FGenerarMovimientos := DebeGenerarMovimientosRectificativa(
    FTipoRectificativaFiscal,
    FTratamientoMovimientos = tmrReemplazarOriginales);
  if (FConceptoOperacion <> '') and
     (Trim(FSerieRectificada) <> '') and
     (Trim(FNumeroRectificado) <> '') then
    FConceptoOperacion := FConceptoOperacion + ' de ' +
      FormatearReferenciaFactura(FDataModule.FConexion,
        FSerieRectificada, FNumeroRectificado);
  // Se resuelve al primer uso (AlmacenDeposito): una empresa sin almacen
  // de depositos debe poder vender en caja sin lineas de deposito.
  FAlmacenDeposito := '';
  if FDataModule.cdsCabecera.State in [dsEdit, dsInsert] then
    FDataModule.cdsCabecera.Post;
  if FDataModule.cdsLineas.State in [dsEdit, dsInsert] then
    FDataModule.cdsLineas.Post;
  if FDataModule.cdsLineas.IsEmpty then
    raise Exception.Create(SErrorOperacionCajaSinLineas);
  FCabecera := LeerCabecera(FDataModule.cdsCabecera);
  if FFechaFactura > 0 then
    FCabecera.Fecha := FFechaFactura;
end;

function TGrabacionFacturaCaja.AlmacenDeposito: string;
begin
  if FAlmacenDeposito = '' then
    FAlmacenDeposito := ObtenerAlmacenDepositoEmpresa(
      FDataModule.FConexion, FEmpresa);
  Result := FAlmacenDeposito;
end;

function TGrabacionFacturaCaja.OperacionTieneNovedad: Boolean;
var
  DatosDecision: TDatosDecisionCierreVentaCaja;
  sAccion: string;
begin
  DatosDecision.ImporteEntregado := FDatosCobro.ImporteEntregado;
  DatosDecision.EsDevolucionEconomica :=
    FDatosCobro.EsDevolucionEconomica;
  DatosDecision.TieneArticulosDevueltos :=
    FDatosCobro.TieneArticulosDevueltos;
  DatosDecision.ImporteValeEmitido := FDatosCobro.ImporteValeEmitido;
  DatosDecision.ImporteDejarCuenta := FDatosCobro.ImporteDejarCuenta;
  // FZ-ISSUE-379: una rectificación siempre graba (factura nueva y marca
  // de la original), aunque no haya cobro: la sustitutiva sin cambios
  // cobra 0 y antes se daba por grabada sin grabar nada.
  Result := FTipoRectificativa <> trcNinguna;
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while (not FDataModule.cdsLineas.Eof) and (not Result) do
    begin
      sAccion := Trim(FDataModule.cdsLineas.FieldByName(
        'ACCION_DEPOSITO').AsString);
      Result := AccionTieneNovedadCierreVenta(
        DatosDecision,
        sAccion);
      if not Result then
        FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
end;

procedure TGrabacionFacturaCaja.AtenderOperacionSinNovedad;
begin
  // El recordatorio del cliente de Varios mezclaría los apartados de
  // todos los que han apartado algo con ese cliente.
  if not FDatosCobro.EsClienteVarios then
    ImprimirRecordatorio(
      FDataModule.FPreviewTicket,
      FDataModule.FRepositorioTicketsCaja.Recordatorios,
      FDataModule.FContextoSesion.Ubicacion.Empresa,
      FCabecera.CodigoCliente,
      FDataModule.FParametrosCaja.ImpresoraCaja);
end;

procedure TGrabacionFacturaCaja.DeterminarSiRequiereFactura;
var
  sAccion: string;
  dTotalLiquido: Currency;
begin
  FRequiereFactura := False;
  dTotalLiquido := FDataModule.cdsCabecera.FieldByName(
    'TOTAL_LIQUIDO_FAC').AsCurrency;
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while (not FDataModule.cdsLineas.Eof) and
          (not FRequiereFactura) do
    begin
      sAccion := Trim(FDataModule.cdsLineas.FieldByName(
        'ACCION_DEPOSITO').AsString);
      FRequiereFactura := AccionRequiereFacturaCierreVenta(
        sAccion,
        dTotalLiquido);
      if not FRequiereFactura then
        FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
  FDatosCobro.FRequiereFactura := FRequiereFactura;
end;

procedure TGrabacionFacturaCaja.ValidarSolicitud;
var
  dUltimaFechaSerie: TDateTime;
begin
  if FRequiereFactura and SameText(FTipoFactura, 'NORMAL') then
  begin
    if Trim(FCabecera.RazonSocialCli) = '' then
      raise Exception.Create(
        SErrorRazonSocialClienteFacturaCajaObligatoria);
    if PaisEsEspana(
         FCabecera.CodigoPaisCli, FCabecera.NombrePaisCli) and
       (not DocumentoFiscalValido(FCabecera.NifCli)) then
      raise Exception.Create(
        SErrorDocumentoFiscalClienteCajaNoValido +
        MensajeDocumentoFiscalInvalido(FCabecera.NifCli));
    if PaisEsEspana(
         FCabecera.CodigoPaisEmp, FCabecera.NombrePaisEmp) and
       (not DocumentoFiscalValido(FCabecera.NifEmp)) then
      raise Exception.Create(
        SErrorDocumentoFiscalEmpresaCajaNoValido +
        MensajeDocumentoFiscalInvalido(FCabecera.NifEmp));
  end;
  if FRequiereFactura and (FNumeroManual = '') then
  begin
    dUltimaFechaSerie := TdmCajaOpe.FechaUltimoTicketSerie(
      FDataModule.FConexion, FEmpresa, FSerieElegida);
    if (dUltimaFechaSerie > 0) and
       (Trunc(FCabecera.Fecha) < Trunc(dUltimaFechaSerie)) then
      raise Exception.CreateFmt(
        SErrorFechaTicketSerieNoValida,
        [FSerieElegida,
         FormatDateTime('dd/mm/yyyy', dUltimaFechaSerie),
         FormatDateTime('dd/mm/yyyy', FCabecera.Fecha)]);
  end;
  if FRequiereFactura and
     FDataModule.FParametrosApp.Licencia.Comprobada then
    ValidarLimiteDemoFacturas(
      FDataModule.FConexion,
      FDataModule.FParametrosApp.Licencia.Estado,
      FCabecera.Fecha);
  ValidarDevolucionPendiente;
end;

// Unidades en negativo de la operación en curso, por SKU.
procedure TGrabacionFacturaCaja.SumarDevolucionesLineas(
  ADevolver: TDictionary<string, Double>);
var
  oLineas: TDataSet;
  sSku: string;
  rCantidad, rAcumulado: Double;
begin
  oLineas := FDataModule.cdsLineas;
  oLineas.DisableControls;
  try
    oLineas.First;
    while not oLineas.Eof do
    begin
      sSku := UpperCase(Trim(
        oLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString));
      rCantidad := oLineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
      if (sSku <> '') and (rCantidad < 0) then
      begin
        if not ADevolver.TryGetValue(sSku, rAcumulado) then
          rAcumulado := 0;
        ADevolver.AddOrSetValue(sSku, rAcumulado - rCantidad);
      end;
      oLineas.Next;
    end;
    oLineas.First;
  finally
    oLineas.EnableControls;
  end;
end;

// FZ-ISSUE-392: de una venta no se devuelven más unidades de las que
// quedan (vendidas menos ya devueltas). Vale para la rectificativa por
// diferencias y para la devolución comercial con ticket de origen; la
// sustitutiva reemplaza la venta entera y no pasa por aquí. Un SKU que no
// está en la venta de origen no se controla. Es un aviso al cajero
// (EValidacionBBDD), antes de abrir la transacción.
procedure TGrabacionFacturaCaja.ValidarDevolucionPendiente;
var
  sSerie, sNumero, sSku: string;
  oDevolver: TDictionary<string, Double>;
  oConsulta: TUniQuery;
  rDevolver, rVendida, rDevuelta: Double;
begin
  sSerie := Trim(FSerieRectificada);
  sNumero := Trim(FNumeroRectificado);
  if sSerie = '' then
  begin
    sSerie := Trim(FSerieOrigenDevolucion);
    sNumero := Trim(FNumeroOrigenDevolucion);
  end;
  if (sSerie <> '') and (sNumero <> '') and
     (FTipoRectificativa <> trcSustitutiva) then
  begin
    oDevolver := TDictionary<string, Double>.Create;
    oConsulta := TUniQuery.Create(nil);
    try
      SumarDevolucionesLineas(oDevolver);
      oConsulta.Connection := FDataModule.FConexion;
      oConsulta.SQL.Text :=
        'SELECT L.CODIGO_UNIDAD_FACLIN AS SKU, ' +
        '       MAX(L.DESCRIPCION_ARTICULO_FACLIN) AS DESCRIPCION, ' +
        '       SUM(L.CANTIDAD_FACLIN) AS VENDIDA, ' +
        '       MAX(' + SQLCantidadDevueltaVenta('L.SERIE_FAC_FACLIN',
          'L.NUMERO_FAC_FACLIN', 'L.CODIGO_UNIDAD_FACLIN') +
        ') AS DEVUELTA ' +
        '  FROM fza_facturas_lineas L ' +
        ' WHERE L.SERIE_FAC_FACLIN = :SERIE ' +
        '   AND L.NUMERO_FAC_FACLIN = :NUMERO ' +
        '   AND L.CANTIDAD_FACLIN > 0 ' +
        ' GROUP BY L.CODIGO_UNIDAD_FACLIN';
      oConsulta.ParamByName('SERIE').AsString := sSerie;
      oConsulta.ParamByName('NUMERO').AsString := sNumero;
      if oDevolver.Count > 0 then
        oConsulta.Open;
      while oConsulta.Active and (not oConsulta.Eof) do
      begin
        sSku := UpperCase(Trim(oConsulta.FieldByName('SKU').AsString));
        rVendida := oConsulta.FieldByName('VENDIDA').AsFloat;
        rDevuelta := oConsulta.FieldByName('DEVUELTA').AsFloat;
        if oDevolver.TryGetValue(sSku, rDevolver) and
           (rDevolver > rVendida - rDevuelta + 0.000001) then
          raise EValidacionBBDD.CreateFmt(
            SErrorDevolucionCajaSuperaPendiente,
            [FormatFloat('0.###', rDevolver),
             Trim(oConsulta.FieldByName('DESCRIPCION').AsString + ' (' +
               oConsulta.FieldByName('SKU').AsString + ')'),
             FormatearReferenciaFactura(FDataModule.FConexion, sSerie,
               sNumero),
             FormatFloat('0.###', rVendida - rDevuelta),
             FormatFloat('0.###', rVendida),
             FormatFloat('0.###', rDevuelta)]);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
      FreeAndNil(oDevolver);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.AjustarCobroParcial;
begin
  // FZ-ISSUE-379: en la sustitutiva lo cobrado con la factura original
  // cuenta como entregado; si no, se tomaría por un cobro parcial.
  if FDatosCobro.ImporteEntregado + FDatosCobro.ImporteYaCobrado <
     FDataModule.cdsCabecera.FieldByName(
       'TOTAL_LIQUIDO_FAC').AsCurrency then
  begin
    FDataModule.TransformarLineasParaCobroParcial(
      FDataModule.cdsLineas, FDatosCobro.ImporteEntregado);
    if not FDataModule.CuadrarFacturaEnMemoria(
      FDataModule.cdsCabecera, FDataModule.cdsLineas) then
      raise Exception.Create(SErrorCuadreCobroParcialCaja);
    FCabecera := LeerCabecera(FDataModule.cdsCabecera);
    if FFechaFactura > 0 then
      FCabecera.Fecha := FFechaFactura;
  end;
end;

procedure TGrabacionFacturaCaja.IniciarTransaccion;
var
  ModoArqueo: TModoCambioArqueoVenta;
begin
  FPersistencia.IniciarUnidadTrabajo;
  if FNumeroRectificado <> '' then
  begin
    ModoArqueo := mcavDiferencias;
    if FTipoRectificativa = trcSustitutiva then
      ModoArqueo := mcavSustitutiva;
    InvalidarArqueosCambioVenta(FDataModule.FConexion,
      FSerieRectificada, FNumeroRectificado,
      FDataModule.cdsCabecera.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency,
      ModoArqueo, FDataModule.IdentidadSesion.EsAdministrador,
      FArqueosConfirmados);
  end;
  FNumeroOperacion := FPersistencia.SiguienteOperacion(
    FEmpresa, FAlmacen, FCaja, FUsuario);
  FQuery := FPersistencia.CrearConsulta;
end;

function TGrabacionFacturaCaja.ObtenerNumeroFactura: string;
var
  oStoredProc: TUniStoredProc;
begin
  if FNumeroManual <> '' then
    Result := FNumeroManual
  else
  begin
    oStoredProc := TUniStoredProc.Create(nil);
    try
      oStoredProc.Connection := FDataModule.FConexion;
      oStoredProc.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      oStoredProc.Prepare;
      oStoredProc.ParamByName('pserie').AsString := FSerieGenerada;
      oStoredProc.ParamByName('pTipoDoc').AsString := 'FC';
      oStoredProc.ParamByName(
        'pEMPRESA_CONTADOR').AsString := FEmpresa;
      oStoredProc.ParamByName(
        'pUSUARIOMODIF').AsString := FUsuarioSesion;
      EjecutarContadorDocumentoUniDAC(oStoredProc,
        FDataModule.IdentidadSesion.EsAdministrador,
        FDataModule.FConfirmarContador);
      Result := oStoredProc.ParamByName('pcont').AsString;
    finally
      FreeAndNil(oStoredProc);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.CrearFacturaSiProcede;
begin
  if FRequiereFactura then
  begin
    AsegurarSerieFacturaCaja(FDataModule.FConexion,
      FEmpresa, FAlmacen, FCaja, FSerieGenerada, FTipoFactura,
      FUsuarioSesion, FCabecera.Fecha);
    FNumeroFactura := ObtenerNumeroFactura;
    FDatosCobro.TotalesFactura.Cabecera.Edit;
    FDatosCobro.TotalesFactura.Cabecera.FieldByName(
      'SERIE_FAC').AsString := FSerieElegida;
    FDatosCobro.TotalesFactura.Cabecera.FieldByName(
      'NUMERO_FAC').AsString := FNumeroFactura;
    FDatosCobro.TotalesFactura.Cabecera.FieldByName(
      'TIPO_FAC').AsString := FTipoFactura;
    FDatosCobro.TotalesFactura.Cabecera.Post;
    FDataModule.InsertarCabeceraFactura(
      FQuery,
      FSerieGenerada,
      FNumeroFactura,
      FCabecera.Fecha,
      FTipoFactura,
      'BORRADOR',
      FEmpresa,
      FCabecera,
      '',
      '',
      FAlmacen,
      FCaja,
      FUsuario,
      FNumeroOperacion,
      FUsuarioSesion);
    GenerarCodigoBarrasTicket;

  end
  else
  begin
    FSerieGenerada := '';
    FNumeroFactura := '0';
  end;
end;

procedure TGrabacionFacturaCaja.InsertarLineaAnticipo(
  const ALinea: TDatosLineaFactura;
  AImporte: Currency);
var
  dPrecioBase: Currency;
begin
  if FRequiereFactura then
  begin
    if ALinea.PorcIva = 0 then
      dPrecioBase := AImporte
    else
      dPrecioBase := AImporte / (1 + ALinea.PorcIva / 100);
    FDataModule.InsertarLineaFactura(
      FQuery, FSerieGenerada, FNumeroFactura,
      ALinea.Linea, 'ANTICIPO', 'ANTICIPO',
      ALinea.Descripcion, '', '', '', 'SERVICIO', 'Uds',
      1, 0, '', 'S', dPrecioBase, 0, 0, dPrecioBase, AImporte,
      ALinea.TipoIva, ALinea.PorcIva, dPrecioBase, AImporte,
      ALinea.Vendedor, FEmpresa, FAlmacen, FCaja,
      FNumeroOperacion, '', FUsuarioSesion);
  end;
end;

procedure TGrabacionFacturaCaja.ProcesarAnticipoPrevio(
  const ALinea: TDatosLineaFactura);
begin
  if FRequiereFactura and ((Abs(ALinea.TotalCIva) > 0.001) or
     (ALinea.TipoArticulo = 'SERVICIO')) then
    FDataModule.InsertarLineaFactura(
      FQuery, FSerieGenerada, FNumeroFactura, ALinea.Linea,
      ALinea.Articulo, ALinea.Sku, ALinea.Descripcion,
      ALinea.DescripcionVariacion, ALinea.Familia,
      ALinea.NombreFamilia, ALinea.TipoArticulo,
      ALinea.TipoCantidad, ALinea.Cantidad, ALinea.CosteUnitario,
      ALinea.Tarifa,
      ALinea.EsImpIncl, ALinea.PrecioSalida, ALinea.PorcDto,
      ALinea.PrecioDto, ALinea.PrecioSIva, ALinea.PrecioCIva,
      ALinea.TipoIva, ALinea.PorcIva, ALinea.TotalSIva,
      ALinea.TotalCIva, ALinea.Vendedor, FEmpresa, FAlmacen,
      FCaja, FNumeroOperacion, '', FUsuarioSesion);
  if Abs(ALinea.TotalCIva) > 0.001 then
    FPersistencia.GuardarOperacion(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion, 'CB',
      ALinea.TotalCIva, FUsuario, FFechaOperacion, FNumeroFactura,
      FSerieGenerada, FCabecera.CodigoCliente,
      'Consumo de anticipo: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', ALinea.IdDeposito);
end;

// Líneas convertidas en el cobro parcial: CANTIDAD_DEPOSITO_DEP guarda
// las prendas; la cantidad de la línea es la del abono (1).
function CantidadNuevoDeposito(const ALinea: TDatosLineaFactura): Double;
begin
  if ALinea.CantidadDeposito > 0 then
    Result := ALinea.CantidadDeposito
  else
    Result := ALinea.Cantidad;
end;

procedure TGrabacionFacturaCaja.ProcesarNuevoDeposito(
  const ALinea: TDatosLineaFactura);
var
  iIndice: Integer;
  NumerosMovimiento: TArray<string>;
  sIdDeposito: string;
begin
  if ALinea.TotalCIva > 0 then
    InsertarLineaAnticipo(ALinea, ALinea.TotalCIva);
  if ALinea.AccionDeposito = 'AUMENTAR_DEP' then
  begin
    FDataModule.AumentarAnticipoDeposito(
      FQuery, ALinea.IdDeposito, FEmpresa, FAlmacen,
      FCaja, FUsuario, ALinea.TotalCIva);
    if ALinea.TotalCIva > 0 then
      FPersistencia.GuardarOperacion(
        FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
        'CB', ALinea.TotalCIva, FUsuario, FFechaOperacion,
        FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
        'Cobro a cuenta: ' + ALinea.Descripcion,
        '', '', '', '', '', 'N', ALinea.IdDeposito);
  end
  else
  begin
    sIdDeposito := '';
    FDataModule.CrearNuevoDepositoCliente(
      FQuery, FEmpresa, FCabecera.CodigoCliente,
      ALinea.Articulo, ALinea.Sku, FUsuario,
      ALinea.PrecioOriginalDep, ALinea.TotalCIva,
      FAlmacen, AlmacenDeposito, CantidadNuevoDeposito(ALinea),
      ALinea.TipoIva, ALinea.PorcIva, ALinea.EsImpIncl,
      FCaja, FNumeroOperacion, FFechaOperacion,
      FDatosCobro.EsApartado, FDatosCobro.ContactoApartado, sIdDeposito,
      NumerosMovimiento, SameText(ALinea.TipoArticulo, 'ESTANDAR'),
      ALinea.Lote, ALinea.FechaCaducidad);
    for iIndice := Low(NumerosMovimiento) to High(NumerosMovimiento) do
      RegistrarMovimientoCreado(NumerosMovimiento[iIndice]);
    FPersistencia.GuardarOperacion(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'DE', ALinea.TotalCIva, FUsuario, FFechaOperacion,
      FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
      'Depósito: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', sIdDeposito);
    for iIndice := 0 to High(FDatosCobro.PrendasReparacion) do
      if FDatosCobro.PrendasReparacion[iIndice].LineaPrenda =
         ALinea.Linea then
        FDatosCobro.PrendasReparacion[iIndice].IdDeposito := sIdDeposito;
    AnotarServicioDeposito(ALinea, sIdDeposito, FServiciosDeposito);
  end;
end;

procedure TGrabacionFacturaCaja.AnotarServicioDeposito(
  const ALinea: TDatosLineaFactura; const AIdDeposito: string;
  var ALineas: TLineasServicioVenta);
var
  Servicio: TLineaServicioVenta;
  dPrecio: Currency;
begin
  if SameText(ALinea.TipoArticulo, 'SERVICIO') and
     (Trim(AIdDeposito) <> '') then
  begin
    Servicio := Default(TLineaServicioVenta);
    Servicio.Linea := ALinea.Linea;
    Servicio.Articulo := ALinea.Articulo;
    Servicio.Descripcion := ALinea.Descripcion;
    Servicio.IdDeposito := Trim(AIdDeposito);
    Servicio.Cantidad := CantidadNuevoDeposito(ALinea);
    // PRECIO_ORIGINAL_DEP es unitario con impuestos.
    dPrecio := ALinea.PrecioOriginalDep;
    if dPrecio = 0 then
      dPrecio := ALinea.PrecioCIva;
    Servicio.Total := dPrecio * Servicio.Cantidad;
    Servicio.CosteUltimaCompra := ALinea.CosteUnitario;
    ALineas := ALineas + [Servicio];
  end;
end;

function TGrabacionFacturaCaja.RegistrarOperacionVenta(
  const ALinea: TDatosLineaFactura): string;
var
  dImporteCierre: Currency;
  sIdDeposito: string;
begin
  if ALinea.VieneDeDeposito = 'S' then
  begin
    sIdDeposito := ALinea.IdDeposito;
    Result := AlmacenDeposito;
    FDataModule.CerrarDepositoCliente(
      FQuery, sIdDeposito, FEmpresa, FAlmacen,
      FCaja, FUsuario);
    // PRECIO_ORIGINAL_DEP es unitario: el depósito vale por sus unidades
    dImporteCierre := ALinea.PrecioOriginalDep;
    if ALinea.Cantidad > 0 then
      dImporteCierre := dImporteCierre * ALinea.Cantidad;
    if dImporteCierre = 0 then
      dImporteCierre := ALinea.TotalCIva;
    FPersistencia.GuardarOperacion(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'DE', -dImporteCierre, FUsuario, FFechaOperacion,
      FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
      'Cierre depósito: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', sIdDeposito);
    FPersistencia.GuardarOperacion(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'VE', ALinea.TotalCIva, FUsuario, FFechaOperacion,
      FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
      'Venta depósito: ' + ALinea.Descripcion,
      '', '', '', '', '', 'N', sIdDeposito);
  end
  else
  begin
    Result := FAlmacen;
    if ALinea.TotalCIva > 0 then
      FTotalVentasNormales :=
        FTotalVentasNormales + ALinea.TotalCIva
    else
      FTotalDevolucionesNormales :=
        FTotalDevolucionesNormales + Abs(ALinea.TotalCIva);
  end;
end;

function TGrabacionFacturaCaja.RegistrarMovimientoVenta(
  const ALinea: TDatosLineaFactura;
  const ANumeroMovimiento, AEmpresaMovimiento,
    AAlmacenOrigen, ATipoMovimiento: string): Currency;
var
  Solicitud: TSolicitudMovimientoAlmacenCaja;
begin
  Result := ObtenerCosteMedioSkuAlmacen(
    ALinea.Sku,
    AAlmacenOrigen);
  Solicitud := Default(TSolicitudMovimientoAlmacenCaja);
  Solicitud.Movimiento.Numero := ANumeroMovimiento;
  Solicitud.Movimiento.TipoDocumento := 'VE';
  Solicitud.Movimiento.SerieDocumento := FSerieGenerada;
  Solicitud.Movimiento.NumeroDocumento := FNumeroFactura;
  Solicitud.Movimiento.Linea := ALinea.Linea;
  Solicitud.Movimiento.Empresa := AEmpresaMovimiento;
  Solicitud.Movimiento.Almacen := AAlmacenOrigen;
  Solicitud.Movimiento.Unidad := ALinea.Sku;
  Solicitud.Movimiento.Articulo := ALinea.Articulo;
  Solicitud.Movimiento.TipoMovimiento := ATipoMovimiento;
  Solicitud.Movimiento.Cantidad := ALinea.Cantidad;
  Solicitud.Movimiento.CosteUnitario := Result;
  Solicitud.Movimiento.Usuario := FUsuarioSesion;
  Solicitud.Movimiento.Fecha := FFechaOperacion;
  Solicitud.CajaDocumento := FCaja;
  Solicitud.AlmacenDocumento := FAlmacen;
  Solicitud.NumeroOperacion := FNumeroOperacion;
  Solicitud.CodigoCliente := FCabecera.CodigoCliente;
  Solicitud.Lote := ALinea.Lote;
  Solicitud.FechaCaducidad := ALinea.FechaCaducidad;
  RegistrarMovimientoCreado(
    FDataModule.InsertarMovimientoAlmacen(FQuery, Solicitud));
end;

procedure TGrabacionFacturaCaja.ProcesarVenta(
  const ALinea: TDatosLineaFactura);
var
  LineaFactura: TDatosLineaFactura;
  sAlmacenOrigen: string;
  sEmpresaMovimiento: string;
  sTipoMovimiento: string;
  sNumeroMovimiento: string;
begin
  LineaFactura := ALinea;
  if (ALinea.TipoArticulo = 'ESTANDAR') and
     FGenerarMovimientos then
    sNumeroMovimiento := ObtenerSiguienteContador(
      FDataModule.FConexion, 'MV', FUsuarioSesion)
  else
    sNumeroMovimiento := '';
  sAlmacenOrigen := RegistrarOperacionVenta(ALinea);
  if ALinea.Cantidad < 0 then
    sTipoMovimiento := 'E'
  else
    sTipoMovimiento := 'S';
  // Devolución de ticket de OTRA tienda: la entrada de stock se hace en
  // el almacén de origen del ticket y luego el traspaso automático la
  // lleva al almacén actual (GenerarTraspasoAutomaticoDevolucion).
  sEmpresaMovimiento := FEmpresa;
  if (ALinea.Cantidad < 0) and
     (ALinea.TipoArticulo = 'ESTANDAR') and
     FGenerarMovimientos and
     EsDevolucionOtraTienda then
  begin
    sAlmacenOrigen := FAlmacenOrigenDevolucion;
    if Trim(FEmpresaOrigenDevolucion) <> '' then
      sEmpresaMovimiento := FEmpresaOrigenDevolucion;
    RegistrarLineaTraspasoDevolucion(LineaFactura);
  end;
  if (LineaFactura.TipoArticulo = 'ESTANDAR') and
     FGenerarMovimientos then
    LineaFactura.CosteUnitario := RegistrarMovimientoVenta(
      LineaFactura, sNumeroMovimiento, sEmpresaMovimiento,
      sAlmacenOrigen, sTipoMovimiento);
  if FRequiereFactura and ((Abs(ALinea.TotalCIva) > 0.001) or
     (ALinea.TipoArticulo = 'SERVICIO')) then
    FDataModule.InsertarLineaFactura(
      FQuery, FSerieGenerada, FNumeroFactura, LineaFactura.Linea,
      LineaFactura.Articulo, LineaFactura.Sku,
      LineaFactura.Descripcion, LineaFactura.DescripcionVariacion,
      LineaFactura.Familia, LineaFactura.NombreFamilia,
      LineaFactura.TipoArticulo, LineaFactura.TipoCantidad,
      LineaFactura.Cantidad, LineaFactura.CosteUnitario,
      LineaFactura.Tarifa, LineaFactura.EsImpIncl,
      LineaFactura.PrecioSalida, LineaFactura.PorcDto,
      LineaFactura.PrecioDto, LineaFactura.PrecioSIva,
      LineaFactura.PrecioCIva, LineaFactura.TipoIva,
      LineaFactura.PorcIva, LineaFactura.TotalSIva,
      LineaFactura.TotalCIva, LineaFactura.Vendedor,
      FEmpresa, FAlmacen,
      FCaja, FNumeroOperacion, sNumeroMovimiento, FUsuarioSesion,
      LineaFactura.Lote, LineaFactura.FechaCaducidad);
end;

procedure TGrabacionFacturaCaja.ProcesarLineas;
var
  Linea: TDatosLineaFactura;
begin
  FTotalVentasNormales := 0;
  FTotalDevolucionesNormales := 0;
  // Un reintento tras un bloqueo vuelve a recorrer las líneas.
  FServiciosDeposito := nil;
  FServiciosDesdeDeposito := nil;
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while not FDataModule.cdsLineas.Eof do
    begin
      Linea := LeerLineaActual(FDataModule.cdsLineas);
      Linea.Vendedor := Trim(Linea.Vendedor);
      if Linea.Vendedor = '' then
        Linea.Vendedor := FUsuario;
      if Linea.VieneDeDeposito = 'A' then
        ProcesarAnticipoPrevio(Linea)
      else if (Linea.AccionDeposito = 'NUEVO_DEP') or
              (Linea.AccionDeposito = 'AUMENTAR_DEP') then
        ProcesarNuevoDeposito(Linea)
      else
      begin
        ProcesarVenta(Linea);
        if Linea.VieneDeDeposito = 'S' then
          AnotarServicioDeposito(Linea, Linea.IdDeposito,
            FServiciosDesdeDeposito);
      end;
      FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
end;

procedure TGrabacionFacturaCaja.SincronizarContadorLineas;
begin
  if FRequiereFactura then
  begin
    FQuery.SQL.Text :=
      'UPDATE fza_facturas SET CONTADOR_LINEAS_FAC = (' +
      '  SELECT LPAD(IFNULL(MAX(CAST(LINEA_FACLIN AS UNSIGNED)),0),' +
      '              3,''0'') ' +
      '    FROM fza_facturas_lineas ' +
      '   WHERE NUMERO_FAC_FACLIN = :pnumfac ' +
      '     AND SERIE_FAC_FACLIN = :pserie' +
      ') WHERE NUMERO_FAC = :pnumfac AND SERIE_FAC = :pserie';
    FQuery.ParamByName('pnumfac').AsString := FNumeroFactura;
    FQuery.ParamByName('pserie').AsString := FSerieGenerada;
    FQuery.Execute;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarTotalesVenta;
var
  sSerieRefDevolucion: string;
  sNumeroRefDevolucion: string;
  bSustitutiva: Boolean;
begin
  if FRequiereFactura then
  begin
    // FZ-ISSUE-369: recargo y retención de la factura completa, para que
    // la operación lleve el líquido cobrado (arqueo, devoluciones).
    RepartirAjusteRecargoRetencion(FCabecera, FTotalVentasNormales,
      FTotalDevolucionesNormales);
    // FZ-ISSUE-379: la sustitutiva solo cobra o devuelve la diferencia
    // con la original; la operación se graba aunque sea 0 para que la
    // factura nueva tenga su operación de caja.
    bSustitutiva := FTipoRectificativa = trcSustitutiva;
    if bSustitutiva then
      NetearSustitutiva(FDatosCobro.ImporteYaCobrado, FTotalVentasNormales,
        FTotalDevolucionesNormales);
    if (FTotalVentasNormales > 0) or
       (bSustitutiva and (FTotalDevolucionesNormales = 0)) then
    begin
      if FTipoRectificativa = trcNinguna then
        FConceptoOperacion := 'Venta';
      FPersistencia.GuardarOperacion(
        FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
        'VE', FTotalVentasNormales, FUsuario, FFechaOperacion,
        FNumeroFactura, FSerieGenerada, FCabecera.CodigoCliente,
        FConceptoOperacion, FSerieRectificada, FNumeroRectificado);
    end;
    if FTotalDevolucionesNormales > 0 then
    begin
      if FTipoRectificativa = trcNinguna then
        FConceptoOperacion := 'Devolución de Venta';
      // Referencia al ticket de origen: la rectificada si la hay y,
      // si no, el origen elegido en el selector de devoluciones.
      sSerieRefDevolucion := FSerieRectificada;
      sNumeroRefDevolucion := FNumeroRectificado;
      if Trim(sSerieRefDevolucion) = '' then
      begin
        sSerieRefDevolucion := FSerieOrigenDevolucion;
        sNumeroRefDevolucion := FNumeroOrigenDevolucion;
      end;
      FPersistencia.GuardarOperacion(
        FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
        'DV', -FTotalDevolucionesNormales, FUsuario,
        FFechaOperacion, FNumeroFactura, FSerieGenerada,
        FCabecera.CodigoCliente, FConceptoOperacion,
        sSerieRefDevolucion, sNumeroRefDevolucion,
        FMotivoDevolucion);
      if (Trim(FSerieOrigenDevolucion) <> '') and
         (Trim(FNumeroOrigenDevolucion) <> '') then
        FPersistencia.AcumularDevolucionVentaOrigen(
          FQuery, FEmpresaOrigenDevolucion,
          FAlmacenOrigenDevolucion,
          FSerieOrigenDevolucion, FNumeroOrigenDevolucion,
          FTotalDevolucionesNormales);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarFiscalmente;
var
  Solicitud: TSolicitudEmisionFiscal;
begin
  if FRequiereFactura then
  begin
    if SameText(FTipoFactura, 'RECTIFICATIVA') then
    begin
      if (Trim(FSerieRectificada) = '') or
         (Trim(FNumeroRectificado) = '') then
        raise Exception.Create(
          SErrorFacturaRectificativaCajaSinOriginal);
      TVerifactuCola.EncolarRectificativa(
        FDataModule.FParametrosApp,
        FDataModule.FParametrosCaja,
        CrearServicioVerifactuColaUniDAC(FDataModule.FConexion),
        FServicioEmisionFiscal,
        FDataModule.IdentidadSesion.Usuario,
        FSerieRectificada, FNumeroRectificado,
        FSerieGenerada, FNumeroFactura,
        FTipoRectificativaFiscal,
        FTratamientoMovimientos = tmrReemplazarOriginales);
    end
    else
    begin
      Solicitud := TSolicitudEmisionFiscal.ParaAlta(
        FSerieGenerada,
        FNumeroFactura,
        FDataModule.IdentidadSesion.Usuario,
        '',
        False);
      FServicioEmisionFiscal.Emitir(Solicitud);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarFormasPago;
var
  sCodigoFormaPago: string;
  sDivisa: string;
  sRedBlockchain: string;
  sReferencia: string;
  dImporte: Double;
  dFactor: Double;
  dImporteDivisa: Double;
  dCambioPendiente, dCambio: Currency;
begin
  FNumeroLineaPago := 0;
  // El cambio calculado en el cobro se reparte entre las formas de pago que
  // lo devuelven (efectivo): así lo entregado menos el cambio es lo cobrado.
  dCambioPendiente := FDatosCobro.ImporteCambio;
  FDatosCobro.MemTablePagos.First;
  while not FDatosCobro.MemTablePagos.Eof do
  begin
    sCodigoFormaPago := FDatosCobro.MemTablePagos.FieldByName(
      'CODIGO_FP_CFP').AsString;
    dImporte := FDatosCobro.MemTablePagos.FieldByName(
      'IMPORTE_ENTREGADO').AsFloat;
    if PagoDebePersistirseCierreVenta(
         sCodigoFormaPago,
         dImporte) then
    begin
      Inc(FNumeroLineaPago);
      sDivisa := FDatosCobro.MemTablePagos.FieldByName(
        'CODIGO_DIVISA').AsString;
      sRedBlockchain := FDatosCobro.MemTablePagos.FieldByName(
        'RED_BLOCKCHAIN').AsString;
      dFactor := FDatosCobro.MemTablePagos.FieldByName(
        'FACTOR_CAMBIO').AsFloat;
      dImporteDivisa := FDatosCobro.MemTablePagos.FieldByName(
        'IMPORTE_DIVISA').AsFloat;
      sReferencia := FDatosCobro.MemTablePagos.FieldByName(
        'REFERENCIA').AsString;
      dCambio := FDatosCobro.MemTablePagos.FieldByName(
        'IMPORTE_CAMBIO').AsCurrency;
      if (dCambioPendiente > 0) and (dImporte > 0) and
         (FDatosCobro.MemTablePagos.FieldByName(
            'ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP').AsString = 'S') then
      begin
        dCambio := Min(dCambioPendiente, Currency(dImporte));
        dCambioPendiente := dCambioPendiente - dCambio;
      end;
      FPersistencia.GuardarPago(
        FQuery, FEmpresa, FAlmacen, FCaja,
        FSerieGenerada, FNumeroOperacion, FNumeroLineaPago,
        sCodigoFormaPago, dImporte, dCambio,
        sDivisa, sRedBlockchain, dFactor, dImporteDivisa, sReferencia);
    end;
    FDatosCobro.MemTablePagos.Next;
  end;
end;

procedure TGrabacionFacturaCaja.RegistrarValesRecogidos;
var
  iVale: Integer;
begin
  if FDatosCobro.ValesRecogidos <> nil then
  begin
    for iVale := 0 to FDatosCobro.ValesRecogidos.Count - 1 do
    begin
      if Abs(
        FDatosCobro.ValesRecogidos[iVale].ImporteAplicado) > 0.001 then
      begin
        Inc(FNumeroLineaPago);
        FPersistencia.GuardarPago(
          FQuery, FEmpresa, FAlmacen, FCaja,
          FSerieGenerada, FNumeroOperacion, FNumeroLineaPago,
          'VALE',
          FDatosCobro.ValesRecogidos[iVale].ImporteAplicado,
          0, '', '', 1, 0,
          FDatosCobro.ValesRecogidos[iVale].CodigoVale);
        FPersistencia.GuardarOperacion(
          FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
          'VR',
          FDatosCobro.ValesRecogidos[iVale].ImporteAplicado,
          FUsuario, FFechaOperacion, FNumeroFactura,
          FSerieGenerada, FCabecera.CodigoCliente,
          'Vale canjeado: ' +
          FDatosCobro.ValesRecogidos[iVale].CodigoVale);
        FPersistencia.MarcarValeCanjeado(
          FQuery,
          FDatosCobro.ValesRecogidos[iVale].CodigoVale,
          FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
          FSerieGenerada, FNumeroFactura,
          FDatosCobro.ValesRecogidos[iVale].ImporteAplicado);
      end;
    end;
  end;
end;

// PIN de 4 cifras que se imprime con el vale y se pide al canjearlo si
// el terminal tiene «Recuperar vale sólo con PIN» (FZ-361)
function GenerarPinVale: string;
begin
  Result := Format('%.4d', [Cardinal(TGUID.NewGuid.D1) mod 10000]);
end;

// Caducidad (0 = sin caducidad) y cliente del vale emitido. El vale que
// sale de otro (cambio de un canje parcial o devolución de lo pagado con
// vale) conserva la caducidad que fijó la emisora del padre y su cliente
// (FZ-360).
procedure TGrabacionFacturaCaja.LeerHerenciaValePadre(
  out ACaducidad: TDateTime; out ACliente: string);
var
  sClientePadre: string;
begin
  ACliente := FCabecera.CodigoCliente;
  ACaducidad := 0;
  if FDataModule.FParametrosCaja.GetBool('vgerCaducidadDefVale', False) then
    ACaducidad := FFechaOperacion +
      FDataModule.FParametrosCaja.GetInt('vgerDiasCaducidadVale', 365);
  if FDatosCobro.CodigoValePadre <> '' then
  begin
    FQuery.SQL.Text :=
      'SELECT FECHA_CADUCIDAD_VL, CODIGO_CLI_VL ' +
      '  FROM fza_caja_vales ' +
      ' WHERE CODIGO_VL = :PADRE';
    FQuery.ParamByName('PADRE').AsString := FDatosCobro.CodigoValePadre;
    FQuery.Open;
    try
      if not FQuery.IsEmpty then
      begin
        ACaducidad := 0;
        if not FQuery.FieldByName('FECHA_CADUCIDAD_VL').IsNull then
          ACaducidad :=
            FQuery.FieldByName('FECHA_CADUCIDAD_VL').AsDateTime;
        sClientePadre :=
          Trim(FQuery.FieldByName('CODIGO_CLI_VL').AsString);
        if (sClientePadre <> '') and (sClientePadre <> '0') then
          ACliente := sClientePadre;
      end;
    finally
      FQuery.Close;
    end;
  end;
end;

procedure TGrabacionFacturaCaja.EmitirVale;
var
  sCodigoVale: string;
  sCliente: string;
  dtCaducidad: TDateTime;
begin
  if FDatosCobro.ImporteValeEmitido > 0.001 then
  begin
    sCodigoVale := Format(
      'VALE_%s_%s_%s_%s',
      [FEmpresa, FAlmacen, FCaja, FNumeroOperacion]);
    LeerHerenciaValePadre(dtCaducidad, sCliente);
    FDatosCobro.PinValeEmitido := GenerarPinVale;
    FQuery.SQL.Text :=
      'INSERT INTO fza_caja_vales (' +
      '  CODIGO_VL, CODIGO_PADRE_VL, PIN_SEGURIDAD_VL, ESTADO_VL,' +
      '  IMPORTE_NOMINAL_VL,' +
      '  FECHA_EMISION_VL, FECHA_CADUCIDAD_VL,' +
      '  CODIGO_EMP_EMI_VL, CODIGO_ALM_EMI_VL,' +
      '  CODIGO_CAJA_EMI_VL, NUMERO_OPERACION_EMI_VL,' +
      '  SERIE_FAC_EMI_VL, NUMERO_FAC_EMI_VL,' +
      '  CODIGO_CLI_VL, USUARIO_ALTA, USUARIO_MODIF,' +
      '  INSTANTE_ALTA) VALUES (' +
      '  :CODIGO, NULLIF(:PADRE, ''''), :PIN, ''PENDIENTE'',' +
      '  :IMPORTE, :FEMISION,' +
      '  :FCADUCIDAD, :EMP, :ALM, :CAJA, :NUMOPE,' +
      '  :SERIE, :NUMFAC, :CLIENTE, :USUARIO,' +
      '  :USUARIO, NOW())';
    FQuery.ParamByName('CODIGO').AsString := sCodigoVale;
    FQuery.ParamByName('PADRE').AsString := FDatosCobro.CodigoValePadre;
    FQuery.ParamByName('PIN').AsString := FDatosCobro.PinValeEmitido;
    FQuery.ParamByName('IMPORTE').AsCurrency :=
      FDatosCobro.ImporteValeEmitido;
    FQuery.ParamByName('FEMISION').AsDateTime := FFechaOperacion;
    if dtCaducidad > 0 then
      FQuery.ParamByName('FCADUCIDAD').AsDateTime := dtCaducidad
    else
      FQuery.ParamByName('FCADUCIDAD').Clear;
    FQuery.ParamByName('EMP').AsString := FEmpresa;
    FQuery.ParamByName('ALM').AsString := FAlmacen;
    FQuery.ParamByName('CAJA').AsString := FCaja;
    FQuery.ParamByName('NUMOPE').AsString := FNumeroOperacion;
    FQuery.ParamByName('SERIE').AsString := FSerieGenerada;
    FQuery.ParamByName('NUMFAC').AsString := FNumeroFactura;
    FQuery.ParamByName('CLIENTE').AsString := sCliente;
    FQuery.ParamByName('USUARIO').AsString := FUsuarioSesion;
    FQuery.Execute;
    Inc(FNumeroLineaPago);
    FPersistencia.GuardarPago(
      FQuery, FEmpresa, FAlmacen, FCaja,
      FSerieGenerada, FNumeroOperacion, FNumeroLineaPago,
      'VALE', -FDatosCobro.ImporteValeEmitido, 0,
      '', '', 1, 0, sCodigoVale);
    FPersistencia.GuardarOperacion(
      FQuery, FEmpresa, FAlmacen, FCaja, FNumeroOperacion,
      'VL', -FDatosCobro.ImporteValeEmitido, FUsuario,
      FFechaOperacion, FNumeroFactura, FSerieGenerada,
      FCabecera.CodigoCliente, 'Vale emitido: ' + sCodigoVale);
    FValeGenerado := sCodigoVale;
  end;
end;

function TGrabacionFacturaCaja.HayDepositosPendientes: Boolean;
var
  sAccion: string;
begin
  Result := False;
  FDataModule.cdsLineas.First;
  while (not FDataModule.cdsLineas.Eof) and (not Result) do
  begin
    sAccion := FDataModule.cdsLineas.FieldByName(
      'ACCION_DEPOSITO').AsString;
    Result :=
      (sAccion = 'NUEVO_DEP') or
      (sAccion = 'AUMENTAR_DEP') or
      (sAccion = 'CANCELAR');
    if not Result then
      FDataModule.cdsLineas.Next;
  end;
end;

procedure TGrabacionFacturaCaja.ConfirmarTransaccion;
begin
  FPersistencia.ConfirmarUnidadTrabajo;
end;

procedure TGrabacionFacturaCaja.ImprimirDocumentosDeposito;
begin
  if HayDepositosPendientes and (FNumeroOperacion <> '') then
  begin
    ImprimirResguardoDeposito(
      FDataModule.FPreviewTicket,
      FDataModule.FRepositorioTicketsCaja.Resguardos,
      FEmpresa,
      FAlmacen,
      FCaja,
      FNumeroOperacion,
      FDataModule.FParametrosCaja.ImpresoraCaja,
      nil,
      False,
      FDataModule.FParametrosCaja.GetBool(
        'vgerImprimirCodBarrasTicket', False));
    if not FDatosCobro.EsClienteVarios then
      ImprimirRecordatorio(
        FDataModule.FPreviewTicket,
        FDataModule.FRepositorioTicketsCaja.Recordatorios,
        FDataModule.FContextoSesion.Ubicacion.Empresa,
        FCabecera.CodigoCliente,
        FDataModule.FParametrosCaja.ImpresoraCaja);
  end;
end;

procedure TGrabacionFacturaCaja.LimpiarLineasSinImporte;
begin
  FDataModule.cdsLineas.DisableControls;
  try
    FDataModule.cdsLineas.First;
    while not FDataModule.cdsLineas.Eof do
    begin
      if Abs(FDataModule.cdsLineas.FieldByName(
        'TOTAL_FACLIN').AsCurrency) < 0.001 then
        FDataModule.cdsLineas.Delete
      else
        FDataModule.cdsLineas.Next;
    end;
  finally
    FDataModule.cdsLineas.EnableControls;
  end;
end;

procedure TGrabacionFacturaCaja.AnyadirAvisoTrasGrabacion(
  const AAviso: string);
begin
  if FDataModule.FAvisoTrasGrabacion <> '' then
    FDataModule.FAvisoTrasGrabacion :=
      FDataModule.FAvisoTrasGrabacion + sLineBreak;
  FDataModule.FAvisoTrasGrabacion :=
    FDataModule.FAvisoTrasGrabacion + AAviso;
end;

// La venta ya está confirmada: un fallo aquí no puede revertirla ni darla
// por no grabada (se volvería a cobrar con F12). Solo se avisa.
procedure TGrabacionFacturaCaja.AtenderTareasTrasConfirmar;
begin
  try
    if FGenerarMovimientos then
      SolicitarProcesadoPrestaShop;
  except
    on E: Exception do
      AnyadirAvisoTrasGrabacion(E.Message);
  end;
  try
    ImprimirDocumentosDeposito;
  except
    on E: Exception do
      AnyadirAvisoTrasGrabacion(
        Format(SAvisoImpresionDepositoCaja, [E.Message]));
  end;
  try
    LimpiarLineasSinImporte;
  except
    on E: Exception do
      AnyadirAvisoTrasGrabacion(
        Format(SAvisoLimpiezaLineasCaja, [E.Message]));
  end;
end;

procedure TGrabacionFacturaCaja.RevertirTransaccion;
begin
  FPersistencia.RevertirUnidadTrabajo;
end;

procedure TGrabacionFacturaCaja.RegistrarMovimientoCreado(
  const ANumeroMovimiento: string);
var
  Indice: Integer;
begin
  if Trim(ANumeroMovimiento) = '' then
    raise EArgumentException.Create('ANumeroMovimiento');
  Indice := Length(FNumerosMovimientos);
  SetLength(FNumerosMovimientos, Indice + 1);
  FNumerosMovimientos[Indice] := ANumeroMovimiento;
end;

procedure TGrabacionFacturaCaja.ProcesarRecalculoMovimientos;
var
  Aplazar: Boolean;
  Encolado: Boolean;
  RequiereRecalculo: Boolean;
  sUsuario: string;
begin
  if FGenerarMovimientos and (Trim(FNumeroOperacion) <> '') then
  begin
    Aplazar := FDataModule.FParametrosCaja.GetBool(
      'vgerAplazarRecalculoMovimientos', False);
    if Aplazar then
    begin
      RequiereRecalculo := MovimientosCajaRequierenRecalculo(
        FDataModule.FConexion, FEmpresa, FAlmacen, FCaja,
        FNumeroOperacion, FNumerosMovimientos);
      if RequiereRecalculo then
      begin
        sUsuario := FDataModule.IdentidadSesion.Usuario;
        if Trim(sUsuario) = '' then
          sUsuario := FUsuario;
        Encolado := EncolarMovimientosRecalculo(
          FDataModule.FConexion,
          FNumerosMovimientos,
          'CAJA_RECALCULO_DETECTADO',
          sUsuario);
        if not Encolado then
        begin
          RecalcularMovimientosOperacion(
            FDataModule.FConexion, FAlmacen, FCaja, FNumeroOperacion);
        end;
      end;
    end
    else
    begin
      RecalcularMovimientosOperacion(
        FDataModule.FConexion, FAlmacen, FCaja, FNumeroOperacion);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.RevertirTrasError(
  E: Exception; AConfirmando: Boolean);
begin
  FDataModule.FRegistroLog.RegistrarError(
    'Fallo al grabar la venta: ' + E.ClassName + ': ' + E.Message);
  if E is EConexionPerdidaBBDD then
  begin
    EConexionPerdidaBBDD(E).ConfirmacionIncierta := AConfirmando;
    // La sesión se descarta fuera de la transacción. No se envía
    // ROLLBACK a una conexión rota ni se repite una sentencia suelta.
  end
  else
  try
    RevertirTransaccion;
  except
    on ErrorRollback: Exception do
    begin
      FDataModule.FRegistroLog.RegistrarError(
        'Fallo al revertir la venta: ' + ErrorRollback.Message);
      raise EGrabacionVentaCaja.Create(
        SErrorConfirmacionVentaCaja, False);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.CrearOrdenesReparacion;
var
  Venta: TVentaServiciosReparacion;
  oReparaciones: TReparacionesVentaTpv;
begin
  if FRequiereFactura and (FTipoRectificativa = trcNinguna) then
  begin
    Venta := Default(TVentaServiciosReparacion);
    Venta.Serie := FSerieGenerada;
    Venta.Numero := FNumeroFactura;
    Venta.Empresa := FEmpresa;
    Venta.Almacen := FAlmacen;
    Venta.Usuario := FUsuarioSesion;
    Venta.Fecha := FFechaOperacion;
    Venta.Prendas := FDatosCobro.PrendasReparacion;
    Venta.Cliente := FCabecera.CodigoCliente;
    Venta.NombreCliente := FCabecera.RazonSocialCli;
    Venta.Telefono := FCabecera.MovilCli;
    Venta.Email := FCabecera.EmailCli;
    if Trim(FDatosCobro.NombreReparacion) <> '' then
    begin
      Venta.NombreCliente := FDatosCobro.NombreReparacion;
      Venta.Telefono := FDatosCobro.TelefonoReparacion;
      Venta.Email := FDatosCobro.EmailReparacion;
    end;
    Venta.Cobrada := FDatosCobro.ImporteDejarCuenta < 0.001;
    oReparaciones := TReparacionesVentaTpv.Create(FDataModule.FConexion);
    try
      oReparaciones.EnlazarOrdenesDepositos(Venta, FServiciosDesdeDeposito);
      oReparaciones.CrearOrdenes(Venta);
      oReparaciones.CrearOrdenesDepositos(Venta, FServiciosDeposito);
    finally
      FreeAndNil(oReparaciones);
    end;
  end;
end;

procedure TGrabacionFacturaCaja.EjecutarTransaccion;
var
  bConfirmando: Boolean;
begin
  bConfirmando := False;
  try
    IniciarTransaccion;
    if FPresupuestoNumero <> '' then
      FPersistencia.BloquearPresupuesto(FPresupuestoEmpresa,
        FPresupuestoSerie, FPresupuestoNumero);
    if FGenerarMovimientos and
       FDataModule.FParametrosCaja.GetBool('vgerChkStockOnly', False) then
      ValidarStockCobroCaja(FDataModule.FConexion,
        FDataModule.cdsLineas, FAlmacen);
    CrearFacturaSiProcede;
    ProcesarLineas;
    SincronizarContadorLineas;
    RegistrarTotalesVenta;
    GenerarTraspasoAutomaticoDevolucion;
    ProcesarRecalculoMovimientos;
    CrearOrdenesReparacion;
    if FPresupuestoNumero <> '' then
      FPersistencia.EnlazarPresupuesto(FPresupuestoEmpresa,
        FPresupuestoSerie, FPresupuestoNumero,
        FSerieGenerada, FNumeroFactura);
    RegistrarFiscalmente;
    RegistrarFormasPago;
    RegistrarValesRecogidos;
    EmitirVale;
    bConfirmando := True;
    ConfirmarTransaccion;
  except
    on E: Exception do
    begin
      RevertirTrasError(E, bConfirmando);
      if (E is EConexionPerdidaBBDD) or (E is EBloqueoBBDDTemporal) then
        raise;
      if (E is EErrorBBDD) or (E is EValidacionBBDD) or
         (E is EDAError) then
        raise EGrabacionVentaCaja.Create(
          Format(SErrorGuardarTicketCaja, [E.Message]));
      raise;
    end;
  end;
end;

function TGrabacionFacturaCaja.Ejecutar(
  out ANumeroGenerado, AValeGenerado: string): Boolean;
begin
  ANumeroGenerado := '';
  AValeGenerado := '';
  CargarContexto;
  if OperacionTieneNovedad then
  begin
    DeterminarSiRequiereFactura;
    ValidarSolicitud;
    if (FPresupuestoNumero <> '') and
       ((not FRequiereFactura) or
        (FDatosCobro.ImporteDejarCuenta > 0.001) or
        (FDatosCobro.ImporteEntregado + FDatosCobro.ImporteYaCobrado <
         FDataModule.cdsCabecera.FieldByName(
           'TOTAL_LIQUIDO_FAC').AsCurrency - 0.001)) then
      raise EValidacionBBDD.Create(SErrorPresupuestoCajaCobroCompleto);
    AjustarCobroParcial;
    // Sin entrega (venta a credito, F7) las prendas pasan a deposito con
    // importe 0: ya no hay nada que facturar ni ticket que imprimir.
    DeterminarSiRequiereFactura;
    if FRequiereFactura and Assigned(FDataModule.FConfirmarContador) then
      PrepararNumeracionDocumento(FDataModule.FConexion, dnFactura,
        FEmpresa, FSerieGenerada, FUsuario, FNumeroManual,
        FDataModule.FRegistroLog, FDataModule.FConfirmarContador);
    EjecutarTransaccion;
    if FRequiereFactura then
    begin
      FDataModule.FUltSerieFacGrabada := FSerieGenerada;
      FDataModule.FUltNumeroFacGrabada := FNumeroFactura;
    end;
    Result := True;
    AtenderTareasTrasConfirmar;
  end
  else
  begin
    AtenderOperacionSinNovedad;
    Result := True;
  end;
  ANumeroGenerado := FNumeroOperacion;
  AValeGenerado := FValeGenerado;
end;

function TGrabacionFacturaCaja.EsDevolucionOtraTienda: Boolean;
begin
  Result :=
    (Trim(FAlmacenOrigenDevolucion) <> '') and
    (not SameText(FAlmacenOrigenDevolucion, FAlmacen));
end;

procedure TGrabacionFacturaCaja.GenerarCodigoBarrasTicket;
const
  cPrefijoTicket = '29';
  cDigitosContador = 10;
var
  sContador: string;
  sBase: string;
begin
  // EAN-13 del ticket: prefijo 29 (uso interno de tienda) + contador
  // global 'TK' de 10 dígitos + dígito de control. Mismo patrón que los
  // códigos de artículo (prefijo 21, contador 'BA'). Si la columna aún
  // no existe (script codigo_barras_ticket.sql sin aplicar), se omite.
  FQuery.SQL.Text :=
    'SELECT COUNT(*) AS N ' +
    '  FROM INFORMATION_SCHEMA.COLUMNS ' +
    ' WHERE TABLE_SCHEMA = DATABASE() ' +
    '   AND TABLE_NAME = ''fza_facturas'' ' +
    '   AND COLUMN_NAME = ''CODIGO_BARRAS_FAC''';
  FQuery.Open;
  if FQuery.FieldByName('N').AsInteger > 0 then
  begin
    FQuery.Close;
    sContador := ObtenerSiguienteContador(
      FDataModule.FConexion, 'TK', FUsuarioSesion);
    if Length(sContador) > cDigitosContador then
      sContador := Copy(
        sContador,
        Length(sContador) - cDigitosContador + 1,
        cDigitosContador)
    else
      sContador := StringOfChar(
        '0', cDigitosContador - Length(sContador)) + sContador;
    sBase := cPrefijoTicket + sContador;
    FQuery.SQL.Text :=
      'UPDATE fza_facturas ' +
      '   SET CODIGO_BARRAS_FAC = :CODIGO ' +
      ' WHERE SERIE_FAC = :SERIE ' +
      '   AND NUMERO_FAC = :NUMERO';
    FQuery.ParamByName('CODIGO').AsString :=
      sBase + CalcularDigitoEAN13(sBase);
    FQuery.ParamByName('SERIE').AsString := FSerieGenerada;
    FQuery.ParamByName('NUMERO').AsString := FNumeroFactura;
    FQuery.Execute;
  end
  else
    FQuery.Close;
end;

procedure TGrabacionFacturaCaja.RegistrarLineaTraspasoDevolucion(
  const ALinea: TDatosLineaFactura);
var
  iIndice: Integer;
begin
  iIndice := Length(FLineasTraspasoDev);
  SetLength(FLineasTraspasoDev, iIndice + 1);
  FLineasTraspasoDev[iIndice].Sku := ALinea.Sku;
  FLineasTraspasoDev[iIndice].Articulo := ALinea.Articulo;
  FLineasTraspasoDev[iIndice].Cantidad := Abs(ALinea.Cantidad);
  FLineasTraspasoDev[iIndice].Lote := ALinea.Lote;
  FLineasTraspasoDev[iIndice].FechaCaducidad := ALinea.FechaCaducidad;
end;

function TGrabacionFacturaCaja.ObtenerSerieDocumentoTraspaso(
  const AEmpresa, AAlmacen, ATipoDoc: string): string;
var
  Qry: TUniQuery;
begin
  // Serie configurada para el tipo de documento (prefiere la de la
  // caja / almacén); fallback: el propio tipo de documento. Misma
  // consulta que el traspaso manual: nunca una serie que la empresa
  // use en facturas (FZ-ISSUE-332, FZ-ISSUE-427).
  Result := ATipoDoc;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FDataModule.FConexion;
    Qry.SQL.Text := SqlSerieDocumentoTraspaso;
    Qry.ParamByName('EMP').AsString := AEmpresa;
    Qry.ParamByName('TIPO').AsString := ATipoDoc;
    Qry.ParamByName('ALM').AsString := AAlmacen;
    Qry.ParamByName('CAJA').AsString := FCaja;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('EMPSER').AsString;
  finally
    FreeAndNil(Qry);
  end;
end;

function TGrabacionFacturaCaja.ObtenerCosteMedioSkuAlmacen(
  const ASku, AAlmacen: string): Currency;
var
  Qry: TUniQuery;
begin
  // Sin existencias, stockactual puede tener PMP cero. El último
  // movimiento activo conserva el PMP, incluso si su coste real es cero.
  // Sin historial retenido se respeta el PMP guardado en stockactual.
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := FDataModule.FConexion;
    Qry.SQL.Text :=
      'SELECT CASE WHEN SUM(CANTIDAD_STK) > 0' +
      '            THEN SUM(PRECIO_MEDIO_STK * CANTIDAD_STK)' +
      '                 / SUM(CANTIDAD_STK)' +
      '            ELSE COALESCE((' +
      '              SELECT PRECIO_MEDIO_MOV' +
      '                FROM fza_movimientos_almacen' +
      '               WHERE CODIGO_ALM_MOV = :ALM' +
      '                 AND CODIGO_UNIDAD_MOV = :SKU' +
      '                 AND ESACTIVO_MOV = ''S''' +
      '               ORDER BY FECHA_MOV DESC, INSTANTE_ALTA DESC,' +
      '                        NUMERO_MOV DESC LIMIT 1),' +
      '              MAX(PRECIO_MEDIO_STK), 0) END AS PMP ' +
      '  FROM fza_articulos_stockactual ' +
      ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
    Qry.ParamByName('ALM').AsString := AAlmacen;
    Qry.ParamByName('SKU').AsString := ASku;
    Qry.Open;
    Result := Qry.FieldByName('PMP').AsCurrency;
  finally
    FreeAndNil(Qry);
  end;
end;

function TGrabacionFacturaCaja.RegistrarLineasTraspasoDevolucion(
  const AEmpresaOrigen, ATipoDocumento, ASerieDocumento,
    ANumeroDocumento, ANumeroOperacion: string): Currency;
var
  Coste: Currency;
  Indice: Integer;
  LineaDocumento: Integer;
  NumeroLinea: string;
  SolicitudMovimiento: TSolicitudMovimientoAlmacenCaja;
begin
  Result := 0;
  LineaDocumento := 0;
  for Indice := 0 to High(FLineasTraspasoDev) do
  begin
    LineaDocumento := LineaDocumento + 10;
    NumeroLinea := Format('%.4d', [LineaDocumento]);
    Coste := ObtenerCosteMedioSkuAlmacen(
      FLineasTraspasoDev[Indice].Sku, FAlmacenOrigenDevolucion);
    // Salida del almacén de origen del ticket hacia el actual
    SolicitudMovimiento := Default(TSolicitudMovimientoAlmacenCaja);
    SolicitudMovimiento.Movimiento.TipoDocumento := ATipoDocumento;
    SolicitudMovimiento.Movimiento.SerieDocumento := ASerieDocumento;
    SolicitudMovimiento.Movimiento.NumeroDocumento := ANumeroDocumento;
    SolicitudMovimiento.Movimiento.Linea := NumeroLinea;
    SolicitudMovimiento.Movimiento.Empresa := AEmpresaOrigen;
    SolicitudMovimiento.Movimiento.Almacen := FAlmacenOrigenDevolucion;
    SolicitudMovimiento.Movimiento.AlmacenContrapartida := FAlmacen;
    SolicitudMovimiento.Movimiento.Unidad :=
      FLineasTraspasoDev[Indice].Sku;
    SolicitudMovimiento.Movimiento.Articulo :=
      FLineasTraspasoDev[Indice].Articulo;
    SolicitudMovimiento.Movimiento.TipoMovimiento := 'S';
    SolicitudMovimiento.Movimiento.Cantidad :=
      FLineasTraspasoDev[Indice].Cantidad;
    SolicitudMovimiento.Lote := FLineasTraspasoDev[Indice].Lote;
    SolicitudMovimiento.FechaCaducidad :=
      FLineasTraspasoDev[Indice].FechaCaducidad;
    SolicitudMovimiento.Movimiento.CosteUnitario := Coste;
    SolicitudMovimiento.Movimiento.Usuario := FUsuarioSesion;
    SolicitudMovimiento.Movimiento.Fecha := FFechaOperacion;
    SolicitudMovimiento.CajaDocumento := FCaja;
    SolicitudMovimiento.AlmacenDocumento := FAlmacenOrigenDevolucion;
    SolicitudMovimiento.NumeroOperacion := ANumeroOperacion;
    FDataModule.InsertarMovimientoAlmacen(FQuery, SolicitudMovimiento);
    // Entrada en el almacén donde se hace la devolución
    SolicitudMovimiento := Default(TSolicitudMovimientoAlmacenCaja);
    SolicitudMovimiento.Movimiento.TipoDocumento := ATipoDocumento;
    SolicitudMovimiento.Movimiento.SerieDocumento := ASerieDocumento;
    SolicitudMovimiento.Movimiento.NumeroDocumento := ANumeroDocumento;
    SolicitudMovimiento.Movimiento.Linea := NumeroLinea;
    SolicitudMovimiento.Movimiento.Empresa := FEmpresa;
    SolicitudMovimiento.Movimiento.Almacen := FAlmacen;
    SolicitudMovimiento.Movimiento.AlmacenContrapartida :=
      FAlmacenOrigenDevolucion;
    SolicitudMovimiento.Movimiento.Unidad :=
      FLineasTraspasoDev[Indice].Sku;
    SolicitudMovimiento.Movimiento.Articulo :=
      FLineasTraspasoDev[Indice].Articulo;
    SolicitudMovimiento.Movimiento.TipoMovimiento := 'E';
    SolicitudMovimiento.Movimiento.Cantidad :=
      FLineasTraspasoDev[Indice].Cantidad;
    SolicitudMovimiento.Lote := FLineasTraspasoDev[Indice].Lote;
    SolicitudMovimiento.FechaCaducidad :=
      FLineasTraspasoDev[Indice].FechaCaducidad;
    SolicitudMovimiento.Movimiento.CosteUnitario := Coste;
    SolicitudMovimiento.Movimiento.Usuario := FUsuarioSesion;
    SolicitudMovimiento.Movimiento.Fecha := FFechaOperacion;
    SolicitudMovimiento.CajaDocumento := FCaja;
    SolicitudMovimiento.AlmacenDocumento := FAlmacenOrigenDevolucion;
    SolicitudMovimiento.NumeroOperacion := ANumeroOperacion;
    FDataModule.InsertarMovimientoAlmacen(FQuery, SolicitudMovimiento);
    Result := Result + Coste * FLineasTraspasoDev[Indice].Cantidad;
  end;
end;

procedure TGrabacionFacturaCaja.GenerarTraspasoAutomaticoDevolucion;
var
  oStoredProc: TUniStoredProc;
  sTipoDoc, sSerieDoc: string;
  sNumeroDoc: string;
  sNumOperacion: string;
  sEmpresaOrigen: string;
  sEmpContra: string;
  cTotal: Currency;
begin
  // Devolución de un ticket de OTRA tienda: la entrada de la devolución
  // se hizo en el almacén de origen (ProcesarVenta) y aquí se genera el
  // traspaso automático origen -> almacén actual, dentro de la misma
  // transacción, para que el stock quede donde está físicamente.
  if (Length(FLineasTraspasoDev) > 0) and EsDevolucionOtraTienda then
  begin
    sEmpresaOrigen := Trim(FEmpresaOrigenDevolucion);
    if sEmpresaOrigen = '' then
      sEmpresaOrigen := FEmpresa;
    // TR = misma empresa; TA = entre empresas distintas
    if SameText(sEmpresaOrigen, FEmpresa) then
    begin
      sTipoDoc := 'TR';
      sEmpContra := '';
    end
    else
    begin
      sTipoDoc := 'TA';
      sEmpContra := FEmpresa;
    end;
    sSerieDoc := ObtenerSerieDocumentoTraspaso(
      sEmpresaOrigen, FAlmacenOrigenDevolucion, sTipoDoc);
    oStoredProc := TUniStoredProc.Create(nil);
    try
      oStoredProc.Connection := FDataModule.FConexion;
      oStoredProc.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
      oStoredProc.Prepare;
      oStoredProc.ParamByName('pserie').AsString := sSerieDoc;
      oStoredProc.ParamByName('pTipoDoc').AsString := sTipoDoc;
      oStoredProc.ParamByName(
        'pEMPRESA_CONTADOR').AsString := sEmpresaOrigen;
      oStoredProc.ParamByName('pUSUARIOMODIF').AsString :=
        FUsuarioSesion;
      oStoredProc.Execute;
      sNumeroDoc := oStoredProc.ParamByName('pcont').AsString;
    finally
      FreeAndNil(oStoredProc);
    end;
    sNumOperacion := FPersistencia.SiguienteOperacion(
      sEmpresaOrigen, FAlmacenOrigenDevolucion, FCaja, FUsuario);
    cTotal := RegistrarLineasTraspasoDevolucion(
      sEmpresaOrigen, sTipoDoc, sSerieDoc, sNumeroDoc,
      sNumOperacion);
    RecalcularMovimientosDocumento(FDataModule.FConexion, sTipoDoc,
      sSerieDoc, sNumeroDoc);
    // Operación del traspaso: registrada en el origen con contra el
    // almacén actual (misma convención que el traspaso manual F3)
    FPersistencia.GuardarOperacion(
      FQuery, sEmpresaOrigen, FAlmacenOrigenDevolucion, FCaja,
      sNumOperacion, sTipoDoc, cTotal, FUsuario, FFechaOperacion,
      sNumeroDoc, sSerieDoc, '',
      'Traspaso automático por devolución a ' + FAlmacen,
      FSerieOrigenDevolucion, FNumeroOrigenDevolucion, '',
      sEmpContra, FAlmacen, 'S');
  end;
end;

function TdmCajaOpe.GrabarFacturaSimplificada(
  const AEmpresa, AAlmacen, ACaja, ASerieElegida: string;
  DatosCobro: TDatosFaseCobro;
  SerieGenerada: string;
  out NumeroGenerado: string;
  out ValeGenerado: string;
  const ATipoFactura: string = 'SIMPLIFICADA';
  AFechaFactura: TDateTime = 0;
  AFechaOperacion: TDateTime = 0;
  const ANumeroManual: string = '';
  ATipoRectificativa:
    TTipoRectificativaCaja = trcNinguna;
  const ASerieRectificada: string = '';
  const ANumeroRectificado: string = '';
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa =
      tmrMantenerOriginales;
  const AMotivoDevolucion: string = '';
  const ASerieOrigenDevolucion: string = '';
  const ANumeroOrigenDevolucion: string = '';
  const AEmpresaOrigenDevolucion: string = '';
  const AAlmacenOrigenDevolucion: string = '';
  const AArqueosConfirmados: TArray<string> = nil;
  const APresupuestoEmpresa: string = '';
  const APresupuestoSerie: string = '';
  const APresupuestoNumero: string = ''): Boolean;
var
  Grabacion: TGrabacionFacturaCaja;
begin
  Grabacion := TGrabacionFacturaCaja.Create(
    Self, DatosCobro, AEmpresa, AAlmacen, ACaja,
    ASerieElegida, SerieGenerada, ATipoFactura,
    AFechaFactura, AFechaOperacion, ANumeroManual,
    ATipoRectificativa, ASerieRectificada,
    ANumeroRectificado, ATratamientoMovimientos,
    AMotivoDevolucion, ASerieOrigenDevolucion,
    ANumeroOrigenDevolucion, AEmpresaOrigenDevolucion,
    AAlmacenOrigenDevolucion, AArqueosConfirmados,
    APresupuestoEmpresa, APresupuestoSerie, APresupuestoNumero);
  try
    Result := Grabacion.Ejecutar(
      NumeroGenerado, ValeGenerado);
  finally
    FreeAndNil(Grabacion);
  end;
end;

// =============================================================================
// ALTER TABLE — actualizar el COMMENT del campo con todos los tipos vigentes
// Ejecutar en la BD una sola vez.
// =============================================================================
//
// ALTER TABLE fza_caja_operaciones
//   MODIFY COLUMN `TIPO_OPERACION_OPCAJA` varchar(2)
//     CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NOT NULL
// COMMENT 'VE=Venta, DE=Nuevo depósito, CB=Cobro a cuenta, DV=Devolución
// anticipo, VL=Vale emitido, VR=Vale recogido, AL=Albarán, EC=Entrada efectivo,
// GC=Gasto efectivo, TR=Traspaso almacén, AT=Traspaso empresa';

function TdmCajaOpe.CuadrarFacturaEnMemoria(dsCabecera,
                                            dsLineas: TDataSet): Boolean;
var
  CalculadorFiscal: TFacturaTotales;
begin
  // Instanciamos tu clase pasándole los datasets de la caja
  CalculadorFiscal := TFacturaTotales.Create(
    FConexion,
    CrearRepositorioLecturasFacturaUniDAC(FConexion),
    dsCabecera,
    dsLineas);
  try
    // ProcesarFacturaCompleta se encarga de leer configuración, recorrer líneas
    // y sumarizar
    Result := CalculadorFiscal.ProcesarFacturaCompleta;
    if not Result then
      raise Exception.CreateFmt(SErrorCuadrarFacturaCaja,
                                [CalculadorFiscal.MensajeError]);
  finally
    FreeAndNil(CalculadorFiscal);
  end;
end;

function TdmCajaOpe.BuscarYMostrarNombre(TipoEntidad, Codigo: string;
                                         var LabelDestino: String): Boolean;
var
  unqry: TUniQuery;
  FieldToGet: string;
  SQLStr: string;
begin
  LabelDestino := '';
  Result := False;
  if Trim(Codigo) <> '' then
  begin
    SQLStr := '';
    if TipoEntidad = 'EMPLEADOS' then
    begin
      SQLStr := 'SELECT DIMINUTIVO_TICKET_EMPL ' +
                '  FROM fza_empleados ' +
                ' WHERE CODIGO_EMPL = :COD';
      FieldToGet := 'DIMINUTIVO_TICKET_EMPL';
    end
    else if TipoEntidad = 'CLIENTES' then
    begin
      SQLStr := 'SELECT RAZON_SOCIAL_CLI ' +
                '  FROM fza_clientes ' +
                ' WHERE CODIGO_CLI_CLI = :COD';
      FieldToGet := 'RAZON_SOCIAL_CLI';
    end;
    if SQLStr <> '' then
    begin
      unqry := TUniQuery.Create(nil);
      try
        unqry.Connection := FConexion;
        unqry.SQL.Text := SQLStr;
        unqry.ParamByName('COD').AsString := Codigo;
        unqry.Open;
        if not unqry.IsEmpty then
        begin
          LabelDestino := unqry.FieldByName(FieldToGet).AsString;
          Result := True;
        end;
      finally
        FreeAndNil(unqry);
      end;
    end;
  end;
end;

function TdmCajaOpe.GenerarSkuFinal(ArticuloBase: string): string;
var
  i: Integer;
  ValorAttr: string;
  SkuBuilder: string;
  NumAttr:Integer;
begin
  NumAttr := cdsLineas.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  SkuBuilder := ArticuloBase;
  for i := 1 to NumAttr do
  begin
    ValorAttr := cdsLineas.FieldByName('ATTR' + IntToStr(i) +
                                                           '_VALOR').AsString;
    if ValorAttr <> '' then
       SkuBuilder := SkuBuilder + '/' + ValorAttr;
  end;
  Result := SkuBuilder;
end;

function TdmCajaOpe.TarifaInicialCliente(const ATarifa: string): string;
begin
  Result := TarifaClienteConPeriodicidad(ATarifa,
    FParametrosCaja.TarifaDefecto, GetTarifaDefault);
end;

function TdmCajaOpe.TarifaRespaldo(const ATarifa: string): string;
begin
  Result := Trim(FParametrosCaja.TarifaDefecto);
  if SameText(Result, Trim(ATarifa)) then
    Result := '';
end;

function TdmCajaOpe.EsTarifaPeriodicaAutomatica(
  const ATarifa: string): Boolean;
var
  Periodica: string;
begin
  Periodica := Trim(FParametrosCaja.GetString(
    'vgerTarifaPeriodicaAutomatica', ''));
  Result := (Periodica <> '') and SameText(Periodica, Trim(ATarifa));
end;

function TdmCajaOpe.GetTarifaDefault: string;
var
  Promocional: string;
  Periodicidad: IRepositorioPeriodicidadTarifa;
  Fecha: TDateTime;
begin
  Result := FParametrosCaja.TarifaDefecto;
  Promocional := Trim(FParametrosCaja.GetString(
    'vgerTarifaPeriodicaAutomatica', ''));
  if Promocional <> '' then
  begin
    Fecha := Date;
    if cdsCabecera.Active and not cdsCabecera.IsEmpty then
      Fecha := cdsCabecera.FieldByName('FECHA_FAC').AsDateTime;
    Periodicidad := CrearRepositorioPeriodicidadTarifa(FConexion);
    Result := TarifaInicialConPeriodicidad(Result, Promocional,
      Periodicidad, Fecha);
  end;
end;

procedure TdmCajaOpe.cdsCabeceraAfterInsert(DataSet: TDataSet);
begin
  AplicarValoresPorDefecto(FConexion, cdsCabecera, 'fza_facturas');
  cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString := '0';
  cdsCabecera.FieldByName('SERIE_FAC').AsString := '0';
  cdsCabecera.FieldByName('TIPO_FAC').AsString := 'SIMPLIFICADA';
end;

procedure TdmCajaOpe.cdsLineasAfterDelete(DataSet: TDataSet);
begin
  if not DataSet.ControlsDisabled then
  begin
    if Assigned(FOnRecalcularLineas) then
      FOnRecalcularLineas;
  end;
end;

procedure TdmCajaOpe.cdsLineasAfterInsert(DataSet: TDataSet);
var
  NuevoNumero: Integer;
begin
  if not DataSet.ControlsDisabled then
    AplicarValoresPorDefecto(
      FConexion,
      cdsLineas,
      'fza_facturas_lineas');
  cdsLineas.FieldByName('SERIE_FAC_FACLIN').AsString := '0';
  cdsLineas.FieldByName('NUMERO_FAC_FACLIN').AsString := '0';
  NuevoNumero :=
    cdsCabecera.FieldByName('CONTADOR_LINEAS_FAC').AsInteger + 10;
  cdsCabecera.Edit;
  cdsCabecera.FieldByName('CONTADOR_LINEAS_FAC').AsInteger :=
    NuevoNumero;
  cdsLineas.FieldByName('LINEA_FACLIN').AsString :=
    Format('%.4d', [NuevoNumero]);
  cdsLineas.FieldByName('CODIGO_VENDEDOR_FACLIN').AsString :=
    cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
  cdsLineas.FindField('PORCENTAJE_IVA_FACLIN').AsCurrency :=
    GetTipoIVA(
      cdsLineas.FieldByName('TIPO_IVA_ARTICULO_FACLIN').AsString);
end;

function TdmCajaOpe.GetTipoIVA(sTipoIVA: string): Currency;
var
  fPorcen:Currency;
begin
  case IndexStr(sTipoIVA, ['N', 'R', 'S', 'E']) of
    0: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAN_FAC').AsCurrency;
    1: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAR_FAC').AsCurrency;
    2: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAS_FAC').AsCurrency;
    3: fPorcen := cdsCabecera.FindField(
      'PORCENTAJE_IVAE_FAC').AsCurrency;
    else
    begin
      fPorcen := cdsCabecera.FindField(
        'PORCENTAJE_IVAN_FAC').AsCurrency;
      cdsLineas.FindField('TIPO_IVA_ARTICULO_FACLIN').AsString := 'N';
    end;
  end;
  Result := fPorcen;
end;

procedure TdmCajaOpe.cdsLineasAfterPost(DataSet: TDataSet);
begin
if not DataSet.ControlsDisabled then
  begin
    // 1. Desenganchamos el evento para evitar el bucle infinito
    cdsLineas.AfterPost := nil;
    try
      if Assigned(FOnRecalcularLineas) then
        FOnRecalcularLineas;
    finally
      // 2. Lo volvemos a enganchar al terminar
      cdsLineas.AfterPost := cdsLineasAfterPost;
    end;
  end;
end;

// El cambio de fila se valida en CanFocusRecord. BeforeScroll también
// se dispara al cancelar o borrar, acciones que deben seguir permitidas.
procedure TdmCajaOpe.cdsLineasBeforeInsert(DataSet: TDataSet);
var
  Pendiente: Integer;
begin
  if not DataSet.ControlsDisabled then
  begin
    Pendiente := PrimerAtributoPendienteLineaCaja(DataSet);
    if Pendiente > 0 then
    begin
      if Assigned(FOnAtributoPendiente) then
        FOnAtributoPendiente(Pendiente);
      Abort;
    end;
  end;
end;

procedure TdmCajaOpe.cdsLineasBeforePost(DataSet: TDataSet);
var
  Requeridos, Resueltos, Pendiente: Integer;
begin
  if DataSet.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString = '' then
    Abort;
  Pendiente := PrimerAtributoPendienteLineaCaja(DataSet);
  Requeridos :=
    DataSet.FieldByName('NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
  Resueltos := AtributosResueltosSkuCaja(Trim(
    DataSet.FieldByName('CODIGO_UNIDAD_FACLIN').AsString));
  if (Pendiente = 0) and (Resueltos < Requeridos) then
    Pendiente := Resueltos + 1;
  if Pendiente > 0 then
  begin
    if Assigned(FOnAtributoPendiente) then
      FOnAtributoPendiente(Pendiente);
    Abort;
  end;
  if Assigned(FValidarStockLinea) then
    FValidarStockLinea(DataSet);
  if Assigned(FValidarLoteLinea) then
    FValidarLoteLinea(DataSet);
end;

procedure TdmCajaOpe.ConfigurarEstructuraCabecera;
var
  Indice: TIndexDef;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsCabecera.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsCabecera.Active then cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  Add('SERIE_FAC', ftString, 20, True);
    Add('NUMERO_FAC', ftString, 20, True);
    Add('FECHA_FAC', ftDate, 0);
    Add('ESCONSOLIDADA_FAC', ftString, 1);
    Add('INSTANTECONSO_FAC', ftDateTime, 0);
    Add('TIPO_FAC', ftString, 20); // NORMAL, SIMPLIFICADA...
    Add('FASE_FAC', ftString, 20); // BORRADOR, VERIFACTU_OK...
    Add('CODIGO_EMP_FAC', ftString, 8);
    Add('RAZON_SOCIAL_EMPRESA_FAC', ftString, 200);
    Add('NIF_EMPRESA_FAC', ftString, 50);
    Add('MOVIL_EMPRESA_FAC', ftString, 40);
    Add('EMAIL_EMPRESA_FAC', ftString, 200);
    Add('DIRECCION1_EMPRESA_FAC', ftString, 200);
    Add('DIRECCION2_EMPRESA_FAC', ftString, 200);
    Add('POBLACION_EMPRESA_FAC', ftString, 200);
    Add('PROVINCIA_EMPRESA_FAC', ftString, 200);
    Add('CODIGO_PAI_EMPRESA_FAC', ftString, 3);
    Add('NOMBRE_PAI_EMPRESA_FAC', ftString, 150);
    Add('CODIGO_POSTAL_EMPRESA_FAC', ftString, 15);
    Add('ESRETENCIONES_EMPRESA_FAC', ftString, 1);
    Add('GRUPO_ZONA_IVA_EMPRESA_FAC', ftString, 10);
    Add('ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC', ftString, 1);
    Add('CODIGO_CLI_FAC', ftString, 10);
    Add('RAZON_SOCIAL_CLIENTE_FAC', ftString, 200);
    Add('NIF_CLIENTE_FAC', ftString, 50);
    Add('MOVIL_CLIENTE_FAC', ftString, 40);
    Add('EMAIL_CLIENTE_FAC', ftString, 200);
    Add('DIRECCION1_CLIENTE_FAC', ftString, 200);
    Add('DIRECCION2_CLIENTE_FAC', ftString, 200);
    Add('POBLACION_CLIENTE_FAC', ftString, 200);
    Add('PROVINCIA_CLIENTE_FAC', ftString, 200);
    Add('CODIGO_POSTAL_CLIENTE_FAC', ftString, 15);
    Add('CODIGO_PAI_CLIENTE_FAC', ftString, 3);
    Add('NOMBRE_PAI_CLIENTE_FAC', ftString, 150);
    Add('CODIGO_OFICINA_CONTABLE_FAC', ftString, 10);
    Add('CODIGO_ORGANO_GESTOR_FAC', ftString, 10);
    Add('CODIGO_UNIDAD_TRAMITADORA_FAC', ftString, 10);
    Add('CODIGO_CAJERO_FAC', ftString, 20);
    Add('CODIGO_IVA_FAC', ftString, 20);
    Add('ESIVA_RECARGO_CLIENTE_FAC', ftString, 1);
    Add('ESIVA_EXENTO_CLIENTE_FAC', ftString, 1);
    Add('ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC', ftString, 1);
    Add('ESRETENCIONES_CLIENTE_FAC', ftString, 1);
    Add('TARIFA_ARTICULO_CLIENTE_FAC', ftString, 10);
    Add('ESIMP_INCL_TARIFA_CLIENTE_FAC', ftString, 1);
    Add('ESINTRACOMUNITARIO_CLIENTE_FAC', ftString, 1);
    Add('ESIRPF_IMP_INCL_ZONA_IVA_FAC', ftString, 1);
    Add('ESAPLICA_RE_ZONA_IVA_FAC', ftString, 1);
    Add('ESIVAAGRICOLA_ZONA_IVA_FAC', ftString, 1);
    Add('PALABRA_REPORTS_ZONA_IVA_FAC', ftString, 10);
    Add('ESVENTA_ACTIVO_FIJO_FAC', ftString, 1);
    Add('PORCENTAJE_IVAN_FAC', ftFloat, 0);
    Add('TOTAL_IVAN_FAC', ftCurrency, 0);
    Add('PORCENTAJE_REN_FAC', ftFloat, 0);
    Add('TOTAL_REN_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAN_FAC', ftCurrency, 0);
    Add('PORCENTAJE_IVAR_FAC', ftFloat, 0);
    Add('TOTAL_IVAR_FAC', ftCurrency, 0);
    Add('PORCENTAJE_RER_FAC', ftFloat, 0);
    Add('TOTAL_RER_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAR_FAC', ftCurrency, 0);
    Add('PORCENTAJE_IVAS_FAC', ftFloat, 0);
    Add('TOTAL_IVAS_FAC', ftCurrency, 0);
    Add('PORCENTAJE_RES_FAC', ftFloat, 0);
    Add('TOTAL_RES_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAS_FAC', ftCurrency, 0);
    Add('PORCENTAJE_IVAE_FAC', ftFloat, 0);
    Add('TOTAL_IVAE_FAC', ftCurrency, 0);
    Add('PORCENTAJE_REE_FAC', ftFloat, 0);
    Add('TOTAL_REE_FAC', ftCurrency, 0);
    Add('TOTAL_BASEI_IVAE_FAC', ftCurrency, 0);
    Add('TOTAL_BASES_FAC', ftCurrency, 0);
    Add('TOTAL_IMPUESTOS_FAC', ftCurrency, 0);
    Add('PORCENTAJE_RETENCION_FAC', ftFloat, 0);
    Add('TOTAL_RETENCION_FAC', ftCurrency, 0);
    Add('TOTAL_LIQUIDO_FAC', ftCurrency, 0); // Lo que paga el cliente
    Add('FORMA_PAGO_FAC', ftString, 200);
    Add('NUMERO_FAC_ABONO_FAC', ftString, 8);
    Add('SERIE_FAC_ABONO_FAC', ftString, 8);
    Add('TEXTO_LEGAL_CLIENTE_FAC', ftString, 1000);
    Add('TEXTO_LEGAL_EMPRESA_FAC', ftString, 1000);
    Add('COMENTARIOS_FAC', ftString, 1000);
    Add('XML_FAC', ftMemo, 0); // Para VeriFactu
    Add('DOCUMENTO_FAC', ftBlob, 0);
    Add('CONTADOR_LINEAS_FAC', ftString, 8);
    Add('ESCREARARTICULOS_FAC', ftString, 1);
    Add('ESDESCRIPCIONES_AMP_FAC', ftString, 1);
    Add('ESFECHADEENTREGA_FAC', ftString, 1);
    Add('INSTANTE_MODIF', ftDateTime, 0);
    Add('INSTANTE_ALTA', ftDateTime, 0);
    Add('USUARIO_ALTA', ftString, 100);
  Add('USUARIO_MODIF', ftString, 100);
  Indice := cdsCabecera.IndexDefs.AddIndexDef;
  Indice.Name := 'PK_CABECERA';
  Indice.Fields := 'SERIE_FAC;NUMERO_FAC';
  Indice.Options := [ixPrimary, ixUnique];
  cdsCabecera.CreateDataSet;
end;

procedure TdmCajaOpe.ConfigurarEstructuraLineas;
var
  Indice: TIndexDef;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsLineas.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsLineas.Active then cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  Add('VIENE_DE_DEPOSITO', ftString, 1);
    Add('ID_DEPOSITO_DEP', ftString, 20);
    Add('PRECIO_ORIGINAL_DEP', ftCurrency);
    Add('ACCION_DEPOSITO', ftString, 15); // Valores: 'COBRAR' o 'CANCELAR'
    Add('ANTICIPO_PREVIO', ftCurrency);   // Memoria del dinero adelantado
    // Fecha y hora de la operacion del deposito (F2 cuenta cliente), ya
    // formateada para mostrarse tal cual en el grid.
    Add('FECHA_DEPOSITO_DEP', ftString, 20);
    // Seleccion de la prenda en la cuenta del cliente (F2): 'S' la cobra
    // ahora; si hay alguna marcada, las demas siguen en deposito.
    Add('ESMARCADA_DEP', ftString, 1);
    // Historico (F2 + Ver historico): la linea cerrada lleva cantidad 0
    // para no sumar; aqui se guarda la real, solo para mostrarla.
    Add('CANTIDAD_HISTORICO_DEP', ftFloat);
    // Préstamo (F7): la línea de abono queda en 1 unidad; aquí van las
    // prendas que entran en el depósito nuevo.
    Add('CANTIDAD_DEPOSITO_DEP', ftFloat);
    // -- CLAVES DE ENLACE CON CABECERA (Foreign Keys) --
    Add('SERIE_FAC_FACLIN', ftString, 20, True);
    Add('NUMERO_FAC_FACLIN', ftString, 20, True);
    Add('LINEA_FACLIN', ftString, 4, True);
    Add('CODIGO_VENDEDOR_FACLIN', ftString, 20);
    // -- DATOS DEL ARTÍCULO (PADRE) --
    Add('CODIGO_ART_FACLIN', ftString, 50);
    Add('CODIGO_FAM_FACLIN', ftString, 20);
    Add('NOMBRE_FAM_FACLIN', ftString, 200);
    Add('DESCRIPCION_ARTICULO_FACLIN', ftString, 100);
    // El SKU exacto que descuenta stock (ej: ZAP-OXFORD/42/NEGRO)
    Add('CODIGO_UNIDAD_FACLIN', ftString, 50);
    Add('TIPO_ARTICULO_FACLIN', ftString, 10); // 'ESTANDAR' o 'SERVICIO'
    Add('NUM_ATRIBUTOS_REQ_FACTURA_LINEA', ftInteger, 0);
    for var I := 1 to 5 do
    begin
      Add('ATTR' + IntToStr(i) + '_NOMBRE', ftString, 50);
      Add('ATTR' + IntToStr(i) + '_VALOR', ftString, 50);
    end;
    // DATOS DE TRAZABILIDAD (Si el artículo lo requiere)
    Add('LOTE_FACLIN', ftString, 50);
    // F-LOTEC-015: 'S' si LOTE_FACLIN es una serie (solo para el ticket).
    Add('ESSERIE_LOTE', ftString, 1);
    Add('FECHA_CADUCIDAD_FACLIN', ftDate, 0);
    Add('PRECIO_ULT_COMPRA_FACLIN', ftBCD, 0);
    Add('CODIGO_PRV_FACLIN', ftString, 20);
    Add('RAZON_SOCIAL_PROVEEDOR_FACLIN', ftString, 200);
    Add('ESPROVEEDORPRINCIPAL_FACLIN', ftString, 1);
    Add('FECHA_ENTREGA_FACLIN', ftDateTime, 0);
    // -- CANTIDADES Y TARIFAS --
    Add('TIPO_CANTIDAD_ARTICULO_FACLIN', ftString, 20); // 'Uds', 'Kg'
    Add('ESIMP_INCL_TARIFA_FACLIN', ftString, 1);
    Add('CODIGO_TAR_FACLIN', ftString, 10);
    Add('CANTIDAD_FACLIN', ftFloat, 0);
    // -- PRECIOS Y DESCUENTOS --
    Add('PRECIO_SALIDA_FACLIN', ftCurrency, 0);
    Add('PORCENTAJE_DTO_FACLIN', ftFloat, 0);
    Add('PRECIO_DTO_FACLIN', ftFloat, 0);
    // -- IMPORTES Y TOTALES --
    Add('PRECIO_VENTA_SIVA_ARTICULO_FACLIN', ftCurrency, 0);
    Add('TIPO_IVA_ARTICULO_FACLIN', ftString, 2);
    Add('PORCENTAJE_IVA_FACLIN', ftFloat, 0);
    Add('PRECIO_VENTA_CIVA_ARTICULO_FACLIN', ftCurrency, 0);
    Add('TOTAL_FACLIN', ftCurrency, 0);
    Add('TOTAL_FAC_SIVA_FACLIN', ftCurrency, 0);
    // -- CAMPOS DE AUDITORÍA --
    Add('INSTANTE_MODIF', ftDateTime, 0);
    Add('INSTANTE_ALTA', ftDateTime, 0);
    Add('USUARIO_ALTA', ftString, 100);
  Add('USUARIO_MODIF', ftString, 100);
  Indice := cdsLineas.IndexDefs.AddIndexDef;
  Indice.Name := 'PRIMARY_KEY';
  Indice.Fields :=
    'SERIE_FAC_FACLIN;NUMERO_FAC_FACLIN;LINEA_FACLIN';
  Indice.Options := [ixPrimary, ixUnique];
  cdsLineas.CreateDataSet;
  cdsLineas.IndexName := 'PRIMARY_KEY';
end;

procedure TdmCajaOpe.DataModuleCreate(Sender: TObject);
begin
  qryDefinicionArticulo.Connection := FConexion;
  qryVales.Connection := FConexion;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
end;

procedure ConfigurarSqlInsertarCabeceraFacturaCaja(AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO fza_facturas (' +
    '  SERIE_FAC, NUMERO_FAC, FECHA_FAC,' +
    '  TIPO_FAC, FASE_FAC,' +
    '  CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC,' +
    '  MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC,' +
    '  DIRECCION1_EMPRESA_FAC, DIRECCION2_EMPRESA_FAC,' +
    '  POBLACION_EMPRESA_FAC, PROVINCIA_EMPRESA_FAC,' +
    '  CODIGO_POSTAL_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC,' +
    '  ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC,' +
    '  CODIGO_CLI_FAC, RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC,' +
    '  MOVIL_CLIENTE_FAC, EMAIL_CLIENTE_FAC,' +
    '  DIRECCION1_CLIENTE_FAC, DIRECCION2_CLIENTE_FAC,' +
    '  POBLACION_CLIENTE_FAC, PROVINCIA_CLIENTE_FAC,' +
    '  CODIGO_POSTAL_CLIENTE_FAC, CODIGO_PAI_CLIENTE_FAC, ' +
    'NOMBRE_PAI_CLIENTE_FAC,' +
    '  CODIGO_OFICINA_CONTABLE_FAC, CODIGO_ORGANO_GESTOR_FAC, ' +
    'CODIGO_UNIDAD_TRAMITADORA_FAC,' +
    '  CODIGO_IVA_FAC, TARIFA_ARTICULO_CLIENTE_FAC,' +
    '  ESIVA_RECARGO_CLIENTE_FAC, ESIVA_EXENTO_CLIENTE_FAC,' +
    '  ESIMP_INCL_TARIFA_CLIENTE_FAC,' +
    '  PORCENTAJE_IVAN_FAC, TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, ' +
    'TOTAL_REN_FAC, TOTAL_BASEI_IVAN_FAC,' +
    '  PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, PORCENTAJE_RER_FAC, ' +
    'TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC,' +
    '  PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, ' +
    'TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC,' +
    '  PORCENTAJE_IVAE_FAC, TOTAL_IVAE_FAC, PORCENTAJE_REE_FAC, ' +
    'TOTAL_REE_FAC, TOTAL_BASEI_IVAE_FAC,' +
    '  TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC,' +
    '  PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC,' +
    '  TOTAL_LIQUIDO_FAC,' +
    '  FORMA_PAGO_FAC,' +
    '  COMENTARIOS_FAC,' +
    '  SERIE_FAC_ABONO_FAC, NUMERO_FAC_ABONO_FAC,' +
    '  CODIGO_ALM_FAC, CODIGO_CAJA_FAC,' +
    '  CODIGO_CAJERO_FAC, NUMERO_OPERACION_FAC,' +
    '  ESCREARARTICULOS_FAC, ESDESCRIPCIONES_AMP_FAC, ESFECHADEENTREGA_FAC,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :SERIE, :NRO, :FECHA,' +
    '  :TIPO, :FASE,' +
    '  :EMP, :RSEMP, :NIFEMP,' +
    '  NULLIF(:MOVILEMP,  ''''), NULLIF(:EMAILEMP, ''''),' +
    '  NULLIF(:DIR1EMP,   ''''), NULLIF(:DIR2EMP,  ''''),' +
    '  NULLIF(:POBLEMP,   ''''), NULLIF(:PROVEMP,  ''''),' +
    '  NULLIF(:CPEMP,     ''''), :PAISEMP, NULLIF(:NPAISEMP, ''''),' +
    '  :RETREMP, NULLIF(:GRUPOIVAEMP, ''''),' +
    '  NULLIF(:CLI,       ''''), NULLIF(:RSCLI,    ''''), NULLIF(:NIFCLI,   ' +
    '''''),' +
    '  NULLIF(:MOVILCLI,  ''''), NULLIF(:EMAILCLI, ''''),' +
    '  NULLIF(:DIR1CLI,   ''''), NULLIF(:DIR2CLI,  ''''),' +
    '  NULLIF(:POBLCLI,   ''''), NULLIF(:PROVCLI,  ''''),' +
    '  NULLIF(:CPCLI,     ''''), :PAISCLI, NULLIF(:NPAISCLI, ''''),' +
    '  NULLIF(:DIR3OFICINA, ''''), NULLIF(:DIR3ORGANO, ''''), ' +
    'NULLIF(:DIR3UNIDAD, ''''),' +
    '  NULLIF(:CODIGOIVA, ''''), NULLIF(:TARIFA,   ''''),' +
    '  :ESRECARGO, :ESEXENTO,' +
    '  :ESIMPINCL,' +
    '  :PIVAN,  :TIVAN,  :PREN,  :TREN,  :BASEIN,' +
    '  :PIVAR,  :TIVAR,  :PRER,  :TRER,  :BASEIR,' +
    '  :PIVAS,  :TIVAS,  :PRES,  :TRES,  :BASEIS,' +
    '  :PIVAE,  :TIVAE,  :PREE,  :TREE,  :BASEIE,' +
    '  :TBASES, :TIMPS,' +
    '  :PRETENC, :TRETENC,' +
    '  :TLIQUIDO,' +
    '  NULLIF(:FORMAP,  ''''),' +
    '  NULLIF(:COMENT,  ''''),' +
    '  NULLIF(:SERIEABO, ''''), NULLIF(:NROABO, ''''),' +
    '  NULLIF(:ALM,  ''''), NULLIF(:CAJA,  ''''),' +
    '  NULLIF(:CAJERO, ''''), NULLIF(:NUMOP, ''''),' +
    '  ''N'', ''N'', ''N'',' +
    '  :USUARIO, :USUARIO, NOW())';
end;

procedure AsignarIdentificacionFactura(
  AConsulta: TUniQuery;
  const ASerie, ANumero: string;
  AFecha: TDateTime;
  const ATipo, AFase: string);
begin
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NRO').AsString := ANumero;
  AConsulta.ParamByName('FECHA').AsDate := AFecha;
  AConsulta.ParamByName('TIPO').AsString := ATipo;
  AConsulta.ParamByName('FASE').AsString := AFase;
end;

procedure AsignarEmpresaFactura(
  AConsulta: TUniQuery;
  const AEmpresa: string;
  const ACabecera: TDatosCabeceraFactura);
begin
  AConsulta.ParamByName('EMP').AsString := AEmpresa;
  AConsulta.ParamByName('RSEMP').AsString := ACabecera.RazonSocialEmp;
  AConsulta.ParamByName('NIFEMP').AsString := ACabecera.NifEmp;
  AConsulta.ParamByName('MOVILEMP').AsString := ACabecera.MovilEmp;
  AConsulta.ParamByName('EMAILEMP').AsString := ACabecera.EmailEmp;
  AConsulta.ParamByName('DIR1EMP').AsString := ACabecera.Direccion1Emp;
  AConsulta.ParamByName('DIR2EMP').AsString := ACabecera.Direccion2Emp;
  AConsulta.ParamByName('POBLEMP').AsString := ACabecera.PoblacionEmp;
  AConsulta.ParamByName('PROVEMP').AsString := ACabecera.ProvinciaEmp;
  AConsulta.ParamByName('CPEMP').AsString := ACabecera.CPostalEmp;
  AConsulta.ParamByName('PAISEMP').AsString := ACabecera.CodigoPaisEmp;
  AConsulta.ParamByName('NPAISEMP').AsString := ACabecera.NombrePaisEmp;
  AConsulta.ParamByName('RETREMP').AsString :=
    ACabecera.EsRetencionesEmp;
  AConsulta.ParamByName('GRUPOIVAEMP').AsString :=
    ACabecera.GrupoZonaIvaEmp;
end;

procedure AsignarClienteFactura(
  AConsulta: TUniQuery;
  const ACabecera: TDatosCabeceraFactura);
begin
  AConsulta.ParamByName('CLI').AsString := ACabecera.CodigoCliente;
  AConsulta.ParamByName('RSCLI').AsString := ACabecera.RazonSocialCli;
  AConsulta.ParamByName('NIFCLI').AsString := ACabecera.NifCli;
  AConsulta.ParamByName('MOVILCLI').AsString := ACabecera.MovilCli;
  AConsulta.ParamByName('EMAILCLI').AsString := ACabecera.EmailCli;
  AConsulta.ParamByName('DIR1CLI').AsString := ACabecera.Direccion1Cli;
  AConsulta.ParamByName('DIR2CLI').AsString := ACabecera.Direccion2Cli;
  AConsulta.ParamByName('POBLCLI').AsString := ACabecera.PoblacionCli;
  AConsulta.ParamByName('PROVCLI').AsString := ACabecera.ProvinciaCli;
  AConsulta.ParamByName('CPCLI').AsString := ACabecera.CPostalCli;
  AConsulta.ParamByName('PAISCLI').AsString := ACabecera.CodigoPaisCli;
  AConsulta.ParamByName('NPAISCLI').AsString := ACabecera.NombrePaisCli;
  AConsulta.ParamByName('DIR3OFICINA').AsString :=
    ACabecera.CodigoOficinaContable;
  AConsulta.ParamByName('DIR3ORGANO').AsString :=
    ACabecera.CodigoOrganoGestor;
  AConsulta.ParamByName('DIR3UNIDAD').AsString :=
    ACabecera.CodigoUnidadTramitadora;
  AConsulta.ParamByName('CODIGOIVA').AsString := ACabecera.CodigoIva;
  AConsulta.ParamByName('TARIFA').AsString := ACabecera.Tarifa;
  AConsulta.ParamByName('ESRECARGO').AsString := ACabecera.EsIvaRecargo;
  AConsulta.ParamByName('ESEXENTO').AsString := ACabecera.EsIvaExento;
  AConsulta.ParamByName('ESIMPINCL').AsString :=
    ACabecera.EsImpInclTarifa;
end;

procedure AsignarTotalesFactura(
  AConsulta: TUniQuery;
  const ACabecera: TDatosCabeceraFactura);
begin
  AConsulta.ParamByName('PIVAN').AsCurrency := ACabecera.PorcIvaN;
  AConsulta.ParamByName('TIVAN').AsCurrency := ACabecera.TotalIvaN;
  AConsulta.ParamByName('PREN').AsCurrency := ACabecera.PorcReN;
  AConsulta.ParamByName('TREN').AsCurrency := ACabecera.TotalReN;
  AConsulta.ParamByName('BASEIN').AsCurrency := ACabecera.BaseIN;
  AConsulta.ParamByName('PIVAR').AsCurrency := ACabecera.PorcIvaR;
  AConsulta.ParamByName('TIVAR').AsCurrency := ACabecera.TotalIvaR;
  AConsulta.ParamByName('PRER').AsCurrency := ACabecera.PorcReR;
  AConsulta.ParamByName('TRER').AsCurrency := ACabecera.TotalReR;
  AConsulta.ParamByName('BASEIR').AsCurrency := ACabecera.BaseIR;
  AConsulta.ParamByName('PIVAS').AsCurrency := ACabecera.PorcIvaS;
  AConsulta.ParamByName('TIVAS').AsCurrency := ACabecera.TotalIvaS;
  AConsulta.ParamByName('PRES').AsCurrency := ACabecera.PorcReS;
  AConsulta.ParamByName('TRES').AsCurrency := ACabecera.TotalReS;
  AConsulta.ParamByName('BASEIS').AsCurrency := ACabecera.BaseIS;
  AConsulta.ParamByName('PIVAE').AsCurrency := ACabecera.PorcIvaE;
  AConsulta.ParamByName('TIVAE').AsCurrency := ACabecera.TotalIvaE;
  AConsulta.ParamByName('PREE').AsCurrency := ACabecera.PorcReE;
  AConsulta.ParamByName('TREE').AsCurrency := ACabecera.TotalReE;
  AConsulta.ParamByName('BASEIE').AsCurrency := ACabecera.BaseIE;
  AConsulta.ParamByName('TBASES').AsCurrency := ACabecera.TotalBases;
  AConsulta.ParamByName('TIMPS').AsCurrency := ACabecera.TotalImpuestos;
  AConsulta.ParamByName('PRETENC').AsCurrency := ACabecera.PorcRetencion;
  AConsulta.ParamByName('TRETENC').AsCurrency := ACabecera.TotalRetencion;
  AConsulta.ParamByName('TLIQUIDO').AsCurrency := ACabecera.TotalLiquido;
end;

procedure AsignarReferenciasFactura(
  AConsulta: TUniQuery;
  const ACabecera: TDatosCabeceraFactura;
  const ASerieAbono, ANumeroAbono: string;
  const AAlmacen, ACaja, ACajero: string;
  const ANumeroOperacion, AUsuario: string);
begin
  AConsulta.ParamByName('FORMAP').AsString := ACabecera.FormaPago;
  AConsulta.ParamByName('COMENT').AsString := ACabecera.Comentarios;
  AConsulta.ParamByName('SERIEABO').AsString := ASerieAbono;
  AConsulta.ParamByName('NROABO').AsString := ANumeroAbono;
  AConsulta.ParamByName('ALM').AsString := AAlmacen;
  AConsulta.ParamByName('CAJA').AsString := ACaja;
  AConsulta.ParamByName('CAJERO').AsString := ACajero;
  AConsulta.ParamByName('NUMOP').AsString := ANumeroOperacion;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
end;

procedure TdmCajaOpe.InsertarCabeceraFactura(
  AConsulta: TUniQuery;
  const ASerie, ANumero: string;
  AFecha: TDateTime;
  const ATipo, AFase: string;
  const AEmpresa: string;
  const ACabecera: TDatosCabeceraFactura;
  const ASerieAbono, ANumeroAbono: string;
  const AAlmacen, ACaja, ACajero: string;
  const ANumeroOperacion, AUsuario: string);
begin
  ConfigurarSqlInsertarCabeceraFacturaCaja(AConsulta);
  AsignarIdentificacionFactura(
    AConsulta, ASerie, ANumero, AFecha, ATipo, AFase);
  AsignarEmpresaFactura(AConsulta, AEmpresa, ACabecera);
  AsignarClienteFactura(AConsulta, ACabecera);
  AsignarTotalesFactura(AConsulta, ACabecera);
  AsignarReferenciasFactura(
    AConsulta, ACabecera, ASerieAbono, ANumeroAbono,
    AAlmacen, ACaja, ACajero, ANumeroOperacion, AUsuario);
  AConsulta.Execute;
end;

procedure TdmCajaOpe.InsertarLineaFactura(
            QryTrx:              TUniQuery;
            // — identificación —
            const ASerie:        string;
            const ANro:          string;
            const ALinea:        string;   // '0010', '0020'...
            // — artículo —
            const AArticulo:     string;
            const ASku:          string;
            const ADesc:         string;
            const ADescVariacion:string;
            const AFamilia:      string;
            const ANombreFamilia:string;
            const ATipoArticulo: string;   // 'ESTANDAR', 'SERVICIO', 'KIT'
            const ATipoCantidad: string;   // 'Uds', 'Kg'...
            ACantidad:           Double;
            ACosteUnitario:      Currency;
            // — tarifa y precios —
            const ATarifa:       string;
            AEsImpIncl:          string;   // 'S'/'N'
            APrecioSalida:       Currency;
            APorcDto:            Double;
            APrecioDto:          Currency;
            APrecioSIva:         Currency;
            APrecioCIva:         Currency;
            const ATipoIva:      string;   // 'N','R','S','E'
            APorcIva:            Double;
            ATotalSIva:          Currency;
            ATotalCIva:          Currency;
            // — vendedor —
            const AVendedor:     string;
            // — caja y trazabilidad —
            const AEmpresa:      string;
            const AAlmacen:      string;
            const ACaja:         string;
            ANumOperacion:       string;
            // NUMERO_MOV de fza_movimientos_almacen
            const ANumMovAlmacen:string;
            const AUsuario:      string;
            const ALote:         string;
            AFechaCaducidad:     TDate);
var
  bConLote: Boolean;
begin
  // F-LOTEC-015: el lote solo se graba con los interruptores; sin él, la
  // sentencia es la de siempre.
  bConLote := (Trim(ALote) <> '') and ActivacionVigente.AlgunModoActivo;
  QryTrx.SQL.Text :=
    'INSERT INTO fza_facturas_lineas (' +
    IfThen(bConLote, '  LOTE_FACLIN, FECHA_CADUCIDAD_FACLIN,', '') +
    '  SERIE_FAC_FACLIN, NUMERO_FAC_FACLIN, LINEA_FACLIN,' +
    '  CODIGO_EMP_FACLIN, ' +
    '  CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN,' +
    '  DESCRIPCION_ARTICULO_FACLIN, ' + //DESCRIPCION_VARIACION_FACLIN,' +
    '  CODIGO_FAM_FACLIN, NOMBRE_FAM_FACLIN,' +
    '  PRECIO_ULT_COMPRA_FACLIN,' +
    '  TIPO_ARTICULO_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN,' +
    '  CANTIDAD_FACLIN,' +
    '  CODIGO_TAR_FACLIN, ESIMP_INCL_TARIFA_FACLIN,' +
    '  PRECIO_SALIDA_FACLIN,' +
    '  PORCENTAJE_DTO_FACLIN, PRECIO_DTO_FACLIN,' +
    '  PRECIO_VENTA_SIVA_ARTICULO_FACLIN,' +
    '  PRECIO_VENTA_CIVA_ARTICULO_FACLIN,' +
    '  TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN,' +
    '  TOTAL_FAC_SIVA_FACLIN, TOTAL_FACLIN,' +
    '  CODIGO_VENDEDOR_FACLIN,' +
    '  CODIGO_ALM_FACLIN, CODIGO_CAJA_FACLIN,' +
    '  NUMERO_OPERACION_FACLIN,' +
    '  NUMERO_MOV_FACLIN,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    IfThen(bConLote, '  :LOTE, :CADUCIDAD,', '') +
    '  :SERIE, :NRO, :LINEA,' +
    '  :EMP, ' +
    '  NULLIF(:ART,   ''''), NULLIF(:SKU,    ''''),' +
    '  NULLIF(:DESC,  ''''),' + //NULLIF(:DESCVAR,''''),' +
    '  NULLIF(:FAM,   ''''), NULLIF(:NOMFAM, ''''),' +
    '  :PRECOSTE,' +
    '  :TIPOART, :TIPOCANT,' +
    '  :CANT,' +
    '  NULLIF(:TARIFA,    ''''), :ESIMPINCL,' +
    '  :PRECSALIDA,' +
    '  :PORCDTO, :PRECDTO,' +
    '  :PRECSIVA,' +
    '  :PRECCIVA,' +
    '  :TIPOIVA, :PORCIVA,' +
    '  :TOTALSIVA, :TOTALCIVA,' +
    '  NULLIF(:VENDEDOR,  ''''),' +
    '  NULLIF(:ALM,       ''''), NULLIF(:CAJA, ''''),' +
    '  NULLIF(:NUMOP, ''''),' +
    '  NULLIF(:NUMMOV,    ''''),' +
    '  :USUARIO, :USUARIO, NOW())';
  QryTrx.ParamByName('SERIE').AsString    := ASerie;
  QryTrx.ParamByName('NRO').AsString      := ANro;
  QryTrx.ParamByName('LINEA').AsString    := ALinea;
  QryTrx.ParamByName('EMP').AsString      := AEmpresa;
  QryTrx.ParamByName('ART').AsString      := AArticulo;
  QryTrx.ParamByName('SKU').AsString      := ASku;
  QryTrx.ParamByName('DESC').AsString     := ADesc;
//  QryTrx.ParamByName('DESCVAR').AsString  := ADescVariacion;
  QryTrx.ParamByName('FAM').AsString      := AFamilia;
  QryTrx.ParamByName('NOMFAM').AsString   := ANombreFamilia;
  QryTrx.ParamByName('PRECOSTE').AsCurrency := ACosteUnitario;
  QryTrx.ParamByName('TIPOART').AsString  := ATipoArticulo;
  QryTrx.ParamByName('TIPOCANT').AsString := ATipoCantidad;
  QryTrx.ParamByName('CANT').AsFloat      := ACantidad;
  QryTrx.ParamByName('TARIFA').AsString   := ATarifa;
  QryTrx.ParamByName('ESIMPINCL').AsString:= AEsImpIncl;
  QryTrx.ParamByName('PRECSALIDA').AsCurrency := APrecioSalida;
  QryTrx.ParamByName('PORCDTO').AsFloat   := APorcDto;
  QryTrx.ParamByName('PRECDTO').AsCurrency:= APrecioDto;
  QryTrx.ParamByName('PRECSIVA').AsCurrency := APrecioSIva;
  QryTrx.ParamByName('PRECCIVA').AsCurrency := APrecioCIva;
  QryTrx.ParamByName('TIPOIVA').AsString  := ATipoIva;
  QryTrx.ParamByName('PORCIVA').AsFloat   := APorcIva;
  QryTrx.ParamByName('TOTALSIVA').AsCurrency := ATotalSIva;
  QryTrx.ParamByName('TOTALCIVA').AsCurrency := ATotalCIva;
  QryTrx.ParamByName('VENDEDOR').AsString := AVendedor;
  QryTrx.ParamByName('ALM').AsString      := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString     := ACaja;
  QryTrx.ParamByName('NUMOP').AsString   := ANumOperacion;
  QryTrx.ParamByName('NUMMOV').AsString   := ANumMovAlmacen;
  QryTrx.ParamByName('USUARIO').AsString  := AUsuario;
  if bConLote then
  begin
    QryTrx.ParamByName('LOTE').AsString := Trim(ALote);
    QryTrx.ParamByName('CADUCIDAD').DataType := ftDate;
    if AFechaCaducidad = 0 then
      QryTrx.ParamByName('CADUCIDAD').Clear
    else
      QryTrx.ParamByName('CADUCIDAD').AsDate := AFechaCaducidad;
  end;
  QryTrx.Execute;
end;

end.
