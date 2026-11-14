{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCargasTransito                                           }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Almacén - Cargas en tránsito: consulta de las cargas que viajan en una    }
{    furgoneta o agencia (pendientes, recibidas, devueltas, perdidas), con su  }
{    antigüedad y filtros por tránsito, origen, destino y estado, y debajo     }
{    los apuntes de pérdida y deterioro en transporte, exportables a Excel y   }
{    con la reclamación (referencia, estado e importes) anotada de una vez en  }
{    varios apuntes o en toda la carga (FZ-ISSUE-728). Recibir y desbloquear   }
{    se hace desde la caja (FZ-ISSUE-256).                                     }
{******************************************************************************}
unit inMtoCargasTransito;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxButtons, cxCalendar, cxCurrencyEdit,
  cxSplitter, cxPC, dxSkinsCore, dxSkinscxPCPainter,
  dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataCargasTransito,
  inLibTraspasoOpePersistenciaIntf, inLibPermisosIntf, inMtoGen;

type
  TfrmMtoCargasTransito = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados: Boolean;
    FVerCoste: Boolean;
    FCodigosTransito: TArray<string>;
    FCodigosOrigen: TArray<string>;
    FCodigosDestino: TArray<string>;
    FCodigosEstado: TArray<string>;
    dmmCargas: TdmCargasTransito;
    pnlFiltros: TPanel;
    cbbTransito: TcxComboBox;
    cbbOrigen: TcxComboBox;
    cbbDestino: TcxComboBox;
    cbbEstado: TcxComboBox;
    pnlIncidencias: TPanel;
    pnlBotonesIncidencias: TPanel;
    splIncidencias: TcxSplitter;
    edtReferencia: TcxTextEdit;
    grdIncidencias: TcxGrid;
    tvIncidencias: TcxGridDBTableView;
    function EscalarDpi(AValor: Integer): Integer;
    procedure CrearControlesDinamicos;
    procedure CrearFiltros;
    procedure CrearPanelIncidencias;
    function CrearEtiqueta(AParent: TWinControl; const ATexto: string;
      AIzq, ATop: Integer): TcxLabel;
    function CrearCombo(AIzq, ATop, AAncho: Integer): TcxComboBox;
    function CrearBoton(AParent: TWinControl; const ATexto: string;
      AIzq, ATop, AAncho: Integer; AAlPulsar: TNotifyEvent): TcxButton;
    procedure CargarCombos;
    procedure CargarComboAlmacenes(ACombo: TcxComboBox;
      var ACodigos: TArray<string>;
      const AAlmacenes: TAlmacenesDestinoTraspaso);
    procedure CargarComboEstados;
    function CodigoCombo(ACombo: TcxComboBox;
      const ACodigos: TArray<string>): string;
    function CrearColumna(AVista: TcxGridDBTableView;
      const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
    procedure CrearColumnas;
    procedure CrearColumnasIncidencias;
    function CrearColumnaImporte(const ACampo, ATitulo: string;
      AVisible: Boolean): TcxGridDBColumn;
    function IncidenciasSeleccionadas: TArray<Int64>;
    function IncidenciasAReclamar: TArray<Int64>;
    function PedirReclamacion(ANumIncidencias: Integer;
      var AReclamacion: TReclamacionTransito): Boolean;
    procedure FiltroCambiado(Sender: TObject);
    procedure ReferenciaCambiada(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnHojaRutaClick(Sender: TObject);
    procedure btnExcelIncidenciasClick(Sender: TObject);
    procedure btnReclamacionClick(Sender: TObject);
  protected
    procedure DoCreate; override;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

uses
  System.Math, System.StrUtils,
  inLibMensajesVcl,
  inLibMsgCaja, inLibMsgComun,
  inLibDevExp, inMtoModalImpHojaRutaTransito;

{$R *.dfm}

const
  CAMPO_ID_CARGA = 'ID_TRTRA';
  CAMPO_ID_INCIDENCIA = 'ID_TRTINC';
  CAMPO_CARGA_INCIDENCIA = 'ID_TRTRA_TRTINC';
  FORMATO_IMPORTE = ',0.00';
  FORMATO_UNIDADES = '#,##0.###';
  FORMATO_FECHA = 'dd/mm/yyyy hh:nn';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoCargasTransito.FormCreate(Sender: TObject);
begin
  CrearControlesDinamicos;
  inherited;
end;

// El título se fija tras la traducción del formulario base, que si no lo
// deja con el de su ancestro.
procedure TfrmMtoCargasTransito.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloCargasTransito;
end;

function TfrmMtoCargasTransito.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoCargasTransito.CrearEtiqueta(AParent: TWinControl;
  const ATexto: string; AIzq, ATop: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := AParent;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Caption := ATexto;
  Result.Transparent := True;
end;

function TfrmMtoCargasTransito.CrearCombo(
  AIzq, ATop, AAncho: Integer): TcxComboBox;
begin
  Result := TcxComboBox.Create(Self);
  Result.Parent := pnlFiltros;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Width := EscalarDpi(AAncho);
  Result.Properties.DropDownListStyle := lsFixedList;
  Result.Properties.DropDownRows := 16;
  Result.Properties.OnChange := FiltroCambiado;
end;

function TfrmMtoCargasTransito.CrearBoton(AParent: TWinControl;
  const ATexto: string; AIzq, ATop, AAncho: Integer;
  AAlPulsar: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Self);
  Result.Parent := AParent;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Width := EscalarDpi(AAncho);
  Result.Height := EscalarDpi(34);
  Result.Caption := ATexto;
  Result.OnClick := AAlPulsar;
end;

procedure TfrmMtoCargasTransito.CrearControlesDinamicos;
begin
  if not FControlesCreados then
  begin
    CrearFiltros;
    CrearPanelIncidencias;
    FControlesCreados := True;
  end;
end;

procedure TfrmMtoCargasTransito.CrearFiltros;
begin
  pnlFiltros := TPanel.Create(Self);
  pnlFiltros.Parent := tsLista;
  pnlFiltros.Align := alTop;
  pnlFiltros.Height := EscalarDpi(84);
  pnlFiltros.BevelOuter := bvNone;
  CrearEtiqueta(pnlFiltros, SCaptionFiltroTransito, 12, 16);
  cbbTransito := CrearCombo(90, 12, 260);
  CrearEtiqueta(pnlFiltros, SCaptionFiltroOrigen, 370, 16);
  cbbOrigen := CrearCombo(440, 12, 260);
  CrearEtiqueta(pnlFiltros, SCaptionFiltroDestino, 720, 16);
  cbbDestino := CrearCombo(790, 12, 260);
  CrearEtiqueta(pnlFiltros, SCaptionFiltroEstadoCarga, 1070, 16);
  cbbEstado := CrearCombo(1140, 12, 220);
  CrearBoton(pnlFiltros, SCaptionRefrescarCargasTransito, 1380,
    10, 110, btnRefrescarClick);
  CrearBoton(pnlFiltros, SCaptionHojaRutaTransito, 12,
    44, 170, btnHojaRutaClick);
  CrearEtiqueta(pnlFiltros, STextoAyudaCargasTransito, 200, 50);
end;

// Debajo de la rejilla de cargas, con su separador: los apuntes de
// pérdida y deterioro de las cargas filtradas.
procedure TfrmMtoCargasTransito.CrearPanelIncidencias;
begin
  pnlIncidencias := TPanel.Create(Self);
  pnlIncidencias.Parent := tsLista;
  pnlIncidencias.Align := alBottom;
  pnlIncidencias.Height := EscalarDpi(260);
  pnlIncidencias.BevelOuter := bvNone;
  splIncidencias := TcxSplitter.Create(Self);
  splIncidencias.Parent := tsLista;
  splIncidencias.AlignSplitter := salBottom;
  splIncidencias.Control := pnlIncidencias;
  pnlBotonesIncidencias := TPanel.Create(Self);
  pnlBotonesIncidencias.Parent := pnlIncidencias;
  pnlBotonesIncidencias.Align := alTop;
  pnlBotonesIncidencias.Height := EscalarDpi(48);
  pnlBotonesIncidencias.BevelOuter := bvNone;
  CrearEtiqueta(pnlBotonesIncidencias, SCaptionIncidenciasTransporte,
    12, 12);
  CrearBoton(pnlBotonesIncidencias, SCaptionExcelIncidenciasTransito,
    440, 6, 110, btnExcelIncidenciasClick);
  CrearBoton(pnlBotonesIncidencias,
    SCaptionReclamacionIncidenciaTransito, 560, 6, 150,
    btnReclamacionClick);
  // Por referencia, para ver el total de una reclamación (FZ-ISSUE-728).
  CrearEtiqueta(pnlBotonesIncidencias, SCaptionFiltroReferenciaReclamacion,
    730, 12);
  edtReferencia := TcxTextEdit.Create(Self);
  edtReferencia.Parent := pnlBotonesIncidencias;
  edtReferencia.Left := EscalarDpi(820);
  edtReferencia.Top := EscalarDpi(8);
  edtReferencia.Width := EscalarDpi(200);
  edtReferencia.Properties.OnEditValueChanged := ReferenciaCambiada;
  grdIncidencias := TcxGrid.Create(Self);
  grdIncidencias.Parent := pnlIncidencias;
  grdIncidencias.Align := alClient;
  tvIncidencias := grdIncidencias.CreateView(TcxGridDBTableView)
    as TcxGridDBTableView;
  grdIncidencias.Levels.Add.GridView := tvIncidencias;
  tvIncidencias.OptionsData.Editing := False;
  tvIncidencias.OptionsData.Inserting := False;
  tvIncidencias.OptionsData.Deleting := False;
  tvIncidencias.OptionsSelection.CellSelect := False;
  tvIncidencias.OptionsSelection.MultiSelect := True;
  tvIncidencias.OptionsView.GroupByBox := False;
  tvIncidencias.OptionsView.ColumnAutoWidth := False;
  tvIncidencias.OptionsView.Footer := True;
end;

function TfrmMtoCargasTransito.CrearColumna(AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmMtoCargasTransito.CrearColumnas;
var
  oColumna: TcxGridDBColumn;
begin
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(cxGrdDBTabPrin, CAMPO_ID_CARGA,
      SCaptionColNumeroCargaTransito, 70);
    oColumna := CrearColumna(cxGrdDBTabPrin, 'FECHA_CARGA_TRTRA',
      SCaptionColFechaCargaTransito, 130);
    oColumna.PropertiesClass := TcxDateEditProperties;
    TcxDateEditProperties(oColumna.Properties).DisplayFormat :=
      FORMATO_FECHA;
    CrearColumna(cxGrdDBTabPrin, 'DIAS_TRTRA',
      SCaptionColDiasCargaTransito, 60);
    CrearColumna(cxGrdDBTabPrin, 'ESTADO_TRTRA',
      SCaptionColEstadoCargaTransito, 160);
    CrearColumna(cxGrdDBTabPrin, 'ORIGEN',
      SCaptionColOrigenCargaTransito, 200);
    CrearColumna(cxGrdDBTabPrin, 'TRANSITO',
      SCaptionColTransitoCargaTransito, 200);
    CrearColumna(cxGrdDBTabPrin, 'DESTINO',
      SCaptionColDestinoCargaTransito, 200);
    CrearColumna(cxGrdDBTabPrin, 'CARGA',
      SCaptionColCargaIncidenciaTransito, 130);
    oColumna := CrearColumna(cxGrdDBTabPrin, 'UNIDADES',
      SCaptionColUnidadesCargaTransito, 80);
    oColumna.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(oColumna.Properties).DisplayFormat :=
      FORMATO_UNIDADES;
    CrearColumna(cxGrdDBTabPrin, 'INCIDENCIAS',
      SCaptionColIncidenciasCargaTransito, 90);
    CrearColumna(cxGrdDBTabPrin, 'NUMERO_OPERACION_CARGA_TRTRA',
      SCaptionColOperacionCargaTransito, 100);
    CrearColumna(cxGrdDBTabPrin, 'CIERRE',
      SCaptionColCierreCargaTransito, 150);
    oColumna := CrearColumna(cxGrdDBTabPrin, 'FECHA_RECEPCION_TRTRA',
      SCaptionColFechaCierreCargaTransito, 130);
    oColumna.PropertiesClass := TcxDateEditProperties;
    TcxDateEditProperties(oColumna.Properties).DisplayFormat :=
      FORMATO_FECHA;
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_CAJA_RECEPCION_TRTRA',
      SCaptionColCajaCierreCargaTransito, 70);
    CrearColumna(cxGrdDBTabPrin, 'TIPO_DESBLOQUEO_TRTRA',
      SCaptionColDesbloqueoCargaTransito, 130);
    CrearColumna(cxGrdDBTabPrin, 'MOTIVO_DESBLOQUEO_TRTRA',
      SCaptionColMotivoDesbloqueoCargaTransito, 240);
    CrearColumna(cxGrdDBTabPrin, 'USUARIO_DESBLOQUEO_TRTRA',
      SCaptionColUsuarioDesbloqueoCargaTransito, 120);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_ALM_DESTINO_INICIAL_TRTRA',
      SCaptionColDestinoInicialCargaTransito, 100);
    CrearColumna(cxGrdDBTabPrin, 'CODIGO_EMP_TRTRA',
      SCaptionColEmpresaCargaTransito, 80);
    CrearColumna(cxGrdDBTabPrin, 'USUARIO_ALTA',
      SCaptionColUsuarioIncidenciaTransito, 120);
  end;
end;

// Columna de importe con su total al pie.
function TfrmMtoCargasTransito.CrearColumnaImporte(
  const ACampo, ATitulo: string; AVisible: Boolean): TcxGridDBColumn;
var
  oSuma: TcxGridDBTableSummaryItem;
begin
  Result := CrearColumna(tvIncidencias, ACampo, ATitulo, 90);
  Result.PropertiesClass := TcxCurrencyEditProperties;
  Result.Visible := AVisible;
  oSuma := tvIncidencias.DataController.Summary.FooterSummaryItems.Add
    as TcxGridDBTableSummaryItem;
  oSuma.Column := Result;
  oSuma.Kind := skSum;
  oSuma.Format := FORMATO_IMPORTE;
end;

// El coste y el importe solo los ve quien tiene permiso para ver costes.
procedure TfrmMtoCargasTransito.CrearColumnasIncidencias;
var
  oColumna: TcxGridDBColumn;
begin
  if tvIncidencias.ColumnCount = 0 then
  begin
    // Ocultas: identifican lo seleccionado para la reclamación.
    CrearColumna(tvIncidencias, CAMPO_ID_INCIDENCIA, CAMPO_ID_INCIDENCIA,
      60).Visible := False;
    CrearColumna(tvIncidencias, CAMPO_CARGA_INCIDENCIA,
      CAMPO_CARGA_INCIDENCIA, 60).Visible := False;
    oColumna := CrearColumna(tvIncidencias, 'FECHA_TRTINC',
      SCaptionColFechaIncidenciaTransito, 130);
    oColumna.PropertiesClass := TcxDateEditProperties;
    TcxDateEditProperties(oColumna.Properties).DisplayFormat :=
      FORMATO_FECHA;
    CrearColumna(tvIncidencias, 'TIPO_TRTINC',
      SCaptionColTipoIncidenciaTransito, 100);
    CrearColumna(tvIncidencias, 'CARGA',
      SCaptionColCargaIncidenciaTransito, 110);
    CrearColumna(tvIncidencias, 'CODIGO_ALM_ORIGEN_TRTRA',
      SCaptionColOrigenCargaTransito, 80);
    CrearColumna(tvIncidencias, 'CODIGO_ALM_TRANSITO_TRTRA',
      SCaptionColTransitoCargaTransito, 80);
    CrearColumna(tvIncidencias, 'CODIGO_ALM_DESTINO_TRTRA',
      SCaptionColDestinoCargaTransito, 80);
    CrearColumna(tvIncidencias, 'CODIGO_UNIDAD_TRTINC',
      SCaptionColSkuRepartoTransito, 160);
    CrearColumna(tvIncidencias, 'DESCRIPCION_ARTICULO_TRTINC',
      SCaptionColDescripcionRepartoTransito, 220);
    oColumna := CrearColumna(tvIncidencias, 'CANTIDAD_TRTINC',
      SCaptionColUnidadesCargaTransito, 80);
    oColumna.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(oColumna.Properties).DisplayFormat :=
      FORMATO_UNIDADES;
    oColumna := CrearColumna(tvIncidencias, 'PRECIO_COSTE_TRTINC',
      SCaptionColCosteIncidenciaTransito, 90);
    oColumna.PropertiesClass := TcxCurrencyEditProperties;
    oColumna.Visible := FVerCoste;
    CrearColumnaImporte('TOTAL_COSTE_TRTINC',
      SCaptionColImporteIncidenciaTransito, FVerCoste);
    CrearColumna(tvIncidencias, 'CODIGO_ALM_TARAS_TRTINC',
      SCaptionColTarasIncidenciaTransito, 80);
    CrearColumna(tvIncidencias, 'MOTIVO_TRTINC',
      SCaptionColMotivoRepartoTransito, 220);
    CrearColumna(tvIncidencias, 'REFERENCIA_RECLAMACION_TRTINC',
      SCaptionReclamacionIncidenciaTransito, 140);
    CrearColumna(tvIncidencias, 'ESTADO_RECLAMACION_TRTINC',
      SCaptionColEstadoReclamacionIncidencia, 120);
    CrearColumnaImporte('IMPORTE_RECLAMADO_TRTINC',
      SCaptionColReclamadoIncidenciaTransito, FVerCoste);
    CrearColumnaImporte('IMPORTE_INDEMNIZADO_TRTINC',
      SCaptionColIndemnizadoIncidenciaTransito,
      FVerCoste and dmmCargas.ConImportes);
    CrearColumna(tvIncidencias, 'DOCUMENTO',
      SCaptionColDocumentoCargaTransito, 130);
    CrearColumna(tvIncidencias, 'USUARIO_ALTA',
      SCaptionColUsuarioIncidenciaTransito, 120);
  end;
end;

procedure TfrmMtoCargasTransito.CargarComboAlmacenes(ACombo: TcxComboBox;
  var ACodigos: TArray<string>;
  const AAlmacenes: TAlmacenesDestinoTraspaso);
var
  Almacen: TAlmacenDestinoTraspaso;
begin
  ACodigos := [''];
  ACombo.Properties.Items.Clear;
  ACombo.Properties.Items.Add(SCaptionTodosAlmacenesFiltro);
  for Almacen in AAlmacenes do
  begin
    ACodigos := ACodigos + [Almacen.Codigo];
    ACombo.Properties.Items.Add(Almacen.Codigo + ' - ' + Almacen.Nombre);
  end;
  ACombo.ItemIndex := 0;
end;

procedure TfrmMtoCargasTransito.CargarComboEstados;
const
  CODIGOS: array[0..6] of string = ('PENDIENTE', '', 'RECIBIDO',
    'RECIBIDO_INCIDENCIAS', 'DEVUELTO', 'PERDIDO', 'ANULADO');
var
  Textos: TArray<string>;
  i: Integer;
begin
  Textos := TArray<string>.Create(SCaptionEstadoCargasPendientes,
    SCaptionEstadoCargasTodas, SCaptionEstadoCargasRecibidas,
    SCaptionEstadoCargasConIncidencias, SCaptionEstadoCargasDevueltas,
    SCaptionEstadoCargasPerdidas, SCaptionEstadoCargasAnuladas);
  FCodigosEstado := nil;
  cbbEstado.Properties.Items.Clear;
  for i := Low(CODIGOS) to High(CODIGOS) do
  begin
    FCodigosEstado := FCodigosEstado + [CODIGOS[i]];
    cbbEstado.Properties.Items.Add(Textos[i]);
  end;
  cbbEstado.ItemIndex := 0;
end;

// Los desplegables se cargan sin disparar el filtro: el data module ya
// arranca con las cargas pendientes.
procedure TfrmMtoCargasTransito.CargarCombos;
var
  Almacenes: TAlmacenesDestinoTraspaso;
begin
  cbbTransito.Properties.OnChange := nil;
  cbbOrigen.Properties.OnChange := nil;
  cbbDestino.Properties.OnChange := nil;
  cbbEstado.Properties.OnChange := nil;
  try
    CargarComboAlmacenes(cbbTransito, FCodigosTransito,
      dmmCargas.ListarAlmacenes(True));
    Almacenes := dmmCargas.ListarAlmacenes(False);
    CargarComboAlmacenes(cbbOrigen, FCodigosOrigen, Almacenes);
    CargarComboAlmacenes(cbbDestino, FCodigosDestino, Almacenes);
    CargarComboEstados;
  finally
    cbbTransito.Properties.OnChange := FiltroCambiado;
    cbbOrigen.Properties.OnChange := FiltroCambiado;
    cbbDestino.Properties.OnChange := FiltroCambiado;
    cbbEstado.Properties.OnChange := FiltroCambiado;
  end;
end;

function TfrmMtoCargasTransito.CodigoCombo(ACombo: TcxComboBox;
  const ACodigos: TArray<string>): string;
begin
  Result := '';
  if (ACombo.ItemIndex >= 0) and (ACombo.ItemIndex <= High(ACodigos)) then
    Result := ACodigos[ACombo.ItemIndex];
end;

procedure TfrmMtoCargasTransito.CrearTablaPrincipal;
begin
  inherited;
  dmmCargas := tdmDataModule as TdmCargasTransito;
  FVerCoste := Assigned(Permisos) and
    Permisos.TienePermiso(PERMISO_CAJA_VER_COSTE, paDenegar);
  pkFieldName := CAMPO_ID_CARGA;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  tsFicha.TabVisible := False;
  nvNavegador.Visible := False;
  CargarCombos;
  CrearColumnas;
  tvIncidencias.DataController.DataSource := dmmCargas.dsIncidencias;
  CrearColumnasIncidencias;
end;

procedure TfrmMtoCargasTransito.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoCargasTransito.FiltroCambiado(Sender: TObject);
begin
  if Assigned(dmmCargas) then
    dmmCargas.AplicarFiltros(
      CodigoCombo(cbbTransito, FCodigosTransito),
      CodigoCombo(cbbOrigen, FCodigosOrigen),
      CodigoCombo(cbbDestino, FCodigosDestino),
      CodigoCombo(cbbEstado, FCodigosEstado));
end;

procedure TfrmMtoCargasTransito.ReferenciaCambiada(Sender: TObject);
begin
  if Assigned(dmmCargas) then
    dmmCargas.FiltrarReferencia(VarToStr(edtReferencia.EditValue));
end;

procedure TfrmMtoCargasTransito.btnRefrescarClick(Sender: TObject);
begin
  FiltroCambiado(Sender);
end;

procedure TfrmMtoCargasTransito.btnHojaRutaClick(Sender: TObject);
var
  Transito: string;
begin
  Transito := CodigoCombo(cbbTransito, FCodigosTransito);
  if Trim(Transito) = '' then
  begin
    cbbTransito.SetFocus;
    ShowMessage_fza(Self, SErrorHojaRutaSinTransito);
  end
  else
    TfrmPrintHojaRutaTransito.Ejecutar(Self, ConexionPrincipal, Transito,
      PuedeImprimir, PuedeExportar);
end;

procedure TfrmMtoCargasTransito.btnExcelIncidenciasClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, grdIncidencias,
      Format(SNombreArchivoIncidenciasTransito,
        [FormatDateTime('yyyymmdd', Date)]));
end;

function TfrmMtoCargasTransito.IncidenciasSeleccionadas: TArray<Int64>;
var
  oColumnaId: TcxGridDBColumn;
  i: Integer;
begin
  Result := nil;
  oColumnaId := tvIncidencias.GetColumnByFieldName(CAMPO_ID_INCIDENCIA);
  if Assigned(oColumnaId) then
    for i := 0 to tvIncidencias.Controller.SelectedRecordCount - 1 do
      Result := Result + [Int64(tvIncidencias.Controller.
        SelectedRecords[i].Values[oColumnaId.Index])];
end;

// Varias seleccionadas: esas. Una sola de una carga con más incidencias:
// se ofrece anotar la reclamación en toda la carga (FZ-ISSUE-728).
function TfrmMtoCargasTransito.IncidenciasAReclamar: TArray<Int64>;
var
  oApuntes: TDataSet;
  aCarga: TArray<Int64>;
begin
  Result := IncidenciasSeleccionadas;
  oApuntes := dmmCargas.dsIncidencias.DataSet;
  if Length(Result) = 0 then
    Result := [oApuntes.FieldByName(CAMPO_ID_INCIDENCIA).AsLargeInt];
  if Length(Result) = 1 then
  begin
    aCarga := dmmCargas.IncidenciasCarga(
      oApuntes.FieldByName(CAMPO_CARGA_INCIDENCIA).AsLargeInt);
    if (Length(aCarga) > 1) and (MessageBox_fza(
         Format(SPreguntaReclamacionCargaCompleta,
           [oApuntes.FieldByName('CARGA').AsString, Length(aCarga)]),
         STituloReclamacionIncidenciaTransito,
         MB_YESNO or MB_ICONQUESTION) = IDYES) then
      Result := aCarga;
  end;
end;

function TfrmMtoCargasTransito.PedirReclamacion(ANumIncidencias: Integer;
  var AReclamacion: TReclamacionTransito): Boolean;
var
  oDialogo: TForm;
  oInfo: TcxLabel;
  edtReferenciaRec: TcxTextEdit;
  cbbEstadoRec: TcxComboBox;
  edtReclamado: TcxCurrencyEdit;
  edtIndemnizado: TcxCurrencyEdit;
  oAceptar, oCancelar: TcxButton;
  bImportes: Boolean;
  iTopBotones: Integer;
begin
  bImportes := FVerCoste and dmmCargas.ConImportes;
  oDialogo := TForm.CreateNew(Self);
  try
    oDialogo.Caption := STituloReclamacionIncidenciaTransito;
    oDialogo.BorderStyle := bsDialog;
    oDialogo.Position := poOwnerFormCenter;
    oDialogo.Font.Assign(Font);
    oDialogo.ClientWidth := EscalarDpi(480);
    oInfo := CrearEtiqueta(oDialogo,
      Format(SInfoAlcanceReclamacionTransito, [ANumIncidencias]), 16, 12);
    oInfo.Properties.WordWrap := True;
    oInfo.AutoSize := False;
    oInfo.Width := EscalarDpi(448);
    oInfo.Height := EscalarDpi(44);
    CrearEtiqueta(oDialogo, SPreguntaReclamacionIncidenciaTransito, 16, 62);
    edtReferenciaRec := TcxTextEdit.Create(oDialogo);
    edtReferenciaRec.Parent := oDialogo;
    edtReferenciaRec.Left := EscalarDpi(16);
    edtReferenciaRec.Top := EscalarDpi(84);
    edtReferenciaRec.Width := EscalarDpi(448);
    edtReferenciaRec.Properties.MaxLength := 100;
    edtReferenciaRec.Text := AReclamacion.Referencia;
    CrearEtiqueta(oDialogo, SEtiquetaEstadoReclamacionTransito, 16, 120);
    cbbEstadoRec := TcxComboBox.Create(oDialogo);
    cbbEstadoRec.Parent := oDialogo;
    cbbEstadoRec.Left := EscalarDpi(16);
    cbbEstadoRec.Top := EscalarDpi(142);
    cbbEstadoRec.Width := EscalarDpi(220);
    cbbEstadoRec.Properties.DropDownListStyle := lsFixedList;
    cbbEstadoRec.Properties.Items.AddStrings([SEstadoReclamacionPendiente,
      SEstadoReclamacionEnviada, SEstadoReclamacionAceptada,
      SEstadoReclamacionCobrada, SEstadoReclamacionRechazada]);
    cbbEstadoRec.ItemIndex := Max(0, IndexStr(AReclamacion.Estado,
      ESTADOS_RECLAMACION_TRANSITO));
    CrearEtiqueta(oDialogo, SEtiquetaImporteReclamadoTransito, 16, 178)
      .Visible := bImportes;
    edtReclamado := TcxCurrencyEdit.Create(oDialogo);
    edtReclamado.Parent := oDialogo;
    edtReclamado.Left := EscalarDpi(16);
    edtReclamado.Top := EscalarDpi(200);
    edtReclamado.Width := EscalarDpi(160);
    edtReclamado.Value := AReclamacion.ImporteReclamado;
    edtReclamado.Visible := bImportes;
    CrearEtiqueta(oDialogo, SEtiquetaImporteIndemnizadoTransito, 16, 236)
      .Visible := bImportes;
    edtIndemnizado := TcxCurrencyEdit.Create(oDialogo);
    edtIndemnizado.Parent := oDialogo;
    edtIndemnizado.Left := EscalarDpi(16);
    edtIndemnizado.Top := EscalarDpi(258);
    edtIndemnizado.Width := EscalarDpi(160);
    if AReclamacion.ConIndemnizado then
      edtIndemnizado.Value := AReclamacion.ImporteIndemnizado
    else
      edtIndemnizado.EditValue := Null;
    edtIndemnizado.Visible := bImportes;
    iTopBotones := 186;
    if bImportes then
      iTopBotones := 304;
    oAceptar := CrearBoton(oDialogo, SCaptionAceptar, 234, iTopBotones,
      110, nil);
    oAceptar.ModalResult := mrOk;
    oAceptar.Default := True;
    oCancelar := CrearBoton(oDialogo, SCaptionCancelar, 354, iTopBotones,
      110, nil);
    oCancelar.ModalResult := mrCancel;
    oCancelar.Cancel := True;
    oDialogo.ClientHeight := EscalarDpi(iTopBotones + 50);
    oDialogo.ActiveControl := edtReferenciaRec;
    Result := oDialogo.ShowModal = mrOk;
    if Result then
    begin
      AReclamacion.Referencia := Trim(edtReferenciaRec.Text);
      AReclamacion.Estado :=
        ESTADOS_RECLAMACION_TRANSITO[cbbEstadoRec.ItemIndex];
      if bImportes then
      begin
        AReclamacion.ImporteReclamado := edtReclamado.Value;
        AReclamacion.ConIndemnizado :=
          not VarIsNull(edtIndemnizado.EditValue) and
          (Trim(edtIndemnizado.Text) <> '');
        AReclamacion.ImporteIndemnizado := 0;
        if AReclamacion.ConIndemnizado then
          AReclamacion.ImporteIndemnizado := edtIndemnizado.Value;
      end;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

// La reclamación al transportista o al seguro es una para toda la carga:
// referencia, estado e importes se anotan de una vez (FZ-ISSUE-728).
procedure TfrmMtoCargasTransito.btnReclamacionClick(Sender: TObject);
var
  oApuntes: TDataSet;
  aIds: TArray<Int64>;
  Reclamacion: TReclamacionTransito;
  iId: Int64;
begin
  oApuntes := dmmCargas.dsIncidencias.DataSet;
  if (not Assigned(oApuntes)) or (not oApuntes.Active) or
     oApuntes.IsEmpty then
    ShowMessage_fza(SInfoSinIncidenciasTransito)
  else
  begin
    iId := oApuntes.FieldByName(CAMPO_ID_INCIDENCIA).AsLargeInt;
    aIds := IncidenciasAReclamar;
    Reclamacion := dmmCargas.LeerReclamacion(aIds);
    if PedirReclamacion(Length(aIds), Reclamacion) then
    begin
      try
        dmmCargas.GrabarReclamacion(aIds, Reclamacion);
      except
        on E: EArgumentException do
          ShowMessage_fza(E.Message);
      end;
      dmmCargas.RefrescarIncidencias;
      oApuntes.Locate(CAMPO_ID_INCIDENCIA, iId, []);
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoCargasTransito);
  ForceReferenceToClass(TfrmMtoCargasTransito);
end.
