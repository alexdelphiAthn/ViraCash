{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosPrestaShopPortes                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                        }
{   Fecha:       19/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                               }
{    Reglas fiscales para los portes de pedidos importados de PrestaShop.     }
{******************************************************************************}
unit inLibPedidosPrestaShopPortes;

interface

uses
  System.SysUtils;

const
  CODIGO_ARTICULO_GASTOS_TRANSPORTE = 'GASTOS_T';
  CODIGO_SKU_GASTOS_TRANSPORTE = 'GASTOS_T';
  DESCRIPCION_GASTOS_TRANSPORTE = 'GASTOS TRANSPORTE';
  TIPO_ARTICULO_GASTOS_TRANSPORTE = 'SERVICIO';
  TIPO_IVA_GASTOS_TRANSPORTE = 'N';

type
  EPortesPedidoPrestaShop = class(Exception);

  TPortesPedidoPrestaShop = record
    DebeInsertarse: Boolean;
    PrecioSinIva: Currency;
    PrecioConIva: Currency;
    PorcentajeIva: Double;
  end;

function PrepararPortesPedidoPrestaShop(
  ATotalSinIva, ATotalConIva: Currency;
  APorcentajeIvaNormal: Double): TPortesPedidoPrestaShop;

implementation

uses
  System.Math;

resourcestring
  SErrorGastosTransportePrestaShopNegativos =
    'Los gastos de transporte de PrestaShop no pueden ser negativos.';
  SErrorPorcentajeIvaNormalNegativo =
    'El porcentaje de IVA normal no puede ser negativo.';
  SErrorPortesPrestaShopIvaNormalNoCoincide =
    'Los portes de PrestaShop no corresponden al IVA normal configurado ' +
    '(sin IVA: %.2f; con IVA: %.2f; IVA normal: %.2f%%).';

const
  TOLERANCIA_REDONDEO_PORTES = 0.01;

function PrepararPortesPedidoPrestaShop(
  ATotalSinIva, ATotalConIva: Currency;
  APorcentajeIvaNormal: Double): TPortesPedidoPrestaShop;
var
  TotalEsperado: Currency;
begin
  Result := Default(TPortesPedidoPrestaShop);
  Result.DebeInsertarse :=
    (Abs(ATotalSinIva) >= 0.005) or (Abs(ATotalConIva) >= 0.005);
  if Result.DebeInsertarse then
  begin
    if (ATotalSinIva < 0) or (ATotalConIva < 0) then
      raise EPortesPedidoPrestaShop.Create(
        SErrorGastosTransportePrestaShopNegativos);
    if APorcentajeIvaNormal < 0 then
      raise EPortesPedidoPrestaShop.Create(SErrorPorcentajeIvaNormalNegativo);
    TotalEsperado := ATotalSinIva * (1 + APorcentajeIvaNormal / 100);
    if Abs(ATotalConIva - TotalEsperado) > TOLERANCIA_REDONDEO_PORTES then
      raise EPortesPedidoPrestaShop.CreateFmt(
        SErrorPortesPrestaShopIvaNormalNoCoincide,
        [ATotalSinIva, ATotalConIva, APorcentajeIvaNormal]);
    Result.PrecioSinIva := ATotalSinIva;
    Result.PrecioConIva := ATotalConIva;
    Result.PorcentajeIva := APorcentajeIvaNormal;
  end;
end;

end.
