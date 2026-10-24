{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasWsCola                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.3.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cola transaccional de eventos de venta y envío al webservice de respaldo. }
{    El alta entra por IAltaVentasWsCola; el despacho de la cola               }
{    por IDespachoVentasWsCola.                                                }
{******************************************************************************}
unit inLibVentasWsCola;

interface

uses
  inLibEstadoColasIntf,
  System.SysUtils, System.Classes, inLibParametrosIntf,
  inLibContextoSesionIntf,
  inLibVentasWsJsonIntf, inLibVentasWsColaIntf, inLibLogIntf;

type
  TVentasWsCola = class
  private
    FHilo: TThread;
    FRegistroLog: IRegistroLog;
    FEstado: IEstadoCola;
    class function Activa(
      const AParametrosCaja: IParametrosCaja): Boolean; static;
    class procedure AdjuntarPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IAltaVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      AEsFactura: Boolean;
      const ARegistroLog: IRegistroLog); static;
  public
    class procedure RegistrarFactura(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IAltaVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ATipoOperacion: string); static;
    class procedure RegistrarEventoSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IAltaVentasWsCola;
      const AUsuario: string;
      const ATipoEvento, ASerie, ANumero: string;
      const ARegistroLog: IRegistroLog); static;
    class procedure AdjuntarTicketPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IAltaVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      const ARegistroLog: IRegistroLog); static;
    class procedure AdjuntarFacturaPdfSeguro(
      const AParametrosCaja: IParametrosCaja;
      const ARepositorio: IAltaVentasWsCola;
      const AUsuario: string;
      const ASerie, ANumero, ARutaPdf: string;
      const ARegistroLog: IRegistroLog); static;
    constructor Create(const ARegistroLog: IRegistroLog;
      const AEstado: IEstadoCola = nil);
    destructor Destroy; override;
    procedure IniciarHilo(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AFabricaSesion: IFabricaSesionVentasWs;
      const AUsuario: string);
    procedure DetenerHilo;
  end;

implementation

uses
  inLibEstadoColas, inLibColasSenal, System.SyncObjs,
  inLibFormatoDocumento, inLibFormatoDocumentoLecturasIntf,
  Winapi.Windows, System.Hash, System.JSON,
  System.Generics.Collections,
  inLibGlobalVar, inLibMsgIntegraciones,
  inLibVentasWsJson, inLibViraCashApi,
  inLibColasHistorialIntf, inLibVentasWsColaHistorialIntf,
  inLibErroresHttp;

type
  THiloVentasWsCola = class(TThread)
  private
    FSesion: ISesionVentasWs;
    FRepositorio: IDespachoVentasWsCola;
    FRegistradorIntentos: IRegistradorIntentosVentasWsCola;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FParametrosCaja: IParametrosCaja;
    FFabricaSesion: IFabricaSesionVentasWs;
    FRegistroLog: IRegistroLog;
    FEstado: IEstadoCola;
    FUsuario: string;
    FAvisoConfiguracion: Boolean;
    procedure EsperarCiclo;
    procedure EsperarSegundos(ASegundos: Integer);
    procedure ProcesarPendientes;
    function ProcesarFila(AIdCola: Int64): Boolean;
    function EnviarConHistorial(
      AIdCola: Int64;
      const AFila: TFilaVentasWsCola;
      const AContenido: string): TResultadoViraCashApi;
    procedure RegistrarIntentoSeguro(
      const AIntento: TIntentoVentasWsCola);
    procedure GuardarError(AIdCola: Int64; const AMensaje: string;
      AIntentos: Integer; AConsumirIntento: Boolean);
    function DebeCancelarEnvio: Boolean;
    procedure AplazarEnvioInterrumpido(AIdCola: Int64;
      const AMensaje: string);
  protected
    procedure Execute; override;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const AParametrosCaja: IParametrosCaja;
      const AFabricaSesion: IFabricaSesionVentasWs;
      const AUsuario: string;
      const ARegistroLog: IRegistroLog;
      const AEstado: IEstadoCola); reintroduce;
    destructor Destroy; override;
  end;

