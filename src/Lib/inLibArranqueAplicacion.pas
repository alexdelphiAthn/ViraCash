{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArranqueAplicacion                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina las fases de arranque principal y preparación del logon.        }
{******************************************************************************}
unit inLibArranqueAplicacion;

interface

uses
  inLibContextoSesionIntf,
  inLibLicenciaAplicacion;

type
  IPasosArranqueAplicacion = interface
    ['{D16F4F64-425D-4C2B-B61A-7D77292CE073}']
    procedure PrepararContextoAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      out AIdentidad: TIdentidadSesion;
      out AUbicacion: TUbicacionSesion);
    procedure MostrarSplashInicio;
    procedure CrearInfraestructuraAplicacion;
    procedure CargarServiciosAplicacion(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure ActivarAplicacion;
    procedure PresentarAplicacion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure FinalizarArranqueAplicacion;
  end;
  ICasoUsoArranqueAplicacion = interface
    ['{7B63D33A-1BE1-49A1-9018-60F798E21B9D}']
    procedure Ejecutar(
      const AContextoSesion: IContextoSesionAplicacion;
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
  end;
  IPasosPreparacionLogon = interface
    ['{8349B08E-53F2-46E4-945D-9F3583A06BA7}']
    procedure PrepararLogon;
    function ConectarServidorLogon: Boolean;
    function ValidarEstructuraLogon: Boolean;
    function ConectarAplicacionLogon: Boolean;
    function PrepararLicenciaLogon: Boolean;
    procedure PrepararNuevoEquipo;
  end;
  ICasoUsoPreparacionLogon = interface
    ['{EF902D59-64C5-4300-A6CC-A19AF264DBB7}']
    procedure Ejecutar;
  end;

function CrearCasoUsoArranqueAplicacion(
  const APasos: IPasosArranqueAplicacion):
  ICasoUsoArranqueAplicacion;
function CrearCasoUsoPreparacionLogon(
  const APasos: IPasosPreparacionLogon):
  ICasoUsoPreparacionLogon;

implementation

uses
  System.SysUtils;

type
  TCasoUsoArranqueAplicacion = class(
    TInterfacedObject,
    ICasoUsoArranqueAplicacion)
  private
    FPasos: IPasosArranqueAplicacion;
  public
    constructor Create(const APasos: IPasosArranqueAplicacion);
    procedure Ejecutar(
      const AContextoSesion: IContextoSesionAplicacion;
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
  end;
  TCasoUsoPreparacionLogon = class(
    TInterfacedObject,
    ICasoUsoPreparacionLogon)
  private
    FPasos: IPasosPreparacionLogon;
  public
    constructor Create(const APasos: IPasosPreparacionLogon);
    procedure Ejecutar;
  end;

constructor TCasoUsoArranqueAplicacion.Create(
  const APasos: IPasosArranqueAplicacion);
begin
  if not Assigned(APasos) then
    raise EArgumentNilException.Create('APasos');
  inherited Create;
  FPasos := APasos;
end;

procedure TCasoUsoArranqueAplicacion.Ejecutar(
  const AContextoSesion: IContextoSesionAplicacion;
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
var
  Identidad: TIdentidadSesion;
  Ubicacion: TUbicacionSesion;
begin
  FPasos.PrepararContextoAplicacion(
    AContextoSesion, Identidad, Ubicacion);
  FPasos.MostrarSplashInicio;
  FPasos.CrearInfraestructuraAplicacion;
  FPasos.CargarServiciosAplicacion(AResultadoLicencia);
  FPasos.ActivarAplicacion;
  FPasos.PresentarAplicacion(Identidad, Ubicacion);
  FPasos.FinalizarArranqueAplicacion;
end;

constructor TCasoUsoPreparacionLogon.Create(
  const APasos: IPasosPreparacionLogon);
begin
  if not Assigned(APasos) then
    raise EArgumentNilException.Create('APasos');
  inherited Create;
  FPasos := APasos;
end;

procedure TCasoUsoPreparacionLogon.Ejecutar;
var
  Continuar: Boolean;
begin
  FPasos.PrepararLogon;
  Continuar := FPasos.ConectarServidorLogon;
  if Continuar then
    Continuar := FPasos.ValidarEstructuraLogon;
  if Continuar then
    Continuar := FPasos.ConectarAplicacionLogon;
  if Continuar then
    Continuar := FPasos.PrepararLicenciaLogon;
  if Continuar then
    FPasos.PrepararNuevoEquipo;
end;

function CrearCasoUsoArranqueAplicacion(
  const APasos: IPasosArranqueAplicacion):
  ICasoUsoArranqueAplicacion;
begin
  Result := TCasoUsoArranqueAplicacion.Create(APasos);
end;

function CrearCasoUsoPreparacionLogon(
  const APasos: IPasosPreparacionLogon):
  ICasoUsoPreparacionLogon;
begin
  Result := TCasoUsoPreparacionLogon.Create(APasos);
end;

end.
