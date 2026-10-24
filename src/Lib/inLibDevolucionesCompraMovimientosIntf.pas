{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDevolucionesCompraMovimientosIntf                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de los movimientos de almacén de devoluciones de compra.           }
{******************************************************************************}
unit inLibDevolucionesCompraMovimientosIntf;

interface

type
  IMovimientosDevolucionCompra = interface
    ['{5BB360D5-6E2D-4424-BC35-56B61CB1AE29}']
    procedure GenerarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure RevertirDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure SincronizarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string;
      AGenerar: Boolean);
  end;

  IUnidadTrabajoMovimientosDevolucionCompra = interface
    ['{BC2DE26A-1272-4AB1-8556-3BD95C4088F4}']
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

implementation
end.
