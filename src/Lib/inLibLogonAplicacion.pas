{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLogonAplicacion                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Clasifica los resultados de autenticación sin filtrar infraestructura.    }
{******************************************************************************}
unit inLibLogonAplicacion;

interface

uses
  inLibLogonAplicacionIntf;

function CrearAplicacionLogon(
  const ARepositorio: IRepositorioLogon): IAplicacionLogon;

implementation

uses
  System.SysUtils,
  inLibNuevoEquipo;

type
  TAplicacionLogon = class(TInterfacedObject, IAplicacionLogon)
  private
    FRepositorio: IRepositorioLogon;
  public
    constructor Create(const ARepositorio: IRepositorioLogon);
    function Autenticar(
      const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
    procedure EstablecerContrasenaNuevoEquipo(
      const AUsuario, AContrasenaNueva: string;
      AExigirContrasenaDemoInicial: Boolean = False);
  end;

function CrearAplicacionLogon(
  const ARepositorio: IRepositorioLogon): IAplicacionLogon;
begin
  Result := TAplicacionLogon.Create(ARepositorio);
end;

constructor TAplicacionLogon.Create(
  const ARepositorio: IRepositorioLogon);
begin
  if ARepositorio = nil then
    raise EArgumentNilException.Create('ARepositorio');
  inherited Create;
  FRepositorio := ARepositorio;
end;

function TAplicacionLogon.Autenticar(
  const AUsuario, AContrasena: string): TResultadoAutenticacionLogon;
begin
  try
    Result := FRepositorio.Autenticar(AUsuario, AContrasena);
  except
    on E: ERepositorioLogonNoDisponible do
      Result := TResultadoAutenticacionLogon.Crear(
        ealNoDisponible,
        E.Message);
    on E: Exception do
      Result := TResultadoAutenticacionLogon.Crear(
        ealError,
        E.Message);
  end;
end;

procedure TAplicacionLogon.EstablecerContrasenaNuevoEquipo(
  const AUsuario, AContrasenaNueva: string;
  AExigirContrasenaDemoInicial: Boolean);
begin
  if not SameText(
           Trim(AUsuario),
           USUARIO_INICIAL_NUEVO_EQUIPO) then
    raise EArgumentException.Create('AUsuario');
  ValidarContrasenaNuevoEquipo(AContrasenaNueva);
  FRepositorio.EstablecerContrasenaNuevoEquipo(
    AUsuario,
    AContrasenaNueva,
    AExigirContrasenaDemoInicial);
end;

end.
