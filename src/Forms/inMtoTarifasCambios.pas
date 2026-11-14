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
  dxScrollbarAnnotations, dxDateRanges, dxCore, cxGroupBox, cxMemo,
  cxSplitter, cxListView, System.Generics.Collections,
  UniDataTarifasCambios, inLibTarifasCambiosExcel, inMtoGen,
  inLibCargaMasivaArticulosPersistenciaIntf, inLibPermisosIntf,
  inLibSimulacionPrecioCaja;

type
  TfrmMtoTarifasCambios = class(TfrmMtoGen, IBorradoContextualVentana)
    procedure FormCreate(Sender: TObject);
  private type
    // Texto de un control creado en código: se vuelve a leer de su
    // resourcestring al cambiar el idioma en caliente (FZ-ISSUE-945).
    TTextoDinamico = record
      Objeto: TPersistent;
      Propiedad: string;
      Recurso: PResStringRec;
    end;
    // Opción de un desplegable de rejilla con texto de valor de documento.
    TOpcionDinamica = record
      Opcion: TcxImageComboBoxItem;
      Campo: string;
      Valor: string;
    end;
  private
    FTextosDinamicos: TList<TTextoDinamico>;
    FOpcionesDinamicas: TList<TOpcionDinamica>;
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
    btnEtiquetar      : TcxButton;
    // Etiquetas de la sesion (FZ-ISSUE-944).
    FEtiquetasDmArt   : TObject;
    FEtiquetaPorArticulo: Boolean;
    pnlSeleccion: TPanel;
    btnMarcarTodo: TcxButton;
    btnDesmarcarTodo: TcxButton;
    btnActualizarCostes: TcxButton;
    btnEliminarLineas: TcxButton;
    btnEliminarSinStock: TcxButton;
    actIrArticulo     : TAction;
    // Rejilla de 4 columnas (etiqueta + control) de la ficha.
    FColEtiqueta      : array[0..3] of Integer;
    FColControl       : array[0..3] of Integer;
    FColAncho         : array[0..3] of Integer;
    // Pestaña de prueba: precio que cobraría la caja.
    FSimulacion       : TServiciosSimulacionPrecioCaja;
    tsPrueba          : TcxTabSheet;
    pnlPrueba         : TcxGroupBox;
    edtPruebaSku      : TcxTextEdit;
    cbbPruebaTarifa   : TcxLookupComboBox;
    dtePruebaFecha    : TcxDateEdit;
    btnPruebaCalcular : TcxButton;
    mPruebaResultado  : TcxMemo;
    // Periodos (etapas de rebajas) de la sesión. FZ-ISSUE-944.
    pnlPeriodos       : TPanel;
    cxgrdPeriodos     : TcxGrid;
    tvPeriodos        : TcxGridDBTableView;
    glPeriodos        : TcxGridLevel;
    pnlPeriodosAcciones: TPanel;
    btnAnadirPeriodo  : TcxButton;
    btnEliminarPeriodo: TcxButton;
    btnVerPeriodos    : TcxButton;
    // Divisores: cabecera/detalle y periodos/articulos (FZ-ISSUE-944).
    pnlSuperior       : TPanel;
    splCabecera       : TcxSplitter;
    splPeriodos       : TcxSplitter;
    FSincronizando    : Boolean;
    FPeriodosVistaIniciada: Boolean;
    FSesionVistaPeriodos  : Integer;
    FEstiloSinStock       : TcxStyle;
    procedure CrearControlesDinamicos;
    procedure CrearAtajos;
    procedure CrearCabecera;
    procedure CrearParametros;
    procedure CrearAcciones;
    procedure CrearGridLineas;
    procedure CrearColumnasCabecera;
    procedure CrearColumnasLineas;
    function  Esc(AValor: Integer): Integer;
    function  AnchoTexto(const ATexto: string): Integer;
    procedure CalcularColumnas;
    procedure AsignarTexto(AObjeto: TPersistent;
                           const APropiedad: string;
                           ARecurso: PResStringRec);
    procedure ReaplicarTextosDinamicos;
    procedure CrearEtiqueta(AParent: TWinControl;
                            ATexto: PResStringRec;
                            AIzq, ATop: Integer);
    procedure ColocarCampo(AParent: TWinControl; ATexto: PResStringRec;
                           AControl: TControl; ACol, ATop: Integer;
                           AAncho: Integer = 0);
    procedure ColocarBoton(ABoton: TcxButton; ATop: Integer;
                           var AX: Integer; AHueco: Integer = 0);
    function  CrearBoton(AParent: TWinControl; ACaption: PResStringRec;
                         AOnClick: TNotifyEvent): TcxButton;
    function  CrearColumna(AView: TcxGridDBTableView;
                           const ACampo: string;
                           ATitulo: PResStringRec;
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
    procedure btnEtiquetarClick(Sender: TObject);
    procedure CargarAlmacenesEtiquetasSesion(ALV: TcxListView);
    procedure CrearDataSetEtiquetasSesion(ADmArt: TObject;
      const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
    procedure btnMarcarTodoClick(Sender: TObject);
    procedure btnActualizarCostesClick(Sender: TObject);
    procedure btnEliminarLineasClick(Sender: TObject);
    procedure btnEliminarSinStockClick(Sender: TObject);
    procedure btnDesmarcarTodoClick(Sender: TObject);
    function IdsLineasSeleccionadas: TArray<Integer>;
    function LeerExcelSesion(const AArchivo: string;
      out ALineas: TLineasSesionTarifaExcel): Boolean;
    procedure actIrArticuloExecute(Sender: TObject);
    procedure CrearPestanaPrueba;
    function  LeerEntradaPrueba(out AEntrada: TEntradaSimulacionPrecioCaja;
                                out AError: string): Boolean;
    procedure MostrarResultadoPrueba(
      const AEntrada: TEntradaSimulacionPrecioCaja;
      const AResultado: TResultadoSimulacionPrecioCaja);
    procedure btnPruebaCalcularClick(Sender: TObject);
    procedure CrearRejillaPeriodos;
    procedure CrearColumnasPeriodos;
    procedure ColumnaOpciones(AColumna: TcxGridDBColumn;
      const ACampo: string; const AValores: array of string);
    procedure ColumnaSiNo(AColumna: TcxGridDBColumn);
    procedure ActualizarEstadoPeriodos;
    procedure SincronizarPeriodosSesion;
    procedure dsPeriodosDataChange(Sender: TObject; Field: TField);
    procedure btnAnadirPeriodoClick(Sender: TObject);
    procedure btnEliminarPeriodoClick(Sender: TObject);
    procedure btnVerPeriodosClick(Sender: TObject);
    procedure tvLineasGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure MostrarPeriodos(AVisible: Boolean);
  public
    dmmTarifasCambios: TdmTarifasCambios;
    function TextoConfirmacionBorrado: string; override;
    function IsShortCut(var Message: TWMKey): Boolean; override;
    function ProcesarBorradoContextual: Boolean;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ACargaMasiva: TServiciosCargaMasivaArticulos;
      const ASimulacion: TServiciosSimulacionPrecioCaja); reintroduce;
      overload;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure AplicarTraduccionActual; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  dxSpreadSheet,
  inLibMensajesVcl, inLibShowMto, inLibHojaCalculoDevEx, inMtoPreviewExcel,
  inMtoModalCargarSesionTarifa, inLibMsgArticulos, inLibMsgFacturas,
  inLibTraducciones, UniDataConfiguracionPantalla,
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf, Vcl.StdCtrls,
  inMtoModalEtiqArt, UniDataArticulos, System.TypInfo;

{$R *.dfm}

const
  FMT_EUROS = ',0.00 ' + #8364 + ';-,0.00 ' + #8364;
  FMT_PORCENTAJE = '0.00 %';

procedure ForceReferenceToClass(C: TClass); begin end;

constructor TfrmMtoTarifasCambios.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ACargaMasiva: TServiciosCargaMasivaArticulos;
  const ASimulacion: TServiciosSimulacionPrecioCaja);
