{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDistribucionTiendasRepositorio                         }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adaptador UniDAC de la distribución entre tiendas: unidades del           }
{    documento de trabajo, stock por almacén y propuestas de traspaso          }
{    (fza_traspasos_propuestas y fza_traspasos_propuestas_lineas).             }
{******************************************************************************}
unit UniDataDistribucionTiendasRepositorio;

interface

uses
  System.SysUtils, Uni,
  inLibDistribucionTiendasIntf;

type
  // Las propuestas del documento cambiaron (alguien confirmó una) desde que
  // se cargó la distribución: hay que recargar antes de guardar.
  EDistribucionTiendasDesactualizada = class(Exception);

function CrearRepositorioDistribucionTiendasUniDAC(
  AConexion: TUniConnection): IRepositorioDistribucionTiendas;

// SQL expuesto para las pruebas de contrato e integración.
function SqlUnidadesDocumentoDistribucion: string;
function SqlAlmacenesDistribucion: string;
function SqlStocksDistribucion(ANumeroSkus: Integer): string;
function SqlAsignacionesDistribucion: string;
function SqlFirmaPropuestasResueltas: string;
function SqlRechazarPropuestaTraspaso: string;
function SqlGuardarPrioridadAlmacen: string;
function SqlCabecerasPropuestasTraspaso(const AFiltro: string): string;
function SqlLineasPropuestasTraspaso(const AFiltro: string): string;
function SqlInsertarPropuestaTraspaso: string;
function SqlInsertarLineaPropuestaTraspaso: string;
function SqlBorrarLineasPropuestasPendientes: string;
function SqlBorrarPropuestasPendientesVacias: string;
function SqlBloquearPropuestasPendientes: string;

const
  FILTRO_PROPUESTAS_DOCUMENTO = 'P.ID_DTR_TRPRO = :ID_DTR';
  // Las que caja aún puede traspasar: pendientes y trasladadas en parte.
  FILTRO_PROPUESTAS_PENDIENTES_ORIGEN =
    'P.CODIGO_ALM_ORIGEN_TRPRO = :ORIGEN ' +
    'AND P.ESTADO_TRPRO IN (''PENDIENTE'', ''TRASLADADO PARCIAL'')';
  FILTRO_PROPUESTA_POR_ID = 'P.ID_TRPRO = :ID_TRPRO';

implementation

uses
  System.Generics.Collections, Data.DB,
  inLibMsgDistribucionTiendas;

const
  TOLERANCIA_CANTIDAD = 0.000001;
  SEPARADOR_CLAVE = #9;

type
  TRepositorioDistribucionTiendasUniDAC = class(
    TInterfacedObject,
    IRepositorioDistribucionTiendas)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function LeerTitulo(
      AConsulta: TUniQuery; AIdDocumento: Int64): string;
    function LeerUnidades(
      AConsulta: TUniQuery;
      AIdDocumento: Int64): TUnidadesDocumentoDistribucion;
    function LeerAlmacenes(
      AConsulta: TUniQuery;
      AIdDocumento: Int64): TAlmacenesDistribucion;
    function LeerStocksConsulta(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      const ASkus: TArray<string>): TStocksDistribucion;
    function LeerAsignaciones(
      AConsulta: TUniQuery;
      AIdDocumento: Int64): TAsignacionesDistribucion;
    function LeerPropuestas(
      const AFiltro, AParametro: string;
      const AValor: Variant): TPropuestasTraspaso;
    procedure LeerLineasPropuestas(
      AConsulta: TUniQuery;
      const AFiltro, AParametro: string;
      const AValor: Variant;
      var APropuestas: TPropuestasTraspaso);
    function LeerFirmaResueltas(
      AConsulta: TUniQuery; AIdDocumento: Int64): string;
    procedure CargarPropuestasPendientes(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      APendientes: TDictionary<string, Int64>);
    function AsegurarPropuestaPendiente(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      const AAsignacion: TAsignacionDistribucion;
      const AUsuario: string;
      APendientes: TDictionary<string, Int64>): Int64;
    procedure InsertarLinea(
      AConsulta: TUniQuery;
      AIdDocumento, AIdPropuesta: Int64;
      const AAsignacion: TAsignacionDistribucion;
      const AUsuario: string);
    procedure SincronizarPropuestas(
      AConsulta: TUniQuery;
      AIdDocumento: Int64;
      const AFirmaResueltas: string;
      const AAsignaciones: TAsignacionesDistribucion;
      const AUsuario: string);
  public
    constructor Create(AConexion: TUniConnection);
    // Lecturas
    function CargarDocumento(
      AIdDocumento: Int64): TDocumentoDistribucion;
    function ListarAlmacenesDestino: TAlmacenesDistribucion;
    function LeerPropuesta(AIdPropuesta: Int64): TPropuestaTraspaso;
    function LeerStocks(
      AIdDocumento: Int64;
      const ASkus: TArray<string>): TStocksDistribucion;
    function ListarPropuestasPendientesOrigen(
      const AAlmacenOrigen: string): TPropuestasTraspaso;
    function ListarPropuestasDocumento(
      AIdDocumento: Int64): TPropuestasTraspaso;
    // Escrituras
    procedure GuardarPrioridadesAlmacenes(
      const APrioridades: TPrioridadesAlmacenDistribucion;
      const AUsuario: string);
    function RechazarPropuesta(
      AIdPropuesta: Int64;
      const AMotivo, AUsuario: string): Boolean;
    function EliminarPropuestaPendiente(AIdPropuesta: Int64): Boolean;
    procedure GuardarPropuestas(
      AIdDocumento: Int64;
      const AFirmaResueltas: string;
      const AAsignaciones: TAsignacionesDistribucion;
      const AUsuario: string);
  end;

function ClavePareja(const AOrigen, ADestino: string): string;
begin
  Result := AnsiUpperCase(Trim(AOrigen)) + SEPARADOR_CLAVE +
    AnsiUpperCase(Trim(ADestino));
end;

