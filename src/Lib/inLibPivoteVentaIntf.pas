{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteVentaIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de persistencia del pivote de venta (fascículo V2 del anexo        }
{    SRP). Devuelve records de SKU, atributos y conjuntos; no cruza            }
{    TDataSet, TUniQuery ni TUniConnection. La implementación UniDAC vive      }
{    en UniDataPivoteVenta.                                                    }
{******************************************************************************}
unit inLibPivoteVentaIntf;
interface
uses
  System.SysUtils;
type
  // FZ-ISSUE-413: el SKU que habría que dar de alta ya existe y está de
  // baja. El mensaje es el código del SKU.
  ESkuDeBajaPivoteVenta = class(Exception);
  // Atributos de variación de un SKU: color (id y textos) y talla.
  TInfoSkuPivoteVenta = record
    Encontrado : Boolean;
    ColorAv    : Integer;
    TallaAv    : Integer;
    ColorTexto : string;
    ColorCodigo: string;
    VarSku     : string;
    // Copa (eje de pestañas) del SKU; '' con «Tallas y colores».
    PestanaTexto: string;
  end;
  // Posición (id de talla, valor visible) dentro de un conjunto pivot.
  TValorTallaPivoteVenta = record
    IdAv : Integer;
    Valor: string;
  end;
  TValoresTallaPivoteVenta = TArray<TValorTallaPivoteVenta>;
  // Lecturas que necesita el modelo para agrupar y resolver lineas.
  IRepositorioModeloPivoteVenta = interface
    ['{8E99E961-92C5-42DA-ABCF-DA83B89E6EF2}']
    function ObtenerInfoSku(const ACodigoSku: string)
                            : TInfoSkuPivoteVenta;
    function ResolverSkuDesdeCodigoBarras(
      const ACodigoBarras: string): string;
    // SKU único activo del artículo; '' si tiene cero o varios.
    function ResolverSkuUnicoArticulo(
      const ACodigoArticulo: string): string;
    // Sistema asignado al articulo. Sin asignacion, busca uno que cubra
    // las tallas del documento; devuelve 0 si no encuentra ninguno.
    function ResolverConjuntoArticulo(const AArticulo: string;
      const AIdsTalla: TArray<Integer>): Integer;
    // Posiciones ordenadas (ORDEN_ACD) de un conjunto real.
    function PosicionesConjunto(AIdAc: Integer)
                                : TValoresTallaPivoteVenta;
    // Tallas presentes en los SKUs del artículo, por ORDEN_AV.
    function TallasDeArticulo(const ACodigoArticulo: string)
                              : TValoresTallaPivoteVenta;
    // Valores de talla concretos por id, por ORDEN_AV.
    function TallasPorIds(const AIdsTalla: TArray<Integer>)
                          : TValoresTallaPivoteVenta;
  end;
  // Operaciones que necesita el coordinador al editar una celda.
  IRepositorioEdicionPivoteVenta = interface
    ['{D1E844D7-EFBF-4446-814C-7667D1EE40B7}']
    function DescripcionTalla(AIdAvTalla: Integer): string;
    // SKU activo del artículo con esa talla, ese color (si > 0) y ese
    // valor de pestañas (si > 0). Con varios candidatos de un tipo con
    // pestañas lanza ESkuAmbiguo (inLibResolucionSku).
    function BuscarSkuActivoPorAtributos(
      const ACodigoArticulo: string;
      ATallaAv, AColorAv, APestanaAv: Integer): string;
    // Valor de pestañas (copa) del SKU; 0 si no tiene.
    function IdValorPestanaSku(const ACodigoSku: string): Integer;
    // Alta idempotente del SKU y sus atributos de color, talla y
    // pestañas. Si ese SKU (por código o por esos atributos) ya existe de
    // baja, no lo toca y lanza ESkuDeBajaPivoteVenta. Con un tipo con
    // pestañas exige APestanaAv > 0 (ESkuSinValorPestana).
    procedure CrearSkuConAtributos(const ACodigoSku, ACodigoArticulo,
                                   AVariacionSku: string;
                                   AColorAv, ATallaAv,
                                   APestanaAv: Integer);
    // Abre el buscador de artículos (stock del almacén indicado) y
    // devuelve el artículo elegido; False si el usuario cancela.
    function ElegirArticuloDesdeBusqueda(const AAlmacenStock: string;
                                         out ACodigoArticulo: string)
                                         : Boolean;
  end;

implementation

end.
