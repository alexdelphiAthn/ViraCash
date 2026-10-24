{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerificacionNifRoi                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verificación del NIF-IVA de un operador intracomunitario (ROI) en VIES,   }
{    el censo de la Comisión Europea que reúne los registros de operadores     }
{    intracomunitarios de cada Estado. Servicio SOAP checkVat, público y sin   }
{    certificado. Sólo para facturas intracomunitarias.                        }
{******************************************************************************}
unit inLibVerificacionNifRoi;

interface

const
  cUrlVerificacionNifRoi =
    'https://ec.europa.eu/taxation_customs/vies/services/checkVatService';

type
  // NoDisponible: VIES o el registro del Estado no han respondido; no
  // dice nada del NIF.
  TEstadoVerificacionRoi = (
    evrValido,
    evrNoValido,
    evrNoDisponible);

  TResultadoVerificacionRoi = record
    CodigoPais: string;
    NumeroIva: string;
    // VIES devuelve '---' cuando el Estado no publica estos datos.
    Nombre: string;
    Direccion: string;
    Estado: TEstadoVerificacionRoi;
    // Error de VIES (MS_UNAVAILABLE, INVALID_INPUT...) o de red.
    Detalle: string;
  end;

  // Lanza el transporte HTTP; las pruebas lo sustituyen.
  TEnvioVerificacionRoi = reference to function(
    const AUrl, APeticion: string;
    out AStatus: Integer): string;

// Separa el prefijo de país del NIF-IVA. Si el NIF no lo lleva se usa
// APaisIso2 (país del cliente; GR se convierte en EL). Lanza
// EVerificacionNif si el NIF está vacío o el país no es de la UE.
procedure SepararNifIvaRoi(
  const ANif, APaisIso2: string;
  out APais, ANumero: string);
function ConstruirPeticionVerificacionRoi(
  const APais, ANumero: string): string;
function InterpretarRespuestaVerificacionRoi(
  const AXml: string;
  AStatus: Integer;
  const APais, ANumero: string): TResultadoVerificacionRoi;
// Texto que se guarda en el cliente (RESULTADO_VERIFICACION_NIF_CLI).
function TextoResultadoVerificacionRoi(
  const AResultado: TResultadoVerificacionRoi): string;
// Un error de red no lanza: vuelve como evrNoDisponible.
function VerificarNifRoi(
  const ANif, APaisIso2, AUrl: string;
  const AEnvio: TEnvioVerificacionRoi = nil): TResultadoVerificacionRoi;

implementation

uses
  System.SysUtils, System.StrUtils, System.Classes,
  System.Net.HttpClient, System.Net.URLClient, System.NetConsts,
  inLibVerificacionNifIntf, inLibVerificacionNif, inLibMsgVerificacionNif;

const
  cNsSoap = 'http://schemas.xmlsoap.org/soap/envelope/';
  cNsVies = 'urn:ec.europa.eu:taxud:vies:services:checkVat:types';
  // Prefijos de VIES: Grecia es EL; XI = Irlanda del Norte.
  cPaisesVies: array[0..27] of string = (
    'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'EL', 'ES',
    'FI', 'FR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT',
    'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK', 'XI');
  cFaultEntradaNoValida = 'INVALID_INPUT';
  cTimeoutConexionMs = 10000;
  cTimeoutRespuestaMs = 30000;

function EsPaisVies(const APais: string): Boolean;
begin
  Result := MatchStr(APais, cPaisesVies);
end;

function PaisVies(const APaisIso2: string): string;
begin
  Result := UpperCase(Trim(APaisIso2));
  if Result = 'GR' then
    Result := 'EL';
end;

