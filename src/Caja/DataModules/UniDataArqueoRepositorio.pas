{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataArqueoRepositorio                                     }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cálculo del arqueo de caja (cierre Z) en vivo para un contexto            }
{    Empresa/Almacén/Caja y un rango de fechas. Devuelve un record             }
{    TArqueoCaja con todos los importes que pinta la pantalla F11.             }
{                                                                              }
{    Las formas de pago son N (EFE, TARJ, BONO, USD, BTC, ...). El reparto     }
{    entre "efectivo" y "otros" se hace dinámicamente leyendo                  }
{    fza_caja_formas_pago.ESABRE_CAJON_FORMA_PAGO_CFP, que es la marca         }
{    canónica de "esto va al cajón físico". El detalle por forma se devuelve   }
{    en PagosPorForma para poder pintar el desglose en la pantalla.            }
{                                                                              }
{    No persiste nada; la futura implementación del F5 Recuento usará          }
{    estos cálculos como punto de partida para grabar en fza_caja_arqueos.     }
{******************************************************************************}
unit UniDataArqueoRepositorio;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, Uni, DBAccess,
  inLibArqueoIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioArqueoCaja = class(
    TInterfacedObject,
    IRepositorioArqueoCaja)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    procedure CalcularContadores(var AArqueo: TArqueoCaja);
    procedure CalcularLineas(var AArqueo: TArqueoCaja);
    procedure CalcularOperaciones(var AArqueo: TArqueoCaja);
    procedure CalcularDepositos(var AArqueo: TArqueoCaja);
    procedure CalcularVales(var AArqueo: TArqueoCaja);
    procedure CalcularPagos(var AArqueo: TArqueoCaja);
    procedure CalcularEfectivoAnterior(var AArqueo: TArqueoCaja);
    procedure CalcularDerivados(var AArqueo: TArqueoCaja);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function Calcular(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate): TArqueoCaja;
  end;

function SqlExcluirLiquidacionDepositoArqueo: string;

implementation

uses
  System.DateUtils, UniDataRectificativasSql,
  inLibCatalogoSqlEjecucion,
  UniDataCatalogoSqlValidacion;

function SqlExcluirLiquidacionDepositoArqueo: string;
begin
  // La liquidacion ya tiene su movimiento DE: no es una venta normal.
  // Mismo criterio que V_NORMALES; evita sumar el anticipo ACUENTA.
  Result :=
    'AND NOT EXISTS (SELECT 1 FROM fza_caja_operaciones od ' +
    'WHERE o.TIPO_OPERACION_OPCAJA = ''VE'' ' +
    'AND od.CODIGO_EMP_OPCAJA = o.CODIGO_EMP_OPCAJA ' +
    'AND od.CODIGO_ALM_OPCAJA = o.CODIGO_ALM_OPCAJA ' +
    'AND od.CODIGO_CAJA_OPCAJA = o.CODIGO_CAJA_OPCAJA ' +
    'AND od.NUMERO_OPERACION_OPCAJA = o.NUMERO_OPERACION_OPCAJA ' +
    'AND od.TIPO_OPERACION_OPCAJA = ''DE'') ';
end;

function SqlContadores: string;
begin
  Result :=
    ' SELECT ' +
    'COUNT(DISTINCT CASE ' +
    'WHEN TIPO_OPERACION_OPCAJA = :pTIPO_VE ' +
    'THEN NUMERO_OPERACION_OPCAJA END) AS VENTAS, ' +
    'COUNT(DISTINCT NUMERO_OPERACION_OPCAJA) AS OPERAC ' +
    'FROM fza_caja_operaciones o ' +
    'WHERE CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA');
end;

