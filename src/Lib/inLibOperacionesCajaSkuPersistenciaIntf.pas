{******************************************************************************}
{                                                                              }
{  Modulo:       inLibOperacionesCajaSkuPersistenciaIntf                      }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura de operaciones de caja asociadas a un SKU.             }
{******************************************************************************}
unit inLibOperacionesCajaSkuPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaOperacionesCajaSku = interface
    ['{07DCC17A-D311-4C89-ABD6-23D6E6319367}']
    function DataSet: TDataSet;
  end;

  IRepositorioOperacionesCajaSku = interface
    ['{E7E0BCF4-B33C-4196-857E-C93330921716}']
    function ConsultarOperaciones(
      const ACodigoSku: string): IConsultaOperacionesCajaSku;
  end;

implementation

end.
