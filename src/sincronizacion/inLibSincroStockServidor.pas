{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroStockServidor                                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Central en memoria. Reglas que debe cumplir la implementación real:      }
{      - Los eventos de un terminal se procesan en orden de secuencia; un     }
{        hueco deja el evento FUERA_DE_ORDEN (el terminal lo reintenta).      }
{      - Idempotencia por IdEvento.                                            }
{      - El stock es la suma de movimientos; cada movimiento publica una      }
{        novedad tnStock con la cifra resultante y la versión.                 }
{      - Las reservas descuentan del disponible, no del stock, hasta que      }
{        llega la venta que las consume.                                       }
{      - Un stock negativo publica tnSobreventa para el terminal causante y   }
{        el resto de tiendas.                                                  }
{******************************************************************************}
unit inLibSincroStockServidor;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses
  {$IFDEF FPC}
  SysUtils, Generics.Collections,
  {$ELSE}
  System.SysUtils, System.Generics.Collections,
  {$ENDIF}
  inLibSincroProtocolo, inLibSincroStockProtocolo;

type
  TMovimiento = record
    IdEvento: string;
    Articulo: string;
    Almacen: string;
    Cantidad: Integer; // con signo
    Instante: Int64;
  end;

  TTraspasoEnTransito = record
    IdTraspaso: string;
    Articulo: string;
    Origen: string;
    Destino: string;
    Cantidad: Integer;
  end;

  TReserva = record
    Articulo: string;
    Almacen: string;
    Cantidad: Integer;
    Consumida: Boolean;
  end;

  TSobreventa = record
    Version: Int64;
    Terminal: string;
    Articulo: string;
    Almacen: string;
    StockResultante: Integer;
    ConReserva: Boolean; // sobreventa pese a reserva: nunca debería ocurrir
    Instante: Int64;      // cuándo la detectó la central
    InstanteVenta: Int64; // cuándo se hizo la venta en la tienda
  end;

  TEstadisticasCentral = record
    Lotes: Integer;
    Aceptados: Integer;
    Repetidos: Integer;
    Rechazados: Integer;
    FueraDeOrden: Integer;
    ReservasConcedidas: Integer;
    ReservasDenegadas: Integer;
    Consultas: Integer;
    PeticionesNovedades: Integer;
    Confirmaciones: Integer;
    EventosPorTipo: array[TTipoEvento] of Integer;
  end;

  TServidorStock = class(TInterfacedObject, IServicioStock)
  private
    FReloj: Int64;
    FArticulos: TDictionary<string, Currency>;
    FStock: TDictionary<string, Integer>;
    FMovimientos: TList<TMovimiento>;
    FEventosVistos: TDictionary<string, TResultadoEvento>;
    FUltimaSecuencia: TDictionary<string, Int64>;
    FTransito: TDictionary<string, TTraspasoEnTransito>;
    FReservas: TDictionary<string, TReserva>;
    FNovedades: TList<TNovedadStock>;
    FCursores: TDictionary<string, Int64>;
    FSobreventas: TList<TSobreventa>;
    FUltimaVersion: Int64;
    FEstadisticas: TEstadisticasCentral;
    function Publicar(const ANovedad: TNovedadStock): Int64;
    procedure PublicarStock(const AArticulo, AAlmacen, ATerminal: string);
    procedure Mover(const AIdEvento, AArticulo, AAlmacen: string;
      ACantidad: Integer; AInstante: Int64);
    function ReservadoActivo(const AArticulo, AAlmacen: string): Integer;
    function Aplicar(const AEvento: TEventoStock;
      out AMotivo: string): Boolean;
    function GetNumeroMovimientos: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    { IServicioStock }
    function EnviarEventos(const ATerminal: string;
      const AEventos: TEventosStock): TRespuestaEventos;
    function PedirNovedades(const ATerminal: string;
      ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedadesStock;
    procedure ConfirmarNovedades(const ATerminal: string;
      AHastaVersion: Int64);
    function Reservar(const ATerminal, AIdReserva, AArticulo,
      AAlmacen: string; ACantidad: Integer): TRespuestaReserva;
    function ConsultarStock(const AArticulo, AAlmacen: string): TConsultaStock;
    { Backoffice de la central }
    procedure CrearArticulo(const AArticulo: string; APrecio: Currency);
    procedure CambiarPrecio(const AArticulo: string; APrecio: Currency);
    procedure CargarStock(const AArticulo, AAlmacen: string;
      ACantidad: Integer);
    { Consultas de verificación }
    function Stock(const AArticulo, AAlmacen: string): Integer;
    function StockPorMovimientos(const AArticulo, AAlmacen: string): Integer;
    function Disponible(const AArticulo, AAlmacen: string): Integer;
    function TraspasosEnTransito: Integer;
    function CursorConfirmado(const ATerminal: string): Int64;
    function ExisteEvento(const AIdEvento: string): Boolean;
    property Reloj: Int64 read FReloj write FReloj;
    property Articulos: TDictionary<string, Currency> read FArticulos;
    property StockTabla: TDictionary<string, Integer> read FStock;
    property Sobreventas: TList<TSobreventa> read FSobreventas;
    property UltimaVersion: Int64 read FUltimaVersion;
    property NumeroMovimientos: Integer read GetNumeroMovimientos;
    property Estadisticas: TEstadisticasCentral read FEstadisticas;
  end;

implementation

const
  CMaximoPagina = 500;

constructor TServidorStock.Create;
begin
  inherited Create;
  FArticulos := TDictionary<string, Currency>.Create;
  FStock := TDictionary<string, Integer>.Create;
  FMovimientos := TList<TMovimiento>.Create;
  FEventosVistos := TDictionary<string, TResultadoEvento>.Create;
  FUltimaSecuencia := TDictionary<string, Int64>.Create;
  FTransito := TDictionary<string, TTraspasoEnTransito>.Create;
  FReservas := TDictionary<string, TReserva>.Create;
  FNovedades := TList<TNovedadStock>.Create;
  FCursores := TDictionary<string, Int64>.Create;
  FSobreventas := TList<TSobreventa>.Create;
end;

destructor TServidorStock.Destroy;
begin
  FSobreventas.Free;
  FCursores.Free;
  FNovedades.Free;
  FReservas.Free;
  FTransito.Free;
  FUltimaSecuencia.Free;
  FEventosVistos.Free;
  FMovimientos.Free;
  FStock.Free;
  FArticulos.Free;
  inherited Destroy;
end;

function TServidorStock.GetNumeroMovimientos: Integer;
begin
  Result := FMovimientos.Count;
end;

function TServidorStock.Publicar(const ANovedad: TNovedadStock): Int64;
var
  oNovedad: TNovedadStock;
begin
  // Versión asignada con el contador bloqueado (ver esquema_sincro.sql).
  Inc(FUltimaVersion);
  oNovedad := ANovedad;
  oNovedad.Version := FUltimaVersion;
  oNovedad.Instante := FReloj;
  FNovedades.Add(oNovedad);
  Result := FUltimaVersion;
end;

procedure TServidorStock.PublicarStock(const AArticulo, AAlmacen,
  ATerminal: string);
var
  oNovedad: TNovedadStock;
begin
  oNovedad := Default(TNovedadStock);
  oNovedad.Tipo := tnStock;
  oNovedad.Articulo := AArticulo;
  oNovedad.Almacen := AAlmacen;
  oNovedad.Terminal := ATerminal;
  oNovedad.Cantidad := Stock(AArticulo, AAlmacen);
  Publicar(oNovedad);
end;

procedure TServidorStock.Mover(const AIdEvento, AArticulo, AAlmacen: string;
  ACantidad: Integer; AInstante: Int64);
var
  oMovimiento: TMovimiento;
  sClave: string;
begin
  // INSERT en srv_sincro_movimientos + UPDATE srv_sincro_stock, en la
  // misma transacción que el alta del evento.
  oMovimiento.IdEvento := AIdEvento;
  oMovimiento.Articulo := AArticulo;
  oMovimiento.Almacen := AAlmacen;
  oMovimiento.Cantidad := ACantidad;
  oMovimiento.Instante := AInstante;
  FMovimientos.Add(oMovimiento);
  sClave := ClaveStock(AArticulo, AAlmacen);
  FStock.AddOrSetValue(sClave, Stock(AArticulo, AAlmacen) + ACantidad);
end;

function TServidorStock.ReservadoActivo(const AArticulo,
  AAlmacen: string): Integer;
var
  oReserva: TReserva;
begin
  Result := 0;
  for oReserva in FReservas.Values do
    if (not oReserva.Consumida) and (oReserva.Articulo = AArticulo) and
       (oReserva.Almacen = AAlmacen) then
      Inc(Result, oReserva.Cantidad);
end;

function TServidorStock.Aplicar(const AEvento: TEventoStock;
  out AMotivo: string): Boolean;
var
  oTraspaso: TTraspasoEnTransito;
  oReserva: TReserva;
  oNovedad: TNovedadStock;
  oSobreventa: TSobreventa;
  iStock: Integer;
  bConReserva: Boolean;
begin
  AMotivo := '';
  Result := False;
  if (AEvento.Tipo <> teAltaArticulo) and
     not FArticulos.ContainsKey(AEvento.Articulo) then
  begin
    AMotivo := 'articulo desconocido ' + AEvento.Articulo;
    Exit;
  end;
  if (AEvento.Tipo in [teCompra, teVenta, teDevolucion, teTraspasoSalida]) and
     (AEvento.Cantidad <= 0) then
  begin
    AMotivo := 'cantidad no valida';
    Exit;
  end;
  case AEvento.Tipo of
    teAltaArticulo:
      begin
        if FArticulos.ContainsKey(AEvento.Articulo) then
        begin
          AMotivo := 'el articulo ya existe';
          Exit;
        end;
        FArticulos.Add(AEvento.Articulo, AEvento.Precio);
        oNovedad := Default(TNovedadStock);
        oNovedad.Tipo := tnArticulo;
        oNovedad.Articulo := AEvento.Articulo;
        oNovedad.Precio := AEvento.Precio;
        oNovedad.Terminal := AEvento.Terminal;
        Publicar(oNovedad);
      end;
    teCompra, teDevolucion:
      begin
        Mover(AEvento.IdEvento, AEvento.Articulo, AEvento.Almacen,
          AEvento.Cantidad, AEvento.Instante);
        PublicarStock(AEvento.Articulo, AEvento.Almacen, AEvento.Terminal);
      end;
    teVenta:
      begin
        // Una venta con id de reserva desconocido es una venta sin
        // reserva (la petición de reserva nunca llegó).
        bConReserva := (AEvento.IdReserva <> '') and
          FReservas.TryGetValue(AEvento.IdReserva, oReserva);
        if bConReserva and not oReserva.Consumida then
        begin
          oReserva.Consumida := True;
          FReservas.AddOrSetValue(AEvento.IdReserva, oReserva);
        end;
        Mover(AEvento.IdEvento, AEvento.Articulo, AEvento.Almacen,
          -AEvento.Cantidad, AEvento.Instante);
        iStock := Stock(AEvento.Articulo, AEvento.Almacen);
        if iStock < 0 then
        begin
          oSobreventa.Terminal := AEvento.Terminal;
          oSobreventa.Articulo := AEvento.Articulo;
          oSobreventa.Almacen := AEvento.Almacen;
          oSobreventa.StockResultante := iStock;
          oSobreventa.ConReserva := bConReserva;
          oSobreventa.Instante := FReloj;
          oSobreventa.InstanteVenta := AEvento.Instante;
          oNovedad := Default(TNovedadStock);
          oNovedad.Tipo := tnSobreventa;
          oNovedad.Articulo := AEvento.Articulo;
          oNovedad.Almacen := AEvento.Almacen;
          oNovedad.Terminal := AEvento.Terminal;
          oNovedad.Cantidad := iStock;
          oSobreventa.Version := Publicar(oNovedad);
          FSobreventas.Add(oSobreventa);
        end;
        PublicarStock(AEvento.Articulo, AEvento.Almacen, AEvento.Terminal);
      end;
    teTraspasoSalida:
      begin
        if FTransito.ContainsKey(AEvento.IdTraspaso) then
        begin
          AMotivo := 'traspaso ya en transito';
          Exit;
        end;
        oTraspaso.IdTraspaso := AEvento.IdTraspaso;
        oTraspaso.Articulo := AEvento.Articulo;
        oTraspaso.Origen := AEvento.Almacen;
        oTraspaso.Destino := AEvento.AlmacenDestino;
        oTraspaso.Cantidad := AEvento.Cantidad;
        FTransito.Add(AEvento.IdTraspaso, oTraspaso);
        Mover(AEvento.IdEvento, AEvento.Articulo, AEvento.Almacen,
          -AEvento.Cantidad, AEvento.Instante);
        Mover(AEvento.IdEvento, AEvento.Articulo, CAlmacenTransito,
          AEvento.Cantidad, AEvento.Instante);
        PublicarStock(AEvento.Articulo, AEvento.Almacen, AEvento.Terminal);
        oNovedad := Default(TNovedadStock);
        oNovedad.Tipo := tnTraspasoEnTransito;
        oNovedad.Articulo := AEvento.Articulo;
        oNovedad.Almacen := AEvento.AlmacenDestino;
        oNovedad.AlmacenOrigen := AEvento.Almacen;
        oNovedad.IdTraspaso := AEvento.IdTraspaso;
        oNovedad.Cantidad := AEvento.Cantidad;
        oNovedad.Terminal := AEvento.Terminal;
        Publicar(oNovedad);
      end;
    teTraspasoRecepcion:
      begin
        if not FTransito.TryGetValue(AEvento.IdTraspaso, oTraspaso) then
        begin
          AMotivo := 'traspaso desconocido o ya recibido';
          Exit;
        end;
        FTransito.Remove(AEvento.IdTraspaso);
        Mover(AEvento.IdEvento, oTraspaso.Articulo, CAlmacenTransito,
          -oTraspaso.Cantidad, AEvento.Instante);
        Mover(AEvento.IdEvento, oTraspaso.Articulo, oTraspaso.Destino,
          oTraspaso.Cantidad, AEvento.Instante);
        PublicarStock(oTraspaso.Articulo, oTraspaso.Destino, AEvento.Terminal);
        oNovedad := Default(TNovedadStock);
        oNovedad.Tipo := tnTraspasoRecibido;
        oNovedad.Articulo := oTraspaso.Articulo;
        oNovedad.Almacen := oTraspaso.Destino;
        oNovedad.AlmacenOrigen := oTraspaso.Origen;
        oNovedad.IdTraspaso := AEvento.IdTraspaso;
        oNovedad.Cantidad := oTraspaso.Cantidad;
        oNovedad.Terminal := AEvento.Terminal;
        Publicar(oNovedad);
      end;
    teInventario:
      begin
        // Solo se aplica el ajuste: las ventas hechas sin conexión
        // mientras se contaba no se pierden.
        if AEvento.Cantidad <> 0 then
          Mover(AEvento.IdEvento, AEvento.Articulo, AEvento.Almacen,
            AEvento.Cantidad, AEvento.Instante);
        PublicarStock(AEvento.Articulo, AEvento.Almacen, AEvento.Terminal);
      end;
  end;
  Inc(FEstadisticas.EventosPorTipo[AEvento.Tipo]);
  Result := True;
end;

function TServidorStock.EnviarEventos(const ATerminal: string;
  const AEventos: TEventosStock): TRespuestaEventos;
var
  iIndice: Integer;
  oEvento: TEventoStock;
  eVisto: TResultadoEvento;
  iUltima: Int64;
  sMotivo: string;
begin
  // Todo el lote en una transacción; acuses tras el COMMIT.
  Result := Default(TRespuestaEventos);
  Inc(FEstadisticas.Lotes);
  SetLength(Result.Acks, Length(AEventos));
  if not FUltimaSecuencia.TryGetValue(ATerminal, iUltima) then
    iUltima := 0;
  for iIndice := 0 to High(AEventos) do
  begin
    oEvento := AEventos[iIndice];
    Result.Acks[iIndice].IdEvento := oEvento.IdEvento;
    Result.Acks[iIndice].Motivo := '';
    if FEventosVistos.TryGetValue(oEvento.IdEvento, eVisto) then
    begin
      // Un reenvío devuelve REPETIDO aunque el original fuese rechazado:
      // la decisión de negocio ya se tomó y se comunicó.
      Result.Acks[iIndice].Resultado := reRepetido;
      if eVisto = reRechazado then
        Result.Acks[iIndice].Resultado := reRechazado;
      Inc(FEstadisticas.Repetidos);
      Continue;
    end;
    if not SameText(oEvento.Terminal, ATerminal) then
    begin
      Result.Acks[iIndice].Resultado := reRechazado;
      Result.Acks[iIndice].Motivo := 'evento de otro terminal';
      Inc(FEstadisticas.Rechazados);
      Continue;
    end;
    if oEvento.Secuencia <> iUltima + 1 then
    begin
      if oEvento.Secuencia <= iUltima then
      begin
        Result.Acks[iIndice].Resultado := reRechazado;
        Result.Acks[iIndice].Motivo := 'secuencia ya consumida';
        FEventosVistos.Add(oEvento.IdEvento, reRechazado);
        Inc(FEstadisticas.Rechazados);
      end
      else
      begin
        Result.Acks[iIndice].Resultado := reFueraDeOrden;
        Result.Acks[iIndice].Motivo := Format(
          'se esperaba la secuencia %d', [iUltima + 1]);
        Inc(FEstadisticas.FueraDeOrden);
      end;
      Continue;
    end;
    // La secuencia se consume tanto si se acepta como si se rechaza.
    iUltima := oEvento.Secuencia;
    FUltimaSecuencia.AddOrSetValue(ATerminal, iUltima);
    if Aplicar(oEvento, sMotivo) then
    begin
      Result.Acks[iIndice].Resultado := reAceptado;
      FEventosVistos.Add(oEvento.IdEvento, reAceptado);
      Inc(FEstadisticas.Aceptados);
    end
    else
    begin
      Result.Acks[iIndice].Resultado := reRechazado;
      Result.Acks[iIndice].Motivo := sMotivo;
      FEventosVistos.Add(oEvento.IdEvento, reRechazado);
      Inc(FEstadisticas.Rechazados);
    end;
  end;
end;

function TServidorStock.PedirNovedades(const ATerminal: string;
  ADesdeVersion: Int64; AMaximo: Integer): TRespuestaNovedadesStock;
var
  iIndice, iCuenta: Integer;
begin
  Result := Default(TRespuestaNovedadesStock);
  Inc(FEstadisticas.PeticionesNovedades);
  if (AMaximo <= 0) or (AMaximo > CMaximoPagina) then
    AMaximo := CMaximoPagina;
  Result.UltimaVersion := FUltimaVersion;
  iCuenta := 0;
  // Las versiones son 1..N contiguas: se puede saltar directamente.
  iIndice := ADesdeVersion;
  if iIndice < 0 then
    iIndice := 0;
  while iIndice < FNovedades.Count do
  begin
    if iCuenta = AMaximo then
    begin
      Result.HayMas := True;
      Break;
    end;
    SetLength(Result.Novedades, iCuenta + 1);
    Result.Novedades[iCuenta] := FNovedades[iIndice];
    Inc(iCuenta);
    Inc(iIndice);
  end;
end;

procedure TServidorStock.ConfirmarNovedades(const ATerminal: string;
  AHastaVersion: Int64);
var
  iActual: Int64;
begin
  Inc(FEstadisticas.Confirmaciones);
  if AHastaVersion > FUltimaVersion then
    AHastaVersion := FUltimaVersion;
  if not FCursores.TryGetValue(ATerminal, iActual) then
    iActual := 0;
  if AHastaVersion > iActual then
    FCursores.AddOrSetValue(ATerminal, AHastaVersion);
end;

function TServidorStock.Reservar(const ATerminal, AIdReserva, AArticulo,
  AAlmacen: string; ACantidad: Integer): TRespuestaReserva;
var
  oReserva: TReserva;
begin
  // UPDATE srv_sincro_stock SET RESERVADO = RESERVADO + :n
  //  WHERE ... AND STOCK - RESERVADO >= :n   -> ROW_COUNT() decide.
  Result := Default(TRespuestaReserva);
  if FReservas.TryGetValue(AIdReserva, oReserva) then
  begin
    Result.Resultado := rrConcedida; // idempotente
    Result.Disponible := Disponible(AArticulo, AAlmacen);
    Exit;
  end;
  if not FArticulos.ContainsKey(AArticulo) then
  begin
    Result.Resultado := rrArticuloDesconocido;
    Exit;
  end;
  if Disponible(AArticulo, AAlmacen) >= ACantidad then
  begin
    oReserva.Articulo := AArticulo;
    oReserva.Almacen := AAlmacen;
    oReserva.Cantidad := ACantidad;
    oReserva.Consumida := False;
    FReservas.Add(AIdReserva, oReserva);
    Result.Resultado := rrConcedida;
    Inc(FEstadisticas.ReservasConcedidas);
  end
  else
  begin
    Result.Resultado := rrSinStock;
    Inc(FEstadisticas.ReservasDenegadas);
  end;
  Result.Disponible := Disponible(AArticulo, AAlmacen);
end;

function TServidorStock.ConsultarStock(const AArticulo,
  AAlmacen: string): TConsultaStock;
begin
  Inc(FEstadisticas.Consultas);
  Result.Articulo := AArticulo;
  Result.Almacen := AAlmacen;
  Result.Cantidad := Stock(AArticulo, AAlmacen);
  Result.Version := FUltimaVersion;
end;

procedure TServidorStock.CrearArticulo(const AArticulo: string;
  APrecio: Currency);
var
  oNovedad: TNovedadStock;
begin
  FArticulos.AddOrSetValue(AArticulo, APrecio);
  oNovedad := Default(TNovedadStock);
  oNovedad.Tipo := tnArticulo;
  oNovedad.Articulo := AArticulo;
  oNovedad.Precio := APrecio;
  Publicar(oNovedad);
end;

procedure TServidorStock.CambiarPrecio(const AArticulo: string;
  APrecio: Currency);
begin
  if FArticulos.ContainsKey(AArticulo) then
    CrearArticulo(AArticulo, APrecio);
end;

procedure TServidorStock.CargarStock(const AArticulo, AAlmacen: string;
  ACantidad: Integer);
begin
  Mover('CENTRAL-' + IntToStr(FMovimientos.Count + 1), AArticulo, AAlmacen,
    ACantidad, FReloj);
  PublicarStock(AArticulo, AAlmacen, '');
end;

function TServidorStock.Stock(const AArticulo, AAlmacen: string): Integer;
begin
  if not FStock.TryGetValue(ClaveStock(AArticulo, AAlmacen), Result) then
    Result := 0;
end;

function TServidorStock.StockPorMovimientos(const AArticulo,
  AAlmacen: string): Integer;
var
  oMovimiento: TMovimiento;
begin
  Result := 0;
  for oMovimiento in FMovimientos do
    if (oMovimiento.Articulo = AArticulo) and
       (oMovimiento.Almacen = AAlmacen) then
      Inc(Result, oMovimiento.Cantidad);
end;

function TServidorStock.Disponible(const AArticulo, AAlmacen: string): Integer;
begin
  Result := Stock(AArticulo, AAlmacen) - ReservadoActivo(AArticulo, AAlmacen);
end;

function TServidorStock.TraspasosEnTransito: Integer;
begin
  Result := FTransito.Count;
end;

function TServidorStock.CursorConfirmado(const ATerminal: string): Int64;
begin
  if not FCursores.TryGetValue(ATerminal, Result) then
    Result := 0;
end;

function TServidorStock.ExisteEvento(const AIdEvento: string): Boolean;
var
  eVisto: TResultadoEvento;
begin
  Result := FEventosVistos.TryGetValue(AIdEvento, eVisto) and
    (eVisto = reAceptado);
end;

end.
