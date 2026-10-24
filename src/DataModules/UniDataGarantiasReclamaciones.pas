{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataGarantiasReclamaciones                                 }
{    Tipo:       Data Module                                                   }
{ Versión:       1.1.0                                                         }
{   Fecha:       19/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ventas - Reclamaciones de garantía por número de serie (F-LOTEC-021):     }
{    lista filtrable, datos de una serie vendida, alta                         }
{    (PRC_FZA_GARANTIAS_ALTA), cambio de estado y sustitución por otra unidad  }
{    (PRC_FZA_GARANTIAS_SUSTITUIR). Desde el 19/10/2026 la consulta principal  }
{    es editable (ficha con cliente, proveedor y las cuatro fases) con         }
{    SQLUpdate propio, y ofrece la lista de proveedores del desplegable.       }
{******************************************************************************}
unit UniDataGarantiasReclamaciones;

interface

uses
  inLibRegistroPantallas,
  System.SysUtils, System.Classes,
  Data.DB, MemDS, DBAccess, Uni,
  UniDataGen,
  inLibGarantias, inLibGarantiasResguardo;

const
  // Columnas de fza_garantias_reclamaciones que se editan en la ficha, en
  // el orden en que las graba SqlActualizacionGarantia.
  COLUMNAS_FICHA_GARANTIA: array[0..36] of string = (
    'MOTIVO_GAR', 'OBSERVACIONES_GAR', 'MODELO_GAR', 'CODIGO_PRV_GAR',
    'NOMBRE_CLIENTE_GAR', 'TELEFONO_CLIENTE_GAR', 'EMAIL_CLIENTE_GAR',
    'DIRECCION_CLIENTE_GAR', 'CODIGO_POSTAL_CLIENTE_GAR',
    'POBLACION_CLIENTE_GAR', 'PROVINCIA_CLIENTE_GAR',
    'FECHA_RECEPCION_GAR', 'MEDIO_RECEPCION_GAR', 'AGENCIA_RECEPCION_GAR',
    'TRACKING_RECEPCION_GAR', 'OBSERVACIONES_RECEPCION_GAR',
    'FECHA_ENVIO_FAB_GAR', 'RMA_GAR', 'DIRECCION_ENVIO_FAB_GAR',
    'AGENCIA_ENVIO_FAB_GAR', 'TRACKING_ENVIO_FAB_GAR',
    'ESINCIDENCIA_ENVIO_FAB_GAR', 'INCIDENCIA_ENVIO_FAB_GAR',
    'RECLAMACION_TRANSPORTE_ENVIO_FAB_GAR',
    'FECHA_RECEPCION_FAB_GAR', 'TRACKING_RECEPCION_FAB_GAR',
    'ESINCIDENCIA_RECEPCION_FAB_GAR', 'INCIDENCIA_RECEPCION_FAB_GAR',
    'RECLAMACION_TRANSPORTE_RECEPCION_FAB_GAR',
    'OBSERVACIONES_RECEPCION_FAB_GAR',
    'FECHA_ENTREGA_CLI_GAR', 'MEDIO_ENTREGA_CLI_GAR',
    'AGENCIA_ENTREGA_CLI_GAR', 'TRACKING_ENTREGA_CLI_GAR',
    'ESINCIDENCIA_ENTREGA_CLI_GAR', 'INCIDENCIA_ENTREGA_CLI_GAR',
    'RECLAMACION_TRANSPORTE_ENTREGA_CLI_GAR');

