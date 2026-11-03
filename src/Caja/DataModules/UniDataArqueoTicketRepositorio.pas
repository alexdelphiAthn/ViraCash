{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArqueoTicketRepositorio                               }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas catalogadas para presentar e imprimir arqueos de Caja.          }
{******************************************************************************}
unit UniDataArqueoTicketRepositorio;

interface

uses
  System.SysUtils,
  Data.DB, Uni,
  inLibArqueoIntf,
  inLibArqueoTicketIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioArqueoTicket = class(
    TInterfacedObject,
    IRepositorioArqueoTicket)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function AbrirConsulta(
      AIndiceDefinicion: Integer;
      const AConfigurar: TProc<TUniQuery>): TUniQuery;
    procedure ConfigurarContexto(
      AQuery: TUniQuery;
      const AArqueo: TArqueoCaja);
    function ListarRecuentoHistorico(
      const ACodigoArqueo: string):
      TArray<TRecuentoHistoricoArqueo>;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function ObtenerEmpresa(
      const AEmpresa: string): TEmpresaArqueoTicket;
    function ObtenerContadores(
      const AArqueo: TArqueoCaja): TContadoresArqueoTicket;
    function ListarDevolucionesPorFormaPago(
      const AArqueo: TArqueoCaja):
      TArray<TDevolucionFormaPagoArqueo>;
    function ListarResumenSeccion(
      const AArqueo: TArqueoCaja;
      ANiveles: Integer;
      AIncluirDevoluciones: Boolean): TArray<TResumenSeccionArqueo>;
    function ListarResumenTemporada(
      const AArqueo: TArqueoCaja):
      TArray<TResumenTemporadaArqueo>;
    function ListarResumenEmpleado(
      const AArqueo: TArqueoCaja):
      TArray<TResumenEmpleadoArqueo>;
    function ListarResumenFormaPago(
      const AArqueo: TArqueoCaja):
      TArray<TResumenFormaPagoArqueo>;
    function ListarResumenSerie(
      const AArqueo: TArqueoCaja):
      TArray<TResumenSerieArqueo>;
    function ObtenerRangoHistorico(
      const AEmpresa, AAlmacen, ACaja, ACodigoArqueo: string):
      TRangoHistoricoArqueo;
    function ObtenerCierreHistorico(
      const AEmpresa, AAlmacen, ACaja, ACodigoArqueo: string):
      TCierreHistoricoArqueo;
  end;

implementation

uses
  System.Generics.Collections,
  UniDataRectificativasSql, UniDataArqueoRepositorio,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

function SqlEmpresa: string;
begin
  Result :=
    'SELECT RAZON_SOCIAL_EMP, NIF_EMP, DIRECCION1_EMP, ' +
    'CODIGO_POSTAL_EMP, POBLACION_EMP, PROVINCIA_EMP ' +
    'FROM fza_empresas ' +
    'WHERE CODIGO_EMP_EMP = :pEMPRESA';
end;

function SqlContadores: string;
begin
  Result :=
    'SELECT COALESCE(MIN(o.NUMERO_OPERACION_OPCAJA), '''') AS PRIMERA, ' +
    'COALESCE(MAX(o.NUMERO_OPERACION_OPCAJA), '''') AS ULTIMA, ' +
    'COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS UDS ' +
    'FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_facturas_lineas l ' +
    'ON l.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    'AND l.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    'AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    'AND l.NUMERO_OPERACION_FACLIN = o.NUMERO_OPERACION_OPCAJA ' +
    // FZ-ISSUE-433: con las devoluciones (DV), como la pestaña Resúmenes.
    'WHERE o.TIPO_OPERACION_OPCAJA IN (:pTIPO_VE, :pTIPO_DV) ' +
    'AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA');
end;

function SqlDevolucionesPorFormaPago: string;
begin
  Result :=
    'SELECT p.CODIGO_FP_CFP AS FP, ' +
    'ABS(COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO), 0)) AS IMPORTE ' +
    'FROM fza_caja_pagos p ' +
    'JOIN fza_caja_operaciones o ' +
    'ON o.CODIGO_EMP_OPCAJA = p.CODIGO_EMP_PAGO ' +
    'AND o.CODIGO_ALM_OPCAJA = p.CODIGO_ALM_PAGO ' +
    'AND o.CODIGO_CAJA_OPCAJA = p.CODIGO_CAJA_PAGO ' +
    'AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO ' +
    'WHERE p.CODIGO_EMP_PAGO = :pEMPRESA ' +
    'AND p.CODIGO_ALM_PAGO = :pALMACEN ' +
    'AND p.CODIGO_CAJA_PAGO = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND o.TIPO_OPERACION_OPCAJA = :pTIPO_DV ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'GROUP BY p.CODIGO_FP_CFP ' +
    'ORDER BY p.CODIGO_FP_CFP';
