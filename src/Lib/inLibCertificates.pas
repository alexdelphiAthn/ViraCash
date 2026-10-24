{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCertificates                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura del almacén de certificados digitales de Windows.                 }
{    Expone serie, emisor, titular y caducidad de los certificados instalados. }
{******************************************************************************}
unit inLibCertificates;

interface
uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, System.Types,
  Winapi.Windows, system.StrUtils, Winapi.Messages, cxGridTableView;
const
  COLUMNA_CER_TIPO = 0;
  COLUMNA_CER_TITULAR = 1;
  COLUMNA_CER_NOMBRE = 2;
  COLUMNA_CER_EMISOR = 3;
  COLUMNA_CER_FECHAHASTA = 4;
  COLUMNA_CER_NROSERIE = 5;
  CRYPT32 = 'crypt32.dll';
  X509_ASN_ENCODING = $00000001;
  PKCS_7_ASN_ENCODING = $00010000;
  szOID_ENHANCED_KEY_USAGE = '2.5.29.37';
  CERT_FIND_PROP_ONLY_ENHKEY_USAGE_FLAG = 1;
  CERT_FIND_EXT_ONLY_ENHKEY_USAGE_FLAG = 2;
  CERT_FIND_NO_ENHKEY_USAGE_FLAG = 4;
  CERT_FIND_OR_ENHKEY_USAGE_FLAG = 8;
  CERT_FIND_VALID_ENHKEY_USAGE_FLAG = $20;
  CERT_STORE_PROV_SYSTEM = 10;
  CERT_X500_NAME_STR = 3;
  CERT_NAME_STR_NO_QUOTING_FLAG = $10;
  CERT_SIMPLE_NAME_STR = 1;
  CERT_NAME_STR_SEMICOLON_FLAG = 1;
  CERT_OID_NAME_STR = 2;
  CERT_NAME_STR_CRLF_FLAG = 2;
  CERT_NAME_STR_NO_PLUS_FLAG = 32;
  CERT_NAME_STR_REVERSE_FLAG = 4;
  CERT_NAME_STR_DISABLE_IE4_UTF8_FLAG = 65536;
  CERT_NAME_STR_ENABLE_PUNYCODE_FLAG = 131072;
  CERT_NAME_STR_ENABLE_UTF8_UNICODE_FLAG = 262144;
  CRYPT_DECODE_ALLOC_FLAG = $8000;
  CRYPT_DECODE_NOCOPY_FLAG = $1;
