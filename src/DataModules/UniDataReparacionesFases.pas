{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataReparacionesFases                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Catálogo, cambios de fase y registro de los avisos al cliente.            }
{******************************************************************************}
unit UniDataReparacionesFases;

interface

uses
  System.Classes, Data.DB, Uni, inLibReparacionesFases,
  inLibCorreoReparaciones;

type
  TDatosFasesReparacion = class(TComponent)
  private
    FConexion: TUniConnection;
    FHistorial: TUniQuery;
    FOrigen: TDataSource;
    FAvisos: TUniQuery;
    FOrigenAvisos: TDataSource;
    function Consulta(const ASql: string): TUniQuery;
    function Bloquear(AReparacion: Int64): TUniQuery;
    function CambiarBloqueada(const ACambio: TCambioFaseReparacion): Int64;
    function InsertarHistorial(const ACambio: TCambioFaseReparacion;
      const AAnterior, ANueva: string): Int64;
  public
    constructor CreateDatos(AOwner: TComponent; AConexion: TUniConnection);
    procedure AsignarMaestro(AMaestro: TDataSource);
    procedure Refrescar;
    function Catalogo: TArray<TFaseReparacionCatalogo>;
    function LeerParametrosArreglos: TParametrosArreglos;
    procedure GuardarParametrosArreglos(const AParametros: TParametrosArreglos);
    procedure AplicarFaseTrabajo(ALinea: Int64; ATerminado: Boolean;
      const AUsuario: string);
    function Anadir(const ADescripcion, AUsuario: string): string;
    function Cambiar(const ACambio: TCambioFaseReparacion): Int64;
    procedure RegistrarInicial(AReparacion: Int64; const AUsuario: string);
    procedure PrepararEntrega(AReparacion: Int64;
      const AUsuario: string);
    procedure RegistrarEntrega(AReparacion: Int64;
      const AUsuario: string);
    function AvisoSeleccionado: TAvisoFaseReparacion;
    function IniciarAviso(const ACorreo: TCorreoFaseReparacion): string;
    procedure FinalizarAviso(const AId, AEstado, AResultado,
      AUsuario: string);
    property OrigenAvisos: TDataSource read FOrigenAvisos;
    property Origen: TDataSource read FOrigen;
  end;

const
  // G: expediente; se conserva la entrega real como estado final.
  SQL_CODIGO_FASE_ACTUAL =
    'CASE WHEN G.FECHA_ENTREGA_CLI_GAR IS NOT NULL THEN ''ENTREGADO'' ' +
    'WHEN G.CODIGO_GARFA_GAR IS NOT NULL THEN G.CODIGO_GARFA_GAR ' +
    'WHEN G.FECHA_RECEPCION_GAR IS NOT NULL THEN ''EN_TALLER'' ' +
    'ELSE ''EN_RECEPCION'' END';

implementation

uses
  UniDataReparacionesPrendas,
  System.SysUtils, inLibMsgReparaciones, inLibReparaciones,
  inLibGlobalVar, inLibAppParamPersistenciaIntf, UniDataAppParamRepositorio;

function TDatosFasesReparacion.LeerParametrosArreglos: TParametrosArreglos;
var
  Valor: TValorPerfilAppParam;
begin
  Result := Default(TParametrosArreglos);
  for Valor in CrearRepositorioAppParamUniDAC(FConexion).
    CargarValores('', oAll, 'ParametrosArreglos') do
    if Valor.Subclave = 'FaseEmpezar' then
      Result.FaseEmpezar := Valor.Valor
    else if Valor.Subclave = 'FaseTerminar' then
      Result.FaseTerminar := Valor.Valor;
end;

procedure TDatosFasesReparacion.GuardarParametrosArreglos(
  const AParametros: TParametrosArreglos);
var
  Valores: TValoresPerfilAppParam;
  Codigo: string;
  Fase: TFaseReparacionCatalogo;
  bValida, bPropia: Boolean;
