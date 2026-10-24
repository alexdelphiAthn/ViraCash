{******************************************************************************}
{                                                                              }
{  Módulo:       inLibValidacionDocumentoLecturasIntf                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato de lecturas para validar tallas de un documento de compra.       }
{******************************************************************************}
unit inLibValidacionDocumentoLecturasIntf;

interface

uses
  inLibDocumentoIntf;

type
  IValidacionDocumentoLecturas = interface
    ['{7FD598AA-A3BD-4584-9ED3-835B5B99E9AC}']
    function ListarArticulosSinSistemaTallas(
      const AConfiguracion: TConfiguracionDocumento;
      const ASerie, ANumero: string): TArray<string>;
  end;

implementation

end.
