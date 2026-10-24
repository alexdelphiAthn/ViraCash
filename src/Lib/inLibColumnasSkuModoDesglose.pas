{******************************************************************************}
{                                                                              }
{  Modulo:       inLibColumnasSkuModoDesglose                                  }
{    Tipo:       Libreria                                                      }
{ Version:       0.1.0                                                         }
{   Fecha:       05/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    PRUEBA ColumnSKUcxGrid: implementacion de IModoEntradaGrid en modo        }
{    desglose (columna articulo + columnas color / talla).                     }
{                                                                              }
{    Es un ADAPTADOR: delega toda la operativa en TGridArticulosLineas         }
{    (inLibGridArticulos), el desarrollo ya en produccion en caja y            }
{    traspasos (busqueda incremental, lector, paleta de swatches,              }
{    autocompletado de atributos unicos). Aqui solo se traduce el contrato     }
{    IModoEntradaGrid a su API y se reexpone el evento OnResuelto.             }
{******************************************************************************}
unit inLibColumnasSkuModoDesglose;

interface

uses
  System.SysUtils, System.Classes,
  inLibColumnasSkuIntf, inLibGridArticulos;

type
  TModoEntradaDesglose = class(TInterfacedObject, IModoEntradaGrid,
    ILecturaModoEntrada)
  private
    FConfig: TConfigColumnasSku;
    FGrid: TGridArticulosLineas;
    FOnResuelto: TSkuResueltoEvent;
    // Reenvia el aviso de TGridArticulosLineas al documento.
    procedure GridResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
  public
    constructor Create(const AConfig: TConfigColumnasSku;
      AGrid: TGridArticulosLineas);
    destructor Destroy; override;
    procedure Construir(
      AOnResuelto: TSkuResueltoEvent;
      AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
    procedure Desmontar;
    procedure MostrarEditor;
    function ResolverEntrada(const AEntrada: string): Boolean;
    function ResolverLectura(const AEntrada: string): Boolean;
  end;

implementation

constructor TModoEntradaDesglose.Create(
  const AConfig: TConfigColumnasSku; AGrid: TGridArticulosLineas);
begin
  inherited Create;
  FConfig := AConfig;
  if not Assigned(AGrid) then
    raise EArgumentNilException.Create('AGrid');
  FGrid := AGrid;
  FGrid.OnResuelto := GridResuelto;
  FGrid.AlmacenStock := AConfig.AlmacenStock;
  FGrid.AceptarNoCatalogo := AConfig.AceptarNoCatalogo;
  FGrid.OnLoteLeido := AConfig.OnLoteLeido;
  FGrid.DesplazamientoHorizontal := AConfig.DesplazamientoHorizontal;
end;

destructor TModoEntradaDesglose.Destroy;
begin
  FreeAndNil(FGrid);
  inherited;
end;

procedure TModoEntradaDesglose.GridResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  if Assigned(FOnResuelto) then
    FOnResuelto(ACodArt, ASku, ADescripcion, ACompleto);
end;

procedure TModoEntradaDesglose.Construir(
  AOnResuelto: TSkuResueltoEvent;
  AOnEntrarEdicion, AOnSalirEdicion: TNotifyEvent);
begin
  FOnResuelto := AOnResuelto;
  FGrid.OnEntrarEdicion := AOnEntrarEdicion;
  FGrid.OnSalirEdicion := AOnSalirEdicion;
  FGrid.Construir;
end;

procedure TModoEntradaDesglose.Desmontar;
begin
  // Las lineas del cds ya llevan su SKU y cantidad. Solo hay que soltar
  // eventos y editores antes de que el host destruya las columnas.
  if Assigned(FGrid) then
    FGrid.Desmontar;
end;

procedure TModoEntradaDesglose.MostrarEditor;
begin
  FGrid.MostrarEditorArticulo;
end;

function TModoEntradaDesglose.ResolverEntrada(
  const AEntrada: string): Boolean;
begin
  Result := FGrid.ResolverEntrada(AEntrada);
end;

function TModoEntradaDesglose.ResolverLectura(
  const AEntrada: string): Boolean;
begin
  Result := FGrid.ResolverLectura(AEntrada);
end;

end.
