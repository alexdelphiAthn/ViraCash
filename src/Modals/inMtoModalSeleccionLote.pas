{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeleccionLote                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Elegir de qué lote o serie sale una línea (F-LOTEC-010).       }
{    Lista las existencias del almacén en orden de salida FEFO,    }
{    propone las cantidades y resalta caducados y próximos a     }
{    caducar. En SERIE se marcan o se leen las unidades: N unidades → N        }
{    asignaciones de 1. Los caducados avisan, no bloquean.                     }
{******************************************************************************}
unit inMtoModalSeleccionLote;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms,
  cxGraphics, cxStyles, cxCustomData, cxDataStorage, cxEdit, cxLabel,
  cxTextEdit, cxGrid,
  cxGridLevel, cxGridCustomTableView, cxGridTableView,
  inMtoModalAceptCancel, inLibTrazabilidad, inLibLotesPersistenciaIntf,
  inLibLotesVisualIntf;

type
  TfrmModalSeleccionLote = class(TfrmModalAceptCancel)
    lblCabecera: TcxLabel;
    lblLeerSerie: TcxLabel;
    edtLeerSerie: TcxTextEdit;
    grdLotes: TcxGrid;
    tvLotes: TcxGridTableView;
    colElegir: TcxGridColumn;
    colLote: TcxGridColumn;
    colCaducidad: TcxGridColumn;
    colDias: TcxGridColumn;
    colEntrada: TcxGridColumn;
    colStock: TcxGridColumn;
    colCantidad: TcxGridColumn;
    lblPie: TcxLabel;
    lblAviso: TcxLabel;
    styCaducado: TcxStyle;
    styProximo: TcxStyle;
  private
    FParametros: TParametrosSeleccionLote;
    FLotes: TLotesDisponibles;
    FEstilos: TcxStyleRepository;
    // Caducados ya avisados: un segundo Aceptar con la misma selección los
    // da por buenos.
    FCaducadosAvisados: string;
    FResultado: TResultadoSeleccionLote;
    // Trama STX/ETX de la pistola (FZ-ISSUE-330): sin Intro detrás.
    FLeyendoTrama: Boolean;
    FTrama: string;
    function AnadirEtiqueta(AAltura: Integer): TcxLabel;
    function CrearColumna(
      const ACaption: string;
      AValueTypeClass: TcxValueTypeClass;
      AAncho: Integer): TcxGridColumn;
    procedure ConstruirCabecera;
    procedure ConstruirRejilla;
    procedure ConstruirPie;
    procedure CargarLotes;
    procedure ProponerCantidades;
    function EsSerie: Boolean;
    function CantidadFila(AFila: Integer): Double;
    function CantidadElegida: Double;
    function CaducadosElegidos: string;
    function ValidarSeleccion: Boolean;
    function RecogerAsignaciones: TArray<TAsignacionLote>;
    procedure MostrarAviso(const ATexto: string);
    procedure ActualizarPie(Sender: TObject);
    procedure tvLotesGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
    procedure DoShow; override;
    procedure KeyPress(var Key: Char); override;
  public
    constructor CreateSeleccion(
      AOwner: TComponent;
      const ARepositorio: IRepositorioLotes;
      const AParametros: TParametrosSeleccionLote);
    function IsShortCut(var Message: TWMKey): Boolean; override;
    function CloseQuery: Boolean; override;
    // Marca la serie leída (pistola o teclado). False si no está en la
    // lista; el motivo queda en lblAviso.
    function LeerSerie(const ALectura: string): Boolean;
    property Resultado: TResultadoSeleccionLote read FResultado;
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioLotes;
      const AParametros: TParametrosSeleccionLote): TResultadoSeleccionLote;
  end;

// Puerto visual de F-LOTEC para el lector y las pantallas con líneas: elegir
// lotes con este modal y capturar series con inMtoModalAltaSeries.
function CrearSelectorLotesVisual(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AReimprimir: TProc<string> = nil): ISelectorLotesVisual;

implementation

uses
  System.Variants, System.UITypes, Vcl.Graphics,
  cxCheckBox, cxCurrencyEdit,
  inLibMsgTrazabilidad, inLibSeriesCodigosBarras, inMtoModalAltaSeries,
  inMtoModalHistoricoLote;

