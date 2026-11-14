{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTicketsCajaIntf                                          }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Read models para reimpresiones, resguardos y recordatorios de Caja.       }
{******************************************************************************}
unit inLibTicketsCajaIntf;

interface

uses
  System.SysUtils,
  inLibCajaDatosFactura,
  inLibGenerarTicketIntf;

type
  TContextoOperacionTicketCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    Operacion: string;
  end;

  TEmpresaResguardoTicketCaja = record
    FormatoDocumento: string;
    Encontrada: Boolean;
    RazonSocial: string;
  end;

  TFechaResguardoTicketCaja = record
    Encontrada: Boolean;
    FechaOperacion: TDateTime;
    CodigoCliente: string;
  end;

  TDepositoResguardoTicketCaja = record
    CodigoUnidad: string;
    Descripcion: string;
    CodigoCliente: string;
    TotalPvp: Currency;
  end;

  // Apartado del cliente de Varios: quién aparta y el ticket con el que se
  // completa la venta desde F4.
  TApartadoResguardoTicketCaja = record
    Encontrado: Boolean;
    NombreContacto: string;
    TelefonoContacto: string;
    SerieFactura: string;
    NumeroFactura: string;
    CodigoBarras: string;
  end;
  TEntregaResguardoTicketCaja = record
    TipoOperacion: string;
    Importe: Currency;
    DescripcionArticulo: string;
  end;

  TDevolucionEconomicaTicketCaja = record
    TipoOperacion: string;
    Importe: Currency;
  end;

  TCabeceraTicketCaja = record
    Encontrada: Boolean;
    TipoOperacion: string;
    FechaOperacion: TDateTime;
    InstanteAlta: TDateTime;
    CodigoEmpleado: string;
    DiminutivoVendedor: string;
    CodigoClienteOperacion: string;
    Concepto: string;
    ImporteOperacion: Currency;
    SerieFactura: string;
    NumeroFactura: string;
    TipoFactura: string;
    FormatoDocumento: string;
    NifEmpresaFactura: string;
    FechaFactura: TDateTime;
    TotalLiquido: Currency;
    TotalRetencion: Currency;
    ImporteVerifactu: Currency;
    RazonSocialEmpresa: string;
    DireccionEmpresa: string;
    CodigoPostalEmpresa: string;
    PoblacionEmpresa: string;
    MovilEmpresa: string;
    TextoLegalEmpresa: string;
    CodigoClienteFactura: string;
    TotalIvaNormal: Currency;
    BaseIvaNormal: Currency;
    PorcentajeIvaNormal: Double;
    TotalIvaReducido: Currency;
    BaseIvaReducido: Currency;
    PorcentajeIvaReducido: Double;
    // FZ-ISSUE-335: superreducido y exento también salen en el ticket.
    TotalIvaSuperreducido: Currency;
    BaseIvaSuperreducido: Currency;
    PorcentajeIvaSuperreducido: Double;
    TotalIvaExento: Currency;
    BaseIvaExento: Currency;
    PorcentajeIvaExento: Double;
    // FZ-ISSUE-375: recargo de equivalencia por tramo.
    TotalReNormal: Currency;
    PorcentajeReNormal: Double;
    TotalReReducido: Currency;
    PorcentajeReReducido: Double;
    TotalReSuperreducido: Currency;
    PorcentajeReSuperreducido: Double;
    TotalReExento: Currency;
    PorcentajeReExento: Double;
  end;

  TLineaTicketCaja = record
    ClaveAgrupacion: string;
    CodigoUnidad: string;
    TipoCantidad: string;
    Cantidad: Double;
    Total: Currency;
    TotalBruto: Currency;
    PrecioSalida: Double;
    PorcentajeDescuento: Double;
    ImporteDescuento: Double;
    Descripcion: string;
    // F-LOTEC-015: lote o serie de la línea ('' sin lote).
    Lote: string;
    FechaCaducidad: TDate;
    EsSerie: Boolean;
  end;

  TPagoTicketCaja = record
    CodigoFormaPago: string;
    DescripcionFormaPago: string;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
    // FZ-ISSUE-933: referencia del pago (bono, vale...); '' si no tiene.
    Referencia: string;
  end;

  TValeTicketCaja = record
    Codigo: string;
    ImporteNominal: Currency;
    Pin: string;
  end;

  TEmpresaRecordatorioTicketCaja = record
    Encontrada: Boolean;
    Codigo: string;
    RazonSocial: string;
  end;

  TAnticipoRecordatorioTicketCaja = record
    TipoOperacion: string;
    Importe: Currency;
    FechaOperacion: TDateTime;
    Empresa: string;
    Almacen: string;
    Caja: string;
  end;

  TDepositoPendienteTicketCaja = record
    IdDeposito: string;
    CodigoUnidad: string;
    Empresa: string;
    Almacen: string;
    Caja: string;
    Descripcion: string;
    PrecioVenta: Currency;
    FechaCreacion: TDateTime;
    ImporteAnticipo: Currency;
    CantidadPendiente: Double;
    CodigoCliente: string;
    RazonSocialCliente: string;
  end;

  IRepositorioResguardosCaja = interface
    ['{8AF084E2-0C15-46AF-9278-1F86EAB471E4}']
    function ObtenerEmpresaResguardo(
      const AEmpresa: string): TEmpresaResguardoTicketCaja;
    function ObtenerFechaResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TFechaResguardoTicketCaja;
    function ListarNuevosDepositosResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDepositoResguardoTicketCaja>;
    function ListarEntregasResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TEntregaResguardoTicketCaja>;
    function ListarDevolucionesEconomicasResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDevolucionEconomicaTicketCaja>;
    function ListarDepositosDevueltosResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TDepositoResguardoTicketCaja>;
    function ObtenerTotalPagadoResguardo(
      const AContexto: TContextoOperacionTicketCaja): Currency;
    function ObtenerApartadoResguardo(
      const AContexto: TContextoOperacionTicketCaja):
      TApartadoResguardoTicketCaja;
    function ListarPieTicket(
      const AEmpresa: string): TArray<string>;
  end;
  IRepositorioTicketsVentaCaja = interface
    ['{E5D9A3B4-44A3-48AE-8194-A9E05D64B619}']
    function ObtenerCabeceraTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TCabeceraTicketCaja;
    function ListarLineasTicket(
      const ASerie, ANumero: string): TArray<TLineaTicketCaja>;
    function ListarPagosTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TPagoTicketCaja>;
    function ListarValesTicket(
      const AContexto: TContextoOperacionTicketCaja):
      TArray<TValeTicketCaja>;
    function ListarPieTicket(
      const AEmpresa: string): TArray<string>;
    function ObtenerCodigoBarrasTicket(
      const ASerie, ANumero: string): string;
    // FZ-ISSUE-200: factura rectificada o sustituida por ASerie/ANumero.
    function ObtenerReferenciaRectificacionTicket(
      const ASerie, ANumero: string): TReferenciaRectificacionTicket;
  end;
  IRepositorioRecordatoriosCaja = interface
    ['{C7C5D86D-3905-478B-B54A-FA466317D470}']
    function ObtenerEmpresaRecordatorio(
      const AEmpresa: string): TEmpresaRecordatorioTicketCaja;
    function ListarAnticiposRecordatorio(
      const AIdDeposito: string):
      TArray<TAnticipoRecordatorioTicketCaja>;
    function ListarDepositosPendientesRecordatorio(
      const ACodigoCliente: string):
      TArray<TDepositoPendienteTicketCaja>;
  end;
  TRepositoriosTicketsCaja = record
    Resguardos: IRepositorioResguardosCaja;
    Tickets: IRepositorioTicketsVentaCaja;
    Recordatorios: IRepositorioRecordatoriosCaja;
    Impresion: ILecturasImpresionTicket;
  end;

implementation

end.
