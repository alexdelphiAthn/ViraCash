{******************************************************************************}
{                                                                              }
{  Módulo:       inLibEAN13                                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cálculo y validación de códigos de barras EAN-8 y EAN-13.                 }
{    Dígito de control y verificación de códigos completos.                    }
{******************************************************************************}
unit inLibEAN13;

interface

uses
  SysUtils;

// Calcula el dígito de control a partir de los primeros 7 dígitos
function CalcularDigitoEAN8(const ACodigo7: string): Char;

// Valida si un código EAN-8 completo (8 dígitos) es correcto
function EsEAN8Valido(const ACodigo: string): Boolean;

// Calcula el dígito de control a partir de los primeros 12 dígitos
function CalcularDigitoEAN13(const ACodigo12: string): Char;

// Valida si un código EAN-13 completo (13 dígitos) es correcto
function EsEAN13Valido(const ACodigo: string): Boolean;

// True si el código es un GTIN de los que asigna GS1 (EAN-8, UPC-A,
// EAN-13 o GTIN-14 numéricos): solo puede usarlo la empresa que tiene ese
// prefijo. Los de circulación restringida (EAN-13 20..29, 02 y 04; UPC-A
// 2 y 4; EAN-8 0 y 2) son de uso interno y no cuentan. FZ-ISSUE-307.
function EsCodigoGs1Asignado(const ACodigo: string): Boolean;

implementation

uses
  inLibMsgArticulos, inLibMsgComun;

function CalcularDigitoEAN8(const ACodigo7: string): Char;
var
  i, SumaImpares, SumaPares, Total, Resto, DigitoControl: Integer;
begin
  // Validamos que al menos tenga 7 caracteres
  if Length(ACodigo7) < 7 then
    raise Exception.Create(SErrorCodigoEanMinimo7Digitos);

  SumaImpares := 0;
  SumaPares := 0;

  for i := 1 to 7 do
  begin
    // Validación de seguridad para asegurar que son solo números
    if not CharInSet(ACodigo7[i], ['0'..'9']) then
      raise Exception.Create(SErrorCodigoBarrasNoNumerico);

    // OJO a la diferencia con EAN-13:
    // En EAN-8, las posiciones IMPARES se multiplican por 3
    if (i mod 2) <> 0 then
      SumaImpares := SumaImpares + ((Ord(ACodigo7[i]) - Ord('0')) * 3)
    else
      SumaPares := SumaPares + (Ord(ACodigo7[i]) - Ord('0'));
  end;

  Total := SumaImpares + SumaPares;

  Resto := Total mod 10;

  if Resto = 0 then
    DigitoControl := 0
  else
    DigitoControl := 10 - Resto;

  // Devolvemos el dígito calculado como Char
  Result := Chr(DigitoControl + Ord('0'));
end;

function EsEAN8Valido(const ACodigo: string): Boolean;
begin
  // Un EAN-8 estándar tiene exactamente 8 caracteres
  Result := False;
  if Length(ACodigo) = 8 then
  begin
    try
      Result := CalcularDigitoEAN8(Copy(ACodigo, 1, 7)) = ACodigo[8];
    except
      Result := False;
    end;
  end;
end;

function CalcularDigitoEAN13(const ACodigo12: string): Char;
var
  i, SumaImpares, SumaPares, Total, Resto, DigitoControl: Integer;
begin
  // Validamos que al menos tenga 12 caracteres para evitar Access Violations
  if Length(ACodigo12) < 12 then
    raise Exception.Create(SErrorCodigoEanMinimo12Digitos);

  SumaImpares := 0;
  SumaPares := 0;

  // Los strings en Delphi empiezan en el índice 1
  for i := 1 to 12 do
  begin
    // Validación de seguridad por si el string trae letras o basura
    if not CharInSet(ACodigo12[i], ['0'..'9']) then
      raise Exception.Create(SErrorCodigoBarrasNoNumerico);

    // Convertimos el char a entero restando el valor ASCII del '0'
    if (i mod 2) <> 0 then
      // Posiciones impares (1, 3, 5...)
      SumaImpares := SumaImpares + (Ord(ACodigo12[i]) - Ord('0'))
    else
      // Posiciones pares (2, 4, 6...)
      SumaPares := SumaPares + (Ord(ACodigo12[i]) - Ord('0'));
  end;

  // La regla EAN-13 dice que las posiciones pares se multiplican por 3
  Total := SumaImpares + (SumaPares * 3);

  // Sacamos el resto de dividir entre 10
  Resto := Total mod 10;

  if Resto = 0 then
    DigitoControl := 0
  else
    DigitoControl := 10 - Resto;

  // Devolvemos el dígito calculado como Char
  Result := Chr(DigitoControl + Ord('0'));
end;

function EsEAN13Valido(const ACodigo: string): Boolean;
begin
  // Un EAN-13 estándar tiene exactamente 13 caracteres
  Result := False;
  if Length(ACodigo) = 13 then
  begin
    try
      Result := CalcularDigitoEAN13(Copy(ACodigo, 1, 12)) = ACodigo[13];
    except
      Result := False;
    end;
  end;
end;

function EsSoloDigitos(const ACodigo: string): Boolean;
var
  cCaracter: Char;
begin
  Result := ACodigo <> '';
  for cCaracter in ACodigo do
    Result := Result and CharInSet(cCaracter, ['0'..'9']);
end;

// Prefijo de un GTIN-13 (o del cuerpo de un GTIN-14) de circulación
// restringida: 20..29 de uso interno y 02/04 de GS1 US
function EsPrefijoGtin13Interno(const ACodigo: string): Boolean;
begin
  Result := (Copy(ACodigo, 1, 1) = '2') or (Copy(ACodigo, 1, 2) = '02') or
    (Copy(ACodigo, 1, 2) = '04');
end;

function EsCodigoGs1Asignado(const ACodigo: string): Boolean;
var
  sCodigo: string;
begin
  sCodigo := Trim(ACodigo);
  Result := False;
  if EsSoloDigitos(sCodigo) then
    case Length(sCodigo) of
      8:
        Result := EsEAN8Valido(sCodigo) and
          not CharInSet(sCodigo[1], ['0', '2']);
      12:
        Result := EsEAN13Valido('0' + sCodigo) and
          not CharInSet(sCodigo[1], ['2', '4']);
      13:
        Result := EsEAN13Valido(sCodigo) and
          not EsPrefijoGtin13Interno(sCodigo);
      14:
        Result := not EsPrefijoGtin13Interno(Copy(sCodigo, 2, 13));
    end;
end;

end.
