{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaCatalogoAltaIntf                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contratos de alta inactiva e idempotente del catálogo PrestaShop.         }
{******************************************************************************}
unit inLibPrestaCatalogoAltaIntf;

interface

uses
  System.SysUtils,
  inLibPrestaCatalogoIntf;

type
  TResultadoAltaPresta = record
    Id: Integer;
    Creado: Boolean;
  end;

  TAltaCategoriaPresta = record
    IdPadre: Integer;
    IdTienda: Integer;
    IdIdioma: Integer;
    Nombre: string;
    Enlace: string;
    Activa: Boolean;
  end;

  TAltaGrupoAtributosPresta = record
    IdTienda: Integer;
    IdIdioma: Integer;
    Nombre: string;
    NombrePublico: string;
    TipoGrupo: string;
    EsColor: Boolean;
  end;

  TAltaValorAtributoPresta = record
    IdGrupo: Integer;
    IdTienda: Integer;
    IdIdioma: Integer;
    Nombre: string;
    Color: string;
  end;

  TAltaProductoPresta = record
    IdCategoriaDefecto: Integer;
    IdGrupoReglasIva: Integer;
    IdTienda: Integer;
    IdIdioma: Integer;
    Referencia: string;
    Nombre: string;
    Enlace: string;
    DescripcionCorta: string;
    Descripcion: string;
    Precio: Double;
    IdsCategorias: TArray<Integer>;
  end;

  TAltaCombinacionPresta = record
    IdProducto: Integer;
    IdTienda: Integer;
    Referencia: string;
    ImpactoPrecio: Double;
    Predeterminada: Boolean;
    CantidadMinima: Integer;
    IdsValores: TArray<Integer>;
  end;

  IClienteCatalogoAltaPresta = interface
    ['{C361A76C-3A69-4946-B2D7-F33DF24CEDC7}']
    function AsegurarCategoria(
      const ADatos: TAltaCategoriaPresta): TResultadoAltaPresta;
    function AsegurarGrupoAtributos(
      const ADatos: TAltaGrupoAtributosPresta): TResultadoAltaPresta;
    function AsegurarValorAtributo(
      const ADatos: TAltaValorAtributoPresta): TResultadoAltaPresta;
    // La implementación fuerza active=0 y este contrato no permite activarlo.
    function AsegurarProductoInactivo(
      const ADatos: TAltaProductoPresta): TResultadoAltaPresta;
    function AsegurarCombinacion(
      const ADatos: TAltaCombinacionPresta): TResultadoAltaPresta;
    // Si el producto ya tiene imagen no sube otra. Permite reanudar la saga
    // tras un fallo sin duplicar la foto en el catálogo.
    function AsegurarImagenProductoSiVacia(
      AIdProducto, AIdTienda: Integer;
      const ARutaImagen: string): Boolean;
  end;

implementation

end.
