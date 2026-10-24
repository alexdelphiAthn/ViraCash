{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidoOcr                                              }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       08/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Catálogo UniDAC para resolver el primer sistema activo que contiene       }
{    todas las tallas y recuperar colores básicos del histórico del proveedor. }
{******************************************************************************}
unit UniDataPedidoOcr;

interface

uses
  System.Generics.Collections,
  Uni,
  inLibPedidoOcr,
  inLibComprasSesionesIntf;

type
  TValorTallaPedidoOcr = record
    IdAv: Integer;
    Valor: string;
  end;
  TValoresTallaPedidoOcr = TArray<TValorTallaPedidoOcr>;
  TResolucionTallasPedidoOcr = record
    Encontrada: Boolean;
    IdAc: Integer;
    NombreSistema: string;
    IdsAv: TArray<Integer>;
  end;
  TSistemaTallasPedidoOcr = class
  public
    IdAc: Integer;
    Nombre: string;
    Valores: TValoresTallaPedidoOcr;
  end;
  TCatalogoTallasPedidoOcr = class
  private
    FSistemas: TObjectList<TSistemaTallasPedidoOcr>;
    FMaximoPosiciones: Integer;
    procedure Cargar(AConexion: TUniConnection);
    function BuscarValor(ASistema: TSistemaTallasPedidoOcr;
      const ATalla: string): Integer;
  public
    constructor Create(AConexion: TUniConnection;
      AMaximoPosiciones: Integer);
    destructor Destroy; override;
    function Resolver(
      const ATallas: TTallasPedidoOcr): TResolucionTallasPedidoOcr;
  end;
  TCatalogoArticulosPedidoOcr = class
  private
    FArticulos: TDictionary<string, TResolverDuplicadoSesion>;
    procedure Cargar(AConexion: TUniConnection;
      const ACodigoProveedor, ACodigoTarifa: string;
      const ALineas: TLineasPedidoOcr);
  public
    constructor Create(AConexion: TUniConnection;
      const ACodigoProveedor, ACodigoTarifa: string;
      const ALineas: TLineasPedidoOcr);
    destructor Destroy; override;
    function Resolver(const AModelo: string): TResolverDuplicadoSesion;
  end;
  TCatalogoColoresPedidoOcr = class
  private
    FColores: TDictionary<string, string>;
    procedure Cargar(AConexion: TUniConnection;
      const ACodigoProveedor: string;
      const ALineas: TLineasPedidoOcr);
  public
    constructor Create(AConexion: TUniConnection;
      const ACodigoProveedor: string;
      const ALineas: TLineasPedidoOcr);
    destructor Destroy; override;
    function Resolver(const AColorProveedor: string;
      out ACodigoColorBasico: string): Boolean;
  end;
  TCeldaPedidoOcr = record
    Linea: Integer;
    IdAv: Integer;
    Cantidad: Double;
  end;
  TCeldasPedidoOcr = TArray<TCeldaPedidoOcr>;
  TPersistenciaPedidoOcr = class
  public
    class procedure GuardarCeldas(AConexion: TUniConnection;
      const ASerie, ANumero, AUsuario: string;
      const ACeldas: TCeldasPedidoOcr); static;
    class function ReservarLineas(AConexion: TUniConnection;
      const ASerie, ANumero: string;
      ACantidad: Integer): Integer; static;
  end;
  // Reutiliza primero la última clasificación de una sesión y después la
  // clasificación más repetida entre los artículos del proveedor.
  THistoricoColoresPedidoOcr = class
  private
    class function ConsultarCodigo(
      AConexion: TUniConnection;
      const ASql, ACodigoProveedor,
      AColorProveedor: string): string; static;
  public
    class function Resolver(
      AConexion: TUniConnection;
      const ACodigoProveedor,
      AColorProveedor: string;
      out ACodigoColorBasico: string): Boolean; static;
  end;

implementation

uses
  Data.DB,
  System.SysUtils,
  System.Classes,
  inLibComprasSesionesReglas;

