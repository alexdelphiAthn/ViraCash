{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFirmaEjecutable                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba la firma Authenticode de un ejecutable: que Windows la dé por   }
{    buena (WinVerifyTrust, sin consultar revocaciones por red), que el        }
{    titular sea Alejandro Laorden Hidalgo (CN y O) y que el certificado sea   }
{    de validación extendida (política 2.23.140.1.3 del CA/Browser Forum).     }
{    No se ata a la huella: al renovar el certificado cambia y la             }
{    comprobación tiene que seguir valiendo.                                   }
{******************************************************************************}
unit inLibFirmaEjecutable;

interface

const
  cTitularFirmaViraCash = 'Alejandro Laorden Hidalgo';
  // Firma de código con validación extendida (CA/Browser Forum).
  cOidPoliticaFirmaCodigoEV = '2.23.140.1.3';

type
  TEstadoFirmaEjecutable = (
    // Firma válida, del titular y con certificado EV.
    efePropia,
    efeSinFirma,
    // Lleva firma, pero Windows no la da por buena (fichero alterado,
    // cadena no fiable...).
    efeNoValida,
    efeOtroTitular,
    // Del titular, pero con un certificado que no es EV.
    efeNoEV,
    // No se ha podido leer la firma.
    efeNoComprobada);

  TResultadoFirmaEjecutable = record
    Estado: TEstadoFirmaEjecutable;
    Titular: string;
    Organizacion: string;
    CodigoWinTrust: Integer;
    Detalle: string;
    function Correcta: Boolean;
  end;

// No lanza excepciones: lo que falle queda en efeNoComprobada y Detalle.
function ComprobarFirmaEjecutable(
  const ARuta: string): TResultadoFirmaEjecutable;
// True si el ejecutable está dentro de un árbol de fuentes (hay un
// vcash.dproj en su carpeta o en alguna de las de encima): es una
// compilación de desarrollo, que no se firma.
function EsEjecutableDesarrollo(const ARuta: string): Boolean;
// Qué le pasa a la firma, para el usuario; '' si es correcta.
function TextoFirmaEjecutable(
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable): string;
// Lo mismo, pero también dice cuándo está bien o es una compilación de
// desarrollo sin firmar (Ayuda > Comprobar integridad).
function TextoComprobacionFirma(
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable): string;
// Lo que no se ha podido mirar no se le echa en cara al usuario, ni la
// compilación de desarrollo sin firmar.
function DebeAvisarFirma(
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable): Boolean;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  inLibMsgComun;

function TextoFirmaEjecutable(
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable): string;
var
  sFichero: string;
begin
  sFichero := ExtractFileName(ARuta);
  case AResultado.Estado of
    efeSinFirma:
      Result := Format(SFirmaEjecutableSinFirma, [sFichero]);
    efeNoValida:
      Result := Format(
        SFirmaEjecutableNoValida,
        [sFichero, IntToHex(AResultado.CodigoWinTrust, 8)]);
    efeOtroTitular:
      Result := Format(
        SFirmaEjecutableOtroTitular,
        [sFichero, AResultado.Titular]);
    efeNoEV:
      Result := Format(
        SFirmaEjecutableNoEV,
        [sFichero, AResultado.Titular]);
    efeNoComprobada:
      Result := Format(
        SFirmaEjecutableNoComprobada,
        [sFichero, AResultado.Detalle]);
  else
    Result := '';
  end;
end;

function TextoComprobacionFirma(
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable): string;
begin
  if AResultado.Correcta then
    Result := Format(SFirmaEjecutableCorrecta,
                     [ExtractFileName(ARuta), AResultado.Titular])
  else if (AResultado.Estado = efeSinFirma) and
          EsEjecutableDesarrollo(ARuta) then
    Result := Format(SFirmaEjecutableDesarrollo, [ExtractFileName(ARuta)])
  else
    Result := TextoFirmaEjecutable(ARuta, AResultado);
end;

