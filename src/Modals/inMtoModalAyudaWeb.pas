{******************************************************************************}
{ Módulo: inMtoModalAyudaWeb                                                   }
{ Tipo: Formulario modal                                                       }
{ Fecha: 16/09/2026                                                            }
{ Autor: Alejandro Laorden Hidalgo                                             }
{ Copyright (c) Alejandro Laorden Hidalgo.                                     }
{ SPDX-License-Identifier: MPL-2.0                                             }
{ Descripción: Foro y manual en una ventana interna con navegación limitada.   }
{******************************************************************************}
unit inMtoModalAyudaWeb;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.Edge, cxButtons, cxLabel, inMtoFrmBase;

type
  TfrmModalAyudaWeb = class(TfrmBase)
    pnlNavegacion: TPanel;
    btnAtras: TcxButton;
    btnAdelante: TcxButton;
    btnRecargar: TcxButton;
    btnSalir: TcxButton;
    lblEstado: TcxLabel;
    navegador: TEdgeBrowser;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnAtrasClick(Sender: TObject);
    procedure btnAdelanteClick(Sender: TObject);
    procedure btnRecargarClick(Sender: TObject);
    procedure navegadorCreado(Sender: TCustomEdgeBrowser; AResult: HResult);
    procedure navegadorHistorial(Sender: TCustomEdgeBrowser);
    procedure navegadorIniciaNavegacion(Sender: TCustomEdgeBrowser;
      Args: TNavigationStartingEventArgs);
    procedure navegadorNuevaVentana(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
  private
    FUrlInicial: string;
    procedure IniciarNavegador;
    procedure ActualizarBotones;
    function EsDireccionWeb(const ADireccion: string): Boolean;
  public
    class function Ejecutar(AOwner: TComponent;
      const ATitulo, AUrl: string): TModalResult;
  end;

implementation

uses
  Winapi.ActiveX, System.SysUtils, System.Win.ComObj, inLibMsgComun,
  inLibWebView2Loader;

{$R *.dfm}

class function TfrmModalAyudaWeb.Ejecutar(AOwner: TComponent;
  const ATitulo, AUrl: string): TModalResult;
var
  Formulario: TfrmModalAyudaWeb;
begin
  Formulario := TfrmModalAyudaWeb.Create(AOwner);
  try
    Formulario.Caption := ATitulo;
    Formulario.FUrlInicial := AUrl;
    Result := Formulario.ShowModal;
  finally
    FreeAndNil(Formulario);
  end;
end;

procedure TfrmModalAyudaWeb.FormCreate(Sender: TObject);
begin
  btnAtras.Caption := SCaptionAyudaWebAtras;
  btnAdelante.Caption := SCaptionAyudaWebAdelante;
  btnRecargar.Caption := SCaptionAyudaWebRecargar;
  btnSalir.Caption := SCaptionSalir;
  inherited;
end;

procedure TfrmModalAyudaWeb.FormShow(Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Self);
  IniciarNavegador;
end;

procedure TfrmModalAyudaWeb.IniciarNavegador;
begin
  lblEstado.Caption := SInfoAyudaWebCargando;
  lblEstado.Visible := True;
  navegador.Visible := False;
  btnRecargar.Enabled := False;
  PrepararCargadorWebView2;
  navegador.CreateWebView;
end;

procedure TfrmModalAyudaWeb.navegadorCreado(Sender: TCustomEdgeBrowser;
  AResult: HResult);
begin
  if Succeeded(AResult) then
  begin
    navegador.DefaultContextMenusEnabled := False;
    navegador.DevToolsEnabled := False;
    navegador.StatusBarEnabled := False;
    lblEstado.Visible := False;
    navegador.Visible := True;
    navegador.Navigate(FUrlInicial);
  end
  else
    lblEstado.Caption := Format(SErrorAyudaWebIniciar,
      [IntToHex(AResult, 8)]);
  ActualizarBotones;
end;

procedure TfrmModalAyudaWeb.ActualizarBotones;
begin
  btnAtras.Enabled := navegador.CanGoBack;
  btnAdelante.Enabled := navegador.CanGoForward;
  btnRecargar.Enabled := navegador.BrowserControlState <>
    TCustomEdgeBrowser.TBrowserControlState.Creating;
end;

procedure TfrmModalAyudaWeb.navegadorHistorial(Sender: TCustomEdgeBrowser);
begin
  ActualizarBotones;
end;

procedure TfrmModalAyudaWeb.btnAtrasClick(Sender: TObject);
begin
  if navegador.CanGoBack then
    navegador.GoBack;
end;

procedure TfrmModalAyudaWeb.btnAdelanteClick(Sender: TObject);
begin
  if navegador.CanGoForward then
    navegador.GoForward;
end;

procedure TfrmModalAyudaWeb.btnRecargarClick(Sender: TObject);
begin
  if navegador.WebViewCreated then
    navegador.Refresh
  else
    IniciarNavegador;
end;

function TfrmModalAyudaWeb.EsDireccionWeb(const ADireccion: string): Boolean;
begin
  Result := ADireccion.StartsWith('https://', True) or
    ADireccion.StartsWith('http://', True);
end;

procedure TfrmModalAyudaWeb.navegadorIniciaNavegacion(
  Sender: TCustomEdgeBrowser; Args: TNavigationStartingEventArgs);
var
  Direccion: PWideChar;
begin
  Direccion := nil;
  try
    OleCheck(Args.ArgsInterface.Get_uri(Direccion));
    if not EsDireccionWeb(Direccion) then
      OleCheck(Args.ArgsInterface.Set_Cancel(1));
  finally
    CoTaskMemFree(Direccion);
  end;
end;

procedure TfrmModalAyudaWeb.navegadorNuevaVentana(
  Sender: TCustomEdgeBrowser; Args: TNewWindowRequestedEventArgs);
var
  Direccion: PWideChar;
begin
  OleCheck(Args.ArgsInterface.Set_Handled(1));
  Direccion := nil;
  try
    OleCheck(Args.ArgsInterface.Get_uri(Direccion));
    if EsDireccionWeb(Direccion) then
      navegador.Navigate(Direccion);
  finally
    CoTaskMemFree(Direccion);
  end;
end;

end.
