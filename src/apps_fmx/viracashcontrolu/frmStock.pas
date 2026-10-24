unit frmStock;

{
  Pantalla principal: consulta movil de stock de ViraCash.

  Funcionalidades:
  - Buscar stock por codigo de articulo (manual o por escaner de camara)
  - Mostrar resultados en TStringGrid con tallas como columnas
  - Tres modos de agrupacion (rotativo con un boton):
      1. Por Color    -> filas = colores, columnas = tallas
      2. Por Almacen  -> filas = almacenes, columnas = tallas
      3. Detalle      -> filas = "Color . Almacen", columnas = tallas
  - Adapta tamano de fila/fuente a movil
  - Recalcula ancho de columnas al redimensionar (rotar pantalla, etc.)
  - Boton para abrir el escaner de codigos de barras EAN-8 y EAN-13
  - Foto representativa del articulo, con lado mayor de 300 px, en la
    esquina superior derecha
}

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  System.Generics.Defaults,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.StdCtrls, FMX.Edit,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid, FMX.Grid.Style,
  FMX.ScrollBox, FMX.TextLayout, FMX.Objects, FMX.Graphics, FMX.Platform,
  FMX.ListBox, System.Math, System.UITypes, uApiClient, uSettings,
  System.Rtti;

type
  TAgrupacion = (agColor, agAlmacen);

  TColumnaCantidad = class(TStringColumn)
  private
    FColorTexto: TAlphaColor;
  public
    procedure DefaultDrawCell(
      const Canvas: TCanvas;
      const Bounds: TRectF;
      const Row: Integer;
      const Value: TValue;
      const State: TGridDrawStates); override;
    property ColorTexto: TAlphaColor read FColorTexto write FColorTexto;
  end;

  TFormStock = class(TForm)
    pnlTop: TPanel;
    edtArticulo: TEdit;
    btnEscanear: TButton;
    btnConsultar: TButton;
    btnAgrupar: TButton;
    btnFiltros: TButton;
    btnAnterior: TButton;
    btnSiguiente: TButton;
    btnSalir: TButton;
    pnlBottom: TPanel;
    sbTotal: TVertScrollBox;
    lblTotal: TLabel;
    grdStock: TStringGrid;
    pnlArticulo: TPanel;
    pnlFoto: TPanel;
    imgFoto: TImage;
    lblFoto: TLabel;
    sbArticulo: TVertScrollBox;
    lblArticulo: TLabel;
    pnlEstado: TPanel;
    lblEstado: TLabel;
    cboEstado: TComboBox;
    rctEstado: TRectangle;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnConsultarClick(Sender: TObject);
    procedure btnAgruparClick(Sender: TObject);
    procedure btnFiltrosClick(Sender: TObject);
    procedure btnAnteriorClick(Sender: TObject);
    procedure btnSiguienteClick(Sender: TObject);
    procedure btnSalirClick(Sender: TObject);
    procedure btnEscanearClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure grdStockCellClick(const Column: TColumn; const Row: Integer);
    procedure grdStockDrawColumnCell(
      Sender: TObject;
      const Canvas: TCanvas;
      const Column: TColumn;
      const Bounds: TRectF;
      const Row: Integer;
      const Value: TValue;
      const State: TGridDrawStates);
    procedure cboEstadoChange(Sender: TObject);
  private
    FUltimo: TStockResultado;
    FTieneDatos: Boolean;
    FAgrupacion: TAgrupacion;
    FDisposicionHorizontal: Boolean;
    FDisposicionInicializada: Boolean;
    FNumColumnasTallas: Integer;
    FExpandidos: TList<string>;
    FColoresDisponibles: TList<string>;
    FColoresActivos: TList<string>;
    FAlmacenesDisponibles: TList<string>;
    FAlmacenesActivos: TList<string>;
    FHistorico: TList<string>;
    FIndiceHistorico: Integer;
    FEstado: TEstadoConsultaStock;
    FActualizandoEstado: Boolean;
    FCodigoConsultaActual: string;
    FArticuloFiltros: string;
    procedure RellenarGrid;
    procedure ActualizarTextoBotonAgrupar;
    procedure ActualizarDisposicion;
    procedure ActualizarAreaTexto(
      Area: TVertScrollBox;
      VolverAlInicio: Boolean);
    procedure ActualizarBotonesHistorico;
    procedure ActualizarCabeceraArticulo;
    procedure ActualizarResumen;
    procedure AplicarColorEstado;
    procedure AjustarAnchoColumnas;
    procedure ConsultarCodigo(
      const Codigo: string;
      RegistrarHistorico: Boolean);
    procedure PrepararFiltros;
    procedure EstablecerTextoArticulo(const Texto: string);
    procedure EstablecerTextoResumen(const Texto: string);
    procedure ReajustarAreasTexto;
    procedure RegistrarConsultaHistorico(const Articulo: string);
    function ItemVisible(const Item: TStockItem): Boolean;
    function TotalAlmacenesActivos: Double;
    function TotalUnidadConsultadaActiva: Double;
    function TotalVisible: Double;
    function ColorEstado: TAlphaColor;
    function IntentarColorEtiqueta(
      const Etiqueta: string;
      out Color: TAlphaColor): Boolean;
    function ListaComoArray(ALista: TList<string>): TArray<string>;
    procedure LimpiarFoto;
    procedure CargarFoto300(const Stock: TStockResultado);
    procedure OnFiltrosAplicados(
      const Colores, Almacenes: TArray<string>);
    /// Callback que recibe el codigo desde el formulario de escaneo
    procedure OnCodigoEscaneado(const Codigo: string);
    procedure OnEscanerOcultado;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  FormStock: TFormStock;

implementation

{$R *.fmx}

uses
  frmLogin,
  frmEscaner,
  frmFiltrosStock,
  TraduccionMovil,
  TextosControlU;

const
  LADO_MAXIMO_FOTO = 300;
  MAXIMO_HISTORICO = 30;

constructor TFormStock.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TraducirFormulario(Self);
end;

procedure TColumnaCantidad.DefaultDrawCell(
  const Canvas: TCanvas;
  const Bounds: TRectF;
  const Row: Integer;
  const Value: TValue;
  const State: TGridDrawStates);
var
  ColorAnterior: TAlphaColor;
begin
  ColorAnterior := Layout.Color;
  try
    Layout.Color := FColorTexto;
    inherited DefaultDrawCell(Canvas, Bounds, Row, Value, State);
  finally
    Layout.Color := ColorAnterior;
  end;
