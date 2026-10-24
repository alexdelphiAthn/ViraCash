{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataTiraCajaTicketRepositorio                             }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas catalogadas para imprimir y exportar la tira de Caja.           }
{******************************************************************************}
unit UniDataTiraCajaTicketRepositorio;

interface

uses
  System.SysUtils,
  Data.DB, Uni,
  inLibTiraCajaTicketIntf,
  inLibCatalogoSqlIntf;

type
  TRepositorioTiraCajaTicket = class(
    TInterfacedObject,
    IRepositorioTiraCajaTicket)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function AbrirConsulta(
      AIndiceDefinicion: Integer;
      const AConfigurar: TProc<TUniQuery>): TUniQuery;
    procedure ConfigurarOperacion(
      AQuery: TUniQuery;
      const AEmpresa, AAlmacen, ACaja, AOperacion: string);
    procedure ConfigurarRango(
      AQuery: TUniQuery;
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate);
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql = nil;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql: TDefinicionesSql;
    function ObtenerEmpresa(
      const AEmpresa: string): TEmpresaTiraCajaTicket;
    function ListarLineasVenta(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TLineaVentaTiraCaja>;
    function ListarFormasPago(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TFormaPagoTiraCaja>;
    function ListarLineasTraspaso(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TLineaTraspasoTiraCaja>;
    function ListarDepositos(
      const AEmpresa, AAlmacen, ACaja, AOperacion: string):
      TArray<TDepositoTiraCaja>;
    function ListarOperaciones(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate;
      const ASeries: TArray<string>;
      ACronologico, AIncluirTraspasos, AIncluirIngresos,
      AIncluirGastos, AIncluirCredito: Boolean):
      TArray<TOperacionTiraCaja>;
    function ListarSeries(
      const AEmpresa, AAlmacen, ACaja: string;
      AFechaDesde, AFechaHasta: TDate): TArray<string>;
  end;

implementation

uses
  System.Generics.Collections, System.StrUtils,
  UniDataRectificativasSql,
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

function SqlLineasVenta: string;
begin
  Result :=
    'SELECT CODIGO_UNIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'CANTIDAD_FACLIN, TOTAL_FACLIN ' +
    'FROM fza_facturas_lineas ' +
    'WHERE CODIGO_EMP_FACLIN = :pEMP ' +
    'AND CODIGO_ALM_FACLIN = :pALM ' +
    'AND CODIGO_CAJA_FACLIN = :pCAJA ' +
    'AND NUMERO_OPERACION_FACLIN = :pOPE ' +
    'ORDER BY LINEA_FACLIN';
end;

function SqlFormasPago: string;
begin
  Result :=
    'SELECT p.CODIGO_FP_CFP, ' +
    'COALESCE(fp.DESCRIPCION_FORMA_PAGO_CFP, ' +
    'p.CODIGO_FP_CFP) AS DESCR, ' +
    'p.IMPORTE_ENTREGADO_PAGO, p.IMPORTE_CAMBIO_PAGO ' +
    'FROM fza_caja_pagos p ' +
    'LEFT JOIN fza_caja_formas_pago fp ' +
    'ON fp.CODIGO_FP_CFP = p.CODIGO_FP_CFP ' +
    'WHERE p.CODIGO_EMP_PAGO = :pEMP ' +
    'AND p.CODIGO_ALM_PAGO = :pALM ' +
    'AND p.CODIGO_CAJA_PAGO = :pCAJA ' +
    'AND p.NUMERO_OPERACION_PAGO = :pOPE ' +
    'ORDER BY p.NUMERO_LINEA_PAGO';
end;

function SqlLineasTraspaso: string;
begin
  Result :=
    'SELECT m.CODIGO_UNIDAD_MOV, m.CANTIDAD_MOV, ' +
    'COALESCE(NULLIF(TRIM(m.DESCRIPCION_ARTICULO_MOV), ''''), ' +
    'a.DESCRIPCION_ART, '''') AS DESCRIPCION, ' +
    'm.PRECIO_COSTE_UNITARIO_MOV ' +
    'FROM fza_movimientos_almacen m ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV ' +
    'WHERE m.CODIGO_EMP_MOV = :pEMP ' +
    'AND m.CODIGO_ALM_DOC_MOV = :pALM ' +
    'AND m.CODIGO_CAJA_DOC_MOV = :pCAJA ' +
    'AND m.NUMERO_OPERACION_DOC_MOV = :pOPE ' +
    'AND m.TIPO_MOV = ''S'' ' +
    'ORDER BY m.LINEA_MOV';
end;

function SqlDepositos: string;
begin
  Result :=
    'SELECT d.CODIGO_CLI_DEP, ' +
    'COALESCE(c.RAZON_SOCIAL_CLI, '''') AS CLIENTE, ' +
    'd.CODIGO_UNIDAD_DEP, ' +
    'COALESCE(a.DESCRIPCION_ART, '''') AS DESCRIPCION, ' +
    'd.PRECIO_VENTA_DEP, ' +
    'COALESCE(d.CANTIDAD_PENDIENTE_DEP, 1) AS CANTIDAD, ' +
    'd.IMPORTE_ANTICIPO_DEP ' +
    'FROM fza_depositos_cliente d ' +
    'LEFT JOIN fza_clientes c ' +
    'ON c.CODIGO_CLI_CLI = d.CODIGO_CLI_DEP ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP ' +
    'WHERE d.CODIGO_EMP_DEP = :pEMP ' +
    'AND d.CODIGO_ALM_DEP = :pALM ' +
    'AND d.CODIGO_CAJA_DEP = :pCAJA ' +
    'AND d.NUMERO_OPERACION_DEP = :pOPE ' +
    'ORDER BY d.ID_DEPOSITO_DEP';
end;

function SqlOperaciones: string;
begin
  Result :=
    'SELECT o.CODIGO_EMP_OPCAJA, o.CODIGO_ALM_OPCAJA, ' +
    'o.CODIGO_CAJA_OPCAJA, o.NUMERO_OPERACION_OPCAJA, ' +
    'o.FECHA_OPERACION_OPCAJA, o.SERIE_FAC_OPCAJA, ' +
    'o.NUMERO_FAC_OPCAJA, o.IMPORTE_TOTAL_OPCAJA, ' +
    'o.CONCEPTO_GASTO_INGRESO_OPCAJA, ' +
    'o.CODIGO_ALM_CONTRA_OPCAJA, ' +
    'f.TOTAL_BASES_FAC, f.TOTAL_IMPUESTOS_FAC, ' +
    'f.TOTAL_LIQUIDO_FAC, f.FECHA_FAC, f.NIF_EMPRESA_FAC, ' +
    'COALESCE(e.FORMATO_DOCUMENTO_EMP, ' +
    '''Serie.NroDocumento'') AS FORMATO_DOCUMENTO_EMP, ' +
    'CASE WHEN o.TIPO_OPERACION_OPCAJA IN (''TR'',''AT'') ' +
    'THEN ''TRA'' ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = ''EC'' THEN ''ING'' ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = ''GC'' THEN ''GAS'' ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = ''DE'' THEN ''DEP'' ' +
    'ELSE ''VEN'' END AS GRUPO, ' +
    'CASE WHEN o.TIPO_OPERACION_OPCAJA IN (''TR'',''AT'') THEN 2 ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = ''EC'' THEN 3 ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = ''GC'' THEN 4 ' +
    'WHEN o.TIPO_OPERACION_OPCAJA = ''DE'' THEN 5 ' +
    'ELSE 1 END AS GRUPO_ORDEN ' +
    'FROM fza_caja_operaciones o ' +
    'LEFT JOIN fza_facturas f ' +
    'ON f.CODIGO_EMP_FAC = o.CODIGO_EMP_OPCAJA ' +
    'AND f.CODIGO_ALM_FAC = o.CODIGO_ALM_OPCAJA ' +
    'AND f.CODIGO_CAJA_FAC = o.CODIGO_CAJA_OPCAJA ' +
    'AND f.SERIE_FAC = o.SERIE_FAC_OPCAJA ' +
    'AND f.NUMERO_FAC = o.NUMERO_FAC_OPCAJA ' +
    'LEFT JOIN fza_empresas e ' +
    'ON e.CODIGO_EMP_EMP = o.CODIGO_EMP_OPCAJA ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :pEMP ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALM ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'AND ((o.SERIE_FAC_OPCAJA IS NOT NULL ' +
    'AND o.SERIE_FAC_OPCAJA <> '''' ' +
    'AND o.TIPO_OPERACION_OPCAJA ' +
    'NOT IN (''TR'',''AT'',''EC'',''GC'',''DE'') ' +
    // Una venta puede dejar varias filas en fza_caja_operaciones
    // con la misma factura (VE + DV, CB de anticipo, VR de vale
    // canjeado, VL de vale emitido). La tira imprime el documento
    // completo (líneas y formas de pago de la factura), así que
    // cada fila extra repetía el ticket y volvía a sumar su total.
    // Se deja una sola fila por factura: la más representativa
    // (VE, luego DV) y, a igualdad, la primera grabada.
    'AND (o.NUMERO_FAC_OPCAJA IS NULL ' +
    'OR o.NUMERO_FAC_OPCAJA = '''' ' +
    'OR o.ID_OPCAJA = (SELECT od.ID_OPCAJA ' +
    'FROM fza_caja_operaciones od ' +
    'WHERE od.CODIGO_EMP_OPCAJA = o.CODIGO_EMP_OPCAJA ' +
    'AND od.CODIGO_ALM_OPCAJA = o.CODIGO_ALM_OPCAJA ' +
    'AND od.CODIGO_CAJA_OPCAJA = o.CODIGO_CAJA_OPCAJA ' +
    'AND od.SERIE_FAC_OPCAJA = o.SERIE_FAC_OPCAJA ' +
    'AND od.NUMERO_FAC_OPCAJA = o.NUMERO_FAC_OPCAJA ' +
    'AND od.TIPO_OPERACION_OPCAJA ' +
    'NOT IN (''TR'',''AT'',''EC'',''GC'',''DE'') ' +
    'ORDER BY CASE od.TIPO_OPERACION_OPCAJA ' +
    'WHEN ''VE'' THEN 0 WHEN ''DV'' THEN 1 ELSE 2 END, ' +
    'od.ID_OPCAJA LIMIT 1)) ' +
    'AND (:pTODAS_SERIES = ''S'' ' +
    'OR FIND_IN_SET(o.SERIE_FAC_OPCAJA, :pSERIES) > 0)) ' +
    'OR (:pINCLUIR_TRASPASOS = ''S'' ' +
    'AND o.TIPO_OPERACION_OPCAJA IN (''TR'',''AT'')) ' +
    'OR (:pINCLUIR_INGRESOS = ''S'' ' +
    'AND o.TIPO_OPERACION_OPCAJA = ''EC'') ' +
    'OR (:pINCLUIR_GASTOS = ''S'' ' +
    'AND o.TIPO_OPERACION_OPCAJA = ''GC'') ' +
    'OR (:pINCLUIR_CREDITO = ''S'' ' +
    'AND o.TIPO_OPERACION_OPCAJA = ''DE'')) ' +
    'ORDER BY CASE WHEN :pCRONOLOGICO = ''S'' ' +
    'THEN 0 ELSE GRUPO_ORDEN END, ' +
    'o.FECHA_OPERACION_OPCAJA, o.NUMERO_OPERACION_OPCAJA';
end;

function SqlSeries: string;
begin
  Result :=
    'SELECT DISTINCT o.SERIE_FAC_OPCAJA AS SERIE ' +
    'FROM fza_caja_operaciones o ' +
    'WHERE o.CODIGO_EMP_OPCAJA = :pEMP ' +
    'AND o.CODIGO_ALM_OPCAJA = :pALM ' +
    'AND o.CODIGO_CAJA_OPCAJA = :pCAJA ' +
    'AND o.SERIE_FAC_OPCAJA IS NOT NULL ' +
    'AND o.SERIE_FAC_OPCAJA <> '''' ' +
    'AND o.FECHA_OPERACION_OPCAJA >= :pFDESDE ' +
    'AND o.FECHA_OPERACION_OPCAJA <= :pFHASTA ' +
    SQLExcluirVentaRetirada(
      'o.CODIGO_EMP_OPCAJA',
      'o.SERIE_FAC_OPCAJA',
      'o.NUMERO_FAC_OPCAJA') +
    'ORDER BY o.SERIE_FAC_OPCAJA';
end;

function DefinicionSql(
  const AOperacion, ASql, AParametros, ACampos: string):
  TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioTiraCajaTicket',
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

class function TRepositorioTiraCajaTicket.DefinicionesSql:
  TDefinicionesSql;
const
  PARAMETROS_OPERACION = 'pEMP,pALM,pCAJA,pOPE';
  PARAMETROS_RANGO = 'pEMP,pALM,pCAJA,pFDESDE,pFHASTA';
begin
  SetLength(Result, 7);
  Result[0] := DefinicionSql(
    'ObtenerEmpresa',
    SqlEmpresa,
    'pEMPRESA',
    'RAZON_SOCIAL_EMP,NIF_EMP,DIRECCION1_EMP,' +
    'CODIGO_POSTAL_EMP,POBLACION_EMP,PROVINCIA_EMP');
  Result[1] := DefinicionSql(
    'ListarLineasVenta',
    SqlLineasVenta,
    PARAMETROS_OPERACION,
    'CODIGO_UNIDAD_FACLIN,DESCRIPCION_ARTICULO_FACLIN,' +
    'CANTIDAD_FACLIN,TOTAL_FACLIN');
  Result[2] := DefinicionSql(
    'ListarFormasPago',
    SqlFormasPago,
    PARAMETROS_OPERACION,
    'CODIGO_FP_CFP,DESCR,IMPORTE_ENTREGADO_PAGO,' +
    'IMPORTE_CAMBIO_PAGO');
  Result[3] := DefinicionSql(
    'ListarLineasTraspaso',
    SqlLineasTraspaso,
    PARAMETROS_OPERACION,
    'CODIGO_UNIDAD_MOV,CANTIDAD_MOV,DESCRIPCION,' +
    'PRECIO_COSTE_UNITARIO_MOV');
  Result[4] := DefinicionSql(
    'ListarDepositos',
    SqlDepositos,
    PARAMETROS_OPERACION,
    'CODIGO_CLI_DEP,CLIENTE,CODIGO_UNIDAD_DEP,DESCRIPCION,' +
    'PRECIO_VENTA_DEP,CANTIDAD,IMPORTE_ANTICIPO_DEP');
  Result[5] := DefinicionSql(
    'ListarOperaciones',
    SqlOperaciones,
    PARAMETROS_RANGO + ',pTODAS_SERIES,pSERIES,' +
    'pINCLUIR_TRASPASOS,pINCLUIR_INGRESOS,pINCLUIR_GASTOS,' +
    'pINCLUIR_CREDITO,pCRONOLOGICO',
    'CODIGO_EMP_OPCAJA,CODIGO_ALM_OPCAJA,CODIGO_CAJA_OPCAJA,' +
    'NUMERO_OPERACION_OPCAJA,FECHA_OPERACION_OPCAJA,' +
    'SERIE_FAC_OPCAJA,NUMERO_FAC_OPCAJA,IMPORTE_TOTAL_OPCAJA,' +
    'CONCEPTO_GASTO_INGRESO_OPCAJA,CODIGO_ALM_CONTRA_OPCAJA,' +
    'TOTAL_BASES_FAC,TOTAL_IMPUESTOS_FAC,' +
    'TOTAL_LIQUIDO_FAC,FECHA_FAC,NIF_EMPRESA_FAC,' +
    'FORMATO_DOCUMENTO_EMP,GRUPO');
  Result[6] := DefinicionSql(
    'ListarSeries',
    SqlSeries,
    PARAMETROS_RANGO,
    'SERIE');
end;

constructor TRepositorioTiraCajaTicket.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

function TRepositorioTiraCajaTicket.AbrirConsulta(
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

procedure TRepositorioTiraCajaTicket.ConfigurarOperacion(
  AQuery: TUniQuery;
  const AEmpresa, AAlmacen, ACaja, AOperacion: string);
begin
  AQuery.ParamByName('pEMP').AsString := AEmpresa;
  AQuery.ParamByName('pALM').AsString := AAlmacen;
  AQuery.ParamByName('pCAJA').AsString := ACaja;
  AQuery.ParamByName('pOPE').AsString := AOperacion;
end;

procedure TRepositorioTiraCajaTicket.ConfigurarRango(
  AQuery: TUniQuery;
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate);
begin
  AQuery.ParamByName('pEMP').AsString := AEmpresa;
  AQuery.ParamByName('pALM').AsString := AAlmacen;
  AQuery.ParamByName('pCAJA').AsString := ACaja;
  AQuery.ParamByName('pFDESDE').AsDateTime := AFechaDesde;
  AQuery.ParamByName('pFHASTA').AsDateTime := AFechaHasta;
end;

function TRepositorioTiraCajaTicket.ObtenerEmpresa(
  const AEmpresa: string): TEmpresaTiraCajaTicket;
var
  sEmpresa: string;
  oQuery: TUniQuery;
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

function TRepositorioTiraCajaTicket.ListarLineasVenta(
  const AEmpresa, AAlmacen, ACaja, AOperacion: string):
  TArray<TLineaVentaTiraCaja>;
var
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  sOperacion: string;
  oLinea: TLineaVentaTiraCaja;
  oLista: TList<TLineaVentaTiraCaja>;
  oQuery: TUniQuery;
begin
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  sOperacion := AOperacion;
  oLista := TList<TLineaVentaTiraCaja>.Create;
  try
    oQuery := AbrirConsulta(
      1,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(
          AConsulta,
          sEmpresa,
          sAlmacen,
          sCaja,
          sOperacion);
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
        oLinea.Descripcion :=
          oQuery.FieldByName('DESCRIPCION_ARTICULO_FACLIN').AsString;
        oLinea.Cantidad :=
          oQuery.FieldByName('CANTIDAD_FACLIN').AsFloat;
        oLinea.Total :=
          oQuery.FieldByName('TOTAL_FACLIN').AsCurrency;
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

function TRepositorioTiraCajaTicket.ListarFormasPago(
  const AEmpresa, AAlmacen, ACaja, AOperacion: string):
  TArray<TFormaPagoTiraCaja>;
var
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  sOperacion: string;
  oLinea: TFormaPagoTiraCaja;
  oLista: TList<TFormaPagoTiraCaja>;
  oQuery: TUniQuery;
begin
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  sOperacion := AOperacion;
  oLista := TList<TFormaPagoTiraCaja>.Create;
  try
    oQuery := AbrirConsulta(
      2,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(
          AConsulta,
          sEmpresa,
          sAlmacen,
          sCaja,
          sOperacion);
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Codigo :=
          oQuery.FieldByName('CODIGO_FP_CFP').AsString;
        oLinea.Descripcion :=
          oQuery.FieldByName('DESCR').AsString;
        oLinea.ImporteEntregado :=
          oQuery.FieldByName('IMPORTE_ENTREGADO_PAGO').AsCurrency;
        oLinea.ImporteCambio :=
          oQuery.FieldByName('IMPORTE_CAMBIO_PAGO').AsCurrency;
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

function TRepositorioTiraCajaTicket.ListarLineasTraspaso(
  const AEmpresa, AAlmacen, ACaja, AOperacion: string):
  TArray<TLineaTraspasoTiraCaja>;
var
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  sOperacion: string;
  oLinea: TLineaTraspasoTiraCaja;
  oLista: TList<TLineaTraspasoTiraCaja>;
  oQuery: TUniQuery;
begin
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  sOperacion := AOperacion;
  oLista := TList<TLineaTraspasoTiraCaja>.Create;
  try
    oQuery := AbrirConsulta(
      3,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(
          AConsulta,
          sEmpresa,
          sAlmacen,
          sCaja,
          sOperacion);
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_MOV').AsString;
        oLinea.Descripcion :=
          oQuery.FieldByName('DESCRIPCION').AsString;
        oLinea.Cantidad :=
          oQuery.FieldByName('CANTIDAD_MOV').AsFloat;
        oLinea.PrecioCosteUnitario :=
          oQuery.FieldByName('PRECIO_COSTE_UNITARIO_MOV').AsFloat;
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

function TRepositorioTiraCajaTicket.ListarDepositos(
  const AEmpresa, AAlmacen, ACaja, AOperacion: string):
  TArray<TDepositoTiraCaja>;
var
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  sOperacion: string;
  oLinea: TDepositoTiraCaja;
  oLista: TList<TDepositoTiraCaja>;
  oQuery: TUniQuery;
begin
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  sOperacion := AOperacion;
  oLista := TList<TDepositoTiraCaja>.Create;
  try
    oQuery := AbrirConsulta(
      4,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarOperacion(
          AConsulta,
          sEmpresa,
          sAlmacen,
          sCaja,
          sOperacion);
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.CodigoCliente :=
          oQuery.FieldByName('CODIGO_CLI_DEP').AsString;
        oLinea.Cliente :=
          oQuery.FieldByName('CLIENTE').AsString;
        oLinea.CodigoUnidad :=
          oQuery.FieldByName('CODIGO_UNIDAD_DEP').AsString;
        oLinea.Descripcion :=
          oQuery.FieldByName('DESCRIPCION').AsString;
        oLinea.PrecioVenta :=
          oQuery.FieldByName('PRECIO_VENTA_DEP').AsCurrency;
        oLinea.Cantidad :=
          oQuery.FieldByName('CANTIDAD').AsFloat;
        oLinea.ImporteAnticipo :=
          oQuery.FieldByName('IMPORTE_ANTICIPO_DEP').AsCurrency;
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

function TRepositorioTiraCajaTicket.ListarOperaciones(
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate;
  const ASeries: TArray<string>;
  ACronologico, AIncluirTraspasos, AIncluirIngresos,
  AIncluirGastos, AIncluirCredito: Boolean):
  TArray<TOperacionTiraCaja>;
var
  bCronologico: Boolean;
  bTodasSeries: Boolean;
  bIncluirCredito: Boolean;
  bIncluirGastos: Boolean;
  bIncluirIngresos: Boolean;
  bIncluirTraspasos: Boolean;
  dFechaDesde: TDate;
  dFechaHasta: TDate;
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  sSeries: string;
  oLinea: TOperacionTiraCaja;
  oLista: TList<TOperacionTiraCaja>;
  oQuery: TUniQuery;
begin
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  dFechaDesde := AFechaDesde;
  dFechaHasta := AFechaHasta;
  sSeries := string.Join(',', ASeries);
  bTodasSeries := Length(ASeries) = 0;
  bCronologico := ACronologico;
  bIncluirTraspasos := AIncluirTraspasos;
  bIncluirIngresos := AIncluirIngresos;
  bIncluirGastos := AIncluirGastos;
  bIncluirCredito := AIncluirCredito;
  oLista := TList<TOperacionTiraCaja>.Create;
  try
    oQuery := AbrirConsulta(
      5,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarRango(
          AConsulta,
          sEmpresa,
          sAlmacen,
          sCaja,
          dFechaDesde,
          dFechaHasta);
        if bTodasSeries then
          AConsulta.ParamByName('pTODAS_SERIES').AsString := 'S'
        else
          AConsulta.ParamByName('pTODAS_SERIES').AsString := 'N';
        AConsulta.ParamByName('pSERIES').AsString := sSeries;
        AConsulta.ParamByName(
          'pINCLUIR_TRASPASOS').AsString :=
          IfThen(bIncluirTraspasos, 'S', 'N');
        AConsulta.ParamByName(
          'pINCLUIR_INGRESOS').AsString :=
          IfThen(bIncluirIngresos, 'S', 'N');
        AConsulta.ParamByName(
          'pINCLUIR_GASTOS').AsString :=
          IfThen(bIncluirGastos, 'S', 'N');
        AConsulta.ParamByName(
          'pINCLUIR_CREDITO').AsString :=
          IfThen(bIncluirCredito, 'S', 'N');
        AConsulta.ParamByName(
          'pCRONOLOGICO').AsString :=
          IfThen(bCronologico, 'S', 'N');
      end);
    try
      while not oQuery.Eof do
      begin
        oLinea.Empresa :=
          oQuery.FieldByName('CODIGO_EMP_OPCAJA').AsString;
        oLinea.Almacen :=
          oQuery.FieldByName('CODIGO_ALM_OPCAJA').AsString;
        oLinea.Caja :=
          oQuery.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
        oLinea.NumeroOperacion :=
          oQuery.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
        oLinea.FechaOperacion :=
          oQuery.FieldByName('FECHA_OPERACION_OPCAJA').AsDateTime;
        oLinea.SerieFactura :=
          oQuery.FieldByName('SERIE_FAC_OPCAJA').AsString;
        oLinea.NumeroFactura :=
          oQuery.FieldByName('NUMERO_FAC_OPCAJA').AsString;
        oLinea.ImporteTotal :=
          oQuery.FieldByName('IMPORTE_TOTAL_OPCAJA').AsCurrency;
        oLinea.ConceptoGastoIngreso :=
          oQuery.FieldByName(
            'CONCEPTO_GASTO_INGRESO_OPCAJA').AsString;
        oLinea.AlmacenContrapartida :=
          oQuery.FieldByName(
            'CODIGO_ALM_CONTRA_OPCAJA').AsString;
        oLinea.ImporteVerifactu :=
          oQuery.FieldByName('TOTAL_BASES_FAC').AsCurrency +
          oQuery.FieldByName('TOTAL_IMPUESTOS_FAC').AsCurrency;
        oLinea.TotalLiquido :=
          oQuery.FieldByName('TOTAL_LIQUIDO_FAC').AsCurrency;
        oLinea.FechaFactura :=
          oQuery.FieldByName('FECHA_FAC').AsDateTime;
        oLinea.NifEmpresaFactura :=
          oQuery.FieldByName('NIF_EMPRESA_FAC').AsString;
        oLinea.FormatoDocumento :=
          oQuery.FieldByName('FORMATO_DOCUMENTO_EMP').AsString;
        oLinea.Grupo :=
          oQuery.FieldByName('GRUPO').AsString;
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

function TRepositorioTiraCajaTicket.ListarSeries(
  const AEmpresa, AAlmacen, ACaja: string;
  AFechaDesde, AFechaHasta: TDate): TArray<string>;
var
  dFechaDesde: TDate;
  dFechaHasta: TDate;
  sAlmacen: string;
  sCaja: string;
  sEmpresa: string;
  oLista: TList<string>;
  oQuery: TUniQuery;
begin
  sEmpresa := AEmpresa;
  sAlmacen := AAlmacen;
  sCaja := ACaja;
  dFechaDesde := AFechaDesde;
  dFechaHasta := AFechaHasta;
  oLista := TList<string>.Create;
  try
    oQuery := AbrirConsulta(
      6,
      procedure(AConsulta: TUniQuery)
      begin
        ConfigurarRango(
          AConsulta,
          sEmpresa,
          sAlmacen,
          sCaja,
          dFechaDesde,
          dFechaHasta);
      end);
    try
      while not oQuery.Eof do
      begin
        oLista.Add(
          oQuery.FieldByName('SERIE').AsString);
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

end.
