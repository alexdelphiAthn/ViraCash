{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGarantiasReclamaciones                                   }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.2.0                                                         }
{   Fecha:       30/10/2026                                                    }
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
{    y los datos de recepción, envío y resultado de la reparación.             }
{    El transporte y sus incidencias se registran en Seguimientos.              }
{    Desde el 30/10/2026, con appReparaciones, también reparaciones, arreglos  }
{    y taller sin número de serie: alta con su diálogo, pestaña Reparación     }
{    (presupuesto y líneas), entrega con cobro, anulación, liquidaciones y     }
{    tipos y externos (paneles de inMtoGarantiasReparacionesVcl).              }
{******************************************************************************}
unit inMtoGarantiasReclamaciones;

interface

uses
  inMtoReparacionesFasesVcl, inLibReparacionesFases,
  inMtoReparacionesSeguimientoVcl, inLibRegistroPantallas,
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
  cxDBLookupComboBox, cxGroupBox, cxButtonEdit,
  dxSkinsCore, dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges,
  dxCore,
  UniDataGarantiasReclamaciones, inLibGarantias, inLibReparaciones,
  inLibReparacionesDocumentos, inMtoGarantiasReparacionesVcl, inMtoGen;

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
    FScrollFicha: TScrollBox;
    FSeparadorFicha: TSplitter;
    gbReclamacion: TcxGroupBox;
    gbCliente: TcxGroupBox;
    gbProveedor: TcxGroupBox;
    txtEstadoFicha: TcxTextEdit;
    txtResolucionFicha: TcxTextEdit;
    cbbProveedor: TcxDBLookupComboBox;
    pcFases: TcxPageControl;
    pcSubconsultas: TcxPageControl;
    FSeparadorSubconsultas: TSplitter;
    FCambioPaginaAnterior: TNotifyEvent;
    tsRecepcion: TcxTabSheet;
    tsEnvioFab: TcxTabSheet;
    tsEntregaCli: TcxTabSheet;
    FFechaEntrega: TcxDBDateEdit;
    // Reparaciones (30/10/2026).
    FPanelFotos: TPanelFotosReparacion;
    FPanelFases: TPanelFasesReparacion;
    FPanelConfiguracion: TPanelConfiguracionReparaciones;
    tsFasesActuales: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tsFotosReparacion: TcxTabSheet;
    FEsReparaciones: Boolean;
    FEsSeries: Boolean;
    FCodigosModalidad: TArray<string>;
    cbbModalidad: TcxComboBox;
    btnNueva: TcxButton;
    btnSustituir: TcxButton;
    btnNuevaReparacion: TcxButton;
    btnEntregarReparacion: TcxButton;
    btnAnularReparacion: TcxButton;
    txtModalidadFicha: TcxTextEdit;
    tsReparacion: TcxTabSheet;
    tsCircuito: TcxTabSheet;
    tsTrabajos: TcxTabSheet;
    lblResumenTrabajos: TcxLabel;
    tsAlbaranes: TcxTabSheet;
    pcAlbaranes: TcxPageControl;
    tsAlbaranesCliente: TcxTabSheet;
    tsAlbaranesProveedor: TcxTabSheet;
    lblRepartoTrabajo: TcxLabel;
    FFranquiciaAnterior: TcxDBCurrencyEdit;
    FFranquiciaAcuerdo: TcxLabel;
    FNombreClienteAlbaran: array[0..1] of TcxLabel;
    FCodigoClienteAlbaran: array[0..1] of string;
    tsConfiguracionReparaciones: TcxTabSheet;
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
    function CrearImporte(AParent: TWinControl;
      const ARotulo, ACampo: string; AColumna, AFila: Integer):
      TcxDBCurrencyEdit;
    function CrearFecha(AParent: TWinControl;
      const ARotulo, ACampo: string; AColumna, AFila: Integer): TcxDBDateEdit;
    function CrearMemo(AParent: TWinControl;
      const ARotulo, ACampo: string; AFila, AFilas: Integer): TcxDBMemo;
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
    procedure CrearFaseEntregaCliente;
    function AnchoColumna(AParent: TWinControl; AColumna: Integer): Integer;
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
    procedure DocumentoReparacionClick(Sender: TObject);
    procedure MostrarDocumentoReparacion(ATipo: Integer;
      AMovimiento: Int64 = 0);
    procedure BotonDocumento(AParent: TWinControl; const ATexto: string;
      ATipo, AX, AY: Integer);
    procedure btnEnviarSatClick(Sender: TObject);
    procedure btnReparadaClick(Sender: TObject);
    procedure btnSustituirClick(Sender: TObject);
    procedure btnAbonadaClick(Sender: TObject);
    procedure btnRechazarClick(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
    procedure CrearFiltroModalidad;
    procedure CrearBotonesReparacion;
    procedure CrearFaseReparacion;
    procedure MedidasInstalacionClick(Sender: TObject);
    procedure CrearPestanasReparacion;
    procedure CrearAlbaranesOrden;
    procedure AjustarRotulos(AParent: TWinControl);
    procedure ActualizarRepartoTrabajo;
    function ConfirmarCobroEntrega(out ASerie, ANumero: string): Boolean;
    procedure ActualizarNombresAlbaranes;
    procedure BuscarClienteAlbaran(Sender: TObject; AButtonIndex: Integer);
    procedure OrganizarSubconsultas(Sender: TObject);
    procedure CrearPanelesReparacion;
    procedure LeerInterruptores;
    function ModalidadFiltro: string;
    function Enlaces: TEnlacesReparaciones;
    procedure ModalidadGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure FaseReparacionGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure btnNuevaReparacionClick(Sender: TObject);
    procedure btnEntregarReparacionClick(Sender: TObject);
    procedure btnAnularReparacionClick(Sender: TObject);
    function PedirTicketCobro(out ASerie, ANumero: string): Boolean;
    procedure EjecutarReparacion(AAccion: TProc);
    procedure AvisarFase(const AAviso: TAvisoFaseReparacion);
    procedure ImprimirHoja(const AHoja: THojaReparaciones);
  protected
    procedure DoCreate; override;
    procedure PrepararGuardado; override;
  public
    function SqlRestriccionUsuario: string; override;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  inMtoReparacionesCircuitoVcl, inLibMsgReparacionesCircuito,
  inMtoModalTrabajoCortina, inLibPermisosIntf, inLibFiltroUsuario,
  inLibShowMto, System.Math, Uni, inLibGenBusq, inLibMsgVentas,
  inMtoModalAvisoReparacion, inLibCorreoReparaciones,
  inLibMensajesVcl,
  inLibMsgGarantias, inLibMsgReparaciones, inLibReparacionesIntf,
  inMtoModalReparacion, inLibErroresBBDD, inLibTrazabilidad,
  inMtoModalImpReparacion,
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

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoGarantiasReclamaciones.FormCreate(Sender: TObject);
begin
  if not FControlesCreados then
  begin
    CrearFiltros;
    CrearBotones;
    CrearBotonesReparacion;
    CrearFicha;
    CrearPestanasReparacion;
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
  if Assigned(pcPantalla) then
    pcPantalla.OnChange := FCambioPaginaAnterior;
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
  pnlFiltros.Height := EscalarDpi(138);
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
  CrearFiltroModalidad;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearBotones;
begin
  btnNueva := CrearBoton(SCaptionGarantiaNueva, 12, 54, 110, btnNuevaClick);
  CrearBoton(SCaptionGarantiaEnviarSat, 130, 54, 130, btnEnviarSatClick);
  CrearBoton(SCaptionGarantiaReparada, 268, 54, 110, btnReparadaClick);
  btnSustituir := CrearBoton(SCaptionGarantiaSustituir, 386, 54, 110,
    btnSustituirClick);
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
  oRotulo.AutoSize := True;
  oRotulo.Transparent := True;
end;

procedure TfrmMtoGarantiasReclamaciones.AjustarRotulos(
  AParent: TWinControl);
var
  i, iColumna, iAncho, iDesplazamiento, iPaso: Integer;
  oControl: TControl;
begin
  iAncho := EscalarDpi(AnchoRotulo(AParent));
  for i := 0 to AParent.ControlCount - 1 do
  begin
    oControl := AParent.Controls[i];
    if (oControl is TcxLabel) and (oControl.Align = alNone) then
      iAncho := Max(iAncho, oControl.Width + EscalarDpi(8));
  end;
  iDesplazamiento := iAncho - EscalarDpi(AnchoRotulo(AParent));
  iPaso := EscalarDpi(ANCHO_NOMINAL_FASE div 2);
  for i := 0 to AParent.ControlCount - 1 do
  begin
    oControl := AParent.Controls[i];
    if oControl is TcxCustomEdit then
    begin
      iColumna := 0;
      if AParent is TcxTabSheet then
        iColumna := oControl.Left div iPaso;
      if oControl.Left >= EscalarDpi(MARGEN_FICHA) +
         iColumna * iPaso + EscalarDpi(AnchoRotulo(AParent)) then
      begin
        oControl.Left := oControl.Left + iDesplazamiento;
        if akRight in oControl.Anchors then
          oControl.Width := Max(EscalarDpi(60),
            oControl.Width - iDesplazamiento);
      end;
    end;
  end;
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

// Los importes se alinean a la derecha: su ancho no debe superar la
// página, aunque la ficha se cree mientras su pestaña está oculta.
function TfrmMtoGarantiasReclamaciones.CrearImporte(AParent: TWinControl;
  const ARotulo, ACampo: string; AColumna, AFila: Integer):
  TcxDBCurrencyEdit;
begin
  ColocarRotulo(AParent, ARotulo, AColumna, AFila);
  Result := TcxDBCurrencyEdit.Create(Self);
  ColocarEditor(Result, AParent, AColumna, AFila, 140, False);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.ReadOnly := True;
  Result.Properties.DisplayFormat := '#,##0.00';
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
  CrearTexto(gbReclamacion, SCaptionGarantiaNumero,
    'REFERENCIA_ORDEN', 0, 0, True);
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
  oBoton.SetBounds(EscalarDpi(12), EscalarDpi(230), EscalarDpi(140),
    EscalarDpi(30));
  oBoton.OnClick := btnResguardoClick;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseRecepcion;
var
  oModalidad: TcxDBImageComboBox;
  oOpcion: TcxImageComboBoxItem;
  sModalidad: string;
begin
  tsRecepcion := CrearPestana(SCaptionFaseRecepcion);
  CrearFecha(tsRecepcion, SCaptionGarantiaFechaRecepcion,
    'FECHA_RECEPCION_GAR', 0, 0);
  CrearMedio(tsRecepcion, SCaptionGarantiaMedio, 'MEDIO_RECEPCION_GAR', 1,
    0);
  ColocarRotulo(tsRecepcion, SRotuloModalidad, 0, 1);
  oModalidad := TcxDBImageComboBox.Create(Self);
  ColocarEditor(oModalidad, tsRecepcion, 0, 1, 250, False);
  oModalidad.DataBinding.DataSource := dsTablaG;
  oModalidad.DataBinding.DataField := 'MODALIDAD_GAR';
  oModalidad.Properties.DropDownListStyle := lsFixedList;
  for sModalidad in [MODALIDAD_REPARACION_PAGO,
    MODALIDAD_REPARACION_GARANTIA, MODALIDAD_REPARACION_CORTESIA] do
  begin
    oOpcion := oModalidad.Properties.Items.Add;
    oOpcion.Value := sModalidad;
    oOpcion.Description := TextoModalidadReparacion(sModalidad);
  end;
  CrearMemo(tsRecepcion, SRecepcionEstadoAccesorios,
    'OBSERVACIONES_RECEPCION_GAR', 2, 3);
  CrearBotonResguardoRecepcion;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseEnvioFabricante;
begin
  tsEnvioFab := CrearPestana(SDatosEnvioReparacion);
  CrearTexto(tsEnvioFab, SCaptionGarantiaRmaFicha, 'RMA_GAR', 0, 0, False);
  CrearMemo(tsEnvioFab, SCaptionGarantiaDireccionEnvio,
    'DIRECCION_ENVIO_FAB_GAR', 1, 3);
  BotonDocumento(tsEnvioFab, SImpresoEtiquetaFabricante,
    Ord(drFabricante), 12, 200);
  BotonDocumento(tsEnvioFab, SImpresoEtiquetaCliente,
    Ord(drCliente), 210, 200);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFaseEntregaCliente;
begin
  tsEntregaCli := CrearPestana(SResultadoEntregaReparacion);
  FFechaEntrega := CrearFecha(tsEntregaCli, SCaptionGarantiaFechaEntrega,
    'FECHA_ENTREGA_CLI_GAR', 0, 0);
  CrearMedio(tsEntregaCli, SCaptionGarantiaMedio, 'MEDIO_ENTREGA_CLI_GAR',
    1, 0);
  CrearMemo(tsEntregaCli, SIntervencionResultadoReparacion,
    'OBSERVACIONES_RECEPCION_FAB_GAR', 1, 3);
  BotonDocumento(tsEntregaCli, SImpresoAlbaran,
    Ord(drAlbaran), 12, 200);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFases;
begin
  pcFases := TcxPageControl.Create(Self);
  pcFases.Parent := tsFicha;
  pcFases.Align := alClient;
  CrearFaseRecepcion;
  CrearFaseReparacion;
  CrearFaseEnvioFabricante;
  CrearFaseEntregaCliente;
  CrearAlbaranesOrden;
  pcFases.ActivePage := tsRecepcion;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearAlbaranesOrden;
var
  oDatos: TcxGroupBox;

  procedure CrearCampo(const ARotulo, ACampo: string; AFila: Integer;
    AImporte: Boolean);
  var
    oFila, oValor: TPanel;
    oRotulo: TcxLabel;
    oTexto: TcxDBButtonEdit;
    oImporte: TcxDBCurrencyEdit;
  begin
    oFila := TPanel.Create(Self);
    oFila.Parent := oDatos;
    oFila.Top := EscalarDpi(AFila * 34);
    oFila.Align := alTop;
    oFila.Height := EscalarDpi(34);
    oFila.BevelOuter := bvNone;
    oFila.AlignWithMargins := True;
    oFila.Margins.SetBounds(EscalarDpi(8), 0, EscalarDpi(8), 0);
    oRotulo := TcxLabel.Create(Self);
    oRotulo.Parent := oFila;
    oRotulo.Caption := ARotulo;
    oRotulo.Align := alLeft;
    oRotulo.AutoSize := False;
    oRotulo.Width := EscalarDpi(280);
    oRotulo.Properties.Alignment.Vert := taVCenter;
    oRotulo.Transparent := True;
    oValor := TPanel.Create(Self);
    oValor.Parent := oFila;
    oValor.Align := alClient;
    oValor.AlignWithMargins := True;
    oValor.Margins.SetBounds(0, EscalarDpi(3), 0, EscalarDpi(3));
    oValor.BevelOuter := bvNone;
    if AImporte then
    begin
      oImporte := TcxDBCurrencyEdit.Create(Self);
      oImporte.Parent := oValor;
      oImporte.Align := alLeft;
      oImporte.Width := EscalarDpi(140);
      oImporte.DataBinding.DataSource := dsTablaG;
      oImporte.DataBinding.DataField := ACampo;
      oImporte.Properties.DisplayFormat := '#,##0.00';
      FFranquiciaAnterior := oImporte;
      FFranquiciaAcuerdo := TcxLabel.Create(Self);
      FFranquiciaAcuerdo.Parent := oValor;
      FFranquiciaAcuerdo.Align := alClient;
      FFranquiciaAcuerdo.Transparent := True;
      FFranquiciaAcuerdo.Visible := False;
    end
    else
    begin
      oTexto := TcxDBButtonEdit.Create(Self);
      oTexto.Parent := oValor;
      oTexto.Align := alLeft;
      oTexto.Width := EscalarDpi(220);
      oTexto.Properties.MaxLength := 20;
      oTexto.Tag := AFila;
      oTexto.Properties.Buttons.Clear;
      oTexto.Properties.Buttons.Add.Kind := bkEllipsis;
      oTexto.Properties.OnButtonClick := BuscarClienteAlbaran;
      oTexto.DataBinding.DataSource := dsTablaG;
      oTexto.DataBinding.DataField := ACampo;
      FNombreClienteAlbaran[AFila] := TcxLabel.Create(Self);
      FNombreClienteAlbaran[AFila].Parent := oValor;
      FNombreClienteAlbaran[AFila].Align := alClient;
      FNombreClienteAlbaran[AFila].AutoSize := False;
      FNombreClienteAlbaran[AFila].Caption := '';
      FNombreClienteAlbaran[AFila].Transparent := True;
      FNombreClienteAlbaran[AFila].Properties.Alignment.Vert := taVCenter;
      FNombreClienteAlbaran[AFila].AlignWithMargins := True;
      FNombreClienteAlbaran[AFila].Margins.Left := EscalarDpi(12);
      FNombreClienteAlbaran[AFila].ShowHint := True;
    end;
  end;

begin
  tsAlbaranes := CrearPestana(SAlbaranesOrden);
  oDatos := TcxGroupBox.Create(Self);
  oDatos.Parent := tsAlbaranes;
  oDatos.Tag := ANCHO_NOMINAL_FASE;
  oDatos.Align := alTop;
  oDatos.Height := EscalarDpi(140);
  oDatos.PanelStyle.Active := True;
  oDatos.Style.BorderStyle := ebsNone;
  oDatos.Transparent := True;
  CrearCampo(STitularTrabajo, 'CODIGO_CLI_GAR', 0, False);
  CrearCampo(SPagadorTrabajo, 'CODIGO_CLI_PAGADOR_GAR', 1, False);
  CrearCampo(SFranquiciaTrabajo, 'FRANQUICIA_GAR', 2, True);
  lblRepartoTrabajo := TcxLabel.Create(Self);
  lblRepartoTrabajo.Parent := oDatos;
  lblRepartoTrabajo.Align := alBottom;
  lblRepartoTrabajo.AlignWithMargins := True;
  lblRepartoTrabajo.Margins.Left := EscalarDpi(8);
  lblRepartoTrabajo.Transparent := True;
  pcAlbaranes := TcxPageControl.Create(Self);
  pcAlbaranes.Parent := tsAlbaranes;
  pcAlbaranes.Align := alClient;
  tsAlbaranesCliente := TcxTabSheet.Create(Self);
  tsAlbaranesCliente.PageControl := pcAlbaranes;
  tsAlbaranesCliente.Caption := SAlbaranesClienteTaller;
  tsAlbaranesProveedor := TcxTabSheet.Create(Self);
  tsAlbaranesProveedor.PageControl := pcAlbaranes;
  tsAlbaranesProveedor.Caption := SAlbaranesProveedorTaller;
  pcAlbaranes.ActivePage := tsAlbaranesCliente;
  NumerarPestanasAtajo(pcAlbaranes);
end;

procedure TfrmMtoGarantiasReclamaciones.BuscarClienteAlbaran(
  Sender: TObject; AButtonIndex: Integer);
const
  CAMPOS: array[0..1] of string = (
    'CODIGO_CLI_GAR', 'CODIGO_CLI_PAGADOR_GAR');
var
  oClientes: TUniQuery;
  oEditor: TcxDBButtonEdit;
  oDatos: TDataSet;
begin
  oEditor := Sender as TcxDBButtonEdit;
  oDatos := dsTablaG.DataSet;
  if PuedeAccionMto(apmModificar) and Assigned(oDatos) and
     oDatos.Active and not oDatos.IsEmpty and oDatos.CanModify then
  begin
    oClientes := dmmGarantias.ClientesBusqueda;
    try
      if BusquedaVisual.EjecutarBusquedaDataSet(STituloBusquedaClientes,
        oClientes, 'frmMtoCliReparacionesSearch', Self) and
        not oClientes.IsEmpty then
      begin
        oDatos.Edit;
        oDatos.FieldByName(CAMPOS[oEditor.Tag]).AsString :=
          oClientes.FieldByName('CODIGO_CLI_CLI').AsString;
        ActualizarNombresAlbaranes;
      end;
    finally
      oClientes.Free;
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.ActualizarNombresAlbaranes;
const
  CAMPOS: array[0..1] of string = (
    'CODIGO_CLI_GAR', 'CODIGO_CLI_PAGADOR_GAR');
var
  i: Integer;
  sCodigo: string;
  oDatos: TDataSet;
begin
  oDatos := dsTablaG.DataSet;
  for i := 0 to 1 do
    if Assigned(FNombreClienteAlbaran[i]) then
    begin
      sCodigo := '';
      if Assigned(oDatos) and oDatos.Active and not oDatos.IsEmpty then
        sCodigo := Trim(oDatos.FieldByName(CAMPOS[i]).AsString);
      if sCodigo <> FCodigoClienteAlbaran[i] then
      begin
        FNombreClienteAlbaran[i].Caption :=
          dmmGarantias.NombreCliente(sCodigo);
        FNombreClienteAlbaran[i].Hint := FNombreClienteAlbaran[i].Caption;
        FCodigoClienteAlbaran[i] := sCodigo;
      end;
    end;
end;

procedure TfrmMtoGarantiasReclamaciones.ActualizarRepartoTrabajo;
var
  oDatos: TDataSet;
  dTotal, dTitular: Currency;
  sReparto: string;
begin
  if Assigned(lblRepartoTrabajo) then
  begin
    lblRepartoTrabajo.Caption := '';
    oDatos := dsTablaG.DataSet;
    if Assigned(oDatos) and oDatos.Active and not oDatos.IsEmpty then
    begin
      dTotal := SimpleRoundTo(
        oDatos.FieldByName('TOTAL_CLIENTE_REP').AsCurrency, -2);
      dTitular := oDatos.FieldByName('FRANQUICIA_GAR').AsCurrency;
      if (Trim(oDatos.FieldByName('CODIGO_CLI_PAGADOR_GAR').AsString) = '') or
         SameText(Trim(oDatos.FieldByName('CODIGO_CLI_GAR').AsString),
           Trim(oDatos.FieldByName('CODIGO_CLI_PAGADOR_GAR').AsString)) then
        dTitular := dTotal;
      if (dTitular >= 0) and (dTitular <= dTotal) then
        lblRepartoTrabajo.Caption := Format(SRepartoTrabajo,
          [FormatFloat('#,##0.00', dTitular),
           FormatFloat('#,##0.00', dTotal - dTitular)]);
      sReparto := dmmGarantias.Reparaciones.Circuito.ResumenReparto(IdActual);
      if Assigned(FFranquiciaAcuerdo) then
      begin
        FFranquiciaAnterior.Visible := sReparto = '';
        FFranquiciaAcuerdo.Visible := sReparto <> '';
        if sReparto <> '' then
          FFranquiciaAcuerdo.Caption := CurrToStr(
            dmmGarantias.Reparaciones.Circuito.Cobertura.Acuerdo(
              IdActual).Franquicia);
      end;
      if sReparto <> '' then
        lblRepartoTrabajo.Caption := sReparto;
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearFicha;
begin
  FScrollFicha := TScrollBox.Create(Self);
  FScrollFicha.Name := 'scrollDatosOrden';
  FScrollFicha.Parent := tsFicha;
  FScrollFicha.Align := alTop;
  FScrollFicha.BorderStyle := bsNone;
  pnlFicha := TPanel.Create(Self);
  pnlFicha.Parent := FScrollFicha;
  pnlFicha.Align := alTop;
  pnlFicha.Height := EscalarDpi(TOP_PRIMERA_FILA +
    FILAS_GRUPO * ALTO_FILA + 16);
  pnlFicha.BevelOuter := bvNone;
  FScrollFicha.Height := pnlFicha.Height;
  // Dos grupos alLeft ordenados por Left y el del proveedor ocupa el resto.
  CrearGrupoReclamacion;
  CrearGrupoCliente;
  gbCliente.Left := gbReclamacion.Left + gbReclamacion.Width;
  CrearGrupoProveedor;
  AjustarRotulos(gbReclamacion);
  AjustarRotulos(gbCliente);
  AjustarRotulos(gbProveedor);
  FSeparadorFicha := TSplitter.Create(Self);
  FSeparadorFicha.Name := 'separadorDatosOrden';
  FSeparadorFicha.Parent := tsFicha;
  FSeparadorFicha.Align := alTop;
  FSeparadorFicha.Top := FScrollFicha.Top + FScrollFicha.Height;
  FSeparadorFicha.Height := EscalarDpi(7);
  FSeparadorFicha.MinSize := EscalarDpi(80);
  FSeparadorFicha.AutoSnap := False;
  FSeparadorFicha.ResizeStyle := rsUpdate;
  FSeparadorFicha.Beveled := True;
  CrearFases;
end;

// Las partes del resumen se separan por un punto medio.
function UnirNoVacios(const APartes: array of string): string;
var
  sParte: string;
begin
  Result := '';
  for sParte in APartes do
    if Trim(sParte) <> '' then
    begin
      if Result <> '' then
        Result := Result + '  ·  ';
      Result := Result + Trim(sParte);
    end;
end;

procedure TfrmMtoGarantiasReclamaciones.DatosCambiados(Sender: TObject;
  Field: TField);
var
  oDatos: TDataSet;
begin
  ActualizarRepartoTrabajo;
  ActualizarNombresAlbaranes;
  oDatos := dsTablaG.DataSet;
  if Assigned(oDatos) and oDatos.Active then
  begin
    txtEstadoFicha.Text :=
      TextoEstadoGarantia(oDatos.FieldByName('ESTADO_GAR').AsString);
    txtResolucionFicha.Text :=
      TextoResolucionGarantia(oDatos.FieldByName('RESOLUCION_GAR').AsString);
    txtModalidadFicha.Text := TextoModalidadReparacion(
      oDatos.FieldByName('MODALIDAD_GAR').AsString) + ' - ' +
      oDatos.FieldByName('FASE_ACTUAL').AsString;
    lblResumenTrabajos.Caption := UnirNoVacios([
      SRotuloNumeroDeposito + ' ' +
        oDatos.FieldByName('REFERENCIA_ORDEN').AsString,
      oDatos.FieldByName('OBJETO_REP').AsString,
      oDatos.FieldByName('NOMBRE_CLIENTE_GAR').AsString,
      txtModalidadFicha.Text]);
    if (oDatos.FieldByName('ESPRESUPUESTO_GAR').AsString = 'S') and
       not oDatos.FieldByName('TOTAL_PRESUPUESTO_GAR').IsNull then
      lblResumenTrabajos.Caption := UnirNoVacios([
        lblResumenTrabajos.Caption, SRotuloImportePresupuesto + ' ' +
        FormatFloat('#,##0.00',
          oDatos.FieldByName('TOTAL_PRESUPUESTO_GAR').AsCurrency)]);
    if Assigned(dmmGarantias) and
       not Assigned(cbbProveedor.Properties.ListSource) then
      cbbProveedor.Properties.ListSource := dmmGarantias.Proveedores;
  end
  else
  begin
    txtEstadoFicha.Text := '';
    txtResolucionFicha.Text := '';
    txtModalidadFicha.Text := '';
    lblResumenTrabajos.Caption := '';
  end;
  if Assigned(FPanelFotos) then
    FPanelFotos.MostrarReparacion(Enlaces.ReparacionActual());
  if Assigned(FPanelFases) then
  begin
    if Assigned(oDatos) and oDatos.Active and not oDatos.IsEmpty then
      FPanelFases.MostrarReparacion(IdActual,
        oDatos.FieldByName('CODIGO_FASE_ACTUAL').AsString,
        oDatos.FieldByName('FASE_ACTUAL').AsString)
    else
      FPanelFases.MostrarReparacion(0, '', '');
  end;
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
    CrearColumna('REFERENCIA_ORDEN', SCaptionColGarantiaId, 130);
    CrearColumna('MODALIDAD_GAR', SColModalidad, 100).OnGetDisplayText :=
      ModalidadGetDisplayText;
    CrearColumna('FASE_ACTUAL', SFaseActual, 280);
    CrearColumna('FASE_REP', SFaseSituacionTrabajos, 130).OnGetDisplayText :=
      FaseReparacionGetDisplayText;
    CrearColumna('CATEGORIA_GAR', SColTipoCategoria, 90);
    CrearColumna('OBJETO_REP', SColObjetoReparacion, 220);
    CrearColumnaFecha('FECHA_PREVISTA_GAR', SColEntregaAproximada,
      FORMATO_FECHA);
    CrearColumna('TOTAL_CLIENTE_REP', SColImporteCliente, 90);
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
  LeerInterruptores;
  CrearPanelesReparacion;
end;

function TfrmMtoGarantiasReclamaciones.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroOrdenesTrabajo(ContextoSesion, ParametrosApp);
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
    dmmGarantias.AplicarFiltros(EstadoFiltro, edtTexto.Text,
      ModalidadFiltro);
end;

procedure TfrmMtoGarantiasReclamaciones.Refrescar(AId: Int64);
begin
  FiltroCambiado(nil);
  if (AId > 0) and
     not dmmGarantias.unqryTablaG.Locate(CAMPO_ID, AId, []) then
  begin
    cbbEstado.ItemIndex := 1;
    FiltroCambiado(nil);
    dmmGarantias.unqryTablaG.Locate(CAMPO_ID, AId, []);
  end;
  // Las líneas y liquidaciones no se releen solas al volver al mismo
  // expediente: sin esto, inicio y fin de la línea seguían vacíos.
  dmmGarantias.Reparaciones.RefrescarLineas;
  dmmGarantias.Reparaciones.RefrescarLiquidaciones;
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
begin
  MostrarDocumentoReparacion(Ord(drRecepcion));
end;

procedure TfrmMtoGarantiasReclamaciones.MostrarDocumentoReparacion(
  ATipo: Integer; AMovimiento: Int64);
begin
  if PuedeImprimir and HayReclamacion then
  begin
    if ActualizarRegistroEnEdicion(dmmGarantias.unqryTablaG) then
      btnGrabarClick(Self);
    if dmmGarantias.unqryTablaG.State = dsBrowse then
      TfrmPrintReparacion.Ejecutar(Self,
        dmmGarantias.DatosImpreso(TDocumentoReparacion(ATipo), AMovimiento),
        TDocumentoReparacion(ATipo));
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.DocumentoReparacionClick(
  Sender: TObject);
begin
  MostrarDocumentoReparacion(TComponent(Sender).Tag);
end;

procedure TfrmMtoGarantiasReclamaciones.BotonDocumento(
  AParent: TWinControl; const ATexto: string; ATipo, AX, AY: Integer);
var
  oBoton: TcxButton;
begin
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := AParent;
  oBoton.Caption := ATexto;
  oBoton.Tag := ATipo;
  oBoton.SetBounds(EscalarDpi(AX), EscalarDpi(AY), EscalarDpi(180),
    EscalarDpi(30));
  oBoton.OnClick := DocumentoReparacionClick;
end;

procedure TfrmMtoGarantiasReclamaciones.btnExcelClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxGrdPrincipal,
      Format(SNombreArchivoGarantias,
        [FormatDateTime('yyyymmdd', Date)]), False);
