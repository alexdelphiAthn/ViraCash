{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalRevalorizacionInventario                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Simula la apreciación o depreciación porcentual del PMP de las líneas     }
{    seleccionadas sin modificar el inventario hasta confirmar.                }
{******************************************************************************}
unit inMtoModalRevalorizacionInventario;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  Data.DB,
  Datasnap.DBClient,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtons,
  cxCheckBox,
  cxContainer,
  cxControls,
  cxCurrencyEdit,
  cxEdit,
  cxGrid,
  cxGridCustomTableView,
  cxGridCustomView,
  cxGridDBTableView,
  cxGridLevel,
  cxGridTableView,
  cxLabel,
  cxRadioGroup,
  inLibInventariosRevalorizacion,
  inLibMargenVinculadas,
  inLibInformeSimulacionValoracion,
  inMtoFrmBase;

type
  TResultadoRevalorizacionInventario = record
    Aceptado: Boolean;
    Simulacion: TSimulacionRevalorizacionInventario;
  end;

  // Textos y comportamiento opcionales para reutilizar el modal fuera de
  // inventarios (traspasos). Los campos vacíos conservan los textos de
  // inventarios.
  TOpcionesRevalorizacionInventario = record
    Titulo: string;
    Explicacion: string;
    CaptionAceptar: string;
    CaptionUnidades: string;
    CaptionPrecioActual: string;
    CaptionPrecioSimulado: string;
    // Título y cabecera de la columna PMP del listado impreso.
    TituloInforme: string;
    CaptionPrecioMedioInforme: string;
    OcultarUnidadesFinales: Boolean;
    PreseleccionarTodas: Boolean;
    // Margen minimo exigible sobre el coste al facturar a una empresa
    // vinculada: se teclea aqui, al facturar, y solo avisa.
    MostrarMargenMinimo: Boolean;
    // Porcentaje que se propone en el campo del modal: a 0 manda la escala
    // por antigüedad.
    MargenMinimo: Currency;
    EscalaMargenMinimo: TEscalaMargenMinimo;
    // El resultado se factura: cada línea se redondea a céntimos antes de
    // sumar, para que el total simulado sea el de la factura.
    ImportesACentimos: Boolean;
  end;

  TfrmModalRevalorizacionInventario = class(TfrmBase)
    pnlConfiguracion: TPanel;
    lblExplicacion: TcxLabel;
    lblInventario: TcxLabel;
    rgTipo: TcxRadioGroup;
    lblPorcentaje: TcxLabel;
    curPorcentaje: TcxCurrencyEdit;
    lblMargenMinimo: TcxLabel;
    curMargenMinimo: TcxCurrencyEdit;
    chkCosteYaDevaluado: TcxCheckBox;
    rgBase: TcxRadioGroup;
    btnSimular: TcxButton;
    btnSeleccionarTodo: TcxButton;
    btnSeleccionarNinguno: TcxButton;
    cxgrdSimulacion: TcxGrid;
    tvSimulacion: TcxGridDBTableView;
    cxgrdlvlSimulacion: TcxGridLevel;
    pnlResumen: TPanel;
    lblNumeroLineas: TcxLabel;
    lblTotalAnterior: TcxLabel;
    curTotalAnterior: TcxCurrencyEdit;
    lblTotalSimulado: TcxLabel;
    curTotalSimulado: TcxCurrencyEdit;
    lblTotalDiferencia: TcxLabel;
    curTotalDiferencia: TcxCurrencyEdit;
    lblAvisos: TcxLabel;
    pnlBotones: TPanel;
    btnCancelar: TcxButton;
    btnImprimir: TcxButton;
    btnPreparar: TcxButton;
    cdsSimulacion: TClientDataSet;
    dsSimulacion: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure btnSimularClick(Sender: TObject);
    procedure btnSeleccionarTodoClick(Sender: TObject);
    procedure btnSeleccionarNingunoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnPrepararClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure ConfiguracionPropertiesChange(Sender: TObject);
    procedure cdsSimulacionAfterPost(DataSet: TDataSet);
  private
    FActualizando: Boolean;
    FLineasLimitadasPorVenta: Integer;
    FColumnaIndiceBase: TcxGridDBColumn;
    FColumnaUnidadesAnteriores: TcxGridDBColumn;
    FColumnaUnidadesFinales: TcxGridDBColumn;
    FColumnaAntiguedad: TcxGridDBColumn;
    FColumnaMargenMinimo: TcxGridDBColumn;
    FColumnaPrecioVenta: TcxGridDBColumn;
    FColumnaAvisoVenta: TcxGridDBColumn;
    FColumnaPrecioAnterior: TcxGridDBColumn;
    FColumnaPrecioSimulado: TcxGridDBColumn;
    FOpciones: TOpcionesRevalorizacionInventario;
    FLineasBase: TLineasBaseRevalorizacionInventario;
    FResultado: TResultadoRevalorizacionInventario;
    FUltimaSimulacion: TSimulacionRevalorizacionInventario;
    procedure AplicarTextos;
    procedure AplicarOpciones;
    procedure CrearEstructura;
    procedure CrearColumnas;
    procedure CargarLineas;
    procedure MarcarLineas(AMarcar: Boolean);
    function ObtenerLineasVisibles: TArray<Boolean>;
    procedure LimpiarCamposCalculados;
    procedure LimpiarResumen;
    procedure InvalidarSimulacion;
    function TipoSeleccionado: TTipoRevalorizacionInventario;
    function BaseSeleccionada: TBaseRevalorizacionInventario;
    function TextoOperacion(
      const ASimulacion: TSimulacionRevalorizacionInventario): string;
    function DatosInforme: TDatosInformeSimulacionValoracion;
    function RecogerLineasSeleccionadas:
      TLineasBaseRevalorizacionInventario;
    function CalcularSimulacion: Boolean;
    procedure MostrarSimulacion(
      const ASimulacion: TSimulacionRevalorizacionInventario);
    function HayPreciosDeVenta: Boolean;
    function TextoAvisoVenta(
      const ALinea: TLineaBaseRevalorizacionInventario): string;
    function HayAvisosVenta: Boolean;
    procedure AnadirAvisosVenta(AAvisos: TStrings);
    function CosteYaDevaluado: Boolean;
    function MargenMinimoExigido: Currency;
    function TextoMargenMinimo: string;
    procedure ActualizarMargenesMinimos;
    function ConfirmarMargenMinimo: Boolean;
    procedure MostrarResumen(
      const AResumen: TResumenSimulacionRevalorizacionInventario);
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ALineas: TLineasBaseRevalorizacionInventario;
      const AIdentificacionInventario: string):
      TResultadoRevalorizacionInventario; overload;
    class function Ejecutar(
      AOwner: TComponent;
      const ALineas: TLineasBaseRevalorizacionInventario;
      const AIdentificacionInventario: string;
      const AOpciones: TOpcionesRevalorizacionInventario):
      TResultadoRevalorizacionInventario; overload;
  end;

