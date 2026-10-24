{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataMovimientosAlmacenRepositorio                          }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lectura filtrada y escritura transaccional del kardex de almacén.         }
{******************************************************************************}
unit UniDataMovimientosAlmacenRepositorio;

interface

uses
  Uni,
  inLibContextoSesionIntf,
  inLibMovimientosAlmacenAplicacion,
  inLibParametrosIntf;

function CrearLectorMovimientosAlmacenUniDAC(
  AConsulta: TUniQuery;
  const AContexto: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion): ILectorMovimientosAlmacen;
procedure CrearEscrituraMovimientosAlmacenUniDAC(
  AConexion: TUniConnection;
  out AEscritor: IEscritorMovimientosAlmacen;
  out AUnidadTrabajo: IUnidadTrabajoMovimientosAlmacen);

implementation

uses
  Data.DB,
  System.SysUtils,
  inLibFiltroUsuario,
  inLibPrestaShopColaSenal,
  UniDataMovimientosAlmacenRecalculo,
  UniDataValoresAutomaticosRepositorio;

const
  NOMBRE_SAVEPOINT_MOVIMIENTOS = 'FZAM_IA42_MOVIMIENTOS';

type
  TLectorMovimientosAlmacenUniDAC = class(
    TInterfacedObject,
    ILectorMovimientosAlmacen)
  private
    FAlmacenRestringido: string;
    FConsulta: TUniQuery;
    FControlesDeshabilitados: Boolean;
    FEmpresaRestringida: string;
    FFiltro: TFiltroMovimientosAlmacen;
    function ConstruirWhere: string;
    procedure AsignarParametros(AConsulta: TUniQuery);
  public
    constructor Create(
      AConsulta: TUniQuery;
      const AContexto: IContextoSesionAplicacion;
      const AParametros: IParametrosAplicacion);
    function ObtenerAnyos: TArray<Integer>;
    function ObtenerAlmacenes: TArray<TAlmacenFiltroMovimiento>;
    procedure Preparar(const AFiltro: TFiltroMovimientosAlmacen);
    function Contar: Integer;
    procedure IniciarCarga(ATamanoBloque: Integer);
    function HayMovimiento: Boolean;
    procedure Siguiente;
    procedure FinalizarCarga;
  end;
  TUnidadTrabajoMovimientosAlmacenUniDAC = class(
    TInterfacedObject,
    IUnidadTrabajoMovimientosAlmacen)
  private
    FConexion: TUniConnection;
    FIniciada: Boolean;
    FPropietaria: Boolean;
  public
    constructor Create(AConexion: TUniConnection);
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  TEscritorMovimientosAlmacenUniDAC = class(
    TInterfacedObject,
    IEscritorMovimientosAlmacen)
  private
    FConexion: TUniConnection;
    procedure AsignarParametros(
      AProcedimiento: TUniStoredProc;
      const AMovimiento: TMovimientoAlmacenEscritura;
      const ANumero: string);
    procedure CrearParametros(AProcedimiento: TUniStoredProc);
  public
    constructor Create(AConexion: TUniConnection);
    procedure Guardar(const AMovimiento: TMovimientoAlmacenEscritura);
  end;

constructor TLectorMovimientosAlmacenUniDAC.Create(
  AConsulta: TUniQuery;
  const AContexto: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion);
begin
  inherited Create;
  if not Assigned(AConsulta) then
    raise EArgumentNilException.Create('AConsulta');
  FConsulta := AConsulta;
  FEmpresaRestringida := EmpresaRestringida(AContexto, AParametros);
  FAlmacenRestringido := AlmacenRestringido(AContexto, AParametros);
end;

function TLectorMovimientosAlmacenUniDAC.ConstruirWhere: string;
var
  I: Integer;
begin
  Result := ' WHERE 1 = 1';
  if Length(FFiltro.Anyos) > 0 then
  begin
    Result := Result + ' AND YEAR(m.FECHA_MOV) IN (';
    for I := 0 to Length(FFiltro.Anyos) - 1 do
    begin
      if I > 0 then
        Result := Result + ', ';
      Result := Result + ':ANYO_' + IntToStr(I);
    end;
    Result := Result + ')';
  end;
  if Length(FFiltro.Almacenes) > 0 then
  begin
    Result := Result + ' AND m.CODIGO_ALM_MOV IN (';
    for I := 0 to Length(FFiltro.Almacenes) - 1 do
    begin
      if I > 0 then
        Result := Result + ', ';
      Result := Result + ':ALMACEN_' + IntToStr(I);
    end;
    Result := Result + ')';
  end;
  if FEmpresaRestringida <> '' then
    Result := Result +
      ' AND (m.CODIGO_EMP_MOV = :EMPRESA_R OR m.CODIGO_EMP_MOV IS NULL)';
  if FAlmacenRestringido <> '' then
    Result := Result +
      ' AND (m.CODIGO_ALM_MOV = :ALMACEN_R OR m.CODIGO_ALM_MOV IS NULL)';
