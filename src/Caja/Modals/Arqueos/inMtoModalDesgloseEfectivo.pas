{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalDesgloseEfectivo                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Recuento detallado del efectivo del cajón. Presenta una tabla con una     }
{    fila por denominación para teclear cuántos billetes y monedas hay y       }
{    devuelve el desglose contado al arqueo, que lo lleva a la fila Efectivo.  }
{******************************************************************************}
unit inMtoModalDesgloseEfectivo;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions, Vcl.Menus,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles,
  cxClasses, cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit,
  cxCurrencyEdit, cxSpinEdit, cxButtons, cxNavigator, cxCustomData, cxData,
  cxDataStorage, cxFilter, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGrid,
  dxCoreGraphics, cxLocalization,
  JvComponentBase, JvEnterTab,
  inMtoFrmBase, inLibArqueoDesglose;

type
  TfrmModalDesgloseEfectivo = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    cxgrdDesglose: TcxGrid;
    tvDesglose: TcxGridTableView;
    tvDesgloseTipo: TcxGridColumn;
    tvDesgloseValor: TcxGridColumn;
    tvDesgloseUnidades: TcxGridColumn;
    tvDesgloseImporte: TcxGridColumn;
    lvDesglose: TcxGridLevel;
    pnlResumen: TPanel;
    lblResumenTit: TcxLabel;
    lblBilletesLbl: TcxLabel;
    lblBilletes: TcxLabel;
    lblMonedasLbl: TcxLabel;
    lblMonedas: TcxLabel;
    lblPiezasLbl: TcxLabel;
    lblPiezas: TcxLabel;
    lblTotalLbl: TcxLabel;
    lblTotal: TcxLabel;
    lblSistemaLbl: TcxLabel;
    lblSistema: TcxLabel;
    lblDiferenciaLbl: TcxLabel;
    lblDiferencia: TcxLabel;
    lblAyuda: TcxLabel;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    btnLimpiar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    actLimpiar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure actLimpiarExecute(Sender: TObject);
    procedure tvDesgloseEditValueChanged(
      Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure tvDesgloseEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    procedure tvDesgloseKeyDown(
      Sender: TObject;
      var Key: Word;
      Shift: TShiftState);
  private
    FEfectivoSistema: Currency;
    FFormatoImportes: TFormatSettings;
    FMostrarSistema: Boolean;
    procedure Preparar(
      const ADenominaciones: TArray<Currency>;
      const ADesglose: TDesgloseArqueo);
    procedure EscribirUnidades(
      AFila: Integer;
      AUnidades: Integer);
    function  Contado: TDesgloseArqueo;
    procedure RecalcularTotales;
    procedure LimpiarUnidades;
  public
    procedure AplicarTraduccionActual; override;
    class function Ejecutar(
      AOwner: TComponent;
      const ADenominaciones: TArray<Currency>;
      AEfectivoSistema: Currency;
      AMostrarSistema: Boolean;
      var ADesglose: TDesgloseArqueo): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgCaja;

const
  cMaximoUnidadesDesglose = 99999;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalDesgloseEfectivo.Ejecutar(
  AOwner: TComponent;
  const ADenominaciones: TArray<Currency>;
  AEfectivoSistema: Currency;
  AMostrarSistema: Boolean;
  var ADesglose: TDesgloseArqueo): Boolean;
var
  frm: TfrmModalDesgloseEfectivo;
begin
  Result := False;
  frm := TfrmModalDesgloseEfectivo.Create(AOwner);
  try
    frm.FEfectivoSistema := AEfectivoSistema;
    frm.FMostrarSistema := AMostrarSistema;
    frm.Preparar(ADenominaciones, ADesglose);
    if frm.ShowModal = mrOk then
    begin
      ADesglose := frm.Contado;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalDesgloseEfectivo.FormCreate(Sender: TObject);
var
  Propiedades: TcxSpinEditProperties;
  NombreRegion: array[0..LOCALE_NAME_MAX_LENGTH - 1] of Char;
begin
  inherited;
  // El idioma del hilo puede cambiar al traducir la aplicación.
  // Los importes siguen la configuración regional del usuario de Windows.
  if GetUserDefaultLocaleName(
    NombreRegion, Length(NombreRegion)) = 0 then
    RaiseLastOSError;
  FFormatoImportes := TFormatSettings.Create(string(NombreRegion));
  Caption := STituloRecuentoEfectivoCaja;
  KeyPreview := True;
  Position := poScreenCenter;
  Propiedades := tvDesgloseUnidades.Properties as TcxSpinEditProperties;
  Propiedades.ValueType := vtInt;
  Propiedades.AssignedValues.MinValue := True;
  Propiedades.MinValue := 0;
  Propiedades.AssignedValues.MaxValue := True;
  Propiedades.MaxValue := cMaximoUnidadesDesglose;
  lblAyuda.Caption := SAyudaDesgloseEfectivo;
end;

procedure TfrmModalDesgloseEfectivo.FormShow(Sender: TObject);
begin
  inherited;
  if tvDesglose.DataController.RecordCount > 0 then
  begin
    cxgrdDesglose.SetFocus;
    tvDesglose.DataController.FocusedRecordIndex := 0;
    tvDesglose.Controller.FocusedColumn := tvDesgloseUnidades;
    tvDesglose.Controller.EditingController.ShowEdit(tvDesgloseUnidades);
  end;
end;

procedure TfrmModalDesgloseEfectivo.AplicarTraduccionActual;
begin
  inherited;
  // Los importes son datos regionales calculados, no textos del catálogo.
  if Assigned(tvDesglose) and
     (tvDesglose.DataController.RecordCount > 0) then
    RecalcularTotales;
end;

function BuscarUnidadesContadas(
  const ADesglose: TDesgloseArqueo;
  AValor: Currency): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(ADesglose) do
    if ADesglose[i].Valor = AValor then
      Result := ADesglose[i].Unidades;
end;

procedure TfrmModalDesgloseEfectivo.Preparar(
  const ADenominaciones: TArray<Currency>;
  const ADesglose: TDesgloseArqueo);
var
  aFilas: TDesgloseArqueo;
  i: Integer;
  sTipo: string;
begin
  aFilas := CrearDesgloseArqueo(ADenominaciones);
  { Al reabrir la ventana se recupera lo que ya habían contado. }
  for i := 0 to High(aFilas) do
    aFilas[i].Unidades := BuscarUnidadesContadas(
      ADesglose,
      aFilas[i].Valor);
  tvDesglose.BeginUpdate;
  try
    tvDesglose.DataController.RecordCount := Length(aFilas);
    for i := 0 to High(aFilas) do
    begin
      if aFilas[i].Tipo = tdaBillete then
        sTipo := STipoBilleteDesglose
      else
        sTipo := STipoMonedaDesglose;
      tvDesglose.DataController.Values[
        i, tvDesgloseTipo.Index] := sTipo;
      tvDesglose.DataController.Values[
        i, tvDesgloseValor.Index] := Double(aFilas[i].Valor);
      tvDesglose.DataController.Values[
        i, tvDesgloseUnidades.Index] := aFilas[i].Unidades;
      tvDesglose.DataController.Values[
        i, tvDesgloseImporte.Index] := Double(aFilas[i].Importe);
    end;
  finally
    tvDesglose.EndUpdate;
  end;
  lblSistemaLbl.Visible := FMostrarSistema;
  lblSistema.Visible := FMostrarSistema;
  lblDiferenciaLbl.Visible := FMostrarSistema;
  lblDiferencia.Visible := FMostrarSistema;
  RecalcularTotales;
end;

function TfrmModalDesgloseEfectivo.Contado: TDesgloseArqueo;
var
  i: Integer;
  vUnidades: Variant;
  vValor: Variant;
begin
  SetLength(Result, tvDesglose.DataController.RecordCount);
  for i := 0 to High(Result) do
  begin
    vValor := tvDesglose.DataController.Values[
      i, tvDesgloseValor.Index];
    vUnidades := tvDesglose.DataController.Values[
      i, tvDesgloseUnidades.Index];
    if VarIsNull(vValor) or VarIsEmpty(vValor) then
      Result[i].Valor := 0
    else
      Result[i].Valor := Currency(Double(vValor));
    if VarIsNull(vUnidades) or VarIsEmpty(vUnidades) then
      Result[i].Unidades := 0
    else
      Result[i].Unidades := StrToIntDef(VarToStr(vUnidades), 0);
    if Result[i].Unidades < 0 then
      Result[i].Unidades := 0;
  end;
end;

procedure TfrmModalDesgloseEfectivo.RecalcularTotales;
var
  aDesglose: TDesgloseArqueo;
  i: Integer;
  vDiferencia: Currency;
  vTotal: Currency;
begin
  aDesglose := Contado;
  for i := 0 to High(aDesglose) do
    tvDesglose.DataController.Values[
      i, tvDesgloseImporte.Index] := Double(aDesglose[i].Importe);
  vTotal := TotalDesgloseArqueo(aDesglose);
  vDiferencia := vTotal - FEfectivoSistema;
  lblBilletes.Caption := FormatFloat(
    '#,##0.00',
    TotalDesgloseArqueoPorTipo(aDesglose, tdaBillete), FFormatoImportes);
  lblMonedas.Caption := FormatFloat(
    '#,##0.00',
    TotalDesgloseArqueoPorTipo(aDesglose, tdaMoneda), FFormatoImportes);
  lblPiezas.Caption := IntToStr(UnidadesDesgloseArqueo(aDesglose));
  lblTotal.Caption := FormatFloat('#,##0.00', vTotal, FFormatoImportes);
  lblSistema.Caption := FormatFloat(
    '#,##0.00', FEfectivoSistema, FFormatoImportes);
  lblDiferencia.Caption := FormatFloat(
    '#,##0.00', vDiferencia, FFormatoImportes);
  if vDiferencia < 0 then
    lblDiferencia.Style.TextColor := clRed
  else if vDiferencia > 0 then
    lblDiferencia.Style.TextColor := clGreen
  else
    lblDiferencia.Style.TextColor := clWindowText;
end;

procedure TfrmModalDesgloseEfectivo.EscribirUnidades(
  AFila: Integer;
  AUnidades: Integer);
begin
  tvDesglose.DataController.Values[
    AFila, tvDesgloseUnidades.Index] := AUnidades;
end;

procedure TfrmModalDesgloseEfectivo.LimpiarUnidades;
var
  i: Integer;
begin
  tvDesglose.BeginUpdate;
  try
    for i := 0 to tvDesglose.DataController.RecordCount - 1 do
      EscribirUnidades(i, 0);
  finally
    tvDesglose.EndUpdate;
  end;
  RecalcularTotales;
end;

procedure TfrmModalDesgloseEfectivo.tvDesgloseEditValueChanged(
  Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem);
var
  iFila: Integer;
  iUnidades: Integer;
  oEdit: TcxCustomEdit;
  v: Variant;
begin
  if AItem = tvDesgloseUnidades then
  begin
    iFila := tvDesglose.DataController.FocusedRecordIndex;
    if iFila >= 0 then
    begin
      iUnidades := 0;
      oEdit := tvDesglose.Controller.EditingController.Edit;
      if Assigned(oEdit) then
      begin
        v := oEdit.EditValue;
        if not (VarIsNull(v) or VarIsEmpty(v)) then
          iUnidades := StrToIntDef(VarToStr(v), 0);
      end;
      if iUnidades < 0 then
        iUnidades := 0;
      EscribirUnidades(iFila, iUnidades);
      RecalcularTotales;
    end;
  end;
end;

procedure TfrmModalDesgloseEfectivo.tvDesgloseEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
begin
  tvDesgloseKeyDown(Sender, Key, Shift);
end;

procedure TfrmModalDesgloseEfectivo.tvDesgloseKeyDown(
  Sender: TObject;
  var Key: Word;
  Shift: TShiftState);
var
  iDestino: Integer;
  iFila: Integer;
begin
  if (Key = VK_RETURN) or
     ((Key = VK_END) and (ssCtrl in Shift)) or
     ((Key = VK_HOME) and (ssCtrl in Shift)) then
  begin
    if tvDesglose.Controller.EditingController.IsEditing then
      tvDesglose.Controller.EditingController.HideEdit(True);
    iFila := tvDesglose.DataController.FocusedRecordIndex;
    if Key = VK_RETURN then
      iDestino := iFila + 1
    else if Key = VK_END then
      iDestino := tvDesglose.DataController.RecordCount - 1
    else
      iDestino := 0;
    if iDestino < 0 then
      iDestino := 0;
    if iDestino > tvDesglose.DataController.RecordCount - 1 then
      iDestino := tvDesglose.DataController.RecordCount - 1;
    if iDestino <> iFila then
    begin
      tvDesglose.DataController.FocusedRecordIndex := iDestino;
      tvDesglose.Controller.FocusedColumn := tvDesgloseUnidades;
      tvDesglose.Controller.EditingController.ShowEdit(
        tvDesgloseUnidades);
    end;
    Key := 0;
  end;
end;

procedure TfrmModalDesgloseEfectivo.actAceptarExecute(Sender: TObject);
begin
  if tvDesglose.Controller.EditingController.IsEditing then
    tvDesglose.Controller.EditingController.HideEdit(True);
  RecalcularTotales;
  ModalResult := mrOk;
end;

procedure TfrmModalDesgloseEfectivo.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmModalDesgloseEfectivo.actLimpiarExecute(Sender: TObject);
begin
  if MessageBox_fza(
       PChar(SPreguntaLimpiarDesglose),
       PChar(STituloAvisoCaja),
       MB_YESNO or MB_ICONQUESTION) = IDYES then
    LimpiarUnidades;
end;

initialization
  ForceReferenceToClass(TfrmModalDesgloseEfectivo);
end.
