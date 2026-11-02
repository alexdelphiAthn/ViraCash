{******************************************************************************}
{                                                                              }
{  Programa:     SimulacionStock                                               }
{    Tipo:       Simulación de consola                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tres tiendas con base de datos local y una central. Cada tienda vende    }
{    de su almacén y del almacén compartido CENTRAL, compra, devuelve, hace   }
{    traspasos, inventarios, da de alta artículos y consulta el stock de las  }
{    demás. La red pierde mensajes, se corta y una tienda se reinicia.        }
{                                                                              }
{    Un tick es un segundo. Con conexión, cada tienda sincroniza en cada      }
{    tick (equivale a una espera larga en la petición de novedades).           }
{                                                                              }
{    Al final se verifica la INTEGRIDAD (stock central = suma de movimientos, }
{    stock propio de cada tienda = central, copias = central, cero traspasos   }
{    en tránsito, cero sobreventas con reserva) y se informa de la VIGENCIA   }
{    (latencia de cada cambio hasta verse en las demás tiendas y exactitud    }
{    de las consultas).                                                        }
{                                                                              }
{    Uso: SimulacionStock [semilla] [ticks] [detalle]                         }
{      detalle = 1 muestra además la cronología de cada incidencia.          }
{    Código de salida 0 si se cumplen todas las invariantes, 1 si no.          }
{******************************************************************************}
program SimulacionStock;

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}
{$APPTYPE CONSOLE}

uses
  {$IFDEF FPC}
  SysUtils, Generics.Collections,
  {$ELSE}
  System.SysUtils, System.Generics.Collections,
  {$ENDIF}
  inLibSincroProtocolo in 'inLibSincroProtocolo.pas',
  inLibSincroTransporteSimulado in 'inLibSincroTransporteSimulado.pas',
  inLibSincroStockProtocolo in 'inLibSincroStockProtocolo.pas',
  inLibSincroStockServidor in 'inLibSincroStockServidor.pas',
  inLibSincroStockCliente in 'inLibSincroStockCliente.pas',
  inLibSincroStockTransporte in 'inLibSincroStockTransporte.pas';

const
  CTiendas = 3;
  CArticulosIniciales = 30;
  CTransitoMinimo = 60; // segundos que tarda en llegar un traspaso

type
  TConsultaRegistro = record
    Fuente: TFuenteConsulta;
    Exacta: Boolean;
    Antiguedad: Int64;
    Diferencia: Integer;
  end;

  TTienda = record
    Nombre: string;
    AlmacenNombre: string;
    Almacen: TAlmacenTienda;
    Transporte: TTransporteStock;
    Servicio: IServicioStock;
    Cliente: TClienteTienda;
    Reinicios: Integer;
    Consultas: TList<TConsultaRegistro>;
    Inventarios: Integer;
    AjustesInventario: Integer;
    Traspasos: Integer;
    Altas: Integer;
    VentasOmitidas: Integer; // sin stock propio
    Ventas: array[TResultadoVentaTienda] of Integer;
  end;

var
  oCentralObj: TServidorStock;
  oCentral: IServicioStock;
  aTiendas: array[0..CTiendas - 1] of TTienda;
  aArticulos: TList<string>; // conocidos por la central (para el backoffice)
  oAzar: TAleatorio;
  iSemilla: UInt64;
  iTicks: Integer;
  bDetalle: Boolean;
  iErrores: Integer;
  iLineasDetalle: Integer;

procedure OrdenarCadenas(var AValores: TArray<string>);
var
  iExterno, iInterno: Integer;
  sValor: string;
begin
  for iExterno := 1 to High(AValores) do
  begin
    sValor := AValores[iExterno];
    iInterno := iExterno - 1;
    while (iInterno >= 0) and (AValores[iInterno] > sValor) do
    begin
      AValores[iInterno + 1] := AValores[iInterno];
      Dec(iInterno);
    end;
    AValores[iInterno + 1] := sValor;
  end;
end;

procedure OrdenarEnteros(var AValores: TArray<Int64>);
var
  iExterno, iInterno: Integer;
  iValor: Int64;
begin
  for iExterno := 1 to High(AValores) do
  begin
    iValor := AValores[iExterno];
    iInterno := iExterno - 1;
    while (iInterno >= 0) and (AValores[iInterno] > iValor) do
    begin
      AValores[iInterno + 1] := AValores[iInterno];
      Dec(iInterno);
    end;
    AValores[iInterno + 1] := iValor;
  end;
end;

procedure Fallo(const ATexto: string);
begin
  Inc(iErrores);
  Writeln('  [FALLO] ', ATexto);
end;

procedure Correcto(const ATexto: string);
begin
  Writeln('  [ OK  ] ', ATexto);
end;

procedure Cronologia(ATick: Integer; const ATexto: string;
  ASiempre: Boolean = False);
begin
  if ASiempre or bDetalle then
  begin
    Writeln(Format('%4d:%2.2d  %s', [ATick div 60, ATick mod 60, ATexto]));
    Inc(iLineasDetalle);
  end;
