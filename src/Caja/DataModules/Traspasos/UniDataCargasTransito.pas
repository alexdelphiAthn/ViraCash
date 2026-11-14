{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCargasTransito                                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Almacén - Cargas en tránsito: las cargas de la empresa que viajan en un   }
{    almacén de tránsito (furgoneta, agencia), con su antigüedad y cómo se     }
{    cerraron, y los apuntes de pérdida y deterioro en transporte para         }
{    reclamar al transportista o al seguro (FZ-ISSUE-256).                     }
{******************************************************************************}
unit UniDataCargasTransito;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen,
  inLibTraspasoOpePersistenciaIntf;

const
  // Ciclo de la reclamación al transportista o al seguro (FZ-ISSUE-728).
  ESTADOS_RECLAMACION_TRANSITO: array[0..4] of string = ('PENDIENTE',
    'ENVIADA', 'ACEPTADA', 'COBRADA', 'RECHAZADA');

type
  // Lo que se anota de una vez en varias incidencias. Los importes son el
  // total de la reclamación y se reparten en proporción al coste de cada
  // incidencia; sin AConIndemnizado el indemnizado queda sin saber (NULL).
  TReclamacionTransito = record
    Referencia: string;
    Estado: string;
    ImporteReclamado: Currency;
    ImporteIndemnizado: Currency;
    ConIndemnizado: Boolean;
  end;

  TdmCargasTransito = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FConImportes: Boolean;
    procedure ConfigurarConsultas;
    procedure AsignarFiltros(AConsulta: TUniQuery;
      const ATransito, AOrigen, ADestino: string);
    function ExistenImportesReclamacion: Boolean;
    function CostesIncidencias(
      const AIds: TArray<Int64>): TArray<Currency>;
    procedure ActualizarReclamacion(AConsulta: TUniQuery; AId: Int64;
      const AReclamacion: TReclamacionTransito;
      AReclamado, AIndemnizado: Currency; AReclamadoEsCoste: Boolean);
  public
    unqryIncidencias: TUniQuery;
    dsIncidencias: TDataSource;
    procedure AbrirDetalles; override;
    // Almacenes activos para los filtros: los de tránsito o el resto.
    function ListarAlmacenes(
      ASoloTransito: Boolean): TAlmacenesDestinoTraspaso;
    // Vacío = sin filtro. El estado solo filtra las cargas; los apuntes
    // llevan los otros tres filtros.
    procedure AplicarFiltros(
      const ATransito, AOrigen, ADestino, AEstado: string);
    // Filtra los apuntes por la referencia de la reclamación (contiene).
    procedure FiltrarReferencia(const AReferencia: string);
    procedure RefrescarIncidencias;
    // Incidencias de una carga, para reclamarlas todas de una vez.
    function IncidenciasCarga(AIdCarga: Int64): TArray<Int64>;
    function CosteTotalIncidencias(const AIds: TArray<Int64>): Currency;
    // Lo anotado en las incidencias: referencia y estado de la primera,
    // importes sumados (el indemnizado, si alguna lo tiene).
    function LeerReclamacion(
      const AIds: TArray<Int64>): TReclamacionTransito;
    procedure GrabarReclamacion(const AIds: TArray<Int64>;
      const AReclamacion: TReclamacionTransito);
    // False si la BBDD aún no tiene las columnas de importes (script 845).
    property ConImportes: Boolean read FConImportes;
  end;

function ConsultarHojaRutaTransito(AOwner: TComponent;
  AConexion: TUniConnection; const ATransito: string;
  const AIds: TArray<Int64> = nil): TUniQuery;

function SqlCargasTransito: string;
function SqlIncidenciasTransito(AConImportes: Boolean = True): string;
// Reparte ATotal en proporción a APesos, a céntimos y sin perder el
// redondeo (el resto va a la última). Sin pesos, a partes iguales.
function RepartirImporteReclamacion(ATotal: Currency;
  const APesos: TArray<Currency>): TArray<Currency>;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  System.Math, System.StrUtils,
  inLibMsgCaja;

