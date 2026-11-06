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
    FAsignaciones: TArray<Integer>;
    FVista: TcxGridTableView;
    FColumna: TcxComboBox;
    FSeparador: TcxComboBox;
    FCabecera: TcxCheckBox;
    FArticulo: TcxComboBox;
    FColor: TcxComboBox;
    FTalla: TcxComboBox;
    FNumeroColumnas: Integer;
    FPreparando: Boolean;
    procedure CrearControles;
    procedure CrearRejilla;
    procedure CargarCsv;
    procedure MostrarCsv;
    procedure OpcionesCambiadas(Sender: TObject);
    procedure ColumnaCambiada(Sender: TObject);
    procedure ArticuloCambiado(Sender: TObject);
    procedure ColorCambiado(Sender: TObject);
    procedure AsignarClick(Sender: TObject);
    procedure AsignarFila(AFila: Integer);
    procedure QuitarClick(Sender: TObject);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
    function ArticuloCombo(const AValor: TCombinacionBarrasSesion): string;
    function TallaCombo(const AValor: TCombinacionBarrasSesion): string;
    function CodigoFila(AFila: Integer): string;
    function Recoger: TCombinacionesBarrasSesion;
    procedure MostrarAsignacion(AFila: Integer);
  public
    class function Ejecutar(AOwner: TComponent; const ATexto: string;
      const AValores: TCombinacionesBarrasSesion;
      out AResultado: TCombinacionesBarrasSesion): Boolean;
    function CloseQuery: Boolean; override;
  end;

implementation

uses
  System.SysUtils, System.Variants, System.Math,
  cxGrid, cxCustomData, cxDataStorage, cxButtons, cxLabel, cxGroupBox,
  inLibMsgBarrasSesion, inLibMensajesVcl;

procedure AnadirUnico(ACombo: TcxComboBox; const ATexto: string);
begin
  if ACombo.Properties.Items.IndexOf(ATexto) < 0 then
    ACombo.Properties.Items.Add(ATexto);
end;

function CrearCombo(AOwner: TComponent; AParent: TWinControl;
  const ATitulo: string; AIzquierda, AArriba, AAncho: Integer): TcxComboBox;
var
  oEtiqueta: TcxLabel;
begin
  oEtiqueta := TcxLabel.Create(AOwner);
  oEtiqueta.Parent := AParent;
  oEtiqueta.Transparent := True;
  oEtiqueta.SetBounds(AIzquierda, AArriba, AAncho, 22);
  oEtiqueta.Caption := ATitulo;
  Result := TcxComboBox.Create(AOwner);
  Result.Parent := AParent;
  Result.SetBounds(AIzquierda, AArriba + 24, AAncho, 26);
  Result.Properties.DropDownListStyle := lsFixedList;
end;

procedure TfrmModalCsvBarrasSesion.CrearControles;
var
  oPanel: TcxGroupBox;
  oBoton: TcxButton;
  oAyuda: TcxLabel;