implementation

uses
  inLibMensajesVcl,
  Vcl.Dialogs,
  Vcl.Graphics,
  cxClasses,
  cxData,
  cxDataStorage,
  cxDBData,
  cxGraphics,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxStyles,
  inLibMsgArticulos,
  inLibMsgComun,
  inMtoModalImpSimulacionValoracion;

{$R *.dfm}

const
  CAMPO_APLICAR = 'APLICAR';
  CAMPO_INDICE_BASE = 'INDICE_BASE';
  CAMPO_LINEA = 'LINEA';
  CAMPO_ARTICULO = 'ARTICULO';
  CAMPO_SKU = 'SKU';
  CAMPO_DESCRIPCION = 'DESCRIPCION';
  CAMPO_CANTIDAD_TEORICA = 'CANTIDAD_TEORICA';
  CAMPO_CANTIDAD_FISICA = 'CANTIDAD_FISICA';
  CAMPO_ANTIGUEDAD = 'ANTIGUEDAD';
  CAMPO_MARGEN_MINIMO = 'MARGEN_MINIMO';
  CAMPO_PRECIO_VENTA = 'PRECIO_VENTA';
  CAMPO_AVISO_VENTA = 'AVISO_VENTA';
  CAMPO_PMP_ANTERIOR = 'PMP_ANTERIOR';
  CAMPO_PMP_SIMULADO = 'PMP_SIMULADO';
  CAMPO_VALOR_ANTERIOR = 'VALOR_ANTERIOR';
  CAMPO_VALOR_SIMULADO = 'VALOR_SIMULADO';
  CAMPO_DIFERENCIA = 'DIFERENCIA';

class function TfrmModalRevalorizacionInventario.Ejecutar(
  AOwner: TComponent;
  const ALineas: TLineasBaseRevalorizacionInventario;
  const AIdentificacionInventario: string):
  TResultadoRevalorizacionInventario;
begin
  Result := Ejecutar(
    AOwner,
    ALineas,
    AIdentificacionInventario,
    Default(TOpcionesRevalorizacionInventario));
end;

class function TfrmModalRevalorizacionInventario.Ejecutar(
  AOwner: TComponent;
  const ALineas: TLineasBaseRevalorizacionInventario;
  const AIdentificacionInventario: string;
  const AOpciones: TOpcionesRevalorizacionInventario):
  TResultadoRevalorizacionInventario;
var
  Formulario: TfrmModalRevalorizacionInventario;
begin
  Result := Default(TResultadoRevalorizacionInventario);
  Formulario := TfrmModalRevalorizacionInventario.Create(AOwner);
  try
    Formulario.FOpciones := AOpciones;
    Formulario.AplicarOpciones;
    Formulario.FLineasBase := Copy(ALineas, 0, Length(ALineas));
    Formulario.lblInventario.Caption := AIdentificacionInventario;
    Formulario.CargarLineas;
    Formulario.ShowModal;
    Result := Formulario.FResultado;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalRevalorizacionInventario.FormCreate(Sender: TObject);
begin
  inherited;
  FActualizando := False;
  FResultado := Default(TResultadoRevalorizacionInventario);
  FUltimaSimulacion := Default(TSimulacionRevalorizacionInventario);
  AplicarTextos;
  CrearEstructura;
  CrearColumnas;
  rgTipo.ItemIndex := 0;
  rgBase.ItemIndex := 0;
  curPorcentaje.Value := 10;
  InvalidarSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.AplicarTextos;
