{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoLotesCaducidades                                         }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Stock por lote o serie, caducidad y antigüedad. Exportable a Excel.     }
{    Filtros por caducidad, tipo, almacén y artículo.                         }
{    Solo con algún interruptor de trazabilidad encendido.                    }
{******************************************************************************}
unit inMtoLotesCaducidades;

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
  cxSpinEdit, cxPC, dxSkinsCore, dxSkinscxPCPainter,
  dxScrollbarAnnotations, dxDateRanges, dxCore,
  UniDataLotesConsultas, inLibTraspasoOpePersistenciaIntf, inMtoGen,
  inLibRetiradaLotesIntf;

type
  TfrmMtoLotesCaducidades = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados: Boolean;
    FRetirar: TcxButton;
    FHistorico: TcxButton;
    FCodigosAlmacen: TArray<string>;
    dmmLotes: TdmLotesConsultas;
    pnlFiltros: TPanel;
    cbbAlmacen: TcxComboBox;
    cbbFiltro: TcxComboBox;
    spnDias: TcxSpinEdit;
    cbbTipo: TcxComboBox;
    edtArticulo: TcxTextEdit;
    procedure RetirarClick(Sender: TObject);
    procedure HistoricoClick(Sender: TObject);
    function LineaRegistro(ARegistro: TcxCustomGridRecord):
      TLineaRetiradaLote;
    function EscalarDpi(AValor: Integer): Integer;
    procedure CrearFiltros;
    procedure CrearFiltrosLotes;
    function CrearEtiqueta(const ATexto: string;
      AIzq, ATop: Integer): TcxLabel;
    function CrearCombo(AIzq, ATop, AAncho: Integer;
      const ATextos: array of string): TcxComboBox;
    function CrearBoton(const ATexto: string; AIzq, ATop, AAncho: Integer;
      AAlPulsar: TNotifyEvent): TcxButton;
    procedure CargarAlmacenes;
    function CrearColumna(AVista: TcxGridDBTableView;
      const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
    procedure FormatoFecha(AColumna: TcxGridDBColumn);
    procedure FormatoNumero(AColumna: TcxGridDBColumn;
      const AFormato: string);
    procedure CrearColumnasLotes;
    function CodigoAlmacen: string;
    function CodigoFiltro: string;
    function CodigoTipo: string;
    function DiasAvisoDefecto: Integer;
    procedure AplicarFiltros;
    procedure FiltroCambiado(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    function FiltrosActuales: TFiltrosLotes;
    function Selecciones: TArray<string>;
  protected
    procedure DoCreate; override;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    // Desde la consulta de stock: abre filtrado por un artículo.
    procedure FiltrarArticulo(const AArticulo: string);
  end;

implementation

uses
  inLibMensajesVcl,
  inLibMsgLotesConsultas,
  inLibTrazabilidad,
  inLibDevExp,
  inMtoModalImpCaducidades, inLibPermisosIntf,
  inMtoModalRetiradaLotes, inMtoModalHistoricoLote,
  UniDataLotesRepositorio, inLibMsgRetiradaLotes;

{$R *.dfm}

const
  FORMATO_FECHA = 'dd/mm/yyyy';
  FORMATO_UNIDADES = '#,##0.###';
  FORMATO_IMPORTE = '#,##0.00';
  CODIGOS_FILTRO: array[0..2] of string = (FILTRO_LOTES_PROXIMOS,
    FILTRO_LOTES_CADUCADOS, FILTRO_LOTES_TODO);
  CODIGOS_TIPO: array[0..2] of string = ('', TIPO_CATALOGO_LOTE,
    TIPO_CATALOGO_SERIE);

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoLotesCaducidades.FormCreate(Sender: TObject);
begin
  if not FControlesCreados then
  begin
    CrearFiltros;
    FControlesCreados := True;
  end;
  inherited;
end;

procedure TfrmMtoLotesCaducidades.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloLotesCaducidades;
end;

function TfrmMtoLotesCaducidades.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmMtoLotesCaducidades.CrearEtiqueta(const ATexto: string;
  AIzq, ATop: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := pnlFiltros;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Caption := ATexto;
  Result.Transparent := True;
end;

function TfrmMtoLotesCaducidades.CrearCombo(AIzq, ATop, AAncho: Integer;
  const ATextos: array of string): TcxComboBox;
var
  sTexto: string;
begin
  Result := TcxComboBox.Create(Self);
  Result.Parent := pnlFiltros;
  Result.Left := EscalarDpi(AIzq);
  Result.Top := EscalarDpi(ATop);
  Result.Width := EscalarDpi(AAncho);
  Result.Properties.DropDownListStyle := lsFixedList;
  Result.Properties.DropDownRows := 16;
  for sTexto in ATextos do
    Result.Properties.Items.Add(sTexto);
  if Length(ATextos) > 0 then
    Result.ItemIndex := 0;
end;

function TfrmMtoLotesCaducidades.CrearBoton(const ATexto: string;
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

procedure TfrmMtoLotesCaducidades.CrearFiltros;
begin
  pnlFiltros := TPanel.Create(Self);
  pnlFiltros.Parent := tsLista;
  pnlFiltros.Align := alTop;
  pnlFiltros.Height := EscalarDpi(132);
  pnlFiltros.BevelOuter := bvNone;
  CrearEtiqueta(SCaptionLotesAlmacen, 12, 16);
  cbbAlmacen := CrearCombo(80, 12, 260, []);
  CrearBoton(SCaptionLotesRefrescar, 670, 10, 110, FiltroCambiado);
  CrearBoton(SCaptionLotesExcel, 790, 10, 80, btnExcelClick);
  CrearBoton(SCaptionLotesImprimir, 880, 10, 100, btnImprimirClick);
  CrearFiltrosLotes;
  FRetirar := CrearBoton(SBotonRetirarLotes, 12, 90, 160, RetirarClick);
  FHistorico := CrearBoton(SBotonHistoricoRetirada, 184, 90, 170,
    HistoricoClick);
end;

procedure TfrmMtoLotesCaducidades.CrearFiltrosLotes;
begin
  CrearEtiqueta(SCaptionLotesFiltro, 12, 54);
  cbbFiltro := CrearCombo(80, 50, 220, [SCaptionLotesFiltroProximos,
    SCaptionLotesFiltroCaducados, SCaptionLotesFiltroTodo]);
  CrearEtiqueta(SCaptionLotesDias, 320, 54);
  spnDias := TcxSpinEdit.Create(Self);
  spnDias.Parent := pnlFiltros;
  spnDias.Left := EscalarDpi(390);
  spnDias.Top := EscalarDpi(50);
  spnDias.Width := EscalarDpi(70);
  spnDias.Properties.MinValue := 0;
  spnDias.Properties.MaxValue := 3650;
  spnDias.Hint := SHintLotesDias;
  spnDias.ShowHint := True;
  CrearEtiqueta(SCaptionLotesTipo, 480, 54);
  cbbTipo := CrearCombo(530, 50, 140, [SCaptionLotesTipoTodos,
    SCaptionLotesTipoLotes, SCaptionLotesTipoSeries]);
  CrearEtiqueta(SCaptionLotesArticulo, 690, 54);
  edtArticulo := TcxTextEdit.Create(Self);
  edtArticulo.Parent := pnlFiltros;
  edtArticulo.Left := EscalarDpi(760);
  edtArticulo.Top := EscalarDpi(50);
  edtArticulo.Width := EscalarDpi(160);
end;

procedure TfrmMtoLotesCaducidades.CargarAlmacenes;
var
  Almacen: TAlmacenDestinoTraspaso;
begin
  FCodigosAlmacen := [''];
  cbbAlmacen.Properties.Items.Clear;
  cbbAlmacen.Properties.Items.Add(SCaptionLotesTodosAlmacenes);
  for Almacen in dmmLotes.ListarAlmacenes do
  begin
    FCodigosAlmacen := FCodigosAlmacen + [Almacen.Codigo];
    cbbAlmacen.Properties.Items.Add(Almacen.Codigo + ' - ' + Almacen.Nombre);
  end;
  cbbAlmacen.ItemIndex := 0;
end;

function TfrmMtoLotesCaducidades.CrearColumna(AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmMtoLotesCaducidades.FormatoFecha(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxDateEditProperties;
  TcxDateEditProperties(AColumna.Properties).DisplayFormat := FORMATO_FECHA;
end;

procedure TfrmMtoLotesCaducidades.FormatoNumero(AColumna: TcxGridDBColumn;
  const AFormato: string);
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat := AFormato;
end;

procedure TfrmMtoLotesCaducidades.CrearColumnasLotes;
var
  v: TcxGridDBTableView;
begin
  v := cxGrdDBTabPrin;
  CrearColumna(v, 'CODIGO_ALM_STK', SCaptionColLotesAlmacen, 70);
  CrearColumna(v, 'CODIGO_ART_SKU', SCaptionColLotesArticulo, 110);
  CrearColumna(v, 'DESCRIPCION_ART', SCaptionColLotesDescripcion, 220);
  CrearColumna(v, 'DESCRIPCION_FAM', SCaptionColLotesFamilia, 130);
  CrearColumna(v, 'CODIGO_UNIDAD_STK', SCaptionColLotesSku, 140);
  CrearColumna(v, 'LOTE_STK', SCaptionColLotesLote, 150);
  CrearColumna(v, 'TIPO_LOT', SCaptionColLotesTipo, 45);
  FormatoFecha(CrearColumna(v, 'FECHA_CADUCIDAD',
    SCaptionColLotesCaducidad, 90));
  CrearColumna(v, 'DIAS_PARA_CADUCAR', SCaptionColLotesDias, 55);
  CrearColumna(v, 'ESCADUCADO', SCaptionColLotesCaducado, 70);
  FormatoNumero(CrearColumna(v, 'CANTIDAD_STK', SCaptionColLotesCantidad,
    80), FORMATO_UNIDADES);
  FormatoFecha(CrearColumna(v, 'FECHA_ENTRADA_LOT',
    SCaptionColLotesEntrada, 90));
  CrearColumna(v, 'DIAS_DESDE_ENTRADA', SCaptionColLotesAntiguedad, 80);
  CrearColumna(v, 'NOMBRE_PRV', SCaptionColLotesProveedor, 160);
  FormatoNumero(CrearColumna(v, 'VALOR_TOTAL_STK', SCaptionColLotesValor,
    90), FORMATO_IMPORTE);
end;

procedure TfrmMtoLotesCaducidades.CrearTablaPrincipal;
begin
  inherited;
  dmmLotes := tdmDataModule as TdmLotesConsultas;
  pkFieldName := 'CODIGO_UNIDAD_STK';
  cxGrdDBTabPrin.OptionsSelection.MultiSelect := True;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  tsFicha.TabVisible := False;
  nvNavegador.Visible := False;
  if cxGrdDBTabPrin.ColumnCount = 0 then
    CrearColumnasLotes;
  spnDias.Value := DiasAvisoDefecto;
  CargarAlmacenes;
  cbbAlmacen.Properties.OnChange := FiltroCambiado;
  cbbFiltro.Properties.OnChange := FiltroCambiado;
  cbbTipo.Properties.OnChange := FiltroCambiado;
  // La primera carga (TfrmMtoGen) usa lo que se ve: con el filtro de
  // próximos, los días del parámetro y no 0 (FZ-ISSUE-280).
  if not dmmLotes.unqryTablaG.Active then
    dmmLotes.PrepararFiltros(FiltrosActuales);
end;

procedure TfrmMtoLotesCaducidades.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

function TfrmMtoLotesCaducidades.DiasAvisoDefecto: Integer;
begin
  Result := CADUCIDAD_DIAS_AVISO_DEFECTO;
  if Assigned(ParametrosApp) then
    Result := ParametrosApp.GetInt(PARAMETRO_CADUCIDAD_DIAS_AVISO,
      CADUCIDAD_DIAS_AVISO_DEFECTO);
end;

function TfrmMtoLotesCaducidades.CodigoAlmacen: string;
begin
  Result := '';
  if (cbbAlmacen.ItemIndex >= 0) and
     (cbbAlmacen.ItemIndex <= High(FCodigosAlmacen)) then
    Result := FCodigosAlmacen[cbbAlmacen.ItemIndex];
end;

function TfrmMtoLotesCaducidades.CodigoFiltro: string;
begin
  Result := FILTRO_LOTES_TODO;
  if cbbFiltro.ItemIndex in [0..High(CODIGOS_FILTRO)] then
    Result := CODIGOS_FILTRO[cbbFiltro.ItemIndex];
end;

function TfrmMtoLotesCaducidades.CodigoTipo: string;
begin
  Result := '';
  if cbbTipo.ItemIndex in [0..High(CODIGOS_TIPO)] then
    Result := CODIGOS_TIPO[cbbTipo.ItemIndex];
end;

function TfrmMtoLotesCaducidades.FiltrosActuales: TFiltrosLotes;
begin
  Result.Almacen := CodigoAlmacen;
  Result.Articulo := Trim(edtArticulo.Text);
  Result.TipoLote := CodigoTipo;
  Result.Filtro := CodigoFiltro;
  Result.Dias := spnDias.Value;
  Result.DiasDefecto := DiasAvisoDefecto;
end;

procedure TfrmMtoLotesCaducidades.AplicarFiltros;
begin
  dmmLotes.AplicarFiltros(FiltrosActuales);
end;

procedure TfrmMtoLotesCaducidades.FiltroCambiado(Sender: TObject);
begin
  if Assigned(dmmLotes) then
    AplicarFiltros;
end;

procedure TfrmMtoLotesCaducidades.FiltrarArticulo(const AArticulo: string);
begin
  edtArticulo.Text := AArticulo;
  cbbFiltro.ItemIndex := High(CODIGOS_FILTRO);
  FiltroCambiado(nil);
end;

procedure TfrmMtoLotesCaducidades.btnExcelClick(Sender: TObject);
var
  sNombre: string;
begin
  sNombre := SNombreArchivoLotes;
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxGrdPrincipal,
      Format(sNombre, [FormatDateTime('yyyymmdd', Date)]));
end;

// Pares título / valor de los filtros para el resumen del informe.
function TfrmMtoLotesCaducidades.Selecciones: TArray<string>;
begin
  Result := [SCaptionLotesAlmacen, cbbAlmacen.Text,
    SCaptionLotesFiltro, cbbFiltro.Text,
    SCaptionLotesTipo, cbbTipo.Text];
  if spnDias.Value > 0 then
    Result := Result + [SCaptionLotesDias, IntToStr(spnDias.Value)];
  if Trim(edtArticulo.Text) <> '' then
    Result := Result + [SCaptionLotesArticulo, Trim(edtArticulo.Text)];
end;

// Informe del stock por lote.
procedure TfrmMtoLotesCaducidades.btnImprimirClick(Sender: TObject);
var
  oInforme: TfrmPrintCaducidades;
begin
  if PuedeImprimir and Assigned(dmmLotes) then
  begin
    oInforme := TfrmPrintCaducidades.CreateInforme(Application, dmmLotes,
      FiltrosActuales, Selecciones);
    try
      oInforme.ShowModal;
    finally
      FreeAndNil(oInforme);
    end;
  end;
end;

function TfrmMtoLotesCaducidades.LineaRegistro(
  ARegistro: TcxCustomGridRecord): TLineaRetiradaLote;
begin
  Result := Default(TLineaRetiradaLote);
  Result.CodigoSku := VarToStr(ARegistro.Values[
    cxGrdDBTabPrin.GetColumnByFieldName('CODIGO_UNIDAD_STK').Index]);
  Result.CodigoAlmacen := VarToStr(ARegistro.Values[
    cxGrdDBTabPrin.GetColumnByFieldName('CODIGO_ALM_STK').Index]);
  Result.Lote := VarToStr(ARegistro.Values[
    cxGrdDBTabPrin.GetColumnByFieldName('LOTE_STK').Index]);
  Result.Cantidad := ARegistro.Values[
    cxGrdDBTabPrin.GetColumnByFieldName('CANTIDAD_STK').Index];
end;

procedure TfrmMtoLotesCaducidades.RetirarClick(Sender: TObject);
var
  Orden: TOrdenRetiradaLotes;
  Indice: Integer;
begin
  if PuedeAccionMto(apmModificar) then
  begin
    Orden := Default(TOrdenRetiradaLotes);
    Orden.Empresa := UbicacionSesion.Empresa;
    Orden.Usuario := IdentidadSesion.Usuario;
    Orden.Empleado := Orden.Usuario;
    Orden.EsUrgente := True;
    for Indice := 0 to cxGrdDBTabPrin.Controller.SelectedRecordCount - 1 do
      Orden.Lineas := Orden.Lineas + [LineaRegistro(
        cxGrdDBTabPrin.Controller.SelectedRecords[Indice])];
    if (Length(Orden.Lineas) = 0) and
       Assigned(cxGrdDBTabPrin.Controller.FocusedRecord) then
      Orden.Lineas := [LineaRegistro(
        cxGrdDBTabPrin.Controller.FocusedRecord)];
    if TfrmModalRetiradaLotes.Ejecutar(Self, ConexionPrincipal, Orden) then
      AplicarFiltros;
  end;
end;

procedure TfrmMtoLotesCaducidades.HistoricoClick(Sender: TObject);
var
  Linea: TLineaRetiradaLote;
begin
  if PuedeAccionMto(apmConsultar) and
     Assigned(cxGrdDBTabPrin.Controller.FocusedRecord) then
  begin
    Linea := LineaRegistro(cxGrdDBTabPrin.Controller.FocusedRecord);
    TfrmModalHistoricoLote.Ejecutar(Self,
      CrearRepositorioLotesUniDAC(ConexionPrincipal),
      Linea.CodigoSku, Linea.Lote,
      procedure(AMovimiento: string)
      begin
        if PuedeImprimir then
          TfrmModalRetiradaLotes.Reimprimir(Self, ConexionPrincipal,
            UbicacionSesion.Empresa, AMovimiento);
      end);
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoLotesCaducidades);
  ForceReferenceToClass(TfrmMtoLotesCaducidades);
end.
