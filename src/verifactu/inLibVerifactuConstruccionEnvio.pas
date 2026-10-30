{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuConstruccionEnvio                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Construye registros de alta e interpreta respuestas AEAT sin BBDD.        }
{******************************************************************************}
unit inLibVerifactuConstruccionEnvio;

interface

uses
  System.SysUtils;

type
  TEntradaConstruccionRegistroAlta = record
    FormatoDocumento: string;
    Serie: string;
    Numero: string;
    NumSerieFactura: string;
    NifEmisor: string;
    NombreEmisor: string;
    FechaExpedicion: string;
    TipoFactura: string;
    TipoRectificativa: string;
    RectNumero: string;
    RectNumSerieFactura: string;
    RectFecha: string;
    RectBase: string;
    RectCuota: string;
    RectCuotaRe: string;
    TieneRectCuotaRe: Boolean;
    TieneImporteRectificacion: Boolean;
    NifCliente: string;
    NombreCliente: string;
    PaisClienteISO2: string;
    EsClienteUE: Boolean;
    EsClienteExtr: Boolean;
    CuotaTotal: string;
    ImporteTotal: string;
    CadenaNumSerieFactura: string;
    CadenaFecha: string;
    HuellaAnterior: string;
    FechaHoraHuso: string;
    SistemaInformaticoXml: string;
    DesgloseXml: string;
    DescripcionOperacion: string;
    EmitidaPorTerceroODestinatario: string;
    EsSubsanacion: Boolean;
  end;

  TResultadoConstruccionRegistroAlta = record
    Xml: string;
    Huella: string;
  end;

  TInterpretacionRespuestaAeat = record
    EsHttpCorrecto: Boolean;
    Aceptado: Boolean;
    Duplicado: Boolean;
    EstadoEnvio: string;
    EstadoRegistro: string;
    CodigoError: string;
    DescripcionError: string;
    EsperaSegundos: Integer;
    Csv: string;
  end;

function ConstruirRegistroAltaVerifactu(
  const AEntrada: TEntradaConstruccionRegistroAlta):
  TResultadoConstruccionRegistroAlta;

function InterpretarRespuestaAeat(
  AEstadoHttp: Integer;
  const AXml: string): TInterpretacionRespuestaAeat;

// Código de un faultstring de la AEAT: «Codigo[4104].Error en...» → 4104
function ExtraerCodigoFault(const AFaultString: string): string;

// True si la respuesta procede del servicio SOAP de la AEAT y resuelve el
// envío: HTTP 200 con EstadoEnvio o SOAP Fault con HTTP 200 o 500
// (FZ-ISSUE-763: la AEAT devuelve faults con HTTP 200). Un proxy, un
// portal cautivo o un cuerpo truncado no lo son: el registro pudo quedar
// registrado o no, y el envío sigue siendo incierto.
function EsRespuestaAeatDefinitiva(
  AEstadoHttp: Integer;
  const AXml: string): Boolean;

implementation

uses
  inLibFormatoDocumento,
  System.Hash, System.StrUtils,
  inLibMsgFacturas;

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function CalcularHuellaAlta(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(
    'IDEmisorFactura=' + AEntrada.NifEmisor +
    '&NumSerieFactura=' + AEntrada.NumSerieFactura +
    '&FechaExpedicionFactura=' + AEntrada.FechaExpedicion +
    '&TipoFactura=' + AEntrada.TipoFactura +
    '&CuotaTotal=' + AEntrada.CuotaTotal +
    '&ImporteTotal=' + AEntrada.ImporteTotal +
    '&Huella=' + AEntrada.HuellaAnterior +
    '&FechaHoraHusoGenRegistro=' + AEntrada.FechaHoraHuso));
end;