begin
  Caption := STituloRevalorizacionInventario;
  lblExplicacion.Caption := STextoRevalorizacionInventario;
  rgTipo.Caption := SCaptionOperacionRevalorizacionInventario;
  rgTipo.Properties.Items[0].Caption := SCaptionApreciarInventario;
  rgTipo.Properties.Items[1].Caption := SCaptionDepreciarInventario;
  lblPorcentaje.Caption := SCaptionPorcentajeRevalorizacionInventario;
  btnSimular.Caption := SCaptionSimularRevalorizacionInventario;
  btnSeleccionarTodo.Caption :=
    SCaptionSeleccionarTodoRevalorizacionInventario;
  btnSeleccionarNinguno.Caption :=
    SCaptionSeleccionarNingunoRevalorizacionInventario;
  btnPreparar.Caption := SCaptionPrepararPmpRevalorizacionInventario;
  btnCancelar.Caption := SCaptionCancelarEsc;
  rgBase.Caption := SCaptionBaseRevalorizacionInventario;
  rgBase.Properties.Items[0].Caption :=
    SCaptionBasePrecioMedioRevalorizacionInventario;
  rgBase.Properties.Items[1].Caption :=
    SCaptionBaseUltimaCompraRevalorizacionInventario;
  btnImprimir.Caption := SCaptionImprimirRevalorizacionInventario;
  lblTotalAnterior.Caption :=
    SCaptionTotalAnteriorRevalorizacionInventario;
  lblTotalSimulado.Caption :=
    SCaptionTotalSimuladoRevalorizacionInventario;
  lblTotalDiferencia.Caption :=
    SCaptionTotalDiferenciaRevalorizacionInventario;
end;

procedure TfrmModalRevalorizacionInventario.CrearEstructura;
begin
  cdsSimulacion.Close;
  cdsSimulacion.FieldDefs.Clear;
  cdsSimulacion.FieldDefs.Add(CAMPO_APLICAR, ftBoolean);
  cdsSimulacion.FieldDefs.Add(CAMPO_INDICE_BASE, ftInteger);
  cdsSimulacion.FieldDefs.Add(CAMPO_LINEA, ftWideString, 30);
  cdsSimulacion.FieldDefs.Add(CAMPO_ARTICULO, ftWideString, 50);
  cdsSimulacion.FieldDefs.Add(CAMPO_SKU, ftWideString, 100);
  cdsSimulacion.FieldDefs.Add(CAMPO_DESCRIPCION, ftWideString, 250);
  cdsSimulacion.FieldDefs.Add(CAMPO_CANTIDAD_TEORICA, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_CANTIDAD_FISICA, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_ANTIGUEDAD, ftInteger);
  cdsSimulacion.FieldDefs.Add(CAMPO_MARGEN_MINIMO, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_PRECIO_VENTA, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_AVISO_VENTA, ftWideString, 60);
  cdsSimulacion.FieldDefs.Add(CAMPO_PMP_ANTERIOR, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_PMP_SIMULADO, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_VALOR_ANTERIOR, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_VALOR_SIMULADO, ftCurrency);
  cdsSimulacion.FieldDefs.Add(CAMPO_DIFERENCIA, ftCurrency);
  cdsSimulacion.CreateDataSet;
end;

procedure ConfigurarColumnaMonetaria(
  AColumna: TcxGridDBColumn;
  const AFormato: string);
var
  Propiedades: TcxCurrencyEditProperties;
begin
  AColumna.PropertiesClass := TcxCurrencyEditProperties;
  Propiedades := TcxCurrencyEditProperties(AColumna.Properties);
  Propiedades.DisplayFormat := AFormato;
  Propiedades.ReadOnly := True;
end;

function CrearColumna(
  AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string;
  AAncho: Integer;
  AEditable: Boolean): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := AAncho;
  Result.Options.Editing := AEditable;
end;

procedure TfrmModalRevalorizacionInventario.CrearColumnas;
var
  Columna: TcxGridDBColumn;
  PropiedadesCheck: TcxCheckBoxProperties;
