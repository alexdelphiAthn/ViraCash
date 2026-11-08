{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaFaseCobro                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario de la fase de cobro de caja (TPV).                             }
{    Calcula totales, gestiona formas de pago, vales y tickets.                }
{******************************************************************************}
unit inMtoCajaFaseCobro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB, Math,
  // Componentes DevExpress
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer,
  cxEdit, dxSkinsCore, cxTextEdit, cxMaskEdit, cxSpinEdit, cxCurrencyEdit,
  cxLabel, cxButtons, cxGroupBox, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView,
  cxGrid, cxDropDownEdit, dxDateRanges, dxScrollbarAnnotations,
  cxCheckBox,
  // Acceso a Datos y Librerías Propias
  VirtualTable,
  inMtoFrmBase, inLibFacturas, inLibFaseCobro, inLibCajaTipos,
  inLibFaseCobroPersistenciaIntf,
  inMtoCajaReferenciaPago, System.UITypes, dxGDIPlusClasses, cxImage,
  inLibInformesCajaPersistenciaIntf, inLibCajaPantallaInyeccion,
  inLibCajaSubsanacionIntf,
  JvComponentBase, JvEnterTab, cxLocalization;

type
  TTipoImpresionTicket = inLibCajaTipos.TTipoImpresionVenta;
  TEntradaFaseCobro = record
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    Fecha: TDateTime;
    CodigoCliente: string;
    EmailCliente: string;
    NifCliente: string;
    CodigoPaisCliente: string;
    NombrePaisCliente: string;
    RectificaA: string;
    HayLineasDeposito: Boolean;
    // Ticket de origen de la devolución o rectificación (FZ-363)
    EmpresaOrigen: string;
    SerieOrigen: string;
    NumeroOrigen: string;
  end;
  TResultadoFaseCobro = record
    TipoImpresion: TTipoImpresionTicket;
    SerieDocumento: string;
    SerieFactura: string;
    FechaFactura: TDateTime;
    NumeroManual: string;
    DatosCobro: TDatosFaseCobro;
  end;
  TfrmMtoCajaFaseCobro = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlIzquierdo: TPanel;
    pnlDerecho: TPanel;
    dsFormasPago: TDataSource;
    txtTotalPagar: TcxCurrencyEdit;
    txtPendienteCobro: TcxCurrencyEdit;
    txtCantidadLineas: TcxTextEdit;
    txtBrutoLineas: TcxCurrencyEdit;
    txtPorcenDtoLineal: TcxTextEdit;
    txtTotalDtoLineal: TcxCurrencyEdit;
    txtPorcenDtoGlobal: TcxCurrencyEdit;
    txtDtoGlobal: TcxCurrencyEdit;
    lblNumDoc: TcxLabel;
    edtNumeroDoc: TcxTextEdit;
    cbbSERIE_FAC: TcxComboBox;
    pnlCuenta: TPanel;
    lblPendienteCobro: TcxLabel;
    lblImporteACuenta: TcxLabel;
    txtDejarCuenta: TcxCurrencyEdit;
    txtPendienteCuenta: TcxCurrencyEdit;
    pnlCambioVales: TPanel;
    lblValeEmitido: TcxLabel;
    lblValeRecogido: TcxLabel;
    txtValeRecogido: TcxCurrencyEdit;
    txtValeEmitido: TcxCurrencyEdit;
    txtCambio: TcxCurrencyEdit;
    cxgrdFormasPago: TcxGrid;
    dbtvFormasPago: TcxGridDBTableView;
    dbmImporte: TcxGridDBColumn;
    btnSinTicket: TcxButton;
    btnF11: TcxButton;
    btnConTicket: TcxButton;
    btnF12: TcxButton;
    btnSinPrecios: TcxButton;
    btnF10: TcxButton;
    btnDeposito: TcxButton;
    btnF7: TcxButton;
    btnFactura: TcxButton;
    btnF8: TcxButton;
    btnBuscarVale: TcxButton;
    btnF6: TcxButton;
    btnMasDatos: TcxButton;
    btnF2: TcxButton;
    btnBuscarT: TcxButton;
    btnF3: TcxButton;
    btnAtras: TcxButton;
    btnESC: TcxButton;
    alFaseCobro: TActionList;
    actSalir: TAction;
    pnlLogoLeft: TPanel;
    pnlContenedor: TPanel;
    pnlTotales: TPanel;
    lblImporteDtoLineal: TcxLabel;
    lblImporteTotalAPagar: TcxLabel;
    lblDescuento: TcxLabel;
    lblSuma: TcxLabel;
    // Edits de Importes
    cxgrdlvlFormasPago: TcxGridLevel;
    // Columnas Grid
    cxgrdbclmnCodigo: TcxGridDBColumn;
    dbmDescripcion: TcxGridDBColumn;
    // Panel Inferior (Totales finales)
    lblPendienteCobroAlt: TcxLabel;
    lblDevolucionCambio: TcxLabel;
    styRepoCobro: TcxStyleRepository;
    styCobroLine: TcxStyle;
    dbtvFormasPagoESDIVISA_FORMA_PAGO_CFP: TcxGridDBColumn;
    dbtvFormasPagoESCRIPTO_FORMA_PAGO_CFP: TcxGridDBColumn;
    dbtvFormasPagoESIMPORTE_DIVISA: TcxGridDBColumn;
    actRellenar: TAction;
    actBuscarVale: TAction;
    actSinTicket: TAction;
    actConTicket: TAction;
    actSinPrecios: TAction;
    actDepositoCliente: TAction;
    actFactura: TAction;
    cxImage1: TcxImage;
    imgEnviarEmail: TImage;
    chkEnviarEmail: TcxCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dbmImportePropertiesEditValueChanged(Sender: TObject);
    procedure dbmImportePropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
    procedure btnAtrasClick(Sender: TObject);
    procedure txtPorcenDtoGlobalPropertiesChange(Sender: TObject);
    procedure txtPorcenDtoGlobalPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
    procedure txtTotalPagarPropertiesChange(Sender: TObject);
    procedure txtTotalPagarPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption;
      var Error: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure btnESCClick(Sender: TObject);
    procedure dbmImporteGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure txtValeEmitidoPropertiesEditValueChanged(Sender: TObject);
    procedure dbtvFormasPagoEditChanged(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem);
    procedure btnBuscarTClick(Sender: TObject);
    procedure btnF3Click(Sender: TObject);
    procedure actRellenarExecute(Sender: TObject);
    procedure btnBuscarValeClick(Sender: TObject);
    procedure btnF6Click(Sender: TObject);
    procedure dbtvFormasPagoEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure actBuscarValeExecute(Sender: TObject);
    procedure btnSinTicketClick(Sender: TObject);
    procedure btnConTicketClick(Sender: TObject);
    procedure btnSinPreciosClick(Sender: TObject);
    procedure btnF7Click(Sender: TObject);
    procedure actSinTicketExecute(Sender: TObject);
    procedure actConTicketExecute(Sender: TObject);
    procedure actSinPreciosExecute(Sender: TObject);
    procedure actDepositoClienteExecute(Sender: TObject);
    procedure btnDepositoClick(Sender: TObject);
    procedure btnFacturaClick(Sender: TObject);
    procedure actFacturaExecute(Sender: TObject);
    procedure chkEnviarEmailPropertiesEditValueChanged(Sender: TObject);
  private
    FTipoImpresion: TTipoImpresionTicket;
    FDatosCobro: TDatosFaseCobro;
    FRepositorioPersistencia: IRepositorioFaseCobro;
    FRepositorioVales: IRepositorioInformesCaja;
    FMemTablePagos: TVirtualTable;
    FActualizandoVale: Boolean;
    FActualizandoDescuento: Boolean;
    FEditorDescuentoActual: TcxCurrencyEdit;
    FEmailEnvio: string;
    FActualizandoEmail: Boolean;
    FCodigoEmpresa: string;
    FCodigoCliente: string;
    FEmailCliente: string;
    FNifCliente: string;
    FCodigoPaisCliente: string;
    FNombrePaisCliente: string;
    FSerieFactura: string;
    FFechaFactura: TDateTime;
    FNumeroManual: string;
    FRectificaA: string;
    FCodigoAlmacen: string;
    FCodigoCaja: string;
    FFecha: TDate;
    FHayLineasDeposito: Boolean;
    FEmpresaOrigen: string;
    FSerieOrigen: string;
    FNumeroOrigen: string;
    FModoSubsanacion: Boolean;
    FPagosSubsanacion: TPagosSubsanacionCaja;
    FPagosFijosSubsanacion: TPagosSubsanacionCaja;
    // FZ-ISSUE-369: totales recalculados como factura completa (F8).
    FTotalesComoFactura: Boolean;
    procedure PrepararModoSubsanacion;
    function RecalcularTotalesComoTipo(
      const ATipoFactura: string): Boolean;
    function RecalcularTotalesComoTicket: Boolean;
    function ValidarCobroSubsanacion: Boolean;
    function PedirContactoApartado: Boolean;
    function ValidaryConfirmar:boolean;
    function ValidarDepositoCredito: Boolean;
    function PuedeEmitir(const ASerie: string; AFecha: TDateTime): Boolean;
    function SerieAdmiteFecha(var ASerie: string;
      AFecha: TDateTime; const ASubtipo: string): Boolean;
    procedure AvisarSiNumeracionConHuecos(const ASerie: string);
    function NumeroManualIntroducido: string;
    function ValidarHuecoManual(const ASerie, ANumero: string;
      out ANumeroFmt: string): Boolean;
    procedure CargarFormasPago;
    procedure AplicarValesOrigenSiProcede;
    procedure CargarComboSeries;
    procedure AjustarFormatoEditorActivo;
    procedure ActualizarInterfaz;
    procedure ActualizarImportesDescuento;
    function PuedeAplicarDescuentoGlobal: Boolean;
    function ConfirmarEditoresDescuento: Boolean;
    procedure ConfigurarTablaVirtual;
    procedure ConfigurarModoDevolucion;
    procedure ConfigurarModoCobroNormal;
    procedure RellenarPendienteEnFormaActual;
    procedure EscribirImporteEnFormaActual(AImporte: Double);
    procedure AnularImporteEnFormaActual;
    procedure MemTablePagosAfterPost(DataSet: TDataSet);
    procedure FMemTablePagosBeforePost(DataSet: TDataSet);
    procedure AplicarEstiloCaja;
    procedure DibujarIconoEmail;
    function GetEnviarEmail: Boolean;
  public
    constructor Create(
      AOwner: TComponent;
      const ADependencias: TDependenciasFaseCobro); reintroduce;
      overload;
    property DatosCobro: TDatosFaseCobro read FDatosCobro;
    property TipoImpresion: TTipoImpresionTicket read FTipoImpresion;
    property EnviarEmail: Boolean read GetEnviarEmail;
    property EmailEnvio: string read FEmailEnvio;
    procedure Configurar(const AEntrada: TEntradaFaseCobro);
    // Subsanación: sólo forma de pago y descuento global, con los cobros
    // vigentes precargados y sin emitir documento. Los vales y la deuda se
    // conservan; con líneas fijas (depósitos) no hay descuento global.
    procedure ConfigurarSubsanacion(const APagos: TPagosSubsanacionCaja;
      AHayLineasFijas: Boolean);
    function PagosSubsanacion: TPagosSubsanacionCaja;
    function ObtenerResultado: TResultadoFaseCobro;
    // FZ-ISSUE-369: si se cancela tras F8, la venta vuelve a calcularse
    // como ticket.
    procedure DeshacerTotalesFactura;
    procedure CargarDatosDesdeFactura(TotalesFactura: TFacturaTotales);
    procedure AlRecalcularDatos(Sender: TObject);
    function AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                  ADatosActuales: TDatosReferencia): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibTipoCantidad, inLibMensajesVcl, inLibRedondeo,
  UniDataFaseCobroRepositorio,
  inMtoCajaSeleccionVale, inMtoModalOpcionesDocumento,
  inLibOpcionesDocumentoIntf, inLibMsgOpcionesDocumento,
  UniDataOpcionesDocumentoRepositorio, Uni,
     UniDataCaja, inLibDocumentoFiscal, inLibCorreoTickets, inLibMsgCaja,
  inLibCajaEstiloVcl, inLibMsgSubsanacionCaja, inLibMsgTickets,
  inLibAvisoHuecosNumeracion, System.StrUtils;

