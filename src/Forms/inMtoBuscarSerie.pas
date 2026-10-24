{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoBuscarSerie                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Almacén - Buscar serie (F-LOTEC-018): se lee un IMEI, número de serie o   }
{    lote y se ve el artículo, dónde está (o que ya no hay stock), de qué      }
{    compra salió, todos sus movimientos con documento, cliente y proveedor    }
{    y, con garantías, la venta, el fin de garantía y las reclamaciones.       }
{******************************************************************************}
unit inMtoBuscarSerie;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Data.DB,
  cxClasses, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, cxNavigator, cxDBData, cxGridLevel,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxContainer, cxLabel, cxTextEdit,
  cxMaskEdit, cxButtons, cxCalendar, cxCurrencyEdit, cxSplitter, cxPC,
  dxSkinsCore, dxSkinscxPCPainter, dxScrollbarAnnotations, dxDateRanges,
  dxCore,
  UniDataBuscarSerie, inMtoGen;

type
  TfrmMtoBuscarSerie = class(TfrmMtoGen)
    procedure FormCreate(Sender: TObject);
  private
    FControlesCreados: Boolean;
    FConGarantias: Boolean;
    dmmSerie: TdmBuscarSerie;
    pnlBusqueda: TPanel;
    edtSerie: TcxTextEdit;
    lblResumen: TcxLabel;
    pnlReclamaciones: TPanel;
    splReclamaciones: TcxSplitter;
    grdReclamaciones: TcxGrid;
    tvReclamaciones: TcxGridDBTableView;
    function EscalarDpi(AValor: Integer): Integer;
    procedure CrearBusqueda;
    procedure CrearReclamaciones;
    function CrearColumna(AVista: TcxGridDBTableView;
      const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
    procedure FormatoFecha(AColumna: TcxGridDBColumn);
    procedure CrearColumnasHistorico;
    procedure CrearColumnasReclamaciones;
    procedure EstadoGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure ResolucionGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    function TextoGarantia(const AResultado: TResultadoBuscarSerie): string;
    function Resumen(const AResultado: TResultadoBuscarSerie): string;
    procedure btnBuscarClick(Sender: TObject);
    procedure edtSerieKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  protected
    procedure DoCreate; override;
  public
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure BuscarSerie(const ASerie: string);
  end;

// Dónde está la serie y de qué entrada viene (sin pantalla, para probarlo).
function TextoUbicacionSerie(const AResultado: TResultadoBuscarSerie): string;
function TextoOrigenSerie(const AResultado: TResultadoBuscarSerie): string;

implementation

uses
  inLibMensajesVcl,
  inLibMsgLotesConsultas,
  inLibTrazabilidad,
  inLibGarantias;

{$R *.dfm}

const
  FORMATO_FECHA = 'dd/mm/yyyy';
  FORMATO_FECHA_HORA = 'dd/mm/yyyy hh:nn';

procedure ForceReferenceToClass(C: TClass);
begin
end;

procedure TfrmMtoBuscarSerie.FormCreate(Sender: TObject);
begin
  if not FControlesCreados then
  begin
    CrearBusqueda;
    CrearReclamaciones;
    FControlesCreados := True;
  end;
  inherited;
end;

procedure TfrmMtoBuscarSerie.DoCreate;
begin
  inherited DoCreate;
  Caption := STituloBuscarSerie;
end;

function TfrmMtoBuscarSerie.EscalarDpi(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, 96);
end;

procedure TfrmMtoBuscarSerie.CrearBusqueda;
var
  oEtiqueta: TcxLabel;
  oBoton: TcxButton;
begin
  pnlBusqueda := TPanel.Create(Self);
  pnlBusqueda.Parent := tsLista;
  pnlBusqueda.Align := alTop;
  pnlBusqueda.Height := EscalarDpi(150);
  pnlBusqueda.BevelOuter := bvNone;
  oEtiqueta := TcxLabel.Create(Self);
  oEtiqueta.Parent := pnlBusqueda;
  oEtiqueta.SetBounds(EscalarDpi(12), EscalarDpi(16), EscalarDpi(150),
    EscalarDpi(22));
  oEtiqueta.Caption := SCaptionBuscarSerie;
  oEtiqueta.Transparent := True;
  edtSerie := TcxTextEdit.Create(Self);
  edtSerie.Parent := pnlBusqueda;
  edtSerie.SetBounds(EscalarDpi(170), EscalarDpi(12), EscalarDpi(280),
    EscalarDpi(26));
  edtSerie.OnKeyDown := edtSerieKeyDown;
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := pnlBusqueda;
  oBoton.SetBounds(EscalarDpi(460), EscalarDpi(10), EscalarDpi(110),
    EscalarDpi(32));
  oBoton.Caption := SCaptionBuscarSerieBoton;
  oBoton.OnClick := btnBuscarClick;
  lblResumen := TcxLabel.Create(Self);
  lblResumen.Parent := pnlBusqueda;
  lblResumen.SetBounds(EscalarDpi(12), EscalarDpi(50), EscalarDpi(1100),
    EscalarDpi(96));
  lblResumen.AutoSize := False;
  lblResumen.Properties.WordWrap := True;
  lblResumen.Transparent := True;
end;

procedure TfrmMtoBuscarSerie.CrearReclamaciones;
begin
  pnlReclamaciones := TPanel.Create(Self);
  pnlReclamaciones.Parent := tsLista;
  pnlReclamaciones.Align := alBottom;
  pnlReclamaciones.Height := EscalarDpi(180);
  pnlReclamaciones.BevelOuter := bvNone;
  splReclamaciones := TcxSplitter.Create(Self);
  splReclamaciones.Parent := tsLista;
  splReclamaciones.AlignSplitter := salBottom;
  splReclamaciones.Control := pnlReclamaciones;
  grdReclamaciones := TcxGrid.Create(Self);
  grdReclamaciones.Parent := pnlReclamaciones;
  grdReclamaciones.Align := alClient;
  tvReclamaciones := grdReclamaciones.CreateView(TcxGridDBTableView)
    as TcxGridDBTableView;
  grdReclamaciones.Levels.Add.GridView := tvReclamaciones;
  tvReclamaciones.OptionsData.Editing := False;
  tvReclamaciones.OptionsView.GroupByBox := False;
end;

function TfrmMtoBuscarSerie.CrearColumna(AVista: TcxGridDBTableView;
  const ACampo, ATitulo: string; AAncho: Integer): TcxGridDBColumn;
begin
  Result := AVista.CreateColumn;
  Result.DataBinding.FieldName := ACampo;
  Result.Caption := ATitulo;
  Result.Width := EscalarDpi(AAncho);
  Result.Options.Editing := False;
end;

procedure TfrmMtoBuscarSerie.FormatoFecha(AColumna: TcxGridDBColumn);
begin
  AColumna.PropertiesClass := TcxDateEditProperties;
  TcxDateEditProperties(AColumna.Properties).DisplayFormat :=
    FORMATO_FECHA_HORA;
end;

procedure TfrmMtoBuscarSerie.CrearColumnasHistorico;
var
  v: TcxGridDBTableView;
begin
  v := cxGrdDBTabPrin;
  FormatoFecha(CrearColumna(v, 'FECHA_MOV', SCaptionColHistFecha, 130));
  CrearColumna(v, 'TIPO_DOC_MOV', SCaptionColHistDocumento, 50);
  CrearColumna(v, 'SERIE_DOC_MOV', SCaptionColHistSerieDoc, 70);
  CrearColumna(v, 'NUMERO_DOC_MOV', SCaptionColHistNumeroDoc, 100);
  CrearColumna(v, 'CODIGO_ALM_MOV', SCaptionColHistAlmacen, 70);
  CrearColumna(v, 'CODIGO_ALM_CONTRA_MOV', SCaptionColHistContra, 90);
  CrearColumna(v, 'TIPO_MOV', SCaptionColHistTipo, 40);
  CrearColumna(v, 'CANTIDAD_MOV', SCaptionColHistCantidad, 70);
  CrearColumna(v, 'CODIGO_UNIDAD_MOV', SCaptionColLotesSku, 140);
  CrearColumna(v, 'RAZON_SOCIAL_CLI', SCaptionColHistCliente, 200);
  CrearColumna(v, 'NOMBRE_PRV', SCaptionColHistProveedor, 200);
end;

procedure TfrmMtoBuscarSerie.CrearColumnasReclamaciones;
var
  v: TcxGridDBTableView;
begin
  v := tvReclamaciones;
  CrearColumna(v, 'ID_GAR', SCaptionColReclamacion, 60);
  FormatoFecha(CrearColumna(v, 'FECHA_RECLAMACION_GAR',
    SCaptionColHistFecha, 130));
  CrearColumna(v, 'LOTE_GAR', SCaptionColLotesLote, 150);
  // FZ-ISSUE-602: textos traducidos, no los códigos internos.
  CrearColumna(v, 'ESTADO_GAR', SCaptionColReclamacionEstado,
    90).OnGetDisplayText := EstadoGetDisplayText;
  CrearColumna(v, 'RESOLUCION_GAR', SCaptionColReclamacionResolucion,
    90).OnGetDisplayText := ResolucionGetDisplayText;
  CrearColumna(v, 'LOTE_SUSTITUTO_GAR', SCaptionColReclamacionSustituta,
    150);
  CrearColumna(v, 'MOTIVO_GAR', SCaptionColReclamacionMotivo, 280);
end;

procedure TfrmMtoBuscarSerie.EstadoGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoEstadoGarantia(AText);
end;

procedure TfrmMtoBuscarSerie.ResolucionGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  AText := TextoResolucionGarantia(AText);
end;

procedure TfrmMtoBuscarSerie.CrearTablaPrincipal;
begin
  inherited;
  dmmSerie := tdmDataModule as TdmBuscarSerie;
  pkFieldName := 'NUMERO_MOV';
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  tsFicha.TabVisible := False;
  nvNavegador.Visible := False;
  FConGarantias := Assigned(ParametrosApp) and
    TActivacionTrazabilidad.Leer(ParametrosApp).Garantias;
  pnlReclamaciones.Visible := FConGarantias;
  splReclamaciones.Visible := FConGarantias;
  if cxGrdDBTabPrin.ColumnCount = 0 then
    CrearColumnasHistorico;
  if FConGarantias and (tvReclamaciones.ColumnCount = 0) then
  begin
    tvReclamaciones.DataController.DataSource := dmmSerie.dsReclamaciones;
    CrearColumnasReclamaciones;
  end;
end;

procedure TfrmMtoBuscarSerie.ResetForm;
begin
  inherited;
  pcPantalla.ActivePage := tsLista;
end;

function TextoUbicacionSerie(const AResultado: TResultadoBuscarSerie): string;
begin
  if AResultado.AlmacenesConStock <> '' then
    Result := Format(SResumenSerieEnStock, [AResultado.AlmacenesConStock])
  else if AResultado.TieneMovimientos then
    Result := SResumenSerieSinStock
  else
    Result := SResumenSerieSinExistencias;
  if AResultado.TieneEntrada then
    Result := Result + sLineBreak + TextoOrigenSerie(AResultado);
end;

// Documento y proveedor de la entrada, omitiendo lo que no conste (en un
// alta manual no hay ninguno de los dos).
function TextoOrigenSerie(const AResultado: TResultadoBuscarSerie): string;
var
  sDocumento, sNumero, sFecha, sProveedor: string;
begin
  sNumero := Trim(AResultado.NumeroDocOrigen);
  if (sNumero <> '') and (Trim(AResultado.SerieDocOrigen) <> '') then
    sNumero := Trim(AResultado.SerieDocOrigen) + '/' + sNumero;
  sDocumento := Trim(Trim(AResultado.TipoDocOrigen) + ' ' + sNumero);
  sFecha := DateToStr(AResultado.FechaEntrada);
  sProveedor := Trim(AResultado.Proveedor);
  if (sDocumento <> '') and (sProveedor <> '') then
    Result := Format(SResumenSerieOrigen, [sDocumento, sFecha, sProveedor])
  else if sDocumento <> '' then
    Result := Format(SResumenSerieOrigenSinProveedor, [sDocumento, sFecha])
  else if sProveedor <> '' then
    Result := Format(SResumenSerieEntradaProveedor, [sFecha, sProveedor])
  else
    Result := Format(SResumenSerieEntradaSinDocumento, [sFecha]);
end;

function TfrmMtoBuscarSerie.TextoGarantia(
  const AResultado: TResultadoBuscarSerie): string;
var
  G: TDatosSerieGarantia;
  sEstado: string;
begin
  Result := '';
  G := AResultado.Garantia;
  if FConGarantias and G.Encontrada and G.Vendida then
  begin
    Result := Format(SResumenSerieVendida, [DateToStr(G.FechaVenta),
      G.RazonSocialCliente, G.DocumentoVenta]);
    if G.Devuelta then
      Result := Result + ' ' + SResumenSerieDevuelta;
    if G.TieneMeses then
    begin
      sEstado := SResumenSerieFueraGarantia;
      if G.EnGarantia then
        sEstado := SResumenSerieEnGarantia;
      Result := Result + ' ' + Format(SResumenSerieGarantiaHasta,
        [DateToStr(G.FechaFinGarantia), sEstado]);
    end;
    Result := Result + ' ' + Format(SResumenSerieReclamaciones,
      [G.ReclamacionesAbiertas]);
  end;
end;

function TfrmMtoBuscarSerie.Resumen(
  const AResultado: TResultadoBuscarSerie): string;
var
  sGarantia: string;
begin
  Result := Format(SResumenSerieArticulo, [AResultado.Articulo,
    AResultado.Descripcion, AResultado.Sku]);
  if AResultado.Articulos > 1 then
    Result := Result + sLineBreak + Format(SResumenSerieVariosArticulos,
      [AResultado.Articulos]);
  Result := Result + sLineBreak + TextoUbicacionSerie(AResultado);
  sGarantia := TextoGarantia(AResultado);
  if sGarantia <> '' then
    Result := Result + sLineBreak + sGarantia;
end;

procedure TfrmMtoBuscarSerie.BuscarSerie(const ASerie: string);
var
  Resultado: TResultadoBuscarSerie;
begin
  edtSerie.Text := Trim(ASerie);
  if edtSerie.Text <> '' then
  begin
    Resultado := dmmSerie.Buscar(edtSerie.Text, FConGarantias);
    if Resultado.Encontrada then
      lblResumen.Caption := Resumen(Resultado)
    else
      lblResumen.Caption := Format(SInfoSerieNoEncontrada,
        [edtSerie.Text]);
  end;
end;

procedure TfrmMtoBuscarSerie.btnBuscarClick(Sender: TObject);
begin
  BuscarSerie(edtSerie.Text);
end;

procedure TfrmMtoBuscarSerie.edtSerieKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    BuscarSerie(edtSerie.Text);
    edtSerie.SelectAll;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoBuscarSerie);
  ForceReferenceToClass(TfrmMtoBuscarSerie);
end.
