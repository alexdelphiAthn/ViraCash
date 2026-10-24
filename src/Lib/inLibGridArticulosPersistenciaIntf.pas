{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGridArticulosPersistenciaIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de la consulta de artículos enlazada al buscador visual del grid.  }
{******************************************************************************}
unit inLibGridArticulosPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaArticulosGrid = interface
    ['{BD170E35-6C18-4769-A938-7F78C6D4DC31}']
    function DataSet: TDataSet;
    procedure Aplicar(const AAlmacenStock: string);
  end;

implementation

end.
