{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesTarifas                                 }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Filas de tarifa que crea una sesión de compra al materializar             }
{    (FZ-ISSUE-638): lectura de las vigentes, grabación modificando las        }
{    existentes o como tarifa nueva desde una fecha, y vista previa del        }
{    patrón de precios antes de confirmar.                                     }
{******************************************************************************}
unit UniDataComprasSesionesTarifas;

interface

uses
  Uni,
  inLibComprasSesionesIntf,
  inLibComprasSesionesPreciosTalla;

// Filas activas del artículo en la tarifa que están vigentes en AFecha;
// de cada clave, la que empieza más tarde.
function LeerFilasVigentesTarifa(AConexion: TUniConnection;
  const ACodigoArticulo, ACodigoTarifa: string;
  AFecha: TDateTime): TFilasPrecioTarifa;
// Graba las filas del patrón. Con mteNuevaDesde y una fila vigente de la
// misma clave, esta se cierra el día anterior a la fecha y se inserta la
// nueva; con mteModificar se actualiza la vigente.
procedure GrabarFilasPrecioTarifa(AConexion: TUniConnection;
  const ACodigoArticulo, ACodigoTarifa, AUsuario: string;
  const AFilas: TFilasPrecioTarifa;
  const AOpciones: TOpcionesTarifaSesion);
// Vista previa, sin escribir: artículos de la sesión con precios por
// talla, color o SKU, o con filas vigentes en la tarifa.
function CalcularPreciosTarifaSesion(AConexion: TUniConnection;
  const ASerie, ANumero, ACodigoTarifa: string): TArticulosPreciosTarifa;
// Fecha con la que se leen las filas vigentes según la opción elegida.
function FechaVigenciaTarifaSesion(
  const AOpciones: TOpcionesTarifaSesion): TDateTime;
// Datos de un SKU de la sesión con el código que le da la materialización:
// ART/FILA/PESTANA/PIVOTE, sin los tramos vacíos.
function PrecioSkuSesion(const ACodigoArticulo, AValorFila, AValorPestana,
  AValorPivot: string; ACoste, APvp: Double): TPrecioSkuSesion;

implementation

uses
  System.SysUtils,
  inLibGeneracionSkus;