begin
  for Codigo in TArray<string>.Create(AParametros.FaseEmpezar,
    AParametros.FaseTerminar) do
  begin
    bValida := Codigo = '';
    for Fase in Catalogo do
      bValida := bValida or ((Fase.Codigo = Codigo) and
        (Codigo <> FASE_ENTREGADA_CLIENTE));
    if not bValida then
      raise EArgumentException.Create(SFaseSeleccionar);
  end;
  SetLength(Valores, 2);
  Valores[0].Subclave := 'FaseEmpezar';
  Valores[0].Valor := AParametros.FaseEmpezar;
  Valores[1].Subclave := 'FaseTerminar';
  Valores[1].Valor := AParametros.FaseTerminar;
  bPropia := not FConexion.InTransaction;
  if bPropia then
    FConexion.StartTransaction;
  try
    CrearRepositorioAppParamUniDAC(FConexion).GuardarValores(oAll,
      'ParametrosArreglos', Valores);
    if bPropia then
      FConexion.Commit;
  except
    if bPropia then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TDatosFasesReparacion.AplicarFaseTrabajo(ALinea: Int64;
  ATerminado: Boolean; const AUsuario: string);
var
  Parametros: TParametrosArreglos;
  Cambio: TCambioFaseReparacion;
  oDatos: TUniQuery;