const
  SQL_EMPRESA_HOJA_RUTA =
    'CASE WHEN V.ESCOMPARTIDO_ALM = ''S'' THEN T.CODIGO_EMP_TRTRA ' +
    'ELSE COALESCE(NULLIF(V.CODIGO_EMP_ALM, ''''), ' +
    'T.CODIGO_EMP_TRTRA) END';
  SQL_CONDICION_TRANSITO =
    'TIPO_USO_ALM IN (''TR' + #$C1 + 'NSITO'', ''TRANSITO'')';
  SQL_FILTROS_CARGA =
    ' WHERE (:EMP = '''' OR T.CODIGO_EMP_TRTRA = :EMP) ' +
    '   AND (:TRANSITO = '''' OR T.CODIGO_ALM_TRANSITO_TRTRA = :TRANSITO) ' +
    '   AND (:ORIGEN = '''' OR T.CODIGO_ALM_ORIGEN_TRTRA = :ORIGEN) ' +
    '   AND (:DESTINO = '''' OR T.CODIGO_ALM_DESTINO_TRTRA = :DESTINO) ';

procedure ForceReferenceToClass(C: TClass);
begin
end;

function SqlCamposHojaRuta: string;
begin
  Result :=
      'SELECT CONCAT(LENGTH(T.CODIGO_ALM_ORIGEN_TRTRA), '':'' , ' +
      'T.CODIGO_ALM_ORIGEN_TRTRA' +
      ', LENGTH(T.CODIGO_ALM_DESTINO_TRTRA), '':'' , ' +
      ' T.CODIGO_ALM_DESTINO_TRTRA, COALESCE(D.CODIGO_EMP_ALM, '''')) ' +
      ' AS GRUPO, T.ID_TRTRA AS ID_CARGA, ' +
      ' T.FECHA_CARGA_TRTRA AS FECHA_CARGA, ' +
      ' CONCAT_WS('' - '', T.CODIGO_ALM_TRANSITO_TRTRA, ' +
      ' V.NOMBRE_ALM_ALM) AS TRANSITO, ' +
      ' CONCAT_WS('' - '', ' + SQL_EMPRESA_HOJA_RUTA + ', ' +
      ' EO.RAZON_SOCIAL_EMP) AS ENTREGA, ' +
      ' CONCAT_WS('' - '', D.CODIGO_EMP_ALM, ' +
      ' ED.RAZON_SOCIAL_EMP) AS RECIBE, ' +
      ' CONCAT_WS('' - '', T.CODIGO_ALM_DESTINO_TRTRA, ' +
      ' D.NOMBRE_ALM_ALM) AS DESTINO, ' +
      ' CONCAT_WS('' - '', T.CODIGO_ALM_ORIGEN_TRTRA, ' +
      ' O.NOMBRE_ALM_ALM) AS ORIGEN, ' +
      ' CONCAT(T.TIPO_DOC_CARGA_TRTRA, '' '', ' +
      ' T.SERIE_CARGA_TRTRA, ''/'', T.NUMERO_CARGA_TRTRA) AS DOCUMENTO, ' +
      ' T.NUMERO_OPERACION_CARGA_TRTRA AS OPERACION, ' +
      ' M.CODIGO_UNIDAD_MOV AS SKU, ' +
      ' COALESCE(NULLIF(M.DESCRIPCION_ARTICULO_MOV, ''''), ' +
      ' A.DESCRIPCION_ART, M.CODIGO_ART_MOV) AS DESCRIPCION, ' +
      ' COALESCE(M.LOTE_MOV, '''') AS LOTE, ' +
      ' M.CANTIDAD_MOV AS UNIDADES ';
end;

