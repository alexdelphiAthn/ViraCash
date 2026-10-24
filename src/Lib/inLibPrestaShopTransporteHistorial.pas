{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPrestaShopTransporteHistorial                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Decora el transporte PrestaShop y registra cada operación HTTP sin        }
{    conservar credenciales, URL base, rutas locales ni contenido binario.     }
{******************************************************************************}
unit inLibPrestaShopTransporteHistorial;

interface

uses
  inLibPrestaCatalogoIntf, inLibPrestaShopColaHistorialIntf;

type
  TContextoTransportePrestaShop = record
    IdCola: Int64;
    IdReclamacion: string;
    VersionReclamada: Int64;
    NumeroIntento: Integer;
    Usuario: string;
    OrdenOperacion: Integer;
  end;

  ITransportePrestaShopConHistorial = interface(ITransporteAltaPresta)
    ['{C1B63A59-8491-452E-BE4C-6C3A02CD142F}']
    procedure EstablecerContexto(
      const AContexto: TContextoTransportePrestaShop);
    procedure LimpiarContexto;
  end;

function CrearTransportePrestaShopConHistorial(
  const ATransporte: ITransporteAltaPresta;
  const ARegistrador: IRegistradorEventosPrestaShopCola;
  const AUrlBase: string;
  const ASecreto: string):
  ITransportePrestaShopConHistorial;

implementation

uses
  System.Diagnostics, System.Hash, System.IOUtils,
  System.RegularExpressions, System.SysUtils,
  inLibColasHistorialIntf;

const
  CMetodoGet = 'GET';
  CMetodoPatch = 'PATCH';
  CMetodoPost = 'POST';
  CTextoOculto = '[OCULTO]';

type
  TTransportePrestaShopConHistorial = class(
    TInterfacedObject,
    ITransportePrestaShopConHistorial)
  private
    FTransporte: ITransporteAltaPresta;
    FRegistrador: IRegistradorEventosPrestaShopCola;
    FContexto: TContextoTransportePrestaShop;
    FHayContexto: Boolean;
    FUltimoErrorRegistro: string;
    FSecreto: string;
    FUrlBase: string;
    function CrearEvento(const AMetodo, ARecurso,
      APeticion: string): TEventoPrestaShopCola;
    function CrearEventoImagenSeguro(
      const ARecurso, ARutaImagen: string): TEventoPrestaShopCola;
    function CrearEventoSeguro(const AMetodo, ARecurso,
      APeticion: string): TEventoPrestaShopCola;
    function DescribirImagen(const ARutaImagen: string): string;
    function EsRespuestaCorrecta(AEstadoHttp: Integer): Boolean;
    function SanearRecurso(const ARecurso: string): string;
    function SanearTexto(const ATexto: string): string;
    procedure CompletarConExcepcion(
      var AEvento: TEventoPrestaShopCola;
      const AError: Exception;
      const ARutaLocal: string;
      const ACronometro: TStopwatch);
    procedure CompletarConRespuesta(
      var AEvento: TEventoPrestaShopCola;
      const ARespuesta: TRespuestaHttpPresta;
      const ACronometro: TStopwatch);
    procedure FinalizarTiempos(
      var AEvento: TEventoPrestaShopCola;
      const ACronometro: TStopwatch);
    procedure IntentarCompletarConExcepcion(
      var AEvento: TEventoPrestaShopCola;
      const AError: Exception;
      const ARutaLocal: string;
      const ACronometro: TStopwatch);
    procedure IntentarCompletarConRespuesta(
      var AEvento: TEventoPrestaShopCola;
      const ARespuesta: TRespuestaHttpPresta;
      const ACronometro: TStopwatch);
    procedure RegistrarEvento(const AEvento: TEventoPrestaShopCola);
    function ContextoValido(
      const AContexto: TContextoTransportePrestaShop): Boolean;
  public
    constructor Create(
      const ATransporte: ITransporteAltaPresta;
      const ARegistrador: IRegistradorEventosPrestaShopCola;
      const AUrlBase: string;
      const ASecreto: string);
    destructor Destroy; override;
    function EjecutarGet(
      const ARecurso: string): TRespuestaHttpPresta;
    function EjecutarPatch(const ARecurso, AXml: string):
      TRespuestaHttpPresta;
    function EjecutarPostXml(const ARecurso, AXml: string):
      TRespuestaHttpPresta;
    function EjecutarPostImagen(const ARecurso, ARutaImagen: string):
      TRespuestaHttpPresta;
    procedure EstablecerContexto(
      const AContexto: TContextoTransportePrestaShop);
    procedure LimpiarContexto;
  end;

