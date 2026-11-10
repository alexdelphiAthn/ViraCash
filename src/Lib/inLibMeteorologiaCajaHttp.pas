{******************************************************************************}
{                                                                              }
{  Módulo: inLibMeteorologiaCajaHttp                                           }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Consulta y presentación del tiempo diario de la tienda.        }
{******************************************************************************}
unit inLibMeteorologiaCajaHttp;

interface

uses
  System.JSON, inLibMeteorologiaCajaIntf;

function CrearServicioMeteorologiaCajaHttp(const AUrl, AToken: string):
  IServicioMeteorologiaCaja;
function LeerParteMeteorologiaCaja(AParte: TJSONObject):
  TParteMeteorologiaCaja;
function LeerHistoricoMeteorologiaCaja(AParte: TJSONObject):
  TPartesMeteorologiaCaja;

implementation

uses
  System.SysUtils, System.DateUtils, System.Generics.Collections, System.Math,
  System.Net.HttpClient,
  System.Net.URLClient, System.NetEncoding, inLibMsgMeteorologiaCaja;

type
  TServicioMeteorologiaCajaHttp = class(TInterfacedObject,
    IServicioMeteorologiaCaja)
  private
    FUrl: string;
    FToken: string;
    function Consultar(const AConsulta: string): TJSONObject;
    function ResolverLocalidad(const AUbicacion: TUbicacionMeteorologiaCaja):
      TJSONObject;
    function ConsultarTramo(ACiudad: TJSONObject;
      ADesde, AHasta: TDateTime; const AAccion: string):
      TPartesMeteorologiaCaja;
  public
    constructor Create(const AUrl, AToken: string);
    function ConsultarHoy(const AUbicacion: TUbicacionMeteorologiaCaja):
      TParteMeteorologiaCaja;
    function ConsultarHistorico(const AUbicacion: TUbicacionMeteorologiaCaja;
      ADesde, AHasta: TDateTime; const ACancelar: TFunc<Boolean> = nil):
      TPartesMeteorologiaCaja;
  end;

function ValorNumero(AValor: TJSONValue): TValorMeteorologiaCaja;
begin
  Result := Default(TValorMeteorologiaCaja);
  if AValor is TJSONNumber then
  begin
    Result.TieneValor := True;
    Result.Valor := TJSONNumber(AValor).AsDouble;
  end
  else if not (AValor is TJSONNull) then
    raise EConvertError.Create(SErrorRespuestaMeteoCaja);
end;

function ValorDiario(AParte: TJSONObject;
  const ACampo: string; AIndice: Integer): TValorMeteorologiaCaja;
var
  oValores: TJSONArray;
begin
  oValores := AParte.GetValue<TJSONArray>(ACampo);
  if (AIndice < 0) or (AIndice >= oValores.Count) then
    raise EConvertError.Create(SErrorRespuestaMeteoCaja);
  Result := ValorNumero(oValores.Items[AIndice]);
end;

function LeerDiaMeteorologiaCaja(AParte: TJSONObject;
  AIndice: Integer): TParteMeteorologiaCaja;
var
  oDiario: TJSONObject;
  oFechas: TJSONArray;
begin
  Result := Default(TParteMeteorologiaCaja);
  if (AParte.GetValue<string>('daily_units.temperature_2m_mean') <> '°C') or
     (AParte.GetValue<string>('daily_units.rain_sum') <> 'mm') then
    raise EConvertError.Create(SErrorRespuestaMeteoCaja);
  oDiario := AParte.GetValue<TJSONObject>('daily');
  oFechas := oDiario.GetValue<TJSONArray>('time');
  Result.Fecha := ISO8601ToDate(
    oFechas.Items[AIndice].Value + 'T00:00:00Z', True);
  Result.InstanteConsultaUtc := TTimeZone.Local.ToUniversalTime(Now);
  Result.ZonaHoraria := AParte.GetValue<string>('timezone');
  Result.Temperatura := ValorDiario(oDiario, 'temperature_2m_mean', AIndice);
  Result.Nubes := ValorDiario(oDiario, 'cloud_cover_mean', AIndice);
  Result.CodigoTiempo := ValorDiario(oDiario, 'weather_code', AIndice);
  Result.Minima := ValorDiario(oDiario, 'temperature_2m_min', AIndice);
  Result.Maxima := ValorDiario(oDiario, 'temperature_2m_max', AIndice);
  Result.Lluvia := ValorDiario(oDiario, 'rain_sum', AIndice);
  Result.TipoDato := AParte.GetValue<string>('tipo_dato', 'REANALISIS_ERA5');
