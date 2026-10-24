{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCriptoCurr                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente de la API pública de CoinGecko v3.                                }
{    Consulta precios y datos de mercado de criptomonedas.                     }
{******************************************************************************}
unit inLibCriptoCurr;

{
  ============================================================
  CoinGeckoAPI.pas
  Librería para consumir la API pública de CoinGecko v3
  https://api.coingecko.com/api/v3

  Sin API Key para uso básico (plan free).
  Rate limit free: ~30 llamadas/minuto.

  Autor  : Generado para ViraCash
  Delphi : 10.x / 11 / 12 (VCL y FMX)
  Requiere: System.Net.HttpClient, System.JSON
  ============================================================

  USO RÁPIDO:
  -----------
    var
      API   : TCoinGeckoAPI;
      Precio: Double;
    begin
      API := TCoinGeckoAPI.Create;
      try
        Precio := API.GetPrice('bitcoin', 'eur');
        // Presentar el precio desde el formulario consumidor.
      finally
        FreeAndNil(API);
      end;
    end;

  IDs DE MONEDAS más comunes:
    bitcoin, ethereum, tether, binancecoin, solana,
    ripple, cardano, dogecoin, polkadot, litecoin,
    chainlink, stellar, uniswap, monero, shiba-inu

  ENDPOINTS DISPONIBLES:
  ----------------------
    GetPrice(CoinID, VsCurrency)              → precio actual (float)
    GetPrices(CoinIDs, VsCurrencies)          → varios coins/currencies
    GetCoinDetail(CoinID)                     → info completa del coin
    GetMarkets(VsCurrency, Limit)             → ranking de mercado
    GetHistoricalPrice(CoinID, Date, Cur)     → precio en fecha concreta
    GetMarketChart(CoinID, VsCurrency, Days)  → histórico OHLC
    GetTopCoins(VsCurrency, Limit)            → top N coins con precios
    SearchCoins(Query)                        → buscar coin por nombre
    GetSupportedCurrencies                    → divisas fiat soportadas
    Ping                                      → test de conectividad
  ============================================================
}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.JSON,
  System.Generics.Collections,
  System.DateUtils,
  System.Math, System.NetConsts;

const
  COINGECKO_BASE_URL  = 'https://api.coingecko.com/api/v3';
  // ms (CoinGecko puede tardar más que Frankfurter)
  COINGECKO_TIMEOUT   = 15000;

