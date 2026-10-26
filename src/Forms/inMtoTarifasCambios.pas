{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTarifasCambios                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sesiones de cambios de tarifa: carga, calculo, revision y aplicacion.     }
{******************************************************************************}
unit inMtoTarifasCambios;

interface

uses
  inLibRegistroPantallas, inLibVentanaEmbebidaIntf,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit,
  cxNavigator, cxDBData, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  cxContainer, cxTextEdit, cxDBEdit, cxLabel, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxCurrencyEdit, cxLookupEdit,
  cxDBLookupEdit, cxDBLookupComboBox, cxCheckBox, cxPC, cxImageComboBox,
  dxSkinsCore, dxSkinBlue, dxSkinsDefaultPainters, dxSkinscxPCPainter,
  dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataTarifasCambios, inLibTarifasCambiosExcel, inMtoGen,
  inLibCargaMasivaArticulosPersistenciaIntf, inLibPermisosIntf;

type
  TfrmMtoTarifasCambios = class(TfrmMtoGen, IBorradoContextualVentana)
    procedure FormCreate(Sender: TObject);
  private
    FCargaMasiva: TServiciosCargaMasivaArticulos;
    FControlesCreados : Boolean;
    pnlCabecera       : TPanel;
    pnlParametros     : TPanel;
    pnlAcciones       : TPanel;
    pcDetalle         : TcxPageControl;
    tsLineas          : TcxTabSheet;
    cxgrdLineas       : TcxGrid;
    tvLineas          : TcxGridDBTableView;
    glLineas          : TcxGridLevel;
    txtNombre         : TcxDBTextEdit;
    dteFecha          : TcxDBDateEdit;
    txtEstado         : TcxDBTextEdit;
    cbbTarifaOrigen   : TcxDBLookupComboBox;
    cbbTarifaDestino  : TcxDBLookupComboBox;
    cbbCampoOrigen    : TcxDBImageComboBox;
    cbbCampoDestino   : TcxDBImageComboBox;
    cbbTipoAplicacion : TcxDBImageComboBox;
    curValor          : TcxDBCurrencyEdit;
    curRedondeo       : TcxDBCurrencyEdit;
    curMenos          : TcxDBCurrencyEdit;
    chkRedondear      : TcxDBCheckBox;
    dteDesde          : TcxDBDateEdit;
    dteHasta          : TcxDBDateEdit;
    btnCargar         : TcxButton;
    btnCalcular       : TcxButton;
    btnAplicar        : TcxButton;
    btnRefrescar      : TcxButton;
    btnExportarExcel  : TcxButton;
    btnCargarExcel    : TcxButton;
    btnDescuentoLote  : TcxButton;
    pnlSeleccion: TPanel;
    btnMarcarTodo: TcxButton;
    btnDesmarcarTodo: TcxButton;
    btnActualizarCostes: TcxButton;
    btnEliminarLineas: TcxButton;
    actIrArticulo     : TAction;
    procedure CrearControlesDinamicos;
    procedure CrearAtajos;
    procedure CrearCabecera;
    procedure CrearParametros;
    procedure CrearAcciones;
    procedure CrearGridLineas;
    procedure CrearColumnasCabecera;
    procedure CrearColumnasLineas;
    procedure CrearEtiqueta(AParent: TWinControl;
                            const ATexto: string;
                            AIzq, ATop: Integer);
    function  CrearColumna(AView: TcxGridDBTableView;
                           const ACampo, ATitulo: string;
                           AAncho: Integer): TcxGridDBColumn;
    procedure FormatoImporte(AColumna: TcxGridDBColumn;
                             const AFormato: string);
    procedure ConfigurarCombos;
    procedure VincularDatos;
    procedure DesvincularDatos;
    procedure ActualizarFormatoValor;
    function  GrabarCabeceraSiNecesario: Boolean;
    procedure cbbTipoAplicacionEditValueChanged(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);
    procedure btnCargarClick(Sender: TObject);
    procedure btnCalcularClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
    procedure btnCargarExcelClick(Sender: TObject);
    procedure btnDescuentoLoteClick(Sender: TObject);
    procedure btnMarcarTodoClick(Sender: TObject);
    procedure btnActualizarCostesClick(Sender: TObject);
    procedure btnEliminarLineasClick(Sender: TObject);
    procedure btnDesmarcarTodoClick(Sender: TObject);
    function IdsLineasSeleccionadas: TArray<Integer>;
    function LeerExcelSesion(const AArchivo: string;
      out ALineas: TLineasSesionTarifaExcel): Boolean;
    procedure actIrArticuloExecute(Sender: TObject);
  public
    dmmTarifasCambios: TdmTarifasCambios;
    function TextoConfirmacionBorrado: string; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    function ProcesarBorradoContextual: Boolean;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ACargaMasiva: TServiciosCargaMasivaArticulos); reintroduce;
      overload;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  dxSpreadSheet,
  inLibMensajesVcl, inLibShowMto, inLibHojaCalculoDevEx, inMtoPreviewExcel,
  inMtoModalCargarSesionTarifa, inLibMsgArticulos, inLibMsgFacturas,
  inLibTraducciones, UniDataConfiguracionPantalla;

{$R *.dfm}

const
  FMT_EUROS = ',0.00 ' + #8364 + ';-,0.00 ' + #8364;
  FMT_PORCENTAJE = '0.00 %';

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoTarifasCambios.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ACargaMasiva: TServiciosCargaMasivaArticulos);
begin
  ValidarServiciosCargaMasiva(ACargaMasiva);
  FCargaMasiva := ACargaMasiva;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoTarifasCambios.FormCreate(Sender: TObject);
begin
  CrearControlesDinamicos;
  inherited;
end;

destructor TfrmMtoTarifasCambios.Destroy;
begin
  DesvincularDatos;
  inherited;
end;

