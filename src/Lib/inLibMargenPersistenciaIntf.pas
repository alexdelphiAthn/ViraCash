{******************************************************************************}
{                                                                              }
{  Modulo:       inLibMargenPersistenciaIntf                                  }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos para persistir coste y precio de salida calculados.       }
{******************************************************************************}
unit inLibMargenPersistenciaIntf;

interface

type
  TSolicitudPersistenciaMargen = record
    CodigoUnicoTarifa: Integer;
    CodigoArticulo: string;
    CodigoUnidad: string;
    Usuario: string;
    PrecioCoste: Double;
    PrecioSalida: Double;
  end;

  TResultadoPersistenciaMargen = record
    Guardado: Boolean;
    FaltaProveedorPrincipal: Boolean;
    MensajeError: string;
  end;

  // Última compra entre los SKU de una fila de tarifa: coste sin impuestos
  // (0 si no hay compra), su fecha (0 si no hay) y el proveedor del albarán
  // de esa fecha ('' si no se encuentra, p. ej. una factura sin albarán).
  TUltimaCompraTarifa = record
    Coste: Double;
    Fecha: TDateTime;
    Proveedor: string;
  end;

  IRepositorioMargen = interface
    ['{0D5D05A3-71EA-4259-BAEA-97EDE3FEFCD6}']
    function Guardar(
      const ASolicitud: TSolicitudPersistenciaMargen
    ): TResultadoPersistenciaMargen;
    // IVA vigente del grupo por defecto para 'N', 'R', 'S' o 'E'
    // (FZ-ISSUE-315: margen sobre venta de las tarifas con impuestos).
    function PorcentajeIva(const ATipoIva: string): Double;
    // FZ-ISSUE-426: última compra entre los SKU que cubre la fila de
    // tarifa ('' = todo el artículo). Solo se muestra como referencia.
    function UltimaCompra(const ACodigoArticulo,
      ACodigoUnidadTarifa: string): TUltimaCompraTarifa;
  end;

implementation

end.
