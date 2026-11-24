{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataDevolucionesCompraRepositorio                          }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas UniDAC auxiliares de devoluciones de compra.                    }
{******************************************************************************}
unit UniDataDevolucionesCompraRepositorio;

interface

uses
  Data.DB, Uni, inLibDevolucionesCompraPersistenciaIntf;

function TieneOrigenRecepcionDevolucion(ALinea: TDataSet): Boolean;
function ConsultaOrigenRecepcionDevolucion(AConexion: TUniConnection;
  const AEmpresa, AProveedor, AAlmacenRestringido: string): TDataSet;
procedure CopiarOrigenRecepcionDevolucion(AOrigen, ADestino: TDataSet);
procedure ValidarOrigenRecepcionDevolucion(AConexion: TUniConnection;
  ACabecera, ALinea: TDataSet; const AAlmacenRestringido: string);

function CrearServiciosPersistenciaDevolucionCompraUniDAC(
  AConexion: TUniConnection
): TServiciosPersistenciaDevolucionCompra;

implementation

uses
  System.SysUtils, System.Math, DBAccess,
  UniDataDevolucionesCompraStockRepositorio, inLibMsgCompras,
  inLibErroresBBDD;

const
  SQL_ENTRADAS_ORIGEN =
    'SELECT H.SERIE_ALBC AS SERIE, H.NUMERO_ALBC AS NUMERO, ' +
    'L.LINEA_ALBCLIN AS LINEA, H.FECHA_ALBC AS FECHA, ' +
    'M.CODIGO_UNIDAD_MOV AS SKU, M.CODIGO_ALM_MOV AS ALMACEN, ' +
    'M.CODIGO_ART_MOV AS ARTICULO, COALESCE(M.LOTE_MOV, '''') AS LOTE, ' +
    'MAX(M.FECHA_CADUCIDAD_MOV) AS CADUCIDAD, ' +
    'MAX(L.DESCRIPCION_ARTICULO_ALBCLIN) AS DESCRIPCION, ' +
    'MAX(L.REF_PRV_ALBCLIN) AS MODELO, ' +
    'MAX(H.REF_PROVEEDOR_ALBC) AS REFERENCIA, ' +
    'MAX(L.TIPO_CANTIDAD_ARTICULO_ALBCLIN) AS UNIDAD, ' +
    'MAX(L.TIPO_IVA_ARTICULO_ALBCLIN) AS TIPO_IVA, ' +
    'MAX(L.SERIE_PEDC_ALBCLIN) AS SERIE_PEDIDO, ' +
    'MAX(L.NUMERO_PEDC_ALBCLIN) AS NUMERO_PEDIDO, ' +
    'MAX(L.LINEA_PEDC_ALBCLIN) AS LINEA_PEDIDO, ' +
    'SUM(M.CANTIDAD_MOV) AS RECIBIDAS, ' +
    'MAX(COALESCE(L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN,0) * ' +
    '(1-COALESCE(L.PORCENTAJE_DTO_ALBCLIN,0)/100) * ' +
    'GREATEST(0,1-CASE WHEN H.TOTAL_BRUTO_ALBC>0 ' +
    'AND COALESCE(H.TOTAL_DTO_COMERCIAL_ALBC,0)<>0 ' +
    'THEN H.TOTAL_DTO_COMERCIAL_ALBC/H.TOTAL_BRUTO_ALBC ' +
    'ELSE COALESCE(H.PORCENTAJE_DTO_COMERCIAL_ALBC,0)/100 END)) AS PRECIO ' +
    'FROM fza_albaranes_compra H JOIN fza_albaranes_compra_lineas L ' +
    'ON L.SERIE_ALBC_ALBCLIN=H.SERIE_ALBC ' +
    'AND L.NUMERO_ALBC_ALBCLIN=H.NUMERO_ALBC ' +
    'JOIN fza_movimientos_almacen M ON M.TIPO_DOC_MOV=''AC'' ' +
    'AND M.TIPO_MOV=''E'' AND M.ESACTIVO_MOV=''S'' AND M.CANTIDAD_MOV>0 ' +
    'AND M.SERIE_DOC_MOV=H.SERIE_ALBC AND M.NUMERO_DOC_MOV=H.NUMERO_ALBC ' +
    'AND M.LINEA_MOV=L.LINEA_ALBCLIN AND M.CODIGO_EMP_MOV=H.CODIGO_EMP_ALBC ' +
    'WHERE H.CODIGO_EMP_ALBC=:EMP AND H.CODIGO_PRV_ALBC=:PRV ' +
    'AND COALESCE(H.ESTADO_ALBC,'''')<>''CANCELADO'' ' +
    'AND EXISTS (SELECT 1 FROM fza_almacenes A ' +
    'WHERE A.CODIGO_EMP_ALM=H.CODIGO_EMP_ALBC ' +
    'AND A.CODIGO_ALM_ALM=M.CODIGO_ALM_MOV ' +
    'AND UPPER(TRIM(COALESCE(A.TIPO_USO_ALM,''''))) ' +
    'NOT IN (''DEPÓSITO'',''DEPOSITO'')) ' +
    'AND (COALESCE(TRIM(M.LOTE_MOV),'''')<>'''' OR NOT EXISTS (' +
    'SELECT 1 FROM fza_empresas E WHERE E.CODIGO_EMP_EMP=H.CODIGO_EMP_ALBC ' +
    'AND E.ESLOTES_REPOSICION_EMP=''S'')) ' +
    'AND COALESCE(M.CODIGO_UNIDAD_MOV,'''')<>'''' ';
  SQL_GRUPO_ORIGEN =
    'GROUP BY H.SERIE_ALBC,H.NUMERO_ALBC,L.LINEA_ALBCLIN,H.FECHA_ALBC,' +
    'M.CODIGO_UNIDAD_MOV,M.CODIGO_ALM_MOV,M.CODIGO_ART_MOV, ' +
    'COALESCE(M.LOTE_MOV,'''') ';
  SQL_DEVOLUCIONES_ORIGEN =
    'FROM fza_devoluciones_compra_lineas D WHERE D.CANTIDAD_DEVCLIN>0 AND ';