function SqlLineas: string;
begin
  Result :=
    // FZ-ISSUE-348: el precio de salida del TPV ya lleva el IVA; solo se
    // añade cuando la tarifa de la línea es sin impuestos.
    ' SELECT COALESCE(SUM(ROUND(l.CANTIDAD_FACLIN ' +
    '* l.PRECIO_SALIDA_FACLIN ' +
    '* CASE WHEN l.ESIMP_INCL_TARIFA_FACLIN = ''N'' ' +
    'THEN 1 + COALESCE(l.PORCENTAJE_IVA_FACLIN, 0) / 100 ' +
    'ELSE 1 END, 2)), 0) ' +
    'AS BRUTO, COALESCE(SUM(l.TOTAL_FACLIN), 0) AS NETO_LIN ' +
    'FROM fza_caja_operaciones o JOIN fza_facturas_lineas l ' +
    'ON l.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA ' +
    'AND l.CODIGO_ALM_FACLIN = o.CODIGO_ALM_OPCAJA ' +
    'AND l.CODIGO_CAJA_FACLIN = o.CODIGO_CAJA_OPCAJA ' +
    'AND l.NUMERO_OPERACION_FACLIN = o.NUMERO_OPERACION_OPCAJA ' +
    'WHERE o.TIPO_OPERACION_OPCAJA = :pTIPO_VE ' +
    'AND o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA');
end;

function SqlOperaciones: string;
begin
  Result :=
    ' SELECT COALESCE(SUM(CASE ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_VE ' +
    'THEN o.IMPORTE_TOTAL_OPCAJA ELSE 0 END), 0) AS NETO, ' +
    'COALESCE(SUM(CASE ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_VE ' +
    'AND o.IMPORTE_TOTAL_OPCAJA > 0 AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_caja_operaciones o2 ' +
    'WHERE o2.CODIGO_EMP_OPCAJA = o.CODIGO_EMP_OPCAJA ' +
    'AND o2.CODIGO_ALM_OPCAJA = o.CODIGO_ALM_OPCAJA ' +
    'AND o2.CODIGO_CAJA_OPCAJA = o.CODIGO_CAJA_OPCAJA ' +
    'AND o2.NUMERO_OPERACION_OPCAJA = o.NUMERO_OPERACION_OPCAJA ' +
    'AND o2.TIPO_OPERACION_OPCAJA = :pTIPO_DE) ' +
    'THEN o.IMPORTE_TOTAL_OPCAJA ELSE 0 END), 0) AS V_NORMALES, ' +
    'ABS(COALESCE(SUM(CASE ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_DV ' +
    'THEN o.IMPORTE_TOTAL_OPCAJA ELSE 0 END), 0)) AS V_DEVOL, ' +
    'COALESCE(SUM(CASE ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_EC ' +
    'THEN o.IMPORTE_TOTAL_OPCAJA ELSE 0 END), 0) AS ENTRADAS, ' +
    'COALESCE(SUM(CASE ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = :pTIPO_GC ' +
    'THEN o.IMPORTE_TOTAL_OPCAJA ELSE 0 END), 0) AS SALIDAS ' +
    'FROM fza_caja_operaciones o ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA');
end;

