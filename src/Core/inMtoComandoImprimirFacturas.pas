{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComandoImprimirFacturas                                  }
{    Tipo:       Coordinador de aplicación                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Genera por línea de comandos los PDF de facturas autorizadas para la     }
{    sesión activa, usando el mismo informe y exportador que la aplicación.    }
{******************************************************************************}
unit inMtoComandoImprimirFacturas;

interface

uses
  System.Classes,
  inLibComandoImprimirFacturas,
  inLibConexionesIntf,
  inLibContextoSesionIntf,
  inLibLogIntf,
  inLibParametrosIntf,
  inLibPermisosIntf,
  Uni;

type
  TResultadoComandoImprimirFacturas = record
    CodigoSalida: Cardinal;
    EsError: Boolean;
    Mensaje: string;
    CorreoSolicitado: Boolean;
    CorreosEnviados: Integer;
    CorreosSinDestinatario: Integer;
    CorreosConError: Integer;
    DetalleCorreo: string;
  end;
  TResultadoLoteImpresionFacturas = record
    Solicitadas: Integer;
    Impresas: Integer;
    OmitidasNoConsolidadas: Integer;
    Error: string;
    CorreoSolicitado: Boolean;
    CorreosEnviados: Integer;
    CorreosSinDestinatario: Integer;
    CorreosConError: Integer;
    DetalleCorreo: string;
  end;
  TFinalizarLoteImpresionFacturas = reference to procedure(
    const AResultado: TResultadoLoteImpresionFacturas);

function EsProcesoComandoImprimirFacturas: Boolean;
function ValidarSintaxisProcesoComandoImprimirFacturas(
  const ARegistroLog: IRegistroLog
): Cardinal;
function EjecutarComandoImprimirFacturas(
  const AParametros: TArray<string>;
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  AEnviarEmail: Boolean = False
): TResultadoComandoImprimirFacturas;
procedure IniciarLoteImpresionFacturas(
  const AReferencias: TReferenciasComandoFactura;
  const AFormato, AImpresoraConfigurada: string;
  AOwnerSesion: TComponent;
  AConexionPrincipal: TUniConnection;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  AEnviarEmail: Boolean;
  const AAlFinalizar: TFinalizarLoteImpresionFacturas);
procedure DetenerLoteImpresionFacturasAlCerrar;
function EjecutarProcesoComandoImprimirFacturas(
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog
): Cardinal;
function FinalizarProcesoComandoImprimirFacturasSinSesion(
  const ARegistroLog: IRegistroLog
): Cardinal;
function FinalizarProcesoComandoImprimirFacturasConError(
  const ARegistroLog: IRegistroLog;
  const AMensaje: string
): Cardinal;

implementation

uses
  System.Generics.Collections,
  System.Hash,
  System.IOUtils,
  System.SyncObjs,
  System.SysUtils,
  Winapi.Windows,
  Vcl.Forms,
  Data.DB,
  frPrinter,
  inLibFiltroUsuario,
  inLibCorreoTickets,
  inLibLineaComandos,
  inLibMsgConfiguracion,
  inLibSalidaComandos,
  inLibVerifactu,
  inMtoModalImpFac,
  UniDataComandoImprimirFacturasConsulta,
  UniDataFacturas;

type
  TEstadoFacturaImpresionLote = (
    efilImpresa,
    efilOmitidaNoConsolidada,
    efilError
  );
  TDatosCorreoFacturaLote = record
    Email: string;
    EmailRespuesta: string;
    NombreEmpresa: string;
    RutaPdf: string;
    ErrorPreparacion: string;
  end;
  TContadoresExportacionFacturas = record
    Generadas: Integer;
    CorreosEnviados: Integer;
    CorreosSinDestinatario: Integer;
    CorreosConError: Integer;
    DetalleCorreo: string;
  end;
  TThreadAcceso = class(TThread);
  ITrabajoLoteImpresionFacturas = interface
    procedure Ejecutar(AHilo: TThread);
  end;
  TTrabajoLoteImpresionFacturas = class(
    TInterfacedObject,
    ITrabajoLoteImpresionFacturas)
  private
    FReferencias: TReferenciasComandoFactura;
    FFormato: string;
    FImpresora: string;
    FOwnerSesion: TComponent;
    FConexionPrincipal: TUniConnection;
    FConexiones: IServicioConexiones;
    FContextoSesion: IContextoSesionAplicacion;
    FParametrosApp: IParametrosAplicacion;
    FRegistroLog: IRegistroLog;
    FAutorizacion: TContextoAutorizacionComandoFactura;
    FUsuario: string;
    FEnviarEmail: Boolean;
    FAlFinalizar: TFinalizarLoteImpresionFacturas;
    FResultado: TResultadoLoteImpresionFacturas;
    function DebeDetener(AHilo: TThread): Boolean;
    function ProcesarFactura(
      AHilo: TThread;
      const AReferencia: TReferenciaComandoFactura): Boolean;
    procedure ProcesarFacturas(
      AHilo: TThread;
      const AReferencias: TReferenciasComandoFactura);
    procedure NotificarResultado;
  public
    constructor Create(
      const AReferencias: TReferenciasComandoFactura;
      const AFormato, AImpresora: string;
      AOwnerSesion: TComponent;
      AConexionPrincipal: TUniConnection;
      const AConexiones: IServicioConexiones;
      const AContextoSesion: IContextoSesionAplicacion;
      const AParametrosApp: IParametrosAplicacion;
      const ARegistroLog: IRegistroLog;
      const AAutorizacion: TContextoAutorizacionComandoFactura;
      const AUsuario: string;
      AEnviarEmail: Boolean;
      const AAlFinalizar: TFinalizarLoteImpresionFacturas;
      const AResultadoInicial: TResultadoLoteImpresionFacturas);
    procedure Ejecutar(AHilo: TThread);
  end;

const
  SALIDA_COMANDO_IMPRESION_ERROR = 1;
  SALIDA_COMANDO_IMPRESION_SINTAXIS = 2;
  SALIDA_COMANDO_IMPRESION_DIRECTORIO = 3;
  SALIDA_COMANDO_IMPRESION_AUTORIZACION = 4;
  SALIDA_COMANDO_IMPRESION_FACTURA = 5;
  SALIDA_COMANDO_IMPRESION_FORMATO = 6;
  SALIDA_COMANDO_IMPRESION_EXPORTACION = 7;
  SALIDA_COMANDO_IMPRESION_SESION = 8;

resourcestring
  SErrorNombreComandoImprimirFacturasBloqueado =
    'El nombre está bloqueado por otro proceso.';
  SEstadoCorreoFacturaSinEmail = 'SIN EMAIL';
  SEstadoCorreoFacturaError = 'ERROR';
  SEstadoCorreoFacturaEnviado = 'ENVIADO';
  SDetalleCorreoFacturaSinEmail = 'EMAIL_CLIENTE_FAC vacío';
  SErrorListaComandoImprimirFacturas =
    'Lista de facturas no válida: %s.';
  SErrorDirectorioComandoImprimirFacturas =
    'No se puede preparar el directorio de destino "%s".';
  SErrorFormatoComandoImprimirFacturas =
    'El formato de factura "%s" no existe o no está disponible para ' +
    'el usuario actual.';
  SErrorFacturaNoEncontradaComando =
    'La factura %s no existe.';
  SErrorFacturaFueraAmbitoComando =
    'La factura %s no pertenece al ámbito de empresa, almacén y caja ' +
    'permitido al usuario %s.';
  SErrorPermisoFacturaComando =
    'El usuario %s no tiene permiso para imprimir la factura %s.';
  SErrorTipoFacturaComando =
    'La factura %s tiene un tipo no admitido: %s.';
  SErrorFacturaNoAutorizadaComando =
    'La factura %s no está disponible o el usuario %s no está autorizado ' +
    'para imprimirla.';
  SErrorFacturaNoConsolidadaComando =
    'La factura %s no está consolidada y VeriFactu ONLINE está activo.';
  SErrorPrepararFacturaComando =
    'No se pudieron obtener los datos de impresión de la factura %s.';
  SErrorExportarFacturaComando =
    'No se pudo generar el PDF de la factura %s en "%s".';
  SErrorPublicarFacturaComando =
    'No se pudo publicar el PDF de la factura %s en "%s": %s.';
  SErrorColisionNombrePdfComando =
    'Las facturas del lote producen el mismo nombre de salida: "%s".';
  SErrorBloqueoNombrePdfComando =
    'Otro proceso está generando el mismo PDF o no se pudo bloquear su ' +
    'nombre de salida: "%s". %s';
  SErrorSesionComandoImprimirFacturas =
    'No se ha iniciado sesión. La autenticación fue cancelada o no pudo ' +
    'completarse.';
  SErrorServiciosComandoImprimirFacturas =
    'La sesión o los servicios necesarios para imprimir no están disponibles.';
  SInfoDetectadoComandoImprimirFacturas =
    'Detectado /imprimirfacturas. Se valida la sintaxis antes del inicio de ' +
    'sesión.';
  SInfoSintaxisValidaComandoImprimirFacturas =
    'Sintaxis válida. Facturas solicitadas: %d. Formato: %s. Destino: %s.';
  SInfoSolicitudSesionComandoImprimirFacturas =
    'La sintaxis es válida. Se requiere una sesión autenticada para continuar.';
  SInfoInicioComandoImprimirFacturas =
    'Inicio de /imprimirfacturas. Usuario: %s. Grupo: %s. Facturas: %d. ' +
    'Formato: %s.';
  SInfoUbicacionComandoImprimirFacturas =
    'Ubicación de sesión. Empresa: %s. Almacén: %s. Caja: %s.';
  SInfoPoliticaComandoImprimirFacturas =
    'Política de impresión. VeriFactu ONLINE: %s. Permiso factura: %s. ' +
    'Permiso factura simplificada: %s.';
  SInfoAmbitoComandoImprimirFacturas =
    'Ámbito aplicado. Empresa: %s. Almacén: %s. Caja: %s.';
  SInfoInicioValidacionComandoImprimirFacturas =
    'Se inicia la prevalidación completa de %d facturas.';
  SInfoConsultaFacturaComandoImprimirFacturas =
    'Validación %d/%d. Se consulta la factura %s.';
  SInfoDatosFacturaComandoImprimirFacturas =
    'Factura %s localizada. Tipo: %s. Consolidada: %s. Empresa: %s. ' +
    'Almacén: %s. Caja: %s.';
  SInfoFacturaAutorizadaComandoImprimirFacturas =
    'Factura %s autorizada.';
  SInfoFinValidacionComandoImprimirFacturas =
    'Prevalidación completa superada. No se ha generado todavía ningún PDF.';
  SInfoDirectorioExisteComandoImprimirFacturas =
    'El directorio de destino ya existe: %s.';
  SInfoCrearDirectorioComandoImprimirFacturas =
    'El directorio no existe. Se intenta crearlo: %s.';
  SInfoDirectorioPreparadoComandoImprimirFacturas =
    'Directorio de destino preparado: %s.';
  SInfoCrearImpresorComandoImprimirFacturas =
    'Se crean el módulo de datos y el impresor exclusivos del lote.';
  SInfoConexionImpresorComandoImprimirFacturas =
    'Las consultas del lote se asignan a la conexión de la sesión del ' +
    'proceso.';
  SInfoFuentesComandoImprimirFacturas =
    'Exportador PDF configurado con fuentes embebidas.';
  SInfoModoArchivoComandoImprimirFacturas =
    'Modo de exportación: solo archivo. No se modifica el BLOB de la ' +
    'factura ni se encola un adjunto para servicios externos.';
  SInfoCargarFormatoComandoImprimirFacturas =
    'Se comprueba y carga el formato visible "%s".';
  SInfoFormatoCargadoComandoImprimirFacturas =
    'Formato "%s" cargado correctamente.';
  SInfoPrepararFacturaComandoImprimirFacturas =
    'Impresión %d/%d. Se preparan los datos de %s.';
  SInfoDatosPreparadosComandoImprimirFacturas =
    'Datos de impresión preparados para %s.';
  SInfoNombrePdfComandoImprimirFacturas =
    'ObtenerNombreFactura ha producido "%s" para %s.';
  SInfoPdfExistenteComandoImprimirFacturas =
    'El PDF de destino ya existe y será sustituido: %s.';
  SInfoExportarPdfComandoImprimirFacturas =
    'Se exporta %s a PDF en "%s".';
  SInfoPdfTemporalComandoImprimirFacturas =
    'Se genera primero un PDF temporal único para %s.';
  SInfoBloqueoPdfComandoImprimirFacturas =
    'Bloqueo exclusivo adquirido para publicar "%s".';
  SInfoLiberarBloqueoPdfComandoImprimirFacturas =
    'Bloqueo exclusivo liberado para "%s".';
  SAvisoEliminarPdfTemporalComandoImprimirFacturas =
    'No se pudo eliminar el PDF temporal "%s": %s.';
  SInfoPdfFacturaComando =
    'PDF generado y comprobado para %s: %s (%d bytes).';
  SInfoLoteParcialComandoImprimirFacturas =
    ' Antes del error se completaron %d de %d PDF.';
  SInfoCerrarImpresorComandoImprimirFacturas =
    'Se liberan el impresor y el módulo de datos del lote.';
  SInfoFinComandoImprimirFacturas =
    'Generados %d PDF de factura en "%s" con el usuario %s.';
  SErrorSinImpresoraLoteFacturas =
    'No hay ninguna impresora de documentos disponible.';
  SErrorImpresoraLoteFacturasNoExiste =
    'La impresora de documentos "%s" no está disponible.';
  SErrorIniciarLoteImpresionFacturas =
    'No se pudo iniciar la impresión por lotes: %s';
  SErrorLoteImpresionFacturasEnCurso =
    'Ya hay una impresión por lotes en curso.';
  SErrorLoteImpresionFacturasCerrando =
    'No se puede iniciar la impresión por lotes porque la aplicación se ' +
    'está cerrando.';
  SErrorImprimirFacturaLote =
    'No se pudo enviar la factura %s a la impresora "%s".';
  SInfoInicioLoteImpresionFacturas =
    'Se inicia en segundo plano la impresión de %d facturas filtradas.';
  SInfoOmitirFacturaNoConsolidadaLote =
    'La factura %s se omite porque no está consolidada.';
  SInfoFacturaEnviadaLote =
    'Factura %s enviada a la impresora "%s".';
  SInfoFinLoteImpresionFacturas =
    'Impresión por lotes finalizada. Solicitadas: %d. Impresas: %d. ' +
    'Omitidas no consolidadas: %d.';
  SInfoCorreoFacturaLoteEnviado =
    'Factura %s enviada por correo a %s.';
  SAvisoCorreoFacturaLoteSinDestinatario =
    'Factura %s sin envío: EMAIL_CLIENTE_FAC está vacío.';
  SErrorCorreoFacturaLote =
    'No se pudo enviar por correo la factura %s a %s: %s';
  SErrorPrepararCorreoFacturaLote =
    'No se pudo generar el PDF temporal para enviar por correo la factura %s.';
  SErrorInesperadoLotePdfFacturas =
    'Se produjo un error inesperado durante el lote de PDF: %s: %s.';