begin
  ValidarServiciosCargaMasiva(ACargaMasiva);
  ValidarServiciosSimulacionPrecioCaja(ASimulacion);
  FCargaMasiva := ACargaMasiva;
  FSimulacion := ASimulacion;
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
  FreeAndNil(FOpcionesDinamicas);
  FreeAndNil(FTextosDinamicos);
end;

procedure TfrmMtoTarifasCambios.AsignarTexto(AObjeto: TPersistent;
  const APropiedad: string; ARecurso: PResStringRec);
var
  rTexto: TTextoDinamico;
begin
  if not Assigned(FTextosDinamicos) then
    FTextosDinamicos := TList<TTextoDinamico>.Create;
  SetStrProp(AObjeto, APropiedad, LoadResString(ARecurso));
  rTexto.Objeto := AObjeto;
  rTexto.Propiedad := APropiedad;
  rTexto.Recurso := ARecurso;
  FTextosDinamicos.Add(rTexto);
end;

// Etiquetas, botones, pestañas y columnas se crean en código con el texto
// del idioma de ese momento. El cambio de idioma en caliente solo traduce
// los componentes con nombre: el resto se vuelve a leer de su
// resourcestring, que ya devuelve el idioma nuevo (FZ-ISSUE-945).
procedure TfrmMtoTarifasCambios.ReaplicarTextosDinamicos;
var
  rOpcion: TOpcionDinamica;
  rTexto: TTextoDinamico;
begin
  if Assigned(FTextosDinamicos) then
    for rTexto in FTextosDinamicos do
      SetStrProp(
        rTexto.Objeto,
        rTexto.Propiedad,
        LoadResString(rTexto.Recurso));
  if Assigned(FOpcionesDinamicas) then
    for rOpcion in FOpcionesDinamicas do
      rOpcion.Opcion.Description := TextoValorDocumento(
        rOpcion.Campo,
        rOpcion.Valor);
  if Assigned(btnVerPeriodos) and Assigned(pnlPeriodos) then
  begin
    if pnlPeriodos.Visible then
      btnVerPeriodos.Caption := SCaptionOcultarPeriodosTarifa
    else
      btnVerPeriodos.Caption := SCaptionVerPeriodosTarifa;
  end;
end;

procedure TfrmMtoTarifasCambios.AplicarTraduccionActual;
begin
  inherited;
  if FControlesCreados then
  begin
    ReaplicarTextosDinamicos;
    if Assigned(cxGrdDBTabPrin) then
      cxGrdDBTabPrin.LayoutChanged;
    if Assigned(tvLineas) then
      tvLineas.LayoutChanged;
    if Assigned(tvPeriodos) then
      tvPeriodos.LayoutChanged;
  end;
end;

procedure TfrmMtoTarifasCambios.CrearControlesDinamicos;
begin
  if not FControlesCreados then
  begin
    CrearCabecera;
    CrearParametros;
    CrearAcciones;
    CrearGridLineas;
    CrearPestanaPrueba;
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
  AsignarTexto(actIrArticulo, 'Caption', @SCaptionCambioIrArticulo);
  actIrArticulo.ShortCut := ShortCut(Ord('R'), [ssCtrl]);
  actIrArticulo.OnExecute := actIrArticuloExecute;
  actIrArticulo.ActionList := alMtoGen;
end;

// Las etiquetas y los botones se miden con la fuente real del formulario
// para que no se corten ni se monten sobre su control.
const
  FICHA_MARGEN      = 12;
  FICHA_SEP_ETIQ    = 8;
  FICHA_SEP_COLUMNA = 28;
  FICHA_ALTO_FILA   = 36;
  FICHA_ALTO_BOTON  = 28;
  FICHA_SEP_BOTON   = 8;
  FICHA_SEP_GRUPO   = 24;

function TfrmMtoTarifasCambios.Esc(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoTarifasCambios.AnchoTexto(const ATexto: string): Integer;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(Font);
    Result := Bmp.Canvas.TextWidth(ATexto);
  finally
    Bmp.Free;
  end;
end;

// Columna 0: tarifa/campo de origen; 1: destino; 2: fechas y tipo de
// aplicacion; 3: estado, hasta y valor. Cada columna alinea sus etiquetas.
procedure TfrmMtoTarifasCambios.CalcularColumnas;

  function MaxTexto(const ATextos: array of string): Integer;
  var
    Texto: string;
  begin
    Result := 0;
    for Texto in ATextos do
      if AnchoTexto(Texto) > Result then
        Result := AnchoTexto(Texto);
  end;

var
  Etiquetas: array[0..3] of Integer;
  X, Col: Integer;
begin
  Etiquetas[0] := MaxTexto([SCaptionCambioTarifaNombre,
    SCaptionCambioTarifaOrigen, SCaptionCambioCampoOrigen,
    SCaptionCambioRedondeo]);
  Etiquetas[1] := MaxTexto([SCaptionCambioTarifaDestino,
    SCaptionCambioCampoDestino, SCaptionCambioMenos]);
  Etiquetas[2] := MaxTexto([SCaptionCambioTarifaFecha,
    SCaptionCambioTarifaDesde, SCaptionCambioAplicar]);
  Etiquetas[3] := MaxTexto([SCaptionCambioTarifaEstado,
    SCaptionCambioTarifaHasta, SCaptionCambioValor]);
  FColAncho[0] := Esc(210);
  FColAncho[1] := Esc(210);
  FColAncho[2] := Esc(200);
  FColAncho[3] := Esc(130);
  X := Esc(FICHA_MARGEN);
  for Col := 0 to 3 do
  begin
    FColEtiqueta[Col] := X;
    FColControl[Col] := X + Etiquetas[Col] + Esc(FICHA_SEP_ETIQ);
    X := FColControl[Col] + FColAncho[Col] + Esc(FICHA_SEP_COLUMNA);
  end;
end;

procedure TfrmMtoTarifasCambios.ColocarCampo(AParent: TWinControl;
  ATexto: PResStringRec; AControl: TControl; ACol, ATop, AAncho: Integer);
begin
  if Assigned(ATexto) then
    CrearEtiqueta(AParent, ATexto, FColEtiqueta[ACol], ATop + Esc(3));
  AControl.Parent := AParent;
  AControl.Left := FColControl[ACol];
  AControl.Top := ATop;
  if AAncho > 0 then
    AControl.Width := AAncho
  else
    AControl.Width := FColAncho[ACol];
end;

procedure TfrmMtoTarifasCambios.ColocarBoton(ABoton: TcxButton;
  ATop: Integer; var AX: Integer; AHueco: Integer);
var
  Ancho: Integer;
begin
  Inc(AX, AHueco);
  Ancho := AnchoTexto(ABoton.Caption) + Esc(32);
  if Ancho < Esc(100) then
    Ancho := Esc(100);
  ABoton.SetBounds(AX, ATop, Ancho, Esc(FICHA_ALTO_BOTON));
  Inc(AX, Ancho + Esc(FICHA_SEP_BOTON));
end;

procedure TfrmMtoTarifasCambios.CrearCabecera;
var
  Fila0, Fila1: Integer;
begin
  CalcularColumnas;
  Fila0 := Esc(10);
  Fila1 := Fila0 + Esc(FICHA_ALTO_FILA);
  // Cabecera, parametros y acciones van en un contenedor que el divisor
  // de la cabecera puede encoger o agrandar.
  pnlSuperior := TPanel.Create(Self);
  pnlSuperior.Parent := tsFicha;
  pnlSuperior.Align := alTop;
  pnlSuperior.BevelOuter := bvNone;
  pnlCabecera := TPanel.Create(Self);
  pnlCabecera.Parent := pnlSuperior;
  pnlCabecera.Align := alTop;
  pnlCabecera.Height := Fila1 + Esc(FICHA_ALTO_FILA);
  pnlCabecera.BevelOuter := bvNone;
  pnlCabecera.ParentBackground := False;
  pnlCabecera.Color := clWhite;
  // Fila 0: el nombre ocupa las columnas de origen y destino.
  txtNombre := TcxDBTextEdit.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaNombre, txtNombre, 0, Fila0,
    FColControl[1] + FColAncho[1] - FColControl[0]);
  dteFecha := TcxDBDateEdit.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaFecha, dteFecha, 2, Fila0,
    Esc(130));
  txtEstado := TcxDBTextEdit.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaEstado, txtEstado, 3, Fila0);
  txtEstado.Properties.ReadOnly := True;
  // Fila 1: tarifas y vigencia.
  cbbTarifaOrigen := TcxDBLookupComboBox.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaOrigen, cbbTarifaOrigen, 0,
    Fila1);
  cbbTarifaDestino := TcxDBLookupComboBox.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaDestino, cbbTarifaDestino, 1,
    Fila1);
  dteDesde := TcxDBDateEdit.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaDesde, dteDesde, 2, Fila1,
    Esc(130));
  dteHasta := TcxDBDateEdit.Create(Self);
  ColocarCampo(pnlCabecera, @SCaptionCambioTarifaHasta, dteHasta, 3, Fila1);
