{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuReintentos                                      }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas puras de espera y agotamiento de reintentos Verifactu.             }
{******************************************************************************}
unit inLibVerifactuReintentos;
interface
function CalcularEsperaReintentoVerifactu(AIntentos: Integer): Integer;
function CalcularEstadoReintentoVerifactu(
  AIntentos, AMaxIntentos: Integer): string;
// True si la AEAT ha rechazado el registro por sus datos (EstadoRegistro
// Incorrecto con un código de validación 1xxx, p. ej. 1239 NIF no
// censado): reenviarlo daría el mismo rechazo, así que no se reintenta.
// Los fallos de servicio (4xxx, 5xxx, faults) siguen siendo reintentables.
function EsRechazoDefinitivoVerifactu(
  const AEstadoRegistro, ACodigoError: string): Boolean;
implementation
uses
  System.SysUtils;
function CalcularEsperaReintentoVerifactu(AIntentos: Integer): Integer;
begin
  if AIntentos > 5 then
    Result := 60 * 32
  else
    Result := 60 * (1 shl AIntentos);
end;
function CalcularEstadoReintentoVerifactu(
  AIntentos, AMaxIntentos: Integer): string;
begin
  if (AIntentos + 1) >= AMaxIntentos then
    Result := 'ERROR'
  else
    Result := 'PENDIENTE';
end;
function EsRechazoDefinitivoVerifactu(
  const AEstadoRegistro, ACodigoError: string): Boolean;
var
  iCodigo: Integer;
begin
  iCodigo := StrToIntDef(Trim(ACodigoError), 0);
  Result := SameText(Trim(AEstadoRegistro), 'Incorrecto') and
            (iCodigo >= 1000) and (iCodigo <= 1999);
end;
end.
