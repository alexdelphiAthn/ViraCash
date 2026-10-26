{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTraspaso                                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de la operativa de traspasos entre almacenes (TPV).           }
{    El traspaso ejecutado se graba SOLO en fza_caja_operaciones (TR/AT) +     }
{    fza_movimientos_almacen (par salida+entrada). Ver                         }
{    DESARROLLOS EN CURSO/traspasos_caja.md.                                   }
{******************************************************************************}
unit UniDataTraspaso;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Datasnap.DBClient, Uni, MemDS,
  DBAccess, System.Math, System.StrUtils,
  inLibErroresBBDD,
  UniDataValoresAutomaticosRepositorio,
  inLibContextoSesionIntf,
  inLibDistribucionTiendasIntf,
  inLibTraspasoOpePersistenciaIntf,
  inLibLotesPersistenciaIntf, inLibLotesLineaDocumento,
  System.Generics.Collections, inLibTraspasoTicket,
  inLibRecuentoSkuNormalizacion, inLibTraspasoRecuentoApp,
  inLibTransitoEmpresas;

type
  // Modo de la operativa: traspaso directo, solicitud, atención o reposición.
  TModoTraspaso = (mtTraspaso, mtSolicitar, mtAtender, mtReposicion);

  // Validación de negocio (stock insuficiente, líneas incompletas, destino
  // sin elegir...). El formulario y el gestor global la muestran como
  // aviso, tambien cuando el grid publica al avanzar de linea.
  EValidacionTraspaso = class(EValidacionBBDD);

  TContextoGrabacionTraspaso = record
    Empresa: string;
    AlmacenOrigen: string;
    AlmacenDestino: string;
    Caja: string;
    Usuario: string;
    EmpresaContra: string;
    EmpresaDestino: string;
    TipoDocumento: string;
    SerieDocumento: string;
    NumeroDocumento: string;
    Empleado: string;
    NumeroOperacion: string;
    FechaOperacion: TDateTime;
    // Salida de un transito (FZ-ISSUE-717): empresa de la operacion de
    // caja y su contrapartida. En una TA, la que entrega y la que recibe.
    EmpresaOperacion: string;
    EmpresaContraOperacion: string;
  end;

  // Reparto de una linea de una carga en transito al recibirla
  // (FZ-ISSUE-256): lo cargado llega bien, llega deteriorado (pasa al
  // almacen de taras) o no llega (perdida). El coste es el de la carga.
  TLineaRecepcionTransito = record
    CodigoSku: string;
    CodigoArticulo: string;
    Descripcion: string;
    // Unidad de medida del articulo: decide los decimales de las cantidades.
    Unidad: string;
    CantidadCargada: Double;
    CantidadRecibida: Double;
    CantidadDeteriorada: Double;
    CantidadPerdida: Double;
    CosteUnitario: Currency;
    Motivo: string;
    // F-LOTEC-017: cada lote o serie de la carga es una línea propia
    // ('' sin lote; 0 = sin caducidad).
    Lote: string;
    FechaCaducidad: TDate;
  end;
  TLineasRecepcionTransito = TArray<TLineaRecepcionTransito>;

  // Carga en transito bloqueada dentro de la transaccion que la cierra.
  TCargaTransito = record
    Id: Int64;
    // Empresa que cargo: duena de la mercancia en un transito compartido.
    Empresa: string;
    AlmacenOrigen: string;
    AlmacenTransito: string;
    AlmacenDestino: string;
    TipoDocumento: string;
    Serie: string;
    Numero: string;
  end;

  // Documento que saca mercancia de un transito, con su operacion de caja.
  // Sin almacen de entrada es una perdida.
  TSalidaTransito = record
    AlmacenEntrada: string;
    TipoDocumento: string;
    Serie: string;
    Numero: string;
    NumeroOperacion: string;
    Lineas: Integer;
  end;

  // Que parte del reparto de las lineas mueve un documento de salida.
  TParteCargaTransito = (pctCargada, pctRecibida, pctDeteriorada,
    pctPerdida);

  TdmTraspaso = class(TDataModule)
    cdsCabecera: TClientDataSet;
    cdsLineas: TClientDataSet;
    dsCabecera: TDataSource;
    dsLineas: TDataSource;
    qryAux: TUniQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    FConexion: TUniConnection;
    FModo: TModoTraspaso;
    FContextoSesion: IContextoSesionAplicacion;
    // Propuesta de traspaso (Distribuir entre tiendas) que este traspaso
    // confirma al grabarse; 0 = ninguna.
    FIdPropuesta: Int64;
    // Estado en que queda la propuesta al grabar: TRASLADADO o
    // TRASLADADO PARCIAL.
    FEstadoPropuestaAlGrabar: string;
    // Traspaso hecho con la app de recuento que este traspaso recoge
    // (FZ-ISSUE-351); 0 = ninguno.
    FIdRecuentoApp: Int64;
    FUltimoDocumentoGrabado: TContextoGrabacionTraspaso;
    // Carga hacia un almacen de transito: destino final al que va. Vacio en
    // un traspaso normal (FZ-ISSUE-215).
    FDestinoFinalTransito: string;
    // F-LOTEC-017: lote y serie de las líneas (solo con interruptores).
    FLotesLineas: TLotesLineasDocumento;
    FCargandoLineas: Boolean;
    // FZ-ISSUE-324: unidad de medida por artículo (cache de la sesión)
    FUnidadesArticulo: TDictionary<string, TUnidadLineaTicketTraspaso>;
    FConsultaUnidad: TUniQuery;
    procedure CompletarUnidadLinea;
    function GetIdentidadSesion: TIdentidadSesion;
    function LotesLineasActivos: Boolean;
    procedure cdsLineasBeforePost(DataSet: TDataSet);
    procedure ValidarCantidadLineaActual;
    procedure cdsLineasAfterPost(DataSet: TDataSet);
    procedure ValidarLotesLineas;
    function CargarSolicitudSinLotes(const ANumero, ASerie: string): Boolean;
    function OperacionRecuentoAppEn(AConsulta: TUniQuery;
      const AEmpresa, AAlmacen: string; AIdRecuento: Int64): string;
    procedure ExigirRecuentoAppNoGrabado(QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso);
    function ObtenerStockLote(const ASku, ALote, AAlmacen: string): Double;
    procedure RegistrarCargaTransito(QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso);
    function AlmacenCaja: string;
    function AbrirCargasTransitoPendientes(
      const AColumnaAlmacen, AAlmacen: string): TDataSet;
    function ContarCargasTransito(
      const AColumnaAlmacen, AAlmacen: string): Integer;
    function ContarSolicitudesPendientes(
      const AColumnaAlmacen, AAlmacen: string): Integer;
    function BloquearCargaTransito(QryTrx: TUniQuery; AId: Int64;
      ADesdeOrigen: Boolean): TCargaTransito;
    function LeerLineasCargaTransito(
      const ACarga: TCargaTransito): TLineasRecepcionTransito;
    function RepartirCargaTransito(
      const ACarga, AReparto: TLineasRecepcionTransito
    ): TLineasRecepcionTransito;
    procedure ValidarAlmacenTarasTransito(
      const ALineas: TLineasRecepcionTransito;
      const AAlmacenTaras: string);
    function CrearContextoSalidaTransito(const ACarga: TCargaTransito;
      const AAlmacenEntrada: string): TContextoGrabacionTraspaso;
    function GrabarLineasSalidaTransito(QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso;
      const ALineas: TLineasRecepcionTransito;
      AParte: TParteCargaTransito;
      out ASalidas: TArray<string>): Integer;
    // FZ-ISSUE-377: coste de los movimientos grabados (por NUMERO_MOV). La
    // serie y el número de un traspaso se repiten entre empresas, así que
    // sumar por documento mezclaría los de otras.
    function TotalCosteMovimientos(QryTrx: TUniQuery;
      const ANumeros: TArray<string>): Currency;
    function GrabarSalidaTransito(QryTrx: TUniQuery;
      const ACarga: TCargaTransito;
      const AAlmacenEntrada, AConcepto: string;
      const ALineas: TLineasRecepcionTransito;
      AParte: TParteCargaTransito): TSalidaTransito;
    procedure InsertarIncidenciasTransito(QryTrx: TUniQuery;
      const ACarga: TCargaTransito;
      const ALineas: TLineasRecepcionTransito;
      AParte: TParteCargaTransito; const ASalida: TSalidaTransito);
    procedure CerrarCargaTransito(QryTrx: TUniQuery;
      const ACarga: TCargaTransito; const AEstado: string;
      const ACierre: TSalidaTransito;
      const ATipoDesbloqueo, AMotivo: string);
    procedure ActualizarAnuncioTransito(QryTrx: TUniQuery;
      const ATransito: string);
    function RecibirCargaTransito(AId: Int64;
      const AReparto: TLineasRecepcionTransito;
      const AAlmacenTaras: string): TArray<string>;
    function DesbloquearCargaTransito(AId: Int64;
      const ATipoDesbloqueo, AMotivo: string): string;
    function EsDestinoFinalValido(const AAlmacen: string): Boolean;
    procedure ConfigurarEstructuraCabecera;
    procedure ConfigurarEstructuraLineas;
    procedure DesempaquetarAtributosLinea(const ASku: string);
    procedure cdsLineasNewRecord(DataSet: TDataSet);
    function ObtenerEmpresaAlmacen(const AAlmacen: string): string;
    function LeerTransitoEmpresa(
      const AAlmacen: string): TTransitoEmpresa;
    // Devuelve el articulo padre del SKU activo. Vacio si no existe.
    function ObtenerArticuloSku(const ASku: string): string;
    // Devuelve el articulo padre aunque el SKU historico este inactivo.
    function ObtenerArticuloSkuHistorico(const ASku: string): string;
    function ObtenerIdColorBasicoSolicitud(const AArticulo, AColor: string;
                             out AIdColorBasico: Integer): Boolean;
    function BuscarSkuTcActivoUnico(const AArticulo, ATalla: string;
                             AIdColorBasico: Integer): string;
    function ResolverSkuSolicitudActivo(const AArticulo,
                             ASkuSolicitado: string): string;
    // Recorre el cds antes de grabar/imprimir: descarta lineas en blanco
    // (sin articulo) y aborta con error si una linea tiene articulo pero el
    // SKU no esta cerrado (falta color/talla).
    procedure LimpiarLineasIncompletas;
    procedure ValidarLineasReposicionAuto;
    // Aborta (raise) si un traspaso directo pide mas unidades de las que hay
    // en el almacen origen. Las solicitudes usan el mismo detalle como aviso.
    procedure ValidarStockOrigen(const AAlmacenOrigen: string);
    function AvisoStockOrigenEnFecha(const AAlmacenOrigen: string;
      AFecha: TDateTime): string;
    function ObtenerStockEnFecha(const ASku, ALote, AAlmacen: string;
      AFecha: TDateTime): Double;
    // Serie del documento de traspaso (fza_empresas_series + fallback) y su
    // siguiente número (PRC_GET_NEXT_CONT_FACT_SERIE, como la factura).
    function ObtenerSerieDocumento(const AEmpresa, AAlmacen, ACaja,
                             ATipoDoc: string): string;
    function SiguienteNumeroDocumento(const ASerie, ATipoDoc, AEmpresa,
                             AUsuario: string): string;
    // FZ-ISSUE-628: serie y número de una solicitud o reposición (TS). La
    // serie es la configurada para la caja o el almacén que la emite (o la
    // general de la empresa) y se numera con su contador, como el resto de
    // documentos. Sin serie TS configurada, la serie fija 'TS' de siempre.
    procedure AsignarNumeroSolicitud(const AEmpresa, AAlmacen,
                             ACaja: string; out ANumero, ASerie: string);
    // Replica autocontenida de los helpers de UniDataCaja (privados allí).
    function SiguienteOpCaja(const AEmpresa, AAlmacen, ACaja,
                             AEmpleado: string): string;
    // Devuelve el NUMERO_MOV grabado.
    function InsertarMovimientoAlmacen(QryTrx: TUniQuery;
                             const ATipoDoc, ASerie, ANro, ALinea, AEmpresa,
                             AAlmacen, ACaja, AAlmacenContra, ATipoMov,
                             ASku: string; ACantidad: Double; ACoste: Currency;
                             const AUsuario: string;
                             const AAlmacenDoc: string = '';
                             const ANumOperacion: string = '';
                             const ACodCliente: string = '';
                             const ACodArticulo: string = '';
                             AFechaMovimiento: TDateTime = 0;
                             const ALote: string = '';
                             AFechaCaducidad: TDate = 0): string;
    procedure InsertarOperacionCaja(QryTrx: TUniQuery;
                             const AEmpresa, AAlmacen, ACaja, ANumOperacion,
                             ATipoOp: string; AImporte: Currency;
                             AFechaOperacion: TDateTime;
                             const AEmpleado, AConcepto, ASerieOrigen,
                             ANroOrigen, AEmpresaContra, AAlmContra,
                             AEsTraspaso, ANroDoc, ASerieDoc: string);
    // Suma lo servido a las líneas de la solicitud y recalcula su estado.
    procedure MarcarSolicitudAtendida(QryTrx: TUniQuery;
                             const ANumero, ASerie: string);
    // Pasa la propuesta vinculada a TRASLADADO (o TRASLADADO PARCIAL) con
    // la referencia del traspaso y anota en sus líneas lo realmente traspasado.
    procedure MarcarPropuestaConfirmada(
      QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso);
    procedure AnotarLineasPropuestaTraspasadas(QryTrx: TUniQuery);
    function CrearContextoGrabacionTraspaso(
      const AAlmacenDestino: string): TContextoGrabacionTraspaso;
    function GrabarLineasTraspaso(
      QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso): Currency;
    procedure RegistrarOperacionTraspaso(
      QryTrx: TUniQuery;
      const AContexto: TContextoGrabacionTraspaso;
      ATotal: Currency;
      const ANumSolicitud, ASerieSolicitud: string);
    function EjecutarGrabacionTraspaso(
      var AContexto: TContextoGrabacionTraspaso;
      const ANumSolicitud, ASerieSolicitud: string;
      out ANumOperacion: string): Boolean;
    procedure InsertarCabeceraReposicionAuto(
      AConsulta: TUniQuery;
      const AAlmacenOrigen, ANumero, ASerie: string;
      const ADesde, AHasta: TDateTime; AComoSolicitud: Boolean);
    function InsertarLineasReposicionAuto(
      AConsulta: TUniQuery;
      const ANumero, ASerie: string): Integer;
    function TieneLineasReposicionPositivas: Boolean;
  public
    constructor Create(
      AOwner: TComponent;
      AConexion: TUniConnection); reintroduce;
    destructor Destroy; override;
    // F-LOTEC-017: con algún interruptor, el lote o la serie de cada línea
    // se decide al grabarla (traspaso y atender: sale del origen).
    procedure ConfigurarLotesLineas(const AConfig: TConfiguracionLotesLineas);
    function DocumentoLotes: TDocumentoLineaLote;
    // Botón de la columna Lote: vuelve a elegir el de la línea actual.
    procedure ElegirLoteLinea;
    // Las líneas del traspaso están en memoria: las series de las demás
    // líneas se buscan en cdsLineas, no en una tabla.
    function EnvolverLecturaTrazabilidad(
      const ALectura: ILecturaTrazabilidadArticulo):
      ILecturaTrazabilidadArticulo;
    // Cargas de propuestas o solicitudes: no se pregunta el lote línea a
    // línea; GrabarTraspaso exige que esté.
    property CargandoLineas: Boolean read FCargandoLineas
      write FCargandoLineas;
    property IdentidadSesion: TIdentidadSesion read GetIdentidadSesion;
    property Modo: TModoTraspaso read FModo write FModo;
    property IdPropuesta: Int64 read FIdPropuesta;
    property IdRecuentoApp: Int64 read FIdRecuentoApp;
    procedure PrepararNuevo(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                            ACaja: string; AFecha: TDateTime);
    // El próximo GrabarTraspaso confirmará esta propuesta de traspaso en
    // su misma transacción. PrepararNuevo la desvincula.
    procedure VincularPropuesta(AIdPropuesta: Int64);
    // FZ-ISSUE-351: el próximo GrabarTraspaso referencia este traspaso de
    // la app (serie RA) y se niega si ya hay otra operación con él.
    // PrepararNuevo lo desvincula.
    procedure VincularRecuentoApp(AIdRecuento: Int64);
    // Operación de caja que ya recogió el traspaso AIdRecuento de la app
    // desde AAlmacen; vacío si ninguna.
    function OperacionRecuentoApp(const AEmpresa, AAlmacen: string;
      AIdRecuento: Int64): string;
    // Artículo y descripción de un SKU activo.
    function DatosSkuTraspaso(const ASku: string;
      out ADatos: TDatosSkuTraspaso): Boolean;
    // EAN -> SKU de las lecturas del móvil, sobre esta conexión.
    function CrearResolutorSkuRecuento: IResolutorSkuRecuento;
    // Cómo queda la propuesta vinculada al grabar (TRASLADADO, por omisión,
    // o TRASLADADO PARCIAL, que la deja abierta con lo que falte).
    procedure EstablecerEstadoPropuestaAlGrabar(const AEstado: string);
    // Propuestas de la distribución entre tiendas, sobre esta conexión.
    function CrearRepositorioPropuestas: IRepositorioDistribucionTiendas;
    // Última referencia de documento grabada (tipo, serie y número).
    function UltimoDocumentoGrabado: TContextoGrabacionTraspaso;
    function ObtenerCosteMedio(const ASku, AAlmacen: string): Currency;
    function ObtenerStock(const ASku, AAlmacen: string): Double;
    // FZ-ISSUE-324: unidad (TIPO_CANTIDAD_ART), sus decimales y si es de
    // la magnitud UNIDAD; desconocida si el artículo o la unidad no existen
    function UnidadArticulo(
      const ACodigoArticulo: string): TUnidadLineaTicketTraspaso;
    // Devuelve el detalle de las lineas que superan el stock del almacen.
    // Vacio indica que todas disponen de stock suficiente.
    function ObtenerAvisoStockOrigen(const AAlmacenOrigen: string): string;
    // Graba el traspaso directo: par salida+entrada por línea + operación
    // de caja TR/AT, todo en una transacción. Devuelve el nº de operación.
    function GrabarTraspaso(const AAlmacenDestino: string;
                            out ANumOperacion: string;
                            const ANumSolicitud: string = '';
                            const ASerieSolicitud: string = ''): Boolean;
    // --- Transito en dos pasos (fza_traspasos_transito, FZ-ISSUE-215) ---
    // Almacenes TRANSITO activos (furgonetas, agencias): destino de una
    // carga en el traspaso directo.
    function ListarAlmacenesTransito: TAlmacenesDestinoTraspaso;
    function EsAlmacenTransito(const AAlmacen: string): Boolean;
    // Destino propuesto por el almacen de transito (DESTINO_ACTUAL_ALM).
    // Antes de GrabarTraspaso hacia un transito: destino final de la carga.
    procedure EstablecerDestinoFinalTransito(const AAlmacen: string);
    // Numero de cargas pendientes de recibir en AAlmacen (boton
    // «Recepcionar (n)» del destino).
    function ContarCargasTransitoPendientes(const AAlmacen: string): Integer;
    // Propuestas de distribucion con origen en AAlmacen que caja aun puede
    // traspasar (boton «Confirmar propuesta», visible solo si hay alguna).
    function ContarPropuestasPendientesOrigen(const AAlmacen: string): Integer;
    // Solicitudes PENDIENTE que piden a AAlmacen (boton «Atender
    // solicitudes») y que AAlmacen pidio a otros (boton «Mis peticiones»).
    function ContarSolicitudesPendientesAtender(
      const AAlmacen: string): Integer;
    function ContarMisPeticionesPendientes(const AAlmacen: string): Integer;
    // FZ-ISSUE-351: el almacen ha hecho alguna peticion (Mis peticiones
    // completo); sin ninguna se muestra en pequeño.
    function ExistenMisPeticiones(const AAlmacen: string): Boolean;
    // Cargas pendientes de recibir en AAlmacen. El llamante lo libera.
    function QueryCargasTransitoPendientes(const AAlmacen: string): TDataSet;
    // Recibe en bloque las cargas indicadas en el almacen y caja de la
    // cabecera: un traspaso transito -> propio por carga. Devuelve los
    // numeros de operacion grabados.
    function RecibirCargasTransito(const AIds: TArray<Int64>): TArray<string>;
    // --- Cargas con problemas (FZ-ISSUE-256 y 257) ---
    // Lineas de una carga, con todo recibido: la pantalla reparte cada una
    // entre recibido, deteriorado y perdido.
    function LineasCargaTransito(AId: Int64): TLineasRecepcionTransito;
    // Almacenes de taras de la empresa de la caja; primero el que cuelga
    // de su almacen.
    function ListarAlmacenesTaras: TAlmacenesDestinoTraspaso;
    // Recibe una carga con el reparto indicado: lo recibido entra en el
    // almacen de la caja, lo deteriorado en AAlmacenTaras y lo perdido
    // sale del transito sin entrar en ninguno. Deja un apunte por linea
    // con incidencia. Devuelve las operaciones grabadas.
    function RecibirCargaTransitoConIncidencias(AId: Int64;
      const AReparto: TLineasRecepcionTransito;
      const AAlmacenTaras: string): TArray<string>;
    // Cargas pendientes que salieron de AAlmacen (el origen las puede
    // desbloquear). El llamante libera el dataset.
    function ContarCargasTransitoEnviadas(const AAlmacen: string): Integer;
    function QueryCargasTransitoEnviadas(const AAlmacen: string): TDataSet;
    // Desbloqueo de una carga pendiente desde la caja del origen, con
    // motivo obligatorio. Devolver y dar por perdida devuelven el numero
    // de operacion.
    function DevolverCargaTransito(AId: Int64;
      const AMotivo: string): string;
    function DarPorPerdidaCargaTransito(AId: Int64;
      const AMotivo: string): string;
    procedure CambiarDestinoCargaTransito(AId: Int64;
      const ANuevoDestino, AMotivo: string);
    // Apuntes de perdida y deterioro de las cargas que salieron de
    // AAlmacen o iban a el, del mas reciente al mas antiguo. El
    // llamante libera el dataset.
    function QueryIncidenciasTransito(const AAlmacen: string): TDataSet;
    // Referencia de la reclamacion al transportista o al seguro.
    procedure AnotarReclamacionIncidenciaTransito(AId: Int64;
      const AReferencia: string);
    // --- Ciclo de solicitudes (fza_traspasos_solicitudes) ---
    // Solicitar: graba la petición (origen = a quién pido) en estado
    // PENDIENTE, sin mover stock.
    function GrabarSolicitud(const AAlmacenOrigen: string;
                             out ANumero, ASerie: string): Boolean;
    procedure CargarVentasReposicion(
      const ALineas: TLineasVentaReposicion);
    // FZ-ISSUE-411: con AComoSolicitud la reposición nace como una
    // solicitud corriente (MANUAL, PENDIENTE) que el origen atiende; sin
    // ella es informativa (AUTO, REPOSICION). El intervalo de ventas se
    // guarda en los dos casos.
    function GrabarReposicionAuto(
      const AAlmacenOrigen: string;
      const ADesde, AHasta: TDateTime;
      AComoSolicitud: Boolean;
      out ANumero, ASerie: string): Boolean;
    // Atender: lista las solicitudes pendientes que me tocan (yo, origen).
    procedure CargarSolicitudesPendientes(AItems, ACodigos: TStrings);
    // Dataset para el modal de solicitudes abiertas. El llamante lo libera.
    function QuerySolicitudesAbiertas: TDataSet;
    // Historico de MIS peticiones (yo soy el destino que pide), todos los
    // estados, para saber si se han servido/denegado, mas las que me pidieron
    // y denegue entera o en parte. El llamante lo libera.
    function QueryMisPeticiones(const APropio: string): TDataSet;
    // Detalle maestro/detalle de los articulos de una solicitud. El llamante
    // libera el dataset devuelto.
    function QueryLineasSolicitud(
      AMaestro: TDataSource): TDataSet;
    // Carga una solicitud pendiente en cabecera/líneas para servirla.
    function CargarSolicitud(const ANumero, ASerie: string): Boolean;
    // Cierra (estado CERRADA) la solicitud cargada aunque queden lineas sin
    // atender. Devuelve False si no hay solicitud cargada.
    function CerrarSolicitud: Boolean;
    // Resuelve la solicitud cargada sin mover stock (usa cdsLineas: CANTIDAD y
    // MOTIVO por linea). Denegacion total/parcial con motivo; no crea traspaso.
    function GrabarDenegacion: Boolean;
    // Valida el empleado responsable por su código o diminutivo de ticket.
    function ValidarEmpleado(const ABusqueda: string;
                             out ACodigo, ANombre: string): Boolean;
  end;

