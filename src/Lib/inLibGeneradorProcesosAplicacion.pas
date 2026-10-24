{******************************************************************************}
{                                                                              }
{  Módulo:       inLibGeneradorProcesosAplicacion                              }
{    Tipo:       Librería de aplicación                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Orquesta la ejecución de procesos sin depender de VCL ni UniDAC.          }
{******************************************************************************}
unit inLibGeneradorProcesosAplicacion;

interface

type
  TTipoSentenciaProceso = (
    tspConsulta,
    tspComando
  );
  IResultadoSentenciaProceso = interface
    ['{2585A051-A761-4263-8263-C1C7BB2FA2F5}']
    function Correcto: Boolean;
    function TieneDatos: Boolean;
    function Filas: Integer;
    function Milisegundos: Int64;
    function MensajeError: string;
  end;
  IRepositorioGeneradorProcesos = interface
    ['{E08D5332-14DA-428A-9FF2-A096D5E498F6}']
    function SepararSentencias(
      const AScript: string): TArray<string>;
    function EjecutarSentencia(
      const ASentencia: string;
      ATipo: TTipoSentenciaProceso): IResultadoSentenciaProceso;
    // Cancelacion pedida desde otro hilo mientras la sentencia esta
    // en marcha: corta la que se este ejecutando y el servicio no
    // lanza las siguientes.
    procedure PedirCancelacion;
    procedure OlvidarCancelacion;
    function CancelacionPedida: Boolean;
  end;
  ICatalogoGeneradorProcesos = interface
    ['{85545472-C12B-474E-8AC5-B18374569809}']
    procedure Refrescar(const ABaseDatos: string);
    function CargarEstructura(
      const ATipo, ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
    function GenerarLlamadaProcedimiento(
      const ANombre: string): string;
  end;
  TDecisionContinuarProceso = function(
    const AResultado: IResultadoSentenciaProceso;
    AIndice: Integer): Boolean of object;
  // Aviso de por qué sentencia va el script y de lo que va a ejecutar.
  // Lo llama el hilo que ejecuta, así que quien lo atienda no puede
  // tocar la VCL.
  TAvisoSentenciaProceso = procedure(
    ANumero, ATotal: Integer;
    const ASentencia: string) of object;
  TResultadoEjecucionProceso = record
    Resultados: TArray<IResultadoSentenciaProceso>;
    Cancelada: Boolean;
  end;
  TServicioGeneradorProcesos = class
  private
    FRepositorio: IRepositorioGeneradorProcesos;
  public
    constructor Create(
      const ARepositorio: IRepositorioGeneradorProcesos);
    function Ejecutar(
      const AScript: string;
      ADecidirContinuacion: TDecisionContinuarProceso;
      AAvisarSentencia: TAvisoSentenciaProceso = nil):
      TResultadoEjecucionProceso;
  end;

function PrimeraLineaUtilProceso(const ASQL: string): string;
function TipoSentenciaProceso(
  const ASQL: string): TTipoSentenciaProceso;

implementation

uses
  System.Classes,
  System.SysUtils,
  inLibProteccionDatosFacturacion;

function PrimeraLineaUtilProceso(const ASQL: string): string;
var
  I: Integer;
  Linea: string;
  Lineas: TStringList;
begin
  Result := '';
  Lineas := TStringList.Create;
  try
    Lineas.Text := ASQL;
    for I := 0 to Lineas.Count - 1 do
    begin
      Linea := Trim(Lineas[I]);
      if (Result = '') and (Linea <> '') and
         (Pos('--', Linea) <> 1) then
        Result := Linea;
    end;
  finally
    Lineas.Free;
  end;
end;

function TipoSentenciaProceso(
  const ASQL: string): TTipoSentenciaProceso;
var
  PrimeraLinea: string;
begin
  PrimeraLinea := UpperCase(PrimeraLineaUtilProceso(ASQL));
  if (Pos('SELECT', PrimeraLinea) = 1) or
     (Pos('CALL', PrimeraLinea) = 1) or
     (Pos('SHOW', PrimeraLinea) = 1) or
     (Pos('EXPLAIN ', PrimeraLinea) = 1) or
     (Pos('DESCRIBE ', PrimeraLinea) = 1) or
     (Pos('DESC ', PrimeraLinea) = 1) then
    Result := tspConsulta
  else
    Result := tspComando;
end;

constructor TServicioGeneradorProcesos.Create(
  const ARepositorio: IRepositorioGeneradorProcesos);
begin
  inherited Create;
  if ARepositorio = nil then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

function TServicioGeneradorProcesos.Ejecutar(
  const AScript: string;
  ADecidirContinuacion: TDecisionContinuarProceso;
  AAvisarSentencia: TAvisoSentenciaProceso):
  TResultadoEjecucionProceso;
var
  I: Integer;
  Resultado: IResultadoSentenciaProceso;
  Sentencias: TArray<string>;
begin
  Result := Default(TResultadoEjecucionProceso);
  FRepositorio.OlvidarCancelacion;
  Sentencias := FRepositorio.SepararSentencias(Trim(AScript));
  // Se valida el lote completo antes de ejecutar la primera sentencia para
  // impedir que un script mixto deje cambios parciales antes del bloqueo.
  for I := 0 to Length(Sentencias) - 1 do
    ValidarSqlSinModificacionesFacturacion(Sentencias[I]);
  for I := 0 to Length(Sentencias) - 1 do
  begin
    if not Result.Cancelada then
    begin
      if FRepositorio.CancelacionPedida then
        Result.Cancelada := True
      else
      begin
        if Assigned(AAvisarSentencia) then
          AAvisarSentencia(I + 1, Length(Sentencias), Sentencias[I]);
        Resultado := FRepositorio.EjecutarSentencia(
          Sentencias[I],
          TipoSentenciaProceso(Sentencias[I]));
        // El error de una sentencia cortada a proposito no se
        // ensenia como fallo del script ni se pregunta por el.
        if (not Resultado.Correcto) and
           FRepositorio.CancelacionPedida then
          Result.Cancelada := True
        else
        begin
          SetLength(Result.Resultados,
            Length(Result.Resultados) + 1);
          Result.Resultados[High(Result.Resultados)] := Resultado;
          if not Resultado.Correcto then
          begin
            if Assigned(ADecidirContinuacion) then
              Result.Cancelada :=
                not ADecidirContinuacion(Resultado, I)
            else
              Result.Cancelada := True;
          end;
        end;
      end;
    end;
  end;
end;

end.
