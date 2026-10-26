{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpFacCompraV                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion VERTICAL de factura de compra. Estilo factura:         }
{    una fila por SKU sin pivotar tallas. Hereda de TfrmPrint igual que        }
{    el modal horizontal pero usa LineasFacturaSku (no LineasFactura) y        }
{    tiene su propio diseno FastReport embebido (a disenar con el FR          }
{    designer la primera vez que se abra).                                     }
{******************************************************************************}
unit inMtoModalImpFacCompraV;

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
  inMtoModalGenImp, UniDataFacturasCompra;

type
  TfrmPrintFacCompraV = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  protected
    procedure PrepararDatosEdicion; override;
  public
    dmFacc: TdmFacturasCompra;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inMtoPreviewExcel, inLibDocCompraExcel, inLibMsgCompras,
  inLibComprasDirectasInforme;

{$R *.dfm}

resourcestring
  SNombreArchivoFacturaCompraVertical = 'FacCompraV_%s_%s';
  STituloPreviewFacturaCompraVertical = 'FACTURA DE COMPRA';
  SEtiquetaAlmacenDestinoFacturaCompraVertical = 'ALMACEN DESTINO';

procedure TfrmPrintFacCompraV.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  cfg: TDocCompraCabCfg;
begin
  if dmFacc = nil then
    ShowMessage_fza(SErrorFacturaCompraExportarNoPreparada)
  else
  begin
    dmFacc.PrepararPrintSku(edtSerie.Text, edtNumero.Text);
    cfg := Default(TDocCompraCabCfg);
    cfg.Titulo         := STituloPreviewFacturaCompraVertical;
    cfg.EtiquetaIzq    := SEtiquetaAlmacenDestinoFacturaCompraVertical;
    cfg.FieldRazonIzq  := 'NOMBRE_ALM_FACC';
    cfg.FieldDirIzq    := 'DIRECCION_ALM_FACC';
    cfg.FieldCPIzq     := 'CODIGO_POSTAL_ALM_FACC';
    cfg.FieldPobIzq    := 'POBLACION_ALM_FACC';
    cfg.FieldCifIzq    := 'CIF_EMP';
    cfg.FieldTelIzq    := 'TELEFONO_ALM_FACC';
    cfg.FieldProvIzq   := 'PROVINCIA_ALM_FACC';
    cfg.FieldRazonPrv  := 'RAZON_SOCIAL_PRV';
    cfg.FieldDirPrv    := 'DIRECCION1_PRV';
    cfg.FieldCPPrv     := 'CODIGO_POSTAL_PRV';
    cfg.FieldPobPrv    := 'POBLACION_PRV';
    cfg.FieldCifPrv    := 'CIF_PRV';
    cfg.FieldTelPrv    := 'TELEFONO1_PRV';
    cfg.FieldProvPrv   := 'PROVINCIA_PRV';
    cfg.FieldSerie     := 'SERIE_FACC';
    cfg.FieldNumero    := 'NUMERO_FACC';
    cfg.FieldFecha     := 'FECHA_FACC';
    cfg.FieldEstado    := 'ESTADO_FACC';
    cfg.FieldRefPrv    := 'REF_PROVEEDOR_FACC';
    cfg.MostrarPrecioVenta := False;
    AdaptarExcelCompraDirecta(dmFacc.unqryCabFaccPrint, cfg);
    Screen.Cursor := crHourGlass;
    try
      fPreview := TfrmMtoPreviewExcel.Create(Self);
      try
        fPreview.PopupParent := Self;
        fPreview.DialogoGuardar.InitialDir :=
          ParametrosApp.GetPath('appDirExcel');
        fPreview.DialogoGuardar.FileName :=
          Format(SNombreArchivoFacturaCompraVertical,
            [edtSerie.Text, edtNumero.Text]);
        ExportarDocCompraVertical(ConexionPrincipal,fPreview.dxSpreadSheet1,
          dmFacc.unqryCabFaccPrint,
          dmFacc.unqryLinFaccSkuPrint,
          cfg);
        Screen.Cursor := crDefault;
        fPreview.ShowModal;
      finally
        FreeAndNil(fPreview);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmPrintFacCompraV.FormCreate(Sender: TObject);
begin
  inherited;
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintFacCompraV.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintFacCompraV.preparar_consulta;
begin
  if dmFacc <> nil then
  begin
    dmFacc.PrepararPrintSku(edtSerie.Text, edtNumero.Text);
    AdaptarInformeCompraDirecta(frxrprt1, dmFacc.unqryCabFaccPrint);
  end;
end;

procedure TfrmPrintFacCompraV.AfterReportLoaded;
begin
  inherited;
  if dmFacc <> nil then
  begin
    RebindReportDataSetsByDataModule(frxrprt1, dmFacc);
    AdaptarInformeCompraDirecta(frxrprt1, dmFacc.unqryCabFaccPrint);
  end;
end;

end.
