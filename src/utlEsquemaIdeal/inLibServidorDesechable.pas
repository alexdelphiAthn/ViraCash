{******************************************************************************}
{                                                                              }
{  Módulo:       inLibServidorDesechable                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Servidor MariaDB 12, MariaDB 10 o MySQL 8 de usar y tirar: crea su        }
{    carpeta de datos, lo arranca en un puerto libre de 127.0.0.1, carga       }
{    scripts con el cliente del propio motor y lo para.                        }
{******************************************************************************}
unit inLibServidorDesechable;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  Uni;

type
  TMotorDesechable = (mdMariaDB12, mdMariaDB10, mdMySQL8);

  EServidorDesechable = class(Exception);

  TServidorDesechable = class
  private
    FMotor: TMotorDesechable;
    FBinarios: string;
    FRaiz: string;
    FPuerto: Integer;
    FProceso: TProcessInformation;
    FArrancado: Boolean;
    function Programa(const ANombre: string): string;
    function CarpetaBase: string;
    function OpcionesComunes: string;
    procedure Inicializar(const ADatos: string);
    procedure Esperar;
  public
    constructor Create(
      AMotor: TMotorDesechable;
      const ABinarios, ARaiz: string);
    destructor Destroy; override;
    procedure Arrancar;
    procedure Parar;
    function Conectar(const ABase: string): TUniConnection;
    procedure CrearBase(const ABase: string);
    // Carga un script con el cliente del motor (mariadb.exe o mysql.exe),
    // como se haría a mano: admite DELIMITER y volcados enteros.
    procedure CargarScript(const ARuta, ABase: string);
    property Motor: TMotorDesechable read FMotor;
    property Puerto: Integer read FPuerto;
  end;

// Ejecuta una orden sin ventana y espera. AEntrada, si no es vacía, es el
// fichero que recibe por la entrada estándar; la salida y los errores van
// a ASalida. Devuelve el código de salida.
function EjecutarProceso(
  const AOrden, ADirectorio, AEntrada, ASalida: string): Cardinal;
function PuertoLibre: Integer;
function TextoMotorDesechable(AMotor: TMotorDesechable): string;

implementation

uses
  Winapi.WinSock,
  Data.DB,
  System.IOUtils,
  System.Diagnostics,
  MySQLUniProvider;

const
  cEsperaArranqueMs = 120000;
  cEsperaParadaMs = 60000;

function TextoMotorDesechable(AMotor: TMotorDesechable): string;
const
  cTextos: array[TMotorDesechable] of string = (
    'MariaDB 12',
    'MariaDB 10',
    'MySQL 8');
begin
  Result := cTextos[AMotor];
end;

function PuertoLibre: Integer;
var
  oDatos: TWSAData;
  hSocket: TSocket;
  oDireccion: TSockAddrIn;
  iLongitud: Integer;
begin
  // El sistema da un puerto libre al enlazar con el 0.
  if WSAStartup($0202, oDatos) <> 0 then
    raise EServidorDesechable.Create('No se puede iniciar Winsock');
  try
    hSocket := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    try
      FillChar(oDireccion, SizeOf(oDireccion), 0);
      oDireccion.sin_family := AF_INET;
      oDireccion.sin_addr.S_addr := inet_addr('127.0.0.1');
      oDireccion.sin_port := 0;
      iLongitud := SizeOf(oDireccion);
      if (bind(hSocket, oDireccion, SizeOf(oDireccion)) <> 0) or
         (getsockname(hSocket, oDireccion, iLongitud) <> 0) then
        raise EServidorDesechable.Create('No hay un puerto libre');
      Result := ntohs(oDireccion.sin_port);
    finally
      closesocket(hSocket);
    end;
  finally
    WSACleanup;
  end;
end;

function AbrirHeredable(const ARuta: string; AEscritura: Boolean): THandle;
var
  oSeguridad: TSecurityAttributes;
