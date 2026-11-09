{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentanaEspera                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ventana de espera con barra en movimiento continuo que vive en un hilo    }
{    propio, de modo que sigue animándose aunque el hilo principal esté        }
{    bloqueado en una consulta o preparando un informe. Solo usa la API de     }
{    Windows: ningún control VCL se toca desde el hilo de la ventana.          }
{    Incluye la espera de una tarea que atiende los mensajes que otros hilos   }
{    envían al principal (SendMessage, Synchronize) sin despachar la entrada.  }
{    La ventana lleva su propio cronómetro: el tiempo transcurrido lo cuenta   }
{    y lo pinta el hilo de la ventana, no el que está esperando.               }
{    La variante de proceso en segundo plano añade barra de título, botón de   }
{    minimizar, botón propio en la barra de tareas y un cuadro con barras de   }
{    desplazamiento donde se lee lo que se está ejecutando: cada trabajo       }
{    largo tiene la suya y se puede apartar mientras se sigue con otra cosa.   }
{******************************************************************************}
unit inLibVentanaEspera;

interface

uses
  Winapi.Windows, System.SysUtils, System.Threading;

const
  // Clases de ventana registradas; permiten a las pruebas localizarlas.
  cClaseVentanaEspera = 'ViraCashVentanaEspera';
  cClaseVentanaProceso = 'ViraCashVentanaProceso';

type
  TEstiloVentanaEspera = (
    // Sin marco: acompaña a la ventana que espera y se esconde con ella.
    eveAcompaniaVentana,
    // Con barra de título, minimizar, botón en la barra de tareas y cuadro
    // de texto: el trabajo sigue aunque se aparte la ventana.
    eveProcesoSegundoPlano
  );

  // Contrato de la ventana de espera. Se usa desde el hilo principal y
  // ninguna llamada bloquea: solo envían mensajes al hilo de la ventana.
  IVentanaEspera = interface
    ['{7C1E1B7E-2C0B-4C4B-9F8E-5A0F6D5B2E31}']
    // Muestra la ventana con la fase indicada (o cambia la fase si ya
    // está visible), limpia el detalle y olvida una cancelación previa.
    procedure Mostrar(const AFase: string);
    // Cambia la línea de detalle ("Página 3. Seleccionando artículo...").
    procedure ActualizarDetalle(const ADetalle: string);
    // Texto largo del cuadro con barras de desplazamiento (la sentencia
    // que se está ejecutando). La ventana sin cuadro lo ignora.
    procedure MostrarTexto(const ATexto: string);
    // Habilita o deshabilita el botón Cancelar.
    procedure PermitirCancelar(APermitir: Boolean);
    // True si el usuario ha pulsado Cancelar desde el último Mostrar.
    function Cancelado: Boolean;
    // Oculta la ventana y descarta las pulsaciones de teclado y ratón
    // acumuladas mientras el hilo principal estaba ocupado.
    procedure Ocultar;
  end;

// Crea la ventana (oculta) centrada sobre AReferencia, en coordenadas de
// pantalla, con las medidas escaladas a APixelesPorPulgada. Liberar la
// interfaz cierra la ventana y termina su hilo.
//
// AVentanaVigilada es la ventana del programa que esta esperando: la de
// espera se coloca justo encima de ella y se oculta mientras esa ventana
// se minimiza o se esconde, en vez de quedarse sobre todas las
// aplicaciones. Con 0 se comporta como una ventana suelta.
function CrearVentanaEspera(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer;
  AVentanaVigilada: HWND = 0): IVentanaEspera;

// Ventana de un proceso que corre por su cuenta: se puede minimizar y
// mover, sale en la barra de tareas con ATitulo, enseña en un cuadro con
// barras de desplazamiento lo que está ejecutando y no se esconde con la
// pantalla que lo lanzó. Liberar la interfaz la cierra.
function CrearVentanaProcesoSegundoPlano(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer;
  const ATitulo: string): IVentanaEspera;

// Espera a que termine ATarea atendiendo la barra de título, pero sin
// despachar teclado ni ratón del área de trabajo (no hay
// reentrada en la pantalla) pero atendiendo lo que otros hilos piden al
// principal: SendMessage a sus ventanas (el monitor SQL escribe en un memo
// desde el hilo de la consulta) y Synchronize/Queue. Un WaitForAll a secas
// se queda bloqueado con esas peticiones pendientes.
procedure EsperarTareaAtendiendoMensajes(
  const ATarea: ITask); overload;
// Igual que la anterior, llamando a AVigilar en cada vuelta: es donde la
// pantalla mira si se ha pulsado Cancelar en la ventana de espera y corta
// la sentencia en curso.
procedure EsperarTareaAtendiendoMensajes(
  const ATarea: ITask;
  const AVigilar: TProc); overload;

// Despacha las órdenes de minimizar y restaurar que la barra de tareas haya
// dejado en la cola de este hilo, y descarta las demás órdenes de sistema
// (cerrar, mover). Es para llamarla desde AVigilar en las esperas largas:
// sin ella la orden se queda en cola, el programa no se aparta cuando se
// le pide y se minimiza por sorpresa al terminar. No despacha nada más, así
// que sigue sin haber reentrada en la pantalla.
procedure AtenderMinimizarYRestaurar;

