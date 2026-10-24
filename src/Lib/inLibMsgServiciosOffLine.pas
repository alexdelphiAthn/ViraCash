{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgServiciosOffLine                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de los servicios off line (copia de seguridad y precios medios).   }
{******************************************************************************}
unit inLibMsgServiciosOffLine;

interface

resourcestring
  STituloServiciosOffLine =
    'Establecer servicios off line';
  SCaptionIntroduccionServiciosOffLine =
    'Deje programados en el servidor los procesos que conviene ejecutar ' +
    'fuera de hora. ViraCash los instala como tareas del Programador de ' +
    'tareas de Windows.';
  SCaptionGrupoCuentaServiciosOffLine =
    ' Cuenta de Windows que ejecutará las tareas ';
  SCaptionUsuarioCuentaServiciosOffLine =
    'Usuario de Windows:';
  SCaptionContrasenaServiciosOffLine =
    'Contraseña:';
  SCaptionGrupoCopiaServiciosOffLine =
    ' Copia de seguridad ';
  SCaptionGrupoPreciosServiciosOffLine =
    ' Cálculo de precios medios ';
  SCaptionInstalarCopiaServiciosOffLine =
    'Dejar programada la copia de seguridad';
  SCaptionInstalarPreciosServiciosOffLine =
    'Dejar programado el cálculo de precios medios';
  SCaptionCarpetaCopiaServiciosOffLine =
    'Carpeta de destino:';
  SCaptionNombreCopiaServiciosOffLine =
    'Nombre del fichero:';
  SCaptionHoraServiciosOffLine =
    'Hora de arranque:';
  SCaptionTokensCopiaServiciosOffLine =
    'El nombre admite DIASEMANA, DIAMES, MES y AÑO, que se sustituyen al ' +
    'crear la copia. La extensión debe ser .crypt: la copia se cifra con ' +
    'la contraseña de la conexión.';
  SCaptionPreciosServiciosOffLine =
    'Procesa la cola de recálculos de stock y precio medio pendientes ' +
    'hasta dejarla vacía.';
  SCaptionUsuarioServiciosOffLine =
    'Las tareas arrancan aunque nadie tenga la sesión iniciada. Con ' +
    'contraseña llegan también a carpetas de red (si la cambia, vuelva ' +
    'a instalarlas); sin ella, ViraCash pedirá permisos de ' +
    'administrador.';
  SCaptionInstalarServiciosOffLine =
    '&Instalar';
  SCaptionCerrarServiciosOffLine =
    '&Cerrar';
  SSolicitudCarpetaCopiaServiciosOffLine =
    'Elija la carpeta donde dejar las copias de seguridad';
  SEstadoServicioOffLineNoInstalado =
    'No instalado.';
  SEstadoServicioOffLineInstalado =
    'Instalado. Próxima ejecución: %s';
  SEstadoServicioOffLineInstaladoSinFecha =
    'Instalado.';
  SEstadoServicioOffLineDesactivado =
    'Instalado, pero desactivado en el Programador de tareas.';
  SEstadoServicioOffLineOtroEjecutable =
    'Ojo: la tarea instalada ejecuta %s';
  SEstadoServicioOffLineConSesion =
    'Ojo: la tarea instalada solo arranca con la sesión iniciada; ' +
    'vuelva a instalarla para que no haga falta.';
  SEstadoServicioOffLineError =
    'No se pudo consultar el Programador de tareas: %s';
  SErrorPerfilServiciosOffLine =
    'No se pudo determinar el perfil .ini de esta sesión.';
  SErrorEjecutableServiciosOffLine =
    'No se encontró el ejecutable de ViraCash.';
  SErrorCarpetaServiciosOffLine =
    'Indique la carpeta de destino de la copia con una ruta completa ' +
    '(unidad o recurso de red).';
  SErrorNombreServiciosOffLine =
    'Indique el nombre del fichero de la copia.';
  SErrorExtensionServiciosOffLine =
    'El nombre del fichero de la copia debe terminar en .crypt.';
  SErrorRutaServiciosOffLine =
    'La ruta de la copia no es válida: revise la carpeta y el nombre.';
  SErrorHoraServiciosOffLine =
    'La hora de arranque no es válida.';
  SErrorUsuarioServiciosOffLine =
    'Indique la cuenta de Windows con la que se ejecutarán las tareas.';
  SPreguntaQuitarServicioOffLine =
    'El servicio «%s» está instalado y lo ha desmarcado.' + sLineBreak +
    sLineBreak + '¿Desea quitarlo del Programador de tareas?';
  SAvisoSinCambiosServiciosOffLine =
    'No hay nada que instalar ni que quitar.';
  SInfoServicioOffLineInstalado =
    'Servicio «%s» instalado: arranca cada día a las %s.';
  SInfoServicioOffLineQuitado =
    'Servicio «%s» quitado del Programador de tareas.';
  SErrorInstalarServicioOffLine =
    'No se pudo instalar «%s»: %s';
  SErrorQuitarServicioOffLine =
    'No se pudo quitar «%s»: %s';
  SErrorPlanServiciosOffLineNoValido =
    'La instancia con permisos de administrador no recibió un plan válido.';
  SErrorElevacionServiciosOffLineSinRespuesta =
    'La instancia con permisos de administrador no devolvió resultado.';
  SErrorElevacionServiciosOffLineRechazada =
    'Se necesitan permisos de administrador para dejar las tareas ' +
    'preparadas sin sesión iniciada.';
  SErrorElevacionServiciosOffLine =
    'No se pudieron instalar los servicios con permisos de ' +
    'administrador: %s';
  SDescripcionTareaCopiaServiciosOffLine =
    'Copia de seguridad cifrada de ViraCash (perfil %s).';
  SDescripcionTareaPreciosServiciosOffLine =
    'Recálculo de stock y precios medios pendientes de ViraCash ' +
    '(perfil %s).';

implementation

end.