end;

function Precio: Currency;
begin
  Result := (500 + oAzar.Entero(9500)) / 100;
end;

procedure CrearTiendas;
var
  iIndice: Integer;
begin
  for iIndice := 0 to CTiendas - 1 do
    with aTiendas[iIndice] do
    begin
      Nombre := 'TIENDA' + IntToStr(iIndice + 1);
      AlmacenNombre := 'ALM' + IntToStr(iIndice + 1);
      Almacen := TAlmacenTienda.Create(Nombre, AlmacenNombre);
      Transporte := TTransporteStock.Create(
        oCentral, iSemilla * 97 + UInt64(iIndice) + 1);
      Servicio := Transporte;
      Transporte.Config := ConfigFallos(0.03, 0.03, 0.01);
      Cliente := TClienteTienda.Create(Almacen, Servicio);
      Cliente.TamanoLote := 25;
      Cliente.TamanoPagina := 100;
      Cliente.EsperaMaxima := 30;
      Consultas := TList<TConsultaRegistro>.Create;
    end;
end;

procedure LiberarTiendas;
var
  iIndice: Integer;
begin
  for iIndice := 0 to CTiendas - 1 do
    with aTiendas[iIndice] do
    begin
      Consultas.Free;
      Cliente.Free;
      Servicio := nil;
      Almacen.Free;
    end;
end;

procedure CargaInicial;
var
  iIndice, iTienda: Integer;
  sArticulo: string;
begin
  // La central crea el catálogo y el stock de partida. Las tiendas lo
  // reciben como novedades en su primera sincronización.
  for iIndice := 1 to CArticulosIniciales do
  begin
    sArticulo := Format('ART%3.3d', [iIndice]);
    aArticulos.Add(sArticulo);
    oCentralObj.CrearArticulo(sArticulo, Precio);
    for iTienda := 0 to CTiendas - 1 do
      oCentralObj.CargarStock(sArticulo, aTiendas[iTienda].AlmacenNombre,
        5 + oAzar.Entero(26));
    // Poco stock en el almacén compartido: la última unidad se disputa.
    oCentralObj.CargarStock(sArticulo, CAlmacenCompartido, oAzar.Entero(5));
  end;
  // Las tiendas parten con la copia al día y con su stock propio cargado
  // en su base local (una instalación inicial).
  for iTienda := 0 to CTiendas - 1 do
  begin
    // La instalación se hace con una conexión fiable.
    aTiendas[iTienda].Transporte.Config := ConfigSinFallos;
    aTiendas[iTienda].Cliente.Sincronizar(0);
    aTiendas[iTienda].Transporte.Config := ConfigFallos(0.03, 0.03, 0.01);
    for iIndice := 0 to aArticulos.Count - 1 do
      aTiendas[iTienda].Almacen.StockPropioTabla.AddOrSetValue(
        aArticulos[iIndice],
        oCentralObj.Stock(aArticulos[iIndice],
          aTiendas[iTienda].AlmacenNombre));
  end;
end;

function DebeEstarConectada(AIndice, ATick: Integer): Boolean;
begin
  case AIndice of
    0: Result := not ((ATick >= 900) and (ATick < 960));
    1: Result := not ((ATick >= 300) and (ATick < 600));  // 5 minutos
  else
    Result := not ((ATick >= 1500) and (ATick < 1560));
  end;
end;

procedure ReiniciarTienda(var ATienda: TTienda; ATick: Integer);
begin
  ATienda.Cliente.Free;
  ATienda.Cliente := TClienteTienda.Create(ATienda.Almacen, ATienda.Servicio);
  ATienda.Cliente.TamanoLote := 25;
  ATienda.Cliente.TamanoPagina := 100;
  ATienda.Cliente.EsperaMaxima := 30;
  Inc(ATienda.Reinicios);
  Cronologia(ATick, Format(
    '%s SE REINICIA: %d eventos pendientes, cursor %d, %d traspasos por recibir',
    [ATienda.Nombre, ATienda.Almacen.NumeroPendientes, ATienda.Almacen.Cursor,
     ATienda.Almacen.TraspasosPendientes.Count]), True);
end;

function ArticuloAlAzar(const ATienda: TTienda): string;
var
  aClaves: TArray<string>;
begin
  aClaves := ATienda.Almacen.Articulos.Keys.ToArray;
  if Length(aClaves) = 0 then
    Exit('');
  OrdenarCadenas(aClaves); // orden determinista
  Result := aClaves[oAzar.Entero(Length(aClaves))];
end;

procedure RegistrarConsulta(var ATienda: TTienda; const AArticulo,
  AAlmacen: string; const AResultado: TResultadoConsulta);
var
  oRegistro: TConsultaRegistro;
begin
  oRegistro.Fuente := AResultado.Fuente;
  oRegistro.Diferencia := AResultado.Cantidad -
    oCentralObj.Stock(AArticulo, AAlmacen);
  oRegistro.Exacta := oRegistro.Diferencia = 0;
  oRegistro.Antiguedad := AResultado.Antiguedad;
  ATienda.Consultas.Add(oRegistro);
