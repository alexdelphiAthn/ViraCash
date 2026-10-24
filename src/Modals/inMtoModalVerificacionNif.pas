{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalVerificacionNif                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Muestra el resultado de verificar un NIF en la AEAT: rojo si no está      }
{    identificado, revocado o de baja; naranja si casa con otro NIF o con      }
{    otra razón social. Ofrece usar la razón social oficial. FZ-ISSUE-131.     }
{******************************************************************************}
unit inMtoModalVerificacionNif;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, Vcl.Controls,
  Vcl.Forms, Vcl.Graphics, cxLabel,
  inMtoModalAceptCancel, inLibVerificacionNifIntf;

type
  TfrmModalVerificacionNif = class(TfrmModalAceptCancel)
  private
    FResultado: TResultadoVerificacionNif;
    FPuedeUsarRazonSocial: Boolean;
    FUsarRazonSocial: Boolean;
    function AnadirFila(
      const ATexto: string;
      AAltura: Integer;
      AColor: TColor;
      ANegrita: Boolean): TcxLabel;
    procedure ConstruirFilas;
    procedure UsarRazonSocialClick(Sender: TObject);
    procedure CerrarClick(Sender: TObject);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
    procedure DoShow; override;
  public
    function IsShortCut(var Message: TWMKey): Boolean; override;
    constructor CreateVerificacion(
      AOwner: TComponent;
      const AResultado: TResultadoVerificacionNif;
      APermitirUsarRazonSocial: Boolean);
    // True si el usuario pide sustituir el nombre por el de la AEAT.
    class function Ejecutar(
      AOwner: TComponent;
      const AResultado: TResultadoVerificacionNif;
      APermitirUsarRazonSocial: Boolean): Boolean;
  end;

implementation

uses
  System.SysUtils,
  inLibMsgVerificacionNif;

const
  // Medidas a 96 ppp; se aplican con ScaleValue.
  ANCHO_MODAL = 620;
  ALTO_FILA = 26;
  ALTO_MENSAJE = 46;
  MARGEN_FILA = 10;
  ALTO_BOTONERA = 50;
  ANCHO_BOTON_USAR = 250;
  ANCHO_BOTON_CERRAR = 140;
  MARGEN_BOTON = 9;
  COLOR_ERROR = TColor($000000C8);
  COLOR_AVISO = TColor($00007FE0);
  COLOR_CORRECTA = TColor($00008000);

function ColorGravedad(AGravedad: TGravedadVerificacionNif): TColor;
begin
  case AGravedad of
    gvnError:
      Result := COLOR_ERROR;
    gvnAviso:
      Result := COLOR_AVISO;
  else
    Result := COLOR_CORRECTA;
  end;
end;

function MensajeEstado(const AResultado: TResultadoVerificacionNif): string;
begin
  case AResultado.Estado of
    evnNoIdentificado:
      Result := SVerificacionNifNoIdentificado;
    evnRevocado:
      Result := SVerificacionNifRevocado;
    evnBaja:
      Result := SVerificacionNifBaja;
    evnOtro:
      Result := SVerificacionNifOtro;
  else
    Result := SVerificacionNifCorrecta;
  end;
end;

constructor TfrmModalVerificacionNif.CreateVerificacion(
  AOwner: TComponent;
  const AResultado: TResultadoVerificacionNif;
  APermitirUsarRazonSocial: Boolean);
begin
  inherited Create(AOwner);
  FResultado := AResultado;
  FPuedeUsarRazonSocial := APermitirUsarRazonSocial and
    AResultado.EsPersonaJuridica and AResultado.NombreDistinto and
    (Trim(AResultado.NombreAeat) <> '');
  OnClose := CerrarSinLiberar;
  Position := poOwnerFormCenter;
  BorderStyle := bsDialog;
  Font.Name := 'Source Sans 3';
  ClientWidth := ScaleValue(ANCHO_MODAL);
  ConstruirFilas;
  pnlButton.Height := ScaleValue(ALTO_BOTONERA);
  btnCancelar.Caption := SCaptionCerrarVerificacionNif;
  btnCancelar.OnClick := CerrarClick;
  btnCancelar.Width := ScaleValue(ANCHO_BOTON_CERRAR);
  btnCancelar.AlignWithMargins := True;
  btnCancelar.Margins.SetBounds(0, ScaleValue(MARGEN_BOTON),
    ScaleValue(MARGEN_BOTON), ScaleValue(MARGEN_BOTON));
  btnCancelar.Align := alRight;
  btnAceptar.Caption := SCaptionUsarRazonSocialAeat;
  btnAceptar.OnClick := UsarRazonSocialClick;
  btnAceptar.Visible := FPuedeUsarRazonSocial;
  btnAceptar.Width := ScaleValue(ANCHO_BOTON_USAR);
  btnAceptar.AlignWithMargins := True;
  btnAceptar.Margins.SetBounds(0, ScaleValue(MARGEN_BOTON),
    ScaleValue(MARGEN_BOTON), ScaleValue(MARGEN_BOTON));
  btnAceptar.Align := alRight;