function TieneOrigenRecepcionDevolucion(ALinea: TDataSet): Boolean;
var
  Campo: TField;
begin
  Result := False;
  if Assigned(ALinea) and ALinea.Active then
  begin
    Campo := ALinea.FindField('SERIE_ALBC_DEVCLIN');
    Result := Assigned(Campo) and (Campo.AsString <> '');
  end;
end;

function ConsultaOrigenRecepcionDevolucion(AConexion: TUniConnection;
  const AEmpresa, AProveedor, AAlmacenRestringido: string): TDataSet;
var
  Datos: TUniQuery;
begin
  Datos := TUniQuery.Create(nil);
  try
    Datos.Connection := AConexion;
    Datos.SQL.Text :=
      'SELECT R.*, R.RECIBIDAS-COALESCE((SELECT SUM(D.CANTIDAD_DEVCLIN) ' +
      SQL_DEVOLUCIONES_ORIGEN + 'D.SERIE_ALBC_DEVCLIN=R.SERIE ' +
      'AND D.NUMERO_ALBC_DEVCLIN=R.NUMERO AND D.LINEA_ALBC_DEVCLIN=R.LINEA ' +
      'AND D.CODIGO_UNIDAD_DEVCLIN=R.SKU AND D.CODIGO_ALMACEN_DEVCLIN=R.ALMACEN ' +
      'AND COALESCE(D.LOTE_DEVCLIN,'''')=R.LOTE),0) AS PENDIENTES ' +
      'FROM (' + SQL_ENTRADAS_ORIGEN +
      'AND (:ALM='''' OR M.CODIGO_ALM_MOV=:ALM) ' +
      SQL_GRUPO_ORIGEN + ') R HAVING PENDIENTES>0 ' +
      'ORDER BY FECHA DESC, SERIE, NUMERO, LINEA, SKU';
    Datos.ParamByName('EMP').AsString := AEmpresa;
    Datos.ParamByName('PRV').AsString := AProveedor;
    Datos.ParamByName('ALM').AsString := AAlmacenRestringido;
    Datos.Open;
  except
    Datos.Free;
    raise;
  end;
  Result := Datos;
end;