begin
  Parametros := LeerParametrosArreglos;
  Cambio := Default(TCambioFaseReparacion);
  Cambio.Nueva := Parametros.FaseEmpezar;
  if ATerminado then
    Cambio.Nueva := Parametros.FaseTerminar;
  if Cambio.Nueva <> '' then
  begin
    oDatos := Consulta('SELECT G.ID_GAR, G.CATEGORIA_GAR, ' +
      '(SELECT COUNT(*) FROM fza_garantias_lineas T ' +
      'WHERE T.ID_GAR_GARLIN = G.ID_GAR ' +
      'AND T.TIPO_LINEA_GARLIN = ''' + LINEA_REPARACION_MANO_OBRA + ''' ' +
      'AND T.FECHA_INICIO_GARLIN IS NOT NULL) AS INICIADAS, ' +
      '(SELECT COUNT(*) FROM fza_garantias_lineas T ' +
      'WHERE T.ID_GAR_GARLIN = G.ID_GAR ' +
      'AND T.TIPO_LINEA_GARLIN = ''' + LINEA_REPARACION_MANO_OBRA + ''' ' +
      'AND T.FECHA_FIN_GARLIN IS NULL) AS PENDIENTES ' +
      'FROM fza_garantias_lineas L JOIN fza_garantias_reclamaciones G ' +
      'ON G.ID_GAR = L.ID_GAR_GARLIN WHERE L.ID_GARLIN = :LINEA');
    try
      oDatos.ParamByName('LINEA').AsLargeInt := ALinea;
      oDatos.Open;
      if not oDatos.IsEmpty and
        SameText(Trim(oDatos.FieldByName('CATEGORIA_GAR').AsString),
          'ARREGLOS') and
        (((not ATerminado) and
          (oDatos.FieldByName('INICIADAS').AsInteger = 1)) or
        (ATerminado and
          (oDatos.FieldByName('PENDIENTES').AsInteger = 0))) then
      begin
        Cambio.Reparacion := oDatos.FieldByName('ID_GAR').AsLargeInt;
        Cambio.Usuario := AUsuario;
        Cambio.Observaciones := SParametrosArreglosCambioInicio;
        if ATerminado then
          Cambio.Observaciones := SParametrosArreglosCambioFin;
        Cambiar(Cambio);
      end;
    finally
      FreeAndNil(oDatos);
    end;
  end;
end;

constructor TDatosFasesReparacion.CreateDatos(AOwner: TComponent;
  AConexion: TUniConnection);
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FHistorial := Consulta('SELECT ID_GARHIS, ID_GAR_GARHIS, ' +
    'FASE_ANTERIOR_GARHIS, FASE_GARHIS, INSTANTE_GARHIS, ' +
    'OBSERVACIONES_GARHIS, USUARIO_ALTA ' +
    'FROM fza_garantias_fases_hist WHERE ID_GAR_GARHIS = :ID_GAR ' +
    'ORDER BY ID_GARHIS DESC');
  FHistorial.ReadOnly := True;
  FOrigen := TDataSource.Create(Self);
  FOrigen.DataSet := FHistorial;
  FAvisos := Consulta('SELECT ID_GARAVI, ID_GAR_GARAVI, ' +
    'INSTANTE_ALTA, EMAIL_GARAVI, ASUNTO_GARAVI, TEXTO_GARAVI, ' +
    'ESTADO_GARAVI, ' +
    'RESULTADO_GARAVI, USUARIO_ALTA ' +
    'FROM fza_garantias_fases_avisos WHERE ID_GAR_GARAVI = :ID_GAR ' +
    'ORDER BY INSTANTE_ALTA DESC');
  FAvisos.ReadOnly := True;
  FOrigenAvisos := TDataSource.Create(Self);
  FOrigenAvisos.DataSet := FAvisos;
end;

function TDatosFasesReparacion.Consulta(const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(Self);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

procedure TDatosFasesReparacion.AsignarMaestro(AMaestro: TDataSource);
begin
  FHistorial.MasterSource := AMaestro;
  FHistorial.MasterFields := 'ID_GAR';
  FHistorial.DetailFields := 'ID_GAR_GARHIS';
  FAvisos.MasterSource := AMaestro;
  FAvisos.MasterFields := 'ID_GAR';
  FAvisos.DetailFields := 'ID_GAR_GARAVI';
  FAvisos.Open;
  TDateTimeField(FAvisos.FieldByName('INSTANTE_ALTA')).DisplayFormat :=
    'dd/mm/yyyy hh:nn:ss';
  FHistorial.Open;
  TDateTimeField(FHistorial.FieldByName('INSTANTE_GARHIS')).DisplayFormat :=
    'dd/mm/yyyy hh:nn:ss';
end;

procedure TDatosFasesReparacion.Refrescar;
begin
  if FHistorial.Active then
  begin
    FHistorial.Close;
    FHistorial.Open;
    TDateTimeField(FHistorial.FieldByName('INSTANTE_GARHIS')).DisplayFormat :=
      'dd/mm/yyyy hh:nn:ss';
    FHistorial.First;
  end;
  if FAvisos.Active then
  begin
    FAvisos.Close;
    FAvisos.Open;
    TDateTimeField(FAvisos.FieldByName('INSTANTE_ALTA')).DisplayFormat :=
      'dd/mm/yyyy hh:nn:ss';
  end;
end;

function TDatosFasesReparacion.Catalogo:
  TArray<TFaseReparacionCatalogo>;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := Consulta('SELECT CODIGO_GARFA, DESCRIPCION_GARFA ' +
    'FROM fza_garantias_fases WHERE ESACTIVO_GARFA = ''S'' ' +
    'ORDER BY ORDEN_GARFA, DESCRIPCION_GARFA');
  try
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].Codigo :=
        oConsulta.FieldByName('CODIGO_GARFA').AsString;
      Result[High(Result)].Descripcion :=
        oConsulta.FieldByName('DESCRIPCION_GARFA').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosFasesReparacion.Anadir(const ADescripcion,
  AUsuario: string): string;
var
  oConsulta: TUniQuery;
  rId: TGUID;
begin
  if (Trim(ADescripcion) = '') or (Length(Trim(ADescripcion)) > 120) then
    raise EArgumentException.Create(SFaseNombreInvalido);
  if Trim(AUsuario) = '' then
    raise EArgumentException.Create(SFaseUsuarioObligatorio);
  oConsulta := Consulta('SELECT CODIGO_GARFA FROM fza_garantias_fases ' +
    'WHERE DESCRIPCION_GARFA = :NOMBRE');
  try
    oConsulta.ParamByName('NOMBRE').AsString := Trim(ADescripcion);
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      raise EArgumentException.Create(SFaseDuplicada);
    oConsulta.Close;
    CreateGUID(rId);
    Result := StringReplace(Copy(GUIDToString(rId), 2, 36), '-', '',
      [rfReplaceAll]);
    oConsulta.SQL.Text := 'INSERT INTO fza_garantias_fases ' +
      '(CODIGO_GARFA, DESCRIPCION_GARFA, INSTANTE_ALTA, USUARIO_ALTA) ' +
      'VALUES (:CODIGO, :NOMBRE, NOW(6), :USUARIO)';
    oConsulta.ParamByName('CODIGO').AsString := Result;
    oConsulta.ParamByName('NOMBRE').AsString := Trim(ADescripcion);
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosFasesReparacion.Bloquear(AReparacion: Int64): TUniQuery;
begin
  Result := Consulta('SELECT G.ESTADO_GAR, G.FECHA_ENTREGA_CLI_GAR, ' +
    SQL_CODIGO_FASE_ACTUAL + ' AS CODIGO_ACTUAL, F.DESCRIPCION_GARFA ' +
    'FROM fza_garantias_reclamaciones G JOIN fza_garantias_fases F ' +
    'ON F.CODIGO_GARFA = ' + SQL_CODIGO_FASE_ACTUAL +
    ' WHERE G.ID_GAR = :ID FOR UPDATE');
  try
    Result.ParamByName('ID').AsLargeInt := AReparacion;
    Result.Open;
    if Result.IsEmpty then
      raise EArgumentException.Create(SInfoSinReparacion);
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function TDatosFasesReparacion.InsertarHistorial(
  const ACambio: TCambioFaseReparacion;
  const AAnterior, ANueva: string): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_garantias_fases_hist ' +
    '(ID_GAR_GARHIS, CODIGO_ANTERIOR_GARHIS, FASE_ANTERIOR_GARHIS, ' +
    'CODIGO_GARFA_GARHIS, FASE_GARHIS, INSTANTE_GARHIS, ' +
    'OBSERVACIONES_GARHIS, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (:ID, NULLIF(:ANTERIOR, ''''), NULLIF(:TEXTO_ANTERIOR, ''''), ' +
    ':NUEVA, :TEXTO_NUEVA, NOW(6), :OBSERVACIONES, NOW(6), :USUARIO)');
  try
    oConsulta.ParamByName('ID').AsLargeInt := ACambio.Reparacion;
    oConsulta.ParamByName('ANTERIOR').AsString := ACambio.Anterior;
    oConsulta.ParamByName('TEXTO_ANTERIOR').AsString := AAnterior;
    oConsulta.ParamByName('NUEVA').AsString := ACambio.Nueva;
    oConsulta.ParamByName('TEXTO_NUEVA').AsString := ANueva;
    oConsulta.ParamByName('OBSERVACIONES').AsString := ACambio.Observaciones;
    oConsulta.ParamByName('USUARIO').AsString := Copy(ACambio.Usuario, 1, 50);
    oConsulta.Execute;
    oConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosFasesReparacion.RegistrarInicial(AReparacion: Int64;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := Consulta('INSERT INTO fza_garantias_fases_hist ' +
    '(ID_GAR_GARHIS, CODIGO_GARFA_GARHIS, FASE_GARHIS, INSTANTE_GARHIS, ' +
    'OBSERVACIONES_GARHIS, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT G.ID_GAR, F.CODIGO_GARFA, F.DESCRIPCION_GARFA, NOW(6), ' +
    '''Situación inicial'', NOW(6), :USUARIO ' +
    'FROM fza_garantias_reclamaciones G JOIN fza_garantias_fases F ' +
    'ON F.CODIGO_GARFA = ' + SQL_CODIGO_FASE_ACTUAL +
    ' WHERE G.ID_GAR = :ID AND NOT EXISTS ' +
    '(SELECT 1 FROM fza_garantias_fases_hist H ' +
    'WHERE H.ID_GAR_GARHIS = G.ID_GAR)');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosFasesReparacion.CambiarBloqueada(
  const ACambio: TCambioFaseReparacion): Int64;