type
  // ──────────────────────────────────────────────────────────
  ECoinGeckoError = class(Exception);

  // ──────────────────────────────────────────────────────────
  // Precio simple de un coin en una o varias currencies
  // ──────────────────────────────────────────────────────────
  TCoinPrice = record
    CoinID         : string;
    Prices         : TDictionary<string, Double>;  // currency → precio
    MarketCaps     : TDictionary<string, Double>;
    Vol24h         : TDictionary<string, Double>;
    Change24h      : TDictionary<string, Double>;  // % cambio 24h
    LastUpdated    : TDateTime;

    function GetPrice(const ACurrency: string): Double;
    function GetChange24h(const ACurrency: string): Double;
  end;

  // ──────────────────────────────────────────────────────────
  // Entrada del ranking de mercado
  // ──────────────────────────────────────────────────────────
  TCoinMarket = record
    ID                   : string;
    Symbol               : string;
    Name                 : string;
    CurrentPrice         : Double;
    MarketCap            : Double;
    MarketCapRank        : Integer;
    TotalVolume          : Double;
    High24h              : Double;
    Low24h               : Double;
    PriceChange24h       : Double;
    PriceChangePct24h    : Double;
    CirculatingSupply    : Double;
    TotalSupply          : Double;
    ATH                  : Double;  // All Time High
    ATHDate              : TDate;
    ATL                  : Double;  // All Time Low
    ATLDate              : TDate;
    LastUpdated          : TDateTime;
    ImageURL             : string;
  end;

  // ──────────────────────────────────────────────────────────
  // Detalle completo de una moneda
  // ──────────────────────────────────────────────────────────
  TCoinDetail = record
    ID              : string;
    Symbol          : string;
    Name            : string;
    Description     : string;   // en inglés
    HomepageURL     : string;
    GenesisDate     : string;
    MarketCapRank   : Integer;
    CoingeckoRank   : Integer;
    CoingeckoScore  : Double;
    DeveloperScore  : Double;
    CommunityScore  : Double;
    LiquidityScore  : Double;
    PublicInterest  : Double;
    // Precios actuales (map currency → valor)
    CurrentPrices   : TDictionary<string, Double>;
    MarketCaps      : TDictionary<string, Double>;
    TotalVolumes    : TDictionary<string, Double>;
  end;

  // ──────────────────────────────────────────────────────────
  // Punto de la serie histórica (precio + marketcap + volumen)
  // ──────────────────────────────────────────────────────────
  TChartPoint = record
    Timestamp  : TDateTime;
    Price      : Double;
    MarketCap  : Double;
    Volume     : Double;
  end;

  // ──────────────────────────────────────────────────────────
  // Resultado de búsqueda
  // ──────────────────────────────────────────────────────────
  TCoinSearchResult = record
    ID     : string;
    Name   : string;
    Symbol : string;
    Rank   : Integer;
    Thumb  : string;  // URL miniatura
  end;

  // ──────────────────────────────────────────────────────────
  // Clase principal
  // ──────────────────────────────────────────────────────────
  TCoinGeckoAPI = class
  private
    FHttpClient : THTTPClient;
    FBaseURL    : string;
    FTimeout    : Integer;
    FApiKey     : string;   // opcional: clave Pro para más rate limit
    FLastError  : string;

    function  DoGet(const AURL: string): string;
    function  BuildURL(const APath: string;
                       const AParams: array of string): string;
    function  SafeDouble(AObj: TJSONObject; const AKey: string): Double;
    function  SafeInt(AObj: TJSONObject; const AKey: string): Integer;
    function  SafeStr(AObj: TJSONObject; const AKey: string): string;
    function  UnixToDateTime(AUnix: Int64): TDateTime;

  public
    constructor Create(const AApiKey: string = '';
                       const ABaseURL: string = COINGECKO_BASE_URL);
    destructor  Destroy; override;

    // ── Test ──────────────────────────────────────────────
    /// Devuelve True si la API responde correctamente
    function Ping: Boolean;

    // ── Precios simples ───────────────────────────────────

    /// Precio actual de un coin en una currency (eur, usd, gbp...)
    function GetPrice(const ACoinID, AVsCurrency: string): Double;

    /// Precios de varios coins en varias currencies a la vez
    /// ACoinIDs    = ['bitcoin','ethereum']
    /// ACurrencies = ['eur','usd']
    function GetPrices(const ACoinIDs: TArray<string>;
                       const ACurrencies: TArray<string>;
                       AIncludeMarketCap : Boolean = False;
                       AInclude24hVol    : Boolean = False;
                       AInclude24hChange : Boolean = False): TArray<TCoinPrice>;

    /// Top N coins con precio, market cap y cambio 24h
    function GetTopCoins(const AVsCurrency: string = 'eur';
                         ALimit: Integer = 10): TArray<TCoinMarket>;

    // ── Ranking de mercado ────────────────────────────────

    /// Lista de monedas ordenadas por capitalización
    function GetMarkets(const AVsCurrency: string = 'eur';
                        ALimit: Integer = 20;
                        APage: Integer = 1): TArray<TCoinMarket>;

    // ── Detalle de moneda ─────────────────────────────────

    /// Información completa de una moneda (cuidado: respuesta grande)
    function GetCoinDetail(const ACoinID: string): TCoinDetail;

    // ── Histórico ─────────────────────────────────────────

    /// Precio de un coin en una fecha concreta (YYYY-MM-DD o TDate)
    function GetHistoricalPrice(const ACoinID: string;
                                const ADate: TDate;
                                const AVsCurrency: string = 'eur'): Double;

    /// Serie histórica de precios (últimos N días o rango)
    /// ADays: 1, 7, 14, 30, 90, 180, 365, 'max'
    function GetMarketChart(const ACoinID: string;
                            const AVsCurrency: string = 'eur';
                            ADays: Integer = 30): TArray<TChartPoint>;

    // ── Búsqueda ──────────────────────────────────────────

    /// Busca coins por nombre o símbolo
    function SearchCoins(const AQuery: string): TArray<TCoinSearchResult>;

    // ── Utilidades ────────────────────────────────────────

    /// Lista de currencies fiat soportadas ('eur', 'usd', 'gbp'...)
    function GetSupportedCurrencies: TArray<string>;

    // ── Propiedades ───────────────────────────────────────
    property Timeout   : Integer read FTimeout   write FTimeout;
    property ApiKey    : string  read FApiKey    write FApiKey;
    property LastError : string  read FLastError;
  end;

