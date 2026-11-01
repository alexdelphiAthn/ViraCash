{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoListasRegalos                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ventas Mayor - Lista de regalos PrestaShop (nacimiento, bautizo...).      }
{    Lista con filtros y sincronización con la tienda; ficha montada en        }
{    código con la cabecera, los artículos (alta por SKU o código de barras)   }
{    y los regalos recibidos (entrega y anulación), y cierre o anulación de    }
{    la lista. Solo con appListasRegalos encendido (si no, el menú se oculta). }
{******************************************************************************}
unit inMtoListasRegalos;

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
  cxDBEdit, cxMemo, cxImageComboBox, cxGroupBox, cxSpinEdit,
  cxCurrencyEdit, dxCore, cxScrollBox, cxSplitter,
  UniDataListasRegalos, inMtoGen;

type
  TfrmMtoListasRegalos = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados: Boolean;
    FCodigosEstado: TArray<string>;
    dmmListas: TdmListasRegalos;
    FDesplazamiento: TcxScrollBox;
    FContenidoFicha: TcxGroupBox;
    FSeparadorFicha: TcxSplitter;
    pnlFiltros: TcxGroupBox;
    cbbEstado: TcxComboBox;
    edtTexto: TcxTextEdit;
    pnlCabecera: TcxGroupBox;
    grpDatos: TcxGroupBox;
    grpTitulares: TcxGroupBox;
    pcDetalle: TcxPageControl;
    tsLineas: TcxTabSheet;
    tsRegalos: TcxTabSheet;
    edtSku: TcxTextEdit;
    edtCantidad: TcxSpinEdit;
    tvLineas: TcxGridDBTableView;
    tvRegalos: TcxGridDBTableView;
    function EscalarDpi(AValor: Integer): Integer;
    function CrearPanel(AParent: TWinControl; AAlineacion: TAlign;
      AAlto: Integer): TcxGroupBox;
    function CrearEtiqueta(AParent: TWinControl; const ATexto: string;
      AIzq, ATop: Integer): TcxLabel;
    function CrearBoton(AParent: TWinControl; const ATexto: string;
      AIzq, ATop, AAncho: Integer; AAlPulsar: TNotifyEvent): TcxButton;
    procedure CrearFiltros;
    procedure CrearColumnas;
    function CrearColumna(AVista: TcxGridDBTableView;
      const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
    procedure ColumnaCasilla(AColumna: TcxGridDBColumn);
    procedure ColumnaImporte(AColumna: TcxGridDBColumn);
    procedure ImporteGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure AjustarEditores(Sender: TObject);
    procedure AjustarContenidoFicha(Sender: TObject);
    procedure AjustarRepartoFicha(Sender: TObject);
    procedure LimitarRepartoFicha(Sender: TObject;
      var NewSize: Integer; var Accept: Boolean);
    // Ficha: rótulo y editor en la fila AFila de un grupo de una columna.
    procedure Colocar(AParent: TWinControl; const ARotulo: string;
      AEditor: TcxCustomEdit; AFila: Integer);
    function CrearTexto(AParent: TWinControl; const ARotulo, ACampo: string;
      AFila: Integer; ASoloLectura: Boolean = False): TcxDBTextEdit;
    function CrearFecha(AParent: TWinControl; const ARotulo, ACampo: string;
      AFila: Integer): TcxDBDateEdit;
    function CrearOpciones(AParent: TWinControl; const ARotulo, ACampo: string;
      AFila: Integer; const AValores, ATextos: array of string):
      TcxDBImageComboBox;
    procedure CrearCasilla(AParent: TWinControl; const ARotulo,
      ACampo: string; AFila: Integer);
    procedure CrearGrupoDatos;
    procedure CrearGrupoTitulares;
    procedure CrearPestanaLineas;
    procedure CrearPestanaRegalos;
    function CrearRejilla(AParent: TWinControl;
      ADatos: TDataSource): TcxGridDBTableView;
    procedure EstadoListaGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure TipoListaGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure CanalGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure EstadoRegaloGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    function EstadoFiltro: string;
    function HayLista: Boolean;
    function ListaGrabada: Boolean;
    function HayFila(ADatos: TDataSet; const AAviso: string): Boolean;
    procedure MostrarResultado(AResultado: Integer);
    procedure FiltroCambiado(Sender: TObject);
    procedure btnSincronizarClick(Sender: TObject);
    procedure btnCerrarListaClick(Sender: TObject);
    procedure btnAnularListaClick(Sender: TObject);
    procedure btnAgregarLineaClick(Sender: TObject);
    procedure btnCambiarCantidadClick(Sender: TObject);
    procedure btnEntregarRegaloClick(Sender: TObject);
    procedure btnAnularRegaloClick(Sender: TObject);
  protected
    procedure DoCreate; override;
    procedure CrearFicha;
  public
    function ContarHijosActivos: Integer; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  end;

implementation

{$R *.dfm}

uses
  System.Math, inLibMensajesVcl, inLibListasRegalos,
  inLibListasRegalosSincronizacion,
  inLibMsgListasRegalos, inLibGestorGuardianBorradoMto;

const
  CAMPO_CODIGO = 'CODIGO_LRG';
  FORMATO_FECHA_LISTA = 'dd/mm/yyyy';
  FORMATO_IMPORTE = '#,##0.00';
  FORMATO_EUROS = '0.00 "€"';
  // Ficha: medidas nominales a 96 ppp.
  MARGEN = 12;
  ANCHO_ROTULO = 130;
  ALTO_FILA = 32;
  TOP_PRIMERA_FILA = 24;
  FILAS_CABECERA = 9;
  ANCHO_GRUPO_DATOS = 470;

procedure TfrmMtoListasRegalos.FormCreate(Sender: TObject);
begin
  if not FControlesCreados then
  begin
    CrearFiltros;
    CrearFicha;
    FControlesCreados := True;
  end;
  inherited;
end;

// El título se fija tras la traducción del formulario base.
procedure TfrmMtoListasRegalos.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloListasRegalos;
end;

function TfrmMtoListasRegalos.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoListasRegalos.CrearPanel(AParent: TWinControl;
  AAlineacion: TAlign; AAlto: Integer): TcxGroupBox;
begin
  Result := TcxGroupBox.Create(Self);
  Result.Parent := AParent;
  Result.Align := AAlineacion;
  Result.Height := EscalarDpi(AAlto);
  Result.PanelStyle.Active := True;
  Result.Style.BorderStyle := ebsNone;
  Result.Transparent := True;
end;

function TfrmMtoListasRegalos.CrearEtiqueta(AParent: TWinControl;
  const ATexto: string; AIzq, ATop: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := AParent;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Caption := ATexto;
  Result.Transparent := True;
end;

function TfrmMtoListasRegalos.CrearBoton(AParent: TWinControl;
  const ATexto: string; AIzq, ATop, AAncho: Integer;
  AAlPulsar: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Self);
  Result.Parent := AParent;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Width := EscalarDpi(AAncho);
  Result.Height := EscalarDpi(32);
  Result.Caption := ATexto;
  Result.OnClick := AAlPulsar;
end;

procedure TfrmMtoListasRegalos.CrearFiltros;
begin
  pnlFiltros := CrearPanel(tsLista, alTop, 52);
  CrearEtiqueta(pnlFiltros, SCaptionFiltroEstadoLista, 12, 16);
  cbbEstado := TcxComboBox.Create(Self);
  cbbEstado.Parent := pnlFiltros;
  cbbEstado.Left := EscalarDpi(80);
  cbbEstado.Top := EscalarDpi(12);
  cbbEstado.Width := EscalarDpi(150);
  cbbEstado.Properties.DropDownListStyle := lsFixedList;
  cbbEstado.Properties.Items.AddStrings([SCaptionListasAbiertas,
    SCaptionListasCerradas, SCaptionListasAnuladas, SCaptionListasTodas]);
  FCodigosEstado := [ESTADO_LISTA_ABIERTA, ESTADO_LISTA_CERRADA,
    ESTADO_LISTA_ANULADA, ''];
  cbbEstado.ItemIndex := 0;
  cbbEstado.Properties.OnChange := FiltroCambiado;
  CrearEtiqueta(pnlFiltros, SCaptionFiltroTextoLista, 250, 16);
  edtTexto := TcxTextEdit.Create(Self);
  edtTexto.Parent := pnlFiltros;
  edtTexto.Left := EscalarDpi(390);
  edtTexto.Top := EscalarDpi(12);
  edtTexto.Width := EscalarDpi(240);
  CrearBoton(pnlFiltros, SCaptionListaRefrescar, 650, 10, 110,
    FiltroCambiado);
  CrearBoton(pnlFiltros, SCaptionListaSincronizar, 770, 10, 220,
    btnSincronizarClick);
end;

function TfrmMtoListasRegalos.CrearColumna(AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmMtoListasRegalos.ColumnaCasilla(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxCheckBoxProperties;
  TcxCheckBoxProperties(AColumna.Properties).ValueChecked := 'S';
  TcxCheckBoxProperties(AColumna.Properties).ValueUnchecked := 'N';
end;

procedure TfrmMtoListasRegalos.ColumnaImporte(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(AColumna.Properties).DecimalPlaces := 2;
  TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat :=
    FORMATO_EUROS;
  AColumna.OnGetDisplayText := ImporteGetDisplayText;
end;

procedure TfrmMtoListasRegalos.ImporteGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if not VarIsNull(ARecord.Values[Sender.Index]) then
    AText := FormatFloat(FORMATO_IMPORTE, ARecord.Values[Sender.Index]);
end;

function TfrmMtoListasRegalos.ContarHijosActivos: Integer;
begin
  Result := cBorradoConConfirmacionPropia;
end;

procedure TfrmMtoListasRegalos.CrearColumnas;
var
  oColumna: TcxGridDBColumn;
begin
  cxgrdPrincipal.LookAndFeel.ScrollbarMode := sbmClassic;
  cxGrdDBTabPrin.OptionsView.HeaderAutoHeight := True;
  if cxGrdDBTabPrin.ColumnCount = 0 then
  begin
    CrearColumna(cxGrdDBTabPrin, CAMPO_CODIGO, SColListaCodigo, 80);
    CrearColumna(cxGrdDBTabPrin, 'CLAVE_PUBLICA_LRG', SColListaClave, 100);
    CrearColumna(cxGrdDBTabPrin, 'TIPO_LRG', SColListaTipo,
      100).OnGetDisplayText := TipoListaGetDisplayText;
    CrearColumna(cxGrdDBTabPrin, 'TITULO_LRG', SColListaTitulo, 240);
    CrearColumna(cxGrdDBTabPrin, 'NOMBRE_TITULARES_LRG', SColListaTitulares,
      200);
    CrearColumna(cxGrdDBTabPrin, 'NOMBRE_HOMENAJEADO_LRG',
      SColListaHomenajeado, 140);
    oColumna := CrearColumna(cxGrdDBTabPrin, 'FECHA_EVENTO_LRG',
      SColListaFechaEvento, 140);
    oColumna.PropertiesClass := TcxDateEditProperties;
    TcxDateEditProperties(oColumna.Properties).DisplayFormat :=
      FORMATO_FECHA_LISTA;
    CrearColumna(cxGrdDBTabPrin, 'ESTADO_LRG', SColListaEstado,
      90).OnGetDisplayText := EstadoListaGetDisplayText;
    ColumnaCasilla(CrearColumna(cxGrdDBTabPrin, 'ESPUBLICA_WEB_LRG',
      SColListaWeb, 60));
    CrearColumna(cxGrdDBTabPrin, 'NUMERO_LINEAS', SColListaLineas, 80);
    ColumnaImporte(CrearColumna(cxGrdDBTabPrin, 'IMPORTE_REGALADO',
      SColListaRegalado, 100));
    CrearColumna(cxGrdDBTabPrin, 'VERSION_LRG', SColListaVersion, 70);
  end;
end;

procedure TfrmMtoListasRegalos.Colocar(AParent: TWinControl;
  const ARotulo: string; AEditor: TcxCustomEdit; AFila: Integer);
begin
  if ARotulo <> '' then
    CrearEtiqueta(AParent, ARotulo, MARGEN,
      TOP_PRIMERA_FILA + AFila * ALTO_FILA + 3);
  AEditor.Parent := AParent;
  AEditor.Left := EscalarDpi(MARGEN + ANCHO_ROTULO);
  AEditor.Top := EscalarDpi(TOP_PRIMERA_FILA + AFila * ALTO_FILA);
  // El grupo alClient puede no tener aún su ancho final: mínimo razonable
  // y anclaje a la derecha para que siga al contenedor.
  AEditor.Width := Max(EscalarDpi(40),
    AParent.ClientWidth - AEditor.Left - EscalarDpi(MARGEN));
  AEditor.Anchors := [akLeft, akTop, akRight];
  AEditor.Tag := 1;
end;

procedure TfrmMtoListasRegalos.AjustarRepartoFicha(Sender: TObject);
var
  iMaximo: Integer;
begin
  iMaximo := Max(EscalarDpi(100),
    tsFicha.ClientHeight - EscalarDpi(148));
  FDesplazamiento.Height := Min(FDesplazamiento.Height, iMaximo);
end;

procedure TfrmMtoListasRegalos.LimitarRepartoFicha(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  NewSize := EnsureRange(NewSize, EscalarDpi(100),
    Max(EscalarDpi(100), tsFicha.ClientHeight - EscalarDpi(148)));
  Accept := True;
end;

procedure TfrmMtoListasRegalos.AjustarContenidoFicha(Sender: TObject);
begin
  if Assigned(FContenidoFicha) then
  begin
    FContenidoFicha.Width := Max(FDesplazamiento.ClientWidth,
      FContenidoFicha.Constraints.MinWidth);
    FContenidoFicha.Height := Max(FDesplazamiento.ClientHeight,
      FContenidoFicha.Constraints.MinHeight);
  end;
end;

procedure TfrmMtoListasRegalos.AjustarEditores(Sender: TObject);
var
  Grupo: TWinControl;
  i: Integer;
begin
  Grupo := Sender as TWinControl;
  for i := 0 to Grupo.ControlCount - 1 do
    if (Grupo.Controls[i] is TcxCustomEdit) and
       (Grupo.Controls[i].Tag = 1) then
      Grupo.Controls[i].Width := Max(EscalarDpi(40),
        Grupo.ClientWidth - Grupo.Controls[i].Left - EscalarDpi(MARGEN));
end;

function TfrmMtoListasRegalos.CrearTexto(AParent: TWinControl;
  const ARotulo, ACampo: string; AFila: Integer;
  ASoloLectura: Boolean): TcxDBTextEdit;
begin
  Result := TcxDBTextEdit.Create(Self);
  Colocar(AParent, ARotulo, Result, AFila);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.ReadOnly := ASoloLectura;
  Result.TabStop := not ASoloLectura;
end;

function TfrmMtoListasRegalos.CrearFecha(AParent: TWinControl;
  const ARotulo, ACampo: string; AFila: Integer): TcxDBDateEdit;
begin
  Result := TcxDBDateEdit.Create(Self);
  Colocar(AParent, ARotulo, Result, AFila);
  Result.Anchors := [akLeft, akTop];
  Result.Tag := 0;
  Result.Width := EscalarDpi(130);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  Result.Properties.DisplayFormat := FORMATO_FECHA_LISTA;
  Result.Properties.ShowTime := False;
end;

function TfrmMtoListasRegalos.CrearOpciones(AParent: TWinControl;
  const ARotulo, ACampo: string; AFila: Integer;
  const AValores, ATextos: array of string): TcxDBImageComboBox;
var
  i: Integer;
  oOpcion: TcxImageComboBoxItem;
begin
  Result := TcxDBImageComboBox.Create(Self);
  Colocar(AParent, ARotulo, Result, AFila);
  Result.DataBinding.DataSource := dsTablaG;
  Result.DataBinding.DataField := ACampo;
  for i := 0 to High(AValores) do
  begin
    oOpcion := Result.Properties.Items.Add;
    oOpcion.Value := AValores[i];
    oOpcion.Description := ATextos[i];
  end;
end;

procedure TfrmMtoListasRegalos.CrearCasilla(AParent: TWinControl;
  const ARotulo, ACampo: string; AFila: Integer);
var
  oCasilla: TcxDBCheckBox;
begin
  oCasilla := TcxDBCheckBox.Create(Self);
  Colocar(AParent, '', oCasilla, AFila);
  oCasilla.Caption := ARotulo;
  oCasilla.Transparent := True;
  oCasilla.DataBinding.DataSource := dsTablaG;
  oCasilla.DataBinding.DataField := ACampo;
  oCasilla.Properties.ValueChecked := 'S';
  oCasilla.Properties.ValueUnchecked := 'N';
end;

procedure TfrmMtoListasRegalos.CrearGrupoDatos;
var
  oBonificacion: TcxDBCurrencyEdit;
begin
  grpDatos := TcxGroupBox.Create(Self);
  grpDatos.Parent := pnlCabecera;
  grpDatos.Align := alLeft;
  grpDatos.Width := EscalarDpi(ANCHO_GRUPO_DATOS);
  grpDatos.Caption := SGrupoDatosLista;
  grpDatos.AlignWithMargins := True;
  grpDatos.OnResize := AjustarEditores;
  CrearTexto(grpDatos, SRotuloListaCodigo, CAMPO_CODIGO, 0, True);
  CrearTexto(grpDatos, SRotuloListaClave, 'CLAVE_PUBLICA_LRG', 1, True);
  CrearOpciones(grpDatos, SRotuloListaTipo, 'TIPO_LRG', 2, TIPOS_LISTA,
    [STipoListaNacimiento, STipoListaBautizo, STipoListaComunion,
     STipoListaCumpleanos, STipoListaBoda, STipoListaOtra]);
  CrearTexto(grpDatos, SRotuloListaTitulo, 'TITULO_LRG', 3);
  CrearTexto(grpDatos, SRotuloListaHomenajeado, 'NOMBRE_HOMENAJEADO_LRG', 4);
  CrearFecha(grpDatos, SRotuloListaFechaEvento, 'FECHA_EVENTO_LRG', 5);
  CrearFecha(grpDatos, SRotuloListaCaducidad, 'FECHA_CADUCIDAD_LRG', 6);
  CrearOpciones(grpDatos, SRotuloListaEstado, 'ESTADO_LRG', 7,
    [ESTADO_LISTA_ABIERTA, ESTADO_LISTA_CERRADA, ESTADO_LISTA_ANULADA],
    [SEstadoListaAbierta, SEstadoListaCerrada, SEstadoListaAnulada])
    .Properties.ReadOnly := True;
  oBonificacion := TcxDBCurrencyEdit.Create(Self);
  Colocar(grpDatos, SRotuloListaBonificacion, oBonificacion, 8);
  oBonificacion.Anchors := [akLeft, akTop];
  oBonificacion.Tag := 0;
  oBonificacion.Width := EscalarDpi(90);
  oBonificacion.DataBinding.DataSource := dsTablaG;
  oBonificacion.DataBinding.DataField := 'PORCENTAJE_BONIFICACION_LRG';
  oBonificacion.Properties.DisplayFormat := FORMATO_IMPORTE;
end;

procedure TfrmMtoListasRegalos.CrearGrupoTitulares;
var
  oMensaje: TcxDBMemo;
begin
  grpTitulares := TcxGroupBox.Create(Self);
  grpTitulares.Parent := pnlCabecera;
  grpTitulares.Align := alClient;
  grpTitulares.Caption := SGrupoTitularesLista;
  grpTitulares.AlignWithMargins := True;
  grpTitulares.OnResize := AjustarEditores;
  CrearTexto(grpTitulares, SRotuloListaTitulares, 'NOMBRE_TITULARES_LRG', 0);
  CrearTexto(grpTitulares, SRotuloListaCliente, 'CODIGO_CLI_LRG', 1);
  CrearTexto(grpTitulares, SRotuloListaEmail, 'EMAIL_TITULARES_LRG', 2);
  CrearTexto(grpTitulares, SRotuloListaMovil, 'MOVIL_TITULARES_LRG', 3);
  CrearOpciones(grpTitulares, SRotuloListaEntrega, 'TIPO_ENTREGA_LRG', 4,
    ENTREGAS_LISTA, [SEntregaListaTienda, SEntregaListaDomicilio]);
  CrearCasilla(grpTitulares, SRotuloListaPublica, 'ESPUBLICA_WEB_LRG', 5);
  CrearCasilla(grpTitulares, SRotuloListaBuscable, 'ESBUSCABLE_LRG', 6);
  oMensaje := TcxDBMemo.Create(Self);
  Colocar(grpTitulares, SRotuloListaMensaje, oMensaje, 7);
  oMensaje.Height := EscalarDpi(2 * ALTO_FILA - 4);
  oMensaje.DataBinding.DataSource := dsTablaG;
  oMensaje.DataBinding.DataField := 'MENSAJE_LRG';
  oMensaje.Properties.ScrollBars := ssVertical;
end;

function TfrmMtoListasRegalos.CrearRejilla(AParent: TWinControl;
  ADatos: TDataSource): TcxGridDBTableView;
var
  oRejilla: TcxGrid;
  oNivel: TcxGridLevel;
begin
  oRejilla := TcxGrid.Create(Self);
  oRejilla.Parent := AParent;
  oRejilla.Align := alClient;
  Result := oRejilla.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  oNivel := oRejilla.Levels.Add;
  oNivel.GridView := Result;
  Result.DataController.DataSource := ADatos;
  Result.OptionsData.Inserting := False;
  Result.OptionsData.Deleting := False;
  Result.OptionsView.GroupByBox := False;
  Result.OptionsView.HeaderAutoHeight := True;
  oRejilla.LookAndFeel.ScrollbarMode := sbmClassic;
end;

procedure TfrmMtoListasRegalos.CrearPestanaLineas;
var
  oBarra: TcxGroupBox;
begin
  tsLineas := TcxTabSheet.Create(Self);
  tsLineas.PageControl := pcDetalle;
  tsLineas.Caption := SPestanaLineasLista;
  oBarra := CrearPanel(tsLineas, alTop, 48);
  CrearEtiqueta(oBarra, SRotuloListaSku, 12, 14);
  edtSku := TcxTextEdit.Create(Self);
  edtSku.Parent := oBarra;
  edtSku.Left := EscalarDpi(180);
  edtSku.Top := EscalarDpi(10);
  edtSku.Width := EscalarDpi(220);
  CrearEtiqueta(oBarra, SRotuloListaCantidad, 412, 14);
  edtCantidad := TcxSpinEdit.Create(Self);
  edtCantidad.Parent := oBarra;
  edtCantidad.Left := EscalarDpi(480);
  edtCantidad.Top := EscalarDpi(10);
  edtCantidad.Width := EscalarDpi(70);
  edtCantidad.Properties.MinValue := 1;
  edtCantidad.Properties.MaxValue := 999;
  edtCantidad.Value := 1;
  CrearBoton(oBarra, SCaptionListaAgregarLinea, 562, 8, 100,
    btnAgregarLineaClick);
  CrearBoton(oBarra, SCaptionListaCambiarCantidad, 670, 8, 150,
    btnCambiarCantidadClick);
end;

procedure TfrmMtoListasRegalos.CrearPestanaRegalos;
var
  oBarra: TcxGroupBox;
begin
  tsRegalos := TcxTabSheet.Create(Self);
  tsRegalos.PageControl := pcDetalle;
  tsRegalos.Caption := SPestanaRegalosLista;
  oBarra := CrearPanel(tsRegalos, alTop, 48);
  CrearBoton(oBarra, SCaptionListaEntregarRegalo, 12, 8, 160,
    btnEntregarRegaloClick);
  CrearBoton(oBarra, SCaptionListaAnularRegalo, 180, 8, 160,
    btnAnularRegaloClick);
end;

procedure TfrmMtoListasRegalos.CrearFicha;
var
  oBotones: TcxGroupBox;
begin
  FDesplazamiento := TcxScrollBox.Create(Self);
  FDesplazamiento.Parent := tsFicha;
  FDesplazamiento.Align := alTop;
  FDesplazamiento.Height := Min(EscalarDpi(384),
    Max(EscalarDpi(100), tsFicha.ClientHeight div 2));
  FDesplazamiento.AutoScroll := True;
  FDesplazamiento.LookAndFeel.ScrollbarMode := sbmClassic;
  FDesplazamiento.VertScrollBar.Tracking := True;
  FDesplazamiento.HorzScrollBar.Tracking := True;
  FContenidoFicha := CrearPanel(FDesplazamiento, alNone, 384);
  FContenidoFicha.Constraints.MinWidth := EscalarDpi(1000);
  FContenidoFicha.Constraints.MinHeight := EscalarDpi(384);
  FDesplazamiento.OnResize := AjustarContenidoFicha;
  AjustarContenidoFicha(FDesplazamiento);
  pnlCabecera := CrearPanel(FContenidoFicha, alTop,
    TOP_PRIMERA_FILA + FILAS_CABECERA * ALTO_FILA + 24);
  CrearGrupoDatos;
  CrearGrupoTitulares;
  oBotones := CrearPanel(FContenidoFicha, alTop, 48);
  oBotones.Top := pnlCabecera.Top + pnlCabecera.Height;
  CrearBoton(oBotones, SCaptionListaCerrar, 12, 8, 140, btnCerrarListaClick);
  CrearBoton(oBotones, SCaptionListaAnular, 160, 8, 140,
    btnAnularListaClick);
  FSeparadorFicha := TcxSplitter.Create(Self);
  FSeparadorFicha.Parent := tsFicha;
  FSeparadorFicha.AlignSplitter := salTop;
  FSeparadorFicha.Top := FDesplazamiento.BoundsRect.Bottom;
  FSeparadorFicha.Control := FDesplazamiento;
  FSeparadorFicha.MinSize := EscalarDpi(100);
  FSeparadorFicha.ResizeUpdate := True;
  FSeparadorFicha.OnCanResize := LimitarRepartoFicha;
  tsFicha.OnResize := AjustarRepartoFicha;
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := tsFicha;
  pcDetalle.Align := alClient;
  CrearPestanaLineas;
  CrearPestanaRegalos;
  pcDetalle.ActivePage := tsLineas;
  AjustarEditores(grpDatos);
  AjustarEditores(grpTitulares);
end;

// Las rejillas de detalle se enlazan cuando el data module ya existe.
procedure TfrmMtoListasRegalos.CrearTablaPrincipal;
var
  oColumna: TcxGridDBColumn;
begin
  inherited;
  dmmListas := tdmDataModule as TdmListasRegalos;
  pkFieldName := CAMPO_CODIGO;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  nvNavegador.Buttons.Delete.Visible := False;
  CrearColumnas;
  tvLineas := CrearRejilla(tsLineas, dmmListas.dsLineas);
  CrearColumna(tvLineas, 'CODIGO_SKU_LRGLIN', SColLineaSku, 170);
  CrearColumna(tvLineas, 'DESCRIPCION_LRGLIN', SColLineaDescripcion, 260);
  CrearColumna(tvLineas, 'CANTIDAD_DESEADA_LRGLIN', SColLineaDeseada, 70);
  CrearColumna(tvLineas, 'CANTIDAD_REGALADA_LRGLIN', SColLineaRegalada, 80);
  CrearColumna(tvLineas, 'CANTIDAD_PENDIENTE_LRGLIN', SColLineaPendiente, 80);
  ColumnaImporte(CrearColumna(tvLineas, 'PRECIO_REFERENCIA_LRGLIN',
    SColLineaPrecio, 100));
  oColumna := CrearColumna(tvLineas, 'ESIMPRESCINDIBLE_LRGLIN',
    SColLineaImprescindible, 130);
  ColumnaCasilla(oColumna);
  oColumna.Options.Editing := True;
  oColumna := CrearColumna(tvLineas, 'ESADMITE_OTRA_VARIANTE_LRGLIN',
    SColLineaOtraVariante, 170);
  ColumnaCasilla(oColumna);
  oColumna.Options.Editing := True;
  CrearColumna(tvLineas, 'OBSERVACIONES_LRGLIN', SColLineaObservaciones,
    240).Options.Editing := True;
  tvRegalos := CrearRejilla(tsRegalos, dmmListas.dsRegalos);
  tvRegalos.OptionsData.Editing := False;
  CrearColumna(tvRegalos, 'INSTANTE_LRGREG', SColRegaloFecha, 130);
  CrearColumna(tvRegalos, 'CANAL_LRGREG', SColRegaloCanal,
    70).OnGetDisplayText := CanalGetDisplayText;
  CrearColumna(tvRegalos, 'CODIGO_SKU_LRGREG', SColLineaSku, 160);
  CrearColumna(tvRegalos, 'CANTIDAD_LRGREG', SColRegaloCantidad, 85);
  ColumnaImporte(CrearColumna(tvRegalos, 'IMPORTE_LRGREG',
    SColRegaloImporte, 100));
  CrearColumna(tvRegalos, 'NOMBRE_REGALANTE_LRGREG', SColRegaloRegalante,
    160);
  CrearColumna(tvRegalos, 'MENSAJE_LRGREG', SColRegaloMensaje, 220);
  ColumnaCasilla(CrearColumna(tvRegalos, 'ESENTREGADO_LRGREG',
    SColRegaloEntregado, 80));
  CrearColumna(tvRegalos, 'ESTADO_LRGREG', SColRegaloEstado,
    90).OnGetDisplayText := EstadoRegaloGetDisplayText;
  CrearColumna(tvRegalos, 'DOCUMENTO_REGALO', SColRegaloPedido, 160);
  FiltroCambiado(nil);
end;

procedure TfrmMtoListasRegalos.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

procedure TfrmMtoListasRegalos.EstadoListaGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoEstadoLista(AText);
end;

procedure TfrmMtoListasRegalos.TipoListaGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoTipoLista(AText);
end;

procedure TfrmMtoListasRegalos.CanalGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoCanalRegalo(AText);
end;

procedure TfrmMtoListasRegalos.EstadoRegaloGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoEstadoRegalo(AText);
end;

function TfrmMtoListasRegalos.EstadoFiltro: string;
begin
  Result := '';
  if (cbbEstado.ItemIndex >= 0) and
     (cbbEstado.ItemIndex <= High(FCodigosEstado)) then
    Result := FCodigosEstado[cbbEstado.ItemIndex];
end;

function TfrmMtoListasRegalos.HayLista: Boolean;
begin
  Result := Assigned(dmmListas) and (dmmListas.CodigoLista <> '');
  if not Result then
    ShowMessage_fza(SInfoListaSinSeleccion);
end;

// Las operaciones de la ficha trabajan sobre la lista ya grabada.
function TfrmMtoListasRegalos.ListaGrabada: Boolean;
begin
  Result := HayLista and not (dsTablaG.State in dsEditModes);
  if HayLista and not Result then
    ShowMessage_fza(SInfoListaGrabarAntes);
end;

function TfrmMtoListasRegalos.HayFila(ADatos: TDataSet;
  const AAviso: string): Boolean;
begin
  Result := ADatos.Active and not ADatos.IsEmpty;
  if not Result then
    ShowMessage_fza(AAviso);
end;

procedure TfrmMtoListasRegalos.MostrarResultado(AResultado: Integer);
var
  sTexto: string;
begin
  sTexto := TextoResultadoLista(AResultado);
  if sTexto <> '' then
    ShowMessage_fza(sTexto);
end;

procedure TfrmMtoListasRegalos.FiltroCambiado(Sender: TObject);
begin
  if Assigned(dmmListas) then
    dmmListas.AplicarFiltros(EstadoFiltro, edtTexto.Text);
end;

procedure TfrmMtoListasRegalos.btnSincronizarClick(Sender: TObject);
var
  oInforme: TInformeSincronizacionListas;
  sCodigo: string;
begin
  sCodigo := dmmListas.CodigoLista;
  Screen.Cursor := crHourGlass;
  try
    oInforme := dmmListas.Sincronizar;
  finally
    Screen.Cursor := crDefault;
  end;
  if oInforme.Vacio then
    ShowMessage_fza(SInfoSincronizacionListasVacia)
  else
    ShowMessage_fza(Format(SInfoSincronizacionListas, [oInforme.Publicadas,
      oInforme.Registrados, oInforme.Rechazados]) + sLineBreak +
      sLineBreak + string.Join(sLineBreak, oInforme.Detalle));
  FiltroCambiado(nil);
  dmmListas.unqryTablaG.Locate(CAMPO_CODIGO, sCodigo, []);
end;

procedure TfrmMtoListasRegalos.btnCerrarListaClick(Sender: TObject);
var
  oCierre: TResultadoCierreLista;
begin
  if ListaGrabada and (MessageDlg_fza(Format(SConfirmarCerrarLista,
    [dmmListas.CodigoLista, FormatFloat(FORMATO_IMPORTE,
      dmmListas.unqryTablaG.FieldByName('IMPORTE_REGALADO').AsFloat)]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    oCierre := dmmListas.Cerrar;
    if oCierre.Resultado = RESULTADO_LRG_CORRECTO then
      ShowMessage_fza(Format(SInfoListaCerrada,
        [FormatFloat(FORMATO_IMPORTE, oCierre.TotalRegalado),
         FormatFloat(FORMATO_IMPORTE, oCierre.Bonificacion)]))
    else
      MostrarResultado(oCierre.Resultado);
  end;
end;

procedure TfrmMtoListasRegalos.btnAnularListaClick(Sender: TObject);
begin
  if ListaGrabada and (MessageDlg_fza(Format(SConfirmarAnularLista,
    [dmmListas.CodigoLista]), mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    MostrarResultado(dmmListas.Anular);
end;

procedure TfrmMtoListasRegalos.btnAgregarLineaClick(Sender: TObject);
begin
  if ListaGrabada and (Trim(edtSku.Text) <> '') then
  begin
    MostrarResultado(dmmListas.AgregarLinea(edtSku.Text,
      edtCantidad.Value));
    edtSku.Clear;
    edtCantidad.Value := 1;
    edtSku.SetFocus;
  end;
end;

procedure TfrmMtoListasRegalos.btnCambiarCantidadClick(Sender: TObject);
var
  sValor: string;
  oLineas: TDataSet;
begin
  oLineas := dmmListas.Lineas;
  if ListaGrabada and HayFila(oLineas, SInfoLineaSinSeleccion) then
  begin
    sValor := oLineas.FieldByName('CANTIDAD_DESEADA_LRGLIN').AsString;
    if InputQuery_fza(SCaptionListaCambiarCantidad, SPreguntaCantidadLinea,
      sValor) then
      MostrarResultado(dmmListas.CambiarCantidadLinea(
        oLineas.FieldByName('LINEA_LRGLIN').AsInteger,
        StrToIntDef(Trim(sValor), -1)));
  end;
end;

procedure TfrmMtoListasRegalos.btnEntregarRegaloClick(Sender: TObject);
var
  oRegalos: TDataSet;
begin
  oRegalos := dmmListas.Regalos;
  if HayLista and HayFila(oRegalos, SInfoRegaloSinSeleccion) then
    MostrarResultado(dmmListas.EntregarRegalo(
      oRegalos.FieldByName('ID_LRGREG').AsLargeInt));
end;

procedure TfrmMtoListasRegalos.btnAnularRegaloClick(Sender: TObject);
var
  sMotivo: string;
  oRegalos: TDataSet;
begin
  oRegalos := dmmListas.Regalos;
  sMotivo := '';
  if HayLista and HayFila(oRegalos, SInfoRegaloSinSeleccion) and
     InputQuery_fza(SCaptionListaAnularRegalo,
       SPreguntaMotivoAnulacionRegalo, sMotivo) then
    MostrarResultado(dmmListas.AnularRegalo(
      oRegalos.FieldByName('ID_LRGREG').AsLargeInt, sMotivo));
end;

initialization
  RegistrarPantalla(TfrmMtoListasRegalos);
end.
