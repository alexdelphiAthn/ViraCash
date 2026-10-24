{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalSepaRemesaVenta                                    }
{    Tipo:       Modal                                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Edición previa de datos SEPA para remesas de venta.                      }
{******************************************************************************}
unit inMtoModalSepaRemesaVenta;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Data.DB, Datasnap.DBClient, cxClasses, cxControls, cxContainer, cxEdit,
  cxTextEdit, cxDropDownEdit, cxMaskEdit, cxCalendar, cxLabel, cxButtons,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxGrid, cxGridLevel, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  inLibSepaRemesasVenta;

type
  // TDatosSepaRemesaVenta y sus tipos auxiliares viven ahora en
  // inLibSepaRemesasVenta, compartidos con UniDataRemesasVenta.
  TfrmModalSepaRemesaVenta = class(TForm)
  private
    FCbbTipoSecuencia: TcxComboBox;
    FCdsClientes: TClientDataSet;
    FDatos: TDatosSepaRemesaVenta;
    FDsClientes: TDataSource;
    FEdtCodigoAcreedor: TcxTextEdit;
    FGrid: TcxGrid;
    FTvClientes: TcxGridDBTableView;
    procedure btnAceptarClick(Sender: TObject);
    procedure CargarDatos;
    procedure CrearCampos;
    procedure CrearColumnas;
    procedure CrearControles;
    procedure DescargarDatos;
    function DatosValidos: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    class function Ejecutar(var ADatos: TDatosSepaRemesaVenta): Boolean;
  end;

implementation

uses
  inLibMensajesVcl,
  Vcl.Dialogs, inLibMsgComun, inLibMsgVentas;

resourcestring
  STituloDatosSepaRemesa = 'Datos SEPA de la remesa';

function LimpiarValorSepa(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));
end;

function TipoSecuenciaValido(const AValor: string): Boolean;
var
  sValor: string;
begin
  sValor := LimpiarValorSepa(AValor);
  Result := (sValor = 'FRST') or (sValor = 'RCUR') or
            (sValor = 'OOFF') or (sValor = 'FNAL');
end;

constructor TfrmModalSepaRemesaVenta.Create(AOwner: TComponent);
begin
  // Modal programatico: no hay .dfm que cargar.
  inherited CreateNew(AOwner);
  BorderStyle := bsDialog;
  Caption := STituloDatosSepaRemesa;
  ClientHeight := 520;
  ClientWidth := 900;
  Position := poScreenCenter;
  FCdsClientes := TClientDataSet.Create(Self);
  FDsClientes := TDataSource.Create(Self);
  FDsClientes.DataSet := FCdsClientes;
  CrearCampos;
  CrearControles;
end;

procedure TfrmModalSepaRemesaVenta.CrearCampos;
begin
  FCdsClientes.FieldDefs.Add('CODIGO_CLI', ftString, 20);
  FCdsClientes.FieldDefs.Add('NOMBRE_CLI', ftString, 200);
  FCdsClientes.FieldDefs.Add('ID_MANDATO', ftString, 35);
  FCdsClientes.FieldDefs.Add('FECHA_FIRMA', ftDate);
  FCdsClientes.CreateDataSet;
end;

procedure TfrmModalSepaRemesaVenta.CrearControles;
var
  btnAceptar: TcxButton;
  btnCancelar: TcxButton;
  lblAcreedor: TcxLabel;
  lblClientes: TcxLabel;
  lblSecuencia: TcxLabel;
  pnlBotones: TPanel;
