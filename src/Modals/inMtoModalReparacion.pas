{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalReparacion                                          }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Alta de una reparación o un arreglo (lo que el cliente deja en            }
{    depósito): modalidad, tipo de servicio, trabajo y detalles, objeto con o  }
{    sin serie, cliente, fabricante en garantía, quién lo hace (operario o     }
{    externo), importes, presupuesto, cobro y fecha aproximada de entrega.     }
{    El tipo propone los valores. Graba con IRepositorioReparaciones.          }
{******************************************************************************}
unit inMtoModalReparacion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms,
  cxTextEdit, cxDropDownEdit, cxCheckBox, cxCalendar, cxCurrencyEdit,
  inMtoModalAceptCancel, inLibReparaciones, inLibReparacionesIntf;

type
  TfrmModalReparacion = class(TfrmModalAceptCancel)
  private
    FCatalogo: ICatalogoReparaciones;
    FRepositorio: IRepositorioReparaciones;
    FReparacion: TReparacionNueva;
    FTipos: TArray<TTipoServicio>;
    FEjecutores: TArray<TEjecutorServicio>;
    FId: Int64;
    FCargando: Boolean;
    FModalidadElegida: Boolean;
    FModalidad: TcxComboBox;
    FTipo: TcxComboBox;
    FTrabajo: TcxTextEdit;
    FDetalles: TcxTextEdit;
    FObservaciones: TcxTextEdit;
    FOrigen: TcxComboBox;
    FSku: TcxTextEdit;
    FSerie: TcxTextEdit;
    FObjeto: TcxTextEdit;
    FReferencia: TcxTextEdit;
    FSerieVenta: TcxTextEdit;
    FNumeroVenta: TcxTextEdit;
    FCliente: TcxTextEdit;
    FNombre: TcxTextEdit;
    FTelefono: TcxTextEdit;
    FFabricante: TcxTextEdit;
    FPrevista: TcxDateEdit;
    FEjecutor: TcxComboBox;
    FCantidad: TcxCurrencyEdit;
    FPrecioCliente: TcxCurrencyEdit;
    FPrecioCoste: TcxCurrencyEdit;
    FPresupuesto: TcxCheckBox;
    FModoCobro: TcxComboBox;
    FCobrado: TcxCheckBox;
    FSerieCobro: TcxTextEdit;
    FNumeroCobro: TcxTextEdit;
    procedure CrearControles;
    procedure CrearColumnaObjeto;
    procedure CrearColumnaCliente;
    procedure CrearRotulo(const ATexto: string; AColumna, AFila: Integer);
    procedure Colocar(AEditor: TControl; AColumna, AFila: Integer);
    function CrearTexto(const ARotulo: string; AColumna, AFila,
      ALongitud: Integer): TcxTextEdit;
    function CrearLista(const ARotulo: string;
      AColumna, AFila: Integer): TcxComboBox;
    function CrearImporte(const ARotulo: string;
      AColumna, AFila: Integer): TcxCurrencyEdit;
    function CrearCasilla(const ARotulo: string;
      AColumna, AFila: Integer): TcxCheckBox;
    procedure CargarListas;
    procedure Mostrar;
    procedure MostrarEjecutor;
    procedure TipoCambiado(Sender: TObject);
    procedure ModalidadCambiada(Sender: TObject);
    procedure Recoger;
    procedure RecogerEjecutor;
    function Grabar: Boolean;
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  protected
    procedure DoCreate; override;
  public
    constructor CreateReparacion(AOwner: TComponent;
      const ACatalogo: ICatalogoReparaciones;
      const ARepositorio: IRepositorioReparaciones;
      const ABase: TReparacionNueva);
    function CloseQuery: Boolean; override;
    // Número de la reparación grabada; 0 si se cancela.
    class function Ejecutar(AOwner: TComponent;
      const ACatalogo: ICatalogoReparaciones;
      const ARepositorio: IRepositorioReparaciones;
      const ABase: TReparacionNueva): Int64;
  end;

implementation

uses
  System.SysUtils, cxLabel, inLibMsgReparaciones, inLibMensajesVcl,
  inLibTrabajosCortinas, inMtoModalMedidasCliente;

