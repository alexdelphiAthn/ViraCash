{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalActualizacion                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       18/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Muestra el progreso de comprobar, instalar y revertir una versión.        }
{    Antes de comprobar, contrasta el parámetro appMotorBaseDatos con el       }
{    servidor y, si no cuadran, avisa y propone cambiarlo.                     }
{******************************************************************************}
unit inMtoModalActualizacion;

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Uni,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxProgressBar,
  cxButtons,
  inMtoFrmBase,
  inLibActualizacionEstado,
  inLibActualizacionIntf,
  inLibActualizacionProceso,
  inLibActualizacionScriptsLectura,
  inLibActualizacionScripts,
  inLibAnfitrionMtoIntf,
  inLibMotorBaseDatos,
  inLibParametrosIntf,
  inLibVentanaEspera;

const
  cMensajeEjecutarActualizacion = WM_APP + 121;

type
  TfrmModalActualizacion = class(TfrmBase)
    lblTitulo: TcxLabel;
    lblEstado: TcxLabel;
    prgProceso: TcxProgressBar;
    btnReintentar: TcxButton;
    btnCompararModelo: TcxButton;
    btnDetalle: TcxButton;
    btnCerrar: TcxButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure btnReintentarClick(Sender: TObject);
    procedure btnDetalleClick(Sender: TObject);
    procedure btnCompararModeloClick(Sender: TObject);
  private
    FAnfitrion: IAnfitrionMantenimiento;
    FContexto: TContextoActualizacion;
    FParametros: IParametrosAplicacion;
    FParametrosEdicion: IParametrosEdicion;
    FIniciado: Boolean;
    FModo: TModoPantallaActualizacion;
    FProcesando: Boolean;
    FDespachando: Boolean;
    FResultado: TResultadoActualizacion;
    FSolicitarCopiaPrevia: TSolicitarCopiaPreviaActualizacion;
    FAlArrancar: Boolean;
    FErrorMostrado: Boolean;
    function TextoScriptsFaltantes(
      const AFaltantes: TArray<TScriptFaltante>): string;
    function TextoEstadoReversion(
      const AEstado: TEstadoActualizacion): string;
    function CrearInteraccion: TInteraccionActualizacion;
    function ConsultarVersionServidor: string;
    procedure GuardarMotorBaseDatos(AMotor: TMotorBaseDatos);
    function ProponerCambioMotor(
      const AVersion: string;
      AMotorServidor: TMotorBaseDatos): Boolean;
    function AvisarMotorNoAdmitido(const AVersion: string): Boolean;
    function RevisarMotorBaseDatos: Boolean;
    procedure EjecutarProceso;
    procedure MostrarErrorProceso;
    procedure MensajeEjecutarActualizacion(
      var AMensaje: TMessage); message cMensajeEjecutarActualizacion;
    procedure WMSysCommand(
      var AMensaje: TWMSysCommand); message WM_SYSCOMMAND;
  protected
    procedure DoCreate; override;
  public
    procedure Progreso(const ATexto: string; APorcentaje: Integer);
    function ConfirmarInstalacion(
      const AManifiesto: TManifiestoActualizacion): Boolean;
    function DecidirScripts(
      const AFaltantes: TArray<TScriptFaltante>;
      AHayVersionNueva: Boolean):
      TDecisionScriptsActualizacion;
    function DecidirModo(
      const AFaltantes: TArray<TScriptFaltante>;
      AHayVersionNueva: Boolean;
      const AVersion: string): TDecisionScriptsActualizacion;
    function ConfirmarScriptComparacion(
      const AVersion, ARutaScript, ASalida: string;
      AConAvisos: Boolean): Boolean;
    function CrearVentanaProceso(const ATitulo: string): IVentanaEspera;
    function CrearVentanaEsperaPantalla: IVentanaEspera;
    function SolicitarCopiaPrevia(out ARutaCopia: string): Boolean;
    function ConfirmarReversion(
      const AEstado: TEstadoActualizacion): Boolean;
    function ConsultarRestaurarCopia(
      const ASinRollback: TArray<string>;
      const ARutaCopia: string): Boolean;
    class function Ejecutar(
      AOwner: TComponent;
      const AAnfitrion: IAnfitrionMantenimiento;
      const AParametros: IParametrosAplicacion;
      const AParametrosEdicion: IParametrosEdicion;
      AConexion: TUniConnection;
      const AVersionInstalada: string;
      AModo: TModoPantallaActualizacion;
      out AResultado: TResultadoActualizacion;
      const ASolicitarCopiaPrevia: TSolicitarCopiaPreviaActualizacion = nil;
      AAlArrancar: Boolean = False
      ): Boolean;
  end;

