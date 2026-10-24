{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLotesVisualIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Puerto visual de la trazabilidad (F-LOTEC-010): elegir lotes o series     }
{    para una salida y capturar las series de una entrada de compra. Lo        }
{    implementan los modales inMtoModalSeleccionLote e inMtoModalAltaSeries;   }
{    el lector y las pantallas con líneas dependen solo de este contrato.      }
{******************************************************************************}
unit inLibLotesVisualIntf;

interface

uses
  inLibTrazabilidad;

type
  TParametrosSeleccionLote = record
    CodigoSku: string;
    DescripcionArticulo: string;
    CodigoAlmacen: string;
    // Modo efectivo: LOTE o SERIE.
    Modo: TModoTrazabilidad;
    // Unidades que pide la línea (> 0). En SERIE, cuántas marcar.
    Cantidad: Double;
    // Días de aviso de caducidad ya resueltos (DiasAvisoEfectivos).
    DiasAviso: Integer;
    Hoy: TDate;
    // Caja: existencias netas tras descontar otras líneas del ticket.
    UsarDisponibles: Boolean;
    Disponibles: TLotesDisponibles;
  end;

  TResultadoSeleccionLote = record
    Aceptado: Boolean;
    // Lote y cantidad elegidos, en el orden de salida. En SERIE una
    // asignación de 1 por unidad (N unidades → N líneas de 1).
    Asignaciones: TArray<TAsignacionLote>;
  end;

  TParametrosAltaSeries = record
    CodigoSku: string;
    DescripcionArticulo: string;
    // Unidades de la línea de compra; 0 = las que se lean.
    Cantidad: Integer;
    // Series que ya tiene la propia línea (al volver a abrir el modal).
    SeriesIniciales: TArray<string>;
    // Series de las demás líneas del documento: no se pueden repetir.
    SeriesDocumento: TArray<string>;
  end;

  TResultadoAltaSeries = record
    Aceptado: Boolean;
    Series: TArray<string>;
    // El usuario pide etiquetas por unidad (Code128 con la serie).
    ImprimirEtiquetas: Boolean;
  end;

  ISelectorLotesVisual = interface
    ['{8086EC3C-7E9F-4918-BB24-330B03AB17D5}']
    function SeleccionarLotes(
      const AParametros: TParametrosSeleccionLote): TResultadoSeleccionLote;
    function CapturarSeries(
      const AParametros: TParametrosAltaSeries): TResultadoAltaSeries;
    // Movimientos de un lote o serie (ficha de artículo, F-LOTEC-011).
    procedure MostrarHistorico(const ACodigoSku, ALote: string);
  end;

implementation

end.