// ──────────────────────────────────────────────────────────────
// Funciones globales rápidas
// ──────────────────────────────────────────────────────────────

/// Precio de Bitcoin en euros (función rápida)
function CoinGeckoGetBTCPrice(const ACurrency: string = 'eur'): Double;

/// Precio de cualquier coin (función rápida)
function CoinGeckoGetPrice(const ACoinID, ACurrency: string): Double;
function GetPriceBinance(const SymbolPair: string): Double;
procedure TestBinance;

implementation

uses
  inLibJsonSeguro, inLibMsgConfiguracion,
  inLibMsgIntegraciones;

function GetPriceBinance(const SymbolPair: string): Double;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  JSON: TJSONObject;
  PriceStr: string;
begin
  // SymbolPair ejemplo: 'BTCEUR' o 'BTCUSDT'
  Result := 0.0;
  Client := THTTPClient.Create;
  try
    Response := Client.Get(
      'https://api.binance.com/api/v3/ticker/price?symbol=' +
      UpperCase(SymbolPair));

    if Response.StatusCode = 200 then
    begin
      JSON :=
        TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        if Assigned(JSON) then
        begin
          PriceStr := JSON.GetValue('price').Value;
          Result := StrToFloatDef(PriceStr, 0.0, TFormatSettings.Invariant);
        end;
      finally
        FreeAndNil(JSON);
      end;
    end;
  finally
    FreeAndNil(Client);
  end;
end;

procedure TestBinance;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
begin
  Client := THTTPClient.Create;
  try
    // Probamos con un par que SIEMPRE existe
    Resp :=
      Client.Get('https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT');

    if Resp.StatusCode = 200 then
      System.Writeln('Éxito: ' + Resp.ContentAsString)
    else
      // Esto te dirá el mensaje de error real de Binance (ej:
      // {"code":-1121,"msg":"Invalid symbol."})
      System.Writeln(
        'Error ' + Resp.StatusCode.ToString + ': ' + Resp.ContentAsString);
  finally
    FreeAndNil(Client);
  end;
end;

{ TCoinPrice }

function TCoinPrice.GetPrice(const ACurrency: string): Double;
begin
  Result := 0;
  if Assigned(Prices) then
    Prices.TryGetValue(LowerCase(ACurrency), Result);
end;

function TCoinPrice.GetChange24h(const ACurrency: string): Double;
begin
  Result := 0;
  if Assigned(Change24h) then
    Change24h.TryGetValue(LowerCase(ACurrency) + '_24h_change', Result);
end;

procedure LiberarDiccionariosPrecio(var APrecio: TCoinPrice);
begin
  FreeAndNil(APrecio.Prices);
  FreeAndNil(APrecio.MarketCaps);
  FreeAndNil(APrecio.Vol24h);
  FreeAndNil(APrecio.Change24h);
end;

procedure LiberarPrecios(var APrecios: TArray<TCoinPrice>);
var
  i: Integer;
begin
  for i := 0 to High(APrecios) do
    LiberarDiccionariosPrecio(APrecios[i]);
  APrecios := nil;
end;

procedure LiberarPreciosLista(ALista: TList<TCoinPrice>);
var
  i: Integer;
  oPrecio: TCoinPrice;
begin
  if Assigned(ALista) then
  begin
    for i := 0 to ALista.Count - 1 do
    begin
      oPrecio := ALista[i];
      LiberarDiccionariosPrecio(oPrecio);
    end;
  end;
end;

procedure LiberarDiccionariosDetalle(var ADetalle: TCoinDetail);
begin
  FreeAndNil(ADetalle.CurrentPrices);
  FreeAndNil(ADetalle.MarketCaps);
  FreeAndNil(ADetalle.TotalVolumes);
end;

{ TCoinGeckoAPI }