procedure TfrmMtoTarifasCambios.CrearControlesDinamicos;
begin
  if not FControlesCreados then
  begin
    CrearCabecera;
    CrearParametros;
    CrearAcciones;
    CrearGridLineas;
    ConfigurarCombos;
    CrearAtajos;
    FControlesCreados := True;
  end;
end;

// Ctrl+R -> ficha del articulo de la linea en foco. Va en alMtoGen, la
// lista que el principal consulta para la pestana activa (como Ctrl+F).
procedure TfrmMtoTarifasCambios.CrearAtajos;
begin
  actIrArticulo := TAction.Create(Self);
  actIrArticulo.Caption := SCaptionCambioIrArticulo;
  actIrArticulo.ShortCut := ShortCut(Ord('R'), [ssCtrl]);
  actIrArticulo.OnExecute := actIrArticuloExecute;
  actIrArticulo.ActionList := alMtoGen;
end;

procedure TfrmMtoTarifasCambios.CrearCabecera;
begin
  pnlCabecera := TPanel.Create(Self);
  pnlCabecera.Parent := tsFicha;
  pnlCabecera.Align := alTop;
  pnlCabecera.Height := 88;
  pnlCabecera.BevelOuter := bvNone;
  pnlCabecera.ParentBackground := False;
  pnlCabecera.Color := clWhite;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaNombre, 12, 12);
  txtNombre := TcxDBTextEdit.Create(Self);
  txtNombre.Parent := pnlCabecera;
  txtNombre.Left := 80;
  txtNombre.Top := 8;
  txtNombre.Width := 330;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaFecha, 430, 12);
  dteFecha := TcxDBDateEdit.Create(Self);
  dteFecha.Parent := pnlCabecera;
  dteFecha.Left := 486;
  dteFecha.Top := 8;
  dteFecha.Width := 120;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaEstado, 625, 12);
  txtEstado := TcxDBTextEdit.Create(Self);
  txtEstado.Parent := pnlCabecera;
  txtEstado.Left := 688;
  txtEstado.Top := 8;
  txtEstado.Width := 120;
  txtEstado.Properties.ReadOnly := True;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaOrigen, 12, 50);
  cbbTarifaOrigen := TcxDBLookupComboBox.Create(Self);
  cbbTarifaOrigen.Parent := pnlCabecera;
  cbbTarifaOrigen.Left := 110;
  cbbTarifaOrigen.Top := 46;
  cbbTarifaOrigen.Width := 220;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaDestino, 350, 50);
  cbbTarifaDestino := TcxDBLookupComboBox.Create(Self);
  cbbTarifaDestino.Parent := pnlCabecera;
  cbbTarifaDestino.Left := 456;
  cbbTarifaDestino.Top := 46;
  cbbTarifaDestino.Width := 220;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaDesde, 696, 50);
  dteDesde := TcxDBDateEdit.Create(Self);
  dteDesde.Parent := pnlCabecera;
  dteDesde.Left := 748;
  dteDesde.Top := 46;
  dteDesde.Width := 110;
  CrearEtiqueta(pnlCabecera, SCaptionCambioTarifaHasta, 876, 50);
  dteHasta := TcxDBDateEdit.Create(Self);
  dteHasta.Parent := pnlCabecera;
  dteHasta.Left := 928;
  dteHasta.Top := 46;
  dteHasta.Width := 110;
end;

procedure TfrmMtoTarifasCambios.CrearParametros;
begin
  pnlParametros := TPanel.Create(Self);
  pnlParametros.Parent := tsFicha;
  pnlParametros.Align := alTop;
  pnlParametros.Height := 86;
  pnlParametros.BevelOuter := bvNone;
  pnlParametros.ParentBackground := False;
  pnlParametros.Color := clWhite;
  CrearEtiqueta(pnlParametros, SCaptionCambioCampoOrigen, 12, 10);
  cbbCampoOrigen := TcxDBImageComboBox.Create(Self);
  cbbCampoOrigen.Parent := pnlParametros;
  cbbCampoOrigen.Left := 80;
  cbbCampoOrigen.Top := 6;
  cbbCampoOrigen.Width := 170;
  CrearEtiqueta(pnlParametros, SCaptionCambioCampoDestino, 268, 10);
  cbbCampoDestino := TcxDBImageComboBox.Create(Self);
  cbbCampoDestino.Parent := pnlParametros;
  cbbCampoDestino.Left := 338;
  cbbCampoDestino.Top := 6;
  cbbCampoDestino.Width := 145;
  CrearEtiqueta(pnlParametros, SCaptionCambioAplicar, 502, 10);
  cbbTipoAplicacion := TcxDBImageComboBox.Create(Self);
  cbbTipoAplicacion.Parent := pnlParametros;
  cbbTipoAplicacion.Left := 572;
  cbbTipoAplicacion.Top := 6;
  cbbTipoAplicacion.Width := 180;
  CrearEtiqueta(pnlParametros, SCaptionCambioValor, 770, 10);
  curValor := TcxDBCurrencyEdit.Create(Self);
  curValor.Parent := pnlParametros;
  curValor.Left := 820;
  curValor.Top := 6;
  curValor.Width := 90;
  curValor.Properties.UseDisplayFormatWhenEditing := True;
  CrearEtiqueta(pnlParametros, SCaptionCambioRedondeo, 12, 48);
  curRedondeo := TcxDBCurrencyEdit.Create(Self);
  curRedondeo.Parent := pnlParametros;
  curRedondeo.Left := 96;
  curRedondeo.Top := 44;
  curRedondeo.Width := 90;
  CrearEtiqueta(pnlParametros, SCaptionCambioMenos, 208, 48);
  curMenos := TcxDBCurrencyEdit.Create(Self);
  curMenos.Parent := pnlParametros;
  curMenos.Left := 264;
  curMenos.Top := 44;
  curMenos.Width := 90;
  chkRedondear := TcxDBCheckBox.Create(Self);
  chkRedondear.Parent := pnlParametros;
  chkRedondear.Left := 378;
  chkRedondear.Top := 43;
  chkRedondear.Width := 165;
  chkRedondear.Caption := SCaptionRedondearHaciaArriba;
  chkRedondear.Properties.ValueChecked := 'S';
  chkRedondear.Properties.ValueUnchecked := 'N';
