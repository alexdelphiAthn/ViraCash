# Sincronización cliente-servidor (simulación)

Simulación ejecutable de la arquitectura con la que cada tienda de ViraCash
trabaja sobre una **base de datos local** y se sincroniza con una **central**
mediante un servicio con **acuses**, tolerante a desconexiones, pérdidas de
mensajes, duplicados y reinicios, y pensada para que la información sea
**íntegra** (nada se pierde ni se duplica) y **vigente** (un cambio en una
tienda se ve en las demás en segundos).

Igual que `pruebaventasws`, son proyectos **independientes**: no se
compilan dentro de `vcash.dproj`. El código es Object Pascal sin VCL ni
UniDAC y compila tanto en Delphi como en Free Pascal.

Hay tres niveles:

| Nivel | Qué cubre | Programas |
|---|---|---|
| **Ventas** (`inLibSincro*`) | Subida de ventas y bajada de novedades genéricas. Es el protocolo mínimo. | `SimulacionSincro`, `PruebasSincro` |
| **Stock multitienda** (`inLibSincroStock*`) | Ventas, compras, devoluciones, traspasos, inventarios, altas de artículo, precios, stock por almacén, reserva en línea, consulta de stock con respaldo local. | `SimulacionStock`, `PruebasStock` |
| **Bases de datos reales** (`bbdd/`) | Lo mismo con tres bases MariaDB (central, webservice, tienda) y procedimientos almacenados, webservice PHP por HTTP, agentes de tienda como procesos y "internet" simulada. Mide la vigencia con reloj real. Ver [`bbdd/README.md`](bbdd/README.md). | `bbdd/simulacion/simular.php` |

## Arquitectura

```
        TIENDA (base local)                                CENTRAL
 ┌───────────────────────────────┐                ┌──────────────────────────┐
 │ Documento ─(misma transacción)►│                │                          │
 │   fza_sincro_salida           │ EnviarEventos  │ srv_sincro_eventos       │
 │   (bandeja, en orden de       ├───lote────────►│ srv_sincro_movimientos   │
 │    secuencia)                 │◄──acuse/evento─┤ srv_sincro_stock = suma  │
 │   stock PROPIO (exacto)       │                │                          │
 │                               │ Reservar       │ srv_sincro_reservas      │
 │   venta del almacén ──────────┼───────────────►│ (última unidad, atómico) │
 │   compartido                  │◄──concedida────┤                          │
 │                               │                │                          │
 │   COPIA del stock de los      │ PedirNovedades │ srv_sincro_novedades     │
 │   demás almacenes + cursor ◄──┼──página────────┤ (registro versionado)    │
 │   (con antigüedad)            ├──Confirmar────►│ srv_sincro_terminales    │
 │                               │                │                          │
 │   consulta de stock ──────────┼─ConsultarStock►│ (en línea; si no hay red │
 │                               │                │  responde la copia local)│
 └───────────────────────────────┘                └──────────────────────────┘
        TClienteTienda            IServicioStock          TServidorStock
```

## Principios

1. **El stock no se envía como cifra, se envía como movimiento.** La
   central lo calcula sumando movimientos. Un reenvío o un desorden no lo
   corrompen, y el inventario envía el **ajuste** (contado − teórico), no
   el recuento, para no pisar las ventas hechas sin conexión mientras se
   contaba.
2. **Cada dato tiene un único responsable.** La central manda sobre
   artículos y precios; cada tienda sobre sus documentos y su almacén (por
   eso su stock propio es exacto siempre, con o sin red); el stock se
   deriva de los movimientos. Las altas de artículo desde tienda llevan
   prefijo de tienda para no chocar.
3. **Vender nunca depende de la red.** El evento entra en la bandeja en la
   misma transacción que el documento. Se envía en orden de secuencia; la
   central responde `FUERA_DE_ORDEN` a un hueco y el terminal reintenta.
4. **Solo un acuse de la central saca un evento de PENDIENTE.** Ante
   cualquier fallo de red se reintenta con el mismo `IdEvento`; la central
   responde `REPETIDO` si ya lo tenía. Un `RECHAZADO` es un error de
   negocio y no se reintenta.
