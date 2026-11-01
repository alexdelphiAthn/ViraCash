# Listas de regalos (nacimiento, bautizo, comunión)

Proyecto separado, pendiente de fundir con ViraCash. Los titulares eligen
artículos en la tienda y cada invitado regala el que quiera, **en caja o en
PrestaShop**. ViraCash es la única fuente de verdad: guarda las listas, los
regalos y los totales; la tienda web muestra lo pendiente, reserva lo que el
invitado mete en el carrito y anota el regalo cuando se valida el pedido.

```
lista_regalos/
  sql/          scripts idempotentes + rollback (irán a DESARROLLOS EN CURSO)
  prestashop/   módulo vcashlistaregalos (PrestaShop 8.0 – 9.x)
  prototipo/    sincronizador en Python = lo que hará ViraCash en Delphi
  pruebas/      batería SQL desechable y prueba de extremo a extremo
```

## Funcionamiento

1. **Alta en tienda.** El dependiente crea la lista (`PRC_LRG_CREAR`), que
   recibe un código correlativo (contador `LR`) y una **clave pública** de
   8 caracteres sin 0/O ni 1/I/L, para dictarla por teléfono. Los artículos
   se añaden escaneando (`PRC_LRG_LINEA_AGREGAR`); escanear dos veces el
   mismo SKU suma cantidad.
2. **Publicación.** El sincronizador manda a cada tienda PrestaShop las
   listas cuya versión no tiene (`PRC_LRG_PUBLICACIONES_PENDIENTES`) y
   confirma la versión enviada (`PRC_LRG_PUBLICACION_CONFIRMAR`).
3. **Regalo en caja.** La caja busca la lista (`PRC_LRG_BUSCAR`: código,
   clave, titulares, homenajeado o cliente), elige la línea y, dentro de la
   transacción de la operación, llama a `PRC_LRG_REGALO_CAJA`. Sin forzar,
   no deja regalar más de lo pendiente.
4. **Regalo en la web.** El invitado abre `/lista-regalos/<clave>` (o busca
   en `/listas-regalos`), escribe su nombre y su mensaje y pulsa «Regalar».
   El módulo bloquea la lista, comprueba lo pendiente, añade al carrito y
   **reserva** la cantidad. Al validarse el pedido, la reserva pasa a regalo
   web PENDIENTE y el pedido lleva una nota privada con la lista.
5. **Recogida.** El sincronizador lee esos regalos (`accion=regalos`), los
   registra con `PRC_LRG_REGALO_WEB` y, al republicar la lista, le dice a la
   tienda qué líneas de pedido ya cuentan (`regalos_web_incluidos`), que
   pasan a REGISTRADO en la misma transacción: así no se restan dos veces.
6. **Entrega y cierre.** `PRC_LRG_REGALO_ENTREGAR` marca lo que se lleva la
   familia. `PRC_LRG_CERRAR` fija el total regalado y la **bonificación**
   (`PORCENTAJE_BONIFICACION_LRG`); al republicar, la lista desaparece de la
   web (404).

### Lo pendiente en la web

```
pendiente = deseada
          − regalada según ViraCash (caja + web ya registrada)
          − regalos web que ViraCash aún no ha recogido
          − reservas vigentes de otros carritos
```

Una reserva cuenta mientras su carrito tenga el producto, no se haya
convertido en pedido y no haya caducado (60 minutos por defecto,
configurable en el módulo). Un mismo producto de un carrito solo puede ir a
una línea de lista, así cada línea de pedido es un único regalo en ViraCash.

### Decisiones tomadas

- **Cantidades en `int`** (son unidades) y **sin contador en la línea**: lo
  regalado se suma desde los regalos (`VI_LRG_LINEAS_ESTADO`), no se
  guarda, para que no pueda descuadrar.
- **Excedentes.** Un pedido web ya pagado nunca se rechaza: si supera lo
  pendiente (por ejemplo, una venta de caja entre el pedido y la
  sincronización), se registra con `ESEXCEDENTE_LRGREG = 'S'` (resultado 2)
  y la tienda gestiona el cambio. La caja sí se frena (-5) salvo que
  fuerce.
- **Otra talla o color.** Con `ESADMITE_OTRA_VARIANTE_LRGLIN = 'S'`, el
  invitado puede regalar otro SKU del mismo artículo, en caja y en la web
  (selector de combinación).
- **Idempotencia.** La caja se identifica por almacén + caja + operación +
  línea; la web, por origen + línea de pedido. Reintentar devuelve 3 sin
  duplicar.
- **Bloqueos.** El regalo bloquea la línea (`FOR UPDATE`) y lee la lista
  compartida, para serializarse con otra caja y con el cierre.
