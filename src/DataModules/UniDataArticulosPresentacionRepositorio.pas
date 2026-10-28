{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataArticulosPresentacionRepositorio                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Unica unidad con SQL y transacciones de la pantalla de articulos.         }
{    Implementa los puertos de inLibArticulosPresentacionIntf.                 }
{******************************************************************************}
unit UniDataArticulosPresentacionRepositorio;

interface

uses
  Uni,
  inLibPerfilesUsuarioIntf,
  inLibArticulosPresentacionIntf;

function CrearCatalogoAltaTarifasArticuloUniDAC(
  AConexion: TUniConnection): ICatalogoAltaTarifasArticulo;
function CrearLecturaCodigosBarrasArticuloUniDAC(
  AConexion: TUniConnection): ILecturaCodigosBarrasArticulo;
function CrearListaArticulosPantallaUniDAC(
  AConsulta: TUniQuery): IListaArticulosPantalla;
function CrearEscrituraPrecargaArticulosUniDAC(
  AConexion: TUniConnection;
  const AEscritura: IEscritorPerfilesUsuario): IEscrituraPrecargaArticulos;

implementation

uses
  System.SysUtils, System.Classes,
  inLibArticulosFiltro, inLibFiltroUsuario;

const
  SQL_LISTAR_SKUS_ARTICULO =
    'SELECT DISTINCT sku.CODIGO_UNIDAD_SKU AS CODIGO_SKU, ' +
    '       color.AV AS COLOR, ' +
    '       COALESCE(atb.HEX_ATB, '''') AS HEX_COLOR, ' +
    '       COALESCE(talla.AV, '''') AS TALLA, ' +
    '       color.ORDEN_AV AS ORDEN_COLOR, ' +
    '       COALESCE(talla.ORDEN_AV, 0) AS ORDEN_TALLA ' +
    '  FROM fza_articulos_skus sku ' +
    '  LEFT JOIN (fza_atributos_sku sku_color ' +
    '  JOIN fza_atributos_valores color ' +
    '    ON color.ID_AV = sku_color.ID_AV_SA ' +
    '   AND color.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 WHERE ' +
    'SK452.CODIGO_UNIDAD_SKU = sku_color.CODIGO_UNIDAD_SKU_SA) ' +
    'AND EJ452.EJE_VA = ''F'')) ' +
    '    ON sku_color.CODIGO_UNIDAD_SKU_SA = sku.CODIGO_UNIDAD_SKU ' +
    '  LEFT JOIN fza_articulos_atributos_basicos aab ' +
    '    ON aab.CODIGO_ART_AAB = sku.CODIGO_ART_SKU ' +
    '   AND aab.ID_AV_AAB = color.ID_AV ' +
    '  LEFT JOIN fza_atributos_basicos atb ' +
    '    ON atb.ID_ATB = COALESCE(aab.ID_ATB_AAB, color.ID_ATB_AV) ' +
    '  LEFT JOIN (fza_atributos_sku sku_talla ' +
    '  JOIN fza_atributos_valores talla ' +
    '    ON talla.ID_AV = sku_talla.ID_AV_SA ' +
    '   AND talla.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 WHERE ' +
    'SK452.CODIGO_UNIDAD_SKU = sku_talla.CODIGO_UNIDAD_SKU_SA) ' +
    'AND EJ452.EJE_VA = ''P'')) ' +
    '    ON sku_talla.CODIGO_UNIDAD_SKU_SA = sku.CODIGO_UNIDAD_SKU ' +
    ' WHERE sku.CODIGO_ART_SKU = :ART ' +
    ' ORDER BY ORDEN_COLOR, COLOR, ORDEN_TALLA, TALLA, CODIGO_SKU';
  SQL_LISTAR_TALLAS_COLECCION =
    'SELECT AV.AV AS TALLA ' +
    '  FROM fza_articulos_conjuntos_asign ACA ' +
    '  JOIN fza_atributos_conjuntos_det ACD ' +
    '    ON ACD.ID_AC_ACD = ACA.ID_AC_ACA ' +
    '  JOIN fza_atributos_valores AV ' +
    '    ON AV.ID_AV = ACD.ID_AV_ACD ' +
    ' WHERE ACA.CODIGO_ART_ACA = :ART ' +
    '   AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
    'AR452.CODIGO_ART_ART = :ART) AND EJ452.EJE_VA = ''P'') ' +
    '   AND COALESCE(AV.ESACTIVO_AV, ''S'') = ''S'' ' +
    ' ORDER BY ACD.ORDEN_ACD, AV.ORDEN_AV, AV.AV';
  SQL_LISTAR_TARIFAS_ACTIVAS =
    '  SELECT CODIGO_TAR_ARTTAR ' +
    '    FROM fza_tarifas ' +
    '   WHERE ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY ORDEN_TAR';
  SQL_LISTAR_CODIGOS_BARRAS =
    'SELECT cb.CODIGO_BARRAS_CB, cb.CODIGO_UNIDAD_CB, cb.TIPO_CODIGO_CB ' +
    '  FROM fza_codigos_barras cb '                                       +
    '  JOIN fza_articulos_skus sku '                                      +
    '    ON sku.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB '                 +
    ' WHERE sku.CODIGO_ART_SKU = :CODIGO_ART_ART';

