{******************************************************************************}
{                                                                              }
{  Módulo:       fVentasFiltros                                                }
{    Tipo:       Formulario (App FMX)                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selección compacta de los filtros publicados por ventas/lineas.php.      }
{******************************************************************************}
unit fVentasFiltros;

interface

uses
  System.Classes,
  FMX.Forms, FMX.Controls, FMX.ListBox,
  VentasModelo;

type
  TFiltrosVentasAplicados = reference to procedure(
    const AFiltro: TFiltroLineas);

  TfrmFiltrosVentas = class(TForm)
  private
    FAlmacen: TComboBox;
    FContenido: TControl;
    FEmpresa: TComboBox;
    FFamilia: TComboBox;
    FFiltro: TFiltroLineas;
    FOpciones: TOpcionesVentas;
    FProveedor: TComboBox;
    FTemporada: TComboBox;
    function LeerSeleccion(ACombo: TComboBox;
      const AOpciones: TArrOpcionVenta): string;
    procedure CargarCombo(ACombo: TComboBox;
      const AOpciones: TArrOpcionVenta;
      const ASeleccion: string);
    procedure Construir;
    procedure CrearSelector(const ATitulo: string;
      out ACombo: TComboBox);
    procedure OnAplicarClick(Sender: TObject);
    procedure OnLimpiarClick(Sender: TObject);
  public
    class procedure Mostrar(AOwner: TComponent;
      const AOpciones: TOpcionesVentas;
      const AFiltro: TFiltroLineas;
      const AAlAplicar: TFiltrosVentasAplicados);
  end;

implementation

uses
  System.SysUtils, System.Types, System.UITypes, System.Threading,
  FMX.Types, FMX.Layouts, FMX.StdCtrls, TraduccionMovil;

procedure TfrmFiltrosVentas.CrearSelector(const ATitulo: string;
  out ACombo: TComboBox);
var
  lblTitulo: TLabel;
  laySelector: TLayout;
begin
  laySelector := TLayout.Create(Self);
  laySelector.Parent := FContenido;
  laySelector.Align := TAlignLayout.Top;
  laySelector.Height := 68;
  laySelector.Margins.Rect := RectF(12, 2, 12, 0);
  lblTitulo := TLabel.Create(Self);
  lblTitulo.Parent := laySelector;
  lblTitulo.Align := TAlignLayout.Top;
  lblTitulo.Height := 24;
  lblTitulo.Text := ATitulo;
  ACombo := TComboBox.Create(Self);
  ACombo.Parent := laySelector;
  ACombo.Align := TAlignLayout.Client;
end;

procedure TfrmFiltrosVentas.CargarCombo(ACombo: TComboBox;
  const AOpciones: TArrOpcionVenta;
  const ASeleccion: string);
var
  iOpcion: Integer;
  iSeleccionado: Integer;
  sNombre: string;
begin
  ACombo.Items.Add(Tr('Todos'));
  iSeleccionado := 0;
  for iOpcion := 0 to High(AOpciones) do
  begin
    sNombre := Trim(AOpciones[iOpcion].Nombre);
    if sNombre = '' then
      sNombre := AOpciones[iOpcion].Codigo;
    if (Trim(AOpciones[iOpcion].Codigo) <> '') and
       not SameText(sNombre, AOpciones[iOpcion].Codigo) then
      sNombre := sNombre + ' (' + AOpciones[iOpcion].Codigo + ')';
    ACombo.Items.Add(sNombre);
    if SameText(AOpciones[iOpcion].Codigo, ASeleccion) then
      iSeleccionado := iOpcion + 1;
  end;
  if (ASeleccion <> '') and (iSeleccionado = 0) then
  begin
    ACombo.Items.Add(ASeleccion);
    iSeleccionado := ACombo.Items.Count - 1;
  end;
  ACombo.ItemIndex := iSeleccionado;
end;

function TfrmFiltrosVentas.LeerSeleccion(ACombo: TComboBox;
  const AOpciones: TArrOpcionVenta): string;
var
  iOpcion: Integer;
begin
  Result := '';
  iOpcion := ACombo.ItemIndex - 1;
  if (iOpcion >= 0) and (iOpcion <= High(AOpciones)) then
    Result := AOpciones[iOpcion].Codigo
  else if ACombo.ItemIndex > 0 then
    Result := ACombo.Items[ACombo.ItemIndex];
