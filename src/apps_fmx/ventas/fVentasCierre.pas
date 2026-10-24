{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasCierre                                                 }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Resumen y detalle de un cierre de caja publicado en la web.              }
{******************************************************************************}
unit fVentasCierre;

interface

uses
  System.Classes,
  FMX.Forms, FMX.Controls,
  VentasModelo;

type
  TfrmCierreVenta = class(TForm)
  private
    FContenido: TControl;
    procedure AgregarDato(const AEtiqueta, AValor: string);
    procedure AgregarDetalles(const ATitulo: string;
      const ADetalles: TArrDetalleCierreVenta);
    procedure AgregarSeccion(const ATitulo: string);
    procedure Construir(const ACierre: TCierreVenta);
    procedure OnCerrarClick(Sender: TObject);
  public
    class procedure Mostrar(AOwner: TComponent;
      const ACierre: TCierreVenta);
  end;

implementation

uses
  System.SysUtils, System.Types, System.UITypes, System.Threading,
  FMX.Types, FMX.Layouts, FMX.StdCtrls, TraduccionMovil;

function Moneda(AValor: Double): string;
begin
  Result := FormatFloat('#,##0.00', AValor, FormatoIdioma) + ' €';
end;

procedure TfrmCierreVenta.AgregarDato(
  const AEtiqueta, AValor: string);
var
  lblEtiqueta: TLabel;
  lblValor: TLabel;
  layFila: TLayout;
begin
  layFila := TLayout.Create(Self);
  layFila.Parent := FContenido;
  layFila.Align := TAlignLayout.Top;
  layFila.Height := 38;
  layFila.Margins.Bottom := 2;
  lblEtiqueta := TLabel.Create(Self);
  lblEtiqueta.Parent := layFila;
  lblEtiqueta.Align := TAlignLayout.Left;
  lblEtiqueta.Width := 142;
  lblEtiqueta.Text := AEtiqueta;
  lblEtiqueta.TextSettings.FontColor := TAlphaColorRec.Gray;
  lblEtiqueta.StyledSettings :=
    lblEtiqueta.StyledSettings - [TStyledSetting.FontColor];
  lblValor := TLabel.Create(Self);
  lblValor.Parent := layFila;
  lblValor.Align := TAlignLayout.Client;
  lblValor.Text := AValor;
  lblValor.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblValor.StyledSettings :=
    lblValor.StyledSettings - [TStyledSetting.Style];
  lblValor.WordWrap := True;
end;

procedure TfrmCierreVenta.AgregarSeccion(const ATitulo: string);
var
  lblTitulo: TLabel;
begin
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := FContenido;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 42;
  lblTitulo.Margins.Top := 8;
  lblTitulo.Text := ATitulo;
  lblTitulo.TextSettings.Font.Size := 16;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
end;

procedure TfrmCierreVenta.AgregarDetalles(const ATitulo: string;
  const ADetalles: TArrDetalleCierreVenta);
var
  iDetalle: Integer;
  lblDetalle: TLabel;
  lblTitulo: TLabel;
  layDetalle: TLayout;
begin
  if Length(ADetalles) > 0 then
  begin
    AgregarSeccion(ATitulo);
    for iDetalle := 0 to High(ADetalles) do
    begin
      layDetalle := TLayout.Create(Self);
      layDetalle.Parent := FContenido;
      layDetalle.Align := TAlignLayout.Top;
      layDetalle.Height := 76;
      layDetalle.Margins.Bottom := 4;
      lblTitulo := TLabel.Create(Self);
      lblTitulo.Parent := layDetalle;
      lblTitulo.Align := TAlignLayout.Top;
      lblTitulo.Height := 26;
      lblTitulo.Text := ADetalles[iDetalle].Titulo;
      lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
      lblTitulo.StyledSettings :=
        lblTitulo.StyledSettings - [TStyledSetting.Style];
      lblDetalle := TLabel.Create(Self);
      lblDetalle.Parent := layDetalle;
      lblDetalle.Align := TAlignLayout.Client;
      lblDetalle.Text := ADetalles[iDetalle].Detalle;
      lblDetalle.TextSettings.Font.Size := 12;
      lblDetalle.TextSettings.FontColor := TAlphaColorRec.Gray;
      lblDetalle.StyledSettings :=
        lblDetalle.StyledSettings - [TStyledSetting.FontColor];
      lblDetalle.WordWrap := True;
    end;
  end;
