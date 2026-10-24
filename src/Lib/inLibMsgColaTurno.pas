{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgColaTurno                                             }
{    Tipo:       Recursos de texto                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Textos del turno de proceso de colas.                                     }
{******************************************************************************}
unit inLibMsgColaTurno;

interface

resourcestring
  SErrorNombreTurnoColaNoValido =
    'Nombre de turno de cola no válido: %s';
  SAvisoTurnoColaSinRespuesta =
    'El motor no resolvió el turno de la cola: este puesto la atiende ' +
    'como hasta ahora.';
  SAvisoTurnoColaNoDisponible =
    'No se pudo repartir el turno de la cola (%s): este puesto la ' +
    'atiende como hasta ahora.';
  SAvisoTurnoColaNoLiberado =
    'No se pudo soltar el turno de la cola (%s): el motor lo soltará al ' +
    'cerrar la conexión.';

implementation

end.
