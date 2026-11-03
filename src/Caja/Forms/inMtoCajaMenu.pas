{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaMenu                                                 }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Menu principal del modulo de caja (TPV).                                  }
{    Acceso a ventas, arqueo, gastos, entrada de cambio y calendario.          }
{******************************************************************************}
unit inMtoCajaMenu;

interface
uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  inMtoFrmBase,
  System.Classes, Vcl.Graphics, Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, JvExControls, JvAnimatedImage,
  JvGIFCtrl, cxLabel, Vcl.ExtCtrls, math, cxStyles,
  Data.DB, DBAccess, Uni, Vcl.Menus,
  Vcl.StdCtrls, cxButtons, inLibCajaVentanasIntf, inMtoTraspasoOpe,
  UniDataTraspaso,
  system.IOUtils, system.IniFiles,
  inMtoModalCajDef, JvTFManager, JvTFGlance, JvTFMonths, Vcl.ComCtrls,
  JvExComCtrls, JvMonthCalendar, cxCalendar, CommCtrl,
  inLibVentasCalendario, System.Actions, Vcl.ActnList, dxGDIPlusClasses,
  cxImage, inLibPermisosIntf, inLibCajaPantallaInyeccion,
  inLibCajaMenuTarjetaVcl, inLibCajaMenuMaquetaVcl,
  inLibIndicadoresColasVcl;

const
  WM_REACTIVAR_OPERACION_CAJA = WM_APP + 107;