- **Lista cerrada.** No admite regalos, cambios de líneas ni anulaciones;
  un regalo web que llegue después se rechaza (-1) y el pedido queda como
  una venta normal.
- **Agotado.** Un artículo sin existencias (y sin venta en descubierto) no
  se ofrece en la web, pero sigue en la lista para regalarlo en caja.

## Base de datos

| Tabla | Sufijo | Contenido |
|---|---|---|
| `fza_listas_regalos` | `LRG` | cabecera, estado, clave pública, bonificación, versión |
| `fza_listas_regalos_lineas` | `LRGLIN` | SKU deseado, cantidad, imprescindible, otra variante |
| `fza_listas_regalos_regalos` | `LRGREG` | cada regalo: canal, importe, regalante, entrega |
| `fza_listas_regalos_publicaciones` | `LRGPUB` | versión publicada por tienda |

Estados: lista `ABIERTA` → `CERRADA` | `ANULADA` (solo sin regalos);
regalo `CONFIRMADO` → `ANULADO` (devolución, solo con la lista abierta).

**Códigos de `p_RESULTADO`:** 1 correcto · 2 correcto con matiz (cantidad
sumada o excedente) · 3 ya registrado (reintento) · 0 nada que hacer ·
-1 lista inexistente o no abierta · -2 línea inexistente o inactiva ·
-3 SKU no válido · -4 cantidad no válida · -5 supera lo pendiente o deja la
línea por debajo de lo regalado · -6 el estado no lo permite.

Los procedimientos que escriben toman la transacción solo si no hay una
abierta (mismo patrón que `PRC_GET_NEXT_CONTADOR`). Parámetros y variables
de texto declaran `utf8mb4_spanish_ci`: la batería lo prueba sobre una BBDD
con otra colación por defecto, donde sin ello salta el error 1267.

## API del módulo

`<tienda>/index.php?fc=module&module=vcashlistaregalos&controller=api&accion=…`
con la cabecera `X-Vcash-Clave` (se genera al instalar; se ve y se regenera
en la configuración del módulo). Respuestas JSON con `ok`; los errores
llevan `error` y código HTTP 400, 401, 404 o 500.

| Acción | Método | Cuerpo / parámetros | Respuesta |
|---|---|---|---|
| `versiones` | GET | — | `listas: [{codigo, version, visible}]` |
| `publicar` | POST | `lista`, `lineas`, `regalos_web_incluidos` | `ignorada`, `skus_sin_producto` |
| `regalos` | GET | `desde`, `limite` (≤ 500) | `regalos: [...]` pendientes |
| `confirmar` | POST | `ids_linea_pedido`, `estado` (`REGISTRADO`/`RECHAZADO`) | `confirmados` |

`publicar` sustituye la lista y sus líneas; si la tienda ya tiene una
versión posterior, la ignora. Cada línea se enlaza por `reference`: la de la
combinación es el código de SKU y la del producto, el código de artículo
(lo mismo que publica ViraCash, `inLibPrestaShopCola.pas`). Una referencia
ambigua o ausente deja la línea «Disponible en la tienda». Los regalos
llevan `valido` e `id_estado_pedido` del pedido de PrestaShop.

El ejemplo completo del cuerpo de `publicar` es `leer_lista()` en
`prototipo/sincronizar_listas.py`.

## Pruebas

```powershell
py -3.14 pruebas\test_listas_regalos.py -v
```

Levanta un MariaDB 12.3 desechable en `%TEMP%`, copia del modelo
`fza_contadores`, `fza_articulos_skus` y `PRC_GET_NEXT_CONTADOR`, y
comprueba en 15 casos: aplicar dos veces, revertir dos veces, volver a
aplicar, colación distinta, numeración, líneas, regalos de caja y web,
otra variante, anulación, entrega, cierre, búsqueda, publicaciones y el
bloqueo entre dos cajas (1205). Última ejecución: 15/15.

```powershell
py -3.14 pruebas\e2e_puericultura_lab.py
```

Prueba de extremo a extremo con datos reales: copia del bazar
`fzam_bazar_turnos_listas` (motor de la batería 16, 127.0.0.1:34712) y el
laboratorio PrestaShop (127.0.0.1:8081). Crea una lista de bautizo con el
faldón, los recordatorios y las cajitas; regala en caja y en la web (el
pedido se valida con el núcleo de PrestaShop, así que salta el hook real),
sincroniza, comprueba que nada cuenta dos veces y cierra la lista (82,40 €
regalados, 4,12 € de bonificación). Última ejecución: 22/22.

### Batería para un agente

`factuzam_web\tests\listas_regalos` (37 casos en `casos.json`, LEEME con
el escenario, `preparar.sh`, verificaciones SQL de ViraCash y de la tienda).
Base propia `fzam_listas_regalos` en 34712; los esperados se fijaron con
`ensayo_esperados.py` (0 fallos el 01/11/2026).

