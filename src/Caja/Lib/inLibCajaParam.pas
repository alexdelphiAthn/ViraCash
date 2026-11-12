{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaParam                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de configuración del punto de venta.                           }
{    Definición, carga desde BBDD y acceso tipado a opciones de caja.          }
{******************************************************************************}
unit inLibCajaParam;

interface

uses
  inLibParametrosIntf, inLibParametrosBase, inLibPerfilesUsuarioIntf,
  inLibContextoSesionIntf, inLibDeteccionImpresora;

const
  PARAMETRO_USAR_ALMACENES_TRANSITO = 'vgerUsarAlmacenesTransito';
  // Ticket de caja con formato FastReport (impreso como imagen): el
  // parámetro guarda el nombre de un formato de factura (frmPrintFac) que
  // empieza por cPrefijoFormatoTicket. Vacío = ticket ESC/POS de texto.
  cParametroFormatoTicket = 'vgerFormatoTicket';
  cPrefijoFormatoTicket = 'Ticket';
  // Sin marcar, la fase de cobro oculta el botón, las cajas y las
  // etiquetas de vales (tiendas que no los usan).
  PARAMETRO_USAR_VALES_COBRO = 'vgerUsarValesCobro';

type
  TParametrosCaja = class(
    TParametrosBase,
    IParametrosCaja
  )
  private
    FContextoSesion: IContextoSesionAplicacion;
    FDetectorImpresora: IDetectorImpresora;
    function SegundosEsperaDeteccionImpresora: Integer;
    procedure RegistrarControlArticulos;
    procedure RegistrarConfiguracionCaja;
    procedure RegistrarDevolucionesYVales;
    procedure RegistrarAvisosYBusquedas;
    procedure RegistrarImpresion;
    procedure RegistrarEmpleado;
    procedure RegistrarPermisosYArqueo;
    procedure RegistrarTrazabilidad;
    procedure InicializarParametrosCaja(
      const AUsuario, AGrupo: string);
  protected
    procedure DespuesDeRecargar; override;
  public
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const ACachePerfiles: ICachePerfilesUsuario;
      const AContextoSesion: IContextoSesionAplicacion);
    destructor Destroy; override;
    function ImpresoraCaja: string;
    function NivelesFamiliaArqueo: Integer;
    function TarifaDefecto: string;
  end;

function UsarAlmacenesTransito(
  const AParametros: IParametrosCaja): Boolean;

function UsarValesCobro(
  const AParametros: IParametrosCaja): Boolean;

function CrearParametrosCaja(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion;
  const AUsuario, AGrupo: string
): TServiciosParametrosCaja;

implementation

uses
  System.SysUtils,
  inLibArqueoDesglose, inLibMsgCaja,
  inLibRetiradaLotesIntf, inLibMsgRetiradaLotes;

const
  cParametroEsperaDeteccionImpresora =
    'vgerImpresoraEsperaSegundos';

function UsarAlmacenesTransito(
  const AParametros: IParametrosCaja): Boolean;
begin
  Result := Assigned(AParametros) and
    AParametros.GetBool(PARAMETRO_USAR_ALMACENES_TRANSITO, False);
end;

function UsarValesCobro(
  const AParametros: IParametrosCaja): Boolean;
begin
  // Por defecto (sin parámetros o sin valor guardado) los vales se usan.
  Result := (not Assigned(AParametros)) or
    AParametros.GetBool(PARAMETRO_USAR_VALES_COBRO, True);
end;

{ TParametrosCaja }

constructor TParametrosCaja.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion);
begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create(
      SErrorContextoImpresoraCajaNoProporcionado);
  inherited Create(
    APerfilesLectura,
    ACachePerfiles,
    'frmMtoCajaParam',
    TArray<string>.Create(
      'WindowState',
      'Left',
      'Top',
      'Width',
      'Height',
      'Divider'
    )
  );
  FContextoSesion := AContextoSesion;
  FDetectorImpresora := CrearDetectorImpresora('DetectorImpresoraTickets');
end;

destructor TParametrosCaja.Destroy;
begin
  if Assigned(FDetectorImpresora) then
    FDetectorImpresora.Cancelar;
  FDetectorImpresora := nil;
  FContextoSesion := nil;
  inherited;
end;

procedure TParametrosCaja.DespuesDeRecargar;
var
  sArchivoCache: string;
  sPatronImpresora: string;
begin
  sPatronImpresora := Trim(GetString('vgerDefPrinter', 'DEBUG'));
  sArchivoCache := Format('Caja_%s.cache',
    [FContextoSesion.Identidad.Usuario]);
  FDetectorImpresora.Preparar(
    sPatronImpresora,
    sArchivoCache,
    SegundosEsperaDeteccionImpresora);
end;

function TParametrosCaja.SegundosEsperaDeteccionImpresora: Integer;
begin
  Result := LimitarEsperaDeteccionImpresora(
    GetInt(cParametroEsperaDeteccionImpresora, 5));
end;

function TParametrosCaja.ImpresoraCaja: string;
begin
  Result := FDetectorImpresora.ValorActual;
  try
    FDetectorImpresora.IniciarDeteccion;
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inLibCajaParam.ImpresoraCaja.IniciarDeteccion', E);
  end;
