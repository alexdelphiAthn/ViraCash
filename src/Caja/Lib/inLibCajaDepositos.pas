{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaDepositos                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cálculos puros para materializar depósitos pendientes en caja.           }
{******************************************************************************}
unit inLibCajaDepositos;

interface

function CalcularImporteSinIvaDeposito(
  AImporte, APorcentajeIva: Currency): Currency;

implementation

function CalcularImporteSinIvaDeposito(
  AImporte, APorcentajeIva: Currency): Currency;
begin
  Result := AImporte;
  if APorcentajeIva <> 0 then
    Result := AImporte / (1 + (APorcentajeIva / 100));
end;

end.
