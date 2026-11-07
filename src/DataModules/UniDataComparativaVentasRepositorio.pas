{******************************************************************************}
{                                                                              }
{  Módulo: UniDataComparativaVentasRepositorio                                 }
{    Tipo: Informe de gestión                                                  }
{   Fecha: 07/11/2026                                                          }
{   Autor: Alejandro Laorden Hidalgo                                           }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{                                                                              }
{******************************************************************************}
unit UniDataComparativaVentasRepositorio;

interface

uses
  Uni, inLibComparativaVentasIntf;

function CrearRepositorioComparativaVentas(AConexion: TUniConnection):
  IRepositorioComparativaVentas;
// Se expone la consulta para verificar su contrato en un laboratorio aislado.
function SqlComparativaVentas(ACriterio: TCriterioComparativaVentas): string;

implementation

uses
  System.SysUtils, System.DateUtils, System.Generics.Collections,
  UniDataRectificativasSql;

type
  TRepositorioComparativaVentas = class(TInterfacedObject,
    IRepositorioComparativaVentas)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function Consultar(const AFiltro: TFiltroComparativaVentas;
      ADesde, AHasta: TDateTime): TVentasDiariasComparativa;
  end;

function SqlOrigenIngresosComparativa: string;
begin
  // El mismo criterio VE/DV/DE del histórico de operaciones de venta.
  // Los pagos se suman antes de unir líneas para no multiplicar las unidades.
  Result :=
    ' JOIN (SELECT OC.CODIGO_EMP_OPCAJA, OC.CODIGO_ALM_OPCAJA,' +
    ' OC.CODIGO_CAJA_OPCAJA, OC.NUMERO_OPERACION_OPCAJA,' +
    ' OC.SERIE_FAC_OPCAJA, OC.NUMERO_FAC_OPCAJA,' +
    ' OC.FECHA_OPERACION_OPCAJA,' +
    ' ROW_NUMBER() OVER (PARTITION BY OC.CODIGO_EMP_OPCAJA,' +
    ' OC.SERIE_FAC_OPCAJA, OC.NUMERO_FAC_OPCAJA' +
    ' ORDER BY FIELD(OC.TIPO_OPERACION_OPCAJA, ''VE'', ''DV'', ''DE''),' +
    ' OC.FECHA_OPERACION_OPCAJA, OC.CODIGO_ALM_OPCAJA,' +
    ' OC.CODIGO_CAJA_OPCAJA, OC.NUMERO_OPERACION_OPCAJA) POSICION' +
    ' FROM fza_caja_operaciones OC' +
    ' WHERE OC.CODIGO_EMP_OPCAJA = :EMPRESA' +
    ' AND OC.TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'', ''DE'')) O' +
    ' ON O.CODIGO_EMP_OPCAJA = F.CODIGO_EMP_FAC' +
    ' AND O.SERIE_FAC_OPCAJA = F.SERIE_FAC' +
    ' AND O.NUMERO_FAC_OPCAJA = F.NUMERO_FAC AND O.POSICION = 1' +
    ' LEFT JOIN (' +
    ' SELECT P.CODIGO_EMP_PAGO, P.CODIGO_ALM_PAGO,' +
    ' P.CODIGO_CAJA_PAGO, P.NUMERO_OPERACION_PAGO,' +
    ' SUM(P.IMPORTE_ENTREGADO_PAGO - P.IMPORTE_CAMBIO_PAGO) INGRESOS' +
    ' FROM fza_caja_pagos P' +
    ' WHERE P.CODIGO_EMP_PAGO = :EMPRESA' +
    ' GROUP BY P.CODIGO_EMP_PAGO, P.CODIGO_ALM_PAGO,' +
    ' P.CODIGO_CAJA_PAGO, P.NUMERO_OPERACION_PAGO) PG' +
    ' ON PG.CODIGO_EMP_PAGO = O.CODIGO_EMP_OPCAJA' +
    ' AND PG.CODIGO_ALM_PAGO = O.CODIGO_ALM_OPCAJA' +
    ' AND PG.CODIGO_CAJA_PAGO = O.CODIGO_CAJA_OPCAJA' +
    ' AND PG.NUMERO_OPERACION_PAGO = O.NUMERO_OPERACION_OPCAJA';
end;

function SqlComparativaVentas(ACriterio: TCriterioComparativaVentas): string;
var
  sFecha, sImporte, sAlmacen: string;
  bCaja: Boolean;
