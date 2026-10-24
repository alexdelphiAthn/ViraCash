{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCifradoCopias                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Cifrado autenticado, comprimido y versionado para copias de seguridad.    }
{******************************************************************************}
unit inLibCifradoCopias;

interface

uses
  System.SysUtils;

const
  MAXIMO_BYTES_SQL_EN_CADENA = 400 * 1024 * 1024;

type
  ECifradoCopia = class(Exception);
  TEtapaAperturaCopia = (
    eacVerificandoIntegridad,
    eacIntegridadVerificada,
    eacDescifrando,
    eacValidandoContenido
  );
  TEtapaAperturaCopiaEvent = procedure(
    AEtapa: TEtapaAperturaCopia) of object;

function EsFormatoCifradoActual(const ADatos: string): Boolean;
function CifrarCopiaSeguridad(
  const ADatos, AContrasena: string
): string;
function CifrarCopiaSeguridadComprimida(
  const ADatos, AContrasena: string
): string;
function EmpaquetarCopiaSeguridadZip(
  const ADatos: TBytes
): TBytes;
procedure EmpaquetarCopiaSeguridadZipDesdeFichero(
  const ARutaScript, ARutaZip: string);
procedure CifrarCopiaSeguridadComprimidaDesdeFichero(
  const ARutaScript, ARutaDestino, AContrasena: string);
procedure DesempaquetarCopiaSeguridadZipDesdeFichero(
  const ARutaZip, ARutaScript: string);
procedure DescifrarCopiaSeguridadDesdeFichero(
  const ARutaCopia, ARutaScript, AContrasena: string;
  AOnEtapa: TEtapaAperturaCopiaEvent = nil);
function DesempaquetarCopiaSeguridadZip(
  const ADatos: TBytes
): TBytes;
function DescifrarCopiaSeguridad(
  const ADatos, AContrasena: string
): string;

implementation

uses
  Winapi.Windows,
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.NetEncoding,
  System.StrUtils,
  System.Zip,
  System.ZLib,
  DCPcrypt2,
  DCPrijndael,
  inLibCifrado,
  inLibMsgConfiguracion;

resourcestring
  SErrorInicializarGeneradorCriptografico =
    'No se pudo inicializar el generador criptográfico.';
  SErrorGenerarDatosAleatoriosSeguros =
    'No se pudieron generar datos aleatorios seguros.';
  SErrorContenidoCifradoLongitudInvalida =
    'El contenido cifrado no tiene una longitud válida.';
  SErrorRellenoCopiaCifradaInvalido =
    'El relleno de la copia cifrada no es válido.';
  SErrorRellenoCopiaCifradaDanado =
    'El relleno de la copia cifrada está dañado.';
  SErrorBase64CopiaCifradaInvalido =
    'La copia cifrada contiene Base64 no válido: %s';
  SErrorScriptComprimirVacio =
    'El script que se va a comprimir está vacío.';
  SErrorCopiaDescomprimidaTamanoMaximo =
    'La copia descomprimida supera el tamaño permitido.';
  SErrorZipCopiaUnicoArchivo =
    'El ZIP de la copia debe contener un único archivo.';
  SErrorZipCopiaSinScript =
    'El ZIP de la copia no contiene el script esperado.';
  SErrorScriptZipVacio =
    'El script contenido en el ZIP está vacío.';
  SErrorZipCopiaInvalido =
    'El ZIP de la copia no es válido: %s';
  SErrorFormatoCopiaNoValido =
    'El formato solicitado para la copia no es válido.';
  SErrorContrasenaCopiaVacia =
    'La contraseña de la copia no puede estar vacía.';
  SErrorCabeceraCopiaCifradaIncompleta =
    'La cabecera de la copia cifrada está incompleta.';
  SErrorVersionCopiaCifradaIncompatible =
    'La versión de la copia cifrada no es compatible.';
  SErrorIteracionesCopiaNoValido =
    'El número de iteraciones de la copia no es válido.';
  SErrorMetadatosCopiaCifradaInvalidos =
    'Los metadatos de la copia cifrada no son válidos.';
  SErrorContrasenaIncorrectaOCopiaDanada =
    'La contraseña no es correcta o la copia está dañada.';
  SErrorIndicarContrasenaCopia =
    'Debe indicar la contraseña de la copia.';
  SErrorAbrirCopiaCifradaHistorica =
    'No se pudo abrir la copia cifrada histórica.';

const
  CABECERA_CIFRADO = 'FZAM_COPIA_CIFRADA_V2';
  CABECERA_CIFRADO_ZLIB = 'FZAM_COPIA_CIFRADA_V3';
  CABECERA_CIFRADO_ZIP = 'FZAM_COPIA_CIFRADA_V3_ZIP';
  NOMBRE_ENTRADA_ZIP = 'copia.sql';
  ITERACIONES_PBKDF2 = 100000;
  LONGITUD_SAL = 16;
  LONGITUD_VECTOR = 16;
  LONGITUD_CLAVE = 32;
  LONGITUD_CLAVES = 64;
  LONGITUD_BLOQUE_AES = 16;
  PROVEEDOR_RSA_AES = 24;
  VERIFICAR_CONTEXTO = $F0000000;
  MAXIMO_DATOS_DESCOMPRIMIDOS = 1024 * 1024 * 1024;
  LONGITUD_BLOQUE_HMAC = 64;
  TAMANO_BLOQUE_FLUJO = 1024 * 1024;
  MAXIMO_BYTES_LINEA_METADATOS = 1024;
  TAMANO_PREFIJO_FORMATO = 128;
  TAMANO_BLOQUE_BASE64 = 3 * 1024 * 1024;

type
  TFormatoCifradoCopia = (
    fccDesconocido,
    fccV2,
    fccV3ZLib,
    fccV3Zip
  );
  TSobreCifradoCopia = record
    Cabecera: string;
    Iteraciones: Integer;
    Sal: TBytes;
    Vector: TBytes;
    Mac: TBytes;
    Cifrado: TBytes;
  end;

function FzaCryptAcquireContextW(
  var AProveedor: NativeUInt;
  AContenedor, AProveedorNombre: PWideChar;
  ATipoProveedor, AFlags: DWORD
): BOOL; stdcall; external 'advapi32.dll' name 'CryptAcquireContextW';
function FzaCryptReleaseContext(
  AProveedor: NativeUInt;
  AFlags: DWORD
): BOOL; stdcall; external 'advapi32.dll' name 'CryptReleaseContext';
function FzaCryptGenRandom(
  AProveedor: NativeUInt;
  ALongitud: DWORD;
  ABuffer: PByte
): BOOL; stdcall; external 'advapi32.dll' name 'CryptGenRandom';

function ConcatenarBytes(
  const APrimero, ASegundo: TBytes
): TBytes;
var
  iLongitudPrimero: Integer;
begin
  iLongitudPrimero := Length(APrimero);
  SetLength(Result, iLongitudPrimero + Length(ASegundo));
  if iLongitudPrimero > 0 then
  begin
    Move(
      APrimero[0],
      Result[0],
      iLongitudPrimero);
  end;
  if Length(ASegundo) > 0 then
  begin
    Move(
      ASegundo[0],
      Result[iLongitudPrimero],
      Length(ASegundo));
  end;
end;

function EnteroBigEndian(AValor: Integer): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := Byte((AValor shr 24) and $FF);
  Result[1] := Byte((AValor shr 16) and $FF);
  Result[2] := Byte((AValor shr 8) and $FF);
  Result[3] := Byte(AValor and $FF);
