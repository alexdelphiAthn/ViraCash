{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuNoVerifactuExportIntf                           }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de lectura para exportar registros NO VERI*FACTU.                  }
{******************************************************************************}
unit inLibVerifactuNoVerifactuExportIntf;

interface

uses
  Data.DB;

type
  // Los TDataSet devueltos pertenecen al llamador.
  IRepositorioExportacionNoVerifactu = interface
    ['{71ABBD4E-BC62-4934-AF74-6A550F996183}']
    function ColumnasFirmaEventosDisponibles: Boolean;
    function ColumnasFirmaFacturacionDisponibles: Boolean;
    function ContarEventosSinFirma: Integer;
    function ContarFacturasSinFirma: Integer;
    function BuscarEventos: TDataSet;
    function BuscarFacturacion: TDataSet;
  end;

implementation
end.
