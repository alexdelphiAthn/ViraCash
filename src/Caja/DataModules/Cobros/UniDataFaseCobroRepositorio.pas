{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataFaseCobroRepositorio                                   }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas UniDAC utilizadas durante la fase de cobro.                     }
{******************************************************************************}
unit UniDataFaseCobroRepositorio;

interface

uses
  Uni, inLibFaseCobroPersistenciaIntf;

function CrearRepositorioFaseCobroUniDAC(
  AConexion: TUniConnection
): IRepositorioFaseCobro;

function FiltroAmbitoCanjeVale(
  const ARestriccion: TRestriccionCanjeVale): string;
procedure AsignarAmbitoCanjeVale(AConsulta: TUniQuery;
  const ARestriccion: TRestriccionCanjeVale);

function ValidarAlmacenDepositoCredito(AConexion: TUniConnection;
  const AEmpresa: string; out AMensaje: string): Boolean;

procedure AsegurarSerieFacturaCaja(AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, ASerie, ASubtipo, AUsuario: string;
  AFecha: TDateTime);

implementation

uses
  System.SysUtils, Data.DB, UniDataValoresAutomaticosRepositorio,
  UniDataAlmacenesEmpresaRepositorio, inLibAlmacenesEmpresaPersistenciaIntf,
  inLibMsgCaja;

function FiltroAmbitoCanjeVale(
  const ARestriccion: TRestriccionCanjeVale): string;
begin
  Result := '';
  if ARestriccion.Ambito <> acvTodos then
  begin
    Result := ' AND CODIGO_EMP_EMI_VL = :EMP_CANJE' +
      ' AND CODIGO_ALM_EMI_VL = :ALM_CANJE';
    if ARestriccion.Ambito = acvCaja then
      Result := Result + ' AND CODIGO_CAJA_EMI_VL = :CAJA_CANJE';
  end;
end;

procedure AsignarAmbitoCanjeVale(AConsulta: TUniQuery;
  const ARestriccion: TRestriccionCanjeVale);
begin
  if ARestriccion.Ambito <> acvTodos then
  begin
    AConsulta.ParamByName('EMP_CANJE').AsString := ARestriccion.Empresa;
    AConsulta.ParamByName('ALM_CANJE').AsString := ARestriccion.Almacen;
    if ARestriccion.Ambito = acvCaja then
      AConsulta.ParamByName('CAJA_CANJE').AsString := ARestriccion.Caja;
  end;
end;

function ValidarAlmacenDepositoCredito(AConexion: TUniConnection;
  const AEmpresa: string; out AMensaje: string): Boolean;
var
  Repositorio: IRepositorioAlmacenesEmpresa;
begin
  Repositorio := TRepositorioAlmacenesEmpresaUniDAC.Create(AConexion);
  Result := Repositorio.ObtenerAlmacenDepositoEmpresa(AEmpresa) <> '';
  AMensaje := '';
  if not Result then
    AMensaje := Format(SErrorCreditoSinAlmacenDeposito, [AEmpresa]);
end;

