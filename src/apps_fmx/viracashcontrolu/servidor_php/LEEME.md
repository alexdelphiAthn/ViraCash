# Servidor PHP de ViraCashControlU

Estos endpoints se instalan en el mismo servidor de la red interna que accede
a la base de datos de ViraCash. El teléfono nunca se conecta directamente a
MariaDB/MySQL.

## Instalador completo para Windows

El paquete `ViraCashControlU-Servidor-2026.08.28.2-x64.exe` incluye Apache,
PHP x64 Thread Safe, PDO MySQL, Visual C++ y esta API. Se genera con
`C:\DISCO_DURO\proyectos\factuzam_web\scripts\instalador_viracashcontrolu\Crear-Instalador.ps1`
y se entrega en
`C:\DISCO_DURO\proyectos\factuzam_web\build\ViraCashControlU-Servidor`.

El asistente ofrece puerto HTTP **80 por defecto**, editable, y un botón
para comprobar MariaDB. Comprueba conexión, columnas y permisos con consultas
de solo lectura; no instala MariaDB, crea usuarios ni ejecuta migraciones.
También compara en el registro de Windows el runtime Visual C++ x64 instalado
con la versión mínima del paquete y solo marca su instalación cuando hace falta.

Utiliza una carpeta propia (`C:\ViraCashControlU`) y el servicio
`ViraCashControlUApache`, sin modificar el Apache/PHP existente. Solo publica
`viracashcontrolu\publico`; `viracashcontrolu\privado` queda fuera del `DocumentRoot`
y protegida por permisos de Windows. Genera el secreto de tokens durante la
instalación y desactiva la escritura de `ULTIMO_LOGIN_USU`.

La regla opcional de firewall admite el puerto elegido solo desde la subred
local en perfiles Privado/Dominio. HTTP es para una LAN controlada; no se
configuran certificados HTTPS ni acceso público a Internet. Al finalizar se
presentan las URL que pueden copiarse en la app Android.

## Instalación manual

1. Requiere PHP 8.1 o posterior con `pdo_mysql` y acceso de lectura a la base
   de datos ViraCash.
2. Configura como `DocumentRoot` únicamente la carpeta `publico`. La carpeta
   `privado` no debe publicarse.
3. Copia `privado/config.php.example` como `privado/config.php`, completa la
   conexión, genera un secreto de token distinto y configura como
   `CFG_FOTOS_DIRECTORIO` la raíz de `appDirFotos` (la que contiene `300`). El
   proceso PHP debe poder escribir en `CFG_LOGIN_RATE_LIMIT_DIRECTORIO`.
4. En la app indica la URL que corresponde a `publico`, por ejemplo
   `https://stock.intranet.local/fzamcontrolu` o
   `http://192.168.1.20/fzamcontrolu`.

Permisos mínimos orientativos para el usuario de base de datos:

```sql
GRANT SELECT ON ViraCash.fza_usuarios TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT ON ViraCash.fza_usuarios_grupos TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT ON ViraCash.fza_permisos TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT ON ViraCash.fza_articulos TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT ON ViraCash.fza_articulos_skus TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT ON ViraCash.fza_codigos_barras TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT ON ViraCash.fza_articulos_fotos TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT (
  CODIGO_UNIDAD_STK, CODIGO_ALM_STK, CANTIDAD_STK,
  CANTIDAD_ENT_COMPRA_STK, CANTIDAD_ENT_TRASPASO_STK,
  CANTIDAD_ENT_DEPOSITO_STK, CANTIDAD_ENT_REGULAR_STK,
  CANTIDAD_ENT_ALBENTRADA_STK, CANTIDAD_SAL_VENTA_STK
) ON ViraCash.fza_articulos_stockactual
  TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT (CODIGO_UNIDAD_PDR, CODIGO_ALM_PDR, CANTIDAD_PDR)
  ON ViraCash.fza_articulos_pdte_recibir
  TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT (CODIGO_UNIDAD_SKU_SA, ID_AV_SA)
  ON ViraCash.fza_atributos_sku TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT (ID_AV, ID_VA_AV, AV, ORDEN_AV)
  ON ViraCash.fza_atributos_valores TO 'viracashcontrolu'@'servidor-web';
GRANT SELECT (
  CODIGO_ALM_ALM, NOMBRE_ALM_ALM, ESACTIVO_ALM, TIPO_USO_ALM,
  ORDEN_ALM
)
  ON ViraCash.fza_almacenes TO 'viracashcontrolu'@'servidor-web';
GRANT UPDATE (ULTIMO_LOGIN_USU) ON ViraCash.fza_usuarios
  TO 'viracashcontrolu'@'servidor-web';
```

La consulta de los cuatro estados usa SQL normalizado y parámetros PDO; no
depende de `PRC_GET_CAJA_STOCK_PIVOTADO`. La actualización de
`ULTIMO_LOGIN_USU` puede desactivarse con
`CFG_ACTUALIZAR_ULTIMO_LOGIN=false` si se prefiere una cuenta estrictamente de
solo lectura.