// Tiempo transcurrido en m:ss, o h:mm:ss a partir de la hora: es lo que la
// ventana de espera pinta junto al botón.
function TextoTiempoEspera(AMilisegundos: UInt64): string;

implementation

uses
  Winapi.Messages, Winapi.CommCtrl, Winapi.MultiMon,
  System.Classes, System.Math, System.SyncObjs, inLibMsgComun,
  inLibFuenteInterfaz;

const
  WM_ESPERA_MOSTRAR = WM_APP + 1;
  WM_ESPERA_OCULTAR = WM_APP + 2;
  WM_ESPERA_FASE = WM_APP + 3;
  WM_ESPERA_DETALLE = WM_APP + 4;
  WM_ESPERA_CANCELABLE = WM_APP + 5;
  WM_ESPERA_CERRAR = WM_APP + 6;
  WM_ESPERA_TEXTO = WM_APP + 7;
  ID_BOTON_CANCELAR = 1;
  // Sondeo del estado de la ventana vigilada: minimizada u oculta.
  ID_TEMPORIZADOR_VIGILANCIA = 2;
  INTERVALO_VIGILANCIA_MS = 200;
  PIXELES_POR_PULGADA_BASE = 96;
  PUNTOS_FUENTE = 10;
  PUNTOS_FUENTE_TEXTO = 9;
  NOMBRE_FUENTE = 'Source Sans 3';
  NOMBRE_FUENTE_TEXTO = 'Source Code Pro';
  INTERVALO_MARQUEE_MS = 30;
  ESPERA_CREACION_MS = 3000;
  ESPERA_CIERRE_MS = 3000;
  INTERVALO_SONDEO_TAREA_MS = 20;

type
  // Medidas a 96 ppp de cada variante; se escalan a los ppp indicados al
  // crear la ventana. Un alto de texto 0 significa que no hay cuadro.
  TMaquetaEspera = record
    Ancho: Integer;
    Alto: Integer;
    Margen: Integer;
    ArribaFase: Integer;
    AltoFase: Integer;
    ArribaDetalle: Integer;
    AltoDetalle: Integer;
    ArribaTexto: Integer;
    AltoTexto: Integer;
    ArribaBarra: Integer;
    AltoBarra: Integer;
    ArribaBoton: Integer;
    AnchoBoton: Integer;
    AltoBoton: Integer;
    AnchoTiempo: Integer;
  end;

const
  cMaquetaAcompania: TMaquetaEspera = (
    Ancho: 420;
    Alto: 132;
    Margen: 20;
    ArribaFase: 14;
    AltoFase: 20;
    ArribaDetalle: 38;
    AltoDetalle: 18;
    ArribaTexto: 0;
    AltoTexto: 0;
    ArribaBarra: 64;
    AltoBarra: 14;
    ArribaBoton: 90;
    AnchoBoton: 88;
    AltoBoton: 24;
    AnchoTiempo: 90;
  );
  cMaquetaProceso: TMaquetaEspera = (
    Ancho: 480;
    Alto: 248;
    Margen: 16;
    ArribaFase: 12;
    AltoFase: 20;
    ArribaDetalle: 34;
    AltoDetalle: 18;
    ArribaTexto: 58;
    AltoTexto: 110;
    ArribaBarra: 178;
    AltoBarra: 14;
    ArribaBoton: 204;
    AnchoBoton: 88;
    AltoBoton: 24;
    AnchoTiempo: 90;
  );

type
  // Hilo propietario de la ventana: crea la clase, la ventana y sus
  // controles, y bombea sus mensajes hasta recibir WM_ESPERA_CERRAR.
  THiloVentanaEspera = class(TThread)
  private
    FReferencia: TRect;
    FPixelesPorPulgada: Integer;
    FVentanaVigilada: HWND;
    FEstilo: TEstiloVentanaEspera;
    FMaqueta: TMaquetaEspera;
    FTitulo: string;
    FMostrada: Boolean;
    FVentana: HWND;
    FBarra: HWND;
    FBoton: HWND;
    FTexto: HWND;
    FFuente: HFONT;
    FFuenteNegrita: HFONT;
    FFuenteTexto: HFONT;
    FFase: string;
    FDetalle: string;
    FTiempo: string;
    FInicio: UInt64;
    FCancelado: Integer;
    FCreada: TEvent;
    function Escalar(AValor: Integer): Integer;
    function CrearVentana: Boolean;
    procedure CrearFuentes;
    procedure CrearControles;
    procedure Colocar;
    procedure LiberarFuentes;
    procedure Pintar;
    procedure PintarTexto(
      AContexto: HDC;
      AFuente: HFONT;
      AArriba, AAlto: Integer;
      const ATexto: string;
      AAlineacion: UINT);
    procedure CambiarTexto(var ADestino: string; ALParam: LPARAM);
    procedure CambiarSentencia(ALParam: LPARAM);
    procedure InvalidarTextos;
    procedure ReiniciarTiempo;
    procedure ActualizarTiempo;
    procedure InvalidarTiempo;
    procedure Cancelar;
    function VentanaVigiladaUtilizable: Boolean;
    procedure AjustarAVentanaVigilada;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AReferencia: TRect;
      APixelesPorPulgada: Integer;
      AVentanaVigilada: HWND;
      AEstilo: TEstiloVentanaEspera;
      const ATitulo: string);
    destructor Destroy; override;
    function Procesar(
      AVentana: HWND;
      AMensaje: UINT;
      AWParam: WPARAM;
      ALParam: LPARAM): LRESULT;
    function EstaCancelado: Boolean;
    procedure ReiniciarCancelacion;
    property Creada: TEvent read FCreada;
    property Ventana: HWND read FVentana;
  end;

  TVentanaEspera = class(TInterfacedObject, IVentanaEspera)
  private
    FHilo: THiloVentanaEspera;
    function VentanaLista: HWND;
    procedure Enviar(AMensaje: UINT; AWParam: WPARAM);
    procedure EnviarTexto(AMensaje: UINT; const ATexto: string);
    procedure CerrarHilo;
  public
    constructor Create(
      const AReferencia: TRect;
      APixelesPorPulgada: Integer;
      AVentanaVigilada: HWND;
      AEstilo: TEstiloVentanaEspera;
      const ATitulo: string);
    destructor Destroy; override;
    procedure Mostrar(const AFase: string);
    procedure ActualizarDetalle(const ADetalle: string);
    procedure MostrarTexto(const ATexto: string);
    procedure PermitirCancelar(APermitir: Boolean);
    function Cancelado: Boolean;
    procedure Ocultar;
  end;

