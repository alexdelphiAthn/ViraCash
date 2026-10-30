{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSiiConstruccionEnvio                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Construye el registro SII de facturas emitidas (alta, modificación y      }
{    baja), su sobre SOAP, e interpreta las respuestas de la AEAT sin BBDD.    }
{******************************************************************************}
unit inLibSiiConstruccionEnvio;

interface

uses
  inLibVerifactuDesgloseFiscal;

const
  // Espacios de nombres del SII v1.1. Los XSD v1.1 se publican bajo
  // .../aeat/ssii_1_1/fact/ws/, pero su targetNamespace sigue siendo la
  // ruta sin versión .../aeat/ssii/fact/ws/ (comprobado el 07/10/2026).
  cNsSiiSuministroLR =
    'https://www2.agenciatributaria.gob.es/static_files/common/internet/' +
    'dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd';
  cNsSiiSuministroInformacion =
    'https://www2.agenciatributaria.gob.es/static_files/common/internet/' +
    'dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd';
  cIdVersionSii = '1.1';

type
  // Bloque de DesgloseTipoOperacion cuando la contraparte no tiene NIF
  // español (parámetro appSiiTipoOperacionDefecto)
  TTipoOperacionSii = (tosEntrega, tosPrestacionServicios);

  // A0 = alta de una factura nueva; A1 = modificación de una ya registrada
  TTipoComunicacionSii = (tcsAlta, tcsModificacion);

  // Mismos datos que TDatosFacturaRegistro (inLibVerifactuEnvio) más los
  // propios del SII. Importes sin formatear: la unidad los formatea.
  TEntradaConstruccionRegistroSii = record
    // Formato de documento de la empresa: separa serie y número en el
    // NumSerieFacturaEmisor igual que en la factura impresa
    FormatoDocumento: string;
    NifEmisor: string;
    NombreEmisor: string;
    Serie: string;
    Numero: string;
    // FECHA_FAC: da la fecha de expedición y el periodo de liquidación
    FechaFac: TDateTime;
    TipoFactura: string;        // F1 / F2 / F3 / R1..R5
    TipoRectificativa: string;  // I = diferencias; S = sustitutiva
    RectSerie: string;
    RectNumero: string;
    RectFecha: string;          // dd-mm-yyyy
    RectBase: Currency;
    RectCuota: Currency;
    RectCuotaRe: Currency;
    TieneImporteRectificacion: Boolean;
    NifCliente: string;
    NombreCliente: string;
    PaisClienteISO2: string;
    EsClienteUE: Boolean;
    EsClienteExtr: Boolean;
    ImporteTotal: Currency;
    // Calificación de la operación (catálogo fza_verifactu_operaciones)
    OpDefinida: Boolean;
    OpClaveRegimen: string;     // clave de régimen VeriFactu
    OpCalificacion: string;     // S1 / S2 / N1 / N2 o ''
    OpOperExenta: string;       // E1..E6 o ''
    OpRepercuteIva: Boolean;
    // Clave de régimen del SII ya traducida; vacía = se traduce
    // OpClaveRegimen con TraducirClaveRegimenSii
    ClaveRegimenSii: string;
    Bandas: array[0..3] of TBandaDesgloseFiscal;
    TipoOperacionDefecto: TTipoOperacionSii;
    DescripcionOperacion: string;
  end;

  TInterpretacionRespuestaSii = record
    EsHttpCorrecto: Boolean;
    Aceptado: Boolean;
    AceptadoConErrores: Boolean;
    Duplicado: Boolean;
    EstadoEnvio: string;
    EstadoRegistro: string;
    CodigoError: string;
    DescripcionError: string;
    // CSV del envío (cabecera de la respuesta)
    Csv: string;
    // CSV y estado del registro que ya estaba en el SII (solo duplicados)
    CsvRegistroDuplicado: string;
    EstadoRegistroDuplicado: string;
  end;

// SuministroLRFacturasEmitidas con un único RegistroLRFacturasEmitidas
function ConstruirSuministroLRFacturasEmitidas(
  const AEntrada: TEntradaConstruccionRegistroSii;
  ATipoComunicacion: TTipoComunicacionSii): string;

// BajaLRFacturasEmitidas con un único RegistroLRBajaExpedidas
function ConstruirBajaLRFacturasEmitidas(
  const AEntrada: TEntradaConstruccionRegistroSii): string;

function EnvolverSoapSii(const ACuerpo: string): string;

function InterpretarRespuestaSii(
  AEstadoHttp: Integer;
  const AXml: string): TInterpretacionRespuestaSii;