type
  TfrmMtoMenuCaja = class(TfrmBase, IReceptorFechaCaja)
    lblF5: TcxLabel;
    lblF10: TcxLabel;
    lblBuscarModificar: TcxLabel;
    lblVentas: TcxLabel;
    clkHora: TcxClock;
    tmrReloj: TTimer;
    lblF6: TcxLabel;
    lblEntradaCambio: TcxLabel;
    lblF7: TcxLabel;
    lblGastosCaja: TcxLabel;
    lblArqueo: TcxLabel;
    lblF11: TcxLabel;
    lblSalir: TcxLabel;
    lblESC: TcxLabel;
    lblFecha: TcxLabel;
    lblF3: TcxLabel;
    lblTraspasos: TcxLabel;
    lblEmpresa: TcxLabel;
    calMes: TCalendarioMenuCaja;
    alCajaMenu: TActionList;
    actSalirMenu: TAction;
    cxImage1: TcxImage;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lblEntradaCambioClick(Sender: TObject);
    procedure lblGastosCajaClick(Sender: TObject);
    procedure lblArqueoClick(Sender: TObject);
    procedure lblTraspasosClick(Sender: TObject);
    procedure JvMonthCalendar1GetMonthBoldInfo(Sender: TObject;
      Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
    procedure JvMonthCalendar1DblClick(Sender: TObject);
    procedure JvMonthCalendar1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure lblESCClick(Sender: TObject);
    procedure cxButton1Click(Sender: TObject);
    procedure lblVentasClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lblEmpresaDblClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure JvMonthCalendar1Click(Sender: TObject);
    procedure lblBuscarModificarClick(Sender: TObject);
    procedure lblF10Click(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure WMActivate(var Mensaje: TWMActivate); message WM_ACTIVATE;
    procedure WMReactivarOperacionCaja(var Mensaje: TMessage);
      message WM_REACTIVAR_OPERACION_CAJA;
    procedure WMRestaurarMenuCaja(var Mensaje: TMessage);
      message WM_RESTAURAR_MENU_CAJA;
    procedure WMSize(var Mensaje: TWMSize); message WM_SIZE;
    procedure WMSysCommand(var Mensaje: TWMSysCommand);
      message WM_SYSCOMMAND;
  private
    FCerrando: Boolean;
    FIndicadoresColas: TIndicadoresColasVcl;
    FVentasCal: TVentasCalendarioCache;
    FDependenciasInyeccion: TDependenciasMenuCaja;
    procedure AbrirBuscarModificar;
  private
    FUltimoTickReloj: TDateTime;
    // Tarjetas del menú (se crean en ejecución; los textos salen de las
    // etiquetas ocultas del DFM para conservar su traducción) y navegación
    // por teclado.
    FTarjetas: TArray<TTarjetaMenuCaja>;
    FSelectedIndex: Integer;
    procedure CrearTarjetas;
    procedure MaquetarPantalla;
    procedure TarjetaSeleccionar(Sender: TObject);
    procedure SetSelectedIndex(NewIndex: Integer);
    procedure ExecuteSelectedItem;
    procedure AbrirSelectorCaja;
    procedure RecargarCalendario;
    procedure clkHoraDblClick(Sender: TObject);
  public
    FFechaCaja: TDateTime;
    FEmpresa, FAlmacen, FCaja: string;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion;
      const ADependencias: TDependenciasMenuCaja); reintroduce; overload;
    procedure ActualizarFechaCaja(AFechaCaja: TDateTime);
    function FechaOperacionCaja(const AEmpresa, AAlmacen,
      ACaja: string): TDateTime;
    property FechaCaja: TDateTime read FFechaCaja;
  end;

function BuscarMenuCaja: TfrmMtoMenuCaja;
function MenuCajaAbierto: Boolean;
procedure MostrarMenuCaja(
  const APermisos: IPermisosAplicacion); overload;
procedure MostrarMenuCaja(
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasMenuCaja); overload;

implementation

uses
  inLibMensajesVcl, inLibCajaEstiloVcl,
  DateUtils,
  inMtoModalArqueo, inMtoModalEntradaCambio, inMtoModalGastoCaja,
  inLibMsgCaja, inLibTraducciones, inLibVentanaBarraTareas;

const
  // Identificador de aplicación propio: botón separado en la barra de
  // tareas, con el icono del menú de caja, aunque la barra combine botones.
  GRUPO_BARRA_TAREAS_CAJA = 'ViraCash.Caja';
  ICONO_MENU_CAJA = 'MNUMENUCAJA';

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

function BuscarMenuCaja: TfrmMtoMenuCaja;
var
  Componente: TComponent;
begin
  Componente := Application.FindComponent('frmMtoMenuCaja');
  if (Componente is TfrmMtoMenuCaja) and
     not (csDestroying in Componente.ComponentState) then
    Result := TfrmMtoMenuCaja(Componente)
  else
    Result := nil;
end;

function MenuCajaAbierto: Boolean;
begin
  Result := BuscarMenuCaja <> nil;
end;

procedure MostrarMenuCaja(
  const APermisos: IPermisosAplicacion);
begin
  ValidarDependenciaCaja(nil, 'contexto del menú de Caja');
end;

procedure MostrarMenuCaja(
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasMenuCaja);
var
  Formulario: TfrmMtoMenuCaja;
begin
  if BuscarOperacionCajaVisible <> nil then
    ReactivarOperacionCajaVisible
  else
  begin
    Formulario := BuscarMenuCaja;
    if Formulario = nil then
    begin
      Formulario := TfrmMtoMenuCaja.Create(
        Application,
        APermisos,
        ADependencias);
      Formulario.Show;
    end
    else
    begin
      if Formulario.WindowState = wsMinimized then
        Formulario.WindowState := wsNormal;
      Formulario.BringToFront;
    end;
  end;
end;

constructor TfrmMtoMenuCaja.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasMenuCaja);
begin
  ADependencias.Validar;
  FDependenciasInyeccion := ADependencias;
  inherited Create(AOwner, APermisos);
  if Assigned(FDependenciasInyeccion.ConsultarEstadosColas) then
  begin
    ClientHeight := ClientHeight + MulDiv(24, CurrentPPI, 96);
    FIndicadoresColas := TIndicadoresColasVcl.CrearBarra(
      Self, FDependenciasInyeccion.ConsultarEstadosColas);
  end;
end;

procedure TfrmMtoMenuCaja.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle   := Params.ExStyle or WS_EX_APPWINDOW;
  Params.WndParent := 0;
end;

procedure TfrmMtoMenuCaja.CreateWnd;
begin
  inherited;
  AsignarGrupoBarraTareas(Handle, GRUPO_BARRA_TAREAS_CAJA);
  AsignarIconoVentanaDesdePng(Handle, ICONO_MENU_CAJA);
end;

procedure TfrmMtoMenuCaja.DestroyWnd;
begin
  // La propiedad debe quitarse antes de destruir la ventana.
  QuitarGrupoBarraTareas(Handle);
  LiberarIconoVentana(Handle);
  inherited;
