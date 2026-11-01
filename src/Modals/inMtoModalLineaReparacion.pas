{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalLineaReparacion                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Alta o cambio de una línea de una reparación: mano de obra con su         }
{    ejecutor (operario o empresa externa) o material (SKU), cantidad u        }
{    horas, precio al cliente y coste. Graba con IRepositorioReparaciones.     }
{******************************************************************************}
unit inMtoModalLineaReparacion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms,
  cxTextEdit, cxDropDownEdit, cxCurrencyEdit,
  inMtoModalAceptCancel, inLibReparaciones, inLibReparacionesIntf;

type
  TfrmModalLineaReparacion = class(TfrmModalAceptCancel)
  private
    FCatalogo: ICatalogoReparaciones;
    FRepositorio: IRepositorioReparaciones;
    FLinea: TLineaReparacion;
    FTipos: TArray<TTipoServicio>;
    FEjecutores: TArray<TEjecutorServicio>;
    FId: Int64;
    FTipoLinea: TcxComboBox;
    FTipo: TcxComboBox;
    FDescripcion: TcxTextEdit;
    FEjecutor: TcxComboBox;
    FSku: TcxTextEdit;
    FCantidad: TcxCurrencyEdit;
    FPrecioCliente: TcxCurrencyEdit;
    FPrecioCoste: TcxCurrencyEdit;
    procedure CrearControles;
    function CrearRotuloYEditor(const ARotulo: string; AFila: Integer;
      AEditor: TControl): TControl;
    function CrearImporte(const ARotulo: string;
      AFila: Integer): TcxCurrencyEdit;
    procedure CargarListas;
    procedure Mostrar;
    procedure TipoCambiado(Sender: TObject);
    procedure Recoger;
    function Grabar: Boolean;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
  public
    constructor CreateLinea(AOwner: TComponent;
      const ACatalogo: ICatalogoReparaciones;
      const ARepositorio: IRepositorioReparaciones;
      const ALinea: TLineaReparacion);
    function CloseQuery: Boolean; override;
    // Id de la línea grabada; 0 si se cancela.
    class function Ejecutar(AOwner: TComponent;
      const ACatalogo: ICatalogoReparaciones;
      const ARepositorio: IRepositorioReparaciones;
      const ALinea: TLineaReparacion): Int64;
  end;

implementation

uses
  inLibMsgReparacionesCircuito,
  System.SysUtils, cxLabel, inLibMsgReparaciones, inLibMensajesVcl;

const
  ANCHO_ROTULO = 150;
  ANCHO_EDITOR = 300;
  ALTO_FILA = 32;
  MARGEN = 12;
  TIPOS_LINEA: array[0..1] of string = (LINEA_REPARACION_MANO_OBRA,
    LINEA_REPARACION_MATERIAL);

constructor TfrmModalLineaReparacion.CreateLinea(AOwner: TComponent;
  const ACatalogo: ICatalogoReparaciones;
  const ARepositorio: IRepositorioReparaciones;
  const ALinea: TLineaReparacion);
begin
  inherited Create(AOwner);
  FCatalogo := ACatalogo;
  FRepositorio := ARepositorio;
  FLinea := ALinea;
  if FLinea.TipoLinea = '' then
    FLinea.TipoLinea := LINEA_REPARACION_MANO_OBRA;
  if FLinea.Cantidad <= 0 then
    FLinea.Cantidad := 1;
  OnClose := CerrarSinLiberar;
  ClientWidth := ScaleValue(MARGEN * 2 + ANCHO_ROTULO + ANCHO_EDITOR);
  ClientHeight := ScaleValue(8 * ALTO_FILA + 3 * MARGEN) + pnlButton.Height;
  CrearControles;
  CargarListas;
  Mostrar;
end;

procedure TfrmModalLineaReparacion.DoCreate;
begin
  inherited;
  Caption := STituloLineaReparacion;
end;

