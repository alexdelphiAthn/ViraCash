{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosVisibilidad                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decide qué columnas de tarifas y SKUs aportan información visible.       }
{******************************************************************************}
unit inLibArticulosVisibilidad;

interface

uses
  Data.DB;

type
  TVisibilidadColumnasArticulo = record
    MostrarSkuTarifa: Boolean;
    MostrarCompraSku: Boolean;
  end;

function EvaluarVisibilidadColumnasArticulo(
  ATarifas, ASkus: TDataSet): TVisibilidadColumnasArticulo;

implementation

uses
  System.SysUtils;

const
  cCampoCodigoUnidadTarifa = 'CODIGO_UNIDAD_ARTTAR';
  cCampoPrecioUltimaCompraSku = 'PRECIO_ULT_COMPRA_SKUC';

function ContieneTextoNoVacio(
  ADataSet: TDataSet;
  const ACampo: string): Boolean;
var
  Campo: TField;
  Marcador: TBookmark;
begin
  Result := False;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    Campo := ADataSet.FindField(ACampo);
    if Assigned(Campo) and not ADataSet.IsEmpty then
    begin
      ADataSet.DisableControls;
      Marcador := ADataSet.GetBookmark;
      try
        ADataSet.First;
        while not ADataSet.Eof and not Result do
        begin
          Result := not Campo.IsNull and (Trim(Campo.AsString) <> '');
          ADataSet.Next;
        end;
      finally
        if ADataSet.BookmarkValid(Marcador) then
          ADataSet.GotoBookmark(Marcador);
        ADataSet.FreeBookmark(Marcador);
        ADataSet.EnableControls;
      end;
    end;
  end;
end;

function ContieneNumeroNoCero(
  ADataSet: TDataSet;
  const ACampo: string): Boolean;
var
  Campo: TField;
  Marcador: TBookmark;
begin
  Result := False;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    Campo := ADataSet.FindField(ACampo);
    if Assigned(Campo) and not ADataSet.IsEmpty then
    begin
      ADataSet.DisableControls;
      Marcador := ADataSet.GetBookmark;
      try
        ADataSet.First;
        while not ADataSet.Eof and not Result do
        begin
          Result := not Campo.IsNull and (Campo.AsFloat <> 0);
          ADataSet.Next;
        end;
      finally
        if ADataSet.BookmarkValid(Marcador) then
          ADataSet.GotoBookmark(Marcador);
        ADataSet.FreeBookmark(Marcador);
        ADataSet.EnableControls;
      end;
    end;
  end;
end;

function EvaluarVisibilidadColumnasArticulo(
  ATarifas, ASkus: TDataSet): TVisibilidadColumnasArticulo;
begin
  Result.MostrarSkuTarifa := ContieneTextoNoVacio(
    ATarifas, cCampoCodigoUnidadTarifa);
  Result.MostrarCompraSku := ContieneNumeroNoCero(
    ASkus, cCampoPrecioUltimaCompraSku);
end;

end.
