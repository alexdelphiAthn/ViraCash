{******************************************************************************}
{                                                                              }
{  Módulo:       inLibFaseCobro                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Gestión de la fase de cobro en el punto de venta.                         }
{    Totales, cambio, validación de deuda y gestión de formas de pago.         }
{******************************************************************************}
unit inLibFaseCobro;

{
  Biblioteca para gestión de fase de cobro en punto de venta

  Funcionalidades:
  - Cálculo automático de totales, pendientes y cambios
  - Validación de deudas según cliente
  - Emisión de vales por importes negativos
  - Gestión de referencias y divisas en formas de pago
  - Integración con VirtualTable para grid de pagos

  Autor: Alejandro Laorden Hidalgo
  Fecha: 2026-02-15
}

interface

uses
  inLibReparaciones,
  System.SysUtils, System.Classes, System.Generics.Collections, System.Math,
  Data.DB, VirtualTable, inLibFacturas, inLibFaseCobroPersistenciaIntf,
  inLibFaseCobroCalculo;

type
  TDatosCliente = record
    CodigoCliente: string;
    NombreCliente: string;
    PermiteDeuda: Boolean;
    EsClienteVarios: Boolean;
    LimiteCredito: Currency;
    DeudaActual: Currency;
    procedure Clear;
  end;

  // Quién aparta prendas a nombre del cliente de Varios.
  TContactoApartado = record
    Nombre: string;
    Telefono: string;
  end;

  TFormaPagoInfo = record
    Codigo: string;
    Descripcion: string;
    DevuelveCambio: Boolean;
    RequiereReferencia: Boolean;
    OrdenPrioridad: Integer;
  end;

  TFormaPagoItem = record
    NumeroLinea: Integer;
    CodigoFormaPago: string;
    DescripcionFormaPago: string;
    CodigoDivisa: string;
    RedBlockchain: string;
    // Double: con cripto el factor tiene más de 4 decimales (FZ-569).
    FactorCambio: Double;
    ImporteDivisa: Double;
    ImporteEntregado: Currency;
    ImporteCambio: Currency;
    Referencia: string;
    Observaciones: string;
  end;

  TResultadoValidacion = record
    Valido: Boolean;
    Mensaje: string;
    PermitirContinuar: Boolean;
    class function OK: TResultadoValidacion; static;
    class function Error(const AMensaje: string): TResultadoValidacion; static;
    class function Advertencia(const AMensaje: string): TResultadoValidacion;
                                                                         static;
  end;

  TDatosReferencia = record
    Referencia: string;
    CodigoDivisa: string;
    EsCripto: boolean;
    EsDivisa: boolean;
    Pendiente:Double;
    FactorCambio: Double;
    ImporteDivisa: Double;
    ImporteEuros:Currency;
    RedBlockchain: string;
    HashBlockchain: string;
    procedure Init;
  end;

  TValeAplicado = record
    CodigoVale: string;
    PinSeguridad: string;
    ImporteAplicado: Currency;
  end;

  TDatosFaseCobro = class
  private
    FRepositorio: IRepositorioFaseCobro;
    FTotalesFactura: TFacturaTotales;
    FDatosCliente: TDatosCliente;
    FMemTablePagos: TVirtualTable;
    FValesRecogidos: TList<TValeAplicado>;
    FCodigoValeEmitido:String;
    FPinValeEmitido: string;
    FImporteBruto: Currency;
    FImporteDescuentoLineal: Currency;
    FImporteAntesDescuento: Currency;
    FPorcentajeDescuentoGlobal: Currency;
    FImporteDescuentoGlobal: Currency;
    FDescuentoPorImporte: Boolean;
    FImporteDescuentoFijado: Currency;
    FImporteTotalPagar: Currency;
    FImporteEntregado: Currency;
    FImportePendiente: Currency;
    FImporteCambio: Currency;
    FImporteDejarCuenta: Currency;
    FImporteValeRecogido: Currency;
    FImporteValeEmitido: Currency;
    FImporteDevueltoDeMas: Currency;
    FImporteValeObligatorio: Currency;
    FImporteYaCobrado: Currency;
    FCodigoValePadre: string;
    FImporteValesFijos: Currency;
    FHayCliente: Boolean;
    FPermiteDeuda: Boolean;
    FEsClienteVarios: Boolean;
    FContactoApartado: TContactoApartado;
    FCalculandoTotales: Boolean;
    FOnRecalculado: TNotifyEvent;
    FOnRequiereReferencia: TFunc<TFormaPagoInfo, TDatosReferencia, Boolean>;
    procedure CalcularTotales;
    procedure AplicarResultadoTotales(
      const AResultado: TResultadoTotalesCobro);
    function LeerEntradaTotales: TEntradaTotalesCobro;
    procedure LimpiarPagosCubiertosPorVales(
      var AEntrada: TEntradaTotalesCobro);
    procedure InicializarTotalesPorDefecto;
    function ValidarDeuda: TResultadoValidacion;
    function ValidarApartado(
      AImporteCuenta: Currency): TResultadoValidacion;
    function ValidarVale: TResultadoValidacion;
    function ImporteEfectivoEuros: Currency;
    function ValidarLimiteEfectivo: TResultadoValidacion;
    function ObtenerFormaPagoInfo(const ACodigo: string): TFormaPagoInfo;
    function ObtenerCurrencySafe(const ANombreCampo: string;
                                 const ADefault: Currency = 0): Currency;
    function ObtenerStringSafe(const ANombreCampo: string;
                               const ADefault: string = ''): string;
  public
    PrendasReparacion: TArray<TPrendaVentaReparacion>;
    NombreReparacion: string;
    TelefonoReparacion: string;
    EmailReparacion: string;
    FRequiereFactura:Boolean;
    constructor Create(
      const ARepositorio: IRepositorioFaseCobro;
      AMemTable: TVirtualTable);
    destructor Destroy; override;
    procedure CargarDatosFactura(ATotales: TFacturaTotales);
    procedure EstablecerCliente(const ACodigo, ANombre: string;
                                APermiteDeuda, AEsClienteVarios: Boolean;
                                ALimiteCredito, ADeudaActual: Currency);
                                overload;
    procedure EstablecerCliente(const ACodigo: string;
      const ACliente: TClienteFaseCobro); overload;
    procedure QuitarCliente;
    procedure EstablecerContactoApartado(const AContacto: TContactoApartado);
    function EsApartado: Boolean;
