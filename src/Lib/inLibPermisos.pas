{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPermisos                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resolución inmutable de permisos por usuario, grupo y ámbito Todos.       }
{******************************************************************************}
unit inLibPermisos;

interface

uses
  System.Generics.Collections,
  inLibPermisosIntf;

type
  TPermisosAplicacion = class(
    TInterfacedObject,
    IPermisosAplicacion
  )
  private
    FIdentidad : TIdentidadPermisos;
    FPermisos  : TDictionary<string, Boolean>;
    FDisponible: Boolean;
    function Clave(const ASujeto, ACodigo: string): string;
    function GetDisponible: Boolean;
    function Buscar(const ASujeto, ACodigo: string;
                    out APermitido: Boolean): Boolean;
  public
    constructor Create(
      const AIdentidad: TIdentidadPermisos;
      const AReglas: TArray<TReglaPermiso>;
      ADisponible: Boolean = True
    );
    destructor Destroy; override;
    class function CrearNoDisponible(
      const AIdentidad: TIdentidadPermisos
    ): IPermisosAplicacion; static;
    function Evaluar(const ACodigo: string;
                     APermisoAusente: TPermisoAusente): TResultadoPermiso;
    function TienePermiso(const ACodigo: string;
                          APermisoAusente: TPermisoAusente): Boolean;
  end;

implementation

uses
  System.SysUtils;

constructor TPermisosAplicacion.Create(
  const AIdentidad: TIdentidadPermisos;
  const AReglas: TArray<TReglaPermiso>;
  ADisponible: Boolean);
var
  Regla: TReglaPermiso;
begin
  inherited Create;
  FIdentidad := AIdentidad;
  FDisponible := ADisponible;
  FPermisos := TDictionary<string, Boolean>.Create;
  for Regla in AReglas do
    FPermisos.AddOrSetValue(
      Clave(Regla.Sujeto, Regla.Codigo),
      Regla.Permitido);
end;

destructor TPermisosAplicacion.Destroy;
begin
  FreeAndNil(FPermisos);
  inherited;
end;

class function TPermisosAplicacion.CrearNoDisponible(
  const AIdentidad: TIdentidadPermisos): IPermisosAplicacion;
var
  Reglas: TArray<TReglaPermiso>;
begin
  SetLength(Reglas, 0);
  Result := TPermisosAplicacion.Create(AIdentidad, Reglas, False);
end;

function TPermisosAplicacion.Clave(
  const ASujeto, ACodigo: string): string;
begin
  Result := LowerCase(Trim(ASujeto)) + '|' +
            LowerCase(Trim(ACodigo));
end;

function TPermisosAplicacion.GetDisponible: Boolean;
begin
  Result := FDisponible;
end;

function TPermisosAplicacion.Buscar(
  const ASujeto, ACodigo: string;
  out APermitido: Boolean): Boolean;
begin
  Result := FPermisos.TryGetValue(
    Clave(ASujeto, ACodigo),
    APermitido);
end;

function TPermisosAplicacion.Evaluar(
  const ACodigo: string;
  APermisoAusente: TPermisoAusente): TResultadoPermiso;
var
  Permitido: Boolean;
begin
  Result.Codigo := Trim(ACodigo);
  Result.Permitido := False;
  Result.Origen := opNoDisponible;
  if FIdentidad.EsAdministrador then
  begin
    Result.Permitido := True;
    Result.Origen := opAdministrador;
  end
  else if FDisponible then
  begin
    if Buscar(FIdentidad.Usuario, ACodigo, Permitido) then
    begin
      Result.Permitido := Permitido;
      Result.Origen := opUsuario;
    end
    else if Buscar(FIdentidad.Grupo, ACodigo, Permitido) then
    begin
      Result.Permitido := Permitido;
      Result.Origen := opGrupo;
    end
    else if (APermisoAusente <> paExigirConcesion) and
            Buscar('Todos', ACodigo, Permitido) then
    begin
      Result.Permitido := Permitido;
      Result.Origen := opTodos;
    end
    else
    begin
      Result.Permitido := APermisoAusente = paPermitir;
      Result.Origen := opNoDefinido;
    end;
  end;
end;

function TPermisosAplicacion.TienePermiso(
  const ACodigo: string;
  APermisoAusente: TPermisoAusente): Boolean;
begin
  Result := Evaluar(ACodigo, APermisoAusente).Permitido;
end;

end.