// FormatFloat admite tres secciones: positivo, negativo y cero. Poniendo en
// la del cero un literal vacío ('' entre comillas simples) el importe a cero
// se ve en blanco, en vez de un 0,00 que hay que borrar antes de teclear.
function ConCeroEnBlanco(const AFormato: string): string;
begin
  Result := AFormato + ';-' + AFormato + ';' + #39#39;
end;

constructor TfrmMtoCajaFaseCobro.Create(
  AOwner: TComponent;
  const ADependencias: TDependenciasFaseCobro);
begin
  ADependencias.Validar;
  FRepositorioPersistencia := ADependencias.Persistencia;
  FRepositorioVales := ADependencias.Vales;
  inherited Create(AOwner);
end;

procedure TfrmMtoCajaFaseCobro.Configurar(
  const AEntrada: TEntradaFaseCobro);
begin
  FCodigoEmpresa := AEntrada.CodigoEmpresa;
  FCodigoAlmacen := AEntrada.CodigoAlmacen;
  FCodigoCaja := AEntrada.CodigoCaja;
  FDatosCobro.RestriccionVales := TRestriccionCanjeVale.Crear(
    ParametrosCaja.GetString('vgerAmbitoCanjeVale', 'TODOS'),
    FCodigoEmpresa, FCodigoAlmacen, FCodigoCaja);
  FFecha := AEntrada.Fecha;
  FCodigoCliente := AEntrada.CodigoCliente;
  FEmailCliente := AEntrada.EmailCliente;
  FNifCliente := AEntrada.NifCliente;
  FCodigoPaisCliente := AEntrada.CodigoPaisCliente;
  FNombrePaisCliente := AEntrada.NombrePaisCliente;
  FRectificaA := AEntrada.RectificaA;
  FHayLineasDeposito := AEntrada.HayLineasDeposito;
  FEmpresaOrigen := AEntrada.EmpresaOrigen;
  FSerieOrigen := AEntrada.SerieOrigen;
  FNumeroOrigen := AEntrada.NumeroOrigen;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarSubsanacion(
  const APagos: TPagosSubsanacionCaja; AHayLineasFijas: Boolean);
var
  oPago: TPagoSubsanacionCaja;
begin
  FModoSubsanacion := True;
  FPagosSubsanacion := nil;
  FPagosFijosSubsanacion := nil;
  for oPago in APagos do
    if MatchText(Trim(oPago.FormaPago), ['VALE', 'DEUDA']) then
      FPagosFijosSubsanacion := FPagosFijosSubsanacion + [oPago]
    else
      FPagosSubsanacion := FPagosSubsanacion + [oPago];
  FHayLineasDeposito := FHayLineasDeposito or AHayLineasFijas;
end;

procedure TfrmMtoCajaFaseCobro.PrepararModoSubsanacion;
var
  oControl: TControl;
  oPago: TPagoSubsanacionCaja;
  sCodigo: string;
  dRestante, dImporte, dVales: Currency;
  i: Integer;
begin
  Caption := SSubsanacionTituloCobro;
  for oControl in TArray<TControl>.Create(btnSinPrecios,
    btnDeposito, btnFactura, btnBuscarVale, btnMasDatos, chkEnviarEmail,
    imgEnviarEmail, cbbSERIE_FAC, edtNumeroDoc, lblNumDoc, pnlCuenta) do
    oControl.Visible := False;
  btnConTicket.Caption := SSubsanacionBoton;
  // F11 también subsana: graba la corrección sin reimprimir el ticket.
  btnSinTicket.Caption := SSubsanacionBotonSinTicket;
  FMemTablePagos.DisableControls;
  try
    // Cualquier forma de pago (divisas, criptomonedas y bonos incluidos)
    // salvo vales y deuda: los del ticket se conservan y no se añaden.
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      sCodigo := FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString;
      if MatchText(sCodigo, ['VALE', 'DEUDA']) then
        FMemTablePagos.Delete
      else
        FMemTablePagos.Next;
    end;
    dVales := 0;
    for oPago in FPagosFijosSubsanacion do
      dVales := dVales + oPago.Importe;
    FDatosCobro.EstablecerValesFijos(dVales);
    // Los cobros vigentes se precargan hasta el total corregido: si bajó,
    // se recortan en orden; si subió, la diferencia va al último.
    dRestante := FDatosCobro.ImporteTotalPagar - dVales;
    for i := 0 to High(FPagosSubsanacion) do
    begin
      oPago := FPagosSubsanacion[i];
      dImporte := Min(oPago.Importe, dRestante);
      if i = High(FPagosSubsanacion) then
        dImporte := dRestante;
      if (dImporte > 0) and FMemTablePagos.Locate('CODIGO_FP_CFP',
        oPago.FormaPago, [loCaseInsensitive]) then
      begin
        dRestante := dRestante - dImporte;
        FMemTablePagos.Edit;
        FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat :=
          FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat +
          dImporte;
        if Trim(oPago.Referencia) <> '' then
          FMemTablePagos.FieldByName('REFERENCIA').AsString :=
            oPago.Referencia;
        // Divisa o cripto: se conserva la moneda y el importe entregado en
        // ella, en proporción si el cobro en euros se ha recortado.
        if Trim(oPago.CodigoDivisa) <> '' then
          FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString :=
            oPago.CodigoDivisa;
        FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString :=
          oPago.RedBlockchain;
        if oPago.FactorCambio > 0 then
          FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat :=
            oPago.FactorCambio;
        if (oPago.ImporteDivisa <> 0) and (oPago.Importe <> 0) then
        begin
          FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat :=
            FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat +
            oPago.ImporteDivisa * (dImporte / oPago.Importe);
          FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
        end;
        FMemTablePagos.Post;
      end;
    end;
    FMemTablePagos.First;
  finally
    FMemTablePagos.EnableControls;
  end;
end;

function TfrmMtoCajaFaseCobro.PedirContactoApartado: Boolean;
var
  oValores: array of string;
  oContacto: TContactoApartado;
begin
  // El cliente de Varios no identifica a nadie: el apartado guarda quién
  // se lleva las prendas para localizarle y para la copia de la prenda.
  SetLength(oValores, 2);
  oValores[0] := FDatosCobro.ContactoApartado.Nombre;
  oValores[1] := FDatosCobro.ContactoApartado.Telefono;
  Result := InputQuery_fza(
    STituloApartadoCaja,
    [SNombreContactoApartadoCaja, STelefonoContactoApartadoCaja],
    oValores,
    function(const AValores: array of string): Boolean
    begin
      Result := Trim(AValores[0]) <> '';
      if not Result then
        ShowMessage_fza(SErrorNombreContactoApartadoCaja);
    end);
  if Result then
  begin
    oContacto.Nombre := oValores[0];
    oContacto.Telefono := oValores[1];
    FDatosCobro.EstablecerContactoApartado(oContacto);
  end;