end;

procedure TfrmMtoTarifasCambios.CrearAcciones;
begin
  pnlAcciones := TPanel.Create(Self);
  pnlAcciones.Parent := tsFicha;
  pnlAcciones.Align := alTop;
  pnlAcciones.Height := 44;
  pnlAcciones.BevelOuter := bvNone;
  pnlAcciones.ParentBackground := False;
  pnlAcciones.Color := clWhite;
  btnCargar := TcxButton.Create(Self);
  btnCargar.Parent := pnlAcciones;
  btnCargar.Left := 12;
  btnCargar.Top := 6;
  btnCargar.Width := 130;
  btnCargar.Caption := SCaptionCargarArticulos;
  btnCargar.OnClick := btnCargarClick;
  btnCalcular := TcxButton.Create(Self);
  btnCalcular.Parent := pnlAcciones;
  btnCalcular.Left := 154;
  btnCalcular.Top := 6;
  btnCalcular.Width := 120;
  btnCalcular.Caption := SCaptionCalcularLineas;
  btnCalcular.OnClick := btnCalcularClick;
  btnAplicar := TcxButton.Create(Self);
  btnAplicar.Parent := pnlAcciones;
  btnAplicar.Left := 286;
  btnAplicar.Top := 6;
  btnAplicar.Width := 116;
  btnAplicar.Caption := SCaptionAplicarTarifa;
  btnAplicar.OnClick := btnAplicarClick;
  btnRefrescar := TcxButton.Create(Self);
  btnRefrescar.Parent := pnlAcciones;
  btnRefrescar.Left := 414;
  btnRefrescar.Top := 6;
  btnRefrescar.Width := 92;
  btnRefrescar.Caption := SCaptionRefrescar;
  btnRefrescar.OnClick := btnRefrescarClick;
  btnExportarExcel := TcxButton.Create(Self);
  btnExportarExcel.Parent := pnlAcciones;
  btnExportarExcel.Left := 530;
  btnExportarExcel.Top := 6;
  btnExportarExcel.Width := 116;
  btnExportarExcel.Caption := SCaptionExportarExcelSesionTarifa;
  btnExportarExcel.OnClick := btnExportarExcelClick;
  btnCargarExcel := TcxButton.Create(Self);
  btnCargarExcel.Parent := pnlAcciones;
  btnCargarExcel.Left := 658;
  btnCargarExcel.Top := 6;
  btnCargarExcel.Width := 116;
  btnCargarExcel.Caption := SCaptionCargarExcelSesionTarifa;
  btnCargarExcel.OnClick := btnCargarExcelClick;
  btnDescuentoLote := TcxButton.Create(Self);
  btnDescuentoLote.Parent := pnlAcciones;
  btnDescuentoLote.Left := 798;
  btnDescuentoLote.Top := 6;
  btnDescuentoLote.Width := 130;
  btnDescuentoLote.Caption := SCaptionDescuentoLoteSesionTarifa;
  btnDescuentoLote.OnClick := btnDescuentoLoteClick;
end;

procedure TfrmMtoTarifasCambios.CrearGridLineas;
begin
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := tsFicha;
  pcDetalle.Align := alClient;
  tsLineas := TcxTabSheet.Create(Self);
  tsLineas.PageControl := pcDetalle;
  tsLineas.Caption := SCaptionTabLineasTarifa;
  pnlSeleccion := TPanel.Create(Self);
  pnlSeleccion.Parent := tsLineas;
  pnlSeleccion.Align := alTop;
  pnlSeleccion.Height := 36;
  pnlSeleccion.BevelOuter := bvNone;
  btnMarcarTodo := TcxButton.Create(Self);
  btnMarcarTodo.Parent := pnlSeleccion;
  btnMarcarTodo.SetBounds(8, 5, 130, 25);
  btnMarcarTodo.Caption := SCaptionMarcarTodoSesionTarifa;
  btnMarcarTodo.OnClick := btnMarcarTodoClick;
  btnDesmarcarTodo := TcxButton.Create(Self);
  btnDesmarcarTodo.Parent := pnlSeleccion;
  btnDesmarcarTodo.SetBounds(146, 5, 140, 25);
  btnDesmarcarTodo.Caption := SCaptionDesmarcarTodoSesionTarifa;
  btnDesmarcarTodo.OnClick := btnDesmarcarTodoClick;
  btnActualizarCostes := TcxButton.Create(Self);
  btnActualizarCostes.Parent := pnlSeleccion;
  btnActualizarCostes.SetBounds(300, 5, 160, 25);
  btnActualizarCostes.Caption := SCaptionActualizarCostesSesion;
  btnActualizarCostes.OnClick := btnActualizarCostesClick;
  btnEliminarLineas := TcxButton.Create(Self);
  btnEliminarLineas.Parent := pnlSeleccion;
  btnEliminarLineas.SetBounds(472, 5, 150, 25);
  btnEliminarLineas.Caption := SCaptionEliminarLineasSesion;
  btnEliminarLineas.OnClick := btnEliminarLineasClick;
  cxgrdLineas := TcxGrid.Create(Self);
  cxgrdLineas.Parent := tsLineas;
  cxgrdLineas.Align := alClient;
  tvLineas := TcxGridDBTableView.Create(cxgrdLineas);
  glLineas := cxgrdLineas.Levels.Add;
  glLineas.GridView := tvLineas;
  tvLineas.OptionsData.Deleting := False;
  tvLineas.OptionsData.Inserting := False;
  tvLineas.OptionsData.Appending := False;
  tvLineas.Navigator.Visible := True;
  tvLineas.Navigator.Buttons.First.Visible := True;
  tvLineas.Navigator.Buttons.PriorPage.Visible := False;
  tvLineas.Navigator.Buttons.Prior.Visible := True;
  tvLineas.Navigator.Buttons.Next.Visible := True;
  tvLineas.Navigator.Buttons.NextPage.Visible := False;
  tvLineas.Navigator.Buttons.Last.Visible := True;
  tvLineas.Navigator.Buttons.Insert.Visible := False;
  tvLineas.Navigator.Buttons.Append.Visible := False;
  tvLineas.Navigator.Buttons.Delete.Visible := True;
  tvLineas.Navigator.Buttons.Delete.Hint := SCaptionEliminarLineasSesion;
  tvLineas.Navigator.Buttons.Delete.OnClick := btnEliminarLineasClick;
  tvLineas.Navigator.Buttons.SaveBookmark.Visible := False;
  tvLineas.Navigator.Buttons.GotoBookmark.Visible := False;
  tvLineas.Navigator.Buttons.Filter.Visible := False;
  tvLineas.OptionsView.GroupByBox := False;
  // Casillas y seleccion con Ctrl, Mayus y Ctrl+Mayus.
  tvLineas.OptionsSelection.MultiSelect := True;
  tvLineas.OptionsSelection.MultiSelectMode := msmPersistent;
  tvLineas.OptionsSelection.CheckBoxVisibility :=
    [cbvColumnHeader, cbvDataRow];
  tvLineas.DataController.KeyFieldNames := 'ID_TARCLIN';
