{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentanaSeparadaVcl                                         }
{    Tipo:       Librería                                                       }
{ Versión:       1.0.0                                                          }
{   Fecha:       18/10/2026                                                     }
{   Autor:       Alejandro Laorden Hidalgo                                      }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                     }
{  Descripción:                                                                }
{    Presentación nativa de una pantalla separada de sus pestañas.              }
{******************************************************************************}
unit inLibVentanaSeparadaVcl;

interface

uses
  Winapi.Windows, Winapi.Messages, Vcl.Controls,
  inLibVentanaEmbebidaIntf;

type
  TPresentacionVentanaSeparada = class
  private
    FConfiguracion: TConfiguracionVentanaGestionada;
  public
    procedure Configurar(
      const AConfiguracion: TConfiguracionVentanaGestionada);
    procedure PrepararParametros(var AParametros: TCreateParams);
    procedure CrearManejador(AVentana: HWND);
    procedure DestruirManejador(AVentana: HWND);
    function ProcesarMensaje(AVentana: HWND;
      var AMensaje: TMessage): Boolean;
    function SolicitarCierre: Boolean;
    function EstaSeparada: Boolean;
  end;

implementation

uses
  Winapi.CommCtrl, Vcl.Forms, System.SysUtils,
  inLibVentanaBarraTareas, inLibMsgComun;

const
  COMANDO_VOLVER_A_PESTANA = $1F10;
  MENSAJE_VOLVER_A_PESTANA = WM_APP + $513;

function MensajeVentanaSeparada(AVentana: HWND; AMensaje: UINT;
  AWParam: WPARAM; ALParam: LPARAM; AIdentificador: UINT_PTR;
  ADatos: DWORD_PTR): LRESULT; stdcall;
var
  oMensaje: TMessage;
  oPresentacion: TPresentacionVentanaSeparada;
  bTratado: Boolean;
begin
  oPresentacion := TPresentacionVentanaSeparada(ADatos);
  oMensaje := Default(TMessage);
  oMensaje.Msg := AMensaje;
  oMensaje.WParam := AWParam;
  oMensaje.LParam := ALParam;
  try
    bTratado := oPresentacion.ProcesarMensaje(AVentana, oMensaje);
  except
    Application.HandleException(oPresentacion);
    bTratado := True;
  end;
  if bTratado then
    Result := oMensaje.Result
  else
    Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
end;

procedure TPresentacionVentanaSeparada.Configurar(
  const AConfiguracion: TConfiguracionVentanaGestionada);
begin
  FConfiguracion := AConfiguracion;
end;

procedure TPresentacionVentanaSeparada.PrepararParametros(
  var AParametros: TCreateParams);
begin
  if FConfiguracion.Separada then
  begin
    AParametros.ExStyle := AParametros.ExStyle or WS_EX_APPWINDOW;
    AParametros.ExStyle := AParametros.ExStyle and not WS_EX_TOOLWINDOW;
    AParametros.WndParent := 0;
  end;
end;

procedure TPresentacionVentanaSeparada.CrearManejador(AVentana: HWND);
var
  hMenuSistema: HMENU;
  oControles: TInitCommonControlsEx;
begin
  if FConfiguracion.Separada then
  begin
    // Interceptar antes del skin: DevExpress consume WM_CONTEXTMENU y
    // reconstruye el menú del sistema antes de llegar al WndProc VCL.
    oControles.dwSize := SizeOf(oControles);
    oControles.dwICC := ICC_STANDARD_CLASSES;
    InitCommonControlsEx(oControles);
    if not SetWindowSubclass(AVentana, MensajeVentanaSeparada,
      UINT_PTR(Self), DWORD_PTR(Self)) then
      RaiseLastOSError;
    AsignarGrupoBarraTareas(AVentana, FConfiguracion.Grupo);
    AsignarIconoVentanaDesdePng(AVentana,
      FConfiguracion.RecursoIcono);
    hMenuSistema := GetSystemMenu(AVentana, False);
    AppendMenu(hMenuSistema, MF_SEPARATOR, 0, nil);
    AppendMenu(hMenuSistema, MF_STRING, COMANDO_VOLVER_A_PESTANA,
      PChar(SDockarPestana));
  end;
end;

procedure TPresentacionVentanaSeparada.DestruirManejador(AVentana: HWND);
begin
  RemoveWindowSubclass(AVentana, MensajeVentanaSeparada, UINT_PTR(Self));
  // Se limpia también al volver: la configuración puede haber cambiado
  // antes de que VCL destruya el antiguo manejador independiente.
  QuitarGrupoBarraTareas(AVentana);
  LiberarIconoVentana(AVentana);
end;

function TPresentacionVentanaSeparada.ProcesarMensaje(AVentana: HWND;
  var AMensaje: TMessage): Boolean;
var
  bMenuTitulo: Boolean;
begin
  Result := FConfiguracion.Separada and
    (((AMensaje.Msg = WM_SYSCOMMAND) and
      ((AMensaje.WParam and $FFF0) = COMANDO_VOLVER_A_PESTANA)) or
     (AMensaje.Msg = MENSAJE_VOLVER_A_PESTANA));
  bMenuTitulo := (AMensaje.Msg = WM_NCRBUTTONUP) and
    (AMensaje.WParam = HTCAPTION);
  if FConfiguracion.Separada and (AMensaje.Msg = WM_CONTEXTMENU) and
     (AMensaje.LParam <> -1) and
     (AVentana <> 0) then
    bMenuTitulo := SendMessage(AVentana, WM_NCHITTEST, 0,
      AMensaje.LParam) = HTCAPTION;
  if FConfiguracion.Separada and bMenuTitulo and
     Assigned(FConfiguracion.MostrarMenu) then
  begin
    FConfiguracion.MostrarMenu(
      SmallInt(LoWord(AMensaje.LParam)),
      SmallInt(HiWord(AMensaje.LParam)));
    AMensaje.Result := 0;
    Result := True;
  end;
  if Result then
  begin
    // No se recrea la ventana dentro del seguimiento del menú nativo.
    if AMensaje.Msg = WM_SYSCOMMAND then
      PostMessage(AVentana, MENSAJE_VOLVER_A_PESTANA, 0, 0)
    else if (AMensaje.Msg = MENSAJE_VOLVER_A_PESTANA) and
            Assigned(FConfiguracion.Volver) then
      FConfiguracion.Volver();
    AMensaje.Result := 0;
  end;
end;

function TPresentacionVentanaSeparada.SolicitarCierre: Boolean;
begin
  Result := Assigned(FConfiguracion.Cerrar);
  if Result then
    FConfiguracion.Cerrar();
end;

function TPresentacionVentanaSeparada.EstaSeparada: Boolean;
begin
  Result := FConfiguracion.Separada;
end;

end.
