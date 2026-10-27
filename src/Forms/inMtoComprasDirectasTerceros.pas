{******************************************************************************}
{  Módulo:       inMtoComprasDirectasTerceros                                  }
{    Tipo:       Formulario (Mto)                                              }
{   Fecha:       26/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{******************************************************************************}
unit inMtoComprasDirectasTerceros;

interface

uses
  System.Classes, Vcl.Forms, Data.DB, cxPC, cxCheckBox, cxDBEdit,
  cxCalendar, cxScrollBox,
  inMtoFacturasCompra, inLibPermisosIntf,
  UniDataComprasPantallaComposicion;

type
  TfrmMtoComprasDirectasTerceros = class(TfrmMtoFacturasCompra)
  private
    FComponer: TComponerFacturaCompraPantalla;
    FTratamientoAgricola: TcxDBCheckBox;
    FPorcentajeCompensacion: TcxDBCurrencyEdit;
    FTotalCompensacion: TcxDBCurrencyEdit;
    FAcuerdo: TcxDBCheckBox;
    FRepresentacion: TcxDBCheckBox;
    FFechaContable: TcxDBDateEdit;
    FCuotaDeducible: TcxDBCurrencyEdit;
    FPaginaFiscal: TcxTabSheet;
    FContenedorFiscal: TcxScrollBox;
    FActualizandoTratamiento: Boolean;
    procedure CrearControlesFiscales;
    procedure CrearControlesCompensacion;
    function EnviarRegistroFiscalActual: string;
    procedure CambiarTratamientoAgricola(Sender: TObject);
    procedure ImprimirReciboPago(Sender: TObject);
    procedure EmitirFiscal(Sender: TObject);
    procedure CrearControlesEnvioFiscal;
    procedure ComponerServicios;
  public
    constructor Create(AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const AComponer: TComponerFacturaCompraPantalla); reintroduce;
    procedure CrearTablaPrincipal; override;
    procedure AplicarEtiquetas; override;
    function EsPantallaCompraDirecta: Boolean; override;
  end;

function CrearComprasDirectasTercerosInyectada(AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerFacturaCompraPantalla): TForm;

implementation

uses
  System.SysUtils, Vcl.Controls, cxLabel, cxButtons, cxCurrencyEdit,
  inLibMsgCompras,
  cxDBLabel,
  inLibRegistroPantallas, inLibReagpVcl, inLibComprasDirectas,
  inMtoFacturasCompraPagosVcl, UniDataComprasDirectasFiscal,
  inLibMensajesVcl;

{$R *.dfm}


constructor TfrmMtoComprasDirectasTerceros.Create(AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerFacturaCompraPantalla);
begin
  if not Assigned(AComponer) then
    raise EArgumentNilException.Create('AComponer');
  FComponer := AComponer;
  inherited Create(AOwner, AContexto);
end;

function CrearComprasDirectasTercerosInyectada(AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerFacturaCompraPantalla): TForm;
begin
  Result := TfrmMtoComprasDirectasTerceros.Create(AOwner,
    AContexto, AComponer);
end;

function TfrmMtoComprasDirectasTerceros.EsPantallaCompraDirecta: Boolean;
begin
  Result := True;
end;

procedure TfrmMtoComprasDirectasTerceros.ComponerServicios;
var
  oContexto: TContextoFacturaCompraPantalla;
  oEntrada: TEntradaDocumentoCompraPantalla;
begin
  oEntrada := Default(TEntradaDocumentoCompraPantalla);
  oEntrada.Conexion := dmmFacturasCompra.unqryTablaG.Connection;
  oEntrada.Cabecera := dmmFacturasCompra.unqryTablaG;
  oEntrada.Lineas := dmmFacturasCompra.unqryFacturasCompraLineas;
  FComponer(oEntrada, oContexto);
  FAplicacionArticuloCompra := oContexto.AplicacionArticulo;
  FValidadorArticulos := oContexto.ValidadorArticulos;
  FLookupAtributos := oContexto.LookupAtributos;
  FBusquedaProveedores := oContexto.BusquedaProveedores;
  FBusquedasArticulos := oContexto.BusquedasArticulos;
  FRepositorioSeleccionBanco := oContexto.SeleccionBanco;
  FComponer := nil;
end;

procedure TfrmMtoComprasDirectasTerceros.CrearTablaPrincipal;
var
  oBoton: TcxButton;
begin
  inherited;
  ComponerServicios;
  CrearControlesFiscales;
  CrearControlesEnvioFiscal;
  oBoton := TcxButton.Create(Self);
  oBoton.Name := 'btnImprimirReciboPago';
  oBoton.Parent := pnlEfectosTop;
  oBoton.SetBounds(344, 5, 190, 26);
  oBoton.Caption := SImprimirReciboPago;
  oBoton.OnClick := ImprimirReciboPago;
  btnCODIGO_EMP_FACC.Enabled := False;
end;

function CrearRotulo(AOwner: TComponent; AParent: TWinControl;
  const ATexto: string; ATop: Integer): TcxLabel;
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(AOwner);
  oRotulo.Parent := AParent;
  oRotulo.Transparent := True;
  oRotulo.SetBounds(16, ATop, 240, 22);
  oRotulo.Caption := ATexto;
  Result := oRotulo;
end;

procedure TfrmMtoComprasDirectasTerceros.CrearControlesFiscales;
begin
  FPaginaFiscal := TcxTabSheet.Create(Self);
  FPaginaFiscal.PageControl := pcFactura;
  FPaginaFiscal.Caption := SDatosFiscales;
  FContenedorFiscal := TcxScrollBox.Create(Self);
  FContenedorFiscal.Name := 'scrTratamientoFiscal';
  FContenedorFiscal.Parent := FPaginaFiscal;
  FContenedorFiscal.Align := alClient;
  FContenedorFiscal.AutoScroll := True;
  FTratamientoAgricola := TcxDBCheckBox.Create(Self);
  FTratamientoAgricola.Parent := FContenedorFiscal;
  FTratamientoAgricola.Name := 'chkTratamientoAgricola';
  FTratamientoAgricola.SetBounds(16, 16, 430, 26);
  FTratamientoAgricola.Caption := STratamientoAgricola;
  FTratamientoAgricola.DataBinding.DataSource := dsTablaG;
  FTratamientoAgricola.DataBinding.DataField := 'MODALIDAD_FACC';
  FTratamientoAgricola.Properties.ValueChecked := 'REAGP';
  FTratamientoAgricola.Properties.ValueUnchecked := 'AUTOFAC';
  FTratamientoAgricola.Properties.OnEditValueChanged :=
    CambiarTratamientoAgricola;
  FTratamientoAgricola.Visible := Assigned(ParametrosApp) and
    ParametrosApp.GetBool(PARAMETRO_USAR_REAGP, False);
  FAcuerdo := TcxDBCheckBox.Create(Self);
  FAcuerdo.Name := 'chkAcuerdoAutofactura';
  FAcuerdo.Parent := FContenedorFiscal;
  FAcuerdo.SetBounds(16, 54, 580, 26);
  FAcuerdo.Caption := SAcuerdoFacturacion;
  FAcuerdo.DataBinding.DataSource := dsTablaG;
  FAcuerdo.DataBinding.DataField := 'ESACUERDO_AUTOFAC_FACC';
  FAcuerdo.Properties.ValueChecked := 'S';
  FAcuerdo.Properties.ValueUnchecked := 'N';
  CrearControlesCompensacion;
end;

procedure TfrmMtoComprasDirectasTerceros.CrearControlesCompensacion;
begin
  CrearRotulo(Self, FContenedorFiscal, SPorcentajeCompensacion, 96).
    Visible := FTratamientoAgricola.Visible;
  FPorcentajeCompensacion := TcxDBCurrencyEdit.Create(Self);
  FPorcentajeCompensacion.Name := 'txtPorcentajeCompensacion';
  FPorcentajeCompensacion.Parent := FContenedorFiscal;
  FPorcentajeCompensacion.SetBounds(270, 96, 130, 26);
  FPorcentajeCompensacion.DataBinding.DataSource := dsTablaG;
  FPorcentajeCompensacion.DataBinding.DataField :=
    'PORCENTAJE_COMPENSACION_FACC';
  FPorcentajeCompensacion.Properties.DisplayFormat := '0.00';
  CrearRotulo(Self, FContenedorFiscal, STotalCompensacion, 136).
    Visible := FTratamientoAgricola.Visible;
  FTotalCompensacion := TcxDBCurrencyEdit.Create(Self);
  FTotalCompensacion.Name := 'txtTotalCompensacion';
  FTotalCompensacion.Parent := FContenedorFiscal;
  FTotalCompensacion.SetBounds(270, 136, 130, 26);
  FTotalCompensacion.DataBinding.DataSource := dsTablaG;
  FTotalCompensacion.DataBinding.DataField := 'TOTAL_COMPENSACION_FACC';
  FTotalCompensacion.Properties.ReadOnly := True;
  FPorcentajeCompensacion.Visible := FTratamientoAgricola.Visible;
  FTotalCompensacion.Visible := FTratamientoAgricola.Visible;
end;

procedure TfrmMtoComprasDirectasTerceros.CrearControlesEnvioFiscal;
var
  oBoton: TcxButton;
  oEstado: TcxDBLabel;
begin
  FRepresentacion := TcxDBCheckBox.Create(Self);
  FRepresentacion.Name := 'chkRepresentacionFiscal';
  FRepresentacion.Parent := FContenedorFiscal;
  FRepresentacion.SetBounds(16, 176, 660, 26);
  FRepresentacion.Caption := SRepresentacionFiscal;
  FRepresentacion.DataBinding.DataSource := dsTablaG;
  FRepresentacion.DataBinding.DataField := 'ESREPRESENTACION_FISCAL_FACC';
  FRepresentacion.Properties.ValueChecked := 'S';
  FRepresentacion.Properties.ValueUnchecked := 'N';
  CrearRotulo(Self, FContenedorFiscal, SFechaContable, 216);
  FFechaContable := TcxDBDateEdit.Create(Self);
  FFechaContable.Name := 'dteRegistroContable';
  FFechaContable.Parent := FContenedorFiscal;
  FFechaContable.SetBounds(270, 216, 160, 26);
  FFechaContable.DataBinding.DataSource := dsTablaG;
  FFechaContable.DataBinding.DataField := 'FECHA_REGISTRO_CONTABLE_FACC';
  CrearRotulo(Self, FContenedorFiscal, SCuotaDeducible, 256);
  FCuotaDeducible := TcxDBCurrencyEdit.Create(Self);
  FCuotaDeducible.Name := 'txtCuotaDeducible';
  FCuotaDeducible.Parent := FContenedorFiscal;
  FCuotaDeducible.SetBounds(270, 256, 160, 26);
  FCuotaDeducible.DataBinding.DataSource := dsTablaG;
  FCuotaDeducible.DataBinding.DataField := 'CUOTA_DEDUCIBLE_FACC';
  oBoton := TcxButton.Create(Self);
  oBoton.Parent := FContenedorFiscal;
  oBoton.SetBounds(16, 300, 240, 30);
  oBoton.Caption := SGenerarEnviarFiscal;
  oBoton.OnClick := EmitirFiscal;
  oEstado := TcxDBLabel.Create(Self);
  oEstado.Parent := FContenedorFiscal;
  oEstado.SetBounds(270, 300, 220, 28);
  oEstado.DataBinding.DataSource := dsTablaG;
  oEstado.DataBinding.DataField := 'ESTADO_FISCAL_FACC';
end;

procedure TfrmMtoComprasDirectasTerceros.EmitirFiscal(Sender: TObject);
begin
  if not Permisos.TienePermiso(
    'ComprasDirectasTerceros.modificar', paPermitir) then
    Abort;
  ShowMessage_fza(EnviarRegistroFiscalActual);
end;

function TfrmMtoComprasDirectasTerceros.EnviarRegistroFiscalActual: string;
begin
  if dsTablaG.DataSet.State in dsEditModes then
    dsTablaG.DataSet.Post;
  Result := ProcesarFiscalCompraDirecta(
    dmmFacturasCompra.unqryTablaG.Connection, ParametrosApp,
    dsTablaG.DataSet.FieldByName('SERIE_FACC').AsString,
    dsTablaG.DataSet.FieldByName('NUMERO_FACC').AsString,
    IdentidadSesion.Usuario, UbicacionSesion.Empresa);
  dsTablaG.DataSet.Refresh;
end;

procedure TfrmMtoComprasDirectasTerceros.CambiarTratamientoAgricola(
  Sender: TObject);
begin
  if Assigned(dmmFacturasCompra) and
     (not FActualizandoTratamiento) and
     (dmmFacturasCompra.unqryTablaG.State in dsEditModes) then
  begin
    FActualizandoTratamiento := True;
    try
      FTratamientoAgricola.PostEditValue;
      dmmFacturasCompra.ActualizarModalidadCompra;
    finally
      FActualizandoTratamiento := False;
    end;
  end;
end;

procedure TfrmMtoComprasDirectasTerceros.ImprimirReciboPago(Sender: TObject);
begin
  if not PuedeImprimir then
    Abort;
  ImprimirReciboPagoCompraVcl(Self, dmmFacturasCompra);
end;

procedure TfrmMtoComprasDirectasTerceros.AplicarEtiquetas;
begin
  inherited;
  Caption := STituloComprasDirectas;
  lblCodigoProveedor.Caption := SProveedorEmisor;
  lblCodigoEmpresa.Caption := SEmpresaDestinataria;
  tsEfectos.Caption := SRecibosPago;
  btnGenerarEfectos.Caption := SGenerarRecibos;
  btnRegistrarPago.Caption := SRegistrarPago;
end;

initialization
  RegistrarPantalla(TfrmMtoComprasDirectasTerceros);

end.
