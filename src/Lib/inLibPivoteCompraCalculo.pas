{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteCompraCalculo                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cálculos puros de claves, pendientes y estados del pivote de compra.      }
{******************************************************************************}
unit inLibPivoteCompraCalculo;

interface

uses
  System.SysUtils,
  inLibGridPivoteCompraTipos;

function ClaveCeldaPivoteCompra(ALinea, AIdAtributo: Integer): Int64;
function LineaClavePivoteCompra(AClave: Int64): Integer;
function AtributoClavePivoteCompra(AClave: Int64): Integer;
function EstadoRecepcionPivoteCompra(APedida, ARecibida: Double)
  : TEstadoFilaRecibida;
function PendientePivoteCompra(APedida, ARecibida: Double): Double;
function LimitarARecibirPivoteCompra(APedida, ARecibida,
  ASolicitada: Double): Double;
function PrefijoSkuTallaPivoteCompra(const ASku: string): string;

implementation

const
  FACTOR_CLAVE_CELDA = 100000;

function ClaveCeldaPivoteCompra(ALinea, AIdAtributo: Integer): Int64;
begin
  Result := Int64(ALinea) * FACTOR_CLAVE_CELDA + AIdAtributo;
end;

function LineaClavePivoteCompra(AClave: Int64): Integer;
begin
  Result := Integer(AClave div FACTOR_CLAVE_CELDA);
end;

function AtributoClavePivoteCompra(AClave: Int64): Integer;
begin
  Result := Integer(AClave mod FACTOR_CLAVE_CELDA);
end;

function EstadoRecepcionPivoteCompra(APedida, ARecibida: Double)
  : TEstadoFilaRecibida;
begin
  if APedida <= 0 then
    Result := efrIndefinido
  else if ARecibida <= 0 then
    Result := efrNada
  else if ARecibida + 0.0001 >= APedida then
    Result := efrTotal
  else
    Result := efrParcial;
end;

function PendientePivoteCompra(APedida, ARecibida: Double): Double;
begin
  Result := APedida - ARecibida;
  if Result < 0 then
    Result := 0;
end;

function LimitarARecibirPivoteCompra(APedida, ARecibida,
  ASolicitada: Double): Double;
var
  dPendiente: Double;
begin
  dPendiente := PendientePivoteCompra(APedida, ARecibida);
  Result := ASolicitada;
  if Result < 0 then
    Result := 0;
  if Result > dPendiente then
    Result := dPendiente;
end;

function PrefijoSkuTallaPivoteCompra(const ASku: string): string;
var
  iPosicion: Integer;
begin
  Result := '';
  iPosicion := LastDelimiter('/', ASku);
  if iPosicion > 1 then
    Result := Copy(ASku, 1, iPosicion - 1);
end;

end.
