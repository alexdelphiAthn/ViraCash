{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFaseCobroPersistenciaIntf                                }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura para la fase de cobro de caja.                          }
{******************************************************************************}
unit inLibFaseCobroPersistenciaIntf;

interface

uses
  Data.DB;

type
  TSeriesFaseCobro = TArray<string>;

  TSolicitudSeriesFaseCobro = record
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    Subtipo: string;
    Fecha: TDateTime;
  end;

  TResumenNumeracionFaseCobro = record
    Filas: Int64;
    Minimo: Int64;
    Maximo: Int64;
    Longitud: Integer;
    ExistentesNumero: Int64;
  end;

  TClienteFaseCobro = record
    Nombre: string;
    Email: string;
    PermiteDeuda: Boolean;
    EsClienteVarios: Boolean;
    LimiteCredito: Currency;
    DeudaActual: Currency;
  end;

  TValeOrigenFaseCobro = record
    Codigo: string;
    Importe: Currency;
  end;

  // Vales del ticket de origen de una devolución o rectificación (FZ-363)
  TValesOrigenFaseCobro = record
    // Lo pagado con vales en el origen que aún no se ha devuelto en vale
    ImporteCanjeado: Currency;
    CodigoValeCanjeado: string;
    // Vales emitidos por el origen que siguen pendientes de canje
    ValesPendientes: TArray<TValeOrigenFaseCobro>;
  end;

  IResultadoConsultaFaseCobro = interface
    ['{B113484C-65F7-4E4A-9CED-8538A80AF0CD}']
    function DataSet: TDataSet;
  end;

  IRepositorioFaseCobro = interface
    ['{D42F6F1C-8476-483A-9623-FB493B519C9D}']
    function ListarSeries(
      const ASolicitud: TSolicitudSeriesFaseCobro
    ): TSeriesFaseCobro;
    function ObtenerResumenNumeracion(
      const ACodigoEmpresa, ASerie: string;
      ANumero: Int64
    ): TResumenNumeracionFaseCobro;
    function ConsultarFormasPago: IResultadoConsultaFaseCobro;
    function ObtenerCliente(
      const ACodigoCliente: string;
      out ACliente: TClienteFaseCobro
    ): Boolean;
    function ExisteValePendiente(
      const ACodigoVale: string
    ): Boolean;
    function ConsultarValesOrigen(
      const AEmpresa, ASerie, ANumero: string
    ): TValesOrigenFaseCobro;
  end;

implementation

end.
