{******************************************************************************}
{  Módulo: inMtoModalDatosOrden. Tipo: Formulario (Modal)                      }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Edición de datos operativos de una orden sin persistencia.     }
{******************************************************************************}
unit inMtoModalDatosOrden;

interface

uses
  System.Classes, Vcl.Forms, cxTextEdit, inMtoModalAceptCancel;

type
  TfrmModalDatosOrden = class(TfrmModalAceptCancel)
  private
    FEditores: TArray<TcxTextEdit>;
    procedure CrearCampos(const ARotulos: array of string;
      const AValores: TArray<string>);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    class function Ejecutar(AOwner: TComponent; const ATitulo: string;
      const ARotulos: array of string; var AValores: TArray<string>): Boolean;
  end;

implementation

uses
  System.SysUtils, System.Math, cxLabel;

procedure TfrmModalDatosOrden.CrearCampos(const ARotulos: array of string;
  const AValores: TArray<string>);
var
  i, iFilas, iColumna, iFila: Integer;
  oRotulo: TcxLabel;
begin
  iFilas := Min(9, Length(ARotulos));
  ClientWidth := ScaleValue(460 * Ceil(Length(ARotulos) / iFilas));
  ClientHeight := ScaleValue(24 + iFilas * 55) + pnlButton.Height;
  SetLength(FEditores, Length(ARotulos));
  for i := 0 to High(ARotulos) do
  begin
    iColumna := i div iFilas;
    iFila := i mod iFilas;
    oRotulo := TcxLabel.Create(Self);
    oRotulo.Parent := pnlBody;
    oRotulo.Transparent := True;
    oRotulo.Caption := ARotulos[i];
    oRotulo.SetBounds(ScaleValue(12 + iColumna * 460),
      ScaleValue(8 + iFila * 55), ScaleValue(430), ScaleValue(22));
    FEditores[i] := TcxTextEdit.Create(Self);
    FEditores[i].Parent := pnlBody;
    FEditores[i].SetBounds(ScaleValue(12 + iColumna * 460),
      ScaleValue(30 + iFila * 55), ScaleValue(430), ScaleValue(26));
    FEditores[i].Text := AValores[i];
    FEditores[i].Properties.MaxLength := 500;
  end;
end;

procedure TfrmModalDatosOrden.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalDatosOrden.Ejecutar(AOwner: TComponent;
  const ATitulo: string; const ARotulos: array of string;
  var AValores: TArray<string>): Boolean;
var
  oFormulario: TfrmModalDatosOrden;
  i: Integer;
begin
  if (Length(ARotulos) = 0) or (Length(ARotulos) <> Length(AValores)) then
    raise EArgumentException.Create('ARotulos');
  oFormulario := TfrmModalDatosOrden.Create(AOwner);
  try
    oFormulario.Caption := ATitulo;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.CrearCampos(ARotulos, AValores);
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
    if Result then
      for i := 0 to High(AValores) do
        AValores[i] := Trim(oFormulario.FEditores[i].Text);
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