begin
  oSeguridad.nLength := SizeOf(oSeguridad);
  oSeguridad.lpSecurityDescriptor := nil;
  oSeguridad.bInheritHandle := True;
  if AEscritura then
    Result := CreateFile(PChar(ARuta), GENERIC_WRITE, FILE_SHARE_READ,
                         @oSeguridad, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0)
  else
    Result := CreateFile(PChar(ARuta), GENERIC_READ, FILE_SHARE_READ,
                         @oSeguridad, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if Result = INVALID_HANDLE_VALUE then
    raise EServidorDesechable.CreateFmt('No se puede abrir %s: %s',
                                        [ARuta, SysErrorMessage(GetLastError)]);
end;

function Lanzar(
  const AOrden, ADirectorio: string;
  AEntrada, ASalida: THandle): TProcessInformation;
var
  oInicio: TStartupInfo;
  sOrden: string;
begin
  FillChar(oInicio, SizeOf(oInicio), 0);
  oInicio.cb := SizeOf(oInicio);
  oInicio.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
  oInicio.wShowWindow := SW_HIDE;
  oInicio.hStdInput := AEntrada;
  oInicio.hStdOutput := ASalida;
  oInicio.hStdError := ASalida;
  sOrden := AOrden;
  UniqueString(sOrden);
  if not CreateProcess(nil, PChar(sOrden), nil, nil, True, CREATE_NO_WINDOW,
                       nil, PChar(ADirectorio), oInicio, Result) then
    raise EServidorDesechable.CreateFmt(
      'No se puede lanzar %s: %s',
      [AOrden, SysErrorMessage(GetLastError)]);
end;

function EjecutarProceso(
  const AOrden, ADirectorio, AEntrada, ASalida: string): Cardinal;
var
  hEntrada, hSalida: THandle;
  oProceso: TProcessInformation;
begin
  hEntrada := 0;
  if AEntrada <> '' then
    hEntrada := AbrirHeredable(AEntrada, False);
  try
    hSalida := AbrirHeredable(ASalida, True);
    try
      oProceso := Lanzar(AOrden, ADirectorio, hEntrada, hSalida);
      try
        WaitForSingleObject(oProceso.hProcess, INFINITE);
        GetExitCodeProcess(oProceso.hProcess, Result);
      finally
        CloseHandle(oProceso.hThread);
        CloseHandle(oProceso.hProcess);
      end;
    finally
      CloseHandle(hSalida);
    end;
  finally
    if hEntrada <> 0 then
      CloseHandle(hEntrada);
  end;
end;

{ TServidorDesechable }

constructor TServidorDesechable.Create(
  AMotor: TMotorDesechable;
  const ABinarios, ARaiz: string);
begin
  inherited Create;
  FMotor := AMotor;
  FBinarios := ExcludeTrailingPathDelimiter(ABinarios);
  FRaiz := ARaiz;
  TDirectory.CreateDirectory(FRaiz);
  FPuerto := PuertoLibre;
end;

destructor TServidorDesechable.Destroy;
begin
  Parar;
  inherited;
end;

function TServidorDesechable.Programa(const ANombre: string): string;
begin
  Result := TPath.Combine(FBinarios, ANombre);
  if not FileExists(Result) then
    raise EServidorDesechable.CreateFmt('%s: no existe %s',
                                        [TextoMotorDesechable(FMotor),
                                         Result]);
end;

function TServidorDesechable.CarpetaBase: string;
begin
  // Sin barra final: dentro de comillas, \" escaparía la comilla de cierre
  // al partir la línea de órdenes.
  Result := ExcludeTrailingPathDelimiter(ExtractFilePath(FBinarios));
end;

function TServidorDesechable.OpcionesComunes: string;
var
  sTemporal: string;
begin
  // Temporales propios: con %TEMP% compartido entre varios servidores
  // MariaDB llegó a fallar al borrar un #sql-temptable interno.
  sTemporal := TPath.Combine(FRaiz, 'tmp');
  TDirectory.CreateDirectory(sTemporal);
  Result := Format(' --port=%d --bind-address=127.0.0.1 --tmpdir="%s"' +
                   ' --character-set-server=utf8mb4' +
                   ' --collation-server=utf8mb4_spanish_ci',
                   [FPuerto, sTemporal]);
end;

procedure TServidorDesechable.Inicializar(const ADatos: string);
var
  sOrden: string;
begin
  case FMotor of
    mdMariaDB12:
      sOrden := Format('"%s" --datadir="%s"',
                       [Programa('mariadb-install-db.exe'), ADatos]);
    mdMariaDB10:
      sOrden := Format('"%s" --datadir="%s"',
                       [Programa('mysql_install_db.exe'), ADatos]);
  else
    sOrden := Format('"%s" --no-defaults --basedir="%s" --datadir="%s"' +
                     ' --lower_case_table_names=1 --initialize-insecure',
                     [Programa('mysqld.exe'), CarpetaBase, ADatos]);
  end;
  if EjecutarProceso(sOrden, FRaiz, '',
                     TPath.Combine(FRaiz, 'inicializar.log')) <> 0 then
    raise EServidorDesechable.CreateFmt(
      '%s: no se pudo crear la carpeta de datos (ver %s)',
      [TextoMotorDesechable(FMotor),
       TPath.Combine(FRaiz, 'inicializar.log')]);
end;

procedure TServidorDesechable.Arrancar;
var
  sDatos, sOrden: string;
  hSalida: THandle;
begin
  sDatos := TPath.Combine(FRaiz, 'datos');
  Inicializar(sDatos);
  case FMotor of
    mdMariaDB12:
      sOrden := Format('"%s" --no-defaults --datadir="%s"',
                       [Programa('mariadbd.exe'), sDatos]);
    mdMariaDB10:
      sOrden := Format('"%s" --no-defaults --datadir="%s"',
                       [Programa('mysqld.exe'), sDatos]);
  else
    sOrden := Format('"%s" --no-defaults --basedir="%s" --datadir="%s"' +
                     ' --lower_case_table_names=1 --mysqlx=OFF' +
                     ' --sql-mode=NO_AUTO_VALUE_ON_ZERO,' +
                     'NO_ENGINE_SUBSTITUTION' +
                     ' --log-bin-trust-function-creators=1',
                     [Programa('mysqld.exe'), CarpetaBase, sDatos]);
  end;
  hSalida := AbrirHeredable(TPath.Combine(FRaiz, 'servidor.log'), True);
  try
    FProceso := Lanzar(sOrden + OpcionesComunes, FRaiz, 0, hSalida);
    FArrancado := True;
  finally
    CloseHandle(hSalida);
  end;
  Esperar;
end;

procedure TServidorDesechable.Esperar;
var
  oCronometro: TStopwatch;
  oConexion: TUniConnection;
  bListo: Boolean;
  iCodigo: Cardinal;
begin
  bListo := False;
  oCronometro := TStopwatch.StartNew;
  while not bListo and
        (oCronometro.ElapsedMilliseconds < cEsperaArranqueMs) do
  begin
    GetExitCodeProcess(FProceso.hProcess, iCodigo);
    if iCodigo <> STILL_ACTIVE then
      raise EServidorDesechable.CreateFmt(
        '%s terminó al arrancar (código %d); ver %s',
        [TextoMotorDesechable(FMotor), iCodigo,
         TPath.Combine(FRaiz, 'servidor.log')]);
    try
      oConexion := Conectar('');
      oConexion.Free;
      bListo := True;
    except
      on EDatabaseError do
        Sleep(500);
    end;
  end;
  if not bListo then
    raise EServidorDesechable.CreateFmt('%s no acepta conexiones',
                                        [TextoMotorDesechable(FMotor)]);
end;

function TServidorDesechable.Conectar(const ABase: string): TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  try
    Result.ProviderName := 'MySQL';
    Result.Server := '127.0.0.1';
    Result.Port := FPuerto;
    Result.Username := 'root';
    Result.Password := '';
    Result.Database := ABase;
    Result.SpecificOptions.Values['UseUnicode'] := 'True';
    Result.SpecificOptions.Values['ConnectionTimeout'] := '2';
    Result.LoginPrompt := False;
    Result.Connect;
  except
    Result.Free;
    raise;
  end;
end;

procedure TServidorDesechable.CrearBase(const ABase: string);
var
  oConexion: TUniConnection;
begin
  oConexion := Conectar('');
  try
    oConexion.ExecSQL(Format('DROP DATABASE IF EXISTS `%s`', [ABase]));
    oConexion.ExecSQL(Format('CREATE DATABASE `%s` CHARACTER SET utf8mb4 ' +
                             'COLLATE utf8mb4_spanish_ci', [ABase]));
  finally
    oConexion.Free;
  end;
end;

procedure TServidorDesechable.CargarScript(const ARuta, ABase: string);
var
  sCliente, sSalida: string;
begin
  if FMotor = mdMariaDB12 then
    sCliente := Programa('mariadb.exe')
  else
    sCliente := Programa('mysql.exe');
  sSalida := TPath.Combine(FRaiz, 'carga_' +
                           TPath.GetFileNameWithoutExtension(ARuta) + '.log');
  if EjecutarProceso(
       Format('"%s" --protocol=tcp -h127.0.0.1 -P%d -uroot ' +
              '--default-character-set=utf8mb4 %s',
              [sCliente, FPuerto, ABase]),
       FRaiz, ARuta, sSalida) <> 0 then
    raise EServidorDesechable.CreateFmt(
      '%s: falló la carga de %s:%s%s',
      [TextoMotorDesechable(FMotor), ExtractFileName(ARuta), sLineBreak,
       Copy(TFile.ReadAllText(sSalida), 1, 2000)]);
end;

procedure TServidorDesechable.Parar;
var
  oConexion: TUniConnection;
begin
  if FArrancado then
  begin
    FArrancado := False;
    try
      oConexion := Conectar('');
      try
        oConexion.ExecSQL('SHUTDOWN');
      finally
        oConexion.Free;
      end;
    except
      on EDatabaseError do
        TerminateProcess(FProceso.hProcess, 1);
    end;
    if WaitForSingleObject(FProceso.hProcess, cEsperaParadaMs) <>
       WAIT_OBJECT_0 then
      TerminateProcess(FProceso.hProcess, 1);
    CloseHandle(FProceso.hThread);
    CloseHandle(FProceso.hProcess);
  end;
end;

end.
