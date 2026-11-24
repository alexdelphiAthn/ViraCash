{******************************************************************************}
{  Módulo:       UniDataReposicionAutomatica                                  }
{    Tipo:       Persistencia UniDAC                                          }
{   Fecha:       18/11/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Reserva estable de partidas por recepción, sin convertir el artículo.      }
{******************************************************************************}
unit UniDataReposicionAutomatica;

interface

uses
  Data.DB, Uni, inLibParametrosIntf, inLibTrazabilidad;

type
  TRecepcionReposicion = record
    TipoDocumento: string;
    Serie: string;
    Numero: string;
    Sku: string;
    Temporada: string;
    Usuario: string;
    // FZ-ISSUE-1042: lote confirmado por el usuario ('' = generarlo).
    LoteSolicitado: string;
  end;

  // Propuesta de lote para una línea de compra (FZ-ISSUE-1042).
  TPropuestaReposicion = record
    Aplica: Boolean;
    LoteActual: string;
    Propuesta: string;
    FechaEntrada: TDate;
  end;

  // Devuelve '' si el lote vale o el texto del aviso (FZ-ISSUE-1051).
  TValidacionLoteReposicion = reference to function(
    const ALote: string): string;

  // Muestra la propuesta y devuelve el lote confirmado. False = cancelar.
  // AValidar se consulta antes de cerrar; con aviso, se vuelve a pedir.
  TConfirmacionLoteReposicion = reference to function(const ASku: string;
    AFechaEntrada: TDate; var ALote: string;
    const AValidar: TValidacionLoteReposicion): Boolean;

var
  // La asigna la interfaz; sin ella se acepta la propuesta.
  ConfirmacionLoteReposicion: TConfirmacionLoteReposicion;

const
  LONGITUD_MAXIMA_LOTE_REPOSICION = 50;

function EsPartidaReposicion(AConexion: TUniConnection;
  const ASku, ALote: string): Boolean;
function EmpresaReposicionActiva(AConexion: TUniConnection;
  const AEmpresa: string): Boolean;
function HayPartidasReposicion(AConexion: TUniConnection): Boolean;
function ActivacionVisualReposicion(AConexion: TUniConnection;
  const AParametros: IParametros): TActivacionTrazabilidad;
function PrepararPartidaReposicion(AConexion: TUniConnection;
  const ARecepcion: TRecepcionReposicion): string;
function ProponerPartidaReposicion(AConexion: TUniConnection;
  const ATipo, ASerie, ANumero, ASku: string): TPropuestaReposicion;
procedure PrepararReposicionLinea(AConexion: TUniConnection;
  ALinea: TDataSet; const ASufijo, AUsuario: string;
  const AParametros: IParametros);
procedure PrepararReposicionMovimiento(AProcedimiento: TUniStoredProc;
  var ALote: string);

implementation

uses
  System.SysUtils, System.Variants, UniDataCodigosBarrasLote,
  UniDataAppParamRepositorio, inLibAppParamPersistenciaIntf,
  inLibMsgTrazabilidad, inLibErroresBBDD;

