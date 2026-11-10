{******************************************************************************}
{                                                                              }
{  Módulo: inLibMeteorologiaCajaVcl                                            }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Consulta y presentación del tiempo diario de la tienda.        }
{******************************************************************************}
unit inLibMeteorologiaCajaVcl;

interface

uses
  System.Classes, Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics,
  cxGroupBox, cxLabel, inLibMeteorologiaCajaIntf,
  inLibMeteorologiaCajaTarea, inLibLogIntf;

type
  TIndicadorMeteorologiaCaja = class(TComponent)
  private
    FPanel: TcxGroupBox;
    FMeteo: TcxLabel;
    FPluma: TcxLabel;
    FTemperatura: TcxLabel;
    FMaxima: TcxLabel;
    FMinima: TcxLabel;
    FNubes: TcxLabel;
    FLluvia: TcxLabel;
    FTemporizador: TTimer;
    FRepositorio: IRepositorioMeteorologiaCaja;
    FServicio: IServicioMeteorologiaCaja;
    FRegistro: IRegistroLog;
    FConsulta: IConsultaMeteorologiaCaja;
    FUbicacion: TUbicacionMeteorologiaCaja;
    FEmpresa: string;
    FAlmacen: string;
    FFechaParte: TDateTime;
    FAlAbrirHistorico: TNotifyEvent;
    FAlEditarObservaciones: TNotifyEvent;
    function CrearEtiqueta(const ANombre: string): TcxLabel;
    procedure CrearControles(AContenedor: TWinControl);
    procedure PulsarMeteo(Sender: TObject);
    procedure DobleClickMeteo(Sender: TObject);
    procedure EditarObservaciones(Sender: TObject);
    procedure Consultar;
    procedure RecogerConsulta(Sender: TObject);
    procedure GuardarYMostrar(const AParte: TParteMeteorologiaCaja);
    procedure MostrarParte(const AParte: TParteMeteorologiaCaja);
    procedure MostrarError(const AMensaje: string);
    procedure Limpiar;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AContenedor: TWinControl;
      const ARepositorio: IRepositorioMeteorologiaCaja;
      const AServicio: IServicioMeteorologiaCaja;
      const ARegistro: IRegistroLog); reintroduce;
    destructor Destroy; override;
    procedure Ubicar(ALeft, ATop, AWidth, AHeight: Integer);
    procedure EstablecerAlmacen(const AEmpresa, AAlmacen: string);
    property AlEditarObservaciones: TNotifyEvent
      read FAlEditarObservaciones write FAlEditarObservaciones;
    property AlAbrirHistorico: TNotifyEvent read FAlAbrirHistorico
      write FAlAbrirHistorico;
  end;

function ColorTemperaturaMeteoCaja(
  const ATemperatura: TValorMeteorologiaCaja): TColor;

implementation

uses
  System.SysUtils, Winapi.Windows, cxContainer, cxEdit, cxGraphics,
  inLibMsgMeteorologiaCaja;

function TextoValor(const AValor: TValorMeteorologiaCaja): string;
begin
  Result := '—';
  if AValor.TieneValor then
    Result := FormatFloat('0.#', AValor.Valor);
end;

function ColorTemperaturaMeteoCaja(
  const ATemperatura: TValorMeteorologiaCaja): TColor;
begin
  Result := clGrayText;
  if ATemperatura.TieneValor then
  begin
    if ATemperatura.Valor < 0 then
      Result := clWhite
    else if ATemperatura.Valor < 4 then
      Result := $00FAa560
    else if ATemperatura.Valor > 30 then
      Result := $007171F8
    else
      Result := $0080DE4A;
  end;
end;

constructor TIndicadorMeteorologiaCaja.Create(AContenedor: TWinControl;
  const ARepositorio: IRepositorioMeteorologiaCaja;
  const AServicio: IServicioMeteorologiaCaja; const ARegistro: IRegistroLog);
begin
  inherited Create(AContenedor);
  FRepositorio := ARepositorio;
  FServicio := AServicio;
  FRegistro := ARegistro;
  CrearControles(AContenedor);
  FTemporizador := TTimer.Create(Self);
  FTemporizador.Enabled := False;
  FTemporizador.Interval := 150;
  FTemporizador.OnTimer := RecogerConsulta;
  Limpiar;
end;

destructor TIndicadorMeteorologiaCaja.Destroy;
begin
  FreeAndNil(FTemporizador);
  if Assigned(FConsulta) then
    FConsulta.Cancelar;
  FConsulta := nil;
  FreeAndNil(FPanel);
  inherited;
end;

procedure TIndicadorMeteorologiaCaja.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FPanel) then
    FPanel := nil;
end;

function TIndicadorMeteorologiaCaja.CrearEtiqueta(
  const ANombre: string): TcxLabel;
