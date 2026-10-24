{******************************************************************************}
{  MovilConfig: configuración única y migración de las apps anteriores.        }
{  FZ-ISSUE-353. Copyright (c) Alejandro Laorden Hidalgo.                      }
{******************************************************************************}
unit MovilConfig;

interface

uses System.SysUtils;

type
  TMovilConfig = class
  private
    FRuta: string;
    procedure ImportarAnterior;
  public
    Url: string;
    Token: string;
    Operario: string;
    Dispositivo: string;
    UrlStock: string;
    constructor Create;
    procedure Guardar;
    function CarpetaIdentidad: string;
  end;

implementation

uses System.IOUtils, System.IniFiles, System.Hash,
  ConfiguracionClienteMovil, TraduccionMovil;

constructor TMovilConfig.Create;
var
  oIni: TIniFile;
begin
  inherited Create;
  FRuta := TPath.Combine(TPath.GetDocumentsPath, 'viracashmovil.ini');
  Url := cUrlApiMovil;
  if not TFile.Exists(FRuta) then
    ImportarAnterior;
  oIni := TIniFile.Create(FRuta);
  try
    Url := oIni.ReadString('servidor', 'url', Url);
    Token := oIni.ReadString('servidor', 'token', Token);
    Operario := oIni.ReadString('dispositivo', 'operario', Operario);
    Dispositivo := oIni.ReadString('dispositivo', 'nombre', Dispositivo);
    UrlStock := oIni.ReadString('stock', 'url', '');
  finally
    oIni.Free;
  end;
end;

procedure TMovilConfig.ImportarAnterior;
var
  sNombre: string;
  sRuta: string;
  oIni: TIniFile;
begin
  for sNombre in ['recuento.ini', 'ventas.ini', 'fotosnube.ini'] do
  begin
    sRuta := TPath.Combine(TPath.GetDocumentsPath, sNombre);
    if (Token = '') and TFile.Exists(sRuta) then
    begin
      oIni := TIniFile.Create(sRuta);
      try
        if sNombre = 'fotosnube.ini' then
        begin
          Url := oIni.ReadString('FotosNube', 'Url', Url);
          Url := StringReplace(Url, 'fotos/subir.php', '', []);
          Token := oIni.ReadString('FotosNube', 'ApiKey', '');
        end
        else
        begin
          Url := oIni.ReadString('servidor', 'url', Url);
          Token := oIni.ReadString('servidor', 'token', '');
          Operario := oIni.ReadString('dispositivo', 'operario', '');
          Dispositivo := oIni.ReadString('dispositivo', 'nombre', '');
        end;
      finally
        oIni.Free;
      end;
    end;
  end;
end;

procedure TMovilConfig.Guardar;
var
  oIni: TIniFile;
begin
  Url := Trim(Url);
  if not Url.StartsWith('https://', True) then
    raise Exception.Create(Tr('La URL de la API debe usar HTTPS.'));
  if (Pos('?', Url) > 0) or (Pos('#', Url) > 0) or
     (Pos('@', Url) > 0) then
    raise Exception.Create(
      Tr('Indica la URL base sin parámetros ni usuario.'));
  if not Url.EndsWith('/') then
    Url := Url + '/';
  Token := Trim(Token);
  if Length(Token) < 32 then
    raise Exception.Create(Tr('Introduce una clave API válida.'));
  oIni := TIniFile.Create(FRuta);
  try
    oIni.WriteString('servidor', 'url', Url);
    oIni.WriteString('servidor', 'token', Token);
    oIni.WriteString('dispositivo', 'operario', Operario);
    oIni.WriteString('dispositivo', 'nombre', Dispositivo);
    oIni.WriteString('stock', 'url', UrlStock);
    oIni.UpdateFile;
  finally
    oIni.Free;
  end;
end;

function TMovilConfig.CarpetaIdentidad: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'viracashmovil');
  Result := TPath.Combine(Result,
    THashSHA2.GetHashString(Url + #10 + Token));
  ForceDirectories(Result);
end;

end.
