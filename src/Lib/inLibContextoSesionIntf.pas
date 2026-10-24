{******************************************************************************}
{                                                                              }
{  Módulo:       inLibContextoSesionIntf                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y estructuras del contexto de la sesión de la aplicación.       }
{******************************************************************************}
unit inLibContextoSesionIntf;

interface

type
  TLogSesionProc = procedure(const ATexto: string) of object;

  TIdentidadSesion = record
    Usuario  : string;
    Grupo    : string;
    GrupoRaiz: string;
    class function Crear(
      const AUsuario, AGrupo, AGrupoRaiz: string
    ): TIdentidadSesion; static;
    function EsAdministrador: Boolean;
  end;

  TUbicacionSesion = record
    Empresa: string;
    Almacen: string;
    Caja   : string;
    class function Crear(
      const AEmpresa, AAlmacen, ACaja: string
    ): TUbicacionSesion; static;
  end;

  TResultadoInicioSesion = record
    Autenticado: Boolean;
    Identidad  : TIdentidadSesion;
    Ubicacion  : TUbicacionSesion;
    class function CrearAutenticado(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion
    ): TResultadoInicioSesion; static;
    class function CrearNoAutenticado: TResultadoInicioSesion; static;
  end;

  IContextoSesionAplicacion = interface
    ['{EC179077-3766-447E-8117-E5B6714444EC}']
    function GetCerrandoAplicacion: Boolean;
    function GetIdentidad: TIdentidadSesion;
    function GetUbicacion: TUbicacionSesion;
    procedure LogSesion(const ATexto: string);
    property CerrandoAplicacion: Boolean
      read GetCerrandoAplicacion;
    property Identidad: TIdentidadSesion read GetIdentidad;
    property Ubicacion: TUbicacionSesion read GetUbicacion;
  end;

  IGestorContextoSesion = interface
    ['{EB158CD4-A7EE-4AA4-AEA6-92CD19A9E715}']
    procedure AsignarLogSesion(ALogSesion: TLogSesionProc);
    procedure MarcarCierreAplicacion;
    procedure EstablecerIdentidad(const AIdentidad: TIdentidadSesion);
    procedure CambiarUbicacion(const AUbicacion: TUbicacionSesion);
  end;

  IProveedorContextoSesion = interface
    ['{F4896B62-6FC6-4E32-9BDF-372C918F217A}']
    function GetContextoSesion: IContextoSesionAplicacion;
    property ContextoSesion: IContextoSesionAplicacion
      read GetContextoSesion;
  end;

implementation

uses
  System.SysUtils;

class function TIdentidadSesion.Crear(
  const AUsuario, AGrupo, AGrupoRaiz: string): TIdentidadSesion;
begin
  Result.Usuario := Trim(AUsuario);
  Result.Grupo := Trim(AGrupo);
  Result.GrupoRaiz := Trim(AGrupoRaiz);
end;

function TIdentidadSesion.EsAdministrador: Boolean;
begin
  Result := SameText(GrupoRaiz, 'S');
end;

class function TUbicacionSesion.Crear(
  const AEmpresa, AAlmacen, ACaja: string): TUbicacionSesion;
begin
  Result.Empresa := Trim(AEmpresa);
  Result.Almacen := Trim(AAlmacen);
  Result.Caja := Trim(ACaja);
end;

class function TResultadoInicioSesion.CrearAutenticado(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion): TResultadoInicioSesion;
begin
  Result.Autenticado := True;
  Result.Identidad := AIdentidad;
  Result.Ubicacion := AUbicacion;
end;

class function TResultadoInicioSesion.CrearNoAutenticado:
  TResultadoInicioSesion;
begin
  Result.Autenticado := False;
  Result.Identidad := TIdentidadSesion.Crear('', '', '');
  Result.Ubicacion := TUbicacionSesion.Crear('', '', '');
end;

end.
