{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpDevCompra                                        }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       23/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion de un devolucion de compra. Hereda del modal generico  }
{    TfrmPrint. Misma logica que inMtoModalImpSesion pero contra los datasets  }
{    de devoluciones (TdmDevolucionesCompra.PrepararPrint y los fxds*          }
{    asociados).                                                               }
{    La orientacion (horizontal / vertical) la decide el llamador via la       }
{    propiedad Orientacion; el report .fr3 embebido en frxrprt1 se disena      }
{    a mano con el FastReport designer.                                        }
{******************************************************************************}
unit inMtoModalImpDevCompra;

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
  inMtoModalGenImp, UniDataDevolucionesCompra;

type
  TfrmPrintDevCompra = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  protected
    procedure PrepararDatosEdicion; override;
  public
    dmDevc: TdmDevolucionesCompra;
    procedure preparar_consulta; override;
    procedure AfterReportLoaded; override;
  end;

implementation

uses
  inMtoPreviewExcel, inLibDocCompraExcel;

{$R *.dfm}

resourcestring
  SNombreArchivoDevolucionCompra = 'DevCompra_%s_%s';
  STituloPreviewDevolucionCompra = 'DEVOLUCION A PROVEEDOR';
  SEtiquetaAlmacenSalidaDevolucionCompra = 'ALMACEN SALIDA';

procedure TfrmPrintDevCompra.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  cfg: TDocCompraCabCfg;
begin
  if dmDevc <> nil then
  begin
    dmDevc.PrepararPrint(edtSerie.Text, edtNumero.Text);
  cfg := Default(TDocCompraCabCfg);
  cfg.Titulo         := STituloPreviewDevolucionCompra;
  cfg.EtiquetaIzq    := SEtiquetaAlmacenSalidaDevolucionCompra;
  cfg.FieldRazonIzq  := 'NOMBRE_ALM_DEVC';
  cfg.FieldDirIzq    := 'DIRECCION_ALM_DEVC';
  cfg.FieldCPIzq     := 'CODIGO_POSTAL_ALM_DEVC';
  cfg.FieldPobIzq    := 'POBLACION_ALM_DEVC';
  cfg.FieldCifIzq    := 'CIF_EMP';
  cfg.FieldTelIzq    := 'TELEFONO_ALM_DEVC';
  cfg.FieldProvIzq   := 'PROVINCIA_ALM_DEVC';
  cfg.FieldRazonPrv  := 'RAZON_SOCIAL_PRV';
  cfg.FieldDirPrv    := 'DIRECCION1_PRV';
  cfg.FieldCPPrv     := 'CODIGO_POSTAL_PRV';
  cfg.FieldPobPrv    := 'POBLACION_PRV';
  cfg.FieldCifPrv    := 'CIF_PRV';
  cfg.FieldTelPrv    := 'TELEFONO1_PRV';
  cfg.FieldProvPrv   := 'PROVINCIA_PRV';
  cfg.FieldSerie     := 'SERIE_DEVC';
  cfg.FieldNumero    := 'NUMERO_DEVC';
  cfg.FieldFecha     := 'FECHA_DEVC';
  cfg.FieldEstado    := 'ESTADO_DEVC';
  cfg.FieldRefPrv    := 'REF_PROVEEDOR_DEVC';
  cfg.MostrarPrecioVenta := False;
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName :=
      Format(SNombreArchivoDevolucionCompra,
        [edtSerie.Text, edtNumero.Text]);
    try
      ExportarDocCompraHorizontal(ConexionPrincipal,fPreview.dxSpreadSheet1,
        dmDevc.unqryCabDevcPrint,
        dmDevc.unqryLinDevcPrint,
        dmDevc.unqryGuiasDevcPrint,
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

procedure TfrmPrintDevCompra.FormCreate(Sender: TObject);
begin
  inherited;
  // El diseno FastReport vive embebido en frxrprt1 (.dfm). Lo
  // duplicamos en frxReportOrigen para que la opcion "Predeterminado"
  // de Consultar_Formularios (frxrprt1.AssignAll(frxReportOrigen))
  // restaure el diseno original en vez de vaciar el report. Mismo
  // patron que TfrmPrintSesion.
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintDevCompra.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintDevCompra.preparar_consulta;
begin
  if dmDevc <> nil then
    dmDevc.PrepararPrint(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintDevCompra.AfterReportLoaded;
begin
  inherited;
  if dmDevc <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmDevc);
end;

end.