end;

procedure OperarTienda(AIndice, ATick: Integer);
var
  sArticulo, sAlmacen: string;
  iCantidad, iContado, iDestino, iIndice: Integer;
  eVenta: TResultadoVentaTienda;
  oConsulta: TResultadoConsulta;
  oEvento: TEventoStock;
  oPendiente: TTraspasoPendiente;
begin
  if ArticuloAlAzar(aTiendas[AIndice]) = '' then
    Exit; // sin catálogo todavía: no puede operar
  with aTiendas[AIndice] do
  begin
    // Venta
    if oAzar.Probable(0.25) then
    begin
      sArticulo := ArticuloAlAzar(aTiendas[AIndice]);
      iCantidad := 1;
      if oAzar.Probable(0.10) then
        iCantidad := 2;
      if oAzar.Probable(0.20) then
        sAlmacen := CAlmacenCompartido
      else
        sAlmacen := AlmacenNombre;
      if (sAlmacen = AlmacenNombre) and
         (Almacen.StockPropio(sArticulo) < iCantidad) then
        Inc(VentasOmitidas) // el dependiente ve que no hay: no vende
      else
      begin
        eVenta := Cliente.Vender(sArticulo, sAlmacen, iCantidad, ATick);
        Inc(Ventas[eVenta]);
        case eVenta of
          vtVendidaSinConexion:
            Cronologia(ATick, Format('%s vende %d x %s de %s SIN CONEXION ' +
              '(copia local: %d uds)', [Nombre, iCantidad, sArticulo,
              sAlmacen, Cliente.ConsultarStock(sArticulo, sAlmacen,
              ATick).Cantidad]));
          vtBloqueadaSinStock:
            Cronologia(ATick, Format('%s: venta de %d x %s de %s BLOQUEADA, ' +
              'la central no tiene disponible', [Nombre, iCantidad,
              sArticulo, sAlmacen]));
        end;
      end;
    end;
    // Devolución
    if oAzar.Probable(0.02) then
      Almacen.Devolver(ArticuloAlAzar(aTiendas[AIndice]), 1, ATick);
    // Compra (albarán de proveedor)
    if oAzar.Probable(0.02) then
      Almacen.Comprar(ArticuloAlAzar(aTiendas[AIndice]),
        5 + oAzar.Entero(16), ATick);
    // Alta de artículo en la tienda (código con prefijo de tienda)
    if oAzar.Probable(0.005) then
    begin
      Inc(Altas);
      sArticulo := Format('%s-NUEVO%2.2d', [AlmacenNombre, Altas]);
      Almacen.AltaArticulo(sArticulo, Precio, ATick);
      Almacen.Comprar(sArticulo, 10, ATick);
      Cronologia(ATick, Format('%s da de alta %s y recibe 10 uds',
        [Nombre, sArticulo]));
    end;
    // Traspaso a otra tienda
    if oAzar.Probable(0.02) then
    begin
      sArticulo := ArticuloAlAzar(aTiendas[AIndice]);
      iCantidad := 1 + oAzar.Entero(3);
      if Almacen.StockPropio(sArticulo) >= iCantidad + 2 then
      begin
        iDestino := (AIndice + 1 + oAzar.Entero(CTiendas - 1)) mod CTiendas;
        oEvento := Almacen.TraspasoSalida(sArticulo,
          aTiendas[iDestino].AlmacenNombre, iCantidad, ATick);
        Inc(Traspasos);
        Cronologia(ATick, Format('%s envia traspaso de %d x %s a %s',
          [Nombre, iCantidad, sArticulo, aTiendas[iDestino].Nombre]));
      end;
    end;
    // Recepción de traspasos que ya han tenido tiempo de llegar
    iIndice := 0;
    while iIndice < Almacen.TraspasosPendientes.Count do
    begin
      oPendiente := Almacen.TraspasoPendiente(iIndice);
      if (oPendiente.InstanteAviso + CTransitoMinimo <= ATick) and
         oAzar.Probable(0.20) then
      begin
        Almacen.TraspasoRecepcion(oPendiente.IdTraspaso, ATick);
        Cronologia(ATick, Format('%s recibe traspaso de %d x %s desde %s',
          [Nombre, oPendiente.Cantidad, oPendiente.Articulo,
           oPendiente.Origen]));
      end
      else
        Inc(iIndice);
    end;
    // Inventario de un artículo (recuento físico con posible merma)
    if oAzar.Probable(0.005) then
    begin
      sArticulo := ArticuloAlAzar(aTiendas[AIndice]);
      iContado := Almacen.StockPropio(sArticulo);
      if oAzar.Probable(0.40) and (iContado > 0) then
        Dec(iContado, 1 + oAzar.Entero(2)); // merma de 1 o 2 unidades
      if iContado < 0 then
        iContado := 0; // no se pueden contar unidades negativas
      oEvento := Almacen.Inventario(sArticulo, iContado, ATick);
      Inc(Inventarios);
      if oEvento.Cantidad <> 0 then
      begin
        Inc(AjustesInventario);
        Cronologia(ATick, Format(
          '%s inventaria %s: contadas %d, teorico %d, AJUSTE %d',
          [Nombre, sArticulo, iContado, iContado - oEvento.Cantidad,
           oEvento.Cantidad]));
      end;
    end;
    // Consulta del stock de otro almacén (lo que pide un cliente)
    if oAzar.Probable(0.30) then
    begin
      sArticulo := ArticuloAlAzar(aTiendas[AIndice]);
      iDestino := oAzar.Entero(CTiendas);
      if iDestino = AIndice then
        sAlmacen := CAlmacenCompartido
      else
        sAlmacen := aTiendas[iDestino].AlmacenNombre;
      oConsulta := Cliente.ConsultarStock(sArticulo, sAlmacen, ATick);
      RegistrarConsulta(aTiendas[AIndice], sArticulo, sAlmacen, oConsulta);
      if (oConsulta.Fuente = fcCopiaLocal) and
         (oConsulta.Cantidad <> oCentralObj.Stock(sArticulo, sAlmacen)) then
        Cronologia(ATick, Format(
          '%s consulta %s en %s: muestra %d uds (copia de hace %ds); ' +
          'la central tiene %d', [Nombre, sArticulo, sAlmacen,
          oConsulta.Cantidad, oConsulta.Antiguedad,
          oCentralObj.Stock(sArticulo, sAlmacen)]));
    end;
  end;
