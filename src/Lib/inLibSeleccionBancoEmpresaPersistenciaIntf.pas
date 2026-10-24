{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSeleccionBancoEmpresaPersistenciaIntf                   }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para seleccionar cuentas bancarias de una empresa.     }
{******************************************************************************}
unit inLibSeleccionBancoEmpresaPersistenciaIntf;

interface

uses
  Data.DB;

type
  TUsoBancoEmpresa = (
    ubeCobro,
    ubePago
  );

  IConsultaBancosEmpresa = interface
    ['{EB7727D5-2E6E-4DF7-8CF4-37F4E20E79CC}']
    function DataSet: TDataSet;
  end;

  IRepositorioSeleccionBancoEmpresa = interface
    ['{F732D702-AF03-442E-9034-603F9E5EBDBC}']
    function ConsultarCuentas(
      const ACodigoEmpresa: string;
      AUso: TUsoBancoEmpresa): IConsultaBancosEmpresa;
  end;

implementation

end.
