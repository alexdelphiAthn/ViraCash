{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevExcel                                                 }
{    Tipo:       Librería (transitoria - Fase 1)                               }
{ Versión:       2.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Shims transitorios. La lógica real vive ahora en inLibHojaCalculoDevEx    }
{    (métodos de clase) e inLibHojaCalculoUtil (helpers puros). Estas rutinas  }
{    sólo delegan para no romper los exportadores aún no migrados. Se          }
{    eliminarán en la Fase 4, cuando todos usen IEscritorHojaCalculo.          }
{    Ver desacoplar_excel_hojacalculo.md.                                      }
{******************************************************************************}
unit inLibDevExcel;

interface

uses
  System.Variants,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles;

  procedure Merge(Sheet: TdxSpreadSheetTableView;
                  ARow, ACol, ColCount, RowCount: Integer);
  procedure W(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
              const AValue: Variant;
              ABold: Boolean = False;
              AAlign: TdxSpreadSheetDataAlignHorz = ssahLeft);
  procedure WFormula(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
                     const AFormula: string;
                     AFormat: string = '');
  procedure PintarCuadro(Sheet: TdxSpreadSheetTableView;
                         R1, C1, R2, C2: Integer;
                         DxStyle: TdxSpreadSheetCellBorderStyle);
  function GetRef(R, C: Integer; Absolute: Boolean = False): string;
  function ColToLetras(C: Integer): string;
  function SepFormula: string;

implementation

uses
  inLibHojaCalculoDevEx, inLibHojaCalculoUtil;

// Unidad transitoria (Fase 1): migrar a IEscritorHojaCalculo.

  procedure Merge(Sheet: TdxSpreadSheetTableView;
                  ARow, ACol, ColCount, RowCount: Integer);
  begin
    TEscritorHojaCalculoDevEx.MezclarDx(Sheet, ARow, ACol, ColCount,
      RowCount);
  end;

  procedure W(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
              const AValue: Variant;
              ABold: Boolean = False;
              AAlign: TdxSpreadSheetDataAlignHorz = ssahLeft);
  begin
    TEscritorHojaCalculoDevEx.EscribirCeldaDx(Sheet, ARow, ACol, AValue,
      ABold, AAlign);
  end;

  procedure WFormula(Sheet: TdxSpreadSheetTableView;ARow, ACol: Integer;
                     const AFormula: string;
                     AFormat: string = '');
  begin
    TEscritorHojaCalculoDevEx.EscribirFormulaDx(Sheet, ARow, ACol, AFormula,
      AFormat);
  end;

  procedure PintarCuadro(Sheet: TdxSpreadSheetTableView;
                         R1, C1, R2, C2: Integer;
                         DxStyle: TdxSpreadSheetCellBorderStyle);
  begin
    TEscritorHojaCalculoDevEx.PintarCuadroDx(Sheet, R1, C1, R2, C2, DxStyle);
  end;

  function GetRef(R, C: Integer; Absolute: Boolean = False): string;
  begin
    Result := ReferenciaCelda(R, C, Absolute);
  end;

  function ColToLetras(C: Integer): string;
  begin
    Result := ColumnaALetras(C);
  end;

  function SepFormula: string;
  begin
    Result := SeparadorFormula;
  end;

end.