// procedure CargarFormasPagoDisponibles(AFormasPago: TArray<TFormaPagoInfo>);
    function ActualizarImportePago(ALineaPago: Integer; AImporte: Currency;
                                   ADatosRef: TDatosReferencia): Boolean;
    procedure AplicarDescuentoGlobal(APorcentaje: Currency); overload;
    procedure AplicarDescuentoGlobal(APorcentaje: Currency;
                                     AImporte: Currency); overload;
    function ValidarTotalPagar(ATotal: Currency;
      APermiteDescuento: Boolean): TResultadoValidacion;
    function AplicarTotalPagar(ATotal: Currency;
      APermiteDescuento: Boolean): TResultadoValidacion;
    function PuedeDejarEnCuenta: Boolean;
    function EstablecerDejarEnCuenta(AImporte: Currency): TResultadoValidacion;
    function PuedeEmitirVale: Boolean;
    function EmitirVale(AImporte: Currency): TResultadoValidacion;
    procedure RegistrarValeRecogido(ACodigoVale: string; AImporte: Currency);
    // Subsanación: neto de los vales ya grabados en el ticket (canjeados
    // menos emitidos). Cubre parte del total sin filas en la rejilla.
    procedure EstablecerValesFijos(AImporte: Currency);
    // Devolución o rectificación de un ticket con vales (FZ-363): lo
    // pagado con vale se devuelve en vale y los vales que emitió el
    // ticket y siguen pendientes se recogen como pago.
    procedure AplicarValesOrigen(const AVales: TValesOrigenFaseCobro);
    // Canje parcial: el vale de cambio procede del vale canjeado (FZ-360)
    procedure EstablecerValePadre(const ACodigoVale: string);
    function EsDevolucionEconomica: Boolean;
    // FZ-ISSUE-395: algún pago con importe usa una forma de pago que
    // abre el cajón (el efectivo); con solo tarjeta no hay que abrirlo.
    function AlgunPagoAbreCajon: Boolean;
    function TieneArticulosDevueltos: Boolean;
    function ValidarParaCobro: TResultadoValidacion;
    function ObtenerDatosPagosParaGrabar: TArray<TFormaPagoItem>;
    procedure Recalcular;
    property ImporteBruto: Currency read FImporteBruto;
    property ImporteDescuentoLineal: Currency read FImporteDescuentoLineal;
    property ImporteAntesDescuento: Currency read FImporteAntesDescuento;
    property PorcentajeDescuentoGlobal: Currency
      read FPorcentajeDescuentoGlobal;
    property ImporteDescuentoGlobal: Currency read FImporteDescuentoGlobal;
    property ImporteTotalPagar: Currency read FImporteTotalPagar;
    property ImporteEntregado: Currency read FImporteEntregado;
    property ImportePendiente: Currency read FImportePendiente;
    property ImporteCambio: Currency read FImporteCambio;
    property ImporteDejarCuenta: Currency read FImporteDejarCuenta;
    property ImporteValeRecogido: Currency read FImporteValeRecogido;
    property ImporteValeEmitido: Currency read FImporteValeEmitido;
    property CodigoValeEmitido:String read FCodigoValeEmitido
                                      write FCodigoValeEmitido;
    property PinValeEmitido: string read FPinValeEmitido
                                   write FPinValeEmitido;
    property ImporteValeObligatorio: Currency read FImporteValeObligatorio;
    // FZ-ISSUE-379: líquido de la factura sustituida (0 si no lo es).
    property ImporteYaCobrado: Currency read FImporteYaCobrado;
    procedure EstablecerImporteYaCobrado(AImporte: Currency);
    // Vale canjeado en el ticket de origen del que procede el emitido
    property CodigoValePadre: string read FCodigoValePadre;
    property HayCliente: Boolean read FHayCliente;
    property PermiteDeuda: Boolean read FPermiteDeuda;
    // Cliente genérico: lo que deja en cuenta es un apartado sin deuda.
    property EsClienteVarios: Boolean read FEsClienteVarios;
    property ContactoApartado: TContactoApartado read FContactoApartado;
    property ImporteDevolucionPendiente: Currency read FImportePendiente;
    property OnRecalculado: TNotifyEvent read FOnRecalculado
                                         write FOnRecalculado;
    property OnRequiereReferencia: TFunc<TFormaPagoInfo,
                                         TDatosReferencia,
                                         Boolean>
                                   read FOnRequiereReferencia
                                   write FOnRequiereReferencia;
    property MemTablePagos: TVirtualTable read FMemTablePagos;
    property ValesRecogidos: TList<TValeAplicado> read FValesRecogidos;
    property TotalesFactura:TFacturaTotales read FTotalesFactura;
  end;

implementation

uses
  Vcl.Dialogs, System.UITypes, inLibMsgCaja;

