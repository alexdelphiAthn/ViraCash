{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDevolucionesCompraPersistenciaIntf                       }
{    Tipo:       Contratos de persistencia                                     }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos de datos para el mantenimiento de devoluciones de compra.         }
{******************************************************************************}
unit inLibDevolucionesCompraPersistenciaIntf;

interface

uses
  inLibDevolucionesCompraStock;

type
  TColorArticuloDevolucionCompra = record
    Texto: string;
    Codigo: string;
  end;

  TColoresArticuloDevolucionCompra =
    TArray<TColorArticuloDevolucionCompra>;

  TGrupoColorDevolucionCompra = record
    Serie: string;
    Numero: string;
    CodigoArticulo: string;
    IdColor: Integer;
  end;

  IRepositorioDatosDevolucionCompra = interface
    ['{E728E6B9-7564-4D03-BA6A-F9828B48C7D8}']
    function CodigoSkuRepresentanteColor(
      const ACodigoArticulo, AColor: string;
      AIdConjuntoPivot: Integer
    ): string;
    function ListarColoresArticulo(
      const ACodigoArticulo: string
    ): TColoresArticuloDevolucionCompra;
    function ObtenerColorLinea(
      const ASerie, ANumero, ALinea: string;
      out AIdColor: Integer
    ): Boolean;
    function BorrarGrupoColor(
      const AGrupo: TGrupoColorDevolucionCompra
    ): Integer;
    function ResolverConjuntoPivotArticulo(
      const ACodigoArticulo: string
    ): Integer;
    function ModeloProveedorArticulo(
      const ACodigoArticulo, ACodigoProveedor: string
    ): string;
    function EsCodigoArticuloExacto(
      const ACodigo: string
    ): Boolean;
  end;

  TServiciosPersistenciaDevolucionCompra = record
    Datos: IRepositorioDatosDevolucionCompra;
    Stock: IPersistenciaStockDevolucionCompra;
  end;

implementation

end.
