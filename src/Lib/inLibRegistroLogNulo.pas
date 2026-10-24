{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRegistroLogNulo                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Implementación nula para contextos de diseño y pruebas sin registro.      }
{******************************************************************************}
unit inLibRegistroLogNulo;

interface

uses
  inLibLogIntf;

function CrearRegistroLogNulo: IRegistroLog;

implementation

uses
  inLibMonitorSQLIntf,
  inLibParametrosIntf;

type
  TRegistroLogNulo = class(TInterfacedObject, IRegistroLog)
  public
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

function CrearRegistroLogNulo: IRegistroLog;
begin
  Result := TRegistroLogNulo.Create;
end;

procedure TRegistroLogNulo.RegistrarInformacion(
  const AMensaje: string);
begin
end;

procedure TRegistroLogNulo.RegistrarAviso(const AMensaje: string);
begin
end;

procedure TRegistroLogNulo.RegistrarError(const AMensaje: string);
begin
end;

procedure TRegistroLogNulo.RegistrarRendimiento(
  const AEtiqueta, ADetalle: string;
  ADuracionMs: Int64);
begin
end;

procedure TRegistroLogNulo.RegistrarEvento(
  const AUnidad, AObjeto, AEvento, ADetalle: string);
begin
end;

procedure TRegistroLogNulo.RegistrarSQL(
  const ASQL: string;
  ADuracionMs: Int64;
  AFilas: Integer;
  ACorrecto: Boolean;
  const AError, AParametros: string);
begin
end;

function TRegistroLogNulo.ObtenerEvidencias: TEvidenciasLog;
begin
  Result.RutaArchivo := '';
  Result.SQLActivo := False;
  Result.RendimientoActivo := False;
  Result.AvanzadoActivo := False;
end;

procedure TRegistroLogNulo.ActivarDiagnosticoCompleto;
begin
end;

procedure TRegistroLogNulo.AsignarMonitorSQL(
  const AMonitorSQL: IServicioMonitorSQL);
begin
end;

procedure TRegistroLogNulo.AplicarModosDepuracion(
  const AParametros: IParametrosAplicacion);
begin
end;

end.