end;

procedure AgregarOpcion(ACombo: TcxDBImageComboBox;
  const ACampo, AValor: string);
var
  Opcion: TcxImageComboBoxItem;
begin
  Opcion := ACombo.Properties.Items.Add;
  Opcion.Value := AValor;
  Opcion.Description := TextoValorDocumento(ACampo, AValor);
end;

procedure TfrmMtoTarifasCambios.ConfigurarCombos;
begin
  AgregarOpcion(cbbCampoOrigen,
    'CAMPO_ORIGEN_TARC', 'PRECIO_ORIGEN');
  AgregarOpcion(cbbCampoOrigen,
    'CAMPO_ORIGEN_TARC', 'PRECIO_COSTE');
  AgregarOpcion(cbbCampoOrigen,
    'CAMPO_ORIGEN_TARC', 'PRECIO_DESTINO_ACTUAL');
  AgregarOpcion(cbbCampoDestino,
    'CAMPO_DESTINO_TARC', 'AMBOS');
  AgregarOpcion(cbbCampoDestino,
    'CAMPO_DESTINO_TARC', 'PRECIO_SALIDA');
  AgregarOpcion(cbbCampoDestino,
    'CAMPO_DESTINO_TARC', 'PRECIO_FINAL');
  AgregarOpcion(cbbTipoAplicacion,
    'TIPO_APLICACION_TARC', 'COPIAR');
  AgregarOpcion(cbbTipoAplicacion,
    'TIPO_APLICACION_TARC', 'INCREMENTO_LINEAL');
  AgregarOpcion(cbbTipoAplicacion,
    'TIPO_APLICACION_TARC', 'INCREMENTO_PORCENTUAL');
  AgregarOpcion(cbbTipoAplicacion,
    'TIPO_APLICACION_TARC', 'PRECIO_FIJO');
  cbbTipoAplicacion.Properties.OnEditValueChanged :=
    cbbTipoAplicacionEditValueChanged;
  cbbTarifaOrigen.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbTarifaOrigen.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
  cbbTarifaDestino.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbTarifaDestino.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
end;

procedure TfrmMtoTarifasCambios.VincularDatos;
begin
  txtNombre.DataBinding.DataSource := dsTablaG;
  txtNombre.DataBinding.DataField := 'NOMBRE_TARC';
  dteFecha.DataBinding.DataSource := dsTablaG;
  dteFecha.DataBinding.DataField := 'FECHA_TARC';
  txtEstado.DataBinding.DataSource := dsTablaG;
  txtEstado.DataBinding.DataField := 'ESTADO_TARC';
  cbbTarifaOrigen.DataBinding.DataSource := dsTablaG;
  cbbTarifaOrigen.DataBinding.DataField := 'CODIGO_TAR_ORIGEN_TARC';
  cbbTarifaDestino.DataBinding.DataSource := dsTablaG;
  cbbTarifaDestino.DataBinding.DataField := 'CODIGO_TAR_DESTINO_TARC';
  cbbCampoOrigen.DataBinding.DataSource := dsTablaG;
  cbbCampoOrigen.DataBinding.DataField := 'CAMPO_ORIGEN_TARC';
  cbbCampoDestino.DataBinding.DataSource := dsTablaG;
  cbbCampoDestino.DataBinding.DataField := 'CAMPO_DESTINO_TARC';
  cbbTipoAplicacion.DataBinding.DataSource := dsTablaG;
  cbbTipoAplicacion.DataBinding.DataField := 'TIPO_APLICACION_TARC';
  curValor.DataBinding.DataSource := dsTablaG;
  curValor.DataBinding.DataField := 'VALOR_APLICACION_TARC';
  curRedondeo.DataBinding.DataSource := dsTablaG;
  curRedondeo.DataBinding.DataField := 'VALOR_REDONDEO_TARC';
  curMenos.DataBinding.DataSource := dsTablaG;
  curMenos.DataBinding.DataField := 'VALOR_MENOS_AJUSTE_TARC';
  chkRedondear.DataBinding.DataSource := dsTablaG;
  chkRedondear.DataBinding.DataField := 'ESREDONDEAR_ARRIBA_TARC';
  dteDesde.DataBinding.DataSource := dsTablaG;
  dteDesde.DataBinding.DataField := 'FECHA_DESDE_TARC';
  dteHasta.DataBinding.DataSource := dsTablaG;
  dteHasta.DataBinding.DataField := 'FECHA_HASTA_TARC';
  dsTablaG.OnDataChange := dsTablaGDataChange;
  ActualizarFormatoValor;
