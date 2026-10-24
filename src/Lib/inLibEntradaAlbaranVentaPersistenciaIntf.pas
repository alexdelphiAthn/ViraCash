{******************************************************************************}
{                                                                              }
{  Modulo:       inLibEntradaAlbaranVentaPersistenciaIntf                     }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para la entrada de articulos en albaranes de venta.    }
{******************************************************************************}
unit inLibEntradaAlbaranVentaPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaEntradaAlbaranVenta = interface
    ['{A33891BF-AEB9-449D-8ABA-E3445F0BEDFB}']
    function DataSet: TDataSet;
  end;

  TConfiguracionArticuloAlbaranVenta = record
    EsTrazable: Boolean;
    EsVariacion: Boolean;
    NumeroSkus: Integer;
  end;

  IRepositorioEntradaAlbaranVenta = interface
    ['{C206AC0E-553C-4284-871D-1CF1CEDE7961}']
    function ConsultarArticulos(
      const ATarifa: string;
      AFecha: TDateTime): IConsultaEntradaAlbaranVenta;
    function ConsultarSkus(
      const ACodigoArticulo: string): IConsultaEntradaAlbaranVenta;
    function LeerConfiguracionArticulo(
      const ACodigoArticulo: string): TConfiguracionArticuloAlbaranVenta;
  end;

implementation

end.
