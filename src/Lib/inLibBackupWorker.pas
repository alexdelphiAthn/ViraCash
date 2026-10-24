{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBackupWorker                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Hilos para ejecutar copia y restauración segura en segundo plano.         }
{******************************************************************************}
unit inLibBackupWorker;

interface

uses
  System.Classes, System.SysUtils,
  Backup.Engine, Backup.Types,
  inLibBackupPersistenciaIntf,
  inLibCifradoCopias,
  inLibCopiasSeguridadIntf;

type
  TWorkerProgresoEvent = TProgresoCopiaSeguridadEvent;
  TWorkerFinalizarEvent = TFinalizarCopiaSeguridadEvent;

const
  TIMEOUT_CONEXION_PREDETERMINADO_SEG = 5;
  TIMEOUT_COMANDO_PREDETERMINADO_SEG = 30;

type
  TBackupWorker = class(TThread)
  private
    FHost: string;
    FPort: Integer;
    FDatabase: string;
    FUser: string;
    FPassword: string;
    FRutaFichero: string;
    FModo: TModoProteccionCopia;
    FPassEncriptar: string;
    FResultado: TResultadoCopiaSeguridad;
    FError: string;
    FProgresoEtapa: string;
    FProgresoPaso: Integer;
    FProgresoTotal: Integer;
    FProgresoFilaGlobal: Integer;
    FProgresoFilasGlobalTotal: Integer;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    FFabricaPersistencia: IFabricaPersistenciaBackup;
    procedure EngineProgress(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AHost: string;
      APort: Integer;
      const ADatabase, AUser, APassword: string;
      const ARutaFichero: string;
      AModo: TModoProteccionCopia;
      const APassEncriptar: string;
      const AFabricaPersistencia:
        IFabricaPersistenciaBackup = nil);
    property OnProgreso: TWorkerProgresoEvent
      read FOnProgreso write FOnProgreso;
    property OnFinalizar: TWorkerFinalizarEvent
      read FOnFinalizar write FOnFinalizar;
  end;

  TRestoreWorker = class(TThread)
  private
    FHost: string;
    FPort: Integer;
    FDatabase: string;
    FUser: string;
    FPassword: string;
    FRutaFichero: string;
    FModo: TModoProteccionCopia;
    FPassDesencriptar: string;
    FResultado: TResultadoCopiaSeguridad;
    FError: string;
    FLogBuffer: TStringList;
    FErrores: Integer;
    FPosicion: Integer;
    FTotal: Integer;
    FSentenciasEjecutadas: Integer;
    FProgresoEtapa: string;
    FPrimerError: string;
    FOnProgreso: TWorkerProgresoEvent;
    FOnFinalizar: TWorkerFinalizarEvent;
    FFabricaPersistencia: IFabricaPersistenciaBackup;
    function CrearFlujoRestauracion: TStream;
    procedure ActualizarEtapaAperturaCopia(
      AEtapa: TEtapaAperturaCopia);
    procedure EjecutarSQLStreaming(
      const APersistencia: IPersistenciaRestauracionBackup);
    procedure ActualizarProgresoSQL(
      APosicion, ATotal, ASentencias: Integer);
    procedure ComprobarCancelacion;
    procedure RegistrarExcepcion(E: Exception);
    procedure SyncProgreso;
    procedure SyncFinalizar;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AHost: string;
      APort: Integer;
      const ADatabase, AUser, APassword: string;
      const ARutaFichero: string;
      const APassDesencriptar: string;
      AModo: TModoProteccionCopia;
      const AFabricaPersistencia:
        IFabricaPersistenciaBackup = nil);
    destructor Destroy; override;
    property OnProgreso: TWorkerProgresoEvent
      read FOnProgreso write FOnProgreso;
    property OnFinalizar: TWorkerFinalizarEvent
      read FOnFinalizar write FOnFinalizar;
  end;

