{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGastoCajaPersistenciaIntf                               }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de escritura para registrar gastos y retiradas de caja.            }
{******************************************************************************}
unit inLibGastoCajaPersistenciaIntf;

interface

type
  TSolicitudGastoCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    Empleado: string;
    Concepto: string;
    FechaOperacion: TDateTime;
    Importe: Currency;
  end;

  IRepositorioGastoCaja = interface
    ['{132154B3-F321-412A-BF10-BFC2F214AA4A}']
    function Registrar(
      const ASolicitud: TSolicitudGastoCaja): string;
  end;

implementation

end.
