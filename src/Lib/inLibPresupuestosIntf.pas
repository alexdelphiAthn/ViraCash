{******************************************************************************}
{                                                                              }
{                        Módulo: inLibPresupuestosIntf                         }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibPresupuestosIntf;

interface

uses
  inLibDocumentoIntf;

type
  TDestinoPresupuesto = (dpPedido, dpAlbaran, dpFactura);
  TDestinosPresupuesto = set of TDestinoPresupuesto;

  // Datos del documento de destino elegidos en el dialogo de conversion.
  // NumeroDestino vacio = siguiente numero del contador de la serie.
  // MueveStock solo se aplica a las facturas. FormaPago vacia = la del
  // presupuesto.
  TOpcionesConversionPresupuesto = record
    Almacen: string;
    SerieDestino: string;
    NumeroDestino: string;
    Fecha: TDateTime;
    MueveStock: Boolean;
    FormaPago: string;
  end;

  TSolicitudConversionPresupuesto = record
    Destino: TDestinoPresupuesto;
    Serie: string;
    Numero: string;
    Usuario: string;
    // False: presupuesto ya convertido, se abre su documento de destino.
    ConOpciones: Boolean;
    Opciones: TOpcionesConversionPresupuesto;
  end;

  TResultadoConversionPresupuesto = record
    TipoDocumento: TTipoDocumento;
    Pantalla: string;
    Serie: string;
    Numero: string;
  end;

function CrearSolicitudConversionPresupuesto(
  ADestino: TDestinoPresupuesto;
  const ASerie, ANumero, AUsuario: string):
  TSolicitudConversionPresupuesto;
function TipoDestinoPresupuesto(ADestino: TDestinoPresupuesto):
  TTipoDocumento;
function PantallaDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;
function CrearSolicitudConversionPresupuestoOpciones(
  ADestino: TDestinoPresupuesto;
  const ASerie, ANumero, AUsuario: string;
  const AOpciones: TOpcionesConversionPresupuesto):
  TSolicitudConversionPresupuesto;
function DestinoPresupuestoMueveStockOpcional(
  ADestino: TDestinoPresupuesto): Boolean;

implementation

function CrearSolicitudConversionPresupuesto(
  ADestino: TDestinoPresupuesto;
  const ASerie, ANumero, AUsuario: string):
  TSolicitudConversionPresupuesto;
begin
  Result := Default(TSolicitudConversionPresupuesto);
  Result.Destino := ADestino;
  Result.Serie := ASerie;
  Result.Numero := ANumero;
  Result.Usuario := AUsuario;
end;

function TipoDestinoPresupuesto(ADestino: TDestinoPresupuesto):
  TTipoDocumento;
const
  TIPOS: array[TDestinoPresupuesto] of TTipoDocumento =
    (tdPedido, tdAlbaran, tdFactura);
begin
  Result := TIPOS[ADestino];
end;

function PantallaDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;
const
  PANTALLAS: array[TDestinoPresupuesto] of string =
    ('Pedidos', 'Albaranes', 'Facturas');
begin
  Result := PANTALLAS[ADestino];
end;

function CrearSolicitudConversionPresupuestoOpciones(
  ADestino: TDestinoPresupuesto;
  const ASerie, ANumero, AUsuario: string;
  const AOpciones: TOpcionesConversionPresupuesto):
  TSolicitudConversionPresupuesto;
begin
  Result := CrearSolicitudConversionPresupuesto(ADestino, ASerie, ANumero,
    AUsuario);
  Result.ConOpciones := True;
  Result.Opciones := AOpciones;
end;

// Pedidos y albaranes siempre mueven (o reservan) stock; la factura
// puede nacer con o sin movimientos.
function DestinoPresupuestoMueveStockOpcional(
  ADestino: TDestinoPresupuesto): Boolean;
begin
  Result := ADestino = dpFactura;
end;

end.
