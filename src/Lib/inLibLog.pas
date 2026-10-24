{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLog                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Sistema de log con rotación y exclusión mutua entre procesos.             }
{    Niveles informativo, aviso, error y SQL, con retención configurable.      }
{******************************************************************************}
unit inLibLog;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, //inLibGlobalVar,
  inLibDir, Windows, System.SyncObjs, Winapi.Messages,
  System.TypInfo, System.Zip, System.Generics.Collections,
  inLibMonitorSQLIntf, inLibParametrosIntf, inLibLogIntf;

const
  DEFAULT_LOG_RETENTION = 10;
  // Cada instancia escribe en su propio archivo, así que el mutex de
  // escritura solo tiene que excluir a quien comparta ese archivo. Uno
  // global serializaría todas las sesiones de un servidor de
  // terminales (y las demás aplicaciones de la casa) sin motivo.
  PREFIJO_MUTEX_ESCRITURA = 'Local\ViraCashLogEscritura_';
  // La rotación usa su propio mutex: comprimir puede tardar segundos y,
  // compartiendo el de escritura, dejaba a las demás instancias sin
  // escribir hasta agotar el tiempo de espera.
  MUTEX_ROTACION_NAME = 'Global\RotateFileLogMutex';
  // Cada instancia publica un mutex con el nombre de su archivo de log.
  // Mientras exista, ese archivo está vivo: ni se archiva ni se borra.
  PREFIJO_MUTEX_LOG_EN_USO = 'Global\ViraCashLogEnUso_';
  MUTEX_TIMEOUT = 5000; // 5 segundos de timeout

type
  // ltPerf: instrumentación de cronómetros (LogPerf). Apagado por defecto
  // para no ensuciar el log; se enciende con appModoDebug.
  // ltAvanzado: eventos de UI / dataset (LogEvento). Se enciende con
  // appLogAvanzado.
  TLogType = (ltInfo, ltWarning, ltError, ltSQL, ltPerf, ltAvanzado);
  TLogFlags = set of TLogType;
  TLog = class
  private
    FLogFileName: string;
    FCarpetaLog: string;
    FLogFlags: TLogFlags;
    FInstanceID: string;
    FLogRetention: Integer;
    FMutexHandle: THandle;
    FMutexRotacion: THandle;
    FMutexEnUso: THandle;
    FMonitorSQL: IServicioMonitorSQL;
    function LogTypeToString(ALogType: TLogType): string;
    procedure WriteToLog(const AMessage: string; ALogType: TLogType);
    procedure WriteToLogInternal(const AMessage: string);
    procedure WriteInitialInfo;
    function GenerateInstanceID: string;
    procedure RotateLogs;
    function AcquireMutex(AMutex: THandle): Boolean;
    procedure ReleaseMutex(AMutex: THandle);
    function IsFileAccessible(const FileName: string): Boolean;
    function ClaveFechaLog(const AFecha: TDateTime): string;
    function CarpetaArchivoDia(const AFecha: TDateTime): string;
    function FechaZipAnterior(const AFileName: string;
                              out AFecha: TDateTime): Boolean;
    procedure ConsolidarZipAnterior(const AZipAnterior: string;
                                    const AFechaLog: TDateTime);
    procedure ConsolidarZipsRepetidos;
    procedure ArchivarGrupoLogs(const AArchivos: TList<string>;
                                const AFechaLog: TDateTime);
    procedure BorrarLogArchivado(const ARuta: string; ATamano: Int64;
                                 const AModificado: TDateTime);
  public
    // ACarpetaLog vacío significa la carpeta de log de la aplicación.
    // Se puede fijar otra para probar la rotación sin tocar la real.
    constructor Create(ALogRetention: Integer = DEFAULT_LOG_RETENTION;
                       const ACarpetaLog: string = '');
    destructor Destroy; override;
    procedure LogInfo(const AMessage: string); overload;
    procedure LogWarning(const AMessage: string);
    procedure LogError(const AMessage: string);
    procedure LogSQL(const ASQL: string);
    // Version detallada del log SQL. Registra el SQL ya ejecutado junto
    // con su tiempo en ms, filas afectadas/devueltas y exito/fallo.
    // AParams es opcional: si viene relleno (clave=valor;clave=valor)
    // se anade tras la query. Pensado para que el invocador decida si
    // se loguean valores reales segun appLogParamsSQL.
    procedure LogSQLExt(const ASQL: string; AElapsedMs: Int64; ARows: Integer;
                        AOk: Boolean; const AError: string = '';
                        const AParams: string = '');
    // Log avanzado de eventos de usuario / UI. Una linea por evento con
    // unidad (modulo Pascal), objeto (form / control / dataset), evento
    // (Click, Show, BeforePost, Execute...) y un detalle libre.
    procedure LogEvento(const AUnidad, AObjeto, AEvento, ADetalle: string);
    // Cronometro instrumentado. Escribe al log para medir operaciones.
    // Patron tipico:
    //   sw := TStopwatch.StartNew;
    //   ...trabajo...
    //   Log.LogPerf('Articulos.AfterScroll', 'CargarPropiedades',
    //               sw.ElapsedMilliseconds);
    procedure LogPerf(const ATag, ADetalle: string; AElapsedMs: Int64);
    procedure EnableLogType(ALogType: TLogType);
    procedure DisableLogType(ALogType: TLogType);
    function IsLogTypeEnabled(ALogType: TLogType): Boolean;
    procedure ActivarDiagnosticoCompleto;
    procedure AsignarMonitorSQL(
      const AMonitorSQL: IServicioMonitorSQL);
    property InstanceID: string read FInstanceID;
    property ArchivoActual: string read FLogFileName;
  end;

