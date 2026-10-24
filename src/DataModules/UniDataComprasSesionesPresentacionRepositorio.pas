{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataComprasSesionesPresentacionRepositorio                 }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Consultas de enlace de los colaboradores de presentacion de sesiones      }
{    de compra.                                                                }
{******************************************************************************}
unit UniDataComprasSesionesPresentacionRepositorio;

interface

uses
  Uni,
  inLibVariacionesRotulos;

function CrearConsultaModelosProveedorUniDAC(
  AConexion: TUniConnection): TUniQuery;
// Sistemas de tallas activos (ID_AC, NOMBRE_AC, PRIMERA, ULTIMA) sin
// abrir: alimenta la lista del combo "Sistema tallas". Son todas las del
// atributo pivote del tipo indicado. La colección sigue perteneciendo
// al atributo, no al tipo de variación (FZ-ISSUE-449 y 452).
function CrearConsultaConjuntosTallasUniDAC(
  AConexion: TUniConnection;
  const ACodigoVariacion: string = ''): TUniQuery;
// Rótulos de la pantalla para un tipo de variación (FZ-ISSUE-420). Sin
// código, o si no existe, los de «Tallas y colores».
function CargarRotulosVariacionUniDAC(
  AConexion: TUniConnection;
  const ACodigoVariacion: string): TRotulosVariacion;
// Líneas de la sesión cuya colección pivote es de un atributo que el tipo
// de variación no tiene: para avisar al cambiar el de la cabecera.
function ContarLineasSesionOtraVariacionUniDAC(
  AConexion: TUniConnection;
  const ASerie, ANumero, ACodigoVariacion: string): Integer;
// Tipo de variación que se propone a una sesión nueva: el de la última
// sesión del proveedor o el de la última de cualquier proveedor. Vacío si
// no hay ninguno. AIdConjuntoTallas ya no interviene (FZ-ISSUE-449).
function VariacionPropuestaSesionUniDAC(
  AConexion: TUniConnection;
  AIdConjuntoTallas: Integer;
  const ACodigoProveedor: string): string;
// Valores activos de un atributo en su orden (las copas A, B, C...).
function ValoresAtributoUniDAC(AConexion: TUniConnection;
  const AIdAtributo: string): TArray<string>;

implementation

uses
  System.Classes,
  System.SysUtils,
  Data.DB;

