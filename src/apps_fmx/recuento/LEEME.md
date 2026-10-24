# App de recuento (FMX Android)

App de mano para recontar inventarios escaneando códigos de barras. Sube los
eventos a un servidor PHP que hace de puente con ViraCash.

> Diseño completo y contrato del servidor en
> `DESARROLLOS EN CURSO/recuento_inventarios_app.md` y
> `.../recuento_inventarios_php.md`.

## Estructura

| Unidad | Responsabilidad |
|---|---|
| `RecuentoViraCash.dpr` | Proyecto. Crea el menú como formulario principal. |
| `RecuentoModelo.pas` | Tipos/records (almacén, plantilla, ítem de catálogo, evento) y `TModoRecuento`. |
| `RecuentoConfig.pas` | Config local (INI en Documentos): URL, carpeta, token, operario. Singleton `oConfig`. |
| `RecuentoApi.pas` | Cliente REST (`THTTPClient` + `System.JSON`) contra el PHP. |
| `RecuentoLocal.pas` | Cola offline en SQLite (UniDAC). Singleton `oLocal`. |
| `RecuentoSync.pas` | Vacía la cola subiendo por lotes (idempotente por uuid). |
| `fRecuentoMenu.pas` | Menú: 3 opciones + Configuración (formulario principal). |
| `fRecuentoSelector.pas` | Selector de lista (almacén / plantilla), modal asíncrono. |
| `fRecuentoConteo.pas` | Pantalla de conteo: escaneo → cola → sincronizar/finalizar. |
| `fRecuentoConfig.pas` | Configuración y alta de dispositivo (obtiene token). |

## Flujo

1. **Configuración** → URL del servidor, carpeta de cliente, operario y
   **Registrar dispositivo** (obtiene el token).
2. **Opción 1/2** → pregunta el **almacén** (recuento libre), crea el recuento y
   abre la pantalla de conteo (modo +1 o +cantidad).
3. **Opción 3** → elige una **plantilla** que envió ViraCash y cuenta contra su
   catálogo.
4. **Opción 4 (Traspaso)** → elige **origen** y **destino** y cuenta por cantidad
   lo que se mueve (parte del cliente; ViraCash generaría el traspaso al recoger).
5. En conteo: cada Intro en el campo de escaneo encola un evento con su día/hora.
   **Sincronizar** sube la cola; **Finalizar** sube lo pendiente y marca el
   recuento `RECONTADO`.

## Cómo compilar

No se ha podido compilar aquí (requiere RAD Studio + Android SDK/NDK; este
entorno no los tiene). Para construirla:

1. Abre `RecuentoViraCash.dpr` en RAD Studio (genera el `.dproj`).
2. Plataforma **Android** (o Win64 para probar en escritorio).
3. Dependencias: **UniDAC** de Devart con el provider **SQLite**
   (`SQLiteUniProvider`), y FMX (incluido). `System.Net.HttpClient` es RTL.
4. Permiso **INTERNET** en las opciones del proyecto (Android).

Las pantallas se construyen **por código** (sin `.fmx`) para no depender del
diseñador y que el esqueleto compile tal cual; se pueden pasar al diseñador
visual más adelante.

## Pendiente (siguientes pasos)

- **Red en hilo**: las llamadas REST se hacen ahora síncronas (marcadas con
  `// TODO`). Moverlas a `TTask` para no bloquear la UI (ANR en Android).
- **Lote/caducidad**: pedirlos al escanear un artículo trazable
  (`EsTrazable` del catálogo). Hay `// TODO` en `fRecuentoConteo`.
- **Escaneo por cámara**: hoy va por lector hardware (keyboard-wedge: el código
  llega como texto + Intro). Añadir cámara con una librería de barras.
- **.dproj**: configurarlo en el IDE (iconos, permisos, firma).
- No compilado en este entorno: puede requerir ajustes menores al abrir en IDE.