end;

function SqlResumenSeccion: string;
var
  iNivel: Integer;
  sJoins: string;
  sNiveles: string;
  sPadre: string;
  sRuta: string;
begin
  sRuta := 'CONCAT_WS(''|''';
  iNivel := 8;
  while iNivel >= 1 do
  begin
    sRuta := sRuta + Format(
      ', COALESCE(a%d.NOMBRE_FAM_FAM, a%d.CODIGO_FAM_FAM)',
      [iNivel, iNivel]);
    Dec(iNivel);
  end;
  sRuta := sRuta +
    ', COALESCE(f.NOMBRE_FAM_FAM, f.CODIGO_FAM_FAM))';
  sJoins := '';
  sPadre := 'f';
  iNivel := 1;
  while iNivel <= 8 do
  begin
    sJoins := sJoins + Format(
      ' LEFT JOIN fza_articulos_familias a%d' +
      ' ON a%d.CODIGO_FAM_FAM = %s.CODIGO_PADRE_FAM ',
      [iNivel, iNivel, sPadre]);
    sPadre := Format('a%d', [iNivel]);
    Inc(iNivel);
  end;
  sNiveles :=
    'SELECT 1 AS NIVEL UNION ALL SELECT 2 UNION ALL SELECT 3 ' +
    'UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 ' +
    'UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9';
  Result :=
    'SELECT CONCAT(REPEAT(''  '', x.NIVEL - 1), ' +
    'SUBSTRING_INDEX(x.CLAVE, ''|'', -1)) AS FAMILIA, ' +
    'COALESCE(SUM(x.CANTIDAD), 0) AS UDS, ' +
    'COALESCE(SUM(x.TOTAL), 0) AS NETO ' +
    'FROM (SELECT n.NIVEL AS NIVEL, ' +
    'SUBSTRING_INDEX(b.RUTA, ''|'', n.NIVEL) AS CLAVE, ' +
    'b.CANTIDAD AS CANTIDAD, ' +
    'b.TOTAL AS TOTAL FROM (SELECT b0.RUTA, b0.CANTIDAD, b0.TOTAL, ' +
    '(CHAR_LENGTH(b0.RUTA) - ' +
    'CHAR_LENGTH(REPLACE(b0.RUTA,''|'','''')))+1 AS PROF ' +
    'FROM (SELECT COALESCE(NULLIF(' + sRuta + ', ''''), ' +
    'l.NOMBRE_FAM_FACLIN, l.CODIGO_FAM_FACLIN, ' +
    'a.CODIGO_FAM_ART, ''(sin familia)'') AS RUTA, ' +
    'l.CANTIDAD_FACLIN AS CANTIDAD, ' +
    'l.TOTAL_FACLIN AS TOTAL FROM fza_caja_operaciones o ' +
    'JOIN fza_facturas_lineas l ' +
    'ON l.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    'AND l.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    'AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    'AND l.NUMERO_OPERACION_FACLIN = ' +
    'o.NUMERO_OPERACION_OPCAJA LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = l.CODIGO_ART_FACLIN ' +
    'LEFT JOIN fza_articulos_familias f ' +
    'ON f.CODIGO_FAM_FAM = ' +
    'COALESCE(l.CODIGO_FAM_FACLIN, a.CODIGO_FAM_ART)' +
    sJoins +
    // FZ-ISSUE-407: pTIPO_DV repite la venta cuando no se piden las
    // devoluciones (ticket); la pantalla las incluye.
    'WHERE o.TIPO_OPERACION_OPCAJA IN (:pTIPO_VE, :pTIPO_DV) ' +
    'AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    ') b0) b JOIN (' + sNiveles + ') n ' +
    'ON n.NIVEL <= b.PROF AND n.NIVEL <= :pNIVELES) x ' +
    'GROUP BY x.NIVEL, x.CLAVE ORDER BY x.CLAVE';
end;