function SqlPrestamos: string;
begin
  // FZ-ISSUE-349: PENDIENTE es lo que los clientes deben al final del
  // rango por esos depósitos: valor menos anticipos cobrados hasta
  // pFHASTA, y nada si ya se liquidaron (DE negativa) dentro de él. Se
  // calcula con las operaciones, no con ESTADO_DEP, para que un arqueo
  // pasado no cambie al liquidarse después.
  Result :=
    'SELECT COALESCE(SUM(d.PRECIO_VENTA_DEP ' +
    '* COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1)), 0) AS PRESTAMOS, ' +
    'COALESCE(SUM(CASE WHEN EXISTS (' +
    'SELECT 1 FROM fza_caja_operaciones ol ' +
    'WHERE ol.CODIGO_EMP_OPCAJA = d.CODIGO_EMP_DEP ' +
    'AND ol.ID_DEPOSITO_OPCAJA = d.ID_DEPOSITO_DEP ' +
    'AND ol.TIPO_OPERACION_OPCAJA = :pTIPO_DE ' +
    'AND ol.IMPORTE_TOTAL_OPCAJA < 0 ' +
    'AND ol.FECHA_OPERACION_OPCAJA <= :pFHASTA' +
    SQLExcluirVentaRetirada(
      'ol.CODIGO_EMP_OPCAJA',
      'ol.SERIE_FAC_OPCAJA',
      'ol.NUMERO_FAC_OPCAJA') +
    ') THEN 0 ELSE GREATEST(d.PRECIO_VENTA_DEP ' +
    '* COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1) - COALESCE((' +
    'SELECT SUM(oa.IMPORTE_TOTAL_OPCAJA) FROM fza_caja_operaciones oa ' +
    'WHERE oa.CODIGO_EMP_OPCAJA = d.CODIGO_EMP_DEP ' +
    'AND oa.ID_DEPOSITO_OPCAJA = d.ID_DEPOSITO_DEP ' +
    'AND oa.TIPO_OPERACION_OPCAJA IN (:pTIPO_CB, :pTIPO_DE) ' +
    'AND oa.IMPORTE_TOTAL_OPCAJA > 0 ' +
    'AND oa.FECHA_OPERACION_OPCAJA <= :pFHASTA' +
    SQLExcluirVentaRetirada(
      'oa.CODIGO_EMP_OPCAJA',
      'oa.SERIE_FAC_OPCAJA',
      'oa.NUMERO_FAC_OPCAJA') +
    '), 0), 0) END), 0) AS PENDIENTE ' +
    'FROM fza_depositos_cliente d ' +
    'WHERE d.CODIGO_EMP_DEP = :pEMPRESA ' +
    'AND d.CODIGO_ALM_DEP = :pALMACEN ' +
    'AND d.CODIGO_CAJA_DEP = :pCAJA ' +
    'AND d.FECHA_CREACION_DEP >= :pFDESDE ' +
    'AND d.FECHA_CREACION_DEP <= :pFHASTA';
end;