type
  {$IF CompilerVersion < 34.0} // Delphi 10.3 y versiones anteriores
  // Declarar tipos que no existen en Delphi 10.3
  PCERT_NAME_BLOB = ^CERT_NAME_BLOB;
  PCERT_INFO = ^CERT_INFO;
  PCERT_EXTENSION = ^CERT_EXTENSION;
  PCERT_PUBLIC_KEY_INFO = ^CERT_PUBLIC_KEY_INFO;
  CERT_NAME_BLOB = record
    cbData: DWORD;
    pbData: PByte;
  end;
  CRYPT_INTEGER_BLOB = CERT_NAME_BLOB;
  CRYPT_BIT_BLOB = record
    cbData: DWORD;
    pbData: PByte;
    cUnusedBits: DWORD;
  end;
  CRYPT_ALGORITHM_IDENTIFIER = record
    pszObjId: LPSTR;
    Parameters: CERT_NAME_BLOB;
  end;
  CERT_PUBLIC_KEY_INFO = record
    Algorithm: CRYPT_ALGORITHM_IDENTIFIER;
    PublicKey: CRYPT_BIT_BLOB;
  end;
  CERT_EXTENSION = record
    pszObjId: LPSTR;
    fCritical: BOOL;
    Value: CERT_NAME_BLOB;
  end;
  HCRYPTPROV_LEGACY = ULONG_PTR;
  HCRYPTPROV = ULONG_PTR;
  HCERTSTORE = THandle;
  PCCERT_CONTEXT = ^CERT_CONTEXT;
  CERT_CONTEXT = record
    dwCertEncodingType: DWORD;
    pbCertEncoded: PBYTE;
    cbCertEncoded: DWORD;
    pCertInfo: PCERT_INFO;
    hCertStore: HCERTSTORE;
  end;
  CERT_INFO = record
    dwVersion: DWORD;
    SerialNumber: CRYPT_INTEGER_BLOB;
    SignatureAlgorithm: CRYPT_ALGORITHM_IDENTIFIER;
    Issuer: CERT_NAME_BLOB;
    NotBefore: FILETIME;
    NotAfter: FILETIME;
    Subject: CERT_NAME_BLOB;
    SubjectPublicKeyInfo: CERT_PUBLIC_KEY_INFO;
    IssuerUniqueId: CRYPT_BIT_BLOB;
    SubjectUniqueId: CRYPT_BIT_BLOB;
    cExtension: DWORD;
    rgExtension: PCERT_EXTENSION;
  end;
  {$ELSE}
  // Para Delphi 11, estos tipos ya existen en Winapi.Windows
  HCRYPTPROV_LEGACY = ULONG_PTR;
  {$IFEND}
  // Este tipo no existe en ninguna versión, siempre hay que declararlo
  PCERT_ENHKEY_USAGE = ^CERT_ENHKEY_USAGE;
  CERT_ENHKEY_USAGE = record
    cUsageIdentifier: DWORD;
    rgpszUsageIdentifier: ^LPSTR;
  end;
  function CertNameToStrA(dwCertEncodingType: DWORD;
                          pName: PCERT_NAME_BLOB;
                          dwStrType: DWORD;
                          psz: LPSTR;
                          csz: DWORD): DWORD;
                          stdcall; external CRYPT32;
  procedure CargarCertificados(ATvCertificados: TcxGridTableView);
  function GetCertName(pName: PCERT_NAME_BLOB): string;
  function FileTimeToDateTime(const AFileTime: TFileTime): TDateTime;
  function GetCertificateName(pName: PCERT_NAME_BLOB): string;
  function IsCertificateValid(ACertContext: PCCERT_CONTEXT): Boolean;
  function IsEFacturaCertificate(ACertContext: PCCERT_CONTEXT): Boolean;
  function GetCertificateType(const AIssuer: string): string;
  function ExtractCertificateName(const ADescription: string): string;
  function ObtenerCaducidadCertificado(const ANumeroSerie,
                                       ATitular: string;
                                       out AFechaHasta: TDateTime;
                                       out ATitularReal: string): Boolean;
  procedure AgregarCertificado(ATvCertificados: TcxGridTableView;
                               const ASubject, AIssuer,
                               ASerialNumber: string;
                               AValidFrom, AValidTo: TDateTime);
  function CertGetEnhancedKeyUsage(
                                    pCertContext: PCCERT_CONTEXT;
                                    dwFlags: DWORD;
                                    pUsage: PCERT_ENHKEY_USAGE;
                                    pcbUsage: PDWORD):
                                    BOOL; stdcall; external CRYPT32;
  function CertCloseStore(hCertStore: HCERTSTORE;
                          dwFlags: DWORD): BOOL;
                          stdcall; external CRYPT32;
  function CertEnumCertificatesInStore(hCertStore: HCERTSTORE;
                                       pPrevCertContext: PCCERT_CONTEXT):
                                       PCCERT_CONTEXT;
                                       stdcall; external CRYPT32;
  function CertOpenSystemStoreA(hprov: HCRYPTPROV_LEGACY;
                                szSubsystemProtocol: LPCSTR):HCERTSTORE;
                                stdcall; external 'crypt32.dll';
  function CertNameToStr(dwCertEncodingType: DWORD;
                         pName: PCERT_NAME_BLOB;
                         dwStrType: DWORD;
                         psz: PWideChar;
                         csz: DWORD): DWORD;
                         stdcall; external 'crypt32.dll';
implementation
function NormalizarNumeroSerieCertificado(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));
  Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
  Result := StringReplace(Result, ':', '', [rfReplaceAll]);
  Result := StringReplace(Result, '-', '', [rfReplaceAll]);
end;

function InvertirBytesHex(const AHex: string): string;
var
  iPos: Integer;
begin
  Result := '';
  iPos := Length(AHex) - 1;
  while iPos >= 1 do
  begin
    Result := Result + Copy(AHex, iPos, 2);
    Dec(iPos, 2);
  end;
end;

function NumeroSerieCertificado(ACertContext: PCCERT_CONTEXT): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to ACertContext^.pCertInfo^.SerialNumber.cbData - 1 do
    Result := Result +
      IntToHex(PByte(ACertContext^.pCertInfo^.SerialNumber.pbData)[I], 2);
end;

function CertificadoCoincide(ACertContext: PCCERT_CONTEXT;
                             const ANumeroSerie,
                             ATitular: string): Boolean;
var
  sBuscada: string;
  sSerie:   string;
  sSubject: string;
  sTitular: string;
