{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMensajesVcl                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cuadros de mensaje propios de la aplicación: ShowMessage_fza,             }
{    ShowMessageFmt_fza, MessageDlg_fza y MessageBox_fza. Construyen el        }
{    diálogo clásico de la VCL (CreateMessageDialog) con la fuente             }
{    corporativa Source Sans 3 en lugar del TaskDialog del sistema, y          }
{    conservan los parámetros y resultados de las funciones originales:        }
{    mrXxx en MessageDlg_fza e IDXXX con indicadores MB_* en MessageBox_fza.   }
{******************************************************************************}
unit inLibMensajesVcl;

interface

uses
  Winapi.Windows, System.UITypes, System.Classes, Vcl.Dialogs;

const
  NOMBRE_FUENTE_MENSAJES = 'Source Sans 3';
  TAMANO_FUENTE_MENSAJES = 11;
  // Tipo de MessageBox que Winapi.Windows no declara.
  MB_CANCELTRYCONTINUE = $00000006;

// Carga las cuatro caras para este proceso antes de crear el logon.
// Evita depender de la notificación de fuentes del instalador.
function CargarFuentesInterfaz(const ADirectorio: string): Integer;
procedure LiberarFuentesInterfaz(const ADirectorio: string);

// Sustituto de ShowMessage: sin icono y con el título de la aplicación.
procedure ShowMessage_fza(const AMensaje: string); overload;
procedure ShowMessage_fza(AOwner: TComponent;
  const AMensaje: string); overload;
procedure ShowMessageFmt_fza(const AFormato: string;
  const AArgumentos: array of const);
// Sustitutos de MessageDlg: mismos parámetros y resultados (mrYes, mrNo...).
function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint): Integer; overload;
function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint;
  ABotonPorDefecto: TMsgDlgBtn): Integer; overload;
// Propietario explícito para confirmaciones sobre otro modal.
function MessageDlg_fza(AOwner: TComponent; const AMensaje: string;
  ATipo: TMsgDlgType; ABotones: TMsgDlgButtons;
  AContextoAyuda: Longint): Integer; overload;
function MessageDlg_fza(AOwner: TComponent; const AMensaje: string;
  ATipo: TMsgDlgType; ABotones: TMsgDlgButtons;
  AContextoAyuda: Longint; ABotonPorDefecto: TMsgDlgBtn): Integer;
  overload;
// Como MessageDlg_fza, con otro texto en los botones: ATextos va en el
// orden de TMsgDlgBtn (el de izquierda a derecha); un texto vacío deja el
// de la VCL. Los botones se ensanchan lo que pida su texto.
function MessageDlgTextos_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; const ATextos: array of string;
  ABotonPorDefecto: TMsgDlgBtn): Integer; overload;
function MessageDlgTextos_fza(AOwner: TComponent;
  const AMensaje: string; ATipo: TMsgDlgType; ABotones: TMsgDlgButtons;
  const ATextos: array of string; ABotonPorDefecto: TMsgDlgBtn): Integer;
  overload;
// Sustituto de Application.MessageBox: indicadores MB_OK, MB_YESNO,
// MB_ICONINFORMATION, MB_DEFBUTTON2... y resultados IDOK, IDYES, IDNO...
function MessageBox_fza(const ATexto, ATitulo: string;
  AIndicadores: Longint = MB_OK): Integer;
// Sustitutos de InputQuery e InputBox con la misma fuente que los mensajes.
function InputQuery_fza(const ATitulo, APregunta: string;
  var AValor: string): Boolean; overload;
// Varias preguntas con validación al aceptar, como el InputQuery de la VCL.
function InputQuery_fza(const ATitulo: string;
  const APreguntas: array of string; var AValores: array of string;
  const AValidar: TInputCloseQueryFunc): Boolean; overload;
function InputBox_fza(const ATitulo, APregunta, AValorDefecto: string): string;

// Traducción entre los indicadores MB_* y el diálogo de la VCL. Públicas
// para poder probarlas sin mostrar ventanas.
function BotonesDeIndicadores(AIndicadores: Longint): TMsgDlgButtons;
function TipoDeIndicadores(AIndicadores: Longint): TMsgDlgType;
function BotonPorDefectoDeIndicadores(AIndicadores: Longint): TMsgDlgBtn;
function BotonPorDefectoDeBotones(ABotones: TMsgDlgButtons): TMsgDlgBtn;
function ResultadoDeMessageBox(AResultadoModal: Integer;
  AIndicadores: Longint): Integer;

