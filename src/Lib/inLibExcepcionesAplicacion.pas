{******************************************************************************}
{                                                                              }
{  Módulo:       inLibExcepcionesAplicacion                                    }
{    Tipo:       Servicio                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Registra, presenta y permite enviar las excepciones de la aplicación.     }
{******************************************************************************}
unit inLibExcepcionesAplicacion;

interface

uses
  inLibContextoSesionIntf,
  inLibExcepcionesAplicacionIntf,
  inLibLogIntf;

function CrearGestorExcepcionesAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog;
  const APresentacion: IPresentacionExcepcionesAplicacion
): IGestorExcepcionesAplicacion;

implementation

uses
  inLibMensajesVcl,
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.UITypes,
  Vcl.Clipbrd,
  Vcl.Controls,
  Vcl.Dialogs,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.StdCtrls,
  cxButtons,
  cxCheckBox,
  cxLabel,
  cxMemo,
  cxTextEdit,
  inLibEnvioErroresIntf,
  inLibGlobalVar,
  inLibMsgComun,
  inLibWin;

type
  TGestorExcepcionesAplicacion = class(
    TInterfacedObject,
    IGestorExcepcionesAplicacion)
  private
    FContextoSesion: IContextoSesionAplicacion;
    FEvidencia: TEvidenciaError;
    FEstadoVista: TEstadoVistaErrorAplicacion;
    FGestionandoExcepcion: Boolean;
    FPresentacion: IPresentacionExcepcionesAplicacion;
    FRegistroLog: IRegistroLog;
    FSalidaAplicacionSolicitada: Boolean;
    FServicioEnvioErrores: IServicioEnvioErrores;
    FVista: IVistaErrorAplicacion;
    function ConstruirDetalle(Sender: TObject;
      E: Exception): string;
    procedure AplicarEstadoVista;
    procedure ActivarLogClick(Sender: TObject);
    procedure ActualizarEstadoLog;
    procedure ConfigurarDialogo;
    procedure CopiaSeguridadCambio(Sender: TObject);
    procedure CopiarDetalleClick(Sender: TObject);
    procedure EnviarDesarrolladorClick(Sender: TObject);
    procedure GestionarFueraHiloPrincipal(Sender: TObject;
      E: Exception);
    procedure MostrarDetalle(const ATexto: string);
    procedure MostrarFallback(E: Exception);
    procedure PrepararEvidencia(const AClase, AMensaje,
      ADetalle: string);
    function PrepararCopiaSeguridad: Boolean;
    function PreguntarActivacionLog: Boolean;
    procedure RegistrarDetalleSeguro(E: Exception;
      const ADetalle: string);
    procedure RegistrarRuidoSeguro(E: Exception);
    procedure RegistrarValidacionSegura(Sender: TObject;
      E: Exception);
    procedure MostrarValidacion(E: Exception);
    procedure SalirAplicacionClick(Sender: TObject);
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      const ARegistroLog: IRegistroLog;
      const APresentacion: IPresentacionExcepcionesAplicacion);
    procedure Gestionar(Sender: TObject; E: Exception);
    procedure AsignarServicioEnvioErrores(
      const AServicio: IServicioEnvioErrores);
  end;

function CrearGestorExcepcionesAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog;
  const APresentacion: IPresentacionExcepcionesAplicacion
): IGestorExcepcionesAplicacion;
begin
  Result := TGestorExcepcionesAplicacion.Create(
    AContextoSesion,
    ARegistroLog,
    APresentacion);
end;

constructor TGestorExcepcionesAplicacion.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  const ARegistroLog: IRegistroLog;
  const APresentacion: IPresentacionExcepcionesAplicacion);
begin
  inherited Create;
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create('AContextoSesion');
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  if not Assigned(APresentacion) then
    raise EArgumentNilException.Create('APresentacion');
  FContextoSesion := AContextoSesion;
  FPresentacion := APresentacion;
  FRegistroLog := ARegistroLog;
end;

procedure TGestorExcepcionesAplicacion.AsignarServicioEnvioErrores(
  const AServicio: IServicioEnvioErrores);
