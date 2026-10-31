{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalEvidenciaReparacion                                 }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Seguimiento de reparaciones y conservación de evidencias.                 }
{******************************************************************************}
unit inMtoModalEvidenciaReparacion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, cxTextEdit, cxDropDownEdit,
  cxCalendar, cxMemo, inMtoModalAceptCancel,
  inLibReparacionesEvidencias;

type
  TfrmModalEvidenciaReparacion = class(TfrmModalAceptCancel)
  private
    FCarpeta: string;
    FOriginal: TEvidenciaReparacion;
    FFecha: TcxDateEdit;
    FFase: TcxComboBox;
    FComentario: TcxMemo;
    FArchivo: TcxTextEdit;
    procedure Colocar(const ATitulo: string; AArriba: Integer;
      AEditor: TControl);
    procedure CrearControles(AFases: TStrings);
    procedure SeleccionarFotoClick(Sender: TObject);
    procedure Guardar;
    procedure CargarOriginal;
    function Mostrar(const ACarpeta: string; AFases: TStrings): Boolean;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    function CloseQuery: Boolean; override;
    class function Ejecutar(AOwner: TComponent; const ACarpeta: string;
      AFases: TStrings): Boolean;
    class function Editar(AOwner: TComponent;
      const AOriginal: TEvidenciaReparacion; AFases: TStrings): Boolean;
  end;

implementation

uses
  System.SysUtils, Vcl.Dialogs, Vcl.StdCtrls, cxLabel, cxButtons,
  System.DateUtils, System.IOUtils,
  inLibMsgReparaciones, inLibMensajesVcl;

procedure TfrmModalEvidenciaReparacion.Colocar(const ATitulo: string;
  AArriba: Integer; AEditor: TControl);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Transparent := True;
  oRotulo.Caption := ATitulo;
  oRotulo.SetBounds(ScaleValue(12), ScaleValue(AArriba),
    ScaleValue(130), ScaleValue(24));
  AEditor.Parent := pnlBody;
  AEditor.SetBounds(ScaleValue(150), ScaleValue(AArriba),
    ScaleValue(440), ScaleValue(26));
end;

procedure TfrmModalEvidenciaReparacion.CrearControles(AFases: TStrings);
var
  iFase: Integer;
  oBoton: TcxButton;
begin
  FFecha := TcxDateEdit.Create(Self);
  Colocar(SFotosFecha, 12, FFecha);
  FFecha.Properties.Kind := ckDateTime;
  FFecha.Properties.DisplayFormat := 'dd/mm/yyyy hh:nn:ss';
  FFecha.Properties.EditFormat := 'dd/mm/yyyy hh:nn:ss';
  FFecha.Date := Now;
  FFase := TcxComboBox.Create(Self);
  Colocar(SFotosFase, 48, FFase);
  FFase.Properties.Items.Add(SFotosGeneral);
  FFase.Properties.Items.Add(SFotosAntes);
  FFase.Properties.Items.Add(SFotosDespues);
  for iFase := 1 to AFases.Count - 1 do
    if FFase.Properties.Items.IndexOf(AFases[iFase]) < 0 then
      FFase.Properties.Items.Add(AFases[iFase]);
  FFase.ItemIndex := 0;
  FArchivo := TcxTextEdit.Create(Self);
  Colocar(SFotosArchivo, 84, FArchivo);
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := pnlBody;
  oBoton.SetBounds(ScaleValue(150), ScaleValue(120), ScaleValue(180),
    ScaleValue(30));
  oBoton.Caption := SFotosBuscar;
  oBoton.OnClick := SeleccionarFotoClick;
  FComentario := TcxMemo.Create(Self);
  Colocar(SFotosComentario, 162, FComentario);
  FComentario.Height := ScaleValue(150);
  FComentario.Properties.ScrollBars := ssVertical;
end;

procedure TfrmModalEvidenciaReparacion.SeleccionarFotoClick(Sender: TObject);
var
  oDialogo: TOpenDialog;
begin
  oDialogo := TOpenDialog.Create(Self);
  try
    oDialogo.Title := SFotosBuscar;
    oDialogo.Filter := SFotosFiltro;
    oDialogo.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];
    if oDialogo.Execute then
      FArchivo.Text := oDialogo.FileName;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmModalEvidenciaReparacion.Guardar;
var
  rEntrada: TEntradaEvidenciaReparacion;
begin
  rEntrada := Default(TEntradaEvidenciaReparacion);
  rEntrada.Fase := FFase.Text;
  rEntrada.Instante := FFecha.Date;
  rEntrada.Archivo := Trim(FArchivo.Text);
  rEntrada.Comentario := FComentario.Text;
  if FOriginal.Recibo = '' then
    GuardarEvidenciaReparacion(FCarpeta, rEntrada)
  else
    EditarEvidenciaReparacion(FOriginal, rEntrada);
end;

function TfrmModalEvidenciaReparacion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    try
      Guardar;
    except
      on E: Exception do
      begin
        Result := False;
        sFicha := 'N';
        ShowMessage_fza(E.Message);
      end;
    end;
  end;
end;

procedure TfrmModalEvidenciaReparacion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TfrmModalEvidenciaReparacion.CargarOriginal;
begin
  if FOriginal.Recibo <> '' then
  begin
    Caption := SFotosEditar;
    FFecha.Date := ISO8601ToDate(FOriginal.Instante, False);
    FFase.Text := FOriginal.Fase;
    FComentario.Text := FOriginal.Comentario;
    FArchivo.Text := FOriginal.Archivo;
  end;
end;

function TfrmModalEvidenciaReparacion.Mostrar(const ACarpeta: string;
  AFases: TStrings): Boolean;
begin
  Caption := SFotosAnadir;
  FCarpeta := ACarpeta;
  OnClose := CerrarSinLiberar;
  ClientWidth := ScaleValue(610);
  ClientHeight := ScaleValue(330) + pnlButton.Height;
  CrearControles(AFases);
  CargarOriginal;
  ShowModal;
  Result := sFicha = 'S';
end;

class function TfrmModalEvidenciaReparacion.Ejecutar(AOwner: TComponent;
  const ACarpeta: string; AFases: TStrings): Boolean;
var
  oFormulario: TfrmModalEvidenciaReparacion;
begin
  oFormulario := TfrmModalEvidenciaReparacion.Create(AOwner);
  try
    Result := oFormulario.Mostrar(ACarpeta, AFases);
  finally
    FreeAndNil(oFormulario);
  end;
end;

class function TfrmModalEvidenciaReparacion.Editar(AOwner: TComponent;
  const AOriginal: TEvidenciaReparacion; AFases: TStrings): Boolean;
var
  oFormulario: TfrmModalEvidenciaReparacion;
begin
  oFormulario := TfrmModalEvidenciaReparacion.Create(AOwner);
  try
    oFormulario.FOriginal := AOriginal;
    Result := oFormulario.Mostrar(ExtractFilePath(AOriginal.Recibo), AFases);
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