procedure CopiarOrigenRecepcionDevolucion(AOrigen, ADestino: TDataSet);
const
  CAMPOS_ORIGEN: array[0..15] of string = (
    'SERIE', 'NUMERO', 'LINEA', 'ARTICULO', 'SKU', 'ALMACEN', 'MODELO',
    'DESCRIPCION', 'UNIDAD', 'TIPO_IVA', 'PRECIO', 'SERIE_PEDIDO',
    'NUMERO_PEDIDO', 'LINEA_PEDIDO', 'LOTE', 'CADUCIDAD');
  CAMPOS_DESTINO: array[0..15] of string = (
    'SERIE_ALBC', 'NUMERO_ALBC', 'LINEA_ALBC', 'CODIGO_ART', 'CODIGO_UNIDAD',
    'CODIGO_ALMACEN', 'REF_PRV', 'DESCRIPCION_ARTICULO',
    'TIPO_CANTIDAD_ARTICULO', 'TIPO_IVA_ARTICULO',
    'PRECIO_COMPRA_SIVA_ARTICULO', 'SERIE_PEDC', 'NUMERO_PEDC', 'LINEA_PEDC',
    'LOTE', 'FECHA_CADUCIDAD');
var
  I: Integer;
  Prefijo: string;
begin
  for I := Low(CAMPOS_ORIGEN) to High(CAMPOS_ORIGEN) do
    ADestino.FieldByName(CAMPOS_DESTINO[I] + '_DEVCLIN').Value :=
      AOrigen.FieldByName(CAMPOS_ORIGEN[I]).Value;
  if ADestino.State = dsInsert then
  begin
    for I := 1 to 5 do
    begin
      Prefijo := 'ATTR' + IntToStr(I);
      ADestino.FieldByName(Prefijo + '_VALOR_DEVCLIN').AsString := '';
      ADestino.FieldByName(Prefijo + '_NOMBRE_DEVCLIN').AsString := '';
    end;
    ADestino.FieldByName('NUM_ATRIBUTOS_DEVCLIN').AsInteger := 0;
  end;
end;

procedure ValidarOrigenRecepcionDevolucion(AConexion: TUniConnection;
  ACabecera, ALinea: TDataSet; const AAlmacenRestringido: string);
var
  Datos: TUniQuery;
  Pendientes, Cantidad: Double;
  Almacen: string;

  procedure ClaveRecepcion;
  begin
    Datos.ParamByName('SERIE').AsString :=
      ALinea.FieldByName('SERIE_ALBC_DEVCLIN').AsString;
    Datos.ParamByName('NUMERO').AsString :=
      ALinea.FieldByName('NUMERO_ALBC_DEVCLIN').AsString;
  end;

  procedure EmpresaProveedor;
  begin
    Datos.ParamByName('EMP').AsString :=
      ACabecera.FieldByName('CODIGO_EMP_DEVC').AsString;
    Datos.ParamByName('PRV').AsString :=
      ACabecera.FieldByName('CODIGO_PRV_DEVC').AsString;
  end;

  procedure ClavePartida;
  begin
    ClaveRecepcion;
    Datos.ParamByName('LINEA').AsString :=
      ALinea.FieldByName('LINEA_ALBC_DEVCLIN').AsString;
    Datos.ParamByName('SKU').AsString :=
      ALinea.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString;
    Datos.ParamByName('ALM').AsString := Almacen;
    Datos.ParamByName('LOTE').AsString :=
      ALinea.FieldByName('LOTE_DEVCLIN').AsString;
  end;