var
  GBloqueoLoteImpresionFacturas: TCriticalSection;
  GHiloLoteImpresionFacturas: TThread;
  GInicioLoteImpresionFacturasEnCurso: Boolean;
  GCierreLoteImpresionFacturas: Boolean;

procedure InformarFalloRegistroEnDepurador(
  const AOperacion: string;
  E: Exception);
begin
  OutputDebugString(PChar(
    'inMtoComandoImprimirFacturas.' + AOperacion + ': ' +
    E.ClassName + ': ' + E.Message));
end;

function HiloLoteTerminado(AHilo: TThread): Boolean;
begin
  Result := Assigned(AHilo) and TThreadAcceso(AHilo).Terminated;
end;

procedure RegistrarInformacionSeguro(
  const ARegistroLog: IRegistroLog;
  const AMensaje: string);
begin
  if Assigned(ARegistroLog) then
  begin
    try
      ARegistroLog.RegistrarInformacion(AMensaje);
    except
      on E: Exception do
        InformarFalloRegistroEnDepurador('RegistrarInformacion', E);
    end;
  end;
end;

procedure RegistrarAvisoSeguro(
  const ARegistroLog: IRegistroLog;
  const AMensaje: string);
begin
  if Assigned(ARegistroLog) then
  begin
    try
      ARegistroLog.RegistrarAviso(AMensaje);
    except
      on E: Exception do
        InformarFalloRegistroEnDepurador('RegistrarAviso', E);
    end;
  end;
end;

procedure RegistrarErrorSeguro(
  const ARegistroLog: IRegistroLog;
  const AMensaje: string);
begin
  if Assigned(ARegistroLog) then
  begin
    try
      ARegistroLog.RegistrarError(AMensaje);
    except
      on E: Exception do
        InformarFalloRegistroEnDepurador('RegistrarError', E);
    end;
  end;
end;

