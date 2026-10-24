{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuRegistroEventos                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina y construye eventos fiscales sin conocer su persistencia.        }
{******************************************************************************}
unit inLibVerifactuRegistroEventos;

interface

uses
  System.SysUtils;

type
  TEmpresaRegistroEventoVerifactu = record
    NifObligado: string;
    NombreObligado: string;
    SerialCertificado: string;
    TitularCertificado: string;
    NifProductor: string;
    NombreProductor: string;
    IdInstalacion: string;
    VersionInstalacion: string;
    CodigoSifInstalacion: string;
    EsMultiOt: string;
  end;

  TEventoAnteriorVerifactu = record
    EsPrimero: Boolean;
    TipoEvento: Integer;
    Instante: TDateTime;
    Huella: string;
  end;

  TSolicitudRegistroEventoVerifactu = record
    EsNoVerifactu: Boolean;
    FirmarCertificado: Boolean;
    InstanteRegistro: TDateTime;
    InstanteEvento: TDateTime;
    Version: string;
    Usuario: string;
    TipoEvento: Integer;
    Descripcion: string;
    DatosAdicionales: string;
    SerieFactura: string;
    NumeroFactura: string;
  end;

  TFirmaRegistroEventoVerifactu = record
    XmlFirmado: string;
    FirmaXades: string;
    FirmaDigital: string;
    SerieCertificado: string;
    TitularCertificado: string;
    HuellaCertificado: string;
  end;

  TRegistroEventoVerifactu = record
    TieneColumnasFirma: Boolean;
    Instante: string;
    TipoEvento: Integer;
    Usuario: string;
    Version: string;
    Descripcion: string;
    DatosAdicionales: string;
    HashAnterior: string;
    HashPropio: string;
    FirmaDigital: string;
    NumeroFactura: string;
    SerieFactura: string;
    Xml: string;
    FirmaXades: string;
    SerieCertificado: string;
    TitularCertificado: string;
    HuellaCertificado: string;
  end;

  IRepositorioRegistroEventosVerifactu = interface
    ['{A2ED9962-7271-4E7B-B2B3-B0B7D88C9A71}']
    function TieneColumnasFirma: Boolean;
    function CargarEmpresa: TEmpresaRegistroEventoVerifactu;
    function CargarAnterior: TEventoAnteriorVerifactu;
    procedure Guardar(const ARegistro: TRegistroEventoVerifactu);
  end;

  IValidadorRelojRegistroEventosVerifactu = interface
    ['{0D96AA2B-631C-44F2-87D4-711CAAB8F8AD}']
    procedure ExigirRelojFiscal;
  end;

  IFirmadorRegistroEventosVerifactu = interface
    ['{49BBC60E-C15E-467D-A423-52A8B9E78161}']
    function Firmar(
      const AXml, AHuella, ASerieCertificado,
      ATitularCertificado: string): TFirmaRegistroEventoVerifactu;
  end;

  IRegistroEventosVerifactu = interface
    ['{51F8FC5C-A1A7-45E0-8A68-4B57A456EB36}']
    procedure Registrar(
      const ASolicitud: TSolicitudRegistroEventoVerifactu);
  end;

function CrearRegistroEventosVerifactu(
  const ARepositorio: IRepositorioRegistroEventosVerifactu;
  const AValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
  const AFirmador: IFirmadorRegistroEventosVerifactu):
  IRegistroEventosVerifactu;

implementation

uses
  System.DateUtils, System.Hash, System.TimeSpan,
  inLibMsgVerifactu;

const
  cTipoEventoInicio = 101;
  cTipoEventoFin = 102;
  cTipoEventoExportarFacturas = 108;
  cTipoEventoExportarEventos = 109;
  cTipoEventoIncidenciaReloj = 111;
  cNsEventosSif =
    'https://www2.agenciatributaria.gob.es/static_files/common/internet/' +
    'dep/aplicaciones/es/aeat/tike/cont/ws/EventosSIF.xsd';
  cNsDsig = 'http://www.w3.org/2000/09/xmldsig#';