begin
  Almacen := ALinea.FieldByName('CODIGO_ALMACEN_DEVCLIN').AsString;
  if not AConexion.InTransaction or
     ((AAlmacenRestringido <> '') and
      not SameText(AAlmacenRestringido, Almacen)) then
    raise EValidacionBBDD.Create(SErrorOrigenRecepcionNoDisponible);
  Datos := TUniQuery.Create(nil);
  try
    Datos.Connection := AConexion;
    Datos.SQL.Text :=
      'SELECT SERIE_ALBC FROM fza_albaranes_compra ' +
      'WHERE SERIE_ALBC=:SERIE AND NUMERO_ALBC=:NUMERO ' +
      'AND CODIGO_EMP_ALBC=:EMP AND CODIGO_PRV_ALBC=:PRV FOR UPDATE';
    ClaveRecepcion;
    EmpresaProveedor;
    Datos.Open;
    if Datos.IsEmpty then
      raise EValidacionBBDD.Create(SErrorOrigenRecepcionNoDisponible);
    Datos.Close;
    Datos.SQL.Text := SQL_ENTRADAS_ORIGEN +
      'AND H.SERIE_ALBC=:SERIE AND H.NUMERO_ALBC=:NUMERO ' +
      'AND L.LINEA_ALBCLIN=:LINEA AND M.CODIGO_UNIDAD_MOV=:SKU ' +
      'AND M.CODIGO_ALM_MOV=:ALM AND COALESCE(M.LOTE_MOV,'''')=:LOTE ' +
      SQL_GRUPO_ORIGEN + 'FOR UPDATE';
    EmpresaProveedor;
    ClavePartida;
    Datos.Open;
    if Datos.IsEmpty then
      raise EValidacionBBDD.Create(SErrorOrigenRecepcionNoDisponible);
    Pendientes := Datos.FieldByName('RECIBIDAS').AsFloat;
    CopiarOrigenRecepcionDevolucion(Datos, ALinea);
    Datos.Close;
    Datos.SQL.Text := 'SELECT D.CANTIDAD_DEVCLIN ' +
      SQL_DEVOLUCIONES_ORIGEN + 'D.SERIE_ALBC_DEVCLIN=:SERIE ' +
      'AND D.NUMERO_ALBC_DEVCLIN=:NUMERO AND D.LINEA_ALBC_DEVCLIN=:LINEA ' +
      'AND D.CODIGO_UNIDAD_DEVCLIN=:SKU AND D.CODIGO_ALMACEN_DEVCLIN=:ALM ' +
      'AND COALESCE(D.LOTE_DEVCLIN,'''')=:LOTE ' +
      'AND NOT (D.SERIE_DEVC_DEVCLIN=:SERIE_DC ' +
      'AND D.NUMERO_DEVC_DEVCLIN=:NUMERO_DC AND D.LINEA_DEVCLIN=:LIN_DC) ' +
      'FOR UPDATE';
    ClavePartida;
    Datos.ParamByName('SERIE_DC').AsString :=
      ALinea.FieldByName('SERIE_DEVC_DEVCLIN').AsString;
    Datos.ParamByName('NUMERO_DC').AsString :=
      ALinea.FieldByName('NUMERO_DEVC_DEVCLIN').AsString;
    Datos.ParamByName('LIN_DC').AsString :=
      ALinea.FieldByName('LINEA_DEVCLIN').AsString;
    Datos.Open;
    while not Datos.Eof do
    begin
      Pendientes := Pendientes - Datos.Fields[0].AsFloat;
      Datos.Next;
    end;
    Cantidad := ALinea.FieldByName('CANTIDAD_DEVCLIN').AsFloat;
    if Cantidad <= 0 then
      raise EValidacionBBDD.Create(SErrorOrigenRecepcionCantidadPositiva);
    if Cantidad - Pendientes > 0.0000001 then
      raise EValidacionBBDD.CreateFmt(SErrorOrigenRecepcionCantidad,
        [Max(0.0, Pendientes)]);
  finally
    Datos.Free;
  end;
end;

type
  TRepositorioDatosDevolucionCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioDatosDevolucionCompra)
  private
    FConexion: TUniConnection;
    function SqlJoinColorLinea: string;
    function SqlCondicionGrupo(AIdColor: Integer): string;
    procedure AsignarGrupo(
      AConsulta: TUniQuery;
      const AGrupo: TGrupoColorDevolucionCompra);
  public
    constructor Create(AConexion: TUniConnection);
    function CodigoSkuRepresentanteColor(
      const ACodigoArticulo, AColor: string;
      AIdConjuntoPivot: Integer
    ): string;
    function ListarColoresArticulo(
      const ACodigoArticulo: string
    ): TColoresArticuloDevolucionCompra;
    function ObtenerColorLinea(
      const ASerie, ANumero, ALinea: string;
      out AIdColor: Integer
    ): Boolean;
    function BorrarGrupoColor(
      const AGrupo: TGrupoColorDevolucionCompra
    ): Integer;
    function ResolverConjuntoPivotArticulo(
      const ACodigoArticulo: string
    ): Integer;
    function ModeloProveedorArticulo(
      const ACodigoArticulo, ACodigoProveedor: string
    ): string;
    function EsCodigoArticuloExacto(
      const ACodigo: string
    ): Boolean;
  end;

constructor TRepositorioDatosDevolucionCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TRepositorioDatosDevolucionCompraUniDAC.SqlJoinColorLinea:
  string;
begin
  Result :=
    '  LEFT JOIN fza_atributos_sku SAC ' +
    '    ON SAC.CODIGO_UNIDAD_SKU_SA = L.CODIGO_UNIDAD_DEVCLIN ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_valores AV ' +
    '                WHERE AV.ID_AV = SAC.ID_AV_SA ' +
    '                  AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
    'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    '(SELECT SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 ' +
    'WHERE SK452.CODIGO_UNIDAD_SKU = SAC.CODIGO_UNIDAD_SKU_SA) ' +
    'AND EJ452.EJE_VA = ''F'')) ' +
    '  LEFT JOIN fza_atributos_valores AVC ' +
    '    ON AVC.ID_AV = SAC.ID_AV_SA ' +
    '   AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 WHERE ' +
    'SK452.CODIGO_UNIDAD_SKU = SAC.CODIGO_UNIDAD_SKU_SA) AND ' +
    'EJ452.EJE_VA = ''F'') ';
end;

function TRepositorioDatosDevolucionCompraUniDAC.SqlCondicionGrupo(
  AIdColor: Integer
): string;
begin
  Result :=
    ' WHERE L.SERIE_DEVC_DEVCLIN = :SERIE ' +
    '   AND L.NUMERO_DEVC_DEVCLIN = :NUMERO ' +
    '   AND L.CODIGO_ART_DEVCLIN = :ARTICULO ';
  if AIdColor > 0 then
  begin
    Result := Result +
      '   AND COALESCE(AVC.ID_AV, 0) = :COLOR ';
  end
  else
  begin
    Result := Result +
      '   AND COALESCE(AVC.ID_AV, 0) = 0 ';
  end;
end;

procedure TRepositorioDatosDevolucionCompraUniDAC.AsignarGrupo(
  AConsulta: TUniQuery;
  const AGrupo: TGrupoColorDevolucionCompra);
begin
  AConsulta.ParamByName('SERIE').AsString := AGrupo.Serie;
  AConsulta.ParamByName('NUMERO').AsString := AGrupo.Numero;
  AConsulta.ParamByName('ARTICULO').AsString := AGrupo.CodigoArticulo;
  if AGrupo.IdColor > 0 then
  begin
    AConsulta.ParamByName('COLOR').AsInteger := AGrupo.IdColor;
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.
  CodigoSkuRepresentanteColor(
    const ACodigoArticulo, AColor: string;
    AIdConjuntoPivot: Integer
  ): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  if (ACodigoArticulo <> '') and (AColor <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT X.SKU ' +
        '  FROM ( ' +
        '        SELECT SK.CODIGO_UNIDAD_SKU AS SKU, ' +
        '               COALESCE(NULLIF(AVC.AV, ''''), ' +
        '                 CASE WHEN EXISTS (SELECT 1 FROM ' +
      'VI_VARIACIONES_EJES E WHERE E.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND E.EJE_VA = ''F'') ' +
        '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
        '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
        '                      ELSE '''' END, '''') AS COLOR_TXT, ' +
        '               CASE WHEN :ID_CONJUNTO <= 0 THEN 0 ' +
        '                    WHEN TAL.ID_AV_SA IS NULL THEN 0 ' +
        '                    WHEN ACD.ID_AV_ACD IS NOT NULL THEN 0 ' +
        '                    ELSE 1 END AS PENALIZA, ' +
        '               COALESCE(ACD.ORDEN_ACD, 999999) AS ORDEN_TALLA ' +
        '          FROM fza_articulos_skus SK ' +
        '          LEFT JOIN fza_atributos_sku CO ' +
        '            ON CO.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '           AND EXISTS (' +
        '             SELECT 1 FROM fza_atributos_valores AVC0 ' +
        '              WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
        '                AND AVC0.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')) ' +
        '          LEFT JOIN fza_atributos_valores AVC ' +
        '            ON AVC.ID_AV = CO.ID_AV_SA ' +
        '           AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
        'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
        '          LEFT JOIN fza_atributos_sku TAL ' +
        '            ON TAL.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
        '           AND EXISTS (' +
        '             SELECT 1 FROM fza_atributos_valores AVT ' +
        '              WHERE AVT.ID_AV = TAL.ID_AV_SA ' +
        '                AND AVT.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
        'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
        'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'')) ' +
        '          LEFT JOIN fza_atributos_conjuntos_det ACD ' +
        '            ON ACD.ID_AC_ACD = :ID_CONJUNTO ' +
        '           AND ACD.ID_AV_ACD = TAL.ID_AV_SA ' +
        '         WHERE SK.CODIGO_ART_SKU = :ARTICULO ' +
        '           AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
        '       ) X ' +
        ' WHERE X.COLOR_TXT = :COLOR ' +
        ' ORDER BY X.PENALIZA, X.ORDEN_TALLA, X.SKU ' +
        ' LIMIT 1';
      oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
      oConsulta.ParamByName('COLOR').AsString := AColor;
      oConsulta.ParamByName('ID_CONJUNTO').AsInteger :=
        AIdConjuntoPivot;
      oConsulta.Open;
      if not oConsulta.Eof then
      begin
        Result := Trim(oConsulta.FieldByName('SKU').AsString);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.ListarColoresArticulo(
  const ACodigoArticulo: string
): TColoresArticuloDevolucionCompra;
var
  oConsulta: TUniQuery;
  iColor: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT X.COLOR_TXT, MIN(X.COLOR_COD) AS COLOR_COD ' +
      '  FROM ( ' +
      '        SELECT COALESCE(NULLIF(AVC.AV, ''''), ' +
      '                 CASE WHEN EXISTS (SELECT 1 FROM ' +
      'VI_VARIACIONES_EJES E WHERE E.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND E.EJE_VA = ''F'') ' +
      '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
      '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
      '                      ELSE '''' END, '''') AS COLOR_TXT, ' +
      '               COALESCE(ATBC.CODIGO_ATB, ' +
      '                 CASE WHEN EXISTS (SELECT 1 FROM ' +
      'VI_VARIACIONES_EJES E WHERE E.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND E.EJE_VA = ''F'') ' +
      '                      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(' +
      '                        SK.CODIGO_UNIDAD_SKU, ''/'', 2), ''/'', -1) ' +
      '                      ELSE '''' END, '''') AS COLOR_COD ' +
      '          FROM fza_articulos_skus SK ' +
      '          LEFT JOIN fza_atributos_sku CO ' +
      '            ON CO.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
      '           AND EXISTS (' +
      '             SELECT 1 FROM fza_atributos_valores AVC0 ' +
      '              WHERE AVC0.ID_AV = CO.ID_AV_SA ' +
      '                AND AVC0.ID_VA_AV = (SELECT EJ452.ID_ATB_VA ' +
      'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')) ' +
      '          LEFT JOIN fza_atributos_valores AVC ' +
      '            ON AVC.ID_AV = CO.ID_AV_SA ' +
      '           AND AVC.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
      'SK.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
      '          LEFT JOIN fza_atributos_basicos ATBC ' +
      '            ON ATBC.ID_ATB = AVC.ID_ATB_AV ' +
      '         WHERE SK.CODIGO_ART_SKU = :ARTICULO ' +
      '           AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
      '       ) X ' +
      ' WHERE X.COLOR_TXT <> '''' ' +
      ' GROUP BY X.COLOR_TXT ' +
      ' ORDER BY X.COLOR_TXT';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    SetLength(Result, oConsulta.RecordCount);
    iColor := 0;
    while not oConsulta.Eof do
    begin
      Result[iColor].Texto := Trim(
        oConsulta.FieldByName('COLOR_TXT').AsString);
      Result[iColor].Codigo := Trim(
        oConsulta.FieldByName('COLOR_COD').AsString);
      Inc(iColor);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.ObtenerColorLinea(
  const ASerie, ANumero, ALinea: string;
  out AIdColor: Integer
): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AIdColor := 0;
  if (ASerie <> '') and (ANumero <> '') and (ALinea <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(AVC.ID_AV, 0) AS COLOR_AV ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        SqlJoinColorLinea +
        ' WHERE L.SERIE_DEVC_DEVCLIN = :SERIE ' +
        '   AND L.NUMERO_DEVC_DEVCLIN = :NUMERO ' +
        '   AND L.LINEA_DEVCLIN = :LINEA';
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('LINEA').AsString := ALinea;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        AIdColor := oConsulta.FieldByName('COLOR_AV').AsInteger;
        Result := True;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.BorrarGrupoColor(
  const AGrupo: TGrupoColorDevolucionCompra
): Integer;
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
    begin
      FConexion.StartTransaction;
    end;
    try
      oConsulta.SQL.Text :=
        'DELETE C ' +
        '  FROM fza_devoluciones_compra_celdas C ' +
        '  JOIN fza_devoluciones_compra_lineas L ' +
        '    ON C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
        '   AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
        '   AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) ' +
        '       = CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
        SqlJoinColorLinea +
        SqlCondicionGrupo(AGrupo.IdColor);
      AsignarGrupo(oConsulta, AGrupo);
      oConsulta.ExecSQL;
      oConsulta.SQL.Text :=
        'DELETE L ' +
        '  FROM fza_devoluciones_compra_lineas L ' +
        SqlJoinColorLinea +
        SqlCondicionGrupo(AGrupo.IdColor);
      AsignarGrupo(oConsulta, AGrupo);
      oConsulta.ExecSQL;
      Result := oConsulta.RowsAffected;
      if bTransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Commit;
      end;
    except
      if bTransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.
  ResolverConjuntoPivotArticulo(
    const ACodigoArticulo: string
  ): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ACA.ID_AC_ACA ' +
      '  FROM fza_articulos_conjuntos_asign ACA ' +
      ' WHERE ACA.CODIGO_ART_ACA = :ARTICULO ' +
      '   AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
      'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
      'AR452.CODIGO_ART_ART = :ARTICULO) AND EJ452.EJE_VA = ''P'') ' +
      ' ORDER BY ACA.ID_VA_ACA ' +
      ' LIMIT 1';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.ModeloProveedorArticulo(
  const ACodigoArticulo, ACodigoProveedor: string
): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT AP.REF_PROVEEDOR_AP ' +
      '  FROM fza_articulos_proveedores AP ' +
      ' WHERE AP.CODIGO_ART_AP = :ARTICULO ' +
      '   AND COALESCE(TRIM(AP.REF_PROVEEDOR_AP), '''') <> '''' ' +
      ' ORDER BY CASE WHEN AP.CODIGO_PRV_AP = :PROVEEDOR ' +
      '               THEN 0 ELSE 1 END, ' +
      '          CASE AP.ESPROVEEDORPRINCIPAL_AP ' +
      '               WHEN ''S'' THEN 0 ELSE 1 END, ' +
      '          AP.FECHA_VALIDEZ_AP DESC, AP.CODIGO_PRV_AP ' +
      ' LIMIT 1';
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('PROVEEDOR').AsString := ACodigoProveedor;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      Result := oConsulta.FieldByName('REF_PROVEEDOR_AP').AsString;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioDatosDevolucionCompraUniDAC.EsCodigoArticuloExacto(
  const ACodigo: string
): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Trim(ACodigo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT 1 ' +
        '  FROM fza_articulos ' +
        ' WHERE CODIGO_ART_ART = :ARTICULO ' +
        ' LIMIT 1';
      oConsulta.ParamByName('ARTICULO').AsString := Trim(ACodigo);
      oConsulta.Open;
      Result := not oConsulta.IsEmpty;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearServiciosPersistenciaDevolucionCompraUniDAC(
  AConexion: TUniConnection
): TServiciosPersistenciaDevolucionCompra;
begin
  Result.Datos := TRepositorioDatosDevolucionCompraUniDAC.Create(
    AConexion);
  Result.Stock := CrearPersistenciaStockDevolucionCompra(AConexion);
end;

end.
