{******************************************************************************}
{                                                                              }
{  Módulo: inLibComparativaVentasInforme                                       }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit inLibComparativaVentasInforme;

interface

uses
  Data.DB, Datasnap.DBClient, inLibComparativaVentasIntf,
  inLibInformeTabular;

procedure CargarComparativaInforme(ADatos: TClientDataSet;
  const AFilas: TFilasComparativaVentas);
function ColumnasComparativaInforme: TColumnasInformeTabular;

implementation

uses
  inLibMsgInformesCliente,
  System.SysUtils, inLibComparativaVentas;

function ColumnasComparativaInforme: TColumnasInformeTabular;
begin
  Result := [
    ColumnaInforme('FECHA', SInformeFechaActual, 1.6),
    ColumnaInforme('VENTA', SInformeVenta, 1, '%2.2n'),
    ColumnaInforme('ACUMULADO', SInformeVentaAcumulada, 1.1, '%2.2n'),
    ColumnaInforme('UNIDADES', SInformeUnidades, 0.7, '%g'),
    ColumnaInforme('UDS_ACUM', SInformeUnidadesAcumuladas, 0.8, '%g'),
    ColumnaInforme('FECHA_ANT', SInformeFechaAnterior, 1.6),
    ColumnaInforme('VENTA_ANT', SInformeVentaAnterior, 1, '%2.2n'),
    ColumnaInforme('ACUM_ANT', SInformeVentaAcumuladaAnterior, 1.1, '%2.2n'),
    ColumnaInforme('UNIDADES_ANT', SInformeUnidadesAnterior, 0.7, '%g'),
    ColumnaInforme('UDS_ACUM_ANT',
      SInformeUnidadesAcumuladasAnterior, 0.8, '%g'),
    ColumnaInforme('VAR_VENTA', SInformeVariacionVenta, 0.9, '%2.2n'),
    ColumnaInforme('VAR_UDS', SInformeVariacionUnidades, 0.9, '%2.2n')];
end;

procedure CrearCamposComparativa(ADatos: TClientDataSet);
var
  oColumna: TColumnaInformeTabular;
begin
  ADatos.Close;
  ADatos.FieldDefs.Clear;
  for oColumna in ColumnasComparativaInforme do
    if oColumna.Numerica then
      ADatos.FieldDefs.Add(oColumna.Campo, ftFloat)
    else
      ADatos.FieldDefs.Add(oColumna.Campo, ftString, 40);
  ADatos.CreateDataSet;
end;

procedure PonerVariacion(ADatos: TDataSet; const ACampo: string;
  AActual, AAnterior: Double);
var
  dPorcentaje: Double;
begin
  if VariacionComparativa(AActual, AAnterior, dPorcentaje) then
    ADatos.FieldByName(ACampo).AsFloat := dPorcentaje
  else
    ADatos.FieldByName(ACampo).Clear;
end;

procedure AnadirFilaComparativa(ADatos: TDataSet;
  const AFila: TFilaComparativaVentas; AEsTotal: Boolean);
begin
  ADatos.Append;
  if AEsTotal then
    ADatos.FieldByName('FECHA').AsString := SInformeTotal
  else
  begin
    if AFila.TieneFecha then
      ADatos.FieldByName('FECHA').AsString :=
        FormatDateTime('dd/mm/yyyy ddd', AFila.Fecha);
    if AFila.TieneFechaAnterior then
      ADatos.FieldByName('FECHA_ANT').AsString :=
        FormatDateTime('dd/mm/yyyy ddd', AFila.FechaAnterior);
  end;
  if AFila.TieneFecha or AEsTotal then
  begin
    ADatos.FieldByName('VENTA').AsCurrency := AFila.Venta;
    ADatos.FieldByName('UNIDADES').AsFloat := AFila.Unidades;
  end;
  if AFila.TieneFechaAnterior or AEsTotal then
  begin
    ADatos.FieldByName('VENTA_ANT').AsCurrency := AFila.VentaAnterior;
    ADatos.FieldByName('UNIDADES_ANT').AsFloat := AFila.UnidadesAnterior;
  end;
  ADatos.FieldByName('ACUMULADO').AsCurrency := AFila.Acumulado;
  ADatos.FieldByName('ACUM_ANT').AsCurrency := AFila.AcumuladoAnterior;
  ADatos.FieldByName('UDS_ACUM').AsFloat := AFila.UnidadesAcumuladas;
  ADatos.FieldByName('UDS_ACUM_ANT').AsFloat :=
    AFila.UnidadesAcumuladasAnterior;
  if (AFila.TieneFecha and AFila.TieneFechaAnterior) or AEsTotal then
  begin
    PonerVariacion(ADatos, 'VAR_VENTA', AFila.Venta, AFila.VentaAnterior);
    PonerVariacion(ADatos, 'VAR_UDS', AFila.Unidades, AFila.UnidadesAnterior);
  end;
  ADatos.Post;
end;

procedure CargarComparativaInforme(ADatos: TClientDataSet;
  const AFilas: TFilasComparativaVentas);
var
  oFila, oTotal: TFilaComparativaVentas;
begin
  CrearCamposComparativa(ADatos);
  ADatos.DisableControls;
  try
    oTotal := Default(TFilaComparativaVentas);
    for oFila in AFilas do
    begin
      AnadirFilaComparativa(ADatos, oFila, False);
      oTotal := oFila;
    end;
    oTotal.Venta := oTotal.Acumulado;
    oTotal.VentaAnterior := oTotal.AcumuladoAnterior;
    oTotal.Unidades := oTotal.UnidadesAcumuladas;
    oTotal.UnidadesAnterior := oTotal.UnidadesAcumuladasAnterior;
    AnadirFilaComparativa(ADatos, oTotal, True);
    ADatos.First;
  finally
    ADatos.EnableControls;
  end;
end;

end.
