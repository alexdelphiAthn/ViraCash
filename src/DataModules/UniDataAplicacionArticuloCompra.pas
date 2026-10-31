{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAplicacionArticuloCompra                              }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores UniDAC del caso de uso de artículos en líneas de compra.      }
{******************************************************************************}
unit UniDataAplicacionArticuloCompra;

interface

uses
  Data.DB, Uni, inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf, inLibAplicacionArticuloCompraIntf;

function SqlCostePropuestoSkuCompra: string;

function CrearRepositorioLecturasArticuloCompraUniDAC(
  AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver):
  IRepositorioLecturasArticuloCompra;
function CrearPuertoLineaArticuloCompraUniDAC(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet): IPuertoLineaArticuloCompra;
function RecogerEntradaArticuloCompra(
  const ACodigoIntroducido: string;
  ACabecera: TDataSet;
  ATipoDocumento: TTipoDocumentoArticuloCompra;
  APivoteActivo: Boolean): TEntradaAplicacionArticuloCompra;

implementation

uses
  System.SysUtils, inLibComprasImpuestos, inLibMsgCompras,
  UniDataImpuestosRepositorio, UniDataArticulosValidadorRepositorio;

// Histórico del SKU; si no lo hay, el coste de su fila de tarifa con la
// misma prioridad que el PVP: SKU exacto, talla para cualquier color
// (ART/*/TALLA) y prefijo de color (ART/COLOR). La fila general del
// artículo no entra: ahí manda el último coste del proveedor
// (FZ-ISSUE-466, FZ-ISSUE-634).
function SqlCostePropuestoSkuCompra: string;
begin
  Result :=
    'SELECT SC.PRECIO_ULT_COMPRA_SKUC AS COSTE, ' +
    'SC.FECHA_ULT_COMPRA_SKUC AS FECHA_COSTE, 0 AS PRIORIDAD, ' +
    '0 AS LONGITUD, ' +
    'SC.FECHA_ULT_COMPRA_SKUC AS FECHA_ORDEN, 0 AS ID_ORDEN ' +
    'FROM fza_articulos_skus_costes SC ' +
    'WHERE SC.CODIGO_UNIDAD_SKU_SKUC = :sku ' +
    'AND SC.PRECIO_ULT_COMPRA_SKUC IS NOT NULL ' +
    'UNION ALL ' +
    'SELECT PT.PRECIO_COSTE_ARTTAR, PT.FECHA_ULT_COMPRA_ARTTAR, ' +
    // FZ-ISSUE-786 (observación de FZ-782): la tarifa general del
    // artículo (sin unidad) es el último recurso; antes un SKU sin compras
    // ni tarifa propia proponía 0,00.
    'CASE WHEN COALESCE(PT.CODIGO_UNIDAD_ARTTAR, '''') = '''' THEN 4 ' +
    'WHEN PT.CODIGO_UNIDAD_ARTTAR = :sku THEN 1 ' +
    'WHEN LOCATE(''/*/'', PT.CODIGO_UNIDAD_ARTTAR) > 0 THEN 2 ' +
    'ELSE 3 END, CHAR_LENGTH(PT.CODIGO_UNIDAD_ARTTAR), ' +
    'PT.FECHA_DESDE_ARTTAR, PT.CODIGO_UNICO_ARTTAR ' +
    'FROM fza_articulos_tarifas PT ' +
    'WHERE PT.CODIGO_ART_ARTTAR = :art ' +
    'AND PT.CODIGO_TAR_ARTTAR = :tar AND PT.ESACTIVO_ARTTAR = ''S'' ' +
    'AND PT.PRECIO_COSTE_ARTTAR IS NOT NULL ' +
    'AND (COALESCE(PT.CODIGO_PRV_ARTTAR, '''') = '''' ' +
    'OR PT.CODIGO_PRV_ARTTAR = :prv) ' +
    'AND (PT.FECHA_DESDE_ARTTAR IS NULL ' +
    'OR PT.FECHA_DESDE_ARTTAR <= :fecha) ' +
    'AND (PT.FECHA_HASTA_ARTTAR IS NULL ' +
    'OR PT.FECHA_HASTA_ARTTAR >= :fecha) ' +
    'AND (PT.CODIGO_UNIDAD_ARTTAR = :sku ' +
    'OR COALESCE(PT.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'OR (COALESCE(PT.CODIGO_UNIDAD_ARTTAR, '''') <> '''' ' +
    'AND LOCATE(''/*/'', PT.CODIGO_UNIDAD_ARTTAR) = 0 ' +
    'AND LEFT(:sku, CHAR_LENGTH(PT.CODIGO_UNIDAD_ARTTAR) + 1) ' +
    '= CONCAT(PT.CODIGO_UNIDAD_ARTTAR, ''/'')) ' +
    'OR EXISTS (SELECT 1 FROM fza_atributos_sku ATS ' +
    'JOIN fza_atributos_valores TALLA ON TALLA.ID_AV = ATS.ID_AV_SA ' +
    'AND TALLA.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
    'AR452.CODIGO_ART_ART = :art) AND EJ452.EJE_VA = ''P'') ' +
    'WHERE ATS.CODIGO_UNIDAD_SKU_SA = :sku ' +
    'AND PT.CODIGO_UNIDAD_ARTTAR = ' +
    'CONCAT(PT.CODIGO_ART_ARTTAR, ''/*/'', TALLA.AV))) ' +
    'ORDER BY PRIORIDAD, LONGITUD DESC, FECHA_ORDEN DESC, ' +
    'ID_ORDEN DESC LIMIT 1';
end;

type
  TRepositorioLecturasArticuloCompraUniDAC = class(
    TInterfacedObject,
    IRepositorioLecturasArticuloCompra)
  private
    FConexion: TUniConnection;
    FValidador: IArticulosValidador;
    FResolver: IArticulosResolver;
    procedure CompletarCosteSku(const AFecha: TDateTime;
      const ACodigoProveedor: string; var ADatos: TArticuloDatos);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AValidador: IArticulosValidador;
      const AResolver: IArticulosResolver);
    function ResolverEntrada(
      const AEntrada: string): TArtResolucionEntrada;
    function ResolverDatos(
      const ACodigoArticulo, ACodigoSku: string;
      const AFecha: TDateTime;
      const ACodigoAlmacen,
      ACodigoProveedor: string): TArticuloDatos;
    function ResolverUltimoCoste(
      const ACodigoArticulo,
      ACodigoProveedor: string): TArticuloCoste;
    function BuscarConjuntoPivote(
      const ACodigoArticulo: string): Integer;
    function BuscarModeloProveedor(
      const ACodigoArticulo,
      ACodigoProveedor: string): string;
  end;

  TPuertoLineaArticuloCompraUniDAC = class(
    TInterfacedObject,
    IPuertoLineaArticuloCompra)
  private
    FConexion: TUniConnection;
    FCabecera: TDataSet;
    FLineas: TDataSet;
    procedure LimpiarCampo(const ACampo: string);
    procedure PonerFloat(const ACampo: string; AValor: Double);
    procedure PonerInteger(const ACampo: string; AValor: Integer);
    procedure PonerString(const ACampo, AValor: string);
  public
    constructor Create(
      AConexion: TUniConnection;
      ACabecera, ALineas: TDataSet);
    function PrepararLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      out AActual: TLineaActualArticuloCompra): Boolean;
    procedure AplicarLinea(
      const AConfiguracion: TConfiguracionCamposArticuloCompra;
      const ALinea: TLineaArticuloCompra);
  end;