resourcestring
  SErrorFirmaCertificadoDesactivada =
    'El modo NO VERI*FACTU exige firma electrónica con certificado ' +
    'oficial. Active appVerifactuFirmaCertificado.';
  SErrorColumnasFirmaAusentes =
    'Faltan columnas de firma en fza_verifactu_eventos. Aplique el ' +
    'script DESARROLLOS EN CURSO\verifactu_registros_firmados.sql.';
  SErrorRepositorioEventosAusente =
    'El repositorio de eventos Verifactu es obligatorio.';
  SErrorValidadorRelojAusente =
    'El validador de reloj de eventos Verifactu es obligatorio.';
  SErrorFirmadorEventosAusente =
    'El firmador de eventos Verifactu es obligatorio.';

type
  TEstadoRegistroEventoVerifactu = record
    Empresa: TEmpresaRegistroEventoVerifactu;
    Anterior: TEventoAnteriorVerifactu;
    Registro: TRegistroEventoVerifactu;
    ErrorFirma: string;
    ErrorReloj: string;
    DebeFirmar: Boolean;
  end;

  TRegistroEventosVerifactu = class(
    TInterfacedObject,
    IRegistroEventosVerifactu)
  private
    FRepositorio: IRepositorioRegistroEventosVerifactu;
    FValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
    FFirmador: IFirmadorRegistroEventosVerifactu;
    function InicializarEstado(
      const ASolicitud: TSolicitudRegistroEventoVerifactu):
      TEstadoRegistroEventoVerifactu;
    procedure ComprobarReloj(
      const ASolicitud: TSolicitudRegistroEventoVerifactu;
      var AEstado: TEstadoRegistroEventoVerifactu);
    procedure ConfigurarFirma(
      const ASolicitud: TSolicitudRegistroEventoVerifactu;
      var AEstado: TEstadoRegistroEventoVerifactu);
    procedure ConstruirRegistro(
      const ASolicitud: TSolicitudRegistroEventoVerifactu;
      var AEstado: TEstadoRegistroEventoVerifactu);
    procedure FirmarRegistro(
      const ASolicitud: TSolicitudRegistroEventoVerifactu;
      var AEstado: TEstadoRegistroEventoVerifactu);
    procedure AplicarFalloFirma(
      const ASolicitud: TSolicitudRegistroEventoVerifactu;
      var AEstado: TEstadoRegistroEventoVerifactu);
    procedure NotificarErrorParcial(
      const ASolicitud: TSolicitudRegistroEventoVerifactu;
      const AEstado: TEstadoRegistroEventoVerifactu);
  public
    constructor Create(
      const ARepositorio: IRepositorioRegistroEventosVerifactu;
      const AValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
      const AFirmador: IFirmadorRegistroEventosVerifactu);
    procedure Registrar(
      const ASolicitud: TSolicitudRegistroEventoVerifactu);
  end;

function EscaparXml(const AValor: string): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function TextoEvento(const AValor: string): string;
begin
  Result := Trim(AValor);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  while Pos('  ', Result) > 0 do
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
  if Length(Result) > 100 then
    Result := Copy(Result, 1, 100);
end;

function AnadirIncidencia(const ADatos, ATipo,
  AMensaje: string): string;
begin
  Result := Trim(ADatos);
  if Result <> '' then
    Result := Result + ' | ';
  Result := Result + ATipo + '=' + Trim(AMensaje);
end;

function FechaHoraHuso(ADt: TDateTime): string;
var
  oDesfase: TTimeSpan;
  sSigno: string;
begin
  oDesfase := TTimeZone.Local.GetUtcOffset(ADt);
  if oDesfase.Ticks < 0 then
    sSigno := '-'
  else
    sSigno := '+';
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', ADt) + sSigno +
    Format('%.2d:%.2d', [Abs(oDesfase.Hours), Abs(oDesfase.Minutes)]);
end;

function TipoEventoAeat(ATipoEvento: Integer): string;
begin
  case ATipoEvento of
    cTipoEventoInicio:
      Result := '01';
    cTipoEventoFin:
      Result := '02';
    cTipoEventoExportarFacturas:
      Result := '08';
    cTipoEventoExportarEventos:
      Result := '09';
  else
    Result := '90';
  end;
end;

function ConstruirSistemaInformatico(
  const AEmpresa: TEmpresaRegistroEventoVerifactu;
  const AVersion: string): string;
