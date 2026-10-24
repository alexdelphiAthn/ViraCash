{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopCola                                        }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       2.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Persiste eventos por artículo y obtiene su estado actual al reclamarlo.   }
{******************************************************************************}
unit UniDataPrestaShopCola;

interface

uses
  Uni, inLibPrestaShopColaIntf;

function CrearRepositorioPrestaShopColaUniDAC(
  AConexion: TUniConnection): IRepositorioPrestaShopCola;

implementation

uses
  inLibRedondeo,
  UniDataTarifasPrecioSql,
  System.Math, System.StrUtils, System.SysUtils, Data.DB,
  inLibPrestaShopColaSenal,
  UniDataPrestaShopPrecioCondicional;

type
  TRepositorioPrestaShopColaUniDAC = class(
    TInterfacedObject,
    IRepositorioPrestaShopCola)
  private
    FConexion: TUniConnection;
    FUsarDescuentoCondicional: Boolean;
    function CrearToken: string;
    function NuevaConsulta: TUniQuery;
    function PrecioSinIva(
      APrecio, APorcentajeIva: Double;
      AEsImpuestoIncluido: Boolean): Double;
    procedure CargarLineas(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      var ATrabajo: TTrabajoArticuloPrestaShop);
    procedure CargarPrecioProducto(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      var ATrabajo: TTrabajoArticuloPrestaShop);
  public
    constructor Create(AConexion: TUniConnection);
    procedure EncolarCambio(
      const ACodigoArticulo, ACodigoUnidad: string;
      AEsPrecio, AEsStock: Boolean;
      const AUsuario: string);
    procedure EncolarVisibilidad(
      const ACodigoArticulo: string;
      AAccion: TAccionVisibilidadPrestaShop;
      const AUsuario: string);
    function LeerConfiguracionPerfil(
      const AUsuario, AGrupo: string): TConfiguracionGlobalPrestaShop;
    function DestinoSinConflictos(
      const AConfiguracion: TConfiguracionGlobalPrestaShop;
      const AUsuario: string): Boolean;
    procedure ReconciliarSiProcede(
      const AConfiguracion: TConfiguracionPrestaShopCola;
      AHoras: Integer;
      const AUsuario: string);
    procedure ReencolarProcesandoCaducadas(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMinutos: Integer);
    function ReclamarRecuperacion(
      const AClaveInstalacion: string;
      AIdTienda, ASegundos: Integer;
      const AUsuario: string): Boolean;
    function BuscarPendientes(
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      AMaximo: Integer): TArray<Int64>;
    function TieneVisibilidadPendiente(
      const AClaveInstalacion: string;
      AIdTienda: Integer): Boolean;
    function MarcarProcesando(
      AIdCola: Int64;
      const AClaveInstalacion: string;
      AIdTienda: Integer;
      const AUsuario: string;
      out AToken: string): Boolean;
    procedure LeerTrabajo(
      AIdCola: Int64;
      const AToken: string;
      const AConfiguracion: TConfiguracionPrestaShopCola;
      out ATrabajo: TTrabajoArticuloPrestaShop);
    function RenovarReclamacion(
      AIdCola: Int64;
      const AToken: string): Boolean;
    function LiberarReclamacionSinIntento(
      AIdCola: Int64;
      const AToken, AUsuario: string): Boolean;
    function MarcarAltaEnCurso(
      AIdCola: Int64;
      const AToken: string): Boolean;
    procedure MarcarEnviada(
      AIdCola: Int64;
      const AToken, AUsuario: string;
      ATieneProximoPrecio: Boolean;
      AProximoPrecio: TDateTime);
    procedure GuardarErrorIntento(
      AIdCola: Int64;
      const AToken, AEstado: string;
      AEsperaSegundos: Integer;
      const AMensaje, AUsuario: string;
      AConsumirIntento: Boolean = True);
  end;

