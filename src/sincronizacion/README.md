# Sincronización cliente-servidor (simulación)

Simulación ejecutable de la arquitectura con la que cada caja de ViraCash
**envía sus ventas** al servidor central y **recibe novedades** (precios,
bajas de artículos) mediante un servicio con **acuses**, siendo
**tolerante a desconexiones**, pérdidas de mensajes, duplicados y reinicios.

Igual que `pruebaventasws`, son proyectos **independientes**: no se
compilan dentro de `vcash.dproj`. El código es Object Pascal sin VCL ni
UniDAC y compila tanto en Delphi como en Free Pascal.

## Arquitectura

```
        TERMINAL (caja)                                  SERVIDOR
 ┌───────────────────────────────┐                ┌──────────────────────────┐
 │ Venta ──(misma transacción)──►│                │                          │
 │   fza_ventas_ws_cola          │  EnviarVentas  │ srv_sincro_ventas        │
 │   (bandeja de salida)  ───────┼──────lote─────►│  PK = ID_EVENTO          │
 │   PENDIENTE→CONFIRMADA ◄──────┼──acuse/venta───┤  ACEPTADA/REPETIDA/      │
 │            →RECHAZADA         │                │  RECHAZADA               │
 │                               │                │                          │
 │   fza_sincro_cursor    ───────┼─PedirNovedades►│ srv_sincro_novedades     │
 │   (última versión aplicada)◄──┼──página────────┤  registro de solo añadir │
 │                        ───────┼─Confirmar─────►│ srv_sincro_terminales    │
 │                               │  (hasta v)     │  versión confirmada      │
 └───────────────────────────────┘                └──────────────────────────┘
          TClienteSincro         IServicioSincro          TServidorSincro
```

Dos canales independientes; cada uno con su propia garantía:

| Canal | Quién guarda el progreso | Garantía | Cómo |
|---|---|---|---|
| Subida (ventas) | El terminal (estado de cada fila de la bandeja) | Cada venta llega **exactamente una vez** a efectos de negocio | Entrega *al menos una vez* + idempotencia por `IdEvento` |
| Bajada (novedades) | El terminal (cursor) | Cada novedad se aplica **una vez y en orden** | Versión creciente + cursor atómico con el cambio |

## Reglas del protocolo

1. **Vender nunca depende de la red.** La venta se graba en la bandeja de
   salida en la misma transacción que la factura o el ticket.
2. **Una venta solo deja de estar PENDIENTE con un acuse del servidor.**
   `ACEPTADA` o `REPETIDA` → `CONFIRMADA`; `RECHAZADA` → `RECHAZADA` con
   motivo, y no se reintenta (es un error de negocio, no de red).
3. **Ante cualquier fallo de red, se reintenta.** El terminal no sabe si
   el servidor llegó a procesar el lote, y no necesita saberlo: el reenvío
   lleva el mismo `IdEvento` y el servidor responde `REPETIDA`. Espera
   exponencial 1, 2, 4… hasta `EsperaMaxima`.
4. **Una novedad se aplica y el cursor avanza en la misma transacción.**
   Lo que llegue con versión ≤ cursor se ignora.
5. **El acuse de novedades es informativo.** El terminal es el dueño de
   su cursor; el servidor solo lo usa para monitorizar y purgar. Si el
   acuse se pierde, el siguiente lo sustituye, y un acuse viejo nunca hace
   retroceder (`GREATEST`).
6. **El servidor asigna las versiones con un contador bloqueado, no con
   `AUTO_INCREMENT`.** Con autoincremento, una transacción con id menor
   puede confirmarse después que otra con id mayor y un terminal que ya
   hubiese leído la mayor se saltaría la menor para siempre.

## Fallos simulados

`TTransporteSimulado` se interpone entre cliente y servidor y provoca:

| Fallo | Qué pasa en el servidor | Qué ve el terminal | Resultado |
|---|---|---|---|
| Sin conexión | Nada | Error de red | Sigue PENDIENTE, reintento |
| Petición perdida | Nada | Tiempo agotado | Sigue PENDIENTE, reintento |
| **Respuesta perdida** | **Lo procesa** | Tiempo agotado | Reenvío → `REPETIDA` → CONFIRMADA |
| Duplicado | Lo recibe dos veces | Respuesta normal | La segunda es `REPETIDA` |
| Reinicio del terminal | — | Pierde la memoria del motor | Bandeja y cursor persisten |