type
  TdmGarantiasReclamaciones = class(TdmBase)
    procedure DataModuleCreate(Sender: TObject);
  private
    FProveedores: TUniQuery;
    FdsProveedores: TDataSource;
    procedure ConfigurarConsulta;
    procedure TablaGBeforeInsert(DataSet: TDataSet);
    procedure TablaGBeforeDelete(DataSet: TDataSet);
    procedure TablaGAfterPost(DataSet: TDataSet);
  public
    // AEstado: un ESTADO_GAR, FILTRO_GARANTIA_PENDIENTES o '' (todas).
    // ATexto: parte de la serie, del SKU, del cliente, del contacto o del
    // RMA; '' = sin filtro.
    procedure AplicarFiltros(const AEstado, ATexto: string);
    // Proveedores activos para el desplegable de la ficha. Se crea y abre
    // la primera vez que se pide, ya con la conexión heredada.
    function Proveedores: TDataSource;
    function DatosResguardo: TResguardoGarantia;
    function DatosSerie(const ASerie: string): TDatosSerieGarantia;
    function Alta(const ADatos: TDatosSerieGarantia;
      const AMotivo: string): Int64;
    procedure CambiarEstado(AId: Int64;
      const AEstado, AResolucion, AObservaciones: string);
    procedure Sustituir(AId: Int64;
      const ASerieNueva, AAlmacen, AAlmacenTaras: string);
    // Almacén de taras activo de la empresa; primero el hijo de AAlmacen.
    // '' si no hay ninguno.
    function AlmacenTaras(const AAlmacen: string): string;
  end;

// Lista filtrada y ordenada de la rejilla.
function SqlReclamacionesGarantia: string;
// UPDATE de las columnas de la ficha por ID_GAR (parámetros = campos).
function SqlActualizacionGarantia: string;
// Fila completa de una reclamación (:ID_GAR), para refrescar tras grabar.
function SqlRefrescoGarantia: string;
// Fila de PRC_FZA_GARANTIAS_DATOS_SERIE (vacía = no encontrada).
function LeerDatosSerieGarantia(
  AConsulta: TDataSet): TDatosSerieGarantia;

implementation

uses
  inLibMsgGarantias, inLibErroresBBDD;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

procedure ForceReferenceToClass(C: TClass);
begin
end;

function ColumnasFichaSql: string;
var
  sColumna: string;
begin
  Result := '';
  for sColumna in COLUMNAS_FICHA_GARANTIA do
    Result := Result + ', G.' + sColumna;
end;

