{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalRetiradaLotes                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       13/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Confirmación de retirada y ticket opcional.                   }
{******************************************************************************}
unit inMtoModalRetiradaLotes;

interface

uses
  System.Classes, Uni, Vcl.Forms, cxGridTableView, cxTextEdit,
  cxDropDownEdit, cxCheckBox, inMtoModalAceptCancel,
  inLibRetiradaLotesIntf;

type
  TfrmModalRetiradaLotes = class(TfrmModalAceptCancel)
  private
    FRepositorio: IRepositorioRetiradaLotes;
    FOrden: TOrdenRetiradaLotes;
    FAlmacenes: TArray<TAlmacenRetiradaLotes>;
    FEmpleado: TcxTextEdit;
    FMotivo: TcxComboBox;
    FDestino: TcxComboBox;
    FUrgente: TcxCheckBox;
    FVista: TcxGridTableView;
    FGuardada: Boolean;
    procedure CrearCabecera;
    procedure CrearRejilla;
    procedure Recoger;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);

  protected
    function ConfirmarImpresion(const AOrden: TOrdenRetiradaLotes):
      Boolean; virtual;
    procedure EnviarTicket(const AOrden: TOrdenRetiradaLotes); virtual;
    procedure PreguntarImpresion(const AOrden: TOrdenRetiradaLotes);
    procedure DoCreate; override;
  public
    constructor CreateRetirada(AOwner: TComponent; AConexion: TUniConnection;
      const AOrden: TOrdenRetiradaLotes);
    function CloseQuery: Boolean; override;
    class function Ejecutar(AOwner: TComponent; AConexion: TUniConnection;
      const AOrden: TOrdenRetiradaLotes): Boolean;
    class procedure Reimprimir(AOwner: TComponent;
      AConexion: TUniConnection; const AEmpresa, AMovimiento: string);
  end;

implementation

uses
  System.SysUtils, System.Variants, System.UITypes, Vcl.Controls, Vcl.Dialogs,
  cxGrid, cxGridLevel, cxGroupBox, cxLabel, cxCustomData, cxDataStorage,
  cxCurrencyEdit, inLibRetiradaLotes, inLibRetiradaLotesTicket,
  inLibMsgRetiradaLotes, inLibMensajesVcl,
  UniDataRetiradaLotesRepositorio;

constructor TfrmModalRetiradaLotes.CreateRetirada(AOwner: TComponent;
  AConexion: TUniConnection; const AOrden: TOrdenRetiradaLotes);
begin
  inherited Create(AOwner);
  FOrden := AOrden;
  if FOrden.Id = '' then
    FOrden.Id := CrearIdRetirada;
  FOrden.Lineas := Copy(AOrden.Lineas);
  FRepositorio := TRepositorioRetiradaLotes.Create(AConexion, AOrden.Empresa);
  OnClose := CerrarSinLiberar;
  ClientWidth := ScaleValue(820);
  ClientHeight := ScaleValue(460);
  CrearCabecera;
  CrearRejilla;
end;

procedure TfrmModalRetiradaLotes.DoCreate;
begin
  inherited;
  Caption := STituloOrdenRetirada;
end;

procedure TfrmModalRetiradaLotes.CrearCabecera;
var
  Cabecera: TcxGroupBox;
  Etiqueta: TcxLabel;
  Indice: Integer;
