{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGarantiasReclamaciones                                   }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       19/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ventas - Reclamaciones de garantía por número de serie (F-LOTEC-021).     }
{    Alta leyendo la serie (artículo, cliente, venta y fin de garantía salen   }
{    del histórico), envío al SAT, reparada, sustitución por otra unidad       }
{    (la devuelta entra en taras), abonada y rechazada. Solo con el            }
{    interruptor appGarantias encendido (el menú se oculta si no).             }
{    Desde el 19/10/2026 la ficha (montada en código) recoge el cliente y su   }
{    dirección de envío, el aparato y su modelo, el proveedor con sus datos    }
{    y las cuatro fases: recepción, envío al fabricante (RMA, tracking,        }
{    incidencias), recepción del fabricante y entrega al cliente.              }
{******************************************************************************}
unit inMtoGarantiasReclamaciones;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtons, cxCalendar, cxPC, cxCheckBox,
  cxDBEdit, cxMemo, cxImageComboBox, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxGroupBox,
  dxSkinsCore, dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges,
  dxCore,
  UniDataGarantiasReclamaciones, inLibGarantias, inMtoGen;

type
  TfrmMtoGarantiasReclamaciones = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados: Boolean;
    FCodigosEstado: TArray<string>;
    dmmGarantias: TdmGarantiasReclamaciones;
    pnlFiltros: TPanel;
    cbbEstado: TcxComboBox;
    edtTexto: TcxTextEdit;
    pnlFicha: TPanel;
    gbReclamacion: TcxGroupBox;
    gbCliente: TcxGroupBox;
    gbProveedor: TcxGroupBox;
    txtEstadoFicha: TcxTextEdit;
    txtResolucionFicha: TcxTextEdit;
    cbbProveedor: TcxDBLookupComboBox;
    pcFases: TcxPageControl;
    tsRecepcion: TcxTabSheet;
    tsEnvioFab: TcxTabSheet;
    tsRecepcionFab: TcxTabSheet;
    tsEntregaCli: TcxTabSheet;
    function EscalarDpi(AValor: Integer): Integer;
    procedure CrearFiltros;
    procedure CrearBotones;
    function CrearEtiqueta(const ATexto: string;
      AIzq, ATop: Integer): TcxLabel;
    function CrearBoton(const ATexto: string; AIzq, ATop, AAncho: Integer;
      AAlPulsar: TNotifyEvent): TcxButton;
    procedure CargarComboEstados;
    function CrearColumna(const ACampo, ATitulo: string;
      AAncho: Integer): TcxGridDBColumn;
    procedure CrearColumnaFecha(const ACampo, ATitulo: string;
      const AFormato: string);
    procedure CrearColumnas;
    procedure EstadoGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure ResolucionGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure FaseGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    // Ficha montada en código: tres grupos arriba (reclamación, cliente,
    // proveedor) y las fases en pestañas debajo.
    procedure CrearFicha;
    function CrearGrupo(const ATitulo: string; AAncho: Integer;
      AAlineacion: TAlign): TcxGroupBox;
    function CrearPestana(const ATitulo: string): TcxTabSheet;
    procedure ColocarRotulo(AParent: TWinControl; const ATexto: string;
      AColumna, AFila: Integer);
    procedure ColocarEditor(AEditor: TWinControl; AParent: TWinControl;
      AColumna, AFila, AAncho: Integer; AEstirar: Boolean);
    function CrearTexto(AParent: TWinControl;
      const ARotulo, ACampo: string; AColumna, AFila: Integer;
      ASoloLectura: Boolean): TcxDBTextEdit;
    function CrearTextoLibre(AParent: TWinControl; const ARotulo: string;
      AFila: Integer): TcxTextEdit;
    function CrearFecha(AParent: TWinControl;
      const ARotulo, ACampo: string; AColumna, AFila: Integer): TcxDBDateEdit;
    function CrearMemo(AParent: TWinControl;
      const ARotulo, ACampo: string; AFila, AFilas: Integer): TcxDBMemo;
    function CrearCasilla(AParent: TWinControl;
      const ARotulo, ACampo: string; AColumna, AFila: Integer): TcxDBCheckBox;
    function CrearMedio(AParent: TWinControl;
      const ARotulo, ACampo: string; AColumna, AFila: Integer):
      TcxDBImageComboBox;
    procedure CrearGrupoReclamacion;
    procedure CrearGrupoCliente;
    procedure CrearGrupoProveedor;
    procedure CrearFases;
    procedure CrearFaseRecepcion;
    procedure CrearBotonResguardoRecepcion;
    procedure CrearFaseEnvioFabricante;
    procedure CrearFaseRecepcionFabricante;
    procedure CrearFaseEntregaCliente;
    function AnchoColumna(AParent: TWinControl; AColumna: Integer): Integer;
    procedure RotularPestana(APagina: TcxTabSheet; AOrden: Integer;
      const ATitulo, ACampoFecha: string);
    procedure DatosCambiados(Sender: TObject; Field: TField);
    function EstadoFiltro: string;
    function HayReclamacion: Boolean;
    function IdActual: Int64;
    function ReclamacionAbierta: Boolean;
    procedure Refrescar(AId: Int64);
    function ResumenSerie(const ADatos: TDatosSerieGarantia): string;
    function ConfirmarAlta(const ADatos: TDatosSerieGarantia): Boolean;
    procedure DarDeAlta(const ASerie: string);
    procedure Cerrar(const AEstado, AResolucion: string;
      APedirObservaciones: Boolean);
    procedure FiltroCambiado(Sender: TObject);
    procedure btnNuevaClick(Sender: TObject);
    procedure btnFichaClick(Sender: TObject);
    procedure btnResguardoClick(Sender: TObject);
    procedure MostrarResguardo;
    procedure btnEnviarSatClick(Sender: TObject);
    procedure btnReparadaClick(Sender: TObject);
    procedure btnSustituirClick(Sender: TObject);
    procedure btnAbonadaClick(Sender: TObject);
    procedure btnRechazarClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  protected
    procedure DoCreate; override;
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgGarantias,
  inLibDevExp, inLibGarantiasResguardo, inLibDatasets, inLibDir, frxClass;