end;

procedure TfrmModalVerificacionNif.DoCreate;
begin
  inherited;
  // TfrmBase traduce el Caption por la jerarquía de clases: sin clave
  // propia quedaría el título de TfrmBase.
  Caption := STituloVerificacionNif;
end;

procedure TfrmModalVerificacionNif.DoShow;
begin
  inherited;
  // FZ-ISSUE-136: sin «Usar razón social» el foco va a Cerrar (la base
  // solo enfoca Aceptar cuando está visible).
  if (not btnAceptar.Visible) and btnCancelar.CanFocus then
    btnCancelar.SetFocus;
end;

function TfrmModalVerificacionNif.AnadirFila(
  const ATexto: string;
  AAltura: Integer;
  AColor: TColor;
  ANegrita: Boolean): TcxLabel;
begin
  Result := TcxLabel.Create(Self);
  Result.Parent := pnlBody;
  Result.AutoSize := False;
  Result.Height := ScaleValue(AAltura);
  Result.AlignWithMargins := True;
  Result.Margins.SetBounds(ScaleValue(MARGEN_FILA), 0,
    ScaleValue(MARGEN_FILA), 0);
  // alTop apila en orden de creación si cada fila entra por debajo.
  Result.Top := pnlBody.Height;
  Result.Align := alTop;
  Result.Properties.WordWrap := True;
  Result.Transparent := True;
  Result.Caption := ATexto;
  if AColor <> clDefault then
    Result.Style.TextColor := AColor;
  if ANegrita then
    Result.Style.TextStyle := [fsBold];
end;

procedure TfrmModalVerificacionNif.ConstruirFilas;
var
  iAltura: Integer;
begin
  iAltura := MARGEN_FILA;
  AnadirFila(SCaptionVerificacionNifEnviado + '  ' +
    FResultado.NifEnviado + ' · ' + FResultado.NombreEnviado,
    ALTO_FILA, clDefault, False);
  Inc(iAltura, ALTO_FILA);
  AnadirFila(SCaptionVerificacionNifAeat + '  ' +
    FResultado.NifAeat + ' · ' + Trim(FResultado.NombreAeat),
    ALTO_FILA, clDefault, False);
  Inc(iAltura, ALTO_FILA);
  AnadirFila(SCaptionVerificacionNifResultado + '  ' +
    FResultado.Resultado, ALTO_FILA,
    ColorGravedad(FResultado.Gravedad), True);
  Inc(iAltura, ALTO_FILA);
  AnadirFila(MensajeEstado(FResultado), ALTO_MENSAJE,
    ColorGravedad(FResultado.Gravedad), False);
  Inc(iAltura, ALTO_MENSAJE);
  if FResultado.NifDistinto then
  begin
    AnadirFila(Format(SVerificacionNifNifDistinto,
      [FResultado.NifAeat, FResultado.NifEnviado]), ALTO_MENSAJE,
      COLOR_AVISO, False);
    Inc(iAltura, ALTO_MENSAJE);
  end;
  if FResultado.NombreDistinto then
  begin
    AnadirFila(SVerificacionNifNombreDistinto, ALTO_FILA,
      COLOR_AVISO, False);
    Inc(iAltura, ALTO_FILA);
  end;
  ClientHeight := ScaleValue(iAltura + MARGEN_FILA + ALTO_BOTONERA);
end;

procedure TfrmModalVerificacionNif.UsarRazonSocialClick(Sender: TObject);
begin
  FUsarRazonSocial := FPuedeUsarRazonSocial;
  ModalResult := mrOk;
end;

procedure TfrmModalVerificacionNif.CerrarClick(Sender: TObject);
begin
  FUsarRazonSocial := False;
  ModalResult := mrCancel;
end;

// La base libera el modal al cerrarse (caFree); Ejecutar lo libera.
procedure TfrmModalVerificacionNif.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

function TfrmModalVerificacionNif.IsShortCut(var Message: TWMKey): Boolean;
begin
  if Message.CharCode = VK_ESCAPE then
  begin
    CerrarClick(Self);
    Result := True;
  end
  else if Message.CharCode = VK_F12 then
  begin
    // La acción F12 heredada cerraría como Cancelar.
    if FPuedeUsarRazonSocial then
      UsarRazonSocialClick(Self)
    else
      CerrarClick(Self);
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

class function TfrmModalVerificacionNif.Ejecutar(
  AOwner: TComponent;
  const AResultado: TResultadoVerificacionNif;
  APermitirUsarRazonSocial: Boolean): Boolean;
var
  oFormulario: TfrmModalVerificacionNif;
begin
  oFormulario := TfrmModalVerificacionNif.CreateVerificacion(
    AOwner, AResultado, APermitirUsarRazonSocial);
  try
    oFormulario.ShowModal;
    Result := oFormulario.FUsarRazonSocial;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
