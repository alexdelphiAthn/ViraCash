{******************************************************************************}
{                                                                              }
{  Modulo:       inLibEntradaCambioPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de escritura para registrar una entrada de cambio en caja.         }
{******************************************************************************}
unit inLibEntradaCambioPersistenciaIntf;

interface

type
  TSolicitudEntradaCambio = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    Empleado: string;
    Concepto: string;
    FechaOperacion: TDateTime;
    Importe: Currency;
  end;

  IRepositorioEntradaCambio = interface
    ['{2C447B0D-CBFB-447C-8B9F-AF3104C02A05}']
    function Registrar(
      const ASolicitud: TSolicitudEntradaCambio): string;
  end;

implementation

end.
