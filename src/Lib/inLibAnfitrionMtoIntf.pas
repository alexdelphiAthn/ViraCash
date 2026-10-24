{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAnfitrionMtoIntf                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos mínimos entre los mantenimientos y la aplicación anfitriona.    }
{******************************************************************************}
unit inLibAnfitrionMtoIntf;

interface

uses
  System.SysUtils, Winapi.Messages, Vcl.Menus, inLibUnitForm;

const
  WM_FREECONTROL = WM_USER + 1;

type
  // Un servicio del anfitrion que debia estar no esta disponible. El
  // descubrimiento falla ruidosamente (PLAN_SOLID, Fase 4, patron 5.3).
  EServicioNoDisponible = class(Exception);

  IAnfitrionMantenimiento = interface
    ['{545F7B3D-D158-49C2-BC88-537B85F68A13}']
    function ResolverCallPantalla(const AUnidadClase: string): string;
    function ResolverDataModulePantalla(
      const AUnidadClase: string): string;
    procedure CancelarEdicionesPantallas;
    procedure VincularFotoMantenimiento(AMantenimiento: TObject);
    function CrearCopiaPreviaScriptSoporte: Boolean;
    // Como la anterior, pero devuelve dónde quedó la copia para poder
    // revertir después una actualización.
    function CrearCopiaPreviaActualizacion(
      out ARutaCopia: string): Boolean;
  end;

  IProveedorMenuPantallas = interface
    ['{8B43F995-A4C7-483E-8DEB-34D23A85A90C}']
    function MenuAplicacion: TMainMenu;
    function RegistroPantallas: TfzaWinF;
  end;

// Las pantallas creadas mediante una clase decoradora/inyectada no tienen
// por que figurar en fza_winforms. Se consulta primero la clase concreta y
// despues sus ancestros hasta reutilizar el registro de la pantalla base.
function ResolverCallPantallaPorJerarquia(
  const AAnfitrion: IAnfitrionMantenimiento;
  AClasePantalla: TClass): string;
function ResolverDataModulePantallaPorJerarquia(
  const AAnfitrion: IAnfitrionMantenimiento;
  AClasePantalla: TClass): string;

implementation

function ResolverCallPantallaPorJerarquia(
  const AAnfitrion: IAnfitrionMantenimiento;
  AClasePantalla: TClass): string;
var
  Clase: TClass;
begin
  Result := '';
  if Assigned(AAnfitrion) then
  begin
    Clase := AClasePantalla;
    while Assigned(Clase) and (Result = '') do
    begin
      Result := AAnfitrion.ResolverCallPantalla(
        Clase.UnitName + '.' + Clase.ClassName);
      if Result = '' then
        Clase := Clase.ClassParent;
    end;
  end;
end;

function ResolverDataModulePantallaPorJerarquia(
  const AAnfitrion: IAnfitrionMantenimiento;
  AClasePantalla: TClass): string;
var
  Clase: TClass;
begin
  Result := '';
  if Assigned(AAnfitrion) then
  begin
    Clase := AClasePantalla;
    while Assigned(Clase) and (Result = '') do
    begin
      Result := AAnfitrion.ResolverDataModulePantalla(
        Clase.UnitName + '.' + Clase.ClassName);
      if Result = '' then
        Clase := Clase.ClassParent;
    end;
  end;
end;

end.
