{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDeteccionImpresora                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Detección diferida de una impresora por patrón en segundo plano.          }
{    La comparten la impresora de tickets y la de documentos.                  }
{******************************************************************************}
unit inLibDeteccionImpresora;

interface

uses
  System.SysUtils;

const
  cMaximoEsperaDeteccionImpresoraSegundos = 300;

type
  // Resuelve en segundo plano el nombre real de una impresora a partir del
  // patrón configurado: un nombre exacto de impresora instalada, varias
  // subcadenas separadas por ';' o DEBUG (sin búsqueda). La búsqueda
  // recorre las impresoras locales, las redirigidas por Terminal Server y
  // las de red, y reintenta durante la espera indicada porque en sesiones
  // remotas la impresora puede aparecer segundos después del arranque. El
  // resultado se conserva hasta la siguiente preparación. Lo comparten la
  // impresora de tickets (caja) y la de documentos (aplicación).
  IDetectorImpresora = interface
    ['{6F8EA4BE-502C-450D-A188-61A819F0367F}']
    // Invalida la detección en curso; la usa el propietario al liberarse.
    procedure Cancelar;
    // Lanza la búsqueda si aún no se inició para el patrón vigente.
    procedure IniciarDeteccion;
    // Fija patrón, archivo de caché y espera. Si ya hubo una preparación
    // anterior (recarga de parámetros) reinicia la detección de inmediato.
    procedure Preparar(
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer);
    // Impresora resuelta, DEBUG o cadena vacía mientras no haya resultado.
    function ValorActual: string;
  end;

function CrearDetectorImpresora(
  const ANombreHilo: string): IDetectorImpresora;
// Recorta la espera configurada al rango admitido (0-300 segundos).
function LimitarEsperaDeteccionImpresora(ASegundos: Integer): Integer;
// Deja constancia en el depurador de un fallo que no debe interrumpir al
// llamador (arranque de la detección).
procedure InformarFalloSecundarioEnDepurador(
  const AContexto: PChar;
  E: Exception);

implementation

uses
  System.Classes, System.SyncObjs, Winapi.Windows,
  inLibBuscarImpresora;

const
  cIntervaloDeteccionImpresoraMs = 1000;

type
  IEstadoDeteccionImpresora = interface
    ['{0B5F543D-E73A-48FC-A7FD-91BD12E74B4A}']
    procedure Cancelar;
    procedure Completar(
      AGeneracion: Integer;
      const ANombreImpresora: string);
    function EstaVigente(AGeneracion: Integer): Boolean;
    procedure Preparar(
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer;
      out AIniciarTrasRecarga: Boolean);
    procedure RestablecerInicio(AGeneracion: Integer);
    procedure Solicitar(
      out AIniciar: Boolean;
      out AGeneracion: Integer;
      out APatronImpresora, AArchivoCache: string;
      out ASegundosEspera: Integer);
    function ValorActual: string;
  end;

  TEstadoDeteccionImpresora = class(
    TInterfacedObject,
    IEstadoDeteccionImpresora
  )
  private
    FArchivoCache: string;
    FBloqueo: TCriticalSection;
    FGeneracion: Integer;
    FIniciada: Boolean;
    FPatronImpresora: string;
    FPreparada: Boolean;
    FSegundosEspera: Integer;
    FValorActual: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancelar;
    procedure Completar(
      AGeneracion: Integer;
      const ANombreImpresora: string);
    function EstaVigente(AGeneracion: Integer): Boolean;
    procedure Preparar(
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer;
      out AIniciarTrasRecarga: Boolean);
    procedure RestablecerInicio(AGeneracion: Integer);
    procedure Solicitar(
      out AIniciar: Boolean;
      out AGeneracion: Integer;
      out APatronImpresora, AArchivoCache: string;
      out ASegundosEspera: Integer);
    function ValorActual: string;
  end;

  THiloDeteccionImpresora = class(TThread)
  private
    FArchivoCache: string;
    FEstado: IEstadoDeteccionImpresora;
    FGeneracion: Integer;
    FNombreHilo: string;
    FPatronImpresora: string;
    FSegundosEspera: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AEstado: IEstadoDeteccionImpresora;
      AGeneracion: Integer;
      const APatronImpresora, AArchivoCache, ANombreHilo: string;
      ASegundosEspera: Integer);
  end;

  TDetectorImpresora = class(
    TInterfacedObject,
    IDetectorImpresora
  )
  private
    FEstado: IEstadoDeteccionImpresora;
    FNombreHilo: string;
  public
    constructor Create(const ANombreHilo: string);
    procedure Cancelar;
    procedure IniciarDeteccion;
    procedure Preparar(
      const APatronImpresora, AArchivoCache: string;
      ASegundosEspera: Integer);
    function ValorActual: string;
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