function TextoUnaLinea(const ATexto: string): string;
begin
  Result := StringReplace(ATexto, #13, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #9, ' ', [rfReplaceAll]);
  Result := Trim(Result);
end;

procedure AgregarDetalleCorreo(
  var ADetalle: string;
  const AReferencia, AEstado, AEmail, AMensaje: string);
var
  sLinea: string;
begin
  sLinea := TextoUnaLinea(AReferencia) + ' | ' + AEstado;
  if Trim(AEmail) <> '' then
    sLinea := sLinea + ' | ' + TextoUnaLinea(AEmail);
  if Trim(AMensaje) <> '' then
    sLinea := sLinea + ' | ' + TextoUnaLinea(AMensaje);
  if ADetalle <> '' then
    ADetalle := ADetalle + sLineBreak;
  ADetalle := ADetalle + sLinea;
end;

function EnviarPdfFacturaPorCorreo(
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AReferencia, ANombreEmpresa, AEmailRespuesta, AEmail,
    ARutaPdf: string;
  out AMensaje: string): Boolean;
var
  oRutas: TStringList;
begin
  oRutas := TStringList.Create;
  try
    oRutas.Add(ARutaPdf);
    Result := EnviarDocumentosPorCorreo(
      AParametrosApp,
      tdcFactura,
      AReferencia,
      ANombreEmpresa,
      AEmail,
      AEmailRespuesta,
      oRutas,
      ARegistroLog,
      AMensaje);
  finally
    FreeAndNil(oRutas);
  end;
end;

procedure RegistrarCorreoSinDestinatario(
  const AReferencia: TReferenciaComandoFactura;
  const ARegistroLog: IRegistroLog;
  var AContador: Integer;
  var ADetalle: string);
begin
  Inc(AContador);
  AgregarDetalleCorreo(
    ADetalle,
    AReferencia.Texto,
    SEstadoCorreoFacturaSinEmail,
    '',
    SDetalleCorreoFacturaSinEmail);
  RegistrarAvisoSeguro(
    ARegistroLog,
    Format(
      SAvisoCorreoFacturaLoteSinDestinatario,
      [AReferencia.Texto]));
end;

procedure RegistrarErrorCorreoFactura(
  const AReferencia: TReferenciaComandoFactura;
  const AEmail, AMensaje: string;
  const ARegistroLog: IRegistroLog;
  ARegistrarMensajeDirecto: Boolean;
  var AContador: Integer;
  var ADetalle: string);
begin
  Inc(AContador);
  AgregarDetalleCorreo(
    ADetalle,
    AReferencia.Texto,
    SEstadoCorreoFacturaError,
    AEmail,
    AMensaje);
  if ARegistrarMensajeDirecto then
    RegistrarErrorSeguro(ARegistroLog, AMensaje)
  else
    RegistrarErrorSeguro(
      ARegistroLog,
      Format(
        SErrorCorreoFacturaLote,
        [AReferencia.Texto, AEmail, AMensaje]));
end;

procedure RegistrarCorreoFacturaEnviado(
  const AReferencia: TReferenciaComandoFactura;
  const AEmail: string;
  const ARegistroLog: IRegistroLog;
  var AContador: Integer;
  var ADetalle: string);
begin
  Inc(AContador);
  AgregarDetalleCorreo(
    ADetalle,
    AReferencia.Texto,
    SEstadoCorreoFacturaEnviado,
    AEmail,
    '');
  RegistrarInformacionSeguro(
    ARegistroLog,
    Format(
      SInfoCorreoFacturaLoteEnviado,
      [AReferencia.Texto, AEmail]));
end;

procedure ProcesarCorreoFactura(
  const AReferencia: TReferenciaComandoFactura;
  const ACorreo: TDatosCorreoFacturaLote;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  ARegistrarErrorPreparacionDirecto: Boolean;
  var AEnviados, ASinDestinatario, AConError: Integer;
  var ADetalle: string);
var
  sMensaje: string;
begin
  if ACorreo.Email = '' then
    RegistrarCorreoSinDestinatario(
      AReferencia, ARegistroLog, ASinDestinatario, ADetalle)
  else if ACorreo.ErrorPreparacion <> '' then
    RegistrarErrorCorreoFactura(
      AReferencia,
      ACorreo.Email,
      ACorreo.ErrorPreparacion,
      ARegistroLog,
      ARegistrarErrorPreparacionDirecto,
      AConError,
      ADetalle)
  else
  begin
    try
      if EnviarPdfFacturaPorCorreo(
        AParametrosApp,
        nil,
        AReferencia.Texto,
        ACorreo.NombreEmpresa,
        ACorreo.EmailRespuesta,
        ACorreo.Email,
        ACorreo.RutaPdf,
        sMensaje) then
      begin
        RegistrarCorreoFacturaEnviado(
          AReferencia,
          ACorreo.Email,
          ARegistroLog,
          AEnviados,
          ADetalle);
      end
      else
        RegistrarErrorCorreoFactura(
          AReferencia,
          ACorreo.Email,
          sMensaje,
          ARegistroLog,
          False,
          AConError,
          ADetalle);
    except
      on E: Exception do
        RegistrarErrorCorreoFactura(
          AReferencia,
          ACorreo.Email,
          E.ClassName + ': ' + E.Message,
          ARegistroLog,
          False,
          AConError,
          ADetalle);
    end;
  end;
end;

procedure EliminarPdfTemporalSeguro(
  const ARuta: string;
  const ARegistroLog: IRegistroLog);
begin
  if (Trim(ARuta) <> '') and FileExists(ARuta) then
  begin
    try
      SetLastError(ERROR_SUCCESS);
      if not System.SysUtils.DeleteFile(ARuta) then
        RegistrarAvisoSeguro(
          ARegistroLog,
          Format(
            SAvisoEliminarPdfTemporalComandoImprimirFacturas,
            [ARuta, SysErrorMessage(GetLastError)]));
    except
      on E: Exception do
        RegistrarAvisoSeguro(
          ARegistroLog,
          Format(
            SAvisoEliminarPdfTemporalComandoImprimirFacturas,
            [ARuta, E.ClassName + ': ' + E.Message]));
    end;
  end;
end;

function TextoSiNo(AValor: Boolean): string;
begin
  if AValor then
    Result := 'Sí'
  else
    Result := 'No';
end;

function TextoAmbito(const AValor: string): string;
begin
  Result := Trim(AValor);
  if Result = '' then
    Result := '(sin restricción)';
end;

function CrearRutaTemporalPdf(const ARutaFinal: string): string;
var
  oIdentificador: TGUID;
  sIdentificador: string;
begin
  CreateGUID(oIdentificador);
  sIdentificador := GUIDToString(oIdentificador);
  sIdentificador := StringReplace(
    sIdentificador,
    '{',
    '',
    [rfReplaceAll]);
  sIdentificador := StringReplace(
    sIdentificador,
    '}',
    '',
    [rfReplaceAll]);
  Result := TPath.Combine(
    ExtractFilePath(ARutaFinal),
    '.viracash-pdf-' + IntToStr(GetCurrentProcessId) + '-' +
    sIdentificador + '.pdf');
end;

function EsPdfValido(
  const ARuta: string;
  out ATamano: Int64): Boolean;
const
  TAMANO_COLA_PDF = 4096;
  TAMANO_MINIMO_PDF = 256;
var
  aCabecera: array[0..4] of Byte;
  aCola: TBytes;
  bFinEncontrado: Boolean;
  iIndice: Integer;
  iTamanoCola: Integer;
  oFlujo: TFileStream;
begin
  Result := False;
  ATamano := 0;
  if FileExists(ARuta) then
  begin
    oFlujo := TFileStream.Create(
      ARuta,
      fmOpenRead or fmShareDenyWrite);
    try
      ATamano := oFlujo.Size;
      if ATamano >= TAMANO_MINIMO_PDF then
      begin
        oFlujo.ReadBuffer(aCabecera, Length(aCabecera));
        Result := (aCabecera[0] = Ord('%')) and
                  (aCabecera[1] = Ord('P')) and
                  (aCabecera[2] = Ord('D')) and
                  (aCabecera[3] = Ord('F')) and
                  (aCabecera[4] = Ord('-'));
        if Result then
        begin
          if ATamano > TAMANO_COLA_PDF then
            iTamanoCola := TAMANO_COLA_PDF
          else
            iTamanoCola := Integer(ATamano);
          SetLength(aCola, iTamanoCola);
          oFlujo.Position := ATamano - iTamanoCola;
          oFlujo.ReadBuffer(aCola[0], iTamanoCola);
          bFinEncontrado := False;
          iIndice := 0;
          while (iIndice <= Length(aCola) - 5) and
                not bFinEncontrado do
          begin
            bFinEncontrado :=
              (aCola[iIndice] = Ord('%')) and
              (aCola[iIndice + 1] = Ord('%')) and
              (aCola[iIndice + 2] = Ord('E')) and
              (aCola[iIndice + 3] = Ord('O')) and
              (aCola[iIndice + 4] = Ord('F'));
            Inc(iIndice);
          end;
          Result := bFinEncontrado;
        end;
      end;
    finally
      FreeAndNil(oFlujo);
    end;
  end;
end;

function PublicarPdfTemporal(
  const ARutaTemporal, ARutaFinal: string;
  out AError: string): Boolean;
var
  iError: Cardinal;
begin
  AError := '';
  SetLastError(ERROR_SUCCESS);
  Result := MoveFileEx(
    PChar(ARutaTemporal),
    PChar(ARutaFinal),
    MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH);
  if not Result then
  begin
    iError := GetLastError;
    AError := SysErrorMessage(iError);
  end;
end;

function IntentarBloquearRutaPdf(
  const ARuta: string;
  out ABloqueo: THandle;
  out AError: string): Boolean;
var
  iEspera: Cardinal;
  sNombreMutex: string;
  sRutaNormalizada: string;
begin
  Result := False;
  ABloqueo := 0;
  AError := '';
  try
    sRutaNormalizada := UpperCase(TPath.GetFullPath(ARuta));
    sNombreMutex := 'Local\ViraCash-ImprimirFactura-' +
      THashSHA2.GetHashString(sRutaNormalizada);
    SetLastError(ERROR_SUCCESS);
    ABloqueo := CreateMutex(nil, False, PChar(sNombreMutex));
    if ABloqueo = 0 then
      AError := SysErrorMessage(GetLastError)
    else
    begin
      iEspera := WaitForSingleObject(ABloqueo, 0);
      Result := (iEspera = WAIT_OBJECT_0) or
                (iEspera = WAIT_ABANDONED);
      if not Result then
      begin
        if iEspera = WAIT_TIMEOUT then
          AError := SErrorNombreComandoImprimirFacturasBloqueado
        else
          AError := SysErrorMessage(GetLastError);
        CloseHandle(ABloqueo);
        ABloqueo := 0;
      end;
    end;
  except
    on E: Exception do
    begin
      AError := E.ClassName + ': ' + E.Message;
      if ABloqueo <> 0 then
      begin
        CloseHandle(ABloqueo);
        ABloqueo := 0;
      end;
    end;
  end;
end;

procedure LiberarBloqueoRutaPdf(var ABloqueo: THandle);
begin
  if ABloqueo <> 0 then
  begin
    ReleaseMutex(ABloqueo);
    CloseHandle(ABloqueo);
    ABloqueo := 0;
  end;
end;

function CrearResultado(
  ACodigoSalida: Cardinal;
  const AMensaje: string
): TResultadoComandoImprimirFacturas;
begin
  Result := Default(TResultadoComandoImprimirFacturas);
  Result.CodigoSalida := ACodigoSalida;
  Result.EsError := ACodigoSalida <> 0;
  Result.Mensaje := AMensaje;
end;

function EsProcesoComandoImprimirFacturas: Boolean;
begin
  Result := EsComandoImprimirFacturas(
    ObtenerParametrosLineaComandos);
end;

function MensajeErrorSolicitud(
  const ASolicitud: TSolicitudComandoImprimirFacturas): string;
begin
  case ASolicitud.Error of
    ecifListaVacia,
    ecifReferenciaInvalida,
    ecifReferenciaDuplicada:
      Result := Format(
        SErrorListaComandoImprimirFacturas,
        [ASolicitud.DetalleError]);
    ecifFormato:
      Result := Format(
        SErrorFormatoComandoImprimirFacturas,
        [ASolicitud.Formato]);
    ecifDirectorio:
      Result := Format(
        SErrorDirectorioComandoImprimirFacturas,
        [ASolicitud.DirectorioDestino]);
  else
    Result := SErrorSintaxisComandoImprimirFacturas;
  end;
end;

function CodigoErrorSolicitud(
  AError: TErrorComandoImprimirFacturas): Cardinal;
begin
  case AError of
    ecifDirectorio:
      Result := SALIDA_COMANDO_IMPRESION_DIRECTORIO;
    ecifFormato:
      Result := SALIDA_COMANDO_IMPRESION_FORMATO;
  else
    Result := SALIDA_COMANDO_IMPRESION_SINTAXIS;
  end;
end;

function CrearContextoAutorizacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion
): TContextoAutorizacionComandoFactura;
begin
  Result := Default(TContextoAutorizacionComandoFactura);
  // En SII también solo se imprime la factura consolidada (FZ-ISSUE-293)
  Result.VerifactuOnline := VerifactuActivo(AParametrosApp) or
    SiiActivo(AParametrosApp);
  Result.PuedeImprimirNormal := Assigned(APermisos) and
    APermisos.TienePermiso(
      CodigoPermisoMto('Facturas', apmImprimir),
      paPermitir);
  Result.PuedeImprimirSimplificada := Assigned(APermisos) and
    APermisos.TienePermiso(
      CodigoPermisoMto('FacturasSimplif', apmImprimir),
      paPermitir);
  Result.EmpresaRestringida := EmpresaRestringida(
    AContextoSesion,
    AParametrosApp);
  Result.AlmacenRestringido := AlmacenRestringido(
    AContextoSesion,
    AParametrosApp);
  Result.CajaRestringida := CajaRestringida(
    AContextoSesion,
    AParametrosApp);
end;

function LeerDatosAutorizacion(
  AConsulta: TUniQuery;
  const AReferencia: TReferenciaComandoFactura
): TDatosAutorizacionComandoFactura;
begin
  Result := Default(TDatosAutorizacionComandoFactura);
  AConsulta.Close;
  AConsulta.ParamByName('SERIE').AsString := AReferencia.Serie;
  AConsulta.ParamByName('NUMERO').AsString := AReferencia.Numero;
  AConsulta.Open;
  Result.Existe := not AConsulta.IsEmpty;
  if Result.Existe then
  begin
    Result.Consolidada := SameText(
      AConsulta.FieldByName('ESCONSOLIDADA_FAC').AsString,
      'S');
    Result.TipoFactura :=
      AConsulta.FieldByName('TIPO_FAC').AsString;
    Result.CodigoEmpresa :=
      AConsulta.FieldByName('CODIGO_EMP_FAC').AsString;
    Result.CodigoAlmacen :=
      AConsulta.FieldByName('CODIGO_ALM_FAC').AsString;
    Result.CodigoCaja :=
      AConsulta.FieldByName('CODIGO_CAJA_FAC').AsString;
  end;
end;

function LeerDatosAutorizacionDataSet(
  ADataSet: TDataSet): TDatosAutorizacionComandoFactura;
begin
  Result := Default(TDatosAutorizacionComandoFactura);
  Result.Existe := Assigned(ADataSet) and
                   ADataSet.Active and
                   not ADataSet.IsEmpty;
  if Result.Existe then
  begin
    Result.Consolidada := SameText(
      ADataSet.FieldByName('ESCONSOLIDADA_FAC').AsString,
      'S');
    Result.TipoFactura :=
      ADataSet.FieldByName('TIPO_FAC').AsString;
    Result.CodigoEmpresa :=
      ADataSet.FieldByName('CODIGO_EMP_FAC').AsString;
    Result.CodigoAlmacen :=
      ADataSet.FieldByName('CODIGO_ALM_FAC').AsString;
    Result.CodigoCaja :=
      ADataSet.FieldByName('CODIGO_CAJA_FAC').AsString;
  end;
end;

function DataSetCorrespondeAReferencia(
  ADataSet: TDataSet;
  const AReferencia: TReferenciaComandoFactura): Boolean;
