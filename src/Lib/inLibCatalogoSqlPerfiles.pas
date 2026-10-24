{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlPerfiles                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resuelve SQL base o personalizado desde un diccionario de perfiles.       }
{******************************************************************************}
unit inLibCatalogoSqlPerfiles;

interface

uses
  inLibCatalogoSqlIntf,
  inLibConexionPerfilIntf,
  inLibPerfilesUsuarioIntf;

type
  TCatalogoSqlPerfiles = class(
    TInterfacedObject,
    ICatalogoSql)
  private
    FPerfil: TProfileDicc;
    FMotor: TMotorBBDD;
    function PerfilActivo(const AValor: string): Boolean;
  public
    constructor Create(APerfil: TProfileDicc); overload;
    constructor Create(
      APerfil: TProfileDicc;
      AMotor: TMotorBBDD); overload;
    destructor Destroy; override;
    function GetMotor: TMotorBBDD;
    function Resolver(
      const ADefinicion: TDefinicionSql): TSqlResuelto;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibCatalogoSqlValidacion;

constructor TCatalogoSqlPerfiles.Create(
  APerfil: TProfileDicc);
begin
  Create(APerfil, mbMariaDB);
end;

constructor TCatalogoSqlPerfiles.Create(
  APerfil: TProfileDicc;
  AMotor: TMotorBBDD);
var
  oPar: TPair<string, TDictValue>;
begin
  inherited Create;
  FMotor := AMotor;
  FPerfil := TProfileDicc.Create;
  if Assigned(APerfil) then
  begin
    for oPar in APerfil do
      FPerfil.AddOrSetValue(oPar.Key, oPar.Value);
  end;
end;

function TCatalogoSqlPerfiles.GetMotor: TMotorBBDD;
begin
  Result := FMotor;
end;

destructor TCatalogoSqlPerfiles.Destroy;
begin
  FreeAndNil(FPerfil);
  inherited;
end;

function TCatalogoSqlPerfiles.PerfilActivo(
  const AValor: string): Boolean;
begin
  Result := SameText(
    Copy(Trim(AValor), 1, 1), 'S');
end;

function TCatalogoSqlPerfiles.Resolver(
  const ADefinicion: TDefinicionSql): TSqlResuelto;
var
  oValidacion: TResultadoValidacionSql;
  oValor: TDictValue;
  sClave: string;
  sSqlPerfil: string;
begin
  Result := ResolverSqlBaseMotor(
    ADefinicion,
    FMotor);
  sClave := ClavePerfilSql(ADefinicion);
  if (ADefinicion.Politica <> pesSoloBase) and
     Assigned(FPerfil) and
     FPerfil.TryGetValue(sClave, oValor) and
     PerfilActivo(oValor.sValue) then
  begin
    sSqlPerfil := string(oValor.sValueText);
    oValidacion := ValidarSql(
      ADefinicion,
      sSqlPerfil,
      FMotor);
    if oValidacion.EsValido then
    begin
      Result.Texto := sSqlPerfil;
      Result.ClavePerfil := sClave;
      Result.MotivoSqlBase := '';
      Result.Origen := osPerfil;
      Result.Politica := ADefinicion.Politica;
      Result.Motor := FMotor;
    end
    else
      Result := ResolverSqlBaseMotor(
        ADefinicion,
        FMotor,
        oValidacion.Mensaje);
  end;
end;

end.