const
  SQL_FILAS_VIGENTES =
    'SELECT T.CODIGO_UNICO_ARTTAR, T.CODIGO_UNIDAD_ARTTAR, ' +
    '       T.FECHA_DESDE_ARTTAR, ' +
    '       COALESCE(T.PRECIO_COSTE_ARTTAR, 0) AS COSTE, ' +
    '       COALESCE(T.PRECIO_FINAL_ARTTAR, 0) AS PVP ' +
    '  FROM fza_articulos_tarifas T ' +
    ' WHERE T.CODIGO_ART_ARTTAR = :ART ' +
    '   AND T.CODIGO_TAR_ARTTAR = :TAR ' +
    '   AND T.ESACTIVO_ARTTAR = ''S'' ' +
    '   AND (T.FECHA_DESDE_ARTTAR IS NULL ' +
    '        OR T.FECHA_DESDE_ARTTAR <= :FECHA) ' +
    '   AND (T.FECHA_HASTA_ARTTAR IS NULL ' +
    '        OR T.FECHA_HASTA_ARTTAR >= :FECHA) ' +
    ' ORDER BY T.CODIGO_UNIDAD_ARTTAR, T.FECHA_DESDE_ARTTAR DESC, ' +
    '          T.CODIGO_UNICO_ARTTAR DESC';
  SQL_ACTUALIZAR_FILA =
    'UPDATE fza_articulos_tarifas ' +
    '   SET PRECIO_SALIDA_ARTTAR = :PVP, ' +
    '       PRECIO_FINAL_ARTTAR = :PVP, ' +
    '       PRECIO_COSTE_ARTTAR = :COSTE, ' +
    '       ESACTIVO_ARTTAR = ''S'', ' +
    '       INSTANTE_MODIF = NOW(), ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE CODIGO_UNICO_ARTTAR = :CODIGO';
  SQL_CERRAR_FILA =
    'UPDATE fza_articulos_tarifas ' +
    '   SET FECHA_HASTA_ARTTAR = :HASTA, ' +
    '       INSTANTE_MODIF = NOW(), ' +
    '       USUARIO_MODIF = :USUARIO ' +
    ' WHERE CODIGO_UNICO_ARTTAR = :CODIGO';
  SQL_INSERTAR_FILA =
    'INSERT INTO fza_articulos_tarifas ' +
    '  (CODIGO_ART_ARTTAR, CODIGO_UNIDAD_ARTTAR, CODIGO_TAR_ARTTAR, ' +
    '   ESACTIVO_ARTTAR, PRECIO_SALIDA_ARTTAR, PRECIO_FINAL_ARTTAR, ' +
    '   PRECIO_COSTE_ARTTAR, FECHA_DESDE_ARTTAR, ' +
    '   INSTANTE_ALTA, USUARIO_ALTA, INSTANTE_MODIF, USUARIO_MODIF) ' +
    'VALUES (:ART, :UNIDAD, :TAR, ''S'', :PVP, :PVP, :COSTE, :DESDE, ' +
    '        NOW(), :USUARIO, NOW(), :USUARIO)';
  // Una fila por SKU con cantidad de las líneas de matriz.
  SQL_PRECIOS_SKUS_SESION =
    'SELECT CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    '            THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    '            ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
    '       L.LINEA_SESLIN, L.TIPO_LINEA_SESLIN, ' +
    '       IFNULL(L.COLOR_TEXTO_SESLIN, '''') AS COLOR_TEXTO, ' +
    '       IFNULL(L.PESTANA_TEXTO_SESLIN, '''') AS PESTANA_TEXTO, ' +
    '       COALESCE((SELECT GROUP_CONCAT(AV2.AV SEPARATOR ''/'') ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '          JOIN fza_atributos_valores AV2 ' +
    '            ON AV2.ID_AV = FA.ID_AV_SESFILAT ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL), '''') ' +
    '       AS VAL_FILA, ' +
    '       COALESCE(AVP.AV, '''') AS VAL_PIVOT, ' +
    '       COALESCE(L.PRECIO_COMPRA_SESLIN, 0) * GREATEST(0, 1 - ' +
    '       IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0) / 100) ' +
    '       * (1 - IFNULL(L.PORCENTAJE_DTO_SESLIN, 0) / 100) ' +
    '       AS COSTE_LINEA, ' +
    '       COALESCE(L.PRECIO_VENTA_SESLIN, 0) AS PVP_LINEA, ' +
    '       COALESCE(P.PRECIO_COMPRA_SESLINSKU, L.PRECIO_COMPRA_SESLIN, 0) ' +
    '       * GREATEST(0, 1 - IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0) ' +
    '       / 100) * ' +
    '       (1 - IFNULL(L.PORCENTAJE_DTO_SESLIN, 0) / 100) AS COSTE_SKU, ' +
    '       COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN, 0) ' +
    '       AS PVP_SKU ' +
    '  FROM fza_compras_sesiones_lineas L ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    '  LEFT JOIN fza_compras_sesiones_celdas C ' +
    '    ON C.SERIE_SES_SESCEL = L.SERIE_SES_SESLIN ' +
    '   AND C.NUMERO_SES_SESCEL = L.NUMERO_SES_SESLIN ' +
    '   AND C.LINEA_SES_SESCEL = L.LINEA_SESLIN ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    '   AND L.TIPO_LINEA_SESLIN = ''MATRIZ'' ' +
    '  LEFT JOIN fza_atributos_valores AVP ' +
    '    ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
    '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    '    ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    '   AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    '   AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
    '   AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
    '   AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    ' WHERE L.SERIE_SES_SESLIN = :SERIE ' +
    '   AND L.NUMERO_SES_SESLIN = :NUMERO ' +
    '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    ' ORDER BY L.LINEA_SESLIN, C.ID_FILA_SES_SESCEL, AVP.ORDEN_AV, ' +
    '          AVP.AV';

