{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalRepartoAutomatico                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Parámetros del reparto automático de la distribución entre tiendas:       }
{    tiendas que participan, tope por tienda y talla, stock objetivo y         }
{    criterio de prioridad. No conoce al formulario que lo abre.               }
{******************************************************************************}
unit inMtoModalRepartoAutomatico;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls,
  cxContainer, cxEdit, cxTextEdit, cxMaskEdit, cxSpinEdit, cxLabel,
  cxButtons, cxClasses, cxLocalization, cxCheckListBox, cxGroupBox,
  cxRadioGroup, dxSkinsCore,
  JvComponentBase, JvEnterTab,
  inMtoModalAceptCancel,
  inLibDistribucionTiendasIntf, inLibDistribucionTiendas;

type
  TResultadoRepartoAutomatico = record
    Aceptado: Boolean;
    Parametros: TParametrosRepartoAutomatico;
  end;

  TfrmModalRepartoAutomatico = class(TfrmModalAceptCancel)
    lblDestinos: TcxLabel;
    clbDestinos: TcxCheckListBox;
    btnMarcarTodos: TcxButton;
    btnDesmarcarTodos: TcxButton;
    lblMaximo: TcxLabel;
    edtMaximo: TcxSpinEdit;
    lblObjetivo: TcxLabel;
    edtObjetivo: TcxSpinEdit;
    rgCriterio: TcxRadioGroup;
    lblAyuda: TcxLabel;
    procedure btnMarcarTodosClick(Sender: TObject);
    procedure btnDesmarcarTodosClick(Sender: TObject);
  private
    FCodigos: TArray<string>;
    FResultado: TResultadoRepartoAutomatico;
    procedure CargarDestinos(
      const ADestinos: TAlmacenesDistribucion;
      const AMarcados, AOrigenes: TArray<string>);
    procedure MostrarParametros(
      const AParametros: TParametrosRepartoAutomatico);
    procedure MarcarTodos(AMarcado: Boolean);
    function LeerParametros: TParametrosRepartoAutomatico;
  protected
    procedure DoCreate; override;
  public
    class function Ejecutar(
      AOwner: TComponent;
      const ADestinos: TAlmacenesDistribucion;
      const AOrigenes: TArray<string>;
      const AIniciales: TParametrosRepartoAutomatico
    ): TResultadoRepartoAutomatico;
    function CloseQuery: Boolean; override;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibInformePropuestasTraspaso,
  inLibMsgDistribucionTiendas;

class function TfrmModalRepartoAutomatico.Ejecutar(
  AOwner: TComponent;
  const ADestinos: TAlmacenesDistribucion;
  const AOrigenes: TArray<string>;
  const AIniciales: TParametrosRepartoAutomatico
): TResultadoRepartoAutomatico;
var
  oFormulario: TfrmModalRepartoAutomatico;
begin
  oFormulario := TfrmModalRepartoAutomatico.Create(AOwner);
  // El ancestro se libera solo al cerrar (caFree); aquí se libera a mano
  // para poder leer antes el resultado.
  oFormulario.OnClose := nil;
  try
    oFormulario.CargarDestinos(ADestinos, AIniciales.Destinos, AOrigenes);
    oFormulario.MostrarParametros(AIniciales);
    oFormulario.ShowModal;
    Result := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

// El título se fija tras la traducción del formulario base, que si no lo
// deja con el de su ancestro.
procedure TfrmModalRepartoAutomatico.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloRepartoAutomatico;
  rgCriterio.Properties.Items[0].Caption := SCaptionCriterioOrdenAlmacen;
  rgCriterio.Properties.Items[1].Caption := SCaptionCriterioMenorStock;
  lblAyuda.Caption := SAyudaRepartoAutomatico;
end;

// Sin ninguna marcada de antemano participan todas. El origen sale siempre
// desmarcado: de él sale la mercancía; si se quiere, se marca a mano.
procedure TfrmModalRepartoAutomatico.CargarDestinos(
  const ADestinos: TAlmacenesDistribucion;
  const AMarcados, AOrigenes: TArray<string>);
var
  i, j: Integer;
  bMarcado: Boolean;
  oElemento: TcxCheckListBoxItem;