// Procedimiento de ventana: delega en el hilo guardado en los datos de
// usuario de la ventana desde WM_NCCREATE.
function VentanaEsperaWndProc(
  AVentana: HWND;
  AMensaje: UINT;
  AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  oHilo: THiloVentanaEspera;
begin
  if AMensaje = WM_NCCREATE then
    SetWindowLongPtr(AVentana, GWLP_USERDATA,
      LONG_PTR(PCreateStruct(ALParam)^.lpCreateParams));
  oHilo := THiloVentanaEspera(
    Pointer(GetWindowLongPtr(AVentana, GWLP_USERDATA)));
  if oHilo <> nil then
    Result := oHilo.Procesar(AVentana, AMensaje, AWParam, ALParam)
  else
    Result := DefWindowProc(AVentana, AMensaje, AWParam, ALParam);
end;

// Vacía la cola de teclado y ratón del hilo que llama. Devuelve cuántos
// mensajes se han descartado.
function DescartarEntradaPendiente: Integer;
var
  oMensaje: TMsg;
begin
  Result := 0;
  while PeekMessage(oMensaje, 0, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE) do
    Inc(Result);
  while PeekMessage(oMensaje, 0, WM_MOUSEFIRST, WM_MOUSELAST, PM_REMOVE) do
    Inc(Result);
end;

function TextoTiempoEspera(AMilisegundos: UInt64): string;
var
  iSegundos: Integer;
begin
  iSegundos := Integer(AMilisegundos div 1000);
  if iSegundos >= 3600 then
    Result := Format('%d:%.2d:%.2d',
      [iSegundos div 3600, (iSegundos div 60) mod 60,
       iSegundos mod 60])
  else
    Result := Format('%d:%.2d',
      [iSegundos div 60, iSegundos mod 60]);
end;

{ THiloVentanaEspera }

constructor THiloVentanaEspera.Create(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer;
  AVentanaVigilada: HWND;
  AEstilo: TEstiloVentanaEspera;
  const ATitulo: string);
begin
  inherited Create(True);
  FReferencia := AReferencia;
  FPixelesPorPulgada := Max(APixelesPorPulgada, PIXELES_POR_PULGADA_BASE);
  FVentanaVigilada := AVentanaVigilada;
  FEstilo := AEstilo;
  FTitulo := ATitulo;
  if AEstilo = eveProcesoSegundoPlano then
    FMaqueta := cMaquetaProceso
  else
    FMaqueta := cMaquetaAcompania;
  FMostrada := False;
  FCreada := TEvent.Create(nil, True, False, '');
end;

destructor THiloVentanaEspera.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FCreada);
end;

function THiloVentanaEspera.Escalar(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, FPixelesPorPulgada, PIXELES_POR_PULGADA_BASE);
end;

function THiloVentanaEspera.CrearVentana: Boolean;
var
  hPuntero: HCURSOR;
  iEstilo: DWORD;
  iEstiloEx: DWORD;
  oClase: TWndClassEx;
  sClase: string;
