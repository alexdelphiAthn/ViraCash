{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaStockPersistenciaIntf                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato mínimo de lectura para la política de stock de Caja.             }
{******************************************************************************}
unit inLibCajaStockPersistenciaIntf;

interface

type
  TEstadoSkuCajaStock = record
    Existe: Boolean;
    Activo: Boolean;
  end;
  ICajaStockPersistencia = interface
    ['{DC945339-4063-4B0B-B53F-D9AE6DA3DDD6}']
    function ObtenerEstadoSku(
      const ACodigoSku: string): TEstadoSkuCajaStock;
    function ObtenerCantidadDisponible(
      const ACodigoSku, ACodigoAlmacen: string): Double;
  end;

implementation

end.