// SELECT y JOIN comunes a la lista y al refresco: la reclamación, el
// artículo, el cliente de la venta, el proveedor al que se reclama y la
// fase actual (la última con fecha).
function SqlSeleccionGarantias: string;
begin
  Result :=
    'SELECT G.ID_GAR, G.FECHA_RECLAMACION_GAR, G.LOTE_GAR, ' +
    '       G.CODIGO_ART_GAR, ' +
    '       G.CODIGO_UNIDAD_GAR, COALESCE(A.DESCRIPCION_ART, '''') ' +
    '         AS DESCRIPCION_ART, ' +
    // FZ-ISSUE-602: una venta al contado no tiene cliente que mostrar.
    '       CASE WHEN C.CODIGO_CLI_CLI IS NULL AND ' +
    '                 COALESCE(G.CODIGO_CLI_GAR, '''') IN ('''', ''0'') ' +
    '            THEN '''' ' +
    '            ELSE CONCAT_WS('' - '', G.CODIGO_CLI_GAR, ' +
    '                           C.RAZON_SOCIAL_CLI) END AS CLIENTE, ' +
    '       CONCAT_WS('' '', G.TIPO_DOC_VENTA_GAR, ' +
    '                 CONCAT(G.SERIE_DOC_VENTA_GAR, ''/'', ' +
    '                        G.NUMERO_DOC_VENTA_GAR)) AS VENTA, ' +
    '       G.FECHA_VENTA_GAR, G.FECHA_FIN_GARANTIA_GAR, ' +
    '       IF(G.FECHA_FIN_GARANTIA_GAR >= DATE(G.FECHA_RECLAMACION_GAR), ' +
    '          ''S'', ''N'') AS ESEN_GARANTIA, ' +
    '       G.ESTADO_GAR, COALESCE(G.RESOLUCION_GAR, '''') ' +
    '         AS RESOLUCION_GAR, ' +
    '       COALESCE(G.LOTE_SUSTITUTO_GAR, '''') AS LOTE_SUSTITUTO_GAR, ' +
    '       G.USUARIO_ALTA, G.INSTANTE_ALTA, G.USUARIO_MODIF, ' +
    '       G.INSTANTE_MODIF' + ColumnasFichaSql + ', ' +
    '       CASE WHEN G.FECHA_ENTREGA_CLI_GAR IS NOT NULL THEN ''' +
    FASE_GARANTIA_ENTREGA_CLI + ''' ' +
    '            WHEN G.FECHA_RECEPCION_FAB_GAR IS NOT NULL THEN ''' +
    FASE_GARANTIA_RECEPCION_FAB + ''' ' +
    '            WHEN G.FECHA_ENVIO_FAB_GAR IS NOT NULL THEN ''' +
    FASE_GARANTIA_ENVIO_FAB + ''' ' +
    '            WHEN G.FECHA_RECEPCION_GAR IS NOT NULL THEN ''' +
    FASE_GARANTIA_RECEPCION + ''' ' +
    '            ELSE '''' END AS FASE_GAR, ' +
    '       COALESCE(P.RAZON_SOCIAL_PRV, '''') AS RAZON_SOCIAL_PRV, ' +
    '       P.CONTACTO_PRV, P.TELEFONO_CONTACTO_PRV, P.TELEFONO_PRV, ' +
    '       P.MOVIL_PRV, P.EMAIL_PRV, P.DIRECCION1_PRV, ' +
    '       P.CODIGO_POSTAL_PRV, P.POBLACION_PRV, P.PROVINCIA_PRV ' +
    '  FROM fza_garantias_reclamaciones G ' +
    '  LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = G.CODIGO_ART_GAR ' +
    '  LEFT JOIN fza_clientes C ON C.CODIGO_CLI_CLI = G.CODIGO_CLI_GAR ' +
    '  LEFT JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = G.CODIGO_PRV_GAR ';
end;

// Las abiertas primero, de la más antigua a la más reciente; después las
// cerradas, de la más reciente a la más antigua.
function SqlReclamacionesGarantia: string;
begin
  Result := SqlSeleccionGarantias +
    ' WHERE (:ESTADO = '''' ' +
    '        OR (:ESTADO = ''' + FILTRO_GARANTIA_PENDIENTES + ''' ' +
    '            AND G.ESTADO_GAR IN (''' + ESTADO_GARANTIA_ABIERTA +
    ''', ''' + ESTADO_GARANTIA_EN_SAT + ''')) ' +
    '        OR G.ESTADO_GAR = :ESTADO) ' +
    '   AND (:TEXTO = '''' OR G.LOTE_GAR LIKE :PATRON ' +
    '        OR G.CODIGO_UNIDAD_GAR LIKE :PATRON ' +
    '        OR G.CODIGO_CLI_GAR LIKE :PATRON ' +
    '        OR C.RAZON_SOCIAL_CLI LIKE :PATRON ' +
    '        OR G.NOMBRE_CLIENTE_GAR LIKE :PATRON ' +
    '        OR G.RMA_GAR LIKE :PATRON) ' +
    ' ORDER BY G.ESTADO_GAR IN (''' + ESTADO_GARANTIA_ABIERTA + ''', ''' +
    ESTADO_GARANTIA_EN_SAT + ''') DESC, ' +
    '          IF(G.ESTADO_GAR IN (''' + ESTADO_GARANTIA_ABIERTA + ''', ''' +
    ESTADO_GARANTIA_EN_SAT + '''), G.FECHA_RECLAMACION_GAR, NULL), ' +
    '          G.FECHA_RECLAMACION_GAR DESC, G.ID_GAR DESC';
end;

function SqlActualizacionGarantia: string;
var
  sColumna: string;
begin
  Result := 'UPDATE fza_garantias_reclamaciones SET ';
  for sColumna in COLUMNAS_FICHA_GARANTIA do
    Result := Result + sColumna + ' = :' + sColumna + ', ';
  Result := Result +
    'USUARIO_MODIF = :USUARIO_MODIF, INSTANTE_MODIF = NOW() ' +
    'WHERE ID_GAR = :Old_ID_GAR';
end;

function SqlRefrescoGarantia: string;
begin
  Result := SqlSeleccionGarantias + ' WHERE G.ID_GAR = :ID_GAR';
end;

procedure TdmGarantiasReclamaciones.DataModuleCreate(Sender: TObject);
begin
  inherited;
  ConfigurarConsulta;
end;

// La consulta lleva alias y JOIN, así que UniDAC no deduce la tabla a
// grabar: UPDATE y refresco explícitos y campos sin marcar como solo
// lectura (los de las tablas unidas no entran en el UPDATE y la ficha
// los muestra bloqueados).
procedure TdmGarantiasReclamaciones.ConfigurarConsulta;
begin
  unqryTablaG.SQL.Text := SqlReclamacionesGarantia;
  unqryTablaG.SQLUpdate.Text := SqlActualizacionGarantia;
  unqryTablaG.SQLRefresh.Text := SqlRefrescoGarantia;
  unqryTablaG.KeyFields := 'ID_GAR';
  unqryTablaG.ReadOnly := False;
  unqryTablaG.Options.SetFieldsReadOnly := False;
  unqryTablaG.ParamByName('ESTADO').AsString := FILTRO_GARANTIA_PENDIENTES;
  unqryTablaG.ParamByName('TEXTO').AsString := '';
  unqryTablaG.ParamByName('PATRON').AsString := '';
  unqryTablaG.BeforeInsert := TablaGBeforeInsert;
  unqryTablaG.BeforeDelete := TablaGBeforeDelete;
  unqryTablaG.AfterPost := TablaGAfterPost;
end;

// El alta necesita la serie leída (artículo, cliente y venta salen del
// histórico): no se inserta una fila vacía desde el navegador.
procedure TdmGarantiasReclamaciones.TablaGBeforeInsert(DataSet: TDataSet);
begin
  NotificarInformacion(SInfoAltaGarantiaDesdeNueva);
  Abort;
end;

procedure TdmGarantiasReclamaciones.TablaGBeforeDelete(DataSet: TDataSet);
begin
  NotificarInformacion(SInfoGarantiaNoSeBorra);
  Abort;
end;

// Tras grabar se relee la fila: la fase y los datos del proveedor elegido
// vienen calculados o de otra tabla.
procedure TdmGarantiasReclamaciones.TablaGAfterPost(DataSet: TDataSet);
begin
  unqryTablaG.RefreshRecord;
end;

procedure TdmGarantiasReclamaciones.AplicarFiltros(
  const AEstado, ATexto: string);
begin
  if unqryTablaG.Active then
    unqryTablaG.Close;
  unqryTablaG.ParamByName('ESTADO').AsString := Trim(AEstado);
  unqryTablaG.ParamByName('TEXTO').AsString := Trim(ATexto);
  unqryTablaG.ParamByName('PATRON').AsString := '%' + Trim(ATexto) + '%';
  unqryTablaG.Open;
end;

function TdmGarantiasReclamaciones.Proveedores: TDataSource;
begin
  if not Assigned(FProveedores) then
  begin
    FProveedores := TUniQuery.Create(Self);
    FProveedores.Connection := unqryTablaG.Connection;
    FProveedores.SQL.Text :=
      'SELECT P.CODIGO_PRV_PRV, P.RAZON_SOCIAL_PRV ' +
      '  FROM fza_proveedores P ' +
      ' WHERE P.ESACTIVO_PRV = ''S'' ' +
      ' ORDER BY P.RAZON_SOCIAL_PRV, P.CODIGO_PRV_PRV';
    FProveedores.ReadOnly := True;
    FdsProveedores := TDataSource.Create(Self);
    FdsProveedores.DataSet := FProveedores;
  end;
  if (not FProveedores.Active) and Assigned(FProveedores.Connection) then
    FProveedores.Open;
  Result := FdsProveedores;
end;

function SqlTiendaResguardoGarantia: string;
begin
  Result :=
    'SELECT E.RAZON_SOCIAL_EMP, E.NIF_EMP, A.NOMBRE_ALM_ALM, ' +
    '       COALESCE(NULLIF(A.DIRECCION_ALM, ''''), E.DIRECCION1_EMP) ' +
    '         AS DIRECCION, ' +
    '       CONCAT_WS('' '', A.CODIGO_POSTAL_ALM, A.POBLACION_ALM, ' +
    '                 A.PROVINCIA_ALM) AS POBLACION, A.TELEFONO_ALM ' +
    '  FROM fza_garantias_reclamaciones G ' +
    '  JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = G.CODIGO_ALM_GAR ' +
    '  JOIN fza_empresas E ON E.CODIGO_EMP_EMP = A.CODIGO_EMP_ALM ' +
    ' WHERE G.ID_GAR = :ID';
