{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopColaSenal                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Señal auto-reset compartida por productores y consumidor PrestaShop.      }
{******************************************************************************}
unit inLibPrestaShopColaSenal;

interface

uses
  System.SyncObjs;

procedure SolicitarProcesadoPrestaShop;
function EsperarProcesadoPrestaShop(AMilisegundos: Cardinal): TWaitResult;

implementation

uses
  System.SysUtils;

var
  GSenalProcesadoPrestaShop: TEvent;

procedure SolicitarProcesadoPrestaShop;
begin
  GSenalProcesadoPrestaShop.SetEvent;
end;

function EsperarProcesadoPrestaShop(AMilisegundos: Cardinal): TWaitResult;
begin
  Result := GSenalProcesadoPrestaShop.WaitFor(AMilisegundos);
end;

initialization
  GSenalProcesadoPrestaShop := TEvent.Create(nil, False, False, '');

finalization
  FreeAndNil(GSenalProcesadoPrestaShop);

end.