function SqlResumenTemporada: string;
begin
  Result :=
    'SELECT COALESCE(NULLIF(COALESCE(v.VALOR_PV, ' +
    'v.VALOR_LIBRE_ARTPROP), ''''), ''(sin temporada)'') AS TEMPORADA, ' +
    'COALESCE(SUM(l.CANTIDAD_FACLIN), 0) AS UDS, ' +
    'COALESCE(SUM(l.TOTAL_FACLIN), 0) AS NETO ' +
    'FROM fza_caja_operaciones o JOIN fza_facturas_lineas l ' +
    'ON l.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    'AND l.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    'AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    'AND l.NUMERO_OPERACION_FACLIN = o.NUMERO_OPERACION_OPCAJA ' +
    'LEFT JOIN vi_articulos_propiedades_efectivas v ' +
    'ON v.CODIGO_UNIDAD_SKU = l.CODIGO_UNIDAD_FACLIN ' +
    'AND v.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    'WHERE o.TIPO_OPERACION_OPCAJA IN (:pTIPO_VE, :pTIPO_DV) ' +
    'AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'GROUP BY TEMPORADA ORDER BY TEMPORADA';
end;

function SqlResumenEmpleado: string;
begin
  Result :=
    'SELECT COALESCE(e.DIMINUTIVO_TICKET_EMPL, ' +
    'o.CODIGO_EMPLEADO_OPCAJA, ''?'') AS EMPLEADO, ' +
    'COUNT(DISTINCT o.NUMERO_OPERACION_OPCAJA) AS OPS, ' +
    'COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0) AS NETO ' +
    'FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_empleados e ' +
    'ON e.CODIGO_EMPL = o.CODIGO_EMPLEADO_OPCAJA ' +
    'WHERE o.TIPO_OPERACION_OPCAJA IN (:pTIPO_VE, :pTIPO_DV) ' +
    'AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'GROUP BY o.CODIGO_EMPLEADO_OPCAJA, e.DIMINUTIVO_TICKET_EMPL ' +
    'ORDER BY NETO DESC';
end;

function SqlResumenFormaPago: string;
begin
  Result :=
    'SELECT p.CODIGO_FP_CFP AS FP, ' +
    'COALESCE(fp.DESCRIPCION_FORMA_PAGO_CFP, ' +
    'p.CODIGO_FP_CFP) AS DESCR, COUNT(*) AS UDS, ' +
    // FZ-ISSUE-433: lo cobrado (entregado menos cambio), sin la entrada
    // de cambio ni los gastos de caja, como la pestaña Resúmenes.
    'COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO - ' +
    'COALESCE(p.IMPORTE_CAMBIO_PAGO, 0)), 0) AS IMP ' +
    'FROM fza_caja_pagos p ' +
    'JOIN fza_caja_operaciones o ' +
    'ON o.CODIGO_EMP_OPCAJA = p.CODIGO_EMP_PAGO ' +
    'AND o.CODIGO_ALM_OPCAJA = p.CODIGO_ALM_PAGO ' +
    'AND o.CODIGO_CAJA_OPCAJA = p.CODIGO_CAJA_PAGO ' +
    'AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO ' +
    'LEFT JOIN fza_caja_formas_pago fp ' +
    'ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP ' +
    'WHERE p.CODIGO_EMP_PAGO = :pEMPRESA ' +
    'AND p.CODIGO_ALM_PAGO = :pALMACEN ' +
    'AND p.CODIGO_CAJA_PAGO = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND o.TIPO_OPERACION_OPCAJA NOT IN (:pTIPO_EC, :pTIPO_GC) ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'GROUP BY p.CODIGO_FP_CFP, fp.DESCRIPCION_FORMA_PAGO_CFP ' +
    'ORDER BY IMP DESC';
end;

function SqlResumenSerie: string;
begin
  Result :=
    'SELECT f.SERIE_FAC AS SERIE, ' +
    'COALESCE(SUM(f.TOTAL_BASES_FAC), 0) AS BASE, ' +
    'COALESCE(SUM(f.TOTAL_IMPUESTOS_FAC), 0) AS CUOTA, ' +
    'COALESCE(SUM(f.TOTAL_LIQUIDO_FAC), 0) AS TOTAL ' +
    'FROM fza_caja_operaciones o ' +
    'JOIN fza_facturas f ' +
    'ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA ' +
    'AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA ' +
    'AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA ' +
    'AND f.SERIE_FAC = o.SERIE_FAC_OPCAJA ' +
    'AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA ' +
    'WHERE o.TIPO_OPERACION_OPCAJA IN (:pTIPO_VE, :pTIPO_DV) ' +
    'AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SqlExcluirLiquidacionDepositoArqueo +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'GROUP BY f.SERIE_FAC ORDER BY f.SERIE_FAC';
end;

function SqlRangoHistorico: string;
begin
  Result :=
    'SELECT CODIGO_EMP_ARQ, CODIGO_ALM_ARQ, CODIGO_CAJA_ARQ, ' +
    'FECHA_DESDE_ARQ, FECHA_HASTA_ARQ ' +
    'FROM fza_caja_arqueos ' +
    'WHERE CODIGO_ARQ = :pARQ ' +
    'AND CODIGO_EMP_ARQ = :pEMP ' +
    'AND CODIGO_ALM_ARQ = :pALM ' +
    'AND CODIGO_CAJA_ARQ = :pCAJA';
end;

function SqlCierreHistorico: string;
begin
  Result :=
    'SELECT *, COALESCE(e.NOMBRE_EMPL, ' +
    'e.DIMINUTIVO_TICKET_EMPL, '''') AS NOMBRE_VENDEDOR ' +
    'FROM fza_caja_arqueos a ' +
    'LEFT JOIN fza_empleados e ' +
    'ON e.CODIGO_EMPL = a.CODIGO_EMPLEADO_ARQ ' +
    'WHERE a.CODIGO_ARQ = :pARQ ' +
    'AND a.CODIGO_EMP_ARQ = :pEMP ' +
    'AND a.CODIGO_ALM_ARQ = :pALM ' +
    'AND a.CODIGO_CAJA_ARQ = :pCAJA';
