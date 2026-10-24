{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormManager                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestor de formularios embebidos en un cxPageControl.                      }
{    Crea, selecciona y cierra ventanas hijas dentro del marco principal.      }
{******************************************************************************}
unit inLibFormManager;

interface

uses
  System.Generics.Collections, Vcl.Forms, Vcl.Controls, cxPC, System.Classes,
  winapi.Windows, winapi.Messages, System.SysUtils, System.Types,
  Vcl.Menus,
  inLibVentanaEmbebidaIntf, inLibArrastrePestanasVcl;

type
  TRegistroVentanaGestionada = class
  public
    Pestana: TcxTabSheet;
    Ventana: IVentanaSeparable;
    RecursoIcono: string;
    IndicePestana: Integer;
    Separada: Boolean;
  end;

  TEmbeddedFormManager = class(TComponent)
  private
    FPageControl: TcxPageControl;
    FForms: TList<TForm>;
    FExternas: TList<TForm>;
    // Identidad estable de cada ventana (CALL[#instancia]); el caption
    // queda solo como texto visible de la pestania.
    FClaves: TDictionary<string, TForm>;
    FContratos: TDictionary<TForm, IMantenimientoEmbebido>;
    FTitulos: TDictionary<TForm, TFunc<string>>;
    FVentanas: TObjectDictionary<TForm, TRegistroVentanaGestionada>;
    FArrastre: TArrastrePestanas;
    FConsultandoCierre: Boolean;
    FModoSDI: Boolean;
    FMenuPestana: TPopupMenu;
    FMenuSeparar: TMenuItem;
    FMenuAbiertas: TMenuItem;
    FFormularioMenu: TForm;
    function VentanasAbiertas: TArray<TForm>;
    procedure CrearMenuPestanas;
    procedure MenuContextualPestanas(Sender: TObject;
      MousePos: TPoint; var Handled: Boolean);
    procedure CerrarDesdeMenu(Sender: TObject);
    procedure SepararDesdeMenu(Sender: TObject);
    procedure CerrarOtrasDesdeMenu(Sender: TObject);
    procedure ActualizarMenuAbiertas;
    procedure ActivarDesdeMenu(Sender: TObject);
    procedure ConfigurarVentana(AForm: TForm;
      ARegistro: TRegistroVentanaGestionada);
    procedure SepararPestana(APestana: TcxTabSheet; APunto: TPoint);
    procedure InternalCloseForm(AForm: TForm;
                                AForzar: Boolean = False;
                                ALiberarAhora: Boolean = False);
    procedure QuitarClave(AForm: TForm);
  protected
    function PrepararMenuPestana(AForm: TForm): TPopupMenu;
    procedure Notification(AComponent: TComponent;
                           Operation: TOperation); override;
  public

    constructor Create(APageControl: TcxPageControl); reintroduce;
    destructor Destroy; override;
    // AIconoPestana: indice, en las Images del cxPageControl, del
    // icono que se dibuja en la pestania; -1 = sin icono.
    procedure EmbedForm(AForm: TForm;
                         const AMantenimiento: IMantenimientoEmbebido;
                         const ATitle: string;
                         const AClave: string = '';
                         ASelect: Boolean = True;
                         AIconoPestana: Integer = -1;
                         AObtenerTitulo: TFunc<string> = nil);
    // Solo navegacion: conserva el ciclo de vida propio de Caja.
    procedure RegistrarVentanaExterna(AForm: TForm);
    procedure ActualizarTitulos;
    function FindFormByCaption(const ATitle: string): TForm;
    // Ventana registrada con esa clave; nil si no hay ninguna.
    function FormPorClave(const AClave: string): TForm;
    // Formulario embebido en la pestania activa; nil si no hay ninguno.
    function FormActivo: TForm;
    // Clave con la que se registro un formulario; '' si no esta.
    function ClaveDeForm(AForm: TForm): string;
    function MantenimientoDeForm(
      AForm: TForm): IMantenimientoEmbebido;
    function GetEnumerator: TList<TForm>.TEnumerator;
    procedure CloseFormByCaption(const ATitle:string);
    procedure CloseActiveForm;
    procedure CloseAll;
    procedure ActivarFormulario(AForm: TForm);
    procedure SepararFormulario(AForm: TForm; const APunto: TPoint);
    procedure ReintegrarFormulario(AForm: TForm);
    procedure AsignarRecursoIcono(AForm: TForm; const ARecurso: string);
    function PrepararCierre: Boolean;
    function ProcesarArrastre(const AMensaje: TMsg): Boolean;
    procedure MostrarMenuPestana(AForm: TForm; const APunto: TPoint);
    procedure CerrarOtrasPestanas(AConservar: TForm);
    function RecorrerVentanas(AAnterior: Boolean): Boolean;
    function ProcesarCambioVentana(const AMensaje: TMsg): Boolean;
    property ModoSDI: Boolean read FModoSDI write FModoSDI;
  end;