end;

function TfrmMtoCajaFaseCobro.ValidarCobroSubsanacion: Boolean;
begin
  // Los vales del ticket ya están en ImporteValeRecogido; no se admiten
  // vales nuevos (ni el que se emitiría por exceso) ni dejar a cuenta.
  Result := (Abs(FDatosCobro.ImportePendiente) < 0.01) and
    (Abs(FDatosCobro.ImporteCambio) < 0.01) and
    (FDatosCobro.ImporteValeEmitido = 0) and
    (FDatosCobro.ImporteDejarCuenta = 0) and
    (FDatosCobro.ValesRecogidos.Count = 0);
  if not Result then
    MessageDlg_fza(SSubsanacionCobroExacto, mtError, [mbOK], 0);
end;

function TfrmMtoCajaFaseCobro.PagosSubsanacion: TPagosSubsanacionCaja;
var
  oPago: TPagoSubsanacionCaja;
begin
  // Vales y deuda del ticket, tal cual, y los cobros de la rejilla.
  Result := Copy(FPagosFijosSubsanacion);
  FMemTablePagos.DisableControls;
  try
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      oPago := Default(TPagoSubsanacionCaja);
      oPago.FormaPago :=
        FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString;
      oPago.Referencia := Trim(
        FMemTablePagos.FieldByName('REFERENCIA').AsString);
      oPago.Importe := RedondearDecimales(
        FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat -
        FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency, 2);
      oPago.CodigoDivisa :=
        FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
      oPago.RedBlockchain :=
        FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString;
      oPago.FactorCambio :=
        FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat;
      oPago.ImporteDivisa :=
        FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat;
      if oPago.Importe <> 0 then
        Result := Result + [oPago];
      FMemTablePagos.Next;
    end;
  finally
    FMemTablePagos.EnableControls;
  end;
end;

function TfrmMtoCajaFaseCobro.ObtenerResultado:
  TResultadoFaseCobro;
begin
  Result := Default(TResultadoFaseCobro);
  Result.TipoImpresion := FTipoImpresion;
  Result.SerieDocumento := Trim(cbbSERIE_FAC.Text);
  Result.SerieFactura := FSerieFactura;
  Result.FechaFactura := FFechaFactura;
  Result.NumeroManual := FNumeroManual;
  Result.DatosCobro := FDatosCobro;
end;

procedure TfrmMtoCajaFaseCobro.CargarComboSeries;
var
  Solicitud: TSolicitudSeriesFaseCobro;
  Series: TSeriesFaseCobro;
  sSerie: string;
begin
  Solicitud.CodigoEmpresa := FCodigoEmpresa;
  Solicitud.CodigoAlmacen := FCodigoAlmacen;
  Solicitud.CodigoCaja := FCodigoCaja;
  Solicitud.Fecha := FFecha;
  if FRectificaA <> '' then
  begin
    Solicitud.Subtipo := 'RECTIFICATIVA';
  end
  else
  begin
    Solicitud.Subtipo := 'SIMPLIFICADA';
  end;
  Series := FRepositorioPersistencia.ListarSeries(Solicitud);
  cbbSERIE_FAC.Properties.Items.BeginUpdate;
  try
    cbbSERIE_FAC.Properties.Items.Clear;
    cbbSERIE_FAC.ItemIndex := -1;
    cbbSERIE_FAC.Text := '';
    for sSerie in Series do
    begin
      cbbSERIE_FAC.Properties.Items.Add(sSerie);
    end;
  finally
    cbbSERIE_FAC.Properties.Items.EndUpdate;
  end;
  if (cbbSERIE_FAC.Properties.Items.Count > 0) and
     (cbbSERIE_FAC.ItemIndex = -1) then
  begin
    cbbSERIE_FAC.ItemIndex := 0;
  end;
end;
procedure TfrmMtoCajaFaseCobro.btnConTicketClick(Sender: TObject);
begin
  if FModoSubsanacion then
  begin
    if ValidarYConfirmar and ValidarCobroSubsanacion then
    begin
      FTipoImpresion := tiConTicket;
      ModalResult := mrOk;
    end;
  end
  else if ValidarYConfirmar and RecalcularTotalesComoTicket and
          PuedeEmitir(cbbSERIE_FAC.Text, FFecha) then
  begin
    FTipoImpresion := tiConTicket;
    ModalResult := mrOk;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnDepositoClick(Sender: TObject);
begin
  inherited;
  btnF7Click(Sender);
end;

const
  TIPO_FACTURA_COMPLETA_CAJA = 'NORMAL';
  TIPO_FACTURA_TICKET_CAJA = 'SIMPLIFICADA';

// Dialogo comun: serie de factura completa (por defecto la del almacen de
// la caja) y fecha. El numero sale del contador y la forma de pago son
// los cobros de esta pantalla.
function SolicitarSerieFechaFacturaCaja(AOwner: TComponent;
  AConexion: TUniConnection; const AEmpresa, AAlmacen: string;
  out AOpciones: TOpcionesDocumento): Boolean;
var
  oConfig: TConfiguracionOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
begin
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := 'FC';
  oTipo.Nombre := SNombreFacturaVentaOpcionesDocumento;
  oConfig := Default(TConfiguracionOpcionesDocumento);
  oConfig.Titulo := STituloFacturaCajaOpcionesDocumento;
  oConfig.Tipos := [oTipo];
  oConfig.Propuesta.Empresa := AEmpresa;
  oConfig.Propuesta.Almacen := AAlmacen;
  oConfig.Propuesta.Tipo := 'FC';
  oConfig.Propuesta.Fecha := Date;
  oConfig.Visibles := [codEmpresa, codSerie, codFecha];
  oConfig.Fijos := [codEmpresa];
  Result := TfrmModalOpcionesDocumento.Solicitar(AOwner,
    CrearLectorOpcionesDocumentoUniDAC(AConexion), oConfig, AOpciones);
end;

procedure TfrmMtoCajaFaseCobro.btnFacturaClick(Sender: TObject);
var
  oDatos: TOpcionesDocumento;
begin
  //F8 -> grabar la venta como factura completa (A4), no como ticket
  if FModoSubsanacion then
    Exit;
  if FRectificaA <> '' then
    ShowMessage_fza(SErrorRectificacionCajaNoAdmiteBorrador)
  else if (Trim(FCodigoCliente) = '') or (Trim(FCodigoCliente) = '0') then
    ShowMessage_fza(SErrorClienteBorradorCajaNoAsignado)
  else if Trim(FNifCliente) = '' then
    ShowMessage_fza(SErrorNifClienteBorradorCajaNoIndicado)
  else if PaisEsEspana(FCodigoPaisCliente, FNombrePaisCliente) and
          (not DocumentoFiscalValido(FNifCliente)) then
    ShowMessage_fza(SErrorDocumentoFiscalClienteCajaNoValido +
                MensajeDocumentoFiscalInvalido(FNifCliente))
  else if ValidarYConfirmar and
          RecalcularTotalesComoTipo(TIPO_FACTURA_COMPLETA_CAJA) then
  begin
    // Serie de factura completa (por defecto la del almacén) y fecha
    if SolicitarSerieFechaFacturaCaja(Self, ConexionPrincipal,
         FCodigoEmpresa, FCodigoAlmacen, oDatos) then
    begin
      if SerieAdmiteFecha(oDatos.Serie, oDatos.Fecha, 'NORMAL') then
      begin
        AvisarSiNumeracionConHuecos(oDatos.Serie);
        FNumeroManual  := '';
        FSerieFactura  := oDatos.Serie;
        FFechaFactura  := oDatos.Fecha;
        FTipoImpresion := tiFactura;
        ModalResult    := mrOk;
      end;
    end;
  end;
end;

// FZ-ISSUE-369: TFacturaTotales no aplica recargo ni retención a la
// factura SIMPLIFICADA, y la caja calcula como ticket. Al elegir factura
// completa se recalcula como NORMAL y, al volver a un ticket, como
// SIMPLIFICADA. Si cambia el total, la pantalla sigue abierta para
// ajustar el cobro (el usuario vuelve a pulsar el botón).
function TfrmMtoCajaFaseCobro.RecalcularTotalesComoTipo(
  const ATipoFactura: string): Boolean;
var
  oTotales: TFacturaTotales;
  cAnterior: Currency;
begin
  Result := True;
  oTotales := FDatosCobro.TotalesFactura;
  if (oTotales <> nil) and
     not SameText(oTotales.Cabecera.FieldByName('TIPO_FAC').AsString,
       ATipoFactura) then
  begin
    cAnterior := FDatosCobro.ImporteTotalPagar;
    oTotales.Cabecera.Edit;
    oTotales.Cabecera.FieldByName('TIPO_FAC').AsString := ATipoFactura;
    oTotales.Cabecera.Post;
    oTotales.ProcesarFacturaCompleta;
    FDatosCobro.CargarDatosFactura(oTotales);
    FTotalesComoFactura :=
      SameText(ATipoFactura, TIPO_FACTURA_COMPLETA_CAJA);
    Result := FDatosCobro.ImporteTotalPagar = cAnterior;
    if not Result then
      ShowMessage_fza(Format(SAvisoTotalCobroCambiaTipoFactura,
        [FormatCurr(',0.00 €', cAnterior),
         FormatCurr(',0.00 €', FDatosCobro.ImporteTotalPagar)]));
  end;
