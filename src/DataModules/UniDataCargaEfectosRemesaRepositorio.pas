{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataCargaEfectosRemesaRepositorio                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC para cargar efectos en remesas de compra o venta.    }
{******************************************************************************}
unit UniDataCargaEfectosRemesaRepositorio;

interface

uses
  Uni, inLibCargaEfectosRemesaPersistenciaIntf;

function CrearRepositorioCargaEfectosRemesaUniDAC(
  AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;

implementation

uses
  System.SysUtils, Data.DB, DBAccess;

const
  SQL_EMPRESAS =
    'SELECT * FROM fza_empresas ORDER BY RAZON_SOCIAL_EMP';

type
  TConfigPersistenciaRemesa = record
    TablaEfectos: string;
    TablaRemesas: string;
    SufijoEfecto: string;
    SufijoRemesa: string;
    CampoSerieFactura: string;
    CampoNumeroFactura: string;
    CampoTercero: string;
    ProcedimientoCrear: string;
    ProcedimientoAnyadir: string;
    ParametroNumeroEfecto: string;
  end;

  TConsultaEfectosRemesaUniDAC = class(
    TInterfacedObject,
    IConsultaEfectosRemesa)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioCargaEfectosRemesaUniDAC = class(
    TInterfacedObject,
    IRepositorioCargaEfectosRemesa)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function CargarEfectos(
      ATipo: TTipoCargaEfectosRemesa;
      const ASerieRemesa, ANumeroRemesa: string;
      const AEfectos: TEfectosParaRemesar;
      const AUsuario: string): TResultadoCargaEfectosRemesa;
    function AbrirConsulta(
      const ASql: string): IConsultaEfectosRemesa;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarEmpresas: IConsultaEfectosRemesa;
    function ConsultarEfectosPendientes(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa: string;
      AFechaHasta: TDateTime): IConsultaEfectosRemesa;
    function ListarRemesasAbiertas(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa: string): TRemesasAbiertas;
    function CrearRemesa(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa, AUsuario: string): TResultadoCreacionRemesa;
    function AnyadirEfectos(
      ATipo: TTipoCargaEfectosRemesa;
      const ASerieRemesa, ANumeroRemesa: string;
      const AEfectos: TEfectosParaRemesar;
      const AUsuario: string): TResultadoCargaEfectosRemesa;
    function CrearRemesaConEfectos(
      ATipo: TTipoCargaEfectosRemesa;
      const AEmpresa: string;
      const AEfectos: TEfectosParaRemesar;
      const AUsuario: string;
      out ACreacion: TResultadoCreacionRemesa): TResultadoCargaEfectosRemesa;
  end;

function ConfigPersistencia(
  ATipo: TTipoCargaEfectosRemesa): TConfigPersistenciaRemesa;
begin
  case ATipo of
    tcerCompra:
      begin
        Result.TablaEfectos := 'fza_efectos_compra';
        Result.TablaRemesas := 'fza_remesas_compra';
        Result.SufijoEfecto := 'EFEC';
        Result.SufijoRemesa := 'REMC';
        Result.CampoSerieFactura := 'SERIE_FACC_EFEC';
        Result.CampoNumeroFactura := 'NUMERO_FACC_EFEC';
        Result.CampoTercero := 'RAZON_SOCIAL_PRV_EFEC';
        Result.ProcedimientoCrear := 'PRC_REMC_CREAR';
        Result.ProcedimientoAnyadir := 'PRC_REMC_ANYADIR_EFECTO';
        Result.ParametroNumeroEfecto := 'p_NUM_EFEC';
      end;
    tcerVenta:
      begin
        Result.TablaEfectos := 'fza_efectos_venta';
        Result.TablaRemesas := 'fza_remesas_venta';
        Result.SufijoEfecto := 'EFV';
        Result.SufijoRemesa := 'REMV';
        Result.CampoSerieFactura := 'SERIE_FAC_EFV';
        Result.CampoNumeroFactura := 'NUMERO_FAC_EFV';
        Result.CampoTercero := 'RAZON_SOCIAL_CLI_EFV';
        Result.ProcedimientoCrear := 'PRC_REMV_CREAR';
        Result.ProcedimientoAnyadir := 'PRC_REMV_ANYADIR_EFECTO';
        Result.ParametroNumeroEfecto := 'p_NUM_EFV';
      end;
  end;
end;

function ConstruirSqlEfectos(
  const AConfig: TConfigPersistenciaRemesa): string;
begin
  Result :=
    'SELECT ' + AConfig.CampoSerieFactura + ' AS SERIE_FAC_EFECTO, ' +
    AConfig.CampoNumeroFactura + ' AS NUMERO_FAC_EFECTO, ' +
    'NUMERO_' + AConfig.SufijoEfecto + ' AS NUMERO_EFECTO, ' +
    AConfig.CampoTercero + ' AS TERCERO_EFECTO, ' +
    'FECHA_VENCIMIENTO_' + AConfig.SufijoEfecto +
    ' AS FECHA_VENCIMIENTO_EFECTO, IMPORTE_PENDIENTE_' +
    AConfig.SufijoEfecto + ' AS IMPORTE_PENDIENTE_EFECTO, ESTADO_' +
    AConfig.SufijoEfecto + ' AS ESTADO_EFECTO FROM ' +
    AConfig.TablaEfectos + ' WHERE CODIGO_EMP_' +
    AConfig.SufijoEfecto + ' = :EMP AND SERIE_' +
    AConfig.SufijoRemesa + '_' + AConfig.SufijoEfecto +
    ' IS NULL AND COALESCE(ESTADO_' + AConfig.SufijoEfecto + ', ' +
    QuotedStr('') + ') IN (' + QuotedStr('PENDIENTE') + ', ' +
    QuotedStr('PARCIAL') + ') AND COALESCE(IMPORTE_PENDIENTE_' +
    AConfig.SufijoEfecto + ', 0) > 0 AND FECHA_VENCIMIENTO_' +
    AConfig.SufijoEfecto + ' <= :HASTA ORDER BY FECHA_VENCIMIENTO_' +
    AConfig.SufijoEfecto + ', ' + AConfig.CampoTercero;
end;

function ConstruirSqlRemesas(
  const AConfig: TConfigPersistenciaRemesa): string;
begin
  Result :=
    'SELECT SERIE_' + AConfig.SufijoRemesa + ' AS SERIE_REMESA, ' +
    'NUMERO_' + AConfig.SufijoRemesa + ' AS NUMERO_REMESA, FECHA_' +
    AConfig.SufijoRemesa + ' AS FECHA_REMESA FROM ' +
    AConfig.TablaRemesas + ' WHERE CODIGO_EMP_' +
    AConfig.SufijoRemesa + ' = :EMP AND COALESCE(ESTADO_' +
    AConfig.SufijoRemesa + ', ' + QuotedStr('') + ') IN (' +
    QuotedStr('ABIERTA') + ', ' + QuotedStr('CERRADA') +
    ') ORDER BY FECHA_' + AConfig.SufijoRemesa + ' DESC, NUMERO_' +
    AConfig.SufijoRemesa + ' DESC';
end;

constructor TConsultaEfectosRemesaUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaEfectosRemesaUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaEfectosRemesaUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioCargaEfectosRemesaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioCargaEfectosRemesaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioCargaEfectosRemesaUniDAC.AbrirConsulta(
  const ASql: string): IConsultaEfectosRemesa;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := ASql;
    Consulta.Open;
    Result := TConsultaEfectosRemesaUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioCargaEfectosRemesaUniDAC.ConsultarEmpresas:
  IConsultaEfectosRemesa;
begin
  Result := AbrirConsulta(SQL_EMPRESAS);
end;

function TRepositorioCargaEfectosRemesaUniDAC.ConsultarEfectosPendientes(
  ATipo: TTipoCargaEfectosRemesa;
  const AEmpresa: string;
  AFechaHasta: TDateTime): IConsultaEfectosRemesa;
var
  Config: TConfigPersistenciaRemesa;
  Consulta: TUniQuery;
begin
  Config := ConfigPersistencia(ATipo);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := ConstruirSqlEfectos(Config);
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('HASTA').AsDateTime := AFechaHasta;
    Consulta.Open;
    Result := TConsultaEfectosRemesaUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioCargaEfectosRemesaUniDAC.ListarRemesasAbiertas(
  ATipo: TTipoCargaEfectosRemesa;
  const AEmpresa: string): TRemesasAbiertas;
var
  Config: TConfigPersistenciaRemesa;
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Config := ConfigPersistencia(ATipo);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := ConstruirSqlRemesas(Config);
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion].Serie :=
        Consulta.FieldByName('SERIE_REMESA').AsString;
      Result[Posicion].Numero :=
        Consulta.FieldByName('NUMERO_REMESA').AsString;
      Result[Posicion].Fecha :=
        Consulta.FieldByName('FECHA_REMESA').AsDateTime;
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioCargaEfectosRemesaUniDAC.CrearRemesa(
  ATipo: TTipoCargaEfectosRemesa;
  const AEmpresa, AUsuario: string): TResultadoCreacionRemesa;
