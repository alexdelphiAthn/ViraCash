{******************************************************************************}
{                                                                              }
{  Programa:     PruebasStock                                                  }
{    Tipo:       Pruebas de consola                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Escenarios deterministas del protocolo de stock: orden de secuencia,     }
{    stock como suma de movimientos, traspasos, inventario con ventas sin     }
{    conexión, reserva de la última unidad, sobreventa sin conexión, reserva  }
{    con respuesta perdida, consulta con respaldo local, alta de artículo en  }
{    tienda, reinicio y cambio de precio. Código de salida 0 si todo pasa.    }
{******************************************************************************}
program PruebasStock;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}
{$APPTYPE CONSOLE}

uses
  {$IFDEF FPC}
  SysUtils,
  {$ELSE}
  System.SysUtils,
  {$ENDIF}
  inLibSincroProtocolo in 'inLibSincroProtocolo.pas',
  inLibSincroTransporteSimulado in 'inLibSincroTransporteSimulado.pas',
  inLibSincroStockProtocolo in 'inLibSincroStockProtocolo.pas',
  inLibSincroStockServidor in 'inLibSincroStockServidor.pas',
  inLibSincroStockCliente in 'inLibSincroStockCliente.pas',
  inLibSincroStockTransporte in 'inLibSincroStockTransporte.pas';

type
  TTiendaPrueba = record
    Almacen: TAlmacenTienda;
    Transporte: TTransporteStock;
    Servicio: IServicioStock;
    Cliente: TClienteTienda;
  end;

  TEntorno = record
    CentralObj: TServidorStock;
    Central: IServicioStock;
    T1, T2: TTiendaPrueba;
  end;

var
  iPruebas, iFallos: Integer;
  sPrueba: string;

procedure Comprobar(ACondicion: Boolean; const ATexto: string);
begin
  if not ACondicion then
  begin
    Inc(iFallos);
    Writeln('    [FALLO] ', sPrueba, ': ', ATexto);
  end;
end;

procedure CrearTienda(const AEntorno: TEntorno; const ANombre,
  AAlmacen: string; ASemilla: UInt64; out ATienda: TTiendaPrueba);
begin
  ATienda.Almacen := TAlmacenTienda.Create(ANombre, AAlmacen);
  ATienda.Transporte := TTransporteStock.Create(AEntorno.Central, ASemilla);
  ATienda.Servicio := ATienda.Transporte;
  ATienda.Cliente := TClienteTienda.Create(ATienda.Almacen, ATienda.Servicio);
end;

procedure Iniciar(const ANombre: string; out AEntorno: TEntorno);
begin
  sPrueba := ANombre;
  Inc(iPruebas);
  AEntorno.CentralObj := TServidorStock.Create;
  AEntorno.Central := AEntorno.CentralObj;
  // Catálogo de partida: dos artículos, stock en cada almacén y 1 unidad
  // en el almacén compartido.
  AEntorno.CentralObj.CrearArticulo('A', 10);
  AEntorno.CentralObj.CrearArticulo('B', 20);
  AEntorno.CentralObj.CargarStock('A', 'ALM1', 10);
  AEntorno.CentralObj.CargarStock('A', 'ALM2', 5);
  AEntorno.CentralObj.CargarStock('A', CAlmacenCompartido, 1);
  AEntorno.CentralObj.CargarStock('B', 'ALM1', 3);
  CrearTienda(AEntorno, 'TIENDA1', 'ALM1', 1, AEntorno.T1);
  CrearTienda(AEntorno, 'TIENDA2', 'ALM2', 2, AEntorno.T2);
  AEntorno.T1.Cliente.Sincronizar(0);
  AEntorno.T2.Cliente.Sincronizar(0);
  AEntorno.T1.Almacen.StockPropioTabla.AddOrSetValue('A', 10);
  AEntorno.T1.Almacen.StockPropioTabla.AddOrSetValue('B', 3);
  AEntorno.T2.Almacen.StockPropioTabla.AddOrSetValue('A', 5);
