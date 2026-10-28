unit UniDataInformeRecibosFacturaRepositorio;

interface

uses
  Uni, inLibInformeRecibosFacturaPersistenciaIntf;

function CrearPreparadorInformeRecibosFacturaUniDAC(
  AConsultaRecibos: TUniQuery): IPreparadorInformeRecibosFactura;

implementation

uses
  UniDataFormatoDocumentoRepositorio, inLibComprasDirectas;

type
  TPreparadorInformeRecibosFacturaUniDAC = class(
    TInterfacedObject,
    IPreparadorInformeRecibosFactura)
  private
    FConsultaRecibos: TUniQuery;
    procedure PrepararRecibos(
      const ACriterios: TCriteriosInformeRecibosFactura);
    procedure PrepararEfectosCompra(
      const ACriterios: TCriteriosInformeRecibosFactura);
    procedure PrepararEfectosVenta(
      const ACriterios: TCriteriosInformeRecibosFactura);
  public
    constructor Create(AConsultaRecibos: TUniQuery);
    procedure Preparar(
      const ACriterios: TCriteriosInformeRecibosFactura);
  end;

constructor TPreparadorInformeRecibosFacturaUniDAC.Create(
  AConsultaRecibos: TUniQuery);
begin
  inherited Create;
  FConsultaRecibos := AConsultaRecibos;
end;

procedure TPreparadorInformeRecibosFacturaUniDAC.PrepararRecibos(
  const ACriterios: TCriteriosInformeRecibosFactura);
begin
  FConsultaRecibos.SQL.Text :=
    'SELECT r.*, ' +
    ExpresionSqlFormatoDocumento(
      'emp.FORMATO_DOCUMENTO_EMP',
      'r.SERIE_FAC_REC',
      'r.NUMERO_FAC_REC') +
    ' AS DOCUMENTO_FACTURA_FORMATO ' +
    'FROM vi_recibos r ' +
    'LEFT JOIN fza_facturas fac ' +
    'ON fac.SERIE_FAC = r.SERIE_FAC_REC ' +
    'AND fac.NUMERO_FAC = r.NUMERO_FAC_REC ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC ' +
    'WHERE NUMERO_FAC_REC = :numfac ' +
    'AND SERIE_FAC_REC = :serie ';
  if ACriterios.ReciboActual then
    FConsultaRecibos.SQL.Add('AND NUMERO_PLAZO_REC = :recibo');
  FConsultaRecibos.Params.ParamByName('numfac').AsString :=
    ACriterios.NumeroFactura;
  FConsultaRecibos.Params.ParamByName('serie').AsString := ACriterios.Serie;
  if ACriterios.ReciboActual then
    FConsultaRecibos.Params.ParamByName('recibo').AsString :=
      ACriterios.NumeroRecibo;
end;

// FZ-ISSUE-102.14: el SP deja los efectos con las columnas de vi_recibos
// en una temporal de la sesion; se lee en la misma conexion.
procedure TPreparadorInformeRecibosFacturaUniDAC.PrepararEfectosVenta(
  const ACriterios: TCriteriosInformeRecibosFactura);
var
  sEfectos: string;
begin
  sEfectos := '';
  if ACriterios.ReciboActual then
    sEfectos := ACriterios.Efectos;
  FConsultaRecibos.Connection.ExecSQL(
    'CALL PRC_PREPARAR_RECIBOS_EFECTOS_VENTA(:serie, :numfac, :efectos)',
    [ACriterios.Serie, ACriterios.NumeroFactura, sEfectos]);
  FConsultaRecibos.SQL.Text :=
    'SELECT r.*, ' +
    ExpresionSqlFormatoDocumento(
      'emp.FORMATO_DOCUMENTO_EMP',
      'r.SERIE_FAC_REC',
      'r.NUMERO_FAC_REC') +
    ' AS DOCUMENTO_FACTURA_FORMATO ' +
    'FROM tmp_recibos_efectos_venta r ' +
    'LEFT JOIN fza_facturas fac ' +
    'ON fac.SERIE_FAC = r.SERIE_FAC_REC ' +
    'AND fac.NUMERO_FAC = r.NUMERO_FAC_REC ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = fac.CODIGO_EMP_FAC ' +
    'ORDER BY r.NUMERO_PLAZO_REC';
