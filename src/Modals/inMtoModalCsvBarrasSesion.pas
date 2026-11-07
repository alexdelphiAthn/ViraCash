{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalCsvBarrasSesion                                     }
{  Versión:      1.0.0                                                         }
{  Fecha:        06/11/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Códigos de barras de fabricante en sesiones de compra.        }
{******************************************************************************}
unit inMtoModalCsvBarrasSesion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms,
  cxGridTableView, cxDropDownEdit, cxCheckBox,
  inMtoModalAceptCancel, inLibCodigosBarrasSesion;

type
  TfrmModalCsvBarrasSesion = class(TfrmModalAceptCancel)
  private
    FTexto: string;
    FFilas: TFilasCsvBarras;
    FOriginales: TCombinacionesBarrasSesion;
    FResultado: TCombinacionesBarrasSesion;
    FVista: TcxGridTableView;
    FColumna: TcxComboBox;
    FSeparador: TcxComboBox;
    FCabecera: TcxCheckBox;
    FArticulo: TcxComboBox;
    FIdentificar: TcxComboBox;
    FColor: TcxComboBox;
    FTalla: TcxComboBox;
    FColorFijo: TcxComboBox;
    FPreparando: Boolean;
    procedure CrearControles;
    procedure CargarCsv;
    procedure OpcionesCambiadas(Sender: TObject);
    procedure ColumnaColorCambiada(Sender: TObject);
    procedure IdentificacionCambiada(Sender: TObject);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
    procedure LlenarColumnas(ACombo: TcxComboBox;
      const ANombres: array of string; AOpcional: Boolean);
  public
    class function Ejecutar(AOwner: TComponent; const ATexto: string;
      const AValores: TCombinacionesBarrasSesion;
      out AResultado: TCombinacionesBarrasSesion): Boolean;
    function CloseQuery: Boolean; override;
  end;

implementation

uses
  System.SysUtils, System.Math, Vcl.Graphics,
  cxGrid, cxGridCustomTableView, cxCustomData, cxDataStorage,
  cxLabel, cxGroupBox,
  inLibMsgBarrasSesion, inLibMensajesVcl;

function CrearCombo(AOwner: TComponent; AParent: TWinControl;
  const ATitulo: string; AIzquierda, AArriba, AAncho: Integer): TcxComboBox;
var
  oEtiqueta: TcxLabel;
begin
  oEtiqueta := TcxLabel.Create(AOwner);
  oEtiqueta.Parent := AParent;
  oEtiqueta.Transparent := True;
  oEtiqueta.SetBounds(AIzquierda, AArriba, AAncho, 20);
  oEtiqueta.Caption := ATitulo;
  Result := TcxComboBox.Create(AOwner);
  Result.Parent := AParent;
  Result.SetBounds(AIzquierda, AArriba + 22, AAncho, 24);
  Result.Properties.DropDownListStyle := lsFixedList;
end;

procedure TfrmModalCsvBarrasSesion.CrearControles;
var
  oPanel: TcxGroupBox;
  oAyuda: TcxLabel;
  oRejilla: TcxGrid;
  v: TCombinacionBarrasSesion;
  sColor: string;
