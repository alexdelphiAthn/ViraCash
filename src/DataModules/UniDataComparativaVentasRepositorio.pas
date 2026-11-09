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
  System.SyncObjs, System.Classes,
  UniDataRectificativasSql;

type
  TRepositorioComparativaVentas = class(TInterfacedObject,
    IRepositorioComparativaVentas)
  private
    FConexion: TUniConnection;
    FConsulta: TUniQuery;
    FCancelada: Integer;
    FUltimoCorte: UInt64;
    FSeccion: TCriticalSection;
    procedure AnotarConsulta(AConsulta: TUniQuery);
  public
    constructor Create(AConexion: TUniConnection);
    destructor Destroy; override;
    procedure Cancelar;
    function Consultar(const AFiltro: TFiltroComparativaVentas;
      ADesde, AHasta: TDateTime;
      APeriodo: TPeriodoComparativaVentas = pcvPrimero):
      TVentasDiariasComparativa;
  end;

function SqlOrigenIngresosComparativa: string;
begin
  // Numerar solo las facturas con operaciones en el periodo. Se conservan
  // todas sus operaciones para elegir la primera del historico, aunque
  // quede fuera del periodo. Los pagos se consultan por su clave completa.
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
    ' FROM (SELECT DISTINCT C.CODIGO_EMP_OPCAJA,' +
    ' C.SERIE_FAC_OPCAJA, C.NUMERO_FAC_OPCAJA' +
    ' FROM fza_caja_operaciones C' +
    ' WHERE C.CODIGO_EMP_OPCAJA = :EMPRESA' +
    ' AND C.FECHA_OPERACION_OPCAJA >= :DESDE' +
    ' AND C.FECHA_OPERACION_OPCAJA < :HASTA' +
    ' AND C.TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'', ''DE'')) C' +
    ' STRAIGHT_JOIN fza_caja_operaciones OC' +
    ' ON OC.CODIGO_EMP_OPCAJA = C.CODIGO_EMP_OPCAJA' +
    ' AND OC.SERIE_FAC_OPCAJA = C.SERIE_FAC_OPCAJA' +
    ' AND OC.NUMERO_FAC_OPCAJA = C.NUMERO_FAC_OPCAJA' +
    ' WHERE OC.CODIGO_EMP_OPCAJA = :EMPRESA' +
    ' AND OC.TIPO_OPERACION_OPCAJA IN (''VE'', ''DV'', ''DE'')) O' +
    ' ON O.CODIGO_EMP_OPCAJA = F.CODIGO_EMP_FAC' +
    ' AND O.SERIE_FAC_OPCAJA = F.SERIE_FAC' +
    ' AND O.NUMERO_FAC_OPCAJA = F.NUMERO_FAC AND O.POSICION = 1';
end;

function SqlFiltrosCatalogoComparativa: string;
begin
  // EXISTS evita multiplicar ventas si hay varios proveedores del artículo.
  // Temporada vigente: SKU, color y artículo, por ese orden.
  Result :=
    ' AND (:PROVEEDORES = '''' OR EXISTS (' +
    ' SELECT 1 FROM fza_articulos_proveedores AP' +
    ' WHERE AP.CODIGO_ART_AP = FL.CODIGO_ART_FACLIN' +
    ' AND FIND_IN_SET(AP.CODIGO_PRV_AP, :PROVEEDORES) > 0))' +
    ' AND (:TEMPORADAS = '''' OR FIND_IN_SET(COALESCE((' +
    ' SELECT COALESCE(PV.PV, AP.VALOR_LIBRE_ARTPROP, '''')' +
    ' FROM fza_articulos_propiedades AP' +
    ' LEFT JOIN fza_propiedades_valores PV' +
    ' ON PV.ID_PV_ARTPROP = AP.ID_PV_ARTPROP' +
    ' WHERE AP.CODIGO_ART_ART = FL.CODIGO_ART_FACLIN' +
    ' AND AP.CODIGO_PROP_ARTPROP = ''TEMPORADA''' +
    ' AND AP.CODIGO_UNIDAD_ARTPROP IN ('''',' +
    ' NULLIF(FL.CODIGO_UNIDAD_FACLIN, ''''),' +
    ' SUBSTRING_INDEX(NULLIF(FL.CODIGO_UNIDAD_FACLIN, ''''), ''/'', 2))' +
    ' ORDER BY LENGTH(AP.CODIGO_UNIDAD_ARTPROP) DESC LIMIT 1), ''''),' +
    ' :TEMPORADAS) > 0)';