const
  CSegundosReintentoSinConexion = 300;
  cContenidoBase64Omitido =
    '[OMITIDO DEL HISTORIAL: CONTENIDO BINARIO/BASE64]';
  cContenidoSensibleOmitido =
    '[OMITIDO DEL HISTORIAL: CREDENCIAL O SECRETO]';
  cPeticionJsonNoDisponible =
    '[PETICIÓN OMITIDA DEL HISTORIAL: JSON NO VÁLIDO]';
  cRespuestaNoDisponible =
    '[RESPUESTA OMITIDA DEL HISTORIAL: NO SE PUDO SANEAR]';

function EsCampoBinarioHistorial(const ANombre: string): Boolean;
begin
  Result := SameText(ANombre, 'contenido_base64') or
            SameText(ANombre, 'DOCUMENTO_FAC') or
            SameText(ANombre, 'PDF_FAC') or
            SameText(ANombre, 'QRCODE_PNG_FACCON');
end;

function EsCampoSensibleHistorial(const ANombre: string): Boolean;
begin
  Result := SameText(ANombre, 'authorization') or
            SameText(ANombre, 'api_key') or
            SameText(ANombre, 'apikey') or
            SameText(ANombre, 'clave_api') or
            SameText(ANombre, 'password') or
            SameText(ANombre, 'contrasena') or
            SameText(ANombre, 'access_token') or
            SameText(ANombre, 'refresh_token') or
            SameText(ANombre, 'client_secret') or
            SameText(ANombre, 'secret');
end;

procedure OcultarContenidoNoPersistible(AValor: TJSONValue);
var
  iIndice: Integer;
  oObjeto: TJSONObject;
  oPar: TJSONPair;
begin
  if AValor is TJSONObject then
  begin
    oObjeto := TJSONObject(AValor);
    iIndice := 0;
    while iIndice < oObjeto.Count do
    begin
      oPar := oObjeto.Pairs[iIndice];
      if EsCampoBinarioHistorial(oPar.JsonString.Value) then
        oPar.JsonValue := TJSONString.Create(cContenidoBase64Omitido)
      else if EsCampoSensibleHistorial(oPar.JsonString.Value) then
        oPar.JsonValue := TJSONString.Create(cContenidoSensibleOmitido)
      else
        OcultarContenidoNoPersistible(oPar.JsonValue);
      Inc(iIndice);
    end;
  end
  else if AValor is TJSONArray then
  begin
    iIndice := 0;
    while iIndice < TJSONArray(AValor).Count do
    begin
      OcultarContenidoNoPersistible(TJSONArray(AValor).Items[iIndice]);
      Inc(iIndice);
    end;
  end;
end;

function PeticionParaHistorial(const AContenido: string): string;
var
  oJson: TJSONValue;
begin
  Result := cPeticionJsonNoDisponible;
  oJson := nil;
  try
    try
      oJson := TJSONObject.ParseJSONValue(AContenido);
      if Assigned(oJson) then
      begin
        OcultarContenidoNoPersistible(oJson);
        Result := oJson.ToJSON;
      end;
    except
      on E: Exception do
        Result := cPeticionJsonNoDisponible + ' ' + E.ClassName;
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function RespuestaParaHistorial(const AContenido: string): string;
var
  oJson: TJSONValue;
begin
  Result := AContenido;
  oJson := nil;
  try
    try
      oJson := TJSONObject.ParseJSONValue(AContenido);
      if Assigned(oJson) then
      begin
        OcultarContenidoNoPersistible(oJson);
        Result := oJson.ToJSON;
      end;
    except
      on E: Exception do
        Result := AContenido;
    end;
  finally
    FreeAndNil(oJson);
  end;
end;

function OcultarSecretoLiteral(const AContenido, ASecreto: string): string;
begin
  Result := AContenido;
  if ASecreto <> '' then
    Result := StringReplace(
      Result, ASecreto, cContenidoSensibleOmitido, [rfReplaceAll]);