function SqlOrigenHojaRuta: string;
begin
  Result :=
      ' FROM fza_traspasos_transito T ' +
      ' JOIN fza_almacenes V ' +
      ' ON V.CODIGO_ALM_ALM = T.CODIGO_ALM_TRANSITO_TRTRA ' +
      ' LEFT JOIN fza_almacenes O ' +
      ' ON O.CODIGO_ALM_ALM = T.CODIGO_ALM_ORIGEN_TRTRA ' +
      ' LEFT JOIN fza_almacenes D ' +
      ' ON D.CODIGO_ALM_ALM = T.CODIGO_ALM_DESTINO_TRTRA ' +
      ' LEFT JOIN fza_empresas EO ' +
      ' ON EO.CODIGO_EMP_EMP = ' + SQL_EMPRESA_HOJA_RUTA + ' ' +
      ' LEFT JOIN fza_empresas ED ' +
      ' ON ED.CODIGO_EMP_EMP = D.CODIGO_EMP_ALM ' +
      ' JOIN fza_movimientos_almacen M ' +
      ' ON M.TIPO_DOC_MOV = T.TIPO_DOC_CARGA_TRTRA ' +
      ' AND M.SERIE_DOC_MOV = T.SERIE_CARGA_TRTRA ' +
      ' AND M.NUMERO_DOC_MOV = T.NUMERO_CARGA_TRTRA ' +
      ' AND M.CODIGO_ALM_MOV = T.CODIGO_ALM_TRANSITO_TRTRA ' +
      ' AND M.CODIGO_ALM_CONTRA_MOV = T.CODIGO_ALM_ORIGEN_TRTRA ' +
      ' AND M.TIPO_MOV = ''E'' AND M.CANTIDAD_MOV > 0 ' +
      ' LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = M.CODIGO_ART_MOV ' +
      ' WHERE T.CODIGO_ALM_TRANSITO_TRTRA = :TRANSITO ' +
      ' AND T.ESTADO_TRTRA = ''PENDIENTE'' ' +
      ' AND V.TIPO_USO_ALM IN (''TRÁNSITO'', ''TRANSITO'') ' +
      ' ORDER BY GRUPO, T.ID_TRTRA, M.LINEA_MOV, M.CODIGO_UNIDAD_MOV';
end;

// La hoja reúne la furgoneta completa, sin limitarla a la empresa que
// consulta. El origen de cada entrada evita cruzar documentos con igual
// serie y número pertenecientes a empresas distintas (FZ-ISSUE-377).
procedure FiltrarCargasHojaRuta(AConsulta: TUniQuery;
  const AIds: TArray<Int64>);
var
  Parametros: string;
  I: Integer;
begin
  if Length(AIds) > 0 then
  begin
    Parametros := '';
    for I := 0 to High(AIds) do
    begin
      if I > 0 then
        Parametros := Parametros + ',';
      Parametros := Parametros + ':CARGA' + IntToStr(I);
    end;
    AConsulta.SQL.Text := StringReplace(AConsulta.SQL.Text,
      ' ORDER BY GRUPO', ' AND T.ID_TRTRA IN (' + Parametros +
      ') ORDER BY GRUPO', []);
    for I := 0 to High(AIds) do
      AConsulta.ParamByName('CARGA' + IntToStr(I)).AsLargeInt := AIds[I];
  end;
end;

function ConsultarHojaRutaTransito(AOwner: TComponent;
  AConexion: TUniConnection; const ATransito: string;
  const AIds: TArray<Int64>): TUniQuery;
begin
  if Trim(ATransito) = '' then
    raise EArgumentException.Create(SErrorHojaRutaSinTransito);
  Result := TUniQuery.Create(AOwner);
  try
    Result.Connection := AConexion;
    Result.ReadOnly := True;
    Result.SQL.Text := SqlCamposHojaRuta + SqlOrigenHojaRuta;
    FiltrarCargasHojaRuta(Result,AIds);
    Result.ParamByName('TRANSITO').AsString := Trim(ATransito);
    Result.Open;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