function SqlCobrosClientes: string;
begin
  Result :=
    'SELECT COALESCE(SUM(o.IMPORTE_TOTAL_OPCAJA), 0) AS COBROS ' +
    'FROM fza_caja_operaciones o ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :pEMPRESA ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALMACEN ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    'AND o.TIPO_OPERACION_OPCAJA IN (:pTIPO_CB, :pTIPO_DE) ' +
    'AND o.IMPORTE_TOTAL_OPCAJA > 0 ' +
    'AND o.ID_DEPOSITO_OPCAJA IS NOT NULL ' +
    'AND o.ID_DEPOSITO_OPCAJA <> '''' ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA');
end;

function SqlValesEmitidos: string;
begin
  Result :=
    'SELECT COALESCE(SUM(IMPORTE_NOMINAL_VL), 0) AS EMITIDOS ' +
    'FROM fza_caja_vales v ' +
    'WHERE v.CODIGO_EMP_EMI_VL = :pEMPRESA ' +
    'AND v.CODIGO_ALM_EMI_VL = :pALMACEN ' +
    'AND v.CODIGO_CAJA_EMI_VL = :pCAJA ' +
    'AND v.FECHA_EMISION_VL >= :pFDESDE ' +
    'AND v.FECHA_EMISION_VL <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'v.CODIGO_EMP_EMI_VL',
      'v.SERIE_FAC_EMI_VL',
      'v.NUMERO_FAC_EMI_VL');
end;

function SqlValesRecogidos: string;
begin
  Result :=
    'SELECT COALESCE(SUM(IMPORTE_REDIMIDO_VL), 0) AS RECOGIDOS ' +
    'FROM fza_caja_vales v ' +
    'WHERE v.CODIGO_EMP_RED_VL = :pEMPRESA ' +
    'AND v.CODIGO_ALM_RED_VL = :pALMACEN ' +
    'AND v.CODIGO_CAJA_RED_VL = :pCAJA ' +
    'AND v.FECHA_REDENCION_VL >= :pFDESDE ' +
    'AND v.FECHA_REDENCION_VL <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'v.CODIGO_EMP_RED_VL',
      'v.SERIE_FAC_RED_VL',
      'v.NUMERO_FAC_RED_VL');
end;

function SqlPagosPorForma: string;
begin
  Result :=
    'SELECT fp.CODIGO_FP_CFP AS CODIGO, ' +
    'fp.DESCRIPCION_FORMA_PAGO_CFP AS DESCRIPCION, ' +
    'fp.ESABRE_CAJON_FORMA_PAGO_CFP AS ESCAJON, ' +
    'COALESCE(SUM(p.IMPORTE_ENTREGADO_PAGO - ' +
    'p.IMPORTE_CAMBIO_PAGO), 0) AS IMPORTE ' +
    'FROM fza_caja_formas_pago fp LEFT JOIN fza_caja_pagos p ' +
    'ON p.CODIGO_FP_CFP = fp.CODIGO_FP_CFP ' +
    'AND p.CODIGO_EMP_PAGO = :pEMPRESA ' +
    'AND p.CODIGO_ALM_PAGO = :pALMACEN ' +
    'AND p.CODIGO_CAJA_PAGO = :pCAJA ' +
    'AND EXISTS (SELECT 1 FROM fza_caja_operaciones o ' +
    'WHERE o.CODIGO_EMP_OPCAJA = p.CODIGO_EMP_PAGO ' +
    'AND o.CODIGO_ALM_OPCAJA = p.CODIGO_ALM_PAGO ' +
    'AND o.CODIGO_CAJA_OPCAJA = p.CODIGO_CAJA_PAGO ' +
    'AND o.NUMERO_OPERACION_OPCAJA = p.NUMERO_OPERACION_PAGO ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    // FZ-ISSUE-346: entradas de cambio y gastos de caja van aparte
    // (EfectivoEntradas / EfectivoSalidas); aquí contaban otra vez.
    'AND o.TIPO_OPERACION_OPCAJA NOT IN (:pTIPO_EC, :pTIPO_GC) ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    ') WHERE fp.ESACTIVO_FORMA_PAGO_CFP = ''S'' ' +
    'GROUP BY fp.CODIGO_FP_CFP, fp.DESCRIPCION_FORMA_PAGO_CFP, ' +
    'fp.ESABRE_CAJON_FORMA_PAGO_CFP ' +
    'ORDER BY ESCAJON DESC, fp.CODIGO_FP_CFP';
end;

function SqlComprobarEfectivoAnterior: string;
begin
  Result :=
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
    'WHERE TABLE_SCHEMA = DATABASE() ' +
    'AND TABLE_NAME = ''fza_caja_arqueos'' ' +
    'AND COLUMN_NAME = ''EFECTIVO_DEJADO_CAJA_ARQ''';
end;

function SqlEfectivoAnterior: string;
begin
  Result :=
    'SELECT EFECTIVO_DEJADO_CAJA_ARQ FROM fza_caja_arqueos ' +
    'WHERE CODIGO_EMP_ARQ = :pEMPRESA ' +
    'AND CODIGO_ALM_ARQ = :pALMACEN ' +
    'AND CODIGO_CAJA_ARQ = :pCAJA ' +
    'AND FASE_ARQ = ''CERRADO'' ' +
    'AND FECHA_HASTA_ARQ <= :pFDESDE ' +
    'ORDER BY FECHA_HASTA_ARQ DESC LIMIT 1';
end;

function DefinicionSql(
  const AOperacion, ASql, AParametros,
  ACampos: string;
  APolitica: TPoliticaEjecucionSql =
    pesPerfilLecturaConFallback): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioArqueoCaja',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    APolitica);
end;

class function TRepositorioArqueoCaja.DefinicionesSql:
  TDefinicionesSql;
const
  PARAMETROS_RANGO =
    'pTIPO_VE,pEMPRESA,pALMACEN,pCAJA,pFDESDE,pFHASTA';
  PARAMETROS_CONTEXTO =
    'pEMPRESA,pALMACEN,pCAJA,pFDESDE,pFHASTA';