end;

function TfrmMtoCajaFaseCobro.RecalcularTotalesComoTicket: Boolean;
begin
  Result := not FTotalesComoFactura or
    RecalcularTotalesComoTipo(TIPO_FACTURA_TICKET_CAJA);
end;

procedure TfrmMtoCajaFaseCobro.DeshacerTotalesFactura;
var
  oTotales: TFacturaTotales;
begin
  oTotales := FDatosCobro.TotalesFactura;
  if FTotalesComoFactura and (oTotales <> nil) then
  begin
    oTotales.Cabecera.Edit;
    oTotales.Cabecera.FieldByName('TIPO_FAC').AsString :=
      TIPO_FACTURA_TICKET_CAJA;
    oTotales.Cabecera.Post;
    oTotales.ProcesarFacturaCompleta;
    FTotalesComoFactura := False;
  end;
end;

procedure TfrmMtoCajaFaseCobro.actFacturaExecute(Sender: TObject);
begin
  //F8 -> Factura completa
  btnFacturaClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnSinTicketClick(Sender: TObject);
begin
  if FModoSubsanacion then
  begin
    if ValidarYConfirmar and ValidarCobroSubsanacion then
    begin
      FTipoImpresion := tiSinTicket;
      ModalResult := mrOk;
    end;
  end
  else if ValidarYConfirmar and RecalcularTotalesComoTicket and
          PuedeEmitir(cbbSERIE_FAC.Text, FFecha) then
  begin
    FTipoImpresion := tiSinTicket;
    ModalResult := mrOk;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnSinPreciosClick(Sender: TObject);
begin
  if not FModoSubsanacion and ValidarYConfirmar and
     RecalcularTotalesComoTicket and
     PuedeEmitir(cbbSERIE_FAC.Text, FFecha) then
  begin
    FTipoImpresion := tiTicketRegalo;
    ModalResult := mrOk;
  end;
end;

function TfrmMtoCajaFaseCobro.ValidarDepositoCredito: Boolean;
var
  Mensaje: string;
begin
  Result := ValidarAlmacenDepositoCredito(
    ConexionPrincipal, FCodigoEmpresa, Mensaje);
  if not Result then
    ShowMessage_fza(Mensaje);
end;

function TfrmMtoCajaFaseCobro.ValidarYConfirmar: Boolean;
var
  Res: TResultadoValidacion;
begin
  Result := ConfirmarEditoresDescuento;
  if Result then
  begin
    if dbtvFormasPago.Controller.EditingController.IsEditing then
      dbtvFormasPago.Controller.EditingController.HideEdit(True);
    if FMemTablePagos.State in [dsEdit, dsInsert] then
      FMemTablePagos.Post;
    FDatosCobro.Recalcular;
    Res := FDatosCobro.ValidarParaCobro;
    Result := Res.Valido;
    if not Result then
      MessageDlg_fza(Res.Mensaje, mtError, [mbOK], 0);
    if Result and (FDatosCobro.ImporteDejarCuenta > 0) then
      Result := ValidarDepositoCredito;
  end;
end;

function TfrmMtoCajaFaseCobro.ConfirmarEditoresDescuento: Boolean;
begin
  Result := True;
  if txtTotalPagar.ModifiedAfterEnter then
    Result := txtTotalPagar.ValidateEdit;
  if Result and txtPorcenDtoGlobal.ModifiedAfterEnter then
    Result := txtPorcenDtoGlobal.ValidateEdit;
  if Result then
  begin
    txtTotalPagar.PostEditValue;
    txtPorcenDtoGlobal.PostEditValue;
  end;
end;

function TfrmMtoCajaFaseCobro.SerieAdmiteFecha(var ASerie: string;
  AFecha: TDateTime; const ASubtipo: string): Boolean;
var
  dUltima: TDateTime;
  oConfig: TConfiguracionOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
  oElegido: TOpcionesDocumento;
  sAviso: string;
begin
  Result := True;
  dUltima := TdmCajaOpe.FechaUltimoTicketSerie(
    ConexionPrincipal,
    FCodigoEmpresa,
    ASerie);
  if (dUltima > 0) and (Trunc(AFecha) < Trunc(dUltima)) then
  begin
    Result := False;
    sAviso := Format(SErrorFechaSerieEmisionCajaNoValida,
      [ASerie, FormatDateTime('dd/mm/yyyy', dUltima),
       FormatDateTime('dd/mm/yyyy', AFecha)]);
    if MessageDlg_fza(sAviso + sLineBreak + sLineBreak +
         SPreguntaCambiarSerieFechaVenta, mtWarning,
         [mbYes, mbNo], 0, mbNo) = mrYes then
    begin
      oTipo := Default(TTipoOpcionesDocumento);
      oTipo.Codigo := 'FC';
      oTipo.Subtipo := ASubtipo;
      oConfig := Default(TConfiguracionOpcionesDocumento);
      oConfig.Titulo := STituloCambiarSerieFechaVenta;
      oConfig.Aviso := sAviso;
      oConfig.Tipos := [oTipo];
      oConfig.Propuesta.Empresa := FCodigoEmpresa;
      oConfig.Propuesta.Almacen := FCodigoAlmacen;
      oConfig.Propuesta.Tipo := 'FC';
      oConfig.Propuesta.Serie := ASerie;
      oConfig.Propuesta.Fecha := Trunc(AFecha);
      oConfig.Visibles := [codEmpresa, codSerie, codFecha];
      oConfig.Fijos := [codEmpresa, codFecha];
      oConfig.Validar :=
        function(const AOpciones: TOpcionesDocumento;
          out AMensaje: string): Boolean
        var
          dUltimaElegida: TDateTime;
        begin
          dUltimaElegida := TdmCajaOpe.FechaUltimoTicketSerie(
            ConexionPrincipal, FCodigoEmpresa, AOpciones.Serie);
          Result := (dUltimaElegida = 0) or
            (Trunc(AFecha) >= Trunc(dUltimaElegida));
          if not Result then
            AMensaje := Format(SErrorFechaSerieEmisionCajaNoValida,
              [AOpciones.Serie, FormatDateTime('dd/mm/yyyy', dUltimaElegida),
               FormatDateTime('dd/mm/yyyy', AFecha)]);
        end;
      Result := TfrmModalOpcionesDocumento.Solicitar(Self,
        CrearLectorOpcionesDocumentoUniDAC(ConexionPrincipal),
        oConfig, oElegido);
      if Result then
        ASerie := oElegido.Serie;
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.AvisarSiNumeracionConHuecos(
  const ASerie: string);
var
  Resumen: TResumenNumeracionFaseCobro;
  iHuecos: Int64;
begin
  if (Trim(ASerie) <> '') and
     ParametrosCaja.GetBool('vgerAvisoHuecosNumeracion', True) then
  begin
    Resumen := FRepositorioPersistencia.ObtenerResumenNumeracion(
      FCodigoEmpresa,
      ASerie,
      0);
    iHuecos := HuecosNumeracion(
      Resumen.Filas, Resumen.Minimo, Resumen.Maximo);
    // FZ-ISSUE-394: una vez por sesión y serie; se repite solo si
    // aparecen huecos nuevos (los migrados no saltan en cada venta).
    if RegistroAvisosHuecosNumeracion.DebeAvisar(
         FCodigoEmpresa, ASerie, iHuecos) then
    begin
      MessageDlg_fza(
        Format(
          SAvisoHuecosNumeracionSerieCaja,
          [
            ASerie,
            iHuecos,
            Resumen.Minimo,
            Resumen.Maximo
          ]),
        mtWarning,
        [mbOK],
        0);
    end;
  end;
end;
function TfrmMtoCajaFaseCobro.NumeroManualIntroducido: string;
var
  s: string;
begin
  // Vacio o todo ceros (placeholder '00000000') => numeracion automatica.
  s := Trim(edtNumeroDoc.Text);
  if StrToInt64Def(s, 0) = 0 then
    Result := ''
  else
    Result := s;
end;

function TfrmMtoCajaFaseCobro.ValidarHuecoManual(
  const ASerie, ANumero: string;
  out ANumeroFmt: string
): Boolean;
var
  Resumen: TResumenNumeracionFaseCobro;
  iNumero: Int64;
begin
  Result := False;
  ANumeroFmt := '';
  iNumero := StrToInt64Def(Trim(ANumero), 0);
  if iNumero <= 0 then
  begin
    MessageDlg_fza(
      SErrorNumeroBorradorCajaNoValido,
      mtError,
      [mbOK],
      0);
  end
  else
  begin
    Resumen := FRepositorioPersistencia.ObtenerResumenNumeracion(
      FCodigoEmpresa,
      ASerie,
      iNumero);
    if Resumen.ExistentesNumero > 0 then
    begin
      MessageDlg_fza(
        Format(
          SErrorNumeroBorradorCajaExistente,
          [iNumero, ASerie]),
        mtError,
        [mbOK],
        0);
    end
    else if (Resumen.Maximo <= Resumen.Minimo) or
            (iNumero <= Resumen.Minimo) or
            (iNumero >= Resumen.Maximo) then
    begin
      MessageDlg_fza(
        Format(
          SErrorNumeroBorradorCajaNoEsHueco,
          [iNumero, ASerie, Resumen.Minimo, Resumen.Maximo]),
        mtError,
        [mbOK],
        0);
    end
    else
    begin
      ANumeroFmt := IntToStr(iNumero);
      while Length(ANumeroFmt) < Resumen.Longitud do
      begin
        ANumeroFmt := '0' + ANumeroFmt;
      end;
      Result := True;
    end;
  end;