end;

procedure TLectorMovimientosAlmacenUniDAC.AsignarParametros(
  AConsulta: TUniQuery);
var
  I: Integer;
begin
  for I := 0 to Length(FFiltro.Anyos) - 1 do
    AConsulta.ParamByName('ANYO_' + IntToStr(I)).AsInteger :=
      FFiltro.Anyos[I];
  for I := 0 to Length(FFiltro.Almacenes) - 1 do
    AConsulta.ParamByName('ALMACEN_' + IntToStr(I)).AsString :=
      FFiltro.Almacenes[I];
  if FEmpresaRestringida <> '' then
    AConsulta.ParamByName('EMPRESA_R').AsString := FEmpresaRestringida;
  if FAlmacenRestringido <> '' then
    AConsulta.ParamByName('ALMACEN_R').AsString := FAlmacenRestringido;
end;

function TLectorMovimientosAlmacenUniDAC.ObtenerAnyos: TArray<Integer>;
var
  Consulta: TUniQuery;
begin
  Result := nil;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConsulta.Connection;
    Consulta.SQL.Text :=
      'SELECT DISTINCT YEAR(FECHA_MOV) AS ANYO ' +
      'FROM fza_movimientos_almacen ' +
      'WHERE FECHA_MOV IS NOT NULL ' +
      'ORDER BY ANYO DESC';
    Consulta.Open;
    while not Consulta.Eof do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Consulta.FieldByName('ANYO').AsInteger;
      Consulta.Next;
    end;
  finally
    Consulta.Free;
  end;
end;

function TLectorMovimientosAlmacenUniDAC.ObtenerAlmacenes:
  TArray<TAlmacenFiltroMovimiento>;
var
  Consulta: TUniQuery;
begin
  Result := nil;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConsulta.Connection;
    Consulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      'FROM fza_almacenes ' +
      'WHERE ESACTIVO_ALM = ''S'' ';
    if FEmpresaRestringida <> '' then
      Consulta.SQL.Add('AND CODIGO_EMP_ALM = :EMPRESA ');
    if FAlmacenRestringido <> '' then
      Consulta.SQL.Add('AND CODIGO_ALM_ALM = :ALMACEN ');
    Consulta.SQL.Add('ORDER BY ORDEN_ALM, CODIGO_ALM_ALM');
    if FEmpresaRestringida <> '' then
      Consulta.ParamByName('EMPRESA').AsString := FEmpresaRestringida;
    if FAlmacenRestringido <> '' then
      Consulta.ParamByName('ALMACEN').AsString := FAlmacenRestringido;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].Codigo :=
        Consulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[High(Result)].Nombre :=
        Consulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Consulta.Next;
    end;
  finally
    Consulta.Free;
  end;
end;

procedure TLectorMovimientosAlmacenUniDAC.Preparar(
  const AFiltro: TFiltroMovimientosAlmacen);
begin
  FFiltro := AFiltro;
  FConsulta.Close;
  FConsulta.SQL.Text :=
    'SELECT m.*, a.TIPO_CANTIDAD_ART ' +
    'FROM fza_movimientos_almacen m ' +
    'LEFT JOIN fza_articulos a ' +
    'ON a.CODIGO_ART_ART = m.CODIGO_ART_MOV' +
    ConstruirWhere +
    ' ORDER BY m.FECHA_MOV DESC';
  AsignarParametros(FConsulta);
end;

function TLectorMovimientosAlmacenUniDAC.Contar: Integer;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConsulta.Connection;
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM fza_movimientos_almacen m' +
      ConstruirWhere;
    AsignarParametros(Consulta);
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.Fields[0].AsInteger;
  finally
    Consulta.Free;
  end;
end;

procedure TLectorMovimientosAlmacenUniDAC.IniciarCarga(
  ATamanoBloque: Integer);