constructor TCoinGeckoAPI.Create(const AApiKey, ABaseURL: string);
begin
  inherited Create;
  FBaseURL    := ABaseURL;
  FApiKey     := AApiKey;
  FTimeout    := COINGECKO_TIMEOUT;
  FLastError  := '';
  FHttpClient := THTTPClient.Create;
  FHttpClient.ContentType := 'application/json';
  // Cabecera User-Agent recomendada por CoinGecko
  FHttpClient.CustomHeaders['User-Agent'] := 'ViraCash-Delphi/1.0';
  if FApiKey <> '' then
    FHttpClient.CustomHeaders['x-cg-demo-api-key'] := FApiKey;
end;

destructor TCoinGeckoAPI.Destroy;
begin
  FreeAndNil(FHttpClient);
  inherited;
end;

// ── Helpers ────────────────────────────────────────────────

function TCoinGeckoAPI.DoGet(const AURL: string): string;
var
  Response: IHTTPResponse;
begin
  FLastError := '';
  try
    FHttpClient.ResponseTimeout := FTimeout;
    Response := FHttpClient.Get(AURL);
    case Response.StatusCode of
      200: Result := Response.ContentAsString(TEncoding.UTF8);
      429: raise ECoinGeckoError.Create(SErrorLimitePeticionesCripto);
      else raise ECoinGeckoError.CreateFmt(SErrorHttpCripto,
             [Response.StatusCode, Response.StatusText]);
    end;
  except
    on E: ECoinGeckoError do begin FLastError := E.Message; raise; end;
    on E: Exception do
    begin
      FLastError := E.Message;
      raise ECoinGeckoError.Create(Format(SErrorRedCripto, [E.Message]));
    end;
  end;
end;

function TCoinGeckoAPI.BuildURL(const APath: string;
                                 const AParams: array of string): string;
var
  i: Integer;
  Sep: string;
begin
  Result := FBaseURL + APath;
  Sep    := '?';
  i := 0;
  while i < Length(AParams) - 1 do
  begin
    if AParams[i + 1] <> '' then
    begin
      Result := Result + Sep + AParams[i] + '=' + AParams[i + 1];
      Sep := '&';
    end;
    Inc(i, 2);
  end;
end;

function TCoinGeckoAPI.SafeDouble(AObj: TJSONObject;
                                  const AKey: string): Double;
begin
  // Conversion explicita con defecto: sin try/except mudos.
  Result := JsonDoubleODefecto(AObj, AKey, 0);
end;

function TCoinGeckoAPI.SafeInt(AObj: TJSONObject; const AKey: string): Integer;
begin
  // Conversion explicita con defecto: sin try/except mudos.
  Result := JsonEnteroODefecto(AObj, AKey, 0);
end;

function TCoinGeckoAPI.SafeStr(AObj: TJSONObject; const AKey: string): string;
var
  V: TJSONValue;
begin
  Result := '';
  if Assigned(AObj) then
  begin
    V := AObj.GetValue(AKey);
    if Assigned(V) and not (V is TJSONNull) then
      Result := V.Value;
  end;
end;

function TCoinGeckoAPI.UnixToDateTime(AUnix: Int64): TDateTime;
begin
  Result := System.DateUtils.UnixToDateTime(AUnix);
end;

// ── Métodos públicos ───────────────────────────────────────

function TCoinGeckoAPI.Ping: Boolean;
var
  Raw  : string;
  JSON : TJSONObject;
begin
  Result := False;
  try
    Raw  := DoGet(FBaseURL + '/ping');
    JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if Assigned(JSON) then
    try
      Result := JSON.GetValue('gecko_says') <> nil;
    finally
      FreeAndNil(JSON);
    end;
  except
    Result := False;
  end;
end;

function TCoinGeckoAPI.GetPrice(const ACoinID, AVsCurrency: string): Double;
var
  Prices: TArray<TCoinPrice>;
begin
  Result := 0;
  Prices := nil;
  try
    Prices := GetPrices([LowerCase(ACoinID)], [LowerCase(AVsCurrency)]);
    if Length(Prices) > 0 then
      Result := Prices[0].GetPrice(AVsCurrency);
  finally
    LiberarPrecios(Prices);
  end;
end;

function IfThen(AValue: Boolean;
                const ATrue: string;
                AFalse: string = ''): string; overload;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function TCoinGeckoAPI.GetPrices(const ACoinIDs: TArray<string>;
                                  const ACurrencies: TArray<string>;
                                  AIncludeMarketCap : Boolean;
                                  AInclude24hVol    : Boolean;
                                  AInclude24hChange: Boolean):
                                  TArray<TCoinPrice>;