end;

function ContieneTexto(
  const Valores: TArray<string>;
  const Valor: string): Boolean;
var
  Candidato: string;
begin
  Result := False;
  for Candidato in Valores do
  begin
    if SameText(Candidato, Valor) then
      Result := True;
  end;
end;

function TFormStock.ColorEstado: TAlphaColor;
begin
  case FEstado of
    ecEntradas:
      Result := TAlphaColorRec.Green;
    ecVentas:
      Result := TAlphaColorRec.Red;
    ecPendienteRecibir:
      Result := TAlphaColor($FFFF8000);
  else
    Result := TAlphaColorRec.Navy;
  end;
end;

procedure TFormStock.AplicarColorEstado;
var
  i: Integer;
begin
  rctEstado.Fill.Color := ColorEstado;
  rctEstado.Stroke.Color := TAlphaColorRec.Gray;
  for i := 0 to grdStock.ColumnCount - 1 do
  begin
    if grdStock.Columns[i] is TColumnaCantidad then
      TColumnaCantidad(grdStock.Columns[i]).ColorTexto := ColorEstado;
  end;
  grdStock.Repaint;
end;

procedure TFormStock.cboEstadoChange(Sender: TObject);
begin
  if not FActualizandoEstado and
     (cboEstado.ItemIndex >= Ord(Low(TEstadoConsultaStock))) and
     (cboEstado.ItemIndex <= Ord(High(TEstadoConsultaStock))) then
  begin
    FEstado := TEstadoConsultaStock(cboEstado.ItemIndex);
    AplicarColorEstado;
    if FCodigoConsultaActual <> '' then
      ConsultarCodigo(FCodigoConsultaActual, False);
  end;
end;

function TFormStock.IntentarColorEtiqueta(
  const Etiqueta: string;
  out Color: TAlphaColor): Boolean;
var
  Nombre: string;
begin
  Nombre := Trim(Etiqueta);
  if (FAgrupacion = agColor) and
     (Nombre.StartsWith('▶ ') or Nombre.StartsWith('▼ ')) then
    Nombre := Trim(Nombre.Substring(2))
  else if (FAgrupacion = agAlmacen) and Nombre.Contains('↳ ') then
    Nombre := Trim(Nombre.Substring(Nombre.IndexOf('↳ ') + 2))
  else
    Nombre := '';

  Nombre := UpperCase(Nombre);
  if Nombre.Contains('AZUL MARINO') then
    Color := TAlphaColorRec.Navy
  else if Nombre.Contains('AZUL') then
    Color := TAlphaColorRec.Blue
  else if Nombre.Contains('ROJO') then
    Color := TAlphaColorRec.Red
  else if Nombre.Contains('VERDE') then
    Color := TAlphaColorRec.Green
  else if Nombre.Contains('AMARILLO') then
    Color := TAlphaColorRec.Gold
  else if Nombre.Contains('NARANJA') then
    Color := TAlphaColorRec.Orange
  else if Nombre.Contains('NEGRO') then
    Color := TAlphaColorRec.Black
  else if Nombre.Contains('BLANCO') then
    Color := TAlphaColorRec.White
  else if Nombre.Contains('GRIS') then
    Color := TAlphaColorRec.Gray
  else if Nombre.Contains('MARRON') or Nombre.Contains('MARRÓN') then
    Color := TAlphaColorRec.Brown
  else if Nombre.Contains('BURDEOS') then
    Color := TAlphaColorRec.Maroon
  else if Nombre.Contains('MORADO') or Nombre.Contains('VIOLETA') then
    Color := TAlphaColorRec.Purple
  else if Nombre.Contains('ROSA') then
    Color := TAlphaColorRec.Hotpink
  else if Nombre.Contains('TURQUESA') then
    Color := TAlphaColorRec.Turquoise
  else if Nombre.Contains('CELESTE') then
    Color := TAlphaColorRec.Lightblue
  else if Nombre.Contains('BEIGE') then
    Color := TAlphaColorRec.Beige
  else if Nombre.Contains('CAMEL') then
    Color := TAlphaColorRec.Tan
  else if Nombre.Contains('DORADO') then
    Color := TAlphaColorRec.Goldenrod
  else if Nombre.Contains('PLATA') then
    Color := TAlphaColorRec.Silver
  else
    Color := TAlphaColorRec.Null;
  Result := Color <> TAlphaColorRec.Null;
end;

procedure TFormStock.grdStockDrawColumnCell(
  Sender: TObject;
  const Canvas: TCanvas;
  const Column: TColumn;
  const Bounds: TRectF;
  const Row: Integer;
  const Value: TValue;
  const State: TGridDrawStates);
var
  Color: TAlphaColor;
  EstadoCanvas: TCanvasSaveState;
  Indicador: TRectF;
  Lado: Single;
begin
  if (Column.Index = 0) and
     IntentarColorEtiqueta(Column.ValueToString(Value), Color) then
  begin
    Lado := Min(14, Bounds.Height - 8);
    Indicador := TRectF.Create(
      Bounds.Left - 20,
      Bounds.CenterPoint.Y - Lado / 2,
      Bounds.Left - 20 + Lado,
      Bounds.CenterPoint.Y + Lado / 2);
    EstadoCanvas := Canvas.SaveState;
    try
      Canvas.Fill.Kind := TBrushKind.Solid;
      Canvas.Fill.Color := Color;
      Canvas.FillRect(Indicador, 2, 2, AllCorners, 1);
      Canvas.Stroke.Kind := TBrushKind.Solid;
      Canvas.Stroke.Color := TAlphaColorRec.Gray;
      Canvas.Stroke.Thickness := 1;
      Canvas.DrawRect(Indicador, 2, 2, AllCorners, 1);
    finally
      Canvas.RestoreState(EstadoCanvas);
    end;
  end;
end;

procedure TFormStock.ActualizarAreaTexto(
  Area: TVertScrollBox;
  VolverAlInicio: Boolean);
begin
  Area.RealignContent;
  if VolverAlInicio then
    Area.ViewportPosition := TPointF.Create(0, 0)
  else
    Area.ViewportPosition := TPointF.Create(
      0,
      Area.ViewportPosition.Y);
end;

procedure TFormStock.EstablecerTextoArticulo(const Texto: string);
begin
  lblArticulo.Text := Texto;
  ActualizarAreaTexto(sbArticulo, True);
end;

procedure TFormStock.EstablecerTextoResumen(const Texto: string);
begin
  lblTotal.Text := Texto;
  ActualizarAreaTexto(sbTotal, True);