## Estado del entorno de juego (31/10/2026)

- **ViraCash:** `fzam_bazar_turnos_listas` en 127.0.0.1:34712, copia de
  `fzam_bazar_turnos` (que no se ha tocado) con los scripts aplicados.
  Lista abierta de demostración **000002 «Lista de nacimiento de Vera»**
  (clave `FW752TW5`): sillas de coche, trona y silla de paseo (esta, sin
  existencias en la web). Las listas de bautizo de la E2E quedan cerradas.
- **PrestaShop:** módulo instalado; los 7 artículos de puericultura (QB-P8)
  publicados en la categoría *Puericultura* con `prototipo\sincronizar_listas.py
  catalogo`. La lista de Vera se ve en
  http://127.0.0.1:8081/lista-regalos/FW752TW5.
- Para sincronizar a mano después de tocar la copia:
  `py -3.14 prototipo\sincronizar_listas.py sincronizar --clave <clave API>`.

## Pantalla en ViraCash (31/10/2026)

**Ventas Mayor ▸ Lista de regalos Prestashop**, visible solo con el
parámetro **`appListasRegalos`** (grupo PrestaShop de Parámetros de Entorno,
apagado por defecto). Se reevalúa al desplegar Ventas Mayor, así que
activarlo no exige reiniciar. Con él encendido, el permiso
`menu.ListasRegalosPrestaShop` sigue decidiendo si se puede abrir.

- **Lista:** filtro por estado y por titulares o código, y botón
  «Sincronizar con PrestaShop».
- **Ficha:** cabecera editable (al grabar sube `VERSION_LRG`); botones
  Cerrar lista y Anular lista.
- **Pestaña Artículos:** alta por SKU o código de barras con el precio de la
  tarifa web (`appPrestaShopTarifa`), «Cambiar cantidad» y casillas de
  imprescindible, otra talla u observaciones.
- **Pestaña Regalos:** Marcar entregado y Anular regalo.
- **Sincronización:** usa `appPrestaShopUrl` y la clave del módulo,
  **`appPrestaShopClaveListasRegalos`**.

Unidades en `ViraCash\src`: `inMtoListasRegalos` (pantalla),
`UniDataListasRegalos` (data module), `inLibListasRegalos` (dominio),
`inLibListasRegalosPrestaShop` (cliente HTTP y JSON),
`inLibListasRegalosSincronizacion` (caso de uso),
`UniDataListasRegalosSincronizacion` (repositorio) y
`inLibMsgListasRegalos` (117 textos registrados para traducción). La
pantalla se registra con `sql\20261031_listas_regalos_pantalla.sql`
(`fza_winforms` y permiso).

`pruebas\e2e_sincronizador_delphi.py` compila
`pruebas\delphi\PruebaSincronizacionListas.dpr` con esas unidades y
repite el circuito contra la copia y la tienda. Última ejecución: 10/10.

## Fusión con ViraCash (pendiente)

1. **Scripts.** Mover `sql\*.sql` a `factuzam_web\DESARROLLOS EN CURSO` con
   la numeración vigente y ajustar `-- @requiere`. Ya van en UTF-8 con BOM
   y CRLF. Registrar los cuatro sufijos en `LIBRO_DE_ESTILO_BBDD.md` y
   en `UNormalizerEngine.pas` → `InitDefaults`.
2. **Vale de bonificación** al cerrar (`fza_caja_vales`, enlazado en
   `CODIGO_VL_LRG`): la pantalla ya fija el importe, falta emitirlo.
3. **Caja:** botón «Lista de regalos» (buscar, elegir línea, nombre y
   mensaje del regalante), llamada a `PRC_LRG_REGALO_CAJA` dentro de la
   transacción de la operación y ticket regalo. Devoluciones →
   `PRC_LRG_REGALO_ANULAR`.
4. **Sincronización automática:** hoy se lanza con el botón de la
   pantalla; falta engancharla en segundo plano junto a la importación de
   pedidos, y anular el regalo de un pedido cancelado en PrestaShop.
5. **Traducciones:** los textos ya están registrados; faltan las filas de
   `fza_traducciones` en los otros idiomas (delta como en las demás tandas)
   y los dominios del módulo (`Modules.Vcashlistaregalos.Shop` y
   `.Admin`).
6. **Informes:** lista para los titulares (regalado, quién, mensajes) y
   lista de lo que queda, con el descuento de cierre
   (`PORCENTAJE_DESCUENTO_CIERRE_LRG`, aún sin uso).

Queda fuera de esta primera versión: aportaciones parciales a un artículo
caro entre varios invitados, aviso por correo a los titulares y multitienda
dentro de una misma instalación de PrestaShop.