// True si la respuesta procede del servicio SOAP del SII y resuelve el
// envío: HTTP 200 con EstadoEnvio, o SOAP Fault con HTTP 500 o con HTTP
// 200 (FZ-ISSUE-308: un fault con 200 se reintentaba sin fin sin gastar
// intento).
function EsRespuestaSiiDefinitiva(
  AEstadoHttp: Integer;
  const AXml: string): Boolean;

// FZ-ISSUE-308: lo que contestó el servicio, para el mensaje de la cola:
// el faultstring si es un SOAP Fault, el título si es una página web y si
// no el principio del cuerpo en una línea (como mucho 300 caracteres).
function ExtractoRespuestaSii(const ACuerpo: string): string;

// True si la respuesta es una página web (portal, proxy, certificado) y no
// un mensaje SOAP.
function EsPaginaWebSii(const ACuerpo: string): Boolean;

// True si el SII ha rechazado el registro por sus datos y reenviarlo
// daría el mismo rechazo. Ver el criterio en la implementación.
function EsRechazoDefinitivoSii(
  const AEstadoRegistro, ACodigoError: string): Boolean;

// Valor del parámetro appSiiTipoOperacionDefecto
function TipoOperacionSiiDesdeTexto(const ATexto: string): TTipoOperacionSii;

// Clave de régimen VeriFactu → ClaveRegimenEspecialOTrascendencia del SII
function TraducirClaveRegimenSii(const AClaveVerifactu: string): string;

implementation

uses
  System.SysUtils, System.StrUtils,
  inLibFormatoDocumento, inLibMsgFacturas, inLibMsgVerifactu,
  inLibVerifactu,
  // ExtraerCodigoFault: los faults del SII dicen «Codigo[4102]...»
  inLibVerifactuConstruccionEnvio;

const
  cNsSoapSii = 'http://schemas.xmlsoap.org/soap/envelope/';
  cTextoTipoOperacionSii: array[TTipoOperacionSii] of string =
    ('Entrega', 'PrestacionServicios');
  cTextoTipoComunicacionSii: array[TTipoComunicacionSii] of string =
    ('A0', 'A1');
  cClaveRegimenGeneral = '01';
  cClaveRegimenExportacion = '02';
  // IdOperacionesTrascendenciaTributariaType del XSD v1.1: 01..16
  cClaveRegimenSiiMaxima = 16;
  cCodigoDuplicadoSii = '3000';
  cImporteMinimo = 0.001;

type
  // Reglas fiscales de la operación. Réplica de ResolverReglasDesglose
  // (inLibVerifactuDesgloseFiscal), que es privada de esa unidad: si se
  // cambia una, hay que cambiar la otra.
  TReglasOperacionSii = record
    ClaveRegimen: string;
    Calificacion: string;
    OperacionExenta: string;
    RepercuteIva: Boolean;
  end;

  // Contenido de un TipoSinDesglose antes de envolverlo en Sujeta/NoSujeta
  TPartesDesgloseSii = record
    Exenta: string;
    NoExenta: string;
    NoSujeta: string;
  end;

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

// Elemento del espacio de nombres SuministroInformacion (prefijo sii)
function Etiqueta(const ANombre, AContenido: string): string;
begin
  Result := '<sii:' + ANombre + '>' + AContenido + '</sii:' + ANombre + '>';
end;

// Elemento del espacio de nombres SuministroLR (prefijo siiLR)
function EtiquetaLR(const ANombre, AContenido: string): string;
begin
  Result := '<siiLR:' + ANombre + '>' + AContenido + '</siiLR:' +
    ANombre + '>';
end;

function EtiquetaImporte(const ANombre: string; AImporte: Currency): string;
begin
  Result := Etiqueta(ANombre, FormatearImporteVerifactu(AImporte));
end;

function FormatearFechaSii(AFecha: TDateTime): string;
begin
  Result := FormatDateTime('dd"-"mm"-"yyyy', AFecha);
end;

function MensajeFactura(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const AMensaje: string): string;
begin
  Result := FormatearMensajeDocumentos(AEntrada.FormatoDocumento, AMensaje,
    [AEntrada.TipoFactura, AEntrada.Serie, AEntrada.Numero]);
end;

function EsRectificativa(
  const AEntrada: TEntradaConstruccionRegistroSii): Boolean;
begin
  Result := Copy(AEntrada.TipoFactura, 1, 1) = 'R';
end;

function EsSustitutiva(
  const AEntrada: TEntradaConstruccionRegistroSii): Boolean;
begin
  Result := EsRectificativa(AEntrada) and
    (AEntrada.TipoRectificativa = 'S');