implementation

uses
  System.SysUtils, System.Math, Vcl.Forms, Vcl.StdCtrls,
  Vcl.Menus, Vcl.Controls, inLibPosicionFormulario, inLibFuenteInterfaz;

type
  TOrdenBotones = array of TMsgDlgBtn;
  TAjusteCuadroEntrada = class
  private
    FDialogo: TForm;
    FAlActivarAnterior: TNotifyEvent;
    FAlRedimensionarAnterior: TNotifyEvent;
    FAjustando: Boolean;
    procedure ActivarFormulario(Sender: TObject);
    procedure AjustarAlto(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

const
  ARCHIVOS_FUENTE_INTERFAZ: array[0..3] of string = (
    'SourceSans3-Regular.ttf',
    'SourceSans3-Bold.ttf',
    'SourceSans3-Italic.ttf',
    'SourceSans3-BoldItalic.ttf');

function CargarFuentesInterfaz(const ADirectorio: string): Integer;
var
  sArchivo: string;
  sRuta: string;
begin
  Result := 0;
  for sArchivo in ARCHIVOS_FUENTE_INTERFAZ do
  begin
    sRuta := IncludeTrailingPathDelimiter(ADirectorio) + sArchivo;
    if FileExists(sRuta) then
      Inc(Result, AddFontResourceEx(PChar(sRuta), FR_PRIVATE, nil));
  end;
end;

procedure LiberarFuentesInterfaz(const ADirectorio: string);
var
  sArchivo: string;
  sRuta: string;
begin
  for sArchivo in ARCHIVOS_FUENTE_INTERFAZ do
  begin
    sRuta := IncludeTrailingPathDelimiter(ADirectorio) + sArchivo;
    if FileExists(sRuta) then
      RemoveFontResourceEx(PChar(sRuta), FR_PRIVATE, nil);
  end;
end;

// Botones de cada tipo MB_* en el orden en que Windows los presenta; el
// índice de MB_DEFBUTTONn se refiere a ese orden.
function OrdenBotonesWindows(AIndicadores: Longint): TOrdenBotones;
begin
  case AIndicadores and MB_TYPEMASK of
    MB_OKCANCEL:
      Result := [mbOK, mbCancel];
    MB_ABORTRETRYIGNORE:
      Result := [mbAbort, mbRetry, mbIgnore];
    MB_YESNOCANCEL:
      Result := [mbYes, mbNo, mbCancel];
    MB_YESNO:
      Result := [mbYes, mbNo];
    MB_RETRYCANCEL:
      Result := [mbRetry, mbCancel];
    MB_CANCELTRYCONTINUE:
      Result := [mbCancel, mbRetry, mbIgnore];
  else
    Result := [mbOK];
  end;
end;

function BotonesDeIndicadores(AIndicadores: Longint): TMsgDlgButtons;
var
  oBoton: TMsgDlgBtn;
begin
  Result := [];
  for oBoton in OrdenBotonesWindows(AIndicadores) do
    Include(Result, oBoton);
end;

function TipoDeIndicadores(AIndicadores: Longint): TMsgDlgType;
begin
  // MB_ICONHAND agrupa STOP y ERROR; MB_ICONEXCLAMATION, WARNING;
  // MB_ICONASTERISK, INFORMATION.
  case AIndicadores and MB_ICONMASK of
    MB_ICONHAND:
      Result := mtError;
    MB_ICONQUESTION:
      Result := mtConfirmation;
    MB_ICONEXCLAMATION:
      Result := mtWarning;
    MB_ICONASTERISK:
      Result := mtInformation;
  else
    Result := mtCustom;
  end;
end;

function BotonPorDefectoDeIndicadores(AIndicadores: Longint): TMsgDlgBtn;
var
  aOrden: TOrdenBotones;
  iIndice: Integer;
begin
  aOrden := OrdenBotonesWindows(AIndicadores);
  iIndice := (AIndicadores and MB_DEFMASK) shr 8;
  if (iIndice < 0) or (iIndice > High(aOrden)) then
    iIndice := 0;
  Result := aOrden[iIndice];
end;

function BotonPorDefectoDeBotones(ABotones: TMsgDlgButtons): TMsgDlgBtn;
begin
  // Mismo criterio que MessageDlg de la VCL.
  if mbOK in ABotones then
    Result := mbOK
  else if mbYes in ABotones then
    Result := mbYes
  else
    Result := mbRetry;
end;

function ResultadoDeMessageBox(AResultadoModal: Integer;
  AIndicadores: Longint): Integer;
var
  bReintentarContinuar: Boolean;
  oBotones: TMsgDlgButtons;
begin
  oBotones := BotonesDeIndicadores(AIndicadores);
  bReintentarContinuar :=
    (AIndicadores and MB_TYPEMASK) = MB_CANCELTRYCONTINUE;
  case AResultadoModal of
    mrOk:
      Result := IDOK;
    mrAbort:
      Result := IDABORT;
    mrRetry:
      if bReintentarContinuar then
        Result := IDTRYAGAIN
      else
        Result := IDRETRY;
    mrIgnore:
      if bReintentarContinuar then
        Result := IDCONTINUE
      else
        Result := IDIGNORE;
    mrYes:
      Result := IDYES;
    mrNo:
      Result := IDNO;
  else
    // mrCancel: botón Cancelar, Escape o cierre de la ventana. Sin botón
    // Cancelar equivale al botón que la VCL asocia a Escape.
    if mbCancel in oBotones then
      Result := IDCANCEL
    else if mbNo in oBotones then
      Result := IDNO
    else if mbOK in oBotones then
      Result := IDOK
    else
      Result := IDCANCEL;
  end;
end;

// CreateMessageDialog e InputQuery toman la fuente de Screen.MessageFont al
// crear el formulario y dimensionan con ella el texto y los botones.
procedure ConFuenteMensajes(const AProceso: TProc);
var
  iTamanoAnterior: Integer;
  sFuenteAnterior: string;
begin
  sFuenteAnterior := Screen.MessageFont.Name;
  iTamanoAnterior := Screen.MessageFont.Size;
  Screen.MessageFont.Name := NombreFuenteInterfaz(NOMBRE_FUENTE_MENSAJES);
  Screen.MessageFont.Size := TAMANO_FUENTE_MENSAJES;
  try
    AProceso();
  finally
    Screen.MessageFont.Name := sFuenteAnterior;
    Screen.MessageFont.Size := iTamanoAnterior;
  end;
end;

constructor TAjusteCuadroEntrada.Create;
begin
  inherited Create;
  FAlActivarAnterior := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := ActivarFormulario;
end;

destructor TAjusteCuadroEntrada.Destroy;
var
  Evento: TNotifyEvent;
begin
  Evento := ActivarFormulario;
  if (TMethod(Screen.OnActiveFormChange).Code = TMethod(Evento).Code) and
     (TMethod(Screen.OnActiveFormChange).Data = Self) then
    Screen.OnActiveFormChange := FAlActivarAnterior;
  inherited;
end;

procedure TAjusteCuadroEntrada.ActivarFormulario(Sender: TObject);
begin
  if Assigned(FAlActivarAnterior) then
    FAlActivarAnterior(Sender);
  if (FDialogo = nil) and Assigned(Screen.ActiveForm) and
     (Screen.ActiveForm.ClassName = 'TInputQueryForm') then
  begin
    FDialogo := Screen.ActiveForm;
    FAlRedimensionarAnterior := FDialogo.OnResize;
    FDialogo.OnResize := AjustarAlto;
    AjustarAlto(FDialogo);
  end;
end;

procedure TAjusteCuadroEntrada.AjustarAlto(Sender: TObject);
var
  I, AltoContenido: Integer;
begin
  if not FAjustando then
  begin
    FAjustando := True;
    try
      if Assigned(FAlRedimensionarAnterior) then
        FAlRedimensionarAnterior(Sender);
      // El area util se calcula con el marco real del skin y el DPI actual.
      AltoContenido := 0;
      for I := 0 to FDialogo.ControlCount - 1 do
        if FDialogo.Controls[I].Visible then
          AltoContenido := Max(AltoContenido,
            FDialogo.Controls[I].BoundsRect.Bottom);
      FDialogo.ClientHeight := Max(FDialogo.ClientHeight,
        AltoContenido + FDialogo.ScaleValue(8));
    finally
      FAjustando := False;
    end;
  end;
end;

procedure ConCuadroEntradaCompleto(const AProceso: TProc);
var
  Ajuste: TAjusteCuadroEntrada;
begin
  Ajuste := TAjusteCuadroEntrada.Create;
  try
    ConFuenteMensajes(AProceso);
  finally
    FreeAndNil(Ajuste);
  end;
end;

function CrearDialogo(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; ABotonPorDefecto: TMsgDlgBtn;
  AContextoAyuda: Longint): TForm;
var
  oDialogo: TForm;
begin
  oDialogo := nil;
  ConFuenteMensajes(
    procedure
    begin
      oDialogo := CreateMessageDialog(
        AMensaje, ATipo, ABotones, ABotonPorDefecto);
    end);
  Result := oDialogo;
  Result.HelpContext := AContextoAyuda;
  Result.Position := poScreenCenter;
end;

function MostrarDialogo(ADialogo: TForm): Integer;
begin
  try
    Result := ADialogo.ShowModal;
  finally
    ADialogo.Free;
  end;
end;

procedure ShowMessage_fza(const AMensaje: string);
begin
  MostrarDialogo(CrearDialogo(AMensaje, mtCustom, [mbOK], mbOK, 0));
end;

procedure ShowMessage_fza(AOwner: TComponent; const AMensaje: string);
var
  Dialogo: TForm;
begin
  Dialogo := CrearDialogo(AMensaje, mtCustom, [mbOK], mbOK, 0);
  AsociarVentanaPropietaria(Dialogo, AOwner);
  AjustarFormularioAreaTrabajo(Dialogo, AOwner);
  MostrarDialogo(Dialogo);
end;

procedure ShowMessageFmt_fza(const AFormato: string;
  const AArgumentos: array of const);
begin
  ShowMessage_fza(Format(AFormato, AArgumentos));
end;

function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint): Integer;
begin
  Result := MessageDlg_fza(AMensaje, ATipo, ABotones, AContextoAyuda,
    BotonPorDefectoDeBotones(ABotones));
