{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaSubsanacionImportes                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta unidades e importes de subsanación a líneas en memoria por copia.  }
{******************************************************************************}
unit UniDataCajaSubsanacionImportes;

interface

uses
  Data.DB, Datasnap.DBClient,
  inLibCajaSubsanacion;

function LeerImportesSubsanacion(
  ADataSet: TDataSet): TLineasSubsanacionCaja;
procedure AplicarImportesSubsanacion(ADataSet: TClientDataSet;
  const ALineas: TLineasSubsanacionCaja);
// Deja precios coherentes con el importe de cada línea modificada respecto
// a su importe original, directamente sobre ADataSet (edición en pantalla).
procedure SincronizarPreciosSubsanacion(ADataSet: TDataSet;
  const ALineas: TLineasSubsanacionCaja);

implementation

uses
  inLibRedondeo,
  System.SysUtils, System.Math, System.Generics.Collections,
  inLibFacturas, inLibMsgSubsanacionCaja;

type
  TIndicesSubsanacion = TDictionary<string, Integer>;

procedure ValidarDataSetSubsanacion(ADataSet: TDataSet);
begin
  if (ADataSet = nil) or not ADataSet.Active then
    raise EArgumentException.Create(SSubsanacionDatosNoDisponibles);
  if ADataSet.State <> dsBrowse then
    raise EArgumentException.Create(SSubsanacionEdicionPendiente);
end;

function LeerLineaSubsanacion(ADataSet: TDataSet): TLineaSubsanacionCaja;
begin
  Result := Default(TLineaSubsanacionCaja);
  Result.Numero := ADataSet.FieldByName(fnrolin).AsString;
  Result.Descripcion := ADataSet.FieldByName(fdescripcion).AsString;
  Result.CantidadOriginal := ADataSet.FieldByName(fcant).AsFloat;
  Result.Cantidad := Result.CantidadOriginal;
  Result.ImporteOriginal := RedondearDecimales(
    ADataSet.FieldByName(ftotciva).AsCurrency, 2);
  Result.Importe := Result.ImporteOriginal;
  Result.PrecioSalidaOriginal := ADataSet.FieldByName(fpreciosal).AsCurrency;
  Result.PrecioSalida := Result.PrecioSalidaOriginal;
end;

function LeerImportesSubsanacion(
  ADataSet: TDataSet): TLineasSubsanacionCaja;
var
  oLineas: TList<TLineaSubsanacionCaja>;
  aMarcador: TBookmark;
begin
  ValidarDataSetSubsanacion(ADataSet);
  oLineas := TList<TLineaSubsanacionCaja>.Create;
  try
    ADataSet.DisableControls;
    aMarcador := ADataSet.GetBookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        oLineas.Add(LeerLineaSubsanacion(ADataSet));
        ADataSet.Next;
      end;
      Result := oLineas.ToArray;
    finally
      if ADataSet.BookmarkValid(aMarcador) then
        ADataSet.GotoBookmark(aMarcador);
      ADataSet.FreeBookmark(aMarcador);
      ADataSet.EnableControls;
    end;
  finally
    FreeAndNil(oLineas);
  end;
end;

procedure IndexarLineasSubsanacion(const ALineas: TLineasSubsanacionCaja;
  AIndices: TIndicesSubsanacion);
var
  i: Integer;
begin
  for i := 0 to High(ALineas) do
  begin
    if (Trim(ALineas[i].Numero) = '') or
       AIndices.ContainsKey(ALineas[i].Numero) then
      raise EArgumentException.Create(SSubsanacionIdentificadorLinea);
    AIndices.Add(ALineas[i].Numero, i);
  end;
end;

procedure ValidarCorrespondenciaLinea(ADataSet: TDataSet;
  const ALinea: TLineaSubsanacionCaja);
var
  rActual: TLineaSubsanacionCaja;
begin
  rActual := LeerLineaSubsanacion(ADataSet);
  if (rActual.CantidadOriginal <> ALinea.CantidadOriginal) or
     (rActual.ImporteOriginal <> ALinea.ImporteOriginal) or
     (rActual.PrecioSalidaOriginal <> ALinea.PrecioSalidaOriginal) then
    raise EArgumentException.CreateFmt(
      SSubsanacionLineaModificada, [ALinea.Numero]);
end;

procedure ValidarCorrespondenciaLineas(ADataSet: TDataSet;
  const ALineas: TLineasSubsanacionCaja; AIndices: TIndicesSubsanacion);
var
  iIndice: Integer;
  sNumero: string;
  oVisitadas: TDictionary<string, Boolean>;
begin
  if ADataSet.RecordCount <> Length(ALineas) then
    raise EArgumentException.Create(SSubsanacionLineasDistintas);
  oVisitadas := TDictionary<string, Boolean>.Create;
  try
    ADataSet.First;
    while not ADataSet.Eof do
    begin
      sNumero := ADataSet.FieldByName(fnrolin).AsString;
      if not AIndices.TryGetValue(sNumero, iIndice) or
         oVisitadas.ContainsKey(sNumero) then
        raise EArgumentException.Create(SSubsanacionLineasDistintas);
      oVisitadas.Add(sNumero, True);
      ValidarCorrespondenciaLinea(ADataSet, ALineas[iIndice]);
      ADataSet.Next;
    end;
  finally
    FreeAndNil(oVisitadas);
  end;
end;

procedure CopiarImportesCalculados(ADataSet: TDataSet;
  ALinea: TLinFac; AImporte: Currency);
