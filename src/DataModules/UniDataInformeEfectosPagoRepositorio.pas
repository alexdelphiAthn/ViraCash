unit UniDataInformeEfectosPagoRepositorio;

interface

uses
  Uni, inLibInformeEfectosPagoPersistenciaIntf;

function CrearRepositorioInformeEfectosPagoUniDAC(
  AConexion: TUniConnection): IRepositorioInformeEfectosPago;

implementation

uses
  System.SysUtils, System.Classes, Data.DB;

type
  TResultadoInformeEfectosPagoUniDAC = class(
    TInterfacedObject,
    IResultadoInformeEfectosPago)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioInformeEfectosPagoUniDAC = class(
    TInterfacedObject,
    IRepositorioInformeEfectosPago)
  private
    FConexion: TUniConnection;
    function ExisteTabla(const ANombreTabla: string): Boolean;
    function LeerOpciones(
      AConsulta: TUniQuery): TOpcionesInformeEfectosPago;
    function CampoFechaSql(ATipoFecha: Integer): string;
    function NivelN(
      const ANiveles: TArray<string>;
      AIndice: Integer): string;
    function GrupoCodigoSql(const ACodigo: string): string;
    function GrupoEtiquetaSql(const ACodigo: string): string;
    function ConstruirSql(
      const ACriterios: TCriteriosInformeEfectosPago): string;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarTipos: TOpcionesInformeEfectosPago;
    function ListarSituaciones: TOpcionesInformeEfectosPago;
    function ListarBancos: TOpcionesInformeEfectosPago;
    function Preparar(
      const ACriterios: TCriteriosInformeEfectosPago
    ): IResultadoInformeEfectosPago;
  end;

constructor TResultadoInformeEfectosPagoUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoInformeEfectosPagoUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited Destroy;
end;

function TResultadoInformeEfectosPagoUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioInformeEfectosPagoUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioInformeEfectosPagoUniDAC.ExisteTabla(
  const ANombreTabla: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS C FROM INFORMATION_SCHEMA.TABLES ' +
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :TABLA';
    oConsulta.ParamByName('TABLA').AsString := ANombreTabla;
    oConsulta.Open;
    Result := oConsulta.FieldByName('C').AsInteger > 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeEfectosPagoUniDAC.LeerOpciones(
  AConsulta: TUniQuery): TOpcionesInformeEfectosPago;
var
  iOpcion: Integer;
begin
  SetLength(Result, 0);
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    iOpcion := Length(Result);
    SetLength(Result, iOpcion + 1);
    Result[iOpcion].Codigo := AConsulta.FieldByName('COD').AsString;
    Result[iOpcion].Nombre := AConsulta.FieldByName('NOM').AsString;
    AConsulta.Next;
  end;
end;

function TRepositorioInformeEfectosPagoUniDAC.ListarTipos:
  TOpcionesInformeEfectosPago;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT e.CODIGO_TEFE_EFEC AS COD, ' +
      'COALESCE(NULLIF(t.DESCRIPCION_TEFE, ''''), ' +
      'e.CODIGO_TEFE_EFEC) AS NOM ' +
      'FROM fza_efectos_compra e ' +
      'LEFT JOIN fza_tipos_efecto t ' +
      'ON t.CODIGO_TEFE = e.CODIGO_TEFE_EFEC ' +
      'WHERE COALESCE(e.CODIGO_TEFE_EFEC, '''') <> '''' ' +
      'ORDER BY NOM, COD';
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeEfectosPagoUniDAC.ListarSituaciones:
  TOpcionesInformeEfectosPago;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT DISTINCT COALESCE(NULLIF(ESTADO_EFEC, ''''), ' +
      '''PENDIENTE'') AS COD, ' +
      'COALESCE(NULLIF(ESTADO_EFEC, ''''), ''PENDIENTE'') AS NOM ' +
      'FROM fza_efectos_compra ORDER BY COD';
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeEfectosPagoUniDAC.ListarBancos:
  TOpcionesInformeEfectosPago;
var
  bBancos: Boolean;
  bEmpresasBancos: Boolean;
  oConsulta: TUniQuery;
  sSql: string;
begin
  bEmpresasBancos := ExisteTabla('fza_empresas_bancos');
  bBancos := ExisteTabla('fza_bancos');
  sSql :=
    'SELECT DISTINCT COALESCE(NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
    '''-'') AS COD, ';
  if bEmpresasBancos and bBancos then
    sSql := sSql +
      'COALESCE(NULLIF(b.NOMBRE_BAN, ''''), ' +
      'NULLIF(eb.NOMBRE_EMPBAN, ''''), ' +
      'NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
      '''Sin banco remesa'') AS NOM FROM fza_efectos_compra e ' +
      'LEFT JOIN fza_empresas_bancos eb ' +
      'ON eb.CODIGO_EMPBAN = e.CODIGO_EMPBAN_EFEC ' +
      'LEFT JOIN fza_bancos b ON b.CODIGO_BAN = eb.CODIGO_BAN_EMPBAN '
  else if bEmpresasBancos then
    sSql := sSql +
      'COALESCE(NULLIF(eb.NOMBRE_EMPBAN, ''''), ' +
      'NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
      '''Sin banco remesa'') AS NOM FROM fza_efectos_compra e ' +
      'LEFT JOIN fza_empresas_bancos eb ' +
      'ON eb.CODIGO_EMPBAN = e.CODIGO_EMPBAN_EFEC '
  else
    sSql := sSql +
      'COALESCE(NULLIF(e.CODIGO_EMPBAN_EFEC, ''''), ' +
      '''Sin banco remesa'') AS NOM FROM fza_efectos_compra e ';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := sSql + 'ORDER BY NOM, COD';
    Result := LeerOpciones(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioInformeEfectosPagoUniDAC.CampoFechaSql(
  ATipoFecha: Integer): string;
begin
  if ATipoFecha = 0 then
    Result := 'COALESCE(E.FECHA_FACTURA_VIEW_EFEC, F.FECHA_FACC, ' +
      'E.FECHA_EMISION_EFEC, E.FECHA_VENCIMIENTO_EFEC)'
  else if ATipoFecha = 1 then
    Result := 'COALESCE(F.FECHA_VALOR_FACC, E.FECHA_EMISION_EFEC, ' +
      'E.FECHA_FACTURA_VIEW_EFEC, E.FECHA_VENCIMIENTO_EFEC)'
  else
    Result := 'COALESCE(E.FECHA_VENCIMIENTO_EFEC, ' +
      'E.FECHA_FACTURA_VIEW_EFEC, E.FECHA_EMISION_EFEC)';
end;

function TRepositorioInformeEfectosPagoUniDAC.NivelN(
  const ANiveles: TArray<string>;
  AIndice: Integer): string;
begin
  if (AIndice >= 0) and (AIndice < Length(ANiveles)) then
    Result := ANiveles[AIndice]
  else
    Result := '';
end;

function TRepositorioInformeEfectosPagoUniDAC.GrupoCodigoSql(
  const ACodigo: string): string;
begin
  if SameText(ACodigo, 'ALM') then
    Result := 'COALESCE(NULLIF(D.CODIGO_ALM_EFEC, ''''), ''-'')'
  else if SameText(ACodigo, 'FECHA') then
    Result := 'DATE_FORMAT(D.FECHA_FILTRO_EFEC, ''%Y-%m-%d'')'
  else if SameText(ACodigo, 'PRV') then
    Result := 'COALESCE(NULLIF(D.CODIGO_PRV_EFEC, ''''), ''-'')'
  else if SameText(ACodigo, 'BANCO') then
    Result := 'D.CODIGO_BANCO_REMESA'
  else if SameText(ACodigo, 'ESTADO') then
    Result := 'D.SITUACION_EFEC'
  else if SameText(ACodigo, 'TEFE') then
    Result := 'COALESCE(NULLIF(D.CODIGO_TEFE_EFEC, ''''), ''-'')'
  else
    Result := '''''';
end;

function TRepositorioInformeEfectosPagoUniDAC.GrupoEtiquetaSql(
  const ACodigo: string): string;
begin
  if SameText(ACodigo, 'ALM') then
    Result := 'CONCAT(''ALMACEN '', ' + GrupoCodigoSql('ALM') + ')'
  else if SameText(ACodigo, 'FECHA') then
    Result := 'CONCAT(''FECHA '', DATE_FORMAT(D.FECHA_FILTRO_EFEC, ' +
      '''%d/%m/%Y''))'
  else if SameText(ACodigo, 'PRV') then
    Result := 'CONCAT(''PVDOR. '', D.CODIGO_PRV_EFEC, '' '', ' +
      'D.PROVEEDOR_EFEC)'
  else if SameText(ACodigo, 'BANCO') then
    Result := 'CONCAT(''BANCO REM. '', D.BANCO_REMESA_EFEC)'
  else if SameText(ACodigo, 'ESTADO') then
    Result := 'CONCAT(''SITUACION '', D.SITUACION_EFEC)'
  else if SameText(ACodigo, 'TEFE') then
    Result := 'CONCAT(''TIPO EFECTO '', D.TIPO_EFECTO_EFEC)'
  else
    Result := '''''';
