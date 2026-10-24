{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTraspasoOpePersistenciaIntf                             }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura auxiliar de la operativa de traspasos.                  }
{******************************************************************************}
unit inLibTraspasoOpePersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TAlmacenDestinoTraspaso = record
    Codigo: string;
    Nombre: string;
  end;

  TAlmacenesDestinoTraspaso = TArray<TAlmacenDestinoTraspaso>;

  TFiltroVentasReposicion = record
    Empresa: string;
    AlmacenDestino: string;
    AlmacenOrigen: string;
    Desde: TDateTime;
    Hasta: TDateTime;
  end;

  TLineaVentaReposicion = record
    CodigoArticulo: string;
    Sku: string;
    Descripcion: string;
    CodigoProveedor: string;
    NombreProveedor: string;
    APedir: Double;
    StockDestino: Double;
    StockOrigen: Double;
  end;

  TLineasVentaReposicion = TArray<TLineaVentaReposicion>;

  IRepositorioTraspasoOpe = interface
    ['{63C74CB2-AD1B-47B5-B405-4F750B037DF1}']
    function ListarAlmacenesDestino(
      const AAlmacenPropio: string): TAlmacenesDestinoTraspaso;
    function ListarVentasReposicion(
      const AFiltro: TFiltroVentasReposicion): TLineasVentaReposicion;
  end;

implementation

end.