const
  SQL_INICIO_CONTADOR_CAJA =
    'SELECT COALESCE(MAX(CAST(NUMERO_FAC AS UNSIGNED)), 0) + 1 AS INICIO ' +
    'FROM fza_facturas WHERE CODIGO_EMP_FAC = :EMP AND SERIE_FAC = :SERIE';
  SQL_ASEGURAR_CONTADOR_CAJA =
    'INSERT INTO fza_contadores (TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, ' +
    'CON, NUM_DIGITOS_CON, ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (''FC'', :EMP, :SERIE, :INICIO, ' +
    '6, ''S'', ''N'', NOW(), :USUARIO, :USUARIO) ' +
    'ON DUPLICATE KEY UPDATE CON = fza_contadores.CON';
  SQL_BUSCAR_SERIE_CAJA =
    'SELECT CODIGO_SERIE_EMPSER FROM vi_empresas_series ' +
    'WHERE CODIGO_EMP_EMPSER = :EMP AND EMPSER = :SERIE ' +
    'AND TIPO_DOC_EMPSER = ''FC'' AND SUBTIPO_EMPSER = :SUBTIPO ' +
    'AND (CODIGO_ALM_EMPSER = :ALM OR ' +
    'COALESCE(CODIGO_ALM_EMPSER, '''') = '''') ' +
    'AND (CODIGO_CAJA_EMPSER = :CAJA OR ' +
    'COALESCE(CODIGO_CAJA_EMPSER, '''') = '''') ' +
    'AND (FECHA_DESDE_EMPSER IS NULL OR FECHA_DESDE_EMPSER <= :FECHA) ' +
    'AND (FECHA_HASTA_EMPSER IS NULL OR FECHA_HASTA_EMPSER >= :FECHA) ' +
    'LIMIT 1';
  SQL_BLOQUEAR_CONTADOR_SERIES =
    'INSERT INTO fza_contadores (TIPO_DOC_CON, EMPRESA_CON, SERIE_CON, ' +
    'CON, NUM_DIGITOS_CON, ESACTIVO_CON, DEFAULT_CON, INSTANTE_ALTA, ' +
    'USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (''ES'', ''-'', ''-'', 1, 3, ''S'', ''S'', NOW(), ' +
    ':USUARIO, :USUARIO) ' +
    'ON DUPLICATE KEY UPDATE CON = fza_contadores.CON';
  SQL_INSERTAR_SERIE_CAJA =
    'INSERT INTO fza_empresas_series (CODIGO_SERIE_EMPSER, ' +
    'CODIGO_EMP_EMPSER, CODIGO_ALM_EMPSER, CODIGO_CAJA_EMPSER, EMPSER, ' +
    'TIPO_DOC_EMPSER, SUBTIPO_EMPSER, FECHA_DESDE_EMPSER, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:CODIGO, :EMP, :ALM, :CAJA, :SERIE, ''FC'', :SUBTIPO, ' +
    ':FECHA, NOW(), NOW(), :USUARIO, :USUARIO)';

procedure AsegurarSerieFacturaCaja(AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja, ASerie, ASubtipo, AUsuario: string;
  AFecha: TDateTime);
var
  Consulta: TUniQuery;
  CodigoSerie: string;
  InicioContador: Int64;

  procedure BuscarSerie(ABloquear: Boolean);
  begin
    Consulta.Close;
    Consulta.SQL.Text := SQL_BUSCAR_SERIE_CAJA;
    if ABloquear then
      Consulta.SQL.Add('FOR UPDATE');
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('SUBTIPO').AsString := ASubtipo;
    Consulta.ParamByName('ALM').AsString := AAlmacen;
    Consulta.ParamByName('CAJA').AsString := ACaja;
    Consulta.ParamByName('FECHA').AsDateTime := Trunc(AFecha);
    Consulta.Open;
  end;

begin
  if (Trim(ASerie) = '') or (Length(ASerie) > 12) then
    raise Exception.Create('Indique una serie de entre 1 y 12 caracteres.');
  if not AConexion.InTransaction then
    raise Exception.Create('La serie requiere la transacción de la venta.');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    Consulta.SQL.Text := SQL_INICIO_CONTADOR_CAJA;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.Open;
    InicioContador := Consulta.FieldByName('INICIO').AsLargeInt;
    Consulta.Close;
    // El contador ya existente conserva número, actividad y configuración.
    // Su PK serializa las altas simultáneas de la misma empresa/serie.
    Consulta.SQL.Text := SQL_ASEGURAR_CONTADOR_CAJA;
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('SERIE').AsString := ASerie;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.ParamByName('INICIO').AsLargeInt := InicioContador;
    Consulta.Execute;
    BuscarSerie(False);
    if Consulta.IsEmpty then
    begin
      Consulta.Close;
      // Exclusivo antes del INSERT IGNORE del generador ES: evita dos
      // bloqueos compartidos que luego intenten ascender a exclusivos.
      Consulta.SQL.Text := SQL_BLOQUEAR_CONTADOR_SERIES;
      Consulta.ParamByName('USUARIO').AsString := AUsuario;
      Consulta.Execute;
      CodigoSerie := ObtenerSiguienteContador(AConexion, 'ES', AUsuario);
      // Bloquear ES antes de leer con bloqueo evita que dos series nuevas
      // retengan huecos de empresas_series mientras esperan el contador.
      BuscarSerie(True);
      if Consulta.IsEmpty then
      begin
        Consulta.Close;
        Consulta.SQL.Text := SQL_INSERTAR_SERIE_CAJA;
        Consulta.ParamByName('CODIGO').AsString := CodigoSerie;
        Consulta.ParamByName('EMP').AsString := AEmpresa;
        Consulta.ParamByName('ALM').AsString := AAlmacen;
        Consulta.ParamByName('CAJA').AsString := ACaja;
        Consulta.ParamByName('SERIE').AsString := ASerie;
        Consulta.ParamByName('SUBTIPO').AsString := ASubtipo;
        Consulta.ParamByName('FECHA').AsDateTime := Trunc(AFecha);
        Consulta.ParamByName('USUARIO').AsString := AUsuario;
        Consulta.Execute;
      end;
    end;
  finally
    Consulta.Free;
  end;