function TfrmModalLineaReparacion.CrearRotuloYEditor(const ARotulo: string;
  AFila: Integer; AEditor: TControl): TControl;
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Transparent := True;
  oRotulo.Caption := ARotulo;
  oRotulo.SetBounds(ScaleValue(MARGEN),
    ScaleValue(MARGEN + AFila * ALTO_FILA + 3), ScaleValue(ANCHO_ROTULO), 22);
  AEditor.Parent := pnlBody;
  AEditor.Left := ScaleValue(MARGEN + ANCHO_ROTULO);
  AEditor.Top := ScaleValue(MARGEN + AFila * ALTO_FILA);
  AEditor.Width := ScaleValue(ANCHO_EDITOR);
  Result := AEditor;
end;

function TfrmModalLineaReparacion.CrearImporte(const ARotulo: string;
  AFila: Integer): TcxCurrencyEdit;
begin
  Result := CrearRotuloYEditor(ARotulo, AFila,
    TcxCurrencyEdit.Create(Self)) as TcxCurrencyEdit;
  Result.Width := ScaleValue(120);
  Result.Properties.DisplayFormat := ',0.00';
  Result.Properties.DecimalPlaces := 2;
end;

procedure TfrmModalLineaReparacion.CrearControles;
begin
  FTipoLinea := CrearRotuloYEditor(SRotuloTipoLinea, 0,
    TcxComboBox.Create(Self)) as TcxComboBox;
  FTipoLinea.Properties.DropDownListStyle := lsFixedList;
  FTipo := CrearRotuloYEditor(SRotuloTipoServicio, 1,
    TcxComboBox.Create(Self)) as TcxComboBox;
  FTipo.Properties.DropDownListStyle := lsFixedList;
  FDescripcion := CrearRotuloYEditor(SRotuloDescripcionLinea, 2,
    TcxTextEdit.Create(Self)) as TcxTextEdit;
  FDescripcion.Properties.MaxLength := 200;
  FEjecutor := CrearRotuloYEditor(SRotuloEjecutorReparacion, 3,
    TcxComboBox.Create(Self)) as TcxComboBox;
  FEjecutor.Properties.DropDownListStyle := lsFixedList;
  FSku := CrearRotuloYEditor(SCircuitoCodigoManual, 4,
    TcxTextEdit.Create(Self)) as TcxTextEdit;
  FSku.Properties.MaxLength := 50;
  FCantidad := CrearImporte(SRotuloCantidadReparacion, 5);
  FPrecioCliente := CrearImporte(SRotuloPrecioClienteReparacion, 6);
  FPrecioCoste := CrearImporte(SRotuloPrecioCosteReparacion, 7);
end;

procedure TfrmModalLineaReparacion.CargarListas;
var
  Tipo: TTipoServicio;
  Ejecutor: TEjecutorServicio;
begin
  FTipos := FCatalogo.Tipos('');
  FEjecutores := FCatalogo.Ejecutores;
  FTipoLinea.Properties.Items.Add(SLineaManoObra);
  FTipoLinea.Properties.Items.Add(SLineaMaterial);
  FTipo.Properties.Items.Add(SSinTipoServicio);
  for Tipo in FTipos do
    FTipo.Properties.Items.Add(Tipo.Categoria + ' - ' + Tipo.Descripcion);
  FEjecutor.Properties.Items.Add(SSinEjecutor);
  for Ejecutor in FEjecutores do
    FEjecutor.Properties.Items.Add(
      TextoEjecutorReparacion(Ejecutor.Tipo) + ': ' + Ejecutor.Nombre);
  FTipo.ItemIndex := 0;
  FTipo.Properties.OnChange := TipoCambiado;
end;

procedure TfrmModalLineaReparacion.Mostrar;
var
  iIndice: Integer;