{$R *.dfm}

const
  CAMPO_ID = 'ID_GAR';
  FORMATO_FECHA = 'dd/mm/yyyy';
  FORMATO_FECHA_HORA = 'dd/mm/yyyy hh:nn';
  // Rejilla de la ficha, en unidades de 96 ppp: rótulo y editor por fila.
  MARGEN_FICHA = 12;
  ANCHO_ROTULO_GRUPO = 104;
  // A 125 % «Reclamación transporte:» pasa de 180 unidades.
  ANCHO_ROTULO_FASE = 200;
  ALTO_FILA = 27;
  TOP_PRIMERA_FILA = 24;
  FILAS_GRUPO = 13;
  ANCHO_GRUPO_RECLAMACION = 420;
  ANCHO_GRUPO_CLIENTE = 390;
  ANCHO_GRUPO_PROVEEDOR = 380;
  ANCHO_NOMINAL_FASE = 1160;
  MARCA_FASE_HECHA = '✓ ';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoGarantiasReclamaciones.FormCreate(Sender: TObject);
begin
  if not FControlesCreados then
  begin
    CrearFiltros;
    CrearBotones;
    CrearFicha;
    FControlesCreados := True;
  end;
  inherited;
end;

// El título se fija tras la traducción del formulario base.
procedure TfrmMtoGarantiasReclamaciones.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloGarantiasReclamaciones;
end;

destructor TfrmMtoGarantiasReclamaciones.Destroy;
begin
  if Assigned(dsTablaG) then
    dsTablaG.OnDataChange := nil;
  if Assigned(cbbProveedor) then
    cbbProveedor.Properties.ListSource := nil;
  inherited;
end;