// Las pendientes primero y, dentro, las más antiguas; después las
// cerradas, de la más reciente a la más antigua.
function SqlCargasTransito: string;
begin
  Result :=
    'SELECT T.ID_TRTRA, T.FECHA_CARGA_TRTRA, ' +
    '       DATEDIFF(CURRENT_DATE, T.FECHA_CARGA_TRTRA) AS DIAS_TRTRA, ' +
    '       T.ESTADO_TRTRA, ' +
    '       CONCAT(T.CODIGO_ALM_ORIGEN_TRTRA, '' - '', ' +
    '              COALESCE(AO.NOMBRE_ALM_ALM, '''')) AS ORIGEN, ' +
    '       CONCAT(T.CODIGO_ALM_TRANSITO_TRTRA, '' - '', ' +
    '              COALESCE(ATR.NOMBRE_ALM_ALM, '''')) AS TRANSITO, ' +
    '       CONCAT(T.CODIGO_ALM_DESTINO_TRTRA, '' - '', ' +
    '              COALESCE(AD.NOMBRE_ALM_ALM, '''')) AS DESTINO, ' +
    '       CONCAT_WS('' '', T.TIPO_DOC_CARGA_TRTRA, ' +
    '                 CONCAT(T.SERIE_CARGA_TRTRA, ''/'', ' +
    '                        T.NUMERO_CARGA_TRTRA)) AS CARGA, ' +
    '       COALESCE(T.NUMERO_OPERACION_CARGA_TRTRA, '''') ' +
    '         AS NUMERO_OPERACION_CARGA_TRTRA, ' +
    '       (SELECT COALESCE(SUM(M.CANTIDAD_MOV), 0) ' +
    '          FROM fza_movimientos_almacen M ' +
    '         WHERE M.TIPO_DOC_MOV = T.TIPO_DOC_CARGA_TRTRA ' +
    '           AND M.SERIE_DOC_MOV = T.SERIE_CARGA_TRTRA ' +
    '           AND M.NUMERO_DOC_MOV = T.NUMERO_CARGA_TRTRA ' +
    '           AND M.CODIGO_ALM_MOV = T.CODIGO_ALM_TRANSITO_TRTRA ' +
    '           AND M.TIPO_MOV = ''E'') AS UNIDADES, ' +
    '       (SELECT COUNT(*) FROM fza_traspasos_transito_incidencias I ' +
    '         WHERE I.ID_TRTRA_TRTINC = T.ID_TRTRA) AS INCIDENCIAS, ' +
    '       CONCAT_WS('' '', T.TIPO_DOC_RECEPCION_TRTRA, ' +
    '                 CONCAT(T.SERIE_RECEPCION_TRTRA, ''/'', ' +
    '                        T.NUMERO_RECEPCION_TRTRA)) AS CIERRE, ' +
    '       T.FECHA_RECEPCION_TRTRA, ' +
    '       COALESCE(T.CODIGO_CAJA_RECEPCION_TRTRA, '''') ' +
    '         AS CODIGO_CAJA_RECEPCION_TRTRA, ' +
    '       COALESCE(T.TIPO_DESBLOQUEO_TRTRA, '''') ' +
    '         AS TIPO_DESBLOQUEO_TRTRA, ' +
    '       COALESCE(T.MOTIVO_DESBLOQUEO_TRTRA, '''') ' +
    '         AS MOTIVO_DESBLOQUEO_TRTRA, ' +
    '       COALESCE(T.USUARIO_DESBLOQUEO_TRTRA, '''') ' +
    '         AS USUARIO_DESBLOQUEO_TRTRA, ' +
    '       COALESCE(T.CODIGO_ALM_DESTINO_INICIAL_TRTRA, '''') ' +
    '         AS CODIGO_ALM_DESTINO_INICIAL_TRTRA, ' +
    '       T.CODIGO_EMP_TRTRA, T.USUARIO_ALTA ' +
    '  FROM fza_traspasos_transito T ' +
    '  LEFT JOIN fza_almacenes AO ' +
    '    ON AO.CODIGO_ALM_ALM = T.CODIGO_ALM_ORIGEN_TRTRA ' +
    '  LEFT JOIN fza_almacenes ATR ' +
    '    ON ATR.CODIGO_ALM_ALM = T.CODIGO_ALM_TRANSITO_TRTRA ' +
    '  LEFT JOIN fza_almacenes AD ' +
    '    ON AD.CODIGO_ALM_ALM = T.CODIGO_ALM_DESTINO_TRTRA ' +
    SQL_FILTROS_CARGA +
    '   AND (:ESTADO = '''' OR T.ESTADO_TRTRA = :ESTADO) ' +
    ' ORDER BY (T.ESTADO_TRTRA = ''PENDIENTE'') DESC, ' +
    '          IF(T.ESTADO_TRTRA = ''PENDIENTE'', T.FECHA_CARGA_TRTRA, ' +
    '             NULL), ' +
    '          T.FECHA_CARGA_TRTRA DESC, T.ID_TRTRA DESC';
end;

