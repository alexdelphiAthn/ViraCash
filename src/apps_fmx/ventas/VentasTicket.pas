{******************************************************************************}
{                                                                              }
{  Módulo:       VentasTicket                                                  }
{    Tipo:       Librería (App FMX)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Descarga autenticada y validación del ticket, sin depender de la UI.      }
{******************************************************************************}
unit VentasTicket;

interface

uses
  System.SysUtils, System.Classes;

const
  cMaximoTicketVenta = 20 * 1024 * 1024;

type
  ICancelacionTicketVenta = interface
    ['{705CE16C-BEF9-4CDF-B88F-12D3FD4228BD}']
    procedure Cancelar;
    function EstaCancelado: Boolean;
  end;

  TCancelacionTicketVenta = class(TInterfacedObject,
    ICancelacionTicketVenta)
  private
    FCancelado: Integer;
  public
    procedure Cancelar;
    function EstaCancelado: Boolean;
  end;

  TPeticionTicketVenta = record
    Empresa: string;
    Serie: string;
    Numero: string;
    UrlBase: string;
    Token: string;
  end;

  TMetadatosTicketVenta = record
    Mime: string;
    Huella: string;
    Tamano: string;
    Longitud: Int64;
  end;

  TResultadoTicketVenta = record
    Contenido: TBytes;
    Error: string;
  end;

  ELimiteTicketVenta = class(Exception);

  TMemoriaTicketVenta = class(TMemoryStream)
  public
    function Write(const ABuffer; ACantidad: Longint): Longint; override;
  end;

  TClienteTicketVenta = class
  private
    class function LeerRespuesta(const AUrl: string;
      const APeticion: TPeticionTicketVenta;
      const ACancelacion: ICancelacionTicketVenta):
      TResultadoTicketVenta; static;
  public
    class function ComponerUrl(const APeticion: TPeticionTicketVenta;
      out AError: string): string; static;
    class function ErrorHttp(AEstado: Integer): string; static;
    class function ValidarContenido(AContenido: TStream;
      const AMetadatos: TMetadatosTicketVenta): string; static;
    class function Descargar(const APeticion: TPeticionTicketVenta;
      const ACancelacion: ICancelacionTicketVenta):
      TResultadoTicketVenta; static;
  end;

implementation

uses
  System.SyncObjs, System.Hash, System.NetEncoding,
  System.Net.URLClient, System.Net.HttpClient, TraduccionMovil;

// Textos en español; Tr los traduce al idioma del dispositivo (TextosVentas).
const
  STicketLimite = 'El ticket supera el límite de 20 MB.';
  STicketConfiguracion = 'Revisa la dirección HTTPS del servidor y la API.';
  STicketIdentificacion = 'Faltan los datos del documento de esta venta.';
  STicketAusente = 'Esta venta todavía no tiene un ticket PDF disponible.';
  STicketAcceso = 'La API no tiene acceso o ha sido revocada. ' +
    'Revisa la configuración de la instalación.';
  STicketRedireccion = 'El servidor ha redirigido la descarga. ' +
    'Revisa la dirección del endpoint.';
  STicketHttp = 'No se pudo recuperar el ticket (HTTP %d).';
  STicketNoPdf = 'El servidor no ha devuelto un ticket PDF válido.';
  STicketIncompleto = 'El ticket llegó incompleto o su huella no coincide. ' +
    'Vuelve a intentarlo.';
  STicketConexion = 'No se pudo descargar el ticket. ' +
    'Comprueba la conexión y vuelve a intentarlo.';
  STicketCancelado = 'Descarga de ticket cancelada.';

procedure TCancelacionTicketVenta.Cancelar;
begin
  TInterlocked.Exchange(FCancelado, 1);
end;

function TCancelacionTicketVenta.EstaCancelado: Boolean;
begin
  Result := TInterlocked.CompareExchange(FCancelado, 0, 0) <> 0;
end;

function TMemoriaTicketVenta.Write(const ABuffer;
  ACantidad: Longint): Longint;
begin
  if (ACantidad < 0) or
     (Position + Int64(ACantidad) > cMaximoTicketVenta) then
    raise ELimiteTicketVenta.Create(Tr(STicketLimite));
  Result := inherited Write(ABuffer, ACantidad);
end;

