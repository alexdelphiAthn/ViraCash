{******************************************************************************}
{                                                                              }
{  Módulo:       UParametrosPrueba                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de aplicación en memoria para la careta de pruebas.            }
{******************************************************************************}
unit UParametrosPrueba;

interface

uses
  inLibParametrosIntf,
  inLibLicenciaAplicacion;

type
  { Implementación mínima de IParametrosAplicacion. Sustituye a la tabla
    de parámetros de ViraCash para que la careta pueda reutilizar tal
    cual el cliente HTTP y el serializador de ventas. }
  TParametrosPrueba = class(TInterfacedObject, IParametros,
    IParametrosAplicacion)
  private
    FReferencia: string;
    FToken: string;
    FUrl: string;
    function GetBool(
      const AKey: string;
      const ADefault: Boolean = False
    ): Boolean;
    function GetInt(
      const AKey: string;
      const ADefault: Integer = 0
    ): Integer;
    function GetPath(const ANombre: string): string;
    function ImpresoraDocumentos: string;
    function Licencia: TResultadoLicenciaAplicacion;
    function GetString(
      const AKey: string;
      const ADefault: string = ''
    ): string;
  public
    constructor Create(const AUrl, AToken, AReferencia: string);
  end;

implementation

uses
  System.SysUtils;

constructor TParametrosPrueba.Create(
  const AUrl, AToken, AReferencia: string);
begin
  inherited Create;
  FUrl := Trim(AUrl);
  FToken := Trim(AToken);
  FReferencia := Trim(AReferencia);
end;

function TParametrosPrueba.GetString(
  const AKey: string; const ADefault: string): string;
begin
  if SameText(AKey, 'appApiUrl') then
    Result := FUrl
  else if SameText(AKey, 'appApiToken') then
    Result := FToken
  else if SameText(AKey, 'appApiReferencia') then
    Result := FReferencia
  else
    Result := ADefault;
end;

function TParametrosPrueba.GetBool(
  const AKey: string; const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
end;

function TParametrosPrueba.GetInt(
  const AKey: string; const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosPrueba.GetPath(const ANombre: string): string;
begin
  Result := '';
end;

function TParametrosPrueba.ImpresoraDocumentos: string;
begin
  Result := '';
end;

function TParametrosPrueba.Licencia:
  TResultadoLicenciaAplicacion;
begin
  Result := TResultadoLicenciaAplicacion.CrearNoComprobada;
end;

end.
