{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPrecioLineaVenta                                         }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       13/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    FZ-ISSUE-942: precio unitario de una linea de venta a partir del precio   }
{    de salida y el % de descuento, con la misma aritmetica Currency que       }
{    TLinFac.CalcularLinea. Lo usan la linea de factura y la prueba de         }
{    precio de caja, para que no puedan divergir.                              }
{******************************************************************************}
unit inLibPrecioLineaVenta;

interface

// Descuento de la linea: APrecioSalida * APorcentajeDto / 100, a Currency
// (4 decimales), igual que TLinFac.
function DescuentoLineaVenta(APrecioSalida, APorcentajeDto: Currency): Currency;

// Precio unitario con el descuento aplicado, sin redondear (4 decimales).
function PrecioLineaVentaConDescuento(APrecioSalida,
  APorcentajeDto: Currency): Currency;

// Importe que cobra la caja por una unidad: el precio con descuento
// redondeado a centimos como el total de la linea (RedondearACentimos).
function PrecioUnidadVentaCaja(APrecioSalida,
  APorcentajeDto: Currency): Double;

implementation

uses
  inLibRedondeo;

function DescuentoLineaVenta(APrecioSalida, APorcentajeDto: Currency): Currency;
begin
  Result := APrecioSalida * (APorcentajeDto / 100);
end;

function PrecioLineaVentaConDescuento(APrecioSalida,
  APorcentajeDto: Currency): Currency;
begin
  Result := APrecioSalida - DescuentoLineaVenta(APrecioSalida, APorcentajeDto);
end;

function PrecioUnidadVentaCaja(APrecioSalida,
  APorcentajeDto: Currency): Double;
begin
  Result := RedondearACentimos(
    PrecioLineaVentaConDescuento(APrecioSalida, APorcentajeDto));
end;

end.