begin
  tvSimulacion.ClearItems;
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_APLICAR,
    SCaptionColAplicarRevalorizacionInventario,
    65,
    True);
  Columna.PropertiesClass := TcxCheckBoxProperties;
  PropiedadesCheck := TcxCheckBoxProperties(Columna.Properties);
  PropiedadesCheck.ValueChecked := True;
  PropiedadesCheck.ValueUnchecked := False;
  FColumnaIndiceBase := CrearColumna(
    tvSimulacion,
    CAMPO_INDICE_BASE,
    '',
    0,
    False);
  FColumnaIndiceBase.Visible := False;
  CrearColumna(
    tvSimulacion,
    CAMPO_LINEA,
    SCaptionColLineaRevalorizacionInventario,
    65,
    False);
  CrearColumna(
    tvSimulacion,
    CAMPO_ARTICULO,
    SCaptionColArticulo,
    110,
    False);
  CrearColumna(
    tvSimulacion,
    CAMPO_SKU,
    SCaptionColSku,
    145,
    False);
  CrearColumna(
    tvSimulacion,
    CAMPO_DESCRIPCION,
    SCaptionColDescripcion,
    220,
    False);
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_CANTIDAD_TEORICA,
    SCaptionColCantidadTeoricaRevalorizacionInventario,
    95,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.####');
  FColumnaUnidadesAnteriores := Columna;
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_CANTIDAD_FISICA,
    SCaptionColCantidadFisicaRevalorizacionInventario,
    95,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.####');
  FColumnaUnidadesFinales := Columna;
  FColumnaAntiguedad := CrearColumna(
    tvSimulacion,
    CAMPO_ANTIGUEDAD,
    SCaptionColAntiguedadRevalorizacion,
    95,
    False);
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_PMP_ANTERIOR,
    SCaptionColPmpAnteriorRevalorizacionInventario,
    95,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.0000');
  FColumnaPrecioAnterior := Columna;
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_MARGEN_MINIMO,
    SCaptionColMargenMinimoRevalorizacion,
    90,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.## %');
  FColumnaMargenMinimo := Columna;
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_PRECIO_VENTA,
    SCaptionColPrecioVentaDestinoRevalorizacion,
    100,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.0000');
  FColumnaPrecioVenta := Columna;
  FColumnaAvisoVenta := CrearColumna(
    tvSimulacion,
    CAMPO_AVISO_VENTA,
    SCaptionColAvisoVentaDestinoRevalorizacion,
    150,
    False);
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_PMP_SIMULADO,
    SCaptionColPmpSimuladoRevalorizacionInventario,
    100,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.0000');
  FColumnaPrecioSimulado := Columna;
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_VALOR_ANTERIOR,
    SCaptionColValorAnteriorRevalorizacionInventario,
    105,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.00 €;-#,##0.00 €');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_VALOR_SIMULADO,
    SCaptionColValorSimuladoRevalorizacionInventario,
    105,
    False);
  ConfigurarColumnaMonetaria(Columna, '#,##0.00 €;-#,##0.00 €');
  Columna := CrearColumna(
    tvSimulacion,
    CAMPO_DIFERENCIA,
    SCaptionColDiferenciaRevalorizacionInventario,
    105,
    False);
  ConfigurarColumnaMonetaria(Columna, '+#,##0.00 €;-#,##0.00 €');
end;

procedure TfrmModalRevalorizacionInventario.CargarLineas;
var
  iLinea: Integer;
begin
  FActualizando := True;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.EmptyDataSet;
    for iLinea := 0 to High(FLineasBase) do
    begin
      cdsSimulacion.Append;
      cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean :=
        FOpciones.PreseleccionarTodas;
      cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger := iLinea;
      cdsSimulacion.FieldByName(CAMPO_LINEA).AsString :=
        FLineasBase[iLinea].Linea;
      cdsSimulacion.FieldByName(CAMPO_ARTICULO).AsString :=
        FLineasBase[iLinea].CodigoArticulo;
      cdsSimulacion.FieldByName(CAMPO_SKU).AsString :=
        FLineasBase[iLinea].CodigoUnidad;
      cdsSimulacion.FieldByName(CAMPO_DESCRIPCION).AsString :=
        FLineasBase[iLinea].Descripcion;
      cdsSimulacion.FieldByName(CAMPO_CANTIDAD_TEORICA).AsCurrency :=
        FLineasBase[iLinea].CantidadTeorica;
      cdsSimulacion.FieldByName(CAMPO_CANTIDAD_FISICA).AsCurrency :=
        FLineasBase[iLinea].CantidadFisica;
      cdsSimulacion.FieldByName(CAMPO_ANTIGUEDAD).AsInteger :=
        FLineasBase[iLinea].AntiguedadMeses;
      cdsSimulacion.FieldByName(CAMPO_MARGEN_MINIMO).AsCurrency :=
        MargenMinimoLinea(
          FOpciones.EscalaMargenMinimo,
          AntiguedadAplicable(
            FLineasBase[iLinea].AntiguedadMeses, CosteYaDevaluado),
          FOpciones.MargenMinimo);
      cdsSimulacion.FieldByName(CAMPO_PRECIO_VENTA).AsCurrency :=
        FLineasBase[iLinea].PrecioVentaDestino;
      cdsSimulacion.FieldByName(CAMPO_AVISO_VENTA).AsString :=
        TextoAvisoVenta(FLineasBase[iLinea]);
      cdsSimulacion.FieldByName(CAMPO_PMP_ANTERIOR).AsCurrency :=
        FLineasBase[iLinea].PrecioMedioActual;
      cdsSimulacion.Post;
    end;
    cdsSimulacion.First;
  finally
    cdsSimulacion.EnableControls;
    FActualizando := False;
  end;
  InvalidarSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.MarcarLineas(
  AMarcar: Boolean);
var
  EsLineaVisible: TArray<Boolean>;
  IndiceBase: Integer;
  DebeMarcar: Boolean;
begin
  if AMarcar then
    EsLineaVisible := ObtenerLineasVisibles;
  FActualizando := True;
  cdsSimulacion.DisableControls;
  try
    if cdsSimulacion.State in [dsEdit, dsInsert] then
      cdsSimulacion.Post;
    cdsSimulacion.First;
    while not cdsSimulacion.Eof do
    begin
      IndiceBase :=
        cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger;
      DebeMarcar := False;
      if AMarcar then
        DebeMarcar :=
          (IndiceBase >= 0) and
          (IndiceBase < Length(EsLineaVisible)) and
          EsLineaVisible[IndiceBase];
      if cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean <>
         DebeMarcar then
      begin
        cdsSimulacion.Edit;
        cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean := DebeMarcar;
        cdsSimulacion.Post;
      end;
      cdsSimulacion.Next;
    end;
    cdsSimulacion.First;
  finally
    cdsSimulacion.EnableControls;
    FActualizando := False;
  end;
  InvalidarSimulacion;