var
  oActual, oNueva: TUniQuery;
  sAnterior, sTextoAnterior, sNueva: string;
  rCambio: TCambioFaseReparacion;
begin
  Result := 0;
  oActual := Bloquear(ACambio.Reparacion);
  oNueva := nil;
  try
    sAnterior := oActual.FieldByName('CODIGO_ACTUAL').AsString;
    if (ACambio.Anterior <> '') and (ACambio.Anterior <> sAnterior) then
      raise EArgumentException.Create(SFaseConflicto);
    if (oActual.FieldByName('ESTADO_GAR').AsString = 'ANULADA') or
       ((not oActual.FieldByName('FECHA_ENTREGA_CLI_GAR').IsNull) and
        (ACambio.Nueva <> FASE_ENTREGADA_CLIENTE)) then
      raise EArgumentException.Create(SFaseCerrada);
    if (ACambio.Nueva = FASE_ENTREGADA_CLIENTE) and
       oActual.FieldByName('FECHA_ENTREGA_CLI_GAR').IsNull then
      raise EArgumentException.Create(SFaseUsarEntrega);
    if sAnterior <> ACambio.Nueva then
    begin
      oNueva := Consulta('SELECT DESCRIPCION_GARFA ' +
        'FROM fza_garantias_fases WHERE CODIGO_GARFA = :CODIGO ' +
        'AND ESACTIVO_GARFA = ''S''');
      oNueva.ParamByName('CODIGO').AsString := ACambio.Nueva;
      oNueva.Open;
      if oNueva.IsEmpty then
        raise EArgumentException.Create(SFaseSeleccionar);
      sNueva := oNueva.FieldByName('DESCRIPCION_GARFA').AsString;
      sTextoAnterior := oActual.FieldByName('DESCRIPCION_GARFA').AsString;
      RegistrarInicial(ACambio.Reparacion, ACambio.Usuario);
      oActual.Close;
      oActual.SQL.Text := 'UPDATE fza_garantias_reclamaciones ' +
        'SET CODIGO_GARFA_GAR = :NUEVA, INSTANTE_MODIF = NOW(6), ' +
        'USUARIO_MODIF = :USUARIO WHERE ID_GAR = :ID';
      oActual.ParamByName('NUEVA').AsString := ACambio.Nueva;
      oActual.ParamByName('USUARIO').AsString := Copy(ACambio.Usuario, 1, 50);
      oActual.ParamByName('ID').AsLargeInt := ACambio.Reparacion;
      oActual.Execute;
      rCambio := ACambio;
      rCambio.Anterior := sAnterior;
      Result := InsertarHistorial(rCambio, sTextoAnterior, sNueva);
    end;
  finally
    FreeAndNil(oNueva);
    FreeAndNil(oActual);
  end;