const
  SQL_MODELOS_PROVEEDOR =
    'SELECT ap.REF_PROVEEDOR_AP AS REFPRV,' +
    '       ap.CODIGO_ART_AP    AS CODART,' +
    '       a.DESCRIPCION_ART   AS DESCRIPCION,' +
    '       ap.PRECIO_ULT_COMPRA_AP AS PCOMPRA,' +
    '       COALESCE((SELECT acn.NOMBRE_AC' +
    '                   FROM fza_articulos_conjuntos_asign aca' +
    '                   JOIN fza_atributos_conjuntos acn' +
    '                     ON acn.ID_AC = aca.ID_AC_ACA' +
    '                  WHERE aca.CODIGO_ART_ACA = a.CODIGO_ART_ART' +
    '                    AND aca.ID_VA_ACA = (SELECT ' +
    'EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 WHERE ' +
    'EJ452.ID_VAR_VA = a.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'')' +
    '                  ORDER BY aca.ID_VA_ACA LIMIT 1), '''') AS SISTEMA,' +
    '       COALESCE((SELECT GROUP_CONCAT(DISTINCT av.AV ORDER BY av.AV' +
    '                                     SEPARATOR '', '')' +
    '                   FROM fza_articulos_skus sk' +
    '                   JOIN fza_atributos_sku sa' +
    '                     ON sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU' +
    '                   JOIN fza_atributos_valores av' +
    '                     ON av.ID_AV = sa.ID_AV_SA AND ' +
    'av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')' +
    '                  WHERE sk.CODIGO_ART_SKU = a.CODIGO_ART_ART' +
    '                    AND sk.ESACTIVO_SKU = ''S''), '''') AS COLORES' +
    '  FROM fza_articulos_proveedores ap' +
    '  JOIN fza_articulos a ON a.CODIGO_ART_ART = ap.CODIGO_ART_AP' +
    '                       AND a.ESACTIVO_ART = ''S''' +
    ' WHERE ap.CODIGO_PRV_AP = :prv' +
    '   AND ap.REF_PROVEEDOR_AP IS NOT NULL' +
    '   AND ap.REF_PROVEEDOR_AP <> ''''' +
    ' GROUP BY ap.REF_PROVEEDOR_AP, ap.CODIGO_ART_AP, a.DESCRIPCION_ART,' +
    '          ap.PRECIO_ULT_COMPRA_AP' +
    ' ORDER BY ap.REF_PROVEEDOR_AP';
  SQL_CONJUNTOS_TALLAS =
    'SELECT AC.ID_AC, AC.NOMBRE_AC, ' +
    '  (SELECT COUNT(*) FROM fza_atributos_conjuntos_det ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC) AS CANTIDAD_TALLAS, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD, AV.AV LIMIT 1) AS PRIMERA, ' +
    '  (SELECT AV.AV FROM fza_atributos_conjuntos_det ACD ' +
    '     JOIN fza_atributos_valores AV ON AV.ID_AV = ACD.ID_AV_ACD ' +
    '    WHERE ACD.ID_AC_ACD = AC.ID_AC ' +
    '    ORDER BY ACD.ORDEN_ACD DESC, AV.AV DESC LIMIT 1) AS ULTIMA ' +
    '  FROM fza_atributos_conjuntos AC ' +
    ' WHERE AC.ESACTIVO_AC = ''S'' ' +
    // FZ-ISSUE-449 y 452: las colecciones del atributo pivote del tipo
    // de variación de la sesión (EJE_VA = 'P'), sea TAL o uno propio; sin
    // tipo, las de cualquier atributo pivote. Una base sin tipos de
    // variación definidos sigue viendo las de TAL.
    '   AND (AC.ID_VA_AC IN ( ' +
    '          SELECT EJ.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ ' +
    '           WHERE EJ.EJE_VA = ''P'' ' +
    '             AND (:CODIGO_VAR = '''' ' +
    '                  OR EJ.ID_VAR_VA = :CODIGO_VAR)) ' +
    '        OR (AC.ID_VA_AC = ''TAL'' AND NOT EXISTS ( ' +
    '          SELECT 1 FROM VI_VARIACIONES_EJES EJ0 ' +
    '           WHERE EJ0.EJE_VA = ''P''))) ' +
    ' ORDER BY AC.NOMBRE_AC';
  SQL_ROTULOS_VARIACION =
    'SELECT V.ROTULO_OTRO_VAR, V.ESCOLOR_BASICO_VAR ' +
    '  FROM fza_variaciones V ' +
    ' WHERE V.CODIGO_VAR = :CODIGO_VAR';
  SQL_ATRIBUTOS_VARIACION =
    // El eje sale de la vista y no de fza_variaciones_atributos.EJE_VA:
    // Artículos y Sesiones abren aunque la BBDD no tenga aún
    // 20261023_variaciones_eje_pestana.sql (entonces no hay pestañas).
    'SELECT VA.ID_ATB_VA, VA.NOMBRE_VA, VA.NOMBRE_VISIBLE_VA, ' +
    '       VA.ORDEN_VA, COALESCE(EJ.EJE_VA, '''') AS EJE_VA ' +
    '  FROM fza_variaciones_atributos VA ' +
    '  LEFT JOIN VI_VARIACIONES_EJES EJ ' +
    '    ON EJ.ID_VAR_VA = VA.ID_VAR_VA ' +
    '   AND EJ.ID_ATB_VA = VA.ID_ATB_VA ' +
    ' WHERE VA.ID_VAR_VA = :CODIGO_VAR ' +
    ' ORDER BY VA.ORDEN_VA, VA.ID_ATB_VA';
  SQL_LINEAS_OTRA_VARIACION =
    'SELECT COUNT(*) AS N ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    '  JOIN fza_atributos_conjuntos AC ' +
    '    ON AC.ID_AC = L.ID_AC_PIVOT_SESLIN ' +
    ' WHERE L.SERIE_SES_SESLIN = :SERIE ' +
    '   AND L.NUMERO_SES_SESLIN = :NUMERO ' +
    // FZ-ISSUE-449: una colección es de otra variación cuando su
    // atributo no está entre los del tipo de la sesión.
    '   AND NOT EXISTS (SELECT 1 FROM fza_variaciones_atributos VA ' +
    '        WHERE VA.ID_VAR_VA = :CODIGO_VAR ' +
    '          AND VA.ID_ATB_VA = AC.ID_VA_AC)';
  SQL_VARIACION_ULTIMA_SESION =
    'SELECT S.CODIGO_VAR_SES ' +
    '  FROM fza_compras_sesiones S ' +
    '  JOIN fza_variaciones V ' +
    '    ON V.CODIGO_VAR = S.CODIGO_VAR_SES AND V.ESACTIVO_VAR = ''S'' ' +
    ' WHERE (:PRV = '''' OR S.CODIGO_PRV_SES = :PRV) ' +
    ' ORDER BY S.INSTANTE_ALTA DESC, S.NUMERO_SES DESC ' +
    ' LIMIT 1';

function CrearConsultaModelosProveedorUniDAC(
  AConexion: TUniConnection): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    Result.SQL.Text := SQL_MODELOS_PROVEEDOR;
  except
    Result.Free;
    raise;
  end;
end;

