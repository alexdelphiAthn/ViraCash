{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoConfig                                               }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pantalla de configuración: URL del servidor, clave API de la empresa,     }
{    operario y nombre del dispositivo. UI por código (sin .fmx).              }
{******************************************************************************}
unit fRecuentoConfig;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.Edit, FMX.Layouts, FMX.Types,
  FMX.DialogService,
  RecuentoConfig, RecuentoApi;

type
  TfrmConfig = class(TForm)
  private
    FUrl, FToken, FOperario, FDispositivo: TEdit;
    FSiguienteY: Single;
    procedure ApilarArriba(AControl: TControl);
    function NuevoEdit(const ATitulo, AValor: string): TEdit;
    procedure Construir;
    procedure VolcarAConfig;
    procedure OnGuardarClick(Sender: TObject);
    procedure OnProbarClick(Sender: TObject);
    procedure OnVolverClick(Sender: TObject);
  public
    class procedure EditarAsync(AOwner: TComponent; ACallback: TProc);
  end;

implementation

uses
  TraduccionMovil;

const
  cSeparadorRuta = '/';

function TfrmConfig.NuevoEdit(const ATitulo, AValor: string): TEdit;
var
  lbl: TLabel;
  edt: TEdit;
begin
  lbl := TLabel.Create(Self);
  lbl.Parent := Self;
  lbl.Height := 24;
  lbl.Text := ATitulo;
  ApilarArriba(lbl);
  edt := TEdit.Create(Self);
  edt.Parent := Self;
  edt.Height := 40;
  edt.Margins.Bottom := 8;
  edt.Text := AValor;
  ApilarArriba(edt);
  Result := edt;
end;

procedure TfrmConfig.ApilarArriba(AControl: TControl);
begin
  // Con Align=Top FMX ordena por la Y previa, no por el orden de creación:
  // se fija una Y creciente para que cada etiqueta quede encima de su edit.
  AControl.Position.Y := FSiguienteY;
  FSiguienteY := FSiguienteY + AControl.Height + AControl.Margins.Bottom;
  AControl.Align := TAlignLayout.Top;
end;

procedure TfrmConfig.Construir;
var
  layBotones: TLayout;
  btnProbar, btnGuardar, btnVolver: TButton;
begin
  Self.Caption := Tr('Configuración');
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 56;
  btnVolver := TButton.Create(Self);
  btnVolver.Parent := layBotones;
  btnVolver.Align := TAlignLayout.Left;
  btnVolver.Width := 110;
  btnVolver.Text := Tr('Volver');
  btnVolver.OnClick := OnVolverClick;
  btnGuardar := TButton.Create(Self);
  btnGuardar.Parent := layBotones;
  btnGuardar.Align := TAlignLayout.Left;
  btnGuardar.Width := 110;
  btnGuardar.Text := Tr('Guardar');
  btnGuardar.OnClick := OnGuardarClick;
  btnProbar := TButton.Create(Self);
  btnProbar.Parent := layBotones;
  btnProbar.Align := TAlignLayout.Right;
  btnProbar.Width := 150;
  btnProbar.Text := Tr('Probar conexión');
  btnProbar.OnClick := OnProbarClick;
  // Los campos se crean en el orden en que se ven (ver ApilarArriba).
  FSiguienteY := 0;
  FUrl         := NuevoEdit(
    TrF('URL del servidor (acaba en %s)', [cSeparadorRuta]), oConfig.UrlBase);
  FToken       := NuevoEdit(
    Tr('Clave API (la de la empresa, empieza por fza_)'), oConfig.Token);
  FToken.Password := True;
  FOperario    := NuevoEdit(Tr('Operario'), oConfig.Operario);
  FDispositivo := NuevoEdit(Tr('Nombre del dispositivo'),
    oConfig.Dispositivo);
end;

procedure TfrmConfig.VolcarAConfig;
begin
  oConfig.UrlBase     := Trim(FUrl.Text);
  oConfig.Token       := Trim(FToken.Text);
  oConfig.Operario    := Trim(FOperario.Text);
  oConfig.Dispositivo := Trim(FDispositivo.Text);
  oConfig.Guardar;
end;

procedure TfrmConfig.OnGuardarClick(Sender: TObject);
begin
  VolcarAConfig;
  TDialogService.ShowMessage(Tr('Configuración guardada'));
end;

procedure TfrmConfig.OnProbarClick(Sender: TObject);
var
  oApi: TRecuentoApi;
begin
  VolcarAConfig;
  // TODO: mover esta llamada de red a un hilo (TTask) para no bloquear la UI.
  oApi := TRecuentoApi.Create;
  try
    if oApi.ProbarConexion then
      TDialogService.ShowMessage(Tr('Conexión correcta'))
    else
      TDialogService.ShowMessage(
        TrF('No se pudo conectar: %s', [oApi.UltimoError]));
  finally
    FreeAndNil(oApi);
  end;
end;

procedure TfrmConfig.OnVolverClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

class procedure TfrmConfig.EditarAsync(AOwner: TComponent; ACallback: TProc);
var
  frm: TfrmConfig;
begin
  frm := TfrmConfig.CreateNew(AOwner);
  frm.Construir;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if Assigned(ACallback) then
        ACallback();
      // En Windows este callback corre dentro del cierre del modal: liberar
      // aquí el formulario provoca un access violation. Se difiere.
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
    end);
end;

end.