end;

procedure ValidarRectificativa(
  const AEntrada: TEntradaConstruccionRegistroSii);
begin
  if EsRectificativa(AEntrada) and
     (AEntrada.TipoRectificativa <> 'I') and
     (AEntrada.TipoRectificativa <> 'S') then
    raise Exception.Create(MensajeFactura(AEntrada,
      SErrorSiiTipoRectificativaInvalido));
  if EsSustitutiva(AEntrada) and
     (not AEntrada.TieneImporteRectificacion) then
    raise Exception.Create(MensajeFactura(AEntrada,
      SErrorSiiRectificativaSinImporteOriginal));
end;

function ConstruirCabecera(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const ATipoComunicacion: string): string;
begin
  // La cabecera de la baja (CabeceraSiiBaja) no lleva TipoComunicacion
  Result := Etiqueta('IDVersionSii', cIdVersionSii) +
    Etiqueta('Titular',
      Etiqueta('NombreRazon', EscaparXml(AEntrada.NombreEmisor)) +
      Etiqueta('NIF', EscaparXml(AEntrada.NifEmisor)));
  if ATipoComunicacion <> '' then
    Result := Result + Etiqueta('TipoComunicacion', ATipoComunicacion);
  Result := Etiqueta('Cabecera', Result);
end;

