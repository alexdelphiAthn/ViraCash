{******************************************************************************}
{                                                                              }
{  Módulo:       inLibReparaciones                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Dominio de las reparaciones dentro de la gestión de garantías:            }
{    modalidad (garantía, pago, cortesía), objeto con o sin serie, tipos de    }
{    servicio, presupuesto, líneas de mano de obra y material con su           }
{    ejecutor (operario o empresa externa), fases, cobro al cliente y          }
{    liquidaciones (pago a externos y cargo al fabricante). Sin VCL ni SQL.    }
{******************************************************************************}
unit inLibReparaciones;

interface

const
  // Interruptor de la pantalla «Reparaciones y garantías» (perfiles).
  PARAMETRO_REPARACIONES = 'appReparaciones';

  // MODALIDAD_GAR y MODALIDAD_GARTIP.
  MODALIDAD_REPARACION_GARANTIA = 'GARANTIA';
  MODALIDAD_REPARACION_PAGO = 'PAGO';
  MODALIDAD_REPARACION_CORTESIA = 'CORTESIA';

  // ORIGEN_OBJETO_GAR.
  ORIGEN_REPARACION_VENDIDO = 'VENDIDO';
  ORIGEN_REPARACION_CLIENTE = 'CLIENTE';
  ORIGEN_REPARACION_TIENDA = 'TIENDA';

  // MODO_COBRO_GAR y MODO_COBRO_GARTIP.
  COBRO_REPARACION_COMPRA = 'COMPRA';
  COBRO_REPARACION_RECOGIDA = 'RECOGIDA';
  COBRO_REPARACION_GRATIS = 'GRATIS';

  // ESTADO_PRESUPUESTO_GAR.
  PRESUPUESTO_PENDIENTE = 'PENDIENTE';
  PRESUPUESTO_ACEPTADO = 'ACEPTADO';
  PRESUPUESTO_RECHAZADO = 'RECHAZADO';

  // TIPO_LINEA_GARLIN y TIPO_EJECUTOR_GARLIN.
  LINEA_REPARACION_MANO_OBRA = 'MANO_OBRA';
  LINEA_REPARACION_MATERIAL = 'MATERIAL';
  EJECUTOR_REPARACION_OPERARIO = 'OPERARIO';
  EJECUTOR_REPARACION_EXTERNO = 'EXTERNO';

  // SENTIDO_GARLIQ y MODO_LIQUIDACION_SERVICIOS_PRV (NULL = periódica).
  LIQUIDACION_REPARACION_PAGO = 'PAGO';
  LIQUIDACION_REPARACION_CARGO = 'CARGO';
  MODO_LIQUIDACION_PERIODICA = 'PERIODICA';
  MODO_LIQUIDACION_LINEA = 'LINEA';

  // Estado anulado del expediente (ESTADO_GAR); los demás son los de
  // inLibGarantias.
  ESTADO_REPARACION_ANULADA = 'ANULADA';

  // Fase calculada de una reparación.
  FASE_REPARACION_RECIBIDO = 'RECIBIDO';
  FASE_REPARACION_PRESUPUESTO = 'PRESUPUESTO';
  FASE_REPARACION_RECHAZADO = 'RECHAZADO';
  FASE_REPARACION_EN_REPARACION = 'EN_REPARACION';
  FASE_REPARACION_REPARADO = 'REPARADO';
  FASE_REPARACION_ENTREGADO = 'ENTREGADO';
  FASE_REPARACION_ANULADO = 'ANULADO';

