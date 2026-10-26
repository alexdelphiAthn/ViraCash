{******************************************************************************}
{  Módulo:       inLibComprasDirectasFiscal                                    }
{    Tipo:       Librería                                                      }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{******************************************************************************}
unit inLibComprasDirectasFiscal;

interface

uses
  inLibComprasDirectas, inLibVerifactuDesgloseFiscal;

type
  TRegistroCompraDirectaSii = record
    Modalidad: TModalidadCompraDirecta;
    NifEmpresa: string;
    NombreEmpresa: string;
    NifProveedor: string;
    NombreProveedor: string;
    Documento: string;
    Fecha: TDateTime;
    FechaContable: TDateTime;
    Descripcion: string;
    Total: Currency;
    BaseCompensacion: Currency;
    PorcentajeCompensacion: Currency;
    ImporteCompensacion: Currency;
    CuotaDeducible: Currency;
    Bandas: array[0..3] of TBandaDesgloseFiscal;
  end;

function ConstruirCompraDirectaSii(
  const AEntrada: TRegistroCompraDirectaSii): string;

function EnvolverAutofacturaVerifactu(const ANif, ANombre,
  ARegistro: string): string;

implementation

uses
  System.SysUtils, inLibSiiConstruccionEnvio;

function Escapar(const ATexto: string): string;
begin
  Result := StringReplace(ATexto, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

function Etiqueta(const ANombre, AValor: string): string;
begin
  Result := '<sii:' + ANombre + '>' + AValor + '</sii:' + ANombre + '>';
end;

function Importe(AValor: Currency): string;
begin
  Result := FormatFloat('0.00', AValor, TFormatSettings.Invariant);
end;

function DesgloseCompraSii(const AEntrada: TRegistroCompraDirectaSii): string;
var
  oBanda: TBandaDesgloseFiscal;
  sDetalle: string;
begin
  Result := '';
  if AEntrada.Modalidad = mcdReagp then
    Result := Etiqueta('DetalleIVA',
      Etiqueta('BaseImponible', Importe(AEntrada.BaseCompensacion)) +
      Etiqueta('PorcentCompensacionREAGYP',
        Importe(AEntrada.PorcentajeCompensacion)) +
      Etiqueta('ImporteCompensacionREAGYP',
        Importe(AEntrada.ImporteCompensacion)))
  else
    for oBanda in AEntrada.Bandas do
      if oBanda.Base <> 0 then
      begin
        sDetalle := Etiqueta('TipoImpositivo', Importe(oBanda.Porcentaje)) +
          Etiqueta('BaseImponible', Importe(oBanda.Base)) +
          Etiqueta('CuotaSoportada', Importe(oBanda.Cuota));
        if oBanda.CuotaRecargo <> 0 then
          sDetalle := sDetalle + Etiqueta('TipoRecargoEquivalencia',
            Importe(oBanda.PorcentajeRecargo)) +
            Etiqueta('CuotaRecargoEquivalencia', Importe(oBanda.CuotaRecargo));
        Result := Result + Etiqueta('DetalleIVA', sDetalle);
      end;
  Result := Etiqueta('DesgloseFactura', Etiqueta('DesgloseIVA', Result));
end;

function EnvolverAutofacturaVerifactu(const ANif, ANombre,
  ARegistro: string): string;
const
  NS = 'https://www2.agenciatributaria.gob.es/static_files/common/internet/' +
    'dep/aplicaciones/es/aeat/tike/cont/ws/';
begin
  Result := '<?xml version="1.0" encoding="UTF-8"?>' +
    '<soapenv:Envelope ' +
    'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
    'xmlns:sum="' + NS + 'SuministroLR.xsd" xmlns:sum1="' +
    NS + 'SuministroInformacion.xsd"><soapenv:Header/><soapenv:Body>' +
    '<sum:RegFactuSistemaFacturacion><sum:Cabecera><sum1:ObligadoEmision>' +
    '<sum1:NombreRazon>' + Escapar(ANombre) + '</sum1:NombreRazon>' +
    '<sum1:NIF>' + Escapar(ANif) + '</sum1:NIF>' +
    '</sum1:ObligadoEmision></sum:Cabecera><sum:RegistroFactura>' +
    ARegistro + '</sum:RegistroFactura></sum:RegFactuSistemaFacturacion>' +
    '</soapenv:Body></soapenv:Envelope>';
end;

function ConstruirCompraDirectaSii(
  const AEntrada: TRegistroCompraDirectaSii): string;
var
  oFiscal: TClasificacionFiscalCompraDirecta;
  sCabecera, sRegistro, sFactura: string;
begin
  oFiscal := ClasificarCompraDirecta(AEntrada.Modalidad);
  sCabecera := Etiqueta('Cabecera', Etiqueta('IDVersionSii', '1.1') +
    Etiqueta('Titular',
      Etiqueta('NombreRazon', Escapar(AEntrada.NombreEmpresa)) +
      Etiqueta('NIF', Escapar(AEntrada.NifEmpresa))) +
    Etiqueta('TipoComunicacion', 'A0'));
  sRegistro := Etiqueta('PeriodoLiquidacion',
    Etiqueta('Ejercicio', FormatDateTime('yyyy', AEntrada.FechaContable)) +
    Etiqueta('Periodo', FormatDateTime('mm', AEntrada.FechaContable))) +
    '<siiLR:IDFactura>' + Etiqueta('IDEmisorFactura',
      Etiqueta('NIF', Escapar(AEntrada.NifProveedor))) +
    Etiqueta('NumSerieFacturaEmisor', Escapar(AEntrada.Documento)) +
    Etiqueta('FechaExpedicionFacturaEmisor',
      FormatDateTime('dd-mm-yyyy', AEntrada.Fecha)) + '</siiLR:IDFactura>';
  sFactura := Etiqueta('TipoFactura', oFiscal.TipoFacturaSii) +
    Etiqueta('ClaveRegimenEspecialOTrascendencia', oFiscal.RegimenSii) +
    Etiqueta('ImporteTotal', Importe(AEntrada.Total)) +
    Etiqueta('DescripcionOperacion', Escapar(AEntrada.Descripcion)) +
    DesgloseCompraSii(AEntrada) +
    Etiqueta('Contraparte',
      Etiqueta('NombreRazon', Escapar(AEntrada.NombreProveedor)) +
      Etiqueta('NIF', Escapar(AEntrada.NifProveedor))) +
    Etiqueta('FechaRegContable',
      FormatDateTime('dd-mm-yyyy', AEntrada.FechaContable)) +
    Etiqueta('CuotaDeducible', Importe(AEntrada.CuotaDeducible));
  Result := '<siiLR:SuministroLRFacturasRecibidas xmlns:siiLR="' +
    cNsSiiSuministroLR + '" xmlns:sii="' +
    cNsSiiSuministroInformacion + '">' + sCabecera +
    '<siiLR:RegistroLRFacturasRecibidas>' + sRegistro +
    '<siiLR:FacturaRecibida>' + sFactura + '</siiLR:FacturaRecibida>' +
    '</siiLR:RegistroLRFacturasRecibidas>' +
    '</siiLR:SuministroLRFacturasRecibidas>';
end;

end.