begin
  lblAcreedor := TcxLabel.Create(Self);
  lblAcreedor.Parent := Self;
  lblAcreedor.Left := 16;
  lblAcreedor.Top := 14;
  lblAcreedor.Caption := SCaptionCodigoAcreedor;
  FEdtCodigoAcreedor := TcxTextEdit.Create(Self);
  FEdtCodigoAcreedor.Parent := Self;
  FEdtCodigoAcreedor.Left := 16;
  FEdtCodigoAcreedor.Top := 40;
  FEdtCodigoAcreedor.Width := 320;
  FEdtCodigoAcreedor.Properties.MaxLength := 35;
  lblSecuencia := TcxLabel.Create(Self);
  lblSecuencia.Parent := Self;
  lblSecuencia.Left := 360;
  lblSecuencia.Top := 14;
  lblSecuencia.Caption := SCaptionSecuencia;
  FCbbTipoSecuencia := TcxComboBox.Create(Self);
  FCbbTipoSecuencia.Parent := Self;
  FCbbTipoSecuencia.Left := 360;
  FCbbTipoSecuencia.Top := 40;
  FCbbTipoSecuencia.Width := 120;
  FCbbTipoSecuencia.Properties.DropDownListStyle := lsFixedList;
  FCbbTipoSecuencia.Properties.Items.Add('FRST');
  FCbbTipoSecuencia.Properties.Items.Add('RCUR');
  FCbbTipoSecuencia.Properties.Items.Add('OOFF');
  FCbbTipoSecuencia.Properties.Items.Add('FNAL');
  lblClientes := TcxLabel.Create(Self);
  lblClientes.Parent := Self;
  lblClientes.Left := 16;
  lblClientes.Top := 82;
  lblClientes.Caption := SCaptionMandatosPorCliente;
  FGrid := TcxGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Left := 16;
  FGrid.Top := 112;
  FGrid.Width := 868;
  FGrid.Height := 340;
  FGrid.Anchors := [akLeft, akTop, akRight, akBottom];
  FTvClientes := FGrid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  FTvClientes.DataController.DataSource := FDsClientes;
  FTvClientes.OptionsData.Appending := False;
  FTvClientes.OptionsData.Deleting := False;
  FTvClientes.OptionsView.GroupByBox := False;
  FGrid.Levels.Add.GridView := FTvClientes;
  CrearColumnas;
  pnlBotones := TPanel.Create(Self);
  pnlBotones.Parent := Self;
  pnlBotones.Align := alBottom;
  pnlBotones.Height := 56;
  pnlBotones.BevelOuter := bvNone;
  btnCancelar := TcxButton.Create(Self);
  btnCancelar.Parent := pnlBotones;
  btnCancelar.Left := 692;
  btnCancelar.Top := 10;
  btnCancelar.Width := 90;
  btnCancelar.Height := 34;
  btnCancelar.Caption := SCaptionCancelar;
  btnCancelar.ModalResult := mrCancel;
  btnAceptar := TcxButton.Create(Self);
  btnAceptar.Parent := pnlBotones;
  btnAceptar.Left := 794;
  btnAceptar.Top := 10;
  btnAceptar.Width := 90;
  btnAceptar.Height := 34;
  btnAceptar.Caption := SCaptionAceptar;
  btnAceptar.OnClick := btnAceptarClick;
end;

procedure TfrmModalSepaRemesaVenta.CrearColumnas;
var
  oCol: TcxGridDBColumn;
begin
  oCol := FTvClientes.CreateColumn;
  oCol.Caption := SCaptionColCodigoMandato;
  oCol.DataBinding.FieldName := 'CODIGO_CLI';
  oCol.Options.Editing := False;
  oCol.Width := 90;
  oCol := FTvClientes.CreateColumn;
  oCol.Caption := SCaptionColClienteMandato;
  oCol.DataBinding.FieldName := 'NOMBRE_CLI';
  oCol.Options.Editing := False;
  oCol.Width := 300;
  oCol := FTvClientes.CreateColumn;
  oCol.Caption := SCaptionColMandato;
  oCol.DataBinding.FieldName := 'ID_MANDATO';
  oCol.Width := 220;
  oCol := FTvClientes.CreateColumn;
  oCol.Caption := SCaptionColFechaFirmaMandato;
  oCol.DataBinding.FieldName := 'FECHA_FIRMA';
  oCol.PropertiesClassName := 'TcxDateEditProperties';
  oCol.Width := 120;
end;

procedure TfrmModalSepaRemesaVenta.CargarDatos;
var
  i: Integer;
begin
  FEdtCodigoAcreedor.Text := LimpiarValorSepa(FDatos.CodigoAcreedor);
  FCbbTipoSecuencia.Text := LimpiarValorSepa(FDatos.TipoSecuencia);
  if FCbbTipoSecuencia.Text = '' then
    FCbbTipoSecuencia.Text := 'RCUR';
  FCdsClientes.DisableControls;
  try
    FCdsClientes.EmptyDataSet;
    for i := 0 to Length(FDatos.Clientes) - 1 do
    begin
      FCdsClientes.Append;
      FCdsClientes.FieldByName('CODIGO_CLI').AsString :=
        FDatos.Clientes[i].CodigoCliente;
      FCdsClientes.FieldByName('NOMBRE_CLI').AsString :=
        FDatos.Clientes[i].NombreCliente;
      FCdsClientes.FieldByName('ID_MANDATO').AsString :=
        FDatos.Clientes[i].IdMandato;
      if FDatos.Clientes[i].FechaFirma > 0 then
        FCdsClientes.FieldByName('FECHA_FIRMA').AsDateTime :=
          FDatos.Clientes[i].FechaFirma;
      FCdsClientes.Post;
    end;
    FCdsClientes.First;
  finally
    FCdsClientes.EnableControls;
  end;