function DebeAvisarFirma(
  const ARuta: string;
  const AResultado: TResultadoFirmaEjecutable): Boolean;
begin
  Result := not AResultado.Correcta and
    (AResultado.Estado <> efeNoComprobada) and
    not ((AResultado.Estado = efeSinFirma) and
         EsEjecutableDesarrollo(ARuta));
end;

type
  TBlobCripto = record
    cbData: DWORD;
    pbData: PByte;
  end;

  TIdentificadorAlgoritmo = record
    pszObjId: PAnsiChar;
    Parameters: TBlobCripto;
  end;

  TBlobBits = record
    cbData: DWORD;
    pbData: PByte;
    cUnusedBits: DWORD;
  end;

  TInfoClavePublica = record
    Algorithm: TIdentificadorAlgoritmo;
    PublicKey: TBlobBits;
  end;

  PExtensionCertificado = ^TExtensionCertificado;
  TExtensionCertificado = record
    pszObjId: PAnsiChar;
    fCritical: BOOL;
    Value: TBlobCripto;
  end;

  // CERT_INFO de wincrypt.h.
  PInfoCertificado = ^TInfoCertificado;
  TInfoCertificado = record
    dwVersion: DWORD;
    SerialNumber: TBlobCripto;
    SignatureAlgorithm: TIdentificadorAlgoritmo;
    Issuer: TBlobCripto;
    NotBefore: TFileTime;
    NotAfter: TFileTime;
    Subject: TBlobCripto;
    SubjectPublicKeyInfo: TInfoClavePublica;
    IssuerUniqueId: TBlobBits;
    SubjectUniqueId: TBlobBits;
    cExtension: DWORD;
    rgExtension: PExtensionCertificado;
  end;

  // CERT_CONTEXT.
  PContextoCertificado = ^TContextoCertificado;
  TContextoCertificado = record
    dwCertEncodingType: DWORD;
    pbCertEncoded: PByte;
    cbCertEncoded: DWORD;
    pCertInfo: PInfoCertificado;
    hCertStore: Pointer;
  end;

  // Principio de CMSG_SIGNER_INFO: lo único que hace falta para buscar el
  // certificado del firmante.
  PInfoFirmanteMensaje = ^TInfoFirmanteMensaje;
  TInfoFirmanteMensaje = record
    dwVersion: DWORD;
    Issuer: TBlobCripto;
    SerialNumber: TBlobCripto;
  end;

  PInfoPolitica = ^TInfoPolitica;
  TInfoPolitica = record
    pszPolicyIdentifier: PAnsiChar;
    cPolicyQualifier: DWORD;
    rgPolicyQualifier: Pointer;
  end;

  PInfoPoliticas = ^TInfoPoliticas;
  TInfoPoliticas = record
    cPolicyInfo: DWORD;
    rgPolicyInfo: PInfoPolitica;
  end;

  // WINTRUST_FILE_INFO de wintrust.h.
  PInfoFicheroWinTrust = ^TInfoFicheroWinTrust;
  TInfoFicheroWinTrust = record
    cbStruct: DWORD;
    pcwszFilePath: PWideChar;
    hFile: THandle;
    pgKnownSubject: PGUID;
  end;

  // WINTRUST_DATA. La unión de punteros se queda en pFile, que es el único
  // que se usa.
  PDatosWinTrust = ^TDatosWinTrust;
  TDatosWinTrust = record
    cbStruct: DWORD;
    pPolicyCallbackData: Pointer;
    pSIPClientData: Pointer;
    dwUIChoice: DWORD;
    fdwRevocationChecks: DWORD;
    dwUnionChoice: DWORD;
    pFile: PInfoFicheroWinTrust;
    dwStateAction: DWORD;
    hWVTStateData: THandle;
    pwszURLReference: PWideChar;
    dwProvFlags: DWORD;
    dwUIContext: DWORD;
    pSignatureSettings: Pointer;
  end;

