{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataBusquedasCompraRepositorio                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas UniDAC para búsquedas de artículos y SKU en compras.            }
{******************************************************************************}
unit UniDataBusquedasCompraRepositorio;

interface

uses
  Uni,
  inLibBusquedasCompraPersistenciaIntf;

function CrearBusquedasCompraPersistenciaUniDAC(
  AConexion: TUniConnection): IBusquedasCompraPersistencia;

implementation

uses
  System.SysUtils, Data.DB;

const
  SQL_ARTICULOS_PROVEEDOR =
    'SELECT art.CODIGO_ART_ART, art.ESACTIVO_ART, art.ORDEN_ART, ' +
    '       art.DESCRIPCION_ART, art.CODIGO_FAM_ART, ' +
    '       fam.DESCRIPCION_FAM, ' +
    '       COALESCE(pv.PV, artprop.VALOR_LIBRE_ARTPROP, '''') ' +
    '         AS TEMPORADA, art.TIPO_IVA_ART, ' +
    '       iva.NOMBRE_TIPO_IVA_IVATIP, art.TIPO_CANTIDAD_ART, ' +
    '       ap.CODIGO_PRV_AP, prv.RAZON_SOCIAL_PRV, ' +
    '       prv.NOMBRE_PRV, ' +
    '       ap.REF_PROVEEDOR_AP AS REF_PROVEEDOR, ' +
    '       ap.PRECIO_ULT_COMPRA_AP, ap.FECHA_VALIDEZ_AP ' +
    '  FROM fza_articulos_proveedores ap ' +
    '  JOIN fza_articulos art ' +
    '    ON art.CODIGO_ART_ART = ap.CODIGO_ART_AP ' +
    '  LEFT JOIN fza_articulos_familias fam ' +
    '    ON fam.CODIGO_FAM_FAM = art.CODIGO_FAM_ART ' +
    '  LEFT JOIN fza_articulos_propiedades artprop ' +
    '    ON artprop.CODIGO_ART_ART = art.CODIGO_ART_ART ' +
    '   AND artprop.CODIGO_PROP_ARTPROP = ''TEMPORADA'' ' +
    '   AND artprop.CODIGO_UNIDAD_ARTPROP = '''' ' +
    '  LEFT JOIN fza_propiedades_valores pv ' +
    '    ON pv.ID_PV_ARTPROP = artprop.ID_PV_ARTPROP ' +
    '  LEFT JOIN fza_ivas_tipos iva ' +
    '    ON iva.CODIGO_ABREVIATURA_IVA_IVATIP = art.TIPO_IVA_ART ' +
    '  LEFT JOIN fza_proveedores prv ' +
    '    ON prv.CODIGO_PRV_PRV = ap.CODIGO_PRV_AP ' +
    ' WHERE ap.CODIGO_PRV_AP = :prv ' +
    '   AND COALESCE(art.ESACTIVO_ART, ''S'') = ''S'' ' +
    ' ORDER BY art.ORDEN_ART, art.CODIGO_ART_ART';
  SQL_SKUS_ARTICULO =
    'SELECT SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU, ' +
    '       GROUP_CONCAT(AV.AV ORDER BY ' +
    '       COALESCE(VA.ORDEN_VA, 999), ' +
    '       AV.ORDEN_AV SEPARATOR '' / '') AS ATRIBUTOS ' +
    '  FROM fza_articulos_skus SK ' +
    '  LEFT JOIN fza_atributos_sku SA ' +
    '    ON SA.CODIGO_UNIDAD_SKU_SA = SK.CODIGO_UNIDAD_SKU ' +
    '  LEFT JOIN fza_atributos_valores AV ' +
    '    ON AV.ID_AV = SA.ID_AV_SA ' +
    '  LEFT JOIN fza_variaciones_atributos VA ' +
    '    ON VA.ID_VAR_VA = SK.CODIGO_VAR_SKU ' +
    '   AND VA.ID_ATB_VA = AV.ID_VA_AV ' +
    ' WHERE SK.CODIGO_ART_SKU = :art ' +
    '   AND COALESCE(SK.ESACTIVO_SKU, ''S'') = ''S'' ' +
    ' GROUP BY SK.CODIGO_UNIDAD_SKU, SK.CODIGO_ART_SKU ' +
    ' ORDER BY SK.CODIGO_UNIDAD_SKU';

type
  TConsultaBusquedaCompraUniDAC = class(
    TInterfacedObject,
    IConsultaBusquedaCompra)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConexion: TUniConnection;
      const ASql, AParametro, AValor: string);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TBusquedasCompraPersistenciaUniDAC = class(
    TInterfacedObject,
    IBusquedasCompraPersistencia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ConsultarArticulosProveedor(
      const ACodigoProveedor: string): IConsultaBusquedaCompra;
    function ConsultarSkusArticulo(
      const ACodigoArticulo: string): IConsultaBusquedaCompra;
  end;

constructor TConsultaBusquedaCompraUniDAC.Create(
  AConexion: TUniConnection; const ASql, AParametro, AValor: string);
begin
  inherited Create;
  FConsulta := TUniQuery.Create(nil);
  FConsulta.Connection := AConexion;
  FConsulta.SQL.Text := ASql;
  FConsulta.ParamByName(AParametro).AsString := AValor;
  FConsulta.Open;
end;

destructor TConsultaBusquedaCompraUniDAC.Destroy;
begin
  FConsulta.Free;
  inherited;
end;

function TConsultaBusquedaCompraUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TBusquedasCompraPersistenciaUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TBusquedasCompraPersistenciaUniDAC.ConsultarArticulosProveedor(
  const ACodigoProveedor: string): IConsultaBusquedaCompra;
begin
  Result := TConsultaBusquedaCompraUniDAC.Create(
    FConexion, SQL_ARTICULOS_PROVEEDOR, 'prv', ACodigoProveedor);
end;

function TBusquedasCompraPersistenciaUniDAC.ConsultarSkusArticulo(
  const ACodigoArticulo: string): IConsultaBusquedaCompra;
begin
  Result := TConsultaBusquedaCompraUniDAC.Create(
    FConexion, SQL_SKUS_ARTICULO, 'art', ACodigoArticulo);
end;

function CrearBusquedasCompraPersistenciaUniDAC(
  AConexion: TUniConnection): IBusquedasCompraPersistencia;
begin
  Result := TBusquedasCompraPersistenciaUniDAC.Create(AConexion);
end;

end.
