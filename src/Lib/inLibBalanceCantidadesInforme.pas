{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceCantidadesInforme                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Visibilidad de cantidades agregadas en FastReport.                        }
{******************************************************************************}
unit inLibBalanceCantidadesInforme;

interface

uses
  Data.DB, frxClass, inLibBalanceCantidades;

function PrepararIndiceCantidadesBalance(ADatos: TDataSet;
  const AUnidadArticulo: TUnidadArticuloBalance): TIndiceCantidadesBalance;
procedure AplicarCantidadBalance(AComponente: TfrxReportComponent;
  ADatos: TDataSet; AIndice: TIndiceCantidadesBalance);

function EtiquetaBandaBalance(const ACodigo, APredeterminado: string): string;
function RotuloEjeBalanceTraducido(const ARotulo: string): string;

implementation

uses
  System.SysUtils, inLibMsgArticulos;

function EtiquetaBandaBalance(
  const ACodigo, APredeterminado: string): string;
begin
  Result := APredeterminado;
  if SameText(ACodigo, 'EXIINI') then
    Result := SCaptionExistenciasInicialesBalanceTallas;
  if SameText(ACodigo, 'EXIFIN') then
    Result := SCaptionExistenciasFinalesBalanceTallas;
  if SameText(ACodigo, 'ENT') then
    Result := SCaptionEntradasBalanceTallas;
  if SameText(ACodigo, 'VEN') then
    Result := SCaptionVentasBalanceTallas;
  if SameText(ACodigo, 'ENTCMP') then
    Result := SCaptionEntradaCompraBalanceTallas;
  if SameText(ACodigo, 'ENTALB') then
    Result := SCaptionAlbaranEntradaBalanceTallas;
  if SameText(ACodigo, 'ENTTRA') then
    Result := SCaptionTraspasosBalanceTallas;
  if SameText(ACodigo, 'ENTDEP') then
    Result := SCaptionDepositosBalanceTallas;
  if SameText(ACodigo, 'ENTREG') then
    Result := SCaptionRegularizacionesBalanceTallas;
  if SameText(ACodigo, 'ENTDEV') then
    Result := SCaptionDevolucionProveedorBalanceTallas;
  if SameText(ACodigo, 'ENTOTR') then
    Result := SCaptionOtrosMovimientosBalanceTallas;
  if SameText(ACodigo, 'SALALB') then
    Result := SCaptionAlbaranVentaBalanceTallas;
end;

function RotuloEjeBalanceTraducido(const ARotulo: string): string;
begin
  // El nombre configurado para un eje personalizado se conserva.
  Result := ARotulo;
  if SameText(ARotulo, 'Color') then
    Result := SCaptionColColor;
end;

function CodigosGrupo(ADatos: TDataSet): TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, 3);
  for i := 1 to 3 do
    Result[i - 1] := ADatos.FieldByName(
      Format('GRUPO%d_COD', [i])).AsString;
end;

function PrepararIndiceCantidadesBalance(ADatos: TDataSet;
  const AUnidadArticulo: TUnidadArticuloBalance): TIndiceCantidadesBalance;
var
  oMarca: TBookmark;
  sUnidad: string;
begin
  Result := TIndiceCantidadesBalance.Create;
  try
    oMarca := ADatos.Bookmark;
    ADatos.DisableControls;
    try
      ADatos.First;
      while not ADatos.Eof do
      begin
        sUnidad := '';
        if Assigned(AUnidadArticulo) then
          sUnidad := AUnidadArticulo(
            ADatos.FieldByName('CODIGO_ART_ART').AsString);
        Result.Agregar(sUnidad, CodigosGrupo(ADatos));
        ADatos.Next;
      end;
    finally
      if ADatos.BookmarkValid(oMarca) then
        ADatos.Bookmark := oMarca;
      ADatos.EnableControls;
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

procedure AplicarCantidadBalance(AComponente: TfrxReportComponent;
  ADatos: TDataSet; AIndice: TIndiceCantidadesBalance);
var
  iNivel: Integer;
begin
  if (AComponente is TfrxMemoView) and (AIndice <> nil) then
  begin
    if SameText(AComponente.Name, 'MemoRSCdad') then
      AComponente.Visible := AIndice.TotalSumable;
    for iNivel := 1 to 3 do
      if SameText(AComponente.Name,
        Format('MemoGF%dCdad', [iNivel])) then
        AComponente.Visible := AIndice.GrupoSumable(
          CodigosGrupo(ADatos), iNivel);
  end;
end;

end.