resourcestring
  SErrorDejarCuentaSinClienteAsignado =
    'No se puede dejar en cuenta sin cliente asignado.';
  SErrorClienteNoPermiteDejarCuenta =
    'El cliente no tiene permitido dejar cantidades en cuenta.';
  SErrorLimiteCreditoExcedido =
    'Límite de crédito excedido.' + sLineBreak +
    'Deuda actual: %m' + sLineBreak +
    'Nueva deuda: %m' + sLineBreak +
    'Límite: %m';
  SErrorImporteValeNoPositivo =
    'El importe del vale no puede ser cero o menor que cero.';
  SErrorDejarImporteCuentaSinCliente =
    'No se puede dejar importe en cuenta sin cliente.';
  SErrorClienteNoPermiteImporteCuenta =
    'El cliente no permite dejar cantidades en cuenta.';
  SErrorValeNoDisponible =
    'El vale introducido (%s) no existe en la base de datos o ha sido ' +
    'recogido o anulado.';
  SErrorDevolucionIncompleta =
    'Devolución incompleta. Falta por devolver al cliente: %m';
  SErrorDevolucionExcesiva =
    'Se devuelve más de lo debido. Sobran: %m';
  SErrorDevolucionExcesivaVale =
    'Se devuelve más de lo debido. Sobran: %m' + sLineBreak +
    'Lo pagado con vale en el ticket de origen (%m) se devuelve en vale.';
  SErrorPagoNoIndicado = 'No se ha indicado ningún pago.';
  SErrorApartadoSinEntregaCuenta =
    'Para apartar prendas el cliente tiene que dejar algo a cuenta.';
  SErrorApartadoSinContacto =
    'Indique el nombre de quien aparta las prendas.';
  SAdvertenciaCobroIncompleto =
    'Cobro incompleto. Pendiente: %m' + sLineBreak +
    '¿Desea dejarlo en cuenta?';
  SErrorLimitePagoEfectivo =
    'No se puede cobrar en efectivo %m.' + sLineBreak + sLineBreak +
    'La Ley 7/2012 (art. 7, en la redacción de la Ley 11/2021) prohíbe ' +
    'pagar en efectivo operaciones de %m o más cuando una de las partes ' +
    'es empresario o profesional.' + sLineBreak + sLineBreak +
    'El efectivo en euros no puede llegar a %m: cobre el resto (%m como ' +
    'mínimo) con tarjeta, transferencia u otra forma de pago.';

const
  // Límite legal de pago en efectivo (Ley 7/2012, art. 7): se prohíben los
  // pagos en efectivo de 1.000 euros o más.
  LIMITE_PAGO_EFECTIVO_EUROS = 1000;

{ TDatosCliente }


procedure TDatosCliente.Clear;
begin
  CodigoCliente := '';
  NombreCliente := '';
  PermiteDeuda := False;
  EsClienteVarios := False;
  LimiteCredito := 0;
  DeudaActual := 0;
end;

{ TDatosReferencia }

procedure TDatosReferencia.Init;
begin
  Referencia := '';
  CodigoDivisa := 'EUR';
  FactorCambio := 1;
  ImporteDivisa := 0;
  RedBlockchain := '';
  HashBlockchain := '';
  EsCripto := False;
  EsDivisa := False;
end;

{ TResultadoValidacion }

class function TResultadoValidacion.OK: TResultadoValidacion;
begin
  Result.Valido := True;
  Result.Mensaje := '';
  Result.PermitirContinuar := True;
end;

class function TResultadoValidacion.Error(
  const AMensaje: string): TResultadoValidacion;
begin
  Result.Valido := False;
  Result.Mensaje := AMensaje;
  Result.PermitirContinuar := False;
end;

class function TResultadoValidacion.Advertencia(
  const AMensaje: string): TResultadoValidacion;
begin
  Result.Valido := False;
  Result.Mensaje := AMensaje;
  Result.PermitirContinuar := True;
end;

{ TDatosFaseCobro }

constructor TDatosFaseCobro.Create(
  const ARepositorio: IRepositorioFaseCobro;
  AMemTable: TVirtualTable);
begin
  inherited Create;
  FRepositorio := ARepositorio;
  FMemTablePagos := AMemTable;
  FValesRecogidos := TList<TValeAplicado>.Create;
  FImporteBruto := 0;
  FImporteDescuentoLineal := 0;
  FPorcentajeDescuentoGlobal := 0;
  FImporteDescuentoGlobal := 0;
  FImporteTotalPagar := 0;
  FImporteEntregado := 0;
  FImportePendiente := 0;
  FImporteCambio := 0;
  FImporteDejarCuenta := 0;
  FImporteValeRecogido := 0;
  FImporteValeEmitido := 0;
  FImporteDevueltoDeMas := 0;
  FImporteValeObligatorio := 0;
  FImporteYaCobrado := 0;
  FCodigoValePadre := '';
  FHayCliente := False;
  FPermiteDeuda := False;
  FDatosCliente.Clear;
end;

destructor TDatosFaseCobro.Destroy;
begin
  FreeAndNil(FValesRecogidos);
  inherited;
end;

procedure TDatosFaseCobro.CargarDatosFactura(ATotales: TFacturaTotales);
begin
  FTotalesFactura := ATotales;
  if Assigned(ATotales) then
  begin
    FImporteBruto := ATotales.Totales.TotalBruto;
    FImporteDescuentoLineal := ATotales.Totales.TotalDescuentosLineas;
    FImporteAntesDescuento := ATotales.Totales.TotalLiquido;
  end
  else
  begin
    FImporteBruto := 0;
    FImporteDescuentoLineal := 0;
    FImporteAntesDescuento := 0;
  end;
  Recalcular;
end;

procedure TDatosFaseCobro.EstablecerCliente(const ACodigo: string;
  const ACliente: TClienteFaseCobro);
begin
  EstablecerCliente(ACodigo, ACliente.Nombre, ACliente.PermiteDeuda,
    ACliente.EsClienteVarios, ACliente.LimiteCredito, ACliente.DeudaActual);
end;

procedure TDatosFaseCobro.EstablecerCliente(const ACodigo, ANombre: string;
  APermiteDeuda, AEsClienteVarios: Boolean;
  ALimiteCredito, ADeudaActual: Currency);
begin
  FDatosCliente.CodigoCliente := Trim(ACodigo);
  FDatosCliente.NombreCliente := Trim(ANombre);
  FDatosCliente.PermiteDeuda := APermiteDeuda;
  FDatosCliente.EsClienteVarios := AEsClienteVarios;
  FDatosCliente.LimiteCredito := ALimiteCredito;
  FDatosCliente.DeudaActual := ADeudaActual;
  FHayCliente := (Trim(FDatosCliente.CodigoCliente) <> '');
  FPermiteDeuda := FHayCliente and APermiteDeuda;
  FEsClienteVarios := FHayCliente and AEsClienteVarios;
  FContactoApartado := Default(TContactoApartado);
  if not PuedeDejarEnCuenta then
    FImporteDejarCuenta := 0;
  Recalcular;
