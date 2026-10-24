{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsJsonIntf                                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto del serializador JSON de ventas para el webservice.               }
{******************************************************************************}
unit inLibVentasWsJsonIntf;

interface

uses
  inLibParametrosIntf;

type
  IVentasWsJson = interface
    ['{39BA2674-37D2-4593-AC18-973117DB37F0}']
    function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string;
  end;
implementation
end.