begin
  // La que acompania a una pantalla ensenia el reloj de arena: ahi el
  // programa esta esperando. La de un proceso suelto, no: el programa
  // sigue funcionando y en su cuadro de texto se puede seleccionar.
  if FEstilo = eveProcesoSegundoPlano then
  begin
    sClase := cClaseVentanaProceso;
    hPuntero := LoadCursor(0, IDC_ARROW);
  end
  else
  begin
    sClase := cClaseVentanaEspera;
    hPuntero := LoadCursor(0, IDC_WAIT);
  end;
  FillChar(oClase, SizeOf(oClase), 0);
  oClase.cbSize := SizeOf(oClase);
  oClase.lpfnWndProc := @VentanaEsperaWndProc;
  oClase.hInstance := HInstance;
  oClase.hCursor := hPuntero;
  oClase.hbrBackground := HBRUSH(COLOR_BTNFACE + 1);
  oClase.lpszClassName := PChar(sClase);
  if (RegisterClassEx(oClase) = 0) and
     (GetLastError <> ERROR_CLASS_ALREADY_EXISTS) then
    Result := False
  else
  begin
    // Sin WS_EX_TOPMOST: la espera acompana al programa, no se pone
    // sobre las demas aplicaciones. Se mantiene encima de la ventana
    // que espera desde AjustarAVentanaVigilada.
    if FEstilo = eveProcesoSegundoPlano then
    begin
      iEstilo := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or
        WS_MINIMIZEBOX;
      iEstiloEx := WS_EX_APPWINDOW;
    end
    else
    begin
      iEstilo := WS_POPUP or WS_BORDER;
      iEstiloEx := WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE;
    end;
    FVentana := CreateWindowEx(
      iEstiloEx,
      PChar(sClase), PChar(FTitulo), iEstilo,
      0, 0, Escalar(FMaqueta.Ancho), Escalar(FMaqueta.Alto),
      0, 0, HInstance, Pointer(Self));
    Result := FVentana <> 0;
  end;
end;

procedure THiloVentanaEspera.CrearFuentes;
var
  oFuente: TLogFont;
begin
  FillChar(oFuente, SizeOf(oFuente), 0);
  oFuente.lfHeight := -MulDiv(PUNTOS_FUENTE, FPixelesPorPulgada, 72);
  oFuente.lfWeight := FW_NORMAL;
  oFuente.lfCharSet := DEFAULT_CHARSET;
  oFuente.lfQuality := CLEARTYPE_QUALITY;
  StrPLCopy(oFuente.lfFaceName, NombreFuenteInterfaz(NOMBRE_FUENTE),
    LF_FACESIZE - 1);
  FFuente := CreateFontIndirect(oFuente);
  oFuente.lfWeight := FW_BOLD;
  FFuenteNegrita := CreateFontIndirect(oFuente);
  oFuente.lfWeight := FW_NORMAL;
  oFuente.lfHeight := -MulDiv(PUNTOS_FUENTE_TEXTO, FPixelesPorPulgada, 72);
  StrPLCopy(oFuente.lfFaceName, NombreFuenteInterfaz(NOMBRE_FUENTE_TEXTO),
    LF_FACESIZE - 1);
  FFuenteTexto := CreateFontIndirect(oFuente);
end;

procedure THiloVentanaEspera.LiberarFuentes;
begin
  if FFuente <> 0 then
    DeleteObject(FFuente);
  if FFuenteNegrita <> 0 then
    DeleteObject(FFuenteNegrita);
  if FFuenteTexto <> 0 then
    DeleteObject(FFuenteTexto);
  FFuente := 0;
  FFuenteNegrita := 0;
  FFuenteTexto := 0;
end;

procedure THiloVentanaEspera.CrearControles;
var
  oControles: TInitCommonControlsEx;
begin
  oControles.dwSize := SizeOf(oControles);
  oControles.dwICC := ICC_PROGRESS_CLASS;
  InitCommonControlsEx(oControles);
  if FMaqueta.AltoTexto > 0 then
  begin
    // Solo lectura y con las dos barras: el SQL largo se lee entero sin
    // que nadie pueda tocarlo mientras corre.
    FTexto := CreateWindowEx(WS_EX_CLIENTEDGE, 'EDIT', '',
      WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or
      ES_MULTILINE or ES_READONLY,
      0, 0, 0, 0, FVentana, 0, HInstance, nil);
    SendMessage(FTexto, WM_SETFONT, WPARAM(FFuenteTexto), 1);
  end;
  FBarra := CreateWindowEx(0, PROGRESS_CLASS, '',
    WS_CHILD or WS_VISIBLE or PBS_MARQUEE,
    0, 0, 0, 0, FVentana, 0, HInstance, nil);
  SendMessage(FBarra, PBM_SETMARQUEE, 1, INTERVALO_MARQUEE_MS);
  FBoton := CreateWindowEx(0, 'BUTTON', PChar(SCaptionCancelar),
    WS_CHILD or WS_VISIBLE or WS_DISABLED or BS_PUSHBUTTON,
    0, 0, 0, 0, FVentana, HMENU(ID_BOTON_CANCELAR), HInstance, nil);
  SendMessage(FBoton, WM_SETFONT, WPARAM(FFuente), 1);
end;

procedure THiloVentanaEspera.Colocar;
var
  iAncho: Integer;
  iAlto: Integer;
  iAnchoCliente: Integer;
  iAltoCliente: Integer;
  iIzquierda: Integer;
  iArriba: Integer;
  oMarco: TRect;
  oMonitor: TMonitorInfo;