end;

procedure TFormStock.ReajustarAreasTexto;
begin
  Realign;
  ActualizarAreaTexto(sbArticulo, False);
  ActualizarAreaTexto(sbTotal, False);
end;

procedure TFormStock.FormShow(Sender: TObject);
begin
  if FExpandidos = nil then
    FExpandidos := TList<string>.Create;
  if FColoresDisponibles = nil then
    FColoresDisponibles := TList<string>.Create;
  if FColoresActivos = nil then
    FColoresActivos := TList<string>.Create;
  if FAlmacenesDisponibles = nil then
    FAlmacenesDisponibles := TList<string>.Create;
  if FAlmacenesActivos = nil then
    FAlmacenesActivos := TList<string>.Create;
  if FHistorico = nil then
    FHistorico := TList<string>.Create;
  FExpandidos.Clear;
  FColoresDisponibles.Clear;
  FColoresActivos.Clear;
  FAlmacenesDisponibles.Clear;
  FAlmacenesActivos.Clear;
  FHistorico.Clear;
  FIndiceHistorico := -1;
  FActualizandoEstado := True;
  FEstado := ecStock;
  cboEstado.ItemIndex := Ord(FEstado);
  FActualizandoEstado := False;
  FCodigoConsultaActual := '';
  FArticuloFiltros := '';
  FAgrupacion := agColor;
  FTieneDatos := False;
  FDisposicionInicializada := False;
  FNumColumnasTallas := 0;
  FUltimo := Default(TStockResultado);
  grdStock.RowCount := 0;
  grdStock.ClearColumns;
  grdStock.Options := grdStock.Options -
    [TGridOption.ColumnResize, TGridOption.ColumnMove];
  grdStock.ScrollTo(0, 0, False);
  ActualizarTextoBotonAgrupar;
  AplicarColorEstado;
  ActualizarBotonesHistorico;
  ActualizarDisposicion;
  LimpiarFoto;
  EstablecerTextoArticulo(Tr('Introduce o escanea un artículo.'));
  EstablecerTextoResumen('');
end;

procedure TFormStock.grdStockCellClick(
  const Column: TColumn;
  const Row: Integer);
var
  TextoCelda, ClavePadre: string;
begin
  if (Column.Index = 0) and (Row < grdStock.RowCount - 1) then
  begin
    TextoCelda := grdStock.Cells[0, Row];
    if TextoCelda.StartsWith('▶ ') or TextoCelda.StartsWith('▼ ') then
    begin
      ClavePadre := TextoCelda.Substring(2);
      if FExpandidos.Contains(ClavePadre) then
        FExpandidos.Remove(ClavePadre) // Si estaba abierto, lo cerramos
      else
        FExpandidos.Add(ClavePadre);   // Si estaba cerrado, lo abrimos
      RellenarGrid;
    end;
  end;
end;

procedure TFormStock.ActualizarDisposicion;
var
  AltoBoton: Single;
  AnchoBoton: Single;
  AnchoEdicion: Single;
  AnchoFiltro: Single;
  EsHorizontal: Boolean;
  Margen: Single;
  Separacion: Single;
  {$IFDEF ANDROID}
  ServicioPantalla: IFMXScreenService;
  {$ENDIF}
