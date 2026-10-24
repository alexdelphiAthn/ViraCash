{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoTickets                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       13/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Genera los PDF asociados a una operación y los envía mediante el          }
{    servicio web de correo configurado para la instalación.                   }
{******************************************************************************}
unit inLibCorreoTickets;

interface

uses
  System.SysUtils, System.Classes, Uni, inLibParametrosIntf,
  inLibTraspasoTicketIntf, inLibTicketsCajaIntf,
  inLibUnidadesMedida, inLibPreviewTicket, inLibLogIntf;

type
  // Cada valor tiene su texto en el contrato del servicio web
  // (tipo_documento de correo/enviar_ticket.php).
  TTipoDocumentoCorreo = (
    tdcTicket,
    tdcFactura,
    tdcPresupuesto,
    tdcPedido,
    tdcAlbaran,
    tdcPedidoCompra,
    tdcAlbaranCompra,
    tdcDevolucionCompra,
    tdcFacturaCompra
  );

  TDatosCorreoOperacion = record
    Encontrada: Boolean;
    EmailCliente: string;
    CodigoCliente: string;
    NombreEmpresa: string;
    TieneFactura: Boolean;
    TieneDepositos: Boolean;
    EsOperacionCaja: Boolean;
    EsTraspaso: Boolean;
  end;

function CorreoTicketsConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
// Texto del tipo en el contrato del servicio web (ASCII, en minúsculas).
function TipoDocumentoTexto(
  ATipoDocumento: TTipoDocumentoCorreo): string;
function EnviarDocumentosPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  ATipoDocumento: TTipoDocumentoCorreo;
  const AReferenciaDocumento, ANombreEmpresa, AEmail: string;
  const ARutasPDF: TStrings;
  const ARegistroLog: IRegistroLog;
  out AMensaje: string): Boolean; overload;
function EnviarDocumentosPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  ATipoDocumento: TTipoDocumentoCorreo;
  const AReferenciaDocumento, ANombreEmpresa, AEmail,
    AEmailRespuesta: string;
  const ARutasPDF: TStrings;
  const ARegistroLog: IRegistroLog;
  out AMensaje: string): Boolean; overload;
// ANombreDocumento (de fza_tipos_documentos) sustituye en el asunto y el
// cuerpo del correo al nombre fijo del tipo; vacío conserva el fijo.
function EnviarDocumentosPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  ATipoDocumento: TTipoDocumentoCorreo;
  const AReferenciaDocumento, ANombreDocumento, ANombreEmpresa, AEmail,
    AEmailRespuesta: string;
  const ARutasPDF: TStrings;
  const ARegistroLog: IRegistroLog;
  out AMensaje: string): Boolean; overload;
// Borra un PDF temporal de correo. False si sigue en disco; el motivo queda
// como aviso en el log.
function EliminarDocumentoTemporalSeguro(
  const ARuta: string;
  const ARegistroLog: IRegistroLog): Boolean;
function EnviarDocumentacionOperacion(
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  const ARepositorioTicketsCaja: TRepositoriosTicketsCaja;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  const ADatos: TDatosCorreoOperacion;
  const AEmpresa, AAlmacen, ACaja, ANumeroOperacion, AEmail: string;
  out AMensaje: string;
  AImprimirLotes: Boolean = True): Boolean;

implementation

uses
  System.JSON, System.Net.HttpClient, System.Net.Mime,
  Winapi.Windows,
  inLibGenerarTicketBD, inLibGenerarTicketCaja,
  inLibTraspasoTicket, inLibViraCashApi, inLibCorreoValidacion,
  inLibMsgComun;