begin
  oPanel := TcxGroupBox.Create(Self);
  oPanel.Parent := pnlBody;
  oPanel.PanelStyle.Active := True;
  oPanel.Align := alTop;
  oPanel.Height := 205;
  FColumna := CrearCombo(Self, oPanel, SBarrasColumna, 12, 8, 240);
  FColumna.Name := 'cbbColumnaBarras';
  FSeparador := CrearCombo(Self, oPanel, SBarrasSeparador, 270, 8, 130);
  FSeparador.Name := 'cbbSeparadorCsv';
  FSeparador.Properties.Items.Add(';');
  FSeparador.Properties.Items.Add(',');
  FSeparador.Properties.Items.Add('TAB');
  FCabecera := TcxCheckBox.Create(Self);
  FCabecera.Parent := oPanel;
  FCabecera.SetBounds(420, 32, 310, 26);
  FCabecera.Caption := SBarrasCabecera;
  FCabecera.Checked := True;
  FArticulo := CrearCombo(Self, oPanel, SBarrasArticulo, 12, 66, 300);
  FArticulo.Name := 'cbbArticuloBarras';
  FColor := CrearCombo(Self, oPanel, SBarrasColor, 330, 66, 230);
  FColor.Name := 'cbbColorBarras';
  FTalla := CrearCombo(Self, oPanel, SBarrasTalla, 578, 66, 130);
  FTalla.Name := 'cbbTallaBarras';
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := oPanel;
  oBoton.SetBounds(12, 125, 300, 30);
  oBoton.Caption := SBarrasAsignar;
  oBoton.Name := 'btnAsignarBarras';
  oBoton.OnClick := AsignarClick;
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := oPanel;
  oBoton.SetBounds(330, 125, 230, 30);
  oBoton.Caption := SBarrasQuitar;
  oBoton.Name := 'btnQuitarBarras';
  oBoton.OnClick := QuitarClick;
  oAyuda := TcxLabel.Create(Self);
  oAyuda.Parent := oPanel;
  oAyuda.Transparent := True;
  oAyuda.SetBounds(12, 163, 950, 38);
  oAyuda.Properties.WordWrap := True;
  oAyuda.Caption := SBarrasAyuda;
  CrearRejilla;
end;

procedure TfrmModalCsvBarrasSesion.CrearRejilla;
var
  oRejilla: TcxGrid;
begin
  oRejilla := TcxGrid.Create(Self);
  oRejilla.Name := 'cxgrdCsvBarras';
  oRejilla.Parent := pnlBody;
  oRejilla.Align := alClient;
  FVista := oRejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  FVista.Name := 'tvCsvBarras';
  oRejilla.Levels.Add.GridView := FVista;
  FVista.OptionsData.Editing := False;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsCustomize.ColumnSorting := False;
end;

function TfrmModalCsvBarrasSesion.ArticuloCombo(
  const AValor: TCombinacionBarrasSesion): string;
begin
  Result := AValor.Articulo + ' - ' + AValor.Descripcion;
  if AValor.Articulo = '' then
    Result := Format('[%d] %s', [AValor.Linea, AValor.Descripcion]);
end;

function TfrmModalCsvBarrasSesion.TallaCombo(
  const AValor: TCombinacionBarrasSesion): string;
begin
  Result := AValor.Talla;
  if Result = '' then
    Result := SBarrasSinTalla;
end;

procedure TfrmModalCsvBarrasSesion.CargarCsv;
var
  c: Char;
  i, j: Integer;
  sTitulo: string;
begin
  c := ';';
  case FSeparador.ItemIndex of
    1: c := ',';
    2: c := #9;
  end;
  FFilas := LeerCsvBarras(FTexto, c);
  if Length(FFilas) = 0 then
    raise Exception.Create(SBarrasCsvVacio);
  FNumeroColumnas := 0;
  for i := 0 to High(FFilas) do
    FNumeroColumnas := Max(FNumeroColumnas, Length(FFilas[i]));
  FColumna.Properties.Items.Clear;
  for j := 0 to FNumeroColumnas - 1 do
  begin
    sTitulo := Format(SBarrasColumnaNumero, [j + 1]);
    if FCabecera.Checked and (j < Length(FFilas[0])) then
      sTitulo := sTitulo + ' - ' + FFilas[0][j];
    FColumna.Properties.Items.Add(sTitulo);
  end;
  FColumna.ItemIndex := 0;
  MostrarCsv;
end;

procedure TfrmModalCsvBarrasSesion.MostrarCsv;
var
  i, j, n: Integer;
  oColumna: TcxGridColumn;
