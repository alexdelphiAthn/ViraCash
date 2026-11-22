unit UniDataAlmacenesEmpresaRepositorio;

interface

uses
  Data.DB, Uni,
  inLibAlmacenesEmpresaPersistenciaIntf;

type
  TRepositorioAlmacenesEmpresaUniDAC = class(
    TInterfacedObject, IRepositorioAlmacenesEmpresa)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function AlmacenPerteneceEmpresa(const AEmpresa,
      AAlmacen: string): Boolean;
    function PrimerAlmacenEmpresa(const AEmpresa: string): string;
    function ObtenerAlmacenDepositoEmpresa(
      const AEmpresa: string; const AAlmacenOrigen: string = ''): string;
  end;

  TCustodiaDeposito = record
    Almacen: string;
    Lote: string;
    Caducidad: TDateTime;
    TieneMovimiento: Boolean;
  end;

function AlmacenPerteneceEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): Boolean;
function PrimerAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
function ResolverAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): string;
procedure AjustarEmpresaAlmacenDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
procedure AjustarEmpresasAlmacenesDocumento(AConexion: TUniConnection;
  ADataSet: TDataSet);
function ObtenerAlmacenDepositoEmpresa(AConexion: TUniConnection;
  const AEmpresa: string; const AAlmacenOrigen: string = ''): string;
function ObtenerAlmacenCustodiaDeposito(AConexion: TUniConnection;
  const AEmpresa, AIdDeposito: string): string;
function LeerCustodiaDeposito(AConexion: TUniConnection;
  const AEmpresa, AIdDeposito: string): TCustodiaDeposito;
function SqlMovimientoCustodiaDeposito(ABloquear: Boolean): string;

const
  SERIE_CAMBIO_DEPOSITO = 'CAMBIODEP';

implementation

uses
  System.SysUtils,
  inLibData, inLibMsgCaja;

function SqlMovimientoCustodiaDeposito(ABloquear: Boolean): string;
var
  Bloqueo: string;
begin
  Bloqueo := '';
  if ABloquear then
    Bloqueo := ' FOR UPDATE';
  // D es la ficha del depósito. La entrada del último cambio manda
  // sobre la del traspaso que dio de alta el depósito.
  Result :=
    'COALESCE((' +
    ' SELECT M.NUMERO_MOV FROM fza_movimientos_almacen M ' +
    ' WHERE M.CODIGO_EMP_MOV = D.CODIGO_EMP_DEP ' +
    '   AND M.TIPO_DOC_MOV = ''TR'' AND M.TIPO_MOV = ''E'' ' +
    '   AND M.SERIE_DOC_MOV = ''' + SERIE_CAMBIO_DEPOSITO + ''' ' +
    '   AND M.NUMERO_DOC_MOV = D.ID_DEPOSITO_DEP ' +
    '   AND M.ESACTIVO_MOV = ''S'' ' +
    ' ORDER BY M.NUMERO_MOV DESC LIMIT 1' + Bloqueo + '), (' +
    ' SELECT M.NUMERO_MOV FROM fza_movimientos_almacen M ' +
    ' JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = M.CODIGO_ALM_MOV ' +
    '    AND A.CODIGO_EMP_ALM = M.CODIGO_EMP_MOV ' +
    ' WHERE M.CODIGO_EMP_MOV = D.CODIGO_EMP_DEP ' +
    '   AND M.CODIGO_ALM_DOC_MOV = D.CODIGO_ALM_DEP ' +
    '   AND M.CODIGO_ALM_CONTRA_MOV = D.CODIGO_ALM_DEP ' +
    '   AND M.CODIGO_CAJA_DOC_MOV = D.CODIGO_CAJA_DEP ' +
    '   AND M.NUMERO_OPERACION_DOC_MOV = D.NUMERO_OPERACION_DEP ' +
    '   AND M.CODIGO_UNIDAD_MOV = D.CODIGO_UNIDAD_DEP ' +
    '   AND M.TIPO_DOC_MOV = ''TR'' AND M.TIPO_MOV = ''E'' ' +
    '   AND M.ESACTIVO_MOV = ''S'' ' +
    '   AND A.TIPO_USO_ALM IN (''DEPÓSITO'', ''DEPOSITO'') ' +
    ' ORDER BY M.NUMERO_MOV LIMIT 1' + Bloqueo + ')) ';
end;

constructor TRepositorioAlmacenesEmpresaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioAlmacenesEmpresaUniDAC.AlmacenPerteneceEmpresa(
  const AEmpresa, AAlmacen: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        '   AND CODIGO_ALM_ALM = :ALMACEN ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := Trim(AEmpresa);
      oConsulta.ParamByName('ALMACEN').AsString := Trim(AAlmacen);
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioAlmacenesEmpresaUniDAC.PrimerAlmacenEmpresa(
  const AEmpresa: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_ALM_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        '   AND COALESCE(ESACTIVO_ALM, ''S'') = ''S'' ' +
        // FZ-ISSUE-786: se propone antes un almacen normal que uno de
        // depositos, transito o taras.
        ' ORDER BY CASE WHEN COALESCE(TIPO_USO_ALM, '''') IN ' +
        '   ('''', ''ESTANDAR'', ''ESTANDARD'') THEN 0 ELSE 1 END, ' +
        '   COALESCE(ORDEN_ALM, 2147483647), ' +
        '          CODIGO_ALM_ALM ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMPRESA').AsString := Trim(AEmpresa);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioAlmacenesEmpresaUniDAC.ObtenerAlmacenDepositoEmpresa(
  const AEmpresa, AAlmacenOrigen: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if Assigned(FConexion) and FConexion.Connected then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_ALM_ALM ' +
        '  FROM fza_almacenes ' +
        ' WHERE CODIGO_EMP_ALM = :EMP ' +
        '   AND ESACTIVO_ALM = ''S'' ' +
        '   AND TIPO_USO_ALM IN (''DEPÓSITO'', ''DEPOSITO'') ' +
        '   AND (COALESCE(TRIM(CODIGO_PADRE_ALM), '''') = '''' ' +
        '     OR CODIGO_PADRE_ALM = :ORIGEN) ' +
        ' ORDER BY CASE WHEN CODIGO_PADRE_ALM = :ORIGEN ' +
        '                    AND :ORIGEN <> '''' THEN 0 ELSE 1 END, ' +
        '          COALESCE(ORDEN_ALM, 2147483647), CODIGO_ALM_ALM ' +
        ' LIMIT 1';
      oConsulta.ParamByName('EMP').AsString := Trim(AEmpresa);
      oConsulta.ParamByName('ORIGEN').AsString := Trim(AAlmacenOrigen);
      oConsulta.Open;
      if not oConsulta.IsEmpty then
        Result := oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearRepositorio(AConexion: TUniConnection):
  IRepositorioAlmacenesEmpresa;
