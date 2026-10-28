{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSepaRemesasCompra                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       28/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fichero de transferencias SEPA (cuaderno 34, ISO 20022 pain.001) de las  }
{    remesas de pago: versión 2009 (pain.001.001.03) o 2019 (001.09).         }
{******************************************************************************}
unit inLibSepaRemesasCompra;

interface

uses
  System.SysUtils;

type
  TFormatoSepaTransferencia = (fstPain00100103, fstPain00100109);

  TEfectoSepaCompraValidado = record
    IdPago: string;
    Importe: Currency;
    NombreBeneficiario: string;
    IbanBeneficiario: string;
    Concepto: string;
  end;

  // Remesa lista para escribir: identificadores fijados, IBAN validados y
  // avisos (IBAN del efecto distinto de la ficha) para que la UI confirme.
  TRemesaSepaCompraValidada = record
    IdMensaje: string;
    Formato: TFormatoSepaTransferencia;
    Instante: TDateTime;
    DesfaseUtcMinutos: Integer;
    NombreEmpresa: string;
    IdOrdenante: string;
    IbanEmpresa: string;
    BicEmpresa: string;
    FechaEjecucion: TDateTime;
    Efectos: TArray<TEfectoSepaCompraValidado>;
    Avisos: TArray<string>;
  end;

  TResultadoSepaRemesaCompra = record
    Archivo: string;
    NumPagos: Integer;
    Total: Currency;
  end;

  // Fichero ya generado para la remesa (vacío si nunca se generó).
  TFicheroSepaRemesaCompra = record
    Estado: string;
    IdMensaje: string;
    Formato: string;
    Archivo: string;
    Instante: TDateTime;
  end;

const
  CEstadoRemesaCompraGenerada = 'GENERADA';
  CNormaSepaTransferencias = '34.14';

function NombreFormatoSepaTransferencia(
  AFormato: TFormatoSepaTransferencia): string;
function FormatoSepaTransferenciaDesdeNombre(const AValor: string;
  ADefecto: TFormatoSepaTransferencia): TFormatoSepaTransferencia;
function CrearIdMensajeSepaRemesaCompra(const ASerie, ANumero: string;
  AInstante: TDateTime): string;
function CrearIdPagoSepaRemesaCompra(const ASerieFactura,
  ANumeroFactura: string; ANumeroEfecto: Integer): string;
function FormatearInstanteSepa(AInstante: TDateTime;
  ADesfaseUtcMinutos: Integer): string;
function DesfaseUtcLocalMinutos(AInstante: TDateTime): Integer;
procedure ValidarRemesaSepaCompra(const ARemesa: TRemesaSepaCompraValidada;
  AHoy: TDateTime);
function ConstruirXmlSepaRemesaCompra(
  const ARemesa: TRemesaSepaCompraValidada;
  AHoy: TDateTime): string;
function GenerarSepaRemesaCompra(
  const ARemesa: TRemesaSepaCompraValidada;
  const AArchivo: string): TResultadoSepaRemesaCompra;

implementation

uses
  System.Classes, System.DateUtils, System.IOUtils, System.TimeSpan,
  inLibMsgCompras, uDJMSepa;

const
  CLongitudIdSepa = 35;
  CLongitudNombreSepa = 70;
  CLongitudConceptoSepa = 140;
  CNombresFormato: array[TFormatoSepaTransferencia] of string = (
    'pain.001.001.03', 'pain.001.001.09');

function NombreFormatoSepaTransferencia(
  AFormato: TFormatoSepaTransferencia): string;
begin
  Result := CNombresFormato[AFormato];
end;

function FormatoSepaTransferenciaDesdeNombre(const AValor: string;
  ADefecto: TFormatoSepaTransferencia): TFormatoSepaTransferencia;
var
  eFormato: TFormatoSepaTransferencia;
begin
  Result := ADefecto;
  for eFormato := Low(TFormatoSepaTransferencia) to
    High(TFormatoSepaTransferencia) do
  begin
    if SameText(Trim(AValor), CNombresFormato[eFormato]) then
      Result := eFormato;
  end;
end;

function SoloAlfanumerico(const AValor: string): string;
var
  cCaracter: Char;
