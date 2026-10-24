{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopAltaArticuloIntf                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Instantánea local validada para dar de alta un artículo en PrestaShop.   }
{******************************************************************************}
unit inLibPrestaShopAltaArticuloIntf;

interface

uses
  System.SysUtils;

type
  EAltaArticuloPrestaLocal = class(Exception);

  TConfiguracionAltaArticuloPresta = record
    CodigoEmpresa: string;
    CodigoTarifa: string;
    StockActivo: Boolean;
  end;

  TFamiliaAltaArticuloPresta = record
    Codigo: string;
    CodigoPadre: string;
    Nombre: string;
    Enlace: string;
  end;

  TAtributoAltaArticuloPresta = record
    CodigoGrupo: string;
    NombreGrupo: string;
    NombrePublicoGrupo: string;
    TipoGrupo: string;
    EsColor: Boolean;
    CodigoValor: string;
    NombreValor: string;
    ColorHtml: string;
  end;

  TSkuAltaArticuloPresta = record
    Codigo: string;
    PrecioSinIva: Double;
    ImpactoPrecio: Double;
    Cantidad: Integer;
    Predeterminado: Boolean;
    Atributos: TArray<TAtributoAltaArticuloPresta>;
  end;

  TFotoAltaArticuloPresta = record
    CodigoUnidad: string;
    Nombre: string;
    RutaReal: string;
    Principal: Boolean;
  end;

  TArticuloCompletoAltaPresta = record
    Codigo: string;
    Nombre: string;
    Enlace: string;
    DescripcionCorta: string;
    Descripcion: string;
    TipoIva: string;
    PorcentajeIva: Double;
    PrecioBaseSinIva: Double;
    EsServicio: Boolean;
    TieneVariaciones: Boolean;
    Cantidad: Integer;
    // Familias se entrega siempre ordenado desde la raíz local hasta la hoja.
    Familias: TArray<TFamiliaAltaArticuloPresta>;
    // Los artículos sin variaciones publican Cantidad y no crean combinación.
    Skus: TArray<TSkuAltaArticuloPresta>;
    // La foto general tiene CodigoUnidad vacío y Principal=True.
    Fotos: TArray<TFotoAltaArticuloPresta>;
  end;

  IRepositorioAltaArticuloPresta = interface
    ['{8F093AF4-E690-4B50-9C3C-C2E93E61DCD1}']
    function CargarValidado(
      const ACodigoArticulo, AUsuario, AGrupo: string;
      const AConfiguracion: TConfiguracionAltaArticuloPresta):
      TArticuloCompletoAltaPresta;
  end;

implementation

end.
