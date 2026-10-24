{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDocumentosTrabajo                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Data module de Documentos de Trabajo.                                     }
{******************************************************************************}
unit UniDataDocumentosTrabajo;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes, Vcl.ComCtrls, cxListView,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen;

type
  TDocTrabajoAmbito = (dtaPropios, dtaCompartidos, dtaArchivados);

  TdmDocumentosTrabajo = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure unqryTablaGBeforeInsertDTR(DataSet: TDataSet);
    procedure unqryTablaGBeforeEdit(DataSet: TDataSet);
    procedure unqryTablaGBeforeDelete(DataSet: TDataSet);
    procedure unqryTablaGAfterInsert(DataSet: TDataSet);
    procedure unqryTablaGBeforePost(DataSet: TDataSet);
    procedure unqryLineasAfterInsert(DataSet: TDataSet);
    procedure unqryLineasBeforeEdit(DataSet: TDataSet);
    procedure unqryLineasBeforeDelete(DataSet: TDataSet);
    procedure unqryLineasBeforePost(DataSet: TDataSet);
    procedure unqryCompartidosAfterInsert(DataSet: TDataSet);
    procedure unqryCompartidosBeforeEdit(DataSet: TDataSet);
    procedure unqryCompartidosBeforeDelete(DataSet: TDataSet);
    procedure unqryCompartidosBeforePost(DataSet: TDataSet);
    procedure unqryProtegidaAfterUpdateExecute(Sender: TDataSet;
      StatementTypes: TStatementTypes; Params: TDAParams);
  private
    FAmbito: TDocTrabajoAmbito;
    procedure ConfigurarQueries;
    procedure ConfigurarSqlCabecera;
    procedure ConfigurarQueryCompartidos;
    function SqlSelectLineas: string;
    procedure ExpandirEtiquetasPorCantidadDoc(ADmArt: TObject;
                                              AIdDtr: Int64;
                                              const AAlmacenesCsv: string);
    function ObtenerAlmacenesSql(const AAlmacenesCsv: string): string;
    function ObtenerSkusDocumentoCsv(AIdDtr: Int64;
                                     const AAlmacenesCsv: string): string;
    function ExisteDestinoCompartir(const ADestino, ATipo: string): Boolean;
    function NormalizarTipoDestino(const ADestino, ATipo: string): string;
    function SiguienteLinea: string;
    function EsPropietarioDocumentoActual: Boolean;
    function ActualizarEstadoDocumentoActual(
      const AEstado: string): Boolean;
    procedure RecargarAmbitoActual;
  public
    unqryLineas: TUniQuery;
    unqryCompartidos: TUniQuery;
    dsLineas: TDataSource;
    dsCompartidos: TDataSource;
    property Ambito: TDocTrabajoAmbito read FAmbito;
    // El form empuja su dsTablaG; el DM ya no usa GetOwnerForm.
    procedure AsignarMaestroCabecera(ADataSource: TDataSource); override;
    procedure AbrirDetalles; override;
    procedure CambiarAmbito(const AAmbito: TDocTrabajoAmbito);
    function PuedeEditarDocumentoActual: Boolean;
    function PuedeEnviarDocumentoActual: Boolean;
    function PuedeArchivarDocumentoActual: Boolean;
    // ENVIADO o ARCHIVADO -> CREADO: el documento vuelve a ser editable
    // y enviable para reutilizarlo.
    function PuedeReabrirDocumentoActual: Boolean;
    function MarcarDocumentoActualEnviado: Boolean;
    function ArchivarDocumentoActual: Boolean;
    function ReabrirDocumentoActual: Boolean;
    procedure CargarAlmacenesEtiquetasDoc(AIdDtr: Int64; ALV: TcxListView);
    function CompartirDocumentoActual(const ADestino, ATipo: string): Boolean;
    procedure CrearDataSetEtiquetasDoc(ADmArt: TObject; AIdDtr: Int64;
                                       const ACodTarifa,
                                             AAlmacenesCsv: string;
                                       AFecha: TDateTime);
    // Contrato ColumnSKUcxGrid: rellena ATTR1..5_VALOR_DTL y
    // NUM_ATRIBUTOS_DTL troceando el SKU de cada linea que aun los
    // tenga vacios (idempotente por linea; columnas reales, el Post
    // actualiza BD).
    procedure DesempaquetarAtributosLineas;
    // FZ-ISSUE-334: si otra pantalla (Distribuir entre tiendas, otro
    // puesto) cambió el estado del documento actual, recarga su cabecera y
    // sus líneas. True si lo ha recargado.
    function RefrescarDocumentoSiCambio: Boolean;
    procedure RecargarDocumentoActual;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
  UniDataTarifasPrecioSql,
  inLibLineaSku,
  System.Generics.Collections, System.Variants,
  UniDataArticulos, inLibDocumentosTrabajoEstados,
  inLibMsgArticulos, inLibMsgVentas;

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TdmDocumentosTrabajo.DataModuleCreate(Sender: TObject);
begin
  inherited;
  FAmbito := dtaPropios;
  unqryLineas := TUniQuery.Create(Self);
  unqryCompartidos := TUniQuery.Create(Self);
  dsLineas := TDataSource.Create(Self);
  dsCompartidos := TDataSource.Create(Self);
  dsLineas.DataSet := unqryLineas;
  dsCompartidos.DataSet := unqryCompartidos;
  ConfigurarQueries;
end;

procedure TdmDocumentosTrabajo.DataModuleDestroy(Sender: TObject);
begin
  if Assigned(unqryLineas) then
  begin
    unqryLineas.Close;
  end;
  if Assigned(unqryCompartidos) then
  begin
    unqryCompartidos.Close;
  end;
  inherited;
end;

procedure TdmDocumentosTrabajo.ConfigurarSqlCabecera;
begin
  if FAmbito = dtaCompartidos then
  begin
    unqryTablaG.SQL.Text :=
      'SELECT DISTINCT d.* ' +
      '  FROM fza_documentos_trabajo d ' +
      '  JOIN fza_documentos_trabajo_compartidos c ' +
      '    ON c.ID_DTR_DTC = d.ID_DTR ' +
      ' WHERE ((COALESCE(c.TIPO_DESTINO_DTC, ''USUARIO'') = ''USUARIO'' ' +
      '         AND COALESCE(NULLIF(c.USUARIO_GRUPO_DTC, ''''), ' +
      '                      c.USUARIO_DTC) = :USUARIO) ' +
      '    OR (COALESCE(c.TIPO_DESTINO_DTC, ''USUARIO'') = ''GRUPO'' ' +
      '        AND COALESCE(NULLIF(c.USUARIO_GRUPO_DTC, ''''), ' +
      '                     c.USUARIO_DTC) = :GRUPO)) ' +
      '   AND ' + CondicionSqlDocumentoTrabajoActivo('d.ESTADO_DTR') +
      ClausulaOrdenSqlDocumentosTrabajo('d');
  end
  else if FAmbito = dtaArchivados then
  begin
    unqryTablaG.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_documentos_trabajo ' +
      ' WHERE USUARIO_DTR = :USUARIO ' +
      '   AND ' +
      CondicionSqlDocumentoTrabajoArchivado('ESTADO_DTR') +
      ClausulaOrdenSqlDocumentosTrabajo('');
  end
  else
  begin
    unqryTablaG.SQL.Text :=
      'SELECT * ' +
      '  FROM fza_documentos_trabajo ' +
      ' WHERE USUARIO_DTR = :USUARIO ' +
      '   AND ' + CondicionSqlDocumentoTrabajoActivo('ESTADO_DTR') +
      ClausulaOrdenSqlDocumentosTrabajo('');
  end;
  unqryTablaG.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
  if FAmbito = dtaCompartidos then
  begin
    unqryTablaG.ParamByName('GRUPO').AsString := IdentidadSesion.Grupo;
  end;
end;

