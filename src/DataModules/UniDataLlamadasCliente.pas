{ Persistencia de llamadas de clientes y del proyecto de consultoría. }
unit UniDataLlamadasCliente;

interface

uses
  System.Classes, Data.DB, Uni, inLibPermisosIntf;

const
  PermisoConsultarLlamadas = 'menu.mnuLlamadasCliente';
  PermisoEditarProyecto = 'menu.mnuDisenadorLlamadas';

type
  TDatosLlamada = record
    Cliente, Telefono, Motivo, Resultado: string;
    Fecha, Seguimiento: TDateTime;
  end;

  TRepositorioLlamadas = class
  private
    FConexion: TUniConnection;
    FPermisos: IPermisosAplicacion;
    FUsuario, FCliente: string;
    function Consulta(const ASql: string): TUniQuery;
    procedure Exigir(const ACodigo: string);
  public
    constructor Create(AConexion: TUniConnection;
      const APermisos: IPermisosAplicacion; const AUsuario, ACliente: string);
    function AbrirListado(ASoloSeguimiento: Boolean = False): TUniQuery;
    procedure Guardar(AId: Int64; AVersion: Integer;
      const ADatos: TDatosLlamada);
    procedure Borrar(AId: Int64; AVersion: Integer);
    function LeerProyecto(out AVersion: Integer): string;
    procedure Publicar(const AContenido: string; AVersion: Integer);
    procedure ExigirEditor;
    function Permitido(const ACodigo: string): Boolean;
    property Cliente: string read FCliente;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SPermiso = 'Falta el permiso %s.';
  SDatos = 'Indique un cliente, una fecha y un motivo válidos.';
  SCliente = 'El cliente indicado no existe o pertenece a otra ficha.';
  SConflicto = 'La llamada ha cambiado. Actualice la lista y vuelva a abrirla.';
  SConflictoProyecto = 'Otro operario ha publicado una versión más reciente.';

constructor TRepositorioLlamadas.Create(AConexion: TUniConnection;
  const APermisos: IPermisosAplicacion; const AUsuario, ACliente: string);
begin
  inherited Create;
  FConexion := AConexion;
  FPermisos := APermisos;
  FUsuario := AUsuario;
  FCliente := ACliente;
  Exigir(PermisoConsultarLlamadas);
end;

function TRepositorioLlamadas.Permitido(const ACodigo: string): Boolean;
begin
  Result := Assigned(FPermisos) and
    FPermisos.TienePermiso(ACodigo, paExigirConcesion);
end;

procedure TRepositorioLlamadas.Exigir(const ACodigo: string);
begin
  if not Permitido(ACodigo) then
    raise EInvalidOpException.CreateFmt(SPermiso, [ACodigo]);
end;

procedure TRepositorioLlamadas.ExigirEditor;
begin
  Exigir(PermisoEditarProyecto);
end;

function TRepositorioLlamadas.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TRepositorioLlamadas.AbrirListado(ASoloSeguimiento: Boolean): TUniQuery;
var
  oConsulta: TUniQuery;
begin
  Exigir(PermisoConsultarLlamadas);
  oConsulta := Consulta('SELECT L.ID_CLLAM,L.VERSION_CLLAM,' +
    ' L.CODIGO_CLI_CLLAM,C.RAZON_SOCIAL_CLI,L.FECHA_CLLAM,' +
    ' L.TELEFONO_CLLAM,L.MOTIVO_CLLAM,L.RESULTADO_CLLAM,' +
    ' L.SEGUIMIENTO_CLLAM FROM fza_clientes_llamadas L' +
    ' LEFT JOIN fza_clientes C ON C.CODIGO_CLI_CLI=' +
    'L.CODIGO_CLI_CLLAM COLLATE utf8mb4_spanish_ci WHERE 1=1');
  try
    if FCliente <> '' then
    begin
      oConsulta.SQL.Add('AND L.CODIGO_CLI_CLLAM=:CLI');
      oConsulta.ParamByName('CLI').AsString := FCliente;
    end;
    if ASoloSeguimiento then
      oConsulta.SQL.Add('AND L.SEGUIMIENTO_CLLAM IS NOT NULL ' +
        'ORDER BY L.SEGUIMIENTO_CLLAM, L.FECHA_CLLAM, L.ID_CLLAM')
    else
      oConsulta.SQL.Add('ORDER BY L.FECHA_CLLAM DESC,L.ID_CLLAM DESC');
    oConsulta.ReadOnly := True;
    oConsulta.Open;
    Result := oConsulta;
  except
    oConsulta.Free;
    raise;
  end;
end;

procedure TRepositorioLlamadas.Guardar(AId: Int64; AVersion: Integer;
  const ADatos: TDatosLlamada);
var
  oConsulta: TUniQuery;