// FZ-ISSUE-325: almacén del que salen Stock Origen y Coste de las líneas.
// Al solicitar o reponer sirve el almacén elegido en el selector (la
// cabecera lleva el propio, que es quien recibe); en traspaso y al atender
// sirve el propio.
function AlmacenStockLineasTraspaso(AModo: TModoTraspaso;
  const APropio, ASeleccionado: string): string;

// FZ-ISSUE-332: SELECT de la serie de un documento de traspaso (TR, TA,
// pérdida en tránsito) con :EMP, :TIPO, :ALM y :CAJA. Prefiere la de la
// caja, luego la del almacén y la marcada por defecto, y descarta las
// series que la empresa usa en facturas (FC, VE, DV): un traspaso nunca
// comparte serie y número con una factura. Sin fila, el llamante usa el
// propio tipo de documento como serie.
function SqlSerieDocumentoTraspaso: string;

implementation

{$R *.dfm}

uses
  inLibTrazabilidad, inLibMsgTrazabilidad,
  UniDataMovimientosLote,
  inLibMsgCaja,
  inLibMsgDistribucionTiendas,
  inLibDocumentosTrabajoEstados,
  UniDataDistribucionTiendasRepositorio,
  inLibPrestaShopColaSenal,
  UniDataMovimientosAlmacenRecalculo,
  inLibTraspasoSolicitudAtencion,
  UniDataResolutorSkuRecuento,
  inLibLineaSku, inLibArticulosAtributosIntf,
  UniDataArticulosAtributosRepositorio;

resourcestring
  SErrorCantidadLineaStockTraspaso =
    'La cantidad de %s (%s) supera el stock del origen (%s).';
  SDetalleStockTraspasoInsuficiente =
    '  %s: pides %s, hay %s'#13#10;
  SDireccionPeticionEnviada =
    'Enviada';
  SDireccionPeticionRecibida =
    'Recibida';

constructor TdmTraspaso.Create(
  AOwner: TComponent;
  AConexion: TUniConnection);
var
  ProveedorContexto: IProveedorContextoSesion;
begin
  FConexion := AConexion;
  FContextoSesion := nil;
  if Supports(AOwner, IProveedorContextoSesion, ProveedorContexto) then
    FContextoSesion := ProveedorContexto.ContextoSesion;
  inherited Create(AOwner);
end;

function SqlSerieDocumentoTraspaso: string;
begin
  Result :=
    'SELECT S.EMPSER FROM vi_empresas_series S' +
    ' WHERE S.CODIGO_EMP_EMPSER = :EMP AND S.TIPO_DOC_EMPSER = :TIPO' +
    '   AND (S.CODIGO_ALM_EMPSER = :ALM OR S.CODIGO_ALM_EMPSER IS NULL' +
    '        OR S.CODIGO_ALM_EMPSER = '''')' +
    '   AND (S.CODIGO_CAJA_EMPSER = :CAJA OR S.CODIGO_CAJA_EMPSER IS NULL' +
    '        OR S.CODIGO_CAJA_EMPSER = '''')' +
    '   AND NOT EXISTS (SELECT 1 FROM vi_empresas_series F' +
    '                    WHERE F.CODIGO_EMP_EMPSER = S.CODIGO_EMP_EMPSER' +
    '                      AND F.EMPSER = S.EMPSER' +
    '                      AND F.TIPO_DOC_EMPSER IN' +
    '                          (''FC'', ''VE'', ''DV''))' +
    ' ORDER BY (S.CODIGO_CAJA_EMPSER = :CAJA) DESC,' +
    '          (S.CODIGO_ALM_EMPSER = :ALM) DESC,' +
    '          S.ESDEFECTO_EMPSER DESC LIMIT 1';
end;

// FZ-ISSUE-628: serie de una solicitud de traspaso (TS) con :EMP, :ALM y
// :CAJA. Mismo orden que la del traspaso (caja, almacén, por defecto). La
// solicitud vive en su propia tabla y no se graba como operación de caja:
// no choca con las facturas, así que no se descartan sus series.
function SqlSerieSolicitudTraspaso: string;
begin
  Result :=
    'SELECT S.EMPSER FROM vi_empresas_series S' +
    ' WHERE S.CODIGO_EMP_EMPSER = :EMP' +
    '   AND S.TIPO_DOC_EMPSER = ''TS''' +
    '   AND (S.CODIGO_ALM_EMPSER = :ALM OR S.CODIGO_ALM_EMPSER IS NULL' +
    '        OR S.CODIGO_ALM_EMPSER = '''')' +
    '   AND (S.CODIGO_CAJA_EMPSER = :CAJA OR S.CODIGO_CAJA_EMPSER IS NULL' +
    '        OR S.CODIGO_CAJA_EMPSER = '''')' +
    '   AND (S.FECHA_DESDE_EMPSER IS NULL' +
    '        OR S.FECHA_DESDE_EMPSER <= CURDATE())' +
    '   AND (S.FECHA_HASTA_EMPSER IS NULL' +
    '        OR S.FECHA_HASTA_EMPSER >= CURDATE())' +
    '   AND IFNULL(S.EMPSER, '''') <> ''''' +
    ' ORDER BY (S.CODIGO_CAJA_EMPSER = :CAJA) DESC,' +
    '          (S.CODIGO_ALM_EMPSER = :ALM) DESC,' +
    '          S.ESDEFECTO_EMPSER DESC, S.EMPSER LIMIT 1';
end;

function AlmacenStockLineasTraspaso(AModo: TModoTraspaso;
  const APropio, ASeleccionado: string): string;
begin
  if AModo in [mtSolicitar, mtReposicion] then
    Result := ASeleccionado
  else
    Result := APropio;
end;

function TdmTraspaso.GetIdentidadSesion: TIdentidadSesion;
begin
  if not Assigned(FContextoSesion) then
    raise Exception.Create(SErrorContextoSesionTraspasoNoConfigurado);
  Result := FContextoSesion.Identidad;
end;

procedure TdmTraspaso.DataModuleCreate(Sender: TObject);
begin
  qryAux.Connection := FConexion;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
  cdsLineas.OnNewRecord := cdsLineasNewRecord;
  cdsLineas.BeforePost := cdsLineasBeforePost;
  cdsLineas.AfterPost := cdsLineasAfterPost;
end;

type
  // Series de las demás líneas del traspaso, que viven en cdsLineas.
  TLecturaTrazabilidadTraspaso = class(TInterfacedObject,
    ILecturaTrazabilidadArticulo)
  private
    FInterna: ILecturaTrazabilidadArticulo;
    FLineas: TClientDataSet;
  public
    constructor Create(const AInterna: ILecturaTrazabilidadArticulo;
      ALineas: TClientDataSet);
    function Leer(const ACodigoArticulo: string): TTrazabilidadArticulo;
    function LotesOtrasLineas(const ATabla, ACampoSerie, ACampoNumero,
      ACampoLinea, ACampoLote, ASerie, ANumero, ALinea: string):
      TArray<string>;
  end;

constructor TLecturaTrazabilidadTraspaso.Create(
  const AInterna: ILecturaTrazabilidadArticulo; ALineas: TClientDataSet);
begin
  inherited Create;
  if not Assigned(AInterna) then
    raise EArgumentNilException.Create('AInterna');
  FInterna := AInterna;
  FLineas := ALineas;
end;

function TLecturaTrazabilidadTraspaso.Leer(
  const ACodigoArticulo: string): TTrazabilidadArticulo;
begin
  Result := FInterna.Leer(ACodigoArticulo);
end;

function TLecturaTrazabilidadTraspaso.LotesOtrasLineas(const ATabla,
  ACampoSerie, ACampoNumero, ACampoLinea, ACampoLote, ASerie, ANumero,
  ALinea: string): TArray<string>;
var
  oClon: TClientDataSet;
  sLote: string;
begin
  // La línea actual se salta por su posición (en inserción aún no está en
  // el clon); la tabla y la clave del documento no aplican aquí.
  Result := [];
  oClon := TClientDataSet.Create(nil);
  try
    oClon.CloneCursor(FLineas, True);
    oClon.First;
    while not oClon.Eof do
    begin
      sLote := Trim(oClon.FieldByName(ACampoLote).AsString);
      if (sLote <> '') and
         ((FLineas.State = dsInsert) or (oClon.RecNo <> FLineas.RecNo)) then
        Result := Result + [sLote];
      oClon.Next;
    end;
  finally
    FreeAndNil(oClon);
  end;
end;

destructor TdmTraspaso.Destroy;
begin
  FreeAndNil(FLotesLineas);
  FreeAndNil(FConsultaUnidad);
  FreeAndNil(FUnidadesArticulo);
  inherited;
end;

function TdmTraspaso.UnidadArticulo(
  const ACodigoArticulo: string): TUnidadLineaTicketTraspaso;
var
  sClave: string;
begin
  Result := UnidadLineaTicketDesconocida;
  sClave := UpperCase(Trim(ACodigoArticulo));
  if sClave <> '' then
  begin
    if FUnidadesArticulo = nil then
      FUnidadesArticulo :=
        TDictionary<string, TUnidadLineaTicketTraspaso>.Create;
    if not FUnidadesArticulo.TryGetValue(sClave, Result) then
    begin
      // Consulta propia: se llama desde el BeforePost de las líneas, que
      // puede ocurrir mientras qryAux recorre otra consulta
      if FConsultaUnidad = nil then
      begin
        FConsultaUnidad := TUniQuery.Create(nil);
        FConsultaUnidad.Connection := FConexion;
        FConsultaUnidad.SQL.Text :=
          'SELECT A.TIPO_CANTIDAD_ART, U.DECIMALES_UNIMED,' +
          '       U.MAGNITUD_UNIMED' +
          '  FROM fza_articulos A' +
          '  LEFT JOIN fza_unidades_medida U' +
          '    ON U.CODIGO_UNIMED = A.TIPO_CANTIDAD_ART' +
          ' WHERE A.CODIGO_ART_ART = :ART';
      end;
      FConsultaUnidad.ParamByName('ART').AsString := Trim(ACodigoArticulo);
      FConsultaUnidad.Open;
      try
        if (not FConsultaUnidad.IsEmpty) and
           not FConsultaUnidad.FieldByName('DECIMALES_UNIMED').IsNull then
        begin
          Result.Codigo :=
            FConsultaUnidad.FieldByName('TIPO_CANTIDAD_ART').AsString;
          Result.Decimales :=
            FConsultaUnidad.FieldByName('DECIMALES_UNIMED').AsInteger;
          Result.EsUnidades := SameText(
            FConsultaUnidad.FieldByName('MAGNITUD_UNIMED').AsString,
            'UNIDAD');
        end;
      finally
        FConsultaUnidad.Close;
      end;
      FUnidadesArticulo.Add(sClave, Result);
    end;
  end;
end;

procedure TdmTraspaso.CompletarUnidadLinea;
var
  rUnidad: TUnidadLineaTicketTraspaso;
begin
  // Se recalcula en cada grabación: el artículo de la línea puede cambiar
  rUnidad := UnidadArticulo(cdsLineas.FieldByName('CODIGO_ART').AsString);
  cdsLineas.FieldByName('UNIDAD').AsString := rUnidad.Codigo;
  if rUnidad.Decimales < 0 then
    cdsLineas.FieldByName('DECIMALES_UNIDAD').Clear
  else
    cdsLineas.FieldByName('DECIMALES_UNIDAD').AsInteger := rUnidad.Decimales;
  cdsLineas.FieldByName('ESUNIDADES').AsString :=
    IfThen(rUnidad.EsUnidades, 'S', 'N');
end;

procedure TdmTraspaso.ConfigurarLotesLineas(
  const AConfig: TConfiguracionLotesLineas);
begin
  FreeAndNil(FLotesLineas);
  if AConfig.Activacion.AlgunModoActivo then
    FLotesLineas := TLotesLineasDocumento.Create(AConfig);
end;

function TdmTraspaso.DocumentoLotes: TDocumentoLineaLote;
begin
  // El número del traspaso se asigna al grabar: aún no lo hay.
  Result := Default(TDocumentoLineaLote);
  Result.TipoDocumento := 'TR';
  Result.CodigoAlmacen :=
    Trim(cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString);
end;

function TdmTraspaso.LotesLineasActivos: Boolean;
begin
  // Solo lo que sale del origen ahora: el traspaso directo y atender una
  // solicitud. Pedir (solicitud, reposición) va sin lote.
  Result := Assigned(FLotesLineas) and (FModo in [mtTraspaso, mtAtender]);
end;

procedure TdmTraspaso.cdsLineasBeforePost(DataSet: TDataSet);
begin
  if Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) = '' then
    cdsLineas.FieldByName('CANTIDAD').AsFloat := 1;
  if not FCargandoLineas then
    ValidarCantidadLineaActual;
  CompletarUnidadLinea;
  if LotesLineasActivos and not FCargandoLineas then
    FLotesLineas.AntesDePostLinea(cdsLineas, DocumentoLotes);
end;

procedure TdmTraspaso.ValidarCantidadLineaActual;
const
  TOLERANCIA_CANTIDAD_LINEA = 0.0000005;
var
  sSku: string;
  rCantidad, rStock: Double;
begin
  sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
  if (FModo in [mtTraspaso, mtAtender]) and (sSku <> '') and
     not cdsLineas.FieldByName('STOCK_ORIGEN').IsNull then
  begin
    rCantidad := cdsLineas.FieldByName('CANTIDAD').AsFloat;
    rStock := cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat;
    if (rCantidad > 0) and
       (rCantidad - rStock > TOLERANCIA_CANTIDAD_LINEA) then
      raise EValidacionTraspaso.CreateFmt(SErrorCantidadLineaStockTraspaso,
        [sSku, FormatFloat('0.######', rCantidad),
         FormatFloat('0.######', rStock)]);
  end;
end;

procedure TdmTraspaso.cdsLineasAfterPost(DataSet: TDataSet);
begin
  if LotesLineasActivos and not FCargandoLineas then
    FLotesLineas.DespuesDePostLinea;
end;

procedure TdmTraspaso.ElegirLoteLinea;
begin
  if LotesLineasActivos and cdsLineas.Active and not cdsLineas.IsEmpty then
    FLotesLineas.ElegirLote(cdsLineas, DocumentoLotes);
end;

function TdmTraspaso.EnvolverLecturaTrazabilidad(
  const ALectura: ILecturaTrazabilidadArticulo):
  ILecturaTrazabilidadArticulo;
begin
  Result := TLecturaTrazabilidadTraspaso.Create(ALectura, cdsLineas);
end;

// Antes de grabar: cada línea lleva el lote o la serie que pide su artículo
// (las cargadas de una propuesta o solicitud no se preguntaron) y una serie
// no sale dos veces.
procedure TdmTraspaso.ValidarLotesLineas;
var
  aLineas: TArray<TLineaLoteGrabada>;
  dicModos: TDictionary<string, TModoTrazabilidad>;
  lstSeries: TStringList;
  oClon: TClientDataSet;
  oModo: TModoTrazabilidad;
  rConfig: TConfiguracionLotesLineas;
  rLinea: TLineaLoteGrabada;
  sError: string;
begin
  if LotesLineasActivos then
  begin
    rConfig := FLotesLineas.Configuracion;
    aLineas := [];
    sError := '';
    dicModos := TDictionary<string, TModoTrazabilidad>.Create;
    lstSeries := TStringList.Create;
    oClon := TClientDataSet.Create(nil);
    try
      lstSeries.CaseSensitive := False;
      oClon.CloneCursor(cdsLineas, True);
      oClon.First;
      while not oClon.Eof do
      begin
        rLinea := Default(TLineaLoteGrabada);
        rLinea.Linea := Trim(oClon.FieldByName('LINEA').AsString);
        if rLinea.Linea = '' then
          rLinea.Linea := IntToStr(oClon.RecNo);
        rLinea.Articulo := Trim(oClon.FieldByName('CODIGO_ART').AsString);
        rLinea.Lote := Trim(oClon.FieldByName('LOTE').AsString);
        if not oClon.FieldByName('FECHA_CADUCIDAD').IsNull then
          rLinea.FechaCaducidad :=
            Trunc(oClon.FieldByName('FECHA_CADUCIDAD').AsDateTime);
        rLinea.Cantidad := oClon.FieldByName('CANTIDAD').AsFloat;
        aLineas := aLineas + [rLinea];
        if (rLinea.Articulo <> '') and (rLinea.Lote <> '') then
        begin
          if not dicModos.TryGetValue(UpperCase(rLinea.Articulo), oModo) then
          begin
            oModo := rConfig.Activacion.ModoEfectivo(
              rConfig.Lectura.Leer(rLinea.Articulo).Modo);
            dicModos.Add(UpperCase(rLinea.Articulo), oModo);
          end;
          if (oModo = mtSerie) and (sError = '') then
          begin
            if lstSeries.IndexOf(rLinea.Lote) >= 0 then
              sError := Format(SErrorSerieRepetidaDocumento, [rLinea.Lote])
            else
              lstSeries.Add(rLinea.Lote);
          end;
        end;
        oClon.Next;
      end;
    finally
      FreeAndNil(oClon);
      FreeAndNil(lstSeries);
      FreeAndNil(dicModos);
    end;
    if sError = '' then
      sError := ValidarLotesLineasGrabadas(aLineas, rConfig.Activacion,
        rConfig.Lectura, False);
    if sError <> '' then
      raise EValidacionTraspaso.Create(sError);
  end;
end;

procedure TdmTraspaso.ConfigurarEstructuraCabecera;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsCabecera.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsCabecera.Active then
    cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.IndexDefs.Clear;
  Add('CODIGO_EMP', ftString, 20);
    Add('CODIGO_ALM_ORIGEN', ftString, 10);
    Add('CODIGO_ALM_DESTINO', ftString, 10);
    Add('CODIGO_CAJA', ftString, 10);
    Add('CODIGO_EMPLEADO', ftString, 20);
    Add('NUMERO_SOL', ftString, 20);
    Add('SERIE_SOL', ftString, 20);
    Add('FECHA', ftDateTime, 0);
    Add('CONTADOR_LINEAS', ftInteger, 0);
  Add('TOTAL', ftCurrency, 0);
  cdsCabecera.CreateDataSet;
end;

procedure TdmTraspaso.ConfigurarEstructuraLineas;
  procedure Add(const ANombre: string; ATipo: TFieldType;
    ATamano: Integer = 0; ARequerido: Boolean = False);
  begin
    cdsLineas.FieldDefs.Add(ANombre, ATipo, ATamano, ARequerido);
  end;
begin
  if cdsLineas.Active then
    cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.IndexDefs.Clear;
  Add('LINEA', ftString, 4);
    Add('CODIGO_ART', ftString, 20);
    Add('CODIGO_UNIDAD', ftString, 50);
    Add('DESCRIPCION', ftString, 100);
    Add('NUM_ATRIBUTOS', ftInteger, 0);
    Add('ATTR1_VALOR', ftString, 50);
    Add('ATTR2_VALOR', ftString, 50);
    Add('ATTR3_VALOR', ftString, 50);
    Add('ATTR4_VALOR', ftString, 50);
    Add('ATTR5_VALOR', ftString, 50);
    Add('ATTR1_NOMBRE', ftString, 50);
    Add('ATTR2_NOMBRE', ftString, 50);
    Add('ATTR3_NOMBRE', ftString, 50);
    Add('ATTR4_NOMBRE', ftString, 50);
    Add('ATTR5_NOMBRE', ftString, 50);
    Add('CANTIDAD', ftFloat, 0);
    // CANTIDAD_PEDIDA: lo que se pidio (referencia al atender; CANTIDAD pasa a
    // ser lo que se sirve). MOTIVO: razon del rechazo si se deniega (sirve 0).
    Add('CANTIDAD_PEDIDA', ftFloat, 0);
    Add('PRECIO_COSTE', ftCurrency, 0);
    Add('TOTAL', ftCurrency, 0);
    Add('STOCK_ORIGEN', ftFloat, 0);
    Add('STOCK_DESTINO', ftFloat, 0);
    Add('CODIGO_PROVEEDOR', ftString, 20);
    Add('NOMBRE_PROVEEDOR', ftString, 200);
  Add('MOTIVO', ftString, 255);
  // F-LOTEC-017: lote o serie y su caducidad (vacíos sin trazabilidad).
  Add('LOTE', ftString, 50);
  Add('FECHA_CADUCIDAD', ftDate, 0);
  // FZ-ISSUE-324: unidad de medida del artículo (decimales de las
  // cantidades en la rejilla y en el ticket)
  Add('UNIDAD', ftString, 20);
  Add('DECIMALES_UNIDAD', ftInteger, 0);
  Add('ESUNIDADES', ftString, 1);
  cdsLineas.CreateDataSet;
  cdsLineas.FieldByName('STOCK_DESTINO').Alignment := taCenter;
  cdsLineas.FieldByName('STOCK_ORIGEN').Alignment := taCenter;