end;

type
  TResultadoConsultaFaseCobroUniDAC = class(
    TInterfacedObject,
    IResultadoConsultaFaseCobro)
  private
    FDataSet: TDataSet;
  public
    constructor Create(ADataSet: TDataSet);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioFaseCobroUniDAC = class(
    TInterfacedObject,
    IRepositorioFaseCobro)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarSeries(
      const ASolicitud: TSolicitudSeriesFaseCobro
    ): TSeriesFaseCobro;
    function ObtenerResumenNumeracion(
      const ACodigoEmpresa, ASerie: string;
      ANumero: Int64
    ): TResumenNumeracionFaseCobro;
    function ConsultarFormasPago: IResultadoConsultaFaseCobro;
    function ObtenerCliente(
      const ACodigoCliente: string;
      out ACliente: TClienteFaseCobro
    ): Boolean;
    function ExisteValePendiente(
      const ACodigoVale: string;
      const ARestriccion: TRestriccionCanjeVale;
      out AMensaje: string
    ): Boolean;
    function ConsultarValesOrigen(
      const AEmpresa, ASerie, ANumero: string
    ): TValesOrigenFaseCobro;
  end;

constructor TResultadoConsultaFaseCobroUniDAC.Create(ADataSet: TDataSet);
begin
  inherited Create;
  FDataSet := ADataSet;
end;

destructor TResultadoConsultaFaseCobroUniDAC.Destroy;
begin
  FreeAndNil(FDataSet);
  inherited;
end;

function TResultadoConsultaFaseCobroUniDAC.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

constructor TRepositorioFaseCobroUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioFaseCobroUniDAC.ListarSeries(
  const ASolicitud: TSolicitudSeriesFaseCobro
): TSeriesFaseCobro;
var
  oConsulta: TUniQuery;
  iSerie: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT EMPSER AS SERIE_CON ' +
      '  FROM vi_empresas_series ' +
      ' WHERE CODIGO_EMP_EMPSER = :EMPRESA ' +
      '   AND (CODIGO_ALM_EMPSER = :ALMACEN ' +
      '        OR IFNULL(CODIGO_ALM_EMPSER, '''') = '''') ' +
      '   AND (CODIGO_CAJA_EMPSER = :CAJA ' +
      '        OR IFNULL(CODIGO_CAJA_EMPSER, '''') = '''') ' +
      '   AND TIPO_DOC_EMPSER = ''FC'' ' +
      '   AND SUBTIPO_EMPSER = :SUBTIPO ' +
      '   AND (FECHA_DESDE_EMPSER <= :FECHA ' +
      '        OR FECHA_DESDE_EMPSER IS NULL) ' +
      '   AND (FECHA_HASTA_EMPSER >= :FECHA ' +
      '        OR FECHA_HASTA_EMPSER IS NULL)';
    oConsulta.ParamByName('EMPRESA').AsString :=
      ASolicitud.CodigoEmpresa;
    oConsulta.ParamByName('ALMACEN').AsString :=
      ASolicitud.CodigoAlmacen;
    oConsulta.ParamByName('CAJA').AsString := ASolicitud.CodigoCaja;
    oConsulta.ParamByName('SUBTIPO').AsString := ASolicitud.Subtipo;
    oConsulta.ParamByName('FECHA').AsDateTime := ASolicitud.Fecha;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iSerie := 0;
    while not oConsulta.Eof do
    begin
      Result[iSerie] := oConsulta.FieldByName('SERIE_CON').AsString;
      Inc(iSerie);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ObtenerResumenNumeracion(
  const ACodigoEmpresa, ASerie: string;
  ANumero: Int64
): TResumenNumeracionFaseCobro;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResumenNumeracionFaseCobro);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS NFILAS, ' +
      '       MIN(CAST(NUMERO_FAC AS UNSIGNED)) AS NMIN, ' +
      '       MAX(CAST(NUMERO_FAC AS UNSIGNED)) AS NMAX, ' +
      '       MAX(LENGTH(NUMERO_FAC)) AS NLEN, ' +
      '       SUM(CASE WHEN CAST(NUMERO_FAC AS UNSIGNED) = :NUMERO ' +
      '                THEN 1 ELSE 0 END) AS NEXISTE ' +
      '  FROM fza_facturas ' +
      ' WHERE CODIGO_EMP_FAC = :EMPRESA ' +
      '   AND SERIE_FAC = :SERIE';
    oConsulta.ParamByName('NUMERO').AsLargeInt := ANumero;
    oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.Open;
    Result.Filas := oConsulta.FieldByName('NFILAS').AsLargeInt;
    Result.Minimo := oConsulta.FieldByName('NMIN').AsLargeInt;
    Result.Maximo := oConsulta.FieldByName('NMAX').AsLargeInt;
    Result.Longitud := oConsulta.FieldByName('NLEN').AsInteger;
    Result.ExistentesNumero :=
      oConsulta.FieldByName('NEXISTE').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ConsultarFormasPago:
  IResultadoConsultaFaseCobro;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  oConsulta.Connection := FConexion;
  oConsulta.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_caja_formas_pago ' +
    ' WHERE ESACTIVO_FORMA_PAGO_CFP = ''S'' ' +
    ' ORDER BY ORDEN_VISUAL_FORMA_PAGO_CFP';
  oConsulta.Open;
  Result := TResultadoConsultaFaseCobroUniDAC.Create(oConsulta);
