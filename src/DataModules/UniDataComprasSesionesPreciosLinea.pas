{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesPreciosLinea                            }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coste y PVP de cada talla de una línea de sesión de compra, en            }
{    fza_compras_sesiones_lineas_skus_precios (FZ-ISSUE-638).                  }
{******************************************************************************}
unit UniDataComprasSesionesPreciosLinea;

interface

uses
  Uni,
  inLibComprasSesionesPreciosTalla;

// Una celda por color y talla de la línea, con sus precios si los tiene.
function LeerPreciosCeldasLinea(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer): TPreciosCeldasSesion;
// Sustituye los precios de la línea: la celda sin coste ni PVP propios
// vuelve a heredar los de la línea.
procedure GrabarPreciosCeldasLinea(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer;
  const APrecios: TPreciosCeldasSesion; const AUsuario: string);
// Alguna talla de la línea tiene coste o PVP propios.
function LineaTienePreciosCeldas(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer): Boolean;
// La línea destino (otro color del mismo artículo) toma los precios por
// talla de la origen; las tallas que la origen no tiene heredan.
procedure CopiarPreciosCeldasLinea(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALineaOrigen, ALineaDestino: Integer;
  const AUsuario: string);

implementation

uses
  System.SysUtils, Data.DB;

const
  // Todas las tallas, aunque no tengan cantidades. Las celdas existentes
  // conservan las filas de sesiones antiguas o sin sistema de tallas.
  SQL_CELDAS_PARA_PRECIOS =
    '(SELECT L.SERIE_SES_SESLIN AS SERIE_SES_SESCEL, ' +
    '        L.NUMERO_SES_SESLIN AS NUMERO_SES_SESCEL, ' +
    '        L.LINEA_SESLIN AS LINEA_SES_SESCEL, ' +
    '        COALESCE(F.ID_FILA_SESFIL, 1) AS ID_FILA_SES_SESCEL, ' +
    '        D.ID_AV_ACD AS ID_AV_PIVOT_SESCEL ' +
    '   FROM fza_compras_sesiones_lineas L ' +
    '   JOIN fza_atributos_conjuntos_det D ' +
    '     ON D.ID_AC_ACD = L.ID_AC_PIVOT_SESLIN ' +
    '   LEFT JOIN fza_compras_sesiones_lineas_filas F ' +
    '     ON F.SERIE_SES_SESFIL = L.SERIE_SES_SESLIN ' +
    '    AND F.NUMERO_SES_SESFIL = L.NUMERO_SES_SESLIN ' +
    '    AND F.LINEA_SES_SESFIL = L.LINEA_SESLIN ' +
    '  WHERE L.SERIE_SES_SESLIN = :SERIE ' +
    '    AND L.NUMERO_SES_SESLIN = :NUMERO ' +
    ' UNION ' +
    ' SELECT SERIE_SES_SESCEL, NUMERO_SES_SESCEL, LINEA_SES_SESCEL, ' +
    '        ID_FILA_SES_SESCEL, ID_AV_PIVOT_SESCEL ' +
    '   FROM fza_compras_sesiones_celdas ' +
    '  WHERE SERIE_SES_SESCEL = :SERIE ' +
    '    AND NUMERO_SES_SESCEL = :NUMERO) C ';
  SQL_LEER_PRECIOS_CELDAS =
    'SELECT C.ID_FILA_SES_SESCEL AS ID_FILA, ' +
    '       C.ID_AV_PIVOT_SESCEL AS ID_AV_PIVOT, ' +
    '       AVP.AV AS TALLA, ' +
    '       COALESCE(NULLIF((SELECT GROUP_CONCAT(AV2.AV SEPARATOR ''/'') ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '          JOIN fza_atributos_valores AV2 ' +
    '            ON AV2.ID_AV = FA.ID_AV_SESFILAT ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL), ''''), ' +
    '         L.COLOR_TEXTO_SESLIN, '''') AS COLOR, ' +
    '       P.PRECIO_COMPRA_SESLINSKU, P.PRECIO_VENTA_SESLINSKU ' +
    '  FROM ' + SQL_CELDAS_PARA_PRECIOS +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL ' +
    '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
    '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL ' +
    '  JOIN fza_atributos_valores AVP ' +
    '    ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
    '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    '    ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    '   AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    '   AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
    '   AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
    '   AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    ' WHERE C.SERIE_SES_SESCEL = :SERIE ' +
    '   AND C.NUMERO_SES_SESCEL = :NUMERO ' +
    '   AND C.LINEA_SES_SESCEL = :LINEA ' +
    ' GROUP BY C.SERIE_SES_SESCEL, C.NUMERO_SES_SESCEL, ' +
    '          C.LINEA_SES_SESCEL, C.ID_FILA_SES_SESCEL, ' +
    '          C.ID_AV_PIVOT_SESCEL, AVP.AV, AVP.ORDEN_AV, ' +
    '          L.COLOR_TEXTO_SESLIN, P.PRECIO_COMPRA_SESLINSKU, ' +
    '          P.PRECIO_VENTA_SESLINSKU ' +
    ' ORDER BY C.ID_FILA_SES_SESCEL, AVP.ORDEN_AV, AVP.AV';
  SQL_BORRAR_PRECIO_CELDA =
    'DELETE FROM fza_compras_sesiones_lineas_skus_precios ' +
    ' WHERE SERIE_SES_SESLINSKU = :SERIE ' +
    '   AND NUMERO_SES_SESLINSKU = :NUMERO ' +
    '   AND LINEA_SES_SESLINSKU = :LINEA ' +
    '   AND ID_FILA_SES_SESLINSKU = :FILA ' +
    '   AND ID_AV_PIVOT_SESLINSKU = :PIVOTE';
  SQL_INSERTAR_PRECIO_CELDA =
    'INSERT INTO fza_compras_sesiones_lineas_skus_precios ' +
    '  (SERIE_SES_SESLINSKU, NUMERO_SES_SESLINSKU, LINEA_SES_SESLINSKU, ' +
    '   ID_FILA_SES_SESLINSKU, ID_AV_PIVOT_SESLINSKU, ' +
    '   PRECIO_COMPRA_SESLINSKU, PRECIO_VENTA_SESLINSKU, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:SERIE, :NUMERO, :LINEA, :FILA, :PIVOTE, :COSTE, :PVP, ' +
    '        NOW(), :USUARIO, NOW(), :USUARIO)';
  SQL_LINEA_TIENE_PRECIOS =
    'SELECT COUNT(*) AS PRECIOS ' +
    '  FROM fza_compras_sesiones_lineas_skus_precios ' +
    ' WHERE SERIE_SES_SESLINSKU = :SERIE ' +
    '   AND NUMERO_SES_SESLINSKU = :NUMERO ' +
    '   AND LINEA_SES_SESLINSKU = :LINEA';
  SQL_BORRAR_PRECIOS_LINEA =
    'DELETE FROM fza_compras_sesiones_lineas_skus_precios ' +
    ' WHERE SERIE_SES_SESLINSKU = :SERIE ' +
    '   AND NUMERO_SES_SESLINSKU = :NUMERO ' +
    '   AND LINEA_SES_SESLINSKU = :LINEA';
  // Se casa por talla; si la origen tiene varias filas con esa talla
  // (formato distribuido) se prefiere la misma fila y, si no, la primera.
  SQL_COPIAR_PRECIOS_LINEA =
    'INSERT INTO fza_compras_sesiones_lineas_skus_precios ' +
    '  (SERIE_SES_SESLINSKU, NUMERO_SES_SESLINSKU, LINEA_SES_SESLINSKU, ' +
    '   ID_FILA_SES_SESLINSKU, ID_AV_PIVOT_SESLINSKU, ' +
    '   PRECIO_COMPRA_SESLINSKU, PRECIO_VENTA_SESLINSKU, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'SELECT DISTINCT C.SERIE_SES_SESCEL, C.NUMERO_SES_SESCEL, ' +
    '       C.LINEA_SES_SESCEL, C.ID_FILA_SES_SESCEL, ' +
    '       C.ID_AV_PIVOT_SESCEL, ' +
    '       P.PRECIO_COMPRA_SESLINSKU, P.PRECIO_VENTA_SESLINSKU, ' +
    '       NOW(), :USUARIO, NOW(), :USUARIO ' +
    '  FROM ' + SQL_CELDAS_PARA_PRECIOS +
    '  JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    '    ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    '   AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    '   AND P.LINEA_SES_SESLINSKU = :ORIGEN ' +
    '   AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    '   AND P.ID_FILA_SES_SESLINSKU = ' +
    '       (SELECT P2.ID_FILA_SES_SESLINSKU ' +
    '          FROM fza_compras_sesiones_lineas_skus_precios P2 ' +
    '         WHERE P2.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    '           AND P2.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    '           AND P2.LINEA_SES_SESLINSKU = :ORIGEN ' +
    '           AND P2.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    '         ORDER BY (P2.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL) ' +
    '                  DESC, P2.ID_FILA_SES_SESLINSKU ' +
    '         LIMIT 1) ' +
    ' WHERE C.SERIE_SES_SESCEL = :SERIE ' +
    '   AND C.NUMERO_SES_SESCEL = :NUMERO ' +
    '   AND C.LINEA_SES_SESCEL = :DESTINO';

