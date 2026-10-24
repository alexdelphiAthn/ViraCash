{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataInventariosInyeccion                                  }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone los adaptadores UniDAC del contexto de Inventarios.               }
{******************************************************************************}
unit UniDataInventariosInyeccion;

interface

uses
  Uni,
  UniDataRepositoriosArticulosPantalla,
  inLibInventariosInyeccion;

function CrearDependenciasInventariosUniDAC(
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection): TDependenciasInventarios;

implementation

uses
  System.SysUtils,
  UniDataColumnasDocumentoRepositorio,
  UniDataColumnasSkuServicios,
  UniDataInventariosBusquedas,
  UniDataInventarioNubeRepositorio;

function CrearDependenciasInventariosUniDAC(
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection): TDependenciasInventarios;
var
  DependenciasArticulos: TDependenciasArticulosInventarios;
begin
  if not Assigned(AArticulos) then
    raise EArgumentNilException.Create('AArticulos');
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  DependenciasArticulos := Default(TDependenciasArticulosInventarios);
  DependenciasArticulos.ResolucionValidacion :=
    AArticulos.CrearValidadorArticulos(AConexion);
  DependenciasArticulos.Atributos :=
    AArticulos.CrearLookupAtributosArticulos(AConexion);
  DependenciasArticulos.AtributosGlobales :=
    CrearColumnasDocumentoLecturas(AConexion);
  DependenciasArticulos.ColumnasSku :=
    CrearServiciosColumnasSkuUniDAC(AConexion);
  Result := TDependenciasInventarios.Crear(
    DependenciasArticulos,
    CrearBusquedasInventarioUniDAC(AConexion),
    CrearRepositorioRecuentoRemotoInventarioUniDAC(AConexion),
    CrearInventarioNubeRepositorio(AConexion),
    AArticulos.CrearServicioCargaMasivaArticulos);
end;

end.
