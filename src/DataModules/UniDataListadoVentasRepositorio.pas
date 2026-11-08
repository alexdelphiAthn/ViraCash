{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataListadoVentasRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Lecturas UniDAC para el listado filtrable de ventas.                     }
{******************************************************************************}
unit UniDataListadoVentasRepositorio;

interface

uses
  Uni, inLibListadoVentasPersistenciaIntf;

function CrearRepositorioListadoVentasUniDAC(
  AConexion: TUniConnection): IRepositorioListadoVentas;

implementation

uses
  System.Classes, System.SysUtils, Data.DB, UniDataRectificativasSql;

const
  SQL_FAMILIAS =
    'SELECT CODIGO_FAM_FAM AS COD, ' +
    'COALESCE(NOMBRE_FAM_FAM, DESCRIPCION_FAM, CODIGO_FAM_FAM) NOM ' +
    'FROM fza_articulos_familias ' +
    'WHERE IFNULL(ESACTIVO_FAM, ''S'') = ''S'' ' +
    'ORDER BY ORDEN_FAM, CODIGO_FAM_FAM';
  SQL_PROVEEDORES =
    'SELECT CODIGO_PRV_PRV AS COD, RAZON_SOCIAL_PRV AS NOM ' +
    'FROM fza_proveedores ' +
    'WHERE IFNULL(ESACTIVO_PRV, ''S'') = ''S'' ' +
    'ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV';
  SQL_TEMPORADAS =
    'SELECT PV AS COD, PV AS NOM ' +
    'FROM fza_propiedades_valores ' +
    'WHERE ID_PROP_PV = ''TEMPORADA'' ' +
    'AND IFNULL(ESACTIVO_PV, ''S'') = ''S'' ' +
    'ORDER BY PV';

type
  TConsultaListadoVentasUniDAC = class(
    TInterfacedObject,
    IConsultaListadoVentas)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioListadoVentasUniDAC = class(
    TInterfacedObject,
    IRepositorioListadoVentas)
  private
    FConexion: TUniConnection;
    function ListarOpciones(const ASql: string): TOpcionesListadoVentas;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarFamilias: TOpcionesListadoVentas;
    function ListarProveedores: TOpcionesListadoVentas;
    function ListarTemporadas: TOpcionesListadoVentas;
    function ConsultarVentas(
      const AFiltro: TFiltroListadoVentas): IConsultaListadoVentas;
  end;

function ConstruirSqlListadoVentas: string;
const
  // Vendedor de la venta: en la factura simplificada cada línea lleva el
  // suyo; en la normal es el de la factura, que sus líneas heredan. La
  // cabecera cubre las líneas que no lo tengan.
  SQL_CODIGO_VENDEDOR =
    'COALESCE(NULLIF(TRIM(fl.`CODIGO_VENDEDOR_FACLIN`), ''''), ' +
    'NULLIF(TRIM(f.`CODIGO_CAJERO_FAC`), ''''))';
var
  Lineas: TStringList;

  procedure Anyadir(const ATexto: string);
  begin
    Lineas.Add(ATexto);
  end;