function CampoString(ADataSet: TDataSet; const ACampo: string): string;
var
  oCampo: TField;
begin
  Result := '';
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if oCampo <> nil then
      Result := Trim(oCampo.AsString);
  end;
end;

function CampoFecha(ADataSet: TDataSet; const ACampo: string): TDateTime;
var
  oCampo: TField;
begin
  Result := Date;
  if Assigned(ADataSet) and ADataSet.Active then
  begin
    oCampo := ADataSet.FindField(ACampo);
    if (oCampo <> nil) and (not oCampo.IsNull) then
      Result := oCampo.AsDateTime;
  end;
end;

function CrearRepositorioLecturasArticuloCompraUniDAC(
  AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver):
  IRepositorioLecturasArticuloCompra;
begin
  Result := TRepositorioLecturasArticuloCompraUniDAC.Create(
    AConexion,
    AValidador,
    AResolver);
end;

function CrearPuertoLineaArticuloCompraUniDAC(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet): IPuertoLineaArticuloCompra;
begin
  Result := TPuertoLineaArticuloCompraUniDAC.Create(
    AConexion,
    ACabecera,
    ALineas);
end;

function RecogerEntradaArticuloCompra(
  const ACodigoIntroducido: string;
  ACabecera: TDataSet;
  ATipoDocumento: TTipoDocumentoArticuloCompra;
  APivoteActivo: Boolean): TEntradaAplicacionArticuloCompra;
