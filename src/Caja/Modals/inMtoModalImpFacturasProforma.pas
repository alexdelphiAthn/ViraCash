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

end.