type
  TTipoServicio = record
    Codigo: string;
    Categoria: string;
    ClaseServicio: string;
    Descripcion: string;
    Modalidad: string;
    EsPresupuesto: Boolean;
    PrecioCliente: Currency;
    PrecioCoste: Currency;
    Cantidad: Double;
    ModoCobro: string;
    DiasPlazo: Integer;
    Articulo: string;
    TipoEjecutor: string;
    Empleado: string;
    Proveedor: string;
  end;

  TDatosTrabajoReparacion = record
    Clase: string;
    AlturaMedida: Double;
    LargoFinal: Double;
    Acabado: string;
    Direccion: string;
    Cita: TDateTime;
  end;

  TPrendaVentaReparacion = record
    LineaServicio: string;
    UnidadServicio: Integer;
    LineaPrenda: string;
    UnidadPrenda: Integer;
    Descripcion: string;
    Trabajo: TDatosTrabajoReparacion;
  end;

  TVentaServiciosReparacion = record
    Serie, Numero, Empresa, Almacen, Usuario: string;
    Cliente, NombreCliente, Telefono, Email: string;
    Fecha: TDateTime;
    Cobrada: Boolean;
    Prendas: TArray<TPrendaVentaReparacion>;
  end;

  // Línea de servicio de la venta: del ticket o del depósito que se deja
  // en préstamo (IdDeposito, FZ-ISSUE-778). Total con impuestos.
  TLineaServicioVenta = record
    Linea, Articulo, Descripcion, IdDeposito: string;
    Cantidad: Double;
    Total, CosteUltimaCompra: Currency;
  end;
  TLineasServicioVenta = TArray<TLineaServicioVenta>;

  TArticuloServicioReparacion = record
    Tipo: TTipoServicio;
    Tarifa: string;
    Empresa: string;
    Usuario: string;
  end;

  // Operario (fza_empleados) o empresa externa (fza_proveedores).
  TEjecutorServicio = record
    Tipo: string;
    Codigo: string;
    Nombre: string;
    ModoLiquidacion: string;
  end;

  // Lo que recoge el alta de una reparación; la primera línea sale del tipo.
  TReparacionNueva = record
    Almacen: string;
    Fecha: TDateTime;
    Modalidad: string;
    Tipo: string;
    Categoria: string;
    Cliente: string;
    NombreCliente: string;
    TelefonoCliente: string;
    Origen: string;
    Sku: string;
    Serie: string;
    DescripcionObjeto: string;
    ReferenciaObjeto: string;
    SerieVenta: string;
    NumeroVenta: string;
    Trabajo: string;
    Detalles: string;
    Observaciones: string;
    Fabricante: string;
    FechaPrevista: TDateTime;
    EsPresupuesto: Boolean;
    ModoCobro: string;
    EsCobrado: Boolean;
    SerieCobro: string;
    NumeroCobro: string;
    TipoEjecutor: string;
    Empleado: string;
    Proveedor: string;
    Cantidad: Double;
    PrecioCliente: Currency;
    PrecioCoste: Currency;
    Usuario: string;
  end;

  TLineaReparacion = record
    Id: Int64;
    Reparacion: Int64;
    TipoLinea: string;
    Tipo: string;
    Descripcion: string;
    TipoEjecutor: string;
    Empleado: string;
    Proveedor: string;
    Sku: string;
    Cantidad: Double;
    PrecioCliente: Currency;
    PrecioCoste: Currency;
    Usuario: string;
  end;

  // Lo necesario para calcular la fase del expediente.
  TSituacionReparacion = record
    Estado: string;
    Entregado: Boolean;
    EsPresupuesto: Boolean;
    EstadoPresupuesto: string;
    LineasManoObra: Integer;
    LineasIniciadas: Integer;
    LineasTerminadas: Integer;
  end;

  TLiquidacionReparaciones = record
    Id: Int64;
    Sentido: string;
    Proveedor: string;
    Hasta: TDateTime;
    Lineas: Integer;
    Total: Currency;
  end;

// Reparación nueva con los valores del tipo: categoría, modalidad,
// trabajo, presupuesto, cobro, ejecutor, cantidad, precios y fecha prevista.
function AplicarTipoServicio(const AReparacion: TReparacionNueva;
  const ATipo: TTipoServicio;
  AConservarModalidad: Boolean = False): TReparacionNueva;
// En garantía y cortesía el cliente no paga: cobro gratis y precio 0.
function NormalizarCobroReparacion(
  const AReparacion: TReparacionNueva): TReparacionNueva;
// '' si se puede dar de alta; si no, el motivo.
function ValidarReparacionNueva(const AReparacion: TReparacionNueva): string;
function ValidarLineaReparacion(const ALinea: TLineaReparacion): string;
function FaseReparacion(const ASituacion: TSituacionReparacion): string;
// Sin presupuesto, o con él aceptado, se puede empezar a trabajar.
function PuedeEmpezarReparacion(AEsPresupuesto: Boolean;
  const AEstadoPresupuesto: string): Boolean;
function PuedeEntregarReparacion(const AFase: string): Boolean;
function PuedeAnularReparacion(const AFase: string;
  ATieneLiquidaciones: Boolean): Boolean;
// La línea de un externo se liquida al terminarla si cobra por línea.
function LiquidaAlTerminarLinea(const ATipoEjecutor,
  AModoLiquidacion: string): Boolean;