begin
  Exigir(PermisoConsultarLlamadas);
  if AId = 0 then
    Exigir('Llamadas.insertar')
  else
    Exigir('Llamadas.modificar');
  if (Trim(ADatos.Cliente) = '') or (Trim(ADatos.Motivo) = '') or
     (ADatos.Fecha <= 0) or (Length(ADatos.Motivo) > 255) or
     (Length(ADatos.Cliente) > 20) or (Length(ADatos.Telefono) > 40) or
     (Length(ADatos.Resultado) > 500) then
    raise EArgumentException.Create(SDatos);
  if (FCliente <> '') and not SameText(FCliente, ADatos.Cliente) then
    raise EArgumentException.Create(SCliente);
  if AId = 0 then
    oConsulta := Consulta('INSERT INTO fza_clientes_llamadas' +
      ' (CODIGO_CLI_CLLAM,FECHA_CLLAM,TELEFONO_CLLAM,MOTIVO_CLLAM,' +
      ' RESULTADO_CLLAM,SEGUIMIENTO_CLLAM,INSTANTE_ALTA,USUARIO_ALTA)' +
      ' SELECT CODIGO_CLI_CLI,:FECHA,:TEL,:MOT,:RES,:SEG,NOW(),:USR' +
      ' FROM fza_clientes WHERE CODIGO_CLI_CLI=:CLI')
  else
    oConsulta := Consulta('UPDATE fza_clientes_llamadas SET' +
      ' FECHA_CLLAM=:FECHA,TELEFONO_CLLAM=:TEL,MOTIVO_CLLAM=:MOT,' +
      ' RESULTADO_CLLAM=:RES,SEGUIMIENTO_CLLAM=:SEG,USUARIO_MODIF=:USR,' +
      ' INSTANTE_MODIF=NOW(),VERSION_CLLAM=VERSION_CLLAM+1' +
      ' WHERE ID_CLLAM=:ID AND VERSION_CLLAM=:VER AND CODIGO_CLI_CLLAM=:CLI');
  try
    oConsulta.ParamByName('CLI').AsString := Trim(ADatos.Cliente);
    oConsulta.ParamByName('FECHA').AsDateTime := ADatos.Fecha;
    oConsulta.ParamByName('TEL').AsString := Trim(ADatos.Telefono);
    oConsulta.ParamByName('MOT').AsString := Trim(ADatos.Motivo);
    oConsulta.ParamByName('RES').AsString := Trim(ADatos.Resultado);
    oConsulta.ParamByName('SEG').DataType := ftDate;
    if ADatos.Seguimiento > 0 then
      oConsulta.ParamByName('SEG').AsDate := ADatos.Seguimiento
    else
      oConsulta.ParamByName('SEG').Clear;
    oConsulta.ParamByName('USR').AsString := FUsuario;
    if AId <> 0 then
    begin
      oConsulta.ParamByName('ID').AsLargeInt := AId;
      oConsulta.ParamByName('VER').AsInteger := AVersion;
    end;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      if AId = 0 then
        raise EArgumentException.Create(SCliente)
      else
        raise EInvalidOpException.Create(SConflicto);
  finally
    oConsulta.Free;
  end;
end;

procedure TRepositorioLlamadas.Borrar(AId: Int64; AVersion: Integer);
var
  oConsulta: TUniQuery;
begin
  Exigir(PermisoConsultarLlamadas);
  Exigir('Llamadas.borrar');
  oConsulta := Consulta('DELETE FROM fza_clientes_llamadas' +
    ' WHERE ID_CLLAM=:ID AND VERSION_CLLAM=:VER');
  try
    if FCliente <> '' then
    begin
      oConsulta.SQL.Add('AND CODIGO_CLI_CLLAM=:CLI');
      oConsulta.ParamByName('CLI').AsString := FCliente;
    end;
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ParamByName('VER').AsInteger := AVersion;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EInvalidOpException.Create(SConflicto);
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioLlamadas.LeerProyecto(out AVersion: Integer): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT CONTENIDO_CPROY,VERSION_CPROY' +
    ' FROM fza_consultoria_proyectos WHERE CODIGO_CPROY=''Llamadas''');
  try
    oConsulta.Open;
    AVersion := oConsulta.FieldByName('VERSION_CPROY').AsInteger;
    Result := oConsulta.FieldByName('CONTENIDO_CPROY').AsString;
  finally
    oConsulta.Free;
  end;
end;

procedure TRepositorioLlamadas.Publicar(const AContenido: string;
  AVersion: Integer);
var
  oConsulta: TUniQuery;
begin
  ExigirEditor;
  if AVersion = 0 then
    oConsulta := Consulta('INSERT INTO fza_consultoria_proyectos' +
      ' (CODIGO_CPROY,CONTENIDO_CPROY,VERSION_CPROY,' +
      ' INSTANTE_ALTA,USUARIO_ALTA) VALUES (''Llamadas'',:TXT,1,NOW(),:USR)')
  else
    oConsulta := Consulta('UPDATE fza_consultoria_proyectos SET' +
      ' CONTENIDO_CPROY=:TXT,VERSION_CPROY=VERSION_CPROY+1,' +
      ' USUARIO_MODIF=:USR,INSTANTE_MODIF=NOW()' +
      ' WHERE CODIGO_CPROY=''Llamadas'' AND VERSION_CPROY=:VER');
  try
    oConsulta.ParamByName('TXT').AsMemo := AContenido;
    oConsulta.ParamByName('USR').AsString := FUsuario;
    if AVersion <> 0 then
      oConsulta.ParamByName('VER').AsInteger := AVersion;
    oConsulta.ExecSQL;
    if oConsulta.RowsAffected <> 1 then
      raise EInvalidOpException.Create(SConflictoProyecto);
  finally
    oConsulta.Free;
  end;
end;

end.
