{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesRenumeracion                            }
{    Tipo:       Módulo de datos                                               }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Renumera de 10 en 10 las líneas de una sesión de compra siguiendo el      }
{    orden artículo, color y línea, y arrastra las tablas que cuelgan de la    }
{    línea (FZ-ISSUE-416).                                                     }
{******************************************************************************}
unit UniDataComprasSesionesRenumeracion;

interface

uses
  Uni, inLibComprasSesionesIntf;

// Devuelve los cambios aplicados (vacío si las líneas ya estaban en orden).
// Usa la transacción abierta o abre una propia.
function RenumerarLineasSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string): TCambiosLineaSesion;

implementation

uses
  System.SysUtils, Data.DB, inLibComprasSesionesReglas;

type
  TTablaLineaSesion = record
    Tabla: string;
    Serie: string;
    Numero: string;
    Linea: string;
  end;

const
  TABLAS_LINEA: array[0..6] of TTablaLineaSesion = (
    (Tabla: 'fza_compras_sesiones_lineas'; Serie: 'SERIE_SES_SESLIN';
     Numero: 'NUMERO_SES_SESLIN'; Linea: 'LINEA_SESLIN'),
    (Tabla: 'fza_compras_sesiones_celdas'; Serie: 'SERIE_SES_SESCEL';
     Numero: 'NUMERO_SES_SESCEL'; Linea: 'LINEA_SES_SESCEL'),
    (Tabla: 'fza_compras_sesiones_fotos'; Serie: 'SERIE_SES_CSF';
     Numero: 'NUMERO_SES_CSF'; Linea: 'LINEA_CSF'),
    (Tabla: 'fza_compras_sesiones_lineas_filas';
     Serie: 'SERIE_SES_SESFIL'; Numero: 'NUMERO_SES_SESFIL';
     Linea: 'LINEA_SES_SESFIL'),
    (Tabla: 'fza_compras_sesiones_lineas_filas_atr';
     Serie: 'SERIE_SES_SESFILAT'; Numero: 'NUMERO_SES_SESFILAT';
     Linea: 'LINEA_SES_SESFILAT'),
    (Tabla: 'fza_compras_sesiones_lineas_props';
     Serie: 'SERIE_SES_SESLPROP'; Numero: 'NUMERO_SES_SESLPROP';
     Linea: 'LINEA_SES_SESLPROP'),
    (Tabla: 'fza_compras_sesiones_lineas_skus_precios';
     Serie: 'SERIE_SES_SESLINSKU'; Numero: 'NUMERO_SES_SESLINSKU';
     Linea: 'LINEA_SES_SESLINSKU'));
  SQL_LINEAS_ORDEN =
    'SELECT LINEA_SESLIN, ' +
    '       COALESCE(NULLIF(TRIM(CODIGO_ART_TENTATIVO_SESLIN), ''''), ' +
    '                TRIM(COALESCE(CODIGO_ART_REUSAR_SESLIN, ''''))) ' +
    '         AS ARTICULO, ' +
    '       TRIM(COALESCE(COLOR_TEXTO_SESLIN, '''')) AS COLOR ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s AND NUMERO_SES_SESLIN = :n ' +
    ' ORDER BY LINEA_SESLIN';
  // Filas hijas de líneas que ya no existen.
  SQL_LINEAS_SIN_DUENO =
    'SELECT DISTINCT h.%3:s AS LINEA FROM %0:s h ' +
    ' WHERE h.%1:s = :s AND h.%2:s = :n AND h.%3:s > 0 ' +
    '   AND NOT EXISTS (SELECT 1 FROM fza_compras_sesiones_lineas l ' +
    '        WHERE l.SERIE_SES_SESLIN = h.%1:s ' +
    '          AND l.NUMERO_SES_SESLIN = h.%2:s ' +
    '          AND l.LINEA_SESLIN = h.%3:s)';
  SQL_APARTAR =
    'UPDATE %0:s SET %3:s = :destino ' +
    ' WHERE %1:s = :s AND %2:s = :n AND %3:s = :origen';
  SQL_ASENTAR =
    'UPDATE %0:s SET %3:s = -%3:s ' +
    ' WHERE %1:s = :s AND %2:s = :n AND %3:s < 0';
  SQL_CONTADOR =
    'UPDATE fza_compras_sesiones SET CONTADOR_LINEAS_SES = :c ' +
    ' WHERE SERIE_SES = :s AND NUMERO_SES = :n';

function SqlTabla(const APlantilla: string;
  const ATabla: TTablaLineaSesion): string;
begin
  Result := Format(APlantilla,
    [ATabla.Tabla, ATabla.Serie, ATabla.Numero, ATabla.Linea]);
end;

function LeerLineasOrden(AConsulta: TUniQuery;
  const ASerie, ANumero: string): TArray<TLineaOrdenSesion>;
var
  oLinea: TLineaOrdenSesion;
begin
  Result := nil;
  AConsulta.SQL.Text := SQL_LINEAS_ORDEN;
  AConsulta.ParamByName('s').AsString := ASerie;
  AConsulta.ParamByName('n').AsString := ANumero;
  AConsulta.Open;
  while not AConsulta.Eof do
  begin
    oLinea.Linea := AConsulta.FieldByName('LINEA_SESLIN').AsInteger;
    oLinea.Articulo := AConsulta.FieldByName('ARTICULO').AsString;
    oLinea.Color := AConsulta.FieldByName('COLOR').AsString;
    Result := Result + [oLinea];
    AConsulta.Next;
  end;
  AConsulta.Close;
end;

// Un número con filas hijas huérfanas no se reutiliza: la línea que lo
// recibiera heredaría fotos o propiedades de otra ya borrada.
function LeerNumerosReservados(AConsulta: TUniQuery;
  const ASerie, ANumero: string): TArray<Integer>;
var
  i: Integer;
begin
  Result := nil;
  for i := 1 to High(TABLAS_LINEA) do
  begin
    AConsulta.SQL.Text := SqlTabla(SQL_LINEAS_SIN_DUENO, TABLAS_LINEA[i]);
    AConsulta.ParamByName('s').AsString := ASerie;
    AConsulta.ParamByName('n').AsString := ANumero;
    AConsulta.Open;
    while not AConsulta.Eof do
    begin
      Result := Result + [AConsulta.FieldByName('LINEA').AsInteger];
      AConsulta.Next;
    end;
    AConsulta.Close;
  end;
end;

// Dos pasos para no chocar con la clave primaria cuando dos líneas
// intercambian su número: primero al negativo del destino, luego a positivo.
procedure AplicarCambios(AConsulta: TUniQuery;
  const ASerie, ANumero: string; const ACambios: TCambiosLineaSesion;
  const AReservados: TArray<Integer>);
var
  oCambio: TCambioLineaSesion;
  i, iContador, iReservado: Integer;
begin
  iContador := 0;
  for i := 0 to High(TABLAS_LINEA) do
  begin
    AConsulta.SQL.Text := SqlTabla(SQL_APARTAR, TABLAS_LINEA[i]);
    for oCambio in ACambios do
    begin
      if oCambio.Antes <> oCambio.Despues then
      begin
        AConsulta.ParamByName('s').AsString := ASerie;
        AConsulta.ParamByName('n').AsString := ANumero;
        AConsulta.ParamByName('origen').AsInteger := oCambio.Antes;
        AConsulta.ParamByName('destino').AsInteger := -oCambio.Despues;
        AConsulta.ExecSQL;
      end;
    end;
  end;
  for i := 0 to High(TABLAS_LINEA) do
  begin
    AConsulta.SQL.Text := SqlTabla(SQL_ASENTAR, TABLAS_LINEA[i]);
    AConsulta.ParamByName('s').AsString := ASerie;
    AConsulta.ParamByName('n').AsString := ANumero;
    AConsulta.ExecSQL;
  end;
  for oCambio in ACambios do
  begin
    if oCambio.Despues > iContador then
      iContador := oCambio.Despues;
  end;
  for iReservado in AReservados do
  begin
    if iReservado > iContador then
      iContador := iReservado;
  end;
  AConsulta.SQL.Text := SQL_CONTADOR;
  AConsulta.ParamByName('c').AsInteger := iContador;
  AConsulta.ParamByName('s').AsString := ASerie;
  AConsulta.ParamByName('n').AsString := ANumero;
  AConsulta.ExecSQL;
end;

function RenumerarLineasSesion(AConexion: TUniConnection;
  const ASerie, ANumero: string): TCambiosLineaSesion;
var
  oConsulta: TUniQuery;
  aReservados: TArray<Integer>;
  bTransaccionPropia: Boolean;
begin
  Result := nil;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    aReservados := LeerNumerosReservados(oConsulta, ASerie, ANumero);
    Result := RenumeracionLineasSesion(
      LeerLineasOrden(oConsulta, ASerie, ANumero), aReservados);
    if Length(Result) > 0 then
    begin
      bTransaccionPropia := not AConexion.InTransaction;
      if bTransaccionPropia then
        AConexion.StartTransaction;
      try
        AplicarCambios(oConsulta, ASerie, ANumero, Result, aReservados);
        if bTransaccionPropia then
          AConexion.Commit;
      except
        if bTransaccionPropia then
          AConexion.Rollback;
        raise;
      end;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
