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
  System.Generics.Defaults, Data.DB, inLibErroresBBDD, inLibMsgArticulos,
  inLibMsgTrazabilidad;

type
  TCantidadesSerie = TDictionary<string, Double>;

procedure ValidarStockCobroCaja(AConexion: TUniConnection;
  ALineas: TClientDataSet; const AAlmacen: string);
var
  Lineas: TClientDataSet;
  Consulta: TUniQuery;
  Cantidades: TDictionary<string, Double>;
  Claves: TStringList;
  SeriesPorSku: TObjectDictionary<string, TCantidadesSerie>;
  Series: TCantidadesSerie;
  CampoSerie: TField;
  Sku, Detalle, Serie: string;
  Partida: TPair<string, Double>;
  Cantidad, Disponible: Double;
begin
  if not AConexion.InTransaction then
    raise EInvalidOpException.Create(
      STextoLaComprobacionDeStockRequiereLaTransaccionArticulos);
  Lineas := TClientDataSet.Create(nil);
  Consulta := TUniQuery.Create(nil);
  Cantidades := TDictionary<string, Double>.Create;
  SeriesPorSku := TObjectDictionary<string, TCantidadesSerie>.Create(
    [doOwnsValues]);
  Claves := TStringList.Create;
  try
    Lineas.CloneCursor(ALineas, True);
    CampoSerie := Lineas.FindField('ESSERIE_LOTE');
    Lineas.First;
    while not Lineas.Eof do
    begin
      Sku := UpperCase(Trim(Lineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString));
      Cantidad := Lineas.FieldByName('CANTIDAD_FACLIN').AsFloat;
      // FZ-ISSUE-1100: se valida el neto del SKU en la operación; las
      // líneas en negativo (unidades que vuelven) compensan las ventas.
      if (Sku <> '') and (Abs(Cantidad) > 0.0000005) and
         SameText(Lineas.FieldByName('TIPO_ARTICULO_FACLIN').AsString,
           'ESTANDAR') and
         (Trim(Lineas.FieldByName('VIENE_DE_DEPOSITO').AsString) = '') and
         (Trim(Lineas.FieldByName('ACCION_DEPOSITO').AsString) = '') then
      begin
        if not Cantidades.TryGetValue(Sku, Disponible) then
          Disponible := 0;
        Cantidades.AddOrSetValue(Sku, Disponible + Cantidad);
        if Assigned(CampoSerie) and SameText(CampoSerie.AsString, 'S') then
        begin
          Serie := Trim(Lineas.FieldByName('LOTE_FACLIN').AsString);
          if Serie <> '' then
          begin
            if not SeriesPorSku.TryGetValue(Sku, Series) then
            begin
              Series := TCantidadesSerie.Create(TIStringComparer.Ordinal);
              SeriesPorSku.Add(Sku, Series);
            end;
            Series.TryGetValue(Serie, Disponible);
            Series.AddOrSetValue(Serie, Disponible + Cantidad);
          end;
        end;
      end;
      Lineas.Next;
    end;
    // Un cambio de serie puede dejar el SKU a cero y vender otra partida.
    for Sku in Cantidades.Keys do
      if Cantidades[Sku] > 0.0000005 then
        Claves.Add(Sku)
      else if SeriesPorSku.TryGetValue(Sku, Series) then
        for Partida in Series do
          if Partida.Value > 0.0000005 then
          begin
            Claves.Add(Sku);
            Break;
          end;
    // Mismo orden entre cajas; los bloqueos duran hasta commit/rollback.
    Claves.Sort;
    Consulta.Connection := AConexion;
    Consulta.SQL.Text :=
      'SELECT LOTE_STK, CANTIDAD_STK FROM fza_articulos_stockactual ' +
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
      if SeriesPorSku.TryGetValue(Sku, Series) then
        for Partida in Series do
          if Partida.Value > 0.0000005 then
          begin
            Cantidad := 0;
            if Consulta.Locate('LOTE_STK', Partida.Key,
              [loCaseInsensitive]) then
              Cantidad := Consulta.FieldByName('CANTIDAD_STK').AsFloat;
            if Cantidad <= 0 then
              raise EValidacionBBDD.CreateFmt(SErrorSerieNoEnAlmacen,
                [Partida.Key, AAlmacen]);
            if Partida.Value > Cantidad + 0.0000005 then
              raise EValidacionBBDD.CreateFmt(SErrorCantidadLoteSuperaStock,
                [Partida.Key, FormatFloat('0.###', Partida.Value),
                 FormatFloat('0.###', Cantidad)]);
          end;
      Consulta.Close;
      if (Cantidades[Sku] > 0.0000005) and
         (Cantidades[Sku] > Disponible + 0.0000005) then
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
    SeriesPorSku.Free;
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