begin
  Result :=
    '<sf:SistemaInformatico>' +
    '<sf:NombreRazon>' + EscaparXml(AEmpresa.NombreProductor) +
    '</sf:NombreRazon>' +
    '<sf:NIF>' + EscaparXml(AEmpresa.NifProductor) + '</sf:NIF>' +
    '<sf:NombreSistemaInformatico>ViraCash</sf:NombreSistemaInformatico>' +
    '<sf:IdSistemaInformatico>FZ</sf:IdSistemaInformatico>' +
    '<sf:Version>' + EscaparXml(AVersion) + '</sf:Version>' +
    '<sf:NumeroInstalacion>' + EscaparXml(AEmpresa.IdInstalacion) +
    '</sf:NumeroInstalacion>' +
    '<sf:TipoUsoPosibleSoloVerifactu>N</sf:TipoUsoPosibleSoloVerifactu>' +
    '<sf:TipoUsoPosibleMultiOT>S</sf:TipoUsoPosibleMultiOT>' +
    '<sf:IndicadorMultiplesOT>' + AEmpresa.EsMultiOt +
    '</sf:IndicadorMultiplesOT>' +
    '</sf:SistemaInformatico>';
end;

function ConstruirObligado(
  const AEmpresa: TEmpresaRegistroEventoVerifactu): string;
begin
  Result :=
    '<sf:ObligadoEmision>' +
    '<sf:NombreRazon>' + EscaparXml(AEmpresa.NombreObligado) +
    '</sf:NombreRazon>' +
    '<sf:NIF>' + EscaparXml(AEmpresa.NifObligado) + '</sf:NIF>' +
    '</sf:ObligadoEmision>';
end;

function ConstruirEncadenamiento(
  const AAnterior: TEventoAnteriorVerifactu): string;
begin
  if AAnterior.EsPrimero then
    Result := '<sf:Encadenamiento><sf:PrimerEvento>S</sf:PrimerEvento>' +
      '</sf:Encadenamiento>'
  else
    Result := '<sf:Encadenamiento><sf:EventoAnterior>' +
      '<sf:TipoEvento>' + TipoEventoAeat(AAnterior.TipoEvento) +
      '</sf:TipoEvento>' +
      '<sf:FechaHoraHusoGenEvento>' + FechaHoraHuso(AAnterior.Instante) +
      '</sf:FechaHoraHusoGenEvento>' +
      '<sf:HuellaEvento>' + AAnterior.Huella + '</sf:HuellaEvento>' +
      '</sf:EventoAnterior></sf:Encadenamiento>';
end;

function ConstruirXml(
  const AEmpresa: TEmpresaRegistroEventoVerifactu;
  const AAnterior: TEventoAnteriorVerifactu;
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  const ADatosAdicionales: string;
  out AHuella: string): string;
var
  sBaseHash: string;
  sFechaHuso: string;
  sOtros: string;
  sTipoAeat: string;
begin
  sTipoAeat := TipoEventoAeat(ASolicitud.TipoEvento);
  sFechaHuso := FechaHoraHuso(ASolicitud.InstanteEvento);
  sOtros := TextoEvento(ASolicitud.Descripcion + ' ' +
    ADatosAdicionales);
  sBaseHash := 'TipoEvento=' + sTipoAeat +
    '&FechaHoraHusoGenEvento=' + sFechaHuso +
    '&OtrosDatosEvento=' + sOtros +
    '&HuellaEventoAnterior=' + AAnterior.Huella;
  AHuella := UpperCase(THashSHA2.GetHashString(sBaseHash));
  Result := '<?xml version="1.0" encoding="UTF-8"?>' +
    '<sf:RegistroEvento xmlns:sf="' + cNsEventosSif +
    '" xmlns:ds="' + cNsDsig + '">' +
    '<sf:IDVersion>1.0</sf:IDVersion><sf:Evento>' +
    ConstruirSistemaInformatico(AEmpresa, ASolicitud.Version) +
    ConstruirObligado(AEmpresa) +
    '<sf:FechaHoraHusoGenEvento>' + sFechaHuso +
    '</sf:FechaHoraHusoGenEvento><sf:TipoEvento>' + sTipoAeat +
    '</sf:TipoEvento>';
  if sOtros <> '' then
    Result := Result + '<sf:OtrosDatosEvento>' + EscaparXml(sOtros) +
      '</sf:OtrosDatosEvento>';
  Result := Result + ConstruirEncadenamiento(AAnterior) +
    '<sf:TipoHuella>01</sf:TipoHuella><sf:HuellaEvento>' + AHuella +
    '</sf:HuellaEvento></sf:Evento></sf:RegistroEvento>';