end;

procedure TdmTraspaso.DesempaquetarAtributosLinea(const ASku: string);
var
  aValores: TArray<string>;
  oLookup: IArticulosAtributosLookup;
  i: Integer;
begin
  oLookup := TRepositorioArticulosAtributos.Create(FConexion);
  aValores := ValoresLegiblesLineaSku(
    cdsLineas.FieldByName('CODIGO_ART').AsString, ASku, oLookup);
  cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger :=
    Min(Length(aValores), 5);
  for i := 1 to 5 do
    cdsLineas.FieldByName('ATTR' + IntToStr(i) + '_VALOR').AsString := '';
  for i := 0 to Min(High(aValores), 4) do
    cdsLineas.FieldByName('ATTR' + IntToStr(i + 1) + '_VALOR').AsString :=
      aValores[i];
end;

procedure TdmTraspaso.cdsLineasNewRecord(DataSet: TDataSet);
begin
  DataSet.FieldByName('CANTIDAD').AsFloat := 1;
end;

procedure TdmTraspaso.PrepararNuevo(AModo: TModoTraspaso; const AEmpresa,
                                    AAlmacen, ACaja: string; AFecha: TDateTime);
begin
  FModo := AModo;
  FIdPropuesta := 0;
  FIdRecuentoApp := 0;
  FDestinoFinalTransito := '';
  FEstadoPropuestaAlGrabar := ESTADO_PROPUESTA_TRASPASO_TRASLADADO;
  ConfigurarEstructuraCabecera;
  ConfigurarEstructuraLineas;
  cdsCabecera.Append;
  cdsCabecera.FieldByName('CODIGO_EMP').AsString := AEmpresa;
  // En mtTraspaso el origen es el propio; en mtSolicitar se invierte (origen
  // será otro almacén y el propio pasa a destino) — se ajusta desde el form.
  cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString := AAlmacen;
  cdsCabecera.FieldByName('CODIGO_CAJA').AsString := ACaja;
  cdsCabecera.FieldByName('FECHA').AsDateTime := AFecha;
  cdsCabecera.FieldByName('CONTADOR_LINEAS').AsInteger := 0;
  cdsCabecera.FieldByName('TOTAL').AsCurrency := 0;
  cdsCabecera.Post;
end;

function TdmTraspaso.CrearRepositorioPropuestas:
  IRepositorioDistribucionTiendas;
begin
  Result := CrearRepositorioDistribucionTiendasUniDAC(FConexion);
end;

procedure TdmTraspaso.VincularPropuesta(AIdPropuesta: Int64);
begin
  FIdPropuesta := AIdPropuesta;
  FEstadoPropuestaAlGrabar := ESTADO_PROPUESTA_TRASPASO_TRASLADADO;
end;

procedure TdmTraspaso.VincularRecuentoApp(AIdRecuento: Int64);
begin
  FIdRecuentoApp := AIdRecuento;
end;

function TdmTraspaso.OperacionRecuentoAppEn(AConsulta: TUniQuery;
  const AEmpresa, AAlmacen: string; AIdRecuento: Int64): string;
begin
  // Empresa y almacén primero: aprovechan IDX_OPCAJA_EMP_ALM_TIPO_FECHA.
  AConsulta.SQL.Text :=
    'SELECT NUMERO_OPERACION_OPCAJA FROM fza_caja_operaciones ' +
    ' WHERE CODIGO_EMP_OPCAJA = :EMP ' +
    '   AND CODIGO_ALM_OPCAJA = :ALM ' +
    '   AND SERIE_REF_ORIGEN_OPCAJA = :SERIE ' +
    '   AND NUMERO_REF_ORIGEN_OPCAJA = :NUMERO ' +
    ' LIMIT 1';
  AConsulta.ParamByName('EMP').AsString := AEmpresa;
  AConsulta.ParamByName('ALM').AsString := AAlmacen;
  AConsulta.ParamByName('SERIE').AsString := SERIE_REFERENCIA_RECUENTO_APP;
  AConsulta.ParamByName('NUMERO').AsString := IntToStr(AIdRecuento);
  AConsulta.Open;
  try
    Result := '';
    if not AConsulta.IsEmpty then
      Result := AConsulta.Fields[0].AsString;
  finally
    AConsulta.Close;
  end;
end;

function TdmTraspaso.OperacionRecuentoApp(const AEmpresa, AAlmacen: string;
  AIdRecuento: Int64): string;
begin
  Result := OperacionRecuentoAppEn(qryAux, AEmpresa, AAlmacen, AIdRecuento);
end;

// Dentro de la transacción del traspaso: si una caída dejó grabado el
// traspaso sin marcarlo en el servidor, no se graba otra vez.
procedure TdmTraspaso.ExigirRecuentoAppNoGrabado(QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso);
var
  sOperacion: string;
begin
  sOperacion := OperacionRecuentoAppEn(QryTrx, AContexto.Empresa,
    AContexto.AlmacenOrigen, FIdRecuentoApp);
  if sOperacion <> '' then
    raise EValidacionTraspaso.CreateFmt(SErrorTraspasoAppYaGrabado,
      [FIdRecuentoApp, sOperacion]);
end;

function TdmTraspaso.DatosSkuTraspaso(const ASku: string;
  out ADatos: TDatosSkuTraspaso): Boolean;
begin
  ADatos := Default(TDatosSkuTraspaso);
  qryAux.SQL.Text :=
    'SELECT S.CODIGO_ART_SKU, A.DESCRIPCION_ART ' +
    '  FROM fza_articulos_skus S ' +
    '  JOIN fza_articulos A ON A.CODIGO_ART_ART = S.CODIGO_ART_SKU ' +
    ' WHERE S.CODIGO_UNIDAD_SKU = :SKU AND S.ESACTIVO_SKU = ''S'' ' +
    ' LIMIT 1';
  qryAux.ParamByName('SKU').AsString := Trim(ASku);
  qryAux.Open;
  try
    Result := not qryAux.IsEmpty;
    if Result then
    begin
      ADatos.CodigoArticulo := qryAux.Fields[0].AsString;
      ADatos.Descripcion := qryAux.Fields[1].AsString;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.CrearResolutorSkuRecuento: IResolutorSkuRecuento;
begin
  Result := CrearResolutorSkuRecuentoUniDAC(FConexion);
end;

procedure TdmTraspaso.EstablecerEstadoPropuestaAlGrabar(
  const AEstado: string);
begin
  if not (SameText(AEstado, ESTADO_PROPUESTA_TRASPASO_TRASLADADO) or
          SameText(AEstado,
            ESTADO_PROPUESTA_TRASPASO_TRASLADADO_PARCIAL)) then
    raise EArgumentException.CreateFmt(
      'Estado de propuesta no válido al grabar: %s', [AEstado]);
  FEstadoPropuestaAlGrabar := AEstado;
end;

function TdmTraspaso.UltimoDocumentoGrabado: TContextoGrabacionTraspaso;
begin
  Result := FUltimoDocumentoGrabado;
end;

procedure TdmTraspaso.CargarVentasReposicion(
  const ALineas: TLineasVentaReposicion);
var
  iLinea: Integer;
begin
  ConfigurarEstructuraLineas;
  for iLinea := 0 to High(ALineas) do
  begin
    cdsLineas.Append;
    cdsLineas.FieldByName('LINEA').AsString :=
      Format('%.4d', [(iLinea + 1) * 10]);
    cdsLineas.FieldByName('CODIGO_ART').AsString :=
      ALineas[iLinea].CodigoArticulo;
    cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
      ALineas[iLinea].Sku;
    DesempaquetarAtributosLinea(ALineas[iLinea].Sku);
    cdsLineas.FieldByName('DESCRIPCION').AsString :=
      ALineas[iLinea].Descripcion;
    cdsLineas.FieldByName('CANTIDAD').AsFloat :=
      ALineas[iLinea].APedir;
    cdsLineas.FieldByName('CANTIDAD_PEDIDA').AsFloat :=
      ALineas[iLinea].APedir;
    cdsLineas.FieldByName('STOCK_DESTINO').AsFloat :=
      ALineas[iLinea].StockDestino;
    cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
      ALineas[iLinea].StockOrigen;
    cdsLineas.FieldByName('CODIGO_PROVEEDOR').AsString :=
      ALineas[iLinea].CodigoProveedor;
    cdsLineas.FieldByName('NOMBRE_PROVEEDOR').AsString :=
      ALineas[iLinea].NombreProveedor;
    cdsLineas.Post;
  end;
  if cdsCabecera.State = dsBrowse then
    cdsCabecera.Edit;
  cdsCabecera.FieldByName('CONTADOR_LINEAS').AsInteger := Length(ALineas);
  cdsCabecera.Post;
end;

function TdmTraspaso.TieneLineasReposicionPositivas: Boolean;
begin
  Result := False;
  cdsLineas.First;
  while not cdsLineas.Eof and not Result do
  begin
    Result := cdsLineas.FieldByName('CANTIDAD').AsFloat > 0;
    if not Result then
      cdsLineas.Next;
  end;
end;

function TdmTraspaso.ObtenerEmpresaAlmacen(const AAlmacen: string): string;
begin
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMP_ALM FROM fza_almacenes WHERE CODIGO_ALM_ALM = :ALM';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_EMP_ALM').AsString;
  finally
    qryAux.Close;
  end;
end;

// Empresa del almacen y si es un transito compartido (FZ-ISSUE-717): la
// marca solo puede estar en un almacen de transito.
function TdmTraspaso.LeerTransitoEmpresa(
  const AAlmacen: string): TTransitoEmpresa;
begin
  Result := Default(TTransitoEmpresa);
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMP_ALM, ESCOMPARTIDO_ALM FROM fza_almacenes ' +
    ' WHERE CODIGO_ALM_ALM = :ALM';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.Open;
  try
    if not qryAux.IsEmpty then
    begin
      Result.Empresa := qryAux.FieldByName('CODIGO_EMP_ALM').AsString;
      Result.EsCompartido := SameText(
        qryAux.FieldByName('ESCOMPARTIDO_ALM').AsString, 'S');
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerArticuloSku(const ASku: string): string;
begin
  // Un SKU es valido solo si existe (activo) en fza_articulos_skus. Asi se
  // bloquea grabar un SKU incompleto tipo 'ART/COLOR' al que le falta la talla
  // (existe 'ART/COLOR/TALLA' pero no 'ART/COLOR').
  qryAux.SQL.Text :=
    'SELECT CODIGO_ART_SKU FROM fza_articulos_skus' +
    ' WHERE CODIGO_UNIDAD_SKU = :SKU AND ESACTIVO_SKU = ''S'' LIMIT 1';
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_ART_SKU').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerArticuloSkuHistorico(
  const ASku: string): string;
begin
  qryAux.SQL.Text :=
    'SELECT CODIGO_ART_SKU FROM fza_articulos_skus' +
    ' WHERE CODIGO_UNIDAD_SKU = :SKU LIMIT 1';
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ''
    else
      Result := qryAux.FieldByName('CODIGO_ART_SKU').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerIdColorBasicoSolicitud(
  const AArticulo, AColor: string;
  out AIdColorBasico: Integer): Boolean;
var
  bInvalido: Boolean;
  iIdActual: Integer;
begin
  AIdColorBasico := 0;
  bInvalido := False;
  // El valor historico puede estar inactivo. Se conserva la prioridad de la
  // vista vi_atributos_sku_basico: articulo, conjunto y valor global.
  qryAux.SQL.Text :=
    'SELECT CASE' +
    '         WHEN AAB.CODIGO_ART_AAB IS NOT NULL THEN AAB.ID_ATB_AAB' +
    '         WHEN ACD.ID_ATB_ACD IS NOT NULL THEN ACD.ID_ATB_ACD' +
    '         ELSE AV.ID_ATB_AV' +
    '       END AS ID_ATB' +
    '  FROM fza_atributos_valores AV' +
    '  LEFT JOIN fza_articulos_atributos_basicos AAB' +
    '    ON AAB.CODIGO_ART_AAB = :ART' +
    '   AND AAB.ID_AV_AAB = AV.ID_AV' +
    '  LEFT JOIN fza_articulos_conjuntos_asign ACA' +
    '    ON ACA.CODIGO_ART_ACA = :ART' +
    '   AND ACA.ID_VA_ACA = AV.ID_VA_AV' +
    '  LEFT JOIN fza_atributos_conjuntos_det ACD' +
    '    ON ACD.ID_AC_ACD = ACA.ID_AC_ACA' +
    '   AND ACD.ID_AV_ACD = AV.ID_AV' +
    ' WHERE AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
    'AR452.CODIGO_ART_ART = :ART) AND EJ452.EJE_VA = ''F'')' +
    '   AND TRIM(AV.AV) = :COLOR';
  qryAux.ParamByName('ART').AsString := AArticulo;
  qryAux.ParamByName('COLOR').AsString := AColor;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      if qryAux.FieldByName('ID_ATB').IsNull then
        bInvalido := True
      else
      begin
        iIdActual := qryAux.FieldByName('ID_ATB').AsInteger;
        if AIdColorBasico = 0 then
          AIdColorBasico := iIdActual
        else if AIdColorBasico <> iIdActual then
          bInvalido := True;
      end;
      qryAux.Next;
    end;
    Result := (AIdColorBasico > 0) and not bInvalido;
  finally
    qryAux.Close;
  end;
  if not Result then
    AIdColorBasico := 0;
end;

function TdmTraspaso.BuscarSkuTcActivoUnico(
  const AArticulo, ATalla: string;
  AIdColorBasico: Integer): string;
var
  iCandidatos: Integer;
  sCandidato: string;
begin
  Result := '';
  iCandidatos := 0;
  sCandidato := '';
  qryAux.SQL.Text :=
    'SELECT DISTINCT SK.CODIGO_UNIDAD_SKU' +
    '  FROM fza_articulos_skus SK' +
    '  JOIN vi_atributos_sku_basico C' +
    '    ON C.CODIGO_UNIDAD_SKU = SK.CODIGO_UNIDAD_SKU' +
    '   AND C.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')' +
    '  JOIN fza_atributos_valores CAV' +
    '    ON CAV.ID_AV = C.ID_AV AND CAV.ESACTIVO_AV = ''S''' +
    '  JOIN fza_atributos_basicos B' +
    '    ON B.ID_ATB = C.ID_ATB_AV AND B.ESACTIVO_ATB = ''S''' +
    '  JOIN vi_atributos_sku_basico T' +
    '    ON T.CODIGO_UNIDAD_SKU = SK.CODIGO_UNIDAD_SKU' +
    '   AND T.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'')' +
    '  JOIN fza_atributos_valores TAV' +
    '    ON TAV.ID_AV = T.ID_AV AND TAV.ESACTIVO_AV = ''S''' +
    ' WHERE SK.CODIGO_ART_SKU = :ART' +
    '   AND SK.ESACTIVO_SKU = ''S''' +
    '   AND C.ID_ATB_AV = :ID_COLOR' +
    '   AND TRIM(T.VALOR_AV) = :TALLA' +
    ' ORDER BY SK.CODIGO_UNIDAD_SKU' +
    ' LIMIT 2';
  qryAux.ParamByName('ART').AsString := AArticulo;
  qryAux.ParamByName('ID_COLOR').AsInteger := AIdColorBasico;
  qryAux.ParamByName('TALLA').AsString := ATalla;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      Inc(iCandidatos);
      if iCandidatos = 1 then
        sCandidato := qryAux.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      qryAux.Next;
    end;
    if iCandidatos = 1 then
      Result := sCandidato;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ResolverSkuSolicitudActivo(
  const AArticulo, ASkuSolicitado: string): string;
var
  Partes: TArray<string>;
  iIdColorBasico: Integer;
  sArticulo, sArticuloSku, sSku: string;
begin
  Result := '';
  sArticulo := Trim(AArticulo);
  sSku := Trim(ASkuSolicitado);
  sArticuloSku := ObtenerArticuloSku(sSku);
  if sArticuloSku <> '' then
  begin
    if SameText(sArticuloSku, sArticulo) then
      Result := sSku;
  end
  else
  begin
    Partes := sSku.Split(['/']);
    if (Length(Partes) = 3) and SameText(Trim(Partes[0]), sArticulo) and
       ObtenerIdColorBasicoSolicitud(sArticulo, Trim(Partes[1]),
                                     iIdColorBasico) then
      Result := BuscarSkuTcActivoUnico(sArticulo, Trim(Partes[2]),
                                       iIdColorBasico);
  end;
end;

procedure TdmTraspaso.LimpiarLineasIncompletas;
var
  sArt, sSku, sArtSku: string;
