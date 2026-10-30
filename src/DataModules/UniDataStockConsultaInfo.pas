{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataStockConsultaInfo                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas UniDAC para el resumen de la cabecera de la consulta de stock.   }
{******************************************************************************}
unit UniDataStockConsultaInfo;

interface

uses
  Uni,
  inLibStockConsultaInfo;

function CargarInfoCabeceraStock(
  AConexion: TUniConnection;
  const ACodigoArticulo: string;
  const ATarifa: string = 'PVP'): TInfoCabeceraStock;

implementation

uses
  System.SysUtils, System.Generics.Collections, Data.DB,
  UniDataPrecioUnidad;

procedure CargarPropiedades(
  AConsulta: TUniQuery;
  const ACodigoArticulo: string;
  var AInfo: TInfoCabeceraStock);
var
  i: Integer;
begin
  AConsulta.SQL.Text :=
    'SELECT P.CODIGO_PROP_ARTPROP, P.NOMBRE_PROP_PROP, P.TIPO_VALOR_PROP, ' +
    '       AP.VALOR_LIBRE_ARTPROP, PV.PV ' +
    '  FROM fza_articulos_propiedades AP ' +
    '  JOIN fza_propiedades P ' +
    '    ON P.CODIGO_PROP_ARTPROP = AP.CODIGO_PROP_ARTPROP ' +
    '  LEFT JOIN fza_propiedades_valores PV ' +
    '    ON PV.ID_PV_ARTPROP = AP.ID_PV_ARTPROP ' +
    ' WHERE AP.CODIGO_ART_ART = :art ' +
    '   AND AP.CODIGO_UNIDAD_ARTPROP = '''' ' +
    '   AND IFNULL(P.ESACTIVO_PROP, ''S'') = ''S'' ' +
    ' ORDER BY P.NOMBRE_PROP_PROP';
  AConsulta.ParamByName('art').AsString := ACodigoArticulo;
  AConsulta.Open;
  SetLength(AInfo.Propiedades, 0);
  i := 0;
  while not AConsulta.Eof do
  begin
    SetLength(AInfo.Propiedades, i + 1);
    AInfo.Propiedades[i].Codigo :=
      AConsulta.FieldByName('CODIGO_PROP_ARTPROP').AsString;
    AInfo.Propiedades[i].Nombre :=
      AConsulta.FieldByName('NOMBRE_PROP_PROP').AsString;
    AInfo.Propiedades[i].TipoValor :=
      AConsulta.FieldByName('TIPO_VALOR_PROP').AsString;
    AInfo.Propiedades[i].ValorLibre :=
      AConsulta.FieldByName('VALOR_LIBRE_ARTPROP').AsString;
    AInfo.Propiedades[i].ValorLista :=
      AConsulta.FieldByName('PV').AsString;
    Inc(i);
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

procedure CargarTarifas(
  AConsulta: TUniQuery;
  const ACodigoArticulo: string;
  var AInfo: TInfoCabeceraStock);
var
  i: Integer;
begin
  AConsulta.SQL.Text :=
    'SELECT AT.CODIGO_TAR_ARTTAR, T.NOMBRE_TAR_TAR, ' +
    '       AT.PRECIO_FINAL_ARTTAR ' +
    '  FROM fza_articulos_tarifas AT ' +
    '  LEFT JOIN fza_tarifas T ' +
    '    ON T.CODIGO_TAR_ARTTAR = AT.CODIGO_TAR_ARTTAR ' +
    ' WHERE AT.CODIGO_ART_ARTTAR = :art ' +
    '   AND IFNULL(AT.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '   AND AT.ESACTIVO_ARTTAR = ''S'' ' +
    '   AND (AT.FECHA_DESDE_ARTTAR IS NULL ' +
    '        OR AT.FECHA_DESDE_ARTTAR <= CURRENT_DATE) ' +
    '   AND (AT.FECHA_HASTA_ARTTAR IS NULL ' +
    '        OR AT.FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
    '   AND AT.CODIGO_UNICO_ARTTAR = ( ' +
    '         SELECT AT2.CODIGO_UNICO_ARTTAR ' +
    '           FROM fza_articulos_tarifas AT2 ' +
    '          WHERE AT2.CODIGO_ART_ARTTAR = AT.CODIGO_ART_ARTTAR ' +
    '            AND IFNULL(AT2.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    '            AND AT2.CODIGO_TAR_ARTTAR = AT.CODIGO_TAR_ARTTAR ' +
    '            AND AT2.ESACTIVO_ARTTAR = ''S'' ' +
    '            AND (AT2.FECHA_DESDE_ARTTAR IS NULL ' +
    '                 OR AT2.FECHA_DESDE_ARTTAR <= CURRENT_DATE) ' +
    '            AND (AT2.FECHA_HASTA_ARTTAR IS NULL ' +
    '                 OR AT2.FECHA_HASTA_ARTTAR >= CURRENT_DATE) ' +
    '          ORDER BY AT2.FECHA_DESDE_ARTTAR DESC, ' +
    '                   AT2.CODIGO_UNICO_ARTTAR DESC ' +
    '          LIMIT 1) ' +
    ' ORDER BY COALESCE(T.ORDEN_TAR, 999999), T.NOMBRE_TAR_TAR';
  AConsulta.ParamByName('art').AsString := ACodigoArticulo;
  AConsulta.Open;
  SetLength(AInfo.Tarifas, 0);
  i := 0;
  while not AConsulta.Eof do
  begin
    SetLength(AInfo.Tarifas, i + 1);
    AInfo.Tarifas[i].Codigo :=
      AConsulta.FieldByName('CODIGO_TAR_ARTTAR').AsString;
    AInfo.Tarifas[i].Nombre :=
      AConsulta.FieldByName('NOMBRE_TAR_TAR').AsString;
    AInfo.Tarifas[i].PrecioFinal :=
      AConsulta.FieldByName('PRECIO_FINAL_ARTTAR').AsFloat;
    Inc(i);
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

procedure CargarProveedores(
  AConsulta: TUniQuery;
  const ACodigoArticulo: string;
  var AInfo: TInfoCabeceraStock);
var
  i: Integer;
begin
  AConsulta.SQL.Text :=
    'SELECT AP.CODIGO_PRV_AP, P.RAZON_SOCIAL_PRV, ' +
    '       AP.REF_PROVEEDOR_AP, AP.PRECIO_ULT_COMPRA_AP, ' +
    '       AP.ESPROVEEDORPRINCIPAL_AP ' +
    '  FROM fza_articulos_proveedores AP ' +
    '  LEFT JOIN fza_proveedores P ' +
    '    ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
    ' WHERE AP.CODIGO_ART_AP = :art ' +
    ' ORDER BY AP.ESPROVEEDORPRINCIPAL_AP DESC, ' +
    '          P.RAZON_SOCIAL_PRV';
  AConsulta.ParamByName('art').AsString := ACodigoArticulo;
  AConsulta.Open;
  SetLength(AInfo.Proveedores, 0);
  i := 0;
  while not AConsulta.Eof do
  begin
    SetLength(AInfo.Proveedores, i + 1);
    AInfo.Proveedores[i].Codigo :=
      AConsulta.FieldByName('CODIGO_PRV_AP').AsString;
    AInfo.Proveedores[i].RazonSocial :=
      AConsulta.FieldByName('RAZON_SOCIAL_PRV').AsString;
    AInfo.Proveedores[i].Referencia :=
      AConsulta.FieldByName('REF_PROVEEDOR_AP').AsString;
    AInfo.Proveedores[i].PrecioUltimaCompra :=
      AConsulta.FieldByName('PRECIO_ULT_COMPRA_AP').AsFloat;
    AInfo.Proveedores[i].EsPrincipal :=
      AConsulta.FieldByName(
        'ESPROVEEDORPRINCIPAL_AP').AsString = 'S';
    Inc(i);
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

function CargarInfoCabeceraStock(
  AConexion: TUniConnection;
  const ACodigoArticulo: string; const ATarifa: string): TInfoCabeceraStock;
var
  Consulta: TUniQuery;
  Precio: TPrecioSkuUnidad;
  oPrecios: TList<string>;
begin
  Result := Default(TInfoCabeceraStock);
  if Trim(ACodigoArticulo) <> '' then
  begin
    Consulta := TUniQuery.Create(nil);
    try
      Consulta.Connection := AConexion;
      CargarPropiedades(Consulta, ACodigoArticulo, Result);
      CargarTarifas(Consulta, ACodigoArticulo, Result);
      CargarProveedores(Consulta, ACodigoArticulo, Result);
      oPrecios := TList<string>.Create;
      try
        for Precio in ListarPreciosUnidad(AConexion, ACodigoArticulo,
          ATarifa, Date) do
          if Precio.PrecioUnidad.Texto <> '' then
            oPrecios.Add(Precio.CodigoSku + ': ' +
              Precio.PrecioUnidad.Texto);
        Result.PreciosUnidad := oPrecios.ToArray;
      finally
        FreeAndNil(oPrecios);
      end;
    finally
      FreeAndNil(Consulta);
    end;
  end;
end;

end.
