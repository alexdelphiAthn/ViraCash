{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInformeDocumentosProveedorTotales                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Total general del "Listado de documentos proveedor" (FZ-ISSUE-247). La    }
{    misma compra aparece como pedido, albarán y factura, así que el resumen   }
{    final solo suma las filas con COMPRA_NETA_DOC = 1: facturas y albaranes   }
{    y devoluciones sin facturar. Los subtotales por tipo no cambian. Se       }
{    aplica al cargar el informe, también a los formatos personalizados.       }
{******************************************************************************}
unit inLibInformeDocumentosProveedorTotales;

interface

uses
  frxClass;

const
  CAMPO_COMPRA_NETA_DOC = 'COMPRA_NETA_DOC';

// Reescribe las sumas de la banda de resumen del informe para que solo
// cuenten las compras netas y pone ATitulo en lugar de 'TOTAL GENERAL'.
// Idempotente.
procedure AjustarTotalGeneralDocumentosProveedor(AInforme: TfrxReport;
  const ADataSet, ATitulo: string);

implementation

uses
  System.SysUtils, System.RegularExpressions;

const
  TITULO_ORIGINAL = 'TOTAL GENERAL';

function SumaComprasNetas(const ATexto, ADataSet: string): string;
begin
  Result := ATexto;
  if Pos(CAMPO_COMPRA_NETA_DOC, Result) = 0 then
    Result := TRegEx.Replace(Result,
      'SUM\(<' + TRegEx.Escape(ADataSet) + '\."(\w+)">',
      'SUM(IIF(<' + ADataSet + '."' + CAMPO_COMPRA_NETA_DOC +
      '"> = 1, <' + ADataSet + '."$1">, 0)', [roIgnoreCase]);
end;

procedure AjustarTotalGeneralDocumentosProveedor(AInforme: TfrxReport;
  const ADataSet, ATitulo: string);
var
  i: Integer;
  oMemo: TfrxCustomMemoView;
begin
  if AInforme = nil then
    Exit;
  for i := 0 to AInforme.AllObjects.Count - 1 do
    if (TObject(AInforme.AllObjects[i]) is TfrxCustomMemoView) and
       (TfrxCustomMemoView(AInforme.AllObjects[i]).Parent is
        TfrxReportSummary) then
    begin
      oMemo := TfrxCustomMemoView(AInforme.AllObjects[i]);
      if SameText(Trim(oMemo.Text), TITULO_ORIGINAL) then
        oMemo.Text := ATitulo
      else
        oMemo.Text := SumaComprasNetas(oMemo.Text, ADataSet);
    end;
end;

end.