begin
  Result := '';
  for cCaracter in UpperCase(Trim(AValor)) do
  begin
    if CharInSet(cCaracter, ['A'..'Z', '0'..'9']) then
      Result := Result + cCaracter;
  end;
end;

function CrearIdMensajeSepaRemesaCompra(const ASerie, ANumero: string;
  AInstante: TDateTime): string;
begin
  // 20 + 1 + 14 = 35: la marca de tiempo nunca se recorta.
  Result := Copy('REMC-' + SoloAlfanumerico(ASerie) + '-' +
    SoloAlfanumerico(ANumero), 1, 20) + '-' +
    FormatDateTime('yyyymmddhhnnss', AInstante);
end;

function CrearIdPagoSepaRemesaCompra(const ASerieFactura,
  ANumeroFactura: string; ANumeroEfecto: Integer): string;
begin
  Result := SoloAlfanumerico(ASerieFactura) + '-' +
    SoloAlfanumerico(ANumeroFactura) + '-' + IntToStr(ANumeroEfecto);
  // Se conserva el final (número de factura y de efecto) si no cabe.
  if Length(Result) > CLongitudIdSepa then
    Result := Copy(Result, Length(Result) - CLongitudIdSepa + 1,
      CLongitudIdSepa);
end;

function DesfaseUtcLocalMinutos(AInstante: TDateTime): Integer;
begin
  Result := Round(TTimeZone.Local.GetUtcOffset(AInstante).TotalMinutes);
end;

// Hora local con su desfase explícito (+01:00): nunca «Z» sobre hora local.
function FormatearInstanteSepa(AInstante: TDateTime;
  ADesfaseUtcMinutos: Integer): string;
var
  iMinutos: Integer;
  sSigno: string;
begin
  sSigno := '+';
  iMinutos := ADesfaseUtcMinutos;
  if iMinutos < 0 then
  begin
    sSigno := '-';
    iMinutos := -iMinutos;
  end;
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', AInstante) +
    sSigno + Format('%.2d:%.2d', [iMinutos div 60, iMinutos mod 60]);
end;

function ImporteEnCentimos(AImporte: Currency): Int64;
begin
  Result := Trunc(AImporte * 100 + 0.5);
end;

function FormatearCentimos(ACentimos: Int64): string;
begin
  Result := IntToStr(ACentimos div 100) + '.' +
    Format('%.2d', [ACentimos mod 100]);
end;

function TextoSepa(const AValor: string; ALongitud: Integer): string;
begin
  Result := Trim(uSEPA_CleanStr(AValor, ALongitud));
end;

procedure ValidarRemesaSepaCompra(const ARemesa: TRemesaSepaCompraValidada;
  AHoy: TDateTime);
var
  iIndice: Integer;
begin
  if Length(ARemesa.Efectos) = 0 then
    raise Exception.Create(SErrorRemesaCompraSepaSinEfectos);
  if (Trim(ARemesa.IdMensaje) = '') or
     (Length(ARemesa.IdMensaje) > CLongitudIdSepa) then
    raise Exception.CreateFmt(SErrorRemesaCompraSepaIdMensaje,
      [ARemesa.IdMensaje]);
  if TextoSepa(ARemesa.NombreEmpresa, CLongitudNombreSepa) = '' then
    raise Exception.Create(SErrorRemesaCompraSepaSinOrdenante);
  if Trim(ARemesa.IbanEmpresa) = '' then
    raise Exception.Create(SErrorRemesaCompraSepaSinBancoPago);
  if ARemesa.FechaEjecucion <= 0 then
    raise Exception.Create(SErrorRemesaCompraSepaSinFechaCargo);
  if DateOf(ARemesa.FechaEjecucion) < DateOf(AHoy) then
    raise Exception.CreateFmt(SErrorRemesaCompraSepaFechaPasada,
      [DateToStr(ARemesa.FechaEjecucion)]);
  for iIndice := Low(ARemesa.Efectos) to High(ARemesa.Efectos) do
  begin
    if ImporteEnCentimos(ARemesa.Efectos[iIndice].Importe) <= 0 then
      raise Exception.CreateFmt(SErrorRemesaCompraSepaImporte,
        [ARemesa.Efectos[iIndice].IdPago]);
    if TextoSepa(ARemesa.Efectos[iIndice].NombreBeneficiario,
       CLongitudNombreSepa) = '' then
      raise Exception.CreateFmt(SErrorRemesaCompraSepaSinBeneficiario,
        [ARemesa.Efectos[iIndice].IdPago]);
    if Trim(ARemesa.Efectos[iIndice].IbanBeneficiario) = '' then
      raise Exception.CreateFmt(SErrorRemesaCompraSepaSinIbanBeneficiario,
        [ARemesa.Efectos[iIndice].NombreBeneficiario]);
  end;