end;

procedure LiberarTienda(var ATienda: TTiendaPrueba);
begin
  ATienda.Cliente.Free;
  ATienda.Servicio := nil;
  ATienda.Almacen.Free;
end;

procedure Terminar(var AEntorno: TEntorno; AFallosPrevios: Integer);
begin
  LiberarTienda(AEntorno.T1);
  LiberarTienda(AEntorno.T2);
  AEntorno.Central := nil;
  if iFallos = AFallosPrevios then
    Writeln('  [ OK  ] ', sPrueba)
  else
    Writeln('  [FALLO] ', sPrueba);
end;

procedure SincronizarTodo(var AEntorno: TEntorno; AAhora: Int64);
begin
  AEntorno.CentralObj.Reloj := AAhora;
  AEntorno.T1.Cliente.Sincronizar(AAhora);
  AEntorno.T2.Cliente.Sincronizar(AAhora);
  AEntorno.T1.Cliente.Sincronizar(AAhora);
end;

function Evento(const ATerminal: string; ASecuencia: Int64;
  const AArticulo: string; ACantidad: Integer): TEventoStock;
begin
  Result := Default(TEventoStock);
  Result.IdEvento := ATerminal + '-' + IntToStr(ASecuencia);
  Result.Terminal := ATerminal;
  Result.Secuencia := ASecuencia;
  Result.Tipo := teVenta;
  Result.Articulo := AArticulo;
  Result.Almacen := 'ALM1';
  Result.Cantidad := ACantidad;
end;

procedure PruebaOrdenDeSecuencia;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  aLote: TEventosStock;
  oRespuesta: TRespuestaEventos;
begin
  iPrevios := iFallos;
  Iniciar('Secuencia: un hueco deja el evento FUERA_DE_ORDEN sin aplicarlo', oEnt);
  SetLength(aLote, 1);
  aLote[0] := Evento('TIENDA1', 2, 'A', 1);
  oRespuesta := oEnt.Central.EnviarEventos('TIENDA1', aLote);
  Comprobar(oRespuesta.Acks[0].Resultado = reFueraDeOrden,
    'la secuencia 2 sin la 1 debe quedar fuera de orden');
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM1') = 10, 'no debe aplicarse');
  SetLength(aLote, 3);
  aLote[0] := Evento('TIENDA1', 1, 'A', 1);
  aLote[1] := Evento('TIENDA1', 2, 'A', 1);
  aLote[2] := Evento('TIENDA1', 3, 'Z', 1); // artículo inexistente
  oRespuesta := oEnt.Central.EnviarEventos('TIENDA1', aLote);
  Comprobar((oRespuesta.Acks[0].Resultado = reAceptado) and
            (oRespuesta.Acks[1].Resultado = reAceptado),
    'con la 1 presente, 1 y 2 se aceptan en el mismo lote');
  Comprobar(oRespuesta.Acks[2].Resultado = reRechazado,
    'el articulo inexistente se rechaza');
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM1') = 8, 'stock 10 - 2');
  SetLength(aLote, 1);
  aLote[0] := Evento('TIENDA1', 4, 'A', 1);
  oRespuesta := oEnt.Central.EnviarEventos('TIENDA1', aLote);
  Comprobar(oRespuesta.Acks[0].Resultado = reAceptado,
    'un rechazo consume su secuencia y no bloquea la siguiente');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaStockComoSumaDeMovimientos;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Stock central = suma de movimientos (venta, compra, devolucion)', oEnt);
  oEnt.T1.Almacen.Vender('A', 'ALM1', 2, '', 1);
  oEnt.T1.Almacen.Comprar('A', 7, 2);
  oEnt.T1.Almacen.Devolver('A', 1, 3);
  Comprobar(oEnt.T1.Almacen.StockPropio('A') = 16,
    'el stock propio se calcula localmente sin red: 10-2+7+1');
  SincronizarTodo(oEnt, 10);
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM1') = 16, 'la central da 16');
  Comprobar(oEnt.CentralObj.StockPorMovimientos('A', 'ALM1') = 16,
    'y coincide con la suma de movimientos');
  Comprobar(oEnt.T2.Almacen.Copia.ContainsKey(ClaveStock('A', 'ALM1')) and
    (oEnt.T2.Almacen.Copia[ClaveStock('A', 'ALM1')].Cantidad = 16),
    'la otra tienda ve 16 en su copia');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaTraspaso;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  oPendiente: TTraspasoPendiente;
