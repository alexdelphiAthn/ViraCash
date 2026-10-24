{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalImpSimulacionValoracion                             }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Impresión del listado de una simulación de valoración (inventarios y     }
{    traspasos): líneas con precio de última compra, PMP y precio simulado.   }
{    El botón Excel genera la hoja nativa DevExpress con vista previa.         }
{******************************************************************************}
unit inMtoModalImpSimulacionValoracion;

interface

uses
  inLibMsgArticulos,
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
  inLibInformeSimulacionValoracion, inMtoPreviewExcel;

type
  TfrmPrintSimulacionValoracion = class(TfrmPrint)
    lblDescripcion: TcxLabel;
    dsCabecera: TDataSource;
    dsLineas: TDataSource;
    fxdsCabecera: TfrxDBDataset;
    fxdsLineas: TfrxDBDataset;
    cdsCabecera: TClientDataSet;
    cdsLineas: TClientDataSet;
  private
    FDatos: TDatosInformeSimulacionValoracion;
    procedure CargarCabecera;
    procedure CargarLineas;
    procedure ExportarExcelNativo(Sender: TObject);
    procedure MostrarPreviewExcel(APreview: TfrmMtoPreviewExcel);
  public
    class procedure Mostrar(
      AOwner: TComponent;
      const ADatos: TDatosInformeSimulacionValoracion); static;
    procedure preparar_consulta; override;
  end;

implementation

{$R *.dfm}

uses
  inLibHojaCalculoIntf,
  inLibHojaCalculoDevEx,
  inLibInformeSimulacionValoracionExcel,
  inLibMsgComun;


const
  CAMPO_TITULO = 'TITULO';
  CAMPO_IDENTIFICACION = 'IDENTIFICACION';
  CAMPO_OPERACION = 'OPERACION';
  CAMPO_FECHA = 'FECHA';
  CAMPO_NUMERO_LINEAS = 'NUMERO_LINEAS';
  CAMPO_VALOR_ANTERIOR = 'VALOR_ANTERIOR';
  CAMPO_VALOR_SIMULADO = 'VALOR_SIMULADO';
  CAMPO_DIFERENCIA = 'DIFERENCIA';
  CAMPO_CAP_FECHA = 'CAP_FECHA';
  CAMPO_CAP_LINEA = 'CAP_LINEA';
  CAMPO_CAP_ARTICULO = 'CAP_ARTICULO';
  CAMPO_CAP_SKU = 'CAP_SKU';
  CAMPO_CAP_DESCRIPCION = 'CAP_DESCRIPCION';
  CAMPO_CAP_UNIDADES = 'CAP_UNIDADES';
  CAMPO_CAP_ULTIMA_COMPRA = 'CAP_ULTIMA_COMPRA';
  CAMPO_CAP_PRECIO_MEDIO = 'CAP_PRECIO_MEDIO';
  CAMPO_CAP_PRECIO_SIMULADO = 'CAP_PRECIO_SIMULADO';
  CAMPO_CAP_LINEAS_SIMULADAS = 'CAP_LINEAS_SIMULADAS';
  CAMPO_CAP_VALOR_ANTERIOR = 'CAP_VALOR_ANTERIOR';
  CAMPO_CAP_VALOR_SIMULADO = 'CAP_VALOR_SIMULADO';
  CAMPO_CAP_DIFERENCIA = 'CAP_DIFERENCIA';
  CAMPO_LINEA = 'LINEA';
  CAMPO_ARTICULO = 'ARTICULO';
  CAMPO_SKU = 'SKU';
  CAMPO_DESCRIPCION = 'DESCRIPCION';
  CAMPO_UNIDADES = 'UNIDADES';
  CAMPO_PRECIO_ULTIMA_COMPRA = 'PRECIO_ULTIMA_COMPRA';
  CAMPO_PRECIO_MEDIO = 'PRECIO_MEDIO';
  CAMPO_PRECIO_SIMULADO = 'PRECIO_SIMULADO';
  CAMPO_SIMULADA = 'SIMULADA';

class procedure TfrmPrintSimulacionValoracion.Mostrar(
  AOwner: TComponent;
  const ADatos: TDatosInformeSimulacionValoracion);
var
  oFormulario: TfrmPrintSimulacionValoracion;
begin
  oFormulario := TfrmPrintSimulacionValoracion.Create(AOwner);
  try
    oFormulario.FDatos := ADatos;
    // El Excel se genera con la hoja nativa en vez de exportar el informe.
    oFormulario.btnExcel.OnClick := oFormulario.ExportarExcelNativo;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmPrintSimulacionValoracion.CargarCabecera;