end;

function SqlRecuentoHistorico: string;
begin
  Result :=
    'SELECT CODIGO_FP_CFP_ARQR, DESCRIPCION_FP_ARQR, ESCAJON_ARQR, ' +
    'IMPORTE_SISTEMA_ARQR, IMPORTE_RECUENTO_ARQR, DIFERENCIA_ARQR ' +
    'FROM fza_caja_arqueos_recuento ' +
    'WHERE CODIGO_ARQ_ARQR = :pARQ ' +
    'ORDER BY ESCAJON_ARQR DESC, CODIGO_FP_CFP_ARQR';
end;

function DefinicionSql(
  const AOperacion, ASql, AParametros, ACampos: string):
  TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioArqueoTicket',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

class function TRepositorioArqueoTicket.DefinicionesSql:
  TDefinicionesSql;
const
  PARAMETROS_CONTEXTO =
    'pEMPRESA,pALMACEN,pCAJA,pFDESDE,pFHASTA';
  CAMPOS_CIERRE =
    'CODIGO_EMP_ARQ,CODIGO_ALM_ARQ,CODIGO_CAJA_ARQ,' +
    'FECHA_DESDE_ARQ,FECHA_HASTA_ARQ,CANTIDAD_VENTAS_ARQ,' +
    'TOTAL_EFECTIVO_INGRESOS_ARQ,TOTAL_EFECTIVO_ENTRADAS_ARQ,' +
    'TOTAL_EFECTIVO_SALIDAS_ARQ,TOTAL_EFECTIVO_ANTERIOR_ARQ,' +
    'TOTAL_EFECTIVO_CAJA_ARQ,OBSERVACIONES_ARQ,' +
    'CODIGO_EMPLEADO_ARQ,NOMBRE_VENDEDOR';