end;

function NuevoUuid: string;
var
  oGuid: TGUID;
  sGuid: string;
begin
  CreateGUID(oGuid);
  sGuid := GUIDToString(oGuid);
  Result := Copy(sGuid, 2, 36);
end;

class function TVentasWsCola.Activa(
  const AParametrosCaja: IParametrosCaja): Boolean;
begin
  Result := Assigned(AParametrosCaja) and
            AParametrosCaja.GetBool('vgerEnviarVentasWS', False);
end;

class procedure TVentasWsCola.RegistrarFactura(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IAltaVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ATipoOperacion: string);
var
  iIdCola: Int64;
  sTipoEvento: string;
begin
  if Activa(AParametrosCaja) then
  begin
    if SameText(ATipoOperacion, 'ANULACION') then
      sTipoEvento := 'VENTA_ANULADA'
    else if SameText(ATipoOperacion, 'SUSTITUCION') then
      sTipoEvento := 'VENTA_SUSTITUIDA'
    else if SameText(ATipoOperacion, 'SUBSANACION') then
      sTipoEvento := 'FISCAL_ACTUALIZADO'
    else
      sTipoEvento := 'VENTA_CONFIRMADA';
    // La cola se escribe dentro de la transacción del llamador: el
    // repositorio trabaja sobre la misma conexión de AQryTrx.
    iIdCola := ARepositorio.Encolar(
      NuevoUuid, sTipoEvento, ASerie, ANumero, AUsuario);
    if iIdCola = 0 then
      raise Exception.Create(FormatearMensajeDocumentos(
        FormatoDocumentoFacturaDelProveedor(ARepositorio, ASerie, ANumero),
        SErrorEncolarVentaWebservice,
        [ASerie, ANumero]));
  end;
end;

class procedure TVentasWsCola.RegistrarEventoSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IAltaVentasWsCola;
  const AUsuario: string;
  const ATipoEvento, ASerie, ANumero: string;
  const ARegistroLog: IRegistroLog);
var
  sReferencia: string;
begin
  sReferencia := FormatearDocumento(
    FORMATO_DOCUMENTO_DEFECTO, ASerie, ANumero);
  if Activa(AParametrosCaja) then
  begin
    try
      sReferencia := FormatearDocumento(
        FormatoDocumentoFacturaDelProveedor(ARepositorio, ASerie, ANumero),
        ASerie, ANumero);
      ARepositorio.Encolar(
        NuevoUuid, ATipoEvento, ASerie, ANumero, AUsuario);
    except
      on E: Exception do
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarError(
            'No se pudo encolar el evento ' + ATipoEvento +
            ' de ' + sReferencia + ': ' + E.Message);
    end;
  end;
end;

class procedure TVentasWsCola.AdjuntarTicketPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IAltaVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  const ARegistroLog: IRegistroLog);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    ARepositorio,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    False,
    ARegistroLog);
end;

class procedure TVentasWsCola.AdjuntarFacturaPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IAltaVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  const ARegistroLog: IRegistroLog);
begin
  AdjuntarPdfSeguro(
    AParametrosCaja,
    ARepositorio,
    AUsuario,
    ASerie,
    ANumero,
    ARutaPdf,
    True,
    ARegistroLog);
end;

class procedure TVentasWsCola.AdjuntarPdfSeguro(
  const AParametrosCaja: IParametrosCaja;
  const ARepositorio: IAltaVentasWsCola;
  const AUsuario: string;
  const ASerie, ANumero, ARutaPdf: string;
  AEsFactura: Boolean;
  const ARegistroLog: IRegistroLog);
var
  iIdCola: Int64;
  sTipoEvento: string;
  sReferencia: string;
