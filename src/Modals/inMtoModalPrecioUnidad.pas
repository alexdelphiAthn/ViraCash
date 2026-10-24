{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalPrecioUnidad                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                                }
{    Edición del contenido de un SKU y referencia común de su artículo.        }
{******************************************************************************}
unit inMtoModalPrecioUnidad;

interface

uses
  System.Classes, Vcl.Controls, Uni, cxLabel, cxCurrencyEdit,
  cxDropDownEdit, cxCheckBox, inMtoFrmBase, inLibPrecioUnidad;

type
  TContextoContenidoSku = record
    CodigoSku: string;
    CodigoArticulo: string;
    Tarifa: string;
    Usuario: string;
    PuedeEditar: Boolean;
  end;
  TfrmModalPrecioUnidad = class(TfrmBase)
  private
    FConexion: TUniConnection;
    FContexto: TContextoContenidoSku;
    FContenido: TContenidoPrecioUnidad;
    FPrecioEnvase: Double;
    FValorContenido: TcxCurrencyEdit;
    FValorReferencia: TcxCurrencyEdit;
    FUnidadContenido: TcxComboBox;
    FUnidadReferencia: TcxComboBox;
    FIndicar: TcxCheckBox;
    FTicket: TcxCheckBox;
    FPrecio: TcxLabel;
    function Numero(const ATitulo: string; ATop: Integer): TcxCurrencyEdit;
    function Unidad(const ATitulo: string; ATop: Integer): TcxComboBox;
    procedure Rotulo(const ATitulo: string; ALeft, ATop: Integer);
    procedure CrearControles;
    procedure Cargar;
    function Recoger: TContenidoPrecioUnidad;
    procedure Cambiar(Sender: TObject);
    procedure Aceptar(Sender: TObject);
  public
    class function Ejecutar(AOwner: TComponent; AConexion: TUniConnection;
      const AContexto: TContextoContenidoSku): Boolean;
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils, Vcl.Forms, cxButtons, cxTextEdit, cxEdit,
  inLibMsgArticulos, inLibMsgComun, inLibMensajesVcl, UniDataPrecioUnidad;

procedure TfrmModalPrecioUnidad.Rotulo(const ATitulo: string;
  ALeft, ATop: Integer);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := Self;
  oRotulo.Transparent := True;
  oRotulo.AutoSize := False;
  oRotulo.Properties.WordWrap := True;
  oRotulo.Caption := ATitulo;
  oRotulo.SetBounds(ScaleValue(ALeft), ScaleValue(ATop),
    ClientWidth - ScaleValue(ALeft + 16), ScaleValue(40));
end;

function TfrmModalPrecioUnidad.Numero(const ATitulo: string;
  ATop: Integer): TcxCurrencyEdit;
begin
  Rotulo(ATitulo, 16, ATop);
  Result := TcxCurrencyEdit.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(ScaleValue(16), ScaleValue(ATop + 22),
    ScaleValue(190), ScaleValue(26));
  Result.Properties.DecimalPlaces := 6;
  Result.Properties.DisplayFormat := '0.######';
  Result.Properties.EditFormat := '0.######';
  Result.Properties.OnEditValueChanged := Cambiar;
  Result.Enabled := FContexto.PuedeEditar;
end;

function TfrmModalPrecioUnidad.Unidad(const ATitulo: string;
  ATop: Integer): TcxComboBox;
begin
  Rotulo(ATitulo, 240, ATop);
  Result := TcxComboBox.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(ScaleValue(240), ScaleValue(ATop + 22),
    ScaleValue(280), ScaleValue(26));
  Result.Properties.Items.Text := 'g' + sLineBreak + 'kg' + sLineBreak +
    'ml' + sLineBreak + 'l' + sLineBreak + 'ud';
  Result.Properties.DropDownListStyle := lsFixedList;
  Result.Properties.OnEditValueChanged := Cambiar;
  Result.Enabled := FContexto.PuedeEditar;
end;

procedure TfrmModalPrecioUnidad.CrearControles;
var
  oBoton: TcxButton;