begin
  oPanel := TcxGroupBox.Create(Self);
  oPanel.Parent := pnlBody;
  oPanel.PanelStyle.Active := True;
  oPanel.Align := alTop;
  oPanel.Height := 210;
  FColumna := CrearCombo(Self, oPanel, SBarrasColumna, 12, 6, 260);
  FColumna.Name := 'cbbColumnaBarras';
  FSeparador := CrearCombo(Self, oPanel, SBarrasSeparador, 290, 6, 130);
  FSeparador.Name := 'cbbSeparadorCsv';
  FSeparador.Properties.Items.Add(';');
  FSeparador.Properties.Items.Add(',');
  FSeparador.Properties.Items.Add('TAB');
  FCabecera := TcxCheckBox.Create(Self);
  FCabecera.Parent := oPanel;
  FCabecera.SetBounds(440, 28, 310, 24);
  FCabecera.Caption := SBarrasCabecera;
  FCabecera.Checked := True;
  FIdentificar := CrearCombo(Self, oPanel, SBarrasIdentificarPor,
    752, 6, 210);
  FIdentificar.Name := 'cbbIdentificarArticuloCsv';
  FIdentificar.Properties.Items.Add(SBarrasModeloProveedor);
  FIdentificar.Properties.Items.Add(SBarrasCodigoInterno);
  FIdentificar.ItemIndex := 0;
  FIdentificar.Properties.OnChange := IdentificacionCambiada;
  FArticulo := CrearCombo(Self, oPanel, SBarrasColumnaArticulo,
    12, 60, 300);
  FArticulo.Name := 'cbbArticuloBarras';
  FColor := CrearCombo(Self, oPanel, SBarrasColor, 330, 60, 300);
  FColor.Name := 'cbbColorBarras';
  FTalla := CrearCombo(Self, oPanel, SBarrasTalla, 648, 60, 300);
  FTalla.Name := 'cbbTallaBarras';
  FColorFijo := CrearCombo(Self, oPanel, SBarrasColorFijo, 12, 114, 400);
  FColorFijo.Name := 'cbbColorFijoBarras';
  FColorFijo.Properties.Items.Add(SBarrasColorAutomatico);
  for v in FOriginales do
  begin
    sColor := ColorCombinacionBarras(v);
    if FColorFijo.Properties.Items.IndexOf(sColor) < 0 then
      FColorFijo.Properties.Items.Add(sColor);
  end;
  FColorFijo.ItemIndex := 0;
  FColor.Properties.OnChange := ColumnaColorCambiada;
  oAyuda := TcxLabel.Create(Self);
  oAyuda.Parent := oPanel;
  oAyuda.Transparent := True;
  oAyuda.SetBounds(12, 168, 936, 38);
  oAyuda.Properties.WordWrap := True;
  oAyuda.Caption := SBarrasAyuda;
  oRejilla := TcxGrid.Create(Self);
  oRejilla.Name := 'cxgrdCsvBarras';
  oRejilla.Parent := pnlBody;
  oRejilla.Align := alClient;
  FVista := oRejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  FVista.Name := 'tvCsvBarras';
  oRejilla.Levels.Add.GridView := FVista;
  FVista.OptionsData.Editing := False;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsView.ColumnAutoWidth := True;
  FVista.OptionsCustomize.ColumnSorting := False;
end;

function NormalizarCabecera(const ATexto: string): string;
begin
  Result := LowerCase(Trim(ATexto));
  Result := StringReplace(Result, 'ó', 'o', [rfReplaceAll]);
  Result := StringReplace(Result, 'í', 'i', [rfReplaceAll]);
  Result := StringReplace(Result, '_', ' ', [rfReplaceAll]);
end;

procedure TfrmModalCsvBarrasSesion.LlenarColumnas(ACombo: TcxComboBox;
  const ANombres: array of string; AOpcional: Boolean);
var
  i: Integer;
  sNombre: string;
begin
  ACombo.Properties.Items.Clear;
  ACombo.Properties.Items.Add(SBarrasSinColumna);
  for i := 0 to FVista.ItemCount - 1 do
    ACombo.Properties.Items.Add(FVista.Items[i].Caption);
  ACombo.ItemIndex := 0;
  if FCabecera.Checked then
    for sNombre in ANombres do
      for i := 0 to High(FFilas[0]) do
        if (ACombo.ItemIndex = 0) and
          (NormalizarCabecera(FFilas[0][i]) = sNombre) then
          ACombo.ItemIndex := i + 1;
  if not AOpcional and (ACombo.ItemIndex = 0) and
    (ACombo = FColumna) and (FVista.ItemCount > 0) then
    ACombo.ItemIndex := 1;
end;

procedure TfrmModalCsvBarrasSesion.CargarCsv;
var
  c: Char;
  i, j, n, nColumnas: Integer;
  oColumna: TcxGridColumn;
