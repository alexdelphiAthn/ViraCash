{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerificacionXadesNoVerifactu                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Valida el perfil XAdES exigido en exportaciones NO VERI*FACTU.            }
{******************************************************************************}
unit inLibVerificacionXadesNoVerifactu;

interface

uses
  System.SysUtils;

type
  TCausaRechazoXadesNoVerifactu = (
    crxXmlNoLegible,
    crxRaizEventoIncorrecta,
    crxEventoFirmadoAusente,
    crxRaizFacturaIncorrecta,
    crxFirmaAusente,
    crxCertificadoAusente,
    crxSignedInfoAusente,
    crxCanonicalizacionFirmaIncorrecta,
    crxMetodoFirmaIncorrecto,
    crxNumeroReferenciasIncorrecto,
    crxReferenciaDocumentoAusente,
    crxTransformacionEnvelopedAusente,
    crxDigestDocumentoIncorrecto,
    crxReferenciaPropiedadesAusente,
    crxCanonicalizacionPropiedadesIncorrecta,
    crxDigestPropiedadesIncorrecto,
    crxQualifyingPropertiesAusente,
    crxSignedPropertiesAusente,
    crxSigningCertificateAusente,
    crxPoliticaFirmaAusente,
    crxIdentificadorPoliticaIncorrecto,
    crxDigestPoliticaIncorrecto,
    crxValorDigestPoliticaIncorrecto,
    crxUrlPoliticaIncorrecta
  );

  TResultadoPerfilXadesNoVerifactu = record
    Causas: TArray<TCausaRechazoXadesNoVerifactu>;
    function EsValido: Boolean;
    function Contiene(
      ACausa: TCausaRechazoXadesNoVerifactu): Boolean;
  end;

function VerificarPerfilXadesNoVerifactu(
  const AXml: string;
  AEsEvento: Boolean): TResultadoPerfilXadesNoVerifactu;
function MensajeRechazoXadesNoVerifactu(
  ACausa: TCausaRechazoXadesNoVerifactu;
  const AEtiqueta: string): string;

implementation

uses
  Xml.XMLDoc, Xml.XMLIntf, Xml.Win.msxmldom,
  inLibMsgFacturas,
  inLibMsgVerifactu;

const
  cAlgC14n = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
  cAlgEnveloped =
    'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
  cAlgRsaSha256 =
    'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
  cAlgSha1 = 'http://www.w3.org/2000/09/xmldsig#sha1';
  cAlgSha256 = 'http://www.w3.org/2001/04/xmlenc#sha256';
  cTipoSignedProperties = 'http://uri.etsi.org/01903#SignedProperties';
  cPoliticaAeatId = 'urn:oid:2.16.724.1.3.1.1.2.1.9';
  cPoliticaAeatUrl =
    'https://sede.administracion.gob.es/politica_de_firma_anexo_1.pdf';
  cPoliticaAeatHashSha1 = 'G7roucf600+f03r/o0bAOQ6WAs0=';

function TResultadoPerfilXadesNoVerifactu.EsValido: Boolean;
begin
  Result := Length(Causas) = 0;
end;

function TResultadoPerfilXadesNoVerifactu.Contiene(
  ACausa: TCausaRechazoXadesNoVerifactu): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := 0;
  while (not Result) and (i < Length(Causas)) do
  begin
    Result := Causas[i] = ACausa;
    Inc(i);
  end;
end;

procedure AgregarCausa(
  var AResultado: TResultadoPerfilXadesNoVerifactu;
  ACausa: TCausaRechazoXadesNoVerifactu);
var
  iCantidad: Integer;
begin
  iCantidad := Length(AResultado.Causas);
  SetLength(AResultado.Causas, iCantidad + 1);
  AResultado.Causas[iCantidad] := ACausa;
end;

function NombreLocal(const ANodeName: string): string;
var
  iPosicion: Integer;
begin
  Result := ANodeName;
  iPosicion := Pos(':', Result);
  if iPosicion > 0 then
    Result := Copy(Result, iPosicion + 1, MaxInt);