begin
  // La geometria real evita estrechar el grid en multiventana o DeX.
  EsHorizontal := ClientWidth > ClientHeight * 1.25;
  {$IFDEF ANDROID}
  if TPlatformServices.Current.SupportsPlatformService(
     IFMXScreenService, ServicioPantalla) then
    EsHorizontal := EsHorizontal and
      (ServicioPantalla.GetScreenOrientation in
        [TScreenOrientation.Landscape,
         TScreenOrientation.InvertedLandscape]);
  {$ENDIF}

  {$IFDEF ANDROID}
  if EsHorizontal then
  begin
    pnlTop.Height := 48;
    pnlBottom.Height := 40;
    pnlEstado.Height := 70;
    grdStock.RowHeight := 44;
    grdStock.TextSettings.Font.Size := 14;
    edtArticulo.TextSettings.Font.Size := 14;
    lblTotal.TextSettings.Font.Size := 13;
    lblArticulo.TextSettings.Font.Size := 13;
    lblEstado.TextSettings.Font.Size := 11;
    AltoBoton := 40;
  end
  else
  begin
    pnlTop.Height := 72;
    pnlBottom.Height := 56;
    pnlEstado.Height := 42;
    grdStock.RowHeight := 56;
    grdStock.TextSettings.Font.Size := 16;
    edtArticulo.TextSettings.Font.Size := 16;
    lblTotal.TextSettings.Font.Size := 16;
    lblArticulo.TextSettings.Font.Size := 15;
    lblEstado.TextSettings.Font.Size := 13;
    AltoBoton := 44;
  end;
  {$ELSE}
  grdStock.RowHeight := 28;
  grdStock.TextSettings.Font.Size := 12;
  pnlTop.Height := 56;
  pnlBottom.Height := 40;
  pnlEstado.Height := 42;
  edtArticulo.TextSettings.Font.Size := 14;
  lblTotal.TextSettings.Font.Size := 14;
  lblArticulo.TextSettings.Font.Size := 15;
  lblEstado.TextSettings.Font.Size := 12;
  AltoBoton := 36;
  {$ENDIF}

  if (not FDisposicionInicializada) or
     (EsHorizontal <> FDisposicionHorizontal) then
  begin
    pnlArticulo.Align := TAlignLayout.None;
    pnlFoto.Align := TAlignLayout.None;

    if EsHorizontal then
    begin
      pnlArticulo.Width := EnsureRange(ClientWidth * 0.28, 176, 220);
      pnlArticulo.Align := TAlignLayout.Right;
      pnlFoto.Height := 112;
      pnlFoto.Align := TAlignLayout.Top;
    end
    else
    begin
      {$IFDEF ANDROID}
      pnlArticulo.Height := 124;
      pnlFoto.Width := 120;
      {$ELSE}
      pnlArticulo.Height := 112;
      pnlFoto.Width := 108;
      {$ENDIF}
      pnlArticulo.Align := TAlignLayout.Top;
      pnlFoto.Align := TAlignLayout.Right;
    end;
    FDisposicionHorizontal := EsHorizontal;
    FDisposicionInicializada := True;
  end;

  if EsHorizontal then
    pnlArticulo.Width := EnsureRange(ClientWidth * 0.28, 176, 220);
  if EsHorizontal then
  begin
    lblEstado.Position.X := 8;
    lblEstado.Position.Y := 2;
    lblEstado.Width := Max(40, pnlEstado.Width - 16);
    lblEstado.Height := 20;
    cboEstado.Position.X := 8;
    cboEstado.Position.Y := 25;
    cboEstado.Width := Max(90, pnlEstado.Width - 42);
    cboEstado.Height := 38;
    rctEstado.Position.X := pnlEstado.Width - 28;
    rctEstado.Position.Y := 35;
  end
  else
  begin
    lblEstado.Position.X := 6;
    lblEstado.Position.Y := 1;
    lblEstado.Width := 50;
    lblEstado.Height := 40;
    cboEstado.Position.X := 58;
    cboEstado.Position.Y := 2;
    cboEstado.Width := Max(90, pnlEstado.Width - 88);
    cboEstado.Height := 38;
    rctEstado.Position.X := pnlEstado.Width - 26;
    rctEstado.Position.Y := 13;
  end;
  rctEstado.Width := 16;
  rctEstado.Height := 16;
  grdStock.ScrollDirections := FMX.ScrollBox.TScrollDirections.Both;

  Margen := 8;
  Separacion := 4;
  AnchoFiltro := 56;
  AnchoBoton := EnsureRange(
    (pnlTop.Width - Margen * 2 - Separacion * 4 -
      AnchoFiltro - 80) / 3,
    32,
    44);
  AnchoEdicion := pnlTop.Width - Margen * 2 - AnchoBoton * 3 -
    AnchoFiltro - Separacion * 4;
  AnchoEdicion := Max(36, AnchoEdicion);

  edtArticulo.Position.X := Margen;
  edtArticulo.Position.Y := (pnlTop.Height - AltoBoton) / 2;
  edtArticulo.Width := AnchoEdicion;
  edtArticulo.Height := AltoBoton;

  btnEscanear.Position.X := edtArticulo.Position.X + AnchoEdicion +
    Separacion;
  btnEscanear.Position.Y := edtArticulo.Position.Y;
  btnEscanear.Width := AnchoBoton;
  btnEscanear.Height := AltoBoton;

  btnConsultar.Position.X := btnEscanear.Position.X + AnchoBoton +
    Separacion;
  btnConsultar.Position.Y := edtArticulo.Position.Y;
  btnConsultar.Width := AnchoBoton;
  btnConsultar.Height := AltoBoton;

  btnAgrupar.Position.X := btnConsultar.Position.X + AnchoBoton +
    Separacion;
  btnAgrupar.Position.Y := edtArticulo.Position.Y;
  btnAgrupar.Width := AnchoBoton;
  btnAgrupar.Height := AltoBoton;

  btnFiltros.Position.X := btnAgrupar.Position.X + AnchoBoton +
    Separacion;
  btnFiltros.Position.Y := edtArticulo.Position.Y;
  btnFiltros.Width := AnchoFiltro;
  btnFiltros.Height := AltoBoton;

  btnAnterior.Position.X := 2;
  btnAnterior.Position.Y := 4;
  btnAnterior.Width := 44;
  btnAnterior.Height := Max(32, pnlBottom.Height - 8);
  btnSiguiente.Position.X := 50;
  btnSiguiente.Position.Y := 4;
  btnSiguiente.Width := 44;
  btnSiguiente.Height := Max(32, pnlBottom.Height - 8);

  btnSalir.Position.X := Max(98, pnlBottom.Width - 58);
  btnSalir.Position.Y := 4;
  btnSalir.Width := 56;
  btnSalir.Height := Max(32, pnlBottom.Height - 8);
  ReajustarAreasTexto;
end;

procedure TFormStock.LimpiarFoto;
begin
  imgFoto.Bitmap.SetSize(1, 1);
  imgFoto.Bitmap.Clear(0);
  lblFoto.Text := Tr('Sin foto'#13#10'300 px');
  lblFoto.Visible := True;
end;

procedure TFormStock.CargarFoto300(const Stock: TStockResultado);
var
  Alto, Ancho: Integer;
  Bytes: TBytes;
  Miniatura: TBitmap;
  Stream: TBytesStream;
begin
  LimpiarFoto;
  Bytes := TApiClient.DescargarFoto300(Stock);
  if Length(Bytes) = 0 then
    Exit;

  Stream := TBytesStream.Create(Bytes);
  try
    try
      imgFoto.Bitmap.LoadFromStream(Stream);
      if Max(imgFoto.Bitmap.Width, imgFoto.Bitmap.Height) >
         LADO_MAXIMO_FOTO then
      begin
        if imgFoto.Bitmap.Width >= imgFoto.Bitmap.Height then
        begin
          Ancho := LADO_MAXIMO_FOTO;
          Alto := Max(1, Round(imgFoto.Bitmap.Height * LADO_MAXIMO_FOTO /
            imgFoto.Bitmap.Width));
        end
        else
        begin
          Alto := LADO_MAXIMO_FOTO;
          Ancho := Max(1, Round(imgFoto.Bitmap.Width * LADO_MAXIMO_FOTO /
            imgFoto.Bitmap.Height));
        end;
        Miniatura := imgFoto.Bitmap.CreateThumbnail(Ancho, Alto);
        try
          imgFoto.Bitmap.Assign(Miniatura);
        finally
          Miniatura.Free;
        end;
      end;
      lblFoto.Visible := False;
    except
      LimpiarFoto;
      lblFoto.Text := Tr('Foto no válida');
    end;
  finally
    Stream.Free;
  end;
end;

procedure TFormStock.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FHistorico);
  FreeAndNil(FAlmacenesActivos);
  FreeAndNil(FAlmacenesDisponibles);
  FreeAndNil(FColoresActivos);
  FreeAndNil(FColoresDisponibles);
  FreeAndNil(FExpandidos);
end;

procedure TFormStock.FormResize(Sender: TObject);
begin
  ActualizarDisposicion;
  if FTieneDatos then
    AjustarAnchoColumnas;
end;

procedure TFormStock.AjustarAnchoColumnas;
var
  Layout: TTextLayout;
  i, Fila: Integer;
  AnchoCol0, AnchoTotal, AnchoDisponible, Incremento: Single;
  SumaAnchos: Single;
  AnchosTallas: array of Single;
  MargenCelda: Single;