end;

procedure TfrmMtoTarifasCambios.CrearParametros;
var
  Fila0, Fila1: Integer;
begin
  Fila0 := Esc(8);
  Fila1 := Fila0 + Esc(FICHA_ALTO_FILA);
  pnlParametros := TPanel.Create(Self);
  pnlParametros.Parent := pnlSuperior;
  pnlParametros.Align := alTop;
  pnlParametros.Top := pnlCabecera.Top + pnlCabecera.Height;
  pnlParametros.Height := Fila1 + Esc(FICHA_ALTO_FILA) + Esc(4);
  pnlParametros.BevelOuter := bvNone;
  pnlParametros.ParentBackground := False;
  pnlParametros.Color := clWhite;
  // Fila 0: de donde sale el precio, a donde va y como se calcula.
  cbbCampoOrigen := TcxDBImageComboBox.Create(Self);
  ColocarCampo(pnlParametros, @SCaptionCambioCampoOrigen, cbbCampoOrigen, 0,
    Fila0);
  cbbCampoDestino := TcxDBImageComboBox.Create(Self);
  ColocarCampo(pnlParametros, @SCaptionCambioCampoDestino, cbbCampoDestino, 1,
    Fila0);
  cbbTipoAplicacion := TcxDBImageComboBox.Create(Self);
  ColocarCampo(pnlParametros, @SCaptionCambioAplicar, cbbTipoAplicacion, 2,
    Fila0);
  curValor := TcxDBCurrencyEdit.Create(Self);
  ColocarCampo(pnlParametros, @SCaptionCambioValor, curValor, 3, Fila0);
  curValor.Properties.UseDisplayFormatWhenEditing := True;
  // Fila 1: redondeo del precio resultante.
  curRedondeo := TcxDBCurrencyEdit.Create(Self);
  ColocarCampo(pnlParametros, @SCaptionCambioRedondeo, curRedondeo, 0, Fila1,
    Esc(110));
  curMenos := TcxDBCurrencyEdit.Create(Self);
  ColocarCampo(pnlParametros, @SCaptionCambioMenos, curMenos, 1, Fila1,
    Esc(110));
  chkRedondear := TcxDBCheckBox.Create(Self);
  chkRedondear.Parent := pnlParametros;
  AsignarTexto(chkRedondear, 'Caption', @SCaptionRedondearHaciaArriba);
  chkRedondear.Left := FColEtiqueta[2];
  chkRedondear.Top := Fila1 + Esc(1);
  chkRedondear.Width := AnchoTexto(SCaptionRedondearHaciaArriba) + Esc(36);
  chkRedondear.Properties.ValueChecked := 'S';
  chkRedondear.Properties.ValueUnchecked := 'N';
end;

function TfrmMtoTarifasCambios.CrearBoton(AParent: TWinControl;
  ACaption: PResStringRec; AOnClick: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Self);
  Result.Parent := AParent;
  AsignarTexto(Result, 'Caption', ACaption);
  Result.OnClick := AOnClick;
end;

// Botones en el orden del flujo de trabajo: cargar, calcular, ajustar y
// aplicar; despues el intercambio con Excel y, aparte, refrescar.
// Se crean en ese orden para que el tabulador lo siga.
procedure TfrmMtoTarifasCambios.CrearAcciones;
var
  X, Y: Integer;
begin
  pnlAcciones := TPanel.Create(Self);
  pnlAcciones.Parent := pnlSuperior;
  pnlAcciones.Align := alTop;
  pnlAcciones.Top := pnlParametros.Top + pnlParametros.Height;
  pnlAcciones.Height := Esc(FICHA_ALTO_BOTON) + Esc(14);
  pnlAcciones.BevelOuter := bvNone;
  pnlAcciones.ParentBackground := False;
  pnlAcciones.Color := clWhite;
  btnCargar := CrearBoton(pnlAcciones, @SCaptionCargarArticulos,
    btnCargarClick);
  btnCalcular := CrearBoton(pnlAcciones, @SCaptionCalcularLineas,
    btnCalcularClick);
  btnDescuentoLote := CrearBoton(pnlAcciones,
    @SCaptionDescuentoLoteSesionTarifa, btnDescuentoLoteClick);
  btnAplicar := CrearBoton(pnlAcciones, @SCaptionAplicarTarifa,
    btnAplicarClick);
  btnEtiquetar := CrearBoton(pnlAcciones, @SCaptionEtiquetarSesionTarifa,
    btnEtiquetarClick);
  btnExportarExcel := CrearBoton(pnlAcciones,
    @SCaptionExportarExcelSesionTarifa, btnExportarExcelClick);
  btnCargarExcel := CrearBoton(pnlAcciones,
    @SCaptionCargarExcelSesionTarifa, btnCargarExcelClick);
  btnRefrescar := CrearBoton(pnlAcciones, @SCaptionRefrescar,
    btnRefrescarClick);
  // FZ-ISSUE-944: muestra u oculta la rejilla de periodos de la pestaña
  // Líneas. Se coloca con el texto más largo para que no cambie de ancho.
  btnVerPeriodos := CrearBoton(pnlAcciones, @SCaptionOcultarPeriodosTarifa,
    btnVerPeriodosClick);
  if Length(SCaptionVerPeriodosTarifa) >
     Length(SCaptionOcultarPeriodosTarifa) then
    btnVerPeriodos.Caption := SCaptionVerPeriodosTarifa;
  X := Esc(FICHA_MARGEN);
  Y := Esc(6);
  ColocarBoton(btnCargar, Y, X);
  ColocarBoton(btnCalcular, Y, X);
  ColocarBoton(btnDescuentoLote, Y, X);
  ColocarBoton(btnAplicar, Y, X);
  ColocarBoton(btnEtiquetar, Y, X);
  ColocarBoton(btnExportarExcel, Y, X, Esc(FICHA_SEP_GRUPO));
  ColocarBoton(btnCargarExcel, Y, X);
  ColocarBoton(btnRefrescar, Y, X, Esc(FICHA_SEP_GRUPO));
  ColocarBoton(btnVerPeriodos, Y, X, Esc(FICHA_SEP_GRUPO));
  btnVerPeriodos.Caption := SCaptionOcultarPeriodosTarifa;
  pnlSuperior.Height := pnlCabecera.Height + pnlParametros.Height +
    pnlAcciones.Height;
  splCabecera := TcxSplitter.Create(Self);
  splCabecera.Parent := tsFicha;
  splCabecera.AlignSplitter := salTop;
  splCabecera.Control := pnlSuperior;
  splCabecera.Top := pnlSuperior.Top + pnlSuperior.Height;
  splCabecera.Height := Esc(8);
  splCabecera.HotZoneClassName := 'TcxMediaPlayer9Style';
end;

procedure TfrmMtoTarifasCambios.CrearGridLineas;
var
  X, Y: Integer;
