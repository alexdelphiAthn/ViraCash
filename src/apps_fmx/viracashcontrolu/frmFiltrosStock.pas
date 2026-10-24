unit frmFiltrosStock;

{
  Selector movil de colores y almacenes para la consulta de stock.
  Replica la seleccion multiple de la pantalla Ctrl+U de escritorio.
}

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ListBox, FMX.TabControl;

type
  TFiltrosStockAplicadosEvent = procedure(
    const AColores, AAlmacenes: TArray<string>) of object;

  TFormFiltrosStock = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    tabFiltros: TTabControl;
    tabColores: TTabItem;
    tabAlmacenes: TTabItem;
    lstColores: TListBox;
    lstAlmacenes: TListBox;
    pnlBotones: TPanel;
    btnTodos: TButton;
    btnNinguno: TButton;
    btnCancelar: TButton;
    btnAplicar: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);
    procedure btnTodosClick(Sender: TObject);
    procedure btnNingunoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
  private
    FOnFiltrosAplicados: TFiltrosStockAplicadosEvent;
    procedure ActualizarDisposicion;
    procedure CargarLista(
      ALista: TListBox;
      const AValores, AActivos: TArray<string>);
    function LeerMarcados(ALista: TListBox): TArray<string>;
    procedure MarcarLista(ALista: TListBox; AMarcado: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Preparar(
      const AColores, AColoresActivos: TArray<string>;
      const AAlmacenes, AAlmacenesActivos: TArray<string>);
    property OnFiltrosAplicados: TFiltrosStockAplicadosEvent
      read FOnFiltrosAplicados write FOnFiltrosAplicados;
  end;

var
  FormFiltrosStock: TFormFiltrosStock;

implementation

{$R *.fmx}

uses
  TraduccionMovil;

constructor TFormFiltrosStock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TraducirFormulario(Self);
end;

function ContieneTexto(
  const AValores: TArray<string>;
  const AValor: string): Boolean;
var
  Valor: string;
begin
  Result := False;
  for Valor in AValores do
  begin
    if SameText(Valor, AValor) then
      Result := True;
  end;
end;

procedure TFormFiltrosStock.CargarLista(
  ALista: TListBox;
  const AValores, AActivos: TArray<string>);
var
  Item: TListBoxItem;
  Valor: string;
begin
  ALista.BeginUpdate;
  try
    ALista.Clear;
    for Valor in AValores do
    begin
      Item := TListBoxItem.Create(ALista);
      Item.Parent := ALista;
      Item.Text := Valor;
      Item.IsChecked := ContieneTexto(AActivos, Valor);
    end;
  finally
    ALista.EndUpdate;
  end;
end;

function TFormFiltrosStock.LeerMarcados(
  ALista: TListBox): TArray<string>;
var
  i: Integer;
  NumeroMarcados: Integer;
begin
  SetLength(Result, 0);
  NumeroMarcados := 0;
  for i := 0 to ALista.Count - 1 do
  begin
    if ALista.ItemByIndex(i).IsChecked then
    begin
      SetLength(Result, NumeroMarcados + 1);
      Result[NumeroMarcados] := ALista.ItemByIndex(i).Text;
      Inc(NumeroMarcados);
    end;
  end;
end;

procedure TFormFiltrosStock.MarcarLista(
  ALista: TListBox;
  AMarcado: Boolean);
var
  i: Integer;
begin
  for i := 0 to ALista.Count - 1 do
    ALista.ItemByIndex(i).IsChecked := AMarcado;
end;

procedure TFormFiltrosStock.Preparar(
  const AColores, AColoresActivos: TArray<string>;
  const AAlmacenes, AAlmacenesActivos: TArray<string>);
begin
  CargarLista(lstColores, AColores, AColoresActivos);
  CargarLista(lstAlmacenes, AAlmacenes, AAlmacenesActivos);
  tabFiltros.ActiveTab := tabColores;
  ActualizarDisposicion;
end;

procedure TFormFiltrosStock.ActualizarDisposicion;
const
  MARGEN = 4;
var
  AnchoBoton: Single;
begin
  AnchoBoton := (pnlBotones.Width - MARGEN * 5) / 4;

  btnTodos.Position.X := MARGEN;
  btnTodos.Width := AnchoBoton;
  btnNinguno.Position.X := btnTodos.Position.X + AnchoBoton + MARGEN;
  btnNinguno.Width := AnchoBoton;
  btnCancelar.Position.X := btnNinguno.Position.X + AnchoBoton + MARGEN;
  btnCancelar.Width := AnchoBoton;
  btnAplicar.Position.X := btnCancelar.Position.X + AnchoBoton + MARGEN;
  btnAplicar.Width := AnchoBoton;
end;

procedure TFormFiltrosStock.FormResize(Sender: TObject);
begin
  ActualizarDisposicion;
end;

procedure TFormFiltrosStock.btnTodosClick(Sender: TObject);
begin
  if tabFiltros.ActiveTab = tabAlmacenes then
    MarcarLista(lstAlmacenes, True)
  else
    MarcarLista(lstColores, True);
end;

procedure TFormFiltrosStock.btnNingunoClick(Sender: TObject);
begin
  if tabFiltros.ActiveTab = tabAlmacenes then
    MarcarLista(lstAlmacenes, False)
  else
    MarcarLista(lstColores, False);
end;

procedure TFormFiltrosStock.btnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TFormFiltrosStock.btnAplicarClick(Sender: TObject);
var
  Almacenes: TArray<string>;
  Colores: TArray<string>;
begin
  Colores := LeerMarcados(lstColores);
  Almacenes := LeerMarcados(lstAlmacenes);
  if Assigned(FOnFiltrosAplicados) then
    FOnFiltrosAplicados(Colores, Almacenes);
  Close;
end;

procedure TFormFiltrosStock.FormClose(
  Sender: TObject;
  var Action: TCloseAction);
begin
  Action := TCloseAction.caHide;
end;

end.