end;

procedure TfrmFiltrosVentas.Construir;
var
  btnAplicar: TButton;
  btnLimpiar: TButton;
  layBotones: TLayout;
  scbSelectores: TVertScrollBox;
begin
  Self.Caption := Tr('Filtros de ventas');
  layBotones := TLayout.Create(Self);
  layBotones.Parent := Self;
  layBotones.Align := TAlignLayout.Bottom;
  layBotones.Height := 64;
  layBotones.Margins.Rect := RectF(12, 6, 12, 10);
  btnLimpiar := TButton.Create(Self);
  btnLimpiar.Parent := layBotones;
  btnLimpiar.Align := TAlignLayout.Left;
  btnLimpiar.Width := 120;
  btnLimpiar.Text := Tr('Limpiar');
  btnLimpiar.OnClick := OnLimpiarClick;
  btnAplicar := TButton.Create(Self);
  btnAplicar.Parent := layBotones;
  btnAplicar.Align := TAlignLayout.Client;
  btnAplicar.Margins.Left := 8;
  btnAplicar.Text := Tr('Aplicar filtros');
  btnAplicar.OnClick := OnAplicarClick;
  scbSelectores := TVertScrollBox.Create(Self);
  scbSelectores.Parent := Self;
  scbSelectores.Align := TAlignLayout.Client;
  FContenido := scbSelectores;
  CrearSelector(Tr('Empresa'), FEmpresa);
  CrearSelector(Tr('Almacén'), FAlmacen);
  CrearSelector(Tr('Temporada'), FTemporada);
  CrearSelector(Tr('Familia'), FFamilia);
  CrearSelector(Tr('Proveedor'), FProveedor);
  CargarCombo(FEmpresa, FOpciones.Empresas, FFiltro.Empresa);
  CargarCombo(FAlmacen, FOpciones.Almacenes, FFiltro.Almacen);
  CargarCombo(FTemporada, FOpciones.Temporadas, FFiltro.Temporada);
  CargarCombo(FFamilia, FOpciones.Familias, FFiltro.Familia);
  CargarCombo(FProveedor, FOpciones.Proveedores, FFiltro.Proveedor);
end;

procedure TfrmFiltrosVentas.OnAplicarClick(Sender: TObject);
begin
  FFiltro.Empresa := LeerSeleccion(FEmpresa, FOpciones.Empresas);
  FFiltro.Almacen := LeerSeleccion(FAlmacen, FOpciones.Almacenes);
  FFiltro.Temporada := LeerSeleccion(
    FTemporada, FOpciones.Temporadas);
  FFiltro.Familia := LeerSeleccion(FFamilia, FOpciones.Familias);
  FFiltro.Proveedor := LeerSeleccion(
    FProveedor, FOpciones.Proveedores);
  ModalResult := mrOk;
end;

procedure TfrmFiltrosVentas.OnLimpiarClick(Sender: TObject);
begin
  FFiltro := Default(TFiltroLineas);
  ModalResult := mrOk;
end;

class procedure TfrmFiltrosVentas.Mostrar(AOwner: TComponent;
  const AOpciones: TOpcionesVentas;
  const AFiltro: TFiltroLineas;
  const AAlAplicar: TFiltrosVentasAplicados);
var
  frm: TfrmFiltrosVentas;
  oAlAplicar: TFiltrosVentasAplicados;
begin
  // El callback se copia: el modal es asíncrono y no debe capturar el
  // parámetro de este método más allá de su vida.
  oAlAplicar := AAlAplicar;
  frm := TfrmFiltrosVentas.CreateNew(AOwner);
  frm.FOpciones := AOpciones;
  frm.FFiltro := AFiltro;
  try
    frm.Construir;
  except
    FreeAndNil(frm);
    raise;
  end;
  frm.ShowModal(
    procedure(AResult: TModalResult)
    begin
      if (AResult = mrOk) and Assigned(oAlAplicar) then
        oAlAplicar(frm.FFiltro);
      TThread.ForceQueue(nil,
        procedure
        begin
          frm.Free;
        end);
    end);
end;

end.
