{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCajaStockRepositorio                                   }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptador UniDAC de las lecturas de stock usadas por Caja.                }
{******************************************************************************}
unit UniDataCajaStockRepositorio;

interface

uses
  Uni, Datasnap.DBClient,
  inLibCajaStockPersistenciaIntf;

function CrearCajaStockRepositorio(
  AConexion: TUniConnection): ICajaStockPersistencia;

procedure ValidarStockCobroCaja(AConexion: TUniConnection;
  ALineas: TClientDataSet; const AAlmacen: string);

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, inLibErroresBBDD, inLibMsgArticulos;

procedure ValidarStockCobroCaja(AConexion: TUniConnection;
  ALineas: TClientDataSet; const AAlmacen: string);
var
  Lineas: TClientDataSet;
  Consulta: TUniQuery;
  Cantidades: TDictionary<string, Double>;
  Claves: TStringList;
  Sku, Detalle: string;
  Cantidad, Disponible: Double;
begin
  if not AConexion.InTransaction then
    raise EInvalidOpException.Create(
      'La comprobación de stock requiere la transacción del cobro.');
  Lineas := TClientDataSet.Create(nil);
  Consulta := TUniQuery.Create(nil);
  Cantidades := TDictionary<string, Double>.Create;
  Claves := TStringList.Create;
  try
    Lineas.CloneCursor(ALineas, True);
    Lineas.First;
    while not Lineas.Eof do
    begin
      Sku := UpperCase(Trim(Lineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString));
      Cantidad := Lineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
      if (Sku <> '') and (Cantidad > 0) and
         SameText(Lineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString,
           'ESTANDAR') and
         (Trim(Lineas.FieldByName('VIENE_DE_DEPOSITO').AsString) = '') and
         (Trim(Lineas.FieldByName('ACCION_DEPOSITO').AsString) = '') then
      begin
        if not Cantidades.TryGetValue(Sku, Disponible) then
        begin
          Disponible := 0;
          Claves.Add(Sku);
        end;
        Cantidades.AddOrSetValue(Sku, Disponible + Cantidad);
      end;
      Lineas.Next;
    end;
    // Mismo orden entre cajas; los bloqueos duran hasta commit/rollback.
    Claves.Sort;
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT CANTIDAD_STK FROM fza_articulos_stockactual ' +
      'WHERE CODIGO_UNIDAD_STK = :SKU AND CODIGO_ALM_STK = :ALMACEN ' +
      'FOR UPDATE';
    for Sku in Claves do
    begin
      Consulta.ParamByName('SKU').AsString := Sku;
      Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
      Consulta.Open;
      Disponible := 0;
      while not Consulta.Eof do
      begin
        Disponible := Disponible +
          Consulta.FieldByName('CANTIDAD_STK').AsFloat;
        Consulta.Next;
      end;
      Consulta.Close;
      if Cantidades[Sku] > Disponible + 0.0000005 then
      begin
        Detalle := Format(SDetalleStockInsuficienteLinea,
          [Sku, FormatFloat('0.###', Cantidades[Sku]),
           FormatFloat('0.###', Disponible), AAlmacen]);
        raise EValidacionBBDD.CreateFmt(SErrorStockInsuficienteLinea,
          [Detalle]);
      end;
    end;
  finally
    Claves.Free;
    Cantidades.Free;
    Consulta.Free;
    Lineas.Free;
  end;
end;

type
  TCajaStockRepositorio = class(
    TInterfacedObject,
    ICajaStockPersistencia)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function ObtenerEstadoSku(
      const ACodigoSku: string): TEstadoSkuCajaStock;
    function ObtenerCantidadDisponible(
      const ACodigoSku, ACodigoAlmacen: string): Double;
    function SkuSinControlStock(const ACodigoSku: string): Boolean;
  end;

function CrearCajaStockRepositorio(
  AConexion: TUniConnection): ICajaStockPersistencia;
begin
  Result := TCajaStockRepositorio.Create(AConexion);
end;

constructor TCajaStockRepositorio.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TCajaStockRepositorio.ObtenerEstadoSku(
  const ACodigoSku: string): TEstadoSkuCajaStock;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TEstadoSkuCajaStock);
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT ESACTIVO_SKU ' +
      '  FROM fza_articulos_skus ' +
      ' WHERE CODIGO_UNIDAD_SKU = :SKU';
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    Result.Existe := not oConsulta.IsEmpty;
    if Result.Existe then
    begin
      Result.Activo :=
        oConsulta.FieldByName('ESACTIVO_SKU').AsString = 'S';
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCajaStockRepositorio.ObtenerCantidadDisponible(
  const ACodigoSku, ACodigoAlmacen: string): Double;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    if Trim(ACodigoAlmacen) <> '' then
    begin
      oConsulta.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS CANTIDAD ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU ' +
        '   AND CODIGO_ALM_STK = :ALMACEN';
      oConsulta.ParamByName('ALMACEN').AsString := ACodigoAlmacen;
    end
    else
    begin
      oConsulta.SQL.Text :=
        'SELECT COALESCE(SUM(CANTIDAD_STK), 0) AS CANTIDAD ' +
        '  FROM fza_articulos_stockactual ' +
        ' WHERE CODIGO_UNIDAD_STK = :SKU';
    end;
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    Result := oConsulta.FieldByName('CANTIDAD').AsFloat;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function TCajaStockRepositorio.SkuSinControlStock(
  const ACodigoSku: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT A.TIPO_ART ' +
      '  FROM fza_articulos_skus S ' +
      '  JOIN fza_articulos A ON A.CODIGO_ART_ART = S.CODIGO_ART_SKU ' +
      ' WHERE S.CODIGO_UNIDAD_SKU = :SKU';
    oConsulta.ParamByName('SKU').AsString := ACodigoSku;
    oConsulta.Open;
    Result := (not oConsulta.IsEmpty) and
      (Trim(oConsulta.FieldByName('TIPO_ART').AsString) <> '') and
      not SameText(Trim(oConsulta.FieldByName('TIPO_ART').AsString),
        'ESTANDAR');
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