end;

procedure EscribirEntidad(ASalida: TStringBuilder;
  AFormato: TFormatoSepaTransferencia; const ABic: string);
var
  sEtiqueta: string;
begin
  ASalida.Append('<FinInstnId>');
  if Trim(ABic) = '' then
    ASalida.Append('<Othr><Id>NOTPROVIDED</Id></Othr>')
  else
  begin
    sEtiqueta := 'BIC';
    if AFormato = fstPain00100109 then
      sEtiqueta := 'BICFI';
    ASalida.Append('<' + sEtiqueta + '>' +
      SoloAlfanumerico(ABic) + '</' + sEtiqueta + '>');
  end;
  ASalida.Append('</FinInstnId>');
end;

procedure EscribirCabecera(ASalida: TStringBuilder;
  const ARemesa: TRemesaSepaCompraValidada; ANumPagos: Integer;
  ATotal: Int64);
begin
  ASalida.Append('<GrpHdr>');
  ASalida.Append('<MsgId>' + ARemesa.IdMensaje + '</MsgId>');
  ASalida.Append('<CreDtTm>' + FormatearInstanteSepa(ARemesa.Instante,
    ARemesa.DesfaseUtcMinutos) + '</CreDtTm>');
  ASalida.Append('<NbOfTxs>' + IntToStr(ANumPagos) + '</NbOfTxs>');
  ASalida.Append('<CtrlSum>' + FormatearCentimos(ATotal) + '</CtrlSum>');
  ASalida.Append('<InitgPty><Nm>' +
    TextoSepa(ARemesa.NombreEmpresa, CLongitudNombreSepa) + '</Nm>');
  if ARemesa.IdOrdenante <> '' then
    ASalida.Append('<Id><OrgId><Othr><Id>' +
      SoloAlfanumerico(ARemesa.IdOrdenante) +
      '</Id></Othr></OrgId></Id>');
  ASalida.Append('</InitgPty>');
  ASalida.Append('</GrpHdr>');
end;

procedure EscribirPago(ASalida: TStringBuilder;
  const AEfecto: TEfectoSepaCompraValidado);
begin
  ASalida.Append('<CdtTrfTxInf>');
  ASalida.Append('<PmtId><EndToEndId>' + AEfecto.IdPago +
    '</EndToEndId></PmtId>');
  ASalida.Append('<Amt><InstdAmt Ccy="EUR">' +
    FormatearCentimos(ImporteEnCentimos(AEfecto.Importe)) +
    '</InstdAmt></Amt>');
  ASalida.Append('<Cdtr><Nm>' +
    TextoSepa(AEfecto.NombreBeneficiario, CLongitudNombreSepa) +
    '</Nm></Cdtr>');
  ASalida.Append('<CdtrAcct><Id><IBAN>' +
    SoloAlfanumerico(AEfecto.IbanBeneficiario) +
    '</IBAN></Id></CdtrAcct>');
  if TextoSepa(AEfecto.Concepto, CLongitudConceptoSepa) <> '' then
    ASalida.Append('<RmtInf><Ustrd>' +
      TextoSepa(AEfecto.Concepto, CLongitudConceptoSepa) +
      '</Ustrd></RmtInf>');
  ASalida.Append('</CdtTrfTxInf>');
end;

procedure EscribirBloquePago(ASalida: TStringBuilder;
  const ARemesa: TRemesaSepaCompraValidada; ANumPagos: Integer;
  ATotal: Int64);
var
  iIndice: Integer;
  sFecha: string;