end;

procedure TfrmMtoTarifasCambios.CrearTablaPrincipal;
begin
  inherited;
  dmmTarifasCambios := tdmDataModule as TdmTarifasCambios;
  dmmTarifasCambios.unqryLineas.MasterFields := 'CODIGO_TARC';
  dmmTarifasCambios.unqryLineas.DetailFields := 'CODIGO_TARC_TARCLIN';
  dmmTarifasCambios.unqryLineas.MasterSource := dsTablaG;
  tvLineas.DataController.DataSource := dmmTarifasCambios.dsLineas;
  btnActualizarCostes.Enabled := PuedeAccionMto(apmModificar);
  btnEliminarLineas.Enabled := PuedeAccionMto(apmBorrar);
  nvNavegador.Buttons.Delete.Hint := SCaptionEliminarSesionCompleta;
  tvLineas.OptionsData.Deleting := PuedeAccionMto(apmBorrar);
  tvLineas.Navigator.Buttons.Delete.Enabled := True;
  cbbTarifaOrigen.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  cbbTarifaDestino.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  pkFieldName := 'CODIGO_TARC';
  VincularDatos;
  CrearColumnasCabecera;
  CrearColumnasLineas;
  AplicarTraducciones(Self, Self);
end;

procedure TfrmMtoTarifasCambios.DesvincularDatos;
begin
  if Assigned(dsTablaG) then
    dsTablaG.OnDataChange := nil;
  if Assigned(cbbTipoAplicacion) then
    cbbTipoAplicacion.Properties.OnEditValueChanged := nil;
  if Assigned(tvLineas) then
  begin
    tvLineas.DataController.DataSource := nil;
    FreeAndNil(tvLineas);
  end;
  if Assigned(cbbTarifaOrigen) then
    cbbTarifaOrigen.Properties.ListSource := nil;
  if Assigned(cbbTarifaDestino) then
    cbbTarifaDestino.Properties.ListSource := nil;
  if Assigned(dmmTarifasCambios) then
  begin
    if Assigned(dmmTarifasCambios.dsLineas) then
      dmmTarifasCambios.dsLineas.DataSet := nil;
    if Assigned(dmmTarifasCambios.dsTarifas) then
      dmmTarifasCambios.dsTarifas.DataSet := nil;
    if Assigned(dmmTarifasCambios.unqryLineas) then
    begin
      if dmmTarifasCambios.unqryLineas.Active then
        dmmTarifasCambios.unqryLineas.Close;
      dmmTarifasCambios.unqryLineas.MasterSource := nil;
      dmmTarifasCambios.unqryLineas.MasterFields := '';
      dmmTarifasCambios.unqryLineas.DetailFields := '';
    end;
    if Assigned(dmmTarifasCambios.unqryTarifas) and
       dmmTarifasCambios.unqryTarifas.Active then
      dmmTarifasCambios.unqryTarifas.Close;
  end;
end;

procedure TfrmMtoTarifasCambios.ActualizarFormatoValor;
var
  sTipoAplicacion: string;
begin
  if not ((csDestroying in ComponentState) or
          (cbbTipoAplicacion = nil) or (curValor = nil)) then
  begin
    sTipoAplicacion := VarToStr(cbbTipoAplicacion.EditValue);
    if (sTipoAplicacion = '') and Assigned(dsTablaG.DataSet) and
       (dsTablaG.DataSet.FindField('TIPO_APLICACION_TARC') <> nil) then
      sTipoAplicacion :=
        dsTablaG.DataSet.FieldByName('TIPO_APLICACION_TARC').AsString;
    if SameText(sTipoAplicacion, 'INCREMENTO_PORCENTUAL') then
    begin
      curValor.Properties.DisplayFormat := '0.00 %';
      curValor.Properties.EditFormat := '0.00 %';
    end
    else
    begin
      curValor.Properties.DisplayFormat :=
        ',0.00 ' + #8364 + ';-,0.00 ' + #8364;
      curValor.Properties.EditFormat :=
        ',0.00 ' + #8364 + ';-,0.00 ' + #8364;
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.cbbTipoAplicacionEditValueChanged(
  Sender: TObject);
begin
  if not (csDestroying in ComponentState) then
    ActualizarFormatoValor;
end;

procedure TfrmMtoTarifasCambios.dsTablaGDataChange(Sender: TObject;
  Field: TField);
begin
  if not (csDestroying in ComponentState) then
  begin
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
      not dsTablaG.DataSet.IsEmpty then
      tvLineas.OptionsData.Deleting := PuedeAccionMto(apmBorrar) and
        not SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
          'APLICADA');
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
      not dsTablaG.DataSet.IsEmpty then
      tvLineas.OptionsData.Editing := PuedeAccionMto(apmModificar) and
        not SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
          'APLICADA');
    if (Field = nil) or SameText(Field.FieldName, 'TIPO_APLICACION_TARC') then
      ActualizarFormatoValor;
  end;
end;

procedure TfrmMtoTarifasCambios.CrearColumnasCabecera;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TARC', SCaptionCambioCodigo, 70);
    CrearColumna(cxGrdDBTabPrin, 'NOMBRE_TARC', SCaptionCambioTarifaNombre, 220);
    CrearColumna(cxGrdDBTabPrin, 'FECHA_TARC', SCaptionCambioTarifaFecha, 90);
    CrearColumna(cxGrdDBTabPrin, 'ESTADO_TARC', SCaptionCambioTarifaEstado, 100);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TAR_ORIGEN_TARC',
                 SCaptionCambioTarifaOrigen, 120);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TAR_DESTINO_TARC',
                 SCaptionCambioTarifaDestino, 120);
    CrearColumna(cxGrdDBTabPrin, 'TIPO_APLICACION_TARC', SCaptionCambioAplicacion, 150);
    CrearColumna(cxGrdDBTabPrin, 'VALOR_APLICACION_TARC', SCaptionCambioValor, 90);
  end;
