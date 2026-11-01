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
      const AValores: TArray<string>; const ALongitudes: array of Integer);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
    procedure MostrarCampos(Sender: TObject);
  public
    class function Ejecutar(AOwner: TComponent; const ATitulo: string;
      const ARotulos: array of string; var AValores: TArray<string>): Boolean;
      overload;
    // ALongitudes: máximo de caracteres por campo según su columna; 0 o
    // ausente conserva el límite general.
    class function Ejecutar(AOwner: TComponent; const ATitulo: string;
      const ARotulos: array of string; var AValores: TArray<string>;
      const ALongitudes: array of Integer): Boolean; overload;
  end;

implementation

uses
  System.SysUtils, System.Math, cxLabel;

procedure TfrmModalDatosOrden.CrearCampos(const ARotulos: array of string;
  const AValores: TArray<string>; const ALongitudes: array of Integer);
var
  i, iFilas, iColumna, iFila: Integer;
  oRotulo: TcxLabel;
begin
  iFilas := Min(9, Length(ARotulos));
  ClientWidth := ScaleValue(460 * Ceil(Length(ARotulos) / iFilas));
  ClientHeight := ScaleValue(24 + iFilas * 55) + pnlButton.Height;
  // Los botones heredan la posición del diseño base (más ancho): se
  // recolocan simétricos para que Aceptar no quede cortado.
  btnCancelar.Left := ScaleValue(12);
  btnAceptar.Left := ClientWidth - btnAceptar.Width - ScaleValue(12);
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
    FEditores[i].Properties.MaxLength := 500;
    if (i <= High(ALongitudes)) and (ALongitudes[i] > 0) then
      FEditores[i].Properties.MaxLength := ALongitudes[i];
    FEditores[i].Text := AValores[i];
  end;
end;

procedure TfrmModalDatosOrden.MostrarCampos(Sender: TObject);
begin
  FormShow(Sender);
  // Se edita desde el primer campo; Intro no acepta sin haber revisado.
  if (Length(FEditores) > 0) and FEditores[0].CanFocus then
    FEditores[0].SetFocus;
end;

procedure TfrmModalDatosOrden.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalDatosOrden.Ejecutar(AOwner: TComponent;
  const ATitulo: string; const ARotulos: array of string;
  var AValores: TArray<string>): Boolean;
begin
  Result := Ejecutar(AOwner, ATitulo, ARotulos, AValores, []);
end;

class function TfrmModalDatosOrden.Ejecutar(AOwner: TComponent;
  const ATitulo: string; const ARotulos: array of string;
  var AValores: TArray<string>; const ALongitudes: array of Integer): Boolean;
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
    oFormulario.OnShow := oFormulario.MostrarCampos;
    oFormulario.CrearCampos(ARotulos, AValores, ALongitudes);
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
