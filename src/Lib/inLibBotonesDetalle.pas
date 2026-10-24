{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBotonesDetalle                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Botones «Añadir» y «Borrar» sobre las rejillas de detalle de los          }
{    mantenimientos. Pulsan los botones del navegador de la vista, así que     }
{    hacen lo mismo que «+» y «-», incluido el manejador propio de cada        }
{    pantalla y la confirmación de borrado.                                    }
{******************************************************************************}
unit inLibBotonesDetalle;

interface

uses
  cxGridDBTableView;

type
  TBotonDetalle = (bdAnadir, bdBorrar);
  TBotonesDetalle = set of TBotonDetalle;

// Coloca la barra de botones encima de la rejilla de AVista. Solo crea
// los botones pedidos en ABotones que la vista permite (OptionsData.
// Inserting / Deleting): una pantalla con su propio botón de alta pide
// solo [bdBorrar]. El dueño de lo creado es el de la vista (el form).
procedure AnadirBotonesDetalle(AVista: TcxGridDBTableView;
  ABotones: TBotonesDetalle = [bdAnadir, bdBorrar]);

implementation

uses
  System.SysUtils, System.Classes, System.Actions, Vcl.ActnList,
  Vcl.Controls, cxNavigator, cxButtons, cxGroupBox, cxEdit,
  inLibMsgComun;

const
  ALTO_BARRA = 34;
  ANCHO_BOTON = 96;
  MARGEN_BOTON = 4;

type
  // Colaborador con dueño el formulario: guarda la vista, la rejilla
  // envuelta y las acciones de los dos botones.
  TGestorBotonesDetalle = class(TComponent)
  private
    FVista: TcxGridDBTableView;
    FRejilla: TWinControl;
    FPadreOriginal: TWinControl;
    FContenedor: TcxGroupBox;
    FBarra: TcxGroupBox;
    FAcciones: TActionList;
    FIndiceAlta: Integer;
    function NombreBase: string;
    function CrearPanel(AParent: TWinControl;
      const ANombre: string): TcxGroupBox;
    function CrearAccion(const ANombre: string;
      AEjecutar, AActualizar: TNotifyEvent): TAction;
    procedure CrearBoton(AAccion: TAction; const ANombre: string;
      ALeft: Integer);
    procedure EnvolverRejilla;
    function PuedePulsar(AIndice: Integer): Boolean;
    procedure AnadirExecute(Sender: TObject);
    procedure AnadirUpdate(Sender: TObject);
    procedure BorrarExecute(Sender: TObject);
    procedure BorrarUpdate(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent;
      AOperation: TOperation); override;
  public
    constructor CrearPara(AVista: TcxGridDBTableView;
      ABotones: TBotonesDetalle);
    destructor Destroy; override;
  end;

procedure AnadirBotonesDetalle(AVista: TcxGridDBTableView;
  ABotones: TBotonesDetalle);
begin
  if Assigned(AVista) and
     Assigned(AVista.Owner) and
     (AVista.Control is TWinControl) and
     Assigned(TWinControl(AVista.Control).Parent) and
     (((bdAnadir in ABotones) and AVista.OptionsData.Inserting) or
      ((bdBorrar in ABotones) and AVista.OptionsData.Deleting)) then
    TGestorBotonesDetalle.CrearPara(AVista, ABotones);
end;

{ TGestorBotonesDetalle }

constructor TGestorBotonesDetalle.CrearPara(AVista: TcxGridDBTableView;
  ABotones: TBotonesDetalle);
var
  iLeft: Integer;