function IdentificadorValido(const AValor: string): Boolean;
begin
  Result := (Trim(AValor) <> '') and (Length(AValor) <= 20) and
    (Pos(#0, AValor) = 0) and (Pos(#13, AValor) = 0) and
    (Pos(#10, AValor) = 0);
end;

function TokenValido(const AToken: string): Boolean;
var
  cCaracter: Char;
begin
  Result := (AToken <> '') and (Length(AToken) <= 512);
  for cCaracter in AToken do
    Result := Result and (Ord(cCaracter) >= 33) and
      (Ord(cCaracter) <= 126);
end;

class function TClienteTicketVenta.ComponerUrl(
  const APeticion: TPeticionTicketVenta; out AError: string): string;
var
  oUri: TURI;
  sBase: string;
begin
  Result := '';
  AError := '';
  if not (IdentificadorValido(APeticion.Empresa) and
          IdentificadorValido(APeticion.Serie) and
          IdentificadorValido(APeticion.Numero)) then
    AError := Tr(STicketIdentificacion)
  else
  begin
    sBase := Trim(APeticion.UrlBase);
    oUri := TURI.Create(sBase);
    if not SameText(oUri.Scheme, 'https') or (oUri.Host = '') or
       (oUri.Username <> '') or (oUri.Password <> '') or
       (oUri.Query <> '') or (oUri.Fragment <> '') or
       not TokenValido(APeticion.Token) then
      AError := Tr(STicketConfiguracion)
    else
    begin
      if not sBase.EndsWith('/') then
        sBase := sBase + '/';
      Result := sBase + 'ventas/documento.php?tipo=TICKET_PDF' +
        '&empresa=' + TNetEncoding.URL.Encode(APeticion.Empresa) +
        '&serie=' + TNetEncoding.URL.Encode(APeticion.Serie) +
        '&numero=' + TNetEncoding.URL.Encode(APeticion.Numero);
    end;
  end;
end;

class function TClienteTicketVenta.ErrorHttp(AEstado: Integer): string;
begin
  case AEstado of
    200: Result := '';
    401, 403: Result := Tr(STicketAcceso);
    404: Result := Tr(STicketAusente);
    300..399: Result := Tr(STicketRedireccion);
  else
    Result := TrF(STicketHttp, [AEstado]);
  end;
end;

class function TClienteTicketVenta.ValidarContenido(AContenido: TStream;
  const AMetadatos: TMetadatosTicketVenta): string;
var
  aInicio: array[0..4] of AnsiChar;
  iTamano: Int64;
  iSeparador: Integer;
  sMime: string;
begin
  Result := '';
  sMime := AMetadatos.Mime;
  iSeparador := Pos(';', sMime);
  if iSeparador > 0 then
    SetLength(sMime, iSeparador - 1);
  sMime := Trim(sMime);
  if AContenido.Size > cMaximoTicketVenta then
    Result := Tr(STicketLimite)
  else if (AContenido.Size < SizeOf(aInicio)) or
          not SameText(sMime, 'application/pdf') then
    Result := Tr(STicketNoPdf)
  else
  begin
    AContenido.Position := 0;
    AContenido.ReadBuffer(aInicio, SizeOf(aInicio));
    if (aInicio[0] <> '%') or (aInicio[1] <> 'P') or
       (aInicio[2] <> 'D') or (aInicio[3] <> 'F') or
       (aInicio[4] <> '-') then
      Result := Tr(STicketNoPdf)
    else if not TryStrToInt64(AMetadatos.Tamano, iTamano) or
            (iTamano <> AContenido.Size) or
            ((AMetadatos.Longitud >= 0) and
             (AMetadatos.Longitud <> AContenido.Size)) or
            (Length(AMetadatos.Huella) <> 64) then
      Result := Tr(STicketIncompleto)
    else
    begin
      AContenido.Position := 0;
      if not SameText(THashSHA2.GetHashString(AContenido),
          AMetadatos.Huella) then
        Result := Tr(STicketIncompleto);
    end;
  end;
  AContenido.Position := 0;
end;

class function TClienteTicketVenta.LeerRespuesta(const AUrl: string;
  const APeticion: TPeticionTicketVenta;
  const ACancelacion: ICancelacionTicketVenta): TResultadoTicketVenta;
var
  oHttp: THTTPClient;
  oMemoria: TMemoriaTicketVenta;
  oMetadatos: TMetadatosTicketVenta;
  oRespuesta: IHTTPResponse;
begin
  Result := Default(TResultadoTicketVenta);
  oHttp := THTTPClient.Create;
  try
    oHttp.ConnectionTimeout := 10000;
    oHttp.ResponseTimeout := 30000;
    oHttp.HandleRedirects := False;
    oHttp.AllowCookies := False;
    oHttp.ReceiveDataCallBack :=
      procedure(const Sender: TObject; ALongitud, ALeidos: Int64;
        var AAbortar: Boolean)
      begin
        AAbortar := ACancelacion.EstaCancelado or
          (ALongitud > cMaximoTicketVenta) or
          (ALeidos > cMaximoTicketVenta);
      end;
    oMemoria := TMemoriaTicketVenta.Create;
    try
      oRespuesta := oHttp.Get(AUrl, oMemoria,
        [TNetHeader.Create('Authorization', 'Bearer ' + APeticion.Token),
         TNetHeader.Create('Accept', 'application/pdf'),
         TNetHeader.Create('Accept-Encoding', 'identity')]);
      Result.Error := ErrorHttp(oRespuesta.StatusCode);
      if Result.Error = '' then
      begin
        oMetadatos.Mime := oRespuesta.MimeType;
        oMetadatos.Huella := oRespuesta.HeaderValue['X-Venta-Sha256'];
        oMetadatos.Tamano := oRespuesta.HeaderValue['X-Venta-Tamano'];
        oMetadatos.Longitud := oRespuesta.ContentLength;
        Result.Error := ValidarContenido(oMemoria, oMetadatos);
      end;
      if (Result.Error = '') and not ACancelacion.EstaCancelado then
      begin
        SetLength(Result.Contenido, oMemoria.Size);
        oMemoria.ReadBuffer(Result.Contenido[0], oMemoria.Size);
      end;
    finally
      FreeAndNil(oMemoria);
    end;
  finally
    FreeAndNil(oHttp);
  end;
end;

class function TClienteTicketVenta.Descargar(
  const APeticion: TPeticionTicketVenta;
  const ACancelacion: ICancelacionTicketVenta): TResultadoTicketVenta;
var
  sUrl: string;
begin
  Result := Default(TResultadoTicketVenta);
  try
    sUrl := ComponerUrl(APeticion, Result.Error);
    if (Result.Error = '') and not ACancelacion.EstaCancelado then
      Result := LeerRespuesta(sUrl, APeticion, ACancelacion);
  except
    on E: ELimiteTicketVenta do
      Result.Error := Tr(STicketLimite);
    on E: Exception do
      Result.Error := Tr(STicketConexion);
  end;
  if ACancelacion.EstaCancelado then
    Result.Error := Tr(STicketCancelado);
  if Result.Error <> '' then
    SetLength(Result.Contenido, 0);
end;

end.
