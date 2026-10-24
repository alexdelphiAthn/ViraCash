{******************************************************************************}
{                                                                              }
{  Módulo:       VentasConfig                                                  }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Configuración local de la app (URL de la API, token y referencia de la    }
{    instalación). Se persiste en un INI en el directorio de documentos.       }
{    Singleton global oConfig, igual que en la app de recuento.                }
{******************************************************************************}
unit VentasConfig;

interface

uses SesionClienteMovil;

type
  TVentasConfig = class
  private
    FMostrarMargen: Boolean;
    FReferencia: string;
    FToken: string;
    FUrlBase: string;
    function RutaIni: string;
  public
    Sesion: ISesionClienteMovil;
    ConfiguracionCentral: Boolean;
    CarpetaCache: string;
    constructor Create;
    function EstaConfigurado: Boolean;
    function RutaCacheFotos: string;
    procedure Cargar;
    procedure Guardar;
    property MostrarMargen: Boolean read FMostrarMargen
      write FMostrarMargen;
    property Referencia: string read FReferencia write FReferencia;
    property Token: string read FToken write FToken;
    property UrlBase: string read FUrlBase write FUrlBase;
  end;

var
  oConfig: TVentasConfig;

implementation

uses
  System.SysUtils, System.IOUtils, System.IniFiles,
  ConfiguracionClienteMovil;

constructor TVentasConfig.Create;
begin
  inherited Create;
  FUrlBase := cUrlApiMovil;
  FToken := cTokenApiMovil;
  FReferencia := cReferenciaInstalacionMovil;
  FMostrarMargen := True;
  Cargar;
end;

function TVentasConfig.RutaIni: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'ventas.ini');
end;

function TVentasConfig.RutaCacheFotos: string;
begin
  if CarpetaCache <> '' then
    Result := CarpetaCache
  else
    Result := TPath.Combine(TPath.GetHomePath, 'cachefotos');
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
end;

procedure TVentasConfig.Cargar;
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(RutaIni);
  try
    FUrlBase := oIni.ReadString('servidor', 'url', FUrlBase);
    FToken := oIni.ReadString('servidor', 'token', FToken);
    FReferencia := oIni.ReadString('servidor', 'referencia', FReferencia);
    FMostrarMargen := oIni.ReadBool('vista', 'margen', True);
  finally
    FreeAndNil(oIni);
  end;
end;

procedure TVentasConfig.Guardar;
var
  oIni: TIniFile;
begin
  oIni := TIniFile.Create(RutaIni);
  try
    oIni.WriteString('servidor', 'url', FUrlBase);
    oIni.WriteString('servidor', 'token', FToken);
    oIni.WriteString('servidor', 'referencia', FReferencia);
    oIni.WriteBool('vista', 'margen', FMostrarMargen);
    oIni.UpdateFile;
  finally
    FreeAndNil(oIni);
  end;
end;

function TVentasConfig.EstaConfigurado: Boolean;
begin
  // Solo URL y token: la referencia la resuelve el servidor a partir de la
  // credencial, y ya viene incrustada en la ruta de cada foto. El campo se
  // conserva a efectos informativos.
  Result := (Trim(FUrlBase) <> '') and (Trim(FToken) <> '');
end;

initialization
  oConfig := TVentasConfig.Create;

finalization
  FreeAndNil(oConfig);

end.
