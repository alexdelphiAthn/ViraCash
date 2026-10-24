{******************************************************************************}
{                                                                              }
{  Módulo:       inLibIBAN                                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Validación de IBAN y CCC, generación de IBAN y extracción de sus          }
{    componentes usados por la aplicación.                                     }
{******************************************************************************}
unit inLibIBAN;

interface

uses
  System.Classes;

type
  TIBAN = class
  public
    class function ValidarIBAN(const AIban: string;
                               AErrores: TStringList = nil): Boolean;
    class function ValidarCCC(const ACcc: string;
                              AErrores: TStringList = nil): Boolean;
    class function GenerarIBAN(const APais, ACcc: string): string;
    class function FormatearElectronico(const AIban: string): string;
    class function ExtraerCCC(const AIban: string): string;
    class function DescomponerCCC(const ACcc: string;
                                  out ABanco, ADc, ACuenta: string): Boolean;
  end;

implementation

uses
  System.SysUtils,
  inLibMsgComun;

function SoloAlfanumericos(const AValor: string): string;
var
  cCaracter: Char;
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    cCaracter := UpCase(AValor[i]);
    if CharInSet(cCaracter, ['A'..'Z', '0'..'9']) then
      Result := Result + cCaracter;
  end;
end;

function NormalizarIBAN(const AIban: string): string;
begin
  Result := SoloAlfanumericos(AIban);
  if Copy(Result, 1, 4) = 'IBAN' then
    Delete(Result, 1, 4);
end;

