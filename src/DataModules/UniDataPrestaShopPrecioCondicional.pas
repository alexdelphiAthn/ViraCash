{******************************************************************************}
{                                                                              }
{  Modulo:       UniDataPrestaShopPrecioCondicional                           }
{    Tipo:       SQL compartido                                                }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Construye el precio efectivo que PrestaShop debe publicar respetando     }
{    tanto la ventana de descuento como la condicion por propiedad.           }
{******************************************************************************}
unit UniDataPrestaShopPrecioCondicional;

interface

uses
  Uni;

const
  CMarcadorPrecioCondicionalPrestaShop = '{PRECIO_CONDICIONAL}';

function EsquemaDescuentoCondicionalDisponible(
  AConexion: TUniConnection): Boolean;
function AplicarPrecioCondicionalPrestaShop(
  const ASql, AAliasPrecio, AAliasTarifa, AExpresionArticulo,
  AExpresionSku: string;
  AUsarCondiciones: Boolean): string;

implementation

uses
  System.SysUtils;

function EsquemaDescuentoCondicionalDisponible(
  AConexion: TUniConnection): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  if Assigned(AConexion) then
  begin
    oConsulta := TUniQuery.Create(nil);
    try
      try
        oConsulta.Connection := AConexion;
        oConsulta.SQL.Text :=
          'SELECT COUNT(*) AS NUMERO_OBJETOS ' +
          'FROM information_schema.tables ' +
          'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ' +
          '(''fza_tarifas_descuento_condiciones'', ' +
          '''fza_tarifas_descuento_valores'')';
        oConsulta.Open;
        Result :=
          oConsulta.FieldByName('NUMERO_OBJETOS').AsInteger = 2;
      except
        // Una base anterior a la migracion conserva el descuento legado.
        Result := False;
      end;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function SqlValorEfectivoAplicable(
  const AAliasCondicion, AExpresionArticulo,
  AExpresionSku: string): string;

  function SqlDecisionValor(const AAliasValor: string): string;
  begin
    Result :=
      'EXISTS (SELECT 1 FROM fza_propiedades_valores pve ' +
      'WHERE pve.ID_PV_ARTPROP = ' + AAliasValor +
      '.ID_PV_ARTPROP AND pve.ID_PROP_PV = ' +
      AAliasCondicion + '.CODIGO_PROP_TARDCO ' +
      'AND pve.ESACTIVO_PV = ''S'') AND (' +
      '(' + AAliasCondicion + '.MODO_TARDCO = ''SOLO_SI'' AND ' +
      'EXISTS (SELECT 1 FROM fza_tarifas_descuento_valores dv ' +
      'WHERE dv.CODIGO_TAR_TARDVA = ' + AAliasCondicion +
      '.CODIGO_TAR_TARDCO AND dv.ID_PV_TARDVA = ' +
      AAliasValor + '.ID_PV_ARTPROP)) OR (' +
      AAliasCondicion + '.MODO_TARDCO = ''TODOS_EXCEPTO'' AND ' +
      'NOT EXISTS (SELECT 1 FROM fza_tarifas_descuento_valores dv ' +
      'WHERE dv.CODIGO_TAR_TARDVA = ' + AAliasCondicion +
      '.CODIGO_TAR_TARDCO AND dv.ID_PV_TARDVA = ' +
      AAliasValor + '.ID_PV_ARTPROP)))';
  end;

  function SqlValorArticulo: string;
  begin
    Result :=
      'EXISTS (SELECT 1 FROM fza_articulos_propiedades ep ' +
      'WHERE ep.CODIGO_ART_ART = ' + AExpresionArticulo +
      ' AND ep.CODIGO_PROP_ARTPROP = ' +
      AAliasCondicion + '.CODIGO_PROP_TARDCO ' +
      'AND COALESCE(ep.CODIGO_UNIDAD_ARTPROP, '''') = '''' ' +
      'AND ep.ID_PV_ARTPROP IS NOT NULL AND ' +
      SqlDecisionValor('ep') + ')';
  end;

  function SqlValorSku: string;
  begin
    Result :=
      'EXISTS (SELECT 1 FROM vi_articulos_propiedades_efectivas ep ' +
      'WHERE ep.CODIGO_ART = ' + AExpresionArticulo +
      ' AND ep.CODIGO_UNIDAD_SKU = ' +
      AExpresionSku + ' AND ep.CODIGO_PROP_ARTPROP = ' +
      AAliasCondicion + '.CODIGO_PROP_TARDCO ' +
      'AND ep.ID_PV_ARTPROP IS NOT NULL AND ' +
      SqlDecisionValor('ep') + ')';
  end;

begin
  if Trim(AExpresionSku) = '' then
    Result := SqlValorArticulo
  else
    Result :=
      '((COALESCE(' + AExpresionSku + ', '''') <> '''' AND ' +
      SqlValorSku + ') OR (COALESCE(' + AExpresionSku +
      ', '''') = '''' AND ' +
      SqlValorArticulo + '))';
end;

function SqlDescuentoAplicable(
  const AAliasTarifa, AExpresionArticulo,
  AExpresionSku: string): string;
var
  sCondicion: string;
begin
  sCondicion := 'dc';
  Result :=
    '(NOT EXISTS (SELECT 1 ' +
    'FROM fza_tarifas_descuento_condiciones dc0 ' +
    'WHERE dc0.CODIGO_TAR_TARDCO = ' + AAliasTarifa +
    '.CODIGO_TAR_ARTTAR) OR EXISTS (SELECT 1 ' +
    'FROM fza_tarifas_descuento_condiciones ' + sCondicion + ' ' +
    'WHERE ' + sCondicion + '.CODIGO_TAR_TARDCO = ' +
    AAliasTarifa + '.CODIGO_TAR_ARTTAR AND (' +
    sCondicion + '.MODO_TARDCO = ''TODOS'' OR (' +
    sCondicion + '.MODO_TARDCO IN ' +
    '(''SOLO_SI'', ''TODOS_EXCEPTO'') AND ' +
    sCondicion + '.POLITICA_SIN_VALOR_TARDCO = ''NO_APLICAR'' AND ' +
    'EXISTS (SELECT 1 FROM fza_propiedades pdc ' +
    'WHERE pdc.CODIGO_PROP_ARTPROP = ' + sCondicion +
    '.CODIGO_PROP_TARDCO AND pdc.ESACTIVO_PROP = ''S'' ' +
    'AND pdc.TIPO_VALOR_PROP = ''LISTA'') AND ' +
    'EXISTS (SELECT 1 FROM fza_tarifas_descuento_valores dv0 ' +
    'WHERE dv0.CODIGO_TAR_TARDVA = ' + sCondicion +
    '.CODIGO_TAR_TARDCO) AND NOT EXISTS (SELECT 1 ' +
    'FROM fza_tarifas_descuento_valores dvi ' +
    'LEFT JOIN fza_propiedades_valores pvi ' +
    'ON pvi.ID_PV_ARTPROP = dvi.ID_PV_TARDVA ' +
    'WHERE dvi.CODIGO_TAR_TARDVA = ' + sCondicion +
    '.CODIGO_TAR_TARDCO AND (pvi.ID_PV_ARTPROP IS NULL OR ' +
    'pvi.ID_PROP_PV <> ' + sCondicion + '.CODIGO_PROP_TARDCO OR ' +
    'COALESCE(pvi.ESACTIVO_PV, ''N'') <> ''S'')) AND ' +
    SqlValorEfectivoAplicable(
      sCondicion, AExpresionArticulo, AExpresionSku) + '))))';
end;

function SqlPrecioCondicional(
  const AAliasPrecio, AAliasTarifa, AExpresionArticulo,
  AExpresionSku: string;
  AUsarCondiciones: Boolean): string;
var
  sNoAplicable: string;
begin
  sNoAplicable :=
    '((' + AAliasTarifa + '.FECHA_DESDE_DTO_TAR IS NOT NULL AND ' +
    AAliasTarifa + '.FECHA_DESDE_DTO_TAR > CURDATE()) OR (' +
    AAliasTarifa + '.FECHA_HASTA_DTO_TAR IS NOT NULL AND ' +
    AAliasTarifa + '.FECHA_HASTA_DTO_TAR < CURDATE()))';
  if AUsarCondiciones then
    sNoAplicable :=
      '(' + sNoAplicable + ' OR NOT ' +
      SqlDescuentoAplicable(
        AAliasTarifa, AExpresionArticulo, AExpresionSku) + ')';
  Result :=
    'CASE WHEN ((COALESCE(' + AAliasPrecio +
    '.PORCENTAJE_DTO_ARTTAR, 0) <> 0 OR COALESCE(' +
    AAliasPrecio + '.PRECIO_DTO_ARTTAR, 0) <> 0) AND ' +
    sNoAplicable + ') THEN ' + AAliasPrecio +
    '.PRECIO_SALIDA_ARTTAR ELSE ' + AAliasPrecio +
    '.PRECIO_FINAL_ARTTAR END';
end;

function AplicarPrecioCondicionalPrestaShop(
  const ASql, AAliasPrecio, AAliasTarifa, AExpresionArticulo,
  AExpresionSku: string;
  AUsarCondiciones: Boolean): string;
begin
  if Pos(CMarcadorPrecioCondicionalPrestaShop, ASql) = 0 then
    raise EArgumentException.Create(
      'El SQL no contiene el marcador de precio de PrestaShop');
  Result := StringReplace(
    ASql,
    CMarcadorPrecioCondicionalPrestaShop,
    SqlPrecioCondicional(
      AAliasPrecio,
      AAliasTarifa,
      AExpresionArticulo,
      AExpresionSku,
      AUsarCondiciones),
    [rfReplaceAll]);
  if Pos(CMarcadorPrecioCondicionalPrestaShop, Result) > 0 then
    raise EArgumentException.Create(
      'No se pudo construir el precio condicional de PrestaShop');
end;

end.
