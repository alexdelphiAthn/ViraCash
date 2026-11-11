{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFacturacionAlbaranesCompraPersistenciaIntf              }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de persistencia para agrupar albaranes en facturas de compra.     }
{******************************************************************************}
unit inLibFacturacionAlbaranesCompraPersistenciaIntf;

interface

uses
  System.SysUtils, Data.DB, inLibOpcionesDocumentoIntf;

type
  IConsultaFacturacionAlbaranesCompra = interface
    ['{3BED93DD-B9F9-4A34-B0C4-582345954365}']
    function DataSet: TDataSet;
  end;

  TFacturaCompraAbierta = record
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
  end;

  TFacturasCompraAbiertas = TArray<TFacturaCompraAbierta>;

  TResultadoFacturacionAlbaranCompra = record
    Procesado: Boolean;
    SerieFactura: string;
    NumeroFactura: string;
  end;

  IRepositorioFacturacionAlbaranesCompra = interface
    ['{19174795-0A71-4A72-915A-85BF1CB7D971}']
    function ConsultarAlbaranesPendientes(
      const AEmpresa, AProveedor: string
    ): IConsultaFacturacionAlbaranesCompra;
    function ConsultarEmpresas: IConsultaFacturacionAlbaranesCompra;
    function ConsultarProveedores: IConsultaFacturacionAlbaranesCompra;
    function BuscarNombreProveedor(const AProveedor: string): string;
    function ListarFacturasAbiertas(
      const AEmpresa, AProveedor: string): TFacturasCompraAbiertas;
    function FacturarAlbaran(
      const ASerieAlbaran, ANumeroAlbaran, ASerieFactura,
      ANumeroFactura, AUsuario: string
    ): TResultadoFacturacionAlbaranCompra;
    // Como FacturarAlbaran, pero si no hay factura destino crea el
    // borrador con la serie, número, fecha, forma de pago y almacén del
    // diálogo común (número vacío = contador de la serie).
    function FacturarAlbaranConOpciones(
      const ASerieAlbaran, ANumeroAlbaran, ASerieFactura,
      ANumeroFactura: string; const AOpciones: TOpcionesDocumento;
      const AUsuario: string
    ): TResultadoFacturacionAlbaranCompra;
    function BuscarFormaPagoProveedor(const AProveedor: string): string;
    procedure ProponerReferenciaProveedor(
      const ASerie, ANumero, AUsuario: string);
  end;

implementation

end.
