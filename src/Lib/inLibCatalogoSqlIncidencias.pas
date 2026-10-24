{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCatalogoSqlIncidencias                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Conserva la última causa de fallback con ciclo de vida explícito.         }
{******************************************************************************}
unit inLibCatalogoSqlIncidencias;

interface

uses
  System.Generics.Collections,
  System.SyncObjs,
  inLibCatalogoSqlIntf;

type
  TRegistroIncidenciasSql = class(
    TInterfacedObject,
    IRegistroIncidenciasSql)
  private
    FBloqueo: TCriticalSection;
    FIncidencias: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Registrar(
      const AClavePerfil, ACausa: string);
    function ObtenerUltimaCausa(
      const AClavePerfil: string): string;
  end;

implementation

uses
  System.SysUtils;

constructor TRegistroIncidenciasSql.Create;
begin
  inherited Create;
  FBloqueo := TCriticalSection.Create;
  FIncidencias := TDictionary<string, string>.Create;
end;

destructor TRegistroIncidenciasSql.Destroy;
begin
  FreeAndNil(FIncidencias);
  FreeAndNil(FBloqueo);
  inherited;
end;

procedure TRegistroIncidenciasSql.Registrar(
  const AClavePerfil, ACausa: string);
begin
  FBloqueo.Acquire;
  try
    FIncidencias.AddOrSetValue(
      UpperCase(AClavePerfil),
      ACausa);
  finally
    FBloqueo.Release;
  end;
end;

function TRegistroIncidenciasSql.ObtenerUltimaCausa(
  const AClavePerfil: string): string;
begin
  Result := '';
  FBloqueo.Acquire;
  try
    FIncidencias.TryGetValue(
      UpperCase(AClavePerfil),
      Result);
  finally
    FBloqueo.Release;
  end;
end;

end.
