{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPermisosUniDAC                                           }
{    Tipo:       Librería                                                      }
{ Versión:       2.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construye permisos desde reglas obtenidas mediante un contrato estrecho. }
{******************************************************************************}
unit inLibPermisosUniDAC;

interface

uses
  System.SysUtils,
  inLibPermisosIntf, inLibPermisosPersistenciaIntf;

type
  EErrorCargaPermisos = class(Exception)
  private
    FError: TErrorLecturaPermisos;
  public
    constructor Create(AError: TErrorLecturaPermisos;
      const ADetalle: string);
    property Error: TErrorLecturaPermisos read FError;
  end;

  TCargadorPermisosUniDAC = class
  public
    class function Cargar(
      const ARepositorio: IRepositorioPermisos;
      const AIdentidad: TIdentidadPermisos
    ): IPermisosAplicacion;
  end;

implementation

uses
  System.Generics.Collections,
  inLibPermisos;

constructor EErrorCargaPermisos.Create(
  AError: TErrorLecturaPermisos; const ADetalle: string);
begin
  inherited Create(ADetalle);
  FError := AError;
end;

class function TCargadorPermisosUniDAC.Cargar(
  const ARepositorio: IRepositorioPermisos;
  const AIdentidad: TIdentidadPermisos): IPermisosAplicacion;
var
  i: Integer;
  oReglas: TList<TReglaPermiso>;
  oResultado: TResultadoLecturaPermisos;
begin
  if not Assigned(ARepositorio) then
  begin
    raise EErrorCargaPermisos.Create(
      elpConexionNoDisponible,
      'No se ha configurado el repositorio de permisos.');
  end;
  oResultado := ARepositorio.CargarReglas(AIdentidad);
  if not oResultado.Exito then
  begin
    raise EErrorCargaPermisos.Create(
      oResultado.Error, oResultado.Detalle);
  end;
  oReglas := TList<TReglaPermiso>.Create;
  try
    for i := 0 to Length(oResultado.Reglas) - 1 do
    begin
      oReglas.Add(TReglaPermiso.Crear(
        oResultado.Reglas[i].Sujeto,
        oResultado.Reglas[i].Codigo,
        oResultado.Reglas[i].Permitido));
    end;
    Result := TPermisosAplicacion.Create(
      AIdentidad,
      oReglas.ToArray,
      True);
  finally
    FreeAndNil(oReglas);
  end;
end;

end.