type
  TCatalogoAltaTarifasArticuloUniDAC = class(
    TInterfacedObject,
    ICatalogoAltaTarifasArticulo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarSkus(
      const ACodigoArticulo: string): TDetallesSkuTarifaArticulo;
    function ListarTallasColeccion(
      const ACodigoArticulo: string): TArray<string>;
    function ListarTarifasActivas: TArray<string>;
  end;

  TLecturaCodigosBarrasArticuloUniDAC = class(
    TInterfacedObject,
    ILecturaCodigosBarrasArticulo)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ListarCodigosBarras(
      const ACodigoArticulo: string): TCodigosBarrasArticulo;
  end;

  TListaArticulosPantallaUniDAC = class(
    TInterfacedObject,
    IListaArticulosPantalla)
  private
    FConsulta: TUniQuery;
    FSqlBase: string;
  public
    constructor Create(AConsulta: TUniQuery);
    procedure AplicarFiltro(const AFiltro: TFiltroArticulos);
  end;

  TEscrituraPrecargaArticulosUniDAC = class(
    TInterfacedObject,
    IEscrituraPrecargaArticulos)
  private
    FConexion: TUniConnection;
    FEscritura: IEscritorPerfilesUsuario;
  public
    constructor Create(
      AConexion: TUniConnection;
      const AEscritura: IEscritorPerfilesUsuario);
    procedure GrabarPerfiles(const APerfiles: TPerfilList);
  end;

constructor TCatalogoAltaTarifasArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TCatalogoAltaTarifasArticuloUniDAC.ListarSkus(
  const ACodigoArticulo: string): TDetallesSkuTarifaArticulo;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_SKUS_ARTICULO;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila].CodigoSku :=
        oConsulta.FieldByName('CODIGO_SKU').AsString;
      Result[iFila].Color :=
        oConsulta.FieldByName('COLOR').AsString;
      Result[iFila].HexColor :=
        oConsulta.FieldByName('HEX_COLOR').AsString;
      Result[iFila].Talla :=
        oConsulta.FieldByName('TALLA').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCatalogoAltaTarifasArticuloUniDAC.ListarTallasColeccion(
  const ACodigoArticulo: string): TArray<string>;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_TALLAS_COLECCION;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila] := oConsulta.FieldByName('TALLA').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCatalogoAltaTarifasArticuloUniDAC.ListarTarifasActivas:
  TArray<string>;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_TARIFAS_ACTIVAS;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila] := oConsulta.FieldByName('CODIGO_TAR_ARTTAR').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TLecturaCodigosBarrasArticuloUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TLecturaCodigosBarrasArticuloUniDAC.ListarCodigosBarras(
  const ACodigoArticulo: string): TCodigosBarrasArticulo;
var
  iFila: Integer;
  oConsulta: TUniQuery;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text := SQL_LISTAR_CODIGOS_BARRAS;
    oConsulta.ParamByName('CODIGO_ART_ART').AsString := ACodigoArticulo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iFila := Length(Result);
      SetLength(Result, iFila + 1);
      Result[iFila].Codigo :=
        oConsulta.FieldByName('CODIGO_BARRAS_CB').AsString;
      Result[iFila].Sku :=
        oConsulta.FieldByName('CODIGO_UNIDAD_CB').AsString;
      Result[iFila].Tipo :=
        oConsulta.FieldByName('TIPO_CODIGO_CB').AsString;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TListaArticulosPantallaUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

procedure TListaArticulosPantallaUniDAC.AplicarFiltro(
  const AFiltro: TFiltroArticulos);
var
  aFamilias, aProveedores, aTemporadas: TArray<string>;
  oSql: TStringBuilder;
  procedure AgregarLista(AConstructor: TStringBuilder;
    const ACampo, APrefijo: string; const AValores: TArray<string>);
  var
    iIndice: Integer;
  begin
    if Length(AValores) > 0 then
    begin
      AConstructor.Append('  AND ' + ACampo + ' IN (');
      for iIndice := 0 to High(AValores) do
      begin
        if iIndice > 0 then
          AConstructor.Append(', ');
        AConstructor.Append(':' + APrefijo + IntToStr(iIndice));
      end;
      AConstructor.AppendLine(')');
    end;
  end;
  procedure AplicarParametros(const APrefijo: string;
    const AValores: TArray<string>);
  var
    iIndice: Integer;
  begin
    for iIndice := 0 to High(AValores) do
      FConsulta.ParamByName(APrefijo + IntToStr(iIndice)).AsString :=
        AValores[iIndice];
  end;