end;

function TfrmModalRevalorizacionInventario.ObtenerLineasVisibles:
  TArray<Boolean>;
var
  iFila: Integer;
  iIndiceBase: Integer;
  iRegistro: Integer;
begin
  SetLength(Result, Length(FLineasBase));
  for iFila := 0 to tvSimulacion.DataController.FilteredRecordCount - 1 do
  begin
    iRegistro :=
      tvSimulacion.DataController.FilteredRecordIndex[iFila];
    iIndiceBase := tvSimulacion.DataController.Values[
      iRegistro, FColumnaIndiceBase.Index];
    if (iIndiceBase >= 0) and (iIndiceBase < Length(Result)) then
      Result[iIndiceBase] := True;
  end;
end;

procedure TfrmModalRevalorizacionInventario.LimpiarCamposCalculados;
var
  EsMarcadorValido: Boolean;
  Marcador: TBookmark;
begin
  EsMarcadorValido := not cdsSimulacion.IsEmpty;
  if EsMarcadorValido then
    Marcador := cdsSimulacion.GetBookmark;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.First;
    while not cdsSimulacion.Eof do
    begin
      if not cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).IsNull or
         not cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).IsNull or
         not cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).IsNull or
         not cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).IsNull then
      begin
        cdsSimulacion.Edit;
        cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).Clear;
        cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).Clear;
        cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).Clear;
        cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).Clear;
        cdsSimulacion.Post;
      end;
      cdsSimulacion.Next;
    end;
  finally
    if EsMarcadorValido then
    begin
      if cdsSimulacion.BookmarkValid(Marcador) then
        cdsSimulacion.GotoBookmark(Marcador);
      cdsSimulacion.FreeBookmark(Marcador);
    end;
    cdsSimulacion.EnableControls;
  end;
end;

procedure TfrmModalRevalorizacionInventario.LimpiarResumen;
begin
  lblNumeroLineas.Caption := Format(
    SFormatoLineasRevalorizacionInventario,
    [0]);
  curTotalAnterior.EditValue := Null;
  curTotalSimulado.EditValue := Null;
  curTotalDiferencia.EditValue := Null;
end;

procedure TfrmModalRevalorizacionInventario.InvalidarSimulacion;
begin
  if not FActualizando then
  begin
    FActualizando := True;
    try
      LimpiarCamposCalculados;
      LimpiarResumen;
      FUltimaSimulacion :=
        Default(TSimulacionRevalorizacionInventario);
      btnPreparar.Enabled := False;
      btnImprimir.Enabled := False;
      lblAvisos.Style.Font.Color := clWindowText;
      lblAvisos.Caption :=
        SInfoSimulacionPendienteRevalorizacionInventario;
    finally
      FActualizando := False;
    end;
  end;
end;

function TfrmModalRevalorizacionInventario.TipoSeleccionado:
  TTipoRevalorizacionInventario;
begin
  Result := triApreciacion;
  if rgTipo.ItemIndex = 1 then
    Result := triDepreciacion;
end;

function TfrmModalRevalorizacionInventario.RecogerLineasSeleccionadas:
  TLineasBaseRevalorizacionInventario;
var
  IndiceBase: Integer;
  NumeroSeleccionadas: Integer;
begin
  SetLength(Result, Length(FLineasBase));
  if cdsSimulacion.State in [dsEdit, dsInsert] then
    cdsSimulacion.Post;
  NumeroSeleccionadas := 0;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.First;
    while not cdsSimulacion.Eof do
    begin
      if cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean then
      begin
        IndiceBase :=
          cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger;
        Result[NumeroSeleccionadas] := FLineasBase[IndiceBase];
        Inc(NumeroSeleccionadas);
      end;
      cdsSimulacion.Next;
    end;
  finally
    cdsSimulacion.EnableControls;
  end;
  SetLength(Result, NumeroSeleccionadas);
end;

function TfrmModalRevalorizacionInventario.CalcularSimulacion: Boolean;
var
  LineasSeleccionadas: TLineasBaseRevalorizacionInventario;
  Tipo: TTipoRevalorizacionInventario;
  Porcentaje: Currency;