begin
  FServicioEnvioErrores := AServicio;
end;

function TGestorExcepcionesAplicacion.ConstruirDetalle(
  Sender: TObject;
  E: Exception): string;
begin
  Result := ConstruirDetalleExcepcionAplicacion(
    Sender,
    E,
    FContextoSesion.Identidad,
    FContextoSesion.Ubicacion,
    oAppName,
    oVersion,
    GetComputerName,
    Now,
    ExceptAddr);
end;

procedure TGestorExcepcionesAplicacion.RegistrarRuidoSeguro(
  E: Exception);
begin
  try
    FRegistroLog.RegistrarAviso(
      'AppException ignorado (editor inplace sin Parent): ' +
      E.Message);
  except
    on EFalloLog: Exception do
      OutputDebugString(PChar(
        'ViraCash: fallo al registrar AppException: ' +
        EFalloLog.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.RegistrarValidacionSegura(
  Sender: TObject;
  E: Exception);
var
  sSender: string;
begin
  sSender := '(nil)';
  if Assigned(Sender) then
    sSender := Sender.ClassName;
  try
    FRegistroLog.RegistrarAviso(
      'Validación de entrada ' + E.ClassName +
      ' [' + sSender + ']: ' + E.Message);
  except
    on EFalloLog: Exception do
      OutputDebugString(PChar(
        'ViraCash: fallo al registrar validación: ' +
        EFalloLog.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.RegistrarDetalleSeguro(
  E: Exception;
  const ADetalle: string);
begin
  try
    FRegistroLog.RegistrarError(
      'AppException ' + E.ClassName + ': ' + E.Message);
    FRegistroLog.RegistrarError(
      'AppException detalle:' + sLineBreak + ADetalle);
  except
    on EFalloLog: Exception do
      OutputDebugString(PChar(
        'ViraCash: fallo al registrar AppException: ' +
        EFalloLog.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.PrepararEvidencia(
  const AClase, AMensaje, ADetalle: string);
begin
  FEvidencia := Default(TEvidenciaError);
  if Assigned(FServicioEnvioErrores) then
  begin
    FEvidencia := FServicioEnvioErrores.Preparar(
      AClase,
      AMensaje,
      ADetalle);
  end;
end;

// Un componente de datos que trabaja en un hilo (TUniScript sin OnError,
// por ejemplo) llama a Application.HandleException desde ese hilo. Crear
// allí la ventana de error interbloquea la VCL con el hilo principal y
// cuelga el programa: se registra aquí y se muestra en el principal.
procedure TGestorExcepcionesAplicacion.GestionarFueraHiloPrincipal(
  Sender: TObject;
  E: Exception);
var
  sClase: string;
  sDetalle: string;
  sMensaje: string;
begin
  try
    sClase := E.ClassName;
    sMensaje := E.Message;
    sDetalle := ConstruirDetalle(Sender, E);
    RegistrarDetalleSeguro(E, sDetalle);
    TThread.Queue(
      nil,
      procedure
      begin
        if not FSalidaAplicacionSolicitada and
           not FGestionandoExcepcion then
        begin
          FGestionandoExcepcion := True;
          try
          try
            PrepararEvidencia(sClase, sMensaje, sDetalle);
            MostrarDetalle(sDetalle);
          except
            on EFalloUI: Exception do
              OutputDebugString(PChar(
                'ViraCash: fallo al mostrar AppException: ' +
                EFalloUI.Message));
          end;
          finally
            FGestionandoExcepcion := False;
          end;
        end;
      end);
  except
    on EFallo: Exception do
      OutputDebugString(PChar(
        'ViraCash: fallo al gestionar AppException de un hilo: ' +
        EFallo.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.Gestionar(
  Sender: TObject;
  E: Exception);
var
  sDetalle: string;
begin
  if not FSalidaAplicacionSolicitada then
  begin
    if TThread.CurrentThread.ThreadID <> MainThreadID then
      GestionarFueraHiloPrincipal(Sender, E)
    else if FGestionandoExcepcion then
      // ShowModal procesa mensajes: un fallo de repintado no debe abrir
      // otro dialogo ni sustituir FVista/FEvidencia del error original.
      RegistrarDetalleSeguro(E, ConstruirDetalle(Sender, E))
    else
    begin
    FGestionandoExcepcion := True;
    try
    if EsValidacionAplicacionEsperada(E) then
    begin
      RegistrarValidacionSegura(Sender, E);
      MostrarValidacion(E);
    end
    else if EsRuidoEditorInplace(E) then
      RegistrarRuidoSeguro(E)
    else
    begin
      try
        sDetalle := ConstruirDetalle(Sender, E);
        RegistrarDetalleSeguro(E, sDetalle);
        PrepararEvidencia(E.ClassName, E.Message, sDetalle);
        MostrarDetalle(sDetalle);
      except
        if not FSalidaAplicacionSolicitada then
          MostrarFallback(E);
      end;
    end;
    finally
      FGestionandoExcepcion := False;
    end;
    end;
  end;
end;

procedure TGestorExcepcionesAplicacion.MostrarValidacion(
  E: Exception);
begin
  try
    MessageDlg_fza(
      E.Message,
      mtWarning,
      [mbOk],
      0);
  except
    on EFalloUI: Exception do
      OutputDebugString(PChar(
        'ViraCash: fallo al mostrar validación: ' +
        EFalloUI.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.MostrarFallback(E: Exception);
begin
  try
    Application.ShowException(E);
  except
    on EFalloUI: Exception do
      OutputDebugString(PChar(
        'ViraCash: fallo al mostrar AppException: ' +
        EFalloUI.Message));
  end;
end;

procedure TGestorExcepcionesAplicacion.ConfigurarDialogo;
var
  Acciones: TAccionesVistaErrorAplicacion;
  Configuracion: TConfiguracionVistaErrorAplicacion;
begin
  Acciones := Default(TAccionesVistaErrorAplicacion);
  Acciones.ActivarLog :=
    procedure
    begin
      ActivarLogClick(nil);
    end;
  Acciones.CambiarCopiaSeguridad :=
    procedure
    begin
      CopiaSeguridadCambio(nil);
    end;
  Acciones.CopiarDetalle :=
    procedure
    begin
      CopiarDetalleClick(nil);
    end;
  Acciones.EnviarError :=
    procedure
    begin
      EnviarDesarrolladorClick(nil);
    end;
  Acciones.SalirAplicacion :=
    procedure
    begin
      SalirAplicacionClick(nil);
    end;
  Configuracion := Default(TConfiguracionVistaErrorAplicacion);
  Configuracion.Titulo := STituloErrorProducido;
  Configuracion.EtiquetaEmail := SCaptionEmailContactoError;
  Configuracion.EtiquetaTelefono := SCaptionTelefonoContactoError;
  Configuracion.EtiquetaDescripcion := SCaptionDescripcionError;
  Configuracion.TextoCerrar := SCaptionCerrar;
  Configuracion.TextoSalirAplicacion := SCaptionSalirAplicacion;
  Configuracion.TextoCopiar := SCaptionCopiarPortapapeles;
  Configuracion.TextoEnviar := SCaptionEnviarDesarrollador;
  Configuracion.TextoActivarLog := SCaptionActivarLogCompleto;
  Configuracion.TextoEnviarCopia := SCaptionEnviarCopiaSeguridadError;
  Configuracion.PuedeEnviar := Assigned(FServicioEnvioErrores);
  Configuracion.Acciones := Acciones;
  FVista.Configurar(Configuracion);
  FEstadoVista := Default(TEstadoVistaErrorAplicacion);
  FEstadoVista.Evidencias := SCaptionDetalleErrorCabecera + ' ' +
    SInfoEvidenciasError;
  FEstadoVista.PuedeEnviar := Assigned(FServicioEnvioErrores);
  FEstadoVista.ActivarLogVisible :=
    Assigned(FServicioEnvioErrores) and
    not FEvidencia.Log.Completo;
  FEstadoVista.ActivarLogHabilitado := True;
  ActualizarEstadoLog;
  AplicarEstadoVista;
end;

procedure TGestorExcepcionesAplicacion.SalirAplicacionClick(
  Sender: TObject);
begin
  FSalidaAplicacionSolicitada := True;
  Application.Terminate;
end;

procedure ConfigurarEtiqueta(
  AEtiqueta: TcxLabel;
  AParent: TWinControl;
  ALeft, ATop, AWidth, AHeight: Integer;
  const ACaption: string);
begin
  AEtiqueta.Parent := AParent;
  AEtiqueta.Left := ALeft;
  AEtiqueta.Top := ATop;
  AEtiqueta.Width := AWidth;
  AEtiqueta.Height := AHeight;
  AEtiqueta.AutoSize := False;
  AEtiqueta.Properties.WordWrap := True;
  AEtiqueta.Caption := ACaption;
end;

function SolicitarContrasenaCopia(
  AOwner: TCustomForm;
  out AContrasena: string): Boolean;
var
  BotonAceptar: TcxButton;
  BotonCancelar: TcxButton;
  Dialogo: TForm;
  EdtConfirmacion: TcxTextEdit;
  EdtContrasena: TcxTextEdit;
  LabelConfirmacion: TcxLabel;
  LabelContrasena: TcxLabel;
  LabelExplicacion: TcxLabel;
  bTerminar: Boolean;
  iResultado: Integer;
begin
  Result := False;
  AContrasena := '';
  Dialogo := TForm.Create(AOwner);
  try
    Dialogo.Caption := STituloContrasenaCopiaError;
    Dialogo.Position := poScreenCenter;
    Dialogo.BorderIcons := [];
    Dialogo.BorderStyle := bsDialog;
    Dialogo.ClientWidth := 520;
    Dialogo.ClientHeight := 224;
    LabelExplicacion := TcxLabel.Create(Dialogo);
    ConfigurarEtiqueta(
      LabelExplicacion,
      Dialogo,
      24,
      16,
      472,
      48,
      SInfoContrasenaCopiaError);
    LabelContrasena := TcxLabel.Create(Dialogo);
    ConfigurarEtiqueta(
      LabelContrasena,
      Dialogo,
      24,
      77,
      144,
      24,
      SCaptionContrasenaCopiaError);
    EdtContrasena := TcxTextEdit.Create(Dialogo);
    EdtContrasena.Parent := Dialogo;
    EdtContrasena.SetBounds(176, 75, 320, 26);
    EdtContrasena.Properties.EchoMode := eemPassword;
    EdtContrasena.Properties.PasswordChar := #9679;
    LabelConfirmacion := TcxLabel.Create(Dialogo);
    ConfigurarEtiqueta(
      LabelConfirmacion,
      Dialogo,
      24,
      117,
      144,
      24,
      SCaptionRepetirContrasenaCopiaError);
    EdtConfirmacion := TcxTextEdit.Create(Dialogo);
    EdtConfirmacion.Parent := Dialogo;
    EdtConfirmacion.SetBounds(176, 115, 320, 26);
    EdtConfirmacion.Properties.EchoMode := eemPassword;
    EdtConfirmacion.Properties.PasswordChar := #9679;
    BotonCancelar := TcxButton.Create(Dialogo);
    BotonCancelar.Parent := Dialogo;
    BotonCancelar.SetBounds(152, 171, 160, 32);
    BotonCancelar.Caption := SCaptionCancelar;
    BotonCancelar.Cancel := True;
    BotonCancelar.ModalResult := mrCancel;
    BotonAceptar := TcxButton.Create(Dialogo);
    BotonAceptar.Parent := Dialogo;
    BotonAceptar.SetBounds(328, 171, 168, 32);
    BotonAceptar.Caption := SCaptionAceptar;
    BotonAceptar.Default := True;
    BotonAceptar.ModalResult := mrOk;
    Dialogo.ActiveControl := EdtContrasena;
    bTerminar := False;
    while not bTerminar do
    begin
      iResultado := Dialogo.ShowModal;
      if iResultado <> mrOk then
        bTerminar := True
      else if Trim(EdtContrasena.Text) = '' then
      begin
        MessageDlg_fza(
          SErrorContrasenaCopiaErrorVacia,
          mtWarning,
          [mbOk],
          0);
        EdtContrasena.SetFocus;
      end
      else if EdtContrasena.Text <> EdtConfirmacion.Text then
      begin
        MessageDlg_fza(
          SErrorContrasenasCopiaErrorNoCoinciden,
          mtWarning,
          [mbOk],
          0);
        EdtConfirmacion.SetFocus;
      end
      else
      begin
        AContrasena := EdtContrasena.Text;
        Result := True;
        bTerminar := True;
      end;
    end;
    EdtContrasena.Text := '';
    EdtConfirmacion.Text := '';
  finally
    FreeAndNil(Dialogo);
  end;
end;

procedure TGestorExcepcionesAplicacion.CopiaSeguridadCambio(
  Sender: TObject);
begin
  if FVista.EnviarCopiaSeguridad then
  begin
    FEstadoVista.Evidencias := SInfoEvidenciasCopiaError;
    FEstadoVista.EstadoLog := SInfoCopiaSeguridadError;
    FEstadoVista.NivelEstado := nevaInformacion;
    FEstadoVista.ActivarLogVisible := False;
  end
  else
  begin
    if Assigned(FServicioEnvioErrores) then
      FServicioEnvioErrores.DescartarCopiaSeguridad(FEvidencia);
    FEstadoVista.Evidencias := SCaptionDetalleErrorCabecera + ' ' +
      SInfoEvidenciasError;
    ActualizarEstadoLog;
    FEstadoVista.ActivarLogVisible :=
      Assigned(FServicioEnvioErrores) and
      not FEvidencia.Log.Completo;
  end;
  AplicarEstadoVista;
end;

procedure TGestorExcepcionesAplicacion.AplicarEstadoVista;
begin
  if Assigned(FVista) then
    FVista.AplicarEstado(FEstadoVista);
end;

procedure TGestorExcepcionesAplicacion.ActualizarEstadoLog;
begin
  if not Assigned(FServicioEnvioErrores) then
  begin
    FEstadoVista.EstadoLog := SErrorNoSePudoEnviarError;
    FEstadoVista.NivelEstado := nevaError;
  end
  else if FEvidencia.Log.Completo then
  begin
    FEstadoVista.EstadoLog := SInfoLogErrorCompleto;
    FEstadoVista.NivelEstado := nevaCorrecto;
  end
  else
  begin
    FEstadoVista.EstadoLog := SAvisoLogErrorIncompleto;
    FEstadoVista.NivelEstado := nevaError;
  end;
end;

procedure TGestorExcepcionesAplicacion.MostrarDetalle(
  const ATexto: string);
begin
  FVista := FPresentacion.CrearVistaError;
  try
    ConfigurarDialogo;
    FVista.EstablecerDetalle(ATexto);
    FVista.Mostrar;
  finally
    if Assigned(FServicioEnvioErrores) then
      FServicioEnvioErrores.Limpiar(FEvidencia);
    FVista := nil;
  end;
end;

function TGestorExcepcionesAplicacion.PreguntarActivacionLog:
  Boolean;
begin
  Result := True;
  if Assigned(FServicioEnvioErrores) and
     not FEvidencia.Log.Completo then
  begin
    if MessageDlg_fza(
         SPreguntaActivarLogCompleto,
         mtConfirmation,
         [mbYes, mbNo],
         0) = mrYes then
    begin
      ActivarLogClick(nil);
      Result := False;
    end;
  end;
end;

function TGestorExcepcionesAplicacion.PrepararCopiaSeguridad:
  Boolean;
var
  sContrasena: string;
  sError: string;
begin
  Result := FileExists(FEvidencia.RutaCopiaSeguridad);
  sContrasena := '';
  if not Result then
  begin
    Screen.Cursor := crDefault;
    Result := SolicitarContrasenaCopia(
      Screen.ActiveCustomForm,
      sContrasena);
    if Result then
    begin
      Screen.Cursor := crHourGlass;
      FEstadoVista.EstadoLog := SInfoPreparandoCopiaSeguridadError;
      FEstadoVista.NivelEstado := nevaInformacion;
      AplicarEstadoVista;
      Result := FServicioEnvioErrores.PrepararCopiaSeguridad(
        FEvidencia,
        sContrasena,
        sError);
      if not Result then
      begin
        Screen.Cursor := crDefault;
        MessageDlg_fza(
          Format(SErrorPrepararCopiaSeguridadError, [sError]),
          mtError,
          [mbOk],
          0);
      end;
      CopiaSeguridadCambio(nil);
    end;
  end;
  sContrasena := '';
end;

procedure TGestorExcepcionesAplicacion.ActivarLogClick(
  Sender: TObject);
begin
  if Assigned(FServicioEnvioErrores) then
  begin
    FServicioEnvioErrores.ActivarDiagnosticoCompleto;
    FEstadoVista.EstadoLog := SInfoLogActivadoRepetir;
    FEstadoVista.NivelEstado := nevaCorrecto;
    FEstadoVista.ActivarLogHabilitado := False;
    AplicarEstadoVista;
  end;
end;

procedure TGestorExcepcionesAplicacion.EnviarDesarrolladorClick(
  Sender: TObject);
var
  bContinuar: Boolean;
  bEnviarCopia: Boolean;
  Contacto: TContactoError;
  Resultado: TResultadoEnvioError;
  sMensaje: string;
begin
  Contacto.Email := Trim(FVista.Email);
  Contacto.Telefono := Trim(FVista.Telefono);
  Contacto.Descripcion := FVista.Descripcion;
  if not EmailSoporteValido(Contacto.Email) or
     not TelefonoSoporteValido(Contacto.Telefono) then
  begin
    MessageDlg_fza(
      SErrorContactoEnvioErrorNoValido,
      mtWarning,
      [mbOk],
      0);
  end
  else
  begin
    bEnviarCopia := FVista.EnviarCopiaSeguridad;
    if bEnviarCopia then
      bContinuar := True
    else
      bContinuar := PreguntarActivacionLog;
    if bContinuar then
    begin
      FEstadoVista.PuedeEnviar := False;
      AplicarEstadoVista;
      Screen.Cursor := crHourGlass;
      try
        if bEnviarCopia then
          bContinuar := PrepararCopiaSeguridad;
        if bContinuar then
        begin
          Resultado := FServicioEnvioErrores.Enviar(
            FEvidencia,
            Contacto);
        end;
      finally
        Screen.Cursor := crDefault;
      end;
      if bContinuar then
      begin
        sMensaje := Resultado.Mensaje;
        if Resultado.Ok then
        begin
          sMensaje := Format(
            SInfoErrorEnviado,
            [Resultado.Referencia]);
          if Resultado.UrlSeguimiento <> '' then
          begin
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(
                SInfoSeguimientoError,
                [Resultado.UrlSeguimiento]);
          end;
          if bEnviarCopia then
          begin
            sMensaje := sMensaje + sLineBreak + sLineBreak +
              Format(
                SInfoEnviarContrasenaCopiaError,
                [Resultado.Referencia]);
          end;
          FVista.InsertarDetalle(sMensaje + sLineBreak);
          FRegistroLog.RegistrarInformacion(sMensaje);
          FPresentacion.MostrarMensaje(sMensaje);
        end
        else
        begin
          FEstadoVista.PuedeEnviar := True;
          AplicarEstadoVista;
          FRegistroLog.RegistrarAviso(
            'No se pudo enviar AppException: ' + sMensaje);
          MessageDlg_fza(sMensaje, mtError, [mbOk], 0);
        end;
      end;
      if not bContinuar then
      begin
        FEstadoVista.PuedeEnviar := True;
        AplicarEstadoVista;
      end;
    end;
  end;
end;

procedure TGestorExcepcionesAplicacion.CopiarDetalleClick(
  Sender: TObject);
begin
  if Assigned(FVista) then
  begin
    try
      Clipboard.AsText := FVista.TextoDetalle;
    except
      on E: Exception do
        FRegistroLog.RegistrarAviso(
          'No se pudo copiar al portapapeles: ' + E.Message);
    end;
  end;
end;

end.
