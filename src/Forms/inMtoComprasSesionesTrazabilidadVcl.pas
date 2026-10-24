{******************************************************************************}
{  Módulo:       inMtoComprasSesionesTrazabilidadVcl                         }
{    Tipo:       Colaborador VCL                                             }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Entrada de lotes, caducidad y series por celda de la sesión. }
{******************************************************************************}
unit inMtoComprasSesionesTrazabilidadVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB,
  cxPC, cxGrid, cxGridDBTableView, cxGridCustomTableView,
  cxCheckBox, cxLabel,
  inLibTrazabilidadAlta;

type
  TEntornoTrazabilidadSesion = record
    Lineas: TDataSource;
    RecargarCeldas: TProc;
    OtroLote: TProc;
    MarcarLotes: TProc<Boolean>;
  end;

  TFichaTrazabilidadSesion = class(TComponent)
  private
    FPagina: TcxTabSheet;
    FVista: TcxGridDBTableView;
    FDatos: TDataSource;
    FLineas: TDataSource;
    FMarcaLotes: TcxCheckBox;
    FActualizandoLotes: Boolean;
    FLineaActiva: TcxLabel;
    FRecargarCeldas: TProc;
    FMarcarLotes: TProc<Boolean>;
    FOtroLote: TProc;
    FLeerAlta: TFunc<TTrazabilidadAlta>;
    FPuedeEditar: TFunc<Boolean>;
    procedure AgregarColumna(const ACampo, ATitulo: string;
      AEditable: Boolean; AAncho: Integer);
    procedure ConfigurarColumnas;
    procedure CrearControlesLotes;
    procedure EntrarRejilla(Sender: TObject);
    procedure SalirRejilla(Sender: TObject);
    procedure OtroLote(Sender: TObject);
    procedure LotesCambiados(Sender: TObject);
    procedure DatosLineasCambiados(Sender: TObject; Field: TField);
    procedure ActualizarMarcaLotes;
    procedure AlEditar(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
  public
    constructor Crear(AOwner: TComponent; APaginas: TcxPageControl;
      ADatos: TDataSource; ALeerAlta: TFunc<TTrazabilidadAlta>;
      APuedeEditar: TFunc<Boolean>;
      const AEntorno: TEntornoTrazabilidadSesion);
    destructor Destroy; override;
    procedure ActualizarPagina;
  end;

implementation

uses
  Vcl.Controls, Vcl.Forms, inLibGridTallasInline,
  cxGridLevel, cxGridTableView, cxBlobEdit, cxCalendar,
  cxButtons, inLibTrazabilidad, inLibMsgTrazabilidad;

constructor TFichaTrazabilidadSesion.Crear(AOwner: TComponent;
  APaginas: TcxPageControl; ADatos: TDataSource;
  ALeerAlta: TFunc<TTrazabilidadAlta>; APuedeEditar: TFunc<Boolean>;
  const AEntorno: TEntornoTrazabilidadSesion);
var
  oGrid: TcxGrid;
  oNivel: TcxGridLevel;
  oAyuda: TcxLabel;
begin
  inherited Create(AOwner);
  FDatos := ADatos;
  FLineas := TDataSource.Create(Self);
  FLineas.AutoEdit := False;
  FLineas.DataSet := AEntorno.Lineas.DataSet;
  FRecargarCeldas := AEntorno.RecargarCeldas;
  FMarcarLotes := AEntorno.MarcarLotes;
  FOtroLote := AEntorno.OtroLote;
  FLeerAlta := ALeerAlta;
  FPuedeEditar := APuedeEditar;
  FPagina := TcxTabSheet.Create(Self);
  FPagina.Name := 'tsTrazabilidadSesion';
  FPagina.PageControl := APaginas;
  FPagina.Caption := SCaptionSesionLotes;
  oAyuda := TcxLabel.Create(Self);
  oAyuda.Parent := FPagina;
  oAyuda.Caption := SHintSesionLotes;
  oAyuda.Align := alTop;
  CrearControlesLotes;
  FLineas.OnDataChange := DatosLineasCambiados;
  ActualizarMarcaLotes;
  oGrid := TcxGrid.Create(Self);
  oGrid.Parent := FPagina;
  oGrid.Align := alClient;
  oGrid.OnEnter := EntrarRejilla;
  oGrid.OnExit := SalirRejilla;
  FVista := oGrid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  FVista.DataController.DataSource := ADatos;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsData.Inserting := False;
  FVista.OptionsData.Deleting := False;
  FVista.OnEditing := AlEditar;
  oNivel := oGrid.Levels.Add;
  oNivel.GridView := FVista;
  ConfigurarColumnas;
end;

procedure TFichaTrazabilidadSesion.CrearControlesLotes;
var
  oOtroLote: TcxButton;
begin
  FLineaActiva := TcxLabel.Create(Self);
  FLineaActiva.Parent := FPagina;
  FLineaActiva.Align := alTop;
  // El cambio se persiste mediante MarcarLotes. Un editor DB iniciaria
  // otra edicion mientras esa operacion refresca el mismo dataset.
  FMarcaLotes := TcxCheckBox.Create(Self);
  FMarcaLotes.Parent := FPagina;
  FMarcaLotes.Align := alTop;
  FMarcaLotes.Caption := SCaptionSesionArticuloPorLotes;
  FMarcaLotes.Properties.ValueChecked := 'S';
  FMarcaLotes.Properties.ValueUnchecked := 'N';
  FMarcaLotes.OnClick := LotesCambiados;
  oOtroLote := TcxButton.Create(Self);
  oOtroLote.Parent := FPagina;
  oOtroLote.Align := alTop;
  oOtroLote.Caption := SCaptionSesionOtroLote;
  oOtroLote.OnClick := OtroLote;
end;

destructor TFichaTrazabilidadSesion.Destroy;
begin
  FLineas.OnDataChange := nil;
  FLeerAlta := nil;
  FPuedeEditar := nil;
  FRecargarCeldas := nil;
  FMarcarLotes := nil;
  FOtroLote := nil;
  inherited;
end;

procedure TFichaTrazabilidadSesion.AgregarColumna(
  const ACampo, ATitulo: string; AEditable: Boolean; AAncho: Integer);
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := FVista.CreateColumn;
  oColumna.DataBinding.FieldName := ACampo;
  oColumna.Caption := ATitulo;
  oColumna.Options.Editing := AEditable;
  oColumna.Width := AAncho;
  if ACampo = 'SERIES_SESCEL' then
  begin
    // El editor emergente conserva Enter dentro del texto y evita que
    // la navegacion del mantenimiento acepte la edicion de la sesion.
    oColumna.PropertiesClass := TcxBlobEditProperties;
    TcxBlobEditProperties(oColumna.Properties).BlobEditKind := bekMemo;
    TcxBlobEditProperties(oColumna.Properties).BlobPaintStyle := bpsText;
    TcxBlobEditProperties(oColumna.Properties).MemoWantReturns := True;
    TcxBlobEditProperties(oColumna.Properties).MemoWantTabs := False;
    TcxBlobEditProperties(oColumna.Properties).MemoWordWrap := False;
    TcxBlobEditProperties(oColumna.Properties).PopupWidth := 360;
    TcxBlobEditProperties(oColumna.Properties).PopupHeight := 200;
  end
  else if ACampo = 'CADUCIDAD_SESCEL' then
    oColumna.PropertiesClass := TcxDateEditProperties;
end;

procedure TFichaTrazabilidadSesion.EntrarRejilla(Sender: TObject);
begin
  if Owner is TForm then
    ActivarEnterComoTab(TForm(Owner), False);
end;

// Volcar tambien el texto que sigue dentro del editor activo: Post del
// dataset por si solo no lo recibe antes de cambiar de pestaña o copiar.
procedure TFichaTrazabilidadSesion.SalirRejilla(Sender: TObject);
begin
  FVista.DataController.PostEditingData;
  if Assigned(FDatos.DataSet) and FDatos.DataSet.Active then
    FDatos.DataSet.CheckBrowseMode;
end;

procedure TFichaTrazabilidadSesion.ConfigurarColumnas;
begin
  AgregarColumna('ALMACEN_DESTINO', SCaptionSesionAlmacen, False, 110);
  AgregarColumna('VALOR_TALLA', SCaptionSesionTalla, False, 95);
  AgregarColumna('VALOR_FILA', SCaptionSesionFila, False, 100);
  AgregarColumna('CANTIDAD_SESCEL', SCaptionColumnaCantidadLote, False, 80);
  AgregarColumna('LOTE_SESCEL', SCaptionColumnaLote, True, 140);
  AgregarColumna('CADUCIDAD_SESCEL', SCaptionColumnaCaducidad, True, 110);
  AgregarColumna('SERIES_SESCEL', SCaptionSesionSeries, True, 220);
end;

procedure TFichaTrazabilidadSesion.ActualizarPagina;
begin
  if FPagina.PageControl.ActivePage = FPagina then
  begin
    FRecargarCeldas();
    ActualizarMarcaLotes;
    if FLineas.DataSet.Active and not FLineas.DataSet.IsEmpty then
      FLineaActiva.Caption := Format(SCaptionSesionLineaLotes,
        [FLineas.DataSet.FieldByName('LINEA_SESLIN').AsInteger,
         FLineas.DataSet.FieldByName('DESCRIPCION_SESLIN').AsString,
         FLineas.DataSet.FieldByName('COLOR_TEXTO_SESLIN').AsString])
    else
      FLineaActiva.Caption := '';
  end;
end;

procedure TFichaTrazabilidadSesion.OtroLote(Sender: TObject);
begin
  if FPuedeEditar() then
  begin
    SalirRejilla(Sender);
    FOtroLote();
  end;
end;

procedure TFichaTrazabilidadSesion.LotesCambiados(Sender: TObject);
begin
  if not FActualizandoLotes and FMarcaLotes.Enabled and
    FPuedeEditar() then
  begin
    FActualizandoLotes := True;
    try
      FMarcarLotes(FMarcaLotes.Checked);
    finally
      FActualizandoLotes := False;
      ActualizarMarcaLotes;
    end;
  end;
end;

procedure TFichaTrazabilidadSesion.DatosLineasCambiados(
  Sender: TObject; Field: TField);
begin
  ActualizarMarcaLotes;
end;

procedure TFichaTrazabilidadSesion.ActualizarMarcaLotes;
var
  bHayLinea: Boolean;
begin
  if not FActualizandoLotes then
  begin
    FActualizandoLotes := True;
    try
      bHayLinea := Assigned(FLineas.DataSet) and
        FLineas.DataSet.Active and not FLineas.DataSet.IsEmpty;
      FMarcaLotes.Enabled := bHayLinea and FPuedeEditar() and
        not SameText(FLineas.DataSet.FieldByName(
          'ACCION_DUPLICADO_SESLIN').AsString, 'REUSAR');
      FMarcaLotes.Checked := bHayLinea and
        SameText(FLineas.DataSet.FieldByName(
          'ESTRAZABLE_SESLIN').AsString, 'S');
    finally
      FActualizandoLotes := False;
    end;
  end;
end;

procedure TFichaTrazabilidadSesion.AlEditar(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
var
  rAlta: TTrazabilidadAlta;
  sCampo: string;
begin
  AAllow := AAllow and FPuedeEditar();
  rAlta := FLeerAlta();
  sCampo := TcxGridDBColumn(AItem).DataBinding.FieldName;
  if sCampo = 'LOTE_SESCEL' then
    AAllow := AAllow and (rAlta.Modo = mtLote)
  else if sCampo = 'CADUCIDAD_SESCEL' then
    AAllow := AAllow and (rAlta.Modo = mtLote)
  else if sCampo = 'SERIES_SESCEL' then
    AAllow := AAllow and (rAlta.Modo = mtSerie);
end;

end.