begin
  Result := False;
  Tipo := TipoSeleccionado;
  Porcentaje := curPorcentaje.Value;
  if not PorcentajeRevalorizacionValido(Tipo, Porcentaje) then
    ShowMessage_fza(SErrorPorcentajeRevalorizacionInventario)
  else
  begin
    LineasSeleccionadas := RecogerLineasSeleccionadas;
    if Length(LineasSeleccionadas) = 0 then
      ShowMessage_fza(SErrorSeleccionRevalorizacionInventario)
    else
    begin
      FUltimaSimulacion := SimularRevalorizacionInventario(
        LineasSeleccionadas,
        Tipo,
        Porcentaje,
        BaseSeleccionada);
      FLineasLimitadasPorVenta := 0;
      if FOpciones.MostrarMargenMinimo then
      begin
        // El recuento se hace antes de ajustar: despues ya no hay ninguna
        // por encima de su precio de venta.
        FLineasLimitadasPorVenta :=
          ContarLineasLimitadasPorVenta(FUltimaSimulacion);
        FUltimaSimulacion := AplicarTopeVentaSimulacion(FUltimaSimulacion);
      end;
      if FOpciones.ImportesACentimos then
        FUltimaSimulacion :=
          RedondearImportesSimulacionACentimos(FUltimaSimulacion);
      MostrarSimulacion(FUltimaSimulacion);
      btnPreparar.Enabled := True;
      btnImprimir.Enabled := True;
      // Sin precio base el porcentaje no hace nada: se avisa ademas
      // del resumen, porque el listado lo da por simulado a 0.
      if FUltimaSimulacion.Resumen.LineasSinPrecioBase > 0 then
        ShowMessage_fza(Format(
          SAvisoSinPrecioBaseRevalorizacionInventario,
          [FUltimaSimulacion.Resumen.LineasSinPrecioBase]));
      Result := True;
    end;
  end;
end;

procedure TfrmModalRevalorizacionInventario.MostrarSimulacion(
  const ASimulacion: TSimulacionRevalorizacionInventario);
var
  iLinea: Integer;
begin
  FActualizando := True;
  cdsSimulacion.DisableControls;
  try
    cdsSimulacion.First;
    iLinea := 0;
    while not cdsSimulacion.Eof do
    begin
      cdsSimulacion.Edit;
      cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).Clear;
      cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).Clear;
      cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).Clear;
      cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).Clear;
      if cdsSimulacion.FieldByName(CAMPO_APLICAR).AsBoolean and
         (iLinea < Length(ASimulacion.Lineas)) then
      begin
        cdsSimulacion.FieldByName(CAMPO_PMP_SIMULADO).AsCurrency :=
          ASimulacion.Lineas[iLinea].PrecioMedioNuevo;
        cdsSimulacion.FieldByName(CAMPO_VALOR_ANTERIOR).AsCurrency :=
          ASimulacion.Lineas[iLinea].ValorAnterior;
        cdsSimulacion.FieldByName(CAMPO_VALOR_SIMULADO).AsCurrency :=
          ASimulacion.Lineas[iLinea].ValorNuevo;
        cdsSimulacion.FieldByName(CAMPO_DIFERENCIA).AsCurrency :=
          ASimulacion.Lineas[iLinea].DiferenciaValor;
        Inc(iLinea);
      end;
      cdsSimulacion.Post;
      cdsSimulacion.Next;
    end;
    cdsSimulacion.First;
  finally
    cdsSimulacion.EnableControls;
    FActualizando := False;
  end;
  MostrarResumen(ASimulacion.Resumen);
end;

procedure TfrmModalRevalorizacionInventario.MostrarResumen(
  const AResumen: TResumenSimulacionRevalorizacionInventario);
var
  Avisos: TStringList;
begin
  lblNumeroLineas.Caption := Format(
    SFormatoLineasRevalorizacionInventario,
    [AResumen.NumeroLineas]);
  curTotalAnterior.Value := AResumen.ValorAnterior;
  curTotalSimulado.Value := AResumen.ValorNuevo;
  curTotalDiferencia.Value := AResumen.DiferenciaValor;
  Avisos := TStringList.Create;
  try
    if AResumen.LineasConDiferenciaUnidades > 0 then
      Avisos.Add(Format(
        SAvisoDiferenciasUnidadesRevalorizacionInventario,
        [AResumen.LineasConDiferenciaUnidades]));
    if AResumen.LineasConPrecioCorregido > 0 then
      Avisos.Add(Format(
        SAvisoPmpCorregidosRevalorizacionInventario,
        [AResumen.LineasConPrecioCorregido]));
    if AResumen.LineasSinUltimaCompra > 0 then
      Avisos.Add(Format(
        SAvisoSinUltimaCompraRevalorizacionInventario,
        [AResumen.LineasSinUltimaCompra]));
    if AResumen.LineasSinPrecioBase > 0 then
      Avisos.Add(Format(
        SAvisoSinPrecioBaseRevalorizacionInventario,
        [AResumen.LineasSinPrecioBase]));
    if FLineasLimitadasPorVenta > 0 then
      Avisos.Add(Format(
        SAvisoLineasLimitadasPorVenta,
        [FLineasLimitadasPorVenta]));
    AnadirAvisosVenta(Avisos);
    lblAvisos.Style.Font.Color := clMaroon;
    lblAvisos.Caption := Trim(Avisos.Text);
  finally
    FreeAndNil(Avisos);
  end;
end;

procedure TfrmModalRevalorizacionInventario.btnSimularClick(
  Sender: TObject);
begin
  CalcularSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.btnSeleccionarTodoClick(
  Sender: TObject);
begin
  MarcarLineas(True);
end;

procedure TfrmModalRevalorizacionInventario.btnSeleccionarNingunoClick(
  Sender: TObject);
begin
  MarcarLineas(False);
end;

procedure TfrmModalRevalorizacionInventario.btnCancelarClick(
  Sender: TObject);
