{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaPresentacionEstados                         }
{    Tipo:       Colaborador de presentacion                                   }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Catalogo de estados de stock ofrecidos al usuario segun el modo           }
{    simplificado / desglosado, su color y su nombre corto. Estado puro: sin   }
{    VCL y sin SQL. Los colores se expresan como enteros BGR ($00BBGGRR),      }
{    igual que TColor, para no arrastrar la VCL a esta unidad.                 }
{******************************************************************************}
unit inLibStockConsultaPresentacionEstados;

interface

uses
  inLibStockConsultaPersistenciaIntf;

const
  // Colores BGR equivalentes a las constantes clXxx de la VCL.
  COLOR_ESTADO_EXISTENCIAS    = $00800000;  // clNavy
  COLOR_ESTADO_ENTRADAS       = $00008000;  // clGreen
  COLOR_ESTADO_SALIDAS        = $00000080;  // clMaroon
  COLOR_ESTADO_VENTAS         = $000000FF;  // clRed
  COLOR_ESTADO_TRASPASO_ENT   = $00808000;  // clTeal
  COLOR_ESTADO_TRASPASO_SAL   = $00800080;  // clPurple
  COLOR_ESTADO_REGULARIZADAS  = $00800080;  // clPurple
  COLOR_ESTADO_PDTE_RECIBIR   = $000080FF;  // naranja
  COLOR_ESTADO_PDTE_SERVIR    = $00808000;  // clTeal
  COLOR_ESTADO_PRESTADAS      = $00808080;  // clGray
  COLOR_ESTADO_ENT_COMPRA     = $00008000;  // verde oscuro
  COLOR_ESTADO_ENT_DEPOSITO   = $00CC9900;  // ambar
  COLOR_ESTADO_SAL_DEPOSITO   = $0099CCFF;  // amarillo claro
  COLOR_ESTADO_SAL_ALB_VENTA  = $000000C0;  // rojo oscuro
  COLOR_ESTADO_ENT_ALB_ENT    = $0000C000;  // verde claro
  COLOR_ESTADO_NEUTRO         = $00000000;  // clBlack

type
  // Resultado de pinchar un estado en la leyenda inferior: si hubo que
  // cambiar de modo y en que posicion del combo queda el estado pedido
  // (-1 si el modo resultante no lo ofrece).
  TResultadoLeyendaStock = record
    ModoCambiado: Boolean;
    ModoDesglosado: Boolean;
    Indice: Integer;
  end;

  TSeleccionEstadosStock = class
  private
    FEstados: TArray<TEstadoStock>;
    FModoDesglosado: Boolean;
    function GetCuenta: Integer;
    function GetEstado(AIndice: Integer): TEstadoStock;
    procedure Agregar(AEstado: TEstadoStock);
  public
    constructor Create;
    procedure Recalcular;
    procedure FijarModo(AModoDesglosado: Boolean);
    function IndiceDe(AEstado: TEstadoStock): Integer;
    function ResolverLeyenda(
      AEstado: TEstadoStock): TResultadoLeyendaStock;
    property ModoDesglosado: Boolean read FModoDesglosado;
    property Cuenta: Integer read GetCuenta;
    property Estados[AIndice: Integer]: TEstadoStock read GetEstado;
  end;

const
  ESTADOS_LEYENDA_STOCK: array[0..7] of TEstadoStock = (
    esExistencias, esEntradas, esSalidas, esVentas, esRegularizadas,
    esPdteRecibir, esPdteServir, esPrestadas);
  // Estados que solo existen en modo simplificado o solo en desglosado.
  ESTADOS_SOLO_SIMPLIFICADO = [esEntradas, esSalidas];
  ESTADOS_SOLO_DESGLOSADO = [esVentas, esRegularizadas, esPrestadas];

function ColorEstadoStock(AEstado: TEstadoStock): Integer;
function NombreEstadoStockCorto(AEstado: TEstadoStock): string;
function EsEstadoStockValido(ANumero: Integer): Boolean;

implementation

uses
  inLibMsgArticulos;

function ColorEstadoStock(AEstado: TEstadoStock): Integer;
begin
  case AEstado of
    esExistencias:        Result := COLOR_ESTADO_EXISTENCIAS;
    esEntradas:           Result := COLOR_ESTADO_ENTRADAS;
    esSalidas:            Result := COLOR_ESTADO_SALIDAS;
    esVentas:             Result := COLOR_ESTADO_VENTAS;
    esEntradaTraspaso:    Result := COLOR_ESTADO_TRASPASO_ENT;
    esSalidaTraspaso:     Result := COLOR_ESTADO_TRASPASO_SAL;
    esRegularizadas:      Result := COLOR_ESTADO_REGULARIZADAS;
    esPdteRecibir:        Result := COLOR_ESTADO_PDTE_RECIBIR;
    esPdteServir:         Result := COLOR_ESTADO_PDTE_SERVIR;
    esPrestadas:          Result := COLOR_ESTADO_PRESTADAS;
    esEntradaCompra:      Result := COLOR_ESTADO_ENT_COMPRA;
    esEntradaDeposito:    Result := COLOR_ESTADO_ENT_DEPOSITO;
    esSalidaDeposito:     Result := COLOR_ESTADO_SAL_DEPOSITO;
    esSalidaAlbVenta:     Result := COLOR_ESTADO_SAL_ALB_VENTA;
    esEntradaAlbEntrada:  Result := COLOR_ESTADO_ENT_ALB_ENT;
    esPdteTraspasar:      Result := COLOR_ESTADO_TRASPASO_SAL;
    esPdteRecTraspaso:    Result := COLOR_ESTADO_TRASPASO_ENT;
    esDisponible:         Result := COLOR_ESTADO_EXISTENCIAS;
  else
    Result := COLOR_ESTADO_NEUTRO;
  end;