end;

function EsNodo(const ANode: IXMLNode;
  const ANombreLocal: string): Boolean;
begin
  Result := (ANode <> nil) and
    SameText(NombreLocal(ANode.NodeName), ANombreLocal);
end;

function BuscarHijo(const ANode: IXMLNode;
  const ANombreLocal: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) then
        Result := oHijo;
      Inc(i);
    end;
  end;
end;

function BuscarDescendiente(const ANode: IXMLNode;
  const ANombreLocal: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) then
        Result := oHijo
      else
        Result := BuscarDescendiente(oHijo, ANombreLocal);
      Inc(i);
    end;
  end;
end;

function AtributoNodo(const ANode: IXMLNode;
  const ANombre: string): string;
var
  oAtributo: IXMLNode;
begin
  Result := '';
  if ANode <> nil then
  begin
    oAtributo := ANode.AttributeNodes.FindNode(ANombre);
    if oAtributo <> nil then
      Result := Trim(oAtributo.Text);
  end;
end;

function BuscarHijoConAtributo(const ANode: IXMLNode;
  const ANombreLocal, AAtributo, AValor: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) and
         SameText(AtributoNodo(oHijo, AAtributo), AValor) then
        Result := oHijo;
      Inc(i);
    end;
  end;
end;

function BuscarDescendienteConAtributo(const ANode: IXMLNode;
  const ANombreLocal, AAtributo, AValor: string): IXMLNode;
var
  i: Integer;
  oHijo: IXMLNode;
begin
  Result := nil;
  if ANode <> nil then
  begin
    i := 0;
    while (Result = nil) and (i < ANode.ChildNodes.Count) do
    begin
      oHijo := ANode.ChildNodes[i];
      if EsNodo(oHijo, ANombreLocal) and
         SameText(AtributoNodo(oHijo, AAtributo), AValor) then
        Result := oHijo
      else
        Result := BuscarDescendienteConAtributo(oHijo, ANombreLocal,
          AAtributo, AValor);
      Inc(i);
    end;
  end;
end;

function BuscarRuta(const ANode: IXMLNode;
  const ANombres: array of string): IXMLNode;
var
  i: Integer;
begin
  Result := ANode;
  i := Low(ANombres);
  while (Result <> nil) and (i <= High(ANombres)) do
  begin
    Result := BuscarHijo(Result, ANombres[i]);
    Inc(i);
  end;
end;

function TextoRuta(const ANode: IXMLNode;
  const ANombres: array of string): string;
var
  oNodo: IXMLNode;
begin
  Result := '';
  oNodo := BuscarRuta(ANode, ANombres);
  if oNodo <> nil then
    Result := Trim(oNodo.Text);
end;

function ContarHijos(const ANode: IXMLNode;
  const ANombreLocal: string): Integer;
var
  i: Integer;
begin
  Result := 0;
  if ANode <> nil then
  begin
    for i := 0 to ANode.ChildNodes.Count - 1 do
      if EsNodo(ANode.ChildNodes[i], ANombreLocal) then
        Inc(Result);
  end;
end;

function CargarXml(const AXml: string;
  out ADocumento: IXMLDocument): Boolean;
begin
  Result := False;
  ADocumento := nil;
  if Trim(AXml) <> '' then
  begin
    try
      ADocumento := TXMLDocument.Create(nil);
      ADocumento.LoadFromXML(AXml);
      ADocumento.Active := True;
      Result := ADocumento.DocumentElement <> nil;
    except
      ADocumento := nil;
    end;
  end;
end;

function ObtenerNodoFirmado(const ARaiz: IXMLNode;
  AEsEvento: Boolean;
  var AResultado: TResultadoPerfilXadesNoVerifactu): IXMLNode;
var
  sRaiz: string;