begin
  if grdStock.ColumnCount = 0 then Exit;
  if grdStock.ColumnCount < FNumColumnasTallas + 2 then
  begin
    grdStock.Columns[0].Width := Max(150, grdStock.Width - 20);
    Exit;
  end;

  // Margen extra para que el texto y las flechas no toquen los bordes
  MargenCelda := 26;

  // Creamos el medidor de texto con la fuente de tu grid
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.Font.Assign(grdStock.TextSettings.Font);

    // --- 1. Medir la Columna 0 (Almacén / Color) ---
    AnchoCol0 := 0;
    Layout.Text := grdStock.Columns[0].Header;
    AnchoCol0 := Max(
      AnchoCol0,
      Layout.TextWidth + MargenCelda + 24);

    for Fila := 0 to grdStock.RowCount - 1 do
    begin
      Layout.Text := grdStock.Cells[0, Fila];
      AnchoCol0 := Max(
        AnchoCol0,
        Layout.TextWidth + MargenCelda + 24);
    end;
    // Color/almacen es la columna principal: nunca se sacrifica para hacer
    // entrar las tallas. Si no caben, el grid conserva sus anchos y desplaza.
    if FDisposicionHorizontal then
      AnchoCol0 := Max(AnchoCol0, 180)
    else
      AnchoCol0 := Max(AnchoCol0, 150);

    // --- 2. Medir la Columna Total (Última) ---
    AnchoTotal := 0;
    Layout.Text := grdStock.Columns[FNumColumnasTallas + 1].Header;
    AnchoTotal := Max(AnchoTotal, Layout.TextWidth + MargenCelda);

    for Fila := 0 to grdStock.RowCount - 1 do
    begin
      Layout.Text := grdStock.Cells[FNumColumnasTallas + 1, Fila];
      AnchoTotal := Max(AnchoTotal, Layout.TextWidth + MargenCelda);
    end;

    // --- 3. Medir las Columnas de Tallas (una a una) ---
    SetLength(AnchosTallas, FNumColumnasTallas);
    SumaAnchos := AnchoCol0 + AnchoTotal;

    for i := 1 to FNumColumnasTallas do
    begin
      AnchosTallas[i-1] := 0;
      Layout.Text := grdStock.Columns[i].Header;
      AnchosTallas[i-1] := Max(
        AnchosTallas[i-1],
        Layout.TextWidth + MargenCelda);

      for Fila := 0 to grdStock.RowCount - 1 do
      begin
        Layout.Text := grdStock.Cells[i, Fila];
        AnchosTallas[i-1] := Max(
          AnchosTallas[i-1],
          Layout.TextWidth + MargenCelda);
      end;

      // Ancho mínimo de 50px para poder tocarlas bien con el dedo
      AnchosTallas[i-1] := Max(AnchosTallas[i-1], 50);
      SumaAnchos := SumaAnchos + AnchosTallas[i-1];
    end;

    // --- 4. Distribuir el espacio sobrante ---
    AnchoDisponible := grdStock.Width - 20; // 20px para la barra de scroll

    // Las columnas de valores comparten el sobrante. La primera conserva el
    // ancho que necesita su texto y deja de dominar el grid en horizontal.
    if SumaAnchos < AnchoDisponible then
    begin
      Incremento := (AnchoDisponible - SumaAnchos) /
        (FNumColumnasTallas + 1);
      for i := 0 to FNumColumnasTallas - 1 do
        AnchosTallas[i] := AnchosTallas[i] + Incremento;
      AnchoTotal := AnchoTotal + Incremento;
    end;

    // --- 5. Aplicar los anchos finales al Grid ---
    grdStock.Columns[0].Width := AnchoCol0;
    for i := 1 to FNumColumnasTallas do
      grdStock.Columns[i].Width := AnchosTallas[i-1];
    grdStock.Columns[FNumColumnasTallas + 1].Width := AnchoTotal;
    grdStock.ScrollTo(0, grdStock.ViewportPosition.Y, False);

  finally
    Layout.Free;
  end;
end;

procedure TFormStock.ActualizarTextoBotonAgrupar;
begin
  if FAgrupacion = agColor then
    btnAgrupar.Text := Tr('Por almacén')
  else
    btnAgrupar.Text := Tr('Por color');
end;

procedure TFormStock.btnEscanearClick(Sender: TObject);
begin
  if not Assigned(FormEscaner) then
    Application.CreateForm(TFormEscaner, FormEscaner);

  FormEscaner.OnCodigoEscaneado := OnCodigoEscaneado;
  FormEscaner.OnEscanerOcultado := OnEscanerOcultado;
  FormEscaner.Show;
end;

procedure TFormStock.OnCodigoEscaneado(const Codigo: string);
begin
  // Recibimos el codigo desde el escaner y lanzamos consulta
  edtArticulo.Text := Codigo;
  btnConsultarClick(nil);
end;

procedure TFormStock.OnEscanerOcultado;
begin
  Show;
end;

procedure TFormStock.btnConsultarClick(Sender: TObject);
begin
  ConsultarCodigo(Trim(edtArticulo.Text), True);
end;

function TFormStock.ListaComoArray(
  ALista: TList<string>): TArray<string>;
begin
  if ALista = nil then
    SetLength(Result, 0)
  else
    Result := ALista.ToArray;
end;

procedure TFormStock.PrepararFiltros;
var
  AlmacenesActivosAnteriores: TArray<string>;
  AlmacenesAnteriores: TArray<string>;
  ColoresActivosAnteriores: TArray<string>;
  ColoresAnteriores: TArray<string>;
  Almacen: string;
  Color: string;
  Item: TStockItem;
  MismoArticulo: Boolean;
