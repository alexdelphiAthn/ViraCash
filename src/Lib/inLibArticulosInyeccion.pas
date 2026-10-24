{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosInyeccion                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contexto de capacidades obligatorias para la pantalla de artículos.       }
{******************************************************************************}
unit inLibArticulosInyeccion;

interface

uses
  inLibArticulosGuardadoIntf,
  inLibArticulosPropiedadesPersistenciaIntf,
  inLibArticulosVariacionesIntf,
  inLibGeneracionSkusPersistenciaIntf,
  inLibMargenPersistenciaIntf;

type
  ICreadorGuardadoArticulo = interface
    ['{C64D9A4E-8AB3-4D49-A0BF-D5B52CFCB1DA}']
    function Crear(
      const AOperaciones: IOperacionesGuardadoArticulo
    ): IAplicacionGuardadoArticulo;
  end;

  TContextoDependenciasArticulos = record
    Guardado: ICreadorGuardadoArticulo;
    Propiedades: TServiciosPropiedadesArticulo;
    Variaciones: IArticulosVariaciones;
    Margen: IRepositorioMargen;
    GeneracionSkus: IRepositorioGeneracionSkus;
    class function Crear(
      const AGuardado: ICreadorGuardadoArticulo;
      const APropiedades: TServiciosPropiedadesArticulo;
      const AVariaciones: IArticulosVariaciones
    ): TContextoDependenciasArticulos; overload; static;
    class function Crear(
      const AGuardado: ICreadorGuardadoArticulo;
      const APropiedades: TServiciosPropiedadesArticulo;
      const AVariaciones: IArticulosVariaciones;
      const AMargen: IRepositorioMargen
    ): TContextoDependenciasArticulos; overload; static;
    class function Crear(
      const AGuardado: ICreadorGuardadoArticulo;
      const APropiedades: TServiciosPropiedadesArticulo;
      const AVariaciones: IArticulosVariaciones;
      const AMargen: IRepositorioMargen;
      const AGeneracionSkus: IRepositorioGeneracionSkus
    ): TContextoDependenciasArticulos; overload; static;
    function CrearGuardado(
      const AOperaciones: IOperacionesGuardadoArticulo
    ): IAplicacionGuardadoArticulo;
    procedure Validar;
    procedure Liberar;
  end;

function CrearCreadorGuardadoArticulo: ICreadorGuardadoArticulo;

implementation

uses
  System.SysUtils,
  inLibArticulosGuardado;

resourcestring
  SErrorGuardadoArticuloNoDisponible =
    'No se proporcionó la capacidad de guardado de artículos.';
  SErrorAplicacionGuardadoArticuloNoDisponible =
    'La capacidad de guardado no creó la aplicación de artículos.';
  SErrorLecturaPropiedadesArticuloNoDisponible =
    'No se proporcionó la lectura de propiedades de artículos.';
  SErrorEscrituraPropiedadesArticuloNoDisponible =
    'No se proporcionó la escritura de propiedades de artículos.';
  SErrorVariacionesArticuloNoDisponibles =
    'No se proporcionó la capacidad de variaciones de artículos.';

type
  TCreadorGuardadoArticulo = class(
    TInterfacedObject,
    ICreadorGuardadoArticulo)
  public
    function Crear(
      const AOperaciones: IOperacionesGuardadoArticulo
    ): IAplicacionGuardadoArticulo;
  end;

function TCreadorGuardadoArticulo.Crear(
  const AOperaciones: IOperacionesGuardadoArticulo
): IAplicacionGuardadoArticulo;
begin
  if not Assigned(AOperaciones) then
    raise EArgumentNilException.Create('AOperaciones');
  Result := CrearAplicacionGuardadoArticulo(AOperaciones);
end;

class function TContextoDependenciasArticulos.Crear(
  const AGuardado: ICreadorGuardadoArticulo;
  const APropiedades: TServiciosPropiedadesArticulo;
  const AVariaciones: IArticulosVariaciones
): TContextoDependenciasArticulos;
begin
  Result := Default(TContextoDependenciasArticulos);
  Result.Guardado := AGuardado;
  Result.Propiedades := APropiedades;
  Result.Variaciones := AVariaciones;
  Result.Validar;
end;

class function TContextoDependenciasArticulos.Crear(
  const AGuardado: ICreadorGuardadoArticulo;
  const APropiedades: TServiciosPropiedadesArticulo;
  const AVariaciones: IArticulosVariaciones;
  const AMargen: IRepositorioMargen
): TContextoDependenciasArticulos;
begin
  Result := Crear(AGuardado, APropiedades, AVariaciones);
  Result.Margen := AMargen;
end;

class function TContextoDependenciasArticulos.Crear(
  const AGuardado: ICreadorGuardadoArticulo;
  const APropiedades: TServiciosPropiedadesArticulo;
  const AVariaciones: IArticulosVariaciones;
  const AMargen: IRepositorioMargen;
  const AGeneracionSkus: IRepositorioGeneracionSkus
): TContextoDependenciasArticulos;
begin
  Result := Crear(AGuardado, APropiedades, AVariaciones, AMargen);
  Result.GeneracionSkus := AGeneracionSkus;
end;

procedure TContextoDependenciasArticulos.Validar;
begin
  if not Assigned(Guardado) then
    raise EArgumentNilException.Create(SErrorGuardadoArticuloNoDisponible);
  if not Assigned(Propiedades.Lectura) then
  begin
    raise EArgumentNilException.Create(
      SErrorLecturaPropiedadesArticuloNoDisponible);
  end;
  if not Assigned(Propiedades.Escritura) then
  begin
    raise EArgumentNilException.Create(
      SErrorEscrituraPropiedadesArticuloNoDisponible);
  end;
  if not Assigned(Variaciones) then
  begin
    raise EArgumentNilException.Create(
      SErrorVariacionesArticuloNoDisponibles);
  end;
end;

function TContextoDependenciasArticulos.CrearGuardado(
  const AOperaciones: IOperacionesGuardadoArticulo
): IAplicacionGuardadoArticulo;
begin
  Validar;
  Result := Guardado.Crear(AOperaciones);
  if not Assigned(Result) then
  begin
    raise EInvalidOpException.Create(
      SErrorAplicacionGuardadoArticuloNoDisponible);
  end;
end;

procedure TContextoDependenciasArticulos.Liberar;
begin
  Guardado := nil;
  Propiedades.Lectura := nil;
  Propiedades.Escritura := nil;
  Variaciones := nil;
  Margen := nil;
  GeneracionSkus := nil;
end;

function CrearCreadorGuardadoArticulo: ICreadorGuardadoArticulo;
begin
  Result := TCreadorGuardadoArticulo.Create;
end;

end.