begin
  Result := ARaiz;
  sRaiz := NombreLocal(ARaiz.NodeName);
  if AEsEvento then
  begin
    if not SameText(sRaiz, 'RegistroEvento') then
      AgregarCausa(AResultado, crxRaizEventoIncorrecta);
    Result := BuscarHijo(ARaiz, 'Evento');
    if Result = nil then
      AgregarCausa(AResultado, crxEventoFirmadoAusente);
  end
  else if (not SameText(sRaiz, 'RegistroAlta')) and
          (not SameText(sRaiz, 'RegistroAnulacion')) then
    AgregarCausa(AResultado, crxRaizFacturaIncorrecta);
end;

procedure ValidarReferenciaDocumento(const ASignedInfo: IXMLNode;
  var AResultado: TResultadoPerfilXadesNoVerifactu);
var
  oDigest: IXMLNode;
  oReferencia: IXMLNode;
begin
  oReferencia := BuscarHijoConAtributo(ASignedInfo, 'Reference', 'URI', '');
  if oReferencia = nil then
    AgregarCausa(AResultado, crxReferenciaDocumentoAusente)
  else
  begin
    if BuscarDescendienteConAtributo(oReferencia, 'Transform',
       'Algorithm', cAlgEnveloped) = nil then
      AgregarCausa(AResultado, crxTransformacionEnvelopedAusente);
    oDigest := BuscarDescendiente(oReferencia, 'DigestMethod');
    if AtributoNodo(oDigest, 'Algorithm') <> cAlgSha256 then
      AgregarCausa(AResultado, crxDigestDocumentoIncorrecto);
  end;
end;

procedure ValidarReferenciaPropiedades(const ASignedInfo: IXMLNode;
  var AResultado: TResultadoPerfilXadesNoVerifactu);
var
  oDigest: IXMLNode;
  oReferencia: IXMLNode;
begin
  oReferencia := BuscarHijoConAtributo(ASignedInfo, 'Reference', 'Type',
    cTipoSignedProperties);
  if oReferencia = nil then
    AgregarCausa(AResultado, crxReferenciaPropiedadesAusente)
  else
  begin
    if BuscarDescendienteConAtributo(oReferencia, 'Transform',
       'Algorithm', cAlgC14n) = nil then
      AgregarCausa(AResultado, crxCanonicalizacionPropiedadesIncorrecta);
    oDigest := BuscarDescendiente(oReferencia, 'DigestMethod');
    if AtributoNodo(oDigest, 'Algorithm') <> cAlgSha256 then
      AgregarCausa(AResultado, crxDigestPropiedadesIncorrecto);
  end;
end;

procedure ValidarSignedInfo(const AFirma: IXMLNode;
  var AResultado: TResultadoPerfilXadesNoVerifactu);
var
  oMetodo: IXMLNode;
  oSignedInfo: IXMLNode;
begin
  oSignedInfo := BuscarHijo(AFirma, 'SignedInfo');
  if oSignedInfo = nil then
    AgregarCausa(AResultado, crxSignedInfoAusente)
  else
  begin
    oMetodo := BuscarHijo(oSignedInfo, 'CanonicalizationMethod');
    if AtributoNodo(oMetodo, 'Algorithm') <> cAlgC14n then
      AgregarCausa(AResultado, crxCanonicalizacionFirmaIncorrecta);
    oMetodo := BuscarHijo(oSignedInfo, 'SignatureMethod');
    if AtributoNodo(oMetodo, 'Algorithm') <> cAlgRsaSha256 then
      AgregarCausa(AResultado, crxMetodoFirmaIncorrecto);
    if ContarHijos(oSignedInfo, 'Reference') <> 2 then
      AgregarCausa(AResultado, crxNumeroReferenciasIncorrecto);
    ValidarReferenciaDocumento(oSignedInfo, AResultado);
    ValidarReferenciaPropiedades(oSignedInfo, AResultado);
  end;
end;

procedure ValidarPolitica(const APropiedades: IXMLNode;
  var AResultado: TResultadoPerfilXadesNoVerifactu);
var
  oDigest: IXMLNode;
  oPolitica: IXMLNode;