end;

function TdmGarantiasReclamaciones.DatosResguardo: TResguardoGarantia;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResguardoGarantia);
  if unqryTablaG.IsEmpty then
    raise EValidacionBBDD.Create(SInfoSinReclamacion);
  Result.Numero := unqryTablaG.FieldByName('ID_GAR').AsLargeInt;
  Result.Fecha := unqryTablaG.FieldByName('FECHA_RECLAMACION_GAR').AsDateTime;
  Result.Recepcion := unqryTablaG.FieldByName('FECHA_RECEPCION_GAR').AsDateTime;
  Result.Cliente := unqryTablaG.FieldByName('NOMBRE_CLIENTE_GAR').AsString;
  if Trim(Result.Cliente) = '' then
    Result.Cliente := unqryTablaG.FieldByName('CLIENTE').AsString;
  Result.TelefonoCliente :=
    unqryTablaG.FieldByName('TELEFONO_CLIENTE_GAR').AsString;
  Result.Articulo := unqryTablaG.FieldByName('CODIGO_ART_GAR').AsString;
  Result.Descripcion := unqryTablaG.FieldByName('DESCRIPCION_ART').AsString;
  Result.Modelo := unqryTablaG.FieldByName('MODELO_GAR').AsString;
  Result.Serie := unqryTablaG.FieldByName('LOTE_GAR').AsString;
  Result.Motivo := unqryTablaG.FieldByName('MOTIVO_GAR').AsString;
  Result.Observaciones :=
    unqryTablaG.FieldByName('OBSERVACIONES_RECEPCION_GAR').AsString;
  Result.Medio := unqryTablaG.FieldByName('MEDIO_RECEPCION_GAR').AsString;
  Result.DocumentoVenta := unqryTablaG.FieldByName('VENTA').AsString;
  Result.FechaVenta := unqryTablaG.FieldByName('FECHA_VENTA_GAR').AsDateTime;
  Result.FinGarantia :=
    unqryTablaG.FieldByName('FECHA_FIN_GARANTIA_GAR').AsDateTime;
  Result.EnGarantia :=
    unqryTablaG.FieldByName('ESEN_GARANTIA').AsString = 'S';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text := SqlTiendaResguardoGarantia;
    oConsulta.ParamByName('ID').AsLargeInt := Result.Numero;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EValidacionBBDD.Create(SErrorTiendaResguardo);
    Result.Empresa := oConsulta.FieldByName('RAZON_SOCIAL_EMP').AsString;
    Result.Nif := oConsulta.FieldByName('NIF_EMP').AsString;
    Result.Tienda := oConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
    Result.DireccionTienda := oConsulta.FieldByName('DIRECCION').AsString;
    Result.PoblacionTienda := oConsulta.FieldByName('POBLACION').AsString;
    Result.TelefonoTienda := oConsulta.FieldByName('TELEFONO_ALM').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function LeerDatosSerieGarantia(
  AConsulta: TDataSet): TDatosSerieGarantia;