end;

function TDatosFasesReparacion.Cambiar(
  const ACambio: TCambioFaseReparacion): Int64;
var
  bPropia: Boolean;
  sError: string;
begin
  sError := ValidarCambioFase(ACambio);
  if sError <> '' then
    raise EArgumentException.Create(sError);
  bPropia := not FConexion.InTransaction;
  if bPropia then
    FConexion.StartTransaction;
  try
    Result := CambiarBloqueada(ACambio);
    if bPropia then
      FConexion.Commit;
  except
    if bPropia then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TDatosFasesReparacion.PrepararEntrega(AReparacion: Int64;
  const AUsuario: string);
var
  oBloqueo: TUniQuery;
begin
  oBloqueo := Bloquear(AReparacion);
  try
    RegistrarInicial(AReparacion, AUsuario);
  finally
    FreeAndNil(oBloqueo);
  end;
end;

procedure TDatosFasesReparacion.RegistrarEntrega(AReparacion: Int64;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
  rCambio: TCambioFaseReparacion;
  sAnterior: string;
  oPrendas: TDatosPrendasReparacion;
begin
  rCambio := Default(TCambioFaseReparacion);
  rCambio.Reparacion := AReparacion;
  rCambio.Nueva := FASE_ENTREGADA_CLIENTE;
  rCambio.Usuario := AUsuario;
  rCambio.Observaciones := SFaseEntregaRegistrada;
  oConsulta := Consulta('SELECT CODIGO_GARFA_GARHIS, FASE_GARHIS ' +
    'FROM fza_garantias_fases_hist WHERE ID_GAR_GARHIS = :ID ' +
    'ORDER BY ID_GARHIS DESC LIMIT 1');
  try
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.Open;
    rCambio.Anterior :=
      oConsulta.FieldByName('CODIGO_GARFA_GARHIS').AsString;
    sAnterior := oConsulta.FieldByName('FASE_GARHIS').AsString;
    if rCambio.Anterior <> FASE_ENTREGADA_CLIENTE then
      InsertarHistorial(rCambio, sAnterior, SFaseEntregado);
    oConsulta.Close;
    oConsulta.SQL.Text := 'UPDATE fza_garantias_reclamaciones ' +
      'SET CODIGO_GARFA_GAR = :NUEVA WHERE ID_GAR = :ID';
    oConsulta.ParamByName('ID').AsLargeInt := AReparacion;
    oConsulta.ParamByName('NUEVA').AsString := FASE_ENTREGADA_CLIENTE;
    oConsulta.Execute;
    oPrendas := TDatosPrendasReparacion.Create(FConexion);
    try
      oPrendas.Entregar(AReparacion,AUsuario);
    finally
      FreeAndNil(oPrendas);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosFasesReparacion.AvisoSeleccionado: TAvisoFaseReparacion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TAvisoFaseReparacion);
  if not FHistorial.Active or FHistorial.IsEmpty then
    raise EArgumentException.Create(SFaseSinHistorial);
  Result.Historial := FHistorial.FieldByName('ID_GARHIS').AsLargeInt;
  Result.Reparacion := FHistorial.FieldByName('ID_GAR_GARHIS').AsLargeInt;
  Result.Fase := FHistorial.FieldByName('FASE_GARHIS').AsString;
  Result.Instante := FHistorial.FieldByName('INSTANTE_GARHIS').AsDateTime;
  oConsulta := Consulta('SELECT NOMBRE_CLIENTE_GAR, EMAIL_CLIENTE_GAR, ' +
    'DESCRIPCION_OBJETO_GAR FROM fza_garantias_reclamaciones ' +
    'WHERE ID_GAR = :ID');
  try
    oConsulta.ParamByName('ID').AsLargeInt := Result.Reparacion;
    oConsulta.Open;
    Result.Cliente := oConsulta.FieldByName('NOMBRE_CLIENTE_GAR').AsString;
    Result.Email := oConsulta.FieldByName('EMAIL_CLIENTE_GAR').AsString;
    Result.Objeto := oConsulta.FieldByName('DESCRIPCION_OBJETO_GAR').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TDatosFasesReparacion.IniciarAviso(
  const ACorreo: TCorreoFaseReparacion): string;