const
  cCrypt32 = 'crypt32.dll';
  cWinTrust = 'wintrust.dll';
  // WINTRUST_ACTION_GENERIC_VERIFY_V2: comprobación Authenticode normal.
  cAccionVerificacionGenerica: TGUID =
    '{00AAC56B-CD44-11D0-8CC2-00C04FC295EE}';
  cObjetoConsultaFichero = 1;
  cContenidoPkcs7Incrustado = $400;
  cFormatoBinario = $2;
  cParametroInfoFirmante = 6;
  cCodificacion = $00010001; // X509_ASN_ENCODING or PKCS_7_ASN_ENCODING
  cBuscarCertificadoFirmante = $000B0000; // CERT_FIND_SUBJECT_CERT
  cNombrePorAtributo = 3; // CERT_NAME_ATTR_TYPE
  cOidNombreComun: AnsiString = '2.5.4.3';
  cOidOrganizacion: AnsiString = '2.5.4.10';
  cOidPoliticasCertificado: AnsiString = '2.5.29.32';
  cEstructuraPoliticas = 16; // X509_CERT_POLICIES
  cSinFirma = Integer($800B0100); // TRUST_E_NOSIGNATURE
  cEleccionFichero = 1; // WTD_CHOICE_FILE
  cSinInterfaz = 2; // WTD_UI_NONE
  cSinRevocacion = 0; // WTD_REVOKE_NONE
  cAccionVerificar = 1; // WTD_STATEACTION_VERIFY
  cAccionCerrar = 2; // WTD_STATEACTION_CLOSE
  // WTD_REVOCATION_CHECK_NONE or WTD_CACHE_ONLY_URL_RETRIEVAL: al arrancar
  // no se sale a la red.
  cOpcionesProveedor = $00000010 or $00001000;
  // build\reproducible\bin\Win64\Release (compilar.ps1) está a 6 niveles
  // de vcash.dproj.
  cNivelesDesarrollo = 8;
  cProyectoViraCash = 'vcash.dproj';

function CryptQueryObject(dwObjectType: DWORD; pvObject: Pointer;
  dwExpectedContentTypeFlags, dwExpectedFormatTypeFlags,
  dwFlags: DWORD; pdwMsgAndCertEncodingType, pdwContentType,
  pdwFormatType: PDWORD; phCertStore, phMsg: PPointer;
  ppvContext: PPointer): BOOL; stdcall; external cCrypt32;
function CryptMsgGetParam(hCryptMsg: Pointer; dwParamType,
  dwIndex: DWORD; pvData: Pointer; var pcbData: DWORD): BOOL; stdcall;
  external cCrypt32;
function CryptMsgClose(hCryptMsg: Pointer): BOOL; stdcall;
  external cCrypt32;
function CertCloseStore(hCertStore: Pointer; dwFlags: DWORD): BOOL;
  stdcall; external cCrypt32;
function CertFindCertificateInStore(hCertStore: Pointer;
  dwCertEncodingType, dwFindFlags, dwFindType: DWORD;
  pvFindPara: Pointer;
  pPrevCertContext: PContextoCertificado): PContextoCertificado;
  stdcall; external cCrypt32;
function CertFreeCertificateContext(
  pCertContext: PContextoCertificado): BOOL; stdcall; external cCrypt32;
function CertGetNameStringW(pCertContext: PContextoCertificado;
  dwType, dwFlags: DWORD; pvTypePara: Pointer; pszNameString: PWideChar;
  cchNameString: DWORD): DWORD; stdcall; external cCrypt32;
function CertFindExtension(pszObjId: PAnsiChar; cExtensions: DWORD;
  rgExtensions: PExtensionCertificado): PExtensionCertificado; stdcall;
  external cCrypt32;
function CryptDecodeObjectEx(dwCertEncodingType: DWORD;
  lpszStructType: PAnsiChar; pbEncoded: PByte; cbEncoded,
  dwFlags: DWORD; pDecodePara, pvStructInfo: Pointer;
  var pcbStructInfo: DWORD): BOOL; stdcall; external cCrypt32;