begin
  if FConsulta <> nil then
  begin
    aTemporadas := SepararValoresFiltroArticulos(
      AFiltro.TemporadasCsv);
    aProveedores := SepararValoresFiltroArticulos(
      AFiltro.ProveedoresCsv);
    aFamilias := SepararValoresFiltroArticulos(AFiltro.FamiliasCsv);
    // La consulta base es la que tenía la lista la primera vez: la del
    // perfil si oGetSQLFromDB la cargó, o la del diseño. Los filtros se
    // inyectan en ella en vez de sustituirla por SELECT * FROM vi_articulos,
    // que descartaba las columnas de la consulta del perfil. Debe exponer
    // vi_articulos con ese nombre.
    if FSqlBase = '' then
      FSqlBase := Trim(FConsulta.SQL.Text);
    if FSqlBase = '' then
      FSqlBase := 'SELECT * FROM vi_articulos';
    oSql := TStringBuilder.Create;
    try
      case AFiltro.Estado of
        efaActivos:
          oSql.AppendLine(
            '  AND vi_articulos.ESACTIVO_ART = ''S''');
        efaInactivos:
          oSql.AppendLine(
            '  AND vi_articulos.ESACTIVO_ART = ''N''');
      end;
      if AFiltro.SoloConStock then
        oSql.AppendLine(
          '  AND EXISTS (SELECT 1 FROM fza_articulos_skus sk ' +
          ' JOIN fza_articulos_stockactual stk ' +
          '   ON stk.CODIGO_UNIDAD_STK = sk.CODIGO_UNIDAD_SKU ' +
          ' WHERE sk.CODIGO_ART_SKU = ' +
          'vi_articulos.CODIGO_ART_ART ' +
          '   AND stk.CANTIDAD_STK > 0)');
      AgregarLista(oSql, 'vi_articulos.TEMPORADA_ART',
        'TEMP', aTemporadas);
      AgregarLista(oSql, 'vi_articulos.CODIGO_PRV_AP',
        'PRV', aProveedores);
      AgregarLista(oSql, 'vi_articulos.CODIGO_FAM_ART',
        'FAM', aFamilias);
      FConsulta.Close;
      FConsulta.SQL.Text := InyectarFiltroSql(FSqlBase, ' ' + oSql.ToString);
      if Pos('ORDER BY', UpperCase(FSqlBase)) = 0 then
        FConsulta.SQL.Add('ORDER BY vi_articulos.ORDEN_ART');
      AplicarParametros('TEMP', aTemporadas);
      AplicarParametros('PRV', aProveedores);
      AplicarParametros('FAM', aFamilias);
    finally
      oSql.Free;
    end;
  end;
end;

constructor TEscrituraPrecargaArticulosUniDAC.Create(
  AConexion: TUniConnection;
  const AEscritura: IEscritorPerfilesUsuario);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  // AEscritura puede llegar sin resolver si el propietario no publica los
  // servicios de perfiles; el fallo se manifiesta al grabar, como antes.
  FConexion := AConexion;
  FEscritura := AEscritura;
end;

procedure TEscrituraPrecargaArticulosUniDAC.GrabarPerfiles(
  const APerfiles: TPerfilList);
begin
  // Unidad de trabajo de la precarga: el upsert de todos los filtros
  // entra o no entra completo.
  FConexion.StartTransaction;
  try
    FEscritura.GrabarPerfiles(APerfiles);
    FConexion.Commit;
  except
    FConexion.Rollback;
    raise;
  end;
end;

function CrearCatalogoAltaTarifasArticuloUniDAC(
  AConexion: TUniConnection): ICatalogoAltaTarifasArticulo;
begin
  Result := TCatalogoAltaTarifasArticuloUniDAC.Create(AConexion);
end;

function CrearLecturaCodigosBarrasArticuloUniDAC(
  AConexion: TUniConnection): ILecturaCodigosBarrasArticulo;
begin
  Result := TLecturaCodigosBarrasArticuloUniDAC.Create(AConexion);
end;

function CrearListaArticulosPantallaUniDAC(
  AConsulta: TUniQuery): IListaArticulosPantalla;
begin
  Result := TListaArticulosPantallaUniDAC.Create(AConsulta);
end;

function CrearEscrituraPrecargaArticulosUniDAC(
  AConexion: TUniConnection;
  const AEscritura: IEscritorPerfilesUsuario): IEscrituraPrecargaArticulos;
begin
  Result := TEscrituraPrecargaArticulosUniDAC.Create(AConexion, AEscritura);
end;

end.