var
  oConfiguracion: TConfiguracionCamposArticuloCompra;
begin
  oConfiguracion := ConfiguracionCamposArticuloCompra(ATipoDocumento);
  Result := Default(TEntradaAplicacionArticuloCompra);
  Result.CodigoIntroducido := ACodigoIntroducido;
  Result.CodigoProveedor := CampoString(
    ACabecera,
    oConfiguracion.CampoProveedorCabecera);
  Result.CodigoAlmacen := CampoString(
    ACabecera,
    oConfiguracion.CampoAlmacenCabecera);
  Result.PreferenciaPivoteHorizontal := CampoString(
    ACabecera,
    oConfiguracion.CampoPreferenciaPivoteCabecera);
  Result.Fecha := CampoFecha(
    ACabecera,
    oConfiguracion.CampoFechaCabecera);
  Result.PivoteActivo := APivoteActivo;
end;

constructor TRepositorioLecturasArticuloCompraUniDAC.Create(
  AConexion: TUniConnection;
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if AValidador = nil then
    raise EArgumentNilException.Create('AValidador');
  if AResolver = nil then
    raise EArgumentNilException.Create('AResolver');
  inherited Create;
  FConexion := AConexion;
  FValidador := AValidador;
  FResolver := AResolver;
end;

function TRepositorioLecturasArticuloCompraUniDAC.ResolverEntrada(
  const AEntrada: string): TArtResolucionEntrada;
var
  sSku: string;
begin
  Result := FValidador.Resolver(AEntrada);
  // FZ-ISSUE-520: un SKU dado de baja (leído por su EAN o tecleado, que la
  // búsqueda ya no encuentra) no se compra, y el aviso lo dice en vez de
  // «no se encontró».
  if Result.Encontrado then
    sSku := Result.CodigoSku
  else
    sSku := AEntrada;
  if SkuDadoDeBaja(FConexion, sSku) then
  begin
    Result.Encontrado := False;
    Result.Mensaje := Format(SErrorSkuCompraNoActivo, [Trim(sSku)]);
  end;
end;

procedure TRepositorioLecturasArticuloCompraUniDAC.CompletarCosteSku(
  const AFecha: TDateTime; const ACodigoProveedor: string;
  var ADatos: TArticuloDatos);
var
  oConsulta: TUniQuery;
  dFecha: TDateTime;
begin
  // Antes del coste genérico del artículo: histórico del propio SKU o,
  // si aún no se ha comprado, su coste de tarifa vigente (FZ-ISSUE-466).
  if ADatos.Encontrado and (Trim(ADatos.CodigoSku) <> '') then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text := SqlCostePropuestoSkuCompra;
      oConsulta.ParamByName('art').AsString := ADatos.CodigoArticulo;
      oConsulta.ParamByName('sku').AsString := ADatos.CodigoSku;
      oConsulta.ParamByName('tar').AsString :=
        ADatos.PrecioTarifaDefault.CodigoTarifa;
      oConsulta.ParamByName('prv').AsString := ACodigoProveedor;
      dFecha := AFecha;
      if dFecha = 0 then
        dFecha := Date;
      oConsulta.ParamByName('fecha').AsDate := dFecha;
      oConsulta.Open;
      if not oConsulta.IsEmpty then
      begin
        ADatos.UltimoCoste.PrecioUltCompra :=
          oConsulta.FieldByName('COSTE').AsFloat;
        ADatos.UltimoCoste.FechaValidezCompra :=
          oConsulta.FieldByName('FECHA_COSTE').AsDateTime;
        ADatos.UltimoCoste.Encontrado := True;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function TRepositorioLecturasArticuloCompraUniDAC.ResolverDatos(
  const ACodigoArticulo, ACodigoSku: string;
  const AFecha: TDateTime;
  const ACodigoAlmacen,
  ACodigoProveedor: string): TArticuloDatos;
begin
  Result := FResolver.ResolverDatos(
    ACodigoArticulo,
    ACodigoSku,
    '',
    AFecha,
    ACodigoAlmacen,
    ACodigoProveedor);
  CompletarCosteSku(AFecha, ACodigoProveedor, Result);
end;

function TRepositorioLecturasArticuloCompraUniDAC.ResolverUltimoCoste(
  const ACodigoArticulo,
  ACodigoProveedor: string): TArticuloCoste;
begin
  Result := FResolver.ResolverUltimoCoste(
    ACodigoArticulo,
    ACodigoProveedor,
    '');
end;

function TRepositorioLecturasArticuloCompraUniDAC.BuscarConjuntoPivote(
  const ACodigoArticulo: string): Integer;
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
      ' WHERE ACA.CODIGO_ART_ACA = :art ' +
      '   AND ACA.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA FROM ' +
      'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
      'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
      'AR452.CODIGO_ART_ART = :art) AND EJ452.EJE_VA = ''P'') ' +
      ' ORDER BY ACA.ID_VA_ACA ' +
      ' LIMIT 1';
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('ID_AC_ACA').AsInteger;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TRepositorioLecturasArticuloCompraUniDAC.BuscarModeloProveedor(
  const ACodigoArticulo,
  ACodigoProveedor: string): string;
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
      ' WHERE AP.CODIGO_ART_AP = :art ' +
      '   AND COALESCE(TRIM(AP.REF_PROVEEDOR_AP), '''') <> '''' ' +
      ' ORDER BY CASE WHEN AP.CODIGO_PRV_AP = :prv THEN 0 ELSE 1 END, ' +
      '          CASE AP.ESPROVEEDORPRINCIPAL_AP WHEN ''S'' THEN 0 ' +
      '               ELSE 1 END, ' +
      '          AP.FECHA_VALIDEZ_AP DESC, AP.CODIGO_PRV_AP ' +
      ' LIMIT 1';
    oConsulta.ParamByName('art').AsString := ACodigoArticulo;
    oConsulta.ParamByName('prv').AsString := ACodigoProveedor;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
      Result := oConsulta.FieldByName('REF_PROVEEDOR_AP').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

constructor TPuertoLineaArticuloCompraUniDAC.Create(
  AConexion: TUniConnection;
  ACabecera, ALineas: TDataSet);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not Assigned(ACabecera) then
    raise EArgumentNilException.Create('ACabecera');
  if not Assigned(ALineas) then
    raise EArgumentNilException.Create('ALineas');
  inherited Create;
  FConexion := AConexion;
  FCabecera := ACabecera;
  FLineas := ALineas;
end;

procedure TPuertoLineaArticuloCompraUniDAC.LimpiarCampo(
  const ACampo: string);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.Clear;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.PonerFloat(
  const ACampo: string;
  AValor: Double);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsFloat := AValor;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.PonerInteger(
  const ACampo: string;
  AValor: Integer);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsInteger := AValor;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.PonerString(
  const ACampo,
  AValor: string);
var
  oCampo: TField;
begin
  if ACampo <> '' then
  begin
    oCampo := FLineas.FindField(ACampo);
    if oCampo <> nil then
      oCampo.AsString := AValor;
  end;
end;

function TPuertoLineaArticuloCompraUniDAC.PrepararLinea(
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  out AActual: TLineaActualArticuloCompra): Boolean;
var
  oCampo: TField;
begin
  AActual := Default(TLineaActualArticuloCompra);
  Result := Assigned(FLineas) and FLineas.Active;
  if Result then
  begin
    if FLineas.IsEmpty then
      FLineas.Append;
    if not (FLineas.State in dsEditModes) then
      FLineas.Edit;
    Result := FLineas.State in dsEditModes;
    if Result then
    begin
      oCampo := FLineas.FindField(AConfiguracion.CampoCantidad);
      if oCampo <> nil then
        AActual.Cantidad := oCampo.AsFloat;
      oCampo := FLineas.FindField(AConfiguracion.CampoCodigoArticulo);
      if oCampo <> nil then
        AActual.CodigoArticulo := oCampo.AsString;
      oCampo := FLineas.FindField(AConfiguracion.CampoCodigoSku);
      if oCampo <> nil then
        AActual.CodigoSku := oCampo.AsString;
      oCampo := FLineas.FindField(AConfiguracion.CampoPrecioCompra);
      if oCampo <> nil then
        AActual.PrecioCompra := oCampo.AsFloat;
    end;
  end;
end;

procedure TPuertoLineaArticuloCompraUniDAC.AplicarLinea(
  const AConfiguracion: TConfiguracionCamposArticuloCompra;
  const ALinea: TLineaArticuloCompra);
begin
  PonerString(AConfiguracion.CampoCodigoArticulo,
              ALinea.CodigoArticulo);
  PonerString(AConfiguracion.CampoCodigoSku, ALinea.CodigoSku);
  PonerString(AConfiguracion.CampoReferenciaProveedor,
              ALinea.ReferenciaProveedor);
  PonerString(AConfiguracion.CampoCodigoFamilia,
              ALinea.CodigoFamilia);
  PonerString(AConfiguracion.CampoNombreFamilia,
              ALinea.NombreFamilia);
  PonerString(AConfiguracion.CampoDescripcionArticulo,
              ALinea.DescripcionArticulo);
  PonerString(AConfiguracion.CampoTipoCantidad, ALinea.TipoCantidad);
  PonerString(AConfiguracion.CampoTipoIva, ALinea.TipoIva);
  if ALinea.AsignarAlmacen then
    PonerString(AConfiguracion.CampoAlmacenLinea,
                ALinea.CodigoAlmacen);
  if ALinea.IdConjuntoPivote > 0 then
    PonerInteger(AConfiguracion.CampoIdConjuntoPivote,
                 ALinea.IdConjuntoPivote)
  else
    LimpiarCampo(AConfiguracion.CampoIdConjuntoPivote);
  if ALinea.AsignarCantidad then
    PonerFloat(AConfiguracion.CampoCantidad, ALinea.Cantidad);
  if ALinea.AsignarTotalUnidades then
    PonerFloat(AConfiguracion.CampoTotalUnidades,
               ALinea.TotalUnidades);
  PonerFloat(AConfiguracion.CampoPrecioCompra, ALinea.PrecioCompra);
  PonerFloat(AConfiguracion.CampoTotal, ALinea.Total);
  PrepararLineaFiscalCompra(
    CrearLecturasImpuestos(FConexion),
    FCabecera,
    FLineas,
    AConfiguracion.SufijoCabecera,
    AConfiguracion.SufijoLinea,
    AConfiguracion.CampoTotal);
end;

end.
