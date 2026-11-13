{******************************************************************************}
{  Módulo:       inMtoModalMovimientosArticuloColor                            }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Movimientos del artículo con saldo por SKU y fecha reciente.   }
{******************************************************************************}
unit inMtoModalMovimientosArticuloColor;

interface

uses
  System.Classes, System.Types, System.Generics.Collections,
  System.Actions, Vcl.ActnList,
  Data.DB, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  cxButtons, cxClasses, cxControls, cxCustomData, cxData, cxDataStorage,
  cxDBData, cxDropDownEdit, cxEdit, cxFilter, cxGraphics,
  cxGrid, cxGridCustomTableView,
  cxGridCustomView, cxGridDBTableView, cxGridLevel, cxGridTableView,
  cxGroupBox, cxLabel, cxLookAndFeelPainters, cxLookAndFeels, cxNavigator,
  cxStyles, dxDateRanges, dxScrollbarAnnotations,
  inMtoFrmBase, inLibAtributosPaletaIntf,
  inLibMovimientosArticuloNavegacion;

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
    btnIrDocumento: TcxButton;
    btnIrMovimiento: TcxButton;
    alNavegacion: TActionList;
    actIrDocumento: TAction;
    actIrMovimiento: TAction;
    dsMovimientos: TDataSource;
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrMovimientoExecute(Sender: TObject);
    procedure dsMovimientosDataChange(Sender: TObject; Field: TField);
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
    FDestino: TDestinoMovimientoArticulo;
    // Vista horizontal (tallas en columnas, como Ctrl+U): la de entrada.
    // F1 alterna con la vertical, como en los documentos de compra.
    FVistaHorizontal: TcxGridDBTableView;
    FOrigenHorizontal: TDataSource;
    function EsVistaHorizontal: Boolean;
    function DatosActivos: TDataSet;
    function ReferenciaSeleccionada: TReferenciaDocumentoMovimiento;
    procedure SolicitarNavegacion(ADocumento: Boolean);
    procedure AplicarColorSeleccionado;
    procedure FiltrarColor(ADatos: TDataSet);
    procedure ActualizarMuestraColor;
    procedure AnadirColumna(AVista: TcxGridDBTableView;
      const ACampo, ATitulo: string; AAncho: Integer;
      const AFormato: string = '');
    procedure CargarColores(const ASkuInicial: string);
    procedure RegistrarColor(const AColor, AHex: string);
    procedure PrepararColumnas;
    procedure PrepararVistaHorizontal(ADatos: TDataSet;
      const ATallas: TArray<string>);
    procedure AlternarVista;
    procedure OrdenarMovimientosPorFecha(AVista: TcxGridDBTableView);
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    function DestinoSeleccionado(ADocumento: Boolean):
      TDestinoMovimientoArticulo;
    destructor Destroy; override;
    // ADatos y ADatosHorizontal pertenecen al llamador y deben vivir hasta
    // que cierre el modal. ATallas: títulos de las columnas T<i> de
    // ADatosHorizontal, en el orden de la consulta de stock (Ctrl+U).
    class procedure Ejecutar(AOwner: TComponent;
      ADatos, ADatosHorizontal: TDataSet; const ATallas: TArray<string>;
      const AArticulo: string; const ASkuInicial: string = '');
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Variants, System.UITypes,
  Vcl.Graphics, cxCurrencyEdit, dxCore,
  inLibAtributosPaleta, inLibStockConsultaPresentacionPivote,
  inLibShowMto, inLibMensajesVcl,
  UniDataDestinoFacturaRepositorio,
  inLibMsgArticulos;

{$R *.dfm}

const
  FORMATO_CANTIDAD_MOVIMIENTOS = '#,##0.######;-#,##0.######;0';

class procedure TfrmModalMovimientosArticuloColor.Ejecutar(
  AOwner: TComponent; ADatos, ADatosHorizontal: TDataSet;
  const ATallas: TArray<string>; const AArticulo: string;
  const ASkuInicial: string);
var
  oFormulario: TfrmModalMovimientosArticuloColor;
