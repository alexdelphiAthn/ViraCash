{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCliEti                                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal de impresion de etiquetas de clientes.                              }
{    Permite codigo de cliente y numero de blancos a dejar.                    }
{******************************************************************************}
unit inMtoModalCliEti;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoModalGenImp, cxGraphics,
  cxLookAndFeels, cxLookAndFeelPainters, Vcl.Menus, frxDesgn, Data.DB, MemDS,
  DBAccess, Uni, frxExportXLSX, frxClass, frxExportBaseDialog, frxExportPDF,
  cxClasses, cxLocalization, Vcl.StdCtrls, cxButtons, Vcl.ExtCtrls, dxSkinsCore,
  dxSkinBlue, cxControls, cxContainer, cxEdit, cxTextEdit, cxMaskEdit,
  cxSpinEdit, cxLabel, cxGroupBox, cxRadioGroup, UniDataClientes,
  JvComponentBase, JvEnterTab, frxSmartMemo, frLocalization, frLanguageSpanish,
  System.Actions, Vcl.ActnList, frxExportBaseImageSettingsDialog, frCoreClasses;

type
  TfrmPrintCliEti = class(TfrmPrint)
    cxRadioGroup1: TcxRadioGroup;
    cxlbl2: TcxLabel;
    speDejarBlancos: TcxSpinEdit;
    edtCodCli: TcxTextEdit;
    cxLabel1: TcxLabel;
  private
    FDataModule: TdmClientes;
  public
    procedure Preparar(ADataModule: TdmClientes);
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

resourcestring
  SErrorModuloClientesNoIndicado =
    'No se ha indicado el módulo de clientes';
  SErrorModuloClientesObligatorio =
    'El módulo de clientes es obligatorio';

procedure TfrmPrintCliEti.preparar_consulta;
begin
  if not Assigned(FDataModule) then
    raise EArgumentNilException.Create(
      SErrorModuloClientesNoIndicado);
  FDataModule.CrearDataSetEtiquetas(speDejarBlancos.Value, edtCodCli.text);
end;

procedure TfrmPrintCliEti.Preparar(ADataModule: TdmClientes);
begin
  if not Assigned(ADataModule) then
    raise EArgumentNilException.Create(SErrorModuloClientesObligatorio);
  FDataModule := ADataModule;
end;

end.
