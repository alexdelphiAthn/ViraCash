{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalFechaHoraRecuento                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Solicita el instante aplicable a líneas de recuento importadas que no     }
{    incluyen su propia fecha y hora.                                          }
{******************************************************************************}
unit inMtoModalFechaHoraRecuento;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtons,
  cxCalendar,
  cxContainer,
  cxControls,
  cxDropDownEdit,
  cxEdit,
  cxLabel,
  cxMaskEdit,
  cxTextEdit,
  inMtoFrmBase;

type
  TMensajesFechaHoraRecuento = record
    Titulo: string;
    Explicacion: string;
    Etiqueta: string;
    TextoAceptar: string;
    TextoCancelar: string;
    ErrorNoIndicada: string;
  end;

  TResultadoFechaHoraRecuento = record
    Aceptado: Boolean;
    FechaHora: TDateTime;
  end;

  TfrmModalFechaHoraRecuento = class(TfrmBase)
    pnlContenido: TPanel;
    lblExplicacion: TcxLabel;
    lblFechaHora: TcxLabel;
    dteFechaHora: TcxDateEdit;
    pnlBotones: TPanel;
    btnCancelar: TcxButton;
    btnAceptar: TcxButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FMensajeError: string;
    FResultado: TResultadoFechaHoraRecuento;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AFechaPropuesta: TDateTime;
      const AMensajes: TMensajesFechaHoraRecuento):
      TResultadoFechaHoraRecuento;
  end;

implementation

uses
  inLibMensajesVcl,
  Vcl.Dialogs,
  inLibInventariosAplicacion;

{$R *.dfm}

class function TfrmModalFechaHoraRecuento.Ejecutar(
  AOwner: TComponent;
  AFechaPropuesta: TDateTime;
  const AMensajes: TMensajesFechaHoraRecuento):
  TResultadoFechaHoraRecuento;
var
  Formulario: TfrmModalFechaHoraRecuento;
begin
  Formulario := TfrmModalFechaHoraRecuento.Create(AOwner);
  try
    Formulario.FResultado := Default(TResultadoFechaHoraRecuento);
    Formulario.Caption := AMensajes.Titulo;
    Formulario.lblExplicacion.Caption :=
      AMensajes.Explicacion;
    Formulario.lblFechaHora.Caption :=
      AMensajes.Etiqueta;
    Formulario.btnAceptar.Caption := AMensajes.TextoAceptar;
    Formulario.btnCancelar.Caption := AMensajes.TextoCancelar;
    Formulario.FMensajeError := AMensajes.ErrorNoIndicada;
    Formulario.dteFechaHora.Date := AFechaPropuesta;
    Formulario.ShowModal;
    Result := Formulario.FResultado;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalFechaHoraRecuento.btnAceptarClick(Sender: TObject);
begin
  if not FechaHoraRecuentoInventarioValida(
       dteFechaHora.Date,
       Now) then
    ShowMessage_fza(FMensajeError)
  else
  begin
    FResultado.Aceptado := True;
    FResultado.FechaHora := dteFechaHora.Date;
    Close;
  end;
end;

procedure TfrmModalFechaHoraRecuento.btnCancelarClick(Sender: TObject);
begin
  FResultado.Aceptado := False;
  Close;
end;

end.