end;

procedure Simular;
var
  iTick, iIndice, iAntes: Integer;
  bConectada: Boolean;
  sArticulo: string;
begin
  Writeln('--- Fase 1: operacion con red inestable (', iTicks div 60,
    ' min) ---');
  for iTick := 1 to iTicks do
  begin
    oCentralObj.Reloj := iTick;
    // Backoffice central: cambios de precio
    if oAzar.Probable(0.02) then
    begin
      sArticulo := aArticulos[oAzar.Entero(aArticulos.Count)];
      oCentralObj.CambiarPrecio(sArticulo, Precio);
    end;
    for iIndice := 0 to CTiendas - 1 do
      with aTiendas[iIndice] do
      begin
        bConectada := DebeEstarConectada(iIndice, iTick);
        if bConectada <> Transporte.Conectado then
        begin
          Transporte.Conectado := bConectada;
          if bConectada then
            Cronologia(iTick, Format(
              '%s RECUPERA LA CONEXION: %d eventos pendientes, cursor %d de %d',
              [Nombre, Almacen.NumeroPendientes, Almacen.Cursor,
               oCentralObj.UltimaVersion]), True)
          else
            Cronologia(iTick, Nombre + ' PIERDE LA CONEXION', True);
        end;
        OperarTienda(iIndice, iTick);
        if (iIndice = 2) and (iTick = 1530) then
          ReiniciarTienda(aTiendas[iIndice], iTick);
        // Con conexión, sincroniza cada segundo (espera larga). Sin
        // conexión, lo intenta cada 10 s.
        if bConectada or (iTick mod 10 = 0) then
        begin
          iAntes := oCentralObj.Sobreventas.Count;
          Cliente.Sincronizar(iTick);
          while iAntes < oCentralObj.Sobreventas.Count do
          begin
            Cronologia(iTick, Format(
              'CENTRAL detecta SOBREVENTA: %s en %s queda en %d por una ' +
              'venta de %s hecha a las %d:%2.2d sin respuesta de la central',
              [oCentralObj.Sobreventas[iAntes].Articulo,
               oCentralObj.Sobreventas[iAntes].Almacen,
               oCentralObj.Sobreventas[iAntes].StockResultante,
               oCentralObj.Sobreventas[iAntes].Terminal,
               oCentralObj.Sobreventas[iAntes].InstanteVenta div 60,
               oCentralObj.Sobreventas[iAntes].InstanteVenta mod 60]), True);
            Inc(iAntes);
          end;
        end;
      end;
  end;
end;

function Drenar: Integer;
var
  iRonda, iIndice: Integer;
  bTodoAlDia: Boolean;
  oPendiente: TTraspasoPendiente;
begin
  Writeln;
  Writeln('--- Fase 2: red restablecida, drenaje ---');
  for iIndice := 0 to CTiendas - 1 do
  begin
    aTiendas[iIndice].Transporte.Conectado := True;
    aTiendas[iIndice].Transporte.Config := ConfigSinFallos;
  end;
  Result := 0;
  for iRonda := 1 to 500 do
  begin
    bTodoAlDia := True;
    oCentralObj.Reloj := iTicks + iRonda * 100;
    for iIndice := 0 to CTiendas - 1 do
      with aTiendas[iIndice] do
      begin
        while Almacen.TraspasosPendientes.Count > 0 do
        begin
          oPendiente := Almacen.TraspasoPendiente(0);
          Almacen.TraspasoRecepcion(oPendiente.IdTraspaso,
            oCentralObj.Reloj);
        end;
        Cliente.Sincronizar(oCentralObj.Reloj);
        if (Almacen.NumeroPendientes > 0) or
           (Almacen.Cursor <> oCentralObj.UltimaVersion) or
           (oCentralObj.TraspasosEnTransito > 0) then
          bTodoAlDia := False;
      end;
    Result := iRonda;
    if bTodoAlDia then
      Exit;
  end;