end;

// ---------------------------------------------------------------------------
// Reparaciones (30/10/2026)
// ---------------------------------------------------------------------------

procedure TfrmMtoGarantiasReclamaciones.CrearFiltroModalidad;
begin
  CrearEtiqueta(SCaptionFiltroModalidad, 840, 16);
  cbbModalidad := TcxComboBox.Create(Self);
  cbbModalidad.Parent := pnlFiltros;
  cbbModalidad.Left := EscalarDpi(940);
  cbbModalidad.Top := EscalarDpi(12);
  cbbModalidad.Width := EscalarDpi(170);
  cbbModalidad.Properties.DropDownListStyle := lsFixedList;
  FCodigosModalidad := TArray<string>.Create('',
    MODALIDAD_REPARACION_GARANTIA, MODALIDAD_REPARACION_PAGO,
    MODALIDAD_REPARACION_CORTESIA);
  cbbModalidad.Properties.Items.Add(SCaptionModalidadesTodas);
  cbbModalidad.Properties.Items.Add(SModalidadGarantia);
  cbbModalidad.Properties.Items.Add(SModalidadPago);
  cbbModalidad.Properties.Items.Add(SModalidadCortesia);
  cbbModalidad.ItemIndex := 0;
  cbbModalidad.Properties.OnChange := FiltroCambiado;