begin
  Cabecera := TcxGroupBox.Create(Self);
  Cabecera.Parent := pnlBody;
  Cabecera.Align := alTop;
  Cabecera.Height := ScaleValue(120);
  Cabecera.PanelStyle.Active := True;
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.Caption := SEtiquetaEmpleadoRetirada;
  Etiqueta.SetBounds(ScaleValue(8), ScaleValue(8), 100, 22);
  FEmpleado := TcxTextEdit.Create(Self);
  FEmpleado.Parent := Cabecera;
  FEmpleado.SetBounds(ScaleValue(120), ScaleValue(8), ScaleValue(230), 24);
  FEmpleado.Text := FOrden.Empleado;
  FEmpleado.Properties.MaxLength := 50;
  FMotivo := TcxComboBox.Create(Self);
  FMotivo.Parent := Cabecera;
  FMotivo.SetBounds(ScaleValue(370), ScaleValue(8), ScaleValue(240), 24);
  FMotivo.Properties.DropDownListStyle := lsFixedList;
  for Indice := Ord(Low(TMotivoRetiradaLote)) to
      Ord(High(TMotivoRetiradaLote)) do
    FMotivo.Properties.Items.Add(TextoMotivoRetirada(
      TMotivoRetiradaLote(Indice)));
  FMotivo.ItemIndex := Ord(FOrden.Motivo);
  FDestino := TcxComboBox.Create(Self);
  FDestino.Parent := Cabecera;
  FDestino.SetBounds(ScaleValue(120), ScaleValue(46), ScaleValue(490), 24);
  FDestino.Properties.DropDownListStyle := lsFixedList;
  FAlmacenes := FRepositorio.AlmacenesTaras(FOrden.Empresa);
  for Indice := 0 to High(FAlmacenes) do
    FDestino.Properties.Items.Add(FAlmacenes[Indice].Codigo + ' - ' +
      FAlmacenes[Indice].Nombre);
  if Length(FAlmacenes) = 1 then
    FDestino.ItemIndex := 0;
  Etiqueta := TcxLabel.Create(Self);
  Etiqueta.Parent := Cabecera;
  Etiqueta.Caption := SDestinoTicketRetirada;
  Etiqueta.SetBounds(ScaleValue(8), ScaleValue(46), 105, 22);
  FUrgente := TcxCheckBox.Create(Self);
  FUrgente.Parent := Cabecera;
  FUrgente.Caption := SEtiquetaUrgenteRetirada;
  FUrgente.SetBounds(ScaleValue(120), ScaleValue(82), ScaleValue(400), 24);
  FUrgente.Checked := FOrden.EsUrgente;
end;

procedure TfrmModalRetiradaLotes.CrearRejilla;
const
  TITULOS: array[0..3] of string = ('SKU', 'Lote / serie',
    'Almacén origen', 'Unidades a retirar');
var
  Rejilla: TcxGrid;
  Columna: TcxGridColumn;
  Indice: Integer;
begin
  Rejilla := TcxGrid.Create(Self);
  Rejilla.Parent := pnlBody;
  Rejilla.Align := alClient;
  FVista := Rejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  Rejilla.Levels.Add.GridView := FVista;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsView.ColumnAutoWidth := True;
  for Indice := 0 to High(TITULOS) do
  begin
    Columna := FVista.CreateColumn;
    Columna.Caption := TITULOS[Indice];
    Columna.DataBinding.ValueTypeClass := TcxStringValueType;
    Columna.Options.Editing := Indice = 3;
  end;
  FVista.Columns[3].DataBinding.ValueTypeClass := TcxFloatValueType;
  FVista.Columns[3].PropertiesClass := TcxCurrencyEditProperties;
  TcxCurrencyEditProperties(FVista.Columns[3].Properties).DecimalPlaces := 6;
  TcxCurrencyEditProperties(FVista.Columns[3].Properties).DisplayFormat :=
    '#,##0.######';
  FVista.DataController.RecordCount := Length(FOrden.Lineas);
  for Indice := 0 to High(FOrden.Lineas) do
  begin
    FVista.DataController.Values[Indice, 0] := FOrden.Lineas[Indice].CodigoSku;
    FVista.DataController.Values[Indice, 1] := FOrden.Lineas[Indice].Lote;
    FVista.DataController.Values[Indice, 2] :=
      FOrden.Lineas[Indice].CodigoAlmacen;
    FVista.DataController.Values[Indice, 3] := FOrden.Lineas[Indice].Cantidad;
  end;
end;

procedure TfrmModalRetiradaLotes.Recoger;
var
  Indice: Integer;
