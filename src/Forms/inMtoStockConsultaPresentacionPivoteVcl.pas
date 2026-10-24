{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoStockConsultaPresentacionPivoteVcl                       }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Presentadores del selector de estado (combo, radios de modo y leyenda) y  }
{    de la rejilla pivote de la consulta de stock. Reciben los controles, el   }
{    repositorio de pivote y cierres de reaccion; nunca el formulario.         }
{******************************************************************************}
unit inMtoStockConsultaPresentacionPivoteVcl;

interface

uses
  Winapi.Windows,
  System.Classes, System.Generics.Collections, System.Variants,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  Data.DB, Uni,
  cxClasses, cxControls, cxContainer, cxEdit, cxTextEdit,
  cxCurrencyEdit, cxDropDownEdit, cxGraphics, dxCoreGraphics, cxCustomData,
  cxData, cxDataStorage, cxDBData,
  cxGridCustomTableView, cxGridCustomView, cxGridDBTableView,
  cxGridTableView, cxRadioGroup, cxStyles,
  inLibStockCeldaDocumento,
  inLibStockConsultaPersistenciaIntf,
  inLibStockConsultaPresentacionEstados,
  inLibStockConsultaPresentacionPivote;

type
  TReaccionStockConsulta = reference to procedure;

  TPresentadorEstadosStock = class
  private
    FSeleccion: TSeleccionEstadosStock;
    FCombo: TcxComboBox;
    FRadioSimplificado: TcxRadioButton;
    FRadioDesglosado: TcxRadioButton;
    FPanelLeyenda: TWinControl;
    FAlRecargar: TReaccionStockConsulta;
    FAlGuardarModo: TReaccionStockConsulta;
    procedure RadioClick(Sender: TObject);
    procedure LeyendaClick(Sender: TObject);
    procedure CrearLeyenda;
  public
    constructor Create(
      AOwner: TComponent;
      ACombo: TcxComboBox;
      APanelModo: TWinControl;
      APanelLeyenda: TWinControl;
      AReferencia: TControl;
      const ACaptionSimplificado, ACaptionDesglosado: string;
      const AAlRecargar, AAlGuardarModo: TReaccionStockConsulta);
    destructor Destroy; override;
    procedure PoblarCombo;
    procedure AplicarModo(AModoDesglosado: Boolean);
    procedure MarcarModoEnRadios;
    procedure AplicarColorEstadoActual;
    function EstadoActual: TEstadoStock;
    function ModoDesglosado: Boolean;
  end;

  TPresentadorPivoteStock = class
  private
    FVista: TcxGridDBTableView;
    FOrigen: TDataSource;
    FRepositorio: IRepositorioPivoteStock;
    FConexion: TUniConnection;
    FResultado: IResultadoConsultaStock;
    FColumnas: TList<TcxGridDBColumn>;
    FColumnaGrupo: TcxGridDBColumn;
    FColumnaEstado: TcxGridDBColumn;
    FTallas: TArray<TInfoColumna>;
    FEstilos: array[TEstadoStock] of TcxStyle;
    FEstiloGrupo: TcxStyle;
    FEsModoColor: Boolean;
    FEsModoTodo: Boolean;
    FEstadoActual: TEstadoStock;
    function EscalarAncho(AAncho96Dpi: Integer): Integer;
    procedure CrearEstilos(AOwner: TComponent);
    procedure DibujarCelda(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure EstadoGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure DatosGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure GrupoGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure ConfigurarColumnaDatos(AColumna: TcxGridDBColumn);
    function ColumnaEnfocada: TcxGridDBColumn;
  public
    constructor Create(
      AOwner: TComponent;
      AVista: TcxGridDBTableView;
      const ARepositorio: IRepositorioPivoteStock;
      AConexion: TUniConnection);
    destructor Destroy; override;
    procedure Limpiar;
    procedure ReconstruirColumnas(
      const ATallas: TArray<TInfoColumna>;
      APorColor: Boolean; AEstado: TEstadoStock);
    procedure Consultar(const ASolicitud: TSolicitudPivoteStock;
      const ATallas: TArray<TInfoColumna>);
    function ListarTallas(const ACodigoArticulo: string;
      const AColores: TArray<string>): TArray<TInfoColumna>;
    procedure LeerCeldaEnfocada(var AEstado: TEstadoCeldaStock);
    function TallaEnfocada(out ATalla: string): Boolean;
    function GrupoEnfocado(out AGrupo: string): Boolean;
    function HayFilaEnfocada: Boolean;
    function HayColumnaEnfocada: Boolean;
    function CantidadEnfocada(out ACantidad: Double): Boolean;
    property EsModoColor: Boolean read FEsModoColor;
    property EsModoTodo: Boolean read FEsModoTodo;
    property Tallas: TArray<TInfoColumna> read FTallas;
  end;

implementation

uses
  System.SysUtils, System.Math,
  cxLookAndFeels, cxLookAndFeelPainters,
  inLibAtributosPaleta,
  inLibMsgArticulos;

const
  // Contraste reforzado para los fondos claros y oscuros de los temas.
  CONTRASTE_MINIMO_ESTADO = 7.0;

function LuminanciaRelativa(AColor: TColor): Double;

  function Canal(AValor: Byte): Double;
  var
    dValor: Double;
  begin
    dValor := AValor / 255;
    if dValor <= 0.03928 then
      Result := dValor / 12.92
    else
      Result := Power((dValor + 0.055) / 1.055, 2.4);
  end;

var
  iRGB: Integer;
begin
  iRGB := ColorToRGB(AColor);
  Result := 0.2126 * Canal(GetRValue(iRGB)) +
    0.7152 * Canal(GetGValue(iRGB)) + 0.0722 * Canal(GetBValue(iRGB));
end;

function Contraste(AColor1, AColor2: TColor): Double;
var
  dL1, dL2: Double;
begin
  dL1 := LuminanciaRelativa(AColor1);
  dL2 := LuminanciaRelativa(AColor2);
  Result := (Max(dL1, dL2) + 0.05) / (Min(dL1, dL2) + 0.05);
end;

// Los colores de estado estan pensados para fondo claro (azul marino,
// granate...). Con un skin oscuro se aclaran, y con uno claro se oscurecen,
// lo justo para que se lean; el tono se conserva.
function ColorTextoLegible(ABase, AFondo: TColor): TColor;
var
  cBase, cExtremo: TColor;
  iMezcla: Integer;
begin
  cBase := ABase;
  Result := cBase;
  if Contraste(clWhite, AFondo) > Contraste(clBlack, AFondo) then
    cExtremo := clWhite
  else
    cExtremo := clBlack;
  iMezcla := 0;
  while (Contraste(Result, AFondo) < CONTRASTE_MINIMO_ESTADO) and
        (iMezcla < 100) do
  begin
    Inc(iMezcla, 10);
    Result := dxGetMiddleRGB(cExtremo, cBase, iMezcla);
  end;
end;

function ColorEstadoLegible(AEstado: TEstadoStock; AFondo: TColor): TColor;
begin
  Result := ColorTextoLegible(TColor(ColorEstadoStock(AEstado)), AFondo);
end;

type
  TColumnaPivoteStock = class(TcxGridDBColumn)
  protected
    procedure ChangeScale(M, D: Integer); override;
  public
    constructor CrearEnVista(AVista: TcxGridDBTableView);
  end;

const
  ANCHO_RADIO_MODO = 110;
  ALTO_RADIO_MODO = 22;
  MARGEN_TEXTO_RADIO_MODO = 30;
  SEPARACION_RADIO_MODO = 16;
  SEPARACION_ENTRE_RADIOS = 4;
  TOP_LEYENDA = 5;
  MARGEN_LEYENDA = 8;
  SEPARACION_LEYENDA = 14;
  FORMATO_CANTIDAD_STOCK = '#,##0.##;-#,##0.##;0';

constructor TColumnaPivoteStock.CrearEnVista(
  AVista: TcxGridDBTableView);
begin
  inherited Create(AVista.Owner);
  SetParentComponent(AVista);
end;

procedure TColumnaPivoteStock.ChangeScale(M, D: Integer);
var
  iAnchoAnterior: Integer;
begin
  iAnchoAnterior := Width;
  inherited ChangeScale(M, D);
  // DevExpress escala primero MinWidth y puede elevar Width al nuevo
  // mínimo. El ancho original, incluido el manual, se escala una sola vez.
  Width := MulDiv(iAnchoAnterior, M, D);
end;

constructor TPresentadorEstadosStock.Create(
  AOwner: TComponent;
  ACombo: TcxComboBox;
  APanelModo: TWinControl;
  APanelLeyenda: TWinControl;
  AReferencia: TControl;
  const ACaptionSimplificado, ACaptionDesglosado: string;
  const AAlRecargar, AAlGuardarModo: TReaccionStockConsulta);
var
  iAltoRadio: Integer;
  iAnchoMinimo: Integer;
  iAnchoSimplificado: Integer;
  iAnchoDesglosado: Integer;
  iMargenTexto: Integer;
  iSeparacionModo: Integer;
  iSeparacionRadios: Integer;
begin
  inherited Create;
  FSeleccion := TSeleccionEstadosStock.Create;
  FCombo := ACombo;
  FPanelLeyenda := APanelLeyenda;
  FAlRecargar := AAlRecargar;
  FAlGuardarModo := AAlGuardarModo;
  FRadioSimplificado := TcxRadioButton.Create(AOwner);
  FRadioSimplificado.Parent := APanelModo;
  FRadioSimplificado.Caption := ACaptionSimplificado;
  // Sin transparencia pintan fondo claro de sistema y con skin oscuro el
  // texto no se ve.
  FRadioSimplificado.Transparent := True;
  // Estos radios heredan una fuente escalada por DPI, pero antes conservaban
  // un ancho fijo de 110 px. En monitores escalados se veian como
  // "Simplifica" y "Desglosa". Medimos el texto ya escalado y reservamos el
  // hueco del indicador y sus margenes; el minimo tambien se escala.
  iAltoRadio := MulDiv(ALTO_RADIO_MODO,
    AReferencia.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iAnchoMinimo := MulDiv(ANCHO_RADIO_MODO,
    AReferencia.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iMargenTexto := MulDiv(MARGEN_TEXTO_RADIO_MODO,
    AReferencia.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSeparacionModo := MulDiv(SEPARACION_RADIO_MODO,
    AReferencia.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSeparacionRadios := MulDiv(SEPARACION_ENTRE_RADIOS,
    AReferencia.CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iAnchoSimplificado := cxTextWidth(
    FRadioSimplificado.Font, FRadioSimplificado.Caption) + iMargenTexto;
  if iAnchoSimplificado < iAnchoMinimo then
    iAnchoSimplificado := iAnchoMinimo;
  FRadioSimplificado.SetBounds(
    AReferencia.Left + AReferencia.Width + iSeparacionModo,
    AReferencia.Top, iAnchoSimplificado, iAltoRadio);
  FRadioSimplificado.GroupIndex := 1;
  FRadioSimplificado.OnClick := RadioClick;
  FRadioDesglosado := TcxRadioButton.Create(AOwner);
  FRadioDesglosado.Parent := APanelModo;
  FRadioDesglosado.Caption := ACaptionDesglosado;
  FRadioDesglosado.Transparent := True;
  iAnchoDesglosado := cxTextWidth(
    FRadioDesglosado.Font, FRadioDesglosado.Caption) + iMargenTexto;
  if iAnchoDesglosado < iAnchoMinimo then
    iAnchoDesglosado := iAnchoMinimo;
  FRadioDesglosado.SetBounds(
    FRadioSimplificado.Left + FRadioSimplificado.Width +
      iSeparacionRadios,
    AReferencia.Top, iAnchoDesglosado, iAltoRadio);
  FRadioDesglosado.GroupIndex := 1;
  FRadioDesglosado.OnClick := RadioClick;
  CrearLeyenda;
end;

destructor TPresentadorEstadosStock.Destroy;
begin
  FAlRecargar := nil;
  FAlGuardarModo := nil;
  FreeAndNil(FSeleccion);
  inherited Destroy;
end;

function TPresentadorEstadosStock.ModoDesglosado: Boolean;
begin
  Result := FSeleccion.ModoDesglosado;
end;

// Mapeo posicion del combo -> estado. Sin seleccion valida se asume
// existencias, que es el estado por defecto de la pantalla.
function TPresentadorEstadosStock.EstadoActual: TEstadoStock;
begin
  if (FCombo.ItemIndex >= 0) and
     (FCombo.ItemIndex < FSeleccion.Cuenta) then
    Result := FSeleccion.Estados[FCombo.ItemIndex]
  else
    Result := esExistencias;
end;

procedure TPresentadorEstadosStock.AplicarColorEstadoActual;
begin
  FCombo.Style.TextColor := ColorEstadoLegible(EstadoActual,
    RootLookAndFeel.Painter.DefaultEditorBackgroundColor(False));
end;

procedure TPresentadorEstadosStock.PoblarCombo;
var
  i: Integer;
begin
  FCombo.Properties.Items.BeginUpdate;
  try
    FCombo.Properties.Items.Clear;
    for i := 0 to FSeleccion.Cuenta - 1 do
      FCombo.Properties.Items.Add(
        NombreEstadoStockCorto(FSeleccion.Estados[i]));
  finally
    FCombo.Properties.Items.EndUpdate;
  end;
  FCombo.ItemIndex := 0;
end;

procedure TPresentadorEstadosStock.MarcarModoEnRadios;
begin
  if FSeleccion.ModoDesglosado then
    FRadioDesglosado.Checked := True
  else
    FRadioSimplificado.Checked := True;
end;

procedure TPresentadorEstadosStock.AplicarModo(AModoDesglosado: Boolean);
begin
  FSeleccion.FijarModo(AModoDesglosado);
  PoblarCombo;
end;

procedure TPresentadorEstadosStock.RadioClick(Sender: TObject);
begin
  FSeleccion.FijarModo(FRadioDesglosado.Checked);
  PoblarCombo;
  FAlGuardarModo();
  FAlRecargar();
end;

// Leyenda al pie: el nombre de cada estado en su color. Pinchar uno lo
// selecciona y, si hace falta, conmuta el modo para que ese estado exista
// en el combo.
procedure TPresentadorEstadosStock.CrearLeyenda;
var
  i: Integer;
  Etiqueta: TLabel;
  iIzquierda: Integer;
begin
  iIzquierda := MARGEN_LEYENDA;
  for i := Low(ESTADOS_LEYENDA_STOCK) to High(ESTADOS_LEYENDA_STOCK) do
  begin
    Etiqueta := TLabel.Create(FPanelLeyenda);
    Etiqueta.Parent := FPanelLeyenda;
    Etiqueta.AutoSize := True;
    Etiqueta.Font.Color := ColorEstadoLegible(ESTADOS_LEYENDA_STOCK[i],
      RootLookAndFeel.Painter.DefaultControlColor);
    Etiqueta.Font.Style := [fsBold];
    Etiqueta.Caption :=
      NombreEstadoStockCorto(ESTADOS_LEYENDA_STOCK[i]);
    Etiqueta.Tag := Ord(ESTADOS_LEYENDA_STOCK[i]);
    Etiqueta.Cursor := crHandPoint;
    Etiqueta.OnClick := LeyendaClick;
    Etiqueta.Top := TOP_LEYENDA;
    Etiqueta.Left := iIzquierda;
    iIzquierda := iIzquierda + Etiqueta.Width + SEPARACION_LEYENDA;
  end;
end;

procedure TPresentadorEstadosStock.LeyendaClick(Sender: TObject);
var
  Resultado: TResultadoLeyendaStock;
begin
  if Sender is TLabel then
  begin
    Resultado := FSeleccion.ResolverLeyenda(
      TEstadoStock(TLabel(Sender).Tag));
    if Resultado.ModoCambiado then
    begin
      MarcarModoEnRadios;
      PoblarCombo;
      FAlGuardarModo();
    end;
    if Resultado.Indice >= 0 then
    begin
      if FCombo.ItemIndex <> Resultado.Indice then
        FCombo.ItemIndex := Resultado.Indice
      else if Resultado.ModoCambiado then
        FAlRecargar();
    end
    else if Resultado.ModoCambiado then
      FAlRecargar();
  end;
end;

constructor TPresentadorPivoteStock.Create(
  AOwner: TComponent;
  AVista: TcxGridDBTableView;
  const ARepositorio: IRepositorioPivoteStock;
  AConexion: TUniConnection);
begin
  inherited Create;
  FVista := AVista;
  FRepositorio := ARepositorio;
  FConexion := AConexion;
  FColumnas := TList<TcxGridDBColumn>.Create;
  FOrigen := TDataSource.Create(AOwner);
  FOrigen.DataSet := nil;
  FVista.DataController.DataSource := FOrigen;
  FVista.OptionsView.ColumnAutoWidth := False;
  FVista.OnCustomDrawCell := DibujarCelda;
  CrearEstilos(AOwner);
end;

destructor TPresentadorPivoteStock.Destroy;
begin
  if FOrigen <> nil then
    FOrigen.DataSet := nil;
  FResultado := nil;
  FRepositorio := nil;
  FConexion := nil;
  FreeAndNil(FColumnas);
  FreeAndNil(FOrigen);
  inherited Destroy;
end;

// Un estilo por estado con su TextColor. Es la via que respeta cxGrid:
// modificar AViewInfo.Params.TextColor en OnCustomDrawCell no surte
// efecto porque el render por defecto sobrescribe ese color.
procedure TPresentadorPivoteStock.CrearEstilos(AOwner: TComponent);
var
  Estado: TEstadoStock;
  Estilo: TcxStyle;
begin
  FEstiloGrupo := TcxStyle.Create(AOwner);
  FEstiloGrupo.AssignedValues := [svTextColor];
  for Estado := Low(TEstadoStock) to High(TEstadoStock) do
  begin
    Estilo := TcxStyle.Create(AOwner);
    Estilo.AssignedValues := [svTextColor];
    Estilo.TextColor := ColorEstadoLegible(Estado,
      RootLookAndFeel.Painter.DefaultContentColor);
    FEstilos[Estado] := Estilo;
  end;
end;

procedure TPresentadorPivoteStock.Limpiar;
begin
  FOrigen.DataSet := nil;
  FResultado := nil;
end;

function TPresentadorPivoteStock.EscalarAncho(
  AAncho96Dpi: Integer): Integer;
var
  iPpi: Integer;
begin
  iPpi := USER_DEFAULT_SCREEN_DPI;
  if (FVista <> nil) and (FVista.Site <> nil) then
    iPpi := FVista.Site.CurrentPPI;
  Result := MulDiv(AAncho96Dpi, iPpi, USER_DEFAULT_SCREEN_DPI);
end;

function TPresentadorPivoteStock.ListarTallas(
  const ACodigoArticulo: string;
  const AColores: TArray<string>): TArray<TInfoColumna>;
begin
  Result := FRepositorio.ListarTallas(ACodigoArticulo, AColores);
end;

procedure TPresentadorPivoteStock.Consultar(
  const ASolicitud: TSolicitudPivoteStock;
  const ATallas: TArray<TInfoColumna>);
begin
  FResultado := FRepositorio.Consultar(ASolicitud, ATallas);
  FOrigen.DataSet := FResultado.DataSet;
end;

procedure TPresentadorPivoteStock.ConfigurarColumnaDatos(
  AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClassName := 'TcxCurrencyEditProperties';
  TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat :=
    FORMATO_CANTIDAD_STOCK;
  TcxCurrencyEditProperties(
    AColumna.Properties).UseDisplayFormatWhenEditing := True;
  AColumna.HeaderAlignmentHorz := taCenter;
  AColumna.Options.Editing := False;
  AColumna.Options.Sorting := False;
  AColumna.Styles.OnGetContentStyle := DatosGetContentStyle;
end;

// Las columnas del pivote son todas dinamicas: se liberan y se vuelven a
// crear en cada recarga a partir del mapa que decide inLib.
procedure TPresentadorPivoteStock.ReconstruirColumnas(
  const ATallas: TArray<TInfoColumna>;
  APorColor: Boolean; AEstado: TEstadoStock);
var
  Definiciones: TDefinicionesColumnasPivote;
  Definicion: TDefinicionColumnaPivote;
  Columna: TcxGridDBColumn;
  i: Integer;
  sTituloGrupo: string;
begin
  for i := FColumnas.Count - 1 downto 0 do
    FColumnas[i].Free;
  FColumnas.Clear;
  FColumnaGrupo := nil;
  FColumnaEstado := nil;
  FEsModoColor := APorColor;
  FEsModoTodo := AEstado = esTodoAlaVez;
  FEstadoActual := AEstado;
  if APorColor then
    sTituloGrupo := SCaptionColColor
  else
    sTituloGrupo := SCaptionColAlmacen;
  Definiciones := DefinirColumnasPivoteStock(
    ATallas, APorColor, FEsModoTodo, sTituloGrupo,
    SCaptionColEstado, SCaptionColTotal);
  for Definicion in Definiciones do
  begin
    Columna := TColumnaPivoteStock.CrearEnVista(FVista);
    // Fijar Width antes de MinWidth y del campo: si ya coincide con el
    // mínimo, DevExpress no lo guarda como asignado y al abrir el dataset
    // lo sustituye por DisplayWidth, aunque ColumnAutoWidth sea False.
    Columna.Width := EscalarAncho(Definicion.Ancho);
    Columna.MinWidth := Columna.Width;
    Columna.Caption := Definicion.Titulo;
    Columna.DataBinding.FieldName := Definicion.Campo;
    case Definicion.Clase of
      cpsGrupo:
        begin
          Columna.BestFitMaxWidth := EscalarAncho(360);
          Columna.HeaderAlignmentHorz := taLeftJustify;
          Columna.Options.Sorting := False;
          Columna.Styles.OnGetContentStyle := GrupoGetContentStyle;
          FColumnaGrupo := Columna;
        end;
      cpsEstado:
        begin
          Columna.BestFitMaxWidth := EscalarAncho(180);
          Columna.OnGetDisplayText := EstadoGetDisplayText;
          Columna.HeaderAlignmentHorz := taLeftJustify;
          Columna.Options.Sorting := False;
          Columna.Styles.OnGetContentStyle := DatosGetContentStyle;
          FColumnaEstado := Columna;
        end;
    else
      begin
        Columna.BestFitMaxWidth := EscalarAncho(110);
        ConfigurarColumnaDatos(Columna);
      end;
    end;
    FColumnas.Add(Columna);
  end;
  FTallas := Copy(ATallas);
end;

// El fondo real de la fila puede diferir de DefaultContentColor del skin.
// Resolverlo en cada dibujo conserva el contraste al alternar filas o tema.
procedure TPresentadorPivoteStock.DatosGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  iEstado: Integer;
  Parametros: TcxViewParams;
  Estilo: TcxStyle;
begin
  if ARecord <> nil then
  begin
    iEstado := Ord(FEstadoActual);
    if FEsModoTodo and (FColumnaEstado <> nil) then
      iEstado := StrToIntDef(
        VarToStr(ARecord.Values[FColumnaEstado.Index]), -1);
    if EsEstadoStockValido(iEstado) then
    begin
      FVista.Styles.GetContentParams(ARecord, nil, Parametros);
      Estilo := FEstilos[TEstadoStock(iEstado)];
      Estilo.TextColor := ColorEstadoLegible(
        TEstadoStock(iEstado), Parametros.Color);
      AStyle := Estilo;
    end;
  end;
end;

procedure TPresentadorPivoteStock.GrupoGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  Parametros: TcxViewParams;
begin
  if ARecord <> nil then
  begin
    FVista.Styles.GetContentParams(ARecord, nil, Parametros);
    FEstiloGrupo.TextColor := ColorTextoLegible(
      Parametros.TextColor, Parametros.Color);
    AStyle := FEstiloGrupo;
  end;
end;

// Convierte el ESTADO_NUM crudo en su nombre corto, para no meter
// cadenas de presentacion en el SQL del pivote.
procedure TPresentadorPivoteStock.EstadoGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
var
  iEstado: Integer;
begin
  iEstado := StrToIntDef(AText, -1);
  if EsEstadoStockValido(iEstado) then
    AText := NombreEstadoStockCorto(TEstadoStock(iEstado));
end;

// Solo se pinta el cuadradito del color basico delante del texto en la
// columna de grupo del modo Por Color. El color del resto de celdas va
// por cxStyles.
procedure TPresentadorPivoteStock.DibujarCelda(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  ADone := False;
  if FEsModoColor and (FColumnaGrupo <> nil) and
     (AViewInfo.Item is TcxGridDBColumn) and
     (AViewInfo.Item = FColumnaGrupo) then
  begin
    // Solo el atributo de color: el pintor generico probaba el texto contra
    // todos los atributos y una talla podia heredar un color basico.
    if PintarCeldaSwatchColorDeSkuSiAplica(FConexion, ACanvas, AViewInfo) then
      ADone := True;
  end;
end;

function TPresentadorPivoteStock.ColumnaEnfocada: TcxGridDBColumn;
begin
  Result := nil;
  if FVista.Controller.FocusedColumn is TcxGridDBColumn then
    Result := TcxGridDBColumn(FVista.Controller.FocusedColumn);
end;

function TPresentadorPivoteStock.HayFilaEnfocada: Boolean;
begin
  Result := FVista.Controller.FocusedRecord <> nil;
end;

function TPresentadorPivoteStock.HayColumnaEnfocada: Boolean;
begin
  Result := ColumnaEnfocada <> nil;
end;

function TPresentadorPivoteStock.TallaEnfocada(
  out ATalla: string): Boolean;
var
  Columna: TcxGridDBColumn;
begin
  ATalla := '';
  Columna := ColumnaEnfocada;
  Result := (Columna <> nil) and
            TallaDeColumnaPivoteStock(
              Columna.DataBinding.FieldName, FTallas, ATalla);
end;

function TPresentadorPivoteStock.GrupoEnfocado(
  out AGrupo: string): Boolean;
var
  Registro: TcxCustomGridRecord;
begin
  AGrupo := '';
  Registro := FVista.Controller.FocusedRecord;
  Result := (Registro <> nil) and (FColumnaGrupo <> nil);
  if Result then
    AGrupo := VarToStr(Registro.Values[FColumnaGrupo.Index]);
end;

// Cantidad de la celda enfocada. Devuelve False cuando la celda esta
// vacia, para que el llamador la trate como stock cero.
function TPresentadorPivoteStock.CantidadEnfocada(
  out ACantidad: Double): Boolean;
var
  Columna: TcxGridDBColumn;
  Registro: TcxCustomGridRecord;
  vValor: Variant;
begin
  Result := False;
  ACantidad := 0;
  Columna := ColumnaEnfocada;
  Registro := FVista.Controller.FocusedRecord;
  if (Columna <> nil) and (Registro <> nil) then
  begin
    vValor := Registro.Values[Columna.Index];
    if not (VarIsNull(vValor) or VarIsEmpty(vValor)) then
    begin
      ACantidad := VarAsType(vValor, varDouble);
      Result := True;
    end;
  end;
end;

// Vuelca en el estado de celda todo lo que depende de la rejilla; las
// decisiones viven en inLibStockCeldaDocumento.
procedure TPresentadorPivoteStock.LeerCeldaEnfocada(
  var AEstado: TEstadoCeldaStock);
var
  Columna: TcxGridDBColumn;
  Registro: TcxCustomGridRecord;
  i: Integer;
begin
  AEstado.EsModoTodo := FEsModoTodo;
  AEstado.EsModoColor := FEsModoColor;
  SetLength(AEstado.Tallas, Length(FTallas));
  for i := 0 to High(FTallas) do
    AEstado.Tallas[i] := FTallas[i].Codigo;
  Registro := FVista.Controller.FocusedRecord;
  AEstado.HayFila := Registro <> nil;
  Columna := ColumnaEnfocada;
  if Columna <> nil then
  begin
    AEstado.HayColumnaDeDatos := True;
    AEstado.NombreCampo := Columna.DataBinding.FieldName;
  end;
  if AEstado.HayFila and (FColumnaEstado <> nil) then
    AEstado.FilaEsExistencias :=
      StrToIntDef(
        VarToStr(Registro.Values[FColumnaEstado.Index]), -1) =
        Ord(esExistencias);
  if AEstado.HayFila and (FColumnaGrupo <> nil) then
  begin
    AEstado.HayColumnaGrupo := True;
    AEstado.Grupo := VarToStr(Registro.Values[FColumnaGrupo.Index]);
  end;
end;

end.
