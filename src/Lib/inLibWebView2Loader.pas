{******************************************************************************}
{ Módulo: inLibWebView2Loader                                                  }
{ Tipo: Librería                                                               }
{ Fecha: 17/09/2026                                                            }
{ Autor: Alejandro Laorden Hidalgo                                             }
{ Copyright (c) Alejandro Laorden Hidalgo.                                     }
{ SPDX-License-Identifier: MPL-2.0                                             }
{ Descripción: WebView2Loader.dll viaja como recurso dentro de vcash.exe. Se    }
{   escribe en %TEMP%\ViraCash\WebView2\<arquitectura>\<hash> y se carga desde }
{   allí con ruta completa, comprobando antes su SHA-256.                      }
{******************************************************************************}
unit inLibWebView2Loader;

interface

// Deja cargado el WebView2Loader.dll incluido en el ejecutable. Si no se
// puede, devuelve False y Vcl.Edge buscará la DLL junto al ejecutable.
function PrepararCargadorWebView2: Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  System.Hash, Winapi.EdgeUtils;

{$IFDEF WIN64}
{$R '..\3rdpartyComp\WebView2\WebView2Loader_x64.res'}
const
  cArquitectura = 'x64';
  cHashCargador =
    '8427B1FC58EC707813E5C0A51EB5D69397BB333250A7B891BE4D3B123F1E0F1C';
{$ELSE}
{$R '..\3rdpartyComp\WebView2\WebView2Loader_x86.res'}
const
  cArquitectura = 'x86';
  cHashCargador =
    '44AB92C2246EBFB5F98AA5726626FB44BEB61543F2EF1803338AF9FD295E63F0';
{$ENDIF}

const
  cNombreRecurso = 'WEBVIEW2LOADER';
  cNombreDll = 'WebView2Loader.dll';
  // Basta un prefijo del hash para separar versiones del cargador.
  cLongitudCarpetaHash = 16;

var
  FCargado: Boolean;

function HashDe(const ADatos: TBytes): string;
var
  Hash: THashSHA2;
begin
  Hash := THashSHA2.Create;
  Hash.Update(ADatos);
  Result := UpperCase(Hash.HashAsString);
end;

function LeerRecurso: TBytes;
var
  Recurso: TResourceStream;
begin
  Recurso := TResourceStream.Create(HInstance, cNombreRecurso, RT_RCDATA);
  try
    SetLength(Result, Recurso.Size);
    Recurso.ReadBuffer(Result, Length(Result));
  finally
    Recurso.Free;
  end;
end;

// Abre la DLL impidiendo que otro proceso la modifique mientras esté abierta
// y comprueba su contenido. Solo devuelve el handle si el hash coincide.
function AbrirVerificado(const ARuta: string; out AFichero: THandle): Boolean;
var
  Flujo: THandleStream;
  Datos: TBytes;
begin
  AFichero := CreateFile(PChar(ARuta), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := AFichero <> INVALID_HANDLE_VALUE;
  if Result then
  begin
    Result := False;
    try
      Flujo := THandleStream.Create(AFichero);
      try
        SetLength(Datos, Flujo.Size);
        Flujo.ReadBuffer(Datos, Length(Datos));
      finally
        Flujo.Free;
      end;
      Result := HashDe(Datos) = cHashCargador;
    finally
      if not Result then
      begin
        CloseHandle(AFichero);
        AFichero := INVALID_HANDLE_VALUE;
      end;
    end;
  end;
end;

// Escribe con nombre provisional y renombra sin reemplazar: si otra instancia
// de ViraCash se adelanta, se conserva su copia.
procedure EscribirCargador(const ACarpeta, ARuta: string;
  const ADatos: TBytes);
var
  Provisional: string;
begin
  ForceDirectories(ACarpeta);
  Provisional := TPath.Combine(ACarpeta, TGUID.NewGuid.ToString + '.tmp');
  TFile.WriteAllBytes(Provisional, ADatos);
  if not MoveFileEx(PChar(Provisional), PChar(ARuta),
    MOVEFILE_WRITE_THROUGH) then
    System.SysUtils.DeleteFile(Provisional);
end;

// Deja en ARuta una copia verificada y abierta en AFichero. Si falta o está
// alterada, se vuelve a escribir desde el recurso.
function ObtenerCargadorVerificado(out ARuta: string;
  out AFichero: THandle): Boolean;
var
  Datos: TBytes;
  Carpeta: string;
begin
  Datos := LeerRecurso;
  Carpeta := TPath.Combine(TPath.GetTempPath, 'ViraCash\WebView2\' +
    cArquitectura + '\' + Copy(cHashCargador, 1, cLongitudCarpetaHash));
  ARuta := TPath.Combine(Carpeta, cNombreDll);
  AFichero := INVALID_HANDLE_VALUE;
  // Un .res desactualizado respecto a la DLL verificada no se usa.
  Result := HashDe(Datos) = cHashCargador;
  if Result and not AbrirVerificado(ARuta, AFichero) then
  begin
    if FileExists(ARuta) then
      System.SysUtils.DeleteFile(ARuta);
    EscribirCargador(Carpeta, ARuta, Datos);
    Result := AbrirVerificado(ARuta, AFichero);
  end;
end;

// Carga la DLL mientras sigue abierta sin permitir escrituras, de modo que
// no puede cambiar entre la comprobación del hash y LoadLibrary.
function CargarVerificado(const ARuta: string; AFichero: THandle): Boolean;
begin
  try
{$IF Declared(SetWebView2Path)}
    SetWebView2Path(ARuta);
    Result := CheckWebView2Loaded;
    if not Result then
      SetWebView2Path(cNombreDll);
{$ELSE}
    // Con el módulo ya cargado por ruta completa, la carga por nombre que
    // hace Vcl.Edge/EdgeUtils reutiliza este mismo módulo.
    Result := (LoadLibrary(PChar(ARuta)) <> 0) and CheckWebView2Loaded;
{$IFEND}
  finally
    CloseHandle(AFichero);
  end;
end;

function PrepararCargadorWebView2: Boolean;
var
  Ruta: string;
  Fichero: THandle;
begin
  if not FCargado then
    try
      if ObtenerCargadorVerificado(Ruta, Fichero) then
        FCargado := CargarVerificado(Ruta, Fichero);
    except
      on EResNotFound do
        FCargado := False;
      on EStreamError do
        FCargado := False;
      on EInOutError do
        FCargado := False;
      on EOSError do
        FCargado := False;
    end;
  Result := FCargado;
end;

end.
