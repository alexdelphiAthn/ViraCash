{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDir                                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Acceso a las carpetas de Windows utilizadas por la aplicación.            }
{******************************************************************************}
unit inLibDir;

interface

const
  CSIDL_MYDOCUMENTS = $000C;
  CSIDL_DESKTOPDIRECTORY = $0010;
  CSIDL_LOCAL_APPDATA = $001C;

function DirApp: String;
function GetSpecialFolderPath(ACarpetaCSIDL: Integer): string;
function GetUserFolder: String;
function GetUserDeskFolder: String;
function GetLogFolder: String;
function GetUserFolderTickets: String;

implementation

uses
  Forms, ShlObj, SysUtils, Windows, System.IOUtils, System.IniFiles;

function GetSpecialFolderPath(
  ACarpetaCSIDL: Integer): string;
var
  aRuta: array [0..MAX_PATH] of Char;
begin
  if SHGetFolderPath(
       0,
       ACarpetaCSIDL,
       0,
       0,
       aRuta) = S_OK then
    Result := aRuta
  else
    Result := '';
end;

function GetUserFolderTickets: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_LOCAL_APPDATA) +
    '\viracash\tickets\';
  ForceDirectories(Result);
end;

function GetUserFolder: String;
var
  sAnterior: string;
  sPerfil: string;
  sDestino: string;
  sMarca: string;
  oIni: TIniFile;
  bPrimeraApertura: Boolean;
begin
  Result := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA) + '\viracash\';
  sMarca := Result + '.perfiles_importados';
  bPrimeraApertura := not FileExists(sMarca);
  ForceDirectories(Result);
  sAnterior := GetSpecialFolderPath(CSIDL_LOCAL_APPDATA) + '\factuzam\';
  if bPrimeraApertura and DirectoryExists(sAnterior) then
  begin
    for sPerfil in TDirectory.GetFiles(sAnterior, '*.ini') do
    begin
      sDestino := ExtractFileName(sPerfil);
      if SameText(sDestino, 'fzam.ini') then
        sDestino := 'vcash.ini';
      sDestino := Result + sDestino;
      if not FileExists(sDestino) then
      begin
        TFile.Copy(sPerfil, sDestino, False);
        // Conservar el identificador usado por las credenciales de Windows.
        oIni := TIniFile.Create(sDestino);
        try
          if not oIni.ValueExists('ConnData', 'ProfileId') then
            oIni.WriteString('ConnData', 'ProfileId',
              ChangeFileExt(ExtractFileName(sPerfil), ''));
        finally
          oIni.Free;
        end;
      end;
    end;
    TFile.WriteAllText(sMarca, 'ViraCash');
  end;
end;

function GetLogFolder: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_LOCAL_APPDATA) +
    '\viracash\log\';
  ForceDirectories(
    Result + 'archive\');
  ForceDirectories(Result);
end;

function GetUserDeskFolder: String;
begin
  Result := GetSpecialFolderPath(
    CSIDL_DESKTOPDIRECTORY);
end;

function DirApp: String;
begin
  Result := ExtractFilePath(
    Application.ExeName);
end;

end.