begin
  oPolitica := BuscarRuta(APropiedades,
    ['SignedProperties', 'SignedSignatureProperties',
     'SignaturePolicyIdentifier', 'SignaturePolicyId']);
  if oPolitica = nil then
    AgregarCausa(AResultado, crxPoliticaFirmaAusente)
  else
  begin
    if TextoRuta(oPolitica, ['SigPolicyId', 'Identifier']) <>
       cPoliticaAeatId then
      AgregarCausa(AResultado, crxIdentificadorPoliticaIncorrecto);
    oDigest := BuscarRuta(oPolitica, ['SigPolicyHash', 'DigestMethod']);
    if AtributoNodo(oDigest, 'Algorithm') <> cAlgSha1 then
      AgregarCausa(AResultado, crxDigestPoliticaIncorrecto);
    if TextoRuta(oPolitica, ['SigPolicyHash', 'DigestValue']) <>
       cPoliticaAeatHashSha1 then
      AgregarCausa(AResultado, crxValorDigestPoliticaIncorrecto);
    if TextoRuta(oPolitica, ['SigPolicyQualifiers',
       'SigPolicyQualifier', 'SPURI']) <> cPoliticaAeatUrl then
      AgregarCausa(AResultado, crxUrlPoliticaIncorrecta);
  end;
end;

procedure ValidarPropiedades(const AFirma: IXMLNode;
  var AResultado: TResultadoPerfilXadesNoVerifactu);
var
  oPropiedades: IXMLNode;
begin
  oPropiedades := BuscarDescendiente(AFirma, 'QualifyingProperties');
  if oPropiedades = nil then
    AgregarCausa(AResultado, crxQualifyingPropertiesAusente)
  else
  begin
    if BuscarDescendiente(oPropiedades, 'SignedProperties') = nil then
      AgregarCausa(AResultado, crxSignedPropertiesAusente);
    if BuscarDescendiente(oPropiedades, 'SigningCertificate') = nil then
      AgregarCausa(AResultado, crxSigningCertificateAusente);
    ValidarPolitica(oPropiedades, AResultado);
  end;
end;

procedure ValidarFirma(const AFirma: IXMLNode;
  var AResultado: TResultadoPerfilXadesNoVerifactu);
begin
  if AFirma = nil then
    AgregarCausa(AResultado, crxFirmaAusente)
  else
  begin
    if BuscarDescendiente(AFirma, 'X509Certificate') = nil then
      AgregarCausa(AResultado, crxCertificadoAusente);
    ValidarSignedInfo(AFirma, AResultado);
    ValidarPropiedades(AFirma, AResultado);
  end;
end;

function VerificarPerfilXadesNoVerifactu(const AXml: string;
  AEsEvento: Boolean): TResultadoPerfilXadesNoVerifactu;
var
  oDocumento: IXMLDocument;
  oFirma: IXMLNode;
  oNodoFirmado: IXMLNode;
begin
  Result := Default(TResultadoPerfilXadesNoVerifactu);
  if not CargarXml(AXml, oDocumento) then
    AgregarCausa(Result, crxXmlNoLegible)
  else
  begin
    oNodoFirmado := ObtenerNodoFirmado(oDocumento.DocumentElement,
      AEsEvento, Result);
    oFirma := BuscarHijo(oNodoFirmado, 'Signature');
    ValidarFirma(oFirma, Result);
  end;
end;

function MensajeEstructuraXades(
  ACausa: TCausaRechazoXadesNoVerifactu;
  const AEtiqueta: string): string;
begin
  Result := '';
  case ACausa of
    crxXmlNoLegible:
      Result := Format(SErrorXmlFirmadoNoLegible, [AEtiqueta]);
    crxRaizEventoIncorrecta:
      Result := Format(SErrorFirmaEventoRaizIncorrecta, [AEtiqueta]);
    crxEventoFirmadoAusente:
      Result := Format(SErrorEventoFirmadoNoEncontrado, [AEtiqueta]);
    crxRaizFacturaIncorrecta:
      Result := Format(SErrorFirmaFacturaRaizIncorrecta, [AEtiqueta]);
    crxFirmaAusente:
      Result := Format(SErrorFirmaXadesNodoAeatIncorrecto, [AEtiqueta]);
    crxCertificadoAusente:
      Result := Format(SErrorFirmaXadesSinCertificado, [AEtiqueta]);
    crxSignedInfoAusente:
      Result := Format(SErrorFirmaXadesSinSignedInfo, [AEtiqueta]);
  end;