end;

procedure VerificarIntegridad;
var
  iIndice, iEntrada, iConf, iRech, iPend, iDif, iSobre: Integer;
  sClave, sArticulo: string;
  oCopia: TCopiaStock;
  oEntrada: TEntradaBandeja;
  oSobreventa: TSobreventa;
  cPrecio: Currency;
  bIgual: Boolean;
begin
  Writeln;
  Writeln('--- Fase 3: integridad ---');
  // Central: stock = suma de movimientos
  iDif := 0;
  for sClave in oCentralObj.StockTabla.Keys do
  begin
    sArticulo := Copy(sClave, 1, Pos('|', sClave) - 1);
    if oCentralObj.Stock(sArticulo, Copy(sClave, Pos('|', sClave) + 1,
         Length(sClave))) <>
       oCentralObj.StockPorMovimientos(sArticulo,
         Copy(sClave, Pos('|', sClave) + 1, Length(sClave))) then
      Inc(iDif);
  end;
  if iDif = 0 then
    Correcto(Format('Central: stock = suma de movimientos en %d ' +
      'articulo/almacen (%d movimientos)', [oCentralObj.StockTabla.Count,
      oCentralObj.NumeroMovimientos]))
  else
    Fallo(Format('Central: %d cifras de stock no cuadran con sus movimientos',
      [iDif]));
  // Nada en tránsito
  iDif := 0;
  for sArticulo in oCentralObj.Articulos.Keys do
    if oCentralObj.Stock(sArticulo, CAlmacenTransito) <> 0 then
      Inc(iDif);
  if (oCentralObj.TraspasosEnTransito = 0) and (iDif = 0) then
    Correcto('Central: ningun traspaso en transito y almacen TRANSITO a cero')
  else
    Fallo(Format('Central: %d traspasos en transito, %d articulos con ' +
      'stock en TRANSITO', [oCentralObj.TraspasosEnTransito, iDif]));
  // Sobreventas
  iSobre := 0;
  for oSobreventa in oCentralObj.Sobreventas do
    if oSobreventa.ConReserva then
      Inc(iSobre);
  if iSobre = 0 then
    Correcto(Format('Central: %d sobreventas, todas de ventas sin conexion; ' +
      'ninguna con reserva', [oCentralObj.Sobreventas.Count]))
  else
    Fallo(Format('Central: %d sobreventas pese a reserva en linea', [iSobre]));

  for iIndice := 0 to CTiendas - 1 do
    with aTiendas[iIndice] do
    begin
      // Bandeja
      iConf := 0;
      iRech := 0;
      iPend := 0;
      for iEntrada := 0 to Almacen.Bandeja.Count - 1 do
      begin
        oEntrada := Almacen.Bandeja[iEntrada];
        case oEntrada.Estado of
          eePendiente: Inc(iPend);
          eeRechazado:
            begin
              Inc(iRech);
              Writeln(Format('          %s: evento %d %s rechazado: %s',
                [Nombre, oEntrada.Evento.Secuencia,
                 TipoEventoTexto(oEntrada.Evento.Tipo), oEntrada.Motivo]));
            end;
          eeConfirmado:
            begin
              Inc(iConf);
              if not oCentralObj.ExisteEvento(oEntrada.Evento.IdEvento) then
                Fallo(Format('%s: evento %d confirmado que no esta en la central',
                  [Nombre, oEntrada.Evento.Secuencia]));
            end;
        end;
      end;
      if (iPend = 0) and (iRech = 0) and (iConf = Almacen.Bandeja.Count) then
        Correcto(Format('%s: %d eventos, todos confirmados por la central',
          [Nombre, Almacen.Bandeja.Count]))
      else
        Fallo(Format('%s: %d eventos: %d confirmados, %d rechazados, %d pendientes',
          [Nombre, Almacen.Bandeja.Count, iConf, iRech, iPend]));
      // Stock propio = central
      iDif := 0;
      for sArticulo in oCentralObj.Articulos.Keys do
      begin
        if Almacen.StockPropio(sArticulo) <>
           oCentralObj.Stock(sArticulo, AlmacenNombre) then
        begin
          Inc(iDif);
          if iDif <= 5 then
            Writeln(Format('          %s: %s propio %d, central %d',
              [Nombre, sArticulo, Almacen.StockPropio(sArticulo),
               oCentralObj.Stock(sArticulo, AlmacenNombre)]));
        end;
        if Almacen.StockPropio(sArticulo) < 0 then
          Fallo(Format('%s: stock propio negativo en %s', [Nombre, sArticulo]));
      end;
      if iDif = 0 then
        Correcto(Format('%s: stock propio de %s identico al de la central ' +
          'en los %d articulos', [Nombre, AlmacenNombre,
          oCentralObj.Articulos.Count]))
      else
        Fallo(Format('%s: %d articulos con stock propio distinto de la central',
          [Nombre, iDif]));
      // Copia de los demás almacenes = central
      iDif := 0;
      // (TRANSITO es interno de la central: no se publica)
      for sClave in oCentralObj.StockTabla.Keys do
        if (Copy(sClave, Pos('|', sClave) + 1, Length(sClave)) <>
            AlmacenNombre) and
           (Copy(sClave, Pos('|', sClave) + 1, Length(sClave)) <>
            CAlmacenTransito) then
        begin
          if not Almacen.TieneCopia(Copy(sClave, 1, Pos('|', sClave) - 1),
               Copy(sClave, Pos('|', sClave) + 1, Length(sClave)), oCopia) or
             (oCopia.Cantidad <> oCentralObj.StockTabla[sClave]) then
            Inc(iDif);
        end;
      if iDif = 0 then
        Correcto(Format('%s: copia local de los otros almacenes identica ' +
          'a la central (%d cifras)', [Nombre, Almacen.Copia.Count]))
      else
        Fallo(Format('%s: %d cifras de la copia local difieren de la central',
          [Nombre, iDif]));
      // Artículos y precios
      bIgual := Almacen.Articulos.Count = oCentralObj.Articulos.Count;
      if bIgual then
        for sArticulo in oCentralObj.Articulos.Keys do
          if not Almacen.Articulos.TryGetValue(sArticulo, cPrecio) or
             (cPrecio <> oCentralObj.Articulos[sArticulo]) then
          begin
            bIgual := False;
            Break;
          end;
      if bIgual then
        Correcto(Format('%s: catalogo y precios identicos (%d articulos)',
          [Nombre, Almacen.Articulos.Count]))
      else
        Fallo(Format('%s: catalogo o precios distintos (%d frente a %d)',
          [Nombre, Almacen.Articulos.Count, oCentralObj.Articulos.Count]));
      // Avisos de sobreventa
      if Almacen.Sobreventas.Count = oCentralObj.Sobreventas.Count then
        Correcto(Format('%s: ha recibido los %d avisos de sobreventa',
          [Nombre, Almacen.Sobreventas.Count]))
      else
        Fallo(Format('%s: %d avisos de sobreventa de %d',
          [Nombre, Almacen.Sobreventas.Count, oCentralObj.Sobreventas.Count]));
      if oCentralObj.CursorConfirmado(Nombre) <> Almacen.Cursor then
        Fallo(Format('%s: la central no tiene confirmada la ultima version',
          [Nombre]));
    end;