begin
  inherited Create(AVista.Owner);
  FVista := AVista;
  FRejilla := TWinControl(AVista.Control);
  FPadreOriginal := FRejilla.Parent;
  Self.Name := 'bdt' + Self.NombreBase;
  FVista.FreeNotification(Self);
  FRejilla.FreeNotification(Self);
  FPadreOriginal.FreeNotification(Self);
  // Las vistas que solo tienen «Añadir al final» (documentos) no muestran
  // Insert; entonces el botón pulsa Append.
  FIndiceAlta := NBDI_INSERT;
  if (not FVista.Navigator.Buttons.Insert.Visible) and
     FVista.Navigator.Buttons.Append.Visible then
    FIndiceAlta := NBDI_APPEND;
  // Borrar preguntaba dos veces: el navegador («¿Desea borrar este
  // registro?») y la rejilla («¿Borrar registro?»). Si la rejilla ya
  // pregunta, el navegador no.
  if FVista.OptionsData.DeletingConfirmation then
    FVista.Navigator.Buttons.ConfirmDelete := False;
  FAcciones := TActionList.Create(Self);
  Self.EnvolverRejilla;
  iLeft := MARGEN_BOTON;
  if (bdAnadir in ABotones) and FVista.OptionsData.Inserting then
  begin
    Self.CrearBoton(Self.CrearAccion('actAnadir', Self.AnadirExecute,
      Self.AnadirUpdate), 'btnAnadir', iLeft);
    iLeft := iLeft + ANCHO_BOTON + MARGEN_BOTON;
  end;
  if (bdBorrar in ABotones) and FVista.OptionsData.Deleting then
    Self.CrearBoton(Self.CrearAccion('actBorrar', Self.BorrarExecute,
      Self.BorrarUpdate), 'btnBorrar', iLeft);
end;

// Al cerrar el formulario este colaborador se libera antes que la rejilla
// (se creó después): la rejilla sale del contenedor para que no la
// destruya él, y la libera su dueño como siempre.
destructor TGestorBotonesDetalle.Destroy;
begin
  if Assigned(FRejilla) and
     (FRejilla.Parent = FContenedor) then
  begin
    if (csDestroying in FRejilla.ComponentState) or
       (not Assigned(FPadreOriginal)) then
      FRejilla.Parent := nil
    else
      FRejilla.Parent := FPadreOriginal;
  end;
  inherited;
end;

procedure TGestorBotonesDetalle.Notification(AComponent: TComponent;
  AOperation: TOperation);
begin
  inherited;
  if AOperation = opRemove then
  begin
    if AComponent = FVista then
      FVista := nil;
    if AComponent = FRejilla then
      FRejilla := nil;
    if AComponent = FPadreOriginal then
      FPadreOriginal := nil;
  end;
end;

// tvAlmacenesCajas -> AlmacenesCajas: los nombres de los controles
// creados siguen el de la vista y no se repiten en el formulario.
function TGestorBotonesDetalle.NombreBase: string;
begin
  Result := FVista.Name;
  if SameText(Copy(Result, 1, 2), 'tv') then
    Result := Copy(Result, 3, MaxInt);
end;

function TGestorBotonesDetalle.CrearPanel(AParent: TWinControl;
  const ANombre: string): TcxGroupBox;
begin
  Result := TcxGroupBox.Create(Self);
  Result.Name := ANombre + Self.NombreBase;
  Result.Caption := '';
  Result.PanelStyle.Active := True;
  Result.Style.BorderStyle := ebsNone;
  Result.Transparent := True;
  Result.Parent := AParent;
end;

// La rejilla pasa a un contenedor que ocupa su mismo sitio (alineación,
// posición y anclajes), con la barra encima. Así vale igual para una
// rejilla que llena su pestaña que para dos rejillas lado a lado.
procedure TGestorBotonesDetalle.EnvolverRejilla;
begin
  FPadreOriginal.DisableAlign;
  try
    FContenedor := Self.CrearPanel(FPadreOriginal, 'pnlDetalle');
    FContenedor.Align := alNone;
    FContenedor.BoundsRect := FRejilla.BoundsRect;
    FContenedor.Anchors := FRejilla.Anchors;
    FContenedor.AlignWithMargins := FRejilla.AlignWithMargins;
    FContenedor.Margins.Assign(FRejilla.Margins);
    FContenedor.TabOrder := FRejilla.TabOrder;
    FContenedor.Align := FRejilla.Align;
    FBarra := Self.CrearPanel(FContenedor, 'pnlBotones');
    FBarra.Align := alTop;
    FBarra.Height := ALTO_BARRA;
    FRejilla.AlignWithMargins := False;
    FRejilla.Parent := FContenedor;
    FRejilla.Align := alClient;
  finally
    FPadreOriginal.EnableAlign;
  end;
