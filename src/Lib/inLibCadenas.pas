{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCadenas                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Utilidades de cadenas y validación de símbolos por perfil.                }
{******************************************************************************}
unit inLibCadenas;

interface

uses
  inLibPerfilesUsuarioIntf;

type
  TArrayCadenas = array of string;

function HayCoincidencia(
  const ACadena, ACaracteres: string): string;
function SimbolosProhibidos(
  const ACadena: string;
  const APerfilesUsuario: ILectorPerfilesUsuario): Boolean; overload;
// APermitidos: símbolos que se aceptan aunque la lista los prohíba
function SimbolosProhibidos(
  const ACadena: string;
  const APerfilesUsuario: ILectorPerfilesUsuario;
  const APermitidos: string): Boolean; overload;
function PrimerSimboloProhibido(const ACadena: string;
  const APerfilesUsuario: ILectorPerfilesUsuario;
  const APermitidos: string = ''): string;
function SepararAnsi(
  const ACadena, ASeparador: string): TArrayCadenas;
function ContarOcurrenciasAnsi(
  const ACadena, ASubcadena: string): Integer;

implementation

uses
  System.SysUtils;

const
  SIMBOLOS_PREDETERMINADOS =
    'ºª,="'':;·|.,¨{}~^][()/+€%*';

function HayCoincidencia(
  const ACadena, ACaracteres: string): string;
var
  bCoincidencia: Boolean;
  i: Integer;
  j: Integer;
begin
  Result := '';
  bCoincidencia := False;
  i := 1;
  while (i <= Length(ACadena)) and
        not bCoincidencia do
  begin
    j := 1;
    while (j <= Length(ACaracteres)) and
          not bCoincidencia do
    begin
      if ACadena[i] = ACaracteres[j] then
      begin
        bCoincidencia := True;
        Result := ACadena[i];
      end;
      Inc(j);
    end;
    Inc(i);
  end;
end;

function SimbolosProhibidos(
  const ACadena: string;
  const APerfilesUsuario: ILectorPerfilesUsuario): Boolean;
begin
  Result := SimbolosProhibidos(ACadena, APerfilesUsuario, '');
end;

function SimbolosProhibidos(
  const ACadena: string;
  const APerfilesUsuario: ILectorPerfilesUsuario;
  const APermitidos: string): Boolean;
begin
  Result := PrimerSimboloProhibido(ACadena, APerfilesUsuario,
    APermitidos) <> '';
end;

function PrimerSimboloProhibido(
  const ACadena: string;
  const APerfilesUsuario: ILectorPerfilesUsuario;
  const APermitidos: string): string;
var
  i: Integer;
  sSimbolos: string;
begin
  sSimbolos := SIMBOLOS_PREDETERMINADOS;
  if Assigned(APerfilesUsuario) then
    sSimbolos := APerfilesUsuario.ObtenerValorPerfil(
      'inLibtb',
      'oSimbolosProhibidos',
      SIMBOLOS_PREDETERMINADOS);
  for i := 1 to Length(APermitidos) do
    sSimbolos := StringReplace(
      sSimbolos, APermitidos[i], '', [rfReplaceAll]);
  Result := HayCoincidencia(
    ACadena, sSimbolos);
end;

function ContarOcurrenciasAnsi(
  const ACadena, ASubcadena: string): Integer;
var
  iLongitud: Integer;
  pCadena: PChar;
  pSubcadena: PChar;
begin
  Result := 0;
  iLongitud := Length(ASubcadena);
  if iLongitud > 0 then
  begin
    pSubcadena := PChar(Pointer(ASubcadena));
    pCadena := PChar(Pointer(ACadena));
    while Assigned(pCadena) do
    begin
      pCadena := AnsiStrPos(
        pCadena, pSubcadena);
      if Assigned(pCadena) then
      begin
        Inc(Result);
        Inc(pCadena, iLongitud);
      end;
    end;
  end;
end;

function SepararAnsi(
  const ACadena, ASeparador: string): TArrayCadenas;
var
  i: Integer;
  iLongitud: Integer;
  pCadena: PChar;
  pFinal: PChar;
  pSeparador: PChar;
begin
  SetLength(
    Result,
    ContarOcurrenciasAnsi(
      ACadena, ASeparador) + 1);
  pCadena := PChar(ACadena);
  pSeparador := PChar(ASeparador);
  iLongitud := Length(ASeparador);
  i := 0;
  repeat
    pFinal := AnsiStrPos(
      pCadena, pSeparador);
    if not Assigned(pFinal) then
      pFinal := AnsiStrScan(
        pCadena, #0);
    SetString(
      Result[i],
      pCadena,
      pFinal - pCadena);
    pCadena := pFinal + iLongitud;
    Inc(i);
  until pFinal^ = #0;
end;

end.
