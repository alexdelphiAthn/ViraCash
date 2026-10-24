{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalServiciosOffLine                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       20/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Instala fuera de hora la copia de seguridad y el cálculo de precios      }
{    medios como tareas del Programador de tareas de Windows.                  }
{******************************************************************************}
unit inMtoModalServiciosOffLine;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtonEdit,
  cxButtons,
  cxCheckBox,
  cxContainer,
  cxControls,
  cxDropDownEdit,
  cxEdit,
  cxGraphics,
  cxGroupBox,
  cxLabel,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxMaskEdit,
  cxPC,
  cxTextEdit,
  cxTimeEdit,
  inMtoFrmBase,
  inLibServiciosOffLineElevacion,
  inLibServiciosOffLineIntf;

type
  TfrmModalServiciosOffLine = class(TfrmBase)
    pnlPrincipal: TPanel;
    lblIntroduccion: TcxLabel;
    pcServicios: TcxPageControl;
    tsCuenta: TcxTabSheet;
    tsCopia: TcxTabSheet;
    tsPrecios: TcxTabSheet;
    gbCuenta: TcxGroupBox;
    lblUsuarioCuenta: TcxLabel;
    edtUsuarioCuenta: TcxTextEdit;
    lblContrasena: TcxLabel;
    edtContrasena: TcxTextEdit;
    chkCopia: TcxCheckBox;
    lblCarpetaCopia: TcxLabel;
    edtCarpetaCopia: TcxButtonEdit;
    lblNombreCopia: TcxLabel;
    edtNombreCopia: TcxTextEdit;
    lblTokensCopia: TcxLabel;
    lblHoraCopia: TcxLabel;
    edtHoraCopia: TcxTimeEdit;
    lblEstadoCopia: TcxLabel;
    chkPrecios: TcxCheckBox;
    lblExplicacionPrecios: TcxLabel;
    lblHoraPrecios: TcxLabel;
    edtHoraPrecios: TcxTimeEdit;
    lblEstadoPrecios: TcxLabel;
    lblUsuario: TcxLabel;
    pnlBotones: TPanel;
    btnInstalar: TcxButton;
    btnCerrar: TcxButton;
    procedure btnCerrarClick(Sender: TObject);
    procedure btnInstalarClick(Sender: TObject);
    procedure chkCopiaPropertiesEditValueChanged(Sender: TObject);
    procedure chkPreciosPropertiesEditValueChanged(Sender: TObject);
    procedure edtCarpetaCopiaPropertiesButtonClick(
      Sender: TObject;
      AButtonIndex: Integer);
  private
    FEntorno: TEntornoServiciosOffLine;
    FEstadoCopia: TEstadoServicioOffLine;
    FEstadoPrecios: TEstadoServicioOffLine;
    FProgramador: IProgramadorServiciosOffLine;
    function ConfiguracionEnPantalla(
      AServicio: TServicioOffLine): TConfiguracionServicioOffLine;
    function CredencialEnPantalla: TCredencialServiciosOffLine;
    function TextoEstado(
      const AEstado: TEstadoServicioOffLine): string;
    procedure ActualizarDisponibilidad;
    procedure AnadirOperacion(
      var APlan: TPlanServiciosOffLine;
      AServicio: TServicioOffLine;
      AMarcado: Boolean;
      const AEstado: TEstadoServicioOffLine;
      AMensajes: TStrings);
    procedure AplicarCambios;
    procedure AplicarPlan(
      const APlan: TPlanServiciosOffLine;
      AMensajes: TStrings);
    procedure CargarEstado;
    procedure Configurar(
      const AProgramador: IProgramadorServiciosOffLine;
      const AEntorno: TEntornoServiciosOffLine);
    procedure VolcarEstado(
      const AEstado: TEstadoServicioOffLine;
      AServicio: TServicioOffLine);
  protected
    procedure DoCreate; override;
  public
    class procedure Ejecutar(
      AOwner: TComponent;
      const AProgramador: IProgramadorServiciosOffLine;
      const AEntorno: TEntornoServiciosOffLine);
  end;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  Vcl.FileCtrl,
  inLibMensajesVcl,
  inLibMsgServiciosOffLine,
  inLibProgramadorTareasWindows,
  inLibServiciosOffLine;

procedure TfrmModalServiciosOffLine.DoCreate;
begin
  inherited;
  // FormCreate de TfrmBase traduce el Caption buscando su clave por la
  // jerarquía de clases: sin clave propia aplica la de TfrmBase.
  Caption := STituloServiciosOffLine;
end;

class procedure TfrmModalServiciosOffLine.Ejecutar(
  AOwner: TComponent;
  const AProgramador: IProgramadorServiciosOffLine;
  const AEntorno: TEntornoServiciosOffLine);
var
  oFormulario: TfrmModalServiciosOffLine;