begin
  Result := TcxLabel.Create(FPanel);
  Result.Name := ANombre;
  Result.Parent := FPanel;
  Result.AutoSize := False;
  Result.Transparent := True;
  Result.ParentFont := False;
  Result.Style.BorderStyle := ebsNone;
  Result.Style.Font.Name := 'Segoe UI Emoji';
  Result.Style.Font.Height := -MulDiv(11, FPanel.CurrentPPI, 96);
  Result.Properties.Alignment.Vert := taVCenter;
  Result.Properties.Alignment.Horz := taCenter;
  Result.Properties.WordWrap := False;
  Result.ParentShowHint := False;
  Result.ShowHint := True;
end;

procedure TIndicadorMeteorologiaCaja.CrearControles(
  AContenedor: TWinControl);
begin
  FPanel := TcxGroupBox.Create(Self);
  FPanel.FreeNotification(Self);
  FPanel.Parent := AContenedor;
  FPanel.PanelStyle.Active := True;
  FPanel.Style.BorderStyle := ebsNone;
  FPanel.Transparent := True;
  FMeteo := CrearEtiqueta('lblConsultarMeteo');
  FMeteo.Cursor := crHandPoint;
  FMeteo.Style.Font.Name := 'Segoe UI';
  FMeteo.Style.Font.Height := -MulDiv(12, FPanel.CurrentPPI, 96);
  FMeteo.Style.Font.Style := [fsBold];
  FMeteo.OnClick := PulsarMeteo;
  FMeteo.OnDblClick := DobleClickMeteo;
  FPluma := CrearEtiqueta('lblObservacionesDiaCaja');
  FPluma.Caption := '🖋';
  FPluma.Cursor := crHandPoint;
  FPluma.Hint := SHintObservacionesCaja;
  FPluma.Style.Font.Height := -MulDiv(16, FPanel.CurrentPPI, 96);
  FPluma.OnClick := EditarObservaciones;
  FTemperatura := CrearEtiqueta('lblTemperaturaMeteo');
  FMaxima := CrearEtiqueta('lblMaximaMeteo');
  FMinima := CrearEtiqueta('lblMinimaMeteo');
  FMaxima.Style.Font.Height := -MulDiv(10, FPanel.CurrentPPI, 96);
  FMinima.Style.Font.Height := FMaxima.Style.Font.Height;
  FNubes := CrearEtiqueta('lblNubesMeteo');
  FLluvia := CrearEtiqueta('lblLluviaMeteo');
end;

procedure TIndicadorMeteorologiaCaja.Ubicar(
  ALeft, ATop, AWidth, AHeight: Integer);
var
  iFila, iAncho, iTercio, iPluma: Integer;
begin
  FPanel.SetBounds(ALeft, ATop, AWidth, AHeight);
  iFila := AHeight div 3;
  iAncho := FPanel.ClientWidth;
  iTercio := (iAncho * 38) div 100;
  iPluma := MulDiv(28, FPanel.CurrentPPI, 96);
  FMeteo.SetBounds(0, 0, iAncho - iPluma, iFila);
  FPluma.SetBounds(iAncho - iPluma, 0, iPluma, iFila);
  FTemperatura.SetBounds(0, iFila, iTercio, iFila);
  FMaxima.SetBounds(iTercio, iFila, (iAncho - iTercio) div 2, iFila);
  FMinima.SetBounds(FMaxima.BoundsRect.Right, iFila,
    iAncho - FMaxima.BoundsRect.Right, iFila);
  FNubes.SetBounds(0, 2 * iFila, iAncho div 2, iFila);
  FLluvia.SetBounds(iAncho div 2, 2 * iFila, iAncho - iAncho div 2, iFila);
end;

procedure TIndicadorMeteorologiaCaja.Limpiar;
begin
  FFechaParte := 0;
  FMeteo.Caption := SCaptionMeteoCaja;
  FMeteo.Hint := SHintConsultarMeteoCaja;
  FMeteo.Enabled := True;
  FTemperatura.Visible := False;
  FMaxima.Visible := False;
  FMinima.Visible := False;
  FNubes.Visible := False;
  FLluvia.Visible := False;
end;

procedure TIndicadorMeteorologiaCaja.EstablecerAlmacen(
  const AEmpresa, AAlmacen: string);
begin
  if (FEmpresa <> AEmpresa) or (FAlmacen <> AAlmacen) then
  begin
    if Assigned(FConsulta) then
      FConsulta.Cancelar;
    FConsulta := nil;
    FTemporizador.Enabled := False;
    FEmpresa := AEmpresa;
    FAlmacen := AAlmacen;
    Limpiar;
  end;
end;

procedure TIndicadorMeteorologiaCaja.PulsarMeteo(Sender: TObject);
begin
  Consultar;
end;

procedure TIndicadorMeteorologiaCaja.DobleClickMeteo(Sender: TObject);
begin
  if Assigned(FAlAbrirHistorico) then
    FAlAbrirHistorico(Self);