function WinVerifyTrust(hwnd: HWND; pgActionID: PGUID;
  pWVTData: Pointer): Integer; stdcall; external cWinTrust;

{ TResultadoFirmaEjecutable }

function TResultadoFirmaEjecutable.Correcta: Boolean;
begin
  Result := Estado = efePropia;
end;

// WinVerifyTrust: 0 si la firma vale, TRUST_E_NOSIGNATURE si no hay.
function VerificarConfianza(const ARuta: string): Integer;
var
  Datos: TDatosWinTrust;
  Fichero: TInfoFicheroWinTrust;
begin
  ZeroMemory(@Fichero, SizeOf(Fichero));
  Fichero.cbStruct := SizeOf(Fichero);
  Fichero.pcwszFilePath := PChar(ARuta);
  ZeroMemory(@Datos, SizeOf(Datos));
  Datos.cbStruct := SizeOf(Datos);
  Datos.dwUIChoice := cSinInterfaz;
  Datos.fdwRevocationChecks := cSinRevocacion;
  Datos.dwUnionChoice := cEleccionFichero;
  Datos.pFile := @Fichero;
  Datos.dwStateAction := cAccionVerificar;
  Datos.dwProvFlags := cOpcionesProveedor;
  Result := WinVerifyTrust(0, @cAccionVerificacionGenerica, @Datos);
  Datos.dwStateAction := cAccionCerrar;
  WinVerifyTrust(0, @cAccionVerificacionGenerica, @Datos);
end;

function NombreCertificado(
  ACertificado: PContextoCertificado;
  const AOid: AnsiString): string;
var
  iLongitud: DWORD;
begin
  Result := '';
  iLongitud := CertGetNameStringW(ACertificado, cNombrePorAtributo, 0,
    PAnsiChar(AOid), nil, 0);
  if iLongitud > 1 then
  begin
    SetLength(Result, iLongitud - 1);
    CertGetNameStringW(ACertificado, cNombrePorAtributo, 0,
      PAnsiChar(AOid), PWideChar(Result), iLongitud);
  end;
end;

function TienePoliticaEV(ACertificado: PContextoCertificado): Boolean;
var
  aDatos: TBytes;
  iIndice: Integer;
  iLongitud: DWORD;
  pExtension: PExtensionCertificado;
  pPolitica: PInfoPolitica;
  pPoliticas: PInfoPoliticas;
begin
  Result := False;
  pExtension := CertFindExtension(
    PAnsiChar(cOidPoliticasCertificado),
    ACertificado^.pCertInfo^.cExtension,
    ACertificado^.pCertInfo^.rgExtension);
  iLongitud := 0;
  if Assigned(pExtension) and
     CryptDecodeObjectEx(cCodificacion, PAnsiChar(cEstructuraPoliticas),
       pExtension^.Value.pbData, pExtension^.Value.cbData, 0, nil, nil,
       iLongitud) then
  begin
    SetLength(aDatos, iLongitud);
    if CryptDecodeObjectEx(cCodificacion, PAnsiChar(cEstructuraPoliticas),
         pExtension^.Value.pbData, pExtension^.Value.cbData, 0, nil,
         @aDatos[0], iLongitud) then
    begin
      pPoliticas := PInfoPoliticas(@aDatos[0]);
      pPolitica := pPoliticas^.rgPolicyInfo;
      for iIndice := 1 to Integer(pPoliticas^.cPolicyInfo) do
      begin
        if string(AnsiString(pPolitica^.pszPolicyIdentifier)) =
           cOidPoliticaFirmaCodigoEV then
          Result := True;
        Inc(pPolitica);
      end;
    end;
  end;
end;

// Certificado del firmante, sacado de la firma incrustada en el fichero.
// Quien lo recibe lo libera con CertFreeCertificateContext.
function CertificadoFirmante(
  const ARuta: string;
  out AAlmacen, AMensaje: Pointer): PContextoCertificado;