implementation

uses
  System.Math, inLibPosicionFormulario, inLibMsgComun,
  inLibVentanaBarraTareas;

{ TEmbeddedFormManager }

constructor TEmbeddedFormManager.Create(APageControl: TcxPageControl);
begin
  inherited Create(APageControl);   // Owner = PageControl para autoliberación
  FPageControl := APageControl;
  FForms := TList<TForm>.Create;
  FExternas := TList<TForm>.Create;
  FClaves := TDictionary<string, TForm>.Create;
  FContratos := TDictionary<TForm, IMantenimientoEmbebido>.Create;
  FTitulos := TDictionary<TForm, TFunc<string>>.Create;
  FVentanas := TObjectDictionary<TForm,
    TRegistroVentanaGestionada>.Create([doOwnsValues]);
  FArrastre := TArrastrePestanas.Crear(Self, FPageControl,
    procedure(APestana: TcxTabSheet; APunto: TPoint)
    begin
      SepararPestana(APestana, APunto);
    end);
  CrearMenuPestanas;
end;

procedure TEmbeddedFormManager.Notification(AComponent: TComponent;
                                            Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent is TForm) then
  begin
    if AComponent = FFormularioMenu then
      FFormularioMenu := nil;
    FForms.Remove(TForm(AComponent));
    FExternas.Remove(TForm(AComponent));
    QuitarClave(TForm(AComponent));
    FContratos.Remove(TForm(AComponent));
    FTitulos.Remove(TForm(AComponent));
    FVentanas.Remove(TForm(AComponent));
  end;
end;

procedure TEmbeddedFormManager.EmbedForm(AForm: TForm;
                                         const AMantenimiento:
                                           IMantenimientoEmbebido;
                                         const ATitle: string;
                                         const AClave: string = '';
                                         ASelect: Boolean = True;
                                         AIconoPestana: Integer = -1;
                                         AObtenerTitulo: TFunc<string> = nil);
var
  NewTab: TcxTabSheet;
  oRegistro: TRegistroVentanaGestionada;
  bRedibujar: Boolean;
