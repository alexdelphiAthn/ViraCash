{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsJson                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.4.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada del serializador JSON de ventas para el webservice. Mantiene      }
{    la firma pública y delega en IVentasWsJson.                               }
{******************************************************************************}
unit inLibVentasWsJson;

interface

uses
  inLibParametrosIntf, inLibVentasWsJsonIntf;

type
  TVentasWsJson = class
  public
    class function ConstruirEvento(
      const AParametrosApp: IParametrosAplicacion;
      const AVersionApp: string;
      const AVentasWsJson: IVentasWsJson;
      AIdCola: Int64;
      const AIdEvento, ATipoEvento, AEmpresa,
        ASerie, ANumero: string): string; static;
  end;

implementation

class function TVentasWsJson.ConstruirEvento(
  const AParametrosApp: IParametrosAplicacion;
  const AVersionApp: string;
  const AVentasWsJson: IVentasWsJson;
  AIdCola: Int64;
  const AIdEvento, ATipoEvento, AEmpresa,
    ASerie, ANumero: string): string;
begin
  Result := AVentasWsJson.ConstruirEvento(
    AParametrosApp, AVersionApp, AIdCola, AIdEvento, ATipoEvento,
    AEmpresa, ASerie, ANumero);
end;

end.
