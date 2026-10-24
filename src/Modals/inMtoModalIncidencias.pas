{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalIncidencias                                         }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal generico de presentacion de incidencias / errores en bloque.        }
{    Recibe un TStrings con un mensaje por linea y lo muestra en un memo       }
{    de solo lectura, con boton Aceptar para cerrar.                           }
{    Usado por inMtoComprasSesiones antes de materializar (validador detallado)}
{******************************************************************************}
unit inMtoModalIncidencias;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxMemo;

type
  TfrmModalIncidencias = class(TfrmBase)
    pnlBody    : TPanel;
    pnlButton  : TPanel;
    lblTitulo  : TcxLabel;
    memInc     : TcxMemo;
    btnAceptar : TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAceptarClick(Sender: TObject);
  public
    class procedure Mostrar(
      AOwner: TComponent;
      const ATitulo: string;
      ALineas: TStrings); static;
    class procedure MostrarMensaje(
      AOwner: TComponent;
      const ATitulo, AMensaje: string); static;
    procedure SetIncidencias(const ATitulo: string; ALineas: TStrings);
  end;

implementation

{$R *.dfm}

class procedure TfrmModalIncidencias.Mostrar(
  AOwner: TComponent;
  const ATitulo: string;
  ALineas: TStrings);
var
  Formulario: TfrmModalIncidencias;
begin
  Formulario := TfrmModalIncidencias.Create(AOwner);
  Formulario.OnClose := nil;
  try
    Formulario.SetIncidencias(ATitulo, ALineas);
    Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

class procedure TfrmModalIncidencias.MostrarMensaje(
  AOwner: TComponent;
  const ATitulo, AMensaje: string);
var
  Lineas: TStringList;
begin
  Lineas := TStringList.Create;
  try
    Lineas.Add(AMensaje);
    Mostrar(AOwner, ATitulo, Lineas);
  finally
    FreeAndNil(Lineas);
  end;
end;

procedure TfrmModalIncidencias.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
end;

procedure TfrmModalIncidencias.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caFree;
end;

procedure TfrmModalIncidencias.btnAceptarClick(Sender: TObject);
begin
  inherited;
  ModalResult := mrOk;
end;

procedure TfrmModalIncidencias.SetIncidencias(const ATitulo: string;
                                               ALineas: TStrings);
begin
  if ATitulo <> '' then lblTitulo.Caption := ATitulo;
  memInc.Lines.BeginUpdate;
  try
    memInc.Lines.Clear;
    if ALineas <> nil then memInc.Lines.Assign(ALineas);
  finally
    memInc.Lines.EndUpdate;
  end;
end;

end.
