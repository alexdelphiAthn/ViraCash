{******************************************************************************}
{                                                                              }
{  Modulo:       inLibAvisoHuecosNumeracion                                    }
{    Tipo:       Libreria de dominio                                           }
{ Version:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Decide cuando avisar de huecos en la numeracion de una serie de caja.     }
{    FZ-ISSUE-394: los huecos historicos (p. ej. de una migracion) se          }
{    avisan una vez por sesion y serie; solo se repite si aparecen mas.        }
{******************************************************************************}
unit inLibAvisoHuecosNumeracion;

interface

uses
  System.Generics.Collections;

type
  TRegistroAvisosHuecosNumeracion = class
  private
    FAvisados: TDictionary<string, Int64>;
    function Clave(const AEmpresa, ASerie: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    // Anota los huecos actuales de la serie y dice si hay que avisar:
    // la primera vez que se ven y cada vez que aumentan.
    function DebeAvisar(const AEmpresa, ASerie: string;
      AHuecos: Int64): Boolean;
  end;

// Números que faltan entre el mínimo y el máximo de la serie.
function HuecosNumeracion(AFilas, AMinimo, AMaximo: Int64): Int64;

// Registro de la sesión de la aplicación.
function RegistroAvisosHuecosNumeracion: TRegistroAvisosHuecosNumeracion;

implementation

uses
  System.SysUtils;

var
  FRegistroSesion: TRegistroAvisosHuecosNumeracion;

function HuecosNumeracion(AFilas, AMinimo, AMaximo: Int64): Int64;
begin
  Result := 0;
  if AFilas > 0 then
    Result := (AMaximo - AMinimo + 1) - AFilas;
  if Result < 0 then
    Result := 0;
end;

function RegistroAvisosHuecosNumeracion: TRegistroAvisosHuecosNumeracion;
begin
  if FRegistroSesion = nil then
    FRegistroSesion := TRegistroAvisosHuecosNumeracion.Create;
  Result := FRegistroSesion;
end;

constructor TRegistroAvisosHuecosNumeracion.Create;
begin
  inherited Create;
  FAvisados := TDictionary<string, Int64>.Create;
end;

destructor TRegistroAvisosHuecosNumeracion.Destroy;
begin
  FreeAndNil(FAvisados);
  inherited;
end;

function TRegistroAvisosHuecosNumeracion.Clave(
  const AEmpresa, ASerie: string): string;
begin
  Result := UpperCase(Trim(AEmpresa)) + #9 + UpperCase(Trim(ASerie));
end;

function TRegistroAvisosHuecosNumeracion.DebeAvisar(
  const AEmpresa, ASerie: string; AHuecos: Int64): Boolean;
var
  iAnteriores: Int64;
  sClave: string;
begin
  sClave := Clave(AEmpresa, ASerie);
  if not FAvisados.TryGetValue(sClave, iAnteriores) then
    iAnteriores := 0;
  Result := AHuecos > iAnteriores;
  // Se guarda siempre el valor actual: si se rellena un hueco y después
  // aparece otro nuevo, vuelve a avisar.
  FAvisados.AddOrSetValue(sClave, AHuecos);
end;

initialization

finalization
  FreeAndNil(FRegistroSesion);

end.
