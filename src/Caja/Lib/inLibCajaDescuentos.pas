{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaDescuentos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reparte descuentos globales entre las líneas de una venta de caja.        }
{******************************************************************************}
unit inLibCajaDescuentos;

interface

uses
  Data.DB, inLibCajaVentaIntf;

type
  TRepartidorDescuento = class(TInterfacedObject, IRepartidorDescuento)
  public
    function Repartir(
      const ALineas: TArray<TLineaRepartoDescuento>;
      AImporteDescuento: Currency
    ): TArray<TResultadoLineaDescuento>;
  end;

procedure AplicarRepartoDescuentoDataSet(
  const ARepartidor: IRepartidorDescuento;
  ADataSet: TDataSet;
  AImporteDescuento: Currency);

implementation

uses
  inLibRedondeo,
  System.Math, System.SysUtils, inLibFacturas, inLibMsgCaja;

function TRepartidorDescuento.Repartir(
  const ALineas: TArray<TLineaRepartoDescuento>;
  AImporteDescuento: Currency
): TArray<TResultadoLineaDescuento>;
var
  i: Integer;
  dCantidad: Double;
  cBaseAcumulada: Currency;
  cDescuentoHastaLinea: Currency;
  cDescuentoAcumulado: Currency;
  cDescuentoLinea: Currency;
  cTotalLinea: Currency;
  cTotalFinal: Currency;
  cTotalBruto: Currency;
  cComprobacion: Currency;
begin
  SetLength(Result, 0);
  cTotalBruto := 0;
  for i := 0 to High(ALineas) do
  begin
    cTotalBruto := cTotalBruto +
      RedondearDecimales(ALineas[i].Cantidad * ALineas[i].PrecioSalida, 2);
  end;
  if (AImporteDescuento <> 0) and
     (cTotalBruto <> 0) and
     (Length(ALineas) > 0) then
  begin
    SetLength(Result, Length(ALineas));
    cDescuentoAcumulado := 0;
    cBaseAcumulada := 0;
    for i := 0 to High(ALineas) do
    begin
      dCantidad := ALineas[i].Cantidad;
      Result[i].PrecioConDescuento := ALineas[i].PrecioSalida;
      if dCantidad <> 0 then
      begin
        cTotalLinea := RedondearDecimales(
          dCantidad * ALineas[i].PrecioSalida, 2);
        cBaseAcumulada := cBaseAcumulada + cTotalLinea;
        // Redondear el acumulado evita cargar todos los céntimos al final.
        cDescuentoHastaLinea := RedondearDecimales(
          AImporteDescuento * (cBaseAcumulada / cTotalBruto), 2);
        cDescuentoLinea := cDescuentoHastaLinea - cDescuentoAcumulado;
        cTotalFinal := cTotalLinea - cDescuentoLinea;
        Result[i].ImporteDescuento := cDescuentoLinea;
        Result[i].PrecioConDescuento := cTotalFinal / dCantidad;
        // RedondearDecimales devuelve Double y compararlo con un Currency
        // falla por el último bit (273,90 <> 273,90): se pasa antes
        // por una variable Currency para comparar importes exactos.
        cComprobacion := RedondearDecimales(
          Result[i].PrecioConDescuento * dCantidad, 2);
        if cComprobacion <> cTotalFinal then
          raise EArgumentException.Create(SErrorDescuentoPrecisionLinea);
        if cTotalLinea <> 0 then
          Result[i].PorcentajeDescuento :=
            (cDescuentoLinea / cTotalLinea) * 100;
        cDescuentoAcumulado := cDescuentoHastaLinea;
      end;
    end;
  end;
end;

procedure AplicarPrecioRepartido(ALineas: TDataSet;
  APrecioConIva: Currency);
var
  Linea: TLinFac;
begin
  Linea := TLinFac.Create(ALineas);
  try
    Linea.PreCiva := APrecioConIva;
    if SameText(Linea.Impcl, 'S') then
      Linea.Dto := Linea.PrecioSal - APrecioConIva
    else
      Linea.Dto := Linea.PrecioSal - Linea.PreSiva;
    Linea.CalcularLinea;
    Linea.CopyToDataSetLin;
  finally
    Linea.Free;
  end;
end;

procedure AplicarRepartoDescuentoDataSet(
  const ARepartidor: IRepartidorDescuento;
  ADataSet: TDataSet;
  AImporteDescuento: Currency);
var
  Lineas: TArray<TLineaRepartoDescuento>;
  Resultados: TArray<TResultadoLineaDescuento>;
  Marcador: TBookmark;
  i: Integer;
begin
  if Assigned(ARepartidor) and
     Assigned(ADataSet) and
     ADataSet.Active and
     (not ADataSet.IsEmpty) and
     (AImporteDescuento <> 0) then
  begin
    ADataSet.DisableControls;
    Marcador := ADataSet.GetBookmark;
    try
      SetLength(Lineas, ADataSet.RecordCount);
      i := 0;
      ADataSet.First;
      while not ADataSet.Eof do
      begin
        Lineas[i].Cantidad :=
          ADataSet.FieldByName('CANTIDAD_FACLIN').AsFloat;
        Lineas[i].PrecioSalida :=
          ADataSet.FieldByName(fpreciva).AsCurrency;
        Inc(i);
        ADataSet.Next;
      end;
      Resultados := ARepartidor.Repartir(
        Lineas,
        AImporteDescuento);
      if Length(Resultados) = Length(Lineas) then
      begin
        i := 0;
        ADataSet.First;
        while not ADataSet.Eof do
        begin
          if Lineas[i].Cantidad <> 0 then
          begin
            ADataSet.Edit;
            AplicarPrecioRepartido(
              ADataSet, Resultados[i].PrecioConDescuento);
            ADataSet.Post;
          end;
          Inc(i);
          ADataSet.Next;
        end;
      end;
    finally
      if ADataSet.BookmarkValid(Marcador) then
        ADataSet.GotoBookmark(Marcador);
      ADataSet.FreeBookmark(Marcador);
      ADataSet.EnableControls;
    end;
  end;
end;

end.
