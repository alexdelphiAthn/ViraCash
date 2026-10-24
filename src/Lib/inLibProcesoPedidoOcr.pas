{******************************************************************************}
{                                                                              }
{  Módulo:       inLibProcesoPedidoOcr                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Ejecuta el extractor OCR externo situado junto a ViraCash.exe y devuelve }
{    las rutas temporales del JSON, las fotos y las páginas TIFF generadas.    }
{******************************************************************************}
unit inLibProcesoPedidoOcr;

interface

uses
  System.SysUtils;

type
  TResultadoProcesoPedidoOcr = record
    FicheroJson: string;
    DirectorioTrabajo: string;
    SalidaProceso: string;
  end;
  TProcesoPedidoOcr = class
  private
    class function CrearDirectorioTrabajo: string; static;
    class function EntreComillas(const AValor: string): string; static;
    class function LeerSalidaProceso(const AFichero: string): string; static;
  public
    class function Ejecutar(const AFicheroPdf: string;
      const AProcesarMensajes: TProc): TResultadoProcesoPedidoOcr; static;
    class procedure EliminarTrabajo(
      const ADirectorioTrabajo: string); static;
  end;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.IOUtils;

resourcestring
  SErrorPdfPedidoOcrNoExiste = 'No existe el PDF: %s';
  SErrorEjecutablePedidoOcrNoEncontrado =
    'No se encuentra %s junto a ViraCash.exe.';
  SErrorLogPedidoOcrNoCreado =
    'No se pudo crear el log del OCR (%d).';
  SErrorProcesoPedidoOcrNoIniciado =
    'No se pudo iniciar el OCR (%d).';
  SErrorEsperaProcesoPedidoOcr =
    'Error esperando al proceso OCR (%d).';
  SErrorResultadoProcesoPedidoOcrNoLeido =
    'No se pudo leer el resultado del OCR (%d).';
  SErrorExtractorPedidoOcr =
    'El extractor OCR terminó con código %d.%s%s';
  SErrorExtractorPedidoOcrSinJson =
    'El extractor terminó sin generar el JSON del pedido.';

const
  cNombreEjecutableOcr = 'ExtraerPedidoAlbionTesseract.exe';
  cCarpetaTemporalOcr = 'ViraCashPedidoOcr';

class function TProcesoPedidoOcr.CrearDirectorioTrabajo: string;
var
  Id: TGUID;
  sId: string;
begin
  CreateGUID(Id);
  sId := GUIDToString(Id).Replace('{', '').Replace('}', '');
  Result := TPath.Combine(
    TPath.Combine(TPath.GetTempPath, cCarpetaTemporalOcr),
    sId);
  TDirectory.CreateDirectory(Result);
end;

class function TProcesoPedidoOcr.EntreComillas(
  const AValor: string): string;
begin
  Result := '"' + AValor + '"';
end;

// El extractor escribe por la salida estandar, que aqui va redirigida a
// un fichero: en ese caso Delphi la codifica con la pagina de codigos
// ANSI del equipo (1252 en los clientes), no en UTF-8. Leerla como UTF-8
// estricto reventaba con "No mapping for the Unicode character exists in
// the target multi-byte code page" en cuanto el log traia un acento. El
// log es solo diagnostico, asi que probamos UTF-8 y caemos a ANSI.
class function TProcesoPedidoOcr.LeerSalidaProceso(
  const AFichero: string): string;
var
  aBytes: TBytes;