begin
  FVista.DataController.PostEditingData;
  FOrden.Empleado := Trim(FEmpleado.Text);
  FOrden.Motivo := TMotivoRetiradaLote(FMotivo.ItemIndex);
  FOrden.EsUrgente := FUrgente.Checked;
  FOrden.AlmacenDestino := '';
  if (FDestino.ItemIndex >= 0) and
     (FDestino.ItemIndex <= High(FAlmacenes)) then
    FOrden.AlmacenDestino := FAlmacenes[FDestino.ItemIndex].Codigo;
  for Indice := 0 to High(FOrden.Lineas) do
    FOrden.Lineas[Indice].Cantidad :=
      FVista.DataController.Values[Indice, 3];
end;

function TfrmModalRetiradaLotes.CloseQuery: Boolean;
var
  Error: string;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') and not FGuardada then
  begin
    Result := False;
    try
      Recoger;
      Error := ValidarOrdenRetirada(FOrden);
      if Error <> '' then
        raise Exception.Create(Error);
      if MessageDlg_fza(SPreguntaRegistrarRetirada, mtConfirmation,
         [mbYes, mbNo], 0) = mrYes then
      begin
        FOrden := FRepositorio.Guardar(FOrden);
        FGuardada := True;
        PreguntarImpresion(FOrden);
        Result := True;
      end;
    except
      on E: Exception do
        ShowMessage_fza(E.Message);
    end;
    if not Result then
      sFicha := 'N';
  end;
end;

function TfrmModalRetiradaLotes.ConfirmarImpresion(
  const AOrden: TOrdenRetiradaLotes): Boolean;
begin
  Result := MessageDlg_fza(Format(SPreguntaImprimirRetirada, [AOrden.Id]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmModalRetiradaLotes.EnviarTicket(
  const AOrden: TOrdenRetiradaLotes);
begin
  if not Assigned(ParametrosCaja) then
    raise Exception.Create('Parámetros de caja no disponibles.');
  ImprimirTicketRetirada(PreviewTicket, AOrden,
    ParametrosCaja.ImpresoraCaja,
    ParametrosCaja.GetString(PARAMETRO_FORMATO_RETIRADA_LOTES, 'TEXTO42'));
end;

procedure TfrmModalRetiradaLotes.PreguntarImpresion(
  const AOrden: TOrdenRetiradaLotes);
begin
  if ConfirmarImpresion(AOrden) then
    try
      EnviarTicket(AOrden);
    except
      on E: Exception do
        ShowMessage_fza(Format(SErrorRetiradaImpresion,
          [AOrden.Id, E.Message]));
    end;
end;

procedure TfrmModalRetiradaLotes.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalRetiradaLotes.Ejecutar(AOwner: TComponent;
  AConexion: TUniConnection; const AOrden: TOrdenRetiradaLotes): Boolean;
var
  Formulario: TfrmModalRetiradaLotes;
begin
  Formulario := TfrmModalRetiradaLotes.CreateRetirada(
    AOwner, AConexion, AOrden);
  try
    Formulario.ShowModal;
    Result := Formulario.FGuardada;
  finally
    Formulario.Free;
  end;
end;

class procedure TfrmModalRetiradaLotes.Reimprimir(AOwner: TComponent;
  AConexion: TUniConnection; const AEmpresa, AMovimiento: string);
var
  Formulario: TfrmModalRetiradaLotes;
  Repositorio: IRepositorioRetiradaLotes;
  Orden: TOrdenRetiradaLotes;
begin
  Repositorio := TRepositorioRetiradaLotes.Create(AConexion, AEmpresa);
  Orden := Repositorio.LeerPorMovimiento(AMovimiento);
  Formulario := TfrmModalRetiradaLotes.CreateRetirada(AOwner, AConexion, Orden);
  try
    Formulario.PreguntarImpresion(Orden);
  finally
    Formulario.Free;
  end;
end;

end.