begin
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sArt := Trim(cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // Linea en blanco / fantasma (sin articulo): se descarta en silencio.
    if sArt = '' then
      cdsLineas.Delete
    // Articulo tecleado pero SKU sin cerrar (falta color/talla): es un intento
    // real, no se graba a medias -> avisamos y abortamos.
    else if sSku = '' then
      raise EValidacionTraspaso.CreateFmt(
        SErrorSkuTraspasoIncompleto, [sArt, sSku])
    else
    begin
      sArtSku := ObtenerArticuloSku(sSku);
      if sArtSku = '' then
        raise EValidacionTraspaso.CreateFmt(
          SErrorSkuTraspasoNoDisponible, [sSku, sArt])
      else if not SameText(sArt, sArtSku) then
        raise EValidacionTraspaso.CreateFmt(
          SErrorArticuloSkuTraspasoNoCoincide,
          [sArt, sSku, sArtSku])
      else
        cdsLineas.Next;
    end;
  end;
end;

procedure TdmTraspaso.ValidarLineasReposicionAuto;
var
  sArt, sSku, sArtSku: string;
begin
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sArt := Trim(cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // El alta manual puede dejar la fila nueva sin usar. No debe impedir
    // emitir las lineas completas que ya estaban cargadas.
    if sArt = '' then
      cdsLineas.Delete
    else
    begin
      if cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
      begin
        if sSku = '' then
          raise EValidacionTraspaso.CreateFmt(
            SErrorSkuTraspasoIncompleto, [sArt, sSku]);
        sArtSku := ObtenerArticuloSkuHistorico(sSku);
        if sArtSku = '' then
          raise EValidacionTraspaso.CreateFmt(
            SErrorSkuTraspasoNoDisponible, [sSku, sArt])
        else if not SameText(sArt, sArtSku) then
          raise EValidacionTraspaso.CreateFmt(
            SErrorArticuloSkuTraspasoNoCoincide,
            [sArt, sSku, sArtSku]);
      end;
      cdsLineas.Next;
    end;
  end;
end;

// FZ-ISSUE-351: varias líneas del mismo SKU se suman antes de compararlas
// con su stock total, y las de un lote, además, con el stock de ese lote.
function TdmTraspaso.ObtenerAvisoStockOrigen(
  const AAlmacenOrigen: string): string;
begin
  Result := AvisoStockOrigenEnFecha(AAlmacenOrigen, 0);
end;

function TdmTraspaso.ObtenerStockEnFecha(
  const ASku, ALote, AAlmacen: string; AFecha: TDateTime): Double;
begin
  // No incluir existencias de entradas posteriores a la fecha de caja.
  qryAux.SQL.Text :=
    'SELECT COALESCE(SUM(CASE WHEN TIPO_MOV = ''E'' ' +
    ' THEN CANTIDAD_MOV ELSE -CANTIDAD_MOV END), 0) AS STK ' +
    ' FROM fza_movimientos_almacen ' +
    ' WHERE CODIGO_ALM_MOV = :ALM AND CODIGO_UNIDAD_MOV = :SKU ' +
    ' AND ESACTIVO_MOV = ''S'' ' +
    ' AND (FECHA_MOV IS NULL OR FECHA_MOV <= :FECHA)';
  if ALote <> '' then
    qryAux.SQL.Add(' AND COALESCE(LOTE_MOV, '''') = :LOTE');
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.ParamByName('FECHA').AsDateTime := AFecha;
  if ALote <> '' then
    qryAux.ParamByName('LOTE').AsString := ALote;
  qryAux.Open;
  try
    Result := qryAux.FieldByName('STK').AsFloat;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.AvisoStockOrigenEnFecha(
  const AAlmacenOrigen: string; AFecha: TDateTime): string;
var
  dicCantidades: TDictionary<string, Double>;
  lstClaves: TStringList;
  sClave, sSku, sLote, sFalta: string;
  dCant, dStock: Double;
  iSeparador: Integer;

  procedure Acumular(const AClave: string; ACantidad: Double);
  var
    dActual: Double;
  begin
    if not dicCantidades.TryGetValue(AClave, dActual) then
    begin
      dActual := 0;
      lstClaves.Add(AClave);
    end;
    dicCantidades.AddOrSetValue(AClave, dActual + ACantidad);
  end;

begin
  sFalta := '';
  if cdsLineas.State in [dsEdit, dsInsert] then
    cdsLineas.Post;
  dicCantidades := TDictionary<string, Double>.Create;
  lstClaves := TStringList.Create;
  try
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      sSku := Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
      sLote := Trim(cdsLineas.FieldByName('LOTE').AsString);
      dCant := cdsLineas.FieldByName('CANTIDAD').AsFloat;
      // La comprobacion historica suma solo lo que GrabarLineas mueve.
      // El aviso de stock actual conserva su comportamiento anterior.
      if (sSku <> '') and ((AFecha = 0) or (dCant > 0)) then
      begin
        Acumular(sSku, dCant);
        if sLote <> '' then
          Acumular(sSku + #9 + sLote, dCant);
      end;
      cdsLineas.Next;
    end;
    for sClave in lstClaves do
    begin
      dCant := dicCantidades[sClave];
      iSeparador := Pos(#9, sClave);
      if iSeparador = 0 then
      begin
        if AFecha > 0 then
          dStock := ObtenerStockEnFecha(sClave, '', AAlmacenOrigen, AFecha)
        else
          dStock := ObtenerStock(sClave, AAlmacenOrigen);
        if dCant > dStock then
          sFalta := sFalta + Format(SDetalleStockTraspasoInsuficiente,
            [sClave, FormatFloat('0.###', dCant),
             FormatFloat('0.###', dStock)]);
      end
      else
      begin
        sSku := Copy(sClave, 1, iSeparador - 1);
        sLote := Copy(sClave, iSeparador + 1, MaxInt);
        if AFecha > 0 then
          dStock := ObtenerStockEnFecha(sSku, sLote, AAlmacenOrigen, AFecha)
        else
          dStock := ObtenerStockLote(sSku, sLote, AAlmacenOrigen);
        if dCant > dStock then
          sFalta := sFalta + Format(SDetalleStockLoteTraspasoInsuficiente,
            [sSku, sLote, FormatFloat('0.###', dCant),
             FormatFloat('0.###', dStock)]) + sLineBreak;
      end;
    end;
  finally
    FreeAndNil(lstClaves);
    FreeAndNil(dicCantidades);
  end;
  if sFalta <> '' then
  begin
    Result := Format(SErrorStockTraspasoInsuficiente,
      [AAlmacenOrigen, sFalta]);
    if AFecha > 0 then
      Result := Result + sLineBreak +
        Format(SInfoFechaStockTraspaso, [DateTimeToStr(AFecha)]);
  end
  else
    Result := '';
end;

procedure TdmTraspaso.ValidarStockOrigen(const AAlmacenOrigen: string);
var
  sAviso: string;
begin
  sAviso := ObtenerAvisoStockOrigen(AAlmacenOrigen);
  if sAviso <> '' then
    raise EValidacionTraspaso.Create(sAviso);
end;

function TdmTraspaso.ValidarEmpleado(const ABusqueda: string;
                                     out ACodigo, ANombre: string): Boolean;
begin
  Result := False;
  ACodigo := '';
  ANombre := '';
  qryAux.SQL.Text :=
    'SELECT CODIGO_EMPL, DIMINUTIVO_TICKET_EMPL FROM fza_empleados' +
    ' WHERE (CODIGO_EMPL = :BUS OR DIMINUTIVO_TICKET_EMPL = :BUS)' +
    '   AND ESACTIVO_EMPL = ''S'' LIMIT 1';
  qryAux.ParamByName('BUS').AsString := ABusqueda;
  qryAux.Open;
  try
    if not qryAux.IsEmpty then
    begin
      ACodigo := qryAux.FieldByName('CODIGO_EMPL').AsString;
      ANombre := qryAux.FieldByName('DIMINUTIVO_TICKET_EMPL').AsString;
      Result := True;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerSerieDocumento(const AEmpresa, AAlmacen, ACaja,
                                           ATipoDoc: string): string;
begin
  // Serie configurada para este tipo de documento (prefiere la de la caja /
  // almacén; si no, la de empresa), nunca una de facturas (FZ-ISSUE-332).
  // Fallback: el propio tipo de documento.
  qryAux.SQL.Text := SqlSerieDocumentoTraspaso;
  qryAux.ParamByName('EMP').AsString := AEmpresa;
  qryAux.ParamByName('TIPO').AsString := ATipoDoc;
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('CAJA').AsString := ACaja;
  qryAux.Open;
  try
    if qryAux.IsEmpty then
      Result := ATipoDoc
    else
      Result := qryAux.FieldByName('EMPSER').AsString;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.SiguienteNumeroDocumento(const ASerie, ATipoDoc, AEmpresa,
                                              AUsuario: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := FConexion;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    SpTrx.Prepare;
    SpTrx.ParamByName('pserie').AsString := ASerie;
    SpTrx.ParamByName('pTipoDoc').AsString := ATipoDoc;
    SpTrx.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    SpTrx.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    SpTrx.Execute;
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    FreeAndNil(SpTrx);
  end;
end;

procedure TdmTraspaso.AsignarNumeroSolicitud(const AEmpresa, AAlmacen,
  ACaja: string; out ANumero, ASerie: string);
begin
  ASerie := '';
  qryAux.SQL.Text := SqlSerieSolicitudTraspaso;
  qryAux.ParamByName('EMP').AsString := AEmpresa;
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('CAJA').AsString := ACaja;
  qryAux.Open;
  try
    if not qryAux.IsEmpty then
      ASerie := Trim(qryAux.FieldByName('EMPSER').AsString);
  finally
    qryAux.Close;
  end;
  if ASerie = '' then
  begin
    // Sin serie TS configurada: serie fija y contador general, como antes.
    ANumero := ObtenerSiguienteContador(FConexion, 'TS',
      IdentidadSesion.Usuario);
    ASerie := 'TS';
  end
  else
    ANumero := SiguienteNumeroDocumento(ASerie, 'TS', AEmpresa,
      IdentidadSesion.Usuario);
end;

function TdmTraspaso.ObtenerCosteMedio(const ASku, AAlmacen: string): Currency;
begin
  // El coste es el PMP almacenado (PRECIO_MEDIO_STK), igual que usa el SP
  // PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT para valorar la salida y que muestra
  // la ficha del articulo. NO se recalcula con VALOR_TOTAL_STK (que puede
  // estar a 0 aunque el PMP exista). Con varios lotes: media ponderada por
  // cantidad; si no hay stock pero hay PMP guardado, se toma ese (MAX).
  qryAux.SQL.Text :=
    'SELECT CASE WHEN SUM(CANTIDAD_STK) > 0' +
    '            THEN SUM(PRECIO_MEDIO_STK * CANTIDAD_STK)' +
    '                 / SUM(CANTIDAD_STK)' +
    '            ELSE MAX(PRECIO_MEDIO_STK) END AS PMP ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    Result := qryAux.FieldByName('PMP').AsCurrency;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerStock(const ASku, AAlmacen: string): Double;
begin
  // Suma de todos los lotes del SKU en el almacen.
  qryAux.SQL.Text :=
    'SELECT COALESCE(SUM(CANTIDAD_STK),0) AS STK ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.Open;
  try
    Result := qryAux.FieldByName('STK').AsFloat;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ObtenerStockLote(
  const ASku, ALote, AAlmacen: string): Double;
begin
  qryAux.SQL.Text :=
    'SELECT COALESCE(SUM(CANTIDAD_STK),0) AS STK ' +
    '  FROM fza_articulos_stockactual ' +
    ' WHERE CODIGO_ALM_STK = :ALM AND CODIGO_UNIDAD_STK = :SKU ' +
    '   AND LOTE_STK = :LOTE';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.ParamByName('SKU').AsString := ASku;
  qryAux.ParamByName('LOTE').AsString := ALote;
  qryAux.Open;
  try
    Result := qryAux.FieldByName('STK').AsFloat;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.SiguienteOpCaja(const AEmpresa, AAlmacen, ACaja,
                                     AEmpleado: string): string;
var
  SpTrx: TUniStoredProc;
begin
  SpTrx := TUniStoredProc.Create(nil);
  try
    SpTrx.Connection := FConexion;
    SpTrx.StoredProcName := 'PRC_GET_NEXT_OP_CAJA';
    SpTrx.Params.CreateParam(ftString, 'pEmpresa', ptInput).AsString :=
      AEmpresa;
    SpTrx.Params.CreateParam(ftString, 'pAlmacen', ptInput).AsString :=
      AAlmacen;
    SpTrx.Params.CreateParam(ftString, 'pCaja', ptInput).AsString := ACaja;
    SpTrx.Params.CreateParam(ftString, 'pUsuario', ptInput).AsString :=
      AEmpleado;
    SpTrx.Params.CreateParam(ftString, 'pSerie', ptOutput).Size := 12;
    SpTrx.Params.CreateParam(ftString, 'pcont', ptOutput).Size := 20;
    SpTrx.Prepare;
    SpTrx.Execute;
    Result := SpTrx.ParamByName('pcont').AsString;
  finally
    FreeAndNil(SpTrx);
  end;
end;

function FechaCajaConHora(AFechaCaja: TDateTime): TDateTime;
begin
  if AFechaCaja > 0 then
    Result := AFechaCaja
  else
    Result := Now;
end;

function TdmTraspaso.InsertarMovimientoAlmacen(QryTrx: TUniQuery;
                          const ATipoDoc, ASerie, ANro, ALinea, AEmpresa,
                          AAlmacen, ACaja, AAlmacenContra, ATipoMov,
                          ASku: string; ACantidad: Double; ACoste: Currency;
                          const AUsuario: string; const AAlmacenDoc: string;
                          const ANumOperacion: string;
                          const ACodCliente: string;
                          const ACodArticulo: string;
                          AFechaMovimiento: TDateTime;
                          const ALote: string;
                          AFechaCaducidad: TDate): string;
var
  uspMov: TUniStoredProc;
  uspMovLote: TUniStoredProc;
  QryFecha: TUniQuery;
  sNumeroMov: string;
begin
  sNumeroMov := ObtenerSiguienteContador(FConexion, 'MV',
    IdentidadSesion.Usuario);
  Result := sNumeroMov;
  uspMovLote := nil;
  uspMov := TUniStoredProc.Create(nil);
  try
    uspMov.Connection := QryTrx.Connection;
    uspMov.StoredProcName := 'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    uspMov.Prepare;
    uspMov.ParamByName('p_NUMERO_MOV').AsString := sNumeroMov;
    uspMov.ParamByName('p_TIPO_DOC_MOV').AsString := ATipoDoc;
    uspMov.ParamByName('p_SERIE_DOC_MOV').AsString := ASerie;
    uspMov.ParamByName('p_NRO_DOC_MOV').AsString := ANro;
    uspMov.ParamByName('p_LINEA_MOV').AsString := ALinea;
    uspMov.ParamByName('p_CODIGO_EMPRESA_MOV').AsString := AEmpresa;
    uspMov.ParamByName('p_CODIGO_ALMACEN_MOV').AsString := AAlmacen;
    uspMov.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := ACaja;
    if Trim(AAlmacenContra) = '' then
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
    else
      uspMov.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').AsString :=
        AAlmacenContra;
    uspMov.ParamByName('p_CODIGO_UNIDAD_MOV').AsString := ASku;
    uspMov.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString := ATipoMov;
    uspMov.ParamByName('p_CANTIDAD_MOV').AsFloat := Abs(ACantidad);
    uspMov.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency := ACoste;
    uspMov.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency :=
      ACoste * Abs(ACantidad);
    uspMov.ParamByName('p_USUARIO').AsString := AUsuario;
    uspMov.ParamByName('p_ALMACEN_DOC').AsString := AAlmacenDoc;
    uspMov.ParamByName('p_NUMOP_DOC').AsString := ANumOperacion;
    uspMov.ParamByName('p_CODCLIENTE').AsString := ACodCliente;
    uspMov.ParamByName('p_CODARTICULO').AsString := ACodArticulo;
    // F-LOTEC-017: la serie o el lote viajan con su número y caducidad.
    uspMovLote := TUniStoredProc.Create(nil);
    EjecutarMovimientoConLote(uspMov, uspMovLote, ALote, AFechaCaducidad);
    if AFechaMovimiento > 0 then
    begin
      QryFecha := TUniQuery.Create(nil);
      try
        QryFecha.Connection := QryTrx.Connection;
        QryFecha.SQL.Text :=
          'UPDATE fza_movimientos_almacen ' +
          '   SET FECHA_MOV = :FECHA ' +
          ' WHERE NUMERO_MOV = :NUMERO';
        QryFecha.ParamByName('FECHA').AsDateTime :=
          FechaCajaConHora(AFechaMovimiento);
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
end;

procedure TdmTraspaso.InsertarOperacionCaja(QryTrx: TUniQuery;
                          const AEmpresa, AAlmacen, ACaja, ANumOperacion,
                          ATipoOp: string; AImporte: Currency;
                          AFechaOperacion: TDateTime;
                          const AEmpleado, AConcepto, ASerieOrigen,
                          ANroOrigen, AEmpresaContra, AAlmContra,
                          AEsTraspaso, ANroDoc, ASerieDoc: string);
var
  dtFechaOperacion: TDateTime;
begin
  dtFechaOperacion := FechaCajaConHora(AFechaOperacion);
  QryTrx.SQL.Text :=
    'INSERT INTO fza_caja_operaciones (' +
    '  CODIGO_EMP_OPCAJA, CODIGO_ALM_OPCAJA, CODIGO_CAJA_OPCAJA,' +
    '  NUMERO_FAC_OPCAJA, SERIE_FAC_OPCAJA,' +
    '  NUMERO_OPERACION_OPCAJA, TIPO_OPERACION_OPCAJA, IMPORTE_TOTAL_OPCAJA,' +
    '  FECHA_OPERACION_OPCAJA, FECHA_OP_DIA_OPCAJA, CODIGO_EMPLEADO_OPCAJA,' +
    '  CONCEPTO_GASTO_INGRESO_OPCAJA, SERIE_REF_ORIGEN_OPCAJA,' +
    '  NUMERO_REF_ORIGEN_OPCAJA, CODIGO_EMP_CONTRA_OPCAJA,' +
    '  CODIGO_ALM_CONTRA_OPCAJA, ESTRASPASO_OPCAJA, ESTADO_DEVOLUCION_OPCAJA,' +
    '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (' +
    '  :EMP, :ALM, :CAJA,' +
    '  NULLIF(:NRODOC, ''''), NULLIF(:SERIEDOC, ''''),' +
    '  :NUMOP, :TIPOOP, :IMPORTE, :FECHAOP, :FECHADIA,' +
    '  :EMPLEADO, NULLIF(:CONCEPTO, ''''), NULLIF(:SERIEORIG, ''''),' +
    '  NULLIF(:NROORIG, ''''), NULLIF(:EMPCONTRA, ''''),' +
    '  NULLIF(:ALMCONTRA, ''''), :ESTRASPASO, ''N'',' +
    '  :USUARIO, :USUARIO, NOW())';
  QryTrx.ParamByName('EMP').AsString := AEmpresa;
  QryTrx.ParamByName('ALM').AsString := AAlmacen;
  QryTrx.ParamByName('CAJA').AsString := ACaja;
  QryTrx.ParamByName('NUMOP').AsString := ANumOperacion;
  QryTrx.ParamByName('TIPOOP').AsString := ATipoOp;
  QryTrx.ParamByName('IMPORTE').AsCurrency := AImporte;
  QryTrx.ParamByName('FECHAOP').AsDateTime := dtFechaOperacion;
  QryTrx.ParamByName('FECHADIA').AsDateTime := Trunc(dtFechaOperacion);
  QryTrx.ParamByName('EMPLEADO').AsString := AEmpleado;
  QryTrx.ParamByName('CONCEPTO').AsString := AConcepto;
  QryTrx.ParamByName('SERIEORIG').AsString := ASerieOrigen;
  QryTrx.ParamByName('NROORIG').AsString := ANroOrigen;
  QryTrx.ParamByName('EMPCONTRA').AsString := AEmpresaContra;
  QryTrx.ParamByName('ALMCONTRA').AsString := AAlmContra;
  QryTrx.ParamByName('ESTRASPASO').AsString := AEsTraspaso;
  QryTrx.ParamByName('NRODOC').AsString := ANroDoc;
  QryTrx.ParamByName('SERIEDOC').AsString := ASerieDoc;
  // Auditoría con el usuario logueado; el empleado responsable va en EMPLEADO.
  QryTrx.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  QryTrx.Execute;
end;

function TdmTraspaso.CrearContextoGrabacionTraspaso(
  const AAlmacenDestino: string): TContextoGrabacionTraspaso;
begin
  Result.Empresa := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  Result.AlmacenOrigen := cdsCabecera.FieldByName(
    'CODIGO_ALM_ORIGEN').AsString;
  Result.AlmacenDestino := AAlmacenDestino;
  Result.Caja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.Empleado := cdsCabecera.FieldByName(
    'CODIGO_EMPLEADO').AsString;
  Result.FechaOperacion := cdsCabecera.FieldByName('FECHA').AsDateTime;
  if SameText(Result.AlmacenOrigen, Result.AlmacenDestino) then
    raise EValidacionTraspaso.Create(SErrorAlmacenesTraspasoCoincidentes);
  // FZ-ISSUE-717: lo que entra en un transito compartido sigue siendo de
  // la empresa que lo carga; la TA, si la hay, sera al descargar.
  Result.EmpresaContra := EmpresaEntradaTransito(Result.Empresa,
    LeerTransitoEmpresa(Result.AlmacenDestino));
  if (Result.EmpresaContra = '') or
     SameText(Result.EmpresaContra, Result.Empresa) then
    Result.TipoDocumento := 'TR'
  else
    Result.TipoDocumento := 'TA';
  if Trim(Result.EmpresaContra) <> '' then
    Result.EmpresaDestino := Result.EmpresaContra
  else
    Result.EmpresaDestino := Result.Empresa;
  Result.SerieDocumento := ObtenerSerieDocumento(Result.Empresa,
    Result.AlmacenOrigen, Result.Caja, Result.TipoDocumento);
  Result.NumeroDocumento := '';
  Result.NumeroOperacion := '';
end;

function TdmTraspaso.GrabarLineasTraspaso(
  QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso): Currency;
var
  sArticulo: string;
  sLinea: string;
  sSku: string;
  dCantidad: Double;
  cCoste: Currency;
  iLinea: Integer;
  sLote: string;
  dtCaducidad: TDate;
  aSalidas: TArray<string>;
begin
  iLinea := 0;
  aSalidas := nil;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    sSku := cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
    dCantidad := cdsLineas.FieldByName('CANTIDAD').AsFloat;
    if (Trim(sSku) <> '') and (dCantidad > 0) then
    begin
      Inc(iLinea, 10);
      sLinea := Format('%.4d', [iLinea]);
      sArticulo := cdsLineas.FieldByName('CODIGO_ART').AsString;
      cCoste := cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
      sLote := Trim(cdsLineas.FieldByName('LOTE').AsString);
      dtCaducidad := 0;
      if not cdsLineas.FieldByName('FECHA_CADUCIDAD').IsNull then
        dtCaducidad :=
          Trunc(cdsLineas.FieldByName('FECHA_CADUCIDAD').AsDateTime);
      aSalidas := aSalidas + [InsertarMovimientoAlmacen(QryTrx,
        AContexto.TipoDocumento, AContexto.SerieDocumento,
        AContexto.NumeroDocumento, sLinea, AContexto.Empresa,
        AContexto.AlmacenOrigen, AContexto.Caja, AContexto.AlmacenDestino,
        'S', sSku, dCantidad, cCoste, AContexto.Usuario,
        AContexto.AlmacenOrigen, AContexto.NumeroOperacion, '', sArticulo,
        AContexto.FechaOperacion, sLote, dtCaducidad)];
      InsertarMovimientoAlmacen(QryTrx, AContexto.TipoDocumento,
        AContexto.SerieDocumento, AContexto.NumeroDocumento, sLinea,
        AContexto.EmpresaDestino, AContexto.AlmacenDestino,
        AContexto.Caja, AContexto.AlmacenOrigen, 'E', sSku, dCantidad,
        cCoste, AContexto.Usuario, AContexto.AlmacenOrigen,
        AContexto.NumeroOperacion, '', sArticulo,
        AContexto.FechaOperacion, sLote, dtCaducidad);
    end;
    cdsLineas.Next;
  end;
  if iLinea = 0 then
    raise EValidacionTraspaso.Create(SErrorLineasTraspasoNoDisponibles);
  EncolarORecalcularMovimientosDocumento(FConexion,
    AContexto.TipoDocumento, AContexto.SerieDocumento,
    AContexto.NumeroDocumento, 'TRASPASO_CAJA', AContexto.Usuario);
  // Coste de las salidas tras el recálculo (PMP del origen).
  Result := TotalCosteMovimientos(QryTrx, aSalidas);
end;

function TdmTraspaso.TotalCosteMovimientos(QryTrx: TUniQuery;
  const ANumeros: TArray<string>): Currency;
var
  sMarcas: string;
  i: Integer;
begin
  Result := 0;
  if Length(ANumeros) > 0 then
  begin
    sMarcas := '';
    for i := 0 to High(ANumeros) do
    begin
      if i > 0 then
        sMarcas := sMarcas + ', ';
      sMarcas := sMarcas + ':M' + IntToStr(i);
    end;
    QryTrx.SQL.Text :=
      'SELECT IFNULL(SUM(TOTAL_COSTE_MOV), 0) AS TOTAL ' +
      '  FROM fza_movimientos_almacen ' +
      ' WHERE NUMERO_MOV IN (' + sMarcas + ')';
    for i := 0 to High(ANumeros) do
      QryTrx.ParamByName('M' + IntToStr(i)).AsString := ANumeros[i];
    QryTrx.Open;
    Result := QryTrx.FieldByName('TOTAL').AsCurrency;
    QryTrx.Close;
  end;
end;

procedure TdmTraspaso.RegistrarOperacionTraspaso(
  QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso;
  ATotal: Currency;
  const ANumSolicitud, ASerieSolicitud: string);
var
  sSerieReferencia: string;
  sNumeroReferencia: string;
begin
  // La operación referencia lo que la originó: la solicitud atendida o la
  // propuesta de traspaso confirmada.
  sSerieReferencia := ASerieSolicitud;
  sNumeroReferencia := ANumSolicitud;
  if FIdPropuesta > 0 then
  begin
    sSerieReferencia := SERIE_REFERENCIA_PROPUESTA_TRASPASO;
    sNumeroReferencia := IntToStr(FIdPropuesta);
  end
  else if FIdRecuentoApp > 0 then
  begin
    ExigirRecuentoAppNoGrabado(QryTrx, AContexto);
    sSerieReferencia := SERIE_REFERENCIA_RECUENTO_APP;
    sNumeroReferencia := IntToStr(FIdRecuentoApp);
  end;
  InsertarOperacionCaja(QryTrx, AContexto.Empresa,
    AContexto.AlmacenOrigen, AContexto.Caja, AContexto.NumeroOperacion,
    AContexto.TipoDocumento, ATotal, AContexto.FechaOperacion,
    AContexto.Empleado, 'Traspaso a ' + AContexto.AlmacenDestino,
    sSerieReferencia, sNumeroReferencia, AContexto.EmpresaContra,
    AContexto.AlmacenDestino, 'S', AContexto.NumeroDocumento,
    AContexto.SerieDocumento);
  if FIdPropuesta > 0 then
    MarcarPropuestaConfirmada(QryTrx, AContexto)
  else if Trim(ANumSolicitud) <> '' then
    MarcarSolicitudAtendida(QryTrx, ANumSolicitud, ASerieSolicitud);
  if FDestinoFinalTransito <> '' then
    RegistrarCargaTransito(QryTrx, AContexto);
end;

// El predicado lleva estado, origen y destino: si otro usuario ya la
// cerró, o el destino elegido no es el suyo, no cuadra ninguna fila y
// la excepción deshace el traspaso entero. Una trasladada en parte se
// puede volver a traspasar hasta que se dé por trasladada.
procedure TdmTraspaso.MarcarPropuestaConfirmada(
  QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso);
begin
  QryTrx.SQL.Text :=
    'UPDATE fza_traspasos_propuestas ' +
    '   SET ESTADO_TRPRO = :ESTADO, ' +
    '       TIPO_DOC_TRPRO = :TIPO, ' +
    '       SERIE_DOC_TRPRO = :SERIE, ' +
    '       NUMERO_DOC_TRPRO = :NUMERO, ' +
    '       NUMERO_OPERACION_TRPRO = :NUMOP, ' +
    '       CODIGO_CAJA_TRPRO = :CAJA, ' +
    '       INSTANTE_RESOLUCION_TRPRO = NOW(), ' +
    '       USUARIO_RESOLUCION_TRPRO = :USUARIO, ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_TRPRO = :ID_TRPRO ' +
    '   AND ESTADO_TRPRO IN (:PENDIENTE, :PARCIAL) ' +
    '   AND CODIGO_ALM_ORIGEN_TRPRO = :ORIGEN ' +
    '   AND CODIGO_ALM_DESTINO_TRPRO = :DESTINO';
  QryTrx.ParamByName('ESTADO').AsString := FEstadoPropuestaAlGrabar;
  QryTrx.ParamByName('PENDIENTE').AsString :=
    ESTADO_PROPUESTA_TRASPASO_PENDIENTE;
  QryTrx.ParamByName('PARCIAL').AsString :=
    ESTADO_PROPUESTA_TRASPASO_TRASLADADO_PARCIAL;
  QryTrx.ParamByName('TIPO').AsString := AContexto.TipoDocumento;
  QryTrx.ParamByName('SERIE').AsString := AContexto.SerieDocumento;
  QryTrx.ParamByName('NUMERO').AsString := AContexto.NumeroDocumento;
  QryTrx.ParamByName('NUMOP').AsString := AContexto.NumeroOperacion;
  QryTrx.ParamByName('CAJA').AsString := AContexto.Caja;
  QryTrx.ParamByName('USUARIO').AsString := AContexto.Usuario;
  QryTrx.ParamByName('ID_TRPRO').AsLargeInt := FIdPropuesta;
  QryTrx.ParamByName('ORIGEN').AsString := AContexto.AlmacenOrigen;
  QryTrx.ParamByName('DESTINO').AsString := AContexto.AlmacenDestino;
  QryTrx.Execute;
  if QryTrx.RowsAffected <> 1 then
    raise EValidacionTraspaso.CreateFmt(
      SErrorPropuestaTraspasoNoPendiente,
      [FIdPropuesta, AContexto.AlmacenOrigen, AContexto.AlmacenDestino]);
  AnotarLineasPropuestaTraspasadas(QryTrx);
  // El documento de trabajo ya se ha materializado en un traspaso: queda
  // como enviado para que no se editen sus líneas.
  QryTrx.SQL.Text :=
    'UPDATE fza_documentos_trabajo ' +
    '   SET ESTADO_DTR = :ENVIADO, USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_DTR = (SELECT P.ID_DTR_TRPRO ' +
    '                   FROM fza_traspasos_propuestas P ' +
    '                  WHERE P.ID_TRPRO = :ID_TRPRO) ' +
    '   AND ' + CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR');
  QryTrx.ParamByName('ENVIADO').AsString :=
    ESTADO_DOCUMENTO_TRABAJO_ENVIADO;
  QryTrx.ParamByName('USUARIO').AsString := AContexto.Usuario;
  QryTrx.ParamByName('ID_TRPRO').AsLargeInt := FIdPropuesta;
  QryTrx.Execute;
end;

// Lo traspasado puede no coincidir con lo propuesto: en caja se pueden
// retocar las unidades o añadir alguna línea antes de grabar.
procedure TdmTraspaso.AnotarLineasPropuestaTraspasadas(QryTrx: TUniQuery);
begin
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    if (Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '') and
       (cdsLineas.FieldByName('CANTIDAD').AsFloat > 0) then
    begin
      QryTrx.SQL.Text :=
        'INSERT INTO fza_traspasos_propuestas_lineas (' +
        '  ID_TRPRO_TRPROLIN, CODIGO_UNIDAD_TRPROLIN, ' +
        '  CODIGO_ART_TRPROLIN, DESCRIPCION_ARTICULO_TRPROLIN, ' +
        '  CANTIDAD_TRPROLIN, CANTIDAD_TRASPASADA_TRPROLIN, ' +
        '  INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (' +
        '  :ID_TRPRO, :SKU, :ARTICULO, :DESCRIPCION, 0, :CANTIDAD, ' +
        '  NOW(), :USUARIO, :USUARIO) ' +
        'ON DUPLICATE KEY UPDATE ' +
        '  CANTIDAD_TRASPASADA_TRPROLIN = ' +
        '    CANTIDAD_TRASPASADA_TRPROLIN + :CANTIDAD, ' +
        '  USUARIO_MODIF = :USUARIO';
      QryTrx.ParamByName('ID_TRPRO').AsLargeInt := FIdPropuesta;
      QryTrx.ParamByName('SKU').AsString :=
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
      QryTrx.ParamByName('ARTICULO').AsString :=
        cdsLineas.FieldByName('CODIGO_ART').AsString;
      QryTrx.ParamByName('DESCRIPCION').AsString :=
        cdsLineas.FieldByName('DESCRIPCION').AsString;
      QryTrx.ParamByName('CANTIDAD').AsFloat :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat;
      QryTrx.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      QryTrx.Execute;
    end;
    cdsLineas.Next;
  end;
end;

function TdmTraspaso.EjecutarGrabacionTraspaso(
  var AContexto: TContextoGrabacionTraspaso;
  const ANumSolicitud, ASerieSolicitud: string;
  out ANumOperacion: string): Boolean;
var
  oConsulta: TUniQuery;
  cTotal: Currency;
  sAviso: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    AContexto.NumeroOperacion := SiguienteOpCaja(AContexto.Empresa,
      AContexto.AlmacenOrigen, AContexto.Caja, AContexto.Usuario);
    ANumOperacion := AContexto.NumeroOperacion;
    AContexto.NumeroDocumento := SiguienteNumeroDocumento(
      AContexto.SerieDocumento, AContexto.TipoDocumento,
      AContexto.Empresa, AContexto.Usuario);
    FConexion.StartTransaction;
    try
      // Tambien al atender: no consumir entradas de fechas futuras.
      sAviso := AvisoStockOrigenEnFecha(AContexto.AlmacenOrigen,
        FechaCajaConHora(AContexto.FechaOperacion));
      if sAviso <> '' then
        raise EValidacionTraspaso.Create(sAviso);
      cTotal := GrabarLineasTraspaso(oConsulta, AContexto);
      RegistrarOperacionTraspaso(oConsulta, AContexto, cTotal,
        ANumSolicitud, ASerieSolicitud);
      FConexion.Commit;
      FUltimoDocumentoGrabado := AContexto;
      FDestinoFinalTransito := '';
      SolicitarProcesadoPrestaShop;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// ---------------------------------------------------------------------------
// Transito en dos pasos (FZ-ISSUE-215). Cargar es un traspaso normal hacia
// el almacen TRANSITO que ademas anota la carga con su destino final;
// recibir es otro traspaso transito -> destino, uno por carga, grabado en
// la caja del destino. Las lineas de la carga son los movimientos de
// entrada en el transito: no hay tabla de lineas.
// ---------------------------------------------------------------------------

const
  SQL_CONDICION_TRANSITO =
    'TIPO_USO_ALM IN (''TR' + #$C1 + 'NSITO'', ''TRANSITO'')';
  // Estados que cierran una carga (ESTADO_TRTRA), tipos de desbloqueo y
  // de incidencia (FZ-ISSUE-256).
  ESTADO_CARGA_RECIBIDO = 'RECIBIDO';
  ESTADO_CARGA_INCIDENCIAS = 'RECIBIDO_INCIDENCIAS';
  ESTADO_CARGA_DEVUELTO = 'DEVUELTO';
  ESTADO_CARGA_PERDIDO = 'PERDIDO';
  ESTADO_CARGA_ANULADO = 'ANULADO';
  DESBLOQUEO_DEVOLUCION = 'DEVOLUCION';
  DESBLOQUEO_CAMBIO_DESTINO = 'CAMBIO_DESTINO';
  DESBLOQUEO_PERDIDA = 'PERDIDA';
  INCIDENCIA_PERDIDA = 'PERDIDA';
  INCIDENCIA_DETERIORO = 'DETERIORO';
  COLUMNA_ALMACEN_ORIGEN_CARGA = 'CODIGO_ALM_ORIGEN_TRTRA';
  COLUMNA_ALMACEN_DESTINO_CARGA = 'CODIGO_ALM_DESTINO_TRTRA';
  TOLERANCIA_UNIDADES_TRANSITO = 0.0000005;

function TdmTraspaso.ListarAlmacenesTransito: TAlmacenesDestinoTraspaso;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      '   AND ' + SQL_CONDICION_TRANSITO +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.EsAlmacenTransito(const AAlmacen: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_almacenes ' +
      ' WHERE CODIGO_ALM_ALM = :ALM ' +
      '   AND ' + SQL_CONDICION_TRANSITO;
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmTraspaso.EstablecerDestinoFinalTransito(const AAlmacen: string);
begin
  FDestinoFinalTransito := Trim(AAlmacen);
end;

// Dentro de la transaccion del traspaso: si algo falla no queda ni la
// carga ni su mercancia en el transito.
procedure TdmTraspaso.RegistrarCargaTransito(QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso);
begin
  if SameText(FDestinoFinalTransito, AContexto.AlmacenDestino) or
     SameText(FDestinoFinalTransito, AContexto.AlmacenOrigen) then
    raise EValidacionTraspaso.Create(SErrorDestinoFinalTransitoNoValido);
  QryTrx.SQL.Text :=
    'INSERT INTO fza_traspasos_transito ' +
    '  (CODIGO_EMP_TRTRA, CODIGO_ALM_ORIGEN_TRTRA, ' +
    '   CODIGO_ALM_TRANSITO_TRTRA, CODIGO_ALM_DESTINO_TRTRA, ' +
    '   TIPO_DOC_CARGA_TRTRA, SERIE_CARGA_TRTRA, NUMERO_CARGA_TRTRA, ' +
    '   NUMERO_OPERACION_CARGA_TRTRA, CODIGO_CAJA_CARGA_TRTRA, ' +
    '   FECHA_CARGA_TRTRA, ESTADO_TRTRA, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'VALUES (:EMP, :ORIGEN, :TRANSITO, :DESTINO, :TIPO, :SERIE, ' +
    '   :NUMERO, :NUMOP, :CAJA, :FECHA, ''PENDIENTE'', NOW(), :USUARIO, ' +
    '   :USUARIO)';
  QryTrx.ParamByName('EMP').AsString := AContexto.Empresa;
  QryTrx.ParamByName('ORIGEN').AsString := AContexto.AlmacenOrigen;
  QryTrx.ParamByName('TRANSITO').AsString := AContexto.AlmacenDestino;
  QryTrx.ParamByName('DESTINO').AsString := FDestinoFinalTransito;
  QryTrx.ParamByName('TIPO').AsString := AContexto.TipoDocumento;
  QryTrx.ParamByName('SERIE').AsString := AContexto.SerieDocumento;
  QryTrx.ParamByName('NUMERO').AsString := AContexto.NumeroDocumento;
  QryTrx.ParamByName('NUMOP').AsString := AContexto.NumeroOperacion;
  QryTrx.ParamByName('CAJA').AsString := AContexto.Caja;
  QryTrx.ParamByName('FECHA').AsDateTime := AContexto.FechaOperacion;
  QryTrx.ParamByName('USUARIO').AsString := AContexto.Usuario;
  QryTrx.ExecSQL;
  // El transito muestra de donde viene y adonde va su ultima carga.
  QryTrx.SQL.Text :=
    'UPDATE fza_almacenes ' +
    '   SET ORIGEN_ACTUAL_ALM = :ORIGEN, DESTINO_ACTUAL_ALM = :DESTINO ' +
    ' WHERE CODIGO_ALM_ALM = :TRANSITO';
  QryTrx.ParamByName('ORIGEN').AsString := AContexto.AlmacenOrigen;
  QryTrx.ParamByName('DESTINO').AsString := FDestinoFinalTransito;
  QryTrx.ParamByName('TRANSITO').AsString := AContexto.AlmacenDestino;
  QryTrx.ExecSQL;
end;

// Almacen de la caja que opera: el de la cabecera (el propio en todos los
// modos; en las solicitudes el otro almacen viaja como parametro).
function TdmTraspaso.AlmacenCaja: string;
begin
  Result := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
end;

function TdmTraspaso.ContarCargasTransito(
  const AColumnaAlmacen, AAlmacen: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_traspasos_transito ' +
      ' WHERE ' + AColumnaAlmacen + ' = :ALM ' +
      '   AND ESTADO_TRTRA = ''PENDIENTE''';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.ContarCargasTransitoPendientes(
  const AAlmacen: string): Integer;
begin
  Result := ContarCargasTransito(COLUMNA_ALMACEN_DESTINO_CARGA, AAlmacen);
end;

function TdmTraspaso.ContarPropuestasPendientesOrigen(
  const AAlmacen: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_traspasos_propuestas P ' +
      ' WHERE ' + FILTRO_PROPUESTAS_PENDIENTES_ORIGEN;
    oConsulta.ParamByName('ORIGEN').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.ContarSolicitudesPendientes(
  const AColumnaAlmacen, AAlmacen: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_traspasos_solicitudes ' +
      ' WHERE ' + AColumnaAlmacen + ' = :ALM ' +
      '   AND ESTADO_TRSOL = ''PENDIENTE''';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.ContarSolicitudesPendientesAtender(
  const AAlmacen: string): Integer;
begin
  Result := ContarSolicitudesPendientes('CODIGO_ALM_ORIGEN_TRSOL', AAlmacen);
end;

// FZ-ISSUE-339: las reposiciones automáticas (estado REPOSICION, sin
// atender ni denegar) también muestran el botón el día que se emiten; sin
// ese límite quedaría visible para siempre, porque nunca se resuelven.
// Alguna petición hecha desde AAlmacen, en cualquier estado.
function TdmTraspaso.ExistenMisPeticiones(const AAlmacen: string): Boolean;
begin
  qryAux.SQL.Text :=
    'SELECT 1 FROM fza_traspasos_solicitudes ' +
    ' WHERE CODIGO_ALM_DESTINO_TRSOL = :ALM LIMIT 1';
  qryAux.ParamByName('ALM').AsString := AAlmacen;
  qryAux.Open;
  try
    Result := not qryAux.IsEmpty;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.ContarMisPeticionesPendientes(
  const AAlmacen: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_traspasos_solicitudes ' +
      ' WHERE CODIGO_ALM_DESTINO_TRSOL = :ALM ' +
      '   AND (ESTADO_TRSOL = ''PENDIENTE'' ' +
      '        OR (ESTADO_TRSOL = ''REPOSICION'' ' +
      '            AND FECHA_TRSOL >= CURDATE()))';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('N').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.ContarCargasTransitoEnviadas(
  const AAlmacen: string): Integer;
begin
  Result := ContarCargasTransito(COLUMNA_ALMACEN_ORIGEN_CARGA, AAlmacen);
end;

// Cargas PENDIENTE del almacen indicado en AColumnaAlmacen (una de las dos
// constantes COLUMNA_ALMACEN_*_CARGA), con sus dias en transito.
function TdmTraspaso.AbrirCargasTransitoPendientes(
  const AColumnaAlmacen, AAlmacen: string): TDataSet;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.ReadOnly := True;
    oConsulta.SQL.Text :=
      'SELECT T.ID_TRTRA, T.FECHA_CARGA_TRTRA, ' +
      '       DATEDIFF(CURRENT_DATE, T.FECHA_CARGA_TRTRA) AS DIAS_TRTRA, ' +
      '       T.CODIGO_ALM_ORIGEN_TRTRA, T.CODIGO_ALM_TRANSITO_TRTRA, ' +
      '       A.NOMBRE_ALM_ALM, T.CODIGO_ALM_DESTINO_TRTRA, ' +
      '       CONCAT(T.SERIE_CARGA_TRTRA, ''/'', T.NUMERO_CARGA_TRTRA) ' +
      '         AS DOCUMENTO_CARGA_TRTRA, ' +
      '       (SELECT COALESCE(SUM(M.CANTIDAD_MOV), 0) ' +
      '          FROM fza_movimientos_almacen M ' +
      '         WHERE M.TIPO_DOC_MOV = T.TIPO_DOC_CARGA_TRTRA ' +
      '           AND M.SERIE_DOC_MOV = T.SERIE_CARGA_TRTRA ' +
      '           AND M.NUMERO_DOC_MOV = T.NUMERO_CARGA_TRTRA ' +
      '           AND M.CODIGO_ALM_MOV = T.CODIGO_ALM_TRANSITO_TRTRA ' +
      '           AND M.TIPO_MOV = ''E'') AS UNIDADES_TRTRA ' +
      '  FROM fza_traspasos_transito T ' +
      '  LEFT JOIN fza_almacenes A ' +
      '    ON A.CODIGO_ALM_ALM = T.CODIGO_ALM_TRANSITO_TRTRA ' +
      ' WHERE T.' + AColumnaAlmacen + ' = :ALM ' +
      '   AND T.ESTADO_TRTRA = ''PENDIENTE'' ' +
      ' ORDER BY T.FECHA_CARGA_TRTRA, T.ID_TRTRA';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TdmTraspaso.QueryCargasTransitoPendientes(
  const AAlmacen: string): TDataSet;
begin
  Result := AbrirCargasTransitoPendientes(
    COLUMNA_ALMACEN_DESTINO_CARGA, AAlmacen);
end;

function TdmTraspaso.QueryCargasTransitoEnviadas(
  const AAlmacen: string): TDataSet;
begin
  Result := AbrirCargasTransitoPendientes(
    COLUMNA_ALMACEN_ORIGEN_CARGA, AAlmacen);
end;

// Bloquea la carga (FOR UPDATE) si sigue PENDIENTE y le toca al almacen de
// la caja: al destino final para recibirla o, con ADesdeOrigen, al que la
// cargo para desbloquearla. Dos cajas no pueden cerrarla a la vez.
function TdmTraspaso.BloquearCargaTransito(QryTrx: TUniQuery; AId: Int64;
  ADesdeOrigen: Boolean): TCargaTransito;
var
  sColumna: string;
begin
  Result := Default(TCargaTransito);
  if ADesdeOrigen then
    sColumna := COLUMNA_ALMACEN_ORIGEN_CARGA
  else
    sColumna := COLUMNA_ALMACEN_DESTINO_CARGA;
  QryTrx.SQL.Text :=
    'SELECT CODIGO_EMP_TRTRA, CODIGO_ALM_ORIGEN_TRTRA, ' +
    '       CODIGO_ALM_TRANSITO_TRTRA, CODIGO_ALM_DESTINO_TRTRA, ' +
    '       TIPO_DOC_CARGA_TRTRA, SERIE_CARGA_TRTRA, ' +
    '       NUMERO_CARGA_TRTRA ' +
    '  FROM fza_traspasos_transito ' +
    ' WHERE ID_TRTRA = :ID ' +
    '   AND ESTADO_TRTRA = ''PENDIENTE'' ' +
    '   AND ' + sColumna + ' = :ALM ' +
    '   FOR UPDATE';
  QryTrx.ParamByName('ID').AsLargeInt := AId;
  QryTrx.ParamByName('ALM').AsString := AlmacenCaja;
  QryTrx.Open;
  if QryTrx.IsEmpty then
  begin
    if ADesdeOrigen then
      raise EValidacionTraspaso.Create(SErrorCargaTransitoNoDesbloqueable)
    else
      raise EValidacionTraspaso.Create(SErrorCargaTransitoNoPendiente);
  end;
  Result.Id := AId;
  Result.Empresa := QryTrx.FieldByName('CODIGO_EMP_TRTRA').AsString;
  Result.AlmacenOrigen :=
    QryTrx.FieldByName('CODIGO_ALM_ORIGEN_TRTRA').AsString;
  Result.AlmacenTransito :=
    QryTrx.FieldByName('CODIGO_ALM_TRANSITO_TRTRA').AsString;
  Result.AlmacenDestino :=
    QryTrx.FieldByName('CODIGO_ALM_DESTINO_TRTRA').AsString;
  Result.TipoDocumento :=
    QryTrx.FieldByName('TIPO_DOC_CARGA_TRTRA').AsString;
  Result.Serie := QryTrx.FieldByName('SERIE_CARGA_TRTRA').AsString;
  Result.Numero := QryTrx.FieldByName('NUMERO_CARGA_TRTRA').AsString;
  QryTrx.Close;
end;

// Lineas de la carga: sus entradas en el transito, por SKU, con todo
// recibido mientras no se reparta otra cosa. El coste unitario es el de la
// carga (total / unidades de esas entradas), no el PMP del transito.
function TdmTraspaso.LeerLineasCargaTransito(
  const ACarga: TCargaTransito): TLineasRecepcionTransito;
var
  oLineas: TUniQuery;
  iLinea: Integer;
begin
  Result := nil;
  oLineas := TUniQuery.Create(nil);
  try
    oLineas.Connection := FConexion;
    oLineas.SQL.Text :=
      'SELECT M.CODIGO_UNIDAD_MOV, ' +
      '       MAX(M.CODIGO_ART_MOV) AS CODIGO_ART_MOV, ' +
      '       MAX(COALESCE(NULLIF(TRIM(M.DESCRIPCION_ARTICULO_MOV), ''''), ' +
      '           A.DESCRIPCION_ART, '''')) AS DESCRIPCION, ' +
      '       MAX(COALESCE(A.TIPO_CANTIDAD_ART, '''')) AS UNIDAD, ' +
      '       SUM(M.CANTIDAD_MOV) AS CANTIDAD, ' +
      '       SUM(M.TOTAL_COSTE_MOV) AS TOTAL_COSTE, ' +
      '       IFNULL(M.LOTE_MOV, '''') AS LOTE, ' +
      '       MAX(M.FECHA_CADUCIDAD_MOV) AS FECHA_CADUCIDAD ' +
      '  FROM fza_movimientos_almacen M ' +
      '  LEFT JOIN fza_articulos A ' +
      '    ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
      ' WHERE M.TIPO_DOC_MOV = :TIPO ' +
      '   AND M.SERIE_DOC_MOV = :SERIE ' +
      '   AND M.NUMERO_DOC_MOV = :NUMERO ' +
      '   AND M.CODIGO_ALM_MOV = :TRANSITO ' +
      // FZ-ISSUE-377: la serie y el número se repiten entre empresas; el
      // almacén de origen (contrapartida de la entrada) los distingue.
      '   AND M.CODIGO_ALM_CONTRA_MOV = :ORIGEN ' +
      '   AND M.TIPO_MOV = ''E'' ' +
      '   AND M.CANTIDAD_MOV > 0 ' +
      ' GROUP BY M.CODIGO_UNIDAD_MOV, IFNULL(M.LOTE_MOV, '''') ' +
      ' ORDER BY MIN(M.LINEA_MOV), M.CODIGO_UNIDAD_MOV, ' +
      '          IFNULL(M.LOTE_MOV, '''')';
    oLineas.ParamByName('TIPO').AsString := ACarga.TipoDocumento;
    oLineas.ParamByName('SERIE').AsString := ACarga.Serie;
    oLineas.ParamByName('NUMERO').AsString := ACarga.Numero;
    oLineas.ParamByName('TRANSITO').AsString := ACarga.AlmacenTransito;
    oLineas.ParamByName('ORIGEN').AsString := ACarga.AlmacenOrigen;
    oLineas.Open;
    SetLength(Result, oLineas.RecordCount);
    iLinea := 0;
    while not oLineas.Eof do
    begin
      Result[iLinea] := Default(TLineaRecepcionTransito);
      Result[iLinea].CodigoSku :=
        oLineas.FieldByName('CODIGO_UNIDAD_MOV').AsString;
      Result[iLinea].CodigoArticulo :=
        oLineas.FieldByName('CODIGO_ART_MOV').AsString;
      Result[iLinea].Descripcion :=
        oLineas.FieldByName('DESCRIPCION').AsString;
      Result[iLinea].Unidad := oLineas.FieldByName('UNIDAD').AsString;
      Result[iLinea].CantidadCargada :=
        oLineas.FieldByName('CANTIDAD').AsFloat;
      Result[iLinea].CantidadRecibida := Result[iLinea].CantidadCargada;
      Result[iLinea].Lote := oLineas.FieldByName('LOTE').AsString;
      if not oLineas.FieldByName('FECHA_CADUCIDAD').IsNull then
        Result[iLinea].FechaCaducidad :=
          Trunc(oLineas.FieldByName('FECHA_CADUCIDAD').AsDateTime);
      Result[iLinea].CosteUnitario :=
        oLineas.FieldByName('TOTAL_COSTE').AsFloat /
        Result[iLinea].CantidadCargada;
      Inc(iLinea);
      oLineas.Next;
    end;
  finally
    FreeAndNil(oLineas);
  end;
end;

function TdmTraspaso.LineasCargaTransito(
  AId: Int64): TLineasRecepcionTransito;
var
  oConsulta: TUniQuery;
  oCarga: TCargaTransito;
begin
  oCarga := Default(TCargaTransito);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ORIGEN_TRTRA, CODIGO_ALM_TRANSITO_TRTRA, ' +
      '       TIPO_DOC_CARGA_TRTRA, SERIE_CARGA_TRTRA, NUMERO_CARGA_TRTRA ' +
      '  FROM fza_traspasos_transito WHERE ID_TRTRA = :ID';
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.Open;
    oCarga.Id := AId;
    oCarga.AlmacenOrigen :=
      oConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRTRA').AsString;
    oCarga.AlmacenTransito :=
      oConsulta.FieldByName('CODIGO_ALM_TRANSITO_TRTRA').AsString;
    oCarga.TipoDocumento :=
      oConsulta.FieldByName('TIPO_DOC_CARGA_TRTRA').AsString;
    oCarga.Serie := oConsulta.FieldByName('SERIE_CARGA_TRTRA').AsString;
    oCarga.Numero := oConsulta.FieldByName('NUMERO_CARGA_TRTRA').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
  Result := LeerLineasCargaTransito(oCarga);
end;

function TdmTraspaso.ListarAlmacenesTaras: TAlmacenesDestinoTraspaso;
var
  oConsulta: TUniQuery;
  iAlmacen: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''TARAS'' ' +
      '   AND CODIGO_EMP_ALM = :EMP ' +
      ' ORDER BY (COALESCE(CODIGO_PADRE_ALM, '''') = :ALM) DESC, ' +
      '          ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.ParamByName('EMP').AsString :=
      cdsCabecera.FieldByName('CODIGO_EMP').AsString;
    oConsulta.ParamByName('ALM').AsString := AlmacenCaja;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CantidadParteTransito(const ALinea: TLineaRecepcionTransito;
  AParte: TParteCargaTransito): Double;
begin
  case AParte of
    pctRecibida:
      Result := ALinea.CantidadRecibida;
    pctDeteriorada:
      Result := ALinea.CantidadDeteriorada;
    pctPerdida:
      Result := ALinea.CantidadPerdida;
  else
    Result := ALinea.CantidadCargada;
  end;
end;

function HayUnidadesParteTransito(const ALineas: TLineasRecepcionTransito;
  AParte: TParteCargaTransito): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(ALineas) do
    if CantidadParteTransito(ALineas[i], AParte) >
       TOLERANCIA_UNIDADES_TRANSITO then
      Result := True;
end;

// Lleva a las lineas de la carga el reparto que llega de la pantalla y lo
// valida: solo SKU de la carga, sin negativos y recibido + deteriorado +
// perdido = cargado. Sin reparto se recibe todo.
function TdmTraspaso.RepartirCargaTransito(
  const ACarga, AReparto: TLineasRecepcionTransito
): TLineasRecepcionTransito;
var
  i, j, iEncontradas: Integer;
  dSuma: Double;
begin
  Result := Copy(ACarga);
  iEncontradas := 0;
  for i := 0 to High(Result) do
    for j := 0 to High(AReparto) do
      if SameText(Result[i].CodigoSku, AReparto[j].CodigoSku) and
         SameText(Result[i].Lote, AReparto[j].Lote) then
      begin
        Inc(iEncontradas);
        Result[i].CantidadRecibida := AReparto[j].CantidadRecibida;
        Result[i].CantidadDeteriorada := AReparto[j].CantidadDeteriorada;
        Result[i].CantidadPerdida := AReparto[j].CantidadPerdida;
        Result[i].Motivo := Trim(AReparto[j].Motivo);
      end;
  if iEncontradas <> Length(AReparto) then
    raise EValidacionTraspaso.Create(SErrorRepartoTransitoLineasAjenas);
  for i := 0 to High(Result) do
  begin
    dSuma := Result[i].CantidadRecibida + Result[i].CantidadDeteriorada +
      Result[i].CantidadPerdida;
    if (Result[i].CantidadRecibida < 0) or
       (Result[i].CantidadDeteriorada < 0) or
       (Result[i].CantidadPerdida < 0) or
       (Abs(dSuma - Result[i].CantidadCargada) >
        TOLERANCIA_UNIDADES_TRANSITO) then
      raise EValidacionTraspaso.CreateFmt(SErrorRepartoTransitoNoCuadra,
        [Result[i].CodigoSku,
         FormatFloat('0.######', Result[i].CantidadCargada),
         FormatFloat('0.######', dSuma)]);
  end;
end;

// Lo deteriorado necesita un almacen de taras de la empresa de la caja.
procedure TdmTraspaso.ValidarAlmacenTarasTransito(
  const ALineas: TLineasRecepcionTransito; const AAlmacenTaras: string);
var
  Almacen: TAlmacenDestinoTraspaso;
  bValido: Boolean;
begin
  if HayUnidadesParteTransito(ALineas, pctDeteriorada) then
  begin
    if Trim(AAlmacenTaras) = '' then
      raise EValidacionTraspaso.Create(SErrorAlmacenTarasTransitoNoIndicado);
    bValido := False;
    for Almacen in ListarAlmacenesTaras do
      if SameText(Almacen.Codigo, AAlmacenTaras) then
        bValido := True;
    if not bValido then
      raise EValidacionTraspaso.CreateFmt(
        SErrorAlmacenTarasTransitoNoValido, [AAlmacenTaras]);
  end;
end;

// Cabecera del documento que saca mercancia del transito. Lo emite la caja
// de la cabecera y entra en AAlmacenEntrada: su almacen, uno de taras de su
// empresa o ninguno si es una perdida. Entrega la empresa del transito o,
// si es compartido, la que cargo (FZ-ISSUE-717); TA si no es la de la caja.
// El documento se numera en la caja que lo graba.
function TdmTraspaso.CrearContextoSalidaTransito(
  const ACarga: TCargaTransito;
  const AAlmacenEntrada: string): TContextoGrabacionTraspaso;
var
  oSalida: TSalidaTransitoEmpresas;
begin
  Result := Default(TContextoGrabacionTraspaso);
  Result.AlmacenOrigen := ACarga.AlmacenTransito;
  Result.AlmacenDestino := AAlmacenEntrada;
  Result.Caja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  Result.Usuario := IdentidadSesion.Usuario;
  Result.Empleado := cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  Result.FechaOperacion := cdsCabecera.FieldByName('FECHA').AsDateTime;
  Result.EmpresaDestino := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  Result.EmpresaContra := Result.EmpresaDestino;
  oSalida := ResolverSalidaTransito(ACarga.Empresa, Result.EmpresaDestino,
    LeerTransitoEmpresa(ACarga.AlmacenTransito), AAlmacenEntrada = '');
  Result.Empresa := oSalida.EmpresaEntrega;
  Result.TipoDocumento := oSalida.TipoDocumento;
  Result.EmpresaOperacion := oSalida.EmpresaOperacion;
  Result.EmpresaContraOperacion := oSalida.EmpresaContraOperacion;
  Result.SerieDocumento := ObtenerSerieDocumento(Result.EmpresaDestino,
    AlmacenCaja, Result.Caja, Result.TipoDocumento);
  Result.NumeroOperacion := SiguienteOpCaja(Result.EmpresaDestino,
    AlmacenCaja, Result.Caja, Result.Usuario);
  Result.NumeroDocumento := SiguienteNumeroDocumento(
    Result.SerieDocumento, Result.TipoDocumento, Result.EmpresaDestino,
    Result.Usuario);
end;

// Una salida del transito por linea con unidades en AParte y, si hay
// almacen de entrada, su entrada. Devuelve las lineas grabadas.
function TdmTraspaso.GrabarLineasSalidaTransito(QryTrx: TUniQuery;
  const AContexto: TContextoGrabacionTraspaso;
  const ALineas: TLineasRecepcionTransito;
  AParte: TParteCargaTransito;
  out ASalidas: TArray<string>): Integer;
var
  sLinea: string;
  dCantidad: Double;
  cCoste: Currency;
  i: Integer;
begin
  Result := 0;
  ASalidas := nil;
  for i := 0 to High(ALineas) do
  begin
    dCantidad := CantidadParteTransito(ALineas[i], AParte);
    if dCantidad > TOLERANCIA_UNIDADES_TRANSITO then
    begin
      Inc(Result);
      sLinea := Format('%.4d', [Result * 10]);
      // Sale al coste medio del transito: el motor de stock valora asi
      // toda salida y lleva ese coste a la entrada del traspaso.
      cCoste := ObtenerCosteMedio(ALineas[i].CodigoSku,
        AContexto.AlmacenOrigen);
      ASalidas := ASalidas + [InsertarMovimientoAlmacen(QryTrx,
        AContexto.TipoDocumento, AContexto.SerieDocumento,
        AContexto.NumeroDocumento, sLinea, AContexto.Empresa,
        AContexto.AlmacenOrigen, AContexto.Caja, AContexto.AlmacenDestino,
        'S', ALineas[i].CodigoSku, dCantidad, cCoste, AContexto.Usuario,
        AlmacenCaja, AContexto.NumeroOperacion, '',
        ALineas[i].CodigoArticulo, AContexto.FechaOperacion,
        ALineas[i].Lote, ALineas[i].FechaCaducidad)];
      if AContexto.AlmacenDestino <> '' then
        InsertarMovimientoAlmacen(QryTrx, AContexto.TipoDocumento,
          AContexto.SerieDocumento, AContexto.NumeroDocumento, sLinea,
          AContexto.EmpresaDestino, AContexto.AlmacenDestino,
          AContexto.Caja, AContexto.AlmacenOrigen, 'E',
          ALineas[i].CodigoSku, dCantidad, cCoste, AContexto.Usuario,
          AlmacenCaja, AContexto.NumeroOperacion, '',
          ALineas[i].CodigoArticulo, AContexto.FechaOperacion,
          ALineas[i].Lote, ALineas[i].FechaCaducidad);
    end;
  end;
end;

// Un documento que saca del transito la parte AParte de las lineas hacia
// AAlmacenEntrada (vacio = perdida), con su operacion en la caja de la
// cabecera. Sin unidades en esa parte no graba nada.
function TdmTraspaso.GrabarSalidaTransito(QryTrx: TUniQuery;
  const ACarga: TCargaTransito; const AAlmacenEntrada, AConcepto: string;
  const ALineas: TLineasRecepcionTransito;
  AParte: TParteCargaTransito): TSalidaTransito;
var
  oContexto: TContextoGrabacionTraspaso;
  cTotal: Currency;
  aSalidas: TArray<string>;
begin
  Result := Default(TSalidaTransito);
  Result.AlmacenEntrada := AAlmacenEntrada;
  if HayUnidadesParteTransito(ALineas, AParte) then
  begin
    oContexto := CrearContextoSalidaTransito(ACarga, AAlmacenEntrada);
    Result.Lineas := GrabarLineasSalidaTransito(QryTrx, oContexto,
      ALineas, AParte, aSalidas);
    EncolarORecalcularMovimientosDocumento(FConexion,
      oContexto.TipoDocumento, oContexto.SerieDocumento,
      oContexto.NumeroDocumento, 'TRASPASO_CAJA', oContexto.Usuario);
    cTotal := TotalCosteMovimientos(QryTrx, aSalidas);
    // Operación y movimientos conservan el tipo de su contador (TP en
    // una pérdida). No se identifica como TR un documento numerado en TP.
    InsertarOperacionCaja(QryTrx, oContexto.EmpresaOperacion, AlmacenCaja,
      oContexto.Caja, oContexto.NumeroOperacion,
      oContexto.TipoDocumento, cTotal,
      oContexto.FechaOperacion, oContexto.Empleado, AConcepto,
      ACarga.Serie, ACarga.Numero, oContexto.EmpresaContraOperacion,
      oContexto.AlmacenOrigen, 'S', oContexto.NumeroDocumento,
      oContexto.SerieDocumento);
    Result.TipoDocumento := oContexto.TipoDocumento;
    Result.Serie := oContexto.SerieDocumento;
    Result.Numero := oContexto.NumeroDocumento;
    Result.NumeroOperacion := oContexto.NumeroOperacion;
  end;
end;

// Un apunte por linea deteriorada o perdida, valorado al coste de la
// carga, para reclamar al transportista o al seguro.
procedure TdmTraspaso.InsertarIncidenciasTransito(QryTrx: TUniQuery;
  const ACarga: TCargaTransito; const ALineas: TLineasRecepcionTransito;
  AParte: TParteCargaTransito; const ASalida: TSalidaTransito);
var
  dCantidad: Double;
  i: Integer;
begin
  for i := 0 to High(ALineas) do
  begin
    dCantidad := CantidadParteTransito(ALineas[i], AParte);
    if dCantidad > TOLERANCIA_UNIDADES_TRANSITO then
    begin
      QryTrx.SQL.Text :=
        'INSERT INTO fza_traspasos_transito_incidencias ' +
        '  (ID_TRTRA_TRTINC, TIPO_TRTINC, CODIGO_UNIDAD_TRTINC, ' +
        '   CODIGO_ART_TRTINC, DESCRIPCION_ARTICULO_TRTINC, ' +
        '   CANTIDAD_TRTINC, PRECIO_COSTE_TRTINC, TOTAL_COSTE_TRTINC, ' +
        '   CODIGO_ALM_TARAS_TRTINC, MOTIVO_TRTINC, TIPO_DOC_TRTINC, ' +
        '   SERIE_DOC_TRTINC, NUMERO_DOC_TRTINC, FECHA_TRTINC, ' +
        IfThen(ALineas[i].Lote <> '',
          '   LOTE_TRTINC, FECHA_CADUCIDAD_TRTINC, ', '') +
        '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
        'VALUES (:ID, :TIPO, :SKU, NULLIF(:ARTICULO, ''''), ' +
        '   NULLIF(:DESCRIPCION, ''''), :CANTIDAD, :COSTE, ' +
        '   ROUND(:CANTIDAD * :COSTE, 6), NULLIF(:TARAS, ''''), ' +
        '   NULLIF(:MOTIVO, ''''), :TIPODOC, :SERIE, :NUMERO, :FECHA, ' +
        IfThen(ALineas[i].Lote <> '', '   :LOTE, :CADUCIDAD, ', '') +
        '   NOW(), :USUARIO, :USUARIO)';
      QryTrx.ParamByName('ID').AsLargeInt := ACarga.Id;
      if AParte = pctPerdida then
        QryTrx.ParamByName('TIPO').AsString := INCIDENCIA_PERDIDA
      else
        QryTrx.ParamByName('TIPO').AsString := INCIDENCIA_DETERIORO;
      QryTrx.ParamByName('SKU').AsString := ALineas[i].CodigoSku;
      QryTrx.ParamByName('ARTICULO').AsString := ALineas[i].CodigoArticulo;
      QryTrx.ParamByName('DESCRIPCION').AsString :=
        Copy(ALineas[i].Descripcion, 1, 100);
      QryTrx.ParamByName('CANTIDAD').AsFloat := dCantidad;
      QryTrx.ParamByName('COSTE').AsCurrency := ALineas[i].CosteUnitario;
      QryTrx.ParamByName('TARAS').AsString := ASalida.AlmacenEntrada;
      QryTrx.ParamByName('MOTIVO').AsString :=
        Copy(ALineas[i].Motivo, 1, 255);
      QryTrx.ParamByName('TIPODOC').AsString := ASalida.TipoDocumento;
      QryTrx.ParamByName('SERIE').AsString := ASalida.Serie;
      QryTrx.ParamByName('NUMERO').AsString := ASalida.Numero;
      QryTrx.ParamByName('FECHA').AsDateTime :=
        FechaCajaConHora(cdsCabecera.FieldByName('FECHA').AsDateTime);
      QryTrx.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      // F-LOTEC-017: la incidencia de una serie identifica la unidad (sin
      // lote, la sentencia de siempre).
      if ALineas[i].Lote <> '' then
      begin
        QryTrx.ParamByName('LOTE').AsString := ALineas[i].Lote;
        QryTrx.ParamByName('CADUCIDAD').DataType := ftDate;
        if ALineas[i].FechaCaducidad = 0 then
          QryTrx.ParamByName('CADUCIDAD').Clear
        else
          QryTrx.ParamByName('CADUCIDAD').AsDate :=
            ALineas[i].FechaCaducidad;
      end;
      QryTrx.ExecSQL;
    end;
  end;
end;

// Cierra la carga con el documento que la saca del transito. Los datos
// del desbloqueo solo se escriben cuando lo hay: recibir no depende de
// esas columnas.
procedure TdmTraspaso.CerrarCargaTransito(QryTrx: TUniQuery;
  const ACarga: TCargaTransito; const AEstado: string;
  const ACierre: TSalidaTransito; const ATipoDesbloqueo, AMotivo: string);
var
  sDesbloqueo: string;
begin
  sDesbloqueo := '';
  if ATipoDesbloqueo <> '' then
    sDesbloqueo :=
      '       TIPO_DESBLOQUEO_TRTRA = :DESBLOQUEO, ' +
      '       MOTIVO_DESBLOQUEO_TRTRA = :MOTIVO, ' +
      '       USUARIO_DESBLOQUEO_TRTRA = :USUARIO, ' +
      '       INSTANTE_DESBLOQUEO_TRTRA = NOW(), ';
  QryTrx.SQL.Text :=
    'UPDATE fza_traspasos_transito ' +
    '   SET ESTADO_TRTRA = :ESTADO, ' +
    '       TIPO_DOC_RECEPCION_TRTRA = NULLIF(:TIPO, ''''), ' +
    '       SERIE_RECEPCION_TRTRA = NULLIF(:SERIE, ''''), ' +
    '       NUMERO_RECEPCION_TRTRA = NULLIF(:NUMERO, ''''), ' +
    '       NUMERO_OPERACION_RECEPCION_TRTRA = NULLIF(:NUMOP, ''''), ' +
    '       CODIGO_CAJA_RECEPCION_TRTRA = :CAJA, ' +
    '       FECHA_RECEPCION_TRTRA = :FECHA, ' + sDesbloqueo +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_TRTRA = :ID ' +
    '   AND ESTADO_TRTRA = ''PENDIENTE''';
  QryTrx.ParamByName('ESTADO').AsString := AEstado;
  QryTrx.ParamByName('TIPO').AsString := ACierre.TipoDocumento;
  QryTrx.ParamByName('SERIE').AsString := ACierre.Serie;
  QryTrx.ParamByName('NUMERO').AsString := ACierre.Numero;
  QryTrx.ParamByName('NUMOP').AsString := ACierre.NumeroOperacion;
  QryTrx.ParamByName('CAJA').AsString :=
    cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  QryTrx.ParamByName('FECHA').AsDateTime :=
    cdsCabecera.FieldByName('FECHA').AsDateTime;
  QryTrx.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  QryTrx.ParamByName('ID').AsLargeInt := ACarga.Id;
  if ATipoDesbloqueo <> '' then
  begin
    QryTrx.ParamByName('DESBLOQUEO').AsString := ATipoDesbloqueo;
    QryTrx.ParamByName('MOTIVO').AsString := Copy(Trim(AMotivo), 1, 255);
  end;
  QryTrx.ExecSQL;
  if QryTrx.RowsAffected <> 1 then
    raise EValidacionTraspaso.Create(SErrorCargaTransitoNoPendiente);
end;

// El transito anuncia de donde viene y adonde va su ultima carga
// pendiente; sin cargas pendientes deja de anunciarlo.
procedure TdmTraspaso.ActualizarAnuncioTransito(QryTrx: TUniQuery;
  const ATransito: string);
var
  sOrigen, sDestino: string;
begin
  sOrigen := '';
  sDestino := '';
  QryTrx.SQL.Text :=
    'SELECT CODIGO_ALM_ORIGEN_TRTRA, CODIGO_ALM_DESTINO_TRTRA ' +
    '  FROM fza_traspasos_transito ' +
    ' WHERE CODIGO_ALM_TRANSITO_TRTRA = :TRANSITO ' +
    '   AND ESTADO_TRTRA = ''PENDIENTE'' ' +
    ' ORDER BY FECHA_CARGA_TRTRA DESC, ID_TRTRA DESC ' +
    ' LIMIT 1';
  QryTrx.ParamByName('TRANSITO').AsString := ATransito;
  QryTrx.Open;
  if not QryTrx.IsEmpty then
  begin
    sOrigen := QryTrx.FieldByName('CODIGO_ALM_ORIGEN_TRTRA').AsString;
    sDestino := QryTrx.FieldByName('CODIGO_ALM_DESTINO_TRTRA').AsString;
  end;
  QryTrx.Close;
  QryTrx.SQL.Text :=
    'UPDATE fza_almacenes ' +
    '   SET ORIGEN_ACTUAL_ALM = NULLIF(:ORIGEN, ''''), ' +
    '       DESTINO_ACTUAL_ALM = NULLIF(:DESTINO, '''') ' +
    ' WHERE CODIGO_ALM_ALM = :TRANSITO';
  QryTrx.ParamByName('ORIGEN').AsString := sOrigen;
  QryTrx.ParamByName('DESTINO').AsString := sDestino;
  QryTrx.ParamByName('TRANSITO').AsString := ATransito;
  QryTrx.ExecSQL;
end;

// Una carga, una transaccion: si falla, las ya recibidas quedan grabadas y
// esta sigue PENDIENTE. Lo recibido entra en el almacen de la caja, lo
// deteriorado en el de taras y lo perdido sale del transito sin entrar en
// ninguno; cada parte con su documento y su operacion de caja. Una carga
// cuyos movimientos se anularon (sin lineas) se cierra como ANULADO sin
// mover nada.
function TdmTraspaso.RecibirCargaTransito(AId: Int64;
  const AReparto: TLineasRecepcionTransito;
  const AAlmacenTaras: string): TArray<string>;
var
  oConsulta: TUniQuery;
  oCarga: TCargaTransito;
  aLineas: TLineasRecepcionTransito;
  oRecibido, oDeteriorado, oPerdido, oCierre: TSalidaTransito;
  sEstado, sDocumento: string;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      oCarga := BloquearCargaTransito(oConsulta, AId, False);
      aLineas := RepartirCargaTransito(LeerLineasCargaTransito(oCarga),
        AReparto);
      ValidarAlmacenTarasTransito(aLineas, AAlmacenTaras);
      sDocumento := oCarga.Serie + '/' + oCarga.Numero;
      oRecibido := GrabarSalidaTransito(oConsulta, oCarga, AlmacenCaja,
        Format(SConceptoRecepcionTransito,
          [oCarga.AlmacenTransito, sDocumento]), aLineas, pctRecibida);
      oDeteriorado := GrabarSalidaTransito(oConsulta, oCarga,
        Trim(AAlmacenTaras), Format(SConceptoDeterioroTransito,
          [oCarga.AlmacenTransito, Trim(AAlmacenTaras), sDocumento]),
        aLineas, pctDeteriorada);
      oPerdido := GrabarSalidaTransito(oConsulta, oCarga, '',
        Format(SConceptoPerdidaTransito,
          [oCarga.AlmacenTransito, sDocumento]), aLineas, pctPerdida);
      InsertarIncidenciasTransito(oConsulta, oCarga, aLineas,
        pctDeteriorada, oDeteriorado);
      InsertarIncidenciasTransito(oConsulta, oCarga, aLineas, pctPerdida,
        oPerdido);
      // La carga se cierra con el primer documento que la saco del
      // transito: la recepcion si llego algo en buen estado.
      oCierre := oRecibido;
      if oCierre.Lineas = 0 then
        oCierre := oDeteriorado;
      if oCierre.Lineas = 0 then
        oCierre := oPerdido;
      if oDeteriorado.Lineas + oPerdido.Lineas > 0 then
        sEstado := ESTADO_CARGA_INCIDENCIAS
      else if oRecibido.Lineas > 0 then
        sEstado := ESTADO_CARGA_RECIBIDO
      else
        sEstado := ESTADO_CARGA_ANULADO;
      CerrarCargaTransito(oConsulta, oCarga, sEstado, oCierre, '', '');
      ActualizarAnuncioTransito(oConsulta, oCarga.AlmacenTransito);
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
    if oRecibido.Lineas > 0 then
      Result := Result + [oRecibido.NumeroOperacion];
    if oDeteriorado.Lineas > 0 then
      Result := Result + [oDeteriorado.NumeroOperacion];
    if oPerdido.Lineas > 0 then
      Result := Result + [oPerdido.NumeroOperacion];
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.RecibirCargasTransito(
  const AIds: TArray<Int64>): TArray<string>;
var
  iId: Int64;
begin
  Result := nil;
  for iId in AIds do
    Result := Result + RecibirCargaTransito(iId, nil, '');
  if Length(Result) > 0 then
    SolicitarProcesadoPrestaShop;
end;

function TdmTraspaso.RecibirCargaTransitoConIncidencias(AId: Int64;
  const AReparto: TLineasRecepcionTransito;
  const AAlmacenTaras: string): TArray<string>;
begin
  Result := RecibirCargaTransito(AId, AReparto, AAlmacenTaras);
  if Length(Result) > 0 then
    SolicitarProcesadoPrestaShop;
end;

// Desbloqueo con movimiento de stock, desde la caja del almacen que cargo:
// devolver al origen (traspaso transito -> origen) o dar por perdida
// (salida del transito con un apunte por linea). Devuelve la operacion.
function TdmTraspaso.DesbloquearCargaTransito(AId: Int64;
  const ATipoDesbloqueo, AMotivo: string): string;
var
  oConsulta: TUniQuery;
  oCarga: TCargaTransito;
  aLineas: TLineasRecepcionTransito;
  oCierre: TSalidaTransito;
  sEstado, sDocumento: string;
  i: Integer;
begin
  if Trim(AMotivo) = '' then
    raise EValidacionTraspaso.Create(SErrorMotivoDesbloqueoTransitoVacio);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      oCarga := BloquearCargaTransito(oConsulta, AId, True);
      aLineas := LeerLineasCargaTransito(oCarga);
      sDocumento := oCarga.Serie + '/' + oCarga.Numero;
      if ATipoDesbloqueo = DESBLOQUEO_PERDIDA then
      begin
        for i := 0 to High(aLineas) do
        begin
          aLineas[i].CantidadRecibida := 0;
          aLineas[i].CantidadPerdida := aLineas[i].CantidadCargada;
          aLineas[i].Motivo := Trim(AMotivo);
        end;
        oCierre := GrabarSalidaTransito(oConsulta, oCarga, '',
          Format(SConceptoPerdidaTransito,
            [oCarga.AlmacenTransito, sDocumento]), aLineas, pctPerdida);
        InsertarIncidenciasTransito(oConsulta, oCarga, aLineas,
          pctPerdida, oCierre);
        sEstado := ESTADO_CARGA_PERDIDO;
      end
      else
      begin
        oCierre := GrabarSalidaTransito(oConsulta, oCarga,
          oCarga.AlmacenOrigen, Format(SConceptoDevolucionTransito,
            [oCarga.AlmacenTransito, sDocumento]), aLineas, pctCargada);
        sEstado := ESTADO_CARGA_DEVUELTO;
      end;
      if oCierre.Lineas = 0 then
        sEstado := ESTADO_CARGA_ANULADO;
      CerrarCargaTransito(oConsulta, oCarga, sEstado, oCierre,
        ATipoDesbloqueo, AMotivo);
      ActualizarAnuncioTransito(oConsulta, oCarga.AlmacenTransito);
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
    Result := oCierre.NumeroOperacion;
  finally
    FreeAndNil(oConsulta);
  end;
  if Result <> '' then
    SolicitarProcesadoPrestaShop;
end;

function TdmTraspaso.DevolverCargaTransito(AId: Int64;
  const AMotivo: string): string;
begin
  Result := DesbloquearCargaTransito(AId, DESBLOQUEO_DEVOLUCION, AMotivo);
end;

function TdmTraspaso.DarPorPerdidaCargaTransito(AId: Int64;
  const AMotivo: string): string;
begin
  Result := DesbloquearCargaTransito(AId, DESBLOQUEO_PERDIDA, AMotivo);
end;

// Mismo criterio que el desplegable de destino del traspaso: un almacen
// activo de uso estandar.
function TdmTraspaso.EsDestinoFinalValido(const AAlmacen: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_almacenes ' +
      ' WHERE CODIGO_ALM_ALM = :ALM ' +
      '   AND ESACTIVO_ALM = ''S'' ' +
      '   AND TIPO_USO_ALM = ''ESTANDAR''';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// La carga sigue PENDIENTE y pasa a «Recepcionar» del nuevo destino. No
// mueve stock: la mercancia sigue en el transito. Se conserva el destino
// con el que se cargo.
procedure TdmTraspaso.CambiarDestinoCargaTransito(AId: Int64;
  const ANuevoDestino, AMotivo: string);
var
  oConsulta: TUniQuery;
  oCarga: TCargaTransito;
  sNuevo: string;
begin
  sNuevo := Trim(ANuevoDestino);
  if Trim(AMotivo) = '' then
    raise EValidacionTraspaso.Create(SErrorMotivoDesbloqueoTransitoVacio);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      oCarga := BloquearCargaTransito(oConsulta, AId, True);
      if (sNuevo = '') or SameText(sNuevo, oCarga.AlmacenDestino) or
         SameText(sNuevo, oCarga.AlmacenOrigen) or
         SameText(sNuevo, oCarga.AlmacenTransito) or
         (not EsDestinoFinalValido(sNuevo)) then
        raise EValidacionTraspaso.Create(
          SErrorNuevoDestinoTransitoNoValido);
      // El destino inicial se fija antes de cambiar el destino: MariaDB
      // evalua las asignaciones de izquierda a derecha.
      oConsulta.SQL.Text :=
        'UPDATE fza_traspasos_transito ' +
        '   SET CODIGO_ALM_DESTINO_INICIAL_TRTRA = COALESCE( ' +
        '         CODIGO_ALM_DESTINO_INICIAL_TRTRA, ' +
        '         CODIGO_ALM_DESTINO_TRTRA), ' +
        '       CODIGO_ALM_DESTINO_TRTRA = :NUEVO, ' +
        '       TIPO_DESBLOQUEO_TRTRA = :DESBLOQUEO, ' +
        '       MOTIVO_DESBLOQUEO_TRTRA = :MOTIVO, ' +
        '       USUARIO_DESBLOQUEO_TRTRA = :USUARIO, ' +
        '       INSTANTE_DESBLOQUEO_TRTRA = NOW(), ' +
        '       USUARIO_MODIF = :USUARIO ' +
        ' WHERE ID_TRTRA = :ID ' +
        '   AND ESTADO_TRTRA = ''PENDIENTE''';
      oConsulta.ParamByName('NUEVO').AsString := sNuevo;
      oConsulta.ParamByName('DESBLOQUEO').AsString :=
        DESBLOQUEO_CAMBIO_DESTINO;
      oConsulta.ParamByName('MOTIVO').AsString :=
        Copy(Trim(AMotivo), 1, 255);
      oConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      oConsulta.ParamByName('ID').AsLargeInt := AId;
      oConsulta.ExecSQL;
      if oConsulta.RowsAffected <> 1 then
        raise EValidacionTraspaso.Create(
          SErrorCargaTransitoNoDesbloqueable);
      ActualizarAnuncioTransito(oConsulta, oCarga.AlmacenTransito);
      FConexion.Commit;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.QueryIncidenciasTransito(
  const AAlmacen: string): TDataSet;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.ReadOnly := True;
    oConsulta.SQL.Text :=
      'SELECT I.ID_TRTINC, I.FECHA_TRTINC, I.TIPO_TRTINC, ' +
      '       CONCAT(T.SERIE_CARGA_TRTRA, ''/'', T.NUMERO_CARGA_TRTRA) ' +
      '         AS DOCUMENTO_CARGA_TRTRA, ' +
      '       T.CODIGO_ALM_ORIGEN_TRTRA, T.CODIGO_ALM_TRANSITO_TRTRA, ' +
      '       T.CODIGO_ALM_DESTINO_TRTRA, I.CODIGO_UNIDAD_TRTINC, ' +
      IfThen(Assigned(FLotesLineas), '       I.LOTE_TRTINC, ', '') +
      '       I.DESCRIPCION_ARTICULO_TRTINC, I.CANTIDAD_TRTINC, ' +
      '       I.PRECIO_COSTE_TRTINC, I.TOTAL_COSTE_TRTINC, ' +
      '       I.CODIGO_ALM_TARAS_TRTINC, I.MOTIVO_TRTINC, ' +
      '       I.REFERENCIA_RECLAMACION_TRTINC, ' +
      '       CONCAT(I.SERIE_DOC_TRTINC, ''/'', I.NUMERO_DOC_TRTINC) ' +
      '         AS DOCUMENTO_TRTINC, ' +
      '       I.USUARIO_ALTA ' +
      '  FROM fza_traspasos_transito_incidencias I ' +
      '  JOIN fza_traspasos_transito T ' +
      '    ON T.ID_TRTRA = I.ID_TRTRA_TRTINC ' +
      ' WHERE T.CODIGO_ALM_ORIGEN_TRTRA = :ALM ' +
      '    OR T.CODIGO_ALM_DESTINO_TRTRA = :ALM ' +
      ' ORDER BY I.FECHA_TRTINC DESC, I.ID_TRTINC DESC';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

procedure TdmTraspaso.AnotarReclamacionIncidenciaTransito(AId: Int64;
  const AReferencia: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'UPDATE fza_traspasos_transito_incidencias ' +
      '   SET REFERENCIA_RECLAMACION_TRTINC = NULLIF(:REFERENCIA, ''''), ' +
      '       USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_TRTINC = :ID';
    oConsulta.ParamByName('REFERENCIA').AsString :=
      Copy(Trim(AReferencia), 1, 100);
    oConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.GrabarTraspaso(const AAlmacenDestino: string;
                                    out ANumOperacion: string;
                                    const ANumSolicitud: string;
                                    const ASerieSolicitud: string): Boolean;
var
  oContexto: TContextoGrabacionTraspaso;
begin
  LimpiarLineasIncompletas;
  if cdsLineas.IsEmpty then
    raise EValidacionTraspaso.Create(SErrorLineasTraspasoNoDisponibles);
  if Trim(AAlmacenDestino) = '' then
    raise EValidacionTraspaso.Create(
      SErrorAlmacenDestinoTraspasoNoSeleccionado);
  ValidarLotesLineas;
  oContexto := CrearContextoGrabacionTraspaso(AAlmacenDestino);
  // Al atender una solicitud el stock insuficiente es solo una advertencia
  // de la pantalla. El traspaso directo conserva el bloqueo para evitar
  // negativos involuntarios.
  if Trim(ANumSolicitud) = '' then
    ValidarStockOrigen(oContexto.AlmacenOrigen);
  Result := EjecutarGrabacionTraspaso(oContexto, ANumSolicitud,
    ASerieSolicitud, ANumOperacion);
end;

procedure TdmTraspaso.MarcarSolicitudAtendida(QryTrx: TUniQuery;
                          const ANumero, ASerie: string);
var
  sUsuario: string;
begin
  sUsuario := IdentidadSesion.Usuario;
  // Resolucion por linea: registra lo servido (CANTIDAD) y, si no se cubre
  // lo pedido (denegada o servida en parte), el motivo. CANTIDAD_SERVIDA
  // suma; ESATENDIDA = 'S' cuando se cubre lo pedido (FZ-ISSUE-326).
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    if Trim(cdsLineas.FieldByName('LINEA').AsString) <> '' then
    begin
      QryTrx.SQL.Text := SqlLineaSolicitudAtendida;
      QryTrx.ParamByName('SERV').AsFloat :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat;
      QryTrx.ParamByName('MOT').AsString :=
        cdsLineas.FieldByName('MOTIVO').AsString;
      QryTrx.ParamByName('USU').AsString := sUsuario;
      QryTrx.ParamByName('NUM').AsString := ANumero;
      QryTrx.ParamByName('SER').AsString := ASerie;
      QryTrx.ParamByName('LIN').AsString :=
        cdsLineas.FieldByName('LINEA').AsString;
      QryTrx.Execute;
      if QryTrx.RowsAffected <> 1 then
        raise EValidacionTraspaso.CreateFmt(
          SErrorLineaSolicitudTraspasoNoActualizada,
          [cdsLineas.FieldByName('LINEA').AsString, ANumero, ASerie]);
    end;
    cdsLineas.Next;
  end;
  // Estado de la cabecera segun lo servido por linea: todo cubierto,
  // COMPLETADO TOTAL; nada servido, DENEGADO TOTAL; el resto (alguna linea
  // denegada o servida en parte), COMPLETADO PARCIAL.
  QryTrx.SQL.Text := SqlEstadoSolicitudAtendida;
  QryTrx.ParamByName('NUM').AsString := ANumero;
  QryTrx.ParamByName('SER').AsString := ASerie;
  QryTrx.ParamByName('USU').AsString := sUsuario;
  QryTrx.Execute;
end;

procedure TdmTraspaso.InsertarCabeceraReposicionAuto(
  AConsulta: TUniQuery;
  const AAlmacenOrigen, ANumero, ASerie: string;
  const ADesde, AHasta: TDateTime; AComoSolicitud: Boolean);
var
  sAlmacenDestino: string;
  sTipo: string;
  sEstado: string;
begin
  if AComoSolicitud then
  begin
    sTipo := 'MANUAL';
    sEstado := 'PENDIENTE';
  end
  else
  begin
    sTipo := 'AUTO';
    sEstado := 'REPOSICION';
  end;
  sAlmacenDestino :=
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  AConsulta.SQL.Text :=
    'INSERT INTO fza_traspasos_solicitudes (' +
    '  NUMERO_TRSOL, SERIE_TRSOL, FECHA_TRSOL, TIPO_TRSOL,' +
    '  ESTADO_TRSOL, CODIGO_EMP_TRSOL,' +
    '  CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL,' +
    '  CODIGO_EMP_CONTRA_TRSOL, CODIGO_CAJA_TRSOL,' +
    '  CODIGO_EMPLEADO_TRSOL, INSTANTE_VENTAS_DESDE_TRSOL,' +
    '  INSTANTE_VENTAS_HASTA_TRSOL, USUARIO_ALTA,' +
    '  USUARIO_MODIF, INSTANTE_ALTA) ' +
    'VALUES (:NUM, :SER, CURRENT_TIMESTAMP, :TIPO, :ESTADO, :EMP,' +
    '  :ORI, :DES, NULLIF(:EMPC, ''''), :CAJA, :EMPLE,' +
    '  :DESDE, :HASTA, :USU, :USU, NOW())';
  AConsulta.ParamByName('NUM').AsString := ANumero;
  AConsulta.ParamByName('SER').AsString := ASerie;
  AConsulta.ParamByName('TIPO').AsString := sTipo;
  AConsulta.ParamByName('ESTADO').AsString := sEstado;
  AConsulta.ParamByName('EMP').AsString :=
    cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  AConsulta.ParamByName('ORI').AsString := AAlmacenOrigen;
  AConsulta.ParamByName('DES').AsString := sAlmacenDestino;
  AConsulta.ParamByName('EMPC').AsString :=
    ObtenerEmpresaAlmacen(AAlmacenOrigen);
  AConsulta.ParamByName('CAJA').AsString :=
    cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  AConsulta.ParamByName('EMPLE').AsString :=
    cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  AConsulta.ParamByName('DESDE').AsDateTime := ADesde;
  AConsulta.ParamByName('HASTA').AsDateTime := AHasta;
  AConsulta.ParamByName('USU').AsString := IdentidadSesion.Usuario;
  AConsulta.Execute;
end;

function TdmTraspaso.InsertarLineasReposicionAuto(
  AConsulta: TUniQuery;
  const ANumero, ASerie: string): Integer;
var
  iLinea: Integer;
begin
  iLinea := 0;
  cdsLineas.First;
  while not cdsLineas.Eof do
  begin
    if cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
    begin
      Inc(iLinea, 10);
      AConsulta.SQL.Text :=
        'INSERT INTO fza_traspasos_solicitudes_lineas (' +
        '  NUMERO_TRSOL_TRSOLLIN, SERIE_TRSOL_TRSOLLIN,' +
        '  LINEA_TRSOLLIN, CODIGO_ART_TRSOLLIN,' +
        '  CODIGO_UNIDAD_TRSOLLIN, DESCRIPCION_ARTICULO_TRSOLLIN,' +
        '  CANTIDAD_PEDIDA_TRSOLLIN, CANTIDAD_SERVIDA_TRSOLLIN,' +
        '  ESATENDIDA_TRSOLLIN, CODIGO_PRV_TRSOLLIN,' +
        '  RAZON_SOCIAL_PRV_TRSOLLIN, USUARIO_ALTA,' +
        '  USUARIO_MODIF, INSTANTE_ALTA) ' +
        'VALUES (:NUM, :SER, :LIN, :ART, :SKU, :DESC, :CANT, 0,' +
        '  ''N'', NULLIF(:PRV, ''''), NULLIF(:NOMPRV, ''''),' +
        '  :USU, :USU, NOW())';
      AConsulta.ParamByName('NUM').AsString := ANumero;
      AConsulta.ParamByName('SER').AsString := ASerie;
      AConsulta.ParamByName('LIN').AsString := Format('%.4d', [iLinea]);
      AConsulta.ParamByName('ART').AsString :=
        cdsLineas.FieldByName('CODIGO_ART').AsString;
      AConsulta.ParamByName('SKU').AsString :=
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
      AConsulta.ParamByName('DESC').AsString :=
        cdsLineas.FieldByName('DESCRIPCION').AsString;
      AConsulta.ParamByName('CANT').AsFloat :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat;
      AConsulta.ParamByName('PRV').AsString :=
        cdsLineas.FieldByName('CODIGO_PROVEEDOR').AsString;
      AConsulta.ParamByName('NOMPRV').AsString :=
        cdsLineas.FieldByName('NOMBRE_PROVEEDOR').AsString;
      AConsulta.ParamByName('USU').AsString := IdentidadSesion.Usuario;
      AConsulta.Execute;
    end;
    cdsLineas.Next;
  end;
  Result := iLinea div 10;
end;

function TdmTraspaso.GrabarReposicionAuto(
  const AAlmacenOrigen: string;
  const ADesde, AHasta: TDateTime;
  AComoSolicitud: Boolean;
  out ANumero, ASerie: string): Boolean;
var
  oConsulta: TUniQuery;
  sAlmacenDestino: string;
begin
  ValidarLineasReposicionAuto;
  if ADesde >= AHasta then
    raise EValidacionTraspaso.Create(
      SErrorRangoVentasReposicionNoValido);
  if cdsLineas.IsEmpty then
    raise EValidacionTraspaso.Create(
      SErrorLineasSolicitudTraspasoNoDisponibles);
  if not TieneLineasReposicionPositivas then
    raise EValidacionTraspaso.Create(
      SErrorLineasSolicitudTraspasoNoDisponibles);
  if Trim(AAlmacenOrigen) = '' then
    raise EValidacionTraspaso.Create(
      SErrorAlmacenOrigenSolicitudNoSeleccionado);
  sAlmacenDestino :=
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  if SameText(sAlmacenDestino, AAlmacenOrigen) then
    raise EValidacionTraspaso.Create(SErrorSolicitudTraspasoMismoAlmacen);
  // FZ-ISSUE-628: serie de la caja y el almacén que emiten la reposición.
  AsignarNumeroSolicitud(cdsCabecera.FieldByName('CODIGO_EMP').AsString,
    sAlmacenDestino, cdsCabecera.FieldByName('CODIGO_CAJA').AsString,
    ANumero, ASerie);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    FConexion.StartTransaction;
    try
      InsertarCabeceraReposicionAuto(
        oConsulta, AAlmacenOrigen, ANumero, ASerie, ADesde, AHasta,
        AComoSolicitud);
      if InsertarLineasReposicionAuto(
        oConsulta, ANumero, ASerie) = 0 then
        raise EValidacionTraspaso.Create(
          SErrorLineasSolicitudTraspasoNoDisponibles);
      FConexion.Commit;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmTraspaso.GrabarSolicitud(const AAlmacenOrigen: string;
                                     out ANumero, ASerie: string): Boolean;
var
  QryTrx: TUniQuery;
  sEmpresa, sAlmacenPropio, sCaja, sUsuario, sEmpContra, sLinea,
  sEmpleado: string;
  iLinea: Integer;
begin
  // Quita la linea en blanco y la fantasma antes de grabar la solicitud.
  LimpiarLineasIncompletas;
  if cdsLineas.IsEmpty then
    raise EValidacionTraspaso.Create(
      SErrorLineasSolicitudTraspasoNoDisponibles);
  if Trim(AAlmacenOrigen) = '' then
    raise EValidacionTraspaso.Create(
      SErrorAlmacenOrigenSolicitudNoSeleccionado);
  sEmpresa := cdsCabecera.FieldByName('CODIGO_EMP').AsString;
  // En mtSolicitar el propio (CODIGO_ALM_ORIGEN) es el DESTINO de la petición.
  sAlmacenPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  sCaja := cdsCabecera.FieldByName('CODIGO_CAJA').AsString;
  sUsuario := IdentidadSesion.Usuario;
  sEmpleado := cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
  if SameText(sAlmacenPropio, AAlmacenOrigen) then
    raise EValidacionTraspaso.Create(SErrorSolicitudTraspasoMismoAlmacen);
  sEmpContra := ObtenerEmpresaAlmacen(AAlmacenOrigen);
  // FZ-ISSUE-628: serie de la caja y el almacén que emiten la solicitud.
  AsignarNumeroSolicitud(sEmpresa, sAlmacenPropio, sCaja, ANumero, ASerie);
  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := FConexion;
    FConexion.StartTransaction;
    try
      QryTrx.SQL.Text :=
        'INSERT INTO fza_traspasos_solicitudes (' +
        '  NUMERO_TRSOL, SERIE_TRSOL, FECHA_TRSOL, ESTADO_TRSOL,' +
        '  CODIGO_EMP_TRSOL, CODIGO_ALM_ORIGEN_TRSOL,' +
        '  CODIGO_ALM_DESTINO_TRSOL, CODIGO_EMP_CONTRA_TRSOL,' +
        '  CODIGO_CAJA_TRSOL, CODIGO_EMPLEADO_TRSOL,' +
        '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
        'VALUES (:NUM, :SER, CURRENT_TIMESTAMP, ''PENDIENTE'', :EMP, :ORI,' +
        '  :DES,' +
        '  NULLIF(:EMPC, ''''), :CAJA, :EMPLE, :USU, :USU, NOW())';
      QryTrx.ParamByName('NUM').AsString := ANumero;
      QryTrx.ParamByName('SER').AsString := ASerie;
      QryTrx.ParamByName('EMP').AsString := sEmpresa;
      QryTrx.ParamByName('ORI').AsString := AAlmacenOrigen;
      QryTrx.ParamByName('DES').AsString := sAlmacenPropio;
      QryTrx.ParamByName('EMPC').AsString := sEmpContra;
      QryTrx.ParamByName('CAJA').AsString := sCaja;
      QryTrx.ParamByName('EMPLE').AsString := sEmpleado;
      QryTrx.ParamByName('USU').AsString := sUsuario;
      QryTrx.Execute;
      iLinea := 0;
      cdsLineas.First;
      while not cdsLineas.Eof do
      begin
        // Salta la linea en blanco de entrada del grid.
        if Trim(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '' then
        begin
          iLinea := iLinea + 10;
          sLinea := Format('%.4d', [iLinea]);
          QryTrx.SQL.Text :=
            'INSERT INTO fza_traspasos_solicitudes_lineas (' +
            '  NUMERO_TRSOL_TRSOLLIN, SERIE_TRSOL_TRSOLLIN, LINEA_TRSOLLIN,' +
            '  CODIGO_ART_TRSOLLIN, CODIGO_UNIDAD_TRSOLLIN,' +
            '  DESCRIPCION_ARTICULO_TRSOLLIN, CANTIDAD_PEDIDA_TRSOLLIN,' +
            '  CANTIDAD_SERVIDA_TRSOLLIN, ESATENDIDA_TRSOLLIN,' +
            '  USUARIO_ALTA, USUARIO_MODIF, INSTANTE_ALTA) ' +
            'VALUES (:NUM, :SER, :LIN, :ART, :SKU, :DESC, :CANT, 0, ''N'',' +
            '  :USU, :USU, NOW())';
          QryTrx.ParamByName('NUM').AsString := ANumero;
          QryTrx.ParamByName('SER').AsString := ASerie;
          QryTrx.ParamByName('LIN').AsString := sLinea;
          QryTrx.ParamByName('ART').AsString :=
            cdsLineas.FieldByName('CODIGO_ART').AsString;
          QryTrx.ParamByName('SKU').AsString :=
            cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
          QryTrx.ParamByName('DESC').AsString :=
            cdsLineas.FieldByName('DESCRIPCION').AsString;
          QryTrx.ParamByName('CANT').AsFloat :=
            cdsLineas.FieldByName('CANTIDAD').AsFloat;
          QryTrx.ParamByName('USU').AsString := sUsuario;
          QryTrx.Execute;
        end;
        cdsLineas.Next;
      end;
      if iLinea = 0 then
        raise EValidacionTraspaso.Create(
          SErrorLineasSolicitudTraspasoNoDisponibles);
      FConexion.Commit;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(QryTrx);
  end;
end;

procedure TdmTraspaso.CargarSolicitudesPendientes(AItems, ACodigos: TStrings);
var
  sPropio: string;
begin
  AItems.Clear;
  ACodigos.Clear;
  sPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  qryAux.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.ESTADO_TRSOL,' +
    '       S.CODIGO_ALM_DESTINO_TRSOL,' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND L.ESATENDIDA_TRSOLLIN = ''N'') AS NLIN' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_ORIGEN_TRSOL = :PROPIO' +
    '   AND S.ESTADO_TRSOL = ''PENDIENTE''' +
    ' ORDER BY S.FECHA_TRSOL, S.NUMERO_TRSOL';
  qryAux.ParamByName('PROPIO').AsString := sPropio;
  qryAux.Open;
  try
    while not qryAux.Eof do
    begin
      AItems.Add(Format('%s/%s  ->  %s  ·  %d líneas  ·  %s',
        [qryAux.FieldByName('SERIE_TRSOL').AsString,
         qryAux.FieldByName('NUMERO_TRSOL').AsString,
         qryAux.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString,
         qryAux.FieldByName('NLIN').AsInteger,
         qryAux.FieldByName('ESTADO_TRSOL').AsString]));
      ACodigos.Add(qryAux.FieldByName('NUMERO_TRSOL').AsString + '|' +
                   qryAux.FieldByName('SERIE_TRSOL').AsString);
      qryAux.Next;
    end;
  finally
    qryAux.Close;
  end;
end;

function TdmTraspaso.QuerySolicitudesAbiertas: TDataSet;
var
  oConsulta: TUniQuery;
  sPropio: string;
begin
  // Solicitudes ABIERTAS (PENDIENTE) que me tocan a mi (yo soy el origen al que
  // se pide). Una vez resueltas (COMPLETADO/DENEGADO/CERRADA) no vuelven a
  // salir. Cada fila lleva el resumen para el modal y el NUMERO/SERIE.
  sPropio := cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  oConsulta := TUniQuery.Create(nil);
  oConsulta.Connection := FConexion;
  // Devolvemos los nombres reales de columna (sin alias) para que el
  // formateador (fza_config_campos) ponga los titulos, igual
  // que el resto de buscadores. El conteo de lineas pendientes es calculado,
  // con sufijo de la tabla para poder titularlo en config.
  oConsulta.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.FECHA_TRSOL,' +
    '       S.CODIGO_ALM_DESTINO_TRSOL, S.ESTADO_TRSOL,' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND L.ESATENDIDA_TRSOLLIN = ''N'') AS LINEAS_PEND_TRSOL' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_ORIGEN_TRSOL = :PROPIO' +
    '   AND S.ESTADO_TRSOL = ''PENDIENTE''' +
    ' ORDER BY S.FECHA_TRSOL, S.NUMERO_TRSOL';
  oConsulta.ParamByName('PROPIO').AsString := sPropio;
  Result := oConsulta;
end;

function TdmTraspaso.QueryMisPeticiones(
  const APropio: string): TDataSet;
var
  oConsulta: TUniQuery;
begin
  // Historico de MIS peticiones: yo soy el DESTINO que pidio. Salen TODOS los
  // estados (PENDIENTE / COMPLETADO TOTAL / COMPLETADO PARCIAL / DENEGADO TOTAL
  // / CERRADA) para saber si se han servido o denegado. Ademas salen las que me
  // pidieron a mi (yo soy el origen) y denegue entera o en parte (alguna linea
  // con motivo de rechazo), para que quien deniega tambien las vea;
  // DIRECCION_TRSOL distingue enviadas de recibidas.
  // Devolvemos los nombres reales de columna (sin alias)
  // para que el formateador (fza_config_campos) ponga los titulos; el origen
  // es a quien se pidio y el destino quien pidio. El llamante libera el query.
  oConsulta := TUniQuery.Create(nil);
  oConsulta.Connection := FConexion;
  oConsulta.SQL.Text :=
    'SELECT S.NUMERO_TRSOL, S.SERIE_TRSOL, S.FECHA_TRSOL,' +
    '       CASE WHEN S.CODIGO_ALM_DESTINO_TRSOL = :PROPIO' +
    '            THEN :ENVIADA ELSE :RECIBIDA END AS DIRECCION_TRSOL,' +
    '       S.CODIGO_ALM_DESTINO_TRSOL,' +
    '       S.CODIGO_ALM_ORIGEN_TRSOL, S.TIPO_TRSOL,' +
    '       S.ESTADO_TRSOL,' +
    '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE' +
    '       (SELECT COUNT(*) FROM fza_traspasos_solicitudes_lineas L' +
    '         WHERE L.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '           AND L.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '           AND COALESCE(L.ESATENDIDA_TRSOLLIN, ''N'') <> ''S''' +
    '           AND NULLIF(TRIM(' +
    '               L.MOTIVO_RECHAZO_TRSOLLIN), '''') IS NULL)' +
    '       END' +
    '         AS LINEAS_PEND_TRSOL' +
    '  FROM fza_traspasos_solicitudes S' +
    ' WHERE S.CODIGO_ALM_DESTINO_TRSOL = :PROPIO' +
    '    OR (S.CODIGO_ALM_ORIGEN_TRSOL = :PROPIO' +
    '        AND (S.ESTADO_TRSOL = ''DENEGADO TOTAL''' +
    '             OR EXISTS (SELECT 1' +
    '                  FROM fza_traspasos_solicitudes_lineas LD' +
    '                 WHERE LD.NUMERO_TRSOL_TRSOLLIN = S.NUMERO_TRSOL' +
    '                   AND LD.SERIE_TRSOL_TRSOLLIN = S.SERIE_TRSOL' +
    '                   AND NULLIF(TRIM(' +
    '                       LD.MOTIVO_RECHAZO_TRSOLLIN), '''')' +
    '                       IS NOT NULL)))' +
    ' ORDER BY S.FECHA_TRSOL DESC, S.NUMERO_TRSOL DESC';
  oConsulta.ParamByName('PROPIO').AsString := APropio;
  oConsulta.ParamByName('ENVIADA').AsString := 'ENVIADA';
  oConsulta.ParamByName('RECIBIDA').AsString := 'RECIBIDA';
  Result := oConsulta;
end;

function TdmTraspaso.QueryLineasSolicitud(
  AMaestro: TDataSource): TDataSet;
var
  oConsulta: TUniQuery;
begin
  if not Assigned(AMaestro) then
    raise EArgumentNilException.Create('AMaestro');
  if not Assigned(AMaestro.DataSet) then
    raise EArgumentNilException.Create('AMaestro.DataSet');
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT L.NUMERO_TRSOL_TRSOLLIN,' +
      '       L.SERIE_TRSOL_TRSOLLIN,' +
      '       L.LINEA_TRSOLLIN,' +
      '       L.CODIGO_ART_TRSOLLIN,' +
      '       L.CODIGO_UNIDAD_TRSOLLIN,' +
      '       COALESCE(NULLIF(TRIM(' +
      '         L.DESCRIPCION_ARTICULO_TRSOLLIN), ''''),' +
      '         A.DESCRIPCION_ART, '''') AS DESCRIPCION_ART,' +
      '       L.CANTIDAD_PEDIDA_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE' +
      '         L.CANTIDAD_SERVIDA_TRSOLLIN END' +
      '         AS CANTIDAD_SERVIDA_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN 0 ELSE GREATEST(' +
      '         COALESCE(L.CANTIDAD_PEDIDA_TRSOLLIN, 0) -' +
      '         COALESCE(L.CANTIDAD_SERVIDA_TRSOLLIN, 0), 0) END' +
      '         AS CANTIDAD_PENDIENTE_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN NULL ELSE' +
      '         L.ESATENDIDA_TRSOLLIN END AS ESATENDIDA_TRSOLLIN,' +
      '       CASE WHEN S.TIPO_TRSOL = ''AUTO'' THEN NULL ELSE' +
      '         L.MOTIVO_RECHAZO_TRSOLLIN END' +
      '         AS MOTIVO_RECHAZO_TRSOLLIN,' +
      '       L.CODIGO_PRV_TRSOLLIN,' +
      '       L.RAZON_SOCIAL_PRV_TRSOLLIN' +
      '  FROM fza_traspasos_solicitudes_lineas L' +
      '  JOIN fza_traspasos_solicitudes S' +
      '    ON S.NUMERO_TRSOL = L.NUMERO_TRSOL_TRSOLLIN' +
      '   AND S.SERIE_TRSOL = L.SERIE_TRSOL_TRSOLLIN' +
      '  LEFT JOIN fza_articulos A' +
      '    ON A.CODIGO_ART_ART = L.CODIGO_ART_TRSOLLIN' +
      ' WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUMERO_TRSOL' +
      '   AND L.SERIE_TRSOL_TRSOLLIN = :SERIE_TRSOL' +
      ' ORDER BY L.LINEA_TRSOLLIN';
    oConsulta.MasterFields := 'NUMERO_TRSOL;SERIE_TRSOL';
    oConsulta.DetailFields :=
      'NUMERO_TRSOL_TRSOLLIN;SERIE_TRSOL_TRSOLLIN';
    oConsulta.MasterSource := AMaestro;
    oConsulta.ReadOnly := True;
    Result := oConsulta;
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function TdmTraspaso.CerrarSolicitud: Boolean;
var
  sNum, sSer: string;
begin
  // Cierra la solicitud cargada (CERRADA) aunque queden lineas sin servir.
  sNum := cdsCabecera.FieldByName('NUMERO_SOL').AsString;
  sSer := cdsCabecera.FieldByName('SERIE_SOL').AsString;
  Result := False;
  if (Trim(sNum) <> '') and (Trim(sSer) <> '') then
  begin
    qryAux.SQL.Text :=
      'UPDATE fza_traspasos_solicitudes' +
      '   SET ESTADO_TRSOL = ''CERRADA'', USUARIO_MODIF = :USU' +
      ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
    qryAux.ParamByName('USU').AsString := IdentidadSesion.Usuario;
    qryAux.ParamByName('NUM').AsString := sNum;
    qryAux.ParamByName('SER').AsString := sSer;
    qryAux.ExecSQL;
    Result := True;
  end;
end;

function TdmTraspaso.GrabarDenegacion: Boolean;
var
  QryTrx: TUniQuery;
  sNum, sSer: string;
begin
  // Resuelve la solicitud cargada SIN movimiento de stock, usando lo que haya
  // en cdsLineas (CANTIDAD por linea y MOTIVO). Si todo va a 0 el estado queda
  // DENEGADO TOTAL; si alguna lleva cantidad, COMPLETADO TOTAL/PARCIAL. Lo usa
  // el atender cuando no se sirve nada (denegacion total con motivo por linea).
  sNum := cdsCabecera.FieldByName('NUMERO_SOL').AsString;
  sSer := cdsCabecera.FieldByName('SERIE_SOL').AsString;
  if (Trim(sNum) = '') or (Trim(sSer) = '') then
    raise EValidacionTraspaso.Create(SErrorSolicitudTraspasoNoCargada);
  QryTrx := TUniQuery.Create(nil);
  try
    QryTrx.Connection := FConexion;
    FConexion.StartTransaction;
    try
      MarcarSolicitudAtendida(QryTrx, sNum, sSer);
      FConexion.Commit;
      Result := True;
    except
      FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(QryTrx);
  end;
end;

function TdmTraspaso.CargarSolicitud(const ANumero, ASerie: string): Boolean;
var
  bCargando: Boolean;
begin
  // F-LOTEC-017: las líneas de la solicitud no preguntan el lote al
  // cargarse; se elige con el botón de la columna y se exige al grabar.
  bCargando := FCargandoLineas;
  FCargandoLineas := True;
  try
    Result := CargarSolicitudSinLotes(ANumero, ASerie);
  finally
    FCargandoLineas := bCargando;
  end;
end;

function TdmTraspaso.CargarSolicitudSinLotes(const ANumero,
  ASerie: string): Boolean;
var
  bExiste: Boolean;
  sPropio, sSkuActivo, sSkuSolicitado, sSolicitante: string;
begin
  sPropio := '';
  sSolicitante := '';
  qryAux.SQL.Text :=
    'SELECT CODIGO_ALM_ORIGEN_TRSOL, CODIGO_ALM_DESTINO_TRSOL' +
    '  FROM fza_traspasos_solicitudes' +
    ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
  qryAux.ParamByName('NUM').AsString := ANumero;
  qryAux.ParamByName('SER').AsString := ASerie;
  qryAux.Open;
  try
    bExiste := not qryAux.IsEmpty;
    if bExiste then
    begin
      sPropio := qryAux.FieldByName('CODIGO_ALM_ORIGEN_TRSOL').AsString;
      sSolicitante := qryAux.FieldByName('CODIGO_ALM_DESTINO_TRSOL').AsString;
    end;
  finally
    qryAux.Close;
  end;
  Result := bExiste;
  if bExiste then
  begin
    ConfigurarEstructuraLineas;
    if cdsCabecera.State = dsBrowse then
      cdsCabecera.Edit;
    cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString := sPropio;
    cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString := sSolicitante;
    cdsCabecera.FieldByName('NUMERO_SOL').AsString := ANumero;
    cdsCabecera.FieldByName('SERIE_SOL').AsString := ASerie;
    cdsCabecera.Post;
    // Pase 1: volcar SKU/uds pendientes (qryAux ocupado, sin coste todavía).
    qryAux.SQL.Text :=
      'SELECT LINEA_TRSOLLIN, CODIGO_ART_TRSOLLIN,' +
      '       CODIGO_UNIDAD_TRSOLLIN,' +
      '       DESCRIPCION_ARTICULO_TRSOLLIN,' +
      '       (CANTIDAD_PEDIDA_TRSOLLIN -' +
      '        CANTIDAD_SERVIDA_TRSOLLIN) AS PENDIENTE' +
      '  FROM fza_traspasos_solicitudes_lineas' +
      ' WHERE NUMERO_TRSOL_TRSOLLIN = :NUM' +
      '   AND SERIE_TRSOL_TRSOLLIN = :SER' +
      '   AND (CANTIDAD_PEDIDA_TRSOLLIN -' +
      '        CANTIDAD_SERVIDA_TRSOLLIN) > 0' +
      ' ORDER BY LINEA_TRSOLLIN';
    qryAux.ParamByName('NUM').AsString := ANumero;
    qryAux.ParamByName('SER').AsString := ASerie;
    qryAux.Open;
    try
      while not qryAux.Eof do
      begin
        cdsLineas.Append;
        cdsLineas.FieldByName('LINEA').AsString :=
          qryAux.FieldByName('LINEA_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CODIGO_ART').AsString :=
          qryAux.FieldByName('CODIGO_ART_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
          qryAux.FieldByName('CODIGO_UNIDAD_TRSOLLIN').AsString;
        DesempaquetarAtributosLinea(
          qryAux.FieldByName('CODIGO_UNIDAD_TRSOLLIN').AsString);
        cdsLineas.FieldByName('DESCRIPCION').AsString :=
          qryAux.FieldByName('DESCRIPCION_ARTICULO_TRSOLLIN').AsString;
        cdsLineas.FieldByName('CANTIDAD').AsFloat :=
          qryAux.FieldByName('PENDIENTE').AsFloat;
        // Lo pendiente es lo que se ofrece servir; el que atiende baja CANTIDAD
        // (o la deja en 0 para denegar, indicando MOTIVO).
        cdsLineas.FieldByName('CANTIDAD_PEDIDA').AsFloat :=
          qryAux.FieldByName('PENDIENTE').AsFloat;
        cdsLineas.FieldByName('MOTIVO').AsString := '';
        cdsLineas.Post;
        qryAux.Next;
      end;
    finally
      qryAux.Close;
    end;
    // Pase 2: rellenar coste y stock del almacén que sirve (el propio).
    cdsLineas.First;
    while not cdsLineas.Eof do
    begin
      cdsLineas.Edit;
      sSkuSolicitado := cdsLineas.FieldByName('CODIGO_UNIDAD').AsString;
      sSkuActivo := ResolverSkuSolicitudActivo(
        cdsLineas.FieldByName('CODIGO_ART').AsString, sSkuSolicitado);
      if (sSkuActivo <> '') and not SameText(sSkuActivo, sSkuSolicitado) then
      begin
        cdsLineas.FieldByName('CODIGO_UNIDAD').AsString := sSkuActivo;
        DesempaquetarAtributosLinea(sSkuActivo);
      end;
      cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
        ObtenerCosteMedio(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString,
                          sPropio);
      cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
        ObtenerStock(cdsLineas.FieldByName('CODIGO_UNIDAD').AsString, sPropio);
      cdsLineas.FieldByName('TOTAL').AsCurrency :=
        cdsLineas.FieldByName('CANTIDAD').AsFloat *
        cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
      cdsLineas.Post;
      cdsLineas.Next;
    end;
  end;
end;

end.