end;

function TGestorBotonesDetalle.CrearAccion(const ANombre: string;
  AEjecutar, AActualizar: TNotifyEvent): TAction;
begin
  Result := TAction.Create(Self);
  Result.Name := ANombre + Self.NombreBase;
  Result.ActionList := FAcciones;
  Result.OnExecute := AEjecutar;
  Result.OnUpdate := AActualizar;
  AActualizar(Result);
end;

procedure TGestorBotonesDetalle.CrearBoton(AAccion: TAction;
  const ANombre: string; ALeft: Integer);
var
  oBoton: TcxButton;
begin
  oBoton := TcxButton.Create(Self);
  oBoton.Name := ANombre + Self.NombreBase;
  oBoton.Parent := FBarra;
  oBoton.SetBounds(ALeft, MARGEN_BOTON, ANCHO_BOTON,
    ALTO_BARRA - 2 * MARGEN_BOTON);
  oBoton.Action := AAccion;
  oBoton.ShowHint := True;
end;

// Misma regla que el navegador de la vista para activar «+» y «-».
function TGestorBotonesDetalle.PuedePulsar(AIndice: Integer): Boolean;
var
  oNavegador: IcxNavigator;
begin
  Result := Assigned(FVista) and
    FVista.Navigator.Buttons[AIndice].Enabled and
    Supports(FVista, IcxNavigator, oNavegador) and
    oNavegador.IsActive;
  if Result then
  begin
    case AIndice of
      NBDI_INSERT:
        Result := oNavegador.CanInsert;
      NBDI_APPEND:
        Result := oNavegador.CanAppend;
      NBDI_DELETE:
        Result := oNavegador.CanDelete;
    end;
  end;
end;

// El foco va a la rejilla antes del alta: si la fila nueva naciera con
// el foco en el botón, la rejilla la cancelaría al entrar y salir de ella
// sin cambios (CancelOnExit). Después, el editor queda abierto en la
// columna enfocada para teclear sin doble clic (FZ-ISSUE-625).
procedure TGestorBotonesDetalle.AnadirExecute(Sender: TObject);
begin
  if Assigned(FVista) then
  begin
    if FVista.Site.CanFocus then
      FVista.Site.SetFocus;
    FVista.Navigator.Buttons.ClickButton(FIndiceAlta);
    if FVista.DataController.IsEditing and
       (not FVista.Controller.EditingController.IsEditing) then
      FVista.Controller.EditingController.ShowEdit;
  end;
end;

// Los textos se releen en cada actualización: si el usuario cambia de
// idioma con la pantalla abierta, los botones lo siguen.
procedure TGestorBotonesDetalle.AnadirUpdate(Sender: TObject);
var
  oAccion: TAction;
begin
  oAccion := Sender as TAction;
  oAccion.Caption := SBotonAnadirDetalle;
  oAccion.Hint := SHintAnadirDetalle;
  oAccion.Enabled := Self.PuedePulsar(FIndiceAlta);
end;

procedure TGestorBotonesDetalle.BorrarExecute(Sender: TObject);
begin
  if Assigned(FVista) then
    FVista.Navigator.Buttons.ClickButton(NBDI_DELETE);
end;

procedure TGestorBotonesDetalle.BorrarUpdate(Sender: TObject);
var
  oAccion: TAction;
begin
  oAccion := Sender as TAction;
  oAccion.Caption := SBotonBorrarDetalle;
  oAccion.Hint := SHintBorrarDetalle;
  oAccion.Enabled := Self.PuedePulsar(NBDI_DELETE);
end;

end.
