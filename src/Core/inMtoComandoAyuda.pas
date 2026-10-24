{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComandoAyuda                                             }
{    Tipo:       Coordinador de aplicación                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Publica la ayuda en la consola o salida estándar y finaliza el proceso.   }
{******************************************************************************}
unit inMtoComandoAyuda;

interface

function EsProcesoComandoAyuda: Boolean;
function EjecutarProcesoComandoAyuda: Cardinal;

implementation

uses
  inLibComandoAyuda,
  inLibLineaComandos,
  inLibSalidaComandos;

function EsProcesoComandoAyuda: Boolean;
begin
  Result := EsComandoAyuda(ObtenerParametrosLineaComandos);
end;

function EjecutarProcesoComandoAyuda: Cardinal;
var
  sAyuda: string;
begin
  sAyuda := CrearTextoAyudaComandos;
  EscribirMensajeComando(sAyuda, False);
  Result := 0;
end;

end.