var
  oConsulta: TUniQuery;
  rId: TGUID;
begin
  if FConexion.InTransaction then
    raise EArgumentException.Create(SFaseCorreoTransaccion);
  if ValidarCorreoFase(ACorreo) <> '' then
    raise EArgumentException.Create(ValidarCorreoFase(ACorreo));
  CreateGUID(rId);
  Result := StringReplace(Copy(GUIDToString(rId), 2, 36), '-', '',
    [rfReplaceAll]);
  oConsulta := Consulta('INSERT INTO fza_garantias_fases_avisos ' +
    '(ID_GARAVI, ID_GAR_GARAVI, ID_GARHIS_GARAVI, EMAIL_GARAVI, ' +
    'ASUNTO_GARAVI, TEXTO_GARAVI, ESTADO_GARAVI, INSTANTE_ALTA, USUARIO_ALTA) '+
    'SELECT :AVISO, H.ID_GAR_GARHIS, H.ID_GARHIS, :EMAIL, :ASUNTO, ' +
    ':TEXTO, ''ENVIANDO'', NOW(6), :USUARIO ' +
    'FROM fza_garantias_fases_hist H WHERE H.ID_GARHIS = :HISTORIAL ' +
    'AND H.ID_GAR_GARHIS = :REPARACION');
  try
    oConsulta.ParamByName('AVISO').AsString := Result;
    oConsulta.ParamByName('HISTORIAL').AsLargeInt := ACorreo.Aviso.Historial;
    oConsulta.ParamByName('REPARACION').AsLargeInt := ACorreo.Aviso.Reparacion;
    oConsulta.ParamByName('EMAIL').AsString := Trim(ACorreo.Email);
    oConsulta.ParamByName('ASUNTO').AsString := ACorreo.Asunto;
    oConsulta.ParamByName('TEXTO').AsString := ACorreo.Texto;
    oConsulta.ParamByName('USUARIO').AsString := Copy(ACorreo.Usuario, 1, 50);
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EArgumentException.Create(SFaseSinHistorial);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TDatosFasesReparacion.FinalizarAviso(const AId, AEstado,
  AResultado, AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if FConexion.InTransaction then
    raise EArgumentException.Create(SFaseCorreoTransaccion);
  oConsulta := Consulta('UPDATE fza_garantias_fases_avisos ' +
    'SET ESTADO_GARAVI = :ESTADO, RESULTADO_GARAVI = :RESULTADO, ' +
    'INSTANTE_MODIF = NOW(6), USUARIO_MODIF = :USUARIO ' +
    'WHERE ID_GARAVI = :ID AND ESTADO_GARAVI = ''ENVIANDO''');
  try
    oConsulta.ParamByName('ID').AsString := AId;
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    oConsulta.ParamByName('RESULTADO').AsString := AResultado;
    oConsulta.ParamByName('USUARIO').AsString := Copy(AUsuario, 1, 50);
    oConsulta.Execute;
    if oConsulta.RowsAffected <> 1 then
      raise EArgumentException.Create(SFaseSinHistorial);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