begin
  if AClave <> '' then
    FClaves.AddOrSetValue(AClave, AForm);
  FContratos.AddOrSetValue(AForm, AMantenimiento);
  if Assigned(AObtenerTitulo) then
    FTitulos.AddOrSetValue(AForm, AObtenerTitulo);
  bRedibujar := FPageControl.Visible;
  if bRedibujar then
    SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(False), 0);
  try
    NewTab := TcxTabSheet.Create(FPageControl);
    NewTab.Caption := ATitle + ' ';
    NewTab.ImageIndex := AIconoPestana;
    oRegistro := TRegistroVentanaGestionada.Create;
    oRegistro.Pestana := NewTab;
    Supports(AForm, IVentanaSeparable, oRegistro.Ventana);
    oRegistro.Separada := FModoSDI and Assigned(oRegistro.Ventana);
    FVentanas.Add(AForm, oRegistro);
    AForm.Caption := ATitle;
    ConfigurarVentana(AForm, oRegistro);
    if oRegistro.Separada then
    begin
      AForm.Align := alNone;
      AForm.Parent := nil;
      AForm.BorderStyle := bsSizeable;
      AForm.BorderIcons := [biSystemMenu, biMinimize, biMaximize];
      FijarPosicionFormulario(AForm, poScreenCenter);
      if AForm.HandleAllocated then
        AForm.Perform(CM_RECREATEWND, 0, 0);
      if Assigned(FPageControl.Images) and (AIconoPestana >= 0) then
        FPageControl.Images.GetIcon(AIconoPestana, AForm.Icon);
    end
    else
    begin
      NewTab.PageControl := FPageControl;
      AForm.BorderStyle := bsNone;
      AForm.Parent := NewTab;
      AForm.SetBounds(0, 0, NewTab.ClientWidth, NewTab.ClientHeight);
      AForm.Align := alClient;
    end;
    FForms.Add(AForm);
    AForm.FreeNotification(Self);    // <-- CLAVE: nos avisarán si lo liberan
    if ASelect and not oRegistro.Separada then
      FPageControl.ActivePage := NewTab;
  finally
    if bRedibujar then
    begin
      SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(True), 0);
      RedrawWindow(FPageControl.Handle, nil, 0,
        RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
    end;
    AForm.Visible := True;
    AForm.Show;
  end;
end;

destructor TEmbeddedFormManager.Destroy;
begin
  FPageControl.OnContextPopup := nil;
  FreeAndNil(FArrastre);
  FreeAndNil(FVentanas);
  FreeAndNil(FTitulos);
  FreeAndNil(FContratos);
  FreeAndNil(FForms);
  FreeAndNil(FExternas);
  FreeAndNil(FClaves);
  inherited;
end;

procedure TEmbeddedFormManager.RegistrarVentanaExterna(AForm: TForm);
begin
  if Assigned(AForm) and not FExternas.Contains(AForm) and
     not FForms.Contains(AForm) then
  begin
    FExternas.Add(AForm);
    AForm.FreeNotification(Self);
  end;
end;

function TEmbeddedFormManager.VentanasAbiertas: TArray<TForm>;
var
  oLista: TList<TForm>;
  oFormulario: TForm;
begin
  oLista := TList<TForm>.Create;
  try
    oLista.AddRange(FForms);
    for oFormulario in FExternas do
      if oFormulario.Visible and
         not (csDestroying in oFormulario.ComponentState) then
        oLista.Add(oFormulario);
    Result := oLista.ToArray;
  finally
    oLista.Free;
  end;
end;

procedure TEmbeddedFormManager.ActualizarTitulos;
var
  oFormulario: TForm;
  ObtenerTitulo: TFunc<string>;
  oRegistro: TRegistroVentanaGestionada;
begin
  for oFormulario in FForms do
    if FTitulos.TryGetValue(oFormulario, ObtenerTitulo) then
    begin
      oFormulario.Caption := ObtenerTitulo();
      if FVentanas.TryGetValue(oFormulario, oRegistro) then
        oRegistro.Pestana.Caption := oFormulario.Caption + ' ';
    end;
end;

procedure TEmbeddedFormManager.CloseAll;
var
  F: TForm;
begin
  while FForms.Count > 0 do
  begin
    F := FForms[FForms.Count - 1];
    // Durante el apagado los servicios deben sobrevivir a los formularios.
    InternalCloseForm(F, True, True);
  end;
end;

function TEmbeddedFormManager.FindFormByCaption(const ATitle: string): TForm;
var
  F: TForm;
begin
  Result := nil;
  for F in FForms do
  begin
    if (Result = nil) and (F.Parent is TcxTabSheet) and
       (Trim(TcxTabSheet(F.Parent).Caption) = Trim(ATitle)) then
      Result := F;
  end;
end;

function TEmbeddedFormManager.FormPorClave(const AClave: string): TForm;
begin
  if not FClaves.TryGetValue(AClave, Result) then
    Result := nil;
end;

function TEmbeddedFormManager.FormActivo: TForm;
var
  ts: TcxTabSheet;
begin
  Result := nil;
  if (Screen.ActiveForm is TForm) and
     (FForms.Contains(TForm(Screen.ActiveForm)) or
      FExternas.Contains(TForm(Screen.ActiveForm))) then
    Result := TForm(Screen.ActiveForm)
  else if (FPageControl <> nil) and (FPageControl.ActivePage <> nil) then
  begin
    ts := FPageControl.ActivePage;
    if (ts.ControlCount > 0) and (ts.Controls[0] is TForm) then
      Result := TForm(ts.Controls[0]);
  end;
end;

function TEmbeddedFormManager.ClaveDeForm(AForm: TForm): string;
var
  sClave: string;
begin
  Result := '';
  for sClave in FClaves.Keys do
  begin
    if FClaves[sClave] = AForm then
    begin
      Result := sClave;
      Break;
    end;
  end;
end;

function TEmbeddedFormManager.MantenimientoDeForm(
  AForm: TForm): IMantenimientoEmbebido;
begin
  if not FContratos.TryGetValue(AForm, Result) then
    Result := nil;
end;

procedure TEmbeddedFormManager.QuitarClave(AForm: TForm);
var
  sClave: string;
begin
  for sClave in FClaves.Keys do
  begin
    if FClaves[sClave] = AForm then
    begin
      FClaves.Remove(sClave);
      Break;
    end;
  end;
end;

// Esto habilita la sintaxis "for .. in"
function TEmbeddedFormManager.GetEnumerator: TList<TForm>.TEnumerator;
begin
  Result := FForms.GetEnumerator;
end;

procedure TEmbeddedFormManager.CloseActiveForm;
var
  ActiveSheet: TcxTabSheet;
  I: Integer;
  F: TForm;
begin
  ActiveSheet := FPageControl.ActivePage;
  if ActiveSheet <> nil then
  begin
    // Se busca el formulario alojado en la pestaña activa.
    for I := FForms.Count - 1 downto 0 do
    begin
      F := FForms[I];
      if F.Parent = ActiveSheet then
      begin
        InternalCloseForm(F);
        Break;
      end;
    end;
  end;
end;

procedure TEmbeddedFormManager.InternalCloseForm(AForm: TForm;
                                                AForzar: Boolean;
                                                ALiberarAhora: Boolean);
var
  ParentTab: TWinControl;
  oMantenimiento: IMantenimientoEmbebido;
  bInterceptar: Boolean;
  oRegistro: TRegistroVentanaGestionada;
begin
  if (AForm <> nil) and (PPointer(AForm)^ <> nil) then
  begin
    try
      if csDestroying in AForm.ComponentState then
        FForms.Remove(AForm)
      else
      begin
        bInterceptar := False;
        if (not AForzar) and
           FContratos.TryGetValue(AForm, oMantenimiento) then
          bInterceptar := oMantenimiento.InterceptarCierre;
        if not AForzar and not bInterceptar then
          bInterceptar := not AForm.CloseQuery;
        if not bInterceptar then
        begin
          SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(False), 0);
          SendMessage(AForm.Handle, WM_SETREDRAW, WPARAM(False), 0);
          AForm.Hide;
          ParentTab := AForm.Parent;
          if FVentanas.TryGetValue(AForm, oRegistro) then
            ParentTab := oRegistro.Pestana;
          FForms.Remove(AForm);
          QuitarClave(AForm);
          FContratos.Remove(AForm);
          FTitulos.Remove(AForm);
          FVentanas.Remove(AForm);
          AForm.Parent := nil;
          if ALiberarAhora then
            FreeAndNil(AForm)
          else
            AForm.Release;
          if (ParentTab <> nil) and (ParentTab is TcxTabSheet) and
             not (csDestroying in ParentTab.ComponentState) then
            FreeAndNil(ParentTab);
        end;
      end;
    finally
      SendMessage(FPageControl.Handle, WM_SETREDRAW, WPARAM(True), 0);
      RedrawWindow(FPageControl.Handle, nil, 0,
        RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_ALLCHILDREN);
    end;
  end;
