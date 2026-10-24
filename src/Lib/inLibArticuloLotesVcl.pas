{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticuloLotesVcl                                         }
{    Tipo:       Librería (colaborador VCL)                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Pestaña «Lotes / Series» de la ficha de artículo (F-LOTEC-011): el        }
{    catálogo de lotes y series del artículo con sus existencias   }
{    por almacén, caducidad y estado; histórico de movimientos y alta manual   }
{    en el catálogo. Solo existe con algún interruptor de trazabilidad.        }
{******************************************************************************}
unit inLibArticuloLotesVcl;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, cxPC, cxGrid,
  cxGridTableView,
  cxGridCustomTableView, cxButtons, cxGroupBox, cxStyles, cxCheckBox,
  inLibTrazabilidad, inLibLotesPersistenciaIntf, inLibLotesVisualIntf;

type
  TResultadoAltaManualLotes = record
    Creados: Integer;
    Existentes: Integer;
    Errores: TArray<string>;
  end;

  TPestanaLotesArticuloVcl = class(TComponent)
  private
    FActivacion: TActivacionTrazabilidad;
    FConsulta: IConsultaLotesArticulo;
    FRepositorio: IRepositorioLotes;
    FSelector: ISelectorLotesVisual;
    FUsuario: string;
    FDiasAvisoGeneral: Integer;
    FPestana: TcxTabSheet;
    FBotonHistorico: TcxButton;
    FBotonAlta: TcxButton;
    FBotonEtiqueta: TcxButton;
    FAlImprimirEtiqueta: TProc<TLoteArticulo>;
    FAlRetirar: TProc<TArray<TLoteArticulo>>;
    FSoloConExistencias: TcxCheckBox;
    FVista: TcxGridTableView;
    FEstilos: TcxStyleRepository;
    FEstiloCaducado: TcxStyle;
    FEstiloProximo: TcxStyle;
    FLotes: TArray<TLoteArticulo>;
    // Filas pintadas, en el orden de los registros de la rejilla.
    FVisibles: TArray<TLoteArticulo>;
    FCodigoArticulo: string;
    FDescripcion: string;
    FModo: TModoTrazabilidad;
    FDiasAviso: Integer;
    FHoy: TDate;
    FExigeCaducidad: Boolean;
    procedure RetirarClick(Sender: TObject);
    procedure ConstruirBotones;
    procedure ConstruirRejilla;
    procedure Pintar;
    function LoteActual(out ALote: TLoteArticulo): Boolean;
    function ElegirSku(out ASku: string): Boolean;
    function PedirLotes(const ASku: string; out ALotes: TArray<string>;
      out AFechaCaducidad: TDate): Boolean;
    procedure HistoricoClick(Sender: TObject);
    procedure AltaClick(Sender: TObject);
    procedure EtiquetaClick(Sender: TObject);
    procedure SetAlImprimirEtiqueta(const AValor: TProc<TLoteArticulo>);
    procedure SoloConExistenciasClick(Sender: TObject);
    procedure VistaGetContentStyle(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; AItem: TcxCustomGridTableItem;
      var AStyle: TcxStyle);
  public
    constructor CreatePestana(AOwner: TComponent; APaginas: TcxPageControl;
      const AActivacion: TActivacionTrazabilidad;
      const AConsulta: IConsultaLotesArticulo;
      const ARepositorio: IRepositorioLotes;
      const ASelector: ISelectorLotesVisual;
      const AUsuario: string; ADiasAvisoGeneral: Integer);
    // ADiasAvisoArticulo: DIAS_AVISO_CADUCIDAD_ART (DIAS_AVISO_SIN_VALOR
    // si es NULL); AExigeCaducidad: ESCADUCIDAD_ART = 'S'.
    procedure Cargar(const ACodigoArticulo, ADescripcion: string;
      AModo: TModoTrazabilidad; ADiasAvisoArticulo: Integer;
      AHoy: TDate; AExigeCaducidad: Boolean = False);
    procedure MostrarHistoricoActual;
    // F-LOTEC-022: imprime etiquetas del lote o serie enfocado; sin
    // asignar, el botón no se ve.
    property AlImprimirEtiqueta: TProc<TLoteArticulo>
      read FAlImprimirEtiqueta write SetAlImprimirEtiqueta;
    procedure ImprimirEtiquetaActual;
    procedure DarDeAltaManual;
    property AlRetirar: TProc<TArray<TLoteArticulo>>
      read FAlRetirar write FAlRetirar;
    property Pestana: TcxTabSheet read FPestana;
    property Vista: TcxGridTableView read FVista;
    property SoloConExistencias: TcxCheckBox read FSoloConExistencias;
  end;

