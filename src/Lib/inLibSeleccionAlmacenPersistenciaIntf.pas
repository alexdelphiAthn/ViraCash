{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSeleccionAlmacenPersistenciaIntf                       }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos de los selectores de almacen para albaranes.              }
{******************************************************************************}
unit inLibSeleccionAlmacenPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaSeleccionAlmacen = interface
    ['{D856B566-8B5D-4970-BE4D-1E18A742BF73}']
    function DataSet: TDataSet;
  end;

  TSeriesSeleccionAlmacen = TArray<string>;

  IRepositorioSeleccionAlmacen = interface
    ['{9D946942-5B55-4D59-9245-C0C84988C030}']
    function ConsultarAlmacenes: IConsultaSeleccionAlmacen;
    function ConsultarTemporadas: IConsultaSeleccionAlmacen;
    function ConsultarAlbaranesVenta(
      const ANumeroPedido: string;
      const ASeriePedido: string): IConsultaSeleccionAlmacen;
    function ConsultarAlbaranesCompra(
      const ANumeroPedido: string;
      const ASeriePedido: string): IConsultaSeleccionAlmacen;
    function ListarSeries(
      const AEmpresa: string;
      const ATipoDocumento: string): TSeriesSeleccionAlmacen;
    function ObtenerSerieAlmacen(
      const AEmpresa: string;
      const ATipoDocumento: string;
      const AAlmacen: string): string;
  end;

implementation

end.