end;

function TfrmMtoGarantiasReclamaciones.ModalidadFiltro: string;
begin
  Result := '';
  if Assigned(cbbModalidad) and (cbbModalidad.ItemIndex > 0) then
    Result := FCodigosModalidad[cbbModalidad.ItemIndex];
end;

procedure TfrmMtoGarantiasReclamaciones.CrearBotonesReparacion;
begin
  btnNuevaReparacion := CrearBoton(SCaptionNuevaReparacion, 12, 96, 170,
    btnNuevaReparacionClick);
  btnEntregarReparacion := CrearBoton(SCaptionEntregarReparacion, 190, 96,
    150, btnEntregarReparacionClick);
  btnAnularReparacion := CrearBoton(SCaptionAnularReparacion, 348, 96, 150,
    btnAnularReparacionClick);
end;

// Datos de la reparación; sus líneas y el presupuesto van en la pestaña
// Trabajos, que tiene la altura de la pantalla.
procedure TfrmMtoGarantiasReclamaciones.CrearFaseReparacion;
var
  oBoton: TcxButton;
begin
  tsReparacion := CrearPestana(SCaptionFaseReparacion);
  txtModalidadFicha := CrearTextoLibre(tsReparacion, SRotuloModalidad, 0);
  CrearTexto(tsReparacion, SColTipoCategoria, 'CATEGORIA_GAR', 1, 0, True);
  CrearTexto(tsReparacion, SRotuloDescripcionObjeto,
    'DESCRIPCION_OBJETO_GAR', 0, 1, False);
  CrearTexto(tsReparacion, SRotuloReferenciaObjeto, 'REFERENCIA_OBJETO_GAR',
    1, 1, False);
  CrearTexto(tsReparacion, SRotuloDetallesReparacion, 'DETALLES_GAR', 0, 2,
    False);
  CrearFecha(tsReparacion, SRotuloEntregaAproximada, 'FECHA_PREVISTA_GAR',
    1, 2);
  CrearTexto(tsReparacion, SRotuloEstadoPresupuesto,
    'ESTADO_PRESUPUESTO_GAR', 0, 3, True);
  CrearImporte(tsReparacion, SRotuloImportePresupuesto,
    'TOTAL_PRESUPUESTO_GAR', 1, 3);
  CrearImporte(tsReparacion, SColImporteCliente, 'TOTAL_CLIENTE_REP', 0, 4);
  CrearImporte(tsReparacion, SColImporteCoste, 'TOTAL_COSTE_REP', 1, 4);
  CrearTexto(tsReparacion, SRotuloSerieCobroReparacion, 'SERIE_COBRO_GAR',
    0, 5, False);
  CrearTexto(tsReparacion, SRotuloNumeroCobroReparacion, 'NUMERO_COBRO_GAR',
    1, 5, False);
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := tsReparacion;
  oBoton.Caption := SMedidasCita;
  oBoton.SetBounds(EscalarDpi(12),EscalarDpi(230),EscalarDpi(220),
    EscalarDpi(32));
  oBoton.OnClick := MedidasInstalacionClick;