begin
  if not Assigned(ADatos) then
    raise EArgumentNilException.Create('ADatos');
  if not Assigned(ADatosHorizontal) then
    raise EArgumentNilException.Create('ADatosHorizontal');
  oFormulario := TfrmModalMovimientosArticuloColor.Create(AOwner);
  try
    oFormulario.Caption := STituloMovimientosArticuloColor;
    oFormulario.lblArticulo.Caption := AArticulo;
    oFormulario.lblPrecios.Caption := SAyudaPreciosMovimientosArticulo +
      ' ' + SAyudaVistaMovimientosArticulo;
    oFormulario.lblColor.Caption := SColorSelectorMovimientosArticulo;
    oFormulario.btnCerrar.Caption := SCerrarMovimientosArticulo;
    oFormulario.actIrDocumento.Caption := SIrDocumentoMovimientosArticulo;
    oFormulario.actIrMovimiento.Caption := SIrMovimientoMovimientosArticulo;
    oFormulario.tvMovimientos.OptionsView.NoDataToDisplayInfoText :=
      SSinMovimientosArticulo;
    oFormulario.PrepararColumnas;
    oFormulario.dsMovimientos.DataSet := ADatos;
    oFormulario.PrepararVistaHorizontal(ADatosHorizontal, ATallas);
    oFormulario.CargarColores(ASkuInicial);
    oFormulario.OrdenarMovimientosPorFecha(oFormulario.tvMovimientos);
    oFormulario.OrdenarMovimientosPorFecha(oFormulario.FVistaHorizontal);
    oFormulario.lvlMovimientos.GridView := oFormulario.FVistaHorizontal;
    oFormulario.ShowModal;
    if oFormulario.ModalResult = mrOk then
      ShowMto(AOwner.Owner, oFormulario.FDestino.Pantalla,
        oFormulario.FDestino.Clave);
  finally
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmModalMovimientosArticuloColor.actIrDocumentoExecute(
  Sender: TObject);
begin
  SolicitarNavegacion(True);
end;

procedure TfrmModalMovimientosArticuloColor.actIrMovimientoExecute(
  Sender: TObject);
begin
  SolicitarNavegacion(False);
end;

procedure TfrmModalMovimientosArticuloColor.dsMovimientosDataChange(
  Sender: TObject; Field: TField);
var
  oDatos: TDataSet;
  bHayFila: Boolean;
begin
  oDatos := DatosActivos;
  bHayFila := Assigned(oDatos) and oDatos.Active and not oDatos.IsEmpty;
  actIrMovimiento.Enabled := bHayFila;
  actIrDocumento.Enabled := bHayFila;
end;

function TfrmModalMovimientosArticuloColor.EsVistaHorizontal: Boolean;
begin
  Result := Assigned(FVistaHorizontal) and
    (lvlMovimientos.GridView = FVistaHorizontal);
end;

function TfrmModalMovimientosArticuloColor.DatosActivos: TDataSet;
begin
  if EsVistaHorizontal then
    Result := FOrigenHorizontal.DataSet
  else
    Result := dsMovimientos.DataSet;
end;

procedure TfrmModalMovimientosArticuloColor.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  // F1: alterna vista horizontal (tallas en columnas) y vertical.
  if (Key = VK_F1) and (Shift = []) then
  begin
    Key := 0;
    AlternarVista;
  end
  else
    inherited KeyDown(Key, Shift);
end;

procedure TfrmModalMovimientosArticuloColor.AlternarVista;
begin
  if EsVistaHorizontal then
    lvlMovimientos.GridView := tvMovimientos
  else
    lvlMovimientos.GridView := FVistaHorizontal;
  dsMovimientosDataChange(nil, nil);
end;

function TfrmModalMovimientosArticuloColor.ReferenciaSeleccionada:
  TReferenciaDocumentoMovimiento;
var
  oDatos: TDataSet;
begin
  oDatos := DatosActivos;
  Result.Tipo := Trim(oDatos.FieldByName('TIPO_DOC_MOV').AsString);
  Result.Serie := Trim(oDatos.FieldByName('SERIE_DOC_MOV').AsString);
  Result.Numero := Trim(oDatos.FieldByName('NUMERO_DOC_MOV').AsString);
  Result.Empresa := Trim(oDatos.FieldByName('CODIGO_EMP_MOV').AsString);
  Result.Almacen := Trim(oDatos.FieldByName('CODIGO_ALM_DOC_MOV').AsString);
  if Result.Almacen = '' then
    Result.Almacen := Trim(oDatos.FieldByName('CODIGO_ALM_MOV').AsString);
  Result.Caja := Trim(oDatos.FieldByName('CODIGO_CAJA_DOC_MOV').AsString);
  Result.Operacion := Trim(
    oDatos.FieldByName('NUMERO_OPERACION_DOC_MOV').AsString);
