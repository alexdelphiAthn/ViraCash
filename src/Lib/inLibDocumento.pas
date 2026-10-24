{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDocumento                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Configuración y estrategias de la familia común de documentos.            }
{******************************************************************************}
unit inLibDocumento;

interface

uses
  inLibDocumentoIntf;

function CrearConfiguracionDocumento(
  ATipoDocumento: TTipoDocumento;
  ASentido: TSentidoDocumento
): TConfiguracionDocumento;
function CrearEstrategiaDocumento(
  const AConfiguracion: TConfiguracionDocumento
): IEstrategiaDocumento;
procedure ValidarConfiguracionDocumento(
  const AConfiguracion: TConfiguracionDocumento);
// Tipo de movimiento de una línea: una cantidad negativa invierte el del
// documento (devolución de cliente en venta, al proveedor en compra).
function TipoMovimientoStockLinea(
  const ATipoMovimiento: string;
  ACantidad: Double): string;

implementation

uses
  inLibRedondeo,
  System.Math, System.SysUtils;

type
  TEstrategiaDocumento = class(TInterfacedObject, IEstrategiaDocumento)
  private
    FConfiguracion: TConfiguracionDocumento;
    function CalcularDivisorImpuestos(
      const AEntrada: TEntradaCalculoDocumento): Double;
  public
    constructor Create(
      const AConfiguracion: TConfiguracionDocumento);
    function CalcularLinea(
      const AEntrada: TEntradaCalculoDocumento
    ): TResultadoCalculoDocumento;
    function CantidadMovimientoStock(
      ACantidad: Currency
    ): Currency;
    function TipoDocumentoMovimientoStock: string;
    function TipoMovimientoStock: string;
    function FormatearNumero(AContador: Int64): string;
    function DebeGenerarAsiento: Boolean;
    function DebeEmitirVerifactu: Boolean;
  end;

procedure ConfigurarIdentidad(
  var AConfiguracion: TConfiguracionDocumento;
  const ANombre, ATablaCabecera, ATablaLineas,
  APrefijoCabecera, APrefijoLineas, ATipoContador: string);
begin
  AConfiguracion.NombreSingular := ANombre;
  AConfiguracion.TablaCabecera := ATablaCabecera;
  AConfiguracion.TablaLineas := ATablaLineas;
  AConfiguracion.PrefijoCabecera := APrefijoCabecera;
  AConfiguracion.PrefijoLineas := APrefijoLineas;
  AConfiguracion.TipoContador := ATipoContador;
  AConfiguracion.CampoSerieCabecera :=
    'SERIE_' + APrefijoCabecera;
  AConfiguracion.CampoNumeroCabecera :=
    'NUMERO_' + APrefijoCabecera;
  AConfiguracion.CampoSerieLinea :=
    'SERIE_' + APrefijoCabecera + '_' + APrefijoLineas;
  AConfiguracion.CampoNumeroLinea :=
    'NUMERO_' + APrefijoCabecera + '_' + APrefijoLineas;
  AConfiguracion.CampoArticuloLinea :=
    'CODIGO_ART_' + APrefijoLineas;
  AConfiguracion.CampoProductoLinea :=
    'CODIGO_UNIDAD_' + APrefijoLineas;
  AConfiguracion.CampoUnidadLinea :=
    AConfiguracion.CampoProductoLinea;
end;

procedure ConfigurarAlbaran(
  var AConfiguracion: TConfiguracionDocumento);
begin
  if AConfiguracion.Sentido = sdVenta then
  begin
    ConfigurarIdentidad(
      AConfiguracion,
      'albarán de venta',
      'fza_albaranes',
      'fza_albaranes_lineas',
      'ALB',
      'ALBLIN',
      'AV');
    AConfiguracion.SignoStock := -1;
    AConfiguracion.TipoDocumentoMovimientoStock := 'AV';
  end
  else
  begin
    ConfigurarIdentidad(
      AConfiguracion,
      'albarán de compra',
      'fza_albaranes_compra',
      'fza_albaranes_compra_lineas',
      'ALBC',
      'ALBCLIN',
      'AB');
    AConfiguracion.SignoStock := 1;
    AConfiguracion.TipoDocumentoMovimientoStock := 'AC';
  end;
  AConfiguracion.MueveStock := True;
end;

procedure ConfigurarPedido(
  var AConfiguracion: TConfiguracionDocumento);