const
  ANCHO_ROTULO = 200;
  ANCHO_EDITOR = 250;
  ANCHO_COLUMNA = 470;
  ALTO_FILA = 30;
  MARGEN = 12;
  FILAS = 14;
  MODALIDADES: array[0..2] of string = (MODALIDAD_REPARACION_PAGO,
    MODALIDAD_REPARACION_GARANTIA, MODALIDAD_REPARACION_CORTESIA);
  ORIGENES: array[0..2] of string = (ORIGEN_REPARACION_CLIENTE,
    ORIGEN_REPARACION_VENDIDO, ORIGEN_REPARACION_TIENDA);
  MODOS_COBRO: array[0..2] of string = (COBRO_REPARACION_RECOGIDA,
    COBRO_REPARACION_COMPRA, COBRO_REPARACION_GRATIS);

function IndiceDe(const AValores: array of string;
  const AValor: string): Integer;
var
  iIndice: Integer;
begin
  Result := 0;
  for iIndice := 0 to High(AValores) do
    if AValores[iIndice] = AValor then
      Result := iIndice;
end;

constructor TfrmModalReparacion.CreateReparacion(AOwner: TComponent;
  const ACatalogo: ICatalogoReparaciones;
  const ARepositorio: IRepositorioReparaciones;
  const ABase: TReparacionNueva);
begin
  inherited Create(AOwner);
  FCatalogo := ACatalogo;
  FRepositorio := ARepositorio;
  FReparacion := ABase;
  if FReparacion.Fecha = 0 then
    FReparacion.Fecha := Date;
  if not EsModalidadReparacion(FReparacion.Modalidad) then
    FReparacion.Modalidad := MODALIDAD_REPARACION_PAGO;
  if not EsOrigenReparacion(FReparacion.Origen) then
    FReparacion.Origen := ORIGEN_REPARACION_CLIENTE;
  if not EsModoCobroReparacion(FReparacion.ModoCobro) then
    FReparacion.ModoCobro := COBRO_REPARACION_RECOGIDA;
  if FReparacion.Cantidad <= 0 then
    FReparacion.Cantidad := 1;
  OnClose := CerrarSinLiberar;
  ClientWidth := ScaleValue(2 * ANCHO_COLUMNA + MARGEN);
  ClientHeight := ScaleValue(FILAS * ALTO_FILA + 3 * MARGEN) +
    pnlButton.Height;
  CrearControles;
  CargarListas;
  Mostrar;
end;

procedure TfrmModalReparacion.DoCreate;
begin
  inherited;
  Caption := STituloAltaReparacion;
end;

procedure TfrmModalReparacion.CrearRotulo(const ATexto: string;
  AColumna, AFila: Integer);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Transparent := True;
  oRotulo.Caption := ATexto;
  oRotulo.Left := ScaleValue(MARGEN + AColumna * ANCHO_COLUMNA);
  oRotulo.Top := ScaleValue(MARGEN + AFila * ALTO_FILA + 3);
end;

procedure TfrmModalReparacion.Colocar(AEditor: TControl;
  AColumna, AFila: Integer);
begin
  AEditor.Parent := pnlBody;
  AEditor.Left := ScaleValue(MARGEN + ANCHO_ROTULO +
    AColumna * ANCHO_COLUMNA);
  AEditor.Top := ScaleValue(MARGEN + AFila * ALTO_FILA);
  AEditor.Width := ScaleValue(ANCHO_EDITOR);
end;

function TfrmModalReparacion.CrearTexto(const ARotulo: string;
  AColumna, AFila, ALongitud: Integer): TcxTextEdit;
begin
  CrearRotulo(ARotulo, AColumna, AFila);
  Result := TcxTextEdit.Create(Self);
  Colocar(Result, AColumna, AFila);
  Result.Properties.MaxLength := ALongitud;
end;

function TfrmModalReparacion.CrearLista(const ARotulo: string;
  AColumna, AFila: Integer): TcxComboBox;
begin
  CrearRotulo(ARotulo, AColumna, AFila);
  Result := TcxComboBox.Create(Self);
  Colocar(Result, AColumna, AFila);
  Result.Properties.DropDownListStyle := lsFixedList;
end;

function TfrmModalReparacion.CrearImporte(const ARotulo: string;
  AColumna, AFila: Integer): TcxCurrencyEdit;
