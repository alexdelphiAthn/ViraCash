{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalErrorAplicacion                                     }
{    Tipo:       Formulario modal                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presenta el detalle de una excepción y las opciones de soporte.           }
{******************************************************************************}
unit inMtoModalErrorAplicacion;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtons,
  cxCheckBox,
  cxClasses,
  cxContainer,
  cxControls,
  cxEdit,
  cxGraphics,
  cxLabel,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxMemo,
  cxTextEdit,
  dxCore,
  dxSkinsForm,
  inMtoFrmBase,
  inLibExcepcionesAplicacionIntf;

type
  TfrmModalErrorAplicacion = class(TfrmBase)
    pnlContacto: TPanel;
    lblEvidencias: TcxLabel;
    lblEmail: TcxLabel;
    edtEmail: TcxTextEdit;
    lblTelefono: TcxLabel;
    edtTelefono: TcxTextEdit;
    lblDescripcion: TcxLabel;
    mDescripcion: TcxMemo;
    chkEnviarCopia: TcxCheckBox;
    lblEstadoLog: TcxLabel;
    pnlBotones: TPanel;
    btnActivarLog: TcxButton;
    btnEnviar: TcxButton;
    btnCopiar: TcxButton;
    btnSalirAplicacion: TcxButton;
    btnCerrar: TcxButton;
    mDetalle: TcxMemo;
  end;

function CrearPresentacionExcepcionesAplicacionVcl:
  IPresentacionExcepcionesAplicacion;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Vcl.Graphics,
  inMtoModalMensajeTexto;