end;

function Percentil(const AValores: TArray<Int64>; APorcentaje: Integer): Int64;
var
  iIndice: Integer;
begin
  if Length(AValores) = 0 then
    Exit(0);
  iIndice := (Length(AValores) * APorcentaje + 99) div 100 - 1;
  if iIndice < 0 then
    iIndice := 0;
  if iIndice > High(AValores) then
    iIndice := High(AValores);
  Result := AValores[iIndice];
end;

function ConexionContinua(AIndice: Integer; ADesde, AHasta: Int64): Boolean;
var
  iTick: Int64;
begin
  Result := True;
  iTick := ADesde;
  while iTick <= AHasta do
  begin
    if not DebeEstarConectada(AIndice, iTick) then
      Exit(False);
    Inc(iTick);
  end;
end;

procedure InformarVigencia;
const
  CTramos: array[0..4] of Int64 = (1, 5, 30, 120, High(Int64));
  CNombresTramo: array[0..4] of string =
    ('<= 1 s', '2-5 s', '6-30 s', '31-120 s', '> 2 min');
var
  iIndice, iTramo, iMuestra: Integer;
  aTodas, aConConexion: TArray<Int64>;
  iTodas, iConConexion: Integer;
  oLatencia: TLatencia;
  aTramos: array[0..4] of Integer;
  iSuma: Int64;
  oRegistro: TConsultaRegistro;
  aTotal, aExactas: array[TFuenteConsulta] of Integer;
  iAntigMax, iAntigSuma, iAntigCuenta, iDifMax: Int64;
  eFuente: TFuenteConsulta;