begin
  CrearRotulo(ARotulo, AColumna, AFila);
  Result := TcxCurrencyEdit.Create(Self);
  Colocar(Result, AColumna, AFila);
  Result.Width := ScaleValue(120);
  Result.Properties.DisplayFormat := ',0.00';
  Result.Properties.DecimalPlaces := 2;
end;

function TfrmModalReparacion.CrearCasilla(const ARotulo: string;
  AColumna, AFila: Integer): TcxCheckBox;
begin
  Result := TcxCheckBox.Create(Self);
  Colocar(Result, AColumna, AFila);
  Result.Caption := ARotulo;
  Result.Transparent := True;
end;

// Columna 0: servicio y objeto.
procedure TfrmModalReparacion.CrearColumnaObjeto;
begin
  FModalidad := CrearLista(SRotuloModalidad, 0, 0);
  FTipo := CrearLista(SRotuloTipoServicio, 0, 1);
  FTrabajo := CrearTexto(SRotuloTrabajoReparacion, 0, 2, 500);
  FDetalles := CrearTexto(SRotuloDetallesReparacion, 0, 3, 500);
  FObservaciones := CrearTexto(SRotuloObservacionesReparacion, 0, 4, 500);
  FOrigen := CrearLista(SRotuloOrigenObjeto, 0, 6);
  FSku := CrearTexto(SRotuloSkuObjeto, 0, 7, 50);
  FSerie := CrearTexto(SRotuloSerieObjeto, 0, 8, 50);
  FObjeto := CrearTexto(SRotuloDescripcionObjeto, 0, 9, 200);
  FReferencia := CrearTexto(SRotuloReferenciaObjeto, 0, 10, 100);
  FSerieVenta := CrearTexto(SRotuloSerieVentaObjeto, 0, 11, 20);
  FNumeroVenta := CrearTexto(SRotuloNumeroVentaObjeto, 0, 12, 20);
end;

// Columna 1: cliente, quién lo hace, importes y cobro.
procedure TfrmModalReparacion.CrearColumnaCliente;
begin
  FCliente := CrearTexto(SRotuloCodigoClienteReparacion, 1, 0, 20);
  FNombre := CrearTexto(SRotuloClienteReparacion, 1, 1, 200);
  FTelefono := CrearTexto(SRotuloTelefonoReparacion, 1, 2, 40);
  FFabricante := CrearTexto(SRotuloFabricanteReparacion, 1, 3, 20);
  CrearRotulo(SRotuloEntregaAproximada, 1, 4);
  FPrevista := TcxDateEdit.Create(Self);
  Colocar(FPrevista, 1, 4);
  FPrevista.Width := ScaleValue(130);
  FEjecutor := CrearLista(SRotuloEjecutorReparacion, 1, 5);
  FCantidad := CrearImporte(SRotuloCantidadReparacion, 1, 6);
  FPrecioCliente := CrearImporte(SRotuloPrecioClienteReparacion, 1, 7);
  FPrecioCoste := CrearImporte(SRotuloPrecioCosteReparacion, 1, 8);
  FPresupuesto := CrearCasilla(SRotuloPresupuestoReparacion, 1, 9);
  FModoCobro := CrearLista(SRotuloModoCobroReparacion, 1, 10);
  FCobrado := CrearCasilla(SRotuloCobradoReparacion, 1, 11);
  FSerieCobro := CrearTexto(SRotuloSerieCobroReparacion, 1, 12, 20);
  FNumeroCobro := CrearTexto(SRotuloNumeroCobroReparacion, 1, 13, 20);
end;

procedure TfrmModalReparacion.CrearControles;
begin
  CrearColumnaObjeto;
  CrearColumnaCliente;
end;

procedure TfrmModalReparacion.CargarListas;
var
  Tipo: TTipoServicio;
  Ejecutor: TEjecutorServicio;
  sValor: string;