end;

function DerivarClavePBKDF2(
  const AContrasena: string;
  const ASal: TBytes;
  AIteraciones, ALongitud: Integer
): TBytes;
var
  aClaveContrasena: TBytes;
  aDatosBloque: TBytes;
  aU: TBytes;
  aT: TBytes;
  iBloque: Integer;
  iBloques: Integer;
  iDestino: Integer;
  iIndice: Integer;
  iIteracion: Integer;
  iCopiar: Integer;
begin
  aClaveContrasena := TEncoding.UTF8.GetBytes(AContrasena);
  iBloques := (ALongitud + LONGITUD_CLAVE - 1) div LONGITUD_CLAVE;
  SetLength(Result, ALongitud);
  iDestino := 0;
  for iBloque := 1 to iBloques do
  begin
    aDatosBloque := ConcatenarBytes(
      ASal,
      EnteroBigEndian(iBloque));
    aU := THashSHA2.GetHMACAsBytes(
      aDatosBloque,
      aClaveContrasena);
    aT := Copy(aU, 0, Length(aU));
    for iIteracion := 2 to AIteraciones do
    begin
      aU := THashSHA2.GetHMACAsBytes(
        aU,
        aClaveContrasena);
      for iIndice := 0 to High(aT) do
        aT[iIndice] := aT[iIndice] xor aU[iIndice];
    end;
    iCopiar := Length(aT);
    if iDestino + iCopiar > ALongitud then
      iCopiar := ALongitud - iDestino;
    Move(
      aT[0],
      Result[iDestino],
      iCopiar);
    Inc(iDestino, iCopiar);
  end;
end;

function GenerarBytesAleatorios(ALongitud: Integer): TBytes;
var
  hProveedor: NativeUInt;
begin
  hProveedor := 0;
  SetLength(Result, ALongitud);
  if not FzaCryptAcquireContextW(
    hProveedor,
    nil,
    nil,
    PROVEEDOR_RSA_AES,
    VERIFICAR_CONTEXTO) then
  begin
    raise ECifradoCopia.Create(SErrorInicializarGeneradorCriptografico);
  end;
  try
    if not FzaCryptGenRandom(
      hProveedor,
      DWORD(ALongitud),
      @Result[0]) then
    begin
      raise ECifradoCopia.Create(SErrorGenerarDatosAleatoriosSeguros);
    end;
  finally
    FzaCryptReleaseContext(hProveedor, 0);
  end;
end;

function CifrarAESBytes(
  const ADatos, AClave, AVector: TBytes
): TBytes;
var
  aOrigen: TBytes;
  iIndice: Integer;
  iLongitud: Integer;
  iRelleno: Integer;
  oCifrador: TDCP_rijndael;
begin
  aOrigen := Copy(ADatos, 0, Length(ADatos));
  iLongitud := Length(aOrigen);
  iRelleno := LONGITUD_BLOQUE_AES -
    (iLongitud mod LONGITUD_BLOQUE_AES);
  SetLength(aOrigen, iLongitud + iRelleno);
  for iIndice := iLongitud to High(aOrigen) do
    aOrigen[iIndice] := Byte(iRelleno);
  SetLength(Result, Length(aOrigen));
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    oCifrador.Init(
      AClave[0],
      256,
      @AVector[0]);
    oCifrador.Encrypt(
      aOrigen[0],
      Result[0],
      Length(aOrigen));
  finally
    FreeAndNil(oCifrador);
  end;
end;

function DescifrarAESBytes(
  const ADatos, AClave, AVector: TBytes
): TBytes;
var
  iIndice: Integer;
  iRelleno: Integer;
  oCifrador: TDCP_rijndael;
begin
  if (Length(ADatos) = 0) or
     ((Length(ADatos) mod LONGITUD_BLOQUE_AES) <> 0) then
  begin
    raise ECifradoCopia.Create(SErrorContenidoCifradoLongitudInvalida);
  end;
  SetLength(Result, Length(ADatos));
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    oCifrador.Init(
      AClave[0],
      256,
      @AVector[0]);
    oCifrador.Decrypt(
      ADatos[0],
      Result[0],
      Length(ADatos));
  finally
    FreeAndNil(oCifrador);
  end;
  iRelleno := Result[High(Result)];
  if (iRelleno < 1) or
     (iRelleno > LONGITUD_BLOQUE_AES) then
  begin
    raise ECifradoCopia.Create(SErrorRellenoCopiaCifradaInvalido);
  end;
  for iIndice := Length(Result) - iRelleno to High(Result) do
  begin
    if Result[iIndice] <> Byte(iRelleno) then
    begin
      raise ECifradoCopia.Create(SErrorRellenoCopiaCifradaDanado);
    end;
  end;
  SetLength(Result, Length(Result) - iRelleno);
end;

function CodificarBase64(const ABytes: TBytes): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(ABytes);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function DecodificarBase64(const ATexto: string): TBytes;
begin
  try
    Result := TNetEncoding.Base64.DecodeStringToBytes(ATexto);
  except
    on E: Exception do
    begin
      raise ECifradoCopia.CreateFmt(
        SErrorBase64CopiaCifradaInvalido,
        [E.Message]);
    end;
  end;
end;