const
  SQL_COLOR_HISTORICO_SESIONES =
    'SELECT L.CODIGO_ATB_COLOR_SESLIN AS CODIGO_COLOR' +
    '  FROM fza_compras_sesiones_lineas L' +
    '  JOIN fza_compras_sesiones S' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN' +
    '  JOIN fza_atributos_basicos B' +
    '    ON B.ID_VA_ATB = ''CO''' +
    '   AND B.CODIGO_ATB = L.CODIGO_ATB_COLOR_SESLIN' +
    '   AND B.ESACTIVO_ATB = ''S''' +
    ' WHERE S.CODIGO_PRV_SES = :proveedor' +
    '   AND UPPER(TRIM(L.COLOR_TEXTO_SESLIN)) = :color' +
    ' ORDER BY COALESCE(S.INSTANTE_MODIF, S.INSTANTE_ALTA) DESC,' +
    '          S.FECHA_SES DESC, L.LINEA_SESLIN DESC' +
    ' LIMIT 1';
  SQL_COLOR_HISTORICO_ARTICULOS =
    'SELECT B.CODIGO_ATB AS CODIGO_COLOR' +
    '  FROM fza_articulos_proveedores AP' +
    '  JOIN fza_articulos_skus SKU' +
    '    ON SKU.CODIGO_ART_SKU = AP.CODIGO_ART_AP' +
    '  JOIN fza_atributos_sku SA' +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU' +
    '  JOIN fza_atributos_valores AV' +
    '    ON AV.ID_AV = SA.ID_AV_SA' +
    '   AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'')' +
    '  JOIN fza_articulos_atributos_basicos AAB' +
    '    ON AAB.CODIGO_ART_AAB = SKU.CODIGO_ART_SKU' +
    '   AND AAB.ID_AV_AAB = AV.ID_AV' +
    '  JOIN fza_atributos_basicos B' +
    '    ON B.ID_ATB = AAB.ID_ATB_AAB' +
    '   AND B.ID_VA_ATB = ''CO''' +
    '   AND B.ESACTIVO_ATB = ''S''' +
    ' WHERE AP.CODIGO_PRV_AP = :proveedor' +
    '   AND UPPER(TRIM(AV.AV)) = :color' +
    ' GROUP BY B.CODIGO_ATB' +
    ' ORDER BY COUNT(DISTINCT AP.CODIGO_ART_AP) DESC,' +
    '          B.CODIGO_ATB' +
    ' LIMIT 1';

function ClaveModeloPedidoOcr(const AModelo: string): string;
begin
  Result := UpperCase(Trim(AModelo));
end;

function ClaveColorPedidoOcr(const AColor: string): string;
begin
  Result := UpperCase(SanearColorSku(AColor));
end;

procedure PrepararListaClaves(const ALineas: TLineasPedidoOcr;
  AModelos: Boolean; AClaves: TStringList);
var
  iLinea: Integer;
  sClave: string;
begin
  AClaves.Sorted := True;
  AClaves.Duplicates := dupIgnore;
  AClaves.CaseSensitive := False;
  for iLinea := 0 to High(ALineas) do
  begin
    if AModelos then
      sClave := ClaveModeloPedidoOcr(ALineas[iLinea].Modelo)
    else
      sClave := ClaveColorPedidoOcr(ALineas[iLinea].Color);
    if sClave <> '' then
      AClaves.Add(sClave);
  end;
end;

function ListaParametros(const APrefijo: string;
  ACantidad: Integer): string;
var
  iParametro: Integer;
begin
  Result := '';
  for iParametro := 0 to ACantidad - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + ':' + APrefijo + IntToStr(iParametro);
  end;
end;

constructor TCatalogoArticulosPedidoOcr.Create(
  AConexion: TUniConnection;
  const ACodigoProveedor, ACodigoTarifa: string;
  const ALineas: TLineasPedidoOcr);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FArticulos :=
    TDictionary<string, TResolverDuplicadoSesion>.Create;
  Cargar(
    AConexion,
    ACodigoProveedor,
    ACodigoTarifa,
    ALineas);