function TdmDocumentosTrabajo.SqlSelectLineas: string;
begin
  Result :=
    'SELECT l.*, ' +
    '       COALESCE(a.CODIGO_FAM_ART, '''') AS CODIGO_FAM_ART, ' +
    '       COALESCE(f.DESCRIPCION_FAM, '''') AS DESCRIPCION_FAM, ' +
    '       COALESCE(ap.CODIGO_PRV_AP, '''') AS CODIGO_PRV_AP, ' +
    '       COALESCE(NULLIF(p.NOMBRE_PRV, ''''), ' +
    '                p.RAZON_SOCIAL_PRV, '''') AS NOMBRE_PRV, ' +
    '       COALESCE(ap.REF_PROVEEDOR_AP, '''') AS REF_PROVEEDOR, ' +
    '       COALESCE((SELECT COALESCE(pe.VALOR_PV, ' +
    '                                pe.VALOR_LIBRE_ARTPROP) ' +
    '                   FROM vi_articulos_propiedades_efectivas pe ' +
    '                  WHERE pe.CODIGO_ART = l.CODIGO_ART_DTL ' +
    '                    AND pe.CODIGO_UNIDAD_SKU = ' +
    '                        l.CODIGO_UNIDAD_DTL ' +
    '                    AND pe.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    '                  LIMIT 1), '''') AS TEMPORADA_ART, ' +
    '       COALESCE(tar.CODIGO_TAR_ARTTAR, '''') ' +
    '         AS CODIGO_TAR_ARTTAR, ' +
    '       COALESCE(tar.NOMBRE_TAR_TAR, '''') AS NOMBRE_TAR_TAR, ' +
    '       COALESCE((SELECT at.PRECIO_FINAL_ARTTAR ' +
    '                   FROM fza_articulos_tarifas at ' +
    '                  WHERE at.CODIGO_UNICO_ARTTAR = ' +
    '                        ({PRECIO_TARIFA})), 0) ' +
    '         AS PRECIO_FINAL_ARTTAR ' +
    '  FROM fza_documentos_trabajo_lineas l ' +
    '  LEFT JOIN fza_articulos a ' +
    '    ON a.CODIGO_ART_ART = l.CODIGO_ART_DTL ' +
    '  LEFT JOIN fza_articulos_familias f ' +
    '    ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_articulos_proveedores ap ' +
    '    ON ap.CODIGO_ART_AP = l.CODIGO_ART_DTL ' +
    '   AND ap.CODIGO_PRV_AP = ' +
    '       (SELECT apx.CODIGO_PRV_AP ' +
    '          FROM fza_articulos_proveedores apx ' +
    '         WHERE apx.CODIGO_ART_AP = l.CODIGO_ART_DTL ' +
    '         ORDER BY CASE ' +
    '                    WHEN apx.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
    '                    THEN 0 ELSE 1 ' +
    '                  END, ' +
    '                  apx.FECHA_VALIDEZ_AP DESC, ' +
    '                  apx.CODIGO_PRV_AP ' +
    '         LIMIT 1) ' +
    '  LEFT JOIN fza_proveedores p ' +
    '    ON p.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    '  LEFT JOIN fza_tarifas tar ' +
    '    ON tar.CODIGO_TAR_ARTTAR = ' +
    '       (SELECT t.CODIGO_TAR_ARTTAR ' +
    '          FROM fza_tarifas t ' +
    '         WHERE t.ESACTIVO_ARTTAR = ''S'' ' +
    '         ORDER BY (t.ORDEN_TAR IS NULL), t.ORDEN_TAR, ' +
    '                  t.CODIGO_TAR_ARTTAR ' +
    '         LIMIT 1) ';
  Result := StringReplace(Result, '{PRECIO_TARIFA}',
    SqlSeleccionPrecioTarifa('l.CODIGO_ART_DTL',
      'l.CODIGO_UNIDAD_DTL', 'tar.CODIGO_TAR_ARTTAR', 'CURRENT_DATE'),
    [rfReplaceAll]);
end;

procedure TdmDocumentosTrabajo.AsignarMaestroCabecera(
  ADataSource: TDataSource);
begin
  inherited;
  unqryLineas.MasterSource := ADataSource;
  unqryCompartidos.MasterSource := ADataSource;
end;

procedure TdmDocumentosTrabajo.ConfigurarQueries;
begin
  ConfigurarSqlCabecera;
  unqryTablaG.KeyFields := 'ID_DTR';
  unqryTablaG.Options.StrictUpdate := True;
  unqryTablaG.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo ' +
    '  (TITULO_DTR, TIPO_DTR, ESTADO_DTR, CODIGO_EMP_DTR, CODIGO_ALM_DTR, ' +
    '   USUARIO_DTR, INSTANTE_DOCUMENTO_DTR, OBSERVACIONES_DTR, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES ' +
    '  (:TITULO_DTR, :TIPO_DTR, :ESTADO_DTR, :CODIGO_EMP_DTR, ' +
    '   :CODIGO_ALM_DTR, :USUARIO_DTR, :INSTANTE_DOCUMENTO_DTR, ' +
    '   :OBSERVACIONES_DTR, :INSTANTE_ALTA, :USUARIO_ALTA, ' +
    '   :USUARIO_MODIF)';
  unqryTablaG.SQLUpdate.Text :=
    'UPDATE fza_documentos_trabajo SET ' +
    '  TITULO_DTR = :TITULO_DTR, ' +
    '  TIPO_DTR = :TIPO_DTR, ' +
    '  ESTADO_DTR = :ESTADO_DTR, ' +
    '  CODIGO_EMP_DTR = :CODIGO_EMP_DTR, ' +
    '  CODIGO_ALM_DTR = :CODIGO_ALM_DTR, ' +
    '  USUARIO_DTR = :USUARIO_DTR, ' +
    '  INSTANTE_DOCUMENTO_DTR = :INSTANTE_DOCUMENTO_DTR, ' +
    '  OBSERVACIONES_DTR = :OBSERVACIONES_DTR, ' +
    '  USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE ID_DTR = :Old_ID_DTR ' +
    '  AND USUARIO_DTR = :Old_USUARIO_DTR ' +
    '  AND ' + CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR');
  unqryTablaG.SQLDelete.Text :=
    'DELETE FROM fza_documentos_trabajo ' +
    ' WHERE ID_DTR = :Old_ID_DTR ' +
    '   AND USUARIO_DTR = :Old_USUARIO_DTR ' +
    '   AND ' + CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR');
  unqryTablaG.SQLRefresh.Text :=
    'SELECT * FROM fza_documentos_trabajo WHERE ID_DTR = :ID_DTR';
  unqryTablaG.SQLLock.Text :=
    'SELECT * FROM fza_documentos_trabajo ' +
    ' WHERE ID_DTR = :Old_ID_DTR ' +
    '   AND USUARIO_DTR = :Old_USUARIO_DTR ' +
    '   AND ' + CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR') +
    ' FOR UPDATE';
  unqryTablaG.BeforeInsert := unqryTablaGBeforeInsertDTR;
  unqryTablaG.BeforeEdit := unqryTablaGBeforeEdit;
  unqryTablaG.AfterInsert := unqryTablaGAfterInsert;
  unqryTablaG.BeforeDelete := unqryTablaGBeforeDelete;
  unqryTablaG.BeforePost := unqryTablaGBeforePost;
  unqryTablaG.AfterUpdateExecute := unqryProtegidaAfterUpdateExecute;
  unqryLineas.Connection := ConexionPrincipal;
  unqryLineas.SQL.Text := SqlSelectLineas +
    ' WHERE l.ID_DTR_DTL = :ID_DTR ' +
    ' ORDER BY l.LINEA_DTL';
  unqryLineas.KeyFields := 'ID_DTL';
  unqryLineas.Options.StrictUpdate := True;
  unqryLineas.MasterFields := 'ID_DTR';
  unqryLineas.DetailFields := 'ID_DTR_DTL';
  if FMaestroCabecera <> nil then
  begin
    unqryLineas.MasterSource := FMaestroCabecera;
  end;
  // ATTR1..5 / NUM_ATRIBUTOS / ID_AC_PIVOT: columnas del contrato
  // ColumnSKUcxGrid (documentos_trabajo_columnas_sku.sql).
  unqryLineas.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo_lineas ' +
    '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
    '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
    '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
    '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
    '   ORIGEN_DTL, OBSERVACIONES_DTL, ' +
    '   ATTR1_VALOR_DTL, ATTR1_NOMBRE_DTL, ' +
    '   ATTR2_VALOR_DTL, ATTR2_NOMBRE_DTL, ' +
    '   ATTR3_VALOR_DTL, ATTR3_NOMBRE_DTL, ' +
    '   ATTR4_VALOR_DTL, ATTR4_NOMBRE_DTL, ' +
    '   ATTR5_VALOR_DTL, ATTR5_NOMBRE_DTL, ' +
    '   NUM_ATRIBUTOS_DTL, ID_AC_PIVOT_DTL, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, ' +
    '   USUARIO_MODIF) ' +
    'SELECT ' +
    '  :ID_DTR_DTL, :LINEA_DTL, :CODIGO_ART_DTL, :CODIGO_UNIDAD_DTL, ' +
    '   :CODIGO_ALM_DTL, :LOTE_DTL, :FECHA_CADUCIDAD_DTL, ' +
    '   :DESCRIPCION_ARTICULO_DTL, :DESCRIPCION_UNIDAD_DTL, ' +
    '   :CANTIDAD_STOCK_DTL, :CANTIDAD_DTL, :INSTANTE_STOCK_DTL, ' +
    '   :ORIGEN_DTL, :OBSERVACIONES_DTL, ' +
    '   :ATTR1_VALOR_DTL, :ATTR1_NOMBRE_DTL, ' +
    '   :ATTR2_VALOR_DTL, :ATTR2_NOMBRE_DTL, ' +
    '   :ATTR3_VALOR_DTL, :ATTR3_NOMBRE_DTL, ' +
    '   :ATTR4_VALOR_DTL, :ATTR4_NOMBRE_DTL, ' +
    '   :ATTR5_VALOR_DTL, :ATTR5_NOMBRE_DTL, ' +
    '   :NUM_ATRIBUTOS_DTL, :ID_AC_PIVOT_DTL, ' +
    '   :INSTANTE_ALTA, ' +
    '   :USUARIO_ALTA, :USUARIO_MODIF ' +
    '  FROM fza_documentos_trabajo dtr_guard ' +
    ' WHERE dtr_guard.ID_DTR = :ID_DTR_DTL ' +
    '   AND dtr_guard.USUARIO_DTR = :USUARIO_MODIF ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR');
  unqryLineas.SQLUpdate.Text :=
    'UPDATE fza_documentos_trabajo_lineas l ' +
    '  JOIN fza_documentos_trabajo dtr_guard ' +
    '    ON dtr_guard.ID_DTR = l.ID_DTR_DTL ' +
    '   AND dtr_guard.USUARIO_DTR = :USUARIO_MODIF ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR') + ' ' +
    'SET ' +
    '  l.ID_DTR_DTL = :ID_DTR_DTL, ' +
    '  l.LINEA_DTL = :LINEA_DTL, ' +
    '  l.CODIGO_ART_DTL = :CODIGO_ART_DTL, ' +
    '  l.CODIGO_UNIDAD_DTL = :CODIGO_UNIDAD_DTL, ' +
    '  l.CODIGO_ALM_DTL = :CODIGO_ALM_DTL, ' +
    '  l.LOTE_DTL = :LOTE_DTL, ' +
    '  l.FECHA_CADUCIDAD_DTL = :FECHA_CADUCIDAD_DTL, ' +
    '  l.DESCRIPCION_ARTICULO_DTL = :DESCRIPCION_ARTICULO_DTL, ' +
    '  l.DESCRIPCION_UNIDAD_DTL = :DESCRIPCION_UNIDAD_DTL, ' +
    '  l.CANTIDAD_STOCK_DTL = :CANTIDAD_STOCK_DTL, ' +
    '  l.CANTIDAD_DTL = :CANTIDAD_DTL, ' +
    '  l.INSTANTE_STOCK_DTL = :INSTANTE_STOCK_DTL, ' +
    '  l.ORIGEN_DTL = :ORIGEN_DTL, ' +
    '  l.OBSERVACIONES_DTL = :OBSERVACIONES_DTL, ' +
    '  l.ATTR1_VALOR_DTL = :ATTR1_VALOR_DTL, ' +
    '  l.ATTR1_NOMBRE_DTL = :ATTR1_NOMBRE_DTL, ' +
    '  l.ATTR2_VALOR_DTL = :ATTR2_VALOR_DTL, ' +
    '  l.ATTR2_NOMBRE_DTL = :ATTR2_NOMBRE_DTL, ' +
    '  l.ATTR3_VALOR_DTL = :ATTR3_VALOR_DTL, ' +
    '  l.ATTR3_NOMBRE_DTL = :ATTR3_NOMBRE_DTL, ' +
    '  l.ATTR4_VALOR_DTL = :ATTR4_VALOR_DTL, ' +
    '  l.ATTR4_NOMBRE_DTL = :ATTR4_NOMBRE_DTL, ' +
    '  l.ATTR5_VALOR_DTL = :ATTR5_VALOR_DTL, ' +
    '  l.ATTR5_NOMBRE_DTL = :ATTR5_NOMBRE_DTL, ' +
    '  l.NUM_ATRIBUTOS_DTL = :NUM_ATRIBUTOS_DTL, ' +
    '  l.ID_AC_PIVOT_DTL = :ID_AC_PIVOT_DTL, ' +
    '  l.USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE l.ID_DTL = :Old_ID_DTL ' +
    '  AND l.ID_DTR_DTL = :Old_ID_DTR_DTL ' +
    '  AND :ID_DTR_DTL = :Old_ID_DTR_DTL ' +
    '  AND dtr_guard.ID_DTR = :Old_ID_DTR_DTL';
  unqryLineas.SQLDelete.Text :=
    'DELETE l ' +
    '  FROM fza_documentos_trabajo_lineas l ' +
    '  JOIN fza_documentos_trabajo dtr_guard ' +
    '    ON dtr_guard.ID_DTR = l.ID_DTR_DTL ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR') + ' ' +
    ' WHERE l.ID_DTL = :Old_ID_DTL ' +
    '   AND l.ID_DTR_DTL = :Old_ID_DTR_DTL';
  unqryLineas.SQLRefresh.Text := SqlSelectLineas +
    ' WHERE l.ID_DTL = :ID_DTL';
  unqryLineas.SQLLock.Text :=
    'SELECT l.* ' +
    '  FROM fza_documentos_trabajo_lineas l ' +
    '  JOIN fza_documentos_trabajo dtr_guard ' +
    '    ON dtr_guard.ID_DTR = l.ID_DTR_DTL ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR') + ' ' +
    ' WHERE l.ID_DTL = :Old_ID_DTL ' +
    '   AND l.ID_DTR_DTL = :Old_ID_DTR_DTL ' +
    ' FOR UPDATE';
  unqryLineas.BeforeInsert := unqryLineasBeforeEdit;
  unqryLineas.BeforeEdit := unqryLineasBeforeEdit;
  unqryLineas.AfterInsert := unqryLineasAfterInsert;
  unqryLineas.BeforeDelete := unqryLineasBeforeDelete;
  unqryLineas.BeforePost := unqryLineasBeforePost;
  unqryLineas.AfterUpdateExecute := unqryProtegidaAfterUpdateExecute;
  ConfigurarQueryCompartidos;
end;

procedure TdmDocumentosTrabajo.ConfigurarQueryCompartidos;
begin
  unqryCompartidos.Connection := ConexionPrincipal;
  unqryCompartidos.SQL.Text :=
    'SELECT * ' +
    '  FROM fza_documentos_trabajo_compartidos ' +
    ' WHERE ID_DTR_DTC = :ID_DTR ' +
    ' ORDER BY TIPO_DESTINO_DTC, USUARIO_GRUPO_DTC';
  unqryCompartidos.KeyFields := 'ID_DTC';
  unqryCompartidos.Options.StrictUpdate := True;
  unqryCompartidos.MasterFields := 'ID_DTR';
  unqryCompartidos.DetailFields := 'ID_DTR_DTC';
  if FMaestroCabecera <> nil then
  begin
    unqryCompartidos.MasterSource := FMaestroCabecera;
  end;
  unqryCompartidos.SQLInsert.Text :=
    'INSERT INTO fza_documentos_trabajo_compartidos ' +
    '  (ID_DTR_DTC, USUARIO_DTC, USUARIO_GRUPO_DTC, TIPO_DESTINO_DTC, ' +
    '   PERMISO_DTC, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT ' +
    '  :ID_DTR_DTC, :USUARIO_DTC, :USUARIO_GRUPO_DTC, ' +
    '   :TIPO_DESTINO_DTC, :PERMISO_DTC, :INSTANTE_ALTA, ' +
    '   :USUARIO_ALTA, :USUARIO_MODIF ' +
    '  FROM fza_documentos_trabajo dtr_guard ' +
    ' WHERE dtr_guard.ID_DTR = :ID_DTR_DTC ' +
    '   AND dtr_guard.USUARIO_DTR = :USUARIO_MODIF ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR');
  unqryCompartidos.SQLUpdate.Text :=
    'UPDATE fza_documentos_trabajo_compartidos c ' +
    '  JOIN fza_documentos_trabajo dtr_guard ' +
    '    ON dtr_guard.ID_DTR = c.ID_DTR_DTC ' +
    '   AND dtr_guard.USUARIO_DTR = :USUARIO_MODIF ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR') + ' ' +
    'SET ' +
    '  c.ID_DTR_DTC = :ID_DTR_DTC, ' +
    '  c.USUARIO_DTC = :USUARIO_DTC, ' +
    '  c.USUARIO_GRUPO_DTC = :USUARIO_GRUPO_DTC, ' +
    '  c.TIPO_DESTINO_DTC = :TIPO_DESTINO_DTC, ' +
    '  c.PERMISO_DTC = :PERMISO_DTC, ' +
    '  c.USUARIO_MODIF = :USUARIO_MODIF ' +
    'WHERE c.ID_DTC = :Old_ID_DTC ' +
    '  AND c.ID_DTR_DTC = :Old_ID_DTR_DTC ' +
    '  AND :ID_DTR_DTC = :Old_ID_DTR_DTC ' +
    '  AND dtr_guard.ID_DTR = :Old_ID_DTR_DTC';
  unqryCompartidos.SQLDelete.Text :=
    'DELETE c ' +
    '  FROM fza_documentos_trabajo_compartidos c ' +
    '  JOIN fza_documentos_trabajo dtr_guard ' +
    '    ON dtr_guard.ID_DTR = c.ID_DTR_DTC ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR') + ' ' +
    ' WHERE c.ID_DTC = :Old_ID_DTC ' +
    '   AND c.ID_DTR_DTC = :Old_ID_DTR_DTC';
  unqryCompartidos.SQLRefresh.Text :=
    'SELECT * FROM fza_documentos_trabajo_compartidos WHERE ID_DTC = :ID_DTC';
  unqryCompartidos.SQLLock.Text :=
    'SELECT c.* ' +
    '  FROM fza_documentos_trabajo_compartidos c ' +
    '  JOIN fza_documentos_trabajo dtr_guard ' +
    '    ON dtr_guard.ID_DTR = c.ID_DTR_DTC ' +
    '   AND ' +
    CondicionSqlDocumentoTrabajoCreado('dtr_guard.ESTADO_DTR') + ' ' +
    ' WHERE c.ID_DTC = :Old_ID_DTC ' +
    '   AND c.ID_DTR_DTC = :Old_ID_DTR_DTC ' +
    ' FOR UPDATE';
  unqryCompartidos.BeforeInsert := unqryCompartidosBeforeEdit;
  unqryCompartidos.BeforeEdit := unqryCompartidosBeforeEdit;
  unqryCompartidos.AfterInsert := unqryCompartidosAfterInsert;
  unqryCompartidos.BeforeDelete := unqryCompartidosBeforeDelete;
  unqryCompartidos.BeforePost := unqryCompartidosBeforePost;
  unqryCompartidos.AfterUpdateExecute := unqryProtegidaAfterUpdateExecute;
end;

function TdmDocumentosTrabajo.ObtenerAlmacenesSql(
  const AAlmacenesCsv: string): string;
var
  i: Integer;
  lst: TStringList;
  sCodigo: string;
begin
  Result := '';
  if Trim(AAlmacenesCsv) <> '' then
  begin
    lst := TStringList.Create;
    try
      lst.StrictDelimiter := True;
      lst.Delimiter := ',';
      lst.DelimitedText := AAlmacenesCsv;
      for i := 0 to lst.Count - 1 do
      begin
        sCodigo := Trim(lst[i]);
        if sCodigo <> '' then
        begin
          if Result <> '' then
          begin
            Result := Result + ',';
          end;
          Result := Result + QuotedStr(sCodigo);
        end;
      end;
    finally
      FreeAndNil(lst);
    end;
  end;
end;

function TdmDocumentosTrabajo.ObtenerSkusDocumentoCsv(AIdDtr: Int64;
  const AAlmacenesCsv: string): string;
var
  q: TUniQuery;
  sAlmacenes: string;
begin
  Result := '';
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
    q.SQL.Text :=
      'SELECT DISTINCT CODIGO_UNIDAD_DTL ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID_DTR ' +
      '   AND COALESCE(CODIGO_UNIDAD_DTL, '''') <> ''''';
    if sAlmacenes <> '' then
    begin
      q.SQL.Add('   AND CODIGO_ALM_DTL IN (' + sAlmacenes + ')');
    end;
    q.SQL.Add(' ORDER BY CODIGO_UNIDAD_DTL');
    q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
    q.Open;
    while not q.Eof do
    begin
      if Result <> '' then
      begin
        Result := Result + ',';
      end;
      Result := Result + QuotedStr(
        q.FieldByName('CODIGO_UNIDAD_DTL').AsString);
      q.Next;
    end;
  finally
    FreeAndNil(q);
  end;
end;

procedure TdmDocumentosTrabajo.CargarAlmacenesEtiquetasDoc(AIdDtr: Int64;
  ALV: TcxListView);
var
  q: TUniQuery;
  oItem: TListItem;
begin
  if ALV <> nil then
  begin
    ALV.Items.BeginUpdate;
    try
      ALV.Clear;
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionPrincipal;
        q.SQL.Text :=
          'SELECT DISTINCT L.CODIGO_ALM_DTL AS COD, ' +
          '       COALESCE(A.NOMBRE_ALM_ALM, L.CODIGO_ALM_DTL) AS NOM ' +
          '  FROM fza_documentos_trabajo_lineas L ' +
          '  LEFT JOIN fza_almacenes A ' +
          '    ON A.CODIGO_ALM_ALM = L.CODIGO_ALM_DTL ' +
          ' WHERE L.ID_DTR_DTL = :ID_DTR ' +
          '   AND COALESCE(L.CODIGO_ALM_DTL, '''') <> '''' ' +
          ' ORDER BY COD';
        q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
        q.Open;
        while not q.Eof do
        begin
          oItem := ALV.Items.Add;
          oItem.Caption := q.FieldByName('COD').AsString;
          oItem.SubItems.Add(q.FieldByName('NOM').AsString);
          oItem.Checked := True;
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;
    finally
      ALV.Items.EndUpdate;
    end;
  end;
end;

procedure TdmDocumentosTrabajo.ExpandirEtiquetasPorCantidadDoc(ADmArt: TObject;
  AIdDtr: Int64; const AAlmacenesCsv: string);
var
  q: TUniQuery;
  oDmArt: TdmArticulos;
  oCantidades: TDictionary<string, Integer>;
  Filas: array of array of Variant;
  i, j, k, iOriginales, iSkuIdx, iStockIdx, iCantidad: Integer;
  sAlmacenes, sSku: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    oCantidades := TDictionary<string, Integer>.Create;
    try
      q := TUniQuery.Create(nil);
      try
        q.Connection := ConexionPrincipal;
        sAlmacenes := ObtenerAlmacenesSql(AAlmacenesCsv);
        q.SQL.Text :=
          'SELECT CODIGO_UNIDAD_DTL, ' +
          '       SUM(COALESCE(CANTIDAD_DTL, 0)) AS CANTIDAD ' +
          '  FROM fza_documentos_trabajo_lineas ' +
          ' WHERE ID_DTR_DTL = :ID_DTR ' +
          '   AND COALESCE(CODIGO_UNIDAD_DTL, '''') <> ''''';
        if sAlmacenes <> '' then
        begin
          q.SQL.Add('   AND CODIGO_ALM_DTL IN (' + sAlmacenes + ')');
        end;
        q.SQL.Add(' GROUP BY CODIGO_UNIDAD_DTL');
        q.ParamByName('ID_DTR').AsLargeInt := AIdDtr;
        q.Open;
        while not q.Eof do
        begin
          iCantidad := Trunc(q.FieldByName('CANTIDAD').AsFloat);
          sSku := q.FieldByName('CODIGO_UNIDAD_DTL').AsString;
          if (sSku <> '') and (iCantidad > 0) then
          begin
            oCantidades.AddOrSetValue(sSku, iCantidad);
          end;
          q.Next;
        end;
      finally
        FreeAndNil(q);
      end;

      if oDmArt.cdsEtiquetasArt.Active then
      begin
        if (not oDmArt.cdsEtiquetasArt.IsEmpty) and
           (oDmArt.cdsEtiquetasArt.FindField('CODIGO_UNIDAD_SKU') <> nil) then
        begin
          iSkuIdx := oDmArt.cdsEtiquetasArt.FieldByName(
            'CODIGO_UNIDAD_SKU').Index;
          iStockIdx := -1;
          if oDmArt.cdsEtiquetasArt.FindField('STOCK_FILTRADO') <> nil then
          begin
            iStockIdx := oDmArt.cdsEtiquetasArt.FieldByName(
              'STOCK_FILTRADO').Index;
          end;
          oDmArt.cdsEtiquetasArt.DisableControls;
          oDmArt.cdsEtiquetasArt.DisableConstraints;
          try
            for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
            begin
              oDmArt.cdsEtiquetasArt.Fields[j].ReadOnly := False;
              oDmArt.cdsEtiquetasArt.Fields[j].Required := False;
            end;
            iOriginales := oDmArt.cdsEtiquetasArt.RecordCount;
            SetLength(Filas, iOriginales);
            oDmArt.cdsEtiquetasArt.First;
            for i := 0 to iOriginales - 1 do
            begin
              SetLength(Filas[i], oDmArt.cdsEtiquetasArt.FieldCount);
              for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
              begin
                Filas[i][j] := oDmArt.cdsEtiquetasArt.Fields[j].Value;
              end;
              oDmArt.cdsEtiquetasArt.Next;
            end;
            oDmArt.cdsEtiquetasArt.EmptyDataSet;
            for i := 0 to iOriginales - 1 do
            begin
              sSku := VarToStr(Filas[i][iSkuIdx]);
              if oCantidades.TryGetValue(sSku, iCantidad) then
              begin
                if iCantidad > 0 then
                begin
                  for k := 1 to iCantidad do
                  begin
                    oDmArt.cdsEtiquetasArt.Append;
                    for j := 0 to oDmArt.cdsEtiquetasArt.FieldCount - 1 do
                    begin
                      oDmArt.cdsEtiquetasArt.Fields[j].Value := Filas[i][j];
                    end;
                    if iStockIdx >= 0 then
                    begin
                      oDmArt.cdsEtiquetasArt.Fields[iStockIdx].AsInteger :=
                        iCantidad;
                    end;
                    oDmArt.cdsEtiquetasArt.Post;
                  end;
                end;
              end;
            end;
          finally
            oDmArt.cdsEtiquetasArt.EnableConstraints;
            oDmArt.cdsEtiquetasArt.EnableControls;
          end;
        end
        else
        begin
          oDmArt.cdsEtiquetasArt.EmptyDataSet;
        end;
      end;
    finally
      oCantidades.Free;
    end;
  end;
end;

procedure TdmDocumentosTrabajo.CrearDataSetEtiquetasDoc(ADmArt: TObject;
  AIdDtr: Int64; const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
var
  oDmArt: TdmArticulos;
  sSkus: string;
begin
  if ADmArt is TdmArticulos then
  begin
    oDmArt := TdmArticulos(ADmArt);
    sSkus := ObtenerSkusDocumentoCsv(AIdDtr, AAlmacenesCsv);
    if sSkus <> '' then
    begin
      oDmArt.CrearDataSetEtiquetasArt('', ACodTarifa, '', AFecha, sSkus);
      ExpandirEtiquetasPorCantidadDoc(oDmArt, AIdDtr, AAlmacenesCsv);
    end
    else
    begin
      oDmArt.CrearDataSetEtiquetasArt('DUMMY_SIN_LINEAS',
                                      ACodTarifa, '', AFecha);
    end;
  end;
end;

function TdmDocumentosTrabajo.ExisteDestinoCompartir(const ADestino,
  ATipo: string): Boolean;
var
  q: TUniQuery;
begin
  Result := False;
  q := TUniQuery.Create(nil);
  try
    q.Connection := ConexionPrincipal;
    if SameText(ATipo, 'USUARIO') then
    begin
      q.SQL.Text :=
        'SELECT USUARIO_USU ' +
        '  FROM fza_usuarios ' +
        ' WHERE USUARIO_USU = :DESTINO';
    end
    else if SameText(ATipo, 'GRUPO') then
    begin
      q.SQL.Text :=
        'SELECT GRUPO_USUGRP ' +
        '  FROM fza_usuarios_grupos ' +
        ' WHERE GRUPO_USUGRP = :DESTINO';
    end;
    if q.SQL.Text <> '' then
    begin
      q.ParamByName('DESTINO').AsString := ADestino;
      q.Open;
      Result := not q.IsEmpty;
    end;
  finally
    FreeAndNil(q);
  end;
end;

function TdmDocumentosTrabajo.NormalizarTipoDestino(const ADestino,
  ATipo: string): string;
var
  sTipo: string;
begin
  Result := '';
  sTipo := UpperCase(Trim(ATipo));
  if (sTipo <> '') and (sTipo <> 'USUARIO') and (sTipo <> 'GRUPO') then
  begin
    raise ERangeError.Create(SErrorTipoDestinoDocumentoTrabajo);
  end;
  if sTipo <> '' then
  begin
    if not ExisteDestinoCompartir(ADestino, sTipo) then
    begin
      raise ERangeError.Create(SErrorDestinoCompartidoNoExiste);
    end;
    Result := sTipo;
  end
  else if ExisteDestinoCompartir(ADestino, 'USUARIO') then
  begin
    Result := 'USUARIO';
  end
  else if ExisteDestinoCompartir(ADestino, 'GRUPO') then
  begin
    Result := 'GRUPO';
  end
  else
  begin
    raise ERangeError.Create(SErrorDestinoCompartidoNoExiste);
  end;
end;

function TdmDocumentosTrabajo.CompartirDocumentoActual(const ADestino,
  ATipo: string): Boolean;
var
  sDestino: string;
  sTipo: string;
begin
  Result := False;
  RefrescarDocumentoSiCambio;
  sDestino := Trim(ADestino);
  if sDestino = '' then
  begin
    raise ERangeError.Create(SErrorDestinoCompartirObligatorio);
  end;
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(
      SErrorCompartirDocumentoTrabajoSoloPropietario);
  end;
  if unqryTablaG.State in dsEditModes then
  begin
    unqryTablaG.Post;
  end;
  if unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    raise ERangeError.Create(SErrorCabeceraDocumentoTrabajoSinGrabar);
  end;
  sTipo := NormalizarTipoDestino(sDestino, ATipo);
  if SameText(sTipo,
              'USUARIO') and SameText(sDestino, IdentidadSesion.Usuario) then
  begin
    raise ERangeError.Create(SErrorCompartirDocumentoTrabajoConsigoMismo);
  end;
  if not unqryCompartidos.Active then
  begin
    unqryCompartidos.Open;
  end;
  if unqryCompartidos.State in dsEditModes then
  begin
    unqryCompartidos.Post;
  end;
  if not unqryCompartidos.Locate('TIPO_DESTINO_DTC;USUARIO_GRUPO_DTC',
                                 VarArrayOf([sTipo, sDestino]),
                                 [loCaseInsensitive]) then
  begin
    unqryCompartidos.Append;
    unqryCompartidos.FieldByName('TIPO_DESTINO_DTC').AsString := sTipo;
    unqryCompartidos.FieldByName('USUARIO_GRUPO_DTC').AsString := sDestino;
    unqryCompartidos.FieldByName('USUARIO_DTC').AsString := sDestino;
    unqryCompartidos.FieldByName('PERMISO_DTC').AsString := 'LECTURA';
    unqryCompartidos.Post;
    Result := True;
  end;
end;

procedure TdmDocumentosTrabajo.AbrirDetalles;
begin
  inherited;
  // Cinturon: si las queries se configuraron antes de recibir el
  // maestro, recablear aqui antes de abrir.
  if (FMaestroCabecera <> nil) and (unqryLineas.MasterSource = nil) then
  begin
    unqryLineas.MasterSource := FMaestroCabecera;
  end;
  if (FMaestroCabecera <> nil) and
     (unqryCompartidos.MasterSource = nil) then
  begin
    unqryCompartidos.MasterSource := FMaestroCabecera;
  end;
  if not unqryLineas.Active then
  begin
    unqryLineas.Open;
  end;
  if not unqryCompartidos.Active then
  begin
    unqryCompartidos.Open;
  end;
end;

procedure TdmDocumentosTrabajo.CambiarAmbito(const AAmbito: TDocTrabajoAmbito);
begin
  if FAmbito <> AAmbito then
  begin
    FAmbito := AAmbito;
    RecargarAmbitoActual;
  end;
end;

procedure TdmDocumentosTrabajo.RecargarAmbitoActual;
var
  bAbrir: Boolean;
begin
  bAbrir := unqryTablaG.Active;
  if unqryCompartidos.Active then
  begin
    unqryCompartidos.Close;
  end;
  if unqryLineas.Active then
  begin
    unqryLineas.Close;
  end;
  if unqryTablaG.Active then
  begin
    unqryTablaG.Close;
  end;
  ConfigurarSqlCabecera;
  if bAbrir then
  begin
    unqryTablaG.Open;
    AbrirDetalles;
  end;
end;

function TdmDocumentosTrabajo.EsPropietarioDocumentoActual: Boolean;
begin
  Result :=
    unqryTablaG.Active and
    (not unqryTablaG.IsEmpty) and
    SameText(unqryTablaG.FieldByName('USUARIO_DTR').AsString,
             IdentidadSesion.Usuario);
end;

function TdmDocumentosTrabajo.PuedeEditarDocumentoActual: Boolean;
begin
  Result :=
    (FAmbito = dtaPropios) and
    EsPropietarioDocumentoActual and
    EsDocumentoTrabajoCreado(
      unqryTablaG.FieldByName('ESTADO_DTR').AsString);
end;

function TdmDocumentosTrabajo.PuedeEnviarDocumentoActual: Boolean;
begin
  Result :=
    (FAmbito in [dtaPropios, dtaCompartidos]) and
    unqryTablaG.Active and
    (not unqryTablaG.IsEmpty) and
    (unqryTablaG.State = dsBrowse) and
    (not unqryTablaG.FieldByName('ID_DTR').IsNull) and
    EsDocumentoTrabajoCreado(
      unqryTablaG.FieldByName('ESTADO_DTR').AsString) and
    ((FAmbito = dtaCompartidos) or EsPropietarioDocumentoActual);
end;

function TdmDocumentosTrabajo.PuedeArchivarDocumentoActual: Boolean;
var
  sEstado: string;
begin
  Result := False;
  if (FAmbito = dtaPropios) and
     EsPropietarioDocumentoActual and
     (unqryTablaG.State = dsBrowse) and
     (not unqryTablaG.FieldByName('ID_DTR').IsNull) then
  begin
    sEstado := unqryTablaG.FieldByName('ESTADO_DTR').AsString;
    Result := EsDocumentoTrabajoCreado(sEstado) or
              EsDocumentoTrabajoEnviado(sEstado);
  end;
end;

function TdmDocumentosTrabajo.PuedeReabrirDocumentoActual: Boolean;
var
  sEstado: string;
begin
  Result := False;
  if (FAmbito in [dtaPropios, dtaArchivados]) and
     EsPropietarioDocumentoActual and
     (unqryTablaG.State = dsBrowse) and
     (not unqryTablaG.FieldByName('ID_DTR').IsNull) then
  begin
    sEstado := unqryTablaG.FieldByName('ESTADO_DTR').AsString;
    Result := EsDocumentoTrabajoEnviado(sEstado) or
              EsDocumentoTrabajoArchivado(sEstado);
  end;
end;

function TdmDocumentosTrabajo.ActualizarEstadoDocumentoActual(
  const AEstado: string): Boolean;
var
  idDtr: Int64;
  q: TUniQuery;
  sCondicion: string;
  sEstadoActual: string;
  sEstadoNuevo: string;
begin
  if not EsPropietarioDocumentoActual then
  begin
    raise ERangeError.Create(
      SErrorActualizarEstadoDocumentoTrabajoSoloPropietario);
  end;
  if unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    raise ERangeError.Create(SErrorCabeceraDocumentoTrabajoSinGrabar);
  end;

  sEstadoActual := NormalizarEstadoDocumentoTrabajo(
    unqryTablaG.FieldByName('ESTADO_DTR').AsString);
  sEstadoNuevo := NormalizarEstadoDocumentoTrabajo(AEstado);
  if not EsEstadoDocumentoTrabajoValido(sEstadoNuevo) then
  begin
    raise ERangeError.Create(SErrorEstadoDocumentoTrabajoNoValido);
  end;
  Result := True;
  if sEstadoActual <> sEstadoNuevo then
  begin
    if sEstadoNuevo = ESTADO_DOCUMENTO_TRABAJO_ENVIADO then
    begin
      if not EsDocumentoTrabajoCreado(sEstadoActual) then
      begin
        raise ERangeError.Create(SErrorEnviarDocumentoTrabajoNoPermitido);
      end;
      sCondicion := CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR');
    end
    else if sEstadoNuevo = ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO then
    begin
      if not (EsDocumentoTrabajoCreado(sEstadoActual) or
              EsDocumentoTrabajoEnviado(sEstadoActual)) then
      begin
        raise ERangeError.Create(SErrorArchivarDocumentoTrabajoNoPermitido);
      end;
      sCondicion := '(' +
        CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR') + ' OR ' +
        CondicionSqlDocumentoTrabajoEnviado('ESTADO_DTR') + ')';
    end
    else if sEstadoNuevo = ESTADO_DOCUMENTO_TRABAJO_CREADO then
    begin
      if not (EsDocumentoTrabajoEnviado(sEstadoActual) or
              EsDocumentoTrabajoArchivado(sEstadoActual)) then
      begin
        raise ERangeError.Create(SErrorReabrirDocumentoTrabajoNoPermitido);
      end;
      sCondicion := '(' +
        CondicionSqlDocumentoTrabajoEnviado('ESTADO_DTR') + ' OR ' +
        CondicionSqlDocumentoTrabajoArchivado('ESTADO_DTR') + ')';
    end
    else
    begin
      raise ERangeError.Create(SErrorEstadoDocumentoTrabajoNoValido);
    end;

    if unqryCompartidos.State in dsEditModes then
    begin
      unqryCompartidos.Post;
    end;
    if unqryLineas.State in dsEditModes then
    begin
      unqryLineas.Post;
    end;
    if unqryTablaG.State in dsEditModes then
    begin
      unqryTablaG.Post;
    end;
    idDtr := unqryTablaG.FieldByName('ID_DTR').AsLargeInt;

    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryTablaG.Connection;
      q.SQL.Text :=
        'UPDATE fza_documentos_trabajo ' +
        '   SET ESTADO_DTR = :ESTADO, USUARIO_MODIF = :USUARIO ' +
        ' WHERE ID_DTR = :ID_DTR ' +
        '   AND USUARIO_DTR = :USUARIO ' +
        '   AND ' + sCondicion;
      q.ParamByName('ESTADO').AsString := sEstadoNuevo;
      q.ParamByName('USUARIO').AsString := IdentidadSesion.Usuario;
      q.ParamByName('ID_DTR').AsLargeInt := idDtr;
      q.Execute;
      if q.RowsAffected <> 1 then
      begin
        raise ERangeError.Create(SErrorActualizarEstadoDocumentoTrabajo);
      end;
    finally
      FreeAndNil(q);
    end;

    // Archivar o desarchivar saca el documento de la lista actual.
    if (sEstadoNuevo = ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO) or
       (sEstadoActual = ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO) then
    begin
      RecargarAmbitoActual;
    end
    else
    begin
      unqryTablaG.RefreshRecord;
    end;
  end;
end;

function TdmDocumentosTrabajo.MarcarDocumentoActualEnviado: Boolean;
var
  bYaEnviado: Boolean;
begin
  bYaEnviado := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) then
  begin
    unqryTablaG.RefreshRecord;
    bYaEnviado := EsDocumentoTrabajoEnviado(
      unqryTablaG.FieldByName('ESTADO_DTR').AsString);
  end;
  if bYaEnviado then
  begin
    Result := True;
  end
  else
  begin
    if not PuedeEditarDocumentoActual then
    begin
      raise ERangeError.Create(SErrorEnviarDocumentoTrabajoNoPermitido);
    end;
    Result := ActualizarEstadoDocumentoActual(
      ESTADO_DOCUMENTO_TRABAJO_ENVIADO);
  end;
end;

function TdmDocumentosTrabajo.ArchivarDocumentoActual: Boolean;
begin
  if not PuedeArchivarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorArchivarDocumentoTrabajoNoPermitido);
  end;
  Result := ActualizarEstadoDocumentoActual(
    ESTADO_DOCUMENTO_TRABAJO_ARCHIVADO);
end;

function TdmDocumentosTrabajo.ReabrirDocumentoActual: Boolean;
begin
  if not PuedeReabrirDocumentoActual then
  begin
    raise ERangeError.Create(SErrorReabrirDocumentoTrabajoNoPermitido);
  end;
  Result := ActualizarEstadoDocumentoActual(
    ESTADO_DOCUMENTO_TRABAJO_CREADO);
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforeInsertDTR(
  DataSet: TDataSet);
begin
  if FAmbito <> dtaPropios then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
  inherited unqryTablaGBeforeInsert(DataSet);
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforeEdit(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforeDelete(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

procedure TdmDocumentosTrabajo.unqryTablaGAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('TITULO_DTR').AsString :=
    'Documento de trabajo ' + FormatDateTime('dd/mm/yyyy hh:nn', Now);
  DataSet.FieldByName('TIPO_DTR').AsString := 'GENERAL';
  DataSet.FieldByName('ESTADO_DTR').AsString :=
    ESTADO_DOCUMENTO_TRABAJO_CREADO;
  DataSet.FieldByName('CODIGO_EMP_DTR').AsString := UbicacionSesion.Empresa;
  DataSet.FieldByName('CODIGO_ALM_DTR').AsString := UbicacionSesion.Almacen;
  DataSet.FieldByName('USUARIO_DTR').AsString := IdentidadSesion.Usuario;
  DataSet.FieldByName('INSTANTE_DOCUMENTO_DTR').AsDateTime := Now;
end;

procedure TdmDocumentosTrabajo.unqryTablaGBeforePost(DataSet: TDataSet);
var
  sEstado: string;
begin
  if (DataSet.State = dsEdit) and not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
  inherited;
  if DataSet.State = dsInsert then
  begin
    DataSet.FieldByName('USUARIO_DTR').AsString := IdentidadSesion.Usuario;
  end;
  if Trim(DataSet.FieldByName('USUARIO_DTR').AsString) = '' then
  begin
    DataSet.FieldByName('USUARIO_DTR').AsString := IdentidadSesion.Usuario;
  end;
  if not SameText(DataSet.FieldByName('USUARIO_DTR').AsString,
                  IdentidadSesion.Usuario) then
  begin
    raise ERangeError.Create(SErrorCambiarPropietarioDocumentoTrabajo);
  end;
  if Trim(DataSet.FieldByName('TITULO_DTR').AsString) = '' then
  begin
    raise ERangeError.Create(SErrorTituloDocumentoTrabajoObligatorio);
  end;
  sEstado := NormalizarEstadoDocumentoTrabajo(
    DataSet.FieldByName('ESTADO_DTR').AsString);
  if DataSet.State = dsInsert then
  begin
    // Un alta siempre inicia el ciclo; ENVIADO y ARCHIVADO solo se alcanzan
    // mediante las transiciones protegidas del documento ya persistido.
    sEstado := ESTADO_DOCUMENTO_TRABAJO_CREADO;
  end
  else if not EsEstadoDocumentoTrabajoValido(sEstado) then
  begin
    raise ERangeError.Create(SErrorEstadoDocumentoTrabajoNoValido);
  end;
  DataSet.FieldByName('ESTADO_DTR').AsString := sEstado;
  if Trim(DataSet.FieldByName('TIPO_DTR').AsString) = '' then
  begin
    DataSet.FieldByName('TIPO_DTR').AsString := 'GENERAL';
  end;
end;

function TdmDocumentosTrabajo.SiguienteLinea: string;
var
  q: TUniQuery;
  iLinea: Integer;
begin
  iLinea := 1;
  if not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    q := TUniQuery.Create(nil);
    try
      q.Connection := unqryLineas.Connection;
      q.SQL.Text :=
        'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS LINEA ' +
        '  FROM fza_documentos_trabajo_lineas ' +
        ' WHERE ID_DTR_DTL = :ID_DTR';
      q.ParamByName('ID_DTR').AsLargeInt :=
        unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
      q.Open;
      if not q.IsEmpty then
      begin
        iLinea := q.FieldByName('LINEA').AsInteger;
      end;
    finally
      FreeAndNil(q);
    end;
  end;
  Result := Format('%.8d', [iLinea]);
end;

procedure TdmDocumentosTrabajo.unqryLineasAfterInsert(DataSet: TDataSet);
begin
  if not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    DataSet.FieldByName('ID_DTR_DTL').AsLargeInt :=
      unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
  end;
  DataSet.FieldByName('LINEA_DTL').AsString := SiguienteLinea;
  // El default SQL no se aplica antes de validar los campos requeridos.
  DataSet.FieldByName('LOTE_DTL').AsString := '';
  DataSet.FieldByName('CANTIDAD_STOCK_DTL').AsFloat := 0;
  DataSet.FieldByName('CANTIDAD_DTL').AsFloat := 0;
  DataSet.FieldByName('INSTANTE_STOCK_DTL').AsDateTime := Now;
  DataSet.FieldByName('ORIGEN_DTL').AsString := 'MANUAL';
end;

procedure TdmDocumentosTrabajo.unqryLineasBeforeEdit(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

procedure TdmDocumentosTrabajo.unqryLineasBeforeDelete(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

procedure TdmDocumentosTrabajo.unqryLineasBeforePost(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
  if DataSet.FieldByName('ID_DTR_DTL').IsNull then
  begin
    raise ERangeError.Create(SErrorCabeceraDocumentoTrabajoSinGrabar);
  end;
  if Trim(DataSet.FieldByName('LINEA_DTL').AsString) = '' then
  begin
    DataSet.FieldByName('LINEA_DTL').AsString := SiguienteLinea;
  end;
  if Trim(DataSet.FieldByName('CODIGO_ART_DTL').AsString) = '' then
  begin
    raise ERangeError.Create(SErrorArticuloLineaDocumentoTrabajoObligatorio);
  end;
  if Trim(DataSet.FieldByName('CODIGO_UNIDAD_DTL').AsString) = '' then
  begin
    raise ERangeError.Create(SErrorSkuLineaDocumentoTrabajoObligatorio);
  end;
  if DataSet.FieldByName('INSTANTE_STOCK_DTL').IsNull then
  begin
    DataSet.FieldByName('INSTANTE_STOCK_DTL').AsDateTime := Now;
  end;
  ActualizarAuditoria(DataSet);
end;

procedure TdmDocumentosTrabajo.DesempaquetarAtributosLineas;
begin
  if unqryLineas.Active and (not unqryLineas.IsEmpty) then
  begin
    // FZ-ISSUE-334: el desempaquetado graba las líneas y su UPDATE exige
    // el documento en CREADO; con el estado en memoria desfasado fallaba
    // con «Update failed. Found 0 records». Se mira el estado guardado.
    RefrescarDocumentoSiCambio;
    if PuedeEditarDocumentoActual then
    begin
      try
        DesempaquetarAtributosLineasSku(unqryLineas, 'DTL');
      except
        on E: EDatabaseError do
        begin
          // Cambió entre la comprobación y la grabación: solo presentación,
          // no se avisa al usuario; se recarga lo que hay en la BBDD.
          if unqryLineas.State in dsEditModes then
            unqryLineas.Cancel;
          RegistroLog.RegistrarAviso(
            'Documentos de trabajo: atributos de las líneas no grabados (' +
            E.Message + '); se recarga el documento');
          RecargarDocumentoActual;
        end;
      end;
    end;
  end;
end;

function TdmDocumentosTrabajo.RefrescarDocumentoSiCambio: Boolean;
var
  oConsulta: TUniQuery;
  bExiste: Boolean;
  sEstadoGuardado: string;
begin
  Result := False;
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.State in [dsBrowse, dsEdit]) and
     not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := unqryTablaG.Connection;
      oConsulta.SQL.Text :=
        'SELECT ESTADO_DTR FROM fza_documentos_trabajo WHERE ID_DTR = :ID';
      oConsulta.ParamByName('ID').AsLargeInt :=
        unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
      oConsulta.Open;
      bExiste := not oConsulta.IsEmpty;
      sEstadoGuardado := '';
      if bExiste then
        sEstadoGuardado := oConsulta.FieldByName('ESTADO_DTR').AsString;
    finally
      FreeAndNil(oConsulta);
    end;
    if (not bExiste) or not SameText(sEstadoGuardado,
         unqryTablaG.FieldByName('ESTADO_DTR').AsString) then
    begin
      // Descartar ediciones obsoletas antes de refrescar: nunca Post.
      if unqryLineas.State in dsEditModes then
        unqryLineas.Cancel;
      if unqryCompartidos.State in dsEditModes then
        unqryCompartidos.Cancel;
      if unqryTablaG.State = dsEdit then
        unqryTablaG.Cancel;
      if bExiste then
        RecargarDocumentoActual
      else
        RecargarAmbitoActual;
      Result := True;
    end;
  end;
end;

procedure TdmDocumentosTrabajo.RecargarDocumentoActual;
begin
  if unqryTablaG.Active and (not unqryTablaG.IsEmpty) and
     (unqryTablaG.State = dsBrowse) then
  begin
    try
      unqryTablaG.RefreshRecord;
    except
      on E: EDatabaseError do
      begin
        // Borrado en otro puesto: se recarga la lista entera
        RegistroLog.RegistrarAviso(
          'Documentos de trabajo: el documento actual ya no existe (' +
          E.Message + ')');
        RecargarAmbitoActual;
      end;
    end;
  end;
  if unqryLineas.Active and (unqryLineas.State = dsBrowse) then
    unqryLineas.Refresh;
end;

procedure TdmDocumentosTrabajo.unqryCompartidosAfterInsert(DataSet: TDataSet);
begin
  if not unqryTablaG.FieldByName('ID_DTR').IsNull then
  begin
    DataSet.FieldByName('ID_DTR_DTC').AsLargeInt :=
      unqryTablaG.FieldByName('ID_DTR').AsLargeInt;
  end;
  DataSet.FieldByName('TIPO_DESTINO_DTC').AsString := 'USUARIO';
  DataSet.FieldByName('PERMISO_DTC').AsString := 'LECTURA';
end;

procedure TdmDocumentosTrabajo.unqryCompartidosBeforeEdit(
  DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

procedure TdmDocumentosTrabajo.unqryCompartidosBeforeDelete(DataSet: TDataSet);
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

procedure TdmDocumentosTrabajo.unqryCompartidosBeforePost(DataSet: TDataSet);
var
  sDestino: string;
  sTipo: string;
begin
  if not PuedeEditarDocumentoActual then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
  if DataSet.FieldByName('ID_DTR_DTC').IsNull then
  begin
    raise ERangeError.Create(SErrorCabeceraDocumentoTrabajoSinGrabar);
  end;
  sDestino := Trim(DataSet.FieldByName('USUARIO_GRUPO_DTC').AsString);
  if sDestino = '' then
  begin
    sDestino := Trim(DataSet.FieldByName('USUARIO_DTC').AsString);
  end;
  if sDestino = '' then
  begin
    raise ERangeError.Create(SErrorDestinoCompartidoObligatorio);
  end;
  sTipo := NormalizarTipoDestino(
    sDestino, DataSet.FieldByName('TIPO_DESTINO_DTC').AsString);
  if SameText(sTipo,
              'USUARIO') and SameText(sDestino, IdentidadSesion.Usuario) then
  begin
    raise ERangeError.Create(SErrorCompartirDocumentoTrabajoConsigoMismo);
  end;
  DataSet.FieldByName('TIPO_DESTINO_DTC').AsString := sTipo;
  DataSet.FieldByName('USUARIO_GRUPO_DTC').AsString := sDestino;
  DataSet.FieldByName('USUARIO_DTC').AsString := sDestino;
  if Trim(DataSet.FieldByName('PERMISO_DTC').AsString) = '' then
  begin
    DataSet.FieldByName('PERMISO_DTC').AsString := 'LECTURA';
  end;
  ActualizarAuditoria(DataSet);
end;

procedure TdmDocumentosTrabajo.unqryProtegidaAfterUpdateExecute(
  Sender: TDataSet; StatementTypes: TStatementTypes; Params: TDAParams);
begin
  if ((stInsert in StatementTypes) or
      (stUpdate in StatementTypes) or
      (stDelete in StatementTypes)) and
     (TUniQuery(Sender).RowsAffected <> 1) then
  begin
    // Las sentencias llevan el estado CREADO en el mismo guard SQL. Si
    // otra sesion lo envio o archivo entre la lectura y el Post, 0 filas
    // significa conflicto y nunca debe aceptarse como una escritura valida.
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
end;

initialization
  RegistrarDataModule(TdmDocumentosTrabajo);
  ForceReferenceToClass(TdmDocumentosTrabajo);
end.