constructor TTransportePrestaShopConHistorial.Create(
  const ATransporte: ITransporteAltaPresta;
  const ARegistrador: IRegistradorEventosPrestaShopCola;
  const AUrlBase: string;
  const ASecreto: string);
begin
  if not Assigned(ATransporte) then
    raise EArgumentNilException.Create('ATransporte');
  inherited Create;
  FTransporte := ATransporte;
  FRegistrador := ARegistrador;
  FUrlBase := Trim(AUrlBase);
  while (Length(FUrlBase) > 0) and
        CharInSet(FUrlBase[Length(FUrlBase)], ['/', '\']) do
    Delete(FUrlBase, Length(FUrlBase), 1);
  FSecreto := ASecreto;
  LimpiarContexto;
end;

destructor TTransportePrestaShopConHistorial.Destroy;
begin
  FSecreto := '';
  FUrlBase := '';
  FRegistrador := nil;
  FTransporte := nil;
  inherited;
end;

function TTransportePrestaShopConHistorial.ContextoValido(
  const AContexto: TContextoTransportePrestaShop): Boolean;
begin
  Result := (AContexto.IdCola > 0) and
    (Trim(AContexto.IdReclamacion) <> '') and
    (AContexto.VersionReclamada > 0) and
    (AContexto.NumeroIntento > 0) and
    (AContexto.OrdenOperacion >= 0);
end;

procedure TTransportePrestaShopConHistorial.EstablecerContexto(
  const AContexto: TContextoTransportePrestaShop);
begin
  LimpiarContexto;
  if ContextoValido(AContexto) then
  begin
    FContexto := AContexto;
    FContexto.IdReclamacion := Trim(FContexto.IdReclamacion);
    FContexto.Usuario := Trim(FContexto.Usuario);
    if FContexto.Usuario = '' then
      FContexto.Usuario := 'SISTEMA';
    FHayContexto := True;
  end
  else
    FUltimoErrorRegistro :=
      'El contexto del historial PrestaShop no es válido';
end;

procedure TTransportePrestaShopConHistorial.LimpiarContexto;
begin
  FContexto := Default(TContextoTransportePrestaShop);
  FHayContexto := False;
end;

function TTransportePrestaShopConHistorial.SanearTexto(
  const ATexto: string): string;
begin
  Result := ATexto;
  if FUrlBase <> '' then
    Result := StringReplace(
      Result,
      FUrlBase,
      '[URL BASE OCULTA]',
      [rfReplaceAll, rfIgnoreCase]);
  if FSecreto <> '' then
    Result := StringReplace(
      Result,
      FSecreto,
      CTextoOculto,
      [rfReplaceAll, rfIgnoreCase]);
  Result := TRegEx.Replace(
    Result,
    '(?im)authorization\s*:[^\r\n]*',
    'Authorization: ' + CTextoOculto);
  Result := TRegEx.Replace(
    Result,
    '(?i)\bhttps?://[^\s<>"'']+',
    '[URL OCULTA]');
  Result := TRegEx.Replace(
    Result,
    '(?i)\b[a-z]:[\\/][^\r\n<>"|?*:]*',
    '[RUTA LOCAL OCULTA]');
  Result := TRegEx.Replace(
    Result,
    '(?m)\\\\[^\\\r\n]+\\[^\r\n<>"|?*:]*',
    '[RUTA LOCAL OCULTA]');
  Result := TRegEx.Replace(
    Result,
    '(?i)(ws_key|api_key|apikey|token|key)\s*=\s*' +
    '[^&\s<>"'']+',
    '$1=' + CTextoOculto);
  Result := TRegEx.Replace(
    Result,
    '(?is)<(password|passwd|ws_key|api_key|apikey|' +
    'authorization)>.*?</\1>',
    '<$1>' + CTextoOculto + '</$1>');
  Result := TRegEx.Replace(
    Result,
    '(?i)"(password|passwd|ws_key|api_key|apikey|' +
    'authorization)"\s*:\s*"[^"]*"',
    '"$1":"' + CTextoOculto + '"');
end;

function TTransportePrestaShopConHistorial.SanearRecurso(
  const ARecurso: string): string;
var
  iInicio: Integer;
  iSeparador: Integer;
  sRecurso: string;
begin
  sRecurso := Trim(ARecurso);
  iInicio := Pos('://', sRecurso);
  if iInicio > 0 then
  begin
    Inc(iInicio, 3);
    iSeparador := iInicio;
    while (iSeparador <= Length(sRecurso)) and
          (not CharInSet(sRecurso[iSeparador], ['/', '?', '#'])) do
      Inc(iSeparador);
    if iSeparador <= Length(sRecurso) then
      sRecurso := Copy(sRecurso, iSeparador, MaxInt)
    else
      sRecurso := '';
  end;
  Result := AcotarTextoHistorial(
    SanearTexto(sRecurso),
    CMaximoRecursoHistorial);
end;

function TTransportePrestaShopConHistorial.DescribirImagen(
  const ARutaImagen: string): string;
var
  iTamano: Int64;
  sHash: string;
  sNombre: string;
begin
  sNombre := ExtractFileName(ARutaImagen);
  if sNombre = '' then
    sNombre := '[SIN NOMBRE]';
  Result := 'archivo=' + sNombre;
  try
    iTamano := TFile.GetSize(ARutaImagen);
    sHash := UpperCase(
      THashSHA2.GetHashStringFromFile(ARutaImagen));
    Result := Result + sLineBreak +
      'tamano_bytes=' + IntToStr(iTamano) + sLineBreak +
      'sha256=' + sHash;
  except
    on E: Exception do
      Result := Result + sLineBreak +
        'metadatos=no_disponibles';
  end;
  Result := AcotarTextoHistorial(
    Result,
    CMaximoPeticionHistorial);
end;

function TTransportePrestaShopConHistorial.CrearEvento(
  const AMetodo, ARecurso, APeticion: string): TEventoPrestaShopCola;
begin
  Result := Default(TEventoPrestaShopCola);
  Result.InstanteInicio := Now;
  if FHayContexto then
  begin
    Inc(FContexto.OrdenOperacion);
    Result.IdCola := FContexto.IdCola;
    Result.IdReclamacion := FContexto.IdReclamacion;
    Result.VersionReclamada := FContexto.VersionReclamada;
    Result.NumeroIntento := FContexto.NumeroIntento;
    Result.OrdenOperacion := FContexto.OrdenOperacion;
    Result.MetodoHttp := AMetodo;
    Result.RecursoHttp := SanearRecurso(ARecurso);
    Result.Peticion := AcotarTextoHistorial(
      SanearTexto(APeticion),
      CMaximoPeticionHistorial);
    Result.Usuario := FContexto.Usuario;
  end;
end;

function TTransportePrestaShopConHistorial.CrearEventoSeguro(
  const AMetodo, ARecurso,
  APeticion: string): TEventoPrestaShopCola;
begin
  Result := Default(TEventoPrestaShopCola);
  try
    Result := CrearEvento(AMetodo, ARecurso, APeticion);
  except
    on E: Exception do
      FUltimoErrorRegistro := E.ClassName + ': ' + E.Message;
  end;
end;

function TTransportePrestaShopConHistorial.CrearEventoImagenSeguro(
  const ARecurso, ARutaImagen: string): TEventoPrestaShopCola;
begin
  Result := Default(TEventoPrestaShopCola);
  try
    Result := CrearEvento(
      CMetodoPost,
      ARecurso,
      DescribirImagen(ARutaImagen));
  except
    on E: Exception do
      FUltimoErrorRegistro := E.ClassName + ': ' + E.Message;
  end;
end;

function TTransportePrestaShopConHistorial.EsRespuestaCorrecta(
  AEstadoHttp: Integer): Boolean;
begin
  Result := (AEstadoHttp >= 200) and (AEstadoHttp < 300);
end;

procedure TTransportePrestaShopConHistorial.FinalizarTiempos(
  var AEvento: TEventoPrestaShopCola;
  const ACronometro: TStopwatch);
begin
  AEvento.DuracionMs := ACronometro.ElapsedMilliseconds;
  AEvento.InstanteFin := Now;
  if AEvento.InstanteFin < AEvento.InstanteInicio then
    AEvento.InstanteFin := AEvento.InstanteInicio;
end;

procedure TTransportePrestaShopConHistorial.RegistrarEvento(
  const AEvento: TEventoPrestaShopCola);
begin
  if FHayContexto and Assigned(FRegistrador) then
  begin
    try
      FRegistrador.IntentarRegistrar(
        AEvento,
        FUltimoErrorRegistro);
    except
      on E: Exception do
        FUltimoErrorRegistro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

procedure TTransportePrestaShopConHistorial.CompletarConRespuesta(
  var AEvento: TEventoPrestaShopCola;
  const ARespuesta: TRespuestaHttpPresta;
  const ACronometro: TStopwatch);
begin
  FinalizarTiempos(AEvento, ACronometro);
  AEvento.EstadoHttp := ARespuesta.EstadoHttp;
  AEvento.TextoEstado := AcotarTextoHistorial(
    SanearTexto(ARespuesta.TextoEstado),
    CMaximoTextoEstadoHistorial);
  AEvento.Respuesta := AcotarTextoHistorial(
    SanearTexto(ARespuesta.Contenido),
    CMaximoRespuestaHistorial);
  if EsRespuestaCorrecta(ARespuesta.EstadoHttp) then
    AEvento.Resultado := rccCorrecto
  else
  begin
    AEvento.Resultado := rccError;
    AEvento.Mensaje := AcotarTextoHistorial(
      Format(
        'HTTP %d %s',
        [ARespuesta.EstadoHttp, AEvento.TextoEstado]),
      CMaximoMensajeHistorial);
  end;
  RegistrarEvento(AEvento);
end;

procedure TTransportePrestaShopConHistorial.CompletarConExcepcion(
  var AEvento: TEventoPrestaShopCola;
  const AError: Exception;
  const ARutaLocal: string;
  const ACronometro: TStopwatch);
var
  sMensaje: string;
begin
  FinalizarTiempos(AEvento, ACronometro);
  AEvento.EstadoHttp := 0;
  AEvento.TextoEstado := AcotarTextoHistorial(
    AError.ClassName,
    CMaximoTextoEstadoHistorial);
  AEvento.Resultado := rccError;
  sMensaje := AError.ClassName + ': ' + AError.Message;
  if ARutaLocal <> '' then
    sMensaje := StringReplace(
      sMensaje,
      ARutaLocal,
      ExtractFileName(ARutaLocal),
      [rfReplaceAll, rfIgnoreCase]);
  AEvento.Mensaje := AcotarTextoHistorial(
    SanearTexto(sMensaje),
    CMaximoMensajeHistorial);
  RegistrarEvento(AEvento);
end;

procedure TTransportePrestaShopConHistorial.IntentarCompletarConRespuesta(
  var AEvento: TEventoPrestaShopCola;
  const ARespuesta: TRespuestaHttpPresta;
  const ACronometro: TStopwatch);
begin
  try
    CompletarConRespuesta(AEvento, ARespuesta, ACronometro);
  except
    on E: Exception do
      FUltimoErrorRegistro := E.ClassName + ': ' + E.Message;
  end;
end;

procedure TTransportePrestaShopConHistorial.IntentarCompletarConExcepcion(
  var AEvento: TEventoPrestaShopCola;
  const AError: Exception;
  const ARutaLocal: string;
  const ACronometro: TStopwatch);
begin
  try
    CompletarConExcepcion(
      AEvento,
      AError,
      ARutaLocal,
      ACronometro);
  except
    on E: Exception do
      FUltimoErrorRegistro := E.ClassName + ': ' + E.Message;
  end;
end;

function TTransportePrestaShopConHistorial.EjecutarGet(
  const ARecurso: string): TRespuestaHttpPresta;
var
  oCronometro: TStopwatch;
  rEvento: TEventoPrestaShopCola;
begin
  rEvento := CrearEventoSeguro(CMetodoGet, ARecurso, '');
  oCronometro := TStopwatch.StartNew;
  try
    Result := FTransporte.EjecutarGet(ARecurso);
    IntentarCompletarConRespuesta(rEvento, Result, oCronometro);
  except
    on E: Exception do
    begin
      IntentarCompletarConExcepcion(
        rEvento,
        E,
        '',
        oCronometro);
      raise;
    end;
  end;
end;

function TTransportePrestaShopConHistorial.EjecutarPatch(
  const ARecurso, AXml: string): TRespuestaHttpPresta;
var
  oCronometro: TStopwatch;
  rEvento: TEventoPrestaShopCola;
begin
  rEvento := CrearEventoSeguro(CMetodoPatch, ARecurso, AXml);
  oCronometro := TStopwatch.StartNew;
  try
    Result := FTransporte.EjecutarPatch(ARecurso, AXml);
    IntentarCompletarConRespuesta(rEvento, Result, oCronometro);
  except
    on E: Exception do
    begin
      IntentarCompletarConExcepcion(
        rEvento,
        E,
        '',
        oCronometro);
      raise;
    end;
  end;
end;

function TTransportePrestaShopConHistorial.EjecutarPostXml(
  const ARecurso, AXml: string): TRespuestaHttpPresta;
var
  oCronometro: TStopwatch;
  rEvento: TEventoPrestaShopCola;
begin
  rEvento := CrearEventoSeguro(CMetodoPost, ARecurso, AXml);
  oCronometro := TStopwatch.StartNew;
  try
    Result := FTransporte.EjecutarPostXml(ARecurso, AXml);
    IntentarCompletarConRespuesta(rEvento, Result, oCronometro);
  except
    on E: Exception do
    begin
      IntentarCompletarConExcepcion(
        rEvento,
        E,
        '',
        oCronometro);
      raise;
    end;
  end;
end;

function TTransportePrestaShopConHistorial.EjecutarPostImagen(
  const ARecurso, ARutaImagen: string): TRespuestaHttpPresta;
var
  oCronometro: TStopwatch;
  rEvento: TEventoPrestaShopCola;
begin
  rEvento := CrearEventoImagenSeguro(
    ARecurso,
    ARutaImagen);
  oCronometro := TStopwatch.StartNew;
  try
    Result := FTransporte.EjecutarPostImagen(
      ARecurso,
      ARutaImagen);
    IntentarCompletarConRespuesta(rEvento, Result, oCronometro);
  except
    on E: Exception do
    begin
      IntentarCompletarConExcepcion(
        rEvento,
        E,
        ARutaImagen,
        oCronometro);
      raise;
    end;
  end;
end;

function CrearTransportePrestaShopConHistorial(
  const ATransporte: ITransporteAltaPresta;
  const ARegistrador: IRegistradorEventosPrestaShopCola;
  const AUrlBase: string;
  const ASecreto: string):
  ITransportePrestaShopConHistorial;
begin
  Result := TTransportePrestaShopConHistorial.Create(
    ATransporte,
    ARegistrador,
    AUrlBase,
    ASecreto);
end;

end.