end;

destructor TCatalogoArticulosPedidoOcr.Destroy;
begin
  FArticulos.Free;
  inherited Destroy;
end;

procedure TCatalogoArticulosPedidoOcr.Cargar(
  AConexion: TUniConnection;
  const ACodigoProveedor, ACodigoTarifa: string;
  const ALineas: TLineasPedidoOcr);
var
  iClave: Integer;
  oArticulo: TResolverDuplicadoSesion;
  oClaves: TStringList;
  oConsulta: TUniQuery;
  sClave: string;
  sParametros: string;
begin
  oClaves := TStringList.Create;
  try
    PrepararListaClaves(ALineas, True, oClaves);
    if oClaves.Count > 0 then
    begin
      sParametros := ListaParametros('modelo', oClaves.Count);
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'SELECT UPPER(TRIM(AP.REF_PROVEEDOR_AP)) AS CLAVE_MODELO, ' +
          '       A.CODIGO_ART_ART, A.DESCRIPCION_ART, ' +
          '       A.CODIGO_FAM_ART, F.NOMBRE_FAM_FAM, ' +
          '       A.TIPO_ART, A.TIPO_IVA_ART, A.TIPO_CANTIDAD_ART, ' +
          '       A.ESVARIACION_ART, A.ESTRAZABLE_ART, ' +
          '       A.TIPO_VARIACION_ART, ' +
          '       AP.PRECIO_ULT_COMPRA_AP AS PRECIO_ULT_COMPRA, ' +
          '       AP.REF_PROVEEDOR_AP AS REF_PROVEEDOR, ' +
          '       (SELECT ACA.ID_AC_ACA ' +
          '          FROM fza_articulos_conjuntos_asign ACA ' +
          '         WHERE ACA.CODIGO_ART_ACA = A.CODIGO_ART_ART ' +
          '           AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
          'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
          'A.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'') ' +
          '         ORDER BY ACA.ID_VA_ACA LIMIT 1) AS ID_AC_PIVOT, ' +
          '       (SELECT ACA.ID_VA_ACA ' +
          '          FROM fza_articulos_conjuntos_asign ACA ' +
          '         WHERE ACA.CODIGO_ART_ACA = A.CODIGO_ART_ART ' +
          '           AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
          'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
          'A.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''P'') ' +
          '         ORDER BY ACA.ID_VA_ACA LIMIT 1) AS ID_VA_PIVOT, ' +
          '       (SELECT ACA.ID_AC_ACA ' +
          '          FROM fza_articulos_conjuntos_asign ACA ' +
          '         WHERE ACA.CODIGO_ART_ACA = A.CODIGO_ART_ART ' +
          '           AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
          'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
          'A.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''F'') ' +
          '         LIMIT 1) AS ID_AC_FILA, ' +
          '       (SELECT ACA.ID_VA_ACA ' +
          '          FROM fza_articulos_conjuntos_asign ACA ' +
          '         WHERE ACA.CODIGO_ART_ACA = A.CODIGO_ART_ART ' +
          '           AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
          'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
          'A.TIPO_VARIACION_ART AND EJ452.EJE_VA = ''F'') ' +
          '         LIMIT 1) AS ID_VA_FILA, ' +
          '       COALESCE((SELECT T.PRECIO_FINAL_ARTTAR ' +
          '          FROM fza_articulos_tarifas T ' +
          '         WHERE T.CODIGO_ART_ARTTAR = A.CODIGO_ART_ART ' +
          '           AND T.CODIGO_UNIDAD_ARTTAR = '''' ' +
          '           AND (T.ESACTIVO_ARTTAR = ''S'' ' +
          '                OR T.CODIGO_TAR_ARTTAR = :tarifa) ' +
          '         ORDER BY (T.CODIGO_TAR_ARTTAR = :tarifa) DESC, ' +
          '                  T.ESACTIVO_ARTTAR DESC, ' +
          '                  T.FECHA_DESDE_ARTTAR DESC, ' +
          '                  T.CODIGO_UNICO_ARTTAR DESC ' +
          '         LIMIT 1), 0) AS PRECIO_VENTA ' +
          '  FROM fza_articulos_proveedores AP ' +
          '  JOIN fza_articulos A ' +
          '    ON A.CODIGO_ART_ART = AP.CODIGO_ART_AP ' +
          '   AND A.ESACTIVO_ART = ''S'' ' +
          '  LEFT JOIN fza_articulos_familias F ' +
          '    ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART ' +
          ' WHERE AP.CODIGO_PRV_AP = :proveedor ' +
          '   AND UPPER(TRIM(AP.REF_PROVEEDOR_AP)) IN (' +
          sParametros + ') ' +
          ' ORDER BY CLAVE_MODELO, ' +
          '          AP.ESPROVEEDORPRINCIPAL_AP DESC, ' +
          '          A.CODIGO_ART_ART';
        oConsulta.ParamByName('proveedor').AsString :=
          ACodigoProveedor;
        oConsulta.ParamByName('tarifa').AsString := ACodigoTarifa;
        for iClave := 0 to oClaves.Count - 1 do
          oConsulta.ParamByName('modelo' + IntToStr(iClave)).AsString :=
            oClaves[iClave];
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          sClave := oConsulta.FieldByName('CLAVE_MODELO').AsString;
          if not FArticulos.ContainsKey(sClave) then
          begin
            oArticulo := Default(TResolverDuplicadoSesion);
            oArticulo.Encontrado := True;
            oArticulo.Origen := 'REF';
            oArticulo.CodigoArt :=
              oConsulta.FieldByName('CODIGO_ART_ART').AsString;
            oArticulo.DescripcionArt :=
              oConsulta.FieldByName('DESCRIPCION_ART').AsString;
            oArticulo.CodigoFam :=
              oConsulta.FieldByName('CODIGO_FAM_ART').AsString;
            oArticulo.NombreFam :=
              oConsulta.FieldByName('NOMBRE_FAM_FAM').AsString;
            oArticulo.IdAcPivot :=
              oConsulta.FieldByName('ID_AC_PIVOT').AsInteger;
            oArticulo.IdVaPivot :=
              oConsulta.FieldByName('ID_VA_PIVOT').AsString;
            oArticulo.IdAcFila :=
              oConsulta.FieldByName('ID_AC_FILA').AsInteger;
            oArticulo.IdVaFila :=
              oConsulta.FieldByName('ID_VA_FILA').AsString;
            oArticulo.TipoVariacion :=
              oConsulta.FieldByName('TIPO_VARIACION_ART').AsString;
            oArticulo.EsVariacion :=
              oConsulta.FieldByName('ESVARIACION_ART').AsString = 'S';
            oArticulo.EsTrazable :=
              oConsulta.FieldByName('ESTRAZABLE_ART').AsString = 'S';
            oArticulo.TipoArt :=
              oConsulta.FieldByName('TIPO_ART').AsString;
            oArticulo.TipoIva :=
              oConsulta.FieldByName('TIPO_IVA_ART').AsString;
            oArticulo.TipoCantidad :=
              oConsulta.FieldByName('TIPO_CANTIDAD_ART').AsString;
            oArticulo.UltimoCoste :=
              oConsulta.FieldByName('PRECIO_ULT_COMPRA').AsFloat;
            oArticulo.PrecioVenta :=
              oConsulta.FieldByName('PRECIO_VENTA').AsFloat;
            oArticulo.PrecioVentaResuelta := True;
            oArticulo.RefProveedor :=
              oConsulta.FieldByName('REF_PROVEEDOR').AsString;
            FArticulos.Add(sClave, oArticulo);
          end;
          oConsulta.Next;
        end;
      finally
        oConsulta.Free;
      end;
    end;
  finally
    oClaves.Free;
  end;
end;

function TCatalogoArticulosPedidoOcr.Resolver(
  const AModelo: string): TResolverDuplicadoSesion;
begin
  Result := Default(TResolverDuplicadoSesion);
  FArticulos.TryGetValue(ClaveModeloPedidoOcr(AModelo), Result);
end;

constructor TCatalogoColoresPedidoOcr.Create(
  AConexion: TUniConnection;
  const ACodigoProveedor: string;
  const ALineas: TLineasPedidoOcr);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FColores := TDictionary<string, string>.Create;
  Cargar(AConexion, ACodigoProveedor, ALineas);
end;

destructor TCatalogoColoresPedidoOcr.Destroy;
begin
  FColores.Free;
  inherited Destroy;
end;

procedure TCatalogoColoresPedidoOcr.Cargar(
  AConexion: TUniConnection;
  const ACodigoProveedor: string;
  const ALineas: TLineasPedidoOcr);
var
  iClave: Integer;
  oClaves: TStringList;
  oConsulta: TUniQuery;
  sClave: string;
  sParametros: string;
begin
  oClaves := TStringList.Create;
  try
    PrepararListaClaves(ALineas, False, oClaves);
    if oClaves.Count > 0 then
    begin
      sParametros := ListaParametros('color', oClaves.Count);
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'SELECT H.COLOR_PROVEEDOR, H.CODIGO_COLOR, H.PRIORIDAD, ' +
          '       H.RECENCIA, H.FRECUENCIA ' +
          '  FROM ( ' +
          '       SELECT UPPER(TRIM(L.COLOR_TEXTO_SESLIN)) ' +
          '                AS COLOR_PROVEEDOR, ' +
          '              B.CODIGO_ATB AS CODIGO_COLOR, ' +
          '              0 AS PRIORIDAD, ' +
          '              MAX(COALESCE(S.INSTANTE_MODIF, ' +
          '                           S.INSTANTE_ALTA)) AS RECENCIA, ' +
          '              0 AS FRECUENCIA ' +
          '         FROM fza_compras_sesiones_lineas L ' +
          '         JOIN fza_compras_sesiones S ' +
          '           ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
          '          AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
          '         JOIN fza_atributos_basicos B ' +
          '           ON B.ID_VA_ATB = ''CO'' ' +
          '          AND B.CODIGO_ATB = L.CODIGO_ATB_COLOR_SESLIN ' +
          '          AND B.ESACTIVO_ATB = ''S'' ' +
          '        WHERE S.CODIGO_PRV_SES = :proveedor ' +
          '          AND UPPER(TRIM(L.COLOR_TEXTO_SESLIN)) IN (' +
          sParametros + ') ' +
          '        GROUP BY COLOR_PROVEEDOR, B.CODIGO_ATB ' +
          '       UNION ALL ' +
          '       SELECT UPPER(TRIM(AV.AV)) AS COLOR_PROVEEDOR, ' +
          '              B.CODIGO_ATB AS CODIGO_COLOR, ' +
          '              1 AS PRIORIDAD, ' +
          '              CAST(''1900-01-01'' AS DATETIME) AS RECENCIA, ' +
          '              COUNT(DISTINCT AP.CODIGO_ART_AP) ' +
          '                AS FRECUENCIA ' +
          '         FROM fza_articulos_proveedores AP ' +
          '         JOIN fza_articulos_skus SKU ' +
          '           ON SKU.CODIGO_ART_SKU = AP.CODIGO_ART_AP ' +
          '         JOIN fza_atributos_sku SA ' +
          '           ON SA.CODIGO_UNIDAD_SKU_SA = ' +
          '              SKU.CODIGO_UNIDAD_SKU ' +
          '         JOIN fza_atributos_valores AV ' +
          '           ON AV.ID_AV = SA.ID_AV_SA ' +
          '          AND AV.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
          'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
          'SKU.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''F'') ' +
          '         JOIN fza_articulos_atributos_basicos AAB ' +
          '           ON AAB.CODIGO_ART_AAB = SKU.CODIGO_ART_SKU ' +
          '          AND AAB.ID_AV_AAB = AV.ID_AV ' +
          '         JOIN fza_atributos_basicos B ' +
          '           ON B.ID_ATB = AAB.ID_ATB_AAB ' +
          '          AND B.ID_VA_ATB = ''CO'' ' +
          '          AND B.ESACTIVO_ATB = ''S'' ' +
          '        WHERE AP.CODIGO_PRV_AP = :proveedor ' +
          '          AND UPPER(TRIM(AV.AV)) IN (' +
          sParametros + ') ' +
          '        GROUP BY COLOR_PROVEEDOR, B.CODIGO_ATB ' +
          '       ) H ' +
          ' ORDER BY H.COLOR_PROVEEDOR, H.PRIORIDAD, ' +
          '          H.RECENCIA DESC, H.FRECUENCIA DESC, ' +
          '          H.CODIGO_COLOR';
        oConsulta.ParamByName('proveedor').AsString :=
          ACodigoProveedor;
        for iClave := 0 to oClaves.Count - 1 do
          oConsulta.ParamByName('color' + IntToStr(iClave)).AsString :=
            oClaves[iClave];
        oConsulta.Open;
        while not oConsulta.Eof do
        begin
          sClave := oConsulta.FieldByName('COLOR_PROVEEDOR').AsString;
          if not FColores.ContainsKey(sClave) then
            FColores.Add(
              sClave,
              oConsulta.FieldByName('CODIGO_COLOR').AsString);
          oConsulta.Next;
        end;
      finally
        oConsulta.Free;
      end;
    end;
  finally
    oClaves.Free;
  end;
end;

function TCatalogoColoresPedidoOcr.Resolver(
  const AColorProveedor: string;
  out ACodigoColorBasico: string): Boolean;
begin
  ACodigoColorBasico := '';
  Result := FColores.TryGetValue(
    ClaveColorPedidoOcr(AColorProveedor),
    ACodigoColorBasico);
end;

class procedure TPersistenciaPedidoOcr.GuardarCeldas(
  AConexion: TUniConnection;
  const ASerie, ANumero, AUsuario: string;
  const ACeldas: TCeldasPedidoOcr);
var
  iCelda: Integer;
  oConsulta: TUniQuery;
  sValores: string;
begin
  if Length(ACeldas) > 0 then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      sValores := '';
      for iCelda := 0 to High(ACeldas) do
      begin
        if sValores <> '' then
          sValores := sValores + ', ';
        sValores := sValores +
          '(:serie, :numero, :linea' + IntToStr(iCelda) +
          ', 1, '''', :valor' + IntToStr(iCelda) +
          ', :cantidad' + IntToStr(iCelda) +
          ', NOW(), :usuario, NOW(), :usuario)';
      end;
      oConsulta.SQL.Text :=
        'INSERT INTO fza_compras_sesiones_celdas ' +
        '  (SERIE_SES_SESCEL, NUMERO_SES_SESCEL, ' +
        '   LINEA_SES_SESCEL, ID_FILA_SES_SESCEL, ' +
        '   CODIGO_ALM_SESCEL, ID_AV_PIVOT_SESCEL, ' +
        '   CANTIDAD_SESCEL, INSTANTE_ALTA, USUARIO_ALTA, ' +
        '   INSTANTE_MODIF, USUARIO_MODIF) VALUES ' +
        sValores +
        ' ON DUPLICATE KEY UPDATE ' +
        '   CANTIDAD_SESCEL = VALUES(CANTIDAD_SESCEL), ' +
        '   INSTANTE_MODIF = NOW(), ' +
        '   USUARIO_MODIF = VALUES(USUARIO_MODIF)';
      oConsulta.ParamByName('serie').AsString := ASerie;
      oConsulta.ParamByName('numero').AsString := ANumero;
      oConsulta.ParamByName('usuario').AsString := AUsuario;
      for iCelda := 0 to High(ACeldas) do
      begin
        oConsulta.ParamByName(
          'linea' + IntToStr(iCelda)).AsInteger :=
          ACeldas[iCelda].Linea;
        oConsulta.ParamByName(
          'valor' + IntToStr(iCelda)).AsInteger :=
          ACeldas[iCelda].IdAv;
        oConsulta.ParamByName(
          'cantidad' + IntToStr(iCelda)).AsFloat :=
          ACeldas[iCelda].Cantidad;
      end;
      oConsulta.ExecSQL;
    finally
      oConsulta.Free;
    end;
  end;