end;

procedure TEmbeddedFormManager.CloseFormByCaption(const ATitle: string);
var
  LForm: TForm;
begin
  LForm := FindFormByCaption(ATitle);
  if LForm <> nil then
    InternalCloseForm(LForm);
end;

procedure TEmbeddedFormManager.ConfigurarVentana(AForm: TForm;
  ARegistro: TRegistroVentanaGestionada);
var
  oConfiguracion: TConfiguracionVentanaGestionada;
begin
  if Assigned(ARegistro.Ventana) then
  begin
    oConfiguracion := Default(TConfiguracionVentanaGestionada);
    oConfiguracion.Separada := ARegistro.Separada;
    oConfiguracion.Grupo := 'ViraCash.Pantalla.' +
      IntToStr(GetCurrentProcessId) + '.' + IntToStr(NativeUInt(AForm));
    oConfiguracion.RecursoIcono := ARegistro.RecursoIcono;
    // TForm.Close ya ha consultado CloseQuery antes de DoClose.
    oConfiguracion.Cerrar :=
      procedure
      begin
        InternalCloseForm(AForm, True);
      end;
    oConfiguracion.Volver :=
      procedure
      begin
        ReintegrarFormulario(AForm);
      end;
    oConfiguracion.MostrarMenu :=
      procedure(X, Y: Integer)
      begin
        MostrarMenuPestana(AForm, Point(X, Y));
      end;
    ARegistro.Ventana.ConfigurarVentanaGestionada(oConfiguracion);
  end;
end;

procedure TEmbeddedFormManager.AsignarRecursoIcono(AForm: TForm;
  const ARecurso: string);
