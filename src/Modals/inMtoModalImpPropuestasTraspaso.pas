{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpPropuestasTraspaso                               }
{    Tipo:       Formulario (Print)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Impresión de las propuestas de traspaso de una distribución entre         }
{    tiendas, a modo de repaso: una hoja por origen-destino y una línea por    }
{    artículo y color con sus tallas.                                          }
{******************************************************************************}
unit inMtoModalImpPropuestasTraspaso;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Variants, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Menus, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Data.DB,
  Datasnap.DBClient,
  inMtoModalGenImp, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters,
  cxButtons, cxControls, cxContainer, cxEdit, cxLabel, cxStyles,
  cxClasses, cxLocalization, dxCore, dxSkinsForm, JvComponentBase,
  JvEnterTab, System.Actions, Vcl.ActnList, frxClass, frxDBSet, frxDesgn,
  frxExportXLSX, frxExportBaseDialog, frxExportPDF, frxSmartMemo,
  frLocalization, frLanguageSpanish, frxExportBaseImageSettingsDialog,
  frCoreClasses,
  inLibInformePropuestasTraspaso;

type
  TfrmPrintPropuestasTraspaso = class(TfrmPrint)
    lblDescripcion: TcxLabel;
    dsCabecera: TDataSource;
    dsLineas: TDataSource;
    fxdsCabecera: TfrxDBDataset;
    fxdsLineas: TfrxDBDataset;
    cdsCabecera: TClientDataSet;
    cdsLineas: TClientDataSet;
  private
    FHojas: THojasInformePropuestasTraspaso;
    FIdDocumento: Int64;
    procedure CargarCabecera;
    procedure DefinirLineas;
    procedure CargarLineas;
    procedure AgregarLinea(
      const AHoja: THojaInformePropuestaTraspaso;
      const ALinea: TLineaInformePropuestaTraspaso);
  protected
    procedure DoCreate; override;
  public
    class procedure Mostrar(
      AOwner: TComponent;
      const AHojas: THojasInformePropuestasTraspaso;
      AIdDocumento: Int64); static;
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMsgDistribucionTiendas;

const
  CAMPO_TITULO = 'TITULO';
  CAMPO_CAP_ARTICULO = 'CAP_ARTICULO';
  CAMPO_CAP_DESCRIPCION = 'CAP_DESCRIPCION';
  CAMPO_CAP_COLOR = 'CAP_COLOR';
  CAMPO_CAP_TALLAS = 'CAP_TALLAS';
  CAMPO_CAP_UNIDADES = 'CAP_UNIDADES';
  CAMPO_CAP_TOTAL = 'CAP_TOTAL';
  CAMPO_ID_PROPUESTA = 'ID_PROPUESTA';
  CAMPO_NUMERO = 'NUMERO';
  CAMPO_ORIGEN = 'ORIGEN';
  CAMPO_DESTINO = 'DESTINO';
  CAMPO_DOCUMENTO = 'DOCUMENTO';
  CAMPO_ESTADO = 'ESTADO';
  CAMPO_FECHA = 'FECHA';
  CAMPO_ARTICULO = 'ARTICULO';
  CAMPO_DESCRIPCION = 'DESCRIPCION';
  CAMPO_COLOR = 'COLOR';
  CAMPO_TALLAS = 'TALLAS';
  CAMPO_UNIDADES = 'UNIDADES';

class procedure TfrmPrintPropuestasTraspaso.Mostrar(
  AOwner: TComponent;
  const AHojas: THojasInformePropuestasTraspaso;
  AIdDocumento: Int64);
var
  oFormulario: TfrmPrintPropuestasTraspaso;
begin
  oFormulario := TfrmPrintPropuestasTraspaso.Create(AOwner);
  try
    oFormulario.FHojas := AHojas;
    oFormulario.FIdDocumento := AIdDocumento;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

// El título se fija tras la traducción del formulario base, que si no lo
// deja con el de su ancestro.
procedure TfrmPrintPropuestasTraspaso.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloImprimirPropuestasTraspaso;
  lblDescripcion.Caption := STextoImprimirPropuestasTraspaso;
end;