var
  URL       : string;
  Raw       : string;
  JSON      : TJSONObject;
  CoinObj   : TJSONObject;
  CurPair   : TJSONPair;
  Coin      : TCoinPrice;
  CoinList  : TList<TCoinPrice>;
  IDs       : string;
  Curs      : string;
  CoinPair  : TJSONPair;
begin
  Result := nil;
  try
    IDs  := string.Join(',', ACoinIDs);
    Curs := string.Join(',', ACurrencies);

    URL := BuildURL('/simple/price', [
      'ids',                    IDs,
      'vs_currencies',          Curs,
      'include_market_cap',     IfThen(AIncludeMarketCap, 'true', 'false'),
      'include_24hr_vol',       IfThen(AInclude24hVol,    'true', 'false'),
      'include_24hr_change',    IfThen(AInclude24hChange, 'true', 'false'),
      'include_last_updated_at','true'
    ]);

    Raw  := DoGet(URL);
    JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if not Assigned(JSON) then
      raise ECoinGeckoError.Create(SErrorJsonCripto);
    try
      CoinList := TList<TCoinPrice>.Create;
      try
        try
          for CoinPair in JSON do
          begin
            Coin := Default(TCoinPrice);
            try
              Coin.CoinID      := CoinPair.JsonString.Value;
              Coin.Prices      := TDictionary<string, Double>.Create;
              Coin.MarketCaps  := TDictionary<string, Double>.Create;
              Coin.Vol24h      := TDictionary<string, Double>.Create;
              Coin.Change24h   := TDictionary<string, Double>.Create;
              Coin.LastUpdated := 0;

              CoinObj := CoinPair.JsonValue as TJSONObject;
              if Assigned(CoinObj) then
                for CurPair in CoinObj do
                begin
                  // last_updated_at es Unix timestamp
                  if CurPair.JsonString.Value = 'last_updated_at' then
                    Coin.LastUpdated := UnixToDateTime(
                      StrToInt64Def(CurPair.JsonValue.Value, 0))
                  else if CurPair.JsonString.Value.EndsWith(
                            '_market_cap') then
                    Coin.MarketCaps.AddOrSetValue(
                      CurPair.JsonString.Value,
                      CurPair.JsonValue.AsType<Double>)
                  else if CurPair.JsonString.Value.EndsWith('_24h_vol') then
                    Coin.Vol24h.AddOrSetValue(CurPair.JsonString.Value,
                                              CurPair.JsonValue.AsType<Double>)
                  else if CurPair.JsonString.Value.EndsWith(
                            '_24h_change') then
                    Coin.Change24h.AddOrSetValue(
                      CurPair.JsonString.Value,
                      CurPair.JsonValue.AsType<Double>)
                  else
                    Coin.Prices.AddOrSetValue(CurPair.JsonString.Value,
                                              CurPair.JsonValue.AsType<Double>);
                end;

              CoinList.Add(Coin);
            except
              LiberarDiccionariosPrecio(Coin);
              raise;
            end;
            // La lista pasa a ser propietaria de los diccionarios.
            Coin.Prices := nil;
            Coin.MarketCaps := nil;
            Coin.Vol24h := nil;
            Coin.Change24h := nil;
          end;
          Result := CoinList.ToArray;
        except
          LiberarPreciosLista(CoinList);
          raise;
        end;
      finally
        FreeAndNil(CoinList);
      end;
    finally
      FreeAndNil(JSON);
    end;
  except
    LiberarPrecios(Result);
    raise;
  end;
end;

function TCoinGeckoAPI.GetTopCoins(const AVsCurrency: string;
                                    ALimit: Integer): TArray<TCoinMarket>;
begin
  Result := GetMarkets(AVsCurrency, ALimit, 1);
end;

function TCoinGeckoAPI.GetMarkets(const AVsCurrency: string;
                                   ALimit, APage: Integer): TArray<TCoinMarket>;
var
  URL      : string;
  Raw      : string;
  JSONArr  : TJSONArray;
  Item     : TJSONValue;
  Obj      : TJSONObject;
  Market   : TCoinMarket;
  List     : TList<TCoinMarket>;
