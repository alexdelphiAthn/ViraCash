{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSepaRemesasVentaLecturasIntf                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para cargar una remesa SEPA ya validada.                         }
{******************************************************************************}
unit inLibSepaRemesasVentaLecturasIntf;

interface

uses
  inLibSepaRemesasVenta;

type
  ISepaRemesasVentaLecturas = interface
    ['{FB1632E4-46B6-4F6F-9CA9-EAA3A772B7C4}']
    function CargarRemesaValidada(const ASerie,
      ANumero: string): TRemesaSepaVentaValidada;
  end;

implementation

end.