begin
  MismoArticulo := SameText(FArticuloFiltros, FUltimo.Articulo);
  AlmacenesAnteriores := ListaComoArray(FAlmacenesDisponibles);
  AlmacenesActivosAnteriores := ListaComoArray(FAlmacenesActivos);
  ColoresAnteriores := ListaComoArray(FColoresDisponibles);
  ColoresActivosAnteriores := ListaComoArray(FColoresActivos);
  FColoresDisponibles.Clear;
  FColoresActivos.Clear;
  FAlmacenesDisponibles.Clear;
  FAlmacenesActivos.Clear;

  for Color in FUltimo.Colores do
  begin
    if not FColoresDisponibles.Contains(Color) then
      FColoresDisponibles.Add(Color);
  end;
  for Almacen in FUltimo.Almacenes do
  begin
    if not FAlmacenesDisponibles.Contains(Almacen) then
      FAlmacenesDisponibles.Add(Almacen);
  end;

  for Item in FUltimo.Items do
  begin
    if not FColoresDisponibles.Contains(Item.Color) then
      FColoresDisponibles.Add(Item.Color);
    if not FAlmacenesDisponibles.Contains(Item.Almacen) then
      FAlmacenesDisponibles.Add(Item.Almacen);
  end;
  FColoresDisponibles.Sort;
  FAlmacenesDisponibles.Sort;

  for Color in FColoresDisponibles do
  begin
    if not MismoArticulo or
       (Length(ColoresAnteriores) = 0) or
       not ContieneTexto(ColoresAnteriores, Color) or
       ContieneTexto(ColoresActivosAnteriores, Color) then
      FColoresActivos.Add(Color);
  end;

  for Almacen in FAlmacenesDisponibles do
  begin
    if Length(AlmacenesAnteriores) = 0 then
    begin
      if not FUltimo.TieneAlmacenesPredeterminados or
         ContieneTexto(
           FUltimo.AlmacenesPredeterminados,
           Almacen) then
        FAlmacenesActivos.Add(Almacen);
    end
    else if ContieneTexto(AlmacenesAnteriores, Almacen) then
    begin
      if ContieneTexto(AlmacenesActivosAnteriores, Almacen) then
        FAlmacenesActivos.Add(Almacen);
    end
    else if ContieneTexto(
      FUltimo.AlmacenesPredeterminados,
      Almacen) then
      FAlmacenesActivos.Add(Almacen);
  end;
  FArticuloFiltros := FUltimo.Articulo;
end;

function TFormStock.ItemVisible(const Item: TStockItem): Boolean;
begin
  Result := FColoresActivos.Contains(Item.Color) and
    FAlmacenesActivos.Contains(Item.Almacen);
end;

function TFormStock.TotalVisible: Double;
var
  Item: TStockItem;
begin
  Result := 0;
  for Item in FUltimo.Items do
  begin
    if ItemVisible(Item) then
      Result := Result + Item.Unidades;
  end;
end;

function TFormStock.TotalAlmacenesActivos: Double;
var
  Item: TStockItem;
begin
  Result := 0;
  for Item in FUltimo.Items do
  begin
    if FAlmacenesActivos.Contains(Item.Almacen) then
      Result := Result + Item.Unidades;
  end;
end;

function TFormStock.TotalUnidadConsultadaActiva: Double;
var
  Cantidad: TCantidadUnidadAlmacen;
begin
  if Length(FUltimo.CantidadesUnidadPorAlmacen) = 0 then
    Result := FUltimo.TotalUnidadConsultada
  else
  begin
    Result := 0;
    for Cantidad in FUltimo.CantidadesUnidadPorAlmacen do
    begin
      if FAlmacenesActivos.Contains(Cantidad.Almacen) then
        Result := Result + Cantidad.Unidades;
    end;
  end;
end;

procedure TFormStock.ActualizarCabeceraArticulo;
var
  TextoArticulo: string;
begin
  if FTieneDatos then
  begin
    TextoArticulo := FUltimo.Articulo;
    if Trim(FUltimo.Descripcion) <> '' then
      TextoArticulo := TextoArticulo + sLineBreak +
        FUltimo.Descripcion;
    EstablecerTextoArticulo(TextoArticulo + sLineBreak +
      TrF(
        '%s: %.0f uds.',
        [NombreEstadoConsultaStock(FEstado),
         TotalAlmacenesActivos]));
  end;
end;

procedure TFormStock.ActualizarResumen;
var
  EstadoUnidad: string;
  FiltrosLimitan: Boolean;
  NombreEstado: string;
  PrefijoUnidad: string;
  TextoUnidad: string;
  TotalUnidad: Double;
begin
  ActualizarCabeceraArticulo;
  NombreEstado := NombreEstadoConsultaStock(FEstado);
  FiltrosLimitan :=
    (FColoresActivos.Count <> FColoresDisponibles.Count) or
    (FAlmacenesActivos.Count <> FAlmacenesDisponibles.Count);
  if FUltimo.UnidadConsultada <> '' then
  begin
    TextoUnidad := FUltimo.UnidadConsultada;
    PrefijoUnidad := FUltimo.Articulo + '/';
    if SameText(
      Copy(TextoUnidad, 1, Length(PrefijoUnidad)),
      PrefijoUnidad) then
      Delete(TextoUnidad, 1, Length(PrefijoUnidad));
    TextoUnidad := StringReplace(
      TextoUnidad, '/', ' / ', [rfReplaceAll]);
    TotalUnidad := TotalUnidadConsultadaActiva;
    if (FEstado = ecStock) and
       (TotalUnidad = 0) then
      EstadoUnidad := Tr('sin stock')
    else
      EstadoUnidad := TrF(
        '%.0f uds.', [TotalUnidad]);
    EstablecerTextoResumen(TrF(
      'Lectura %s: %s | %s visible: %.0f | Artículo: %.0f uds.',
      [TextoUnidad, EstadoUnidad, NombreEstado, TotalVisible,
       TotalAlmacenesActivos]));
  end
  else if FiltrosLimitan then
    EstablecerTextoResumen(TrF(
      '%s visible: %.0f uds. | Artículo: %.0f uds.',
      [NombreEstado, TotalVisible, TotalAlmacenesActivos]))
  else
    EstablecerTextoResumen(TrF(
      'Artículo %s - %s: %.0f uds.',
      [FUltimo.Articulo, NombreEstado, TotalAlmacenesActivos]));
end;

procedure TFormStock.OnFiltrosAplicados(
  const Colores, Almacenes: TArray<string>);
var
  Valor: string;
begin
  FColoresActivos.Clear;
  for Valor in Colores do
  begin
    if FColoresDisponibles.Contains(Valor) then
      FColoresActivos.Add(Valor);
  end;

  FAlmacenesActivos.Clear;
  for Valor in Almacenes do
  begin
    if FAlmacenesDisponibles.Contains(Valor) then
      FAlmacenesActivos.Add(Valor);
  end;

  FExpandidos.Clear;
  RellenarGrid;
  ActualizarResumen;
end;

procedure TFormStock.btnFiltrosClick(Sender: TObject);
begin
  if FTieneDatos then
  begin
    if FormFiltrosStock = nil then
      Application.CreateForm(
        TFormFiltrosStock,
        FormFiltrosStock);
    FormFiltrosStock.OnFiltrosAplicados := OnFiltrosAplicados;
    FormFiltrosStock.Preparar(
      ListaComoArray(FColoresDisponibles),
      ListaComoArray(FColoresActivos),
      ListaComoArray(FAlmacenesDisponibles),
      ListaComoArray(FAlmacenesActivos));
    FormFiltrosStock.Show;
  end;