begin
  URL := BuildURL('/coins/markets', [
    'vs_currency',            LowerCase(AVsCurrency),
    'order',                  'market_cap_desc',
    'per_page',               IntToStr(ALimit),
    'page',                   IntToStr(APage),
    'sparkline',              'false',
    'price_change_percentage','24h'
  ]);

  Raw     := DoGet(URL);
  JSONArr := TJSONObject.ParseJSONValue(Raw) as TJSONArray;
  if not Assigned(JSONArr) then
    raise ECoinGeckoError.Create(SErrorJsonCripto);

  List := TList<TCoinMarket>.Create;
  try
    for Item in JSONArr do
    begin
      Obj := Item as TJSONObject;
      // Default() libera los strings (ID, Symbol, Name) del record
      // anterior. FillChar machacaba los punteros sin liberar.
      Market := Default(TCoinMarket);

      Market.ID                := SafeStr(Obj, 'id');
      Market.Symbol            := SafeStr(Obj, 'symbol');
      Market.Name              := SafeStr(Obj, 'name');
      Market.ImageURL          := SafeStr(Obj, 'image');
      Market.CurrentPrice      := SafeDouble(Obj, 'current_price');
      Market.MarketCap         := SafeDouble(Obj, 'market_cap');
      Market.MarketCapRank     := SafeInt(Obj, 'market_cap_rank');
      Market.TotalVolume       := SafeDouble(Obj, 'total_volume');
      Market.High24h           := SafeDouble(Obj, 'high_24h');
      Market.Low24h            := SafeDouble(Obj, 'low_24h');
      Market.PriceChange24h    := SafeDouble(Obj, 'price_change_24h');
      Market.PriceChangePct24h := SafeDouble(Obj,
                                             'price_change_percentage_24h');
      Market.CirculatingSupply := SafeDouble(Obj, 'circulating_supply');
      Market.TotalSupply       := SafeDouble(Obj, 'total_supply');
      Market.ATH               := SafeDouble(Obj, 'ath');
      Market.ATL               := SafeDouble(Obj, 'atl');

      // Fechas opcionales: si el ISO no parsea quedan a 0 y el
      // mercado se conserva igualmente.
      Market.ATHDate := JsonFechaIsoODefecto(
        SafeStr(Obj, 'ath_date'), 0);
      Market.ATLDate := JsonFechaIsoODefecto(
        SafeStr(Obj, 'atl_date'), 0);
      Market.LastUpdated := JsonFechaIsoODefecto(
        SafeStr(Obj, 'last_updated'), 0);

      List.Add(Market);
    end;
    Result := List.ToArray;
  finally
    FreeAndNil(List);
    FreeAndNil(JSONArr);
  end;
end;

function TCoinGeckoAPI.GetCoinDetail(const ACoinID: string): TCoinDetail;
var
  URL         : string;
  Raw         : string;
  JSON        : TJSONObject;
  MarketData  : TJSONObject;
  CurrentPr   : TJSONObject;
  MktCap      : TJSONObject;
  TotVol      : TJSONObject;
  Links       : TJSONObject;
  HomepageArr : TJSONArray;
  DescObj     : TJSONObject;
  ScoresObj   : TJSONObject;
  Pair        : TJSONPair;
  rValor      : Double;
