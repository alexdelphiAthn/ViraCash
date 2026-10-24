{******************************************************************************}
{                                                                              }
{  Módulo:       inLibIndicadoresColasVcl                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Siglas de las colas activas con color y último evento en el hint.         }
{******************************************************************************}
unit inLibIndicadoresColasVcl;

interface

uses
  System.Classes, System.SysUtils, System.Types, Vcl.ComCtrls,
  Vcl.ExtCtrls, Vcl.Controls,
  inLibEstadoColasIntf;

type
  TIndicadoresColasVcl = class(TComponent)
  private
    FBarra: TStatusBar;
    FTemporizador: TTimer;
    FConsultar: TConsultarEstadosColas;
    FAjustar: TProc;
    FAbrirCola: TProc<TTipoColaEstado>;
    FEstados: TEstadosColas;
    FPaneles: array[TTipoColaEstado] of TStatusPanel;
    FPanelFinal: TStatusPanel;
    FDibujarAnterior: TDrawPanelEvent;
    FMouseMoveAnterior: TMouseMoveEvent;
    FMouseDownAnterior: TMouseEvent;
    FHintAnterior: string;
    FShowHintAnterior: Boolean;
    FParentShowHintAnterior: Boolean;
    procedure Refrescar(Sender: TObject);
    procedure ReconstruirPaneles;
    procedure DibujarPanel(ABarra: TStatusBar; APanel: TStatusPanel;
      const ARect: TRect);
    procedure MoverRaton(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PulsarRaton(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    function ColaEnPosicion(const APosicion: TPoint;
      out ATipo: TTipoColaEstado): Boolean;
    procedure ActualizarHint(const APosicion: TPoint);
    function HintCola(ATipo: TTipoColaEstado): string;
  public
    class function CrearBarra(AFormulario: TWinControl;
      const AConsultar: TConsultarEstadosColas): TIndicadoresColasVcl;
    constructor Create(AOwner: TComponent; ABarra: TStatusBar;
      const AConsultar: TConsultarEstadosColas;
      const AAjustar: TProc;
      const AAbrirCola: TProc<TTipoColaEstado> = nil;
      APanelFinal: TStatusPanel = nil); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  Winapi.Windows, Winapi.CommCtrl, Vcl.Graphics, Vcl.Forms,
  inLibMsgIntegraciones;

const
  CSiglasColas: array[TTipoColaEstado] of string = ('WS', 'AEAT', 'PS');
  CColoresColas: array[TActividadCola] of TColor =
    (clGreen, clBlue, clRed);

class function TIndicadoresColasVcl.CrearBarra(
  AFormulario: TWinControl;
  const AConsultar: TConsultarEstadosColas): TIndicadoresColasVcl;
var
  oBarra: TStatusBar;
  oPanelFinal: TStatusPanel;
begin
  oBarra := TStatusBar.Create(AFormulario);
  oBarra.Parent := AFormulario;
  oBarra.Align := alBottom;
  oBarra.SizeGrip := False;
  oBarra.Visible := False;
  oBarra.ParentFont := False;
  oBarra.Font.Name := 'Segoe UI';
  oBarra.Font.Height := -MulDiv(12, AFormulario.CurrentPPI, 96);
  oBarra.Height := MulDiv(24, AFormulario.CurrentPPI, 96);
  oPanelFinal := oBarra.Panels.Add;
  Result := TIndicadoresColasVcl.Create(AFormulario, oBarra, AConsultar,
    procedure
    var
      iPanel: Integer;
    begin
      oBarra.Canvas.Font.Assign(oBarra.Font);
      for iPanel := 0 to oBarra.Panels.Count - 2 do
        oBarra.Panels[iPanel].Width :=
          oBarra.Canvas.TextWidth(oBarra.Panels[iPanel].Text) +
          MulDiv(16, oBarra.CurrentPPI, 96);
      oBarra.Visible := oBarra.Panels.Count > 1;
    end, nil, oPanelFinal);
end;

constructor TIndicadoresColasVcl.Create(AOwner: TComponent;
  ABarra: TStatusBar; const AConsultar: TConsultarEstadosColas;
  const AAjustar: TProc; const AAbrirCola: TProc<TTipoColaEstado>;
  APanelFinal: TStatusPanel);
begin
  inherited Create(AOwner);
  FBarra := ABarra;
  FConsultar := AConsultar;
  FAjustar := AAjustar;
  FAbrirCola := AAbrirCola;
  FPanelFinal := APanelFinal;
  FDibujarAnterior := FBarra.OnDrawPanel;
  FMouseMoveAnterior := FBarra.OnMouseMove;
  FMouseDownAnterior := FBarra.OnMouseDown;
  FHintAnterior := FBarra.Hint;
  FShowHintAnterior := FBarra.ShowHint;
  FParentShowHintAnterior := FBarra.ParentShowHint;
  FBarra.OnDrawPanel := DibujarPanel;
  FBarra.OnMouseMove := MoverRaton;
  FBarra.OnMouseDown := PulsarRaton;
  FBarra.ParentShowHint := False;
  FBarra.ShowHint := True;
  FTemporizador := TTimer.Create(Self);
  FTemporizador.Interval := 200;
  FTemporizador.OnTimer := Refrescar;
  Refrescar(nil);
end;

destructor TIndicadoresColasVcl.Destroy;
var
  eCola: TTipoColaEstado;
begin
  FreeAndNil(FTemporizador);
  if Assigned(FBarra) then
  begin
    FBarra.OnDrawPanel := FDibujarAnterior;
    FBarra.OnMouseMove := FMouseMoveAnterior;
    FBarra.OnMouseDown := FMouseDownAnterior;
    FBarra.Hint := FHintAnterior;
    FBarra.ShowHint := FShowHintAnterior;
    FBarra.ParentShowHint := FParentShowHintAnterior;
    for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
      FreeAndNil(FPaneles[eCola]);
  end;
  FConsultar := nil;
  FAjustar := nil;
  FAbrirCola := nil;
  inherited;
end;

procedure TIndicadoresColasVcl.Refrescar(Sender: TObject);
var
  aEstados: TEstadosColas;
  eCola: TTipoColaEstado;
  bCambianPaneles: Boolean;
  bCambianColores: Boolean;
  oPosicion: TPoint;
begin
  aEstados := FConsultar();
  bCambianPaneles := False;
  bCambianColores := False;
  for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
  begin
    bCambianPaneles := bCambianPaneles or
      (FEstados[eCola].Activa <> aEstados[eCola].Activa);
    bCambianColores := bCambianColores or
      (FEstados[eCola].Actividad <> aEstados[eCola].Actividad);
  end;
  FEstados := aEstados;
  if bCambianPaneles then
    ReconstruirPaneles;
  if bCambianColores then
    FBarra.Invalidate;
  GetCursorPos(oPosicion);
  oPosicion := FBarra.ScreenToClient(oPosicion);
  if PtInRect(FBarra.ClientRect, oPosicion) then
    ActualizarHint(oPosicion);
end;

procedure TIndicadoresColasVcl.ReconstruirPaneles;
var
  eCola: TTipoColaEstado;
begin
  FBarra.Panels.BeginUpdate;
  try
    for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
      FreeAndNil(FPaneles[eCola]);
    for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
    begin
      FPaneles[eCola] := nil;
      if FEstados[eCola].Activa then
      begin
        FPaneles[eCola] := FBarra.Panels.Add;
        if Assigned(FPanelFinal) then
          FPaneles[eCola].Index := FPanelFinal.Index;
        FPaneles[eCola].Style := psOwnerDraw;
        FPaneles[eCola].Text := ' ' + CSiglasColas[eCola] + ' ';
      end;
    end;
  finally
    FBarra.Panels.EndUpdate;
  end;
  FAjustar();
end;

procedure TIndicadoresColasVcl.DibujarPanel(ABarra: TStatusBar;
  APanel: TStatusPanel; const ARect: TRect);
var
  eCola: TTipoColaEstado;
  oRect: TRect;
  iModoFondo: Integer;
begin
  if Assigned(FDibujarAnterior) then
    FDibujarAnterior(ABarra, APanel, ARect);
  for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
    if APanel = FPaneles[eCola] then
    begin
      ABarra.Canvas.Font.Assign(ABarra.Font);
      ABarra.Canvas.Font.Color := CColoresColas[FEstados[eCola].Actividad];
      oRect := ARect;
      if oRect.Width > APanel.Width then
        oRect.Right := oRect.Left + APanel.Width;
      iModoFondo := SetBkMode(ABarra.Canvas.Handle, TRANSPARENT);
      DrawText(ABarra.Canvas.Handle, PChar(CSiglasColas[eCola]), -1,
        oRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
      SetBkMode(ABarra.Canvas.Handle, iModoFondo);
      ABarra.Canvas.Font.Assign(ABarra.Font);
    end;
end;

function TIndicadoresColasVcl.HintCola(ATipo: TTipoColaEstado): string;
var
  sNombre: string;
  sEstado: string;
begin
  case ATipo of
    tceWs: sNombre := SColaNombreWs;
    tceHacienda: sNombre := SColaNombreHacienda;
    tcePrestaShop: sNombre := SColaNombrePrestaShop;
  end;
  case FEstados[ATipo].Actividad of
    acCorrecta: sEstado := SColaEstadoCorrecto;
    acOcupada: sEstado := SColaEstadoOcupado;
    acIncidencia: sEstado := SColaEstadoIncidencia;
  end;
  Result := Format(SColaHintEstado,
    [sNombre, FEstados[ATipo].HorasIncidencias, sEstado]) + sLineBreak +
    Format(SColaHintUltimoEvento, [
      FormatDateTime('dd/mm/yyyy hh:nn:ss', FEstados[ATipo].Instante),
      FEstados[ATipo].UltimoEvento]);
  if (FEstados[ATipo].Incidencia <> '') and
     (FEstados[ATipo].Incidencia <> FEstados[ATipo].UltimoEvento) then
    Result := Result + sLineBreak +
      Format(SColaHintIncidencia, [FEstados[ATipo].Incidencia]);
  Result := StringReplace(Result, '|', '/', [rfReplaceAll]);
  if Assigned(FAbrirCola) then
    Result := Result + sLineBreak + SColaHintAbrir;
end;

procedure TIndicadoresColasVcl.ActualizarHint(const APosicion: TPoint);
var
  iPanel: Integer;
  oRectPanel: TRect;
  eCola: TTipoColaEstado;
  sHint: string;
begin
  sHint := FHintAnterior;
  for iPanel := 0 to FBarra.Panels.Count - 1 do
  begin
    SendMessage(FBarra.Handle, SB_GETRECT, iPanel, LPARAM(@oRectPanel));
    if PtInRect(oRectPanel, APosicion) then
      for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
        if FBarra.Panels[iPanel] = FPaneles[eCola] then
          sHint := HintCola(eCola);
  end;
  if FBarra.Hint <> sHint then
  begin
    Application.CancelHint;
    FBarra.Hint := sHint;
  end;
end;

procedure TIndicadoresColasVcl.MoverRaton(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(FMouseMoveAnterior) then
    FMouseMoveAnterior(Sender, Shift, X, Y);
  ActualizarHint(Point(X, Y));
end;

function TIndicadoresColasVcl.ColaEnPosicion(const APosicion: TPoint;
  out ATipo: TTipoColaEstado): Boolean;
var
  eCola: TTipoColaEstado;
  oRectPanel: TRect;
begin
  Result := False;
  ATipo := Low(TTipoColaEstado);
  for eCola := Low(TTipoColaEstado) to High(TTipoColaEstado) do
    if Assigned(FPaneles[eCola]) then
      if SendMessage(FBarra.Handle, SB_GETRECT,
        FPaneles[eCola].Index, LPARAM(@oRectPanel)) <> 0 then
      begin
        // El último panel nativo se extiende hasta el borde de la barra;
        // solo responde la zona donde se dibujan las siglas.
        if oRectPanel.Width > FPaneles[eCola].Width then
          oRectPanel.Right := oRectPanel.Left + FPaneles[eCola].Width;
        if PtInRect(oRectPanel, APosicion) then
        begin
          ATipo := eCola;
          Result := True;
        end;
      end;
end;

procedure TIndicadoresColasVcl.PulsarRaton(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  eCola: TTipoColaEstado;
begin
  if Assigned(FMouseDownAnterior) then
    FMouseDownAnterior(Sender, Button, Shift, X, Y);
  if (Button = mbLeft) and (ssDouble in Shift) and
     Assigned(FAbrirCola) and ColaEnPosicion(Point(X, Y), eCola) then
  begin
    Application.CancelHint;
    FAbrirCola(eCola);
  end;
end;

end.