begin
  FVista.BeginUpdate;
  try
    FVista.ClearItems;
    for j := 0 to FNumeroColumnas + 2 do
    begin
      oColumna := FVista.CreateColumn;
      oColumna.DataBinding.ValueType := 'String';
      oColumna.Width := 160;
      if j < FNumeroColumnas then
        oColumna.Caption := FColumna.Properties.Items[j]
      else
        case j - FNumeroColumnas of
          0: oColumna.Caption := SBarrasArticulo;
          1: oColumna.Caption := SBarrasColor;
          2: oColumna.Caption := SBarrasTalla;
        end;
    end;
    n := Ord(FCabecera.Checked);
    FVista.DataController.RecordCount := Length(FFilas) - n;
    SetLength(FAsignaciones, Length(FFilas) - n);
    for i := 0 to High(FAsignaciones) do
    begin
      FAsignaciones[i] := -1;
      for j := 0 to High(FFilas[i + n]) do
        FVista.DataController.Values[i, j] := FFilas[i + n][j];
    end;
  finally
    FVista.EndUpdate;
  end;
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

procedure TfrmModalCsvBarrasSesion.ColumnaCambiada(Sender: TObject);
var
  i: Integer;
begin
  if not FPreparando then
    for i := 0 to High(FAsignaciones) do
    begin
      FAsignaciones[i] := -1;
      MostrarAsignacion(i);
    end;
end;

procedure TfrmModalCsvBarrasSesion.ArticuloCambiado(Sender: TObject);
var
  v: TCombinacionBarrasSesion;
begin
  FColor.Properties.Items.Clear;
  FColor.ItemIndex := -1;
  FTalla.Properties.Items.Clear;
  FTalla.ItemIndex := -1;
  for v in FOriginales do
    if ArticuloCombo(v) = FArticulo.Text then
      AnadirUnico(FColor, ColorCombinacionBarras(v));
end;

procedure TfrmModalCsvBarrasSesion.ColorCambiado(Sender: TObject);
var
  v: TCombinacionBarrasSesion;
begin
  FTalla.Properties.Items.Clear;
  FTalla.ItemIndex := -1;
  for v in FOriginales do
    if (ArticuloCombo(v) = FArticulo.Text) and
      (ColorCombinacionBarras(v) = FColor.Text) then
      AnadirUnico(FTalla, TallaCombo(v));
end;

function TfrmModalCsvBarrasSesion.CodigoFila(AFila: Integer): string;
var
  n, iColumna: Integer;
begin
  n := AFila + Ord(FCabecera.Checked);
  iColumna := FColumna.ItemIndex;
  Result := '';
  if (n >= 0) and (n < Length(FFilas)) and (iColumna >= 0) then
    if iColumna < Length(FFilas[n]) then
      Result := Trim(FFilas[n][iColumna]);
end;

procedure TfrmModalCsvBarrasSesion.MostrarAsignacion(AFila: Integer);
var
  n: Integer;
begin
  n := FAsignaciones[AFila];
  FVista.DataController.Values[AFila, FNumeroColumnas] := '';
  FVista.DataController.Values[AFila, FNumeroColumnas + 1] := '';
  FVista.DataController.Values[AFila, FNumeroColumnas + 2] := '';
  if n >= 0 then
  begin
    FVista.DataController.Values[AFila, FNumeroColumnas] :=
      ArticuloCombo(FOriginales[n]);
    FVista.DataController.Values[AFila, FNumeroColumnas + 1] :=
      ColorCombinacionBarras(FOriginales[n]);
    FVista.DataController.Values[AFila, FNumeroColumnas + 2] :=
      TallaCombo(FOriginales[n]);
  end;
end;

procedure TfrmModalCsvBarrasSesion.AsignarClick(Sender: TObject);
begin
  AsignarFila(FVista.Controller.FocusedRecordIndex);
end;

procedure TfrmModalCsvBarrasSesion.AsignarFila(AFila: Integer);
var
  i, n, iFila: Integer;
  sCodigo: string;