begin
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := tsFicha;
  pcDetalle.Align := alClient;
  tsLineas := TcxTabSheet.Create(Self);
  tsLineas.PageControl := pcDetalle;
  AsignarTexto(tsLineas, 'Caption', @SCaptionTabLineasTarifa);
  CrearRejillaPeriodos;
  splPeriodos := TcxSplitter.Create(Self);
  splPeriodos.Parent := tsLineas;
  splPeriodos.AlignSplitter := salTop;
  splPeriodos.Control := pnlPeriodos;
  splPeriodos.Top := pnlPeriodos.Top + pnlPeriodos.Height;
  splPeriodos.Height := Esc(8);
  splPeriodos.HotZoneClassName := 'TcxMediaPlayer9Style';
  pnlSeleccion := TPanel.Create(Self);
  pnlSeleccion.Parent := tsLineas;
  pnlSeleccion.Align := alTop;
  pnlSeleccion.Top := splPeriodos.Top + splPeriodos.Height;
  pnlSeleccion.Height := Esc(FICHA_ALTO_BOTON) + Esc(10);
  pnlSeleccion.BevelOuter := bvNone;
  btnMarcarTodo := CrearBoton(pnlSeleccion,
    @SCaptionMarcarTodoSesionTarifa, btnMarcarTodoClick);
  btnDesmarcarTodo := CrearBoton(pnlSeleccion,
    @SCaptionDesmarcarTodoSesionTarifa, btnDesmarcarTodoClick);
  btnActualizarCostes := CrearBoton(pnlSeleccion,
    @SCaptionActualizarCostesSesion, btnActualizarCostesClick);
  btnEliminarLineas := CrearBoton(pnlSeleccion,
    @SCaptionEliminarLineasSesion, btnEliminarLineasClick);
  btnEliminarSinStock := CrearBoton(pnlSeleccion,
    @SCaptionEliminarLineasSinStockSesion, btnEliminarSinStockClick);
  X := Esc(8);
  Y := Esc(5);
  ColocarBoton(btnMarcarTodo, Y, X);
  ColocarBoton(btnDesmarcarTodo, Y, X);
  ColocarBoton(btnActualizarCostes, Y, X, Esc(FICHA_SEP_GRUPO));
  ColocarBoton(btnEliminarLineas, Y, X);
  ColocarBoton(btnEliminarSinStock, Y, X);
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

// ===========================================================================
//   Periodos (etapas de rebajas). FZ-ISSUE-944.
// ===========================================================================

// Rejilla de periodos encima de las lineas: al elegir uno, las lineas se
// filtran a ese periodo y "Calcular lineas" usa sus parametros.
procedure TfrmMtoTarifasCambios.CrearRejillaPeriodos;
var
  X, Y: Integer;
begin
  pnlPeriodos := TPanel.Create(Self);
  pnlPeriodos.Parent := tsLineas;
  pnlPeriodos.Align := alTop;
  pnlPeriodos.Height := Esc(170);
  pnlPeriodos.BevelOuter := bvNone;
  pnlPeriodosAcciones := TPanel.Create(Self);
  pnlPeriodosAcciones.Parent := pnlPeriodos;
  pnlPeriodosAcciones.Align := alTop;
  pnlPeriodosAcciones.Height := Esc(FICHA_ALTO_BOTON) + Esc(10);
  pnlPeriodosAcciones.BevelOuter := bvNone;
  btnAnadirPeriodo := CrearBoton(pnlPeriodosAcciones,
    @SCaptionAnadirPeriodoTarifa, btnAnadirPeriodoClick);
  btnEliminarPeriodo := CrearBoton(pnlPeriodosAcciones,
    @SCaptionEliminarPeriodoTarifa, btnEliminarPeriodoClick);
  X := Esc(8);
  Y := Esc(5);
  ColocarBoton(btnAnadirPeriodo, Y, X);
  ColocarBoton(btnEliminarPeriodo, Y, X);
  CrearEtiqueta(pnlPeriodosAcciones, @SAyudaPeriodosTarifa,
    X + Esc(FICHA_SEP_GRUPO), Y + Esc(5));
  // La rejilla ocupa el resto: el divisor de periodos la agranda o encoge.
  cxgrdPeriodos := TcxGrid.Create(Self);
  cxgrdPeriodos.Parent := pnlPeriodos;
  cxgrdPeriodos.Align := alClient;
  tvPeriodos := TcxGridDBTableView.Create(cxgrdPeriodos);
  glPeriodos := cxgrdPeriodos.Levels.Add;
  glPeriodos.GridView := tvPeriodos;
  AsignarTexto(glPeriodos, 'Caption', @SCaptionPeriodosTarifa);
  tvPeriodos.OptionsData.Deleting := False;
  tvPeriodos.OptionsData.Inserting := False;
  tvPeriodos.OptionsData.Appending := False;
  tvPeriodos.OptionsView.GroupByBox := False;
  tvPeriodos.DataController.KeyFieldNames := 'ID_TARCP';
end;

// Valores fijos con el mismo texto que los combos de la cabecera.
procedure TfrmMtoTarifasCambios.ColumnaOpciones(AColumna: TcxGridDBColumn;
  const ACampo: string; const AValores: array of string);
var
  Opcion: TcxImageComboBoxItem;
  Propiedades: TcxImageComboBoxProperties;
  rOpcion: TOpcionDinamica;
  sValor: string;
begin
  if not Assigned(FOpcionesDinamicas) then
    FOpcionesDinamicas := TList<TOpcionDinamica>.Create;
  AColumna.PropertiesClass := TcxImageComboBoxProperties;
  Propiedades := AColumna.Properties as TcxImageComboBoxProperties;
  for sValor in AValores do
  begin
    Opcion := Propiedades.Items.Add;
    Opcion.Value := sValor;
    Opcion.Description := TextoValorDocumento(ACampo, sValor);
    rOpcion.Opcion := Opcion;
    rOpcion.Campo := ACampo;
    rOpcion.Valor := sValor;
    FOpcionesDinamicas.Add(rOpcion);
  end;
end;

procedure TfrmMtoTarifasCambios.ColumnaSiNo(AColumna: TcxGridDBColumn);
var
  Propiedades: TcxCheckBoxProperties;
begin
  AColumna.PropertiesClass := TcxCheckBoxProperties;
  Propiedades := AColumna.Properties as TcxCheckBoxProperties;
  Propiedades.ValueChecked := 'S';
  Propiedades.ValueUnchecked := 'N';
end;

procedure TfrmMtoTarifasCambios.CrearColumnasPeriodos;
begin
  if tvPeriodos.ColumnCount = 0 then
  begin
    CrearColumna(tvPeriodos, 'NUMERO_TARCP', @SCaptionPeriodoTarifaNumero,
      40).Options.Editing := False;
    CrearColumna(tvPeriodos, 'NOMBRE_TARCP', @SCaptionPeriodoTarifaNombre,
      160);
    CrearColumna(tvPeriodos, 'FECHA_DESDE_TARCP', @SCaptionCambioTarifaDesde,
      95);
    CrearColumna(tvPeriodos, 'FECHA_HASTA_TARCP', @SCaptionCambioTarifaHasta,
      95);
    ColumnaOpciones(CrearColumna(tvPeriodos, 'TIPO_APLICACION_TARCP',
      @SCaptionCambioAplicar, 150), 'TIPO_APLICACION_TARC',
      ['COPIAR', 'INCREMENTO_LINEAL', 'INCREMENTO_PORCENTUAL',
       'PRECIO_FIJO']);
    FormatoImporte(CrearColumna(tvPeriodos, 'VALOR_APLICACION_TARCP',
      @SCaptionCambioValor, 80), '0.00');
    ColumnaOpciones(CrearColumna(tvPeriodos, 'CAMPO_ORIGEN_TARCP',
      @SCaptionCambioCampoOrigen, 140), 'CAMPO_ORIGEN_TARC',
      ['PRECIO_ORIGEN', 'PRECIO_COSTE', 'PRECIO_DESTINO_ACTUAL']);
    ColumnaOpciones(CrearColumna(tvPeriodos, 'CAMPO_DESTINO_TARCP',
      @SCaptionCambioCampoDestino, 130), 'CAMPO_DESTINO_TARC',
      ['AMBOS', 'PRECIO_SALIDA', 'PRECIO_FINAL']);
    FormatoImporte(CrearColumna(tvPeriodos, 'VALOR_REDONDEO_TARCP',
      @SCaptionCambioRedondeo, 80), FMT_EUROS);
    FormatoImporte(CrearColumna(tvPeriodos, 'VALOR_MENOS_AJUSTE_TARCP',
      @SCaptionCambioMenos, 80), FMT_EUROS);
    ColumnaSiNo(CrearColumna(tvPeriodos, 'ESREDONDEAR_ARRIBA_TARCP',
      @SCaptionRedondearHaciaArriba, 90));
    CrearColumna(tvPeriodos, 'ESTADO_TARCP', @SCaptionCambioTarifaEstado,
      90).Options.Editing := False;
  end;
