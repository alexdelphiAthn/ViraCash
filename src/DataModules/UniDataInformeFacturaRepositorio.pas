unit UniDataInformeFacturaRepositorio;

interface

uses
  Uni, inLibInformeFacturaPersistenciaIntf;

function CrearPreparadorInformeFacturaUniDAC(
  AConsultaFactura: TUniQuery;
  AConsultaLineas: TUniQuery): IPreparadorInformeFactura;

implementation

uses
  Data.DB;

type
  TPreparadorInformeFacturaUniDAC = class(
    TInterfacedObject,
    IPreparadorInformeFactura)
  private
    FConsultaFactura: TUniQuery;
    FConsultaLineas: TUniQuery;
    procedure PrepararActual(const ACriterios: TCriteriosInformeFactura);
    procedure PrepararRango(const ACriterios: TCriteriosInformeFactura);
  public
    constructor Create(
      AConsultaFactura: TUniQuery;
      AConsultaLineas: TUniQuery);
    procedure Preparar(const ACriterios: TCriteriosInformeFactura);
  end;

function SQLCamposOperacionCaja: string;
begin
  Result :=
    ', OC.ID_OPCAJA_FACOP AS ID_OPERACION_CAJA_FACTURA, ' +
    'CONCAT(''TA '', OC.NUMERO_OPERACION_OPCAJA, '' / ID '', ' +
    'OC.ID_OPCAJA_FACOP) AS DOCUMENTO_OPERACION_CAJA, ' +
    'OC.FECHA_OPERACION_OPCAJA AS FECHA_OPERACION_CAJA, ' +
    'CASE WHEN OC.ID_OPCAJA_FACOP IS NULL THEN ''N'' ELSE ''S'' END ' +
    'AS ESFACTURA_TA_CAJA ';
end;

// Descripcion del articulo y, debajo, el SKU (el formato de factura no
// tiene columna de codigo). Antes el SKU iba delante y partia la
// descripcion. F-LOTEC-016: con las etiquetas, el lote o la serie (y su
// caducidad) en otra linea.
function SQLDescripcionLinea: string;
begin
  Result :=
    'CONCAT_WS(CHAR(13,10), ' +
    'NULLIF(TRIM(L.DESCRIPCION_ARTICULO_FACLIN), ''''), ' +
    'NULLIF(TRIM(L.CODIGO_UNIDAD_FACLIN), ''''), ' +
    'CASE WHEN :ETIQUETA_LOTE <> '''' AND ' +
    'TRIM(IFNULL(L.LOTE_FACLIN, '''')) <> '''' THEN CONCAT(' +
    'IF(EXISTS(SELECT 1 FROM fza_articulos A ' +
    'WHERE A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    'AND A.TIPO_TRAZABILIDAD_ART = ''SERIE''), :ETIQUETA_SERIE, ' +
    ':ETIQUETA_LOTE_TEXTO), '' '', TRIM(L.LOTE_FACLIN), ' +
    'IF(L.FECHA_CADUCIDAD_FACLIN IS NULL, '''', CONCAT('' '', ' +
    ':ETIQUETA_CADUCIDAD, '' '', ' +
    'DATE_FORMAT(L.FECHA_CADUCIDAD_FACLIN, ''%d/%m/%Y'')))) END) ' +
    'AS DESCRIPCION_PRINT_FACLIN, ' +
    'CASE WHEN EXISTS(SELECT 1 FROM fza_articulos A ' +
    'WHERE A.CODIGO_ART_ART = L.CODIGO_ART_FACLIN ' +
    'AND A.TIPO_TRAZABILIDAD_ART = ''SERIE'') ' +
    'THEN ''S'' ELSE ''N'' END AS ESSERIE_LOTE ';
end;

procedure AsignarEtiquetasLote(AConsulta: TUniQuery;
  const ACriterios: TCriteriosInformeFactura);
begin
  AConsulta.Params.ParamByName('ETIQUETA_LOTE').AsString :=
    ACriterios.EtiquetaLote;
  AConsulta.Params.ParamByName('ETIQUETA_LOTE_TEXTO').AsString :=
    ACriterios.EtiquetaLote;
  AConsulta.Params.ParamByName('ETIQUETA_SERIE').AsString :=
    ACriterios.EtiquetaSerie;
  AConsulta.Params.ParamByName('ETIQUETA_CADUCIDAD').AsString :=
    ACriterios.EtiquetaCaducidad;