function CrearConsultaConjuntosTallasUniDAC(
  AConexion: TUniConnection;
  const ACodigoVariacion: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    // FZ-ISSUE-452: la colección pertenece al atributo pivote del tipo.
    Result.SQL.Text := SQL_CONJUNTOS_TALLAS;
    Result.ParamByName('CODIGO_VAR').AsString := ACodigoVariacion;
    Result.ReadOnly := True;
  except
    Result.Free;
    raise;
  end;
end;

function LeerAtributosVariacion(
  AConsulta: TUniQuery;
  const ACodigoVariacion: string): TAtributosVariacionRotulo;
var
  iIndice: Integer;
begin
  AConsulta.SQL.Text := SQL_ATRIBUTOS_VARIACION;
  AConsulta.ParamByName('CODIGO_VAR').AsString := ACodigoVariacion;
  AConsulta.Open;
  try
    SetLength(Result, AConsulta.RecordCount);
    iIndice := 0;
    while not AConsulta.Eof do
    begin
      Result[iIndice].Id := AConsulta.FieldByName('ID_ATB_VA').AsString;
      Result[iIndice].Nombre :=
        AConsulta.FieldByName('NOMBRE_VA').AsString;
      Result[iIndice].NombreVisible :=
        AConsulta.FieldByName('NOMBRE_VISIBLE_VA').AsString;
      Result[iIndice].Orden := AConsulta.FieldByName('ORDEN_VA').AsInteger;
      Result[iIndice].EjeDeclarado :=
        AConsulta.FieldByName('EJE_VA').AsString;
      Inc(iIndice);
      AConsulta.Next;
    end;
  finally
    AConsulta.Close;
  end;
end;

function CargarRotulosVariacionUniDAC(
  AConexion: TUniConnection;
  const ACodigoVariacion: string): TRotulosVariacion;
var
  oConsulta: TUniQuery;
  sCodigo: string;
  sRotuloOtro: string;
  bColorBasico: Boolean;
begin
  sCodigo := Trim(ACodigoVariacion);
  Result := RotulosVariacionPorDefecto;
  if sCodigo <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SQL_ROTULOS_VARIACION;
      oConsulta.ParamByName('CODIGO_VAR').AsString := sCodigo;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        sRotuloOtro := oConsulta.FieldByName('ROTULO_OTRO_VAR').AsString;
        bColorBasico := SameText(Trim(
          oConsulta.FieldByName('ESCOLOR_BASICO_VAR').AsString), 'S');
        oConsulta.Close;
        Result := ConstruirRotulosVariacion(sCodigo,
          LeerAtributosVariacion(oConsulta, sCodigo),
          sRotuloOtro, bColorBasico);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function ContarLineasSesionOtraVariacionUniDAC(
  AConexion: TUniConnection;
  const ASerie, ANumero, ACodigoVariacion: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  if (Trim(ASerie) <> '') and (Trim(ANumero) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SQL_LINEAS_OTRA_VARIACION;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('CODIGO_VAR').AsString :=
        Trim(ACodigoVariacion);
      oConsulta.Open;
      Result := oConsulta.FieldByName('N').AsInteger;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function ValoresAtributoUniDAC(AConexion: TUniConnection;
  const AIdAtributo: string): TArray<string>;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  if Trim(AIdAtributo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT AV.AV ' +
        '  FROM fza_atributos_valores AV ' +
        ' WHERE AV.ID_VA_AV = :ATRIBUTO ' +
        '   AND COALESCE(AV.ESACTIVO_AV, ''S'') = ''S'' ' +
        ' ORDER BY AV.ORDEN_AV, AV.AV';
      oConsulta.ParamByName('ATRIBUTO').AsString := Trim(AIdAtributo);
      oConsulta.Open;
      while not oConsulta.Eof do
      begin
        Result := Result + [oConsulta.FieldByName('AV').AsString];
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function LeerPrimerValor(AConsulta: TUniQuery): string;
begin
  Result := '';
  AConsulta.Open;
  try
    if not AConsulta.IsEmpty then
      Result := Trim(AConsulta.Fields[0].AsString);
  finally
    AConsulta.Close;
  end;
end;

function VariacionPropuestaSesionUniDAC(
  AConexion: TUniConnection;
  AIdConjuntoTallas: Integer;
  const ACodigoProveedor: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    // FZ-ISSUE-449: la colección ya no tiene tipo de variación, así que
    // AIdConjuntoTallas no propone ninguno; decide la última sesión.
    if Trim(ACodigoProveedor) <> '' then
    begin
      oConsulta.SQL.Text := SQL_VARIACION_ULTIMA_SESION;
      oConsulta.ParamByName('PRV').AsString := Trim(ACodigoProveedor);
      Result := LeerPrimerValor(oConsulta);
    end;
    if Result = '' then
    begin
      oConsulta.SQL.Text := SQL_VARIACION_ULTIMA_SESION;
      oConsulta.ParamByName('PRV').AsString := '';
      Result := LeerPrimerValor(oConsulta);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
