{******************************************************************************}
{                                                                              }
{  Modulo:       inLibMovimientosSkuPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       07/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura de movimientos de almacen asociados a un SKU y de       }
{    reconstruccion global del stock a partir del kardex.                      }
{******************************************************************************}
unit inLibMovimientosSkuPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaMovimientosSku = interface
    ['{8B9E52D3-37C7-4E1A-AFCA-9F58F17BF951}']
    function DataSet: TDataSet;
  end;

  IRepositorioMovimientosSku = interface
    ['{29CD711B-2A4B-49F4-A660-B559D54A4637}']
    function ConsultarMovimientos(
      const ACodigoSku: string): IConsultaMovimientosSku;
    function ReconstruirStock: string;
  end;

implementation

end.