function Log: TLog;
function CrearRegistroLog: IRegistroLog;
procedure LiberarLog;

// Nombre del mutex con el que una instancia marca su archivo de log como
// en uso. Público para diagnóstico y para las pruebas de rotación.
function NombreMutexLogEnUso(const ARutaLog: string): string;
// Nombre del mutex que serializa la escritura de un archivo de log.
function NombreMutexEscrituraLog(const ARutaLog: string): string;
// Indica si un proceso vivo está escribiendo ese archivo de log.
function LogEnUso(const ARutaLog: string): Boolean;

// Aplica los flags de depuración al log y al monitor SQL inyectado.
// Es idempotente y se invoca al cargar o recargar los parámetros.
procedure AplicarModosDepuracion(
  const AParametros: IParametrosAplicacion);

implementation

uses
  System.DateUtils, System.Generics.Defaults, inLibWin,
  inLibGlobalVar, inLibMsgComun, inLibMsgConfiguracion;

type
  TLogFileInfo = record
    Ruta: string;
    FechaLog: TDateTime;
    FechaOrden: TDateTime;
  end;

  // Huella del archivo en el momento de volcarlo al ZIP. Solo se borra
  // el original si sigue siendo el mismo cuando se cierra el ZIP.
  TLogArchivado = record
    Ruta: string;
    Tamano: Int64;
    Modificado: TDateTime;
  end;

  TAdaptadorRegistroLog = class(TInterfacedObject, IRegistroLog)
  private
    FLog: TLog;
  public
    constructor Create(ALog: TLog);
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

var
  FLog: TLog;

function Log: TLog;
begin
  Result := FLog;
end;

function CrearRegistroLog: IRegistroLog;
begin
  Result := TAdaptadorRegistroLog.Create(Log);
end;

procedure LiberarLog;
begin
  FreeAndNil(FLog);
end;

{ TAdaptadorRegistroLog }

