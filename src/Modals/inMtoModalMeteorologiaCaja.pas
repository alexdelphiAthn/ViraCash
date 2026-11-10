{******************************************************************************}
{                                                                              }
{  Módulo: inMtoModalMeteorologiaCaja                                          }
{  Tipo: Formulario (Modal)                                                    }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Consulta y presentación del tiempo diario de la tienda.        }
{******************************************************************************}
unit inMtoModalMeteorologiaCaja;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.ExtCtrls,
  cxGroupBox, cxLabel, cxTextEdit, cxCalendar, cxButtons,
  cxGrid, cxGridTableView, cxGridCustomTableView, cxGraphics,
  inMtoFrmBase, inLibMeteorologiaCajaIntf, inLibMeteorologiaCajaTarea;

type
  TfrmModalMeteorologiaCaja = class(TfrmBase)
  private
    FCabecera: TcxGroupBox;
    FCiudad: TcxTextEdit;
    FDesde: TcxDateEdit;
    FHasta: TcxDateEdit;
    FBoton: TcxButton;
    FTemperatura: TcxLabel;
    FMaxima: TcxLabel;
    FMinima: TcxLabel;
    FCielo: TcxLabel;
    FLluvia: TcxLabel;
    FEstado: TcxLabel;
    FGrid: TcxGrid;
    FTabla: TcxGridTableView;
    FTemporizador: TTimer;
    FServicio: IServicioMeteorologiaCaja;
    FUbicacion: TUbicacionMeteorologiaCaja;
    FConsulta: IConsultaMeteorologiaCaja;
    FPartes: TPartesMeteorologiaCaja;
    function S(AValor: Integer): Integer;
    function Etiqueta(const ATexto: string; AX, AY, AAncho: Integer):
      TcxLabel;
    procedure CrearCabecera;
    procedure CrearResumen;
    procedure CrearTabla;
    procedure Consultar(Sender: TObject);
    procedure IniciarHistorico;
    procedure Recoger(Sender: TObject);
    procedure MostrarFilas;
    procedure SeleccionarDia(Sender: TcxCustomGridTableView;
      AAnterior, AActual: TcxCustomGridRecord; ACambio: Boolean);
    procedure MostrarResumen(AIndice: Integer);
    procedure PintarTemperatura(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AInfo: TcxGridTableDataCellViewInfo;
      var AHecho: Boolean);
  public
    destructor Destroy; override;
    class procedure Ejecutar(AOwner: TComponent;
      const AUbicacion: TUbicacionMeteorologiaCaja;
      const AServicio: IServicioMeteorologiaCaja);
  end;

implementation

uses
  System.DateUtils, Vcl.Forms, Winapi.Windows, Vcl.Graphics,
  cxContainer, cxEdit, cxGridLevel,
  inLibMeteorologiaCajaVcl, inLibMsgMeteorologiaCaja;

{$R *.dfm}

function Texto(const AValor: TValorMeteorologiaCaja): string;
begin
  Result := '—';
  if AValor.TieneValor then
    Result := FormatFloat('0.#', AValor.Valor);
end;

class procedure TfrmModalMeteorologiaCaja.Ejecutar(AOwner: TComponent;
  const AUbicacion: TUbicacionMeteorologiaCaja;
  const AServicio: IServicioMeteorologiaCaja);
var
  oVentana: TfrmModalMeteorologiaCaja;
begin
  oVentana := TfrmModalMeteorologiaCaja.Create(AOwner);
  try
    oVentana.FServicio := AServicio;
    oVentana.FUbicacion := AUbicacion;
    oVentana.CrearCabecera;
    oVentana.CrearTabla;
    oVentana.AplicarTraduccionActual;
    oVentana.ShowModal;
  finally
    FreeAndNil(oVentana);
  end;
end;

destructor TfrmModalMeteorologiaCaja.Destroy;
begin
  FreeAndNil(FTemporizador);
  if Assigned(FConsulta) then
    FConsulta.Cancelar;
  FConsulta := nil;
  inherited;
end;