begin
  Lineas := TStringList.Create;
  try
    // FZ-ISSUE-864: repartir la cuota historica por tramo, antes de
    // filtrar articulos. El acumulado conserva hasta el ultimo centimo.
    Anyadir('WITH BASES_RECARGO AS (');
    // La empresa de la linea puede ser NULL en documentos historicos.
    // Usar siempre la cabecera, igual que en el filtro de empresa.
    Anyadir(' SELECT f.CODIGO_EMP_FAC AS CODIGO_EMP_FACLIN,');
    Anyadir('        l.SERIE_FAC_FACLIN,');
    Anyadir('        l.NUMERO_FAC_FACLIN, l.LINEA_FACLIN,');
    Anyadir('        COALESCE(l.TOTAL_FAC_SIVA_FACLIN, 0) AS BASE_LINEA,');
    Anyadir('        CASE COALESCE(NULLIF(TRIM(');
    Anyadir('          l.TIPO_IVA_ARTICULO_FACLIN), ''''), ''N'')');
    Anyadir('          WHEN ''N'' THEN COALESCE(f.TOTAL_REN_FAC, 0)');
    Anyadir('          WHEN ''R'' THEN COALESCE(f.TOTAL_RER_FAC, 0)');
    Anyadir('          WHEN ''S'' THEN COALESCE(f.TOTAL_RES_FAC, 0)');
    Anyadir('          WHEN ''E'' THEN COALESCE(f.TOTAL_REE_FAC, 0)');
    Anyadir('          ELSE 0 END AS CUOTA_GRUPO,');
    Anyadir('        SUM(COALESCE(l.TOTAL_FAC_SIVA_FACLIN, 0)) OVER W_GRUPO');
    Anyadir('          AS BASE_GRUPO,');
    Anyadir('        SUM(COALESCE(l.TOTAL_FAC_SIVA_FACLIN, 0)) OVER');
    Anyadir('          (W_GRUPO ORDER BY l.LINEA_FACLIN');
    Anyadir('            ROWS UNBOUNDED PRECEDING)');
    Anyadir('          AS BASE_ACUMULADA');
    Anyadir(' FROM fza_facturas_lineas l JOIN fza_facturas f');
    Anyadir('   ON f.SERIE_FAC = l.SERIE_FAC_FACLIN');
    Anyadir('  AND f.NUMERO_FAC = l.NUMERO_FAC_FACLIN');
    Anyadir(' WHERE f.FECHA_FAC >= :pDESDE AND f.FECHA_FAC < :pHASTA');
    Anyadir('   AND f.CODIGO_EMP_FAC = :pEMPRESA');
    Anyadir(' WINDOW W_GRUPO AS (PARTITION BY f.CODIGO_EMP_FAC,');
    Anyadir('   l.SERIE_FAC_FACLIN, l.NUMERO_FAC_FACLIN,');
    Anyadir('   COALESCE(NULLIF(TRIM(l.TIPO_IVA_ARTICULO_FACLIN),');
    Anyadir('     ''''), ''N''))');
    Anyadir('), RECARGOS_ASIGNADOS AS (');
    Anyadir(' SELECT CODIGO_EMP_FACLIN, SERIE_FAC_FACLIN, NUMERO_FAC_FACLIN,');
    Anyadir('   LINEA_FACLIN, COALESCE(');
    Anyadir('     ROUND(CUOTA_GRUPO * BASE_ACUMULADA');
    Anyadir('       / NULLIF(BASE_GRUPO, 0), 2)');
    Anyadir('     - ROUND(CUOTA_GRUPO * (BASE_ACUMULADA - BASE_LINEA)');
    Anyadir('       / NULLIF(BASE_GRUPO, 0), 2), 0) AS IMPORTE_RE');
    Anyadir(' FROM BASES_RECARGO)');
    Anyadir('SELECT L.*');
    Anyadir('  FROM (');
    Anyadir('SELECT f.`FECHA_FAC`,');
    Anyadir('       CONCAT(fl.`SERIE_FAC_FACLIN`, ''.'',');
    Anyadir('              fl.`NUMERO_FAC_FACLIN`) AS `DOCUMENTO_FAC`,');
    Anyadir('       f.`TIPO_FAC`,');
    Anyadir('       f.`FASE_FAC`,');
    Anyadir('       f.`ESCONSOLIDADA_FAC`,');
    Anyadir('       COALESCE(fl.`CODIGO_ALM_FACLIN`,');
    Anyadir('                f.`CODIGO_ALM_FAC`) AS `CODIGO_ALM_FACLIN`,');
    Anyadir('       CASE WHEN TRIM(COALESCE(f.`CODIGO_CLI_FAC`,');
    Anyadir('         '''')) IN ('''', ''0'') THEN ''''');
    Anyadir('         ELSE f.`CODIGO_CLI_FAC` END AS `CODIGO_CLI_FAC`,');
    Anyadir('       f.`RAZON_SOCIAL_CLIENTE_FAC`,');
    Anyadir('       COALESCE(' + SQL_CODIGO_VENDEDOR + ', '''')');
    Anyadir('         AS `CODIGO_VENDEDOR`,');
    Anyadir('       COALESCE(NULLIF(TRIM(ven.`NOMBRE_EMPL`), ''''),');
    Anyadir('                NULLIF(TRIM(ven.`DIMINUTIVO_TICKET_EMPL`),');
    Anyadir('                       ''''),');
    Anyadir('                ' + SQL_CODIGO_VENDEDOR + ', '''')');
    Anyadir('         AS `NOMBRE_VENDEDOR`,');
    Anyadir('       fl.`SERIE_FAC_FACLIN`,');
    Anyadir('       fl.`NUMERO_FAC_FACLIN`,');
    Anyadir('       fl.`LINEA_FACLIN`,');
    Anyadir('       fl.`CODIGO_ART_FACLIN`,');
    Anyadir('       fl.`CODIGO_UNIDAD_FACLIN`,');
    Anyadir('       fl.`DESCRIPCION_ARTICULO_FACLIN`,');
    Anyadir('       fl.`DESCRIPCION_VARIACION_FACLIN`,');
    Anyadir('       COALESCE(ap.`REF_PROVEEDOR_AP`, '''')');
    Anyadir('         AS `REF_PROVEEDOR`,');
    // Conserva el dato historico y recupera el maestro solo si falta.
    Anyadir('       COALESCE(NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Anyadir('                art.`CODIGO_FAM_ART`, '''') AS ' +
      '`CODIGO_FAM_FACLIN`,');
    // FZ-ISSUE-432: manda el nombre de la familia del maestro. Según el
    // origen, la línea guardaba el nombre o la descripción y el
    // listado partía una misma familia en dos grupos.
    Anyadir('       COALESCE(NULLIF(TRIM(fam.`NOMBRE_FAM_FAM`), ''''),');
    Anyadir('                NULLIF(fl.`NOMBRE_FAM_FACLIN`, ''''),');
    Anyadir('                NULLIF(fam.`DESCRIPCION_FAM`, ''''),');
    Anyadir('                NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Anyadir('                art.`CODIGO_FAM_ART`, '''') AS ' +
      '`NOMBRE_FAM_FACLIN`,');
    Anyadir('       COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Anyadir('                ap.`CODIGO_PRV_AP`, '''') AS ' +
      '`CODIGO_PRV_FACLIN`,');
    Anyadir('       COALESCE(NULLIF(' +
      'fl.`RAZON_SOCIAL_PROVEEDOR_FACLIN`, ''''),');
    Anyadir('                NULLIF(prv.`RAZON_SOCIAL_PRV`, ''''),');
    Anyadir('                NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Anyadir('                ap.`CODIGO_PRV_AP`, '''')');
    Anyadir('         AS `RAZON_SOCIAL_PROVEEDOR_FACLIN`,');
    Anyadir('       COALESCE(pvsku.`PV`, tsku.`VALOR_LIBRE_ARTPROP`,');
    Anyadir('                pvcol.`PV`, tcol.`VALOR_LIBRE_ARTPROP`,');
    Anyadir('                pvart.`PV`, tart.`VALOR_LIBRE_ARTPROP`,');
    Anyadir('                '''') AS `TEMPORADA_ART`,');
    Anyadir('       fl.`CANTIDAD_FACLIN`,');
    // FZ-ISSUE-432: las facturas creadas desde albarán antes del script
    // 817 no llevan precio de salida; vale el precio de la línea en los
    // términos de su tarifa.
    Anyadir('       COALESCE(NULLIF(fl.`PRECIO_SALIDA_FACLIN`, 0),');
    Anyadir('         CASE WHEN fl.`ESIMP_INCL_TARIFA_FACLIN` = ''S''');
    Anyadir('              THEN fl.`PRECIO_VENTA_CIVA_ARTICULO_FACLIN`');
    Anyadir('              ELSE fl.`PRECIO_VENTA_SIVA_ARTICULO_FACLIN`');
    Anyadir('         END, 0) AS `PRECIO_SALIDA_FACLIN`,');
    Anyadir('       fl.`PORCENTAJE_DTO_FACLIN`,');
    Anyadir('       fl.`PRECIO_VENTA_SIVA_ARTICULO_FACLIN`,');
    Anyadir('       fl.`PRECIO_VENTA_CIVA_ARTICULO_FACLIN`,');
    Anyadir('       fl.`TOTAL_FAC_SIVA_FACLIN`,');
    Anyadir('       COALESCE(fl.`TOTAL_FACLIN`, 0) +');
    Anyadir('         COALESCE(re.IMPORTE_RE, 0) AS `TOTAL_FACLIN`');
    Anyadir('  FROM `fza_facturas_lineas` fl');
    Anyadir('  JOIN `fza_facturas` f');
    Anyadir('    ON f.`NUMERO_FAC` = fl.`NUMERO_FAC_FACLIN`');
    Anyadir('   AND f.`SERIE_FAC` = fl.`SERIE_FAC_FACLIN`');
    Anyadir('  LEFT JOIN RECARGOS_ASIGNADOS re');
    Anyadir('    ON re.CODIGO_EMP_FACLIN = f.CODIGO_EMP_FAC');
    Anyadir('   AND re.SERIE_FAC_FACLIN = fl.SERIE_FAC_FACLIN');
    Anyadir('   AND re.NUMERO_FAC_FACLIN = fl.NUMERO_FAC_FACLIN');
    Anyadir('   AND re.LINEA_FACLIN = fl.LINEA_FACLIN');
    Anyadir('  LEFT JOIN `fza_empleados` ven');
    Anyadir('    ON ven.`CODIGO_EMPL` = ' + SQL_CODIGO_VENDEDOR);
    Anyadir('  LEFT JOIN `fza_articulos` art');
    Anyadir('    ON art.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Anyadir('  LEFT JOIN `fza_articulos_familias` fam');
    Anyadir('    ON fam.`CODIGO_FAM_FAM` =');
    Anyadir('       COALESCE(NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Anyadir('                art.`CODIGO_FAM_ART`)');
    Anyadir('  LEFT JOIN `fza_articulos_proveedores` ap');
    Anyadir('    ON ap.`CODIGO_ART_AP` = art.`CODIGO_ART_ART`');
    Anyadir('   AND ap.`CODIGO_PRV_AP` =');
    // Usa el proveedor historico de la venta y el principal como respaldo.
    Anyadir('       COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Anyadir('         (SELECT apx.`CODIGO_PRV_AP`');
    Anyadir('            FROM `fza_articulos_proveedores` apx');
    Anyadir('           WHERE apx.`CODIGO_ART_AP` = art.`CODIGO_ART_ART`');
    Anyadir('           ORDER BY CASE');
    Anyadir('                      WHEN apx.`ESPROVEEDORPRINCIPAL_AP` = ''S''');
    Anyadir('                      THEN 0 ELSE 1');
    Anyadir('                    END,');
    Anyadir('                    apx.`FECHA_VALIDEZ_AP` DESC,');
    Anyadir('                    apx.`CODIGO_PRV_AP`');
    Anyadir('           LIMIT 1))');
    Anyadir('  LEFT JOIN `fza_proveedores` prv');
    Anyadir('    ON prv.`CODIGO_PRV_PRV` =');
    Anyadir('       COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Anyadir('                ap.`CODIGO_PRV_AP`)');
    Anyadir('  LEFT JOIN `fza_articulos_propiedades` tsku');
    Anyadir('    ON tsku.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Anyadir('   AND tsku.`CODIGO_PROP_ARTPROP` = ''TEMPORADA''');
    Anyadir('   AND tsku.`CODIGO_UNIDAD_ARTPROP` = fl.`CODIGO_UNIDAD_FACLIN`');
    Anyadir('  LEFT JOIN `fza_propiedades_valores` pvsku');
    Anyadir('    ON pvsku.`ID_PV_ARTPROP` = tsku.`ID_PV_ARTPROP`');
    Anyadir('  LEFT JOIN `fza_articulos_propiedades` tcol');
    Anyadir('    ON tcol.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Anyadir('   AND tcol.`CODIGO_PROP_ARTPROP` = ''TEMPORADA''');
    Anyadir('   AND tcol.`CODIGO_UNIDAD_ARTPROP` =');
    Anyadir('       SUBSTRING_INDEX(fl.`CODIGO_UNIDAD_FACLIN`, ''/'', 2)');
    Anyadir('  LEFT JOIN `fza_propiedades_valores` pvcol');
    Anyadir('    ON pvcol.`ID_PV_ARTPROP` = tcol.`ID_PV_ARTPROP`');
    Anyadir('  LEFT JOIN `fza_articulos_propiedades` tart');
    Anyadir('    ON tart.`CODIGO_ART_ART` = fl.`CODIGO_ART_FACLIN`');
    Anyadir('   AND tart.`CODIGO_PROP_ARTPROP` = ''TEMPORADA''');
    Anyadir('   AND tart.`CODIGO_UNIDAD_ARTPROP` = ''''');
    Anyadir('  LEFT JOIN `fza_propiedades_valores` pvart');
    Anyadir('    ON pvart.`ID_PV_ARTPROP` = tart.`ID_PV_ARTPROP`');
    Anyadir(' WHERE f.`FECHA_FAC` >= :pDESDE');
    Anyadir('   AND f.`FECHA_FAC` < :pHASTA');
    Anyadir('   AND f.CODIGO_EMP_FAC = :pEMPRESA');
    Anyadir('   AND (:pFAM = '''' OR');
    Anyadir('        COALESCE(NULLIF(TRIM(fl.`CODIGO_FAM_FACLIN`), ''''),');
    Anyadir('                 art.`CODIGO_FAM_ART`) = :pFAM)');
    Anyadir('   AND (:pPRV = '''' OR');
    Anyadir('        COALESCE(NULLIF(TRIM(fl.`CODIGO_PRV_FACLIN`), ''''),');
    Anyadir('                 ap.`CODIGO_PRV_AP`) = :pPRV)');
    Anyadir('   AND (:pCON = ''N''');
    Anyadir('        OR COALESCE(f.`ESCONSOLIDADA_FAC`, ''N'') = ''S'')');
    Anyadir('   AND COALESCE(f.`FASE_FAC`, '''') <> ''CANCELADA''');
    Anyadir(SQLExcluirVentaRetirada(
      'f.CODIGO_EMP_FAC', 'f.SERIE_FAC', 'f.NUMERO_FAC'));
    // FZ-ISSUE-388: las líneas del ticket convertido en factura normal
    // ya salen con la factura que lo sustituye.
    Anyadir(SQLExcluirTicketSustituido(
      'f.CODIGO_EMP_FAC', 'f.SERIE_FAC', 'f.NUMERO_FAC'));
    Anyadir('       ) L');
    Anyadir(' WHERE (:pTMP = '''' OR L.`TEMPORADA_ART` = :pTMP)');
    Anyadir(' ORDER BY L.`FECHA_FAC` DESC, L.`SERIE_FAC_FACLIN`,');
    Anyadir('          L.`NUMERO_FAC_FACLIN`, L.`LINEA_FACLIN`');
    Result := Lineas.Text;
  finally
    FreeAndNil(Lineas);
  end;
end;

constructor TConsultaListadoVentasUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaListadoVentasUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaListadoVentasUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioListadoVentasUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TRepositorioListadoVentasUniDAC.ListarOpciones(
  const ASql: string): TOpcionesListadoVentas;
var
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := ASql;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion].Codigo := Consulta.FieldByName('COD').AsString;
      Result[Posicion].Nombre := Consulta.FieldByName('NOM').AsString;
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioListadoVentasUniDAC.ListarFamilias:
  TOpcionesListadoVentas;
begin
  Result := ListarOpciones(SQL_FAMILIAS);
end;

function TRepositorioListadoVentasUniDAC.ListarProveedores:
  TOpcionesListadoVentas;
begin
  Result := ListarOpciones(SQL_PROVEEDORES);
end;

function TRepositorioListadoVentasUniDAC.ListarTemporadas:
  TOpcionesListadoVentas;
begin
  Result := ListarOpciones(SQL_TEMPORADAS);
end;

function TRepositorioListadoVentasUniDAC.ConsultarVentas(
  const AFiltro: TFiltroListadoVentas): IConsultaListadoVentas;
var
  Consulta: TUniQuery;
begin
  if Trim(AFiltro.Empresa) = '' then
    raise EArgumentException.Create('Debe indicar la empresa de sesion');
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := FConexion;
    Consulta.SQL.Text := ConstruirSqlListadoVentas;
    Consulta.ParamByName('pEMPRESA').AsString := AFiltro.Empresa;
    Consulta.ParamByName('pDESDE').AsDateTime := AFiltro.FechaDesde;
    Consulta.ParamByName('pHASTA').AsDateTime := AFiltro.FechaHastaExclusiva;
    Consulta.ParamByName('pFAM').AsString := AFiltro.Familia;
    Consulta.ParamByName('pPRV').AsString := AFiltro.Proveedor;
    Consulta.ParamByName('pTMP').AsString := AFiltro.Temporada;
    if AFiltro.SoloConsolidadas then
      Consulta.ParamByName('pCON').AsString := 'S'
    else
      Consulta.ParamByName('pCON').AsString := 'N';
    Consulta.Open;
    Result := TConsultaListadoVentasUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function CrearRepositorioListadoVentasUniDAC(
  AConexion: TUniConnection): IRepositorioListadoVentas;
begin
  Result := TRepositorioListadoVentasUniDAC.Create(AConexion);
end;

end.