implementation

uses
  System.IOUtils,
  inLibActualizacionServicio,
  inLibAppParamPersistenciaIntf,
  inLibMensajesVcl,
  inLibMsgIntegraciones,
  inLibPerfilesUsuarioIntf,
  inMtoModalMensajeTexto,
  UniDataAppParamRepositorio,
  UniDataVersionServidor;

const
  // Perfil en el que se guardan los parámetros de la aplicación.
  cFormularioParametrosAplicacion = 'frmMtoAppParam';

{$R *.dfm}

class function TfrmModalActualizacion.Ejecutar(
  AOwner: TComponent;
  const AAnfitrion: IAnfitrionMantenimiento;
  const AParametros: IParametrosAplicacion;
  const AParametrosEdicion: IParametrosEdicion;
  AConexion: TUniConnection;
  const AVersionInstalada: string;
  AModo: TModoPantallaActualizacion;
  out AResultado: TResultadoActualizacion;
  const ASolicitarCopiaPrevia: TSolicitarCopiaPreviaActualizacion;
  AAlArrancar: Boolean): Boolean;
var
  oFormulario: TfrmModalActualizacion;
begin
  oFormulario := TfrmModalActualizacion.Create(AOwner);
  try
    oFormulario.FAnfitrion := AAnfitrion;
    oFormulario.FSolicitarCopiaPrevia := ASolicitarCopiaPrevia;
    oFormulario.FAlArrancar := AAlArrancar;
    oFormulario.FModo := AModo;
    oFormulario.FProcesando := True;
    oFormulario.FParametros := AParametros;
    oFormulario.FParametrosEdicion := AParametrosEdicion;
    oFormulario.FContexto.Conexion := AConexion;
    oFormulario.FContexto.VersionInstalada := AVersionInstalada;
    oFormulario.FContexto.RutaEjecutable := ExpandFileName(ParamStr(0));
    oFormulario.FContexto.Motor := MotorBaseDatosDeTexto(
      AParametros.GetString(
        PARAMETRO_MOTOR_BASE_DATOS,
        MOTOR_BASE_DATOS_MARIADB1213));
    oFormulario.FContexto.Servicio := CrearServicioActualizaciones(
      AParametros,
      oFormulario.Progreso);
    oFormulario.ShowModal;
    AResultado := oFormulario.FResultado;
    if oFormulario.FErrorMostrado then
      AResultado.Mensaje := '';
    Result := AResultado.Ok;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalActualizacion.DoCreate;
begin
  inherited;
  // FormCreate de TfrmBase traduce el Caption por la jerarquía de clases:
  // sin clave propia dejaría 'frmBase'. El modo todavía no está asignado,
  // así que el título definitivo se pone en FormShow.
  Caption := STituloComprobarActualizaciones;
  btnReintentar.Caption := SBotonReintentarActualizacion;
  btnCompararModelo.Caption := SBotonCompararModeloActualizacion;
  btnDetalle.Caption := SBotonDetalleActualizacion;
  btnCerrar.Caption := SBotonCerrarActualizacion;
end;

procedure TfrmModalActualizacion.Progreso(
  const ATexto: string;
  APorcentaje: Integer);