begin
  iPrevios := iFallos;
  Iniciar('Traspaso: salida a TRANSITO, aviso al destino, recepcion', oEnt);
  oEnt.T1.Almacen.TraspasoSalida('A', 'ALM2', 3, 1);
  Comprobar(oEnt.T1.Almacen.StockPropio('A') = 7, 'origen descuenta al salir');
  SincronizarTodo(oEnt, 2);
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM1') = 7, 'central: origen 7');
  Comprobar(oEnt.CentralObj.Stock('A', CAlmacenTransito) = 3,
    'central: 3 en transito');
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM2') = 5,
    'central: destino sin cambios hasta recibir');
  Comprobar(oEnt.T2.Almacen.TraspasosPendientes.Count = 1,
    'el destino sabe que le llega un traspaso');
  oPendiente := oEnt.T2.Almacen.TraspasoPendiente(0);
  Comprobar((oPendiente.Articulo = 'A') and (oPendiente.Cantidad = 3) and
    (oPendiente.Origen = 'ALM1'), 'con articulo, cantidad y origen');
  oEnt.T2.Almacen.TraspasoRecepcion(oPendiente.IdTraspaso, 3);
  Comprobar(oEnt.T2.Almacen.StockPropio('A') = 8, 'destino suma al recibir');
  SincronizarTodo(oEnt, 4);
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM2') = 8, 'central: destino 8');
  Comprobar(oEnt.CentralObj.Stock('A', CAlmacenTransito) = 0,
    'central: transito a cero');
  Comprobar(oEnt.CentralObj.TraspasosEnTransito = 0, 'ningun traspaso abierto');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaInventarioConVentasSinConexion;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  oEvento: TEventoStock;
