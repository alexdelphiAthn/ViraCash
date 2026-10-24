{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpAlbCompra                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de un albaran de compra. Hereda del modal generico     }
{    TfrmPrint. Misma logica que inMtoModalImpSesion pero contra los datasets  }
{    de albaranes (TdmAlbaranesCompra.PrepararPrint y los fxds* asociados).    }
{    La orientacion (horizontal / vertical) la decide el llamador via la       }
{    propiedad Orientacion; el report .fr3 embebido en frxrprt1 se disena      }
{    a mano con el FastReport designer.                                        }
{******************************************************************************}
unit inMtoModalImpAlbCompra;

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
  TfrmPrintAlbCompra = class(TfrmPrint)
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
  SNombreArchivoAlbaranCompra = 'AlbCompra_%s_%s';
  STituloPreviewAlbaranCompra = 'ALBARAN DE COMPRA';
  SEtiquetaAlmacenDestinoAlbaranCompra = 'ALMACEN DESTINO';

procedure TfrmPrintAlbCompra.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  cfg: TDocCompraCabCfg;
begin
  if dmAlbc <> nil then
  begin
    dmAlbc.PrepararPrint(edtSerie.Text, edtNumero.Text);
  cfg := Default(TDocCompraCabCfg);
  cfg.Titulo         := STituloPreviewAlbaranCompra;
  cfg.EtiquetaIzq    := SEtiquetaAlmacenDestinoAlbaranCompra;
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
      Format(SNombreArchivoAlbaranCompra,
        [edtSerie.Text, edtNumero.Text]);
    try
      ExportarDocCompraHorizontal(ConexionPrincipal,fPreview.dxSpreadSheet1,
        dmAlbc.unqryCabAlbcPrint,
        dmAlbc.unqryLinAlbcPrint,
        dmAlbc.unqryGuiasAlbcPrint,
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

procedure TfrmPrintAlbCompra.FormCreate(Sender: TObject);
begin
  inherited;
  // El diseno FastReport vive embebido en frxrprt1 (.dfm). Lo
  // duplicamos en frxReportOrigen para que la opcion "Predeterminado"
  // de Consultar_Formularios (frxrprt1.AssignAll(frxReportOrigen))
  // restaure el diseno original en vez de vaciar el report. Mismo
  // patron que TfrmPrintSesion.
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintAlbCompra.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintAlbCompra.preparar_consulta;
begin
  if dmAlbc <> nil then
    dmAlbc.PrepararPrint(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintAlbCompra.AfterReportLoaded;
begin
  inherited;
  if dmAlbc <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmAlbc);
end;

end.
