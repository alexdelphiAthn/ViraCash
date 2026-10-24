{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceTallasExcel                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.4.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada de exportación Excel para el balance de almacén por tallas.       }
{******************************************************************************}
unit inLibBalanceTallasExcel;

interface

uses
  Data.DB, dxSpreadSheet, inLibFotos, inLibBalanceExcelComun,
  inLibUnidadesMedida, inLibBalanceCantidades;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos); overload;
// Con aviso de avance (fila procesada y total) para la ventana de espera
// y, opcional, el resumen de selecciones debajo del título.
procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos;
  const AProgreso: TProgresoBalanceExcel;
  const AResumen: TArray<string> = nil;
  const ADecimalesArticulo: TDecimalesArticulo = nil;
  const AUnidadArticulo: TUnidadArticuloBalance = nil); overload;

implementation

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos);
begin
  ExportarBalanceExcel(ASheetControl, QDatos, AFotos, tbeConTallas);
end;

procedure ExportarBalanceTallasExcel(ASheetControl: TdxSpreadSheet;
  const QDatos: TDataSet; AFotos: TFotosArticulos;
  const AProgreso: TProgresoBalanceExcel;
  const AResumen: TArray<string>;
  const ADecimalesArticulo: TDecimalesArticulo;
  const AUnidadArticulo: TUnidadArticuloBalance);
begin
  ExportarBalanceExcel(ASheetControl, QDatos, AFotos, tbeConTallas,
    AProgreso, AResumen, ADecimalesArticulo, AUnidadArticulo);
end;

end.