end;

procedure TParametrosCaja.InicializarParametrosCaja(
  const AUsuario, AGrupo: string);
begin
  RegistrarControlArticulos;
  RegistrarConfiguracionCaja;
  RegistrarDevolucionesYVales;
  RegistrarAvisosYBusquedas;
  RegistrarImpresion;
  RegistrarEmpleado;
  RegistrarPermisosYArqueo;
  RegistrarTrazabilidad;
  Inicializar(AUsuario, AGrupo);
end;

procedure TParametrosCaja.RegistrarTrazabilidad;
begin
  // F-LOTEC: solo se muestran con su interruptor de aplicación encendido
  // (TActivacionTrazabilidad.ParametroVisible). Los caducados avisan,
  // nunca bloquean la venta.
  RegistrarParametro('Trazabilidad',
                     'vgerLoteAsignarFefo',
                     'Asignar el lote automáticamente (primero el que ' +
                     'antes caduca)',
                     tpBoolean,
                     'True');
  RegistrarParametro('Trazabilidad',
                     'vgerSerieExigirEnVenta',
                     'Exigir el número de serie al vender',
                     tpBoolean,
                     'True');
end;

procedure TParametrosCaja.RegistrarControlArticulos;
begin
  RegistrarParametro('Control de Artículos',
                     'vgerChkExistOnly',
                     'Permitir sólo artículos que existan',
                     tpBoolean,
                     'True');
  RegistrarParametro('Control de Artículos',
                     'vgerChkStockOnly',
                     'Permitir sólo artículos con stock',
                     tpBoolean,
                     'False');
end;

procedure TParametrosCaja.RegistrarConfiguracionCaja;
begin
  RegistrarParametro('Configuración de Caja',
                     PARAMETRO_USAR_ALMACENES_TRANSITO,
                     'Usar almacenes de tránsito',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerShowCajaSelection',
                     'Presentar selección de caja',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerFillEmpleadoDefecto',
                     'Rellenar empleado por defecto al abrir',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerDefTarifa',
                     'Tarifa por defecto en caja',
                     tpString,
                     'PVP');
  RegistrarParametro('Configuración de Caja',
                     'vgerTarifaPeriodicaAutomatica',
                     'Tarifa periódica automática (código, vacío: no usar)',
                     tpString,
                     '');
  RegistrarParametro('Configuración de Caja',
                     'vgerMaxOpPending',
                     'Número de operaciones pendientes',
                     tpInteger,
                     '5');
  RegistrarParametro('Configuración de Caja',
                     'vgerAutoLoadDepositos',
                     'Cargar depósitos automáticamente al seleccionar cliente',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerAgruparUnidadesIguales',
                     'Agrupar unidades iguales en una sola línea',
                     tpBoolean,
                     'False');
  RegistrarParametro('Configuración de Caja',
                     'vgerAplazarRecalculoMovimientos',
                     'Aplazar recálculos de stock de caja y albaranes',
                     tpBoolean,
                     'False');
  // FZ-ISSUE-411: marcada, la reposición desde ventas (Traspasos > F5) se
  // emite como una solicitud corriente: el almacén origen la ve en «Atender
  // solicitudes», la sirve y queda como servida. Sin marcar sigue siendo
  // informativa (estado REPOSICION, FZ-ISSUE-339).
  RegistrarParametro('Configuración de Caja',
                     'vgerReposicionComoSolicitud',
                     'Emitir las reposiciones como solicitud de traspaso ' +
                     '(el almacén origen las atiende)',
                     tpBoolean,
                     'False');
  RegistrarParametro('Servicios web',
                     'vgerEnviarVentasWS',
                     'Enviar ventas completas al webservice de respaldo',
                     tpBoolean,
                     'False');
end;

procedure TParametrosCaja.RegistrarDevolucionesYVales;
begin
  RegistrarParametro('Devoluciones y Vales',
                     PARAMETRO_USAR_VALES_COBRO,
                     'Usar vales en la fase de cobro',
                     tpBoolean,
                     'True');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerReqRefDevolucion',
                     'Pedir referencia en devoluciones',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerRecuperaValePIN',
                     'Recuperar Vale sólo con PIN',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerAmbitoCanjeVale',
                     'Canjear vales de: TODOS, ALMACEN o CAJA',
                     tpString,
                     'TODOS');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerCaducidadDefVale',
                     'Caducidad por defecto en vale',
                     tpBoolean,
                     'False');
  RegistrarParametro('Devoluciones y Vales',
                     'vgerDiasCaducidadVale',
                     'Días hasta caducidad en vale',
                     tpInteger,
                     '365');
end;