end;

procedure TfrmMtoGarantiasReclamaciones.MedidasInstalacionClick(
  Sender: TObject);
begin
  if PuedeAccionMto(apmModificar) and ReclamacionAbierta then
  begin
    if ActualizarRegistroEnEdicion(dmmGarantias.unqryTablaG) then
      btnGrabarClick(Sender);
    if dmmGarantias.unqryTablaG.State=dsBrowse then
    begin
      TfrmModalTrabajoCortina.EditarOrden(Self,
        dmmGarantias.unqryTablaG.Connection,IdActual,
        dmmGarantias.IdentidadSesion.Usuario);
      Refrescar(IdActual);
    end;
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.OrganizarSubconsultas(
  Sender: TObject);
var
  oDestino: TcxPageControl;
  oPestana: TcxTabSheet;
  aPestanas: TArray<TcxTabSheet>;
begin
  if Assigned(FCambioPaginaAnterior) then
    FCambioPaginaAnterior(Sender);
  if pcPantalla.ActivePage = tsFicha then
    oDestino := pcFases
  else
    oDestino := pcSubconsultas;
  aPestanas := [tsTrabajos, tsFotosReparacion,
    tsMovimientos, tsFasesActuales];
  for oPestana in aPestanas do
    if oPestana.PageControl <> oDestino then
      oPestana.PageControl := oDestino;
  NumerarPestanasAtajo(pcFases);
  NumerarPestanasAtajo(pcSubconsultas);
