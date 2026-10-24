{******************************************************************************}
{                                                                              }
{  Modulo:       inLibVerifactuNoVerifactuExport                               }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       15/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exportacion local de registros NO VERI*FACTU: eventos y facturacion.      }
{    Empaqueta los XML oficiales firmados al crear cada registro.              }
{******************************************************************************}
unit inLibVerifactuNoVerifactuExport;

interface

uses
  System.SysUtils, Uni, inLibParametrosIntf,
  inLibVerifactuNoVerifactuExportIntf, inLibLogIntf;

type
  TResultadoExportacionNoVerifactu = record
    ArchivoEventos:     string;
    ArchivoFacturacion: string;
    Eventos:            Integer;
    RegistrosFactura:   Integer;
    TitularCertificado: string;
    SerieCertificado:   string;
  end;

function ExportarRegistrosNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const ARepositorio:
                                      IRepositorioExportacionNoVerifactu;
                                      AConn: TUniConnection;
                                      const AUsuario: string;
                                      const AArchivoBase: string;
                                      const ARegistroLog: IRegistroLog):
                                      TResultadoExportacionNoVerifactu;

implementation

uses
  System.Classes, System.IOUtils, System.Hash, System.NetEncoding, Data.DB,
  inLibGlobalVar, inLibMsgVerifactu, inLibVerifactu;

