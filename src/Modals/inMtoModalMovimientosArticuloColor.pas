{******************************************************************************}
{  Módulo:       inMtoModalMovimientosArticuloColor                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Movimientos del artículo ordenados por color y talla.          }
{******************************************************************************}
unit inMtoModalMovimientosArticuloColor;

interface

uses
  System.Classes, System.Types, System.Generics.Collections,
  Data.DB, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxButtons, cxClasses, cxControls, cxCustomData, cxData, cxDataStorage,
  cxDBData, cxDropDownEdit, cxEdit, cxFilter, cxGraphics,
  cxGrid, cxGridCustomTableView,
  cxGridCustomView, cxGridDBTableView, cxGridLevel, cxGridTableView,
  cxGroupBox, cxLabel, cxLookAndFeelPainters, cxLookAndFeels, cxNavigator,
  cxStyles, dxDateRanges, dxScrollbarAnnotations,
  inMtoFrmBase, inLibAtributosPaletaIntf;

type
  TfrmModalMovimientosArticuloColor = class(TfrmBase)
    pnlCabecera: TcxGroupBox;
    lblArticulo: TcxLabel;
    lblPrecios: TcxLabel;
    lblColor: TcxLabel;
    cbbColor: TcxComboBox;
    imgColor: TImage;
    cxgrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    lvlMovimientos: TcxGridLevel;
    pnlBotones: TcxGroupBox;
    btnCerrar: TcxButton;
    dsMovimientos: TDataSource;
    procedure cbbColorPropertiesChange(Sender: TObject);
    procedure DibujarColorCombo(AControl: TcxCustomComboBox;
      ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
      AState: TOwnerDrawState);
    procedure DibujarColorFila(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  private
    FColores: TStringList;
    FPaleta: TDictionary<string, TInfoBasico>;
    procedure AplicarColorSeleccionado;
    procedure ActualizarMuestraColor;
    procedure AnadirColumna(const ACampo, ATitulo: string;
      AAncho: Integer; const AFormato: string = '');
    procedure CargarColores(const ASkuInicial: string);
    procedure RegistrarColor(const AColor, AHex: string);
    procedure PrepararColumnas;
  public
    destructor Destroy; override;
    // ADatos pertenece al llamador y debe vivir hasta que cierre el modal.
    class procedure Ejecutar(AOwner: TComponent; ADatos: TDataSet;
      const AArticulo: string; const ASkuInicial: string = '');
  end;

implementation

uses
  System.SysUtils, System.Variants, Vcl.Graphics, cxCurrencyEdit,
  inLibAtributosPaleta,
  inLibMsgArticulos;

{$R *.dfm}

class procedure TfrmModalMovimientosArticuloColor.Ejecutar(
  AOwner: TComponent; ADatos: TDataSet; const AArticulo: string;
  const ASkuInicial: string);
var
  oFormulario: TfrmModalMovimientosArticuloColor;
begin
  if not Assigned(ADatos) then
    raise EArgumentNilException.Create('ADatos');
  oFormulario := TfrmModalMovimientosArticuloColor.Create(AOwner);
  try
    oFormulario.Caption := STituloMovimientosArticuloColor;
    oFormulario.lblArticulo.Caption := AArticulo;
    oFormulario.lblPrecios.Caption := SAyudaPreciosMovimientosArticulo;
    oFormulario.lblColor.Caption := SColorSelectorMovimientosArticulo;
    oFormulario.btnCerrar.Caption := SCerrarMovimientosArticulo;
    oFormulario.tvMovimientos.OptionsView.NoDataToDisplayInfoText :=
      SSinMovimientosArticulo;
    oFormulario.PrepararColumnas;
    oFormulario.dsMovimientos.DataSet := ADatos;
    oFormulario.CargarColores(ASkuInicial);
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

destructor TfrmModalMovimientosArticuloColor.Destroy;
begin
  FreeAndNil(FColores);
  FreeAndNil(FPaleta);
  inherited;
end;

procedure TfrmModalMovimientosArticuloColor.CargarColores(
  const ASkuInicial: string);
var
  oDatos: TDataSet;
  oPosicion: TBookmark;
  sColor: string;
  sColorInicial: string;
  bColorInicial: Boolean;
begin
  bColorInicial := False;
  sColorInicial := '';
  FPaleta := TDictionary<string, TInfoBasico>.Create;
  FColores := TStringList.Create;
  FColores.Sorted := True;
  FColores.Duplicates := dupIgnore;
  oDatos := dsMovimientos.DataSet;
  oDatos.DisableControls;
  oPosicion := oDatos.GetBookmark;
  try
    oDatos.First;
    while not oDatos.Eof do
    begin
      sColor := oDatos.FieldByName('COLOR_AV').AsString;
      FColores.Add(sColor);
      RegistrarColor(sColor, oDatos.FieldByName('HEX_COLOR').AsString);
      if (ASkuInicial <> '') and SameText(ASkuInicial,
        oDatos.FieldByName('CODIGO_UNIDAD_MOV').AsString) then
      begin
        sColorInicial := sColor;
        bColorInicial := True;
      end;
      oDatos.Next;
    end;
    if oDatos.BookmarkValid(oPosicion) then
      oDatos.GotoBookmark(oPosicion);
  finally
    oDatos.FreeBookmark(oPosicion);
    oDatos.EnableControls;
  end;
  cbbColor.Properties.Items.Add(STodosColoresMovimientosArticulo);
  for sColor in FColores do
  begin
    if sColor = '' then
      cbbColor.Properties.Items.Add(SSinColorMovimientosArticulo)
    else
      cbbColor.Properties.Items.Add(sColor);
  end;
  cbbColor.ItemIndex := 0;
  if bColorInicial then
    cbbColor.ItemIndex := FColores.IndexOf(sColorInicial) + 1;
end;

procedure TfrmModalMovimientosArticuloColor.RegistrarColor(
  const AColor, AHex: string);
var
  rInfo: TInfoBasico;
begin
  rInfo := Default(TInfoBasico);
  rInfo.HexColor := AHex;
  rInfo.Color := HexToColor(AHex);
  rInfo.EsValido := rInfo.Color <> clNone;
  FPaleta.AddOrSetValue(AColor, rInfo);
end;

procedure TfrmModalMovimientosArticuloColor.DibujarColorCombo(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas; AIndex: Integer;
  const ARect: TRect; AState: TOwnerDrawState);
var
  rInfo: TInfoBasico;
  bColor: Boolean;
begin
  rInfo := Default(TInfoBasico);
  if (AIndex >= 0) and (AIndex < cbbColor.Properties.Items.Count) then
  begin
    bColor := Assigned(FPaleta) and (AIndex > 0) and
      FPaleta.TryGetValue(cbbColor.Properties.Items[AIndex], rInfo);
    PintarOpcionComboConSwatch(ACanvas, ARect, AState,
      cbbColor.Properties.Items[AIndex], bColor and rInfo.EsValido, rInfo);
  end;
end;

procedure TfrmModalMovimientosArticuloColor.DibujarColorFila(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  rInfo: TInfoBasico;
begin
  if Assigned(FPaleta) and Assigned(AViewInfo.GridRecord) and
    FPaleta.TryGetValue(
    VarToStr(AViewInfo.GridRecord.Values[AViewInfo.Item.Index]), rInfo) then
    ADone := PintarCeldaConCuadradoColor(ACanvas, AViewInfo, rInfo);
end;

procedure TfrmModalMovimientosArticuloColor.cbbColorPropertiesChange(
  Sender: TObject);
begin
  AplicarColorSeleccionado;
end;

procedure TfrmModalMovimientosArticuloColor.AplicarColorSeleccionado;
var
  oDatos: TDataSet;
  sColor: string;
begin
  oDatos := dsMovimientos.DataSet;
  if Assigned(oDatos) and Assigned(FColores) then
  begin
    oDatos.Filtered := False;
    if cbbColor.ItemIndex > 0 then
    begin
      sColor := FColores[cbbColor.ItemIndex - 1];
      oDatos.Filter := 'COLOR_AV = ' + QuotedStr(sColor);
      if sColor = '' then
        oDatos.Filter := '(COLOR_AV IS NULL) OR (COLOR_AV = '''')';
      oDatos.Filtered := True;
    end;
    ActualizarMuestraColor;
  end;
end;

procedure TfrmModalMovimientosArticuloColor.ActualizarMuestraColor;
var
  rInfo: TInfoBasico;
begin
  rInfo := Default(TInfoBasico);
  imgColor.Visible := (cbbColor.ItemIndex > 0) and
    FPaleta.TryGetValue(cbbColor.Text, rInfo) and rInfo.EsValido;
  if imgColor.Visible then
  begin
    PintarSwatchEnBitmap(imgColor.Picture.Bitmap, rInfo, ScaleValue(20));
    imgColor.Hint := rInfo.HexColor;
  end;
end;

procedure TfrmModalMovimientosArticuloColor.AnadirColumna(
  const ACampo, ATitulo: string; AAncho: Integer;
  const AFormato: string);
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := tvMovimientos.CreateColumn;
  oColumna.Name := 'col' + ACampo;
  oColumna.DataBinding.FieldName := ACampo;
  oColumna.Caption := ATitulo;
  oColumna.Width := ScaleValue(AAncho);
  if AFormato <> '' then
  begin
    oColumna.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(oColumna.Properties).DisplayFormat :=
      AFormato;
  end;
end;

procedure TfrmModalMovimientosArticuloColor.PrepararColumnas;
const
  FORMATO_PRECIO = '#,##0.00;-#,##0.00;0.00';
begin
  AnadirColumna('COLOR_AV', SColorMovimientosArticulo, 140);
  tvMovimientos.Columns[0].Options.Filtering := False;
  tvMovimientos.Columns[0].OnCustomDrawCell := DibujarColorFila;
  AnadirColumna('TALLA_AV', STallaMovimientosArticulo, 70);
  AnadirColumna('FECHA_MOV', SFechaMovimientosArticulo, 110);
  AnadirColumna('NUMERO_MOV', SNumeroMovimientosArticulo, 95);
  AnadirColumna('CODIGO_EMP_MOV', SEmpresaMovimientosArticulo, 80);
  AnadirColumna('CODIGO_ALM_MOV', SAlmacenMovimientosArticulo, 80);
  AnadirColumna('TIPO_MOV', STipoMovimientosArticulo, 60);
  AnadirColumna('CANTIDAD_MOV', SUnidadesMovimientosArticulo, 80,
    '#,##0.######;-#,##0.######;0');
  AnadirColumna('PRECIO_COSTE_UNITARIO_MOV', SPrecioCompraMovimientos,
    170, FORMATO_PRECIO);
  AnadirColumna('PRECIO_VENTA', SPrecioVentaMovimientos,
    170, FORMATO_PRECIO);
  AnadirColumna('TIPO_DOC_MOV', SDocumentoMovimientosArticulo, 70);
  AnadirColumna('DESCRIPCION_TIPO_DOCUMENTO_TD',
    SDescripcionDocumentoMovimientosArticulo, 180);
  AnadirColumna('SERIE_DOC_MOV', SSerieMovimientosArticulo, 70);
  AnadirColumna('NUMERO_DOC_MOV', SNumeroDocumentoMovimientosArticulo, 100);
  AnadirColumna('CODIGO_CAJA_DOC_MOV', SCajaMovimientosArticulo, 65);
  AnadirColumna('PRECIO_VENTA_SIVA', SPrecioVentaSinIvaMovimientos,
    170, FORMATO_PRECIO);
  AnadirColumna('PORCENTAJE_DTO', SDescuentoMovimientosArticulo, 90,
    '0.## "%"');
  AnadirColumna('TOTAL_COSTE_MOV', STotalCosteMovimientosArticulo, 120,
    FORMATO_PRECIO);
  AnadirColumna('LINEA_MOV', SLineaMovimientosArticulo, 65);
  AnadirColumna('NOMBRE_ALMACEN', SNombreAlmacenMovimientosArticulo, 140);
  AnadirColumna('NUMERO_OPERACION_DOC_MOV', SOperacionMovimientosArticulo,
    100);
  AnadirColumna('CODIGO_UNIDAD_MOV', SSkuMovimientosArticulo, 180);
  AnadirColumna('ESACTIVO_MOV', SActivoMovimientosArticulo, 70);
end;

end.