end;

procedure TfrmCierreVenta.Construir(const ACierre: TCierreVenta);
var
  btnCerrar: TButton;
  lblTitulo: TLabel;
  scbDatos: TVertScrollBox;
begin
  Self.Caption := Tr('Cierre de caja');
  btnCerrar := TButton.Create(Self);
  btnCerrar.Parent := Self;
  btnCerrar.Align := TAlignLayout.Bottom;
  btnCerrar.Height := 52;
  btnCerrar.Margins.Rect := RectF(12, 8, 12, 12);
  btnCerrar.Text := Tr('Cerrar');
  btnCerrar.OnClick := OnCerrarClick;
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := Self;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 56;
  lblTitulo.Margins.Rect := RectF(12, 10, 12, 0);
  lblTitulo.Text := TrF('Cierre %s', [ACierre.Codigo]);
  lblTitulo.TextSettings.Font.Size := 19;
  lblTitulo.TextSettings.Font.Style := [TFontStyle.fsBold];
  lblTitulo.StyledSettings := [];
  scbDatos := TVertScrollBox.Create(Self);
  scbDatos.Parent := Self;
  scbDatos.Align := TAlignLayout.Client;
  scbDatos.Margins.Rect := RectF(12, 0, 12, 0);
  FContenido := scbDatos;
  AgregarDato(Tr('Fecha y hora'),
    FechaVisible(ACierre.Fecha) + '  ' + ACierre.Hora);
  AgregarDato(Tr('Almacén'), ACierre.Almacen);
  AgregarDato(Tr('Caja'), ACierre.Caja);
  AgregarDato(Tr('Empresa'), ACierre.Empresa);
  AgregarSeccion(Tr('Resumen'));
  AgregarDato(Tr('Ventas'), Moneda(ACierre.Resumen.TotalVentas));
  AgregarDato(Tr('Recuento'), Moneda(ACierre.Resumen.TotalRecuento));
  AgregarDato(Tr('Diferencia'),
    Moneda(ACierre.Resumen.DiferenciaTotal));
  AgregarDato(Tr('Efectivo en caja'),
    Moneda(ACierre.Resumen.EfectivoCaja));
  AgregarDato(Tr('Efectivo dejado'),
    Moneda(ACierre.Resumen.EfectivoDejado));
  AgregarDetalles(Tr('Recuento'), ACierre.Recuento);
  AgregarDetalles(Tr('Temporadas'), ACierre.ResumenTemporadas);
  AgregarDetalles(Tr('Familias'), ACierre.ResumenFamilias);
  AgregarDetalles(Tr('Proveedores'), ACierre.ResumenProveedores);
  AgregarDetalles(Tr('Formas de pago'), ACierre.ResumenFormasPago);
  AgregarDetalles(Tr('Empleados'), ACierre.ResumenEmpleados);
  AgregarDetalles(Tr('Series'), ACierre.ResumenSeries);
end;

procedure TfrmCierreVenta.OnCerrarClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

class procedure TfrmCierreVenta.Mostrar(AOwner: TComponent;
  const ACierre: TCierreVenta);
var
  frm: TfrmCierreVenta;
begin
  frm := TfrmCierreVenta.CreateNew(AOwner);
  try
    frm.Construir(ACierre);
  except
    FreeAndNil(frm);
    raise;
  end;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
    end);
end;

end.
