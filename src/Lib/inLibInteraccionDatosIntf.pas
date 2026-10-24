{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInteraccionDatosIntf                                     }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Eventos para que la presentación atienda mensajes de la capa de datos.   }
{******************************************************************************}
unit inLibInteraccionDatosIntf;

interface

type
  TSeveridadMensajeDatos = (
    smdInformacion,
    smdAdvertencia,
    smdError
  );

  TNotificarMensajeDatosEvent = procedure(Sender: TObject;
    const AMensaje: string; ASeveridad: TSeveridadMensajeDatos) of object;
  TConfirmarMensajeDatosEvent = function(Sender: TObject;
    const AMensaje: string): Boolean of object;

implementation

end.