end;

function TRepositorioInformeEfectosPagoUniDAC.ConstruirSql(
  const ACriterios: TCriteriosInformeEfectosPago): string;
var
  bBancos: Boolean;
  bEmpresasBancos: Boolean;
  sl: TStringList;
  procedure Anadir(const ALinea: string);
  begin
    sl.Add(ALinea);
  end;
begin
  bEmpresasBancos := ExisteTabla('fza_empresas_bancos');
  bBancos := ExisteTabla('fza_bancos');
  sl := TStringList.Create;
  try
    Anadir('SELECT D.*,');
    Anadir('       ' + GrupoCodigoSql(NivelN(ACriterios.Niveles, 0)) +
      ' AS GRUPO1_COD,');
    Anadir('       ' + GrupoEtiquetaSql(NivelN(ACriterios.Niveles, 0)) +
      ' AS GRUPO1_ETIQ,');
    Anadir('       ' + GrupoCodigoSql(NivelN(ACriterios.Niveles, 1)) +
      ' AS GRUPO2_COD,');
    Anadir('       ' + GrupoEtiquetaSql(NivelN(ACriterios.Niveles, 1)) +
      ' AS GRUPO2_ETIQ,');
    Anadir('       ' + GrupoCodigoSql(NivelN(ACriterios.Niveles, 2)) +
      ' AS GRUPO3_COD,');
    Anadir('       ' + GrupoEtiquetaSql(NivelN(ACriterios.Niveles, 2)) +
      ' AS GRUPO3_ETIQ');
    Anadir('FROM (');
    Anadir('SELECT CONCAT(E.SERIE_FACC_EFEC, ''.'', E.NUMERO_FACC_EFEC,');
    Anadir('       ''/'', LPAD(E.NUMERO_EFEC, 3, ''0'')) ' +
      'AS IDENTIFICADOR_EFECTO,');
    Anadir('COALESCE(NULLIF(E.DESCRIPCION_TEFE_VIEW_EFEC, ''''), ' +
      '''No definido'') AS TIPO_EFECTO_EFEC,');
    Anadir('COALESCE(NULLIF(F.CODIGO_ALM_FACC, ''''), '''') ' +
      'AS CODIGO_ALM_EFEC,');
    Anadir('COALESCE(NULLIF(E.CODIGO_PRV_EFEC, ''''), '''') ' +
      'AS CODIGO_PRV_EFEC,');
    Anadir('COALESCE(NULLIF(E.NOMBRE_PRV_VIEW_EFEC, ''''), ' +
      'NULLIF(E.RAZON_SOCIAL_PRV_EFEC, ''''), E.CODIGO_PRV_EFEC) ' +
      'AS PROVEEDOR_EFEC,');
    Anadir('COALESCE(NULLIF(E.ESTADO_EFEC, ''''), ''PENDIENTE'') ' +
      'AS SITUACION_EFEC,');
    Anadir('E.FECHA_VENCIMIENTO_EFEC,');
    Anadir('COALESCE(E.FECHA_FACTURA_VIEW_EFEC, F.FECHA_FACC) ' +
      'AS FECHA_DOCUMENTO_EFEC,');
    Anadir('COALESCE(F.FECHA_VALOR_FACC, E.FECHA_EMISION_EFEC) ' +
      'AS FECHA_VALOR_EFEC,');
    Anadir(CampoFechaSql(ACriterios.TipoFecha) + ' AS FECHA_FILTRO_EFEC,');
    Anadir('DATEDIFF(E.FECHA_VENCIMIENTO_EFEC, ' +
      'COALESCE(E.FECHA_FACTURA_VIEW_EFEC, F.FECHA_FACC, ' +
      'E.FECHA_EMISION_EFEC)) AS DIAS_EFEC,');
    Anadir('COALESCE(E.IMPORTE_EFEC, 0) AS IMPORTE_EFEC,');
    Anadir('COALESCE(E.IMPORTE_PAGADO_EFEC, 0) AS IMPORTE_PAGADO_EFEC,');
    Anadir('COALESCE(E.IMPORTE_PENDIENTE_EFEC, 0) ' +
      'AS IMPORTE_PENDIENTE_EFEC,');
    Anadir('E.SERIE_FACC_EFEC, E.NUMERO_FACC_EFEC, E.NUMERO_EFEC,');
    Anadir('E.CODIGO_TEFE_EFEC,');
    Anadir('COALESCE(NULLIF(E.SERIE_REMC_EFEC, ''''), '''') ' +
      'AS SERIE_REMC_EFEC,');
    Anadir('COALESCE(NULLIF(E.NUMERO_REMC_EFEC, ''''), '''') ' +
      'AS NUMERO_REMC_EFEC,');
    Anadir('CASE WHEN COALESCE(NULLIF(E.SERIE_REMC_EFEC, ''''), '''') = '''' ' +
      'THEN COALESCE(NULLIF(E.NUMERO_REMC_EFEC, ''''), '''') ' +
      'WHEN COALESCE(NULLIF(E.NUMERO_REMC_EFEC, ''''), '''') = '''' ' +
      'THEN E.SERIE_REMC_EFEC ELSE CONCAT(E.SERIE_REMC_EFEC, ''/'', ' +
      'E.NUMERO_REMC_EFEC) END AS REMESA_EFEC,');
    Anadir('COALESCE(NULLIF(E.CODIGO_EMPBAN_EFEC, ''''), ''-'') ' +
      'AS CODIGO_BANCO_REMESA,');
    if bEmpresasBancos and bBancos then
      Anadir('COALESCE(NULLIF(B.NOMBRE_BAN, ''''), ' +
        'NULLIF(EB.NOMBRE_EMPBAN, ''''), ' +
        'NULLIF(E.CODIGO_EMPBAN_EFEC, ''''), ''Sin banco remesa'') ' +
        'AS BANCO_REMESA_EFEC,')
    else if bEmpresasBancos then
      Anadir('COALESCE(NULLIF(EB.NOMBRE_EMPBAN, ''''), ' +
        'NULLIF(E.CODIGO_EMPBAN_EFEC, ''''), ''Sin banco remesa'') ' +
        'AS BANCO_REMESA_EFEC,')
    else
      Anadir('COALESCE(NULLIF(E.CODIGO_EMPBAN_EFEC, ''''), ' +
        '''Sin banco remesa'') AS BANCO_REMESA_EFEC,');
    Anadir('COALESCE(NULLIF(E.REFERENCIA_DOCUMENTO_EFEC, ''''), ' +
      'NULLIF(E.DOC_EXTERNO_EFEC, ''''), CONCAT(E.SERIE_FACC_EFEC, ''/'', ' +
      'E.NUMERO_FACC_EFEC)) AS REFERENCIA_EFEC');
    Anadir('FROM vi_efectos_compra E');
    Anadir('LEFT JOIN fza_facturas_compra F ' +
      'ON F.SERIE_FACC = E.SERIE_FACC_EFEC ' +
      'AND F.NUMERO_FACC = E.NUMERO_FACC_EFEC');
    if bEmpresasBancos then
      Anadir('LEFT JOIN fza_empresas_bancos EB ' +
        'ON EB.CODIGO_EMPBAN = E.CODIGO_EMPBAN_EFEC');
    if bEmpresasBancos and bBancos then
      Anadir('LEFT JOIN fza_bancos B ' +
        'ON B.CODIGO_BAN = EB.CODIGO_BAN_EMPBAN');
    Anadir(') D');
    Anadir('WHERE D.FECHA_FILTRO_EFEC >= :pDESDE');
    Anadir('AND D.FECHA_FILTRO_EFEC <= :pHASTA');
    Anadir('AND (:pALM = '''' OR FIND_IN_SET(D.CODIGO_ALM_EFEC, :pALM))');
    Anadir('AND (:pPRV = '''' OR FIND_IN_SET(D.CODIGO_PRV_EFEC, :pPRV))');
    Anadir('AND (:pTIP = '''' OR FIND_IN_SET(D.CODIGO_TEFE_EFEC, :pTIP))');
    Anadir('AND (:pEST = '''' OR FIND_IN_SET(D.SITUACION_EFEC, :pEST))');
    Anadir('AND (:pBAN = '''' OR FIND_IN_SET(D.CODIGO_BANCO_REMESA, :pBAN))');
    Anadir('AND (:pNUMDESDE = '''' OR ' +
      'D.IDENTIFICADOR_EFECTO >= :pNUMDESDE)');
    Anadir('AND (:pNUMHASTA = '''' OR ' +
      'D.IDENTIFICADOR_EFECTO <= :pNUMHASTA)');
    Anadir('AND (:pMODOEST = 3 OR (:pMODOEST = 0 AND ' +
      'D.IMPORTE_PENDIENTE_EFEC <= 0.0001) OR (:pMODOEST = 1 AND ' +
      'D.SITUACION_EFEC = ''DEVUELTO'') OR (:pMODOEST = 2 AND ' +
      'D.IMPORTE_PENDIENTE_EFEC > 0.0001 AND D.SITUACION_EFEC NOT IN ' +
      '(''PAGADO'', ''ANULADO'', ''CONCILIADO'')))');
    Anadir('ORDER BY GRUPO1_COD, GRUPO2_COD, GRUPO3_COD, ' +
      'D.FECHA_VENCIMIENTO_EFEC, D.IDENTIFICADOR_EFECTO');
    Result := sl.Text;
  finally
    FreeAndNil(sl);
  end;