function CrearCopiaSeguridadBD(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  AModo: TModoProteccionCopia;
  const APassEncriptar: string;
  AOnProgreso: TWorkerProgresoEvent;
  out AError: string;
  const AFabricaPersistencia:
    IFabricaPersistenciaBackup = nil): TResultadoCopiaSeguridad;
function EsScriptCopiaSeguridadCompleto(
  const ARutaScript: string): Boolean;

implementation

uses
  Winapi.Windows,
  Core_Interfaces, ScriptWriters, System.IOUtils,
  inLibMsgConfiguracion;

const
  MARCADOR_FINAL_COPIA = '-- FZAM_FIN_COPIA_SEGURIDAD';
  TAMANO_COLA_VALIDACION = 64 * 1024;

type
  TFlujoScriptTemporal = class(TFileStream)
  private
    FRutaFichero: string;
  public
    constructor Create(const ARutaFichero: string);
    destructor Destroy; override;
  end;

constructor TFlujoScriptTemporal.Create(
  const ARutaFichero: string);
begin
  inherited Create(
    ARutaFichero,
    fmOpenRead or fmShareDenyWrite);
  FRutaFichero := ARutaFichero;
end;

destructor TFlujoScriptTemporal.Destroy;
var
  sRutaFichero: string;
begin
  sRutaFichero := FRutaFichero;
  inherited Destroy;
  if FileExists(sRutaFichero) then
    System.SysUtils.DeleteFile(sRutaFichero);
end;

function CrearConfiguracionConexion(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string):
  TConfiguracionConexionBackup;
begin
  Result := Default(TConfiguracionConexionBackup);
  Result.Host := AHost;
  Result.Puerto := APort;
  Result.BaseDatos := ADatabase;
  Result.Usuario := AUser;
  Result.Contrasena := APassword;
  Result.TimeoutConexionSeg :=
    TIMEOUT_CONEXION_PREDETERMINADO_SEG;
  Result.TimeoutComandoSeg :=
    TIMEOUT_COMANDO_PREDETERMINADO_SEG;
end;

function ResolverFabricaPersistencia(
  const AFabrica: IFabricaPersistenciaBackup):
  IFabricaPersistenciaBackup;
begin
  Result := AFabrica;
  if not Assigned(Result) then
  begin
    Result := CrearFabricaPersistenciaBackupPredeterminada;
  end;
end;

function CrearOpcionesBackup: TBackupOptions;
begin
  Result := Default(TBackupOptions);
  Result.WithData := True;
  Result.WithTriggers := True;
  Result.WithProcedures := True;
  Result.WithFunctions := True;
  Result.WithViews := True;
  Result.DropTablesFirst := True;
  Result.UseTransactions := True;
  Result.ExtendedInsert := True;
  Result.ExtendedInsertRows := 500;
end;

function CrearRutaScriptBackup(
  const ARutaFichero: string): string;
var
  sDirectorio: string;
begin
  sDirectorio := ExtractFilePath(ARutaFichero);
  if sDirectorio = '' then
    sDirectorio := GetCurrentDir;
  Result := TPath.Combine(
    sDirectorio,
    'viracash_sql_' + TGUID.NewGuid.ToString + '.tmp');
end;

function CrearRutaSalidaTemporal(
  const ARutaFichero: string): string;
var
  sDirectorio: string;
begin
  sDirectorio := ExtractFilePath(ARutaFichero);
  if sDirectorio = '' then
    sDirectorio := GetCurrentDir;
  Result := TPath.Combine(
    sDirectorio,
    'viracash_salida_' + TGUID.NewGuid.ToString + '.tmp');
end;

function CrearRutaScriptRestauracionTemporal: string;
begin
  Result := TPath.Combine(
    TPath.GetTempPath,
    'viracash_restauracion_' + TGUID.NewGuid.ToString + '.tmp');
end;

function EsScriptCopiaSeguridadCompleto(
  const ARutaScript: string): Boolean;
var
  aCola: TBytes;
  iIndice: Integer;
  iLeer: Integer;
  oLineas: TStringList;
  oScript: TFileStream;
  sUltimaLinea: string;