// Sin las columnas de importes (BBDD sin el script de FZ-ISSUE-728) se
// reclama el coste y el indemnizado queda vacío.
function SqlIncidenciasTransito(AConImportes: Boolean): string;
var
  sImportes: string;
begin
  sImportes :=
    '       I.TOTAL_COSTE_TRTINC AS IMPORTE_RECLAMADO_TRTINC, ' +
    '       CAST(NULL AS DECIMAL(19,6)) AS IMPORTE_INDEMNIZADO_TRTINC, ';
  if AConImportes then
    sImportes :=
      '       COALESCE(I.IMPORTE_RECLAMADO_TRTINC, I.TOTAL_COSTE_TRTINC) ' +
      '         AS IMPORTE_RECLAMADO_TRTINC, ' +
      '       I.IMPORTE_INDEMNIZADO_TRTINC, ';
  Result :=
    'SELECT I.ID_TRTINC, I.ID_TRTRA_TRTINC, I.FECHA_TRTINC, I.TIPO_TRTINC, ' +
    '       CONCAT(T.SERIE_CARGA_TRTRA, ''/'', T.NUMERO_CARGA_TRTRA) ' +
    '         AS CARGA, ' +
    '       T.CODIGO_ALM_ORIGEN_TRTRA, T.CODIGO_ALM_TRANSITO_TRTRA, ' +
    '       T.CODIGO_ALM_DESTINO_TRTRA, I.CODIGO_UNIDAD_TRTINC, ' +
    '       COALESCE(I.DESCRIPCION_ARTICULO_TRTINC, '''') ' +
    '         AS DESCRIPCION_ARTICULO_TRTINC, ' +
    '       I.CANTIDAD_TRTINC, I.PRECIO_COSTE_TRTINC, I.TOTAL_COSTE_TRTINC, ' +
    '       COALESCE(I.CODIGO_ALM_TARAS_TRTINC, '''') ' +
    '         AS CODIGO_ALM_TARAS_TRTINC, ' +
    '       COALESCE(I.MOTIVO_TRTINC, '''') AS MOTIVO_TRTINC, ' +
    '       COALESCE(I.REFERENCIA_RECLAMACION_TRTINC, '''') ' +
    '         AS REFERENCIA_RECLAMACION_TRTINC, ' +
    '       I.ESTADO_RECLAMACION_TRTINC, ' +
    sImportes +
    '       CONCAT_WS('' '', I.TIPO_DOC_TRTINC, ' +
    '                 CONCAT(I.SERIE_DOC_TRTINC, ''/'', ' +
    '                        I.NUMERO_DOC_TRTINC)) AS DOCUMENTO, ' +
    '       I.USUARIO_ALTA ' +
    '  FROM fza_traspasos_transito_incidencias I ' +
    '  JOIN fza_traspasos_transito T ' +
    '    ON T.ID_TRTRA = I.ID_TRTRA_TRTINC ' +
    SQL_FILTROS_CARGA +
    '   AND (:REFERENCIA = '''' OR I.REFERENCIA_RECLAMACION_TRTINC ' +
    '        LIKE CONCAT(''%'', :REFERENCIA, ''%'')) ' +
    ' ORDER BY I.FECHA_TRTINC DESC, I.ID_TRTINC DESC';
end;

function RepartirImporteReclamacion(ATotal: Currency;
  const APesos: TArray<Currency>): TArray<Currency>;
var
  cPesoTotal: Currency;
  cRepartido: Currency;
  i: Integer;
begin
  SetLength(Result, Length(APesos));
  cPesoTotal := 0;
  for i := 0 to High(APesos) do
    cPesoTotal := cPesoTotal + APesos[i];
  cRepartido := 0;
  for i := 0 to High(APesos) - 1 do
  begin
    if cPesoTotal <> 0 then
      Result[i] := SimpleRoundTo(ATotal * APesos[i] / cPesoTotal, -2)
    else
      Result[i] := SimpleRoundTo(ATotal / Length(APesos), -2);
    cRepartido := cRepartido + Result[i];
  end;
  if Length(APesos) > 0 then
    Result[High(APesos)] := ATotal - cRepartido;
end;

procedure TdmCargasTransito.DataModuleCreate(Sender: TObject);
begin
  inherited;
  unqryIncidencias := TUniQuery.Create(Self);
  // Hereda la conexión que TdmBase.DoCreate ya dejó en unqryTablaG antes de
  // tocar SpecificOptions: UniDAC valida cada opción contra el proveedor de
  // la conexión y sin ella lanza "Connection is not defined".
  unqryIncidencias.Connection := unqryTablaG.Connection;
  dsIncidencias := TDataSource.Create(Self);
  dsIncidencias.DataSet := unqryIncidencias;
  ConfigurarConsultas;
end;

procedure TdmCargasTransito.DataModuleDestroy(Sender: TObject);
begin
  CancelarEjecucionActiva;
  if Assigned(dsIncidencias) then
    dsIncidencias.DataSet := nil;
  if Assigned(unqryIncidencias) and unqryIncidencias.Active then
    unqryIncidencias.Close;
  inherited;
end;

// Arranca con las cargas pendientes de la empresa de la sesión.
procedure TdmCargasTransito.ConfigurarConsultas;
begin
  unqryTablaG.SQL.Text := SqlCargasTransito;
  unqryTablaG.KeyFields := 'ID_TRTRA';
  unqryTablaG.ReadOnly := True;
  FConImportes := ExistenImportesReclamacion;
  unqryIncidencias.SQL.Text := SqlIncidenciasTransito(FConImportes);
  if Assigned(unqryIncidencias.Connection) then
    unqryIncidencias.SpecificOptions.Values['FetchAll'] := 'True';
  unqryIncidencias.ReadOnly := True;
  AsignarFiltros(unqryTablaG, '', '', '');
  unqryTablaG.ParamByName('ESTADO').AsString := 'PENDIENTE';
  AsignarFiltros(unqryIncidencias, '', '', '');
  unqryIncidencias.ParamByName('REFERENCIA').AsString := '';
end;

function TdmCargasTransito.ExistenImportesReclamacion: Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Assigned(unqryTablaG.Connection) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := unqryTablaG.Connection;
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS N ' +
        '  FROM INFORMATION_SCHEMA.COLUMNS ' +
        ' WHERE TABLE_SCHEMA = DATABASE() ' +
        '   AND TABLE_NAME = ''fza_traspasos_transito_incidencias'' ' +
        '   AND COLUMN_NAME IN (''IMPORTE_RECLAMADO_TRTINC'', ' +
        '                       ''IMPORTE_INDEMNIZADO_TRTINC'')';
      oConsulta.Open;
      Result := oConsulta.FieldByName('N').AsInteger = 2;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

procedure TdmCargasTransito.AsignarFiltros(AConsulta: TUniQuery;
  const ATransito, AOrigen, ADestino: string);
begin
  AConsulta.ParamByName('EMP').AsString := Trim(UbicacionSesion.Empresa);
  AConsulta.ParamByName('TRANSITO').AsString := Trim(ATransito);
  AConsulta.ParamByName('ORIGEN').AsString := Trim(AOrigen);
  AConsulta.ParamByName('DESTINO').AsString := Trim(ADestino);
end;

procedure TdmCargasTransito.AbrirDetalles;
begin
  inherited;
  RefrescarIncidencias;
end;

function TdmCargasTransito.ListarAlmacenes(
  ASoloTransito: Boolean): TAlmacenesDestinoTraspaso;
var
  oConsulta: TUniQuery;
  sCondicion: string;
  iAlmacen: Integer;
begin
  Result := nil;
  sCondicion := 'NOT ' + SQL_CONDICION_TRANSITO;
  if ASoloTransito then
    sCondicion := SQL_CONDICION_TRANSITO;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ALM_ALM, NOMBRE_ALM_ALM ' +
      '  FROM fza_almacenes ' +
      ' WHERE ESACTIVO_ALM = ''S'' ' +
      '   AND ' + sCondicion +
      ' ORDER BY ORDEN_ALM, CODIGO_ALM_ALM';
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iAlmacen := 0;
    while not oConsulta.Eof do
    begin
      Result[iAlmacen].Codigo :=
        oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Result[iAlmacen].Nombre :=
        oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Inc(iAlmacen);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmCargasTransito.AplicarFiltros(
  const ATransito, AOrigen, ADestino, AEstado: string);
begin
  if unqryTablaG.Active then
    unqryTablaG.Close;
  AsignarFiltros(unqryTablaG, ATransito, AOrigen, ADestino);
  unqryTablaG.ParamByName('ESTADO').AsString := Trim(AEstado);
  unqryTablaG.Open;
  if unqryIncidencias.Active then
    unqryIncidencias.Close;
  AsignarFiltros(unqryIncidencias, ATransito, AOrigen, ADestino);
  unqryIncidencias.Open;
end;

procedure TdmCargasTransito.FiltrarReferencia(const AReferencia: string);
begin
  if unqryIncidencias.Active then
    unqryIncidencias.Close;
  unqryIncidencias.ParamByName('REFERENCIA').AsString := Trim(AReferencia);
  unqryIncidencias.Open;
end;

procedure TdmCargasTransito.RefrescarIncidencias;
begin
  if unqryIncidencias.Active then
    unqryIncidencias.Refresh
  else
    unqryIncidencias.Open;
end;

function TdmCargasTransito.IncidenciasCarga(
  AIdCarga: Int64): TArray<Int64>;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT ID_TRTINC ' +
      '  FROM fza_traspasos_transito_incidencias ' +
      ' WHERE ID_TRTRA_TRTINC = :CARGA ' +
      ' ORDER BY ID_TRTINC';
    oConsulta.ParamByName('CARGA').AsLargeInt := AIdCarga;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + [oConsulta.FieldByName('ID_TRTINC').AsLargeInt];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Coste de cada incidencia en el orden de AIds.
function TdmCargasTransito.CostesIncidencias(
  const AIds: TArray<Int64>): TArray<Currency>;
var
  oConsulta: TUniQuery;
  i: Integer;
begin
  SetLength(Result, Length(AIds));
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT TOTAL_COSTE_TRTINC ' +
      '  FROM fza_traspasos_transito_incidencias ' +
      ' WHERE ID_TRTINC = :ID';
    for i := 0 to High(AIds) do
    begin
      oConsulta.Close;
      oConsulta.ParamByName('ID').AsLargeInt := AIds[i];
      oConsulta.Open;
      Result[i] := oConsulta.FieldByName('TOTAL_COSTE_TRTINC').AsCurrency;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmCargasTransito.CosteTotalIncidencias(
  const AIds: TArray<Int64>): Currency;
var
  cCoste: Currency;
begin
  Result := 0;
  for cCoste in CostesIncidencias(AIds) do
    Result := Result + cCoste;
end;

function TdmCargasTransito.LeerReclamacion(
  const AIds: TArray<Int64>): TReclamacionTransito;
var
  oConsulta: TUniQuery;
  sImportes: string;
  i: Integer;
begin
  Result := Default(TReclamacionTransito);
  Result.Estado := ESTADOS_RECLAMACION_TRANSITO[0];
  sImportes := 'TOTAL_COSTE_TRTINC AS RECLAMADO, NULL AS INDEMNIZADO ';
  if FConImportes then
    sImportes :=
      'COALESCE(IMPORTE_RECLAMADO_TRTINC, TOTAL_COSTE_TRTINC) ' +
      '  AS RECLAMADO, IMPORTE_INDEMNIZADO_TRTINC AS INDEMNIZADO ';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT COALESCE(REFERENCIA_RECLAMACION_TRTINC, '''') AS REFERENCIA, ' +
      '       ESTADO_RECLAMACION_TRTINC AS ESTADO, ' + sImportes +
      '  FROM fza_traspasos_transito_incidencias ' +
      ' WHERE ID_TRTINC = :ID';
    for i := 0 to High(AIds) do
    begin
      oConsulta.Close;
      oConsulta.ParamByName('ID').AsLargeInt := AIds[i];
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        if i = 0 then
        begin
          Result.Referencia := oConsulta.FieldByName('REFERENCIA').AsString;
          Result.Estado := oConsulta.FieldByName('ESTADO').AsString;
        end;
        Result.ImporteReclamado := Result.ImporteReclamado +
          oConsulta.FieldByName('RECLAMADO').AsCurrency;
        if not oConsulta.FieldByName('INDEMNIZADO').IsNull then
        begin
          Result.ConIndemnizado := True;
          Result.ImporteIndemnizado := Result.ImporteIndemnizado +
            oConsulta.FieldByName('INDEMNIZADO').AsCurrency;
        end;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmCargasTransito.ActualizarReclamacion(AConsulta: TUniQuery;
  AId: Int64; const AReclamacion: TReclamacionTransito;
  AReclamado, AIndemnizado: Currency; AReclamadoEsCoste: Boolean);