begin
  Result := Default(TDatosSerieGarantia);
  Result.Encontrada := not AConsulta.IsEmpty;
  if Result.Encontrada then
  begin
    Result.Sku := AConsulta.FieldByName('CODIGO_UNIDAD_LOT').AsString;
    Result.Serie := AConsulta.FieldByName('LOTE_LOT').AsString;
    Result.Articulo := AConsulta.FieldByName('CODIGO_ART_SKU').AsString;
    Result.Descripcion := AConsulta.FieldByName('DESCRIPCION_ART').AsString;
    Result.TieneMeses :=
      not AConsulta.FieldByName('MESES_GARANTIA_ART').IsNull;
    Result.MesesGarantia :=
      AConsulta.FieldByName('MESES_GARANTIA_ART').AsInteger;
    Result.Vendida := not AConsulta.FieldByName('FECHA_VENTA').IsNull;
    Result.TipoDocVenta := AConsulta.FieldByName('TIPO_DOC_VENTA').AsString;
    Result.SerieDocVenta :=
      AConsulta.FieldByName('SERIE_DOC_VENTA').AsString;
    Result.NumeroDocVenta :=
      AConsulta.FieldByName('NUMERO_DOC_VENTA').AsString;
    Result.FechaVenta := AConsulta.FieldByName('FECHA_VENTA').AsDateTime;
    Result.Cliente := AConsulta.FieldByName('CODIGO_CLI').AsString;
    Result.RazonSocialCliente :=
      AConsulta.FieldByName('RAZON_SOCIAL_CLI').AsString;
    Result.FechaFinGarantia :=
      AConsulta.FieldByName('FECHA_FIN_GARANTIA').AsDateTime;
    Result.EnGarantia :=
      AConsulta.FieldByName('ESEN_GARANTIA').AsString = 'S';
    Result.Devuelta := AConsulta.FieldByName('ESDEVUELTA').AsString = 'S';
    Result.AlmacenStock :=
      AConsulta.FieldByName('CODIGO_ALM_STOCK').AsString;
    Result.AlmacenVenta :=
      AConsulta.FieldByName('CODIGO_ALM_VENTA').AsString;
    Result.ReclamacionesAbiertas :=
      AConsulta.FieldByName('RECLAMACIONES_ABIERTAS').AsInteger;
  end;