begin
  iPrevios := iFallos;
  Iniciar('Inventario sin conexion: se envia el ajuste y no se pierden ventas', oEnt);
  oEnt.T1.Transporte.Conectado := False;
  oEnt.T1.Almacen.Vender('A', 'ALM1', 2, '', 1);        // teórico 8
  oEvento := oEnt.T1.Almacen.Inventario('A', 7, 2);     // contadas 7
  Comprobar(oEvento.Cantidad = -1, 'el ajuste es contado - teorico = -1');
  Comprobar(oEvento.Contado = 7, 'se conserva el recuento');
  oEnt.T1.Almacen.Vender('A', 'ALM1', 1, '', 3);        // 6
  Comprobar(oEnt.T1.Almacen.StockPropio('A') = 6, 'local 6');
  oEnt.T1.Cliente.Sincronizar(4);
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM1') = 10, 'la central sigue en 10');
  oEnt.T1.Transporte.Conectado := True;
  SincronizarTodo(oEnt, 100);
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM1') = 6,
    'la central aplica venta, ajuste y venta: 10-2-1-1 = 6');
  Comprobar(oEnt.CentralObj.StockPorMovimientos('A', 'ALM1') = 6,
    'y cuadra con los movimientos');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaReservaUltimaUnidad;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Reserva en linea: la ultima unidad de CENTRAL solo se vende una vez', oEnt);
  Comprobar(oEnt.T1.Cliente.Vender('A', CAlmacenCompartido, 1, 1) =
    vtVendidaConReserva, 'la primera tienda la reserva');
  Comprobar(oEnt.T2.Cliente.Vender('A', CAlmacenCompartido, 1, 1) =
    vtBloqueadaSinStock, 'la segunda queda bloqueada al instante');
  Comprobar(oEnt.CentralObj.Disponible('A', CAlmacenCompartido) = 0,
    'disponible 0 aunque la venta aun no ha llegado');
  Comprobar(oEnt.CentralObj.Stock('A', CAlmacenCompartido) = 1,
    'el stock no baja hasta que llega la venta');
  SincronizarTodo(oEnt, 2);
  Comprobar(oEnt.CentralObj.Stock('A', CAlmacenCompartido) = 0, 'stock 0');
  Comprobar(oEnt.CentralObj.Disponible('A', CAlmacenCompartido) = 0,
    'la reserva se consumio: disponible sigue 0, no -1');
  Comprobar(oEnt.CentralObj.Sobreventas.Count = 0, 'sin sobreventa');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaSobreventaSinConexion;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Sin conexion se vende con riesgo y la central avisa de la sobreventa', oEnt);
  oEnt.T2.Transporte.Conectado := False;
  Comprobar(oEnt.T2.Cliente.Vender('A', CAlmacenCompartido, 1, 1) =
    vtVendidaSinConexion, 'la tienda sin red vende con riesgo');
  Comprobar(oEnt.T1.Cliente.Vender('A', CAlmacenCompartido, 1, 1) =
    vtVendidaConReserva, 'la tienda con red reserva la misma unidad');
  SincronizarTodo(oEnt, 2);
  Comprobar(oEnt.CentralObj.Sobreventas.Count = 0,
    'mientras la venta sin red no llega, no hay sobreventa');
  oEnt.T2.Transporte.Conectado := True;
  SincronizarTodo(oEnt, 100);
  Comprobar(oEnt.CentralObj.Stock('A', CAlmacenCompartido) = -1,
    'al llegar, el stock queda en -1');
  Comprobar(oEnt.CentralObj.Sobreventas.Count = 1, 'una sobreventa');
  Comprobar((oEnt.CentralObj.Sobreventas.Count = 1) and
    (oEnt.CentralObj.Sobreventas[0].Terminal = 'TIENDA2') and
    not oEnt.CentralObj.Sobreventas[0].ConReserva,
    'atribuida a la tienda sin red y sin reserva');
  Comprobar((oEnt.T1.Almacen.Sobreventas.Count = 1) and
    (oEnt.T2.Almacen.Sobreventas.Count = 1),
    'las dos tiendas reciben el aviso');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaReservaConRespuestaPerdida;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Reserva con respuesta perdida: se reintenta con el mismo id', oEnt);
  oEnt.T1.Transporte.ForzarFallo(ffRespuestaPerdida);
  Comprobar(oEnt.T1.Cliente.Vender('A', CAlmacenCompartido, 1, 1) =
    vtVendidaConReserva, 'el reintento recupera la reserva ya creada');
  Comprobar(oEnt.CentralObj.Estadisticas.ReservasConcedidas = 1,
    'solo se creo una reserva');
  Comprobar(oEnt.CentralObj.Disponible('A', CAlmacenCompartido) = 0,
    'disponible 0');
  SincronizarTodo(oEnt, 2);
  Comprobar(oEnt.CentralObj.Disponible('A', CAlmacenCompartido) = 0,
    'tras la venta no queda reserva huerfana: disponible 0, no -1');
  Comprobar(oEnt.CentralObj.Sobreventas.Count = 0, 'sin sobreventa');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaReservaSinNingunaRespuesta;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Reserva creada pero sin respuesta alguna: la venta la consume', oEnt);
  oEnt.T1.Cliente.ReintentosReserva := 1;
  oEnt.T1.Transporte.ForzarFallo(ffRespuestaPerdida);
  Comprobar(oEnt.T1.Cliente.Vender('A', CAlmacenCompartido, 1, 1) =
    vtVendidaSinConexion, 'sin respuesta, la tienda vende con riesgo');
  Comprobar(oEnt.CentralObj.Disponible('A', CAlmacenCompartido) = 0,
    'la central si creo la reserva');
  SincronizarTodo(oEnt, 2);
  Comprobar(oEnt.CentralObj.Stock('A', CAlmacenCompartido) = 0, 'stock 0');
  Comprobar(oEnt.CentralObj.Disponible('A', CAlmacenCompartido) = 0,
    'la venta llevo el id y consumio la reserva: disponible 0, no -1');
  Comprobar(oEnt.CentralObj.Sobreventas.Count = 0,
    'y no cuenta como sobreventa');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaConsultaConRespaldo;