const
  cNsViraCashNoVerifactu = 'urn:factuzam:no-verifactu:v1';

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function ValorCampo(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := oCampo.AsString;
end;

function ValorFechaIso(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADataSet.FindField(ACampo);
  if (oCampo <> nil) and (not oCampo.IsNull) then
    Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', oCampo.AsDateTime);
end;

function CDataXml(const AValor: string): string;
begin
  Result := '<![CDATA[' +
            StringReplace(AValor, ']]>', ']]]]><![CDATA[>',
                          [rfReplaceAll]) +
            ']]>';
end;

procedure AgregarEtiqueta(ASb: TStringBuilder; const ANombre,
                          AValor: string);
begin
  ASb.Append('<fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
  ASb.Append(EscaparXml(AValor));
  ASb.Append('</fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
end;

procedure AgregarEtiquetaCData(ASb: TStringBuilder; const ANombre,
                               AValor: string);
begin
  ASb.Append('<fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
  ASb.Append(CDataXml(AValor));
  ASb.Append('</fz:');
  ASb.Append(ANombre);
  ASb.Append('>');
end;

function Sha256Base64(const AValor: string): string;
var
  aHash: TBytes;
  sHex: string;
  i: Integer;
begin
  sHex := THashSHA2.GetHashString(AValor);
  SetLength(aHash, Length(sHex) div 2);
  for i := 0 to Length(aHash) - 1 do
    aHash[i] := StrToIntDef('$' + Copy(sHex, (i * 2) + 1, 2), 0);
  Result := TNetEncoding.Base64.EncodeBytesToString(aHash);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '', [rfReplaceAll]);
end;

function FechaHoraExportacion: string;
begin
  Result := FormatDateTime('yyyymmdd_hhnnss', Now);
end;

function FechaHoraIsoAhora: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', Now);
end;

function ColumnasFirmaEventosDisponibles(
  const ARepositorio: IRepositorioExportacionNoVerifactu): Boolean;
begin
  Result := ARepositorio.ColumnasFirmaEventosDisponibles;
end;

function ColumnasFirmaFacturacionDisponibles(
  const ARepositorio: IRepositorioExportacionNoVerifactu): Boolean;
begin
  Result := ARepositorio.ColumnasFirmaFacturacionDisponibles;
end;

function ContarEventosSinFirma(
  const ARepositorio: IRepositorioExportacionNoVerifactu): Integer;
begin
  Result := ARepositorio.ContarEventosSinFirma;
end;

function ContarFacturasSinFirma(
  const ARepositorio: IRepositorioExportacionNoVerifactu): Integer;
begin
  Result := ARepositorio.ContarFacturasSinFirma;
end;

procedure RegistrarIncidenciaExportacionSeguro(
                                               const AParametrosApp:
                                               IParametrosAplicacion;
                                               AConn: TUniConnection;
                                               const AUsuario: string;
                                               const AMensaje: string;
                                               const ARegistroLog:
                                               IRegistroLog);
begin
  try
    RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
      cEventoNoVerifactuIncidenciaCert,
      'Exportación NO VERI*FACTU bloqueada', AMensaje);
  except
    on E: Exception do
    begin
      // La incidencia principal ya queda en el error que se muestra.
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarError(
          'No se pudo registrar el evento NO VERI*FACTU: ' +
          E.Message);
    end;
  end;
end;

procedure ValidarExportacionLegalNoVerifactu(
  const AParametrosApp: IParametrosAplicacion;
  AConn: TUniConnection;
  const AUsuario: string;
  const ARepositorio: IRepositorioExportacionNoVerifactu;
  const ARegistroLog: IRegistroLog);
var
  iEventos:  Integer;
  iFacturas: Integer;
  sError:    string;
begin
  if NoVerifactuActivo(AParametrosApp) then
  begin
    sError := '';
    if not VerifactuFirmaCertificado(AParametrosApp) then
      sError := SErrorExportarNoVerifactuSinCertificado
    else if not ColumnasFirmaEventosDisponibles(ARepositorio) then
      sError := SErrorExportarNoVerifactuSinColumnasEventos
    else if not ColumnasFirmaFacturacionDisponibles(ARepositorio) then
      sError := SErrorExportarNoVerifactuSinColumnasFacturacion
    else
    begin
      iEventos := ContarEventosSinFirma(ARepositorio);
      iFacturas := ContarFacturasSinFirma(ARepositorio);
      if (iEventos > 0) or (iFacturas > 0) then
        sError := Format(SErrorExportarNoVerifactuRegistrosSinFirma,
          [iEventos, iFacturas]);
    end;
    if sError <> '' then
    begin
      RegistrarIncidenciaExportacionSeguro(AParametrosApp, AConn,
        AUsuario, sError, ARegistroLog);
      raise Exception.Create(sError);
    end;
  end;
end;

function ConstruirXmlEventos(
                             const AParametrosApp: IParametrosAplicacion;
                             const ARepositorio:
                             IRepositorioExportacionNoVerifactu;
                             const AUsuario: string;
                             out ATotal: Integer):
  string;
var
  Qry: TDataSet;
  Sb: TStringBuilder;
begin
  ATotal := 0;
  Sb := TStringBuilder.Create;
  Qry := ARepositorio.BuscarEventos;
  try
    Sb.Append('<?xml version="1.0" encoding="UTF-8"?>');
    Sb.Append('<fz:RegistroEventosNoVerifactu xmlns:fz="');
    Sb.Append(cNsViraCashNoVerifactu);
    Sb.Append('" Generado="');
    Sb.Append(EscaparXml(FechaHoraIsoAhora));
    Sb.Append('" VersionFactuzam="');
    Sb.Append(EscaparXml(oVersion));
    Sb.Append('" UsuarioExportacion="');
    Sb.Append(EscaparXml(AUsuario));
    Sb.Append('" ModoVerifactu="');
    Sb.Append(EscaparXml(ModoVerifactuTexto(AParametrosApp)));
    Sb.Append('">');
    while not Qry.Eof do
    begin
      Inc(ATotal);
      Sb.Append('<fz:Evento>');
      AgregarEtiqueta(Sb, 'Id', ValorCampo(Qry, 'ID_LOG'));
      AgregarEtiqueta(Sb, 'Instante',
                      ValorFechaIso(Qry, 'TIMESTAMP_LOG'));
      AgregarEtiqueta(Sb, 'Tipo', ValorCampo(Qry, 'TIPO_EVENTO_LOG'));
      AgregarEtiqueta(Sb, 'Usuario', ValorCampo(Qry, 'USUARIO_LOG'));
      AgregarEtiqueta(Sb, 'Version', ValorCampo(Qry, 'VERSION_LOG'));
      AgregarEtiquetaCData(Sb, 'Descripcion',
                           ValorCampo(Qry, 'DESCRIPCION_LOG'));
      AgregarEtiquetaCData(Sb, 'DatosAdicionales',
                           ValorCampo(Qry, 'DATOS_ADICIONALES_LOG'));
      AgregarEtiqueta(Sb, 'SerieFactura',
                      ValorCampo(Qry, 'SERIE_FAC_LOG'));
      AgregarEtiqueta(Sb, 'NumeroFactura',
                      ValorCampo(Qry, 'NUMERO_FAC_LOG'));
      AgregarEtiqueta(Sb, 'HashAnterior',
                      ValorCampo(Qry, 'HASH_ANTERIOR_LOG'));
      AgregarEtiqueta(Sb, 'HashPropio',
                      ValorCampo(Qry, 'HASH_PROPIO_LOG'));
      AgregarEtiqueta(Sb, 'FirmaDigital',
                      ValorCampo(Qry, 'FIRMA_DIGITAL_LOG'));
      AgregarEtiquetaCData(Sb, 'RegistroXmlFirmado',
                           ValorCampo(Qry, 'REGISTRO_XML_LOG'));
      AgregarEtiquetaCData(Sb, 'FirmaXades',
                           ValorCampo(Qry, 'FIRMA_XADES_LOG'));
      AgregarEtiqueta(Sb, 'SerieCertificado',
                      ValorCampo(Qry, 'SERIE_CERTIFICADO_LOG'));
      AgregarEtiqueta(Sb, 'TitularCertificado',
                      ValorCampo(Qry, 'TITULAR_CERTIFICADO_LOG'));
      AgregarEtiqueta(Sb, 'HuellaCertificado',
                      ValorCampo(Qry, 'HUELLA_CERTIFICADO_LOG'));
      Sb.Append('</fz:Evento>');
      Qry.Next;
    end;
    Sb.Append('</fz:RegistroEventosNoVerifactu>');
    Result := Sb.ToString;
  finally
    FreeAndNil(Qry);
    FreeAndNil(Sb);
  end;
end;

function ConstruirXmlFacturacion(
                                 const AParametrosApp:
                                 IParametrosAplicacion;
                                 const ARepositorio:
                                 IRepositorioExportacionNoVerifactu;
                                 const AUsuario: string;
                                 out ATotal: Integer):
  string;
var
  Qry: TDataSet;
  Sb: TStringBuilder;
  sPeticion: string;
  sRegistroXml: string;
begin
  ATotal := 0;
  Sb := TStringBuilder.Create;
  Qry := ARepositorio.BuscarFacturacion;
  try
    Sb.Append('<?xml version="1.0" encoding="UTF-8"?>');
    Sb.Append('<fz:RegistroFacturacionNoVerifactu xmlns:fz="');
    Sb.Append(cNsViraCashNoVerifactu);
    Sb.Append('" Generado="');
    Sb.Append(EscaparXml(FechaHoraIsoAhora));
    Sb.Append('" VersionFactuzam="');
    Sb.Append(EscaparXml(oVersion));
    Sb.Append('" UsuarioExportacion="');
    Sb.Append(EscaparXml(AUsuario));
    Sb.Append('" ModoVerifactu="');
    Sb.Append(EscaparXml(ModoVerifactuTexto(AParametrosApp)));
    Sb.Append('">');
    while not Qry.Eof do
    begin
      Inc(ATotal);
      sPeticion := ValorCampo(Qry, 'PETICION_COMPLETA_FACCON');
      sRegistroXml := ValorCampo(Qry, 'REGISTRO_XML_FACCON');
      Sb.Append('<fz:RegistroFactura>');
      AgregarEtiqueta(Sb, 'Id', ValorCampo(Qry, 'ID_FACCON'));
      AgregarEtiqueta(Sb, 'Serie', ValorCampo(Qry, 'SERIE_FAC_FACCON'));
      AgregarEtiqueta(Sb, 'Numero',
                      ValorCampo(Qry, 'NUMERO_FAC_FACCON'));
      AgregarEtiqueta(Sb, 'Estado', ValorCampo(Qry, 'ESTADO_FACCON'));
      AgregarEtiqueta(Sb, 'FechaFactura', ValorFechaIso(Qry, 'FECHA_FAC'));
      AgregarEtiqueta(Sb, 'TipoFactura', ValorCampo(Qry, 'TIPO_FAC'));
      AgregarEtiqueta(Sb, 'NifEmisor',
                      ValorCampo(Qry, 'NIF_EMPRESA_FAC'));
      AgregarEtiqueta(Sb, 'NombreEmisor',
                      ValorCampo(Qry, 'RAZON_SOCIAL_EMPRESA_FAC'));
      AgregarEtiqueta(Sb, 'NifCliente',
                      ValorCampo(Qry, 'NIF_CLIENTE_FAC'));
      AgregarEtiqueta(Sb, 'NombreCliente',
                      ValorCampo(Qry, 'RAZON_SOCIAL_CLIENTE_FAC'));
      AgregarEtiqueta(Sb, 'TotalLiquido',
                      ValorCampo(Qry, 'TOTAL_LIQUIDO_FAC'));
      AgregarEtiqueta(Sb, 'TotalImpuestos',
                      ValorCampo(Qry, 'TOTAL_IMPUESTOS_FAC'));
      AgregarEtiqueta(Sb, 'NifCadena',
                      ValorCampo(Qry,
                                 'ISSUER_IRS_ID_CONSOLIDACION_FACCON'));
      AgregarEtiqueta(Sb, 'FechaEmisionRegistro',
                      ValorFechaIso(Qry, 'ISSUED_TIME_FACCON'));
      AgregarEtiqueta(Sb, 'FechaProceso',
                      ValorFechaIso(Qry,
                                    'FECHA_PROCESAMIENTO_FACCON'));
      AgregarEtiqueta(Sb, 'NumeroCadena',
                      ValorCampo(Qry, 'CHAIN_NUMBER_FACCON'));
      AgregarEtiqueta(Sb, 'HashCadena',
                      ValorCampo(Qry, 'CHAIN_HASH_FACCON'));
      AgregarEtiqueta(Sb, 'IdColaAlta',
                      ValorCampo(Qry, 'QUEUE_ID_CONSOLIDACION_FACCON'));
      AgregarEtiqueta(Sb, 'IdColaAnulacion',
                      ValorCampo(Qry, 'QUEUE_ID_CANCEL_FACCON'));
      AgregarEtiqueta(Sb, 'RequestId',
                      ValorCampo(Qry,
                                 'REQUEST_ID_CONSOLIDACION_FACCON'));
      AgregarEtiqueta(Sb, 'HashPeticionBase64', Sha256Base64(sPeticion));
      AgregarEtiqueta(Sb, 'HashRegistroXmlBase64',
                      Sha256Base64(sRegistroXml));
      AgregarEtiquetaCData(Sb, 'RegistroXmlFirmado', sRegistroXml);
      AgregarEtiquetaCData(Sb, 'FirmaDigitalXades',
                           ValorCampo(Qry, 'FIRMA_DIGITAL_FACCON'));
      AgregarEtiqueta(Sb, 'SerieCertificado',
                      ValorCampo(Qry, 'SERIE_CERTIFICADO_FACCON'));
      AgregarEtiqueta(Sb, 'TitularCertificado',
                      ValorCampo(Qry, 'TITULAR_CERTIFICADO_FACCON'));
      AgregarEtiqueta(Sb, 'HuellaCertificado',
                      ValorCampo(Qry, 'HUELLA_CERTIFICADO_FACCON'));
      if sPeticion <> '' then
        AgregarEtiquetaCData(Sb, 'PeticionCompletaXml', sPeticion)
      else
        AgregarEtiqueta(Sb, 'Aviso',
                        'Registro sin PETICION_COMPLETA_FACCON guardada');
      Sb.Append('</fz:RegistroFactura>');
      Qry.Next;
    end;
    Sb.Append('</fz:RegistroFacturacionNoVerifactu>');
    Result := Sb.ToString;
  finally
    FreeAndNil(Qry);
    FreeAndNil(Sb);
  end;
end;

function NombreArchivoConSufijo(const AArchivoBase, ASufijo: string):
  string;
var
  sDirectorio: string;
  sNombre: string;
begin
  sDirectorio := TPath.GetDirectoryName(AArchivoBase);
  sNombre := TPath.GetFileNameWithoutExtension(AArchivoBase);
  if sNombre = '' then
    sNombre := 'NoVerifactu_' + FechaHoraExportacion;
  Result := TPath.Combine(sDirectorio, sNombre + ASufijo + '.xml');
end;

procedure GuardarTextoUtf8(const AArchivo, ATexto: string);
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(AArchivo));
  TFile.WriteAllText(AArchivo, ATexto, TEncoding.UTF8);
end;

function ExportarRegistrosNoVerifactu(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      const ARepositorio:
                                      IRepositorioExportacionNoVerifactu;
                                      AConn: TUniConnection;
                                      const AUsuario: string;
                                      const AArchivoBase: string;
                                      const ARegistroLog: IRegistroLog):
                                      TResultadoExportacionNoVerifactu;
var
  sXmlEventos: string;
  sXmlFacturacion: string;
begin
  if AConn = nil then
    raise Exception.Create(SErrorConexionExportarNoVerifactu);
  if Trim(AArchivoBase) = '' then
    raise Exception.Create(SErrorArchivoBaseExportacionNoIndicado);
  ValidarExportacionLegalNoVerifactu(
    AParametrosApp,
    AConn,
    AUsuario,
    ARepositorio,
    ARegistroLog);
  Result.TitularCertificado := '';
  Result.SerieCertificado := '';
  Result.ArchivoEventos := NombreArchivoConSufijo(AArchivoBase, '_eventos');
  Result.ArchivoFacturacion := NombreArchivoConSufijo(AArchivoBase,
                                                       '_facturacion');
  RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
    cEventoNoVerifactuExportFact,
    'Exportación de registros de facturación NO VERI*FACTU',
    Result.ArchivoFacturacion);
  RegistrarEventoVerifactu(AParametrosApp, AConn, AUsuario,
    cEventoNoVerifactuExportEventos,
    'Exportación de registros de eventos NO VERI*FACTU',
    Result.ArchivoEventos);
  sXmlEventos := ConstruirXmlEventos(AParametrosApp, ARepositorio, AUsuario,
    Result.Eventos);
  sXmlFacturacion := ConstruirXmlFacturacion(
    AParametrosApp,
    ARepositorio,
    AUsuario,
    Result.RegistrosFactura);
  GuardarTextoUtf8(Result.ArchivoEventos, sXmlEventos);
  GuardarTextoUtf8(Result.ArchivoFacturacion, sXmlFacturacion);
end;

end.
