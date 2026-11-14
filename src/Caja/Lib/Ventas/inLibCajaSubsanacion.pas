{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaSubsanacion                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Valida unidades e importes de una subsanación de caja y reparte totales. }
{******************************************************************************}
unit inLibCajaSubsanacion;

interface

type
  TLineaSubsanacionCaja = record
    Numero: string;
    Descripcion: string;
    // Unidades editables como en el ticket; las originales permiten
    // detectar el cambio y regenerar el movimiento de stock de la línea.
    CantidadOriginal: Double;
    Cantidad: Double;
    ImporteOriginal: Currency;
    Importe: Currency;
    // Precio de salida editable como en el ticket; la diferencia con el
    // importe queda como descuento de la línea.
    PrecioSalidaOriginal: Currency;
    PrecioSalida: Currency;
    // Abono a cuenta de un depósito o anticipo que deja deuda: su importe
    // ya se declaró en otro ticket y no se puede corregir.
    Fija: Boolean;
    // Prenda de un depósito: sus unidades son las del depósito cerrado y
    // sólo se corrige su importe.
    CantidadFija: Boolean;
  end;
  TLineasSubsanacionCaja = TArray<TLineaSubsanacionCaja>;

function LineaSubsanacionModificada(
  const ALinea: TLineaSubsanacionCaja): Boolean;
function CantidadSubsanacionModificada(
  const ALinea: TLineaSubsanacionCaja): Boolean;
function HayLineasFijasSubsanacion(
  const ALineas: TLineasSubsanacionCaja): Boolean;

function TotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja): Currency;
procedure ValidarImportesSubsanacion(
  const ALineas: TLineasSubsanacionCaja);
function RepartirTotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja;
  ATotal: Currency): TLineasSubsanacionCaja;
function CalcularPrecioSubsanacion(
  const ALinea: TLineaSubsanacionCaja): Currency;

implementation

uses
  inLibRedondeo,
  System.Math, System.SysUtils,
  inLibMsgSubsanacionCaja;

function TieneDecimalesDeCentimo(AImporte: Currency): Boolean;
var
  iDiezmilesimas: Int64;
begin
  // Currency almacena diezmilésimas; el módulo evita errores binarios.
  Move(AImporte, iDiezmilesimas, SizeOf(iDiezmilesimas));
  Result := (iDiezmilesimas mod 100) <> 0;
end;

procedure ValidarImporteLinea(const ALinea: TLineaSubsanacionCaja);
begin
  if IsNan(ALinea.Cantidad) or IsInfinite(ALinea.Cantidad) then
    raise EArgumentException.CreateFmt(
      SSubsanacionCantidadInvalida, [ALinea.Numero]);
  // Las unidades corregidas siguen siendo una venta: positivas y nunca en
  // la prenda de un depósito, cuyas unidades fija el propio depósito.
  if CantidadSubsanacionModificada(ALinea) then
  begin
    if ALinea.CantidadFija then
      raise EArgumentException.CreateFmt(
        SSubsanacionCantidadFija, [ALinea.Numero]);
    if ALinea.Cantidad <= 0 then
      raise EArgumentException.CreateFmt(
        SSubsanacionCantidadNoPositiva, [ALinea.Numero]);
  end;
  if TieneDecimalesDeCentimo(ALinea.Importe) then
    raise EArgumentException.CreateFmt(
      SSubsanacionDecimalesLinea, [ALinea.Numero]);
  if (ALinea.Cantidad = 0) and (ALinea.Importe <> 0) then
    raise EArgumentException.CreateFmt(
      SSubsanacionCantidadCero, [ALinea.Numero]);
  if ((ALinea.Cantidad > 0) and (ALinea.Importe < 0)) or
     ((ALinea.Cantidad < 0) and (ALinea.Importe > 0)) then
    raise EArgumentException.CreateFmt(
      SSubsanacionSignoLinea, [ALinea.Numero]);
end;

function CalcularPrecioSubsanacion(
  const ALinea: TLineaSubsanacionCaja): Currency;
var
  dImporteReconstruido: Currency;
begin
  ValidarImporteLinea(ALinea);
  Result := 0;
  if ALinea.Cantidad <> 0 then
  begin
    Result := ALinea.Importe / ALinea.Cantidad;
    dImporteReconstruido := RedondearDecimales(
      Result * ALinea.Cantidad, 2);
    if dImporteReconstruido <> ALinea.Importe then
      raise EArgumentException.CreateFmt(
        SSubsanacionPrecisionLinea, [ALinea.Numero]);
  end;
end;

function CantidadSubsanacionModificada(
  const ALinea: TLineaSubsanacionCaja): Boolean;