// Pago al recoger, sin cobrar y con algo que cobrar: un presupuesto
// rechazado sin cargo se entrega sin ticket.
function FaltaCobrarReparacion(const AModalidad, AModoCobro: string;
  AEsCobrado: Boolean; AImporte: Currency): Boolean;
function EsModalidadReparacion(const AValor: string): Boolean;
function EsModoCobroReparacion(const AValor: string): Boolean;
function EsOrigenReparacion(const AValor: string): Boolean;
function TextoModalidadReparacion(const AValor: string): string;
function TextoFaseReparacion(const AValor: string): string;
function TextoModoCobroReparacion(const AValor: string): string;
function TextoOrigenReparacion(const AValor: string): string;
function TextoEjecutorReparacion(const AValor: string): string;
function TextoModoLiquidacion(const AValor: string): string;

implementation

uses
  System.SysUtils, System.Math, inLibGarantias, inLibMsgReparaciones;

function AplicarTipoServicio(const AReparacion: TReparacionNueva;
  const ATipo: TTipoServicio;
  AConservarModalidad: Boolean): TReparacionNueva;
begin
  Result := AReparacion;
  Result.Tipo := ATipo.Codigo;
  Result.Categoria := ATipo.Categoria;
  if not AConservarModalidad then
    Result.Modalidad := ATipo.Modalidad;
  if Trim(Result.Trabajo) = '' then
    Result.Trabajo := ATipo.Descripcion;
  Result.EsPresupuesto := ATipo.EsPresupuesto;
  Result.ModoCobro := ATipo.ModoCobro;
  Result.TipoEjecutor := ATipo.TipoEjecutor;
  Result.Empleado := ATipo.Empleado;
  Result.Proveedor := ATipo.Proveedor;
  Result.Cantidad := ATipo.Cantidad;
  Result.PrecioCliente := ATipo.PrecioCliente;
  Result.PrecioCoste := ATipo.PrecioCoste;
  if Result.Fecha > 0 then
    Result.FechaPrevista := Result.Fecha + ATipo.DiasPlazo;
  Result := NormalizarCobroReparacion(Result);
end;

function NormalizarCobroReparacion(
  const AReparacion: TReparacionNueva): TReparacionNueva;
begin
  Result := AReparacion;
  if Result.Modalidad <> MODALIDAD_REPARACION_PAGO then
  begin
    Result.ModoCobro := COBRO_REPARACION_GRATIS;
    Result.PrecioCliente := 0;
    Result.EsPresupuesto := False;
  end;
end;

function EsModalidadReparacion(const AValor: string): Boolean;
begin
  Result := (AValor = MODALIDAD_REPARACION_GARANTIA) or
    (AValor = MODALIDAD_REPARACION_PAGO) or
    (AValor = MODALIDAD_REPARACION_CORTESIA);
end;

function EsModoCobroReparacion(const AValor: string): Boolean;
begin
  Result := (AValor = COBRO_REPARACION_COMPRA) or
    (AValor = COBRO_REPARACION_RECOGIDA) or
    (AValor = COBRO_REPARACION_GRATIS);
end;

function EsOrigenReparacion(const AValor: string): Boolean;
begin
  Result := (AValor = ORIGEN_REPARACION_VENDIDO) or
    (AValor = ORIGEN_REPARACION_CLIENTE) or
    (AValor = ORIGEN_REPARACION_TIENDA);
end;

function ValidarEjecutor(const ATipoEjecutor, AEmpleado,
  AProveedor: string): string;
begin
  Result := '';
  if (ATipoEjecutor = EJECUTOR_REPARACION_OPERARIO) and
     (Trim(AProveedor) <> '') then
    Result := SErrorEjecutorReparacion
  else if (ATipoEjecutor = EJECUTOR_REPARACION_EXTERNO) and
          (Trim(AEmpleado) <> '') then
    Result := SErrorEjecutorReparacion
  else if (ATipoEjecutor <> '') and
          (ATipoEjecutor <> EJECUTOR_REPARACION_OPERARIO) and
          (ATipoEjecutor <> EJECUTOR_REPARACION_EXTERNO) then
    Result := SErrorEjecutorReparacion;
end;

