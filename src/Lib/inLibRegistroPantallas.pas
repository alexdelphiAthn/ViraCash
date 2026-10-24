{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRegistroPantallas                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registro compartido de clases de pantallas y data modules. Cada unidad   }
{    registra su propia clase durante la inicialización y la resolución se    }
{    realiza por el nombre cualificado 'Unidad.TClase'. Un nombre incorrecto  }
{    en la BBDD se detecta al arrancar con TfzaWinF.ComprobarRegistradas.      }
{******************************************************************************}
unit inLibRegistroPantallas;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Vcl.Forms;

type
  EFabricaPantallaNoRegistrada = class(Exception);
  TFabricaPantalla = reference to function(
    AOwner: TComponent): TForm;

// Registra una clase de formulario por su QualifiedClassName
// ('inMtoClientes.TfrmMtoClientes'). El identificador lo comprueba el
// compilador: aquí no hay cadenas que puedan divergir del código.
procedure RegistrarPantalla(AClase: TFormClass);

// Registra una clase de data module por su QualifiedClassName
// ('UniDataClientes.TdmClientes').
procedure RegistrarDataModule(AClase: TComponentClass);

// Registra la construcción explícita de una pantalla. La fábrica queda
// asociada a la clase compilada, no a una clave de servicios por nombre.
procedure RegistrarFabricaPantalla(
  AClase: TFormClass;
  const AFabrica: TFabricaPantalla);

// Retira la fábrica y libera cualquier captura de su raíz de composición.
procedure RetirarFabricaPantalla(AClase: TFormClass);

// Indica si la raíz ha configurado la construcción explícita de la clase.
function TieneFabricaPantalla(AClase: TFormClass): Boolean;

// Crea mediante la fábrica registrada. Falla si falta la composición o si
// esta devuelve una clase distinta de la solicitada.
function CrearPantallaInyectada(
  AClase: TFormClass;
  AOwner: TComponent): TForm;

// Clase registrada para el nombre cualificado (UNITF_WINF); nil si no
// hay ninguna. Comparación sin distinguir mayúsculas.
function ClasePantalla(const ANombre: string): TFormClass;

// Clase registrada para el nombre cualificado (DATAMODULE_WINF); nil si
// no hay ninguna.
function ClaseDataModule(const ANombre: string): TComponentClass;

implementation

var
  oPantallas: TDictionary<string, TFormClass>;
  oDataModules: TDictionary<string, TComponentClass>;
  oFabricasPantallas: TDictionary<TFormClass, TFabricaPantalla>;

resourcestring
  SErrorFabricaPantallaNoRegistrada =
    'La pantalla %s no tiene una fábrica de composición registrada.';
  SErrorFabricaPantallaResultadoNulo =
    'La fábrica de la pantalla %s no ha devuelto una instancia.';
  SErrorFabricaPantallaClaseInvalida =
    'La fábrica de %s ha devuelto una pantalla de clase %s.';

procedure RegistrarPantalla(AClase: TFormClass);
begin
  oPantallas.AddOrSetValue(UpperCase(AClase.QualifiedClassName), AClase);
end;

procedure RegistrarDataModule(AClase: TComponentClass);
begin
  oDataModules.AddOrSetValue(UpperCase(AClase.QualifiedClassName), AClase);
end;

procedure RegistrarFabricaPantalla(
  AClase: TFormClass;
  const AFabrica: TFabricaPantalla);
begin
  if not Assigned(AClase) then
    raise EArgumentNilException.Create('AClase');
  if not Assigned(AFabrica) then
    raise EArgumentNilException.Create('AFabrica');
  oFabricasPantallas.AddOrSetValue(AClase, AFabrica);
end;

procedure RetirarFabricaPantalla(AClase: TFormClass);
begin
  if Assigned(AClase) then
    oFabricasPantallas.Remove(AClase);
end;

function TieneFabricaPantalla(AClase: TFormClass): Boolean;
begin
  Result := Assigned(AClase) and
            oFabricasPantallas.ContainsKey(AClase);
end;

function CrearPantallaInyectada(
  AClase: TFormClass;
  AOwner: TComponent): TForm;
var
  Fabrica: TFabricaPantalla;
  sClaseResultado: string;
begin
  Result := nil;
  if not Assigned(AClase) then
    raise EArgumentNilException.Create('AClase');
  if not oFabricasPantallas.TryGetValue(AClase, Fabrica) then
  begin
    raise EFabricaPantallaNoRegistrada.CreateFmt(
      SErrorFabricaPantallaNoRegistrada,
      [AClase.ClassName]);
  end;
  Result := Fabrica(AOwner);
  if not Assigned(Result) then
  begin
    raise EInvalidOpException.CreateFmt(
      SErrorFabricaPantallaResultadoNulo,
      [AClase.ClassName]);
  end;
  if not Result.ClassType.InheritsFrom(AClase) then
  begin
    sClaseResultado := Result.ClassName;
    FreeAndNil(Result);
    raise EInvalidCast.CreateFmt(
      SErrorFabricaPantallaClaseInvalida,
      [AClase.ClassName, sClaseResultado]);
  end;
end;

function ClasePantalla(const ANombre: string): TFormClass;
begin
  if not oPantallas.TryGetValue(UpperCase(Trim(ANombre)), Result) then
    Result := nil;
end;

function ClaseDataModule(const ANombre: string): TComponentClass;
begin
  if not oDataModules.TryGetValue(UpperCase(Trim(ANombre)), Result) then
    Result := nil;
end;

initialization
  oPantallas := TDictionary<string, TFormClass>.Create;
  oDataModules := TDictionary<string, TComponentClass>.Create;
  oFabricasPantallas :=
    TDictionary<TFormClass, TFabricaPantalla>.Create;

finalization
  FreeAndNil(oFabricasPantallas);
  FreeAndNil(oPantallas);
  FreeAndNil(oDataModules);

end.