begin
  oFormulario := TfrmModalServiciosOffLine.Create(AOwner);
  try
    oFormulario.Configurar(AProgramador, AEntorno);
    oFormulario.ShowModal;
    oFormulario.edtContrasena.Text := '';
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalServiciosOffLine.Configurar(
  const AProgramador: IProgramadorServiciosOffLine;
  const AEntorno: TEntornoServiciosOffLine);
begin
  FProgramador := AProgramador;
  FEntorno := AEntorno;
  edtUsuarioCuenta.Text := FEntorno.Usuario;
  lblUsuario.Caption := SCaptionUsuarioServiciosOffLine;
  CargarEstado;
end;

procedure TfrmModalServiciosOffLine.CargarEstado;
begin
  FEstadoCopia := FProgramador.Consultar(
    soCopiaSeguridad,
    FEntorno);
  FEstadoPrecios := FProgramador.Consultar(
    soPreciosMedios,
    FEntorno);
  VolcarEstado(FEstadoCopia, soCopiaSeguridad);
  VolcarEstado(FEstadoPrecios, soPreciosMedios);
  ActualizarDisponibilidad;
end;

procedure TfrmModalServiciosOffLine.VolcarEstado(
  const AEstado: TEstadoServicioOffLine;
  AServicio: TServicioOffLine);