// ===========================================================================
//   SQL
// ===========================================================================

// Color, talla y orden de talla de un SKU. El color es el atributo 'CO';
// la talla, el resto de atributos. El orden sigue el criterio de la
// consulta de stock: artículo, conjunto del artículo y valor global.
function SqlAtributosSku(const ACampoSku, ACampoArticulo: string): string;
begin
  Result :=
    '       COALESCE((SELECT MIN(AVC.AV) ' +
    '                   FROM fza_atributos_sku SAC ' +
    '                   JOIN fza_atributos_valores AVC ' +
    '                     ON AVC.ID_AV = SAC.ID_AV_SA ' +
    '                  WHERE SAC.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku +
    '                    AND AVC.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = (SELECT SK452.CODIGO_VAR_SKU FROM ' +
    'fza_articulos_skus SK452 WHERE SK452.CODIGO_UNIDAD_SKU = ' +
    'SAC.CODIGO_UNIDAD_SKU_SA) AND EJ452.EJE_VA = ''F'')), '''') AS ' +
    'COLOR, ' +
    '       COALESCE((SELECT GROUP_CONCAT(AVT.AV ' +
    '                          ORDER BY AVT.ID_VA_AV SEPARATOR ''/'') ' +
    '                   FROM fza_atributos_sku SAT ' +
    '                   JOIN fza_atributos_valores AVT ' +
    '                     ON AVT.ID_AV = SAT.ID_AV_SA ' +
    '                  WHERE SAT.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku +
    '                    AND AVT.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = (SELECT SK452.CODIGO_VAR_SKU FROM ' +
    'fza_articulos_skus SK452 WHERE SK452.CODIGO_UNIDAD_SKU = ' +
    'SAT.CODIGO_UNIDAD_SKU_SA) AND EJ452.EJE_VA = ''P'')), '''') AS ' +
    'TALLA, ' +
    '       COALESCE((SELECT MIN(COALESCE(AAB.ORDEN_AAB, ' +
    '                                     ACD.ORDEN_ACD, ' +
    '                                     AVO.ORDEN_AV)) ' +
    '                   FROM fza_atributos_sku SAO ' +
    '                   JOIN fza_atributos_valores AVO ' +
    '                     ON AVO.ID_AV = SAO.ID_AV_SA ' +
    '                   LEFT JOIN fza_articulos_atributos_basicos AAB ' +
    '                     ON AAB.CODIGO_ART_AAB = ' + ACampoArticulo +
    '                    AND AAB.ID_AV_AAB = AVO.ID_AV ' +
    '                   LEFT JOIN fza_articulos_conjuntos_asign ACA ' +
    '                     ON ACA.CODIGO_ART_ACA = ' + ACampoArticulo +
    '                    AND ACA.ID_VA_ACA = AVO.ID_VA_AV ' +
    '                   LEFT JOIN fza_atributos_conjuntos_det ACD ' +
    '                     ON ACD.ID_AC_ACD = ACA.ID_AC_ACA ' +
    '                    AND ACD.ID_AV_ACD = AVO.ID_AV ' +
    '                  WHERE SAO.CODIGO_UNIDAD_SKU_SA = ' + ACampoSku +
    '                    AND AVO.ID_VA_AV = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = (SELECT SK452.CODIGO_VAR_SKU FROM ' +
    'fza_articulos_skus SK452 WHERE SK452.CODIGO_UNIDAD_SKU = ' +
    'SAO.CODIGO_UNIDAD_SKU_SA) AND EJ452.EJE_VA = ''P'')), 0) AS ' +
    'ORDEN_TALLA ';
end;

// Una fila por almacén y SKU. El almacén de la línea manda; si no lo
// lleva, el de la cabecera del documento. Las líneas sin SKU cerrado o sin
// unidades no se pueden repartir.
function SqlUnidadesDocumentoDistribucion: string;
begin
  Result :=
    'SELECT L.CODIGO_ALM, L.CODIGO_ART, L.CODIGO_UNIDAD, ' +
    '       L.DESCRIPCION, L.CANTIDAD, ' +
    SqlAtributosSku('L.CODIGO_UNIDAD', 'L.CODIGO_ART') +
    '  FROM (SELECT COALESCE(NULLIF(DTL.CODIGO_ALM_DTL, ''''), ' +
    '                        DTR.CODIGO_ALM_DTR, '''') AS CODIGO_ALM, ' +
    '               DTL.CODIGO_ART_DTL AS CODIGO_ART, ' +
    '               DTL.CODIGO_UNIDAD_DTL AS CODIGO_UNIDAD, ' +
    '               MAX(COALESCE(DTL.DESCRIPCION_ARTICULO_DTL, '''')) ' +
    '                 AS DESCRIPCION, ' +
    '               SUM(DTL.CANTIDAD_DTL) AS CANTIDAD ' +
    '          FROM fza_documentos_trabajo_lineas DTL ' +
    '          JOIN fza_documentos_trabajo DTR ' +
    '            ON DTR.ID_DTR = DTL.ID_DTR_DTL ' +
    '         WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '           AND COALESCE(DTL.CODIGO_UNIDAD_DTL, '''') <> '''' ' +
    '         GROUP BY COALESCE(NULLIF(DTL.CODIGO_ALM_DTL, ''''), ' +
    '                           DTR.CODIGO_ALM_DTR, ''''), ' +
    '                  DTL.CODIGO_ART_DTL, DTL.CODIGO_UNIDAD_DTL ' +
    '        HAVING SUM(DTL.CANTIDAD_DTL) > 0) L ' +
    ' WHERE L.CODIGO_ALM <> '''' ' +
    ' ORDER BY L.CODIGO_ART, COLOR, ORDEN_TALLA, TALLA, L.CODIGO_ALM';
end;