begin
  FConsulta.DisableControls;
  FControlesDeshabilitados := True;
  try
    FConsulta.Close;
    FConsulta.FetchRows := ATamanoBloque;
    FConsulta.Open;
    FConsulta.First;
  except
    FConsulta.EnableControls;
    FControlesDeshabilitados := False;
    raise;
  end;
end;

function TLectorMovimientosAlmacenUniDAC.HayMovimiento: Boolean;
begin
  Result := not FConsulta.Eof;
end;

procedure TLectorMovimientosAlmacenUniDAC.Siguiente;
begin
  FConsulta.Next;
end;

procedure TLectorMovimientosAlmacenUniDAC.FinalizarCarga;
begin
  if FConsulta.Active then
    FConsulta.First;
  if FControlesDeshabilitados then
  begin
    FConsulta.EnableControls;
    FControlesDeshabilitados := False;
  end;
end;

constructor TUnidadTrabajoMovimientosAlmacenUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

procedure TUnidadTrabajoMovimientosAlmacenUniDAC.Iniciar;
begin
  if FIniciada then
    raise EInvalidOpException.Create(
      'La unidad de trabajo de movimientos ya está iniciada');
  FPropietaria := not FConexion.InTransaction;
  if FPropietaria then
    FConexion.StartTransaction
  else
    FConexion.ExecSQL('SAVEPOINT ' + NOMBRE_SAVEPOINT_MOVIMIENTOS);
  FIniciada := True;
end;

procedure TUnidadTrabajoMovimientosAlmacenUniDAC.Confirmar;
var
  EsPropietaria: Boolean;
begin
  if not FIniciada then
    raise EInvalidOpException.Create(
      'La unidad de trabajo de movimientos no está iniciada');
  EsPropietaria := FPropietaria;
  if EsPropietaria then
    FConexion.Commit
  else
    FConexion.ExecSQL('RELEASE SAVEPOINT ' + NOMBRE_SAVEPOINT_MOVIMIENTOS);
  FIniciada := False;
  FPropietaria := False;
  if EsPropietaria then
    SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoMovimientosAlmacenUniDAC.Revertir;
begin
  if FIniciada then
  begin
    if FPropietaria and FConexion.InTransaction then
      FConexion.Rollback
    else if FConexion.InTransaction then
    begin
      FConexion.ExecSQL(
        'ROLLBACK TO SAVEPOINT ' + NOMBRE_SAVEPOINT_MOVIMIENTOS);
      FConexion.ExecSQL(
        'RELEASE SAVEPOINT ' + NOMBRE_SAVEPOINT_MOVIMIENTOS);
    end;
    FIniciada := False;
    FPropietaria := False;
  end;
end;

constructor TEscritorMovimientosAlmacenUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

procedure TEscritorMovimientosAlmacenUniDAC.CrearParametros(
  AProcedimiento: TUniStoredProc);