end;

procedure TfrmMtoMenuCaja.WMActivate(var Mensaje: TWMActivate);
begin
  inherited;
  // La restauracion de Windows termina despues de WM_ACTIVATE. Se difiere
  // la reposicion para que el menu no tape la operacion de caja visible.
  if Mensaje.Active <> WA_INACTIVE then
    PostMessage(Handle, WM_REACTIVAR_OPERACION_CAJA, 0, 0);
end;

procedure TfrmMtoMenuCaja.WMReactivarOperacionCaja(var Mensaje: TMessage);
begin
  // Al minimizar la ventana principal, TApplication.Minimize oculta las
  // ventanas que dependen del menú (ventas, traspasos, arqueo...) y sólo las
  // devuelve al restaurar la principal. El menú tiene botón propio en la
  // barra de tareas: al traerlo desde ahí se vuelven a mostrar.
  if not IsIconic(Handle) then
    ShowOwnedPopups(Handle, True);
  ReactivarOperacionCajaVisible;
  Mensaje.Result := 0;
end;

procedure TfrmMtoMenuCaja.WMRestaurarMenuCaja(var Mensaje: TMessage);
begin
  // Ventas ya se ha ocultado cuando se procesa este mensaje.
  if not FCerrando and not Application.Terminated and
     not (csDestroying in ComponentState) and
     Assigned(Application.MainForm) and
     not (csDestroying in Application.MainForm.ComponentState) then
  begin
    if WindowState = wsMinimized then
      WindowState := wsNormal;
    Show;
    BringToFront;
    SetForegroundWindow(Handle);
    if CanFocus then
      SetFocus;
  end;
  Mensaje.Result := 0;
end;

procedure TfrmMtoMenuCaja.WMSize(var Mensaje: TWMSize);
begin
  inherited;
  if Mensaje.SizeType <> SIZE_MINIMIZED then
    PostMessage(Handle, WM_REACTIVAR_OPERACION_CAJA, 0, 0);
end;

procedure TfrmMtoMenuCaja.WMSysCommand(var Mensaje: TWMSysCommand);
begin
  inherited;
  if Mensaje.CmdType and $FFF0 = SC_RESTORE then
    PostMessage(Handle, WM_REACTIVAR_OPERACION_CAJA, 0, 0);
end;

procedure TfrmMtoMenuCaja.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FCerrando := True;
  Action := caFree;
  if Assigned(Application.MainForm) and
     (Application.MainForm.WindowState = wsMinimized) then
    Application.MainForm.WindowState := wsMaximized;
end;

procedure TfrmMtoMenuCaja.FormCloseQuery(Sender: TObject;
                                         var CanClose: Boolean);
begin
  CanClose := PuedenCerrarOperacionesCaja;
end;

procedure TfrmMtoMenuCaja.FormCreate(Sender: TObject);
var
  bContinuar: Boolean;
begin
  inherited;
  FDependenciasInyeccion.Validar;
  bContinuar := True;
  Self.Position := poScreenCenter;
  // forzar mes actual (evita fecha cacheada en DFM)
  calMes.ConfigurarIdioma(Traducciones);
  calMes.Date := Date;

  Application.ShowHint     := True;
  Application.HintPause    := 500;
  Application.HintHidePause := 5000;
  calMes.ShowHint       := True;
  calMes.ParentShowHint := False;
  lblFecha.Caption := FormatearFechaHoraIdioma(
    'dddd d mmmm yyyy',
    Now,
    Traducciones);
  // Permiso: si no puede cambiar fecha, deshabilitar calendario
  if (not Assigned(Permisos)) or
     (not Permisos.TienePermiso(
       PERMISO_CAJA_CAMBIAR_FECHA,
       paPermitir)) then
    calMes.Enabled := False;
  // Crear el caché ANTES de cualquier cosa que pueda disparar eventos del
  // calendario
  FVentasCal := TVentasCalendarioCache.Create(
    ConexionPrincipal,
    FDependenciasInyeccion.VentasCalendario);
  // La maqueta crea el handle del calendario, que pide enseguida los días en
  // negrita: tiene que ir después de crear el caché.
  CrearTarjetas;
  AdaptarLogotipoCaja(cxImage1);
  MaquetarPantalla;

  if ParametrosCaja.GetBool('vgerShowCajaSelection', True) then
    AbrirSelectorCaja
  else
  begin
    FEmpresa := UbicacionSesion.Empresa;
    FAlmacen := UbicacionSesion.Almacen;
    FCaja    := UbicacionSesion.Caja;
    if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
    begin
      ShowMessage_fza(SErrorAsignarUbicacionCaja);
      bContinuar := False;
    end
    else
    begin
      lblEmpresa.Caption := Format(SCaptionEmpresaAlmacenCaja,
                                   [FEmpresa, FAlmacen, FCaja]);
      FVentasCal.Reconfigurar(FEmpresa, FAlmacen, FCaja);
    end;
  end;

  if bContinuar then
  begin
    calMes.Invalidate;
    ActualizarFechaCaja(Now);
    clkHora.OnDblClick := clkHoraDblClick;
    FSelectedIndex := -1;
    SetSelectedIndex(0);
  end;
