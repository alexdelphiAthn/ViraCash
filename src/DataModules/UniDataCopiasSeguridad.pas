{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCopiasSeguridad                                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone el repositorio UniDAC usado por los casos de uso de copias.       }
{******************************************************************************}
unit UniDataCopiasSeguridad;

interface

uses
  Uni,
  inLibContextoSesionIntf,
  inLibCopiasSeguridadIntf;

function CrearRepositorioCopiasSeguridadUniDAC(
  const AContextoSesion: IContextoSesionAplicacion;
  AConexion: TUniConnection): IRepositorioCopiasSeguridad;

implementation

uses
  inLibCopiasSeguridad;

function CrearRepositorioCopiasSeguridadUniDAC(
  const AContextoSesion: IContextoSesionAplicacion;
  AConexion: TUniConnection): IRepositorioCopiasSeguridad;
begin
  Result := TRepositorioCopiasSeguridadUniDAC.Create(
    AContextoSesion,
    AConexion);
end;

end.
