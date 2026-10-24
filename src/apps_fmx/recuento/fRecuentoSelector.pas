{******************************************************************************}
{                                                                              }
{  Módulo:       fRecuentoSelector                                             }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selector genérico de lista (modal asíncrono). Lo usa el menú para elegir  }
{    almacén (recuento libre) o plantilla (opción 3). La UI se construye por   }
{    código (sin .fmx).                                                        }
{******************************************************************************}
unit fRecuentoSelector;

interface

uses
  System.SysUtils, System.Classes, System.UITypes,
  FMX.Forms, FMX.Controls, FMX.StdCtrls, FMX.ListBox, FMX.Layouts, FMX.Types;

type
  TfrmSelector = class(TForm)
  private
    FLista   : TListBox;
    FValores : TArray<string>;
    FCallback: TProc<Boolean, string>;
    procedure Construir(const ATitulo: string; const ACaptions: TArray<string>);
    procedure OnAceptarClick(Sender: TObject);
    procedure OnCancelarClick(Sender: TObject);
  public
    class procedure ElegirAsync(AOwner: TComponent; const ATitulo: string;
      const ACaptions, AValores: TArray<string>;
      ACallback: TProc<Boolean, string>);
  end;

implementation

uses
  TraduccionMovil;

procedure TfrmSelector.Construir(const ATitulo: string;
  const ACaptions: TArray<string>);
var
  lblTitulo: TLabel;
  layBotones: TLayout;
  btnAceptar, btnCancelar: TButton;
  i: Integer;
  oItem: TListBoxItem;
begin
  Self.Caption := ATitulo;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 44;
  lblTitulo.Text := ATitulo;
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 56;
  btnCancelar := TButton.Create(Self);
  btnCancelar.Parent := layBotones;
  btnCancelar.Align := TAlignLayout.Left;
  btnCancelar.Width := 150;
  btnCancelar.Text := Tr('Cancelar');
  btnCancelar.OnClick := OnCancelarClick;
  btnAceptar := TButton.Create(Self);
  btnAceptar.Parent := layBotones;
  btnAceptar.Align := TAlignLayout.Right;
  btnAceptar.Width := 150;
  btnAceptar.Text := Tr('Aceptar');
  btnAceptar.OnClick := OnAceptarClick;
  FLista := TListBox.Create(Self);
  FLista.Parent := Self;
  FLista.Align := TAlignLayout.Client;
  for i := 0 to High(ACaptions) do
  begin
    oItem := TListBoxItem.Create(FLista);
    oItem.Parent := FLista;
    oItem.Text := ACaptions[i];
  end;
end;

procedure TfrmSelector.OnAceptarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmSelector.OnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

class procedure TfrmSelector.ElegirAsync(AOwner: TComponent;
  const ATitulo: string; const ACaptions, AValores: TArray<string>;
  ACallback: TProc<Boolean, string>);
var
  frm: TfrmSelector;
begin
  frm := TfrmSelector.CreateNew(AOwner);
  frm.FValores := AValores;
  frm.FCallback := ACallback;
  frm.Construir(ATitulo, ACaptions);
  frm.ShowModal(
    procedure(AResult: TModalResult)
    var
      sValor: string;
    begin
      sValor := '';
      if (AResult = mrOk) and (frm.FLista.ItemIndex >= 0) and
         (frm.FLista.ItemIndex <= High(frm.FValores)) then
        sValor := frm.FValores[frm.FLista.ItemIndex];
      if Assigned(frm.FCallback) then
        frm.FCallback(AResult = mrOk, sValor);
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