type
  // Artículo de la vista previa mientras se recorren sus SKU.
  TArticuloVistaPrevia = record
    CodigoArticulo: string;
    Referencia: TFilaPrecioTarifa;
    Precios: TPreciosSkuSesion;
  end;

function FechaVigenciaTarifaSesion(
  const AOpciones: TOpcionesTarifaSesion): TDateTime;
begin
  Result := Date;
  if (AOpciones.Modo = mteNuevaDesde) and (AOpciones.FechaDesde > 0) then
    Result := Int(AOpciones.FechaDesde);
end;

function PrecioSkuSesion(const ACodigoArticulo, AValorFila, AValorPestana,
  AValorPivot: string; ACoste, APvp: Double): TPrecioSkuSesion;
var
  sFila: string;
  sTramoPestana: string;
begin
  // Mismo código que ProcesarSkuSesion: ART/FILA/PESTANA/PIVOTE
  // normalizados.
  sFila := NormalizarValorCodigoSku(AValorFila);
  sTramoPestana := '';
  if Trim(AValorPestana) <> '' then
    sTramoPestana := NormalizarValorCodigoSku(Trim(AValorPestana)) + '/';
  if sFila = '' then
  begin
    Result.ClaveColor := '';
    Result.CodigoSku := ACodigoArticulo + '/' + sTramoPestana +
      NormalizarValorCodigoSku(AValorPivot);
  end
  else
  begin
    Result.ClaveColor := ACodigoArticulo + '/' + sFila;
    Result.CodigoSku := Result.ClaveColor + '/' + sTramoPestana +
      NormalizarValorCodigoSku(AValorPivot);
  end;
  Result.Talla := Trim(AValorPivot);
  Result.Coste := ACoste;
  Result.Pvp := APvp;
end;

function LeerFilasVigentesTarifa(AConexion: TUniConnection;
  const ACodigoArticulo, ACodigoTarifa: string;
  AFecha: TDateTime): TFilasPrecioTarifa;
var
  oConsulta: TUniQuery;
  sClave: string;
  sAnterior: string;
  bPrimera: Boolean;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_FILAS_VIGENTES;
    oConsulta.ParamByName('ART').AsString := ACodigoArticulo;
    oConsulta.ParamByName('TAR').AsString := ACodigoTarifa;
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.Open;
    bPrimera := True;
    sAnterior := '';
    while not oConsulta.Eof do
    begin
      sClave := Trim(oConsulta.FieldByName('CODIGO_UNIDAD_ARTTAR').AsString);
      // Viene ordenado: la primera de cada clave es la que manda.
      if bPrimera or not SameText(sClave, sAnterior) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)].Clave := sClave;
        Result[High(Result)].Coste :=
          oConsulta.FieldByName('COSTE').AsFloat;
        Result[High(Result)].Pvp := oConsulta.FieldByName('PVP').AsFloat;
      end;
      bPrimera := False;
      sAnterior := sClave;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

// Fila vigente en AFecha con la misma clave: código y fecha desde.
function BuscarFilaVigente(AConsulta: TUniQuery;
  const ACodigoArticulo, ACodigoTarifa, AClave: string; AFecha: TDateTime;
  out AFechaDesde: TDateTime): Integer;
