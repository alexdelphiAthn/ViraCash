{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgPersistenciaSubsanacionCaja                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mensajes de validación y guardado de subsanaciones de caja.               }
{******************************************************************************}
unit inLibMsgPersistenciaSubsanacionCaja;

interface

resourcestring
  SSubsanacionSinPermiso =
    'No dispone de permiso para modificar los cobros de caja.';
  SSubsanacionIdentidadInvalida =
    'Seleccione una operación con factura, empresa, almacén y caja.';
  SSubsanacionFacturaNoVigente =
    'Sólo se pueden subsanar tickets emitidos y vigentes de esta operación.';
  SSubsanacionRegistroNoAceptado =
    'El ticket debe tener un registro aceptado en VeriFactu y no tener ' +
    'envíos o anulaciones pendientes.';
  SSubsanacionOperacionCompleja =
    'Esta subsanación admite ventas, también de depósitos y con vales, ' +
    'pero no devoluciones, cancelaciones de depósito, recibos ni ' +
    'facturas relacionadas.';
  SSubsanacionPagoUnico = 'La operación no tiene cobros registrados.';
  SSubsanacionValesFijos =
    'Los vales y la deuda del ticket no se pueden modificar: conserve ' +
    'los mismos importes y códigos.';
  SSubsanacionLineaFija =
    'La línea %s es un abono a cuenta o un anticipo que deja deuda y no ' +
    'se puede corregir.';
  SSubsanacionPrendaBajoAnticipo =
    'La línea %s es una prenda de depósito: su importe no puede ser ' +
    'inferior al anticipo ya entregado (%s).';
  SSubsanacionPagosInvalidos =
    'Indique cobros positivos, con dos decimales como máximo, que sumen ' +
    'el total corregido del ticket.';
  SSubsanacionObservacionPago = 'Subsanación: %s';
  SSubsanacionDescuadreOriginal =
    'Los importes del ticket, sus líneas, la operación y el cobro no ' +
    'coinciden. Revise la operación antes de subsanar.';
  SSubsanacionArqueoCerrado =
    'La operación pertenece a un arqueo cerrado y no se puede subsanar.';
  SSubsanacionDatosFiscales =
    'El ticket requiere revisar sus datos fiscales antes de subsanar ' +
    'los importes de caja.';
  SSubsanacionRegistrada =
    'Subsanación de caja %s\%s guardada (modo %s). Motivo: %s';
  SSubsanacionConflicto =
    'La operación ha cambiado desde que se abrió. Vuelva a cargarla.';
  SSubsanacionMotivoObligatorio =
    'Indique el motivo de la subsanación, con un máximo de 500 caracteres.';
  SSubsanacionMedioInvalido =
    'Seleccione una forma de pago activa; los vales y la deuda no se ' +
    'pueden añadir en una subsanación.';
  SSubsanacionReferenciaInvalida =
    'La forma de pago requiere referencia o supera los 100 caracteres.';
  SSubsanacionSinCambios =
    'No se han modificado los importes ni la forma de pago.';
  SSubsanacionTotalInvalido =
    'El importe corregido de esta venta no puede ser negativo.';
  SSubsanacionTransaccionActiva =
    'Finalice la operación pendiente antes de guardar la subsanación.';
  SSubsanacionEsquemaPendiente =
    'Falta instalar la actualización 20260916_caja_subsanaciones.sql.';
  SSubsanacionCalculoInvalido =
    'No se ha podido cuadrar el importe corregido con los impuestos ' +
    'originales del ticket: %s';
  SSubsanacionTotalFiscalDistinto =
    'el total fiscal no coincide con el importe solicitado';
  SSubsanacionLineaIntactaDistinta =
    'el recálculo cambiaría otra línea que no se ha corregido';
  SSubsanacionCantidadNoAplicada =
    'la cantidad corregida no se ha aplicado a la línea %s';
  SSubsanacionCantidadPrendaDeposito =
    'La línea %s es una prenda de depósito: puede corregir su importe, ' +
    'pero no sus unidades.';
  SSubsanacionStockInconsistente =
    'El movimiento de stock de la línea %s no coincide con sus unidades ' +
    'vendidas. Revise el stock del ticket antes de corregir las unidades.';
  SSubsanacionStockInactivo =
    'El ticket tiene movimientos de stock anulados: no se pueden ' +
    'corregir sus unidades.';
  SSubsanacionMotivoRecalculoStock = 'Subsanación de caja %s\%s';
  SSubsanacionStockRegenerado =
    'Subsanación de caja %s\%s: regenerados %d movimientos de stock.';

implementation

end.