end;

function NombreEstadoStockCorto(AEstado: TEstadoStock): string;
begin
  case AEstado of
    esExistencias:        Result := SCaptionStockExistencias;
    esEntradas:           Result := SCaptionStockEntradas;
    esSalidas:            Result := SCaptionStockSalidas;
    esVentas:             Result := SCaptionStockVentas;
    esRegularizadas:      Result := SCaptionStockRegularizadas;
    esEntradaTraspaso:    Result := SCaptionStockEntradaTraspaso;
    esSalidaTraspaso:     Result := SCaptionStockSalidaTraspaso;
    esPdteRecibir:        Result := SCaptionStockPendienteRecibir;
    esPdteServir:         Result := SCaptionStockPendienteServir;
    esPrestadas:          Result := SCaptionStockPrestadas;
    esTodoAlaVez:         Result := SCaptionStockTodosEstados;
    esEntradaCompra:      Result := SCaptionStockEntradaCompra;
    esEntradaDeposito:    Result := SCaptionStockEntradaDeposito;
    esSalidaDeposito:     Result := SCaptionStockSalidaDeposito;
    esSalidaAlbVenta:     Result := SCaptionStockAlbaranVenta;
    esEntradaAlbEntrada:  Result := SCaptionStockAlbaranEntrada;
    esPdteTraspasar:      Result := SCaptionStockPendienteTraspasar;
    esPdteRecTraspaso:    Result := SCaptionStockPendienteRecibirTraspaso;
    esDisponible:         Result := SCaptionStockDisponible;
  else
    Result := '';
  end;
end;

function EsEstadoStockValido(ANumero: Integer): Boolean;
begin
  Result := (ANumero >= Ord(Low(TEstadoStock))) and
            (ANumero <= Ord(High(TEstadoStock)));
end;

constructor TSeleccionEstadosStock.Create;
begin
  inherited Create;
  FModoDesglosado := False;
  Recalcular;
end;

function TSeleccionEstadosStock.GetCuenta: Integer;
begin
  Result := Length(FEstados);
end;

function TSeleccionEstadosStock.GetEstado(
  AIndice: Integer): TEstadoStock;
begin
  if (AIndice >= 0) and (AIndice < Length(FEstados)) then
    Result := FEstados[AIndice]
  else
    Result := esExistencias;
end;

procedure TSeleccionEstadosStock.Agregar(AEstado: TEstadoStock);
begin
  SetLength(FEstados, Length(FEstados) + 1);
  FEstados[High(FEstados)] := AEstado;
end;

// Los totales agregados de entradas/salidas solo se ofrecen en modo
// simplificado; en desglosado se sustituyen por sus subtipos para no
// mezclar el agregado con su propio desglose.
procedure TSeleccionEstadosStock.Recalcular;
begin
  SetLength(FEstados, 0);
  Agregar(esExistencias);
  if not FModoDesglosado then
  begin
    Agregar(esEntradas);
    Agregar(esSalidas);
  end;
  Agregar(esPdteServir);
  Agregar(esPdteRecibir);
  // FZ-ISSUE-251: pendiente de traspaso (solicitudes, propuestas y cargas
  // en transito) y disponible = existencias - pendiente de traspasar.
  Agregar(esPdteTraspasar);
  Agregar(esPdteRecTraspaso);
  Agregar(esDisponible);
  Agregar(esTodoAlaVez);
  if FModoDesglosado then
  begin
    Agregar(esEntradaCompra);
    Agregar(esEntradaTraspaso);
    Agregar(esSalidaTraspaso);
    Agregar(esEntradaDeposito);
    Agregar(esSalidaDeposito);
    Agregar(esVentas);
    Agregar(esRegularizadas);
    Agregar(esSalidaAlbVenta);
    Agregar(esEntradaAlbEntrada);
    Agregar(esPrestadas);
  end;
end;

procedure TSeleccionEstadosStock.FijarModo(AModoDesglosado: Boolean);
begin
  FModoDesglosado := AModoDesglosado;
  Recalcular;
end;

function TSeleccionEstadosStock.IndiceDe(
  AEstado: TEstadoStock): Integer;
var
  i: Integer;
begin
  Result := -1;
  i := 0;
  while (Result < 0) and (i < Length(FEstados)) do
  begin
    if FEstados[i] = AEstado then
      Result := i;
    Inc(i);
  end;
end;

// Pinchar un estado de la leyenda que el modo actual no ofrece cambia el
// modo antes de seleccionarlo, de modo que la leyenda siga siendo un
// acceso directo valido en ambos modos.
function TSeleccionEstadosStock.ResolverLeyenda(
  AEstado: TEstadoStock): TResultadoLeyendaStock;
begin
  Result.ModoCambiado := False;
  if (AEstado in ESTADOS_SOLO_SIMPLIFICADO) and FModoDesglosado then
  begin
    FijarModo(False);
    Result.ModoCambiado := True;
  end
  else if (AEstado in ESTADOS_SOLO_DESGLOSADO) and
          (not FModoDesglosado) then
  begin
    FijarModo(True);
    Result.ModoCambiado := True;
  end;
  Result.ModoDesglosado := FModoDesglosado;
  Result.Indice := IndiceDe(AEstado);
end;

end.