end;

// Si la serie está en varios SKU (no debería: es única), la primera.
function TdmGarantiasReclamaciones.DatosSerie(
  const ASerie: string): TDatosSerieGarantia;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'CALL PRC_FZA_GARANTIAS_DATOS_SERIE(:SERIE, NULL)';
    oConsulta.ParamByName('SERIE').AsString := Trim(ASerie);
    oConsulta.Open;
    Result := LeerDatosSerieGarantia(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// PRC_FZA_GARANTIAS_ALTA copia el cliente, el modelo y el proveedor del
// artículo y deja la recepción de hoy en tienda.
function TdmGarantiasReclamaciones.Alta(const ADatos: TDatosSerieGarantia;
  const AMotivo: string): Int64;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'CALL PRC_FZA_GARANTIAS_ALTA(:SKU, :SERIE, :ARTICULO, :CLIENTE, ' +
      ':TIPO, :SERIE_DOC, :NUMERO_DOC, :VENTA, :FIN, :MOTIVO, :ALMACEN, ' +
      ':USUARIO, @ID_GAR)';
    oConsulta.ParamByName('SKU').AsString := ADatos.Sku;
    oConsulta.ParamByName('SERIE').AsString := ADatos.Serie;
    oConsulta.ParamByName('ARTICULO').AsString := ADatos.Articulo;
    oConsulta.ParamByName('CLIENTE').AsString := ADatos.Cliente;
    oConsulta.ParamByName('TIPO').AsString := ADatos.TipoDocVenta;
    oConsulta.ParamByName('SERIE_DOC').AsString := ADatos.SerieDocVenta;
    oConsulta.ParamByName('NUMERO_DOC').AsString := ADatos.NumeroDocVenta;
    oConsulta.ParamByName('VENTA').DataType := ftDate;
    oConsulta.ParamByName('FIN').DataType := ftDate;
    if ADatos.Vendida then
      oConsulta.ParamByName('VENTA').AsDate := ADatos.FechaVenta;
    if ADatos.Vendida and ADatos.TieneMeses then
      oConsulta.ParamByName('FIN').AsDate := ADatos.FechaFinGarantia;
    oConsulta.ParamByName('MOTIVO').AsString := Copy(Trim(AMotivo), 1, 500);
    oConsulta.ParamByName('ALMACEN').AsString :=
      AlmacenRecepcionGarantia(ADatos, UbicacionSesion.Almacen);
    oConsulta.ParamByName('USUARIO').AsString :=
      Copy(IdentidadSesion.Usuario, 1, 50);
    oConsulta.ExecSQL;
    oConsulta.SQL.Text := 'SELECT @ID_GAR AS ID';
    oConsulta.Open;
    Result := oConsulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Solo cambia reclamaciones abiertas: una cerrada no se reabre por error.
procedure TdmGarantiasReclamaciones.CambiarEstado(AId: Int64;
  const AEstado, AResolucion, AObservaciones: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'UPDATE fza_garantias_reclamaciones ' +
      '   SET ESTADO_GAR = :ESTADO, ' +
      '       FECHA_ENVIO_FAB_GAR = CASE WHEN :ESTADO = ''' +
      ESTADO_GARANTIA_EN_SAT + ''' THEN ' +
      '         COALESCE(FECHA_ENVIO_FAB_GAR, CURDATE()) ' +
      '         ELSE FECHA_ENVIO_FAB_GAR END, ' +
      '       RESOLUCION_GAR = NULLIF(:RESOLUCION, ''''), ' +
      '       FECHA_RESOLUCION_GAR = IF(:ESTADO IN (''' +
      ESTADO_GARANTIA_RESUELTA + ''', ''' + ESTADO_GARANTIA_RECHAZADA +
      '''), NOW(), NULL), ' +
      '       OBSERVACIONES_GAR = COALESCE(NULLIF(:OBSERVACIONES, ''''), ' +
      '                                    OBSERVACIONES_GAR), ' +
      '       INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_GAR = :ID ' +
      '   AND ESTADO_GAR IN (''' + ESTADO_GARANTIA_ABIERTA + ''', ''' +
      ESTADO_GARANTIA_EN_SAT + ''')';
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    oConsulta.ParamByName('RESOLUCION').AsString := AResolucion;
    oConsulta.ParamByName('OBSERVACIONES').AsString :=
      Copy(Trim(AObservaciones), 1, 500);
    oConsulta.ParamByName('USUARIO').AsString :=
      Copy(IdentidadSesion.Usuario, 1, 50);
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TdmGarantiasReclamaciones.Sustituir(AId: Int64;
  const ASerieNueva, AAlmacen, AAlmacenTaras: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'CALL PRC_FZA_GARANTIAS_SUSTITUIR(:ID, :SERIE, :ALMACEN, :TARAS, ' +
      ':USUARIO)';
    oConsulta.ParamByName('ID').AsLargeInt := AId;
    oConsulta.ParamByName('SERIE').AsString := Trim(ASerieNueva);
    oConsulta.ParamByName('ALMACEN').AsString := AAlmacen;
    oConsulta.ParamByName('TARAS').AsString := AAlmacenTaras;
    oConsulta.ParamByName('USUARIO').AsString :=
      Copy(IdentidadSesion.Usuario, 1, 50);
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TdmGarantiasReclamaciones.AlmacenTaras(
  const AAlmacen: string): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := unqryTablaG.Connection;
    oConsulta.SQL.Text :=
      'SELECT T.CODIGO_ALM_ALM ' +
      '  FROM fza_almacenes T ' +
      '  JOIN fza_almacenes A ON A.CODIGO_ALM_ALM = :ALM ' +
      ' WHERE T.ESACTIVO_ALM = ''S'' ' +
      '   AND T.TIPO_USO_ALM = ''TARAS'' ' +
      '   AND T.CODIGO_EMP_ALM = A.CODIGO_EMP_ALM ' +
      ' ORDER BY (COALESCE(T.CODIGO_PADRE_ALM, '''') = :ALM) DESC, ' +
      '          T.ORDEN_ALM, T.CODIGO_ALM_ALM ' +
      ' LIMIT 1';
    oConsulta.ParamByName('ALM').AsString := AAlmacen;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

initialization
  RegistrarDataModule(TdmGarantiasReclamaciones);
  ForceReferenceToClass(TdmGarantiasReclamaciones);
end.
