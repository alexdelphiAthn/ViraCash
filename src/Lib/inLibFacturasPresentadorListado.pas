{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFacturasPresentadorListado                               }
{    Tipo:       Contrato (sin VCL)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto para preparar la consulta del listado de facturas.                 }
{******************************************************************************}
unit inLibFacturasPresentadorListado;

interface

uses
  Data.DB;

type
  // La sentencia del listado vive en la capa de persistencia: la pantalla
  // solo dice qué vista quiere y si la columna de cola Verifactu procede.
  IPreparadorListadoFacturas = interface
    ['{7A2C51E8-3B44-49F0-A0D6-5C918E4B7F32}']
    function EstadoColaDisponible(out AMensaje: string): Boolean;
    procedure PrepararListado(
      AConsulta: TDataSet;
      const AVista: string;
      AIncluirEstadoCola: Boolean);
  end;

implementation

end.
