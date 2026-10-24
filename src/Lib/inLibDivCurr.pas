{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDivCurr                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente de la API pública frankfurter.app (BCE).                          }
{    Consulta tasas de cambio actuales e históricas entre divisas.             }
{******************************************************************************}
unit inLibDivCurr;

{
  ============================================================
  inLibDivCurr.pas
  Librería para consumir la API pública frankfurter.app
  Fuente: Banco Central Europeo (BCE) - Actualización diaria
  Sin API Key. Sin registro.

  Autor  : Generado para ViraCash
  Delphi : 10.x / 11 / 12 (VCL y FMX)
  Requiere: System.Net.HttpClient, System.JSON
  ============================================================

  USO RÁPIDO:
  -----------
    var
      API: TFrankfurterAPI;
      Tasa: Double;
    begin
      API := TFrankfurterAPI.Create;
      try
        Tasa := API.GetRate('EUR', 'USD');
        // Presentar la tasa desde el formulario consumidor.
      finally
        FreeAndNil(API);
      end;
    end;

  ENDPOINTS DISPONIBLES:
  ----------------------
    GetRate(Base, Target)                   → tasa de cambio actual (float)
    GetRates(Base, Targets)                 → varias divisas a la vez
    GetLatest(Base)                         → TFrankfurterResult completo
    GetHistorical(Date, Base, Targets)      → tasas de una fecha concreta
    GetSeries(StartDate, EndDate, Base)     → serie histórica
    ConvertAmount(Amount, From, To)         → conversión directa de importe
    GetCurrencies                           → lista de divisas soportadas
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
  System.DateUtils, System.NetConsts;

const
  FRANKFURTER_BASE_URL = 'https://api.frankfurter.app';
  FRANKFURTER_TIMEOUT  = 10000; // ms

type
  // ──────────────────────────────────────────────────────────
  // Excepción propia de la librería
  // ──────────────────────────────────────────────────────────
  EFrankfurterError = class(Exception);

  // ──────────────────────────────────────────────────────────
  // Registro de una divisa soportada
  // ──────────────────────────────────────────────────────────
  TFrankfurterCurrency = record
    Code : string;   // 'EUR', 'USD', 'GBP'...
    Name : string;   // 'Euro', 'US Dollar'...
  end;

  // ──────────────────────────────────────────────────────────
  // Resultado principal de una consulta de tasas
  // ──────────────────────────────────────────────────────────
  TFrankfurterResult = record
    Amount : Double;                         // importe base consultado
    Base   : string;                         // divisa base
    Date   : TDate;                          // fecha de las tasas
    Rates  : TDictionary<string, Double>;    // mapa Código → Tasa
    // Devuelve la tasa de una divisa concreta (0 si no existe)
    function GetRate(const ACode: string): Double;
    // Convierte un importe usando las tasas del resultado
    function Convert(AAmount: Double; const ATargetCode: string): Double;
  end;

  // ──────────────────────────────────────────────────────────
  // Serie histórica: fecha → (divisa → tasa)
  // ──────────────────────────────────────────────────────────
  TFrankfurterSeries = TDictionary<TDate, TDictionary<string, Double>>;

  // ──────────────────────────────────────────────────────────
  // Clase principal de la librería
  // ──────────────────────────────────────────────────────────
  TFrankfurterAPI = class
  private
    FHttpClient : THTTPClient;
    FBaseURL    : string;
    FTimeout    : Integer;
    FLastError  : string;

    function  DoGet(const AURL: string): string;
    function  BuildRatesURL(const AEndpoint, ABase: string;
                            const ATargets: TArray<string>): string;
    procedure ParseRatesInto(AJSON: TJSONObject;
                             var AResult: TFrankfurterResult);
    function  JSONToDate(const AStr: string): TDate;

  public
    constructor Create(const ABaseURL: string = FRANKFURTER_BASE_URL);
    destructor  Destroy; override;

    // ── Consultas principales ──────────────────────────────

    /// Tasa de cambio puntual entre dos divisas (hoy)
    function GetRate(const ABase, ATarget: string): Double;

    /// Tasas de una divisa base hacia varias destino
    /// ATargets = ['USD','GBP','JPY']  (vacío = todas)
    function GetRates(const ABase: string;
                      const ATargets: TArray<string> = nil): TFrankfurterResult;

    /// Igual que GetRates pero devuelve el objeto completo (hoy)
    function GetLatest(const ABase: string = 'EUR';
      const ATargets: TArray<string> = nil): TFrankfurterResult;

    /// Tasas de una fecha histórica concreta
    function GetHistorical(const ADate: TDate;
      const ABase: string = 'EUR';
      const ATargets: TArray<string> = nil): TFrankfurterResult;

    /// Serie de tasas entre dos fechas
    /// Devuelve un diccionario TDate → (código → tasa)
    function GetSeries(const AStartDate, AEndDate: TDate;
      const ABase: string = 'EUR';
      const ATargets: TArray<string> = nil): TFrankfurterSeries;

    /// Convierte un importe de una divisa a otra (usa la API directamente)
    function ConvertAmount(AAmount: Double;
                           const AFrom, ATo: string): Double;

    /// Lista de divisas soportadas por la API
    function GetCurrencies: TArray<TFrankfurterCurrency>;

    // ── Propiedades ────────────────────────────────────────
    property Timeout   : Integer read FTimeout   write FTimeout;
    property LastError : string  read FLastError;
  end;

// ──────────────────────────────────────────────────────────────
// Funciones de utilidad independientes
// ──────────────────────────────────────────────────────────────

/// Devuelve la tasa EUR→Target directamente (función global rápida)
function FrankfurterGetRate(const ATarget: string): Double;

/// Convierte importe directamente (función global rápida)
function FrankfurterConvert(AAmount: Double;
                            const AFrom, ATo: string): Double;

implementation

uses
  inLibMsgIntegraciones;

{ TFrankfurterResult }

function TFrankfurterResult.GetRate(const ACode: string): Double;
begin
  Result := 0;
  if Assigned(Rates) then
    Rates.TryGetValue(UpperCase(ACode), Result);
end;

function TFrankfurterResult.Convert(AAmount: Double;
                                    const ATargetCode: string): Double;
var
  Rate: Double;
begin
  Rate := GetRate(ATargetCode);
  if Rate = 0 then
    raise EFrankfurterError.CreateFmt(SErrorDivisaNoEncontrada,
                                     [ATargetCode]);
  Result := AAmount * Rate;
end;

procedure LiberarResultadoFrankfurter(var AResultado: TFrankfurterResult);
begin
  FreeAndNil(AResultado.Rates);
end;

procedure LiberarSerieFrankfurter(var ASerie: TFrankfurterSeries);
var
  oRates: TDictionary<string, Double>;
begin
  if Assigned(ASerie) then
  begin
    for oRates in ASerie.Values do
      oRates.Free;
    FreeAndNil(ASerie);
  end;
end;

{ TFrankfurterAPI }

constructor TFrankfurterAPI.Create(const ABaseURL: string);
begin
  inherited Create;
  FBaseURL    := ABaseURL;
  FTimeout    := FRANKFURTER_TIMEOUT;
  FLastError  := '';
  FHttpClient := THTTPClient.Create;
  FHttpClient.ContentType := 'application/json';
end;

destructor TFrankfurterAPI.Destroy;
begin
  FreeAndNil(FHttpClient);
  inherited;
end;

// ── HTTP ───────────────────────────────────────────────────

function TFrankfurterAPI.DoGet(const AURL: string): string;
var
  Response : IHTTPResponse;
begin
  FLastError := '';
  try
    FHttpClient.ResponseTimeout := FTimeout;
    Response := FHttpClient.Get(AURL);
    if Response.StatusCode = 200 then
      Result := Response.ContentAsString(TEncoding.UTF8)
    else
      raise EFrankfurterError.CreateFmt(SErrorHttpDivisas,
        [Response.StatusCode, Response.StatusText]);
  except
    on E: EFrankfurterError do
    begin
      FLastError := E.Message;
      raise;
    end;
    on E: Exception do
    begin
      FLastError := E.Message;
      raise EFrankfurterError.Create(Format(SErrorRedDivisas, [E.Message]));
    end;
  end;
end;

// ── Helpers internos ───────────────────────────────────────

function TFrankfurterAPI.BuildRatesURL(const AEndpoint, ABase: string;
                                        const ATargets: TArray<string>): string;
var
  Params: string;
begin
  Result := FBaseURL + '/' + AEndpoint;
  Params := '';

  if ABase <> '' then
    Params := 'from=' + UpperCase(ABase);

  if (ATargets <> nil) and (Length(ATargets) > 0) then
  begin
    if Params <> '' then Params := Params + '&';
    Params := Params + 'to=' + string.Join(',', ATargets);
  end;

  if Params <> '' then
    Result := Result + '?' + Params;
end;

function TFrankfurterAPI.JSONToDate(const AStr: string): TDate;
begin
  // Formato devuelto por la API: 'YYYY-MM-DD'
  try
    Result := EncodeDate(
      StrToInt(Copy(AStr, 1, 4)),
      StrToInt(Copy(AStr, 6, 2)),
      StrToInt(Copy(AStr, 9, 2))
    );
  except
    Result := Today;
  end;
end;

procedure TFrankfurterAPI.ParseRatesInto(AJSON: TJSONObject;
                                          var AResult: TFrankfurterResult);
var
  RatesObj : TJSONObject;
  Pair     : TJSONPair;
  RateVal  : Double;
begin
  // amount
  if AJSON.TryGetValue<Double>('amount', RateVal) then
    AResult.Amount := RateVal
  else
    AResult.Amount := 1;

  // base
  AResult.Base := AJSON.GetValue<string>('base', '');

  // date
  AResult.Date := JSONToDate(AJSON.GetValue<string>('date', ''));

  // rates
  if not Assigned(AResult.Rates) then
    AResult.Rates := TDictionary<string, Double>.Create;

  AResult.Rates.Clear;
  RatesObj := AJSON.GetValue<TJSONObject>('rates');
  if Assigned(RatesObj) then
    for Pair in RatesObj do
      AResult.Rates.AddOrSetValue(Pair.JsonString.Value,
                                  Pair.JsonValue.AsType<Double>);
end;

// ── Métodos públicos ───────────────────────────────────────

function TFrankfurterAPI.GetRate(const ABase, ATarget: string): Double;
var
  Res: TFrankfurterResult;
begin
  Res.Rates := nil;
  try
    Res := GetLatest(ABase, [UpperCase(ATarget)]);
    Result := Res.GetRate(ATarget);
  finally
    if Assigned(Res.Rates) then FreeAndNil(Res.Rates);
  end;
end;

function TFrankfurterAPI.GetRates(const ABase: string;
  const ATargets: TArray<string>): TFrankfurterResult;
begin
  Result := GetLatest(ABase, ATargets);
end;

function TFrankfurterAPI.GetLatest(const ABase: string;
  const ATargets: TArray<string>): TFrankfurterResult;
var
  URL  : string;
  JSON : TJSONObject;
  Raw  : string;
begin
  Result := Default(TFrankfurterResult);
  try
    URL  := BuildRatesURL('latest', ABase, ATargets);
    Raw  := DoGet(URL);
    JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if not Assigned(JSON) then
      raise EFrankfurterError.Create(SErrorJsonDivisas);
    try
      ParseRatesInto(JSON, Result);
    finally
      FreeAndNil(JSON);
    end;
  except
    LiberarResultadoFrankfurter(Result);
    raise;
  end;
end;

function TFrankfurterAPI.GetHistorical(const ADate: TDate;
  const ABase: string;
  const ATargets: TArray<string>): TFrankfurterResult;
var
  DateStr : string;
  URL     : string;
  JSON    : TJSONObject;
  Raw     : string;
begin
  Result := Default(TFrankfurterResult);
  try
    DateStr := FormatDateTime('yyyy-mm-dd', ADate);
    URL     := BuildRatesURL(DateStr, ABase, ATargets);
    Raw     := DoGet(URL);
    JSON    := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if not Assigned(JSON) then
      raise EFrankfurterError.Create(SErrorJsonDivisas);
    try
      ParseRatesInto(JSON, Result);
    finally
      FreeAndNil(JSON);
    end;
  except
    LiberarResultadoFrankfurter(Result);
    raise;
  end;
end;

function TFrankfurterAPI.GetSeries(const AStartDate, AEndDate: TDate;
  const ABase: string;
  const ATargets: TArray<string>): TFrankfurterSeries;
var
  StartStr : string;
  EndStr   : string;
  URL      : string;
  Raw      : string;
  JSON     : TJSONObject;
  RatesObj : TJSONObject;
  DayObj   : TJSONObject;
  DayPair  : TJSONPair;
  CurPair  : TJSONPair;
  DayDate  : TDate;
  DayRates : TDictionary<string, Double>;
  OldRates : TDictionary<string, Double>;
begin
  Result   := TFrankfurterSeries.Create;
  try
    StartStr := FormatDateTime('yyyy-mm-dd', AStartDate);
    EndStr   := FormatDateTime('yyyy-mm-dd', AEndDate);

    // Endpoint de serie: /YYYY-MM-DD..YYYY-MM-DD
    URL := BuildRatesURL(StartStr + '..' + EndStr, ABase, ATargets);

    Raw  := DoGet(URL);
    JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if not Assigned(JSON) then
      raise EFrankfurterError.Create(SErrorJsonDivisas);
    try
      // La API devuelve "rates":
      // { "2025-01-02": { "USD": 1.04, ... }, ... }
      RatesObj := JSON.GetValue<TJSONObject>('rates');
      if Assigned(RatesObj) then
        for DayPair in RatesObj do
        begin
          DayDate  := JSONToDate(DayPair.JsonString.Value);
          DayObj   := DayPair.JsonValue as TJSONObject;
          DayRates := TDictionary<string, Double>.Create;
          try
            for CurPair in DayObj do
              DayRates.AddOrSetValue(CurPair.JsonString.Value,
                                     CurPair.JsonValue.AsType<Double>);
            if Result.TryGetValue(DayDate, OldRates) then
            begin
              Result.AddOrSetValue(DayDate, DayRates);
              DayRates := nil;
              FreeAndNil(OldRates);
            end
            else
            begin
              Result.Add(DayDate, DayRates);
              DayRates := nil;
            end;
          finally
            FreeAndNil(DayRates);
          end;
        end;
    finally
      FreeAndNil(JSON);
    end;
  except
    LiberarSerieFrankfurter(Result);
    raise;
  end;
end;

function TFrankfurterAPI.ConvertAmount(AAmount: Double;
                                        const AFrom, ATo: string): Double;
var
  URL  : string;
  Raw  : string;
  JSON : TJSONObject;
  Res  : TFrankfurterResult;
begin
  Res.Rates := nil;
  // La API acepta ?amount=X directamente
  URL := Format('%s/latest?amount=%s&from=%s&to=%s',
    [FBaseURL,
     StringReplace(FormatFloat('0.######', AAmount), ',', '.', []),
     UpperCase(AFrom),
     UpperCase(ATo)]);
  Raw  := DoGet(URL);
  JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
  if not Assigned(JSON) then
    raise EFrankfurterError.Create(SErrorJsonDivisas);
  try
    ParseRatesInto(JSON, Res);
    Result := Res.GetRate(ATo);
  finally
    FreeAndNil(JSON);
    if Assigned(Res.Rates) then FreeAndNil(Res.Rates);
  end;
end;

function TFrankfurterAPI.GetCurrencies: TArray<TFrankfurterCurrency>;
var
  URL  : string;
  Raw  : string;
  JSON : TJSONObject;
  Pair : TJSONPair;
  Cur  : TFrankfurterCurrency;
  List : TList<TFrankfurterCurrency>;
begin
  List := TList<TFrankfurterCurrency>.Create;
  try
    URL  := FBaseURL + '/currencies';
    Raw  := DoGet(URL);
    JSON := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
    if not Assigned(JSON) then
      raise EFrankfurterError.Create(SErrorJsonDivisas);
    try
      // Respuesta: { "AUD": "Australian Dollar", "BGN": "Bulgarian Lev", ... }
      for Pair in JSON do
      begin
        Cur.Code := Pair.JsonString.Value;
        Cur.Name := Pair.JsonValue.Value;
        List.Add(Cur);
      end;
    finally
      FreeAndNil(JSON);
    end;
    Result := List.ToArray;
  finally
    FreeAndNil(List);
  end;
end;

// ── Funciones globales rápidas ─────────────────────────────

function FrankfurterGetRate(const ATarget: string): Double;
var
  API: TFrankfurterAPI;
begin
  API := TFrankfurterAPI.Create;
  try
    Result := API.GetRate('EUR', ATarget);
  finally
    FreeAndNil(API);
  end;
end;

function FrankfurterConvert(AAmount: Double;
                             const AFrom, ATo: string): Double;
var
  API: TFrankfurterAPI;
begin
  API := TFrankfurterAPI.Create;
  try
    Result := API.ConvertAmount(AAmount, AFrom, ATo);
  finally
    FreeAndNil(API);
  end;
end;

end.