function SoloNumeros(const AValor: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    if CharInSet(AValor[i], ['0'..'9']) then
      Result := Result + AValor[i];
  end;
end;

function EsNumerico(const AValor: string): Boolean;
begin
  Result := (AValor <> '') and (SoloNumeros(AValor) = AValor);
end;

procedure AnadirError(const AMensaje: string; AErrores: TStringList);
begin
  if Assigned(AErrores) then
    AErrores.Add(AMensaje);
end;

function Modulo97(const AValor: string): Integer;
var
  bValido: Boolean;
  cCaracter: Char;
  i: Integer;
begin
  Result := 0;
  bValido := True;
  i := 1;
  while (i <= Length(AValor)) and bValido do
  begin
    cCaracter := UpCase(AValor[i]);
    if CharInSet(cCaracter, ['0'..'9']) then
      Result := ((Result * 10) + Ord(cCaracter) - Ord('0')) mod 97
    else if CharInSet(cCaracter, ['A'..'Z']) then
      Result := ((Result * 100) + Ord(cCaracter) - Ord('A') + 10) mod 97
    else
      bValido := False;
    Inc(i);
  end;
  if not bValido then
    Result := -1;
end;

function AjustarDigitoControl(ASuma: Integer): Integer;
begin
  Result := 11 - (ASuma mod 11);
  if Result = 11 then
    Result := 0
  else if Result = 10 then
    Result := 1;
end;

function CalcularDigitosCCC(const ABanco, ACuenta: string): Integer;
const
  cPesosBanco: array[1..8] of Integer = (4, 8, 5, 10, 9, 7, 3, 6);
  cPesosCuenta: array[1..10] of Integer =
    (1, 2, 4, 8, 5, 10, 9, 7, 3, 6);
var
  i: Integer;
  iPrimerDigito: Integer;
  iSegundoDigito: Integer;
  iSuma: Integer;
begin
  iSuma := 0;
  for i := 1 to Length(cPesosBanco) do
    iSuma := iSuma + StrToInt(ABanco[i]) * cPesosBanco[i];
  iPrimerDigito := AjustarDigitoControl(iSuma);
  iSuma := 0;
  for i := 1 to Length(cPesosCuenta) do
    iSuma := iSuma + StrToInt(ACuenta[i]) * cPesosCuenta[i];
  iSegundoDigito := AjustarDigitoControl(iSuma);
  Result := (iPrimerDigito * 10) + iSegundoDigito;
end;

class function TIBAN.ValidarIBAN(const AIban: string;
                                 AErrores: TStringList): Boolean;
var
  bDigitoControlValido: Boolean;
  bLongitudValida: Boolean;
  bPaisValido: Boolean;
  sCuenta: string;
  sDigitoControl: string;
  sPais: string;
  sValorModulo: string;
begin
  sCuenta := NormalizarIBAN(AIban);
  sPais := Copy(sCuenta, 1, 2);
  sDigitoControl := Copy(sCuenta, 3, 2);
  bPaisValido := (Length(sPais) = 2) and
                 CharInSet(sPais[1], ['A'..'Z']) and
                 CharInSet(sPais[2], ['A'..'Z']);
  bDigitoControlValido := (Length(sDigitoControl) = 2) and
                          EsNumerico(sDigitoControl);
  bLongitudValida := (Length(sCuenta) >= 15) and
                     (Length(sCuenta) <= 34);
  if not bPaisValido then
    AnadirError(SErrorPaisIbanInvalido, AErrores);
  if not bDigitoControlValido then
    AnadirError(SErrorDigitoControlIbanInvalido, AErrores);
  Result := bPaisValido and bDigitoControlValido and bLongitudValida;
  if Result then
  begin
    sValorModulo := Copy(sCuenta, 5, MaxInt) + Copy(sCuenta, 1, 4);
    Result := Modulo97(sValorModulo) = 1;
  end;
  if not Result and bPaisValido and bDigitoControlValido then
    AnadirError(SErrorIbanInvalido, AErrores);
end;

class function TIBAN.ValidarCCC(const ACcc: string;
                                AErrores: TStringList): Boolean;
var
  bLongitudValida: Boolean;
  bNumerico: Boolean;
  iDigitoCalculado: Integer;
  iDigitoRecibido: Integer;
  sBanco: string;
  sCuenta: string;
  sCcc: string;
  sDigitoControl: string;
begin
  sCcc := NormalizarIBAN(ACcc);
  if Copy(sCcc, 1, 2) = 'ES' then
    sCcc := Copy(sCcc, 5, MaxInt);
  bLongitudValida := Length(sCcc) = 20;
  bNumerico := bLongitudValida and EsNumerico(sCcc);
  if not bLongitudValida then
    AnadirError(SErrorLongitudCuentaBancariaInvalida, AErrores)
  else if not bNumerico then
    AnadirError(SErrorCuentaBancariaInvalida, AErrores);
  Result := bNumerico;
  if Result then
  begin
    sBanco := Copy(sCcc, 1, 8);
    sDigitoControl := Copy(sCcc, 9, 2);
    sCuenta := Copy(sCcc, 11, 10);
    iDigitoCalculado := CalcularDigitosCCC(sBanco, sCuenta);
    iDigitoRecibido := StrToInt(sDigitoControl);
    Result := iDigitoCalculado = iDigitoRecibido;
    if not Result then
    begin
      AnadirError(
        Format(
          SErrorDigitoControlCuentaBancaria,
          [sDigitoControl, Format('%.2d', [iDigitoCalculado])]),
        AErrores);
    end;
  end;
end;

class function TIBAN.GenerarIBAN(const APais, ACcc: string): string;
var
  iDigitoControl: Integer;
  sCcc: string;
  sPais: string;
begin
  Result := '';
  sPais := SoloAlfanumericos(APais);
  sCcc := SoloAlfanumericos(ACcc);
  if (Length(sPais) = 2) and (sCcc <> '') then
  begin
    iDigitoControl := 98 - Modulo97(sCcc + sPais + '00');
    Result := sPais + Format('%.2d', [iDigitoControl]) + sCcc;
  end;
end;

class function TIBAN.FormatearElectronico(const AIban: string): string;
begin
  Result := NormalizarIBAN(AIban);
end;

class function TIBAN.ExtraerCCC(const AIban: string): string;
var
  sIban: string;
begin
  sIban := NormalizarIBAN(AIban);
  if Length(sIban) > 4 then
    Result := Copy(sIban, 5, MaxInt)
  else
    Result := '';
end;

class function TIBAN.DescomponerCCC(const ACcc: string;
                                    out ABanco, ADc,
                                    ACuenta: string): Boolean;
var
  sCcc: string;
begin
  sCcc := SoloNumeros(ACcc);
  Result := Length(sCcc) = 20;
  if Result then
  begin
    ABanco := Copy(sCcc, 1, 8);
    ADc := Copy(sCcc, 9, 2);
    ACuenta := Copy(sCcc, 11, 10);
  end
  else
  begin
    ABanco := '';
    ADc := '';
    ACuenta := '';
  end;
end;

end.