begin
  bCaja := ACriterio = ccvIngresosCaja;
  sFecha := 'F.FECHA_FAC';
  sAlmacen := 'COALESCE(FL.CODIGO_ALM_FACLIN, F.CODIGO_ALM_FAC)';
  sImporte := 'FL.TOTAL_FAC_SIVA_FACLIN';
  if ACriterio = ccvFacturadoConImpuestos then
    sImporte := 'FL.TOTAL_FACLIN';
  if bCaja then
  begin
    sFecha := 'O.FECHA_OPERACION_OPCAJA';
    sAlmacen := 'O.CODIGO_ALM_OPCAJA';
    sImporte := 'COALESCE(PG.INGRESOS * FL.TOTAL_FACLIN / ' +
      'NULLIF((SELECT SUM(FT.TOTAL_FACLIN) FROM fza_facturas_lineas FT' +
      ' WHERE FT.CODIGO_EMP_FACLIN = FL.CODIGO_EMP_FACLIN' +
      ' AND FT.SERIE_FAC_FACLIN = FL.SERIE_FAC_FACLIN' +
      ' AND FT.NUMERO_FAC_FACLIN = FL.NUMERO_FAC_FACLIN), 0), 0)';
  end;
  Result := 'SELECT DATE(' + sFecha + ') FECHA_DIA,' +
    ' SUM(' + sImporte + ') VENTA,' +
    ' SUM(FL.CANTIDAD_FACLIN) UNIDADES' +
    ' FROM fza_facturas F JOIN fza_facturas_lineas FL' +
    ' ON FL.CODIGO_EMP_FACLIN = F.CODIGO_EMP_FAC' +
    ' AND FL.SERIE_FAC_FACLIN = F.SERIE_FAC' +
    ' AND FL.NUMERO_FAC_FACLIN = F.NUMERO_FAC';
  if bCaja then
    Result := Result + SqlOrigenIngresosComparativa;
  Result := Result +
    ' WHERE F.CODIGO_EMP_FAC = :EMPRESA' +
    ' AND ' + sFecha + ' >= :DESDE AND ' + sFecha + ' < :HASTA' +
    ' AND (:ALMACENES = '''' OR FIND_IN_SET(' + sAlmacen +
    ', :ALMACENES) > 0)' +
    ' AND (:FAMILIAS = '''' OR FIND_IN_SET(' +
    'COALESCE(NULLIF(FL.CODIGO_FAM_FACLIN, ''''),' +
    ' (SELECT A.CODIGO_FAM_ART FROM fza_articulos A' +
    ' WHERE A.CODIGO_ART_ART = FL.CODIGO_ART_FACLIN)),' +
    ' :FAMILIAS) > 0)' +
    ' AND (:ARTICULOS = '''' OR FIND_IN_SET(FL.CODIGO_ART_FACLIN,' +
    ' :ARTICULOS) > 0)' +
    ' AND COALESCE(F.FASE_FAC, '''') NOT IN' +
    ' (''BORRADOR'', ''ERROR_BORRADOR'', ''CANCELADA'',' +
    ' ''SIN_VERIF_ANULADA'', ''VERIFACTU_ANULADA'',' +
    ' ''NOVERIFACTU_ANULADA'')' +
    SQLExcluirVentaRetirada(
      'F.CODIGO_EMP_FAC', 'F.SERIE_FAC', 'F.NUMERO_FAC');
  if not bCaja then
    Result := Result + SQLExcluirTicketSustituido(
      'F.CODIGO_EMP_FAC', 'F.SERIE_FAC', 'F.NUMERO_FAC');
  Result := Result + ' GROUP BY DATE(' + sFecha + ') ORDER BY FECHA_DIA';
end;

constructor TRepositorioComparativaVentas.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioComparativaVentas.Consultar(
  const AFiltro: TFiltroComparativaVentas; ADesde, AHasta: TDateTime):
  TVentasDiariasComparativa;
var
  oConsulta: TUniQuery;
  oLista: TList<TVentaDiariaComparativa>;
  oVenta: TVentaDiariaComparativa;
begin
  oConsulta := TUniQuery.Create(nil);
  oLista := TList<TVentaDiariaComparativa>.Create;
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SqlComparativaVentas(AFiltro.Criterio);
    oConsulta.ParamByName('EMPRESA').AsString := AFiltro.Empresa;
    oConsulta.ParamByName('DESDE').AsDateTime := Trunc(ADesde);
    oConsulta.ParamByName('HASTA').AsDateTime := IncDay(Trunc(AHasta));
    oConsulta.ParamByName('ALMACENES').AsString := AFiltro.Almacenes;
    oConsulta.ParamByName('FAMILIAS').AsString := AFiltro.Familias;
    oConsulta.ParamByName('ARTICULOS').AsString := AFiltro.Articulos;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oVenta.Fecha := oConsulta.FieldByName('FECHA_DIA').AsDateTime;
      oVenta.Venta := oConsulta.FieldByName('VENTA').AsCurrency;
      oVenta.Unidades := oConsulta.FieldByName('UNIDADES').AsFloat;
      oLista.Add(oVenta);
      oConsulta.Next;
    end;
    Result := oLista.ToArray;
  finally
    oLista.Free;
    oConsulta.Free;
  end;
end;

function CrearRepositorioComparativaVentas(AConexion: TUniConnection):
  IRepositorioComparativaVentas;
begin
  Result := TRepositorioComparativaVentas.Create(AConexion);
end;

end.
