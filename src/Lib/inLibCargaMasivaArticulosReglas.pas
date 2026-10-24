{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCargaMasivaArticulosReglas                              }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Reglas puras para calcular cantidades de reposicion por SKU.              }
{******************************************************************************}
unit inLibCargaMasivaArticulosReglas;

interface

uses
  System.SysUtils;

const
  RESERVA_STOCK_ORIGEN_DEFECTO_DTR = 1.0;
  MAXIMO_SERVIR_POR_SKU_DEFECTO_DTR = 2.0;
  STOCK_MAXIMO_ALMACEN_VENTA_DEFECTO_DTR = 0.0;

function CalcularCantidadServirSku(
  AStockDisponible: Double;
  AReservaStockOrigen: Double;
  AMaximoServirPorSku: Double): Double;

function RepartirCantidadServirSku(
  const AStocks: TArray<Double>;
  AReservaStockOrigen: Double;
  AMaximoServirPorSku: Double): TArray<Double>;

function CumpleStockMaximoAlmacenVenta(
  AStock: Double;
  AStockMaximo: Double): Boolean;

implementation

uses
  System.Math;

function CalcularCantidadServirSku(
  AStockDisponible: Double;
  AReservaStockOrigen: Double;
  AMaximoServirPorSku: Double): Double;
var
  dCantidadDisponible: Double;
  dCantidadMaxima: Double;
  dReservaStock: Double;
begin
  dReservaStock := Max(0.0, AReservaStockOrigen);
  dCantidadMaxima := Max(0.0, AMaximoServirPorSku);
  dCantidadDisponible := Max(0.0, AStockDisponible - dReservaStock);
  Result := Min(dCantidadMaxima, dCantidadDisponible);
end;

function RepartirCantidadServirSku(
  const AStocks: TArray<Double>;
  AReservaStockOrigen: Double;
  AMaximoServirPorSku: Double): TArray<Double>;
var
  dPendiente: Double;
  dStockTotal: Double;
  i: Integer;
begin
  SetLength(Result, Length(AStocks));
  dStockTotal := 0;
  for i := 0 to High(AStocks) do
  begin
    dStockTotal := dStockTotal + AStocks[i];
  end;
  dPendiente := CalcularCantidadServirSku(
    dStockTotal,
    AReservaStockOrigen,
    AMaximoServirPorSku);
  for i := 0 to High(AStocks) do
  begin
    Result[i] := Min(Max(0.0, AStocks[i]), dPendiente);
    dPendiente := dPendiente - Result[i];
    if dPendiente <= 0 then
    begin
      Break;
    end;
  end;
end;

function CumpleStockMaximoAlmacenVenta(
  AStock: Double;
  AStockMaximo: Double): Boolean;
begin
  Result := Max(0.0, AStock) <= Max(0.0, AStockMaximo);
end;

end.