Apache debe conservar la cabecera `Authorization`; se incluye `.htaccess`. En
Nginx/FastCGI se debe mantener `fastcgi_param HTTP_AUTHORIZATION
$http_authorization;`.

## Contrato

- `POST login.php`: JSON `usuario` y `password`; devuelve `token` y
  `expira_en` dentro de `datos`.
- `GET stock.php?articulo=...&estado=...`: acepta artículo, SKU o código de
  barras y exige `Authorization: Bearer ...`. `estado` admite `stock`,
  `entradas`, `ventas` y `pte_recibir`; si se omite conserva `stock` por
  compatibilidad.
- `GET foto.php?articulo=...&unidad=...`: devuelve el PNG de 300 px con el
  mismo Bearer. La URL la genera `stock.php`; no se aceptan rutas de disco.

`stock.php` y `foto.php` respetan `menu.mnuConsultaStocks` con la misma
precedencia que ViraCash: usuario, grupo y `Todos`; los grupos administradores
omiten la restricción y la ausencia de una regla permite el acceso.

La respuesta de stock incluye `estado`, `cantidad_total`, los catálogos
simples `colores` y `almacenes`, `almacenes_predeterminados` y el detalle por
color, talla y almacén. Los catálogos se consultan de forma independiente para
que sigan completos aunque el estado elegido no tenga cantidades. Los
almacenes se identifican de forma consistente como `CÓDIGO - NOMBRE`.
`almacenes_predeterminados` replica Control U: solo tipos `ESTANDAR` o
`ESTANDARD` quedan marcados al abrir; depósitos, taras y tránsito siguen
disponibles en Filtros, pero empiezan desmarcados. Los campos
`cantidad_total_predeterminada` y
`cantidad_unidad_consultada_predeterminada` excluyen esos almacenes
auxiliares. `cantidad_unidad_consultada_por_almacen` permite actualizar la
cantidad de la variante leída al cambiar los filtros. Se mantiene
`stock_total` como alias de `cantidad_total` para versiones anteriores de la
app.

La web muestra una foto ampliable y filtros visibles de selección múltiple
por color y almacén. El campo aditivo `colores_basicos` es una lista con
`color`, `codigo`, `nombre` y `hex` por cada valor de color del artículo.
Se respeta la prioridad artículo > conjunto > atributo global; una fila
de anulación expresa en el artículo impide heredar el básico.
Solo se representan básicos de color activos. Sin un HEX válido el cuadrado
se muestra rayado; no se asigna un tono por aproximación del nombre.

Esta información es opcional: si falta el esquema o el permiso de lectura
de paleta, no se impide consultar cantidades. Para ver los básicos hacen
falta permisos SELECT de `fza_atributos_basicos`,
`fza_articulos_atributos_basicos`, `fza_articulos_conjuntos_asign`,
`fza_atributos_conjuntos_det` y la columna `ID_ATB_AV` de
`fza_atributos_valores`. No se instalan tablas ni se conceden permisos
automáticamente. Se conservan los campos utilizados por la app móvil.

El lanzador de desarrollo `factuzam_web/scripts/controlu_web/Iniciar-Local.ps1`
permite probar en localhost con el perfil ViraCash guardado en Windows.
Su configuración ignorada por Git exige variables de proceso, activa
`CFG_DB_SOLO_LECTURA=true` y `CFG_ACTUALIZAR_ULTIMO_LOGIN=false`.
Esa configuración no se copia al servidor del cliente.

La contraseña se compara con el MD5 heredado que ya usa ViraCash. No es un
mecanismo moderno: el endpoint no empeora el formato existente, pero se
recomienda migrar las contraseñas cuando la aplicación principal lo permita.

Aunque el servidor esté en la LAN, se recomienda HTTPS. Con HTTP el usuario,
la contraseña y el token pueden verse desde la red local.

El login limita por defecto los intentos por `REMOTE_ADDR` y responde `429`
al superar el umbral. Si hay un proxy inverso, configura allí un límite
equivalente usando la IP real; desactiva el límite PHP únicamente cuando el
proxy ya lo aplique, porque el endpoint no confía en cabeceras reenviadas.

## Verificación

Desde la raíz `servidor_php`:

```sh
php tests/pruebas.php
php -l publico/login.php
php -l publico/stock.php
php -l publico/foto.php
```

Pruebas de idioma de la web (Node 20 o superior):

```sh
node --test tests/idioma.test.mjs
```

## Idioma

La web sigue el idioma del navegador (`navigator.languages`): español,
inglés, catalán o chino se muestran en ese idioma (es-ES, en-GB, ca-ES,
zh-CN) y cualquier otro en inglés. Los textos están en
`publico/controlu-idioma.js` (clave = texto español exacto) y los errores del
hook se traducen por su `codigo` estable; un código desconocido muestra el
mensaje del servidor. Al cambiar un módulo JS, sube su `?v=` en los imports.