end;

procedure TfrmMtoGarantiasReclamaciones.CrearPestanasReparacion;
begin
  pcSubconsultas := TcxPageControl.Create(Self);
  pcSubconsultas.Name := 'pcSubconsultasOrden';
  pcSubconsultas.Parent := tsLista;
  pcSubconsultas.Align := alBottom;
  pcSubconsultas.Height := EscalarDpi(240);
  FSeparadorSubconsultas := TSplitter.Create(Self);
  FSeparadorSubconsultas.Name := 'separadorSubconsultasOrden';
  FSeparadorSubconsultas.Parent := tsLista;
  FSeparadorSubconsultas.Align := alBottom;
  FSeparadorSubconsultas.Height := EscalarDpi(6);
  FSeparadorSubconsultas.Top := pcSubconsultas.Top -
    FSeparadorSubconsultas.Height;
  FSeparadorSubconsultas.MinSize := EscalarDpi(80);
  tsFasesActuales := TcxTabSheet.Create(Self);
  tsFasesActuales.PageControl := pcSubconsultas;
  tsFasesActuales.Caption := SFasePestana;
  tsMovimientos := TcxTabSheet.Create(Self);
  tsMovimientos.PageControl := pcSubconsultas;
  tsMovimientos.Caption := SMovimientoHistorial;
  tsFotosReparacion := TcxTabSheet.Create(Self);
  tsFotosReparacion.PageControl := pcSubconsultas;
  tsFotosReparacion.Caption := SFotosReparacion;
  tsCircuito := TcxTabSheet.Create(Self);
  tsCircuito.PageControl := pcPantalla;
  tsCircuito.Caption := SCircuitoPestana;
  tsTrabajos := TcxTabSheet.Create(Self);
  tsTrabajos.PageControl := pcSubconsultas;
  tsTrabajos.Caption := SCaptionPestanaTrabajos;
  lblResumenTrabajos := TcxLabel.Create(Self);
  lblResumenTrabajos.Parent := tsTrabajos;
  lblResumenTrabajos.Align := alTop;
  lblResumenTrabajos.Transparent := True;
  lblResumenTrabajos.Style.Font.Style := [fsBold];
  lblResumenTrabajos.Properties.Alignment.Vert := taVCenter;
  lblResumenTrabajos.Properties.WordWrap := True;
  lblResumenTrabajos.Height := EscalarDpi(52);
  tsConfiguracionReparaciones := TcxTabSheet.Create(Self);
  tsConfiguracionReparaciones.PageControl := pcPantalla;
  tsConfiguracionReparaciones.Caption := SCaptionPestanaTiposExternos;
  FCambioPaginaAnterior := pcPantalla.OnChange;
  pcPantalla.OnChange := OrganizarSubconsultas;
  OrganizarSubconsultas(pcPantalla);