begin
  sReferencia := FormatearDocumento(
    FORMATO_DOCUMENTO_DEFECTO, ASerie, ANumero);
  if Activa(AParametrosCaja) and FileExists(ARutaPdf) then
  begin
    if AEsFactura then
      sTipoEvento := 'FACTURA_PDF_ACTUALIZADO'
    else
      sTipoEvento := 'TICKET_PDF_ACTUALIZADO';
    try
      sReferencia := FormatearDocumento(
        FormatoDocumentoFacturaDelProveedor(ARepositorio, ASerie, ANumero),
        ASerie, ANumero);
      if not ARepositorio.ActualizarPdfVentaPendiente(
               AEsFactura, ASerie, ANumero, ARutaPdf, AUsuario) then
      begin
        iIdCola := ARepositorio.Encolar(
          NuevoUuid, sTipoEvento, ASerie, ANumero, AUsuario);
        if iIdCola > 0 then
          ARepositorio.ActualizarPdfPorId(
            AEsFactura, iIdCola, ARutaPdf, AUsuario);
      end;
    except
      on E: Exception do
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarError(
            'No se pudo adjuntar el PDF de ' + sReferencia +
            ' a la cola de ventas: ' + E.Message);
    end;
  end;
end;

constructor TVentasWsCola.Create(
  const ARegistroLog: IRegistroLog; const AEstado: IEstadoCola);
begin
  inherited Create;
  FRegistroLog := ARegistroLog;
  FEstado := AEstado;
  if not Assigned(FEstado) then
    FEstado := CrearEstadoCola;
end;

procedure TVentasWsCola.IniciarHilo(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AFabricaSesion: IFabricaSesionVentasWs;
  const AUsuario: string);
var
  oHilo: TThread;
begin
  if FHilo = nil then
  begin
    oHilo := THiloVentasWsCola.Create(
      AContextoSesion,
      AParametrosApp,
      AParametrosCaja,
      AFabricaSesion,
      AUsuario,
      FRegistroLog, FEstado);
    try
      oHilo.FreeOnTerminate := False;
      oHilo.Start;
      if Assigned(FRegistroLog) then
        FRegistroLog.RegistrarInformacion(
          'Cola de ventas WS: hilo iniciado');
      FHilo := oHilo;
      oHilo := nil;
    finally
      FreeAndNil(oHilo);
    end;
  end;
end;

procedure TVentasWsCola.DetenerHilo;
begin
  if FHilo <> nil then
  begin
    FHilo.Terminate;
    FHilo.WaitFor;
    FreeAndNil(FHilo);
    if Assigned(FRegistroLog) then
      FRegistroLog.RegistrarInformacion(
        'Cola de ventas WS: hilo detenido');
  end;
end;

destructor TVentasWsCola.Destroy;
begin
  DetenerHilo;
  inherited;
end;

constructor THiloVentasWsCola.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const AParametrosCaja: IParametrosCaja;
  const AFabricaSesion: IFabricaSesionVentasWs;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog;
  const AEstado: IEstadoCola);
begin
  FEstado := AEstado;
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(AParametrosApp) then
    raise EArgumentNilException.Create('AParametrosApp');
  if not Assigned(AParametrosCaja) then
    raise EArgumentNilException.Create('AParametrosCaja');
  if not Assigned(AFabricaSesion) then
    raise EArgumentNilException.Create('AFabricaSesion');
  inherited Create(True);
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FParametrosCaja := AParametrosCaja;
  FFabricaSesion := AFabricaSesion;
  FUsuario := AUsuario;
  FRegistroLog := ARegistroLog;
end;

destructor THiloVentasWsCola.Destroy;
begin
  FRegistradorIntentos := nil;
  FRepositorio := nil;
  FSesion := nil;
  FFabricaSesion := nil;
  FContextoSesion := nil;
  FParametrosCaja := nil;
  FParametrosApp := nil;
  FRegistroLog := nil;
  inherited;
end;

