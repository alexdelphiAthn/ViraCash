{ Persistencia de reasignaciones y repeticiones. TRJ-004, 02/11/2026. }
unit UniDataCambiosTrabajo;

interface

uses
  Uni, UniDataReparacionesCircuitoBase, inLibCambiosTrabajo,
  inLibPermisosIntf;

const
  SQL_REVISION_TRABAJO =
    'MD5(CONCAT_WS(''|'',L.ID_GARLIN,L.ID_GAR_GARLIN,' +
    'L.TIPO_LINEA_GARLIN,L.DESCRIPCION_GARLIN,' +
    'L.TIPO_EJECUTOR_GARLIN,COALESCE(L.CODIGO_EMPL_GARLIN,''''),' +
    'COALESCE(L.CODIGO_PRV_GARLIN,''''),L.CANTIDAD_GARLIN,' +
    'L.PRECIO_COSTE_GARLIN,L.PRECIO_CLIENTE_GARLIN,' +
    'COALESCE(L.FECHA_INICIO_GARLIN,''''),' +
    'COALESCE(L.FECHA_FIN_GARLIN,''''),' +
    'COALESCE(L.ID_GARLIQ_GARLIN,0),' +
    'COALESCE(L.ID_GARLIQ_CARGO_GARLIN,0),' +
    'COALESCE(L.INSTANTE_MODIF,'''')))';

type
  TRepositorioCambiosTrabajo = class(TRepositorioCircuitoOrden)
  private
    FPermisos: IPermisosAplicacion;
    procedure ExigirEjecutor(const ACambio: TCambioTrabajo);
    procedure ExigirSinPendientes(const ACambio: TCambioTrabajo);
    function LeerOriginal(const ACambio: TCambioTrabajo): TUniQuery;
    function Reintento(const ACambio: TCambioTrabajo): Int64;
    function Aplicar(const ACambio: TCambioTrabajo;
      AOriginal: TUniQuery): Int64;
    function CrearTramo(const ACambio: TCambioTrabajo): Int64;
    procedure Registrar(const ACambio: TCambioTrabajo;
      AOriginal: TUniQuery; ADestino: Int64);
  public
    constructor Create(AConexion: TUniConnection;
      const AUsuario: string; const APermisos: IPermisosAplicacion);
    function Guardar(const ACambio: TCambioTrabajo): Int64;
  end;

implementation

uses
  System.SysUtils, Data.DB, UniDataReparacionesProteccion,
  UniDataReparacionesFases, inLibReparacionesFases;

constructor TRepositorioCambiosTrabajo.Create(AConexion: TUniConnection;
  const AUsuario: string; const APermisos: IPermisosAplicacion);
begin
  inherited Create(AConexion, AUsuario);
  FPermisos := APermisos;
end;

procedure TRepositorioCambiosTrabajo.ExigirEjecutor(
  const ACambio: TCambioTrabajo);
var
  oConsulta: TUniQuery;
  sSql: string;
begin
  sSql := 'SELECT CODIGO_EMPL FROM fza_empleados ' +
    'WHERE CODIGO_EMPL=:CODIGO AND ESACTIVO_EMPL=''S''';
  if ACambio.TipoEjecutor = 'EXTERNO' then
    sSql := 'SELECT CODIGO_PRV_PRV FROM fza_proveedores ' +
      'WHERE CODIGO_PRV_PRV=:CODIGO AND ESACTIVO_PRV=''S''';
  oConsulta := Consulta(sSql);
  try
    oConsulta.ParamByName('CODIGO').AsString := ACambio.Ejecutor;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EArgumentException.Create(SCambioTrabajoEjecutor);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCambiosTrabajo.ExigirSinPendientes(
  const ACambio: TCambioTrabajo);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('SELECT ID_RCT FROM fza_reparaciones_tiempos ' +
    'WHERE ID_GARLIN_RCT=:LINEA AND ESANULADO_RCT=''N'' ' +
    'AND INSTANTE_FIN_RCT IS NULL UNION ALL SELECT ID_RCE ' +
    'FROM fza_reparaciones_entregas WHERE ID_GARLIN_RCE=:LINEA ' +
    'AND CANTIDAD_ENVIADA_RCE>CANTIDAD_RECIBIDA_RCE LIMIT 1');
  try
    oConsulta.ParamByName('LINEA').AsLargeInt := ACambio.Linea;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EArgumentException.Create(SCambioTrabajoPendiente);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCambiosTrabajo.LeerOriginal(
  const ACambio: TCambioTrabajo): TUniQuery;