end;

// appReparaciones muestra lo de reparaciones; appGarantias, el alta y la
// sustitución por número de serie.
procedure TfrmMtoGarantiasReclamaciones.LeerInterruptores;
begin
  FEsReparaciones := ParametrosApp.GetBool(PARAMETRO_REPARACIONES, False);
  if Assigned(FFechaEntrega) then
    FFechaEntrega.Properties.ReadOnly := FEsReparaciones;
  FEsSeries := TActivacionTrazabilidad.Leer(ParametrosApp).Garantias;
  btnNueva.Visible := FEsSeries;
  btnSustituir.Visible := FEsSeries;
  btnNuevaReparacion.Visible := FEsReparaciones;
  btnEntregarReparacion.Visible := FEsReparaciones;
  btnAnularReparacion.Visible := FEsReparaciones;
  tsReparacion.TabVisible := FEsReparaciones;
  tsTrabajos.TabVisible := FEsReparaciones;
  tsCircuito.TabVisible := FEsReparaciones;
  tsAlbaranes.TabVisible := FEsReparaciones;
  tsConfiguracionReparaciones.TabVisible := FEsReparaciones;
  if FEsReparaciones then
    Caption := STituloReparacionesGarantias;
  NumerarPestanasAtajo(pcFases);
  NumerarPestanasAtajo(pcSubconsultas);
