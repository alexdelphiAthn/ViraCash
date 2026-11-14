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

uses
  Data.DB;

function DescribirDeudaOtrasTiendas(ADatos: TDataSet;
  const AEmpresa, AAlmacen: string): string;

function CalcularImporteSinIvaDeposito(
  AImporte, APorcentajeIva: Currency): Currency;

implementation

uses
  System.SysUtils, inLibMsgCaja;

function DescribirDeudaOtrasTiendas(ADatos: TDataSet;
  const AEmpresa, AAlmacen: string): string;
begin
  Result := '';
  while not ADatos.Eof do
  begin
    if (ADatos.FieldByName('EMPRESA').AsString <> AEmpresa) or
       (ADatos.FieldByName('ALMACEN').AsString <> AAlmacen) then
    begin
      if Result <> '' then
        Result := Result + sLineBreak;
      Result := Result + Format(SInfoDeudaOtraTienda, [
        FormatFloat('#,##0.00',
          ADatos.FieldByName('PENDIENTE').AsCurrency),
        ADatos.FieldByName('ALMACEN').AsString + ' - ' +
          ADatos.FieldByName('TIENDA').AsString,
        ADatos.FieldByName('EMPRESA').AsString]);
    end;
    ADatos.Next;
  end;
end;


function CalcularImporteSinIvaDeposito(
  AImporte, APorcentajeIva: Currency): Currency;
begin
  Result := AImporte;
  if APorcentajeIva <> 0 then
    Result := AImporte / (1 + (APorcentajeIva / 100));
end;

end.