end;

function TfrmModalMovimientosArticuloColor.DestinoSeleccionado(
  ADocumento: Boolean): TDestinoMovimientoArticulo;
var
  rReferencia: TReferenciaDocumentoMovimiento;
  oDatos: TDataSet;
begin
  Result := Default(TDestinoMovimientoArticulo);
  Result.Estado := edmSinDocumento;
  oDatos := DatosActivos;
  if Assigned(oDatos) and oDatos.Active and not oDatos.IsEmpty then
  begin
    if ADocumento then
    begin
      rReferencia := ReferenciaSeleccionada;
      Result := DestinoDocumentoMovimiento(rReferencia);
      if (Result.Estado = edmValido) and (Result.Pantalla = 'Facturas') then
        Result.Pantalla := ResolverCallFactura(
          CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
          rReferencia.Numero, rReferencia.Serie);
    end
    else
    begin
      Result.Clave := Trim(oDatos.FieldByName('NUMERO_MOV').AsString);
      if Result.Clave <> '' then
      begin
        Result.Estado := edmValido;
        Result.Pantalla := 'MovimientosAlmacen';
      end;
    end;
  end;
end;

procedure TfrmModalMovimientosArticuloColor.SolicitarNavegacion(
  ADocumento: Boolean);
begin
  FDestino := DestinoSeleccionado(ADocumento);
  case FDestino.Estado of
    edmValido:
      ModalResult := mrOk;
    edmSinDocumento:
      ShowMessage_fza(SSinDocumentoMovimientosArticulo);
    edmCajaSinClave:
      ShowMessage_fza(SCajaSinClaveMovimientosArticulo);
    edmNoSoportado:
      ShowMessage_fza(SDocumentoNoSoportadoMovimientosArticulo);
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
begin
  if Assigned(FColores) then
  begin
    FiltrarColor(dsMovimientos.DataSet);
    if Assigned(FOrigenHorizontal) then
      FiltrarColor(FOrigenHorizontal.DataSet);
    ActualizarMuestraColor;
  end;
end;

procedure TfrmModalMovimientosArticuloColor.FiltrarColor(ADatos: TDataSet);
var
  sColor: string;
