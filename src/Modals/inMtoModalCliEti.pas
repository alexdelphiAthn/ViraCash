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
  dxSpreadSheet,
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
  protected
    procedure DoShow; override;
    procedure ConstruirExcelNativo(AControl: TdxSpreadSheet); override;
    procedure PrepararDatosEdicion; override;
  public
    procedure Preparar(ADataModule: TdmClientes);
    procedure preparar_consulta; override;
  end;

implementation

uses
  inLibMsgComun,
  inLibInformeTabular, inLibInformeTabularExcel;

{$R *.dfm}

resourcestring
  SErrorModuloClientesNoIndicado =
    'No se ha indicado el módulo de clientes';
  SErrorModuloClientesObligatorio =
    'El módulo de clientes es obligatorio';

procedure TfrmPrintCliEti.PrepararDatosEdicion;
begin
  // cdsEtiquetas no tiene proveedor: sin cargarlo antes, el diseñador
  // fallaba con «Missing data provider or data packet».
  preparar_consulta;
end;

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

procedure TfrmPrintCliEti.DoShow;
begin
  inherited;
  btnExcel.OnClick := btnExcelNativoClick;
end;

procedure TfrmPrintCliEti.ConstruirExcelNativo(
  AControl: TdxSpreadSheet);
begin
  ExportarInformeTabularExcel(AControl, FDataModule.unqryCliPrint,
    Caption,
    [ColumnaInforme('CODIGO_CLI_CLI', STextoClienteComun, 1),
     ColumnaInforme('RAZON_SOCIAL_CLI', STextoNombreComun, 3),
     ColumnaInforme('DIRECCION1_CLI', STextoDireccionComun, 3),
     ColumnaInforme('DIRECCION2_CLI', STextoDireccionAdicionalComun, 3),
     ColumnaInforme('CODIGO_POSTAL_CLI', STextoCodigoPostalComun, 1),
     ColumnaInforme('POBLACION_CLI', STextoPoblacionComun, 2),
     ColumnaInforme('PROVINCIA_CLI', STextoProvinciaComun, 2),
     ColumnaInforme('NOMBRE_PAI_CLI', STextoPaisComun, 1)],
    LineasResumenSelecciones + ['Cliente: ' + edtCodCli.Text]);
end;

end.