begin
  Result := TRepositorioAlmacenesEmpresaUniDAC.Create(AConexion);
end;

function AlmacenPerteneceEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): Boolean;
begin
  Result := inLibData.AlmacenPerteneceEmpresa(
    CrearRepositorio(AConexion), AEmpresa, AAlmacen);
end;

function PrimerAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa: string): string;
begin
  Result := inLibData.PrimerAlmacenEmpresa(
    CrearRepositorio(AConexion), AEmpresa);
end;

function ResolverAlmacenEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacen: string): string;
begin
  Result := inLibData.ResolverAlmacenEmpresa(
    CrearRepositorio(AConexion), AEmpresa, AAlmacen);
end;

procedure AjustarEmpresaAlmacenDataSet(AConexion: TUniConnection;
  ADataSet: TDataSet; const ACampoEmpresa, ACampoAlmacen: string);
begin
  inLibData.AjustarEmpresaAlmacenDataSet(
    CrearRepositorio(AConexion), ADataSet,
    ACampoEmpresa, ACampoAlmacen);
end;

procedure AjustarEmpresasAlmacenesDocumento(AConexion: TUniConnection;
  ADataSet: TDataSet);
begin
  inLibData.AjustarEmpresasAlmacenesDocumento(
    CrearRepositorio(AConexion), ADataSet);
end;

function ObtenerAlmacenDepositoEmpresa(AConexion: TUniConnection;
  const AEmpresa, AAlmacenOrigen: string): string;
begin
  Result := inLibData.ObtenerAlmacenDepositoEmpresa(
    CrearRepositorio(AConexion), AEmpresa, AAlmacenOrigen);
end;

function ObtenerAlmacenCustodiaDeposito(AConexion: TUniConnection;
  const AEmpresa, AIdDeposito: string): string;
begin
  Result := LeerCustodiaDeposito(AConexion, AEmpresa, AIdDeposito).Almacen;
end;

function LeerCustodiaDeposito(AConexion: TUniConnection;
  const AEmpresa, AIdDeposito: string): TCustodiaDeposito;
var
  Consulta: TUniQuery;
  Almacenes: IRepositorioAlmacenesEmpresa;
  AlmacenOrigen: string;
begin
  Result := Default(TCustodiaDeposito);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    // La ficha guarda la tienda de origen. La entrada del traspaso guarda
    // dónde quedó la mercancía aunque luego se configure otro depósito.
    Consulta.SQL.Text :=
      'SELECT D.CODIGO_ALM_DEP, M.CODIGO_ALM_MOV AS ALMACEN_CUSTODIA, ' +
      'M.LOTE_MOV, M.FECHA_CADUCIDAD_MOV ' +
      'FROM fza_depositos_cliente D ' +
      'LEFT JOIN fza_movimientos_almacen M ON M.NUMERO_MOV = ' +
      SqlMovimientoCustodiaDeposito(AConexion.InTransaction) +
      'WHERE D.CODIGO_EMP_DEP = :EMP AND D.ID_DEPOSITO_DEP = :ID';
    if AConexion.InTransaction then
      Consulta.SQL.Add('FOR UPDATE');
    Consulta.ParamByName('EMP').AsString := AEmpresa;
    Consulta.ParamByName('ID').AsString := AIdDeposito;
    Consulta.Open;
    if Consulta.IsEmpty then
      raise Exception.Create(SErrorOperacionCajaNoEncontrada);
    Result.Almacen := Consulta.FieldByName('ALMACEN_CUSTODIA').AsString;
    Result.TieneMovimiento := Result.Almacen <> '';
    Result.Lote := Consulta.FieldByName('LOTE_MOV').AsString;
    Result.Caducidad := Consulta.FieldByName('FECHA_CADUCIDAD_MOV').AsDateTime;
    AlmacenOrigen := Consulta.FieldByName('CODIGO_ALM_DEP').AsString;
  finally
    Consulta.Free;
  end;
  if not Result.TieneMovimiento then
  begin
    // En depósitos antiguos sin entrada identificable, priorizar el
    // almacén general usado antes de la selección por tienda.
    Almacenes := CrearRepositorio(AConexion);
    Result.Almacen := Almacenes.ObtenerAlmacenDepositoEmpresa(AEmpresa);
    if Result.Almacen = '' then
      Result.Almacen := inLibData.ObtenerAlmacenDepositoEmpresa(
        Almacenes, AEmpresa, AlmacenOrigen);
  end;
end;

end.
