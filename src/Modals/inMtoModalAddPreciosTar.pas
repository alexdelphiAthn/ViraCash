{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAddPreciosTar                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para anadir precios a SKUs en una o varias tarifas.                 }
{    Selecciona rango de fechas, SKUs y tarifas a aplicar.                     }
{******************************************************************************}
unit inMtoModalAddPreciosTar;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.ImgList,
  System.Actions, Vcl.ActnList,
  JvComponentBase, JvEnterTab,
  cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, cxControls, cxClasses,
  cxLocalization, cxContainer, cxEdit, cxButtons, cxTextEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxCustomListBox, cxCheckListBox,
  inMtoModalAceptCancel, Vcl.ComCtrls, dxCore, cxDateUtils, cxCheckBox,
  inLibArticulosPresentacionIntf;

type
  TfrmMtoModalAddPreciosTar = class(TfrmModalAceptCancel)
    pnlFechas: TPanel;
    lblDesde: TLabel;
    dtpDesde: TcxDateEdit;
    lblHasta: TLabel;
    dtpHasta: TcxDateEdit;
    lblSkus: TLabel;
    chkSkus: TcxCheckListBox;
    lblTarifas: TLabel;
    chkTarifas: TcxCheckListBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FImagenesColores: TImageList;
    FOpcionesSkus: TOpcionesSkuTarifaArticulo;
    // Nombres de los ejes del artículo si no son Color y Talla
    // (FZ-ISSUE-439); vacíos = los textos de siempre.
    FEjeFila: string;
    FEjePivote: string;
    function CrearMuestraColor(const AHex: string): Integer;
  public
    // Antes de CargarSkus. Vacíos dejan «Talla» y «cualquier color».
    procedure AsignarRotulosEjes(const AEjeFila, AEjePivote: string);
    procedure CargarSkus(const ASkus: TOpcionesSkuTarifaArticulo);
    procedure CargarTarifas(const ATarifas: TStrings);
    function FechaDesde: TDate;
    function TieneFechaHasta: Boolean;
    function FechaHasta: TDate;
    procedure ObtenerSkusSeleccionados(AOut: TStrings);
    procedure ObtenerTarifasSeleccionadas(AOut: TStrings);
  end;

implementation

{$R *.dfm}

uses
  inLibArticulosPresentacion, inLibMsgArticulos;


procedure TfrmMtoModalAddPreciosTar.FormCreate(Sender: TObject);
begin
  inherited;
  FImagenesColores := TImageList.Create(Self);
  FImagenesColores.Width := 16;
  FImagenesColores.Height := 16;
  FImagenesColores.Masked := False;
  chkSkus.Images := FImagenesColores;
  chkSkus.ImageLayout := ilAfterChecks;
  dtpDesde.Date := Date;
  dtpHasta.Clear;
end;

procedure TfrmMtoModalAddPreciosTar.FormDestroy(Sender: TObject);
begin
  chkSkus.Images := nil;
  SetLength(FOpcionesSkus, 0);
  FImagenesColores := nil;
end;

function TfrmMtoModalAddPreciosTar.CrearMuestraColor(
  const AHex: string): Integer;
var
  iAzul: Integer;
  iRojo: Integer;
  iVerde: Integer;
  oMuestra: TBitmap;
begin
  Result := -1;
  if DescomponerHexAtributo(AHex, iRojo, iVerde, iAzul) then
  begin
    oMuestra := TBitmap.Create;
    try
      oMuestra.SetSize(FImagenesColores.Width, FImagenesColores.Height);
      oMuestra.Canvas.Brush.Color := TColor(RGB(iRojo, iVerde, iAzul));
      oMuestra.Canvas.FillRect(
        Rect(0, 0, oMuestra.Width, oMuestra.Height));
      oMuestra.Canvas.Brush.Style := bsClear;
      oMuestra.Canvas.Pen.Color := clGray;
      oMuestra.Canvas.Rectangle(
        0, 0, oMuestra.Width, oMuestra.Height);
      Result := FImagenesColores.Add(oMuestra, nil);
    finally
      FreeAndNil(oMuestra);
    end;
  end;