begin
  c := ';';
  case FSeparador.ItemIndex of
    1: c := ',';
    2: c := #9;
  end;
  FFilas := LeerCsvBarras(FTexto, c);
  n := Ord(FCabecera.Checked);
  if Length(FFilas) <= n then
    raise EArgumentException.Create(SBarrasCsvVacio);
  nColumnas := 0;
  for i := 0 to High(FFilas) do
    nColumnas := Max(nColumnas, Length(FFilas[i]));
  FVista.BeginUpdate;
  try
    FVista.ClearItems;
    for j := 0 to nColumnas - 1 do
    begin
      oColumna := FVista.CreateColumn;
      oColumna.DataBinding.ValueType := 'String';
      oColumna.Width := 200;
      oColumna.Caption := Format(SBarrasColumnaNumero, [j + 1]);
      if FCabecera.Checked and (j < Length(FFilas[0])) then
        oColumna.Caption := oColumna.Caption + ' - ' + FFilas[0][j];
    end;
    FVista.DataController.RecordCount := Length(FFilas) - n;
    for i := n to High(FFilas) do
      for j := 0 to High(FFilas[i]) do
        FVista.DataController.Values[i - n, j] := FFilas[i][j];
  finally
    FVista.EndUpdate;
  end;
  LlenarColumnas(FColumna,
    ['codigo de barras', 'codigo barras', 'ean', 'ean13', 'barcode'], False);
  IdentificacionCambiada(nil);
  LlenarColumnas(FColor, ['color / variante', 'color', 'variante'], True);
  LlenarColumnas(FTalla, ['talla'], True);
  ColumnaColorCambiada(nil);
end;

procedure TfrmModalCsvBarrasSesion.IdentificacionCambiada(Sender: TObject);
begin
  if FIdentificar.ItemIndex = 0 then
    LlenarColumnas(FArticulo, ['modelo', 'modelo proveedor', 'modelo prov.',
      'modelo del proveedor', 'referencia proveedor',
      'referencia del proveedor', 'ref proveedor', 'ref. proveedor',
      'referencia', 'articulo', 'codigo de articulo', 'codigo articulo'],
      False)
  else
    LlenarColumnas(FArticulo, ['codigo interno', 'codigo de articulo',
      'codigo articulo', 'articulo'], False);
end;

procedure TfrmModalCsvBarrasSesion.ColumnaColorCambiada(Sender: TObject);
begin
  FColorFijo.Enabled := FColor.ItemIndex = 0;
end;

procedure TfrmModalCsvBarrasSesion.OpcionesCambiadas(Sender: TObject);
begin
  if not FPreparando then
  begin
    FPreparando := True;
    try
      CargarCsv;
    finally
      FPreparando := False;
    end;
  end;
end;

function TfrmModalCsvBarrasSesion.CloseQuery: Boolean;
var
  sColorFijo: string;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    try
      sColorFijo := '';
      if FColorFijo.Enabled and (FColorFijo.ItemIndex > 0) then
        sColorFijo := FColorFijo.Text;
      FResultado := ImportarCsvBarrasSesion(FFilas, FOriginales,
        Ord(FCabecera.Checked), FColumna.ItemIndex - 1,
        FArticulo.ItemIndex - 1, FColor.ItemIndex - 1,
        FTalla.ItemIndex - 1, sColorFijo, FIdentificar.ItemIndex = 0);
    except
      on E: Exception do
      begin
        ShowMessage_fza(E.Message);
        Result := False;
      end;
    end;
  end;
end;

procedure TfrmModalCsvBarrasSesion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalCsvBarrasSesion.Ejecutar(AOwner: TComponent;
  const ATexto: string; const AValores: TCombinacionesBarrasSesion;
  out AResultado: TCombinacionesBarrasSesion): Boolean;
var
  oFormulario: TfrmModalCsvBarrasSesion;
begin
  oFormulario := TfrmModalCsvBarrasSesion.Create(AOwner);
  try
    oFormulario.FPreparando := True;
    oFormulario.FTexto := ATexto;
    oFormulario.FOriginales := Copy(AValores);
    oFormulario.Caption := SBarrasImportar;
    oFormulario.Font.Name := 'Segoe UI';
    oFormulario.Font.Size := 9;
    oFormulario.Font.Style := [];
    oFormulario.ClientWidth := 980;
    oFormulario.ClientHeight := 600;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.CrearControles;
    oFormulario.FSeparador.ItemIndex := 0;
    case DetectarSeparadorBarras(ATexto) of
      ',': oFormulario.FSeparador.ItemIndex := 1;
      #9: oFormulario.FSeparador.ItemIndex := 2;
    end;
    oFormulario.CargarCsv;
    oFormulario.FSeparador.Properties.OnChange :=
      oFormulario.OpcionesCambiadas;
    oFormulario.FCabecera.Properties.OnChange :=
      oFormulario.OpcionesCambiadas;
    oFormulario.FPreparando := False;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
    if Result then
      AResultado := oFormulario.FResultado;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