end;

function TRegistroEventosVerifactu.InicializarEstado(
  const ASolicitud: TSolicitudRegistroEventoVerifactu):
  TEstadoRegistroEventoVerifactu;
begin
  Result := Default(TEstadoRegistroEventoVerifactu);
  Result.DebeFirmar := ASolicitud.FirmarCertificado;
  Result.Registro.TieneColumnasFirma :=
    FRepositorio.TieneColumnasFirma;
  Result.Registro.Instante := FormatDateTime(
    'yyyy-mm-dd hh:nn:ss.zzz', ASolicitud.InstanteRegistro);
  Result.Registro.TipoEvento := ASolicitud.TipoEvento;
  Result.Registro.Usuario := ASolicitud.Usuario;
  Result.Registro.Version := ASolicitud.Version;
  Result.Registro.Descripcion := ASolicitud.Descripcion;
  Result.Registro.DatosAdicionales := ASolicitud.DatosAdicionales;
  Result.Registro.NumeroFactura := ASolicitud.NumeroFactura;
  Result.Registro.SerieFactura := ASolicitud.SerieFactura;
end;

procedure TRegistroEventosVerifactu.ComprobarReloj(
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  var AEstado: TEstadoRegistroEventoVerifactu);
begin
  if ASolicitud.EsNoVerifactu and
     (ASolicitud.TipoEvento <> cTipoEventoIncidenciaReloj) then
  begin
    try
      FValidadorReloj.ExigirRelojFiscal;
    except
      on E: Exception do
      begin
        AEstado.ErrorReloj := E.Message;
        AEstado.Registro.DatosAdicionales := AnadirIncidencia(
          AEstado.Registro.DatosAdicionales,
          'INCIDENCIA_RELOJ', AEstado.ErrorReloj);
      end;
    end;
  end;
end;

procedure TRegistroEventosVerifactu.ConfigurarFirma(
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  var AEstado: TEstadoRegistroEventoVerifactu);
begin
  if ASolicitud.EsNoVerifactu and (not AEstado.DebeFirmar) then
    AEstado.ErrorFirma := SErrorFirmaCertificadoDesactivada;
  if AEstado.DebeFirmar and
     (not AEstado.Registro.TieneColumnasFirma) then
  begin
    AEstado.ErrorFirma := SErrorColumnasFirmaAusentes;
    AEstado.DebeFirmar := False;
  end;
  if AEstado.ErrorFirma <> '' then
    AEstado.Registro.DatosAdicionales := AnadirIncidencia(
      AEstado.Registro.DatosAdicionales,
      'INCIDENCIA_CERTIFICADO', AEstado.ErrorFirma);
end;

procedure TRegistroEventosVerifactu.ConstruirRegistro(
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  var AEstado: TEstadoRegistroEventoVerifactu);
begin
  AEstado.Anterior := FRepositorio.CargarAnterior;
  AEstado.Empresa := FRepositorio.CargarEmpresa;
  if AEstado.Anterior.EsPrimero then
    AEstado.Registro.HashAnterior := StringOfChar('0', 64)
  else
    AEstado.Registro.HashAnterior := AEstado.Anterior.Huella;
  AEstado.Registro.Xml := ConstruirXml(
    AEstado.Empresa, AEstado.Anterior, ASolicitud,
    AEstado.Registro.DatosAdicionales,
    AEstado.Registro.HashPropio);
  AEstado.Registro.FirmaDigital := AEstado.Registro.HashPropio;
end;

procedure TRegistroEventosVerifactu.AplicarFalloFirma(
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  var AEstado: TEstadoRegistroEventoVerifactu);
begin
  AEstado.Registro.DatosAdicionales := AnadirIncidencia(
    ASolicitud.DatosAdicionales,
    'INCIDENCIA_CERTIFICADO', AEstado.ErrorFirma);
  AEstado.Registro.Xml := ConstruirXml(
    AEstado.Empresa, AEstado.Anterior, ASolicitud,
    AEstado.Registro.DatosAdicionales,
    AEstado.Registro.HashPropio);
  AEstado.Registro.FirmaDigital := AEstado.Registro.HashPropio;
  AEstado.Registro.FirmaXades := '';
  AEstado.Registro.SerieCertificado := '';
  AEstado.Registro.TitularCertificado := '';
  AEstado.Registro.HuellaCertificado := '';
