{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGenBusq                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lanzamiento genérico de formularios de búsqueda.                          }
{    Devuelve el dataset o el valor seleccionado por el usuario.               }
{******************************************************************************}
unit inLibGenBusq;

interface

uses
  Forms, Uni, DBAccess, Data.DB;

type
  IBusquedaVisual = interface
    ['{A1C30774-7AE0-4602-9D1D-93CFCD5BFD20}']
    function EjecutarBusqueda(AConexion: TUniConnection;
                              const ACaption: string;
                              ADataSet: TCustomDADataSet;
                              const AName: string;
                              AParentForm: TCustomForm = nil):
                              Boolean; overload;
    function EjecutarBusquedaDataSet(
      const ACaption: string;
      ADataSet: TDataSet;
      const AName: string;
      AParentForm: TCustomForm = nil): Boolean;
    function EjecutarBusqueda(AConexion: TUniConnection;
                              const ACaption, ASql,
                                    ACampoResultado: string;
                              out AValorDevuelto: string;
                              const AName: string;
                              AParentForm: TCustomForm = nil):
                              Boolean; overload;
  end;
  IProveedorBusquedaVisual = interface
    ['{984001D1-F1CF-4E21-8FC5-0492953A3D69}']
    function GetBusquedaVisual: IBusquedaVisual;
    property BusquedaVisual: IBusquedaVisual read GetBusquedaVisual;
  end;

implementation

end.
