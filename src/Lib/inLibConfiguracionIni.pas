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
// Deja el INI en el formato que entiende la API de perfiles de Windows
// (TIniFile): fines de línea CR+LF y, si traía BOM UTF-8, UTF-16 con BOM.
// No toca un archivo que ya está bien ni uno que no existe.
procedure NormalizarFormatoIni(const ARutaIni: string);

implementation

uses
  System.IniFiles, System.IOUtils, System.SysUtils;

const
  CODEPAGE_UTF8 = 65001;

// La API de perfiles de Windows solo toma CR+LF como fin de línea. Un INI
// escrito por otra herramienta con CR+CR+LF (Python en modo texto con
// '\r\n'), CR o LF sueltos queda con claves pegadas al reescribirlo:
// «PoolMax=30» + «Schema=» acaba en «PoolMax=30<CR>Schema=». Con BOM
// UTF-8 la API no reconoce la primera sección y la duplica al final
// (FZ-ISSUE-945).
function NormalizarFinesLineaIni(const ATexto: string): string;
begin
  Result := ATexto;
  while Pos(#13#13#10, Result) > 0 do
    Result := StringReplace(
      Result,
      #13#13#10,
      #13#10,
      [rfReplaceAll]);
  Result := AdjustLineBreaks(Result, tlbsCRLF);
  if (Result <> '') and
     not Result.EndsWith(#13#10) then
    Result := Result + #13#10;
end;

procedure NormalizarFormatoIni(const ARutaIni: string);
var
  aBytes: TBytes;
  bCambiarCodificacion: Boolean;
  iPreambulo: Integer;
  oCodificacion: TEncoding;
  oDestino: TEncoding;
  sNormalizado: string;
  sTexto: string;
begin
  if (Trim(ARutaIni) <> '') and
     FileExists(ARutaIni) then
  begin
    aBytes := TFile.ReadAllBytes(ARutaIni);
    oCodificacion := nil;
    iPreambulo := TEncoding.GetBufferEncoding(
      aBytes,
      oCodificacion,
      TEncoding.Default);
    sTexto := oCodificacion.GetString(
      aBytes,
      iPreambulo,
      Length(aBytes) - iPreambulo);
    sNormalizado := NormalizarFinesLineaIni(sTexto);
    // UTF-16 conserva cualquier carácter y la API lo lee sin conversión.
    bCambiarCodificacion :=
      (iPreambulo > 0) and
      (oCodificacion.CodePage = CODEPAGE_UTF8);
    if bCambiarCodificacion then
      oDestino := TEncoding.Unicode
    else
      oDestino := oCodificacion;
    if bCambiarCodificacion or
       (sNormalizado <> sTexto) then
    begin
      if iPreambulo > 0 then
        aBytes := oDestino.GetPreamble + oDestino.GetBytes(sNormalizado)
      else
        aBytes := oDestino.GetBytes(sNormalizado);
      TFile.WriteAllBytes(ARutaIni, aBytes);
    end;
  end;
end;

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
  sRuta: string;
begin
  sRuta := RutaIniAplicacion(ADirectorio);
  NormalizarFormatoIni(sRuta);
  oIni := TIniFile.Create(sRuta);
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