const
  // Medidas a 96 ppp; se aplican con ScaleValue.
  ANCHO_MODAL = 680;
  ALTO_MODAL = 460;
  ALTO_CABECERA = 48;
  ALTO_LINEA = 24;
  ALTO_AVISO = 44;
  MARGEN = 8;
  ANCHO_ELEGIR = 60;
  ANCHO_LOTE = 200;
  ANCHO_FECHA = 100;
  ANCHO_DIAS = 60;
  ANCHO_CANTIDAD = 100;
  FORMATO_CANTIDAD = '#,##0.###';
  COLOR_CADUCADO = TColor($000000C8);
  COLOR_PROXIMO = TColor($00007FE0);
  SEPARADOR_LISTA = ', ';

type
  TSelectorLotesVisualMto = class(TInterfacedObject, ISelectorLotesVisual)
  private
    FOwner: TComponent;
    FRepositorio: IRepositorioLotes;
    FReimprimir: TProc<string>;
  public
    constructor Create(
      AOwner: TComponent;
      const ARepositorio: IRepositorioLotes;
      const AReimprimir: TProc<string>);
    function SeleccionarLotes(
      const AParametros: TParametrosSeleccionLote): TResultadoSeleccionLote;
    function CapturarSeries(
      const AParametros: TParametrosAltaSeries): TResultadoAltaSeries;
    procedure MostrarHistorico(const ACodigoSku, ALote: string);
  end;

function CrearSelectorLotesVisual(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AReimprimir: TProc<string>): ISelectorLotesVisual;
begin
  Result := TSelectorLotesVisualMto.Create(AOwner, ARepositorio, AReimprimir);
end;

constructor TSelectorLotesVisualMto.Create(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AReimprimir: TProc<string>);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  inherited Create;
  FOwner := AOwner;
  FRepositorio := ARepositorio;
  FReimprimir := AReimprimir;
end;

function TSelectorLotesVisualMto.SeleccionarLotes(
  const AParametros: TParametrosSeleccionLote): TResultadoSeleccionLote;
begin
  Result := TfrmModalSeleccionLote.Ejecutar(FOwner, FRepositorio,
                                            AParametros);
end;

function TSelectorLotesVisualMto.CapturarSeries(
  const AParametros: TParametrosAltaSeries): TResultadoAltaSeries;
begin
  Result := TfrmModalAltaSeries.Ejecutar(FOwner, FRepositorio, AParametros);
end;

procedure TSelectorLotesVisualMto.MostrarHistorico(
  const ACodigoSku, ALote: string);
begin
  TfrmModalHistoricoLote.Ejecutar(FOwner, FRepositorio, ACodigoSku, ALote,
    FReimprimir);
end;

function TextoCantidad(const ACantidad: Double): string;
begin
  Result := FormatFloat(FORMATO_CANTIDAD, ACantidad);
end;

function TextoFecha(AFecha: TDate): string;
begin
  if AFecha = SIN_FECHA then
    Result := ''
  else
    Result := DateToStr(AFecha);
end;

function TextoLote(const ALote: string): string;
begin
  if ALote = '' then
    Result := SCaptionSinLote
  else
    Result := ALote;
end;

{ TfrmModalSeleccionLote }

constructor TfrmModalSeleccionLote.CreateSeleccion(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AParametros: TParametrosSeleccionLote);
begin
  inherited Create(AOwner);
  FParametros := AParametros;
  if AParametros.UsarDisponibles then
    FLotes := OrdenarParaSalida(AParametros.Modo,
      AParametros.Disponibles, AParametros.Hoy)
  else
    FLotes := OrdenarParaSalida(AParametros.Modo,
      ARepositorio.Disponibles(AParametros.CodigoSku,
        AParametros.CodigoAlmacen), AParametros.Hoy);
  OnClose := CerrarSinLiberar;
  Position := poOwnerFormCenter;
  ClientWidth := ScaleValue(ANCHO_MODAL);
  ClientHeight := ScaleValue(ALTO_MODAL);
  FEstilos := TcxStyleRepository.Create(Self);
  styCaducado := TcxStyle(FEstilos.CreateItem(TcxStyle));
  styCaducado.TextColor := COLOR_CADUCADO;
  styProximo := TcxStyle(FEstilos.CreateItem(TcxStyle));
  styProximo.TextColor := COLOR_PROXIMO;
  ConstruirCabecera;
  ConstruirPie;
  ConstruirRejilla;
  CargarLotes;
  ActualizarPie(nil);
end;