begin
  AProcedimiento.Params.Clear;
  AProcedimiento.Params.CreateParam(ftString, 'p_NUMERO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_TIPO_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_SERIE_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_NRO_DOC_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_LINEA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_EMPRESA_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_ALMACEN_MOV', ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_ALMACEN_CONTRA_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODIGO_UNIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_TIPO_MOVIMIENTO_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_CANTIDAD_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_PRECIO_MEDIO_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftBCD, 'p_TOTAL_COSTE_MOV', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_ALMACEN_DOC', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_NUMOP_DOC', ptInput);
  AProcedimiento.Params.CreateParam(
    ftString,
    'p_CODIGO_CAJA_DOC_MOV',
    ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODCLIENTE', ptInput);
  AProcedimiento.Params.CreateParam(ftString, 'p_CODARTICULO', ptInput);
end;

procedure TEscritorMovimientosAlmacenUniDAC.AsignarParametros(
  AProcedimiento: TUniStoredProc;
  const AMovimiento: TMovimientoAlmacenEscritura;
  const ANumero: string);
begin
  AProcedimiento.ParamByName('p_NUMERO_MOV').AsString := ANumero;
  AProcedimiento.ParamByName('p_TIPO_DOC_MOV').AsString :=
    AMovimiento.TipoDocumento;
  AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString :=
    AMovimiento.SerieDocumento;
  AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString :=
    AMovimiento.NumeroDocumento;
  AProcedimiento.ParamByName('p_LINEA_MOV').AsString := AMovimiento.Linea;
  AProcedimiento.ParamByName('p_CODIGO_EMPRESA_MOV').AsString :=
    AMovimiento.Empresa;
  AProcedimiento.ParamByName('p_CODIGO_ALMACEN_MOV').AsString :=
    AMovimiento.Almacen;
  if AMovimiento.AlmacenContrapartida = '' then
    AProcedimiento.ParamByName('p_CODIGO_ALMACEN_CONTRA_MOV').Clear
  else
    AProcedimiento.ParamByName(
      'p_CODIGO_ALMACEN_CONTRA_MOV').AsString :=
      AMovimiento.AlmacenContrapartida;
  AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString :=
    AMovimiento.Unidad;
  AProcedimiento.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString :=
    AMovimiento.TipoMovimiento;
  AProcedimiento.ParamByName('p_CANTIDAD_MOV').AsFloat :=
    Abs(AMovimiento.Cantidad);
  AProcedimiento.ParamByName('p_PRECIO_MEDIO_MOV').AsCurrency :=
    AMovimiento.CosteUnitario;
  AProcedimiento.ParamByName('p_TOTAL_COSTE_MOV').AsCurrency :=
    AMovimiento.CosteUnitario * Abs(AMovimiento.Cantidad);
  AProcedimiento.ParamByName('p_USUARIO').AsString := AMovimiento.Usuario;
  AProcedimiento.ParamByName('p_ALMACEN_DOC').AsString := AMovimiento.Almacen;
  AProcedimiento.ParamByName('p_NUMOP_DOC').AsString := '';
  AProcedimiento.ParamByName('p_CODIGO_CAJA_DOC_MOV').AsString := '';
  AProcedimiento.ParamByName('p_CODCLIENTE').AsString := '';
  AProcedimiento.ParamByName('p_CODARTICULO').AsString :=
    AMovimiento.Articulo;
end;

procedure TEscritorMovimientosAlmacenUniDAC.Guardar(
  const AMovimiento: TMovimientoAlmacenEscritura);
var
  ConsultaFecha: TUniQuery;
  Numero: string;
  Procedimiento: TUniStoredProc;
begin
  if AMovimiento.Cantidad = 0 then
    raise EArgumentException.Create(
      'Un movimiento de almacén no puede tener cantidad cero');
  Numero := Trim(AMovimiento.Numero);
  if Numero = '' then
    Numero := ObtenerSiguienteContador(
      FConexion,
      'MV',
      AMovimiento.Usuario);
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName :=
      'PRC_FZA_MOVIMIENTOS_ALMACEN_INSERT';
    CrearParametros(Procedimiento);
    AsignarParametros(Procedimiento, AMovimiento, Numero);
    Procedimiento.ExecProc;
  finally
    Procedimiento.Free;
  end;
  if AMovimiento.Fecha <> 0 then
  begin
    ConsultaFecha := TUniQuery.Create(nil);
    try
      ConsultaFecha.Connection := FConexion;
      ConsultaFecha.SQL.Text :=
        'UPDATE fza_movimientos_almacen ' +
        'SET FECHA_MOV = :FECHA ' +
        'WHERE NUMERO_MOV = :NUMERO';
      ConsultaFecha.ParamByName('FECHA').AsDateTime := AMovimiento.Fecha;
      ConsultaFecha.ParamByName('NUMERO').AsString := Numero;
      ConsultaFecha.ExecSQL;
    finally
      ConsultaFecha.Free;
    end;
  end;
  RecalcularMovimiento(FConexion, Numero);
end;

function CrearLectorMovimientosAlmacenUniDAC(
  AConsulta: TUniQuery;
  const AContexto: IContextoSesionAplicacion;
  const AParametros: IParametrosAplicacion): ILectorMovimientosAlmacen;
begin
  Result := TLectorMovimientosAlmacenUniDAC.Create(
    AConsulta,
    AContexto,
    AParametros);
end;

procedure CrearEscrituraMovimientosAlmacenUniDAC(
  AConexion: TUniConnection;
  out AEscritor: IEscritorMovimientosAlmacen;
  out AUnidadTrabajo: IUnidadTrabajoMovimientosAlmacen);
begin
  AEscritor := TEscritorMovimientosAlmacenUniDAC.Create(AConexion);
  AUnidadTrabajo :=
    TUnidadTrabajoMovimientosAlmacenUniDAC.Create(AConexion);
end;

end.