begin
  SetLength(Result, 11);
  Result[0] := DefinicionSql(
    'ObtenerEmpresa',
    SqlEmpresa,
    'pEMPRESA',
    'RAZON_SOCIAL_EMP,NIF_EMP,DIRECCION1_EMP,' +
    'CODIGO_POSTAL_EMP,POBLACION_EMP,PROVINCIA_EMP');
  Result[1] := DefinicionSql(
    'ObtenerContadores',
    SqlContadores,
    'pTIPO_VE,pTIPO_DV,' + PARAMETROS_CONTEXTO,
    'PRIMERA,ULTIMA,UDS');
  Result[2] := DefinicionSql(
    'ListarDevolucionesPorFormaPago',
    SqlDevolucionesPorFormaPago,
    PARAMETROS_CONTEXTO + ',pTIPO_DV',
    'FP,IMPORTE');
  Result[3] := DefinicionSql(
    'ListarResumenSeccion',
    SqlResumenSeccion,
    'pTIPO_VE,pTIPO_DV,' + PARAMETROS_CONTEXTO + ',pNIVELES',
    'FAMILIA,UDS,NETO');
  Result[4] := DefinicionSql(
    'ListarResumenTemporada',
    SqlResumenTemporada,
    'pTIPO_VE,pTIPO_DV,' + PARAMETROS_CONTEXTO,
    'TEMPORADA,UDS,NETO');
  Result[5] := DefinicionSql(
    'ListarResumenEmpleado',
    SqlResumenEmpleado,
    'pTIPO_VE,pTIPO_DV,' + PARAMETROS_CONTEXTO,
    'EMPLEADO,OPS,NETO');
  Result[6] := DefinicionSql(
    'ListarResumenFormaPago',
    SqlResumenFormaPago,
    PARAMETROS_CONTEXTO + ',pTIPO_EC,pTIPO_GC',
    'FP,DESCR,UDS,IMP');
  Result[7] := DefinicionSql(
    'ListarResumenSerie',
    SqlResumenSerie,
    'pTIPO_VE,pTIPO_DV,' + PARAMETROS_CONTEXTO,
    'SERIE,BASE,CUOTA,TOTAL');
  Result[8] := DefinicionSql(
    'ObtenerRangoHistorico',
    SqlRangoHistorico,
    'pARQ,pEMP,pALM,pCAJA',
    'CODIGO_EMP_ARQ,CODIGO_ALM_ARQ,CODIGO_CAJA_ARQ,' +
    'FECHA_DESDE_ARQ,FECHA_HASTA_ARQ');
  Result[9] := DefinicionSql(
    'ObtenerCierreHistorico',
    SqlCierreHistorico,
    'pARQ,pEMP,pALM,pCAJA',
    CAMPOS_CIERRE);
  Result[10] := DefinicionSql(
    'ListarRecuentoHistorico',
    SqlRecuentoHistorico,
    'pARQ',
    'CODIGO_FP_CFP_ARQR,DESCRIPCION_FP_ARQR,ESCAJON_ARQR,' +
    'IMPORTE_SISTEMA_ARQR,IMPORTE_RECUENTO_ARQR,DIFERENCIA_ARQR');
end;

constructor TRepositorioArqueoTicket.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

function TRepositorioArqueoTicket.AbrirConsulta(
  AIndiceDefinicion: Integer;
  const AConfigurar: TProc<TUniQuery>): TUniQuery;
var
  oDefinicion: TDefinicionSql;
  oQuery: TUniQuery;
begin
  oDefinicion := DefinicionesSql[AIndiceDefinicion];
  oQuery := TUniQuery.Create(nil);
  try
    oQuery.Connection := FConexion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oQuery.Close;
        oQuery.SQL.Text := ASql;
        AConfigurar(oQuery);
        oQuery.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          oQuery);
      end,
      FIncidenciasSql);
    Result := oQuery;
  except
    FreeAndNil(oQuery);
    raise;
  end;
end;

procedure TRepositorioArqueoTicket.ConfigurarContexto(
  AQuery: TUniQuery;
  const AArqueo: TArqueoCaja);
begin
  AQuery.ParamByName('pEMPRESA').AsString := AArqueo.Empresa;
  AQuery.ParamByName('pALMACEN').AsString := AArqueo.Almacen;
  AQuery.ParamByName('pCAJA').AsString := AArqueo.Caja;
  AQuery.ParamByName('pFDESDE').AsDateTime := AArqueo.FechaDesde;
  AQuery.ParamByName('pFHASTA').AsDateTime := AArqueo.FechaHasta;
end;

function TRepositorioArqueoTicket.ObtenerEmpresa(
  const AEmpresa: string): TEmpresaArqueoTicket;
var
  oQuery: TUniQuery;
  sEmpresa: string;
