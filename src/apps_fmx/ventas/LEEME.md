# VentasViraCash — ventas del día en el móvil

App FMX de **solo lectura**. Enseña las líneas de venta de un día con su
foto y el total del día. No escribe nada en ViraCash.

Proyecto independiente, igual que `recuento`: no se compila dentro de
`vcash.dproj` y la UI se construye por código, sin `.fmx`.

## Qué se ve

Por línea: hora, SKU, descripción, temporada, proveedor, importe y la foto
del artículo a 300 px. Al tocar una fila se abre la ficha con todo:
familia, color, precio de coste, PVP, descuento en % y en euros, precio de
venta y total.

En la cabecera, los cuatro totales del día: **venta**, **coste**,
**margen** (importe y %) y **descuento**. Si escribes en el buscador, los
totales pasan a ser los de lo filtrado y se rotula «(filtrado)».

> El margen se calcula contra la **base imponible**, no contra la venta con
> IVA: el precio de coste no lleva IVA, así que restarlo del importe con
> IVA daría un margen inflado de varios puntos. Por eso la app enseña la
> venta con IVA (que es lo que cuadra con la caja) y a la vez un margen
> honesto.

## Puesta en marcha

1. Con `CertApiWeb`, crear una credencial con los ámbitos **`ventas:leer`**
   y **`fotos:leer`**. Sin el segundo el listado sale sin fotos.
2. En el servidor: subir `ventas/lineas.php`, `fotos/imagen.php` y
   `privado/ventas_proyeccion.php`, y lanzar
   `sql/esquema_ventas_lineas.sql` contra la BBDD del webservice.
3. Abrir la app, botón ⚙, y rellenar URL base, token y referencia.

## Manejo

- En la ficha de una venta, **Ver ticket** descarga su PDF almacenado en
  `api_ventas_documentos`. Usa `ventas/documento.php` con `ventas:leer`,
  sin volver a enviar la venta ni poner la API en el enlace.
- Android abre el visor PDF instalado mediante un permiso temporal de
  lectura; Windows usa su aplicación PDF asociada. Se necesita un visor
  PDF instalado. En iPhone se usa la consulta web de ventas; la apertura
  nativa iOS no está verificada en esta entrega.
- Cada apertura comprueba nuevamente la credencial y valida el tamaño
  (máximo 20 MB), formato y SHA-256 del PDF. Los temporales son privados,
  no se reutilizan, y los de más de ocho horas se eliminan al abrir otro
  ticket. Cerrar la ficha cancela la apertura pendiente.
- **◀ / ▶** cambian de día. Tocar la fecha vuelve a hoy.
- El buscador filtra en local sobre lo ya descargado, así que va instantáneo
  y no vuelve a llamar al servidor.
- Las ventas **anuladas** no cuentan ni salen. El endpoint las excluye salvo
  que se pida `incluir_anuladas=1`.

## Detalles de implementación

- **Fotos**: viajan **dentro del evento de venta**, en la versión de 300 px
  que ViraCash ya tiene generada en `appDirFotos\300\`. El servidor las
  guarda en `api_articulos_fotos`, una fila por artículo y clave de unidad,
  no una por línea: el mismo artículo vendido cien veces guarda una sola
  foto, y si la huella SHA-256 no ha cambiado ni se reescribe el blob.
  La app las pide a `ventas/foto.php`, que solo necesita `ventas:leer` — no
  hace falta el subsistema `fotos_nube` ni el ámbito `fotos:leer`.
  Se descargan en segundo plano después de pintar la lista, así que el
  listado sale de inmediato aunque la red vaya lenta, y quedan cacheadas en
  disco con ETag.
- **Cambio de día durante una descarga**: cada carga lleva un número de
  generación; si cambias de día a media descarga, las fotos pendientes se
  abandonan en vez de pintarse sobre la lista nueva.
- **El día es el de la factura** (`FECHA_FAC`), no el instante UTC de
  recepción. Así el corte del día es el del negocio y no baila con el huso
  horario ni con cuándo se sincronizó el ticket.
- Cada hilo usa su propia instancia de `TVentasApi`: `THTTPClient` no es
  seguro de compartir entre hilos.

## Limitación conocida

La **temporada** de las ventas enviadas **antes** de este cambio llega
vacía: esos eventos se serializaron sin ella y no se puede reconstruir hacia
atrás. Se arregla sola en cuanto esas ventas se vuelvan a enviar; las nuevas
la traen desde el primer momento.