begin
  SetLength(FCodigos, Length(ADestinos));
  clbDestinos.Items.BeginUpdate;
  try
    clbDestinos.Items.Clear;
    for i := 0 to High(ADestinos) do
    begin
      FCodigos[i] := ADestinos[i].Codigo;
      bMarcado := Length(AMarcados) = 0;
      for j := 0 to High(AMarcados) do
      begin
        if SameText(Trim(AMarcados[j]), Trim(ADestinos[i].Codigo)) then
          bMarcado := True;
      end;
      for j := 0 to High(AOrigenes) do
      begin
        if SameText(Trim(AOrigenes[j]), Trim(ADestinos[i].Codigo)) then
          bMarcado := False;
      end;
      oElemento := clbDestinos.Items.Add;
      oElemento.Text := Format(SFormatoDestinoRepartoAutomatico, [
        ADestinos[i].Prioridad,
        TextoAlmacenPropuesta(ADestinos[i].Codigo, ADestinos[i].Nombre)]);
      oElemento.Checked := bMarcado;
    end;
  finally
    clbDestinos.Items.EndUpdate;
  end;
end;

procedure TfrmModalRepartoAutomatico.MostrarParametros(
  const AParametros: TParametrosRepartoAutomatico);
begin
  edtMaximo.Value := AParametros.MaximoPorDestino;
  edtObjetivo.Value := AParametros.StockObjetivo;
  if AParametros.Criterio = craMenorStock then
    rgCriterio.ItemIndex := 1
  else
    rgCriterio.ItemIndex := 0;
end;

procedure TfrmModalRepartoAutomatico.MarcarTodos(AMarcado: Boolean);
var
  i: Integer;
begin
  clbDestinos.Items.BeginUpdate;
  try
    for i := 0 to clbDestinos.Items.Count - 1 do
      clbDestinos.Items[i].Checked := AMarcado;
  finally
    clbDestinos.Items.EndUpdate;
  end;
end;

procedure TfrmModalRepartoAutomatico.btnMarcarTodosClick(Sender: TObject);
begin
  inherited;
  MarcarTodos(True);
end;

procedure TfrmModalRepartoAutomatico.btnDesmarcarTodosClick(
  Sender: TObject);
begin
  inherited;
  MarcarTodos(False);
end;

// Con todas marcadas la lista viaja vacía: así una tienda que se dé de
// alta después entra en el reparto sin tocar los parámetros guardados.
function TfrmModalRepartoAutomatico.LeerParametros:
  TParametrosRepartoAutomatico;
var
  i, iMarcados: Integer;
begin
  Result := Default(TParametrosRepartoAutomatico);
  iMarcados := 0;
  SetLength(Result.Destinos, clbDestinos.Items.Count);
  for i := 0 to clbDestinos.Items.Count - 1 do
  begin
    if clbDestinos.Items[i].Checked then
    begin
      Result.Destinos[iMarcados] := FCodigos[i];
      Inc(iMarcados);
    end;
  end;
  SetLength(Result.Destinos, iMarcados);
  if iMarcados = clbDestinos.Items.Count then
    SetLength(Result.Destinos, 0);
  if not VarIsNull(edtMaximo.Value) and (edtMaximo.Value > 0) then
    Result.MaximoPorDestino := edtMaximo.Value;
  if not VarIsNull(edtObjetivo.Value) and (edtObjetivo.Value > 0) then
    Result.StockObjetivo := edtObjetivo.Value;
  if rgCriterio.ItemIndex = 1 then
    Result.Criterio := craMenorStock
  else
    Result.Criterio := craOrdenAlmacen;
end;

// sFicha lo fija el ancestro: 'S' con Aceptar o F12 y 'N' con Cancelar o
// ESC. Aceptar sin ninguna tienda marcada no tiene sentido y no cierra.
function TfrmModalRepartoAutomatico.CloseQuery: Boolean;
var
  i: Integer;
  bAlgunaMarcada: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    bAlgunaMarcada := False;
    for i := 0 to clbDestinos.Items.Count - 1 do
    begin
      if clbDestinos.Items[i].Checked then
        bAlgunaMarcada := True;
    end;
    Result := bAlgunaMarcada;
    if Result then
    begin
      FResultado.Aceptado := True;
      FResultado.Parametros := LeerParametros;
    end
    else
    begin
      sFicha := 'N';
      ShowMessage_fza(SErrorRepartoAutomaticoSinDestinos);
    end;
  end;
end;

end.