end;

// Sesion aplicada: periodos de solo lectura. Con periodos, los parametros y
// las fechas de la cabecera no se usan: cada periodo tiene los suyos.
procedure TfrmMtoTarifasCambios.ActualizarEstadoPeriodos;
var
  EsEditable: Boolean;
  EsPorPeriodos: Boolean;
  Sesion: Integer;
begin
  if Assigned(dmmTarifasCambios) and Assigned(tvPeriodos) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active then
  begin
    EsPorPeriodos := dmmTarifasCambios.EsSesionPorPeriodos;
    EsEditable := PuedeAccionMto(apmModificar) and
      (not dsTablaG.DataSet.IsEmpty) and
      not SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
        'APLICADA');
    tvPeriodos.OptionsData.Editing := EsEditable;
    btnAnadirPeriodo.Enabled := EsEditable;
    btnEliminarPeriodo.Enabled := EsEditable and EsPorPeriodos;
    pnlParametros.Enabled := not EsPorPeriodos;
    dteDesde.Enabled := not EsPorPeriodos;
    dteHasta.Enabled := not EsPorPeriodos;
    // Al cambiar de sesión, la rejilla se ve solo si la sesión tiene
    // periodos; dentro de una misma sesión manda el botón Ver/Ocultar.
    Sesion := 0;
    if not dsTablaG.DataSet.IsEmpty then
      Sesion := dsTablaG.DataSet.FieldByName('CODIGO_TARC').AsInteger;
    if (not FPeriodosVistaIniciada) or (FSesionVistaPeriodos <> Sesion) then
    begin
      FPeriodosVistaIniciada := True;
      FSesionVistaPeriodos := Sesion;
      MostrarPeriodos(EsPorPeriodos);
    end;
  end;
end;

// Al cambiar de sesion, las lineas llegadas sin periodo (p. ej. desde un
// documento de trabajo) se reparten en sus periodos.
procedure TfrmMtoTarifasCambios.SincronizarPeriodosSesion;
begin
  if Assigned(dmmTarifasCambios) and (not FSincronizando) and
     (dsTablaG.DataSet.State = dsBrowse) then
  begin
    FSincronizando := True;
    try
      dmmTarifasCambios.SincronizarPeriodos;
    finally
      FSincronizando := False;
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.dsPeriodosDataChange(Sender: TObject;
  Field: TField);
begin
  if (Field = nil) and Assigned(dmmTarifasCambios) and
     not (csDestroying in ComponentState) then
    dmmTarifasCambios.FiltrarLineasPeriodo;
end;

procedure TfrmMtoTarifasCambios.btnAnadirPeriodoClick(Sender: TObject);
var
  Periodos: TDataSet;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    dmmTarifasCambios.AnadirPeriodo;
    ActualizarEstadoPeriodos;
    // Al grabar una sesion nueva la rejilla se evalua antes de que exista el
    // periodo y queda oculta: con un periodo siempre se ve.
    MostrarPeriodos(True);
    Periodos := dmmTarifasCambios.unqryPeriodos;
    ShowMessage_fza(Format(SInfoPeriodoTarifaAnadido,
      [Periodos.FieldByName('NUMERO_TARCP').AsInteger,
       DateToStr(Periodos.FieldByName('FECHA_DESDE_TARCP').AsDateTime),
       DateToStr(Periodos.FieldByName('FECHA_HASTA_TARCP').AsDateTime)]));
  end;
end;

// La rejilla de periodos vuelve siempre encima de la barra de selección:
// con Align alTop, el orden lo marca Top al hacerse visible.
procedure TfrmMtoTarifasCambios.MostrarPeriodos(AVisible: Boolean);
begin
  if not Assigned(pnlPeriodos) or not Assigned(splPeriodos) then
    Exit;
  if AVisible then
  begin
    pnlPeriodos.Top := 0;
    splPeriodos.Top := pnlPeriodos.Height;
  end;
  pnlPeriodos.Visible := AVisible;
  splPeriodos.Visible := AVisible;
  if AVisible then
    splPeriodos.Top := pnlPeriodos.Top + pnlPeriodos.Height;
  if AVisible then
    btnVerPeriodos.Caption := SCaptionOcultarPeriodosTarifa
  else
    btnVerPeriodos.Caption := SCaptionVerPeriodosTarifa;
end;

procedure TfrmMtoTarifasCambios.btnVerPeriodosClick(Sender: TObject);
begin
  MostrarPeriodos(not pnlPeriodos.Visible);
end;