begin
  lblEstado.Caption := ATexto;
  if APorcentaje < 0 then
  begin
    // Sin porcentaje conocido: se avanza un poco para que se vea vivo.
    if prgProceso.Position < 90 then
      prgProceso.Position := prgProceso.Position + 5;
  end
  else if APorcentaje > 100 then
    prgProceso.Position := 100
  else
    prgProceso.Position := APorcentaje;
  Update;
end;

function TfrmModalActualizacion.ConfirmarInstalacion(
  const AManifiesto: TManifiestoActualizacion): Boolean;
var
  sTexto: string;
begin
  sTexto := Format(
    SDetalleActualizacionDisponible,
    [FContexto.VersionInstalada,
     AManifiesto.Version,
     AManifiesto.Fecha,
     FormatFloat('#,##0', AManifiesto.Ejecutable.Tamano),
     FormatFloat('#,##0', AManifiesto.Ejecutable.TamanoDescarga),
     Length(AManifiesto.Auxiliares),
     AManifiesto.Notas]);
  TfrmModalMensajeTexto.Mostrar(Self, sTexto);
  if FAlArrancar then
    sTexto := SPreguntaInstalarActualizacionArranque
  else
    sTexto := SPreguntaInstalarActualizacion;
  Result := MessageDlg_fza(Self,
    Format(sTexto, [AManifiesto.Version]),
    mtConfirmation,
    [mbYes, mbNo],
    0) = mrYes;
end;

function TfrmModalActualizacion.TextoScriptsFaltantes(
  const AFaltantes: TArray<TScriptFaltante>): string;
var
  iIndice: Integer;
begin
  Result := SDetalleScriptsFaltantes;
  for iIndice := Low(AFaltantes) to High(AFaltantes) do
    Result := Result + sLineBreak +
      Format(
        SLineaScriptFaltante,
        [AFaltantes[iIndice].Orden,
         AFaltantes[iIndice].Nombre,
         AFaltantes[iIndice].Objeto]);
end;

function TfrmModalActualizacion.DecidirScripts(
  const AFaltantes: TArray<TScriptFaltante>;
  AHayVersionNueva: Boolean):
  TDecisionScriptsActualizacion;
var
  sPregunta: string;
begin
  TfrmModalMensajeTexto.Mostrar(Self, TextoScriptsFaltantes(AFaltantes));
  // Sin versión nueva no hay que salir del programa al terminar, así que
  // no se advierte de ello.
  if AHayVersionNueva then
    sPregunta := SPreguntaAplicarScriptsAhora
  else
    sPregunta := SPreguntaAplicarScriptsAhoraMismaVersion;
  if MessageDlg_fza(Self,
       Format(sPregunta, [Length(AFaltantes)]),
       mtWarning,
       [mbYes, mbNo],
       0) = mrYes then
    Result := dsaAhora
  else
    Result := dsaAplazar;
end;

// La versión trae modelo: además de por scripts, se puede poner al día por
// comparación. Sí = scripts, No = comparación, Cancelar = más tarde.
function TfrmModalActualizacion.DecidirModo(
  const AFaltantes: TArray<TScriptFaltante>;
  AHayVersionNueva: Boolean;
  const AVersion: string): TDecisionScriptsActualizacion;
var
  sSalir: string;
begin
  TfrmModalMensajeTexto.Mostrar(Self, TextoScriptsFaltantes(AFaltantes));
  sSalir := '';
  if AHayVersionNueva then
    sSalir := SAvisoSalirTrasScripts;
  case MessageDlgTextos_fza(Self,
         Format(
           SPreguntaModoActualizacionBBDD,
           [Length(AFaltantes), AVersion, sSalir]),
         mtWarning,
         [mbYes, mbNo, mbCancel],
         [SBotonActualizarPorScripts,
          SBotonActualizarPorComparacion,
          SBotonActualizarMasTarde],
         mbYes) of
    mrYes:
      Result := dsaAhora;
    mrNo:
      Result := dsaComparacion;
  else
    Result := dsaAplazar;
  end;
