{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgSql                                                  }
{    Tipo:       Librería de mensajes                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Literales traducibles de dialectos y selección de SQL por motor.          }
{******************************************************************************}
unit inLibMsgSql;

interface

resourcestring
  SErrorTextoSqlVacio =
    'La sentencia SQL no puede estar vacía.';
  SErrorOrdenSqlVacio =
    'Una consulta limitada debe tener una ordenación determinista.';
  SErrorCantidadLimiteSql =
    'La cantidad de filas del límite SQL debe ser mayor que cero.';
  SErrorDesplazamientoSql =
    'El desplazamiento del límite SQL no puede ser negativo.';
  SErrorNombreSqlVacio =
    'El nombre SQL no puede estar vacío.';
  SErrorLongitudRellenoSql =
    'La longitud del relleno SQL debe ser mayor que cero.';
  SErrorAgregacionDistinctSqlNoSoportada =
    'La agregación de texto DISTINCT no está disponible en %s.';
  SErrorVarianteSqlMotorNoDisponible =
    'La operación SQL %s no tiene una variante para %s.';
  SErrorMotorConexionPendiente =
    'El motor %s está previsto por el contrato, pero su adaptador de ' +
    'conexión todavía no está implementado.';

implementation

end.