begin
  FTipos := FCatalogo.Tipos(FReparacion.Categoria);
  FEjecutores := FCatalogo.Ejecutores;
  FTipo.Properties.Items.Add(SSinTipoServicio);
  for Tipo in FTipos do
    FTipo.Properties.Items.Add(Tipo.Categoria + ' - ' + Tipo.Descripcion);
  FEjecutor.Properties.Items.Add(SSinEjecutor);
  for Ejecutor in FEjecutores do
    FEjecutor.Properties.Items.Add(
      TextoEjecutorReparacion(Ejecutor.Tipo) + ': ' + Ejecutor.Nombre);
  for sValor in MODALIDADES do
    FModalidad.Properties.Items.Add(TextoModalidadReparacion(sValor));
  for sValor in ORIGENES do
    FOrigen.Properties.Items.Add(TextoOrigenReparacion(sValor));
  for sValor in MODOS_COBRO do
    FModoCobro.Properties.Items.Add(TextoModoCobroReparacion(sValor));
  FTipo.ItemIndex := 0;
  FTipo.Properties.OnChange := TipoCambiado;
  FModalidad.Properties.OnChange := ModalidadCambiada;
end;

procedure TfrmModalReparacion.MostrarEjecutor;
var
  iIndice: Integer;
begin
  FEjecutor.ItemIndex := 0;
  for iIndice := 0 to High(FEjecutores) do
    if (FEjecutores[iIndice].Tipo = FReparacion.TipoEjecutor) and
       (((FReparacion.TipoEjecutor = EJECUTOR_REPARACION_OPERARIO) and
         (FEjecutores[iIndice].Codigo = FReparacion.Empleado)) or
        ((FReparacion.TipoEjecutor = EJECUTOR_REPARACION_EXTERNO) and
         (FEjecutores[iIndice].Codigo = FReparacion.Proveedor))) then
      FEjecutor.ItemIndex := iIndice + 1;
end;

procedure TfrmModalReparacion.Mostrar;
begin
  FCargando := True;
  try
    FModalidad.ItemIndex := IndiceDe(MODALIDADES, FReparacion.Modalidad);
    FTrabajo.Text := FReparacion.Trabajo;
    FDetalles.Text := FReparacion.Detalles;
    FObservaciones.Text := FReparacion.Observaciones;
    FOrigen.ItemIndex := IndiceDe(ORIGENES, FReparacion.Origen);
    FSku.Text := FReparacion.Sku;
    FSerie.Text := FReparacion.Serie;
    FObjeto.Text := FReparacion.DescripcionObjeto;
    FReferencia.Text := FReparacion.ReferenciaObjeto;
    FSerieVenta.Text := FReparacion.SerieVenta;
    FNumeroVenta.Text := FReparacion.NumeroVenta;
    FCliente.Text := FReparacion.Cliente;
    FNombre.Text := FReparacion.NombreCliente;
    FTelefono.Text := FReparacion.TelefonoCliente;
    FFabricante.Text := FReparacion.Fabricante;
    if FReparacion.FechaPrevista > 0 then
      FPrevista.Date := FReparacion.FechaPrevista;
    MostrarEjecutor;
    FCantidad.Value := FReparacion.Cantidad;
    FPrecioCliente.Value := FReparacion.PrecioCliente;
    FPrecioCoste.Value := FReparacion.PrecioCoste;
    FPresupuesto.Checked := FReparacion.EsPresupuesto;
    FModoCobro.ItemIndex := IndiceDe(MODOS_COBRO, FReparacion.ModoCobro);
    FCobrado.Checked := FReparacion.EsCobrado;
    FSerieCobro.Text := FReparacion.SerieCobro;
    FNumeroCobro.Text := FReparacion.NumeroCobro;
  finally
    FCargando := False;
  end;
end;

// El tipo propone modalidad, trabajo, ejecutor, importes, cobro y fecha;
// lo tecleado del objeto y del cliente se conserva.
procedure TfrmModalReparacion.TipoCambiado(Sender: TObject);
begin
  if not FCargando and (FTipo.ItemIndex > 0) then
  begin
    Recoger;
    FReparacion.Trabajo := '';
    if FModalidadElegida then
    begin
      // El tipo propone los demás datos sin cambiar la decisión del usuario.
      FReparacion := AplicarTipoServicio(FReparacion,
        FTipos[FTipo.ItemIndex - 1], True);
    end
    else
      FReparacion := AplicarTipoServicio(FReparacion,
        FTipos[FTipo.ItemIndex - 1]);
    Mostrar;
  end;
end;

// En garantía y cortesía el cliente no paga.
procedure TfrmModalReparacion.ModalidadCambiada(Sender: TObject);
begin
  if not FCargando then
  begin
    FModalidadElegida := True;
    Recoger;
    FReparacion := NormalizarCobroReparacion(FReparacion);
    Mostrar;
  end;
