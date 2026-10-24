{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalEnviarDestino                                       }
{    Tipo:       Modal                                                         }
{ Version:       1.0.0                                                        }
{   Fecha:       07/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal generico de destino de documento para el "Enviar a..." de           }
{    Documentos de Trabajo (y futuros): almacen y serie en combos              }
{    (fza_almacenes / fza_empresas_series por tipo de documento) y             }
{    numero editable (por defecto '0' = lo asigna el contador del Mto          }
{    destino al grabar).                                                       }
{******************************************************************************}
unit inMtoModalEnviarDestino;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxButtons, inMtoFrmBase, inLibDestinoEnvioPersistenciaIntf;

type
  TfrmModalEnviarDestino = class(TfrmBase)
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxComboBox;
    lblSerie: TcxLabel;
    cbbSerie: TcxComboBox;
    lblNumero: TcxLabel;
    txtNumero: TcxTextEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
  public
    // Devuelve True si el usuario acepta; AAlm/ASerie/ANumero entran
    // como valores por defecto y salen con lo elegido.
    class function Ejecutar(AOwner: TComponent;
                            AConn: TUniConnection;
                            const ATitulo, AEmpresa,
                                  ATipoDocSerie: string;
                            var AAlm, ASerie, ANumero: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgComun,
  inLibVentasPantallaIntf,
  UniDataVentasPantallaComposicion;

class function TfrmModalEnviarDestino.Ejecutar(AOwner: TComponent;
  AConn: TUniConnection; const ATitulo, AEmpresa,
  ATipoDocSerie: string; var AAlm, ASerie, ANumero: string): Boolean;
var
  frm: TfrmModalEnviarDestino;
  aAlmacenes: TValoresDestinoEnvio;
  aSeries: TValoresDestinoEnvio;
  oContexto: TContextoDestinoEnvioVentasPantalla;
  oRepositorio: IRepositorioDestinoEnvio;
  sValor: string;
begin
  Result := False;
  frm := TfrmModalEnviarDestino.Create(AOwner);
  try
    frm.Caption := ATitulo;
    CrearContextoVentasPantalla(
      AConn,
      oContexto);
    oRepositorio := oContexto.Repositorio;
    aAlmacenes := oRepositorio.ListarAlmacenes(AEmpresa);
    for sValor in aAlmacenes do
    begin
      frm.cbbAlmacen.Properties.Items.Add(sValor);
    end;
    frm.cbbAlmacen.ItemIndex :=
      frm.cbbAlmacen.Properties.Items.IndexOf(AAlm);
    if (frm.cbbAlmacen.ItemIndex < 0) and
       (frm.cbbAlmacen.Properties.Items.Count > 0) then
      frm.cbbAlmacen.ItemIndex := 0;
    aSeries := oRepositorio.ListarSeries(AEmpresa, ATipoDocSerie);
    for sValor in aSeries do
    begin
      frm.cbbSerie.Properties.Items.Add(sValor);
    end;
    frm.cbbSerie.ItemIndex :=
      frm.cbbSerie.Properties.Items.IndexOf(ASerie);
    if (frm.cbbSerie.ItemIndex < 0) and
       (frm.cbbSerie.Properties.Items.Count > 0) then
      frm.cbbSerie.ItemIndex := 0;
    if ANumero = '' then
      frm.txtNumero.Text := '0'
    else
      frm.txtNumero.Text := ANumero;
    if frm.ShowModal = mrOk then
    begin
      AAlm := Trim(frm.cbbAlmacen.Text);
      ASerie := Trim(frm.cbbSerie.Text);
      ANumero := Trim(frm.txtNumero.Text);
      Result := (AAlm <> '') and (ASerie <> '') and (ANumero <> '');
      if not Result then
        ShowMessage_fza(SErrorDestinoEnvioIncompleto);
    end;
  finally
    FreeAndNil(frm);
  end;
end;

end.