end;

procedure TfrmMtoTarifasCambios.CrearColumnasLineas;
begin
  if tvLineas.ColumnCount = 0 then
  begin
    CrearColumna(tvLineas, 'ESAPLICAR_TARCLIN', SCaptionCambioAplicar, 65);
    CrearColumna(tvLineas, 'ESTADO_TARCLIN', SCaptionCambioTarifaEstado, 90);
    CrearColumna(tvLineas, 'CODIGO_ART_TARCLIN', SCaptionCambioArticulo, 110);
    CrearColumna(tvLineas, 'CODIGO_UNIDAD_SKU_TARCLIN',
      SCaptionColSku, 160).Options.Editing := False;
    CrearColumna(tvLineas, 'DESCRIPCION_ART', SCaptionCambioDescripcion, 240);
    CrearColumna(tvLineas, 'NOMBRE_FAM_FAM', SCaptionCambioFamilia, 160);
    CrearColumna(tvLineas, 'RAZON_SOCIAL_PRV', SCaptionCambioProveedor, 180);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_ORIGEN_TARCLIN',
                   SCaptionCambioPrecioOrigen, 90), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_COSTE_TARCLIN',
                   SCaptionCambioCoste, 90), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_SALIDA_ACTUAL_TARCLIN',
                   SCaptionCambioSalidaActual, 100), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_FINAL_ACTUAL_TARCLIN',
                   SCaptionCambioFinalActual, 100), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_NUEVO_TARCLIN',
                   SCaptionCambioSalidaNueva, 100), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_DTO_NUEVO_TARCLIN',
                   SCaptionCambioDtoNuevo, 90), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PORCENTAJE_DTO_NUEVO_TARCLIN',
                   SCaptionCambioPorcentajeDto, 90), FMT_PORCENTAJE);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_FINAL_NUEVO_TARCLIN',
                   SCaptionCambioFinalNuevo, 100), FMT_EUROS);
    CrearColumna(tvLineas, 'MENSAJE_TARCLIN', SCaptionCambioMensaje, 180);
  end;
end;

procedure TfrmMtoTarifasCambios.CrearEtiqueta(AParent: TWinControl;
  const ATexto: string; AIzq, ATop: Integer);
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent := AParent;
  lbl.Left := AIzq;
  lbl.Top := ATop;
  lbl.Caption := ATexto;
  lbl.Transparent := True;
end;