begin
  Result := Assigned(ADataSet) and
            ADataSet.Active and
            not ADataSet.IsEmpty and
            SameText(
              ADataSet.FieldByName('SERIE_FAC').AsString,
              AReferencia.Serie) and
            SameText(
              ADataSet.FieldByName('NUMERO_FAC').AsString,
              AReferencia.Numero);
end;

function CrearErrorAutorizacion(
  ARechazo: TRechazoComandoFactura;
  const AReferencia: TReferenciaComandoFactura;
  const AUsuario: string
): TResultadoComandoImprimirFacturas;
begin
  case ARechazo of
    rcifNoEncontrada:
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_FACTURA,
        Format(
          SErrorFacturaNoAutorizadaComando,
          [AReferencia.Texto, AUsuario]));
    rcifFueraDeAmbito:
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_AUTORIZACION,
        Format(
          SErrorFacturaNoAutorizadaComando,
          [AReferencia.Texto, AUsuario]));
    rcifSinPermiso:
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_AUTORIZACION,
        Format(
          SErrorFacturaNoAutorizadaComando,
          [AReferencia.Texto, AUsuario]));
    rcifTipoNoAdmitido:
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_AUTORIZACION,
        Format(
          SErrorFacturaNoAutorizadaComando,
          [AReferencia.Texto, AUsuario]));
    rcifNoConsolidada:
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_FACTURA,
        Format(
          SErrorFacturaNoConsolidadaComando,
          [AReferencia.Texto]));
  else
    Result := CrearResultado(0, '');
  end;
end;

function ValidarFacturasSolicitadas(
  AConexion: TUniConnection;
  const ASolicitud: TSolicitudComandoImprimirFacturas;
  const AContexto: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog
): TResultadoComandoImprimirFacturas;
var
  iFactura: Integer;
  oConsulta: TUniQuery;
  oDatos: TDatosAutorizacionComandoFactura;
  oRechazo: TRechazoComandoFactura;
begin
  Result := CrearResultado(0, '');
  RegistrarInformacionSeguro(
    ARegistroLog,
    Format(
      SInfoInicioValidacionComandoImprimirFacturas,
      [Length(ASolicitud.Referencias)]));
  oConsulta := CrearConsultaAutorizacionImpresionFacturas(AConexion);
  try
    iFactura := 0;
    while (iFactura <= High(ASolicitud.Referencias)) and
          not Result.EsError do
    begin
      RegistrarInformacionSeguro(
        ARegistroLog,
        Format(
          SInfoConsultaFacturaComandoImprimirFacturas,
          [iFactura + 1,
           Length(ASolicitud.Referencias),
           ASolicitud.Referencias[iFactura].Texto]));
      oDatos := LeerDatosAutorizacion(
        oConsulta,
        ASolicitud.Referencias[iFactura]);
      oRechazo := EvaluarAutorizacionComandoFactura(
        oDatos,
        AContexto);
      if oRechazo <> rcifNinguno then
      begin
        case oRechazo of
          rcifNoEncontrada:
            RegistrarAvisoSeguro(
              ARegistroLog,
              Format(
                SErrorFacturaNoEncontradaComando,
                [ASolicitud.Referencias[iFactura].Texto]));
          rcifFueraDeAmbito:
            RegistrarAvisoSeguro(
              ARegistroLog,
              Format(
                SErrorFacturaFueraAmbitoComando,
                [ASolicitud.Referencias[iFactura].Texto, AUsuario]));
          rcifSinPermiso:
            RegistrarAvisoSeguro(
              ARegistroLog,
              Format(
                SErrorPermisoFacturaComando,
                [AUsuario, ASolicitud.Referencias[iFactura].Texto]));
          rcifTipoNoAdmitido:
            RegistrarAvisoSeguro(
              ARegistroLog,
              Format(
                SErrorTipoFacturaComando,
                [ASolicitud.Referencias[iFactura].Texto,
                 oDatos.TipoFactura]));
          rcifNoConsolidada:
            RegistrarAvisoSeguro(
              ARegistroLog,
              Format(
                SErrorFacturaNoConsolidadaComando,
                [ASolicitud.Referencias[iFactura].Texto]));
        end;
        Result := CrearErrorAutorizacion(
          oRechazo,
          ASolicitud.Referencias[iFactura],
          AUsuario);
      end;
      if oRechazo = rcifNinguno then
      begin
        RegistrarInformacionSeguro(
          ARegistroLog,
          Format(
            SInfoDatosFacturaComandoImprimirFacturas,
            [ASolicitud.Referencias[iFactura].Texto,
             oDatos.TipoFactura,
             TextoSiNo(oDatos.Consolidada),
             TextoAmbito(oDatos.CodigoEmpresa),
             TextoAmbito(oDatos.CodigoAlmacen),
             TextoAmbito(oDatos.CodigoCaja)]));
        RegistrarInformacionSeguro(
          ARegistroLog,
          Format(
            SInfoFacturaAutorizadaComandoImprimirFacturas,
            [ASolicitud.Referencias[iFactura].Texto]));
      end;
      Inc(iFactura);
    end;
  finally
    FreeAndNil(oConsulta);
  end;
  if not Result.EsError then
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      SInfoFinValidacionComandoImprimirFacturas);
  end;
end;

function ResolverImpresoraLote(
  const AConfigurada: string;
  out AImpresora, AError: string): Boolean;
begin
  Result := False;
  AImpresora := '';
  AError := '';
  try
    if (frxPrinters = nil) or
       not frxPrinters.HasPhysicalPrinters then
      AError := SErrorSinImpresoraLoteFacturas
    else
    begin
      AImpresora := Trim(AConfigurada);
      if AImpresora = '' then
      begin
        if frxPrinters.Printer <> nil then
          AImpresora := Trim(frxPrinters.Printer.Name);
      end
      else if frxPrinters.IndexOf(AImpresora) < 0 then
        AError := Format(
          SErrorImpresoraLoteFacturasNoExiste,
          [AImpresora]);
      if AError = '' then
      begin
        if AImpresora = '' then
          AError := SErrorSinImpresoraLoteFacturas
        else
          Result := True;
      end;
    end;
  except
    on E: Exception do
      AError := E.ClassName + ': ' + E.Message;
  end;
end;

function PrevalidarLoteImpresionFacturas(
  AConexion: TUniConnection;
  const AReferencias: TReferenciasComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog;
  AHilo: TThread;
  out AConsolidadas: TReferenciasComandoFactura;
  out AOmitidas: Integer;
  out AError: string): Boolean;
var
  iFactura: Integer;
  oConsulta: TUniQuery;
  oDatos: TDatosAutorizacionComandoFactura;
  oLista: TList<TReferenciaComandoFactura>;
  oRechazo: TRechazoComandoFactura;
begin
  Result := False;
  AConsolidadas := nil;
  AOmitidas := 0;
  AError := '';
  oConsulta := CrearConsultaAutorizacionImpresionFacturas(AConexion);
  oLista := TList<TReferenciaComandoFactura>.Create;
  try
    iFactura := 0;
    while (iFactura <= High(AReferencias)) and
          (AError = '') and
          not HiloLoteTerminado(AHilo) do
    begin
      oDatos := LeerDatosAutorizacion(
        oConsulta, AReferencias[iFactura]);
      oRechazo := EvaluarAutorizacionComandoFactura(
        oDatos, AContexto);
      if oRechazo <> rcifNinguno then
        AError := CrearErrorAutorizacion(
          oRechazo, AReferencias[iFactura], AUsuario).Mensaje
      else if not oDatos.Consolidada then
      begin
        Inc(AOmitidas);
        RegistrarInformacionSeguro(
          ARegistroLog,
          Format(
            SInfoOmitirFacturaNoConsolidadaLote,
            [AReferencias[iFactura].Texto]));
      end
      else
        oLista.Add(AReferencias[iFactura]);
      Inc(iFactura);
    end;
    if (iFactura > High(AReferencias)) and (AError = '') then
    begin
      AConsolidadas := oLista.ToArray;
      Result := True;
    end;
  finally
    FreeAndNil(oLista);
    FreeAndNil(oConsulta);
  end;
end;

function AutorizarFacturaConsolidadaLote(
  const AReferencia: TReferenciaComandoFactura;
  const ADatos: TDatosAutorizacionComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  var AEstado: TEstadoFacturaImpresionLote;
  out AError: string): Boolean;
var
  oRechazo: TRechazoComandoFactura;
begin
  Result := False;
  oRechazo := EvaluarAutorizacionComandoFactura(ADatos, AContexto);
  if oRechazo <> rcifNinguno then
    AError := CrearErrorAutorizacion(
      oRechazo, AReferencia, AUsuario).Mensaje
  else if not ADatos.Consolidada then
    AEstado := efilOmitidaNoConsolidada
  else
    Result := True;
end;

function ValidarReferenciaConsolidadaLote(
  AConsulta: TUniQuery;
  const AReferencia: TReferenciaComandoFactura;
  const AContexto: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  var AEstado: TEstadoFacturaImpresionLote;
  out AError: string): Boolean;
begin
  Result := AutorizarFacturaConsolidadaLote(
    AReferencia,
    LeerDatosAutorizacion(AConsulta, AReferencia),
    AContexto,
    AUsuario,
    AEstado,
    AError);
end;

function PrepararFacturaConsolidadaLote(
  const AReferencia: TReferenciaComandoFactura;
  const AFormato: string;
  const AContexto: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  ADatosFactura: TdmFacturas;
  AFormulario: TfrmPrintFac;
  var AEstado: TEstadoFacturaImpresionLote;
  out AError: string): Boolean;
begin
  Result := False;
  AFormulario.ConfigurarDataModule(ADatosFactura);
  AFormulario.rbActual.Checked := True;
  AFormulario.rbProcesarFiltrados.Checked := False;
  if not AFormulario.SeleccionarFormatoSinDialogo(AFormato) then
    AError := Format(SErrorFormatoComandoImprimirFacturas, [AFormato])
  else
  begin
    AFormulario.edtSerie.Text := AReferencia.Serie;
    AFormulario.edtNroFac.Text := AReferencia.Numero;
    AFormulario.preparar_consulta;
    if not DataSetCorrespondeAReferencia(
      ADatosFactura.unqryFacPrint, AReferencia) then
      AError := Format(SErrorPrepararFacturaComando, [AReferencia.Texto])
    else
      Result := AutorizarFacturaConsolidadaLote(
        AReferencia,
        LeerDatosAutorizacionDataSet(ADatosFactura.unqryFacPrint),
        AContexto,
        AUsuario,
        AEstado,
        AError);
  end;
end;

procedure PrepararCorreoFacturaImpresa(
  const AReferencia: TReferenciaComandoFactura;
  ADatosFactura: TdmFacturas;
  AFormulario: TfrmPrintFac;
  const ARegistroLog: IRegistroLog;
  var ACorreo: TDatosCorreoFacturaLote);
var
  iTamanoPdf: Int64;