end;

function MessageDlg_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; AContextoAyuda: Longint;
  ABotonPorDefecto: TMsgDlgBtn): Integer;
begin
  Result := MostrarDialogo(CrearDialogo(
    AMensaje, ATipo, ABotones, ABotonPorDefecto, AContextoAyuda));
end;

function MessageDlg_fza(AOwner: TComponent; const AMensaje: string;
  ATipo: TMsgDlgType; ABotones: TMsgDlgButtons;
  AContextoAyuda: Longint): Integer;
begin
  Result := MessageDlg_fza(AOwner, AMensaje, ATipo, ABotones,
    AContextoAyuda, BotonPorDefectoDeBotones(ABotones));
end;

function MessageDlg_fza(AOwner: TComponent; const AMensaje: string;
  ATipo: TMsgDlgType; ABotones: TMsgDlgButtons;
  AContextoAyuda: Longint; ABotonPorDefecto: TMsgDlgBtn): Integer;
var
  oDialogo: TForm;
begin
  oDialogo := CrearDialogo(
    AMensaje, ATipo, ABotones, ABotonPorDefecto, AContextoAyuda);
  AsociarVentanaPropietaria(oDialogo, AOwner);
  Result := MostrarDialogo(oDialogo);
end;

// CreateMessageDialog crea los botones en el orden de TMsgDlgBtn y los
// coloca de izquierda a derecha, todos del mismo ancho y centrados.
procedure PonerTextosBotones(ADialogo: TForm;
  const ATextos: array of string);
