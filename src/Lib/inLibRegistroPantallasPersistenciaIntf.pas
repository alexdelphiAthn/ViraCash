{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRegistroPantallasPersistenciaIntf                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de lectura del registro persistente de pantallas.                }
{******************************************************************************}
unit inLibRegistroPantallasPersistenciaIntf;

interface

type
  TPantallaRegistrada = record
    Llamada: string;
    Titulo: string;
    ElementoMenu: string;
    UnidadFormulario: string;
    Atajo: string;
    UnidadDatos: string;
    NumeroVentanas: Integer;
  end;

  ILectorRegistroPantallas = interface
    ['{53B46D73-9D8B-43CB-B163-F2A41F83AB06}']
    function Cargar: TArray<TPantallaRegistrada>;
  end;

implementation

end.