## Ficheros

| Fichero | Contenido |
|---|---|
| `inLibSincroProtocolo.pas` | Mensajes y contrato `IServicioSincro` |
| `inLibSincroServidor.pas` | Servidor en memoria con las reglas del servidor real |
| `inLibSincroCliente.pas` | `TAlmacenCliente` (estado persistente) y `TClienteSincro` (motor) |
| `inLibSincroTransporteSimulado.pas` | Red poco fiable con semilla reproducible |
| `SimulacionSincro.dpr` | Simulación de 3 cajas con cortes, pérdidas y un reinicio |
| `PruebasSincro.dpr` | 11 escenarios deterministas, uno por fallo |
| `sql/esquema_sincro.sql` | Tablas y consultas para llevarlo a MariaDB |

## Ejecutar

Delphi: abrir el `.dpr` en RAD Studio y compilar como aplicación de consola.

Free Pascal:

```bash
fpc SimulacionSincro.dpr && ./SimulacionSincro            # semilla 2026, 600 ticks
./SimulacionSincro 42 1500                                # otra semilla y duración
fpc PruebasSincro.dpr && ./PruebasSincro
```

Ambos devuelven código de salida 0 si todo se cumple y 1 si no, de modo
que pueden ejecutarse en integración continua.

La simulación tiene tres fases:

1. **Operación** con red inestable (20 % de peticiones perdidas, 15 % de
   respuestas perdidas, 5 % de duplicados), un corte largo en CAJA2, cortes
   cortos en CAJA1 y CAJA3, y un reinicio de CAJA3 en plena desconexión.
2. **Drenaje**: se restablece la red y se sincroniza hasta vaciar colas.
3. **Verificación** de invariantes:
   - ventas creadas = confirmadas + rechazadas, sin pendientes;
   - toda venta confirmada está en el servidor con los mismos datos;
   - ninguna venta rechazada está en el servidor;
   - nº de ventas en el servidor = suma de confirmadas (ningún duplicado);
   - el catálogo de cada caja es idéntico al del servidor;
   - el servidor tiene confirmada la última versión de cada caja.

Ejemplo de salida (semilla 2026): 520 ventas en el servidor, 114 reenvíos
detectados como `REPETIDA`, ninguno duplicado, y las tres cajas en la
versión 61 del catálogo.

## Paso a producción

- **Subida**: la cola actual `fza_ventas_ws_cola` ya es la bandeja de
  salida (alta transaccional, `ID_EVENTO_VWSC`, reintentos y el servidor
  responde `repetido: true`). Solo hace falta añadir `SECUENCIA_VWSC` para
  que el servidor detecte huecos.
- **Bajada**: es lo nuevo. Un hilo como `THiloVentasWsCola` que llame a
  `TClienteSincro.Sincronizar` tras cada ciclo de envío, con
  `TAlmacenCliente` sustituido por un repositorio UniDAC sobre
  `fza_sincro_cursor` y las tablas de artículos.
- **Transporte**: implementar `IServicioSincro` sobre
  `TClienteViraCashApi.EnviarJson`/`RecibirJson`, convirtiendo los errores
  HTTP 5xx, los tiempos agotados y la falta de conexión en
  `ETransporteSincro` (reintentable) y los 4xx de validación en acuses
  `RECHAZADA`.
- **Servidor**: los endpoints `sincro/ventas.php`, `sincro/novedades.php`
  y `sincro/novedades_ack.php` siguen las consultas comentadas en
  `sql/esquema_sincro.sql`.
- **Purga**: las novedades con versión menor que la mínima
  `VERSION_CONFIRMADA` de los terminales activos pueden archivarse. Un
  terminal nuevo, o uno con el cursor por debajo de lo purgado, debe
  partir de una instantánea completa del catálogo y fijar su cursor en la
  versión de esa instantánea.
