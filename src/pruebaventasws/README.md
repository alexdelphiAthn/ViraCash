# PruebaVentasWs — careta del webservice de ventas

Proyecto Delphi **independiente** (no se compila dentro de `vcash.dproj`)
para probar de extremo a extremo el envío de ventas al webservice y su
posterior lectura.

## Qué prueba

- **Enviar**: genera el evento con el **mismo serializador de producción**
  (`TVentasWsJson.ConstruirEvento`), lo muestra en un memo editable y lo
  postea a `ventas/eventos.php`. Al reutilizar la unidad real, lo que se
  valida aquí es el contrato de verdad, no una copia que se desincroniza.
- **Consultar**: recupera del servidor lo que quedó almacenado —listado,
  detalle completo y descarga de los PDF—, para verificar que lo enviado
  se ha proyectado bien.

## Configuración

En la cabecera del formulario:

| Campo | Equivale al parámetro |
|---|---|
| URL base de la API | `appApiUrl` |
| Token | `appApiToken` |
| Referencia | `appApiReferencia` |

La credencial necesita los ámbitos `ventas:escribir` (pestaña Enviar) y
`ventas:leer` (pestaña Consultar). Se generan con `CertApiWeb`.

Debajo van los datos de conexión a MariaDB. La conexión es directa
(`TUniConnection` con provider `MySQL`), sin pasar por el servicio de
conexiones de la aplicación, porque la careta no arranca el resto de
ViraCash.

## Uso

1. Rellenar URL, token y referencia. **Probar API** hace un GET contra
   `prueba.php` para confirmar que la credencial responde.
2. **Conectar BBDD** con los datos de la instalación a probar.
3. Pestaña *Enviar venta*: serie y número de una factura existente en
   `fza_facturas`, tipo de evento y secuencia. **Generar JSON** y, si el
   contenido es correcto, **Enviar al webservice**.
4. Pestaña *Consultar ventas*: **Listar** con los filtros que interesen,
   doble clic sobre una fila para ver el detalle y los botones de
   descarga para traerse los PDF (se guardan en *Documentos*).

## Notas

- **Secuencia / ID cola**: cumple dos funciones. Viaja como
  `secuencia_evento` (el servidor exige un entero ≥ 1 y solo proyecta el
  evento si supera la última secuencia recibida) y, si coincide con un
  `ID_VWSC` real de `fza_ventas_ws_cola`, arrastra los PDF adjuntos de esa
  fila. Para una prueba limpia basta con ir subiéndola: 1, 2, 3…
- Reenviar dos veces el mismo JSON devuelve **200 con `repetido: true`**;
  es la idempotencia por `id_evento`. Cada pulsación de *Generar JSON*
  crea un `id_evento` nuevo, así que para probar el reenvío hay que
  enviar dos veces sin regenerar.
- El JSON del memo es editable a propósito: sirve para provocar errores
  de validación del servidor (tipo de evento inválido, huella de PDF que
  no cuadra, referencia ajena…) y comprobar que responde como debe.
- La careta **no escribe en `fza_ventas_ws_cola`**: no interfiere con el
  hilo de la cola real si se prueba contra una instalación en marcha.