end;

function TfrmMtoGarantiasReclamaciones.Enlaces: TEnlacesReparaciones;
begin
  Result.PuedeModificar :=
    function: Boolean
    begin
      Result := PuedeAccionMto(apmModificar);
    end;
  Result.GuardarOrden :=
    procedure
    begin
      if dmmGarantias.unqryTablaG.State in dsEditModes then
        btnGrabarClick(nil);
    end;
  Result.AbrirAlbaran :=
    procedure(AProveedor: Boolean; ASerie, ANumero: string)
    var
      sDestino: string;
    begin
      sDestino := 'Albaranes';
      if AProveedor then
        sDestino := 'AlbaranesCompra';
      ShowMto(Application.MainForm, sDestino, ASerie + ',' + ANumero);
    end;
  Result.ReparacionActual :=
    function: Int64
    begin
      Result := 0;
      if Assigned(dmmGarantias) and dmmGarantias.unqryTablaG.Active and
         not dmmGarantias.unqryTablaG.IsEmpty then
        Result := IdActual;
    end;
  Result.AlmacenActual :=
    function: string
    begin
      Result := dmmGarantias.UbicacionSesion.Almacen;
      if dmmGarantias.unqryTablaG.Active and
         not dmmGarantias.unqryTablaG.IsEmpty then
        Result := dmmGarantias.unqryTablaG.FieldByName(
          'CODIGO_ALM_GAR').AsString;
    end;
  Result.EmpresaActual :=
    function: string
    begin
      Result := dmmGarantias.UbicacionSesion.Empresa;
    end;
  Result.Etiqueta :=
    procedure(AFabricante: Boolean; AMovimiento: Int64)
    begin
      if AFabricante then
        MostrarDocumentoReparacion(Ord(drFabricante), AMovimiento)
      else
        MostrarDocumentoReparacion(Ord(drCliente), AMovimiento);
    end;
  Result.Entregar :=
    procedure
    begin
      btnEntregarReparacionClick(nil);
    end;
  Result.AvisarFase :=
    procedure(AAviso: TAvisoFaseReparacion)
    begin
      AvisarFase(AAviso);
    end;
  Result.TarifaActual :=
    function: string
    begin
      Result := 'PVP';
      if Assigned(ParametrosCaja) then
        Result := ParametrosCaja.TarifaDefecto;
    end;
  Result.Busqueda := BusquedaVisual;
  Result.Usuario := dmmGarantias.IdentidadSesion.Usuario;
  Result.Refrescar :=
    procedure(AId: Int64)
    begin
      if AId = 0 then
        AId := Enlaces.ReparacionActual();
      Refrescar(AId);
    end;
  Result.Imprimir :=
    procedure(AHoja: THojaReparaciones)
    begin
      ImprimirHoja(AHoja);
    end;
end;

procedure TfrmMtoGarantiasReclamaciones.CrearPanelesReparacion;
begin
  FPanelFases := TPanelFasesReparacion.CreatePanel(Self, tsFasesActuales,
    dmmGarantias.Reparaciones, Enlaces);
  TPanelMovimientosReparacion.CreatePanel(Self, tsMovimientos,
    dmmGarantias.Reparaciones, Enlaces);
  FPanelFotos := TPanelFotosReparacion.CreatePanel(Self, tsFotosReparacion,
    dmmGarantias.Reparaciones, Enlaces);
  FPanelFotos.Configurar(ParametrosApp);
  FPanelFotos.MostrarReparacion(Enlaces.ReparacionActual());
  if FEsReparaciones then
  begin
    TPanelCircuitoOrden.CreatePanel(Self, tsCircuito,
      dmmGarantias.Reparaciones, Enlaces);
    TPanelLineasReparacion.CreatePanel(Self, tsTrabajos,
      dmmGarantias.Reparaciones, Enlaces);
    TPanelAlbaranesOrden.CreatePara(Self, tsAlbaranesCliente,
      dmmGarantias.Reparaciones, Enlaces, False);
    TPanelAlbaranesOrden.CreatePara(Self, tsAlbaranesProveedor,
      dmmGarantias.Reparaciones, Enlaces, True);
    FPanelConfiguracion :=
      TPanelConfiguracionReparaciones.CreatePanel(Self,
      tsConfiguracionReparaciones, dmmGarantias.Reparaciones, Enlaces);
  end;
end;

procedure TfrmMtoGarantiasReclamaciones.PrepararGuardado;
begin
  inherited;
  if Assigned(FPanelConfiguracion) then
    FPanelConfiguracion.ConfirmarEdicion;
end;

procedure TfrmMtoGarantiasReclamaciones.ModalidadGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoModalidadReparacion(AText);
end;

procedure TfrmMtoGarantiasReclamaciones.FaseReparacionGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoFaseReparacion(AText);
end;

// Ejecuta una acción del repositorio con la ficha grabada; un error de
// situación o de validación se avisa y la lista se refresca.
procedure TfrmMtoGarantiasReclamaciones.EjecutarReparacion(AAccion: TProc);
var
  iId: Int64;
begin
  iId := IdActual;
  if dmmGarantias.unqryTablaG.State in dsEditModes then
    dmmGarantias.unqryTablaG.Post;
  try
    AAccion();
  except
    on E: EFaseReparacion do
      ShowMessage_fza(E.Message);
    on E: EArgumentException do
      ShowMessage_fza(E.Message);
  end;
  Refrescar(iId);
end;

procedure TfrmMtoGarantiasReclamaciones.btnNuevaReparacionClick(
  Sender: TObject);
var
  Base: TReparacionNueva;
  iId: Int64;
