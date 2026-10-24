{******************************************************************************}
{                                                                              }
{  Módulo:       inLibActualizacionServicio                                    }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta y descarga las actualizaciones publicadas en el webservice.      }
{******************************************************************************}
unit inLibActualizacionServicio;

interface

uses
  inLibActualizacionIntf,
  inLibParametrosIntf;

function CrearServicioActualizaciones(
  const AParametros: IParametrosAplicacion;
  const AProgreso: TProgresoActualizacion = nil): IServicioActualizaciones;

implementation

uses
  System.Classes,
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.JSON,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.SysUtils,
  System.Zip,
  inLibActualizacionInstalacion,
  inLibViraCashApi,
  inLibMsgIntegraciones;

const
  cRutaUltimaActualizacion = 'actualizaciones/ultima.php';
  cRutaDescargaActualizacion = 'actualizaciones/descargar.php';
  cTiempoConexionActualizacion = 15000;
  cTiempoRespuestaActualizacion = 900000;

type
  TServicioActualizaciones = class(
    TInterfacedObject,
    IServicioActualizaciones)
  private
    FParametros: IParametrosAplicacion;
    FProgreso: TProgresoActualizacion;
    function DescargarArchivoEnFlujo(
      const AConsulta, ARutaDestino: string;
      ATamanoEsperado: Int64;
      out AError: string): Boolean;
    function ExtraerUnicaEntradaZip(
      const ARutaZip, ANombre, ARutaDestino: string;
      out AError: string): Boolean;
    procedure Notificar(const ATexto: string; APorcentaje: Integer);
  public
    constructor Create(
      const AParametros: IParametrosAplicacion;
      const AProgreso: TProgresoActualizacion);
    function Configurado: Boolean;
    function ConsultarUltima(
      const AVersionInstalada: string): TManifiestoActualizacion;
    function DescargarEntrada(
      const AVersion, ATipo: string;
      const AEntrada: TEntradaActualizacion;
      const ARutaDestino: string;
      out AError: string): Boolean;
  end;