begin
  Writeln;
  Writeln('--- Vigencia: cuanto tarda un cambio en verse en otra tienda ---');
  Writeln('(latencia de las novedades de stock originadas por otras tiendas ',
    'o la central)');
  for iIndice := 0 to CTiendas - 1 do
    with aTiendas[iIndice] do
    begin
      SetLength(aTodas, Almacen.Latencias.Count);
      SetLength(aConConexion, Almacen.Latencias.Count);
      iTodas := 0;
      iConConexion := 0;
      for iTramo := 0 to 4 do
        aTramos[iTramo] := 0;
      iSuma := 0;
      for iMuestra := 0 to Almacen.Latencias.Count - 1 do
      begin
        oLatencia := Almacen.Latencias[iMuestra];
        // Solo la fase de operación: el drenaje usa un reloj artificial.
        if (oLatencia.Tipo <> tnStock) or
           (oLatencia.InstantePublicado + oLatencia.Latencia > iTicks) then
          Continue;
        aTodas[iTodas] := oLatencia.Latencia;
        Inc(iTodas);
        for iTramo := 0 to 4 do
          if oLatencia.Latencia <= CTramos[iTramo] then
          begin
            Inc(aTramos[iTramo]);
            Break;
          end;
        // Muestras en las que la tienda tuvo conexión todo el tiempo
        // entre la publicación y la aplicación: es la latencia del
        // servicio en sí, sin cortes.
        if (oLatencia.InstantePublicado > 0) and
           ConexionContinua(iIndice, oLatencia.InstantePublicado,
             oLatencia.InstantePublicado + oLatencia.Latencia) then
        begin
          aConConexion[iConConexion] := oLatencia.Latencia;
          Inc(iConConexion);
          Inc(iSuma, oLatencia.Latencia);
        end;
      end;
      SetLength(aTodas, iTodas);
      OrdenarEnteros(aTodas);
      SetLength(aConConexion, iConConexion);
      OrdenarEnteros(aConConexion);
      Writeln(Format('%s: %d novedades de stock recibidas', [Nombre, iTodas]));
      if iTodas > 0 then
      begin
        Writeln(Format('   todas:         mediana %d s, p95 %d s, maximo %d s',
          [Percentil(aTodas, 50), Percentil(aTodas, 95),
           aTodas[High(aTodas)]]));
        if iConConexion > 0 then
          Writeln(Format('   con conexion:  mediana %d s, p95 %d s, maximo %d s, ' +
            'media %.2f s (%d muestras)',
            [Percentil(aConConexion, 50), Percentil(aConConexion, 95),
             aConConexion[High(aConConexion)], iSuma / iConConexion,
             iConConexion]));
        Write('   reparto:      ');
        for iTramo := 0 to 4 do
          Write(Format(' %s: %d (%.0f%%)', [CNombresTramo[iTramo],
            aTramos[iTramo], 100 * aTramos[iTramo] / iTodas]));
        Writeln;
      end;
    end;

  Writeln;
  Writeln('--- Vigencia: exactitud de las consultas de stock de otros almacenes ---');
  for iIndice := 0 to CTiendas - 1 do
    with aTiendas[iIndice] do
    begin
      for eFuente := Low(TFuenteConsulta) to High(TFuenteConsulta) do
      begin
        aTotal[eFuente] := 0;
        aExactas[eFuente] := 0;
      end;
      iAntigMax := 0;
      iAntigSuma := 0;
      iAntigCuenta := 0;
      iDifMax := 0;
      for oRegistro in Consultas do
      begin
        Inc(aTotal[oRegistro.Fuente]);
        if oRegistro.Exacta then
          Inc(aExactas[oRegistro.Fuente]);
        if oRegistro.Fuente = fcCopiaLocal then
        begin
          Inc(iAntigSuma, oRegistro.Antiguedad);
          Inc(iAntigCuenta);
          if oRegistro.Antiguedad > iAntigMax then
            iAntigMax := oRegistro.Antiguedad;
          if Abs(oRegistro.Diferencia) > iDifMax then
            iDifMax := Abs(oRegistro.Diferencia);
        end;
      end;
      Writeln(Format('%s: %d consultas', [Nombre, Consultas.Count]));
      if aTotal[fcEnLinea] > 0 then
        Writeln(Format('   en linea:     %4d, exactas %d (%.1f%%)',
          [aTotal[fcEnLinea], aExactas[fcEnLinea],
           100 * aExactas[fcEnLinea] / aTotal[fcEnLinea]]));
      if aTotal[fcCopiaLocal] > 0 then
      begin
        Writeln(Format('   copia local:  %4d, exactas %d (%.1f%%), ' +
          'desactualizadas %d; desviacion maxima %d uds',
          [aTotal[fcCopiaLocal], aExactas[fcCopiaLocal],
           100 * aExactas[fcCopiaLocal] / aTotal[fcCopiaLocal],
           aTotal[fcCopiaLocal] - aExactas[fcCopiaLocal], iDifMax]));
        Writeln(Format('                 antiguedad mostrada: media %.0f s, ' +
          'maxima %d s', [iAntigSuma / iAntigCuenta, iAntigMax]));
      end;
      if aTotal[fcSinDato] > 0 then
        Writeln(Format('   sin dato:     %4d', [aTotal[fcSinDato]]));
      if aExactas[fcEnLinea] <> aTotal[fcEnLinea] then
        Fallo(Nombre + ': una consulta en linea devolvio un dato distinto ' +
          'del de la central');
    end;
end;

procedure InformarActividad;
var
  iIndice: Integer;
  eTipo: TTipoEvento;
  sArticulo: string;
  aClaves: TArray<string>;