begin
  Caption := SCaptionContenidoPrecioUnidad;
  Rotulo(FContexto.CodigoSku, 16, 12);
  FValorContenido := Numero(SCaptionContenidoNeto, 46);
  FUnidadContenido := Unidad(SCaptionUnidadContenido, 46);
  FValorReferencia := Numero(SCaptionReferenciaPrecio, 114);
  FUnidadReferencia := Unidad(SCaptionUnidadReferencia, 114);
  FIndicar := TcxCheckBox.Create(Self);
  FIndicar.Parent := Self;
  FIndicar.SetBounds(ScaleValue(16), ScaleValue(182), ScaleValue(510), 24);
  FIndicar.Caption := SCaptionIndicarPrecioUnidad;
  FIndicar.Enabled := FContexto.PuedeEditar;
  FIndicar.Properties.OnEditValueChanged := Cambiar;
  FTicket := TcxCheckBox.Create(Self);
  FTicket.Parent := Self;
  FTicket.SetBounds(ScaleValue(16), ScaleValue(214), ScaleValue(510), 24);
  FTicket.Caption := SCaptionPrecioUnidadTicket;
  FTicket.Enabled := FContexto.PuedeEditar;
  Rotulo(SAyudaContenidoPrecioUnidad, 16, 258);
  FPrecio := TcxLabel.Create(Self);
  FPrecio.Parent := Self;
  FPrecio.Transparent := True;
  FPrecio.AutoSize := False;
  FPrecio.SetBounds(ScaleValue(16), ScaleValue(306),
    ScaleValue(510), ScaleValue(48));
  FPrecio.Properties.WordWrap := True;
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := Self;
  oBoton.SetBounds(ScaleValue(16), ScaleValue(376),
    ScaleValue(180), ScaleValue(36));
  oBoton.Caption := SCaptionCancelar;
  oBoton.Cancel := True;
  oBoton.ModalResult := mrCancel;
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := Self;
  oBoton.SetBounds(ScaleValue(340), ScaleValue(376),
    ScaleValue(180), ScaleValue(36));
  oBoton.Caption := SCaptionAceptar;
  oBoton.Default := True;
  oBoton.Enabled := FContexto.PuedeEditar;
  oBoton.OnClick := Aceptar;
end;

procedure TfrmModalPrecioUnidad.Cargar;
var
  Precio: TPrecioSkuContenido;
begin
  FContenido := LeerContenidoPrecioUnidad(FConexion, FContexto.CodigoSku);
  FPrecioEnvase := -1;
  for Precio in ListarPreciosContenido(FConexion,
    FContexto.CodigoArticulo, FContexto.Tarifa, Date) do
    if Precio.Contenido.CodigoSku = FContexto.CodigoSku then
      FPrecioEnvase := Precio.PrecioEnvase;
  FValorContenido.Value := FContenido.Contenido;
  FValorReferencia.Value := FContenido.Referencia;
  FUnidadContenido.Text := FContenido.UnidadContenido;
  FUnidadReferencia.Text := FContenido.UnidadReferencia;
  FIndicar.Checked := FContenido.EsIndicado;
  FTicket.Checked := FContenido.EsTicket;
  Cambiar(nil);
end;

function TfrmModalPrecioUnidad.Recoger: TContenidoPrecioUnidad;
begin
  Result := FContenido;
  Result.Contenido := FValorContenido.Value;
  Result.Referencia := FValorReferencia.Value;
  Result.UnidadContenido := FUnidadContenido.Text;
  Result.UnidadReferencia := FUnidadReferencia.Text;
  Result.EsIndicado := FIndicar.Checked;
  Result.EsTicket := FTicket.Checked;
end;

procedure TfrmModalPrecioUnidad.Cambiar(Sender: TObject);
var
  Precio: TPrecioPorUnidad;
begin
  if (FPrecio <> nil) and (FTicket <> nil) then
  begin
    Precio := CalcularPrecioPorUnidad(Recoger, FPrecioEnvase);
    FPrecio.Properties.WordWrap := Precio.Estado <> epuValido;
    FPrecio.Caption := Precio.Texto;
    if (Precio.Estado <> epuValido) and FIndicar.Checked then
      FPrecio.Caption := Format(SErrorContenidoEtiqueta,
        [FContexto.CodigoSku]);
  end;
end;

procedure TfrmModalPrecioUnidad.Aceptar(Sender: TObject);
var
  Contenido: TContenidoPrecioUnidad;
begin
  Contenido := Recoger;
  if (Contenido.EsIndicado and
     (CalcularPrecioPorUnidad(Contenido, 0).Estado <> epuValido)) or
     (Contenido.EsTicket and not Contenido.EsIndicado) then
    ShowMessage_fza(SErrorContenidoPrecioUnidad)
  else
  begin
    GuardarContenidoPrecioUnidad(FConexion, Contenido, FContexto.Usuario);
    ModalResult := mrOk;
  end;
end;

class function TfrmModalPrecioUnidad.Ejecutar(AOwner: TComponent;
  AConexion: TUniConnection; const AContexto: TContextoContenidoSku): Boolean;
var
  oFormulario: TfrmModalPrecioUnidad;
begin
  oFormulario := TfrmModalPrecioUnidad.Create(AOwner);
  try
    oFormulario.FConexion := AConexion;
    oFormulario.FContexto := AContexto;
    oFormulario.CrearControles;
    oFormulario.Cargar;
    Result := oFormulario.ShowModal = mrOk;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
