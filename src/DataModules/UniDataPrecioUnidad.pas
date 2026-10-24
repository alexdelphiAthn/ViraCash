{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrecioUnidad                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                                }
{    Contenido neto de SKU y precios de referencia de la tarifa vigente.       }
{******************************************************************************}
unit UniDataPrecioUnidad;

interface

uses
  Uni, Data.DB, inLibPrecioUnidad;

type
  TPrecioSkuContenido = record
    Contenido: TContenidoPrecioUnidad;
    PrecioEnvase: Double;
    PrecioUnidad: TPrecioPorUnidad;
  end;

function LeerContenidoPrecioUnidad(AConexion: TUniConnection;
  const ACodigoSku: string): TContenidoPrecioUnidad;
procedure GuardarContenidoPrecioUnidad(AConexion: TUniConnection;
  const AContenido: TContenidoPrecioUnidad; const AUsuario: string);
function ListarPreciosContenido(AConexion: TUniConnection;
  const AArticulo, ATarifa: string; AFecha: TDateTime):
  TArray<TPrecioSkuContenido>;
function ListarContenidoFactura(AConexion: TUniConnection;
  const ASerie, ANumero: string): TArray<TContenidoPrecioUnidad>;
procedure PrepararPreciosUnidadEtiquetas(ADatos: TDataSet);
function SqlCamposPrecioUnidadEtiqueta: string;

implementation

uses
  System.SysUtils, System.Generics.Collections,
  inLibMsgArticulos, UniDataTarifasPrecioSql;

