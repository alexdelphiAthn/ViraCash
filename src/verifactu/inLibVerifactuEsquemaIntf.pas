{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuEsquemaIntf                                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de lectura de capacidades del esquema Verifactu.                 }
{******************************************************************************}
unit inLibVerifactuEsquemaIntf;

interface

type
  IRepositorioEsquemaVerifactu = interface
    ['{6BB8F245-4C3B-41F6-8321-A6F9BC1731E5}']
    function ColaDisponible(out AMensaje: string): Boolean;
  end;

implementation

end.