begin
  AConsulta.ParamByName('REFERENCIA').AsString :=
    Copy(Trim(AReclamacion.Referencia), 1, 100);
  AConsulta.ParamByName('ESTADO').AsString := AReclamacion.Estado;
  AConsulta.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  AConsulta.ParamByName('ID').AsLargeInt := AId;
  if FConImportes then
  begin
    // Reclamar el coste se guarda vacío: sigue al coste de la incidencia.
    AConsulta.ParamByName('RECLAMADO').DataType := ftCurrency;
    if AReclamadoEsCoste then
      AConsulta.ParamByName('RECLAMADO').Clear
    else
      AConsulta.ParamByName('RECLAMADO').AsCurrency := AReclamado;
    AConsulta.ParamByName('INDEMNIZADO').DataType := ftCurrency;
    if AReclamacion.ConIndemnizado then
      AConsulta.ParamByName('INDEMNIZADO').AsCurrency := AIndemnizado
    else
      AConsulta.ParamByName('INDEMNIZADO').Clear;
  end;
  AConsulta.ExecSQL;
end;

// Todas o ninguna: la reclamación es una sola aunque afecte a varias
// incidencias (FZ-ISSUE-728).
procedure TdmCargasTransito.GrabarReclamacion(const AIds: TArray<Int64>;
  const AReclamacion: TReclamacionTransito);
