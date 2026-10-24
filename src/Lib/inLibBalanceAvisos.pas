{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceAvisos                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Bandas de aviso de los balances de almacén (con y sin tallas,            }
{    FZ-ISSUE-091): AVIFAC (uds. facturadas distintas de las vendidas) y      }
{    SINMOV (stock que no sale de ningún movimiento). Las devuelven los SP    }
{    PRC_GET_BALANCE_ALMACEN_*; aquí se reconocen y se resaltan en rojo en el }
{    informe FastReport y en la exportación a Excel.                          }
{******************************************************************************}
unit inLibBalanceAvisos;

interface

uses
  frxClass;

const
  BANDA_AVISO_FACTURADO = 'AVIFAC';
  BANDA_STOCK_SIN_MOVIMIENTOS = 'SINMOV';

// True si el código de banda es un aviso del balance.
function EsBandaAvisoBalance(const ABanda: string): Boolean;

// Añade a cada memo de las bandas de detalle del dataset del balance un
// resaltado (rojo y negrita) que se activa en las filas de aviso.
// FastReport lo aplica y lo deshace fila a fila. No duplica el resaltado si
// el formato ya lo trae (formatos personalizados guardados después).
procedure ResaltarAvisosBalance(AInforme: TfrxReport;
  ADatos: TfrxDataSet);

// Explica los avisos en la cabecera, incluidas las plantillas guardadas.
procedure ExplicarAvisosBalance(AInforme: TfrxReport);

implementation

uses
  System.SysUtils, System.Classes, System.UITypes, Vcl.Graphics, inLibMsgArticulos;

procedure ExplicarAvisosBalance(AInforme: TfrxReport);
var
  oCabecera: TfrxComponent;
  oLeyenda: TfrxMemoView;
begin
  if (AInforme <> nil) and
     (AInforme.FindObject('LeyendaAvisosBalance') = nil) then
  begin
    oCabecera := AInforme.FindObject('ReportTitle1');
    if oCabecera is TfrxReportTitle then
    begin
      oLeyenda := TfrxMemoView.Create(oCabecera);
      oLeyenda.Name := 'LeyendaAvisosBalance';
      oLeyenda.Left := 0;
      oLeyenda.Top := TfrxReportTitle(oCabecera).Height;
      oLeyenda.Width := TfrxReportTitle(oCabecera).Width;
      oLeyenda.Height := 30;
      oLeyenda.Font.Name := 'Arial';
      oLeyenda.Font.Size := 8;
      oLeyenda.Text := SLeyendaAvisosBalance;
      TfrxReportTitle(oCabecera).Height := oLeyenda.Top + oLeyenda.Height;
    end;
  end;
end;

function EsBandaAvisoBalance(const ABanda: string): Boolean;
begin
  Result := SameText(ABanda, BANDA_AVISO_FACTURADO) or
            SameText(ABanda, BANDA_STOCK_SIN_MOVIMIENTOS);
end;

function CondicionAviso(const ANombreDataSet: string): string;
begin
  Result := Format('(<%0:s."BANDA"> = ''%1:s'') or ' +
    '(<%0:s."BANDA"> = ''%2:s'')',
    [ANombreDataSet, BANDA_AVISO_FACTURADO, BANDA_STOCK_SIN_MOVIMIENTOS]);
end;

function TieneResaltado(AMemo: TfrxCustomMemoView;
  const ACondicion: string): Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  for iIndice := 0 to AMemo.Highlights.Count - 1 do
    if SameText(AMemo.Highlights[iIndice].Condition, ACondicion) then
      Result := True;
end;

procedure ResaltarMemo(AMemo: TfrxCustomMemoView;
  const ACondicion: string);
var
  oResaltado: TfrxHighlight;
begin
  if not TieneResaltado(AMemo, ACondicion) then
  begin
    oResaltado := TfrxHighlight(AMemo.Highlights.Add);
    oResaltado.Condition := ACondicion;
    oResaltado.Font.Assign(AMemo.Font);
    oResaltado.Font.Color := clRed;
    oResaltado.Font.Style := oResaltado.Font.Style + [fsBold];
    oResaltado.ApplyFill := False;
  end;
end;

procedure ResaltarBanda(ABanda: TfrxBand; const ACondicion: string);
var
  iIndice: Integer;
begin
  for iIndice := 0 to ABanda.Objects.Count - 1 do
    if TObject(ABanda.Objects[iIndice]) is TfrxCustomMemoView then
      ResaltarMemo(TfrxCustomMemoView(ABanda.Objects[iIndice]), ACondicion);
end;

procedure ResaltarAvisosBalance(AInforme: TfrxReport;
  ADatos: TfrxDataSet);
var
  iIndice: Integer;
  oObjeto: TObject;
  sCondicion: string;
begin
  if (AInforme <> nil) and (ADatos <> nil) then
  begin
    sCondicion := CondicionAviso(ADatos.UserName);
    for iIndice := 0 to AInforme.AllObjects.Count - 1 do
    begin
      oObjeto := TObject(AInforme.AllObjects[iIndice]);
      if (oObjeto is TfrxDataBand) and
         (TfrxDataBand(oObjeto).DataSet = ADatos) then
        ResaltarBanda(TfrxBand(oObjeto), sCondicion);
    end;
  end;
end;

end.
