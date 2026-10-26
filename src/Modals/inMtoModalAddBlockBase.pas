{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddBlockBase                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.1                                                         }
{   Fecha:       22/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal base para carga masiva de articulos con filtros.                    }
{    NO instanciar directamente; usar las clases hijas (Tarifa/Inventario).    }
{******************************************************************************}
unit inMtoModalAddBlockBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus,
  Data.DB,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxClasses, cxContainer, cxEdit, cxLabel, cxButtons,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxCurrencyEdit,
  cxSpinEdit, cxCheckBox, cxRadioGroup, cxPC, cxSplitter,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxGridDBDataDefinitions,
  cxTL, cxTLData, cxDBTL, cxInplaceContainer,
  cxCheckListBox, cxCustomListBox,
  dxSkinsCore, dxSkinsForm, dxSkinsDefaultPainters, dxSkinBlue,
  dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges, dxCore,
  cxLocalization,
  inMtoFrmBase, Vcl.ComCtrls, cxDateUtils, cxGroupBox, JvComponentBase,
  JvEnterTab, System.UITypes,
  inLibCargaMasivaArticulosPersistenciaIntf;

type
  // Resultado base. Los hijos pueden extender con un record propio si necesitan
  // mas campos (p.ej. tarifa: precio_dto, ajuste; inventario: numero_inv).
  TAddBlockBaseResult = record
    Aceptado          : Boolean;
    NumInsertados     : Integer;
    ArticulosCodigos  : TArray<string>;
  end;

  TfrmModalAddBlockBase = class(TfrmBase)
    // Cabecera EXTRA: panel vacio donde los hijos meten sus controles
    // especificos. La base solo coloca el panel, los hijos lo llenan.
    pnlCabeceraExtra: TPanel;

    // Cabecera comun: filtros base
    pnlCabeceraComun: TPanel;
      chkSoloActivos: TcxCheckBox;
      chkExcluirYaCargados: TcxCheckBox;   // hijos definen el texto y la query
      chkSoloConStock: TcxCheckBox;
      lblStockAviso: TcxLabel;
      btnPrevisualizar: TcxButton;
      btnLimpiarFiltros: TcxButton;

    // Filtros (pestañas)
    pcFiltros: TcxPageControl;
      tsFamilias: TcxTabSheet;
        pnlFamiliasTop: TPanel;
          chkPropagarHijos: TcxCheckBox;
          btnExpandirFamilias: TcxButton;
          btnContraerFamilias: TcxButton;
          btnQuitarSelFamilias: TcxButton;
          lblSelFamilias: TcxLabel;
        tlFamilias: TcxDBTreeList;
          tlcolFamiliasNombre: TcxDBTreeListColumn;
          tlcolFamiliasCodigo: TcxDBTreeListColumn;

      tsProveedores: TcxTabSheet;
        pnlProveedoresTop: TPanel;
          edtFiltroProveedor: TcxTextEdit;
          chkSoloPrincipal: TcxCheckBox;
          btnQuitarSelProveedores: TcxButton;
          lblSelProveedores: TcxLabel;
        grdProveedores: TcxGrid;
          tvProveedores: TcxGridDBTableView;
            colProvCodigo: TcxGridDBColumn;
            colProvRazonSocial: TcxGridDBColumn;
            colProvNif: TcxGridDBColumn;
          lvProveedores: TcxGridLevel;

      tsPropiedades: TcxTabSheet;
        pnlPropiedadesTop: TPanel;
          lblPropiedad: TcxLabel;
          cbxPropiedad: TcxComboBox;
          btnQuitarSelPropiedades: TcxButton;
          lblSelPropiedades: TcxLabel;
        grdPropValores: TcxGrid;
          tvPropValores: TcxGridDBTableView;
            colPropIdValor: TcxGridDBColumn;
            colPropPropiedad: TcxGridDBColumn;
            colPropValor: TcxGridDBColumn;
          lvPropValores: TcxGridLevel;

      tsAlmacenes: TcxTabSheet;
        pnlAlmacenesTop: TPanel;
          lblAlmacenInfo: TcxLabel;
          rgStockCombinacion: TcxRadioGroup;
          btnMarcarTodosAlm: TcxButton;
        btnDesmarcarTodosAlm: TcxButton;
        lblSelAlmacenes: TcxLabel;
        lblReservaStockOrigen: TcxLabel;
        spnReservaStockOrigen: TcxSpinEdit;
        lblMaximoServirPorSku: TcxLabel;
        spnMaximoServirPorSku: TcxSpinEdit;
      chkLstAlmacenes: TcxCheckListBox;

      tsFechaAlta: TcxTabSheet;
        chkAplicarFechaAlta: TcxCheckBox;
        lblAltaDesde: TcxLabel;
        dtAltaDesde: TcxDateEdit;
        lblAltaHasta: TcxLabel;
        dtAltaHasta: TcxDateEdit;

      tsVentas: TcxTabSheet;
        chkConVenta: TcxCheckBox;
        lblVtaDesde: TcxLabel;
        dtVtaDesde: TcxDateEdit;
        lblVtaHasta: TcxLabel;
        dtVtaHasta: TcxDateEdit;
        rgConSinVenta: TcxRadioGroup;
        lblNumMinVtas: TcxLabel;
        spnNumMinVtas: TcxSpinEdit;
        lblAlmacenesVentas: TcxLabel;
        chkLstAlmacenesVentas: TcxCheckListBox;
        chkFiltrarStockAlmacenVenta: TcxCheckBox;
        lblStockMaximoAlmacenVenta: TcxLabel;
        spnStockMaximoAlmacenVenta: TcxSpinEdit;

    splitterPreview: TcxSplitter;
    pnlPreview: TPanel;
      lblPreviewInfo: TcxLabel;
      grdPreview: TcxGrid;
        tvPreview: TcxGridDBTableView;
          colPrevCodigo: TcxGridDBColumn;
          colPrevDescripcion: TcxGridDBColumn;
          colPrevFamilia: TcxGridDBColumn;
          colPrevProveedor: TcxGridDBColumn;
          colPrevStock: TcxGridDBColumn;
          colPrevYaCargado: TcxGridDBColumn;
        lvPreview: TcxGridLevel;

    pnlBotonera: TPanel;
      btnAceptar: TcxButton;
      btnCancelar: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    procedure btnPrevisualizarClick(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnLimpiarFiltrosClick(Sender: TObject);

    procedure tlFamiliasNodeCheckChanged(Sender: TcxCustomTreeList;
                                         ANode: TcxTreeListNode;
                                         AState: TcxCheckBoxState);
    procedure btnExpandirFamiliasClick(Sender: TObject);
    procedure btnContraerFamiliasClick(Sender: TObject);
    procedure btnQuitarSelFamiliasClick(Sender: TObject);
    procedure btnQuitarSelProveedoresClick(Sender: TObject);
    procedure btnQuitarSelPropiedadesClick(Sender: TObject);
    procedure btnMarcarTodosAlmClick(Sender: TObject);
    procedure btnDesmarcarTodosAlmClick(Sender: TObject);

    procedure cbxPropiedadPropertiesChange(Sender: TObject);
    procedure edtFiltroProveedorPropertiesChange(Sender: TObject);
    procedure tvProveedoresSelectionChanged(Sender: TcxCustomGridTableView);
    procedure tvPropValoresSelectionChanged(Sender: TcxCustomGridTableView);
    procedure chkLstAlmacenesClickCheck(Sender: TObject);

  protected
    FBaseResultado : TAddBlockBaseResult;
    FPropagandoCheck: Boolean;
    FServicios: TServiciosCargaMasivaArticulos;
    FConsultaFamilias: IConsultaCargaMasivaArticulos;
    FConsultaProveedores: IConsultaCargaMasivaArticulos;
    FConsultaPropValores: IConsultaCargaMasivaArticulos;
    FConsultaPreview: IConsultaCargaMasivaArticulos;
    FFamilias: TDataSet;
    FProveedores: TDataSet;
    FPropValores: TDataSet;
    FDatosPreview: TDataSet;
    FDsFamilias    : TDataSource;
    FDsProveedores : TDataSource;
    FDsPropValores : TDataSource;
    FDsPreview     : TDataSource;
    // FZ-ISSUE-324: unidad del artículo (oculta) para el formato del stock
    FColPrevUnidad: TcxGridDBColumn;
    FCodigosPropiedades: TStringList;
    FCodigosAlmacenesVentas: TStringList;
    FReservaStockOrigenDefecto: Double;
    FMaximoServirPorSkuDefecto: Double;
    FFiltrarStockAlmacenVentaDefecto: Boolean;
    FStockMaximoAlmacenVentaDefecto: Double;

    // === HOOKS para descendientes ============================================

    // Validaciones extra antes de previsualizar.
    // Si devuelve False, el preview no se ejecuta.
    function  ValidarAntesDePrevisualizar(out AMensaje: string): Boolean;
    virtual;

    function ContextoCargaMasiva: TContextoCargaMasivaArticulos;
      virtual; abstract;

    // Mensaje de confirmacion antes de aceptar
    function  TextoConfirmacion(ANumPendientes: Integer): string; virtual;

    // Mensaje de exito tras insertar
    function  TextoExito(ANumInsertados: Integer): string; virtual;

    // Texto de los checkboxes "excluir ya en tarifa/inventario"
    function  TextoExcluirYaCargados: string; virtual;

    // Despues de cargar el preview, los hijos pueden ajustar columnas
    procedure ConfigurarPreviewExtra; virtual;

    // Resumen que se muestra sobre el grid de previsualizacion.
    function TextoResumenPreview(ANumeroRegistros: Integer): string; virtual;

    // INSERCION REAL — el corazon especifico de cada hijo
    function  EjecutarInsercion(out ANumInsertados: Integer;
                                out ACodigos: TArray<string>): Boolean;
                                virtual; abstract;

    // === API que los hijos pueden invocar ===================================

    // Recogida de selecciones (los hijos pueden usarlas en su
    // EjecutarInsercion)
    function  RecogerCodigosFamiliaSeleccionados: TArray<string>;
    function  RecogerCodigosProveedoresSeleccionados: TArray<string>;
    function  RecogerIdsValorPropiedadSeleccionados: TArray<Integer>;
    function  RecogerCodigosAlmacenesSeleccionados: TArray<string>;
    function  RecogerCodigosAlmacenesVentasSeleccionados: TArray<string>;

    function StockCombinacionActual: TStockCombinacionCargaMasiva;
    function RecogerFiltros: TFiltrosCargaMasivaArticulos; virtual;
    function GetConsultasCargaMasiva: IConsultasCargaMasivaArticulos;
    function GetInsercionesCargaMasiva: IInsercionesCargaMasivaArticulos;

    // Carga de datos auxiliares (los hijos las llaman desde su Ejecutar)
    procedure CargarFiltrosAuxiliares;
    procedure CargarFamilias;
    procedure CargarProveedores;
    procedure CargarPropiedades;
    procedure CargarValoresPropiedad(const ACodigoPropiedad: string);
    procedure CargarAlmacenes;
    procedure PreseleccionarAlmacenVentasSesion;
    procedure ConfigurarValoresReposicionDefecto(
      AReservaStockOrigen, AMaximoServirPorSku: Double;
      AFiltrarStockAlmacenVenta: Boolean;
      AStockMaximoAlmacenVenta: Double);

    property ConsultasCargaMasiva: IConsultasCargaMasivaArticulos
      read GetConsultasCargaMasiva;
    property InsercionesCargaMasiva: IInsercionesCargaMasivaArticulos
      read GetInsercionesCargaMasiva;
    property ConsultaPreview: IConsultaCargaMasivaArticulos
      read FConsultaPreview;
    property DatosPreview: TDataSet read FDatosPreview;

  private
    function  EsNodoChecked(ANode: TcxTreeListNode): Boolean;
    procedure SetNodoChecked(ANode: TcxTreeListNode; AValue: Boolean);
    procedure PropagarCheckHijos(ANode: TcxTreeListNode; AValue: Boolean);
    procedure ActualizarContadores;

  public
    constructor Create(
      AOwner: TComponent;
      const AServicios: TServiciosCargaMasivaArticulos); reintroduce;
      overload;
    procedure Inicializar;

    property BaseResultado: TAddBlockBaseResult read FBaseResultado;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibUser, inLibMsgArticulos, inLibMsgComun,
  UniDataConfiguracionPantalla, inLibGridCantidad;

resourcestring
  SCaptionExcluirArticulosYaCargados =
    'Excluir articulos ya cargados';
  SItemTodasPropiedadesAddBlock =
    '(todas - ver todos los valores)';

// ============================================================================
//   API publica del hijo
// ============================================================================

constructor TfrmModalAddBlockBase.Create(
  AOwner: TComponent;
  const AServicios: TServiciosCargaMasivaArticulos);
begin
  ValidarServiciosCargaMasiva(AServicios);
  FServicios := AServicios;
  inherited Create(AOwner);
end;

procedure TfrmModalAddBlockBase.Inicializar;
begin
  CargarFiltrosAuxiliares;
end;

procedure TfrmModalAddBlockBase.CargarFiltrosAuxiliares;
begin
  CargarFamilias;
  CargarProveedores;
  CargarPropiedades;
  CargarAlmacenes;

  // Aplicar caption del checkbox excluir-ya-cargados
  chkExcluirYaCargados.Caption := TextoExcluirYaCargados;
end;

// ============================================================================
//   HOOKS por defecto
// ============================================================================

function TfrmModalAddBlockBase.ValidarAntesDePrevisualizar(
  out AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result   := True;
end;

function TfrmModalAddBlockBase.TextoConfirmacion(
  ANumPendientes: Integer): string;
begin
  Result := Format(SPreguntaConfirmarAddBlock,
                   [ANumPendientes]);
end;

function TfrmModalAddBlockBase.TextoExito(ANumInsertados: Integer): string;
begin
  Result := Format(SInfoArticulosAnadidosAddBlock, [ANumInsertados]);
end;

function TfrmModalAddBlockBase.TextoExcluirYaCargados: string;
begin
  Result := SCaptionExcluirArticulosYaCargados;
end;

procedure TfrmModalAddBlockBase.ConfigurarPreviewExtra;
begin
  // override en hijos para añadir columnas extra al grid
end;

function TfrmModalAddBlockBase.TextoResumenPreview(
  ANumeroRegistros: Integer): string;
begin
  Result := Format(
    SCaptionArticulosCoincidenFiltro,
    [ANumeroRegistros]);
end;

// ============================================================================
//   FORM CREATE / CLOSE
// ============================================================================

procedure TfrmModalAddBlockBase.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poMainFormCenter;
  FBaseResultado.Aceptado := False;
  FPropagandoCheck    := False;
  ValidarServiciosCargaMasiva(FServicios);
  FCodigosPropiedades := TStringList.Create;
  FCodigosAlmacenesVentas := TStringList.Create;
  FDsFamilias     := TDataSource.Create(Self);
  FDsProveedores  := TDataSource.Create(Self);
  FDsPropValores  := TDataSource.Create(Self);
  FDsPreview      := TDataSource.Create(Self);

  // Defaults
  dtAltaDesde.Date := Date - 365;
  dtAltaHasta.Date := Date;
  dtVtaDesde.Date  := Date - 365;
  dtVtaHasta.Date  := Date;
  chkSoloActivos.Checked       := True;
  chkExcluirYaCargados.Checked := True;
  chkSoloConStock.Checked      := False;
  chkPropagarHijos.Checked     := True;
  rgStockCombinacion.ItemIndex := 0;
  ConfigurarValoresReposicionDefecto(0, 1, False, 0);
end;

procedure TfrmModalAddBlockBase.ConfigurarValoresReposicionDefecto(
  AReservaStockOrigen, AMaximoServirPorSku: Double;
  AFiltrarStockAlmacenVenta: Boolean;
  AStockMaximoAlmacenVenta: Double);
begin
  FReservaStockOrigenDefecto := AReservaStockOrigen;
  FMaximoServirPorSkuDefecto := AMaximoServirPorSku;
  FFiltrarStockAlmacenVentaDefecto := AFiltrarStockAlmacenVenta;
  FStockMaximoAlmacenVentaDefecto := AStockMaximoAlmacenVenta;
  spnReservaStockOrigen.Value := FReservaStockOrigenDefecto;
  spnMaximoServirPorSku.Value := FMaximoServirPorSkuDefecto;
  chkFiltrarStockAlmacenVenta.Checked :=
    FFiltrarStockAlmacenVentaDefecto;
  spnStockMaximoAlmacenVenta.Value :=
    FStockMaximoAlmacenVentaDefecto;
end;

procedure TfrmModalAddBlockBase.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
  i: Integer;
begin
  // Liberar los TStringList que cuelgan de los items del CheckListBox
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    if chkLstAlmacenes.Items[i].ItemObject is TStringList then
    begin
      chkLstAlmacenes.Items[i].ItemObject.Free;
      chkLstAlmacenes.Items[i].ItemObject := nil;
    end;

  FreeAndNil(FCodigosPropiedades);
  FreeAndNil(FCodigosAlmacenesVentas);
  if Assigned(FDsFamilias) then
    FDsFamilias.DataSet := nil;
  if Assigned(FDsProveedores) then
    FDsProveedores.DataSet := nil;
  if Assigned(FDsPropValores) then
    FDsPropValores.DataSet := nil;
  if Assigned(FDsPreview) then
    FDsPreview.DataSet := nil;
  FFamilias := nil;
  FProveedores := nil;
  FPropValores := nil;
  FDatosPreview := nil;
  FConsultaFamilias := nil;
  FConsultaProveedores := nil;
  FConsultaPropValores := nil;
  FConsultaPreview := nil;
  FServicios.Consultas := nil;
  FServicios.Inserciones := nil;
  inherited;
  Action := caHide;
end;

// ============================================================================
//   CARGA DE DATOS
// ============================================================================

procedure TfrmModalAddBlockBase.CargarFamilias;

  // Habilita la casilla de verificacion en ANode y, recursivamente, en toda
  // su descendencia. OptionsView.CheckGroups solo activa el mecanismo: es el
  // CheckGroupType de cada nodo (ncgCheckGroup) el que hace que se pinte la
  // casilla de sus hijos. Con el valor por defecto (ncgNone) no se muestra
  // ninguna casilla y CheckState devuelve siempre cbsUnchecked, por lo que
  // el filtro de familias nunca recogia nada. Es idempotente, asi que da
  // igual si Count/Items recorre raices o nodos absolutos.
  procedure HabilitarCasillas(ANode: TcxTreeListNode);
  var
    j: Integer;
  begin
    ANode.CheckGroupType := ncgCheckGroup;
    for j := 0 to ANode.Count - 1 do
      HabilitarCasillas(ANode.Items[j]);
  end;

var
  i: Integer;
begin
  FConsultaFamilias := FServicios.Consultas.ConsultarFamilias;
  FFamilias := FConsultaFamilias.DataSet;
  FDsFamilias.DataSet := FFamilias;
  tlFamilias.BeginUpdate;
  try
    tlFamilias.DataController.DataSource := FDsFamilias;
    tlFamilias.DataController.KeyField    := 'CODIGO_FAM_FAM';
    tlFamilias.DataController.ParentField := 'CODIGO_PADRE';
    tlFamilias.RootValue := '';
  finally
    tlFamilias.EndUpdate;
  end;
  tlFamilias.FullExpand;
  // Pintar la casilla en los nodos raiz (lo gobierna el Root) y en el resto.
  tlFamilias.Root.CheckGroupType := ncgCheckGroup;
  for i := 0 to tlFamilias.Count - 1 do
    HabilitarCasillas(tlFamilias.Items[i]);
end;

procedure TfrmModalAddBlockBase.CargarProveedores;
begin
  FConsultaProveedores := FServicios.Consultas.ConsultarProveedores;
  FProveedores := FConsultaProveedores.DataSet;
  FDsProveedores.DataSet := FProveedores;
  tvProveedores.DataController.DataSource := FDsProveedores;
end;

procedure TfrmModalAddBlockBase.CargarPropiedades;
var
  aPropiedades: TPropiedadesCargaMasiva;
  oPropiedad: TPropiedadCargaMasiva;
  iPropiedadDefecto: Integer;
begin
  aPropiedades := FServicios.Consultas.ListarPropiedades;
  cbxPropiedad.Properties.Items.Clear;
  FCodigosPropiedades.Clear;
  cbxPropiedad.Properties.Items.Add(SItemTodasPropiedadesAddBlock);
  FCodigosPropiedades.Add('');
  for oPropiedad in aPropiedades do
  begin
    cbxPropiedad.Properties.Items.Add(oPropiedad.Nombre);
    FCodigosPropiedades.Add(oPropiedad.Codigo);
  end;
  iPropiedadDefecto := FCodigosPropiedades.IndexOf('TEMPORADA');
  if iPropiedadDefecto < 0 then
  begin
    iPropiedadDefecto := 0;
  end;
  cbxPropiedad.ItemIndex := iPropiedadDefecto;
  CargarValoresPropiedad(FCodigosPropiedades[iPropiedadDefecto]);
end;

procedure TfrmModalAddBlockBase.CargarValoresPropiedad(
  const ACodigoPropiedad: string);
begin
  FDsPropValores.DataSet := nil;
  FPropValores := nil;
  FConsultaPropValores :=
    FServicios.Consultas.ConsultarValoresPropiedad(ACodigoPropiedad);
  FPropValores := FConsultaPropValores.DataSet;
  FDsPropValores.DataSet := FPropValores;
  tvPropValores.DataController.DataSource := FDsPropValores;
  // Al filtrar una propiedad queda un único grupo; debe mostrar sus valores.
  tvPropValores.DataController.Groups.FullExpand;
end;

procedure TfrmModalAddBlockBase.CargarAlmacenes;
var
  aAlmacenes: TAlmacenesCargaMasiva;
  oAlmacen: TAlmacenCargaMasiva;
  it: TcxCheckListBoxItem;
begin
  chkLstAlmacenes.Items.Clear;
  chkLstAlmacenesVentas.Items.Clear;
  FCodigosAlmacenesVentas.Clear;
  aAlmacenes := FServicios.Consultas.ListarAlmacenes;
  for oAlmacen in aAlmacenes do
  begin
    it := chkLstAlmacenes.Items.Add;
    it.Text := oAlmacen.Codigo + ' - ' + oAlmacen.Nombre;
    it.ItemObject := TStringList.Create;
    TStringList(it.ItemObject).Add(oAlmacen.Codigo);

    it := chkLstAlmacenesVentas.Items.Add;
    it.Text := oAlmacen.Codigo + ' - ' + oAlmacen.Nombre;
    FCodigosAlmacenesVentas.Add(oAlmacen.Codigo);
  end;
  PreseleccionarAlmacenVentasSesion;
end;

procedure TfrmModalAddBlockBase.PreseleccionarAlmacenVentasSesion;
var
  CodigoAlmacenSesion: string;
  i: Integer;
begin
  CodigoAlmacenSesion := '';
  if Assigned(ContextoSesion) then
    CodigoAlmacenSesion := UbicacionSesion.Almacen;
  for i := 0 to chkLstAlmacenesVentas.Items.Count - 1 do
    chkLstAlmacenesVentas.Items[i].Checked :=
      SameText(FCodigosAlmacenesVentas[i], CodigoAlmacenSesion);
end;

// ============================================================================
//   ARBOL DE FAMILIAS
// ============================================================================

function TfrmModalAddBlockBase.EsNodoChecked(ANode: TcxTreeListNode): Boolean;
begin
  // El arbol usa OptionsView.CheckGroups (casillas por nodo). El estado de
  // marcado vive en CheckState, NO en Selected (que es solo el resaltado de
  // fila). Leer Selected hacia que RecogerCodigosFamiliaSeleccionados saliera
  // vacio y el filtro de familias nunca se aplicara en la SQL del preview.
  Result := ANode.CheckState = cbsChecked;
end;

procedure TfrmModalAddBlockBase.SetNodoChecked(ANode: TcxTreeListNode;
  AValue: Boolean);
begin
  if AValue then
    ANode.CheckState := cbsChecked
  else
    ANode.CheckState := cbsUnchecked;
end;

procedure TfrmModalAddBlockBase.tlFamiliasNodeCheckChanged(
  Sender: TcxCustomTreeList; ANode: TcxTreeListNode;
  AState: TcxCheckBoxState);
begin
  // Al marcar/desmarcar una familia propagamos el mismo estado a todas sus
  // subfamilias (cuando el usuario tiene activado "Propagar seleccion a
  // subfamilias"). FPropagandoCheck evita la reentrada: al fijar el CheckState
  // de cada hijo se vuelve a disparar este mismo evento. El estado intermedio
  // cbsGrayed (familia con hijos parcialmente marcados) se ignora para no
  // desmarcar en cascada lo que el usuario acaba de marcar.
  if (not FPropagandoCheck) and chkPropagarHijos.Checked and
     (ANode <> nil) and (AState <> cbsGrayed) then
  begin
    FPropagandoCheck := True;
    try
      PropagarCheckHijos(ANode, AState = cbsChecked);
    finally
      FPropagandoCheck := False;
    end;
    ActualizarContadores;
  end;
end;

procedure TfrmModalAddBlockBase.PropagarCheckHijos(ANode: TcxTreeListNode;
  AValue: Boolean);
var
  i: Integer;
begin
  for i := 0 to ANode.Count - 1 do
  begin
    SetNodoChecked(ANode.Items[i], AValue);
    PropagarCheckHijos(ANode.Items[i], AValue);
  end;
end;

procedure TfrmModalAddBlockBase.btnExpandirFamiliasClick(Sender: TObject);
begin
  tlFamilias.FullExpand;
end;

procedure TfrmModalAddBlockBase.btnContraerFamiliasClick(Sender: TObject);
begin
  tlFamilias.FullCollapse;
end;

procedure TfrmModalAddBlockBase.btnQuitarSelFamiliasClick(Sender: TObject);

  procedure ClearRec(N: TcxTreeListNode);
  var i: Integer;
  begin
    SetNodoChecked(N, False);
    for i := 0 to N.Count - 1 do ClearRec(N.Items[i]);
  end;

var
  i: Integer;
begin
  FPropagandoCheck := True;
  try
    for i := 0 to tlFamilias.Count - 1 do
      ClearRec(tlFamilias.Items[i]);
  finally
    FPropagandoCheck := False;
  end;
  ActualizarContadores;
end;

// ============================================================================
//   RESTO DE EVENTOS
// ============================================================================

procedure TfrmModalAddBlockBase.btnQuitarSelProveedoresClick(Sender: TObject);
begin
  tvProveedores.DataController.ClearSelection;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnQuitarSelPropiedadesClick(Sender: TObject);
begin
  tvPropValores.DataController.ClearSelection;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnMarcarTodosAlmClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    chkLstAlmacenes.Items[i].Checked := True;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnDesmarcarTodosAlmClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    chkLstAlmacenes.Items[i].Checked := False;
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.cbxPropiedadPropertiesChange(Sender: TObject);
var
  idx: Integer;
  cod: string;
begin
  idx := cbxPropiedad.ItemIndex;
  if (idx >= 0) and (idx < FCodigosPropiedades.Count) then
  begin
    cod := FCodigosPropiedades[idx];
    CargarValoresPropiedad(cod);
  end;
end;

procedure TfrmModalAddBlockBase.edtFiltroProveedorPropertiesChange(
  Sender: TObject);
var
  txt: string;
begin
  txt := Trim(edtFiltroProveedor.Text);
  if txt = '' then
    FProveedores.Filtered := False
  else
  begin
    FProveedores.Filter :=
      Format('RAZON_SOCIAL_PRV LIKE ''%%%s%%''',
             [StringReplace(txt, '''', '''''', [rfReplaceAll])]);
    FProveedores.Filtered := True;
  end;
end;

procedure TfrmModalAddBlockBase.tvProveedoresSelectionChanged(
  Sender: TcxCustomGridTableView);
begin
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.tvPropValoresSelectionChanged(
  Sender: TcxCustomGridTableView);
begin
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.chkLstAlmacenesClickCheck(Sender: TObject);
begin
  ActualizarContadores;
end;

procedure TfrmModalAddBlockBase.btnLimpiarFiltrosClick(Sender: TObject);
var
  i: Integer;
begin
  if MessageDlg_fza(SPreguntaLimpiarFiltrosAddBlock, mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    btnQuitarSelFamiliasClick(nil);
    tvProveedores.DataController.ClearSelection;
    tvPropValores.DataController.ClearSelection;
    cbxPropiedad.ItemIndex := 0;
    CargarValoresPropiedad('');
    edtFiltroProveedor.Text := '';
    chkAplicarFechaAlta.Checked := False;
    chkConVenta.Checked := False;
    chkSoloConStock.Checked := False;
    spnReservaStockOrigen.Value := FReservaStockOrigenDefecto;
    spnMaximoServirPorSku.Value := FMaximoServirPorSkuDefecto;
    chkFiltrarStockAlmacenVenta.Checked :=
      FFiltrarStockAlmacenVentaDefecto;
    spnStockMaximoAlmacenVenta.Value :=
      FStockMaximoAlmacenVentaDefecto;
    PreseleccionarAlmacenVentasSesion;
    for i := 0 to chkLstAlmacenes.Items.Count - 1 do
      chkLstAlmacenes.Items[i].Checked := False;
    if Assigned(FDatosPreview) and FDatosPreview.Active then
      FDatosPreview.Close;
    lblPreviewInfo.Caption := SCaptionCeroArticulos;
    ActualizarContadores;
  end;
end;

procedure TfrmModalAddBlockBase.ActualizarContadores;
var
  i, n: Integer;
begin
  lblSelFamilias.Caption := Format(SCaptionNumSeleccionados,
    [Length(RecogerCodigosFamiliaSeleccionados)]);
  lblSelProveedores.Caption := Format(SCaptionNumSeleccionados,
    [Length(RecogerCodigosProveedoresSeleccionados)]);
  lblSelPropiedades.Caption := Format(SCaptionNumSeleccionados,
    [Length(RecogerIdsValorPropiedadSeleccionados)]);

  n := 0;
  for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    if chkLstAlmacenes.Items[i].Checked then Inc(n);
  lblSelAlmacenes.Caption := Format(SCaptionNumSeleccionados, [n]);

  if chkSoloConStock.Checked then
  begin
    if n = 0 then
      lblStockAviso.Caption := SCaptionSinAlmacenesSeleccionados
    else
      lblStockAviso.Caption :=
        Format(SCaptionAlmacenesSeleccionados, [n]);
  end
  else
    lblStockAviso.Caption := '';
end;

// ============================================================================
//   RECOGIDA DE SELECCIONES
// ============================================================================

function TfrmModalAddBlockBase.
  RecogerCodigosFamiliaSeleccionados: TArray<string>;
var
  lst: TList<string>;

  procedure Recorrer(ANode: TcxTreeListNode);
  var
    i: Integer;
    v: Variant;
  begin
    if EsNodoChecked(ANode) then
    begin
      v := ANode.Values[tlcolFamiliasCodigo.ItemIndex];
      if not VarIsNull(v) then
        lst.Add(VarToStr(v));
    end;
    for i := 0 to ANode.Count - 1 do
      Recorrer(ANode.Items[i]);
  end;

var
  i: Integer;
begin
  lst := TList<string>.Create;
  try
    for i := 0 to tlFamilias.Count - 1 do
      Recorrer(tlFamilias.Items[i]);
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.
  RecogerCodigosProveedoresSeleccionados: TArray<string>;
var
  lst: TList<string>;
  i, n, recIdx: Integer;
  dc: TcxGridDBDataController;
begin
  lst := TList<string>.Create;
  try
    dc := tvProveedores.DataController;
    n  := dc.GetSelectedCount;
    for i := 0 to n - 1 do
    begin
      recIdx := dc.GetSelectedRowIndex(i);
      lst.Add(VarToStr(dc.Values[recIdx, colProvCodigo.Index]));
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.
  RecogerIdsValorPropiedadSeleccionados: TArray<Integer>;
var
  lst: TList<Integer>;
  i, n, recIdx: Integer;
  dc: TcxGridDBDataController;
  v: Variant;
begin
  lst := TList<Integer>.Create;
  try
    dc := tvPropValores.DataController;
    n  := dc.GetSelectedCount;
    for i := 0 to n - 1 do
    begin
      recIdx := dc.GetSelectedRowIndex(i);
      v := dc.Values[recIdx, colPropIdValor.Index];
      if not VarIsNull(v) then
        lst.Add(StrToIntDef(VarToStr(v), 0));
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.
  RecogerCodigosAlmacenesSeleccionados: TArray<string>;
var
  lst: TList<string>;
  i: Integer;
  it: TcxCheckListBoxItem;
begin
  lst := TList<string>.Create;
  try
    for i := 0 to chkLstAlmacenes.Items.Count - 1 do
    begin
      it := chkLstAlmacenes.Items[i];
      if it.Checked and (it.ItemObject is TStringList) and
         (TStringList(it.ItemObject).Count > 0) then
        lst.Add(TStringList(it.ItemObject)[0]);
    end;
    Result := lst.ToArray;
  finally
    FreeAndNil(lst);
  end;
end;

function TfrmModalAddBlockBase.StockCombinacionActual:
  TStockCombinacionCargaMasiva;
begin
  case rgStockCombinacion.ItemIndex of
    1:
      Result := scTodos;
    2:
      Result := scSumaPositiva;
  else
    Result := scCualquiera;
  end;
end;

function TfrmModalAddBlockBase.
  RecogerCodigosAlmacenesVentasSeleccionados: TArray<string>;
var
  Codigos: TList<string>;
  i: Integer;
begin
  Codigos := TList<string>.Create;
  try
    for i := 0 to chkLstAlmacenesVentas.Items.Count - 1 do
      if chkLstAlmacenesVentas.Items[i].Checked and
         (i < FCodigosAlmacenesVentas.Count) then
        Codigos.Add(FCodigosAlmacenesVentas[i]);
    Result := Codigos.ToArray;
  finally
    FreeAndNil(Codigos);
  end;
end;

function TfrmModalAddBlockBase.RecogerFiltros:
  TFiltrosCargaMasivaArticulos;
begin
  Result.SoloActivos := chkSoloActivos.Checked;
  Result.ExcluirYaCargados := chkExcluirYaCargados.Checked;
  Result.SoloConStock := chkSoloConStock.Checked;
  Result.SoloNegativos := False;
  Result.PropagarFamilias := chkPropagarHijos.Checked;
  Result.SoloProveedorPrincipal := chkSoloPrincipal.Checked;
  Result.AplicarFechaAlta := chkAplicarFechaAlta.Checked;
  Result.FiltrarVentas := chkConVenta.Checked;
  Result.ConVentas := rgConSinVenta.ItemIndex = 0;
  // Sin almacenes de ventas marcados no hay destino con el que comparar el
  // stock: el filtro no se aplica en lugar de exigir que se marque uno.
  Result.FiltrarStockAlmacenVenta :=
    chkFiltrarStockAlmacenVenta.Checked and
    (Length(RecogerCodigosAlmacenesVentasSeleccionados) > 0);
  Result.FechaAltaDesde := dtAltaDesde.Date;
  Result.FechaAltaHasta := dtAltaHasta.Date;
  Result.VentaDesde := dtVtaDesde.Date;
  Result.VentaHasta := dtVtaHasta.Date;
  Result.NumeroMinimoVentas := spnNumMinVtas.Value;
  Result.ReservaStockOrigen := spnReservaStockOrigen.Value;
  Result.MaximoServirPorSku := spnMaximoServirPorSku.Value;
  Result.StockMaximoAlmacenVenta :=
    spnStockMaximoAlmacenVenta.Value;
  Result.StockCombinacion := StockCombinacionActual;
  Result.CodigosFamilia := RecogerCodigosFamiliaSeleccionados;
  Result.CodigosProveedor := RecogerCodigosProveedoresSeleccionados;
  Result.IdsValorPropiedad := RecogerIdsValorPropiedadSeleccionados;
  Result.CodigosAlmacen := RecogerCodigosAlmacenesSeleccionados;
  Result.CodigosAlmacenVenta :=
    RecogerCodigosAlmacenesVentasSeleccionados;
end;

function TfrmModalAddBlockBase.GetConsultasCargaMasiva:
  IConsultasCargaMasivaArticulos;
begin
  Result := FServicios.Consultas;
end;

function TfrmModalAddBlockBase.GetInsercionesCargaMasiva:
  IInsercionesCargaMasivaArticulos;
begin
  Result := FServicios.Inserciones;
end;

// ============================================================================
//   PREVIEW Y ACEPTAR
// ============================================================================

procedure TfrmModalAddBlockBase.btnPrevisualizarClick(Sender: TObject);
var
  sMensaje: string;
begin
  if not ValidarAntesDePrevisualizar(sMensaje) then
  begin
    if sMensaje <> '' then
    begin
      ShowMessage_fza(sMensaje);
    end;
  end
  else if chkSoloConStock.Checked and
          (Length(RecogerCodigosAlmacenesSeleccionados) = 0) then
  begin
    ShowMessage_fza(SErrorAlmacenesSoloStockAddBlock);
    pcFiltros.ActivePage := tsAlmacenes;
  end
  else if chkLstAlmacenesVentas.Visible and chkConVenta.Checked and
          (Length(RecogerCodigosAlmacenesVentasSeleccionados) = 0) then
  begin
    ShowMessage_fza(SErrorAlmacenesVentasAddBlock);
    pcFiltros.ActivePage := tsVentas;
  end
  else
  begin
    Screen.Cursor := crHourGlass;
    try
      FDsPreview.DataSet := nil;
      FDatosPreview := nil;
      FConsultaPreview := FServicios.Consultas.Previsualizar(
        RecogerFiltros,
        ContextoCargaMasiva);
      FDatosPreview := FConsultaPreview.DataSet;
      FDsPreview.DataSet := FDatosPreview;
      tvPreview.DataController.DataSource := FDsPreview;
      // FZ-ISSUE-324: el stock con los decimales de la unidad (kg: 3)
      if (FColPrevUnidad = nil) and
         (FDatosPreview.FindField('TIPO_CANTIDAD_ART') <> nil) then
      begin
        FColPrevUnidad := tvPreview.CreateColumn;
        FColPrevUnidad.DataBinding.FieldName := 'TIPO_CANTIDAD_ART';
        FColPrevUnidad.Visible := False;
        VincularCantidadGrid(colPrevStock, FColPrevUnidad, UnidadesMedida,
          False);
      end;
      ConfigurarPreviewExtra;
      lblPreviewInfo.Caption := TextoResumenPreview(
        FDatosPreview.RecordCount);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmModalAddBlockBase.btnAceptarClick(Sender: TObject);
var
  numIns     : Integer;
  codigos    : TArray<string>;
  pendientes : Integer;
  bContinuar : Boolean;
begin
  btnAceptar.ModalResult := mrNone;
  bContinuar := True;
  pendientes := 0;
  if (not Assigned(FDatosPreview)) or
     (not FDatosPreview.Active) or
     (FDatosPreview.RecordCount = 0) then
  begin
    if MessageDlg_fza(SPreguntaPrevisualizarAddBlock,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      btnPrevisualizarClick(nil);
      bContinuar := Assigned(FDatosPreview) and FDatosPreview.Active and
        (FDatosPreview.RecordCount > 0);
    end
    else
      bContinuar := False;
  end;
  if bContinuar then
  begin
    pendientes := 0;
    FDatosPreview.DisableControls;
    try
      FDatosPreview.First;
      while not FDatosPreview.Eof do
      begin
        if FDatosPreview.FieldByName('YA_CARGADO').AsString <> 'S' then
          Inc(pendientes);
        FDatosPreview.Next;
      end;
      FDatosPreview.First;
    finally
      FDatosPreview.EnableControls;
    end;
    if pendientes = 0 then
    begin
      ShowMessage_fza(SInfoArticulosYaCargadosAddBlock);
      bContinuar := False;
    end;
  end;
  if bContinuar then
  begin
    bContinuar := MessageDlg_fza(TextoConfirmacion(pendientes),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  end;
  if bContinuar and EjecutarInsercion(numIns, codigos) then
  begin
    FBaseResultado.Aceptado         := True;
    FBaseResultado.NumInsertados    := numIns;
    FBaseResultado.ArticulosCodigos := codigos;
    ShowMessage_fza(TextoExito(numIns));
    btnAceptar.ModalResult := mrOk;
    Self.ModalResult := mrOk;
  end;
end;

procedure TfrmModalAddBlockBase.btnCancelarClick(Sender: TObject);
begin
  FBaseResultado.Aceptado := False;
  Self.ModalResult := mrCancel;
end;

end.