begin
  Base := Default(TReparacionNueva);
  Base.Almacen := dmmGarantias.UbicacionSesion.Almacen;
  Base.Fecha := Date;
  Base.Usuario := dmmGarantias.IdentidadSesion.Usuario;
  iId := TfrmModalReparacion.Ejecutar(Self,
    dmmGarantias.Reparaciones.Catalogo,
    dmmGarantias.Reparaciones.Reparaciones, Base);
  if iId > 0 then
  begin
    Refrescar(iId);
    pcPantalla.ActivePage := tsFicha;
    pcFases.ActivePage := tsReparacion;
    if MessageDlg_fza(RotuloReferenciaGarantia(dmmGarantias.DatosResguardo,
      SPreguntaResguardoReparacion),
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      MostrarResguardo;
  end;
end;

// El ticket se teclea como SERIE/NÚMERO; vacío = sin cobrar.
function TfrmMtoGarantiasReclamaciones.PedirTicketCobro(
  out ASerie, ANumero: string): Boolean;
var
  sTexto: string;
  iBarra: Integer;
begin
  sTexto := '';
  ASerie := '';
  ANumero := '';
  Result := InputQuery_fza(STituloEntregarReparacion,
    Format(SPreguntaTicketCobroReparacion,
      [FormatFloat('#,##0.00', dmmGarantias.unqryTablaG.FieldByName(
        'TOTAL_CLIENTE_REP').AsCurrency)]), sTexto);
  sTexto := Trim(sTexto);
  iBarra := LastDelimiter('/', sTexto);
  if Result and (iBarra > 1) then
  begin
    ASerie := Trim(Copy(sTexto, 1, iBarra - 1));
    ANumero := Trim(Copy(sTexto, iBarra + 1, MaxInt));
  end;
  if Result and (ANumero = '') then
    Result := MessageDlg_fza(SPreguntaEntregarSinCobro, mtWarning,
      [mbYes, mbNo], 0, mbNo) = mrYes;
end;

function TfrmMtoGarantiasReclamaciones.ConfirmarCobroEntrega(
  out ASerie, ANumero: string): Boolean;
begin
  ASerie := '';
  ANumero := '';
  Result := True;
  if dmmGarantias.Reparaciones.Circuito.Gestionada(IdActual) then
  begin
    if dmmGarantias.Reparaciones.Circuito.Cierre.SaldoCliente(IdActual)>0 then
      Result := MessageDlg_fza(SPreguntaEntregarSinCobro, mtWarning,
        [mbYes,mbNo],0,mbNo)=mrYes;
  end
  else if FaltaCobrarReparacion(
    dmmGarantias.unqryTablaG.FieldByName('MODALIDAD_GAR').AsString,
    dmmGarantias.unqryTablaG.FieldByName('MODO_COBRO_GAR').AsString,
    dmmGarantias.unqryTablaG.FieldByName('ESCOBRADO_GAR').AsString = 'S',
    dmmGarantias.unqryTablaG.FieldByName('TOTAL_CLIENTE_REP').AsCurrency) and
    (Trim(dmmGarantias.unqryTablaG.FieldByName(
      'CODIGO_CLI_PAGADOR_GAR').AsString) = '') then
    Result := PedirTicketCobro(ASerie,ANumero);
end;

procedure TfrmMtoGarantiasReclamaciones.btnEntregarReparacionClick(
  Sender: TObject);
var
  sSerie, sNumero: string;
begin
  if HayReclamacion and ConfirmarCobroEntrega(sSerie,sNumero) then
    EjecutarReparacion(
      procedure
      begin
        dmmGarantias.Reparaciones.Reparaciones.Entregar(IdActual,Date,
          sNumero<>'',sSerie,sNumero,dmmGarantias.IdentidadSesion.Usuario);
      end);
end;

procedure TfrmMtoGarantiasReclamaciones.btnAnularReparacionClick(
  Sender: TObject);
var
  sMotivo: string;
begin
  sMotivo := '';
  if HayReclamacion and InputQuery_fza(STituloAnularReparacion,
    SPreguntaMotivoAnulacion, sMotivo) and (Trim(sMotivo) <> '') then
    EjecutarReparacion(
      procedure
      begin
        dmmGarantias.Reparaciones.Reparaciones.Anular(IdActual, sMotivo,
          dmmGarantias.IdentidadSesion.Usuario);
      end);
end;

procedure TfrmMtoGarantiasReclamaciones.AvisarFase(
  const AAviso: TAvisoFaseReparacion);
var
  rCorreo: TCorreoFaseReparacion;
  rResguardo: TResguardoGarantia;
begin
  rResguardo := dmmGarantias.DatosResguardo;
  rCorreo := Default(TCorreoFaseReparacion);
  rCorreo.Aviso := AAviso;
  rCorreo.Aviso.Referencia := rResguardo.Referencia;
  rCorreo.Email := AAviso.Email;
  rCorreo.Asunto := AsuntoAvisoFase(rCorreo.Aviso);
  rCorreo.Texto := TextoAvisoFase(rCorreo.Aviso);
  rCorreo.Empresa := rResguardo.Empresa;
  rCorreo.EmailRespuesta := rResguardo.EmailEmpresa;
  rCorreo.Usuario := dmmGarantias.IdentidadSesion.Usuario;
  TfrmModalAvisoReparacion.Ejecutar(Self,
    dmmGarantias.Reparaciones.Fases, rCorreo);
  dmmGarantias.Reparaciones.Fases.Refrescar;
end;

procedure TfrmMtoGarantiasReclamaciones.ImprimirHoja(
  const AHoja: THojaReparaciones);
var
  oInforme: TfrxReport;
  Formato: TFormatoHojaReparacion;
  Eleccion: Integer;
begin
  Eleccion := MessageDlgTextos_fza(
    Format(SPreguntaFormatoHojaReparacion, [AHoja.Titulo]),
    mtConfirmation, [mbYes, mbNo, mbCancel], ['A4', 'Ticket', ''], mbNo);
  Formato := fhrTicket;
  if Eleccion = mrYes then
    Formato := fhrA4;
  if Eleccion <> mrCancel then
  begin
    oInforme := TfrxReport.Create(nil);
    try
      CrearInformeHojaReparaciones(oInforme, AHoja, Formato);
      if Formato = fhrTicket then
        ImprimirHojaReparacionesTicket(oInforme, AHoja.Titulo, PreviewTicket,
          ParametrosCaja.ImpresoraCaja, GetUserFolderTickets + 'Hoja_GAR_' +
          FormatDateTime('yyyymmdd_hhnnss_zzz', Now) + '.pdf')
      else
        oInforme.ShowReport;
    finally
      FreeAndNil(oInforme);
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoGarantiasReclamaciones);
  ForceReferenceToClass(TfrmMtoGarantiasReclamaciones);
end.