function TfrmMtoTarifasCambios.CrearColumna(AView: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AView.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := AAncho;
end;

// Importes con dos decimales, alineados a la derecha, tambien al editar.
procedure TfrmMtoTarifasCambios.FormatoImporte(AColumna: TcxGridDBColumn;
  const AFormato: string);
var
  Propiedades: TcxCurrencyEditProperties;
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  Propiedades := AColumna.Properties as TcxCurrencyEditProperties;
  Propiedades.DisplayFormat := AFormato;
  Propiedades.EditFormat := '0.00';
  Propiedades.DecimalPlaces := 2;
  Propiedades.Alignment.Horz := taRightJustify;
end;

function TfrmMtoTarifasCambios.GrabarCabeceraSiNecesario: Boolean;
begin
  Result := True;
  if Assigned(dsTablaG.DataSet) and
     (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
    dsTablaG.DataSet.Post;
  if (not Assigned(dsTablaG.DataSet)) or dsTablaG.DataSet.IsEmpty then
  begin
    ShowMessage_fza(SErrorSesionTarifaNoSeleccionada);
    Result := False;
  end;
end;

procedure TfrmMtoTarifasCambios.btnCargarClick(Sender: TObject);
var
  res: TCargarSesionTarifaResult;
begin
  if GrabarCabeceraSiNecesario then
  begin
    res := TfrmModalCargarSesionTarifa.Ejecutar(
      Self,
      dsTablaG.DataSet.FieldByName('CODIGO_TARC').AsInteger,
      dsTablaG.DataSet.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString,
      dsTablaG.DataSet.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString,
      FCargaMasiva);
    if res.Aceptado then
      dmmTarifasCambios.unqryLineas.Refresh;
  end;
end;

procedure TfrmMtoTarifasCambios.btnCalcularClick(Sender: TObject);
var
  sMensaje : string;
  iLineas  : Integer;
  Ids: TArray<Integer>;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    Ids := IdsLineasSeleccionadas;
    iLineas := dmmTarifasCambios.RecalcularSesionActual(Ids, sMensaje);
    if sMensaje <> '' then
      ShowMessage_fza(sMensaje)
    else if iLineas = 1 then
      ShowMessage_fza(SInfoLineaSesionTarifaRecalculada)
    else
      ShowMessage_fza(Format(SInfoLineasSesionTarifaRecalculadas, [iLineas]));
  end;
end;

// Aplica lo que se ve en la rejilla, sin recalcular: asi no se pierden los
// descuentos puestos por articulo, en lote o desde Excel. La formula de la
// cabecera solo se aplica con "Calcular lineas".
procedure TfrmMtoTarifasCambios.btnAplicarClick(Sender: TObject);
var
  sMensaje        : string;
  iLineas         : Integer;
  iLineasAplicadas: Integer;
  iSinPrecio      : Integer;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    iLineas := dmmTarifasCambios.unqryLineas.RecordCount;
    iSinPrecio := dmmTarifasCambios.LineasSinPrecioNuevo;
    if iSinPrecio > 0 then
      ShowMessage_fza(Format(SErrorLineasSinPrecioNuevoSesionTarifa,
        [iSinPrecio]))
    else if MessageDlg_fza(Format(SPreguntaAplicarSesionTarifa,
                              [iLineas]),
                       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      iLineasAplicadas := dmmTarifasCambios.AplicarSesionActual(sMensaje);
      if sMensaje <> '' then
        ShowMessage_fza(Format(SErrorAplicarSesionTarifa, [sMensaje]))
      else
        ShowMessage_fza(Format(SInfoLineasSesionTarifaAplicadas,
                           [iLineasAplicadas]));
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.btnRefrescarClick(Sender: TObject);
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    dmmTarifasCambios.unqryTablaG.Refresh;
    dmmTarifasCambios.RellenarPreciosPartida;
    dmmTarifasCambios.unqryLineas.Refresh;
  end;
end;

procedure TfrmMtoTarifasCambios.btnExportarExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
begin
  if PuedeExportar and Assigned(dmmTarifasCambios) and
     GrabarCabeceraSiNecesario then
  begin
    Screen.Cursor := crHourGlass;
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    try
      fPreview.PopupParent := Self;
      fPreview.DialogoGuardar.InitialDir :=
        ParametrosApp.GetPath('appDirExcel');
      fPreview.DialogoGuardar.FileName := Format(SNombreArchivoSesionTarifa,
        [dsTablaG.DataSet.FieldByName('CODIGO_TARC').AsInteger]);
      ExportarSesionTarifaExcel(fPreview.dxSpreadSheet1,
        dsTablaG.DataSet, dmmTarifasCambios.unqryLineas);
      Screen.Cursor := crDefault;
      fPreview.ShowModal;
    finally
      Screen.Cursor := crDefault;
      FreeAndNil(fPreview);
    end;
  end;
end;

function TfrmMtoTarifasCambios.LeerExcelSesion(const AArchivo: string;
  out ALineas: TLineasSesionTarifaExcel): Boolean;
var
  Hoja: TdxSpreadSheet;
  Incidencias: TStringList;
  sMensaje: string;
begin
  Incidencias := TStringList.Create;
  Hoja := TdxSpreadSheet.Create(nil);
  try
    Hoja.LoadFromFile(AArchivo);
    ImportarSesionTarifaDesdeSheet(CrearLectorDevEx(Hoja), ALineas,
      Incidencias, sMensaje);
    if Incidencias.Count > 0 then
      ShowMessage_fza(Format(SErrorCargarExcelSesionTarifa,
        [Incidencias.Text]))
    else if sMensaje <> '' then
      ShowMessage_fza(sMensaje);
    Result := Length(ALineas) > 0;
  finally
    FreeAndNil(Hoja);
    FreeAndNil(Incidencias);
  end;
end;

procedure TfrmMtoTarifasCambios.btnCargarExcelClick(Sender: TObject);
var
  dlgAbrir: TOpenDialog;
  iActualizadas: Integer;
  iNuevas: Integer;
  Lineas: TLineasSesionTarifaExcel;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    if SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
                'APLICADA') then
      ShowMessage_fza(SErrorSesionTarifaAplicadaNoEditable)
    else
    begin
      dlgAbrir := TOpenDialog.Create(Self);
      try
        dlgAbrir.Filter := SFiltroExcelSesionTarifa;
        dlgAbrir.InitialDir := ParametrosApp.GetPath('appDirExcel');
        dlgAbrir.Options := dlgAbrir.Options + [ofFileMustExist];
        if dlgAbrir.Execute and
           LeerExcelSesion(dlgAbrir.FileName, Lineas) and
           (MessageDlg_fza(Format(SPreguntaCargarExcelSesionTarifa,
              [Length(Lineas)]), mtConfirmation, [mbYes, mbNo], 0) =
            mrYes) then
        begin
          Screen.Cursor := crHourGlass;
          try
            dmmTarifasCambios.ImportarLineasExcel(Lineas, iNuevas,
              iActualizadas);
          finally
            Screen.Cursor := crDefault;
          end;
          ShowMessage_fza(Format(SInfoExcelSesionTarifaCargado,
            [iNuevas, iActualizadas]));
        end;
      finally
        FreeAndNil(dlgAbrir);
      end;
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.btnMarcarTodoClick(Sender: TObject);
begin
  if GrabarCabeceraSiNecesario then
  begin
    tvLineas.Controller.EditingController.HideEdit(True);
    if dmmTarifasCambios.unqryLineas.State in dsEditModes then
      dmmTarifasCambios.unqryLineas.Post;
    tvLineas.Site.SetFocus;
    tvLineas.Controller.SelectAll;
  end;
end;

function TfrmMtoTarifasCambios.TextoConfirmacionBorrado: string;
begin
  Result := Format(SPreguntaEliminarSesionCompleta,
    [dsTablaG.DataSet.FieldByName('CODIGO_TARC').AsString]);
end;

function TfrmMtoTarifasCambios.ProcesarBorradoContextual: Boolean;
begin
  // No propagar a las acciones de otro mantenimiento, tampoco cuando
  // la sesión aplicada o el foco actual impiden borrar una línea.
  Result := True;
  if Assigned(cxgrdLineas) and
    ((Screen.ActiveControl = cxgrdLineas) or
     cxgrdLineas.ContainsControl(Screen.ActiveControl)) then
    btnEliminarLineasClick(Self)
  else if Assigned(cxgrdPrincipal) and
    ((Screen.ActiveControl = cxgrdPrincipal) or
     cxgrdPrincipal.ContainsControl(Screen.ActiveControl)) then
    actEliminarRegistroExecute(Self);
end;

function TfrmMtoTarifasCambios.IsShortCut(var Message: TWMKey): Boolean;
begin
  if (Message.CharCode = VK_DELETE) and
    (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) >= 0) then
    Result := ProcesarBorradoContextual
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmMtoTarifasCambios.btnEliminarLineasClick(Sender: TObject);
var
  Ids: TArray<Integer>;
  Mensaje: string;
begin
  if PuedeAccionMto(apmBorrar) and GrabarCabeceraSiNecesario then
  begin
    Ids := IdsLineasSeleccionadas;
    if (Length(Ids) = 0) and dmmTarifasCambios.unqryLineas.Active and
      not dmmTarifasCambios.unqryLineas.IsEmpty then
      Ids := [dmmTarifasCambios.unqryLineas.
        FieldByName('ID_TARCLIN').AsInteger];
    if Length(Ids) = 0 then
      ShowMessage_fza(SErrorSeleccionVaciaSesionTarifa)
    else if SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
      'APLICADA') then
      ShowMessage_fza(SErrorSesionTarifaAplicadaNoBorrarLineas)
    else
    begin
      if Length(Ids) = 1 then
        Mensaje := SPreguntaEliminarUnaLineaSesion
      else
        Mensaje := Format(SPreguntaEliminarLineasSesion, [Length(Ids)]);
      if MessageDlg_fza(Mensaje, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        dmmTarifasCambios.EliminarLineasSesion(Ids);
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.btnActualizarCostesClick(Sender: TObject);
var
  Ids: TArray<Integer>;
begin
  if PuedeAccionMto(apmModificar) and GrabarCabeceraSiNecesario then
  begin
    Ids := IdsLineasSeleccionadas;
    if Length(Ids) = 0 then
      ShowMessage_fza(SErrorSeleccionVaciaSesionTarifa)
    else if SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
      'APLICADA') then
      ShowMessage_fza(SErrorSesionTarifaAplicadaNoEditable)
    else if MessageDlg_fza(SPreguntaActualizarCostesSesion,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      dmmTarifasCambios.ActualizarCostesLineas(Ids);
  end;
end;

procedure TfrmMtoTarifasCambios.btnDesmarcarTodoClick(Sender: TObject);
begin
  tvLineas.Controller.ClearSelection;
end;

// Una seleccion vacia nunca equivale a toda la sesion.
function TfrmMtoTarifasCambios.IdsLineasSeleccionadas: TArray<Integer>;
var
  iFila: Integer;
  Registro: TcxCustomGridRecord;
begin
  SetLength(Result, 0);
  for iFila := 0 to tvLineas.Controller.SelectedRecordCount - 1 do
  begin
    Registro := tvLineas.Controller.SelectedRecords[iFila];
    if Registro.IsData then
      Result := Result + [Integer(
        tvLineas.DataController.GetRecordId(Registro.RecordIndex))];
  end;
end;

procedure TfrmMtoTarifasCambios.btnDescuentoLoteClick(Sender: TObject);
var
  dPorcentaje: Double;
  Ids: TArray<Integer>;
  sPorcentaje: string;
  sConfirmacion: string;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    if SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
                'APLICADA') then
      ShowMessage_fza(SErrorTarifasCambiosSesionAplicadaLote)
    else
    begin
      Ids := IdsLineasSeleccionadas;
      if Length(Ids) = 0 then
        ShowMessage_fza(SErrorSeleccionVaciaSesionTarifa);
      sPorcentaje := '';
      if (Length(Ids) > 0) and
         InputQuery_fza(STituloDescuentoLoteSesionTarifa,
           SPreguntaPorcentajeDescuentoLoteSesionTarifa, sPorcentaje) then
      begin
        sPorcentaje := Trim(StringReplace(sPorcentaje, '%', '',
          [rfReplaceAll]));
        sPorcentaje := StringReplace(sPorcentaje, '.',
          FormatSettings.DecimalSeparator, [rfReplaceAll]);
        sPorcentaje := StringReplace(sPorcentaje, ',',
          FormatSettings.DecimalSeparator, [rfReplaceAll]);
        if (not TryStrToFloat(sPorcentaje, dPorcentaje)) or
           (dPorcentaje < 0) or (dPorcentaje > 100) then
          ShowMessage_fza(SErrorPorcentajeDescuentoLoteSesionTarifa)
        else
        begin
          if Length(Ids) = 1 then
            sConfirmacion := Format(SPreguntaDescuentoUnaLineaSesionTarifa,
              [FormatFloat('0.##', dPorcentaje)])
          else
            sConfirmacion := Format(SPreguntaDescuentoLoteSesionTarifa,
              [FormatFloat('0.##', dPorcentaje), Length(Ids)]);
          if MessageDlg_fza(sConfirmacion, mtConfirmation,
            [mbYes, mbNo], 0) = mrYes then
          begin
            Screen.Cursor := crHourGlass;
            try
              dmmTarifasCambios.AplicarDescuentoLote(Ids, dPorcentaje);
            finally
              Screen.Cursor := crDefault;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.actIrArticuloExecute(Sender: TObject);
