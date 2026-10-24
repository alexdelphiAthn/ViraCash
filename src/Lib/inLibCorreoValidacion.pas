{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoValidacion                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación común de destinatarios de correo para cliente y transporte.    }
{******************************************************************************}
unit inLibCorreoValidacion;

interface

function EmailDocumentoValido(const AEmail: string): Boolean;
function NormalizarEmailRespuestaDocumento(
  const AEmail: string): string;

implementation

uses
  System.SysUtils;

function EsAlfanumericoAscii(ACaracter: Char): Boolean;
begin
  Result := ((ACaracter >= 'A') and (ACaracter <= 'Z')) or
            ((ACaracter >= 'a') and (ACaracter <= 'z')) or
            ((ACaracter >= '0') and (ACaracter <= '9'));
end;

function EsCaracterLocalEmail(ACaracter: Char): Boolean;
begin
  Result := EsAlfanumericoAscii(ACaracter) or
            CharInSet(
              ACaracter,
              ['!', '#', '$', '%', '&', '''', '*', '+', '-', '/', '=',
               '?', '^', '_', '`', '{', '|', '}', '~', '.']);
end;

function EtiquetaDominioValida(
  const ADominio: string;
  AInicio, AFin: Integer): Boolean;
var
  i: Integer;
  iLongitud: Integer;
begin
  iLongitud := AFin - AInicio + 1;
  Result := (iLongitud >= 1) and (iLongitud <= 63);
  if Result then
    Result := EsAlfanumericoAscii(ADominio[AInicio]) and
      EsAlfanumericoAscii(ADominio[AFin]);
  i := AInicio;
  while Result and (i <= AFin) do
  begin
    Result := EsAlfanumericoAscii(ADominio[i]) or
      (ADominio[i] = '-');
    Inc(i);
  end;
end;

function ParteLocalEmailValida(const AParteLocal: string): Boolean;
var
  i: Integer;
begin
  Result := (AParteLocal <> '') and
    (Length(AParteLocal) <= 64);
  if Result then
    Result := (AParteLocal[1] <> '.') and
      (AParteLocal[Length(AParteLocal)] <> '.') and
      (Pos('..', AParteLocal) = 0);
  i := 1;
  while Result and (i <= Length(AParteLocal)) do
  begin
    Result := EsCaracterLocalEmail(AParteLocal[i]);
    Inc(i);
  end;
end;

function DominioEmailValido(const ADominio: string): Boolean;
var
  i: Integer;
  iInicioEtiqueta: Integer;
  iPuntosDominio: Integer;
begin
  Result := (ADominio <> '') and
    (Length(ADominio) <= 253);
  if Result then
    Result := (ADominio[1] <> '.') and
      (ADominio[Length(ADominio)] <> '.') and
      (Pos('..', ADominio) = 0);
  iInicioEtiqueta := 1;
  iPuntosDominio := 0;
  i := 1;
  while Result and (i <= Length(ADominio)) do
  begin
    if ADominio[i] = '.' then
    begin
      Result := EtiquetaDominioValida(
        ADominio,
        iInicioEtiqueta,
        i - 1);
      if Result then
      begin
        Inc(iPuntosDominio);
        iInicioEtiqueta := i + 1;
      end;
    end;
    Inc(i);
  end;
  if Result then
    Result := EtiquetaDominioValida(
      ADominio,
      iInicioEtiqueta,
      Length(ADominio)) and
      (iPuntosDominio > 0);
end;

function EmailDocumentoValido(const AEmail: string): Boolean;
var
  iArroba: Integer;
  sDominio: string;
  sEmail: string;
  sLocal: string;
begin
  sEmail := Trim(AEmail);
  Result := (sEmail <> '') and (Length(sEmail) <= 254);
  iArroba := 0;
  if Result then
  begin
    iArroba := Pos('@', sEmail);
    Result := (iArroba > 1) and
      (Pos('@', Copy(sEmail, iArroba + 1, MaxInt)) = 0);
  end;
  if Result then
  begin
    sLocal := Copy(sEmail, 1, iArroba - 1);
    sDominio := Copy(sEmail, iArroba + 1, MaxInt);
    Result := ParteLocalEmailValida(sLocal) and
      DominioEmailValido(sDominio);
  end;
end;

function NormalizarEmailRespuestaDocumento(
  const AEmail: string): string;
begin
  Result := Trim(AEmail);
  if (Result <> '') and not EmailDocumentoValido(Result) then
    Result := '';
end;

end.