function TfrmMtoGarantiasReclamaciones.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoGarantiasReclamaciones.CrearEtiqueta(const ATexto: string;
  AIzq, ATop: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := pnlFiltros;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Caption := ATexto;
  Result.Transparent := True;
end;

function TfrmMtoGarantiasReclamaciones.CrearBoton(const ATexto: string;
  AIzq, ATop, AAncho: Integer; AAlPulsar: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Self);
  Result.Parent := pnlFiltros;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Width := EscalarDpi(AAncho);
  Result.Height := EscalarDpi(34);
  Result.Caption := ATexto;
  Result.OnClick := AAlPulsar;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFiltros;
begin
  pnlFiltros := TPanel.Create(Self);
  pnlFiltros.Parent := tsLista;
  pnlFiltros.Align := alTop;
  pnlFiltros.Height := EscalarDpi(96);
  pnlFiltros.BevelOuter := bvNone;
  CrearEtiqueta(SCaptionFiltroEstadoGarantia, 12, 16);
  cbbEstado := TcxComboBox.Create(Self);
  cbbEstado.Parent := pnlFiltros;
  cbbEstado.Left := EscalarDpi(90);
  cbbEstado.Top := EscalarDpi(12);
  cbbEstado.Width := EscalarDpi(200);
  cbbEstado.Properties.DropDownListStyle := lsFixedList;
  CrearEtiqueta(SCaptionFiltroSerieGarantia, 310, 16);
  edtTexto := TcxTextEdit.Create(Self);
  edtTexto.Parent := pnlFiltros;
  edtTexto.Left := EscalarDpi(430);
  edtTexto.Top := EscalarDpi(12);
  edtTexto.Width := EscalarDpi(260);
  CrearBoton(SCaptionGarantiaRefrescar, 710, 10, 110, FiltroCambiado);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearBotones;
begin
  CrearBoton(SCaptionGarantiaNueva, 12, 54, 110, btnNuevaClick);
  CrearBoton(SCaptionGarantiaEnviarSat, 130, 54, 130, btnEnviarSatClick);
  CrearBoton(SCaptionGarantiaReparada, 268, 54, 110, btnReparadaClick);
  CrearBoton(SCaptionGarantiaSustituir, 386, 54, 110, btnSustituirClick);
  CrearBoton(SCaptionGarantiaAbonada, 504, 54, 110, btnAbonadaClick);
  CrearBoton(SCaptionGarantiaRechazar, 622, 54, 110, btnRechazarClick);
  CrearBoton(SCaptionGarantiaExcel, 740, 54, 80, btnExcelClick);
  CrearBoton(SCaptionGarantiaFicha, 828, 54, 90, btnFichaClick);
  CrearBoton(SCaptionImprimirResguardo, 926, 54, 110, btnResguardoClick);
end;

// ---------------------------------------------------------------------------
// Ficha
// ---------------------------------------------------------------------------

// El ancho nominal (96 ppp) queda en Tag: el grupo alClient cambia de
// tamaño al mostrarse y sus editores se estiran por anclaje.
function TfrmMtoGarantiasReclamaciones.CrearGrupo(const ATitulo: string;
  AAncho: Integer; AAlineacion: TAlign): TcxGroupBox;
begin
  Result := TcxGroupBox.Create(Self);
  Result.Parent := pnlFicha;
  Result.Tag := AAncho;
  Result.Width := EscalarDpi(AAncho);
  Result.Align := AAlineacion;
  Result.Caption := ATitulo;
  Result.AlignWithMargins := True;
end;

function TfrmMtoGarantiasReclamaciones.CrearPestana(
  const ATitulo: string): TcxTabSheet;
begin
  Result := TcxTabSheet.Create(Self);
  Result.PageControl := pcFases;
  Result.Caption := ATitulo;
end;

// Los grupos de arriba tienen una sola columna de rótulos cortos; las
// pestañas de las fases, dos columnas con rótulos más largos.
function AnchoRotulo(AParent: TWinControl): Integer;
begin
  if AParent is TcxTabSheet then
    Result := ANCHO_ROTULO_FASE
  else
    Result := ANCHO_ROTULO_GRUPO;
end;

// Ancho útil (96 ppp) de una columna (0 o 1) del contenedor.
function TfrmMtoGarantiasReclamaciones.AnchoColumna(AParent: TWinControl;
  AColumna: Integer): Integer;
var
  iAnchoTotal: Integer;
begin
  if AParent is TcxTabSheet then
    iAnchoTotal := ANCHO_NOMINAL_FASE div 2
  else
    iAnchoTotal := AParent.Tag;
  Result := iAnchoTotal - MARGEN_FICHA - AnchoRotulo(AParent) - MARGEN_FICHA;
end;

procedure TfrmMtoGarantiasReclamaciones.ColocarRotulo(AParent: TWinControl;
  const ATexto: string; AColumna, AFila: Integer);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := AParent;
  oRotulo.Left := EscalarDpi(MARGEN_FICHA +
    AColumna * (ANCHO_NOMINAL_FASE div 2));
  oRotulo.Top := EscalarDpi(TOP_PRIMERA_FILA + AFila * ALTO_FILA + 3);
  oRotulo.Caption := ATexto;
  oRotulo.Transparent := True;
end;

// Un editor de la última columna se ancla a la derecha para seguir el
// ancho real del contenedor.
procedure TfrmMtoGarantiasReclamaciones.ColocarEditor(AEditor: TWinControl;
  AParent: TWinControl; AColumna, AFila, AAncho: Integer; AEstirar: Boolean);
begin
  AEditor.Parent := AParent;
  AEditor.Left := EscalarDpi(MARGEN_FICHA + AnchoRotulo(AParent) +
    AColumna * (ANCHO_NOMINAL_FASE div 2));
  AEditor.Top := EscalarDpi(TOP_PRIMERA_FILA + AFila * ALTO_FILA);
  AEditor.Width := EscalarDpi(AAncho);
  if AEstirar then
    AEditor.Anchors := [akLeft, akTop, akRight];
end;

function TfrmMtoGarantiasReclamaciones.CrearTexto(AParent: TWinControl;
  const ARotulo, ACampo: string; AColumna, AFila: Integer;
  ASoloLectura: Boolean): TcxDBTextEdit;
begin
  ColocarRotulo(AParent, ARotulo, AColumna, AFila);
  Result := TcxDBTextEdit.Create(Self);
  ColocarEditor(Result, AParent, AColumna, AFila,
    AnchoColumna(AParent, AColumna),
    (AColumna = 1) or not (AParent is TcxTabSheet));
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.ReadOnly := ASoloLectura;
  if ASoloLectura then
    Result.TabStop := False;
end;

// Texto no enlazado: estado y resolución se muestran traducidos.
function TfrmMtoGarantiasReclamaciones.CrearTextoLibre(
  AParent: TWinControl; const ARotulo: string; AFila: Integer): TcxTextEdit;
begin
  ColocarRotulo(AParent, ARotulo, 0, AFila);
  Result := TcxTextEdit.Create(Self);
  ColocarEditor(Result, AParent, 0, AFila, AnchoColumna(AParent, 0), True);
  Result.Properties.ReadOnly := True;
  Result.TabStop := False;
end;

function TfrmMtoGarantiasReclamaciones.CrearFecha(AParent: TWinControl;
  const ARotulo, ACampo: string; AColumna, AFila: Integer): TcxDBDateEdit;
begin
  ColocarRotulo(AParent, ARotulo, AColumna, AFila);
  Result := TcxDBDateEdit.Create(Self);
  ColocarEditor(Result, AParent, AColumna, AFila, 130, False);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.DisplayFormat := FORMATO_FECHA;
  Result.Properties.ShowTime := False;
end;

// Memo a todo el ancho que ocupa AFilas filas.
function TfrmMtoGarantiasReclamaciones.CrearMemo(AParent: TWinControl;
  const ARotulo, ACampo: string; AFila, AFilas: Integer): TcxDBMemo;
var
  iAncho: Integer;
begin
  ColocarRotulo(AParent, ARotulo, 0, AFila);
  Result := TcxDBMemo.Create(Self);
  if AParent is TcxTabSheet then
    iAncho := ANCHO_NOMINAL_FASE - MARGEN_FICHA - ANCHO_ROTULO_FASE -
      MARGEN_FICHA
  else
    iAncho := AnchoColumna(AParent, 0);
  ColocarEditor(Result, AParent, 0, AFila, iAncho, True);
  Result.Height := EscalarDpi(AFilas * ALTO_FILA - 4);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.ScrollBars := ssVertical;
  Result.Properties.WantReturns := False;
end;

function TfrmMtoGarantiasReclamaciones.CrearCasilla(AParent: TWinControl;
  const ARotulo, ACampo: string; AColumna, AFila: Integer): TcxDBCheckBox;
begin
  Result := TcxDBCheckBox.Create(Self);
  ColocarEditor(Result, AParent, AColumna, AFila,
    AnchoColumna(AParent, AColumna), False);
  Result.Caption := ARotulo;
  Result.Transparent := True;
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.ValueChecked := 'S';
  Result.Properties.ValueUnchecked := 'N';
end;

procedure AgregarMedio(ACombo: TcxDBImageComboBox; const AValor: string);
var
  oOpcion: TcxImageComboBoxItem;
begin
  oOpcion := ACombo.Properties.Items.Add;
  oOpcion.Value := AValor;
  oOpcion.Description := TextoMedioGarantia(AValor);
end;

function TfrmMtoGarantiasReclamaciones.CrearMedio(AParent: TWinControl;
  const ARotulo, ACampo: string; AColumna, AFila: Integer):
  TcxDBImageComboBox;
begin
  ColocarRotulo(AParent, ARotulo, AColumna, AFila);
  Result := TcxDBImageComboBox.Create(Self);
  ColocarEditor(Result, AParent, AColumna, AFila, 200, False);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  AgregarMedio(Result, MEDIO_GARANTIA_TIENDA);
  AgregarMedio(Result, MEDIO_GARANTIA_AGENCIA);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearGrupoReclamacion;
begin
  gbReclamacion := CrearGrupo(SCaptionGrupoReclamacion,
    ANCHO_GRUPO_RECLAMACION, alLeft);
  CrearTexto(gbReclamacion, SCaptionGarantiaNumero, CAMPO_ID, 0, 0, True);
  CrearTexto(gbReclamacion, SCaptionGarantiaFechaReclamacion,
    'FECHA_RECLAMACION_GAR', 0, 1, True);
  txtEstadoFicha := CrearTextoLibre(gbReclamacion,
    SCaptionGarantiaEstadoFicha, 2);
  CrearTexto(gbReclamacion, SCaptionGarantiaSerieFicha, 'LOTE_GAR', 0, 3,
    True);
  CrearTexto(gbReclamacion, SCaptionGarantiaSkuFicha, 'CODIGO_UNIDAD_GAR',
    0, 4, True);
  CrearTexto(gbReclamacion, SCaptionGarantiaArticuloFicha,
    'DESCRIPCION_ART', 0, 5, True);
  CrearTexto(gbReclamacion, SCaptionGarantiaModeloFicha, 'MODELO_GAR', 0, 6,
    False);
  CrearMemo(gbReclamacion, SCaptionGarantiaMotivoFicha, 'MOTIVO_GAR', 7, 2);
  CrearMemo(gbReclamacion, SCaptionGarantiaObservacionesFicha,
    'OBSERVACIONES_GAR', 9, 2);
  txtResolucionFicha := CrearTextoLibre(gbReclamacion,
    SCaptionGarantiaResolucionFicha, 11);
  CrearTexto(gbReclamacion, SCaptionGarantiaSerieEntregada,
    'LOTE_SUSTITUTO_GAR', 0, 12, True);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearGrupoCliente;
begin
  gbCliente := CrearGrupo(SCaptionGrupoClienteGarantia,
    ANCHO_GRUPO_CLIENTE, alLeft);
  CrearTexto(gbCliente, SCaptionGarantiaClienteFicha, 'CLIENTE', 0, 0, True);
  CrearTexto(gbCliente, SCaptionGarantiaNombreCliente,
    'NOMBRE_CLIENTE_GAR', 0, 1, False);
  CrearTexto(gbCliente, SCaptionGarantiaTelefonoFicha,
    'TELEFONO_CLIENTE_GAR', 0, 2, False);
  CrearTexto(gbCliente, SCaptionGarantiaCorreoFicha, 'EMAIL_CLIENTE_GAR',
    0, 3, False);
  CrearTexto(gbCliente, SCaptionGarantiaDireccionFicha,
    'DIRECCION_CLIENTE_GAR', 0, 4, False);
  CrearTexto(gbCliente, SCaptionGarantiaCodigoPostalFicha,
    'CODIGO_POSTAL_CLIENTE_GAR', 0, 5, False);
  CrearTexto(gbCliente, SCaptionGarantiaPoblacionFicha,
    'POBLACION_CLIENTE_GAR', 0, 6, False);
  CrearTexto(gbCliente, SCaptionGarantiaProvinciaFicha,
    'PROVINCIA_CLIENTE_GAR', 0, 7, False);
  CrearTexto(gbCliente, SCaptionGarantiaVentaFicha, 'VENTA', 0, 8, True);
  CrearTexto(gbCliente, SCaptionGarantiaFechaVentaFicha, 'FECHA_VENTA_GAR',
    0, 9, True);
  CrearTexto(gbCliente, SCaptionGarantiaFinGarantiaFicha,
    'FECHA_FIN_GARANTIA_GAR', 0, 10, True);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearGrupoProveedor;
begin
  gbProveedor := CrearGrupo(SCaptionGrupoProveedorGarantia,
    ANCHO_GRUPO_PROVEEDOR, alClient);
  ColocarRotulo(gbProveedor, SCaptionGarantiaProveedorFicha, 0, 0);
  cbbProveedor := TcxDBLookupComboBox.Create(Self);
  ColocarEditor(cbbProveedor, gbProveedor, 0, 0, 260, True);
  cbbProveedor.DataBinding.DataSource := dsTablaG;
  cbbProveedor.DataBinding.DataField := 'CODIGO_PRV_GAR';
  cbbProveedor.Properties.KeyFieldNames := 'CODIGO_PRV_PRV';
  cbbProveedor.Properties.ListFieldNames := 'RAZON_SOCIAL_PRV';
  cbbProveedor.Properties.DropDownListStyle := lsEditList;
  CrearTexto(gbProveedor, SCaptionGarantiaContactoFicha, 'CONTACTO_PRV',
    0, 1, True);
  CrearTexto(gbProveedor, SCaptionGarantiaTelefonoContacto,
    'TELEFONO_CONTACTO_PRV', 0, 2, True);
  CrearTexto(gbProveedor, SCaptionGarantiaTelefonoFicha, 'TELEFONO_PRV',
    0, 3, True);
  CrearTexto(gbProveedor, SCaptionGarantiaMovilFicha, 'MOVIL_PRV', 0, 4,
    True);
  CrearTexto(gbProveedor, SCaptionGarantiaCorreoFicha, 'EMAIL_PRV', 0, 5,
    True);
  CrearTexto(gbProveedor, SCaptionGarantiaDireccionFicha, 'DIRECCION1_PRV',
    0, 6, True);
  CrearTexto(gbProveedor, SCaptionGarantiaCodigoPostalFicha,
    'CODIGO_POSTAL_PRV', 0, 7, True);
  CrearTexto(gbProveedor, SCaptionGarantiaPoblacionFicha, 'POBLACION_PRV',
    0, 8, True);
  CrearTexto(gbProveedor, SCaptionGarantiaProvinciaFicha, 'PROVINCIA_PRV',
    0, 9, True);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearBotonResguardoRecepcion;
var
  oBoton: TcxButton;
begin
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := tsRecepcion;
  oBoton.Caption := SCaptionImprimirResguardo;
  oBoton.SetBounds(EscalarDpi(12), EscalarDpi(200), EscalarDpi(140),
    EscalarDpi(30));
  oBoton.OnClick := btnResguardoClick;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseRecepcion;
begin
  tsRecepcion := CrearPestana(SCaptionFaseRecepcion);
  CrearFecha(tsRecepcion, SCaptionGarantiaFechaRecepcion,
    'FECHA_RECEPCION_GAR', 0, 0);
  CrearMedio(tsRecepcion, SCaptionGarantiaMedio, 'MEDIO_RECEPCION_GAR', 1,
    0);
  CrearTexto(tsRecepcion, SCaptionGarantiaAgencia, 'AGENCIA_RECEPCION_GAR',
    0, 1, False);
  CrearTexto(tsRecepcion, SCaptionGarantiaTracking,
    'TRACKING_RECEPCION_GAR', 1, 1, False);
  CrearMemo(tsRecepcion, SCaptionGarantiaObservacionesFicha,
    'OBSERVACIONES_RECEPCION_GAR', 2, 3);
  CrearBotonResguardoRecepcion;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseEnvioFabricante;
begin
  tsEnvioFab := CrearPestana(SCaptionFaseEnvioFabricante);
  CrearFecha(tsEnvioFab, SCaptionGarantiaFechaEnvio, 'FECHA_ENVIO_FAB_GAR',
    0, 0);
  CrearTexto(tsEnvioFab, SCaptionGarantiaRmaFicha, 'RMA_GAR', 1, 0, False);
  CrearMemo(tsEnvioFab, SCaptionGarantiaDireccionEnvio,
    'DIRECCION_ENVIO_FAB_GAR', 1, 2);
  CrearTexto(tsEnvioFab, SCaptionGarantiaAgencia, 'AGENCIA_ENVIO_FAB_GAR',
    0, 3, False);
  CrearTexto(tsEnvioFab, SCaptionGarantiaTrackingEnvio,
    'TRACKING_ENVIO_FAB_GAR', 1, 3, False);
  CrearCasilla(tsEnvioFab, SCaptionGarantiaIncidencia,
    'ESINCIDENCIA_ENVIO_FAB_GAR', 0, 4);
  CrearTexto(tsEnvioFab, SCaptionGarantiaReclamacionTransporte,
    'RECLAMACION_TRANSPORTE_ENVIO_FAB_GAR', 1, 4, False);
  CrearMemo(tsEnvioFab, SCaptionGarantiaDetalleIncidencia,
    'INCIDENCIA_ENVIO_FAB_GAR', 5, 2);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseRecepcionFabricante;
begin
  tsRecepcionFab := CrearPestana(SCaptionFaseRecepcionFabricante);
  CrearFecha(tsRecepcionFab, SCaptionGarantiaFechaRecepcion,
    'FECHA_RECEPCION_FAB_GAR', 0, 0);
  CrearTexto(tsRecepcionFab, SCaptionGarantiaTrackingRecepcion,
    'TRACKING_RECEPCION_FAB_GAR', 1, 0, False);
  CrearCasilla(tsRecepcionFab, SCaptionGarantiaIncidencia,
    'ESINCIDENCIA_RECEPCION_FAB_GAR', 0, 1);
  CrearTexto(tsRecepcionFab, SCaptionGarantiaReclamacionTransporte,
    'RECLAMACION_TRANSPORTE_RECEPCION_FAB_GAR', 1, 1, False);
  CrearMemo(tsRecepcionFab, SCaptionGarantiaDetalleIncidencia,
    'INCIDENCIA_RECEPCION_FAB_GAR', 2, 2);
  CrearMemo(tsRecepcionFab, SCaptionGarantiaIntervencionFabricante,
    'OBSERVACIONES_RECEPCION_FAB_GAR', 4, 2);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseEntregaCliente;
begin
  tsEntregaCli := CrearPestana(SCaptionFaseEntregaCliente);
  CrearFecha(tsEntregaCli, SCaptionGarantiaFechaEntrega,
    'FECHA_ENTREGA_CLI_GAR', 0, 0);
  CrearMedio(tsEntregaCli, SCaptionGarantiaMedio, 'MEDIO_ENTREGA_CLI_GAR',
    1, 0);
  CrearTexto(tsEntregaCli, SCaptionGarantiaAgencia,
    'AGENCIA_ENTREGA_CLI_GAR', 0, 1, False);
  CrearTexto(tsEntregaCli, SCaptionGarantiaTracking,
    'TRACKING_ENTREGA_CLI_GAR', 1, 1, False);
  CrearCasilla(tsEntregaCli, SCaptionGarantiaIncidencia,
    'ESINCIDENCIA_ENTREGA_CLI_GAR', 0, 2);
  CrearTexto(tsEntregaCli, SCaptionGarantiaReclamacionTransporte,
    'RECLAMACION_TRANSPORTE_ENTREGA_CLI_GAR', 1, 2, False);
  CrearMemo(tsEntregaCli, SCaptionGarantiaDetalleIncidencia,
    'INCIDENCIA_ENTREGA_CLI_GAR', 3, 2);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFases;
begin
  pcFases := TcxPageControl.Create(Self);
  pcFases.Parent := tsFicha;
  pcFases.Align := alClient;
  CrearFaseRecepcion;
  CrearFaseEnvioFabricante;
  CrearFaseRecepcionFabricante;
  CrearFaseEntregaCliente;
  pcFases.ActivePage := tsRecepcion;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFicha;
begin
  pnlFicha := TPanel.Create(Self);
  pnlFicha.Parent := tsFicha;
  pnlFicha.Align := alTop;
  pnlFicha.Height := EscalarDpi(TOP_PRIMERA_FILA +
    FILAS_GRUPO * ALTO_FILA + 16);
  pnlFicha.BevelOuter := bvNone;
  // Dos grupos alLeft ordenados por Left y el del proveedor ocupa el resto.
  CrearGrupoReclamacion;
  CrearGrupoCliente;
  gbCliente.Left := gbReclamacion.Left + gbReclamacion.Width;
  CrearGrupoProveedor;
  CrearFases;
end;

procedure TfrmMtoGarantiasReclamaciones.RotularPestana(
  APagina: TcxTabSheet; AOrden: Integer; const ATitulo, ACampoFecha: string);
var
  oCampo: TField;
  sMarca: string;
begin
  sMarca := '';
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active then
  begin
    oCampo := dsTablaG.DataSet.FindField(ACampoFecha);
    if Assigned(oCampo) and not oCampo.IsNull then
      sMarca := MARCA_FASE_HECHA;
  end;
  APagina.Caption := Format('%s%d. %s', [sMarca, AOrden, ATitulo]);
end;

// Estado y resolución traducidos, marca en las fases con fecha y lista de
// proveedores abierta ya con conexión (en el hilo principal).
procedure TfrmMtoGarantiasReclamaciones.DatosCambiados(Sender: TObject;
  Field: TField);
var
  oDatos: TDataSet;
begin
  oDatos := dsTablaG.DataSet;
  if Assigned(oDatos) and oDatos.Active then
  begin
    txtEstadoFicha.Text :=
      TextoEstadoGarantia(oDatos.FieldByName('ESTADO_GAR').AsString);
    txtResolucionFicha.Text :=
      TextoResolucionGarantia(oDatos.FieldByName('RESOLUCION_GAR').AsString);
    if Assigned(dmmGarantias) and
       not Assigned(cbbProveedor.Properties.ListSource) then
      cbbProveedor.Properties.ListSource := dmmGarantias.Proveedores;
  end
  else
  begin
    txtEstadoFicha.Text := '';
    txtResolucionFicha.Text := '';
  end;
  RotularPestana(tsRecepcion, 1, SCaptionFaseRecepcion,
    'FECHA_RECEPCION_GAR');
  RotularPestana(tsEnvioFab, 2, SCaptionFaseEnvioFabricante,
    'FECHA_ENVIO_FAB_GAR');
  RotularPestana(tsRecepcionFab, 3, SCaptionFaseRecepcionFabricante,
    'FECHA_RECEPCION_FAB_GAR');
  RotularPestana(tsEntregaCli, 4, SCaptionFaseEntregaCliente,
    'FECHA_ENTREGA_CLI_GAR');
end;

// ---------------------------------------------------------------------------
// Lista
// ---------------------------------------------------------------------------

procedure TfrmMtoGarantiasReclamaciones.CargarComboEstados;
begin
  FCodigosEstado := TArray<string>.Create(FILTRO_GARANTIA_PENDIENTES, '',
    ESTADO_GARANTIA_ABIERTA, ESTADO_GARANTIA_EN_SAT,
    ESTADO_GARANTIA_RESUELTA, ESTADO_GARANTIA_RECHAZADA);
  cbbEstado.Properties.OnChange := nil;
  try
    cbbEstado.Properties.Items.Clear;
    cbbEstado.Properties.Items.Add(SCaptionGarantiaAbiertas);
    cbbEstado.Properties.Items.Add(SCaptionGarantiaTodas);
    cbbEstado.Properties.Items.Add(SCaptionGarantiaAbierta);
    cbbEstado.Properties.Items.Add(SCaptionGarantiaEnSat);
    cbbEstado.Properties.Items.Add(SCaptionGarantiaResuelta);
    cbbEstado.Properties.Items.Add(SCaptionGarantiaRechazada);
    cbbEstado.ItemIndex := 0;
  finally
    cbbEstado.Properties.OnChange := FiltroCambiado;
  end;
end;

function TfrmMtoGarantiasReclamaciones.CrearColumna(
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := cxGrdDBTabPrin.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearColumnaFecha(
  const ACampo, ATitulo: string; const AFormato: string);
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := CrearColumna(ACampo, ATitulo, 110);
  oColumna.PropertiesClass := TcxDateEditProperties;
  TcxDateEditProperties(oColumna.Properties).DisplayFormat := AFormato;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearColumnas;
var
  oColumna: TcxGridDBColumn;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(CAMPO_ID, SCaptionColGarantiaId, 60);
    CrearColumnaFecha('FECHA_RECLAMACION_GAR', SCaptionColGarantiaFecha,
      FORMATO_FECHA_HORA);
    CrearColumna('LOTE_GAR', SCaptionColGarantiaSerie, 160);
    CrearColumna('CODIGO_UNIDAD_GAR', SCaptionColGarantiaSku, 140);
    CrearColumna('DESCRIPCION_ART', SCaptionColGarantiaArticulo, 220);
    CrearColumna('MODELO_GAR', SCaptionColGarantiaModelo, 120);
    CrearColumna('CLIENTE', SCaptionClienteVentaGarantia, 220);
    CrearColumna('NOMBRE_CLIENTE_GAR', SCaptionColGarantiaCliente, 160);
    CrearColumna('TELEFONO_CLIENTE_GAR', SCaptionColGarantiaTelefono, 100);
    CrearColumna('VENTA', SCaptionColGarantiaVenta, 130);
    CrearColumnaFecha('FECHA_VENTA_GAR', SCaptionColGarantiaFechaVenta,
      FORMATO_FECHA);
    CrearColumnaFecha('FECHA_FIN_GARANTIA_GAR', SCaptionColGarantiaFin,
      FORMATO_FECHA);
    // FZ-ISSUE-602: casilla y textos traducidos, no los códigos internos.
    oColumna := CrearColumna('ESEN_GARANTIA', SCaptionColGarantiaEnGarantia,
      80);
    oColumna.PropertiesClass := TcxCheckBoxProperties;
    TcxCheckBoxProperties(oColumna.Properties).ValueChecked := 'S';
    TcxCheckBoxProperties(oColumna.Properties).ValueUnchecked := 'N';
    TcxCheckBoxProperties(oColumna.Properties).DisplayChecked := 'S';
    TcxCheckBoxProperties(oColumna.Properties).DisplayUnchecked := 'N';
    oColumna := CrearColumna('ESTADO_GAR', SCaptionColGarantiaEstado, 100);
    oColumna.OnGetDisplayText := EstadoGetDisplayText;
    oColumna := CrearColumna('FASE_GAR', SCaptionColGarantiaFase, 150);
    oColumna.OnGetDisplayText := FaseGetDisplayText;
    CrearColumna('RAZON_SOCIAL_PRV', SCaptionColGarantiaProveedor, 180);
    CrearColumna('RMA_GAR', SCaptionColGarantiaRma, 120);
    oColumna := CrearColumna('RESOLUCION_GAR', SCaptionColGarantiaResolucion,
      100);
    oColumna.OnGetDisplayText := ResolucionGetDisplayText;
    CrearColumna('LOTE_SUSTITUTO_GAR', SCaptionColGarantiaSustituta, 160);
    CrearColumna('MOTIVO_GAR', SCaptionColGarantiaMotivo, 260);
    CrearColumna('OBSERVACIONES_GAR', SCaptionColGarantiaObservaciones,
      260);
    CrearColumna('USUARIO_ALTA', SCaptionColGarantiaUsuario, 110);
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.EstadoGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoEstadoGarantia(AText);
end;

procedure TfrmMtoGarantiasReclamaciones.ResolucionGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoResolucionGarantia(AText);
end;

procedure TfrmMtoGarantiasReclamaciones.FaseGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoFaseGarantia(AText);
end;

// La ficha se edita con el navegador (modificar, grabar, cancelar); el
// alta sigue siendo «Nueva» leyendo la serie y no se borra nada.
procedure TfrmMtoGarantiasReclamaciones.CrearTablaPrincipal;
begin
  inherited;
  dmmGarantias := tdmDataModule as TdmGarantiasReclamaciones;
  pkFieldName := CAMPO_ID;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  dsTablaG.OnDataChange := DatosCambiados;
  CargarComboEstados;
  CrearColumnas;
end;

procedure TfrmMtoGarantiasReclamaciones.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

function TfrmMtoGarantiasReclamaciones.EstadoFiltro: string;
begin
  Result := '';
  if (cbbEstado.ItemIndex >= 0) and
     (cbbEstado.ItemIndex <= High(FCodigosEstado)) then
    Result := FCodigosEstado[cbbEstado.ItemIndex];
end;

procedure TfrmMtoGarantiasReclamaciones.FiltroCambiado(Sender: TObject);
begin
  if Assigned(dmmGarantias) then
    dmmGarantias.AplicarFiltros(EstadoFiltro, edtTexto.Text);
end;

procedure TfrmMtoGarantiasReclamaciones.Refrescar(AId: Int64);
begin
  FiltroCambiado(nil);
  dmmGarantias.unqryTablaG.Locate(CAMPO_ID, AId, []);
end;

function TfrmMtoGarantiasReclamaciones.HayReclamacion: Boolean;
begin
  Result := Assigned(dmmGarantias) and dmmGarantias.unqryTablaG.Active and
    not dmmGarantias.unqryTablaG.IsEmpty;
  if not Result then
    ShowMessage_fza(SInfoSinReclamacion);
end;

function TfrmMtoGarantiasReclamaciones.IdActual: Int64;
begin
  Result := dmmGarantias.unqryTablaG.FieldByName(CAMPO_ID).AsLargeInt;
end;

function TfrmMtoGarantiasReclamaciones.ReclamacionAbierta: Boolean;
begin
  Result := HayReclamacion and EstadoGarantiaAbierto(
    dmmGarantias.unqryTablaG.FieldByName('ESTADO_GAR').AsString);
  if HayReclamacion and not Result then
    ShowMessage_fza(SErrorReclamacionCerrada);
end;

function TfrmMtoGarantiasReclamaciones.ResumenSerie(
  const ADatos: TDatosSerieGarantia): string;
begin
  if not ADatos.Vendida then
    Result := SResumenSinVentaGarantia
  else if not ADatos.TieneMeses then
    Result := Format(SResumenSinMesesGarantia,
      [DateToStr(ADatos.FechaVenta),
       ClienteVentaGarantia(ADatos.RazonSocialCliente),
       ADatos.DocumentoVenta])
  else
    Result := Format(SResumenVentaGarantia,
      [DateToStr(ADatos.FechaVenta),
       ClienteVentaGarantia(ADatos.RazonSocialCliente),
       ADatos.DocumentoVenta, DateToStr(ADatos.FechaFinGarantia)]);
end;

// Fuera de garantía o con otra reclamación abierta se pregunta; no se
// impide (decide la tienda).
function TfrmMtoGarantiasReclamaciones.ConfirmarAlta(
  const ADatos: TDatosSerieGarantia): Boolean;
begin
  Result := True;
  if ADatos.Vendida and ADatos.TieneMeses and not ADatos.EnGarantia then
    Result := MessageDlg_fza(Format(SAvisoFueraGarantia,
      [ADatos.Serie, DateToStr(ADatos.FechaFinGarantia)]), mtWarning,
      [mbYes, mbNo], 0, mbNo) = mrYes;
  if Result and (ADatos.ReclamacionesAbiertas > 0) then
    Result := MessageDlg_fza(Format(SAvisoReclamacionAbierta,
      [ADatos.Serie]), mtWarning, [mbYes, mbNo], 0, mbNo) = mrYes;
end;

// Tras el alta se abre la ficha para completar el cliente y la recepción.
procedure TfrmMtoGarantiasReclamaciones.DarDeAlta(const ASerie: string);
var
  Datos: TDatosSerieGarantia;
  sMotivo: string;
begin
  Datos := dmmGarantias.DatosSerie(ASerie);
  if not Datos.Encontrada then
    ShowMessage_fza(Format(SErrorSerieDesconocidaGarantia, [ASerie]))
  else if ConfirmarAlta(Datos) then
  begin
    sMotivo := '';
    if InputQuery_fza(STituloNuevaReclamacion,
         Format(SPreguntaMotivoReclamacion,
           [Datos.Serie, Datos.Descripcion, ResumenSerie(Datos)]),
         sMotivo) then
    begin
      Refrescar(dmmGarantias.Alta(Datos, sMotivo));
      pcPantalla.ActivePage := tsFicha;
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.btnNuevaClick(Sender: TObject);
var
  sSerie: string;
begin
  sSerie := '';
  if InputQuery_fza(STituloNuevaReclamacion, SPreguntaSerieReclamacion,
       sSerie) and (Trim(sSerie) <> '') then
    DarDeAlta(Trim(sSerie));
end;

procedure TfrmMtoGarantiasReclamaciones.btnFichaClick(Sender: TObject);
begin
  if HayReclamacion then
    pcPantalla.ActivePage := tsFicha;
end;

procedure TfrmMtoGarantiasReclamaciones.Cerrar(
  const AEstado, AResolucion: string; APedirObservaciones: Boolean);
var
  iId: Int64;
  sObservaciones: string;
  bSeguir: Boolean;
begin
  if ReclamacionAbierta then
  begin
    iId := IdActual;
    sObservaciones := '';
    bSeguir := (not APedirObservaciones) or InputQuery_fza(
      Format(STituloObservacionesGarantia, [IntToStr(iId)]),
      SPreguntaObservacionesGarantia, sObservaciones);
    if bSeguir then
    begin
      dmmGarantias.CambiarEstado(iId, AEstado, AResolucion,
        sObservaciones);
      Refrescar(iId);
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.btnEnviarSatClick(Sender: TObject);
begin
  Cerrar(ESTADO_GARANTIA_EN_SAT, '', True);
end;

procedure TfrmMtoGarantiasReclamaciones.btnReparadaClick(Sender: TObject);
begin
  Cerrar(ESTADO_GARANTIA_RESUELTA, RESOLUCION_GARANTIA_REPARADA, True);
end;

// El abono se hace en caja como una devolución con la misma serie; aquí
// solo se anota.
procedure TfrmMtoGarantiasReclamaciones.btnAbonadaClick(Sender: TObject);
begin
  Cerrar(ESTADO_GARANTIA_RESUELTA, RESOLUCION_GARANTIA_ABONADA, True);
end;

procedure TfrmMtoGarantiasReclamaciones.btnRechazarClick(Sender: TObject);
begin
  Cerrar(ESTADO_GARANTIA_RECHAZADA, '', True);
end;

procedure TfrmMtoGarantiasReclamaciones.btnSustituirClick(Sender: TObject);
var
  iId: Int64;
  sSerie, sAlmacen, sTaras, sDevuelta: string;
begin
  if ReclamacionAbierta then
  begin
    iId := IdActual;
    sDevuelta := dmmGarantias.unqryTablaG.FieldByName('LOTE_GAR').AsString;
    sAlmacen := dmmGarantias.UbicacionSesion.Almacen;
    sTaras := dmmGarantias.AlmacenTaras(sAlmacen);
    sSerie := '';
    if sTaras = '' then
      ShowMessage_fza(SErrorSinAlmacenTaras)
    else if InputQuery_fza(STituloSustituirSerie,
         Format(SPreguntaSerieSustituta, [sAlmacen]), sSerie) and
       (Trim(sSerie) <> '') then
    begin
      dmmGarantias.Sustituir(iId, sSerie, sAlmacen, sTaras);
      Refrescar(iId);
      ShowMessage_fza(Format(SInfoSustitucionHecha,
        [Trim(sSerie), sDevuelta, sTaras]));
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.btnResguardoClick(Sender: TObject);
begin
  if HayReclamacion then
  begin
    if ActualizarRegistroEnEdicion(dmmGarantias.unqryTablaG) then
      btnGrabarClick(Sender);
    if dmmGarantias.unqryTablaG.State = dsBrowse then
      MostrarResguardo;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.MostrarResguardo;
var
  oInforme: TfrxReport;
  Formato: TFormatoResguardoGarantia;
  Eleccion: Integer;
begin
  Eleccion := MessageDlgTextos_fza(SPreguntaFormatoResguardo,
    mtConfirmation, [mbYes, mbNo, mbCancel], ['A4', 'Ticket', ''], mbNo);
  if Eleccion = mrYes then
    Formato := frgA4
  else
    Formato := frgTicket;
  if Eleccion <> mrCancel then
  begin
    oInforme := TfrxReport.Create(nil);
    try
      CrearInformeResguardoGarantia(oInforme, dmmGarantias.DatosResguardo,
        Formato);
      if Formato = frgTicket then
        ImprimirResguardoGarantiaTicket(oInforme, PreviewTicket,
          ParametrosCaja.ImpresoraCaja, GetUserFolderTickets +
          'Resguardo_GAR_' + IntToStr(IdActual) + '_' +
          FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '.pdf')
      else
        oInforme.ShowReport;
    finally
      FreeAndNil(oInforme);
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.btnExcelClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxGrdPrincipal,
      Format(SNombreArchivoGarantias,
        [FormatDateTime('yyyymmdd', Date)]), False);
end;

initialization
  RegistrarPantalla(TfrmMtoGarantiasReclamaciones);
  ForceReferenceToClass(TfrmMtoGarantiasReclamaciones);
end.
