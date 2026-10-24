{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalDescargaTraduccion                                  }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Muestra el progreso de descarga e instalación de una traducción.         }
{******************************************************************************}
unit inMtoModalDescargaTraduccion;

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxProgressBar,
  inMtoFrmBase,
  inLibTraduccionesDescargaPersistenciaIntf;

const
  cMensajeEjecutarTraduccion = WM_APP + 117;

type
  TAplicarIdiomaTraduccion = procedure(
    const AIdioma: string) of object;

  TfrmModalDescargaTraduccion = class(TfrmBase)
    lblTitulo: TcxLabel;
    lblEstado: TcxLabel;
    prgDescarga: TcxProgressBar;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
  private
    FAplicarIdioma: TAplicarIdiomaTraduccion;
    FDescargar: Boolean;
    FError: string;
    FIdioma: string;
    FIniciado: Boolean;
    FInstalador: IInstaladorTraduccionesPersistencia;
    FProcesando: Boolean;
    FToken: string;
    FUrlBase: string;
    procedure ActualizarProgreso(
      const ATexto: string;
      APosicion: Integer);
    procedure EjecutarProceso;
    procedure MensajeEjecutarTraduccion(
      var AMensaje: TMessage); message cMensajeEjecutarTraduccion;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const AInstalador: IInstaladorTraduccionesPersistencia;
      const AUrlBase, AToken, AIdioma: string;
      ADescargar: Boolean;
      AAplicarIdioma: TAplicarIdiomaTraduccion;
      out AError: string): Boolean;
  end;

implementation

uses
  inLibMsgIntegraciones, inLibTraduccionesDescarga;

{$R *.dfm}

class function TfrmModalDescargaTraduccion.Ejecutar(
  AOwner: TComponent;
  const AInstalador: IInstaladorTraduccionesPersistencia;
  const AUrlBase, AToken, AIdioma: string;
  ADescargar: Boolean;
  AAplicarIdioma: TAplicarIdiomaTraduccion;
  out AError: string): Boolean;
var
  oFormulario: TfrmModalDescargaTraduccion;
begin
  oFormulario := TfrmModalDescargaTraduccion.Create(AOwner);
  try
    oFormulario.FAplicarIdioma := AAplicarIdioma;
    oFormulario.FDescargar := ADescargar;
    oFormulario.FIdioma := AIdioma;
    oFormulario.FInstalador := AInstalador;
    oFormulario.FToken := AToken;
    oFormulario.FUrlBase := AUrlBase;
    oFormulario.FProcesando := True;
    oFormulario.ShowModal;
    Result := oFormulario.ModalResult = mrOk;
    AError := oFormulario.FError;
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalDescargaTraduccion.ActualizarProgreso(
  const ATexto: string;
  APosicion: Integer);
begin
  if APosicion < 0 then
    APosicion := 0
  else if APosicion > 100 then
    APosicion := 100;
  lblEstado.Caption := ATexto;
  prgDescarga.Position := APosicion;
  Update;
  Application.ProcessMessages;
end;

procedure TfrmModalDescargaTraduccion.EjecutarProceso;
begin
  try
    if FDescargar then
      TInstaladorTraducciones.DescargarEInstalar(
        FInstalador,
        FUrlBase,
        FToken,
        FIdioma,
        ActualizarProgreso)
    else
      ActualizarProgreso(
        SProgresoTraduccionDisponible,
        90);
    ActualizarProgreso(
      SProgresoTraduccionAplicando,
      95);
    if Assigned(FAplicarIdioma) then
      FAplicarIdioma(FIdioma);
    ActualizarProgreso(
      SProgresoTraduccionCompletada,
      100);
  except
    on E: Exception do
    begin
      FError := E.Message;
      RegistroLog.RegistrarError(
        'Descarga de traducción ' + FIdioma + ': ' + E.Message);
    end;
  end;
  FProcesando := False;
  if FError = '' then
    ModalResult := mrOk
  else
    ModalResult := mrCancel;
end;

procedure TfrmModalDescargaTraduccion.FormCloseQuery(
  Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := not FProcesando;
end;

procedure TfrmModalDescargaTraduccion.FormShow(Sender: TObject);
begin
  if not FIniciado then
  begin
    FIniciado := True;
    PostMessage(
      Handle,
      cMensajeEjecutarTraduccion,
      0,
      0);
  end;
end;

procedure TfrmModalDescargaTraduccion.MensajeEjecutarTraduccion(
  var AMensaje: TMessage);
begin
  EjecutarProceso;
end;

end.