begin
  cdsCabecera.Close;
  cdsCabecera.FieldDefs.Clear;
  cdsCabecera.FieldDefs.Add(CAMPO_TITULO, ftWideString, 200);
  cdsCabecera.FieldDefs.Add(CAMPO_IDENTIFICACION, ftWideString, 250);
  cdsCabecera.FieldDefs.Add(CAMPO_OPERACION, ftWideString, 200);
  cdsCabecera.FieldDefs.Add(CAMPO_FECHA, ftDateTime);
  cdsCabecera.FieldDefs.Add(CAMPO_NUMERO_LINEAS, ftInteger);
  cdsCabecera.FieldDefs.Add(CAMPO_VALOR_ANTERIOR, ftCurrency);
  cdsCabecera.FieldDefs.Add(CAMPO_VALOR_SIMULADO, ftCurrency);
  cdsCabecera.FieldDefs.Add(CAMPO_DIFERENCIA, ftCurrency);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_FECHA, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_LINEA, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_ARTICULO, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_SKU, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_DESCRIPCION, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_UNIDADES, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_ULTIMA_COMPRA, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_PRECIO_MEDIO, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_PRECIO_SIMULADO, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_LINEAS_SIMULADAS, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_VALOR_ANTERIOR, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_VALOR_SIMULADO, ftWideString, 50);
  cdsCabecera.FieldDefs.Add(CAMPO_CAP_DIFERENCIA, ftWideString, 50);
  cdsCabecera.CreateDataSet;
  cdsCabecera.Append;
  cdsCabecera.FieldByName(CAMPO_TITULO).AsString := FDatos.Titulo;
  cdsCabecera.FieldByName(CAMPO_IDENTIFICACION).AsString :=
    FDatos.Identificacion;
  cdsCabecera.FieldByName(CAMPO_OPERACION).AsString := FDatos.Operacion;
  cdsCabecera.FieldByName(CAMPO_FECHA).AsDateTime := FDatos.Fecha;
  cdsCabecera.FieldByName(CAMPO_NUMERO_LINEAS).AsInteger :=
    FDatos.NumeroLineasSimuladas;
  cdsCabecera.FieldByName(CAMPO_VALOR_ANTERIOR).AsCurrency :=
    FDatos.ValorAnterior;
  cdsCabecera.FieldByName(CAMPO_VALOR_SIMULADO).AsCurrency :=
    FDatos.ValorSimulado;
  cdsCabecera.FieldByName(CAMPO_DIFERENCIA).AsCurrency :=
    FDatos.DiferenciaValor;
  cdsCabecera.FieldByName(CAMPO_CAP_FECHA).AsString :=
    SCaptionFechaInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_LINEA).AsString :=
    SCaptionColLineaInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_ARTICULO).AsString :=
    SCaptionColArticuloInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_SKU).AsString :=
    SCaptionColSkuInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_DESCRIPCION).AsString :=
    SCaptionColDescripcionInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_UNIDADES).AsString :=
    SCaptionColUnidadesInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_ULTIMA_COMPRA).AsString :=
    SCaptionColUltimaCompraInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_PRECIO_MEDIO).AsString :=
    FDatos.CaptionPrecioMedio;
  cdsCabecera.FieldByName(CAMPO_CAP_PRECIO_SIMULADO).AsString :=
    SCaptionColPrecioSimuladoInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_LINEAS_SIMULADAS).AsString :=
    SCaptionLineasSimuladasInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_VALOR_ANTERIOR).AsString :=
    SCaptionValorAnteriorInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_VALOR_SIMULADO).AsString :=
    SCaptionValorSimuladoInformeValoracion;
  cdsCabecera.FieldByName(CAMPO_CAP_DIFERENCIA).AsString :=
    SCaptionDiferenciaInformeValoracion;
  cdsCabecera.Post;
  cdsCabecera.First;
end;

procedure TfrmPrintSimulacionValoracion.CargarLineas;
var
  iLinea: Integer;