var
  oRegistro: TRegistroVentanaGestionada;
begin
  if FVentanas.TryGetValue(AForm, oRegistro) then
  begin
    oRegistro.RecursoIcono := ARecurso;
    ConfigurarVentana(AForm, oRegistro);
    if oRegistro.Separada and AForm.HandleAllocated then
      AsignarIconoVentanaDesdePng(AForm.Handle, ARecurso);
  end;
end;

procedure TEmbeddedFormManager.ActivarFormulario(AForm: TForm);
var
  oRegistro: TRegistroVentanaGestionada;
  oPrincipal: TCustomForm;
begin
  if FExternas.Contains(AForm) then
  begin
    if AForm.WindowState = wsMinimized then
      AForm.WindowState := wsNormal;
    AForm.Show;
    AForm.BringToFront;
    SetForegroundWindow(AForm.Handle);
    if AForm.CanFocus then
      AForm.SetFocus;
  end
  else if FVentanas.TryGetValue(AForm, oRegistro) then
  begin
    if oRegistro.Separada then
    begin
      if AForm.WindowState = wsMinimized then
        AForm.WindowState := wsNormal;
      AForm.Show;
      AForm.BringToFront;
      SetForegroundWindow(AForm.Handle);
    end
    else
    begin
      oPrincipal := GetParentForm(FPageControl);
      if Assigned(oPrincipal) then
      begin
        if oPrincipal.WindowState = wsMinimized then
          oPrincipal.WindowState := wsNormal;
        oPrincipal.Show;
        oPrincipal.BringToFront;
      end;
      FPageControl.ActivePage := oRegistro.Pestana;
      if AForm.CanFocus then
        AForm.SetFocus;
    end;
  end;
end;

procedure TEmbeddedFormManager.SepararPestana(APestana: TcxTabSheet;
  APunto: TPoint);
begin
  if (APestana.ControlCount > 0) and
     (APestana.Controls[0] is TForm) then
    SepararFormulario(TForm(APestana.Controls[0]), APunto);
end;

procedure TEmbeddedFormManager.SepararFormulario(AForm: TForm;
  const APunto: TPoint);
var
  oRegistro: TRegistroVentanaGestionada;
  oArea: TRect;
  iAncho, iAlto: Integer;
begin
  if not FConsultandoCierre and (Application.ModalLevel = 0) and
     FVentanas.TryGetValue(AForm, oRegistro) and
     Assigned(oRegistro.Ventana) and not oRegistro.Separada then
  begin
    oArea := Screen.MonitorFromPoint(APunto).WorkareaRect;
    iAncho := Min(AForm.Width, oArea.Width);
    iAlto := Min(AForm.Height, oArea.Height);
    oRegistro.IndicePestana := oRegistro.Pestana.PageIndex;
    oRegistro.Ventana.CambiarContenedor(True);
    try
      AForm.Hide;
      if Assigned(FPageControl.Images) and
         (oRegistro.Pestana.ImageIndex >= 0) then
        FPageControl.Images.GetIcon(oRegistro.Pestana.ImageIndex,
          AForm.Icon);
      oRegistro.Separada := True;
      ConfigurarVentana(AForm, oRegistro);
      AForm.Align := alNone;
      AForm.Parent := nil;
      AForm.BorderStyle := bsSizeable;
      AForm.BorderIcons := [biSystemMenu, biMinimize, biMaximize];
      FijarPosicionFormulario(AForm, poDesigned);
      AForm.SetBounds(
        EnsureRange(APunto.X - iAncho div 2,
          oArea.Left, oArea.Right - iAncho),
        EnsureRange(APunto.Y - 24, oArea.Top, oArea.Bottom - iAlto),
        iAncho, iAlto);
      oRegistro.Pestana.PageControl := nil;
      AForm.Show;
    finally
      oRegistro.Ventana.CambiarContenedor(False);
    end;
    ActivarFormulario(AForm);
  end;
end;

procedure TEmbeddedFormManager.ReintegrarFormulario(AForm: TForm);
var
  oRegistro: TRegistroVentanaGestionada;
