{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCoordinadorOperacionesAplicacion                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordina workers, cancelación y ciclo de vida de copias y restauraciones.}
{******************************************************************************}
unit inLibCoordinadorOperacionesAplicacion;

interface

uses
  System.Classes,
  inLibCopiasSeguridadIntf,
  inLibOperacionesAplicacionIntf;

type
  TCasoUsoCopiasSeguridad = class(
    TInterfacedObject,
    ICasoUsoCopiasSeguridad)
  private
    FRepositorioCopias: IRepositorioCopiasSeguridad;
    FPresentacion: IPresentacionOperacionesAplicacion;
    FWorker: TThread;
    FEnCurso: Boolean;
    FCancelacionSolicitada: Boolean;
    FTipoOperacion: TTipoOperacionAplicacion;
    procedure ComenzarOperacion(ATipo: TTipoOperacionAplicacion);
    procedure AbortarInicioOperacion;
    procedure ProgresoWorker(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure FinalizarWorker(
      AResultado: TResultadoCopiaSeguridad;
      const AError: string;
      ALogBuffer: TStringList);
  public
    constructor Create(
      const ARepositorioCopias: IRepositorioCopiasSeguridad;
      const APresentacion: IPresentacionOperacionesAplicacion);
    function EnCurso: Boolean;
    function ModoCreacionCopia: TModoProteccionCopia;
    function ExtensionCreacionCopia: string;
    function PuedeRestaurar(const ARutaFichero: string): Boolean;
    function RequiereContrasena(const ARutaFichero: string): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string);
    function CrearCopia(
      const ARutaFichero, AContrasena: string): Boolean;
    function CancelacionSolicitada: Boolean;
    function SolicitarCancelacion: Boolean;
  end;
  TCoordinadorOperacionesAplicacion = TCasoUsoCopiasSeguridad;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorServicioCopiasNoProporcionado =
    'No se ha proporcionado el servicio de copias de seguridad.';
  SErrorPresentacionOperacionesNoProporcionada =
    'No se ha proporcionado la presentación de operaciones largas.';
  SErrorOperacionAplicacionEnCurso =
    'Ya hay una operación larga en curso.';

constructor TCasoUsoCopiasSeguridad.Create(
  const ARepositorioCopias: IRepositorioCopiasSeguridad;
  const APresentacion: IPresentacionOperacionesAplicacion);
begin
  inherited Create;
  if not Assigned(ARepositorioCopias) then
  begin
    raise EArgumentNilException.Create(
      SErrorServicioCopiasNoProporcionado);
  end;
  if not Assigned(APresentacion) then
  begin
    raise EArgumentNilException.Create(
      SErrorPresentacionOperacionesNoProporcionada);
  end;
  FRepositorioCopias := ARepositorioCopias;
  FPresentacion := APresentacion;
end;

procedure TCasoUsoCopiasSeguridad.ComenzarOperacion(
  ATipo: TTipoOperacionAplicacion);
begin
  if FEnCurso then
  begin
    raise EInvalidOpException.Create(
      SErrorOperacionAplicacionEnCurso);
  end;
  FTipoOperacion := ATipo;
  FWorker := nil;
  FCancelacionSolicitada := False;
  FEnCurso := True;
  FPresentacion.MostrarOperacion;
end;

procedure TCasoUsoCopiasSeguridad.AbortarInicioOperacion;
begin
  FWorker := nil;
  FCancelacionSolicitada := False;
  FEnCurso := False;
  FPresentacion.FinalizarOperacion(
    FTipoOperacion,
    rcsFallida,
    '',
    nil);
end;

function TCasoUsoCopiasSeguridad.EnCurso: Boolean;
begin
  Result := FEnCurso;
end;

function TCasoUsoCopiasSeguridad.ModoCreacionCopia:
  TModoProteccionCopia;
begin
  Result := FRepositorioCopias.ModoCreacion;
end;

function TCasoUsoCopiasSeguridad.ExtensionCreacionCopia: string;
begin
  Result := FRepositorioCopias.ExtensionCreacion;
end;

function TCasoUsoCopiasSeguridad.PuedeRestaurar(
  const ARutaFichero: string): Boolean;
begin
  Result := FRepositorioCopias.PuedeRestaurar(ARutaFichero);
end;

function TCasoUsoCopiasSeguridad.RequiereContrasena(
  const ARutaFichero: string): Boolean;
begin
  Result := FRepositorioCopias.RequiereContrasena(ARutaFichero);
end;

procedure TCasoUsoCopiasSeguridad.IniciarCopia(
  const ARutaFichero, AContrasena: string);
begin
  ComenzarOperacion(toaCopiaSeguridad);
  try
    FRepositorioCopias.IniciarCopia(
      ARutaFichero,
      AContrasena,
      ProgresoWorker,
      FinalizarWorker,
      FWorker);
  except
    AbortarInicioOperacion;
    raise;
  end;
end;

procedure TCasoUsoCopiasSeguridad.IniciarRestauracion(
  const ARutaFichero, AContrasena: string);
begin
  ComenzarOperacion(toaRestauracion);
  try
    FRepositorioCopias.IniciarRestauracion(
      ARutaFichero,
      AContrasena,
      ProgresoWorker,
      FinalizarWorker,
      FWorker);
  except
    AbortarInicioOperacion;
    raise;
  end;
end;

function TCasoUsoCopiasSeguridad.CrearCopia(
  const ARutaFichero, AContrasena: string): Boolean;
var
  Resultado: TResultadoCopiaSeguridad;
  sError: string;
begin
  ComenzarOperacion(toaCopiaSeguridad);
  sError := '';
  try
    Resultado := FRepositorioCopias.CrearCopia(
      ARutaFichero,
      AContrasena,
      ProgresoWorker,
      sError);
    FinalizarWorker(Resultado, sError, nil);
    Result := Resultado = rcsCompletada;
  except
    AbortarInicioOperacion;
    raise;
  end;
end;

function TCasoUsoCopiasSeguridad.CancelacionSolicitada: Boolean;
begin
  Result := FCancelacionSolicitada;
end;

function TCasoUsoCopiasSeguridad.SolicitarCancelacion: Boolean;
begin
  Result := FEnCurso and not FCancelacionSolicitada;
  if Result then
  begin
    FCancelacionSolicitada := True;
    if Assigned(FWorker) then
      FWorker.Terminate;
    FPresentacion.MostrarCancelando;
  end;
end;

procedure TCasoUsoCopiasSeguridad.ProgresoWorker(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if FEnCurso then
  begin
    FPresentacion.ActualizarProgreso(
      AEtapa,
      APaso,
      ATotal,
      AFilaGlobal,
      AFilasGlobalTotal);
  end;
end;

procedure TCasoUsoCopiasSeguridad.FinalizarWorker(
  AResultado: TResultadoCopiaSeguridad;
  const AError: string;
  ALogBuffer: TStringList);
begin
  FWorker := nil;
  FCancelacionSolicitada := False;
  FEnCurso := False;
  FPresentacion.FinalizarOperacion(
    FTipoOperacion,
    AResultado,
    AError,
    ALogBuffer);
end;

end.