procedure TfrmMtoTarifasCambios.btnEliminarPeriodoClick(Sender: TObject);
var
  Periodos: TDataSet;
  sPregunta: string;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    Periodos := dmmTarifasCambios.unqryPeriodos;
    sPregunta := SPreguntaEliminarPeriodoTarifa;
    if Periodos.RecordCount = 1 then
      sPregunta := SPreguntaEliminarUltimoPeriodoTarifa;
    if dmmTarifasCambios.IdPeriodoActual = 0 then
      ShowMessage_fza(SErrorPeriodoTarifaNoSeleccionado)
    else if MessageDlg_fza(Format(sPregunta,
      [Periodos.FieldByName('NUMERO_TARCP').AsInteger,
       Periodos.FieldByName('NOMBRE_TARCP').AsString]),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      dmmTarifasCambios.EliminarPeriodoActual;
      ActualizarEstadoPeriodos;
    end;
  end;
end;

// ===========================================================================
//   Pestaña de prueba: precio que cobraría la caja
// ===========================================================================

const
  PARAMETRO_TARIFA_PERIODICA = 'vgerTarifaPeriodicaAutomatica';
  FMT_PORCENTAJE_PRUEBA = '0.00 %';

procedure TfrmMtoTarifasCambios.CrearPestanaPrueba;
var
  X, Y: Integer;
begin
  tsPrueba := TcxTabSheet.Create(Self);
  tsPrueba.PageControl := pcDetalle;
  AsignarTexto(tsPrueba, 'Caption', @SCaptionTabPruebaPrecio);
  pnlPrueba := TcxGroupBox.Create(Self);
  pnlPrueba.Parent := tsPrueba;
  pnlPrueba.Align := alTop;
  pnlPrueba.PanelStyle.Active := True;
  pnlPrueba.Style.BorderStyle := ebsNone;
  pnlPrueba.Transparent := True;
  pnlPrueba.Height := Esc(FICHA_ALTO_FILA) + Esc(40);
  Y := Esc(8);
  X := Esc(FICHA_MARGEN);
  CrearEtiqueta(pnlPrueba, @SCaptionPruebaPrecioSku, X, Y + Esc(3));
  Inc(X, AnchoTexto(SCaptionPruebaPrecioSku) + Esc(FICHA_SEP_ETIQ));
  edtPruebaSku := TcxTextEdit.Create(Self);
  edtPruebaSku.Parent := pnlPrueba;
  edtPruebaSku.SetBounds(X, Y, Esc(220), edtPruebaSku.Height);
  Inc(X, Esc(220) + Esc(FICHA_SEP_COLUMNA));
  CrearEtiqueta(pnlPrueba, @SCaptionPruebaPrecioTarifa, X, Y + Esc(3));
  Inc(X, AnchoTexto(SCaptionPruebaPrecioTarifa) + Esc(FICHA_SEP_ETIQ));
  cbbPruebaTarifa := TcxLookupComboBox.Create(Self);
  cbbPruebaTarifa.Parent := pnlPrueba;
  cbbPruebaTarifa.SetBounds(X, Y, Esc(200), cbbPruebaTarifa.Height);
  cbbPruebaTarifa.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbPruebaTarifa.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
  cbbPruebaTarifa.Properties.ListOptions.ShowHeader := False;
  cbbPruebaTarifa.Properties.ClearKey := VK_DELETE;
  Inc(X, Esc(200) + Esc(FICHA_SEP_COLUMNA));
  CrearEtiqueta(pnlPrueba, @SCaptionPruebaPrecioFecha, X, Y + Esc(3));
  Inc(X, AnchoTexto(SCaptionPruebaPrecioFecha) + Esc(FICHA_SEP_ETIQ));
  dtePruebaFecha := TcxDateEdit.Create(Self);
  dtePruebaFecha.Parent := pnlPrueba;
  dtePruebaFecha.SetBounds(X, Y, Esc(130), dtePruebaFecha.Height);
  dtePruebaFecha.Date := Date;
  Inc(X, Esc(130) + Esc(FICHA_SEP_COLUMNA));
  btnPruebaCalcular := CrearBoton(pnlPrueba,
    @SCaptionPruebaPrecioCalcular, btnPruebaCalcularClick);
  ColocarBoton(btnPruebaCalcular, Y - Esc(1), X);
  CrearEtiqueta(pnlPrueba, @SAyudaPruebaPrecio, Esc(FICHA_MARGEN),
    Y + Esc(FICHA_ALTO_FILA));
  mPruebaResultado := TcxMemo.Create(Self);
  mPruebaResultado.Parent := tsPrueba;
  mPruebaResultado.Align := alClient;
  mPruebaResultado.Properties.ReadOnly := True;
  mPruebaResultado.Properties.ScrollBars := ssVertical;
end;

// Convierte lo escrito (artículo, SKU o código de barras) en artículo y SKU
// como lo haría la lectura de caja, y añade tarifa, fecha y parámetros.
function TfrmMtoTarifasCambios.LeerEntradaPrueba(
  out AEntrada: TEntradaSimulacionPrecioCaja; out AError: string): Boolean;
var
  Lectura: TArtResolucionEntrada;
  sTexto: string;
begin
  AEntrada := Default(TEntradaSimulacionPrecioCaja);
  AError := '';
  sTexto := Trim(edtPruebaSku.Text);
  Lectura := Default(TArtResolucionEntrada);
  if sTexto <> '' then
    Lectura := FSimulacion.Validador.Resolver(sTexto);
  if sTexto = '' then
    AError := SErrorPruebaPrecioSinSku
  else if not Lectura.Encontrado then
    AError := Format(SErrorPruebaPrecioNoEncontrado, [sTexto])
  else if Lectura.RequiereSku and (Lectura.CodigoSku = '') then
    AError := Format(SErrorPruebaPrecioRequiereSku,
      [Lectura.CodigoArticulo]);
  Result := AError = '';
  if Result then
  begin
    AEntrada.CodigoArticulo := Lectura.CodigoArticulo;
    AEntrada.CodigoSku := Lectura.CodigoSku;
    AEntrada.TarifaSolicitada := VarToStr(cbbPruebaTarifa.EditValue);
    AEntrada.Fecha := dtePruebaFecha.Date;
    AEntrada.TarifaDefecto := ParametrosCaja.TarifaDefecto;
    AEntrada.TarifaPeriodica := ParametrosCaja.GetString(
      PARAMETRO_TARIFA_PERIODICA, '');
  end;
end;

function TextoFechaPrueba(AFecha: TDateTime): string;
begin
  Result := SPruebaPrecioSinLimite;
  if AFecha <> 0 then
    Result := DateToStr(AFecha);
end;

procedure TfrmMtoTarifasCambios.MostrarResultadoPrueba(
  const AEntrada: TEntradaSimulacionPrecioCaja;
  const AResultado: TResultadoSimulacionPrecioCaja);
var
  stLineas: TStrings;
  sTexto: string;
begin
  stLineas := mPruebaResultado.Lines;
  stLineas.BeginUpdate;
  try
    stLineas.Clear;
    stLineas.Add(Format(SPruebaPrecioArticulo, [AEntrada.CodigoArticulo,
      AEntrada.CodigoSku, DateToStr(AEntrada.Fecha)]));
    // FZ-ISSUE-942: lo que diria la caja de la tarifa pedida.
    if AResultado.Aviso <> '' then
      stLineas.Add(AResultado.Aviso);
    if AResultado.EsTarifaSolicitadaDescartada then
      stLineas.Add(Format(SPruebaPrecioTarifaDescartada,
        [AEntrada.TarifaSolicitada, AResultado.TarifaTicket]));
    if AResultado.TarifaTicket = '' then
    begin
      stLineas.Add(SPruebaPrecioSinPrecio);
      Exit;
    end;
    sTexto := AResultado.TarifaTicket;
    if AResultado.EsPeriodicaActiva then
      sTexto := Format(SPruebaPrecioPeriodicaActiva, [sTexto]);
    stLineas.Add(Format(SPruebaPrecioTarifaTicket, [sTexto]));
    sTexto := AResultado.TarifaAplicada;
    if AResultado.EsRespaldo then
      sTexto := Format(SPruebaPrecioRespaldo,
        [sTexto, AResultado.TarifaTicket]);
    stLineas.Add(Format(SPruebaPrecioTarifaAplicada, [sTexto]));
    if AResultado.EsPrecioValido then
    begin
      stLineas.Add(Format(SPruebaPrecioSalida,
        [FormatFloat(FMT_EUROS, AResultado.Precio.PrecioSalida)]));
      stLineas.Add(Format(SPruebaPrecioDescuento, [FormatFloat(
        FMT_PORCENTAJE_PRUEBA, AResultado.Precio.PorcentajeDto)]));
      stLineas.Add(Format(SPruebaPrecioVenta,
        [FormatFloat(FMT_EUROS, AResultado.PrecioVenta)]));
      stLineas.Add(Format(SPruebaPrecioVigencia,
        [TextoFechaPrueba(AResultado.Precio.FechaDesde),
         TextoFechaPrueba(AResultado.Precio.FechaHasta)]));
      if AResultado.Precio.Origen = aopEspecificoSku then
        stLineas.Add(SPruebaPrecioOrigenSku)
      else
        stLineas.Add(SPruebaPrecioOrigenArticulo);
    end
    else
      stLineas.Add(SPruebaPrecioSinPrecio);
  finally
    stLineas.EndUpdate;
  end;
end;

procedure TfrmMtoTarifasCambios.btnPruebaCalcularClick(Sender: TObject);
var
  Entrada: TEntradaSimulacionPrecioCaja;
  sError: string;
begin
  if LeerEntradaPrueba(Entrada, sError) then
    MostrarResultadoPrueba(Entrada,
      SimularPrecioCaja(FSimulacion, Entrada))
  else
    ShowMessage_fza(sError);
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
  // Elegida con el ratón, la opción solo vivía en el editor: al cerrarse
  // la lista y releer el campo volvía «Copiar» y se grababa COPIAR. Así
  // pasa al campo en cuanto se elige (FZ-ISSUE-945).
  cbbCampoOrigen.Properties.ImmediatePost := True;
  cbbCampoDestino.Properties.ImmediatePost := True;
  cbbTipoAplicacion.Properties.ImmediatePost := True;
  cbbTipoAplicacion.Properties.OnEditValueChanged :=
    cbbTipoAplicacionEditValueChanged;
  cbbTarifaOrigen.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbTarifaOrigen.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
  cbbTarifaDestino.Properties.KeyFieldNames := 'CODIGO_TAR_ARTTAR';
  cbbTarifaDestino.Properties.ListFieldNames := 'NOMBRE_TAR_TAR';
  // Una sola columna: sin cabecera, que mostraba el nombre del campo.
  cbbTarifaOrigen.Properties.ListOptions.ShowHeader := False;
  cbbTarifaDestino.Properties.ListOptions.ShowHeader := False;
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
  // FZ-ISSUE-944: en rebajas se puede cambiar la salida, pero avisando.
  dmmTarifasCambios.OnConfirmarCambioSalidaRebajas :=
    function: Boolean
    begin
      Result := MessageDlg_fza(SAvisoCambioSalidaRebajas, mtWarning,
        [mbYes, mbNo], 0) = mrYes;
    end;
  dmmTarifasCambios.unqryLineas.MasterFields := 'CODIGO_TARC';
  dmmTarifasCambios.unqryLineas.DetailFields := 'CODIGO_TARC_TARCLIN';
  dmmTarifasCambios.unqryLineas.MasterSource := dsTablaG;
  tvLineas.DataController.DataSource := dmmTarifasCambios.dsLineas;
  dmmTarifasCambios.unqryPeriodos.MasterFields := 'CODIGO_TARC';
  dmmTarifasCambios.unqryPeriodos.DetailFields := 'CODIGO_TARC_TARCP';
  dmmTarifasCambios.unqryPeriodos.MasterSource := dsTablaG;
  tvPeriodos.DataController.DataSource := dmmTarifasCambios.dsPeriodos;
  dmmTarifasCambios.dsPeriodos.OnDataChange := dsPeriodosDataChange;
  btnActualizarCostes.Enabled := PuedeAccionMto(apmModificar);
  btnEliminarLineas.Enabled := PuedeAccionMto(apmBorrar);
  nvNavegador.Buttons.Delete.Hint := SCaptionEliminarSesionCompleta;
  tvLineas.OptionsData.Deleting := PuedeAccionMto(apmBorrar);
  tvLineas.Navigator.Buttons.Delete.Enabled := True;
  cbbTarifaOrigen.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  cbbTarifaDestino.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  cbbPruebaTarifa.Properties.ListSource := dmmTarifasCambios.dsTarifas;
  pkFieldName := 'CODIGO_TARC';
  VincularDatos;
  CrearColumnasCabecera;
  CrearColumnasLineas;
  CrearColumnasPeriodos;
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
  if Assigned(tvPeriodos) then
  begin
    tvPeriodos.DataController.DataSource := nil;
    FreeAndNil(tvPeriodos);
  end;
  if Assigned(cbbTarifaOrigen) then
    cbbTarifaOrigen.Properties.ListSource := nil;
  if Assigned(cbbTarifaDestino) then
    cbbTarifaDestino.Properties.ListSource := nil;
  if Assigned(cbbPruebaTarifa) then
    cbbPruebaTarifa.Properties.ListSource := nil;
  if Assigned(dmmTarifasCambios) then
  begin
    if Assigned(dmmTarifasCambios.dsLineas) then
      dmmTarifasCambios.dsLineas.DataSet := nil;
    if Assigned(dmmTarifasCambios.dsTarifas) then
      dmmTarifasCambios.dsTarifas.DataSet := nil;
    if Assigned(dmmTarifasCambios.dsPeriodos) then
      dmmTarifasCambios.dsPeriodos.OnDataChange := nil;
    if Assigned(dmmTarifasCambios.unqryLineas) then
    begin
      if dmmTarifasCambios.unqryLineas.Active then
        dmmTarifasCambios.unqryLineas.Close;
      dmmTarifasCambios.unqryLineas.MasterSource := nil;
      dmmTarifasCambios.unqryLineas.MasterFields := '';
      dmmTarifasCambios.unqryLineas.DetailFields := '';
    end;
    if Assigned(dmmTarifasCambios.unqryPeriodos) then
    begin
      if dmmTarifasCambios.unqryPeriodos.Active then
        dmmTarifasCambios.unqryPeriodos.Close;
      dmmTarifasCambios.unqryPeriodos.MasterSource := nil;
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
    if Field = nil then
    begin
      SincronizarPeriodosSesion;
      ActualizarEstadoPeriodos;
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.CrearColumnasCabecera;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TARC', @SCaptionCambioCodigo, 70);
    CrearColumna(cxGrdDBTabPrin, 'NOMBRE_TARC', @SCaptionCambioTarifaNombre, 220);
    CrearColumna(cxGrdDBTabPrin, 'FECHA_TARC', @SCaptionCambioTarifaFecha, 90);
    CrearColumna(cxGrdDBTabPrin, 'ESTADO_TARC', @SCaptionCambioTarifaEstado, 100);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TAR_ORIGEN_TARC',
                 @SCaptionCambioTarifaOrigen, 120);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_TAR_DESTINO_TARC',
                 @SCaptionCambioTarifaDestino, 120);
    CrearColumna(cxGrdDBTabPrin, 'TIPO_APLICACION_TARC', @SCaptionCambioAplicacion, 150);
    CrearColumna(cxGrdDBTabPrin, 'VALOR_APLICACION_TARC', @SCaptionCambioValor, 90);
  end;