begin
  Result := False;
  sBuscada := NormalizarNumeroSerieCertificado(ANumeroSerie);
  sSerie := NormalizarNumeroSerieCertificado(
    NumeroSerieCertificado(ACertContext));
  if sBuscada <> '' then
    Result := (sSerie = sBuscada) or
              (InvertirBytesHex(sSerie) = sBuscada) or
              (sSerie = InvertirBytesHex(sBuscada));
  if (not Result) and (Trim(ATitular) <> '') then
  begin
    sSubject := GetCertificateName(@ACertContext^.pCertInfo^.Subject);
    sTitular := ExtractCertificateName(sSubject);
    Result := ContainsText(sTitular, Trim(ATitular)) or
              ContainsText(sSubject, Trim(ATitular));
  end;
end;

function FileTimeToLocalDateTime(const AFileTime: TFileTime): TDateTime;
var
  LocalFileTime: TFileTime;
  SystemTime:    TSystemTime;
begin
  Result := 0;
  if FileTimeToLocalFileTime(AFileTime, LocalFileTime) then
  begin
    if FileTimeToSystemTime(LocalFileTime, SystemTime) then
      Result := SystemTimeToDateTime(SystemTime);
  end;
end;

function ExtractCertificateName(const ADescription: string): string;
var
  Parts: TArray<string>;
  I: Integer;
begin
  Result := '';
  if ContainsText(ADescription, 'O=') then
  begin
    Parts := ADescription.Split([',']);
    for I := 0 to Length(Parts) - 1 do
    begin
      if Parts[I].Contains('O=') then
      begin
        Result := Copy(Parts[I], 3, Length(Parts[I]));
        Break;
      end;
    end;
  end
  else if ContainsText(ADescription, 'CN=') then
  begin
    Parts := ADescription.Split([',']);
    for I := 0 to Length(Parts) - 1 do
    begin
      if Parts[I].Contains('CN=') then
      begin
        Result := Copy(Parts[I], 4, Length(Parts[I]));
        Break;
      end;
    end;
  end;
end;
function GetCertificateType(const AIssuer: string): string;
begin
  if ContainsText(AIssuer, 'AC Representación') then
    Result := 'Representación FNMT'
  else if ContainsText(AIssuer, 'AC FNMT Usuarios') then
    Result := 'Nominal FNMT'
  else
    Result := 'Otro';
end;
function IsCertificateValid(ACertContext: PCCERT_CONTEXT): Boolean;
var
  CurrentTime, NotBefore, NotAfter: TFileTime;
begin
  //Result := False;
  GetSystemTimeAsFileTime(CurrentTime);
  NotBefore := ACertContext^.pCertInfo^.NotBefore;
  NotAfter := ACertContext^.pCertInfo^.NotAfter;
  Result := (CompareFileTime(CurrentTime, NotBefore) >= 0) and
            (CompareFileTime(CurrentTime, NotAfter) <= 0);
end;
function GetCertificateName(pName: PCERT_NAME_BLOB): string;
var
  dwStrLen: DWORD;
  pwszNameString: PAnsiChar;
begin
  Result := '';
  dwStrLen := CertNameToStrA( X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                              pName,
                              CERT_X500_NAME_STR,
                              nil,
                              0);
  if (dwStrLen > 0) then
  begin
    GetMem(pwszNameString, dwStrLen);
    try
      if CertNameToStrA(
        X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
        pName,
        CERT_X500_NAME_STR,
        pwszNameString,
        dwStrLen) > 0 then
      begin
        Result := string(pwszNameString);
      end;
    finally
      FreeMem(pwszNameString);
    end;
  end;
end;
function GetCertName(pName: PCERT_NAME_BLOB): string;
var
  pcbStrLen: DWORD;
  pwszStr: PWideChar;
begin
  Result := '';
  pcbStrLen := CertNameToStr(X509_ASN_ENCODING,
                             pName,
                             CERT_X500_NAME_STR,
                             nil,
                             0);
  if (pcbStrLen > 1) then
  begin
    GetMem(pwszStr, pcbStrLen * 2);
    try
      if CertNameToStr(X509_ASN_ENCODING,
                       pName,
                       CERT_X500_NAME_STR,
                       pwszStr, pcbStrLen) > 1 then
        Result := pwszStr;
    finally
      FreeMem(pwszStr);
    end;
  end;
end;
function FileTimeToDateTime(const AFileTime: TFileTime): TDateTime;
var
  SystemTime: TSystemTime;
begin
  FileTimeToSystemTime(AFileTime, SystemTime);
  Result := SystemTimeToDateTime(SystemTime);
end;
function IsEFacturaCertificate(ACertContext: PCCERT_CONTEXT): Boolean;
var
  Issuer: string;
begin
  //Result := False;
  Issuer := GetCertificateName(@ACertContext^.pCertInfo^.Issuer);
  Result := (ContainsText(Issuer, 'AC Representación') or
            (ContainsText(Issuer, 'AC FNMT Usuarios')));