begin
  ACorreo.Email := Trim(
    ADatosFactura.unqryFacPrint.FieldByName('EMAIL_CLIENTE_FAC').AsString);
  ACorreo.EmailRespuesta := Trim(
    ADatosFactura.unqryFacPrint.FieldByName('EMAIL_EMPRESA_FAC').AsString);
  ACorreo.NombreEmpresa := Trim(
    ADatosFactura.unqryFacPrint.FieldByName(
      'RAZON_SOCIAL_EMPRESA_FAC').AsString);
  if ACorreo.Email <> '' then
  begin
    ACorreo.RutaPdf := CrearRutaTemporalPdf(
      TPath.Combine(TPath.GetTempPath, 'correo_factura.pdf'));
    try
      if not AFormulario.ExportarPdfPreparado(ACorreo.RutaPdf, False) or
         not EsPdfValido(ACorreo.RutaPdf, iTamanoPdf) then
      begin
        ACorreo.ErrorPreparacion := Format(
          SErrorPrepararCorreoFacturaLote,
          [AReferencia.Texto]);
        EliminarPdfTemporalSeguro(ACorreo.RutaPdf, ARegistroLog);
        ACorreo.RutaPdf := '';
      end;
    except
      on E: Exception do
      begin
        ACorreo.ErrorPreparacion := Format(
          SErrorPrepararCorreoFacturaLote,
          [AReferencia.Texto]) + ' ' + E.ClassName + ': ' + E.Message;
        EliminarPdfTemporalSeguro(ACorreo.RutaPdf, ARegistroLog);
        ACorreo.RutaPdf := '';
      end;
    end;
  end;
end;

function ImprimirFacturaConsolidada(
  const AReferencia: TReferenciaComandoFactura;
  const AFormato, AImpresora: string;
  APrepararCorreo: Boolean;
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const AContexto: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  const ARegistroLog: IRegistroLog;
  out ACorreo: TDatosCorreoFacturaLote;
  out AError: string): TEstadoFacturaImpresionLote;
var
  bPreparada: Boolean;
  oConsulta: TUniQuery;
  oDatosFactura: TdmFacturas;
  oFormulario: TfrmPrintFac;
begin
  Result := efilError;
  ACorreo := Default(TDatosCorreoFacturaLote);
  AError := '';
  oConsulta := nil;
  oDatosFactura := nil;
  oFormulario := nil;
  try
    try
      bPreparada := (AOwnerSesion <> nil) and
                    not (csDestroying in AOwnerSesion.ComponentState) and
                    (AConexion <> nil) and AConexion.Connected;
      if not bPreparada then
        AError := SErrorServiciosComandoImprimirFacturas;
      if bPreparada then
      begin
        oConsulta := CrearConsultaAutorizacionImpresionFacturas(AConexion);
        bPreparada := ValidarReferenciaConsolidadaLote(
          oConsulta, AReferencia, AContexto, AUsuario, Result, AError);
      end;
      if bPreparada then
      begin
        oDatosFactura := TdmFacturas.Create(AOwnerSesion);
        oDatosFactura.ReasignarConexion(AConexion);
        oFormulario := TfrmPrintFac.Create(AOwnerSesion);
        bPreparada := PrepararFacturaConsolidadaLote(
          AReferencia,
          AFormato,
          AContexto,
          AUsuario,
          oDatosFactura,
          oFormulario,
          Result,
          AError);
      end;
      if bPreparada then
      begin
        if not oFormulario.ImprimirPreparadoEn(AImpresora) then
          AError := Format(
            SErrorImprimirFacturaLote,
            [AReferencia.Texto, AImpresora])
        else
        begin
          RegistrarInformacionSeguro(
            ARegistroLog,
            Format(SInfoFacturaEnviadaLote, [AReferencia.Texto, AImpresora]));
          if APrepararCorreo then
            PrepararCorreoFacturaImpresa(
              AReferencia, oDatosFactura, oFormulario, ARegistroLog, ACorreo);
          Result := efilImpresa;
        end;
      end;
    except
      on E: Exception do
        AError := Format(
          SErrorImprimirFacturaLote,
          [AReferencia.Texto, AImpresora]) + ' ' +
          E.ClassName + ': ' + E.Message;
    end;
  finally
    FreeAndNil(oFormulario);
    FreeAndNil(oDatosFactura);
    FreeAndNil(oConsulta);
  end;
end;

function PrepararDirectorio(
  const ARuta: string;
  const ARegistroLog: IRegistroLog): Boolean;
begin
  Result := DirectoryExists(ARuta);
  if Result then
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(SInfoDirectorioExisteComandoImprimirFacturas, [ARuta]));
  end
  else
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(SInfoCrearDirectorioComandoImprimirFacturas, [ARuta]));
    try
      Result := ForceDirectories(ARuta);
    except
      on E: Exception do
        Result := False;
    end;
  end;
  if Result then
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(SInfoDirectorioPreparadoComandoImprimirFacturas, [ARuta]));
  end;
end;

procedure CrearImpresorExportacionFacturas(
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const ARegistroLog: IRegistroLog;
  var ADatosFactura: TdmFacturas;
  var AFormulario: TfrmPrintFac);
begin
  ADatosFactura := TdmFacturas.Create(AOwnerSesion);
  ADatosFactura.ReasignarConexion(AConexion);
  RegistrarInformacionSeguro(
    ARegistroLog,
    SInfoConexionImpresorComandoImprimirFacturas);
  AFormulario := TfrmPrintFac.Create(AOwnerSesion);
  AFormulario.ConfigurarDataModule(ADatosFactura);
  AFormulario.rbActual.Checked := True;
  AFormulario.rbProcesarFiltrados.Checked := False;
  AFormulario.frxpdfxprtPedWeb.EmbeddedFonts := True;
  AFormulario.frxpdfxprtPedWeb.ShowProgress := False;
  RegistrarInformacionSeguro(
    ARegistroLog,
    SInfoFuentesComandoImprimirFacturas);
  RegistrarInformacionSeguro(
    ARegistroLog,
    SInfoModoArchivoComandoImprimirFacturas);
end;

function PrepararFormatoYDestinoExportacion(
  const ASolicitud: TSolicitudComandoImprimirFacturas;
  AFormulario: TfrmPrintFac;
  const ARegistroLog: IRegistroLog): TResultadoComandoImprimirFacturas;
begin
  Result := CrearResultado(0, '');
  RegistrarInformacionSeguro(
    ARegistroLog,
    Format(
      SInfoCargarFormatoComandoImprimirFacturas,
      [ASolicitud.Formato]));
  if not AFormulario.SeleccionarFormatoSinDialogo(ASolicitud.Formato) then
    Result := CrearResultado(
      SALIDA_COMANDO_IMPRESION_FORMATO,
      Format(SErrorFormatoComandoImprimirFacturas, [ASolicitud.Formato]));
  if not Result.EsError then
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(SInfoFormatoCargadoComandoImprimirFacturas, [ASolicitud.Formato]));
    if not PrepararDirectorio(
      ASolicitud.DirectorioDestino, ARegistroLog) then
    begin
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_DIRECTORIO,
        Format(
          SErrorDirectorioComandoImprimirFacturas,
          [ASolicitud.DirectorioDestino]));
    end;
  end;
end;

function PrepararFacturaParaExportar(
  const ASolicitud: TSolicitudComandoImprimirFacturas;
  AIndice: Integer;
  const AContextoAutorizacion: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  AConsultaAutorizacion: TUniQuery;
  ADatosFactura: TdmFacturas;
  AFormulario: TfrmPrintFac;
  ARutasGeneradas: TStringList;
  const ARegistroLog: IRegistroLog;
  out ARutaPdf: string): TResultadoComandoImprimirFacturas;
var
  oDatos: TDatosAutorizacionComandoFactura;
  oRechazo: TRechazoComandoFactura;
  sNombrePdf: string;
begin
  Result := CrearResultado(0, '');
  ARutaPdf := '';
  RegistrarInformacionSeguro(
    ARegistroLog,
    Format(
      SInfoPrepararFacturaComandoImprimirFacturas,
      [AIndice + 1,
       Length(ASolicitud.Referencias),
       ASolicitud.Referencias[AIndice].Texto]));
  oDatos := LeerDatosAutorizacion(
    AConsultaAutorizacion, ASolicitud.Referencias[AIndice]);
  oRechazo := EvaluarAutorizacionComandoFactura(
    oDatos, AContextoAutorizacion);
  if oRechazo <> rcifNinguno then
  begin
    RegistrarAvisoSeguro(
      ARegistroLog,
      'La autorización ha cambiado después de la prevalidación para ' +
      ASolicitud.Referencias[AIndice].Texto + '.');
    Result := CrearErrorAutorizacion(
      oRechazo, ASolicitud.Referencias[AIndice], AUsuario);
  end;
  if not Result.EsError then
  begin
    AFormulario.edtSerie.Text := ASolicitud.Referencias[AIndice].Serie;
    AFormulario.edtNroFac.Text := ASolicitud.Referencias[AIndice].Numero;
    AFormulario.preparar_consulta;
    if not DataSetCorrespondeAReferencia(
      ADatosFactura.unqryFacPrint, ASolicitud.Referencias[AIndice]) then
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_FACTURA,
        Format(
          SErrorPrepararFacturaComando,
          [ASolicitud.Referencias[AIndice].Texto]));
  end;
  if not Result.EsError then
  begin
    oDatos := LeerDatosAutorizacionDataSet(ADatosFactura.unqryFacPrint);
    oRechazo := EvaluarAutorizacionComandoFactura(
      oDatos, AContextoAutorizacion);
    if oRechazo <> rcifNinguno then
    begin
      RegistrarAvisoSeguro(
        ARegistroLog,
        'Los datos de impresión ya no cumplen la autorización para ' +
        ASolicitud.Referencias[AIndice].Texto + '.');
      Result := CrearErrorAutorizacion(
        oRechazo, ASolicitud.Referencias[AIndice], AUsuario);
    end;
  end;
  if not Result.EsError then
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoDatosPreparadosComandoImprimirFacturas,
        [ASolicitud.Referencias[AIndice].Texto]));
    sNombrePdf := AFormulario.ObtenerNombreFactura(
      ADatosFactura.unqryFacPrint) + '.pdf';
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoNombrePdfComandoImprimirFacturas,
        [sNombrePdf, ASolicitud.Referencias[AIndice].Texto]));
    ARutaPdf := TPath.Combine(ASolicitud.DirectorioDestino, sNombrePdf);
    if ARutasGeneradas.IndexOf(ARutaPdf) >= 0 then
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_EXPORTACION,
        Format(SErrorColisionNombrePdfComando, [ARutaPdf]));
  end;
end;

procedure PrepararCorreoPdfExportado(
  const AReferencia: TReferenciaComandoFactura;
  const ARutaPdf: string;
  ADatosFactura: TdmFacturas;
  const ARegistroLog: IRegistroLog;
  var ACorreo: TDatosCorreoFacturaLote);
var
  iTamanoPdf: Int64;