begin
  Writeln;
  Writeln('--- Actividad ---');
  Write('Central: eventos aceptados por tipo:');
  for eTipo := Low(TTipoEvento) to High(TTipoEvento) do
    Write(' ', TipoEventoTexto(eTipo), '=',
      oCentralObj.Estadisticas.EventosPorTipo[eTipo]);
  Writeln;
  with oCentralObj.Estadisticas do
    Writeln(Format('Central: lotes=%d aceptados=%d repetidos=%d rechazados=%d ' +
      'fuera_de_orden=%d reservas=%d/%d denegadas consultas=%d novedades=%d',
      [Lotes, Aceptados, Repetidos, Rechazados, FueraDeOrden,
       ReservasConcedidas, ReservasDenegadas, Consultas,
       oCentralObj.UltimaVersion]));
  for iIndice := 0 to CTiendas - 1 do
    with aTiendas[iIndice] do
    begin
      Writeln(Format('%s: ventas propias=%d de CENTRAL con reserva=%d ' +
        'de CENTRAL sin respuesta=%d bloqueadas sin disponible=%d ' +
        'omitidas sin stock propio=%d | traspasos=%d inventarios=%d ' +
        '(ajustes %d) altas=%d reinicios=%d',
        [Nombre, Ventas[vtVendida], Ventas[vtVendidaConReserva],
         Ventas[vtVendidaSinConexion], Ventas[vtBloqueadaSinStock],
         VentasOmitidas, Traspasos, Inventarios, AjustesInventario, Altas,
         Reinicios]));
      with Transporte.Estadisticas do
        Writeln(Format('%s: red llamadas=%d sin_conexion=%d perdidas=%d ' +
          'respuestas_perdidas=%d duplicados=%d',
          [Nombre, Llamadas, SinConexion, PeticionesPerdidas,
           RespuestasPerdidas, Duplicados]));
    end;

  Writeln;
  Writeln('--- Stock final en la central (primeros articulos) ---');
  Write('ARTICULO    ');
  for iIndice := 0 to CTiendas - 1 do
    Write(Format('%8s', [aTiendas[iIndice].AlmacenNombre]));
  Writeln(Format('%8s%8s', [CAlmacenCompartido, 'TOTAL']));
  aClaves := oCentralObj.Articulos.Keys.ToArray;
  OrdenarCadenas(aClaves);
  iIndice := 0;
  for sArticulo in aClaves do
    if ((Length(sArticulo) = 6) and
        (StrToIntDef(Copy(sArticulo, 4, 3), 99) <= 10)) or
       ((Pos('NUEVO', sArticulo) = 6) and (Copy(sArticulo, 11, 2) <= '02')) then
    begin
      Write(Format('%-12s', [sArticulo]));
      for iIndice := 0 to CTiendas - 1 do
        Write(Format('%8d', [oCentralObj.Stock(sArticulo,
          aTiendas[iIndice].AlmacenNombre)]));
      Writeln(Format('%8d%8d', [oCentralObj.Stock(sArticulo, CAlmacenCompartido),
        oCentralObj.Stock(sArticulo, 'ALM1') + oCentralObj.Stock(sArticulo, 'ALM2') +
        oCentralObj.Stock(sArticulo, 'ALM3') +
        oCentralObj.Stock(sArticulo, CAlmacenCompartido)]));
    end;
  Writeln('(un valor negativo en CENTRAL es una sobreventa de una venta sin ',
    'conexion, ya avisada a todas las tiendas)');
end;

var
  iRondas: Integer;
begin
  iSemilla := 2026;
  iTicks := 1800;
  bDetalle := False;
  if ParamCount >= 1 then
    iSemilla := StrToInt64Def(ParamStr(1), 2026);
  if ParamCount >= 2 then
    iTicks := StrToIntDef(ParamStr(2), 1800);
  if ParamCount >= 3 then
    bDetalle := ParamStr(3) = '1';
  iErrores := 0;
  Writeln(Format('Simulacion de stock multitienda ViraCash (semilla %d, %d s, ' +
    '%d tiendas, %d articulos)', [Int64(iSemilla), iTicks, CTiendas,
    CArticulosIniciales]));
  Writeln;

  oCentralObj := TServidorStock.Create;
  oCentral := oCentralObj;
  oAzar := TAleatorio.Create(iSemilla);
  aArticulos := TList<string>.Create;
  try
    CrearTiendas;
    try
      CargaInicial;
      Simular;
      iRondas := Drenar;
      Writeln(Format('Drenaje completado en %d ronda(s)', [iRondas]));
      VerificarIntegridad;
      InformarVigencia;
      InformarActividad;
    finally
      LiberarTiendas;
    end;
  finally
    aArticulos.Free;
    oAzar.Free;
    oCentral := nil;
  end;

  Writeln;
  if iErrores = 0 then
    Writeln('RESULTADO: todas las invariantes de integridad se cumplen')
  else
    Writeln(Format('RESULTADO: %d invariante(s) incumplida(s)', [iErrores]));
  if iErrores > 0 then
    ExitCode := 1;
end.
