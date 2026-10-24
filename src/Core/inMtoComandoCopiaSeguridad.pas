{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComandoCopiaSeguridad                                   }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ejecuta la copia de seguridad solicitada por línea de comandos.           }
{******************************************************************************}
unit inMtoComandoCopiaSeguridad;

interface

uses
  inLibConexionesIntf,
  inLibLogIntf;

function EsProcesoComandoCopiaSeguridad: Boolean;
function EjecutarProcesoComandoCopiaSeguridad(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): Cardinal;

implementation

uses
  System.Classes,
  System.Hash,
  System.IOUtils,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows,
  Uni,
  inLibCifradoCopias,
  inLibComandoCopiaSeguridad,
  inLibCopiasSeguridad,
  inLibCopiasSeguridadIntf,
  inLibLineaComandos,
  inLibMsgConexion,
  inLibMsgConfiguracion,
  inLibSalidaComandos;

const
  SALIDA_COMANDO_ERROR_INESPERADO = 1;
  SALIDA_COMANDO_SINTAXIS = 2;
  SALIDA_COMANDO_RUTA = 3;
  SALIDA_COMANDO_CLAVE = 4;
  SALIDA_COMANDO_CONEXION = 5;
  SALIDA_COMANDO_COPIA = 6;
  SALIDA_COMANDO_PUBLICACION = 7;

type
  TResultadoComandoCopiaSeguridad = record
    CodigoSalida: Cardinal;
    EsError: Boolean;
    Mensaje: string;
  end;

procedure InformarFalloSecundarioEnDepurador(
  const AContexto: PChar;
  E: Exception);
begin
  try
    OutputDebugString(PChar(
      string(AContexto) + ': ' + E.ClassName + ': ' + E.Message));
  except
    OutputDebugString(AContexto);
  end;
end;

function CrearResultadoComandoCopiaSeguridad(
  ACodigoSalida: Cardinal;
  const AMensaje: string
): TResultadoComandoCopiaSeguridad;
begin
  Result := Default(TResultadoComandoCopiaSeguridad);
  Result.CodigoSalida := ACodigoSalida;
  Result.EsError := ACodigoSalida <> 0;
  Result.Mensaje := AMensaje;
end;

function MensajeErrorSolicitudCopia(
  AError: TErrorComandoCopiaSeguridad): string;
begin
  case AError of
    eccsSintaxis:
      Result := SErrorSintaxisComandoCopiaSeguridad;
    eccsRuta:
      Result := SErrorRutaComandoCopiaSeguridad;
    eccsExtension:
      Result := SErrorExtensionComandoCopiaSeguridad;
    eccsClave:
      Result := SErrorClaveComandoCopiaSeguridad;
  else
    Result := SErrorCrearCopiaSeguridad;
  end;
end;

function CodigoErrorSolicitudCopia(
  AError: TErrorComandoCopiaSeguridad): Cardinal;
begin
  case AError of
    eccsSintaxis:
      Result := SALIDA_COMANDO_SINTAXIS;
    eccsRuta,
    eccsExtension:
      Result := SALIDA_COMANDO_RUTA;
    eccsClave:
      Result := SALIDA_COMANDO_CLAVE;
  else
    Result := SALIDA_COMANDO_ERROR_INESPERADO;
  end;
end;

function CrearResultadoErrorSolicitud(
  AError: TErrorComandoCopiaSeguridad
): TResultadoComandoCopiaSeguridad;
begin
  Result := CrearResultadoComandoCopiaSeguridad(
    CodigoErrorSolicitudCopia(AError),
    MensajeErrorSolicitudCopia(AError));
end;

function InterpretarSolicitudPrevia(
  const AParametros: TArray<string>;
  AInstante: TDateTime
): TSolicitudComandoCopiaSeguridad;
var
  ClavesValidacion: TClavesPredeterminadasCopiaSeguridad;
begin
  ClavesValidacion := Default(
    TClavesPredeterminadasCopiaSeguridad);
  ClavesValidacion.Contrasena := 'validacion';
  ClavesValidacion.ClaveCifrada := THashSHA2.GetHashString(
    ClavesValidacion.Contrasena);
  Result := InterpretarComandoCopiaSeguridad(
    AParametros,
    AInstante,
    ClavesValidacion);
end;

procedure PrepararDirectorioCopia(const ARutaFichero: string);
var
  sDirectorio: string;
