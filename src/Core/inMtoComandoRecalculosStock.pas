{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComandoRecalculosStock                                  }
{    Tipo:       Coordinador de aplicación                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ejecuta sin interfaz la cola de recálculos de movimientos de stock.       }
{******************************************************************************}
unit inMtoComandoRecalculosStock;

interface

uses
  inLibConexionesIntf,
  inLibLogIntf;

function EsProcesoComandoRecalculosStock: Boolean;
function EjecutarProcesoComandoRecalculosStock(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): Cardinal;

implementation

uses
  System.Diagnostics,
  System.SysUtils,
  Winapi.Windows,
  Uni,
  inLibComandoRecalculosStock,
  inLibLineaComandos,
  inLibMsgConfiguracion,
  inLibSalidaComandos,
  inLibTraducciones,
  inLibTraduccionesIntf,
  UniDataRecalculosStockLote,
  UniDataTraduccionesRepositorio;

const
  SALIDA_COMANDO_ERROR_INESPERADO = 1;
  SALIDA_COMANDO_SINTAXIS = 2;
  SALIDA_COMANDO_CONEXION = 3;
  SALIDA_COMANDO_EJECUCION = 4;
  SALIDA_COMANDO_COLA_INCOMPLETA = 5;

type
  TResultadoComandoRecalculosStock = record
    CodigoSalida: Cardinal;
    EsError: Boolean;
    Mensaje: string;
  end;

procedure InformarFalloSecundarioEnDepurador(
  const AContexto: PChar;
  E: Exception);
begin
  try
    OutputDebugString(PChar(
      string(AContexto) + ': ' + E.ClassName + ': ' + E.Message));
  except
    OutputDebugString(AContexto);
  end;
end;

function CrearResultadoComando(
  ACodigoSalida: Cardinal;
  const AMensaje: string
): TResultadoComandoRecalculosStock;
begin
  Result := Default(TResultadoComandoRecalculosStock);
  Result.CodigoSalida := ACodigoSalida;
  Result.EsError := ACodigoSalida <> 0;
  Result.Mensaje := AMensaje;
end;

function CrearUsuarioAuditoriaLote: string;
var
  sUsuarioWindows: string;
begin
  sUsuarioWindows := Trim(GetEnvironmentVariable('USERNAME'));
  if sUsuarioWindows = '' then
    sUsuarioWindows := 'SISTEMA';
  Result := Copy('LOTE/' + sUsuarioWindows, 1, 50);
end;

function CrearConfiguracionLote(
  const ASolicitud: TSolicitudComandoRecalculosStock
): TConfiguracionLoteRecalculosStock;
begin
  Result := Default(TConfiguracionLoteRecalculosStock);
  Result.MaximoGrupos := ASolicitud.MaximoGruposPorLote;
  Result.PausaMilisegundos := ASolicitud.PausaMilisegundos;
  Result.SegundosLease := ASolicitud.SegundosLease;
  Result.SegundosReintento := ASolicitud.SegundosReintento;
  Result.Usuario := CrearUsuarioAuditoriaLote;
end;

function CrearResultadoResumen(
  const AResumen: TResultadoLoteRecalculosStock
): TResultadoComandoRecalculosStock;
begin
  if AResumen.CantidadSinProcesar = 0 then
  begin
    Result := CrearResultadoComando(
      0,
      Format(
        SInfoCompletadoComandoRecalculosStock,
        [AResumen.CantidadLotes]));
  end
  else
  begin
    Result := CrearResultadoComando(
      SALIDA_COMANDO_COLA_INCOMPLETA,
      Format(
        SErrorColaIncompletaComandoRecalculosStock,
        [
          AResumen.CantidadSinProcesar,
          AResumen.CantidadPendientes,
          AResumen.CantidadProcesando,
          AResumen.CantidadErrores
        ]));
  end;
end;

procedure NotificarProgresoLote(
  const AParcial: TResultadoLoteRecalculosStock;
  const ARegistroLog: IRegistroLog);
var
  sMensaje: string;
begin
  sMensaje := Format(
    SInfoProgresoComandoRecalculosStock,
    [
      AParcial.CantidadLotes,
      AParcial.CantidadGruposProcesados,
      AParcial.CantidadGruposError,
      AParcial.CantidadSinProcesar
    ]);
  ARegistroLog.RegistrarInformacion(sMensaje);
  try
    EscribirMensajeComando(sMensaje, False);
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inMtoComandoRecalculosStock.Progreso', E);
  end;
end;

function ProcesarConConexion(
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudComandoRecalculosStock;
  const ARegistroLog: IRegistroLog
): TResultadoComandoRecalculosStock;
var
  oConfiguracion: TConfiguracionLoteRecalculosStock;
  oCronometro: TStopwatch;
  oResumen: TResultadoLoteRecalculosStock;
begin
  oConfiguracion := CrearConfiguracionLote(ASolicitud);
  ARegistroLog.RegistrarInformacion(
    Format(
      SInfoConfiguracionComandoRecalculosStock,
      [
        oConfiguracion.MaximoGrupos,
        oConfiguracion.PausaMilisegundos,
        oConfiguracion.SegundosLease,
        oConfiguracion.SegundosReintento
      ]));
  oCronometro := TStopwatch.StartNew;
  oResumen := ProcesarColaRecalculosStock(
    AConexion,
    oConfiguracion,
    procedure(const AParcial: TResultadoLoteRecalculosStock)
    begin
      NotificarProgresoLote(AParcial, ARegistroLog);
    end);
  ARegistroLog.RegistrarRendimiento(
    'RecalculosStock.Comando',
    Format(
      'lotes=%d; grupos=%d; grupos_error=%d; sin_procesar=%d; errores=%d',
      [
        oResumen.CantidadLotes,
        oResumen.CantidadGruposProcesados,
        oResumen.CantidadGruposError,
        oResumen.CantidadSinProcesar,
        oResumen.CantidadErrores
      ]),
    oCronometro.ElapsedMilliseconds);
  Result := CrearResultadoResumen(oResumen);
