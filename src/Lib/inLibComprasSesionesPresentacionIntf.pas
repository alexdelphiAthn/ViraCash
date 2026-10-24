{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComprasSesionesPresentacionIntf                          }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos de presentacion de la sesion de compra. No conocen VCL,           }
{    formularios, datasets ni UniDAC.                                          }
{******************************************************************************}
unit inLibComprasSesionesPresentacionIntf;

interface

type
  // Ejecuta una accion diferida "una sola vez" tras rearmarla. Es el
  // contrato que sustituye al uso directo de TTimer en el formulario:
  // el nucleo de presentacion decide CUANDO diferir y el adaptador VCL
  // decide COMO (TTimer, cola de mensajes, prueba sincrona).
  IPlanificadorDiferido = interface
    ['{6F0C2C5A-4B32-4C21-9E5D-0A4A7C93F1D2}']
    // Cancela la espera pendiente y vuelve a empezarla desde cero.
    procedure Rearmar;
    // Cancela la espera pendiente sin ejecutar la accion.
    procedure Cancelar;
    // True mientras hay una accion diferida pendiente de ejecutar.
    function Armado: Boolean;
  end;

implementation

end.
