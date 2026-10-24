{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionScripts                                     }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Averigua qué scripts de esquema faltan en esta base y los aplica.         }
{******************************************************************************}
unit inLibActualizacionScripts;

interface

uses
  Uni,
  inLibActualizacionScriptsLectura;

type
  TScriptFaltante = inLibActualizacionScriptsLectura.TScriptFaltante;

  // La comprobación recorre INFORMATION_SCHEMA entero y en una base grande
  // son minutos: corre en un hilo y otro la corta. Ejecutar se llama desde
  // el hilo de trabajo; Cancelar, desde el que mira el botón.
  IConsultaScriptsFaltantes = interface
    ['{5E0B1F0A-6C0D-4B7E-8E55-3B0C6B1D9A42}']
    function Ejecutar(
      out AFaltantes: TArray<TScriptFaltante>;
      out AError: string): Boolean;
    // Se puede llamar las veces que haga falta: corta la sentencia en
    // curso y, si todavía no había empezado, lo reintenta más tarde.
    procedure Cancelar;
    function Cancelada: Boolean;
  end;

// Lee un .sql sin dar por hecho que viene en UTF-8: los scripts antiguos
// pueden estar en la pagina de codigos del equipo.
function LeerTextoScriptSql(const ARuta: string): string;
function CrearConsultaScriptsFaltantes(
  AConexion: TUniConnection;
  const ASqlComprobacion: string): IConsultaScriptsFaltantes;
// Ejecuta el contenido de ARutaSql comprobando antes su huella SHA-256.
function EjecutarScriptActualizacion(
  AConexion: TUniConnection;
  const ARutaSql, ASha256: string;
  out AError: string): Boolean;

implementation

uses
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.SyncObjs,
  System.SysUtils,
  UniScript,
  inLibMsgIntegraciones;

const
  // Entre dos intentos de cortar la sentencia: el primero puede llegar
  // antes de que el servidor haya empezado a ejecutarla.
  cEsperaReintentoCancelacionMs = 1000;

type
  TConsultaScriptsFaltantes = class(
    TInterfacedObject,
    IConsultaScriptsFaltantes)
  private
    FCancelada: Integer;
    FConexion: TUniConnection;
    FConsulta: TUniQuery;
    FSeccion: TCriticalSection;
    FSql: string;
    FUltimoCorte: UInt64;
    procedure AnotarConsulta(AConsulta: TUniQuery);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ASqlComprobacion: string);
    destructor Destroy; override;
    function Ejecutar(
      out AFaltantes: TArray<TScriptFaltante>;
      out AError: string): Boolean;
    procedure Cancelar;
    function Cancelada: Boolean;
  end;

function LeerTextoScriptSql(const ARuta: string): string;
var
  aDatos: TBytes;
  iPreambulo: Integer;
  oCodificacion: TEncoding;
begin
  aDatos := TFile.ReadAllBytes(ARuta);
  oCodificacion := nil;
  iPreambulo := TEncoding.GetBufferEncoding(
    aDatos,
    oCodificacion,
    TEncoding.UTF8);
  try
    Result := oCodificacion.GetString(
      aDatos,
      iPreambulo,
      Length(aDatos) - iPreambulo);
  except
    on E: EEncodingError do
      Result := TEncoding.ANSI.GetString(aDatos);
  end;
end;

{ TConsultaScriptsFaltantes }

constructor TConsultaScriptsFaltantes.Create(
  AConexion: TUniConnection;
  const ASqlComprobacion: string);
begin
  inherited Create;
  FConexion := AConexion;
  FSql := ASqlComprobacion;
  FSeccion := TCriticalSection.Create;
end;

destructor TConsultaScriptsFaltantes.Destroy;
begin
  FSeccion.Free;
  inherited Destroy;
end;

// El hilo que cancela usa la consulta dentro de la misma sección, así que
// el de trabajo no puede liberarla mientras la están cortando.
procedure TConsultaScriptsFaltantes.AnotarConsulta(AConsulta: TUniQuery);
begin
  FSeccion.Enter;
  try
    FConsulta := AConsulta;
  finally
    FSeccion.Leave;
  end;
end;

function TConsultaScriptsFaltantes.Ejecutar(
  out AFaltantes: TArray<TScriptFaltante>;
  out AError: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AFaltantes := nil;
  AError := '';
  if not Assigned(FConexion) then
    AError := SErrorConexionActualizacionNoDisponible
  else if Trim(FSql) = '' then
    AError := SErrorComprobacionScriptsVacia
  else if not Cancelada then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := FSql;
        AnotarConsulta(oConsulta);
        oConsulta.Open;
        AFaltantes := LeerScriptsFaltantes(oConsulta);
        Result := True;
      except
        on E: Exception do
          AError := E.ClassName + ': ' + E.Message;
      end;
    finally
      AnotarConsulta(nil);
      oConsulta.Free;
    end;
  end;
end;

procedure TConsultaScriptsFaltantes.Cancelar;
var
  iAhora: UInt64;
begin
  AtomicExchange(FCancelada, 1);
  iAhora := TThread.GetTickCount64;
  FSeccion.Enter;
  try
    if Assigned(FConsulta) and
       ((FUltimoCorte = 0) or
        (iAhora - FUltimoCorte >= cEsperaReintentoCancelacionMs)) then
    begin
      FUltimoCorte := iAhora;
      try
        FConsulta.BreakExec;
      except
        // No se ha podido cortar ahora: se reintenta en la siguiente
        // llamada. Quien espera no puede quedarse sin su bucle por esto.
        on E: Exception do
          FUltimoCorte := iAhora;
      end;
    end;
  finally
    FSeccion.Leave;
  end;
end;

function TConsultaScriptsFaltantes.Cancelada: Boolean;
begin
  Result := AtomicCmpExchange(FCancelada, 0, 0) <> 0;
end;

function CrearConsultaScriptsFaltantes(
  AConexion: TUniConnection;
  const ASqlComprobacion: string): IConsultaScriptsFaltantes;
begin
  Result := TConsultaScriptsFaltantes.Create(AConexion, ASqlComprobacion);
end;

function EjecutarScriptActualizacion(
  AConexion: TUniConnection;
  const ARutaSql, ASha256: string;
  out AError: string): Boolean;
var
  oScript: TUniScript;
  sContenido: string;
  sHuella: string;
begin
  Result := False;
  AError := '';
  if not Assigned(AConexion) then
    AError := SErrorConexionActualizacionNoDisponible
  else if not TFile.Exists(ARutaSql) then
    AError := Format(SErrorScriptActualizacionAusente, [ARutaSql])
  else
  begin
    try
      sHuella := LowerCase(THashSHA2.GetHashStringFromFile(ARutaSql));
      if (Trim(ASha256) <> '') and not SameText(sHuella, Trim(ASha256)) then
        AError := SErrorHuellaScriptActualizacionNoCoincide
      else
      begin
        sContenido := LeerTextoScriptSql(ARutaSql);
        if Trim(sContenido) = '' then
          AError := Format(SErrorScriptActualizacionVacio, [ARutaSql])
        else
        begin
          oScript := TUniScript.Create(nil);
          try
            oScript.Connection := AConexion;
            oScript.SQL.Text := sContenido;
            oScript.Execute;
            Result := True;
          finally
            oScript.Free;
          end;
        end;
      end;
    except
      on E: Exception do
        AError := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