begin
  ACorreo.Email := Trim(
    ADatosFactura.unqryFacPrint.FieldByName('EMAIL_CLIENTE_FAC').AsString);
  ACorreo.EmailRespuesta := Trim(
    ADatosFactura.unqryFacPrint.FieldByName('EMAIL_EMPRESA_FAC').AsString);
  ACorreo.NombreEmpresa := Trim(
    ADatosFactura.unqryFacPrint.FieldByName(
      'RAZON_SOCIAL_EMPRESA_FAC').AsString);
  if ACorreo.Email <> '' then
  begin
    ACorreo.RutaPdf := CrearRutaTemporalPdf(
      TPath.Combine(TPath.GetTempPath, 'correo_factura.pdf'));
    try
      TFile.Copy(ARutaPdf, ACorreo.RutaPdf, False);
      if not EsPdfValido(ACorreo.RutaPdf, iTamanoPdf) then
      begin
        ACorreo.ErrorPreparacion := Format(
          SErrorPrepararCorreoFacturaLote,
          [AReferencia.Texto]);
        EliminarPdfTemporalSeguro(ACorreo.RutaPdf, ARegistroLog);
        ACorreo.RutaPdf := '';
      end;
    except
      on E: Exception do
      begin
        ACorreo.ErrorPreparacion := Format(
          SErrorPrepararCorreoFacturaLote,
          [AReferencia.Texto]) + ' ' + E.ClassName + ': ' + E.Message;
        EliminarPdfTemporalSeguro(ACorreo.RutaPdf, ARegistroLog);
        ACorreo.RutaPdf := '';
      end;
    end;
  end;
end;

function GenerarYPublicarPdfFactura(
  const AReferencia: TReferenciaComandoFactura;
  const ARutaTemporal, ARutaPdf: string;
  AFormulario: TfrmPrintFac;
  ADatosFactura: TdmFacturas;
  ARutasGeneradas: TStringList;
  AEnviarEmail: Boolean;
  const ARegistroLog: IRegistroLog;
  var AContadores: TContadoresExportacionFacturas;
  var APdfGenerado: Boolean;
  var ACorreo: TDatosCorreoFacturaLote): TResultadoComandoImprimirFacturas;
var
  iTamanoPdf: Int64;
  sErrorPublicacion: string;
begin
  Result := CrearResultado(0, '');
  try
    if not AFormulario.ExportarPdfPreparado(ARutaTemporal, False) then
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_EXPORTACION,
        Format(SErrorExportarFacturaComando, [AReferencia.Texto, ARutaPdf]));
    if not Result.EsError and
       not EsPdfValido(ARutaTemporal, iTamanoPdf) then
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_EXPORTACION,
        Format(SErrorExportarFacturaComando, [AReferencia.Texto, ARutaPdf]));
    if not Result.EsError and
       not PublicarPdfTemporal(
         ARutaTemporal, ARutaPdf, sErrorPublicacion) then
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_EXPORTACION,
        Format(
          SErrorPublicarFacturaComando,
          [AReferencia.Texto, ARutaPdf, sErrorPublicacion]));
    if not Result.EsError and not EsPdfValido(ARutaPdf, iTamanoPdf) then
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_EXPORTACION,
        Format(SErrorExportarFacturaComando, [AReferencia.Texto, ARutaPdf]));
    if not Result.EsError then
    begin
      ARutasGeneradas.Add(ARutaPdf);
      Inc(AContadores.Generadas);
      APdfGenerado := True;
      RegistrarInformacionSeguro(
        ARegistroLog,
        Format(
          SInfoPdfFacturaComando,
          [AReferencia.Texto, ARutaPdf, iTamanoPdf]));
      if AEnviarEmail then
        PrepararCorreoPdfExportado(
          AReferencia, ARutaPdf, ADatosFactura, ARegistroLog, ACorreo);
    end;
  except
    on E: Exception do
      Result := CrearResultado(
        SALIDA_COMANDO_IMPRESION_EXPORTACION,
        Format(SErrorExportarFacturaComando, [AReferencia.Texto, ARutaPdf]) +
        ' ' + E.ClassName + ': ' + E.Message);
  end;
end;

function ExportarPdfFacturaPreparada(
  const AReferencia: TReferenciaComandoFactura;
  const ARutaPdf: string;
  AFormulario: TfrmPrintFac;
  ADatosFactura: TdmFacturas;
  ARutasGeneradas: TStringList;
  AEnviarEmail: Boolean;
  const ARegistroLog: IRegistroLog;
  var AContadores: TContadoresExportacionFacturas;
  var APdfGenerado: Boolean;
  var ACorreo: TDatosCorreoFacturaLote): TResultadoComandoImprimirFacturas;
var
  hBloqueoPdf: THandle;
  sErrorBloqueo: string;
  sRutaTemporal: string;
begin
  Result := CrearResultado(0, '');
  if not IntentarBloquearRutaPdf(
    ARutaPdf, hBloqueoPdf, sErrorBloqueo) then
    Result := CrearResultado(
      SALIDA_COMANDO_IMPRESION_EXPORTACION,
      Format(SErrorBloqueoNombrePdfComando, [ARutaPdf, sErrorBloqueo]))
  else
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(SInfoBloqueoPdfComandoImprimirFacturas, [ARutaPdf]));
    try
      if FileExists(ARutaPdf) then
        RegistrarAvisoSeguro(
          ARegistroLog,
          Format(SInfoPdfExistenteComandoImprimirFacturas, [ARutaPdf]));
      RegistrarInformacionSeguro(
        ARegistroLog,
        Format(
          SInfoExportarPdfComandoImprimirFacturas,
          [AReferencia.Texto, ARutaPdf]));
      sRutaTemporal := CrearRutaTemporalPdf(ARutaPdf);
      RegistrarInformacionSeguro(
        ARegistroLog,
        Format(SInfoPdfTemporalComandoImprimirFacturas, [AReferencia.Texto]));
      try
        Result := GenerarYPublicarPdfFactura(
          AReferencia,
          sRutaTemporal,
          ARutaPdf,
          AFormulario,
          ADatosFactura,
          ARutasGeneradas,
          AEnviarEmail,
          ARegistroLog,
          AContadores,
          APdfGenerado,
          ACorreo);
      finally
        EliminarPdfTemporalSeguro(sRutaTemporal, ARegistroLog);
      end;
    finally
      LiberarBloqueoRutaPdf(hBloqueoPdf);
      RegistrarInformacionSeguro(
        ARegistroLog,
        Format(SInfoLiberarBloqueoPdfComandoImprimirFacturas, [ARutaPdf]));
    end;
  end;
end;

function ProcesarFacturaParaExportar(
  const ASolicitud: TSolicitudComandoImprimirFacturas;
  AIndice: Integer;
  const AContextoAutorizacion: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  const AParametrosApp: IParametrosAplicacion;
  AConsultaAutorizacion: TUniQuery;
  ADatosFactura: TdmFacturas;
  AFormulario: TfrmPrintFac;
  ARutasGeneradas: TStringList;
  const ARegistroLog: IRegistroLog;
  AEnviarEmail: Boolean;
  var AContadores: TContadoresExportacionFacturas
): TResultadoComandoImprimirFacturas;
var
  bPdfGenerado: Boolean;
  oCorreo: TDatosCorreoFacturaLote;
  sRutaPdf: string;
begin
  bPdfGenerado := False;
  oCorreo := Default(TDatosCorreoFacturaLote);
  Result := PrepararFacturaParaExportar(
    ASolicitud,
    AIndice,
    AContextoAutorizacion,
    AUsuario,
    AConsultaAutorizacion,
    ADatosFactura,
    AFormulario,
    ARutasGeneradas,
    ARegistroLog,
    sRutaPdf);
  if not Result.EsError then
    Result := ExportarPdfFacturaPreparada(
      ASolicitud.Referencias[AIndice],
      sRutaPdf,
      AFormulario,
      ADatosFactura,
      ARutasGeneradas,
      AEnviarEmail,
      ARegistroLog,
      AContadores,
      bPdfGenerado,
      oCorreo);
  if AEnviarEmail and bPdfGenerado then
  begin
    try
      ProcesarCorreoFactura(
        ASolicitud.Referencias[AIndice],
        oCorreo,
        AParametrosApp,
        ARegistroLog,
        False,
        AContadores.CorreosEnviados,
        AContadores.CorreosSinDestinatario,
        AContadores.CorreosConError,
        AContadores.DetalleCorreo);
    finally
      EliminarPdfTemporalSeguro(oCorreo.RutaPdf, ARegistroLog);
    end;
  end;
end;

procedure AgregarResumenLoteParcial(
  var AResultado: TResultadoComandoImprimirFacturas;
  AGeneradas, ASolicitadas: Integer);
begin
  if AGeneradas > 0 then
    AResultado.Mensaje := AResultado.Mensaje +
      Format(
        SInfoLoteParcialComandoImprimirFacturas,
        [AGeneradas, ASolicitadas]);
end;

function ExportarFacturas(
  const ASolicitud: TSolicitudComandoImprimirFacturas;
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const AContextoAutorizacion: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  AEnviarEmail: Boolean
): TResultadoComandoImprimirFacturas;
var
  iFactura: Integer;
  oConsultaAutorizacion: TUniQuery;
  oContadores: TContadoresExportacionFacturas;
  oDatosFactura: TdmFacturas;
  oFormulario: TfrmPrintFac;
  oRutasGeneradas: TStringList;
begin
  Result := CrearResultado(0, '');
  oContadores := Default(TContadoresExportacionFacturas);
  RegistrarInformacionSeguro(
    ARegistroLog,
    SInfoCrearImpresorComandoImprimirFacturas);
  oDatosFactura := nil;
  oFormulario := nil;
  oConsultaAutorizacion := nil;
  oRutasGeneradas := TStringList.Create;
  try
    try
      oRutasGeneradas.CaseSensitive := False;
      CrearImpresorExportacionFacturas(
        AOwnerSesion,
        AConexion,
        ARegistroLog,
        oDatosFactura,
        oFormulario);
      Result := PrepararFormatoYDestinoExportacion(
        ASolicitud, oFormulario, ARegistroLog);
      if not Result.EsError then
      begin
        oConsultaAutorizacion :=
          CrearConsultaAutorizacionImpresionFacturas(AConexion);
      end;
      iFactura := 0;
      while (iFactura <= High(ASolicitud.Referencias)) and
            not Result.EsError do
      begin
        Result := ProcesarFacturaParaExportar(
          ASolicitud,
          iFactura,
          AContextoAutorizacion,
          AUsuario,
          AParametrosApp,
          oConsultaAutorizacion,
          oDatosFactura,
          oFormulario,
          oRutasGeneradas,
          ARegistroLog,
          AEnviarEmail,
          oContadores);
        Inc(iFactura);
      end;
      if Result.EsError then
        AgregarResumenLoteParcial(
          Result,
          oContadores.Generadas,
          Length(ASolicitud.Referencias));
    except
      on E: Exception do
      begin
        Result := CrearResultado(
          SALIDA_COMANDO_IMPRESION_ERROR,
          Format(
            SErrorInesperadoLotePdfFacturas,
            [E.ClassName, E.Message]));
        AgregarResumenLoteParcial(
          Result,
          oContadores.Generadas,
          Length(ASolicitud.Referencias));
      end;
    end;
  finally
    Result.CorreoSolicitado := AEnviarEmail;
    Result.CorreosEnviados := oContadores.CorreosEnviados;
    Result.CorreosSinDestinatario := oContadores.CorreosSinDestinatario;
    Result.CorreosConError := oContadores.CorreosConError;
    Result.DetalleCorreo := oContadores.DetalleCorreo;
    FreeAndNil(oFormulario);
    FreeAndNil(oConsultaAutorizacion);
    FreeAndNil(oDatosFactura);
    FreeAndNil(oRutasGeneradas);
    RegistrarInformacionSeguro(
      ARegistroLog,
      SInfoCerrarImpresorComandoImprimirFacturas);
  end;