constructor TAdaptadorRegistroLog.Create(ALog: TLog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('Log no proporcionado.');
  FLog := ALog;
end;

procedure TAdaptadorRegistroLog.RegistrarInformacion(
  const AMensaje: string);
begin
  FLog.LogInfo(AMensaje);
end;

procedure TAdaptadorRegistroLog.RegistrarAviso(
  const AMensaje: string);
begin
  FLog.LogWarning(AMensaje);
end;

procedure TAdaptadorRegistroLog.RegistrarError(
  const AMensaje: string);
begin
  FLog.LogError(AMensaje);
end;

procedure TAdaptadorRegistroLog.RegistrarRendimiento(
  const AEtiqueta, ADetalle: string;
  ADuracionMs: Int64);
begin
  FLog.LogPerf(AEtiqueta, ADetalle, ADuracionMs);
end;

procedure TAdaptadorRegistroLog.RegistrarEvento(
  const AUnidad, AObjeto, AEvento, ADetalle: string);
begin
  FLog.LogEvento(AUnidad, AObjeto, AEvento, ADetalle);
end;

procedure TAdaptadorRegistroLog.RegistrarSQL(
  const ASQL: string;
  ADuracionMs: Int64;
  AFilas: Integer;
  ACorrecto: Boolean;
  const AError, AParametros: string);
begin
  FLog.LogSQLExt(
    ASQL,
    ADuracionMs,
    AFilas,
    ACorrecto,
    AError,
    AParametros);
end;

function TAdaptadorRegistroLog.ObtenerEvidencias: TEvidenciasLog;
begin
  Result.RutaArchivo := FLog.ArchivoActual;
  Result.SQLActivo := FLog.IsLogTypeEnabled(ltSQL);
  Result.RendimientoActivo := FLog.IsLogTypeEnabled(ltPerf);
  Result.AvanzadoActivo := FLog.IsLogTypeEnabled(ltAvanzado);
end;

procedure TAdaptadorRegistroLog.ActivarDiagnosticoCompleto;
begin
  FLog.ActivarDiagnosticoCompleto;
end;

procedure TAdaptadorRegistroLog.AsignarMonitorSQL(
  const AMonitorSQL: IServicioMonitorSQL);
begin
  FLog.AsignarMonitorSQL(AMonitorSQL);
end;

procedure TAdaptadorRegistroLog.AplicarModosDepuracion(
  const AParametros: IParametrosAplicacion);
begin
  inLibLog.AplicarModosDepuracion(AParametros);
end;

function CompararInfoLog(const AIzquierda, ADerecha: TLogFileInfo): Integer;
begin
  if AIzquierda.FechaOrden < ADerecha.FechaOrden then
    Result := -1
  else if AIzquierda.FechaOrden > ADerecha.FechaOrden then
    Result := 1
  else
    Result := CompareText(AIzquierda.Ruta, ADerecha.Ruta);
end;

{ TLog }

function TLog.LogTypeToString(ALogType: TLogType): string;
begin
  case ALogType of
    ltInfo: Result := 'INFO';
    ltWarning: Result := 'WARNING';
    ltError: Result := 'ERROR';
    ltSQL: Result := 'SQL';
    ltPerf: Result := 'PERF';
    ltAvanzado: Result := 'AVANZADO';
  else
    Result := 'DESCONOCIDO';
  end;
end;

function TLog.AcquireMutex(AMutex: THandle): Boolean;
var
  WaitResult: DWORD;
begin
  Result := AMutex <> 0;
  if Result then
  begin
    WaitResult := WaitForSingleObject(AMutex, MUTEX_TIMEOUT);
    Result := (WaitResult = WAIT_OBJECT_0) or
              (WaitResult = WAIT_ABANDONED);
  end;
end;

procedure TLog.ReleaseMutex(AMutex: THandle);
begin
  if AMutex <> 0 then
    Windows.ReleaseMutex(AMutex);
end;

constructor TLog.Create(ALogRetention: Integer = DEFAULT_LOG_RETENTION;
                        const ACarpetaLog: string = '');
  function FileGetSize(const FileName: TFileName): Int64;
  var
   SearchRec: TSearchRec;
  begin
    if FindFirst(FileName, faAnyFile, SearchRec) = 0 then
    begin
      Result := SearchRec.Size;
      System.SysUtils.FindClose(SearchRec);
    end
    else
      Result := -1;
  end;
var
  IsNewFile: Boolean;
begin
  inherited Create;
  FInstanceID := GenerateInstanceID;
  FLogRetention := ALogRetention;
  if ACarpetaLog = '' then
    FCarpetaLog := GetLogFolder
  else
  begin
    FCarpetaLog := IncludeTrailingPathDelimiter(ACarpetaLog);
    ForceDirectories(FCarpetaLog + 'archive\');
  end;
  FLogFileName := TPath.Combine(FCarpetaLog, 'LOG_' +
                                FormatDateTime('yyyy_mm_dd_hhnnss', Now) +
                                '_' + FInstanceID + '.log');
  if not IsFileAccessible(FLogFileName) then
    raise Exception.CreateFmt(SErrorAccesoFicheroLog,
                              [FLogFileName]);
  FMutexHandle := CreateMutex(
    nil, False, PChar(NombreMutexEscrituraLog(FLogFileName)));
  if FMutexHandle = 0 then
    raise Exception.Create(
      Format(SErrorCrearMutexLog,
             [NombreMutexEscrituraLog(FLogFileName)]));
  FMutexRotacion := CreateMutex(nil, False, PChar(MUTEX_ROTACION_NAME));
  // La marca de "en uso" se publica antes de rotar para que ninguna otra
  // instancia pueda archivar y borrar este archivo mientras se escribe.
  FMutexEnUso := CreateMutex(nil, False,
                             PChar(NombreMutexLogEnUso(FLogFileName)));
  // SQL logging desactivado por defecto
  FLogFlags := [ltInfo, ltWarning, ltError];
  IsNewFile := (FileGetSize(FLogFileName) = 0);
  if IsNewFile then
    WriteInitialInfo;
  WriteToLog('Inicio de sesión de log.', ltInfo);
  if FMutexEnUso = 0 then
    WriteToLog('WARNING: No se pudo marcar el archivo de log como en uso; ' +
               'otra instancia podría archivarlo mientras se escribe.',
               ltWarning);
  if FMutexRotacion = 0 then
    WriteToLog('WARNING: No se pudo crear el mutex de rotación de logs.',
               ltWarning);
  RotateLogs;
end;

function TLog.GenerateInstanceID: string;
var
  GUID: TGUID;
begin
  if (CreateGUID(GUID) = S_OK) then
    Result := GUIDToString(GUID)
  else
    Result := IntToStr(DateTimeToUnix(Now, False)) + IntToStr(GetTickCount);
end;

destructor TLog.Destroy;
begin
  try
    try
      WriteToLog('Fin de sesión de log.', ltInfo);
    except
      // Un destructor no debe propagar un fallo secundario del propio log.
      FLogFlags := [];
    end;
  finally
    try
      FMonitorSQL := nil;
    finally
      if FMutexHandle <> 0 then
      begin
        CloseHandle(FMutexHandle);
        FMutexHandle := 0;
      end;
      if FMutexRotacion <> 0 then
      begin
        CloseHandle(FMutexRotacion);
        FMutexRotacion := 0;
      end;
      // Al soltar la marca, el archivo queda archivable por cualquier
      // instancia; el sistema la suelta igual si el proceso muere.
      if FMutexEnUso <> 0 then
      begin
        CloseHandle(FMutexEnUso);
        FMutexEnUso := 0;
      end;
      inherited;
    end;
  end;
end;

procedure TLog.AsignarMonitorSQL(
  const AMonitorSQL: IServicioMonitorSQL);
begin
  FMonitorSQL := AMonitorSQL;
end;

procedure TLog.WriteToLogInternal(const AMessage: string);
var
  LogFile: TextFile;
begin
  if AcquireMutex(FMutexHandle) then
  try
    AssignFile(LogFile, FLogFileName);
    try
      if FileExists(FLogFileName) then
        Append(LogFile)
      else
        Rewrite(LogFile);
      WriteLn(LogFile, Format('%s - [Instance: %s] %s',
                              [FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
                               FInstanceID,
                               AMessage]));
    finally
      CloseFile(LogFile);
    end;
  finally
    ReleaseMutex(FMutexHandle);
  end;
end;

function TLog.IsFileAccessible(const FileName: string): Boolean;
var
  FileHandle: THandle;
begin
  FileHandle := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_ALWAYS,
    FILE_ATTRIBUTE_NORMAL,
    0);
  Result := FileHandle <> INVALID_HANDLE_VALUE;
  if Result then
    CloseHandle(FileHandle);
end;

procedure TLog.WriteInitialInfo;
begin
  WriteToLogInternal('-------- Nuevo fichero de log --------');
  WriteToLogInternal('Fecha: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
  WriteToLogInternal('Nombre del equipo: ' + GetComputerName);
  WriteToLogInternal('Usuario de Windows: ' + GetWindowsUserName);
  WriteToLogInternal('Versión de Windows: ' + GetWindowsVersion);
  WriteToLogInternal('Ruta del programa: ' + GetProgramPath);
  WriteToLogInternal('Carpeta de log: ' + FCarpetaLog);
  WriteToLogInternal('Version de viracash: ' + inLibGlobalVar.oVersion);
  WriteToLogInternal('-------------------------------');
end;
procedure TLog.LogInfo(const AMessage: string);
begin
  WriteToLog('INFO: ' + AMessage, ltInfo);
end;

procedure TLog.LogWarning(const AMessage: string);
begin
  WriteToLog('WARNING: ' + AMessage, ltWarning);
end;

procedure TLog.LogError(const AMessage: string);
begin
  WriteToLog('ERROR: ' + AMessage, ltError);
end;

procedure TLog.LogSQL(const ASQL: string);
var
  SQLOneLine: string;
begin
  SQLOneLine := StringReplace(ASQL, sLineBreak, ' ', [rfReplaceAll]);
  SQLOneLine := Trim(SQLOneLine);
  WriteToLog('SQL: ' + SQLOneLine, ltSQL);
end;

procedure TLog.LogSQLExt(const ASQL: string; AElapsedMs: Int64; ARows: Integer;
                         AOk: Boolean; const AError: string = '';
                         const AParams: string = '');
var
  SQLOneLine, sEstado, sFilas, sLinea: string;
begin
  if ltSQL in FLogFlags then
  begin
  SQLOneLine := StringReplace(ASQL, sLineBreak, ' ', [rfReplaceAll]);
  SQLOneLine := Trim(SQLOneLine);

  if AOk then
    sEstado := 'OK'
  else
    sEstado := 'ERR';

  if ARows >= 0 then
    sFilas := IntToStr(ARows)
  else
    sFilas := '-';

  sLinea := Format('SQL: [%s] %d ms | filas=%s | %s',
                   [sEstado, AElapsedMs, sFilas, SQLOneLine]);

  if AParams <> '' then
    sLinea := sLinea + ' | params=' + AParams;

  if not AOk and (AError <> '') then
    sLinea := sLinea + ' | error=' + AError;

  WriteToLog(sLinea, ltSQL);
  end;
end;

procedure TLog.LogEvento(const AUnidad, AObjeto, AEvento, ADetalle: string);
var
  sLinea: string;
begin
  if ltAvanzado in FLogFlags then
  begin
    sLinea := Format('EVT: %s | %s | %s', [AUnidad, AObjeto, AEvento]);
    if ADetalle <> '' then
      sLinea := sLinea + ' | ' +
        StringReplace(ADetalle, sLineBreak, ' ', [rfReplaceAll]);
    WriteToLog(sLinea, ltAvanzado);
  end;
end;

procedure TLog.LogPerf(const ATag, ADetalle: string; AElapsedMs: Int64);
begin
  // Gateado por ltPerf: si appModoDebug está apagado, esta llamada es no-op.
  // Solo al archivo de log general: TLog.WriteToLog ya es thread-safe.
  // El visor SQL pertenece a la UI y no recibe métricas desde workers.
  WriteToLog(Format('[PERF:%s] %s | %d ms',
                    [ATag, ADetalle, AElapsedMs]),
             ltPerf);
end;

procedure TLog.EnableLogType(ALogType: TLogType);
begin
  Include(FLogFlags, ALogType);
end;

procedure TLog.DisableLogType(ALogType: TLogType);
begin
  Exclude(FLogFlags, ALogType);
end;

function TLog.IsLogTypeEnabled(ALogType: TLogType): Boolean;
begin
  Result := ALogType in FLogFlags;
end;

procedure TLog.ActivarDiagnosticoCompleto;
begin
  EnableLogType(ltSQL);
  EnableLogType(ltPerf);
  EnableLogType(ltAvanzado);
  if Assigned(FMonitorSQL) then
    FMonitorSQL.EstablecerActivo(True);
  LogInfo(
    'Diagnóstico completo activado desde la pantalla de error');
end;

function NombreMutexEscrituraLog(const ARutaLog: string): string;
begin
  // Del mismo nombre de archivo que la marca de uso, pero de la sesión:
  // dos sesiones nunca escriben el mismo log.
  Result := PREFIJO_MUTEX_ESCRITURA + ExtractFileName(ARutaLog);
end;

function NombreMutexLogEnUso(const ARutaLog: string): string;
begin
  // El nombre del archivo ya es único (fecha, hora y GUID de instancia) y
  // no lleva barras, lo único que Windows no admite en el nombre de un
  // objeto de sincronización.
  Result := PREFIJO_MUTEX_LOG_EN_USO + ExtractFileName(ARutaLog);
end;

function LogEnUso(const ARutaLog: string): Boolean;
var
  Marca: THandle;
begin
  Marca := OpenMutex(SYNCHRONIZE, False,
                     PChar(NombreMutexLogEnUso(ARutaLog)));
  Result := Marca <> 0;
  if Result then
    CloseHandle(Marca)
  else
    // Existe pero es de otro usuario: también hay un proceso vivo.
    Result := GetLastError = ERROR_ACCESS_DENIED;
end;

function InfoArchivoLog(const ARuta: string): TLogFileInfo;
var
  sNombre: string;
  dFecha: TDateTime;
  dHora: TDateTime;
  dModificado: TDateTime;
  bConFecha: Boolean;
  bConHora: Boolean;

  function ProbarFecha(const ATexto: string; AAnioPrimero: Boolean;
                       out AFecha: TDateTime): Boolean;
  var
    iAnio: Integer;
    iMes: Integer;
    iDia: Integer;
    bFormato: Boolean;
  begin
    Result := False;
    AFecha := 0;
    if Length(ATexto) = 10 then
    begin
      if AAnioPrimero then
      begin
        bFormato := (ATexto[5] = '_') and (ATexto[8] = '_');
        if bFormato then
          bFormato := TryStrToInt(Copy(ATexto, 1, 4), iAnio) and
                      TryStrToInt(Copy(ATexto, 6, 2), iMes) and
                      TryStrToInt(Copy(ATexto, 9, 2), iDia);
      end
      else
      begin
        bFormato := (ATexto[3] = '_') and (ATexto[6] = '_');
        if bFormato then
          bFormato := TryStrToInt(Copy(ATexto, 1, 2), iDia) and
                      TryStrToInt(Copy(ATexto, 4, 2), iMes) and
                      TryStrToInt(Copy(ATexto, 7, 4), iAnio);
      end;
      if bFormato then
      begin
        try
          AFecha := EncodeDate(Word(iAnio), Word(iMes), Word(iDia));
          Result := True;
        except
          Result := False;
        end;
      end;
    end;
  end;

  function ProbarHora(const ATexto: string; out AHora: TDateTime): Boolean;
  var
    iHora: Integer;
    iMinuto: Integer;
    iSegundo: Integer;
  begin
    AHora := 0;
    Result := (Length(ATexto) = 6) and
              TryStrToInt(Copy(ATexto, 1, 2), iHora) and
              TryStrToInt(Copy(ATexto, 3, 2), iMinuto) and
              TryStrToInt(Copy(ATexto, 5, 2), iSegundo);
    if Result then
      Result := (iHora >= 0) and (iHora <= 23) and
                (iMinuto >= 0) and (iMinuto <= 59) and
                (iSegundo >= 0) and (iSegundo <= 59);
    if Result then
      AHora := EncodeTime(Word(iHora), Word(iMinuto), Word(iSegundo), 0);
  end;

begin
  Result.Ruta := ARuta;
  dFecha := 0;
  dHora := 0;
  bConFecha := False;
  bConHora := False;
  sNombre := TPath.GetFileNameWithoutExtension(ARuta);
  if (Length(sNombre) >= 14) and SameText(Copy(sNombre, 1, 4), 'LOG_') then
  begin
    bConFecha := ProbarFecha(Copy(sNombre, 5, 10), True, dFecha);
    if not bConFecha then
      bConFecha := ProbarFecha(Copy(sNombre, Length(sNombre) - 9, 10),
                               False, dFecha);
    if bConFecha and (Length(sNombre) >= 21) then
      bConHora := ProbarHora(Copy(sNombre, 16, 6), dHora);
  end;
  // La fecha del sistema solo se consulta si el nombre no la trae: es un
  // acceso a disco por archivo y la rotación recorre la carpeta entera
  // en cada arranque.
  if bConFecha and bConHora then
  begin
    Result.FechaLog := dFecha;
    Result.FechaOrden := dFecha + dHora;
  end
  else
  begin
    dModificado := TFile.GetLastWriteTime(ARuta);
    if bConFecha then
    begin
      Result.FechaLog := dFecha;
      Result.FechaOrden := dFecha + Frac(dModificado);
    end
    else
    begin
      Result.FechaLog := Trunc(dModificado);
      Result.FechaOrden := dModificado;
    end;
  end;
end;

function NombreEntradaLibre(const AZip: TZipFile; const ANombre: string;
                            ATamano: Int64;
                            out AYaEstaba: Boolean): string;
var
  sBase: string;
  sExtension: string;
  iEntrada: Integer;
  iCopia: Integer;
  bBuscando: Boolean;
begin
  sBase := TPath.GetFileNameWithoutExtension(ANombre);
  sExtension := TPath.GetExtension(ANombre);
  Result := ANombre;
  AYaEstaba := False;
  iCopia := 1;
  bBuscando := True;
  while bBuscando do
  begin
    iEntrada := AZip.IndexOf(Result);
    if iEntrada < 0 then
      bBuscando := False
    else if Int64(AZip.FileInfo[iEntrada].UncompressedSize64) = ATamano then
    begin
      // Ya estaba archivado tal cual: sobra en la carpeta de log.
      AYaEstaba := True;
      bBuscando := False;
    end
    else
    begin
      // Mismo nombre y distinto contenido: el archivo creció después de
      // archivarlo. Se guarda aparte en vez de perder lo nuevo.
      Result := Format('%s_%d%s', [sBase, iCopia, sExtension]);
      Inc(iCopia);
    end;
  end;
end;

function TLog.ClaveFechaLog(const AFecha: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', AFecha);
end;

function TLog.CarpetaArchivoDia(const AFecha: TDateTime): string;
begin
  Result := TPath.Combine(FCarpetaLog, 'archive');
  Result := TPath.Combine(Result, FormatDateTime('yyyy', AFecha));
  Result := TPath.Combine(Result, FormatDateTime('mm', AFecha));
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
end;

function TLog.FechaZipAnterior(const AFileName: string;
                               out AFecha: TDateTime): Boolean;
var
  sNombre: string;
  sFecha: string;
  iAnio: Integer;
  iMes: Integer;
  iDia: Integer;
  bFormato: Boolean;
begin
  Result := False;
  AFecha := 0;
  sNombre := TPath.GetFileNameWithoutExtension(AFileName);
  if (Length(sNombre) >= 13) and
     SameText(Copy(sNombre, 1, 5), 'Logs_') then
  begin
    // Se admiten los tres nombres que ha usado el programa:
    // Logs_yyyy-mm-dd (actual), Logs_yyyy_mm_dd y Logs_yyyymmdd.
    sFecha := Copy(sNombre, 6, 10);
    bFormato := (Length(sFecha) = 10) and
                ((sFecha[5] = '-') or (sFecha[5] = '_')) and
                (sFecha[8] = sFecha[5]);
    if bFormato then
      bFormato := TryStrToInt(Copy(sFecha, 1, 4), iAnio) and
                  TryStrToInt(Copy(sFecha, 6, 2), iMes) and
                  TryStrToInt(Copy(sFecha, 9, 2), iDia)
    else
    begin
      sFecha := Copy(sNombre, 6, 8);
      bFormato := (Length(sFecha) = 8) and
                  TryStrToInt(Copy(sFecha, 1, 4), iAnio) and
                  TryStrToInt(Copy(sFecha, 5, 2), iMes) and
                  TryStrToInt(Copy(sFecha, 7, 2), iDia);
    end;
    if bFormato then
    begin
      try
        AFecha := EncodeDate(Word(iAnio), Word(iMes), Word(iDia));
        Result := True;
      except
        Result := False;
      end;
    end;
  end;
end;

procedure TLog.ConsolidarZipAnterior(const AZipAnterior: string;
                                     const AFechaLog: TDateTime);
var
  ZipFileName: string;
  EntradaZip: string;
  ZipAnterior: TZipFile;
  ZipDiario: TZipFile;
  Datos: TBytes;
  I: Integer;
  bYaEstaba: Boolean;
  bCompletado: Boolean;
begin
  ZipFileName := TPath.Combine(CarpetaArchivoDia(AFechaLog),
                               'Logs_' + ClaveFechaLog(AFechaLog) + '.zip');
  // Si ya es el ZIP del día con el nombre actual no hay nada que hacer:
  // abrirlo contra sí mismo lo dejaría a medias.
  if not SameText(TPath.GetFullPath(AZipAnterior),
                  TPath.GetFullPath(ZipFileName)) then
  begin
    if not TZipFile.IsValid(AZipAnterior) then
      WriteToLog('WARNING: ZIP de logs anterior no válido: ' + AZipAnterior,
                 ltWarning)
    else if not TFile.Exists(ZipFileName) then
      TFile.Move(AZipAnterior, ZipFileName)
    else
    begin
      ZipAnterior := nil;
      ZipDiario := nil;
      bCompletado := True;
      try
        ZipAnterior := TZipFile.Create;
        ZipDiario := TZipFile.Create;
        ZipAnterior.Open(AZipAnterior, zmRead);
        ZipDiario.Open(ZipFileName, zmReadWrite);
        for I := 0 to ZipAnterior.FileCount - 1 do
        begin
          try
            EntradaZip := NombreEntradaLibre(
              ZipDiario, ZipAnterior.FileName[I],
              Int64(ZipAnterior.FileInfo[I].UncompressedSize64), bYaEstaba);
            if not bYaEstaba then
            begin
              ZipAnterior.Read(I, Datos);
              ZipDiario.Add(Datos, EntradaZip);
            end;
          except
            on E: Exception do
            begin
              bCompletado := False;
              WriteToLog('WARNING: No se pudo consolidar ' +
                         ZipAnterior.FileName[I] + ' desde ' + AZipAnterior +
                         ': ' + E.Message, ltWarning);
            end;
          end;
        end;
        ZipDiario.Close;
        ZipAnterior.Close;
        if bCompletado then
          TFile.Delete(AZipAnterior);
      finally
        try
          FreeAndNil(ZipDiario);
        finally
          FreeAndNil(ZipAnterior);
        end;
      end;
    end;
  end;
end;

procedure TLog.ConsolidarZipsRepetidos;
var
  CarpetaArchivo: string;
  ZipFiles: TArray<string>;
  dFechaLog: TDateTime;
  I: Integer;
begin
  CarpetaArchivo := TPath.Combine(FCarpetaLog, 'archive');
  if TDirectory.Exists(CarpetaArchivo) then
  begin
    // Recorre también los subdirectorios: los ZIP de versiones anteriores
    // (Logs_yyyymmdd y Logs_yyyy_mm_dd) ya vivían en archive\yyyy\mm, y
    // con el nombre actual se creaba otro ZIP del mismo día al lado, de
    // forma que un mismo log acababa repetido en dos o tres comprimidos.
    ZipFiles := TDirectory.GetFiles(CarpetaArchivo, 'Logs_*.zip',
                                    TSearchOption.soAllDirectories);
    for I := 0 to Length(ZipFiles) - 1 do
    begin
      try
        if FechaZipAnterior(ZipFiles[I], dFechaLog) then
          ConsolidarZipAnterior(ZipFiles[I], dFechaLog)
        else
          WriteToLog('WARNING: No se reconoce la fecha del ZIP de logs: ' +
                     ZipFiles[I], ltWarning);
      except
        on E: Exception do
          WriteToLog('WARNING: No se pudo consolidar el ZIP de logs ' +
                     ZipFiles[I] + ': ' + E.Message, ltWarning);
      end;
    end;
  end;
end;

procedure TLog.BorrarLogArchivado(const ARuta: string; ATamano: Int64;
                                  const AModificado: TDateTime);
begin
  try
    if TFile.Exists(ARuta) then
    begin
      // Entre el volcado al ZIP y el borrado el archivo ha podido volver
      // a la vida o crecer. En ese caso se conserva y la próxima rotación
      // lo archivará completo.
      if LogEnUso(ARuta) or
         (TFile.GetSize(ARuta) <> ATamano) or
         (TFile.GetLastWriteTime(ARuta) <> AModificado) then
        WriteToLog('WARNING: Log en uso al archivarlo, se conserva: ' +
                   ARuta, ltWarning)
      else
        TFile.Delete(ARuta);
    end;
  except
    on E: Exception do
      WriteToLog('WARNING: Log archivado pero no borrado ' + ARuta + ': ' +
                 E.Message, ltWarning);
  end;
end;

procedure TLog.ArchivarGrupoLogs(const AArchivos: TList<string>;
                                 const AFechaLog: TDateTime);
var
  ZipFileName: string;
  EntradaZip: string;
  Zip: TZipFile;
  Archivados: TList<TLogArchivado>;
  Archivado: TLogArchivado;
  bYaEstaba: Boolean;
  I: Integer;
begin
  if AArchivos.Count > 0 then
  begin
    ZipFileName := TPath.Combine(CarpetaArchivoDia(AFechaLog),
                                 'Logs_' + ClaveFechaLog(AFechaLog) + '.zip');
    Zip := nil;
    Archivados := nil;
    try
      Zip := TZipFile.Create;
      Archivados := TList<TLogArchivado>.Create;
      if TFile.Exists(ZipFileName) then
        Zip.Open(ZipFileName, zmReadWrite)
      else
        Zip.Open(ZipFileName, zmWrite);
      for I := 0 to AArchivos.Count - 1 do
      begin
        try
          Archivado.Ruta := AArchivos[I];
          Archivado.Tamano := TFile.GetSize(Archivado.Ruta);
          Archivado.Modificado := TFile.GetLastWriteTime(Archivado.Ruta);
          EntradaZip := NombreEntradaLibre(Zip,
                                           ExtractFileName(Archivado.Ruta),
                                           Archivado.Tamano, bYaEstaba);
          if not bYaEstaba then
            Zip.Add(Archivado.Ruta, EntradaZip);
          Archivados.Add(Archivado);
        except
          on E: Exception do
            WriteToLog('WARNING: No se pudo archivar ' + AArchivos[I] +
                       ': ' + E.Message, ltWarning);
        end;
      end;
      Zip.Close;
      // El borrado espera a tener el ZIP cerrado en disco.
      for I := 0 to Archivados.Count - 1 do
        BorrarLogArchivado(Archivados[I].Ruta, Archivados[I].Tamano,
                           Archivados[I].Modificado);
    finally
      try
        FreeAndNil(Zip);
      finally
        FreeAndNil(Archivados);
      end;
    end;
  end;
end;

procedure TLog.RotateLogs;
var
  LogFiles: TArray<string>;
  InfoFiles: TList<TLogFileInfo>;
  Grupo: TList<string>;
  Info: TLogFileInfo;
  sRutaPropia: string;
  I: Integer;
  iRetencion: Integer;
  iArchivar: Integer;
  dFechaGrupo: TDateTime;
  bHayGrupo: Boolean;
begin
  if AcquireMutex(FMutexRotacion) then
  try
    try
      ConsolidarZipsRepetidos;
      LogFiles := TDirectory.GetFiles(FCarpetaLog, '*.log');
      iRetencion := FLogRetention;
      if iRetencion < 1 then
        iRetencion := 1;
      iArchivar := Length(LogFiles) - iRetencion;
      if iArchivar > 0 then
      begin
        sRutaPropia := ExpandFileName(FLogFileName);
        InfoFiles := TList<TLogFileInfo>.Create;
        try
          for I := 0 to Length(LogFiles) - 1 do
          begin
            // Ni el log de esta instancia ni el de otra instancia viva:
            // su proceso lo sigue escribiendo y lo recrearía vacío tras
            // borrarlo, dejando una copia repetida en la carpeta.
            if (not SameText(ExpandFileName(LogFiles[I]), sRutaPropia)) and
               (not LogEnUso(LogFiles[I])) then
              InfoFiles.Add(InfoArchivoLog(LogFiles[I]));
          end;
          InfoFiles.Sort(TComparer<TLogFileInfo>.Construct(
            function(const AIzquierda, ADerecha: TLogFileInfo): Integer
            begin
              Result := CompararInfoLog(AIzquierda, ADerecha);
            end));
          if iArchivar > InfoFiles.Count then
            iArchivar := InfoFiles.Count;
          if iArchivar > 0 then
          begin
            Grupo := TList<string>.Create;
            try
              bHayGrupo := False;
              dFechaGrupo := 0;
              for I := 0 to iArchivar - 1 do
              begin
                Info := InfoFiles[I];
                if (not bHayGrupo) or
                   (Trunc(Info.FechaLog) <> Trunc(dFechaGrupo)) then
                begin
                  if bHayGrupo then
                  begin
                    ArchivarGrupoLogs(Grupo, dFechaGrupo);
                    Grupo.Clear;
                  end;
                  dFechaGrupo := Trunc(Info.FechaLog);
                  bHayGrupo := True;
                end;
                Grupo.Add(Info.Ruta);
              end;
              if bHayGrupo then
                ArchivarGrupoLogs(Grupo, dFechaGrupo);
            finally
              FreeAndNil(Grupo);
            end;
          end;
        finally
          FreeAndNil(InfoFiles);
        end;
      end;
    except
      on E: Exception do
        WriteToLog('WARNING: Error rotando logs: ' + E.Message, ltWarning);
    end;
  finally
    ReleaseMutex(FMutexRotacion);
  end;
end;

procedure TLog.WriteToLog(const AMessage: string; ALogType: TLogType);
begin
  if (ALogType in FLogFlags) then
  begin
   WriteToLogInternal(Format('%s - %s', [AMessage, LogTypeToString(ALogType)]));
  end;
end;

procedure AplicarModosDepuracion(
  const AParametros: IParametrosAplicacion);
var
  bDebug      : Boolean;
  bDebugSQL   : Boolean;
  bLogSQL     : Boolean;
  bLogAvanzado: Boolean;
  bSQLFinal   : Boolean;
begin
  if not Assigned(AParametros) then
    raise EArgumentNilException.Create(
      SErrorParametrosAplicacionNoProporcionados);
  // Flags 'Depuración' (modest-fermat-WUvkF): switches gordos.
  bDebug := AParametros.GetBool('appModoDebug', False);
  bDebugSQL :=
    AParametros.GetBool('appModoDebugSQL', False) or bDebug;
  // Flags 'Log' (great-wright-Xs8yZ): controles finos por tipo.
  bLogSQL := AParametros.GetBool('appLogSQL', False);
  bLogAvanzado :=
    AParametros.GetBool('appLogAvanzado', False);

  // ltSQL se enciende si CUALQUIERA de los modos relacionados con SQL
  // está activo. El cronómetro de UniSQLMonitor (LogSQLExt) y el dump
  // crudo (LogSQL) comparten el mismo flag.
  {$IFDEF DEBUG}
  // En compilaciones DEBUG forzamos siempre el modo SQL
  bSQLFinal := True;
  {$ELSE}
  bSQLFinal := bDebugSQL or bLogSQL;
  {$ENDIF}

  if bSQLFinal then
    Log.EnableLogType(ltSQL)
  else
    Log.DisableLogType(ltSQL);

  // Cronómetros LogPerf enganchados al modo debug general.
  if bDebug then
    Log.EnableLogType(ltPerf)
  else
    Log.DisableLogType(ltPerf);

  // Eventos de UI (LogEvento) controlados por su propio flag.
  if bLogAvanzado then
    Log.EnableLogType(ltAvanzado)
  else
    Log.DisableLogType(ltAvanzado);

  if Assigned(Log.FMonitorSQL) then
    Log.FMonitorSQL.EstablecerActivo(bSQLFinal);

  Log.LogInfo(Format(
    'Modos log aplicados: appModoDebug=%s, appModoDebugSQL=%s, ' +
    'appLogSQL=%s, appLogAvanzado=%s',
    [BoolToStr(bDebug,        True),
     BoolToStr(bDebugSQL,     True),
     BoolToStr(bLogSQL,       True),
     BoolToStr(bLogAvanzado,  True)]));
end;

initialization
  FLog := TLog.Create;
finalization
  LiberarLog;
end.