// Alta en el catálogo de los lotes o series dados (sin diálogos). En SERIE
// cada serie es una unidad; una ya existente en otro artículo o en stock
// queda en Errores.
function DarDeAltaLotesManuales(const ARepositorio: IRepositorioLotes;
  const ACodigoSku: string; AModo: TModoTrazabilidad;
  const ALotes: TArray<string>; AFechaCaducidad, AHoy: TDate;
  const AUsuario: string): TResultadoAltaManualLotes;
function EstadoLoteArticulo(const ALote: TLoteArticulo): string;
// Datos del alta manual de un lote: '' si valen (AFecha = la caducidad o
// SIN_FECHA) o el error que se muestra. Con AExigeCaducidad
// (ESCADUCIDAD_ART = 'S') la caducidad es obligatoria.
function ValidarAltaManualLote(const ALote, ACaducidad: string;
  AExigeCaducidad: Boolean; out AFecha: TDate): string;

implementation

uses
  System.UITypes, System.Variants, Vcl.Graphics,
  cxCustomData, cxDataStorage, cxCurrencyEdit, cxGridLevel,
  cxContainer, cxEdit, inLibMensajesVcl, inLibMsgTrazabilidad,
  inLibMsgLotesConsultas, inLibMsgRetiradaLotes;

const
  // Medidas a 96 ppp.
  ALTO_BOTONERA = 44;
  ANCHO_BOTON = 140;
  ANCHO_CASILLA = 220;
  MARGEN = 8;
  FORMATO_CANTIDAD = '#,##0.###';
  COLOR_CADUCADO = TColor($000000C8);
  COLOR_PROXIMO = TColor($00007FE0);
  COLUMNA_SKU = 0;
  COLUMNA_LOTE = 1;
  COLUMNA_TIPO = 2;
  COLUMNA_CADUCIDAD = 3;
  COLUMNA_DIAS = 4;
  COLUMNA_ENTRADA = 5;
  COLUMNA_ALMACEN = 6;
  COLUMNA_STOCK = 7;
  COLUMNA_ESTADO = 8;

function TextoFecha(AFecha: TDate): string;
begin
  if AFecha = SIN_FECHA then
    Result := ''
  else
    Result := DateToStr(AFecha);
end;

function ValidarAltaManualLote(const ALote, ACaducidad: string;
  AExigeCaducidad: Boolean; out AFecha: TDate): string;
var
  dtFecha: TDateTime;
begin
  Result := '';
  AFecha := SIN_FECHA;
  if Trim(ALote) = '' then
    Result := SErrorLoteVacioAltaManual
  else if Trim(ACaducidad) = '' then
  begin
    if AExigeCaducidad then
      Result := SErrorCaducidadObligatoriaAltaManual;
  end
  else if TryStrToDate(Trim(ACaducidad), dtFecha) then
    AFecha := Trunc(dtFecha)
  else
    Result := Format(SErrorCaducidadAltaManual, [ACaducidad]);
end;

function EstadoLoteArticulo(const ALote: TLoteArticulo): string;
begin
  if not ALote.EsActivo then
    Result := SEstadoLoteInactivo
  else if ALote.Stock > 0 then
    Result := SEstadoLoteConExistencias
  else
    Result := SEstadoLoteSinExistencias;
end;

function DarDeAltaLotesManuales(const ARepositorio: IRepositorioLotes;
  const ACodigoSku: string; AModo: TModoTrazabilidad;
  const ALotes: TArray<string>; AFechaCaducidad, AHoy: TDate;
  const AUsuario: string): TResultadoAltaManualLotes;
var
  rLote: TLoteCatalogo;
  sLote: string;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  Result := Default(TResultadoAltaManualLotes);
  for sLote in ALotes do
  begin
    rLote := Default(TLoteCatalogo);
    rLote.CodigoSku := ACodigoSku;
    rLote.Lote := NormalizarLote(sLote);
    rLote.Modo := AModo;
    rLote.FechaCaducidad := AFechaCaducidad;
    rLote.FechaEntrada := AHoy;
    rLote.EsActivo := True;
    case ARepositorio.Asegurar(rLote, AUsuario) of
      ralCreado:
        Inc(Result.Creados);
      ralActualizado:
        Inc(Result.Existentes);
      ralSerieEnOtroArticulo:
        Result.Errores := Result.Errores +
          [Format(SErrorSerieOtroArticuloAltaManual, [rLote.Lote])];
      ralSerieYaEnStock:
        Result.Errores := Result.Errores +
          [Format(SErrorSerieEnStockAltaManual, [rLote.Lote])];
    end;
  end;
