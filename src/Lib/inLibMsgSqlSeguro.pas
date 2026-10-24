{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgSqlSeguro                                            }
{    Tipo:       Librería de mensajes                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Literales traducibles de validación y delimitación segura de SQL.         }
{******************************************************************************}
unit inLibMsgSqlSeguro;

interface

resourcestring
  SErrorDialectoSqlNoAsignado =
    'El dialecto SQL no está configurado.';
  SIdentificadorSqlNoPermitido =
    'El identificador SQL "%s" no pertenece a la lista blanca.';
  SIdentificadorSqlInvalido =
    'El identificador SQL "%s" contiene caracteres no válidos.';

implementation

end.
