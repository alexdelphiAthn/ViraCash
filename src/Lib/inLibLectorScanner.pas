unit inLibLectorScanner;
{ Detector reutilizable de lector de codigo de barras a nivel de formulario.
  Encapsula las dos formas de deteccion que estaban duplicadas en caja,
  consulta de stock y traspasos, para poder incorporarlas a cualquier
  mantenimiento nuevo sin volver a copiar el codigo:
    1) Trama STX(#2) + codigo + ETX(#3): el lector envuelve el codigo. Las
       teclas se consumen para no ensuciar el control con foco. Si el lector
       remata la trama con CR, LF o CR/LF, se consumen esos controles si
       llegan en la misma rafaga que ETX para no activar el control con foco.
    2) Por VELOCIDAD de tecleo (codigo de barras + CR, sin STX/ETX): el lector
       teclea en rafaga. Medimos la cadencia (ms entre teclas) con GetTickCount;
       si el Enter llega igual de rapido tras una rafaga lo bastante larga, lo
       tratamos como una lectura.
  El procesado del codigo es responsabilidad del formulario (evento
  OnCodigoLeido): la unidad solo DETECTA. El procesado se difiere fuera del
  flujo de teclas con una ventana oculta propia (AllocateHWnd), de modo que el
  formulario no necesita declarar su propio mensaje WM_USER ni su manejador.
  Para incorporarlo a un mantenimiento basta con: crear la instancia en el
  OnCreate, asignar OnCodigoLeido, llamar a KeyDown/KeyPress desde los eventos
  OnKeyDown/OnKeyPress del form (que debe tener KeyPreview := True) y liberar la
  instancia en el OnDestroy.
  El Enter que cierra la lectura conviene entregarlo ademas desde OnShortCut
  del form (AtajoTeclado): ese evento se dispara en CN_KEYDOWN, ANTES que
  CM_DIALOGKEY (jvEnterTab convierte Enter en Tab) y que el boton con foco
  (Enter = clic), que de otro modo se quedan con la tecla sin que OnKeyDown
  llegue a verla cuando el foco no esta en una rejilla. }

interface
uses
  Windows, Messages, Classes, Controls, System.Generics.Collections;
