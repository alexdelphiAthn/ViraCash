{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTiraCajaTicketIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Read models necesarios para imprimir y exportar la tira de Caja.          }
{******************************************************************************}
unit inLibTiraCajaTicketIntf;

interface

uses
  System.SysUtils;

type
  TEmpresaTiraCajaTicket = record
    Encontrada: Boolean;
    RazonSocial: string;
    Nif: string;
    Direccion: string;
    CodigoPostal: string;
    Poblacion: string;
    Provincia: string;
  end;

  TLineaVentaTiraCaja = record
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: Double;
    Total: Currency;
  end;

  TFormaPagoTiraCaja = record
    Codigo: string;
    Descripcion: string;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
  end;

  TLineaTraspasoTiraCaja = record
    CodigoUnidad: string;
    Descripcion: string;
    Cantidad: Double;
    PrecioCosteUnitario: Double;
  end;

  TDepositoTiraCaja = record
    CodigoCliente: string;
    Cliente: string;
    CodigoUnidad: string;
    Descripcion: string;
    PrecioVenta: Currency;
    Cantidad: Double;
    ImporteAnticipo: Currency;
  end;

  TOperacionTiraCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
    FechaOperacion: TDateTime;
    SerieFactura: string;
    NumeroFactura: string;
    ImporteTotal: Currency;
    ConceptoGastoIngreso: string;
    AlmacenContrapartida: string;
    TotalLiquido: Currency;
    ImporteVerifactu: Currency;
    FechaFactura: TDateTime;
    NifEmpresaFactura: string;
    FormatoDocumento: string;
    Grupo: string;
  end;

  IRepositorioTiraCajaTicket = interface
    ['{4A998331-EAC6-4C55-AB78-5190B93D3AA7}']
    function ObtenerEmpresa(
      const AEmpresa: string): TEmpresaTiraCajaTicket;
    function ListarLineasVenta(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TLineaVentaTiraCaja>;
    function ListarFormasPago(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TFormaPagoTiraCaja>;
    function ListarLineasTraspaso(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TLineaTraspasoTiraCaja>;
    function ListarDepositos(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TDepositoTiraCaja>;
    function ListarOperaciones(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate;
      const ASeries: TArray<string>;
      ACronologico, AIncluirTraspasos, AIncluirIngresos,
      AIncluirGastos, AIncluirCredito: Boolean):
      TArray<TOperacionTiraCaja>;
    function ListarSeries(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate): TArray<string>;
  end;

implementation

end.