begin
  sDirectorio := ExcludeTrailingPathDelimiter(
    ExtractFilePath(ARutaFichero));
  if not DirectoryExists(sDirectorio) and
     not ForceDirectories(sDirectorio) then
  begin
    raise EInOutError.Create(sDirectorio);
  end;
end;

function CrearRutaTemporalCopia(const ARutaFichero: string): string;
begin
  Result := TPath.Combine(
    ExtractFilePath(ARutaFichero),
    'viracash_' + TPath.GetRandomFileName);
end;

function EsCopiaTemporalValida(const ARutaFichero: string): Boolean;
var
  iLinea: Integer;
  oLector: TStreamReader;
  sCabecera: string;
  sLinea: string;
begin
  Result := FileExists(ARutaFichero);
  if Result then
  begin
    oLector := TStreamReader.Create(
      ARutaFichero,
      TEncoding.UTF8,
      True);
    try
      sCabecera := oLector.ReadLine;
      Result := EsFormatoCifradoActual(sCabecera);
      iLinea := 1;
      while Result and (iLinea <= 4) do
      begin
        Result := not oLector.EndOfStream;
        if Result then
        begin
          sLinea := Trim(oLector.ReadLine);
          Result := sLinea <> '';
        end;
        Inc(iLinea);
      end;
      if Result then
        Result := not oLector.EndOfStream;
    finally
      FreeAndNil(oLector);
    end;
  end;
end;

function IntentarPublicarCopia(
  const ARutaTemporal, ARutaDestino: string;
  out AError: string): Boolean;
begin
  AError := '';
  Result := MoveFileEx(
    PChar(ARutaTemporal),
    PChar(ARutaDestino),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH);
  if not Result then
    AError := SysErrorMessage(GetLastError);
end;

function ObtenerValorOcultoSolicitud(
  const ASolicitud: TSolicitudComandoCopiaSeguridad): string;
var
  iMarcador: Integer;
  sPrefijo: string;
  sSufijo: string;
begin
  Result := '';
  iMarcador := Pos('***', ASolicitud.RutaRegistro);
  if (iMarcador > 0) and
     (PosEx('***', ASolicitud.RutaRegistro, iMarcador + 3) = 0) then
  begin
    sPrefijo := Copy(
      ASolicitud.RutaRegistro,
      1,
      iMarcador - 1);
    sSufijo := Copy(
      ASolicitud.RutaRegistro,
      iMarcador + 3,
      MaxInt);
    if StartsText(sPrefijo, ASolicitud.RutaDestino) and
       EndsText(sSufijo, ASolicitud.RutaDestino) then
    begin
      Result := Copy(
        ASolicitud.RutaDestino,
        Length(sPrefijo) + 1,
        Length(ASolicitud.RutaDestino) -
          Length(sPrefijo) - Length(sSufijo));
    end;
  end;
end;

function OcultarDetalleSolicitud(
  const ADetalle: string;
  const ASolicitud: TSolicitudComandoCopiaSeguridad): string;
var
  sDirectorioDestino: string;
  sDirectorioRegistro: string;
  sValorOculto: string;
begin
  Result := ReplaceText(
    ADetalle,
    ASolicitud.RutaDestino,
    ASolicitud.RutaRegistro);
  sDirectorioDestino := ExcludeTrailingPathDelimiter(
    ExtractFilePath(ASolicitud.RutaDestino));
  sDirectorioRegistro := ExcludeTrailingPathDelimiter(
    ExtractFilePath(ASolicitud.RutaRegistro));
  if sDirectorioDestino <> sDirectorioRegistro then
  begin
    Result := ReplaceText(
      Result,
      sDirectorioDestino,
      sDirectorioRegistro);
  end;
  sValorOculto := ObtenerValorOcultoSolicitud(ASolicitud);
  if sValorOculto <> '' then
    Result := ReplaceText(Result, sValorOculto, '***');
  if ASolicitud.Contrasena <> '' then
    Result := ReplaceText(Result, ASolicitud.Contrasena, '***');
end;

function CrearErrorPublicacion(
  const ADetalle: string;
  const ASolicitud: TSolicitudComandoCopiaSeguridad
): TResultadoComandoCopiaSeguridad;
begin
  Result := CrearResultadoComandoCopiaSeguridad(
    SALIDA_COMANDO_PUBLICACION,
    Format(
      SErrorPublicarComandoCopiaSeguridad,
      [OcultarDetalleSolicitud(ADetalle, ASolicitud)]));