type
  TVistaErrorAplicacionVcl = class(
    TInterfacedObject,
    IVistaErrorAplicacion)
  private
    FAcciones: TAccionesVistaErrorAplicacion;
    FFormulario: TfrmModalErrorAplicacion;
    procedure ActivarLogClick(Sender: TObject);
    procedure CambiarCopiaSeguridadClick(Sender: TObject);
    procedure CopiarDetalleClick(Sender: TObject);
    procedure EnviarErrorClick(Sender: TObject);
    procedure SalirAplicacionClick(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configurar(
      const AConfiguracion: TConfiguracionVistaErrorAplicacion);
    procedure Mostrar;
    procedure EstablecerDetalle(const ATexto: string);
    procedure InsertarDetalle(const ATexto: string);
    function TextoDetalle: string;
    function Email: string;
    function Telefono: string;
    function Descripcion: string;
    function EnviarCopiaSeguridad: Boolean;
    procedure AplicarEstado(
      const AEstado: TEstadoVistaErrorAplicacion);
  end;

  TPresentacionExcepcionesAplicacionVcl = class(
    TInterfacedObject,
    IPresentacionExcepcionesAplicacion)
  public
    function CrearVistaError: IVistaErrorAplicacion;
    procedure MostrarMensaje(const ATexto: string);
  end;

function CrearPresentacionExcepcionesAplicacionVcl:
  IPresentacionExcepcionesAplicacion;
begin
  Result := TPresentacionExcepcionesAplicacionVcl.Create;
end;

constructor TVistaErrorAplicacionVcl.Create;
begin
  inherited Create;
  FFormulario := TfrmModalErrorAplicacion.Create(Application.MainForm);
end;

destructor TVistaErrorAplicacionVcl.Destroy;
begin
  FAcciones.ActivarLog := nil;
  FAcciones.CambiarCopiaSeguridad := nil;
  FAcciones.CopiarDetalle := nil;
  FAcciones.EnviarError := nil;
  FAcciones.SalirAplicacion := nil;
  FreeAndNil(FFormulario);
  inherited;
end;

procedure TVistaErrorAplicacionVcl.Configurar(
  const AConfiguracion: TConfiguracionVistaErrorAplicacion);
begin
  FAcciones := AConfiguracion.Acciones;
  FFormulario.Caption := AConfiguracion.Titulo;
  FFormulario.lblEmail.Caption := AConfiguracion.EtiquetaEmail;
  FFormulario.lblTelefono.Caption := AConfiguracion.EtiquetaTelefono;
  FFormulario.lblDescripcion.Caption :=
    AConfiguracion.EtiquetaDescripcion;
  FFormulario.btnCerrar.Caption := AConfiguracion.TextoCerrar;
  FFormulario.btnSalirAplicacion.Caption :=
    AConfiguracion.TextoSalirAplicacion;
  FFormulario.btnCopiar.Caption := AConfiguracion.TextoCopiar;
  FFormulario.btnEnviar.Caption := AConfiguracion.TextoEnviar;
  FFormulario.btnActivarLog.Caption := AConfiguracion.TextoActivarLog;
  FFormulario.chkEnviarCopia.Caption := AConfiguracion.TextoEnviarCopia;
  FFormulario.chkEnviarCopia.Enabled := AConfiguracion.PuedeEnviar;
  FFormulario.chkEnviarCopia.OnClick := CambiarCopiaSeguridadClick;
  FFormulario.btnActivarLog.OnClick := ActivarLogClick;
  FFormulario.btnCopiar.OnClick := CopiarDetalleClick;
  FFormulario.btnEnviar.OnClick := EnviarErrorClick;
  FFormulario.btnSalirAplicacion.OnClick := SalirAplicacionClick;
  FFormulario.ActiveControl := FFormulario.btnCerrar;
end;

procedure TVistaErrorAplicacionVcl.Mostrar;
begin
  FFormulario.ShowModal;
end;

procedure TVistaErrorAplicacionVcl.EstablecerDetalle(
  const ATexto: string);
begin
  FFormulario.mDetalle.Text := ATexto;
end;

procedure TVistaErrorAplicacionVcl.InsertarDetalle(
  const ATexto: string);
begin
  FFormulario.mDetalle.Lines.Insert(0, ATexto);
end;

function TVistaErrorAplicacionVcl.TextoDetalle: string;
begin
  Result := FFormulario.mDetalle.Text;
end;

function TVistaErrorAplicacionVcl.Email: string;
begin
  Result := FFormulario.edtEmail.Text;
end;

function TVistaErrorAplicacionVcl.Telefono: string;
begin
  Result := FFormulario.edtTelefono.Text;
end;

function TVistaErrorAplicacionVcl.Descripcion: string;
begin
  Result := FFormulario.mDescripcion.Text;
end;

function TVistaErrorAplicacionVcl.EnviarCopiaSeguridad: Boolean;
begin
  Result := FFormulario.chkEnviarCopia.Checked;
end;

procedure TVistaErrorAplicacionVcl.AplicarEstado(
  const AEstado: TEstadoVistaErrorAplicacion);
begin
  FFormulario.lblEvidencias.Caption := AEstado.Evidencias;
  FFormulario.lblEstadoLog.Caption := AEstado.EstadoLog;
  case AEstado.NivelEstado of
    nevaInformacion:
      FFormulario.lblEstadoLog.Style.TextColor := clNavy;
    nevaCorrecto:
      FFormulario.lblEstadoLog.Style.TextColor := clGreen;
    nevaError:
      FFormulario.lblEstadoLog.Style.TextColor := clMaroon;
  end;
  FFormulario.btnEnviar.Enabled := AEstado.PuedeEnviar;
  FFormulario.btnActivarLog.Visible := AEstado.ActivarLogVisible;
  FFormulario.btnActivarLog.Enabled := AEstado.ActivarLogHabilitado;
  FFormulario.lblEstadoLog.Repaint;
end;

procedure TVistaErrorAplicacionVcl.ActivarLogClick(Sender: TObject);
begin
  if Assigned(FAcciones.ActivarLog) then
    FAcciones.ActivarLog();
end;

procedure TVistaErrorAplicacionVcl.CambiarCopiaSeguridadClick(
  Sender: TObject);
begin
  if Assigned(FAcciones.CambiarCopiaSeguridad) then
    FAcciones.CambiarCopiaSeguridad();
end;

procedure TVistaErrorAplicacionVcl.CopiarDetalleClick(Sender: TObject);
begin
  if Assigned(FAcciones.CopiarDetalle) then
    FAcciones.CopiarDetalle();
end;

procedure TVistaErrorAplicacionVcl.EnviarErrorClick(Sender: TObject);
begin
  if Assigned(FAcciones.EnviarError) then
    FAcciones.EnviarError();
end;

procedure TVistaErrorAplicacionVcl.SalirAplicacionClick(
  Sender: TObject);
begin
  FFormulario.ModalResult := mrAbort;
  if Assigned(FAcciones.SalirAplicacion) then
    FAcciones.SalirAplicacion();
end;

function TPresentacionExcepcionesAplicacionVcl.CrearVistaError:
  IVistaErrorAplicacion;
begin
  Result := TVistaErrorAplicacionVcl.Create;
end;

procedure TPresentacionExcepcionesAplicacionVcl.MostrarMensaje(
  const ATexto: string);
begin
  TfrmModalMensajeTexto.Mostrar(Application.MainForm, ATexto);
end;

end.