begin
  SetLength(Result, 10);
  Result[0] := DefinicionSql(
    'CalcularContadores',
    SqlContadores,
    PARAMETROS_RANGO,
    'VENTAS,OPERAC');
  Result[1] := DefinicionSql(
    'CalcularLineas',
    SqlLineas,
    PARAMETROS_RANGO,
    'BRUTO,NETO_LIN');
  Result[2] := DefinicionSql(
    'CalcularOperaciones',
    SqlOperaciones,
    'pTIPO_VE,pTIPO_DE,pTIPO_DV,pTIPO_EC,pTIPO_GC,' +
    'pEMPRESA,pALMACEN,pCAJA,pFDESDE,pFHASTA',
    'NETO,V_NORMALES,V_DEVOL,ENTRADAS,SALIDAS');
  Result[3] := DefinicionSql(
    'CalcularPrestamos',
    SqlPrestamos,
    PARAMETROS_CONTEXTO + ',pTIPO_CB,pTIPO_DE',
    'PRESTAMOS,PENDIENTE');
  Result[4] := DefinicionSql(
    'CalcularCobrosClientes',
    SqlCobrosClientes,
    'pEMPRESA,pALMACEN,pCAJA,pFDESDE,pFHASTA,pTIPO_CB,pTIPO_DE',
    'COBROS');
  Result[5] := DefinicionSql(
    'CalcularValesEmitidos',
    SqlValesEmitidos,
    PARAMETROS_CONTEXTO,
    'EMITIDOS');
  Result[6] := DefinicionSql(
    'CalcularValesRecogidos',
    SqlValesRecogidos,
    PARAMETROS_CONTEXTO,
    'RECOGIDOS');
  Result[7] := DefinicionSql(
    'CalcularPagosPorForma',
    SqlPagosPorForma,
    PARAMETROS_CONTEXTO + ',pTIPO_EC,pTIPO_GC',
    'CODIGO,DESCRIPCION,ESCAJON,IMPORTE');
  Result[8] := DefinicionSql(
    'ComprobarEfectivoAnterior',
    SqlComprobarEfectivoAnterior,
    '',
    'N',
    pesSoloBase);
  Result[9] := DefinicionSql(
    'ObtenerEfectivoAnterior',
    SqlEfectivoAnterior,
    'pEMPRESA,pALMACEN,pCAJA,pFDESDE',
    'EFECTIVO_DEJADO_CAJA_ARQ');
end;

// =============================================================================
//   API pública
// =============================================================================

constructor TRepositorioArqueoCaja.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

function TRepositorioArqueoCaja.Calcular(
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate): TArqueoCaja;
begin
  // Record que se rellena por pasos. FillChar deja PagosPorForma a nil, que es
  // el valor válido de inicialización para un dynamic array.
  FillChar(Result, SizeOf(Result), 0);
  Result.Empresa    := AEmpresa;
  Result.Almacen    := AAlmacen;
  Result.Caja       := ACaja;
  Result.FechaDesde := AFechaDesde;
  Result.FechaHasta := AFechaHasta;

  if Assigned(FConexion)
    and FConexion.Connected
    and (Trim(AEmpresa) <> '')
    and (Trim(AAlmacen) <> '')
    and (Trim(ACaja) <> '') then
  begin
    CalcularContadores(Result);
    CalcularLineas(Result);
    CalcularOperaciones(Result);
    CalcularDepositos(Result);
    CalcularVales(Result);
    CalcularPagos(Result);
    CalcularEfectivoAnterior(Result);
    CalcularDerivados(Result);
  end;
end;

// =============================================================================
//   Auxiliares privados
// =============================================================================

procedure TRepositorioArqueoCaja.CalcularContadores(
  var AArqueo: TArqueoCaja);
var
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
  Query: TUniQuery;
