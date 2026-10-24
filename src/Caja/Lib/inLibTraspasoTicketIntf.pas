{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraspasoTicketIntf                                      }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de lectura para imprimir solicitudes y traspasos de caja.        }
{******************************************************************************}
unit inLibTraspasoTicketIntf;

interface

type
  TSolicitudTraspasoTicket = record
    Existe: Boolean;
    Tipo: string;
    Origen: string;
    Destino: string;
    Empleado: string;
    Estado: string;
    Fecha: TDateTime;
    InstanteVentasDesde: TDateTime;
    InstanteVentasHasta: TDateTime;
  end;

  TLineaSolicitudTraspasoTicket = record
    Sku: string;
    Descripcion: string;
    CantidadPedida: Double;
    StockOrigen: Double;
    StockDestino: Double;
    CodigoProveedor: string;
    Proveedor: string;
  end;

  TTraspasoTicketHistorico = record
    Existe: Boolean;
    Serie: string;
    NumeroDocumento: string;
    FormatoDocumento: string;
    Origen: string;
    Destino: string;
    Empleado: string;
  end;

  TLineaTraspasoTicket = record
    Sku: string;
    Descripcion: string;
    Cantidad: Double;
  end;

  IRepositorioTraspasoTicket = interface
    ['{35DBDBA6-9E9D-4201-8131-CCB08A95BA01}']
    function ObtenerSolicitud(
      const ANumero, ASerie: string):
      TSolicitudTraspasoTicket;
    function ListarLineasSolicitud(
      const ANumero, ASerie, AOrigen, ADestino: string):
      TArray<TLineaSolicitudTraspasoTicket>;
    function ObtenerStock(
      const AAlmacen, ASku: string): Double;
    function ObtenerTraspasoHistorico(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TTraspasoTicketHistorico;
    function ListarLineasTraspaso(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string):
      TArray<TLineaTraspasoTicket>;
  end;

implementation

end.