begin
  Result.Encontrada := False;
  sEmpresa := AEmpresa;
  oQuery := AbrirConsulta(
    0,
    procedure(AConsulta: TUniQuery)
    begin
      AConsulta.ParamByName('pEMPRESA').AsString := sEmpresa;
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrada := True;
      Result.RazonSocial :=
        oQuery.FieldByName('RAZON_SOCIAL_EMP').AsString;
      Result.Nif := oQuery.FieldByName('NIF_EMP').AsString;
      Result.Direccion :=
        oQuery.FieldByName('DIRECCION1_EMP').AsString;
      Result.CodigoPostal :=
        oQuery.FieldByName('CODIGO_POSTAL_EMP').AsString;
      Result.Poblacion :=
        oQuery.FieldByName('POBLACION_EMP').AsString;
      Result.Provincia :=
        oQuery.FieldByName('PROVINCIA_EMP').AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioArqueoTicket.ObtenerContadores(
  const AArqueo: TArqueoCaja): TContadoresArqueoTicket;
var
  oContexto: TArqueoCaja;
  oQuery: TUniQuery;
begin
  Result.Encontrado := False;
  oContexto := AArqueo;
  oQuery := AbrirConsulta(
    1,
    procedure(AConsulta: TUniQuery)
    begin
      ConfigurarContexto(AConsulta, oContexto);
      AConsulta.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
      AConsulta.ParamByName('pTIPO_DV').AsString := TipoOpDevolucion;
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrado := True;
      Result.PrimeraOperacion :=
        oQuery.FieldByName('PRIMERA').AsString;
      Result.UltimaOperacion :=
        oQuery.FieldByName('ULTIMA').AsString;
      Result.Unidades := oQuery.FieldByName('UDS').AsCurrency;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioArqueoTicket.ListarDevolucionesPorFormaPago(
  const AArqueo: TArqueoCaja):
  TArray<TDevolucionFormaPagoArqueo>;
var
  oContexto: TArqueoCaja;
  oLinea: TDevolucionFormaPagoArqueo;
  oLista: TList<TDevolucionFormaPagoArqueo>;
  oQuery: TUniQuery;
begin
  oContexto := AArqueo;
  oLista := TList<TDevolucionFormaPagoArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      2,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarContexto(AConsulta, oContexto);
        AConsulta.ParamByName('pTIPO_DV').AsString :=
          TipoOpDevolucion;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.FormaPago := oQuery.FieldByName('FP').AsString;
        oLinea.Importe := oQuery.FieldByName('IMPORTE').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ListarResumenSeccion(
  const AArqueo: TArqueoCaja;
  ANiveles: Integer;
  AIncluirDevoluciones: Boolean): TArray<TResumenSeccionArqueo>;
var
  iNiveles: Integer;
  sTipoDevolucion: string;
  oContexto: TArqueoCaja;
  oLinea: TResumenSeccionArqueo;
  oLista: TList<TResumenSeccionArqueo>;
  oQuery: TUniQuery;
begin
  iNiveles := ANiveles;
  if iNiveles < 1 then
    iNiveles := 1;
  if iNiveles > 9 then
    iNiveles := 9;
  if AIncluirDevoluciones then
    sTipoDevolucion := TipoOpDevolucion
  else
    sTipoDevolucion := TipoOpVenta;
  oContexto := AArqueo;
  oLista := TList<TResumenSeccionArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      3,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarContexto(AConsulta, oContexto);
        AConsulta.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        AConsulta.ParamByName('pTIPO_DV').AsString := sTipoDevolucion;
        AConsulta.ParamByName('pNIVELES').AsInteger := iNiveles;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Familia := oQuery.FieldByName('FAMILIA').AsString;
        oLinea.Unidades := oQuery.FieldByName('UDS').AsFloat;
        oLinea.Neto := oQuery.FieldByName('NETO').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ListarResumenTemporada(
  const AArqueo: TArqueoCaja):
  TArray<TResumenTemporadaArqueo>;
var
  oContexto: TArqueoCaja;
  oLinea: TResumenTemporadaArqueo;
  oLista: TList<TResumenTemporadaArqueo>;
  oQuery: TUniQuery;
begin
  oContexto := AArqueo;
  oLista := TList<TResumenTemporadaArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      4,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarContexto(AConsulta, oContexto);
        AConsulta.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        AConsulta.ParamByName('pTIPO_DV').AsString := TipoOpDevolucion;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Temporada :=
          oQuery.FieldByName('TEMPORADA').AsString;
        oLinea.Unidades := oQuery.FieldByName('UDS').AsFloat;
        oLinea.Neto := oQuery.FieldByName('NETO').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ListarResumenEmpleado(
  const AArqueo: TArqueoCaja):
  TArray<TResumenEmpleadoArqueo>;
var
  oContexto: TArqueoCaja;
  oLinea: TResumenEmpleadoArqueo;
  oLista: TList<TResumenEmpleadoArqueo>;
  oQuery: TUniQuery;
begin
  oContexto := AArqueo;
  oLista := TList<TResumenEmpleadoArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      5,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarContexto(AConsulta, oContexto);
        AConsulta.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        AConsulta.ParamByName('pTIPO_DV').AsString := TipoOpDevolucion;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Empleado :=
          oQuery.FieldByName('EMPLEADO').AsString;
        oLinea.Operaciones := oQuery.FieldByName('OPS').AsInteger;
        oLinea.Neto := oQuery.FieldByName('NETO').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ListarResumenFormaPago(
  const AArqueo: TArqueoCaja):
  TArray<TResumenFormaPagoArqueo>;
var
  oContexto: TArqueoCaja;
  oLinea: TResumenFormaPagoArqueo;
  oLista: TList<TResumenFormaPagoArqueo>;
  oQuery: TUniQuery;
begin
  oContexto := AArqueo;
  oLista := TList<TResumenFormaPagoArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      6,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarContexto(AConsulta, oContexto);
        AConsulta.ParamByName('pTIPO_EC').AsString := TipoOpEntradaCambio;
        AConsulta.ParamByName('pTIPO_GC').AsString := TipoOpGastoCaja;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Codigo := oQuery.FieldByName('FP').AsString;
        oLinea.Descripcion := oQuery.FieldByName('DESCR').AsString;
        oLinea.Unidades := oQuery.FieldByName('UDS').AsInteger;
        oLinea.Importe := oQuery.FieldByName('IMP').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ListarResumenSerie(
  const AArqueo: TArqueoCaja):
  TArray<TResumenSerieArqueo>;
var
  oContexto: TArqueoCaja;
  oLinea: TResumenSerieArqueo;
  oLista: TList<TResumenSerieArqueo>;
  oQuery: TUniQuery;
begin
  oContexto := AArqueo;
  oLista := TList<TResumenSerieArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      7,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarContexto(AConsulta, oContexto);
        AConsulta.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        AConsulta.ParamByName('pTIPO_DV').AsString := TipoOpDevolucion;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Serie := oQuery.FieldByName('SERIE').AsString;
        oLinea.Base := oQuery.FieldByName('BASE').AsCurrency;
        oLinea.Cuota := oQuery.FieldByName('CUOTA').AsCurrency;
        oLinea.Total := oQuery.FieldByName('TOTAL').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ObtenerRangoHistorico(
  const AEmpresa, AAlmacen, ACaja, ACodigoArqueo: string):
  TRangoHistoricoArqueo;
var
  sAlmacen: string;
  sArqueo: string;
  sCaja: string;
  sEmpresa: string;
  oQuery: TUniQuery;
begin
  Result.Encontrado := False;
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  sArqueo := ACodigoArqueo;
  oQuery := AbrirConsulta(
    8,
    procedure(AConsulta: TUniQuery)
    begin
      AConsulta.ParamByName('pARQ').AsString := sArqueo;
      AConsulta.ParamByName('pEMP').AsString := sEmpresa;
      AConsulta.ParamByName('pALM').AsString := sAlmacen;
      AConsulta.ParamByName('pCAJA').AsString := sCaja;
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrado := True;
      Result.Empresa :=
        oQuery.FieldByName('CODIGO_EMP_ARQ').AsString;
      Result.Almacen :=
        oQuery.FieldByName('CODIGO_ALM_ARQ').AsString;
      Result.Caja :=
        oQuery.FieldByName('CODIGO_CAJA_ARQ').AsString;
      Result.FechaDesde :=
        oQuery.FieldByName('FECHA_DESDE_ARQ').AsDateTime;
      Result.FechaHasta :=
        oQuery.FieldByName('FECHA_HASTA_ARQ').AsDateTime;
    end;
  finally
    FreeAndNil(oQuery);
  end;
end;

function TRepositorioArqueoTicket.ListarRecuentoHistorico(
  const ACodigoArqueo: string):
  TArray<TRecuentoHistoricoArqueo>;
var
  sArqueo: string;
  oLinea: TRecuentoHistoricoArqueo;
  oLista: TList<TRecuentoHistoricoArqueo>;
  oQuery: TUniQuery;
begin
  sArqueo := ACodigoArqueo;
  oLista := TList<TRecuentoHistoricoArqueo>.Create;
  try
    oQuery := AbrirConsulta(
      10,
      procedure(AConsulta: TUniQuery)
      begin
        AConsulta.ParamByName('pARQ').AsString := sArqueo;
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.CodigoFormaPago :=
          oQuery.FieldByName('CODIGO_FP_CFP_ARQR').AsString;
        oLinea.Descripcion :=
          oQuery.FieldByName('DESCRIPCION_FP_ARQR').AsString;
        oLinea.EsCajon :=
          oQuery.FieldByName('ESCAJON_ARQR').AsString;
        oLinea.Sistema :=
          oQuery.FieldByName('IMPORTE_SISTEMA_ARQR').AsCurrency;
        oLinea.Recuento :=
          oQuery.FieldByName('IMPORTE_RECUENTO_ARQR').AsCurrency;
        oLinea.Diferencia :=
          oQuery.FieldByName('DIFERENCIA_ARQR').AsCurrency;
        oLista.Add(oLinea);
        oQuery.Next;
      end;
    finally
      FreeAndNil(oQuery);
    end;
    Result := oLista.ToArray;
  finally
    FreeAndNil(oLista);
  end;
end;

function TRepositorioArqueoTicket.ObtenerCierreHistorico(
  const AEmpresa, AAlmacen, ACaja, ACodigoArqueo: string):
  TCierreHistoricoArqueo;
var
  sAlmacen: string;
  sArqueo: string;
  sCaja: string;
  sEmpresa: string;
  sNombreVendedor: string;
  sVendedor: string;
  oCampo: TField;
  oQuery: TUniQuery;
begin
  Result.Encontrado := False;
  Result.Lineas := nil;
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  sArqueo := ACodigoArqueo;
  oQuery := AbrirConsulta(
    9,
    procedure(AConsulta: TUniQuery)
    begin
      AConsulta.ParamByName('pARQ').AsString := sArqueo;
      AConsulta.ParamByName('pEMP').AsString := sEmpresa;
      AConsulta.ParamByName('pALM').AsString := sAlmacen;
      AConsulta.ParamByName('pCAJA').AsString := sCaja;
    end);
  try
    if not oQuery.IsEmpty then
    begin
      Result.Encontrado := True;
      Result.Arqueo.Empresa :=
        oQuery.FieldByName('CODIGO_EMP_ARQ').AsString;
      Result.Arqueo.Almacen :=
        oQuery.FieldByName('CODIGO_ALM_ARQ').AsString;
      Result.Arqueo.Caja :=
        oQuery.FieldByName('CODIGO_CAJA_ARQ').AsString;
      Result.Arqueo.FechaDesde :=
        oQuery.FieldByName('FECHA_DESDE_ARQ').AsDateTime;
      Result.Arqueo.FechaHasta :=
        oQuery.FieldByName('FECHA_HASTA_ARQ').AsDateTime;
      Result.Arqueo.CantidadVentas :=
        oQuery.FieldByName('CANTIDAD_VENTAS_ARQ').AsInteger;
      Result.Arqueo.EfectivoIngresos :=
        oQuery.FieldByName('TOTAL_EFECTIVO_INGRESOS_ARQ').AsCurrency;
      Result.Arqueo.EfectivoEntradas :=
        oQuery.FieldByName('TOTAL_EFECTIVO_ENTRADAS_ARQ').AsCurrency;
      Result.Arqueo.EfectivoSalidas :=
        oQuery.FieldByName('TOTAL_EFECTIVO_SALIDAS_ARQ').AsCurrency;
      Result.Arqueo.EfectivoAnterior :=
        oQuery.FieldByName('TOTAL_EFECTIVO_ANTERIOR_ARQ').AsCurrency;
      Result.Arqueo.EfectivoCaja :=
        oQuery.FieldByName('TOTAL_EFECTIVO_CAJA_ARQ').AsCurrency;
      Result.Observaciones :=
        oQuery.FieldByName('OBSERVACIONES_ARQ').AsString;
      sVendedor := Trim(
        oQuery.FieldByName('CODIGO_EMPLEADO_ARQ').AsString);
      sNombreVendedor := Trim(
        oQuery.FieldByName('NOMBRE_VENDEDOR').AsString);
      if (sVendedor <> '') and (sNombreVendedor <> '') then
        sVendedor := sVendedor + ' - ' + sNombreVendedor;
      Result.Vendedor := sVendedor;
      oCampo := oQuery.FindField('TOTAL_RECUENTO_ARQ');
      if Assigned(oCampo) then
        Result.TotalRecuento := oCampo.AsCurrency;
      oCampo := oQuery.FindField('DIFERENCIA_TOTAL_ARQ');
      if Assigned(oCampo) then
        Result.Diferencia := oCampo.AsCurrency;
      Result.TotalSistema :=
        Result.TotalRecuento - Result.Diferencia;
      oCampo := oQuery.FindField('IMPORTE_RETIRADA_ARQ');
      if Assigned(oCampo) then
        Result.Retirada := oCampo.AsCurrency;
      oCampo := oQuery.FindField('CONCEPTO_RETIRADA_ARQ');
      if Assigned(oCampo) then
        Result.ConceptoRetirada := oCampo.AsString;
      oCampo := oQuery.FindField('EFECTIVO_DEJADO_CAJA_ARQ');
      if Assigned(oCampo) then
        Result.EfectivoDejado := oCampo.AsCurrency;
      oCampo := oQuery.FindField('DESGLOSE_BILLETES_ARQ');
      if Assigned(oCampo) then
        Result.DesgloseBilletes := oCampo.AsString;
    end;
  finally
    FreeAndNil(oQuery);
  end;
  if Result.Encontrado then
    Result.Lineas := ListarRecuentoHistorico(
      ACodigoArqueo);
end;

end.