begin
  iFila := AFila;
  if (iFila >= 0) and (iFila < Length(FAsignaciones)) then
  begin
    n := -1;
    for i := 0 to High(FOriginales) do
      if (ArticuloCombo(FOriginales[i]) = FArticulo.Text) and
        (ColorCombinacionBarras(FOriginales[i]) = FColor.Text) and
        (TallaCombo(FOriginales[i]) = FTalla.Text) then
      begin
        if n >= 0 then
          raise Exception.Create(SBarrasAmbigua);
        n := i;
      end;
    if n < 0 then
      raise Exception.Create(SBarrasSeleccion);
    sCodigo := CodigoFila(iFila);
    if sCodigo = '' then
      raise Exception.Create(SBarrasVacio);
    ValidarCodigoBarrasSesion(sCodigo);
    if (FOriginales[n].Codigo <> '') and
      (FOriginales[n].Codigo <> sCodigo) then
      raise Exception.Create(SBarrasOcupada);
    for i := 0 to High(FAsignaciones) do
      if (i <> iFila) and (FAsignaciones[i] >= 0) then
        if (FAsignaciones[i] = n) or SameText(CodigoFila(i), sCodigo) then
          raise Exception.CreateFmt(SBarrasDuplicado, [sCodigo]);
    FAsignaciones[iFila] := n;
    MostrarAsignacion(iFila);
  end;
end;

procedure TfrmModalCsvBarrasSesion.QuitarClick(Sender: TObject);
var
  i: Integer;
begin
  i := FVista.Controller.FocusedRecordIndex;
  if (i >= 0) and (i < Length(FAsignaciones)) then
  begin
    FAsignaciones[i] := -1;
    MostrarAsignacion(i);
  end;
end;

function TfrmModalCsvBarrasSesion.Recoger: TCombinacionesBarrasSesion;
var
  i, j, n: Integer;
begin
  Result := Copy(FOriginales);
  n := 0;
  for i := 0 to High(FAsignaciones) do
    if FAsignaciones[i] >= 0 then
    begin
      Result[FAsignaciones[i]].Codigo := CodigoFila(i);
      Inc(n);
    end;
  if n = 0 then
    raise Exception.Create(SBarrasSinAsignar);
  for i := 0 to High(Result) do
    if Result[i].Codigo <> '' then
      for j := 0 to i - 1 do
        if SameText(Result[i].Codigo, Result[j].Codigo) then
          raise Exception.CreateFmt(SBarrasDuplicado, [Result[i].Codigo]);
end;

function TfrmModalCsvBarrasSesion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    try
      Recoger;
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
  v: TCombinacionBarrasSesion;
begin
  oFormulario := TfrmModalCsvBarrasSesion.Create(AOwner);
  try
    oFormulario.FPreparando := True;
    oFormulario.FTexto := ATexto;
    oFormulario.FOriginales := Copy(AValores);
    oFormulario.Caption := SBarrasImportar;
    oFormulario.ClientWidth := 1000;
    oFormulario.ClientHeight := 650;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.CrearControles;
    oFormulario.FSeparador.ItemIndex := 0;
    case DetectarSeparadorBarras(ATexto) of
      ',': oFormulario.FSeparador.ItemIndex := 1;
      #9: oFormulario.FSeparador.ItemIndex := 2;
    end;
    oFormulario.CargarCsv;
    for v in AValores do
      AnadirUnico(oFormulario.FArticulo, oFormulario.ArticuloCombo(v));
    oFormulario.FArticulo.Properties.OnChange :=
      oFormulario.ArticuloCambiado;
    oFormulario.FColor.Properties.OnChange := oFormulario.ColorCambiado;
    oFormulario.FColumna.Properties.OnChange :=
      oFormulario.ColumnaCambiada;
    oFormulario.FSeparador.Properties.OnChange :=
      oFormulario.OpcionesCambiadas;
    oFormulario.FCabecera.Properties.OnChange :=
      oFormulario.OpcionesCambiadas;
    oFormulario.FPreparando := False;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
    if Result then
      AResultado := oFormulario.Recoger;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