function SqlCamposPrecioUnidadEtiqueta: string;
begin
  Result :=
    'CASE WHEN tar.ESIMP_INCL_TAR = ''S'' THEN ' +
    'eti.FACTOR_PRECIO_UNIDAD * CASE WHEN {DESCUENTO_VIGENTE} ' +
    'THEN prc.PRECIO_FINAL_ARTTAR ELSE prc.PRECIO_SALIDA_ARTTAR ' +
    'END END AS PRECIO_UNIDAD, ' +
    'CAST('''' AS CHAR(80)) AS PRECIO_UNIDAD_TEXTO, ';
end;

function ContenidoDeConsulta(AConsulta: TUniQuery): TContenidoPrecioUnidad;
begin
  Result := Default(TContenidoPrecioUnidad);
  Result.CodigoSku := AConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  Result.Contenido := AConsulta.FieldByName('CONTENIDO_NETO').AsFloat;
  Result.UnidadContenido := AConsulta.FieldByName('UNIDAD_CONTENIDO').AsString;
  Result.Referencia := AConsulta.FieldByName('REFERENCIA_PRECIO').AsFloat;
  Result.UnidadReferencia :=
    AConsulta.FieldByName('UNIDAD_REFERENCIA').AsString;
  Result.EsIndicado := AConsulta.FieldByName('ESPRECIO_UNIDAD_ART').AsString
    = 'S';
  Result.EsTicket :=
    AConsulta.FieldByName('ESPRECIO_UNIDAD_TICKET_ART').AsString = 'S';
end;

const
  CAMPOS_CONTENIDO =
    'C.CODIGO_UNIDAD_SKU, C.CONTENIDO_NETO, C.UNIDAD_CONTENIDO, ' +
    'C.REFERENCIA_PRECIO, C.UNIDAD_REFERENCIA, ' +
    'C.ESPRECIO_UNIDAD_ART, C.ESPRECIO_UNIDAD_TICKET_ART ';

function LeerContenidoPrecioUnidad(AConexion: TUniConnection;
  const ACodigoSku: string): TContenidoPrecioUnidad;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT ' + CAMPOS_CONTENIDO +
      'FROM vi_articulos_contenido_neto C ' +
      'WHERE C.CODIGO_UNIDAD_SKU = :SKU';
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EDatabaseError.CreateFmt(SErrorContenidoSkuNoExiste, [ACodigoSku]);
    Result := ContenidoDeConsulta(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure ActualizarContenido(AConsulta: TUniQuery;
  const AContenido: TContenidoPrecioUnidad; const AUsuario: string);
begin
  AConsulta.SQL.Text := 'UPDATE fza_articulos_skus SET ' +
    'VALOR_CONTENIDO_NETO_SKU = :CONTENIDO, ' +
    'UNIDAD_CONTENIDO_NETO_SKU = :UNIDAD, ' +
    'USUARIO_MODIF = :USUARIO ' +
    'WHERE CODIGO_UNIDAD_SKU = :SKU';
  AConsulta.ParamByName('CONTENIDO').AsFloat := AContenido.Contenido;
  AConsulta.ParamByName('UNIDAD').AsString :=
    LowerCase(Trim(AContenido.UnidadContenido));
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('SKU').AsString := AContenido.CodigoSku;
  AConsulta.ExecSQL;
  AConsulta.SQL.Text := 'UPDATE fza_articulos SET ' +
    'VALOR_REFERENCIA_PRECIO_ART = :REFERENCIA, ' +
    'UNIDAD_REFERENCIA_PRECIO_ART = :UNIDAD, ' +
    'ESPRECIO_UNIDAD_ART = :INDICAR, ' +
    'ESPRECIO_UNIDAD_TICKET_ART = :TICKET, USUARIO_MODIF = :USUARIO ' +
    'WHERE CODIGO_ART_ART = (SELECT CODIGO_ART_SKU ' +
    'FROM fza_articulos_skus WHERE CODIGO_UNIDAD_SKU = :SKU)';
  AConsulta.ParamByName('REFERENCIA').AsFloat := AContenido.Referencia;
  AConsulta.ParamByName('UNIDAD').AsString :=
    LowerCase(Trim(AContenido.UnidadReferencia));
  AConsulta.ParamByName('INDICAR').AsString :=
    Copy('NS', Ord(AContenido.EsIndicado) + 1, 1);
  AConsulta.ParamByName('TICKET').AsString :=
    Copy('NS', Ord(AContenido.EsTicket) + 1, 1);
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('SKU').AsString := AContenido.CodigoSku;
  AConsulta.ExecSQL;
end;

procedure GuardarContenidoPrecioUnidad(AConexion: TUniConnection;
  const AContenido: TContenidoPrecioUnidad; const AUsuario: string);
var
  oConsulta: TUniQuery;
  bPropia: Boolean;
begin
  if AContenido.EsIndicado and
     (CalcularPrecioPorUnidad(AContenido, 0).Estado <> epuValido) then
    raise EArgumentException.Create(SErrorContenidoPrecioUnidad);
  if AContenido.EsTicket and not AContenido.EsIndicado then
    raise EArgumentException.Create(SErrorContenidoPrecioUnidad);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    bPropia := not AConexion.InTransaction;
    if bPropia then
      AConexion.StartTransaction;
    try
      oConsulta.SQL.Text := 'SELECT CODIGO_UNIDAD_SKU ' +
        'FROM fza_articulos_skus WHERE CODIGO_UNIDAD_SKU = :SKU FOR UPDATE';
      oConsulta.ParamByName('SKU').AsString := AContenido.CodigoSku;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise EDatabaseError.CreateFmt(SErrorContenidoSkuNoExiste,
          [AContenido.CodigoSku]);
      oConsulta.Close;
      ActualizarContenido(oConsulta, AContenido, AUsuario);
      if bPropia then
        AConexion.Commit;
    except
      if bPropia then
        AConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function ListarPreciosContenido(AConexion: TUniConnection;
  const AArticulo, ATarifa: string; AFecha: TDateTime):
  TArray<TPrecioSkuContenido>;
var
  oConsulta: TUniQuery;
  oPrecios: TList<TPrecioSkuContenido>;
  Precio: TPrecioSkuContenido;
begin
  oConsulta := TUniQuery.Create(nil);
  oPrecios := TList<TPrecioSkuContenido>.Create;
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT ' + CAMPOS_CONTENIDO +
      ', T.ESIMP_INCL_TAR, CASE WHEN ' +
      '(T.FECHA_DESDE_DTO_TAR IS NULL OR T.FECHA_DESDE_DTO_TAR <= :FECHA) ' +
      'AND (T.FECHA_HASTA_DTO_TAR IS NULL OR ' +
      'T.FECHA_HASTA_DTO_TAR >= :FECHA) ' +
      'THEN P.PRECIO_FINAL_ARTTAR ELSE P.PRECIO_SALIDA_ARTTAR END AS PVP ' +
      'FROM vi_articulos_contenido_neto C ' +
      'LEFT JOIN fza_articulos_tarifas P ON P.CODIGO_UNICO_ARTTAR = (' +
      SqlSeleccionPrecioTarifa('C.CODIGO_ART_SKU', 'C.CODIGO_UNIDAD_SKU',
        ':TARIFA', ':FECHA') + ') ' +
      'LEFT JOIN fza_tarifas T ON T.CODIGO_TAR_ARTTAR = :TARIFA ' +
      'WHERE C.CODIGO_ART_SKU = :ARTICULO ORDER BY C.CODIGO_UNIDAD_SKU';
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
    oConsulta.ParamByName('TARIFA').AsString := ATarifa;
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Precio := Default(TPrecioSkuContenido);
      Precio.Contenido := ContenidoDeConsulta(oConsulta);
      Precio.PrecioEnvase := -1;
      if not oConsulta.FieldByName('PVP').IsNull and
         (oConsulta.FieldByName('ESIMP_INCL_TAR').AsString = 'S') then
        Precio.PrecioEnvase := oConsulta.FieldByName('PVP').AsFloat;
      Precio.PrecioUnidad := CalcularPrecioPorUnidad(Precio.Contenido,
        Precio.PrecioEnvase);
      oPrecios.Add(Precio);
      oConsulta.Next;
    end;
    Result := oPrecios.ToArray;
  finally
    FreeAndNil(oPrecios);
    FreeAndNil(oConsulta);
  end;
end;

function ListarContenidoFactura(AConexion: TUniConnection;
  const ASerie, ANumero: string): TArray<TContenidoPrecioUnidad>;
var
  oConsulta: TUniQuery;
  oContenidos: TList<TContenidoPrecioUnidad>;
begin
  oConsulta := TUniQuery.Create(nil);
  oContenidos := TList<TContenidoPrecioUnidad>.Create;
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT DISTINCT ' + CAMPOS_CONTENIDO +
      'FROM vi_articulos_contenido_neto C ' +
      'JOIN fza_facturas_lineas F ' +
      'ON F.CODIGO_UNIDAD_FACLIN = C.CODIGO_UNIDAD_SKU ' +
      'WHERE F.SERIE_FAC_FACLIN = :SERIE AND F.NUMERO_FAC_FACLIN = :NUMERO ' +
      'AND C.ESPRECIO_UNIDAD_TICKET_ART = ''S''';
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oContenidos.Add(ContenidoDeConsulta(oConsulta));
      oConsulta.Next;
    end;
    Result := oContenidos.ToArray;
  finally
    FreeAndNil(oContenidos);
    FreeAndNil(oConsulta);
  end;
