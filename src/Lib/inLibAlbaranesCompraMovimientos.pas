{******************************************************************************}
{                                                                              }
{  Modulo:       inLibAlbaranesCompraMovimientos                               }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Generacion y reversion de movimientos de almacen para albaranes de        }
{    compra. Centraliza la logica que antes vivia mezclada en la               }
{    materializacion de sesiones para que valga tanto para albaranes que       }
{    nacen de una sesion como para los picados a mano en el Mto.               }
{                                                                              }
{    Fachada sin SQL: el detalle (PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT,          }
{    fuentes lineas/celdas, reversion con recalculo de PMP) vive en            }
{    UniDataAlbaranesCompraMovimientos y se inyecta desde la composición.      }
{******************************************************************************}
unit inLibAlbaranesCompraMovimientos;

interface

uses
  inLibAlbaranesCompraMovimientosIntf;

// Genera movimientos de entrada (TIPO_DOC_MOV='AC', TIPO_MOV='E') para
// todas las celdas con cantidad > 0 del albaran, o para sus lineas
// cuando no haya celdas. AConn debe estar viva; la transaccion la
// gestiona el llamante (este procedimiento no abre ni cierra
// transacciones).
procedure GenerarMovimientosDesdeAlbaranCompra(
  const AMovimientos: IMovimientosAlbaranCompra;
  const ASerieAlbc, ANumAlbc, AUsuario: string);

// Revierte los movimientos creados por GenerarMovimientosDesdeAlbaranCompra.
// Borra fza_movimientos_almacen con TIPO_DOC='AC' + SERIE/NUMERO y
// recalcula el stock/PMP de los SKUs afectados via
// SP_RECALCULAR_PMP_LOTE_ALMACEN para cada (empresa, almacen) tocado.
// Es idempotente: si no hay movimientos, no hace nada.
procedure RevertirMovimientosDesdeAlbaranCompra(
  const AMovimientos: IMovimientosAlbaranCompra;
  const ASerieAlbc, ANumAlbc, AUsuario: string);

implementation

procedure GenerarMovimientosDesdeAlbaranCompra(
  const AMovimientos: IMovimientosAlbaranCompra;
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  AMovimientos.GenerarDesdeAlbaran(
    ASerieAlbc, ANumAlbc, AUsuario);
end;

procedure RevertirMovimientosDesdeAlbaranCompra(
  const AMovimientos: IMovimientosAlbaranCompra;
  const ASerieAlbc, ANumAlbc, AUsuario: string);
begin
  AMovimientos.RevertirDesdeAlbaran(
    ASerieAlbc, ANumAlbc, AUsuario);
end;

end.
