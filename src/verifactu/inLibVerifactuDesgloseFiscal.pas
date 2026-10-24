{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuDesgloseFiscal                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Construye el desglose fiscal Verifactu sin acceso a BBDD ni a la UI.      }
{******************************************************************************}
unit inLibVerifactuDesgloseFiscal;

interface

type
  TBandaDesgloseFiscal = record
    Porcentaje: Currency;
    Base: Currency;
    Cuota: Currency;
    PorcentajeRecargo: Currency;
    CuotaRecargo: Currency;
    EsExenta: Boolean;
  end;

  TOperacionDesgloseFiscal = record
    Definida: Boolean;
    ClaveRegimen: string;
    Calificacion: string;
    OperacionExenta: string;
    RepercuteIva: Boolean;
    EsClienteUE: Boolean;
    EsClienteExtranjero: Boolean;
  end;

  TEntradaDesgloseFiscal = record
    Operacion: TOperacionDesgloseFiscal;
    Bandas: array[0..3] of TBandaDesgloseFiscal;
  end;

function ConstruirDesgloseFiscal(
  const AEntrada: TEntradaDesgloseFiscal): string;

implementation

uses
  System.SysUtils, inLibVerifactu;

type
  TReglasDesgloseFiscal = record
    ClaveRegimen: string;
    Calificacion: string;
    OperacionExenta: string;
    RepercuteIva: Boolean;
  end;

function ResolverReglasDesglose(
  const AOperacion: TOperacionDesgloseFiscal): TReglasDesgloseFiscal;
begin
  Result.ClaveRegimen := '01';
  Result.Calificacion := '';
  Result.OperacionExenta := '';
  Result.RepercuteIva := True;
  if AOperacion.Definida then
  begin
    if AOperacion.ClaveRegimen <> '' then
      Result.ClaveRegimen := AOperacion.ClaveRegimen;
    Result.Calificacion := AOperacion.Calificacion;
    Result.OperacionExenta := AOperacion.OperacionExenta;
    Result.RepercuteIva := AOperacion.RepercuteIva;
  end
  else if AOperacion.EsClienteExtranjero and
          (not AOperacion.EsClienteUE) then
  begin
    Result.OperacionExenta := 'E2';
    Result.RepercuteIva := False;
  end;
end;

function ConstruirCalificacionSinRepercusion(
  const AReglas: TReglasDesgloseFiscal): string;
begin
  if AReglas.OperacionExenta <> '' then
  begin
    Result := '<sum1:OperacionExenta>' +
      AReglas.OperacionExenta + '</sum1:OperacionExenta>';
  end
  else if AReglas.Calificacion <> '' then
  begin
    Result := '<sum1:CalificacionOperacion>' +
      AReglas.Calificacion + '</sum1:CalificacionOperacion>';
  end
  else
    Result := '<sum1:OperacionExenta>E1</sum1:OperacionExenta>';
end;

function ConstruirDetalleSinRepercusion(
  const AEntrada: TEntradaDesgloseFiscal;
  const AReglas: TReglasDesgloseFiscal): string;
var
  dBaseTotal: Currency;
  iBanda: Integer;
begin
  dBaseTotal := 0;
  for iBanda := Low(AEntrada.Bandas) to High(AEntrada.Bandas) do
    dBaseTotal := dBaseTotal + AEntrada.Bandas[iBanda].Base;
  Result :=
    '<sum1:DetalleDesglose>' +
    '<sum1:Impuesto>01</sum1:Impuesto>' +
    '<sum1:ClaveRegimen>' + AReglas.ClaveRegimen +
    '</sum1:ClaveRegimen>' +
    ConstruirCalificacionSinRepercusion(AReglas) +
    '<sum1:BaseImponibleOimporteNoSujeto>' +
    FormatearImporteVerifactu(dBaseTotal) +
    '</sum1:BaseImponibleOimporteNoSujeto>' +
    '</sum1:DetalleDesglose>';
end;

function ConstruirRecargoEquivalencia(
  const ABanda: TBandaDesgloseFiscal): string;
