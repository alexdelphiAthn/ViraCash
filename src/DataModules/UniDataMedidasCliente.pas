{******************************************************************************}
{  Módulo: UniDataMedidasCliente. Fecha: 02/11/2026                            }
{  Descripción: Persistencia de sesiones inmutables y su fotografía por orden. }
{******************************************************************************}
unit UniDataMedidasCliente;

interface

uses
  Uni, inLibMedidasCliente, inLibPermisosIntf;

type
  TRepositorioMedidasCliente = class
  private
    FConexion: TUniConnection;
    FPermisos: IPermisosAplicacion;
    FUsuario: string;
    function Consulta(const ASql: string): TUniQuery;
    procedure ExigirPermiso(const AAccion: string);
    procedure BloquearCliente(const ACliente: string);
    procedure ValidarOrigen(const ASesion: TSesionMedidasCliente);
    procedure InsertarSesion(const ASesion: TSesionMedidasCliente);
    procedure InsertarValor(const AId: string; const AValor: TMedidaCliente);
    function LeerValores(const AId: string): TMedidasCliente;
    function Cabecera(AConsulta: TUniQuery): TSesionMedidasCliente;
  public
    constructor Create(AConexion: TUniConnection;
      const APermisos: IPermisosAplicacion; const AUsuario: string);
    function Disponible: Boolean;
    function Magnitudes: TMagnitudesCliente;
    function Historial(const ACliente: string): TSesionesMedidasCliente;
    function Leer(const ACliente, AId: string): TSesionMedidasCliente;
    procedure Guardar(var ASesion: TSesionMedidasCliente);
    procedure Vincular(AOrden: Int64; const ACliente, AId: string);
    function Fotografia(AOrden: Int64; const ACliente: string): string;
  end;

implementation

uses
  System.SysUtils, Data.DB, inLibMsgMedidasCliente;

constructor TRepositorioMedidasCliente.Create(AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion; const AUsuario: string);
begin
  inherited Create;
  if (AConexion = nil) or (APermisos = nil) or (Trim(AUsuario) = '') then
    raise EArgumentException.Create(SMedidasSinPermiso);
  FConexion := AConexion;
  FPermisos := APermisos;
  FUsuario := AUsuario;
end;

function TRepositorioMedidasCliente.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

procedure TRepositorioMedidasCliente.ExigirPermiso(const AAccion: string);
begin
  if not FPermisos.TienePermiso('clientes.medidas.' + AAccion,
    paExigirConcesion) then
    raise EInvalidOpException.Create(SMedidasSinPermiso);
end;

function TRepositorioMedidasCliente.Disponible: Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES' +
    ' WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN (' +
    '''fza_clientes_medidas'',''fza_clientes_medidas_magnitudes'',' +
    '''fza_clientes_medidas_valores'',''fza_reparaciones_medidas'')');
  try
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsInteger = 4;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioMedidasCliente.Magnitudes: TMagnitudesCliente;
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  ExigirPermiso('consultar');
  Result := nil;
  oConsulta := Consulta('SELECT CODIGO_CMM,NOMBRE_CMM,UNIDAD_CMM,' +
    'VALOR_MINIMO_CMM,VALOR_MAXIMO_CMM FROM fza_clientes_medidas_magnitudes' +
    ' WHERE ESACTIVO_CMM=''S'' ORDER BY ORDEN_CMM,CODIGO_CMM');
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice].Codigo := oConsulta.Fields[0].AsString;
      Result[iIndice].Nombre := oConsulta.Fields[1].AsString;
      Result[iIndice].Unidad := oConsulta.Fields[2].AsString;
      Result[iIndice].Minimo := oConsulta.Fields[3].AsCurrency;
      Result[iIndice].Maximo := oConsulta.Fields[4].AsCurrency;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioMedidasCliente.Cabecera(
  AConsulta: TUniQuery): TSesionMedidasCliente;
begin
  Result := Default(TSesionMedidasCliente);
  Result.Id := AConsulta.FieldByName('ID_CLMED').AsString;
  Result.Cliente := AConsulta.FieldByName('CODIGO_CLI_CLMED').AsString;
  Result.Fecha := AConsulta.FieldByName('FECHA_CLMED').AsDateTime;
  Result.Persona := AConsulta.FieldByName('PERSONA_CLMED').AsString;
  Result.Origen := AConsulta.FieldByName('ID_ORIGEN_CLMED').AsString;
  Result.Motivo := AConsulta.FieldByName('MOTIVO_CLMED').AsString;
  Result.Observaciones :=
    AConsulta.FieldByName('OBSERVACIONES_CLMED').AsString;
  Result.Usuario := AConsulta.FieldByName('USUARIO_ALTA').AsString;
