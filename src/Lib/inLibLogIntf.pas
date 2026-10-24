{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLogIntf                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato mínimo de registro para colaboradores de la aplicación.         }
{******************************************************************************}
unit inLibLogIntf;

interface

uses
  inLibMonitorSQLIntf,
  inLibParametrosIntf;

type
  TEvidenciasLog = record
    RutaArchivo: string;
    SQLActivo: Boolean;
    RendimientoActivo: Boolean;
    AvanzadoActivo: Boolean;
    function Completo: Boolean;
  end;

  IRegistroLog = interface
    ['{97324860-FA85-460F-92D2-9B0E1C95588C}']
    procedure RegistrarInformacion(const AMensaje: string);
    procedure RegistrarAviso(const AMensaje: string);
    procedure RegistrarError(const AMensaje: string);
    procedure RegistrarRendimiento(
      const AEtiqueta, ADetalle: string;
      ADuracionMs: Int64);
    procedure RegistrarEvento(
      const AUnidad, AObjeto, AEvento, ADetalle: string);
    procedure RegistrarSQL(
      const ASQL: string;
      ADuracionMs: Int64;
      AFilas: Integer;
      ACorrecto: Boolean;
      const AError: string = '';
      const AParametros: string = '');
    function ObtenerEvidencias: TEvidenciasLog;
    procedure ActivarDiagnosticoCompleto;
    procedure AsignarMonitorSQL(
      const AMonitorSQL: IServicioMonitorSQL);
    procedure AplicarModosDepuracion(
      const AParametros: IParametrosAplicacion);
  end;

  IProveedorRegistroLog = interface
    ['{DBF55EF8-1DA6-463C-BCF9-8A58BD9DB661}']
    function GetRegistroLog: IRegistroLog;
    property RegistroLog: IRegistroLog read GetRegistroLog;
  end;

implementation

function TEvidenciasLog.Completo: Boolean;
begin
  Result := SQLActivo and
            RendimientoActivo and
            AvanzadoActivo;
end;

end.