begin
  Result := Consulta('SELECT L.*,' + SQL_REVISION_TRABAJO +
    ' AS REVISION FROM fza_garantias_lineas L ' +
    'WHERE L.ID_GARLIN=:LINEA AND L.ID_GAR_GARLIN=:ORDEN FOR UPDATE');
  try
    Result.ParamByName('LINEA').AsLargeInt := ACambio.Linea;
    Result.ParamByName('ORDEN').AsLargeInt := ACambio.Orden;
    Result.Open;
    if Result.IsEmpty or
       (Result.FieldByName('REVISION').AsString <> ACambio.Revision) or
       (Result.FieldByName('TIPO_LINEA_GARLIN').AsString <> 'MANO_OBRA') then
      raise EArgumentException.Create(SCambioTrabajoConflicto);
    if ACambio.Repetir = Result.FieldByName('FECHA_FIN_GARLIN').IsNull then
      raise EArgumentException.Create(SCambioTrabajoEstado);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TRepositorioCambiosTrabajo.Reintento(
  const ACambio: TCambioTrabajo): Int64;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := Consulta('SELECT * FROM fza_reparaciones_cambios_trabajo ' +
    'WHERE ID_RCTRA=:ID FOR UPDATE');
  try
    oConsulta.ParamByName('ID').AsString := ACambio.Id;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      if (oConsulta.FieldByName('ID_GAR_RCTRA').AsLargeInt <> ACambio.Orden) or
         (oConsulta.FieldByName('ID_ORIGEN_RCTRA').AsLargeInt <>
          ACambio.Linea) or
         (oConsulta.FieldByName('REVISION_RCTRA').AsString <>
          ACambio.Revision) or
         (oConsulta.FieldByName('MOTIVO_RCTRA').AsString <> ACambio.Motivo) or
         (oConsulta.FieldByName('TIPO_NUEVO_RCTRA').AsString <>
          ACambio.TipoEjecutor) or
         (oConsulta.FieldByName('EJECUTOR_NUEVO_RCTRA').AsString <>
          ACambio.Ejecutor) or
         (oConsulta.FieldByName('CANTIDAD_RCTRA').AsCurrency <>
          ACambio.Cantidad) or
         (oConsulta.FieldByName('COSTE_ADICIONAL_RCTRA').AsCurrency <>
          ACambio.CosteAdicional) or
         (oConsulta.FieldByName('RESPONSABLE_COSTE_RCTRA').AsString <>
          ACambio.ResponsableCoste) or
         ((oConsulta.FieldByName('ESREPETICION_RCTRA').AsString = 'S') <>
          ACambio.Repetir) then
        raise EArgumentException.Create(SCambioTrabajoConflicto);
      Result := oConsulta.FieldByName('ID_DESTINO_RCTRA').AsLargeInt;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCambiosTrabajo.CrearTramo(
  const ACambio: TCambioTrabajo): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_garantias_lineas ' +
    '(ID_GAR_GARLIN,LINEA_GARLIN,TIPO_LINEA_GARLIN,CODIGO_GARTIP_GARLIN,' +
    'DESCRIPCION_GARLIN,TIPO_EJECUTOR_GARLIN,CODIGO_EMPL_GARLIN,' +
    'CODIGO_PRV_GARLIN,CANTIDAD_GARLIN,PRECIO_CLIENTE_GARLIN,' +
    'PRECIO_COSTE_GARLIN,INSTANTE_ALTA,USUARIO_ALTA) ' +
    'SELECT ID_GAR_GARLIN,(SELECT MAX(N.LINEA_GARLIN)+1 ' +
    'FROM fza_garantias_lineas N WHERE N.ID_GAR_GARLIN=:ORDEN),' +
    '''MANO_OBRA'',CODIGO_GARTIP_GARLIN,DESCRIPCION_GARLIN,' +
    ':TIPO,IF(:TIPO=''OPERARIO'',:EJECUTOR,NULL),' +
    'IF(:TIPO=''EXTERNO'',:EJECUTOR,NULL),:CANTIDAD,0,:COSTE/:CANTIDAD,' +
    'NOW(6),:USUARIO FROM fza_garantias_lineas WHERE ID_GARLIN=:LINEA');
  try
    oConsulta.ParamByName('ORDEN').AsLargeInt := ACambio.Orden;
    oConsulta.ParamByName('LINEA').AsLargeInt := ACambio.Linea;
    oConsulta.ParamByName('TIPO').AsString := ACambio.TipoEjecutor;
    oConsulta.ParamByName('EJECUTOR').AsString := ACambio.Ejecutor;
    oConsulta.ParamByName('CANTIDAD').AsCurrency := ACambio.Cantidad;
    oConsulta.ParamByName('COSTE').AsCurrency := ACambio.CosteAdicional;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID()';
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCambiosTrabajo.Aplicar(const ACambio: TCambioTrabajo;
  AOriginal: TUniQuery): Int64;
var
  oConsulta: TUniQuery;
begin
  Result := ACambio.Linea;
  if not ACambio.Repetir and
     AOriginal.FieldByName('FECHA_INICIO_GARLIN').IsNull then
  begin
    ExigirLineaOrdenEditable(FConexion, ACambio.Linea, False);
    if (ACambio.CosteAdicional <> 0) or
       (ACambio.Cantidad <>
        AOriginal.FieldByName('CANTIDAD_GARLIN').AsCurrency) then
      raise EArgumentException.Create(SCambioTrabajoCostePrevio);
    oConsulta := Consulta('UPDATE fza_garantias_lineas ' +
      'SET TIPO_EJECUTOR_GARLIN=:TIPO,' +
      'CODIGO_EMPL_GARLIN=IF(:TIPO=''OPERARIO'',:EJECUTOR,NULL),' +
      'CODIGO_PRV_GARLIN=IF(:TIPO=''EXTERNO'',:EJECUTOR,NULL),' +
      'INSTANTE_MODIF=NOW(6),USUARIO_MODIF=:USUARIO WHERE ID_GARLIN=:ID');
    oConsulta.ParamByName('TIPO').AsString := ACambio.TipoEjecutor;
    oConsulta.ParamByName('EJECUTOR').AsString := ACambio.Ejecutor;
  end
  else
  begin
    Result := CrearTramo(ACambio);
    oConsulta := Consulta('UPDATE fza_garantias_lineas ' +
      'SET FECHA_FIN_GARLIN=COALESCE(FECHA_FIN_GARLIN,NOW(6)),' +
      'INSTANTE_MODIF=NOW(6),USUARIO_MODIF=:USUARIO WHERE ID_GARLIN=:ID');
  end;
  try
    oConsulta.ParamByName('ID').AsLargeInt := ACambio.Linea;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioCambiosTrabajo.Registrar(
  const ACambio: TCambioTrabajo; AOriginal: TUniQuery; ADestino: Int64);
var
  oConsulta: TUniQuery;
  sAnterior: string;
begin
  sAnterior := AOriginal.FieldByName('CODIGO_EMPL_GARLIN').AsString;
  if AOriginal.FieldByName('TIPO_EJECUTOR_GARLIN').AsString = 'EXTERNO' then
    sAnterior := AOriginal.FieldByName('CODIGO_PRV_GARLIN').AsString;
  oConsulta := Consulta('INSERT INTO fza_reparaciones_cambios_trabajo ' +
    '(ID_RCTRA,ID_GAR_RCTRA,ID_ORIGEN_RCTRA,ID_DESTINO_RCTRA,' +
    'REVISION_RCTRA,ESREPETICION_RCTRA,MOTIVO_RCTRA,TIPO_ANTERIOR_RCTRA,' +
    'EJECUTOR_ANTERIOR_RCTRA,TIPO_NUEVO_RCTRA,EJECUTOR_NUEVO_RCTRA,' +
    'CANTIDAD_RCTRA,COSTE_ADICIONAL_RCTRA,RESPONSABLE_COSTE_RCTRA,' +
    'INSTANTE_ALTA,USUARIO_ALTA) VALUES (:ID,:ORDEN,:ORIGEN,:DESTINO,' +
    ':REVISION,:REPETIR,:MOTIVO,:TIPO_ANTERIOR,:ANTERIOR,:TIPO,:EJECUTOR,' +
    ':CANTIDAD,:COSTE,:RESPONSABLE,NOW(6),:USUARIO)');
  try
    oConsulta.ParamByName('ID').AsString := ACambio.Id;
    oConsulta.ParamByName('ORDEN').AsLargeInt := ACambio.Orden;
    oConsulta.ParamByName('ORIGEN').AsLargeInt := ACambio.Linea;
    oConsulta.ParamByName('DESTINO').AsLargeInt := ADestino;
    oConsulta.ParamByName('REVISION').AsString := ACambio.Revision;
    oConsulta.ParamByName('REPETIR').AsString := 'N';
    if ACambio.Repetir then
      oConsulta.ParamByName('REPETIR').AsString := 'S';
    oConsulta.ParamByName('MOTIVO').AsString := ACambio.Motivo;
    oConsulta.ParamByName('TIPO_ANTERIOR').AsString :=
      AOriginal.FieldByName('TIPO_EJECUTOR_GARLIN').AsString;
    oConsulta.ParamByName('ANTERIOR').AsString := sAnterior;
    oConsulta.ParamByName('TIPO').AsString := ACambio.TipoEjecutor;
    oConsulta.ParamByName('EJECUTOR').AsString := ACambio.Ejecutor;
    oConsulta.ParamByName('CANTIDAD').AsCurrency := ACambio.Cantidad;
    oConsulta.ParamByName('COSTE').AsCurrency := ACambio.CosteAdicional;
    oConsulta.ParamByName('RESPONSABLE').AsString := ACambio.ResponsableCoste;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.Execute;
    Historial(ACambio.Orden, ACambio.Linea, 'CAMBIO_TRABAJO',
      Format('%d -> %d. %s -> %s. %s', [ACambio.Linea, ADestino,
        sAnterior, ACambio.Ejecutor, ACambio.Motivo]));
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioCambiosTrabajo.Guardar(
  const ACambio: TCambioTrabajo): Int64;
var
  iDestino: Int64;
begin
  ValidarCambioTrabajo(ACambio);
  if (FPermisos = nil) or (Trim(FUsuario) = '') or
     not FPermisos.TienePermiso('reparaciones.cambiarTrabajo',
       paExigirConcesion) then
    raise EInvalidOpException.Create(SCambioTrabajoSinPermiso);
  iDestino := 0;
  Transaccion(
    procedure
    var
      oOriginal: TUniQuery;
      oFases: TDatosFasesReparacion;
      rFase: TCambioFaseReparacion;
    begin
      BloquearOrden(ACambio.Orden, False);
      iDestino := Reintento(ACambio);
      if iDestino = 0 then
      begin
        BloquearOrden(ACambio.Orden);
        oOriginal := LeerOriginal(ACambio);
        try
          ExigirEjecutor(ACambio);
          ExigirSinPendientes(ACambio);
          iDestino := Aplicar(ACambio, oOriginal);
          Registrar(ACambio, oOriginal, iDestino);
          if iDestino <> ACambio.Linea then
          begin
            oFases := TDatosFasesReparacion.CreateDatos(nil, FConexion);
            try
              rFase := Default(TCambioFaseReparacion);
              rFase.Reparacion := ACambio.Orden;
              rFase.Nueva := oFases.LeerParametrosArreglos.FaseEmpezar;
              if rFase.Nueva = '' then
                rFase.Nueva := FASE_PENDIENTE_CLIENTE;
              rFase.Usuario := FUsuario;
              rFase.Observaciones := ACambio.Motivo;
              oFases.Cambiar(rFase);
            finally
              FreeAndNil(oFases);
            end;
          end;
        finally
          FreeAndNil(oOriginal);
        end;
      end;
    end);
  Result := iDestino;
end;

end.