5. **Novedades en orden y una sola vez.** Versión global creciente
   asignada con un contador bloqueado (no `AUTO_INCREMENT`); cada tienda
   aplica la novedad y avanza el cursor en la misma transacción.
6. **Última unidad del almacén compartido.** Con red, la venta **reserva**
   la unidad en la central de forma atómica; si no hay disponible, la
   venta se bloquea al instante. Si la red no responde (tras reintentar la
   reserva con el mismo id), se vende **con riesgo**: la central detecta
   la sobreventa al recibir el evento y avisa a todas las tiendas.
7. **Consulta de stock de otra tienda.** Con red va a la central (igual
   de actual que con RDP). Sin red responde la copia local **declarando su
   antigüedad** ("dato de hace 4 min") o "sin dato", nunca un 0 inventado.
8. **Vigencia por espera larga.** La petición de novedades queda abierta y
   la central responde en cuanto hay algo: la latencia queda en 1-2 s sin
   martillear el servidor.

## Fallos simulados

`TTransporteStock` se interpone entre tienda y central y provoca:

| Fallo | Qué pasa en la central | Qué ve la tienda | Resultado |
|---|---|---|---|
| Sin conexión | Nada | Error de red | Sigue PENDIENTE, reintento |
| Petición perdida | Nada | Tiempo agotado | Sigue PENDIENTE, reintento |
| **Respuesta perdida** | **Lo procesa** | Tiempo agotado | Reenvío → `REPETIDO` → confirmado |
| Duplicado | Lo recibe dos veces | Respuesta normal | La segunda es `REPETIDO` |
| Reinicio de la tienda | — | Pierde la memoria del motor | Bandeja, stock, copia, cursor y traspasos pendientes persisten |

## Ficheros

| Fichero | Contenido |
|---|---|
| `inLibSincroProtocolo.pas` | Protocolo mínimo de ventas y contrato `IServicioSincro` |
| `inLibSincroServidor.pas`, `inLibSincroCliente.pas` | Servidor y cliente del protocolo mínimo |
| `inLibSincroTransporteSimulado.pas` | Red poco fiable con semilla reproducible (generador propio) |
| `SimulacionSincro.dpr`, `PruebasSincro.dpr` | Simulación de 3 cajas y 11 pruebas del protocolo mínimo |
| `inLibSincroStockProtocolo.pas` | Eventos, novedades, reservas, consulta: contrato `IServicioStock` |
| `inLibSincroStockServidor.pas` | Central: orden de secuencia, stock por movimientos, tránsito, reservas, sobreventas |
| `inLibSincroStockCliente.pas` | Tienda: bandeja, stock propio, copia con antigüedad, venta con reserva, consulta con respaldo |
| `inLibSincroStockTransporte.pas` | Red poco fiable para `IServicioStock` |
| `SimulacionStock.dpr` | Simulación de 3 tiendas con datos de negocio e informes de integridad y vigencia |
| `PruebasStock.dpr` | 12 escenarios deterministas del protocolo de stock |
| `sql/esquema_sincro.sql` | Tablas y consultas para llevarlo a MariaDB (ambos niveles) |

## Ejecutar

Delphi: abrir el `.dpr` en RAD Studio y compilar como aplicación de consola.

Free Pascal:

```bash
fpc SimulacionStock.dpr && ./SimulacionStock          # semilla 2026, 30 min
./SimulacionStock 42 3600                             # otra semilla, 60 min
./SimulacionStock 42 3600 1                           # con cronología detallada
fpc PruebasStock.dpr && ./PruebasStock
```

Todos devuelven código de salida 0 si todo se cumple y 1 si no, de modo
que pueden ejecutarse en integración continua.

## Qué hace `SimulacionStock`

Un tick es un segundo. Tres tiendas (`TIENDA1..3`, almacenes `ALM1..3`) y
un almacén compartido `CENTRAL` con poco stock para que la última unidad se
dispute. Treinta artículos de partida.

