{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerificacionNif                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Verificación de NIF en la AEAT (VNifV2): petición SOAP, lectura de la     }
{    respuesta y evaluación del resultado. Sin UI ni SQL: el certificado, el   }
{    guardado y el transporte entran por los contratos de                      }
{    inLibVerificacionNifIntf. FZ-ISSUE-131.                                   }
{******************************************************************************}
unit inLibVerificacionNif;

interface

uses
  inLibVerificacionNifIntf;

// También los usa la consulta VIES (inLibVerificacionNifRoi).
function EscaparXmlVerificacion(const AValor: string): string;
// Contenido de la primera etiqueta con ese nombre local, con o sin
// prefijo de espacio de nombres.
function ValorEtiquetaXmlVerificacion(
  const AXml, ANombreLocal: string): string;
// Mayúsculas sin espacios, guiones ni puntos y sin el prefijo ES.
function NormalizarNifVerificacion(const ANif: string): string;
// Letras de sociedad (A, B, C...): la AEAT devuelve la razón social
// oficial. En personas físicas el nombre es un eco del enviado.
function EsNifPersonaJuridica(const ANif: string): Boolean;
function ConstruirPeticionVerificacionNif(
  const ANif, ANombre: string): string;
// Lanza EVerificacionNif si la respuesta no trae ningún contribuyente.
function InterpretarRespuestaVerificacionNif(
  const AXml, ANifEnviado, ANombreEnviado: string
): TResultadoVerificacionNif;
// Texto que se guarda en el cliente; señala el NIF que casó la AEAT.
function TextoResultadoVerificacionNif(
  const AResultado: TResultadoVerificacionNif): string;
function CrearServicioVerificacionNif(
  const ARepositorio: IRepositorioVerificacionNif;
  const ATransporte: ITransporteVerificacionNif): IServicioVerificacionNif;

implementation

uses
  System.SysUtils, System.StrUtils, System.RegularExpressions,
  inLibMsgVerificacionNif;

const
  cNsSoap = 'http://schemas.xmlsoap.org/soap/envelope/';
  cNsEntrada = 'http://www2.agenciatributaria.gob.es/static_files/' +
    'common/internet/dep/aplicaciones/es/aeat/burt/jdit/ws/VNifV2Ent.xsd';
  cLetrasPersonaJuridica = 'ABCDEFGHJNPQRSUVW';
  cHttpCorrecto = 200;

type
  TServicioVerificacionNif = class(
    TInterfacedObject,
    IServicioVerificacionNif)
  private
    FRepositorio: IRepositorioVerificacionNif;
    FTransporte: ITransporteVerificacionNif;
    function LeerCertificado(
      const ACodigoEmpresa: string): TCertificadoVerificacionNif;
  public
    constructor Create(
      const ARepositorio: IRepositorioVerificacionNif;
      const ATransporte: ITransporteVerificacionNif);
    function Verificar(
      const ASolicitud: TSolicitudVerificacionNif): TResultadoVerificacionNif;
  end;