end;
function TfrmMtoCajaFaseCobro.PuedeEmitir(const ASerie: string;
  AFecha: TDateTime): Boolean;
var
  sManual, sNumeroFmt, sSerie, sSubtipo: string;
begin
  sSerie := Trim(ASerie);
  Result := sSerie <> '';
  // FZ-ISSUE-200: sin series de rectificativas, explicar donde se
  // configuran en lugar del aviso generico.
  if (not Result) and (FRectificaA <> '') and
     (cbbSERIE_FAC.Properties.Items.Count = 0) then
    ShowMessage_fza(SAvisoSinSerieRectificativaCaja)
  else if not Result then
    ShowMessage_fza('No hay una serie de factura disponible para esta ' +
      'empresa, almacén y caja. Configúrela en Archivo > Empresas > ' +
      'Series (factura simplificada o rectificativa, según la venta).');
  if Result and (Length(sSerie) > 12) then
  begin
    Result := False;
    ShowMessage_fza('La serie no puede superar los 12 caracteres.');
  end;
  if not Result and cbbSERIE_FAC.CanFocus then
    cbbSERIE_FAC.SetFocus;
  if Result then
  begin
    // Decide entre relleno de hueco (numero manual escrito en 'Nº doc. venta')
    // y emision normal con numeracion automatica.
    sManual := NumeroManualIntroducido;
    if sManual <> '' then
    begin
      // Relleno de hueco: validar el numero; no aplica el control de fecha,
      // el documento del hueco lleva su propia fecha (normalmente anterior).
      Result := ValidarHuecoManual(sSerie, sManual, sNumeroFmt);
      if Result then
        FNumeroManual := sNumeroFmt;
    end
    else
    begin
      // Emision normal: control de fecha y aviso (no bloqueante) de huecos.
      FNumeroManual := '';
      sSubtipo := 'SIMPLIFICADA';
      if FRectificaA <> '' then
        sSubtipo := 'RECTIFICATIVA';
      Result := SerieAdmiteFecha(sSerie, AFecha, sSubtipo);
      if Result then
      begin
        cbbSERIE_FAC.Text := sSerie;
        AvisarSiNumeracionConHuecos(sSerie);
      end;
    end;
  end;
end;

function TfrmMtoCajaFaseCobro.AlRequerirReferencia(AInfo: TFormaPagoInfo;
                                     ADatosActuales: TDatosReferencia): Boolean;
var
  DatosRef: TDatosReferencia;
begin
  DatosRef := ADatosActuales;
  Result := TfrmCajaReferenciaPago.Ejecutar(AInfo,
                                            txtPendienteCobro.value,
                                            DatosRef);
end;

procedure TfrmMtoCajaFaseCobro.FormCreate(Sender: TObject);
var
  Dependencias: TDependenciasFaseCobro;
begin
  inherited;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.Vales := FRepositorioVales;
  Dependencias.Validar;
  FActualizandoEmail := False;
  FEmailEnvio := '';
  chkEnviarEmail.Checked := False;
  AplicarEstiloCaja;
  DibujarIconoEmail;
  ConfigurarTablaVirtual;
  FDatosCobro := TDatosFaseCobro.Create(
    FRepositorioPersistencia,
    FMemTablePagos);
  FDatosCobro.OnRecalculado := AlRecalcularDatos;
  FDatosCobro.OnRequiereReferencia := AlRequerirReferencia;
//  CargarFormasPago;
  dsFormasPago.DataSet := FMemTablePagos;
  FMemTablePagos.AfterPost := MemTablePagosAfterPost;
  FMemTablePagos.BeforePost := FMemTablePagosBeforePost;
end;

// Mismo aspecto que el menú y la operación de caja. Cada acción tenía dos
// botones (tecla y texto) que hacen lo mismo: queda el de texto como tarjeta
// con la tecla en una píldora y se oculta el de la tecla.
procedure TfrmMtoCajaFaseCobro.AplicarEstiloCaja;
const
  PASO_BOTON = 50;
  ALTO_BOTON = 44;
var
  Estilo: TEstiloCaja;
  Etiqueta: TcxLabel;
  Botones: TArray<TcxButton>;
  Teclas: TArray<TcxButton>;
  I: Integer;
begin
  AdaptarLogotipoCaja(cxImage1);
  Estilo := TEstiloCaja.Create(Self);
  QuitarBiselesCaja([pnlLogoLeft, pnlContenedor]);
  ConvertirPanelEnTarjetaCaja(pnlTotales, EscalarCaja(Self, 4));
  ConvertirPanelEnTarjetaCaja(pnlCuenta, EscalarCaja(Self, 4));
  ConvertirPanelEnTarjetaCaja(pnlCambioVales, EscalarCaja(Self, 4));
  for Etiqueta in TArray<TcxLabel>.Create(lblSuma, lblImporteDtoLineal,
    lblDescuento, lblImporteTotalAPagar, lblImporteACuenta,
    lblPendienteCobro, lblValeRecogido, lblValeEmitido, lblDevolucionCambio,
    lblPendienteCobroAlt, lblNumDoc) do
    EstilarEtiquetaCaja(Etiqueta, 20, True);
  // Serie, número y envío por correo en negrita, como los importes.
  chkEnviarEmail.Style.Font.Name := FUENTE_CAJA;
  chkEnviarEmail.Style.Font.Style := [fsBold];
  chkEnviarEmail.Style.Font.Pitch := fpDefault;
  chkEnviarEmail.Style.TextColor := TColoresCaja.Actuales.Texto;
  cbbSERIE_FAC.Style.Font.Style := [fsBold];
  cbbSERIE_FAC.Style.Font.Pitch := fpDefault;
  edtNumeroDoc.Style.Font.Style := [fsBold];
  edtNumeroDoc.Style.Font.Pitch := fpDefault;
  Estilo.EstilarRejilla(dbtvFormasPago);
  for I := 0 to dbtvFormasPago.ColumnCount - 1 do
    dbtvFormasPago.Columns[I].Styles.Header := nil;

  Botones := TArray<TcxButton>.Create(btnSinTicket, btnConTicket,
    btnSinPrecios, btnDeposito, btnFactura, btnBuscarVale, btnMasDatos,
    btnBuscarT, btnAtras);
  Teclas := TArray<TcxButton>.Create(btnF11, btnF12, btnF10, btnF7, btnF8,
    btnF6, btnF2, btnF3, btnESC);
  for I := 0 to High(Botones) do
  begin
    Teclas[I].Visible := False;
    Botones[I].SetBounds(EscalarCaja(Self, 10),
      EscalarCaja(Self, 8 + I * PASO_BOTON),
      Botones[I].Parent.ClientWidth - EscalarCaja(Self, 20),
      EscalarCaja(Self, ALTO_BOTON));
    Estilo.EstilarBoton(Botones[I], Teclas[I].Caption, nil, 20);
  end;
end;

procedure TfrmMtoCajaFaseCobro.DibujarIconoEmail;
var
  Lienzo: TCanvas;
begin
  imgEnviarEmail.Picture.Bitmap.SetSize(24, 18);
  imgEnviarEmail.Picture.Bitmap.PixelFormat := pf32bit;
  imgEnviarEmail.Picture.Bitmap.TransparentColor := clFuchsia;
  imgEnviarEmail.Picture.Bitmap.Transparent := True;
  Lienzo := imgEnviarEmail.Picture.Bitmap.Canvas;
  Lienzo.Brush.Color := clFuchsia;
  Lienzo.FillRect(Rect(0, 0, 24, 18));
  Lienzo.Brush.Style := bsClear;
  Lienzo.Pen.Color := TColoresCaja.Actuales.Texto;
  Lienzo.Pen.Width := 2;
  Lienzo.Rectangle(1, 2, 23, 17);
  Lienzo.MoveTo(2, 3);
  Lienzo.LineTo(12, 11);
  Lienzo.LineTo(22, 3);
  Lienzo.MoveTo(2, 16);
  Lienzo.LineTo(9, 9);
  Lienzo.MoveTo(22, 16);
  Lienzo.LineTo(15, 9);
end;

function TfrmMtoCajaFaseCobro.GetEnviarEmail: Boolean;
begin
  Result := chkEnviarEmail.Checked and (Trim(FEmailEnvio) <> '');
end;

procedure TfrmMtoCajaFaseCobro.chkEnviarEmailPropertiesEditValueChanged(
  Sender: TObject);
var
  sMensaje: string;
  bContinuar: Boolean;
begin
  if not FActualizandoEmail then
  begin
    if chkEnviarEmail.Checked then
    begin
      bContinuar := CorreoTicketsConfigurado(ParametrosApp, sMensaje);
      if not bContinuar then
        ShowMessage_fza(sMensaje)
      else
      begin
        FEmailEnvio := Trim(FEmailEnvio);
        if FEmailEnvio = '' then
          bContinuar := InputQuery_fza(STituloEnviarDocumentacionCaja,
            SSolicitudCorreoDocumentacionCaja, FEmailEnvio);
        if bContinuar and (Trim(FEmailEnvio) = '') then
        begin
          ShowMessage_fza(SErrorCorreoDocumentacionCajaNoIndicado);
          bContinuar := False;
        end;
      end;
      if not bContinuar then
      begin
        FActualizandoEmail := True;
        try
          chkEnviarEmail.Checked := False;
        finally
          FActualizandoEmail := False;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.FMemTablePagosBeforePost(DataSet: TDataSet);
