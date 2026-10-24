{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBusquedasCompraPersistenciaIntf                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos estrechos para las búsquedas de artículos y SKU de compra. El     }
{    dataset se mantiene vivo únicamente para enlazarlo al buscador VCL.       }
{******************************************************************************}
unit inLibBusquedasCompraPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaBusquedaCompra = interface
    ['{7535F347-57CD-41DE-B05F-63CB57CE5978}']
    function DataSet: TDataSet;
  end;

  IBusquedasCompraPersistencia = interface
    ['{13180370-1D34-4DD8-A8DD-37447837771D}']
    function ConsultarArticulosProveedor(
      const ACodigoProveedor: string): IConsultaBusquedaCompra;
    function ConsultarSkusArticulo(
      const ACodigoArticulo: string): IConsultaBusquedaCompra;
  end;

implementation

end.