function LeerPreciosCeldasLinea(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer): TPreciosCeldasSesion;
var
  oConsulta: TUniQuery;
  iCelda: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_LEER_PRECIOS_CELDAS;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.ParamByName('LINEA').AsInteger := ALinea;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      iCelda := Length(Result);
      SetLength(Result, iCelda + 1);
      Result[iCelda].IdFila := oConsulta.FieldByName('ID_FILA').AsInteger;
      Result[iCelda].IdAvPivot :=
        oConsulta.FieldByName('ID_AV_PIVOT').AsInteger;
      Result[iCelda].Color := oConsulta.FieldByName('COLOR').AsString;
      Result[iCelda].Talla := oConsulta.FieldByName('TALLA').AsString;
      Result[iCelda].TieneCoste :=
        not oConsulta.FieldByName('PRECIO_COMPRA_SESLINSKU').IsNull;
      Result[iCelda].Coste :=
        oConsulta.FieldByName('PRECIO_COMPRA_SESLINSKU').AsFloat;
      Result[iCelda].TienePvp :=
        not oConsulta.FieldByName('PRECIO_VENTA_SESLINSKU').IsNull;
      Result[iCelda].Pvp :=
        oConsulta.FieldByName('PRECIO_VENTA_SESLINSKU').AsFloat;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure GrabarPrecioCelda(AConsulta: TUniQuery;
  const ASerie, ANumero: string; ALinea: Integer;
  const APrecio: TPrecioCeldaSesion; const AUsuario: string);