end;

procedure TfrmModalSepaRemesaVenta.DescargarDatos;
var
  i: Integer;
begin
  if FCdsClientes.State in dsEditModes then
    FCdsClientes.Post;
  FDatos.CodigoAcreedor := LimpiarValorSepa(FEdtCodigoAcreedor.Text);
  FDatos.TipoSecuencia := LimpiarValorSepa(FCbbTipoSecuencia.Text);
  SetLength(FDatos.Clientes, FCdsClientes.RecordCount);
  i := 0;
  FCdsClientes.First;
  while not FCdsClientes.Eof do
  begin
    FDatos.Clientes[i].CodigoCliente :=
      FCdsClientes.FieldByName('CODIGO_CLI').AsString;
    FDatos.Clientes[i].NombreCliente :=
      FCdsClientes.FieldByName('NOMBRE_CLI').AsString;
    FDatos.Clientes[i].IdMandato :=
      LimpiarValorSepa(FCdsClientes.FieldByName('ID_MANDATO').AsString);
    if not FCdsClientes.FieldByName('FECHA_FIRMA').IsNull then
      FDatos.Clientes[i].FechaFirma :=
        FCdsClientes.FieldByName('FECHA_FIRMA').AsDateTime
    else
      FDatos.Clientes[i].FechaFirma := 0;
    Inc(i);
    FCdsClientes.Next;
  end;
end;

function TfrmModalSepaRemesaVenta.DatosValidos: Boolean;
begin
  Result := False;
  if Trim(FEdtCodigoAcreedor.Text) = '' then
    ShowMessage_fza(SErrorCodigoAcreedorSepaNoIndicado)
  else if Length(Trim(FEdtCodigoAcreedor.Text)) > 35 then
    ShowMessage_fza(SErrorLongitudCodigoAcreedorSepa)
  else if not CodigoAcreedorSepaValido(FEdtCodigoAcreedor.Text) then
    ShowMessage_fza(SErrorFormatoCodigoAcreedorSepaNoValido)
  else if not TipoSecuenciaValido(FCbbTipoSecuencia.Text) then
    ShowMessage_fza(SErrorSecuenciaSepaNoValida)
  else
  begin
    Result := True;
    if FCdsClientes.State in dsEditModes then
      FCdsClientes.Post;
    FCdsClientes.First;
    while (not FCdsClientes.Eof) and Result do
    begin
      if Trim(FCdsClientes.FieldByName('ID_MANDATO').AsString) = '' then
      begin
        Result := False;
        ShowMessage_fza(SErrorClientesSinMandatoSepa);
      end
      else if Length(Trim(FCdsClientes.FieldByName('ID_MANDATO').AsString)) >
              35 then
      begin
        Result := False;
        ShowMessage_fza(SErrorMandatosSepaLongitudNoValida);
      end
      else if FCdsClientes.FieldByName('FECHA_FIRMA').IsNull then
      begin
        Result := False;
        ShowMessage_fza(SErrorClientesSinFechaFirmaMandatoSepa);
      end;
      if Result then
        FCdsClientes.Next;
    end;
  end;
end;

procedure TfrmModalSepaRemesaVenta.btnAceptarClick(Sender: TObject);
begin
  if DatosValidos then
  begin
    DescargarDatos;
    ModalResult := mrOk;
  end;
end;

class function TfrmModalSepaRemesaVenta.Ejecutar(
  var ADatos: TDatosSepaRemesaVenta): Boolean;
var
  frm: TfrmModalSepaRemesaVenta;
begin
  frm := TfrmModalSepaRemesaVenta.Create(nil);
  try
    frm.FDatos := ADatos;
    frm.CargarDatos;
    Result := frm.ShowModal = mrOk;
    if Result then
      ADatos := frm.FDatos;
  finally
    frm.Free;
  end;
end;

end.
