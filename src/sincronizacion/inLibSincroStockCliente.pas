{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSincroStockCliente                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tienda con base de datos local que trabaja con y sin conexión.            }
{                                                                              }
{    TAlmacenTienda es el estado persistente:                                  }
{      - Bandeja de salida con los eventos en orden de secuencia.              }
{      - Stock PROPIO: exacto siempre, porque solo esta tienda mueve su        }
{        almacén (sale de sus propios eventos, con o sin conexión).            }
{      - COPIA del stock de los demás almacenes, con la versión y el instante  }
{        de la última actualización: es lo que se muestra sin conexión,        }
{        siempre acompañado de su antigüedad.                                  }
{      - Artículos, cursor de novedades, traspasos pendientes de recibir y    }
{        avisos de sobreventa recibidos.                                       }
{                                                                              }
{    TClienteTienda es el motor: vende (con reserva en línea si el almacén    }
{      es compartido), consulta stock (en línea con respaldo local) y          }
{      sincroniza.                                                             }
{******************************************************************************}
unit inLibSincroStockCliente;

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
  TEstadoEvento = (eePendiente, eeConfirmado, eeRechazado);

  TEntradaBandeja = class
  public
    Evento: TEventoStock;
    Estado: TEstadoEvento;
    Intentos: Integer;
    ProximoIntento: Int64;
    Motivo: string;
  end;

  TCopiaStock = record
    Cantidad: Integer;
    Version: Int64;
    InstantePublicado: Int64; // reloj de la central al publicar
    InstanteAplicado: Int64;  // reloj local al aplicar
  end;

  TTraspasoPendiente = record
    IdTraspaso: string;
    Articulo: string;
    Origen: string;
    Cantidad: Integer;
    InstanteAviso: Int64;
  end;

  TAvisoSobreventa = record
    Version: Int64;
    Terminal: string;
    Articulo: string;
    Almacen: string;
    Stock: Integer;
    InstanteRecibido: Int64;
  end;

  TLatencia = record
    Version: Int64;
    Tipo: TTipoNovedadStock;
    InstantePublicado: Int64;
    Latencia: Int64; // ticks entre publicación y aplicación
  end;

  TAlmacenTienda = class
  private
    FTerminal: string;
    FAlmacen: string;
    FBandeja: TObjectList<TEntradaBandeja>;
    FIndice: TDictionary<string, TEntradaBandeja>;
    FUltimaSecuencia: Int64;
    FCursor: Int64;
    FUltimaSincroOk: Int64; // instante de la última bajada completa
    FArticulos: TDictionary<string, Currency>;
    FStockPropio: TDictionary<string, Integer>;
    FCopia: TDictionary<string, TCopiaStock>;
    FTraspasosPendientes: TList<TTraspasoPendiente>;
    FSobreventas: TList<TAvisoSobreventa>;
    FLatencias: TList<TLatencia>;
    function Encolar(const AEvento: TEventoStock): TEventoStock;
  public
    constructor Create(const ATerminal, AAlmacen: string);
    destructor Destroy; override;
    { Operaciones de negocio: cada una graba en la bandeja dentro de la
      transacción del documento. Devuelven el evento generado. }
    function AltaArticulo(const AArticulo: string; APrecio: Currency;
      AInstante: Int64): TEventoStock;
    function Comprar(const AArticulo: string; ACantidad: Integer;
      AInstante: Int64): TEventoStock;
    function Vender(const AArticulo, AAlmacen: string; ACantidad: Integer;
      const AIdReserva: string; AInstante: Int64): TEventoStock;
    function Devolver(const AArticulo: string; ACantidad: Integer;
      AInstante: Int64): TEventoStock;
    function TraspasoSalida(const AArticulo, ADestino: string;
      ACantidad: Integer; AInstante: Int64): TEventoStock;
    function TraspasoRecepcion(const AIdTraspaso: string;
      AInstante: Int64): TEventoStock;
    // Inventario: se envía el ajuste respecto al stock teórico local.
    function Inventario(const AArticulo: string; AContado: Integer;
      AInstante: Int64): TEventoStock;
    { Bandeja }
    function Pendientes(AAhora: Int64; AMaximo: Integer): TEventosStock;
    function NumeroPendientes: Integer;
    function Buscar(const AIdEvento: string): TEntradaBandeja;
    { Novedades }
    procedure AplicarNovedad(const ANovedad: TNovedadStock; AAhora: Int64);
    { Consultas locales }
    function StockPropio(const AArticulo: string): Integer;
    function TieneCopia(const AArticulo, AAlmacen: string;
      out ACopia: TCopiaStock): Boolean;
    function TraspasoPendiente(AIndice: Integer): TTraspasoPendiente;
    property Terminal: string read FTerminal;
    property Almacen: string read FAlmacen;
    property Bandeja: TObjectList<TEntradaBandeja> read FBandeja;
    property Cursor: Int64 read FCursor;
    property UltimaSincroOk: Int64 read FUltimaSincroOk write FUltimaSincroOk;
    property Articulos: TDictionary<string, Currency> read FArticulos;
    property StockPropioTabla: TDictionary<string, Integer> read FStockPropio;
    property Copia: TDictionary<string, TCopiaStock> read FCopia;
    property TraspasosPendientes: TList<TTraspasoPendiente>
      read FTraspasosPendientes;
    property Sobreventas: TList<TAvisoSobreventa> read FSobreventas;
    property Latencias: TList<TLatencia> read FLatencias;
  end;

  TFuenteConsulta = (fcPropio, fcEnLinea, fcCopiaLocal, fcSinDato);

  TResultadoConsulta = record
    Cantidad: Integer;
    Fuente: TFuenteConsulta;
    Antiguedad: Int64; // ticks desde la última actualización de la copia
  end;

  TResultadoVentaTienda = (vtVendida, vtVendidaConReserva,
    vtVendidaSinConexion, vtBloqueadaSinStock);

  TEstadisticasTienda = record
    Ciclos: Integer;
    LotesEnviados: Integer;
    FallosEnvio: Integer;
    EventosConfirmados: Integer;
    EventosRechazados: Integer;
    EventosFueraDeOrden: Integer;
    FallosNovedades: Integer;
    NovedadesAplicadas: Integer;
    VentasPropias: Integer;
    VentasConReserva: Integer;
    VentasSinConexion: Integer;
    VentasBloqueadas: Integer;
    ConsultasPropias: Integer;
    ConsultasEnLinea: Integer;
    ConsultasCopia: Integer;
    ConsultasSinDato: Integer;
  end;

  TClienteTienda = class
  private
    FAlmacen: TAlmacenTienda;
    FServicio: IServicioStock;
    FTamanoLote: Integer;
    FTamanoPagina: Integer;
    FEsperaMaxima: Integer;
    FReintentosReserva: Integer;
    FCursorConfirmado: Int64;
    FUltimoError: string;
    FEstadisticas: TEstadisticasTienda;
    function EsperaReintento(AIntentos: Integer): Int64;
    function SubirEventos(AAhora: Int64): Boolean;
    function BajarNovedades(AAhora: Int64): Boolean;
  public
    constructor Create(AAlmacen: TAlmacenTienda;
      const AServicio: IServicioStock);
    // Venta: si el almacén es el compartido se intenta reservar en línea;
    // si no hay red se vende con riesgo (la central avisará si hubo
    // sobreventa).
    function Vender(const AArticulo, AAlmacen: string; ACantidad: Integer;
      AAhora: Int64): TResultadoVentaTienda;
    // Consulta: propio -> exacto; otro almacén -> central si responde,
    // si no la copia local con su antigüedad.
    function ConsultarStock(const AArticulo, AAlmacen: string;
      AAhora: Int64): TResultadoConsulta;
    function Sincronizar(AAhora: Int64): Boolean;
    property TamanoLote: Integer read FTamanoLote write FTamanoLote;
    property TamanoPagina: Integer read FTamanoPagina write FTamanoPagina;
    property EsperaMaxima: Integer read FEsperaMaxima write FEsperaMaxima;
    property ReintentosReserva: Integer read FReintentosReserva
      write FReintentosReserva;
    property UltimoError: string read FUltimoError;
    property Estadisticas: TEstadisticasTienda read FEstadisticas;
  end;