type
  // El form resuelve y aplica el codigo leido (logica de negocio).
  TEventoCodigoLeido = procedure(Sender: TObject;
                                 const ACodigo: string) of object;
  // Consultas opcionales para afinar el detector por velocidad cuando hay una
  // rejilla editable de por medio.
  TConsultaBooleana = function: Boolean of object;
  TConsultaControl  = function(AControl: TControl): Boolean of object;
  TLectorScanner = class(TObject)
  private
    // --- Configuracion (la puebla el formulario tras crear la instancia) -----
    FActivo: Boolean;
    FUmbralMs: Cardinal;
    FLongitudMinima: Integer;
    FConsumirRafaga: Boolean;
    FOmitirEnRejilla: Boolean;
    // --- Estado interno del detector
    // ------------------------------------------
    FHandle: HWND;
    FLeyendoTrama: Boolean;
    FBufferTrama: string;
    FBufferVel: string;
    FTick: Cardinal;
    FCaracterConsumido: Char;
    FControl: TWinControl;
    FTextoPrevio: string;
    FInicioChar: Char;
    FEsperaEco: Boolean;
    FRejillaEditaba: Boolean;
    FCodigosPendientes: TQueue<string>;
    FProcesandoCodigo: Boolean;
    // Tras ETX se admite un CR, un LF o ambos, por la hora del mensaje.
    FSufijosTrama: set of Byte;
    FTiempoTrama: Cardinal;
    // Modo ConsumirRafaga: teclas rapidas retenidas por si eran del lector.
    // Si la rafaga no se cierra con Enter rapido se devuelven al control
    // con el foco (FZ-ISSUE-110). FEntregando evita volver a retenerlas.
    FRetenidas: string;
    FEntregando: Boolean;
    // Ventana que tenia el foco al retener: un Tab mueve el foco antes de
    // que se devuelvan y no deben acabar en el control siguiente.
    FFocoRetenidas: HWND;
    // --- Eventos
    // ---------------------------------------------------------------
    FOnCodigoLeido: TEventoCodigoLeido;
    FOnLecturaIniciada: TNotifyEvent;
    FOnRejillaEditando: TConsultaBooleana;
    FOnEsControlRejilla: TConsultaControl;
    procedure WndProc(var Msg: TMessage);
    procedure CapturarControl;
    procedure RestaurarControl;
    function EsControlRejilla(AControl: TControl): Boolean;
    function EnRejilla: Boolean;
    function CerrarLecturaConEnter: Boolean;
    function ConsumirSufijoTrama(ACaracter: Char): Boolean;
    procedure EncolarCodigo(const ACodigo: string);
    function GetLecturaPendiente: Boolean;
    procedure ProgramarLiberacion;
    procedure CancelarLiberacion;
    function EsTeclaDeCaracter(ATecla: Word): Boolean;
  protected
    // Entrega las teclas retenidas al control con el foco, en su orden.
    // Sustituible en pruebas.
    procedure EntregarTeclas(const ATexto: string); virtual;
    // Relojes sustituibles en pruebas: cadencia de tecleo (GetTickCount) y
    // hora en que Windows encolo la tecla en curso (GetMessageTime).
    function TiempoActual: Cardinal; virtual;
    function TiempoMensaje: Cardinal; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    // Se invocan desde OnKeyDown / OnKeyPress del formulario (KeyPreview=True).
    procedure KeyDown(var Key: Word; Shift: TShiftState);
    procedure KeyPress(var Key: Char);
    // Se invoca desde OnShortCut del formulario. True si el Enter cierra una
    // lectura (rafaga rapida o CR que el lector envia tras ETX) y se ha
    // consumido: el form debe marcar Handled para que no llegue a jvEnterTab
    // ni al control con foco.
    function AtajoTeclado(var AMensaje: TWMKey): Boolean;
    // Captura la trama antes de los atajos y controles del formulario.
    // Solo consume mensajes dirigidos a este contenedor o a sus hijos.
    function MensajeTrama(var AMensaje: TMsg;
      AContenedor: TWinControl): Boolean;
    // Devuelve al control las teclas retenidas de una rafaga que no era del
    // lector. La llaman las teclas siguientes y el temporizador interno.
    procedure LiberarRetenidas;
    property Retenidas: string read FRetenidas;
    // True mientras se acumula una trama STX/ETX (lo consulta el form para,
    // p.ej., no relanzar su timer de busqueda incremental).
    property LeyendoTrama: Boolean read FLeyendoTrama;
    property LecturaPendiente: Boolean read GetLecturaPendiente;
    // Detector por VELOCIDAD (codigo + CR sin STX/ETX). Apagado por
    // defecto: por decision del usuario (05/10/2026, FZ-ISSUE-230) solo la
    // trama STX/ETX cuenta como lectura en todas las pantallas; lo
    // tecleado deprisa (una cantidad + Intro) se tomaba por un codigo.
    // La trama STX/ETX actua siempre.
    property Activo: Boolean read FActivo write FActivo;
    // Cadencia maxima (ms) entre teclas para considerarlas rafaga del lector.
    property UmbralMs: Cardinal read FUmbralMs write FUmbralMs;
    // Longitud minima del codigo para aceptar la rafaga como lectura.
    property LongitudMinima: Integer read FLongitudMinima
                                     write FLongitudMinima;
    // True: las teclas rapidas de la rafaga se consumen (no llegan al control,
    // util si el control dispara logica costosa en cada cambio). False: se
    // dejan pasar y se restaura el texto previo del control al cerrar.
    property ConsumirRafaga: Boolean read FConsumirRafaga
                                     write FConsumirRafaga;
    // True: el detector por velocidad permanece pasivo si el foco esta en la
    // rejilla (la lectura en celda la resuelve otro mecanismo). Requiere
    // OnEsControlRejilla.
    property OmitirEnRejilla: Boolean read FOmitirEnRejilla
                                      write FOmitirEnRejilla;
    property OnCodigoLeido: TEventoCodigoLeido read FOnCodigoLeido
                                               write FOnCodigoLeido;
    property OnLecturaIniciada: TNotifyEvent read FOnLecturaIniciada
                                             write FOnLecturaIniciada;
    property OnRejillaEditando: TConsultaBooleana read FOnRejillaEditando
                                                  write FOnRejillaEditando;
    property OnEsControlRejilla: TConsultaControl read FOnEsControlRejilla
                                                  write FOnEsControlRejilla;
  end;