end;

function IntentarPrepararConexion(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  out AConexion: TUniConnection;
  out AError: string): Boolean;
begin
  AConexion := nil;
  AError := '';
  try
    AConexion := AFabricaConexiones.CrearConexion(nil);
    AFabricaConexiones.Conectar(AConexion);
    Result := True;
  except
    on E: Exception do
    begin
      AError := E.Message;
      FreeAndNil(AConexion);
      Result := False;
    end;
  end;
end;

// El modo comando no pasa por el login: el idioma de la instalación
// (parámetro appIdioma para «Todos») se aplica a los resourcestring en
// cuanto hay conexión, para que el LOG salga en el idioma configurado
// (FZ-ISSUE-611). Si el catálogo falla, el proceso sigue en español.
procedure ActivarIdiomaInstalacion(
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog);
var
  oTraducciones: IServicioTraducciones;
  sIdioma: string;
begin
  try
    sIdioma := ObtenerIdiomaConfigurado(
      TLectorIdiomaConfiguradoUniDAC.Create(AConexion),
      '',
      ARegistroLog);
    if not SameText(sIdioma, IDIOMA_ESPANOL) then
    begin
      oTraducciones := TServicioTraducciones.Create(
        TLectorCatalogoTraduccionesUniDAC.Create(AConexion),
        ARegistroLog,
        sIdioma);
      ActivarTraduccionResourcestrings(oTraducciones);
    end;
  except
    on E: Exception do
      ARegistroLog.RegistrarAviso(
        'No se pudo aplicar el idioma de la instalación al modo comando: ' +
        E.ClassName + ': ' + E.Message);
  end;
end;

function EjecutarComandoRecalculosStock(
  const AParametros: TArray<string>;
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): TResultadoComandoRecalculosStock;
var
  oConexion: TUniConnection;
  oSolicitud: TSolicitudComandoRecalculosStock;
  sError: string;
begin
  oSolicitud := InterpretarComandoRecalculosStock(AParametros);
  if not oSolicitud.EsValida then
  begin
    Result := CrearResultadoComando(
      SALIDA_COMANDO_SINTAXIS,
      SErrorSintaxisComandoRecalculosStock);
  end
  else if IntentarPrepararConexion(
            AFabricaConexiones,
            oConexion,
            sError) then
  begin
    try
      ActivarIdiomaInstalacion(oConexion, ARegistroLog);
      ARegistroLog.RegistrarInformacion(
        SInfoInicioComandoRecalculosStock);
      ARegistroLog.RegistrarInformacion(
        Format(
          SInfoConexionComandoRecalculosStock,
          [oConexion.Server, oConexion.Database]));
      try
        Result := ProcesarConConexion(
          oConexion,
          oSolicitud,
          ARegistroLog);
      except
        on E: Exception do
        begin
          Result := CrearResultadoComando(
            SALIDA_COMANDO_EJECUCION,
            Format(
              SErrorEjecucionComandoRecalculosStock,
              [E.Message]));
        end;
      end;
    finally
      FreeAndNil(oConexion);
    end;
  end
  else
  begin
    Result := CrearResultadoComando(
      SALIDA_COMANDO_CONEXION,
      Format(
        SErrorConexionComandoRecalculosStock,
        [sError]));
  end;
end;

procedure RegistrarResultadoComando(
  const AResultado: TResultadoComandoRecalculosStock;
  const ARegistroLog: IRegistroLog);
begin
  try
    EscribirMensajeComando(
      AResultado.Mensaje,
      AResultado.EsError);
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inMtoComandoRecalculosStock.Salida', E);
  end;
  try
    if AResultado.EsError then
      ARegistroLog.RegistrarError(AResultado.Mensaje)
    else
      ARegistroLog.RegistrarInformacion(AResultado.Mensaje);
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inMtoComandoRecalculosStock.Log', E);
  end;
end;

function EsProcesoComandoRecalculosStock: Boolean;
begin
  Result := EsComandoRecalculosStock(
    ObtenerParametrosLineaComandos);
end;

function EjecutarProcesoComandoRecalculosStock(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): Cardinal;
var
  oResultado: TResultadoComandoRecalculosStock;
begin
  try
    // El mensaje de inicio se registra tras conectar, ya con el idioma
    // de la instalación aplicado (FZ-ISSUE-611).
    oResultado := EjecutarComandoRecalculosStock(
      ObtenerParametrosLineaComandos,
      AFabricaConexiones,
      ARegistroLog);
  except
    on E: Exception do
    begin
      oResultado := CrearResultadoComando(
        SALIDA_COMANDO_ERROR_INESPERADO,
        Format(
          SErrorEjecucionComandoRecalculosStock,
          [E.Message]));
    end;
  end;
  RegistrarResultadoComando(oResultado, ARegistroLog);
  Result := oResultado.CodigoSalida;
end;

end.