function NuevoId: string;
function FuenteTexto(AFuente: TFuenteConsulta): string;

implementation

function NuevoId: string;
var
  oGuid: TGUID;
begin
  CreateGUID(oGuid);
  Result := Copy(GUIDToString(oGuid), 2, 36);
end;

function FuenteTexto(AFuente: TFuenteConsulta): string;
begin
  case AFuente of
    fcPropio: Result := 'propio';
    fcEnLinea: Result := 'en linea';
    fcCopiaLocal: Result := 'copia local';
  else
    Result := 'sin dato';
  end;
end;

{ TAlmacenTienda }

constructor TAlmacenTienda.Create(const ATerminal, AAlmacen: string);
begin
  inherited Create;
  FTerminal := ATerminal;
  FAlmacen := AAlmacen;
  FBandeja := TObjectList<TEntradaBandeja>.Create(True);
  FIndice := TDictionary<string, TEntradaBandeja>.Create;
  FArticulos := TDictionary<string, Currency>.Create;
  FStockPropio := TDictionary<string, Integer>.Create;
  FCopia := TDictionary<string, TCopiaStock>.Create;
  FTraspasosPendientes := TList<TTraspasoPendiente>.Create;
  FSobreventas := TList<TAvisoSobreventa>.Create;
  FLatencias := TList<TLatencia>.Create;
