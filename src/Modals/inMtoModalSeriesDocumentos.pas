{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSeriesDocumentos                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Captura de ubicación y serie tokenizada para el alta masiva de series   }
{    de empresa en todos los tipos de documento.                              }
{******************************************************************************}
unit inMtoModalSeriesDocumentos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ActnList, System.Actions, Data.DB,
  DBAccess, Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  inMtoFrmBase, UniDataSeriesDocumentosRepositorio;

type
  TfrmModalSeriesDocumentos = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblAlmacen: TcxLabel;
    cbbAlmacen: TcxLookupComboBox;
    lblCaja: TcxLabel;
    cbbCaja: TcxLookupComboBox;
    lblSerieTokenizada: TcxLabel;
    txtSerieTokenizada: TcxTextEdit;
    lblLeyendaTokens: TcxLabel;
    lblLeyendaSubtipos: TcxLabel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    dsAlmacenes: TDataSource;
    dsCajas: TDataSource;
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbbAlmacenPropertiesEditValueChanged(Sender: TObject);
  private
    FAlmacen: string;
    FCaja: string;
    FRepositorio: TRepositorioSeriesDocumentos;
    FSerieTokenizada: string;
    procedure CargarCajas;
  public
    class function Ejecutar(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const AEmpresa: string;
      out AAlmacen: string;
      out ACaja: string;
      out ASerieTokenizada: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgComun, inLibSerieTokenizada;

procedure ForceReferenceToClass(C: TClass);
begin
end;

class function TfrmModalSeriesDocumentos.Ejecutar(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const AEmpresa: string;
  out AAlmacen: string;
  out ACaja: string;
  out ASerieTokenizada: string): Boolean;
var
  frm: TfrmModalSeriesDocumentos;
begin
  Result := False;
  AAlmacen := '';
  ACaja := '';
  ASerieTokenizada := '';
  frm := TfrmModalSeriesDocumentos.Create(AOwner);
  try
    frm.FRepositorio := TRepositorioSeriesDocumentos.Create(
      frm, AConexion);
    frm.dsAlmacenes.DataSet := frm.FRepositorio.Almacenes;
    frm.dsCajas.DataSet := frm.FRepositorio.Cajas;
    frm.FRepositorio.AbrirAlmacenes(AEmpresa);
    frm.cbbAlmacen.EditValue := Null;
    frm.CargarCajas;
    if frm.ShowModal = mrOk then
    begin
      AAlmacen := frm.FAlmacen;
      ACaja := frm.FCaja;
      ASerieTokenizada := frm.FSerieTokenizada;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalSeriesDocumentos.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

procedure TfrmModalSeriesDocumentos.actAceptarExecute(Sender: TObject);
var
  sAlmacen: string;
  sCaja: string;
  sSerieTokenizada: string;
begin
  sAlmacen := Trim(VarToStr(cbbAlmacen.EditValue));
  sCaja := Trim(VarToStr(cbbCaja.EditValue));
  sSerieTokenizada := Trim(txtSerieTokenizada.Text);
  if sAlmacen = '' then
    sCaja := '';
  if sSerieTokenizada = '' then
  begin
    MessageDlg_fza(
      SErrorSerieDocumentoNoIndicada,
      mtWarning,
      [mbOk],
      0);
    txtSerieTokenizada.SetFocus;
  end
  else if not EsSerieTokenizadaValida(sSerieTokenizada) then
  begin
    MessageDlg_fza(
      Format(SErrorSerieTokenizadaEmpresa, [sSerieTokenizada]),
      mtWarning,
      [mbOk],
      0);
    txtSerieTokenizada.SetFocus;
  end
  else
  begin
    FAlmacen := sAlmacen;
    FCaja := sCaja;
    FSerieTokenizada := sSerieTokenizada;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalSeriesDocumentos.CargarCajas;
var
  sAlmacen: string;
begin
  sAlmacen := Trim(VarToStr(cbbAlmacen.EditValue));
  cbbCaja.EditValue := Null;
  FRepositorio.Cajas.Close;
  cbbCaja.Enabled := sAlmacen <> '';
  if sAlmacen <> '' then
    FRepositorio.AbrirCajas(sAlmacen);
end;

procedure TfrmModalSeriesDocumentos.cbbAlmacenPropertiesEditValueChanged(
  Sender: TObject);
begin
  CargarCajas;
end;

procedure TfrmModalSeriesDocumentos.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
