# ViraCashControlU — consulta móvil de stock

Proyecto FireMonkey independiente para consultar el stock de ViraCash desde
Windows o Android. Parte del proyecto `ControlU`, pero vive aislado de
`vcash.dproj`: abrir y compilar `ViraCashControlU.dproj` por separado.

## Funciones

- Acceso por una única URL base del servidor interno, usuario ViraCash y
  contraseña.
- Consulta manual de artículo o lectura EAN-8/EAN-13 con la cámara. El lector
  ofrece una linterna continua cuando la cámara trasera del dispositivo la
  admite y la apaga antes de cerrar o liberar la cámara.
- Consulta de Stock, Entradas, Ventas y Ptes. de recibir. Stock es siempre el
  estado inicial.
- Cantidades pivotadas por color o almacén, con tallas y totales. El color de
  las cifras identifica el estado seleccionado.
- Filas desplegables para ver el segundo nivel de detalle.
- Filtros de colores y almacenes, columnas sin cantidad ocultables y
  desplazamiento horizontal para sistemas con muchas tallas.
- Los almacenes auxiliares (depósitos, taras y tránsito) aparecen en Filtros,
  pero están desmarcados inicialmente igual que en Control U.
- Histórico de los últimos artículos leídos con navegación anterior/siguiente.
- Foto representativa del artículo en la esquina superior derecha.

La foto se descarga en PNG y se limita en el cliente a **300 px en el lado
mayor**. Esto significa 300 píxeles, no 300 dpi. En pantalla se presenta como
miniatura proporcional para no quitar demasiado espacio a la rejilla.

## Contrato del servicio

La carpeta `servidor_php` incluye los endpoints listos para instalar en el
servidor interno. El móvil no se conecta directamente a la base de datos:

1. `POST <url-base>/login.php` con JSON `usuario` y `password`.
2. `GET <url-base>/stock.php?articulo=...&estado=stock` con
   `Authorization: Bearer <token>`.

`estado` admite `stock`, `entradas`, `ventas` y `pte_recibir`. Si se omite se
utiliza `stock` para conservar compatibilidad con clientes anteriores.

La URL base identifica la carpeta que contiene ambos PHP; por ejemplo,
`http://192.168.1.20/fzamcontrolu`. No existe un fallback a otro servidor:
el login, la consulta y la foto conservan siempre el mismo esquema, host y
puerto.

El login devuelve:

```json
{
  "ok": true,
  "datos": {
    "token": "...",
    "expira_en": 28800
  }
}
```

La consulta acepta tanto una respuesta directa como el envoltorio estándar
de ViraCash `{ "datos": { ... } }`:

```json
{
  "datos": {
    "articulo": "ABRIGO-PAÑO",
    "descripcion": "Abrigo de paño caballero",
    "estado": "stock",
    "cantidad_total": 6,
    "stock_total": 6,
    "unidad_consultada": "ABRIGO-PAÑO/CAMEL/M",
    "cantidad_unidad_consultada": 2,
    "cantidad_unidad_consultada_por_almacen": {
      "GEN - Almacén Central": 2
    },
    "colores": ["CAMEL"],
    "almacenes": ["GEN - Almacén Central"],
    "almacenes_predeterminados": ["GEN - Almacén Central"],
    "foto_300_url": "foto.php?articulo=ABRIGO-PA%C3%91O",
    "detalle": {
      "CAMEL": {
        "M": { "GEN - Almacén Central": 2 },
        "L": { "GEN - Almacén Central": 4 }
      }
    }
  }
}
```

La foto es opcional y puede llegar en cualquiera de estos formatos:

- `foto_300_url`, `foto_url` o `foto_ruta`: URL HTTP/HTTPS absoluta del mismo
  origen, ruta relativa a la URL base (`foto.php?...`) o ruta desde la raíz del
  host (`/api/fotos/imagen.php?...`). `foto_ruta` no puede ser una ruta de disco
  del servidor.
- `foto_300_base64`: PNG en Base64, con o sin prefijo `data:image/png;base64,`.
- `fotos[].contenido_base64`, usando la colección que ya genera ViraCash y
  seleccionando la entrada cuyo `articulo` coincida.

El cliente rechaza imágenes de más de 4 MiB para evitar consumos excesivos de
memoria antes de generar la miniatura de 300 px.

El servidor incluido devuelve una ruta relativa a `foto.php`, que lee
`appDirFotos/300` y exige el mismo Bearer. El cliente rechaza cualquier cambio
de esquema, host o puerto para no filtrar la credencial. La instalación y los
permisos mínimos de base de datos están documentados en
`servidor_php/LEEME.md`.

## Configuración y seguridad

- No hay una IP de cliente compilada dentro de la aplicación y solo se guarda
  una URL base.
- HTTPS se permite con cualquier host y exige un certificado válido del
  sistema.
- HTTP solo se admite para IPv4 privadas, loopback o link-local; IPv6 ULA,
  loopback o link-local; nombres sin punto; y nombres terminados en `.local`,
  `.lan` o `.internal`.
- Android permite técnicamente tráfico HTTP porque el host se configura en
  ejecución. La validación estricta se realiza en `uUrlSegura.pas` y también se
  aplica en Win32.
- No se siguen redirecciones HTTP: cada endpoint debe responder directamente
  en el mismo origen configurado.
- Las credenciales solo se conservan cuando se marca **Recordar acceso**.
  El almacenamiento heredado usa ofuscación local, no un almacén seguro del
  sistema; no debe considerarse cifrado fuerte.

La configuración se guarda en `ViraCashControlU/config.json`, dentro del espacio
privado de documentos de la aplicación.

En el acceso también se guarda la preferencia **Ocultar tallas sin stock**.
Está activada por defecto y solo oculta columnas cuya cantidad visible sea
cero en todas las filas; no elimina colores ni almacenes.

Para desplegar los PHP, publica únicamente `servidor_php/publico` y crea
`servidor_php/privado/config.php` a partir de la plantilla. Ese fichero real
está ignorado por Git y no contiene ningún valor de cliente en el proyecto.

> **Advertencia:** HTTP no cifra el usuario, la contraseña, el token ni los
> datos de stock. Debe utilizarse únicamente en una red interna controlada. La
> opción recomendada es HTTPS con un nombre DNS interno y un certificado
> válido.

## Compilación

Requisitos:

- Delphi 13 Florence (el `.dproj` usa formato de proyecto 20.3).
- Plataforma Android 64-bit con SDK/NDK configurados.
- ZXing.Delphi, incluido en `third_party/ZXing.Delphi` bajo licencia Apache
  2.0, para `ZXing.ScanManager`, `ZXing.BarcodeFormat` y `ZXing.ReadResult`.

El `.dproj` incorpora rutas relativas a esas fuentes, por lo que no depende de
la instalación global de ZXing.Delphi en la máquina de desarrollo.

El proyecto declara permisos de cámara, Internet y estado de red. Los iconos,
el icono adaptativo y el splash usan la imagen de marca de ViraCash incluida
en `ViraCashControlU.Artwork`.

Se han validado las configuraciones **Debug Win32** y **Debug Android64**. Para
publicar en Google Play hay que crear la configuración Android64 AppStore desde
las opciones del proyecto, seleccionar AAB y firmarla con el *keystore* de la
empresa; esas credenciales no se incluyen en el repositorio.