begin
  oContexto := AArqueo;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[0];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
    begin
      AArqueo.CantidadVentas      := Query.FieldByName('VENTAS').AsInteger;
      AArqueo.CantidadOperaciones := Query.FieldByName('OPERAC').AsInteger;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TRepositorioArqueoCaja.CalcularLineas(
  var AArqueo: TArqueoCaja);
var
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
  Query: TUniQuery;
begin
  // Suma de las líneas de las facturas asociadas a las ventas del rango. El
  // "bruto" es el total con IVA antes del descuento de línea
  // (PRECIO_SALIDA_FACLIN x CANTIDAD_FACLIN, más el IVA solo si la tarifa
  // de la línea es sin impuestos). El descuento es la diferencia con
  // TOTAL_FACLIN.
  oContexto := AArqueo;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[1];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
    begin
      AArqueo.BrutoLineas      := Query.FieldByName('BRUTO').AsCurrency;
      AArqueo.NetoLineas       := Query.FieldByName('NETO_LIN').AsCurrency;
      AArqueo.DescuentosLineas := AArqueo.BrutoLineas - AArqueo.NetoLineas;
    end;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TRepositorioArqueoCaja.CalcularOperaciones(
  var AArqueo: TArqueoCaja);
var
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
  Query: TUniQuery;
begin
  // Esquema de cálculo:
  //   - Neto              = SUM IMPORTE_TOTAL_OPCAJA WHERE TIPO='VE' (signed,
  //                         se mantiene como cifra interna).
  //   - VentasNormales    = VE > 0 sin DE en la misma operación.
  //   - Devoluciones      = ABS(SUM TIPO='DV')  ← canónico, no VE < 0.
  //
  // Préstamos y CobrosClientes NO se calculan aquí: se sacan en
  // CalcularDepositos directamente de fza_depositos_cliente, que tiene
  // el saldo correcto (PRECIO_VENTA_DEP × CANTIDAD para el valor de la
  // mercancía, IMPORTE_ANTICIPO_DEP para lo ya cobrado).
  oContexto := AArqueo;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[2];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pTIPO_VE').AsString := TipoOpVenta;
        Query.ParamByName('pTIPO_DV').AsString := TipoOpDevolucion;
        Query.ParamByName('pTIPO_EC').AsString := TipoOpEntradaCambio;
        Query.ParamByName('pTIPO_GC').AsString := TipoOpGastoCaja;
        Query.ParamByName('pTIPO_DE').AsString := TipoOpDeposito;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
    begin
      AArqueo.Neto             := Query.FieldByName('NETO').AsCurrency;
      AArqueo.VentasNormales   := Query.FieldByName('V_NORMALES').AsCurrency;
      AArqueo.Devoluciones     := Query.FieldByName('V_DEVOL').AsCurrency;
      AArqueo.EfectivoEntradas := Query.FieldByName('ENTRADAS').AsCurrency;
      AArqueo.EfectivoSalidas  := Query.FieldByName('SALIDAS').AsCurrency;
    end;

    // Operaciones — bruto y descuentos:
    // BrutoOperaciones es la suma neta de líneas (lo que aparece arriba a la
    // izquierda como "Bruto" de la sección Operaciones). El descuento global
    // es la diferencia con el Neto de operaciones.
    AArqueo.BrutoOperaciones      := AArqueo.NetoLineas;
    AArqueo.DescuentosOperaciones := AArqueo.NetoLineas - AArqueo.Neto;
    if AArqueo.DescuentosOperaciones < 0 then
      AArqueo.DescuentosOperaciones := 0;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TRepositorioArqueoCaja.CalcularDepositos(
  var AArqueo: TArqueoCaja);
var
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
  Query: TUniQuery;