function SoloLetrasYDigitos(const AValor: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(AValor) do
    if CharInSet(UpCase(AValor[i]), ['A'..'Z', '0'..'9']) then
      Result := Result + UpCase(AValor[i]);
end;

procedure SepararNifIvaRoi(
  const ANif, APaisIso2: string;
  out APais, ANumero: string);
var
  sNif: string;
  sPrefijo: string;
begin
  sNif := SoloLetrasYDigitos(ANif);
  if sNif = '' then
    raise EVerificacionNif.Create(SErrorVerificacionNifVacio);
  sPrefijo := PaisVies(Copy(sNif, 1, 2));
  if (Length(sNif) > 2) and EsPaisVies(sPrefijo) then
  begin
    APais := sPrefijo;
    ANumero := Copy(sNif, 3, MaxInt);
  end
  else
  begin
    APais := PaisVies(APaisIso2);
    ANumero := sNif;
  end;
  if not EsPaisVies(APais) then
    raise EVerificacionNif.CreateFmt(SErrorVerificacionRoiPaisNoUE,
      [Trim(APaisIso2)]);
end;

function ConstruirPeticionVerificacionRoi(
  const APais, ANumero: string): string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<soapenv:Envelope xmlns:soapenv="' + cNsSoap + '" ' +
    'xmlns:urn="' + cNsVies + '">' +
    '<soapenv:Header/>' +
    '<soapenv:Body>' +
    '<urn:checkVat>' +
    '<urn:countryCode>' + EscaparXmlVerificacion(APais) +
    '</urn:countryCode>' +
    '<urn:vatNumber>' + EscaparXmlVerificacion(ANumero) +
    '</urn:vatNumber>' +
    '</urn:checkVat>' +
    '</soapenv:Body>' +
    '</soapenv:Envelope>';
end;

function InterpretarRespuestaVerificacionRoi(
  const AXml: string;
  AStatus: Integer;
  const APais, ANumero: string): TResultadoVerificacionRoi;
var
  sValido: string;
  sFault: string;
begin
  Result := Default(TResultadoVerificacionRoi);
  Result.CodigoPais := APais;
  Result.NumeroIva := ANumero;
  sValido := LowerCase(ValorEtiquetaXmlVerificacion(AXml, 'valid'));
  sFault := UpperCase(ValorEtiquetaXmlVerificacion(AXml, 'faultstring'));
  if sValido = 'true' then
  begin
    Result.Estado := evrValido;
    Result.Nombre := ValorEtiquetaXmlVerificacion(AXml, 'name');
    Result.Direccion := ValorEtiquetaXmlVerificacion(AXml, 'address');
  end
  else if sValido = 'false' then
    Result.Estado := evrNoValido
  // Formato que el Estado no admite: el número no puede ser válido.
  else if sFault = cFaultEntradaNoValida then
  begin
    Result.Estado := evrNoValido;
    Result.Detalle := sFault;
  end
  else
  begin
    Result.Estado := evrNoDisponible;
    Result.Detalle := sFault;
    if Result.Detalle = '' then
      Result.Detalle := Format('HTTP %d', [AStatus]);
  end;
end;

function TextoResultadoVerificacionRoi(
  const AResultado: TResultadoVerificacionRoi): string;
begin
  case AResultado.Estado of
    evrValido:
      Result := 'ROI VALIDO ' + AResultado.CodigoPais +
        AResultado.NumeroIva;
    evrNoValido:
      Result := 'ROI NO VALIDO ' + AResultado.CodigoPais +
        AResultado.NumeroIva;
  else
    Result := '';
  end;
end;

function EnviarVerificacionRoiHttp(
  const AUrl, APeticion: string;
  out AStatus: Integer): string;
var
  oHttp: THTTPClient;
  oCuerpo: TStringStream;
  oRespuesta: IHTTPResponse;
begin
  oHttp := THTTPClient.Create;
  oCuerpo := TStringStream.Create(APeticion, TEncoding.UTF8);
  try
    oHttp.ConnectionTimeout := cTimeoutConexionMs;
    oHttp.ResponseTimeout := cTimeoutRespuestaMs;
    oHttp.ContentType := 'text/xml; charset=utf-8';
    oRespuesta := oHttp.Post(AUrl, oCuerpo, nil,
      [TNetHeader.Create('SOAPAction', '""')]);
    AStatus := oRespuesta.StatusCode;
    Result := oRespuesta.ContentAsString(TEncoding.UTF8);
  finally
    FreeAndNil(oCuerpo);
    FreeAndNil(oHttp);
  end;
end;

function VerificarNifRoi(
  const ANif, APaisIso2, AUrl: string;
  const AEnvio: TEnvioVerificacionRoi): TResultadoVerificacionRoi;
var
  sPais: string;
  sNumero: string;
  sUrl: string;
  sRespuesta: string;
  iStatus: Integer;
  Envio: TEnvioVerificacionRoi;
begin
  SepararNifIvaRoi(ANif, APaisIso2, sPais, sNumero);
  sUrl := Trim(AUrl);
  if sUrl = '' then
    sUrl := cUrlVerificacionNifRoi;
  Envio := AEnvio;
  if not Assigned(Envio) then
    Envio := EnviarVerificacionRoiHttp;
  try
    sRespuesta := Envio(sUrl,
      ConstruirPeticionVerificacionRoi(sPais, sNumero), iStatus);
    Result := InterpretarRespuestaVerificacionRoi(
      sRespuesta, iStatus, sPais, sNumero);
  except
    // Sin red o sin respuesta: el usuario decide si sigue.
    on E: ENetException do
    begin
      Result := Default(TResultadoVerificacionRoi);
      Result.CodigoPais := sPais;
      Result.NumeroIva := sNumero;
      Result.Estado := evrNoDisponible;
      Result.Detalle := E.Message;
    end;
  end;
end;

end.
