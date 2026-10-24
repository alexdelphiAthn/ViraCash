{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalPreciosTarifaSesion                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Antes de materializar una sesión de compra, resume las filas de tarifa    }
{    que se van a grabar y, si algún artículo ya tiene precio, pregunta si se  }
{    modifica o se crea una tarifa nueva desde una fecha (FZ-ISSUE-638).       }
{******************************************************************************}
unit inMtoModalPreciosTarifaSesion;

interface

uses
  System.Classes, Vcl.Forms, cxMemo, cxRadioGroup, cxCalendar,
  inMtoModalAceptCancel,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPreciosTalla;

type
  TfrmModalPreciosTarifaSesion = class(TfrmModalAceptCancel)
  private
    FTarifa: string;
    FPrecios: TArticulosPreciosTarifa;
    FOpciones: TOpcionesTarifaSesion;
    FResumen: TcxMemo;
    FModificar: TcxRadioButton;
    FNueva: TcxRadioButton;
    FFecha: TcxDateEdit;
    function HayVigentes: Boolean;
    function TextoArticulosVigentes: string;
    procedure CrearResumen;
    procedure CrearOpciones;
    procedure CambiarModo(Sender: TObject);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
  public
    constructor CreatePrecios(AOwner: TComponent; const ATarifa: string;
      const APrecios: TArticulosPreciosTarifa;
      const AOpciones: TOpcionesTarifaSesion);
    function CloseQuery: Boolean; override;
    class function Confirmar(AOwner: TComponent; const ATarifa: string;
      const APrecios: TArticulosPreciosTarifa;
      var AOpciones: TOpcionesTarifaSesion): Boolean;
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Controls, Vcl.Graphics,
  Vcl.StdCtrls, cxGroupBox, cxLabel,
  inLibMensajesVcl, inLibMsgCompras;

constructor TfrmModalPreciosTarifaSesion.CreatePrecios(AOwner: TComponent;
  const ATarifa: string; const APrecios: TArticulosPreciosTarifa;
  const AOpciones: TOpcionesTarifaSesion);
begin
  inherited Create(AOwner);
  FTarifa := ATarifa;
  FPrecios := Copy(APrecios);
  FOpciones := AOpciones;
  OnClose := CerrarSinLiberar;
  ClientWidth := ScaleValue(760);
  ClientHeight := ScaleValue(480);
  if HayVigentes then
    CrearOpciones;
  CrearResumen;
end;

procedure TfrmModalPreciosTarifaSesion.DoCreate;
begin
  inherited;
  Caption := STituloConfirmarPreciosTarifa;
end;

function TfrmModalPreciosTarifaSesion.HayVigentes: Boolean;
var
  oArticulo: TArticuloPreciosTarifa;
begin
  Result := False;
  for oArticulo in FPrecios do
    Result := Result or oArticulo.TieneVigentes;
end;

function TfrmModalPreciosTarifaSesion.TextoArticulosVigentes: string;
var
  oArticulo: TArticuloPreciosTarifa;
begin
  Result := '';
  for oArticulo in FPrecios do
    if oArticulo.TieneVigentes then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + oArticulo.CodigoArticulo;
    end;
end;

procedure TfrmModalPreciosTarifaSesion.CrearResumen;
var
  oCabecera: TcxLabel;
  oArticulo: TArticuloPreciosTarifa;
begin
  oCabecera := TcxLabel.Create(Self);
  oCabecera.Parent := pnlBody;
  oCabecera.Align := alTop;
  oCabecera.Caption := Format(SCabeceraConfirmarPreciosTarifa, [FTarifa]);
  oCabecera.Style.Font.Style := [fsBold];
  FResumen := TcxMemo.Create(Self);
  FResumen.Parent := pnlBody;
  FResumen.Align := alClient;
  FResumen.Properties.ReadOnly := True;
  FResumen.Properties.ScrollBars := ssVertical;
  FResumen.Properties.WordWrap := True;
  FResumen.Lines.BeginUpdate;
  try
    for oArticulo in FPrecios do
      FResumen.Lines.Add(ResumenFilasPrecioTarifa(oArticulo));
  finally
    FResumen.Lines.EndUpdate;
  end;
end;

procedure TfrmModalPreciosTarifaSesion.CrearOpciones;
var
  oGrupo: TcxGroupBox;
  oAviso: TcxLabel;
begin
  oGrupo := TcxGroupBox.Create(Self);
  oGrupo.Parent := pnlBody;
  oGrupo.Align := alBottom;
  oGrupo.Height := ScaleValue(118);
  oGrupo.PanelStyle.Active := True;
  oAviso := TcxLabel.Create(Self);
  oAviso.Parent := oGrupo;
  oAviso.Caption := Format(SAvisoArticulosConTarifaVigente,
    [TextoArticulosVigentes]);
  oAviso.Properties.WordWrap := True;
  oAviso.SetBounds(ScaleValue(8), ScaleValue(6), ScaleValue(740),
    ScaleValue(40));
  FModificar := TcxRadioButton.Create(Self);
  FModificar.Parent := oGrupo;
  FModificar.Caption := SOpcionTarifaModificarVigente;
  FModificar.SetBounds(ScaleValue(8), ScaleValue(50), ScaleValue(400),
    ScaleValue(24));
  FNueva := TcxRadioButton.Create(Self);
  FNueva.Parent := oGrupo;
  FNueva.Caption := SOpcionTarifaNuevaDesde;
  FNueva.SetBounds(ScaleValue(8), ScaleValue(82), ScaleValue(300),
    ScaleValue(24));
  FFecha := TcxDateEdit.Create(Self);
  FFecha.Parent := oGrupo;
  FFecha.SetBounds(ScaleValue(316), ScaleValue(80), ScaleValue(140),
    ScaleValue(24));
  FFecha.Date := FOpciones.FechaDesde;
  FModificar.Checked := FOpciones.Modo = mteModificar;
  FNueva.Checked := FOpciones.Modo = mteNuevaDesde;
  FModificar.OnClick := CambiarModo;
  FNueva.OnClick := CambiarModo;
  CambiarModo(nil);
end;

procedure TfrmModalPreciosTarifaSesion.CambiarModo(Sender: TObject);
begin
  FFecha.Enabled := FNueva.Checked;
end;

function TfrmModalPreciosTarifaSesion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') and Assigned(FNueva) then
  begin
    if FNueva.Checked and (FFecha.Date <= 0) then
    begin
      ShowMessage_fza(SErrorFechaTarifaNueva);
      sFicha := 'N';
      Result := False;
    end
    else if FNueva.Checked then
    begin
      FOpciones.Modo := mteNuevaDesde;
      FOpciones.FechaDesde := Int(FFecha.Date);
    end
    else
      FOpciones.Modo := mteModificar;
  end;
end;

procedure TfrmModalPreciosTarifaSesion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalPreciosTarifaSesion.Confirmar(AOwner: TComponent;
  const ATarifa: string; const APrecios: TArticulosPreciosTarifa;
  var AOpciones: TOpcionesTarifaSesion): Boolean;
var
  oFormulario: TfrmModalPreciosTarifaSesion;
begin
  oFormulario := TfrmModalPreciosTarifaSesion.CreatePrecios(AOwner, ATarifa,
    APrecios, AOpciones);
  try
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
    if Result then
      AOpciones := oFormulario.FOpciones;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