end;

function LeerParteMeteorologiaCaja(AParte: TJSONObject):
  TParteMeteorologiaCaja;
begin
  if AParte.GetValue<TJSONArray>('daily.time').Count <> 1 then
    raise EConvertError.Create(SErrorRespuestaMeteoCaja);
  Result := LeerDiaMeteorologiaCaja(AParte, 0);
  Result.RespuestaJson := AParte.ToJSON;
  if Result.Fecha <> Date then
    raise EConvertError.Create(SErrorRespuestaMeteoCaja);
end;

function LeerHistoricoMeteorologiaCaja(AParte: TJSONObject):
  TPartesMeteorologiaCaja;
var
  iDia, iCantidad: Integer;
begin
  iCantidad := AParte.GetValue<TJSONArray>('daily.time').Count;
  SetLength(Result, iCantidad);
  for iDia := 0 to iCantidad - 1 do
    Result[iDia] := LeerDiaMeteorologiaCaja(AParte, iDia);
end;

constructor TServicioMeteorologiaCajaHttp.Create(
  const AUrl, AToken: string);
begin
  inherited Create;
  FUrl := IncludeTrailingPathDelimiter(AUrl);
  FUrl := StringReplace(FUrl, '\', '/', [rfReplaceAll]);
  FToken := AToken;
end;

function CrearServicioMeteorologiaCajaHttp(const AUrl, AToken: string):
  IServicioMeteorologiaCaja;
begin
  Result := TServicioMeteorologiaCajaHttp.Create(AUrl, AToken);
end;

function TServicioMeteorologiaCajaHttp.Consultar(
  const AConsulta: string): TJSONObject;
var
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  oSobre: TJSONObject;
  sTexto: string;
begin
  if FToken = '' then
    raise EInvalidOpException.Create(SErrorApiMeteoCaja);
  oHttp := THTTPClient.Create;
  oSobre := nil;
  try
    oHttp.ConnectionTimeout := 10000;
    oHttp.ResponseTimeout := 45000;
    oHttp.HandleRedirects := False;
    oHttp.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
    oRespuesta := oHttp.Get(FUrl +
      'meteorologia_prueba/consultar.php?' + AConsulta);
    sTexto := oRespuesta.ContentAsString(TEncoding.UTF8);
    oSobre := TJSONObject.ParseJSONValue(sTexto) as TJSONObject;
    if not Assigned(oSobre) then
      raise EConvertError.Create(SErrorRespuestaMeteoCaja);
    if (oRespuesta.StatusCode <> 200) or
       not oSobre.GetValue<Boolean>('ok', False) then
      raise EInvalidOpException.Create(
        oSobre.GetValue<string>('error.mensaje', SErrorRespuestaMeteoCaja));
    Result := oSobre.GetValue<TJSONObject>('datos').Clone as TJSONObject;
  finally
    FreeAndNil(oSobre);
    FreeAndNil(oHttp);
  end;
end;

function CoincidePostal(ACiudad: TJSONObject; const APostal: string): Boolean;
var
  oCodigos: TJSONArray;
  oCodigo: TJSONValue;
begin
  Result := False;
  if (APostal <> '') and
     ACiudad.TryGetValue<TJSONArray>('postcodes', oCodigos) then
    for oCodigo in oCodigos do
      Result := Result or SameText(oCodigo.Value, APostal);
end;

function ElegirLocalidad(AResultados: TJSONArray;
  const AUbicacion: TUbicacionMeteorologiaCaja): TJSONObject;
var
  oValor: TJSONValue;
  oCiudad, oUnica, oPostal: TJSONObject;
  iCiudades, iPostales: Integer;
begin
  oUnica := nil;
  oPostal := nil;
  iCiudades := 0;
  iPostales := 0;
  for oValor in AResultados do
  begin
    oCiudad := oValor as TJSONObject;
    if SameText(oCiudad.GetValue<string>('name'), AUbicacion.Ciudad) then
    begin
      Inc(iCiudades);
      oUnica := oCiudad;
      if CoincidePostal(oCiudad, AUbicacion.CodigoPostal) then
      begin
        Inc(iPostales);
        oPostal := oCiudad;
      end;
    end;
  end;
  Result := nil;
  if iPostales = 1 then
    Result := oPostal
  else if iCiudades = 1 then
    Result := oUnica;
  if not Assigned(Result) then
    raise EInvalidOpException.CreateFmt(SErrorLocalidadMeteoCaja,
      [AUbicacion.Ciudad, AUbicacion.CodigoPostal]);
end;

function TServicioMeteorologiaCajaHttp.ResolverLocalidad(
  const AUbicacion: TUbicacionMeteorologiaCaja): TJSONObject;
var
  oCiudades: TJSONObject;
  oResultados: TJSONArray;
begin
  oCiudades := Consultar('accion=ciudad&nombre=' +
    TNetEncoding.URL.Encode(AUbicacion.Ciudad));
  try
    if not oCiudades.TryGetValue<TJSONArray>('results', oResultados) then
      raise EInvalidOpException.CreateFmt(SErrorLocalidadMeteoCaja,
        [AUbicacion.Ciudad, AUbicacion.CodigoPostal]);
    Result := ElegirLocalidad(oResultados, AUbicacion).Clone as TJSONObject;
  finally
    FreeAndNil(oCiudades);
  end;
end;

function TServicioMeteorologiaCajaHttp.ConsultarHoy(
  const AUbicacion: TUbicacionMeteorologiaCaja): TParteMeteorologiaCaja;
var
  oCiudad, oParte: TJSONObject;
  sConsulta: string;
begin
  oCiudad := ResolverLocalidad(AUbicacion);
  oParte := nil;
  try
    sConsulta := 'accion=hoy&fecha=' + FormatDateTime('yyyy-mm-dd', Date) +
      '&latitude=' + oCiudad.GetValue('latitude').Value +
      '&longitude=' + oCiudad.GetValue('longitude').Value +
      '&timezone=' + TNetEncoding.URL.Encode(
        oCiudad.GetValue<string>('timezone'));
    oParte := Consultar(sConsulta);
    Result := LeerParteMeteorologiaCaja(oParte);
    Result.Ciudad := oCiudad.GetValue<string>('name');
    Result.Latitud := oCiudad.GetValue<Double>('latitude');
    Result.Longitud := oCiudad.GetValue<Double>('longitude');
  finally
    FreeAndNil(oParte);
    FreeAndNil(oCiudad);
  end;
end;

function TServicioMeteorologiaCajaHttp.ConsultarTramo(ACiudad: TJSONObject;
  ADesde, AHasta: TDateTime; const AAccion: string):
  TPartesMeteorologiaCaja;
var
  oParte: TJSONObject;
  sConsulta: string;
  iDia: Integer;
begin
  sConsulta := 'accion=' + AAccion + '&latitude=' +
    ACiudad.GetValue('latitude').Value + '&longitude=' +
    ACiudad.GetValue('longitude').Value + '&timezone=' +
    TNetEncoding.URL.Encode(ACiudad.GetValue<string>('timezone')) +
    '&fecha_referencia=' + FormatDateTime('yyyy-mm-dd', Date) +
    '&start_date=' + FormatDateTime('yyyy-mm-dd', ADesde) +
    '&end_date=' + FormatDateTime('yyyy-mm-dd', AHasta);
  oParte := Consultar(sConsulta);
  try
    Result := LeerHistoricoMeteorologiaCaja(oParte);
    for iDia := 0 to High(Result) do
      Result[iDia].Ciudad := ACiudad.GetValue<string>('name');
  finally
    FreeAndNil(oParte);
  end;
end;

function TServicioMeteorologiaCajaHttp.ConsultarHistorico(
  const AUbicacion: TUbicacionMeteorologiaCaja;
  ADesde, AHasta: TDateTime; const ACancelar: TFunc<Boolean>):
  TPartesMeteorologiaCaja;
var
  oCiudad: TJSONObject;
  oDias: TList<TParteMeteorologiaCaja>;
  dtInicio, dtFin, dtCorte: TDateTime;
  sAccion: string;
begin
  oCiudad := ResolverLocalidad(AUbicacion);
  oDias := TList<TParteMeteorologiaCaja>.Create;
  try
    dtInicio := DateOf(ADesde);
    dtCorte := Date - 7;
    while dtInicio <= DateOf(AHasta) do
    begin
      if Assigned(ACancelar) and ACancelar() then
        raise EAbort.Create(SErrorConsultaMeteoCancelada);
      sAccion := 'prevision';
      dtFin := DateOf(AHasta);
      if dtInicio <= dtCorte then
      begin
        sAccion := 'historico';
        dtFin := Min(dtFin, Min(dtCorte, dtInicio + 364));
      end;
      oDias.AddRange(ConsultarTramo(oCiudad, dtInicio, dtFin, sAccion));
      dtInicio := dtFin + 1;
    end;
    Result := oDias.ToArray;
  finally
    FreeAndNil(oDias);
    FreeAndNil(oCiudad);
  end;
end;

end.