var
  Botones: TArray<TButton>;
  i, iAncho, iSeparacion, iTotal, iX: Integer;
begin
  Botones := nil;
  for i := 0 to ADialogo.ComponentCount - 1 do
    if ADialogo.Components[i] is TButton then
      Botones := Botones + [TButton(ADialogo.Components[i])];
  if Length(Botones) > 0 then
  begin
    ADialogo.Canvas.Font := ADialogo.Font;
    iAncho := Botones[0].Width;
    for i := 0 to High(Botones) do
    begin
      if (i <= High(ATextos)) and (ATextos[i] <> '') then
        Botones[i].Caption := ATextos[i];
      iAncho := Max(iAncho,
        ADialogo.Canvas.TextWidth(StripHotkey(Botones[i].Caption)) +
        ADialogo.ScaleValue(24));
    end;
    iSeparacion := ADialogo.ScaleValue(4);
    if Length(Botones) > 1 then
      iSeparacion := Botones[1].Left - Botones[0].Left - Botones[0].Width;
    iTotal := Length(Botones) * iAncho + High(Botones) * iSeparacion;
    if iTotal + ADialogo.ScaleValue(16) > ADialogo.ClientWidth then
      ADialogo.ClientWidth := iTotal + ADialogo.ScaleValue(16);
    iX := (ADialogo.ClientWidth - iTotal) div 2;
    for i := 0 to High(Botones) do
    begin
      Botones[i].SetBounds(iX, Botones[i].Top, iAncho, Botones[i].Height);
      Inc(iX, iAncho + iSeparacion);
    end;
  end;