begin
  FResultado.Aceptado := False;
  Close;
end;

procedure TfrmModalRevalorizacionInventario.btnPrepararClick(
  Sender: TObject);
begin
  if CalcularSimulacion and ConfirmarMargenMinimo then
  begin
    FResultado.Aceptado := True;
    FResultado.Simulacion := FUltimaSimulacion;
    Close;
  end;
end;

procedure TfrmModalRevalorizacionInventario.ConfiguracionPropertiesChange(
  Sender: TObject);
begin
  if (Sender = curMargenMinimo) or (Sender = chkCosteYaDevaluado) then
    ActualizarMargenesMinimos;
  InvalidarSimulacion;
end;

procedure TfrmModalRevalorizacionInventario.AplicarOpciones;
begin
  if FOpciones.Titulo <> '' then
    Caption := FOpciones.Titulo;
  if FOpciones.Explicacion <> '' then
    lblExplicacion.Caption := FOpciones.Explicacion;
  if FOpciones.CaptionAceptar <> '' then
    btnPreparar.Caption := FOpciones.CaptionAceptar;
  if FOpciones.CaptionUnidades <> '' then
    FColumnaUnidadesAnteriores.Caption := FOpciones.CaptionUnidades;
  if FOpciones.CaptionPrecioActual <> '' then
    FColumnaPrecioAnterior.Caption := FOpciones.CaptionPrecioActual;
  if FOpciones.CaptionPrecioSimulado <> '' then
    FColumnaPrecioSimulado.Caption := FOpciones.CaptionPrecioSimulado;
  FColumnaUnidadesFinales.Visible := not FOpciones.OcultarUnidadesFinales;
  lblMargenMinimo.Visible := FOpciones.MostrarMargenMinimo;
  curMargenMinimo.Visible := FOpciones.MostrarMargenMinimo;
  chkCosteYaDevaluado.Visible := FOpciones.MostrarMargenMinimo;
  chkCosteYaDevaluado.Caption := SCaptionCosteYaDevaluadoRevalorizacion;
  chkCosteYaDevaluado.Hint := SHintCosteYaDevaluadoRevalorizacion;
  chkCosteYaDevaluado.ShowHint := True;
  FColumnaAntiguedad.Visible := FOpciones.MostrarMargenMinimo;
  FColumnaMargenMinimo.Visible := FOpciones.MostrarMargenMinimo;
  FColumnaPrecioVenta.Visible := HayPreciosDeVenta;
  FColumnaAvisoVenta.Visible := HayAvisosVenta;
  if FOpciones.MostrarMargenMinimo then
  begin
    lblMargenMinimo.Caption := SCaptionMargenMinimoRevalorizacion;
    curMargenMinimo.Value := FOpciones.MargenMinimo;
    curMargenMinimo.ShowHint := True;
    if Length(FOpciones.EscalaMargenMinimo) > 0 then
      curMargenMinimo.Hint := Format(SHintMargenMinimoRevalorizacion,
        [TextoEscalaMargenMinimo(FOpciones.EscalaMargenMinimo)])
    else
      curMargenMinimo.Hint := SHintMargenMinimoSinTramos;
  end;
end;

function TfrmModalRevalorizacionInventario.HayPreciosDeVenta: Boolean;
var
  iLinea: Integer;
begin
  Result := False;
  for iLinea := 0 to High(FLineasBase) do
  begin
    if FLineasBase[iLinea].PrecioVentaDestino > 0 then
      Result := True;
  end;
end;

// FZ-ISSUE-367: unidades vendidas a 0 € o sin línea de factura. No tienen
// tope de venta y se facturan al precio valorado: se marcan y se avisa.
function TfrmModalRevalorizacionInventario.TextoAvisoVenta(
  const ALinea: TLineaBaseRevalorizacionInventario): string;
begin
  Result := '';
  if ALinea.VentaDestinoACero then
    Result := STextoVentaACeroRevalorizacion;
  if ALinea.VentaDestinoSinLinea then
  begin
    if Result <> '' then
      Result := Result + '; ';
    Result := Result + STextoVentaSinLineaRevalorizacion;
  end;
end;

function TfrmModalRevalorizacionInventario.HayAvisosVenta: Boolean;
var
  iLinea: Integer;
begin
  Result := False;
  for iLinea := 0 to High(FLineasBase) do
  begin
    if TextoAvisoVenta(FLineasBase[iLinea]) <> '' then
      Result := True;
  end;
end;

procedure TfrmModalRevalorizacionInventario.AnadirAvisosVenta(
  AAvisos: TStrings);
var
  iLinea   : Integer;
  iACero   : Integer;
  iSinLinea: Integer;
begin
  iACero := 0;
  iSinLinea := 0;
  for iLinea := 0 to High(FLineasBase) do
  begin
    if FLineasBase[iLinea].VentaDestinoACero then
      Inc(iACero);
    if FLineasBase[iLinea].VentaDestinoSinLinea then
      Inc(iSinLinea);
  end;
  if iACero > 0 then
    AAvisos.Add(Format(SAvisoLineasVentaACeroRevalorizacion, [iACero]));
  if iSinLinea > 0 then
    AAvisos.Add(Format(
      SAvisoLineasVentaSinLineaRevalorizacion, [iSinLinea]));