begin
  // Métricas de depósitos basadas en el PERÍODO (no snapshot actual),
  // para que un arqueo de una temporada pasada siga siendo correcto
  // aunque los depósitos de entonces estén cerrados hoy:
  //
  //   - Préstamos      = SUM(PRECIO_VENTA_DEP × CANTIDAD_PENDIENTE_DEP)
  //                      de los depósitos cuya FECHA_CREACION_DEP cae
  //                      en el rango. Da el valor de la mercancía
  //                      comprometida en el período (independiente del
  //                      ESTADO_DEP actual).
  //
  //   - CobrosClientes = SUM(IMPORTE_TOTAL_OPCAJA) de las operaciones
  //                      CB+ y DE+ ligadas a un depósito
  //                      (ID_DEPOSITO_OPCAJA no nulo) que ocurrieron en
  //                      el rango. Es el flujo real de efectivo entrado
  //                      como anticipo durante el período, igual de
  //                      válido para arqueos pasados o actuales.
  //
  //   - PendienteCobro = lo que aún deben al final del rango los
  //                      clientes de esos depósitos (FZ-ISSUE-349).

  // 1) Préstamos: valor de los depósitos creados en el período.
  oContexto := AArqueo;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[3];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.ParamByName('pTIPO_CB').AsString := TipoOpCobroCuenta;
        Query.ParamByName('pTIPO_DE').AsString := TipoOpDeposito;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
    begin
      AArqueo.Prestamos := Query.FieldByName('PRESTAMOS').AsCurrency;
      AArqueo.PendienteCobro :=
        Query.FieldByName('PENDIENTE').AsCurrency;
    end;
  finally
    FreeAndNil(Query);
  end;

  // 2) Cobros clientes: anticipos cobrados (CB+ y DE+ ligados a depósito)
  //    en el período.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[4];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.ParamByName('pTIPO_CB').AsString := TipoOpCobroCuenta;
        Query.ParamByName('pTIPO_DE').AsString := TipoOpDeposito;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
      AArqueo.CobrosClientes := Query.FieldByName('COBROS').AsCurrency;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TRepositorioArqueoCaja.CalcularVales(
  var AArqueo: TArqueoCaja);
var
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
  Query: TUniQuery;
begin
  // Vales emitidos en la caja en el rango.
  oContexto := AArqueo;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[5];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
      AArqueo.ValesEmitidos := Query.FieldByName('EMITIDOS').AsCurrency;
  finally
    FreeAndNil(Query);
  end;

  // Vales recogidos (redimidos) en la caja en el rango.
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[6];
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        Query.Close;
        Query.SQL.Text := ASql;
        Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
        Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
        Query.ParamByName('pCAJA').AsString := oContexto.Caja;
        Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
        Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
        Query.Open;
        ValidarCamposResultadoSql(
          oDefinicion,
          Query);
      end,
      FIncidenciasSql);
    if not Query.Eof then
      AArqueo.ValesRecogidos := Query.FieldByName('RECOGIDOS').AsCurrency;
  finally
    FreeAndNil(Query);
  end;
end;