end;

function MessageDlgTextos_fza(const AMensaje: string; ATipo: TMsgDlgType;
  ABotones: TMsgDlgButtons; const ATextos: array of string;
  ABotonPorDefecto: TMsgDlgBtn): Integer;
begin
  Result := MessageDlgTextos_fza(nil, AMensaje, ATipo, ABotones,
    ATextos, ABotonPorDefecto);
end;

function MessageDlgTextos_fza(AOwner: TComponent;
  const AMensaje: string; ATipo: TMsgDlgType; ABotones: TMsgDlgButtons;
  const ATextos: array of string; ABotonPorDefecto: TMsgDlgBtn): Integer;
var
  oDialogo: TForm;
begin
  oDialogo := CrearDialogo(AMensaje, ATipo, ABotones, ABotonPorDefecto, 0);
  try
    AsociarVentanaPropietaria(oDialogo, AOwner);
    PonerTextosBotones(oDialogo, ATextos);
  except
    oDialogo.Free;
    raise;
  end;
  Result := MostrarDialogo(oDialogo);
end;

function MessageBox_fza(const ATexto, ATitulo: string;
  AIndicadores: Longint): Integer;
var
  oDialogo: TForm;
begin
  oDialogo := CrearDialogo(ATexto, TipoDeIndicadores(AIndicadores),
    BotonesDeIndicadores(AIndicadores),
    BotonPorDefectoDeIndicadores(AIndicadores), 0);
  if ATitulo <> '' then
    oDialogo.Caption := ATitulo;
  if (AIndicadores and (MB_TOPMOST or MB_SYSTEMMODAL)) <> 0 then
    oDialogo.FormStyle := fsStayOnTop;
  // Mismo sonido que el MessageBox de Windows según el icono.
  if (AIndicadores and MB_ICONMASK) <> 0 then
    MessageBeep(AIndicadores and MB_ICONMASK);
  Result := ResultadoDeMessageBox(MostrarDialogo(oDialogo), AIndicadores);
end;

function InputQuery_fza(const ATitulo, APregunta: string;
  var AValor: string): Boolean;
var
  bAceptado: Boolean;
  sValor: string;
begin
  // InputQuery lee Screen.MessageFont durante toda su ejecución (crea y
  // muestra el formulario dentro), así que se envuelve la llamada entera.
  sValor := AValor;
  bAceptado := False;
  ConCuadroEntradaCompleto(
    procedure
    begin
      bAceptado := InputQuery(ATitulo, APregunta, sValor);
    end);
  if bAceptado then
    AValor := sValor;
  Result := bAceptado;
end;

function InputQuery_fza(const ATitulo: string;
  const APreguntas: array of string; var AValores: array of string;
  const AValidar: TInputCloseQueryFunc): Boolean;
var
  bAceptado: Boolean;
  sPreguntas, sValores: TArray<string>;
  I: Integer;
begin
  // Los parámetros array abiertos no pueden capturarse en el método anónimo:
  // se copian a arrays dinámicos y se devuelven al terminar.
  SetLength(sPreguntas, Length(APreguntas));
  for I := 0 to High(APreguntas) do
    sPreguntas[I] := APreguntas[I];
  SetLength(sValores, Length(AValores));
  for I := 0 to High(AValores) do
    sValores[I] := AValores[I];
  bAceptado := False;
  ConCuadroEntradaCompleto(
    procedure
    begin
      bAceptado := InputQuery(ATitulo, sPreguntas, sValores, AValidar);
    end);
  if bAceptado then
    for I := 0 to High(AValores) do
      AValores[I] := sValores[I];
  Result := bAceptado;
end;

function InputBox_fza(const ATitulo, APregunta, AValorDefecto: string): string;
begin
  Result := AValorDefecto;
  InputQuery_fza(ATitulo, APregunta, Result);
end;

end.