end;

// Antes de tocar la base se enseña lo que ha salido de la comparación,
// con lo que DBComparer ha dicho (destino detectado y avisos).
function TfrmModalActualizacion.ConfirmarScriptComparacion(
  const AVersion, ARutaScript, ASalida: string;
  AConAvisos: Boolean): Boolean;
var
  sPregunta: string;
begin
  TfrmModalMensajeTexto.Mostrar(
    Self,
    Format(
      SDetalleScriptComparacion,
      [AVersion,
       ASalida,
       TextoScriptParaVentana(LeerTextoScriptSql(ARutaScript))]));
  if AConAvisos then
    sPregunta := SPreguntaAplicarScriptComparacionConAvisos
  else
    sPregunta := SPreguntaAplicarScriptComparacion;
  Result := MessageDlg_fza(
    Self, sPregunta, mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes;
end;

// La misma ventana que el generador de procesos: cronómetro, se puede
// apartar y enseña el script que se está ejecutando.
function TfrmModalActualizacion.CrearVentanaProceso(
  const ATitulo: string): IVentanaEspera;
begin
  Result := CrearVentanaProcesoSegundoPlano(
    Self.BoundsRect,
    Self.CurrentPPI,
    ATitulo);
end;

// La espera sigue a este modal, que también existe durante el arranque.
// La ventana principal todavía puede estar oculta: vigilarla escondería
// la animación y el cronómetro mientras el comparador sigue trabajando.
function TfrmModalActualizacion.CrearVentanaEsperaPantalla: IVentanaEspera;
begin
  Result := CrearVentanaEspera(
    Self.BoundsRect,
    Self.CurrentPPI,
    Self.Handle);
end;

function TfrmModalActualizacion.SolicitarCopiaPrevia(
  out ARutaCopia: string): Boolean;
begin
  ARutaCopia := '';
  Result := Assigned(FAnfitrion) or Assigned(FSolicitarCopiaPrevia);
  if not Result then
    MessageDlg_fza(Self,
      SErrorAnfitrionCopiaPreviaNoDisponible,
      mtError,
      [mbOk],
      0)
  else
  begin
    MessageDlg_fza(Self, SAvisoCopiaPreviaObligatoria,
      mtInformation, [mbOk], 0);
    if Assigned(FSolicitarCopiaPrevia) then
      Result := FSolicitarCopiaPrevia(ARutaCopia)
    else
      Result := FAnfitrion.CrearCopiaPreviaActualizacion(ARutaCopia);
  end;
end;

function TfrmModalActualizacion.TextoEstadoReversion(
  const AEstado: TEstadoActualizacion): string;
var
  iIndice: Integer;
begin
  Result := Format(
    SDetalleReversionActualizacion,
    [AEstado.VersionDestino,
     AEstado.VersionOrigen,
     AEstado.Instante,
     Length(AEstado.Ejecutables),
     Length(AEstado.Aplicados)]);
  for iIndice := Low(AEstado.Aplicados) to High(AEstado.Aplicados) do
    Result := Result + sLineBreak +
      Format(
        SLineaScriptRevertible,
        [AEstado.Aplicados[iIndice].Nombre,
         AEstado.Aplicados[iIndice].Resultado,
         AEstado.Aplicados[iIndice].RutaRollback]);
  if AEstado.RutaCopiaPrevia <> '' then
    Result := Result + sLineBreak + sLineBreak +
      Format(SLineaCopiaPreviaReversion, [AEstado.RutaCopiaPrevia]);
end;

function TfrmModalActualizacion.ConfirmarReversion(
  const AEstado: TEstadoActualizacion): Boolean;
begin
  TfrmModalMensajeTexto.Mostrar(Self, TextoEstadoReversion(AEstado));
  Result := MessageDlg_fza(Self,
    Format(SPreguntaRevertirActualizacion, [AEstado.VersionOrigen]),
    mtWarning,
    [mbYes, mbNo],
    0) = mrYes;
end;

function TfrmModalActualizacion.ConsultarRestaurarCopia(
  const ASinRollback: TArray<string>;
  const ARutaCopia: string): Boolean;
var
  iIndice: Integer;
  sTexto: string;
begin
  sTexto := SDetalleScriptsSinRollback;
  for iIndice := Low(ASinRollback) to High(ASinRollback) do
    sTexto := sTexto + sLineBreak + '  ' + ASinRollback[iIndice];
  TfrmModalMensajeTexto.Mostrar(Self, sTexto);
  Result := (Trim(ARutaCopia) <> '') and TFile.Exists(ARutaCopia) and
    (MessageDlg_fza(Self,
       Format(SPreguntaRestaurarCopiaPrevia, [ARutaCopia]),
       mtWarning,
       [mbYes, mbNo],
       0) = mrYes);
  if (Trim(ARutaCopia) = '') or not TFile.Exists(ARutaCopia) then
    MessageDlg_fza(Self,
      SAvisoSinCopiaPreviaParaRevertir,
      mtWarning,
      [mbOk],
      0);
end;

function TfrmModalActualizacion.CrearInteraccion:
  TInteraccionActualizacion;
begin
  Result.Progreso := Progreso;
  Result.ConfirmarInstalacion := ConfirmarInstalacion;
  Result.DecidirScripts := DecidirScripts;
  Result.SolicitarCopiaPrevia := SolicitarCopiaPrevia;
  Result.ConfirmarReversion := ConfirmarReversion;
  Result.ConsultarRestaurarCopia := ConsultarRestaurarCopia;
  Result.CrearVentanaProceso := CrearVentanaProceso;
  Result.CrearVentanaEspera := CrearVentanaEsperaPantalla;
  Result.DecidirModo := DecidirModo;
  Result.ConfirmarScriptComparacion := ConfirmarScriptComparacion;
end;

// Si no se puede preguntar, se sigue con el parámetro: no es motivo para
// no actualizar.
function TfrmModalActualizacion.ConsultarVersionServidor: string;
begin
  try
    Result := ConsultarVersionServidorUniDAC(FContexto.Conexion);
  except
    on E: Exception do
    begin
      Result := '';
      RegistroLog.RegistrarAviso(
        'Actualización: no se ha podido leer VERSION(): ' + E.Message);
    end;
  end;
end;

// Se guarda para todos, que es lo que describe: el servidor es el mismo
// para cualquier usuario. Si un usuario o grupo tiene un valor propio,
// ése sigue mandando en los parámetros, y se le dice.
procedure TfrmModalActualizacion.GuardarMotorBaseDatos(
  AMotor: TMotorBaseDatos);
var
  aValores: TValoresPerfilAppParam;
  sVigente: string;
begin
  SetLength(aValores, 1);
  aValores[0].Subclave := PARAMETRO_MOTOR_BASE_DATOS;
  aValores[0].Valor := TextoMotorBaseDatos(AMotor);
  CrearRepositorioAppParamUniDAC(FContexto.Conexion).GuardarValores(
    PERFIL_TODOS,
    cFormularioParametrosAplicacion,
    aValores);
  RegistroLog.RegistrarInformacion(
    'Actualización: parámetro ' + PARAMETRO_MOTOR_BASE_DATOS +
    ' cambiado a ' + aValores[0].Valor + ' para todos.');
  if Assigned(FParametrosEdicion) then
    FParametrosEdicion.Recargar(
      IdentidadSesion.Usuario,
      IdentidadSesion.Grupo);
  sVigente := FParametros.GetString(
    PARAMETRO_MOTOR_BASE_DATOS,
    MOTOR_BASE_DATOS_MARIADB1213);
  if MotorBaseDatosDeTexto(sVigente) <> AMotor then
    MessageDlg_fza(Self,
      Format(
        SAvisoMotorValorPropioUsuario,
        [sVigente, TextoMotorBaseDatos(AMotor)]),
      mtWarning,
      [mbOk],
      0);
  FContexto.Motor := AMotor;
end;

// El servidor es de otro motor admitido. Un administrador puede cambiar
// el parámetro aquí mismo; los demás, seguir con él o dejarlo.
function TfrmModalActualizacion.ProponerCambioMotor(
  const AVersion: string;
  AMotorServidor: TMotorBaseDatos): Boolean;
var
  sAviso: string;
begin
  sAviso := Format(
    SAvisoMotorDistintoServidor,
    [TextoMotorBaseDatos(FContexto.Motor),
     AVersion,
     DescripcionMotorBaseDatos(AMotorServidor)]);
  if SameText(IdentidadSesion.GrupoRaiz, 'S') then
  begin
    case MessageDlgTextos_fza(Self,
           sAviso + sLineBreak + sLineBreak +
             Format(
               SPreguntaCambiarMotorServidor,
               [TextoMotorBaseDatos(AMotorServidor)]),
           mtWarning,
           [mbYes, mbNo, mbCancel],
           [Format(
              SBotonCambiarMotorBaseDatos,
              [TextoMotorBaseDatos(AMotorServidor)]),
            Format(
              SBotonSeguirConMotorBaseDatos,
              [TextoMotorBaseDatos(FContexto.Motor)]),
            SBotonCancelarActualizacionMotor],
           mbYes) of
      mrYes:
        begin
          GuardarMotorBaseDatos(AMotorServidor);
          Result := True;
        end;
      mrNo:
        Result := True;
    else
      Result := False;
    end;
  end
  else
    Result := MessageDlgTextos_fza(Self,
      sAviso + sLineBreak + sLineBreak +
        Format(
          SPreguntaMotorSoloAdministrador,
          [TextoMotorBaseDatos(FContexto.Motor)]),
      mtWarning,
      [mbYes, mbCancel],
      [Format(
         SBotonSeguirConMotorBaseDatos,
         [TextoMotorBaseDatos(FContexto.Motor)]),
       SBotonCancelarActualizacionMotor],
      mbCancel) = mrYes;
end;

function TfrmModalActualizacion.AvisarMotorNoAdmitido(
  const AVersion: string): Boolean;
begin
  Result := MessageDlgTextos_fza(Self,
    Format(
      SAvisoMotorNoAdmitido,
      [AVersion, TextoMotorBaseDatos(FContexto.Motor)]),
    mtWarning,
    [mbYes, mbCancel],
    [Format(
       SBotonSeguirConMotorBaseDatos,
       [TextoMotorBaseDatos(FContexto.Motor)]),
     SBotonCancelarActualizacionMotor],
    mbCancel) = mrYes;
end;

// False si el usuario prefiere no actualizar con el motor que hay.
function TfrmModalActualizacion.RevisarMotorBaseDatos: Boolean;
var
  MotorServidor: TMotorBaseDatos;
  sVersion: string;
begin
  sVersion := ConsultarVersionServidor;
  case CompararMotorConServidor(FContexto.Motor, sVersion, MotorServidor) of
    cmsOtroMotor:
      Result := ProponerCambioMotor(sVersion, MotorServidor);
    cmsNoAdmitido:
      Result := AvisarMotorNoAdmitido(sVersion);
  else
    Result := True;
  end;
end;

procedure TfrmModalActualizacion.MostrarErrorProceso;
begin
  lblEstado.Caption := SErrorActualizacionDetenida;
  btnReintentar.Visible := (FModo in [mpaComprobar, mpaCompararModelo]) and
    not FResultado.RequiereSalir and not FResultado.SolicitaRestaurarCopia;
  btnCompararModelo.Visible := btnReintentar.Visible;
  btnDetalle.Visible := True;
  btnCerrar.Visible := True;
  RegistroLog.RegistrarError(
    'Actualización de la aplicación: ' + FResultado.Mensaje);
  FErrorMostrado := True;
  btnDetalleClick(nil);
end;

procedure TfrmModalActualizacion.btnDetalleClick(Sender: TObject);
begin
  TfrmModalMensajeTexto.Mostrar(Self, STituloComprobarActualizaciones,
    FResultado.Mensaje);
end;

procedure TfrmModalActualizacion.btnReintentarClick(Sender: TObject);
begin
  if not FProcesando then
  begin
    FProcesando := True;
    FErrorMostrado := False;
    FResultado := Default(TResultadoActualizacion);
    btnReintentar.Visible := False;
    btnCompararModelo.Visible := False;
    btnDetalle.Visible := False;
    btnCerrar.Visible := False;
    prgProceso.Position := 0;
    PostMessage(Handle, cMensajeEjecutarActualizacion, 0, 0);
  end;
end;

procedure TfrmModalActualizacion.btnCompararModeloClick(Sender: TObject);
begin
  if not FProcesando then
  begin
    FModo := mpaCompararModelo;
    btnReintentarClick(Sender);
  end;
end;

procedure TfrmModalActualizacion.EjecutarProceso;
var
  Interaccion: TInteraccionActualizacion;
begin
  try
    Interaccion := CrearInteraccion;
    case FModo of
      mpaComprobar, mpaCompararModelo:
        if RevisarMotorBaseDatos then
        begin
          if FModo = mpaCompararModelo then
            FResultado := CompararBaseConModeloPublicado(
              FContexto, Interaccion)
          else
            FResultado := ComprobarEInstalarActualizacion(
              FContexto, Interaccion, FAlArrancar);
        end
        else
        begin
          FResultado := Default(TResultadoActualizacion);
          FResultado.Ok := True;
          FResultado.Cancelado := True;
          FResultado.Mensaje := SInfoActualizacionCanceladaMotor;
        end;
      mpaAplicarPendientes:
        FResultado := AplicarScriptsPendientesActualizacion(
          FContexto.Conexion,
          Interaccion);
      mpaRevertir:
        FResultado := RevertirActualizacion(FContexto, Interaccion);
    end;
    if FResultado.Ok and not FResultado.Cancelado then
      Progreso(SInfoProcesoActualizacionTerminado, 100);
  except
    on E: Exception do
    begin
      FResultado.Ok := False;
      FResultado.Mensaje := E.Message;
    end;
  end;
  FProcesando := False;
  if FResultado.Ok then
    ModalResult := mrOk
  else
    MostrarErrorProceso;
end;

procedure TfrmModalActualizacion.FormCloseQuery(
  Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not FProcesando;
end;

procedure TfrmModalActualizacion.FormShow(Sender: TObject);
begin
  if not FIniciado then
  begin
    FIniciado := True;
    if FModo = mpaRevertir then
      Caption := STituloRevertirActualizacion
    else
      Caption := STituloComprobarActualizaciones;
    lblTitulo.Caption := Caption;
    PostMessage(Handle, cMensajeEjecutarActualizacion, 0, 0);
  end;
end;

procedure TfrmModalActualizacion.MensajeEjecutarActualizacion(
  var AMensaje: TMessage);
begin
  if not FDespachando then
  begin
    FDespachando := True;
    try
      EjecutarProceso;
    finally
      FDespachando := False;
    end;
  end;
end;

// Minimizar esta pantalla minimiza el programa entero: la copia previa
// puede tardar y se sigue en el icono de la barra de tareas. Al
// restaurarlo desde el icono, la pantalla vuelve con la principal.
procedure TfrmModalActualizacion.WMSysCommand(
  var AMensaje: TWMSysCommand);
begin
  if (AMensaje.CmdType and $FFF0) = SC_MINIMIZE then
    Application.Minimize
  else
    inherited;
end;

end.