end;

procedure TfrmMtoMenuCaja.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FIndicadoresColas);
  FreeAndNil(FVentasCal);
  FDependenciasInyeccion := Default(TDependenciasMenuCaja);
end;

procedure TfrmMtoMenuCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_F3:     lblTraspasosClick(Sender);
    VK_F5:     lblVentasClick(Sender);
    VK_F6:     lblEntradaCambioClick(Sender);
    VK_F7:     lblGastosCajaClick(Sender);
    VK_ESCAPE: lblESCClick(Sender);
    VK_F10:    AbrirBuscarModificar;
    VK_F11:    lblArqueoClick(Sender);
  end;
end;

procedure TfrmMtoMenuCaja.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
var
  Tecla: Word;
begin
  // Los atajos funcionan incluso sin un control hijo con el foco.
  // Handled evita que la misma tecla vuelva a ejecutar FormKeyDown.
  case Msg.CharCode of
    VK_F3, VK_F5, VK_F6, VK_F7, VK_F10, VK_F11, VK_ESCAPE:
      begin
        Handled := True;
        Tecla := Msg.CharCode;
        FormKeyDown(Self, Tecla, []);
      end;
    VK_UP:
      begin
        SetSelectedIndex(FSelectedIndex - 1);
        Handled := True;
      end;
    VK_DOWN:
      begin
        SetSelectedIndex(FSelectedIndex + 1);
        Handled := True;
      end;
    VK_RETURN:
      begin
        ExecuteSelectedItem;
        Handled := True;
      end;
  end;
end;

function TfrmMtoMenuCaja.FechaOperacionCaja(
  const AEmpresa, AAlmacen, ACaja: string): TDateTime;
begin
  Result := 0;
  if SameText(FEmpresa, AEmpresa) and SameText(FAlmacen, AAlmacen) and
     SameText(FCaja, ACaja) then
    Result := FFechaCaja;
end;

procedure TfrmMtoMenuCaja.ActualizarFechaCaja(AFechaCaja: TDateTime);
begin
  if AFechaCaja = 0 then
    AFechaCaja := Now;
  FFechaCaja := AFechaCaja;
  FUltimoTickReloj := Now;
  calMes.Date := DateOf(FFechaCaja);
  lblFecha.Caption := FormatearFechaHoraIdioma(
    'dddd d mmmm yyyy',
    FFechaCaja,
    Traducciones);
  clkHora.Time := FFechaCaja;
end;

procedure TfrmMtoMenuCaja.Timer1Timer(Sender: TObject);
var
  dtAhora: TDateTime;
begin
  dtAhora := Now;
  if FUltimoTickReloj = 0 then
    FUltimoTickReloj := dtAhora;
  if FFechaCaja = 0 then
    FFechaCaja := dtAhora;
  FFechaCaja := FFechaCaja + (dtAhora - FUltimoTickReloj);
  FUltimoTickReloj := dtAhora;
  clkHora.Time := FFechaCaja;
  lblFecha.Caption := FormatearFechaHoraIdioma(
    'dddd d mmmm yyyy',
    FFechaCaja,
    Traducciones);
end;

procedure TfrmMtoMenuCaja.clkHoraDblClick(Sender: TObject);
var
  sHora: string;
  dtHora: TDateTime;
  dtFechaBase: TDateTime;