resourcestring
  SErrorSinDocumentosPdfCorreo = 'No hay documentos PDF para enviar.';
  SErrorRutaDocumentoCorreoVacia =
    'La ruta del documento %d está vacía.';
  SErrorDocumentoCorreoNoPdf = 'El documento no es un PDF: %s';
  SErrorDocumentoPdfCorreoNoEncontrado =
    'No se encuentra el documento PDF: %s';
  SErrorServidorCorreoEstado = 'El servidor respondió con código %d.';
  SCorreoDocumentosEnviado =
    'Correo enviado a %s con %d documento(s).';
  SErrorEmailCorreoNoIndicado =
    'Indique una dirección de correo electrónico.';
  SErrorEmailCorreoInvalido =
    'La dirección de correo electrónico no es válida.';
  SErrorEnvioDocumentacionCorreo =
    'No se pudo enviar la documentación: %s';
  SErrorOperacionCorreoNoEncontrada =
    'No se ha encontrado la operación seleccionada.';
  SErrorOperacionCorreoSinDocumentacion =
    'La operación no tiene documentación asociada.';

const
  cRutaCorreo = 'correo/enviar_ticket.php';

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

function CorreoTicketsConfigurado(
  const AParametrosApp: IParametrosAplicacion;
  out AMensaje: string): Boolean;
var
  Faltan: TStringList;
begin
  AMensaje := '';
  Faltan := TStringList.Create;
  try
    if not Assigned(AParametrosApp) then
      Faltan.Add(SParametroAplicacionCorreoFaltante)
    else
    begin
      if TClienteViraCashApi.UrlBase(AParametrosApp) = '' then
        Faltan.Add(SUrlServicioWebCorreoFaltante);
      if TClienteViraCashApi.Token(AParametrosApp) = '' then
        Faltan.Add(SApiKeyInstalacionCorreoFaltante);
      if TClienteViraCashApi.Referencia(AParametrosApp) = '' then
        Faltan.Add(SReferenciaInstalacionCorreoFaltante);
    end;
    Result := Faltan.Count = 0;
    if not Result then
      AMensaje := Format(SErrorParametrosCorreoNoConfigurados,
        [Faltan.Text]);
  finally
    FreeAndNil(Faltan);
  end;
end;

function TipoDocumentoTexto(
  ATipoDocumento: TTipoDocumentoCorreo): string;
begin
  case ATipoDocumento of
    tdcFactura:
      Result := 'factura';
    tdcPresupuesto:
      Result := 'presupuesto';
    tdcPedido:
      Result := 'pedido';
    tdcAlbaran:
      Result := 'albaran';
    tdcPedidoCompra:
      Result := 'pedido_compra';
    tdcAlbaranCompra:
      Result := 'albaran_compra';
    tdcDevolucionCompra:
      Result := 'devolucion_compra';
    tdcFacturaCompra:
      Result := 'factura_compra';
  else
    Result := 'ticket';
  end;
end;

procedure RegistrarErrorCorreo(const ARegistroLog: IRegistroLog;
  const AReferenciaDocumento, AMensaje: string);
begin
  if Assigned(ARegistroLog) then
  begin
    try
      ARegistroLog.RegistrarError(
        'Correo de documento ' + AReferenciaDocumento + ': ' + AMensaje);
    except
      on E: Exception do
        InformarFalloSecundarioEnDepurador(
          'inLibCorreoTickets.RegistrarErrorCorreo', E);
    end;
  end;
end;

function EliminarDocumentoTemporalSeguro(
  const ARuta: string;
  const ARegistroLog: IRegistroLog): Boolean;
var
  iError: Cardinal;
  sDetalle: string;
  sRuta: string;
begin
  Result := True;
  sRuta := Trim(ARuta);
  if (sRuta <> '') and FileExists(sRuta) then
  begin
    sDetalle := '';
    try
      SetLastError(ERROR_SUCCESS);
      Result := System.SysUtils.DeleteFile(sRuta);
      if not Result then
      begin
        iError := GetLastError;
        // Si otro proceso terminó de borrarlo entre FileExists y DeleteFile,
        // la limpieza también se considera completada.
        Result := not FileExists(sRuta);
        if not Result and (iError <> ERROR_SUCCESS) then
          sDetalle := SysErrorMessage(iError);
      end;
    except
      on E: Exception do
      begin
        Result := False;
        sDetalle := E.ClassName + ': ' + E.Message;
      end;
    end;
    if not Result and Assigned(ARegistroLog) then
    begin
      try
        if Trim(sDetalle) <> '' then
          sDetalle := ': ' + sDetalle
        else
          sDetalle := '.';
        ARegistroLog.RegistrarAviso(
          'No se pudo eliminar el PDF temporal de correo "' + sRuta + '"' +
          sDetalle);
      except
        on E: Exception do
          InformarFalloSecundarioEnDepurador(
            'inLibCorreoTickets.EliminarDocumentoTemporalSeguro.Log', E);
      end;
    end;
  end;
