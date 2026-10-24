{******************************************************************************}
{                                                                              }
{  Modulo:       inLibListadoVentasPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para el listado filtrable de ventas.                   }
{******************************************************************************}
unit inLibListadoVentasPersistenciaIntf;

interface

uses
  Data.DB;

type
  TOpcionListadoVentas = record
    Codigo: string;
    Nombre: string;
  end;

  TOpcionesListadoVentas = TArray<TOpcionListadoVentas>;

  TFiltroListadoVentas = record
    FechaDesde: TDateTime;
    FechaHastaExclusiva: TDateTime;
    Familia: string;
    Proveedor: string;
    Temporada: string;
    SoloConsolidadas: Boolean;
  end;

  IConsultaListadoVentas = interface
    ['{9816D9BF-24EA-469B-AA92-68609681230D}']
    function DataSet: TDataSet;
  end;

  IRepositorioListadoVentas = interface
    ['{F52D9903-A8FE-4E02-B287-D9D899851B92}']
    function ListarFamilias: TOpcionesListadoVentas;
    function ListarProveedores: TOpcionesListadoVentas;
    function ListarTemporadas: TOpcionesListadoVentas;
    function ConsultarVentas(
      const AFiltro: TFiltroListadoVentas): IConsultaListadoVentas;
  end;

implementation

end.