end;

{ TPestanaLotesArticuloVcl }

constructor TPestanaLotesArticuloVcl.CreatePestana(AOwner: TComponent;
  APaginas: TcxPageControl; const AActivacion: TActivacionTrazabilidad;
  const AConsulta: IConsultaLotesArticulo;
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual;
  const AUsuario: string; ADiasAvisoGeneral: Integer);
begin
  if not Assigned(APaginas) then
    raise EArgumentNilException.Create('APaginas');
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  inherited Create(AOwner);
  FActivacion := AActivacion;
  FConsulta := AConsulta;
  FRepositorio := ARepositorio;
  FSelector := ASelector;
  FUsuario := AUsuario;
  FDiasAvisoGeneral := ADiasAvisoGeneral;
  FDiasAviso := DiasAvisoEfectivos(DIAS_AVISO_SIN_VALOR, ADiasAvisoGeneral);
  FPestana := TcxTabSheet.Create(Self);
  FPestana.PageControl := APaginas;
  FPestana.Caption := SCaptionPestanaLotesSeries;
  FEstilos := TcxStyleRepository.Create(Self);
  FEstiloCaducado := TcxStyle(FEstilos.CreateItem(TcxStyle));
  FEstiloCaducado.TextColor := COLOR_CADUCADO;
  FEstiloProximo := TcxStyle(FEstilos.CreateItem(TcxStyle));
  FEstiloProximo.TextColor := COLOR_PROXIMO;
  ConstruirBotones;
  ConstruirRejilla;
end;

procedure TPestanaLotesArticuloVcl.ConstruirBotones;
var
  oBotonera: TcxGroupBox;
  BotonRetirar: TcxButton;
begin
  oBotonera := TcxGroupBox.Create(Self);
  oBotonera.Parent := FPestana;
  oBotonera.Align := alTop;
  oBotonera.Height := FPestana.ScaleValue(ALTO_BOTONERA);
  oBotonera.Style.BorderStyle := ebsNone;
  oBotonera.PanelStyle.Active := True;
  FBotonHistorico := TcxButton.Create(Self);
  FBotonHistorico.Parent := oBotonera;
  FBotonHistorico.Caption := SCaptionBotonHistoricoLote;
  FBotonHistorico.SetBounds(FPestana.ScaleValue(MARGEN),
    FPestana.ScaleValue(MARGEN div 2), FPestana.ScaleValue(ANCHO_BOTON),
    FPestana.ScaleValue(ALTO_BOTONERA - MARGEN));
  FBotonHistorico.OnClick := HistoricoClick;
  FBotonAlta := TcxButton.Create(Self);
  FBotonAlta.Parent := oBotonera;
  FBotonAlta.Caption := SCaptionBotonAltaManualLote;
  FBotonAlta.SetBounds(FBotonHistorico.Left + FBotonHistorico.Width +
    FPestana.ScaleValue(MARGEN), FBotonHistorico.Top, FBotonHistorico.Width,
    FBotonHistorico.Height);
  FBotonAlta.OnClick := AltaClick;
  FSoloConExistencias := TcxCheckBox.Create(Self);
  FSoloConExistencias.Parent := oBotonera;
  FSoloConExistencias.Caption := SEstadoLoteConExistencias;
  FSoloConExistencias.Transparent := True;
  FSoloConExistencias.SetBounds(FBotonAlta.Left + FBotonAlta.Width +
    FPestana.ScaleValue(2 * MARGEN), FBotonHistorico.Top,
    FPestana.ScaleValue(ANCHO_CASILLA), FBotonHistorico.Height);
  FSoloConExistencias.Properties.OnChange := SoloConExistenciasClick;
  FBotonEtiqueta := TcxButton.Create(Self);
  FBotonEtiqueta.Parent := oBotonera;
  FBotonEtiqueta.Caption := SCaptionBotonEtiquetaLote;
  FBotonEtiqueta.SetBounds(FSoloConExistencias.Left +
    FSoloConExistencias.Width + FPestana.ScaleValue(MARGEN),
    FBotonHistorico.Top, FBotonHistorico.Width, FBotonHistorico.Height);
  FBotonEtiqueta.OnClick := EtiquetaClick;
  FBotonEtiqueta.Visible := Assigned(FAlImprimirEtiqueta);
  BotonRetirar := TcxButton.Create(Self);
  BotonRetirar.Parent := oBotonera;
  BotonRetirar.Caption := SBotonRetirarLotes;
  BotonRetirar.SetBounds(FBotonEtiqueta.Left + FBotonEtiqueta.Width +
    FPestana.ScaleValue(MARGEN), FBotonHistorico.Top,
    FBotonHistorico.Width, FBotonHistorico.Height);
  BotonRetirar.OnClick := RetirarClick;