procedure THiloVentasWsCola.Execute;
begin
  NameThreadForDebugging('VentasWsCola');
  FAvisoConfiguracion := False;
  while (not Terminated) and (not FContextoSesion.CerrandoAplicacion) do
  begin
    EsperarCiclo;
    if (not Terminated) and (not FContextoSesion.CerrandoAplicacion) then
    begin
      try
        FEstado.IniciarCiclo;
        ProcesarPendientes;
      except
        on E: Exception do
        begin
          if Assigned(FRegistroLog) then
            FRegistroLog.RegistrarError(
              'Cola de ventas WS: ' + E.Message);
          FEstado.Publicar(acIncidencia, E.Message);
          FRegistradorIntentos := nil;
          FRepositorio := nil;
          FSesion := nil;
        end;
      end;
    end;
  end;
end;

procedure THiloVentasWsCola.EsperarCiclo;
var
  iSegundos: Integer;
begin
  iSegundos :=
    FParametrosApp.GetInt('appVentasWsSegundosCiclo', 60);
  if iSegundos < 5 then
    iSegundos := 5;
  EsperarSegundos(iSegundos);
end;

procedure THiloVentasWsCola.EsperarSegundos(ASegundos: Integer);
var
  iPaso: Integer;
  iPasos: Integer;
begin
  if ASegundos > 300 then
    ASegundos := 300;
  iPasos := ASegundos * 10;
  iPaso := 0;
  // FZ-ISSUE-310: «Enviar ya» de la pantalla de la cola corta la espera
  while (iPaso < iPasos) and (not Terminated) and
        (not FContextoSesion.CerrandoAplicacion) do
  begin
    if EsperarProcesadoCola(ccsVentasWs, 100) = wrSignaled then
      Break;
    Inc(iPaso);
  end;
end;

procedure THiloVentasWsCola.ProcesarPendientes;
var
  aPendientes: TArray<Int64>;
  iIndice: Integer;
  iHorasIncidencias: Integer;
begin
  if TVentasWsCola.Activa(FParametrosCaja) then
  begin
    if TClienteViraCashApi.Configurada(FParametrosApp) then
    begin
      FAvisoConfiguracion := False;
      if FSesion = nil then
      begin
        FSesion := FFabricaSesion.CrearSesion;
        if not Assigned(FSesion) then
          raise Exception.Create('La fábrica no creó la sesión VentasWs');
        FRepositorio := FSesion.Repositorio;
        if not Assigned(FRepositorio) then
          raise Exception.Create('La sesión VentasWs no tiene repositorio');
        if not Assigned(FSesion.Json) then
          raise Exception.Create('La sesión VentasWs no tiene serializador');
        FRegistradorIntentos := FSesion.RegistradorIntentos;
      end;
      FRepositorio.ReencolarProcesandoCaducadas;
      aPendientes := FRepositorio.BuscarPendientes(10);
      iIndice := 0;
      while TVentasWsCola.Activa(FParametrosCaja) and
            (iIndice <= High(aPendientes)) and (not Terminated) and
            (not FContextoSesion.CerrandoAplicacion) do
      begin
        if not ProcesarFila(aPendientes[iIndice]) then
          Break;
        Inc(iIndice);
      end;
      if not DebeCancelarEnvio then
      begin
        iHorasIncidencias := HorasIncidenciasColas(FParametrosApp);
        FEstado.FinalizarCiclo(OcultarSecretoLiteral(
          FSesion.LeerIncidencia(iHorasIncidencias),
          TClienteViraCashApi.Token(FParametrosApp)), iHorasIncidencias);
      end;
    end
    else if not FAvisoConfiguracion then
    begin
      if Assigned(FRegistroLog) then
        FRegistroLog.RegistrarAviso(
          'Cola de ventas WS pendiente: falta URL, API key o ' +
          'referencia de instalación.');
      FEstado.Publicar(acIncidencia,
        SColaWsSinConfiguracion);
      FAvisoConfiguracion := True;
    end;
  end
  else
  begin
    FRegistradorIntentos := nil;
    FRepositorio := nil;
    FSesion := nil;
    FAvisoConfiguracion := False;
  end;
end;

function THiloVentasWsCola.ProcesarFila(AIdCola: Int64): Boolean;
var
  oFila: TFilaVentasWsCola;
  oResultado: TResultadoViraCashApi;
  sContenido: string;
  sHuella: string;
