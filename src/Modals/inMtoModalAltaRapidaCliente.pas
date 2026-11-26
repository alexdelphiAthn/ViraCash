{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAltaRapidaCliente                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Alta de un cliente con sus datos básicos para convertir un ticket.       }
{******************************************************************************}
unit inMtoModalAltaRapidaCliente;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxCheckBox, cxLabel, cxButtons,
  inMtoFrmBase, inLibClientesPersistenciaIntf, inLibVerificacionNifIntf;

type
  TResultadoAltaRapidaCliente = record
    Aceptado: Boolean;
    Codigo: string;
    RazonSocial: string;
  end;

  TfrmModalAltaRapidaCliente = class(TfrmBase)
    lblRazonSocial: TcxLabel;
    edtRazonSocial: TcxTextEdit;
    lblNif: TcxLabel;
    edtNif: TcxTextEdit;
    btnValidarAeat: TcxButton;
    lblDireccion: TcxLabel;
    edtDireccion: TcxTextEdit;
    lblCodigoPostal: TcxLabel;
    edtCodigoPostal: TcxTextEdit;
    lblPoblacion: TcxLabel;
    edtPoblacion: TcxTextEdit;
    lblProvincia: TcxLabel;
    edtProvincia: TcxTextEdit;
    lblPais: TcxLabel;
    cbbPais: TcxComboBox;
    chkComprobarNif: TcxCheckBox;
    pnlBotones: TPanel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    procedure btnValidarAeatClick(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
  private
    FResultado: TResultadoAltaRapidaCliente;
    FServicio: IAltaRapidaClientes;
    FVerificacion: IServicioVerificacionNif;
    FEmpresa: string;
    FPaises: TArray<TPaisAltaRapidaCliente>;
    procedure Configurar;
    function LeerDatos: TDatosAltaRapidaCliente;
  public
    class function Ejecutar(AOwner: TComponent;
      const AServicio: IAltaRapidaClientes;
      const AVerificacion: IServicioVerificacionNif;
      const AEmpresa: string): TResultadoAltaRapidaCliente;
  end;

implementation

uses
  System.SysUtils, inLibClientesAltaRapida, inLibDocumentoFiscal,
  inLibMsgVentas, inLibMsgComun, inLibMensajesVcl,
  inLibMsgVerificacionNif, inMtoVerificacionNifVcl;

{$R *.dfm}

class function TfrmModalAltaRapidaCliente.Ejecutar(AOwner: TComponent;
  const AServicio: IAltaRapidaClientes;
      const AVerificacion: IServicioVerificacionNif;
      const AEmpresa: string): TResultadoAltaRapidaCliente;
var
  oFormulario: TfrmModalAltaRapidaCliente;
begin
  oFormulario := TfrmModalAltaRapidaCliente.Create(AOwner);
  try
    oFormulario.FServicio := AServicio;
    oFormulario.FEmpresa := AEmpresa;
    oFormulario.FVerificacion := AVerificacion;
    oFormulario.Configurar;
    oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalAltaRapidaCliente.Configurar;
var
  i: Integer;
begin
  Caption := STituloAltaRapidaCliente;
  lblRazonSocial.Caption := SCaptionRazonSocialAltaRapida;
  lblNif.Caption := SCaptionNifAltaRapida;
  btnValidarAeat.Caption := SValidarAeatAltaRapida;
  btnValidarAeat.Hint := SHintBotonVerificarNif;
  lblDireccion.Caption := SCaptionDireccionAltaRapida;
  lblCodigoPostal.Caption := SCaptionCodigoPostalAltaRapida;
  lblPoblacion.Caption := SCaptionPoblacionAltaRapida;
  lblProvincia.Caption := SCaptionProvinciaAltaRapida;
  lblPais.Caption := SCaptionPaisAltaRapida;
  chkComprobarNif.Caption := SCaptionComprobarNifAltaRapida;
  chkComprobarNif.Checked := True;
  btnGuardar.Caption := SCaptionGuardarAltaRapidaCliente;
  btnCancelar.Caption := SCaptionCancelarEsc;
  btnGuardar.Enabled := PuedeAltaRapidaCliente(Permisos);
  FPaises := FServicio.ConsultarPaises;
  for i := 0 to High(FPaises) do
  begin
    cbbPais.Properties.Items.Add(FPaises[i].Nombre);
    if PaisEsEspana(FPaises[i].Codigo, FPaises[i].Nombre) then
      cbbPais.ItemIndex := i;
  end;
end;

procedure TfrmModalAltaRapidaCliente.btnValidarAeatClick(Sender: TObject);
var
  Solicitud: TSolicitudVerificacionNif;
  sNombre: string;
begin
  Solicitud := Default(TSolicitudVerificacionNif);
  Solicitud.CodigoEmpresa := FEmpresa;
  Solicitud.Nif := Trim(edtNif.Text);
  Solicitud.Nombre := Trim(edtRazonSocial.Text);
  if ConsultarRazonSocialAeat(Self,
    function: TResultadoVerificacionNif
    begin
      Result := FVerificacion.Verificar(Solicitud);
    end, True, sNombre) then
    edtRazonSocial.Text := sNombre;
end;

function TfrmModalAltaRapidaCliente.LeerDatos: TDatosAltaRapidaCliente;
begin
  Result := Default(TDatosAltaRapidaCliente);
  Result.RazonSocial := Trim(edtRazonSocial.Text);
  Result.Nif := Trim(edtNif.Text);
  Result.Direccion := Trim(edtDireccion.Text);
  Result.CodigoPostal := Trim(edtCodigoPostal.Text);
  Result.Poblacion := Trim(edtPoblacion.Text);
  Result.Provincia := Trim(edtProvincia.Text);
  if (cbbPais.ItemIndex >= 0) and
     (cbbPais.ItemIndex < Length(FPaises)) then
    Result.Pais := FPaises[cbbPais.ItemIndex];
  Result.ComprobarNif := chkComprobarNif.Checked;
end;

procedure TfrmModalAltaRapidaCliente.btnGuardarClick(Sender: TObject);
var
  oDatos: TDatosAltaRapidaCliente;
  sError: string;
begin
  oDatos := LeerDatos;
  sError := ErrorDatosAltaRapidaCliente(oDatos);
  if sError <> '' then
    ShowMessage_fza(sError)
  else if PuedeAltaRapidaCliente(Permisos) then
  begin
    FResultado.Codigo := FServicio.CrearCliente(oDatos,
      IdentidadSesion.Usuario, ParametrosCaja.TarifaDefecto);
    FResultado.RazonSocial := oDatos.RazonSocial;
    FResultado.Aceptado := True;
    ModalResult := mrOk;
  end;
end;

end.
