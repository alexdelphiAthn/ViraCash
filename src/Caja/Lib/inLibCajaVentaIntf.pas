{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaVentaIntf                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de validación, descuento, impresión y cierre de ventas de caja. }
{******************************************************************************}
unit inLibCajaVentaIntf;

interface

uses
  System.Classes, System.SysUtils, Data.DB, inLibCajaTipos, inLibFaseCobro;

type
  EGrabacionVentaCaja = class(Exception)
  private
    FPermiteReintentar: Boolean;
  public
    constructor Create(const AMensaje: string;
      APermiteReintentar: Boolean = True); reintroduce;
    property PermiteReintentar: Boolean read FPermiteReintentar;
  end;

  TMotivoStockVenta = (
    msvNinguno,
    msvSkuNoExiste,
    msvSkuInactivo,
    msvSinStock);
  TEntradaPoliticaStockVenta = record
    VerificarExistencia: Boolean;
    Existe: Boolean;
    Activo: Boolean;
    VerificarStock: Boolean;
    BloquearSinStock: Boolean;
    CantidadDisponible: Double;
  end;
  TResultadoPoliticaStockVenta = record
    Permitida: Boolean;
    Motivo: TMotivoStockVenta;
    Mensaje: string;
  end;
  IResultadoConsultaCaja = interface
    ['{2D060C54-6A4E-472E-B970-27777230D9E2}']
    function DataSet: TDataSet;
  end;
  TEmpleadoCaja = record
    Codigo: string;
    Nombre: string;
  end;
  TNombresAtributosCaja = TArray<string>;
  TClienteCaja = record
    Codigo: string;
    RazonSocial: string;
    Nif: string;
    Movil: string;
    Email: string;
    Direccion1: string;
    Direccion2: string;
    Poblacion: string;
    Provincia: string;
    CodigoPostal: string;
    CodigoPais: string;
    NombrePais: string;
    EsIvaRecargo: string;
    CodigoOficinaContable: string;
    CodigoOrganoGestor: string;
    CodigoUnidadTramitadora: string;
    EsIvaExento: string;
    EsRegimenEspecialAgricola: string;
    EsRetenciones: string;
    EsIntracomunitario: string;
    CodigoFormaPago: string;
    TarifaArticulo: string;
    EsPermiteDeuda: string;
    // 'S' = cliente genérico de Varios: aparta prendas sin cuenta propia.
    EsClienteVarios: string;
  end;
  IRepositorioConsultasCaja = interface
    ['{16818A0B-0B01-4D6B-A8CD-9C94923930EA}']
    function ConsultarStock(
      const ACodigoArticulo: string): IResultadoConsultaCaja;
    function ConsultarClientes: IResultadoConsultaCaja;
    function ConsultarTarifas: IResultadoConsultaCaja;
    function ConsultarEmpleados: IResultadoConsultaCaja;
    function BuscarEmpleado(
      const ATexto: string;
      out AEmpleado: TEmpleadoCaja): Boolean;
    function ObtenerCliente(
      const ACodigo: string;
      out ACliente: TClienteCaja): Boolean;
    function ConsultarCabeceraFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
    function ConsultarLineasFactura(
      const ASerie, ANumero: string): IResultadoConsultaCaja;
    function ConsultarFacturaPorCodigoBarras(
      const ACodigoBarras: string): IResultadoConsultaCaja;
    function ConsultarFacturaPorOperacion(
      const AEmpresa, AAlmacen, ACaja,
      ANumeroOperacion: string): IResultadoConsultaCaja;
    function ConsultarVentasOrigenSku(
      const ASku, AEmpresa: string): IResultadoConsultaCaja;
  end;
  IRepositorioArticulosCaja = interface
    ['{6C1C97EF-F58D-4AF5-AC46-607C60686337}']
    function ConsultarArticulosIncremental(
      const ATarifa, ATexto: string;
      AFechaTarifa: TDateTime): IResultadoConsultaCaja;
    function ConsultarArticulosBusqueda(
      const ATarifa: string;
      AFechaTarifa: TDateTime): IResultadoConsultaCaja;
    function ListarNombresAtributosArticulo(
      const AArticulo: string): TNombresAtributosCaja;
  end;
  TResultadoRectificacionCaja = record
    Serie: string;
    Numero: string;
    Tipo: TTipoRectificativaCaja;
    TratamientoMovimientos:
      TTratamientoMovimientosRectificativa;
    DescripcionTipo: string;
    // FZ-ISSUE-379: líquido de la factura de origen (lo ya cobrado).
    LiquidoOrigen: Currency;
  end;
  IServicioRectificacionCaja = interface
    ['{423D8DF2-FC5F-47C4-AD75-5DB2A6B9B8A2}']
    procedure CargarDevolucion(
      const ASerie, ANumero: string;
      ACabecera, ALineas: TDataSet);
    function Cargar(
      const ASerie, ANumero: string;
      ATipo: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa;
      ACabecera, ALineas: TDataSet
    ): TResultadoRectificacionCaja;
  end;
  IPoliticaStockVenta = interface
    ['{D2A29706-51CA-48BA-B1AA-BCA539E8D89F}']
    function Validar(
      const ACodigoSku, ACodigoAlmacen: string
    ): TResultadoPoliticaStockVenta;
    // FZ-ISSUE-424: unidades del SKU en el ticket por encima del stock
    // (con stock) del almacén. Sin stock ya responde Validar.
    function ValidarCantidad(
      const ACodigoSku, ACodigoAlmacen: string;
      ACantidad: Double): TResultadoPoliticaStockVenta;
  end;
  TLineaRepartoDescuento = record
    Cantidad: Double;
    PrecioSalida: Currency;
  end;
  TResultadoLineaDescuento = record
    ImporteDescuento: Currency;
    PrecioConDescuento: Currency;
    PorcentajeDescuento: Double;
  end;
  IRepartidorDescuento = interface
    ['{6D3299DA-C682-4D6E-9B72-D94C5F8547F3}']
    function Repartir(
      const ALineas: TArray<TLineaRepartoDescuento>;
      AImporteDescuento: Currency
    ): TArray<TResultadoLineaDescuento>;
  end;
  TSolicitudImpresionVenta = record
    TipoImpresion: TTipoImpresionVenta;
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    NumeroOperacion: string;
    SerieFactura: string;
    NumeroFactura: string;
    FechaOperacion: TDateTime;
    DatosCobro: TDatosFaseCobro;
  end;
  IImpresorVenta = interface
    ['{77199D03-7606-4B57-A046-BBBEC3E7D60A}']
    procedure Imprimir(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
    procedure GenerarPdfRespaldo(
      const ASolicitud: TSolicitudImpresionVenta;
      ARutasPdf: TStrings);
  end;
  TSolicitudGrabacionVenta = record
    CodigoEmpresa: string;
    CodigoAlmacen: string;
    CodigoCaja: string;
    SerieDocumento: string;
    TipoFactura: string;
    FechaFactura: TDateTime;
    FechaOperacion: TDateTime;
    NumeroManual: string;
    TipoRectificativa: TTipoRectificativaCaja;
    SerieRectificada: string;
    NumeroRectificado: string;
    TratamientoMovimientos:
      TTratamientoMovimientosRectificativa;
    // Devoluciones: motivo y ticket de origen (para referencia en la
    // operación DV y traspaso automático si es de otra tienda)
    MotivoDevolucion: string;
    SerieOrigenDevolucion: string;
    NumeroOrigenDevolucion: string;
    EmpresaOrigenDevolucion: string;
    AlmacenOrigenDevolucion: string;
    DatosCobro: TDatosFaseCobro;
  end;
  TResultadoPersistenciaVentaCaja = record
    Grabada: Boolean;
    NumeroOperacion: string;
    CodigoValeGenerado: string;
    UltimaSerieFactura: string;
    UltimoNumeroFactura: string;
    SerieFacturaImpresion: string;
    NumeroFacturaImpresion: string;
    // Fallo posterior a confirmar la venta (impresión de resguardos):
    // la venta queda grabada y solo hay que avisar.
    AvisoTrasGrabacion: string;
  end;
  IUnidadTrabajoVentaCaja = interface
    ['{B5A33934-55EC-41B1-83B2-AEB0FBAA07BD}']
    function Ejecutar(
      const ASolicitud: TSolicitudGrabacionVenta
    ): TResultadoPersistenciaVentaCaja;
  end;
  TSolicitudCierreVenta = record
    Grabacion: TSolicitudGrabacionVenta;
    TipoImpresion: TTipoImpresionVenta;
  end;
  TResultadoCierreVenta = record
    Grabada: Boolean;
    NumeroGenerado: string;
    CodigoValeGenerado: string;
    AvisoTrasGrabacion: string;
  end;
  ICasoUsoCierreVentaCaja = interface
    ['{78B5CC6D-7852-4944-995D-F6ED0EFA7B58}']
    function Ejecutar(
      const ASolicitud: TSolicitudCierreVenta
    ): TResultadoCierreVenta;
  end;
  TContextoDependenciasOperacionCaja = record
    RepositorioConsultas: IRepositorioConsultasCaja;
    ServicioRectificacion: IServicioRectificacionCaja;
    PoliticaStock: IPoliticaStockVenta;
    RepartidorDescuento: IRepartidorDescuento;
    CasoUsoCierre: ICasoUsoCierreVentaCaja;
  end;

function EvaluarPoliticaStockVenta(
  const AEntrada: TEntradaPoliticaStockVenta
): TResultadoPoliticaStockVenta;

implementation

constructor EGrabacionVentaCaja.Create(const AMensaje: string;
  APermiteReintentar: Boolean);
begin
  inherited Create(AMensaje);
  FPermiteReintentar := APermiteReintentar;
end;

function EvaluarPoliticaStockVenta(
  const AEntrada: TEntradaPoliticaStockVenta
): TResultadoPoliticaStockVenta;
begin
  Result.Permitida := True;
  Result.Motivo := msvNinguno;
  Result.Mensaje := '';
  if AEntrada.VerificarExistencia and (not AEntrada.Existe) then
  begin
    Result.Permitida := False;
    Result.Motivo := msvSkuNoExiste;
  end
  else if AEntrada.VerificarExistencia and (not AEntrada.Activo) then
  begin
    Result.Permitida := False;
    Result.Motivo := msvSkuInactivo;
  end
  else if AEntrada.VerificarStock and
          (AEntrada.CantidadDisponible <= 0) then
  begin
    Result.Permitida := not AEntrada.BloquearSinStock;
    Result.Motivo := msvSinStock;
  end;
end;

end.