begin
  dtFechaBase := FFechaCaja;
  if dtFechaBase = 0 then
    dtFechaBase := Now;
  sHora := FormatDateTime('hh:nn', dtFechaBase);
  if InputQuery_fza(STituloHoraCaja, SSolicitudHoraCaja, sHora) then
  begin
    if TryStrToTime(sHora, dtHora) then
      ActualizarFechaCaja(DateOf(dtFechaBase) + Frac(dtHora))
    else
      ShowMessage_fza(SErrorHoraCajaNoValida);
  end
  else
    ActualizarFechaCaja(Now);
end;

procedure TfrmMtoMenuCaja.AbrirBuscarModificar;
var
  oAnfitrion: IAnfitrionCajaVentanas;
  oConsulta: IConsultaOperacionesCaja;
  oFormulario: TCustomForm;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
  begin
    ShowMessage_fza(SErrorUbicacionCajaBuscarOperacionesNoAsignada);
  end
  else
  begin
    oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
    oConsulta :=
      oAnfitrion.CrearConsultaOperacionesCaja(Application, Permisos);
    oFormulario := oConsulta.FormularioConsultaCaja;
    try
      oFormulario.PopupParent := Self;
      oConsulta.PrepararValores(FEmpresa, FAlmacen, FCaja, FFechaCaja);
      oFormulario.Show;
    except
      FreeAndNil(oFormulario);
      raise;
    end;
  end;
end;

procedure TfrmMtoMenuCaja.AbrirSelectorCaja;
var
  frm: TfrmMtoModalCajDef;
begin
  frm := TfrmMtoModalCajDef.Create(
    Self,
    FDependenciasInyeccion.CajasDefecto);
  try
    // Cierra el cronometro SQL antes de entrar en el selector modal.
    CerrarMonitorSQLPendiente;
    frm.sEmpresa := FEmpresa;
    frm.sAlmacen := FAlmacen;
    frm.sCaja := FCaja;
    frm.ShowModal;
    if (frm.sFicha = 'S') then
    begin
      FEmpresa := frm.EmpresaSeleccionada;
      FAlmacen := frm.AlmacenSeleccionado;
      FCaja    := frm.CajaSeleccionada;
      lblEmpresa.Caption := Format(SCaptionEmpresaAlmacenCaja,
                                   [FEmpresa, FAlmacen, FCaja]);
      RecargarCalendario;
    end
    else
      PostMessage(Self.Handle, WM_CLOSE, 0, 0);
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoMenuCaja.Action1Execute(Sender: TObject);
begin
  inherited;
  lblESCClick(Sender);
end;

procedure TfrmMtoMenuCaja.RecargarCalendario;
begin
  // Si el contexto cambió, esto vacía el caché internamente
  FVentasCal.Reconfigurar(FEmpresa, FAlmacen, FCaja);
  calMes.Invalidate;
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1GetMonthBoldInfo(Sender: TObject;
  Month, Year: Cardinal; var MonthBoldInfo: Cardinal);
begin
  if Assigned(FVentasCal) then
    MonthBoldInfo := FVentasCal.MaskBoldDelMes(Year, Month)
  else
    MonthBoldInfo := 0;
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1Click(Sender: TObject);
begin
  ActualizarFechaCaja(DateOf(calMes.Date) + Frac(FFechaCaja));
  // Si quieres mostrar el resumen del día clickado, descomenta:
  // VentaDia := FVentasCal.GetVentasDia(FFechaCaja);
  // if Assigned(VentaDia) then
  //   ShowMessage_fza(VentaDia.GetHintText);
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1DblClick(Sender: TObject);
begin
  ActualizarFechaCaja(DateOf(calMes.Date) + Frac(FFechaCaja));
end;

procedure TfrmMtoMenuCaja.JvMonthCalendar1KeyDown(Sender: TObject;
                                                  var Key: Word;
  Shift: TShiftState);
begin
  // El calendario reclama las flechas y Enter al nivel de Win32, así que las
  // capturamos aquí para que la navegación del menú funcione aun con el foco
  // sobre él. Key := 0 evita además que el calendario las procese.
  case Key of
    VK_UP:
      begin
        SetSelectedIndex(FSelectedIndex - 1);
        Key := 0;
      end;
    VK_DOWN:
      begin
        SetSelectedIndex(FSelectedIndex + 1);
        Key := 0;
      end;
    VK_RETURN:
      begin
        ExecuteSelectedItem;
        Key := 0;
      end;
  end;
