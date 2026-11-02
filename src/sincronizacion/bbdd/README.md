# Sincronización con bases de datos reales

Montaje completo de la arquitectura con **tres bases de datos MariaDB**,
un **webservice PHP** y **agentes de tienda** que hablan con él por HTTP
"como por internet" (latencia, pérdidas y cortes simulados en la capa de
red de la tienda). Toda la lógica de datos está en **procedimientos
almacenados**; no hay triggers.

```
   TIENDA (base local tienda_tN)             INTERNET            WEBSERVICE (PHP)         CENTRAL
 ┌──────────────────────────────┐                             ┌──────────────────┐   ┌───────────────┐
 │ caja ─► sp_vender, sp_pedido │                             │ eventos.php      │   │ sp_aplicar_   │
 │         sp_albaran_compra... │   POST eventos  ───────────►│  sp_recibir_     ├──►│   evento      │
 │         (documento + evento  │◄─── acuses ─────────────────│  evento          │   │ movimientos   │
 │          en la misma trans.) │                             │ (idempotencia,   │   │ stock = suma  │
 │                              │                             │  orden, auditoría)│   │ novedades     │
 │ agente subida  ◄── salida    │                             │                  │   │ (contador)    │
 │ agente escucha ──► GET novedades?desde=N&espera=20 ───────►│ novedades.php    │◄──┤               │
 │   (petición abierta hasta    │◄─── responde al publicarse ─│  (espera larga)  │   │ sp_reservar   │
 │    que haya algo: la tienda  │                             │ reservas.php ────┼──►│ sp_consultar_ │
 │    "escucha" sin abrir       │   POST reservas / GET stock │ stock.php        │   │   stock       │
 │    ningún puerto)            │                             │ novedades_ack.php│   │               │
 └──────────────────────────────┘                             └──────────────────┘   └───────────────┘
```

## Las tres bases de datos

| Base | Qué sabe | Procedimientos principales |
|---|---|---|
| **`central`** | Negocio: artículos, almacenes, stock (suma de movimientos), ventas, devoluciones, albaranes, pedidos, traspasos (con estado en tránsito), inventarios, reservas, sobreventas, registro de novedades versionado | `sp_aplicar_evento`, `sp_reservar`, `sp_caducar_reservas`, `sp_consultar_stock`, `sp_novedades_desde`, `sp_crear_articulo`, `sp_cambiar_precio`, `sp_cargar_stock`, `sp_verificar_integridad` |
| **`webservice`** | Terminales y tokens, última secuencia por terminal, cada evento recibido con la decisión tomada (idempotencia), versión confirmada, auditoría de peticiones HTTP | `sp_recibir_evento` (orden + idempotencia + transacción + llamada a la central), `sp_confirmar_novedades`, `sp_autenticar`, `sp_estado_terminales` |
| **`tienda_tN`** | Documentos locales, stock propio exacto, copia del stock de los demás almacenes con antigüedad, bandeja de salida, cursor, traspasos por recibir, avisos, latencias medidas | `sp_vender`, `sp_devolucion`, `sp_albaran_compra`, `sp_pedido`, `sp_traspaso_salida`, `sp_traspaso_recepcion`, `sp_inventario`, `sp_alta_articulo`, `sp_lote_pendiente`, `sp_acuse`, `sp_aplazar`, `sp_aplicar_novedad`, `sp_consultar_stock_copia`, `sp_estado` |

Webservice y central están en la misma red (el webservice llama a
`central.sp_*` directamente). Las tiendas solo ven el webservice.

## Reglas de negocio que implementan los procedimientos

- **Lo que pasa por el lector se vende.** `tienda.sp_vender` nunca
  comprueba stock; el stock propio puede quedar negativo (la realidad
  física manda) y el inventario lo corrige con un **ajuste**, no con el
  recuento, para no pisar las ventas hechas mientras se contaba.
- **Cada documento y su evento van en la misma transacción** local. El
  evento lleva un correlativo (`secuencia`) y un `id_evento` único.
- **La tienda puede crear de todo**: ventas, devoluciones, albaranes de
  compra, pedidos a la central, traspasos (salida y recepción),
  inventarios y artículos (con prefijo de su almacén).