begin
  if Assigned(ADatos) then
  begin
    ADatos.Filtered := False;
    if cbbColor.ItemIndex > 0 then
    begin
      sColor := FColores[cbbColor.ItemIndex - 1];
      ADatos.Filter := 'COLOR_AV = ' + QuotedStr(sColor);
      if sColor = '' then
        ADatos.Filter := '(COLOR_AV IS NULL) OR (COLOR_AV = '''')';
      ADatos.Filtered := True;
    end;
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
  AVista: TcxGridDBTableView; const ACampo, ATitulo: string;
  AAncho: Integer; const AFormato: string);
var
  oColumna: TcxGridDBColumn;
begin
  oColumna := AVista.CreateColumn;
  oColumna.Name := AVista.Name + 'col' + ACampo;
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

procedure TfrmModalMovimientosArticuloColor.OrdenarMovimientosPorFecha(
  AVista: TcxGridDBTableView);
var
  oFecha, oNumero: TcxGridDBColumn;
begin
  AVista.DataController.ClearSorting(False);
  oFecha := AVista.GetColumnByFieldName('FECHA_MOV');
  oNumero := AVista.GetColumnByFieldName('NUMERO_MOV');
  // Orden cronológico, como la rejilla de movimientos del artículo.
  oFecha.SortOrder := soAscending;
  oFecha.SortIndex := 0;
  oNumero.SortOrder := soAscending;
  oNumero.SortIndex := 1;
end;

procedure TfrmModalMovimientosArticuloColor.PrepararColumnas;
const
  FORMATO_PRECIO = '#,##0.00;-#,##0.00;0.00';
begin
  AnadirColumna(tvMovimientos, 'COLOR_AV', SColorMovimientosArticulo, 140);
  tvMovimientos.Columns[0].Options.Filtering := False;
  tvMovimientos.Columns[0].OnCustomDrawCell := DibujarColorFila;
  AnadirColumna(tvMovimientos, 'TALLA_AV', STallaMovimientosArticulo, 70);
  AnadirColumna(tvMovimientos, 'FECHA_MOV', SFechaMovimientosArticulo, 110);
  AnadirColumna(tvMovimientos, 'NUMERO_MOV', SNumeroMovimientosArticulo,
    95);
  AnadirColumna(tvMovimientos, 'CODIGO_EMP_MOV',
    SEmpresaMovimientosArticulo, 80);
  AnadirColumna(tvMovimientos, 'CODIGO_ALM_MOV',
    SAlmacenMovimientosArticulo, 80);
  AnadirColumna(tvMovimientos, 'TIPO_MOV', STipoMovimientosArticulo, 60);
  AnadirColumna(tvMovimientos, 'CANTIDAD_MOV',
    SUnidadesMovimientosArticulo, 80, FORMATO_CANTIDAD_MOVIMIENTOS);
  AnadirColumna(tvMovimientos, 'SALDO_STOCK', SCaptionSaldoStockMovimiento,
    90, FORMATO_CANTIDAD_MOVIMIENTOS);
  AnadirColumna(tvMovimientos, 'PRECIO_COSTE_UNITARIO_MOV',
    SPrecioCompraMovimientos, 170, FORMATO_PRECIO);
  AnadirColumna(tvMovimientos, 'PRECIO_VENTA', SPrecioVentaMovimientos,
    170, FORMATO_PRECIO);
  AnadirColumna(tvMovimientos, 'TIPO_DOC_MOV',
    SDocumentoMovimientosArticulo, 70);
  AnadirColumna(tvMovimientos, 'DESCRIPCION_TIPO_DOCUMENTO_TD',
    SDescripcionDocumentoMovimientosArticulo, 180);
  AnadirColumna(tvMovimientos, 'SERIE_DOC_MOV', SSerieMovimientosArticulo,
    70);
  AnadirColumna(tvMovimientos, 'NUMERO_DOC_MOV',
    SNumeroDocumentoMovimientosArticulo, 100);
  AnadirColumna(tvMovimientos, 'CODIGO_CAJA_DOC_MOV',
    SCajaMovimientosArticulo, 65);
  AnadirColumna(tvMovimientos, 'PRECIO_VENTA_SIVA',
    SPrecioVentaSinIvaMovimientos, 170, FORMATO_PRECIO);
  AnadirColumna(tvMovimientos, 'PORCENTAJE_DTO',
    SDescuentoMovimientosArticulo, 90, '0.## "%"');
  AnadirColumna(tvMovimientos, 'TOTAL_COSTE_MOV',
    STotalCosteMovimientosArticulo, 120, FORMATO_PRECIO);
  AnadirColumna(tvMovimientos, 'LINEA_MOV', SLineaMovimientosArticulo, 65);
  AnadirColumna(tvMovimientos, 'NOMBRE_ALMACEN',
    SNombreAlmacenMovimientosArticulo, 140);
  AnadirColumna(tvMovimientos, 'NUMERO_OPERACION_DOC_MOV',
    SOperacionMovimientosArticulo, 100);
  AnadirColumna(tvMovimientos, 'CODIGO_UNIDAD_MOV', SSkuMovimientosArticulo,
    180);
  AnadirColumna(tvMovimientos, 'ESACTIVO_MOV', SActivoMovimientosArticulo,
    70);
end;

// Misma rejilla que la vertical, sin talla, saldo, línea ni SKU (son de
// cada SKU): las tallas pasan a columnas T<i> y Unidades es el total.
procedure TfrmModalMovimientosArticuloColor.PrepararVistaHorizontal(
  ADatos: TDataSet; const ATallas: TArray<string>);
const
  FORMATO_PRECIO = '#,##0.00;-#,##0.00;0.00';
  ANCHO_COLUMNA_TALLA = 60;
var
  oVista: TcxGridDBTableView;
  oColumna: TcxGridDBColumn;
  i: Integer;
begin
  FOrigenHorizontal := TDataSource.Create(Self);
  FOrigenHorizontal.OnDataChange := dsMovimientosDataChange;
  oVista := cxgrdMovimientos.CreateView(TcxGridDBTableView) as
    TcxGridDBTableView;
  oVista.Name := 'tvMovimientosHorizontal';
  oVista.DataController.DataSource := FOrigenHorizontal;
  oVista.FilterRow.Visible := True;
  oVista.OptionsBehavior.AlwaysShowEditor := False;
  oVista.OptionsData.CancelOnExit := False;
  oVista.OptionsData.Deleting := False;
  oVista.OptionsData.Editing := False;
  oVista.OptionsData.Inserting := False;
  oVista.OptionsView.ColumnAutoWidth := False;
  oVista.OptionsView.HeaderAutoHeight := True;
  // Agrupar solo en la vertical: aquí cada fila ya resume un documento.
  oVista.OptionsView.GroupByBox := False;
  oVista.OptionsCustomize.ColumnGrouping := False;
  oVista.OptionsView.NoDataToDisplayInfoText := SSinMovimientosArticulo;
  FVistaHorizontal := oVista;
  AnadirColumna(oVista, 'COLOR_AV', SColorMovimientosArticulo, 140);
  oVista.Columns[0].Options.Filtering := False;
  oVista.Columns[0].OnCustomDrawCell := DibujarColorFila;
  AnadirColumna(oVista, 'FECHA_MOV', SFechaMovimientosArticulo, 110);
  AnadirColumna(oVista, 'CODIGO_EMP_MOV', SEmpresaMovimientosArticulo, 70);
  AnadirColumna(oVista, 'CODIGO_ALM_MOV', SAlmacenMovimientosArticulo, 70);
  AnadirColumna(oVista, 'TIPO_MOV', STipoMovimientosArticulo, 45);
  // Precios y total antes de las tallas, como en la vista legacy.
  AnadirColumna(oVista, 'PRECIO_COSTE_UNITARIO_MOV',
    SPrecioCompraMovimientos, 150, FORMATO_PRECIO);
  AnadirColumna(oVista, 'PRECIO_VENTA', SPrecioVentaMovimientos, 150,
    FORMATO_PRECIO);
  AnadirColumna(oVista, 'CANTIDAD_MOV', SUnidadesMovimientosArticulo, 80,
    FORMATO_CANTIDAD_MOVIMIENTOS);
  for i := 0 to High(ATallas) do
  begin
    AnadirColumna(oVista, CampoTallaPivoteStock(i), ATallas[i],
      ANCHO_COLUMNA_TALLA, FORMATO_CANTIDAD_MOVIMIENTOS);
    oColumna := oVista.Columns[oVista.ColumnCount - 1];
    oColumna.HeaderAlignmentHorz := taCenter;
    oColumna.Options.Sorting := False;
  end;
  AnadirColumna(oVista, 'TIPO_DOC_MOV', SDocumentoMovimientosArticulo, 55);
  AnadirColumna(oVista, 'DESCRIPCION_TIPO_DOCUMENTO_TD',
    SDescripcionDocumentoMovimientosArticulo, 170);
  AnadirColumna(oVista, 'SERIE_DOC_MOV', SSerieMovimientosArticulo, 60);
  AnadirColumna(oVista, 'NUMERO_DOC_MOV',
    SNumeroDocumentoMovimientosArticulo, 90);
  AnadirColumna(oVista, 'CODIGO_CAJA_DOC_MOV', SCajaMovimientosArticulo, 60);
  AnadirColumna(oVista, 'NUMERO_MOV', SNumeroMovimientosArticulo, 95);
  AnadirColumna(oVista, 'PRECIO_VENTA_SIVA', SPrecioVentaSinIvaMovimientos,
    150, FORMATO_PRECIO);
  AnadirColumna(oVista, 'PORCENTAJE_DTO', SDescuentoMovimientosArticulo, 80,
    '0.## "%"');
  AnadirColumna(oVista, 'TOTAL_COSTE_MOV', STotalCosteMovimientosArticulo,
    120, FORMATO_PRECIO);
  AnadirColumna(oVista, 'NOMBRE_ALMACEN', SNombreAlmacenMovimientosArticulo,
    140);
  AnadirColumna(oVista, 'NUMERO_OPERACION_DOC_MOV',
    SOperacionMovimientosArticulo, 100);
  AnadirColumna(oVista, 'ESACTIVO_MOV', SActivoMovimientosArticulo, 60);
  FOrigenHorizontal.DataSet := ADatos;
end;

end.