begin
  Result := 0;
  AFechaDesde := 0;
  AConsulta.SQL.Text := SQL_FILAS_VIGENTES;
  AConsulta.ParamByName('ART').AsString := ACodigoArticulo;
  AConsulta.ParamByName('TAR').AsString := ACodigoTarifa;
  AConsulta.ParamByName('FECHA').AsDate := AFecha;
  AConsulta.Open;
  try
    while (Result = 0) and not AConsulta.Eof do
    begin
      if SameText(Trim(AConsulta.FieldByName(
           'CODIGO_UNIDAD_ARTTAR').AsString), Trim(AClave)) then
      begin
        Result := AConsulta.FieldByName('CODIGO_UNICO_ARTTAR').AsInteger;
        if not AConsulta.FieldByName('FECHA_DESDE_ARTTAR').IsNull then
          AFechaDesde :=
            AConsulta.FieldByName('FECHA_DESDE_ARTTAR').AsDateTime;
      end;
      AConsulta.Next;
    end;
  finally
    AConsulta.Close;
  end;
end;

procedure EjecutarActualizarFila(AConsulta: TUniQuery; ACodigo: Integer;
  const AFila: TFilaPrecioTarifa; const AUsuario: string);
begin
  AConsulta.SQL.Text := SQL_ACTUALIZAR_FILA;
  AConsulta.ParamByName('PVP').AsFloat := AFila.Pvp;
  AConsulta.ParamByName('COSTE').AsFloat := AFila.Coste;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('CODIGO').AsInteger := ACodigo;
  AConsulta.ExecSQL;
end;

procedure EjecutarInsertarFila(AConsulta: TUniQuery;
  const ACodigoArticulo, ACodigoTarifa: string;
  const AFila: TFilaPrecioTarifa; ADesde: TDateTime;
  const AUsuario: string);
begin
  AConsulta.SQL.Text := SQL_INSERTAR_FILA;
  AConsulta.ParamByName('ART').AsString := ACodigoArticulo;
  AConsulta.ParamByName('UNIDAD').AsString := AFila.Clave;
  AConsulta.ParamByName('TAR').AsString := ACodigoTarifa;
  AConsulta.ParamByName('PVP').AsFloat := AFila.Pvp;
  AConsulta.ParamByName('COSTE').AsFloat := AFila.Coste;
  AConsulta.ParamByName('DESDE').AsDate := ADesde;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ExecSQL;
end;

procedure EjecutarCerrarFila(AConsulta: TUniQuery; ACodigo: Integer;
  AHasta: TDateTime; const AUsuario: string);
begin
  AConsulta.SQL.Text := SQL_CERRAR_FILA;
  AConsulta.ParamByName('HASTA').AsDate := AHasta;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('CODIGO').AsInteger := ACodigo;
  AConsulta.ExecSQL;
end;

procedure GrabarFilasPrecioTarifa(AConexion: TUniConnection;
  const ACodigoArticulo, ACodigoTarifa, AUsuario: string;
  const AFilas: TFilasPrecioTarifa;
  const AOpciones: TOpcionesTarifaSesion);
var
  oConsulta: TUniQuery;
  oFila: TFilaPrecioTarifa;
  dtDesde: TDateTime;
  dtVigente: TDateTime;
  iCodigo: Integer;
begin
  dtDesde := FechaVigenciaTarifaSesion(AOpciones);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    for oFila in AFilas do
    begin
      iCodigo := BuscarFilaVigente(oConsulta, ACodigoArticulo,
        ACodigoTarifa, oFila.Clave, dtDesde, dtVigente);
      if iCodigo = 0 then
        EjecutarInsertarFila(oConsulta, ACodigoArticulo, ACodigoTarifa,
          oFila, dtDesde, AUsuario)
      else if (AOpciones.Modo = mteNuevaDesde) and
              (Int(dtVigente) < dtDesde) then
      begin
        // La fila anterior se conserva hasta el día antes de la nueva.
        EjecutarCerrarFila(oConsulta, iCodigo, dtDesde - 1, AUsuario);
        EjecutarInsertarFila(oConsulta, ACodigoArticulo, ACodigoTarifa,
          oFila, dtDesde, AUsuario);
      end
      else
        EjecutarActualizarFila(oConsulta, iCodigo, oFila, AUsuario);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function IndiceArticulo(const AArticulos: TArray<TArticuloVistaPrevia>;
  const ACodigoArticulo: string): Integer;