procedure TParametrosCaja.RegistrarAvisosYBusquedas;
begin
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerAvisoStockWarning',
                     'Aviso en artículos sin stock',
                     tpString,
                     'Artículo sin stock. Compruebe stock en almacén.');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerAvisoHuecosNumeracion',
                     'Avisar de huecos en la numeración de ventas',
                     tpBoolean,
                     'True');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtStockOnly',
                     'Búsqueda de artículos sólo con stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerBusqArtTarifaOnly',
                     'Búsqueda de artículos sólo con tarifa',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerStockTodosColores',
                     'Mostrar todos los colores por separado en el stock',
                     tpBoolean,
                     'False');
  RegistrarParametro('Avisos y Búsquedas',
                     'vgerMoverLineaIdentif',
                     'Mover linea al identificar artículo',
                     tpBoolean,
                     // FZ-ISSUE-455: apagado, la lectura siguiente de un
                     // lector caía en la descripción de la línea anterior.
                     'True');
end;

procedure TParametrosCaja.RegistrarImpresion;
begin
  RegistrarParametro('Impresión', 'vgerImprimirLoteCaducidadTicket',
    'Imprimir lote y caducidad en el ticket (sin marcar, agrupar lotes)',
    tpBoolean, 'True');
  RegistrarParametro('Impresión', PARAMETRO_FORMATO_RETIRADA_LOTES,
    SParametroFormatoRetirada, tpString, 'TEXTO42');
  RegistrarParametro('Impresión',
                     'vgerDefPrinter',
                     'Nombre impresora de tickets',
                     tpString,
                     '');
  RegistrarParametro('Impresión',
                     cParametroEsperaDeteccionImpresora,
                     'Espera para detectar la impresora al arrancar ' +
                     '(0-300 segundos)',
                     tpInteger,
                     '5');
  RegistrarParametro('Impresión',
                     'vgerTipoImpresion',
                     'Tipo de Impresión tickets',
                     tpString,
                     'ESC POS');
  RegistrarParametro('Impresión',
                     'vgerFormatoImpPredet',
                     'Formato de impresión predeterminado',
                     tpString,
                     '');
  RegistrarParametro('Impresión',
                     'vgerImprimirCodBarrasTicket',
                     'Imprimir código de barras EAN13 del ticket',
                     tpBoolean,
                     'False');
  // Formato de factura (frmPrintFac) cuyo nombre empieza por 'Ticket'.
  RegistrarParametro('Impresión',
                     cParametroFormatoTicket,
                     'Formato FastReport del ticket, impreso como imagen ' +
                     '(vacío = ticket de texto)',
                     tpString,
                     '');
end;

procedure TParametrosCaja.RegistrarEmpleado;
begin
  RegistrarParametro('Empleado',
                     'vgerCodEmpleadoDefecto',
                     'Código de empleado por defecto',
                     tpString,
                     '');
  RegistrarParametro('Empleado',
                     'vgerShowEmpleadoLinea',
                     'Mostrar empleado en linea de caja',
                     tpBoolean,
                     'True');
end;

procedure TParametrosCaja.RegistrarPermisosYArqueo;
begin
  RegistrarParametro('Permisos Extra',
                     'vgerArqueoTarjetas',
                     'Permitir Arqueo de Tarjetas',
                     tpBoolean,
                     'False');
  RegistrarParametro('Permisos Extra',
                     'vgerVentasCredito',
                     'Permitir Ventas a Crédito',
                     tpBoolean,
                     'True');
  RegistrarParametro('Permisos Extra',
                     'vgerDescuentos',
                     'Permite descuentos en ventas',
                     tpBoolean,
                     'True');
  RegistrarParametro('Arqueo',
                     'vgerArqueoNivelesFamilia',
                     'Niveles de familia en resumen por sección (1=sección)',
                     tpInteger,
                     '2');
  RegistrarParametro('Arqueo',
                     'vgerArqueoEditarCambio',
                     'Permitir editar el cambio dejado para la ' +
                     'siguiente jornada',
                     tpBoolean,
                     'False');
  RegistrarParametro('Arqueo',
                     'vgerArqueoEmitirJustificante',
                     'Emitir justificante al grabar el cierre',
                     tpBoolean,
                     'True');
  RegistrarParametro('Arqueo',
                     'vgerArqueoRecuentoDetallado',
                     'Recuento detallado de billetes y monedas',
                     tpBoolean,
                     'False');
  RegistrarParametro('Arqueo',
                     'vgerArqueoDenominaciones',
                     'Denominaciones del recuento detallado ' +
                     'separadas por punto y coma',
                     tpString,
                     DenominacionesArqueoPorDefecto);
end;

function TParametrosCaja.NivelesFamiliaArqueo: Integer;
begin
  Result := GetInt('vgerArqueoNivelesFamilia', 2);
  if Result < 1 then
    Result := 1;
  if Result > 9 then
    Result := 9;
end;

function TParametrosCaja.TarifaDefecto: string;
begin
  Result := GetString('vgerDefTarifa', 'PVP');
end;

function CrearParametrosCaja(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion;
  const AUsuario, AGrupo: string
): TServiciosParametrosCaja;
var
  Parametros: TParametrosCaja;
begin
  Parametros := TParametrosCaja.Create(
    APerfilesLectura,
    ACachePerfiles,
    AContextoSesion);
  // Los contratos gobiernan la vida del objeto antes de inicializar.
  Result.Lectura := Parametros;
  Result.Edicion := Parametros;
  Parametros.InicializarParametrosCaja(AUsuario, AGrupo);
end;

end.