end;

procedure TfrmMtoModalAddPreciosTar.AsignarRotulosEjes(
  const AEjeFila, AEjePivote: string);
begin
  FEjeFila := Trim(AEjeFila);
  FEjePivote := Trim(AEjePivote);
  if (FEjeFila <> '') and (FEjePivote <> '') then
    lblSkus.Caption := Format(SCaptionSeleccioneSkuEjesTarifa,
      [LowerCase(FEjeFila), LowerCase(FEjePivote)]);
end;

procedure TfrmMtoModalAddPreciosTar.CargarSkus(
  const ASkus: TOpcionesSkuTarifaArticulo);
var
  i: Integer;
  oItem: TcxCheckListBoxItem;
begin
  chkSkus.Items.Clear;
  FImagenesColores.Clear;
  FOpcionesSkus := System.Copy(ASkus, 0, Length(ASkus));
  for i := 0 to High(FOpcionesSkus) do
  begin
    oItem := chkSkus.Items.Add;
    oItem.Tag := i;
    oItem.Text := FOpcionesSkus[i].CodigoSku;
    if FOpcionesSkus[i].EsTalla then
    begin
      if FEjePivote <> '' then
        oItem.Text := Format(SInfoSkuEjePrecioTarifa,
          [oItem.Text, FEjePivote, FOpcionesSkus[i].Talla])
      else
        oItem.Text := Format(SInfoSkuTallaPrecioTarifa,
          [oItem.Text, FOpcionesSkus[i].Talla]);
    end;
    if Pos('/*/', FOpcionesSkus[i].CodigoSku) > 0 then
    begin
      if (FEjePivote <> '') and (FEjeFila = '') then
        oItem.Text := Format(SInfoSkuEjePrecioTarifa,
          [FOpcionesSkus[i].CodigoSku, FEjePivote,
           FOpcionesSkus[i].Talla])
      else if (FEjePivote <> '') and (FEjeFila <> '') then
        oItem.Text := Format(SInfoEjeCualquierValorTarifa,
          [FOpcionesSkus[i].CodigoSku, FEjePivote,
           FOpcionesSkus[i].Talla, LowerCase(FEjeFila)])
      else
        oItem.Text := Format(SInfoTallaCualquierColorTarifa,
          [FOpcionesSkus[i].CodigoSku, FOpcionesSkus[i].Talla]);
    end;
    if FOpcionesSkus[i].EsTalla then
      oItem.ImageIndex := -1
    else
      oItem.ImageIndex := CrearMuestraColor(FOpcionesSkus[i].HexColor);
  end;
end;

procedure TfrmMtoModalAddPreciosTar.CargarTarifas(const ATarifas: TStrings);
var
  i: Integer;
begin
  chkTarifas.Items.Clear;
  for i := 0 to ATarifas.Count - 1 do
    chkTarifas.Items.Add.Text := ATarifas[i];
end;

function TfrmMtoModalAddPreciosTar.FechaDesde: TDate;
begin
  Result := dtpDesde.Date;
end;

function TfrmMtoModalAddPreciosTar.TieneFechaHasta: Boolean;
begin
  Result := not VarIsNull(dtpHasta.EditValue);
end;

function TfrmMtoModalAddPreciosTar.FechaHasta: TDate;
begin
  Result := dtpHasta.Date;
end;

procedure TfrmMtoModalAddPreciosTar.ObtenerSkusSeleccionados(AOut: TStrings);
var
  i: Integer;
begin
  AOut.Clear;
  for i := 0 to chkSkus.Items.Count - 1 do
    if chkSkus.Items[i].Checked then
      AOut.Add(FOpcionesSkus[chkSkus.Items[i].Tag].CodigoSku);
end;

procedure TfrmMtoModalAddPreciosTar.ObtenerTarifasSeleccionadas(AOut: TStrings);
var
  i: Integer;
begin
  AOut.Clear;
  for i := 0 to chkTarifas.Items.Count - 1 do
    if chkTarifas.Items[i].Checked then
      AOut.Add(chkTarifas.Items[i].Text);
end;

end.