procedure TfrmPrintPropuestasTraspaso.CargarCabecera;
begin
  cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.FieldDefs.Add(CAMPO_TITULO, ftWideString, 200);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_ARTICULO, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_DESCRIPCION, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_COLOR, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_TALLAS, ftWideString, 80);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_UNIDADES, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_TOTAL, ftWideString, 50);
  cdsCabecera.CreateDataSet;
  cdsCabecera.Append;
  cdsCabecera.FieldByName(CAMPO_TITULO).AsString :=
    STituloInformePropuestaTraspaso;
  cdsCabecera.FieldByName(CAMPO_CAP_ARTICULO).AsString :=
    SCaptionColArticuloDistribucion;
  cdsCabecera.FieldByName(CAMPO_CAP_DESCRIPCION).AsString :=
    SCaptionColDescripcionDistribucion;
  cdsCabecera.FieldByName(CAMPO_CAP_COLOR).AsString :=
    SCaptionColColorDistribucion;
  cdsCabecera.FieldByName(CAMPO_CAP_TALLAS).AsString :=
    SCaptionColTallasInformePropuesta;
  cdsCabecera.FieldByName(CAMPO_CAP_UNIDADES).AsString :=
    SCaptionColUnidadesDistribucion;
  cdsCabecera.FieldByName(CAMPO_CAP_TOTAL).AsString :=
    SCaptionTotalInformePropuesta;
  cdsCabecera.Post;
  cdsCabecera.First;
end;

procedure TfrmPrintPropuestasTraspaso.DefinirLineas;
begin
  cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.FieldDefs.Add(CAMPO_ID_PROPUESTA, ftLargeint);
  cdsLineas.FieldDefs.Add(CAMPO_NUMERO, ftWideString, 80);
  cdsLineas.FieldDefs.Add(CAMPO_ORIGEN, ftWideString, 200);
  cdsLineas.FieldDefs.Add(CAMPO_DESTINO, ftWideString, 200);
  cdsLineas.FieldDefs.Add(CAMPO_DOCUMENTO, ftWideString, 300);
  cdsLineas.FieldDefs.Add(CAMPO_ESTADO, ftWideString, 120);
  cdsLineas.FieldDefs.Add(CAMPO_FECHA, ftDateTime);
  cdsLineas.FieldDefs.Add(CAMPO_ARTICULO, ftWideString, 50);
  cdsLineas.FieldDefs.Add(CAMPO_DESCRIPCION, ftWideString, 250);
  cdsLineas.FieldDefs.Add(CAMPO_COLOR, ftWideString, 100);
  cdsLineas.FieldDefs.Add(CAMPO_TALLAS, ftWideString, 1000);
  cdsLineas.FieldDefs.Add(CAMPO_UNIDADES, ftFloat);
  cdsLineas.CreateDataSet;
end;

// La hoja viaja repetida en cada línea: el informe corta por propuesta.
procedure TfrmPrintPropuestasTraspaso.AgregarLinea(
  const AHoja: THojaInformePropuestaTraspaso;
  const ALinea: TLineaInformePropuestaTraspaso);
begin
  cdsLineas.Append;
  cdsLineas.FieldByName(CAMPO_ID_PROPUESTA).AsLargeInt :=
    AHoja.IdPropuesta;
  cdsLineas.FieldByName(CAMPO_NUMERO).AsString := AHoja.Numero;
  cdsLineas.FieldByName(CAMPO_ORIGEN).AsString := AHoja.Origen;
  cdsLineas.FieldByName(CAMPO_DESTINO).AsString := AHoja.Destino;
  cdsLineas.FieldByName(CAMPO_DOCUMENTO).AsString := AHoja.Documento;
  cdsLineas.FieldByName(CAMPO_ESTADO).AsString := AHoja.Estado;
  cdsLineas.FieldByName(CAMPO_FECHA).AsDateTime := AHoja.Instante;
  cdsLineas.FieldByName(CAMPO_ARTICULO).AsString := ALinea.CodigoArticulo;
  cdsLineas.FieldByName(CAMPO_DESCRIPCION).AsString :=
    ALinea.DescripcionArticulo;
  cdsLineas.FieldByName(CAMPO_COLOR).AsString := ALinea.Color;
  cdsLineas.FieldByName(CAMPO_TALLAS).AsString := ALinea.Tallas;
  cdsLineas.FieldByName(CAMPO_UNIDADES).AsFloat := ALinea.Unidades;
  cdsLineas.Post;
end;

procedure TfrmPrintPropuestasTraspaso.CargarLineas;
var
  iHoja, iLinea: Integer;
begin
  DefinirLineas;
  cdsLineas.DisableControls;
  try
    for iHoja := 0 to High(FHojas) do
    begin
      for iLinea := 0 to High(FHojas[iHoja].Lineas) do
        AgregarLinea(FHojas[iHoja], FHojas[iHoja].Lineas[iLinea]);
    end;
    cdsLineas.First;
  finally
    cdsLineas.EnableControls;
  end;
end;

procedure TfrmPrintPropuestasTraspaso.preparar_consulta;
begin
  CargarCabecera;
  CargarLineas;
  dsCabecera.DataSet := cdsCabecera;
  dsLineas.DataSet := cdsLineas;
  fxdsCabecera.UpdateBounds;
  fxdsLineas.UpdateBounds;
  frxpdfxprtPedWeb.FileName := Format(
    SNombreArchivoPropuestasTraspaso, [FIdDocumento]);
end;

end.