function TfrmModalMeteorologiaCaja.S(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

function TfrmModalMeteorologiaCaja.Etiqueta(const ATexto: string;
  AX, AY, AAncho: Integer): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := FCabecera;
  Result.Caption := ATexto;
  Result.AutoSize := False;
  Result.SetBounds(S(AX), S(AY), S(AAncho), S(26));
  Result.Transparent := True;
  Result.ParentShowHint := False;
  Result.ShowHint := True;
end;

procedure TfrmModalMeteorologiaCaja.CrearCabecera;
var
  rRegional: TFormatSettings;
begin
  rRegional := TFormatSettings.Create;
  Caption := STituloHistoricoMeteoCaja;
  FCabecera := TcxGroupBox.Create(Self);
  FCabecera.Parent := Self;
  FCabecera.Align := alTop;
  FCabecera.Height := S(160);
  FCabecera.PanelStyle.Active := True;
  FCabecera.Style.BorderStyle := ebsNone;
  FCabecera.Transparent := True;
  Etiqueta(SCiudadHistoricoMeteoCaja, 12, 8, 280);
  Etiqueta(SDesdeHistoricoMeteoCaja, 310, 8, 160);
  Etiqueta(SHastaHistoricoMeteoCaja, 490, 8, 160);
  FCiudad := TcxTextEdit.Create(Self);
  FCiudad.Parent := FCabecera;
  FCiudad.SetBounds(S(12), S(34), S(280), S(28));
  FCiudad.Text := FUbicacion.Ciudad;
  FDesde := TcxDateEdit.Create(Self);
  FDesde.Parent := FCabecera;
  FDesde.SetBounds(S(310), S(34), S(160), S(28));
  FDesde.Date := StartOfTheMonth(Date);
  FDesde.Properties.DisplayFormat := rRegional.ShortDateFormat;
  FDesde.Properties.EditFormat := rRegional.ShortDateFormat;
  FDesde.Properties.UseDisplayFormatWhenEditing := True;
  FHasta := TcxDateEdit.Create(Self);
  FHasta.Parent := FCabecera;
  FHasta.SetBounds(S(490), S(34), S(160), S(28));
  FHasta.Date := Date;
  FHasta.Properties.DisplayFormat := rRegional.ShortDateFormat;
  FHasta.Properties.EditFormat := rRegional.ShortDateFormat;
  FHasta.Properties.UseDisplayFormatWhenEditing := True;
  FBoton := TcxButton.Create(Self);
  FBoton.Parent := FCabecera;
  FBoton.SetBounds(S(675), S(33), S(195), S(30));
  FBoton.Caption := SConsultarHistoricoMeteoCaja;
  FBoton.OnClick := Consultar;
  CrearResumen;
  FTemporizador := TTimer.Create(Self);
  FTemporizador.Enabled := False;
  FTemporizador.Interval := 150;
  FTemporizador.OnTimer := Recoger;
end;

procedure TfrmModalMeteorologiaCaja.CrearResumen;
begin
  FTemperatura := Etiqueta('🌡 — °C', 12, 87, 160);
  FMaxima := Etiqueta('MAX — °C', 178, 87, 100);
  FMinima := Etiqueta('MIN — °C', 280, 87, 100);
  FCielo := Etiqueta('☀ / ☁ —', 400, 87, 200);
  FLluvia := Etiqueta('🌧 — mm', 640, 87, 200);
  FTemperatura.Style.Font.Name := 'Segoe UI Emoji';
  FTemperatura.Style.Font.Height := -S(20);
  FMaxima.Style.Font.Height := -S(12);
  FMinima.Style.Font.Height := -S(12);
  FTemperatura.Height := S(36);
  FMaxima.Height := S(36);
  FMinima.Height := S(36);
  FTemperatura.Properties.Alignment.Vert := taVCenter;
  FMaxima.Properties.Alignment.Vert := taVCenter;
  FMinima.Properties.Alignment.Vert := taVCenter;
  FEstado := Etiqueta(SNotaHistoricoMeteoCaja, 12, 126, 870);
  FEstado.Hint := SNotaHistoricoMeteoCaja;
end;

procedure TfrmModalMeteorologiaCaja.CrearTabla;
var
  rTitulos: TArray<string>;
  iColumna: Integer;
  oColumna: TcxGridColumn;
begin
  rTitulos := TArray<string>.Create(SColFechaMeteoCaja, SColCieloMeteoCaja,
    SColMediaMeteoCaja, SColMaximaMeteoCaja, SColMinimaMeteoCaja,
    SColNubesMeteoCaja, SColLluviaMeteoCaja);
  FGrid := TcxGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FTabla := FGrid.CreateView(TcxGridTableView) as TcxGridTableView;
  FGrid.Levels.Add.GridView := FTabla;
  FTabla.OptionsData.Editing := False;
  FTabla.OptionsData.Inserting := False;
  FTabla.OptionsData.Deleting := False;
  FTabla.OptionsView.GroupByBox := False;
  FTabla.OptionsView.ColumnAutoWidth := True;
  FTabla.OptionsCustomize.ColumnSorting := False;
  for iColumna := 0 to High(rTitulos) do
  begin
    oColumna := FTabla.CreateColumn;
    oColumna.Caption := rTitulos[iColumna];
    oColumna.Width := S(120);
    oColumna.DataBinding.ValueType := 'String';
  end;
  FTabla.OnFocusedRecordChanged := SeleccionarDia;
  FTabla.OnCustomDrawCell := PintarTemperatura;
end;

procedure TfrmModalMeteorologiaCaja.Consultar(Sender: TObject);
begin
  try
    IniciarHistorico;
  except
    on E: EArgumentException do
    begin
      FEstado.Caption := E.Message;
      FEstado.Hint := E.Message;
    end;
  end;
end;

procedure TfrmModalMeteorologiaCaja.IniciarHistorico;
var
  rUbicacion: TUbicacionMeteorologiaCaja;
  oServicio: IServicioMeteorologiaCaja;
  dtDesde, dtHasta: TDateTime;
begin
  dtDesde := DateOf(FDesde.Date);
  dtHasta := DateOf(FHasta.Date);
  if dtDesde > dtHasta then
    raise EArgumentException.Create(SErrorRangoHistoricoMeteoCaja);
  if dtDesde < EncodeDate(1940, 1, 1) then
    raise EArgumentException.Create(SErrorInicioHistoricoMeteoCaja);
  if dtHasta > Date + 15 then
    raise EArgumentException.CreateFmt(SErrorFinPrevisionMeteoCaja,
      [DateToStr(Date + 15, TFormatSettings.Create)]);
  rUbicacion := FUbicacion;
  rUbicacion.Ciudad := Trim(FCiudad.Text);
  if not SameText(rUbicacion.Ciudad, FUbicacion.Ciudad) then
    rUbicacion.CodigoPostal := '';
  oServicio := FServicio;
  FPartes := nil;
  FTabla.DataController.RecordCount := 0;
  FTemperatura.Caption := '🌡 — °C';
  FMaxima.Caption := 'MAX — °C';
  FMinima.Caption := 'MIN — °C';
  FCielo.Caption := '☀ / ☁ —';
  FLluvia.Caption := '🌧 — mm';
  FConsulta := IniciarTareaMeteorologiaCaja(
    function(const ACancelar: TFunc<Boolean>): TPartesMeteorologiaCaja
    begin
      Result := oServicio.ConsultarHistorico(
        rUbicacion, dtDesde, dtHasta, ACancelar);
    end, RegistroLog);
  FBoton.Enabled := False;
  FCiudad.Enabled := False;
  FDesde.Enabled := False;
  FHasta.Enabled := False;
  FEstado.Caption := SEstadoConsultandoMeteoCaja;
  FTemporizador.Enabled := True;
end;

procedure TfrmModalMeteorologiaCaja.Recoger(Sender: TObject);
var
  rPartes: TPartesMeteorologiaCaja;
  sError: string;
begin
  if Assigned(FConsulta) and FConsulta.Obtener(rPartes, sError) then
  begin
    FConsulta := nil;
    FTemporizador.Enabled := False;
    FBoton.Enabled := True;
    FCiudad.Enabled := True;
    FDesde.Enabled := True;
    FHasta.Enabled := True;
    if sError = '' then
    begin
      FPartes := rPartes;
      MostrarFilas;
    end
    else
      FEstado.Caption := sError;
    FEstado.Hint := FEstado.Caption + #13#10 + SNotaHistoricoMeteoCaja;
  end;
end;

procedure TfrmModalMeteorologiaCaja.MostrarFilas;
var
  iDia: Integer;
begin
  FTabla.BeginUpdate;
  try
    FTabla.DataController.RecordCount := Length(FPartes);
  for iDia := 0 to High(FPartes) do
  begin
    FTabla.DataController.Values[iDia, 0] := DateToStr(FPartes[iDia].Fecha,
      TFormatSettings.Create);
    FTabla.DataController.Values[iDia, 1] := '☁';
    if FPartes[iDia].Nubes.TieneValor and
       (FPartes[iDia].Nubes.Valor < 20) then
      FTabla.DataController.Values[iDia, 1] := '☀';
    FTabla.DataController.Values[iDia, 2] := Texto(FPartes[iDia].Temperatura);
    FTabla.DataController.Values[iDia, 3] := Texto(FPartes[iDia].Maxima);
    FTabla.DataController.Values[iDia, 4] := Texto(FPartes[iDia].Minima);
    FTabla.DataController.Values[iDia, 5] := Texto(FPartes[iDia].Nubes);
    FTabla.DataController.Values[iDia, 6] := Texto(FPartes[iDia].Lluvia);
  end;
  finally
    FTabla.EndUpdate;
  end;
  if Length(FPartes) > 0 then
  begin
    FTabla.Controller.FocusedRecordIndex := 0;
    MostrarResumen(0);
  end;
end;

procedure TfrmModalMeteorologiaCaja.SeleccionarDia(
  Sender: TcxCustomGridTableView; AAnterior, AActual: TcxCustomGridRecord;
  ACambio: Boolean);
begin
  if Assigned(AActual) then
    MostrarResumen(AActual.RecordIndex);
end;

procedure TfrmModalMeteorologiaCaja.MostrarResumen(AIndice: Integer);
var
  rParte: TParteMeteorologiaCaja;
  oEtiqueta: TcxLabel;
begin
  if (AIndice >= 0) and (AIndice < Length(FPartes)) then
  begin
    rParte := FPartes[AIndice];
    FTemperatura.Caption := '🌡 ' + Texto(rParte.Temperatura) + ' °C';
    FMaxima.Caption := 'MAX ' + Texto(rParte.Maxima) + ' °C';
    FMinima.Caption := 'MIN ' + Texto(rParte.Minima) + ' °C';
    for oEtiqueta in TArray<TcxLabel>.Create(
      FTemperatura, FMaxima, FMinima) do
    begin
      oEtiqueta.Transparent := False;
      oEtiqueta.Style.Color := $00332017;
    end;
    FTemperatura.Style.TextColor := ColorTemperaturaMeteoCaja(
      rParte.Temperatura);
    FMaxima.Style.TextColor := ColorTemperaturaMeteoCaja(rParte.Maxima);
    FMinima.Style.TextColor := ColorTemperaturaMeteoCaja(rParte.Minima);
    FCielo.Caption := '☁ ' + Texto(rParte.Nubes) + ' %';
    if rParte.Nubes.TieneValor and (rParte.Nubes.Valor < 20) then
      FCielo.Caption := '☀ ' + Texto(rParte.Nubes) + ' %';
    FLluvia.Caption := '🌧 ' + Texto(rParte.Lluvia) + ' mm';
    FLluvia.Hint := Format(SHintLluviaHistoricoMeteoCaja,
      [Texto(rParte.Lluvia)]);
    FEstado.Caption := SFuenteHistoricoMeteoCaja;
    if rParte.TipoDato = 'PREVISION_DIARIA' then
      FEstado.Caption := SFuentePrevisionMeteoCaja;
    FEstado.Caption := DateToStr(rParte.Fecha,
      TFormatSettings.Create) + ' · ' + FEstado.Caption;
    FEstado.Hint := SNotaHistoricoMeteoCaja;
  end;
end;

procedure TfrmModalMeteorologiaCaja.PintarTemperatura(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
var
  iDia: Integer;
  rValor: TValorMeteorologiaCaja;
begin
  iDia := AInfo.GridRecord.RecordIndex;
  if (iDia >= 0) and (iDia < Length(FPartes)) and
     (AInfo.Item.Index >= 2) and (AInfo.Item.Index <= 4) then
  begin
    case AInfo.Item.Index of
      2: rValor := FPartes[iDia].Temperatura;
      3: rValor := FPartes[iDia].Maxima;
      4: rValor := FPartes[iDia].Minima;
    end;
    ACanvas.Brush.Color := $00332017;
    ACanvas.FillRect(AInfo.Bounds);
    ACanvas.Font.Color := ColorTemperaturaMeteoCaja(rValor);
    ACanvas.DrawText(AInfo.Text, AInfo.ContentBounds,
      cxAlignHCenter or cxAlignVCenter);
    AHecho := True;
  end;
end;

end.