var
  oConsulta: TUniQuery;
  aCostes: TArray<Currency>;
  aReclamado: TArray<Currency>;
  aIndemnizado: TArray<Currency>;
  cCosteTotal: Currency;
  cCoste: Currency;
  i: Integer;
begin
  if not MatchStr(AReclamacion.Estado, ESTADOS_RECLAMACION_TRANSITO) then
    raise EArgumentException.Create(SErrorEstadoReclamacionTransito);
  if (AReclamacion.ImporteReclamado < 0) or
     (AReclamacion.ImporteIndemnizado < 0) then
    raise EArgumentException.Create(SErrorImporteReclamacionTransito);
  if Length(AIds) > 0 then
  begin
    aCostes := CostesIncidencias(AIds);
    cCosteTotal := 0;
    for cCoste in aCostes do
      cCosteTotal := cCosteTotal + cCoste;
    aReclamado := RepartirImporteReclamacion(
      AReclamacion.ImporteReclamado, aCostes);
    aIndemnizado := RepartirImporteReclamacion(
      AReclamacion.ImporteIndemnizado, aCostes);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := unqryTablaG.Connection;
      oConsulta.SQL.Text :=
        'UPDATE fza_traspasos_transito_incidencias ' +
        '   SET REFERENCIA_RECLAMACION_TRTINC = NULLIF(:REFERENCIA, ''''), ' +
        '       ESTADO_RECLAMACION_TRTINC = :ESTADO, ';
      if FConImportes then
        oConsulta.SQL.Add(
          '       IMPORTE_RECLAMADO_TRTINC = :RECLAMADO, ' +
          '       IMPORTE_INDEMNIZADO_TRTINC = :INDEMNIZADO, ');
      oConsulta.SQL.Add(
        '       USUARIO_MODIF = :USUARIO ' +
        ' WHERE ID_TRTINC = :ID');
      oConsulta.Connection.StartTransaction;
      try
        for i := 0 to High(AIds) do
          ActualizarReclamacion(oConsulta, AIds[i], AReclamacion,
            aReclamado[i], aIndemnizado[i],
            AReclamacion.ImporteReclamado = cCosteTotal);
        oConsulta.Connection.Commit;
      except
        oConsulta.Connection.Rollback;
        raise;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

initialization
  RegistrarDataModule(TdmCargasTransito);
  ForceReferenceToClass(TdmCargasTransito);
end.
