{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceCantidades                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Compatibilidad de cantidades del balance (FZ-ISSUE-532).                  }
{******************************************************************************}
unit inLibBalanceCantidades;

interface

uses
  System.Generics.Collections;

type
  TUnidadArticuloBalance = reference to function(
    const ACodigoArticulo: string): string;

  TCompatibilidadCantidadBalance = record
  private
    FUnidad: string;
    FConFilas: Boolean;
    FIncompatible: Boolean;
  public
    procedure Agregar(const AUnidad: string);
    function Sumable: Boolean;
  end;

  TIndiceCantidadesBalance = class
  private
    FGrupos: TDictionary<string, TCompatibilidadCantidadBalance>;
    FTotal: TCompatibilidadCantidadBalance;
    function ClaveGrupo(const ACodigos: array of string;
      ANivel: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Agregar(const AUnidad: string;
      const ACodigos: array of string);
    function GrupoSumable(const ACodigos: array of string;
      ANivel: Integer): Boolean;
    function TotalSumable: Boolean;
  end;

implementation

uses
  System.SysUtils;

procedure TCompatibilidadCantidadBalance.Agregar(const AUnidad: string);
var
  sUnidad: string;
begin
  sUnidad := UpperCase(Trim(AUnidad));
  // Una unidad desconocida no demuestra compatibilidad, ni con otra vacía.
  FIncompatible := FIncompatible or (sUnidad = '') or
    (FConFilas and (FUnidad <> sUnidad));
  FUnidad := sUnidad;
  FConFilas := True;
end;

function TCompatibilidadCantidadBalance.Sumable: Boolean;
begin
  Result := FConFilas and not FIncompatible;
end;

constructor TIndiceCantidadesBalance.Create;
begin
  inherited Create;
  FGrupos := TDictionary<string, TCompatibilidadCantidadBalance>.Create;
end;

destructor TIndiceCantidadesBalance.Destroy;
begin
  FreeAndNil(FGrupos);
  inherited Destroy;
end;

function TIndiceCantidadesBalance.ClaveGrupo(
  const ACodigos: array of string; ANivel: Integer): string;
var
  i: Integer;
begin
  if (ANivel < 1) or (ANivel > Length(ACodigos)) then
    raise EArgumentOutOfRangeException.Create('Nivel de balance inválido');
  Result := '';
  for i := 0 to ANivel - 1 do
    Result := Result + IntToStr(Length(ACodigos[i])) + ':' + ACodigos[i];
end;

procedure TIndiceCantidadesBalance.Agregar(const AUnidad: string;
  const ACodigos: array of string);
var
  i: Integer;
  sClave: string;
  oCompatibilidad: TCompatibilidadCantidadBalance;
begin
  FTotal.Agregar(AUnidad);
  for i := 1 to Length(ACodigos) do
  begin
    sClave := ClaveGrupo(ACodigos, i);
    if not FGrupos.TryGetValue(sClave, oCompatibilidad) then
      oCompatibilidad := Default(TCompatibilidadCantidadBalance);
    oCompatibilidad.Agregar(AUnidad);
    FGrupos.AddOrSetValue(sClave, oCompatibilidad);
  end;
end;

function TIndiceCantidadesBalance.GrupoSumable(
  const ACodigos: array of string; ANivel: Integer): Boolean;
var
  oCompatibilidad: TCompatibilidadCantidadBalance;
begin
  Result := FGrupos.TryGetValue(ClaveGrupo(ACodigos, ANivel),
    oCompatibilidad) and oCompatibilidad.Sumable;
end;

function TIndiceCantidadesBalance.TotalSumable: Boolean;
begin
  Result := FTotal.Sumable;
end;

end.
