{******************************************************************************}
{                                                                              }
{  Módulo:       inLibJsonSeguro                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura de valores JSON con defecto explícito: sin try/except mudos.      }
{    Si la clave falta, es null o el tipo no casa, devuelve el defecto que     }
{    decide el llamador (Fase 1 del PLAN_SOLID: except vacíos = 0).            }
{******************************************************************************}
unit inLibJsonSeguro;

interface

uses
  System.SysUtils, System.JSON, System.DateUtils;

// Valor numérico real de AClave, o ADefecto si falta / null / no casa.
function JsonDoubleODefecto(AObjeto: TJSONObject; const AClave: string;
                            const ADefecto: Double): Double;
// Valor entero de AClave, o ADefecto si falta / null / no casa.
function JsonEnteroODefecto(AObjeto: TJSONObject; const AClave: string;
                            const ADefecto: Integer): Integer;
// Fecha ISO 8601 en hora local, o ADefecto si el texto no parsea.
function JsonFechaIsoODefecto(const ATexto: string;
                              const ADefecto: TDateTime): TDateTime;

implementation

function JsonDoubleODefecto(AObjeto: TJSONObject; const AClave: string;
                            const ADefecto: Double): Double;
var
  oValor: TJSONValue;
begin
  Result := ADefecto;
  if Assigned(AObjeto) then
  begin
    oValor := AObjeto.GetValue(AClave);
    if Assigned(oValor) and (not (oValor is TJSONNull)) then
    begin
      if not oValor.TryGetValue<Double>(Result) then
        Result := ADefecto;
    end;
  end;
end;

function JsonEnteroODefecto(AObjeto: TJSONObject; const AClave: string;
                            const ADefecto: Integer): Integer;
var
  oValor: TJSONValue;
begin
  Result := ADefecto;
  if Assigned(AObjeto) then
  begin
    oValor := AObjeto.GetValue(AClave);
    if Assigned(oValor) and (not (oValor is TJSONNull)) then
    begin
      if not oValor.TryGetValue<Integer>(Result) then
        Result := ADefecto;
    end;
  end;
end;

function JsonFechaIsoODefecto(const ATexto: string;
                              const ADefecto: TDateTime): TDateTime;
begin
  if not TryISO8601ToDate(ATexto, Result, False) then
    Result := ADefecto;
end;

end.
