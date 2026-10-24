{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCifrado                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cifrado AES compatible con las credenciales y copias ya persistidas.      }
{******************************************************************************}
unit inLibCifrado;

interface

function CifrarAES(const ADatos: string): string;
function CifrarAESConContrasena(
  const ADatos: string;
  const AContrasena: AnsiString): string;
function DescifrarAES(const ADatos: string): string;
function DescifrarAESConContrasena(
  const ADatos: string;
  const AContrasena: AnsiString): string;
function CifrarDatosAES(
  const ADatos: string;
  const AClave: AnsiString;
  const AVectorInicializacion: AnsiString): string;
function DescifrarDatosAES(
  const ADatos: string;
  const AClave: AnsiString;
  const AVectorInicializacion: AnsiString): string;

implementation

uses
  System.Classes, System.SysUtils,
  DCPcrypt2, DCPrijndael, dcpbase64;

const
  CLAVE_AES_PREDETERMINADA =
    'Key1234567890-1234567890-1234567';
  VECTOR_AES_PREDETERMINADO =
    '12345678901234561234567890123456';

function DecodificarBase64(const AEntrada: TBytes): TBytes;
var
  iLongitudEntrada: Integer;
  iLongitudResultado: Integer;
begin
  iLongitudEntrada := Length(AEntrada);
  SetLength(Result, (iLongitudEntrada div 4) * 3);
  iLongitudResultado := 0;
  if Length(Result) > 0 then
  begin
    iLongitudResultado := Base64Decode(
      @AEntrada[0],
      @Result[0],
      iLongitudEntrada);
  end;
  SetLength(Result, iLongitudResultado);
end;

function CodificarBase64(const AEntrada: TBytes): TBytes;
var
  iLongitudEntrada: Integer;
begin
  iLongitudEntrada := Length(AEntrada);
  SetLength(Result, ((iLongitudEntrada + 2) div 3) * 4);
  if Length(Result) > 0 then
  begin
    Base64Encode(
      @AEntrada[0],
      @Result[0],
      iLongitudEntrada);
  end;
end;

function DescifrarDatosAES(
  const ADatos: string;
  const AClave: AnsiString;
  const AVectorInicializacion: AnsiString): string;
var
  aBytesClave: TBytes;
  aBytesVectorInicializacion: TBytes;
  aOrigen: TBytes;
  aDestino: TBytes;
  oCifrador: TDCP_rijndael;
  iLongitud: Integer;
  iRelleno: Integer;
begin
  Result := '';
  try
    if Length(ADatos) = 0 then
      raise Exception.Create('Datos de entrada vacíos');
    aBytesClave := TEncoding.ASCII.GetBytes(String(AClave));
    aBytesVectorInicializacion :=
      TEncoding.ASCII.GetBytes(String(AVectorInicializacion));
    aOrigen := DecodificarBase64(
      TEncoding.UTF8.GetBytes(ADatos));
    if Length(aOrigen) = 0 then
      raise Exception.Create('Error al decodificar Base64');
    oCifrador := TDCP_rijndael.Create(nil);
    try
      oCifrador.CipherMode := cmCBC;
      iLongitud := Length(aOrigen);
      SetLength(aDestino, iLongitud);
      oCifrador.Init(
        aBytesClave[0],
        256,
        @aBytesVectorInicializacion[0]);
      oCifrador.Decrypt(
        aOrigen[0],
        aDestino[0],
        iLongitud);
      if Length(aDestino) = 0 then
        raise Exception.Create(
          'Error durante la desencriptación');
      iRelleno := aDestino[iLongitud - 1];
      SetLength(
        aDestino,
        iLongitud - iRelleno);
      Result := TEncoding.UTF8.GetString(aDestino);
    finally
      FreeAndNil(oCifrador);
    end;
  except
    Result := '';
  end;
end;

function CifrarDatosAES(
  const ADatos: string;
  const AClave: AnsiString;
  const AVectorInicializacion: AnsiString): string;
var
  oCifrador: TDCP_rijndael;
  aBytesClave: TBytes;
  aBytesVectorInicializacion: TBytes;
  aOrigen: TBytes;
  aDestino: TBytes;
  aBase64: TBytes;
  iIndice: Integer;
  iLongitud: Integer;
  iTamanoBloque: Integer;
  iRelleno: Integer;
begin
  aBytesClave := TEncoding.ASCII.GetBytes(String(AClave));
  aBytesVectorInicializacion :=
    TEncoding.ASCII.GetBytes(String(AVectorInicializacion));
  aOrigen := TEncoding.UTF8.GetBytes(ADatos);
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    iLongitud := Length(aOrigen);
    iTamanoBloque := oCifrador.BlockSize div 8;
    iRelleno := iTamanoBloque - (iLongitud mod iTamanoBloque);
    Inc(iLongitud, iRelleno);
    SetLength(aOrigen, iLongitud);
    for iIndice := iRelleno downto 1 do
    begin
      aOrigen[iLongitud - iIndice] := iRelleno;
    end;
    SetLength(aDestino, iLongitud);
    oCifrador.Init(
      aBytesClave[0],
      256,
      @aBytesVectorInicializacion[0]);
    oCifrador.Encrypt(
      aOrigen[0],
      aDestino[0],
      iLongitud);
    aBase64 := CodificarBase64(aDestino);
    Result := TEncoding.Default.GetString(aBase64);
  finally
    FreeAndNil(oCifrador);
  end;
end;

function CifrarAESConContrasena(
  const ADatos: string;
  const AContrasena: AnsiString): string;
begin
  Result := CifrarDatosAES(
    ADatos,
    CLAVE_AES_PREDETERMINADA + AContrasena,
    VECTOR_AES_PREDETERMINADO);
end;

function CifrarAES(const ADatos: string): string;
begin
  Result := CifrarDatosAES(
    ADatos,
    CLAVE_AES_PREDETERMINADA,
    VECTOR_AES_PREDETERMINADO);
end;

function DescifrarAESConContrasena(
  const ADatos: string;
  const AContrasena: AnsiString): string;
begin
  Result := DescifrarDatosAES(
    ADatos,
    CLAVE_AES_PREDETERMINADA + AContrasena,
    VECTOR_AES_PREDETERMINADO);
end;

function DescifrarAES(const ADatos: string): string;
begin
  Result := DescifrarDatosAES(
    ADatos,
    CLAVE_AES_PREDETERMINADA,
    VECTOR_AES_PREDETERMINADO);
end;

end.
