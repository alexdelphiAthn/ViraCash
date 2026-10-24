{******************************************************************************}
{                                                                              }
{  Módulo:       inLibColumnasDocumentoLecturasIntf                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para leer nombres globales de atributos documentales.            }
{******************************************************************************}
unit inLibColumnasDocumentoLecturasIntf;

interface

type
  IColumnasDocumentoLecturas = interface
    ['{32133952-B05F-4F00-B291-1BED91DCECE4}']
    function ListarNombresAtributosGlobales: TArray<string>;
  end;

implementation

end.