begin
  Result := True;
  if FRepositorio.MarcarProcesando(AIdCola, FUsuario) then
  begin
    FEstado.Publicar(acOcupada,
      Format(SColaEnviandoRegistro, [AIdCola]));
    oFila := Default(TFilaVentasWsCola);
    oFila := FRepositorio.LeerFila(AIdCola);
    try
      sContenido := oFila.Contenido;
      if sContenido = '' then
      begin
        sContenido := TVentasWsJson.ConstruirEvento(
          FParametrosApp,
          oVersion,
          FSesion.Json,
          AIdCola,
          oFila.IdEvento, oFila.TipoEvento, oFila.Empresa,
          oFila.Serie, oFila.Numero);
        sHuella := UpperCase(THashSHA2.GetHashString(sContenido));
        FRepositorio.GuardarContenido(AIdCola, sContenido, sHuella);
      end;
      oResultado := EnviarConHistorial(AIdCola, oFila, sContenido);
      if oResultado.Ok then
      begin
        FRepositorio.MarcarEnviada(
          AIdCola, oResultado.IdPeticion, FUsuario);
        FEstado.Publicar(acCorrecta,
          Format(SColaRegistroEnviado, [AIdCola]));
      end
      else
        GuardarError(
          AIdCola, oResultado.Mensaje, oFila.Intentos, True);
    except
      on E: EConexionHttpTemporal do
      begin
        GuardarError(AIdCola, E.Message, oFila.Intentos, False);
        Result := False;
      end;
      on E: EPeticionHttpCancelada do
      begin
        AplazarEnvioInterrumpido(AIdCola, E.Message);
        Result := False;
      end;
      on E: Exception do
        GuardarError(AIdCola, E.Message, oFila.Intentos, True);
    end;
  end;
end;

function THiloVentasWsCola.EnviarConHistorial(
  AIdCola: Int64;
  const AFila: TFilaVentasWsCola;
  const AContenido: string): TResultadoViraCashApi;
var
  iInicioMs: UInt64;
  oIntento: TIntentoVentasWsCola;
  sToken: string;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.Respuesta := '';
  Result.IdPeticion := '';
  Result.Mensaje := '';
  oIntento := Default(TIntentoVentasWsCola);
  oIntento.IdCola := AIdCola;
  oIntento.IdEvento := AFila.IdEvento;
  oIntento.NumeroIntento := AFila.Intentos + 1;
  oIntento.MetodoHttp := 'POST';
  oIntento.RecursoHttp := 'ventas/eventos.php';
  oIntento.Peticion := PeticionParaHistorial(AContenido);
  oIntento.Usuario := FUsuario;
  oIntento.InstanteInicio := Now;
  iInicioMs := GetTickCount64;
  try
    try
      Result := TClienteViraCashApi.EnviarJson(
        FParametrosApp,
        oIntento.RecursoHttp,
        AContenido,
        DebeCancelarEnvio);
    except
      on E: Exception do
      begin
        Result.Mensaje := E.Message;
        // Ni la caída de conexión ni el cierre gastan intento: los
        // trata ProcesarFila.
        if (E is EConexionHttpTemporal) or
           (E is EPeticionHttpCancelada) then
          raise;
      end;
    end;
  finally
    oIntento.InstanteFin := Now;
    if oIntento.InstanteFin < oIntento.InstanteInicio then
      oIntento.InstanteFin := oIntento.InstanteInicio;
    oIntento.DuracionMs := Int64(GetTickCount64 - iInicioMs);
    oIntento.IdPeticion := Result.IdPeticion;
    oIntento.EstadoHttp := Result.EstadoHttp;
    try
      sToken := TClienteViraCashApi.Token(FParametrosApp);
      oIntento.Respuesta := OcultarSecretoLiteral(
        RespuestaParaHistorial(Result.Respuesta), sToken);
      oIntento.Mensaje := OcultarSecretoLiteral(Result.Mensaje, sToken);
    except
      on E: Exception do
      begin
        oIntento.Respuesta := cRespuestaNoDisponible;
        oIntento.Mensaje :=
          'No se pudo sanear la respuesta: ' + E.ClassName;
      end;
    end;
    if Result.Ok then
      oIntento.Resultado := rccCorrecto
    else
      oIntento.Resultado := rccError;
    RegistrarIntentoSeguro(oIntento);
  end;
