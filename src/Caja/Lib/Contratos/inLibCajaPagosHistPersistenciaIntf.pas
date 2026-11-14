{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaPagosHistPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura del historico de pagos de caja.                         }
{******************************************************************************}
unit inLibCajaPagosHistPersistenciaIntf;

interface

type
  TCadenasCajaPagosHist = TArray<string>;

  TFiltrosCajaPagosHist = record
    Anyos: TCadenasCajaPagosHist;
    Empresa: string;
    Almacen: string;
    Caja: string;
  end;

  IRepositorioCajaPagosHist = interface
    ['{2E6C7E8A-7436-4F3E-BF55-D8CD3045AA7A}']
    function ListarAnyos: TCadenasCajaPagosHist;
    procedure PrepararConsulta(
      const AFiltros: TFiltrosCajaPagosHist);
    procedure AbrirConsulta;
  end;

implementation

end.