var
  aFirmante: TBytes;
  iCodificacion, iContenido, iFormato, iLongitud: DWORD;
  Info: TInfoCertificado;
begin
  AAlmacen := nil;
  AMensaje := nil;
  if not CryptQueryObject(cObjetoConsultaFichero, PChar(ARuta),
       cContenidoPkcs7Incrustado, cFormatoBinario, 0, @iCodificacion,
       @iContenido, @iFormato, @AAlmacen, @AMensaje, nil) then
    RaiseLastOSError;
  iLongitud := 0;
  if not CryptMsgGetParam(AMensaje, cParametroInfoFirmante, 0, nil,
       iLongitud) then
    RaiseLastOSError;
  SetLength(aFirmante, iLongitud);
  if not CryptMsgGetParam(AMensaje, cParametroInfoFirmante, 0,
       @aFirmante[0], iLongitud) then
    RaiseLastOSError;
  ZeroMemory(@Info, SizeOf(Info));
  Info.Issuer := PInfoFirmanteMensaje(@aFirmante[0])^.Issuer;
  Info.SerialNumber := PInfoFirmanteMensaje(@aFirmante[0])^.SerialNumber;
  Result := CertFindCertificateInStore(AAlmacen, cCodificacion, 0,
    cBuscarCertificadoFirmante, @Info, nil);
  if not Assigned(Result) then
    RaiseLastOSError;
end;

procedure LeerTitular(
  const ARuta: string;
  var AResultado: TResultadoFirmaEjecutable);
var
  Certificado: PContextoCertificado;
  pAlmacen: Pointer;
  pMensaje: Pointer;
begin
  Certificado := nil;
  pAlmacen := nil;
  pMensaje := nil;
  try
    Certificado := CertificadoFirmante(ARuta, pAlmacen, pMensaje);
    AResultado.Titular := NombreCertificado(Certificado, cOidNombreComun);
    AResultado.Organizacion := NombreCertificado(
      Certificado,
      cOidOrganizacion);
    if not SameText(AResultado.Titular, cTitularFirmaViraCash) or
       not SameText(AResultado.Organizacion, cTitularFirmaViraCash) then
      AResultado.Estado := efeOtroTitular
    else if not TienePoliticaEV(Certificado) then
      AResultado.Estado := efeNoEV
    else
      AResultado.Estado := efePropia;
  finally
    if Assigned(Certificado) then
      CertFreeCertificateContext(Certificado);
    if Assigned(pMensaje) then
      CryptMsgClose(pMensaje);
    if Assigned(pAlmacen) then
      CertCloseStore(pAlmacen, 0);
  end;
end;

function ComprobarFirmaEjecutable(
  const ARuta: string): TResultadoFirmaEjecutable;
begin
  Result := Default(TResultadoFirmaEjecutable);
  try
    Result.CodigoWinTrust := VerificarConfianza(ARuta);
    if Result.CodigoWinTrust = cSinFirma then
      Result.Estado := efeSinFirma
    else if Result.CodigoWinTrust <> 0 then
      Result.Estado := efeNoValida
    else
      LeerTitular(ARuta, Result);
  except
    on E: Exception do
    begin
      Result.Estado := efeNoComprobada;
      Result.Detalle := E.Message;
    end;
  end;
end;

function EsEjecutableDesarrollo(const ARuta: string): Boolean;
var
  iNivel: Integer;
  sCarpeta: string;
begin
  Result := False;
  sCarpeta := ExtractFileDir(ExpandFileName(ARuta));
  iNivel := 0;
  while not Result and (sCarpeta <> '') and (iNivel < cNivelesDesarrollo) do
  begin
    Result := TFile.Exists(TPath.Combine(sCarpeta, cProyectoViraCash));
    if SameText(ExtractFileDir(sCarpeta), sCarpeta) then
      sCarpeta := ''
    else
      sCarpeta := ExtractFileDir(sCarpeta);
    Inc(iNivel);
  end;
end;

end.