end;

// Formas de pago con importe neto en los cobros de caja de la
// operacion de la factura (las correcciones que se anulan no cuentan).
function SQLFormasPagoCobroCaja: string;
begin
  Result :=
    '(SELECT GROUP_CONCAT(FP.DESCRIPCION_FORMA_PAGO_CFP ' +
    'ORDER BY FP.ORDEN_VISUAL_FORMA_PAGO_CFP, FP.CODIGO_FP_CFP ' +
    'SEPARATOR '', '') FROM fza_caja_formas_pago FP ' +
    'WHERE (SELECT SUM(P.IMPORTE_ENTREGADO_PAGO - ' +
    'P.IMPORTE_CAMBIO_PAGO) FROM fza_caja_pagos P ' +
    'WHERE P.CODIGO_FP_CFP = FP.CODIGO_FP_CFP ' +
    'AND P.CODIGO_EMP_PAGO = V.CODIGO_EMP_FAC ' +
    'AND P.CODIGO_ALM_PAGO = V.CODIGO_ALM_FAC ' +
    'AND P.CODIGO_CAJA_PAGO = V.CODIGO_CAJA_FAC ' +
    'AND P.NUMERO_OPERACION_PAGO = V.NUMERO_OPERACION_FAC ' +
    'AND P.SERIE_OPERACION_PAGO IN (V.SERIE_FAC, '''')) <> 0)';
end;

// FORMA_PAGO_IMPRESION: la forma de pago del documento o, si no tiene
// (factura simplificada de caja), las formas con que se cobro.
function SQLCabeceraFactura: string;
begin
  Result :=
    'SELECT V.*, COALESCE(' +
    'NULLIF(TRIM(V.DESCRIPCION_FORMA_PAGO_FP), ''''), ' +
    SQLFormasPagoCobroCaja + ', '''') AS FORMA_PAGO_IMPRESION ' +
    'FROM vi_facturas_print V ';
end;

function SQLJoinOperacionCaja: string;
begin
  Result :=
    'LEFT JOIN (SELECT FO.ID_OPCAJA_FACOP, FO.SERIE_FAC_FACOP, ' +
    'FO.NUMERO_FAC_FACOP, O.NUMERO_OPERACION_OPCAJA, ' +
    'O.CODIGO_EMP_OPCAJA, O.CODIGO_ALM_OPCAJA, ' +
    'O.CODIGO_CAJA_OPCAJA, COALESCE(O.FECHA_OP_DIA_OPCAJA, ' +
    'DATE(O.FECHA_OPERACION_OPCAJA)) AS FECHA_OPERACION_OPCAJA ' +
    'FROM fza_facturas_operaciones_caja FO ' +
    'INNER JOIN fza_caja_operaciones O ' +
    'ON O.ID_OPCAJA = FO.ID_OPCAJA_FACOP ' +
    'WHERE O.TIPO_OPERACION_OPCAJA = ''TA'') OC ' +
    'ON OC.SERIE_FAC_FACOP = L.SERIE_FAC_FACLIN ' +
    'AND OC.NUMERO_FAC_FACOP = L.NUMERO_FAC_FACLIN ' +
    'AND OC.CODIGO_EMP_OPCAJA = L.CODIGO_EMP_FACLIN ' +
    'AND OC.CODIGO_ALM_OPCAJA = L.CODIGO_ALM_FACLIN ' +
    'AND OC.CODIGO_CAJA_OPCAJA = L.CODIGO_CAJA_FACLIN ' +
    'AND OC.NUMERO_OPERACION_OPCAJA = ' +
    'L.NUMERO_OPERACION_FACLIN ';
end;

constructor TPreparadorInformeFacturaUniDAC.Create(
  AConsultaFactura: TUniQuery;
  AConsultaLineas: TUniQuery);
begin
  inherited Create;
  FConsultaFactura := AConsultaFactura;
  FConsultaLineas := AConsultaLineas;
end;

procedure TPreparadorInformeFacturaUniDAC.PrepararActual(
  const ACriterios: TCriteriosInformeFactura);
begin
  FConsultaFactura.Close;
  FConsultaFactura.Params.Clear;
  FConsultaFactura.SQL.Text :=
    SQLCabeceraFactura +
    'WHERE NUMERO_FAC = :numfac AND SERIE_FAC = :serie';
  FConsultaFactura.Params.ParamByName('numfac').Value := ACriterios.Numero;
  FConsultaFactura.Params.ParamByName('serie').Value := ACriterios.Serie;
  FConsultaFactura.Open;
  FConsultaLineas.Close;
  FConsultaLineas.Params.Clear;
  FConsultaLineas.SQL.Text :=
    'SELECT L.*, ' + SQLDescripcionLinea +
    SQLCamposOperacionCaja +
    'FROM fza_facturas_lineas L ' +
    SQLJoinOperacionCaja +
    'WHERE L.NUMERO_FAC_FACLIN = :numfac ' +
    'AND L.SERIE_FAC_FACLIN = :serie ' +
    'ORDER BY OC.FECHA_OPERACION_OPCAJA, OC.ID_OPCAJA_FACOP, ' +
    'L.LINEA_FACLIN';
  FConsultaLineas.Params.ParamByName('numfac').Value := ACriterios.Numero;
  FConsultaLineas.Params.ParamByName('serie').Value := ACriterios.Serie;
  AsignarEtiquetasLote(FConsultaLineas, ACriterios);
  FConsultaLineas.Open;
end;

procedure TPreparadorInformeFacturaUniDAC.PrepararRango(
  const ACriterios: TCriteriosInformeFactura);
begin
  FConsultaFactura.Close;
  FConsultaFactura.Params.Clear;
  FConsultaFactura.SQL.Text :=
    SQLCabeceraFactura +
    'WHERE FECHA_FAC >= :fecha_ini AND FECHA_FAC <= :fecha_fin ' +
    'ORDER BY NUMERO_FAC';
  FConsultaFactura.Params.ParamByName('fecha_ini').Value :=
    ACriterios.FechaDesde;
  FConsultaFactura.Params.ParamByName('fecha_fin').Value :=
    ACriterios.FechaHasta;
  FConsultaFactura.Open;
  FConsultaLineas.Close;
  FConsultaLineas.Params.Clear;
  FConsultaLineas.SQL.Text :=
    'SELECT L.*, ' + SQLDescripcionLinea +
    SQLCamposOperacionCaja +
    'FROM fza_facturas_lineas L ' +
    SQLJoinOperacionCaja +
    'INNER JOIN vi_facturas_print F ' +
    'ON F.NUMERO_FAC = L.NUMERO_FAC_FACLIN ' +
    'AND F.SERIE_FAC = L.SERIE_FAC_FACLIN ' +
    'WHERE F.FECHA_FAC >= :fecha_ini ' +
    'AND F.FECHA_FAC <= :fecha_fin ' +
    'ORDER BY L.NUMERO_FAC_FACLIN, L.SERIE_FAC_FACLIN, ' +
    'OC.FECHA_OPERACION_OPCAJA, OC.ID_OPCAJA_FACOP, ' +
    'L.LINEA_FACLIN';
  FConsultaLineas.Params.ParamByName('fecha_ini').DataType := ftDate;
  FConsultaLineas.Params.ParamByName('fecha_ini').Value :=
    ACriterios.FechaDesde;
  FConsultaLineas.Params.ParamByName('fecha_fin').DataType := ftDate;
  FConsultaLineas.Params.ParamByName('fecha_fin').Value :=
    ACriterios.FechaHasta;
  AsignarEtiquetasLote(FConsultaLineas, ACriterios);
  FConsultaLineas.Open;
end;

procedure TPreparadorInformeFacturaUniDAC.Preparar(
  const ACriterios: TCriteriosInformeFactura);
begin
  if ACriterios.FacturaActual then
    PrepararActual(ACriterios)
  else
    PrepararRango(ACriterios);
end;

function CrearPreparadorInformeFacturaUniDAC(
  AConsultaFactura: TUniQuery;
  AConsultaLineas: TUniQuery): IPreparadorInformeFactura;
begin
  Result := TPreparadorInformeFacturaUniDAC.Create(
    AConsultaFactura,
    AConsultaLineas);
end;

end.
