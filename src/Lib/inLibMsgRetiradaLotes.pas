{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgRetiradaLotes                                         }
{    Tipo:       Mensajes                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Textos de las órdenes de retirada de lotes.                   }
{******************************************************************************}
unit inLibMsgRetiradaLotes;

interface

resourcestring
  SBotonHistoricoRetirada = 'Histórico del lote';
  SEmpresaTicketRetirada = 'Empresa: ';
  SEmpleadoTicketRetirada = 'Empleado: ';
  SAlmacenTicketRetirada = 'Almacén: ';
  SLoteTicketRetirada = 'Lote / serie: ';
  SFechaTicketRetirada = 'Fecha límite: ';
  SCantidadTicketRetirada = 'Unidades: ';
  SUbicacionTicketRetirada = 'Ubicación: ';
  SMotivoTicketRetirada = 'Motivo: ';
  SDestinoTicketRetirada = 'Destino TARAS: ';
  SMovimientoTicketRetirada = 'Movimientos: ';
  SOtrosUrgentesTicketRetirada = 'OTROS LOTES URGENTES PENDIENTES';
  SNotaUrgentesTicketRetirada =
    'Stock en origen con fecha de hoy o anterior. Pendiente de retirar.';
  SErrorFormatoTicketRetirada = 'Formato de retirada no reconocido: %s.';
  STituloOrdenRetirada = 'ORDEN DE RETIRADA';
  STituloOrdenRetiradaUrgente = 'ORDEN URGENTE DE RETIRADA';
  SBotonRetirarLotes = 'Retirar lotes';
  SBotonReimprimirRetirada = 'Reimprimir retirada';
  SMotivoCaducidadRetirada = 'Fecha superada';
  SMotivoProximaCaducidadRetirada = 'Próximo a vencer';
  SMotivoAlertaRetirada = 'Alerta de proveedor';
  SMotivoMermaRetirada = 'Merma';
  SMotivoOtroRetirada = 'Otro';
  SEtiquetaMotivoRetirada = 'Motivo';
  SEtiquetaDestinoRetirada = 'Destino';
  SEtiquetaEmpleadoRetirada = 'Empleado';
  SEtiquetaUrgenteRetirada = 'Orden urgente';
  SEtiquetaAlmacenDestinoRetirada = 'Almacén destino';
  SEtiquetaUnidadesRetirada = 'Unidades a retirar';
  SFirmaRetirada = 'Firma: ______________________________';
  SUnidadesRealesRetirada = 'Unidades retiradas: _________________';
  SErrorRetiradaSinLineas = 'Seleccione al menos un lote con existencias.';
  SErrorRetiradaIdentidad = 'Faltan empresa, empleado o usuario.';
  SErrorRetiradaLinea =
    'Lote, SKU, almacén y cantidad positiva obligatorios.';
  SErrorRetiradaDuplicada =
    'El mismo lote y almacén aparece más de una vez.';
  SErrorRetiradaDestino =
    'Seleccione un almacén de taras distinto del origen.';
  SErrorRetiradaStock = 'No hay existencias suficientes de %s, lote %s.';
  SErrorRetiradaAlmacen =
    'El almacén no pertenece a la empresa o no está activo.';
  SErrorRetiradaSinRegistro =
    'No hay una orden de retirada para ese movimiento.';
  SErrorRetiradaConflicto =
    'El identificador ya corresponde a otra retirada.';
  SPreguntaRegistrarRetirada =
    '¿Registrar la retirada y mover las existencias seleccionadas?';
  SPreguntaImprimirRetirada = '¿Imprimir la orden de retirada %s?';
  SInfoRetiradaRegistrada = 'Retirada %s registrada.';
  SErrorRetiradaImpresion =
    'La retirada %s está registrada, pero no se pudo imprimir: %s. ' +
    'Puede reimprimirla desde el histórico del lote.';
  SParametroFormatoRetirada =
    'Formato del ticket de retirada: TEXTO42 (80 mm) o TEXTO32 (58 mm).';

implementation

end.
