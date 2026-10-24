{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRetiradaLotesIntf                                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Órdenes de retirada y su persistencia transaccional.          }
{******************************************************************************}
unit inLibRetiradaLotesIntf;

interface

const
  PARAMETRO_FORMATO_RETIRADA_LOTES = 'vgerFormatoRetiradaLotes';

type
  TMotivoRetiradaLote = (mrlCaducidad, mrlProximaCaducidad,
    mrlAlerta, mrlMerma, mrlOtro);

  TLineaRetiradaLote = record
    CodigoArticulo: string;
    CodigoSku: string;
    Descripcion: string;
    Lote: string;
    FechaCaducidad: TDateTime;
    Cantidad: Double;
    CodigoAlmacen: string;
    Ubicacion: string;
    NumeroMovimiento: string;
    NumeroMovimientoDestino: string;
  end;

  TOrdenRetiradaLotes = record
    Id: string;
    Instante: TDateTime;
    EsUrgente: Boolean;
    Empresa: string;
    Empleado: string;
    Usuario: string;
    Motivo: TMotivoRetiradaLote;
    AlmacenDestino: string;
    Lineas: TArray<TLineaRetiradaLote>;
    Urgentes: TArray<TLineaRetiradaLote>;
  end;

  TAlmacenRetiradaLotes = record
    Codigo: string;
    Nombre: string;
  end;

  IRepositorioRetiradaLotes = interface
    ['{8DD6F8B7-6D32-46A1-8927-82F1D6F6E05F}']
    // Guarda la orden y sus movimientos en una única transacción.
    // Repetir el mismo Id y contenido devuelve la orden sin mover stock.
    function Guardar(const AOrden: TOrdenRetiradaLotes): TOrdenRetiradaLotes;
    function Leer(const AId: string): TOrdenRetiradaLotes;
    function LeerPorMovimiento(const ANumero: string): TOrdenRetiradaLotes;
    function AlmacenesTaras(const AEmpresa: string):
      TArray<TAlmacenRetiradaLotes>;
  end;

implementation

end.