end;

function RutasPdfValidas(const ARutasPDF: TStrings;
  out AMensaje: string): Boolean;
var
  i: Integer;
  sRuta: string;
begin
  Result := False;
  AMensaje := '';
  if not Assigned(ARutasPDF) then
    AMensaje := SErrorSinDocumentosPdfCorreo
  else if ARutasPDF.Count = 0 then
    AMensaje := SErrorSinDocumentosPdfCorreo
  else
  begin
    Result := True;
    for i := 0 to ARutasPDF.Count - 1 do
    begin
      sRuta := Trim(ARutasPDF[i]);
      if sRuta = '' then
      begin
        AMensaje := Format(SErrorRutaDocumentoCorreoVacia,
          [i + 1]);
        Result := False;
        Break;
      end;
      if not SameText(ExtractFileExt(sRuta), '.pdf') then
      begin
        AMensaje := Format(SErrorDocumentoCorreoNoPdf, [sRuta]);
        Result := False;
        Break;
      end;
      if not FileExists(sRuta) then
      begin
        AMensaje := Format(SErrorDocumentoPdfCorreoNoEncontrado,
          [sRuta]);
        Result := False;
        Break;
      end;
    end;
  end;
end;

function MensajeRespuestaServidor(const ATexto: string;
  AEstado: Integer): string;
var
  Json: TJSONValue;
  Valor: TJSONValue;
begin
  Result := '';
  Json := TJSONObject.ParseJSONValue(ATexto);
  try
    if Assigned(Json) then
    begin
      Valor := Json.FindValue('error.mensaje');
      if Assigned(Valor) then
        Result := Valor.Value;
      if Result = '' then
      begin
        Valor := Json.FindValue('message');
        if Assigned(Valor) then
          Result := Valor.Value;
      end;
    end;
  finally
    FreeAndNil(Json);
  end;
  if Result = '' then
    Result := Format(SErrorServidorCorreoEstado, [AEstado]);
end;

procedure GenerarDocumentos(
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  const ARepositorioTicketsCaja: TRepositoriosTicketsCaja;
  AConexion: TUniConnection;
  const AEmpresa, AAlmacen, ACaja,
  ANumeroOperacion: string; const ADatos: TDatosCorreoOperacion;
  ARutasPDF: TStrings; AImprimirLotes: Boolean);
begin
  if ADatos.EsTraspaso then
    TTraspasoTicket.ImprimirTraspasoDesdeBD(
      APreviewTicket,
      ARepositorioTraspaso,
      AEmpresa,
      AAlmacen,
      ACaja,
      ANumeroOperacion,
      'DEBUG',
      ARutasPDF,
      True)
  else
  begin
    if ADatos.TieneFactura then
      ImprimirTicketDesdeBD(
        AParametrosApp,
        APreviewTicket,
        AUnidades,
        ARepositorioTicketsCaja.Tickets,
        AEmpresa,
        AAlmacen,
        ACaja,
        ANumeroOperacion,
        'DEBUG',
        ARutasPDF,
        True, False, AImprimirLotes);
    if ADatos.TieneDepositos then
      ImprimirResguardoDeposito(
        APreviewTicket,
        ARepositorioTicketsCaja.Resguardos,
        AEmpresa,
        AAlmacen,
        ACaja,
        ANumeroOperacion,
        'DEBUG',
        ARutasPDF,
        True);
    if ADatos.EsOperacionCaja then
      ImprimirTicketOperacionCaja(
        APreviewTicket, AConexion, ARepositorioTicketsCaja.Impresion,
        AEmpresa, AAlmacen, ACaja,
        ANumeroOperacion, 'DEBUG', ARutasPDF, True);
    if (ARutasPDF.Count > 0) and (Trim(ADatos.CodigoCliente) <> '') then
      ImprimirRecordatorio(
        APreviewTicket,
        ARepositorioTicketsCaja.Recordatorios,
        AEmpresa,
        ADatos.CodigoCliente,
        'DEBUG',
        ARutasPDF,
        True);
  end;