begin
  Result := Default(TCoinDetail);
  try
    Result.CurrentPrices := TDictionary<string, Double>.Create;
    Result.MarketCaps    := TDictionary<string, Double>.Create;
    Result.TotalVolumes  := TDictionary<string, Double>.Create;

    URL := BuildURL('/coins/' + LowerCase(ACoinID), [
      'localization',      'false',
      'tickers',           'false',
      'market_data',       'true',
      'community_data',    'true',
      'developer_data',    'false',
      'sparkline',         'false'
    ]);

    Raw  := DoGet(URL);
    JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if not Assigned(JSON) then
      raise ECoinGeckoError.Create(SErrorJsonCripto);
    try
      Result.ID     := SafeStr(JSON, 'id');
      Result.Symbol := SafeStr(JSON, 'symbol');
      Result.Name   := SafeStr(JSON, 'name');

      // Descripción en inglés
      DescObj := JSON.GetValue<TJSONObject>('description');
      if Assigned(DescObj) then
        Result.Description := SafeStr(DescObj, 'en');

      // Homepage
      Links := JSON.GetValue<TJSONObject>('links');
      if Assigned(Links) then
      begin
        HomepageArr := Links.GetValue<TJSONArray>('homepage');
        if Assigned(HomepageArr) and (HomepageArr.Count > 0) then
          Result.HomepageURL := HomepageArr.Items[0].Value;
      end;

      Result.GenesisDate  := SafeStr(JSON, 'genesis_date');
      Result.MarketCapRank := SafeInt(JSON, 'market_cap_rank');
      Result.CoingeckoRank := SafeInt(JSON, 'coingecko_rank');

      // Scores
      ScoresObj := JSON;
      Result.CoingeckoScore := SafeDouble(ScoresObj, 'coingecko_score');
      Result.DeveloperScore := SafeDouble(ScoresObj, 'developer_score');
      Result.CommunityScore := SafeDouble(ScoresObj, 'community_score');
      Result.LiquidityScore := SafeDouble(ScoresObj, 'liquidity_score');
      Result.PublicInterest := SafeDouble(ScoresObj, 'public_interest_score');

      // Market data
      MarketData := JSON.GetValue<TJSONObject>('market_data');
      if Assigned(MarketData) then
      begin
        CurrentPr := MarketData.GetValue<TJSONObject>('current_price');
        MktCap    := MarketData.GetValue<TJSONObject>('market_cap');
        TotVol    := MarketData.GetValue<TJSONObject>('total_volume');

        // Divisas con valor no numerico se omiten; el resto sigue.
        if Assigned(CurrentPr) then
          for Pair in CurrentPr do
            if Pair.JsonValue.TryGetValue<Double>(rValor) then
              Result.CurrentPrices.AddOrSetValue(Pair.JsonString.Value,
                                                 rValor);

        if Assigned(MktCap) then
          for Pair in MktCap do
            if Pair.JsonValue.TryGetValue<Double>(rValor) then
              Result.MarketCaps.AddOrSetValue(Pair.JsonString.Value,
                                              rValor);

        if Assigned(TotVol) then
          for Pair in TotVol do
            if Pair.JsonValue.TryGetValue<Double>(rValor) then
              Result.TotalVolumes.AddOrSetValue(Pair.JsonString.Value,
                                                rValor);
      end;
    finally
      FreeAndNil(JSON);
    end;
  except
    LiberarDiccionariosDetalle(Result);
    raise;
  end;
end;

function TCoinGeckoAPI.GetHistoricalPrice(const ACoinID: string;
                                           const ADate: TDate;
                                           const AVsCurrency: string): Double;
var
  URL        : string;
  Raw        : string;
  JSON       : TJSONObject;
  MarketData : TJSONObject;
  PriceObj   : TJSONObject;
  DateStr    : string;
begin
  Result  := 0;
  // CoinGecko espera la fecha en formato DD-MM-YYYY
  DateStr := FormatDateTime('dd-mm-yyyy', ADate);

  URL := BuildURL('/coins/' + LowerCase(ACoinID) + '/history', [
    'date',        DateStr,
    'localization','false'
  ]);

  Raw  := DoGet(URL);
  JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
  if not Assigned(JSON) then
    raise ECoinGeckoError.Create(SErrorJsonCripto);
  try
    MarketData := JSON.GetValue<TJSONObject>('market_data');
    if Assigned(MarketData) then
    begin
      PriceObj := MarketData.GetValue<TJSONObject>('current_price');
      if Assigned(PriceObj) then
        Result := SafeDouble(PriceObj, LowerCase(AVsCurrency));
    end;
  finally
    FreeAndNil(JSON);
  end;
end;

function TCoinGeckoAPI.GetMarketChart(const ACoinID: string;
                                       const AVsCurrency: string;
                                       ADays: Integer): TArray<TChartPoint>;
var
  URL       : string;
  Raw       : string;
  JSON      : TJSONObject;
  PricesArr : TJSONArray;
  MktCapArr : TJSONArray;
  VolArr    : TJSONArray;
  Point     : TChartPoint;
  List      : TList<TChartPoint>;
  i         : Integer;
  Row       : TJSONArray;