begin
  Result := False;
  if FileExists(ARutaScript) then
  begin
    oScript := TFileStream.Create(
      ARutaScript,
      fmOpenRead or fmShareDenyWrite);
    try
      if oScript.Size > 0 then
      begin
        iLeer := TAMANO_COLA_VALIDACION;
        if oScript.Size < iLeer then
          iLeer := Integer(oScript.Size);
        SetLength(aCola, iLeer);
        oScript.Position := oScript.Size - iLeer;
        oScript.ReadBuffer(aCola[0], iLeer);
        oLineas := TStringList.Create;
        try
          oLineas.Text := TEncoding.UTF8.GetString(aCola);
          iIndice := oLineas.Count - 1;
          while (iIndice >= 0) and
                (Trim(oLineas[iIndice]) = '') do
          begin
            Dec(iIndice);
          end;
          if iIndice >= 0 then
          begin
            sUltimaLinea := Trim(oLineas[iIndice]);
            Result := SameText(
              MARCADOR_FINAL_COPIA,
              sUltimaLinea);
          end;
        finally
          FreeAndNil(oLineas);
        end;
      end;
    finally
      FreeAndNil(oScript);
    end;
  end;
end;

procedure PublicarFicheroTemporal(
  const ARutaTemporal, ARutaDestino: string);
var
  oTemporal: TFileStream;