end;

destructor TAlmacenTienda.Destroy;
begin
  FLatencias.Free;
  FSobreventas.Free;
  FTraspasosPendientes.Free;
  FCopia.Free;
  FStockPropio.Free;
  FArticulos.Free;
  FIndice.Free;
  FBandeja.Free;
  inherited Destroy;
end;

function TAlmacenTienda.Encolar(const AEvento: TEventoStock): TEventoStock;
var
  oEntrada: TEntradaBandeja;
begin
  Result := AEvento;
  Inc(FUltimaSecuencia);
  Result.IdEvento := NuevoId;
  Result.Terminal := FTerminal;
  Result.Secuencia := FUltimaSecuencia;
  oEntrada := TEntradaBandeja.Create;
  oEntrada.Evento := Result;
  oEntrada.Estado := eePendiente;
  FBandeja.Add(oEntrada);
  FIndice.Add(Result.IdEvento, oEntrada);
end;

function TAlmacenTienda.AltaArticulo(const AArticulo: string;
  APrecio: Currency; AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
begin
  FArticulos.AddOrSetValue(AArticulo, APrecio);
  oEvento := Default(TEventoStock);
  oEvento.Tipo := teAltaArticulo;
  oEvento.Articulo := AArticulo;
  oEvento.Precio := APrecio;
  oEvento.Instante := AInstante;
  Result := Encolar(oEvento);
end;

function TAlmacenTienda.Comprar(const AArticulo: string; ACantidad: Integer;
  AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
begin
  FStockPropio.AddOrSetValue(AArticulo, StockPropio(AArticulo) + ACantidad);
  oEvento := Default(TEventoStock);
  oEvento.Tipo := teCompra;
  oEvento.Articulo := AArticulo;
  oEvento.Almacen := FAlmacen;
  oEvento.Cantidad := ACantidad;
  oEvento.Instante := AInstante;
  Result := Encolar(oEvento);
end;

function TAlmacenTienda.Vender(const AArticulo, AAlmacen: string;
  ACantidad: Integer; const AIdReserva: string;
  AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
begin
  if AAlmacen = FAlmacen then
    FStockPropio.AddOrSetValue(AArticulo, StockPropio(AArticulo) - ACantidad);
  oEvento := Default(TEventoStock);
  oEvento.Tipo := teVenta;
  oEvento.Articulo := AArticulo;
  oEvento.Almacen := AAlmacen;
  oEvento.Cantidad := ACantidad;
  oEvento.IdReserva := AIdReserva;
  oEvento.Instante := AInstante;
  Result := Encolar(oEvento);
end;

function TAlmacenTienda.Devolver(const AArticulo: string; ACantidad: Integer;
  AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
begin
  FStockPropio.AddOrSetValue(AArticulo, StockPropio(AArticulo) + ACantidad);
  oEvento := Default(TEventoStock);
  oEvento.Tipo := teDevolucion;
  oEvento.Articulo := AArticulo;
  oEvento.Almacen := FAlmacen;
  oEvento.Cantidad := ACantidad;
  oEvento.Instante := AInstante;
  Result := Encolar(oEvento);
end;

function TAlmacenTienda.TraspasoSalida(const AArticulo, ADestino: string;
  ACantidad: Integer; AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
begin
  FStockPropio.AddOrSetValue(AArticulo, StockPropio(AArticulo) - ACantidad);
  oEvento := Default(TEventoStock);
  oEvento.Tipo := teTraspasoSalida;
  oEvento.Articulo := AArticulo;
  oEvento.Almacen := FAlmacen;
  oEvento.AlmacenDestino := ADestino;
  oEvento.IdTraspaso := NuevoId;
  oEvento.Cantidad := ACantidad;
  oEvento.Instante := AInstante;
  Result := Encolar(oEvento);
end;

function TAlmacenTienda.TraspasoRecepcion(const AIdTraspaso: string;
  AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
  iIndice: Integer;
  oPendiente: TTraspasoPendiente;
begin
  Result := Default(TEventoStock);
  for iIndice := 0 to FTraspasosPendientes.Count - 1 do
    if FTraspasosPendientes[iIndice].IdTraspaso = AIdTraspaso then
    begin
      oPendiente := FTraspasosPendientes[iIndice];
      FTraspasosPendientes.Delete(iIndice);
      FStockPropio.AddOrSetValue(oPendiente.Articulo,
        StockPropio(oPendiente.Articulo) + oPendiente.Cantidad);
      oEvento := Default(TEventoStock);
      oEvento.Tipo := teTraspasoRecepcion;
      oEvento.Articulo := oPendiente.Articulo;
      oEvento.Almacen := FAlmacen;
      oEvento.IdTraspaso := AIdTraspaso;
      oEvento.Cantidad := oPendiente.Cantidad;
      oEvento.Instante := AInstante;
      Result := Encolar(oEvento);
      Exit;
    end;
  raise Exception.Create('Traspaso no pendiente: ' + AIdTraspaso);
end;

function TAlmacenTienda.Inventario(const AArticulo: string;
  AContado: Integer; AInstante: Int64): TEventoStock;
var
  oEvento: TEventoStock;
begin
  oEvento := Default(TEventoStock);
  oEvento.Tipo := teInventario;
  oEvento.Articulo := AArticulo;
  oEvento.Almacen := FAlmacen;
  oEvento.Contado := AContado;
  oEvento.Cantidad := AContado - StockPropio(AArticulo); // ajuste
  oEvento.Instante := AInstante;
  FStockPropio.AddOrSetValue(AArticulo, AContado);
  Result := Encolar(oEvento);
end;

function TAlmacenTienda.Pendientes(AAhora: Int64;
  AMaximo: Integer): TEventosStock;
var
  iIndice, iCuenta: Integer;
begin
  // En orden de secuencia; se detiene en el primer pendiente que aún
  // está en espera, para no enviar huecos.
  Result := nil;
  iCuenta := 0;
  for iIndice := 0 to FBandeja.Count - 1 do
  begin
    if iCuenta >= AMaximo then
      Break;
    if FBandeja[iIndice].Estado = eePendiente then
    begin
      if FBandeja[iIndice].ProximoIntento > AAhora then
        Break;
      SetLength(Result, iCuenta + 1);
      Result[iCuenta] := FBandeja[iIndice].Evento;
      Inc(iCuenta);
    end;
  end;
end;

function TAlmacenTienda.NumeroPendientes: Integer;
var
  iIndice: Integer;
begin
  Result := 0;
  for iIndice := 0 to FBandeja.Count - 1 do
    if FBandeja[iIndice].Estado = eePendiente then
      Inc(Result);
end;

function TAlmacenTienda.Buscar(const AIdEvento: string): TEntradaBandeja;
begin
  if not FIndice.TryGetValue(AIdEvento, Result) then
    Result := nil;
end;

procedure TAlmacenTienda.AplicarNovedad(const ANovedad: TNovedadStock;
  AAhora: Int64);
var
  oCopia: TCopiaStock;
  oPendiente: TTraspasoPendiente;
  oAviso: TAvisoSobreventa;
  oLatencia: TLatencia;
begin
  // Cambio y cursor en la misma transacción.
  case ANovedad.Tipo of
    tnArticulo:
      FArticulos.AddOrSetValue(ANovedad.Articulo, ANovedad.Precio);
    tnStock:
      // El stock propio no se toma de la central: sale de los propios
      // eventos y es exacto. La copia guarda todos los demás almacenes.
      if ANovedad.Almacen <> FAlmacen then
      begin
        oCopia.Cantidad := ANovedad.Cantidad;
        oCopia.Version := ANovedad.Version;
        oCopia.InstantePublicado := ANovedad.Instante;
        oCopia.InstanteAplicado := AAhora;
        FCopia.AddOrSetValue(ClaveStock(ANovedad.Articulo, ANovedad.Almacen),
          oCopia);
      end;
    tnTraspasoEnTransito:
      if ANovedad.Almacen = FAlmacen then
      begin
        oPendiente.IdTraspaso := ANovedad.IdTraspaso;
        oPendiente.Articulo := ANovedad.Articulo;
        oPendiente.Origen := ANovedad.AlmacenOrigen;
        oPendiente.Cantidad := ANovedad.Cantidad;
        oPendiente.InstanteAviso := AAhora;
        FTraspasosPendientes.Add(oPendiente);
      end;
    tnTraspasoRecibido:
      ; // informativo para el origen
    tnSobreventa:
      begin
        oAviso.Version := ANovedad.Version;
        oAviso.Terminal := ANovedad.Terminal;
        oAviso.Articulo := ANovedad.Articulo;
        oAviso.Almacen := ANovedad.Almacen;
        oAviso.Stock := ANovedad.Cantidad;
        oAviso.InstanteRecibido := AAhora;
        FSobreventas.Add(oAviso);
      end;
  end;
  if ANovedad.Terminal <> FTerminal then
  begin
    oLatencia.Version := ANovedad.Version;
    oLatencia.Tipo := ANovedad.Tipo;
    oLatencia.InstantePublicado := ANovedad.Instante;
    oLatencia.Latencia := AAhora - ANovedad.Instante;
    FLatencias.Add(oLatencia);
  end;
  FCursor := ANovedad.Version;
end;

function TAlmacenTienda.StockPropio(const AArticulo: string): Integer;
begin
  if not FStockPropio.TryGetValue(AArticulo, Result) then
    Result := 0;
end;

function TAlmacenTienda.TieneCopia(const AArticulo, AAlmacen: string;
  out ACopia: TCopiaStock): Boolean;
begin
  Result := FCopia.TryGetValue(ClaveStock(AArticulo, AAlmacen), ACopia);
end;

function TAlmacenTienda.TraspasoPendiente(
  AIndice: Integer): TTraspasoPendiente;
begin
  Result := FTraspasosPendientes[AIndice];
end;

{ TClienteTienda }

constructor TClienteTienda.Create(AAlmacen: TAlmacenTienda;
  const AServicio: IServicioStock);
begin
  inherited Create;
  FAlmacen := AAlmacen;
  FServicio := AServicio;
  FTamanoLote := 20;
  FTamanoPagina := 100;
  FEsperaMaxima := 60;
  FReintentosReserva := 2;
end;

function TClienteTienda.EsperaReintento(AIntentos: Integer): Int64;
begin
  Result := 1;
  while (AIntentos > 1) and (Result < FEsperaMaxima) do
  begin
    Result := Result * 2;
    Dec(AIntentos);
  end;
  if Result > FEsperaMaxima then
    Result := FEsperaMaxima;
end;

function TClienteTienda.Vender(const AArticulo, AAlmacen: string;
  ACantidad: Integer; AAhora: Int64): TResultadoVentaTienda;
var
  sIdReserva: string;
  oRespuesta: TRespuestaReserva;
  iIntento: Integer;
begin
  if AAlmacen = FAlmacen.Almacen then
  begin
    // Almacén propio: nadie más lo mueve, no hace falta reservar.
    FAlmacen.Vender(AArticulo, AAlmacen, ACantidad, '', AAhora);
    Inc(FEstadisticas.VentasPropias);
    Exit(vtVendida);
  end;
  // Almacén compartido: reserva atómica en la central si hay red. Un
  // paquete perdido no basta para pasar a modo sin conexión: se reintenta
  // la reserva con el MISMO id (es idempotente) antes de vender con riesgo.
  sIdReserva := NuevoId;
  for iIntento := 1 to FReintentosReserva do
    try
      oRespuesta := FServicio.Reservar(FAlmacen.Terminal, sIdReserva,
        AArticulo, AAlmacen, ACantidad);
      if oRespuesta.Resultado = rrConcedida then
      begin
        FAlmacen.Vender(AArticulo, AAlmacen, ACantidad, sIdReserva, AAhora);
        Inc(FEstadisticas.VentasConReserva);
        Exit(vtVendidaConReserva);
      end;
      Inc(FEstadisticas.VentasBloqueadas);
      Exit(vtBloqueadaSinStock);
    except
      on E: ETransporteSincro do
        FUltimoError := E.Message;
    end;
  // Sin respuesta de la central: se vende con riesgo. Puede que la
  // reserva se haya creado y la respuesta se perdiera: la venta lleva el
  // id de reserva para que la central la consuma. Si la reserva no
  // existe, la central la trata como venta sin reserva. Así no quedan
  // reservas huérfanas restando disponible.
  FAlmacen.Vender(AArticulo, AAlmacen, ACantidad, sIdReserva, AAhora);
  Inc(FEstadisticas.VentasSinConexion);
  Result := vtVendidaSinConexion;
end;

function TClienteTienda.ConsultarStock(const AArticulo, AAlmacen: string;
  AAhora: Int64): TResultadoConsulta;
var
  oConsulta: TConsultaStock;
  oCopia: TCopiaStock;
begin
  Result := Default(TResultadoConsulta);
  if AAlmacen = FAlmacen.Almacen then
  begin
    Result.Cantidad := FAlmacen.StockPropio(AArticulo);
    Result.Fuente := fcPropio;
    Inc(FEstadisticas.ConsultasPropias);
    Exit;
  end;
  try
    oConsulta := FServicio.ConsultarStock(AArticulo, AAlmacen);
    Result.Cantidad := oConsulta.Cantidad;
    Result.Fuente := fcEnLinea;
    Inc(FEstadisticas.ConsultasEnLinea);
    Exit;
  except
    on E: ETransporteSincro do
      ; // respaldo local
  end;
  if FAlmacen.TieneCopia(AArticulo, AAlmacen, oCopia) then
  begin
    Result.Cantidad := oCopia.Cantidad;
    Result.Fuente := fcCopiaLocal;
    Result.Antiguedad := AAhora - FAlmacen.UltimaSincroOk;
    Inc(FEstadisticas.ConsultasCopia);
  end
  else
  begin
    Result.Fuente := fcSinDato;
    Result.Antiguedad := AAhora - FAlmacen.UltimaSincroOk;
    Inc(FEstadisticas.ConsultasSinDato);
  end;
end;

function TClienteTienda.SubirEventos(AAhora: Int64): Boolean;
var
  aLote: TEventosStock;
  oRespuesta: TRespuestaEventos;
  oEntrada: TEntradaBandeja;
  iIndice: Integer;
begin
  Result := True;
  aLote := FAlmacen.Pendientes(AAhora, FTamanoLote);
  while Length(aLote) > 0 do
  begin
    Inc(FEstadisticas.LotesEnviados);
    try
      oRespuesta := FServicio.EnviarEventos(FAlmacen.Terminal, aLote);
    except
      on E: ETransporteSincro do
      begin
        Inc(FEstadisticas.FallosEnvio);
        FUltimoError := E.Message;
        for iIndice := 0 to High(aLote) do
        begin
          oEntrada := FAlmacen.Buscar(aLote[iIndice].IdEvento);
          Inc(oEntrada.Intentos);
          oEntrada.ProximoIntento :=
            AAhora + EsperaReintento(oEntrada.Intentos);
        end;
        Exit(False);
      end;
    end;
    for iIndice := 0 to High(oRespuesta.Acks) do
    begin
      oEntrada := FAlmacen.Buscar(oRespuesta.Acks[iIndice].IdEvento);
      if (oEntrada = nil) or (oEntrada.Estado <> eePendiente) then
        Continue;
      case oRespuesta.Acks[iIndice].Resultado of
        reAceptado, reRepetido:
          begin
            oEntrada.Estado := eeConfirmado;
            Inc(FEstadisticas.EventosConfirmados);
          end;
        reRechazado:
          begin
            oEntrada.Estado := eeRechazado;
            oEntrada.Motivo := oRespuesta.Acks[iIndice].Motivo;
            Inc(FEstadisticas.EventosRechazados);
          end;
        reFueraDeOrden:
          Inc(FEstadisticas.EventosFueraDeOrden);
      end;
    end;
    for iIndice := 0 to High(aLote) do
    begin
      oEntrada := FAlmacen.Buscar(aLote[iIndice].IdEvento);
      if oEntrada.Estado = eePendiente then
      begin
        Inc(oEntrada.Intentos);
        oEntrada.ProximoIntento :=
          AAhora + EsperaReintento(oEntrada.Intentos);
      end;
    end;
    aLote := FAlmacen.Pendientes(AAhora, FTamanoLote);
  end;
end;

function TClienteTienda.BajarNovedades(AAhora: Int64): Boolean;
var
  oRespuesta: TRespuestaNovedadesStock;
  iIndice: Integer;
  bCompleta: Boolean;
begin
  Result := True;
  bCompleta := False;
  repeat
    try
      oRespuesta := FServicio.PedirNovedades(
        FAlmacen.Terminal, FAlmacen.Cursor, FTamanoPagina);
    except
      on E: ETransporteSincro do
      begin
        Inc(FEstadisticas.FallosNovedades);
        FUltimoError := E.Message;
        Result := False;
        Break;
      end;
    end;
    for iIndice := 0 to High(oRespuesta.Novedades) do
      if oRespuesta.Novedades[iIndice].Version > FAlmacen.Cursor then
      begin
        FAlmacen.AplicarNovedad(oRespuesta.Novedades[iIndice], AAhora);
        Inc(FEstadisticas.NovedadesAplicadas);
      end;
    bCompleta := not oRespuesta.HayMas;
  until bCompleta;
  if bCompleta then
    FAlmacen.UltimaSincroOk := AAhora; // la copia está al día a esta hora
  if FAlmacen.Cursor > FCursorConfirmado then
    try
      FServicio.ConfirmarNovedades(FAlmacen.Terminal, FAlmacen.Cursor);
      FCursorConfirmado := FAlmacen.Cursor;
    except
      on E: ETransporteSincro do
      begin
        FUltimoError := E.Message;
        Result := False;
      end;
    end;
end;

function TClienteTienda.Sincronizar(AAhora: Int64): Boolean;
var
  bSubida, bBajada: Boolean;
begin
  Inc(FEstadisticas.Ciclos);
  FUltimoError := '';
  bSubida := SubirEventos(AAhora);
  bBajada := BajarNovedades(AAhora);
  Result := bSubida and bBajada;
end;

end.
