{******************************************************************************}
{                                                                              }
{  Modulo:       inLibAbonoDevolucionCompraPersistenciaIntf                    }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       11/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Descripcion:                                                                }
{    FZ-ISSUE-925: borrador del abono (factura rectificativa de compra) de    }
{    una devolucion a proveedor y facturas de origen que puede rectificar.    }
{******************************************************************************}
unit inLibAbonoDevolucionCompraPersistenciaIntf;

interface

type
  TFacturaOrigenAbonoCompra = record
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
    ReferenciaProveedor: string;
    Total: Currency;
  end;

  TFacturasOrigenAbonoCompra = TArray<TFacturaOrigenAbonoCompra>;

  TSolicitudAbonoDevolucionCompra = record
    SerieDevolucion: string;
    NumeroDevolucion: string;
    // Serie y numero del abono; numero vacio = el del contador.
    Serie: string;
    NumeroManual: string;
    Fecha: TDateTime;
    FormaPago: string;
    Almacen: string;
    // Factura de compra que se rectifica; vacia si no se indica.
    SerieOrigen: string;
    NumeroOrigen: string;
    Usuario: string;
  end;

  IRepositorioAbonoDevolucionCompra = interface
    ['{7C1E3A52-9D4B-4F0A-8B61-2E95D3C40F17}']
    // Facturas del proveedor y la empresa que no son abonos ni estan
    // canceladas, de la mas reciente a la mas antigua.
    function ListarFacturasOrigen(
      const AEmpresa, AProveedor: string): TFacturasOrigenAbonoCompra;
    // Crea el borrador y devuelve su serie y numero. Lanza la excepcion
    // de la base si la devolucion no admite abono.
    procedure GenerarAbono(const ASolicitud: TSolicitudAbonoDevolucionCompra;
      out ASerie, ANumero: string);
  end;

implementation

end.
