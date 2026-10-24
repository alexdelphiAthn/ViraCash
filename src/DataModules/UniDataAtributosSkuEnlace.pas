{
  Enlace de un valor de atributo a un SKU (fza_atributos_sku) sin duplicar
  el atributo. El maestro de valores admite dos ID_AV con el mismo texto en
  un atributo (p. ej. dos NEGRO de color): si el SKU ya tiene un valor de ese
  atributo, no se le anade otro. Con dos colores el SKU aparece dos veces en
  los cruces por atributo y el stock pivotado de caja sale duplicado
  (FZ-ISSUE-006).
}
unit UniDataAtributosSkuEnlace;

interface

uses
  Uni;

function AsegurarValorAtributoNormalizado(
  AQuery: TUniQuery;
  const AIdAtributo, AValor, ADescripcion, AUsuario: string;
  AOrden, AIdBasico: Integer): Integer;

procedure EnlazarValorAtributoSku(
  AQuery: TUniQuery;
  const ACodigoSku: string;
  AIdValor: Integer;
  const AUsuario: string);

implementation

uses
  System.SysUtils, Data.DB, inLibCodigosSinBarra;

const
  SQL_BUSCAR_VALOR_NORMALIZADO =
    'SELECT v.ID_AV FROM fza_atributos_valores v ' +
    ' WHERE v.ID_VA_AV = :IDVA ' +
    '   AND UPPER(TRIM(v.AV)) = UPPER(TRIM(:VALOR)) ' +
    ' ORDER BY (v.ESACTIVO_AV = ''S'') DESC, ' +
    '          EXISTS (SELECT 1 FROM fza_atributos_sku s ' +
    '                   WHERE s.ID_AV_SA = v.ID_AV) DESC, v.ID_AV ' +
    ' LIMIT 1';
  SQL_ASEGURAR_VALOR_NORMALIZADO =
    'INSERT INTO fza_atributos_valores ' +
    ' (ID_VA_AV, AV, DESCRIPCION_AV, ORDEN_AV, ID_ATB_AV, ' +
    '  ESACTIVO_AV, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    '  USUARIO_ALTA, USUARIO_MODIF) ' +
    'VALUES (:IDVA, :VALOR, :DESCRIPCION, :ORDEN, :BASICO, ' +
    '        ''S'', NOW(), NOW(), :USUARIO, :USUARIO) ' +
    'ON DUPLICATE KEY UPDATE ID_AV = LAST_INSERT_ID(ID_AV)';
  SQL_ENLAZAR_VALOR_ATRIBUTO_SKU =
    'INSERT IGNORE INTO fza_atributos_sku ' +
    '  (CODIGO_UNIDAD_SKU_SA, ID_AV_SA, INSTANTE_ALTA, ' +
    '   USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'SELECT :sku, av.ID_AV, NOW(), :u, NOW(), :u ' +
    '  FROM fza_atributos_valores av ' +
    ' WHERE av.ID_AV = :av ' +
    '   AND NOT EXISTS ( ' +
    '     SELECT 1 ' +
    '       FROM fza_atributos_sku ask ' +
    '       JOIN fza_atributos_valores avs ' +
    '         ON avs.ID_AV = ask.ID_AV_SA ' +
    '      WHERE ask.CODIGO_UNIDAD_SKU_SA = :sku ' +
    '        AND avs.ID_VA_AV = av.ID_VA_AV)';

// La búsqueda reutiliza el maestro incluso sin UQ_AV_VALOR. Con el índice
// de FZ-177, un alta concurrente devuelve el ID ganador sin error 1062.
// No confirma ni revierte la transacción de la pantalla que lo invoca.
function AsegurarValorAtributoNormalizado(
  AQuery: TUniQuery;
  const AIdAtributo, AValor, ADescripcion, AUsuario: string;
  AOrden, AIdBasico: Integer): Integer;
var
  Valor: string;
begin
  Valor := SinBarraSku(AValor);
  AQuery.Close;
  AQuery.SQL.Text := SQL_BUSCAR_VALOR_NORMALIZADO;
  AQuery.ParamByName('IDVA').AsString := Trim(AIdAtributo);
  AQuery.ParamByName('VALOR').AsString := Valor;
  AQuery.Open;
  Result := 0;
  if not AQuery.IsEmpty then
    Result := AQuery.FieldByName('ID_AV').AsInteger;
  AQuery.Close;
  if Result = 0 then
  begin
    AQuery.SQL.Text := SQL_ASEGURAR_VALOR_NORMALIZADO;
    AQuery.ParamByName('IDVA').AsString := Trim(AIdAtributo);
    AQuery.ParamByName('VALOR').AsString := Valor;
    AQuery.ParamByName('DESCRIPCION').AsString := Trim(ADescripcion);
    AQuery.ParamByName('ORDEN').AsInteger := AOrden;
    if AIdBasico > 0 then
      AQuery.ParamByName('BASICO').AsInteger := AIdBasico
    else
      AQuery.ParamByName('BASICO').Clear;
    AQuery.ParamByName('USUARIO').AsString := AUsuario;
    AQuery.ExecSQL;
    AQuery.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID_AV';
    AQuery.Open;
    Result := AQuery.FieldByName('ID_AV').AsInteger;
    AQuery.Close;
  end;
  // Un básico existente se conserva; solo se completa el dato que falta.
  if (Result > 0) and (AIdBasico > 0) then
  begin
    AQuery.SQL.Text :=
      'UPDATE fza_atributos_valores SET ID_ATB_AV = :BASICO, ' +
      ' INSTANTE_MODIF = NOW(), USUARIO_MODIF = :USUARIO ' +
      ' WHERE ID_AV = :ID AND ID_ATB_AV IS NULL';
    AQuery.ParamByName('BASICO').AsInteger := AIdBasico;
    AQuery.ParamByName('USUARIO').AsString := AUsuario;
    AQuery.ParamByName('ID').AsInteger := Result;
    AQuery.ExecSQL;
  end;
end;

procedure EnlazarValorAtributoSku(
  AQuery: TUniQuery;
  const ACodigoSku: string;
  AIdValor: Integer;
  const AUsuario: string);
begin
  if AIdValor > 0 then
  begin
    AQuery.SQL.Text := SQL_ENLAZAR_VALOR_ATRIBUTO_SKU;
    AQuery.ParamByName('sku').AsString := ACodigoSku;
    AQuery.ParamByName('av').AsInteger := AIdValor;
    AQuery.ParamByName('u').AsString := AUsuario;
    AQuery.ExecSQL;
  end;
end;

end.