var
  oEnt: TEntorno;
  iPrevios: Integer;
  oConsulta: TResultadoConsulta;
begin
  iPrevios := iFallos;
  Iniciar('Consulta de stock: en linea exacta; sin red, copia con antiguedad', oEnt);
  oConsulta := oEnt.T2.Cliente.ConsultarStock('A', 'ALM2', 5);
  Comprobar((oConsulta.Fuente = fcPropio) and (oConsulta.Cantidad = 5),
    'el almacen propio es exacto y local');
  oEnt.T1.Almacen.Vender('A', 'ALM1', 4, '', 5);   // ALM1 pasa a 6
  oEnt.T1.Cliente.Sincronizar(5);
  oEnt.CentralObj.Reloj := 5;
  oConsulta := oEnt.T2.Cliente.ConsultarStock('A', 'ALM1', 5);
  Comprobar((oConsulta.Fuente = fcEnLinea) and (oConsulta.Cantidad = 6),
    'en linea devuelve 6 aunque TIENDA2 no haya sincronizado');
  oEnt.T2.Transporte.Conectado := False;
  oConsulta := oEnt.T2.Cliente.ConsultarStock('A', 'ALM1', 65);
  Comprobar((oConsulta.Fuente = fcCopiaLocal) and (oConsulta.Cantidad = 10),
    'sin red devuelve la copia (10, anterior a la venta)');
  Comprobar(oConsulta.Antiguedad = 65,
    'y declara la antiguedad desde la ultima bajada completa (65 s)');
  oConsulta := oEnt.T2.Cliente.ConsultarStock('B', CAlmacenCompartido, 65);
  Comprobar(oConsulta.Fuente = fcSinDato,
    'sin copia de ese articulo/almacen, lo dice en vez de inventar un 0');
  oEnt.T2.Transporte.Conectado := True;
  oEnt.T2.Cliente.Sincronizar(70);
  oEnt.T2.Transporte.Conectado := False;
  oConsulta := oEnt.T2.Cliente.ConsultarStock('A', 'ALM1', 72);
  Comprobar((oConsulta.Cantidad = 6) and (oConsulta.Antiguedad = 2),
    'tras sincronizar, la copia esta al dia y tiene 2 s');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaAltaDeArticuloEnTienda;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Alta de articulo en tienda: alta, compra y venta en el mismo lote', oEnt);
  oEnt.T1.Almacen.AltaArticulo('ALM1-NUEVO01', 15, 1);
  oEnt.T1.Almacen.Comprar('ALM1-NUEVO01', 10, 1);
  oEnt.T1.Almacen.Vender('ALM1-NUEVO01', 'ALM1', 1, '', 2);
  SincronizarTodo(oEnt, 3);
  Comprobar(oEnt.CentralObj.Articulos.ContainsKey('ALM1-NUEVO01'),
    'la central conoce el articulo');
  Comprobar(oEnt.CentralObj.Stock('ALM1-NUEVO01', 'ALM1') = 9,
    'y su stock 10-1 (el orden de secuencia lo garantiza)');
  Comprobar(oEnt.T2.Almacen.Articulos.ContainsKey('ALM1-NUEVO01') and
    (oEnt.T2.Almacen.Articulos['ALM1-NUEVO01'] = 15),
    'la otra tienda lo recibe con su precio');
  Comprobar(oEnt.T1.Almacen.NumeroPendientes = 0, 'todo confirmado');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaReinicio;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Reinicio de la tienda: conserva bandeja, stock, copia y traspasos', oEnt);
  oEnt.T1.Almacen.TraspasoSalida('A', 'ALM2', 2, 1);
  SincronizarTodo(oEnt, 1);
  oEnt.T2.Transporte.Conectado := False;
  oEnt.T2.Almacen.Vender('A', 'ALM2', 1, '', 2);
  oEnt.T2.Cliente.Sincronizar(2);
  oEnt.T2.Cliente.Free;
  oEnt.T2.Cliente := TClienteTienda.Create(oEnt.T2.Almacen, oEnt.T2.Servicio);
  Comprobar(oEnt.T2.Almacen.NumeroPendientes = 1, 'la venta sigue pendiente');
  Comprobar(oEnt.T2.Almacen.StockPropio('A') = 4, 'stock propio 4');
  Comprobar(oEnt.T2.Almacen.TraspasosPendientes.Count = 1,
    'el traspaso por recibir sigue ahi');
  Comprobar(oEnt.T2.Almacen.Cursor = oEnt.CentralObj.UltimaVersion,
    'el cursor no se pierde');
  oEnt.T2.Transporte.Conectado := True;
  oEnt.T2.Almacen.TraspasoRecepcion(
    oEnt.T2.Almacen.TraspasoPendiente(0).IdTraspaso, 100);
  SincronizarTodo(oEnt, 100);
  Comprobar(oEnt.CentralObj.Stock('A', 'ALM2') = 6, 'central: 5-1+2 = 6');
  Comprobar(oEnt.T2.Almacen.StockPropio('A') = 6, 'local: 6');
  Comprobar(oEnt.CentralObj.TraspasosEnTransito = 0, 'nada en transito');
  Terminar(oEnt, iPrevios);