end;

procedure TIndicadorMeteorologiaCaja.EditarObservaciones(Sender: TObject);
begin
  if Assigned(FAlEditarObservaciones) then
    FAlEditarObservaciones(Self);
end;

procedure TIndicadorMeteorologiaCaja.Consultar;
begin
  if not Assigned(FConsulta) then
  begin
    Limpiar;
    try
      FUbicacion := FRepositorio.LeerUbicacion(FEmpresa, FAlmacen);
      FConsulta := IniciarConsultaMeteorologiaCaja(
        FServicio, FUbicacion, FRegistro);
      FMeteo.Caption := SEstadoConsultandoMeteoCaja;
      FTemporizador.Interval := 150;
      FTemporizador.Enabled := True;
    except
      on E: Exception do
        MostrarError(E.Message);
    end;
  end;
end;

procedure TIndicadorMeteorologiaCaja.RecogerConsulta(Sender: TObject);
var
  rPartes: TPartesMeteorologiaCaja;
  sError: string;
begin
  if (FFechaParte <> 0) and (FFechaParte <> Date) then
    Limpiar;
  if Assigned(FConsulta) and FConsulta.Obtener(rPartes, sError) then
  begin
    FTemporizador.Enabled := False;
    FConsulta := nil;
    FMeteo.Enabled := True;
    if (sError = '') and (Length(rPartes) = 1) then
      GuardarYMostrar(rPartes[0])
    else
      MostrarError(sError);
    FTemporizador.Interval := 1000;
    FTemporizador.Enabled := FFechaParte <> 0;
  end;
end;

procedure TIndicadorMeteorologiaCaja.GuardarYMostrar(
  const AParte: TParteMeteorologiaCaja);
begin
  try
    FRepositorio.Guardar(FUbicacion, AParte);
    MostrarParte(AParte);
  except
    on E: Exception do
      MostrarError(Format(SErrorGuardarMeteoCaja, [E.Message]));
  end;
end;

procedure TIndicadorMeteorologiaCaja.MostrarError(const AMensaje: string);
begin
  Limpiar;
  FMeteo.Caption := SCaptionMeteoCaja + ' · ' + SEstadoErrorMeteoCaja;
  FMeteo.Hint := AMensaje;
  FRegistro.RegistrarAviso('METEO: ' + AMensaje);
end;

procedure TIndicadorMeteorologiaCaja.MostrarParte(
  const AParte: TParteMeteorologiaCaja);
var
  sCielo: string;
begin
  FFechaParte := AParte.Fecha;
  FMeteo.Caption := SCaptionMeteoCaja;
  FMeteo.Hint := Format(SHintFuenteMeteoCaja,
    [AParte.Ciudad, DateToStr(AParte.Fecha)]);
  FTemperatura.Caption := '🌡 ' + TextoValor(AParte.Temperatura) + '°C';
  FTemperatura.Transparent := False;
  FTemperatura.Style.Color := $00332017;
  FTemperatura.Style.TextColor := ColorTemperaturaMeteoCaja(
    AParte.Temperatura);
  FTemperatura.Hint := Format(SHintTemperaturaMeteoCaja,
    [TextoValor(AParte.Minima), TextoValor(AParte.Maxima)]);
  FMaxima.Caption := 'MAX ' + TextoValor(AParte.Maxima) + '°';
  FMinima.Caption := 'MIN ' + TextoValor(AParte.Minima) + '°';
  FMaxima.Style.TextColor := ColorTemperaturaMeteoCaja(AParte.Maxima);
  FMinima.Style.TextColor := ColorTemperaturaMeteoCaja(AParte.Minima);
  FMaxima.Transparent := False;
  FMinima.Transparent := False;
  FMaxima.Style.Color := FTemperatura.Style.Color;
  FMinima.Style.Color := FTemperatura.Style.Color;
  FMaxima.Hint := FTemperatura.Hint;
  FMinima.Hint := FTemperatura.Hint;
  sCielo := '☁';
  if AParte.Nubes.TieneValor and (AParte.Nubes.Valor < 20) then
    sCielo := '☀'
  else if AParte.Nubes.TieneValor and (AParte.Nubes.Valor < 70) then
    sCielo := '🌤';
  FNubes.Caption := sCielo + ' ' + TextoValor(AParte.Nubes) + '%';
  FNubes.Hint := Format(SHintNubesMeteoCaja, [TextoValor(AParte.Nubes)]);
  FLluvia.Caption := '🌧 ' + TextoValor(AParte.Lluvia) + ' mm';
  FLluvia.Hint := Format(SHintLluviaMeteoCaja, [TextoValor(AParte.Lluvia)]);
  FTemperatura.Visible := True;
  FMaxima.Visible := True;
  FMinima.Visible := True;
  FNubes.Visible := True;
  FLluvia.Visible := True;
end;

end.