var
  iArticulo: Integer;
begin
  Result := -1;
  iArticulo := 0;
  while (Result = -1) and (iArticulo <= High(AArticulos)) do
  begin
    if SameText(AArticulos[iArticulo].CodigoArticulo, ACodigoArticulo) then
      Result := iArticulo;
    Inc(iArticulo);
  end;
end;

function LeerArticulosVistaPrevia(AConexion: TUniConnection;
  const ASerie, ANumero: string): TArray<TArticuloVistaPrevia>;
var
  oConsulta: TUniQuery;
  sArticulo: string;
  sFila: string;
  iArticulo: Integer;
begin
  SetLength(Result, 0);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := SQL_PRECIOS_SKUS_SESION;
    oConsulta.ParamByName('SERIE').AsString := ASerie;
    oConsulta.ParamByName('NUMERO').AsString := ANumero;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      sArticulo := Trim(oConsulta.FieldByName('CODIGO_ART').AsString);
      iArticulo := IndiceArticulo(Result, sArticulo);
      if (iArticulo = -1) and (sArticulo <> '') then
      begin
        iArticulo := Length(Result);
        SetLength(Result, iArticulo + 1);
        Result[iArticulo].CodigoArticulo := sArticulo;
        Result[iArticulo].Referencia.Clave := '';
        Result[iArticulo].Referencia.Coste :=
          oConsulta.FieldByName('COSTE_LINEA').AsFloat;
        Result[iArticulo].Referencia.Pvp :=
          oConsulta.FieldByName('PVP_LINEA').AsFloat;
        Result[iArticulo].Precios := nil;
      end;
      if (iArticulo >= 0) and
         (oConsulta.FieldByName('VAL_PIVOT').AsString <> '') and
         (oConsulta.FieldByName('PVP_SKU').AsFloat > 0) then
      begin
        sFila := oConsulta.FieldByName('VAL_FILA').AsString;
        if sFila = '' then
          sFila := oConsulta.FieldByName('COLOR_TEXTO').AsString;
        Result[iArticulo].Precios := Result[iArticulo].Precios + [
          PrecioSkuSesion(sArticulo, sFila,
            oConsulta.FieldByName('PESTANA_TEXTO').AsString,
            oConsulta.FieldByName('VAL_PIVOT').AsString,
            oConsulta.FieldByName('COSTE_SKU').AsFloat,
            oConsulta.FieldByName('PVP_SKU').AsFloat)];
      end;
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CalcularPreciosTarifaSesion(AConexion: TUniConnection;
  const ASerie, ANumero, ACodigoTarifa: string): TArticulosPreciosTarifa;
var
  oArticulos: TArray<TArticuloVistaPrevia>;
  oArticulo: TArticuloVistaPrevia;
  oVigentes: TFilasPrecioTarifa;
  oPrecios: TArticuloPreciosTarifa;
begin
  SetLength(Result, 0);
  if Trim(ACodigoTarifa) <> '' then
  begin
    oArticulos := LeerArticulosVistaPrevia(AConexion, ASerie, ANumero);
    for oArticulo in oArticulos do
    begin
      oVigentes := LeerFilasVigentesTarifa(AConexion,
        oArticulo.CodigoArticulo, ACodigoTarifa, Date);
      oPrecios.CodigoArticulo := oArticulo.CodigoArticulo;
      oPrecios.TieneVigentes := Length(oVigentes) > 0;
      oPrecios.Filas := CalcularFilasPrecioTarifa(oArticulo.CodigoArticulo,
        oArticulo.Precios, oArticulo.Referencia, oVigentes);
      // Sin PVP la sesión no toca la tarifa del artículo.
      if (oPrecios.Filas[0].Pvp > 0) and
         (TienePreciosPorTalla(oPrecios.Filas) or oPrecios.TieneVigentes) then
        Result := Result + [oPrecios];
    end;
  end;
end;

end.