function ValidarObjeto(const AReparacion: TReparacionNueva): string;
begin
  Result := '';
  if not EsOrigenReparacion(AReparacion.Origen) then
    Result := SErrorOrigenReparacion
  else if (AReparacion.Origen = ORIGEN_REPARACION_TIENDA) and
          (Trim(AReparacion.Sku) = '') then
    Result := SErrorSkuReparacionTienda
  else if (Trim(AReparacion.Sku) = '') and
          (Trim(AReparacion.Serie) = '') and
          (Trim(AReparacion.DescripcionObjeto) = '') then
    Result := SErrorObjetoReparacion;
end;

function ValidarCobro(const AReparacion: TReparacionNueva): string;
begin
  Result := '';
  if not EsModalidadReparacion(AReparacion.Modalidad) then
    Result := SErrorModalidadReparacion
  else if not EsModoCobroReparacion(AReparacion.ModoCobro) then
    Result := SErrorModoCobroReparacion
  else if (AReparacion.PrecioCliente < 0) or (AReparacion.PrecioCoste < 0)
          or (AReparacion.Cantidad < 0) then
    Result := SErrorImporteReparacion
  else if (AReparacion.Modalidad <> MODALIDAD_REPARACION_PAGO) and
          ((AReparacion.ModoCobro <> COBRO_REPARACION_GRATIS) or
           (AReparacion.PrecioCliente <> 0)) then
    Result := SErrorCobroSinPagoReparacion;
end;

function ValidarReparacionNueva(const AReparacion: TReparacionNueva): string;
begin
  Result := '';
  if Trim(AReparacion.Almacen) = '' then
    Result := SErrorTiendaReparacion
  else if Trim(AReparacion.Trabajo) = '' then
    Result := SErrorTrabajoReparacion
  else if (Trim(AReparacion.Cliente) = '') and
          (Trim(AReparacion.NombreCliente) = '') and
          (Trim(AReparacion.TelefonoCliente) = '') then
    Result := SErrorClienteReparacion
  else if (AReparacion.FechaPrevista > 0) and
          (Trunc(AReparacion.FechaPrevista) < Trunc(AReparacion.Fecha)) then
    Result := SErrorFechaPrevistaReparacion;
  if Result = '' then
    Result := ValidarObjeto(AReparacion);
  if Result = '' then
    Result := ValidarCobro(AReparacion);
  if Result = '' then
    Result := ValidarEjecutor(AReparacion.TipoEjecutor,
      AReparacion.Empleado, AReparacion.Proveedor);
end;

function ValidarLineaReparacion(const ALinea: TLineaReparacion): string;
begin
  Result := '';
  if ALinea.Reparacion <= 0 then
    Result := SErrorSinReparacion
  else if Trim(ALinea.Descripcion) = '' then
    Result := SErrorDescripcionLineaReparacion
  else if (ALinea.Cantidad <= 0) or (ALinea.PrecioCliente < 0) or
          (ALinea.PrecioCoste < 0) then
    Result := SErrorImporteReparacion
  else if ALinea.TipoLinea = LINEA_REPARACION_MATERIAL then
  begin
    if ALinea.TipoEjecutor <> '' then
      Result := SErrorEjecutorReparacion;
  end
  else if ALinea.TipoLinea = LINEA_REPARACION_MANO_OBRA then
    Result := ValidarEjecutor(ALinea.TipoEjecutor, ALinea.Empleado,
      ALinea.Proveedor)
  else
    Result := SErrorTipoLineaReparacion;
end;

function FaseCerrada(const ASituacion: TSituacionReparacion): string;
begin
  Result := '';
  if ASituacion.Estado = ESTADO_REPARACION_ANULADA then
    Result := FASE_REPARACION_ANULADO
  else if ASituacion.Entregado then
    Result := FASE_REPARACION_ENTREGADO;
end;

function FaseAbierta(const ASituacion: TSituacionReparacion): string;
begin
  if ASituacion.EsPresupuesto and
     (ASituacion.EstadoPresupuesto = PRESUPUESTO_RECHAZADO) then
    Result := FASE_REPARACION_RECHAZADO
  else if not PuedeEmpezarReparacion(ASituacion.EsPresupuesto,
          ASituacion.EstadoPresupuesto) then
    Result := FASE_REPARACION_PRESUPUESTO
  else if (ASituacion.LineasManoObra > 0) and
          (ASituacion.LineasTerminadas >= ASituacion.LineasManoObra) then
    Result := FASE_REPARACION_REPARADO
  else if (ASituacion.LineasIniciadas > 0) or
          (ASituacion.Estado = ESTADO_GARANTIA_EN_SAT) then
    Result := FASE_REPARACION_EN_REPARACION
  else
    Result := FASE_REPARACION_RECIBIDO;
