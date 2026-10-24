{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSqlSeguro                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida identificadores SQL dinámicos contra listas blancas.               }
{******************************************************************************}
unit inLibSqlSeguro;

interface

uses
  System.SysUtils,
  System.Classes,
  inLibDialectoSqlIntf;

type
  EIdentificadorSqlNoPermitido = class(Exception);

function DelimitarIdentificadorSql(
  const AIdentificador: string;
  const AListaPermitida: array of string): string; overload;
function DelimitarIdentificadorSql(
  const AIdentificador: string;
  AListaPermitida: TStrings): string; overload;
function DelimitarIdentificadorSql(
  const ADialecto: IDialectoSql;
  const AIdentificador: string;
  const AListaPermitida: array of string): string; overload;
function DelimitarIdentificadorSql(
  const ADialecto: IDialectoSql;
  const AIdentificador: string;
  AListaPermitida: TStrings): string; overload;

implementation

uses
  inLibConexionPerfilIntf,
  inLibDialectosSql,
  inLibMsgSqlSeguro;

function EsCaracterInicialValido(ACaracter: Char): Boolean;
begin
  Result := CharInSet(ACaracter, ['A'..'Z', 'a'..'z', '_']);
end;

function EsCaracterValido(ACaracter: Char): Boolean;
begin
  Result := EsCaracterInicialValido(ACaracter) or
            CharInSet(ACaracter, ['0'..'9']);
end;

procedure ExigirSintaxisIdentificador(const AIdentificador: string);
var
  i: Integer;
  bValido: Boolean;
begin
  bValido := AIdentificador <> '';
  if bValido then
    bValido := EsCaracterInicialValido(AIdentificador[1]);
  i := 2;
  while bValido and (i <= Length(AIdentificador)) do
  begin
    bValido := EsCaracterValido(AIdentificador[i]);
    Inc(i);
  end;
  if not bValido then
    raise EIdentificadorSqlNoPermitido.CreateFmt(
      SIdentificadorSqlInvalido,
      [AIdentificador]);
end;

function DelimitarIdentificadorSql(
  const AIdentificador: string;
  const AListaPermitida: array of string): string;
begin
  Result := DelimitarIdentificadorSql(
    CrearDialectoSql(mbMariaDB),
    AIdentificador,
    AListaPermitida);
end;

function DelimitarIdentificadorSql(
  const ADialecto: IDialectoSql;
  const AIdentificador: string;
  const AListaPermitida: array of string): string;
var
  i: Integer;
  bPermitido: Boolean;
begin
  if not Assigned(ADialecto) then
    raise EArgumentNilException.Create(
      SErrorDialectoSqlNoAsignado);
  ExigirSintaxisIdentificador(AIdentificador);
  bPermitido := False;
  i := Low(AListaPermitida);
  while (not bPermitido) and (i <= High(AListaPermitida)) do
  begin
    bPermitido := SameText(AIdentificador, AListaPermitida[i]);
    Inc(i);
  end;
  if not bPermitido then
    raise EIdentificadorSqlNoPermitido.CreateFmt(
      SIdentificadorSqlNoPermitido,
      [AIdentificador]);
  Result := ADialecto.DelimitarIdentificador(AIdentificador);
end;

function DelimitarIdentificadorSql(
  const AIdentificador: string;
  AListaPermitida: TStrings): string;
begin
  Result := DelimitarIdentificadorSql(
    CrearDialectoSql(mbMariaDB),
    AIdentificador,
    AListaPermitida);
end;

function DelimitarIdentificadorSql(
  const ADialecto: IDialectoSql;
  const AIdentificador: string;
  AListaPermitida: TStrings): string;
var
  i: Integer;
  bPermitido: Boolean;
begin
  if not Assigned(ADialecto) then
    raise EArgumentNilException.Create(
      SErrorDialectoSqlNoAsignado);
  ExigirSintaxisIdentificador(AIdentificador);
  bPermitido := False;
  i := 0;
  while (not bPermitido) and Assigned(AListaPermitida) and
        (i < AListaPermitida.Count) do
  begin
    bPermitido := SameText(AIdentificador, AListaPermitida[i]);
    Inc(i);
  end;
  if not bPermitido then
    raise EIdentificadorSqlNoPermitido.CreateFmt(
      SIdentificadorSqlNoPermitido,
      [AIdentificador]);
  Result := ADialecto.DelimitarIdentificador(AIdentificador);
end;

end.
