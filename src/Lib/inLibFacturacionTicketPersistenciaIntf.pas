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
  end;

implementation

end.