begin
  if not FConsultandoCierre and (Application.ModalLevel = 0) and
     FVentanas.TryGetValue(AForm, oRegistro) and oRegistro.Separada then
  begin
    oRegistro.Ventana.CambiarContenedor(True);
    try
      AForm.Hide;
      AForm.WindowState := wsNormal;
      oRegistro.Separada := False;
      ConfigurarVentana(AForm, oRegistro);
      oRegistro.Pestana.PageControl := FPageControl;
      oRegistro.Pestana.PageIndex := Min(oRegistro.IndicePestana,
        FPageControl.PageCount - 1);
      AForm.BorderStyle := bsNone;
      AForm.Parent := oRegistro.Pestana;
      AForm.Align := alClient;
      FPageControl.ActivePage := oRegistro.Pestana;
      AForm.Show;
    finally
      oRegistro.Ventana.CambiarContenedor(False);
    end;
    ActivarFormulario(AForm);
  end;
end;

function TEmbeddedFormManager.PrepararCierre: Boolean;
var
  iFormulario: Integer;
begin
  Result := not FConsultandoCierre;
  if Result then
  begin
    FConsultandoCierre := True;
    try
      iFormulario := 0;
      while Result and (iFormulario < FForms.Count) do
      begin
        Result := FForms[iFormulario].CloseQuery;
        if not Result then
          ActivarFormulario(FForms[iFormulario]);
        Inc(iFormulario);
      end;
    finally
      FConsultandoCierre := False;
    end;
  end;
end;

function TEmbeddedFormManager.ProcesarArrastre(
  const AMensaje: TMsg): Boolean;
begin
  Result := FArrastre.ProcesarMensaje(AMensaje);
end;

function TEmbeddedFormManager.RecorrerVentanas(
  AAnterior: Boolean): Boolean;
var
  iDestino: Integer;
  aVentanas: TArray<TForm>;
begin
  aVentanas := VentanasAbiertas;
  Result := (Length(aVentanas) > 0) and not FConsultandoCierre and
    (Application.ModalLevel = 0);
  if Result then
  begin
    iDestino := Length(aVentanas) - 1;
    while (iDestino >= 0) and (aVentanas[iDestino] <> FormActivo) do
      Dec(iDestino);
    if iDestino < 0 then
    begin
      if AAnterior then
        iDestino := Length(aVentanas) - 1
      else
        iDestino := 0;
    end
    else if AAnterior then
      iDestino := (iDestino + Length(aVentanas) - 1) mod Length(aVentanas)
    else
      iDestino := (iDestino + 1) mod Length(aVentanas);
    ActivarFormulario(aVentanas[iDestino]);
  end;
end;

function TEmbeddedFormManager.ProcesarCambioVentana(
  const AMensaje: TMsg): Boolean;
begin
  Result := False;
  if (AMensaje.message = WM_KEYDOWN) and
     (AMensaje.wParam = VK_TAB) and
     (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) >= 0) and
     ((Screen.ActiveForm = GetParentForm(FPageControl)) or
      FForms.Contains(TForm(Screen.ActiveForm)) or
      FExternas.Contains(TForm(Screen.ActiveForm))) then
    Result := RecorrerVentanas(GetKeyState(VK_SHIFT) < 0);
end;

procedure TEmbeddedFormManager.CrearMenuPestanas;
var
  oCerrar, oCerrarOtras: TMenuItem;
begin
  FMenuPestana := TPopupMenu.Create(Self);
  oCerrar := TMenuItem.Create(FMenuPestana);
  oCerrar.Caption := SCerrarPestana;
  oCerrar.OnClick := CerrarDesdeMenu;
  FMenuPestana.Items.Add(oCerrar);
  FMenuSeparar := TMenuItem.Create(FMenuPestana);
  FMenuSeparar.OnClick := SepararDesdeMenu;
  FMenuPestana.Items.Add(FMenuSeparar);
  oCerrarOtras := TMenuItem.Create(FMenuPestana);
  oCerrarOtras.Caption := SCerrarOtrasPestanas;
  oCerrarOtras.OnClick := CerrarOtrasDesdeMenu;
  FMenuPestana.Items.Add(oCerrarOtras);
  FMenuAbiertas := TMenuItem.Create(FMenuPestana);
  FMenuPestana.Items.Add(FMenuAbiertas);
  FPageControl.OnContextPopup := MenuContextualPestanas;
end;

