{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoComprasSesionesBarrasVcl                                 }
{  Versión:      1.0.0                                                         }
{  Fecha:        06/11/2026                                                    }
{  Autor:        Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:  Códigos de barras de fabricante en sesiones de compra.        }
{******************************************************************************}
unit inMtoComprasSesionesBarrasVcl;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Uni, cxPC,
  cxGridTableView, cxCustomData, cxButtons,
  cxLabel, cxGroupBox,
  inLibCodigosBarrasSesion;

type
  TBarrasSesionVcl = class
  private
    FOwner: TComponent;
    FPaginas: TcxPageControl;
    FPagina: TcxTabSheet;
    FVista: TcxGridTableView;
    FConexion: TUniConnection;
    FCabecera: TDataSet;
    FUsuario: string;
    FSerie: string;
    FNumero: string;
    FValores: TCombinacionesBarrasSesion;
    FCargando: Boolean;
    FActualizando: Boolean;
    FDisponible: Boolean;
    FAviso: TcxLabel;
    FBarra: TcxGroupBox;
    FPreparar: TProc;
    FPuedeEditar: TFunc<Boolean>;
    FBotonImportar: TcxButton;
    FBotonGenerar: TcxButton;
    procedure CrearControles;
    procedure CrearRejilla;
    procedure ImportarFichero(const AFichero: string);
    procedure Pintar;
    procedure CargarPagina;
    procedure ActualizarClick(Sender: TObject);
    procedure ImportarClick(Sender: TObject);
    procedure GenerarClick(Sender: TObject);
    procedure CeldaCambiada(ADataController: TcxCustomDataController;
      ARecordIndex, AItemIndex: Integer);
    function ContextoValido: Boolean;
    procedure ComprobarContexto;
  public
    constructor Create(AOwner: TComponent; APaginas: TcxPageControl;
      AConexion: TUniConnection; ACabecera: TDataSet;
      const AUsuario: string; const APreparar: TProc;
      const APuedeEditar: TFunc<Boolean>);
    destructor Destroy; override;
    procedure ActualizarPagina;
  end;

implementation

uses
  System.Variants, System.IOUtils, Vcl.Controls, Vcl.Dialogs,
  cxGrid, cxDataStorage,
  UniDataCodigosBarrasSesion, inMtoModalCsvBarrasSesion,
  inLibMsgBarrasSesion, inLibMensajesVcl;

constructor TBarrasSesionVcl.Create(AOwner: TComponent;
  APaginas: TcxPageControl; AConexion: TUniConnection;
  ACabecera: TDataSet; const AUsuario: string; const APreparar: TProc;
  const APuedeEditar: TFunc<Boolean>);
begin
  inherited Create;
  FOwner := AOwner;
  FPaginas := APaginas;
  FConexion := AConexion;
  FCabecera := ACabecera;
  FUsuario := AUsuario;
  FPreparar := APreparar;
  FPuedeEditar := APuedeEditar;
  FPagina := TcxTabSheet.Create(AOwner);
  FPagina.Name := 'tsCodigosBarrasSesion';
  FPagina.PageControl := APaginas;
  FPagina.Caption := SBarrasTitulo;
  CrearControles;
end;

destructor TBarrasSesionVcl.Destroy;
begin
  FreeAndNil(FPagina);
  inherited;
end;

procedure TBarrasSesionVcl.CrearControles;
var
  oBarra: TcxGroupBox;
  oBoton: TcxButton;