end;

// Los mínimos de cada línea cambian si se teclea un porcentaje que manda
// sobre los tramos.
procedure TfrmModalRevalorizacionInventario.ActualizarMargenesMinimos;
var
  cMargen: Currency;
  iIndice: Integer;
begin
  if FOpciones.MostrarMargenMinimo and cdsSimulacion.Active then
  begin
    cMargen := MargenMinimoExigido;
    FActualizando := True;
    cdsSimulacion.DisableControls;
    try
      cdsSimulacion.First;
      while not cdsSimulacion.Eof do
      begin
        iIndice := cdsSimulacion.FieldByName(CAMPO_INDICE_BASE).AsInteger;
        cdsSimulacion.Edit;
        cdsSimulacion.FieldByName(CAMPO_MARGEN_MINIMO).AsCurrency :=
          MargenMinimoLinea(
            FOpciones.EscalaMargenMinimo,
            AntiguedadAplicable(
              FLineasBase[iIndice].AntiguedadMeses, CosteYaDevaluado),
            cMargen);
        cdsSimulacion.Post;
        cdsSimulacion.Next;
      end;
      cdsSimulacion.First;
    finally
      cdsSimulacion.EnableControls;
      FActualizando := False;
    end;
  end;
end;

function TfrmModalRevalorizacionInventario.CosteYaDevaluado: Boolean;
begin
  Result := FOpciones.MostrarMargenMinimo and
    chkCosteYaDevaluado.Checked;
end;

function TfrmModalRevalorizacionInventario.MargenMinimoExigido: Currency;
begin
  Result := 0;
  if FOpciones.MostrarMargenMinimo then
    Result := curMargenMinimo.Value;
end;

function TfrmModalRevalorizacionInventario.TextoMargenMinimo: string;
var
  cMargen: Currency;
begin
  cMargen := MargenMinimoExigido;
  if cMargen > 0 then
    Result := Format(STextoMargenMinimoUnico,
      [FormatFloat('0.##', cMargen)])
  else
    Result := Format(STextoMargenMinimoPorTramos,
      [TextoEscalaMargenMinimo(FOpciones.EscalaMargenMinimo)]);
end;

function TfrmModalRevalorizacionInventario.ConfirmarMargenMinimo: Boolean;
var
  iLineas: Integer;
begin
  Result := True;
  iLineas := ContarLineasBajoMargenMinimo(
    FLineasBase,
    FUltimaSimulacion,
    FOpciones.EscalaMargenMinimo,
    MargenMinimoExigido,
    CosteYaDevaluado);
  if iLineas > 0 then
    Result := MessageDlg_fza(
      Format(SAvisoLineasBajoMargenMinimoRevalorizacion,
        [iLineas, TextoMargenMinimo]),
      mtWarning, [mbYes, mbNo], 0) = mrYes;
end;

function TfrmModalRevalorizacionInventario.BaseSeleccionada:
  TBaseRevalorizacionInventario;
begin
  Result := briPrecioMedio;
  if rgBase.ItemIndex = 1 then
    Result := briUltimaCompra;
end;

function TfrmModalRevalorizacionInventario.TextoOperacion(
  const ASimulacion: TSimulacionRevalorizacionInventario): string;
var
  sBase: string;
  sTipo: string;
begin
  if ASimulacion.Tipo = triApreciacion then
    sTipo := SCaptionApreciarInventario
  else
    sTipo := SCaptionDepreciarInventario;
  if ASimulacion.BaseCalculo = briUltimaCompra then
    sBase := SCaptionBaseUltimaCompraRevalorizacionInventario
  else
    sBase := SCaptionBasePrecioMedioRevalorizacionInventario;
  Result := Format(
    SFormatoOperacionRevalorizacionInventario,
    [sTipo, FormatFloat('0.00', ASimulacion.Porcentaje), sBase]);
end;

function TfrmModalRevalorizacionInventario.DatosInforme:
  TDatosInformeSimulacionValoracion;
begin
  Result := ConstruirDatosInformeSimulacionValoracion(
    FLineasBase, FUltimaSimulacion);
  if FOpciones.TituloInforme <> '' then
    Result.Titulo := FOpciones.TituloInforme
  else
    Result.Titulo := STituloInformeRevalorizacionInventario;
  Result.Identificacion := lblInventario.Caption;
  Result.Operacion := TextoOperacion(FUltimaSimulacion);
  if FOpciones.CaptionPrecioMedioInforme <> '' then
    Result.CaptionPrecioMedio := FOpciones.CaptionPrecioMedioInforme
  else
    Result.CaptionPrecioMedio :=
      SCaptionColPrecioMedioAlmacenInformeValoracion;
  Result.Fecha := Now;
end;

procedure TfrmModalRevalorizacionInventario.btnImprimirClick(
  Sender: TObject);
begin
  if Length(FUltimaSimulacion.Lineas) = 0 then
    ShowMessage_fza(SInfoSimulacionPendienteRevalorizacionInventario)
  else
    TfrmPrintSimulacionValoracion.Mostrar(Self, DatosInforme);
end;

procedure TfrmModalRevalorizacionInventario.cdsSimulacionAfterPost(
  DataSet: TDataSet);
begin
  InvalidarSimulacion;
end;

end.