begin
  if AEstado.Existe and (Trim(AEstado.Cuenta) <> '') and
     (Pos('\', AEstado.Cuenta) > 0) then
    edtUsuarioCuenta.Text := AEstado.Cuenta;
  if AServicio = soCopiaSeguridad then
  begin
    chkCopia.Checked := AEstado.Existe;
    edtCarpetaCopia.Text := AEstado.Configuracion.Carpeta;
    edtNombreCopia.Text := AEstado.Configuracion.NombreFichero;
    edtHoraCopia.Time := EncodeTime(
      AEstado.Configuracion.Hora,
      AEstado.Configuracion.Minuto,
      0,
      0);
    lblEstadoCopia.Caption := TextoEstado(AEstado);
  end
  else
  begin
    chkPrecios.Checked := AEstado.Existe;
    edtHoraPrecios.Time := EncodeTime(
      AEstado.Configuracion.Hora,
      AEstado.Configuracion.Minuto,
      0,
      0);
    lblEstadoPrecios.Caption := TextoEstado(AEstado);
  end;
end;

function TfrmModalServiciosOffLine.TextoEstado(
  const AEstado: TEstadoServicioOffLine): string;
begin
  if AEstado.Error <> '' then
    Result := Format(SEstadoServicioOffLineError, [AEstado.Error])
  else if not AEstado.Existe then
    Result := SEstadoServicioOffLineNoInstalado
  else if not AEstado.Habilitada then
    Result := SEstadoServicioOffLineDesactivado
  else if AEstado.ProximaEjecucion <> '' then
  begin
    Result := Format(
      SEstadoServicioOffLineInstalado,
      [AEstado.ProximaEjecucion]);
  end
  else
    Result := SEstadoServicioOffLineInstaladoSinFecha;
  if AEstado.Existe and AEstado.RequiereSesionIniciada then
    Result := Result + ' ' + SEstadoServicioOffLineConSesion;
  if AEstado.Existe and not AEstado.EsDeEstaInstalacion then
  begin
    Result := Result + ' ' + Format(
      SEstadoServicioOffLineOtroEjecutable,
      [AEstado.Ejecutable]);
  end;
end;

function TfrmModalServiciosOffLine.ConfiguracionEnPantalla(
  AServicio: TServicioOffLine): TConfiguracionServicioOffLine;
var
  iHora: Word;
  iMilisegundo: Word;
  iMinuto: Word;
  iSegundo: Word;
begin
  Result := Default(TConfiguracionServicioOffLine);
  Result.Servicio := AServicio;
  if AServicio = soCopiaSeguridad then
  begin
    DecodeTime(edtHoraCopia.Time, iHora, iMinuto, iSegundo,
      iMilisegundo);
    Result.Carpeta := ExcludeTrailingPathDelimiter(
      Trim(edtCarpetaCopia.Text));
    Result.NombreFichero := Trim(edtNombreCopia.Text);
  end
  else
  begin
    DecodeTime(edtHoraPrecios.Time, iHora, iMinuto, iSegundo,
      iMilisegundo);
  end;
  Result.Hora := iHora;
  Result.Minuto := iMinuto;
end;

function TfrmModalServiciosOffLine.CredencialEnPantalla:
  TCredencialServiciosOffLine;
begin
  Result := Default(TCredencialServiciosOffLine);
  Result.Usuario := Trim(edtUsuarioCuenta.Text);
  Result.Contrasena := edtContrasena.Text;
end;

procedure TfrmModalServiciosOffLine.ActualizarDisponibilidad;
begin
  lblCarpetaCopia.Enabled := chkCopia.Checked;
  edtCarpetaCopia.Enabled := chkCopia.Checked;
  lblNombreCopia.Enabled := chkCopia.Checked;
  edtNombreCopia.Enabled := chkCopia.Checked;
  lblTokensCopia.Enabled := chkCopia.Checked;
  lblHoraCopia.Enabled := chkCopia.Checked;
  edtHoraCopia.Enabled := chkCopia.Checked;
  lblHoraPrecios.Enabled := chkPrecios.Checked;
  edtHoraPrecios.Enabled := chkPrecios.Checked;
end;

// Cada servicio aporta como mucho una operacion al plan: instalar
// lo marcado o quitar lo desmarcado que siga instalado.
procedure TfrmModalServiciosOffLine.AnadirOperacion(
  var APlan: TPlanServiciosOffLine;
  AServicio: TServicioOffLine;
  AMarcado: Boolean;
  const AEstado: TEstadoServicioOffLine;
  AMensajes: TStrings);
var
  Configuracion: TConfiguracionServicioOffLine;
  Error: TErrorServicioOffLine;
  sNombre: string;
begin
  sNombre := NombreTareaServicioOffLine(AServicio);
  Configuracion := ConfiguracionEnPantalla(AServicio);
  if AMarcado then
  begin
    Error := ValidarServicioOffLine(Configuracion, FEntorno);
    if Error <> esoNinguno then
      AMensajes.Add(DescripcionErrorServicioOffLine(Error))
    else
      AnadirOperacionServiciosOffLine(APlan, True, Configuracion);
  end
  else if AEstado.Existe and
          (MessageDlg_fza(
             Format(SPreguntaQuitarServicioOffLine, [sNombre]),
             mtConfirmation,
             [mbYes, mbNo],
             0) = mrYes) then
    AnadirOperacionServiciosOffLine(APlan, False, Configuracion);
end;

// Con contrasena la tarea se registra desde aqui; sin ella hace
// falta elevacion, porque el Programador solo acepta S4U desde un
// proceso de administrador.
procedure TfrmModalServiciosOffLine.AplicarPlan(
  const APlan: TPlanServiciosOffLine;
  AMensajes: TStrings);
var
  aTextos: TArray<string>;
  iIndice: Integer;
  sError: string;
begin
  aTextos := nil;
  sError := '';
  if (ModoAccesoServiciosOffLine(APlan.Credencial) =
      masContrasena) or ProcesoElevado then
    AplicarPlanServiciosOffLine(FProgramador, APlan, aTextos)
  else
  begin
    EjecutarPlanServiciosOffLineElevado(
      APlan,
      aTextos,
      sError);
  end;
  for iIndice := Low(aTextos) to High(aTextos) do
    AMensajes.Add(aTextos[iIndice]);
  if sError <> '' then
  begin
    AMensajes.Add(Format(
      SErrorElevacionServiciosOffLine,
      [sError]));
  end;
end;

procedure TfrmModalServiciosOffLine.AplicarCambios;
var
  oMensajes: TStringList;
  Plan: TPlanServiciosOffLine;
begin
  Plan := Default(TPlanServiciosOffLine);
  Plan.Entorno := FEntorno;
  Plan.Credencial := CredencialEnPantalla;
  oMensajes := TStringList.Create;
  try
    AnadirOperacion(
      Plan,
      soCopiaSeguridad,
      chkCopia.Checked,
      FEstadoCopia,
      oMensajes);
    AnadirOperacion(
      Plan,
      soPreciosMedios,
      chkPrecios.Checked,
      FEstadoPrecios,
      oMensajes);
    if Length(Plan.Operaciones) = 0 then
    begin
      if oMensajes.Count = 0 then
        oMensajes.Add(SAvisoSinCambiosServiciosOffLine);
    end
    else if Plan.Credencial.Usuario = '' then
      oMensajes.Add(SErrorUsuarioServiciosOffLine)
    else
      AplicarPlan(Plan, oMensajes);
    MessageDlg_fza(oMensajes.Text, mtInformation, [mbOK], 0);
  finally
    FreeAndNil(oMensajes);
  end;
  CargarEstado;
end;

procedure TfrmModalServiciosOffLine.btnInstalarClick(Sender: TObject);
begin
  AplicarCambios;
end;

procedure TfrmModalServiciosOffLine.btnCerrarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalServiciosOffLine.chkCopiaPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarDisponibilidad;
end;

procedure TfrmModalServiciosOffLine.chkPreciosPropertiesEditValueChanged(
  Sender: TObject);
begin
  ActualizarDisponibilidad;
end;

procedure TfrmModalServiciosOffLine.edtCarpetaCopiaPropertiesButtonClick(
  Sender: TObject;
  AButtonIndex: Integer);
var
  sCarpeta: string;
begin
  sCarpeta := Trim(edtCarpetaCopia.Text);
  if SelectDirectory(
       SSolicitudCarpetaCopiaServiciosOffLine,
       '',
       sCarpeta,
       [sdNewUI, sdNewFolder]) then
    edtCarpetaCopia.Text := ExcludeTrailingPathDelimiter(sCarpeta);
end;

end.