end;

procedure PruebaCambioDePrecio;
var
  oEnt: TEntorno;
  iPrevios: Integer;
begin
  iPrevios := iFallos;
  Iniciar('Cambio de precio en la central: llega a las tiendas, con red o al volver', oEnt);
  oEnt.T2.Transporte.Conectado := False;
  oEnt.CentralObj.CambiarPrecio('A', 12.5);
  oEnt.T1.Cliente.Sincronizar(1);
  oEnt.T2.Cliente.Sincronizar(1);
  Comprobar(oEnt.T1.Almacen.Articulos['A'] = 12.5, 'TIENDA1 lo tiene ya');
  Comprobar(oEnt.T2.Almacen.Articulos['A'] = 10, 'TIENDA2 sigue con el viejo');
  oEnt.T2.Transporte.Conectado := True;
  oEnt.T2.Cliente.Sincronizar(2);
  Comprobar(oEnt.T2.Almacen.Articulos['A'] = 12.5, 'y lo recibe al volver');
  Terminar(oEnt, iPrevios);
end;

begin
  iPruebas := 0;
  iFallos := 0;
  Writeln('Pruebas del protocolo de stock multitienda');
  PruebaOrdenDeSecuencia;
  PruebaStockComoSumaDeMovimientos;
  PruebaTraspaso;
  PruebaInventarioConVentasSinConexion;
  PruebaReservaUltimaUnidad;
  PruebaSobreventaSinConexion;
  PruebaReservaConRespuestaPerdida;
  PruebaReservaSinNingunaRespuesta;
  PruebaConsultaConRespaldo;
  PruebaAltaDeArticuloEnTienda;
  PruebaReinicio;
  PruebaCambioDePrecio;
  Writeln;
  Writeln(Format('%d pruebas, %d comprobaciones fallidas', [iPruebas, iFallos]));
  if iFallos > 0 then
    ExitCode := 1;
end.