end;

function PublicarCopiaTemporal(
  const ARutaTemporal: string;
  const ASolicitud: TSolicitudComandoCopiaSeguridad;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  sError: string;
begin
  if not EsCopiaTemporalValida(ARutaTemporal) then
  begin
    Result := CrearResultadoComandoCopiaSeguridad(
      SALIDA_COMANDO_COPIA,
      Format(
        SErrorCrearCopiaSeguridad,
        [SErrorFormatoComandoCopiaSeguridad]));
  end
  else
  begin
    ARegistroLog.RegistrarInformacion(
      SInfoComandoCopiaSeguridadPublicacion);
    if IntentarPublicarCopia(
      ARutaTemporal,
      ASolicitud.RutaDestino,
      sError) then
    begin
      Result := CrearResultadoComandoCopiaSeguridad(
        0,
        Format(
          SInfoComandoCopiaSeguridadCompletado,
          [ASolicitud.RutaRegistro]));
    end
    else
      Result := CrearErrorPublicacion(sError, ASolicitud);
  end;
end;

function CrearCopiaTemporal(
  AConexion: TUniConnection;
  const ARutaTemporal: string;
  const ASolicitud: TSolicitudComandoCopiaSeguridad;
  out AError: string): TResultadoCopiaSeguridad;
begin
  try
    Result := CrearCopiaProtegidaConexion(
      AConexion,
      ARutaTemporal,
      ASolicitud.Contrasena,
      nil,
      AError);
  except
    on E: Exception do
    begin
      AError := E.Message;
      Result := rcsFallida;
    end;
  end;
end;

function EjecutarSolicitudCopiaSeguridad(
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudComandoCopiaSeguridad;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  oResultadoCopia: TResultadoCopiaSeguridad;
  sError: string;
  sRutaTemporal: string;
begin
  sRutaTemporal := '';
  try
    try
      ARegistroLog.RegistrarInformacion(
        Format(
          SInfoComandoCopiaSeguridadDestino,
          [ASolicitud.RutaRegistro]));
      PrepararDirectorioCopia(ASolicitud.RutaDestino);
      sRutaTemporal := CrearRutaTemporalCopia(
        ASolicitud.RutaDestino);
      ARegistroLog.RegistrarInformacion(
        SInfoComandoCopiaSeguridadGeneracion);
      oResultadoCopia := CrearCopiaTemporal(
        AConexion,
        sRutaTemporal,
        ASolicitud,
        sError);
      if oResultadoCopia = rcsCompletada then
      begin
        Result := PublicarCopiaTemporal(
          sRutaTemporal,
          ASolicitud,
          ARegistroLog);
      end
      else
      begin
        Result := CrearResultadoComandoCopiaSeguridad(
          SALIDA_COMANDO_COPIA,
          Format(
            SErrorCrearCopiaSeguridad,
            [OcultarDetalleSolicitud(sError, ASolicitud)]));
      end;
    except
      on E: Exception do
        Result := CrearErrorPublicacion(
          E.Message,
          ASolicitud);
    end;
  finally
    if (sRutaTemporal <> '') and
       FileExists(sRutaTemporal) then
    begin
      System.SysUtils.DeleteFile(sRutaTemporal);
    end;
  end;
end;

function EjecutarConConexion(
  AConexion: TUniConnection;
  const AParametros: TArray<string>;
  AInstante: TDateTime;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  oClaves: TClavesPredeterminadasCopiaSeguridad;
  oSolicitud: TSolicitudComandoCopiaSeguridad;
begin
  oClaves := Default(TClavesPredeterminadasCopiaSeguridad);
  oClaves.Contrasena := AConexion.Password;
  oClaves.ClaveCifrada := THashSHA2.GetHashString(
    oClaves.Contrasena);
  oSolicitud := InterpretarComandoCopiaSeguridad(
    AParametros,
    AInstante,
    oClaves);
  if oSolicitud.EsValida then
  begin
    Result := EjecutarSolicitudCopiaSeguridad(
      AConexion,
      oSolicitud,
      ARegistroLog);
  end
  else
  begin
    Result := CrearResultadoErrorSolicitud(
      oSolicitud.Error);
  end;
end;

function IntentarPrepararConexion(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  out AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog;
  out AError: string): Boolean;
begin
  AConexion := nil;
  AError := '';
  try
    ARegistroLog.RegistrarInformacion(
      SInfoComandoCopiaSeguridadConexion);
    AConexion := AFabricaConexiones.CrearConexion(nil);
    AFabricaConexiones.Conectar(AConexion);
    ARegistroLog.RegistrarInformacion(
      Format(
        SInfoComandoCopiaSeguridadConexionPreparada,
        [AConexion.Server, AConexion.Database]));
    Result := True;
  except
    on E: Exception do
    begin
      AError := E.Message;
      FreeAndNil(AConexion);
      Result := False;
    end;
  end;
end;

function EjecutarComandoValidado(
  const AParametros: TArray<string>;
  AInstante: TDateTime;
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  oConexion: TUniConnection;
  sError: string;
begin
  oConexion := nil;
  try
    if IntentarPrepararConexion(
      AFabricaConexiones,
      oConexion,
      ARegistroLog,
      sError) then
    begin
      try
        Result := EjecutarConConexion(
          oConexion,
          AParametros,
          AInstante,
          ARegistroLog);
      except
        on E: Exception do
        begin
          Result := CrearResultadoComandoCopiaSeguridad(
            SALIDA_COMANDO_ERROR_INESPERADO,
            Format(
              SErrorInesperadoComandoCopiaSeguridad,
              [E.Message]));
        end;
      end;
    end
    else
    begin
      Result := CrearResultadoComandoCopiaSeguridad(
        SALIDA_COMANDO_CONEXION,
        Format(
          SErrorConexionComandoCopiaSeguridad,
          [sError]));
    end;
  finally
    FreeAndNil(oConexion);
  end;
end;

function EjecutarComandoCopiaSeguridad(
  const AParametros: TArray<string>;
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): TResultadoComandoCopiaSeguridad;
var
  dtInstante: TDateTime;
  SolicitudPrevia: TSolicitudComandoCopiaSeguridad;
begin
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  dtInstante := Now;
  ARegistroLog.RegistrarInformacion(
    SInfoComandoCopiaSeguridadInicio);
  if not EsSintaxisComandoCopiaSeguridadValida(AParametros) then
  begin
    Result := CrearResultadoComandoCopiaSeguridad(
      SALIDA_COMANDO_SINTAXIS,
      SErrorSintaxisComandoCopiaSeguridad);
  end
  else
  begin
    SolicitudPrevia := InterpretarSolicitudPrevia(
      AParametros,
      dtInstante);
    if SolicitudPrevia.EsValida then
    begin
      ARegistroLog.RegistrarInformacion(
        SInfoComandoCopiaSeguridadParametrosValidados);
      Result := EjecutarComandoValidado(
        AParametros,
        dtInstante,
        AFabricaConexiones,
        ARegistroLog);
    end
    else
      Result := CrearResultadoErrorSolicitud(
        SolicitudPrevia.Error);
  end;
end;

procedure RegistrarResultadoComando(
  const AResultado: TResultadoComandoCopiaSeguridad;
  const ARegistroLog: IRegistroLog);
begin
  try
    EscribirMensajeComando(
      AResultado.Mensaje,
      AResultado.EsError);
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inMtoComandoCopiaSeguridad.RegistrarResultadoComando.Salida', E);
  end;
  try
    if AResultado.EsError then
      ARegistroLog.RegistrarError(AResultado.Mensaje)
    else
      ARegistroLog.RegistrarInformacion(AResultado.Mensaje);
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inMtoComandoCopiaSeguridad.RegistrarResultadoComando.Log', E);
  end;
end;

function EsProcesoComandoCopiaSeguridad: Boolean;
begin
  Result := EsComandoCopiaSeguridad(
    ObtenerParametrosLineaComandos);
end;

function EjecutarProcesoComandoCopiaSeguridad(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const ARegistroLog: IRegistroLog
): Cardinal;
var
  oResultado: TResultadoComandoCopiaSeguridad;
begin
  try
    oResultado := EjecutarComandoCopiaSeguridad(
      ObtenerParametrosLineaComandos,
      AFabricaConexiones,
      ARegistroLog);
  except
    on E: Exception do
    begin
      oResultado := CrearResultadoComandoCopiaSeguridad(
        SALIDA_COMANDO_ERROR_INESPERADO,
        Format(
          SErrorInesperadoComandoCopiaSeguridad,
          [E.Message]));
    end;
  end;
  RegistrarResultadoComando(
    oResultado,
    ARegistroLog);
  Result := oResultado.CodigoSalida;
end;

end.
