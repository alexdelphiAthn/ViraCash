{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraRecepcionIntf                               }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto para ejecutar una recepción completa de pedido de compra.          }
{******************************************************************************}
unit inLibPedidosCompraRecepcionIntf;
interface
uses
  inLibGridPivoteCompraTipos;
type
  // Datos del albarán nuevo elegidos en el diálogo común: número vacío =
  // contador; forma de pago vacía = la del pedido.
  TDatosAlbaranCompraNuevo = record
    NumeroManual: string;
    FormaPago: string;
  end;
  TParametrosRecepcionPedidoCompra = record
    SeriePedido: string;
    NumeroPedido: string;
    CodigoAlmacen: string;
    SerieAlbaran: string;
    SerieAlbaranDestino: string;
    NumeroAlbaranDestino: string;
    Usuario: string;
    ReferenciaProveedor: string;
    FechaRecepcion: TDateTime;
    IdPvTemporada: Integer;
    Incorporar: Boolean;
    Celdas: TArray<TCeldaARecibir>;
    AlbaranNuevo: TDatosAlbaranCompraNuevo;
  end;
  TResultadoRecepcionPedidoCompra = record
    SerieAlbaran: string;
    NumeroAlbaran: string;
    Mensaje: string;
    // FZ-ISSUE-930: lo marcado «A recibir» en otros almacenes que no
    // ha entrado en el albarán.
    CantidadMarcadaOtrosAlmacenes: Double;
    AlmacenMarcadoSiguiente: string;
  end;
  IRecepcionPedidoCompra = interface
    ['{15EC0714-1FBD-4D5F-A954-E4367F6285E7}']
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;
implementation
end.