**Fase 1 (operación, 30 min):** cada segundo, cada tienda puede vender (de
su almacén o del compartido), devolver, recibir un albarán, dar de alta un
artículo, enviar un traspaso, recibir los que le llegan (tardan un minuto),
inventariar un artículo (a veces con merma) y consultar el stock de otro
almacén. La central cambia precios. La red pierde el 3 % de peticiones y
respuestas y duplica el 1 %. `TIENDA2` está 5 min sin red, `TIENDA1` y
`TIENDA3` un minuto, y `TIENDA3` se reinicia en plena desconexión.

**Fase 2 (drenaje):** se restablece la red y se vacían las colas.

**Fase 3 (integridad):** se comprueba que
- el stock de la central coincide con la suma de sus movimientos;
- no queda ningún traspaso en tránsito;
- ninguna sobreventa se produjo con reserva concedida;
- todos los eventos de cada tienda están confirmados y existen en la central;
- el stock propio de cada tienda es idéntico al de la central, artículo
  por artículo, y nunca negativo;
- la copia local de los demás almacenes es idéntica a la central;
- catálogo y precios son idénticos;
- cada tienda ha recibido todos los avisos de sobreventa.

**Vigencia:** para cada tienda, latencia de las novedades de stock de las
demás (mediana, p95, máximo, reparto por tramos; aparte, solo las muestras
en las que tuvo conexión todo el tiempo) y exactitud de las consultas de
stock por fuente (en línea, copia local, sin dato), con la antigüedad que
se mostró al usuario y la desviación máxima.

Ejemplo (semilla 2026): 1.518 eventos, 50 reenvíos detectados, 15
sobreventas (todas de ventas sin conexión), latencia con conexión de
mediana 1 s y p95 2 s, consultas en línea 100 % exactas, consultas desde
copia durante el corte de 5 min con antigüedad media de 111 s mostrada al
usuario.

## Decisiones tomadas y cómo cambiarlas

- **Sin conexión se permite vender aunque el stock del almacén compartido
  quede negativo.** Para bloquearlo, en `TClienteTienda.Vender` devolver
  `vtBloqueadaSinStock` cuando la reserva no obtiene respuesta.
- **Las tiendas pueden dar de alta artículos.** Para que solo lo haga la
  central, rechazar `teAltaArticulo` en `TServidorStock.Aplicar`.
- **La reserva se reintenta 2 veces** antes de vender con riesgo
  (`ReintentosReserva`).
- **Las reservas no caducan** en la simulación; en producción deben
  caducar (ver `sql/esquema_sincro.sql`).
- **Un traspaso solo se recibe cuando la central ya ha avisado de él.** Si
  la mercancía llega físicamente antes que el dato (origen sin red), en
  producción haría falta una "entrada pendiente de traspaso" que se case
  después.

## Paso a producción

- **Subida**: la cola actual `fza_ventas_ws_cola` ya es la bandeja de
  salida de ventas. Para el resto de documentos, `fza_sincro_salida`
  (esquema en SQL). Un hilo como `THiloVentasWsCola` que llame a
  `TClienteTienda.Sincronizar`.
- **Bajada**: repositorio UniDAC sobre `fza_sincro_cursor`,
  `fza_sincro_stock_copia`, `fza_sincro_traspasos_pendientes` y las tablas
  de artículos, sustituyendo a `TAlmacenTienda`.
- **Transporte**: implementar `IServicioStock` sobre
  `TClienteViraCashApi`, convirtiendo errores 5xx, tiempos agotados y falta
  de conexión en `ETransporteSincro` (reintentable), y los 4xx de
  validación en acuses `RECHAZADO`.
- **Servidor**: los endpoints `sincro/eventos.php`, `novedades.php` (con
  espera larga), `novedades_ack.php`, `reservas.php` y `stock.php` siguen
  las consultas comentadas en `sql/esquema_sincro.sql`.
- **Purga**: las novedades con versión menor que la mínima confirmada por
  los terminales activos pueden archivarse. Un terminal nuevo, o con el
  cursor por debajo de lo purgado, parte de una instantánea completa y fija
  su cursor en la versión de esa instantánea.