begin
  FTipoLinea.ItemIndex := Ord(FLinea.TipoLinea = LINEA_REPARACION_MATERIAL);
  FDescripcion.Text := FLinea.Descripcion;
  FEjecutor.ItemIndex := 0;
  for iIndice := 0 to High(FEjecutores) do
    if (FEjecutores[iIndice].Tipo = FLinea.TipoEjecutor) and
       ((FEjecutores[iIndice].Codigo = FLinea.Empleado) or
        (FEjecutores[iIndice].Codigo = FLinea.Proveedor)) then
      FEjecutor.ItemIndex := iIndice + 1;
  FSku.Text := FLinea.Sku;
  FCantidad.Value := FLinea.Cantidad;
  FPrecioCliente.Value := FLinea.PrecioCliente;
  FPrecioCoste.Value := FLinea.PrecioCoste;
end;

// El tipo propone descripción, ejecutor, cantidad y precios.
procedure TfrmModalLineaReparacion.TipoCambiado(Sender: TObject);
var
  Tipo: TTipoServicio;
begin
  if FTipo.ItemIndex > 0 then
  begin
    Recoger;
    Tipo := FTipos[FTipo.ItemIndex - 1];
    FLinea.Tipo := Tipo.Codigo;
    FLinea.TipoLinea := LINEA_REPARACION_MANO_OBRA;
    FLinea.Descripcion := Tipo.Descripcion;
    FLinea.TipoEjecutor := Tipo.TipoEjecutor;
    FLinea.Empleado := Tipo.Empleado;
    FLinea.Proveedor := Tipo.Proveedor;
    FLinea.Cantidad := Tipo.Cantidad;
    FLinea.PrecioCliente := Tipo.PrecioCliente;
    FLinea.PrecioCoste := Tipo.PrecioCoste;
    Mostrar;
  end;
end;

procedure TfrmModalLineaReparacion.Recoger;
var
  Ejecutor: TEjecutorServicio;
begin
  FLinea.TipoLinea := TIPOS_LINEA[FTipoLinea.ItemIndex];
  FLinea.Descripcion := Trim(FDescripcion.Text);
  FLinea.TipoEjecutor := '';
  FLinea.Empleado := '';
  FLinea.Proveedor := '';
  if (FLinea.TipoLinea = LINEA_REPARACION_MANO_OBRA) and
     (FEjecutor.ItemIndex > 0) then
  begin
    Ejecutor := FEjecutores[FEjecutor.ItemIndex - 1];
    FLinea.TipoEjecutor := Ejecutor.Tipo;
    if Ejecutor.Tipo = EJECUTOR_REPARACION_OPERARIO then
      FLinea.Empleado := Ejecutor.Codigo
    else
      FLinea.Proveedor := Ejecutor.Codigo;
  end;
  FLinea.Sku := '';
  if FLinea.TipoLinea = LINEA_REPARACION_MATERIAL then
    FLinea.Sku := Trim(FSku.Text);
  FLinea.Cantidad := FCantidad.Value;
  FLinea.PrecioCliente := FPrecioCliente.Value;
  FLinea.PrecioCoste := FPrecioCoste.Value;
end;

function TfrmModalLineaReparacion.Grabar: Boolean;
var
  sError: string;
begin
  Recoger;
  sError := ValidarLineaReparacion(FLinea);
  Result := sError = '';
  if Result then
    FId := FRepositorio.GuardarLinea(FLinea)
  else
    ShowMessage_fza(sError);
end;

function TfrmModalLineaReparacion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') and (FId = 0) then
  begin
    try
      Result := Grabar;
    except
      on E: Exception do
      begin
        Result := False;
        ShowMessage_fza(E.Message);
      end;
    end;
    if not Result then
      sFicha := 'N';
  end;
end;

// Ejecutar libera el formulario: el cierre no lo destruye.
procedure TfrmModalLineaReparacion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalLineaReparacion.Ejecutar(AOwner: TComponent;
  const ACatalogo: ICatalogoReparaciones;
  const ARepositorio: IRepositorioReparaciones;
  const ALinea: TLineaReparacion): Int64;
var
  oFormulario: TfrmModalLineaReparacion;
begin
  oFormulario := TfrmModalLineaReparacion.CreateLinea(AOwner, ACatalogo,
    ARepositorio, ALinea);
  try
    oFormulario.ShowModal;
    Result := oFormulario.FId;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