end;

procedure TPestanaLotesArticuloVcl.SetAlImprimirEtiqueta(
  const AValor: TProc<TLoteArticulo>);
begin
  FAlImprimirEtiqueta := AValor;
  if Assigned(FBotonEtiqueta) then
    FBotonEtiqueta.Visible := Assigned(FAlImprimirEtiqueta);
end;

procedure TPestanaLotesArticuloVcl.EtiquetaClick(Sender: TObject);
begin
  ImprimirEtiquetaActual;
end;

procedure TPestanaLotesArticuloVcl.ImprimirEtiquetaActual;
var
  Lote: TLoteArticulo;
begin
  if Assigned(FAlImprimirEtiqueta) then
  begin
    if LoteActual(Lote) then
      FAlImprimirEtiqueta(Lote)
    else
      ShowMessage_fza(SAvisoElijaLoteHistorico);
  end;
end;

procedure TPestanaLotesArticuloVcl.RetirarClick(Sender: TObject);
var
  Lotes: TArray<TLoteArticulo>;
  Indice, Fila: Integer;
  Actual: TLoteArticulo;
begin
  Lotes := [];
  for Indice := 0 to FVista.Controller.SelectedRecordCount - 1 do
  begin
    Fila := FVista.Controller.SelectedRecords[Indice].RecordIndex;
    if (Fila >= 0) and (Fila <= High(FVisibles)) then
      Lotes := Lotes + [FVisibles[Fila]];
  end;
  if (Length(Lotes) = 0) and LoteActual(Actual) then
    Lotes := [Actual];
  if Assigned(FAlRetirar) then
    FAlRetirar(Lotes);
end;

procedure TPestanaLotesArticuloVcl.ConstruirRejilla;

  procedure Columna(const ACaption: string;
    AValueTypeClass: TcxValueTypeClass);
  var
    oColumna: TcxGridColumn;
  begin
    oColumna := FVista.CreateColumn;
    oColumna.Caption := ACaption;
    oColumna.DataBinding.ValueTypeClass := AValueTypeClass;
    oColumna.Options.Editing := False;
  end;

var
  oRejilla: TcxGrid;
begin
  oRejilla := TcxGrid.Create(Self);
  oRejilla.Parent := FPestana;
  oRejilla.Align := alClient;
  FVista := oRejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  oRejilla.Levels.Add.GridView := FVista;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsView.ColumnAutoWidth := True;
  FVista.OptionsData.Editing := False;
  FVista.OptionsData.Inserting := False;
  FVista.OptionsData.Deleting := False;
  FVista.OptionsSelection.CellSelect := False;
  FVista.OptionsSelection.MultiSelect := True;
  FVista.Styles.OnGetContentStyle := VistaGetContentStyle;
  Columna(SCaptionColumnaSku, TcxStringValueType);
  Columna(SCaptionColumnaLoteSerie, TcxStringValueType);
  Columna(SCaptionGrupoTrazabilidad, TcxStringValueType);
  Columna(SCaptionColumnaCaducidad, TcxStringValueType);
  Columna(SCaptionColumnaDiasCaducidad, TcxIntegerValueType);
  Columna(SCaptionColumnaEntrada, TcxStringValueType);
  Columna(SCaptionColumnaAlmacen, TcxStringValueType);
  Columna(SCaptionColumnaStockLote, TcxFloatValueType);
  Columna(SCaptionColumnaEstadoLote, TcxStringValueType);
  FVista.Columns[COLUMNA_STOCK].PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(FVista.Columns[COLUMNA_STOCK].Properties)
    .DisplayFormat := FORMATO_CANTIDAD;