end;

procedure TFormStock.RegistrarConsultaHistorico(
  const Articulo: string);
var
  EsElActual: Boolean;
begin
  EsElActual := (FIndiceHistorico >= 0) and
    (FIndiceHistorico < FHistorico.Count) and
    SameText(FHistorico[FIndiceHistorico], Articulo);
  if not EsElActual then
  begin
    while FHistorico.Count - 1 > FIndiceHistorico do
      FHistorico.Delete(FHistorico.Count - 1);
    FHistorico.Add(Articulo);
    if FHistorico.Count > MAXIMO_HISTORICO then
      FHistorico.Delete(0);
    FIndiceHistorico := FHistorico.Count - 1;
  end;
end;

procedure TFormStock.ActualizarBotonesHistorico;
begin
  btnAnterior.Enabled := FIndiceHistorico > 0;
  btnSiguiente.Enabled := (FIndiceHistorico >= 0) and
    (FIndiceHistorico < FHistorico.Count - 1);
end;

procedure TFormStock.btnAnteriorClick(Sender: TObject);
begin
  if FIndiceHistorico > 0 then
  begin
    Dec(FIndiceHistorico);
    ConsultarCodigo(FHistorico[FIndiceHistorico], False);
  end;
end;

procedure TFormStock.btnSiguienteClick(Sender: TObject);
begin
  if (FIndiceHistorico >= 0) and
     (FIndiceHistorico < FHistorico.Count - 1) then
  begin
    Inc(FIndiceHistorico);
    ConsultarCodigo(FHistorico[FIndiceHistorico], False);
  end;
end;

procedure TFormStock.ConsultarCodigo(
  const Codigo: string;
  RegistrarHistorico: Boolean);
begin
  if Trim(Codigo) = '' then
  begin
    EstablecerTextoResumen(Tr('Introduce un código de artículo.'));
    Exit;
  end;

  edtArticulo.Text := Codigo;
  EstablecerTextoResumen(Tr('Consultando...'));
  EstablecerTextoArticulo(Tr('Consultando artículo...'));
  LimpiarFoto;
  grdStock.RowCount := 0;
  grdStock.ClearColumns;
  Application.ProcessMessages;

  try
    FUltimo := TApiClient.ConsultarStock(Trim(Codigo), FEstado);
    FTieneDatos := True;
    FCodigoConsultaActual := Trim(Codigo);
    PrepararFiltros;
    RellenarGrid;
    ActualizarResumen;
    CargarFoto300(FUltimo);
    if RegistrarHistorico then
      RegistrarConsultaHistorico(Trim(Codigo));
    ActualizarBotonesHistorico;
  except
    on E: Exception do
    begin
      FTieneDatos := False;
      EstablecerTextoResumen(TrF('Error: %s', [E.Message]));
      EstablecerTextoArticulo(Tr('No se pudo consultar el artículo.'));
      LimpiarFoto;
      grdStock.RowCount := 0;
      grdStock.ClearColumns;
      ActualizarBotonesHistorico;
    end;
  end;
end;

procedure TFormStock.btnAgruparClick(Sender: TObject);
begin
  // Solo alternamos entre dos modos ahora
  if FAgrupacion = agColor then
    FAgrupacion := agAlmacen
  else
    FAgrupacion := agColor;
  FExpandidos.Clear;
  ActualizarTextoBotonAgrupar;
  if FTieneDatos then
    RellenarGrid;
end;

procedure TFormStock.btnSalirClick(Sender: TObject);
begin
  TSettings.BorrarToken;
  TSettings.BorrarCredenciales;
  Close;
  if Assigned(FormLogin) then FormLogin.Show;
end;

procedure TFormStock.RellenarGrid;
var
  Tallas, Padres, Hijos: TList<string>;
  Item: TStockItem;
  Padre, Hijo, Talla, EncabezadoCol1: string;
  i, j: Integer;
  Col: TStringColumn;
  ColCantidad: TColumnaCantidad;
  GranTotal, TotalFila, TotalCol: Double;
  OcultarColumnasCero: Boolean;

  // Diccionarios para acumular sumas
  SumPadres, SumHijos: TDictionary<string, TDictionary<string, Double>>;

  // Estructura para organizar las filas antes de pintarlas
  type
    TFilaVirtual = record
      EsPadre: Boolean;
      ClaveSuma: string;
      TituloVisible: string;
    end;
  var
    FilasVirtuales: TList<TFilaVirtual>;
    FilaV: TFilaVirtual;
    Sub: TDictionary<string, Double>;

  procedure Acumular(
    Dict: TDictionary<string, TDictionary<string, Double>>;
    const Clave, ATalla: string;
    AUnidades: Double);
  var
    D: TDictionary<string, Double>;
  begin
    if not Dict.TryGetValue(Clave, D) then
    begin
      D := TDictionary<string, Double>.Create;
      Dict.Add(Clave, D);
    end;
    if D.ContainsKey(ATalla) then D[ATalla] := D[ATalla] + AUnidades
    else D.Add(ATalla, AUnidades);
  end;

  function DebeMostrarTalla(const ATalla: string): Boolean;
  var
    ItemComprobar: TStockItem;
  begin
    Result := not OcultarColumnasCero;
    if OcultarColumnasCero then
    begin
      for ItemComprobar in FUltimo.Items do
      begin
        if ItemVisible(ItemComprobar) and
           SameText(ItemComprobar.Talla, ATalla) and
           (Abs(ItemComprobar.Unidades) > 0.000001) then
          Result := True;
      end;
    end;
  end;

