{******************************************************************************}
{                                                                              }
{  Módulo:       inLibHojaCalculoUtil                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Helpers puros de hoja de cálculo, sin dependencia de DevExpress. Se       }
{    reutilizan desde los adaptadores y los exportadores. Portados de          }
{    inLibDevExcel (GetRef, ColToLetras, SepFormula).                          }
{    Fase 0 del refactor (ver desacoplar_excel_hojacalculo.md).                }
{******************************************************************************}
unit inLibHojaCalculoUtil;

interface

// Convierte un índice de columna (base 0) a letras estilo Excel (0 -> 'A').
function ColumnaALetras(ACol: Integer): string;
// Referencia A1 de una celda (base 0). AAbsoluta antepone '$'.
function ReferenciaCelda(AFila, ACol: Integer;
                         AAbsoluta: Boolean = False): string;
// Separador de argumentos de fórmula según el locale (coma decimal -> ';').
function SeparadorFormula: string;

implementation

uses
  System.SysUtils;

function ColumnaALetras(ACol: Integer): string;
begin
  Result := '';
  repeat
    Result := Chr(Ord('A') + (ACol mod 26)) + Result;
    ACol := ACol div 26 - 1;
  until ACol < 0;
end;

function ReferenciaCelda(AFila, ACol: Integer;
                         AAbsoluta: Boolean = False): string;
var
  sColumna: string;
begin
  sColumna := ColumnaALetras(ACol);
  if AAbsoluta then
    Result := '$' + sColumna + '$' + IntToStr(AFila + 1)
  else
    Result := sColumna + IntToStr(AFila + 1);
end;

function SeparadorFormula: string;
begin
  // Con coma decimal (España) el separador de argumentos es ';'. Emitir ','
  // haría que dxSpreadSheet interprete SUM(A1,A2) como el rango SUM(A1:A2).
  if FormatSettings.DecimalSeparator = ',' then
    Result := ';'
  else
    Result := ',';
end;

end.