end;

function SqlComparativaVentas(ACriterio: TCriterioComparativaVentas): string;
var
  sFecha, sImporte, sAlmacen: string;
  bCaja: Boolean;
begin
  bCaja := ACriterio = ccvIngresosCaja;
  sFecha := 'F.FECHA_FAC';
  // FZ-ISSUE-870: la factura que sustituye a un ticket puede no tener
  // almacen propio. Recuperarlo del origen, sin asumir el de la sesion.
  sAlmacen := 'COALESCE(NULLIF(FL.CODIGO_ALM_FACLIN, ''''),' +
    ' NULLIF(F.CODIGO_ALM_FAC, ''''), (SELECT MIN(COALESCE(' +
    ' NULLIF(OL.CODIGO_ALM_FACLIN, ''''),' +
    ' NULLIF(OFAC.CODIGO_ALM_FAC, '''')))' +
    ' FROM fza_facturas_relaciones R JOIN fza_facturas OFAC' +
    ' ON OFAC.SERIE_FAC = R.SERIE_FAC_ORIGEN_FACREL' +
    ' AND OFAC.NUMERO_FAC = R.NUMERO_FAC_ORIGEN_FACREL' +
    ' AND OFAC.CODIGO_EMP_FAC = F.CODIGO_EMP_FAC' +
    ' LEFT JOIN fza_facturas_lineas OL' +
    ' ON OL.SERIE_FAC_FACLIN = OFAC.SERIE_FAC' +
    ' AND OL.NUMERO_FAC_FACLIN = OFAC.NUMERO_FAC' +
    ' AND OL.CODIGO_UNIDAD_FACLIN = FL.CODIGO_UNIDAD_FACLIN' +
    ' WHERE R.SERIE_FAC_FACREL = F.SERIE_FAC' +
    ' AND R.NUMERO_FAC_FACREL = F.NUMERO_FAC' +
    ' AND R.TIPO_RELACION_FACREL = ''SUSTITUYE''))';
  sImporte := 'FL.TOTAL_FAC_SIVA_FACLIN';
  if ACriterio = ccvFacturadoConImpuestos then
    sImporte := 'FL.TOTAL_FACLIN';
  if bCaja then
  begin
    sFecha := 'O.FECHA_OPERACION_OPCAJA';
    sAlmacen := 'O.CODIGO_ALM_OPCAJA';
    sImporte := 'COALESCE((SELECT SUM(P.IMPORTE_ENTREGADO_PAGO' +
      ' - P.IMPORTE_CAMBIO_PAGO) FROM fza_caja_pagos P' +
      ' WHERE P.CODIGO_EMP_PAGO = O.CODIGO_EMP_OPCAJA' +
      ' AND P.CODIGO_ALM_PAGO = O.CODIGO_ALM_OPCAJA' +
      ' AND P.CODIGO_CAJA_PAGO = O.CODIGO_CAJA_OPCAJA' +
      ' AND P.NUMERO_OPERACION_PAGO = O.NUMERO_OPERACION_OPCAJA)' +
      ' * FL.TOTAL_FACLIN / ' +
      'NULLIF((SELECT SUM(FT.TOTAL_FACLIN) FROM fza_facturas_lineas FT' +
      ' WHERE FT.SERIE_FAC_FACLIN = FL.SERIE_FAC_FACLIN' +
      ' AND FT.NUMERO_FAC_FACLIN = FL.NUMERO_FAC_FACLIN), 0), 0)';
  end;
  Result := 'SELECT DATE(' + sFecha + ') FECHA_DIA,' +
    ' SUM(' + sImporte + ') VENTA,' +
    ' SUM(FL.CANTIDAD_FACLIN) UNIDADES' +
    ' FROM fza_facturas F JOIN fza_facturas_lineas FL' +
    ' ON FL.SERIE_FAC_FACLIN = F.SERIE_FAC' +
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
    SqlFiltrosCatalogoComparativa +
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
  FSeccion := TCriticalSection.Create;