function CrearDatosAutenticados(
  AIteraciones: Integer;
  const ASal, AVector, ACifrado: TBytes;
  const ACabeceraAutenticada: string
): TBytes;
begin
  Result := nil;
  if ACabeceraAutenticada <> '' then
  begin
    Result := TEncoding.ASCII.GetBytes(
      ACabeceraAutenticada + #0);
  end;
  Result := ConcatenarBytes(
    Result,
    TEncoding.ASCII.GetBytes(IntToStr(AIteraciones)));
  Result := ConcatenarBytes(Result, ASal);
  Result := ConcatenarBytes(Result, AVector);
  Result := ConcatenarBytes(Result, ACifrado);
end;

function ComparacionConstante(
  const APrimero, ASegundo: TBytes
): Boolean;
var
  iDiferencia: Byte;
  iIndice: Integer;
begin
  Result := Length(APrimero) = Length(ASegundo);
  iDiferencia := 0;
  if Result then
  begin
    for iIndice := 0 to High(APrimero) do
      iDiferencia := iDiferencia xor
        (APrimero[iIndice] xor ASegundo[iIndice]);
    Result := iDiferencia = 0;
  end;
end;

procedure ComprobarTamanoSqlEnCadena(const ADatos: string);
var
  iTamano: UInt64;
begin
  iTamano := UInt64(TEncoding.UTF8.GetByteCount(ADatos));
  if iTamano > UInt64(MAXIMO_BYTES_SQL_EN_CADENA) then
  begin
    raise ECifradoCopia.Create(SErrorSqlCadenaTamanoMaximo);
  end;
end;

function ObtenerTamanoFicheroSql(const ARutaScript: string): Int64;
var
  oScript: TFileStream;
begin
  if not FileExists(ARutaScript) then
  begin
    raise ECifradoCopia.Create(SErrorFicheroSqlCopiaNoExiste);
  end;
  oScript := TFileStream.Create(
    ARutaScript,
    fmOpenRead or fmShareDenyWrite);
  try
    Result := oScript.Size;
  finally
    FreeAndNil(oScript);
  end;
  if Result = 0 then
  begin
    raise ECifradoCopia.Create(SErrorScriptComprimirVacio);
  end;
end;

function CrearRutaTemporalJuntoA(
  const ARutaReferencia, APrefijo: string): string;
var
  sDirectorio: string;
begin
  sDirectorio := ExtractFilePath(ARutaReferencia);
  if sDirectorio = '' then
    sDirectorio := GetCurrentDir;
  Result := TPath.Combine(
    sDirectorio,
    APrefijo + TGUID.NewGuid.ToString + '.tmp');
end;

procedure EliminarFicheroTemporal(const ARutaFichero: string);
begin
  if (ARutaFichero <> '') and FileExists(ARutaFichero) then
  begin
    System.SysUtils.DeleteFile(ARutaFichero);
  end;
end;

procedure PublicarFicheroTemporal(
  const ARutaTemporal, ARutaDestino: string);
var
  oTemporal: TFileStream;
begin
  oTemporal := TFileStream.Create(
    ARutaTemporal,
    fmOpenReadWrite or fmShareDenyWrite);
  try
    if not FlushFileBuffers(oTemporal.Handle) then
      RaiseLastOSError;
  finally
    FreeAndNil(oTemporal);
  end;
  if not MoveFileEx(
    PChar(ARutaTemporal),
    PChar(ARutaDestino),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
  begin
    RaiseLastOSError;
  end;
end;

procedure EmpaquetarCopiaSeguridadZipDesdeFichero(
  const ARutaScript, ARutaZip: string);
var
  aMarcaUtf8: array[0..2] of Byte;
  oScript: TFileStream;
  oZip: TZipFile;
begin
  ObtenerTamanoFicheroSql(ARutaScript);
  oScript := TFileStream.Create(
    ARutaScript,
    fmOpenRead or fmShareDenyWrite);
  try
    oZip := TZipFile.Create;
    try
      if oScript.Size >= Length(aMarcaUtf8) then
      begin
        oScript.ReadBuffer(aMarcaUtf8[0], Length(aMarcaUtf8));
        if (aMarcaUtf8[0] <> $EF) or
           (aMarcaUtf8[1] <> $BB) or
           (aMarcaUtf8[2] <> $BF) then
        begin
          oScript.Position := 0;
        end;
      end;
      if oScript.Position = oScript.Size then
      begin
        raise ECifradoCopia.Create(SErrorScriptComprimirVacio);
      end;
      oZip.Open(ARutaZip, zmWrite);
      try
        oZip.Add(
          oScript,
          NOMBRE_ENTRADA_ZIP,
          zcDeflate);
      finally
        oZip.Close;
      end;
    finally
      FreeAndNil(oZip);
    end;
  finally
    FreeAndNil(oScript);
  end;
end;

procedure CifrarAESFlujo(
  const AOrigen, ADestino: TStream;
  const AClave, AVector: TBytes);
var
  aCifrado: TBytes;
  aPlano: TBytes;
  bUltimoBloque: Boolean;
  iIndice: Integer;
  iLeidos: Integer;
  iRelleno: Integer;
  iRestante: Int64;
  iTamanoCifrado: Integer;
  oCifrador: TDCP_rijndael;
begin
  SetLength(aPlano, TAMANO_BLOQUE_FLUJO + LONGITUD_BLOQUE_AES);
  SetLength(aCifrado, Length(aPlano));
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    oCifrador.Init(
      AClave[0],
      256,
      @AVector[0]);
    AOrigen.Position := 0;
    bUltimoBloque := False;
    while not bUltimoBloque do
    begin
      iRestante := AOrigen.Size - AOrigen.Position;
      bUltimoBloque := iRestante <= TAMANO_BLOQUE_FLUJO;
      if bUltimoBloque then
        iLeidos := Integer(iRestante)
      else
        iLeidos := TAMANO_BLOQUE_FLUJO;
      if iLeidos > 0 then
        AOrigen.ReadBuffer(aPlano[0], iLeidos);
      iTamanoCifrado := iLeidos;
      if bUltimoBloque then
      begin
        iRelleno := LONGITUD_BLOQUE_AES -
          (iLeidos mod LONGITUD_BLOQUE_AES);
        iTamanoCifrado := iLeidos + iRelleno;
        for iIndice := iLeidos to iTamanoCifrado - 1 do
          aPlano[iIndice] := Byte(iRelleno);
      end;
      oCifrador.Encrypt(
        aPlano[0],
        aCifrado[0],
        iTamanoCifrado);
      ADestino.WriteBuffer(aCifrado[0], iTamanoCifrado);
    end;
  finally
    FreeAndNil(oCifrador);
  end;
end;

procedure DescifrarAESFlujo(
  const AOrigen, ADestino: TStream;
  const AClave, AVector: TBytes);
var
  aCifrado: TBytes;
  aPlano: TBytes;
  bUltimoBloque: Boolean;
  iIndice: Integer;
  iLeidos: Integer;
  iRelleno: Integer;
  iRestante: Int64;
  iTamanoPlano: Integer;
  oCifrador: TDCP_rijndael;
begin
  if (AOrigen.Size = 0) or
     ((AOrigen.Size mod LONGITUD_BLOQUE_AES) <> 0) then
  begin
    raise ECifradoCopia.Create(SErrorContenidoCifradoLongitudInvalida);
  end;
  SetLength(aCifrado, TAMANO_BLOQUE_FLUJO);
  SetLength(aPlano, TAMANO_BLOQUE_FLUJO);
  oCifrador := TDCP_rijndael.Create(nil);
  try
    oCifrador.CipherMode := cmCBC;
    oCifrador.Init(
      AClave[0],
      256,
      @AVector[0]);
    AOrigen.Position := 0;
    bUltimoBloque := False;
    while not bUltimoBloque do
    begin
      iRestante := AOrigen.Size - AOrigen.Position;
      bUltimoBloque := iRestante <= TAMANO_BLOQUE_FLUJO;
      if bUltimoBloque then
        iLeidos := Integer(iRestante)
      else
        iLeidos := TAMANO_BLOQUE_FLUJO;
      AOrigen.ReadBuffer(aCifrado[0], iLeidos);
      oCifrador.Decrypt(
        aCifrado[0],
        aPlano[0],
        iLeidos);
      iTamanoPlano := iLeidos;
      if bUltimoBloque then
      begin
        iRelleno := aPlano[iLeidos - 1];
        if (iRelleno < 1) or
           (iRelleno > LONGITUD_BLOQUE_AES) then
        begin
          raise ECifradoCopia.Create(
            SErrorRellenoCopiaCifradaInvalido);
        end;
        for iIndice := iLeidos - iRelleno to iLeidos - 1 do
        begin
          if aPlano[iIndice] <> Byte(iRelleno) then
          begin
            raise ECifradoCopia.Create(
              SErrorRellenoCopiaCifradaDanado);
          end;
        end;
        iTamanoPlano := iLeidos - iRelleno;
      end;
      if iTamanoPlano > 0 then
        ADestino.WriteBuffer(aPlano[0], iTamanoPlano);
    end;
  finally
    FreeAndNil(oCifrador);
  end;
end;

function CopiarFlujoHastaFin(
  const AOrigen, ADestino: TStream): Int64;
var
  aBuffer: TBytes;
  iLeidos: Integer;
begin
  Result := 0;
  SetLength(aBuffer, TAMANO_BLOQUE_FLUJO);
  iLeidos := AOrigen.Read(aBuffer[0], Length(aBuffer));
  while iLeidos > 0 do
  begin
    ADestino.WriteBuffer(aBuffer[0], iLeidos);
    Inc(Result, iLeidos);
    iLeidos := AOrigen.Read(aBuffer[0], Length(aBuffer));
  end;
end;

function LeerBloqueFlujo(
  const AOrigen: TStream;
  var ABuffer: TBytes): Integer;
var
  bFinFlujo: Boolean;
  iLeidos: Integer;
begin
  Result := 0;
  bFinFlujo := False;
  while (Result < Length(ABuffer)) and
        (not bFinFlujo) do
  begin
    iLeidos := AOrigen.Read(
      ABuffer[Result],
      Length(ABuffer) - Result);
    if iLeidos > 0 then
      Inc(Result, iLeidos)
    else
      bFinFlujo := True;
  end;
end;

function NormalizarClaveHmac(const AClave: TBytes): TBytes;
var
  oHash: THashSHA2;
begin
  if Length(AClave) > LONGITUD_BLOQUE_HMAC then
  begin
    oHash := THashSHA2.Create;
    oHash.Update(AClave, Length(AClave));
    Result := oHash.HashAsBytes;
  end
  else
    Result := Copy(AClave, 0, Length(AClave));
  SetLength(Result, LONGITUD_BLOQUE_HMAC);
end;

function CrearHmacSha256Fichero(
  const AClave, APrefijo: TBytes;
  const ARutaFichero: string): TBytes;
var
  aBloque: TBytes;
  aClaveBloque: TBytes;
  aResumenInterior: TBytes;
  iIndice: Integer;
  iLeer: Integer;
  iLeidos: Integer;
  iRestante: Int64;
  oExterior: THashSHA2;
  oFichero: TFileStream;
  oInterior: THashSHA2;
begin
  aClaveBloque := NormalizarClaveHmac(AClave);
  SetLength(aBloque, TAMANO_BLOQUE_FLUJO);
  for iIndice := 0 to LONGITUD_BLOQUE_HMAC - 1 do
    aClaveBloque[iIndice] := aClaveBloque[iIndice] xor $36;
  oInterior := THashSHA2.Create;
  oInterior.Update(aClaveBloque, Length(aClaveBloque));
  if Length(APrefijo) > 0 then
    oInterior.Update(APrefijo, Length(APrefijo));
  oFichero := TFileStream.Create(
    ARutaFichero,
    fmOpenRead or fmShareDenyWrite);
  try
    while oFichero.Position < oFichero.Size do
    begin
      iRestante := oFichero.Size - oFichero.Position;
      if iRestante > Length(aBloque) then
        iLeer := Length(aBloque)
      else
        iLeer := Integer(iRestante);
      oFichero.ReadBuffer(aBloque[0], iLeer);
      iLeidos := iLeer;
      oInterior.Update(aBloque[0], iLeidos);
    end;
  finally
    FreeAndNil(oFichero);
  end;
  aResumenInterior := oInterior.HashAsBytes;
  aClaveBloque := NormalizarClaveHmac(AClave);
  for iIndice := 0 to LONGITUD_BLOQUE_HMAC - 1 do
    aClaveBloque[iIndice] := aClaveBloque[iIndice] xor $5C;
  oExterior := THashSHA2.Create;
  oExterior.Update(aClaveBloque, Length(aClaveBloque));
  oExterior.Update(
    aResumenInterior,
    Length(aResumenInterior));
  Result := oExterior.HashAsBytes;
end;

procedure EscribirLineaAscii(
  const ADestino: TStream;
  const ATexto: string);
var
  aLinea: TBytes;
begin
  aLinea := TEncoding.ASCII.GetBytes(ATexto + sLineBreak);
  if Length(aLinea) > 0 then
    ADestino.WriteBuffer(aLinea[0], Length(aLinea));
end;

function CodificarBase64Flujo(
  const AOrigen, ADestino: TStream): Int64;
var
  aCodificado: TBytes;
  aPlano: TBytes;
  iLeidos: Integer;
  oBase64: TBase64Encoding;
begin
  Result := 0;
  oBase64 := TBase64Encoding.Create(0);
  try
    AOrigen.Position := 0;
    SetLength(aPlano, TAMANO_BLOQUE_BASE64);
    iLeidos := LeerBloqueFlujo(AOrigen, aPlano);
    while iLeidos > 0 do
    begin
      SetLength(aPlano, iLeidos);
      aCodificado := oBase64.Encode(aPlano);
      if Length(aCodificado) > 0 then
      begin
        ADestino.WriteBuffer(
          aCodificado[0],
          Length(aCodificado));
        Inc(Result, Length(aCodificado));
      end;
      SetLength(aPlano, TAMANO_BLOQUE_BASE64);
      iLeidos := LeerBloqueFlujo(AOrigen, aPlano);
    end;
  finally
    FreeAndNil(oBase64);
  end;
end;

procedure EscribirSobreCifradoDesdeFichero(
  const ARutaCifrado, ARutaDestino: string;
  const ASal, AVector, AMac: TBytes);
var
  iEsperado: Int64;
  iInicio: Int64;
  oCifrado: TFileStream;
  oDestino: TFileStream;
begin
  oCifrado := TFileStream.Create(
    ARutaCifrado,
    fmOpenRead or fmShareDenyWrite);
  try
    oDestino := TFileStream.Create(ARutaDestino, fmCreate);
    try
      EscribirLineaAscii(oDestino, CABECERA_CIFRADO_ZIP);
      EscribirLineaAscii(oDestino, IntToStr(ITERACIONES_PBKDF2));
      EscribirLineaAscii(oDestino, CodificarBase64(ASal));
      EscribirLineaAscii(oDestino, CodificarBase64(AVector));
      EscribirLineaAscii(oDestino, CodificarBase64(AMac));
      iInicio := oDestino.Position;
      CodificarBase64Flujo(oCifrado, oDestino);
      iEsperado := ((oCifrado.Size + 2) div 3) * 4;
      if oDestino.Position - iInicio <> iEsperado then
      begin
        raise ECifradoCopia.Create(
          SErrorEscribirCopiaCifradaIncompleta);
      end;
    finally
      FreeAndNil(oDestino);
    end;
  finally
    FreeAndNil(oCifrado);
  end;
end;

procedure CifrarCopiaSeguridadComprimidaDesdeFichero(
  const ARutaScript, ARutaDestino, AContrasena: string);
var
  aClaveCifrado: TBytes;
  aClaveMac: TBytes;
  aClaves: TBytes;
  aMac: TBytes;
  aPrefijo: TBytes;
  aSal: TBytes;
  aVector: TBytes;
  oCifrado: TFileStream;
  oZip: TFileStream;
  sRutaCifrado: string;
  sRutaDestinoCompleta: string;
  sRutaSobre: string;
  sRutaZip: string;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(SErrorContrasenaCopiaVacia);
  end;
  sRutaDestinoCompleta := ExpandFileName(ARutaDestino);
  sRutaZip := CrearRutaTemporalJuntoA(
    sRutaDestinoCompleta,
    'viracash_zip_');
  sRutaCifrado := CrearRutaTemporalJuntoA(
    sRutaDestinoCompleta,
    'viracash_cifrado_');
  sRutaSobre := CrearRutaTemporalJuntoA(
    sRutaDestinoCompleta,
    'viracash_sobre_');
  try
    EmpaquetarCopiaSeguridadZipDesdeFichero(
      ARutaScript,
      sRutaZip);
    aSal := GenerarBytesAleatorios(LONGITUD_SAL);
    aVector := GenerarBytesAleatorios(LONGITUD_VECTOR);
    aClaves := DerivarClavePBKDF2(
      AContrasena,
      aSal,
      ITERACIONES_PBKDF2,
      LONGITUD_CLAVES);
    aClaveCifrado := Copy(aClaves, 0, LONGITUD_CLAVE);
    aClaveMac := Copy(
      aClaves,
      LONGITUD_CLAVE,
      LONGITUD_CLAVE);
    oZip := TFileStream.Create(
      sRutaZip,
      fmOpenRead or fmShareDenyWrite);
    try
      oCifrado := TFileStream.Create(sRutaCifrado, fmCreate);
      try
        CifrarAESFlujo(
          oZip,
          oCifrado,
          aClaveCifrado,
          aVector);
      finally
        FreeAndNil(oCifrado);
      end;
    finally
      FreeAndNil(oZip);
    end;
    aPrefijo := CrearDatosAutenticados(
      ITERACIONES_PBKDF2,
      aSal,
      aVector,
      nil,
      CABECERA_CIFRADO_ZIP);
    aMac := CrearHmacSha256Fichero(
      aClaveMac,
      aPrefijo,
      sRutaCifrado);
    EscribirSobreCifradoDesdeFichero(
      sRutaCifrado,
      sRutaSobre,
      aSal,
      aVector,
      aMac);
    PublicarFicheroTemporal(
      sRutaSobre,
      sRutaDestinoCompleta);
  finally
    EliminarFicheroTemporal(sRutaSobre);
    EliminarFicheroTemporal(sRutaCifrado);
    EliminarFicheroTemporal(sRutaZip);
  end;
end;

function EmpaquetarCopiaSeguridadZip(
  const ADatos: TBytes): TBytes;
var
  oDestino: TMemoryStream;
  oZip: TZipFile;
begin
  if Length(ADatos) = 0 then
  begin
    raise ECifradoCopia.Create(SErrorScriptComprimirVacio);
  end;
  if UInt64(Length(ADatos)) >
     UInt64(MAXIMO_DATOS_DESCOMPRIMIDOS) then
  begin
    raise ECifradoCopia.Create(SErrorCopiaDescomprimidaTamanoMaximo);
  end;
  oDestino := TMemoryStream.Create;
  oZip := TZipFile.Create;
  try
    oZip.Open(oDestino, zmWrite);
    try
      oZip.Add(
        ADatos,
        NOMBRE_ENTRADA_ZIP,
        zcDeflate);
    finally
      oZip.Close;
    end;
    SetLength(Result, oDestino.Size);
    oDestino.Position := 0;
    if oDestino.Size > 0 then
      oDestino.ReadBuffer(Result[0], oDestino.Size);
  finally
    FreeAndNil(oZip);
    FreeAndNil(oDestino);
  end;
end;

function DescomprimirZLibBytes(const ADatos: TBytes): TBytes;
var
  Buffer: TBytes;
  Destino: TMemoryStream;
  Descompresor: TZDecompressionStream;
  Leidos: Integer;
  Origen: TBytesStream;
begin
  Origen := TBytesStream.Create(ADatos);
  Destino := TMemoryStream.Create;
  try
    Descompresor := TZDecompressionStream.Create(Origen);
    try
      SetLength(Buffer, 65536);
      Leidos := Descompresor.Read(Buffer[0], Length(Buffer));
      while Leidos > 0 do
      begin
        if Destino.Size + Leidos > MAXIMO_DATOS_DESCOMPRIMIDOS then
        begin
          raise ECifradoCopia.Create(SErrorCopiaDescomprimidaTamanoMaximo);
        end;
        Destino.WriteBuffer(Buffer[0], Leidos);
        Leidos := Descompresor.Read(Buffer[0], Length(Buffer));
      end;
    finally
      FreeAndNil(Descompresor);
    end;
    SetLength(Result, Destino.Size);
    Destino.Position := 0;
    if Destino.Size > 0 then
      Destino.ReadBuffer(Result[0], Destino.Size);
  finally
    FreeAndNil(Destino);
    FreeAndNil(Origen);
  end;
end;

function DesempaquetarCopiaSeguridadZip(
  const ADatos: TBytes): TBytes;
var
  oCabecera: TZipHeader;
  oOrigen: TBytesStream;
  oZip: TZipFile;
begin
  oOrigen := TBytesStream.Create(ADatos);
  oZip := TZipFile.Create;
  try
    try
      oZip.Open(oOrigen, zmRead);
      if oZip.FileCount <> 1 then
      begin
        raise ECifradoCopia.Create(SErrorZipCopiaUnicoArchivo);
      end;
      if not SameText(
        oZip.FileName[0],
        NOMBRE_ENTRADA_ZIP) then
      begin
        raise ECifradoCopia.Create(SErrorZipCopiaSinScript);
      end;
      oCabecera := oZip.FileInfo[0];
      if oCabecera.UncompressedSize64 = 0 then
      begin
        raise ECifradoCopia.Create(SErrorScriptZipVacio);
      end;
      if oCabecera.UncompressedSize64 >
         UInt64(MAXIMO_DATOS_DESCOMPRIMIDOS) then
      begin
        raise ECifradoCopia.Create(SErrorCopiaDescomprimidaTamanoMaximo);
      end;
      oZip.Read(0, Result);
    except
      on E: EZipException do
      begin
        raise ECifradoCopia.CreateFmt(
          SErrorZipCopiaInvalido,
          [E.Message]);
      end;
    end;
  finally
    FreeAndNil(oZip);
    FreeAndNil(oOrigen);
  end;
end;

procedure DesempaquetarCopiaSeguridadZipDesdeFichero(
  const ARutaZip, ARutaScript: string);
var
  iCopiados: Int64;
  oCabecera: TZipHeader;
  oCabeceraLocal: TZipHeader;
  oDestino: TFileStream;
  oEntrada: TStream;
  oZip: TZipFile;
  sRutaDestino: string;
  sRutaTemporal: string;
begin
  oDestino := nil;
  oEntrada := nil;
  oZip := TZipFile.Create;
  sRutaDestino := ExpandFileName(ARutaScript);
  sRutaTemporal := CrearRutaTemporalJuntoA(
    sRutaDestino,
    'viracash_sql_extraido_');
  try
    try
      oZip.Open(ARutaZip, zmRead);
      if oZip.FileCount <> 1 then
      begin
        raise ECifradoCopia.Create(SErrorZipCopiaUnicoArchivo);
      end;
      if not SameText(
        oZip.FileName[0],
        NOMBRE_ENTRADA_ZIP) then
      begin
        raise ECifradoCopia.Create(SErrorZipCopiaSinScript);
      end;
      oCabecera := oZip.FileInfo[0];
      if oCabecera.UncompressedSize64 = 0 then
      begin
        raise ECifradoCopia.Create(SErrorScriptZipVacio);
      end;
      {$IF CompilerVersion >= 36.0}
        oZip.Read(
          0,
          oEntrada,
          oCabeceraLocal,
          True);
      {$ELSE}
        oZip.Read(
        0,
        oEntrada,
        oCabeceraLocal);
      {$IFEND}
      oDestino := TFileStream.Create(sRutaTemporal, fmCreate);
      iCopiados := CopiarFlujoHastaFin(oEntrada, oDestino);
      if UInt64(iCopiados) <> oCabecera.UncompressedSize64 then
      begin
        raise ECifradoCopia.Create(
          SErrorExtraerScriptCopiaIncompleto);
      end;
      FreeAndNil(oDestino);
      FreeAndNil(oEntrada);
      PublicarFicheroTemporal(sRutaTemporal, sRutaDestino);
    except
      on E: EZipException do
      begin
        raise ECifradoCopia.CreateFmt(
          SErrorZipCopiaInvalido,
          [E.Message]);
      end;
    end;
  finally
    FreeAndNil(oDestino);
    FreeAndNil(oEntrada);
    FreeAndNil(oZip);
    EliminarFicheroTemporal(sRutaTemporal);
  end;
end;

function ObtenerCabeceraCifrado(const ADatos: string): string;
var
  iFinCabecera: Integer;
begin
  Result := TrimLeft(ADatos);
  iFinCabecera := Pos(#10, Result);
  if iFinCabecera = 0 then
    iFinCabecera := Pos(#13, Result);
  if iFinCabecera > 0 then
    Result := Copy(Result, 1, iFinCabecera - 1);
  Result := Trim(Result);
end;

function ResolverFormatoCifrado(
  const ADatos: string
): TFormatoCifradoCopia;
var
  sCabecera: string;
begin
  sCabecera := ObtenerCabeceraCifrado(ADatos);
  if SameText(CABECERA_CIFRADO, sCabecera) then
    Result := fccV2
  else if SameText(CABECERA_CIFRADO_ZLIB, sCabecera) then
    Result := fccV3ZLib
  else if SameText(CABECERA_CIFRADO_ZIP, sCabecera) then
    Result := fccV3Zip
  else
    Result := fccDesconocido;
end;

function EsFormatoCifradoActual(const ADatos: string): Boolean;
begin
  Result := ResolverFormatoCifrado(ADatos) <>
    fccDesconocido;
end;

procedure PrepararOrigenCifrado(
  const ADatos: string;
  AFormato: TFormatoCifradoCopia;
  out AOrigen: TBytes;
  out ACabecera: string);
begin
  AOrigen := TEncoding.UTF8.GetBytes(ADatos);
  case AFormato of
    fccV2:
      ACabecera := CABECERA_CIFRADO;
    fccV3Zip:
    begin
      AOrigen := EmpaquetarCopiaSeguridadZip(AOrigen);
      ACabecera := CABECERA_CIFRADO_ZIP;
    end;
  else
    raise ECifradoCopia.Create(SErrorFormatoCopiaNoValido);
  end;
end;

function CifrarCopiaSeguridadInterna(
  const ADatos, AContrasena: string;
  AFormato: TFormatoCifradoCopia): string;
var
  aCifrado: TBytes;
  aClaveCifrado: TBytes;
  aClaveMac: TBytes;
  aClaves: TBytes;
  aDatosAutenticados: TBytes;
  aMac: TBytes;
  aOrigen: TBytes;
  aSal: TBytes;
  aVector: TBytes;
  sCabecera: string;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(SErrorContrasenaCopiaVacia);
  end;
  ComprobarTamanoSqlEnCadena(ADatos);
  aSal := GenerarBytesAleatorios(LONGITUD_SAL);
  aVector := GenerarBytesAleatorios(LONGITUD_VECTOR);
  aClaves := DerivarClavePBKDF2(
    AContrasena,
    aSal,
    ITERACIONES_PBKDF2,
    LONGITUD_CLAVES);
  aClaveCifrado := Copy(aClaves, 0, LONGITUD_CLAVE);
  aClaveMac := Copy(
    aClaves,
    LONGITUD_CLAVE,
    LONGITUD_CLAVE);
  PrepararOrigenCifrado(
    ADatos,
    AFormato,
    aOrigen,
    sCabecera);
  aCifrado := CifrarAESBytes(
    aOrigen,
    aClaveCifrado,
    aVector);
  aDatosAutenticados := CrearDatosAutenticados(
    ITERACIONES_PBKDF2,
    aSal,
    aVector,
    aCifrado,
    IfThen(AFormato = fccV3Zip, sCabecera, ''));
  aMac := THashSHA2.GetHMACAsBytes(
    aDatosAutenticados,
    aClaveMac);
  Result := sCabecera + sLineBreak +
    IntToStr(ITERACIONES_PBKDF2) + sLineBreak +
    CodificarBase64(aSal) + sLineBreak +
    CodificarBase64(aVector) + sLineBreak +
    CodificarBase64(aMac) + sLineBreak +
    CodificarBase64(aCifrado);
end;

function CifrarCopiaSeguridad(
  const ADatos, AContrasena: string): string;
begin
  Result := CifrarCopiaSeguridadInterna(
    ADatos,
    AContrasena,
    fccV2);
end;

function CifrarCopiaSeguridadComprimida(
  const ADatos, AContrasena: string): string;
begin
  Result := CifrarCopiaSeguridadInterna(
    ADatos,
    AContrasena,
    fccV3Zip);
end;

function LeerSobreCifrado(
  const ADatos: string;
  AFormato: TFormatoCifradoCopia): TSobreCifradoCopia;
var
  oLineas: TStringList;
begin
  Result := Default(TSobreCifradoCopia);
  oLineas := TStringList.Create;
  try
    oLineas.Text := ADatos;
    if oLineas.Count < 6 then
    begin
      raise ECifradoCopia.Create(SErrorCabeceraCopiaCifradaIncompleta);
    end;
    Result.Cabecera := Trim(oLineas[0]);
    if ResolverFormatoCifrado(Result.Cabecera) <> AFormato then
    begin
      raise ECifradoCopia.Create(SErrorVersionCopiaCifradaIncompatible);
    end;
    Result.Iteraciones := StrToIntDef(
      Trim(oLineas[1]),
      0);
    if (Result.Iteraciones < 10000) or
       (Result.Iteraciones > 1000000) then
    begin
      raise ECifradoCopia.Create(SErrorIteracionesCopiaNoValido);
    end;
    Result.Sal := DecodificarBase64(Trim(oLineas[2]));
    Result.Vector := DecodificarBase64(Trim(oLineas[3]));
    Result.Mac := DecodificarBase64(Trim(oLineas[4]));
    Result.Cifrado := DecodificarBase64(Trim(oLineas[5]));
  finally
    FreeAndNil(oLineas);
  end;
end;

procedure ValidarDimensionesSobre(
  const ASobre: TSobreCifradoCopia);
begin
  if (Length(ASobre.Sal) <> LONGITUD_SAL) or
     (Length(ASobre.Vector) <> LONGITUD_VECTOR) or
     (Length(ASobre.Mac) <> LONGITUD_CLAVE) then
  begin
    raise ECifradoCopia.Create(SErrorMetadatosCopiaCifradaInvalidos);
  end;
end;

function ObtenerClaveCifradoValidada(
  const ASobre: TSobreCifradoCopia;
  const AContrasena: string;
  AFormato: TFormatoCifradoCopia): TBytes;
var
  aClaveMac: TBytes;
  aClaves: TBytes;
  aDatosAutenticados: TBytes;
  aMacCalculado: TBytes;
begin
  aClaves := DerivarClavePBKDF2(
    AContrasena,
    ASobre.Sal,
    ASobre.Iteraciones,
    LONGITUD_CLAVES);
  Result := Copy(aClaves, 0, LONGITUD_CLAVE);
  aClaveMac := Copy(
    aClaves,
    LONGITUD_CLAVE,
    LONGITUD_CLAVE);
  aDatosAutenticados := CrearDatosAutenticados(
    ASobre.Iteraciones,
    ASobre.Sal,
    ASobre.Vector,
    ASobre.Cifrado,
    IfThen(AFormato = fccV3Zip, ASobre.Cabecera, ''));
  aMacCalculado := THashSHA2.GetHMACAsBytes(
    aDatosAutenticados,
    aClaveMac);
  if not ComparacionConstante(aMacCalculado, ASobre.Mac) then
  begin
    raise ECifradoCopia.Create(SErrorContrasenaIncorrectaOCopiaDanada);
  end;
end;

function DescifrarFormatoActual(
  const ADatos, AContrasena: string;
  AFormato: TFormatoCifradoCopia
): string;
var
  aClaveCifrado: TBytes;
  aPlano: TBytes;
  Sobre: TSobreCifradoCopia;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(SErrorIndicarContrasenaCopia);
  end;
  Sobre := LeerSobreCifrado(ADatos, AFormato);
  ValidarDimensionesSobre(Sobre);
  aClaveCifrado := ObtenerClaveCifradoValidada(
    Sobre,
    AContrasena,
    AFormato);
  aPlano := DescifrarAESBytes(
    Sobre.Cifrado,
    aClaveCifrado,
    Sobre.Vector);
  case AFormato of
    fccV3ZLib:
      aPlano := DescomprimirZLibBytes(aPlano);
    fccV3Zip:
      aPlano := DesempaquetarCopiaSeguridadZip(aPlano);
  end;
  Result := TEncoding.UTF8.GetString(aPlano);
end;

function DescifrarCopiaSeguridad(
  const ADatos, AContrasena: string): string;
var
  Formato: TFormatoCifradoCopia;
begin
  Formato := ResolverFormatoCifrado(ADatos);
  if Formato <> fccDesconocido then
  begin
    Result := DescifrarFormatoActual(
      ADatos,
      AContrasena,
      Formato);
  end
  else
  begin
    Result := DescifrarAESConContrasena(
      ADatos,
      AnsiString(AContrasena));
    if Trim(Result) = '' then
    begin
      raise ECifradoCopia.Create(SErrorAbrirCopiaCifradaHistorica);
    end;
  end;
end;

function LeerLineaAscii(
  const AOrigen: TStream;
  out ALinea: string): Boolean;
var
  aBytes: TBytes;
  bByte: Byte;
  bFinLinea: Boolean;
  iLeidos: Integer;
  iLongitud: Integer;
begin
  ALinea := '';
  SetLength(aBytes, 0);
  bFinLinea := False;
  Result := False;
  while (not bFinLinea) and
        (AOrigen.Position < AOrigen.Size) do
  begin
    iLeidos := AOrigen.Read(bByte, 1);
    if iLeidos = 1 then
    begin
      Result := True;
      if bByte = 10 then
        bFinLinea := True
      else if bByte <> 13 then
      begin
        iLongitud := Length(aBytes);
        if iLongitud >= MAXIMO_BYTES_LINEA_METADATOS then
        begin
          raise ECifradoCopia.Create(
            SErrorMetadatosCopiaCifradaInvalidos);
        end;
        SetLength(aBytes, iLongitud + 1);
        aBytes[iLongitud] := bByte;
      end;
    end
    else
      bFinLinea := True;
  end;
  if Length(aBytes) > 0 then
    ALinea := TEncoding.ASCII.GetString(aBytes);
end;

function LeerSobreCifradoDesdeFichero(
  const AOrigen: TStream;
  AFormato: TFormatoCifradoCopia): TSobreCifradoCopia;
var
  aLineas: array[0..4] of string;
  iIndice: Integer;
begin
  Result := Default(TSobreCifradoCopia);
  for iIndice := Low(aLineas) to High(aLineas) do
  begin
    if not LeerLineaAscii(AOrigen, aLineas[iIndice]) then
    begin
      raise ECifradoCopia.Create(
        SErrorCabeceraCopiaCifradaIncompleta);
    end;
  end;
  Result.Cabecera := Trim(aLineas[0]);
  if ResolverFormatoCifrado(Result.Cabecera) <> AFormato then
  begin
    raise ECifradoCopia.Create(
      SErrorVersionCopiaCifradaIncompatible);
  end;
  Result.Iteraciones := StrToIntDef(Trim(aLineas[1]), 0);
  if (Result.Iteraciones < 10000) or
     (Result.Iteraciones > 1000000) then
  begin
    raise ECifradoCopia.Create(SErrorIteracionesCopiaNoValido);
  end;
  Result.Sal := DecodificarBase64(Trim(aLineas[2]));
  Result.Vector := DecodificarBase64(Trim(aLineas[3]));
  Result.Mac := DecodificarBase64(Trim(aLineas[4]));
end;

procedure DecodificarBase64DesdeFichero(
  const AOrigen: TStream;
  const ARutaDestino: string);
var
  aCodificado: TBytes;
  aDecodificado: TBytes;
  iLeidos: Integer;
  oBase64: TBase64Encoding;
  oDestino: TFileStream;
begin
  oBase64 := TBase64Encoding.Create(0);
  oDestino := TFileStream.Create(ARutaDestino, fmCreate);
  try
    SetLength(aCodificado, TAMANO_BLOQUE_FLUJO);
    iLeidos := LeerBloqueFlujo(AOrigen, aCodificado);
    while iLeidos > 0 do
    begin
      SetLength(aCodificado, iLeidos);
      try
        aDecodificado := oBase64.Decode(aCodificado);
      except
        on E: Exception do
        begin
          raise ECifradoCopia.CreateFmt(
            SErrorBase64CopiaCifradaInvalido,
            [E.Message]);
        end;
      end;
      if Length(aDecodificado) > 0 then
      begin
        oDestino.WriteBuffer(
          aDecodificado[0],
          Length(aDecodificado));
      end;
      SetLength(aCodificado, TAMANO_BLOQUE_FLUJO);
      iLeidos := LeerBloqueFlujo(AOrigen, aCodificado);
    end;
    if oDestino.Size = 0 then
    begin
      raise ECifradoCopia.Create(
        SErrorContenidoCifradoLongitudInvalida);
    end;
  finally
    FreeAndNil(oDestino);
    FreeAndNil(oBase64);
  end;
end;

function ResolverFormatoCifradoDesdeFichero(
  const AOrigen: TStream): TFormatoCifradoCopia;
var
  aPrefijo: TBytes;
  iLeer: Integer;
  sPrefijo: string;
begin
  iLeer := TAMANO_PREFIJO_FORMATO;
  if AOrigen.Size < iLeer then
    iLeer := Integer(AOrigen.Size);
  SetLength(aPrefijo, iLeer);
  AOrigen.Position := 0;
  if iLeer > 0 then
    AOrigen.ReadBuffer(aPrefijo[0], iLeer);
  AOrigen.Position := 0;
  sPrefijo := TEncoding.ASCII.GetString(aPrefijo);
  Result := ResolverFormatoCifrado(sPrefijo);
end;

function ObtenerClaveCifradoFicheroValidada(
  const ASobre: TSobreCifradoCopia;
  const AContrasena: string;
  AFormato: TFormatoCifradoCopia;
  const ARutaCifrado: string): TBytes;
var
  aClaveMac: TBytes;
  aClaves: TBytes;
  aMacCalculado: TBytes;
  aPrefijo: TBytes;
begin
  aClaves := DerivarClavePBKDF2(
    AContrasena,
    ASobre.Sal,
    ASobre.Iteraciones,
    LONGITUD_CLAVES);
  Result := Copy(aClaves, 0, LONGITUD_CLAVE);
  aClaveMac := Copy(
    aClaves,
    LONGITUD_CLAVE,
    LONGITUD_CLAVE);
  aPrefijo := CrearDatosAutenticados(
    ASobre.Iteraciones,
    ASobre.Sal,
    ASobre.Vector,
    nil,
    IfThen(AFormato = fccV3Zip, ASobre.Cabecera, ''));
  aMacCalculado := CrearHmacSha256Fichero(
    aClaveMac,
    aPrefijo,
    ARutaCifrado);
  if not ComparacionConstante(aMacCalculado, ASobre.Mac) then
  begin
    raise ECifradoCopia.Create(
      SErrorContrasenaIncorrectaOCopiaDanada);
  end;
end;

procedure DescifrarAESDesdeFicheros(
  const ARutaCifrado, ARutaPlano: string;
  const AClave, AVector: TBytes);
var
  oCifrado: TFileStream;
  oPlano: TFileStream;
begin
  oCifrado := TFileStream.Create(
    ARutaCifrado,
    fmOpenRead or fmShareDenyWrite);
  try
    oPlano := TFileStream.Create(ARutaPlano, fmCreate);
    try
      DescifrarAESFlujo(
        oCifrado,
        oPlano,
        AClave,
        AVector);
    finally
      FreeAndNil(oPlano);
    end;
  finally
    FreeAndNil(oCifrado);
  end;
end;

procedure DescomprimirZLibDesdeFichero(
  const ARutaComprimida, ARutaScript: string);
var
  oComprimido: TFileStream;
  oDescompresor: TZDecompressionStream;
  oScript: TFileStream;
begin
  oComprimido := TFileStream.Create(
    ARutaComprimida,
    fmOpenRead or fmShareDenyWrite);
  try
    oDescompresor := TZDecompressionStream.Create(oComprimido);
    try
      oScript := TFileStream.Create(ARutaScript, fmCreate);
      try
        CopiarFlujoHastaFin(oDescompresor, oScript);
        if oScript.Size = 0 then
        begin
          raise ECifradoCopia.Create(SErrorScriptZipVacio);
        end;
      finally
        FreeAndNil(oScript);
      end;
    finally
      FreeAndNil(oDescompresor);
    end;
  finally
    FreeAndNil(oComprimido);
  end;
end;

procedure GuardarTextoUtf8EnFichero(
  const ATexto, ARutaFichero: string);
var
  aBytesTexto: TBytes;
  oFichero: TFileStream;
begin
  aBytesTexto := TEncoding.UTF8.GetBytes(ATexto);
  oFichero := TFileStream.Create(ARutaFichero, fmCreate);
  try
    if Length(aBytesTexto) > 0 then
    begin
      oFichero.WriteBuffer(
        aBytesTexto[0],
        Length(aBytesTexto));
    end;
  finally
    FreeAndNil(oFichero);
  end;
end;

procedure DescifrarCopiaHistoricaDesdeFichero(
  const ARutaCopia, ARutaScript, AContrasena: string);
var
  oTexto: TStringList;
  sContenido: string;
begin
  oTexto := TStringList.Create;
  try
    oTexto.LoadFromFile(ARutaCopia);
    sContenido := DescifrarCopiaSeguridad(
      oTexto.Text,
      AContrasena);
  finally
    FreeAndNil(oTexto);
  end;
  GuardarTextoUtf8EnFichero(sContenido, ARutaScript);
end;

procedure NotificarEtapaAperturaCopia(
  AOnEtapa: TEtapaAperturaCopiaEvent;
  AEtapa: TEtapaAperturaCopia);
begin
  if Assigned(AOnEtapa) then
    AOnEtapa(AEtapa);
end;

procedure DescifrarCopiaSeguridadDesdeFichero(
  const ARutaCopia, ARutaScript, AContrasena: string;
  AOnEtapa: TEtapaAperturaCopiaEvent);
var
  aClaveCifrado: TBytes;
  Formato: TFormatoCifradoCopia;
  oCopia: TFileStream;
  Sobre: TSobreCifradoCopia;
  sRutaCifrado: string;
  sRutaDestino: string;
  sRutaPlano: string;
  sRutaPublicar: string;
  sRutaScript: string;
begin
  if Trim(AContrasena) = '' then
  begin
    raise ECifradoCopia.Create(SErrorIndicarContrasenaCopia);
  end;
  oCopia := nil;
  sRutaDestino := ExpandFileName(ARutaScript);
  sRutaCifrado := CrearRutaTemporalJuntoA(
    sRutaDestino,
    'viracash_descifrado_');
  sRutaPlano := CrearRutaTemporalJuntoA(
    sRutaDestino,
    'viracash_plano_');
  sRutaScript := CrearRutaTemporalJuntoA(
    sRutaDestino,
    'viracash_sql_');
  sRutaPublicar := '';
  try
    oCopia := TFileStream.Create(
      ARutaCopia,
      fmOpenRead or fmShareDenyWrite);
    Formato := ResolverFormatoCifradoDesdeFichero(oCopia);
    if Formato = fccDesconocido then
    begin
      FreeAndNil(oCopia);
      NotificarEtapaAperturaCopia(
        AOnEtapa,
        eacDescifrando);
      DescifrarCopiaHistoricaDesdeFichero(
        ARutaCopia,
        sRutaScript,
        AContrasena);
      NotificarEtapaAperturaCopia(
        AOnEtapa,
        eacValidandoContenido);
      sRutaPublicar := sRutaScript;
    end
    else
    begin
      Sobre := LeerSobreCifradoDesdeFichero(oCopia, Formato);
      ValidarDimensionesSobre(Sobre);
      NotificarEtapaAperturaCopia(
        AOnEtapa,
        eacVerificandoIntegridad);
      DecodificarBase64DesdeFichero(oCopia, sRutaCifrado);
      FreeAndNil(oCopia);
      aClaveCifrado := ObtenerClaveCifradoFicheroValidada(
        Sobre,
        AContrasena,
        Formato,
        sRutaCifrado);
      NotificarEtapaAperturaCopia(
        AOnEtapa,
        eacIntegridadVerificada);
      NotificarEtapaAperturaCopia(
        AOnEtapa,
        eacDescifrando);
      DescifrarAESDesdeFicheros(
        sRutaCifrado,
        sRutaPlano,
        aClaveCifrado,
        Sobre.Vector);
      NotificarEtapaAperturaCopia(
        AOnEtapa,
        eacValidandoContenido);
      case Formato of
        fccV2:
          sRutaPublicar := sRutaPlano;
        fccV3ZLib:
        begin
          DescomprimirZLibDesdeFichero(
            sRutaPlano,
            sRutaScript);
          sRutaPublicar := sRutaScript;
        end;
        fccV3Zip:
        begin
          DesempaquetarCopiaSeguridadZipDesdeFichero(
            sRutaPlano,
            sRutaScript);
          sRutaPublicar := sRutaScript;
        end;
      else
        raise ECifradoCopia.Create(SErrorFormatoCopiaNoValido);
      end;
    end;
    PublicarFicheroTemporal(sRutaPublicar, sRutaDestino);
  finally
    FreeAndNil(oCopia);
    EliminarFicheroTemporal(sRutaScript);
    EliminarFicheroTemporal(sRutaPlano);
    EliminarFicheroTemporal(sRutaCifrado);
  end;
end;

end.
