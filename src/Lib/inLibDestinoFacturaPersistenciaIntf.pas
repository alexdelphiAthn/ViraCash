{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDestinoFacturaPersistenciaIntf                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato para resolver la pantalla de destino de una factura.             }
{******************************************************************************}
unit inLibDestinoFacturaPersistenciaIntf;

interface

type
  IResolutorDestinoFactura = interface
    ['{0E068078-77C9-4510-B6D7-F80F31FBD5BE}']
    function Resolver(const ANumero, ASerie: string): string;
  end;

implementation

end.