end;

destructor TRepositorioComparativaVentas.Destroy;
begin
  FreeAndNil(FSeccion);
  inherited;
end;

procedure TRepositorioComparativaVentas.AnotarConsulta(AConsulta: TUniQuery);
begin
  FSeccion.Enter;
  try
    FConsulta := AConsulta;
  finally
    FSeccion.Leave;
  end;
end;

procedure TRepositorioComparativaVentas.Cancelar;
var
  iAhora: UInt64;
begin
  AtomicExchange(FCancelada, 1);
  iAhora := TThread.GetTickCount64;
  FSeccion.Enter;
  try
    if Assigned(FConsulta) and
       ((FUltimoCorte = 0) or (iAhora - FUltimoCorte >= 1000)) then
    begin
      FUltimoCorte := iAhora;
      FConsulta.BreakExec;
    end;
  finally
    FSeccion.Leave;
  end;
end;

function TRepositorioComparativaVentas.Consultar(
  const AFiltro: TFiltroComparativaVentas; ADesde, AHasta: TDateTime;
  APeriodo: TPeriodoComparativaVentas): TVentasDiariasComparativa;
var
  oConexion: TUniConnection;
  oConsulta: TUniQuery;
  oLista: TList<TVentaDiariaComparativa>;
  oVenta: TVentaDiariaComparativa;
begin
  if AtomicCmpExchange(FCancelada, 0, 0) <> 0 then
    Abort;
  oConexion := TUniConnection.Create(nil);
  oConsulta := TUniQuery.Create(nil);
  oLista := TList<TVentaDiariaComparativa>.Create;
  try
    // La cancelacion del driver puede cerrar la conexion de la consulta.
    // Mantener intacta la sesion principal y sus tablas temporales.
    oConexion.Assign(FConexion);
    oConexion.LoginPrompt := False;
    oConexion.Connect;
    oConsulta.Connection := oConexion;
    oConsulta.SQL.Text := SqlComparativaVentas(AFiltro.Criterio);
    oConsulta.ParamByName('EMPRESA').AsString := AFiltro.Empresa;
    oConsulta.ParamByName('DESDE').AsDateTime := Trunc(ADesde);
    oConsulta.ParamByName('HASTA').AsDateTime := IncDay(Trunc(AHasta));
    oConsulta.ParamByName('ALMACENES').AsString := AFiltro.Almacenes;
    oConsulta.ParamByName('FAMILIAS').AsString := AFiltro.Familias;
    oConsulta.ParamByName('ARTICULOS').AsString := AFiltro.Articulos;
    oConsulta.ParamByName('PROVEEDORES').AsString := AFiltro.Proveedores;
    if APeriodo = pcvSegundo then
      oConsulta.ParamByName('TEMPORADAS').AsString :=
        AFiltro.TemporadasAnteriores
    else
      oConsulta.ParamByName('TEMPORADAS').AsString := AFiltro.Temporadas;
    AnotarConsulta(oConsulta);
    if AtomicCmpExchange(FCancelada, 0, 0) <> 0 then
      Abort;
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
    AnotarConsulta(nil);
    oLista.Free;
    oConsulta.Free;
    oConexion.Free;
  end;
end;

function CrearRepositorioComparativaVentas(AConexion: TUniConnection):
  IRepositorioComparativaVentas;
begin
  Result := TRepositorioComparativaVentas.Create(AConexion);
end;

end.