function LimitarEsperaDeteccionImpresora(ASegundos: Integer): Integer;
begin
  Result := ASegundos;
  if Result < 0 then
    Result := 0;
  if Result > cMaximoEsperaDeteccionImpresoraSegundos then
    Result := cMaximoEsperaDeteccionImpresoraSegundos;
end;

{ TEstadoDeteccionImpresora }

constructor TEstadoDeteccionImpresora.Create;
begin
  inherited Create;
  FBloqueo := TCriticalSection.Create;
end;

destructor TEstadoDeteccionImpresora.Destroy;
begin
  FreeAndNil(FBloqueo);
  inherited;
end;

procedure TEstadoDeteccionImpresora.Cancelar;
begin
  FBloqueo.Acquire;
  try
    Inc(FGeneracion);
    FIniciada := True;
    FArchivoCache := '';
    FPatronImpresora := '';
    FValorActual := '';
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.Completar(
  AGeneracion: Integer;
  const ANombreImpresora: string);
begin
  FBloqueo.Acquire;
  try
    if FGeneracion = AGeneracion then
      FValorActual := ANombreImpresora;
  finally
    FBloqueo.Release;
  end;
end;

function TEstadoDeteccionImpresora.EstaVigente(
  AGeneracion: Integer): Boolean;
begin
  FBloqueo.Acquire;
  try
    Result := FIniciada and (FGeneracion = AGeneracion);
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.Preparar(
  const APatronImpresora, AArchivoCache: string;
  ASegundosEspera: Integer;
  out AIniciarTrasRecarga: Boolean);
begin
  FBloqueo.Acquire;
  try
    AIniciarTrasRecarga := FPreparada;
    FPreparada := True;
    Inc(FGeneracion);
    FArchivoCache := AArchivoCache;
    FIniciada := (APatronImpresora = '') or
      SameText(APatronImpresora, 'DEBUG');
    FPatronImpresora := APatronImpresora;
    FSegundosEspera := ASegundosEspera;
    if SameText(APatronImpresora, 'DEBUG') then
      FValorActual := 'DEBUG'
    else
      FValorActual := '';
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.RestablecerInicio(
  AGeneracion: Integer);
begin
  FBloqueo.Acquire;
  try
    if FGeneracion = AGeneracion then
      FIniciada := False;
  finally
    FBloqueo.Release;
  end;
end;

procedure TEstadoDeteccionImpresora.Solicitar(
  out AIniciar: Boolean;
  out AGeneracion: Integer;
  out APatronImpresora, AArchivoCache: string;
  out ASegundosEspera: Integer);
begin
  FBloqueo.Acquire;
  try
    AIniciar := not FIniciada;
    if AIniciar then
      FIniciada := True;
    AGeneracion := FGeneracion;
    APatronImpresora := FPatronImpresora;
    AArchivoCache := FArchivoCache;
    ASegundosEspera := FSegundosEspera;
  finally
    FBloqueo.Release;
  end;
end;

function TEstadoDeteccionImpresora.ValorActual: string;
begin
  FBloqueo.Acquire;
  try
    Result := FValorActual;
  finally
    FBloqueo.Release;
  end;
end;

function BuscarImpresoraSegura(
  const APatronImpresora, AArchivoCache: string): string;
begin
  try
    Result := ObtenerImpresoraPorPatronCached(
      APatronImpresora,
      AArchivoCache);
  except
    Result := '';
  end;
end;

procedure EjecutarDeteccionImpresora(
  const AEstado: IEstadoDeteccionImpresora;
  AGeneracion: Integer;
  const APatronImpresora, AArchivoCache, ANombreHilo: string;
  ASegundosEspera: Integer);
var
  iAhora: UInt64;
  iEsperaMs: Cardinal;
  iLimite: UInt64;
  iRestanteMs: UInt64;
  sImpresora: string;
