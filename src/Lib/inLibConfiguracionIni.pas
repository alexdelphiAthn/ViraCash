{******************************************************************************}
{                                                                              }
{  Módulo:       inLibConfiguracionIni                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura, escritura y resolución del INI principal de la aplicación.       }
{******************************************************************************}
unit inLibConfiguracionIni;

interface

// Perfil INI posicional ('viracash_bazar.ini'), antes o después de los
// conmutadores; vacío si no hay. Quien relanza ViraCash lo reenvía
// para no caer en el perfil por defecto (FZ-ISSUE-329). Escrito sin
// extensión ('viracash_bazar') es el mismo perfil: se le añade '.ini'.
function ParametroPerfilIni(const AParametro: string): string;
function PerfilIniArranque: string;
function ConstruirRutaIni(
  const ADirectorio: string;
  const AEjecutable: string;
  const AParametro: string): string;
function RutaIniAplicacion(
  const ADirectorio: string): string;
function LeerCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValorPredeterminado: string;
  const ADirectorio: string): string;
procedure EscribirCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValor: string;
  const ADirectorio: string);

implementation

uses
  System.IniFiles, System.SysUtils;

function LeerPerfilArranque(const AEjecutable: string): string;
var
  sRuta: string;
  oIni: TIniFile;
begin
  Result := '';
  sRuta := ChangeFileExt(AEjecutable, '.arranque.ini');
  if FileExists(sRuta) then
  begin
    oIni := TIniFile.Create(sRuta);
    try
      Result := Trim(oIni.ReadString('Arranque', 'Perfil', ''));
    finally
      oIni.Free;
    end;
    if (Result <> '') and
       ((ExtractFileName(Result) <> Result) or
        (Pos(':', Result) > 0) or
        not SameText(ExtractFileExt(Result), '.ini')) then
      raise EConvertError.Create(
        'El perfil de arranque debe ser un nombre de archivo INI.');
  end;
end;

function ParametroPerfilIni(const AParametro: string): string;
begin
  Result := Trim(AParametro);
  if (Result <> '') and CharInSet(Result[1], ['/', '-']) then
    Result := ''
  // Tomado tal cual, el nombre sin extensión no encontraba el perfil y se
  // creaba otro con la conexión por defecto: la licencia se registraba
  // contra una base que no era la del perfil.
  else if (Result <> '') and (ExtractFileExt(Result) = '') then
    Result := Result + '.ini';
end;

function PerfilIniArranque: string;
var
  i: Integer;
begin
  Result := '';
  i := 1;
  while (i <= ParamCount) and (Result = '') do
  begin
    Result := ParametroPerfilIni(ParamStr(i));
    Inc(i);
  end;
end;

function ConstruirRutaIni(
  const ADirectorio: string;
  const AEjecutable: string;
  const AParametro: string): string;
var
  sParametro: string;
  sNombreFichero: string;
begin
  sParametro := ParametroPerfilIni(AParametro);
  if sParametro = '' then
    sParametro := LeerPerfilArranque(AEjecutable);
  if sParametro = '' then
    sNombreFichero := ChangeFileExt(
      ExtractFileName(AEjecutable),
      '.ini')
  else
    sNombreFichero := sParametro;
  Result := ADirectorio + sNombreFichero;
end;

function RutaIniAplicacion(
  const ADirectorio: string): string;
begin
  Result := ConstruirRutaIni(
    ADirectorio,
    ParamStr(0),
    PerfilIniArranque);
end;

procedure EscribirCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValor: string;
  const ADirectorio: string);
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(
    RutaIniAplicacion(ADirectorio));
  try
    oIni.WriteString(
      ASeccion,
      AClave,
      AValor);
  finally
    FreeAndNil(oIni);
  end;
end;

function LeerCadenaIni(
  const ASeccion: string;
  const AClave: string;
  const AValorPredeterminado: string;
  const ADirectorio: string): string;
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(
    RutaIniAplicacion(ADirectorio));
  try
    Result := oIni.ReadString(
      ASeccion,
      AClave,
      AValorPredeterminado);
    if Result = AValorPredeterminado then
    begin
      EscribirCadenaIni(
        ASeccion,
        AClave,
        AValorPredeterminado,
        ADirectorio);
    end;
  finally
    FreeAndNil(oIni);
  end;
end;

end.