function EscaparXmlVerificacion(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function DesescaparXmlVerificacion(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&apos;', '''', [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
end;

function ValorEtiquetaXmlVerificacion(
  const AXml, ANombreLocal: string): string;
var
  Coincidencia: TMatch;
begin
  Result := '';
  Coincidencia := TRegEx.Match(AXml,
    '<(?:[\w.-]+:)?' + ANombreLocal + '(?:\s[^>]*)?>(.*?)' +
    '</(?:[\w.-]+:)?' + ANombreLocal + '>',
    [roSingleLine, roIgnoreCase]);
  if Coincidencia.Success then
    Result := Trim(DesescaparXmlVerificacion(
      Coincidencia.Groups[1].Value));
end;

function NormalizarNifVerificacion(const ANif: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(ANif) do
    if CharInSet(UpCase(ANif[i]), ['A'..'Z', '0'..'9']) then
      Result := Result + UpCase(ANif[i]);
  if (Length(Result) > 9) and StartsStr('ES', Result) then
    Result := Copy(Result, 3, MaxInt);
end;

function EsNifPersonaJuridica(const ANif: string): Boolean;
var
  sNif: string;
begin
  sNif := NormalizarNifVerificacion(ANif);
  Result := (sNif <> '') and (Pos(sNif[1], cLetrasPersonaJuridica) > 0);
end;

// Sólo letras y dígitos, sin tildes: «S.L.» y «SL» son el mismo nombre.
function NormalizarNombreVerificacion(const ANombre: string): string;
const
  cConTilde = 'ÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÇ';
  cSinTilde = 'AAAAEEEEIIIIOOOOUUUUC';
var
  i: Integer;
  iTilde: Integer;
  cLetra: Char;
begin
  Result := '';
  for i := 1 to Length(ANombre) do
  begin
    cLetra := AnsiUpperCase(ANombre[i])[1];
    iTilde := Pos(cLetra, cConTilde);
    if iTilde > 0 then
      cLetra := cSinTilde[iTilde];
    if CharInSet(cLetra, ['A'..'Z', '0'..'9']) or (cLetra = 'Ñ') then
      Result := Result + cLetra;
  end;
end;

function EstadoDesdeResultado(
  const AResultado: string): TEstadoVerificacionNif;
var
  sResultado: string;
begin
  sResultado := UpperCase(Trim(AResultado));
  if StartsStr('NO IDENTIFICADO', sResultado) then
    Result := evnNoIdentificado
  else if ContainsStr(sResultado, 'REVOCADO') then
    Result := evnRevocado
  else if ContainsStr(sResultado, 'BAJA') then
    Result := evnBaja
  else if sResultado = 'IDENTIFICADO' then
    Result := evnIdentificado
  else
    Result := evnOtro;
end;

function GravedadDesdeResultado(
  const AResultado: TResultadoVerificacionNif): TGravedadVerificacionNif;
begin
  if AResultado.Estado in [evnNoIdentificado, evnRevocado, evnBaja] then
    Result := gvnError
  else if (AResultado.Estado = evnOtro) or AResultado.NifDistinto or
          AResultado.NombreDistinto then
    Result := gvnAviso
  else
    Result := gvnCorrecta;
end;

function ConstruirPeticionVerificacionNif(
  const ANif, ANombre: string): string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<soapenv:Envelope xmlns:soapenv="' + cNsSoap + '" ' +
    'xmlns:vnif="' + cNsEntrada + '">' +
    '<soapenv:Header/>' +
    '<soapenv:Body>' +
    '<vnif:VNifV2Ent>' +
    '<vnif:Contribuyente>' +
    '<vnif:Nif>' + EscaparXmlVerificacion(ANif) + '</vnif:Nif>' +
    '<vnif:Nombre>' + EscaparXmlVerificacion(ANombre) + '</vnif:Nombre>' +
    '</vnif:Contribuyente>' +
    '</vnif:VNifV2Ent>' +
    '</soapenv:Body>' +
    '</soapenv:Envelope>';
end;

function InterpretarRespuestaVerificacionNif(
  const AXml, ANifEnviado, ANombreEnviado: string
): TResultadoVerificacionNif;
var
  sContribuyente: string;
begin
  Result := Default(TResultadoVerificacionNif);
  Result.NifEnviado := NormalizarNifVerificacion(ANifEnviado);
  Result.NombreEnviado := Trim(ANombreEnviado);
  sContribuyente := ValorEtiquetaXmlVerificacion(AXml, 'Contribuyente');
  if sContribuyente = '' then
    raise EVerificacionNif.CreateFmt(SErrorVerificacionNifRespuesta,
      [cHttpCorrecto, ValorEtiquetaXmlVerificacion(AXml, 'faultstring')]);
  Result.NifAeat := NormalizarNifVerificacion(
    ValorEtiquetaXmlVerificacion(sContribuyente, 'Nif'));
  Result.NombreAeat := ValorEtiquetaXmlVerificacion(sContribuyente, 'Nombre');
  Result.Resultado := UpperCase(
    ValorEtiquetaXmlVerificacion(sContribuyente, 'Resultado'));
  Result.Estado := EstadoDesdeResultado(Result.Resultado);
  Result.EsPersonaJuridica := EsNifPersonaJuridica(Result.NifEnviado);
  Result.NifDistinto := (Result.NifAeat <> '') and
    (Result.NifAeat <> Result.NifEnviado);
  Result.NombreDistinto := Result.EsPersonaJuridica and
    (Result.Estado <> evnNoIdentificado) and
    (Result.NombreAeat <> '') and
    (NormalizarNombreVerificacion(Result.NombreAeat) <>
     NormalizarNombreVerificacion(Result.NombreEnviado));
  Result.Gravedad := GravedadDesdeResultado(Result);
end;

function TextoResultadoVerificacionNif(
  const AResultado: TResultadoVerificacionNif): string;
begin
  Result := AResultado.Resultado;
  if AResultado.NifDistinto then
    Result := Result + ' COMO ' + AResultado.NifAeat;
end;

{ TServicioVerificacionNif }

constructor TServicioVerificacionNif.Create(
  const ARepositorio: IRepositorioVerificacionNif;
  const ATransporte: ITransporteVerificacionNif);
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(ATransporte) then
    raise EArgumentNilException.Create('ATransporte');
  inherited Create;
  FRepositorio := ARepositorio;
  FTransporte := ATransporte;
end;

function TServicioVerificacionNif.LeerCertificado(
  const ACodigoEmpresa: string): TCertificadoVerificacionNif;
begin
  if Trim(ACodigoEmpresa) = '' then
    raise EVerificacionNif.Create(SErrorVerificacionNifSinEmpresa);
  Result := FRepositorio.LeerCertificadoEmpresa(Trim(ACodigoEmpresa));
  if (Trim(Result.Serie) = '') and (Trim(Result.Titular) = '') then
    raise EVerificacionNif.CreateFmt(SErrorVerificacionNifSinCertificado,
      [Trim(ACodigoEmpresa)]);
end;

function TServicioVerificacionNif.Verificar(
  const ASolicitud: TSolicitudVerificacionNif): TResultadoVerificacionNif;
var
  Certificado: TCertificadoVerificacionNif;
  iStatus: Integer;
  sNif: string;
  sRespuesta: string;
begin
  sNif := NormalizarNifVerificacion(ASolicitud.Nif);
  if sNif = '' then
    raise EVerificacionNif.Create(SErrorVerificacionNifVacio);
  Certificado := LeerCertificado(ASolicitud.CodigoEmpresa);
  sRespuesta := FTransporte.Enviar(
    ConstruirPeticionVerificacionNif(sNif, Trim(ASolicitud.Nombre)),
    Certificado,
    iStatus);
  if iStatus <> cHttpCorrecto then
    raise EVerificacionNif.CreateFmt(SErrorVerificacionNifRespuesta,
      [iStatus, ValorEtiquetaXmlVerificacion(sRespuesta, 'faultstring')]);
  Result := InterpretarRespuestaVerificacionNif(
    sRespuesta,
    sNif,
    ASolicitud.Nombre);
  if Trim(ASolicitud.CodigoCliente) <> '' then
    FRepositorio.GuardarResultadoCliente(
      Trim(ASolicitud.CodigoCliente),
      TextoResultadoVerificacionNif(Result));
end;

function CrearServicioVerificacionNif(
  const ARepositorio: IRepositorioVerificacionNif;
  const ATransporte: ITransporteVerificacionNif): IServicioVerificacionNif;
begin
  Result := TServicioVerificacionNif.Create(ARepositorio, ATransporte);
end;

end.