end;

function TRepositorioFaseCobroUniDAC.ObtenerCliente(
  const ACodigoCliente: string;
  out ACliente: TClienteFaseCobro
): Boolean;
var
  oConsulta: TUniQuery;
begin
  ACliente := Default(TClienteFaseCobro);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT RAZON_SOCIAL_CLI, EMAIL_CLI, ' +
      '       ESPERMITE_DEUDA_CLI, ESVARIOS_CLI, ' +
      '       TOTAL_LIMITE_CREDITO_CLI, ' +
      '       TOTAL_DEUDA_CLI ' +
      '  FROM fza_clientes ' +
      ' WHERE CODIGO_CLI_CLI = :CODIGO ' +
      ' LIMIT 1';
    oConsulta.ParamByName('CODIGO').AsString := ACodigoCliente;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
    begin
      ACliente.Nombre :=
        oConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
      ACliente.Email := oConsulta.FieldByName('EMAIL_CLI').AsString;
      ACliente.PermiteDeuda :=
        oConsulta.FieldByName('ESPERMITE_DEUDA_CLI').AsString = 'S';
      ACliente.EsClienteVarios :=
        oConsulta.FieldByName('ESVARIOS_CLI').AsString = 'S';
      ACliente.LimiteCredito :=
        oConsulta.FieldByName('TOTAL_LIMITE_CREDITO_CLI').AsCurrency;
      ACliente.DeudaActual :=
        oConsulta.FieldByName('TOTAL_DEUDA_CLI').AsCurrency;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ExisteValePendiente(
  const ACodigoVale: string;
  const ARestriccion: TRestriccionCanjeVale;
  out AMensaje: string
): Boolean;
var
  oConsulta: TUniQuery;
begin
  AMensaje := Format(SErrorValeCanjeNoDisponible, [ACodigoVale]);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_EMP_EMI_VL, CODIGO_ALM_EMI_VL, ' +
      '       CODIGO_CAJA_EMI_VL FROM fza_caja_vales ' +
      ' WHERE CODIGO_VL = :CODIGO ' +
      '   AND ESTADO_VL = ''PENDIENTE'' ' +
      '   AND (FECHA_CADUCIDAD_VL IS NULL ' +
      '        OR FECHA_CADUCIDAD_VL >= CURDATE()) LIMIT 1';
    oConsulta.ParamByName('CODIGO').AsString := ACodigoVale;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
    if Result then
    begin
      Result := ARestriccion.Permite(
        oConsulta.FieldByName('CODIGO_EMP_EMI_VL').AsString,
        oConsulta.FieldByName('CODIGO_ALM_EMI_VL').AsString,
        oConsulta.FieldByName('CODIGO_CAJA_EMI_VL').AsString);
      if not Result then
        AMensaje := ARestriccion.MensajeRechazo(ACodigoVale,
          oConsulta.FieldByName('CODIGO_EMP_EMI_VL').AsString,
          oConsulta.FieldByName('CODIGO_ALM_EMI_VL').AsString,
          oConsulta.FieldByName('CODIGO_CAJA_EMI_VL').AsString);
    end;
    if Result then
      AMensaje := '';
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioFaseCobroUniDAC.ConsultarValesOrigen(
  const AEmpresa, ASerie, ANumero: string
): TValesOrigenFaseCobro;
var
  oConsulta: TUniQuery;
  oVale: TValeOrigenFaseCobro;
