{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesRepositorio                             }
{    Tipo:       Repositorio                                                   }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Repositorio UniDAC y composición de los adaptadores de compras.           }
{******************************************************************************}
unit UniDataComprasSesionesRepositorio;

interface

uses
  System.Classes, Uni, inLibCatalogoSqlIntf, inLibComprasSesionesIntf,
  UniDataComprasSesiones;

type
  TRepositorioComprasSesiones = class(
    TInterfacedObject,
    IRepositorioLecturasComprasSesiones,
    IRepositorioComprasSesiones)
  private
    FConexion: TUniConnection;
    FDataModule: TdmComprasSesiones;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    procedure AsegurarDataModule;
    function EjecutarConsultarCodigosBasicosActivos(
      const ASql, AIdVariacion: string): TArray<string>;
    function EjecutarConsultarKitProveedor(
      const ASql, ACodigoProveedor,
      ACodigoKit: string;
      AIdAcLinea: Integer): TKitProveedorSesion;
    function EjecutarConsultarDetallesKitProveedor(
      const ASql, ACodigoProveedor,
      ACodigoKit: string): TDetallesKitProveedorSesion;
    function EjecutarObtenerNombreFamilia(
      const ASql, ACodigoFamilia: string;
      const ACampo: string = 'NOMBRE_FAM_FAM'): string;
    function EjecutarResolverDuplicadoPorCodigo(
      const ASql, ACodigoBuscado,
      ACodigoProveedor: string): TResolverDuplicadoSesion;
    function EjecutarResolverDuplicadoPorReferencia(
      const ASql, ACodigoBuscado, ACodigoProveedor,
      ACodigoArticuloPreferido: string):
      TResolverDuplicadoSesion;
    function EjecutarResolverDuplicadoIntraSesion(
      const ASql, ASerie, ANumero: string;
      ALineaActual: Integer;
      const AModelo, ACodigoArticulo: string):
      TResolverDuplicadoSesion;
    function EjecutarObtenerPvpArticulo(
      const ASql, ACodigoArticulo,
      ACodigoTarifa: string): Double;
    function EjecutarObtenerSiguienteLinea(
      const ASql, ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function EjecutarConsultarCantidadesLinea(
      const ASql, ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    procedure ValidarCabeceraSesion(AIncidencias: TStrings);
    procedure ValidarExistenciaLineas(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarDuplicadosInternos(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarDuplicadosExternos(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarPvpArticulos(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarReusoSinArticulo(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarLineasSinCodigo(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarLineasSinDescripcion(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
    procedure ValidarMatricesSesion(
      const ASerie, ANumero: string;
      AIncidencias: TStrings);
  public
    constructor Create(
      AConexion: TUniConnection;
      ADataModule: TdmComprasSesiones;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    procedure AplicarDuplicadoEnLinea(
      const AResultado: TResolverDuplicadoSesion);
    procedure BorrarCeldasLinea(
      const ASerie, ANumero: string;
      ALinea: Integer);
    function RenumerarLineas(
      const ASerie, ANumero: string): TCambiosLineaSesion;
    procedure CopiarCeldasDistribuidas(
      const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
      ALineaOrigen, ALineaDestino: Integer);
    function ObtenerSiguienteLinea(
      const ASerie, ANumero: string;
      ALineaActual: Integer): Integer;
    function ConsultarCantidadesLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TCantidadesPivotSesion;
    function ConsultarCodigosBasicosActivos(
      const AIdVariacion: string): TArray<string>;
    function ConsultarKitProveedor(
      const ACodigoProveedor, ACodigoKit: string;
      AIdAcLinea: Integer): TKitProveedorSesion;
    function ConsultarDetallesKitProveedor(
      const ACodigoProveedor, ACodigoKit: string):
      TDetallesKitProveedorSesion;
    function ObtenerNombreFamilia(
      const ACodigoFamilia: string): string;
    function ObtenerDescripcionFamilia(
      const ACodigoFamilia: string): string;
    function ResolverCodigoFamilia(
      const ACodigoTecleado, AUsuario: string;
      out ACodigoGenerado: string): Boolean;
    function ResolverDuplicado(
      const ACodigoBuscado, ACodigoProveedor: string;
      ASoloRefProveedor: Boolean;
      const ACodigoArticuloPreferido: string):
      TResolverDuplicadoSesion;
    function ResolverDuplicadoIntraSesion(
      const ASerie, ANumero: string;
      ALineaActual: Integer;
      const AModelo, ACodigoArticulo: string):
      TResolverDuplicadoSesion;
    function NormalizarDuplicadosIntraSesion(
      const AUsuario, ASerie, ANumero: string): Integer;
    function ValidarSesionDetallado:
      TIncidenciasSesionCompra;
  end;

implementation

uses
  System.StrUtils, System.SysUtils, Data.DB,
  inLibCatalogoSqlEjecucion,
  inLibMsgArticulos, inLibMsgCompras,
  UniDataComprasSesionesOperaciones,
  UniDataComprasSesionesRenumeracion,
  UniDataComprasSesionesPropiedades;

type
  TProcesadorConsultaSesion = reference to procedure(
    AConsulta: TUniQuery;
    AIncidencias: TStrings);

const
  SQL_SIGUIENTE_LINEA =
    'SELECT MIN(LINEA_SESLIN) AS SIGUIENTE ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND LINEA_SESLIN > :l';
  SQL_CANTIDADES_LINEA =
    'SELECT ID_AV_PIVOT_SESCEL, ' +
    '       SUM(CANTIDAD_SESCEL) AS TOTAL ' +
    '  FROM fza_compras_sesiones_celdas ' +
    ' WHERE SERIE_SES_SESCEL = :s ' +
    '   AND NUMERO_SES_SESCEL = :n ' +
    '   AND LINEA_SES_SESCEL = :l ' +
    ' GROUP BY ID_AV_PIVOT_SESCEL';
  SQL_CODIGOS_BASICOS_ACTIVOS =
    'SELECT CODIGO_ATB FROM fza_atributos_basicos ' +
    ' WHERE ID_VA_ATB = :va AND ESACTIVO_ATB = ''S'' ' +
    ' ORDER BY ORDEN_ATB, NOMBRE_ATB';
  SQL_NOMBRE_FAMILIA =
    'SELECT NOMBRE_FAM_FAM FROM fza_articulos_familias ' +
    ' WHERE CODIGO_FAM_FAM = :codigo AND ESACTIVO_FAM = ''S''';
  SQL_DESCRIPCION_FAMILIA =
    'SELECT DESCRIPCION_FAM FROM fza_articulos_familias ' +
    ' WHERE CODIGO_FAM_FAM = :codigo AND ESACTIVO_FAM = ''S''';
  SQL_KIT_PROVEEDOR =
    'SELECT K.ID_AC_TALLAS_PRVKIT, ' +
    '  (SELECT NOMBRE_AC FROM fza_atributos_conjuntos ' +
    '    WHERE ID_AC = K.ID_AC_TALLAS_PRVKIT) AS NOMBRE_TALLAS_KIT, ' +
    '  (SELECT NOMBRE_AC FROM fza_atributos_conjuntos ' +
    '    WHERE ID_AC = :ac) AS NOMBRE_TALLAS_LIN ' +
    '  FROM fza_proveedores_kits K ' +
    ' WHERE K.CODIGO_PRV_PRVKIT = :prv ' +
    '   AND K.CODIGO_PRVKIT = :kit';
  SQL_DETALLES_KIT_PROVEEDOR =
    'SELECT VALOR_DESTINO_PRVKITD, CANTIDAD_PRVKITD ' +
    '  FROM fza_proveedores_kits_det ' +
    ' WHERE CODIGO_PRV_PRVKITD = :prv ' +
    '   AND CODIGO_PRVKIT_PRVKITD = :kit ' +
    ' ORDER BY ORDEN_PRVKITD, VALOR_DESTINO_PRVKITD';
  SQL_VALIDAR_SESION_CON_LINEAS =
    'SELECT COUNT(*) AS N FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n';
  SQL_VALIDAR_DUPLICADOS_INTERNOS =
    'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       G.PRIMERA, G.N ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    '  JOIN (SELECT SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
    '               CODIGO_ART_TENTATIVO_SESLIN, ' +
    '               MIN(CASE WHEN IFNULL(ACCION_DUPLICADO_SESLIN, ' +
    '                   '''') <> ''REUSAR'' THEN LINEA_SESLIN END) ' +
    '                   AS PRIMERA, ' +
    '               COUNT(*) AS N ' +
    '          FROM fza_compras_sesiones_lineas ' +
    '         WHERE SERIE_SES_SESLIN = :s ' +
    '           AND NUMERO_SES_SESLIN = :n ' +
    '           AND CODIGO_ART_TENTATIVO_SESLIN IS NOT NULL ' +
    '           AND TRIM(CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
    '         GROUP BY SERIE_SES_SESLIN, NUMERO_SES_SESLIN, ' +
    '                  CODIGO_ART_TENTATIVO_SESLIN ' +
    '        HAVING COUNT(*) > 1) AS G ' +
    '    ON G.SERIE_SES_SESLIN = L.SERIE_SES_SESLIN ' +
    '   AND G.NUMERO_SES_SESLIN = L.NUMERO_SES_SESLIN ' +
    '   AND G.CODIGO_ART_TENTATIVO_SESLIN = ' +
    '       L.CODIGO_ART_TENTATIVO_SESLIN ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND L.LINEA_SESLIN <> G.PRIMERA ' +
    '   AND (L.ACCION_DUPLICADO_SESLIN IS NULL ' +
    '        OR TRIM(L.ACCION_DUPLICADO_SESLIN) = '''' ' +
    '        OR L.ACCION_DUPLICADO_SESLIN <> ''REUSAR'') ' +
    ' ORDER BY L.LINEA_SESLIN';
  SQL_VALIDAR_DUPLICADOS_EXTERNOS =
    'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.DESCRIPCION_SESLIN, A.ESACTIVO_ART ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    '  JOIN fza_articulos A ' +
    '         ON A.CODIGO_ART_ART = L.CODIGO_ART_TENTATIVO_SESLIN ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND IFNULL(L.ACCION_DUPLICADO_SESLIN, '''') <> ''REUSAR'' ' +
    ' ORDER BY L.LINEA_SESLIN';
  // FZ-ISSUE-415: un artículo puede llevar un PVP por talla o medida
  // (100 ml a 5,50 y 250 ml a 9,95). Solo es incompatible que el mismo
  // SKU (artículo, color y talla con cantidad) reciba dos PVP. Cuenta el
  // PVP tecleado para la talla, si lo hay (FZ-ISSUE-638).
  SQL_VALIDAR_PVP_ARTICULOS =
    'SELECT MIN(L.LINEA_SESLIN) AS LINEA_SESLIN, ' +
    ' CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    ' THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    ' ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
    ' MIN(COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN)) ' +
    ' AS PVP_MINIMO, ' +
    ' MAX(COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN)) ' +
    ' AS PVP_MAXIMO ' +
    ' FROM fza_compras_sesiones_lineas L ' +
    ' JOIN fza_compras_sesiones S ' +
    ' ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    ' AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    ' JOIN fza_compras_sesiones_celdas C ' +
    ' ON C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN ' +
    ' AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN ' +
    ' AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
    ' AND C.CANTIDAD_SESCEL > 0 ' +
    ' LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    ' ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    ' AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    ' AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
    ' AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
    ' AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
    ' AND IFNULL(S.ESPRECIO_POR_SKU_SES, ''N'') <> ''S'' ' +
    ' AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    ' AND COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN) > 0 ' +
    ' GROUP BY CODIGO_ART, ' +
    ' UPPER(TRIM(IFNULL(L.COLOR_TEXTO_SESLIN, ''''))), ' +
    ' UPPER(TRIM(IFNULL(L.PESTANA_TEXTO_SESLIN, ''''))), ' +
    ' C.ID_AV_PIVOT_SESCEL ' +
    ' HAVING MIN(COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN)) ' +
    ' <> MAX(COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN)) ' +
    ' ORDER BY LINEA_SESLIN';
  SQL_VALIDAR_REUSO_SIN_ARTICULO =
    'SELECT L.LINEA_SESLIN, L.CODIGO_ART_REUSAR_SESLIN ' +
    ' FROM fza_compras_sesiones_lineas L ' +
    ' WHERE L.SERIE_SES_SESLIN = :s AND L.NUMERO_SES_SESLIN = :n ' +
    ' AND L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_articulos A ' +
    ' WHERE A.CODIGO_ART_ART = L.CODIGO_ART_REUSAR_SESLIN) ' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_lineas O ' +
    ' WHERE O.SERIE_SES_SESLIN = L.SERIE_SES_SESLIN ' +
    ' AND O.NUMERO_SES_SESLIN = L.NUMERO_SES_SESLIN ' +
    ' AND O.CODIGO_ART_TENTATIVO_SESLIN = L.CODIGO_ART_REUSAR_SESLIN ' +
    ' AND IFNULL(O.ACCION_DUPLICADO_SESLIN, '''') <> ''REUSAR'') ' +
    ' ORDER BY L.LINEA_SESLIN';
  SQL_VALIDAR_LINEAS_SIN_CODIGO =
    'SELECT LINEA_SESLIN FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND (CODIGO_ART_TENTATIVO_SESLIN IS NULL ' +
    '        OR TRIM(CODIGO_ART_TENTATIVO_SESLIN) = '''') ' +
    ' ORDER BY LINEA_SESLIN';
  SQL_VALIDAR_LINEAS_SIN_DESCRIPCION =
    'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       S.ESDESCRIPCION_BLANCO_SES ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND IFNULL(S.ESDESCRIPCION_BLANCO_SES, ''N'') <> ''S'' ' +
    '   AND (L.DESCRIPCION_SESLIN IS NULL ' +
    '        OR TRIM(L.DESCRIPCION_SESLIN) = '''') ' +
    ' ORDER BY L.LINEA_SESLIN';
  SQL_VALIDAR_MATRICES_SIN_CANTIDADES =
    'SELECT L.LINEA_SESLIN, L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.DESCRIPCION_SESLIN ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    '   AND L.NUMERO_SES_SESLIN = :n ' +
    '   AND L.TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_celdas C ' +
    '                    WHERE C.SERIE_SES_SESCEL = ' +
    '                          L.SERIE_SES_SESLIN ' +
    '                      AND C.NUMERO_SES_SESCEL = ' +
    '                          L.NUMERO_SES_SESLIN ' +
    '                      AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
    '                      AND C.CANTIDAD_SESCEL > 0) ' +
    ' ORDER BY L.LINEA_SESLIN';
  // Un articulo reusado sin tallaje deja la linea sin sistema a proposito:
  // sus celdas llevan la talla de sus SKU y la materializacion los
  // resuelve por ella (FZ-ISSUE-138/140).
  SQL_VALIDAR_MATRICES_SIN_TALLAJE =
    'SELECT LINEA_SESLIN, CODIGO_ART_TENTATIVO_SESLIN ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
    '   AND (ID_AC_PIVOT_SESLIN IS NULL OR ID_AC_PIVOT_SESLIN = 0) ' +
    '   AND IFNULL(ACCION_DUPLICADO_SESLIN, '''') <> ''REUSAR'' ' +
    ' ORDER BY LINEA_SESLIN';
  SQL_DUPLICADO_POR_CODIGO =
    'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.CODIGO_FAM_ART, ' +
    '       a.TIPO_ART, a.TIPO_IVA_ART, a.TIPO_CANTIDAD_ART, ' +
    '       a.ESVARIACION_ART, a.ESTRAZABLE_ART, ' +
    '       a.TIPO_VARIACION_ART, ' +
    '       f.NOMBRE_FAM_FAM, ' +
    '       (SELECT aca.ID_AC_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'') ' +
    '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
    '       (SELECT aca.ID_VA_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'') ' +
    '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
    '       (SELECT aca.ID_AC_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''F'') LIMIT 1) AS ' +
    'ID_AC_FILA, ' +
    '       (SELECT aca.ID_VA_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''F'') LIMIT 1) AS ' +
    'ID_VA_FILA, ' +
    '       (SELECT ap.PRECIO_ULT_COMPRA_AP ' +
    '          FROM fza_articulos_proveedores ap ' +
    '         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
    '           AND (:prv = '''' OR ap.CODIGO_PRV_AP = :prv) ' +
    '         ORDER BY (ap.CODIGO_PRV_AP = :prv) DESC, ' +
    '                  ap.ESPROVEEDORPRINCIPAL_AP DESC LIMIT 1) ' +
    '         AS PRECIO_ULT_COMPRA, ' +
    '       (SELECT ap.REF_PROVEEDOR_AP ' +
    '          FROM fza_articulos_proveedores ap ' +
    '         WHERE ap.CODIGO_ART_AP = a.CODIGO_ART_ART ' +
    '           AND (:prv = '''' OR ap.CODIGO_PRV_AP = :prv) ' +
    '         ORDER BY (ap.CODIGO_PRV_AP = :prv) DESC, ' +
    '                  ap.ESPROVEEDORPRINCIPAL_AP DESC LIMIT 1) ' +
    '         AS REF_PROVEEDOR ' +
    '  FROM fza_articulos a ' +
    '  LEFT JOIN fza_articulos_familias f ' +
    '         ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
    ' WHERE a.CODIGO_ART_ART = :art ' +
    '   AND a.ESACTIVO_ART = ''S''';
  SQL_DUPLICADO_POR_REFERENCIA =
    'SELECT a.CODIGO_ART_ART, a.DESCRIPCION_ART, a.CODIGO_FAM_ART, ' +
    '       a.TIPO_ART, a.TIPO_IVA_ART, a.TIPO_CANTIDAD_ART, ' +
    '       a.ESVARIACION_ART, a.ESTRAZABLE_ART, ' +
    '       a.TIPO_VARIACION_ART, ' +
    '       f.NOMBRE_FAM_FAM, ' +
    '       ap.PRECIO_ULT_COMPRA_AP AS PRECIO_ULT_COMPRA, ' +
    '       ap.REF_PROVEEDOR_AP AS REF_PROVEEDOR, ' +
    '       (SELECT aca.ID_AC_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'') ' +
    '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
    '       (SELECT aca.ID_VA_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'') ' +
    '         ORDER BY aca.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
    '       (SELECT aca.ID_AC_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''F'') LIMIT 1) AS ' +
    'ID_AC_FILA, ' +
    '       (SELECT aca.ID_VA_ACA ' +
    '          FROM fza_articulos_conjuntos_asign aca ' +
    '         WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART ' +
    '           AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''F'') LIMIT 1) AS ' +
    'ID_VA_FILA ' +
    '  FROM fza_articulos_proveedores ap ' +
    '  JOIN fza_articulos a ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
    '                       AND a.ESACTIVO_ART = ''S'' ' +
    '  LEFT JOIN fza_articulos_familias f ' +
    '         ON f.CODIGO_FAM_FAM = a.CODIGO_FAM_ART ' +
    ' WHERE ap.CODIGO_PRV_AP = :prv ' +
    '   AND ap.REF_PROVEEDOR_AP = :ref ' +
    '   AND (:artpref = '''' OR ap.CODIGO_ART_AP = :artpref) ' +
    ' ORDER BY (ap.CODIGO_ART_AP = :artpref) DESC, ' +
    '          ap.ESPROVEEDORPRINCIPAL_AP DESC, a.CODIGO_ART_ART ' +
    ' LIMIT 1';
  SQL_DUPLICADO_INTRA_SESION =
    'SELECT L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.DESCRIPCION_SESLIN, L.CODIGO_FAM_SESLIN, ' +
    '       L.TIPO_LINEA_SESLIN, L.TIPO_ART_SESLIN, ' +
    '       L.TIPO_IVA_SESLIN, L.TIPO_CANTIDAD_SESLIN, ' +
    '       L.ESTRAZABLE_SESLIN, L.CODIGO_VAR_SESLIN, ' +
    '       L.ID_VA_PIVOT_SESLIN, L.ID_AC_PIVOT_SESLIN, ' +
    '       L.ID_VA_FILA_SESLIN, L.ID_AC_FILA_SESLIN, ' +
    '       L.PRECIO_COMPRA_SESLIN, L.PRECIO_VENTA_SESLIN, ' +
    '       L.REF_PRV_SESLIN, L.LINEA_SESLIN, ' +
    '       L.COLOR_TEXTO_SESLIN, L.CODIGO_ATB_COLOR_SESLIN, ' +
    '       L.PORCENTAJE_MARGEN_SESLIN ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    ' WHERE L.SERIE_SES_SESLIN = :serie ' +
    '   AND L.NUMERO_SES_SESLIN = :numero ' +
    '   AND L.LINEA_SESLIN <> :linea ' +
    '   AND TRIM(L.CODIGO_ART_TENTATIVO_SESLIN) <> '''' ' +
    '   AND ((:modelo <> '''' ' +
    '         AND TRIM(COALESCE(L.REF_PRV_SESLIN, '''')) = :modelo) ' +
    '        OR (:codigo <> '''' ' +
    '            AND (TRIM(L.CODIGO_ART_TENTATIVO_SESLIN) = :codigo ' +
    '                 OR TRIM(COALESCE(L.CODIGO_ART_REUSAR_SESLIN, '''')) ' +
    '                    = :codigo))) ' +
    ' ORDER BY CASE WHEN (:modelo <> '''' ' +
    '                 AND TRIM(COALESCE(L.REF_PRV_SESLIN, '''')) = :modelo) ' +
    '               THEN 0 ELSE 1 END, ' +
    '          L.LINEA_SESLIN ' +
    ' LIMIT 1';
  SQL_PVP_ARTICULO =
    'SELECT t.PRECIO_FINAL_ARTTAR ' +
    '  FROM fza_articulos_tarifas t ' +
    ' WHERE t.CODIGO_ART_ARTTAR = :art ' +
    '   AND t.CODIGO_UNIDAD_ARTTAR = '''' ' +
    '   AND (t.ESACTIVO_ARTTAR = ''S'' ' +
    '        OR t.CODIGO_TAR_ARTTAR = :tar) ' +
    ' ORDER BY (t.CODIGO_TAR_ARTTAR = :tar) DESC, ' +
    '          t.ESACTIVO_ARTTAR DESC, ' +
    '          t.FECHA_DESDE_ARTTAR DESC, ' +
    '          t.CODIGO_UNICO_ARTTAR DESC ' +
    ' LIMIT 1';

function DefinicionSiguienteLinea: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ObtenerSiguienteLinea',
    SQL_SIGUIENTE_LINEA,
    's,n,l',
    'SIGUIENTE',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionCantidadesLinea: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ConsultarCantidadesLinea',
    SQL_CANTIDADES_LINEA,
    's,n,l',
    'ID_AV_PIVOT_SESCEL,TOTAL',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionCodigosBasicosActivos: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ConsultarCodigosBasicosActivos',
    SQL_CODIGOS_BASICOS_ACTIVOS,
    'va',
    'CODIGO_ATB',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionNombreFamilia: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ObtenerNombreFamilia',
    SQL_NOMBRE_FAMILIA,
    'codigo',
    'NOMBRE_FAM_FAM',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionDescripcionFamilia: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ObtenerDescripcionFamilia',
    SQL_DESCRIPCION_FAMILIA,
    'codigo',
    'DESCRIPCION_FAM',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionKitProveedor: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ConsultarKitProveedor',
    SQL_KIT_PROVEEDOR,
    'ac,prv,kit',
    'ID_AC_TALLAS_PRVKIT,NOMBRE_TALLAS_KIT,NOMBRE_TALLAS_LIN',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionDetallesKitProveedor: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ConsultarDetallesKitProveedor',
    SQL_DETALLES_KIT_PROVEEDOR,
    'prv,kit',
    'VALOR_DESTINO_PRVKITD,CANTIDAD_PRVKITD',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarSesionConLineas: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarSesionConLineas',
    SQL_VALIDAR_SESION_CON_LINEAS,
    's,n',
    'N',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarDuplicadosInternos: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarDuplicadosInternos',
    SQL_VALIDAR_DUPLICADOS_INTERNOS,
    's,n',
    'LINEA_SESLIN,CODIGO_ART_TENTATIVO_SESLIN,PRIMERA,N',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarDuplicadosExternos: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarDuplicadosExternos',
    SQL_VALIDAR_DUPLICADOS_EXTERNOS,
    's,n',
    'LINEA_SESLIN,CODIGO_ART_TENTATIVO_SESLIN,' +
    'DESCRIPCION_SESLIN,ESACTIVO_ART',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarPvpArticulos: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarPvpArticulos',
    SQL_VALIDAR_PVP_ARTICULOS,
    's,n',
    'LINEA_SESLIN,CODIGO_ART,PVP_MINIMO,PVP_MAXIMO',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarReusoSinArticulo: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones', 'ValidarReusoSinArticulo',
    SQL_VALIDAR_REUSO_SIN_ARTICULO, 's,n',
    'LINEA_SESLIN,CODIGO_ART_REUSAR_SESLIN',
    tssSelect, pesPerfilLecturaConFallback);
end;

function DefinicionValidarLineasSinCodigo: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarLineasSinCodigo',
    SQL_VALIDAR_LINEAS_SIN_CODIGO,
    's,n',
    'LINEA_SESLIN',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarLineasSinDescripcion: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarLineasSinDescripcion',
    SQL_VALIDAR_LINEAS_SIN_DESCRIPCION,
    's,n',
    'LINEA_SESLIN,CODIGO_ART_TENTATIVO_SESLIN,' +
    'ESDESCRIPCION_BLANCO_SES',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarMatricesSinCantidades: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarMatricesSinCantidades',
    SQL_VALIDAR_MATRICES_SIN_CANTIDADES,
    's,n',
    'LINEA_SESLIN,CODIGO_ART_TENTATIVO_SESLIN,' +
    'DESCRIPCION_SESLIN',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionValidarMatricesSinTallaje: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ValidarMatricesSinTallaje',
    SQL_VALIDAR_MATRICES_SIN_TALLAJE,
    's,n',
    'LINEA_SESLIN,CODIGO_ART_TENTATIVO_SESLIN',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionDuplicadoPorCodigo: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ResolverDuplicadoPorCodigo',
    SQL_DUPLICADO_POR_CODIGO,
    'art,prv',
    'CODIGO_ART_ART,DESCRIPCION_ART,CODIGO_FAM_ART,' +
    'TIPO_ART,TIPO_IVA_ART,TIPO_CANTIDAD_ART,' +
    'ESVARIACION_ART,ESTRAZABLE_ART,TIPO_VARIACION_ART,' +
    'NOMBRE_FAM_FAM,ID_AC_PIVOT,ID_VA_PIVOT,' +
    'ID_AC_FILA,ID_VA_FILA,PRECIO_ULT_COMPRA,REF_PROVEEDOR',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionDuplicadoPorReferencia: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ResolverDuplicadoPorReferencia',
    SQL_DUPLICADO_POR_REFERENCIA,
    'prv,ref,artpref',
    'CODIGO_ART_ART,DESCRIPCION_ART,CODIGO_FAM_ART,' +
    'TIPO_ART,TIPO_IVA_ART,TIPO_CANTIDAD_ART,' +
    'ESVARIACION_ART,ESTRAZABLE_ART,TIPO_VARIACION_ART,' +
    'NOMBRE_FAM_FAM,ID_AC_PIVOT,ID_VA_PIVOT,' +
    'ID_AC_FILA,ID_VA_FILA,PRECIO_ULT_COMPRA,REF_PROVEEDOR',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionDuplicadoIntraSesion: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ResolverDuplicadoIntraSesion',
    SQL_DUPLICADO_INTRA_SESION,
    'serie,numero,linea,modelo,codigo',
    'CODIGO_ART_TENTATIVO_SESLIN,DESCRIPCION_SESLIN,' +
    'CODIGO_FAM_SESLIN,TIPO_LINEA_SESLIN,TIPO_ART_SESLIN,' +
    'TIPO_IVA_SESLIN,TIPO_CANTIDAD_SESLIN,ESTRAZABLE_SESLIN,' +
    'CODIGO_VAR_SESLIN,ID_VA_PIVOT_SESLIN,ID_AC_PIVOT_SESLIN,' +
    'ID_VA_FILA_SESLIN,ID_AC_FILA_SESLIN,PRECIO_COMPRA_SESLIN,' +
    'PRECIO_VENTA_SESLIN,REF_PRV_SESLIN,LINEA_SESLIN,' +
    'COLOR_TEXTO_SESLIN,CODIGO_ATB_COLOR_SESLIN,' +
    'PORCENTAJE_MARGEN_SESLIN',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionPvpArticulo: TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    'RepositorioComprasSesiones',
    'ObtenerPvpArticulo',
    SQL_PVP_ARTICULO,
    'art,tar',
    'PRECIO_FINAL_ARTTAR',
    tssSelect,
    pesPerfilLecturaConFallback);
end;

procedure AnadirIncidenciaSesion(
  AIncidencias: TStrings;
  ALinea: Integer;
  const ATipo, AMensaje: string);
var
  sLinea: string;
begin
  if ALinea > 0 then
    sLinea := Format(
      STextoLineaIncidenciaSesion,
      [ALinea])
  else
    sLinea := STextoCabeceraIncidenciaSesion;
  AIncidencias.Add(Format(
    SFormatoIncidenciaSesion,
    [ATipo, sLinea, AMensaje]));
end;

procedure EjecutarConsultaValidacionSesion(
  AConexion: TUniConnection;
  const ADefinicion: TDefinicionSql;
  const ACatalogo: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql;
  const ASerie, ANumero: string;
  AIncidencias: TStrings;
  const AProcesar: TProcesadorConsultaSesion);
var
  oResultado: TStringList;
begin
  oResultado := TStringList.Create;
  try
    EjecutarLecturaSqlConFallback(
      ADefinicion,
      ACatalogo,
      procedure(const ASql: string)
      var
        oConsulta: TUniQuery;
        oIntento: TStringList;
      begin
        oConsulta := TUniQuery.Create(nil);
        oIntento := TStringList.Create;
        try
          oConsulta.Connection := AConexion;
          oConsulta.SQL.Text := ASql;
          oConsulta.ParamByName('s').AsString := ASerie;
          oConsulta.ParamByName('n').AsString := ANumero;
          oConsulta.Open;
          AProcesar(oConsulta, oIntento);
          oResultado.Assign(oIntento);
        finally
          FreeAndNil(oIntento);
          FreeAndNil(oConsulta);
        end;
      end,
      AIncidenciasSql);
    AIncidencias.AddStrings(oResultado);
  finally
    FreeAndNil(oResultado);
  end;
end;

function CargarDuplicadoArticulo(
  AConsulta: TUniQuery;
  const AOrigen: string): TResolverDuplicadoSesion;
begin
  Result := Default(TResolverDuplicadoSesion);
  if not AConsulta.IsEmpty then
  begin
    Result.Encontrado := True;
    Result.Origen := AOrigen;
    Result.CodigoArt :=
      AConsulta.FieldByName('CODIGO_ART_ART').AsString;
    Result.DescripcionArt :=
      AConsulta.FieldByName('DESCRIPCION_ART').AsString;
    Result.CodigoFam :=
      AConsulta.FieldByName('CODIGO_FAM_ART').AsString;
    Result.NombreFam :=
      AConsulta.FieldByName('NOMBRE_FAM_FAM').AsString;
    Result.IdAcPivot :=
      AConsulta.FieldByName('ID_AC_PIVOT').AsInteger;
    Result.IdVaPivot :=
      AConsulta.FieldByName('ID_VA_PIVOT').AsString;
    Result.IdAcFila :=
      AConsulta.FieldByName('ID_AC_FILA').AsInteger;
    Result.IdVaFila :=
      AConsulta.FieldByName('ID_VA_FILA').AsString;
    Result.TipoVariacion :=
      AConsulta.FieldByName('TIPO_VARIACION_ART').AsString;
    Result.EsVariacion :=
      AConsulta.FieldByName('ESVARIACION_ART').AsString = 'S';
    Result.EsTrazable :=
      AConsulta.FieldByName('ESTRAZABLE_ART').AsString = 'S';
    Result.TipoArt :=
      AConsulta.FieldByName('TIPO_ART').AsString;
    Result.TipoIva :=
      AConsulta.FieldByName('TIPO_IVA_ART').AsString;
    Result.TipoCantidad :=
      AConsulta.FieldByName('TIPO_CANTIDAD_ART').AsString;
    Result.UltimoCoste :=
      AConsulta.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
    Result.RefProveedor :=
      AConsulta.FieldByName('REF_PROVEEDOR').AsString;
  end;
end;

function CargarDuplicadoIntraSesion(
  AConsulta: TUniQuery): TResolverDuplicadoSesion;
begin
  Result := Default(TResolverDuplicadoSesion);
  if not AConsulta.IsEmpty then
  begin
    Result.Encontrado := True;
    Result.Origen := 'SES';
    Result.CodigoArt :=
      AConsulta.FieldByName(
        'CODIGO_ART_TENTATIVO_SESLIN').AsString;
    Result.DescripcionArt :=
      AConsulta.FieldByName('DESCRIPCION_SESLIN').AsString;
    Result.CodigoFam :=
      AConsulta.FieldByName('CODIGO_FAM_SESLIN').AsString;
    Result.IdAcPivot :=
      AConsulta.FieldByName('ID_AC_PIVOT_SESLIN').AsInteger;
    Result.IdVaPivot :=
      AConsulta.FieldByName('ID_VA_PIVOT_SESLIN').AsString;
    Result.IdAcFila :=
      AConsulta.FieldByName('ID_AC_FILA_SESLIN').AsInteger;
    Result.IdVaFila :=
      AConsulta.FieldByName('ID_VA_FILA_SESLIN').AsString;
    Result.TipoVariacion :=
      AConsulta.FieldByName('CODIGO_VAR_SESLIN').AsString;
    Result.TipoArt :=
      AConsulta.FieldByName('TIPO_ART_SESLIN').AsString;
    Result.TipoIva :=
      AConsulta.FieldByName('TIPO_IVA_SESLIN').AsString;
    Result.TipoCantidad :=
      AConsulta.FieldByName('TIPO_CANTIDAD_SESLIN').AsString;
    Result.EsTrazable :=
      AConsulta.FieldByName('ESTRAZABLE_SESLIN').AsString = 'S';
    Result.EsVariacion := SameText(
      AConsulta.FieldByName('TIPO_LINEA_SESLIN').AsString,
      'MATRIZ');
    Result.UltimoCoste :=
      AConsulta.FieldByName('PRECIO_COMPRA_SESLIN').AsFloat;
    Result.PrecioVenta :=
      AConsulta.FieldByName('PRECIO_VENTA_SESLIN').AsFloat;
    Result.RefProveedor :=
      AConsulta.FieldByName('REF_PRV_SESLIN').AsString;
    Result.LineaOrigen :=
      AConsulta.FieldByName('LINEA_SESLIN').AsInteger;
    Result.ColorTexto :=
      AConsulta.FieldByName('COLOR_TEXTO_SESLIN').AsString;
    Result.CodigoAtbColor :=
      AConsulta.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
    Result.MargenPorcentaje :=
      AConsulta.FieldByName('PORCENTAJE_MARGEN_SESLIN').AsFloat;
  end;
end;

constructor TRepositorioComprasSesiones.Create(
  AConexion: TUniConnection;
  ADataModule: TdmComprasSesiones;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FDataModule := ADataModule;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

procedure TRepositorioComprasSesiones.AsegurarDataModule;
begin
  if not Assigned(FDataModule) then
    raise EInvalidOperation.Create(
      'El repositorio requiere el contexto de la sesión de compra');
end;

class function TRepositorioComprasSesiones.DefinicionesSql:
  TDefinicionesSql;
begin
  SetLength(Result, 20);
  Result[0] := DefinicionSiguienteLinea;
  Result[1] := DefinicionCantidadesLinea;
  Result[2] := DefinicionCodigosBasicosActivos;
  Result[3] := DefinicionNombreFamilia;
  Result[4] := DefinicionKitProveedor;
  Result[5] := DefinicionDetallesKitProveedor;
  Result[6] := DefinicionValidarSesionConLineas;
  Result[7] := DefinicionValidarDuplicadosInternos;
  Result[8] := DefinicionValidarDuplicadosExternos;
  Result[9] := DefinicionValidarLineasSinCodigo;
  Result[10] := DefinicionValidarLineasSinDescripcion;
  Result[11] := DefinicionValidarMatricesSinCantidades;
  Result[12] := DefinicionValidarMatricesSinTallaje;
  Result[13] := DefinicionDuplicadoPorCodigo;
  Result[14] := DefinicionDuplicadoPorReferencia;
  Result[15] := DefinicionDuplicadoIntraSesion;
  Result[16] := DefinicionPvpArticulo;
  Result[17] := DefinicionValidarPvpArticulos;
  Result[18] := DefinicionValidarReusoSinArticulo;
  Result[19] := DefinicionDescripcionFamilia;
end;

procedure TRepositorioComprasSesiones.AplicarDuplicadoEnLinea(
  const AResultado: TResolverDuplicadoSesion);
var
  oDefinicion: TDefinicionSql;
  oResultado: TResolverDuplicadoSesion;
  rPvp: Double;
  sTarifa: string;
begin
  AsegurarDataModule;
  oResultado := AResultado;
  if oResultado.Encontrado and
     (oResultado.Origen <> 'SES') and
     (not oResultado.PrecioVentaResuelta) and
     Assigned(FDataModule.unqryTablaG) and
     (not FDataModule.unqryTablaG.IsEmpty) then
  begin
    sTarifa := Trim(
      FDataModule.unqryTablaG.FieldByName(
        'CODIGO_TAR_SES').AsString);
    rPvp := 0;
    oDefinicion := DefinicionPvpArticulo;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        rPvp := EjecutarObtenerPvpArticulo(
          ASql,
          oResultado.CodigoArt,
          sTarifa);
      end,
      FIncidenciasSql);
    oResultado.PrecioVenta := rPvp;
  end;
  UniDataComprasSesionesOperaciones.AplicarDuplicadoEnLinea(
    FDataModule,
    oResultado);
end;

function TRepositorioComprasSesiones.RenumerarLineas(
  const ASerie, ANumero: string): TCambiosLineaSesion;
begin
  Result := RenumerarLineasSesion(FConexion, ASerie, ANumero);
end;

procedure TRepositorioComprasSesiones.BorrarCeldasLinea(
  const ASerie, ANumero: string;
  ALinea: Integer);
begin
  UniDataComprasSesionesOperaciones.BorrarCeldasLineaSesion(
    FConexion,
    ASerie,
    ANumero,
    ALinea);
end;

procedure TRepositorioComprasSesiones.CopiarCeldasDistribuidas(
  const ASerie, ANumero, AAlmacenCabecera, AUsuario: string;
  ALineaOrigen, ALineaDestino: Integer);
begin
  UniDataComprasSesionesOperaciones.CopiarCeldasDistribuidasSesion(
    FConexion,
    ASerie,
    ANumero,
    AAlmacenCabecera,
    AUsuario,
    ALineaOrigen,
    ALineaDestino);
end;

function TRepositorioComprasSesiones.ConsultarCodigosBasicosActivos(
  const AIdVariacion: string): TArray<string>;
var
  oCodigos: TArray<string>;
  oDefinicion: TDefinicionSql;
begin
  oCodigos := nil;
  oDefinicion := DefinicionCodigosBasicosActivos;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oCodigos := EjecutarConsultarCodigosBasicosActivos(
        ASql,
        AIdVariacion);
    end,
    FIncidenciasSql);
  Result := oCodigos;
end;

function TRepositorioComprasSesiones.ConsultarKitProveedor(
  const ACodigoProveedor, ACodigoKit: string;
  AIdAcLinea: Integer): TKitProveedorSesion;
var
  oDefinicion: TDefinicionSql;
  oKit: TKitProveedorSesion;
begin
  oKit := Default(TKitProveedorSesion);
  oDefinicion := DefinicionKitProveedor;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oKit := EjecutarConsultarKitProveedor(
        ASql,
        ACodigoProveedor,
        ACodigoKit,
        AIdAcLinea);
    end,
    FIncidenciasSql);
  Result := oKit;
end;

function TRepositorioComprasSesiones.
  ConsultarDetallesKitProveedor(
  const ACodigoProveedor, ACodigoKit: string):
  TDetallesKitProveedorSesion;
var
  oDefinicion: TDefinicionSql;
  oDetalles: TDetallesKitProveedorSesion;
begin
  oDetalles := nil;
  oDefinicion := DefinicionDetallesKitProveedor;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oDetalles := EjecutarConsultarDetallesKitProveedor(
        ASql,
        ACodigoProveedor,
        ACodigoKit);
    end,
    FIncidenciasSql);
  Result := oDetalles;
end;

function TRepositorioComprasSesiones.ObtenerNombreFamilia(
  const ACodigoFamilia: string): string;
var
  oDefinicion: TDefinicionSql;
  sNombre: string;
begin
  sNombre := '';
  oDefinicion := DefinicionNombreFamilia;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      sNombre := EjecutarObtenerNombreFamilia(
        ASql,
        ACodigoFamilia);
    end,
    FIncidenciasSql);
  Result := sNombre;
end;

function TRepositorioComprasSesiones.ObtenerDescripcionFamilia(
  const ACodigoFamilia: string): string;
var
  oDefinicion: TDefinicionSql;
  sDescripcion: string;
begin
  sDescripcion := '';
  oDefinicion := DefinicionDescripcionFamilia;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      sDescripcion := EjecutarObtenerNombreFamilia(
        ASql, ACodigoFamilia, 'DESCRIPCION_FAM');
    end,
    FIncidenciasSql);
  Result := sDescripcion;
end;

function TRepositorioComprasSesiones.ResolverCodigoFamilia(
  const ACodigoTecleado, AUsuario: string;
  out ACodigoGenerado: string): Boolean;
begin
  Result :=
    UniDataComprasSesionesOperaciones.ResolverCodigoFamilia(
      FConexion,
      ACodigoTecleado,
      AUsuario,
      ACodigoGenerado);
end;

function TRepositorioComprasSesiones.ResolverDuplicado(
  const ACodigoBuscado, ACodigoProveedor: string;
  ASoloRefProveedor: Boolean;
  const ACodigoArticuloPreferido: string):
  TResolverDuplicadoSesion;
var
  oDefinicion: TDefinicionSql;
  oResultado: TResolverDuplicadoSesion;
  sCodigo: string;
  sCodigoArticuloPreferido: string;
  sProveedor: string;
begin
  oResultado := Default(TResolverDuplicadoSesion);
  sCodigo := Trim(ACodigoBuscado);
  sProveedor := Trim(ACodigoProveedor);
  sCodigoArticuloPreferido :=
    Trim(ACodigoArticuloPreferido);
  if (sCodigo <> '') and
     (not ASoloRefProveedor) then
  begin
    oDefinicion := DefinicionDuplicadoPorCodigo;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oResultado := EjecutarResolverDuplicadoPorCodigo(
          ASql,
          sCodigo,
          sProveedor);
      end,
      FIncidenciasSql);
  end;
  if (sCodigo <> '') and
     (not oResultado.Encontrado) and
     (sProveedor <> '') then
  begin
    oDefinicion := DefinicionDuplicadoPorReferencia;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oResultado := EjecutarResolverDuplicadoPorReferencia(
          ASql,
          sCodigo,
          sProveedor,
          sCodigoArticuloPreferido);
      end,
      FIncidenciasSql);
  end;
  Result := oResultado;
end;

function TRepositorioComprasSesiones.ResolverDuplicadoIntraSesion(
  const ASerie, ANumero: string;
  ALineaActual: Integer;
  const AModelo, ACodigoArticulo: string):
  TResolverDuplicadoSesion;
var
  oDefinicion: TDefinicionSql;
  oResultado: TResolverDuplicadoSesion;
  sCodigo: string;
  sModelo: string;
  sNumero: string;
  sSerie: string;
begin
  oResultado := Default(TResolverDuplicadoSesion);
  sSerie := Trim(ASerie);
  sNumero := Trim(ANumero);
  sModelo := Trim(AModelo);
  sCodigo := Trim(ACodigoArticulo);
  if (sSerie <> '') and
     (sNumero <> '') and
     ((sModelo <> '') or (sCodigo <> '')) then
  begin
    oDefinicion := DefinicionDuplicadoIntraSesion;
    EjecutarLecturaSqlConFallback(
      oDefinicion,
      FCatalogoSql,
      procedure(const ASql: string)
      begin
        oResultado := EjecutarResolverDuplicadoIntraSesion(
          ASql,
          sSerie,
          sNumero,
          ALineaActual,
          sModelo,
          sCodigo);
      end,
      FIncidenciasSql);
  end;
  Result := oResultado;
end;

function TRepositorioComprasSesiones.NormalizarDuplicadosIntraSesion(
  const AUsuario, ASerie, ANumero: string): Integer;
begin
  Result :=
    UniDataComprasSesionesOperaciones.NormalizarDuplicadosIntraSesion(
      FConexion,
      AUsuario,
      ASerie,
      ANumero);
end;

procedure TRepositorioComprasSesiones.ValidarCabeceraSesion(
  AIncidencias: TStrings);
begin
  if Trim(FDataModule.unqryTablaG.FieldByName(
    'CODIGO_EMP_SES').AsString) = '' then
  begin
    AnadirIncidenciaSesion(
      AIncidencias,
      0,
      STipoIncidenciaCabecera,
      SErrorEmpresaSesionFaltante);
  end;
  if Trim(FDataModule.unqryTablaG.FieldByName(
    'CODIGO_PRV_SES').AsString) = '' then
  begin
    AnadirIncidenciaSesion(
      AIncidencias,
      0,
      STipoIncidenciaCabecera,
      SErrorProveedorSesionFaltante);
  end;
  if (FDataModule.unqryTablaG.FieldByName(
      'ESGENERA_ALBARAN_SES').AsString = 'S') and
     (Trim(FDataModule.unqryTablaG.FieldByName(
      'CODIGO_ALM_SES').AsString) = '') then
  begin
    AnadirIncidenciaSesion(
      AIncidencias,
      0,
      STipoIncidenciaCabecera,
      SErrorAlmacenSesionFaltante);
  end;
end;

procedure TRepositorioComprasSesiones.ValidarExistenciaLineas(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarSesionConLineas,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      if AConsulta.FieldByName('N').AsInteger = 0 then
      begin
        AnadirIncidenciaSesion(
          AResultado,
          0,
          STipoIncidenciaCabecera,
          SErrorSesionSinLineas);
      end;
    end);
end;

procedure TRepositorioComprasSesiones.ValidarDuplicadosInternos(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarDuplicadosInternos,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(
          AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicadoInterno,
          Format(
            SErrorCodigoDuplicadoInternoSesion,
            [AConsulta.FieldByName(
               'CODIGO_ART_TENTATIVO_SESLIN').AsString,
             AConsulta.FieldByName('PRIMERA').AsInteger]));
        AConsulta.Next;
      end;
    end);
end;

procedure TRepositorioComprasSesiones.ValidarDuplicadosExternos(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarDuplicadosExternos,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(
          AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicado,
          Format(
            SErrorCodigoDuplicadoSesion,
            [AConsulta.FieldByName(
               'CODIGO_ART_TENTATIVO_SESLIN').AsString,
             IfThen(
               AConsulta.FieldByName('ESACTIVO_ART').AsString = 'N',
               STextoArticuloInactivoSesion,
               '')]));
        AConsulta.Next;
      end;
    end);
end;

procedure TRepositorioComprasSesiones.ValidarPvpArticulos(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion, DefinicionValidarPvpArticulos, FCatalogoSql,
    FIncidenciasSql, ASerie, ANumero, AIncidencias,
    procedure(AConsulta: TUniQuery; AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          'PVP_INCOMPATIBLE',
          Format(SErrorPvpIncompatibleArticuloSesion,
            [AConsulta.FieldByName('CODIGO_ART').AsString,
             AConsulta.FieldByName('PVP_MINIMO').AsString,
             AConsulta.FieldByName('PVP_MAXIMO').AsString]));
        AConsulta.Next;
      end;
    end);
end;

procedure TRepositorioComprasSesiones.ValidarReusoSinArticulo(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion, DefinicionValidarReusoSinArticulo, FCatalogoSql,
    FIncidenciasSql, ASerie, ANumero, AIncidencias,
    procedure(AConsulta: TUniQuery; AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDuplicado,
          Format(SErrorReusoSinArticuloSesion,
            [AConsulta.FieldByName('CODIGO_ART_REUSAR_SESLIN').AsString]));
        AConsulta.Next;
      end;
    end);
end;

procedure TRepositorioComprasSesiones.ValidarLineasSinCodigo(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarLineasSinCodigo,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(
          AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaCodigo,
          SErrorLineaSesionSinCodigo);
        AConsulta.Next;
      end;
    end);
end;

procedure TRepositorioComprasSesiones.ValidarLineasSinDescripcion(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarLineasSinDescripcion,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(
          AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaDescripcion,
          Format(
            SErrorLineaSesionSinDescripcion,
            [AConsulta.FieldByName(
               'CODIGO_ART_TENTATIVO_SESLIN').AsString]));
        AConsulta.Next;
      end;
    end);
end;

function TRepositorioComprasSesiones.ValidarSesionDetallado:
  TIncidenciasSesionCompra;
var
  iIncidencia: Integer;
  oIncidencias: TStringList;
  sNumero: string;
  sSerie: string;
begin
  AsegurarDataModule;
  Result := nil;
  oIncidencias := TStringList.Create;
  try
    if FDataModule.unqryTablaG.IsEmpty then
      oIncidencias.Add(SErrorSesionInactivaIncidencia)
    else
    begin
      sSerie := FDataModule.unqryTablaG.FieldByName(
        'SERIE_SES').AsString;
      sNumero := FDataModule.unqryTablaG.FieldByName(
        'NUMERO_SES').AsString;
      ValidarCabeceraSesion(oIncidencias);
      ValidarExistenciaLineas(sSerie, sNumero, oIncidencias);
      ValidarDuplicadosInternos(sSerie, sNumero, oIncidencias);
      ValidarDuplicadosExternos(sSerie, sNumero, oIncidencias);
      ValidarPvpArticulos(sSerie, sNumero, oIncidencias);
      ValidarReusoSinArticulo(sSerie, sNumero, oIncidencias);
      ValidarLineasSinCodigo(sSerie, sNumero, oIncidencias);
      ValidarLineasSinDescripcion(sSerie, sNumero, oIncidencias);
      ValidarMatricesSesion(sSerie, sNumero, oIncidencias);
      ValidarPropiedadesFamiliaSesion(
        FConexion, sSerie, sNumero, oIncidencias);
    end;
    SetLength(Result, oIncidencias.Count);
    for iIncidencia := 0 to oIncidencias.Count - 1 do
      Result[iIncidencia] := oIncidencias[iIncidencia];
  finally
    FreeAndNil(oIncidencias);
  end;
end;

procedure TRepositorioComprasSesiones.ValidarMatricesSesion(
  const ASerie, ANumero: string;
  AIncidencias: TStrings);
begin
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarMatricesSinCantidades,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(
          AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaCantidades,
          Format(
            SErrorLineaMatrizSinCantidades,
            [AConsulta.FieldByName(
               'CODIGO_ART_TENTATIVO_SESLIN').AsString,
             AConsulta.FieldByName('DESCRIPCION_SESLIN').AsString]));
        AConsulta.Next;
      end;
    end);
  EjecutarConsultaValidacionSesion(
    FConexion,
    DefinicionValidarMatricesSinTallaje,
    FCatalogoSql,
    FIncidenciasSql,
    ASerie,
    ANumero,
    AIncidencias,
    procedure(
      AConsulta: TUniQuery;
      AResultado: TStrings)
    begin
      while not AConsulta.Eof do
      begin
        AnadirIncidenciaSesion(
          AResultado,
          AConsulta.FieldByName('LINEA_SESLIN').AsInteger,
          STipoIncidenciaSistemaTallas,
          Format(
            SErrorLineaMatrizSinSistemaTallas,
            [AConsulta.FieldByName(
               'CODIGO_ART_TENTATIVO_SESLIN').AsString]));
        AConsulta.Next;
      end;
    end);
end;

function TRepositorioComprasSesiones.
  EjecutarConsultarCodigosBasicosActivos(
  const ASql, AIdVariacion: string): TArray<string>;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('va').AsString := AIdVariacion;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice] :=
        oConsulta.FieldByName('CODIGO_ATB').AsString;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.
  EjecutarConsultarKitProveedor(
  const ASql, ACodigoProveedor,
  ACodigoKit: string;
  AIdAcLinea: Integer): TKitProveedorSesion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TKitProveedorSesion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('ac').AsInteger := AIdAcLinea;
    oConsulta.ParamByName('prv').AsString :=
      ACodigoProveedor;
    oConsulta.ParamByName('kit').AsString := ACodigoKit;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result.Encontrado := True;
      Result.IdAcTallas :=
        oConsulta.FieldByName(
          'ID_AC_TALLAS_PRVKIT').AsInteger;
      Result.NombreTallasKit :=
        oConsulta.FieldByName(
          'NOMBRE_TALLAS_KIT').AsString;
      Result.NombreTallasLinea :=
        oConsulta.FieldByName(
          'NOMBRE_TALLAS_LIN').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.
  EjecutarConsultarDetallesKitProveedor(
  const ASql, ACodigoProveedor,
  ACodigoKit: string): TDetallesKitProveedorSesion;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('prv').AsString :=
      ACodigoProveedor;
    oConsulta.ParamByName('kit').AsString := ACodigoKit;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice].ValorDestino :=
        oConsulta.FieldByName(
          'VALOR_DESTINO_PRVKITD').AsString;
      Result[iIndice].Cantidad :=
        oConsulta.FieldByName('CANTIDAD_PRVKITD').AsFloat;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.EjecutarObtenerNombreFamilia(
  const ASql, ACodigoFamilia, ACampo: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('codigo').AsString :=
      ACodigoFamilia;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result :=
        oConsulta.FieldByName(ACampo).AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.
  EjecutarResolverDuplicadoPorCodigo(
  const ASql, ACodigoBuscado,
  ACodigoProveedor: string): TResolverDuplicadoSesion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResolverDuplicadoSesion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('art').AsString :=
      ACodigoBuscado;
    oConsulta.ParamByName('prv').AsString :=
      ACodigoProveedor;
    oConsulta.Open;
    Result := CargarDuplicadoArticulo(
      oConsulta,
      'ART');
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.
  EjecutarResolverDuplicadoPorReferencia(
  const ASql, ACodigoBuscado, ACodigoProveedor,
  ACodigoArticuloPreferido: string):
  TResolverDuplicadoSesion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResolverDuplicadoSesion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('prv').AsString :=
      ACodigoProveedor;
    oConsulta.ParamByName('ref').AsString :=
      ACodigoBuscado;
    oConsulta.ParamByName('artpref').AsString :=
      ACodigoArticuloPreferido;
    oConsulta.Open;
    Result := CargarDuplicadoArticulo(
      oConsulta,
      'REF');
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.
  EjecutarResolverDuplicadoIntraSesion(
  const ASql, ASerie, ANumero: string;
  ALineaActual: Integer;
  const AModelo, ACodigoArticulo: string):
  TResolverDuplicadoSesion;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TResolverDuplicadoSesion);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('serie').AsString := ASerie;
    oConsulta.ParamByName('numero').AsString := ANumero;
    oConsulta.ParamByName('linea').AsInteger := ALineaActual;
    oConsulta.ParamByName('modelo').AsString := AModelo;
    oConsulta.ParamByName('codigo').AsString :=
      ACodigoArticulo;
    oConsulta.Open;
    Result := CargarDuplicadoIntraSesion(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.EjecutarObtenerPvpArticulo(
  const ASql, ACodigoArticulo,
  ACodigoTarifa: string): Double;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('art').AsString :=
      ACodigoArticulo;
    oConsulta.ParamByName('tar').AsString :=
      ACodigoTarifa;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result :=
        oConsulta.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.EjecutarObtenerSiguienteLinea(
  const ASql, ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.ParamByName('l').AsInteger := ALineaActual;
    oConsulta.Open;
    if not oConsulta.FieldByName('SIGUIENTE').IsNull then
      Result := oConsulta.FieldByName(
        'SIGUIENTE').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.EjecutarConsultarCantidadesLinea(
  const ASql, ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
var
  iIndice: Integer;
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('s').AsString := ASerie;
    oConsulta.ParamByName('n').AsString := ANumero;
    oConsulta.ParamByName('l').AsInteger := ALinea;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iIndice := 0;
    while not oConsulta.Eof do
    begin
      Result[iIndice].IdValorPivot :=
        oConsulta.FieldByName(
          'ID_AV_PIVOT_SESCEL').AsInteger;
      Result[iIndice].Cantidad :=
        oConsulta.FieldByName('TOTAL').AsFloat;
      Inc(iIndice);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioComprasSesiones.ObtenerSiguienteLinea(
  const ASerie, ANumero: string;
  ALineaActual: Integer): Integer;
var
  oDefinicion: TDefinicionSql;
  iSiguiente: Integer;
begin
  oDefinicion := DefinicionSiguienteLinea;
  iSiguiente := 0;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      iSiguiente := EjecutarObtenerSiguienteLinea(
        ASql,
        ASerie,
        ANumero,
        ALineaActual);
    end,
    FIncidenciasSql);
  Result := iSiguiente;
end;

function TRepositorioComprasSesiones.ConsultarCantidadesLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TCantidadesPivotSesion;
var
  oCantidades: TCantidadesPivotSesion;
  oDefinicion: TDefinicionSql;
begin
  oDefinicion := DefinicionCantidadesLinea;
  oCantidades := nil;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    begin
      oCantidades := EjecutarConsultarCantidadesLinea(
        ASql,
        ASerie,
        ANumero,
        ALinea);
    end,
    FIncidenciasSql);
  Result := oCantidades;
end;

end.
