{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArqueoIntf                                              }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato del read model utilizado para calcular el arqueo de caja.        }
{******************************************************************************}
unit inLibArqueoIntf;

interface

const
  TipoOpVenta = 'VE';
  TipoOpDevolucion = 'DV';
  TipoOpCobroCuenta = 'CB';
  TipoOpEntradaCambio = 'EC';
  TipoOpGastoCaja = 'GC';
  TipoOpDeposito = 'DE';
  TipoOpValeRedimido = 'VR';
  EstadoDepositoAbierto = 'PENDIENTE';

type
  TArqueoPagoForma = record
    Codigo: string;
    Descripcion: string;
    EsEfectivo: Boolean;
    Importe: Currency;
  end;

  TArqueoCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDate;
    FechaHasta: TDate;
    CantidadVentas: Integer;
    CantidadOperaciones: Integer;
    BrutoLineas: Currency;
    DescuentosLineas: Currency;
    NetoLineas: Currency;
    BrutoOperaciones: Currency;
    DescuentosOperaciones: Currency;
    Neto: Currency;
    Prestamos: Currency;
    Devoluciones: Currency;
    VentasNormales: Currency;
    VentasPrestamos: Currency;
    TotalVentas: Currency;
    ValesRecogidos: Currency;
    ValesEmitidos: Currency;
    CobrosClientes: Currency;
    PendienteCobro: Currency;
    IngresosCaja: Currency;
    EfectivoIngresos: Currency;
    EfectivoEntradas: Currency;
    EfectivoSalidas: Currency;
    EfectivoAnterior: Currency;
    EfectivoCaja: Currency;
    OtrosIngresos: Currency;
    SaldoRecontar: Currency;
    PagosPorForma: TArray<TArqueoPagoForma>;
  end;

  IRepositorioArqueoCaja = interface
    ['{AA6EF4A7-3BC0-4ED3-95C4-E2473B29ACF7}']
    function Calcular(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate): TArqueoCaja;
  end;

// Subtotales de la cascada a partir de los importes ya leídos.
procedure CalcularDerivadosArqueo(var AArqueo: TArqueoCaja);

implementation

procedure CalcularDerivadosArqueo(var AArqueo: TArqueoCaja);
begin
  // Ventas a préstamo = valor de la mercancía comprometida en el período
  // (no el pendiente). Si el cliente ha entregado anticipos, esa parte
  // ya está cobrada pero la venta "comprometida" sigue siendo el total.
  AArqueo.VentasPrestamos := AArqueo.Prestamos;

  // Pendiente de cobro: viene calculado por depósito en
  // CalcularDepositos. «Préstamos − Cobros clientes» contaba como
  // pendientes los depósitos ya liquidados (FZ-ISSUE-349).

  // Total Ventas = ventas normales + ventas a préstamo − devoluciones.
  AArqueo.TotalVentas :=
      AArqueo.VentasNormales
    + AArqueo.VentasPrestamos
    - AArqueo.Devoluciones;

  // Efectivo en caja: efectivo ingresos + entradas − salidas + anterior
  AArqueo.EfectivoCaja :=
      AArqueo.EfectivoIngresos
    + AArqueo.EfectivoEntradas
    - AArqueo.EfectivoSalidas
    + AArqueo.EfectivoAnterior;

  // Saldo a recontar: efectivo en caja + ingresos por formas no-caja
  // (tarjetas, bonos, divisa, cripto...).
  AArqueo.SaldoRecontar := AArqueo.EfectivoCaja + AArqueo.OtrosIngresos;

  // Ingresos caja: lo cobrado en el período por todas las formas de pago
  // (fza_caja_pagos). La fórmula teórica "Neto − Prestamos − VR + VE + CC −
  // Pendiente" arrastra los desajustes del flujo real (consumos de
  // anticipo, tipos DV vs VE…), así que se suman los pagos entregados.
  // FZ-ISSUE-428: no lleva entradas de cambio, gastos de caja ni efectivo
  // anterior; esos entran después, en «Efectivo en caja».
  AArqueo.IngresosCaja :=
    AArqueo.EfectivoIngresos + AArqueo.OtrosIngresos;
end;

end.
