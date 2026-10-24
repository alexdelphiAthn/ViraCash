{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRectificativas                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Reglas de dominio para retirar ventas anuladas o sustituidas. El          }
{    fragmento SQL compartido vive en UniDataRectificativasSql.                }
{******************************************************************************}
unit inLibRectificativas;

interface

function DebeGenerarMovimientosRectificativa(
  const ATipoRectificativa: string;
  AReemplazarMovimientosOriginales: Boolean): Boolean;

implementation

uses
  System.SysUtils;

function DebeGenerarMovimientosRectificativa(
  const ATipoRectificativa: string;
  AReemplazarMovimientosOriginales: Boolean): Boolean;
begin
  Result := (not SameText(Trim(ATipoRectificativa), 'S')) or
    AReemplazarMovimientosOriginales;
end;

end.
