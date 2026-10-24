{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlRegistro                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registro con propietario explícito de las definiciones SQL.               }
{******************************************************************************}
unit inLibCatalogoSqlRegistro;

interface

uses
  System.SysUtils, System.Generics.Collections,
  inLibCatalogoSqlIntf;

type
  ERegistroDefinicionesSql = class(Exception);
  TRegistroDefinicionesSql = class(
    TInterfacedObject,
    IRegistroDefinicionesSql)
  private
    FDefiniciones: TDefinicionesSql;
    FIndices: TDictionary<string, Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Agregar(
      const ADefinicion: TDefinicionSql);
    procedure AgregarRango(
      const ADefiniciones: TDefinicionesSql);
    function Cantidad: Integer;
    function ObtenerDefiniciones: TDefinicionesSql;
  end;

implementation

uses
  inLibCatalogoSqlValidacion;

resourcestring
  SErrorDefinicionSqlDuplicada =
    'La definición SQL está duplicada: %s.';
  SErrorDefinicionSqlInvalida =
    'La definición SQL %s no es válida: %s';

constructor TRegistroDefinicionesSql.Create;
begin
  inherited Create;
  FIndices := TDictionary<string, Integer>.Create;
  FDefiniciones := nil;
end;

destructor TRegistroDefinicionesSql.Destroy;
begin
  FreeAndNil(FIndices);
  FDefiniciones := nil;
  inherited;
end;

procedure TRegistroDefinicionesSql.Agregar(
  const ADefinicion: TDefinicionSql);
var
  iIndice: Integer;
  oValidacion: TResultadoValidacionSql;
  sClave: string;
  sClaveNormalizada: string;
begin
  sClave := ClavePerfilSql(ADefinicion);
  sClaveNormalizada := UpperCase(sClave);
  oValidacion := ValidarDefinicionSql(
    ADefinicion);
  if not oValidacion.EsValido then
    raise ERegistroDefinicionesSql.CreateFmt(
      SErrorDefinicionSqlInvalida,
      [sClave, oValidacion.Mensaje]);
  if FIndices.ContainsKey(sClaveNormalizada) then
    raise ERegistroDefinicionesSql.CreateFmt(
      SErrorDefinicionSqlDuplicada,
      [sClave]);
  iIndice := Length(FDefiniciones);
  SetLength(FDefiniciones, iIndice + 1);
  FDefiniciones[iIndice] := ADefinicion;
  FIndices.Add(sClaveNormalizada, iIndice);
end;

procedure TRegistroDefinicionesSql.AgregarRango(
  const ADefiniciones: TDefinicionesSql);
var
  iIndice: Integer;
begin
  for iIndice := 0 to High(ADefiniciones) do
    Agregar(ADefiniciones[iIndice]);
end;

function TRegistroDefinicionesSql.Cantidad: Integer;
begin
  Result := Length(FDefiniciones);
end;

function TRegistroDefinicionesSql.ObtenerDefiniciones:
  TDefinicionesSql;
begin
  Result := Copy(
    FDefiniciones,
    0,
    Length(FDefiniciones));
end;

end.