begin
  oTemporal := TFileStream.Create(
    ARutaTemporal,
    fmOpenReadWrite or fmShareDenyWrite);
  try
    if not FlushFileBuffers(oTemporal.Handle) then
      RaiseLastOSError;
  finally
    FreeAndNil(oTemporal);
  end;
  if not MoveFileEx(
    PChar(ARutaTemporal),
    PChar(ARutaDestino),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
  begin
    RaiseLastOSError;
  end;
end;

procedure GuardarCopiaGenerada(
  const ARutaScript, ARutaFichero, APassEncriptar: string;
  AModo: TModoProteccionCopia);
var
  sRutaTemporal: string;
begin
  sRutaTemporal := '';
  if AModo = mpcTextoPlano then
    PublicarFicheroTemporal(ARutaScript, ARutaFichero)
  else
  begin
    sRutaTemporal := CrearRutaSalidaTemporal(ARutaFichero);
    try
      case AModo of
        mpcZip:
          EmpaquetarCopiaSeguridadZipDesdeFichero(
            ARutaScript,
            sRutaTemporal);
        mpcCifrada:
          CifrarCopiaSeguridadComprimidaDesdeFichero(
            ARutaScript,
            sRutaTemporal,
            APassEncriptar);
      end;
      PublicarFicheroTemporal(sRutaTemporal, ARutaFichero);
    finally
      if FileExists(sRutaTemporal) then
      begin
        System.SysUtils.DeleteFile(sRutaTemporal);
      end;
    end;
  end;
end;

procedure NotificarGuardadoCopia(
  AModo: TModoProteccionCopia;
  AOnProgreso: TWorkerProgresoEvent);
var
  sEtapa: string;
begin
  if Assigned(AOnProgreso) then
  begin
    case AModo of
      mpcTextoPlano:
        sEtapa := SProgresoGuardandoCopiaTextoPlano;
      mpcZip:
        sEtapa := SProgresoComprimiendoCopiaZip;
      mpcCifrada:
        sEtapa := SProgresoComprimiendoCifrandoCopia;
    end;
    AOnProgreso(sEtapa, 1, 1, 1, 1);
  end;
end;

procedure GenerarCopia(
  const APersistencia: IPersistenciaCopiaBackup;
  const ARutaFichero, APassEncriptar: string;
  AModo: TModoProteccionCopia;
  AOnProgreso: TWorkerProgresoEvent);
var
  oEngine: TDBBackupEngine;
  oExcluirTablas: TStringList;
  oFiltrosDatos: TStringList;
  oIncluirTablas: TStringList;
  oWriter: IScriptWriter;
  sRutaDestino: string;
  sRutaScript: string;
begin
  oEngine := nil;
  oIncluirTablas := nil;
  oExcluirTablas := nil;
  oFiltrosDatos := nil;
  sRutaDestino := ExpandFileName(ARutaFichero);
  sRutaScript := '';
  try
    oIncluirTablas := TStringList.Create;
    oExcluirTablas := TStringList.Create;
    oFiltrosDatos := TStringList.Create;
    sRutaScript := CrearRutaScriptBackup(sRutaDestino);
    oFiltrosDatos.Values['fza_traducciones'] :=
      APersistencia.ObtenerFiltroTraducciones;
    oWriter := TScriptWriter.Create(sRutaScript);
    oEngine := TDBBackupEngine.Create(
      APersistencia.ObtenerServiciosLectura,
      oWriter,
      APersistencia.ObtenerServiciosSql,
      CrearOpcionesBackup,
      oIncluirTablas,
      oExcluirTablas,
      oFiltrosDatos);
    try
      oEngine.OnProgress := AOnProgreso;
      oEngine.GenerateBackup;
      FreeAndNil(oEngine);
      oWriter := nil;
      if not EsScriptCopiaSeguridadCompleto(sRutaScript) then
      begin
        raise Exception.Create(SErrorScriptCopiaIncompleto);
      end;
      NotificarGuardadoCopia(AModo, AOnProgreso);
      GuardarCopiaGenerada(
        sRutaScript,
        sRutaDestino,
        APassEncriptar,
        AModo);
    finally
      FreeAndNil(oEngine);
    end;
  finally
    oWriter := nil;
    if FileExists(sRutaScript) then
    begin
      System.SysUtils.DeleteFile(sRutaScript);
    end;
    FreeAndNil(oFiltrosDatos);
    FreeAndNil(oExcluirTablas);
    FreeAndNil(oIncluirTablas);
  end;
end;

function CrearCopiaSeguridadBD(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  AModo: TModoProteccionCopia;
  const APassEncriptar: string;
  AOnProgreso: TWorkerProgresoEvent;
  out AError: string;
  const AFabricaPersistencia: IFabricaPersistenciaBackup):
  TResultadoCopiaSeguridad;
var
  oFabrica: IFabricaPersistenciaBackup;
  oPersistencia: IPersistenciaCopiaBackup;
begin
  AError := '';
  oFabrica := ResolverFabricaPersistencia(AFabricaPersistencia);
  try
    oPersistencia := oFabrica.CrearCopia(
      CrearConfiguracionConexion(
        AHost,
        APort,
        ADatabase,
        AUser,
        APassword));
    oPersistencia.Preparar;
    GenerarCopia(
      oPersistencia,
      ARutaFichero,
      APassEncriptar,
      AModo,
      AOnProgreso);
    Result := rcsCompletada;
  except
    on E: Exception do
    begin
      if E is EAbort then
      begin
        AError := E.Message;
        Result := rcsCancelada;
      end
      else
      begin
        AError := E.ClassName + ': ' + E.Message;
        Result := rcsFallida;
      end;
    end;
  end;
end;

constructor TBackupWorker.Create(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  AModo: TModoProteccionCopia;
  const APassEncriptar: string;
  const AFabricaPersistencia: IFabricaPersistenciaBackup);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FHost := AHost;
  FPort := APort;
  FDatabase := ADatabase;
  FUser := AUser;
  FPassword := APassword;
  FRutaFichero := ARutaFichero;
  FModo := AModo;
  FPassEncriptar := APassEncriptar;
  FFabricaPersistencia := AFabricaPersistencia;
  FResultado := rcsFallida;
end;

procedure TBackupWorker.EngineProgress(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if Terminated then
  begin
    raise EAbort.Create(SErrorOperacionCanceladaUsuario);
  end;
  FProgresoEtapa := AEtapa;
  FProgresoPaso := APaso;
  FProgresoTotal := ATotal;
  FProgresoFilaGlobal := AFilaGlobal;
  FProgresoFilasGlobalTotal := AFilasGlobalTotal;
  Synchronize(SyncProgreso);
end;

procedure TBackupWorker.SyncProgreso;
begin
  if Assigned(FOnProgreso) then
  begin
    FOnProgreso(
      FProgresoEtapa,
      FProgresoPaso,
      FProgresoTotal,
      FProgresoFilaGlobal,
      FProgresoFilasGlobalTotal);
  end;
end;

procedure TBackupWorker.SyncFinalizar;
begin
  if Assigned(FOnFinalizar) then
  begin
    FOnFinalizar(FResultado, FError, nil);
  end;
end;

procedure TBackupWorker.Execute;
begin
  try
    FResultado := CrearCopiaSeguridadBD(
      FHost,
      FPort,
      FDatabase,
      FUser,
      FPassword,
      FRutaFichero,
      FModo,
      FPassEncriptar,
      EngineProgress,
      FError,
      FFabricaPersistencia);
  finally
    Synchronize(SyncFinalizar);
  end;
end;

constructor TRestoreWorker.Create(
  const AHost: string;
  APort: Integer;
  const ADatabase, AUser, APassword: string;
  const ARutaFichero: string;
  const APassDesencriptar: string;
  AModo: TModoProteccionCopia;
  const AFabricaPersistencia: IFabricaPersistenciaBackup);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FHost := AHost;
  FPort := APort;
  FDatabase := ADatabase;
  FUser := AUser;
  FPassword := APassword;
  FRutaFichero := ARutaFichero;
  FModo := AModo;
  FPassDesencriptar := APassDesencriptar;
  FFabricaPersistencia := AFabricaPersistencia;
  FResultado := rcsFallida;
  FProgresoEtapa := 'Restaurando';
  FLogBuffer := TStringList.Create;
end;

destructor TRestoreWorker.Destroy;
begin
  FreeAndNil(FLogBuffer);
  inherited Destroy;
end;

procedure TRestoreWorker.ComprobarCancelacion;
begin
  if Terminated then
  begin
    raise EAbort.Create(SErrorOperacionCanceladaUsuario);
  end;
end;

procedure TRestoreWorker.RegistrarExcepcion(E: Exception);
begin
  if E is EAbort then
  begin
    FResultado := rcsCancelada;
    FError := E.Message;
  end
  else
  begin
    FResultado := rcsFallida;
    FError := E.ClassName + ': ' + E.Message;
  end;
end;

function TRestoreWorker.CrearFlujoRestauracion: TStream;
var
  sRutaScript: string;
begin
  if FModo = mpcTextoPlano then
  begin
    Result := TFileStream.Create(
      FRutaFichero,
      fmOpenRead or fmShareDenyWrite);
  end
  else
  begin
    sRutaScript := CrearRutaScriptRestauracionTemporal;
    try
      if FModo = mpcCifrada then
      begin
        DescifrarCopiaSeguridadDesdeFichero(
          FRutaFichero,
          sRutaScript,
          FPassDesencriptar,
          ActualizarEtapaAperturaCopia);
      end
      else if FModo = mpcZip then
      begin
        DesempaquetarCopiaSeguridadZipDesdeFichero(
          FRutaFichero,
          sRutaScript);
      end;
      if (not FileExists(sRutaScript)) or
         (TFile.GetSize(sRutaScript) = 0) then
      begin
        raise Exception.Create(SErrorDesencriptarCopia);
      end;
      Result := TFlujoScriptTemporal.Create(sRutaScript);
    except
      if FileExists(sRutaScript) then
        System.SysUtils.DeleteFile(sRutaScript);
      raise;
    end;
  end;
end;

procedure TRestoreWorker.ActualizarEtapaAperturaCopia(
  AEtapa: TEtapaAperturaCopia);
begin
  case AEtapa of
    eacVerificandoIntegridad:
      FProgresoEtapa := SProgresoVerificandoIntegridad;
    eacIntegridadVerificada:
      FProgresoEtapa := SProgresoIntegridadVerificada;
    eacDescifrando:
      FProgresoEtapa := SProgresoDescifrandoCopia;
    eacValidandoContenido:
      FProgresoEtapa := SProgresoValidandoContenido;
  end;
  FPosicion := 0;
  FTotal := 0;
  Synchronize(SyncProgreso);
end;

procedure TRestoreWorker.ActualizarProgresoSQL(
  APosicion, ATotal, ASentencias: Integer);
begin
  FProgresoEtapa := 'Restaurando SQL';
  FPosicion := APosicion;
  FTotal := ATotal;
  FSentenciasEjecutadas := ASentencias;
  Synchronize(SyncProgreso);
end;

procedure TRestoreWorker.EjecutarSQLStreaming(
  const APersistencia: IPersistenciaRestauracionBackup);
var
  oEjecutor: TEjecutorRestauracionSQL;
  oFlujo: TStream;
begin
  oFlujo := CrearFlujoRestauracion;
  try
    FProgresoEtapa := 'Preparando la base de datos';
    FPosicion := 0;
    FTotal := 0;
    Synchronize(SyncProgreso);
    oEjecutor := TEjecutorRestauracionSQL.Create(
      APersistencia,
      ComprobarCancelacion,
      ActualizarProgresoSQL,
      FLogBuffer);
    try
      try
        oEjecutor.Ejecutar(oFlujo);
      finally
        FErrores := oEjecutor.Errores;
        FSentenciasEjecutadas := oEjecutor.SentenciasEjecutadas;
        FPrimerError := oEjecutor.PrimerError;
      end;
    finally
      FreeAndNil(oEjecutor);
    end;
  finally
    FreeAndNil(oFlujo);
  end;
end;

procedure TRestoreWorker.SyncProgreso;
var
  sEtapa: string;
begin
  sEtapa := FProgresoEtapa;
  if sEtapa = '' then
  begin
    sEtapa := 'Restaurando';
  end;
  if Assigned(FOnProgreso) then
  begin
    FOnProgreso(
      sEtapa,
      FPosicion,
      FTotal,
      FPosicion,
      FTotal);
  end;
end;

procedure TRestoreWorker.SyncFinalizar;
var
  stLog: TStringList;
begin
  stLog := FLogBuffer;
  FLogBuffer := nil;
  if Assigned(FOnFinalizar) then
  begin
    FOnFinalizar(FResultado, FError, stLog);
  end
  else
  begin
    FreeAndNil(stLog);
  end;
end;

procedure TRestoreWorker.Execute;
var
  oFabrica: IFabricaPersistenciaBackup;
  oPersistencia: IPersistenciaRestauracionBackup;
begin
  try
    try
      if Trim(FDatabase) = '' then
      begin
        raise Exception.Create(SErrorNombreBBDDDestinoVacio);
      end;
      if not FileExists(FRutaFichero) then
      begin
        raise Exception.Create(Format(
          SErrorFicheroCopiaNoExiste,
          [FRutaFichero]));
      end;
      ComprobarCancelacion;
      FProgresoEtapa := 'Conectando para restaurar';
      FPosicion := 0;
      FTotal := 0;
      Synchronize(SyncProgreso);
      oFabrica := ResolverFabricaPersistencia(FFabricaPersistencia);
      oPersistencia := oFabrica.CrearRestauracion(
        CrearConfiguracionConexion(
          FHost,
          FPort,
          FDatabase,
          FUser,
          FPassword));
      EjecutarSQLStreaming(oPersistencia);
      ComprobarCancelacion;
      FResultado := rcsCompletada;
    except
      on E: Exception do
      begin
        RegistrarExcepcion(E);
      end;
    end;
  finally
    if (FError = '') and (FResultado = rcsFallida) then
    begin
      if FPrimerError <> '' then
      begin
        FError := FPrimerError;
      end
      else
      begin
        FError := SErrorRestauracionNoFinalizada;
      end;
    end;
    Synchronize(SyncFinalizar);
  end;
end;

end.