var
  Config: TConfigPersistenciaRemesa;
  Procedimiento: TUniStoredProc;
begin
  Result.Creada := False;
  Result.Serie := '';
  Result.Numero := '';
  Config := ConfigPersistencia(ATipo);
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := Config.ProcedimientoCrear;
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'p_EMPRESA', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_IBAN', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE_OUT', ptOutput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO_OUT', ptOutput);
    Procedimiento.ParamByName('p_EMPRESA').AsString := AEmpresa;
    Procedimiento.ParamByName('p_IBAN').AsString := '';
    Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
    Procedimiento.ExecProc;
    Result.Serie := Procedimiento.ParamByName('p_SERIE_OUT').AsString;
    Result.Numero := Procedimiento.ParamByName('p_NUMERO_OUT').AsString;
    Result.Creada := Result.Numero <> '';
  finally
    FreeAndNil(Procedimiento);
  end;
end;

function TRepositorioCargaEfectosRemesaUniDAC.CargarEfectos(
  ATipo: TTipoCargaEfectosRemesa;
  const ASerieRemesa, ANumeroRemesa: string;
  const AEfectos: TEfectosParaRemesar;
  const AUsuario: string): TResultadoCargaEfectosRemesa;
var
  Config: TConfigPersistenciaRemesa;
  Efecto: TEfectoParaRemesar;
  Procedimiento: TUniStoredProc;