end;

procedure TPestanaLotesArticuloVcl.Cargar(const ACodigoArticulo,
  ADescripcion: string; AModo: TModoTrazabilidad;
  ADiasAvisoArticulo: Integer; AHoy: TDate; AExigeCaducidad: Boolean);
begin
  FCodigoArticulo := ACodigoArticulo;
  FExigeCaducidad := AExigeCaducidad;
  FDescripcion := ADescripcion;
  FModo := AModo;
  FHoy := AHoy;
  FDiasAviso := DiasAvisoEfectivos(ADiasAvisoArticulo, FDiasAvisoGeneral);
  FLotes := [];
  if Trim(ACodigoArticulo) <> '' then
    FLotes := FConsulta.Lotes(ACodigoArticulo);
  Pintar;
end;

procedure TPestanaLotesArticuloVcl.Pintar;
var
  aVisibles: TArray<TLoteArticulo>;
  iFila: Integer;
  oDatos: TcxCustomDataController;
  rLote: TLoteArticulo;
begin
  aVisibles := [];
  for rLote in FLotes do
  begin
    if (not FSoloConExistencias.Checked) or (rLote.Stock > 0) then
      aVisibles := aVisibles + [rLote];
  end;
  FVisibles := aVisibles;
  oDatos := FVista.DataController;
  oDatos.BeginUpdate;
  try
    oDatos.RecordCount := Length(aVisibles);
    for iFila := 0 to High(aVisibles) do
    begin
      rLote := aVisibles[iFila];
      oDatos.Values[iFila, COLUMNA_SKU] := rLote.CodigoSku;
      oDatos.Values[iFila, COLUMNA_LOTE] := rLote.Lote;
      oDatos.Values[iFila, COLUMNA_TIPO] := TextoModoTrazabilidad(rLote.Modo);
      oDatos.Values[iFila, COLUMNA_CADUCIDAD] :=
        TextoFecha(rLote.FechaCaducidad);
      if rLote.FechaCaducidad = SIN_FECHA then
        oDatos.Values[iFila, COLUMNA_DIAS] := Null
      else
        oDatos.Values[iFila, COLUMNA_DIAS] :=
          DiasParaCaducar(rLote.FechaCaducidad, FHoy);
      oDatos.Values[iFila, COLUMNA_ENTRADA] := TextoFecha(rLote.FechaEntrada);
      oDatos.Values[iFila, COLUMNA_ALMACEN] := rLote.CodigoAlmacen;
      oDatos.Values[iFila, COLUMNA_STOCK] := rLote.Stock;
      oDatos.Values[iFila, COLUMNA_ESTADO] := EstadoLoteArticulo(rLote);
    end;
  finally
    oDatos.EndUpdate;
  end;
end;

function TPestanaLotesArticuloVcl.LoteActual(
  out ALote: TLoteArticulo): Boolean;
var
  iFila: Integer;
begin
  // La fila completa (modo, caducidad, almacén y stock), no solo SKU y
  // lote: las etiquetas los necesitan (FZ-ISSUE-300).
  ALote := Default(TLoteArticulo);
  iFila := FVista.DataController.FocusedRecordIndex;
  Result := (iFila >= 0) and (iFila < FVista.DataController.RecordCount) and
    (iFila <= High(FVisibles));
  if Result then
    ALote := FVisibles[iFila];
end;

procedure TPestanaLotesArticuloVcl.MostrarHistoricoActual;
var
  rLote: TLoteArticulo;
begin
  if LoteActual(rLote) then
    FSelector.MostrarHistorico(rLote.CodigoSku, rLote.Lote)
  else
    ShowMessage_fza(SAvisoElijaLoteHistorico);
end;

function TPestanaLotesArticuloVcl.ElegirSku(out ASku: string): Boolean;
var
  aSkus: TArray<string>;
  rLote: TLoteArticulo;
  sSku: string;
begin
  aSkus := FConsulta.Skus(FCodigoArticulo);
  ASku := '';
  if Length(aSkus) = 1 then
    ASku := aSkus[0]
  else if Length(aSkus) > 1 then
  begin
    ASku := aSkus[0];
    if LoteActual(rLote) then
      ASku := rLote.CodigoSku;
    if not InputQuery_fza(STituloAltaManualLote, SPreguntaSkuAltaManual,
                          ASku) then
      ASku := '';
  end;
  Result := False;
  for sSku in aSkus do
  begin
    if SameText(sSku, Trim(ASku)) then
    begin
      ASku := sSku;
      Result := True;
    end;
  end;
  if (not Result) and (Trim(ASku) <> '') then
    ShowMessageFmt_fza(SErrorSkuNoEsDelArticulo, [ASku]);