implementation

uses
  Forms, SysUtils, cxTextEdit, cxEdit;
const
  // Mensaje interno para diferir el procesado fuera del KeyPress/KeyDown.
  WM_LECTOR_PROCESAR = WM_USER + 200;
  // Maximo de ms (hora de mensaje) entre ETX y el sufijo CR/LF del lector.
  // Se mide con la hora
  // en que Windows encolo cada tecla, asi que no le afecta lo que tarde el
  // formulario en procesar el codigo entre medias.
  MS_SUFIJO_TRAS_TRAMA = 300;
  // Temporizador que devuelve las teclas retenidas si la rafaga se para
  // sin Enter: varias veces el umbral, sin bajar de este minimo.
  ID_TEMPORIZADOR_RETENIDAS = 1;
  MS_MINIMO_LIBERAR_RETENIDAS = 120;

constructor TLectorScanner.Create;
begin
  inherited Create;
  FCodigosPendientes := TQueue<string>.Create;
  FHandle := Classes.AllocateHWnd(WndProc);
  FActivo := False;
  FUmbralMs := 40;
  FLongitudMinima := 4;
  FConsumirRafaga := False;
  FOmitirEnRejilla := False;
end;

destructor TLectorScanner.Destroy;
begin
  if FHandle <> 0 then
  begin
    KillTimer(FHandle, ID_TEMPORIZADOR_RETENIDAS);
    Classes.DeallocateHWnd(FHandle);
  end;
  FCodigosPendientes.Free;
  inherited Destroy;
end;

function TLectorScanner.TiempoActual: Cardinal;
begin
  Result := GetTickCount;
end;

function TLectorScanner.TiempoMensaje: Cardinal;
begin
  Result := Cardinal(GetMessageTime);
end;

// Recibe el mensaje diferido y dispara el procesado de negocio ya fuera del
// flujo de teclas (cxGrid / jvEnterTab han terminado de procesar la tecla).
procedure TLectorScanner.WndProc(var Msg: TMessage);
var
  Codigo: string;
