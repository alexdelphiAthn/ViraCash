{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFormatoDocumentoLecturasIntf                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Contrato para leer el formato documental de una empresa.                  }
{******************************************************************************}
unit inLibFormatoDocumentoLecturasIntf;

interface

type
  IFormatoDocumentoLecturas = interface
    ['{6B4887F6-110B-4F95-A67A-9E3D8C225C1A}']
    function LeerFormatoEmpresa(
      const ACodigoEmpresa: string): string;
    function LeerFormatoFactura(
      const ASerie, ANumero: string): string;
  end;

function FormatoDocumentoFacturaDelProveedor(
  const AProveedor: IInterface; const ASerie, ANumero: string): string;

implementation

uses
  System.SysUtils, inLibFormatoDocumento;

function FormatoDocumentoFacturaDelProveedor(
  const AProveedor: IInterface; const ASerie, ANumero: string): string;
var
  oLecturas: IFormatoDocumentoLecturas;
begin
  Result := FORMATO_DOCUMENTO_DEFECTO;
  if Supports(AProveedor, IFormatoDocumentoLecturas, oLecturas) then
    Result := oLecturas.LeerFormatoFactura(ASerie, ANumero);
end;

end.