end;

procedure THiloVentasWsCola.RegistrarIntentoSeguro(
  const AIntento: TIntentoVentasWsCola);
var
  bRegistrado: Boolean;
  sError: string;
begin
  sError := '';
  if Assigned(FRegistradorIntentos) then
  begin
    try
      bRegistrado :=
        FRegistradorIntentos.IntentarRegistrar(AIntento, sError);
      if (not bRegistrado) and (sError = '') then
        sError := 'El registrador no confirmó la escritura.';
    except
      on E: Exception do
        sError := E.Message;
    end;
  end
  else
    sError := 'No hay registrador de intentos disponible.';
  if sError <> '' then
    FEstado.Publicar(acIncidencia, sError);
  if (sError <> '') and Assigned(FRegistroLog) then
  begin
    try
      FRegistroLog.RegistrarAviso(
        'Cola de ventas WS: no se guardó el historial: ' + sError);
    except
      on E: Exception do
        sError := E.Message;
    end;
  end;
end;

procedure THiloVentasWsCola.GuardarError(AIdCola: Int64;
  const AMensaje: string; AIntentos: Integer;
  AConsumirIntento: Boolean);
var
  iEspera: Integer;
  iMaxIntentos: Integer;
  sEstado: string;
begin
  FEstado.Publicar(acIncidencia, Format(SColaErrorRegistro,
    [AIdCola, OcultarSecretoLiteral(
      AMensaje, TClienteViraCashApi.Token(FParametrosApp))]));
  if not AConsumirIntento then
  begin
    // Una caída del transporte no contamina el presupuesto de errores
    // funcionales y se reintenta sin máximo.
    iEspera := CSegundosReintentoSinConexion;
    sEstado := 'PENDIENTE';
  end
  else
  begin
    // Los errores contabilizables conservan el backoff y el máximo.
    iMaxIntentos :=
      FParametrosApp.GetInt('appVentasWsMaxIntentos', 20);
    if AIntentos > 6 then
      iEspera := 60 * 64
    else
      iEspera := 60 * (1 shl AIntentos);
    if (AIntentos + 1) >= iMaxIntentos then
      sEstado := 'ERROR'
    else
      sEstado := 'PENDIENTE';
  end;
  FRepositorio.GuardarErrorIntento(
    AIdCola, sEstado, iEspera, AMensaje, FUsuario, AConsumirIntento);
  if (not AConsumirIntento) and Assigned(FRegistroLog) then
    FRegistroLog.RegistrarAviso(
      'Cola de ventas WS aplazada por falta de conexión; ' +
      'el intento no se contabiliza: ' + AMensaje);
end;

{ Al cerrar, DetenerHilo espera a este hilo: el envío en curso se corta en
  vez de agotar los tiempos de espera de WinHTTP. }
function THiloVentasWsCola.DebeCancelarEnvio: Boolean;
begin
  Result := Terminated or FContextoSesion.CerrandoAplicacion;
end;

procedure THiloVentasWsCola.AplazarEnvioInterrumpido(AIdCola: Int64;
  const AMensaje: string);
begin
  // Lo cortó el cierre, no el servidor: vuelve a PENDIENTE sin gastar
  // intento ni esperar. Si el servidor llegó a recibirlo, acepta el
  // reenvío como repetido (mismo id de evento y misma huella).
  FRepositorio.GuardarErrorIntento(
    AIdCola, 'PENDIENTE', 0, AMensaje, FUsuario, False);
  if Assigned(FRegistroLog) then
    FRegistroLog.RegistrarInformacion(
      'Cola de ventas WS: envío interrumpido por el cierre; ' +
      'el intento no se contabiliza.');
end;

end.