begin
  sImpresora := '';
  iLimite := GetTickCount64 + UInt64(ASegundosEspera) * 1000;
  try
    TThread.NameThreadForDebugging(ANombreHilo);
    // Winspool no permite cancelar una enumeración ya iniciada.
    if AEstado.EstaVigente(AGeneracion) then
      sImpresora := BuscarImpresoraSegura(
        APatronImpresora,
        AArchivoCache);
    iAhora := GetTickCount64;
    while (sImpresora = '') and
          AEstado.EstaVigente(AGeneracion) and
          (iAhora < iLimite) do
    begin
      iRestanteMs := iLimite - iAhora;
      if iRestanteMs > cIntervaloDeteccionImpresoraMs then
        iEsperaMs := cIntervaloDeteccionImpresoraMs
      else
        iEsperaMs := Cardinal(iRestanteMs);
      Sleep(iEsperaMs);
      if AEstado.EstaVigente(AGeneracion) and
         (GetTickCount64 <= iLimite) then
      begin
        sImpresora := BuscarImpresoraSegura(
          APatronImpresora,
          AArchivoCache);
      end;
      iAhora := GetTickCount64;
    end;
  finally
    if AEstado.EstaVigente(AGeneracion) then
      AEstado.Completar(AGeneracion, sImpresora);
  end;
end;

{ THiloDeteccionImpresora }

constructor THiloDeteccionImpresora.Create(
  const AEstado: IEstadoDeteccionImpresora;
  AGeneracion: Integer;
  const APatronImpresora, AArchivoCache, ANombreHilo: string;
  ASegundosEspera: Integer);
begin
  inherited Create(True);
  FArchivoCache := AArchivoCache;
  FEstado := AEstado;
  FGeneracion := AGeneracion;
  FNombreHilo := ANombreHilo;
  FPatronImpresora := APatronImpresora;
  FSegundosEspera := ASegundosEspera;
  FreeOnTerminate := True;
end;

procedure THiloDeteccionImpresora.Execute;
begin
  EjecutarDeteccionImpresora(
    FEstado,
    FGeneracion,
    FPatronImpresora,
    FArchivoCache,
    FNombreHilo,
    FSegundosEspera);
end;

procedure LanzarDeteccionImpresora(
  const AEstado: IEstadoDeteccionImpresora;
  AGeneracion: Integer;
  const APatronImpresora, AArchivoCache, ANombreHilo: string;
  ASegundosEspera: Integer);
var
  oHilo: THiloDeteccionImpresora;
begin
  oHilo := THiloDeteccionImpresora.Create(
    AEstado,
    AGeneracion,
    APatronImpresora,
    AArchivoCache,
    ANombreHilo,
    ASegundosEspera);
  try
    oHilo.Start;
  except
    oHilo.Free;
    raise;
  end;
end;

{ TDetectorImpresora }

constructor TDetectorImpresora.Create(const ANombreHilo: string);
begin
  inherited Create;
  FEstado := TEstadoDeteccionImpresora.Create;
  FNombreHilo := ANombreHilo;
end;

procedure TDetectorImpresora.Cancelar;
begin
  FEstado.Cancelar;
end;

procedure TDetectorImpresora.IniciarDeteccion;
var
  bIniciar: Boolean;
  iGeneracion: Integer;
  iSegundosEspera: Integer;
  sArchivoCache: string;
  sPatronImpresora: string;
begin
  FEstado.Solicitar(
    bIniciar,
    iGeneracion,
    sPatronImpresora,
    sArchivoCache,
    iSegundosEspera);
  if bIniciar then
  begin
    try
      LanzarDeteccionImpresora(
        FEstado,
        iGeneracion,
        sPatronImpresora,
        sArchivoCache,
        FNombreHilo,
        iSegundosEspera);
    except
      FEstado.RestablecerInicio(iGeneracion);
    end;
  end;
end;

procedure TDetectorImpresora.Preparar(
  const APatronImpresora, AArchivoCache: string;
  ASegundosEspera: Integer);
var
  bIniciarTrasRecarga: Boolean;
begin
  FEstado.Preparar(
    APatronImpresora,
    AArchivoCache,
    ASegundosEspera,
    bIniciarTrasRecarga);
  if bIniciarTrasRecarga then
    IniciarDeteccion;
end;

function TDetectorImpresora.ValorActual: string;
begin
  Result := FEstado.ValorActual;
end;

function CrearDetectorImpresora(
  const ANombreHilo: string): IDetectorImpresora;
begin
  Result := TDetectorImpresora.Create(ANombreHilo);
end;

end.
