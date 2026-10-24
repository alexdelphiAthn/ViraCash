{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPivoteVentaComposicionIntf                               }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resultado tipado de la composición de repositorios del pivote de venta.   }
{******************************************************************************}
unit inLibPivoteVentaComposicionIntf;
interface
uses
  inLibPivoteVentaIntf;
type
  TRepositoriosPivoteVenta = record
    Modelo: IRepositorioModeloPivoteVenta;
    Edicion: IRepositorioEdicionPivoteVenta;
  end;
implementation
end.