begin
  grdStock.BeginUpdate;
  try
    grdStock.RowCount := 0;
    grdStock.ClearColumns;
    FNumColumnasTallas := 0;
    OcultarColumnasCero := TSettings.LeerOcultarColumnasCero;

    if not FTieneDatos then Exit;
    if Length(FUltimo.Items) = 0 then
    begin
      Col := TStringColumn.Create(grdStock);
      Col.Parent := grdStock;
      Col.Header := NombreEstadoConsultaStock(FEstado);
      Col.ReadOnly := True;
      grdStock.RowCount := 1;
      grdStock.Cells[0, 0] := Tr('Sin cantidades para este artículo');
      AjustarAnchoColumnas;
      Exit;
    end;

    Tallas := TList<string>.Create;
    Padres := TList<string>.Create;
    Hijos  := TList<string>.Create;
    SumPadres := TDictionary<string, TDictionary<string, Double>>.Create;
    SumHijos  := TDictionary<string, TDictionary<string, Double>>.Create;
    FilasVirtuales := TList<TFilaVirtual>.Create;

    try
      // --- 1. RECOLECTAR DATOS Y SUMAR ---
      if FAgrupacion = agColor then
        EncabezadoCol1 := Tr('Color')
      else
        EncabezadoCol1 := Tr('Almacén');

      for Item in FUltimo.Items do
      begin
        if ItemVisible(Item) then
        begin
          if FAgrupacion = agColor then
          begin
            Padre := Item.Color;
            Hijo := Item.Almacen;
          end
          else
          begin
            Padre := Item.Almacen;
            Hijo := Item.Color;
          end;
          if not Padres.Contains(Padre) then
            Padres.Add(Padre);
          Talla := Item.Talla;
          if DebeMostrarTalla(Talla) then
          begin
            if not Tallas.Contains(Talla) then
              Tallas.Add(Talla);
            Acumular(SumPadres, Padre, Talla, Item.Unidades);
            Acumular(
              SumHijos,
              Padre + '|' + Hijo,
              Talla,
              Item.Unidades);
          end;
        end;
      end;

      Padres.Sort;
      FNumColumnasTallas := Tallas.Count;

      if Padres.Count = 0 then
      begin
        Col := TStringColumn.Create(grdStock);
        Col.Parent := grdStock;
        Col.Header := EncabezadoCol1;
        Col.ReadOnly := True;
        Col.Width := Max(150, grdStock.Width - 20);
        grdStock.RowCount := 1;
        grdStock.Cells[0, 0] :=
          Tr('Sin datos con los filtros seleccionados');
      end
      else
      begin
        // --- 2. ORDENAR JERARQUÍA (Filas visibles) ---
        for Padre in Padres do
        begin
          FilaV.EsPadre := True;
          FilaV.ClaveSuma := Padre;
          if FExpandidos.Contains(Padre) then
            FilaV.TituloVisible := '▼ ' + Padre
          else
            FilaV.TituloVisible := '▶ ' + Padre;

          FilasVirtuales.Add(FilaV);

          if FExpandidos.Contains(Padre) then
          begin
            Hijos.Clear;
            for Item in FUltimo.Items do
            begin
              if ItemVisible(Item) and
                 (((FAgrupacion = agColor) and
                   (Item.Color = Padre)) or
                  ((FAgrupacion = agAlmacen) and
                   (Item.Almacen = Padre))) then
              begin
                if FAgrupacion = agColor then
                  Hijo := Item.Almacen
                else
                  Hijo := Item.Color;
                if not Hijos.Contains(Hijo) then
                  Hijos.Add(Hijo);
              end;
            end;
            Hijos.Sort;

            for Hijo in Hijos do
            begin
              FilaV.EsPadre := False;
              FilaV.ClaveSuma := Padre + '|' + Hijo;
              FilaV.TituloVisible := '    ↳ ' + Hijo;
              FilasVirtuales.Add(FilaV);
            end;
          end;
        end;

        // --- 3. CREAR COLUMNAS ---
        Col := TStringColumn.Create(grdStock);
        Col.Parent := grdStock;
        Col.Header := EncabezadoCol1;
        Col.Padding.Left := 24;
        Col.ReadOnly := True;

        for Talla in Tallas do
        begin
          ColCantidad := TColumnaCantidad.Create(grdStock);
          ColCantidad.Parent := grdStock;
          ColCantidad.Header := Talla;
          ColCantidad.HorzAlign := TTextAlign.Center;
          ColCantidad.ReadOnly := True;
          ColCantidad.ColorTexto := ColorEstado;
        end;

        ColCantidad := TColumnaCantidad.Create(grdStock);
        ColCantidad.Parent := grdStock;
        ColCantidad.Header := Tr('Total');
        ColCantidad.HorzAlign := TTextAlign.Center;
        ColCantidad.ReadOnly := True;
        ColCantidad.ColorTexto := ColorEstado;

        // --- 4. PINTAR EL GRID ---
        grdStock.RowCount := FilasVirtuales.Count + 1;
        GranTotal := 0;

        for i := 0 to FilasVirtuales.Count - 1 do
        begin
          FilaV := FilasVirtuales[i];
          grdStock.Cells[0, i] := FilaV.TituloVisible;
          TotalFila := 0;

          if FilaV.EsPadre then
            SumPadres.TryGetValue(FilaV.ClaveSuma, Sub)
          else
            SumHijos.TryGetValue(FilaV.ClaveSuma, Sub);

          for j := 0 to Tallas.Count - 1 do
          begin
            Talla := Tallas[j];
            if (Sub <> nil) and Sub.ContainsKey(Talla) then
            begin
              grdStock.Cells[j + 1, i] :=
                FormatFloat('0.##', Sub[Talla], FormatoIdioma);
              TotalFila := TotalFila + Sub[Talla];
            end
            else
              grdStock.Cells[j + 1, i] := '';
          end;

          grdStock.Cells[Tallas.Count + 1, i] :=
            FormatFloat('0.##', TotalFila, FormatoIdioma);

          // Solo se suman padres para no duplicar los hijos expandidos.
          if FilaV.EsPadre then
            GranTotal := GranTotal + TotalFila;
        end;

        // --- 5. FILA TOTAL ---
        grdStock.Cells[0, FilasVirtuales.Count] := Tr('TOTAL');
        for j := 0 to Tallas.Count - 1 do
        begin
          TotalCol := 0;
          Talla := Tallas[j];
          for Padre in Padres do
          begin
            if SumPadres.TryGetValue(Padre, Sub) and
               Sub.ContainsKey(Talla) then
              TotalCol := TotalCol + Sub[Talla];
          end;
          grdStock.Cells[j + 1, FilasVirtuales.Count] :=
            FormatFloat('0.##', TotalCol, FormatoIdioma);
        end;
        grdStock.Cells[Tallas.Count + 1, FilasVirtuales.Count] :=
          FormatFloat('0.##', GranTotal, FormatoIdioma);
        AjustarAnchoColumnas;
      end;
    finally
      for Sub in SumPadres.Values do Sub.Free;
      for Sub in SumHijos.Values do Sub.Free;
      SumPadres.Free;
      SumHijos.Free;
      FilasVirtuales.Free;
      Hijos.Free;
      Padres.Free;
      Tallas.Free;
    end;
  finally
    grdStock.EndUpdate;
  end;
end;

end.