end;

procedure PrepararPreciosUnidadEtiquetas(ADatos: TDataSet);
var
  Precio: TPrecioPorUnidad;
begin
  ADatos.DisableControls;
  try
    ADatos.First;
    while not ADatos.Eof do
    begin
      if ADatos.FieldByName('ESPRECIO_UNIDAD_ART').AsString = 'S' then
      begin
        if ADatos.FieldByName('CONTENIDO_NETO').AsFloat <= 0 then
          raise EValidacionPrecioUnidad.CreateFmt(SErrorContenidoNetoAusente,
            [ADatos.FieldByName('CODIGO_UNIDAD_SKU').AsString]);
        if ADatos.FieldByName('FACTOR_PRECIO_UNIDAD').IsNull then
          raise EValidacionPrecioUnidad.CreateFmt(
            SErrorReferenciaContenidoIncompatible,
            [ADatos.FieldByName('CODIGO_UNIDAD_SKU').AsString]);
        if ADatos.FieldByName('ESIMP_INCL_TAR').AsString <> 'S' then
          raise EValidacionPrecioUnidad.CreateFmt(
            SErrorTarifaContenidoSinImpuestos,
            [ADatos.FieldByName('CODIGO_UNIDAD_SKU').AsString]);
        if ADatos.FieldByName('PRECIO_UNIDAD').IsNull then
          raise EValidacionPrecioUnidad.CreateFmt(SErrorPrecioContenidoAusente,
            [ADatos.FieldByName('CODIGO_UNIDAD_SKU').AsString]);
        Precio := Default(TPrecioPorUnidad);
        Precio.Estado := epuValido;
        Precio.Precio := ADatos.FieldByName('PRECIO_UNIDAD').AsFloat;
        Precio.Unidad := ADatos.FieldByName('UNIDAD_PRECIO').AsString;
        ADatos.Edit;
        ADatos.FieldByName('PRECIO_UNIDAD_TEXTO').AsString := Precio.Texto;
        ADatos.Post;
      end;
      ADatos.Next;
    end;
    ADatos.First;
  finally
    ADatos.EnableControls;
  end;
end;

end.