end;

class function TPersistenciaPedidoOcr.ReservarLineas(
  AConexion: TUniConnection;
  const ASerie, ANumero: string;
  ACantidad: Integer): Integer;
var
  iContador: Integer;
  oConsulta: TUniQuery;
begin
  Result := 0;
  if ACantidad > 0 then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text :=
        'SELECT COALESCE(CONTADOR_LINEAS_SES, 0) AS CONTADOR ' +
        '  FROM fza_compras_sesiones ' +
        ' WHERE SERIE_SES = :serie AND NUMERO_SES = :numero ' +
        ' FOR UPDATE';
      oConsulta.ParamByName('serie').AsString := ASerie;
      oConsulta.ParamByName('numero').AsString := ANumero;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        iContador := oConsulta.FieldByName('CONTADOR').AsInteger;
        Result := iContador + 10;
      end;
      oConsulta.Close;
      if Result > 0 then
      begin
        oConsulta.SQL.Text :=
          'UPDATE fza_compras_sesiones ' +
          '   SET CONTADOR_LINEAS_SES = :ultimo ' +
          ' WHERE SERIE_SES = :serie AND NUMERO_SES = :numero';
        oConsulta.ParamByName('ultimo').AsInteger :=
          Result + ((ACantidad - 1) * 10);
        oConsulta.ParamByName('serie').AsString := ASerie;
        oConsulta.ParamByName('numero').AsString := ANumero;
        oConsulta.ExecSQL;
      end;
    finally
      oConsulta.Free;
    end;
  end;
