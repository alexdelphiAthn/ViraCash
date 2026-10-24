{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpAlbCompraV                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion VERTICAL del albaran de compra. Estilo factura:        }
{    una fila por SKU sin pivotar tallas. Hereda de TfrmPrint igual que        }
{    el modal horizontal pero usa LineasAlbaranSku (no LineasAlbaran) y        }
{    tiene su propio diseno FastReport embebido (a disenar con el FR          }
{    designer la primera vez que se abra).                                     }
{******************************************************************************}
unit inMtoModalImpAlbCompraV;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls, Vcl.ActnList,
  System.Actions,
  Data.DB, MemDS, DBAccess, Uni,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxContainer,
  cxEdit, cxTextEdit, cxLabel, cxButtons, cxClasses, cxLocalization, cxStyles,
  cxMaskEdit,
  dxSkinsCore, dxSkinBlue, dxSkinsForm, dxSkinsDefaultPainters,
  frxClass, frxDBSet, frxDesgn, frxExportBaseDialog, frxExportPDF,
  frxExportXLSX, frxExportBaseImageSettingsDialog, frCoreClasses,
  frLocalization, frLanguageSpanish, frxSmartMemo,
  JvComponentBase, JvEnterTab,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetStyles, dxHashUtils,
  inMtoModalGenImp, UniDataAlbaranesCompra;

type
  TfrmPrintAlbCompraV = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  protected
    procedure PrepararDatosEdicion; override;
  public
    dmAlbc: TdmAlbaranesCompra;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  inMtoPreviewExcel, inLibDocCompraExcel;

{$R *.dfm}

resourcestring
  SNombreArchivoAlbaranCompraVertical = 'AlbCompraV_%s_%s';
  STituloPreviewAlbaranCompraVertical = 'ALBARAN DE COMPRA';
  SEtiquetaAlmacenDestinoAlbaranCompraVertical = 'ALMACEN DESTINO';

procedure TfrmPrintAlbCompraV.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  cfg: TDocCompraCabCfg;
begin
  if dmAlbc <> nil then
  begin
    dmAlbc.PrepararPrintSku(edtSerie.Text, edtNumero.Text);
  cfg := Default(TDocCompraCabCfg);
  cfg.Titulo         := STituloPreviewAlbaranCompraVertical;
  cfg.EtiquetaIzq    := SEtiquetaAlmacenDestinoAlbaranCompraVertical;
  cfg.FieldRazonIzq  := 'NOMBRE_ALM_ALBC';
  cfg.FieldDirIzq    := 'DIRECCION_ALM_ALBC';
  cfg.FieldCPIzq     := 'CODIGO_POSTAL_ALM_ALBC';
  cfg.FieldPobIzq    := 'POBLACION_ALM_ALBC';
  cfg.FieldCifIzq    := 'CIF_EMP';
  cfg.FieldTelIzq    := 'TELEFONO_ALM_ALBC';
  cfg.FieldProvIzq   := 'PROVINCIA_ALM_ALBC';
  cfg.FieldRazonPrv  := 'RAZON_SOCIAL_PRV';
  cfg.FieldDirPrv    := 'DIRECCION1_PRV';
  cfg.FieldCPPrv     := 'CODIGO_POSTAL_PRV';
  cfg.FieldPobPrv    := 'POBLACION_PRV';
  cfg.FieldCifPrv    := 'CIF_PRV';
  cfg.FieldTelPrv    := 'TELEFONO1_PRV';
  cfg.FieldProvPrv   := 'PROVINCIA_PRV';
  cfg.FieldSerie     := 'SERIE_ALBC';
  cfg.FieldNumero    := 'NUMERO_ALBC';
  cfg.FieldFecha     := 'FECHA_ALBC';
  cfg.FieldEstado    := 'ESTADO_ALBC';
  cfg.FieldRefPrv    := 'REF_PROVEEDOR_ALBC';
  cfg.MostrarPrecioVenta := False;
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName :=
      Format(SNombreArchivoAlbaranCompraVertical,
        [edtSerie.Text, edtNumero.Text]);
    try
      ExportarDocCompraVertical(ConexionPrincipal,fPreview.dxSpreadSheet1,
        dmAlbc.unqryCabAlbcPrint,
        dmAlbc.unqryLinAlbcSkuPrint,
        cfg);
    finally
      Screen.Cursor := crDefault;
    end;
    fPreview.ShowModal;
  finally
    FreeAndNil(fPreview);
  end;
  end;
end;

procedure TfrmPrintAlbCompraV.FormCreate(Sender: TObject);
begin
  inherited;
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintAlbCompraV.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintAlbCompraV.preparar_consulta;
begin
  if dmAlbc <> nil then
    dmAlbc.PrepararPrintSku(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintAlbCompraV.AfterReportLoaded;
begin
  inherited;
  if dmAlbc <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmAlbc);
end;

end.
