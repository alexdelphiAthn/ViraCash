{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPathTokens                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resolución de tokens de ruta tipo $(DOCUMENTOS).                          }
{    Conversión bidireccional entre rutas absolutas y rutas tokenizadas.       }
{******************************************************************************}
unit inLibPathTokens;

interface

uses
  Winapi.Windows, Winapi.ShlObj, Winapi.ActiveX,
  System.SysUtils, System.StrUtils;

/// Convierte una ruta absoluta a una ruta con token.
/// Ej: C:\Users\Juan\Documents\X  ->  $(DOCUMENTOS)\X
function PathToToken(const APath: string): string;

/// Expande los tokens de una ruta a rutas absolutas reales.
/// Ej: $(DOCUMENTOS)\X  ->  C:\Users\Juan\Documents\X
function ExpandPathTokens(const APath: string): string;

implementation

type
  TTokenMap = record
    Token : string;     // p. ej. '$(DOCUMENTOS)'
    CSIDL : Integer;    // -1 si se resuelve por otro medio
    Custom: TFunc<string>; // usado si CSIDL = -1
  end;

function GetFolderByCSIDL(ACSIDL: Integer): string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(0, ACSIDL, 0, SHGFP_TYPE_CURRENT, @Buf[0]) = S_OK then
    Result := ExcludeTrailingPathDelimiter(Buf)
  else
    Result := '';
end;

function GetAppDir: string;
begin
  Result := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

// Orden importante: primero los más específicos/largos.
// Así $(LOCALAPPDATA) se detecta antes que $(APPDATA) por subcadena.
function BuildMap: TArray<TTokenMap>;
begin
  SetLength(Result, 8);
  Result[0].Token := '$(LOCALAPPDATA)';  Result[0].CSIDL := CSIDL_LOCAL_APPDATA;
  Result[1].Token := '$(APPDATA)';       Result[1].CSIDL := CSIDL_APPDATA;
  Result[2].Token := '$(DOCUMENTOS)';    Result[2].CSIDL := CSIDL_PERSONAL;
  Result[3].Token := '$(PUBLICO)'; Result[3].CSIDL := CSIDL_COMMON_DOCUMENTS;
  Result[4].Token := '$(PROGRAMDATA)'; Result[4].CSIDL := CSIDL_COMMON_APPDATA;
  Result[5].Token := '$(DESKTOP)'; Result[5].CSIDL := CSIDL_DESKTOPDIRECTORY;
  Result[6].Token := '$(USERPROFILE)';   Result[6].CSIDL := CSIDL_PROFILE;
  Result[7].Token := '$(APPDIR)';        Result[7].CSIDL := -1;
  Result[7].Custom := GetAppDir;
end;

function ResolveToken(const AMap: TTokenMap): string;
begin
  if AMap.CSIDL = -1 then
    Result := AMap.Custom()
  else
    Result := GetFolderByCSIDL(AMap.CSIDL);
end;

// ---------------------------------------------------------------------------
// PathToToken: busca la ruta base más larga que sea prefijo de APath
// ---------------------------------------------------------------------------
function PathToToken(const APath: string): string;
var
  AMap       : TArray<TTokenMap>;
  Ruta      : string;
  MejorTok  : string;
  MejorBase : string;
  BaseReal  : string;
  i         : Integer;
begin
  Result := '';
  if APath <> '' then
  begin
  Result    := APath;
  Ruta      := ExcludeTrailingPathDelimiter(APath);
  MejorTok  := '';
  MejorBase := '';
  AMap       := BuildMap;

  for i := 0 to High(AMap) do
  begin
    BaseReal := ExcludeTrailingPathDelimiter(ResolveToken(AMap[i]));
    if BaseReal <> '' then
    begin
      // Coincidencia exacta o Ruta empieza por BaseReal + separador
      if SameText(Ruta, BaseReal) or
         StartsText(IncludeTrailingPathDelimiter(BaseReal), Ruta) then
      begin
        // Nos quedamos con la base más larga (más específica)
        if Length(BaseReal) > Length(MejorBase) then
        begin
          MejorBase := BaseReal;
          MejorTok  := AMap[i].Token;
        end;
      end;
    end;
  end;

  if MejorBase <> '' then
  begin
    if SameText(Ruta, MejorBase) then
      Result := MejorTok
    else
      Result := MejorTok + Copy(Ruta, Length(MejorBase) + 1, MaxInt);
  end;
  end;
end;

// ---------------------------------------------------------------------------
// ExpandPathTokens: sustituye cada $(TOKEN) por su ruta real
// ---------------------------------------------------------------------------
function ExpandPathTokens(const APath: string): string;
var
  AMap   : TArray<TTokenMap>;
  i     : Integer;
  Base  : string;
begin
  Result := APath;
  if Result <> '' then
  begin
    AMap := BuildMap;
    for i := 0 to High(AMap) do
      if ContainsText(Result, AMap[i].Token) then
      begin
        Base := ExcludeTrailingPathDelimiter(ResolveToken(AMap[i]));
        Result := ReplaceText(Result, AMap[i].Token, Base);
      end;
  end;
end;

end.
