{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopAltaArticulo                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Lee y valida la instantánea local necesaria para un alta en PrestaShop.  }
{******************************************************************************}
unit UniDataPrestaShopAltaArticulo;

interface

uses
  Uni,
  inLibPrestaShopAltaArticuloIntf;

function CrearRepositorioAltaArticuloPrestaUniDAC(
  AConexion: TUniConnection): IRepositorioAltaArticuloPresta;

implementation

uses
  inLibRedondeo,
  UniDataTarifasPrecioSql,
  System.Classes, System.Generics.Collections, System.Math,
  System.StrUtils, System.SysUtils, Data.DB, Vcl.Imaging.PngImage,
  inLibFotosAlmacenamiento, inLibFotosTipos,
  inLibLicenciaAplicacion, inLibParametrosIntf, inLibPathTokens,
  UniDataPrestaShopPrecioCondicional;

const
  CDirectorioFotosPredeterminado = '$(PUBLICO)\ViraCash\fotos';
  CLongitudReferenciaPresta = 64;
  CLongitudNombrePresta = 128;
  CLongitudNombrePublicoPresta = 64;
  CLongitudEnlacePresta = 128;
  CLongitudDescripcionCortaPresta = 800;
  CLongitudDescripcionPresta = 21844;
  CMaximoNivelesFamilia = 50;

  SQL_ARTICULO =
    'SELECT CODIGO_ART_ART, ESACTIVO_ART, ESWEB_ART, TIPO_ART, ' +
    'DESCRIPCION_ART, CODIGO_FAM_ART, TIPO_IVA_ART, ' +
    'ESVARIACION_ART, TIPO_VARIACION_ART ' +
    'FROM fza_articulos WHERE CODIGO_ART_ART = :ARTICULO';

  SQL_PRECIO_ARTICULO =
    'SELECT emp.CODIGO_EMP_EMP AS EMPRESA_OK, ' +
    'tar.CODIGO_TAR_ARTTAR AS TARIFA_OK, tar.ESIMP_INCL_TAR, ' +
    'CASE a.TIPO_IVA_ART ' +
    'WHEN ''N'' THEN iva.PORCENTAJE_NORMAL_IVA ' +
    'WHEN ''R'' THEN iva.PORCENTAJE_REDUCIDO_IVA ' +
    'WHEN ''S'' THEN iva.PORCENTAJE_SUPERREDUCIDO_IVA ' +
    'WHEN ''E'' THEN iva.PORCENTAJE_EXENTO_IVA ' +
    'ELSE NULL END AS PORCENTAJE_IVA, ' +
    '(SELECT {PRECIO_CONDICIONAL} ' +
    'FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_ART_ARTTAR = a.CODIGO_ART_ART ' +
    'AND t.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND t.ESACTIVO_ARTTAR = ''S'' ' +
    'AND COALESCE(t.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND (t.FECHA_DESDE_ARTTAR IS NULL OR ' +
    't.FECHA_DESDE_ARTTAR <= CURDATE()) ' +
    'AND (t.FECHA_HASTA_ARTTAR IS NULL OR ' +
    't.FECHA_HASTA_ARTTAR >= CURDATE()) ' +
    'ORDER BY t.INSTANTE_MODIF DESC, ' +
    't.CODIGO_UNICO_ARTTAR DESC LIMIT 1) AS PRECIO_BRUTO ' +
    'FROM fza_articulos a ' +
    'LEFT JOIN fza_empresas emp ' +
    'ON emp.CODIGO_EMP_EMP = :EMPRESA AND emp.ESACTIVO_EMP = ''S'' ' +
    'LEFT JOIN fza_tarifas tar ' +
    'ON tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'LEFT JOIN fza_ivas iva ON iva.CODIGO_IVA = (' +
    'SELECT iv2.CODIGO_IVA FROM fza_ivas iv2 ' +
    'WHERE iv2.IVA_IVAGRP = emp.GRUPO_ZONA_IVA_EMP ' +
    'AND iv2.FECHA_DESDE_IVA <= CURDATE() ' +
    'AND (iv2.FECHA_HASTA_IVA IS NULL OR ' +
    'iv2.FECHA_HASTA_IVA >= CURDATE()) ' +
    'ORDER BY iv2.FECHA_DESDE_IVA DESC, ' +
    'iv2.CODIGO_IVA DESC LIMIT 1) ' +
    'WHERE a.CODIGO_ART_ART = :ARTICULO';

  SQL_FAMILIA =
    'SELECT CODIGO_FAM_FAM, COALESCE(CODIGO_PADRE_FAM, '''') ' +
    'AS CODIGO_PADRE_FAM, ESACTIVO_FAM, ' +
    'COALESCE(NOMBRE_FAM_FAM, '''') AS NOMBRE_FAM_FAM ' +
    'FROM fza_articulos_familias WHERE CODIGO_FAM_FAM = :FAMILIA';

  SQL_SKUS =
    'SELECT s.CODIGO_UNIDAD_SKU, s.CODIGO_VAR_SKU, ' +
    '(SELECT {PRECIO_CONDICIONAL} ' +
    'FROM fza_articulos_tarifas t ' +
    'WHERE t.CODIGO_UNICO_ARTTAR = ({PRECIO_TARIFA})) ' +
    'AS PRECIO_BRUTO ' +
    'FROM fza_articulos_skus s ' +
    'JOIN fza_tarifas tar ON tar.CODIGO_TAR_ARTTAR = :TARIFA ' +
    'AND tar.ESACTIVO_ARTTAR = ''S'' ' +
    'WHERE s.CODIGO_ART_SKU = :ARTICULO ' +
    'AND s.ESACTIVO_SKU = ''S'' ORDER BY s.CODIGO_UNIDAD_SKU';

  SQL_ATRIBUTOS_SKU =
    'SELECT av.ID_AV, av.ID_VA_AV, av.AV, av.ESACTIVO_AV, ' +
    'va.ID_ATB_VA AS GRUPO_VALIDO, ' +
    'COALESCE(NULLIF(va.NOMBRE_VA, ''''), av.ID_VA_AV) ' +
    'AS NOMBRE_GRUPO, COALESCE(atb.CODIGO_ATB, ' +
    'CONCAT(''AV-'', av.ID_AV)) AS CODIGO_VALOR, ' +
    'COALESCE(NULLIF(atb.NOMBRE_ATB, ''''), av.AV) ' +
    'AS NOMBRE_VALOR, COALESCE(atb.HEX_ATB, '''') AS COLOR_HTML, ' +
    'atb.ID_ATB, atb.ESACTIVO_ATB ' +
    'FROM fza_atributos_sku sa ' +
    'JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    'LEFT JOIN fza_variaciones_atributos va ' +
    'ON va.ID_VAR_VA = :VARIACION AND va.ID_ATB_VA = av.ID_VA_AV ' +
    'LEFT JOIN fza_articulos_atributos_basicos aab ' +
    'ON aab.CODIGO_ART_AAB = :ARTICULO ' +
    'AND aab.ID_AV_AAB = av.ID_AV ' +
    'LEFT JOIN fza_atributos_basicos atb ' +
    'ON atb.ID_ATB = COALESCE(aab.ID_ATB_AAB, av.ID_ATB_AV) ' +
    'WHERE sa.CODIGO_UNIDAD_SKU_SA = :SKU ' +
    'ORDER BY va.ORDEN_VA, av.ORDEN_AV, av.ID_AV';

  SQL_NUMERO_ATRIBUTOS =
    'SELECT COUNT(*) AS NUMERO FROM fza_variaciones_atributos ' +
    'WHERE ID_VAR_VA = :VARIACION';

  SQL_NUMERO_ALMACENES_WEB =
    'SELECT COUNT(*) AS NUMERO FROM fza_almacenes ' +
    'WHERE CODIGO_EMP_ALM = :EMPRESA AND ESWEB_ALM = ''S'' ' +
    'AND ESACTIVO_ALM = ''S'' AND ESFISICO_ALM = ''S'' ' +
    'AND UPPER(TRIM(TIPO_USO_ALM)) = ''ESTANDAR''';

  SQL_STOCK =
    'SELECT FLOOR(GREATEST(SUM(COALESCE(st.CANTIDAD_STK, 0)), 0)) ' +
    'AS CANTIDAD FROM fza_articulos_stockactual st ' +
    'JOIN fza_almacenes alm ' +
    'ON alm.CODIGO_ALM_ALM = st.CODIGO_ALM_STK ' +
    'AND alm.CODIGO_EMP_ALM = :EMPRESA ' +
    'AND alm.ESWEB_ALM = ''S'' AND alm.ESACTIVO_ALM = ''S'' ' +
    'AND alm.ESFISICO_ALM = ''S'' ' +
    'AND UPPER(TRIM(alm.TIPO_USO_ALM)) = ''ESTANDAR'' ' +
    'WHERE st.CODIGO_UNIDAD_STK = :UNIDAD';

  SQL_FOTOS =
    'SELECT CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT, ' +
    'EXTENSION_ORIGEN_FOT, ORDEN_FOT FROM fza_articulos_fotos ' +
    'WHERE CODIGO_ART_FOT = :ARTICULO ' +
    'ORDER BY CASE WHEN CODIGO_UNIDAD_FOT = '''' THEN 0 ELSE 1 END, ' +
    'CODIGO_UNIDAD_FOT, ORDEN_FOT';

type
  TParametrosFotosPerfil = class(TInterfacedObject,
    IParametrosAplicacion)
  private
    FDirectorioFotos: string;
  public
    constructor Create(const ADirectorioFotos: string);
    function GetString(const AKey: string;
      const ADefault: string = ''): string;
    function GetBool(const AKey: string;
      const ADefault: Boolean = False): Boolean;
    function GetInt(const AKey: string;
      const ADefault: Integer = 0): Integer;
    function GetPath(const ANombre: string): string;
    function ImpresoraDocumentos: string;
    function Licencia: TResultadoLicenciaAplicacion;
  end;

  TRepositorioAltaArticuloPrestaUniDAC = class(TInterfacedObject,
    IRepositorioAltaArticuloPresta)
  private
    FConexion: TUniConnection;
    FUsarDescuentoCondicional: Boolean;
    function NuevaConsulta: TUniQuery;
    function LeerDirectorioFotos(
      const AUsuario, AGrupo: string): string;
    function CrearEnlace(const ATexto: string): string;
    function PrecioSinIva(APrecio, APorcentajeIva: Double;
      AImpuestoIncluido: Boolean): Double;
    function LeerCantidad(const ACodigoEmpresa,
      ACodigoUnidad: string): Integer;
    function LeerNumeroAtributos(const AVariacion: string): Integer;
    procedure CargarArticulo(const ACodigoArticulo: string;
      var AArticulo: TArticuloCompletoAltaPresta;
      out ACodigoFamilia, ACodigoVariacion: string);
    procedure CargarPrecio(const AConfiguracion:
      TConfiguracionAltaArticuloPresta;
      var AArticulo: TArticuloCompletoAltaPresta;
      out AImpuestoIncluido: Boolean);
    procedure CargarFamilias(const ACodigoFamilia: string;
      var AArticulo: TArticuloCompletoAltaPresta);
    function CargarAtributosSku(const ACodigoArticulo, ACodigoSku,
      ACodigoVariacion: string): TArray<TAtributoAltaArticuloPresta>;
    procedure CargarSkus(const ACodigoVariacion: string;
      const AConfiguracion: TConfiguracionAltaArticuloPresta;
      AImpuestoIncluido: Boolean;
      var AArticulo: TArticuloCompletoAltaPresta);
    procedure CargarFotos(const AUsuario, AGrupo: string;
      var AArticulo: TArticuloCompletoAltaPresta);
    procedure ValidarImagenPng(const ARuta: string);
    procedure ValidarTextosArticulo(
      const AArticulo: TArticuloCompletoAltaPresta);
    procedure ValidarFamilias(
      const AArticulo: TArticuloCompletoAltaPresta);
    procedure ValidarAtributo(
      const AAtributo: TAtributoAltaArticuloPresta;
      const AClavesGrupo, AClavesAtributo:
        TDictionary<string, string>);
    procedure ValidarSku(
      const ASku: TSkuAltaArticuloPresta;
      const ACodigosSku: TDictionary<string, Boolean>;
      const AClavesGrupo, AClavesAtributo:
        TDictionary<string, string>);
    procedure ValidarSkus(
      const AArticulo: TArticuloCompletoAltaPresta);
    procedure ValidarFotos(
      const AArticulo: TArticuloCompletoAltaPresta);
    procedure ValidarArticulo(
      const AArticulo: TArticuloCompletoAltaPresta);
  public
    constructor Create(AConexion: TUniConnection);
    function CargarValidado(
      const ACodigoArticulo, AUsuario, AGrupo: string;
      const AConfiguracion: TConfiguracionAltaArticuloPresta):
      TArticuloCompletoAltaPresta;
  end;

constructor TParametrosFotosPerfil.Create(
  const ADirectorioFotos: string);
begin
  inherited Create;
  FDirectorioFotos := ADirectorioFotos;
end;

function TParametrosFotosPerfil.GetString(const AKey,
  ADefault: string): string;
begin
  Result := ADefault;
  if SameText(AKey, 'appDirFotos') then
    Result := FDirectorioFotos;
end;

function TParametrosFotosPerfil.GetBool(const AKey: string;
  const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
end;

function TParametrosFotosPerfil.GetInt(const AKey: string;
  const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TParametrosFotosPerfil.GetPath(const ANombre: string): string;
begin
  Result := ExpandPathTokens(GetString(ANombre));
end;

function TParametrosFotosPerfil.ImpresoraDocumentos: string;
begin
  Result := '';
end;

function TParametrosFotosPerfil.Licencia: TResultadoLicenciaAplicacion;
begin
  Result := Default(TResultadoLicenciaAplicacion);
end;

constructor TRepositorioAltaArticuloPrestaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
  FUsarDescuentoCondicional :=
    EsquemaDescuentoCondicionalDisponible(FConexion);
end;

function TRepositorioAltaArticuloPrestaUniDAC.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRepositorioAltaArticuloPrestaUniDAC.LeerDirectorioFotos(
  const AUsuario, AGrupo: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := CDirectorioFotosPredeterminado;
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
      if SameText(
           oConsulta.FieldByName('SUBKEY_USUPER').AsString,
           'appDirFotos') then
      begin
        if Trim(oConsulta.FieldByName('VALUE_USUPER').AsString) <> '' then
          Result := Trim(
            oConsulta.FieldByName('VALUE_USUPER').AsString);
      end;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  Result := ExpandPathTokens(Result);
  if Trim(Result) = '' then
    raise EAltaArticuloPrestaLocal.Create(
      'No está configurada la carpeta de fotos appDirFotos.');
end;

function TRepositorioAltaArticuloPrestaUniDAC.CrearEnlace(
  const ATexto: string): string;
var
  cCaracter: Char;
  iIndice: Integer;
  sNormalizado: string;
begin
  sNormalizado := LowerCase(Trim(ATexto));
  sNormalizado := StringReplace(sNormalizado, 'á', 'a', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'à', 'a', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ä', 'a', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'é', 'e', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'è', 'e', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ë', 'e', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'í', 'i', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ì', 'i', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ï', 'i', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ó', 'o', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ò', 'o', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ö', 'o', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ú', 'u', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ù', 'u', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ü', 'u', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ñ', 'n', [rfReplaceAll]);
  sNormalizado := StringReplace(sNormalizado, 'ç', 'c', [rfReplaceAll]);
  Result := '';
  for iIndice := 1 to Length(sNormalizado) do
  begin
    cCaracter := sNormalizado[iIndice];
    if CharInSet(cCaracter, ['a'..'z', '0'..'9']) then
      Result := Result + cCaracter
    else if (Result <> '') and (Result[Length(Result)] <> '-') then
      Result := Result + '-';
  end;
  while (Result <> '') and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);
end;

function TRepositorioAltaArticuloPrestaUniDAC.PrecioSinIva(
  APrecio, APorcentajeIva: Double;
  AImpuestoIncluido: Boolean): Double;
begin
  Result := APrecio;
  if AImpuestoIncluido then
    Result := APrecio / (1 + (APorcentajeIva / 100));
  Result := RedondearDecimales(Result, 6);
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.CargarArticulo(
  const ACodigoArticulo: string;
  var AArticulo: TArticuloCompletoAltaPresta;
  out ACodigoFamilia, ACodigoVariacion: string);
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_ARTICULO;
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'No existe el artículo local "%s".', [ACodigoArticulo]);
    if oConsulta.FieldByName('ESACTIVO_ART').AsString <> 'S' then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El artículo local "%s" no está activo.', [ACodigoArticulo]);
    if oConsulta.FieldByName('ESWEB_ART').AsString <> 'S' then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El artículo local "%s" no está marcado para web.',
        [ACodigoArticulo]);
    AArticulo.Codigo := Trim(
      oConsulta.FieldByName('CODIGO_ART_ART').AsString);
    AArticulo.Nombre := Trim(
      oConsulta.FieldByName('DESCRIPCION_ART').AsString);
    AArticulo.Enlace := CrearEnlace(AArticulo.Nombre);
    if AArticulo.Enlace = '' then
      AArticulo.Enlace := CrearEnlace(AArticulo.Codigo);
    AArticulo.DescripcionCorta := AArticulo.Nombre;
    AArticulo.Descripcion := AArticulo.Nombre;
    AArticulo.TipoIva := UpperCase(Trim(
      oConsulta.FieldByName('TIPO_IVA_ART').AsString));
    AArticulo.EsServicio := SameText(
      oConsulta.FieldByName('TIPO_ART').AsString, 'SERVICIO');
    AArticulo.TieneVariaciones :=
      oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S';
    ACodigoFamilia := Trim(
      oConsulta.FieldByName('CODIGO_FAM_ART').AsString);
    ACodigoVariacion := Trim(
      oConsulta.FieldByName('TIPO_VARIACION_ART').AsString);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.CargarPrecio(
  const AConfiguracion: TConfiguracionAltaArticuloPresta;
  var AArticulo: TArticuloCompletoAltaPresta;
  out AImpuestoIncluido: Boolean);
var
  dPrecioBruto: Double;
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := AplicarPrecioCondicionalPrestaShop(
      SQL_PRECIO_ARTICULO,
      't',
      'tar',
      'a.CODIGO_ART_ART',
      '',
      FUsarDescuentoCondicional);
    oConsulta.ParamByName('EMPRESA').AsString :=
      AConfiguracion.CodigoEmpresa;
    oConsulta.ParamByName('TARIFA').AsString :=
      AConfiguracion.CodigoTarifa;
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo.Codigo;
    oConsulta.Open;
    if oConsulta.FieldByName('EMPRESA_OK').IsNull then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'La empresa "%s" no existe o no está activa.',
        [AConfiguracion.CodigoEmpresa]);
    if oConsulta.FieldByName('TARIFA_OK').IsNull then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'La tarifa web "%s" no existe o no está activa.',
        [AConfiguracion.CodigoTarifa]);
    if oConsulta.FieldByName('PORCENTAJE_IVA').IsNull then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'No se puede resolver el IVA %s del artículo "%s" ' +
        'para la empresa "%s".',
        [AArticulo.TipoIva, AArticulo.Codigo,
         AConfiguracion.CodigoEmpresa]);
    if oConsulta.FieldByName('PRECIO_BRUTO').IsNull then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El artículo "%s" no tiene precio vigente en la tarifa "%s".',
        [AArticulo.Codigo, AConfiguracion.CodigoTarifa]);
    AArticulo.PorcentajeIva :=
      oConsulta.FieldByName('PORCENTAJE_IVA').AsFloat;
    AImpuestoIncluido :=
      oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S';
    dPrecioBruto := oConsulta.FieldByName('PRECIO_BRUTO').AsFloat;
    AArticulo.PrecioBaseSinIva := PrecioSinIva(
      dPrecioBruto, AArticulo.PorcentajeIva, AImpuestoIncluido);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.CargarFamilias(
  const ACodigoFamilia: string;
  var AArticulo: TArticuloCompletoAltaPresta);
var
  iIndice: Integer;
  iNivel: Integer;
  oConsulta: TUniQuery;
  oFamilia: TFamiliaAltaArticuloPresta;
  oVisitadas: TDictionary<string, Boolean>;
  sCodigo: string;
  sClave: string;
begin
  SetLength(AArticulo.Familias, 0);
  if Trim(ACodigoFamilia) = '' then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El artículo "%s" no tiene familia.', [AArticulo.Codigo]);
  oVisitadas := TDictionary<string, Boolean>.Create;
  oConsulta := NuevaConsulta;
  try
    sCodigo := Trim(ACodigoFamilia);
    iNivel := 0;
    while sCodigo <> '' do
    begin
      Inc(iNivel);
      if iNivel > CMaximoNivelesFamilia then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La familia del artículo "%s" supera %d niveles.',
          [AArticulo.Codigo, CMaximoNivelesFamilia]);
      sClave := UpperCase(sCodigo);
      if oVisitadas.ContainsKey(sClave) then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La jerarquía de familias contiene un ciclo en "%s".',
          [sCodigo]);
      oVisitadas.Add(sClave, True);
      oConsulta.Close;
      oConsulta.SQL.Text := SQL_FAMILIA;
      oConsulta.ParamByName('FAMILIA').AsString := sCodigo;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'No existe la familia local "%s".', [sCodigo]);
      if oConsulta.FieldByName('ESACTIVO_FAM').AsString <> 'S' then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La familia local "%s" no está activa.', [sCodigo]);
      oFamilia := Default(TFamiliaAltaArticuloPresta);
      oFamilia.Codigo := Trim(
        oConsulta.FieldByName('CODIGO_FAM_FAM').AsString);
      oFamilia.CodigoPadre := Trim(
        oConsulta.FieldByName('CODIGO_PADRE_FAM').AsString);
      oFamilia.Nombre := Trim(
        oConsulta.FieldByName('NOMBRE_FAM_FAM').AsString);
      oFamilia.Enlace := CrearEnlace(oFamilia.Nombre);
      if oFamilia.Enlace = '' then
        oFamilia.Enlace := CrearEnlace(oFamilia.Codigo);
      SetLength(AArticulo.Familias, Length(AArticulo.Familias) + 1);
      for iIndice := High(AArticulo.Familias) downto 1 do
        AArticulo.Familias[iIndice] := AArticulo.Familias[iIndice - 1];
      AArticulo.Familias[0] := oFamilia;
      sCodigo := oFamilia.CodigoPadre;
    end;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oVisitadas);
  end;
end;

function TRepositorioAltaArticuloPrestaUniDAC.LeerNumeroAtributos(
  const AVariacion: string): Integer;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_NUMERO_ATRIBUTOS;
    oConsulta.ParamByName('VARIACION').AsString := AVariacion;
    oConsulta.Open;
    Result := oConsulta.FieldByName('NUMERO').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioAltaArticuloPrestaUniDAC.CargarAtributosSku(
  const ACodigoArticulo, ACodigoSku,
  ACodigoVariacion: string): TArray<TAtributoAltaArticuloPresta>;
var
  iAtributo: Integer;
  iEsperados: Integer;
  oAtributo: TAtributoAltaArticuloPresta;
  oConsulta: TUniQuery;
  oGrupos: TDictionary<string, Boolean>;
begin
  SetLength(Result, 0);
  iEsperados := LeerNumeroAtributos(ACodigoVariacion);
  if iEsperados = 0 then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'La variación "%s" del SKU "%s" no define atributos.',
      [ACodigoVariacion, ACodigoSku]);
  oGrupos := TDictionary<string, Boolean>.Create;
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_ATRIBUTOS_SKU;
    oConsulta.ParamByName('VARIACION').AsString := ACodigoVariacion;
    oConsulta.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    iAtributo := 0;
    while not oConsulta.Eof do
    begin
      if oConsulta.FieldByName('GRUPO_VALIDO').IsNull then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'El SKU "%s" contiene un atributo ajeno a la variación "%s".',
          [ACodigoSku, ACodigoVariacion]);
      if oConsulta.FieldByName('ESACTIVO_AV').AsString <> 'S' then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'El SKU "%s" usa un valor de atributo inactivo.', [ACodigoSku]);
      if (not oConsulta.FieldByName('ID_ATB').IsNull) and
         (oConsulta.FieldByName('ESACTIVO_ATB').AsString <> 'S') then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'El SKU "%s" usa un atributo básico inactivo.', [ACodigoSku]);
      oAtributo := Default(TAtributoAltaArticuloPresta);
      oAtributo.CodigoGrupo := Trim(
        oConsulta.FieldByName('ID_VA_AV').AsString);
      oAtributo.NombreGrupo := Trim(
        oConsulta.FieldByName('NOMBRE_GRUPO').AsString);
      oAtributo.NombrePublicoGrupo := oAtributo.NombreGrupo;
      oAtributo.EsColor := SameText(oAtributo.CodigoGrupo, 'CO');
      if oAtributo.EsColor then
        oAtributo.TipoGrupo := 'color'
      else
        oAtributo.TipoGrupo := 'select';
      oAtributo.CodigoValor := Trim(
        oConsulta.FieldByName('CODIGO_VALOR').AsString);
      oAtributo.NombreValor := Trim(
        oConsulta.FieldByName('NOMBRE_VALOR').AsString);
      oAtributo.ColorHtml := Trim(
        oConsulta.FieldByName('COLOR_HTML').AsString);
      if oGrupos.ContainsKey(UpperCase(oAtributo.CodigoGrupo)) then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'El SKU "%s" tiene más de un valor para el atributo "%s".',
          [ACodigoSku, oAtributo.CodigoGrupo]);
      oGrupos.Add(UpperCase(oAtributo.CodigoGrupo), True);
      SetLength(Result, iAtributo + 1);
      Result[iAtributo] := oAtributo;
      Inc(iAtributo);
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
    FreeAndNil(oGrupos);
  end;
  if Length(Result) <> iEsperados then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El SKU "%s" tiene %d atributos y su variación exige %d.',
      [ACodigoSku, Length(Result), iEsperados]);
end;

function TRepositorioAltaArticuloPrestaUniDAC.LeerCantidad(
  const ACodigoEmpresa, ACodigoUnidad: string): Integer;
var
  iCantidad: Int64;
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    oConsulta.SQL.Text := SQL_STOCK;
    oConsulta.ParamByName('EMPRESA').AsString := ACodigoEmpresa;
    oConsulta.ParamByName('UNIDAD').AsString := ACodigoUnidad;
    oConsulta.Open;
    if oConsulta.FieldByName('CANTIDAD').IsNull then
      iCantidad := 0
    else
      iCantidad := oConsulta.FieldByName('CANTIDAD').AsLargeInt;
    if (iCantidad < 0) or (iCantidad > MaxInt) then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El stock de "%s" no cabe en un entero válido.',
        [ACodigoUnidad]);
    Result := Integer(iCantidad);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.CargarSkus(
  const ACodigoVariacion: string;
  const AConfiguracion: TConfiguracionAltaArticuloPresta;
  AImpuestoIncluido: Boolean;
  var AArticulo: TArticuloCompletoAltaPresta);
var
  dPrecioBruto: Double;
  iSku: Integer;
  oConsulta: TUniQuery;
  oSku: TSkuAltaArticuloPresta;
begin
  SetLength(AArticulo.Skus, 0);
  if not AArticulo.TieneVariaciones then
  begin
    if AConfiguracion.StockActivo and (not AArticulo.EsServicio) then
      AArticulo.Cantidad := LeerCantidad(
        AConfiguracion.CodigoEmpresa, AArticulo.Codigo);
  end
  else
  begin
    if Trim(ACodigoVariacion) = '' then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El artículo variable "%s" no tiene tipo de variación.',
        [AArticulo.Codigo]);
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text := AplicarPrecioCondicionalPrestaShop(
        StringReplace(SQL_SKUS, '{PRECIO_TARIFA}',
          SqlSeleccionPrecioTarifa('s.CODIGO_ART_SKU',
            's.CODIGO_UNIDAD_SKU', ':TARIFA', 'CURDATE()'),
          [rfReplaceAll]),
        't',
        'tar',
        's.CODIGO_ART_SKU',
        's.CODIGO_UNIDAD_SKU',
        FUsarDescuentoCondicional);
      oConsulta.ParamByName('TARIFA').AsString :=
        AConfiguracion.CodigoTarifa;
      oConsulta.ParamByName('ARTICULO').AsString := AArticulo.Codigo;
      oConsulta.Open;
      iSku := 0;
      while not oConsulta.Eof do
      begin
        oSku := Default(TSkuAltaArticuloPresta);
        oSku.Codigo := Trim(
          oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString);
        if SameText(oSku.Codigo, AArticulo.Codigo) then
          raise EAltaArticuloPrestaLocal.CreateFmt(
            'El artículo variable "%s" contiene un SKU base sin atributos.',
            [AArticulo.Codigo]);
        if not SameText(
             Trim(oConsulta.FieldByName('CODIGO_VAR_SKU').AsString),
             ACodigoVariacion) then
          raise EAltaArticuloPrestaLocal.CreateFmt(
            'El SKU "%s" no pertenece a la variación "%s".',
            [oSku.Codigo, ACodigoVariacion]);
        if oConsulta.FieldByName('PRECIO_BRUTO').IsNull then
          raise EAltaArticuloPrestaLocal.CreateFmt(
            'El SKU "%s" no tiene precio vigente en la tarifa "%s".',
            [oSku.Codigo, AConfiguracion.CodigoTarifa]);
        dPrecioBruto :=
          oConsulta.FieldByName('PRECIO_BRUTO').AsFloat;
        oSku.PrecioSinIva := PrecioSinIva(
          dPrecioBruto, AArticulo.PorcentajeIva, AImpuestoIncluido);
        oSku.ImpactoPrecio := RedondearDecimales(
          oSku.PrecioSinIva - AArticulo.PrecioBaseSinIva, 6);
        if AConfiguracion.StockActivo and (not AArticulo.EsServicio) then
          oSku.Cantidad := LeerCantidad(
            AConfiguracion.CodigoEmpresa, oSku.Codigo);
        oSku.Predeterminado := iSku = 0;
        oSku.Atributos := CargarAtributosSku(
          AArticulo.Codigo, oSku.Codigo, ACodigoVariacion);
        SetLength(AArticulo.Skus, iSku + 1);
        AArticulo.Skus[iSku] := oSku;
        Inc(AArticulo.Cantidad, oSku.Cantidad);
        Inc(iSku);
        oConsulta.Next;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
    if Length(AArticulo.Skus) = 0 then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El artículo variable "%s" no tiene SKU activos.',
        [AArticulo.Codigo]);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarImagenPng(
  const ARuta: string);
var
  oImagen: TPngImage;
begin
  if not FileExists(ARuta) then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'No existe la foto real "%s".', [ARuta]);
  if not SameText(ExtractFileExt(ARuta), '.png') then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'La copia real de la foto no es PNG: "%s".', [ARuta]);
  oImagen := TPngImage.Create;
  try
    try
      oImagen.LoadFromFile(ARuta);
    except
      on E: Exception do
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La foto real "%s" no es legible: %s', [ARuta, E.Message]);
    end;
    if (oImagen.Width <= 0) or (oImagen.Height <= 0) then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'La foto real "%s" no tiene dimensiones válidas.', [ARuta]);
  finally
    FreeAndNil(oImagen);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.CargarFotos(
  const AUsuario, AGrupo: string;
  var AArticulo: TArticuloCompletoAltaPresta);
var
  bPrincipal: Boolean;
  iFoto: Integer;
  oAlmacenamiento: TAlmacenamientoFotos;
  oConsulta: TUniQuery;
  oFoto: TFotoAltaArticuloPresta;
  oInfo: TFotoInfo;
  oParametros: IParametrosAplicacion;
  oRutas: TDictionary<string, Boolean>;
  sDirectorio: string;
begin
  SetLength(AArticulo.Fotos, 0);
  bPrincipal := False;
  sDirectorio := LeerDirectorioFotos(AUsuario, AGrupo);
  oParametros := TParametrosFotosPerfil.Create(sDirectorio);
  oAlmacenamiento := TAlmacenamientoFotos.Create;
  oRutas := TDictionary<string, Boolean>.Create;
  oConsulta := NuevaConsulta;
  try
    oAlmacenamiento.AsignarParametros(oParametros);
    oConsulta.SQL.Text := SQL_FOTOS;
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo.Codigo;
    oConsulta.Open;
    iFoto := 0;
    while not oConsulta.Eof do
    begin
      oFoto := Default(TFotoAltaArticuloPresta);
      oFoto.CodigoUnidad := Trim(
        oConsulta.FieldByName('CODIGO_UNIDAD_FOT').AsString);
      if (oFoto.CodigoUnidad <> '') and
         (not StartsText(AArticulo.Codigo + '/', oFoto.CodigoUnidad)) then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La clave de foto "%s" no pertenece al artículo "%s".',
          [oFoto.CodigoUnidad, AArticulo.Codigo]);
      oFoto.Nombre := Trim(
        oConsulta.FieldByName('NOMBRE_FOT_FOT').AsString);
      // Sólo la primera foto general es la principal. Las restantes
      // pertenecen a la misma galería, pero PrestaShop debe recibir una
      // única imagen marcada como principal.
      oFoto.Principal := (oFoto.CodigoUnidad = '') and
        (oConsulta.FieldByName('ORDEN_FOT').AsInteger = 1);
      oInfo.Clear;
      oInfo.Encontrada := True;
      oInfo.CodigoArt := AArticulo.Codigo;
      oInfo.CodigoSku := oFoto.CodigoUnidad;
      oInfo.ClaveResuelta := oFoto.CodigoUnidad;
      oInfo.NombreBase := oFoto.Nombre;
      oInfo.ExtensionOrigen := Trim(
        oConsulta.FieldByName('EXTENSION_ORIGEN_FOT').AsString);
      if oFoto.Principal then
        oInfo.Origen := foArticulo
      else
        oInfo.Origen := foSkuPrefijo;
      oFoto.RutaReal := oAlmacenamiento.RutaFoto(oInfo, frReal);
      if oFoto.RutaReal = '' then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'No se encuentra la copia real de la foto "%s".',
          [oFoto.Nombre]);
      ValidarImagenPng(oFoto.RutaReal);
      if oRutas.ContainsKey(UpperCase(oFoto.RutaReal)) then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La ruta de foto real está duplicada: "%s".',
          [oFoto.RutaReal]);
      oRutas.Add(UpperCase(oFoto.RutaReal), True);
      if oFoto.Principal then
      begin
        if bPrincipal then
          raise EAltaArticuloPrestaLocal.CreateFmt(
            'El artículo "%s" tiene más de una foto general.',
            [AArticulo.Codigo]);
        bPrincipal := True;
      end;
      SetLength(AArticulo.Fotos, iFoto + 1);
      AArticulo.Fotos[iFoto] := oFoto;
      Inc(iFoto);
      oConsulta.Next;
    end;
  finally
    oAlmacenamiento.LiberarServicios;
    FreeAndNil(oConsulta);
    FreeAndNil(oRutas);
    FreeAndNil(oAlmacenamiento);
    oParametros := nil;
  end;
  if not bPrincipal then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El artículo "%s" no tiene una foto general real.',
      [AArticulo.Codigo]);
end;

procedure ComprobarTexto(const AValor, ANombre: string;
  ALongitudMaxima: Integer);
begin
  if Trim(AValor) = '' then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      '%s no puede estar vacío.', [ANombre]);
  if Length(AValor) > ALongitudMaxima then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      '%s supera los %d caracteres permitidos.',
      [ANombre, ALongitudMaxima]);
end;

procedure ComprobarDecimal(AValor: Double; const ANombre: string;
  APermiteNegativo: Boolean);
begin
  if IsNan(AValor) or IsInfinite(AValor) then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      '%s no puede ser infinito ni NaN.', [ANombre]);
  if (not APermiteNegativo) and (AValor < 0) then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      '%s no puede ser negativo.', [ANombre]);
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarTextosArticulo(
  const AArticulo: TArticuloCompletoAltaPresta);
begin
  ComprobarTexto(AArticulo.Codigo, 'Referencia del producto',
    CLongitudReferenciaPresta);
  ComprobarTexto(AArticulo.Nombre, 'Nombre del producto',
    CLongitudNombrePresta);
  ComprobarTexto(AArticulo.Enlace, 'Enlace del producto',
    CLongitudEnlacePresta);
  if Length(AArticulo.DescripcionCorta) >
     CLongitudDescripcionCortaPresta then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'La descripción corta supera los %d caracteres permitidos.',
      [CLongitudDescripcionCortaPresta]);
  if Length(AArticulo.Descripcion) > CLongitudDescripcionPresta then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'La descripción supera los %d caracteres permitidos.',
      [CLongitudDescripcionPresta]);
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarFamilias(
  const AArticulo: TArticuloCompletoAltaPresta);
var
  iFamilia: Integer;
  oCodigosFamilia: TDictionary<string, Boolean>;
  sClave: string;
begin
  if Length(AArticulo.Familias) = 0 then
    raise EAltaArticuloPrestaLocal.Create(
      'El producto debe tener al menos una familia local.');
  oCodigosFamilia := TDictionary<string, Boolean>.Create;
  try
    for iFamilia := 0 to High(AArticulo.Familias) do
    begin
      ComprobarTexto(AArticulo.Familias[iFamilia].Codigo,
        'Código de familia', CLongitudReferenciaPresta);
      ComprobarTexto(AArticulo.Familias[iFamilia].Nombre,
        'Nombre de familia', CLongitudNombrePresta);
      ComprobarTexto(AArticulo.Familias[iFamilia].Enlace,
        'Enlace de familia', CLongitudEnlacePresta);
      sClave := UpperCase(AArticulo.Familias[iFamilia].Codigo);
      if oCodigosFamilia.ContainsKey(sClave) then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La familia "%s" está duplicada.',
          [AArticulo.Familias[iFamilia].Codigo]);
      oCodigosFamilia.Add(sClave, True);
      if iFamilia = 0 then
      begin
        if AArticulo.Familias[iFamilia].CodigoPadre <> '' then
          raise EAltaArticuloPrestaLocal.Create(
            'La primera familia de la ruta no es una raíz local.');
      end
      else if not SameText(
                    AArticulo.Familias[iFamilia].CodigoPadre,
                    AArticulo.Familias[iFamilia - 1].Codigo) then
        raise EAltaArticuloPrestaLocal.Create(
          'La ruta jerárquica de familias no es continua.');
    end;
  finally
    FreeAndNil(oCodigosFamilia);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarAtributo(
  const AAtributo: TAtributoAltaArticuloPresta;
  const AClavesGrupo, AClavesAtributo:
    TDictionary<string, string>);
var
  sClave: string;
  sFirma: string;
begin
  ComprobarTexto(AAtributo.CodigoGrupo,
    'Código de grupo', CLongitudNombrePresta);
  ComprobarTexto(AAtributo.NombreGrupo,
    'Nombre de grupo', CLongitudNombrePresta);
  ComprobarTexto(AAtributo.NombrePublicoGrupo,
    'Nombre público de grupo', CLongitudNombrePublicoPresta);
  ComprobarTexto(AAtributo.CodigoValor,
    'Código de valor', CLongitudNombrePresta);
  ComprobarTexto(AAtributo.NombreValor,
    'Nombre de valor', CLongitudNombrePresta);
  if (AAtributo.TipoGrupo <> 'select') and
     (AAtributo.TipoGrupo <> 'radio') and
     (AAtributo.TipoGrupo <> 'color') then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El grupo "%s" tiene un tipo no válido.',
      [AAtributo.CodigoGrupo]);
  sClave := UpperCase(AAtributo.CodigoGrupo);
  sFirma := AAtributo.NombreGrupo + #1 +
    AAtributo.NombrePublicoGrupo + #1 + AAtributo.TipoGrupo;
  if AClavesGrupo.ContainsKey(sClave) then
  begin
    if AClavesGrupo[sClave] <> sFirma then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El grupo de atributo "%s" tiene datos contradictorios.',
        [AAtributo.CodigoGrupo]);
  end
  else
    AClavesGrupo.Add(sClave, sFirma);
  sClave := sClave + #1 + UpperCase(AAtributo.CodigoValor);
  sFirma := AAtributo.NombreValor + #1 + AAtributo.ColorHtml;
  if AClavesAtributo.ContainsKey(sClave) then
  begin
    if AClavesAtributo[sClave] <> sFirma then
      raise EAltaArticuloPrestaLocal.CreateFmt(
        'El valor de atributo "%s" tiene datos contradictorios.',
        [AAtributo.CodigoValor]);
  end
  else
    AClavesAtributo.Add(sClave, sFirma);
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarSku(
  const ASku: TSkuAltaArticuloPresta;
  const ACodigosSku: TDictionary<string, Boolean>;
  const AClavesGrupo, AClavesAtributo:
    TDictionary<string, string>);
var
  iAtributo: Integer;
  sClave: string;
begin
  ComprobarTexto(ASku.Codigo,
    'Referencia de combinación', CLongitudReferenciaPresta);
  ComprobarDecimal(ASku.PrecioSinIva,
    'Precio de combinación sin IVA', False);
  ComprobarDecimal(ASku.ImpactoPrecio,
    'Impacto de precio', True);
  if ASku.Cantidad < 0 then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El stock del SKU "%s" no puede ser negativo.',
      [ASku.Codigo]);
  sClave := UpperCase(ASku.Codigo);
  if ACodigosSku.ContainsKey(sClave) then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El SKU "%s" está duplicado.', [ASku.Codigo]);
  ACodigosSku.Add(sClave, True);
  if Length(ASku.Atributos) = 0 then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El SKU "%s" no tiene atributos.', [ASku.Codigo]);
  for iAtributo := 0 to High(ASku.Atributos) do
    ValidarAtributo(
      ASku.Atributos[iAtributo],
      AClavesGrupo,
      AClavesAtributo);
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarSkus(
  const AArticulo: TArticuloCompletoAltaPresta);
var
  iSku: Integer;
  oClavesAtributo: TDictionary<string, string>;
  oClavesGrupo: TDictionary<string, string>;
  oCodigosSku: TDictionary<string, Boolean>;
begin
  if AArticulo.TieneVariaciones and
     (Length(AArticulo.Skus) = 0) then
    raise EAltaArticuloPrestaLocal.Create(
      'El producto variable debe tener combinaciones activas.');
  if (not AArticulo.TieneVariaciones) and
     (Length(AArticulo.Skus) <> 0) then
    raise EAltaArticuloPrestaLocal.Create(
      'El producto simple no debe crear combinaciones.');
  oCodigosSku := TDictionary<string, Boolean>.Create;
  oClavesGrupo := TDictionary<string, string>.Create;
  oClavesAtributo := TDictionary<string, string>.Create;
  try
    for iSku := 0 to High(AArticulo.Skus) do
    begin
      ValidarSku(
        AArticulo.Skus[iSku],
        oCodigosSku,
        oClavesGrupo,
        oClavesAtributo);
    end;
  finally
    FreeAndNil(oClavesAtributo);
    FreeAndNil(oClavesGrupo);
    FreeAndNil(oCodigosSku);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarFotos(
  const AArticulo: TArticuloCompletoAltaPresta);
var
  iFoto: Integer;
begin
  if Length(AArticulo.Fotos) = 0 then
    raise EAltaArticuloPrestaLocal.Create(
      'El producto debe tener una foto general real.');
  for iFoto := 0 to High(AArticulo.Fotos) do
  begin
    ComprobarTexto(AArticulo.Fotos[iFoto].Nombre,
      'Nombre de foto', 255);
    ComprobarTexto(AArticulo.Fotos[iFoto].RutaReal,
      'Ruta real de foto', 32767);
  end;
end;

procedure TRepositorioAltaArticuloPrestaUniDAC.ValidarArticulo(
  const AArticulo: TArticuloCompletoAltaPresta);
begin
  ValidarTextosArticulo(AArticulo);
  if (AArticulo.TipoIva <> 'N') and (AArticulo.TipoIva <> 'R') and
     (AArticulo.TipoIva <> 'S') and (AArticulo.TipoIva <> 'E') then
    raise EAltaArticuloPrestaLocal.CreateFmt(
      'El tipo de IVA "%s" no se puede publicar.', [AArticulo.TipoIva]);
  ComprobarDecimal(AArticulo.PorcentajeIva,
    'Porcentaje de IVA', False);
  ComprobarDecimal(AArticulo.PrecioBaseSinIva,
    'Precio base sin IVA', False);
  if AArticulo.Cantidad < 0 then
    raise EAltaArticuloPrestaLocal.Create(
      'La cantidad total no puede ser negativa.');
  ValidarFamilias(AArticulo);
  ValidarSkus(AArticulo);
  ValidarFotos(AArticulo);
end;

function TRepositorioAltaArticuloPrestaUniDAC.CargarValidado(
  const ACodigoArticulo, AUsuario, AGrupo: string;
  const AConfiguracion: TConfiguracionAltaArticuloPresta):
  TArticuloCompletoAltaPresta;
var
  bImpuestoIncluido: Boolean;
  oConsulta: TUniQuery;
  sCodigoFamilia: string;
  sCodigoVariacion: string;
begin
  Result := Default(TArticuloCompletoAltaPresta);
  if Trim(ACodigoArticulo) = '' then
    raise EAltaArticuloPrestaLocal.Create(
      'El código de artículo no puede estar vacío.');
  if Trim(AUsuario) = '' then
    raise EAltaArticuloPrestaLocal.Create(
      'El usuario del perfil no puede estar vacío.');
  if Trim(AConfiguracion.CodigoEmpresa) = '' then
    raise EAltaArticuloPrestaLocal.Create(
      'La empresa web no puede estar vacía.');
  if Trim(AConfiguracion.CodigoTarifa) = '' then
    raise EAltaArticuloPrestaLocal.Create(
      'La tarifa web no puede estar vacía.');
  CargarArticulo(Trim(ACodigoArticulo), Result,
    sCodigoFamilia, sCodigoVariacion);
  CargarPrecio(AConfiguracion, Result, bImpuestoIncluido);
  CargarFamilias(sCodigoFamilia, Result);
  if AConfiguracion.StockActivo and (not Result.EsServicio) then
  begin
    oConsulta := NuevaConsulta;
    try
      oConsulta.SQL.Text := SQL_NUMERO_ALMACENES_WEB;
      oConsulta.ParamByName('EMPRESA').AsString :=
        AConfiguracion.CodigoEmpresa;
      oConsulta.Open;
      if oConsulta.FieldByName('NUMERO').AsInteger = 0 then
        raise EAltaArticuloPrestaLocal.CreateFmt(
          'La empresa "%s" no tiene almacenes web activos, ' +
          'físicos y estándar.', [AConfiguracion.CodigoEmpresa]);
    finally
      FreeAndNil(oConsulta);
    end;
  end;
  CargarSkus(sCodigoVariacion, AConfiguracion,
    bImpuestoIncluido, Result);
  CargarFotos(AUsuario, AGrupo, Result);
  ValidarArticulo(Result);
end;

function CrearRepositorioAltaArticuloPrestaUniDAC(
  AConexion: TUniConnection): IRepositorioAltaArticuloPresta;
begin
  Result := TRepositorioAltaArticuloPrestaUniDAC.Create(AConexion);
end;

end.
