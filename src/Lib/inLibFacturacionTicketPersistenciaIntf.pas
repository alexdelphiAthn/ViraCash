{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFacturacionTicketPersistenciaIntf                      }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos para sustituir un ticket por una factura normal.          }
{******************************************************************************}
unit inLibFacturacionTicketPersistenciaIntf;

interface

uses
  System.SysUtils, Data.DB;

type
  IConsultaClientesFacturacionTicket = interface
    ['{30BB7E89-ACAD-4F53-B199-BC4B0AB476C4}']
    function DataSet: TDataSet;
  end;

  TClienteFacturacionTicket = record
    Existe: Boolean;
    RazonSocial: string;
    Nif: string;
    CodigoPais: string;
    NombrePais: string;
  end;

  TTicketFacturacion = record
    Serie: string;
    Numero: string;
    Fecha: TDateTime;
    Total: Currency;
    Detalle: string;
    InstanteModificacion: TDateTime;
  end;

  TTicketsFacturacion = TArray<TTicketFacturacion>;

  // Préstamo (depósito PENDIENTE) del cliente: no tiene ticket, así que se
  // factura como venta nueva (F1) y al emitirse se cierra y queda cobrado.
  TPrestamoFacturacion = record
    IdDeposito: string;
    Fecha: TDateTime;
    Articulo: string;
    Sku: string;
    Descripcion: string;
    Cantidad: Double;
    Precio: Currency;
    Anticipo: Currency;
    Total: Currency;
    InstanteModificacion: TDateTime;
  end;

  TPrestamosFacturacion = TArray<TPrestamoFacturacion>;

  TSolicitudFacturacionTicket = record
    SerieNueva: string;
    Cliente: string;
    Fecha: TDateTime;
    Empresa: string;
    SerieTicket: string;
    NumeroTicket: string;
    Usuario: string;
    // Vacío = contador de la serie.
    NumeroManual: string;
    // Vacía = la del ticket.
    FormaPago: string;
    // En la agrupacion se conserva la seleccion revisada por el usuario.
    Tickets: TTicketsFacturacion;
    // Solo en CrearFacturaPrestamos: préstamos revisados por el usuario.
    Prestamos: TPrestamosFacturacion;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;

  IServicioFacturacionTicket = interface
    ['{DCC154D9-0E3C-414B-BC22-031FB701D97E}']
    function ConsultarClientes: IConsultaClientesFacturacionTicket;
    function ConsultarCliente(
      const ACodigoCliente: string): TClienteFacturacionTicket;
    function CrearFactura(
      const ASolicitud: TSolicitudFacturacionTicket): string;
    function FormaPagoTicket(const ASerie, ANumero: string): string;
    // Fecha del ticket (0 si no existe).
    function FechaTicket(const ASerie, ANumero: string): TDateTime;
    function ConsultarTicketsPeriodo(const AEmpresa, ACliente: string;
      ADesde, AHasta: TDateTime): TTicketsFacturacion;
    function ConsultarTicketsSinCliente(const AEmpresa: string;
      ADesde, AHasta: TDateTime): TTicketsFacturacion;
    // Préstamos pendientes del cliente prestados dentro del período.
    function ConsultarPrestamosPeriodo(const AEmpresa, ACliente: string;
      ADesde, AHasta: TDateTime): TPrestamosFacturacion;
    // Factura F1 de los préstamos: los cierra, resta la deuda, saca el
    // stock del almacén de depósitos y deja la factura cobrada.
    function CrearFacturaPrestamos(
      const ASolicitud: TSolicitudFacturacionTicket): string;
  end;

implementation

end.
