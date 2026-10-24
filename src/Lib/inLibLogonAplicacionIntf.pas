{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLogonAplicacionIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Resultado tipado y puerto de autenticación del inicio de sesión.          }
{******************************************************************************}
unit inLibLogonAplicacionIntf;

interface

uses
  System.SysUtils;

type
  TEstadoAutenticacionLogon = (
    ealAutenticado,
    ealCredencialesInvalidas,
    ealNoDisponible,
    ealError);

  TResultadoAutenticacionLogon = record
    Estado: TEstadoAutenticacionLogon;
    Usuario: string;
    Grupo: string;
    EsGrupoAdministrador: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    Mensaje: string;
    class function Crear(
      AEstado: TEstadoAutenticacionLogon;
      const AMensaje: string): TResultadoAutenticacionLogon; static;
  end;

  ERepositorioLogonNoDisponible = class(Exception);
  ERepositorioLogonError = class(Exception);
  ENuevoEquipoDemoYaPreparado = class(ERepositorioLogonError);

  IRepositorioLogon = interface
    ['{7E58B7E8-C2D1-4D3C-B06A-3317161F5A1B}']
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
    procedure EstablecerContrasenaNuevoEquipo(
      const AUsuario, AContrasenaNueva: string;
      AExigirContrasenaDemoInicial: Boolean = False);
  end;

  IAplicacionLogon = interface
    ['{A64D1FA9-0B93-48B2-9318-80E6A8CF2CD6}']
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
    procedure EstablecerContrasenaNuevoEquipo(
      const AUsuario, AContrasenaNueva: string;
      AExigirContrasenaDemoInicial: Boolean = False);
  end;

  TDecisionErrorScriptLogon = (
    deslContinuar,
    deslDetener);

  TResolverErrorScriptLogon = reference to function(
    const ASentencia, AError: string): TDecisionErrorScriptLogon;

implementation

class function TResultadoAutenticacionLogon.Crear(
  AEstado: TEstadoAutenticacionLogon;
  const AMensaje: string): TResultadoAutenticacionLogon;
begin
  Result := Default(TResultadoAutenticacionLogon);
  Result.Estado := AEstado;
  Result.Mensaje := AMensaje;
end;

end.