begin
  if (Msg.Msg = WM_TIMER) and (Msg.WParam = ID_TEMPORIZADOR_RETENIDAS) then
    LiberarRetenidas
  else if Msg.Msg = WM_LECTOR_PROCESAR then
  begin
    if (not FProcesandoCodigo) and (FCodigosPendientes.Count > 0) then
    begin
      Codigo := FCodigosPendientes.Dequeue;
      FProcesandoCodigo := True;
      try
        if Assigned(FOnCodigoLeido) then
          FOnCodigoLeido(Self, Codigo);
      finally
        FProcesandoCodigo := False;
        if FCodigosPendientes.Count > 0 then
          PostMessage(FHandle, WM_LECTOR_PROCESAR, 0, 0);
      end;
    end;
  end
  else
    Msg.Result := DefWindowProc(FHandle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TLectorScanner.EncolarCodigo(const ACodigo: string);
begin
  if Trim(ACodigo) <> '' then
  begin
    FCodigosPendientes.Enqueue(Trim(ACodigo));
    PostMessage(FHandle, WM_LECTOR_PROCESAR, 0, 0);
  end;
end;

function TLectorScanner.GetLecturaPendiente: Boolean;
begin
  Result := FLeyendoTrama or FProcesandoCodigo or
    (FCodigosPendientes.Count > 0);
end;

function TLectorScanner.MensajeTrama(var AMensaje: TMsg;
  AContenedor: TWinControl): Boolean;
var
  Caracter: Char;
  EsDelContenedor: Boolean;
begin
  Result := False;
  EsDelContenedor := Assigned(AContenedor) and
    AContenedor.HandleAllocated;
  if EsDelContenedor then
    EsDelContenedor := (AMensaje.hwnd = AContenedor.Handle) or
      IsChild(AContenedor.Handle, AMensaje.hwnd);
  if EsDelContenedor then
  begin
    Caracter := #0;
    if AMensaje.message = WM_CHAR then
    begin
      if (AMensaje.wParam = 2) or FLeyendoTrama or
        ((FSufijosTrama <> []) and
        ((AMensaje.wParam = 10) or (AMensaje.wParam = 13))) then
        Caracter := Char(AMensaje.wParam);
    end
    else if AMensaje.message = WM_KEYDOWN then
    begin
      if (AMensaje.wParam = VK_RETURN) and (FSufijosTrama <> []) then
        Caracter := #13
      else if (GetKeyState(VK_CONTROL) < 0) and
        (GetKeyState(VK_MENU) >= 0) then
      begin
        // STX/ETX llegan como Ctrl+B/Ctrl+C; LF puede llegar como Ctrl+J.
        if AMensaje.wParam = Ord('B') then
          Caracter := #2
        else if FLeyendoTrama and (AMensaje.wParam = Ord('C')) then
          Caracter := #3
        else if (FSufijosTrama <> []) and
          (AMensaje.wParam = Ord('J')) then
          Caracter := #10;
      end;
    end;
    if Caracter <> #0 then
    begin
      KeyPress(Caracter);
      Result := Caracter = #0;
    end;
  end;
end;

// True si el control es (o esta dentro de) la rejilla que el form declara como
// suya. Sin callback no hay rejilla -> False.
function TLectorScanner.EsControlRejilla(AControl: TControl): Boolean;
begin
  if Assigned(FOnEsControlRejilla) then
    Result := FOnEsControlRejilla(AControl)
  else
    Result := False;
end;

function TLectorScanner.EnRejilla: Boolean;
begin
  Result := EsControlRejilla(Screen.ActiveControl);
end;

// Guarda el control con foco y su texto al iniciar una rafaga, para poder
// restaurarlo si la lectura entro con el foco fuera de la rejilla. Se llama en
// KeyPress (KeyPreview), antes de que el control reciba el caracter.
procedure TLectorScanner.CapturarControl;
begin
  FControl := Screen.ActiveControl;
  FTextoPrevio := '';
  if (FControl <> nil) and (FControl is TcxCustomTextEdit) then
    FTextoPrevio := TcxCustomTextEdit(FControl).Text;
end;

procedure TLectorScanner.RestaurarControl;
begin
  if (FControl <> nil) and (FControl is TcxCustomTextEdit)
     and (not EsControlRejilla(FControl)) then
  begin
    TcxCustomTextEdit(FControl).Text := FTextoPrevio;
    // El cambio de foco al cerrar la lectura es ASINCRONO: para cuando el
    // control pierde el foco, el flag de escaneo del form ya no esta activo y
    // el cxEdit validaria su contenido al salir (p.ej. "el codigo de cliente
    // no existe"). Marcandolo como NO modificado, ni el OnExit ni la
    // validacion interna del cxEdit se disparan al perder el foco.
    TcxCustomEdit(FControl).EditModified := False;
  end;
  FControl := nil;
  FTextoPrevio := '';
end;

// Acumula la rafaga y la cadencia; la decision final (rafaga + Enter rapido) se
// toma en KeyDown / AtajoTeclado, para adelantarse al editor del grid y a
// jvEnterTab.
procedure TLectorScanner.ProgramarLiberacion;
var
  iMs: Cardinal;
begin
  if FHandle <> 0 then
  begin
    iMs := FUmbralMs * 3;
    if iMs < MS_MINIMO_LIBERAR_RETENIDAS then
      iMs := MS_MINIMO_LIBERAR_RETENIDAS;
    SetTimer(FHandle, ID_TEMPORIZADOR_RETENIDAS, iMs, nil);
  end;
end;

procedure TLectorScanner.CancelarLiberacion;
begin
  if FHandle <> 0 then
    KillTimer(FHandle, ID_TEMPORIZADOR_RETENIDAS);
end;

function TLectorScanner.EsTeclaDeCaracter(ATecla: Word): Boolean;
begin
  Result := (ATecla in [Ord('0')..Ord('9'), Ord('A')..Ord('Z'), VK_SPACE,
                        VK_NUMPAD0..VK_DIVIDE, VK_OEM_1..VK_OEM_8,
                        VK_OEM_102]) or
            (ATecla in [VK_CONTROL, VK_SHIFT, VK_MENU]);
end;

procedure TLectorScanner.EntregarTeclas(const ATexto: string);
var
  hFoco: HWND;
  Caracter: Char;
begin
  hFoco := FFocoRetenidas;
  if (hFoco = 0) or (not IsWindow(hFoco)) then
    hFoco := GetFocus;
  if hFoco <> 0 then
    for Caracter in ATexto do
      SendMessage(hFoco, WM_CHAR, WPARAM(Ord(Caracter)), 0);
end;

procedure TLectorScanner.LiberarRetenidas;
var
  sTexto: string;
begin
  CancelarLiberacion;
  if (FRetenidas <> '') and (not FEntregando) then
  begin
    sTexto := FRetenidas;
    FRetenidas := '';
    // La rafaga deja de ser candidata a lectura: lo retenido era tecleo.
    FBufferVel := '';
    FEntregando := True;
    try
      EntregarTeclas(sTexto);
    finally
      FEntregando := False;
      FFocoRetenidas := 0;
    end;
  end;
end;

procedure TLectorScanner.KeyPress(var Key: Char);
var
  ahora, delta: Cardinal;
begin
  // Las teclas que devuelve LiberarRetenidas pasan sin tocar el detector.
  if FEntregando then
    Exit;
  if Key = #2 then
  begin
    LiberarRetenidas;
    // Inicio de trama STX: empezamos a acumular y avisamos al form (timers...).
    FLeyendoTrama := True;
    FSufijosTrama := [];
    FCaracterConsumido := #0;
    FBufferTrama := '';
    FBufferVel := '';
    FEsperaEco := False;
    Key := #0;
    if Assigned(FOnLecturaIniciada) then
      FOnLecturaIniciada(Self);
  end
  else if FLeyendoTrama then
  begin
    if Key = #3 then
    begin
      FLeyendoTrama := False;
      // El CR/LF que llegue en la misma rafaga que ETX es del lector.
      FSufijosTrama := [10, 13];
      FTiempoTrama := TiempoMensaje;
      Key := #0;
      EncolarCodigo(FBufferTrama);
      FBufferTrama := '';
    end
    else
    begin
      FBufferTrama := FBufferTrama + Key;
      Key := #0;
    end;
  end
  else
  begin
    if (FCaracterConsumido <> #0) and (Key = FCaracterConsumido) then
    begin
      // El caracter de CR/LF ya consumido en KeyDown tampoco llega al foco.
      FCaracterConsumido := #0;
      Key := #0;
    end
    else if ConsumirSufijoTrama(Key) then
      Key := #0;
    if FActivo and (not (FOmitirEnRejilla and EnRejilla)) then
    begin
      // --- Detector por velocidad de tecleo
      // -------------------------------------
      ahora := TiempoActual;
      delta := ahora - FTick;
      FTick := ahora;
      if Key = #0 then
        // Tecla ya consumida: no altera la rafaga.
        FEsperaEco := FEsperaEco
      else if Key >= ' ' then
      begin
        if delta <= FUmbralMs then
        begin
          // Tecla rapida: forma parte de la rafaga del lector.
          if FConsumirRafaga then
          begin
            FBufferVel := FBufferVel + Key;
            if FRetenidas = '' then
              FFocoRetenidas := GetFocus;
            FRetenidas := FRetenidas + Key;
            Key := #0;
            ProgramarLiberacion;
          end
          else if FEsperaEco and (Key = FInicioChar) then
            // Anti-eco: descartamos el reenvio del 1er caracter que hace el
            // cxGrid al arrancar la edicion de la celda.
            FEsperaEco := False
          else
          begin
            FEsperaEco := False;
            FBufferVel := FBufferVel + Key;
          end;
        end
        else
        begin
          // Primer caracter (lento): posible inicio de rafaga. Antes se
          // devuelve lo retenido de la rafaga anterior, para que llegue
          // delante de esta tecla.
          LiberarRetenidas;
          FBufferVel := Key;
          if FConsumirRafaga then
            // No se consume (podria ser manual) ni se captura el control.
            FEsperaEco := False
          else
          begin
            CapturarControl;
            FInicioChar := Key;
            FEsperaEco := EsControlRejilla(FControl) and (not FRejillaEditaba);
          end;
        end;
      end
      else
      begin
        LiberarRetenidas;
        FBufferVel := '';
        FEsperaEco := False;
      end;
    end;
  end;
end;

function TLectorScanner.ConsumirSufijoTrama(ACaracter: Char): Boolean;
begin
  Result := CharInSet(ACaracter, [#10, #13]) and
    (Ord(ACaracter) in FSufijosTrama) and
    ((TiempoMensaje - FTiempoTrama) <= MS_SUFIJO_TRAS_TRAMA);
  if Result and (ACaracter = #13) then
    Exclude(FSufijosTrama, 13)
  else
    FSufijosTrama := [];
end;

// Decide si el Enter que acaba de llegar pertenece al lector y, en ese caso,
// cierra la lectura: CR inmediatamente posterior a una trama STX/ETX (solo se
// descarta) o rafaga rapida acumulada por el detector de velocidad (se
// encamina al procesado). True si el Enter debe consumirse.
function TLectorScanner.CerrarLecturaConEnter: Boolean;
var
  delta: Cardinal;
  Codigo: string;
begin
  Result := ConsumirSufijoTrama(#13);
  if (not Result) and FActivo
     and (not (FOmitirEnRejilla and EnRejilla)) then
  begin
    delta := TiempoActual - FTick;
    if (Length(FBufferVel) >= FLongitudMinima) and (delta <= FUmbralMs) then
    begin
      Codigo := FBufferVel;
      FBufferVel := '';
      // Lo retenido era la lectura: no se devuelve al control.
      FRetenidas := '';
      CancelarLiberacion;
      if not FConsumirRafaga then
        RestaurarControl;
      EncolarCodigo(Codigo);
      Result := True;
    end;
  end;
  // Un Enter que no cierra lectura es tecleo: lo retenido va antes.
  if not Result then
    LiberarRetenidas;
  if Result then
    FCaracterConsumido := #13;
end;

// Cierra el detector por velocidad: si hay rafaga acumulada y el Enter llega
// igual de rapido, lo tratamos como lectura y lo encaminamos al procesado.
procedure TLectorScanner.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // El caracter consumido solo vive entre KeyDown y su KeyPress.
  FCaracterConsumido := #0;
  // Estado de edicion de la rejilla ANTES de esta tecla (KeyPreview corre antes
  // que el KeyDown de la rejilla): lo usa el anti-eco del modo restaurar.
  if Assigned(FOnRejillaEditando) then
    FRejillaEditaba := FOnRejillaEditando()
  else
    FRejillaEditaba := False;
  if Key = VK_RETURN then
  begin
    if CerrarLecturaConEnter then
      Key := 0;
  end
  else if (Key = Ord('J')) and (ssCtrl in Shift) and
    (not (ssAlt in Shift)) then
  begin
    if ConsumirSufijoTrama(#10) then
    begin
      FCaracterConsumido := #10;
      Key := 0;
    end;
  end
  else if not (Key in [VK_CONTROL, VK_SHIFT, VK_MENU]) then
  begin
    FSufijosTrama := [];
    // Tab, flechas, Supr...: lo retenido llega antes que la tecla. Las
    // teclas de caracter se resuelven en KeyPress.
    if not EsTeclaDeCaracter(Key) then
      LiberarRetenidas;
  end;
end;

// Misma decision que KeyDown, pero desde OnShortCut (CN_KEYDOWN): el Enter se
// consume antes de que CM_DIALOGKEY lo convierta en Tab o de que el boton con
// foco lo tome como clic. Si se consume, Windows no genera el #13 de KeyPress
// ni el OnKeyDown, asi que no hay doble procesado.
function TLectorScanner.AtajoTeclado(var AMensaje: TWMKey): Boolean;
begin
  Result := False;
  // OnShortCut llega antes que CM_DIALOGKEY: un Tab o una flecha aun no
  // han movido el foco y lo retenido vuelve a su control (FZ-ISSUE-110).
  if (AMensaje.CharCode <> VK_RETURN) and
     (not EsTeclaDeCaracter(AMensaje.CharCode)) then
    LiberarRetenidas;
  if AMensaje.CharCode = VK_RETURN then
    Result := CerrarLecturaConEnter
  else if (AMensaje.CharCode = Ord('J')) and
    (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) >= 0) then
    Result := ConsumirSufijoTrama(#10);
  if Result then
    AMensaje.CharCode := 0;
end;

end.