end;

procedure TfrmMtoTarifasCambios.CrearColumnasLineas;
var
  oStock: TcxGridDBColumn;
  i: Integer;
begin
  if tvLineas.ColumnCount = 0 then
  begin
    CrearColumna(tvLineas, 'ESAPLICAR_TARCLIN', @SCaptionCambioAplicar, 65);
    CrearColumna(tvLineas, 'ESTADO_TARCLIN', @SCaptionCambioTarifaEstado, 90);
    CrearColumna(tvLineas, 'CODIGO_ART_TARCLIN', @SCaptionCambioArticulo, 140);
    CrearColumna(tvLineas, 'CODIGO_UNIDAD_SKU_TARCLIN',
      @SCaptionColSku, 160).Options.Editing := False;
    CrearColumna(tvLineas, 'DESCRIPCION_ART', @SCaptionCambioDescripcion, 240);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_ORIGEN_TARCLIN',
                   @SCaptionCambioPrecioOrigen, 90), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_COSTE_TARCLIN',
                   @SCaptionCambioCoste, 90), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_SALIDA_ACTUAL_TARCLIN',
                   @SCaptionCambioSalidaActual, 100), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_FINAL_ACTUAL_TARCLIN',
                   @SCaptionCambioFinalActual, 100), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_NUEVO_TARCLIN',
                   @SCaptionCambioSalidaNueva, 100), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_DTO_NUEVO_TARCLIN',
                   @SCaptionCambioDtoNuevo, 90), FMT_EUROS);
    FormatoImporte(CrearColumna(tvLineas, 'PORCENTAJE_DTO_NUEVO_TARCLIN',
                   @SCaptionCambioPorcentajeDto, 90), FMT_PORCENTAJE);
    FormatoImporte(CrearColumna(tvLineas, 'PRECIO_FINAL_NUEVO_TARCLIN',
                   @SCaptionCambioFinalNuevo, 100), FMT_EUROS);
    // FZ-ISSUE-944: los precios (editables en cada periodo) antes que la
    // familia y el proveedor, que dejaban fuera de la vista Salida nueva.
    CrearColumna(tvLineas, 'NOMBRE_FAM_FAM', @SCaptionCambioFamilia, 160);
    CrearColumna(tvLineas, 'RAZON_SOCIAL_PRV', @SCaptionCambioProveedor, 180);
    CrearColumna(tvLineas, 'MENSAJE_TARCLIN', @SCaptionCambioMensaje, 180);
    oStock := CrearColumna(tvLineas, 'STOCK_ACTUAL', @SCaptionColStock, 100);
    FormatoImporte(oStock, '#,##0.######');
    oStock.Options.Editing := False;
    // FZ-ISSUE-944: líneas sin stock (0 o negativo) sombreadas.
    FEstiloSinStock := TcxStyle.Create(Self);
    FEstiloSinStock.AssignedValues := [cxStyles.svColor];
    FEstiloSinStock.Color := $00E0E0E0;
    for i := 0 to tvLineas.ColumnCount - 1 do
      tvLineas.Columns[i].Styles.OnGetContentStyle :=
        tvLineasGetContentStyle;
  end;
end;

procedure TfrmMtoTarifasCambios.tvLineasGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  ColStock: TcxGridDBColumn;
  Valor: Variant;
