{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataMargenRepositorio                                     }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Persistencia UniDAC del coste y precio calculados por el modal de margen. }
{******************************************************************************}
unit UniDataMargenRepositorio;

interface

uses
  Uni, inLibMargenPersistenciaIntf;

function CrearRepositorioMargenUniDAC(
  AConexion: TUniConnection): IRepositorioMargen;

implementation

uses
  System.SysUtils, Data.DB, inLibMsgArticulos,
  UniDataPrestaShopEncolado,
  inLibPrestaShopColaSenal, inLibMargenTarifa;

const
  SQL_COBERTURA_SKU_COMPRA =
    '(F.UNI = '''' OR F.UNI = S.CODIGO_UNIDAD_SKU ' +
    'OR (LOCATE(''/*/'', F.UNI) = 0 ' +
    'AND LEFT(S.CODIGO_UNIDAD_SKU, CHAR_LENGTH(F.UNI) + 1) ' +
    '= CONCAT(F.UNI, ''/'')) ' +
    'OR EXISTS (SELECT 1 FROM fza_atributos_sku ATS ' +
    'JOIN fza_atributos_valores TAL ON TAL.ID_AV = ATS.ID_AV_SA ' +
    'AND TAL.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'S.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P'') ' +
    'WHERE ATS.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU ' +
    'AND F.UNI = CONCAT(F.ART, ''/*/'', TAL.AV))) ';
  // Las importaciones antiguas conservan las compras, aunque aún no
  // exista su resumen por SKU. El coste neto sigue el panel de proveedores.
  SQL_COSTE_COMPRA_ALBARAN =
    'SELECT CAST((L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '(1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100)) * ' +
    'CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
    'GREATEST(0, 1 - CASE ' +
    'WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 THEN ' +
    'IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / A.TOTAL_BRUTO_ALBC ' +
    'ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100 END) ' +
    'ELSE GREATEST(0, 1 - ' +
    'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) END ' +
    'AS DECIMAL(19,6)) AS COSTE, ' +
    'A.FECHA_ALBC AS FECHA, A.CODIGO_PRV_ALBC AS PROVEEDOR ' +
    'FROM (SELECT :ARTICULO AS ART, :UNIDAD AS UNI) F ' +
    'JOIN fza_articulos_skus S ON S.CODIGO_ART_SKU = F.ART ' +
    'JOIN fza_albaranes_compra_lineas L ' +
    'ON L.CODIGO_ART_ALBCLIN = S.CODIGO_ART_SKU ' +
    'AND L.CODIGO_UNIDAD_ALBCLIN = S.CODIGO_UNIDAD_SKU ' +
    'JOIN fza_albaranes_compra A ' +
    'ON A.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
    'AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
    'WHERE IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
    'AND IFNULL(L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '(1 - IFNULL(L.PORCENTAJE_DTO_ALBCLIN, 0) / 100), 0) > 0 ' +
    'AND ' + SQL_COBERTURA_SKU_COMPRA +
    'ORDER BY A.FECHA_ALBC DESC, A.INSTANTE_ALTA DESC, ' +
    'A.SERIE_ALBC DESC, A.NUMERO_ALBC DESC, L.LINEA_ALBCLIN DESC LIMIT 1';
  // La ficha del artículo no depende de una empresa: se toma el IVA vigente
  // del grupo marcado por defecto.
  SQL_PORCENTAJES_IVA_DEFECTO =
    'SELECT IFNULL(I.PORCENTAJE_NORMAL_IVA, 0) AS IVAN, ' +
    'IFNULL(I.PORCENTAJE_REDUCIDO_IVA, 0) AS IVAR, ' +
    'IFNULL(I.PORCENTAJE_SUPERREDUCIDO_IVA, 0) AS IVAS, ' +
    'IFNULL(I.PORCENTAJE_EXENTO_IVA, 0) AS IVAE ' +
    'FROM fza_ivas I ' +
    'JOIN fza_ivas_grupos G ON G.IVA_IVAGRP = I.IVA_IVAGRP ' +
    'WHERE G.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
    'AND I.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (I.FECHA_HASTA_IVA IS NULL OR I.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY I.FECHA_DESDE_IVA DESC LIMIT 1';
  // Misma cobertura de SKU que las filas de tarifa: general, SKU exacto,
  // prefijo «artículo/color» o patrón «artículo/*/talla». El proveedor es
  // el del albarán de compra del SKU con la fecha de esa última compra.
  SQL_COSTE_ULTIMA_COMPRA =
    'SELECT C.PRECIO_ULT_COMPRA_SKUC AS COSTE, ' +
    'C.FECHA_ULT_COMPRA_SKUC AS FECHA, ' +
    '(SELECT A.CODIGO_PRV_ALBC FROM fza_albaranes_compra_lineas L ' +
    'JOIN fza_albaranes_compra A ON A.SERIE_ALBC = L.SERIE_ALBC_ALBCLIN ' +
    'AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
    'WHERE L.CODIGO_ART_ALBCLIN = S.CODIGO_ART_SKU ' +
    'AND L.CODIGO_UNIDAD_ALBCLIN = S.CODIGO_UNIDAD_SKU ' +
    'AND A.FECHA_ALBC = C.FECHA_ULT_COMPRA_SKUC ' +
    'AND COALESCE(A.CODIGO_PRV_ALBC, '''') <> '''' ' +
    'AND IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
    'ORDER BY A.INSTANTE_ALTA DESC, A.SERIE_ALBC DESC, ' +
    'A.NUMERO_ALBC DESC LIMIT 1) AS PROVEEDOR ' +
    'FROM (SELECT :ARTICULO AS ART, :UNIDAD AS UNI) F ' +
    'JOIN fza_articulos_skus S ON S.CODIGO_ART_SKU = F.ART ' +
    'JOIN fza_articulos_skus_costes C ' +
    'ON C.CODIGO_UNIDAD_SKU_SKUC = S.CODIGO_UNIDAD_SKU ' +
    'WHERE IFNULL(C.PRECIO_ULT_COMPRA_SKUC, 0) > 0 ' +
    'AND ' + SQL_COBERTURA_SKU_COMPRA +
    'ORDER BY C.FECHA_ULT_COMPRA_SKUC DESC, C.INSTANTE_MODIF DESC, ' +
    'S.CODIGO_UNIDAD_SKU LIMIT 1';
  SQL_GUARDAR_PRECIO_SALIDA =
    'UPDATE fza_articulos_tarifas SET ' +
    'PRECIO_COSTE_ARTTAR = :p_coste, ' +
    'PRECIO_SALIDA_ARTTAR = :p_salida, ' +
    'PRECIO_FINAL_ARTTAR = :p_salida - COALESCE(PRECIO_DTO_ARTTAR, 0), ' +
    'PORCENTAJE_DTO_ARTTAR = CASE WHEN :p_salida > 0 THEN ' +
    '(COALESCE(PRECIO_DTO_ARTTAR, 0) / :p_salida) * 100 ELSE 0 END, ' +
    'USUARIO_MODIF = :p_usuario, INSTANTE_MODIF = NOW() ' +
    'WHERE CODIGO_UNICO_ARTTAR = :p_unico';

type
  TRepositorioMargenUniDAC = class(
    TInterfacedObject,
    IRepositorioMargen)
  private
    FConexion: TUniConnection;
    procedure AbrirCompra(AConsulta: TUniQuery; const ASql,
      ACodigoArticulo, ACodigoUnidad: string);
    procedure GuardarPrecio(AConsulta: TUniQuery;
      const ASolicitud: TSolicitudPersistenciaMargen);
  public
    constructor Create(AConexion: TUniConnection);
    function Guardar(
      const ASolicitud: TSolicitudPersistenciaMargen
    ): TResultadoPersistenciaMargen;
    function PorcentajeIva(const ATipoIva: string): Double;
    function UltimaCompra(const ACodigoArticulo,
      ACodigoUnidadTarifa: string): TUltimaCompraTarifa;
  end;

constructor TRepositorioMargenUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

procedure TRepositorioMargenUniDAC.GuardarPrecio(
  AConsulta: TUniQuery;
  const ASolicitud: TSolicitudPersistenciaMargen);
begin
  AConsulta.SQL.Text :=
    'SELECT CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas ' +
    'WHERE CODIGO_UNICO_ARTTAR = :UNICO ' +
    'AND CODIGO_ART_ARTTAR = :ARTICULO FOR UPDATE';
  AConsulta.ParamByName('UNICO').AsInteger :=
    ASolicitud.CodigoUnicoTarifa;
  AConsulta.ParamByName('ARTICULO').AsString := ASolicitud.CodigoArticulo;
  AConsulta.Open;
  if AConsulta.IsEmpty then
    raise EDatabaseError.Create(SErrorPrecioTarifaNoGuardado);
  AConsulta.Close;
  AConsulta.SQL.Text := SQL_GUARDAR_PRECIO_SALIDA;
  AConsulta.ParamByName('p_salida').AsFloat := ASolicitud.PrecioSalida;
  AConsulta.ParamByName('p_coste').AsFloat := ASolicitud.PrecioCoste;
  AConsulta.ParamByName('p_usuario').AsString := ASolicitud.Usuario;
  AConsulta.ParamByName('p_unico').AsInteger := ASolicitud.CodigoUnicoTarifa;
  AConsulta.Execute;
end;

function TRepositorioMargenUniDAC.Guardar(
  const ASolicitud: TSolicitudPersistenciaMargen
): TResultadoPersistenciaMargen;
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  Result := Default(TResultadoPersistenciaMargen);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    bTransaccionPropia := not FConexion.InTransaction;
    if bTransaccionPropia then
      FConexion.StartTransaction;
    try
      GuardarPrecio(oConsulta, ASolicitud);
      EncolarPrecioPrestaShop(FConexion, ASolicitud.CodigoArticulo,
        ASolicitud.Usuario);
      if bTransaccionPropia then
        FConexion.Commit;
      Result.Guardado := True;
    except
      on E: Exception do
      begin
        if bTransaccionPropia then
        begin
          FConexion.Rollback;
          Result.MensajeError := E.Message;
        end
        else
          raise;
      end;
    end;
    if Result.Guardado and bTransaccionPropia then
      SolicitarProcesadoPrestaShop;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioMargenUniDAC.PorcentajeIva(
  const ATipoIva: string): Double;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_PORCENTAJES_IVA_DEFECTO;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := PorcentajeIvaPorTipo(ATipoIva,
        oConsulta.FieldByName('IVAN').AsFloat,
        oConsulta.FieldByName('IVAR').AsFloat,
        oConsulta.FieldByName('IVAS').AsFloat,
        oConsulta.FieldByName('IVAE').AsFloat);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioMargenUniDAC.AbrirCompra(AConsulta: TUniQuery;
  const ASql, ACodigoArticulo, ACodigoUnidad: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := ASql;
  AConsulta.ParamByName('ARTICULO').AsString := Trim(ACodigoArticulo);
  AConsulta.ParamByName('UNIDAD').AsString := Trim(ACodigoUnidad);
  AConsulta.Open;
end;

function TRepositorioMargenUniDAC.UltimaCompra(const ACodigoArticulo,
  ACodigoUnidadTarifa: string): TUltimaCompraTarifa;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TUltimaCompraTarifa);
  if Trim(ACodigoArticulo) <> '' then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      AbrirCompra(oConsulta, SQL_COSTE_ULTIMA_COMPRA,
        ACodigoArticulo, ACodigoUnidadTarifa);
      if oConsulta.IsEmpty then
        AbrirCompra(oConsulta, SQL_COSTE_COMPRA_ALBARAN,
          ACodigoArticulo, ACodigoUnidadTarifa);
      if not oConsulta.IsEmpty then
      begin
        Result.Coste := oConsulta.FieldByName('COSTE').AsFloat;
        if not oConsulta.FieldByName('FECHA').IsNull then
          Result.Fecha := oConsulta.FieldByName('FECHA').AsDateTime;
        Result.Proveedor :=
          Trim(oConsulta.FieldByName('PROVEEDOR').AsString);
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function CrearRepositorioMargenUniDAC(
  AConexion: TUniConnection): IRepositorioMargen;
begin
  Result := TRepositorioMargenUniDAC.Create(AConexion);
end;

end.
