{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionArticuloVcl                     }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presentadores del historial de articulos visitados y del desplegable de   }
{    coincidencias de la consulta de stock. Reciben contenedor, control de     }
{    referencia y cierres de aplicacion: nunca el formulario completo.         }
{******************************************************************************}
unit inMtoStockConsultaPresentacionArticuloVcl;

interface

uses
  Winapi.Windows,
  System.Classes,
  Vcl.Controls,
  cxControls, cxContainer, cxEdit, cxTextEdit,
  cxButtons, cxDropDownEdit,
  inLibStockConsultaEntradaIntf,
  inLibStockConsultaPresentacionCoincidencias,
  inLibStockConsultaPresentacionHistorial;

type
  TAplicarArticuloStock = reference to procedure(
    const ACodigoArticulo, ACodigoSku: string);
  TConsultaAdmisionStock = reference to function: Boolean;

  TPresentadorHistorialStock = class
  private
    FHistorial: THistorialArticulosStock;
    FBotonAnterior: TcxButton;
    FBotonSiguiente: TcxButton;
    FNavegar: TAplicarArticuloStock;
    procedure AnteriorClick(Sender: TObject);
    procedure SiguienteClick(Sender: TObject);
    procedure Navegar(const ACodigoArticulo: string);
  public
    constructor Create(
      AOwner: TComponent;
      AContenedor: TWinControl;
      AReferencia: TControl;
      const AHintAnterior, AHintSiguiente: string;
      const ANavegar: TAplicarArticuloStock);
    destructor Destroy; override;
    procedure Registrar(const ACodigoArticulo: string);
    procedure ActualizarBotones;
  end;

  TPresentadorCoincidenciasStock = class
  private
    FCoincidencias: TCoincidenciasArticuloStock;
    FCombo: TcxComboBox;
    FContenedor: TWinControl;
    FReferencia: TWinControl;
    FAplicar: TAplicarArticuloStock;
    FAdmiteSeleccion: TConsultaAdmisionStock;
    procedure ComboEditValueChanged(Sender: TObject);
    procedure ComboExit(Sender: TObject);
    procedure ComboKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure DevolverFoco;
  public
    constructor Create(
      AOwner: TComponent;
      AContenedor: TWinControl;
      AReferencia: TWinControl;
      const AAplicar: TAplicarArticuloStock;
      const AAdmiteSeleccion: TConsultaAdmisionStock);
    destructor Destroy; override;
    procedure Mostrar(
      const ACoincidencias: TCoincidenciasEntradaStock;
      const AHint: string);
    procedure Ocultar;
    function EstaVisible: Boolean;
    function CerrarConEscape: Boolean;
  end;

implementation

uses
  System.SysUtils;

const
  ANCHO_BOTON_HISTORIAL = 28;
  SEPARACION_HISTORIAL = 8;
  SEPARACION_ENTRE_BOTONES = 4;
  MARGEN_DESPLEGABLE_COINCIDENCIAS = 20;

constructor TPresentadorHistorialStock.Create(
  AOwner: TComponent;
  AContenedor: TWinControl;
  AReferencia: TControl;
  const AHintAnterior, AHintSiguiente: string;
  const ANavegar: TAplicarArticuloStock);
begin
  inherited Create;
  FHistorial := THistorialArticulosStock.Create;
  FNavegar := ANavegar;
  FBotonAnterior := TcxButton.Create(AOwner);
  FBotonAnterior.Parent := AContenedor;
  FBotonAnterior.Caption := '<';
  FBotonAnterior.Hint := AHintAnterior;
  FBotonAnterior.ShowHint := True;
  FBotonAnterior.SetBounds(
    AReferencia.Left + AReferencia.Width + SEPARACION_HISTORIAL,
    AReferencia.Top,
    ANCHO_BOTON_HISTORIAL,
    AReferencia.Height);
  FBotonAnterior.OnClick := AnteriorClick;
  FBotonSiguiente := TcxButton.Create(AOwner);
  FBotonSiguiente.Parent := AContenedor;
  FBotonSiguiente.Caption := '>';
  FBotonSiguiente.Hint := AHintSiguiente;
  FBotonSiguiente.ShowHint := True;
  FBotonSiguiente.SetBounds(
    FBotonAnterior.Left + FBotonAnterior.Width +
      SEPARACION_ENTRE_BOTONES,
    AReferencia.Top,
    ANCHO_BOTON_HISTORIAL,
    AReferencia.Height);
  FBotonSiguiente.OnClick := SiguienteClick;
  ActualizarBotones;
end;

destructor TPresentadorHistorialStock.Destroy;
begin
  FNavegar := nil;
  FreeAndNil(FHistorial);
  inherited Destroy;
end;

procedure TPresentadorHistorialStock.Registrar(
  const ACodigoArticulo: string);
begin
  FHistorial.Registrar(ACodigoArticulo);
end;

procedure TPresentadorHistorialStock.ActualizarBotones;
begin
  FBotonAnterior.Enabled := FHistorial.PuedeAnterior;
  FBotonSiguiente.Enabled := FHistorial.PuedeSiguiente;
end;

// Marca el historial como "moviendo" para que la carga del articulo no
// vuelva a registrarlo y desplace la posicion.
procedure TPresentadorHistorialStock.Navegar(
  const ACodigoArticulo: string);
