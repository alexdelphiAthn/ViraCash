{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoDocumentoIntf                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para leer los datos de un documento comercial que se envía por   }
{    correo: nombre del tipo (fza_tipos_documentos) y empresa emisora.         }
{******************************************************************************}
unit inLibCorreoDocumentoIntf;

interface

uses
  inLibCorreoTickets;

type
  TDatosCorreoDocumento = record
    FormatoDocumento: string;
    Encontrado: Boolean;
    // Descripción de fza_tipos_documentos; vacía si el tipo no está dado
    // de alta para la tabla del documento.
    NombreDocumento: string;
    NombreEmpresa: string;
    EmailEmpresa: string;
  end;

  ILectorDatosCorreoDocumento = interface
    ['{994462AA-CF14-44AC-BC45-AC7519B78461}']
    function Leer(ATipo: TTipoDocumentoCorreo;
      const ASerie, ANumero: string): TDatosCorreoDocumento;
  end;

implementation

end.