begin
  if AConfiguracion.Sentido = sdVenta then
    ConfigurarIdentidad(
      AConfiguracion,
      'pedido de venta',
      'fza_pedidos',
      'fza_pedidos_lineas',
      'PED',
      'PEDLIN',
      'PE')
  else
    ConfigurarIdentidad(
      AConfiguracion,
      'pedido de compra',
      'fza_pedidos_compra',
      'fza_pedidos_compra_lineas',
      'PEDC',
      'PEDCLIN',
      'PC');
  AConfiguracion.SignoStock := 0;
  AConfiguracion.MueveStock := False;
end;

procedure ConfigurarPresupuesto(
  var AConfiguracion: TConfiguracionDocumento);
begin
  if AConfiguracion.Sentido <> sdVenta then
    raise EArgumentException.Create('El presupuesto pertenece a ventas.');
  ConfigurarIdentidad(AConfiguracion, 'presupuesto',
    'fza_presupuestos', 'fza_presupuestos_lineas', 'PRE', 'PRELIN', 'PV');
end;

procedure ConfigurarFactura(
  var AConfiguracion: TConfiguracionDocumento);
begin
  if AConfiguracion.Sentido = sdVenta then
  begin
    ConfigurarIdentidad(
      AConfiguracion,
      'factura de venta',
      'fza_facturas',
      'fza_facturas_lineas',
      'FAC',
      'FACLIN',
      'FC');
    AConfiguracion.SignoStock := -1;
    AConfiguracion.TipoDocumentoMovimientoStock := 'FC';
    AConfiguracion.EmiteVerifactu := True;
    AConfiguracion.FiltraCaja := True;
  end
  else
  begin
    ConfigurarIdentidad(
      AConfiguracion,
      'factura de compra',
      'fza_facturas_compra',
      'fza_facturas_compra_lineas',
      'FACC',
      'FACCLIN',
      'FP');
    AConfiguracion.SignoStock := 0;
  end;
  AConfiguracion.GeneraAsiento := True;
  AConfiguracion.MueveStock :=
    AConfiguracion.Sentido = sdVenta;
end;

procedure ConfigurarDevolucion(
  var AConfiguracion: TConfiguracionDocumento);
begin
  if AConfiguracion.Sentido = sdVenta then
    raise EArgumentException.Create(
      'La devolución de venta se representa mediante factura rectificativa.');
  ConfigurarIdentidad(
    AConfiguracion,
    'devolución de compra',
    'fza_devoluciones_compra',
    'fza_devoluciones_compra_lineas',
    'DEVC',
    'DEVCLIN',
    'DC');
  AConfiguracion.SignoStock := -1;
  AConfiguracion.TipoDocumentoMovimientoStock := 'DC';
  AConfiguracion.MueveStock := True;
end;

function TipoMovimientoStockLinea(
  const ATipoMovimiento: string;
  ACantidad: Double): string;
begin
  Result := ATipoMovimiento;
  if (ACantidad < 0) and (ATipoMovimiento = 'E') then
    Result := 'S'
  else if (ACantidad < 0) and (ATipoMovimiento = 'S') then
    Result := 'E';
end;

function CrearConfiguracionDocumento(
  ATipoDocumento: TTipoDocumento;
  ASentido: TSentidoDocumento
): TConfiguracionDocumento;
begin
  Result := Default(TConfiguracionDocumento);
  Result.TipoDocumento := ATipoDocumento;
  Result.Sentido := ASentido;
  Result.UsaSerie := True;
  case ATipoDocumento of
    tdAlbaran:
      ConfigurarAlbaran(Result);
    tdPedido:
      ConfigurarPedido(Result);
    tdFactura:
      ConfigurarFactura(Result);
    tdDevolucion:
      ConfigurarDevolucion(Result);
    tdPresupuesto:
      ConfigurarPresupuesto(Result);
  end;
  Result.DocumentoConArticulo := Result.NombreSingular;
  Result.CampoPivoteCabecera :=
    'ESPIVOTE_HORIZONTAL_' + Result.PrefijoCabecera;
  Result.CampoPivoteLinea :=
    'ID_AC_PIVOT_' + Result.PrefijoLineas;
  ValidarConfiguracionDocumento(Result);
end;