end;

function EnviarAlServicio(const AUrl, AApiKey, AReferencia, AOperacion,
  ANombreDocumento, AEmpresa, AEmail, AEmailRespuesta: string;
  ATipoDocumento: TTipoDocumentoCorreo;
  const ARutasPDF: TStrings;
  out AMensaje: string): Boolean;
var
  Http: THTTPClient;
  Formulario: TMultipartFormData;
  Respuesta: TStringStream;
  ResultadoHttp: IHTTPResponse;
  i: Integer;
begin
  Http := THTTPClient.Create;
  Formulario := TMultipartFormData.Create;
  Respuesta := TStringStream.Create('', TEncoding.UTF8);
  try
    Http.ConnectionTimeout := 15000;
    Http.ResponseTimeout := 60000;
    Http.CustomHeaders['X-API-Key'] := AApiKey;
    Formulario.AddField('referencia', AReferencia);
    Formulario.AddField('destinatario', AEmail);
    Formulario.AddField('operacion', AOperacion);
    Formulario.AddField('nombre_empresa', AEmpresa);
    Formulario.AddField('tipo_documento',
      TipoDocumentoTexto(ATipoDocumento));
    if AEmailRespuesta <> '' then
      Formulario.AddField('email_respuesta', AEmailRespuesta);
    if ANombreDocumento <> '' then
      Formulario.AddField('nombre_documento', ANombreDocumento);
    for i := 0 to ARutasPDF.Count - 1 do
      Formulario.AddFile('documentos[]', Trim(ARutasPDF[i]),
        'application/pdf');
    ResultadoHttp := Http.Post(AUrl, Formulario, Respuesta);
    Result := ResultadoHttp.StatusCode = 200;
    if Result then
      AMensaje := Format(SCorreoDocumentosEnviado,
        [AEmail, ARutasPDF.Count])
    else
      AMensaje := MensajeRespuestaServidor(Respuesta.DataString,
        ResultadoHttp.StatusCode);
  finally
    FreeAndNil(Respuesta);
    FreeAndNil(Formulario);
    FreeAndNil(Http);
  end;
end;

function EnviarDocumentosPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  ATipoDocumento: TTipoDocumentoCorreo;
  const AReferenciaDocumento, ANombreEmpresa, AEmail: string;
  const ARutasPDF: TStrings;
  const ARegistroLog: IRegistroLog;
  out AMensaje: string): Boolean;
begin
  Result := EnviarDocumentosPorCorreo(
    AParametrosApp,
    ATipoDocumento,
    AReferenciaDocumento,
    ANombreEmpresa,
    AEmail,
    '',
    ARutasPDF,
    ARegistroLog,
    AMensaje);
end;

function EnviarDocumentosPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  ATipoDocumento: TTipoDocumentoCorreo;
  const AReferenciaDocumento, ANombreEmpresa, AEmail,
    AEmailRespuesta: string;
  const ARutasPDF: TStrings;
  const ARegistroLog: IRegistroLog;
  out AMensaje: string): Boolean;
begin
  Result := EnviarDocumentosPorCorreo(
    AParametrosApp,
    ATipoDocumento,
    AReferenciaDocumento,
    '',
    ANombreEmpresa,
    AEmail,
    AEmailRespuesta,
    ARutasPDF,
    ARegistroLog,
    AMensaje);
end;

function EnviarDocumentosPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  ATipoDocumento: TTipoDocumentoCorreo;
  const AReferenciaDocumento, ANombreDocumento, ANombreEmpresa, AEmail,
    AEmailRespuesta: string;
  const ARutasPDF: TStrings;
  const ARegistroLog: IRegistroLog;
  out AMensaje: string): Boolean;
var
  sApiKey: string;
  sEmail: string;
  sEmailRespuesta: string;
  sReferenciaInstalacion: string;
  sUrl: string;