procedure TEmbeddedFormManager.MenuContextualPestanas(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
var
  iIndice: Integer;
  oPestana: TcxTabSheet;
begin
  iIndice := FPageControl.IndexOfTabAt(MousePos.X, MousePos.Y);
  if (iIndice >= 0) and not Handled then
  begin
    oPestana := FPageControl.Pages[iIndice];
    Handled := (oPestana.ControlCount > 0) and
      (oPestana.Controls[0] is TForm);
    if Handled then
      MostrarMenuPestana(TForm(oPestana.Controls[0]),
        FPageControl.ClientToScreen(MousePos));
  end;
end;

procedure TEmbeddedFormManager.MostrarMenuPestana(AForm: TForm;
  const APunto: TPoint);
var
  oMenu: TPopupMenu;
begin
  oMenu := PrepararMenuPestana(AForm);
  if Assigned(oMenu) then
    oMenu.Popup(APunto.X, APunto.Y);
end;

function TEmbeddedFormManager.PrepararMenuPestana(
  AForm: TForm): TPopupMenu;
var
  oRegistro: TRegistroVentanaGestionada;
begin
  Result := nil;
  if FVentanas.TryGetValue(AForm, oRegistro) then
  begin
    FFormularioMenu := AForm;
    FMenuPestana.Items[0].Caption := SCerrarPestana;
    FMenuPestana.Items[2].Caption := SCerrarOtrasPestanas;
    FMenuSeparar.Enabled := Assigned(oRegistro.Ventana);
    ActualizarMenuAbiertas;
    if oRegistro.Separada then
      FMenuSeparar.Caption := SDockarPestana
    else
      FMenuSeparar.Caption := SDesdockarPestana;
    Result := FMenuPestana;
  end;
end;

procedure TEmbeddedFormManager.ActualizarMenuAbiertas;
var
  oFormulario: TForm;
  oElemento: TMenuItem;
  oRegistro: TRegistroVentanaGestionada;
begin
  FMenuPestana.Images := FPageControl.Images;
  FMenuAbiertas.Clear;
  FMenuAbiertas.Caption := SOpcionesAbiertas;
  for oFormulario in VentanasAbiertas do
  begin
    oElemento := TMenuItem.Create(FMenuPestana);
    oElemento.Caption := StringReplace(oFormulario.Caption,
      '&', '&&', [rfReplaceAll]);
    if FVentanas.TryGetValue(oFormulario, oRegistro) then
      oElemento.ImageIndex := oRegistro.Pestana.ImageIndex
    else
      oElemento.ImageIndex := -1;
    oElemento.Tag := NativeInt(oFormulario);
    oElemento.Checked := oFormulario = FFormularioMenu;
    oElemento.OnClick := ActivarDesdeMenu;
    FMenuAbiertas.Add(oElemento);
  end;
end;

procedure TEmbeddedFormManager.ActivarDesdeMenu(Sender: TObject);
var
  oFormulario: TForm;
begin
  oFormulario := TForm(TMenuItem(Sender).Tag);
  if FForms.Contains(oFormulario) or FExternas.Contains(oFormulario) then
    ActivarFormulario(oFormulario);
end;

procedure TEmbeddedFormManager.CerrarDesdeMenu(Sender: TObject);
begin
  if FForms.Contains(FFormularioMenu) then
    FFormularioMenu.Close;
end;

procedure TEmbeddedFormManager.SepararDesdeMenu(Sender: TObject);
var
  oRegistro: TRegistroVentanaGestionada;
begin
  if FVentanas.TryGetValue(FFormularioMenu, oRegistro) then
  begin
    if oRegistro.Separada then
      ReintegrarFormulario(FFormularioMenu)
    else
      SepararFormulario(FFormularioMenu, Mouse.CursorPos);
  end;
end;

procedure TEmbeddedFormManager.CerrarOtrasDesdeMenu(Sender: TObject);
begin
  CerrarOtrasPestanas(FFormularioMenu);
end;

procedure TEmbeddedFormManager.CerrarOtrasPestanas(AConservar: TForm);
var
  aFormularios: TArray<TForm>;
  oFormulario: TForm;
  bCerrar: Boolean;
begin
  if FForms.Contains(AConservar) and not FConsultandoCierre then
  begin
    aFormularios := FForms.ToArray;
    bCerrar := True;
    for oFormulario in aFormularios do
      if bCerrar and (oFormulario <> AConservar) and
         FForms.Contains(oFormulario) then
      begin
        bCerrar := oFormulario.CloseQuery;
        if bCerrar then
          InternalCloseForm(oFormulario, True)
        else
          ActivarFormulario(oFormulario);
      end;
    if bCerrar then
      ActivarFormulario(AConservar);
  end;
end;

end.