function ConstruirSubsanacion(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  if AEntrada.EsSubsanacion then
    Result := '<sum1:Subsanacion>S</sum1:Subsanacion>'
  else
    Result := '';
end;

function EsRectificativa(
  const AEntrada: TEntradaConstruccionRegistroAlta): Boolean;
begin
  Result := Copy(AEntrada.TipoFactura, 1, 1) = 'R';
end;

procedure ValidarTipoRectificativa(
  const AEntrada: TEntradaConstruccionRegistroAlta);
begin
  if EsRectificativa(AEntrada) and
     (AEntrada.TipoRectificativa <> 'I') and
     (AEntrada.TipoRectificativa <> 'S') then
    raise Exception.Create(
      'El tipo fiscal de rectificativa debe ser I o S.');
end;

function ConstruirTipoRectificativa(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  if EsRectificativa(AEntrada) then
    Result := '<sum1:TipoRectificativa>' +
      AEntrada.TipoRectificativa + '</sum1:TipoRectificativa>';
end;

function ConstruirFacturasRectificadas(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  if EsRectificativa(AEntrada) and (AEntrada.RectNumero <> '') then
    Result := '<sum1:FacturasRectificadas>' +
      '<sum1:IDFacturaRectificada>' +
      '<sum1:IDEmisorFactura>' + EscaparXml(AEntrada.NifEmisor) +
      '</sum1:IDEmisorFactura>' +
      '<sum1:NumSerieFactura>' +
      EscaparXml(AEntrada.RectNumSerieFactura) +
      '</sum1:NumSerieFactura>' +
      '<sum1:FechaExpedicionFactura>' + AEntrada.RectFecha +
      '</sum1:FechaExpedicionFactura>' +
      '</sum1:IDFacturaRectificada></sum1:FacturasRectificadas>';
end;

function ConstruirFacturasSustituidas(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  if (AEntrada.TipoFactura = 'F3') and
     (AEntrada.RectNumero <> '') then
    Result := '<sum1:FacturasSustituidas>' +
      '<sum1:IDFacturaSustituida>' +
      '<sum1:IDEmisorFactura>' + EscaparXml(AEntrada.NifEmisor) +
      '</sum1:IDEmisorFactura>' +
      '<sum1:NumSerieFactura>' +
      EscaparXml(AEntrada.RectNumSerieFactura) +
      '</sum1:NumSerieFactura>' +
      '<sum1:FechaExpedicionFactura>' + AEntrada.RectFecha +
      '</sum1:FechaExpedicionFactura>' +
      '</sum1:IDFacturaSustituida></sum1:FacturasSustituidas>';
end;

procedure ValidarImporteRectificacion(
  const AEntrada: TEntradaConstruccionRegistroAlta);
begin
  if EsRectificativa(AEntrada) and
     (AEntrada.TipoRectificativa = 'S') and
     (not AEntrada.TieneImporteRectificacion) then
    raise Exception.Create(
      'La rectificativa sustitutiva no tiene los importes originales.');
end;

function ConstruirImporteRectificacion(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  if EsRectificativa(AEntrada) and
     (AEntrada.TipoRectificativa = 'S') then
  begin
    Result := '<sum1:ImporteRectificacion>' +
      '<sum1:BaseRectificada>' +
      AEntrada.RectBase +
      '</sum1:BaseRectificada>' +
      '<sum1:CuotaRectificada>' +
      AEntrada.RectCuota +
      '</sum1:CuotaRectificada>';
    if AEntrada.TieneRectCuotaRe then
      Result := Result + '<sum1:CuotaRecargoRectificado>' +
        AEntrada.RectCuotaRe +
        '</sum1:CuotaRecargoRectificado>';
    Result := Result + '</sum1:ImporteRectificacion>';
  end;
end;

function ConstruirFechaOperacion(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  if EsRectificativa(AEntrada) and (AEntrada.RectFecha <> '') then
    Result := '<sum1:FechaOperacion>' + AEntrada.RectFecha +
      '</sum1:FechaOperacion>';
end;

function ConstruirDestinatarioExtranjero(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
var
  sIdType: string;
begin
  if Trim(AEntrada.NifCliente) = '' then
    raise Exception.Create(FormatearMensajeDocumentos(
      AEntrada.FormatoDocumento, SErrorFacturaExtranjeraSinNifIva,
      [AEntrada.TipoFactura, AEntrada.Serie, AEntrada.Numero]));
  if AEntrada.EsClienteUE then
    sIdType := '02'
  else
    sIdType := '04';
  Result := '<sum1:Destinatarios><sum1:IDDestinatario>' +
    '<sum1:NombreRazon>' + EscaparXml(AEntrada.NombreCliente) +
    '</sum1:NombreRazon><sum1:IDOtro>' +
    '<sum1:CodigoPais>' + EscaparXml(AEntrada.PaisClienteISO2) +
    '</sum1:CodigoPais><sum1:IDType>' + sIdType + '</sum1:IDType>' +
    '<sum1:ID>' + EscaparXml(AEntrada.NifCliente) + '</sum1:ID>' +
    '</sum1:IDOtro></sum1:IDDestinatario></sum1:Destinatarios>';
end;

function ConstruirDestinatarioNacional(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  if Length(AEntrada.NifCliente) <> 9 then
    raise Exception.Create(FormatearMensajeDocumentos(
      AEntrada.FormatoDocumento, SErrorFacturaSinNifClienteValido,
      [AEntrada.TipoFactura, AEntrada.Serie, AEntrada.Numero,
      AEntrada.NifCliente]));
  Result := '<sum1:Destinatarios><sum1:IDDestinatario>' +
    '<sum1:NombreRazon>' + EscaparXml(AEntrada.NombreCliente) +
    '</sum1:NombreRazon><sum1:NIF>' + EscaparXml(AEntrada.NifCliente) +
    '</sum1:NIF></sum1:IDDestinatario></sum1:Destinatarios>';
end;

function ConstruirDestinatarios(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  // Destinatarios es obligatorio en F1, F3 y en toda rectificativa de
  // factura completa (R1..R4); F2 y R5 (simplificadas) no lo llevan.
  if MatchText(AEntrada.TipoFactura,
       ['F1', 'R1', 'R2', 'R3', 'R4', 'F3']) then
  begin
    if AEntrada.EsClienteExtr then
      Result := ConstruirDestinatarioExtranjero(AEntrada)
    else
      Result := ConstruirDestinatarioNacional(AEntrada);
  end;
end;

function ConstruirEncadenamiento(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  if AEntrada.HuellaAnterior = '' then
    Result := '<sum1:Encadenamiento>' +
      '<sum1:PrimerRegistro>S</sum1:PrimerRegistro>' +
      '</sum1:Encadenamiento>'
  else
    Result := '<sum1:Encadenamiento><sum1:RegistroAnterior>' +
      '<sum1:IDEmisorFactura>' + EscaparXml(AEntrada.NifEmisor) +
      '</sum1:IDEmisorFactura>' +
      '<sum1:NumSerieFactura>' +
      EscaparXml(AEntrada.CadenaNumSerieFactura) +
      '</sum1:NumSerieFactura>' +
      '<sum1:FechaExpedicionFactura>' + AEntrada.CadenaFecha +
      '</sum1:FechaExpedicionFactura>' +
      '<sum1:Huella>' + AEntrada.HuellaAnterior + '</sum1:Huella>' +
      '</sum1:RegistroAnterior></sum1:Encadenamiento>';
end;

function ConstruirExpedidorDelegado(
  const AEntrada: TEntradaConstruccionRegistroAlta): string;
begin
  Result := '';
  if AEntrada.EmitidaPorTerceroODestinatario <> '' then
  begin
    if (AEntrada.EmitidaPorTerceroODestinatario <> 'D') and
       (AEntrada.EmitidaPorTerceroODestinatario <> 'T') then
      raise EArgumentException.Create(
        'El expedidor delegado debe ser D (destinatario) o T (tercero).');
    Result := '<sum1:EmitidaPorTerceroODestinatario>' +
      AEntrada.EmitidaPorTerceroODestinatario +
      '</sum1:EmitidaPorTerceroODestinatario>';
  end;
end;

function ConstruirCuerpoRegistroAlta(
  const AEntrada: TEntradaConstruccionRegistroAlta;
  const AHuella: string): string;
begin
  Result := '<sum1:RegistroAlta><sum1:IDVersion>1.0</sum1:IDVersion>' +
    '<sum1:IDFactura><sum1:IDEmisorFactura>' +
    EscaparXml(AEntrada.NifEmisor) + '</sum1:IDEmisorFactura>' +
    '<sum1:NumSerieFactura>' + EscaparXml(AEntrada.NumSerieFactura) +
    '</sum1:NumSerieFactura><sum1:FechaExpedicionFactura>' +
    AEntrada.FechaExpedicion + '</sum1:FechaExpedicionFactura>' +
    '</sum1:IDFactura><sum1:NombreRazonEmisor>' +
    EscaparXml(AEntrada.NombreEmisor) + '</sum1:NombreRazonEmisor>' +
    ConstruirSubsanacion(AEntrada) +
    '<sum1:TipoFactura>' + AEntrada.TipoFactura + '</sum1:TipoFactura>' +
    ConstruirTipoRectificativa(AEntrada) +
    ConstruirFacturasRectificadas(AEntrada) +
    ConstruirFacturasSustituidas(AEntrada) +
    ConstruirImporteRectificacion(AEntrada) +
    ConstruirFechaOperacion(AEntrada) +
    '<sum1:DescripcionOperacion>' +
    EscaparXml(AEntrada.DescripcionOperacion) +
    '</sum1:DescripcionOperacion>' + ConstruirExpedidorDelegado(AEntrada) +
    ConstruirDestinatarios(AEntrada) +
    '<sum1:Desglose>' + AEntrada.DesgloseXml + '</sum1:Desglose>' +
    '<sum1:CuotaTotal>' + AEntrada.CuotaTotal + '</sum1:CuotaTotal>' +
    '<sum1:ImporteTotal>' + AEntrada.ImporteTotal +
    '</sum1:ImporteTotal>' +
    ConstruirEncadenamiento(AEntrada) + AEntrada.SistemaInformaticoXml +
    '<sum1:FechaHoraHusoGenRegistro>' + AEntrada.FechaHoraHuso +
    '</sum1:FechaHoraHusoGenRegistro>' +
    '<sum1:TipoHuella>01</sum1:TipoHuella><sum1:Huella>' + AHuella +
    '</sum1:Huella></sum1:RegistroAlta>';
end;

function ConstruirRegistroAltaVerifactu(
  const AEntrada: TEntradaConstruccionRegistroAlta):
  TResultadoConstruccionRegistroAlta;
begin
  ValidarTipoRectificativa(AEntrada);
  ValidarImporteRectificacion(AEntrada);
  Result.Huella := CalcularHuellaAlta(AEntrada);
  Result.Xml := ConstruirCuerpoRegistroAlta(AEntrada, Result.Huella);
end;

function ExtraerEtiqueta(const AXml, AEtiqueta: string): string;
var
  iIni: Integer;
  iFin: Integer;
  sApertura: string;
begin
  Result := '';
  sApertura := AEtiqueta + '>';
  iIni := Pos('<' + sApertura, AXml);
  if iIni > 0 then
    iIni := iIni + Length(sApertura) + 1
  else
  begin
    iIni := Pos(':' + sApertura, AXml);
    if iIni > 0 then
      iIni := iIni + Length(sApertura) + 1;
  end;
  if iIni > 0 then
  begin
    iFin := PosEx('<', AXml, iIni);
    if iFin > iIni then
      Result := Trim(Copy(AXml, iIni, iFin - iIni));
  end;
end;

procedure LeerRespuestaCorrecta(
  const AXml: string;
  var AResultado: TInterpretacionRespuestaAeat);
begin
  AResultado.EstadoEnvio := ExtraerEtiqueta(AXml, 'EstadoEnvio');
  AResultado.EstadoRegistro := ExtraerEtiqueta(AXml, 'EstadoRegistro');
  AResultado.CodigoError := ExtraerEtiqueta(AXml, 'CodigoErrorRegistro');
  AResultado.DescripcionError := ExtraerEtiqueta(
    AXml, 'DescripcionErrorRegistro');
  AResultado.EsperaSegundos := StrToIntDef(
    ExtraerEtiqueta(AXml, 'TiempoEsperaEnvio'), 0);
  AResultado.Csv := ExtraerEtiqueta(AXml, 'CSV');
  if AResultado.EstadoRegistro = '' then
    AResultado.EstadoRegistro := AResultado.EstadoEnvio;
  AResultado.Duplicado := (AResultado.CodigoError = '3000') or
    ContainsText(AResultado.DescripcionError, 'duplicado');
  AResultado.Aceptado :=
    SameText(AResultado.EstadoEnvio, 'Correcto') or
    SameText(AResultado.EstadoRegistro, 'Correcto') or
    SameText(AResultado.EstadoRegistro, 'AceptadoConErrores') or
    AResultado.Duplicado;
end;

function ExtraerCodigoFault(const AFaultString: string): string;
var
  iIni: Integer;
  iFin: Integer;
begin
  Result := '';
  iIni := Pos('Codigo[', AFaultString);
  if iIni > 0 then
  begin
    iIni := iIni + Length('Codigo[');
    iFin := PosEx(']', AFaultString, iIni);
    if (iFin > iIni) and
       (StrToIntDef(Copy(AFaultString, iIni, iFin - iIni), -1) >= 0) then
      Result := Copy(AFaultString, iIni, iFin - iIni);
  end;
end;

// SOAP Fault sin respuesta del suministro (con HTTP 200 o 500)
function EsFaultAeat(const AXml: string): Boolean;
begin
  Result := (ExtraerEtiqueta(AXml, 'faultstring') <> '') and
    (ExtraerEtiqueta(AXml, 'EstadoEnvio') = '');
end;

function InterpretarRespuestaAeat(
  AEstadoHttp: Integer;
  const AXml: string): TInterpretacionRespuestaAeat;
begin
  Result := Default(TInterpretacionRespuestaAeat);
  // Un fault con HTTP 200 se lee como fault (FZ-ISSUE-763)
  Result.EsHttpCorrecto := (AEstadoHttp = 200) and not EsFaultAeat(AXml);
  if Result.EsHttpCorrecto then
    LeerRespuestaCorrecta(AXml, Result)
  else
  begin
    Result.DescripcionError := ExtraerEtiqueta(AXml, 'faultstring');
    Result.CodigoError := ExtraerCodigoFault(Result.DescripcionError);
  end;
end;

function EsRespuestaAeatDefinitiva(
  AEstadoHttp: Integer;
  const AXml: string): Boolean;
begin
  if (AEstadoHttp = 200) and (ExtraerEtiqueta(AXml, 'EstadoEnvio') <> '') then
    Result := True
  else
    Result := ((AEstadoHttp = 200) or (AEstadoHttp = 500)) and
              (ExtraerEtiqueta(AXml, 'faultstring') <> '');
end;

end.