end;

function TPestanaLotesArticuloVcl.PedirLotes(const ASku: string;
  out ALotes: TArray<string>; out AFechaCaducidad: TDate): Boolean;
var
  aValores: TArray<string>;
  dtFecha: TDate;
  rSeries: TResultadoAltaSeries;
  rParametros: TParametrosAltaSeries;
  sPreguntaCaducidad: string;
begin
  ALotes := [];
  AFechaCaducidad := SIN_FECHA;
  if FActivacion.ModoEfectivo(FModo) = mtSerie then
  begin
    rParametros := Default(TParametrosAltaSeries);
    rParametros.CodigoSku := ASku;
    rParametros.DescripcionArticulo := FDescripcion;
    rSeries := FSelector.CapturarSeries(rParametros);
    Result := rSeries.Aceptado;
    ALotes := rSeries.Series;
  end
  else
  begin
    aValores := ['', ''];
    sPreguntaCaducidad := SPreguntaCaducidadAltaManual;
    if FExigeCaducidad then
      sPreguntaCaducidad := SPreguntaCaducidadObligatoriaAltaManual;
    Result := InputQuery_fza(STituloAltaManualLote,
      [SPreguntaLoteAltaManual, sPreguntaCaducidad], aValores,
      function(const AValores: array of string): Boolean
      var
        sError: string;
      begin
        sError := ValidarAltaManualLote(AValores[0], AValores[1],
          FExigeCaducidad, dtFecha);
        Result := sError = '';
        if not Result then
          ShowMessage_fza(sError);
      end);
    if Result then
    begin
      ALotes := [Trim(aValores[0])];
      ValidarAltaManualLote(aValores[0], aValores[1], FExigeCaducidad,
        AFechaCaducidad);
    end;
  end;
end;

procedure TPestanaLotesArticuloVcl.DarDeAltaManual;
var
  aLotes: TArray<string>;
  dtCaducidad: TDate;
  oModo: TModoTrazabilidad;
  rAlta: TResultadoAltaManualLotes;
  sMensaje: string;
  sSku: string;
begin
  oModo := FActivacion.ModoEfectivo(FModo);
  if not RequiereLote(oModo) then
    ShowMessage_fza(SAvisoArticuloSinTrazabilidad)
  else if ElegirSku(sSku) and PedirLotes(sSku, aLotes, dtCaducidad) and
          (Length(aLotes) > 0) then
  begin
    rAlta := DarDeAltaLotesManuales(FRepositorio, sSku, oModo, aLotes,
      dtCaducidad, FHoy, FUsuario);
    sMensaje := Format(SResumenAltaManualLotes,
                       [rAlta.Creados, rAlta.Existentes]);
    if Length(rAlta.Errores) > 0 then
      sMensaje := sMensaje + sLineBreak +
                  string.Join(sLineBreak, rAlta.Errores);
    ShowMessage_fza(sMensaje);
    Cargar(FCodigoArticulo, FDescripcion, FModo, FDiasAviso, FHoy,
      FExigeCaducidad);
  end;
end;

procedure TPestanaLotesArticuloVcl.HistoricoClick(Sender: TObject);
begin
  MostrarHistoricoActual;
end;

procedure TPestanaLotesArticuloVcl.AltaClick(Sender: TObject);
begin
  DarDeAltaManual;
end;

procedure TPestanaLotesArticuloVcl.SoloConExistenciasClick(Sender: TObject);
begin
  Pintar;
end;

procedure TPestanaLotesArticuloVcl.VistaGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
var
  dtCaducidad: TDateTime;
begin
  if Assigned(ARecord) and TryStrToDate(VarToStr(
       ARecord.Values[COLUMNA_CADUCIDAD]), dtCaducidad) then
  begin
    case EstadoCaducidad(Trunc(dtCaducidad), FHoy, FDiasAviso) of
      ecCaducado:
        AStyle := FEstiloCaducado;
      ecProximaCaducidad:
        AStyle := FEstiloProximo;
    end;
  end;
end;

end.