// Solo una tienda puede ser destino: almacén activo de uso estándar. Los
// de taras, depósito o tránsito, nunca. El tipo vacío cuenta como estándar,
// que es el valor por omisión de la columna.
function CondicionSqlAlmacenAdmiteDestino: string;
begin
  Result :=
    '(ALM.ESACTIVO_ALM = ''S'' ' +
    ' AND COALESCE(NULLIF(TRIM(ALM.TIPO_USO_ALM), ''''), ''ESTANDAR'') ' +
    '     IN (''ESTANDAR'', ''ESTANDARD''))';
end;

// Las tiendas y, además, cualquier almacén que el documento use como
// origen o que ya figure como destino en sus propuestas, aunque no lo sea.
function SqlAlmacenesDistribucion: string;
begin
  Result :=
    'SELECT ALM.CODIGO_ALM_ALM, ' +
    '       COALESCE(ALM.NOMBRE_ALM_ALM, '''') AS NOMBRE_ALM_ALM, ' +
    '       COALESCE(ALM.ORDEN_ALM, 0) AS ORDEN_ALM, ' +
    '       COALESCE(ALM.ORDEN_DISTRIBUCION_ALM, 0) ' +
    '         AS ORDEN_DISTRIBUCION_ALM, ' +
    '       CASE WHEN ' + CondicionSqlAlmacenAdmiteDestino +
    '            THEN ''S'' ELSE ''N'' END AS ADMITE_DESTINO ' +
    '  FROM fza_almacenes ALM ' +
    ' WHERE ' + CondicionSqlAlmacenAdmiteDestino +
    '    OR EXISTS (SELECT 1 ' +
    '                 FROM fza_documentos_trabajo_lineas DTL ' +
    '                 JOIN fza_documentos_trabajo DTR ' +
    '                   ON DTR.ID_DTR = DTL.ID_DTR_DTL ' +
    '                WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '                  AND COALESCE(NULLIF(DTL.CODIGO_ALM_DTL, ''''), ' +
    '                               DTR.CODIGO_ALM_DTR) = ' +
    '                      ALM.CODIGO_ALM_ALM) ' +
    '    OR EXISTS (SELECT 1 ' +
    '                 FROM fza_traspasos_propuestas PRO ' +
    '                WHERE PRO.ID_DTR_TRPRO = :ID_DTR ' +
    '                  AND PRO.CODIGO_ALM_DESTINO_TRPRO = ' +
    '                      ALM.CODIGO_ALM_ALM) ' +
    ' ORDER BY COALESCE(ALM.ORDEN_ALM, 0), ALM.CODIGO_ALM_ALM';
end;

function NombreParametroSku(AIndice: Integer): string;
begin
  Result := 'SKU' + IntToStr(AIndice);
end;

// La clave del stock empieza por el almacén: se entra por almacén y SKU
// (y en ese orden) para no recorrer la tabla entera. Con ANumeroSkus > 0
// solo se leen esos SKU del documento (:SKU0, :SKU1...).
function SqlStocksDistribucion(ANumeroSkus: Integer): string;
var
  i: Integer;
  sFiltro: string;
begin
  sFiltro := '';
  for i := 0 to ANumeroSkus - 1 do
  begin
    if i > 0 then
      sFiltro := sFiltro + ', ';
    sFiltro := sFiltro + ':' + NombreParametroSku(i);
  end;
  if sFiltro <> '' then
    sFiltro := ' AND DTL.CODIGO_UNIDAD_DTL IN (' + sFiltro + ') ';
  Result :=
    'SELECT STRAIGHT_JOIN STK.CODIGO_ALM_STK, STK.CODIGO_UNIDAD_STK, ' +
    '       SUM(STK.CANTIDAD_STK) AS CANTIDAD ' +
    '  FROM (SELECT DISTINCT DTL.CODIGO_UNIDAD_DTL AS CODIGO_UNIDAD ' +
    '          FROM fza_documentos_trabajo_lineas DTL ' +
    '         WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '           AND DTL.CODIGO_UNIDAD_DTL <> '''' ' + sFiltro + ') D ' +
    ' CROSS JOIN fza_almacenes ALM ' +
    '  JOIN fza_articulos_stockactual STK ' +
    '    ON STK.CODIGO_ALM_STK = ALM.CODIGO_ALM_ALM ' +
    '   AND STK.CODIGO_UNIDAD_STK = D.CODIGO_UNIDAD ' +
    ' GROUP BY STK.CODIGO_ALM_STK, STK.CODIGO_UNIDAD_STK';
end;

// Lo trasladado cuenta por lo realmente traspasado; lo pendiente, por lo
// propuesto. Lo trasladado en parte sigue en marcha en caja: cuenta entero
// (o lo traspasado, si pasa de lo propuesto) y no se puede rebajar hasta
// que se dé por trasladado. Lo no aceptado no cuenta: sus unidades vuelven
// a estar por repartir.
function SqlAsignacionesDistribucion: string;
begin
  Result :=
    'SELECT P.CODIGO_ALM_ORIGEN_TRPRO AS ORIGEN, ' +
    '       P.CODIGO_ALM_DESTINO_TRPRO AS DESTINO, ' +
    '       L.CODIGO_UNIDAD_TRPROLIN AS CODIGO_UNIDAD, ' +
    '       SUM(CASE WHEN P.ESTADO_TRPRO = ''TRASLADADO'' ' +
    '                THEN L.CANTIDAD_TRASPASADA_TRPROLIN ' +
    '                WHEN P.ESTADO_TRPRO = ''TRASLADADO PARCIAL'' ' +
    '                THEN GREATEST(L.CANTIDAD_TRPROLIN, ' +
    '                              L.CANTIDAD_TRASPASADA_TRPROLIN) ' +
    '                ELSE 0 END) AS CONFIRMADA, ' +
    '       SUM(CASE WHEN P.ESTADO_TRPRO = ''PENDIENTE'' ' +
    '                THEN L.CANTIDAD_TRPROLIN ' +
    '                ELSE 0 END) AS PENDIENTE ' +
    '  FROM fza_traspasos_propuestas P ' +
    '  JOIN fza_traspasos_propuestas_lineas L ' +
    '    ON L.ID_TRPRO_TRPROLIN = P.ID_TRPRO ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO IN (''PENDIENTE'', ''TRASLADADO'', ' +
    '                          ''TRASLADADO PARCIAL'') ' +
    ' GROUP BY P.CODIGO_ALM_ORIGEN_TRPRO, P.CODIGO_ALM_DESTINO_TRPRO, ' +
    '          L.CODIGO_UNIDAD_TRPROLIN';
end;

// Huella de las propuestas que ya no están pendientes: cuántas son, la
// última y cuándo se resolvió. Cambia en cuanto se traslada o se rechaza
// cualquiera.
function SqlFirmaPropuestasResueltas: string;
begin
  Result :=
    'SELECT CONCAT(COUNT(*), ''|'', COALESCE(MAX(P.ID_TRPRO), 0), ''|'', ' +
    '              COALESCE(DATE_FORMAT(' +
    '                MAX(P.INSTANTE_RESOLUCION_TRPRO), ' +
    '                ''%Y%m%d%H%i%s''), '''')) AS FIRMA ' +
    '  FROM fza_traspasos_propuestas P ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO <> ''PENDIENTE''';
end;

// El estado va en el predicado: si ya se trasladó o se rechazó, no cuadra
// ninguna fila. Una trasladada en parte no se puede deshacer: no aceptar
// lo que falta la da por trasladada con lo ya traspasado (el CASE lee el
// estado anterior a la asignación).
function SqlRechazarPropuestaTraspaso: string;
begin
  Result :=
    'UPDATE fza_traspasos_propuestas ' +
    '   SET ESTADO_TRPRO = CASE WHEN ESTADO_TRPRO = ''TRASLADADO PARCIAL'' ' +
    '                           THEN ''TRASLADADO'' ' +
    '                           ELSE ''NO ACEPTADO'' END, ' +
    '       MOTIVO_RECHAZO_TRPRO = :MOTIVO, ' +
    '       INSTANTE_RESOLUCION_TRPRO = NOW(), ' +
    '       USUARIO_RESOLUCION_TRPRO = :USUARIO, ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_TRPRO = :ID_TRPRO ' +
    '   AND ESTADO_TRPRO IN (''PENDIENTE'', ''TRASLADADO PARCIAL'')';
end;

// Cero o negativo = sin número: el almacén no recibe traspasos desde la
// distribución. A un almacén que no es tienda no se le guarda número.
function SqlGuardarPrioridadAlmacen: string;
begin
  Result :=
    'UPDATE fza_almacenes ALM ' +
    '   SET ALM.ORDEN_DISTRIBUCION_ALM = ' +
    '         CASE WHEN :PRIORIDAD > 0 AND ' +
    CondicionSqlAlmacenAdmiteDestino +
    '              THEN :PRIORIDAD ELSE NULL END, ' +
    '       ALM.USUARIO_MODIF = :USUARIO ' +
    ' WHERE ALM.CODIGO_ALM_ALM = :ALMACEN';
end;

function SqlCabecerasPropuestasTraspaso(const AFiltro: string): string;
begin
  Result :=
    'SELECT P.ID_TRPRO, P.ID_DTR_TRPRO, ' +
    '       COALESCE(DTR.TITULO_DTR, '''') AS TITULO_DTR, ' +
    '       P.INSTANTE_PROPUESTA_TRPRO, P.ESTADO_TRPRO, ' +
    '       P.CODIGO_ALM_ORIGEN_TRPRO, ' +
    '       COALESCE(AO.NOMBRE_ALM_ALM, '''') AS NOMBRE_ORIGEN, ' +
    '       P.CODIGO_ALM_DESTINO_TRPRO, ' +
    '       COALESCE(AD.NOMBRE_ALM_ALM, '''') AS NOMBRE_DESTINO, ' +
    '       COALESCE(P.TIPO_DOC_TRPRO, '''') AS TIPO_DOC_TRPRO, ' +
    '       COALESCE(P.SERIE_DOC_TRPRO, '''') AS SERIE_DOC_TRPRO, ' +
    '       COALESCE(P.NUMERO_DOC_TRPRO, '''') AS NUMERO_DOC_TRPRO, ' +
    '       COALESCE(P.NUMERO_OPERACION_TRPRO, '''') ' +
    '         AS NUMERO_OPERACION_TRPRO, ' +
    '       COALESCE(P.MOTIVO_RECHAZO_TRPRO, '''') ' +
    '         AS MOTIVO_RECHAZO_TRPRO ' +
    '  FROM fza_traspasos_propuestas P ' +
    '  LEFT JOIN fza_documentos_trabajo DTR ' +
    '    ON DTR.ID_DTR = P.ID_DTR_TRPRO ' +
    '  LEFT JOIN fza_almacenes AO ' +
    '    ON AO.CODIGO_ALM_ALM = P.CODIGO_ALM_ORIGEN_TRPRO ' +
    '  LEFT JOIN fza_almacenes AD ' +
    '    ON AD.CODIGO_ALM_ALM = P.CODIGO_ALM_DESTINO_TRPRO ' +
    ' WHERE ' + AFiltro + ' ' +
    ' ORDER BY P.CODIGO_ALM_ORIGEN_TRPRO, P.CODIGO_ALM_DESTINO_TRPRO, ' +
    '          P.ID_TRPRO';
end;

function SqlLineasPropuestasTraspaso(const AFiltro: string): string;
begin
  Result :=
    'SELECT L.ID_TRPRO_TRPROLIN, L.CODIGO_ART_TRPROLIN, ' +
    '       COALESCE(L.DESCRIPCION_ARTICULO_TRPROLIN, '''') ' +
    '         AS DESCRIPCION_ARTICULO_TRPROLIN, ' +
    '       L.CODIGO_UNIDAD_TRPROLIN, L.CANTIDAD_TRPROLIN, ' +
    '       L.CANTIDAD_TRASPASADA_TRPROLIN, ' +
    SqlAtributosSku('L.CODIGO_UNIDAD_TRPROLIN', 'L.CODIGO_ART_TRPROLIN') +
    '  FROM fza_traspasos_propuestas_lineas L ' +
    '  JOIN fza_traspasos_propuestas P ' +
    '    ON P.ID_TRPRO = L.ID_TRPRO_TRPROLIN ' +
    ' WHERE ' + AFiltro + ' ' +
    ' ORDER BY L.ID_TRPRO_TRPROLIN, L.CODIGO_ART_TRPROLIN, COLOR, ' +
    '          ORDEN_TALLA, TALLA';
end;

function SqlBloquearPropuestasPendientes: string;
begin
  Result :=
    'SELECT P.ID_TRPRO, P.CODIGO_ALM_ORIGEN_TRPRO, ' +
    '       P.CODIGO_ALM_DESTINO_TRPRO ' +
    '  FROM fza_traspasos_propuestas P ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO = ''PENDIENTE'' ' +
    ' ORDER BY P.ID_TRPRO ' +
    '   FOR UPDATE';
end;

function SqlInsertarPropuestaTraspaso: string;
begin
  Result :=
    'INSERT INTO fza_traspasos_propuestas (' +
    '  ID_DTR_TRPRO, INSTANTE_PROPUESTA_TRPRO, ESTADO_TRPRO, ' +
    '  CODIGO_ALM_ORIGEN_TRPRO, CODIGO_ALM_DESTINO_TRPRO, ' +
    '  INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (' +
    '  :ID_DTR, NOW(), ''PENDIENTE'', :ORIGEN, :DESTINO, ' +
    '  NOW(), :USUARIO, :USUARIO)';
end;

// El artículo y su descripción salen de las líneas del documento: si el
// SKU ya no está en él, no se inserta nada y el llamante lo detecta.
function SqlInsertarLineaPropuestaTraspaso: string;
begin
  Result :=
    'INSERT INTO fza_traspasos_propuestas_lineas (' +
    '  ID_TRPRO_TRPROLIN, CODIGO_UNIDAD_TRPROLIN, CODIGO_ART_TRPROLIN, ' +
    '  DESCRIPCION_ARTICULO_TRPROLIN, CANTIDAD_TRPROLIN, ' +
    '  CANTIDAD_TRASPASADA_TRPROLIN, INSTANTE_ALTA, USUARIO_ALTA, ' +
    '  USUARIO_MODIF) ' +
    'SELECT :ID_TRPRO, MAX(DTL.CODIGO_UNIDAD_DTL), ' +
    '       MAX(DTL.CODIGO_ART_DTL), ' +
    '       MAX(DTL.DESCRIPCION_ARTICULO_DTL), :CANTIDAD, 0, NOW(), ' +
    '       :USUARIO, :USUARIO ' +
    '  FROM fza_documentos_trabajo_lineas DTL ' +
    ' WHERE DTL.ID_DTR_DTL = :ID_DTR ' +
    '   AND DTL.CODIGO_UNIDAD_DTL = :CODIGO_UNIDAD ' +
    'HAVING COUNT(*) > 0';
end;

function SqlBorrarLineasPropuestasPendientes: string;
begin
  Result :=
    'DELETE L ' +
    '  FROM fza_traspasos_propuestas_lineas L ' +
    '  JOIN fza_traspasos_propuestas P ' +
    '    ON P.ID_TRPRO = L.ID_TRPRO_TRPROLIN ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO = ''PENDIENTE''';
end;

function SqlBorrarPropuestasPendientesVacias: string;
begin
  Result :=
    'DELETE P ' +
    '  FROM fza_traspasos_propuestas P ' +
    ' WHERE P.ID_DTR_TRPRO = :ID_DTR ' +
    '   AND P.ESTADO_TRPRO = ''PENDIENTE'' ' +
    '   AND NOT EXISTS (SELECT 1 ' +
    '                     FROM fza_traspasos_propuestas_lineas L ' +
    '                    WHERE L.ID_TRPRO_TRPROLIN = P.ID_TRPRO)';
end;

// ===========================================================================
//   Repositorio
// ===========================================================================

function CrearRepositorioDistribucionTiendasUniDAC(
  AConexion: TUniConnection): IRepositorioDistribucionTiendas;
begin
  Result := TRepositorioDistribucionTiendasUniDAC.Create(AConexion);
end;

constructor TRepositorioDistribucionTiendasUniDAC.Create(
  AConexion: TUniConnection);
begin
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDistribucionTiendasUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerTitulo(
  AConsulta: TUniQuery; AIdDocumento: Int64): string;
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT DTR.TITULO_DTR ' +
    '  FROM fza_documentos_trabajo DTR ' +
    ' WHERE DTR.ID_DTR = :ID_DTR';
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  if AConsulta.IsEmpty then
    raise EArgumentException.CreateFmt(
      SErrorDocumentoDistribucionNoExiste, [AIdDocumento]);
  Result := AConsulta.FieldByName('TITULO_DTR').AsString;
  AConsulta.Close;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerUnidades(
  AConsulta: TUniQuery;
  AIdDocumento: Int64): TUnidadesDocumentoDistribucion;
var
  Lista: TList<TUnidadDocumentoDistribucion>;
  Unidad: TUnidadDocumentoDistribucion;
begin
  Lista := TList<TUnidadDocumentoDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlUnidadesDocumentoDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Unidad.CodigoAlmacen := AConsulta.FieldByName('CODIGO_ALM').AsString;
      Unidad.CodigoArticulo :=
        AConsulta.FieldByName('CODIGO_ART').AsString;
      Unidad.DescripcionArticulo :=
        AConsulta.FieldByName('DESCRIPCION').AsString;
      Unidad.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD').AsString;
      Unidad.Color := AConsulta.FieldByName('COLOR').AsString;
      Unidad.Talla := AConsulta.FieldByName('TALLA').AsString;
      Unidad.OrdenTalla := AConsulta.FieldByName('ORDEN_TALLA').AsInteger;
      Unidad.Cantidad := AConsulta.FieldByName('CANTIDAD').AsFloat;
      Lista.Add(Unidad);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerAlmacenes(
  AConsulta: TUniQuery;
  AIdDocumento: Int64): TAlmacenesDistribucion;
var
  Lista: TList<TAlmacenDistribucion>;
  Almacen: TAlmacenDistribucion;
begin
  Lista := TList<TAlmacenDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlAlmacenesDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Almacen.Codigo := AConsulta.FieldByName('CODIGO_ALM_ALM').AsString;
      Almacen.Nombre := AConsulta.FieldByName('NOMBRE_ALM_ALM').AsString;
      Almacen.Orden := AConsulta.FieldByName('ORDEN_ALM').AsInteger;
      Almacen.Prioridad :=
        AConsulta.FieldByName('ORDEN_DISTRIBUCION_ALM').AsInteger;
      Almacen.AdmiteDestino := SameText(
        AConsulta.FieldByName('ADMITE_DESTINO').AsString, 'S');
      Lista.Add(Almacen);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerStocks(
  AIdDocumento: Int64;
  const ASkus: TArray<string>): TStocksDistribucion;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    Result := LeerStocksConsulta(oConsulta, AIdDocumento, ASkus);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerStocksConsulta(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  const ASkus: TArray<string>): TStocksDistribucion;
var
  Lista: TList<TStockDistribucion>;
  Stock: TStockDistribucion;
  i: Integer;
begin
  Lista := TList<TStockDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlStocksDistribucion(Length(ASkus));
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    for i := 0 to High(ASkus) do
      AConsulta.ParamByName(NombreParametroSku(i)).AsString :=
        Trim(ASkus[i]);
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Stock.CodigoAlmacen :=
        AConsulta.FieldByName('CODIGO_ALM_STK').AsString;
      Stock.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD_STK').AsString;
      Stock.Cantidad := AConsulta.FieldByName('CANTIDAD').AsFloat;
      Lista.Add(Stock);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerAsignaciones(
  AConsulta: TUniQuery;
  AIdDocumento: Int64): TAsignacionesDistribucion;
var
  Lista: TList<TAsignacionDistribucion>;
  Asignacion: TAsignacionDistribucion;
begin
  Lista := TList<TAsignacionDistribucion>.Create;
  try
    AConsulta.Close;
    AConsulta.SQL.Text := SqlAsignacionesDistribucion;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Asignacion.AlmacenOrigen := AConsulta.FieldByName('ORIGEN').AsString;
      Asignacion.AlmacenDestino :=
        AConsulta.FieldByName('DESTINO').AsString;
      Asignacion.CodigoSku :=
        AConsulta.FieldByName('CODIGO_UNIDAD').AsString;
      Asignacion.CantidadConfirmada :=
        AConsulta.FieldByName('CONFIRMADA').AsFloat;
      Asignacion.CantidadPendiente :=
        AConsulta.FieldByName('PENDIENTE').AsFloat;
      Lista.Add(Asignacion);
      AConsulta.Next;
    end;
    AConsulta.Close;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.CargarDocumento(
  AIdDocumento: Int64): TDocumentoDistribucion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TDocumentoDistribucion);
  oConsulta := NuevaConsulta;
  try
    Result.IdDocumento := AIdDocumento;
    Result.Titulo := LeerTitulo(oConsulta, AIdDocumento);
    Result.Unidades := LeerUnidades(oConsulta, AIdDocumento);
    Result.Almacenes := LeerAlmacenes(oConsulta, AIdDocumento);
    Result.Stocks := LeerStocksConsulta(oConsulta, AIdDocumento, nil);
    // La firma va antes que las asignaciones: si alguien resuelve una
    // propuesta entre las dos lecturas, el guardado posterior se rechaza.
    Result.FirmaResueltas := LeerFirmaResueltas(oConsulta, AIdDocumento);
    Result.Asignaciones := LeerAsignaciones(oConsulta, AIdDocumento);
  finally
    FreeAndNil(oConsulta);
  end;
end;

// ===========================================================================
//   Propuestas: lectura
// ===========================================================================

procedure TRepositorioDistribucionTiendasUniDAC.LeerLineasPropuestas(
  AConsulta: TUniQuery;
  const AFiltro, AParametro: string;
  const AValor: Variant;
  var APropuestas: TPropuestasTraspaso);
var
  Indices: TDictionary<Int64, Integer>;
  Linea: TLineaPropuestaTraspaso;
  i, iPropuesta, iNueva: Integer;
begin
  Indices := TDictionary<Int64, Integer>.Create;
  try
    for i := 0 to High(APropuestas) do
      Indices.AddOrSetValue(APropuestas[i].IdPropuesta, i);
    AConsulta.Close;
    AConsulta.SQL.Text := SqlLineasPropuestasTraspaso(AFiltro);
    AConsulta.ParamByName(AParametro).Value := AValor;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      if Indices.TryGetValue(
           AConsulta.FieldByName('ID_TRPRO_TRPROLIN').AsLargeInt,
           iPropuesta) then
      begin
        Linea.CodigoArticulo :=
          AConsulta.FieldByName('CODIGO_ART_TRPROLIN').AsString;
        Linea.DescripcionArticulo := AConsulta.FieldByName(
          'DESCRIPCION_ARTICULO_TRPROLIN').AsString;
        Linea.CodigoSku :=
          AConsulta.FieldByName('CODIGO_UNIDAD_TRPROLIN').AsString;
        Linea.Color := AConsulta.FieldByName('COLOR').AsString;
        Linea.Talla := AConsulta.FieldByName('TALLA').AsString;
        Linea.OrdenTalla :=
          AConsulta.FieldByName('ORDEN_TALLA').AsInteger;
        Linea.Cantidad :=
          AConsulta.FieldByName('CANTIDAD_TRPROLIN').AsFloat;
        Linea.CantidadTraspasada := AConsulta.FieldByName(
          'CANTIDAD_TRASPASADA_TRPROLIN').AsFloat;
        iNueva := Length(APropuestas[iPropuesta].Lineas);
        SetLength(APropuestas[iPropuesta].Lineas, iNueva + 1);
        APropuestas[iPropuesta].Lineas[iNueva] := Linea;
      end;
      AConsulta.Next;
    end;
    AConsulta.Close;
  finally
    FreeAndNil(Indices);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.LeerPropuestas(
  const AFiltro, AParametro: string;
  const AValor: Variant): TPropuestasTraspaso;
var
  oConsulta: TUniQuery;
  Lista: TList<TPropuestaTraspaso>;
  Propuesta: TPropuestaTraspaso;
begin
  oConsulta := NuevaConsulta;
  Lista := TList<TPropuestaTraspaso>.Create;
  try
    oConsulta.SQL.Text := SqlCabecerasPropuestasTraspaso(AFiltro);
    oConsulta.ParamByName(AParametro).Value := AValor;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Propuesta := Default(TPropuestaTraspaso);
      Propuesta.IdPropuesta :=
        oConsulta.FieldByName('ID_TRPRO').AsLargeInt;
      Propuesta.IdDocumento :=
        oConsulta.FieldByName('ID_DTR_TRPRO').AsLargeInt;
      Propuesta.TituloDocumento :=
        oConsulta.FieldByName('TITULO_DTR').AsString;
      Propuesta.Instante :=
        oConsulta.FieldByName('INSTANTE_PROPUESTA_TRPRO').AsDateTime;
      Propuesta.Estado := oConsulta.FieldByName('ESTADO_TRPRO').AsString;
      Propuesta.AlmacenOrigen :=
        oConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRPRO').AsString;
      Propuesta.NombreAlmacenOrigen :=
        oConsulta.FieldByName('NOMBRE_ORIGEN').AsString;
      Propuesta.AlmacenDestino :=
        oConsulta.FieldByName('CODIGO_ALM_DESTINO_TRPRO').AsString;
      Propuesta.NombreAlmacenDestino :=
        oConsulta.FieldByName('NOMBRE_DESTINO').AsString;
      Propuesta.TipoDocumento :=
        oConsulta.FieldByName('TIPO_DOC_TRPRO').AsString;
      Propuesta.SerieDocumento :=
        oConsulta.FieldByName('SERIE_DOC_TRPRO').AsString;
      Propuesta.NumeroDocumento :=
        oConsulta.FieldByName('NUMERO_DOC_TRPRO').AsString;
      Propuesta.NumeroOperacion :=
        oConsulta.FieldByName('NUMERO_OPERACION_TRPRO').AsString;
      Propuesta.MotivoRechazo :=
        oConsulta.FieldByName('MOTIVO_RECHAZO_TRPRO').AsString;
      Lista.Add(Propuesta);
      oConsulta.Next;
    end;
    Result := Lista.ToArray;
    LeerLineasPropuestas(oConsulta, AFiltro, AParametro, AValor, Result);
  finally
    FreeAndNil(Lista);
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.ListarPropuestasDocumento(
  AIdDocumento: Int64): TPropuestasTraspaso;
begin
  Result := LeerPropuestas(
    FILTRO_PROPUESTAS_DOCUMENTO, 'ID_DTR', AIdDocumento);
end;

function TRepositorioDistribucionTiendasUniDAC.
  ListarPropuestasPendientesOrigen(
  const AAlmacenOrigen: string): TPropuestasTraspaso;
begin
  Result := LeerPropuestas(
    FILTRO_PROPUESTAS_PENDIENTES_ORIGEN, 'ORIGEN', AAlmacenOrigen);
end;

function TRepositorioDistribucionTiendasUniDAC.LeerPropuesta(
  AIdPropuesta: Int64): TPropuestaTraspaso;
var
  Propuestas: TPropuestasTraspaso;
begin
  Propuestas := LeerPropuestas(
    FILTRO_PROPUESTA_POR_ID, 'ID_TRPRO', AIdPropuesta);
  if Length(Propuestas) = 0 then
    raise EArgumentException.CreateFmt(
      SErrorPropuestaTraspasoNoExiste, [AIdPropuesta]);
  Result := Propuestas[0];
end;

// ===========================================================================
//   Propuestas: escritura
// ===========================================================================

function TRepositorioDistribucionTiendasUniDAC.LeerFirmaResueltas(
  AConsulta: TUniQuery; AIdDocumento: Int64): string;
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlFirmaPropuestasResueltas;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  Result := AConsulta.FieldByName('FIRMA').AsString;
  AConsulta.Close;
end;

procedure TRepositorioDistribucionTiendasUniDAC.CargarPropuestasPendientes(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  APendientes: TDictionary<string, Int64>);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlBloquearPropuestasPendientes;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    // Si hubiera más de una pendiente para la pareja, vale la primera.
    if not APendientes.ContainsKey(ClavePareja(
         AConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRPRO').AsString,
         AConsulta.FieldByName('CODIGO_ALM_DESTINO_TRPRO').AsString)) then
      APendientes.Add(
        ClavePareja(
          AConsulta.FieldByName('CODIGO_ALM_ORIGEN_TRPRO').AsString,
          AConsulta.FieldByName('CODIGO_ALM_DESTINO_TRPRO').AsString),
        AConsulta.FieldByName('ID_TRPRO').AsLargeInt);
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

function TRepositorioDistribucionTiendasUniDAC.AsegurarPropuestaPendiente(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  const AAsignacion: TAsignacionDistribucion;
  const AUsuario: string;
  APendientes: TDictionary<string, Int64>): Int64;
var
  sClave: string;
begin
  sClave := ClavePareja(
    AAsignacion.AlmacenOrigen, AAsignacion.AlmacenDestino);
  if not APendientes.TryGetValue(sClave, Result) then
  begin
    AConsulta.Close;
    AConsulta.SQL.Text := SqlInsertarPropuestaTraspaso;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.ParamByName('ORIGEN').AsString :=
      Trim(AAsignacion.AlmacenOrigen);
    AConsulta.ParamByName('DESTINO').AsString :=
      Trim(AAsignacion.AlmacenDestino);
    AConsulta.ParamByName('USUARIO').AsString := AUsuario;
    AConsulta.Execute;
    AConsulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID_TRPRO';
    AConsulta.Open;
    Result := AConsulta.FieldByName('ID_TRPRO').AsLargeInt;
    AConsulta.Close;
    APendientes.Add(sClave, Result);
  end;
end;

procedure TRepositorioDistribucionTiendasUniDAC.InsertarLinea(
  AConsulta: TUniQuery;
  AIdDocumento, AIdPropuesta: Int64;
  const AAsignacion: TAsignacionDistribucion;
  const AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlInsertarLineaPropuestaTraspaso;
  AConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.ParamByName('CODIGO_UNIDAD').AsString :=
    Trim(AAsignacion.CodigoSku);
  AConsulta.ParamByName('CANTIDAD').AsFloat :=
    AAsignacion.CantidadPendiente;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> 1 then
    raise EInvalidOpException.CreateFmt(
      SErrorSkuDistribucionFueraDocumento, [AAsignacion.CodigoSku]);
end;

// Las líneas de las propuestas pendientes se rehacen enteras: son pocas y
// así lo guardado es exactamente lo que se ve en el cuadrante.
procedure TRepositorioDistribucionTiendasUniDAC.SincronizarPropuestas(
  AConsulta: TUniQuery;
  AIdDocumento: Int64;
  const AFirmaResueltas: string;
  const AAsignaciones: TAsignacionesDistribucion;
  const AUsuario: string);
var
  Pendientes: TDictionary<string, Int64>;
  i: Integer;
begin
  Pendientes := TDictionary<string, Int64>.Create;
  try
    // Con las pendientes ya bloqueadas, nadie puede resolver otra hasta
    // que esta transacción termine.
    CargarPropuestasPendientes(AConsulta, AIdDocumento, Pendientes);
    if LeerFirmaResueltas(AConsulta, AIdDocumento) <> AFirmaResueltas then
      raise EDistribucionTiendasDesactualizada.Create(
        SErrorDistribucionTiendasDesactualizada);
    AConsulta.Close;
    AConsulta.SQL.Text := SqlBorrarLineasPropuestasPendientes;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Execute;
    for i := 0 to High(AAsignaciones) do
    begin
      if AAsignaciones[i].CantidadPendiente > TOLERANCIA_CANTIDAD then
        InsertarLinea(
          AConsulta,
          AIdDocumento,
          AsegurarPropuestaPendiente(
            AConsulta, AIdDocumento, AAsignaciones[i], AUsuario,
            Pendientes),
          AAsignaciones[i],
          AUsuario);
    end;
    AConsulta.Close;
    AConsulta.SQL.Text := SqlBorrarPropuestasPendientesVacias;
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Execute;
  finally
    FreeAndNil(Pendientes);
  end;
end;

procedure TRepositorioDistribucionTiendasUniDAC.GuardarPropuestas(
  AIdDocumento: Int64;
  const AFirmaResueltas: string;
  const AAsignaciones: TAsignacionesDistribucion;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  oConsulta := NuevaConsulta;
  try
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
      FConexion.StartTransaction;
    try
      SincronizarPropuestas(
        oConsulta, AIdDocumento, AFirmaResueltas, AAsignaciones, AUsuario);
      if bTransaccionPropia then
        FConexion.Commit;
    except
      if bTransaccionPropia then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.RechazarPropuesta(
  AIdPropuesta: Int64;
  const AMotivo, AUsuario: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SqlRechazarPropuestaTraspaso;
    oConsulta.ParamByName('MOTIVO').AsString := Copy(Trim(AMotivo), 1, 255);
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioDistribucionTiendasUniDAC.GuardarPrioridadesAlmacenes(
  const APrioridades: TPrioridadesAlmacenDistribucion;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
  i: Integer;
begin
  oConsulta := NuevaConsulta;
  try
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
      FConexion.StartTransaction;
    try
      oConsulta.SQL.Text := SqlGuardarPrioridadAlmacen;
      for i := 0 to High(APrioridades) do
      begin
        oConsulta.ParamByName('PRIORIDAD').AsInteger :=
          APrioridades[i].Prioridad;
        oConsulta.ParamByName('USUARIO').AsString := AUsuario;
        oConsulta.ParamByName('ALMACEN').AsString :=
          Trim(APrioridades[i].CodigoAlmacen);
        oConsulta.Execute;
      end;
      if bTransaccionPropia then
        FConexion.Commit;
    except
      if bTransaccionPropia then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Sin documento solo cuadran las tiendas: los almacenes que admiten ser
// destino.
function TRepositorioDistribucionTiendasUniDAC.ListarAlmacenesDestino:
  TAlmacenesDistribucion;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    Result := LeerAlmacenes(oConsulta, 0);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDistribucionTiendasUniDAC.EliminarPropuestaPendiente(
  AIdPropuesta: Int64): Boolean;
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  oConsulta := NuevaConsulta;
  try
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
      FConexion.StartTransaction;
    try
      // La cabecera se borra primero y con el estado en el predicado: si
      // entre tanto se confirmó, no se toca nada.
      oConsulta.SQL.Text :=
        'DELETE FROM fza_traspasos_propuestas ' +
        ' WHERE ID_TRPRO = :ID_TRPRO ' +
        '   AND ESTADO_TRPRO = ''PENDIENTE''';
      oConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
      oConsulta.Execute;
      Result := oConsulta.RowsAffected = 1;
      if Result then
      begin
        oConsulta.SQL.Text :=
          'DELETE FROM fza_traspasos_propuestas_lineas ' +
          ' WHERE ID_TRPRO_TRPROLIN = :ID_TRPRO';
        oConsulta.ParamByName('ID_TRPRO').AsLargeInt := AIdPropuesta;
        oConsulta.Execute;
      end;
      if bTransaccionPropia then
        FConexion.Commit;
    except
      if bTransaccionPropia then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