function TextoJson(
  AJson: TJSONObject;
  const ANombre: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  if Assigned(AJson) then
  begin
    oValor := AJson.GetValue(ANombre);
    if Assigned(oValor) and not (oValor is TJSONNull) then
      Result := oValor.Value;
  end;
end;

function EnteroJson(
  AJson: TJSONObject;
  const ANombre: string): Int64;
begin
  Result := StrToInt64Def(TextoJson(AJson, ANombre), 0);
end;

function BooleanoJson(
  AJson: TJSONObject;
  const ANombre: string): Boolean;
var
  oValor: TJSONValue;
begin
  Result := False;
  if Assigned(AJson) then
  begin
    oValor := AJson.GetValue(ANombre);
    Result := oValor is TJSONTrue;
  end;
end;

function LeerEntrada(AJson: TJSONValue): TEntradaActualizacion;
var
  oObjeto: TJSONObject;
begin
  Result := Default(TEntradaActualizacion);
  if AJson is TJSONObject then
  begin
    oObjeto := TJSONObject(AJson);
    Result.Nombre := TextoJson(oObjeto, 'nombre');
    Result.Archivo := TextoJson(oObjeto, 'archivo');
    Result.Compresion := TextoJson(oObjeto, 'compresion');
    Result.Tamano := EnteroJson(oObjeto, 'tamano');
    Result.Sha256 := LowerCase(TextoJson(oObjeto, 'sha256'));
    Result.TamanoDescarga := EnteroJson(oObjeto, 'tamano_descarga');
    Result.Sha256Descarga := LowerCase(
      TextoJson(oObjeto, 'sha256_descarga'));
    if Result.Compresion = '' then
      Result.Compresion := cCompresionActualizacionNinguna;
    if Result.TamanoDescarga <= 0 then
      Result.TamanoDescarga := Result.Tamano;
    if Result.Sha256Descarga = '' then
      Result.Sha256Descarga := Result.Sha256;
  end;
end;

procedure LeerAuxiliares(
  AJson: TJSONObject;
  var AManifiesto: TManifiestoActualizacion);
var
  iIndice: Integer;
  oLista: TJSONArray;
  oValor: TJSONValue;
begin
  AManifiesto.Auxiliares := nil;
  oValor := AJson.GetValue('auxiliares');
  if oValor is TJSONArray then
  begin
    oLista := TJSONArray(oValor);
    SetLength(AManifiesto.Auxiliares, oLista.Count);
    for iIndice := 0 to oLista.Count - 1 do
      AManifiesto.Auxiliares[iIndice] := LeerEntrada(oLista.Items[iIndice]);
  end;
end;

function LeerListaTextos(AJson: TJSONValue): TArray<string>;
var
  iIndice: Integer;
  oLista: TJSONArray;
begin
  Result := nil;
  if AJson is TJSONArray then
  begin
    oLista := TJSONArray(AJson);
    for iIndice := 0 to oLista.Count - 1 do
    begin
      if oLista.Items[iIndice] is TJSONString then
        Result := Result + [Trim(oLista.Items[iIndice].Value)];
    end;
  end;
end;

procedure LeerComparacion(
  AJson: TJSONObject;
  var AManifiesto: TManifiestoActualizacion);
var
  oValor: TJSONValue;
begin
  AManifiesto.Modelo := Default(TEntradaActualizacion);
  AManifiesto.Comparador := Default(TEntradaActualizacion);
  oValor := AJson.GetValue('comparacion');
  if oValor is TJSONObject then
  begin
    AManifiesto.Modelo := LeerEntrada(
      TJSONObject(oValor).GetValue('modelo'));
    AManifiesto.Comparador := LeerEntrada(
      TJSONObject(oValor).GetValue('comparador'));
  end;
end;

procedure LeerScripts(
  AJson: TJSONObject;
  var AManifiesto: TManifiestoActualizacion);
var
  iIndice: Integer;
  oLista: TJSONArray;
  oScript: TJSONObject;
  oValor: TJSONValue;
begin
  AManifiesto.Scripts := nil;
  oValor := AJson.GetValue('scripts');
  if oValor is TJSONArray then
  begin
    oLista := TJSONArray(oValor);
    SetLength(AManifiesto.Scripts, oLista.Count);
    for iIndice := 0 to oLista.Count - 1 do
    begin
      AManifiesto.Scripts[iIndice] := Default(TScriptActualizacion);
      if oLista.Items[iIndice] is TJSONObject then
      begin
        oScript := TJSONObject(oLista.Items[iIndice]);
        AManifiesto.Scripts[iIndice].Entrada := LeerEntrada(oScript);
        AManifiesto.Scripts[iIndice].Orden := EnteroJson(oScript, 'orden');
        AManifiesto.Scripts[iIndice].Rollback := LeerEntrada(
          oScript.GetValue('rollback'));
        AManifiesto.Scripts[iIndice].Requiere := LeerListaTextos(
          oScript.GetValue('requiere'));
      end;
    end;
  end;
end;

procedure LeerManifiesto(
  AJson: TJSONObject;
  var AManifiesto: TManifiestoActualizacion);
var
  oDatos: TJSONObject;
  oValor: TJSONValue;
begin
  oValor := AJson.GetValue('datos');
  if not (oValor is TJSONObject) then
    AManifiesto.Mensaje := SErrorRespuestaActualizacionNoValida
  else
  begin
    oDatos := TJSONObject(oValor);
    AManifiesto.HayVersion := BooleanoJson(oDatos, 'hay_version');
    AManifiesto.HayActualizacion := BooleanoJson(oDatos, 'hay_actualizacion');
    AManifiesto.Version := TextoJson(oDatos, 'version');
    AManifiesto.Fecha := TextoJson(oDatos, 'fecha');
    AManifiesto.Notas := TextoJson(oDatos, 'notas');
    AManifiesto.Arquitectura := TextoJson(oDatos, 'arquitectura');
    AManifiesto.Ejecutable := LeerEntrada(oDatos.GetValue('ejecutable'));
    AManifiesto.Comprobacion := LeerEntrada(oDatos.GetValue('comprobacion'));
    LeerAuxiliares(oDatos, AManifiesto);
    LeerScripts(oDatos, AManifiesto);
    LeerComparacion(oDatos, AManifiesto);
    AManifiesto.Ok := True;
  end;
end;

{ TServicioActualizaciones }

constructor TServicioActualizaciones.Create(
  const AParametros: IParametrosAplicacion;
  const AProgreso: TProgresoActualizacion);
begin
  inherited Create;
  FParametros := AParametros;
  FProgreso := AProgreso;
end;

procedure TServicioActualizaciones.Notificar(
  const ATexto: string;
  APorcentaje: Integer);
var
  Progreso: TProgresoActualizacion;
begin
  Progreso := FProgreso;
  if Assigned(Progreso) then
  begin
    if TThread.CurrentThread.ThreadID = MainThreadID then
      Progreso(ATexto, APorcentaje)
    else
      // Las descargas corren en su propio hilo y la pantalla solo se toca
      // desde el principal, que mientras espera atiende estas peticiones.
      TThread.Synchronize(
        nil,
        procedure
        begin
          Progreso(ATexto, APorcentaje);
        end);
  end;
end;

function TServicioActualizaciones.Configurado: Boolean;
begin
  Result := TClienteViraCashApi.Configurada(FParametros);
end;

function TServicioActualizaciones.ConsultarUltima(
  const AVersionInstalada: string): TManifiestoActualizacion;
var
  oJson: TJSONValue;
  oResultado: TResultadoViraCashApi;
  sContenido: string;
begin
  Result := Default(TManifiestoActualizacion);
  Result.Arquitectura := ArquitecturaActualizacionActual;
  if not Configurado then
    Result.Mensaje := SErrorActualizacionesNoConfiguradas
  else
  begin
    Notificar(SInfoConsultandoActualizaciones, 5);
    oResultado := TClienteViraCashApi.RecibirJson(
      FParametros,
      cRutaUltimaActualizacion,
      TClienteViraCashApi.ComponerConsulta(
        ['version', 'arquitectura'],
        [AVersionInstalada, ArquitecturaActualizacionActual]),
      sContenido);
    Result.Mensaje := oResultado.Mensaje;
    if oResultado.Ok then
    begin
      oJson := TJSONObject.ParseJSONValue(sContenido);
      try
        if oJson is TJSONObject then
          LeerManifiesto(TJSONObject(oJson), Result)
        else
          Result.Mensaje := SErrorRespuestaActualizacionNoValida;
      finally
        oJson.Free;
      end;
    end;
  end;
end;

function TServicioActualizaciones.DescargarArchivoEnFlujo(
  const AConsulta, ARutaDestino: string;
  ATamanoEsperado: Int64;
  out AError: string): Boolean;
var
  oDestino: TFileStream;
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sUrl: string;
begin
  Result := False;
  AError := '';
  sUrl := TClienteViraCashApi.ComponerUrl(
    FParametros,
    cRutaDescargaActualizacion);
  if Trim(AConsulta) <> '' then
    sUrl := sUrl + '?' + Trim(AConsulta);
  oHttp := THTTPClient.Create;
  try
    oHttp.ConnectionTimeout := cTiempoConexionActualizacion;
    oHttp.ResponseTimeout := cTiempoRespuestaActualizacion;
    oHttp.CustomHeaders['Authorization'] :=
      'Bearer ' + TClienteViraCashApi.Token(FParametros);
    try
      // El ejecutable ronda los 110 MiB: se escribe a disco según llega.
      oDestino := TFileStream.Create(ARutaDestino, fmCreate);
      try
        oRespuesta := oHttp.Get(sUrl, oDestino,
          [TNetHeader.Create('Accept', '*/*')]);
        if (oRespuesta.StatusCode < 200) or
           (oRespuesta.StatusCode >= 300) then
          AError := Format(
            SErrorServidorActualizacionHttp,
            [oRespuesta.StatusCode])
        else if (ATamanoEsperado > 0) and
                (oDestino.Size <> ATamanoEsperado) then
          AError := SErrorTamanoActualizacionNoCoincide
        else
          Result := True;
      finally
        oDestino.Free;
      end;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    oHttp.Free;
  end;
end;

function TServicioActualizaciones.ExtraerUnicaEntradaZip(
  const ARutaZip, ANombre, ARutaDestino: string;
  out AError: string): Boolean;
var
  aDatos: TBytes;
  iEntrada: Integer;
  oDestino: TFileStream;
  oZip: TZipFile;
begin
  Result := False;
  AError := '';
  oZip := TZipFile.Create;
  try
    try
      oZip.Open(ARutaZip, zmRead);
      iEntrada := oZip.IndexOf(ANombre);
      if iEntrada < 0 then
        AError := Format(SErrorEntradaZipActualizacionAusente, [ANombre])
      else if oZip.FileCount <> 1 then
        AError := SErrorZipActualizacionConVariasEntradas
      else
      begin
        oZip.Read(iEntrada, aDatos);
        oDestino := TFileStream.Create(ARutaDestino, fmCreate);
        try
          if Length(aDatos) > 0 then
            oDestino.WriteBuffer(aDatos[0], Length(aDatos));
        finally
          oDestino.Free;
        end;
        Result := True;
      end;
      oZip.Close;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    oZip.Free;
  end;
end;

function TServicioActualizaciones.DescargarEntrada(
  const AVersion, ATipo: string;
  const AEntrada: TEntradaActualizacion;
  const ARutaDestino: string;
  out AError: string): Boolean;
var
  sHuella: string;
  sRutaTemporal: string;
begin
  Result := False;
  AError := '';
  if not AEntrada.Declarada then
    AError := SErrorEntradaActualizacionNoDeclarada
  else
  begin
    Notificar(Format(SInfoDescargandoActualizacion, [AEntrada.Nombre]), -1);
    sRutaTemporal := RutaTemporalActualizacion('.tmp');
    try
      if DescargarArchivoEnFlujo(
           TClienteViraCashApi.ComponerConsulta(
             ['version', 'tipo', 'arquitectura', 'nombre'],
             [AVersion, ATipo, ArquitecturaActualizacionActual,
              AEntrada.Nombre]),
           sRutaTemporal,
           AEntrada.TamanoDescarga,
           AError) then
      begin
        sHuella := LowerCase(
          THashSHA2.GetHashStringFromFile(sRutaTemporal));
        if not SameText(sHuella, AEntrada.Sha256Descarga) then
          AError := SErrorHuellaActualizacionNoCoincide
        else if AEntrada.VieneComprimida then
        begin
          Notificar(
            Format(SInfoDescomprimiendoActualizacion, [AEntrada.Nombre]),
            -1);
          Result := ExtraerUnicaEntradaZip(
            sRutaTemporal,
            AEntrada.Nombre,
            ARutaDestino,
            AError);
        end
        else
        begin
          if TFile.Exists(ARutaDestino) then
            TFile.Delete(ARutaDestino);
          TFile.Move(sRutaTemporal, ARutaDestino);
          sRutaTemporal := '';
          Result := True;
        end;
      end;
    except
      on E: Exception do
      begin
        Result := False;
        AError := E.Message;
      end;
    end;
    if (sRutaTemporal <> '') and TFile.Exists(sRutaTemporal) then
      TFile.Delete(sRutaTemporal);
    if Result then
    begin
      sHuella := LowerCase(THashSHA2.GetHashStringFromFile(ARutaDestino));
      if not SameText(sHuella, AEntrada.Sha256) then
      begin
        Result := False;
        AError := SErrorHuellaActualizacionNoCoincide;
        TFile.Delete(ARutaDestino);
      end;
    end;
  end;
end;

function CrearServicioActualizaciones(
  const AParametros: IParametrosAplicacion;
  const AProgreso: TProgresoActualizacion): IServicioActualizaciones;
begin
  Result := TServicioActualizaciones.Create(AParametros, AProgreso);
end;

end.
