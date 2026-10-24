{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAnfitrionDatosIntf                                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato mínimo del anfitrión de datos de un documento: la librería       }
{    cablea cabecera y detalles sin conocer TdmBase ni unidades UniData*.      }
{******************************************************************************}
unit inLibAnfitrionDatosIntf;

interface

uses
  Data.DB;

type
  // Lo implementa TdmBase (UniDataGen); la librería solo ve el contrato
  // (PLAN_SOLID, Fase 2b, Opción A).
  IAnfitrionDatosDocumento = interface
    ['{6A2B3F11-3EE3-435C-8715-EFE3E3D6BB88}']
    function ObtenerTablaPrincipal: TDataSet;
    procedure AsignarMaestroCabecera(ACabecera: TDataSource);
  end;

implementation

end.