function CrearEstrategiaDocumento(
  const AConfiguracion: TConfiguracionDocumento
): IEstrategiaDocumento;
begin
  ValidarConfiguracionDocumento(AConfiguracion);
  Result := TEstrategiaDocumento.Create(AConfiguracion);
end;

procedure ValidarConfiguracionDocumento(
  const AConfiguracion: TConfiguracionDocumento);
begin
  if Trim(AConfiguracion.TablaCabecera) = '' then
    raise EArgumentException.Create('TablaCabecera');
  if Trim(AConfiguracion.TablaLineas) = '' then
    raise EArgumentException.Create('TablaLineas');
  if Trim(AConfiguracion.PrefijoCabecera) = '' then
    raise EArgumentException.Create('PrefijoCabecera');
  if Trim(AConfiguracion.PrefijoLineas) = '' then
    raise EArgumentException.Create('PrefijoLineas');
  if Trim(AConfiguracion.TipoContador) = '' then
    raise EArgumentException.Create('TipoContador');
  if AConfiguracion.MueveStock and
     (Abs(AConfiguracion.SignoStock) <> 1) then
    raise EArgumentException.Create('SignoStock');
  if AConfiguracion.MueveStock and
     (Trim(AConfiguracion.TipoDocumentoMovimientoStock) = '') then
    raise EArgumentException.Create('TipoDocumentoMovimientoStock');
  if (not AConfiguracion.MueveStock) and
     (AConfiguracion.SignoStock <> 0) then
    raise EArgumentException.Create('SignoStock');
end;

constructor TEstrategiaDocumento.Create(
  const AConfiguracion: TConfiguracionDocumento);
begin
  inherited Create;
  FConfiguracion := AConfiguracion;
end;

function TEstrategiaDocumento.CalcularDivisorImpuestos(
  const AEntrada: TEntradaCalculoDocumento): Double;
begin
  Result := 1;
  if AEntrada.PrecioIncluyeImpuestos then
    Result := 1 +
      (AEntrada.PorcentajeImpuesto / 100) +
      (AEntrada.PorcentajeRecargo / 100);
end;

function TEstrategiaDocumento.CalcularLinea(
  const AEntrada: TEntradaCalculoDocumento
): TResultadoCalculoDocumento;
var
  dDivisor: Double;
begin
  Result := Default(TResultadoCalculoDocumento);
  dDivisor := CalcularDivisorImpuestos(AEntrada);
  if SameValue(dDivisor, 0) then
    dDivisor := 1;
  Result.PrecioNeto := RedondearDecimales(
    (AEntrada.Precio / dDivisor) *
    (1 - (AEntrada.PorcentajeDescuento / 100)),
    4);
  Result.BaseImponible := RedondearDecimales(
    AEntrada.Cantidad * Result.PrecioNeto,
    2);
  Result.CuotaImpuesto := RedondearDecimales(
    Result.BaseImponible *
    (AEntrada.PorcentajeImpuesto / 100),
    2);
  Result.CuotaRecargo := RedondearDecimales(
    Result.BaseImponible *
    (AEntrada.PorcentajeRecargo / 100),
    2);
  Result.Total := Result.BaseImponible +
    Result.CuotaImpuesto + Result.CuotaRecargo;
end;

function TEstrategiaDocumento.CantidadMovimientoStock(
  ACantidad: Currency): Currency;
begin
  Result := 0;
  if FConfiguracion.MueveStock then
    Result := ACantidad * FConfiguracion.SignoStock;
end;

function TEstrategiaDocumento.TipoDocumentoMovimientoStock: string;
begin
  Result := FConfiguracion.TipoDocumentoMovimientoStock;
end;

function TEstrategiaDocumento.TipoMovimientoStock: string;
begin
  Result := '';
  if FConfiguracion.MueveStock then
  begin
    if FConfiguracion.SignoStock > 0 then
      Result := 'E'
    else
      Result := 'S';
  end;
end;

function TEstrategiaDocumento.FormatearNumero(
  AContador: Int64): string;
begin
  if AContador < 0 then
    raise EArgumentOutOfRangeException.Create('AContador');
  Result := IntToStr(AContador);
end;

function TEstrategiaDocumento.DebeGenerarAsiento: Boolean;
begin
  Result := FConfiguracion.GeneraAsiento;
end;

function TEstrategiaDocumento.DebeEmitirVerifactu: Boolean;
begin
  Result := FConfiguracion.EmiteVerifactu;
end;

end.
