{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSepaRemesasCompraLecturasIntf                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para leer una remesa de pago lista para el fichero SEPA.        }
{******************************************************************************}
unit inLibSepaRemesasCompraLecturasIntf;

interface

uses
  inLibSepaRemesasCompra;

type
  ISepaRemesasCompraLecturas = interface
    ['{6C0E5D1B-2F8A-4E77-9B43-1D7A3C9E5B20}']
    function LeerFicheroGenerado(const ASerie,
      ANumero: string): TFicheroSepaRemesaCompra;
    function CargarRemesaValidada(const ASerie, ANumero: string;
      AFormato: TFormatoSepaTransferencia;
      AInstante: TDateTime): TRemesaSepaCompraValidada;
  end;

implementation

end.
