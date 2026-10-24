{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalEmpCer                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de seleccion de certificado de empresa.                             }
{    Lista los certificados disponibles y devuelve el elegido.                 }
{******************************************************************************}
unit inMtoModalEmpCer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, system.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxCore, dxSkinsForm,
  cxClasses, cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics,
  cxControls, cxLookAndFeelPainters, cxCustomListBox, cxCheckListBox,
  cxDBCheckListBox, UniDataArticulos, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  Vcl.ExtCtrls, cxStyles, Data.DB, JvComponentBase, JvEnterTab,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGrid,
  inLibCertificates;

type
  TfrmMtoModalEmpCer = class(TfrmBase)
    pnl1: TPanel;
    btnCancelar1: TcxButton;
    btnAceptar: TcxButton;
    cxgrdCertificados: TcxGrid;
    tvCertificados: TcxGridTableView;
    colTipoCertificado: TcxGridColumn;
    colTitularCertificado: TcxGridColumn;
    colNombreCertificado: TcxGridColumn;
    colEmisorCertificado: TcxGridColumn;
    colFechaHastaCertificado: TcxGridColumn;
    colNumeroSerieCertificado: TcxGridColumn;
    lvCertificados: TcxGridLevel;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }

  public
    sFicha:string;
    { Public declarations }
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgComun;

procedure TfrmMtoModalEmpCer.btnAceptarClick(Sender: TObject);
begin
  inherited;
  if tvCertificados.Controller.FocusedRecord = nil then
  begin
    ShowMessage_fza(SErrorCertificadoNoSeleccionado);
  end
  else
  begin
    sFicha := 'S';
    PostMessage(Handle, WM_CLOSE, 0, 0);
  end;
end;

procedure TfrmMtoModalEmpCer.btnCancelarClick(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoModalEmpCer.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmMtoModalEmpCer.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  sFicha := 'N';
  CargarCertificados(tvCertificados);
  tvCertificados.ApplyBestFit;
end;

end.