end;

procedure TfrmModalReparacion.RecogerEjecutor;
var
  Ejecutor: TEjecutorServicio;
begin
  FReparacion.TipoEjecutor := '';
  FReparacion.Empleado := '';
  FReparacion.Proveedor := '';
  if FEjecutor.ItemIndex > 0 then
  begin
    Ejecutor := FEjecutores[FEjecutor.ItemIndex - 1];
    FReparacion.TipoEjecutor := Ejecutor.Tipo;
    if Ejecutor.Tipo = EJECUTOR_REPARACION_OPERARIO then
      FReparacion.Empleado := Ejecutor.Codigo
    else
      FReparacion.Proveedor := Ejecutor.Codigo;
  end;
end;

procedure TfrmModalReparacion.Recoger;
begin
  FReparacion.Modalidad := MODALIDADES[FModalidad.ItemIndex];
  FReparacion.Tipo := '';
  if FTipo.ItemIndex > 0 then
    FReparacion.Tipo := FTipos[FTipo.ItemIndex - 1].Codigo;
  FReparacion.Trabajo := Trim(FTrabajo.Text);
  FReparacion.Detalles := Trim(FDetalles.Text);
  FReparacion.Observaciones := Trim(FObservaciones.Text);
  FReparacion.Origen := ORIGENES[FOrigen.ItemIndex];
  FReparacion.Sku := Trim(FSku.Text);
  FReparacion.Serie := Trim(FSerie.Text);
  FReparacion.DescripcionObjeto := Trim(FObjeto.Text);
  FReparacion.ReferenciaObjeto := Trim(FReferencia.Text);
  FReparacion.SerieVenta := Trim(FSerieVenta.Text);
  FReparacion.NumeroVenta := Trim(FNumeroVenta.Text);
  FReparacion.Cliente := Trim(FCliente.Text);
  FReparacion.NombreCliente := Trim(FNombre.Text);
  FReparacion.TelefonoCliente := Trim(FTelefono.Text);
  FReparacion.Fabricante := Trim(FFabricante.Text);
  FReparacion.FechaPrevista := 0;
  if FPrevista.Date > 0 then
    FReparacion.FechaPrevista := FPrevista.Date;
  RecogerEjecutor;
  FReparacion.Cantidad := FCantidad.Value;
  FReparacion.PrecioCliente := FPrecioCliente.Value;
  FReparacion.PrecioCoste := FPrecioCoste.Value;
  FReparacion.EsPresupuesto := FPresupuesto.Checked;
  FReparacion.ModoCobro := MODOS_COBRO[FModoCobro.ItemIndex];
  FReparacion.EsCobrado := FCobrado.Checked;
  FReparacion.SerieCobro := Trim(FSerieCobro.Text);
  FReparacion.NumeroCobro := Trim(FNumeroCobro.Text);
end;

function TfrmModalReparacion.Grabar: Boolean;
var
  sError: string;
begin
  Recoger;
  FReparacion := NormalizarCobroReparacion(FReparacion);
  sError := ValidarReparacionNueva(FReparacion);
  Result := sError = '';
  if not Result then
    ShowMessage_fza(sError);
  FReparacion.IdMedicionCliente := '';
  if Result and (FTipo.ItemIndex > 0) then
    if FTipos[FTipo.ItemIndex - 1].ClaseServicio = CLASE_SERVICIO_TRAJE then
      Result := TfrmModalMedidasCliente.Elegir(Self, FReparacion.Cliente,
        FReparacion.IdMedicionCliente);
  if Result then
    FId := FRepositorio.Alta(FReparacion);
end;

function TfrmModalReparacion.CloseQuery: Boolean;
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
procedure TfrmModalReparacion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class function TfrmModalReparacion.Ejecutar(AOwner: TComponent;
  const ACatalogo: ICatalogoReparaciones;
  const ARepositorio: IRepositorioReparaciones;
  const ABase: TReparacionNueva): Int64;
var
  oFormulario: TfrmModalReparacion;
begin
  oFormulario := TfrmModalReparacion.CreateReparacion(AOwner, ACatalogo,
    ARepositorio, ABase);
  try
    oFormulario.ShowModal;
    Result := oFormulario.FId;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