end;

function TRepositorioMedidasCliente.Historial(
  const ACliente: string): TSesionesMedidasCliente;
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  ExigirPermiso('consultar');
  Result := nil;
  oConsulta := Consulta('SELECT ID_CLMED,CODIGO_CLI_CLMED,FECHA_CLMED,' +
    'PERSONA_CLMED,ID_ORIGEN_CLMED,MOTIVO_CLMED,OBSERVACIONES_CLMED,' +
    'USUARIO_ALTA FROM fza_clientes_medidas WHERE CODIGO_CLI_CLMED=:CLI' +
    ' ORDER BY FECHA_CLMED DESC,INSTANTE_ALTA DESC,ID_CLMED DESC');
  try
    oConsulta.ParamByName('CLI').AsString := ACliente;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice] := Cabecera(oConsulta);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioMedidasCliente.LeerValores(
  const AId: string): TMedidasCliente;
var
  oConsulta: TUniQuery;
  iIndice: Integer;
begin
  Result := nil;
  oConsulta := Consulta('SELECT CODIGO_CMM_CMVAL,NOMBRE_CMVAL,' +
    'UNIDAD_CMVAL,VALOR_CMVAL FROM fza_clientes_medidas_valores' +
    ' WHERE ID_CLMED_CMVAL=:ID ORDER BY CODIGO_CMM_CMVAL');
  try
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iIndice := Length(Result);
      SetLength(Result, iIndice + 1);
      Result[iIndice].Codigo := oConsulta.Fields[0].AsString;
      Result[iIndice].Nombre := oConsulta.Fields[1].AsString;
      Result[iIndice].Unidad := oConsulta.Fields[2].AsString;
      Result[iIndice].Conocida := not oConsulta.Fields[3].IsNull;
      Result[iIndice].Valor := oConsulta.Fields[3].AsCurrency;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioMedidasCliente.Leer(const ACliente,
  AId: string): TSesionMedidasCliente;
var
  oConsulta: TUniQuery;
begin
  ExigirPermiso('consultar');
  oConsulta := Consulta('SELECT ID_CLMED,CODIGO_CLI_CLMED,FECHA_CLMED,' +
    'PERSONA_CLMED,ID_ORIGEN_CLMED,MOTIVO_CLMED,OBSERVACIONES_CLMED,' +
    'USUARIO_ALTA FROM fza_clientes_medidas WHERE CODIGO_CLI_CLMED=:CLI' +
    ' AND ID_CLMED=:ID');
  try
    oConsulta.ParamByName('CLI').AsString := ACliente;
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EInvalidOpException.Create(SMedidasSesionInexistente);
    Result := Cabecera(oConsulta);
    Result.Valores := LeerValores(AId);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMedidasCliente.BloquearCliente(const ACliente: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT CODIGO_CLI_CLI FROM fza_clientes' +
    ' WHERE CODIGO_CLI_CLI=:CLI FOR UPDATE');
  try
    oConsulta.ParamByName('CLI').AsString := ACliente;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EInvalidOpException.Create(SMedidasClienteInexistente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMedidasCliente.ValidarOrigen(
  const ASesion: TSesionMedidasCliente);
var
  oConsulta: TUniQuery;
begin
  if ASesion.Origen <> '' then
  begin
    oConsulta := Consulta('SELECT O.ID_CLMED FROM fza_clientes_medidas O' +
      ' WHERE O.ID_CLMED=:ID AND O.CODIGO_CLI_CLMED=:CLI AND NOT EXISTS' +
      ' (SELECT 1 FROM fza_clientes_medidas C' +
      ' WHERE C.ID_ORIGEN_CLMED=O.ID_CLMED) FOR UPDATE');
    try
      oConsulta.ParamByName('ID').AsString := ASesion.Origen;
      oConsulta.ParamByName('CLI').AsString := ASesion.Cliente;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EInvalidOpException.Create(SMedidasOrigenInvalido);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TRepositorioMedidasCliente.InsertarSesion(
  const ASesion: TSesionMedidasCliente);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_clientes_medidas' +
    ' (ID_CLMED,CODIGO_CLI_CLMED,FECHA_CLMED,PERSONA_CLMED,' +
    'ID_ORIGEN_CLMED,MOTIVO_CLMED,OBSERVACIONES_CLMED,' +
    'INSTANTE_ALTA,USUARIO_ALTA)' +
    ' VALUES (:ID,:CLI,:FECHA,:PERSONA,NULLIF(:ORIGEN,''''),' +
    ':MOTIVO,:OBS,NOW(),:USUARIO)');
  try
    oConsulta.ParamByName('ID').AsString := ASesion.Id;
    oConsulta.ParamByName('CLI').AsString := ASesion.Cliente;
    oConsulta.ParamByName('FECHA').AsDate := ASesion.Fecha;
    oConsulta.ParamByName('PERSONA').AsString := ASesion.Persona;
    oConsulta.ParamByName('ORIGEN').AsString := ASesion.Origen;
    oConsulta.ParamByName('MOTIVO').AsString := ASesion.Motivo;
    oConsulta.ParamByName('OBS').AsString := ASesion.Observaciones;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMedidasCliente.InsertarValor(const AId: string;
  const AValor: TMedidaCliente);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_clientes_medidas_valores' +
    ' (ID_CLMED_CMVAL,CODIGO_CMM_CMVAL,NOMBRE_CMVAL,UNIDAD_CMVAL,' +
    'VALOR_CMVAL,INSTANTE_ALTA,USUARIO_ALTA)' +
    ' SELECT :ID,CODIGO_CMM,NOMBRE_CMM,UNIDAD_CMM,:VALOR,NOW(),:USUARIO' +
    ' FROM fza_clientes_medidas_magnitudes WHERE CODIGO_CMM=:CODIGO' +
    ' AND ESACTIVO_CMM=''S''');
  try
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.ParamByName('CODIGO').AsString := AValor.Codigo;
    oConsulta.ParamByName('VALOR').DataType := ftCurrency;
    if AValor.Conocida then
      oConsulta.ParamByName('VALOR').AsCurrency := AValor.Valor
    else
      oConsulta.ParamByName('VALOR').Clear;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EInvalidOpException.Create(SMedidasMagnitudInvalida);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMedidasCliente.Guardar(
  var ASesion: TSesionMedidasCliente);
