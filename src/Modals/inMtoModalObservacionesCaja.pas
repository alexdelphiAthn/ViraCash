{******************************************************************************}
{                                                                              }
{  Módulo: inMtoModalObservacionesCaja                                          }
{  Tipo: Formulario (Modal)                                                    }
{  Versión: 1.0.0                                                              }
{  Fecha: 10/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Edición de observaciones diarias del almacén de caja.           }
{******************************************************************************}
unit inMtoModalObservacionesCaja;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, cxMemo, cxLabel, cxButtons,
  inMtoFrmBase, inLibMeteorologiaCajaIntf;

type
  TfrmModalObservacionesCaja = class(TfrmBase)
  private
    FTexto: TcxMemo;
    FRepositorio: IRepositorioObservacionesCaja;
    FEmpresa: string;
    FAlmacen: string;
    FUsuario: string;
    FFecha: TDateTime;
    procedure CrearControles;
    procedure Guardar(Sender: TObject);
  public
    procedure AplicarTraduccionActual; override;
    class procedure Ejecutar(AOwner: TComponent;
      const ARepositorio: IRepositorioObservacionesCaja;
      const AEmpresa, AAlmacen, AUsuario: string; AFecha: TDateTime);
  end;

implementation

uses
  Winapi.Windows, Vcl.Forms, Vcl.StdCtrls, inLibMensajesVcl,
  inLibMsgMeteorologiaCaja;

{$R *.dfm}

class procedure TfrmModalObservacionesCaja.Ejecutar(AOwner: TComponent;
  const ARepositorio: IRepositorioObservacionesCaja;
  const AEmpresa, AAlmacen, AUsuario: string; AFecha: TDateTime);
var
  oVentana: TfrmModalObservacionesCaja;
  sTexto: string;
begin
  sTexto := ARepositorio.LeerObservaciones(AEmpresa, AAlmacen, AFecha);
  oVentana := TfrmModalObservacionesCaja.Create(AOwner);
  try
    oVentana.FRepositorio := ARepositorio;
    oVentana.FEmpresa := AEmpresa;
    oVentana.FAlmacen := AAlmacen;
    oVentana.FUsuario := AUsuario;
    oVentana.FFecha := Trunc(AFecha);
    oVentana.CrearControles;
    oVentana.FTexto.Text := sTexto;
    oVentana.ActiveControl := oVentana.FTexto;
    oVentana.AplicarTraduccionActual;
    oVentana.ShowModal;
  finally
    oVentana.Free;
  end;
end;

procedure TfrmModalObservacionesCaja.AplicarTraduccionActual;
begin
  inherited;
  Caption := STituloObservacionesCaja;
  if Assigned(Traducciones) then
    Caption := Traducciones.Traducir(
      'inLibMsgMeteorologiaCaja.STituloObservacionesCaja',
      STituloObservacionesCaja);
end;

procedure TfrmModalObservacionesCaja.CrearControles;
var
  oCabecera: TcxLabel;
  oGuardar, oCancelar: TcxButton;
  iMargen, iBoton: Integer;
begin
  Caption := STituloObservacionesCaja;
  iMargen := MulDiv(16, CurrentPPI, 96);
  iBoton := MulDiv(100, CurrentPPI, 96);
  oCabecera := TcxLabel.Create(Self);
  oCabecera.Parent := Self;
  oCabecera.Transparent := True;
  oCabecera.AutoSize := False;
  oCabecera.SetBounds(iMargen, iMargen, ClientWidth - 2 * iMargen,
    MulDiv(28, CurrentPPI, 96));
  oCabecera.Caption := Format(SCabeceraObservacionesCaja,
    [FEmpresa, FAlmacen, DateToStr(FFecha)]);
  FTexto := TcxMemo.Create(Self);
  FTexto.Parent := Self;
  FTexto.Properties.MaxLength := 4000;
  FTexto.Properties.ScrollBars := ssVertical;
  FTexto.Properties.WantReturns := True;
  FTexto.SetBounds(iMargen, oCabecera.BoundsRect.Bottom + iMargen div 2,
    ClientWidth - 2 * iMargen, ClientHeight - 6 * iMargen);
  oCancelar := TcxButton.Create(Self);
  oCancelar.Parent := Self;
  oCancelar.Caption := SCancelarObservacionesCaja;
  oCancelar.Cancel := True;
  oCancelar.ModalResult := mrCancel;
  oCancelar.SetBounds(ClientWidth - iMargen - iBoton,
    ClientHeight - iMargen - MulDiv(32, CurrentPPI, 96),
    iBoton, MulDiv(32, CurrentPPI, 96));
  oGuardar := TcxButton.Create(Self);
  oGuardar.Parent := Self;
  oGuardar.Caption := SGuardarObservacionesCaja;
  oGuardar.SetBounds(oCancelar.Left - iMargen div 2 - iBoton,
    oCancelar.Top, iBoton, oCancelar.Height);
  oGuardar.OnClick := Guardar;
end;

procedure TfrmModalObservacionesCaja.Guardar(Sender: TObject);
begin
  try
    FRepositorio.GuardarObservaciones(FEmpresa, FAlmacen, FFecha,
      FTexto.Text, FUsuario);
    ModalResult := mrOk;
  except
    on E: Exception do
      ShowMessage_fza(E.Message);
  end;
end;

end.