function EsPartidaReposicion(AConexion: TUniConnection;
  const ASku, ALote: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if (Trim(ASku) <> '') and (Trim(ALote) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 FROM fza_articulos_lotes WHERE ' +
        'CODIGO_UNIDAD_LOT = :SKU AND LOTE_LOT = :LOTE ' +
        'AND ESREPOSICION_LOT = ''S''';
      oConsulta.ParamByName('SKU').AsString := ASku;
      oConsulta.ParamByName('LOTE').AsString := ALote;
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function EmpresaReposicionActiva(AConexion: TUniConnection;
  const AEmpresa: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT 1 FROM fza_empresas ' +
      'WHERE CODIGO_EMP_EMP = :EMPRESA AND ESLOTES_REPOSICION_EMP = ''S''';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function HayPartidasReposicion(AConexion: TUniConnection): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT 1 FROM fza_empresas WHERE ESLOTES_REPOSICION_EMP = ''S'' ' +
      'UNION ALL SELECT 1 FROM fza_articulos_lotes ' +
      'WHERE ESREPOSICION_LOT = ''S'' LIMIT 1';
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function ActivacionVisualReposicion(AConexion: TUniConnection;
  const AParametros: IParametros): TActivacionTrazabilidad;
begin
  Result := TActivacionTrazabilidad.Leer(AParametros);
  // FZ-ISSUE-1043: las salidas piden lote de las partidas de reposición.
  PublicarHayReposicion(HayPartidasReposicion(AConexion));
  Result.LotesSoloReposicion := HayReposicionPublicada and not Result.Lotes;
  Result.Lotes := Result.Lotes or Result.LotesSoloReposicion;
end;

function PrepararPartidaReposicion(AConexion: TUniConnection;
  const ARecepcion: TRecepcionReposicion): string;
var
  oReserva: TUniStoredProc;
  EsTransaccionPropia: Boolean;
begin
  oReserva := TUniStoredProc.Create(nil);
  EsTransaccionPropia := not AConexion.InTransaction;
  try
    oReserva.Connection := AConexion;
    oReserva.StoredProcName := 'PRC_FZA_REPOSICION_PREPARAR_LOTE';
    oReserva.Params.CreateParam(ftString, 'p_TIPO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_SKU', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_TEMPORADA', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_LOTE_SOLICITADO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_USUARIO', ptInput);
    oReserva.Params.CreateParam(ftString, 'p_LOTE', ptOutput);
    oReserva.ParamByName('p_TIPO').AsString := ARecepcion.TipoDocumento;
    oReserva.ParamByName('p_SERIE').AsString := ARecepcion.Serie;
    oReserva.ParamByName('p_NUMERO').AsString := ARecepcion.Numero;
    oReserva.ParamByName('p_SKU').AsString := ARecepcion.Sku;
    if Trim(ARecepcion.Temporada) = '' then
      oReserva.ParamByName('p_TEMPORADA').Clear
    else
      oReserva.ParamByName('p_TEMPORADA').AsString := ARecepcion.Temporada;
    if Trim(ARecepcion.LoteSolicitado) = '' then
      oReserva.ParamByName('p_LOTE_SOLICITADO').Value := Null
    else
      oReserva.ParamByName('p_LOTE_SOLICITADO').AsString :=
        Trim(ARecepcion.LoteSolicitado);
    oReserva.ParamByName('p_USUARIO').AsString := ARecepcion.Usuario;
    if EsTransaccionPropia then
      AConexion.StartTransaction;
    try
      oReserva.ExecProc;
      Result := oReserva.ParamByName('p_LOTE').AsString;
      if Result <> '' then
        AsegurarCodigoBarrasLote(AConexion, ARecepcion.Sku, Result,
          ARecepcion.Usuario);
      if EsTransaccionPropia then
        AConexion.Commit;
    except
      if EsTransaccionPropia and AConexion.InTransaction then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oReserva);
  end;
end;

function ProponerPartidaReposicion(AConexion: TUniConnection;
  const ATipo, ASerie, ANumero, ASku: string): TPropuestaReposicion;
var
  oPropuesta: TUniStoredProc;
begin
  Result := Default(TPropuestaReposicion);
  oPropuesta := TUniStoredProc.Create(nil);
  try
    oPropuesta.Connection := AConexion;
    oPropuesta.StoredProcName := 'PRC_FZA_REPOSICION_PROPONER';
    oPropuesta.Params.CreateParam(ftString, 'p_TIPO', ptInput);
    oPropuesta.Params.CreateParam(ftString, 'p_SERIE', ptInput);
    oPropuesta.Params.CreateParam(ftString, 'p_NUMERO', ptInput);
    oPropuesta.Params.CreateParam(ftString, 'p_SKU', ptInput);
    oPropuesta.Params.CreateParam(ftString, 'p_APLICA', ptOutput);
    oPropuesta.Params.CreateParam(ftString, 'p_LOTE_ACTUAL', ptOutput);
    oPropuesta.Params.CreateParam(ftString, 'p_PROPUESTA', ptOutput);
    oPropuesta.Params.CreateParam(ftDate, 'p_FECHA', ptOutput);
    oPropuesta.ParamByName('p_TIPO').AsString := ATipo;
    oPropuesta.ParamByName('p_SERIE').AsString := ASerie;
    oPropuesta.ParamByName('p_NUMERO').AsString := ANumero;
    oPropuesta.ParamByName('p_SKU').AsString := ASku;
    oPropuesta.ExecProc;
    Result.Aplica := oPropuesta.ParamByName('p_APLICA').AsString = 'S';
    Result.LoteActual := oPropuesta.ParamByName('p_LOTE_ACTUAL').AsString;
    Result.Propuesta := oPropuesta.ParamByName('p_PROPUESTA').AsString;
    if not oPropuesta.ParamByName('p_FECHA').IsNull then
      Result.FechaEntrada := oPropuesta.ParamByName('p_FECHA').AsDate;
  finally
    FreeAndNil(oPropuesta);
  end;
end;

// FZ-ISSUE-1051: el lote ya identifica otra recepción (cabecera o partida).
function LoteReposicionOcupado(AConexion: TUniConnection;
  const ATipo, ASerie, ANumero, ALote: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT FNC_FZA_REPOSICION_LOTE_OCUPADO(' +
      ':LOTE, :TIPO, :SERIE, :NUMERO) AS OCUPADO';
    oConsulta.ParamByName('LOTE').AsString := Trim(ALote);
    oConsulta.ParamByName('TIPO').AsString := ATipo;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    Result := oConsulta.FieldByName('OCUPADO').AsString = 'S';
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure LeerDatosPatronReposicion(AConexion: TUniConnection;
  const ARecepcion: TRecepcionReposicion;
  out ACodigoProveedor, AReferencia: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    if ARecepcion.TipoDocumento = 'FP' then
      oConsulta.SQL.Text := 'SELECT CODIGO_PRV_FACC AS PROVEEDOR, ' +
        'REF_PROVEEDOR_FACC AS REFERENCIA FROM fza_facturas_compra ' +
        'WHERE SERIE_FACC = :SERIE AND NUMERO_FACC = :NUMERO'
    else
      oConsulta.SQL.Text := 'SELECT CODIGO_PRV_ALBC AS PROVEEDOR, ' +
        'REF_PROVEEDOR_ALBC AS REFERENCIA FROM fza_albaranes_compra ' +
        'WHERE SERIE_ALBC = :SERIE AND NUMERO_ALBC = :NUMERO';
    oConsulta.ParamByName('SERIE').AsString := ARecepcion.Serie;
    oConsulta.ParamByName('NUMERO').AsString := ARecepcion.Numero;
    oConsulta.Open;
    ACodigoProveedor := oConsulta.FieldByName('PROVEEDOR').AsString;
    AReferencia := oConsulta.FieldByName('REFERENCIA').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function ElegirLoteRecepcion(AConexion: TUniConnection;
  const ARecepcion: TRecepcionReposicion;
  const APropuesta: TPropuestaReposicion; const APatron: string): string;
var
  sProveedor, sReferencia, sBase, sSufijo: string;
  iSufijo: Integer;
  bPreguntar: Boolean;
begin
  if not PatronLoteRecepcionValido(APatron) then
    raise EValidacionBBDD.Create(SErrorPatronLoteRecepcionNoValido);
  bPreguntar := PatronLoteRecepcionPideConfirmacion(APatron);
  if SameText(Trim(APatron), PATRON_LOTE_RECEPCION_PREGUNTAR) then
    sBase := APropuesta.Propuesta
  else
  begin
    LeerDatosPatronReposicion(AConexion, ARecepcion, sProveedor, sReferencia);
    sBase := AplicarPatronLoteRecepcion(APatron, sProveedor, sReferencia,
      APropuesta.FechaEntrada);
  end;
  if (sBase = '') and not bPreguntar then
    raise EValidacionBBDD.Create(SErrorDatoPatronLoteRecepcion);
  if Length(sBase) > LONGITUD_MAXIMA_LOTE_REPOSICION then
  begin
    if not bPreguntar then
      raise EValidacionBBDD.CreateFmt(SErrorLoteReposicionLargo,
        [LONGITUD_MAXIMA_LOTE_REPOSICION]);
    sBase := '';
  end;
  Result := sBase;
  iSufijo := 0;
  while (Result <> '') and LoteReposicionOcupado(AConexion,
    ARecepcion.TipoDocumento, ARecepcion.Serie, ARecepcion.Numero,
    Result) do
  begin
    Inc(iSufijo);
    sSufijo := '-' + IntToStr(iSufijo);
    Result := Copy(sBase, 1, LONGITUD_MAXIMA_LOTE_REPOSICION -
      Length(sSufijo)) + sSufijo;
  end;
  if bPreguntar then
  begin
    if not Assigned(ConfirmacionLoteReposicion) then
      raise EValidacionBBDD.Create(SErrorLoteRecepcionRequiereConfirmacion);
    if not ConfirmacionLoteReposicion(ARecepcion.Sku,
      APropuesta.FechaEntrada, Result,
      function(const ALote: string): string
      begin
        Result := '';
        if LoteReposicionOcupado(AConexion, ARecepcion.TipoDocumento,
          ARecepcion.Serie, ARecepcion.Numero, ALote) then
          Result := Format(SErrorLoteReposicionOcupado, [ALote]);
      end) then
      Abort;
  end;
end;

procedure PrepararReposicionLinea(AConexion: TUniConnection;
  ALinea: TDataSet; const ASufijo, AUsuario: string;
  const AParametros: IParametros);
var
  sCabecera, sTipo, sLote: string;
  Recepcion: TRecepcionReposicion;
  Propuesta: TPropuestaReposicion;
begin
  sCabecera := '';
  sTipo := '';
  if ASufijo = 'ALBCLIN' then
  begin
    sCabecera := 'ALBC';
    sTipo := 'AC';
  end
  else if ASufijo = 'FACCLIN' then
  begin
    sCabecera := 'FACC';
    sTipo := 'FP';
  end;
  // La cabecera reserva una sola identidad, también al editar cantidades.
  if (sTipo <> '') and (ALinea.State in dsEditModes) and
     (ALinea.FieldByName('CANTIDAD_' + ASufijo).AsFloat > 0) then
  begin
    Recepcion := Default(TRecepcionReposicion);
    Recepcion.TipoDocumento := sTipo;
    Recepcion.Serie := ALinea.FieldByName(
      'SERIE_' + sCabecera + '_' + ASufijo).AsString;
    Recepcion.Numero := ALinea.FieldByName(
      'NUMERO_' + sCabecera + '_' + ASufijo).AsString;
    Recepcion.Sku :=
      ALinea.FieldByName('CODIGO_UNIDAD_' + ASufijo).AsString;
    Recepcion.Temporada := AParametros.GetString('appTemporadaDefecto');
    Recepcion.Usuario := AUsuario;
    Propuesta := ProponerPartidaReposicion(AConexion, sTipo,
      Recepcion.Serie, Recepcion.Numero, Recepcion.Sku);
    if Propuesta.Aplica and (Propuesta.LoteActual = '') then
    begin
      sLote := Trim(ALinea.FieldByName('LOTE_' + ASufijo).AsString);
      if sLote = '' then
        sLote := ElegirLoteRecepcion(AConexion, Recepcion, Propuesta,
          AParametros.GetString(PARAMETRO_PATRON_LOTE_RECEPCION,
            PATRON_LOTE_RECEPCION_DEFECTO));
      Recepcion.LoteSolicitado := Trim(sLote);
    end;
    sLote := PrepararPartidaReposicion(AConexion, Recepcion);
    if sLote <> '' then
      ALinea.FieldByName('LOTE_' + ASufijo).AsString := sLote;
  end;
end;

procedure LeerParametrosRecepcion(AConexion: TUniConnection;
  const AUsuario: string; out ATemporada, APatron: string);
var
  oConsulta: TUniQuery;
  sGrupo: string;
  Valores: TValoresPerfilAppParam;
  Valor: TValorPerfilAppParam;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT GRUPO_USU FROM fza_usuarios ' +
      'WHERE USUARIO_USU = :USUARIO';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Open;
    sGrupo := oConsulta.Fields[0].AsString;
  finally
    FreeAndNil(oConsulta);
  end;
  ATemporada := '';
  APatron := PATRON_LOTE_RECEPCION_DEFECTO;
  Valores := CrearRepositorioAppParamUniDAC(AConexion).CargarValores(
    AUsuario, sGrupo, 'frmMtoAppParam');
  for Valor in Valores do
    if SameText(Valor.Subclave, 'appTemporadaDefecto') then
      ATemporada := Valor.Valor
    else if SameText(Valor.Subclave, PARAMETRO_PATRON_LOTE_RECEPCION) then
      APatron := Valor.Valor;
end;

function EsRecepcionAutomatica(AProcedimiento: TUniStoredProc;
  const ATipo: string): Boolean;
var
  oConsulta: TUniQuery;
  sSufijo, sTabla: string;
begin
  sSufijo := 'ALBC';
  sTabla := 'fza_albaranes_compra';
  if ATipo = 'FP' then
  begin
    sSufijo := 'FACC';
    sTabla := 'fza_facturas_compra';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AProcedimiento.Connection;
    oConsulta.SQL.Text := 'SELECT 1 FROM ' + sTabla + ' D ' +
      'JOIN fza_empresas E ON E.CODIGO_EMP_EMP = D.CODIGO_EMP_' +
      sSufijo + ' WHERE D.SERIE_' + sSufijo + ' = :SERIE AND D.NUMERO_' +
      sSufijo + ' = :NUMERO AND D.ESREPOSICION_AUTO_' + sSufijo +
      ' = ''S'' AND E.ESLOTES_REPOSICION_EMP = ''S''';
    oConsulta.ParamByName('SERIE').AsString :=
      AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString;
    oConsulta.ParamByName('NUMERO').AsString :=
      AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString;
    oConsulta.Open;
    Result := not oConsulta.IsEmpty;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure GrabarPartidaLineas(AProcedimiento: TUniStoredProc;
  const ALote, ATipo: string);
var
  sSufijo, sTabla: string;
  oConsulta: TUniQuery;
begin
  sSufijo := 'ALBC';
  sTabla := 'fza_albaranes_compra_lineas';
  if ATipo = 'FP' then
  begin
    sSufijo := 'FACC';
    sTabla := 'fza_facturas_compra_lineas';
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AProcedimiento.Connection;
    oConsulta.SQL.Text := 'UPDATE ' + sTabla + ' SET LOTE_' +
      sSufijo + 'LIN = :LOTE WHERE SERIE_' + sSufijo + '_' +
      sSufijo + 'LIN = :SERIE AND NUMERO_' + sSufijo + '_' +
      sSufijo + 'LIN = :NUMERO AND CODIGO_UNIDAD_' + sSufijo +
      'LIN = :SKU AND COALESCE(LOTE_' + sSufijo + 'LIN, '''') = ''''';
    oConsulta.ParamByName('LOTE').AsString := ALote;
    oConsulta.ParamByName('SERIE').AsString :=
      AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString;
    oConsulta.ParamByName('NUMERO').AsString :=
      AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString;
    oConsulta.ParamByName('SKU').AsString :=
      AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure PrepararReposicionMovimiento(AProcedimiento: TUniStoredProc;
  var ALote: string);
var
  sTipo, sPatron: string;
  Recepcion: TRecepcionReposicion;
  Propuesta: TPropuestaReposicion;
begin
  sTipo := AProcedimiento.ParamByName('p_TIPO_DOC_MOV').AsString;
  if (Trim(ALote) = '') and ((sTipo = 'AC') or (sTipo = 'FP')) and
     (AProcedimiento.ParamByName('p_TIPO_MOVIMIENTO_MOV').AsString = 'E') and
     (AProcedimiento.ParamByName('p_CANTIDAD_MOV').AsFloat > 0) and
     EsRecepcionAutomatica(AProcedimiento, sTipo) then
  begin
    Recepcion := Default(TRecepcionReposicion);
    Recepcion.TipoDocumento := sTipo;
    Recepcion.Serie :=
      AProcedimiento.ParamByName('p_SERIE_DOC_MOV').AsString;
    Recepcion.Numero :=
      AProcedimiento.ParamByName('p_NRO_DOC_MOV').AsString;
    Recepcion.Sku :=
      AProcedimiento.ParamByName('p_CODIGO_UNIDAD_MOV').AsString;
    Recepcion.Usuario := AProcedimiento.ParamByName('p_USUARIO').AsString;
    Propuesta := ProponerPartidaReposicion(AProcedimiento.Connection, sTipo,
      Recepcion.Serie, Recepcion.Numero, Recepcion.Sku);
    if Propuesta.Aplica and (Propuesta.LoteActual = '') then
    begin
      LeerParametrosRecepcion(AProcedimiento.Connection, Recepcion.Usuario,
        Recepcion.Temporada, sPatron);
      Recepcion.LoteSolicitado := ElegirLoteRecepcion(
        AProcedimiento.Connection, Recepcion, Propuesta, sPatron);
    end;
    ALote := PrepararPartidaReposicion(AProcedimiento.Connection, Recepcion);
    if ALote <> '' then
      GrabarPartidaLineas(AProcedimiento, ALote, sTipo);
  end;
end;

end.