procedure TRepositorioArqueoCaja.CalcularPagos(
  var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
  Forma: TArqueoPagoForma;
  Lista: TList<TArqueoPagoForma>;
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
begin
  // Importes entregados por forma de pago en el rango. Agrupado por código
  // y enriquecido con descripción + flag de "abre cajón" (= efectivo) desde
  // fza_caja_formas_pago. El reparto efectivo/otros lo decide la columna
  // ESABRE_CAJON_FORMA_PAGO_CFP, no códigos hardcoded — así si mañana se da
  // de alta otra forma "tipo caja" (otra divisa en efectivo, vale interno,
  // etc.) suma sola en el cubo de efectivo.
  oContexto := AArqueo;
  Lista := TList<TArqueoPagoForma>.Create;
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FConexion;
      // Partimos de TODAS las formas de pago activas y LEFT JOIN a los
      // pagos del periodo. Asi las que no tuvieron movimiento aparecen
      // con importe 0 y el usuario puede rellenar el recuento.
      // EXISTS filtra por fecha sin multiplicar el pago cuando una
      // operación tiene varias filas. El LEFT JOIN conserva los medios
      // sin movimiento. Se suma el neto, incluido el cambio compensado.
      oDefinicion := DefinicionesSql[7];
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        FCatalogoSql,
        procedure(const ASql: string)
        begin
          Query.Close;
          Query.SQL.Text := ASql;
          Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
          Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
          Query.ParamByName('pCAJA').AsString := oContexto.Caja;
          Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
          Query.ParamByName('pFHASTA').AsDateTime := oContexto.FechaHasta;
          Query.ParamByName('pTIPO_EC').AsString := TipoOpEntradaCambio;
          Query.ParamByName('pTIPO_GC').AsString := TipoOpGastoCaja;
          Query.Open;
          ValidarCamposResultadoSql(
            oDefinicion,
            Query);
        end,
        FIncidenciasSql);
      while not Query.Eof do
      begin
        Forma.Codigo      := Query.FieldByName('CODIGO').AsString;
        Forma.Descripcion := Query.FieldByName('DESCRIPCION').AsString;
        Forma.EsEfectivo  := Query.FieldByName('ESCAJON').AsString = 'S';
        Forma.Importe     := Query.FieldByName('IMPORTE').AsCurrency;
        Lista.Add(Forma);
        // El vale es moneda interna: se muestra por forma de pago, pero no
        // incrementa el efectivo ni los otros ingresos a recontar.
        if not SameText(Forma.Codigo, 'VALE') then
        begin
          if Forma.EsEfectivo then
            AArqueo.EfectivoIngresos :=
              AArqueo.EfectivoIngresos + Forma.Importe
          else
            AArqueo.OtrosIngresos :=
              AArqueo.OtrosIngresos + Forma.Importe;
        end;
        Query.Next;
      end;
    finally
      FreeAndNil(Query);
    end;
    AArqueo.PagosPorForma := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

procedure TRepositorioArqueoCaja.CalcularEfectivoAnterior(
  var AArqueo: TArqueoCaja);
var
  Query: TUniQuery;
  bExiste: Boolean;
  oContexto: TArqueoCaja;
  oDefinicion: TDefinicionSql;
begin
  { Comprobar primero si la columna existe (migración pendiente). El
    evento OnError de la conexión UniDAC propaga la excepción antes
    de que un except local la capture, así que hay que evitar el
    SELECT sobre una columna inexistente. }
  oContexto := AArqueo;
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FConexion;
    oDefinicion := DefinicionesSql[8];
    if Assigned(FCatalogoSql) then
      Query.SQL.Text := FCatalogoSql.Resolver(
        oDefinicion).Texto
    else
      Query.SQL.Text := oDefinicion.SqlBase;
    Query.Open;
    ValidarCamposResultadoSql(
      oDefinicion,
      Query);
    bExiste := (not Query.Eof)
               and (Query.FieldByName('N').AsInteger > 0);
  finally
    FreeAndNil(Query);
  end;
  if bExiste then
  begin
    { La columna existe: buscar el último arqueo CERRADO de la misma
      caja anterior a este rango. }
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FConexion;
      oDefinicion := DefinicionesSql[9];
      EjecutarLecturaSqlConFallback(
        oDefinicion,
        FCatalogoSql,
        procedure(const ASql: string)
        begin
          Query.Close;
          Query.SQL.Text := ASql;
          Query.ParamByName('pEMPRESA').AsString := oContexto.Empresa;
          Query.ParamByName('pALMACEN').AsString := oContexto.Almacen;
          Query.ParamByName('pCAJA').AsString := oContexto.Caja;
          Query.ParamByName('pFDESDE').AsDateTime := oContexto.FechaDesde;
          Query.Open;
          ValidarCamposResultadoSql(
            oDefinicion,
            Query);
        end,
        FIncidenciasSql);
      if not Query.Eof then
        AArqueo.EfectivoAnterior :=
          Query.FieldByName('EFECTIVO_DEJADO_CAJA_ARQ').AsCurrency;
    finally
      FreeAndNil(Query);
    end;
  end;
end;

procedure TRepositorioArqueoCaja.CalcularDerivados(
  var AArqueo: TArqueoCaja);
begin
  CalcularDerivadosArqueo(AArqueo);
end;

end.
