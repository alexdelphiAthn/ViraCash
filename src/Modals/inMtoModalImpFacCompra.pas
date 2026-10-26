{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpFacCompra                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de una factura de compra. Hereda del modal generico    }
{    TfrmPrint. Misma logica que inMtoModalImpSesion pero contra los datasets  }
{    de facturas (TdmFacturasCompra.PrepararPrint y los fxds* asociados).    }
{    La orientacion (horizontal / vertical) la decide el llamador via la       }
{    propiedad Orientacion; el report .fr3 embebido en frxrprt1 se disena      }
{    a mano con el FastReport designer.                                        }
{******************************************************************************}
unit inMtoModalImpFacCompra;

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
  TfrmPrintFacCompra = class(TfrmPrint)
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
  SNombreArchivoFacturaCompra = 'FacCompra_%s_%s';
  STituloPreviewFacturaCompra = 'FACTURA DE COMPRA';
  SEtiquetaAlmacenDestinoFacturaCompra = 'ALMACEN DESTINO';

procedure TfrmPrintFacCompra.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  cfg: TDocCompraCabCfg;
begin
  if dmFacc = nil then
    ShowMessage_fza(SErrorFacturaCompraExportarNoPreparada)
  else
  begin
    dmFacc.PrepararPrint(edtSerie.Text, edtNumero.Text);
    cfg := Default(TDocCompraCabCfg);
    cfg.Titulo         := STituloPreviewFacturaCompra;
    cfg.EtiquetaIzq    := SEtiquetaAlmacenDestinoFacturaCompra;
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
          Format(SNombreArchivoFacturaCompra,
            [edtSerie.Text, edtNumero.Text]);
        ExportarDocCompraHorizontal(ConexionPrincipal,fPreview.dxSpreadSheet1,
          dmFacc.unqryCabFaccPrint,
          dmFacc.unqryLinFaccPrint,
          dmFacc.unqryGuiasFaccPrint,
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

procedure TfrmPrintFacCompra.FormCreate(Sender: TObject);
begin
  inherited;
  // El diseno FastReport vive embebido en frxrprt1 (.dfm). Lo
  // duplicamos en frxReportOrigen para que la opcion "Predeterminado"
  // de Consultar_Formularios (frxrprt1.AssignAll(frxReportOrigen))
  // restaure el diseno original en vez de vaciar el report. Mismo
  // patron que TfrmPrintSesion.
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintFacCompra.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintFacCompra.preparar_consulta;
begin
  if dmFacc <> nil then
  begin
    dmFacc.PrepararPrint(edtSerie.Text, edtNumero.Text);
    AdaptarInformeCompraDirecta(frxrprt1, dmFacc.unqryCabFaccPrint);
  end;
end;

procedure TfrmPrintFacCompra.AfterReportLoaded;
begin
  inherited;
  if dmFacc <> nil then
  begin
    RebindReportDataSetsByDataModule(frxrprt1, dmFacc);
    AdaptarInformeCompraDirecta(frxrprt1, dmFacc.unqryCabFaccPrint);
  end;
end;

end.