begin
  AConsulta.SQL.Text := SQL_BORRAR_PRECIO_CELDA;
  AConsulta.ParamByName('SERIE').AsString := ASerie;
  AConsulta.ParamByName('NUMERO').AsString := ANumero;
  AConsulta.ParamByName('LINEA').AsInteger := ALinea;
  AConsulta.ParamByName('FILA').AsInteger := APrecio.IdFila;
  AConsulta.ParamByName('PIVOTE').AsInteger := APrecio.IdAvPivot;
  AConsulta.ExecSQL;
  if APrecio.TieneCoste or APrecio.TienePvp then
  begin
    AConsulta.SQL.Text := SQL_INSERTAR_PRECIO_CELDA;
    AConsulta.ParamByName('SERIE').AsString := ASerie;
    AConsulta.ParamByName('NUMERO').AsString := ANumero;
    AConsulta.ParamByName('LINEA').AsInteger := ALinea;
    AConsulta.ParamByName('FILA').AsInteger := APrecio.IdFila;
    AConsulta.ParamByName('PIVOTE').AsInteger := APrecio.IdAvPivot;
    // NULL = la talla hereda ese precio de la línea.
    AConsulta.ParamByName('COSTE').DataType := ftFloat;
    AConsulta.ParamByName('PVP').DataType := ftFloat;
    if APrecio.TieneCoste then
      AConsulta.ParamByName('COSTE').AsFloat := APrecio.Coste
    else
      AConsulta.ParamByName('COSTE').Clear;
    if APrecio.TienePvp then
      AConsulta.ParamByName('PVP').AsFloat := APrecio.Pvp
    else
      AConsulta.ParamByName('PVP').Clear;
    AConsulta.ParamByName('USUARIO').AsString := AUsuario;
    AConsulta.ExecSQL;
  end;
end;

procedure GrabarPreciosCeldasLinea(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer;
  const APrecios: TPreciosCeldasSesion; const AUsuario: string);
var
  oConsulta: TUniQuery;
  oPrecio: TPrecioCeldaSesion;
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      for oPrecio in APrecios do
        GrabarPrecioCelda(oConsulta, ASerie, ANumero, ALinea, oPrecio,
          AUsuario);
    finally
      FreeAndNil(oConsulta);
    end;
    if bTransaccionPropia then
      AConexion.Commit;
  except
    if bTransaccionPropia then
      AConexion.Rollback;
    raise;
  end;
end;

function LineaTienePreciosCeldas(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALinea: Integer): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_LINEA_TIENE_PRECIOS;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.ParamByName('LINEA').AsInteger := ALinea;
    oConsulta.Open;
    Result := oConsulta.FieldByName('PRECIOS').AsInteger > 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

procedure CopiarPreciosCeldasLinea(AConexion: TUniConnection;
  const ASerie, ANumero: string; ALineaOrigen, ALineaDestino: Integer;
  const AUsuario: string);
var
  oConsulta: TUniQuery;
  bTransaccionPropia: Boolean;
begin
  bTransaccionPropia := not AConexion.InTransaction;
  if bTransaccionPropia then
    AConexion.StartTransaction;
  try
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := AConexion;
      oConsulta.SQL.Text := SQL_BORRAR_PRECIOS_LINEA;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('LINEA').AsInteger := ALineaDestino;
      oConsulta.ExecSQL;
      oConsulta.SQL.Text := SQL_COPIAR_PRECIOS_LINEA;
      oConsulta.ParamByName('SERIE').AsString := ASerie;
      oConsulta.ParamByName('NUMERO').AsString := ANumero;
      oConsulta.ParamByName('ORIGEN').AsInteger := ALineaOrigen;
      oConsulta.ParamByName('DESTINO').AsInteger := ALineaDestino;
      oConsulta.ParamByName('USUARIO').AsString := AUsuario;
      oConsulta.ExecSQL;
    finally
      FreeAndNil(oConsulta);
    end;
    if bTransaccionPropia then
      AConexion.Commit;
  except
    if bTransaccionPropia then
      AConexion.Rollback;
    raise;
  end;
end;

end.