begin
  // La maqueta esta medida sobre el area de trabajo: con barra de titulo
  // la ventana crece por fuera, pero los controles no se mueven.
  iAnchoCliente := Escalar(FMaqueta.Ancho);
  iAltoCliente := Escalar(FMaqueta.Alto);
  oMarco := TRect.Create(0, 0, iAnchoCliente, iAltoCliente);
  AdjustWindowRectEx(oMarco,
    DWORD(GetWindowLongPtr(FVentana, GWL_STYLE)), False,
    DWORD(GetWindowLongPtr(FVentana, GWL_EXSTYLE)));
  iAncho := oMarco.Width;
  iAlto := oMarco.Height;
  iIzquierda := FReferencia.Left + (FReferencia.Width - iAncho) div 2;
  iArriba := FReferencia.Top + (FReferencia.Height - iAlto) div 2;
  oMonitor.cbSize := SizeOf(oMonitor);
  if GetMonitorInfo(
       MonitorFromRect(@FReferencia, MONITOR_DEFAULTTONEAREST),
       @oMonitor) then
  begin
    iIzquierda := Max(oMonitor.rcWork.Left,
      Min(iIzquierda, oMonitor.rcWork.Right - iAncho));
    iArriba := Max(oMonitor.rcWork.Top,
      Min(iArriba, oMonitor.rcWork.Bottom - iAlto));
  end;
  SetWindowPos(FVentana, HWND_TOP, iIzquierda, iArriba, iAncho, iAlto,
    SWP_NOACTIVATE);
  if FTexto <> 0 then
    MoveWindow(FTexto, Escalar(FMaqueta.Margen),
      Escalar(FMaqueta.ArribaTexto),
      iAnchoCliente - 2 * Escalar(FMaqueta.Margen),
      Escalar(FMaqueta.AltoTexto), True);
  MoveWindow(FBarra, Escalar(FMaqueta.Margen),
    Escalar(FMaqueta.ArribaBarra),
    iAnchoCliente - 2 * Escalar(FMaqueta.Margen),
    Escalar(FMaqueta.AltoBarra), True);
  MoveWindow(FBoton, (iAnchoCliente - Escalar(FMaqueta.AnchoBoton)) div 2,
    Escalar(FMaqueta.ArribaBoton), Escalar(FMaqueta.AnchoBoton),
    Escalar(FMaqueta.AltoBoton), True);
end;

procedure THiloVentanaEspera.PintarTexto(
  AContexto: HDC;
  AFuente: HFONT;
  AArriba, AAlto: Integer;
  const ATexto: string;
  AAlineacion: UINT);
var
  oRect: TRect;
  hAnterior: HGDIOBJ;