begin
  Result := False;
  AMensaje := '';
  try
    if CorreoTicketsConfigurado(AParametrosApp, AMensaje) then
    begin
      sEmail := Trim(AEmail);
      sEmailRespuesta :=
        NormalizarEmailRespuestaDocumento(AEmailRespuesta);
      if sEmail = '' then
        AMensaje := SErrorEmailCorreoNoIndicado
      else if not EmailDocumentoValido(sEmail) then
        AMensaje := SErrorEmailCorreoInvalido
      else if not RutasPdfValidas(ARutasPDF, AMensaje) then
      begin
        { RutasPdfValidas deja el detalle en AMensaje. }
      end
      else
      begin
        sUrl := TClienteViraCashApi.ComponerUrl(
          AParametrosApp, cRutaCorreo);
        sApiKey := TClienteViraCashApi.Token(AParametrosApp);
        sReferenciaInstalacion :=
          TClienteViraCashApi.Referencia(AParametrosApp);
        Result := EnviarAlServicio(
          sUrl,
          sApiKey,
          sReferenciaInstalacion,
          Trim(AReferenciaDocumento),
          Trim(ANombreDocumento),
          ANombreEmpresa,
          sEmail,
          sEmailRespuesta,
          ATipoDocumento,
          ARutasPDF,
          AMensaje);
      end;
    end;
  except
    on E: Exception do
      AMensaje := Format(SErrorEnvioDocumentacionCorreo, [E.Message]);
  end;

  if not Result then
    RegistrarErrorCorreo(ARegistroLog, AReferenciaDocumento, AMensaje);
end;

function EnviarDocumentacionOperacion(
  const AParametrosApp: IParametrosAplicacion;
  const APreviewTicket: IPreviewTicket;
  AUnidades: TUnidadesMedida;
  const ARepositorioTraspaso: IRepositorioTraspasoTicket;
  const ARepositorioTicketsCaja: TRepositoriosTicketsCaja;
  const ARegistroLog: IRegistroLog;
  AConexion: TUniConnection;
  const ADatos: TDatosCorreoOperacion;
  const AEmpresa, AAlmacen, ACaja, ANumeroOperacion, AEmail: string;
  out AMensaje: string;
  AImprimirLotes: Boolean): Boolean;
var
  RutasPDF: TStringList;
  i: Integer;
begin
  Result := False;
  AMensaje := '';
  if CorreoTicketsConfigurado(AParametrosApp, AMensaje) then
  begin
    if Trim(AEmail) = '' then
      AMensaje := SErrorEmailCorreoNoIndicado
    else
    begin
      if not ADatos.Encontrada then
        AMensaje := SErrorOperacionCorreoNoEncontrada
      else
      begin
        RutasPDF := TStringList.Create;
        try
          try
            GenerarDocumentos(
              AParametrosApp,
              APreviewTicket,
              AUnidades,
              ARepositorioTraspaso,
              ARepositorioTicketsCaja,
              AConexion,
              AEmpresa,
              AAlmacen,
              ACaja,
              ANumeroOperacion,
              ADatos,
              RutasPDF, AImprimirLotes);
            if RutasPDF.Count = 0 then
              AMensaje := SErrorOperacionCorreoSinDocumentacion
            else
              Result := EnviarDocumentosPorCorreo(
                AParametrosApp,
                tdcTicket,
                ANumeroOperacion,
                ADatos.NombreEmpresa,
                Trim(AEmail),
                RutasPDF,
                ARegistroLog,
                AMensaje);
          except
            on E: Exception do
            begin
              AMensaje := Format(SErrorEnvioDocumentacionCorreo,
                [E.Message]);
              RegistrarErrorCorreo(
                ARegistroLog, ANumeroOperacion, E.Message);
            end;
          end;
        finally
          for i := 0 to RutasPDF.Count - 1 do
            EliminarDocumentoTemporalSeguro(
              RutasPDF[i],
              ARegistroLog);
          FreeAndNil(RutasPDF);
        end;
      end;
    end;
  end;
end;

end.
