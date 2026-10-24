{******************************************************************************}
{                                                                              }
{  Módulo:       inLibExportacionCompraModelo                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Calcula la disposición tabular de compras sin depender de datasets ni    }
{    componentes visuales.                                                     }
{******************************************************************************}
unit inLibExportacionCompraModelo;

interface

uses
  inLibPivoteVentaCalculo;

const
  // Las columnas T01..T21 de las vistas de impresion de compras.
  MAX_TALLAS_EXPORTACION_COMPRA = MAX_TALLAS_HORIZONTAL;
  TALLAS_PREDETERMINADAS_COMPRA = 10;

type
  TColumnasCompraHorizontal = record
    Articulo: Integer;
    Referencia: Integer;
    Descripcion: Integer;
    Color: Integer;
    Sistema: Integer;
    PrecioCompra: Integer;
    PrecioVenta: Integer;
    PrimeraTalla: Integer;
    Unidades: Integer;
    Importe: Integer;
    Ultima: Integer;
  end;

function NormalizarNumeroTallasCompra(ANumero: Integer): Integer;
function UltimaTallaInformada(const ATallas: array of string): Integer;
function CalcularColumnasCompraHorizontal(ANumeroTallas: Integer;
  AMostrarPrecioVenta: Boolean): TColumnasCompraHorizontal;

implementation

uses
  System.SysUtils;

function NormalizarNumeroTallasCompra(ANumero: Integer): Integer;
begin
  if ANumero <= 0 then
    Result := TALLAS_PREDETERMINADAS_COMPRA
  else if ANumero > MAX_TALLAS_EXPORTACION_COMPRA then
    Result := MAX_TALLAS_EXPORTACION_COMPRA
  else
    Result := ANumero;
end;

function UltimaTallaInformada(const ATallas: array of string): Integer;
var
  iTalla: Integer;
begin
  Result := 0;
  iTalla := High(ATallas);
  while (Result = 0) and (iTalla >= Low(ATallas)) do
  begin
    if Trim(ATallas[iTalla]) <> '' then
      Result := iTalla + 1;
    Dec(iTalla);
  end;
end;

function CalcularColumnasCompraHorizontal(ANumeroTallas: Integer;
  AMostrarPrecioVenta: Boolean): TColumnasCompraHorizontal;
begin
  ANumeroTallas := NormalizarNumeroTallasCompra(ANumeroTallas);
  Result.Articulo := 0;
  Result.Referencia := 1;
  Result.Descripcion := 2;
  Result.Color := 3;
  Result.Sistema := 4;
  Result.PrecioCompra := 5;
  if AMostrarPrecioVenta then
  begin
    Result.PrecioVenta := 6;
    Result.PrimeraTalla := 7;
  end
  else
  begin
    Result.PrecioVenta := -1;
    Result.PrimeraTalla := 6;
  end;
  Result.Unidades := Result.PrimeraTalla + ANumeroTallas;
  Result.Importe := Result.Unidades + 1;
  Result.Ultima := Result.Importe;
end;

end.