begin
  cdsLineas.Close;
  cdsLineas.FieldDefs.Clear;
  cdsLineas.FieldDefs.Add(CAMPO_LINEA, ftWideString, 30);
  cdsLineas.FieldDefs.Add(CAMPO_ARTICULO, ftWideString, 50);
  cdsLineas.FieldDefs.Add(CAMPO_SKU, ftWideString, 100);
  cdsLineas.FieldDefs.Add(CAMPO_DESCRIPCION, ftWideString, 250);
  cdsLineas.FieldDefs.Add(CAMPO_UNIDADES, ftCurrency);
  cdsLineas.FieldDefs.Add(CAMPO_PRECIO_ULTIMA_COMPRA, ftCurrency);
  cdsLineas.FieldDefs.Add(CAMPO_PRECIO_MEDIO, ftCurrency);
  cdsLineas.FieldDefs.Add(CAMPO_PRECIO_SIMULADO, ftCurrency);
  cdsLineas.FieldDefs.Add(CAMPO_SIMULADA, ftWideString, 2);
  cdsLineas.CreateDataSet;
  cdsLineas.DisableControls;
  try
    for iLinea := 0 to High(FDatos.Lineas) do
    begin
      cdsLineas.Append;
      cdsLineas.FieldByName(CAMPO_LINEA).AsString :=
        FDatos.Lineas[iLinea].Linea;
      cdsLineas.FieldByName(CAMPO_ARTICULO).AsString :=
        FDatos.Lineas[iLinea].CodigoArticulo;
      cdsLineas.FieldByName(CAMPO_SKU).AsString :=
        FDatos.Lineas[iLinea].CodigoUnidad;
      cdsLineas.FieldByName(CAMPO_DESCRIPCION).AsString :=
        FDatos.Lineas[iLinea].Descripcion;
      cdsLineas.FieldByName(CAMPO_UNIDADES).AsCurrency :=
        FDatos.Lineas[iLinea].Unidades;
      cdsLineas.FieldByName(CAMPO_PRECIO_ULTIMA_COMPRA).AsCurrency :=
        FDatos.Lineas[iLinea].PrecioUltimaCompra;
      cdsLineas.FieldByName(CAMPO_PRECIO_MEDIO).AsCurrency :=
        FDatos.Lineas[iLinea].PrecioMedio;
      if FDatos.Lineas[iLinea].Simulada then
      begin
        cdsLineas.FieldByName(CAMPO_PRECIO_SIMULADO).AsCurrency :=
          FDatos.Lineas[iLinea].PrecioSimulado;
        cdsLineas.FieldByName(CAMPO_SIMULADA).AsString :=
          STextoSiInformeValoracion;
      end;
      cdsLineas.Post;
    end;
    cdsLineas.First;
  finally
    cdsLineas.EnableControls;
  end;
end;

procedure TfrmPrintSimulacionValoracion.preparar_consulta;
begin
  CargarCabecera;
  CargarLineas;
  dsCabecera.DataSet := cdsCabecera;
  dsLineas.DataSet := cdsLineas;
  fxdsCabecera.UpdateBounds;
  fxdsLineas.UpdateBounds;
  frxpdfxprtPedWeb.FileName := SNombreArchivoSimulacionValoracion;
end;

procedure TfrmPrintSimulacionValoracion.MostrarPreviewExcel(
  APreview: TfrmMtoPreviewExcel);
begin
  APreview.ShowModal;
end;

procedure TfrmPrintSimulacionValoracion.ExportarExcelNativo(
  Sender: TObject);
var
  crCursorAnterior: TCursor;
  fPreview: TfrmMtoPreviewExcel;
  oServicios: TServiciosHojaCalculo;
begin
  // Hoja nativa DevExpress con el mismo listado que el informe; el visor
  // permite revisarla y guardarla como .xlsx.
  crCursorAnterior := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  fPreview := nil;
  try
    IniciarEspera(SCaptionEsperaGenerandoHojaCalculo);
    fPreview := TfrmMtoPreviewExcel.Create(Self);
    fPreview.DialogoGuardar.InitialDir :=
      ParametrosApp.GetPath('appDirExcel');
    fPreview.DialogoGuardar.FileName :=
      SNombreArchivoSimulacionValoracion;
    oServicios := CrearServiciosHojaCalculoDevEx(fPreview.dxSpreadSheet1);
    ExportarInformeSimulacionValoracionExcel(
      oServicios.Escritor,
      oServicios.Formateador,
      FDatos);
    TerminarEspera;
    MostrarPreviewExcel(fPreview);
  finally
    TerminarEspera;
    FreeAndNil(fPreview);
    Screen.Cursor := crCursorAnterior;
  end;
end;

end.