begin
  oBarra := TcxGroupBox.Create(FPagina);
  oBarra.Parent := FPagina;
  oBarra.PanelStyle.Active := True;
  oBarra.Align := alTop;
  oBarra.Height := 46;
  FBarra := oBarra;
  oBoton := TcxButton.Create(FPagina);
  oBoton.Parent := oBarra;
  oBoton.SetBounds(8, 8, 130, 30);
  oBoton.Caption := SBarrasActualizar;
  oBoton.OnClick := ActualizarClick;
  FBotonImportar := TcxButton.Create(FPagina);
  FBotonImportar.Name := 'btnImportarBarrasSesion';
  FBotonImportar.Parent := oBarra;
  FBotonImportar.SetBounds(148, 8, 150, 30);
  FBotonImportar.Caption := SBarrasImportar;
  FBotonImportar.OnClick := ImportarClick;
  FBotonGenerar := TcxButton.Create(FPagina);
  FBotonGenerar.Name := 'btnGenerarBarrasSesion';
  FBotonGenerar.Parent := oBarra;
  FBotonGenerar.SetBounds(308, 8, 190, 30);
  FBotonGenerar.Caption := SBarrasAutomatico;
  FBotonGenerar.OnClick := GenerarClick;
  FAviso := TcxLabel.Create(FPagina);
  FAviso.Name := 'lblMigracionBarrasSesion';
  FAviso.Parent := oBarra;
  FAviso.Transparent := True;
  FAviso.SetBounds(8, 44, 900, 42);
  FAviso.Properties.WordWrap := True;
  FAviso.Caption := SBarrasMigracion;
  FAviso.Visible := False;
  CrearRejilla;
end;

procedure TBarrasSesionVcl.CrearRejilla;
var
  oRejilla: TcxGrid;
  oColumna: TcxGridColumn;
  i: Integer;
begin
  oRejilla := TcxGrid.Create(FPagina);
  oRejilla.Parent := FPagina;
  oRejilla.Align := alClient;
  FVista := oRejilla.CreateView(TcxGridTableView) as TcxGridTableView;
  oRejilla.Levels.Add.GridView := FVista;
  FVista.OptionsView.GroupByBox := False;
  FVista.OptionsView.ColumnAutoWidth := True;
  for i := 0 to 6 do
  begin
    oColumna := FVista.CreateColumn;
    oColumna.DataBinding.ValueType := 'String';
    oColumna.Width := 150;
    oColumna.Options.Editing := i = 5;
    case i of
      0: oColumna.Caption := SBarrasLinea;
      1: oColumna.Caption := SBarrasArticulo;
      2: oColumna.Caption := SBarrasDescripcion;
      3: oColumna.Caption := SBarrasColor;
      4: oColumna.Caption := SBarrasTalla;
      5: oColumna.Caption := SBarrasCodigo;
      6: oColumna.Caption := SBarrasModeloProveedor;
    end;
  end;
  FVista.DataController.OnRecordChanged := CeldaCambiada;
end;

function TBarrasSesionVcl.ContextoValido: Boolean;
begin
  Result := FDisponible and FCabecera.Active and not FCabecera.IsEmpty and
    (FCabecera.State = dsBrowse) and
    (FCabecera.FieldByName('ESTADO_SES').AsString <> 'CERRADA') and
    Assigned(FPuedeEditar) and FPuedeEditar();
end;

procedure TBarrasSesionVcl.ComprobarContexto;
begin
  if not ContextoValido then
    raise Exception.Create(SBarrasCerrada);
  if (FSerie <> FCabecera.FieldByName('SERIE_SES').AsString) or
    (FNumero <> FCabecera.FieldByName('NUMERO_SES').AsString) then
    raise Exception.Create(SBarrasCambios);
end;

procedure TBarrasSesionVcl.ActualizarPagina;
begin
  if (FPaginas.ActivePage = FPagina) and not FActualizando then
  begin
    FActualizando := True;
    try
      CargarPagina;
    finally
      FActualizando := False;
    end;
  end;
end;

