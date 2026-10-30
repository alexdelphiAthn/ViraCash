{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalMovimientoReparacion                                }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit inMtoModalMovimientoReparacion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, cxTextEdit, cxDropDownEdit,
  cxCalendar, cxMemo, inMtoModalAceptCancel, inLibReparacionesMovimientos;

type
  TfrmModalMovimientoReparacion = class(TfrmModalAceptCancel)
  private
    FMovimiento: TMovimientoReparacion;
    FFecha: TcxDateEdit;
    FOrigen: TcxTextEdit;
    FDestino: TcxTextEdit;
    FObjeto: TcxTextEdit;
    FEstado: TcxComboBox;
    FAgencia: TcxTextEdit;
    FTracking: TcxTextEdit;
    FIncidencia: TcxMemo;
    procedure Colocar(const ATitulo: string; AFila: Integer;
      AEditor: TControl);
    procedure CrearControles;
    procedure Recoger;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    function CloseQuery: Boolean; override;
    class function Ejecutar(AOwner: TComponent;
      var AMovimiento: TMovimientoReparacion): Boolean;
  end;

implementation

uses
  System.SysUtils, cxLabel, inLibMsgReparaciones, inLibMensajesVcl;

const
  ESTADOS: array[0..4] of string =
    ('ENVIADO', 'RECIBIDO', 'DEVUELTO', 'DEFECTUOSO', 'ANULADO');

procedure TfrmModalMovimientoReparacion.Colocar(const ATitulo: string;
  AFila: Integer; AEditor: TControl);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Transparent := True;
  oRotulo.Caption := ATitulo;
  oRotulo.SetBounds(ScaleValue(12), ScaleValue(12 + AFila * 34),
    ScaleValue(145), ScaleValue(24));
  AEditor.Parent := pnlBody;
  AEditor.SetBounds(ScaleValue(160), ScaleValue(12 + AFila * 34),
    ScaleValue(360), ScaleValue(26));
end;

procedure TfrmModalMovimientoReparacion.CrearControles;
begin
  FFecha := TcxDateEdit.Create(Self);
  Colocar(SMovimientoFecha, 0, FFecha);
  FFecha.Properties.Kind := ckDateTime;
  FFecha.Date := Now;
  FOrigen := TcxTextEdit.Create(Self);
  Colocar(SMovimientoOrigen, 1, FOrigen);
  FOrigen.Text := FMovimiento.Origen;
  FDestino := TcxTextEdit.Create(Self);
  Colocar(SMovimientoDestino, 2, FDestino);
  FDestino.Text := FMovimiento.Destino;
  FObjeto := TcxTextEdit.Create(Self);
  Colocar(SMovimientoObjeto, 3, FObjeto);
  FObjeto.Text := FMovimiento.Objeto;
  FEstado := TcxComboBox.Create(Self);
  Colocar(SMovimientoEstado, 4, FEstado);
  FEstado.Properties.DropDownListStyle := lsFixedList;
  FEstado.Properties.Items.Text := SMovimientoEstados;
  FEstado.ItemIndex := 0;
  FAgencia := TcxTextEdit.Create(Self);
  Colocar(SMovimientoAgencia, 5, FAgencia);
  FAgencia.Text := FMovimiento.Agencia;
  FTracking := TcxTextEdit.Create(Self);
  Colocar(SMovimientoTracking, 6, FTracking);
  FTracking.Text := FMovimiento.Seguimiento;
  FIncidencia := TcxMemo.Create(Self);
  Colocar(SMovimientoIncidencia, 7, FIncidencia);
  FIncidencia.Height := ScaleValue(90);
  FIncidencia.Properties.MaxLength := 2000;
end;

procedure TfrmModalMovimientoReparacion.Recoger;
begin
  FMovimiento.Instante := FFecha.Date;
  FMovimiento.Origen := FOrigen.Text;
  FMovimiento.Destino := FDestino.Text;
  FMovimiento.Objeto := FObjeto.Text;
  FMovimiento.Estado := '';
  if FEstado.ItemIndex >= 0 then
    FMovimiento.Estado := ESTADOS[FEstado.ItemIndex];
  FMovimiento.Agencia := FAgencia.Text;
  FMovimiento.Seguimiento := FTracking.Text;
  FMovimiento.Incidencia := FIncidencia.Text;
end;

function TfrmModalMovimientoReparacion.CloseQuery: Boolean;
var
  sError: string;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    Recoger;
    sError := ValidarMovimientoReparacion(FMovimiento);
    Result := sError = '';
    if not Result then
    begin
      sFicha := 'N';
      ShowMessage_fza(sError);
    end;
  end;
end;

procedure TfrmModalMovimientoReparacion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalMovimientoReparacion.Ejecutar(AOwner: TComponent;
  var AMovimiento: TMovimientoReparacion): Boolean;
var
  oFormulario: TfrmModalMovimientoReparacion;
begin
  oFormulario := TfrmModalMovimientoReparacion.Create(AOwner);
  try
    oFormulario.Caption := SMovimientoNuevo;
    oFormulario.FMovimiento := AMovimiento;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.ClientWidth := oFormulario.ScaleValue(540);
    oFormulario.ClientHeight := oFormulario.ScaleValue(360) +
      oFormulario.pnlButton.Height;
    oFormulario.CrearControles;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
    if Result then
      AMovimiento := oFormulario.FMovimiento;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