begin
  if Assigned(dmmTarifasCambios) then
    ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
      dmmTarifasCambios.unqryLineas, 'CODIGO_ART_TARCLIN');
end;

procedure TfrmMtoTarifasCambios.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsFicha;
end;

// Ctrl+F: la foto sigue al articulo de la linea en foco.
procedure TfrmMtoTarifasCambios.ResolverArtSkuActivo(out ACodArt,
  ACodSku: string);
var
  Lineas: TDataSet;
begin
  ACodArt := '';
  ACodSku := '';
  Lineas := nil;
  if Assigned(dmmTarifasCambios) then
    Lineas := dmmTarifasCambios.unqryLineas;
  if Assigned(Lineas) and Lineas.Active and (not Lineas.IsEmpty) then
  begin
    ACodArt := Lineas.FieldByName('CODIGO_ART_TARCLIN').AsString;
    ACodSku := Lineas.FieldByName('CODIGO_UNIDAD_SKU_TARCLIN').AsString;
  end;
  if ACodArt = '' then
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
end;

function TfrmMtoTarifasCambios.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if Assigned(dmmTarifasCambios) and
     Assigned(dmmTarifasCambios.dsLineas) then
    Result := [dsTablaG, dmmTarifasCambios.dsLineas]
  else
    Result := inherited DataSourcesParaFoto;
end;

initialization
  RegistrarPantalla(TfrmMtoTarifasCambios);
  ForceReferenceToClass(TfrmMtoTarifasCambios);
end.
