{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataInformesCajaRepositorio                               }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC de los informes historicos de caja.                   }
{******************************************************************************}
unit UniDataInformesCajaRepositorio;

interface

uses
  System.Classes, Uni, inLibInformesCajaPersistenciaIntf;

function CrearRepositorioInformesCajaUniDAC(
  AConexion: TUniConnection): IRepositorioInformesCaja;

implementation

uses
  System.SysUtils, Data.DB,
  UniDataRectificativasSql, inLibArqueoIntf;

const
  // Rango pedido, ya formateado, para el subtitulo de los informes A4
  // (con un dato de fecha el informe solo podia mostrar [Date]). Va como
  // texto para que un informe sin filas no falle al formatear un nulo.
  SQL_PERIODO_INFORME =
    '       DATE_FORMAT(:DESDE, ''%d/%m/%Y'') AS FECHA_DESDE_INF, ' +
    '       DATE_FORMAT(:HASTA, ''%d/%m/%Y'') AS FECHA_HASTA_INF ';

type
  TResultadoInformeCajaUniDAC = class(
    TInterfacedObject,
    IResultadoInformeCaja)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioInformesCajaUniDAC = class(
    TInterfacedObject,
    IRepositorioInformesCaja, IRepositorioCuentaClientes)
  private
    FConexion: TUniConnection;
    function EjecutarInforme(
      const ASql: string;
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConstruirFiltroUbicaciones(
      const AUbicaciones: TUbicacionesInformeCaja): string;
    function ConstruirFiltroUbicacionesSolicitudes(
      const AUbicaciones: TUbicacionesInformeCaja): string;
    function ConstruirFiltroEstadosSolicitudes(
      const AEstados: TEstadosSolicitudTraspasoCaja): string;
    function ConstruirSqlSolicitudesTraspaso(
      const AFiltroUbicaciones, AFiltroEstados: string): string;
    procedure AnadirCabeceraOperacionesVenta(ALineas: TStrings);
    procedure AnadirAtributosOperacionesVenta(ALineas: TStrings);
    procedure AnadirImportesOperacionesVenta(ALineas: TStrings);
    procedure AnadirOrigenOperacionesVenta(ALineas: TStrings);
    procedure AnadirProveedorOperacionesVenta(ALineas: TStrings);
    procedure AnadirPrestamosOperacionesVenta(ALineas: TStrings;
      const AFiltroUbicaciones: string);
    procedure AnadirColoresOperacionesVenta(ALineas: TStrings);
    procedure AnadirPagosOperacionesVenta(ALineas: TStrings);
    procedure AnadirFiltrosOperacionesVenta(
      ALineas: TStrings;
      const AFiltroUbicaciones: string);
    function ConstruirSqlOperacionesVenta(
      const AFiltroUbicaciones: string): string;
    function ConstruirFiltroFormasPago(
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja): string;
    procedure AnadirColumnasPagos(ALineas: TStrings);
    procedure AnadirFacturaPagoSinOperacion(ALineas: TStrings);
    function EjecutarInformePagos(
      const ASql: string;
      const ASolicitud: TSolicitudInformeCaja;
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
    ): IResultadoInformeCaja;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarCuentaClientes(const ACliente: string;
      AResumen: Boolean): IResultadoInformeCaja;
    function ConsultarArqueos(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarDepositos(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarOperaciones(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarTotalesOperaciones(
      const ASolicitud: TSolicitudInformeCaja
    ): IResultadoInformeCaja;
    function ListarFormasPago(
      const ASolicitud: TSolicitudInformeCaja
    ): TFormasPagoInformeCaja;
    function ConsultarPagos(
      const ASolicitud: TSolicitudInformeCaja;
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarTotalesPagos(
      const ASolicitud: TSolicitudInformeCaja;
      const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
    ): IResultadoInformeCaja;
    function ListarUbicaciones: TUbicacionesInformeCaja;
    function ConsultarOperacionesVenta(
      const ASolicitud: TSolicitudOperacionesVentaCaja
    ): IResultadoInformeCaja;
    function ListarEstadosSolicitudesTraspaso:
      TEstadosSolicitudTraspasoCaja;
    function ConsultarSolicitudesTraspaso(
      const ASolicitud: TSolicitudTraspasosInformeCaja
    ): IResultadoInformeCaja;
    function ConsultarArqueosHistorico(
      const AEmpresa, AAlmacen, ACaja: string
    ): IResultadoInformeCaja;
    function ConsultarValesPendientes(
      const AFiltro, APin: string
    ): IResultadoInformeCaja;
  end;

constructor TResultadoInformeCajaUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoInformeCajaUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoInformeCajaUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioInformesCajaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformesCajaUniDAC.EjecutarInforme(
  const ASql: string;
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := ASolicitud.FechaHasta;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarCuentaClientes(
  const ACliente: string; AResumen: Boolean): IResultadoInformeCaja;
const
  Enlaces =
    ' LEFT JOIN fza_clientes C ON C.CODIGO_CLI_CLI = D.CODIGO_CLI_DEP ' +
    ' LEFT JOIN fza_empresas E ON E.CODIGO_EMP_EMP = D.CODIGO_EMP_DEP ' +
    ' LEFT JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = D.CODIGO_ALM_DEP ';
  Filtro =
    ' WHERE COALESCE(D.ESAPARTADO_DEP, ''N'') <> ''S'' ' +
    ' AND (:CLIENTE = '''' OR D.CODIGO_CLI_DEP = :CLIENTE) ';
  Origen = ' FROM fza_depositos_cliente D ' + Enlaces + Filtro;
  // Cobros a cuenta del depósito: CB en positivo (el consumo del anticipo
  // al vender va en negativo), sin las ventas anuladas, como el arqueo.
  EnlaceCobro =
    ' O.CODIGO_EMP_OPCAJA = D.CODIGO_EMP_DEP ' +
    ' AND O.ID_DEPOSITO_OPCAJA = D.ID_DEPOSITO_DEP ';
  CondicionCobro =
    ' AND O.TIPO_OPERACION_OPCAJA = :TIPO_CB ' +
    ' AND O.IMPORTE_TOTAL_OPCAJA > 0 ';
  OrigenCobros =
    ' FROM fza_depositos_cliente D ' +
    ' JOIN fza_caja_operaciones O ON ' + EnlaceCobro +
    Enlaces + Filtro + CondicionCobro;
  Pendiente =
    'CASE WHEN D.ESTADO_DEP = ''PENDIENTE'' THEN GREATEST(0, ' +
    'COALESCE(D.PRECIO_VENTA_DEP, 0) * ' +
    'COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1) - ' +
    'COALESCE(D.IMPORTE_ANTICIPO_DEP, 0)) ELSE 0 END';
  Cabecera =
    'D.CODIGO_CLI_DEP AS CLIENTE, ' +
    'COALESCE(C.RAZON_SOCIAL_CLI, D.CODIGO_CLI_DEP) AS NOMBRE, ' +
    'D.CODIGO_EMP_DEP AS EMPRESA, ' +
    'COALESCE(E.RAZON_SOCIAL_EMP, D.CODIGO_EMP_DEP) AS NOMBRE_EMPRESA, ' +
    'D.CODIGO_ALM_DEP AS ALMACEN, ' +
    'COALESCE(A.NOMBRE_ALM_ALM, D.CODIGO_ALM_DEP) AS TIENDA, ' +
    'COALESCE(C.TOTAL_LIMITE_CREDITO_CLI, 0) AS LIMITE, ';
var
  Consulta: TUniQuery;
  Sql: string;
  ExcluirAnuladas: string;
  Cobros: string;
begin
  ExcluirAnuladas := SQLExcluirVentaRetirada(
    'O.CODIGO_EMP_OPCAJA', 'O.SERIE_FAC_OPCAJA', 'O.NUMERO_FAC_OPCAJA');
  Cobros :=
    '(SELECT COALESCE(SUM(O.IMPORTE_TOTAL_OPCAJA), 0) ' +
    ' FROM fza_caja_operaciones O WHERE ' + EnlaceCobro +
    CondicionCobro + ExcluirAnuladas + ')';
  if AResumen then
    Sql := 'SELECT ' + Cabecera +
      'SUM(' + Pendiente + ') AS PENDIENTE, ' +
      'MIN(D.FECHA_CREACION_DEP) AS FECHA, ' +
      'MAX(GREATEST(0, DATEDIFF(CURRENT_DATE, ' +
      'D.FECHA_CREACION_DEP))) AS DIAS ' + Origen +
      ' AND (' + Pendiente + ') > 0 ' +
      ' GROUP BY D.CODIGO_CLI_DEP, C.RAZON_SOCIAL_CLI, ' +
      'D.CODIGO_EMP_DEP, E.RAZON_SOCIAL_EMP, D.CODIGO_ALM_DEP, ' +
      'A.NOMBRE_ALM_ALM, C.TOTAL_LIMITE_CREDITO_CLI ' +
      ' ORDER BY CLIENTE, EMPRESA, ALMACEN'
  else
    // Extracto: el depósito con su entrega inicial y, debajo, una fila por
    // cobro a cuenta. Cada cobro resta de lo pendiente, así que la suma de
    // PENDIENTE sigue siendo el saldo del depósito.
    Sql := 'SELECT * FROM (' +
      'SELECT ' + Cabecera +
      'D.ID_DEPOSITO_DEP AS DEPOSITO, ' +
      'D.FECHA_CREACION_DEP AS FECHA, D.ESTADO_DEP AS ESTADO, ' +
      'COALESCE(D.PRECIO_VENTA_DEP, 0) * ' +
      'COALESCE(D.CANTIDAD_PENDIENTE_DEP, 1) AS IMPORTE, ' +
      'COALESCE(D.IMPORTE_ANTICIPO_DEP, 0) - ' + Cobros + ' AS ENTREGADO, ' +
      Pendiente + ' + CASE WHEN D.ESTADO_DEP = ''PENDIENTE'' THEN ' +
      Cobros + ' ELSE 0 END AS PENDIENTE, ' +
      'D.FECHA_CREACION_DEP AS FECHA_DEPOSITO, 0 AS ORDEN ' + Origen +
      ' UNION ALL ' +
      'SELECT ' + Cabecera +
      'D.ID_DEPOSITO_DEP AS DEPOSITO, O.FECHA_OPERACION_OPCAJA AS FECHA, ' +
      '''COBRO PARCIAL'' AS ESTADO, ' +
      'NULL AS IMPORTE, ' +
      'O.IMPORTE_TOTAL_OPCAJA AS ENTREGADO, ' +
      'CASE WHEN D.ESTADO_DEP = ''PENDIENTE'' THEN ' +
      '-O.IMPORTE_TOTAL_OPCAJA ELSE 0 END AS PENDIENTE, ' +
      'D.FECHA_CREACION_DEP AS FECHA_DEPOSITO, 1 AS ORDEN ' +
      OrigenCobros + ExcluirAnuladas +
      ') X ORDER BY CLIENTE, FECHA_DEPOSITO, DEPOSITO, ORDEN, FECHA';
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := Sql;
    Consulta.ParamByName('CLIENTE').AsString := Trim(ACliente);
    if not AResumen then
      Consulta.ParamByName('TIPO_CB').AsString := TipoOpCobroCuenta;
    Consulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(Consulta);
    Consulta := nil;
  finally
    Consulta.Free;
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarArqueos(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  Result := EjecutarInforme(
    'SELECT a.*, ' +
    SQL_PERIODO_INFORME +
    '  FROM fza_caja_arqueos a ' +
    ' WHERE a.CODIGO_EMP_ARQ = :EMPRESA ' +
    '   AND a.CODIGO_ALM_ARQ = :ALMACEN ' +
    '   AND a.CODIGO_CAJA_ARQ = :CAJA ' +
    '   AND a.FECHA_DESDE_ARQ >= :DESDE ' +
    '   AND a.FECHA_DESDE_ARQ < DATE_ADD(:HASTA, INTERVAL 1 DAY) ' +
    ' ORDER BY a.FECHA_DESDE_ARQ DESC, a.CODIGO_ARQ DESC',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ConsultarDepositos(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  Result := EjecutarInforme(
    'SELECT d.*, ' +
    SQL_PERIODO_INFORME +
    '  FROM fza_depositos_cliente d ' +
    ' WHERE d.CODIGO_EMP_DEP = :EMPRESA ' +
    '   AND d.CODIGO_ALM_DEP = :ALMACEN ' +
    '   AND d.CODIGO_CAJA_DEP = :CAJA ' +
    '   AND DATE(d.FECHA_CREACION_DEP) BETWEEN :DESDE AND :HASTA ' +
    ' ORDER BY d.FECHA_CREACION_DEP, d.ID_DEPOSITO_DEP',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ConsultarOperaciones(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  // NUMERO_FAC_INF: los depositos sin factura guardan '0' en
  // NUMERO_FAC_OPCAJA; el informe debe dejar la columna vacia.
  Result := EjecutarInforme(
    'SELECT o.*, ' +
    '       CASE WHEN TRIM(LEADING ''0'' FROM ' +
    '                 TRIM(COALESCE(o.NUMERO_FAC_OPCAJA, ''''))) = '''' ' +
    '            THEN NULL ' +
    '            ELSE o.NUMERO_FAC_OPCAJA END AS NUMERO_FAC_INF, ' +
    SQL_PERIODO_INFORME +
    '  FROM fza_caja_operaciones o ' +
    ' WHERE o.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND o.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    '   AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
    '   AND DATE(o.FECHA_OPERACION_OPCAJA) BETWEEN :DESDE AND :HASTA ' +
    ' ORDER BY o.FECHA_OPERACION_OPCAJA, o.NUMERO_OPERACION_OPCAJA',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ConsultarTotalesOperaciones(
  const ASolicitud: TSolicitudInformeCaja
): IResultadoInformeCaja;
begin
  // Mismo filtro que ConsultarOperaciones. Los importes se suman con el
  // signo guardado en cada operacion.
  Result := EjecutarInforme(
    'SELECT o.TIPO_OPERACION_OPCAJA, ' +
    '       COUNT(*) AS NUMERO_OPERACIONES_INF, ' +
    '       SUM(COALESCE(o.IMPORTE_TOTAL_OPCAJA, 0)) ' +
    '         AS IMPORTE_TOTAL_INF ' +
    '  FROM fza_caja_operaciones o ' +
    ' WHERE o.CODIGO_EMP_OPCAJA = :EMPRESA ' +
    '   AND o.CODIGO_ALM_OPCAJA = :ALMACEN ' +
    '   AND o.CODIGO_CAJA_OPCAJA = :CAJA ' +
    '   AND DATE(o.FECHA_OPERACION_OPCAJA) BETWEEN :DESDE AND :HASTA ' +
    ' GROUP BY o.TIPO_OPERACION_OPCAJA ' +
    ' ORDER BY o.TIPO_OPERACION_OPCAJA',
    ASolicitud);
end;

function TRepositorioInformesCajaUniDAC.ListarFormasPago(
  const ASolicitud: TSolicitudInformeCaja
): TFormasPagoInformeCaja;
var
  oConsulta: TUniQuery;
  iFormaPago: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT p.CODIGO_FP_CFP AS COD, ' +
      '       COALESCE(fp.DESCRIPCION_FORMA_PAGO_FP, ' +
      '                p.CODIGO_FP_CFP) AS DESCR ' +
      '  FROM vi_caja_pagos p ' +
      '  LEFT JOIN fza_formas_pago fp ' +
      '    ON fp.CODIGO_FP_FP = p.CODIGO_FP_CFP ' +
      ' WHERE p.CODIGO_EMP_PAGO = :EMPRESA ' +
      '   AND p.CODIGO_ALM_PAGO = :ALMACEN ' +
      '   AND p.CODIGO_CAJA_PAGO = :CAJA ' +
      '   AND DATE(p.FECHA_PAGO) BETWEEN :DESDE AND :HASTA ' +
      ' ORDER BY COD';
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := ASolicitud.FechaHasta;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iFormaPago := 0;
    while not oConsulta.Eof do
    begin
      Result[iFormaPago].Codigo :=
        oConsulta.FieldByName('COD').AsString;
      Result[iFormaPago].Descripcion :=
        oConsulta.FieldByName('DESCR').AsString;
      Inc(iFormaPago);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConstruirFiltroFormasPago(
  const ACodigosFormaPago: TCodigosFormaPagoInformeCaja): string;
var
  iCodigo: Integer;
begin
  Result := '';
  for iCodigo := 0 to High(ACodigosFormaPago) do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + ':FP' + IntToStr(iCodigo);
  end;
  if Result <> '' then
    Result := '   AND v.CODIGO_FP_CFP IN (' + Result + ')';
end;

procedure TRepositorioInformesCajaUniDAC.AnadirColumnasPagos(
  ALineas: TStrings);
begin
  // Columnas de vi_caja_pagos. La divisa vacia (pagos anteriores a que se
  // grabara) es la de la empresa: el TPV cobra siempre en EUR.
  ALineas.Add('SELECT v.CODIGO_EMP_PAGO, v.CODIGO_ALM_PAGO,');
  ALineas.Add('       v.CODIGO_CAJA_PAGO, v.SERIE_OPERACION_PAGO,');
  ALineas.Add('       v.NUMERO_OPERACION_PAGO, v.NUMERO_LINEA_PAGO,');
  ALineas.Add('       v.CODIGO_FP_CFP,');
  ALineas.Add('       COALESCE(NULLIF(TRIM(v.CODIGO_DIVISA_PAGO), ''''),');
  ALineas.Add('                ''EUR'') AS CODIGO_DIVISA_PAGO,');
  ALineas.Add('       v.RED_BLOCKCHAIN_PAGO, v.FACTOR_CAMBIO_PAGO,');
  ALineas.Add('       v.IMPORTE_DIVISA_PAGO, v.IMPORTE_ENTREGADO_PAGO,');
  ALineas.Add('       v.IMPORTE_CAMBIO_PAGO, v.REFERENCIA_FACPAG,');
  ALineas.Add('       v.OBSERVACIONES_PAGO, v.INSTANTE_MODIF,');
  ALineas.Add('       v.INSTANTE_ALTA, v.USUARIO_ALTA, v.FECHA_PAGO,');
  AnadirFacturaPagoSinOperacion(ALineas);
  ALineas.Add('       v.DESCRIPCION_FP_PAGO, v.TIPO_OPERACION_PAGO,');
  ALineas.Add('       v.EMPLEADO_PAGO, v.CODIGO_CLI_PAGO,');
  ALineas.Add('       v.IMPORTE_OPERACION_PAGO, v.ARQUEO_PAGO,');
  ALineas.Add('       v.SERIE_ORIGEN_PAGO, v.NUMERO_ORIGEN_PAGO,');
  ALineas.Add('       v.MOTIVO_DEVOLUCION_PAGO, v.TIPO_FAC_PAGO,');
  ALineas.Add('       v.FASE_FAC_PAGO, v.ESCONSOLIDADA_FAC_PAGO,');
  ALineas.Add('       v.TOTAL_FAC_PAGO, v.CODIGO_CLI_FAC_PAGO,');
  ALineas.Add('       v.CLIENTE_FAC_PAGO,');
  ALineas.Add(SQL_PERIODO_INFORME);
end;

procedure TRepositorioInformesCajaUniDAC.AnadirFacturaPagoSinOperacion(
  ALineas: TStrings);
const
  SQL_FACTURA_OPERACION =
    '           FROM fza_facturas fx' + sLineBreak +
    '          WHERE fx.CODIGO_EMP_FAC = v.CODIGO_EMP_PAGO' + sLineBreak +
    '            AND fx.CODIGO_ALM_FAC = v.CODIGO_ALM_PAGO' + sLineBreak +
    '            AND fx.CODIGO_CAJA_FAC = v.CODIGO_CAJA_PAGO' + sLineBreak +
    '            AND fx.NUMERO_OPERACION_FAC =' + sLineBreak +
    '                v.NUMERO_OPERACION_PAGO' + sLineBreak +
    '          ORDER BY fx.SERIE_FAC = v.SERIE_OPERACION_PAGO DESC,' +
    sLineBreak +
    '                   fx.SERIE_FAC, fx.NUMERO_FAC' + sLineBreak +
    '          LIMIT 1)';
begin
  // Pagos cuya operacion ya no esta en fza_caja_operaciones (en la demo,
  // las de abril): la factura se busca por la operacion que guarda
  // fza_facturas. Solo cuando la vista no encuentra la operacion.
  ALineas.Add('       CASE WHEN v.TIPO_OPERACION_PAGO IS NOT NULL');
  ALineas.Add('            THEN v.NUMERO_FAC_PAGO');
  ALineas.Add('            ELSE (SELECT fx.NUMERO_FAC');
  ALineas.Add(SQL_FACTURA_OPERACION);
  ALineas.Add('       END AS NUMERO_FAC_PAGO,');
  ALineas.Add('       CASE WHEN v.TIPO_OPERACION_PAGO IS NOT NULL');
  ALineas.Add('            THEN v.SERIE_FAC_PAGO');
  ALineas.Add('            ELSE (SELECT fx.SERIE_FAC');
  ALineas.Add(SQL_FACTURA_OPERACION);
  ALineas.Add('       END AS SERIE_FAC_PAGO,');
end;

function TRepositorioInformesCajaUniDAC.EjecutarInformePagos(
  const ASql: string;
  const ASolicitud: TSolicitudInformeCaja;
  const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
  iCodigo: Integer;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('EMPRESA').AsString := ASolicitud.Empresa;
    oConsulta.ParamByName('ALMACEN').AsString := ASolicitud.Almacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.Caja;
    oConsulta.ParamByName('DESDE').AsDateTime := ASolicitud.FechaDesde;
    oConsulta.ParamByName('HASTA').AsDateTime := ASolicitud.FechaHasta;
    for iCodigo := 0 to High(ACodigosFormaPago) do
    begin
      oConsulta.ParamByName('FP' + IntToStr(iCodigo)).AsString :=
        ACodigosFormaPago[iCodigo];
    end;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarPagos(
  const ASolicitud: TSolicitudInformeCaja;
  const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
): IResultadoInformeCaja;
var
  slSQL: TStringList;
begin
  slSQL := TStringList.Create;
  try
    AnadirColumnasPagos(slSQL);
    slSQL.Add('  FROM vi_caja_pagos v');
    slSQL.Add(' WHERE v.CODIGO_EMP_PAGO = :EMPRESA');
    slSQL.Add('   AND v.CODIGO_ALM_PAGO = :ALMACEN');
    slSQL.Add('   AND v.CODIGO_CAJA_PAGO = :CAJA');
    slSQL.Add('   AND DATE(v.FECHA_PAGO) BETWEEN :DESDE AND :HASTA');
    slSQL.Add(ConstruirFiltroFormasPago(ACodigosFormaPago));
    slSQL.Add(' ORDER BY v.FECHA_PAGO, v.NUMERO_OPERACION_PAGO,');
    slSQL.Add('          v.NUMERO_LINEA_PAGO');
    Result := EjecutarInformePagos(
      slSQL.Text,
      ASolicitud,
      ACodigosFormaPago);
  finally
    FreeAndNil(slSQL);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarTotalesPagos(
  const ASolicitud: TSolicitudInformeCaja;
  const ACodigosFormaPago: TCodigosFormaPagoInformeCaja
): IResultadoInformeCaja;
var
  slSQL: TStringList;
begin
  slSQL := TStringList.Create;
  try
    slSQL.Add('SELECT v.CODIGO_FP_CFP,');
    slSQL.Add('       COALESCE(MAX(v.DESCRIPCION_FP_PAGO),');
    slSQL.Add('                v.CODIGO_FP_CFP) AS DESCRIPCION_FP_PAGO,');
    slSQL.Add('       COUNT(*) AS NUMERO_PAGOS_INF,');
    slSQL.Add('       SUM(v.IMPORTE_ENTREGADO_PAGO) AS ENTREGADO_INF,');
    slSQL.Add('       SUM(v.IMPORTE_CAMBIO_PAGO) AS CAMBIO_INF,');
    slSQL.Add('       SUM(v.IMPORTE_ENTREGADO_PAGO -');
    slSQL.Add('           v.IMPORTE_CAMBIO_PAGO) AS NETO_INF');
    slSQL.Add('  FROM vi_caja_pagos v');
    slSQL.Add(' WHERE v.CODIGO_EMP_PAGO = :EMPRESA');
    slSQL.Add('   AND v.CODIGO_ALM_PAGO = :ALMACEN');
    slSQL.Add('   AND v.CODIGO_CAJA_PAGO = :CAJA');
    slSQL.Add('   AND DATE(v.FECHA_PAGO) BETWEEN :DESDE AND :HASTA');
    slSQL.Add(ConstruirFiltroFormasPago(ACodigosFormaPago));
    slSQL.Add(' GROUP BY v.CODIGO_FP_CFP');
    slSQL.Add(' ORDER BY v.CODIGO_FP_CFP');
    Result := EjecutarInformePagos(
      slSQL.Text,
      ASolicitud,
      ACodigosFormaPago);
  finally
    FreeAndNil(slSQL);
  end;
end;

function TRepositorioInformesCajaUniDAC.ListarUbicaciones:
  TUbicacionesInformeCaja;
var
  oConsulta: TUniQuery;
  iUbicacion: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT Empresa, NombreEmpresa, Almacen, ' +
      '       `NombreAlmacén`, Caja, NombreCaja ' +
      '  FROM vi_cajasdef ' +
      ' ORDER BY Empresa, Almacen, Caja';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iUbicacion := 0;
    while not oConsulta.Eof do
    begin
      Result[iUbicacion].Empresa :=
        oConsulta.FieldByName('Empresa').AsString;
      Result[iUbicacion].NombreEmpresa :=
        oConsulta.FieldByName('NombreEmpresa').AsString;
      Result[iUbicacion].Almacen :=
        oConsulta.FieldByName('Almacen').AsString;
      Result[iUbicacion].NombreAlmacen :=
        oConsulta.FieldByName('NombreAlmacén').AsString;
      Result[iUbicacion].Caja :=
        oConsulta.FieldByName('Caja').AsString;
      Result[iUbicacion].NombreCaja :=
        oConsulta.FieldByName('NombreCaja').AsString;
      Inc(iUbicacion);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConstruirFiltroUbicaciones(
  const AUbicaciones: TUbicacionesInformeCaja): string;
var
  iUbicacion: Integer;
  sSufijo: string;
begin
  Result := '   AND (';
  for iUbicacion := 0 to High(AUbicaciones) do
  begin
    if iUbicacion > 0 then
    begin
      Result := Result + sLineBreak + '        OR ';
    end;
    sSufijo := IntToStr(iUbicacion);
    Result := Result +
      '(o.CODIGO_EMP_OPCAJA = :pEMPRESA' + sSufijo +
      ' AND o.CODIGO_ALM_OPCAJA = :pALMACEN' + sSufijo +
      ' AND o.CODIGO_CAJA_OPCAJA = :pCAJA' + sSufijo + ')';
  end;
  Result := Result + ')';
end;

procedure TRepositorioInformesCajaUniDAC.AnadirCabeceraOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('SELECT DATE(o.FECHA_OPERACION_OPCAJA) AS FECHA_DIA,');
  ALineas.Add('       DATE(:pDESDE) AS FECHA_DESDE,');
  ALineas.Add('       DATE(:pHASTA) AS FECHA_HASTA,');
  ALineas.Add('       o.CODIGO_EMP_OPCAJA,');
  ALineas.Add('       o.CODIGO_ALM_OPCAJA,');
  ALineas.Add('       o.CODIGO_CAJA_OPCAJA,');
  ALineas.Add('       CONCAT(o.CODIGO_EMP_OPCAJA, ''/'',');
  ALineas.Add('              o.CODIGO_ALM_OPCAJA, ''/'',');
  ALineas.Add('              o.CODIGO_CAJA_OPCAJA) AS CLAVE_CAJA,');
  ALineas.Add('       o.NUMERO_OPERACION_OPCAJA,');
  ALineas.Add('       fl.LINEA_FACLIN,');
  ALineas.Add('       fl.CODIGO_ART_FACLIN AS ARTICULO,');
end;

function SqlValorEjeOperacion(const AEje: string): string;
var
  iAtributo: Integer;
  Posicion: string;
begin
  Result := '(SELECT MAX(COALESCE(NULLIF(CASE';
  for iAtributo := 1 to 5 do
  begin
    Posicion := IntToStr(iAtributo);
    Result := Result + ' WHEN UPPER(TRIM(fl.ATTR' + Posicion +
      '_NOMBRE_FACLIN)) = UPPER(TRIM(va.NOMBRE_VA)) THEN fl.ATTR' +
      Posicion + '_VALOR_FACLIN';
  end;
  Result := Result + ' ELSE '''' END, ''''), av.AV, ''''))' +
    ' FROM fza_articulos art' +
    ' LEFT JOIN fza_articulos_skus sk ON sk.CODIGO_UNIDAD_SKU =' +
    ' fl.CODIGO_UNIDAD_FACLIN' +
    ' JOIN VI_VARIACIONES_EJES ej ON ej.ID_VAR_VA =' +
    ' COALESCE(sk.CODIGO_VAR_SKU, art.TIPO_VARIACION_ART)' +
    ' AND ej.EJE_VA = ' + QuotedStr(AEje) +
    ' JOIN fza_variaciones_atributos va ON va.ID_VAR_VA = ej.ID_VAR_VA' +
    ' AND va.ID_ATB_VA = ej.ID_ATB_VA' +
    ' LEFT JOIN fza_atributos_sku sa ON sa.CODIGO_UNIDAD_SKU_SA =' +
    ' sk.CODIGO_UNIDAD_SKU AND sa.ID_AV_SA IN' +
    ' (SELECT ID_AV FROM fza_atributos_valores' +
    ' WHERE ID_VA_AV = ej.ID_ATB_VA)' +
    ' LEFT JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA' +
    ' WHERE art.CODIGO_ART_ART = fl.CODIGO_ART_FACLIN)';
end;

procedure TRepositorioInformesCajaUniDAC.AnadirAtributosOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('       COALESCE(' + SqlValorEjeOperacion('F') +
    ', '''') AS COLOR,');
  ALineas.Add('       COALESCE(cb.HEX_COLOR_BASICO, '''')');
  ALineas.Add('         AS HEX_COLOR_BASICO,');
  ALineas.Add('       COALESCE(' + SqlValorEjeOperacion('S') +
    ', '''') AS COPA,');
  ALineas.Add('       COALESCE(' + SqlValorEjeOperacion('P') +
    ', '''') AS TALLA,');
  ALineas.Add('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
  ALineas.Add('                ap.CODIGO_PRV_AP, '''') AS PROVEEDOR,');
  ALineas.Add('       COALESCE(ap.REF_PROVEEDOR_AP, '''') AS MODELO,');
  ALineas.Add('       fl.DESCRIPCION_ARTICULO_FACLIN AS DESCRIPCION,');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirImportesOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('       COALESCE(fl.CANTIDAD_FACLIN, 0) AS CANTIDAD,');
  ALineas.Add('       ROUND(COALESCE(fl.CANTIDAD_FACLIN, 0) *');
  ALineas.Add('       COALESCE(fl.PRECIO_SALIDA_FACLIN,');
  ALineas.Add('                fl.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, 0), 2)');
  ALineas.Add('         AS BRUTO,');
  ALineas.Add('       COALESCE(fl.PORCENTAJE_DTO_FACLIN, 0)');
  ALineas.Add('         AS PORCENTAJE_DTO,');
  ALineas.Add('       COALESCE(fl.TOTAL_FACLIN, 0) AS NETO_ARTICULO,');
  // FZ-ISSUE-343: el cobro se reparte sobre el total de la factura; en la
  // liquidación de un apartado la fila VE vale el PVP, pero la factura
  // descuenta el anticipo (39,95 - 10,00) y eso es lo que se cobra.
  ALineas.Add('       COALESCE(');
  ALineas.Add('         pg.INGRESOS_OPERACION * fl.TOTAL_FACLIN /');
  ALineas.Add('         NULLIF((SELECT SUM(ft.TOTAL_FACLIN)');
  ALineas.Add('                   FROM fza_facturas_lineas ft');
  ALineas.Add('                  WHERE ft.CODIGO_EMP_FACLIN =');
  ALineas.Add('                        fl.CODIGO_EMP_FACLIN');
  ALineas.Add('                    AND ft.SERIE_FAC_FACLIN =');
  ALineas.Add('                        fl.SERIE_FAC_FACLIN');
  ALineas.Add('                    AND ft.NUMERO_FAC_FACLIN =');
  ALineas.Add('                        fl.NUMERO_FAC_FACLIN), 0), 0)');
  ALineas.Add('         AS INGRESOS,');
  ALineas.Add('       COALESCE(NULLIF(fl.CODIGO_VENDEDOR_FACLIN, ''''),');
  ALineas.Add('                o.CODIGO_EMPLEADO_OPCAJA, '''') AS VENDEDOR,');
  ALineas.Add('       COALESCE(pg.FORMAS_PAGO, '''') AS FORMA_PAGO,');
  ALineas.Add('       CONCAT_WS(''.'', o.CODIGO_EMP_OPCAJA,');
  ALineas.Add('                 o.TIPO_OPERACION_OPCAJA,');
  ALineas.Add('                 o.SERIE_FAC_OPCAJA,');
  ALineas.Add('                 o.NUMERO_FAC_OPCAJA) AS DOCUMENTO,');
  ALineas.Add(' COALESCE(NULLIF(fl.TIPO_CANTIDAD_ARTICULO_FACLIN, ''''),');
  ALineas.Add('   (SELECT a.TIPO_CANTIDAD_ART FROM fza_articulos a');
  ALineas.Add('    WHERE a.CODIGO_ART_ART = fl.CODIGO_ART_FACLIN), '''')');
  ALineas.Add('   AS UNIDAD_CANTIDAD');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirOrigenOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  FROM fza_caja_operaciones o');
  ALineas.Add('  JOIN fza_facturas_lineas fl');
  ALineas.Add('    ON fl.SERIE_FAC_FACLIN = o.SERIE_FAC_OPCAJA');
  ALineas.Add('   AND fl.NUMERO_FAC_FACLIN = o.NUMERO_FAC_OPCAJA');
  ALineas.Add('   AND fl.CODIGO_EMP_FACLIN = o.CODIGO_EMP_OPCAJA');
  AnadirProveedorOperacionesVenta(ALineas);
end;

procedure TRepositorioInformesCajaUniDAC.AnadirProveedorOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  LEFT JOIN fza_articulos_proveedores ap');
  ALineas.Add('    ON ap.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
  ALineas.Add('   AND ap.CODIGO_PRV_AP =');
  ALineas.Add('       COALESCE(NULLIF(TRIM(fl.CODIGO_PRV_FACLIN), ''''),');
  ALineas.Add('         (SELECT apx.CODIGO_PRV_AP');
  ALineas.Add('            FROM fza_articulos_proveedores apx');
  ALineas.Add('           WHERE apx.CODIGO_ART_AP = fl.CODIGO_ART_FACLIN');
  ALineas.Add('           ORDER BY CASE');
  ALineas.Add('             WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S''');
  ALineas.Add('             THEN 0 ELSE 1');
  ALineas.Add('           END, apx.FECHA_VALIDEZ_AP DESC,');
  ALineas.Add('           apx.CODIGO_PRV_AP');
  ALineas.Add('           LIMIT 1))');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirColoresOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  LEFT JOIN (');
  ALineas.Add('    SELECT sa.CODIGO_UNIDAD_SKU_SA');
  ALineas.Add('             AS CODIGO_UNIDAD_SKU,');
  ALineas.Add('           MAX(atb.HEX_ATB) AS HEX_COLOR_BASICO');
  ALineas.Add('      FROM fza_atributos_sku sa');
  ALineas.Add('      JOIN fza_articulos_skus sk');
  ALineas.Add('        ON sk.CODIGO_UNIDAD_SKU =');
  ALineas.Add('           sa.CODIGO_UNIDAD_SKU_SA');
  ALineas.Add('      JOIN fza_atributos_valores av');
  ALineas.Add('        ON av.ID_AV = sa.ID_AV_SA');
  ALineas.Add('       AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')');
  ALineas.Add('      JOIN fza_articulos_atributos_basicos aab');
  ALineas.Add('        ON aab.CODIGO_ART_AAB = sk.CODIGO_ART_SKU');
  ALineas.Add('       AND aab.ID_AV_AAB = av.ID_AV');
  ALineas.Add('      JOIN fza_atributos_basicos atb');
  ALineas.Add('        ON atb.ID_ATB = aab.ID_ATB_AAB');
  ALineas.Add('     GROUP BY sa.CODIGO_UNIDAD_SKU_SA');
  ALineas.Add('  ) cb');
  ALineas.Add('    ON cb.CODIGO_UNIDAD_SKU =');
  ALineas.Add('       fl.CODIGO_UNIDAD_FACLIN');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirPagosOperacionesVenta(
  ALineas: TStrings);
begin
  ALineas.Add('  LEFT JOIN (');
  ALineas.Add('    SELECT p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
  ALineas.Add('           p.CODIGO_CAJA_PAGO, p.NUMERO_OPERACION_PAGO,');
  ALineas.Add('           GROUP_CONCAT(DISTINCT p.CODIGO_FP_CFP');
  ALineas.Add('             ORDER BY p.CODIGO_FP_CFP SEPARATOR '', '')');
  ALineas.Add('             AS FORMAS_PAGO,');
  ALineas.Add('           SUM(p.IMPORTE_ENTREGADO_PAGO -');
  ALineas.Add('               p.IMPORTE_CAMBIO_PAGO) AS INGRESOS_OPERACION');
  ALineas.Add('      FROM fza_caja_pagos p');
  ALineas.Add('     GROUP BY p.CODIGO_EMP_PAGO, p.CODIGO_ALM_PAGO,');
  ALineas.Add('              p.CODIGO_CAJA_PAGO,');
  ALineas.Add('              p.NUMERO_OPERACION_PAGO');
  ALineas.Add('  ) pg');
  ALineas.Add('    ON pg.CODIGO_EMP_PAGO = o.CODIGO_EMP_OPCAJA');
  ALineas.Add('   AND pg.CODIGO_ALM_PAGO = o.CODIGO_ALM_OPCAJA');
  ALineas.Add('   AND pg.CODIGO_CAJA_PAGO = o.CODIGO_CAJA_OPCAJA');
  ALineas.Add('   AND pg.NUMERO_OPERACION_PAGO =');
  ALineas.Add('       o.NUMERO_OPERACION_OPCAJA');
end;

procedure TRepositorioInformesCajaUniDAC.AnadirFiltrosOperacionesVenta(
  ALineas: TStrings;
  const AFiltroUbicaciones: string);
begin
  ALineas.Add(' WHERE o.TIPO_OPERACION_OPCAJA IN ' +
    '(''VE'', ''DV'', ''DE'')');
  // El anticipo inicial de un prestamo es un cobro, no otra venta.
  ALineas.Add('   AND NOT (o.TIPO_OPERACION_OPCAJA = ''DE'' AND EXISTS (');
  ALineas.Add('     SELECT 1 FROM fza_depositos_cliente dp');
  ALineas.Add('      WHERE dp.CODIGO_EMP_DEP = o.CODIGO_EMP_OPCAJA');
  ALineas.Add('        AND dp.CODIGO_ALM_DEP = o.CODIGO_ALM_OPCAJA');
  ALineas.Add('        AND dp.CODIGO_CAJA_DEP = o.CODIGO_CAJA_OPCAJA');
  ALineas.Add('        AND dp.NUMERO_OPERACION_DEP =');
  ALineas.Add('            o.NUMERO_OPERACION_OPCAJA))');
  // FZ-ISSUE-343: una factura puede tener varias filas de caja (VE + DE
  // al liquidar un apartado, VE + DV en un cambio de talla). Sus líneas
  // se cuentan una sola vez: con la VE, o con la DV o la DE si es la
  // única fila de esa factura.
  ALineas.Add('   AND NOT EXISTS (');
  ALineas.Add('     SELECT 1 FROM fza_caja_operaciones ou');
  ALineas.Add('      WHERE ou.CODIGO_EMP_OPCAJA = o.CODIGO_EMP_OPCAJA');
  ALineas.Add('        AND ou.SERIE_FAC_OPCAJA = o.SERIE_FAC_OPCAJA');
  ALineas.Add('        AND ou.NUMERO_FAC_OPCAJA = o.NUMERO_FAC_OPCAJA');
  ALineas.Add('        AND ou.TIPO_OPERACION_OPCAJA IN ' +
    '(''VE'', ''DV'', ''DE'')');
  ALineas.Add('        AND FIELD(ou.TIPO_OPERACION_OPCAJA, ' +
    '''VE'', ''DV'', ''DE'') <');
  ALineas.Add('            FIELD(o.TIPO_OPERACION_OPCAJA, ' +
    '''VE'', ''DV'', ''DE''))');
  ALineas.Add(AFiltroUbicaciones);
  ALineas.Add('   AND o.FECHA_OPERACION_OPCAJA >= :pDESDE');
  ALineas.Add('   AND o.FECHA_OPERACION_OPCAJA <');
  ALineas.Add('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
  ALineas.Add(SQLExcluirVentaRetirada(
    'o.CODIGO_EMP_OPCAJA',
    'o.SERIE_FAC_OPCAJA',
    'o.NUMERO_FAC_OPCAJA'));

end;

procedure TRepositorioInformesCajaUniDAC.AnadirPrestamosOperacionesVenta(
  ALineas: TStrings; const AFiltroUbicaciones: string);
var
  Filtro: string;
  I: Integer;
begin
  // FZ-ISSUE-865: el prestamo no tiene factura al entregar la mercancia.
  // Valor y fecha siguen el criterio de prestamos del arqueo.
  ALineas.Add('UNION ALL');
  ALineas.Add('SELECT DATE(fl.FECHA_CREACION_DEP) AS FECHA_DIA,');
  ALineas.Add(' DATE(:pDESDE), DATE(:pHASTA), fl.CODIGO_EMP_DEP,');
  ALineas.Add(' fl.CODIGO_ALM_DEP, fl.CODIGO_CAJA_DEP,');
  ALineas.Add(' CONCAT_WS(''/'', fl.CODIGO_EMP_DEP, fl.CODIGO_ALM_DEP,');
  ALineas.Add('   fl.CODIGO_CAJA_DEP), fl.NUMERO_OPERACION_DEP,');
  ALineas.Add(' fl.ID_DEPOSITO_DEP, fl.CODIGO_ART_FACLIN AS ARTICULO,');
  AnadirAtributosOperacionesVenta(ALineas);
  ALineas.Add(' COALESCE(fl.CANTIDAD_PENDIENTE_DEP, 1) AS CANTIDAD,');
  ALineas.Add(' ROUND(fl.PRECIO_VENTA_DEP *');
  ALineas.Add('   COALESCE(fl.CANTIDAD_PENDIENTE_DEP, 1), 2) AS BRUTO,');
  ALineas.Add(' 0 AS PORCENTAJE_DTO,');
  ALineas.Add(' ROUND(fl.PRECIO_VENTA_DEP *');
  ALineas.Add('   COALESCE(fl.CANTIDAD_PENDIENTE_DEP, 1), 2)');
  ALineas.Add('   AS NETO_ARTICULO,');
  ALineas.Add(' 0 AS INGRESOS, COALESCE(fl.USUARIO_ALTA, '''') AS VENDEDOR,');
  ALineas.Add(' ''CREDITO'' AS FORMA_PAGO,');
  ALineas.Add(' CONCAT(''PRESTAMO '', fl.ID_DEPOSITO_DEP) AS DOCUMENTO,');
  ALineas.Add(' COALESCE((SELECT a.TIPO_CANTIDAD_ART FROM fza_articulos a');
  ALineas.Add('   WHERE a.CODIGO_ART_ART = fl.CODIGO_ART_FACLIN), '''')');
  ALineas.Add('   AS UNIDAD_CANTIDAD');
  ALineas.Add(' FROM (SELECT d.ID_DEPOSITO_DEP, d.CODIGO_EMP_DEP,');
  ALineas.Add(' d.CODIGO_ALM_DEP, d.CODIGO_CAJA_DEP, d.NUMERO_OPERACION_DEP,');
  ALineas.Add(' d.FECHA_CREACION_DEP, d.PRECIO_VENTA_DEP,');
  ALineas.Add(' d.CANTIDAD_PENDIENTE_DEP, d.USUARIO_ALTA,');
  ALineas.Add(' d.CODIGO_ART_DEP AS CODIGO_ART_FACLIN,');
  ALineas.Add(' d.CODIGO_UNIDAD_DEP AS CODIGO_UNIDAD_FACLIN,');
  ALineas.Add(' '''' AS CODIGO_PRV_FACLIN,');
  ALineas.Add(' COALESCE(a.DESCRIPCION_ART, d.CODIGO_ART_DEP) AS');
  ALineas.Add('   DESCRIPCION_ARTICULO_FACLIN,');
  for I := 1 to 5 do
    ALineas.Add(Format('%s AS ATTR%d_NOMBRE_FACLIN, ' +
      '%s AS ATTR%d_VALOR_FACLIN,', [QuotedStr(''), I, QuotedStr(''), I]));
  ALineas.Add(' 1 AS ES_PRESTAMO');
  ALineas.Add(' FROM fza_depositos_cliente d');
  ALineas.Add(' LEFT JOIN fza_articulos a');
  ALineas.Add('   ON a.CODIGO_ART_ART = d.CODIGO_ART_DEP');
  ALineas.Add(') fl');
  AnadirProveedorOperacionesVenta(ALineas);
  AnadirColoresOperacionesVenta(ALineas);
  ALineas.Add(' WHERE fl.FECHA_CREACION_DEP >= :pDESDE');
  ALineas.Add(' AND fl.FECHA_CREACION_DEP < DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
  Filtro := StringReplace(AFiltroUbicaciones, 'o.CODIGO_EMP_OPCAJA',
    'fl.CODIGO_EMP_DEP', [rfReplaceAll]);
  Filtro := StringReplace(Filtro, 'o.CODIGO_ALM_OPCAJA',
    'fl.CODIGO_ALM_DEP', [rfReplaceAll]);
  Filtro := StringReplace(Filtro, 'o.CODIGO_CAJA_OPCAJA',
    'fl.CODIGO_CAJA_DEP', [rfReplaceAll]);
  ALineas.Add(Filtro);
end;

function TRepositorioInformesCajaUniDAC.ConstruirSqlOperacionesVenta(
  const AFiltroUbicaciones: string): string;
var
  slSQL: TStringList;
begin
  slSQL := TStringList.Create;
  try
    AnadirCabeceraOperacionesVenta(slSQL);
    AnadirAtributosOperacionesVenta(slSQL);
    AnadirImportesOperacionesVenta(slSQL);
    AnadirOrigenOperacionesVenta(slSQL);
    AnadirColoresOperacionesVenta(slSQL);
    AnadirPagosOperacionesVenta(slSQL);
    AnadirFiltrosOperacionesVenta(slSQL, AFiltroUbicaciones);
    AnadirPrestamosOperacionesVenta(slSQL, AFiltroUbicaciones);
    slSQL.Add(' ORDER BY FECHA_DIA, CODIGO_EMP_OPCAJA,');
    slSQL.Add('   CODIGO_ALM_OPCAJA, CODIGO_CAJA_OPCAJA,');
    slSQL.Add('   NUMERO_OPERACION_OPCAJA, LINEA_FACLIN');
    Result := slSQL.Text;
  finally
    FreeAndNil(slSQL);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarOperacionesVenta(
  const ASolicitud: TSolicitudOperacionesVentaCaja
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
  iUbicacion: Integer;
  sSufijo: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ConstruirSqlOperacionesVenta(
      ConstruirFiltroUbicaciones(ASolicitud.Ubicaciones));
    oConsulta.ParamByName('pDESDE').AsDateTime :=
      Trunc(ASolicitud.FechaDesde);
    oConsulta.ParamByName('pHASTA').AsDateTime :=
      Trunc(ASolicitud.FechaHasta);
    for iUbicacion := 0 to High(ASolicitud.Ubicaciones) do
    begin
      sSufijo := IntToStr(iUbicacion);
      oConsulta.ParamByName('pEMPRESA' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Empresa;
      oConsulta.ParamByName('pALMACEN' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Almacen;
      oConsulta.ParamByName('pCAJA' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Caja;
    end;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConstruirFiltroUbicacionesSolicitudes(
  const AUbicaciones: TUbicacionesInformeCaja): string;
var
  iUbicacion: Integer;
  sSufijo: string;
begin
  if Length(AUbicaciones) = 0 then
    Result := '   AND 1 = 0'
  else
  begin
    Result := '   AND (';
    for iUbicacion := 0 to High(AUbicaciones) do
    begin
      if iUbicacion > 0 then
        Result := Result + sLineBreak + '        OR ';
      sSufijo := IntToStr(iUbicacion);
      Result := Result +
        '(s.CODIGO_EMP_TRSOL = :pEMPRESA' + sSufijo +
        ' AND s.CODIGO_ALM_DESTINO_TRSOL = :pALMACEN' + sSufijo +
        ' AND s.CODIGO_CAJA_TRSOL = :pCAJA' + sSufijo + ')';
    end;
    Result := Result + ')';
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConstruirFiltroEstadosSolicitudes(
  const AEstados: TEstadosSolicitudTraspasoCaja): string;
var
  iEstado: Integer;
begin
  Result := '';
  if Length(AEstados) > 0 then
  begin
    Result := '   AND s.ESTADO_TRSOL IN (';
    for iEstado := 0 to High(AEstados) do
    begin
      if iEstado > 0 then
        Result := Result + ', ';
      Result := Result + ':pESTADO' + IntToStr(iEstado);
    end;
    Result := Result + ')';
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConstruirSqlSolicitudesTraspaso(
  const AFiltroUbicaciones, AFiltroEstados: string): string;
var
  slSQL: TStringList;
begin
  slSQL := TStringList.Create;
  try
    slSQL.Add('SELECT DATE(:pDESDE) AS FECHA_DESDE,');
    slSQL.Add('       DATE(:pHASTA) AS FECHA_HASTA,');
    slSQL.Add('       CONCAT_WS(''|'', s.SERIE_TRSOL,');
    slSQL.Add('         s.NUMERO_TRSOL) AS CLAVE_SOLICITUD,');
    slSQL.Add('       s.NUMERO_TRSOL,');
    slSQL.Add('       s.SERIE_TRSOL,');
    slSQL.Add('       s.FECHA_TRSOL,');
    slSQL.Add('       s.INSTANTE_ALTA,');
    slSQL.Add('       s.TIPO_TRSOL,');
    slSQL.Add('       s.ESTADO_TRSOL,');
    slSQL.Add('       s.INSTANTE_VENTAS_DESDE_TRSOL,');
    slSQL.Add('       s.INSTANTE_VENTAS_HASTA_TRSOL,');
    slSQL.Add('       s.CODIGO_EMP_TRSOL,');
    slSQL.Add('       ep.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_TRSOL,');
    slSQL.Add('       s.CODIGO_ALM_DESTINO_TRSOL,');
    slSQL.Add('       ad.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_DESTINO_TRSOL,');
    slSQL.Add('       s.CODIGO_CAJA_TRSOL,');
    slSQL.Add('       c.DESCRIPCION_ALMCAJ AS NOMBRE_CAJA_TRSOL,');
    slSQL.Add('       s.CODIGO_EMP_CONTRA_TRSOL,');
    slSQL.Add('       ec.RAZON_SOCIAL_EMP AS NOMBRE_EMPRESA_CONTRA_TRSOL,');
    slSQL.Add('       s.CODIGO_ALM_ORIGEN_TRSOL,');
    slSQL.Add('       ao.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN_ORIGEN_TRSOL,');
    slSQL.Add('       s.CODIGO_EMPLEADO_TRSOL,');
    slSQL.Add('       COALESCE(NULLIF(TRIM(e.NOMBRE_EMPL), ''''),');
    slSQL.Add('         NULLIF(TRIM(e.DIMINUTIVO_TICKET_EMPL), ''''),');
    slSQL.Add('         s.CODIGO_EMPLEADO_TRSOL)');
    slSQL.Add('         AS NOMBRE_EMPLEADO_TRSOL,');
    slSQL.Add('       s.OBSERVACIONES_TRSOL,');
    slSQL.Add('       l.LINEA_TRSOLLIN,');
    slSQL.Add('       l.CODIGO_ART_TRSOLLIN AS CODIGO_ART,');
    slSQL.Add('       l.CODIGO_UNIDAD_TRSOLLIN AS SKU_UNIDAD,');
    slSQL.Add('       CASE WHEN l.LINEA_TRSOLLIN IS NULL');
    slSQL.Add('            THEN ''Sin líneas solicitadas''');
    slSQL.Add('            ELSE COALESCE(');
    slSQL.Add('              NULLIF(');
    slSQL.Add('                TRIM(l.DESCRIPCION_ARTICULO_TRSOLLIN), ''''),');
    slSQL.Add('              a.DESCRIPCION_ART, '''') END');
    slSQL.Add('         AS DESCRIPCION_ART,');
    slSQL.Add('       l.CANTIDAD_PEDIDA_TRSOLLIN,');
    slSQL.Add('       CASE WHEN s.TIPO_TRSOL = ''AUTO'' THEN 0');
    slSQL.Add('            ELSE l.CANTIDAD_SERVIDA_TRSOLLIN END');
    slSQL.Add('         AS CANTIDAD_SERVIDA_TRSOLLIN,');
    slSQL.Add('       CASE WHEN l.LINEA_TRSOLLIN IS NULL THEN NULL');
    slSQL.Add('            WHEN s.TIPO_TRSOL = ''AUTO'' THEN 0');
    slSQL.Add('            ELSE GREATEST(');
    slSQL.Add('              COALESCE(l.CANTIDAD_PEDIDA_TRSOLLIN, 0) -');
    slSQL.Add('              COALESCE(l.CANTIDAD_SERVIDA_TRSOLLIN, 0), 0)');
    slSQL.Add('            END AS CANTIDAD_PENDIENTE_TRSOLLIN,');
    slSQL.Add('       CASE WHEN l.LINEA_TRSOLLIN IS NULL THEN ''''');
    slSQL.Add('            WHEN s.TIPO_TRSOL = ''AUTO''');
    slSQL.Add('            THEN ''No aplica''');
    slSQL.Add('            WHEN l.ESATENDIDA_TRSOLLIN = ''S''');
    slSQL.Add('            THEN ''Sí'' ELSE ''No'' END');
    slSQL.Add('         AS ATENDIDA_TRSOLLIN,');
    slSQL.Add('       CASE WHEN s.TIPO_TRSOL = ''AUTO'' THEN NULL');
    slSQL.Add('            ELSE l.MOTIVO_RECHAZO_TRSOLLIN END');
    slSQL.Add('         AS MOTIVO_RECHAZO_TRSOLLIN,');
    slSQL.Add('       l.CODIGO_PRV_TRSOLLIN,');
    slSQL.Add('       l.RAZON_SOCIAL_PRV_TRSOLLIN');
    slSQL.Add('  FROM fza_traspasos_solicitudes s');
    slSQL.Add('  LEFT JOIN fza_traspasos_solicitudes_lineas l');
    slSQL.Add('    ON l.NUMERO_TRSOL_TRSOLLIN = s.NUMERO_TRSOL');
    slSQL.Add('   AND l.SERIE_TRSOL_TRSOLLIN = s.SERIE_TRSOL');
    slSQL.Add('  LEFT JOIN fza_articulos a');
    slSQL.Add('    ON a.CODIGO_ART_ART = l.CODIGO_ART_TRSOLLIN');
    slSQL.Add('  LEFT JOIN fza_empresas ep');
    slSQL.Add('    ON ep.CODIGO_EMP_EMP = s.CODIGO_EMP_TRSOL');
    slSQL.Add('  LEFT JOIN fza_empresas ec');
    slSQL.Add('    ON ec.CODIGO_EMP_EMP = s.CODIGO_EMP_CONTRA_TRSOL');
    slSQL.Add('  LEFT JOIN fza_almacenes ad');
    slSQL.Add('    ON ad.CODIGO_ALM_ALM = s.CODIGO_ALM_DESTINO_TRSOL');
    slSQL.Add('  LEFT JOIN fza_almacenes ao');
    slSQL.Add('    ON ao.CODIGO_ALM_ALM = s.CODIGO_ALM_ORIGEN_TRSOL');
    slSQL.Add('  LEFT JOIN fza_almacenes_cajas c');
    slSQL.Add('    ON c.CODIGO_ALM_ALMCAJ = s.CODIGO_ALM_DESTINO_TRSOL');
    slSQL.Add('   AND c.CODIGO_CAJA_ALMCAJ = s.CODIGO_CAJA_TRSOL');
    slSQL.Add('  LEFT JOIN fza_empleados e');
    slSQL.Add('    ON e.CODIGO_EMPL = s.CODIGO_EMPLEADO_TRSOL');
    slSQL.Add(' WHERE s.INSTANTE_ALTA >= :pDESDE');
    slSQL.Add('   AND s.INSTANTE_ALTA <');
    slSQL.Add('       DATE_ADD(:pHASTA, INTERVAL 1 DAY)');
    slSQL.Add(AFiltroUbicaciones);
    if AFiltroEstados <> '' then
      slSQL.Add(AFiltroEstados);
    slSQL.Add(' ORDER BY s.INSTANTE_ALTA, s.SERIE_TRSOL,');
    slSQL.Add('          CAST(s.NUMERO_TRSOL AS UNSIGNED),');
    slSQL.Add('          l.LINEA_TRSOLLIN');
    Result := slSQL.Text;
  finally
    FreeAndNil(slSQL);
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ListarEstadosSolicitudesTraspaso:
  TEstadosSolicitudTraspasoCaja;
var
  iEstado: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT ESTADO_TRSOL ' +
      '  FROM fza_traspasos_solicitudes ' +
      ' WHERE NULLIF(TRIM(ESTADO_TRSOL), '''') IS NOT NULL ' +
      ' ORDER BY ESTADO_TRSOL';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iEstado := 0;
    while not oConsulta.Eof do
    begin
      Result[iEstado] :=
        oConsulta.FieldByName('ESTADO_TRSOL').AsString;
      Inc(iEstado);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.
  ConsultarSolicitudesTraspaso(
  const ASolicitud: TSolicitudTraspasosInformeCaja
): IResultadoInformeCaja;
var
  iEstado: Integer;
  iUbicacion: Integer;
  oConsulta: TUniQuery;
  sSufijo: string;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ConstruirSqlSolicitudesTraspaso(
      ConstruirFiltroUbicacionesSolicitudes(
        ASolicitud.Ubicaciones),
      ConstruirFiltroEstadosSolicitudes(ASolicitud.Estados));
    oConsulta.ParamByName('pDESDE').AsDateTime :=
      Trunc(ASolicitud.FechaDesde);
    oConsulta.ParamByName('pHASTA').AsDateTime :=
      Trunc(ASolicitud.FechaHasta);
    for iUbicacion := 0 to High(ASolicitud.Ubicaciones) do
    begin
      sSufijo := IntToStr(iUbicacion);
      oConsulta.ParamByName('pEMPRESA' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Empresa;
      oConsulta.ParamByName('pALMACEN' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Almacen;
      oConsulta.ParamByName('pCAJA' + sSufijo).AsString :=
        ASolicitud.Ubicaciones[iUbicacion].Caja;
    end;
    for iEstado := 0 to High(ASolicitud.Estados) do
      oConsulta.ParamByName('pESTADO' + IntToStr(iEstado)).AsString :=
        ASolicitud.Estados[iEstado];
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarArqueosHistorico(
  const AEmpresa, AAlmacen, ACaja: string
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_caja_arqueos ' +
      ' WHERE CODIGO_EMP_ARQ = :EMPRESA ' +
      '   AND CODIGO_ALM_ARQ = :ALMACEN ' +
      '   AND CODIGO_CAJA_ARQ = :CAJA ' +
      ' ORDER BY FECHA_DESDE_ARQ DESC, CODIGO_ARQ DESC';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ACaja;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformesCajaUniDAC.ConsultarValesPendientes(
  const AFiltro, APin: string
): IResultadoInformeCaja;
var
  oConsulta: TUniQuery;
  sSql: string;
begin
  sSql :=
    'SELECT CODIGO_VL, PIN_SEGURIDAD_VL, ESTADO_VL, ' +
    '       IMPORTE_NOMINAL_VL, FECHA_EMISION_VL, ' +
    '       FECHA_CADUCIDAD_VL, OBSERVACIONES_VL, ' +
    '       CODIGO_EMP_EMI_VL, CODIGO_ALM_EMI_VL ' +
    '  FROM fza_caja_vales ' +
    ' WHERE ESTADO_VL = ''PENDIENTE''' +
    // La caducidad la fija la emisora; se respeta siempre (FZ-362)
    '   AND (FECHA_CADUCIDAD_VL IS NULL ' +
    '        OR FECHA_CADUCIDAD_VL >= CURDATE())';
  if AFiltro <> '' then
  begin
    sSql := sSql + ' AND CODIGO_VL LIKE :FILTRO';
  end;
  if APin <> '' then
  begin
    sSql := sSql + ' AND PIN_SEGURIDAD_VL = :PIN';
  end;
  sSql := sSql + ' ORDER BY FECHA_EMISION_VL DESC';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := sSql;
    if AFiltro <> '' then
    begin
      oConsulta.ParamByName('FILTRO').AsString := '%' + AFiltro + '%';
    end;
    if APin <> '' then
    begin
      oConsulta.ParamByName('PIN').AsString := APin;
    end;
    oConsulta.Open;
    Result := TResultadoInformeCajaUniDAC.Create(oConsulta);
    oConsulta := nil;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioInformesCajaUniDAC(
  AConexion: TUniConnection): IRepositorioInformesCaja;
begin
  Result := TRepositorioInformesCajaUniDAC.Create(AConexion);
end;

end.
