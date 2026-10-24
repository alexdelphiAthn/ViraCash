{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionSoporte                                    }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Descarga, valida y sustituye de forma recuperable el ejecutable actual.  }
{******************************************************************************}
unit inLibActualizacionSoporte;

interface

function InstalarActualizacionSoporte(
  const AUrl, ASha256: string;
  ACantidadBytes: Int64;
  out ARutaAnterior, AError: string): Boolean;
procedure ProcesarArranqueActualizacionSoporte;
// Línea de órdenes del ejecutable nuevo: el perfil INI del arranque va
// primero, como en el arranque normal; sin él, el proceso relanzado abría
// el perfil por defecto (otra BBDD) (FZ-ISSUE-329).
function TextoComando(
  const ARutaActual, ARutaAnterior, APerfilIni: string): string;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.Net.HttpClient,
  System.StrUtils,
  System.SysUtils,
  inLibActualizacionInstalacion, inLibConfiguracionIni;

resourcestring
  SErrorActualizacionSinHttps =
    'La actualización no utiliza una conexión HTTPS.';
  SErrorHuellaActualizacionInvalida =
    'La actualización no incluye una huella SHA-256 válida.';
  SErrorServidorActualizacionHttp =
    'El servidor respondió HTTP %d.';
  SErrorTamanoActualizacionNoCoincide =
    'El tamaño de la actualización no coincide.';
  SErrorArchivoActualizacionNoEjecutable =
    'El archivo descargado no es un ejecutable válido.';
  SErrorHuellaActualizacionNoCoincide =
    'La huella SHA-256 de la actualización no coincide.';
  SErrorArquitecturaActualizacionNoCoincide =
    'La actualización no corresponde a la arquitectura instalada.';
  SErrorRestaurarEjecutableAnterior =
    '%sNo se pudo restaurar automáticamente el ejecutable anterior: %s' +
    '%sSe conserva en: %s';
  SErrorRenombrarEjecutableActual =
    'No se pudo renombrar el ejecutable actual: %s';
  SErrorCopiarEjecutableNuevo =
    'No se pudo copiar el nuevo ejecutable: %s';

function DescargarActualizacion(
  const AUrl, ASha256: string;
  ACantidadBytes: Int64;
  out ARuta, AError: string): Boolean;
var
  oFlujo: TFileStream;
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sHash: string;
begin
  Result := False;
  ARuta := '';
  AError := '';
  if not StartsText('https://', Trim(AUrl)) then
    AError := SErrorActualizacionSinHttps
  else if Length(Trim(ASha256)) <> 64 then
    AError := SErrorHuellaActualizacionInvalida
  else
  begin
    ARuta := RutaTemporalActualizacion('.exe');
    oHttp := THTTPClient.Create;
    try
      oFlujo := TFileStream.Create(ARuta, fmCreate);
      try
        try
          oHttp.ConnectionTimeout := 15000;
          oHttp.ResponseTimeout := 600000;
          oRespuesta := oHttp.Get(AUrl, oFlujo);
          if (oRespuesta.StatusCode < 200) or
             (oRespuesta.StatusCode >= 300) then
            AError := Format(
              SErrorServidorActualizacionHttp,
              [oRespuesta.StatusCode])
          else if (ACantidadBytes > 0) and
                  (oFlujo.Size <> ACantidadBytes) then
            AError := SErrorTamanoActualizacionNoCoincide
          else if not CabeceraEjecutableValida(ARuta) then
            AError := SErrorArchivoActualizacionNoEjecutable
          else
          begin
            sHash := UpperCase(THashSHA2.GetHashStringFromFile(ARuta));
            if not SameText(sHash, Trim(ASha256)) then
              AError := SErrorHuellaActualizacionNoCoincide
            else if not MismaArquitecturaEjecutable(ParamStr(0), ARuta) then
              AError := SErrorArquitecturaActualizacionNoCoincide
            else
              Result := True;
          end;
        except
          on E: Exception do
            AError := E.Message;
        end;
      finally
        oFlujo.Free;
      end;
    finally
      oHttp.Free;
    end;
  end;
  if not Result and (ARuta <> '') and FileExists(ARuta) then
  begin
    DeleteFile(ARuta);
    ARuta := '';
  end;
end;

function RutaAnteriorUnica(const ARutaActual: string): string;
var
  sCarpeta: string;
  sNombre: string;
begin
  sCarpeta := ExtractFilePath(ARutaActual);
  sNombre := ChangeFileExt(ExtractFileName(ARutaActual), '');
  Result := TPath.Combine(
    sCarpeta,
    '_' + sNombre + '_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.exe');
end;

function TextoComando(
  const ARutaActual, ARutaAnterior, APerfilIni: string): string;
