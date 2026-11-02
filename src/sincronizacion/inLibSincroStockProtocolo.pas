{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroStockProtocolo                                     }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Protocolo de sincronización de documentos y stock entre tiendas y la      }
{    central. Amplía inLibSincroProtocolo con:                                 }
{      - Eventos de varios tipos (venta, compra, traspaso, inventario, alta   }
{        de artículo) enviados en orden de secuencia por terminal.             }
{      - Novedades de artículos, precios, stock por almacén, traspasos en     }
{        tránsito y avisos de sobreventa.                                      }
{      - Reserva en línea de unidades de un almacén compartido.               }
{      - Consulta de stock en línea.                                           }
{                                                                              }
{    Principio: el stock nunca se envía como cifra, se envía como movimiento.  }
{    La central lo calcula sumando movimientos; por eso un reenvío o un        }
{    desorden no lo corrompen.                                                 }
{******************************************************************************}
unit inLibSincroStockProtocolo;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses
  {$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF},
  inLibSincroProtocolo;

const
  // Almacén compartido del que puede vender cualquier tienda (p. ej. el
  // almacén central para envíos a domicilio). Es el único en el que dos
  // tiendas pueden competir por la misma unidad.
  CAlmacenCompartido = 'CENTRAL';
  // Pseudoalmacén donde está la mercancía de los traspasos en camino.
  CAlmacenTransito = 'TRANSITO';

type
  TTipoEvento = (
    teAltaArticulo,      // una tienda crea un artículo (código con prefijo)
    teCompra,            // entrada por albarán de proveedor
    teVenta,             // salida por venta
    teDevolucion,        // entrada por devolución de cliente
    teTraspasoSalida,    // origen: la mercancía pasa a TRANSITO
    teTraspasoRecepcion, // destino: la mercancía entra desde TRANSITO
    teInventario);       // ajuste = contado - stock teórico local

  TEventoStock = record
    IdEvento: string;
    Terminal: string;
    Secuencia: Int64;
    Tipo: TTipoEvento;
    Articulo: string;
    Almacen: string;
    AlmacenDestino: string; // traspaso
    IdTraspaso: string;     // traspaso
    Cantidad: Integer;      // unidades; en inventario es el AJUSTE
    Contado: Integer;       // inventario: unidades contadas (informativo)
    Precio: Currency;       // alta de artículo
    IdReserva: string;      // venta del almacén compartido reservada en línea
    Instante: Int64;
  end;
  TEventosStock = array of TEventoStock;

  TResultadoEvento = (
    reAceptado,
    reRepetido,
    reRechazado,      // error de negocio permanente
    reFueraDeOrden);  // falta una secuencia anterior: mantener pendiente

  TAckEvento = record
    IdEvento: string;
    Resultado: TResultadoEvento;
    Motivo: string;
  end;
  TAcksEvento = array of TAckEvento;

  TRespuestaEventos = record
    Acks: TAcksEvento;
  end;

  TTipoNovedadStock = (
    tnArticulo,           // alta o cambio de precio
    tnStock,              // stock de Articulo en Almacen = Cantidad
    tnTraspasoEnTransito, // hay un traspaso en camino hacia Almacen
    tnTraspasoRecibido,   // el destino lo ha recibido
    tnSobreventa);        // el stock de Articulo en Almacen quedó negativo

  TNovedadStock = record
    Version: Int64;
    Tipo: TTipoNovedadStock;
    Articulo: string;
    Almacen: string;
    AlmacenOrigen: string;
    Terminal: string;     // terminal que originó el cambio ('' = central)
    IdTraspaso: string;
    Cantidad: Integer;
    Precio: Currency;
    Instante: Int64;      // momento de publicación: sirve para medir la latencia
  end;
  TNovedadesStock = array of TNovedadStock;

  TRespuestaNovedadesStock = record
    Novedades: TNovedadesStock;
    HayMas: Boolean;
    UltimaVersion: Int64;
  end;

  TResultadoReserva = (rrConcedida, rrSinStock, rrArticuloDesconocido);

  TRespuestaReserva = record
    Resultado: TResultadoReserva;
    Disponible: Integer; // tras la reserva
  end;

  TConsultaStock = record
    Articulo: string;
    Almacen: string;
    Cantidad: Integer;
    Version: Int64;
  end;

  // Contrato del servicio. Correspondencia HTTP prevista:
  //   EnviarEventos      -> POST sincro/eventos.php
  //   PedirNovedades     -> GET  sincro/novedades.php?desde=N&maximo=M
  //                         (espera larga: responde en cuanto haya algo)
  //   ConfirmarNovedades -> POST sincro/novedades_ack.php
  //   Reservar           -> POST sincro/reservas.php   (idempotente por id)
  //   ConsultarStock     -> GET  sincro/stock.php?articulo=X&almacen=Y
  IServicioStock = interface
    ['{5C2D1F0A-7B3E-4E8F-9A61-0D4C7E2B9F13}']
    function EnviarEventos(const ATerminal: string;
      const AEventos: TEventosStock): TRespuestaEventos;
    function PedirNovedades(const ATerminal: string;
      ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedadesStock;
    procedure ConfirmarNovedades(const ATerminal: string;
      AHastaVersion: Int64);
    function Reservar(const ATerminal, AIdReserva, AArticulo,
      AAlmacen: string; ACantidad: Integer): TRespuestaReserva;
    function ConsultarStock(const AArticulo, AAlmacen: string): TConsultaStock;
  end;

function TipoEventoTexto(ATipo: TTipoEvento): string;
function TipoNovedadStockTexto(ATipo: TTipoNovedadStock): string;
function ResultadoEventoTexto(AResultado: TResultadoEvento): string;
function ClaveStock(const AArticulo, AAlmacen: string): string;

implementation

function TipoEventoTexto(ATipo: TTipoEvento): string;
begin
  case ATipo of
    teAltaArticulo: Result := 'ALTA_ARTICULO';
    teCompra: Result := 'COMPRA';
    teVenta: Result := 'VENTA';
    teDevolucion: Result := 'DEVOLUCION';
    teTraspasoSalida: Result := 'TRASPASO_SALIDA';
    teTraspasoRecepcion: Result := 'TRASPASO_RECEPCION';
  else
    Result := 'INVENTARIO';
  end;
end;

function TipoNovedadStockTexto(ATipo: TTipoNovedadStock): string;
begin
  case ATipo of
    tnArticulo: Result := 'ARTICULO';
    tnStock: Result := 'STOCK';
    tnTraspasoEnTransito: Result := 'TRASPASO_EN_TRANSITO';
    tnTraspasoRecibido: Result := 'TRASPASO_RECIBIDO';
  else
    Result := 'SOBREVENTA';
  end;
end;

function ResultadoEventoTexto(AResultado: TResultadoEvento): string;
begin
  case AResultado of
    reAceptado: Result := 'ACEPTADO';
    reRepetido: Result := 'REPETIDO';
    reRechazado: Result := 'RECHAZADO';
  else
    Result := 'FUERA_DE_ORDEN';
  end;
end;

function ClaveStock(const AArticulo, AAlmacen: string): string;
begin
  Result := AArticulo + '|' + AAlmacen;
end;

end.