begin
  Result := ALinea.Cantidad <> ALinea.CantidadOriginal;
end;

function LineaSubsanacionModificada(
  const ALinea: TLineaSubsanacionCaja): Boolean;
begin
  Result := CantidadSubsanacionModificada(ALinea) or
    (ALinea.Importe <> ALinea.ImporteOriginal) or
    (ALinea.PrecioSalida <> ALinea.PrecioSalidaOriginal);
end;

function HayLineasFijasSubsanacion(
  const ALineas: TLineasSubsanacionCaja): Boolean;
var
  rLinea: TLineaSubsanacionCaja;
begin
  Result := False;
  for rLinea in ALineas do
    Result := Result or rLinea.Fija;
end;

function TotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja): Currency;
var
  rLinea: TLineaSubsanacionCaja;
begin
  Result := 0;
  for rLinea in ALineas do
    Result := Result + rLinea.Importe;
end;

procedure ValidarImportesSubsanacion(
  const ALineas: TLineasSubsanacionCaja);
var
  rLinea: TLineaSubsanacionCaja;
begin
  if Length(ALineas) = 0 then
    raise EArgumentException.Create(SSubsanacionSinLineas);
  for rLinea in ALineas do
    CalcularPrecioSubsanacion(rLinea);
end;

procedure RepartirDesdeCero(var ALineas: TLineasSubsanacionCaja;
  ATotal: Currency);
var
  i: Integer;
  iLineaConCantidad: Integer;
  iLineasConCantidad: Integer;
begin
  iLineaConCantidad := -1;
  iLineasConCantidad := 0;
  for i := 0 to High(ALineas) do
  begin
    if ALineas[i].Cantidad <> 0 then
    begin
      iLineaConCantidad := i;
      Inc(iLineasConCantidad);
    end;
  end;
  if iLineasConCantidad <> 1 then
    raise EArgumentException.Create(SSubsanacionTotalInicialCero);
  ALineas[iLineaConCantidad].Importe := ATotal;
end;

procedure RepartirProporcionalmente(var ALineas: TLineasSubsanacionCaja;
  ATotalActual, ATotalNuevo: Currency);
var
  i: Integer;
  dBaseAcumulada: Currency;
  dImporteAcumulado: Currency;
  dImporteHastaLinea: Currency;
begin
  if ((ATotalActual > 0) and (ATotalNuevo < 0)) or
     ((ATotalActual < 0) and (ATotalNuevo > 0)) then
    raise EArgumentException.Create(SSubsanacionSignoTotal);
  dBaseAcumulada := 0;
  dImporteAcumulado := 0;
  for i := 0 to High(ALineas) do
  begin
    dBaseAcumulada := dBaseAcumulada + ALineas[i].Importe;
    // Redondear acumulados conserva céntimos y el signo de cada línea.
    if i = High(ALineas) then
      dImporteHastaLinea := ATotalNuevo
    else
      dImporteHastaLinea := RedondearDecimales(
        ATotalNuevo * (dBaseAcumulada / ATotalActual), 2);
    ALineas[i].Importe := dImporteHastaLinea - dImporteAcumulado;
    dImporteAcumulado := dImporteHastaLinea;
  end;
end;

function RepartirTotalSubsanacion(
  const ALineas: TLineasSubsanacionCaja;
  ATotal: Currency): TLineasSubsanacionCaja;
var
  dTotalActual, dTotalFijo: Currency;
  oLibres: TLineasSubsanacionCaja;
  i, j: Integer;
begin
  ValidarImportesSubsanacion(ALineas);
  if TieneDecimalesDeCentimo(ATotal) then
    raise EArgumentException.Create(SSubsanacionDecimalesTotal);
  // Las líneas fijas conservan su importe: el total se reparte en el resto.
  dTotalFijo := 0;
  oLibres := nil;
  for i := 0 to High(ALineas) do
    if ALineas[i].Fija then
      dTotalFijo := dTotalFijo + ALineas[i].Importe
    else
      oLibres := oLibres + [ALineas[i]];
  if Length(oLibres) = 0 then
    raise EArgumentException.Create(SSubsanacionSinLineasEditables);
  dTotalActual := TotalSubsanacion(oLibres);
  if dTotalActual = 0 then
    RepartirDesdeCero(oLibres, ATotal - dTotalFijo)
  else
    RepartirProporcionalmente(oLibres, dTotalActual, ATotal - dTotalFijo);
  Result := Copy(ALineas);
  j := 0;
  for i := 0 to High(Result) do
    if not Result[i].Fija then
    begin
      Result[i] := oLibres[j];
      Inc(j);
    end;
  ValidarImportesSubsanacion(Result);
end;

end.