begin
  FHistorial.Moviendo := True;
  try
    FNavegar(ACodigoArticulo, '');
  finally
    FHistorial.Moviendo := False;
    ActualizarBotones;
  end;
end;

procedure TPresentadorHistorialStock.AnteriorClick(Sender: TObject);
var
  sArticulo: string;
begin
  sArticulo := FHistorial.Anterior;
  if sArticulo <> '' then
    Navegar(sArticulo);
end;

procedure TPresentadorHistorialStock.SiguienteClick(Sender: TObject);
var
  sArticulo: string;
begin
  sArticulo := FHistorial.Siguiente;
  if sArticulo <> '' then
    Navegar(sArticulo);
end;

constructor TPresentadorCoincidenciasStock.Create(
  AOwner: TComponent;
  AContenedor: TWinControl;
  AReferencia: TWinControl;
  const AAplicar: TAplicarArticuloStock;
  const AAdmiteSeleccion: TConsultaAdmisionStock);
begin
  inherited Create;
  FCoincidencias := TCoincidenciasArticuloStock.Create;
  FContenedor := AContenedor;
  FReferencia := AReferencia;
  FAplicar := AAplicar;
  FAdmiteSeleccion := AAdmiteSeleccion;
  FCombo := TcxComboBox.Create(AOwner);
  FCombo.Parent := AContenedor;
  FCombo.Visible := False;
  FCombo.Properties.DropDownListStyle := lsFixedList;
  FCombo.Properties.OnEditValueChanged := ComboEditValueChanged;
  FCombo.OnExit := ComboExit;
  FCombo.OnKeyDown := ComboKeyDown;
  FCombo.TabOrder := AReferencia.TabOrder + 1;
end;

destructor TPresentadorCoincidenciasStock.Destroy;
begin
  FAplicar := nil;
  FAdmiteSeleccion := nil;
  FreeAndNil(FCoincidencias);
  FreeAndNil(FCombo);
  inherited Destroy;
end;

function TPresentadorCoincidenciasStock.EstaVisible: Boolean;
begin
  Result := (FCombo <> nil) and FCombo.Visible;
end;

procedure TPresentadorCoincidenciasStock.Ocultar;
begin
  if FCombo <> nil then
  begin
    FCombo.DroppedDown := False;
    FCombo.Visible := False;
  end;
end;

procedure TPresentadorCoincidenciasStock.DevolverFoco;
begin
  if (FReferencia <> nil) and FReferencia.CanFocus then
    FReferencia.SetFocus;
end;

function TPresentadorCoincidenciasStock.CerrarConEscape: Boolean;
begin
  Result := EstaVisible;
  if Result then
  begin
    Ocultar;
    DevolverFoco;
  end;
end;

// Despliega bajo el buscador una fila por articulo distinto. El ancho se
// ajusta al hueco disponible y las filas visibles se topan para que el
// desplegable no invada la ventana.
procedure TPresentadorCoincidenciasStock.Mostrar(
  const ACoincidencias: TCoincidenciasEntradaStock;
  const AHint: string);
var
  i: Integer;
  iAncho: Integer;
begin
  FCoincidencias.Cargar(ACoincidencias);
  FCombo.Properties.Items.BeginUpdate;
  try
    FCombo.Properties.Items.Clear;
    for i := 0 to FCoincidencias.Cuenta - 1 do
      FCombo.Properties.Items.Add(FCoincidencias.Textos[i]);
  finally
    FCombo.Properties.Items.EndUpdate;
  end;
  if FCoincidencias.Cuenta > 0 then
  begin
    iAncho := AnchoDesplegableCoincidencias(
      FContenedor.ClientWidth - FReferencia.Left -
        MARGEN_DESPLEGABLE_COINCIDENCIAS,
      FReferencia.Width);
    FCombo.SetBounds(
      FReferencia.Left,
      FReferencia.Top + FReferencia.Height + 2,
      iAncho,
      FReferencia.Height);
    FCombo.Properties.DropDownRows := FCoincidencias.FilasDesplegable;
    FCombo.ItemIndex := -1;
    FCombo.Hint := AHint;
    FCombo.Visible := True;
    FCombo.BringToFront;
    if FCombo.CanFocus then
      FCombo.SetFocus;
    FCombo.DroppedDown := True;
  end;
end;

procedure TPresentadorCoincidenciasStock.ComboEditValueChanged(
  Sender: TObject);
var
  iSeleccion: Integer;
begin
  if (FCombo <> nil) and FAdmiteSeleccion() then
  begin
    iSeleccion := FCombo.ItemIndex;
    if FCoincidencias.EsIndiceValido(iSeleccion) then
      FAplicar(
        FCoincidencias.Codigos[iSeleccion],
        FCoincidencias.Skus[iSeleccion]);
  end;
end;

procedure TPresentadorCoincidenciasStock.ComboExit(Sender: TObject);
begin
  if FAdmiteSeleccion() then
    Ocultar;
end;

procedure TPresentadorCoincidenciasStock.ComboKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    Ocultar;
    DevolverFoco;
  end
  else if Key = VK_RETURN then
  begin
    Key := 0;
    if (FCombo.ItemIndex < 0) and (FCoincidencias.Cuenta > 0) then
      FCombo.ItemIndex := 0
    else
      ComboEditValueChanged(Sender);
  end;
end;

end.