var
  Importe: Currency;
  EsDivisa, EsCripto: Boolean;
begin
  if not ((DataSet.State = dsEdit) and
     (DataSet.FieldByName('CODIGO_FP_CFP').AsString = 'VALE')) then
  begin
    Importe := DataSet.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
    EsDivisa :=
      DataSet.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S';
    EsCripto :=
      DataSet.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S';
    if Abs(Importe) < 0.01 then
    begin
      DataSet.FieldByName('REFERENCIA').AsString := '';
      DataSet.FieldByName('RED_BLOCKCHAIN').AsString := '';
//    DataSet.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
      DataSet.FieldByName('FACTOR_CAMBIO').AsFloat := 1;
      DataSet.FieldByName('IMPORTE_DIVISA').AsFloat := 0;
      DataSet.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
      if EsDivisa or EsCripto then
        DataSet.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.MemTablePagosAfterPost(DataSet: TDataSet);
begin
  if Assigned(FDatosCobro) then
    FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.FormDestroy(Sender: TObject);
begin
  inherited;
  if Assigned(FDatosCobro) then
    FreeAndNil(FDatosCobro);
  FRepositorioVales := nil;
  FRepositorioPersistencia := nil;
end;

procedure TfrmMtoCajaFaseCobro.CargarFormasPago;
var
  Resultado: IResultadoConsultaFaseCobro;
  oFormasPago: TDataSet;
  iCampo: Integer;
  oCampoDestino: TField;
begin
  Resultado := FRepositorioPersistencia.ConsultarFormasPago;
  oFormasPago := Resultado.DataSet;
  if FMemTablePagos.Active then
  begin
    FMemTablePagos.Close;
  end;
  FMemTablePagos.FieldDefs.Clear;
  FMemTablePagos.Fields.Clear;
  FMemTablePagos.FieldDefs.Assign(oFormasPago.FieldDefs);
  // Float: con cripto el factor tiene más de 4 decimales (FZ-569).
  FMemTablePagos.FieldDefs.Add('FACTOR_CAMBIO', ftFloat);
  FMemTablePagos.FieldDefs.Add('ESIMPORTE_DIVISA', ftString, 1);
  FMemTablePagos.FieldDefs.Add('REFERENCIA', ftString, 255);
  FMemTablePagos.FieldDefs.Add('RED_BLOCKCHAIN', ftString, 50);
  FMemTablePagos.FieldDefs.Add('IMPORTE_ENTREGADO', ftFloat);
  FMemTablePagos.FieldDefs.Add('IMPORTE_DIVISA', ftFloat);
  FMemTablePagos.FieldDefs.Add('IMPORTE_CAMBIO', ftCurrency);
  FMemTablePagos.FieldDefs.Add('CODIGO_DIVISA', ftString, 6);
  FMemTablePagos.Open;
  FMemTablePagos.DisableControls;
  try
    oFormasPago.First;
    while not oFormasPago.Eof do
    begin
      FMemTablePagos.Append;
      for iCampo := 0 to oFormasPago.FieldCount - 1 do
      begin
        oCampoDestino := FMemTablePagos.FindField(
          oFormasPago.Fields[iCampo].FieldName);
        if Assigned(oCampoDestino) and
           not oFormasPago.Fields[iCampo].IsNull then
        begin
          oCampoDestino.Value := oFormasPago.Fields[iCampo].Value;
        end;
      end;
      FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat := 1;
      FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
      FMemTablePagos.FieldByName('REFERENCIA').AsString := '';
      FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString := '';
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := 0;
      FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat := 0;
      FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
      FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
      FMemTablePagos.Post;
      oFormasPago.Next;
    end;
    FMemTablePagos.First;
  finally
    FMemTablePagos.EnableControls;
  end;
end;
procedure TfrmMtoCajaFaseCobro.RellenarPendienteEnFormaActual;
var
  Pendiente: Currency;
begin
  if ConfirmarEditoresDescuento and
     FMemTablePagos.Active and not FMemTablePagos.IsEmpty then
  begin
    if FDatosCobro.EsDevolucionEconomica then
      Pendiente := FDatosCobro.ImporteDevolucionPendiente
    else
      Pendiente := FDatosCobro.ImportePendiente;
    if Pendiente > 0.01 then
    begin
      if FDatosCobro.EsDevolucionEconomica then
        EscribirImporteEnFormaActual(-Pendiente)
      else
        EscribirImporteEnFormaActual(Pendiente);
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarTablaVirtual;
begin
  FMemTablePagos := TVirtualTable.Create(Self);
end;

procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesEditValueChanged(
  Sender: TObject);
var
  ImporteActual: Double;
  v: Variant;
begin
  ImporteActual := 0;
  if Sender is TcxCurrencyEdit then
  begin
    v := TcxCurrencyEdit(Sender).EditingValue;
    if not (VarIsNull(v) or VarIsEmpty(v)) then
      ImporteActual := Double(v);
  end
  else if Sender is TcxCustomEdit then
  begin
    TcxCustomEdit(Sender).PostEditValue;
    ImporteActual := FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat;
  end;
  if Abs(ImporteActual) >= 0.0000000001 then
  begin
    if FDatosCobro.EsDevolucionEconomica then
    begin
      FDatosCobro.Recalcular;
      EscribirImporteEnFormaActual(-Abs(ImporteActual));
    end
    else
      EscribirImporteEnFormaActual(ImporteActual);
  end
  else
    AnularImporteEnFormaActual;
end;

// Poner a cero un importe ya entregado: sin el Post la rejilla deja la fila
// en edición y el pendiente no se recalcula hasta tocar otro campo. No pasa
// por EscribirImporteEnFormaActual para no pedir referencia de un cero.
procedure TfrmMtoCajaFaseCobro.AnularImporteEnFormaActual;
begin
  if FMemTablePagos.Active and not FMemTablePagos.IsEmpty then
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := 0;
    FMemTablePagos.Post;
  end;
end;

procedure TfrmMtoCajaFaseCobro.AjustarFormatoEditorActivo;
var
  EsCripto, EsDivisa: Boolean;
  EditProps: TcxCurrencyEditProperties;
  ActiveEdit: TcxCustomEdit;