begin
  ADataSet.Edit;
  ADataSet.FieldByName(fcant).AsFloat := ALinea.Cant;
  ADataSet.FieldByName(fpreciosal).AsCurrency := ALinea.PrecioSal;
  ADataSet.FieldByName(fpordto).AsCurrency := ALinea.PorDto;
  ADataSet.FieldByName(fdto).AsCurrency := ALinea.Dto;
  ADataSet.FieldByName(fpresiva).AsCurrency := ALinea.PreSiva;
  ADataSet.FieldByName(fpreciva).AsCurrency := ALinea.PreCiva;
  ADataSet.FieldByName(ftotciva).AsCurrency := AImporte;
  ADataSet.FieldByName(ftotsiva).AsCurrency := ALinea.TotSiva;
  ADataSet.Post;
end;

procedure AplicarImporteLinea(ADataSet: TDataSet;
  const ALinea: TLineaSubsanacionCaja);
var
  oLinea: TLinFac;
  dPrecio: Currency;
  dTotalCalculado: Currency;
begin
  dPrecio := CalcularPrecioSubsanacion(ALinea);
  oLinea := TLinFac.Create(ADataSet);
  try
    // Unidades corregidas (o las originales); el cálculo usa Currency y
    // sólo admite cuatro decimales de cantidad.
    oLinea.Cant := ALinea.Cantidad;
    if not SameValue(oLinea.Cant, ALinea.Cantidad, 0.000001) then
      raise EArgumentException.CreateFmt(
        SSubsanacionPrecisionCantidad, [ALinea.Numero]);
    // Precio de salida tecleado (o el original) y la diferencia con el
    // importe como descuento de la línea, igual que en el ticket.
    if ALinea.PrecioSalida <> ALinea.PrecioSalidaOriginal then
      oLinea.PrecioSal := ALinea.PrecioSalida;
    oLinea.PreCiva := dPrecio;
    if SameText(oLinea.Impcl, 'S') then
      oLinea.Dto := oLinea.PrecioSal - dPrecio
    else
      oLinea.Dto := oLinea.PrecioSal - oLinea.PreSiva;
    oLinea.CalcularLinea;
    // RedondearDecimales devuelve Double: se compara en Currency para no fallar
    // con importes sin representación binaria exacta (36,30).
    dTotalCalculado := RedondearDecimales(oLinea.TotCiva, 2);
    if dTotalCalculado <> ALinea.Importe then
      raise EArgumentException.CreateFmt(
        SSubsanacionPrecisionLinea, [ALinea.Numero]);
    CopiarImportesCalculados(ADataSet, oLinea, ALinea.Importe);
  finally
    FreeAndNil(oLinea);
  end;
end;

procedure AplicarLineasEnCopia(ADataSet: TDataSet;
  const ALineas: TLineasSubsanacionCaja; AIndices: TIndicesSubsanacion);
var
  iIndice: Integer;
begin
  ADataSet.First;
  while not ADataSet.Eof do
  begin
    iIndice := AIndices[ADataSet.FieldByName(fnrolin).AsString];
    if LineaSubsanacionModificada(ALineas[iIndice]) then
      AplicarImporteLinea(ADataSet, ALineas[iIndice]);
    ADataSet.Next;
  end;
end;

procedure PublicarCopiaSubsanacion(ADataSet, ACopia: TClientDataSet);
var
  sLineaActual: string;
begin
  sLineaActual := ADataSet.FieldByName(fnrolin).AsString;
  ADataSet.DisableControls;
  try
    ADataSet.Data := ACopia.Data;
    ADataSet.Locate(fnrolin, sLineaActual, []);
  finally
    ADataSet.EnableControls;
  end;
end;

procedure AplicarImportesSubsanacion(ADataSet: TClientDataSet;
  const ALineas: TLineasSubsanacionCaja);
var
  oCopia: TClientDataSet;
  oIndices: TIndicesSubsanacion;
begin
  ValidarDataSetSubsanacion(ADataSet);
  ValidarImportesSubsanacion(ALineas);
  oCopia := TClientDataSet.Create(nil);
  try
    oCopia.Data := ADataSet.Data;
    oIndices := TIndicesSubsanacion.Create;
    try
      IndexarLineasSubsanacion(ALineas, oIndices);
      ValidarCorrespondenciaLineas(oCopia, ALineas, oIndices);
      AplicarLineasEnCopia(oCopia, ALineas, oIndices);
      PublicarCopiaSubsanacion(ADataSet, oCopia);
    finally
      FreeAndNil(oIndices);
    end;
  finally
    FreeAndNil(oCopia);
  end;
end;

procedure SincronizarPreciosSubsanacion(ADataSet: TDataSet;
  const ALineas: TLineasSubsanacionCaja);
var
  oIndices: TIndicesSubsanacion;
  aMarcador: TBookmark;
  iIndice: Integer;
begin
  ValidarDataSetSubsanacion(ADataSet);
  ValidarImportesSubsanacion(ALineas);
  oIndices := TIndicesSubsanacion.Create;
  try
    IndexarLineasSubsanacion(ALineas, oIndices);
    ADataSet.DisableControls;
    aMarcador := ADataSet.GetBookmark;
    try
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        if not oIndices.TryGetValue(ADataSet.FieldByName(fnrolin).AsString,
             iIndice) then
          raise EArgumentException.Create(SSubsanacionLineasDistintas);
        if LineaSubsanacionModificada(ALineas[iIndice]) then
          AplicarImporteLinea(ADataSet, ALineas[iIndice]);
        ADataSet.Next;
      end;
    finally
      if ADataSet.BookmarkValid(aMarcador) then
        ADataSet.GotoBookmark(aMarcador);
      ADataSet.FreeBookmark(aMarcador);
      ADataSet.EnableControls;
    end;
  finally
    FreeAndNil(oIndices);
  end;
end;

end.