begin
  Result := Default(TValesOrigenFaseCobro);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    // Canjeado en el origen, menos los vales emitidos en esa misma
    // operación (cambio) y los ya devueltos en vale por otras
    // devoluciones (hijos de los vales canjeados).
    oConsulta.SQL.Text :=
      'SELECT MIN(R.CODIGO_VL) AS CODIGO_VL, ' +
      '       COALESCE(SUM(R.IMPORTE_REDIMIDO_VL), 0) - ' +
      '       (SELECT COALESCE(SUM(E.IMPORTE_NOMINAL_VL), 0) ' +
      '          FROM fza_caja_vales E ' +
      '         WHERE E.CODIGO_EMP_EMI_VL = :EMP ' +
      '           AND E.SERIE_FAC_EMI_VL = :SERIE ' +
      '           AND E.NUMERO_FAC_EMI_VL = :NUMERO) - ' +
      '       (SELECT COALESCE(SUM(H.IMPORTE_NOMINAL_VL), 0) ' +
      '          FROM fza_caja_vales H ' +
      '          JOIN fza_caja_vales P ' +
      '            ON P.CODIGO_VL = H.CODIGO_PADRE_VL ' +
      '         WHERE P.CODIGO_EMP_RED_VL = :EMP ' +
      '           AND P.SERIE_FAC_RED_VL = :SERIE ' +
      '           AND P.NUMERO_FAC_RED_VL = :NUMERO ' +
      '           AND H.ESTADO_VL <> ''ANULADO'' ' +
      '           AND NOT (H.CODIGO_EMP_EMI_VL = :EMP ' +
      '                AND H.SERIE_FAC_EMI_VL = :SERIE ' +
      '                AND H.NUMERO_FAC_EMI_VL = :NUMERO)) ' +
      '         AS IMPORTE ' +
      '  FROM fza_caja_vales R ' +
      ' WHERE R.CODIGO_EMP_RED_VL = :EMP ' +
      '   AND R.SERIE_FAC_RED_VL = :SERIE ' +
      '   AND R.NUMERO_FAC_RED_VL = :NUMERO ' +
      '   AND R.ESTADO_VL = ''REDIMIDO''';
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    if (not oConsulta.IsEmpty) and
       (oConsulta.FieldByName('IMPORTE').AsCurrency > 0) then
    begin
      Result.ImporteCanjeado := oConsulta.FieldByName('IMPORTE').AsCurrency;
      Result.CodigoValeCanjeado :=
        oConsulta.FieldByName('CODIGO_VL').AsString;
    end;
    oConsulta.Close;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_VL, IMPORTE_NOMINAL_VL ' +
      '  FROM fza_caja_vales ' +
      ' WHERE CODIGO_EMP_EMI_VL = :EMP ' +
      '   AND SERIE_FAC_EMI_VL = :SERIE ' +
      '   AND NUMERO_FAC_EMI_VL = :NUMERO ' +
      '   AND ESTADO_VL = ''PENDIENTE'' ' +
      '   AND (FECHA_CADUCIDAD_VL IS NULL ' +
      '        OR FECHA_CADUCIDAD_VL >= CURDATE()) ' +
      ' ORDER BY CODIGO_VL';
    oConsulta.ParamByName('EMP').AsString := AEmpresa;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oVale.Codigo := oConsulta.FieldByName('CODIGO_VL').AsString;
      oVale.Importe :=
        oConsulta.FieldByName('IMPORTE_NOMINAL_VL').AsCurrency;
      Result.ValesPendientes := Result.ValesPendientes + [oVale];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioFaseCobroUniDAC(
  AConexion: TUniConnection
): IRepositorioFaseCobro;
begin
  Result := TRepositorioFaseCobroUniDAC.Create(AConexion);
end;

end.