end;

procedure TDatosFaseCobro.EstablecerContactoApartado(
  const AContacto: TContactoApartado);
begin
  FContactoApartado.Nombre := Trim(AContacto.Nombre);
  FContactoApartado.Telefono := Trim(AContacto.Telefono);
end;

function TDatosFaseCobro.EsApartado: Boolean;
begin
  Result := FEsClienteVarios and (FImporteDejarCuenta > 0);
end;

procedure TDatosFaseCobro.QuitarCliente;
begin
  FDatosCliente.Clear;
  FHayCliente := False;
  FPermiteDeuda := False;
  FEsClienteVarios := False;
  FContactoApartado := Default(TContactoApartado);
  if FImporteDejarCuenta > 0 then
  begin
    FImporteDejarCuenta := 0;
    Recalcular;
  end;
end;

function TDatosFaseCobro.ActualizarImportePago(ALineaPago: Integer;
                                               AImporte: Currency;
                                          ADatosRef: TDatosReferencia): Boolean;
var
  FormaPagoInfo: TFormaPagoInfo;
  CodigoFormaPago: string;
  DatosRef: TDatosReferencia;
  bContinuar: Boolean;
begin
  Result := False;
  if Assigned(FMemTablePagos) then
  begin
    CodigoFormaPago := FMemTablePagos.FieldByName(
      'CODIGO_FP_CFP').AsString;
    FormaPagoInfo := ObtenerFormaPagoInfo(CodigoFormaPago);
    DatosRef := ADatosRef;
    bContinuar := True;
    if FormaPagoInfo.RequiereReferencia and
       DatosRef.Referencia.IsEmpty then
    begin
      if Assigned(FOnRequiereReferencia) then
        bContinuar := FOnRequiereReferencia(FormaPagoInfo, DatosRef)
      else
        DatosRef.Init;
    end;
    if bContinuar then
    begin
      FMemTablePagos.Edit;
      FMemTablePagos.FieldByName(
        'IMPORTE_ENTREGADO').AsCurrency := AImporte;
      FMemTablePagos.FieldByName(
        'CODIGO_DIVISA').AsString := DatosRef.CodigoDivisa;
      FMemTablePagos.FieldByName(
        'FACTOR_CAMBIO').AsFloat := DatosRef.FactorCambio;
      FMemTablePagos.FieldByName(
        'IMPORTE_DIVISA').AsCurrency := DatosRef.ImporteDivisa;
      FMemTablePagos.FieldByName(
        'REFERENCIA').AsString := DatosRef.Referencia;
      FMemTablePagos.FieldByName(
        'RED_BLOCKCHAIN').AsString := DatosRef.RedBlockchain;
      FMemTablePagos.Post;
      Recalcular;
      Result := True;
    end;
  end;
end;

procedure TDatosFaseCobro.AplicarDescuentoGlobal(APorcentaje: Currency);
begin
  FDescuentoPorImporte := False;
  FPorcentajeDescuentoGlobal := APorcentaje;
  Recalcular;
end;

procedure TDatosFaseCobro.AplicarDescuentoGlobal(APorcentaje,
                                                 AImporte: Currency);
begin
  FDescuentoPorImporte := True;
  FPorcentajeDescuentoGlobal := APorcentaje;
  FImporteDescuentoFijado := AImporte;
  Recalcular;
end;

function TDatosFaseCobro.ValidarTotalPagar(ATotal: Currency;
  APermiteDescuento: Boolean): TResultadoValidacion;
var
  Porcentaje: Currency;
  Descuento: Currency;
begin
  if not APermiteDescuento then
    Result := TResultadoValidacion.Error(SErrorAjusteTotalNoPermitido)
  else if not TCalculadorFaseCobro.CalcularDescuentoParaTotal(
    FImporteAntesDescuento, ATotal,
    Porcentaje, Descuento) then
    Result := TResultadoValidacion.Error(Format(
      SErrorTotalCobroFueraRango,
      [FImporteAntesDescuento]))
  else
    Result := TResultadoValidacion.Ok;
end;

function TDatosFaseCobro.AplicarTotalPagar(ATotal: Currency;
  APermiteDescuento: Boolean): TResultadoValidacion;
var
  Porcentaje: Currency;
  Descuento: Currency;
begin
  Result := ValidarTotalPagar(ATotal, APermiteDescuento);
  if Result.Valido then
  begin
    TCalculadorFaseCobro.CalcularDescuentoParaTotal(
      FImporteAntesDescuento, ATotal,
      Porcentaje, Descuento);
    AplicarDescuentoGlobal(Porcentaje, Descuento);
  end;
end;

function TDatosFaseCobro.PuedeDejarEnCuenta: Boolean;
begin
  Result := FHayCliente and (FPermiteDeuda or FEsClienteVarios);
end;

function TDatosFaseCobro.EstablecerDejarEnCuenta(
                                      AImporte: Currency): TResultadoValidacion;
var
  NuevaDeuda: Currency;
begin
  Result := TResultadoValidacion.OK;
  if not FHayCliente then
    Result := TResultadoValidacion.Error(SErrorDejarCuentaSinClienteAsignado)
  else if not PuedeDejarEnCuenta then
    Result := TResultadoValidacion.Error(SErrorClienteNoPermiteDejarCuenta)
  else if FEsClienteVarios then
    Result := ValidarApartado(AImporte)
  else if FDatosCliente.LimiteCredito > 0 then
  begin
    NuevaDeuda := FDatosCliente.DeudaActual + AImporte;
    if NuevaDeuda > FDatosCliente.LimiteCredito then
    begin
      Result := TResultadoValidacion.Error(
        Format(SErrorLimiteCreditoExcedido,
               [FDatosCliente.DeudaActual, NuevaDeuda,
                FDatosCliente.LimiteCredito]));
    end;
  end;
  if Result.Valido then
  begin
    FImporteDejarCuenta := AImporte;
    Recalcular;
  end;
