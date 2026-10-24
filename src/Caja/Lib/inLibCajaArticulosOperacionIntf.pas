{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaArticulosOperacionIntf                               }
{    Tipo:       Contrato de persistencia                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Artículos que intervienen en una operación de caja. Lo usan las rejillas  }
{    que pintan la tira de fotos de la operación (Buscar operaciones y el      }
{    histórico de operaciones de caja).                                        }
{******************************************************************************}
unit inLibCajaArticulosOperacionIntf;

interface

type
  // Las cuatro claves de la operación y, si la generó, la factura
  // (borrador) de la que salen las líneas.
  TClaveOperacionCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    Operacion: string;
    SerieFactura: string;
    NumeroFactura: string;
  end;

  TArticuloOperacionCaja = record
    Articulo: string;
    Sku: string;
  end;

  TArticulosOperacionCaja = TArray<TArticuloOperacionCaja>;

  IConsultaArticulosOperacionCaja = interface
    ['{2C0E4E4B-8B0B-4B0E-9E4F-2B1B0E6A9D31}']
    // Artículos de la operación: venta, devolución y traspaso (por los
    // movimientos de almacén), depósito o préstamo y, si existe, las
    // líneas del borrador. Sin repetidos y en orden de línea.
    function ListarArticulosOperacion(
      const AOperacion: TClaveOperacionCaja;
      AMaximo: Integer): TArticulosOperacionCaja;
  end;

implementation

end.
