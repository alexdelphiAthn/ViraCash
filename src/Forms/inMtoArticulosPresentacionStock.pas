{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoArticulosPresentacionStock                               }
{    Tipo:       Colaborador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Paleta basica de la rejilla de stock pivotado: mapa de atributos del      }
{    articulo, cuadrados de color, hints y ancho de columna. Recibe la vista   }
{    y la conexion de lectura, nunca el formulario.                            }
{******************************************************************************}
unit inMtoArticulosPresentacionStock;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  System.Generics.Collections,
  Uni,
  cxCustomData, cxGraphics, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView,
  cxGridDBTableView;

type
  TPresentadorStockArticulo = class
  private
    // NOMBRE_ATRIBUTO (uppercase) -> ID_ATRIBUTO del articulo actual.
    FAtributos: TDictionary<string, string>;
    FVista: TcxGridDBTableView;
    FConexion: TUniConnection;
    FCodigoArticulo: string;
    procedure CrearLeyenda;
    procedure ConfigurarTotalesCabecera;
    procedure ActualizarTotalesCabecera(ASender: TcxDataSummary);
    function ResolverIdVariacion(AItem: TcxCustomGridTableItem;
      out AIdVariacion: string): Boolean;
    function TextoCantidad(AViewInfo: TcxGridTableDataCellViewInfo;
      AColumna: TcxGridDBColumn): string;
    function PintarResumen(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
  public
    constructor Create(AVista: TcxGridDBTableView;
      AConexion: TUniConnection);
    destructor Destroy; override;
    procedure CargarMapaArticulo(const ACodigoArticulo: string);
    procedure PintarCelda(ACanvas: TcxCanvas;
      AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
    function ObtenerHint(AViewInfo: TcxGridTableDataCellViewInfo;
      out AHint: string): Boolean;
    procedure EnsancharColumnasParaSwatch;
    procedure AjustarAnchoColor;
  end;

implementation

uses
  Winapi.Windows, System.Variants, System.Math, Data.DB, Vcl.Graphics,
  Vcl.Controls, cxGroupBox, cxLabel, cxEdit, dxCoreGraphics,
  inLibMsgArticulos,
  inLibStockConsultaPersistenciaIntf,
  inLibDevExp,
  inLibAtributosPaleta,
  inLibAtributosPaletaIntf;

constructor TPresentadorStockArticulo.Create(AVista: TcxGridDBTableView;
  AConexion: TUniConnection);
begin
  inherited Create;
  FVista := AVista;
  FConexion := AConexion;
  FAtributos := TDictionary<string, string>.Create;
  CrearLeyenda;
  FVista.OptionsView.HeaderAutoHeight := True;
  FVista.DataController.Summary.OnAfterSummary :=
    ActualizarTotalesCabecera;
end;

procedure TPresentadorStockArticulo.CrearLeyenda;
var
  oPanel: TcxGroupBox;
  rParametros: TcxViewParams;

  procedure AnadirEtiqueta(const ATexto: string; AColor: TColor);
  var
    oEtiqueta: TcxLabel;
  begin
    oEtiqueta := TcxLabel.Create(oPanel);
    oEtiqueta.Parent := oPanel;
    oEtiqueta.Transparent := True;
    oEtiqueta.Style.Font.Assign(oPanel.Font);
    oEtiqueta.Style.TextColor := AColor;
    oEtiqueta.Caption := ATexto;
    oEtiqueta.AutoSize := True;
    oEtiqueta.AlignWithMargins := True;
    oEtiqueta.Margins.Left := MulDiv(8, oPanel.CurrentPPI, 96);
    oEtiqueta.Margins.Right := MulDiv(12, oPanel.CurrentPPI, 96);
    oEtiqueta.Left := oPanel.Width;
    oPanel.Height := Max(oPanel.Height, oEtiqueta.Height +
      oEtiqueta.Margins.Top + oEtiqueta.Margins.Bottom +
      MulDiv(12, oPanel.CurrentPPI, 96));
    oEtiqueta.Align := alLeft;
  end;

begin
  oPanel := TcxGroupBox.Create(FVista.Control);
  oPanel.Parent := FVista.Control.Parent;
  oPanel.PanelStyle.Active := True;
  oPanel.Style.BorderStyle := ebsNone;
  oPanel.Transparent := True;
  FVista.Styles.GetContentParams(nil, nil, rParametros);
  oPanel.Font.Assign(rParametros.Font);
  oPanel.Height := MulDiv(36, oPanel.CurrentPPI, 96);
  oPanel.Align := alBottom;
  AnadirEtiqueta(SLeyendaVentasStock, clRed);
  AnadirEtiqueta(SLeyendaRecibirStock, clBlue);
  AnadirEtiqueta(SLeyendaExistenciasStock, clBlack);
end;

destructor TPresentadorStockArticulo.Destroy;
begin
  FVista.DataController.Summary.OnAfterSummary := nil;
  FreeAndNil(FAtributos);
  inherited Destroy;
end;

procedure TPresentadorStockArticulo.CargarMapaArticulo(
  const ACodigoArticulo: string);
begin
  FCodigoArticulo := ACodigoArticulo;
  // Debe correr ANTES de reconstruir las columnas dinamicas: el bestfit
  // necesita saber que columnas pintaran swatch para reservarles ancho.
  if FAtributos <> nil then
    CargarMapaAtributosArticulo(FConexion, ACodigoArticulo, FAtributos);
end;

function TPresentadorStockArticulo.ResolverIdVariacion(
  AItem: TcxCustomGridTableItem; out AIdVariacion: string): Boolean;
begin
  AIdVariacion := '';
  Result := (FAtributos <> nil) and (FAtributos.Count > 0) and
            (AItem <> nil);
  if Result then
    // El nombre de campo casa con NOMBRE_VA porque el SP de stock
    // pivotado etiqueta la fila desglosada con ese mismo nombre. Las
    // columnas pivote (S, M, 3, 5, ...) no estan en el diccionario.
    Result := FAtributos.TryGetValue(
      UpperCase(Trim(GetItemFieldName(AItem))), AIdVariacion);
end;

function TPresentadorStockArticulo.TextoCantidad(
  AViewInfo: TcxGridTableDataCellViewInfo;
  AColumna: TcxGridDBColumn): string;
var
  vCantidad: Variant;
  sMascara: string;
begin
  Result := '';
  if (AColumna <> nil) and (AViewInfo.GridRecord <> nil) then
  begin
    vCantidad := AViewInfo.GridRecord.Values[AColumna.Index];
    if not VarIsNull(vCantidad) and not VarIsEmpty(vCantidad) then
    begin
      sMascara := '0.##';
      if AColumna.DataBinding.Field is TNumericField then
        sMascara := TNumericField(
          AColumna.DataBinding.Field).DisplayFormat;
      if sMascara = '' then
        sMascara := '0.##';
      Result := FormatFloat(sMascara, vCantidad);
    end;
  end;
end;

function TPresentadorStockArticulo.PintarResumen(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo): Boolean;
var
  oVentas, oRecibir: TcxGridDBColumn;
  rStock, rVentas, rRecibir: TRect;
  sCampo, sVentas, sRecibir: string;
  iMargen, iMitad, iAltoFuente: Integer;
begin
  sCampo := GetItemFieldName(AViewInfo.Item);
  oVentas := FVista.GetColumnByFieldName(
    PREFIJO_VENTAS_CELDA_STOCK + sCampo);
  oRecibir := FVista.GetColumnByFieldName(
    PREFIJO_RECIBIR_CELDA_STOCK + sCampo);
  Result := (oVentas <> nil) and (oRecibir <> nil);
  if Result then
  begin
    sVentas := TextoCantidad(AViewInfo, oVentas);
    sRecibir := TextoCantidad(AViewInfo, oRecibir);
    iMargen := MulDiv(4, FVista.Control.CurrentPPI, 96);
    rStock := AViewInfo.Bounds;
    InflateRect(rStock, -iMargen, 0);
    iMitad := (rStock.Top + rStock.Bottom) div 2;
    rVentas := rStock;
    rVentas.Bottom := iMitad;
    rRecibir := rStock;
    rRecibir.Top := iMitad;
    ACanvas.Brush.Color := AViewInfo.Params.Color;
    ACanvas.FillRect(AViewInfo.Bounds);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Assign(AViewInfo.Params.Font);
    try
      iAltoFuente := Abs(ACanvas.Font.Height);
      ACanvas.Font.Height := -MulDiv(iAltoFuente, 3, 4);
      ACanvas.Font.Color := clRed;
      ACanvas.DrawText(sVentas, rVentas,
        cxAlignLeft or cxAlignVCenter or cxSingleLine);
      ACanvas.Font.Color := clBlue;
      ACanvas.DrawText(sRecibir, rRecibir,
        cxAlignLeft or cxAlignVCenter or cxSingleLine);
      // Reservar el ancho real de los secundarios antes del stock grande.
      rStock.Left := rStock.Left +
        Max(ACanvas.TextWidth(sVentas), ACanvas.TextWidth(sRecibir)) +
        iMargen;
      ACanvas.Font.Assign(AViewInfo.Params.Font);
      ACanvas.Font.Color := clBlack;
      ACanvas.DrawText(AViewInfo.Text, rStock,
        cxAlignRight or cxAlignVCenter or cxSingleLine or
        cxShowEndEllipsis);
    finally
      ACanvas.Font.Assign(AViewInfo.Params.Font);
      ACanvas.Brush.Style := bsSolid;
    end;
  end;
end;

procedure TPresentadorStockArticulo.PintarCelda(ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var AHecho: Boolean);
var
  oInfo: TInfoBasico;
  sIdVariacion: string;
begin
  if AViewInfo <> nil then
  begin
    if PintarResumen(ACanvas, AViewInfo) then
      AHecho := True
    else if ResolverIdVariacion(AViewInfo.Item, sIdVariacion) then
    begin
      if ObtenerInfoBasicoArticulo(FConexion, FCodigoArticulo,
           sIdVariacion, AViewInfo.Text, oInfo) or
         ObtenerInfoBasico(FConexion, sIdVariacion,
           AViewInfo.Text, oInfo) then
      begin
        if PintarCeldaConCuadradoColor(ACanvas, AViewInfo, oInfo) then
          AHecho := True;
      end;
    end;
  end;
end;

function TPresentadorStockArticulo.ObtenerHint(
  AViewInfo: TcxGridTableDataCellViewInfo; out AHint: string): Boolean;
var
  oInfo: TInfoBasico;
  sIdVariacion: string;
begin
  AHint := '';
  Result := False;
  if AViewInfo <> nil then
  begin
    if ResolverIdVariacion(AViewInfo.Item, sIdVariacion) then
    begin
      Result := ObtenerInfoBasicoArticulo(FConexion, FCodigoArticulo,
        sIdVariacion, AViewInfo.Text, oInfo) or
        ObtenerInfoBasico(FConexion, sIdVariacion, AViewInfo.Text, oInfo);
      if Result then
        AHint := oInfo.Nombre;
    end;
  end;
end;

// Los vendidos se suman por talla con los filtros de la vista.
// La cabecera usa los mismos campos rojos que el detalle de cada celda.
procedure TPresentadorStockArticulo.ConfigurarTotalesCabecera;
var
  iColumna: Integer;
  oColumna, oVentas: TcxGridDBColumn;
  oSuma: TcxGridDBTableSummaryItem;
begin
  // Los perfiles pueden haber restaurado el alto de la cabecera.
  FVista.OptionsView.HeaderHeight := 0;
  FVista.OptionsView.HeaderAutoHeight := True;
  FVista.DataController.Summary.BeginUpdate;
  try
    FVista.DataController.Summary.FooterSummaryItems.Clear;
    FVista.DataController.Summary.Options := [soNullIgnore];
    for iColumna := 0 to FVista.ColumnCount - 1 do
    begin
      oColumna := FVista.Columns[iColumna];
      oVentas := FVista.GetColumnByFieldName(
        PREFIJO_VENTAS_CELDA_STOCK + oColumna.DataBinding.FieldName);
      if oColumna.Visible and (oVentas <> nil) and
         (oVentas.DataBinding.Field is TNumericField) then
      begin
        oSuma := FVista.DataController.Summary.FooterSummaryItems.Add
          as TcxGridDBTableSummaryItem;
        oSuma.Column := oColumna;
        oSuma.FieldName := oVentas.DataBinding.FieldName;
        oSuma.Kind := skSum;
        oSuma.Format := TNumericField(
          oVentas.DataBinding.Field).DisplayFormat;
      end;
    end;
  finally
    FVista.DataController.Summary.EndUpdate;
  end;
  ActualizarTotalesCabecera(FVista.DataController.Summary);
end;

procedure TPresentadorStockArticulo.ActualizarTotalesCabecera(
  ASender: TcxDataSummary);
var
  iSuma, iSalto, iTamano: Integer;
  rParametros: TcxViewParams;
  oSuma: TcxGridDBTableSummaryItem;
  oColumna: TcxGridColumn;
  sTitulo, sTotal: string;
  vTotal: Variant;
begin
  for iSuma := 0 to ASender.FooterSummaryItems.Count - 1 do
  begin
    oSuma := ASender.FooterSummaryItems[iSuma]
      as TcxGridDBTableSummaryItem;
    oColumna := oSuma.Column;
    if oColumna <> nil then
    begin
      sTitulo := oColumna.Caption;
      iSalto := Pos(#13, sTitulo);
      if iSalto = 0 then
        iSalto := Pos('[COLOR=Red]', sTitulo);
      if iSalto > 0 then
        sTitulo := Trim(Copy(sTitulo, 1, iSalto - 1));
      vTotal := ASender.FooterSummaryValues[iSuma];
      sTotal := '0';
      if not VarIsNull(vTotal) and not VarIsEmpty(vTotal) then
        sTotal := oSuma.FormatValue(vTotal, True);
      oColumna.Styles.GetHeaderParams(rParametros);
      iTamano := Max(1, MulDiv(rParametros.Font.Size, 3, 4));
      oColumna.Caption := sTitulo + '  [COLOR=Red][SIZE=' +
        IntToStr(iTamano) + ']' + sTotal + '[/SIZE][/COLOR]';
    end;
  end;
end;

procedure TPresentadorStockArticulo.AjustarAnchoColor;
var
  oColumna: TcxGridDBColumn;
  rParametros: TcxViewParams;
  iRegistro, iAncho, iTexto, iReserva: Integer;
begin
  ConfigurarTotalesCabecera;
  oColumna := FVista.GetColumnByFieldName('Color');
  if oColumna <> nil then
  begin
    // Medir con la fuente efectiva del cliente y reservar la muestra.
    iReserva := MulDiv(28, FVista.Control.CurrentPPI, 96);
    oColumna.Styles.GetHeaderParams(rParametros);
    iAncho := cxTextWidth(rParametros.Font, oColumna.Caption) +
      MulDiv(24, FVista.Control.CurrentPPI, 96);
    oColumna.Styles.GetContentParams(nil, rParametros);
    for iRegistro := 0 to FVista.DataController.RecordCount - 1 do
    begin
      iTexto := cxTextWidth(rParametros.Font,
        FVista.DataController.DisplayTexts[iRegistro, oColumna.Index]);
      iAncho := Max(iAncho, iTexto + iReserva);
    end;
    oColumna.Width := iAncho;
  end;
end;

procedure TPresentadorStockArticulo.EnsancharColumnasParaSwatch;
var
  iColumna: Integer;
begin
  // Solo se ensanchan las columnas que van a pintar swatch. ApplyBestFit
  // mide texto y no reserva sitio para el cuadradito de color.
  if (FVista <> nil) and (FAtributos <> nil) and (FAtributos.Count > 0) then
  begin
    for iColumna := 0 to FVista.ColumnCount - 1 do
      if FAtributos.ContainsKey(
           UpperCase(Trim(GetItemFieldName(FVista.Columns[iColumna])))) then
        AjustarAnchoColumnaParaSwatch(
          FConexion, FVista.Columns[iColumna], FAtributos);
  end;
end;

end.