begin
  if (ARecord <> nil) and ARecord.IsData then
  begin
    ColStock := tvLineas.GetColumnByFieldName('STOCK_ACTUAL');
    if ColStock <> nil then
    begin
      Valor := ARecord.Values[ColStock.Index];
      if VarIsNull(Valor) or VarIsEmpty(Valor) or (Valor <= 0) then
        AStyle := FEstiloSinStock;
    end;
  end;
end;

procedure TfrmMtoTarifasCambios.CrearEtiqueta(AParent: TWinControl;
  ATexto: PResStringRec; AIzq, ATop: Integer);
var
  lbl: TcxLabel;
begin
  lbl := TcxLabel.Create(Self);
  lbl.Parent := AParent;
  lbl.Left := AIzq;
  lbl.Top := ATop;
  AsignarTexto(lbl, 'Caption', ATexto);
  lbl.Transparent := True;
end;

function TfrmMtoTarifasCambios.CrearColumna(AView: TcxGridDBTableView;
  const ACampo: string; ATitulo: PResStringRec;
  AAncho: Integer): TcxGridDBColumn;
begin
  Result := AView.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  AsignarTexto(Result, 'Caption', ATitulo);
  Result.Width := Esc(AAncho);
  if Result.Width < AnchoTexto(Result.Caption) + Esc(20) then
    Result.Width := AnchoTexto(Result.Caption) + Esc(20);
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
  if Assigned(dmmTarifasCambios) and
     (dmmTarifasCambios.unqryPeriodos.State in dsEditModes) then
    dmmTarifasCambios.unqryPeriodos.Post;
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
    begin
      dmmTarifasCambios.SincronizarPeriodos;
      dmmTarifasCambios.unqryLineas.Refresh;
    end;
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
  iSalidaCambiada : Integer;
begin
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    // Con periodos se aplican todos, no solo el que se ve.
    dmmTarifasCambios.SincronizarPeriodos;
    iLineas := dmmTarifasCambios.TotalLineasSesion;
    iSinPrecio := dmmTarifasCambios.LineasSinPrecioNuevo;
    iSalidaCambiada := dmmTarifasCambios.LineasPeriodoConSalidaCambiada;
    if iSinPrecio > 0 then
      ShowMessage_fza(Format(SErrorLineasSinPrecioNuevoSesionTarifa,
        [iSinPrecio]))
    // FZ-ISSUE-944: rebajas con la salida cambiada, contra la ley de consumo.
    else if (iSalidaCambiada > 0) and
      (MessageDlg_fza(Format(SAvisoAplicarSalidaCambiadaRebajas,
        [iSalidaCambiada]), mtWarning, [mbYes, mbNo], 0) <> mrYes) then
      Exit
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
    dmmTarifasCambios.SincronizarPeriodos;
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

// FZ-ISSUE-944: quita las lineas sin stock (0 o negativo). Como Borrar
// linea, un articulo se quita de todos los periodos de la sesion.
procedure TfrmMtoTarifasCambios.btnEliminarSinStockClick(Sender: TObject);
var
  Ids: TArray<Integer>;
  Mensaje: string;
  Lineas: TDataSet;
  Marca: TBookmark;
begin
  if PuedeAccionMto(apmBorrar) and GrabarCabeceraSiNecesario then
  begin
    if SameText(dsTablaG.DataSet.FieldByName('ESTADO_TARC').AsString,
      'APLICADA') then
      ShowMessage_fza(SErrorSesionTarifaAplicadaNoBorrarLineas)
    else
    begin
      Ids := nil;
      Lineas := dmmTarifasCambios.unqryLineas;
      if Lineas.Active then
      begin
        Lineas.DisableControls;
        Marca := Lineas.GetBookmark;
        try
          Lineas.First;
          while not Lineas.Eof do
          begin
            if Lineas.FieldByName('STOCK_ACTUAL').AsFloat <= 0 then
              Ids := Ids + [Lineas.FieldByName('ID_TARCLIN').AsInteger];
            Lineas.Next;
          end;
          if Lineas.BookmarkValid(Marca) then
            Lineas.GotoBookmark(Marca);
        finally
          Lineas.FreeBookmark(Marca);
          Lineas.EnableControls;
        end;
      end;
      if Length(Ids) = 0 then
        ShowMessage_fza(SInfoSesionSinLineasSinStock)
      else
      begin
        if Length(Ids) = 1 then
          Mensaje := SPreguntaEliminarUnaLineaSinStockSesion
        else
          Mensaje := Format(SPreguntaEliminarLineasSinStockSesion,
            [Length(Ids)]);
        if MessageDlg_fza(Mensaje, mtConfirmation, [mbYes, mbNo], 0) =
          mrYes then
          dmmTarifasCambios.EliminarLineasSesion(Ids);
      end;
    end;
  end;
end;

// FZ-ISSUE-944: etiquetas de los articulos de la sesion. La tarifa y la
// fecha se eligen en el modal (con fecha de un periodo, precio de rebaja).
// Una por articulo no reetiqueta todo el stock; si no, por stock.
procedure TfrmMtoTarifasCambios.btnEtiquetarClick(Sender: TObject);
var
  Formulario: TfrmPrintEtiqArt;
  DmArt: TdmArticulos;
  Respuesta: Integer;
begin
  if not PuedeImprimir then
    Abort;
  if Assigned(dmmTarifasCambios) and GrabarCabeceraSiNecesario then
  begin
    if dmmTarifasCambios.SkusEtiquetasSesionCsv(True) = '' then
      ShowMessage_fza(SInfoSesionSinArticulosEtiquetar)
    else
    begin
      Respuesta := MessageDlg_fza(SPreguntaEtiquetaPorArticuloSesion,
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Respuesta <> mrCancel then
      begin
        FEtiquetaPorArticulo := Respuesta = mrYes;
        DmArt := TdmArticulos.Create(nil);
        try
          FEtiquetasDmArt := DmArt;
          Formulario := TfrmPrintEtiqArt.Create(Application);
          try
            Formulario.DM := DmArt;
            Formulario.Caption := STituloEtiquetasSesionTarifa;
            Formulario.TextoOrigenExterno :=
              dsTablaG.DataSet.FieldByName('NOMBRE_TARC').AsString;
            Formulario.CargarAlmacenesExterno :=
              CargarAlmacenesEtiquetasSesion;
            Formulario.CrearDataSetExterno := CrearDataSetEtiquetasSesion;
            Formulario.ShowModal;
          finally
            FreeAndNil(Formulario);
          end;
        finally
          FEtiquetasDmArt := nil;
          FreeAndNil(DmArt);
        end;
      end;
    end;
  end;
end;

// Una por articulo: los almacenes no cuentan. Por stock: todos.
procedure TfrmMtoTarifasCambios.CargarAlmacenesEtiquetasSesion(
  ALV: TcxListView);
begin
  ALV.Items.Clear;
  if (not FEtiquetaPorArticulo) and (FEtiquetasDmArt is TdmArticulos) then
    TdmArticulos(FEtiquetasDmArt).CargarAlmacenesEtiquetas(ALV);
end;

procedure TfrmMtoTarifasCambios.CrearDataSetEtiquetasSesion(ADmArt: TObject;
  const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
var
  DmArt: TdmArticulos;
  Skus: string;
begin
  if ADmArt is TdmArticulos then
  begin
    DmArt := TdmArticulos(ADmArt);
    Skus := dmmTarifasCambios.SkusEtiquetasSesionCsv(FEtiquetaPorArticulo);
    if Skus = '' then
      DmArt.CrearDataSetEtiquetasArt('DUMMY_SIN_LINEAS', ACodTarifa, '',
        AFecha)
    else if FEtiquetaPorArticulo then
      DmArt.CrearDataSetEtiquetasArt('', ACodTarifa, '', AFecha, Skus)
    else
      // Con almacenes marcados ya replica una etiqueta por unidad de stock.
      DmArt.CrearDataSetEtiquetasArt('', ACodTarifa, AAlmacenesCsv, AFecha,
        Skus);
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
      ShowMessage_fza(SErrorSesionTarifaAplicadaNoActualizarCostes)
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
