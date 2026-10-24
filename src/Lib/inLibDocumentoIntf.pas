{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDocumentoIntf                                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos y configuración de la familia común de documentos.              }
{******************************************************************************}
unit inLibDocumentoIntf;

interface

type
  TTipoDocumento = (
    tdAlbaran,
    tdPedido,
    tdFactura,
    tdDevolucion,
    tdPresupuesto
  );

  TSentidoDocumento = (
    sdVenta,
    sdCompra
  );

  TEntradaCalculoDocumento = record
    Cantidad: Currency;
    Precio: Currency;
    PorcentajeDescuento: Double;
    PorcentajeImpuesto: Double;
    PorcentajeRecargo: Double;
    PrecioIncluyeImpuestos: Boolean;
  end;

  TResultadoCalculoDocumento = record
    PrecioNeto: Currency;
    BaseImponible: Currency;
    CuotaImpuesto: Currency;
    CuotaRecargo: Currency;
    Total: Currency;
  end;

  TConfiguracionDocumento = record
    TipoDocumento: TTipoDocumento;
    Sentido: TSentidoDocumento;
    NombreSingular: string;
    TablaCabecera: string;
    TablaLineas: string;
    PrefijoCabecera: string;
    PrefijoLineas: string;
    SignoStock: Integer;
    TipoContador: string;
    TipoDocumentoMovimientoStock: string;
    UsaSerie: Boolean;
    GeneraAsiento: Boolean;
    EmiteVerifactu: Boolean;
    MueveStock: Boolean;
    FiltraCaja: Boolean;
    MensajeCabeceraNoDisponible: string;
    DocumentoConArticulo: string;
    CampoSerieCabecera: string;
    CampoNumeroCabecera: string;
    CampoEstadoCabecera: string;
    CampoPivoteCabecera: string;
    ValorEstadoCabecera: string;
    CampoSerieLinea: string;
    CampoNumeroLinea: string;
    CampoArticuloLinea: string;
    CampoProductoLinea: string;
    CampoUnidadLinea: string;
    CampoPivoteLinea: string;
    CancelarLineaSoloSinNumero: Boolean;
    RecrearLineaVacia: Boolean;
  end;

  IEstrategiaDocumento = interface
    ['{A9098E4E-543A-4B1F-A154-B88941BC4AAE}']
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

implementation

end.