begin
  Result := '"' + ARutaActual + '" ';
  if Trim(APerfilIni) <> '' then
    Result := Result + '"' + Trim(APerfilIni) + '" ';
  Result := Result +
    '/actualizacion-soporte-pid=' + GetCurrentProcessId.ToString + ' ' +
    '/actualizacion-soporte-antiguo="' + ARutaAnterior + '"';
end;

function ArrancarNuevoEjecutable(
  const ARutaActual, ARutaAnterior: string;
  out AError: string): Boolean;
var
  Informacion: TProcessInformation;
  Inicio: TStartupInfo;
  sComando: string;
begin
  ZeroMemory(@Inicio, SizeOf(Inicio));
  ZeroMemory(@Informacion, SizeOf(Informacion));
  Inicio.cb := SizeOf(Inicio);
  sComando := TextoComando(ARutaActual, ARutaAnterior, PerfilIniArranque);
  UniqueString(sComando);
  Result := CreateProcess(
    PChar(ARutaActual),
    PChar(sComando),
    nil,
    nil,
    False,
    0,
    nil,
    PChar(ExtractFilePath(ARutaActual)),
    Inicio,
    Informacion);
  if Result then
  begin
    CloseHandle(Informacion.hThread);
    CloseHandle(Informacion.hProcess);
  end
  else
    AError := SysErrorMessage(GetLastError);
end;

procedure RestaurarEjecutableAnterior(
  const ARutaAnterior, ARutaActual: string;
  var AError: string);
begin
  if not MoveFileEx(
           PChar(ARutaAnterior),
           PChar(ARutaActual),
           MOVEFILE_WRITE_THROUGH) then
    AError := AError + Format(SErrorRestaurarEjecutableAnterior,
      [sLineBreak, SysErrorMessage(GetLastError), sLineBreak,
       ARutaAnterior]);
end;

function InstalarActualizacionSoporte(
  const AUrl, ASha256: string;
  ACantidadBytes: Int64;
  out ARutaAnterior, AError: string): Boolean;
var
  sRutaActual: string;
  sRutaDescarga: string;
begin
  Result := False;
  ARutaAnterior := '';
  AError := '';
  sRutaDescarga := '';
  if DescargarActualizacion(
       AUrl,
       ASha256,
       ACantidadBytes,
       sRutaDescarga,
       AError) then
  begin
    sRutaActual := ExpandFileName(ParamStr(0));
    ARutaAnterior := RutaAnteriorUnica(sRutaActual);
    if not MoveFileEx(
             PChar(sRutaActual),
             PChar(ARutaAnterior),
             MOVEFILE_WRITE_THROUGH) then
      AError := Format(SErrorRenombrarEjecutableActual,
        [SysErrorMessage(GetLastError)])
    else if not CopyFile(
                  PChar(sRutaDescarga),
                  PChar(sRutaActual),
                  True) then
    begin
      AError := Format(SErrorCopiarEjecutableNuevo,
        [SysErrorMessage(GetLastError)]);
      RestaurarEjecutableAnterior(
        ARutaAnterior,
        sRutaActual,
        AError);
    end
    else if not ArrancarNuevoEjecutable(
                      sRutaActual,
                      ARutaAnterior,
                      AError) then
    begin
      DeleteFile(sRutaActual);
      RestaurarEjecutableAnterior(
        ARutaAnterior,
        sRutaActual,
        AError);
    end
    else
      Result := True;
  end;
  if (sRutaDescarga <> '') and FileExists(sRutaDescarga) then
    DeleteFile(sRutaDescarga);
  if not Result then
    ARutaAnterior := '';
end;

function RutaAnteriorSegura(
  const ARuta: string): Boolean;
var
  sActual: string;
  sAnterior: string;
begin
  sActual := ExpandFileName(ParamStr(0));
  sAnterior := ExpandFileName(ARuta);
  Result := SameText(
              ExcludeTrailingPathDelimiter(ExtractFilePath(sActual)),
              ExcludeTrailingPathDelimiter(ExtractFilePath(sAnterior))) and
    StartsText('_', ExtractFileName(sAnterior)) and
    SameText(ExtractFileExt(sAnterior), '.exe');
end;

procedure ProcesarArranqueActualizacionSoporte;
var
  hProceso: THandle;
  iPid: Cardinal;
  sPid: string;
  sRutaAnterior: string;
begin
  sPid := '';
  sRutaAnterior := '';
  if FindCmdLineSwitch(
       'actualizacion-soporte-pid',
       sPid,
       True) and
     FindCmdLineSwitch(
       'actualizacion-soporte-antiguo',
       sRutaAnterior,
       True) and
     TryStrToUInt(sPid, iPid) and
     RutaAnteriorSegura(sRutaAnterior) then
  begin
    hProceso := OpenProcess(SYNCHRONIZE, False, iPid);
    if hProceso <> 0 then
    begin
      WaitForSingleObject(hProceso, 120000);
      CloseHandle(hProceso);
    end;
    if FileExists(sRutaAnterior) then
      DeleteFile(sRutaAnterior);
  end;
end;

end.
