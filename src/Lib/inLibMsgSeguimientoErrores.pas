{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgSeguimientoErrores                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos del envío y seguimiento de errores al soporte (FZ-ISSUE-562).      }
{******************************************************************************}
unit inLibMsgSeguimientoErrores;

interface

resourcestring
  SErrorEnvioErrorNoSeleccionado = 'Seleccione un envío de error.';
  SInfoSeguimientoEnvioErrorActualizado =
    'Estado, mensajes y propuestas actualizados.';
  STituloComentarioEnvioError =
    'Comentario para el desarrollador o técnico';
  SErrorComentarioEnvioErrorVacio = 'Escriba un comentario.';
  SInfoComentarioEnvioErrorEnviado =
    'Comentario enviado correctamente.';
  SInfoEnlaceSeguimientoEnvioErrorNoDisponible =
    'Este envío no dispone de un enlace de seguimiento.';
  SInfoScriptSoporteNoPendiente =
    'No hay un script pendiente o aún no se ha sincronizado.';
  SDetalleScriptSoporte =
    'Descripción:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'SHA-256:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Script SQL:' + sLineBreak + '%s';
  SPreguntaEjecutarScriptSoporte =
    '¿Desea crear una copia de seguridad y ejecutar este script?';
  SErrorServicioCopiaSeguridadNoDisponible =
    'No está disponible el servicio de copia de seguridad.';
  SInfoScriptSoporteEjecutado = 'Script ejecutado correctamente.';
  SInfoActualizacionSoporteNoPendiente =
    'No hay una actualización pendiente o aún no se ha sincronizado.';
  SDetalleActualizacionSoporte =
    'Versión: %s' + sLineBreak + 'Descripción:' + sLineBreak + '%s' +
    sLineBreak + sLineBreak + 'Tamaño: %s bytes' + sLineBreak +
    'SHA-256:' + sLineBreak + '%s';
  SPreguntaInstalarActualizacionSoporte =
    '¿Desea instalar esta actualización y reiniciar ViraCash?';
  SInfoConsultandoSeguimientoEnvioError =
    'Consultando mensajes y propuestas del soporte...';
  SInfoSeguimientoEnvioErrorSincronizado =
    'Seguimiento actualizado dentro de ViraCash.';
  SErrorSincronizarSeguimientoEnvioError = 'No se pudo actualizar: %s';
  SInfoComentarioEnvioErrorConversacion =
    'Comentario enviado y conversación actualizada.';
  SErrorConsultaSeguimientoIncidencia =
    'No se pudo consultar la incidencia.';
  SSeguimientoIncidenciaActualizado =
    'Estado actualizado correctamente.';

implementation

end.