end;

procedure TRegistroEventosVerifactu.FirmarRegistro(
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  var AEstado: TEstadoRegistroEventoVerifactu);
var
  oFirma: TFirmaRegistroEventoVerifactu;
begin
  if AEstado.DebeFirmar then
  begin
    try
      if (Trim(AEstado.Empresa.SerialCertificado) = '') or
         (Trim(AEstado.Empresa.TitularCertificado) = '') then
        raise Exception.Create(
          SErrorCertificadoEventosNoVerifactuNoConfigurado);
      oFirma := FFirmador.Firmar(
        AEstado.Registro.Xml,
        AEstado.Registro.HashPropio,
        AEstado.Empresa.SerialCertificado,
        AEstado.Empresa.TitularCertificado);
      AEstado.Registro.Xml := oFirma.XmlFirmado;
      AEstado.Registro.FirmaXades := oFirma.FirmaXades;
      AEstado.Registro.FirmaDigital := oFirma.FirmaDigital;
      AEstado.Registro.SerieCertificado := oFirma.SerieCertificado;
      AEstado.Registro.TitularCertificado :=
        oFirma.TitularCertificado;
      AEstado.Registro.HuellaCertificado := oFirma.HuellaCertificado;
    except
      on E: Exception do
      begin
        AEstado.ErrorFirma := E.Message;
        AplicarFalloFirma(ASolicitud, AEstado);
      end;
    end;
  end;
end;

procedure TRegistroEventosVerifactu.NotificarErrorParcial(
  const ASolicitud: TSolicitudRegistroEventoVerifactu;
  const AEstado: TEstadoRegistroEventoVerifactu);
begin
  if ASolicitud.EsNoVerifactu and (AEstado.ErrorFirma <> '') then
    raise Exception.CreateFmt(
      SErrorFirmarEventoNoVerifactu, [AEstado.ErrorFirma]);
  if ASolicitud.EsNoVerifactu and (AEstado.ErrorReloj <> '') then
    raise Exception.CreateFmt(
      SErrorRelojEventoNoVerifactu, [AEstado.ErrorReloj]);
end;

constructor TRegistroEventosVerifactu.Create(
  const ARepositorio: IRepositorioRegistroEventosVerifactu;
  const AValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
  const AFirmador: IFirmadorRegistroEventosVerifactu);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create(SErrorRepositorioEventosAusente);
  if not Assigned(AValidadorReloj) then
    raise EArgumentNilException.Create(SErrorValidadorRelojAusente);
  if not Assigned(AFirmador) then
    raise EArgumentNilException.Create(SErrorFirmadorEventosAusente);
  FRepositorio := ARepositorio;
  FValidadorReloj := AValidadorReloj;
  FFirmador := AFirmador;
end;

procedure TRegistroEventosVerifactu.Registrar(
  const ASolicitud: TSolicitudRegistroEventoVerifactu);
var
  oEstado: TEstadoRegistroEventoVerifactu;
begin
  oEstado := InicializarEstado(ASolicitud);
  ComprobarReloj(ASolicitud, oEstado);
  ConfigurarFirma(ASolicitud, oEstado);
  ConstruirRegistro(ASolicitud, oEstado);
  FirmarRegistro(ASolicitud, oEstado);
  FRepositorio.Guardar(oEstado.Registro);
  NotificarErrorParcial(ASolicitud, oEstado);
end;

function CrearRegistroEventosVerifactu(
  const ARepositorio: IRepositorioRegistroEventosVerifactu;
  const AValidadorReloj: IValidadorRelojRegistroEventosVerifactu;
  const AFirmador: IFirmadorRegistroEventosVerifactu):
  IRegistroEventosVerifactu;
begin
  Result := TRegistroEventosVerifactu.Create(
    ARepositorio, AValidadorReloj, AFirmador);
end;

end.