end;

procedure TPreparadorInformeRecibosFacturaUniDAC.PrepararEfectosCompra(
  const ACriterios: TCriteriosInformeRecibosFactura);
var
  sEfectos: string;
begin
  sEfectos := '';
  if ACriterios.ReciboActual then
    sEfectos := ACriterios.Efectos;
  FConsultaRecibos.Connection.ExecSQL(
    'CALL PRC_PREPARAR_RECIBOS_EFECTOS_COMPRA(:SERIE, :NUMERO, :EFECTOS)',
    [ACriterios.Serie, ACriterios.NumeroFactura, sEfectos]);
  FConsultaRecibos.SQL.Text :=
    'SELECT R.SERIE_FAC_REC, R.NUMERO_FAC_REC, R.NUMERO_PLAZO_REC, ' +
    'R.ESTADO_RECIBO_REC, R.EUROS_RECIBO_REC, ' +
    'R.FECHA_EXPEDICION_RECIBO_REC, R.FECHA_VENCIMIENTO_RECIBO_REC, ' +
    'R.IBAN_CLI_REC, ' +
    // FZ-ISSUE-749: lugar de expedición = población de la empresa que paga;
    // texto legal de la compra directa (autofactura o recibo REAGP).
    'COALESCE(NULLIF(TRIM(R.LOCALIDAD_EXPEDICION_RECIBO_REC), ''''), ' +
    'NULLIF(TRIM(F.POBLACION_EMPRESA_FACC), ''''), E.POBLACION_EMP) ' +
    'AS LOCALIDAD_EXPEDICION_RECIBO_REC, ' +
    'CASE F.MODALIDAD_FACC WHEN ''AUTOFAC'' THEN :LEGAL_AUTOFAC ' +
    'WHEN ''REAGP'' THEN :LEGAL_REAGP ELSE '''' END AS TEXTO_LEGAL_REC, ' +
    'R.CODIGO_CLI_REC, R.RAZON_SOCIAL_CLI_REC, ' +
    'R.DIRECCION1_CLIENTE_RECIBO_REC, R.POBLACION_CLI_REC, ' +
    'R.PROVINCIA_CLI_REC, R.CODIGO_POSTAL_CLI_REC, ' +
    'R.IMPORTE_LETRA_RECIBO_REC, ' +
    ExpresionSqlFormatoDocumento('E.FORMATO_DOCUMENTO_EMP',
      'R.SERIE_FAC_REC', 'R.NUMERO_FAC_REC') +
    ' AS DOCUMENTO_FACTURA_FORMATO ' +
    'FROM tmp_recibos_efectos_compra R ' +
    'JOIN fza_facturas_compra F ON F.SERIE_FACC = R.SERIE_FAC_REC ' +
    'AND F.NUMERO_FACC = R.NUMERO_FAC_REC ' +
    'JOIN fza_empresas E ON E.CODIGO_EMP_EMP = F.CODIGO_EMP_FACC ' +
    'ORDER BY R.NUMERO_PLAZO_REC';
  FConsultaRecibos.ParamByName('LEGAL_AUTOFAC').AsString :=
    ClasificarCompraDirecta(mcdAutofactura).TextoLegal;
  FConsultaRecibos.ParamByName('LEGAL_REAGP').AsString :=
    ClasificarCompraDirecta(mcdReagp).TextoLegal;
end;

procedure TPreparadorInformeRecibosFacturaUniDAC.Preparar(
  const ACriterios: TCriteriosInformeRecibosFactura);
begin
  FConsultaRecibos.Close;
  FConsultaRecibos.Params.Clear;
  if ACriterios.EsEfectosCompra then
    PrepararEfectosCompra(ACriterios)
  else if ACriterios.EsEfectosVenta then
    PrepararEfectosVenta(ACriterios)
  else
    PrepararRecibos(ACriterios);
  FConsultaRecibos.Open;
end;

function CrearPreparadorInformeRecibosFacturaUniDAC(
  AConsultaRecibos: TUniQuery): IPreparadorInformeRecibosFactura;
begin
  Result := TPreparadorInformeRecibosFacturaUniDAC.Create(AConsultaRecibos);
end;

end.