end;

// Anulado o entregado mandan sobre las líneas y el presupuesto.
function FaseReparacion(const ASituacion: TSituacionReparacion): string;
begin
  Result := FaseCerrada(ASituacion);
  if Result = '' then
    Result := FaseAbierta(ASituacion);
end;

function PuedeEmpezarReparacion(AEsPresupuesto: Boolean;
  const AEstadoPresupuesto: string): Boolean;
begin
  Result := (not AEsPresupuesto) or
    (AEstadoPresupuesto = PRESUPUESTO_ACEPTADO);
end;

function PuedeEntregarReparacion(const AFase: string): Boolean;
begin
  Result := (AFase = FASE_REPARACION_REPARADO) or
    (AFase = FASE_REPARACION_RECHAZADO);
end;

function PuedeAnularReparacion(const AFase: string;
  ATieneLiquidaciones: Boolean): Boolean;
begin
  Result := not ATieneLiquidaciones and
    (AFase <> FASE_REPARACION_ENTREGADO) and
    (AFase <> FASE_REPARACION_ANULADO);
end;

function LiquidaAlTerminarLinea(const ATipoEjecutor,
  AModoLiquidacion: string): Boolean;
begin
  Result := (ATipoEjecutor = EJECUTOR_REPARACION_EXTERNO) and
    (AModoLiquidacion = MODO_LIQUIDACION_LINEA);
end;

function FaltaCobrarReparacion(const AModalidad, AModoCobro: string;
  AEsCobrado: Boolean; AImporte: Currency): Boolean;
begin
  Result := (AModalidad = MODALIDAD_REPARACION_PAGO) and
    (AModoCobro = COBRO_REPARACION_RECOGIDA) and not AEsCobrado and
    (AImporte > 0);
end;

function TextoDe(const AValor: string; const AValores,
  ATextos: array of string): string;
var
  iIndice: Integer;
begin
  Result := AValor;
  for iIndice := 0 to Min(High(AValores), High(ATextos)) do
    if AValores[iIndice] = AValor then
      Result := ATextos[iIndice];
end;

function TextoModalidadReparacion(const AValor: string): string;
begin
  Result := TextoDe(AValor, [MODALIDAD_REPARACION_GARANTIA,
    MODALIDAD_REPARACION_PAGO, MODALIDAD_REPARACION_CORTESIA],
    [SModalidadGarantia, SModalidadPago, SModalidadCortesia]);
end;

function TextoFaseReparacion(const AValor: string): string;
begin
  Result := TextoDe(AValor, [FASE_REPARACION_RECIBIDO,
    FASE_REPARACION_PRESUPUESTO, FASE_REPARACION_RECHAZADO,
    FASE_REPARACION_EN_REPARACION, FASE_REPARACION_REPARADO,
    FASE_REPARACION_ENTREGADO, FASE_REPARACION_ANULADO],
    [SFaseReparacionRecibido, SFaseReparacionPresupuesto,
     SFaseReparacionRechazado, SFaseReparacionEnReparacion,
     SFaseReparacionReparado, SFaseReparacionEntregado,
     SFaseReparacionAnulado]);
end;

function TextoModoCobroReparacion(const AValor: string): string;
begin
  Result := TextoDe(AValor, [COBRO_REPARACION_COMPRA,
    COBRO_REPARACION_RECOGIDA, COBRO_REPARACION_GRATIS],
    [SCobroReparacionCompra, SCobroReparacionRecogida,
     SCobroReparacionGratis]);
end;

function TextoOrigenReparacion(const AValor: string): string;
begin
  Result := TextoDe(AValor, [ORIGEN_REPARACION_VENDIDO,
    ORIGEN_REPARACION_CLIENTE, ORIGEN_REPARACION_TIENDA],
    [SOrigenReparacionVendido, SOrigenReparacionCliente,
     SOrigenReparacionTienda]);
end;

function TextoEjecutorReparacion(const AValor: string): string;
begin
  Result := TextoDe(AValor, [EJECUTOR_REPARACION_OPERARIO,
    EJECUTOR_REPARACION_EXTERNO],
    [SEjecutorReparacionOperario, SEjecutorReparacionExterno]);
end;

function TextoModoLiquidacion(const AValor: string): string;
begin
  if AValor = MODO_LIQUIDACION_LINEA then
    Result := SModoLiquidacionLinea
  else
    Result := SModoLiquidacionPeriodica;
end;

end.
