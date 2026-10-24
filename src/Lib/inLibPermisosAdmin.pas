{******************************************************************************}
{                                                                              }
{  Modulo:       inLibPermisosAdmin                                            }
{    Tipo:       Libreria                                                      }
{ Version:       1.1.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Contratos y reglas de administracion de permisos. La persistencia se      }
{    resuelve mediante puertos de consulta y edicion.                          }
{******************************************************************************}
unit inLibPermisosAdmin;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibContextoSesionIntf;

type
  TTipoSujeto = (tsTodos, tsGrupo, tsUsuario);
  TPermisoSujeto = record
    Tipo: TTipoSujeto;
    Nombre: string;
    Grupo: string;
    EsAdmin: Boolean;
  end;
  TPermisoCodigo = record
    Codigo: string;
    Descripcion: string;
  end;
  IConsultaPermisosAdmin = interface
    ['{B73FA01B-8230-4919-A75A-A389581538F9}']
    function ListarSujetos: TArray<TPermisoSujeto>;
    function CatalogoCodigos: TArray<TPermisoCodigo>;
    function CargarExplicitos(
      const ASujeto: string): TDictionary<string, string>;
  end;
  IEdicionPermisosAdmin = interface
    ['{9CFD7E10-A1F4-4300-94E5-15F66776D7C5}']
    procedure Establecer(const ASujeto, ACodigo, AValor,
      ADescripcion, AUsuario: string);
    procedure Heredar(const ASujeto, ACodigo: string);
    function Copiar(const AOrigen, ADestino, AUsuario: string;
      AReemplazar, ASoloMenu: Boolean): Integer;
  end;
  TRepositoriosPermisosAdmin = record
    Consulta: IConsultaPermisosAdmin;
    Edicion: IEdicionPermisosAdmin;
  end;
  TPermisosAdmin = class
  public
    class function ListarSujetos(
      const ARepositorio: IConsultaPermisosAdmin): TArray<TPermisoSujeto>;
    class function CatalogoCodigos(
      const ARepositorio: IConsultaPermisosAdmin): TArray<TPermisoCodigo>;
    class function CargarExplicitos(
      const ARepositorio: IConsultaPermisosAdmin;
      const ASujeto: string): TDictionary<string, string>;
    class procedure Establecer(
      const ARepositorio: IEdicionPermisosAdmin;
      const AContextoSesion: IContextoSesionAplicacion;
      const ASujeto, ACodigo, AValor, ADescripcion: string);
    class procedure Heredar(
      const ARepositorio: IEdicionPermisosAdmin;
      const ASujeto, ACodigo: string);
    class function Copiar(
      const ARepositorio: IEdicionPermisosAdmin;
      const AContextoSesion: IContextoSesionAplicacion;
      const AOrigen, ADestino: string;
      AReemplazar, ASoloMenu: Boolean): Integer;
  end;

implementation

class function TPermisosAdmin.ListarSujetos(
  const ARepositorio: IConsultaPermisosAdmin): TArray<TPermisoSujeto>;
begin
  if ARepositorio = nil then
    Result := nil
  else
    Result := ARepositorio.ListarSujetos;
end;

class function TPermisosAdmin.CatalogoCodigos(
  const ARepositorio: IConsultaPermisosAdmin): TArray<TPermisoCodigo>;
begin
  if ARepositorio = nil then
    Result := nil
  else
    Result := ARepositorio.CatalogoCodigos;
end;

class function TPermisosAdmin.CargarExplicitos(
  const ARepositorio: IConsultaPermisosAdmin;
  const ASujeto: string): TDictionary<string, string>;
begin
  if ARepositorio = nil then
    Result := TDictionary<string, string>.Create
  else
    Result := ARepositorio.CargarExplicitos(ASujeto);
end;

class procedure TPermisosAdmin.Establecer(
  const ARepositorio: IEdicionPermisosAdmin;
  const AContextoSesion: IContextoSesionAplicacion;
  const ASujeto, ACodigo, AValor, ADescripcion: string);
begin
  if (ARepositorio <> nil) and (AContextoSesion <> nil) then
    ARepositorio.Establecer(
      ASujeto,
      ACodigo,
      AValor,
      ADescripcion,
      AContextoSesion.Identidad.Usuario);
end;

class procedure TPermisosAdmin.Heredar(
  const ARepositorio: IEdicionPermisosAdmin;
  const ASujeto, ACodigo: string);
begin
  if ARepositorio <> nil then
    ARepositorio.Heredar(ASujeto, ACodigo);
end;

class function TPermisosAdmin.Copiar(
  const ARepositorio: IEdicionPermisosAdmin;
  const AContextoSesion: IContextoSesionAplicacion;
  const AOrigen, ADestino: string;
  AReemplazar, ASoloMenu: Boolean): Integer;
begin
  Result := 0;
  if (ARepositorio <> nil) and (AContextoSesion <> nil) then
    Result := ARepositorio.Copiar(
      AOrigen,
      ADestino,
      AContextoSesion.Identidad.Usuario,
      AReemplazar,
      ASoloMenu);
end;

end.