procedure TfrmModalSeleccionLote.DoCreate;
begin
  inherited;
  // TfrmBase traduce el Caption por la jerarquía de clases: sin clave
  // propia quedaría el título de TfrmBase.
  case FParametros.Modo of
    mtSerie:
      Caption := STituloSeleccionSerie;
  else
    Caption := STituloSeleccionLote;
  end;
end;

procedure TfrmModalSeleccionLote.DoShow;
begin
  inherited;
  if EsSerie and edtLeerSerie.CanFocus then
    edtLeerSerie.SetFocus
  else if (Length(FLotes) > 0) and grdLotes.CanFocus then
  begin
    grdLotes.SetFocus;
    tvLotes.Controller.FocusedRowIndex := 0;
    tvLotes.Controller.FocusedColumn := colCantidad;
  end;
end;

function TfrmModalSeleccionLote.EsSerie: Boolean;
begin
  Result := FParametros.Modo = mtSerie;
end;

function TfrmModalSeleccionLote.AnadirEtiqueta(AAltura: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := pnlBody;
  Result.AutoSize := False;
  Result.Height := ScaleValue(AAltura);
  Result.AlignWithMargins := True;
  Result.Margins.SetBounds(ScaleValue(MARGEN), 0, ScaleValue(MARGEN), 0);
  Result.Transparent := True;
  Result.Properties.WordWrap := True;
end;

procedure TfrmModalSeleccionLote.ConstruirCabecera;
begin
  lblCabecera := AnadirEtiqueta(ALTO_CABECERA);
  lblCabecera.Align := alTop;
  lblCabecera.Style.TextStyle := [fsBold];
  lblCabecera.Caption := Format(SCabeceraSeleccionLote,
    [FParametros.CodigoSku, FParametros.DescripcionArticulo,
     FParametros.CodigoAlmacen, TextoCantidad(FParametros.Cantidad)]);
  lblLeerSerie := AnadirEtiqueta(ALTO_LINEA);
  lblLeerSerie.Top := lblCabecera.Top + lblCabecera.Height;
  lblLeerSerie.Align := alTop;
  lblLeerSerie.Caption := SCaptionLeerSerieSeleccion;
  edtLeerSerie := TcxTextEdit.Create(Self);
  edtLeerSerie.Parent := pnlBody;
  edtLeerSerie.AlignWithMargins := True;
  edtLeerSerie.Margins.SetBounds(ScaleValue(MARGEN), 0,
    ScaleValue(MARGEN), ScaleValue(MARGEN));
  edtLeerSerie.Top := lblLeerSerie.Top + lblLeerSerie.Height;
  edtLeerSerie.Align := alTop;
  lblLeerSerie.Visible := EsSerie;
  edtLeerSerie.Visible := EsSerie;
end;

procedure TfrmModalSeleccionLote.ConstruirPie;
begin
  lblAviso := AnadirEtiqueta(ALTO_AVISO);
  lblAviso.Align := alBottom;
  lblAviso.Style.TextColor := COLOR_CADUCADO;
  lblPie := AnadirEtiqueta(ALTO_LINEA);
  lblPie.Top := lblAviso.Top - ScaleValue(ALTO_LINEA);
  lblPie.Align := alBottom;
end;

function TfrmModalSeleccionLote.CrearColumna(
  const ACaption: string;
  AValueTypeClass: TcxValueTypeClass;
  AAncho: Integer): TcxGridColumn;
begin
  Result := tvLotes.CreateColumn;
  Result.Caption := ACaption;
  Result.DataBinding.ValueTypeClass := AValueTypeClass;
  Result.Width := ScaleValue(AAncho);
  Result.Options.Editing := False;
  Result.Options.Focusing := False;
  Result.Options.Sorting := False;
  Result.Options.Filtering := False;
  Result.Options.Grouping := False;
end;

procedure TfrmModalSeleccionLote.ConstruirRejilla;
begin
  grdLotes := TcxGrid.Create(Self);
  grdLotes.Parent := pnlBody;
  grdLotes.AlignWithMargins := True;
  grdLotes.Margins.SetBounds(ScaleValue(MARGEN), 0, ScaleValue(MARGEN), 0);
  grdLotes.Align := alClient;
  tvLotes := grdLotes.CreateView(TcxGridTableView) as TcxGridTableView;
  grdLotes.Levels.Add.GridView := tvLotes;
  tvLotes.OptionsView.GroupByBox := False;
  tvLotes.OptionsView.ColumnAutoWidth := True;
  tvLotes.OptionsData.Inserting := False;
  tvLotes.OptionsData.Deleting := False;
  tvLotes.OptionsCustomize.ColumnMoving := False;
  tvLotes.OptionsSelection.HideFocusRectOnExit := False;
  tvLotes.Styles.OnGetContentStyle := tvLotesGetContentStyle;
  colElegir := CrearColumna(SCaptionColumnaElegirSerie, TcxBooleanValueType,
                            ANCHO_ELEGIR);
  colElegir.PropertiesClass := TcxCheckBoxProperties;
  TcxCheckBoxProperties(colElegir.Properties).ImmediatePost := True;
  colElegir.Options.Editing := True;
  colElegir.Options.Focusing := True;
  case FParametros.Modo of
    mtSerie:
      colLote := CrearColumna(SCaptionColumnaSerie, TcxStringValueType,
                              ANCHO_LOTE);
  else
    colLote := CrearColumna(SCaptionColumnaLote, TcxStringValueType,
                            ANCHO_LOTE);
  end;
  colCaducidad := CrearColumna(SCaptionColumnaCaducidad, TcxStringValueType,
                               ANCHO_FECHA);
  colDias := CrearColumna(SCaptionColumnaDiasCaducidad, TcxIntegerValueType,
                          ANCHO_DIAS);
  colEntrada := CrearColumna(SCaptionColumnaEntrada, TcxStringValueType,
                             ANCHO_FECHA);
  colStock := CrearColumna(SCaptionColumnaStockLote, TcxFloatValueType,
                           ANCHO_CANTIDAD);
  colStock.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(colStock.Properties).DisplayFormat :=
    FORMATO_CANTIDAD;
  colCantidad := CrearColumna(SCaptionColumnaCantidadLote, TcxFloatValueType,
                              ANCHO_CANTIDAD);
  colCantidad.PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(colCantidad.Properties).DisplayFormat :=
    FORMATO_CANTIDAD;
  TcxCurrencyEditProperties(colCantidad.Properties).EditFormat :=
    FORMATO_CANTIDAD;
  colCantidad.Options.Editing := True;
  colCantidad.Options.Focusing := True;
  // Cada modo enseña lo suyo: la caducidad solo tiene sentido en LOTE y
  // en SERIE se elige marcando, no con cantidades.
  colElegir.Visible := EsSerie;
  colCantidad.Visible := not EsSerie;
  colCaducidad.Visible := FParametros.Modo = mtLote;
  colDias.Visible := FParametros.Modo = mtLote;
  colEntrada.Visible := FParametros.Modo <> mtLote;
  tvLotes.DataController.OnDataChanged := ActualizarPie;
end;

procedure TfrmModalSeleccionLote.CargarLotes;
var
  iFila: Integer;
  oDatos: TcxCustomDataController;
begin
  oDatos := tvLotes.DataController;
  oDatos.BeginUpdate;
  try
    oDatos.RecordCount := Length(FLotes);
    for iFila := 0 to High(FLotes) do
    begin
      oDatos.Values[iFila, colElegir.Index] := False;
      oDatos.Values[iFila, colLote.Index] := TextoLote(FLotes[iFila].Lote);
      oDatos.Values[iFila, colCaducidad.Index] :=
        TextoFecha(FLotes[iFila].FechaCaducidad);
      if FLotes[iFila].FechaCaducidad = SIN_FECHA then
        oDatos.Values[iFila, colDias.Index] := Null
      else
        oDatos.Values[iFila, colDias.Index] := DiasParaCaducar(
          FLotes[iFila].FechaCaducidad, FParametros.Hoy);
      oDatos.Values[iFila, colEntrada.Index] :=
        TextoFecha(FLotes[iFila].FechaEntrada);
      oDatos.Values[iFila, colStock.Index] := FLotes[iFila].Cantidad;
      oDatos.Values[iFila, colCantidad.Index] := 0.0;
    end;
    if not EsSerie then
      ProponerCantidades;
  finally
    oDatos.EndUpdate;
  end;
  if Length(FLotes) = 0 then
  begin
    MostrarAviso(Format(SAvisoSinExistenciasLote,
                        [FParametros.CodigoAlmacen]));
    btnAceptar.Enabled := False;
  end;
end;

procedure TfrmModalSeleccionLote.ProponerCantidades;
var
  iAsignacion: Integer;
  iFila: Integer;
  rPropuesta: TSeleccionLotes;
  Vigentes: TLotesDisponibles;
  Lote: TLoteDisponible;
begin
  // Lo que saldría solo (FEFO): el usuario lo
  // corrige si saca otro lote.
  if FParametros.Cantidad > 0 then
  begin
    Vigentes := [];
    for Lote in FLotes do
      if not EstaCaducado(Lote.FechaCaducidad, FParametros.Hoy) then
        Vigentes := Vigentes + [Lote];
    rPropuesta := SeleccionarFefo(FParametros.Modo, Vigentes,
      FParametros.Cantidad, FParametros.Hoy);
    for iAsignacion := 0 to High(rPropuesta.Asignaciones) do
    begin
      for iFila := 0 to High(FLotes) do
      begin
        if FLotes[iFila].Lote = rPropuesta.Asignaciones[iAsignacion].Lote then
          tvLotes.DataController.Values[iFila, colCantidad.Index] :=
            rPropuesta.Asignaciones[iAsignacion].Cantidad;
      end;
    end;
  end;
end;

function TfrmModalSeleccionLote.CantidadFila(AFila: Integer): Double;
var
  vValor: Variant;
begin
  if EsSerie then
  begin
    vValor := tvLotes.DataController.Values[AFila, colElegir.Index];
    if (not VarIsNull(vValor)) and Boolean(vValor) then
      Result := 1
    else
      Result := 0;
  end
  else
  begin
    vValor := tvLotes.DataController.Values[AFila, colCantidad.Index];
    if VarIsNull(vValor) then
      Result := 0
    else
      Result := vValor;
  end;
end;

function TfrmModalSeleccionLote.CantidadElegida: Double;
var
  iFila: Integer;
begin
  Result := 0;
  for iFila := 0 to High(FLotes) do
    Result := Result + CantidadFila(iFila);
end;

function TfrmModalSeleccionLote.CaducadosElegidos: string;
var
  iFila: Integer;
begin
  Result := '';
  for iFila := 0 to High(FLotes) do
  begin
    if (CantidadFila(iFila) > 0) and
       EstaCaducado(FLotes[iFila].FechaCaducidad, FParametros.Hoy) then
    begin
      if Result <> '' then
        Result := Result + SEPARADOR_LISTA;
      Result := Result + TextoLote(FLotes[iFila].Lote);
    end;
  end;
end;

procedure TfrmModalSeleccionLote.MostrarAviso(const ATexto: string);
begin
  lblAviso.Caption := ATexto;
end;

procedure TfrmModalSeleccionLote.ActualizarPie(Sender: TObject);
begin
  if Assigned(lblPie) then
    lblPie.Caption := Format(SPieSeleccionLote,
      [TextoCantidad(CantidadElegida), TextoCantidad(FParametros.Cantidad)]);
end;

function TfrmModalSeleccionLote.ValidarSeleccion: Boolean;
var
  dCantidad: Double;
  iFila: Integer;
  sCaducados: string;
begin
  Result := True;
  for iFila := 0 to High(FLotes) do
  begin
    dCantidad := CantidadFila(iFila);
    if Result and (dCantidad < 0) then
    begin
      MostrarAviso(Format(SErrorCantidadLoteNegativa,
                          [TextoLote(FLotes[iFila].Lote)]));
      Result := False;
    end
    else if Result and (dCantidad > FLotes[iFila].Cantidad) then
    begin
      MostrarAviso(Format(SErrorCantidadLoteSuperaStock,
        [TextoLote(FLotes[iFila].Lote), TextoCantidad(dCantidad),
         TextoCantidad(FLotes[iFila].Cantidad)]));
      Result := False;
    end;
  end;
  if Result and (CantidadElegida <= 0) then
  begin
    if EsSerie then
      MostrarAviso(SErrorSeleccionSerieVacia)
    else
      MostrarAviso(SErrorSeleccionLoteVacia);
    Result := False;
  end;
  sCaducados := CaducadosElegidos;
  if Result and (sCaducados <> '') and (sCaducados <> FCaducadosAvisados) then
  begin
    // Avisar, no bloquear: el segundo Aceptar con lo mismo pasa.
    FCaducadosAvisados := sCaducados;
    MostrarAviso(Format(SAvisoLotesCaducadosSeleccion, [sCaducados]));
    Result := False;
  end;
end;

function TfrmModalSeleccionLote.RecogerAsignaciones: TArray<TAsignacionLote>;
var
  dCantidad: Double;
  iFila: Integer;
  rAsignacion: TAsignacionLote;
begin
  Result := [];
  for iFila := 0 to High(FLotes) do
  begin
    dCantidad := CantidadFila(iFila);
    if dCantidad > 0 then
    begin
      rAsignacion.Lote := FLotes[iFila].Lote;
      rAsignacion.FechaCaducidad := FLotes[iFila].FechaCaducidad;
      rAsignacion.Cantidad := dCantidad;
      rAsignacion.EsCaducado := EstaCaducado(rAsignacion.FechaCaducidad,
                                             FParametros.Hoy);
      Result := Result + [rAsignacion];
    end;
  end;
end;

function TfrmModalSeleccionLote.LeerSerie(const ALectura: string): Boolean;
var
  iFila: Integer;
  sSerie: string;
begin
  Result := False;
  sSerie := SerieDesdeLectura(ALectura);
  if sSerie <> '' then
  begin
    for iFila := 0 to High(FLotes) do
    begin
      if SameText(FLotes[iFila].Lote, sSerie) then
      begin
        tvLotes.DataController.Values[iFila, colElegir.Index] := True;
        tvLotes.Controller.FocusedRecordIndex := iFila;
        Result := True;
      end;
    end;
    if Result then
      MostrarAviso('')
    else
      MostrarAviso(Format(SErrorSerieNoEnAlmacen,
                          [sSerie, FParametros.CodigoAlmacen]));
  end;
end;

// Las pistolas envuelven el código en STX (Ctrl+B) y ETX (Ctrl+C) y no
// mandan Intro: la lectura solo se tomaba con Intro, así que una serie de
// otro almacén no avisaba de nada (FZ-ISSUE-330). El modal es otra ventana
// y el lector de la pantalla que lo abre no ve sus teclas.
procedure TfrmModalSeleccionLote.KeyPress(var Key: Char);
begin
  if EsSerie and (Key = #2) then
  begin
    FLeyendoTrama := True;
    FTrama := '';
    Key := #0;
  end
  else if FLeyendoTrama then
  begin
    if Key = #3 then
    begin
      FLeyendoTrama := False;
      LeerSerie(FTrama);
      FTrama := '';
      edtLeerSerie.Text := '';
    end
    else if Key >= ' ' then
      FTrama := FTrama + Key;
    Key := #0;
  end;
  inherited KeyPress(Key);
end;

function TfrmModalSeleccionLote.IsShortCut(var Message: TWMKey): Boolean;
begin
  // JvEnterAsTab convierte el Enter en Tab antes de OnKeyDown: la lectura
  // se recoge aquí, que la VCL consulta primero.
  if (Message.CharCode = VK_RETURN) and edtLeerSerie.Visible and
     edtLeerSerie.Focused then
  begin
    LeerSerie(edtLeerSerie.Text);
    edtLeerSerie.Text := '';
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

function TfrmModalSeleccionLote.CloseQuery: Boolean;
begin
  // sFicha lo asigna el ancestro: 'S' tras Aceptar o F12, 'N' al cancelar.
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    tvLotes.DataController.PostEditingData;
    Result := ValidarSeleccion;
    if Result then
    begin
      FResultado.Aceptado := True;
      FResultado.Asignaciones := RecogerAsignaciones;
    end
    else
      sFicha := 'N';
  end;
end;

procedure TfrmModalSeleccionLote.tvLotesGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if Assigned(ARecord) and (ARecord.RecordIndex <= High(FLotes)) then
  begin
    case EstadoCaducidad(FLotes[ARecord.RecordIndex].FechaCaducidad,
                         FParametros.Hoy, FParametros.DiasAviso) of
      ecCaducado:
        AStyle := styCaducado;
      ecProximaCaducidad:
        AStyle := styProximo;
    end;
  end;
end;

// La base libera el modal al cerrarse (caFree); Ejecutar lo libera.
procedure TfrmModalSeleccionLote.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalSeleccionLote.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioLotes;
  const AParametros: TParametrosSeleccionLote): TResultadoSeleccionLote;
var
  oFormulario: TfrmModalSeleccionLote;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  oFormulario := TfrmModalSeleccionLote.CreateSeleccion(
    AOwner, ARepositorio, AParametros);
  try
    oFormulario.ShowModal;
    Result := oFormulario.Resultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
