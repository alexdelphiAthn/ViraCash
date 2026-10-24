# ViraCash Fotos Nube (app FMX para Android)

App **FireMonkey (FMX)** independiente para **Android** que hace fotos con
la cámara del dispositivo, las reduce a una resolución máxima configurable
(por defecto **1000 px** en el lado mayor) y las sube **por lotes** al
endpoint de fotos de la API v1 de ViraCash (`/api/v1/fotos/subir.php`).

Cada foto se identifica por **código de artículo**, **color** e **índice**.
Los tres valores son visibles antes de capturarla; el índice vale **1 por
defecto** y debe ser un entero mayor o igual que 1.

Es un proyecto Delphi **independiente** (`SubirFotosFmx.dpr`), igual que
`utilnormbbdd` o `utilmigsqlsrv`: **no** se compila dentro de `vcash.dproj`.
El uploader VCL de escritorio de `src/fotos_nube/oda/` (`Project1.dpr`,
`UFotoUploader`) sigue intacto; esta carpeta `fmx/` es la versión móvil que
habla con el mismo webservice.

## Estructura

```
fmx/
├── SubirFotosFmx.dpr      Proyecto FMX (Android64).
├── SubirFotosFmx.dproj
├── UPrincipal.pas/.fmx    Form principal: captura, cola y configuración.
├── UConfigFotos.pas       Configuración persistente en INI local.
├── UImagenUtil.pas        Redimensionado de la foto al máximo (JPG).
├── UColaFotosNube.pas     Cola de subida por lotes (hilo de fondo).
└── LEEME_FMX.md           Este fichero.
```

## Flujo

1. **Configuración** (pestaña *Configuración*): URL del endpoint, token
   de API, referencia de instalación (`referencia`, obligatoria) y resolución
   máxima (por defecto 1000). Se guarda en `fotosnube.ini` dentro de la
   carpeta de documentos de la app (sandbox). La ruta exacta se muestra en
   pantalla. La referencia debe coincidir con la asociada al token.
2. **Capturar** (pestaña *Capturar*): se teclea el **código de artículo**
   el **color** y el **índice de foto** (1 por defecto); *Hacer foto* abre
   la cámara y *Elegir de galería* la toma del carrete. Cada foto se reduce
   al máximo configurado y se añade a la cola con su artículo+color+índice
   y estado *Pendiente*.
3. **Subir todas**: envía en segundo plano todas las fotos no subidas.
   Cada elemento pasa a *Subiendo…* → *Subida OK* / *Error*, y el log
   muestra el `sha256` devuelto o el mensaje de error.

## Índice por artículo+color

El webservice nombra cada fichero como `ARTICULO_COLOR_INDICE` y exige los
tres campos no vacíos, así que **siempre se envía el índice visible** (>= 1):

- Una sola foto de un artículo+color → `indice` = 1
  (`ARTICULO_COLOR_1_real.png`).
- Varias del mismo artículo+color → se indica 1, 2, 3… antes de capturar
  cada una (`_1_…`, `_2_…`, etc.).

El índice queda guardado al encolar y no se recalcula al subir, por lo que
el nombre remoto coincide con el valor mostrado al hacer la foto. Después de
encolar correctamente, el campo avanza al siguiente número. La app rechaza
dos fotos pendientes con el mismo artículo, color e índice para evitar que
una sobrescriba a la otra.

## Contrato de la API v1

`POST` multipart/form-data a `/api/v1/fotos/subir.php` con:

| Campo             | Obligatorio | Notas                                  |
|-------------------|-------------|----------------------------------------|
| `imagen`          | sí          | El JPG reducido.                       |
| `articulo`        | sí          | Código de artículo.                    |
| `referencia`      | sí          | Nombre de la instalación.            |
| `color`           | sí          | Color.                                 |
| `indice`          | sí          | Entero visible >= 1; valor inicial 1.  |
| `nombre_original` | no          | Nombre del fichero local.              |
| `osha1`           | no          | SHA1 local para verificación e2e.      |

El token se envía como `Authorization: Bearer fza_...`. La respuesta JSON
usa `{ "ok": true, "datos": { "sha256_real": "..." } }`; los errores se
devuelven en `error.mensaje`.

## Compilación y despliegue (RAD Studio)

> No se puede compilar en este entorno (no hay Delphi). Abrir el `.dproj`
> en **RAD Studio 12 (Athens)** o superior con el **SDK/NDK de Android**
> configurado.

### Permisos de Android

La app pide el permiso de **cámara** en tiempo de ejecución al pulsar
*Hacer foto* (`ConPermisoCamara` en `UPrincipal`). **Pero eso solo funciona
si el permiso está declarado en el manifest**: hay que **marcar los
permisos** en *Project ▸ Options ▸ Application ▸ Uses Permissions* (con la
plataforma **Android 64-bit** seleccionada):

- `Camera` (cámara) — **obligatorio**; si no, Android deniega sin preguntar.
- `Internet` (ya activo por defecto) — necesario para la subida.
- `Read external storage` / `Read media images` — para *Elegir de
  galería* según versión de Android.

(Los permisos también van declarados como `Android_*` en el `.dproj`, así
que normalmente no hay que tocarlos a mano.)

### Icono y splash de Android

El proyecto **no incluye** icono ni splash propios: se generan desde el IDE
en *Project ▸ Options ▸ Application ▸ Icons* y *Splash Images* (con
**Android 64-bit** seleccionado), p. ej. con un texto convertido en imagen.
El IDE añade los recursos y su despliegue al `.dproj` al guardarlos.
El tema es `NoTitleBar` para no depender del icono de la ActionBar al
arrancar (antes causaba un crash `Resources NotFoundException`).

Si ya instalaste la app y denegaste el permiso, vuelve a concederlo en
*Ajustes de Android ▸ Aplicaciones ▸ ViraCash Fotos Nube ▸ Permisos*.

## Nota sobre la versión (regla 6 de CLAUDE.md)

La regla de *pumpear la versión* aplica al binario principal (`viracash`) a
través de `inLibGlobalVar.pas`. Esta app FMX es un proyecto separado que
**no enlaza** esa unit, así que **no** se ha tocado la versión global de
`viracash`. La versión de esta app se define en `UPrincipal.pas`
(`cVersionApp`) y se muestra en el log al arrancar. Si se prefiere
unificar el versionado, indícalo y lo ajusto.