end;

procedure TfrmMtoMenuCaja.cxButton1Click(Sender: TObject);
begin
  calMes.Date := Now;
end;

// =============================================================================
// Tarjetas del menú y navegación: ratón y teclado comparten la selección;
// Enter o clic ejecutan la acción de la etiqueta asociada.
// =============================================================================

procedure TfrmMtoMenuCaja.CrearTarjetas;

  procedure Agregar(AIndice: Integer; ATecla, ATitulo: TcxLabel;
    const AIcono: string);
  var
    oTarjeta: TTarjetaMenuCaja;
  begin
    oTarjeta := TTarjetaMenuCaja.Create(Self);
    oTarjeta.Parent := Self;
    oTarjeta.Tag := AIndice;
    oTarjeta.Tecla := ATecla.Caption;
    oTarjeta.EtiquetaTitulo := ATitulo;
    oTarjeta.Hint := ATitulo.Hint;
    // El tamaño del icono depende del estilo: se fija antes de cargarlo.
    if AIndice < 3 then
      oTarjeta.Estilo := etcGrande
    else
      oTarjeta.Estilo := etcCompacta;
    oTarjeta.CargarIcono(AIcono);
    oTarjeta.OnClick := ATitulo.OnClick;
    oTarjeta.OnSeleccionar := TarjetaSeleccionar;
    FTarjetas[AIndice] := oTarjeta;
  end;

begin
  SetLength(FTarjetas, 7);
  // Orden visual y de navegación: fila grande, fila compacta y salir.
  Agregar(0, lblF5, lblVentas, 'MNUMENUCAJA');
  Agregar(1, lblF10, lblBuscarModificar, 'MNUCAJAOPERACIONESHIST');
  Agregar(2, lblF11, lblArqueo, 'MNUCAJAARQUEOSHIST');
  Agregar(3, lblF6, lblEntradaCambio, 'MNUCAJAPAGOSHIST');
  Agregar(4, lblF7, lblGastosCaja, 'FORMASDEPAGOCAJA1');
  Agregar(5, lblF3, lblTraspasos, 'MNUCAJASOLICITUDESTRASPASOHIST');
  Agregar(6, lblESC, lblSalir, 'SALIR1');
end;

procedure TfrmMtoMenuCaja.MaquetarPantalla;
var
  rControles: TControlesMenuCaja;
begin
  // El calendario nativo se autoajusta; la maqueta le da su tamaño mínimo.
  // DevExpress conserva el tamaño indicado por la maqueta.
  rControles.Logo := cxImage1;
  rControles.Calendario := calMes;
  rControles.Reloj := clkHora;
  rControles.Fecha := lblFecha;
  rControles.Empresa := lblEmpresa;
  rControles.Tarjetas := FTarjetas;
  MaquetarMenuCaja(Self, rControles);
end;

procedure TfrmMtoMenuCaja.TarjetaSeleccionar(Sender: TObject);
begin
  SetSelectedIndex(TTarjetaMenuCaja(Sender).Tag);
end;

procedure TfrmMtoMenuCaja.SetSelectedIndex(NewIndex: Integer);
var
  Cnt, I: Integer;
begin
  Cnt := Length(FTarjetas);
  if Cnt > 0 then
  begin
    NewIndex := ((NewIndex mod Cnt) + Cnt) mod Cnt;
    if NewIndex <> FSelectedIndex then
    begin
      FSelectedIndex := NewIndex;
      for I := 0 to Cnt - 1 do
        FTarjetas[I].Seleccionada := I = FSelectedIndex;
    end;
  end;
end;

procedure TfrmMtoMenuCaja.ExecuteSelectedItem;
begin
  if (FSelectedIndex >= 0) and (FSelectedIndex < Length(FTarjetas)) and
     Assigned(FTarjetas[FSelectedIndex].OnClick) then
    FTarjetas[FSelectedIndex].OnClick(FTarjetas[FSelectedIndex]);
end;

// F5 - Ventas
procedure TfrmMtoMenuCaja.lblVentasClick(Sender: TObject);
var
  oAnfitrion: IAnfitrionCajaVentanas;
  oOperacion: IOperacionCaja;
  oFormulario: TCustomForm;
