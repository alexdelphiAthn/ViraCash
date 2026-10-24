{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAuditoriaDatosIntf                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos para aplicar la auditoría estándar a los datasets.              }
{******************************************************************************}
unit inLibAuditoriaDatosIntf;

interface

uses
  Data.DB;

type
  IServicioAuditoriaDatos = interface
    ['{A758FBCB-B3ED-450A-BD6A-382457260A1C}']
    procedure Actualizar(DataSet: TDataSet);
  end;

  IProveedorAuditoriaDatos = interface
    ['{9CA4ECE0-130C-472E-9D2E-1F2884C52E29}']
    function GetAuditoriaDatos: IServicioAuditoriaDatos;
    property AuditoriaDatos: IServicioAuditoriaDatos
      read GetAuditoriaDatos;
  end;

implementation

end.