end;

function MensajeSignedInfoXades(
  ACausa: TCausaRechazoXadesNoVerifactu;
  const AEtiqueta: string): string;
begin
  Result := '';
  case ACausa of
    crxCanonicalizacionFirmaIncorrecta:
      Result := Format(SErrorCanonicalizacionFirmaAeat, [AEtiqueta]);
    crxMetodoFirmaIncorrecto:
      Result := Format(SErrorMetodoFirmaNoRsaSha256, [AEtiqueta]);
    crxNumeroReferenciasIncorrecto:
      Result := Format(SErrorReferenciasSignedInfo, [AEtiqueta]);
    crxReferenciaDocumentoAusente:
      Result := Format(SErrorReferenciaDocumentoFirmado, [AEtiqueta]);
    crxTransformacionEnvelopedAusente:
      Result := Format(SErrorTransformacionFirmaEnveloped, [AEtiqueta]);
    crxDigestDocumentoIncorrecto:
      Result := Format(SErrorDigestRegistroNoSha256, [AEtiqueta]);
    crxReferenciaPropiedadesAusente:
      Result := Format(SErrorReferenciaSignedProperties, [AEtiqueta]);
  end;
end;

function MensajePropiedadesXades(
  ACausa: TCausaRechazoXadesNoVerifactu;
  const AEtiqueta: string): string;
begin
  Result := '';
  case ACausa of
    crxCanonicalizacionPropiedadesIncorrecta:
      Result := Format(SErrorCanonicalizacionSignedProperties,
        [AEtiqueta]);
    crxDigestPropiedadesIncorrecto:
      Result := Format(SErrorDigestSignedPropertiesNoSha256,
        [AEtiqueta]);
    crxQualifyingPropertiesAusente:
      Result := Format(SErrorQualifyingPropertiesXades, [AEtiqueta]);
    crxSignedPropertiesAusente:
      Result := Format(SErrorSignedPropertiesXades, [AEtiqueta]);
    crxSigningCertificateAusente:
      Result := Format(SErrorSigningCertificateXades, [AEtiqueta]);
    crxPoliticaFirmaAusente:
      Result := Format(SErrorPoliticaFirmaAge, [AEtiqueta]);
  end;
end;

function MensajePoliticaXades(
  ACausa: TCausaRechazoXadesNoVerifactu;
  const AEtiqueta: string): string;
begin
  Result := '';
  case ACausa of
    crxIdentificadorPoliticaIncorrecto:
      Result := Format(SErrorIdentificadorPoliticaAge, [AEtiqueta]);
    crxDigestPoliticaIncorrecto:
      Result := Format(SErrorDigestPoliticaAgeNoSha1, [AEtiqueta]);
    crxValorDigestPoliticaIncorrecto:
      Result := Format(SErrorDigestValuePoliticaAge, [AEtiqueta]);
    crxUrlPoliticaIncorrecta:
      Result := Format(SErrorUrlPoliticaAge, [AEtiqueta]);
  end;
end;

function MensajeRechazoXadesNoVerifactu(
  ACausa: TCausaRechazoXadesNoVerifactu;
  const AEtiqueta: string): string;
begin
  Result := MensajeEstructuraXades(ACausa, AEtiqueta);
  if Result = '' then
    Result := MensajeSignedInfoXades(ACausa, AEtiqueta);
  if Result = '' then
    Result := MensajePropiedadesXades(ACausa, AEtiqueta);
  if Result = '' then
    Result := MensajePoliticaXades(ACausa, AEtiqueta);
end;

end.