end;
procedure CargarCertificados(ATvCertificados: TcxGridTableView);
var
  Store: HCERTSTORE;
  CertContext: PCCERT_CONTEXT;
  Subject, Issuer: string;
  ValidFrom, ValidTo: TDateTime;
  SerialNumber: string;
  I: Integer;
begin
  ATvCertificados.DataController.RecordCount := 0;
  Store := CertOpenSystemStoreA(0, PAnsiChar('MY'));
  {$IF CompilerVersion < 34.0}
  if Store <> 0 then  // Delphi 10.3
  {$ELSE}
  if Store <> nil then  // Delphi 11
  {$IFEND}
  try
    CertContext := nil;
    repeat
      CertContext := CertEnumCertificatesInStore(Store, CertContext);
      if ((CertContext <> nil)
          and (IsCertificateValid(CertContext))
          and (IsEFacturaCertificate(CertContext))) then
      begin
        Subject := GetCertificateName(@CertContext^.pCertInfo^.Subject);
        Issuer := GetCertificateName(@CertContext^.pCertInfo^.Issuer);
        ValidFrom := FileTimeToDateTime(CertContext^.pCertInfo^.NotBefore);
        ValidTo := FileTimeToDateTime(CertContext^.pCertInfo^.NotAfter);
        SerialNumber := '';
        for I := 0 to CertContext^.pCertInfo^.SerialNumber.cbData - 1 do
          SerialNumber := SerialNumber +
            IntToHex(PByte(CertContext^.pCertInfo^.SerialNumber.pbData)[I], 2);
        AgregarCertificado(ATvCertificados, Subject, Issuer, SerialNumber,
                           ValidFrom, ValidTo);
      end;
    until CertContext = nil;
  finally
    CertCloseStore(Store, 0);
  end;
  if ATvCertificados.DataController.RecordCount > 0 then
    ATvCertificados.Controller.FocusedRecordIndex := 0;
end;
function ObtenerCaducidadCertificado(const ANumeroSerie,
                                     ATitular: string;
                                     out AFechaHasta: TDateTime;
                                     out ATitularReal: string): Boolean;
var
  Store: HCERTSTORE;
  CertContext: PCCERT_CONTEXT;
  Subject: string;
begin
  Result := False;
  AFechaHasta := 0;
  ATitularReal := '';
  Store := CertOpenSystemStoreA(0, PAnsiChar('MY'));
  {$IF CompilerVersion < 34.0}
  if Store <> 0 then
  {$ELSE}
  if Store <> nil then
  {$IFEND}
  begin
    try
      CertContext := nil;
      repeat
        CertContext := CertEnumCertificatesInStore(Store, CertContext);
        if (CertContext <> nil) and
           (not Result) and
           CertificadoCoincide(CertContext, ANumeroSerie, ATitular) then
        begin
          AFechaHasta := FileTimeToLocalDateTime(
            CertContext^.pCertInfo^.NotAfter);
          Subject := GetCertificateName(@CertContext^.pCertInfo^.Subject);
          ATitularReal := ExtractCertificateName(Subject);
          if ATitularReal = '' then
            ATitularReal := Subject;
          Result := AFechaHasta > 0;
        end;
      until CertContext = nil;
    finally
      CertCloseStore(Store, 0);
    end;
  end;
end;
procedure AgregarCertificado(ATvCertificados: TcxGridTableView;
  const ASubject, AIssuer, ASerialNumber: string;
  AValidFrom, AValidTo: TDateTime);
var
  iFila: Integer;
  sTipoCertificado: string;
  sNombreCertificado: string;
begin
  iFila := ATvCertificados.DataController.RecordCount;
  ATvCertificados.DataController.RecordCount := iFila + 1;
  sTipoCertificado := GetCertificateType(AIssuer);
  sNombreCertificado := ExtractCertificateName(ASubject);
  ATvCertificados.DataController.Values[iFila, COLUMNA_CER_TIPO] :=
    sTipoCertificado;
  ATvCertificados.DataController.Values[iFila, COLUMNA_CER_TITULAR] :=
    sNombreCertificado;
  ATvCertificados.DataController.Values[iFila, COLUMNA_CER_NOMBRE] :=
    ASubject;
  ATvCertificados.DataController.Values[iFila, COLUMNA_CER_EMISOR] :=
    AIssuer;
  ATvCertificados.DataController.Values[iFila, COLUMNA_CER_FECHAHASTA] :=
    DateTimeToStr(AValidTo);
  ATvCertificados.DataController.Values[iFila, COLUMNA_CER_NROSERIE] :=
    ASerialNumber;
end;
end.