end;

class function THistoricoColoresPedidoOcr.ConsultarCodigo(
  AConexion: TUniConnection;
  const ASql, ACodigoProveedor,
  AColorProveedor: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := ASql;
    oConsulta.ParamByName('proveedor').AsString := ACodigoProveedor;
    oConsulta.ParamByName('color').AsString := AColorProveedor;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := Trim(
        oConsulta.FieldByName('CODIGO_COLOR').AsString);
  finally
    oConsulta.Free;
  end;
end;

class function THistoricoColoresPedidoOcr.Resolver(
  AConexion: TUniConnection;
  const ACodigoProveedor,
  AColorProveedor: string;
  out ACodigoColorBasico: string): Boolean;
var
  sColorNormalizado: string;
begin
  ACodigoColorBasico := '';
  sColorNormalizado := UpperCase(
    SanearColorSku(AColorProveedor));
  if Assigned(AConexion) and
     (Trim(ACodigoProveedor) <> '') and
     (sColorNormalizado <> '') then
  begin
    ACodigoColorBasico := ConsultarCodigo(
      AConexion,
      SQL_COLOR_HISTORICO_SESIONES,
      ACodigoProveedor,
      sColorNormalizado);
    if ACodigoColorBasico = '' then
      ACodigoColorBasico := ConsultarCodigo(
        AConexion,
        SQL_COLOR_HISTORICO_ARTICULOS,
        ACodigoProveedor,
        sColorNormalizado);
  end;
  Result := ACodigoColorBasico <> '';
end;

constructor TCatalogoTallasPedidoOcr.Create(
  AConexion: TUniConnection;
  AMaximoPosiciones: Integer);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FMaximoPosiciones := AMaximoPosiciones;
  FSistemas := TObjectList<TSistemaTallasPedidoOcr>.Create(True);
  Cargar(AConexion);
end;

destructor TCatalogoTallasPedidoOcr.Destroy;
begin
  FSistemas.Free;
  inherited Destroy;
end;

procedure TCatalogoTallasPedidoOcr.Cargar(AConexion: TUniConnection);
var
  iValor: Integer;
  oActual: TSistemaTallasPedidoOcr;
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT AC.ID_AC, AC.NOMBRE_AC, ACD.ID_AV_ACD, AV.AV' +
      '  FROM fza_atributos_conjuntos AC' +
      '  JOIN fza_atributos_conjuntos_det ACD' +
      '    ON ACD.ID_AC_ACD = AC.ID_AC' +
      '  JOIN fza_atributos_valores AV' +
      '    ON AV.ID_AV = ACD.ID_AV_ACD' +
      ' WHERE AC.ESACTIVO_AC = ''S''' +
      '   AND AC.ID_VA_AC IN (SELECT ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES WHERE EJE_VA = ''P'')' +
      ' ORDER BY AC.NOMBRE_AC, AC.ID_AC,' +
      '          ACD.ORDEN_ACD, AV.AV';
    oConsulta.Open;
    oActual := nil;
    while not oConsulta.Eof do
    begin
      if (oActual = nil) or
         (oActual.IdAc <> oConsulta.FieldByName('ID_AC').AsInteger) then
      begin
        oActual := TSistemaTallasPedidoOcr.Create;
        oActual.IdAc := oConsulta.FieldByName('ID_AC').AsInteger;
        oActual.Nombre := oConsulta.FieldByName('NOMBRE_AC').AsString;
        FSistemas.Add(oActual);
      end;
      iValor := Length(oActual.Valores);
      SetLength(oActual.Valores, iValor + 1);
      oActual.Valores[iValor].IdAv :=
        oConsulta.FieldByName('ID_AV_ACD').AsInteger;
      oActual.Valores[iValor].Valor :=
        oConsulta.FieldByName('AV').AsString;
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TCatalogoTallasPedidoOcr.BuscarValor(
  ASistema: TSistemaTallasPedidoOcr;
  const ATalla: string): Integer;
var
  bEncontrada: Boolean;
  iValor: Integer;
  sTalla: string;
begin
  Result := 0;
  bEncontrada := False;
  iValor := 0;
  sTalla := NormalizarTallaPedido(ATalla);
  while (iValor <= High(ASistema.Valores)) and (not bEncontrada) do
  begin
    if NormalizarTallaPedido(ASistema.Valores[iValor].Valor) = sTalla then
    begin
      Result := ASistema.Valores[iValor].IdAv;
      bEncontrada := True;
    end;
    Inc(iValor);
  end;
end;

function TCatalogoTallasPedidoOcr.Resolver(
  const ATallas: TTallasPedidoOcr): TResolucionTallasPedidoOcr;
var
  bCubre: Boolean;
  iSistema: Integer;
  iTalla: Integer;
begin
  Result := Default(TResolucionTallasPedidoOcr);
  iSistema := 0;
  while (iSistema < FSistemas.Count) and (not Result.Encontrada) do
  begin
    bCubre := (Length(FSistemas[iSistema].Valores) <=
               FMaximoPosiciones) and (Length(ATallas) > 0);
    SetLength(Result.IdsAv, Length(ATallas));
    iTalla := 0;
    while (iTalla <= High(ATallas)) and bCubre do
    begin
      Result.IdsAv[iTalla] := BuscarValor(
        FSistemas[iSistema],
        ATallas[iTalla].Talla);
      bCubre := Result.IdsAv[iTalla] > 0;
      Inc(iTalla);
    end;
    if bCubre then
    begin
      Result.Encontrada := True;
      Result.IdAc := FSistemas[iSistema].IdAc;
      Result.NombreSistema := FSistemas[iSistema].Nombre;
    end;
    Inc(iSistema);
  end;
  if not Result.Encontrada then
    Result.IdsAv := nil;
end;

end.
