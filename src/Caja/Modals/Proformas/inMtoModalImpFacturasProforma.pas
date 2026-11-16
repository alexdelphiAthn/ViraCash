{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpFacturasProforma                                }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Impresión de proformas internas de ventas de caja.                        }
{    El documento es no fiscal y agrupa los artículos por operación origen.   }
{******************************************************************************}
unit inMtoModalImpFacturasProforma;

interface

uses
  dxSpreadSheet,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Menus, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Data.DB,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxButtons, cxControls, cxContainer, cxEdit, cxLabel, cxStyles,
  cxClasses, cxLocalization, dxCore, dxSkinsForm, JvComponentBase,
  JvEnterTab, System.Actions, Vcl.ActnList, frxClass, frxDBSet, frxDesgn,
  frxExportXLSX, frxExportBaseDialog, frxExportPDF, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses, UniDataInformeFacturasProforma;

type
  TfrmPrintFacturasProforma = class(TfrmPrint)
    lblDocumentoNoFiscal: TcxLabel;
    dsProforma: TDataSource;
    dsLineasProforma: TDataSource;
    fxdsProforma: TfrxDBDataset;
    fxdsLineasProforma: TfrxDBDataset;
  private
    FDataModule: TdmInformeFacturasProforma;
    FIdProforma: Int64;
    procedure ConfigurarNombrePdf;
  protected
    procedure DoShow; override;
    procedure ConstruirExcelNativo(AControl: TdxSpreadSheet); override;
    procedure PrepararDatosEdicion; override;
    function TraducirContenidoInforme: Boolean; override;
  public
    class procedure Mostrar(
      AOwner: TComponent;
      AIdProforma: Int64); static;
    procedure preparar_consulta; override;
    property IdProforma: Int64 read FIdProforma write FIdProforma;
  end;

implementation

uses
  inLibMsgCaja,
  inLibInformeTabular, inLibInformeTabularExcel;

{$R *.dfm}

resourcestring
  SIdProformaNoValido =
    'No se ha indicado una proforma interna válida para imprimir.';
  SFormatoNombreArchivoProforma =
    'Proforma_%s_%s_%s';

function SanearNombreArchivo(const AOriginal: string): string;
var
  cCaracter: Char;
  iCaracter: Integer;
begin
  Result := '';
  for iCaracter := 1 to Length(AOriginal) do
  begin
    cCaracter := AOriginal[iCaracter];
    case cCaracter of
      #0..#31, '/', '\', ':', '*', '?', '"', '<', '>', '|':
        Result := Result + '_';
    else
      Result := Result + cCaracter;
    end;
  end;
end;

procedure TfrmPrintFacturasProforma.ConfigurarNombrePdf;
var
  sEmpresa: string;
  sNumero: string;
  sSerie: string;
begin
  if not FDataModule.unqryProforma.IsEmpty then
  begin
    sEmpresa := FDataModule.unqryProforma.FieldByName(
      'CODIGO_EMP_PROCAJ').AsString;
    sSerie := FDataModule.unqryProforma.FieldByName(
      'SERIE_PROCAJ').AsString;
    sNumero := FDataModule.unqryProforma.FieldByName(
      'NUMERO_PROCAJ').AsString;
    frxpdfxprtPedWeb.FileName :=
      SanearNombreArchivo(
        Format(SFormatoNombreArchivoProforma,
          [sEmpresa, sSerie, sNumero]));
  end;
end;

class procedure TfrmPrintFacturasProforma.Mostrar(
  AOwner: TComponent;
  AIdProforma: Int64);
var
  oFormulario: TfrmPrintFacturasProforma;
begin
  if AIdProforma <= 0 then
    raise EArgumentOutOfRangeException.Create(SIdProformaNoValido);
  oFormulario := TfrmPrintFacturasProforma.Create(AOwner);
  try
    oFormulario.IdProforma := AIdProforma;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmPrintFacturasProforma.PrepararDatosEdicion;
begin
  preparar_consulta;
end;

procedure TfrmPrintFacturasProforma.preparar_consulta;
begin
  if FIdProforma <= 0 then
    raise EArgumentOutOfRangeException.Create(SIdProformaNoValido);
  if FDataModule = nil then
    FDataModule := TdmInformeFacturasProforma.Create(Self);
  FDataModule.Cargar(FIdProforma);
  dsProforma.DataSet := FDataModule.unqryProforma;
  dsLineasProforma.DataSet := FDataModule.unqryLineas;
  fxdsProforma.UpdateBounds;
  fxdsLineasProforma.UpdateBounds;
  ConfigurarNombrePdf;
end;

function TfrmPrintFacturasProforma.TraducirContenidoInforme: Boolean;
begin
  // La advertencia de documento no fiscal debe conservar su texto legal.
  Result := False;
end;

procedure TfrmPrintFacturasProforma.DoShow;
begin
  inherited;
  btnExcel.OnClick := btnExcelNativoClick;
end;

procedure TfrmPrintFacturasProforma.ConstruirExcelNativo(
  AControl: TdxSpreadSheet);
begin
  ExportarInformeTabularExcel(AControl, dsLineasProforma.DataSet,
    Caption,
    [ColumnaInforme('DESCRIPCION_VINCULO_PROCLIN', STextoVinculoCaja, 2),
     ColumnaInforme('NUMERO_OPERACION_PROCLIN', STextoOperacionCaja, 1),
     ColumnaInforme('FECHA_OPERACION_PROCLIN', STextoFechaCaja, 1),
     ColumnaInforme('CODIGO_ART_PROCLIN', STextoArticuloCaja, 1),
     ColumnaInforme('CODIGO_UNIDAD_PROCLIN', STextoSkuCaja, 1),
     ColumnaInforme('DESCRIPCION_ARTICULO_PROCLIN', STextoDescripcionCaja, 3),
     ColumnaInforme('CANTIDAD_PROCLIN', STextoCantidadCaja, 1, '%g'),
     ColumnaInforme('PRECIO_SIVA_PROCLIN', STextoPrecioSinIvaCaja, 1, '%n'),
     ColumnaInforme('PORCENTAJE_IVA_PROCLIN', STextoIvaCaja, 1, '%n'),
     ColumnaInforme('TOTAL_PROCLIN', STextoTotalCaja, 1, '%n')],
    LineasResumenSelecciones);
  AnadirHojaInformeTabularExcel(AControl, dsProforma.DataSet,
    'Cabecera',
    [ColumnaInforme('SERIE_PROCAJ', STextoSerieCaja, 1),
     ColumnaInforme('NUMERO_PROCAJ', STextoNumeroCaja, 1),
     ColumnaInforme('RAZON_SOCIAL_EMPRESA_PROCAJ', STextoEmpresaCaja, 3),
     ColumnaInforme('NIF_EMPRESA_PROCAJ', STextoNifEmpresaCaja, 1),
     ColumnaInforme('RAZON_SOCIAL_CLIENTE_PROCAJ', STextoClienteCaja, 3),
     ColumnaInforme('TOTAL_BASE_PROCAJ', STextoBaseImponibleCaja, 1, '%n'),
     ColumnaInforme('TOTAL_IMPUESTOS_PROCAJ', STextoImpuestosCaja, 1, '%n'),
     ColumnaInforme('TOTAL_PROCAJ', STextoTotalCaja, 1, '%n')]);
end;

end.
