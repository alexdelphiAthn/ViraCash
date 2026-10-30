{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrecioUnidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                                }
{    Precio por kg o por litro a partir del valor básico del SKU, sin UI ni    }
{    persistencia. El factor lo da vi_articulos_skus_etiquetas: 1 / contenido  }
{    en la unidad base (125 g -> 8). Solo se imprime en etiquetas.             }
{******************************************************************************}
unit inLibPrecioUnidad;

interface

type
  TPrecioPorUnidad = record
    Valido: Boolean;
    Precio: Double;
    Unidad: string;
    function Texto: string;
  end;

function CalcularPrecioPorUnidad(APrecio, AFactor: Double;
  const AUnidad: string): TPrecioPorUnidad;

implementation

uses
  System.SysUtils, System.Math;

function EsNumeroPositivo(AValor: Double): Boolean;
begin
  Result := not IsNan(AValor) and not IsInfinite(AValor) and
    (AValor >= 0.000001);
end;

function TPrecioPorUnidad.Texto: string;
begin
  Result := '';
  if Valido then
    Result := FormatFloat('0.00', Precio) + ' €/' + Unidad;
end;

function CalcularPrecioPorUnidad(APrecio, AFactor: Double;
  const AUnidad: string): TPrecioPorUnidad;
begin
  Result := Default(TPrecioPorUnidad);
  Result.Valido := EsNumeroPositivo(AFactor) and (Trim(AUnidad) <> '') and
    not IsNan(APrecio) and not IsInfinite(APrecio) and (APrecio >= 0);
  if Result.Valido then
  begin
    Result.Precio := APrecio * AFactor;
    Result.Unidad := LowerCase(Trim(AUnidad));
  end;
end;

end.
