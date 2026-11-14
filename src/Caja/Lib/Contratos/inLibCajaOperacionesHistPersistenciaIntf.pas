{******************************************************************************}
{                                                                              }
{  Modulo:       inLibCajaOperacionesHistPersistenciaIntf                     }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos del historico de operaciones de caja.                     }
{******************************************************************************}
unit inLibCajaOperacionesHistPersistenciaIntf;

interface

type
  TCadenasCajaOperacionesHist = TArray<string>;

  TRestriccionCajaOperacionesHist = record
    Empresa: string;
    Almacen: string;
    Caja: string;
  end;

  TFiltrosCajaOperacionesHist = record
    Anyos: TCadenasCajaOperacionesHist;
    Almacenes: TCadenasCajaOperacionesHist;
    Restriccion: TRestriccionCajaOperacionesHist;
  end;

  TAlmacenCajaOperacionesHist = record
    Codigo: string;
    Nombre: string;
  end;

  TAlmacenesCajaOperacionesHist = TArray<TAlmacenCajaOperacionesHist>;

  IRepositorioCajaOperacionesHist = interface
    ['{EB9B00ED-AF25-4377-BD73-D6BA971B0FC0}']
    function ListarAnyos: TCadenasCajaOperacionesHist;
    function ListarAlmacenes(
      const ARestriccion: TRestriccionCajaOperacionesHist
    ): TAlmacenesCajaOperacionesHist;
    function PrepararConsulta(
      const AFiltros: TFiltrosCajaOperacionesHist): Boolean;
    function ContarOperaciones(
      const AFiltros: TFiltrosCajaOperacionesHist): Integer;
    procedure AbrirConsulta(AFilasPorBloque: Integer);
  end;

implementation

end.
