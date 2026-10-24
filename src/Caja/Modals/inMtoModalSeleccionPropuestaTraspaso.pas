{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeleccionPropuestaTraspaso                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Traspasos de caja - Confirmar propuesta: propuestas de traspaso           }
{    pendientes (o trasladadas en parte) cuyo origen es el almacén de la       }
{    caja. La elegida se carga con lo que falta por traspasar y al grabar se   }
{    pregunta si queda trasladada o trasladada en parte; también se puede      }
{    dar por no aceptada indicando el motivo.                                  }
{******************************************************************************}
unit inMtoModalSeleccionPropuestaTraspaso;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses,
  cxLocalization, cxSplitter, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, cxCurrencyEdit, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGrid,
  Data.DB, dxSkinsCore, dxDateRanges, dxScrollbarAnnotations,
  JvComponentBase, JvEnterTab,
  inMtoModalAceptCancel,
  inLibCajaVentanasIntf,
  inLibDistribucionTiendasIntf;

type
  TResultadoSeleccionPropuesta = record
    Cargar: Boolean;
    Propuesta: TPropuestaTraspaso;
    Lineas: TLineasCargaTraspaso;
  end;

  TfrmModalSeleccionPropuestaTraspaso = class(TfrmModalAceptCancel)
    cxgrdPropuestas: TcxGrid;
    tvPropuestas: TcxGridTableView;
    glPropuestas: TcxGridLevel;
    splLineas: TcxSplitter;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridTableView;
    glLineas: TcxGridLevel;
    btnNoAceptar: TcxButton;
    procedure btnNoAceptarClick(Sender: TObject);
  private
    FRepositorio: IRepositorioDistribucionTiendas;
    FAlmacenOrigen: string;
    FUsuario: string;
    FPropuestas: TPropuestasTraspaso;
    FResultado: TResultadoSeleccionPropuesta;
    function CrearColumna(
      AVista: TcxGridTableView;
      const ATitulo: string;
      AAncho: Integer;
      ANumerica: Boolean): TcxGridColumn;
    procedure CrearColumnas;
    procedure CargarPropuestas;
    procedure CargarLineas;
    function IndiceEnfocado: Integer;
    procedure PropuestasFocoCambiado(
      Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
  protected
    procedure DoCreate; override;
  public
    destructor Destroy; override;
    class function Ejecutar(
      AOwner: TComponent;
      const ARepositorio: IRepositorioDistribucionTiendas;
      const AAlmacenOrigen, AUsuario: string
    ): TResultadoSeleccionPropuesta;
    function CloseQuery: Boolean; override;
  end;

// Las líneas de una propuesta, como las espera el traspaso de caja: lo
// que falta por traspasar. Los atributos salen del propio código de SKU
// (artículo/color/talla).
function LineasCargaDePropuesta(
  const APropuesta: TPropuestaTraspaso): TLineasCargaTraspaso;

// Unidades de ALineas (CODIGO_UNIDAD, CANTIDAD) que cubren lo que faltaba
// de la propuesta, sin contar lo que exceda en cada SKU, y si lo cubren
// todo.
function UnidadesCubiertasPropuesta(
  const APropuesta: TPropuestaTraspaso;
  ALineas: TDataSet;
  out ACubreTodo: Boolean): Double;

// Al grabar el traspaso de una propuesta: ¿queda trasladada o trasladada
// en parte? Se propone la primera si las líneas cubren todo lo que
// faltaba. False si se cancela la grabación.
function PreguntarEstadoPropuestaAlGrabar(
  const APropuesta: TPropuestaTraspaso;
  ALineas: TDataSet;
  out AEstado: string): Boolean;

implementation

{$R *.dfm}

uses
  System.Math, System.Generics.Collections, System.UITypes,
  inLibMensajesVcl,
  inLibInformePropuestasTraspaso,
  inLibMsgDistribucionTiendas;

const
  FORMATO_UNIDADES = '0.###';
  TOLERANCIA_UNIDADES = 0.000001;
  MAXIMO_ATRIBUTOS_TRASPASO = 5;

function LineasCargaDePropuesta(
  const APropuesta: TPropuestaTraspaso): TLineasCargaTraspaso;
var
  i, iAtributo, iLineas: Integer;
  PartesSku: TArray<string>;
begin
  SetLength(Result, Length(APropuesta.Lineas));
  iLineas := 0;
  for i := 0 to High(APropuesta.Lineas) do
  begin
    if APropuesta.Lineas[i].CantidadPorTraspasar > 0 then
    begin
      Result[iLineas] := Default(TLineaCargaTraspaso);
      Result[iLineas].CodigoArticulo := APropuesta.Lineas[i].CodigoArticulo;
      Result[iLineas].CodigoSku := APropuesta.Lineas[i].CodigoSku;
      Result[iLineas].Descripcion :=
        APropuesta.Lineas[i].DescripcionArticulo;
      Result[iLineas].Cantidad := APropuesta.Lineas[i].CantidadPorTraspasar;
      PartesSku := APropuesta.Lineas[i].CodigoSku.Split(['/']);
      Result[iLineas].NumeroAtributos := Length(PartesSku) - 1;
      if Result[iLineas].NumeroAtributos > MAXIMO_ATRIBUTOS_TRASPASO then
        Result[iLineas].NumeroAtributos := MAXIMO_ATRIBUTOS_TRASPASO;
      for iAtributo := 1 to Result[iLineas].NumeroAtributos do
        Result[iLineas].ValoresAtributos[iAtributo] :=
          PartesSku[iAtributo];
      Inc(iLineas);
    end;
  end;
  SetLength(Result, iLineas);
end;

function UnidadesCubiertasPropuesta(
  const APropuesta: TPropuestaTraspaso;
  ALineas: TDataSet;
  out ACubreTodo: Boolean): Double;
var
  Cantidades: TDictionary<string, Double>;
  Marca: TBookmark;
  sSku: string;
  dCantidad, dFalta: Double;
  i: Integer;
begin
  Result := 0;
  ACubreTodo := True;
  Cantidades := TDictionary<string, Double>.Create;
  ALineas.DisableControls;
  try
    Marca := ALineas.GetBookmark;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        sSku := AnsiUpperCase(Trim(
          ALineas.FieldByName('CODIGO_UNIDAD').AsString));
        dCantidad := ALineas.FieldByName('CANTIDAD').AsFloat;
        if (sSku <> '') and (dCantidad > 0) then
        begin
          if Cantidades.ContainsKey(sSku) then
            dCantidad := dCantidad + Cantidades[sSku];
          Cantidades.AddOrSetValue(sSku, dCantidad);
        end;
        ALineas.Next;
      end;
      if (Marca <> nil) and ALineas.BookmarkValid(Marca) then
        ALineas.GotoBookmark(Marca);
    finally
      ALineas.FreeBookmark(Marca);
    end;
    // Un SKU repetido en la propuesta consume lo traspasado una sola vez.
    for i := 0 to High(APropuesta.Lineas) do
    begin
      dFalta := APropuesta.Lineas[i].CantidadPorTraspasar;
      if dFalta > 0 then
      begin
        sSku := AnsiUpperCase(Trim(APropuesta.Lineas[i].CodigoSku));
        if not Cantidades.TryGetValue(sSku, dCantidad) then
          dCantidad := 0;
        Result := Result + Min(dCantidad, dFalta);
        if dCantidad + TOLERANCIA_UNIDADES < dFalta then
          ACubreTodo := False;
        if Cantidades.ContainsKey(sSku) then
          Cantidades[sSku] := Max(dCantidad - dFalta, 0);
      end;
    end;
  finally
    ALineas.EnableControls;
    FreeAndNil(Cantidades);
  end;
end;

function PreguntarEstadoPropuestaAlGrabar(
  const APropuesta: TPropuestaTraspaso;
  ALineas: TDataSet;
  out AEstado: string): Boolean;
var
  bCubreTodo: Boolean;
  dCubiertas: Double;
  BotonPorDefecto: TMsgDlgBtn;
begin
  AEstado := '';
  dCubiertas := UnidadesCubiertasPropuesta(APropuesta, ALineas, bCubreTodo);
  if bCubreTodo then
    BotonPorDefecto := mbYes
  else
    BotonPorDefecto := mbNo;
  case MessageDlgTextos_fza(
    Format(SPreguntaEstadoPropuestaTraspasada, [
      FormatFloat(FORMATO_UNIDADES, dCubiertas),
      FormatFloat(FORMATO_UNIDADES, APropuesta.TotalPorTraspasar),
      APropuesta.IdPropuesta,
      TextoAlmacenPropuesta(
        APropuesta.AlmacenDestino, APropuesta.NombreAlmacenDestino)]),
    mtConfirmation, [mbYes, mbNo, mbCancel],
    [SCaptionPropuestaTraspasada, SCaptionPropuestaTraspasadaParcial, ''],
    BotonPorDefecto) of
    mrYes:
      AEstado := ESTADO_PROPUESTA_TRASPASO_TRASLADADO;
    mrNo:
      AEstado := ESTADO_PROPUESTA_TRASPASO_TRASLADADO_PARCIAL;
  end;
  Result := AEstado <> '';
end;

class function TfrmModalSeleccionPropuestaTraspaso.Ejecutar(
  AOwner: TComponent;
  const ARepositorio: IRepositorioDistribucionTiendas;
  const AAlmacenOrigen, AUsuario: string
): TResultadoSeleccionPropuesta;
var
  oFormulario: TfrmModalSeleccionPropuestaTraspaso;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  Result := Default(TResultadoSeleccionPropuesta);
  oFormulario := TfrmModalSeleccionPropuestaTraspaso.Create(AOwner);
  // El ancestro se libera solo al cerrar (caFree); aquí se libera a mano
  // para poder leer antes el resultado.
  oFormulario.OnClose := nil;
  try
    oFormulario.FRepositorio := ARepositorio;
    oFormulario.FAlmacenOrigen := Trim(AAlmacenOrigen);
    oFormulario.FUsuario := Trim(AUsuario);
    oFormulario.Caption := Format(
      STituloSeleccionPropuestaTraspaso, [Trim(AAlmacenOrigen)]);
    oFormulario.CargarPropuestas;
    if Length(oFormulario.FPropuestas) = 0 then
      ShowMessage_fza(Format(
        SInfoNoHayPropuestasPendientesOrigen, [Trim(AAlmacenOrigen)]))
    else
      oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

destructor TfrmModalSeleccionPropuestaTraspaso.Destroy;
begin
  FRepositorio := nil;
  inherited Destroy;
end;

// Los textos se fijan tras la traducción del formulario base, que si no
// deja el título con el de su ancestro.
procedure TfrmModalSeleccionPropuestaTraspaso.DoCreate;
begin
  inherited DoCreate;
  Caption := SCaptionConfirmarPropuesta;
  btnAceptar.Caption := SCaptionCargarPropuestaEnTraspaso;
  btnCancelar.Caption := SCaptionSalirSeleccionPropuesta;
  btnNoAceptar.Caption := SCaptionNoAceptarPropuesta;
  CrearColumnas;
  tvPropuestas.OnFocusedRecordChanged := PropuestasFocoCambiado;
end;

function TfrmModalSeleccionPropuestaTraspaso.CrearColumna(
  AVista: TcxGridTableView;
  const ATitulo: string;
  AAncho: Integer;
  ANumerica: Boolean): TcxGridColumn;
begin
  Result := AVista.CreateColumn;
  Result.Caption := ATitulo;
  Result.Width := ScaleValue(AAncho);
  Result.Options.Editing := False;
  Result.Options.Filtering := False;
  if ANumerica then
  begin
    Result.DataBinding.ValueTypeClass := TcxFloatValueType;
    Result.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(Result.Properties).DisplayFormat :=
      '#,##0.###;-#,##0.###;#';
    TcxCurrencyEditProperties(Result.Properties).DecimalPlaces := 3;
    Result.HeaderAlignmentHorz := taCenter;
  end
  else
    Result.DataBinding.ValueTypeClass := TcxStringValueType;
end;

procedure TfrmModalSeleccionPropuestaTraspaso.CrearColumnas;
begin
  tvPropuestas.ClearItems;
  CrearColumna(tvPropuestas, SCaptionColNumeroPropuesta, 100, False);
  CrearColumna(tvPropuestas, SCaptionColFechaPropuesta, 170, False);
  CrearColumna(tvPropuestas, SCaptionColDestinoPropuesta, 300, False);
  CrearColumna(tvPropuestas, SCaptionColUnidadesPropuesta, 110, True);
  CrearColumna(tvPropuestas, SCaptionColEstadoPropuesta, 150, False);
  CrearColumna(tvPropuestas, SCaptionColDocumentoPropuesta, 360, False);
  tvLineas.ClearItems;
  CrearColumna(tvLineas, SCaptionColArticuloDistribucion, 150, False);
  CrearColumna(tvLineas, SCaptionColDescripcionDistribucion, 420, False);
  CrearColumna(tvLineas, SCaptionColColorDistribucion, 180, False);
  CrearColumna(tvLineas, SCaptionColTallaDistribucion, 170, False);
  CrearColumna(tvLineas, SCaptionColUnidadesPropuesta, 110, True);
end;

procedure TfrmModalSeleccionPropuestaTraspaso.CargarPropuestas;
var
  i: Integer;
begin
  FPropuestas := FRepositorio.ListarPropuestasPendientesOrigen(
    FAlmacenOrigen);
  tvPropuestas.BeginUpdate;
  try
    tvPropuestas.DataController.RecordCount := Length(FPropuestas);
    for i := 0 to High(FPropuestas) do
    begin
      tvPropuestas.DataController.Values[i, 0] :=
        IntToStr(FPropuestas[i].IdPropuesta);
      tvPropuestas.DataController.Values[i, 1] :=
        FormatDateTime('dd/mm/yyyy hh:nn', FPropuestas[i].Instante);
      tvPropuestas.DataController.Values[i, 2] := TextoAlmacenPropuesta(
        FPropuestas[i].AlmacenDestino,
        FPropuestas[i].NombreAlmacenDestino);
      tvPropuestas.DataController.Values[i, 3] :=
        FPropuestas[i].TotalPorTraspasar;
      tvPropuestas.DataController.Values[i, 4] :=
        TextoEstadoPropuestaTraspaso(FPropuestas[i]);
      tvPropuestas.DataController.Values[i, 5] := Format('%d - %s', [
        FPropuestas[i].IdDocumento, FPropuestas[i].TituloDocumento]);
    end;
  finally
    tvPropuestas.EndUpdate;
  end;
  if Length(FPropuestas) > 0 then
    tvPropuestas.Controller.FocusedRecordIndex := 0;
  CargarLineas;
end;

function TfrmModalSeleccionPropuestaTraspaso.IndiceEnfocado: Integer;
begin
  Result := -1;
  if tvPropuestas.Controller.FocusedRecord <> nil then
    Result := tvPropuestas.Controller.FocusedRecord.RecordIndex;
  if Result > High(FPropuestas) then
    Result := -1;
end;

procedure TfrmModalSeleccionPropuestaTraspaso.CargarLineas;
var
  i, iPropuesta: Integer;
  Lineas: TLineasPropuestaTraspaso;
begin
  Lineas := nil;
  iPropuesta := IndiceEnfocado;
  if iPropuesta >= 0 then
    Lineas := FPropuestas[iPropuesta].Lineas;
  tvLineas.BeginUpdate;
  try
    tvLineas.DataController.RecordCount := Length(Lineas);
    for i := 0 to High(Lineas) do
    begin
      tvLineas.DataController.Values[i, 0] := Lineas[i].CodigoArticulo;
      tvLineas.DataController.Values[i, 1] := Lineas[i].DescripcionArticulo;
      tvLineas.DataController.Values[i, 2] := Lineas[i].Color;
      tvLineas.DataController.Values[i, 3] := Lineas[i].Talla;
      tvLineas.DataController.Values[i, 4] := Lineas[i].CantidadPorTraspasar;
    end;
  finally
    tvLineas.EndUpdate;
  end;
end;

procedure TfrmModalSeleccionPropuestaTraspaso.PropuestasFocoCambiado(
  Sender: TcxCustomGridTableView;
  APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  CargarLineas;
end;

procedure TfrmModalSeleccionPropuestaTraspaso.btnNoAceptarClick(
  Sender: TObject);
var
  iPropuesta: Integer;
  iIdPropuesta: Int64;
  sMotivo: string;
begin
  inherited;
  sMotivo := '';
  iPropuesta := IndiceEnfocado;
  if iPropuesta < 0 then
    ShowMessage_fza(SInfoSeleccionarPropuesta)
  else
  begin
    iIdPropuesta := FPropuestas[iPropuesta].IdPropuesta;
    if InputQuery_fza(
         Format(STituloNoAceptarPropuesta, [iIdPropuesta]),
         SPreguntaMotivoNoAceptarPropuesta, sMotivo) then
    begin
      if Trim(sMotivo) = '' then
        ShowMessage_fza(SErrorMotivoNoAceptarObligatorio)
      else
      begin
        // En una trasladada en parte, no aceptar lo que falta la cierra
        // con lo ya traspasado.
        if not FRepositorio.RechazarPropuesta(
             iIdPropuesta, Trim(sMotivo), FUsuario) then
          ShowMessage_fza(Format(
            SInfoPropuestaYaNoPendiente, [iIdPropuesta]))
        else if FPropuestas[iPropuesta].EstaTrasladadaParcial then
          ShowMessage_fza(Format(SInfoPropuestaParcialCerrada, [iIdPropuesta]))
        else
          ShowMessage_fza(Format(SInfoPropuestaNoAceptada, [iIdPropuesta]));
        CargarPropuestas;
      end;
    end;
  end;
end;

// sFicha lo fija el ancestro: 'S' con Aceptar o F12 y 'N' con Cancelar o
// ESC. Aceptar sin propuesta enfocada no cierra.
function TfrmModalSeleccionPropuestaTraspaso.CloseQuery: Boolean;
var
  iPropuesta: Integer;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    iPropuesta := IndiceEnfocado;
    Result := iPropuesta >= 0;
    if Result then
    begin
      FResultado.Cargar := True;
      FResultado.Propuesta := FPropuestas[iPropuesta];
      FResultado.Lineas := LineasCargaDePropuesta(FPropuestas[iPropuesta]);
    end
    else
    begin
      sFicha := 'N';
      ShowMessage_fza(SInfoSeleccionarPropuesta);
    end;
  end;
end;

end.
