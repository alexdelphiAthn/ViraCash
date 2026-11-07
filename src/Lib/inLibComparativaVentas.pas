{******************************************************************************}
{                                                                              }
{  Módulo: inLibComparativaVentas                                              }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inLibComparativaVentas;

interface

uses
  inLibComparativaVentasIntf;

procedure ValidarComparativaVentas(const AFiltro: TFiltroComparativaVentas);
function VariacionComparativa(AActual, AAnterior: Double;
  out APorcentaje: Double): Boolean;
function CalcularComparativaVentas(const AFiltro: TFiltroComparativaVentas;
  const AActual, AAnterior: TVentasDiariasComparativa):
  TFilasComparativaVentas;
function NombreCriterioComparativa(ACriterio: TCriterioComparativaVentas):
  string;

implementation

uses
  inLibMsgInformesCliente,
  System.SysUtils, System.DateUtils, System.Math;

procedure ValidarIntervalo(ADesde, AHasta: TDateTime);
begin
  if (Trunc(ADesde) <= 0) or (Trunc(AHasta) <= 0) then
    raise EArgumentException.Create(SInformeFechasAmbosPeriodos);
  if Trunc(AHasta) < Trunc(ADesde) then
    raise EArgumentException.Create(SInformeFechasInvertidas);
  if DaysBetween(ADesde, AHasta) > 3660 then
    raise EArgumentException.Create(SInformePeriodoMaximo);
end;

procedure ValidarComparativaVentas(const AFiltro: TFiltroComparativaVentas);
begin
  ValidarIntervalo(AFiltro.Desde, AFiltro.Hasta);
  ValidarIntervalo(AFiltro.DesdeAnterior, AFiltro.HastaAnterior);
  if Trim(AFiltro.Empresa) = '' then
    raise EArgumentException.Create(SInformeFaltaEmpresa);
end;

function VariacionComparativa(AActual, AAnterior: Double;
  out APorcentaje: Double): Boolean;
begin
  Result := AAnterior <> 0;
  APorcentaje := 0;
  if Result then
    APorcentaje := (AActual - AAnterior) / Abs(AAnterior) * 100;
end;

procedure IncorporarVentas(var AFilas: TFilasComparativaVentas;
  const AVentas: TVentasDiariasComparativa; ADesde: TDateTime;
  ADias: Integer; AEsAnterior: Boolean);
var
  oVenta: TVentaDiariaComparativa;
  iDia: Integer;
begin
  for oVenta in AVentas do
  begin
    iDia := Trunc(oVenta.Fecha) - Trunc(ADesde);
    if (iDia >= 0) and (iDia < ADias) then
      if AEsAnterior then
      begin
        AFilas[iDia].VentaAnterior :=
          AFilas[iDia].VentaAnterior + oVenta.Venta;
        AFilas[iDia].UnidadesAnterior :=
          AFilas[iDia].UnidadesAnterior + oVenta.Unidades;
      end
      else
      begin
        AFilas[iDia].Venta := AFilas[iDia].Venta + oVenta.Venta;
        AFilas[iDia].Unidades := AFilas[iDia].Unidades + oVenta.Unidades;
      end;
  end;
end;

function CalcularComparativaVentas(const AFiltro: TFiltroComparativaVentas;
  const AActual, AAnterior: TVentasDiariasComparativa):
  TFilasComparativaVentas;
var
  i, iDias, iDiasAnterior: Integer;
  oAcumulado: TFilaComparativaVentas;
begin
  ValidarComparativaVentas(AFiltro);
  iDias := Trunc(AFiltro.Hasta) - Trunc(AFiltro.Desde) + 1;
  iDiasAnterior := Trunc(AFiltro.HastaAnterior) -
    Trunc(AFiltro.DesdeAnterior) + 1;
  SetLength(Result, Max(iDias, iDiasAnterior));
  for i := 0 to High(Result) do
  begin
    Result[i] := Default(TFilaComparativaVentas);
    Result[i].TieneFecha := i < iDias;
    Result[i].TieneFechaAnterior := i < iDiasAnterior;
    if Result[i].TieneFecha then
      Result[i].Fecha := Trunc(AFiltro.Desde) + i;
    if Result[i].TieneFechaAnterior then
      Result[i].FechaAnterior := Trunc(AFiltro.DesdeAnterior) + i;
  end;
  IncorporarVentas(Result, AActual, AFiltro.Desde, iDias, False);
  IncorporarVentas(Result, AAnterior, AFiltro.DesdeAnterior,
    iDiasAnterior, True);
  oAcumulado := Default(TFilaComparativaVentas);
  for i := 0 to High(Result) do
  begin
    oAcumulado.Venta := oAcumulado.Venta + Result[i].Venta;
    oAcumulado.VentaAnterior := oAcumulado.VentaAnterior +
      Result[i].VentaAnterior;
    oAcumulado.Unidades := oAcumulado.Unidades + Result[i].Unidades;
    oAcumulado.UnidadesAnterior := oAcumulado.UnidadesAnterior +
      Result[i].UnidadesAnterior;
    Result[i].Acumulado := oAcumulado.Venta;
    Result[i].AcumuladoAnterior := oAcumulado.VentaAnterior;
    Result[i].UnidadesAcumuladas := oAcumulado.Unidades;
    Result[i].UnidadesAcumuladasAnterior := oAcumulado.UnidadesAnterior;
  end;
end;

function NombreCriterioComparativa(ACriterio: TCriterioComparativaVentas):
  string;
begin
  case ACriterio of
    ccvFacturadoSinImpuestos:
      Result := SInformeSinImpuestos;
    ccvFacturadoConImpuestos:
      Result := SInformeConImpuestos;
    ccvIngresosCaja:
      Result := SInformeIngresosCaja;
  end;
end;

end.