- **El webservice procesa cada evento en su transacción** (`sp_recibir_evento`):
  si el `id_evento` ya se vio devuelve la misma decisión (`REPETIDO` o
  `RECHAZADO`); si la secuencia tiene un hueco, `FUERA_DE_ORDEN` y la tienda
  reintenta; si no, llama a `central.sp_aplicar_evento`. El acuse sale
  después del `COMMIT`.
- **La central no escribe el stock: lo mueve.** `sp_mover` inserta el
  movimiento y actualiza la cifra; `sp_verificar_integridad` comprueba que
  siempre coinciden. Los traspasos pasan por el pseudoalmacén `TRANSITO`.
- **Almacén compartido `CENTRAL`**: la venta reserva en línea
  (`sp_reservar`, atómica, idempotente por id). Sin respuesta tras dos
  intentos, se vende igualmente con `modo = SIN_CONEXION` llevando el id de
  reserva (si la reserva sí se creó, la venta la consume). Si el stock
  queda negativo, la central publica `SOBREVENTA` a todas las tiendas.
- **Novedades**: versión contigua asignada con el contador bloqueado
  (`sp_publicar`). La tienda aplica cada una y avanza el cursor en la
  misma transacción (`sp_aplicar_novedad`), ignorando las ya aplicadas.
- **Pedidos**: la central los registra y responde con `PEDIDO_REGISTRADO`;
  la tienda marca el suyo como registrado al recibirlo.

## Cómo recibe la tienda sin tener nada que enviar

No hace falta un servidor en la tienda (puerto abierto, IP fija, NAT): el
agente de **escucha** mantiene abierta una petición
`GET novedades.php?desde=N&espera=20`. El webservice la deja esperando
(`CFG_ESPERA_MAXIMA_S`, sondeo cada 150 ms al contador de la central) y la
responde en el instante en que la central publica algo. La tienda aplica
y vuelve a quedarse a la escucha; si en 20 s no hay nada, la petición
vuelve vacía y se reabre. Es una conexión saliente normal (HTTPS en
producción), atraviesa cualquier router y el efecto es el de un servidor
en la tienda. Medido aquí: ~120 ms entre publicar y recibir.

Si alguna vez hiciera falta aún menos latencia o muchos miles de tiendas,
el paso natural es WebSocket (misma idea, una sola conexión persistente),
sin cambiar nada de las bases de datos.

El agente de **subida** es independiente: vacía la bandeja en orden de
secuencia cada 300 ms y aplica los acuses; un fallo de red aplaza el lote
con espera exponencial (`sp_aplazar`). En Delphi serían dos hilos del
mismo servicio, como `THiloVentasWsCola`.

## Ficheros

| Ruta | Contenido |
|---|---|
| `sql/central.sql`, `sql/webservice.sql`, `sql/tienda.sql` | Esquemas y procedimientos (la tienda es una plantilla: `__TIENDA__`) |
| `webservice/publico/*.php` | Endpoints: `eventos`, `novedades` (espera larga), `novedades_ack`, `reservas`, `stock`, `prueba` |
| `webservice/privado/comun.php`, `config.php` | JSON, autenticación Bearer por token de terminal, auditoría |
| `webservice/router.php` | Para el servidor integrado de PHP (`PHP_CLI_SERVER_WORKERS` obligatorio) |
| `tienda/internet.php` | Cliente HTTP de la tienda con "internet" simulada (fichero de control por tienda) |
| `tienda/agente.php` | Agente: `--rol=subida`, `--rol=escucha`, `--rol=inicial` |
| `tienda/caja.php` | TPV simulado: ventas por lector, devoluciones, albaranes, pedidos, traspasos, inventarios, altas, consultas |
| `simulacion/simular.php` | Orquestador: crea todo, arranca procesos, provoca cortes y reinicios, drena y llama al informe |
| `simulacion/informe.php` | Verificación de integridad e informe de vigencia (se puede relanzar solo) |

## Ejecutar

