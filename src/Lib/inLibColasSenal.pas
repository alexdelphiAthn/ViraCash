{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColasSenal                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Señales auto-reset que despiertan a los hilos de la cola VERI*FACTU/SII   }
{    y de la cola de ventas WS sin esperar al ciclo (FZ-ISSUE-310). La de      }
{    PrestaShop vive en inLibPrestaShopColaSenal.                              }
{******************************************************************************}
unit inLibColasSenal;

interface

uses
  System.SyncObjs;

type
  TColaConSenal = (ccsVerifactu, ccsVentasWs);

procedure SolicitarProcesadoCola(ACola: TColaConSenal);
function EsperarProcesadoCola(ACola: TColaConSenal;
  AMilisegundos: Cardinal): TWaitResult;

implementation

uses
  System.SysUtils;

var
  GSenales: array[TColaConSenal] of TEvent;

procedure SolicitarProcesadoCola(ACola: TColaConSenal);
begin
  GSenales[ACola].SetEvent;
end;

function EsperarProcesadoCola(ACola: TColaConSenal;
  AMilisegundos: Cardinal): TWaitResult;
begin
  Result := GSenales[ACola].WaitFor(AMilisegundos);
end;

procedure CrearSenales;
var
  eCola: TColaConSenal;
begin
  for eCola := Low(TColaConSenal) to High(TColaConSenal) do
    GSenales[eCola] := TEvent.Create(nil, False, False, '');
end;

procedure LiberarSenales;
var
  eCola: TColaConSenal;
begin
  for eCola := Low(TColaConSenal) to High(TColaConSenal) do
    FreeAndNil(GSenales[eCola]);
end;

initialization
  CrearSenales;

finalization
  LiberarSenales;

end.
