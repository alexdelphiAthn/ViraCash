{******************************************************************************}
{                                                                             }
{  Módulo: inLibMsgCambioCodigoCliente                                        }
{  Tipo: Mensajes                                                             }
{  Versión: 1.0.0                                                             }
{  Fecha: 14/11/2026                                                          }
{  Autor: Alejandro Laorden Hidalgo                                           }
{                                                                             }
{  Copyright (c) Alejandro Laorden Hidalgo.                                   }
{  Descripción:                                                               }
{  Textos de cambio de código y coincidencias de clientes.                    }
{                                                                             }
{******************************************************************************}
unit inLibMsgCambioCodigoCliente;

interface

resourcestring
  SCambioClienteTitulo = 'Cambio de código de cliente';
  SCambioClienteOrigen = 'Código actual del cliente';
  SCambioClienteDestino = 'Código nuevo';
  SCambioClienteCambiar = 'Cambiar código';
  SCambioClienteDuplicados = 'Detectar duplicados';
  SCambioClienteCerrar = 'Cerrar';
  SCambioClienteExplicacion =
    'El cambio conserva la ficha y actualiza sus referencias. ' +
    'El código nuevo debe estar libre. Para detectar duplicados de todos ' +
    'los clientes, deje vacío el código actual.';
  SCambioClientePregunta =
    '¿Cambiar el código de cliente "%s" por "%s"?' + #13#10#13#10 +
    'Se actualizarán las referencias de sus documentos. Los nombres, NIF ' +
    'e importes guardados en ellos se conservarán.' + #13#10#13#10 +
    'Realice el cambio sin otros usuarios trabajando y reinicie las ' +
    'demás sesiones al terminar.';
  SCambioClienteCorrecto =
    'Código cambiado. Referencias actualizadas: %d.';
  SCambioClienteDatosInvalidos =
    'Indique dos códigos distintos de entre 1 y 20 caracteres. ' +
    'El código 0 está reservado para caja y no se puede recodificar.';
  SCambioClienteNoExiste = 'El código actual no corresponde a un cliente.';
  SCambioClienteOcupado =
    'El código nuevo ya existe o tiene referencias. Elija otro código. ' +
    'No se han fusionado ni modificado las fichas.';
  SCambioClienteEsquema =
    'La base contiene referencias de cliente no compatibles con esta ' +
    'utilidad. No se ha realizado ningún cambio.';
  SCambioClienteTransaccion =
    'Hay una operación pendiente en la conexión. Termine esa operación ' +
    'antes de cambiar el código.';
  SCambioClienteCerrarPantallas =
    'Cierre las pantallas de trabajo antes de cambiar códigos de cliente.';
  SCambioClienteSinDuplicados = 'No se han encontrado coincidencias.';
  SCambioClienteResumenDuplicados =
    'Coincidencias: %d. Son posibles duplicados; no se ha modificado nada.';
  SCambioClienteLimiteDuplicados =
    'Se muestran las primeras %d coincidencias. Indique un código para ' +
    'acotar la búsqueda.';
  SCambioClienteCodigo = 'Código';
  SCambioClienteNombre = 'Cliente';
  SCambioClienteOtroCodigo = 'Otro código';
  SCambioClienteOtroNombre = 'Otra ficha';
  SCambioClienteMotivo = 'Coincidencia';
  SCambioClienteNif = 'NIF';
  SCambioClienteContacto = 'Teléfono, móvil o correo';
  SCambioClienteAmbos = 'NIF y contacto';

implementation

end.
