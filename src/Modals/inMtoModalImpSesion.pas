{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalImpSesion                                           }
{    Tipo:       Formulario (Modal)                                            }
{ Version:       0.1.0                                                         }
{   Fecha:       19/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Modal de impresion HORIZONTAL (apaisado) de una sesion de compra.         }
{    Hereda del modal generico de impresion (TfrmPrint). Las tallas viven      }
{    en columnas T01..T21 — el limite coincide con CANT_TALLAS_MAX del         }
{    Mto consumidor inMtoComprasSesiones.                                      }
{                                                                              }
{    Datos: tres TfrxDBDataset montados en TdmComprasSesiones                  }
{      - Sesiones      : cabecera enriquecida (empresa + proveedor + totales)  }
{      - LineasSesiones: una linea = un articulo, con T01..T21 cantidades      }
{      - GuiasTallas   : leyenda con T01..T21 rotulos por sistema usado        }
{                                                                              }
{    Documentado en                                                            }
{    DESARROLLOS EN CURSO/compras_sesiones.md (impresion horizontal).          }
{******************************************************************************}
unit inMtoModalImpSesion;

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
  inMtoModalGenImp, UniDataComprasSesiones;

type
  TfrmPrintSesion = class(TfrmPrint)
    lblSerie:  TcxLabel;
    edtSerie:  TcxTextEdit;
    lblNumero: TcxLabel;
    edtNumero: TcxTextEdit;
    procedure FormCreate(Sender: TObject);
    procedure btnExcelClick(Sender: TObject);
  protected
    procedure PrepararDatosEdicion; override;
  public
    dmSesion: TdmComprasSesiones;
    procedure preparar_consulta;   override;
    procedure AfterReportLoaded;   override;
  end;

implementation

uses
  inMtoPreviewExcel, inLibDocCompraExcel;

{$R *.dfm}

resourcestring
  SNombreArchivoSesionCompra = 'Sesion_%s_%s';
  STituloPreviewSesionCompra = 'SESION DE COMPRA';
  SEtiquetaEmpresaSesionCompra = 'EMPRESA';

procedure TfrmPrintSesion.btnExcelClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  cfg: TDocCompraCabCfg;
begin
  if dmSesion <> nil then
  begin
    dmSesion.PrepararPrint(edtSerie.Text, edtNumero.Text);
  cfg := Default(TDocCompraCabCfg);
  cfg.Titulo         := STituloPreviewSesionCompra;
  cfg.EtiquetaIzq    := SEtiquetaEmpresaSesionCompra;
  cfg.FieldRazonIzq  := 'RAZON_SOCIAL_EMP';
  cfg.FieldDirIzq    := 'DIRECCION1_EMP';
  cfg.FieldCPIzq     := 'CODIGO_POSTAL_EMP';
  cfg.FieldPobIzq    := 'POBLACION_EMP';
  cfg.FieldCifIzq    := 'CIF_EMP';
  cfg.FieldTelIzq    := 'TELEFONO1_EMP';
  cfg.FieldProvIzq   := 'PROVINCIA_EMP';
  cfg.FieldRazonPrv  := 'RAZON_SOCIAL_PRV';
  cfg.FieldDirPrv    := 'DIRECCION1_PRV';
  cfg.FieldCPPrv     := 'CODIGO_POSTAL_PRV';
  cfg.FieldPobPrv    := 'POBLACION_PRV';
  cfg.FieldCifPrv    := 'CIF_PRV';
  cfg.FieldTelPrv    := 'TELEFONO1_PRV';
  cfg.FieldProvPrv   := 'PROVINCIA_PRV';
  cfg.FieldSerie     := 'SERIE_SES';
  cfg.FieldNumero    := 'NUMERO_SES';
  cfg.FieldFecha     := 'FECHA_SES';
  cfg.FieldEstado    := 'ESTADO_SES';
  cfg.FieldRefPrv    := 'REF_PRV_SES';
  cfg.MostrarPrecioVenta := True;
  Screen.Cursor := crHourGlass;
  fPreview := TfrmMtoPreviewExcel.Create(Self);
  try
    fPreview.PopupParent := Self;
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName :=
      Format(SNombreArchivoSesionCompra,
        [edtSerie.Text, edtNumero.Text]);
    try
      ExportarDocCompraHorizontal(ConexionPrincipal,fPreview.dxSpreadSheet1,
        dmSesion.unqryCabSesionPrint,
        dmSesion.unqryLinSesionPrint,
        dmSesion.unqryGuiasSesionPrint,
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

procedure TfrmPrintSesion.FormCreate(Sender: TObject);
begin
  inherited;
  // El diseño FastReport vive embebido en frxrprt1 (.dfm). Lo
  // duplicamos en frxReportOrigen para que la opcion "Predeterminado"
  // de Consultar_Formularios (frxrprt1.AssignAll(frxReportOrigen))
  // restaure el diseño original en vez de vaciar el report.
  frxReportOrigen.AssignAll(frxrprt1);
end;

procedure TfrmPrintSesion.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintSesion.preparar_consulta;
begin
  if dmSesion <> nil then
    dmSesion.PrepararPrint(edtSerie.Text, edtNumero.Text);
end;

procedure TfrmPrintSesion.AfterReportLoaded;
begin
  inherited;
  if dmSesion <> nil then
    RebindReportDataSetsByDataModule(frxrprt1, dmSesion);
end;

end.
