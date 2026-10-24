{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrecioUnidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                                }
{    Contenido neto y precio por unidad de referencia, sin UI ni persistencia. }
{******************************************************************************}
unit inLibPrecioUnidad;

interface

uses
  System.SysUtils;

type
  EValidacionPrecioUnidad = class(Exception);
  TEstadoPrecioUnidad = (epuNoIndicado, epuValido, epuSinContenido,
    epuUnidadIncompatible, epuPrecioInvalido);
  TContenidoPrecioUnidad = record
    CodigoSku: string;
    Contenido: Double;
    UnidadContenido: string;
    Referencia: Double;
    UnidadReferencia: string;
    EsIndicado: Boolean;
    EsTicket: Boolean;
  end;
  TPrecioPorUnidad = record
    Estado: TEstadoPrecioUnidad;
    Precio: Double;
    Unidad: string;
    function Texto: string;
  end;

function CalcularPrecioPorUnidad(const AContenido: TContenidoPrecioUnidad;
  APrecioEnvase: Double): TPrecioPorUnidad;
function BuscarContenidoSku(const AContenidos: TArray<TContenidoPrecioUnidad>;
  const ACodigoSku: string): TContenidoPrecioUnidad;
function TextoPrecioUnidadTicket(const AContenido: TContenidoPrecioUnidad;
  ATotal: Currency; ACantidad: Double): string;

implementation

uses
  System.Math;

function BuscarContenidoSku(const AContenidos: TArray<TContenidoPrecioUnidad>;
  const ACodigoSku: string): TContenidoPrecioUnidad;
var
  Contenido: TContenidoPrecioUnidad;
begin
  Result := Default(TContenidoPrecioUnidad);
  for Contenido in AContenidos do
    if Contenido.CodigoSku = ACodigoSku then
      Result := Contenido;
end;

function TextoPrecioUnidadTicket(const AContenido: TContenidoPrecioUnidad;
  ATotal: Currency; ACantidad: Double): string;
begin
  Result := '';
  if AContenido.EsTicket and (ACantidad <> 0) then
    Result := CalcularPrecioPorUnidad(AContenido,
      Abs(ATotal / ACantidad)).Texto;
end;

function FactorUnidad(const AUnidad: string; out AMagnitud: Integer): Double;
var
  sUnidad: string;
begin
  sUnidad := LowerCase(Trim(AUnidad));
  AMagnitud := 0;
  Result := 0;
  if (sUnidad = 'g') or (sUnidad = 'kg') then
    AMagnitud := 1
  else if (sUnidad = 'ml') or (sUnidad = 'l') then
    AMagnitud := 2
  else if sUnidad = 'ud' then
    AMagnitud := 3;
  if AMagnitud > 0 then
  begin
    Result := 1;
    if (sUnidad = 'g') or (sUnidad = 'ml') then
      Result := 0.001;
  end;
end;

function EsNumeroPositivo(AValor: Double): Boolean;
begin
  Result := not IsNan(AValor) and not IsInfinite(AValor) and
    (AValor >= 0.000001);
end;

function TPrecioPorUnidad.Texto: string;
begin
  Result := '';
  if Estado = epuValido then
    Result := FormatFloat('0.00', Precio) + ' €/' + Unidad;
end;

function CalcularPrecioPorUnidad(const AContenido: TContenidoPrecioUnidad;
  APrecioEnvase: Double): TPrecioPorUnidad;
var
  dContenido, dReferencia: Double;
  iContenido, iReferencia: Integer;
begin
  Result := Default(TPrecioPorUnidad);
  Result.Estado := epuNoIndicado;
  if AContenido.EsIndicado then
  begin
    dContenido := FactorUnidad(AContenido.UnidadContenido, iContenido);
    dReferencia := FactorUnidad(AContenido.UnidadReferencia, iReferencia);
    Result.Estado := epuSinContenido;
    if EsNumeroPositivo(AContenido.Contenido) and
       EsNumeroPositivo(AContenido.Referencia) then
    begin
      Result.Estado := epuUnidadIncompatible;
      if (iContenido > 0) and (iContenido = iReferencia) then
      begin
        Result.Estado := epuPrecioInvalido;
        if not IsNan(APrecioEnvase) and not IsInfinite(APrecioEnvase) and
           (APrecioEnvase >= 0) then
        begin
          Result.Precio := APrecioEnvase * AContenido.Referencia *
            dReferencia / (AContenido.Contenido * dContenido);
          Result.Unidad := LowerCase(Trim(AContenido.UnidadReferencia));
          if AContenido.Referencia <> 1 then
            Result.Unidad := FormatFloat('0.######',
              AContenido.Referencia) + ' ' + Result.Unidad;
          Result.Estado := epuValido;
        end;
      end;
    end;
  end;
end;

end.