begin
  Result.Procesados := 0;
  Result.Omitidos := 0;
  Config := ConfigPersistencia(ATipo);
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := Config.ProcedimientoAnyadir;
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE_REM', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO_REM', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_SERIE_FAC', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_NUMERO_FAC', ptInput);
    Procedimiento.Params.CreateParam(
      ftInteger, Config.ParametroNumeroEfecto, ptInput);
    Procedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    Procedimiento.Params.CreateParam(ftInteger, 'p_RESULTADO', ptOutput);
    for Efecto in AEfectos do
    begin
      Procedimiento.ParamByName('p_SERIE_REM').AsString := ASerieRemesa;
      Procedimiento.ParamByName('p_NUMERO_REM').AsString := ANumeroRemesa;
      Procedimiento.ParamByName('p_SERIE_FAC').AsString :=
        Efecto.SerieFactura;
      Procedimiento.ParamByName('p_NUMERO_FAC').AsString :=
        Efecto.NumeroFactura;
      Procedimiento.ParamByName(
        Config.ParametroNumeroEfecto).AsInteger := Efecto.NumeroEfecto;
      Procedimiento.ParamByName('p_USUARIO').AsString := AUsuario;
      Procedimiento.ExecProc;
      if Procedimiento.ParamByName('p_RESULTADO').AsInteger = 1 then
        Inc(Result.Procesados)
      else
        Inc(Result.Omitidos);
    end;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

// Todo o nada: un commit por efecto dejaba la remesa cargada a medias,
// con riesgo de un fichero SEPA parcial. PRC_REMV/REMC_ANYADIR_EFECTO y
// _CREAR respetan la transacción desde FZ-ISSUE-143 (FZ-ISSUE-152).
function TRepositorioCargaEfectosRemesaUniDAC.AnyadirEfectos(
  ATipo: TTipoCargaEfectosRemesa;
  const ASerieRemesa, ANumeroRemesa: string;
  const AEfectos: TEfectosParaRemesar;
  const AUsuario: string): TResultadoCargaEfectosRemesa;
var
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    Result := CargarEfectos(
      ATipo, ASerieRemesa, ANumeroRemesa, AEfectos, AUsuario);
    if bTransaccionPropia then
      FConexion.Commit;
  except
    if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function TRepositorioCargaEfectosRemesaUniDAC.CrearRemesaConEfectos(
  ATipo: TTipoCargaEfectosRemesa;
  const AEmpresa: string;
  const AEfectos: TEfectosParaRemesar;
  const AUsuario: string;
  out ACreacion: TResultadoCreacionRemesa): TResultadoCargaEfectosRemesa;
var
  bTransaccionPropia: Boolean;
begin
  Result.Procesados := 0;
  Result.Omitidos := 0;
  bTransaccionPropia := not FConexion.InTransaction;
  if bTransaccionPropia then
    FConexion.StartTransaction;
  try
    ACreacion := CrearRemesa(ATipo, AEmpresa, AUsuario);
    if ACreacion.Creada then
      Result := CargarEfectos(
        ATipo, ACreacion.Serie, ACreacion.Numero, AEfectos, AUsuario);
    if bTransaccionPropia then
      FConexion.Commit;
  except
    if bTransaccionPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

function CrearRepositorioCargaEfectosRemesaUniDAC(
  AConexion: TUniConnection): IRepositorioCargaEfectosRemesa;
begin
  Result := TRepositorioCargaEfectosRemesaUniDAC.Create(AConexion);
end;

end.