var
  bPropietario: Boolean;
  rValor: TMedidaCliente;
  sAviso: string;
  rGuid: TGUID;
begin
  ExigirPermiso('alta');
  if ASesion.Origen <> '' then
    ExigirPermiso('corregir');
  sAviso := ValidarSesionMedidas(ASesion, Magnitudes);
  if (sAviso <> '') and not ASesion.AceptaFueraRango then
    raise EArgumentException.Create(SMedidasFueraRango + sLineBreak + sAviso);
  if ASesion.Id = '' then
  begin
    CreateGUID(rGuid);
    ASesion.Id := Copy(GUIDToString(rGuid), 2, 36);
  end;
  bPropietario := not FConexion.InTransaction;
  if bPropietario then
    FConexion.StartTransaction;
  try
    BloquearCliente(ASesion.Cliente);
    ValidarOrigen(ASesion);
    InsertarSesion(ASesion);
    for rValor in ASesion.Valores do
      InsertarValor(ASesion.Id, rValor);
    if bPropietario then
      FConexion.Commit;
  except
    if bPropietario then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TRepositorioMedidasCliente.Vincular(AOrden: Int64;
  const ACliente, AId: string);
var
  oConsulta: TUniQuery;
  rSesion: TSesionMedidasCliente;
begin
  ExigirPermiso('vincular');
  rSesion := Leer(ACliente, AId);
  oConsulta := Consulta('INSERT INTO fza_reparaciones_medidas' +
    ' (ID_GAR_RCMED,ID_CLMED_RCMED,TEXTO_RCMED,INSTANTE_ALTA,USUARIO_ALTA)' +
    ' SELECT ID_GAR,:ID,:TEXTO,NOW(),:USUARIO' +
    ' FROM fza_garantias_reclamaciones WHERE ID_GAR=:ORDEN' +
    ' AND CODIGO_CLI_GAR=:CLI AND ESTADO_GAR=''ABIERTA''');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('CLI').AsString := ACliente;
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.ParamByName('TEXTO').AsString := TextoSesionMedidas(rSesion);
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EInvalidOpException.Create(SMedidasOrdenInvalida);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioMedidasCliente.Fotografia(AOrden: Int64;
  const ACliente: string): string;
var
  oConsulta: TUniQuery;
begin
  ExigirPermiso('consultar');
  oConsulta := Consulta('SELECT M.TEXTO_RCMED' +
    ' FROM fza_reparaciones_medidas M JOIN fza_garantias_reclamaciones G' +
    ' ON G.ID_GAR=M.ID_GAR_RCMED WHERE G.ID_GAR=:ORDEN' +
    ' AND G.CODIGO_CLI_GAR=:CLI');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := AOrden;
    oConsulta.ParamByName('CLI').AsString := ACliente;
    oConsulta.Open;
    Result := '';
    if not oConsulta.IsEmpty then
      Result := oConsulta.Fields[0].AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