end;

function EjecutarComandoImprimirFacturas(
  const AParametros: TArray<string>;
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  AEnviarEmail: Boolean
): TResultadoComandoImprimirFacturas;
var
  oAutorizacion: TContextoAutorizacionComandoFactura;
  oSolicitud: TSolicitudComandoImprimirFacturas;
  sUsuario: string;
begin
  RegistrarInformacionSeguro(
    ARegistroLog,
    SInfoDetectadoComandoImprimirFacturas);
  oSolicitud := InterpretarComandoImprimirFacturas(AParametros);
  if not oSolicitud.EsValida then
  begin
    Result := CrearResultado(
      CodigoErrorSolicitud(oSolicitud.Error),
      MensajeErrorSolicitud(oSolicitud));
  end
  else if (not Assigned(AOwnerSesion)) or
          (not Assigned(AConexion)) or
          (not Assigned(AContextoSesion)) or
          (not Assigned(AParametrosApp)) then
  begin
    Result := CrearResultado(
      SALIDA_COMANDO_IMPRESION_SESION,
      SErrorServiciosComandoImprimirFacturas);
  end
  else
  begin
    sUsuario := AContextoSesion.Identidad.Usuario;
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoInicioComandoImprimirFacturas,
        [sUsuario,
         AContextoSesion.Identidad.Grupo,
         Length(oSolicitud.Referencias),
         oSolicitud.Formato]));
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoUbicacionComandoImprimirFacturas,
        [TextoAmbito(AContextoSesion.Ubicacion.Empresa),
         TextoAmbito(AContextoSesion.Ubicacion.Almacen),
         TextoAmbito(AContextoSesion.Ubicacion.Caja)]));
    oAutorizacion := CrearContextoAutorizacion(
      AContextoSesion,
      AParametrosApp,
      APermisos);
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoPoliticaComandoImprimirFacturas,
        [TextoSiNo(oAutorizacion.VerifactuOnline),
         TextoSiNo(oAutorizacion.PuedeImprimirNormal),
         TextoSiNo(oAutorizacion.PuedeImprimirSimplificada)]));
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoAmbitoComandoImprimirFacturas,
        [TextoAmbito(oAutorizacion.EmpresaRestringida),
         TextoAmbito(oAutorizacion.AlmacenRestringido),
         TextoAmbito(oAutorizacion.CajaRestringida)]));
    Result := ValidarFacturasSolicitadas(
      AConexion,
      oSolicitud,
      oAutorizacion,
      sUsuario,
      ARegistroLog);
    if not Result.EsError then
    begin
      Result := ExportarFacturas(
        oSolicitud,
        AOwnerSesion,
        AConexion,
        oAutorizacion,
        sUsuario,
        AParametrosApp,
        ARegistroLog,
        AEnviarEmail);
    end;
    if not Result.EsError then
    begin
      Result.CodigoSalida := 0;
      Result.EsError := False;
      Result.Mensaje := Format(
        SInfoFinComandoImprimirFacturas,
        [Length(oSolicitud.Referencias),
         oSolicitud.DirectorioDestino,
         sUsuario]);
    end;
  end;
  Result.CorreoSolicitado := AEnviarEmail;
end;

function ReservarInicioLoteImpresionFacturas(
  out AError: string): Boolean;
var
  oHiloFinalizado: TThread;
begin
  Result := False;
  AError := '';
  oHiloFinalizado := nil;
  GBloqueoLoteImpresionFacturas.Acquire;
  try
    if Assigned(GHiloLoteImpresionFacturas) and
       (WaitForSingleObject(
          GHiloLoteImpresionFacturas.Handle, 0) = WAIT_OBJECT_0) then
    begin
      oHiloFinalizado := GHiloLoteImpresionFacturas;
      GHiloLoteImpresionFacturas := nil;
    end;
    if GCierreLoteImpresionFacturas then
      AError := SErrorLoteImpresionFacturasCerrando
    else if GInicioLoteImpresionFacturasEnCurso or
            Assigned(GHiloLoteImpresionFacturas) then
      AError := SErrorLoteImpresionFacturasEnCurso
    else
    begin
      GInicioLoteImpresionFacturasEnCurso := True;
      Result := True;
    end;
  finally
    GBloqueoLoteImpresionFacturas.Release;
  end;
  FreeAndNil(oHiloFinalizado);
end;

procedure LiberarReservaInicioLoteImpresionFacturas;
begin
  GBloqueoLoteImpresionFacturas.Acquire;
  try
    GInicioLoteImpresionFacturasEnCurso := False;
  finally
    GBloqueoLoteImpresionFacturas.Release;
  end;
end;

procedure PublicarEIniciarHiloLoteImpresionFacturas(AHilo: TThread);
begin
  GBloqueoLoteImpresionFacturas.Acquire;
  try
    GHiloLoteImpresionFacturas := AHilo;
    if GCierreLoteImpresionFacturas then
      AHilo.Terminate;
    try
      AHilo.Start;
    except
      GHiloLoteImpresionFacturas := nil;
      raise;
    end;
    GInicioLoteImpresionFacturasEnCurso := False;
  finally
    GBloqueoLoteImpresionFacturas.Release;
  end;
end;

procedure DetenerLoteImpresionFacturasAlCerrar;
var
  bInicioEnCurso: Boolean;
  iEspera: Cardinal;
  oHilo: TThread;
begin
  oHilo := nil;
  repeat
    GBloqueoLoteImpresionFacturas.Acquire;
    try
      GCierreLoteImpresionFacturas := True;
      bInicioEnCurso := GInicioLoteImpresionFacturasEnCurso;
      if not bInicioEnCurso then
      begin
        oHilo := GHiloLoteImpresionFacturas;
        GHiloLoteImpresionFacturas := nil;
        if Assigned(oHilo) then
          oHilo.Terminate;
      end;
    finally
      GBloqueoLoteImpresionFacturas.Release;
    end;
    if bInicioEnCurso then
    begin
      // No se bombea la cola de mensajes VCL durante el cierre. Solo se
      // atienden los Synchronize que el trabajador necesita para terminar.
      CheckSynchronize(0);
      Sleep(1);
    end;
  until not bInicioEnCurso;

  if Assigned(oHilo) then
  begin
    repeat
      iEspera := WaitForSingleObject(oHilo.Handle, 10);
      if iEspera = WAIT_TIMEOUT then
        CheckSynchronize(0);
    until iEspera <> WAIT_TIMEOUT;
    oHilo.WaitFor;
    FreeAndNil(oHilo);
  end;
end;

constructor TTrabajoLoteImpresionFacturas.Create(
  const AReferencias: TReferenciasComandoFactura;
  const AFormato, AImpresora: string;
  AOwnerSesion: TComponent;
  AConexionPrincipal: TUniConnection;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AAutorizacion: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  AEnviarEmail: Boolean;
  const AAlFinalizar: TFinalizarLoteImpresionFacturas;
  const AResultadoInicial: TResultadoLoteImpresionFacturas);
begin
  inherited Create;
  FReferencias := AReferencias;
  FFormato := AFormato;
  FImpresora := AImpresora;
  FOwnerSesion := AOwnerSesion;
  FConexionPrincipal := AConexionPrincipal;
  FConexiones := AConexiones;
  FContextoSesion := AContextoSesion;
  FParametrosApp := AParametrosApp;
  FRegistroLog := ARegistroLog;
  FAutorizacion := AAutorizacion;
  FUsuario := AUsuario;
  FEnviarEmail := AEnviarEmail;
  FAlFinalizar := AAlFinalizar;
  FResultado := AResultadoInicial;
end;

function TTrabajoLoteImpresionFacturas.DebeDetener(
  AHilo: TThread): Boolean;
begin
  Result := HiloLoteTerminado(AHilo) or
            FContextoSesion.CerrandoAplicacion or
            Application.Terminated;
end;

function TTrabajoLoteImpresionFacturas.ProcesarFactura(
  AHilo: TThread;
  const AReferencia: TReferenciaComandoFactura): Boolean;
var
  oCorreo: TDatosCorreoFacturaLote;
  oEstado: TEstadoFacturaImpresionLote;
  sError: string;
begin
  Result := False;
  oCorreo := Default(TDatosCorreoFacturaLote);
  oEstado := efilError;
  sError := '';
  try
    TThread.Synchronize(nil,
      procedure
      begin
        if not DebeDetener(AHilo) then
          oEstado := ImprimirFacturaConsolidada(
            AReferencia,
            FFormato,
            FImpresora,
            FEnviarEmail,
            FOwnerSesion,
            FConexionPrincipal,
            FAutorizacion,
            FUsuario,
            FRegistroLog,
            oCorreo,
            sError);
      end);
    if not DebeDetener(AHilo) then
    begin
      case oEstado of
        efilImpresa:
          begin
            Inc(FResultado.Impresas);
            if FEnviarEmail then
              ProcesarCorreoFactura(
                AReferencia,
                oCorreo,
                FParametrosApp,
                FRegistroLog,
                True,
                FResultado.CorreosEnviados,
                FResultado.CorreosSinDestinatario,
                FResultado.CorreosConError,
                FResultado.DetalleCorreo);
          end;
        efilOmitidaNoConsolidada:
          Inc(FResultado.OmitidasNoConsolidadas);
        efilError:
          FResultado.Error := sError;
      end;
      Result := oEstado <> efilError;
    end;
  finally
    EliminarPdfTemporalSeguro(oCorreo.RutaPdf, FRegistroLog);
  end;
end;

procedure TTrabajoLoteImpresionFacturas.ProcesarFacturas(
  AHilo: TThread;
  const AReferencias: TReferenciasComandoFactura);
var
  iFactura: Integer;
begin
  for iFactura := 0 to High(AReferencias) do
  begin
    if DebeDetener(AHilo) then
      Break;
    if not ProcesarFactura(AHilo, AReferencias[iFactura]) or
       DebeDetener(AHilo) then
      Break;
  end;
end;

procedure TTrabajoLoteImpresionFacturas.NotificarResultado;
var
  oAlFinalizar: TFinalizarLoteImpresionFacturas;
  oContextoSesion: IContextoSesionAplicacion;
  oResultado: TResultadoLoteImpresionFacturas;
begin
  if FResultado.Error <> '' then
    RegistrarErrorSeguro(FRegistroLog, FResultado.Error)
  else
    RegistrarInformacionSeguro(
      FRegistroLog,
      Format(
        SInfoFinLoteImpresionFacturas,
        [FResultado.Solicitadas,
         FResultado.Impresas,
         FResultado.OmitidasNoConsolidadas]));
  if Assigned(FAlFinalizar) then
  begin
    oAlFinalizar := FAlFinalizar;
    oContextoSesion := FContextoSesion;
    oResultado := FResultado;
    TThread.Queue(nil,
      procedure
      begin
        if not oContextoSesion.CerrandoAplicacion and
           not Application.Terminated then
          oAlFinalizar(oResultado);
      end);
  end;