end;

function TRepositorioInformeEfectosPagoUniDAC.Preparar(
  const ACriterios: TCriteriosInformeEfectosPago
): IResultadoInformeEfectosPago;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ConstruirSql(ACriterios);
    oConsulta.ParamByName('pDESDE').AsDateTime := ACriterios.FechaDesde;
    oConsulta.ParamByName('pHASTA').AsDateTime := ACriterios.FechaHasta;
    oConsulta.ParamByName('pALM').AsString := ACriterios.Almacenes;
    oConsulta.ParamByName('pPRV').AsString := ACriterios.Proveedores;
    oConsulta.ParamByName('pTIP').AsString := ACriterios.Tipos;
    oConsulta.ParamByName('pEST').AsString := ACriterios.Situaciones;
    oConsulta.ParamByName('pBAN').AsString := ACriterios.Bancos;
    oConsulta.ParamByName('pNUMDESDE').AsString := ACriterios.NumeroDesde;
    oConsulta.ParamByName('pNUMHASTA').AsString := ACriterios.NumeroHasta;
    oConsulta.ParamByName('pMODOEST').AsInteger := ACriterios.ModoSituacion;
    oConsulta.Open;
    Result := TResultadoInformeEfectosPagoUniDAC.Create(oConsulta);
  except
    FreeAndNil(oConsulta);
    raise;
  end;
end;

function CrearRepositorioInformeEfectosPagoUniDAC(
  AConexion: TUniConnection): IRepositorioInformeEfectosPago;
begin
  Result := TRepositorioInformeEfectosPagoUniDAC.Create(AConexion);
end;

end.