begin
  EsCripto :=
    (FMemTablePagos.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S');
  EsDivisa :=
    (FMemTablePagos.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S');
  ActiveEdit := dbtvFormasPago.Controller.EditingController.Edit;
  if Assigned(ActiveEdit) and (ActiveEdit is TcxCurrencyEdit) then
  begin
    EditProps := TcxCurrencyEditProperties(
      TcxCurrencyEdit(ActiveEdit).ActiveProperties);
    if EsCripto then
    begin
      EditProps.DecimalPlaces := 9;
      EditProps.DisplayFormat := '#,##0.#########';
      EditProps.EditFormat := ConCeroEnBlanco('#########0.#########');
    end
    else if EsDivisa then
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00';
      EditProps.EditFormat := ConCeroEnBlanco(',0.00');
    end
    else
    begin
      EditProps.DecimalPlaces := 2;
      EditProps.DisplayFormat := ',0.00 €';
      EditProps.EditFormat := ConCeroEnBlanco(',0.00 €');
    end;
  end;
end;

// Al entrar en la celda el importe a cero sale en blanco, así que salir de
// ella sin teclear nada tiene que valer: se toma como cero.
procedure TfrmMtoCajaFaseCobro.dbmImportePropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if Trim(VarToStr(DisplayValue)) = '' then
  begin
    DisplayValue := '0';
    ErrorText    := '';
    Error        := False;
  end;
end;

procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoEditChanged(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem);
begin
  inherited;
  if AItem = dbmImporte then
    AjustarFormatoEditorActivo;
end;

procedure TfrmMtoCajaFaseCobro.dbtvFormasPagoEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString = 'VALE' then
    AAllow := False;
end;

procedure TfrmMtoCajaFaseCobro.EscribirImporteEnFormaActual(AImporte: Double);
var
  fp: TFormaPagoInfo;
  dr: TDatosReferencia;
  EsDivisa, EsCripto: Boolean;
begin
  EsDivisa :=
    FMemTablePagos.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString = 'S';
  EsCripto  :=
    FMemTablePagos.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString = 'S';
  fp.Codigo := FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString;
  fp.Descripcion :=
    FMemTablePagos.FieldByName('DESCRIPCION_FORMA_PAGO_CFP').AsString;
  fp.RequiereReferencia :=
          FMemTablePagos.FieldByName(
            'ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString = 'S';
  dr.Init;
  dr.EsDivisa  := EsDivisa;
  dr.EsCripto  := EsCripto;
  dr.Pendiente := txtPendienteCobro.Value;
  if EsDivisa or EsCripto or fp.RequiereReferencia then
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := AImporte;
    FMemTablePagos.Post;
    if TfrmCajaReferenciaPago.Ejecutar(fp, Abs(AImporte), dr) then
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString       := dr.Referencia;
      FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString   :=
                                                            dr.RedBlockchain;
      if EsDivisa then
      begin
        FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat    :=
                                                               dr.ImporteDivisa;
        FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat  :=
                                                                dr.FactorCambio;
        FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
        FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat :=
                                                                dr.ImporteEuros;
      end;
      FMemTablePagos.Post;
    end
    else
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName('REFERENCIA').AsString       := '';
      FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString   := '';
      FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := 0;
      FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat := 1;
      FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsFloat    := 0;
      FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'S';
      FMemTablePagos.Post;
    end;
  end
  else
  begin
    FMemTablePagos.Edit;
    FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsFloat := AImporte;
    FMemTablePagos.FieldByName('ESIMPORTE_DIVISA').AsString := 'N';
    FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString := '';
    FMemTablePagos.Post;
  end;
  FDatosCobro.Recalcular;
end;

procedure TfrmMtoCajaFaseCobro.dbmImporteGetDisplayText(
  Sender: TcxCustomGridTableItem;
  ARecord: TcxCustomGridRecord;
  var AText: string);
var
  EsDivisa: Boolean;
  Importe: Currency;
  RecordIndex: Integer;
  IdxDivisa, IdxCripto, IdxImporte, IdxEsDivisa: Integer;
  vImporte, vEsDivisa: Variant;
begin
  // DevExpress pide el texto con ARecord = nil cuando el editor no está
  // ligado a un registro: se deja el texto por defecto.
  RecordIndex := -1;
  if ARecord <> nil then
    RecordIndex := ARecord.RecordIndex;
  if RecordIndex >= 0 then
  begin
  var DC := dbtvFormasPago.DataController;
  IdxDivisa  := DC.GetItemByFieldName('ESDIVISA_FORMA_PAGO_CFP').Index;
  IdxCripto  := DC.GetItemByFieldName('ESCRIPTO_FORMA_PAGO_CFP').Index;
  IdxImporte := DC.GetItemByFieldName('IMPORTE_ENTREGADO').Index;
  IdxEsDivisa := DC.GetItemByFieldName('ESIMPORTE_DIVISA').Index;
  EsDivisa :=
    (VarToStr(DC.Values[RecordIndex, IdxDivisa]) = 'S') or
    (VarToStr(DC.Values[RecordIndex, IdxCripto]) = 'S');
  if EsDivisa then
  begin
    vImporte := DC.Values[RecordIndex, IdxImporte];
    if VarIsNull(vImporte) or VarIsEmpty(vImporte) then
      Importe := 0
    else
      Importe := Currency(vImporte);
    vEsDivisa := DC.Values[RecordIndex, IdxEsDivisa];
    if VarIsNull(vEsDivisa) or VarIsEmpty(vEsDivisa) then
    begin
      AText := ''
    end
    else
    begin
      if Importe > 0 then
        AText := FormatFloat('#,##0.000000000', Importe);
      if (vEsDivisa = 'N') then
        AText := FormatCurr(',0.00 €', Importe);
    end;
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.CargarDatosDesdeFactura(TotalesFactura:
                                                       TFacturaTotales);
begin
  if TotalesFactura <> nil then
  begin
    FDatosCobro.CargarDatosFactura(TotalesFactura);
    txtCantidadLineas.Text := ResumenCantidadesPorTipo(
      TotalesFactura.Lineas, 'CANTIDAD_FACLIN',
      'TIPO_CANTIDAD_ARTICULO_FACLIN');
    txtCantidadLineas.Hint := txtCantidadLineas.Text;
    txtCantidadLineas.ShowHint := True;
    // El resumen mixto no cabe en la celda de 64 píxeles. Mostrar el
    // número de líneas y conservar el desglose completo en la ayuda.
    if Pos(' + ', txtCantidadLineas.Text) > 0 then
    begin
      lblSuma.Caption := 'Líneas';
      txtCantidadLineas.Text := IntToStr(TotalesFactura.Lineas.RecordCount);
    end;
    txtBrutoLineas.Value := TotalesFactura.Totales.TotalBruto;
    txtTotalDtoLineal.Value := TotalesFactura.Totales.TotalDescuentosLineas;
    if TotalesFactura.Totales.TotalBruto <> 0 then
      txtPorcenDtoLineal.Text := FormatFloat('0.## %',
        (TotalesFactura.Totales.TotalDescuentosLineas /
         TotalesFactura.Totales.TotalBruto) * 100)
    else
      txtPorcenDtoLineal.Text := '0 %';
    FDatosCobro.Recalcular;
  end;
end;

// FZ-ISSUE-363: el vale de origen se precarga como pago recogido en la
// tabla de pagos, que no existe hasta CargarFormasPago (FormShow) y que
// ese método vuelve a crear. Por eso se aplica justo después, y no al
// cargar la factura (daba «closed dataset»).
procedure TfrmMtoCajaFaseCobro.AplicarValesOrigenSiProcede;
begin
  if (not FModoSubsanacion) and
     (Trim(FSerieOrigen) <> '') and (Trim(FNumeroOrigen) <> '') then
    FDatosCobro.AplicarValesOrigen(
      FRepositorioPersistencia.ConsultarValesOrigen(
        FEmpresaOrigen, FSerieOrigen, FNumeroOrigen));
end;

procedure TfrmMtoCajaFaseCobro.AlRecalcularDatos(Sender: TObject);
var
  EsTotal0: Boolean;
begin
  ActualizarImportesDescuento;
  txtCambio.Value       := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value := FDatosCobro.ImporteValeRecogido;
  FActualizandoVale := True;
  try
    txtValeEmitido.Value := FDatosCobro.ImporteValeEmitido;
  finally
    FActualizandoVale := False;
  end;
  EsTotal0 := (Abs(FDatosCobro.ImporteTotalPagar) < 0.01);
  if FDatosCobro.EsDevolucionEconomica then
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImporteDevolucionPendiente;
    txtPendienteCuenta.Value := 0;
    btnConTicket.Enabled  := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
       or EsTotal0;
    btnSinTicket.Enabled  := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
       or EsTotal0;
    btnSinPrecios.Enabled := (FDatosCobro.ImporteDevolucionPendiente <= 0.01)
       or EsTotal0;
    btnBuscarVale.Enabled := false;
  end
  else
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImportePendiente;
    txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
    btnConTicket.Enabled  := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnSinTicket.Enabled  := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnSinPrecios.Enabled := (FDatosCobro.ImportePendiente <= 0.01) or EsTotal0;
    btnBuscarVale.Enabled := (FDatosCobro.ImportePendiente > 0.01)
       and not EsTotal0;
  end;
  btnF6.Enabled := btnBuscarVale.Enabled;
  btnBuscarT.Enabled := (txtPendienteCobro.Value > 0.01) and not EsTotal0;
  btnF3.Enabled      := btnBuscarT.Enabled;
  btnF12.Enabled := btnConTicket.Enabled;
  btnF11.Enabled := btnSinTicket.Enabled;
  btnF10.Enabled := btnSinPrecios.Enabled;
end;

procedure TfrmMtoCajaFaseCobro.ActualizarInterfaz;
begin
  ActualizarImportesDescuento;
  txtCambio.Value         := FDatosCobro.ImporteCambio;
  txtValeRecogido.Value   := FDatosCobro.ImporteValeRecogido;
  txtValeEmitido.Value    := FDatosCobro.ImporteValeEmitido;
  if FDatosCobro.EsDevolucionEconomica then
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImporteDevolucionPendiente;
    txtPendienteCuenta.Value := 0;
    btnConTicket.Enabled := (FDatosCobro.ImporteDevolucionPendiente <= 0.01);
  end
  else
  begin
    txtPendienteCobro.Value  := FDatosCobro.ImportePendiente;
    txtPendienteCuenta.Value := FDatosCobro.ImportePendiente;
    btnConTicket.Enabled := (FDatosCobro.ImportePendiente <= 0.01);
  end;
  btnF12.Enabled := btnConTicket.Enabled;
  // Subsanar sin ticket se admite siempre que se admita subsanar: aquí no
  // hay emisión de documento que distinga a un botón del otro.
  if FModoSubsanacion then
  begin
    btnSinTicket.Enabled := btnConTicket.Enabled;
    btnF11.Enabled := btnSinTicket.Enabled;
  end;
  if FDatosCobro.EsDevolucionEconomica then
    ConfigurarModoDevolucion
  else
    ConfigurarModoCobroNormal;
  var PermiteCredito :=
    ParametrosCaja.GetBool('vgerVentasCredito', True) and
                     FDatosCobro.PuedeDejarEnCuenta;
  if Assigned(btnDeposito) then
    btnDeposito.Enabled := PermiteCredito;
  btnF7.Enabled := PermiteCredito;
end;

function TfrmMtoCajaFaseCobro.PuedeAplicarDescuentoGlobal: Boolean;
begin
  Result := Assigned(FDatosCobro);
  if Result then
    Result := not FHayLineasDeposito and
      (FDatosCobro.ImporteAntesDescuento > 0) and
      ParametrosCaja.GetBool('vgerDescuentos', True);
end;

procedure TfrmMtoCajaFaseCobro.ActualizarImportesDescuento;
begin
  FActualizandoDescuento := True;
  try
    if FEditorDescuentoActual <> txtPorcenDtoGlobal then
      txtPorcenDtoGlobal.Value := FDatosCobro.PorcentajeDescuentoGlobal;
    txtDtoGlobal.Value := FDatosCobro.ImporteDescuentoGlobal;
    if FEditorDescuentoActual <> txtTotalPagar then
      txtTotalPagar.Value := FDatosCobro.ImporteTotalPagar;
  finally
    FActualizandoDescuento := False;
  end;
  txtPorcenDtoGlobal.Enabled := PuedeAplicarDescuentoGlobal;
  txtTotalPagar.Properties.ReadOnly := not PuedeAplicarDescuentoGlobal;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarModoDevolucion;
begin
  txtPorcenDtoGlobal.Enabled := False;
  txtTotalPagar.Properties.ReadOnly := True;
  txtValeEmitido.Properties.ReadOnly := False;
  lblPendienteCobroAlt.Caption := SCaptionPendienteDevolver;
end;

procedure TfrmMtoCajaFaseCobro.ConfigurarModoCobroNormal;
begin
  // Si hay líneas de depósito, el descuento global no está permitido
  if FHayLineasDeposito then
  begin
    txtPorcenDtoGlobal.Enabled := False;
    txtPorcenDtoGlobal.Value   := 0;
    // Opcional: tooltip explicativo
    txtPorcenDtoGlobal.Hint    := SHintSinDescuentoGlobalDeposito;
    txtPorcenDtoGlobal.ShowHint := True;
  end
  else
    txtPorcenDtoGlobal.Enabled :=
      PuedeAplicarDescuentoGlobal;

  txtValeEmitido.Properties.ReadOnly := True;
  lblPendienteCobroAlt.Caption := SCaptionPendienteCobro;
end;

procedure TfrmMtoCajaFaseCobro.txtValeEmitidoPropertiesEditValueChanged(
  Sender: TObject);
begin
  if FDatosCobro.EsDevolucionEconomica and not FActualizandoVale then
  begin
    FActualizandoVale := True;
    try
      FDatosCobro.EmitirVale(txtValeEmitido.Value);
    finally
      FActualizandoVale := False;
    end;
  end;
end;


procedure TfrmMtoCajaFaseCobro.btnESCClick(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnF3Click(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.btnF6Click(Sender: TObject);
begin
  inherited;
  btnBuscarValeClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.btnF7Click(Sender: TObject);
var
  Res: TResultadoValidacion;
begin
  inherited;
  if FModoSubsanacion then
    Exit;
  // 1. Validar que tenemos un cliente válido y con permisos para dejar a deber
  if not FDatosCobro.PuedeDejarEnCuenta then
  begin
    ShowMessage_fza(SErrorCreditoClienteCajaNoPermitido);
  end
  else if (FDatosCobro.ImportePendiente <= 0) and
          (not FDatosCobro.EsDevolucionEconomica) and
          (FDatosCobro.ImporteTotalPagar > 0) then
  begin
    ShowMessage_fza(SErrorImporteCreditoCajaNoPendiente);
  end
  else if FDatosCobro.EsClienteVarios and
          (FDatosCobro.ImporteEntregado <= 0) then
    ShowMessage_fza(SErrorApartadoCajaSinEntrega)
  else if not ValidarDepositoCredito then
    ActualizarInterfaz
  else if FDatosCobro.EsClienteVarios and
          (not PedirContactoApartado) then
    ActualizarInterfaz
  else
  begin
    Res := FDatosCobro.EstablecerDejarEnCuenta(
      FDatosCobro.ImportePendiente);
    if not Res.Valido then
      ShowMessage_fza(Res.Mensaje)
    else
    begin
      ActualizarInterfaz;
      btnConTicketClick(Sender);
    end;
  end;
end;

procedure TfrmMtoCajaFaseCobro.btnAtrasClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMtoCajaFaseCobro.btnBuscarTClick(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.btnBuscarValeClick(Sender: TObject);
var
  ValeSeleccionado: TValeSeleccionado;
  PendienteActual, Exceso: Currency;
begin
  inherited;
  if not FModoSubsanacion and TfrmMtoCajaSeleccionVale.Ejecutar(
    FRepositorioVales, FDatosCobro.RestriccionVales,
    ValeSeleccionado) then
  begin
    // 1. Averiguamos cuánto se debe antes de aplicar el vale
    if FDatosCobro.EsDevolucionEconomica then
      PendienteActual := FDatosCobro.ImporteDevolucionPendiente
    else
      PendienteActual := FDatosCobro.ImportePendiente;
    // 2. Calculamos si el vale es mayor que la deuda
    Exceso := 0;
    if ValeSeleccionado.Importe > PendienteActual then
      Exceso := ValeSeleccionado.Importe - PendienteActual;
    // 3. Registramos siempre el vale recogido por su TOTAL
    FDatosCobro.RegistrarValeRecogido(
      ValeSeleccionado.CodigoVale,
      ValeSeleccionado.Importe
    );
    // 4. Si ha sobrado dinero, generamos automáticamente un vale emitido
    if Exceso > 0 then
    begin
      FDatosCobro.EmitirVale(Exceso);
      FDatosCobro.EstablecerValePadre(ValeSeleccionado.CodigoVale);
    end;
    // 5. Recalcular refrescará la interfaz y los totales
    FDatosCobro.Recalcular;
  end;
end;

procedure TfrmMtoCajaFaseCobro.FormShow(Sender: TObject);
var
  Cliente: TClienteFaseCobro;
begin
  inherited;
  FEmailEnvio := Trim(FEmailCliente);
  // Modo rectificación: número de la factura rectificada a la vista
  if FRectificaA <> '' then
    Caption := Caption + '  -  RECTIFICA la factura ' + FRectificaA;
  if Trim(FCodigoCliente) <> '' then
  begin
    if FRepositorioPersistencia.ObtenerCliente(
         FCodigoCliente,
         Cliente) then
    begin
      if FEmailEnvio = '' then
      begin
        FEmailEnvio := Trim(Cliente.Email);
      end;
      FDatosCobro.EstablecerCliente(FCodigoCliente, Cliente);
    end;
  end;
  CargarComboSeries;
  CargarFormasPago;
  AplicarValesOrigenSiProcede;
  if FModoSubsanacion then
    PrepararModoSubsanacion;
  ActualizarInterfaz;
  if cxgrdFormasPago.CanFocus then
  begin
    cxgrdFormasPago.SetFocus;
    if dbtvFormasPago.Controller.SelectedRecordCount > 0 then
      dbtvFormasPago.Controller.FocusedColumn := dbmImporte;
  end;
end;

procedure TfrmMtoCajaFaseCobro.actRellenarExecute(Sender: TObject);
begin
  inherited;
  RellenarPendienteEnFormaActual;
end;

procedure TfrmMtoCajaFaseCobro.actBuscarValeExecute(Sender: TObject);
begin
  inherited;
  btnBuscarValeClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actConTicketExecute(Sender: TObject);
begin
  inherited;
  btnConTicketClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actDepositoClienteExecute(Sender: TObject);
begin
  inherited;
  btnDepositoClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSalirExecute(Sender: TObject);
begin
  inherited;
  btnAtrasClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSinPreciosExecute(Sender: TObject);
begin
  inherited;
  btnSinPreciosClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.actSinTicketExecute(Sender: TObject);
begin
  inherited;
  btnSinTicketClick(Sender);
end;

procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesChange(
  Sender: TObject);
var
  Valor: Variant;
begin
  if not FActualizandoDescuento and PuedeAplicarDescuentoGlobal then
  begin
    Valor := txtPorcenDtoGlobal.EditingValue;
    // El campo vacío es "sin descuento": se aplica un 0 %
    if VarIsNull(Valor) or VarIsEmpty(Valor) or (Trim(VarToStr(Valor)) = '') then
      Valor := 0;
    if VarIsNumeric(Valor) then
    begin
      if (Valor >= 0) and (Valor <= 100) then
      begin
        FEditorDescuentoActual := txtPorcenDtoGlobal;
        try
          FDatosCobro.AplicarDescuentoGlobal(Valor);
        finally
          FEditorDescuentoActual := nil;
        end;
      end;
    end;
  end;
end;

// Sin descuento el campo se ve en blanco, de modo que dejarlo así no es un
// error de formato: equivale a un 0 %.
procedure TfrmMtoCajaFaseCobro.txtPorcenDtoGlobalPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
begin
  if Trim(VarToStr(DisplayValue)) = '' then
  begin
    DisplayValue := '0';
    ErrorText    := '';
    Error        := False;
  end;
end;

procedure TfrmMtoCajaFaseCobro.txtTotalPagarPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  Resultado: TResultadoValidacion;
  Importe: Currency;
begin
  if not Error and not FActualizandoDescuento and
     not txtTotalPagar.Properties.ReadOnly then
  begin
    if VarIsNull(DisplayValue) or VarIsEmpty(DisplayValue) then
      Resultado := TResultadoValidacion.Error(Format(
        SErrorTotalCobroFueraRango,
        [FDatosCobro.ImporteAntesDescuento]))
    else
    begin
      Importe := txtTotalPagar.Value;
      Resultado := FDatosCobro.ValidarTotalPagar(
        Importe, PuedeAplicarDescuentoGlobal);
    end;
    Error := not Resultado.Valido;
    ErrorText := Resultado.Mensaje;
  end;
end;

procedure TfrmMtoCajaFaseCobro.txtTotalPagarPropertiesChange(
  Sender: TObject);
var
  Resultado: TResultadoValidacion;
  Valor: Variant;
begin
  if not FActualizandoDescuento and PuedeAplicarDescuentoGlobal then
  begin
    Valor := txtTotalPagar.EditingValue;
    if VarIsNumeric(Valor) then
    begin
      Resultado := FDatosCobro.ValidarTotalPagar(
        Valor, PuedeAplicarDescuentoGlobal);
      if Resultado.Valido then
      begin
        FEditorDescuentoActual := txtTotalPagar;
        try
          FDatosCobro.AplicarTotalPagar(Valor, PuedeAplicarDescuentoGlobal);
        finally
          FEditorDescuentoActual := nil;
        end;
      end;
    end;
  end;
end;

end.
