{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAlbaranesCompraMovimientosIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de los movimientos de almacén de albaranes de compra.              }
{******************************************************************************}
unit inLibAlbaranesCompraMovimientosIntf;

interface

type
  IMovimientosAlbaranCompra = interface
    ['{35493A2B-EDAC-40C3-9F26-1E9F5BA677D3}']
    procedure GenerarDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
    procedure RevertirDesdeAlbaran(
      const ASerieAlbc, ANumAlbc, AUsuario: string);
  end;
implementation
end.