begin
  GetClientRect(FVentana, oRect);
  oRect.Left := Escalar(FMaqueta.Margen);
  oRect.Right := oRect.Right - Escalar(FMaqueta.Margen);
  oRect.Top := AArriba;
  oRect.Bottom := AArriba + AAlto;
  hAnterior := SelectObject(AContexto, AFuente);
  try
    DrawText(AContexto, PChar(ATexto), Length(ATexto), oRect,
      AAlineacion or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
  finally
    SelectObject(AContexto, hAnterior);
  end;
end;

procedure THiloVentanaEspera.Pintar;
var
  oPintado: TPaintStruct;
  hContexto: HDC;
begin
  hContexto := BeginPaint(FVentana, oPintado);
  try
    FillRect(hContexto, oPintado.rcPaint, GetSysColorBrush(COLOR_BTNFACE));
    SetBkMode(hContexto, TRANSPARENT);
    SetTextColor(hContexto, GetSysColor(COLOR_BTNTEXT));
    PintarTexto(hContexto, FFuenteNegrita,
      Escalar(FMaqueta.ArribaFase), Escalar(FMaqueta.AltoFase), FFase,
      DT_CENTER);
    PintarTexto(hContexto, FFuente,
      Escalar(FMaqueta.ArribaDetalle), Escalar(FMaqueta.AltoDetalle),
      FDetalle, DT_CENTER);
    PintarTexto(hContexto, FFuente,
      Escalar(FMaqueta.ArribaBoton), Escalar(FMaqueta.AltoBoton), FTiempo,
      DT_RIGHT);
  finally
    EndPaint(FVentana, oPintado);
  end;
end;

procedure THiloVentanaEspera.InvalidarTextos;
var
  oRect: TRect;
begin
  GetClientRect(FVentana, oRect);
  oRect.Bottom := Escalar(FMaqueta.ArribaDetalle + FMaqueta.AltoDetalle);
  InvalidateRect(FVentana, @oRect, False);
end;

// El cronometro arranca con cada Mostrar y lo lleva este hilo, asi que
// sigue contando y repintandose con el hilo principal bloqueado.
procedure THiloVentanaEspera.ReiniciarTiempo;
begin
  FInicio := GetTickCount64;
  FTiempo := TextoTiempoEspera(0);
  InvalidarTiempo;
end;

procedure THiloVentanaEspera.ActualizarTiempo;
var
  sTiempo: string;
begin
  sTiempo := TextoTiempoEspera(GetTickCount64 - FInicio);
  if sTiempo <> FTiempo then
  begin
    FTiempo := sTiempo;
    InvalidarTiempo;
  end;
end;

procedure THiloVentanaEspera.InvalidarTiempo;
var
  oRect: TRect;
begin
  GetClientRect(FVentana, oRect);
  oRect.Left := oRect.Right -
    Escalar(FMaqueta.Margen + FMaqueta.AnchoTiempo);
  oRect.Top := Escalar(FMaqueta.ArribaBoton);
  oRect.Bottom := oRect.Top + Escalar(FMaqueta.AltoBoton);
  InvalidateRect(FVentana, @oRect, False);
end;

procedure THiloVentanaEspera.CambiarTexto(
  var ADestino: string;
  ALParam: LPARAM);
var
  pTexto: PChar;
begin
  pTexto := PChar(ALParam);
  if pTexto <> nil then
  begin
    ADestino := pTexto;
    StrDispose(pTexto);
  end
  else
    ADestino := '';
  InvalidarTextos;
end;

procedure THiloVentanaEspera.CambiarSentencia(ALParam: LPARAM);
var
  pTexto: PChar;
begin
  pTexto := PChar(ALParam);
  try
    if FTexto <> 0 then
    begin
      if pTexto <> nil then
        SetWindowText(FTexto, pTexto)
      else
        SetWindowText(FTexto, '');
      SendMessage(FTexto, EM_SETSEL, 0, 0);
      SendMessage(FTexto, EM_SCROLLCARET, 0, 0);
    end;
  finally
    if pTexto <> nil then
      StrDispose(pTexto);
  end;
end;

procedure THiloVentanaEspera.Cancelar;
begin
  AtomicExchange(FCancelado, 1);
  EnableWindow(FBoton, False);
  FDetalle := SCaptionCancelandoOperacion;
  InvalidarTextos;
end;

// La ventana vigilada deja de servir de referencia mientras esta
// minimizada u oculta: es lo que ocurre al minimizar el programa.
function THiloVentanaEspera.VentanaVigiladaUtilizable: Boolean;
begin
  Result := (FVentanaVigilada = 0) or
    (IsWindow(FVentanaVigilada) and
     IsWindowVisible(FVentanaVigilada) and
     not IsIconic(FVentanaVigilada));
end;

// Iguala la visibilidad de la espera a la de la ventana que espera y,
// cuando se ve, la coloca justo encima de ella. Se llama desde el
// temporizador mientras la espera esta pedida. Si el usuario la ha
// minimizado, se queda donde la dejo.
procedure THiloVentanaEspera.AjustarAVentanaVigilada;
var
  bDebeVerse: Boolean;
  hAnterior: HWND;
  oReferencia, oVentana: TRect;
begin
  if not IsIconic(FVentana) then
  begin
    bDebeVerse := FMostrada and VentanaVigiladaUtilizable;
    if bDebeVerse <> IsWindowVisible(FVentana) then
    begin
      if bDebeVerse then
        ShowWindow(FVentana, SW_SHOWNOACTIVATE)
      else
        ShowWindow(FVentana, SW_HIDE);
    end;
    if bDebeVerse and (FEstilo = eveAcompaniaVentana) and
       IsWindow(FVentanaVigilada) then
    begin
      // Justo sobre la vigilada, sin adelantar otras aplicaciones ni
      // enlazar las colas de entrada de ambos hilos mediante un owner.
      hAnterior := GetWindow(FVentanaVigilada, GW_HWNDPREV);
      if hAnterior = FVentana then
        hAnterior := GetWindow(FVentana, GW_HWNDPREV);
      if hAnterior = 0 then
        hAnterior := HWND_TOP;
      GetWindowRect(FVentanaVigilada, oReferencia);
      GetWindowRect(FVentana, oVentana);
      SetWindowPos(FVentana, hAnterior,
        oReferencia.Left + (oReferencia.Width - oVentana.Width) div 2,
        oReferencia.Top + (oReferencia.Height - oVentana.Height) div 2,
        0, 0, SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
    end;
  end;
end;

function THiloVentanaEspera.EstaCancelado: Boolean;
begin
  Result := AtomicCmpExchange(FCancelado, 0, 0) <> 0;
end;

procedure THiloVentanaEspera.ReiniciarCancelacion;
begin
  AtomicExchange(FCancelado, 0);
end;

function THiloVentanaEspera.Procesar(
  AVentana: HWND;
  AMensaje: UINT;
  AWParam: WPARAM;
  ALParam: LPARAM): LRESULT;
begin
  Result := 0;
  case AMensaje of
    WM_NCCREATE:
      begin
        FVentana := AVentana;
        Result := DefWindowProc(AVentana, AMensaje, AWParam, ALParam);
      end;
    WM_CREATE:
      begin
        CrearFuentes;
        CrearControles;
        Colocar;
      end;
    WM_PAINT:
      Pintar;
    // El cuadro de solo lectura se pinta como tal, no como fondo de
    // ventana: asi se ve que es un texto que se puede recorrer.
    WM_CTLCOLORSTATIC:
      begin
        SetBkColor(HDC(AWParam), GetSysColor(COLOR_WINDOW));
        SetTextColor(HDC(AWParam), GetSysColor(COLOR_WINDOWTEXT));
        Result := LRESULT(GetSysColorBrush(COLOR_WINDOW));
      end;
    WM_COMMAND:
      if (LoWord(AWParam) = ID_BOTON_CANCELAR) and
         (HiWord(AWParam) = BN_CLICKED) then
        Cancelar;
    // La X de la ventana de un proceso no la cierra: seria dejarlo
    // trabajando sin nada a la vista. Vale por el boton Cancelar y la
    // ventana se va cuando el proceso termina de verdad.
    WM_CLOSE:
      Cancelar;
    WM_ESPERA_MOSTRAR:
      begin
        FMostrada := True;
        ReiniciarTiempo;
        SetTimer(AVentana, ID_TEMPORIZADOR_VIGILANCIA,
          INTERVALO_VIGILANCIA_MS, nil);
        AjustarAVentanaVigilada;
      end;
    WM_ESPERA_OCULTAR:
      begin
        FMostrada := False;
        KillTimer(AVentana, ID_TEMPORIZADOR_VIGILANCIA);
        ShowWindow(AVentana, SW_HIDE);
      end;
    WM_TIMER:
      if AWParam = ID_TEMPORIZADOR_VIGILANCIA then
      begin
        ActualizarTiempo;
        AjustarAVentanaVigilada;
      end;
    WM_ESPERA_FASE:
      CambiarTexto(FFase, ALParam);
    WM_ESPERA_DETALLE:
      CambiarTexto(FDetalle, ALParam);
    WM_ESPERA_TEXTO:
      CambiarSentencia(ALParam);
    WM_ESPERA_CANCELABLE:
      EnableWindow(FBoton, AWParam <> 0);
    WM_ESPERA_CERRAR:
      begin
        KillTimer(AVentana, ID_TEMPORIZADOR_VIGILANCIA);
        DestroyWindow(AVentana);
      end;
    WM_DESTROY:
      PostQuitMessage(0);
  else
    Result := DefWindowProc(AVentana, AMensaje, AWParam, ALParam);
  end;
end;

procedure THiloVentanaEspera.Execute;
var
  oMensaje: TMsg;
begin
  NameThreadForDebugging('VentanaEspera');
  try
    if CrearVentana then
    begin
      FCreada.SetEvent;
      while GetMessage(oMensaje, 0, 0, 0) do
      begin
        TranslateMessage(oMensaje);
        DispatchMessage(oMensaje);
      end;
    end;
  finally
    LiberarFuentes;
    FCreada.SetEvent;
  end;
end;

{ TVentanaEspera }

constructor TVentanaEspera.Create(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer;
  AVentanaVigilada: HWND;
  AEstilo: TEstiloVentanaEspera;
  const ATitulo: string);
begin
  inherited Create;
  FHilo := THiloVentanaEspera.Create(
    AReferencia, APixelesPorPulgada, AVentanaVigilada, AEstilo, ATitulo);
  FHilo.Start;
end;

destructor TVentanaEspera.Destroy;
begin
  if FHilo <> nil then
  begin
    CerrarHilo;
    FreeAndNil(FHilo);
  end;
  inherited Destroy;
end;

function TVentanaEspera.VentanaLista: HWND;
begin
  Result := 0;
  if (FHilo <> nil) and
     (FHilo.Creada.WaitFor(ESPERA_CREACION_MS) = wrSignaled) then
    Result := FHilo.Ventana;
end;

procedure TVentanaEspera.Enviar(AMensaje: UINT; AWParam: WPARAM);
var
  hVentana: HWND;
begin
  hVentana := VentanaLista;
  if hVentana <> 0 then
    PostMessage(hVentana, AMensaje, AWParam, 0);
end;

procedure TVentanaEspera.EnviarTexto(AMensaje: UINT; const ATexto: string);
var
  hVentana: HWND;
  pTexto: PChar;
begin
  hVentana := VentanaLista;
  if hVentana <> 0 then
  begin
    pTexto := StrNew(PChar(ATexto));
    if not PostMessage(hVentana, AMensaje, 0, LPARAM(pTexto)) then
      StrDispose(pTexto);
  end;
end;

procedure TVentanaEspera.CerrarHilo;
var
  hVentana: HWND;
begin
  hVentana := VentanaLista;
  if hVentana <> 0 then
    PostMessage(hVentana, WM_ESPERA_CERRAR, 0, 0);
  if WaitForSingleObject(FHilo.Handle, ESPERA_CIERRE_MS) <> WAIT_OBJECT_0 then
    PostThreadMessage(FHilo.ThreadID, WM_QUIT, 0, 0);
end;

procedure TVentanaEspera.Mostrar(const AFase: string);
begin
  if FHilo <> nil then
    FHilo.ReiniciarCancelacion;
  EnviarTexto(WM_ESPERA_FASE, AFase);
  EnviarTexto(WM_ESPERA_DETALLE, '');
  Enviar(WM_ESPERA_MOSTRAR, 0);
end;

procedure TVentanaEspera.ActualizarDetalle(const ADetalle: string);
begin
  EnviarTexto(WM_ESPERA_DETALLE, ADetalle);
end;

procedure TVentanaEspera.MostrarTexto(const ATexto: string);
begin
  // El control de edicion necesita los saltos de linea de Windows.
  EnviarTexto(WM_ESPERA_TEXTO, AdjustLineBreaks(ATexto, tlbsCRLF));
end;

procedure TVentanaEspera.PermitirCancelar(APermitir: Boolean);
begin
  Enviar(WM_ESPERA_CANCELABLE, WPARAM(Ord(APermitir)));
end;

function TVentanaEspera.Cancelado: Boolean;
begin
  Result := (FHilo <> nil) and FHilo.EstaCancelado;
end;

procedure TVentanaEspera.Ocultar;
begin
  Enviar(WM_ESPERA_OCULTAR, 0);
  DescartarEntradaPendiente;
end;

function CrearVentanaEspera(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer;
  AVentanaVigilada: HWND): IVentanaEspera;
begin
  Result := TVentanaEspera.Create(
    AReferencia, APixelesPorPulgada, AVentanaVigilada,
    eveAcompaniaVentana, '');
end;

function CrearVentanaProcesoSegundoPlano(
  const AReferencia: TRect;
  APixelesPorPulgada: Integer;
  const ATitulo: string): IVentanaEspera;
begin
  Result := TVentanaEspera.Create(
    AReferencia, APixelesPorPulgada, 0,
    eveProcesoSegundoPlano, ATitulo);
end;

type
  TArrastreDuranteEspera = record
    Ventana: HWND;
    Inicio: TPoint;
    Limites: TRect;
  end;

procedure TerminarArrastre(var AArrastre: TArrastreDuranteEspera);
begin
  if AArrastre.Ventana <> 0 then
  begin
    if GetCapture = AArrastre.Ventana then
      ReleaseCapture;
    AArrastre.Ventana := 0;
  end;
end;

procedure AtenderBarraTitulo(var AArrastre: TArrastreDuranteEspera);
var
  oMensaje: TMsg;
  oPunto: TPoint;
begin
  // No se despacha WM_NCLBUTTONDOWN: DefWindowProc abriría un bucle
  // modal de movimiento que también despacha acciones de negocio.
  while PeekMessage(oMensaje, 0,
    WM_NCMOUSEMOVE, WM_NCXBUTTONDBLCLK, PM_REMOVE) do
    if (oMensaje.message = WM_NCLBUTTONDOWN) and
       IsWindowEnabled(oMensaje.hwnd) then
    begin
      if oMensaje.wParam = HTMINBUTTON then
      begin
        TerminarArrastre(AArrastre);
        SendMessage(oMensaje.hwnd, WM_SYSCOMMAND, SC_MINIMIZE, 0);
      end
      else if oMensaje.wParam = HTCAPTION then
      begin
        TerminarArrastre(AArrastre);
        AArrastre.Ventana := oMensaje.hwnd;
        AArrastre.Inicio.X := SmallInt(LoWord(oMensaje.lParam));
        AArrastre.Inicio.Y := SmallInt(HiWord(oMensaje.lParam));
        GetWindowRect(oMensaje.hwnd, AArrastre.Limites);
        SetCapture(oMensaje.hwnd);
      end;
    end;
  if AArrastre.Ventana <> 0 then
  begin
    if GetCapture <> AArrastre.Ventana then
      TerminarArrastre(AArrastre)
    else
      while PeekMessage(oMensaje, 0,
        WM_MOUSEFIRST, WM_MOUSELAST, PM_REMOVE) do
      begin
        if (AArrastre.Ventana <> 0) and
           (oMensaje.message = WM_MOUSEMOVE) then
        begin
          oPunto.X := SmallInt(LoWord(oMensaje.lParam));
          oPunto.Y := SmallInt(HiWord(oMensaje.lParam));
          ClientToScreen(oMensaje.hwnd, oPunto);
          SetWindowPos(AArrastre.Ventana, 0,
            AArrastre.Limites.Left + oPunto.X - AArrastre.Inicio.X,
            AArrastre.Limites.Top + oPunto.Y - AArrastre.Inicio.Y,
            0, 0, SWP_NOSIZE or SWP_NOZORDER or SWP_NOACTIVATE);
        end;
        if oMensaje.message = WM_LBUTTONUP then
          TerminarArrastre(AArrastre);
      end;
  end;
  while PeekMessage(oMensaje, 0, WM_PAINT, WM_PAINT, PM_REMOVE) do
    DispatchMessage(oMensaje);
end;

procedure EsperarTareaAtendiendoMensajes(const ATarea: ITask);
begin
  EsperarTareaAtendiendoMensajes(ATarea, nil);
end;

procedure EsperarTareaAtendiendoMensajes(
  const ATarea: ITask;
  const AVigilar: TProc);
var
  oMensaje: TMsg;
  oArrastre: TArrastreDuranteEspera;
begin
  oArrastre := Default(TArrastreDuranteEspera);
  try
    if Assigned(ATarea) then
      while not (ATarea.Status in [TTaskStatus.Completed,
        TTaskStatus.Canceled, TTaskStatus.Exception]) do
      begin
        // PeekMessage sin extraer entrega SendMessage de otros hilos.
        PeekMessage(oMensaje, 0, 0, 0, PM_NOREMOVE);
        CheckSynchronize(INTERVALO_SONDEO_TAREA_MS);
        AtenderBarraTitulo(oArrastre);
        AtenderMinimizarYRestaurar;
        if Assigned(AVigilar) then
          AVigilar();
      end;
  finally
    TerminarArrastre(oArrastre);
  end;
end;

procedure AtenderMinimizarYRestaurar;
var
  oMensaje: TMsg;
begin
  // Solo se retiran de la cola las órdenes de sistema: teclado, ratón y
  // temporizadores siguen sin despacharse mientras dura la espera.
  while PeekMessage(
          oMensaje, 0, WM_SYSCOMMAND, WM_SYSCOMMAND, PM_REMOVE) do
    case oMensaje.wParam and $FFF0 of
      SC_MINIMIZE, SC_RESTORE:
        DispatchMessage(oMensaje);
    end;
end;

end.