end;

function TDatosFaseCobro.EsDevolucionEconomica: Boolean;
begin
  Result := FImporteTotalPagar < 0;
end;

function TDatosFaseCobro.PuedeEmitirVale: Boolean;
begin
  Result := EsDevolucionEconomica or (FImportePendiente < 0) or
            (FImporteValeEmitido > 0);
end;

function TDatosFaseCobro.EmitirVale(AImporte: Currency): TResultadoValidacion;
begin
  if AImporte <= 0 then
    Result := TResultadoValidacion.Error(SErrorImporteValeNoPositivo)
  else
  begin
    FImporteValeEmitido := Abs(AImporte);
    Recalcular;
    Result := TResultadoValidacion.OK;
  end;
end;

procedure TDatosFaseCobro.RegistrarValeRecogido(ACodigoVale: string;
  AImporte: Currency);
var
  ValeAplicado: TValeAplicado;
begin
  if Assigned(FMemTablePagos) then
  begin
    FMemTablePagos.Append;
  FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString := 'VALE';
  FMemTablePagos.FieldByName('DESCRIPCION_FORMA_PAGO_CFP').AsString :=
    ACodigoVale;
  FMemTablePagos.FieldByName('ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP').AsString :=
    'N';
  FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency := AImporte;
  FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString := 'EUR';
  FMemTablePagos.FieldByName('ESCRIPTO_FORMA_PAGO_CFP').AsString := 'N';
  FMemTablePagos.FieldByName('ESDIVISA_FORMA_PAGO_CFP').AsString := 'N';
  FMemTablePagos.FieldByName('ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString := 'S';
  FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat := 1;
  FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency := 0;
  FMemTablePagos.FieldByName('REFERENCIA').AsString := ACodigoVale;
  FMemTablePagos.FieldByName('IMPORTE_CAMBIO').AsCurrency := 0;
  FMemTablePagos.FieldByName('USUARIO_ALTA').AsString := 'CAJA';
  FMemTablePagos.FieldByName('USUARIO_MODIF').AsString := 'CAJA';
  FMemTablePagos.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
  FMemTablePagos.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  FMemTablePagos.Post;
  ValeAplicado.CodigoVale      := ACodigoVale;
  ValeAplicado.PinSeguridad    := '';
  ValeAplicado.ImporteAplicado := AImporte;
    FValesRecogidos.Add(ValeAplicado);
  end;
end;

procedure TDatosFaseCobro.EstablecerValesFijos(AImporte: Currency);
begin
  FImporteValesFijos := AImporte;
  Recalcular;
end;

procedure TDatosFaseCobro.EstablecerValePadre(const ACodigoVale: string);
begin
  FCodigoValePadre := ACodigoVale;
end;

procedure TDatosFaseCobro.EstablecerImporteYaCobrado(AImporte: Currency);
begin
  FImporteYaCobrado := AImporte;
  Recalcular;
end;

procedure TDatosFaseCobro.AplicarValesOrigen(
  const AVales: TValesOrigenFaseCobro);
var
  oVale: TValeOrigenFaseCobro;
begin
  FImporteValeObligatorio := 0;
  FCodigoValePadre := '';
  if EsDevolucionEconomica then
  begin
    if AVales.ImporteCanjeado > 0 then
    begin
      FImporteValeObligatorio := AVales.ImporteCanjeado;
      FCodigoValePadre := AVales.CodigoValeCanjeado;
    end;
  end
  else if FImporteTotalPagar > 0 then
  begin
    for oVale in AVales.ValesPendientes do
      RegistrarValeRecogido(oVale.Codigo, oVale.Importe);
  end;
  Recalcular;
end;

function TDatosFaseCobro.TieneArticulosDevueltos: Boolean;
begin
  if Assigned(FTotalesFactura) then
    Result := FTotalesFactura.FTieneLineasNegativas
  else
    Result := False;
end;

function TDatosFaseCobro.ObtenerCurrencySafe(const ANombreCampo: string;
  const ADefault: Currency = 0): Currency;
var
  Field: TField;
begin
  Result := ADefault;
  if Assigned(FMemTablePagos) and FMemTablePagos.Active then
  begin
    Field := FMemTablePagos.FindField(ANombreCampo);
    if Assigned(Field) and not Field.IsNull then
      Result := Field.AsCurrency;
  end;
end;

function TDatosFaseCobro.ObtenerStringSafe(const ANombreCampo: string;
  const ADefault: string = ''): string;
var
  Field: TField;
begin
  Result := ADefault;
  if Assigned(FMemTablePagos) and FMemTablePagos.Active then
  begin
    Field := FMemTablePagos.FindField(ANombreCampo);
    if Assigned(Field) and not Field.IsNull then
      Result := Field.AsString;
  end;
end;

procedure TDatosFaseCobro.AplicarResultadoTotales(
  const AResultado: TResultadoTotalesCobro);
begin
  FImporteDescuentoGlobal := AResultado.ImporteDescuentoGlobal;
  FImporteTotalPagar := AResultado.ImporteTotalPagar;
  FImporteEntregado := AResultado.ImporteEntregado;
  FImportePendiente := AResultado.ImportePendiente;
  FImporteCambio := AResultado.ImporteCambio;
  FImporteValeRecogido := AResultado.ImporteValeRecogido;
  FImporteValeEmitido := AResultado.ImporteValeEmitido;
  FImporteDevueltoDeMas := AResultado.ImporteDevueltoDeMas;
end;

function TDatosFaseCobro.LeerEntradaTotales: TEntradaTotalesCobro;
var
  oMarcador: TBookmark;
  sCodigoForma: string;
  dImporte: Currency;
begin
  Result := Default(TEntradaTotalesCobro);
  Result.ImporteBruto := FImporteBruto;
  Result.DescuentoLineal := FImporteDescuentoLineal;
  Result.UsarTotalFactura := True;
  Result.TotalFactura := FImporteAntesDescuento;
  Result.PorcentajeDescuento := FPorcentajeDescuentoGlobal;
  Result.DescuentoPorImporte := FDescuentoPorImporte;
  Result.ImporteDescuentoFijado := FImporteDescuentoFijado;
  Result.ImporteDejarCuenta := FImporteDejarCuenta;
  Result.ImporteValeEmitido := FImporteValeEmitido;
  Result.ImporteValeObligatorio := FImporteValeObligatorio;
  Result.ImporteYaCobrado := FImporteYaCobrado;
  Result.TotalValesRecogidos := FImporteValesFijos;
  FMemTablePagos.DisableControls;
  oMarcador := FMemTablePagos.GetBookmark;
  try
    FMemTablePagos.First;
    while not FMemTablePagos.Eof do
    begin
      sCodigoForma := ObtenerStringSafe('CODIGO_FP_CFP', '');
      dImporte := ObtenerCurrencySafe('IMPORTE_ENTREGADO', 0);
      if sCodigoForma = 'VALE' then
        Result.TotalValesRecogidos :=
          Result.TotalValesRecogidos + dImporte
      else if sCodigoForma <> '' then
      begin
        Result.TotalEntregado := Result.TotalEntregado + dImporte;
        if (Abs(dImporte) > 0.001) and
           (ObtenerStringSafe(
              'ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP', 'N') = 'S') then
          Result.TotalEntregadoConCambio :=
            Result.TotalEntregadoConCambio + dImporte;
      end;
      FMemTablePagos.Next;
    end;
  finally
    if FMemTablePagos.BookmarkValid(oMarcador) then
      FMemTablePagos.GotoBookmark(oMarcador);
    FMemTablePagos.FreeBookmark(oMarcador);
    FMemTablePagos.EnableControls;
  end;
end;

procedure TDatosFaseCobro.LimpiarPagosCubiertosPorVales(
  var AEntrada: TEntradaTotalesCobro);
var
  dBase: Currency;
  dDescuento: Currency;
  oMarcador: TBookmark;
begin
  dBase := AEntrada.ImporteBruto - AEntrada.DescuentoLineal;
  dDescuento := 0;
  if Abs(AEntrada.PorcentajeDescuento) > 0.001 then
    dDescuento := dBase * (AEntrada.PorcentajeDescuento / 100);
  if (AEntrada.TotalValesRecogidos >= dBase - dDescuento) and
     (dBase - dDescuento > 0) and
     (AEntrada.TotalEntregado <> 0) then
  begin
    FMemTablePagos.DisableControls;
    oMarcador := FMemTablePagos.GetBookmark;
    try
      FMemTablePagos.First;
      while not FMemTablePagos.Eof do
      begin
        if (FMemTablePagos.FieldByName(
              'CODIGO_FP_CFP').AsString <> 'VALE') and
           (FMemTablePagos.FieldByName(
              'IMPORTE_ENTREGADO').AsCurrency <> 0) then
        begin
          FMemTablePagos.Edit;
          FMemTablePagos.FieldByName(
            'IMPORTE_ENTREGADO').AsCurrency := 0;
          FMemTablePagos.Post;
        end;
        FMemTablePagos.Next;
      end;
    finally
      if FMemTablePagos.BookmarkValid(oMarcador) then
        FMemTablePagos.GotoBookmark(oMarcador);
      FMemTablePagos.FreeBookmark(oMarcador);
      FMemTablePagos.EnableControls;
    end;
    AEntrada.TotalEntregado := 0;
    AEntrada.TotalEntregadoConCambio := 0;
  end;
end;

procedure TDatosFaseCobro.CalcularTotales;
var
  oEntrada: TEntradaTotalesCobro;
  oResultado: TResultadoTotalesCobro;
begin
  if not FCalculandoTotales then
  begin
    FCalculandoTotales := True;
    try
      if Assigned(FMemTablePagos) and
         FMemTablePagos.Active and
         (FMemTablePagos.FieldCount > 0) then
      begin
        oEntrada := LeerEntradaTotales;
        LimpiarPagosCubiertosPorVales(oEntrada);
        oResultado := TCalculadorFaseCobro.CalcularTotales(oEntrada);
        AplicarResultadoTotales(oResultado);
        if Assigned(FOnRecalculado) then
          FOnRecalculado(Self);
      end
      else
        InicializarTotalesPorDefecto;
    finally
      FCalculandoTotales := False;
    end;
  end;
end;

procedure TDatosFaseCobro.InicializarTotalesPorDefecto;
var
  Entrada: TEntradaTotalesCobro;
begin
  Entrada := Default(TEntradaTotalesCobro);
  Entrada.UsarTotalFactura := True;
  Entrada.TotalFactura := FImporteAntesDescuento;
  Entrada.PorcentajeDescuento := FPorcentajeDescuentoGlobal;
  Entrada.DescuentoPorImporte := FDescuentoPorImporte;
  Entrada.ImporteDescuentoFijado := FImporteDescuentoFijado;
  Entrada.ImporteYaCobrado := FImporteYaCobrado;
  AplicarResultadoTotales(TCalculadorFaseCobro.CalcularTotales(Entrada));

  if Assigned(FOnRecalculado) then
    FOnRecalculado(Self);
end;

procedure TDatosFaseCobro.Recalcular;
begin
  CalcularTotales;
end;

function TDatosFaseCobro.ValidarDeuda: TResultadoValidacion;
begin
  Result := TResultadoValidacion.OK;
  if FImporteDejarCuenta > 0 then
  begin
    if not FHayCliente then
      Result := TResultadoValidacion.Error(
        SErrorDejarImporteCuentaSinCliente)
    else if not PuedeDejarEnCuenta then
      Result := TResultadoValidacion.Error(
        SErrorClienteNoPermiteImporteCuenta)
    else if FEsClienteVarios then
      Result := ValidarApartado(FImporteDejarCuenta);
  end;
end;

function TDatosFaseCobro.ValidarApartado(
  AImporteCuenta: Currency): TResultadoValidacion;
begin
  // El apartado no genera deuda: sin entrega a cuenta no habría ticket
  // con el que completar la venta desde F4.
  if AImporteCuenta >= FImporteTotalPagar then
    Result := TResultadoValidacion.Error(SErrorApartadoSinEntregaCuenta)
  else if FContactoApartado.Nombre = '' then
    Result := TResultadoValidacion.Error(SErrorApartadoSinContacto)
  else
    Result := TResultadoValidacion.OK;
end;

function TDatosFaseCobro.ValidarVale: TResultadoValidacion;
var
  Bookmark: TBookmark;
  CodigoVale: string;
begin
  Result := TResultadoValidacion.OK;
  if Assigned(FMemTablePagos) and
     FMemTablePagos.Active and
     not FMemTablePagos.IsEmpty then
  begin
    FMemTablePagos.DisableControls;
    Bookmark := FMemTablePagos.GetBookmark;
    try
      FMemTablePagos.First;
      while not FMemTablePagos.Eof do
      begin
        if (FMemTablePagos.FieldByName(
             'CODIGO_FP_CFP').AsString = 'VALE') and
           (FMemTablePagos.FieldByName(
             'IMPORTE_ENTREGADO').AsCurrency <> 0) then
        begin
          CodigoVale := FMemTablePagos.FieldByName('REFERENCIA').AsString;
          if not FRepositorio.ExisteValePendiente(CodigoVale) then
          begin
            Result := TResultadoValidacion.Error(
              Format(SErrorValeNoDisponible, [CodigoVale]));
            Break;
          end;
        end;
        FMemTablePagos.Next;
      end;
    finally
      if FMemTablePagos.BookmarkValid(Bookmark) then
        FMemTablePagos.GotoBookmark(Bookmark);
      FMemTablePagos.FreeBookmark(Bookmark);
      FMemTablePagos.EnableControls;
    end;
  end;
end;

// Efectivo en euros que se queda la caja: lo entregado en las formas de pago
// de efectivo (EFE, o las que dan cambio y abren el cajón) menos el cambio
// devuelto. Las divisas, las criptomonedas y los vales no cuentan.
function TDatosFaseCobro.ImporteEfectivoEuros: Currency;
var
  oMarcador: TBookmark;
  bEfectivo: Boolean;
begin
  Result := 0;
  if Assigned(FMemTablePagos) and FMemTablePagos.Active and
     not FMemTablePagos.IsEmpty then
  begin
    FMemTablePagos.DisableControls;
    oMarcador := FMemTablePagos.GetBookmark;
    try
      FMemTablePagos.First;
      while not FMemTablePagos.Eof do
      begin
        bEfectivo :=
          (ObtenerStringSafe('ESDIVISA_FORMA_PAGO_CFP', 'N') <> 'S') and
          (ObtenerStringSafe('ESCRIPTO_FORMA_PAGO_CFP', 'N') <> 'S') and
          (ObtenerStringSafe('CODIGO_FP_CFP', '') <> 'VALE') and
          (SameText(ObtenerStringSafe('CODIGO_FP_CFP', ''), 'EFE') or
           ((ObtenerStringSafe('ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP', 'N') =
             'S') and
            (ObtenerStringSafe('ESABRE_CAJON_FORMA_PAGO_CFP', 'N') = 'S')));
        if bEfectivo then
          Result := Result + ObtenerCurrencySafe('IMPORTE_ENTREGADO', 0);
        FMemTablePagos.Next;
      end;
    finally
      if FMemTablePagos.BookmarkValid(oMarcador) then
        FMemTablePagos.GotoBookmark(oMarcador);
      FMemTablePagos.FreeBookmark(oMarcador);
      FMemTablePagos.EnableControls;
    end;
  end;
  // El cambio sólo sale de formas de pago que lo devuelven (el efectivo).
  if Result > 0 then
    Result := Result - Min(FImporteCambio, Result);
end;

function TDatosFaseCobro.AlgunPagoAbreCajon: Boolean;
var
  oMarcador: TBookmark;
begin
  Result := False;
  if Assigned(FMemTablePagos) and FMemTablePagos.Active and
     not FMemTablePagos.IsEmpty then
  begin
    FMemTablePagos.DisableControls;
    oMarcador := FMemTablePagos.GetBookmark;
    try
      FMemTablePagos.First;
      while (not Result) and (not FMemTablePagos.Eof) do
      begin
        Result :=
          (ObtenerCurrencySafe('IMPORTE_ENTREGADO', 0) <> 0) and
          (SameText(ObtenerStringSafe('CODIGO_FP_CFP', ''), 'EFE') or
           (ObtenerStringSafe('ESABRE_CAJON_FORMA_PAGO_CFP', 'N') = 'S'));
        FMemTablePagos.Next;
      end;
    finally
      if FMemTablePagos.BookmarkValid(oMarcador) then
        FMemTablePagos.GotoBookmark(oMarcador);
      FMemTablePagos.FreeBookmark(oMarcador);
      FMemTablePagos.EnableControls;
    end;
  end;
end;

function TDatosFaseCobro.ValidarLimiteEfectivo: TResultadoValidacion;
var
  dEfectivo: Currency;
begin
  Result := TResultadoValidacion.OK;
  dEfectivo := ImporteEfectivoEuros;
  if dEfectivo >= LIMITE_PAGO_EFECTIVO_EUROS then
    Result := TResultadoValidacion.Error(
      Format(SErrorLimitePagoEfectivo,
             [dEfectivo, Currency(LIMITE_PAGO_EFECTIVO_EUROS),
              Currency(LIMITE_PAGO_EFECTIVO_EUROS),
              dEfectivo - LIMITE_PAGO_EFECTIVO_EUROS + 0.01]));
end;

function TDatosFaseCobro.ValidarParaCobro: TResultadoValidacion;
var
  TotalCobrado: Currency;
begin
  CalcularTotales;
  if EsDevolucionEconomica then
  begin
    if FImportePendiente > 0.01 then
      Result := TResultadoValidacion.Error(
        Format(SErrorDevolucionIncompleta,
               [FImportePendiente]))
    else if (FImporteDevueltoDeMas > 0.01) and
            (FImporteValeObligatorio > 0) then
      Result := TResultadoValidacion.Error(
        Format(SErrorDevolucionExcesivaVale,
               [FImporteDevueltoDeMas, FImporteValeEmitido]))
    else if FImporteDevueltoDeMas > 0.01 then
      Result := TResultadoValidacion.Error(
        Format(SErrorDevolucionExcesiva,
               [FImporteDevueltoDeMas]))
    else
      Result := TResultadoValidacion.OK;
  end
  else
  begin
    Result := ValidarDeuda;
    if Result.Valido then
      Result := ValidarVale;
    if Result.Valido then
      Result := ValidarLimiteEfectivo;
    if Result.Valido then
    begin
      TotalCobrado := FImporteEntregado + FImporteDejarCuenta;
      if (TotalCobrado = 0) and (FImporteTotalPagar > 0) then
        Result := TResultadoValidacion.Error(SErrorPagoNoIndicado)
      else if (FImportePendiente > 0.01) and
              (FImporteDejarCuenta = 0) then
        Result := TResultadoValidacion.Advertencia(
          Format(SAdvertenciaCobroIncompleto, [FImportePendiente]))
      else
        Result := TResultadoValidacion.OK;
    end;
  end;
end;

function TDatosFaseCobro.ObtenerDatosPagosParaGrabar: TArray<TFormaPagoItem>;
var
  Lista: TList<TFormaPagoItem>;
  Item: TFormaPagoItem;
  RestanteCambio: Currency;
  EsDevuelveCambio: Boolean;
begin
  CalcularTotales;

  RestanteCambio := FImporteCambio;
  Lista := TList<TFormaPagoItem>.Create;
  try
    if Assigned(FMemTablePagos) and FMemTablePagos.Active then
    begin
      FMemTablePagos.DisableControls;
      try
        FMemTablePagos.First;
        while not FMemTablePagos.Eof do
        begin
          // Solo procesar líneas con importe > 0
          if FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency > 0 then
          begin
            Item := Default(TFormaPagoItem);
            Item.NumeroLinea := Lista.Count + 1;
            Item.CodigoFormaPago :=
              FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString;
            Item.DescripcionFormaPago :=
              FMemTablePagos.FieldByName('DESCRIPCION_FORMA_PAGO_CFP').AsString;
            Item.CodigoDivisa :=
              FMemTablePagos.FieldByName('CODIGO_DIVISA').AsString;
            Item.RedBlockchain :=
              FMemTablePagos.FieldByName('RED_BLOCKCHAIN').AsString;
            Item.FactorCambio :=
              FMemTablePagos.FieldByName('FACTOR_CAMBIO').AsFloat;
            Item.ImporteDivisa :=
              FMemTablePagos.FieldByName('IMPORTE_DIVISA').AsCurrency;
            Item.ImporteEntregado :=
              FMemTablePagos.FieldByName('IMPORTE_ENTREGADO').AsCurrency;
            Item.Referencia :=
              FMemTablePagos.FieldByName('REFERENCIA').AsString;
            Item.Observaciones := '';
            Item.ImporteCambio := 0;
            EsDevuelveCambio := FMemTablePagos.FieldByName(
                                    'ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP')
                                    .AsString = 'S';
            if (RestanteCambio > 0) and EsDevuelveCambio then
            begin
              Item.ImporteCambio := RestanteCambio;
              RestanteCambio := 0;
            end;
            Lista.Add(Item);
          end;
          FMemTablePagos.Next;
        end;
      finally
        FMemTablePagos.EnableControls;
      end;
    end;
    if FImporteDejarCuenta > 0 then
    begin
      Item := Default(TFormaPagoItem);
      Item.NumeroLinea := Lista.Count + 1;
      Item.CodigoFormaPago := 'DEUDA';
      Item.DescripcionFormaPago := 'Dejar en cuenta';
      Item.CodigoDivisa := 'EUR';
      Item.RedBlockchain := '';
      Item.FactorCambio := 1;
      Item.ImporteDivisa := 0;
      Item.ImporteEntregado := FImporteDejarCuenta;
      Item.ImporteCambio := 0;
      Item.Referencia := FDatosCliente.CodigoCliente;
      Item.Observaciones := 'Pendiente cliente: ' + FDatosCliente.NombreCliente;
      Lista.Add(Item);
    end;
    Result := Lista.ToArray;
  finally
    FreeAndNil(Lista);
  end;
end;

function TDatosFaseCobro.ObtenerFormaPagoInfo(
                                         const ACodigo: string): TFormaPagoInfo;
begin
  Result := Default(TFormaPagoInfo);
  if Assigned(FMemTablePagos) and (FMemTablePagos.Active) and
     (FMemTablePagos.FieldByName('CODIGO_FP_CFP').AsString = ACodigo) then
  begin
    Result.Codigo := ACodigo;
    Result.Descripcion :=
                      FMemTablePagos.FieldByName(
                        'DESCRIPCION_FORMA_PAGO_CFP').AsString;
    if FMemTablePagos.FindField('ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP') <> nil then
       Result.DevuelveCambio :=
        (FMemTablePagos.FieldByName(
          'ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP').AsString = 'S')
    else
       Result.DevuelveCambio := True;
    if FMemTablePagos.FindField('ESREQ_REFERENCIA_FORMA_PAGO_CFP') <> nil then
       Result.RequiereReferencia :=
         (FMemTablePagos.FieldByName(
           'ESREQ_REFERENCIA_FORMA_PAGO_CFP').AsString = 'S')
    else
       Result.RequiereReferencia := False;
  end
  else
  begin
    Result.Codigo := ACodigo;
    Result.Descripcion := ACodigo;
    Result.DevuelveCambio := True;
    Result.RequiereReferencia := False;
  end;
end;

end.
