{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoTicketsLecturasIntf                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para cargar datos validados del correo de una operación.         }
{******************************************************************************}
unit inLibCorreoTicketsLecturasIntf;

interface

uses
  inLibCorreoTickets;

type
  ICorreoTicketsLecturas = interface
    ['{DBB61239-E68F-4EAC-9617-BB3E48DCCBCA}']
    function CargarDatosOperacion(const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string): TDatosCorreoOperacion;
    // Razon social de la empresa; vacio si no existe.
    function NombreEmpresa(const AEmpresa: string): string;
  end;

implementation

end.