Requisitos: MariaDB 10.5+ (probado con 10.11), PHP 8.1+ con `pdo_mysql`,
`curl` y `pcntl`, cliente `mariadb` en el PATH. Por defecto se conecta a
`127.0.0.1:3307` como `root` sin clave (`--host`, `--bdpuerto`, `--usuario`,
`--clave` para cambiarlo; también en `webservice/privado/config.php`).

```bash
cd simulacion
php simular.php --duracion=300 --semilla=7          # 5 minutos reales, 3 tiendas
php simular.php --duracion=120 --tiendas=5 --articulos=50
php informe.php                                       # relanzar solo la verificación
```

Los registros de cada proceso quedan en `--dir` (por defecto
`/tmp/viracash_sim`): `subida_TIENDA1.log`, `escucha_TIENDA1.log`,
`caja_TIENDA1.log`, `webservice.log`.

Para arrancar los componentes a mano:

```bash
mariadb < sql/central.sql; mariadb < sql/webservice.sql
sed 's/__TIENDA__/tienda_t1/g' sql/tienda.sql | mariadb
mariadb -e "CALL webservice.sp_alta_terminal('TIENDA1','tokenlargo123456','ALM1');
            CALL tienda_t1.sp_configurar('TIENDA1','ALM1','CENTRAL')"
(cd webservice && PHP_CLI_SERVER_WORKERS=8 php -S 127.0.0.1:8085 router.php)
php tienda/agente.php --terminal=TIENDA1 --bd=tienda_t1 --url=http://127.0.0.1:8085 --token=tokenlargo123456 --rol=inicial
php tienda/agente.php ... --rol=escucha &
php tienda/agente.php ... --rol=subida &
mariadb tienda_t1 -e "CALL sp_vender(UUID(),'ART001','ALM1',1,NULL,'EN_LINEA')"
```

## Qué hace la simulación

Tres tiendas, 30 artículos, poco stock en `CENTRAL`. Cada caja vende
(~1,5 operaciones/s), devuelve, recibe albaranes, pide a la central,
traspasa, recibe traspasos (tardan 30 s), inventaría con merma, da de alta
artículos y consulta el stock de otros almacenes. La central cambia
precios. Internet: 40 ms de ida y vuelta y 3 % de peticiones y respuestas
perdidas (muy pesimista). `TIENDA2` pierde la conexión el 30 % del tiempo,
`TIENDA1` y `TIENDA3` el 10 %, y a `TIENDA3` se le matan y relanzan los
agentes en plena desconexión.

Al terminar se deja la red perfecta, se drena, y el informe verifica:

- central: stock = suma de movimientos, nada en tránsito, ninguna
  sobreventa con reserva concedida, ninguna reserva huérfana;
- cada tienda: todos sus eventos confirmados y presentes en la central;
  stock propio idéntico al de la central artículo por artículo; copia de
  los demás almacenes idéntica; catálogo y precios idénticos; traspasos
  enviados recibidos y ninguno por recibir; pedidos con confirmación;
  todos los avisos de sobreventa; cursor confirmado en el webservice.

Y mide la vigencia con reloj real: latencia de cada novedad de stock
(mediana, p95, máximo, reparto; aparte, solo cuando la tienda tenía
conexión) y exactitud de cada consulta de stock hecha en caja frente a lo
que tenía la central en ese instante, con la antigüedad que se mostró.

## Paso a producción

- **Tienda (Delphi)**: los procedimientos de `tienda.sql` son la API que
  usaría ViraCash desde UniDAC; `agente.php` es la especificación de los
  dos hilos de sincronización; `internet.php` sin la simulación es
  `TClienteViraCashApi`.
- **Webservice**: los PHP valen tal cual tras un servidor web real (HTTPS,
  PHP-FPM); la espera larga necesita que el servidor admita peticiones de
  25 s abiertas (ajustar `max_execution_time` y el tiempo de espera del
  proxy).
- **Central**: `sp_caducar_reservas(15)` en un evento programado; purga de
  novedades por debajo de la mínima `version_confirmada`; un terminal nuevo
  parte de una instantánea y fija su cursor en la versión de esa
  instantánea.
- **Traspasos**: si la mercancía llega antes que el aviso (origen sin red),
  hará falta una "entrada pendiente de traspaso" que se case después.