begin
  oOperacion := BuscarOperacionCajaPendiente(Self, nil,
    FEmpresa, FAlmacen, FCaja);
  if oOperacion <> nil then
  begin
    oFormulario := oOperacion.FormularioCaja;
    oFormulario.WindowState := wsNormal;
    oFormulario.Show;
    oFormulario.BringToFront;
  end
  else
  begin
    oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
    oOperacion := oAnfitrion.CrearOperacionCaja(Application, Permisos);
    oFormulario := oOperacion.FormularioCaja;
    try
      oFormulario.PopupParent := Self;
      oFormulario.Tag := 1;
      oFormulario.Caption := Format(STituloOperacionNCajaReal,
                                    [1, Self.FCaja]);
      oOperacion.PrepararValores(
        Self.FEmpresa, Self.FAlmacen, Self.FCaja, Self.FFechaCaja);
      oFormulario.Show;
    except
      FreeAndNil(oFormulario);
      raise;
    end;
  end;
end;

// F10 - Buscar/Modificar
procedure TfrmMtoMenuCaja.lblBuscarModificarClick(Sender: TObject);
begin
  inherited;
  AbrirBuscarModificar;
end;

procedure TfrmMtoMenuCaja.lblF10Click(Sender: TObject);
begin
  inherited;
  AbrirBuscarModificar;
end;

// F6 - Entrada de Cambio
procedure TfrmMtoMenuCaja.lblEmpresaDblClick(Sender: TObject);
begin
  if ParametrosCaja.GetBool('vgerShowCajaSelection', True) then
    AbrirSelectorCaja;
end;

procedure TfrmMtoMenuCaja.lblEntradaCambioClick(Sender: TObject);
begin
  TfrmModalEntradaCambio.Ejecutar(
    Self,
    ConexionPrincipal,
    FDependenciasInyeccion.EntradaCambio,
    FEmpresa,
    FAlmacen,
    FCaja,
    FFechaCaja);
end;

// F7 - Gastos por Caja
procedure TfrmMtoMenuCaja.lblGastosCajaClick(Sender: TObject);
begin
  TfrmModalGastoCaja.Ejecutar(
    Self,
    ConexionPrincipal,
    FDependenciasInyeccion.Gasto,
    FEmpresa,
    FAlmacen,
    FCaja,
    FFechaCaja);
end;

// F11 - Arqueo
procedure TfrmMtoMenuCaja.lblArqueoClick(Sender: TObject);
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
  begin
    ShowMessage_fza(SErrorUbicacionCajaArqueoNoAsignada);
  end
  else
  begin
    TfrmModalArqueo.Ejecutar(Self,
      ConexionPrincipal,
      FDependenciasInyeccion.Arqueo,
      FEmpresa,
      FAlmacen,
      FCaja,
      DateOf(FFechaCaja),
      DateOf(FFechaCaja));
  end;
end;

// F3 - Traspasos
procedure TfrmMtoMenuCaja.lblTraspasosClick(Sender: TObject);
var
  frmTraspaso: TfrmMtoOpeTraspaso;
begin
  if (FEmpresa = '') or (FAlmacen = '') or (FCaja = '') then
    ShowMessage_fza(SErrorUbicacionCajaTraspasoNoAsignada)
  else
  begin
    frmTraspaso := TfrmMtoOpeTraspaso.Create(
      Application,
      Permisos,
      FDependenciasInyeccion.Traspaso);
    try
      frmTraspaso.PopupParent := Self;
      frmTraspaso.Caption := Format(STituloTraspasosAlmacenCaja,
                                    [Self.FAlmacen, Self.FCaja]);
      frmTraspaso.PrepararValores(mtTraspaso, Self.FEmpresa, Self.FAlmacen,
                                  Self.FCaja, Self.FFechaCaja);
      frmTraspaso.Show;
    except
      FreeAndNil(frmTraspaso);
    end;
  end;
end;

// ESC - Salir
procedure TfrmMtoMenuCaja.lblESCClick(Sender: TObject);
begin
  Close;
end;

initialization
  RegistrarPantalla(TfrmMtoMenuCaja);
  ForceReferenceToClass(TfrmMtoMenuCaja);
end.