procedure TBarrasSesionVcl.CargarPagina;
begin
  FDisponible := BarrasSesionDisponibles(FConexion);
  FAviso.Visible := not FDisponible;
  if FDisponible then
    FBarra.Height := 46
  else
    FBarra.Height := 96;
  if Assigned(FPreparar) then
    FPreparar();
  FValores := nil;
  FSerie := '';
  FNumero := '';
  if FDisponible and FCabecera.Active and not FCabecera.IsEmpty and
    (FCabecera.State = dsBrowse) then
  begin
    FSerie := FCabecera.FieldByName('SERIE_SES').AsString;
    FNumero := FCabecera.FieldByName('NUMERO_SES').AsString;
    FValores := LeerBarrasSesion(FConexion, FSerie, FNumero);
  end;
  FBotonImportar.Enabled := ContextoValido;
  FBotonGenerar.Enabled := ContextoValido;
  FVista.OptionsData.Editing := ContextoValido;
  Pintar;
end;

procedure TBarrasSesionVcl.Pintar;
var
  i: Integer;
begin
  FCargando := True;
  FVista.BeginUpdate;
  try
    FVista.DataController.RecordCount := Length(FValores);
    for i := 0 to High(FValores) do
    begin
      FVista.DataController.Values[i, 0] := IntToStr(FValores[i].Linea);
      FVista.DataController.Values[i, 1] := FValores[i].Articulo;
      FVista.DataController.Values[i, 2] := FValores[i].Descripcion;
      FVista.DataController.Values[i, 3] :=
        ColorCombinacionBarras(FValores[i]);
      FVista.DataController.Values[i, 4] := FValores[i].Talla;
      FVista.DataController.Values[i, 5] := FValores[i].Codigo;
      FVista.DataController.Values[i, 6] := FValores[i].ModeloProveedor;
    end;
  finally
    FVista.EndUpdate;
    FCargando := False;
  end;
end;

procedure TBarrasSesionVcl.CeldaCambiada(
  ADataController: TcxCustomDataController;
  ARecordIndex, AItemIndex: Integer);
var
  aPropuestos: TCombinacionesBarrasSesion;
begin
  if not FCargando and (AItemIndex = 5) and (ARecordIndex >= 0) then
  begin
    ComprobarContexto;
    aPropuestos := Copy(FValores);
    aPropuestos[ARecordIndex].Codigo := Trim(VarToStr(
      ADataController.Values[ARecordIndex, AItemIndex]));
    try
      GuardarBarrasSesion(FConexion, FSerie, FNumero, FUsuario,
        aPropuestos, FValores);
      FValores := aPropuestos;
    except
      Pintar;
      raise;
    end;
  end;
end;

procedure TBarrasSesionVcl.ActualizarClick(Sender: TObject);
begin
  ActualizarPagina;
end;

procedure TBarrasSesionVcl.ImportarClick(Sender: TObject);
var
  oDialogo: TOpenDialog;
begin
  ComprobarContexto;
  oDialogo := TOpenDialog.Create(FOwner);
  try
    oDialogo.Filter := SBarrasFiltroCsv;
    if oDialogo.Execute then
      ImportarFichero(oDialogo.FileName);
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TBarrasSesionVcl.ImportarFichero(const AFichero: string);
var
  aResultado: TCombinacionesBarrasSesion;
  sTexto: string;
begin
  sTexto := TFile.ReadAllText(AFichero, TEncoding.UTF8);
  if TfrmModalCsvBarrasSesion.Ejecutar(FOwner, sTexto, FValores,
    aResultado) then
  begin
    GuardarBarrasSesion(FConexion, FSerie, FNumero, FUsuario,
      aResultado, FValores);
    ActualizarPagina;
  end;
end;

procedure TBarrasSesionVcl.GenerarClick(Sender: TObject);
var
  n: Integer;
begin
  ComprobarContexto;
  n := GenerarBarrasSesion(FConexion, FSerie, FNumero, FUsuario,
    FCabecera.FieldByName('PREFIJO_EAN_SES').AsString);
  ActualizarPagina;
  ShowMessage_fza(Format(SBarrasGenerados, [n]));
end;

end.