const
  CNivelesFamiliaAltaMaximo = 50;
  SQL_PRECIO_PRODUCTO =
    'SELECT {PRECIO_CONDICIONAL} AS PRECIO_BRUTO, ' +
    'tar.ESIMP_INCL_TAR, CASE a.TIPO_IVA_ART ' +
    'WHEN ''N'' THEN iva.PORCENTAJE_NORMAL_IVA ' +
    'WHEN ''R'' THEN iva.PORCENTAJE_REDUCIDO_IVA ' +
    'WHEN ''S'' THEN iva.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    'WHEN ''E'' THEN iva.PORCENTAJE_EXENTO_IVA ' +
    'ELSE NULL END AS PORCENTAJE_IVA ' +
    'FROM fza_articulos a ' +
    'JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'JOIN fza_tarifas tar ' +
    'ON tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'LEFT JOIN fza_ivas iva ON iva.CODIGO_IVA = (' +
    'SELECT iv2.CODIGO_IVA FROM fza_ivas iv2 ' +
    'WHERE iv2.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'AND iv2.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (iv2.FECHA_HASTA_IVA IS NULL ' +
    'OR iv2.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY iv2.FECHA_DESDE_IVA DESC, ' +
    'iv2.CODIGO_IVA DESC LIMIT 1) ' +
    'LEFT JOIN fza_articulos_tarifas tp ' +
    'ON tp.CODIGO_UNICO_ARTTAR = (' +
    'SELECT t.CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND (t.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR t.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'AND (t.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR t.FECHA_HASTA_ARTTAR >= CURDATE()) ' +
    'ORDER BY t.INSTANTE_MODIF DESC, ' +
    't.CODIGO_UNICO_ARTTAR DESC LIMIT 1) ' +
    'WHERE a.CODIGO_ART_ART = :ARTICULO ' +
    'AND a.ESWEB_ART = ''S''';
  SQL_LINEAS =
    'SELECT COALESCE(s.CODIGO_UNIDAD_SKU, ' +
    'a.CODIGO_ART_ART) AS CODIGO_SKU, ' +
    'a.ESACTIVO_ART, COALESCE(s.ESACTIVO_SKU, ' +
    'a.ESACTIVO_ART) AS ESACTIVO_SKU, a.ESVARIACION_ART, ' +
    'a.TIPO_ART, CASE WHEN s.CODIGO_UNIDAD_SKU IS NULL ' +
    'THEN ''N'' ELSE ''S'' END AS ESSKU_REAL, ' +
    '{PRECIO_CONDICIONAL} AS PRECIO_SKU_BRUTO, ' +
    'tar.ESIMP_INCL_TAR, CASE a.TIPO_IVA_ART ' +
    'WHEN ''N'' THEN iva.PORCENTAJE_NORMAL_IVA ' +
    'WHEN ''R'' THEN iva.PORCENTAJE_REDUCIDO_IVA ' +
    'WHEN ''S'' THEN iva.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    'WHEN ''E'' THEN iva.PORCENTAJE_EXENTO_IVA ' +
    'ELSE NULL END AS PORCENTAJE_IVA, ' +
    'CASE WHEN a.ESACTIVO_ART <> ''S'' ' +
    'OR COALESCE(s.ESACTIVO_SKU, a.ESACTIVO_ART) <> ''S'' THEN 0 ' +
    'ELSE COALESCE((SELECT FLOOR(GREATEST(' +
    'SUM(COALESCE(st.CANTIDAD_STK, 0)), 0)) ' +
    'FROM fza_articulos_stockactual st ' +
    'JOIN fza_almacenes alm ' +
    'ON alm.CODIGO_ALM_ALM = st.CODIGO_ALM_STK ' +
    'AND alm.CODIGO_EMP_ALM = :EMPRESA ' +
    'AND alm.ESWEB_ALM = ''S'' ' +
    'AND alm.ESACTIVO_ALM = ''S'' ' +
    'AND alm.ESFISICO_ALM = ''S'' ' +
    'AND UPPER(TRIM(alm.TIPO_USO_ALM)) = ''ESTANDAR'' ' +
    'WHERE st.CODIGO_UNIDAD_STK = ' +
    'COALESCE(s.CODIGO_UNIDAD_SKU, a.CODIGO_ART_ART)), 0) ' +
    'END AS CANTIDAD_STOCK ' +
    'FROM fza_articulos a ' +
    'LEFT JOIN fza_articulos_skus s ' +
    'ON s.CODIGO_ART_SKU = a.CODIGO_ART_ART ' +
    'AND a.ESVARIACION_ART = ''S'' ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'LEFT JOIN fza_tarifas tar ' +
    'ON tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'LEFT JOIN fza_ivas iva ON iva.CODIGO_IVA = (' +
    'SELECT iv2.CODIGO_IVA FROM fza_ivas iv2 ' +
    'WHERE iv2.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'AND iv2.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (iv2.FECHA_HASTA_IVA IS NULL ' +
    'OR iv2.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY iv2.FECHA_DESDE_IVA DESC, ' +
    'iv2.CODIGO_IVA DESC LIMIT 1) ' +
    'LEFT JOIN fza_articulos_tarifas te ' +
    'ON te.CODIGO_UNICO_ARTTAR = (' +
    '{PRECIO_TARIFA}) ' +
    'WHERE a.CODIGO_ART_ART = :ARTICULO ' +
    'AND a.ESWEB_ART = ''S'' ' +
    'ORDER BY CODIGO_SKU';
  SQL_PROXIMO_PRECIO =
    'SELECT MIN(x.FRONTERA) AS FRONTERA FROM (' +
    'SELECT t.FECHA_DESDE_ARTTAR AS FRONTERA ' +
    'FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = :ARTICULO ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND t.FECHA_DESDE_ARTTAR > CURDATE() ' +
    'UNION ALL SELECT DATE_ADD(t.FECHA_HASTA_ARTTAR, ' +
    'INTERVAL 1 DAY) FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = :ARTICULO ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND t.FECHA_HASTA_ARTTAR >= CURDATE() ' +
    'UNION ALL SELECT tar.FECHA_DESDE_DTO_TAR ' +
    'FROM fza_tarifas tar ' +
    'WHERE tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'AND tar.FECHA_DESDE_DTO_TAR > CURDATE() ' +
    'UNION ALL SELECT DATE_ADD(tar.FECHA_HASTA_DTO_TAR, ' +
    'INTERVAL 1 DAY) FROM fza_tarifas tar ' +
    'WHERE tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'AND tar.FECHA_HASTA_DTO_TAR >= CURDATE() ' +
    'UNION ALL SELECT iva.FECHA_DESDE_IVA ' +
    'FROM fza_ivas iva JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'AND iva.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'WHERE iva.FECHA_DESDE_IVA > CURDATE() ' +
    'UNION ALL SELECT DATE_ADD(iva.FECHA_HASTA_IVA, ' +
    'INTERVAL 1 DAY) FROM fza_ivas iva ' +
    'JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp.ESACTIVO_EMP = ''S'' ' +
    'AND iva.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'WHERE iva.FECHA_HASTA_IVA >= CURDATE()) x ' +
    'WHERE EXISTS (SELECT 1 FROM fza_tarifas tar_ok ' +
    'WHERE tar_ok.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar_ok.ESACTIVO_ARTTAR = ''S'') ' +
    'AND EXISTS (SELECT 1 FROM fza_empresas emp_ok ' +
    'WHERE emp_ok.CODIGO_EMP_EMP = :EMPRESA ' +
    'AND emp_ok.ESACTIVO_EMP = ''S'')';

function AccionVisibilidadTexto(
  AAccion: TAccionVisibilidadPrestaShop): string;
begin
  case AAccion of
    avpActivar:
      Result := 'A';
    avpDesactivar:
      Result := 'D';
  else
    Result := 'N';
  end;
end;

function TextoAccionVisibilidad(
  const AAccion: string): TAccionVisibilidadPrestaShop;
begin
  if SameText(Trim(AAccion), 'A') then
    Result := avpActivar
  else if SameText(Trim(AAccion), 'D') then
    Result := avpDesactivar
  else
    Result := avpNinguna;
end;

constructor TRepositorioPrestaShopColaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FUsarDescuentoCondicional :=
    EsquemaDescuentoCondicionalDisponible(FConexion);
end;

function TRepositorioPrestaShopColaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioPrestaShopColaUniDAC.CrearToken: string;
var
  oGuid: TGUID;
  sGuid: string;
begin
  CreateGUID(oGuid);
  sGuid := GUIDToString(oGuid);
  Result := Copy(sGuid, 2, 36);
end;

function TRepositorioPrestaShopColaUniDAC.PrecioSinIva(
  APrecio, APorcentajeIva: Double;
  AEsImpuestoIncluido: Boolean): Double;
begin
  Result := APrecio;
  if AEsImpuestoIncluido then
    Result := APrecio / (1 + (APorcentajeIva / 100));
  Result := RedondearDecimales(Result, 6);
end;

procedure TRepositorioPrestaShopColaUniDAC.EncolarCambio(
  const ACodigoArticulo, ACodigoUnidad: string;
  AEsPrecio, AEsStock: Boolean;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if (Trim(ACodigoArticulo) = '') and
     (Trim(ACodigoUnidad) = '') then
    raise EArgumentException.Create(
      'El cambio PrestaShop no identifica artículo ni unidad');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_ENCOLAR_CAMBIO(' +
      ':ARTICULO, :UNIDAD, :PRECIO, :STOCK, :USUARIO)';
    oConsulta.ParamByName('ARTICULO').AsString :=
      Trim(ACodigoArticulo);
    oConsulta.ParamByName('UNIDAD').AsString :=
      Trim(ACodigoUnidad);
    if AEsPrecio then
      oConsulta.ParamByName('PRECIO').AsString := 'S'
    else
      oConsulta.ParamByName('PRECIO').AsString := 'N';
    if AEsStock then
      oConsulta.ParamByName('STOCK').AsString := 'S'
    else
      oConsulta.ParamByName('STOCK').AsString := 'N';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
  if (AEsPrecio or AEsStock) and
     (not FConexion.InTransaction) then
    SolicitarProcesadoPrestaShop;
end;

procedure TRepositorioPrestaShopColaUniDAC.EncolarVisibilidad(
  const ACodigoArticulo: string;
  AAccion: TAccionVisibilidadPrestaShop;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  if Trim(ACodigoArticulo) = '' then
    raise EArgumentException.Create(
      'La visibilidad PrestaShop no identifica el artículo');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_ENCOLAR_VISIBILIDAD(' +
      ':ARTICULO, :ACCION, :USUARIO)';
    oConsulta.ParamByName('ARTICULO').AsString :=
      Trim(ACodigoArticulo);
    oConsulta.ParamByName('ACCION').AsString :=
      AccionVisibilidadTexto(AAccion);
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
  if not FConexion.InTransaction then
    SolicitarProcesadoPrestaShop;
end;

function TRepositorioPrestaShopColaUniDAC.LeerConfiguracionPerfil(
  const AUsuario, AGrupo: string): TConfiguracionGlobalPrestaShop;
var
  oConsulta: TUniQuery;
  sNombre: string;
  sValor: string;
begin
  Result := Default(TConfiguracionGlobalPrestaShop);
  Result.UrlApi := '';
  Result.SegundosCiclo := 60;
  Result.HorasBarrido := 24;
  Result.MaxIntentos := 10;
  Result.Cola.CodigoEmpresa := '1';
  Result.Cola.CodigoTarifa := 'PVP';
  Result.Cola.IdTienda := 1;
  Result.Cola.IdIdioma := 1;
  Result.Cola.IdCategoriaRaiz := 2;
  Result.Cola.IdReglaIvaNormal := 1;
  Result.Cola.IdReglaIvaReducido := 2;
  Result.Cola.IdReglaIvaSuperreducido := 3;
  Result.Cola.IdReglaIvaExento := 0;
  Result.Cola.NivelesFamiliaAlta := 0;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'CALL PRC_GETPERFILFORMULARIO(' +
      ':USUARIO, :GRUPO, :FORMULARIO)';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('GRUPO').AsString := AGrupo;
    oConsulta.ParamByName('FORMULARIO').AsString :=
      'frmMtoAppParam';
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      sNombre := oConsulta.FieldByName('SUBKEY_USUPER').AsString;
      sValor := oConsulta.FieldByName('VALUE_USUPER').AsString;
      if SameText(
           sNombre,
           'appPrestaShopSincronizarStockPrecios') then
        Result.SincronizarStockPrecios := SameText(sValor, 'True') or
          (sValor = '1') or SameText(sValor, 'S')
      else if SameText(sNombre, 'appPrestaShopCrearArticulos') then
        Result.CrearArticulos := SameText(sValor, 'True') or
          (sValor = '1') or SameText(sValor, 'S')
      else if SameText(
                sNombre,
                'appPrestaShopHacerBarridoPeriodico') then
        Result.HacerBarridoPeriodico := SameText(sValor, 'True') or
          (sValor = '1') or SameText(sValor, 'S')
      else if SameText(sNombre, 'appPrestaShopUrl') then
        Result.UrlApi := Trim(sValor)
      else if SameText(sNombre, 'appPrestaShopApiKey') then
        Result.ClaveApi := Trim(sValor)
      else if SameText(sNombre, 'appPrestaShopEmpresa') then
        Result.Cola.CodigoEmpresa := Trim(sValor)
      else if SameText(sNombre, 'appPrestaShopTarifa') then
        Result.Cola.CodigoTarifa := Trim(sValor)
      else if SameText(sNombre, 'appPrestaShopIdTienda') then
        Result.Cola.IdTienda := StrToIntDef(sValor, 1)
      else if SameText(sNombre, 'appPrestaShopIdIdioma') then
        Result.Cola.IdIdioma := StrToIntDef(sValor, 1)
      else if SameText(sNombre, 'appPrestaShopIdCategoriaRaiz') then
        Result.Cola.IdCategoriaRaiz := StrToIntDef(sValor, 2)
      else if SameText(sNombre, 'appPrestaShopReglaIvaNormal') then
        Result.Cola.IdReglaIvaNormal := StrToIntDef(sValor, 1)
      else if SameText(sNombre, 'appPrestaShopReglaIvaReducido') then
        Result.Cola.IdReglaIvaReducido := StrToIntDef(sValor, 2)
      else if SameText(
                sNombre,
                'appPrestaShopReglaIvaSuperreducido') then
        Result.Cola.IdReglaIvaSuperreducido := StrToIntDef(sValor, 3)
      else if SameText(sNombre, 'appPrestaShopReglaIvaExento') then
        Result.Cola.IdReglaIvaExento := StrToIntDef(sValor, 0)
      else if SameText(sNombre, 'appPrestaShopNivelesFamiliaAlta') then
        Result.Cola.NivelesFamiliaAlta := StrToIntDef(sValor, 0)
      else if SameText(sNombre, 'appPrestaShopSegundosCiclo') then
        Result.SegundosCiclo := StrToIntDef(sValor, 60)
      else if SameText(sNombre, 'appPrestaShopHorasBarrido') then
        Result.HorasBarrido := StrToIntDef(sValor, 24)
      else if SameText(sNombre, 'appPrestaShopMaxIntentos') then
        Result.MaxIntentos := StrToIntDef(sValor, 10);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  Result.Activo := Result.SincronizarStockPrecios;
  Result.Cola.StockActivo := Result.SincronizarStockPrecios;
  if Result.SegundosCiclo < 60 then
    Result.SegundosCiclo := 60;
  if Result.SegundosCiclo > 120 then
    Result.SegundosCiclo := 120;
  if Result.HorasBarrido < 1 then
    Result.HorasBarrido := 1;
  if Result.HorasBarrido > 720 then
    Result.HorasBarrido := 720;
  if Result.MaxIntentos < 1 then
    Result.MaxIntentos := 1;
  if Result.Cola.NivelesFamiliaAlta < 0 then
    Result.Cola.NivelesFamiliaAlta := 0;
  if Result.Cola.NivelesFamiliaAlta > CNivelesFamiliaAltaMaximo then
    Result.Cola.NivelesFamiliaAlta := CNivelesFamiliaAltaMaximo;
end;

function TRepositorioPrestaShopColaUniDAC.DestinoSinConflictos(
  const AConfiguracion: TConfiguracionGlobalPrestaShop;
  const AUsuario: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'WITH sujetos AS (' +
      'SELECT U.USUARIO_USU AS USUARIO, U.GRUPO_USU AS GRUPO ' +
      'FROM fza_usuarios U WHERE U.ESACTIVO_USU = ''S''), ' +
      'candidatos AS (' +
      'SELECT S.USUARIO, P.SUBKEY_USUPER, P.VALUE_USUPER, ' +
      'ROW_NUMBER() OVER (PARTITION BY S.USUARIO, P.SUBKEY_USUPER ' +
      'ORDER BY CASE ' +
      'WHEN P.USUARIO_GRUPO_USUPER = S.USUARIO THEN 1 ' +
      'WHEN P.USUARIO_GRUPO_USUPER = S.GRUPO THEN 2 ELSE 3 END) RN ' +
      'FROM sujetos S JOIN fza_usuarios_perfiles P ' +
      'ON P.USUARIO_GRUPO_USUPER IN (S.USUARIO, S.GRUPO, ''Todos'') ' +
      'AND P.KEY_USUPER = ''frmMtoAppParam'' ' +
      'AND P.SUBKEY_USUPER IN (' +
      '''appPrestaShopSincronizarStockPrecios'', ' +
      '''appPrestaShopCrearArticulos'', ''appPrestaShopUrl'', ' +
      '''appPrestaShopApiKey'', ' +
      '''appPrestaShopEmpresa'', ''appPrestaShopTarifa'', ' +
      '''appPrestaShopIdTienda'', ''appPrestaShopIdIdioma'', ' +
      '''appPrestaShopIdCategoriaRaiz'', ' +
      '''appPrestaShopReglaIvaNormal'', ' +
      '''appPrestaShopReglaIvaReducido'', ' +
      '''appPrestaShopReglaIvaSuperreducido'', ' +
      '''appPrestaShopReglaIvaExento'', ' +
      '''appPrestaShopNivelesFamiliaAlta'')), ' +
      'efectivos AS (' +
      'SELECT USUARIO, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopSincronizarStockPrecios'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''False'') SINCRONIZAR, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopCrearArticulos'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''False'') CREAR, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ''appPrestaShopUrl'' ' +
      'AND RN = 1 THEN VALUE_USUPER END), ' +
      ''''') URL_API, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopApiKey'' AND RN = 1 THEN VALUE_USUPER END), ' +
      ''''') API_KEY, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopEmpresa'' AND RN = 1 THEN VALUE_USUPER END), ' +
      '''1'') EMPRESA, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopTarifa'' AND RN = 1 THEN VALUE_USUPER END), ' +
      '''PVP'') TARIFA, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopIdTienda'' AND RN = 1 THEN VALUE_USUPER END), ' +
      '''1'') TIENDA, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopIdIdioma'' AND RN = 1 THEN VALUE_USUPER END), ' +
      '''1'') IDIOMA, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopIdCategoriaRaiz'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''2'') CATEGORIA_RAIZ, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopReglaIvaNormal'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''1'') IVA_NORMAL, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopReglaIvaReducido'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''2'') IVA_REDUCIDO, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopReglaIvaSuperreducido'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''3'') IVA_SUPERREDUCIDO, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopReglaIvaExento'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''0'') IVA_EXENTO, ' +
      'COALESCE(MAX(CASE WHEN SUBKEY_USUPER = ' +
      '''appPrestaShopNivelesFamiliaAlta'' AND RN = 1 ' +
      'THEN VALUE_USUPER END), ''0'') NIVELES_FAMILIA ' +
      'FROM candidatos GROUP BY USUARIO) ' +
      'SELECT COUNT(*) AS CONFLICTOS FROM efectivos E ' +
      'WHERE E.USUARIO <> :USUARIO ' +
      'AND UPPER(TRIM(E.SINCRONIZAR)) IN (''TRUE'', ''1'', ''S'') ' +
      'AND NULLIF(TRIM(E.URL_API), '''') IS NOT NULL ' +
      'AND NULLIF(TRIM(E.API_KEY), '''') IS NOT NULL ' +
      'AND NULLIF(TRIM(E.EMPRESA), '''') IS NOT NULL ' +
      'AND NULLIF(TRIM(E.TARIFA), '''') IS NOT NULL ' +
      'AND UPPER(SHA2(TRIM(TRAILING ''/'' FROM TRIM(E.URL_API)), ' +
      '256)) = :INSTALACION ' +
      'AND CASE WHEN TRIM(E.TIENDA) REGEXP ''^[+-]?[0-9]+$'' ' +
      'AND LENGTH(TRIM(E.TIENDA)) <= 11 ' +
      'AND CAST(TRIM(E.TIENDA) AS SIGNED) ' +
      'BETWEEN -2147483648 AND 2147483647 ' +
      'THEN CAST(TRIM(E.TIENDA) AS SIGNED) ELSE 1 END = :TIENDA ' +
      'AND (UPPER(TRIM(E.EMPRESA)) <> UPPER(TRIM(:EMPRESA)) ' +
      'OR UPPER(TRIM(E.TARIFA)) <> UPPER(TRIM(:TARIFA)) ' +
      'OR (TRIM(E.IDIOMA) + 0) <> :IDIOMA ' +
      'OR (TRIM(E.CATEGORIA_RAIZ) + 0) <> :CATEGORIA_RAIZ ' +
      'OR (TRIM(E.IVA_NORMAL) + 0) <> :IVA_NORMAL ' +
      'OR (TRIM(E.IVA_REDUCIDO) + 0) <> :IVA_REDUCIDO ' +
      'OR (TRIM(E.IVA_SUPERREDUCIDO) + 0) <> :IVA_SUPERREDUCIDO ' +
      'OR (TRIM(E.IVA_EXENTO) + 0) <> :IVA_EXENTO ' +
      'OR LEAST(50, GREATEST(0, CASE WHEN ' +
      'TRIM(E.NIVELES_FAMILIA) REGEXP ''^-?[0-9]+$'' AND ' +
      'LENGTH(TRIM(E.NIVELES_FAMILIA)) <= 3 THEN ' +
      'CAST(TRIM(E.NIVELES_FAMILIA) AS SIGNED) ELSE 0 END)) ' +
      '<> :NIVELES_FAMILIA ' +
      'OR (UPPER(TRIM(E.SINCRONIZAR)) IN (''TRUE'', ''1'', ''S'')) ' +
      '<> :SINCRONIZAR OR ' +
      '(UPPER(TRIM(E.CREAR)) IN (''TRUE'', ''1'', ''S'')) <> :CREAR)';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('INSTALACION').AsString :=
      AConfiguracion.Cola.ClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger :=
      AConfiguracion.Cola.IdTienda;
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.Cola.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.Cola.CodigoTarifa;
    oConsulta.ParamByName('IDIOMA').AsInteger :=
      AConfiguracion.Cola.IdIdioma;
    oConsulta.ParamByName('CATEGORIA_RAIZ').AsInteger :=
      AConfiguracion.Cola.IdCategoriaRaiz;
    oConsulta.ParamByName('IVA_NORMAL').AsInteger :=
      AConfiguracion.Cola.IdReglaIvaNormal;
    oConsulta.ParamByName('IVA_REDUCIDO').AsInteger :=
      AConfiguracion.Cola.IdReglaIvaReducido;
    oConsulta.ParamByName('IVA_SUPERREDUCIDO').AsInteger :=
      AConfiguracion.Cola.IdReglaIvaSuperreducido;
    oConsulta.ParamByName('IVA_EXENTO').AsInteger :=
      AConfiguracion.Cola.IdReglaIvaExento;
    oConsulta.ParamByName('NIVELES_FAMILIA').AsInteger :=
      AConfiguracion.Cola.NivelesFamiliaAlta;
    oConsulta.ParamByName('SINCRONIZAR').AsInteger :=
      Ord(AConfiguracion.SincronizarStockPrecios);
    oConsulta.ParamByName('CREAR').AsInteger :=
      Ord(AConfiguracion.CrearArticulos);
    oConsulta.Open;
    Result := oConsulta.FieldByName('CONFLICTOS').AsInteger = 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.ReconciliarSiProcede(
  const AConfiguracion: TConfiguracionPrestaShopCola;
  AHoras: Integer;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'CALL PRC_PRESTASHOP_RECONCILIAR(' +
      ':HORAS, :INSTALACION, :TIENDA, :EMPRESA, :TARIFA, ' +
      ':STOCK, :USUARIO)';
    oConsulta.ParamByName('HORAS').AsInteger := AHoras;
    oConsulta.ParamByName('INSTALACION').AsString :=
      AConfiguracion.ClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger :=
      AConfiguracion.IdTienda;
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    if AConfiguracion.StockActivo then
      oConsulta.ParamByName('STOCK').AsString := 'S'
    else
      oConsulta.ParamByName('STOCK').AsString := 'N';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.
  ReencolarProcesandoCaducadas(
  const AClaveInstalacion: string;
  AIdTienda: Integer;
  AMinutos: Integer);
var
  oConsulta: TUniQuery;
begin
  if AMinutos <= 0 then
    raise EArgumentOutOfRangeException.Create('AMinutos');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN ACCION_VISIBILIDAD_PSCOLA ' +
      'IN (''A'', ''D'') THEN ''PENDIENTE_VISIBILIDAD'' ' +
      'WHEN ESCAMBIO_PRECIO_PSCOLA = ''S'' OR ' +
      'ESCAMBIO_STOCK_PSCOLA = ''S'' THEN ''PENDIENTE'' ' +
      'ELSE ''ENVIADA'' END, ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW() ' +
      'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'') ' +
      'AND (INSTANTE_RECLAMACION_PSCOLA IS NULL OR ' +
      'INSTANTE_RECLAMACION_PSCOLA < ' +
      'DATE_SUB(NOW(), INTERVAL :MINUTOS MINUTE))';
    oConsulta.ParamByName('INSTALACION').AsString :=
      AClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
    oConsulta.ParamByName('MINUTOS').AsInteger := AMinutos;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.ReclamarRecuperacion(
  const AClaveInstalacion: string;
  AIdTienda, ASegundos: Integer;
  const AUsuario: string): Boolean;
var
  oProcedimiento: TUniStoredProc;
begin
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oProcedimiento.Connection := FConexion;
    oProcedimiento.StoredProcName :=
      'PRC_PRESTASHOP_RECLAMAR_RECUPERACION';
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_SEGUNDOS', ptInput).AsInteger := ASegundos;
    oProcedimiento.Params.CreateParam(
      ftString, 'p_CLAVE_INSTALACION', ptInput).AsString :=
      AClaveInstalacion;
    oProcedimiento.ParamByName('p_CLAVE_INSTALACION').Size := 64;
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_TIENDA', ptInput).AsInteger := AIdTienda;
    oProcedimiento.Params.CreateParam(
      ftString, 'p_USUARIO', ptInput).AsString := AUsuario;
    oProcedimiento.ParamByName('p_USUARIO').Size := 200;
    oProcedimiento.Params.CreateParam(
      ftInteger, 'p_RECLAMADA', ptOutput);
    oProcedimiento.Execute;
    Result :=
      oProcedimiento.ParamByName('p_RECLAMADA').AsInteger = 1;
  finally
    FreeAndNil(oProcedimiento);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.BuscarPendientes(
  const AClaveInstalacion: string;
  AIdTienda: Integer;
  AMaximo: Integer): TArray<Int64>;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  if AMaximo > 0 then
  begin
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text :=
        'SELECT ID_PSCOLA FROM fza_prestashop_cola ' +
        'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
        'AND ID_TIENDA_PSCOLA = :TIENDA ' +
        'AND ESTADO_PSCOLA IN ' +
        '(''PENDIENTE'', ''PENDIENTE_VISIBILIDAD'') ' +
        'AND (INSTANTE_PROXIMO_INTENTO_PSCOLA IS NULL OR ' +
        'INSTANTE_PROXIMO_INTENTO_PSCOLA <= NOW()) ' +
        'ORDER BY ID_PSCOLA LIMIT :MAXIMO';
      oConsulta.ParamByName('INSTALACION').AsString :=
        AClaveInstalacion;
      oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
      oConsulta.ParamByName('MAXIMO').AsInteger := AMaximo;
      oConsulta.Open;
      SetLength(Result, oConsulta.RecordCount);
      iFila := 0;
      while not oConsulta.Eof do
      begin
        Result[iFila] :=
          oConsulta.FieldByName('ID_PSCOLA').AsLargeInt;
        Inc(iFila);
        oConsulta.Next;
      end;
      SetLength(Result, iFila);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioPrestaShopColaUniDAC.TieneVisibilidadPendiente(
  const AClaveInstalacion: string;
  AIdTienda: Integer): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT COUNT(*) AS NUMERO_FILAS ' +
      'FROM fza_prestashop_cola ' +
      'WHERE CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND (ESTADO_PSCOLA = ''PROCESANDO_VISIBILIDAD'' ' +
      'OR (ESTADO_PSCOLA = ''PENDIENTE_VISIBILIDAD'' ' +
      'AND ACCION_VISIBILIDAD_PSCOLA IN (''A'', ''D'')))';
    oConsulta.ParamByName('INSTALACION').AsString :=
      AClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
    oConsulta.Open;
    Result := oConsulta.FieldByName('NUMERO_FILAS').AsInteger > 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.MarcarProcesando(
  AIdCola: Int64;
  const AClaveInstalacion: string;
  AIdTienda: Integer;
  const AUsuario: string;
  out AToken: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  AToken := CrearToken;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN ACCION_VISIBILIDAD_PSCOLA ' +
      'IN (''A'', ''D'') THEN ''PROCESANDO_VISIBILIDAD'' ' +
      'ELSE ''PROCESANDO'' END, ' +
      'VERSION_RECLAMADA_PSCOLA = VERSION_DESEADA_PSCOLA, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ' +
      'ESCAMBIO_PRECIO_PSCOLA, ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ' +
      'ESCAMBIO_STOCK_PSCOLA, ' +
      'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = ' +
      'ACCION_VISIBILIDAD_PSCOLA, ' +
      'ID_RECLAMACION_PSCOLA = :TOKEN, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NOW(), ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PENDIENTE'', ''PENDIENTE_VISIBILIDAD'') ' +
      'AND (INSTANTE_PROXIMO_INTENTO_PSCOLA IS NULL OR ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA <= NOW())';
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('INSTALACION').AsString :=
      AClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger := AIdTienda;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
    if not Result then
      AToken := '';
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.CargarPrecioProducto(
  const AConfiguracion: TConfiguracionPrestaShopCola;
  var ATrabajo: TTrabajoArticuloPrestaShop);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_PROXIMO_PRECIO;
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ATrabajo.CodigoArticulo;
    oConsulta.Open;
    ATrabajo.TieneProximoCambioPrecio :=
      not oConsulta.FieldByName('FRONTERA').IsNull;
    if ATrabajo.TieneProximoCambioPrecio then
      ATrabajo.ProximoCambioPrecio :=
        oConsulta.FieldByName('FRONTERA').AsDateTime;
    oConsulta.Close;
    oConsulta.SQL.Text := AplicarPrecioCondicionalPrestaShop(
      SQL_PRECIO_PRODUCTO,
      'tp',
      'tar',
      'a.CODIGO_ART_ART',
      '',
      FUsarDescuentoCondicional);
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ATrabajo.CodigoArticulo;
    oConsulta.Open;
    if oConsulta.IsEmpty or
       oConsulta.FieldByName('PRECIO_BRUTO').IsNull then
    begin
      if not ATrabajo.TieneProximoCambioPrecio then
        raise EDatabaseError.CreateFmt(
          'El artículo %s no tiene un precio web válido',
          [ATrabajo.CodigoArticulo]);
    end
    else
    begin
      if (oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S') and
         oConsulta.FieldByName('PORCENTAJE_IVA').IsNull then
        raise EDatabaseError.CreateFmt(
          'El artículo %s no tiene un tipo de IVA válido',
          [ATrabajo.CodigoArticulo]);
      ATrabajo.TienePrecioProducto := True;
      ATrabajo.PrecioProducto := PrecioSinIva(
        oConsulta.FieldByName('PRECIO_BRUTO').AsFloat,
        oConsulta.FieldByName('PORCENTAJE_IVA').AsFloat,
        oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S');
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.CargarLineas(
  const AConfiguracion: TConfiguracionPrestaShopCola;
  var ATrabajo: TTrabajoArticuloPrestaShop);
var
  bActiva: Boolean;
  bEsCombinacion: Boolean;
  iLinea: Integer;
  oConsulta: TUniQuery;
  oLinea: TLineaArticuloPrestaShop;
begin
  SetLength(ATrabajo.Lineas, 0);
  oConsulta := NuevaConsulta;
  try
    if ATrabajo.TieneStock then
    begin
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS NUMERO_ALMACENES ' +
        'FROM fza_almacenes ' +
        'WHERE CODIGO_EMP_ALM = :EMPRESA ' +
        'AND ESWEB_ALM = ''S'' ' +
        'AND ESACTIVO_ALM = ''S'' ' +
        'AND ESFISICO_ALM = ''S'' ' +
        'AND UPPER(TRIM(TIPO_USO_ALM)) = ''ESTANDAR''';
      oConsulta.ParamByName('EMPRESA').AsString :=
        AConfiguracion.CodigoEmpresa;
      oConsulta.Open;
      if oConsulta.FieldByName('NUMERO_ALMACENES').AsInteger = 0 then
        raise EDatabaseError.CreateFmt(
          'La empresa %s no tiene almacenes web activos, físicos y estándar',
          [AConfiguracion.CodigoEmpresa]);
      oConsulta.Close;
    end;
    oConsulta.SQL.Text := AplicarPrecioCondicionalPrestaShop(
      StringReplace(SQL_LINEAS, '{PRECIO_TARIFA}',
        SqlSeleccionPrecioTarifa('a.CODIGO_ART_ART',
          'COALESCE(s.CODIGO_UNIDAD_SKU, a.CODIGO_ART_ART)',
          ':TARIFA', 'CURDATE()'), [rfReplaceAll]),
      'te',
      'tar',
      'a.CODIGO_ART_ART',
      's.CODIGO_UNIDAD_SKU',
      FUsarDescuentoCondicional);
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString :=
      ATrabajo.CodigoArticulo;
    oConsulta.Open;
    iLinea := 0;
    while not oConsulta.Eof do
    begin
      oLinea := Default(TLineaArticuloPrestaShop);
      oLinea.CodigoSku :=
        oConsulta.FieldByName('CODIGO_SKU').AsString;
      if (oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S') and
         ((oConsulta.FieldByName('ESSKU_REAL').AsString <> 'S') or
          SameText(oLinea.CodigoSku, ATrabajo.CodigoArticulo)) then
        raise EDatabaseError.CreateFmt(
          'El artículo variable %s no tiene SKU diferenciados válidos',
          [ATrabajo.CodigoArticulo]);
      bEsCombinacion :=
        (oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S') and
        (oConsulta.FieldByName('ESSKU_REAL').AsString = 'S') and
        (not SameText(oLinea.CodigoSku, ATrabajo.CodigoArticulo));
      bActiva :=
        (oConsulta.FieldByName('ESACTIVO_ART').AsString = 'S') and
        (oConsulta.FieldByName('ESACTIVO_SKU').AsString = 'S');
      oLinea.EstaActiva := bActiva;
      oLinea.EsCombinacion := bEsCombinacion;
      oLinea.TieneStock := ATrabajo.TieneStock and
        (oConsulta.FieldByName('TIPO_ART').AsString <> 'SERVICIO');
      if oLinea.TieneStock then
        oLinea.Cantidad :=
          oConsulta.FieldByName('CANTIDAD_STOCK').AsInteger;
      oLinea.TienePrecio := ATrabajo.TienePrecio and
        bEsCombinacion and bActiva and
        (not oConsulta.FieldByName('PRECIO_SKU_BRUTO').IsNull);
      if oLinea.TienePrecio then
      begin
        if (oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S') and
           oConsulta.FieldByName('PORCENTAJE_IVA').IsNull then
          raise EDatabaseError.CreateFmt(
            'El artículo %s no tiene un tipo de IVA válido',
            [ATrabajo.CodigoArticulo]);
        oLinea.Precio := PrecioSinIva(
          oConsulta.FieldByName('PRECIO_SKU_BRUTO').AsFloat,
          oConsulta.FieldByName('PORCENTAJE_IVA').AsFloat,
          oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S');
      end;
      if oLinea.TienePrecio or oLinea.TieneStock then
      begin
        SetLength(ATrabajo.Lineas, iLinea + 1);
        ATrabajo.Lineas[iLinea] := oLinea;
        Inc(iLinea);
      end;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.LeerTrabajo(
  AIdCola: Int64;
  const AToken: string;
  const AConfiguracion: TConfiguracionPrestaShopCola;
  out ATrabajo: TTrabajoArticuloPrestaShop);
var
  oConsulta: TUniQuery;
begin
  ATrabajo := Default(TTrabajoArticuloPrestaShop);
  ATrabajo.IdCola := AIdCola;
  ATrabajo.Token := AToken;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'SELECT c.ID_PSCOLA, c.ID_TIENDA_PSCOLA, ' +
      'c.CODIGO_ART_PSCOLA, c.CONTADOR_INTENTOS_PSCOLA, ' +
      'c.VERSION_RECLAMADA_PSCOLA, ' +
      'c.ESCAMBIO_PRECIO_RECLAMADO_PSCOLA, ' +
      'c.ESCAMBIO_STOCK_RECLAMADO_PSCOLA, ' +
      'c.ACCION_VISIBILIDAD_RECLAMADA_PSCOLA, ' +
      'c.ID_RECLAMACION_PSCOLA, a.ESWEB_ART, a.TIPO_ART, ' +
      'c.MENSAJE_ERROR_PSCOLA ' +
      'FROM fza_prestashop_cola c ' +
      'LEFT JOIN fza_articulos a ' +
      'ON a.CODIGO_ART_ART = c.CODIGO_ART_PSCOLA ' +
      'WHERE c.ID_PSCOLA = :ID ' +
      'AND c.CLAVE_INSTALACION_PSCOLA = :INSTALACION ' +
      'AND c.ID_TIENDA_PSCOLA = :TIENDA ' +
      'AND c.ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND c.ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'')';
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('INSTALACION').AsString :=
      AConfiguracion.ClaveInstalacion;
    oConsulta.ParamByName('TIENDA').AsInteger :=
      AConfiguracion.IdTienda;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      ATrabajo.IdCola :=
        oConsulta.FieldByName('ID_PSCOLA').AsLargeInt;
      ATrabajo.IdTienda :=
        oConsulta.FieldByName('ID_TIENDA_PSCOLA').AsInteger;
      ATrabajo.Intentos := oConsulta.FieldByName(
        'CONTADOR_INTENTOS_PSCOLA').AsInteger;
      ATrabajo.VersionReclamada := oConsulta.FieldByName(
        'VERSION_RECLAMADA_PSCOLA').AsLargeInt;
      ATrabajo.CodigoArticulo := oConsulta.FieldByName(
        'CODIGO_ART_PSCOLA').AsString;
      ATrabajo.Token := oConsulta.FieldByName(
        'ID_RECLAMACION_PSCOLA').AsString;
      ATrabajo.EstaEnWeb :=
        oConsulta.FieldByName('ESWEB_ART').AsString = 'S';
      ATrabajo.EsServicio := SameText(
        oConsulta.FieldByName('TIPO_ART').AsString,
        'SERVICIO');
      ATrabajo.TienePrecio := oConsulta.FieldByName(
        'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA').AsString = 'S';
      ATrabajo.TieneStock := oConsulta.FieldByName(
        'ESCAMBIO_STOCK_RECLAMADO_PSCOLA').AsString = 'S';
      ATrabajo.AccionVisibilidad := TextoAccionVisibilidad(
        oConsulta.FieldByName(
          'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA').AsString);
      ATrabajo.TieneStock := ATrabajo.TieneStock and
        AConfiguracion.StockActivo and
        (not ATrabajo.EsServicio);
      ATrabajo.ReanudarAlta := StartsText(
        CMarcaReanudacionAltaPrestaShop,
        oConsulta.FieldByName('MENSAJE_ERROR_PSCOLA').AsString);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if (ATrabajo.CodigoArticulo <> '') and ATrabajo.EstaEnWeb then
  begin
    if ATrabajo.TienePrecio then
      CargarPrecioProducto(AConfiguracion, ATrabajo);
    if (ATrabajo.TienePrecio and ATrabajo.TienePrecioProducto) or
       ATrabajo.TieneStock then
      CargarLineas(AConfiguracion, ATrabajo);
    if ATrabajo.TieneStock and (Length(ATrabajo.Lineas) = 0) then
      raise EDatabaseError.CreateFmt(
        'El artículo %s no tiene unidades válidas para sincronizar stock',
        [ATrabajo.CodigoArticulo]);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.RenovarReclamacion(
  AIdCola: Int64;
  const AToken: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola ' +
      'SET INSTANTE_RECLAMACION_PSCOLA = NOW() ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'') ' +
      'AND VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA';
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
    if not Result then
    begin
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS NUMERO_FILAS ' +
        'FROM fza_prestashop_cola ' +
        'WHERE ID_PSCOLA = :ID ' +
        'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
        'AND ESTADO_PSCOLA IN ' +
        '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'') ' +
        'AND VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA';
      oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
      oConsulta.ParamByName('TOKEN').AsString := AToken;
      oConsulta.Open;
      Result := oConsulta.FieldByName('NUMERO_FILAS').AsInteger = 1;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.LiberarReclamacionSinIntento(
  AIdCola: Int64;
  const AToken, AUsuario: string): Boolean;
var
  oConsulta: TUniQuery;
  sUsuario: string;
begin
  sUsuario := Copy(Trim(AUsuario), 1, 50);
  if sUsuario = '' then
    sUsuario := 'SISTEMA';
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN ACCION_VISIBILIDAD_PSCOLA ' +
      'IN (''A'', ''D'') OR ACCION_VISIBILIDAD_RECLAMADA_PSCOLA ' +
      'IN (''A'', ''D'') THEN ''PENDIENTE_VISIBILIDAD'' ' +
      'ELSE ''PENDIENTE'' END, ' +
      'ESCAMBIO_PRECIO_PSCOLA = CASE WHEN ' +
      'ESCAMBIO_PRECIO_PSCOLA = ''S'' OR ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''S'' THEN ''S'' ' +
      'ELSE ''N'' END, ' +
      'ESCAMBIO_STOCK_PSCOLA = CASE WHEN ' +
      'ESCAMBIO_STOCK_PSCOLA = ''S'' OR ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''S'' THEN ''S'' ' +
      'ELSE ''N'' END, ' +
      'ACCION_VISIBILIDAD_PSCOLA = CASE ' +
      'WHEN ACCION_VISIBILIDAD_PSCOLA IN (''A'', ''D'') ' +
      'THEN ACCION_VISIBILIDAD_PSCOLA ' +
      'WHEN ACCION_VISIBILIDAD_RECLAMADA_PSCOLA IN (''A'', ''D'') ' +
      'THEN ACCION_VISIBILIDAD_RECLAMADA_PSCOLA ELSE ''N'' END, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = NULL, ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'')';
    oConsulta.ParamByName('USUARIO').AsString := sUsuario;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioPrestaShopColaUniDAC.MarcarAltaEnCurso(
  AIdCola: Int64;
  const AToken: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola ' +
      'SET MENSAJE_ERROR_PSCOLA = :MARCA ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'') ' +
      'AND VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA';
    oConsulta.ParamByName('MARCA').AsString :=
      CMarcaReanudacionAltaPrestaShop;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
    Result := oConsulta.RowsAffected = 1;
    if not Result then
    begin
      oConsulta.SQL.Text :=
        'SELECT COUNT(*) AS NUMERO_FILAS ' +
        'FROM fza_prestashop_cola ' +
        'WHERE ID_PSCOLA = :ID ' +
        'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
        'AND ESTADO_PSCOLA IN ' +
        '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'') ' +
        'AND VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
        'AND MENSAJE_ERROR_PSCOLA = :MARCA';
      oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
      oConsulta.ParamByName('TOKEN').AsString := AToken;
      oConsulta.ParamByName('MARCA').AsString :=
        CMarcaReanudacionAltaPrestaShop;
      oConsulta.Open;
      Result := oConsulta.FieldByName('NUMERO_FILAS').AsInteger = 1;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.MarcarEnviada(
  AIdCola: Int64;
  const AToken, AUsuario: string;
  ATieneProximoPrecio: Boolean;
  AProximoPrecio: TDateTime);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA <> ' +
      'VERSION_RECLAMADA_PSCOLA AND ACCION_VISIBILIDAD_PSCOLA ' +
      'IN (''A'', ''D'') THEN ''PENDIENTE_VISIBILIDAD'' ' +
      'WHEN VERSION_DESEADA_PSCOLA <> VERSION_RECLAMADA_PSCOLA ' +
      'AND (ESCAMBIO_PRECIO_PSCOLA = ''S'' OR ' +
      'ESCAMBIO_STOCK_PSCOLA = ''S'') THEN ''PENDIENTE'' ' +
      'WHEN VERSION_DESEADA_PSCOLA <> VERSION_RECLAMADA_PSCOLA ' +
      'THEN ''ENVIADA'' ' +
      'WHEN :PROGRAMAR = ''S'' THEN ''PENDIENTE'' ' +
      'ELSE ''ENVIADA'' END, ' +
      'ESCAMBIO_PRECIO_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA = ' +
      'VERSION_RECLAMADA_PSCOLA AND :PROGRAMAR = ''S'' THEN ''S'' ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN ''N'' ' +
      'ELSE ESCAMBIO_PRECIO_PSCOLA END, ' +
      'ESCAMBIO_STOCK_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA = ' +
      'VERSION_RECLAMADA_PSCOLA THEN ''N'' ' +
      'ELSE ESCAMBIO_STOCK_PSCOLA END, ' +
      'ACCION_VISIBILIDAD_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN ''N'' ELSE ACCION_VISIBILIDAD_PSCOLA END, ' +
      'CONTADOR_INTENTOS_PSCOLA = 0, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA <> VERSION_RECLAMADA_PSCOLA ' +
      'THEN NULL WHEN :PROGRAMAR = ''S'' THEN :PROXIMO ' +
      'ELSE NULL END, ' +
      'MENSAJE_ERROR_PSCOLA = NULL, ' +
      'INSTANTE_ULTIMO_ENVIO_PSCOLA = NOW(), ' +
      'VERSION_DESEADA_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'AND :PROGRAMAR = ''S'' THEN VERSION_DESEADA_PSCOLA + 1 ' +
      'ELSE VERSION_DESEADA_PSCOLA END, ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'')';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    if ATieneProximoPrecio then
      oConsulta.ParamByName('PROGRAMAR').AsString := 'S'
    else
      oConsulta.ParamByName('PROGRAMAR').AsString := 'N';
    oConsulta.ParamByName('PROXIMO').DataType := ftDateTime;
    if ATieneProximoPrecio then
      oConsulta.ParamByName('PROXIMO').AsDateTime := AProximoPrecio
    else
      oConsulta.ParamByName('PROXIMO').Clear;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioPrestaShopColaUniDAC.GuardarErrorIntento(
  AIdCola: Int64;
  const AToken, AEstado: string;
  AEsperaSegundos: Integer;
  const AMensaje, AUsuario: string;
  AConsumirIntento: Boolean);
var
  oConsulta: TUniQuery;
begin
  if (AEstado <> 'PENDIENTE') and (AEstado <> 'ERROR') then
    raise EArgumentException.Create(
      'Estado de reintento PrestaShop no válido');
  if AEsperaSegundos < 0 then
    raise EArgumentOutOfRangeException.Create('AEsperaSegundos');
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text :=
      'UPDATE fza_prestashop_cola SET ' +
      'ESTADO_PSCOLA = CASE WHEN VERSION_DESEADA_PSCOLA = ' +
      'VERSION_RECLAMADA_PSCOLA AND :ESTADO = ''ERROR'' ' +
      'THEN ''ERROR'' WHEN ACCION_VISIBILIDAD_PSCOLA ' +
      'IN (''A'', ''D'') THEN ''PENDIENTE_VISIBILIDAD'' ' +
      'WHEN ESCAMBIO_PRECIO_PSCOLA = ''S'' OR ' +
      'ESCAMBIO_STOCK_PSCOLA = ''S'' THEN ''PENDIENTE'' ' +
      'ELSE ''ENVIADA'' END, ' +
      'CONTADOR_INTENTOS_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'AND :INCREMENTO = 0 THEN CONTADOR_INTENTOS_PSCOLA ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'AND :ESTADO = ''ERROR'' AND :ESPERA = 0 ' +
      'THEN CONTADOR_INTENTOS_PSCOLA ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN CONTADOR_INTENTOS_PSCOLA + 1 ELSE 0 END, ' +
      'INSTANTE_PROXIMO_INTENTO_PSCOLA = CASE ' +
      'WHEN :INCREMENTO = 0 THEN ' +
      'DATE_ADD(NOW(), INTERVAL :ESPERA SECOND) ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'AND :ESTADO = ''PENDIENTE'' THEN ' +
      'DATE_ADD(NOW(), INTERVAL :ESPERA SECOND) ELSE NULL END, ' +
      'MENSAJE_ERROR_PSCOLA = CASE ' +
      'WHEN VERSION_DESEADA_PSCOLA = VERSION_RECLAMADA_PSCOLA ' +
      'THEN CASE WHEN MENSAJE_ERROR_PSCOLA LIKE :MARCA_ALTA ' +
      'AND :MENSAJE NOT LIKE :MARCA_ALTA ' +
      'THEN CONCAT(:PREFIJO_ALTA, :MENSAJE) ELSE :MENSAJE END ' +
      'WHEN MENSAJE_ERROR_PSCOLA LIKE :MARCA_ALTA ' +
      'THEN MENSAJE_ERROR_PSCOLA ELSE NULL END, ' +
      'VERSION_RECLAMADA_PSCOLA = NULL, ' +
      'ESCAMBIO_PRECIO_RECLAMADO_PSCOLA = ''N'', ' +
      'ESCAMBIO_STOCK_RECLAMADO_PSCOLA = ''N'', ' +
      'ACCION_VISIBILIDAD_RECLAMADA_PSCOLA = ''N'', ' +
      'ID_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_RECLAMACION_PSCOLA = NULL, ' +
      'INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      'WHERE ID_PSCOLA = :ID ' +
      'AND ID_RECLAMACION_PSCOLA = :TOKEN ' +
      'AND ESTADO_PSCOLA IN ' +
      '(''PROCESANDO'', ''PROCESANDO_VISIBILIDAD'')';
    oConsulta.ParamByName('ESTADO').AsString := AEstado;
    if AConsumirIntento then
      oConsulta.ParamByName('INCREMENTO').AsInteger := 1
    else
      oConsulta.ParamByName('INCREMENTO').AsInteger := 0;
    oConsulta.ParamByName('ESPERA').AsInteger := AEsperaSegundos;
    oConsulta.ParamByName('MENSAJE').AsMemo := AMensaje;
    oConsulta.ParamByName('PREFIJO_ALTA').AsString :=
      CMarcaReanudacionAltaPrestaShop;
    oConsulta.ParamByName('MARCA_ALTA').AsString :=
      CMarcaReanudacionAltaPrestaShop + '%';
    oConsulta.ParamByName('USUARIO').AsString := AUsuario;
    oConsulta.ParamByName('ID').AsLargeInt := AIdCola;
    oConsulta.ParamByName('TOKEN').AsString := AToken;
    oConsulta.Execute;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioPrestaShopColaUniDAC(
  AConexion: TUniConnection): IRepositorioPrestaShopCola;
begin
  Result := TRepositorioPrestaShopColaUniDAC.Create(AConexion);
end;

end.