function ConstruirPeriodoLiquidacion(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  Result := Etiqueta('PeriodoLiquidacion',
    Etiqueta('Ejercicio', FormatDateTime('yyyy', AEntrada.FechaFac)) +
    Etiqueta('Periodo', FormatDateTime('mm', AEntrada.FechaFac)));
end;

function ConstruirIDFactura(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  Result := EtiquetaLR('IDFactura',
    Etiqueta('IDEmisorFactura',
      Etiqueta('NIF', EscaparXml(AEntrada.NifEmisor))) +
    Etiqueta('NumSerieFacturaEmisor', EscaparXml(ComponerNumSerieFactura(
      AEntrada.FormatoDocumento, AEntrada.Serie, AEntrada.Numero))) +
    Etiqueta('FechaExpedicionFacturaEmisor',
      FormatearFechaSii(AEntrada.FechaFac)));
end;

function ConstruirFacturasRectificadas(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  Result := '';
  if AEntrada.RectNumero <> '' then
    Result := Etiqueta('FacturasRectificadas',
      Etiqueta('IDFacturaRectificada',
        Etiqueta('NumSerieFacturaEmisor',
          EscaparXml(ComponerNumSerieFactura(AEntrada.FormatoDocumento,
            AEntrada.RectSerie, AEntrada.RectNumero))) +
        Etiqueta('FechaExpedicionFacturaEmisor', AEntrada.RectFecha)));
end;

function ConstruirImporteRectificacion(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  Result := '';
  if EsSustitutiva(AEntrada) then
  begin
    Result := EtiquetaImporte('BaseRectificada', AEntrada.RectBase) +
      EtiquetaImporte('CuotaRectificada', AEntrada.RectCuota);
    if Abs(AEntrada.RectCuotaRe) > cImporteMinimo then
      Result := Result +
        EtiquetaImporte('CuotaRecargoRectificado', AEntrada.RectCuotaRe);
    Result := Etiqueta('ImporteRectificacion', Result);
  end;
end;

function ConstruirRectificacion(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  Result := '';
  if EsRectificativa(AEntrada) then
    Result := Etiqueta('TipoRectificativa', AEntrada.TipoRectificativa) +
      ConstruirFacturasRectificadas(AEntrada) +
      ConstruirImporteRectificacion(AEntrada);
end;

// La contraparte es obligatoria en F1, F3 y en las rectificativas de
// factura completa (R1..R4); F2 y R5 (simplificadas) no la llevan.
function TieneContraparte(
  const AEntrada: TEntradaConstruccionRegistroSii): Boolean;
begin
  Result := MatchText(AEntrada.TipoFactura,
    ['F1', 'F3', 'R1', 'R2', 'R3', 'R4']);
end;

// Misma regla que ConstruirDestinatarioExtranjero de VeriFactu:
// UE → NIF-IVA (02); resto → documento oficial del país (04)
function ConstruirIDOtro(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
var
  sIdType: string;
begin
  if Trim(AEntrada.NifCliente) = '' then
    raise Exception.Create(MensajeFactura(AEntrada,
      SErrorFacturaExtranjeraSinNifIva));
  if AEntrada.EsClienteUE then
    sIdType := '02'
  else
    sIdType := '04';
  Result := Etiqueta('IDOtro',
    Etiqueta('CodigoPais', EscaparXml(AEntrada.PaisClienteISO2)) +
    Etiqueta('IDType', sIdType) +
    Etiqueta('ID', EscaparXml(AEntrada.NifCliente)));
end;

function ConstruirNifContraparte(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  if Length(AEntrada.NifCliente) <> 9 then
    raise Exception.Create(FormatearMensajeDocumentos(
      AEntrada.FormatoDocumento, SErrorFacturaSinNifClienteValido,
      [AEntrada.TipoFactura, AEntrada.Serie, AEntrada.Numero,
      AEntrada.NifCliente]));
  Result := Etiqueta('NIF', EscaparXml(AEntrada.NifCliente));
end;

function ConstruirContraparte(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
var
  sIdentificacion: string;
begin
  Result := '';
  if TieneContraparte(AEntrada) then
  begin
    if AEntrada.EsClienteExtr then
      sIdentificacion := ConstruirIDOtro(AEntrada)
    else
      sIdentificacion := ConstruirNifContraparte(AEntrada);
    Result := Etiqueta('Contraparte',
      Etiqueta('NombreRazon', EscaparXml(AEntrada.NombreCliente)) +
      sIdentificacion);
  end;
end;

// Desglose a nivel de operación cuando la contraparte se identifica con
// IDOtro o con un NIF que empieza por N (aviso 2006 del SII). R2 y R3
// solo admiten desglose a nivel de factura (error 1322).
function EsDesglosePorOperacion(
  const AEntrada: TEntradaConstruccionRegistroSii): Boolean;
begin
  Result := TieneContraparte(AEntrada) and
    (not MatchText(AEntrada.TipoFactura, ['R2', 'R3'])) and
    (AEntrada.EsClienteExtr or
     StartsText('N', Trim(AEntrada.NifCliente)));
end;

function ResolverReglasOperacionSii(
  const AEntrada: TEntradaConstruccionRegistroSii): TReglasOperacionSii;
begin
  Result.ClaveRegimen := cClaveRegimenGeneral;
  Result.Calificacion := '';
  Result.OperacionExenta := '';
  Result.RepercuteIva := True;
  if AEntrada.OpDefinida then
  begin
    if AEntrada.OpClaveRegimen <> '' then
      Result.ClaveRegimen := AEntrada.OpClaveRegimen;
    Result.Calificacion := AEntrada.OpCalificacion;
    Result.OperacionExenta := AEntrada.OpOperExenta;
    Result.RepercuteIva := AEntrada.OpRepercuteIva;
  end
  else if AEntrada.EsClienteExtr and (not AEntrada.EsClienteUE) then
  begin
    Result.OperacionExenta := 'E2';
    Result.RepercuteIva := False;
  end;
end;

// Con una sola clave 01 el SII no admite las exenciones E2/E3 de
// exportación (error 1301): en ese caso la clave pasa a 02.
function ResolverClaveRegimenSii(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const AReglas: TReglasOperacionSii): string;
begin
  if AEntrada.ClaveRegimenSii <> '' then
    Result := AEntrada.ClaveRegimenSii
  else
    Result := TraducirClaveRegimenSii(AReglas.ClaveRegimen);
  if (Result = cClaveRegimenGeneral) and (not AReglas.RepercuteIva) and
     MatchText(AReglas.OperacionExenta, ['E2', 'E3']) then
    Result := cClaveRegimenExportacion;
end;

// La entrega intracomunitaria (E5) no cabe en PrestacionServicios
// (error 1302): va siempre en Entrega.
function ResolverTipoOperacionDesglose(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const AReglas: TReglasOperacionSii): TTipoOperacionSii;
begin
  Result := AEntrada.TipoOperacionDefecto;
  if (not AReglas.RepercuteIva) and
     SameText(AReglas.OperacionExenta, 'E5') then
    Result := tosEntrega;
end;

function BandaTieneImporte(const ABanda: TBandaDesgloseFiscal): Boolean;
begin
  Result := (Abs(ABanda.Base) > cImporteMinimo) or
    (Abs(ABanda.Cuota) > cImporteMinimo);
end;

function SumarBases(
  const AEntrada: TEntradaConstruccionRegistroSii): Currency;
var
  iBanda: Integer;
begin
  Result := 0;
  for iBanda := Low(AEntrada.Bandas) to High(AEntrada.Bandas) do
    Result := Result + AEntrada.Bandas[iBanda].Base;
end;

// PrestacionServicios (DetalleIVAEmitidaPrestacionType) no admite recargo
function ConstruirDetalleIva(
  const ABanda: TBandaDesgloseFiscal;
  AConRecargo: Boolean): string;
begin
  Result := EtiquetaImporte('TipoImpositivo', ABanda.Porcentaje) +
    EtiquetaImporte('BaseImponible', ABanda.Base) +
    EtiquetaImporte('CuotaRepercutida', ABanda.Cuota);
  if AConRecargo and (Abs(ABanda.CuotaRecargo) > cImporteMinimo) then
    Result := Result +
      EtiquetaImporte('TipoRecargoEquivalencia', ABanda.PorcentajeRecargo) +
      EtiquetaImporte('CuotaRecargoEquivalencia', ABanda.CuotaRecargo);
  Result := Etiqueta('DetalleIVA', Result);
end;

function ConstruirDetalleIvaSinCuota(ABase: Currency): string;
var
  oBanda: TBandaDesgloseFiscal;
begin
  oBanda := Default(TBandaDesgloseFiscal);
  oBanda.Base := ABase;
  Result := ConstruirDetalleIva(oBanda, False);
end;

function ConstruirNoExenta(const ATipoNoExenta, ADetalles: string): string;
begin
  Result := Etiqueta('NoExenta',
    Etiqueta('TipoNoExenta', ATipoNoExenta) +
    Etiqueta('DesgloseIVA', ADetalles));
end;

function ConstruirExenta(const ACausa: string; ABase: Currency): string;
begin
  Result := Etiqueta('Exenta', Etiqueta('DetalleExenta',
    Etiqueta('CausaExencion', ACausa) +
    EtiquetaImporte('BaseImponible', ABase)));
end;

function ResolverTipoNoExenta(const AReglas: TReglasOperacionSii): string;
begin
  if SameText(AReglas.Calificacion, 'S2') then
    Result := 'S2'
  else
    Result := 'S1';
end;

// Bandas con IVA repercutido: las exentas se suman en un único
// DetalleExenta E1 y el resto van a DetalleIVA, una por banda.
function ConstruirPartesConRepercusion(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const AReglas: TReglasOperacionSii;
  AConRecargo: Boolean): TPartesDesgloseSii;
var
  iBanda: Integer;
  dBaseExenta: Currency;
  bHayExenta: Boolean;
  sDetalles: string;
  oBanda: TBandaDesgloseFiscal;
begin
  Result := Default(TPartesDesgloseSii);
  dBaseExenta := 0;
  bHayExenta := False;
  sDetalles := '';
  for iBanda := Low(AEntrada.Bandas) to High(AEntrada.Bandas) do
  begin
    oBanda := AEntrada.Bandas[iBanda];
    if BandaTieneImporte(oBanda) and oBanda.EsExenta then
    begin
      dBaseExenta := dBaseExenta + oBanda.Base;
      bHayExenta := True;
    end;
    if BandaTieneImporte(oBanda) and (not oBanda.EsExenta) then
      sDetalles := sDetalles + ConstruirDetalleIva(oBanda, AConRecargo);
  end;
  if bHayExenta then
    Result.Exenta := ConstruirExenta('E1', dBaseExenta);
  if sDetalles <> '' then
    Result.NoExenta := ConstruirNoExenta(ResolverTipoNoExenta(AReglas),
      sDetalles);
  if (not bHayExenta) and (sDetalles = '') then
    Result.NoExenta := ConstruirNoExenta('S1', ConstruirDetalleIvaSinCuota(0));
end;

// Operación sin repercusión: toda la base va a un solo bloque según la
// calificación del catálogo (mismas reglas que el desglose VeriFactu).
function ConstruirPartesSinRepercusion(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const AReglas: TReglasOperacionSii): TPartesDesgloseSii;
var
  dBase: Currency;
begin
  Result := Default(TPartesDesgloseSii);
  dBase := SumarBases(AEntrada);
  if AReglas.OperacionExenta <> '' then
    Result.Exenta := ConstruirExenta(AReglas.OperacionExenta, dBase)
  else if SameText(AReglas.Calificacion, 'N1') then
    Result.NoSujeta := EtiquetaImporte('ImportePorArticulos7_14_Otros',
      dBase)
  else if SameText(AReglas.Calificacion, 'N2') then
    Result.NoSujeta := EtiquetaImporte('ImporteTAIReglasLocalizacion',
      dBase)
  else if AReglas.Calificacion <> '' then
    Result.NoExenta := ConstruirNoExenta(ResolverTipoNoExenta(AReglas),
      ConstruirDetalleIvaSinCuota(dBase))
  else
    Result.Exenta := ConstruirExenta('E1', dBase);
end;

function ConstruirContenidoDesglose(
  const APartes: TPartesDesgloseSii): string;
begin
  Result := '';
  if (APartes.Exenta <> '') or (APartes.NoExenta <> '') then
    Result := Etiqueta('Sujeta', APartes.Exenta + APartes.NoExenta);
  if APartes.NoSujeta <> '' then
    Result := Result + Etiqueta('NoSujeta', APartes.NoSujeta);
end;

function ConstruirTipoDesglose(
  const AEntrada: TEntradaConstruccionRegistroSii;
  const AReglas: TReglasOperacionSii): string;
var
  bPorOperacion: Boolean;
  eTipoOperacion: TTipoOperacionSii;
  oPartes: TPartesDesgloseSii;
  sContenido: string;
begin
  bPorOperacion := EsDesglosePorOperacion(AEntrada);
  eTipoOperacion := ResolverTipoOperacionDesglose(AEntrada, AReglas);
  if AReglas.RepercuteIva then
    oPartes := ConstruirPartesConRepercusion(AEntrada, AReglas,
      (not bPorOperacion) or (eTipoOperacion = tosEntrega))
  else
    oPartes := ConstruirPartesSinRepercusion(AEntrada, AReglas);
  sContenido := ConstruirContenidoDesglose(oPartes);
  if bPorOperacion then
    Result := Etiqueta('DesgloseTipoOperacion',
      Etiqueta(cTextoTipoOperacionSii[eTipoOperacion], sContenido))
  else
    Result := Etiqueta('DesgloseFactura', sContenido);
  Result := Etiqueta('TipoDesglose', Result);
end;

function ConstruirFacturaExpedida(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
var
  oReglas: TReglasOperacionSii;
begin
  oReglas := ResolverReglasOperacionSii(AEntrada);
  Result := EtiquetaLR('FacturaExpedida',
    Etiqueta('TipoFactura', AEntrada.TipoFactura) +
    ConstruirRectificacion(AEntrada) +
    Etiqueta('ClaveRegimenEspecialOTrascendencia',
      ResolverClaveRegimenSii(AEntrada, oReglas)) +
    EtiquetaImporte('ImporteTotal', AEntrada.ImporteTotal) +
    Etiqueta('DescripcionOperacion',
      EscaparXml(AEntrada.DescripcionOperacion)) +
    ConstruirContraparte(AEntrada) +
    ConstruirTipoDesglose(AEntrada, oReglas));
end;

function ConstruirSuministroLRFacturasEmitidas(
  const AEntrada: TEntradaConstruccionRegistroSii;
  ATipoComunicacion: TTipoComunicacionSii): string;
begin
  ValidarRectificativa(AEntrada);
  Result := EtiquetaLR('SuministroLRFacturasEmitidas',
    ConstruirCabecera(AEntrada,
      cTextoTipoComunicacionSii[ATipoComunicacion]) +
    EtiquetaLR('RegistroLRFacturasEmitidas',
      ConstruirPeriodoLiquidacion(AEntrada) +
      ConstruirIDFactura(AEntrada) +
      ConstruirFacturaExpedida(AEntrada)));
end;

function ConstruirBajaLRFacturasEmitidas(
  const AEntrada: TEntradaConstruccionRegistroSii): string;
begin
  Result := EtiquetaLR('BajaLRFacturasEmitidas',
    ConstruirCabecera(AEntrada, '') +
    EtiquetaLR('RegistroLRBajaExpedidas',
      ConstruirPeriodoLiquidacion(AEntrada) +
      ConstruirIDFactura(AEntrada)));
end;

function EnvolverSoapSii(const ACuerpo: string): string;
begin
  Result :=
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<soapenv:Envelope xmlns:soapenv="' + cNsSoapSii + '" ' +
    'xmlns:siiLR="' + cNsSiiSuministroLR + '" ' +
    'xmlns:sii="' + cNsSiiSuministroInformacion + '">' +
    '<soapenv:Header/><soapenv:Body>' + ACuerpo +
    '</soapenv:Body></soapenv:Envelope>';
end;

// Primer contenido de <Etiqueta> o <prefijo:Etiqueta>, sin atributos
function ExtraerEtiqueta(const AXml, AEtiqueta: string): string;
var
  iIni: Integer;
  iFin: Integer;
  sApertura: string;
begin
  Result := '';
  sApertura := AEtiqueta + '>';
  iIni := Pos('<' + sApertura, AXml);
  if iIni = 0 then
    iIni := Pos(':' + sApertura, AXml);
  if iIni > 0 then
  begin
    iIni := iIni + Length(sApertura) + 1;
    iFin := PosEx('<', AXml, iIni);
    if iFin > iIni then
      Result := Trim(Copy(AXml, iIni, iFin - iIni));
  end;
end;

// Texto desde la primera aparición de AEtiqueta hasta el final ('' si no
// aparece). Separa la cabecera de la respuesta de su RespuestaLinea, y la
// línea de su RegistroDuplicado: los tres repiten CSV o EstadoRegistro.
function SeccionDesde(const AXml, AEtiqueta: string): string;
var
  iIni: Integer;
begin
  Result := '';
  iIni := Pos(AEtiqueta, AXml);
  if iIni > 0 then
    Result := Copy(AXml, iIni, MaxInt);
end;

function SeccionHasta(const AXml, AEtiqueta: string): string;
var
  iFin: Integer;
begin
  Result := AXml;
  iFin := Pos(AEtiqueta, AXml);
  if iFin > 0 then
    Result := Copy(AXml, 1, iFin - 1);
end;

// Duplicado: la línea trae el nodo RegistroDuplicado y el CSV del alta
// previa (RespuestaSuministro.xsd). El catálogo de errores del SII v1.1
// (rev. 17) no publica el código; se mantienen el 3000 y el texto
// «duplic» como en VeriFactu por si el nodo no llega.
function EsRespuestaDuplicado(
  const ALinea: string;
  const AResultado: TInterpretacionRespuestaSii): Boolean;
begin
  Result := (SeccionDesde(ALinea, 'RegistroDuplicado>') <> '') or
    (AResultado.CodigoError = cCodigoDuplicadoSii) or
    ContainsText(AResultado.DescripcionError, 'duplic');
end;

procedure LeerRespuestaCorrecta(
  const AXml: string;
  var AResultado: TInterpretacionRespuestaSii);
var
  sCabecera: string;
  sLinea: string;
  sDuplicado: string;
begin
  sCabecera := SeccionHasta(AXml, 'RespuestaLinea>');
  sLinea := SeccionDesde(AXml, 'RespuestaLinea>');
  sDuplicado := SeccionDesde(sLinea, 'RegistroDuplicado>');
  AResultado.EstadoEnvio := ExtraerEtiqueta(sCabecera, 'EstadoEnvio');
  AResultado.Csv := ExtraerEtiqueta(sCabecera, 'CSV');
  AResultado.EstadoRegistro := ExtraerEtiqueta(sLinea, 'EstadoRegistro');
  AResultado.CodigoError := ExtraerEtiqueta(sLinea, 'CodigoErrorRegistro');
  AResultado.DescripcionError := ExtraerEtiqueta(
    sLinea, 'DescripcionErrorRegistro');
  AResultado.CsvRegistroDuplicado := ExtraerEtiqueta(
    SeccionHasta(sLinea, 'RegistroDuplicado>'), 'CSV');
  AResultado.EstadoRegistroDuplicado := ExtraerEtiqueta(
    sDuplicado, 'EstadoRegistro');
  if AResultado.EstadoRegistro = '' then
    AResultado.EstadoRegistro := AResultado.EstadoEnvio;
  AResultado.Duplicado := EsRespuestaDuplicado(sLinea, AResultado);
  AResultado.AceptadoConErrores :=
    SameText(AResultado.EstadoRegistro, 'AceptadoConErrores');
  // Un duplicado de una factura anulada en el SII no la deja registrada
  AResultado.Aceptado :=
    SameText(AResultado.EstadoRegistro, 'Correcto') or
    AResultado.AceptadoConErrores or
    (AResultado.Duplicado and
     (not SameText(AResultado.EstadoRegistroDuplicado, 'Anulada')));
end;

// SOAP Fault sin respuesta del suministro (con HTTP 200 o 500)
function EsFaultSii(const AXml: string): Boolean;
begin
  Result := (ExtraerEtiqueta(AXml, 'faultstring') <> '') and
    (ExtraerEtiqueta(AXml, 'EstadoEnvio') = '');
end;

function InterpretarRespuestaSii(
  AEstadoHttp: Integer;
  const AXml: string): TInterpretacionRespuestaSii;
begin
  Result := Default(TInterpretacionRespuestaSii);
  // Un fault con HTTP 200 se lee como fault (FZ-ISSUE-308)
  Result.EsHttpCorrecto := (AEstadoHttp = 200) and not EsFaultSii(AXml);
  if Result.EsHttpCorrecto then
    LeerRespuestaCorrecta(AXml, Result)
  else
  begin
    Result.DescripcionError := ExtraerEtiqueta(AXml, 'faultstring');
    Result.CodigoError := ExtraerCodigoFault(Result.DescripcionError);
  end;
end;

function EsRespuestaSiiDefinitiva(
  AEstadoHttp: Integer;
  const AXml: string): Boolean;
begin
  if (AEstadoHttp = 200) and (ExtraerEtiqueta(AXml, 'EstadoEnvio') <> '') then
    Result := True
  else
    Result := ((AEstadoHttp = 200) or (AEstadoHttp = 500)) and
              (ExtraerEtiqueta(AXml, 'faultstring') <> '');
end;

function EsPaginaWebSii(const ACuerpo: string): Boolean;
begin
  Result := ContainsText(ACuerpo, '<html') or
    ContainsText(ACuerpo, '<!DOCTYPE html');
end;

function ExtractoRespuestaSii(const ACuerpo: string): string;
const
  cLongitudExtracto = 300;
var
  iCaracter: Integer;
  sTexto: string;
begin
  Result := ExtraerEtiqueta(ACuerpo, 'faultstring');
  if (Result = '') and EsPaginaWebSii(ACuerpo) then
    Result := ExtraerEtiqueta(ACuerpo, 'title');
  if Result = '' then
  begin
    // En una línea: los saltos y tabuladores pasan a espacios
    sTexto := ACuerpo;
    for iCaracter := 1 to Length(sTexto) do
      if CharInSet(sTexto[iCaracter], [#9, #10, #13]) then
        sTexto[iCaracter] := ' ';
    Result := Copy(Trim(sTexto), 1, cLongitudExtracto);
  end;
end;

// Criterio revisado contra Validaciones_ErroresSII_v1.1.pdf (rev. 17,
// vigente desde el 01/02/2026), apartado «Lista de errores»:
// - 1100..1592 rechazan la factura por sus datos: definitivo, salvo los
//   técnicos 1184 y 1266, que pueden salir bien al reintentar.
// - 3001..3020 y 3902 (ya dada de baja, no existe, sin permisos, periodo
//   incorrecto, factura de otro titular): definitivo.
// - 3500..3506 son errores técnicos de BBDD de la AEAT: se reintenta.
// - 4xxx llegan como SOAP Fault y rechazan el envío entero (cabecera,
//   certificado, censo o fallo técnico): se reintentan, como en VeriFactu.
// - 2xxx dejan el registro AceptadoConErrores: no es un rechazo.
// El duplicado (3000) se trata antes como aceptado.
function EsCodigoRechazoDefinitivoSii(ACodigo: Integer): Boolean;
begin
  Result := ((ACodigo >= 1000) and (ACodigo <= 1999) and
             (ACodigo <> 1184) and (ACodigo <> 1266)) or
            ((ACodigo >= 3001) and (ACodigo <= 3499)) or
            (ACodigo = 3902);
end;

function EsRechazoDefinitivoSii(
  const AEstadoRegistro, ACodigoError: string): Boolean;
begin
  Result := SameText(Trim(AEstadoRegistro), 'Incorrecto') and
    EsCodigoRechazoDefinitivoSii(StrToIntDef(Trim(ACodigoError), 0));
end;

function TipoOperacionSiiDesdeTexto(const ATexto: string): TTipoOperacionSii;
var
  eTipo: TTipoOperacionSii;
  bEncontrado: Boolean;
begin
  Result := tosEntrega;
  bEncontrado := False;
  for eTipo := Low(TTipoOperacionSii) to High(TTipoOperacionSii) do
  begin
    if SameText(Trim(ATexto), cTextoTipoOperacionSii[eTipo]) then
    begin
      Result := eTipo;
      bEncontrado := True;
    end;
  end;
  if not bEncontrado then
    raise Exception.CreateFmt(SErrorSiiTipoOperacionDesconocido, [ATexto]);
end;

// Las claves 01..16 se copian tal cual: el SII v1.1 las admite todas y
// el catálogo (CLAVE_REGIMEN_SII_VFO, ClaveRegimenSii) prevalece donde el
// significado difiere. Las que el SII no tiene (17 OSS/IOSS, 18 recargo
// de equivalencia, 19 REAGYP, 20 simplificado) y cualquier valor no
// válido van al régimen general 01.
function TraducirClaveRegimenSii(const AClaveVerifactu: string): string;
var
  iClave: Integer;
  sClave: string;
begin
  sClave := Trim(AClaveVerifactu);
  iClave := StrToIntDef(sClave, 0);
  if (Length(sClave) = 2) and (iClave >= 1) and
     (iClave <= cClaveRegimenSiiMaxima) then
    Result := sClave
  else
    Result := cClaveRegimenGeneral;
end;

end.