begin
  Result := '';
  if Abs(ABanda.CuotaRecargo) > 0.001 then
  begin
    Result :=
      '<sum1:TipoRecargoEquivalencia>' +
      FormatearImporteVerifactu(ABanda.PorcentajeRecargo) +
      '</sum1:TipoRecargoEquivalencia>' +
      '<sum1:CuotaRecargoEquivalencia>' +
      FormatearImporteVerifactu(ABanda.CuotaRecargo) +
      '</sum1:CuotaRecargoEquivalencia>';
  end;
end;

function ConstruirDetalleBanda(
  const ABanda: TBandaDesgloseFiscal;
  const AReglas: TReglasDesgloseFiscal): string;
var
  sCalificacion: string;
  sDetalle: string;
begin
  sDetalle := '<sum1:Impuesto>01</sum1:Impuesto>' +
    '<sum1:ClaveRegimen>' + AReglas.ClaveRegimen +
    '</sum1:ClaveRegimen>';
  if ABanda.EsExenta then
  begin
    sDetalle := sDetalle +
      '<sum1:OperacionExenta>E1</sum1:OperacionExenta>' +
      '<sum1:BaseImponibleOimporteNoSujeto>' +
      FormatearImporteVerifactu(ABanda.Base) +
      '</sum1:BaseImponibleOimporteNoSujeto>';
  end
  else
  begin
    sCalificacion := AReglas.Calificacion;
    if sCalificacion = '' then
      sCalificacion := 'S1';
    sDetalle := sDetalle +
      '<sum1:CalificacionOperacion>' + sCalificacion +
      '</sum1:CalificacionOperacion>' +
      '<sum1:TipoImpositivo>' +
      FormatearImporteVerifactu(ABanda.Porcentaje) +
      '</sum1:TipoImpositivo>' +
      '<sum1:BaseImponibleOimporteNoSujeto>' +
      FormatearImporteVerifactu(ABanda.Base) +
      '</sum1:BaseImponibleOimporteNoSujeto>' +
      '<sum1:CuotaRepercutida>' +
      FormatearImporteVerifactu(ABanda.Cuota) +
      '</sum1:CuotaRepercutida>' +
      ConstruirRecargoEquivalencia(ABanda);
  end;
  Result := '<sum1:DetalleDesglose>' + sDetalle +
    '</sum1:DetalleDesglose>';
end;

function BandaTieneImporte(
  const ABanda: TBandaDesgloseFiscal): Boolean;
begin
  Result := (Abs(ABanda.Base) > 0.001) or
    (Abs(ABanda.Cuota) > 0.001);
end;

function ConstruirDetalleCero: string;
begin
  Result := '<sum1:DetalleDesglose>' +
    '<sum1:Impuesto>01</sum1:Impuesto>' +
    '<sum1:ClaveRegimen>01</sum1:ClaveRegimen>' +
    '<sum1:CalificacionOperacion>S1</sum1:CalificacionOperacion>' +
    '<sum1:TipoImpositivo>0.00</sum1:TipoImpositivo>' +
    '<sum1:BaseImponibleOimporteNoSujeto>0.00' +
    '</sum1:BaseImponibleOimporteNoSujeto>' +
    '<sum1:CuotaRepercutida>0.00</sum1:CuotaRepercutida>' +
    '</sum1:DetalleDesglose>';
end;

function ConstruirDesgloseFiscal(
  const AEntrada: TEntradaDesgloseFiscal): string;
var
  iBanda: Integer;
  oReglas: TReglasDesgloseFiscal;
begin
  oReglas := ResolverReglasDesglose(AEntrada.Operacion);
  Result := '';
  if not oReglas.RepercuteIva then
    Result := ConstruirDetalleSinRepercusion(AEntrada, oReglas)
  else
  begin
    for iBanda := Low(AEntrada.Bandas) to High(AEntrada.Bandas) do
    begin
      if BandaTieneImporte(AEntrada.Bandas[iBanda]) then
      begin
        Result := Result +
          ConstruirDetalleBanda(AEntrada.Bandas[iBanda], oReglas);
      end;
    end;
  end;
  if Result = '' then
    Result := ConstruirDetalleCero;
end;

end.
