{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAceptCancel                                         }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal generico de aceptar/cancelar.                                       }
{    Reutilizable como base para confirmaciones simples en toda la app.        }
{******************************************************************************}
unit inMtoModalAceptCancel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, JvComponentBase,
  JvEnterTab, cxClasses, cxLocalization, Vcl.ExtCtrls, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, Vcl.StdCtrls, cxButtons,
  System.Actions, Vcl.ActnList;

type
  TfrmModalAceptCancel = class(TfrmBase)
    pnlButton: TPanel;
    btnCancelar: TcxButton;
    btnAceptar: TcxButton;
    pnlBody: TPanel;
    ActionList1: TActionList;
    Action1: TAction;
    Action2: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Action1Execute(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure Action2Execute(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    sFicha:String;
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TfrmModalAceptCancel.Action1Execute(Sender: TObject);
begin
  inherited;
  btnAceptarClick(Sender);
end;

procedure TfrmModalAceptCancel.Action2Execute(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalAceptCancel.btnAceptarClick(Sender: TObject);
begin
  inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalAceptCancel.btnCancelarClick(Sender: TObject);
begin
  inherited;
  sFicha := 'N';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmModalAceptCancel.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmModalAceptCancel.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalAceptCancel.FormShow(Sender: TObject);
begin
  inherited;
  // FZ-ISSUE-136: un descendiente puede ocultar o deshabilitar Aceptar
  // (p. ej. la verificación de NIF); CanBeFocused no lo cubre y SetFocus
  // lanzaría EInvalidOperation.
  if btnAceptar.Visible and btnAceptar.Enabled and
     btnAceptar.CanBeFocused then
    btnAceptar.SetFocus;
end;

end.
