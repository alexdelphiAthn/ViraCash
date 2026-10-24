{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAltaRapida                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de alta rapida con codigo y descripcion.                            }
{    Construye campos dinamicos sobre un ScrollBox segun el llamante.          }
{******************************************************************************}
unit inMtoModalAltaRapida;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxLabel, cxScrollBox, cxTextEdit, cxButtons, cxClasses, Vcl.Menus,
  inMtoFrmBase;

type
  TfrmMtoModalAltaRapida = class(TfrmBase)
    ScrollBox: TcxScrollBox;
    pnlBotones: TPanel;
    btnOk: TcxButton;
    btnCancel: TcxButton;
    lblCod: TcxLabel;
    edtCod: TcxTextEdit;
    lblDesc: TcxLabel;
    edtDesc: TcxTextEdit;
    BevelSep: TBevel;
  public
    const DynStartTop = 140;
    const ColMargin   = 25;
    const ColWidth    = 380;
    const FieldStep   = 55;
  end;

implementation

{$R *.dfm}

end.