begin
  URL := BuildURL('/coins/' + LowerCase(ACoinID) + '/market_chart', [
    'vs_currency', LowerCase(AVsCurrency),
    'days',        IntToStr(ADays),
    'interval',    IfThen(ADays <= 1, 'minutely',
                   IfThen(ADays <= 90, 'hourly', 'daily'))
  ]);

  Raw  := DoGet(URL);
  JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
  if not Assigned(JSON) then
    raise ECoinGeckoError.Create(SErrorJsonCripto);

  List := TList<TChartPoint>.Create;
  try
    PricesArr := JSON.GetValue<TJSONArray>('prices');
    MktCapArr := JSON.GetValue<TJSONArray>('market_caps');
    VolArr    := JSON.GetValue<TJSONArray>('total_volumes');

    if Assigned(PricesArr) then
      for i := 0 to PricesArr.Count - 1 do
      begin
        FillChar(Point, SizeOf(Point), 0);
        Row := PricesArr.Items[i] as TJSONArray;
        if Assigned(Row) and (Row.Count >= 2) then
        begin
          Point.Timestamp := UnixToDateTime(
            Trunc(Row.Items[0].AsType<Double>) div 1000);
          Point.Price     := Row.Items[1].AsType<Double>;
        end;

        // Market cap
        if Assigned(MktCapArr) and (i < MktCapArr.Count) then
        begin
          Row := MktCapArr.Items[i] as TJSONArray;
          if Assigned(Row) and (Row.Count >= 2) then
            Point.MarketCap := Row.Items[1].AsType<Double>;
        end;

        // Volume
        if Assigned(VolArr) and (i < VolArr.Count) then
        begin
          Row := VolArr.Items[i] as TJSONArray;
          if Assigned(Row) and (Row.Count >= 2) then
            Point.Volume := Row.Items[1].AsType<Double>;
        end;

        List.Add(Point);
      end;
    Result := List.ToArray;
  finally
    FreeAndNil(List);
    FreeAndNil(JSON);
  end;
end;

function TCoinGeckoAPI.SearchCoins(
  const AQuery: string): TArray<TCoinSearchResult>;
var
  URL      : string;
  Raw      : string;
  JSON     : TJSONObject;
  CoinsArr : TJSONArray;
  Item     : TJSONValue;
  Obj      : TJSONObject;
  Res      : TCoinSearchResult;
  List     : TList<TCoinSearchResult>;
begin
  URL := BuildURL('/search', ['query', AQuery]);
  Raw  := DoGet(URL);
  JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
  if not Assigned(JSON) then
    raise ECoinGeckoError.Create(SErrorJsonCripto);

  List := TList<TCoinSearchResult>.Create;
  try
    CoinsArr := JSON.GetValue<TJSONArray>('coins');
    if Assigned(CoinsArr) then
      for Item in CoinsArr do
      begin
        Obj := Item as TJSONObject;
        Res.ID     := SafeStr(Obj, 'id');
        Res.Name   := SafeStr(Obj, 'name');
        Res.Symbol := SafeStr(Obj, 'symbol');
        Res.Rank   := SafeInt(Obj, 'market_cap_rank');
        Res.Thumb  := SafeStr(Obj, 'thumb');
        List.Add(Res);
      end;
    Result := List.ToArray;
  finally
    FreeAndNil(List);
    FreeAndNil(JSON);
  end;
end;

function TCoinGeckoAPI.GetSupportedCurrencies: TArray<string>;
var
  URL     : string;
  Raw     : string;
  JSONArr : TJSONArray;
  Item    : TJSONValue;
  List    : TList<string>;
begin
  URL     := FBaseURL + '/simple/supported_vs_currencies';
  Raw     := DoGet(URL);
  JSONArr := TJSONObject.ParseJSONValue(Raw) as TJSONArray;
  if not Assigned(JSONArr) then
    raise ECoinGeckoError.Create(SErrorJsonCripto);

  List := TList<string>.Create;
  try
    for Item in JSONArr do
      List.Add(Item.Value);
    Result := List.ToArray;
  finally
    FreeAndNil(List);
    FreeAndNil(JSONArr);
  end;
end;

// ── Funciones globales ─────────────────────────────────────

function CoinGeckoGetBTCPrice(const ACurrency: string): Double;
var
  API: TCoinGeckoAPI;
begin
  API := TCoinGeckoAPI.Create;
  try
    Result := API.GetPrice('bitcoin', ACurrency);
  finally
    FreeAndNil(API);
  end;
end;

function CoinGeckoGetPrice(const ACoinID, ACurrency: string): Double;
var
  API: TCoinGeckoAPI;
begin
  API := TCoinGeckoAPI.Create;
  try
    Result := API.GetPrice(ACoinID, ACurrency);
  finally
    FreeAndNil(API);
  end;
end;

end.
