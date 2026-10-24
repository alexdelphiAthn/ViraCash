{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenerarTicketCajaPersistenciaIntf                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura tipada de operaciones para generar tickets no fiscales de Caja.   }
{******************************************************************************}
unit inLibGenerarTicketCajaPersistenciaIntf;

interface

uses
  System.SysUtils;

type
  TClaveOperacionTicketCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    NumeroOperacion: string;
  end;
  TDatosOperacionTicketCaja = record
    Encontrada: Boolean;
    TipoOperacion: string;
    FechaOperacion: TDateTime;
    CodigoEmpleado: string;
    Concepto: string;
    Importe: Currency;
  end;
  IGenerarTicketCajaPersistencia = interface
    ['{73368B6C-F30D-491B-BC0F-24F2F5F354D4}']
    function ObtenerOperacion(
      const AClave: TClaveOperacionTicketCaja):
      TDatosOperacionTicketCaja;
  end;

implementation

end.