begin
  sFecha := FormatDateTime('yyyy"-"mm"-"dd', ARemesa.FechaEjecucion);
  if ARemesa.Formato = fstPain00100109 then
    sFecha := '<Dt>' + sFecha + '</Dt>';
  ASalida.Append('<PmtInf>');
  ASalida.Append('<PmtInfId>' + ARemesa.IdMensaje + '</PmtInfId>');
  ASalida.Append('<PmtMtd>TRF</PmtMtd>');
  ASalida.Append('<NbOfTxs>' + IntToStr(ANumPagos) + '</NbOfTxs>');
  ASalida.Append('<CtrlSum>' + FormatearCentimos(ATotal) + '</CtrlSum>');
  ASalida.Append('<PmtTpInf><SvcLvl><Cd>SEPA</Cd></SvcLvl></PmtTpInf>');
  ASalida.Append('<ReqdExctnDt>' + sFecha + '</ReqdExctnDt>');
  ASalida.Append('<Dbtr><Nm>' +
    TextoSepa(ARemesa.NombreEmpresa, CLongitudNombreSepa) +
    '</Nm></Dbtr>');
  ASalida.Append('<DbtrAcct><Id><IBAN>' +
    SoloAlfanumerico(ARemesa.IbanEmpresa) + '</IBAN></Id></DbtrAcct>');
  ASalida.Append('<DbtrAgt>');
  EscribirEntidad(ASalida, ARemesa.Formato, ARemesa.BicEmpresa);
  ASalida.Append('</DbtrAgt>');
  ASalida.Append('<ChrgBr>SLEV</ChrgBr>');
  for iIndice := Low(ARemesa.Efectos) to High(ARemesa.Efectos) do
    EscribirPago(ASalida, ARemesa.Efectos[iIndice]);
  ASalida.Append('</PmtInf>');
end;

function ConstruirXmlSepaRemesaCompra(
  const ARemesa: TRemesaSepaCompraValidada;
  AHoy: TDateTime): string;
var
  iIndice: Integer;
  iTotal: Int64;
  oSalida: TStringBuilder;
begin
  ValidarRemesaSepaCompra(ARemesa, AHoy);
  iTotal := 0;
  for iIndice := Low(ARemesa.Efectos) to High(ARemesa.Efectos) do
    iTotal := iTotal + ImporteEnCentimos(ARemesa.Efectos[iIndice].Importe);
  oSalida := TStringBuilder.Create;
  try
    oSalida.Append('<?xml version="1.0" encoding="UTF-8"?>');
    oSalida.Append(sLineBreak);
    oSalida.Append('<Document xmlns="urn:iso:std:iso:20022:tech:xsd:' +
      NombreFormatoSepaTransferencia(ARemesa.Formato) + '" ' +
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
    oSalida.Append('<CstmrCdtTrfInitn>');
    EscribirCabecera(oSalida, ARemesa, Length(ARemesa.Efectos), iTotal);
    EscribirBloquePago(oSalida, ARemesa, Length(ARemesa.Efectos), iTotal);
    oSalida.Append('</CstmrCdtTrfInitn>');
    oSalida.Append('</Document>');
    oSalida.Append(sLineBreak);
    Result := oSalida.ToString;
  finally
    FreeAndNil(oSalida);
  end;
end;

function GenerarSepaRemesaCompra(
  const ARemesa: TRemesaSepaCompraValidada;
  const AArchivo: string): TResultadoSepaRemesaCompra;
var
  iIndice: Integer;
  sCarpeta: string;
  sXml: string;
begin
  Result.Archivo := Trim(AArchivo);
  Result.NumPagos := Length(ARemesa.Efectos);
  Result.Total := 0;
  if Result.Archivo = '' then
    raise Exception.Create(SErrorRemesaCompraSepaSinArchivo);
  sXml := ConstruirXmlSepaRemesaCompra(ARemesa, Date);
  for iIndice := Low(ARemesa.Efectos) to High(ARemesa.Efectos) do
    Result.Total := Result.Total +
      ImporteEnCentimos(ARemesa.Efectos[iIndice].Importe) / 100;
  sCarpeta := ExtractFilePath(Result.Archivo);
  if (sCarpeta <> '') and (not DirectoryExists(sCarpeta)) then
    ForceDirectories(sCarpeta);
  // UTF-8 sin BOM: algunos bancos rechazan el preámbulo.
  TFile.WriteAllBytes(Result.Archivo, TEncoding.UTF8.GetBytes(sXml));
end;

end.
