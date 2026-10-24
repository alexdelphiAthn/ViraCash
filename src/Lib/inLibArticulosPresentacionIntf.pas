{******************************************************************************}
{                                                                              }
{  Modulo:       inLibArticulosPresentacionIntf                                }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos estrechos que la pantalla de articulos necesita para leer         }
{    catalogos y persistir su precarga. Ninguno conoce VCL ni UniDAC: los      }
{    implementa un adaptador UniData*.                                         }
{******************************************************************************}
unit inLibArticulosPresentacionIntf;

interface

uses
  inLibPerfilesUsuarioIntf, inLibArticulosFiltro;

type
  // Fila de fza_codigos_barras tal como la necesita la verificacion.
  TCodigoBarrasSkuArticulo = record
    Codigo: string;
    Sku: string;
    Tipo: string;
  end;

  TCodigosBarrasArticulo = TArray<TCodigoBarrasSkuArticulo>;

  // Atributos de un SKU que el alta de tarifas agrupa por color.
  TDetalleSkuTarifaArticulo = record
    CodigoSku: string;
    Color: string;
    HexColor: string;
    Talla: string;
  end;
  TDetallesSkuTarifaArticulo = TArray<TDetalleSkuTarifaArticulo>;

  // Fila del selector: artículo, color, SKU o patrón ARTICULO/*/TALLA.
  TOpcionSkuTarifaArticulo = record
    CodigoSku: string;
    Color: string;
    HexColor: string;
    Talla: string;
    EsTalla: Boolean;
  end;
  TOpcionesSkuTarifaArticulo = TArray<TOpcionSkuTarifaArticulo>;

  // Catalogos que alimentan el modal de alta masiva de precios.
  ICatalogoAltaTarifasArticulo = interface
    ['{6B0E9E3A-6D1E-4C4E-9E7B-3C0C2F5A5D11}']
    function ListarSkus(
      const ACodigoArticulo: string): TDetallesSkuTarifaArticulo;
    // Valores de la colección asignada al eje pivote (tallas), en su orden,
    // aunque todavía no tengan SKU (FZ-ISSUE-637).
    function ListarTallasColeccion(
      const ACodigoArticulo: string): TArray<string>;
    function ListarTarifasActivas: TArray<string>;
  end;

  // Lectura de los codigos de barras de todos los SKU de un articulo.
  ILecturaCodigosBarrasArticulo = interface
    ['{2A2D3F41-8C25-4A5F-9B6A-71F0B4E8C622}']
    function ListarCodigosBarras(
      const ACodigoArticulo: string): TCodigosBarrasArticulo;
  end;

  // Consulta maestra del Mto. La pantalla decide QUE filtro aplicar; el
  // adaptador es el unico que toca el SQL del dataset.
  IListaArticulosPantalla = interface
    ['{9F41C7D6-5B78-4E0B-9D3E-4A0E6F7A8B33}']
    procedure AplicarFiltro(const AFiltro: TFiltroArticulos);
  end;

  // Unidad de trabajo de la precarga: la transaccion es del adaptador.
  IEscrituraPrecargaArticulos = interface
    ['{C3B57E08-2D9A-4F16-8E45-6D8B90C1A244}']
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
  end;

implementation

end.
