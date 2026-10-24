{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSerieFechaFacturaPersistenciaIntf                      }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos del selector de serie y fecha de factura.                 }
{******************************************************************************}
unit inLibSerieFechaFacturaPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaSeriesFactura = interface
    ['{63FB1C4A-B662-45EA-9784-4152555CEB54}']
    function DataSet: TDataSet;
  end;

  IRepositorioSerieFechaFactura = interface
    ['{99FD843E-0215-4C71-A403-33D504CB7B4C}']
    function ConsultarSeries(
      const AEmpresa: string): IConsultaSeriesFactura;
    function ObtenerSerieAlmacen(
      const AEmpresa: string;
      const AAlmacen: string): string;
  end;

implementation

end.
