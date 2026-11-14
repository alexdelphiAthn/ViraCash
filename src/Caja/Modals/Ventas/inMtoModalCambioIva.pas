{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCambioIva                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selecciona el tipo de IVA de una línea inmaterial de Caja.                }
{******************************************************************************}
unit inMtoModalCambioIva;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxButtons, cxRadioGroup,
  inMtoFrmBase, dxCoreGraphics, Vcl.Menus, cxGroupBox,
  JvComponentBase, JvEnterTab, cxClasses, cxLocalization;

type
  TfrmModalCambioIva = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    rgTipoIva: TcxRadioGroup;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    function TipoIvaSeleccionado: string;
    procedure PreseleccionarTipoIva(const ATipoIva: string);
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ATipoIvaActual: string;
      out ATipoIvaSeleccionado: string): Boolean;
  end;

implementation

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalCambioIva.Ejecutar(
  AOwner: TComponent;
  const ATipoIvaActual: string;
  out ATipoIvaSeleccionado: string): Boolean;
var
  Formulario: TfrmModalCambioIva;
begin
  Result := False;
  ATipoIvaSeleccionado := '';
  Formulario := TfrmModalCambioIva.Create(AOwner);
  try
    Formulario.PreseleccionarTipoIva(ATipoIvaActual);
    if Formulario.ShowModal = mrOk then
    begin
      ATipoIvaSeleccionado := Formulario.TipoIvaSeleccionado;
      Result := True;
    end;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalCambioIva.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalCambioIva.PreseleccionarTipoIva(
  const ATipoIva: string);
begin
  if SameText(Trim(ATipoIva), 'R') then
    rgTipoIva.ItemIndex := 1
  else if SameText(Trim(ATipoIva), 'S') then
    rgTipoIva.ItemIndex := 2
  else if SameText(Trim(ATipoIva), 'E') then
    rgTipoIva.ItemIndex := 3
  else
    rgTipoIva.ItemIndex := 0;
end;

function TfrmModalCambioIva.TipoIvaSeleccionado: string;
begin
  case rgTipoIva.ItemIndex of
    1:
      Result := 'R';
    2:
      Result := 'S';
    3:
      Result := 'E';
    else
      Result := 'N';
  end;
end;

procedure TfrmModalCambioIva.actAceptarExecute(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmModalCambioIva.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalCambioIva);
end.
