{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColaTurnoIntf                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       19/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato del turno de proceso de una cola: reparte entre los puestos el   }
{    derecho a vaciarla para que solo uno la atienda a la vez.                 }
{******************************************************************************}
unit inLibColaTurnoIntf;

interface

type
  { Turno de proceso de una cola.
    Intentar devuelve False cuando otro puesto la está atendiendo: ese ciclo
    se salta sin trabajo y sin error. Quien lo obtiene lo suelta al terminar,
    y conviene hacerlo en un finally. }
  ITurnoCola = interface
    ['{2B936F2B-E644-49D8-9321-DB68A4BA300B}']
    function Intentar: Boolean;
    procedure Liberar;
  end;

implementation

end.