begin
  Result := '';
  try
    aBytes := TFile.ReadAllBytes(AFichero);
    if Length(aBytes) = 0 then
      Exit;
    try
      Result := TEncoding.UTF8.GetString(aBytes);
    except
      on EEncodingError do
        Result := TEncoding.ANSI.GetString(aBytes);
    end;
    if Result.StartsWith(#$FEFF) then
      Result := Result.Substring(1);
  except
    on Exception do
      Result := '';
  end;
end;

class function TProcesoPedidoOcr.Ejecutar(const AFicheroPdf: string;
  const AProcesarMensajes: TProc): TResultadoProcesoPedidoOcr;
var
  bCreado: Boolean;
  iCodigo: Cardinal;
  iEspera: Cardinal;
  oInicio: TStartupInfo;
  oProceso: TProcessInformation;
  oSeguridad: TSecurityAttributes;
  sComando: string;
  sEjecutable: string;
  sFicheroLog: string;
  sPaginas: string;
  hLog: THandle;
begin
  Result := Default(TResultadoProcesoPedidoOcr);
  if not TFile.Exists(AFicheroPdf) then
    raise Exception.CreateFmt(SErrorPdfPedidoOcrNoExiste, [AFicheroPdf]);
  sEjecutable := TPath.Combine(
    TPath.GetDirectoryName(ParamStr(0)),
    cNombreEjecutableOcr);
  if not TFile.Exists(sEjecutable) then
    raise Exception.CreateFmt(
      SErrorEjecutablePedidoOcrNoEncontrado,
      [cNombreEjecutableOcr]);
  Result.DirectorioTrabajo := CrearDirectorioTrabajo;
  try
    iCodigo := 0;
    Result.FicheroJson := TPath.Combine(
      Result.DirectorioTrabajo,
      'pedido.tesseract.pedido.json');
    sPaginas := TPath.Combine(
      Result.DirectorioTrabajo,
      'pedido.tesseract.pedido.paginas');
    sFicheroLog := TPath.Combine(Result.DirectorioTrabajo, 'ocr.log');
    ZeroMemory(@oSeguridad, SizeOf(oSeguridad));
    oSeguridad.nLength := SizeOf(oSeguridad);
    oSeguridad.bInheritHandle := True;
    hLog := CreateFile(
      PChar(sFicheroLog),
      GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE,
      @oSeguridad,
      CREATE_ALWAYS,
      FILE_ATTRIBUTE_NORMAL,
      0);
    if hLog = INVALID_HANDLE_VALUE then
      raise EOSError.CreateFmt(
        SErrorLogPedidoOcrNoCreado, [GetLastError]);
    ZeroMemory(@oInicio, SizeOf(oInicio));
    ZeroMemory(@oProceso, SizeOf(oProceso));
    oInicio.cb := SizeOf(oInicio);
    oInicio.dwFlags := STARTF_USESTDHANDLES;
    oInicio.hStdOutput := hLog;
    oInicio.hStdError := hLog;
    oInicio.hStdInput := 0;
    sComando := EntreComillas(sEjecutable) + ' ' +
      EntreComillas(TPath.GetFullPath(AFicheroPdf)) +
      ' --output ' + EntreComillas(Result.FicheroJson) +
      ' --debug-dir ' + EntreComillas(sPaginas) +
      ' --force';
    bCreado := CreateProcess(
      nil,
      PChar(sComando),
      nil,
      nil,
      True,
      CREATE_NO_WINDOW,
      nil,
      PChar(TPath.GetDirectoryName(sEjecutable)),
      oInicio,
      oProceso);
    CloseHandle(hLog);
    if not bCreado then
      raise EOSError.CreateFmt(
        SErrorProcesoPedidoOcrNoIniciado, [GetLastError]);
    try
      repeat
        iEspera := WaitForSingleObject(oProceso.hProcess, 100);
        if Assigned(AProcesarMensajes) then
          AProcesarMensajes();
      until iEspera <> WAIT_TIMEOUT;
      if iEspera <> WAIT_OBJECT_0 then
        raise EOSError.CreateFmt(
          SErrorEsperaProcesoPedidoOcr, [GetLastError]);
      if not GetExitCodeProcess(oProceso.hProcess, iCodigo) then
        raise EOSError.CreateFmt(
          SErrorResultadoProcesoPedidoOcrNoLeido, [GetLastError]);
    finally
      CloseHandle(oProceso.hThread);
      CloseHandle(oProceso.hProcess);
    end;
    if TFile.Exists(sFicheroLog) then
      Result.SalidaProceso := LeerSalidaProceso(sFicheroLog);
    if iCodigo <> 0 then
      raise Exception.CreateFmt(
        SErrorExtractorPedidoOcr,
        [iCodigo, sLineBreak, Result.SalidaProceso]);
    if not TFile.Exists(Result.FicheroJson) then
      raise Exception.Create(SErrorExtractorPedidoOcrSinJson);
  except
    EliminarTrabajo(Result.DirectorioTrabajo);
    raise;
  end;
end;

class procedure TProcesoPedidoOcr.EliminarTrabajo(
  const ADirectorioTrabajo: string);
var
  sBase: string;
  sDirectorio: string;
begin
  sBase := IncludeTrailingPathDelimiter(TPath.GetFullPath(
    TPath.Combine(TPath.GetTempPath, cCarpetaTemporalOcr)));
  sDirectorio := TPath.GetFullPath(ADirectorioTrabajo);
  if sDirectorio.StartsWith(sBase, True) and
     TDirectory.Exists(sDirectorio) then
    TDirectory.Delete(sDirectorio, True);
end;

end.