end;

procedure TTrabajoLoteImpresionFacturas.Ejecutar(AHilo: TThread);
var
  bPrevalidado: Boolean;
  oConexionFondo: TUniConnection;
  oConsolidadas: TReferenciasComandoFactura;
begin
  oConexionFondo := nil;
  try
    try
      if not HiloLoteTerminado(AHilo) and
         not FContextoSesion.CerrandoAplicacion then
      begin
        oConexionFondo := FConexiones.CrearConexion(nil, uctSegundoPlano);
        bPrevalidado := PrevalidarLoteImpresionFacturas(
          oConexionFondo,
          FReferencias,
          FAutorizacion,
          FUsuario,
          FRegistroLog,
          AHilo,
          oConsolidadas,
          FResultado.OmitidasNoConsolidadas,
          FResultado.Error);
        // La conexión secundaria solo sirve para la prevalidación. Se libera
        // antes de comenzar a esperar al spooler documento a documento.
        FreeAndNil(oConexionFondo);
        if bPrevalidado and not HiloLoteTerminado(AHilo) then
          ProcesarFacturas(AHilo, oConsolidadas);
      end;
    except
      on E: Exception do
        FResultado.Error := E.ClassName + ': ' + E.Message;
    end;
  finally
    FreeAndNil(oConexionFondo);
  end;
  if not DebeDetener(AHilo) then
    NotificarResultado;
end;

function CrearHiloLoteImpresionFacturas(
  const AReferencias: TReferenciasComandoFactura;
  const AFormato, AImpresora: string;
  AOwnerSesion: TComponent;
  AConexionPrincipal: TUniConnection;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const AAutorizacion: TContextoAutorizacionComandoFactura;
  const AUsuario: string;
  AEnviarEmail: Boolean;
  const AAlFinalizar: TFinalizarLoteImpresionFacturas;
  const AResultadoInicial: TResultadoLoteImpresionFacturas): TThread;
var
  oHilo: TThread;
  oTrabajo: ITrabajoLoteImpresionFacturas;
begin
  oTrabajo := TTrabajoLoteImpresionFacturas.Create(
    AReferencias,
    AFormato,
    AImpresora,
    AOwnerSesion,
    AConexionPrincipal,
    AConexiones,
    AContextoSesion,
    AParametrosApp,
    ARegistroLog,
    AAutorizacion,
    AUsuario,
    AEnviarEmail,
    AAlFinalizar,
    AResultadoInicial);
  oHilo := nil;
  oHilo := TThread.CreateAnonymousThread(
    procedure
    begin
      oTrabajo.Ejecutar(oHilo);
    end);
  Result := oHilo;
end;

procedure FinalizarLoteImpresionFacturasSinHilo(
  const AError: string;
  const ARegistroLog: IRegistroLog;
  const AAlFinalizar: TFinalizarLoteImpresionFacturas;
  var AResultado: TResultadoLoteImpresionFacturas);
begin
  AResultado.Error := AError;
  RegistrarErrorSeguro(ARegistroLog, AError);
  if Assigned(AAlFinalizar) then
    AAlFinalizar(AResultado);
end;

function ServiciosLoteImpresionDisponibles(
  AOwnerSesion: TComponent;
  AConexionPrincipal: TUniConnection;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := (AOwnerSesion <> nil) and
            (AConexionPrincipal <> nil) and
            AConexionPrincipal.Connected and
            Assigned(AConexiones) and
            Assigned(AContextoSesion) and
            Assigned(AParametrosApp);
end;

procedure IniciarLoteImpresionFacturas(
  const AReferencias: TReferenciasComandoFactura;
  const AFormato, AImpresoraConfigurada: string;
  AOwnerSesion: TComponent;
  AConexionPrincipal: TUniConnection;
  const AConexiones: IServicioConexiones;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog;
  AEnviarEmail: Boolean;
  const AAlFinalizar: TFinalizarLoteImpresionFacturas);
var
  bInicioReservado: Boolean;
  oAutorizacion: TContextoAutorizacionComandoFactura;
  oHilo: TThread;
  oReferencias: TReferenciasComandoFactura;
  oResultado: TResultadoLoteImpresionFacturas;
  sImpresora: string;
  sUsuario: string;
begin
  oResultado := Default(TResultadoLoteImpresionFacturas);
  oResultado.Solicitadas := Length(AReferencias);
  oResultado.CorreoSolicitado := AEnviarEmail;
  oHilo := nil;
  bInicioReservado := ReservarInicioLoteImpresionFacturas(oResultado.Error);
  if not bInicioReservado then
    FinalizarLoteImpresionFacturasSinHilo(
      oResultado.Error, ARegistroLog, AAlFinalizar, oResultado)
  else
  begin
    try
      if Length(AReferencias) = 0 then
        FinalizarLoteImpresionFacturasSinHilo(
          Format(SErrorListaComandoImprimirFacturas, ['lista vacía']),
          ARegistroLog,
          AAlFinalizar,
          oResultado)
      else if not ServiciosLoteImpresionDisponibles(
        AOwnerSesion,
        AConexionPrincipal,
        AConexiones,
        AContextoSesion,
        AParametrosApp) then
        FinalizarLoteImpresionFacturasSinHilo(
          SErrorServiciosComandoImprimirFacturas,
          ARegistroLog,
          AAlFinalizar,
          oResultado)
      else if not ResolverImpresoraLote(
        AImpresoraConfigurada, sImpresora, oResultado.Error) then
        FinalizarLoteImpresionFacturasSinHilo(
          oResultado.Error, ARegistroLog, AAlFinalizar, oResultado)
      else
      begin
        oReferencias := System.Copy(AReferencias, 0, Length(AReferencias));
        sUsuario := AContextoSesion.Identidad.Usuario;
        oAutorizacion := CrearContextoAutorizacion(
          AContextoSesion, AParametrosApp, APermisos);
        // El lote físico omite siempre los borradores. El resto de la
        // autorización se comprueba antes del lote y antes de cada impresión.
        oAutorizacion.VerifactuOnline := False;
        RegistrarInformacionSeguro(
          ARegistroLog,
          Format(SInfoInicioLoteImpresionFacturas, [Length(oReferencias)]));
        try
          oHilo := CrearHiloLoteImpresionFacturas(
            oReferencias,
            AFormato,
            sImpresora,
            AOwnerSesion,
            AConexionPrincipal,
            AConexiones,
            AContextoSesion,
            AParametrosApp,
            ARegistroLog,
            oAutorizacion,
            sUsuario,
            AEnviarEmail,
            AAlFinalizar,
            oResultado);
          oHilo.FreeOnTerminate := False;
          PublicarEIniciarHiloLoteImpresionFacturas(oHilo);
          bInicioReservado := False;
        except
          on E: Exception do
          begin
            if bInicioReservado then
              FreeAndNil(oHilo);
            FinalizarLoteImpresionFacturasSinHilo(
              Format(SErrorIniciarLoteImpresionFacturas, [E.Message]),
              ARegistroLog,
              AAlFinalizar,
              oResultado);
          end;
        end;
      end;
    finally
      if bInicioReservado then
        LiberarReservaInicioLoteImpresionFacturas;
    end;
  end;
end;

procedure RegistrarResultadoComando(
  const AResultado: TResultadoComandoImprimirFacturas;
  const ARegistroLog: IRegistroLog);
begin
  if AResultado.EsError then
    RegistrarErrorSeguro(ARegistroLog, AResultado.Mensaje)
  else
    RegistrarInformacionSeguro(ARegistroLog, AResultado.Mensaje);
  EscribirMensajeComando(
    AResultado.Mensaje,
    AResultado.EsError);
end;

function ValidarSintaxisProcesoComandoImprimirFacturas(
  const ARegistroLog: IRegistroLog): Cardinal;
var
  oResultado: TResultadoComandoImprimirFacturas;
  oSolicitud: TSolicitudComandoImprimirFacturas;
begin
  Result := 0;
  RegistrarInformacionSeguro(
    ARegistroLog,
    SInfoDetectadoComandoImprimirFacturas);
  oSolicitud := InterpretarComandoImprimirFacturas(
    ObtenerParametrosLineaComandos);
  if not oSolicitud.EsValida then
  begin
    oResultado := CrearResultado(
      CodigoErrorSolicitud(oSolicitud.Error),
      MensajeErrorSolicitud(oSolicitud));
    RegistrarResultadoComando(oResultado, ARegistroLog);
    Result := oResultado.CodigoSalida;
  end
  else
  begin
    RegistrarInformacionSeguro(
      ARegistroLog,
      Format(
        SInfoSintaxisValidaComandoImprimirFacturas,
        [Length(oSolicitud.Referencias),
         oSolicitud.Formato,
         oSolicitud.DirectorioDestino]));
    RegistrarInformacionSeguro(
      ARegistroLog,
      SInfoSolicitudSesionComandoImprimirFacturas);
  end;
end;

function EjecutarProcesoComandoImprimirFacturas(
  AOwnerSesion: TComponent;
  AConexion: TUniConnection;
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const APermisos: IPermisosAplicacion;
  const ARegistroLog: IRegistroLog
): Cardinal;
var
  oResultado: TResultadoComandoImprimirFacturas;
begin
  try
    oResultado := EjecutarComandoImprimirFacturas(
      ObtenerParametrosLineaComandos,
      AOwnerSesion,
      AConexion,
      AContextoSesion,
      AParametrosApp,
      APermisos,
      ARegistroLog);
  except
    on E: Exception do
    begin
      oResultado := CrearResultado(
        SALIDA_COMANDO_IMPRESION_ERROR,
        E.ClassName + ': ' + E.Message);
    end;
  end;
  RegistrarResultadoComando(oResultado, ARegistroLog);
  Result := oResultado.CodigoSalida;
end;

function FinalizarProcesoComandoImprimirFacturasSinSesion(
  const ARegistroLog: IRegistroLog): Cardinal;
var
  oResultado: TResultadoComandoImprimirFacturas;
begin
  oResultado := CrearResultado(
    SALIDA_COMANDO_IMPRESION_SESION,
    SErrorSesionComandoImprimirFacturas);
  RegistrarResultadoComando(oResultado, ARegistroLog);
  Result := oResultado.CodigoSalida;
end;

function FinalizarProcesoComandoImprimirFacturasConError(
  const ARegistroLog: IRegistroLog;
  const AMensaje: string): Cardinal;
var
  oResultado: TResultadoComandoImprimirFacturas;
begin
  oResultado := CrearResultado(
    SALIDA_COMANDO_IMPRESION_ERROR,
    AMensaje);
  RegistrarResultadoComando(oResultado, ARegistroLog);
  Result := oResultado.CodigoSalida;
end;

initialization
  GBloqueoLoteImpresionFacturas := TCriticalSection.Create;

finalization
  DetenerLoteImpresionFacturasAlCerrar;
  FreeAndNil(GBloqueoLoteImpresionFacturas);

end.
