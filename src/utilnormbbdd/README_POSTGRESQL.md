# Migración de ViraCash a PostgreSQL 16

Este directorio contiene una migración reproducible del volcado histórico de
ViraCash desde MariaDB a PostgreSQL. No es un conversor SQL universal. El
programa conoce deliberadamente el inventario y las particularidades de este
volcado: 66 tablas, 50 vistas, 7.063 filas de datos y 45 rutinas de negocio.
Si ese contrato cambia, la generación debe fallar para obligar a revisar la
conversión semántica.

## Archivos

- `factuzam_original.sql`: fuente MariaDB. Es la referencia histórica y no se
  modifica durante la generación.
- `convert_viracash_to_postgresql.py`: generador específico de ViraCash.
- `.routines_pg_batch_api.sql`: 18 adapters de consulta,
  contadores y resultados de forma fija.
- `.routines_pg_batch_dml.sql`: 25 procedimientos de
  escritura, inventario, facturación y PMP.
- `.routines_pg_batch_pivot.sql`: los 2 resultados
  dinámicos expuestos mediante `refcursor`.

Los tres módulos suman exactamente las 45 rutinas fuente. Se mantienen
separados porque una traducción semántica de procedimientos no puede obtenerse
con sustituciones mecánicas fiables; el generador los valida y los incorpora al
bootstrap único en ese orden.
- `viracash_original_postgresql.sql`: bootstrap generado y versionado. Incluye
  esquema, datos, índices, comentarios, triggers, vistas y el módulo de
  rutinas. No debe editarse a mano.
- `validate_viracash_postgresql.sql`: smoke test de catálogo para una base ya
  cargada. Solo lee metadatos y termina con `ROLLBACK`.

El generador conserva como datos los textos SQL MariaDB almacenados en tablas
de ViraCash; no intenta convertir ni ejecutar esos textos.

## Requisitos

- Python 3.10 o posterior.
- PostgreSQL 16 o posterior, con las utilidades `createdb` y `psql`, y el
  módulo contrib `unaccent` disponible.
- Base de destino en UTF-8.
- Un rol propietario de la base o con permisos suficientes para instalar la
  extensión trusted `unaccent` y crear tablas, vistas, secuencias, funciones,
  procedimientos y triggers en el esquema `public`.

La ordenación depende de la configuración regional de la base de destino.
Debe elegirse al crearla; el bootstrap no fuerza una colación MariaDB
equivalente. Las búsquedas de artículos sí aplican `unaccent` + `ILIKE` para
conservar las comparaciones sin acentos y sin distinción de mayúsculas de la
colación MariaDB de origen.

## Regenerar y comprobar

Ejecutar desde la raíz del repositorio:

```console
python src/utilnormbbdd/convert_viracash_to_postgresql.py
```

La salida se escribe con el formato estable esperado por el repositorio. Para
comprobar en CI que el SQL versionado corresponde exactamente al origen, al
generador y al módulo de rutinas:

```console
python src/utilnormbbdd/convert_viracash_to_postgresql.py --check
```

`--check` no modifica archivos. Regenera en memoria, compara byte a byte y
devuelve un código distinto de cero si la salida está ausente o desactualizada.

## Carga segura

El bootstrap contiene `DROP ... CASCADE` para poder reconstruir sus propios
objetos. Por tanto, debe cargarse en una base nueva y vacía, nunca directamente
sobre una base de producción o una base que contenga objetos ajenos.

Ejemplo, adaptando el nombre y las opciones de conexión al entorno:

```console
createdb --template=template0 --encoding=UTF8 viracash_pg16
psql -X -v ON_ERROR_STOP=1 -d viracash_pg16 -f src/utilnormbbdd/viracash_original_postgresql.sql
psql -X -v ON_ERROR_STOP=1 -d viracash_pg16 -f src/utilnormbbdd/validate_viracash_postgresql.sql
```

`-X` evita que una configuración personal de `psql` altere la carga y
`ON_ERROR_STOP=1` detiene el proceso ante el primer error. El bootstrap se
ejecuta dentro de una transacción: si `psql` termina por un error, el cierre de
la conexión revierte la transacción no confirmada. Aun así, antes de una
migración real se necesita copia de seguridad, ensayo de restauración y pruebas
funcionales de la aplicación.

## Contratos de llamada PostgreSQL

Las rutinas que solo modifican estado se exponen como procedimientos y se
invocan con `CALL`. Los resultados tabulares de forma fija se exponen como
funciones y se consultan con `SELECT`. Los parámetros `OUT` de un procedimiento
PostgreSQL forman una fila de resultado; el adaptador UniDAC no debe conservar
las variables de sesión `@salida` usadas por MariaDB.

`prc_getperfilformulario` pasa de un resultset abierto por `CALL` a una función
de tabla y debe consultarse con:

```sql
SELECT * FROM prc_getperfilformulario(...);
```

`prc_get_caja_stock_pivotado` y
`prc_get_caja_stock_pivotado_withz` producen columnas cuyo número y nombre
dependen de los atributos del artículo. PostgreSQL no permite declarar ese
resultado como una tabla fija, por lo que el contrato usa `refcursor`:

1. Abrir una transacción.
2. Ejecutar `CALL` pasando la entrada y un nombre de cursor.
3. Ejecutar `FETCH ALL FROM nombre_cursor` en la misma conexión y transacción.
4. Confirmar o revertir la transacción.

Ejemplo del patrón, usando la firma versionada de la rutina como autoridad:

```sql
BEGIN;
CALL prc_get_caja_stock_pivotado('ARTICULO', 'viracash_stock');
FETCH ALL FROM viracash_stock;
COMMIT;
```

El cursor deja de existir al terminar la transacción. El código Pascal/PHP
debe encapsular las cuatro operaciones en un adaptador y no puede dejar el
`CALL` en modo autocommit. Debe usarse un nombre de cursor independiente por
operación cuando una conexión pueda tener más de una consulta activa.

La carga de este bootstrap no modifica automáticamente el SQL embebido en la
aplicación. Antes de cambiar la conexión deben migrarse tres patrones:

- `CALL PRC_GETPERFILFORMULARIO(...)` pasa al `SELECT *` anterior.
- Los `CALL` directos de ambos pivotes pasan al ciclo transaccional
  `BEGIN` / `CALL` / `FETCH` / `COMMIT`.
- Las variables MariaDB `@salida` y el `SELECT @salida` posterior desaparecen;
  PostgreSQL devuelve los parámetros `OUT` como la propia fila del `CALL`.

Los procedimientos sin salida, como `prc_recalcular_stock()`, conservan un
`CALL` sin argumentos. Estos cambios de adaptador son una fase de aplicación
distinta y deben probarse con la misma conexión UniDAC durante toda la
transacción del cursor.

## Transacciones: diferencia respecto a MariaDB

Las rutinas originales mezclaban `START TRANSACTION`, `COMMIT`, `ROLLBACK` y
handlers, incluso cuando eran llamadas por otra rutina o desde una transacción
de la aplicación. Esa semántica no tiene una traducción anidada directa en
PL/pgSQL.

En la versión PostgreSQL las rutinas participan en la transacción del llamador
y no hacen `COMMIT` ni `ROLLBACK` internos. Una excepción se propaga y deja la
transacción PostgreSQL en estado fallido hasta que el llamador ejecute
`ROLLBACK` o vuelva a un `SAVEPOINT`. Los contadores se reservan con bloqueo y
`UPDATE ... RETURNING`; si la transacción exterior se revierte, también se
revierte la reserva. Esto es más atómico, pero puede diferir del contador ya
confirmado por una rutina MariaDB.

## Decisiones y defectos conocidos

Correcciones deliberadas de la migración:

- Las fechas cero incompatibles se representan con el centinela
  `1970-01-01 00:00:00`; 213 `NULL` explícitos incompatibles con `NOT NULL` se
  sustituyen de forma dirigida por `DEFAULT`.
- Los BLOB se cargan como `bytea` y se conservan sus bytes; las barras
  invertidas de las rutas mantienen su valor, no su escape textual MariaDB.
- Los contadores evitan las carreras de `IF NOT EXISTS` más
  `INSERT/UPDATE` mediante primitivas atómicas de PostgreSQL.
- Las búsquedas usan `unaccent` + `ILIKE` para conservar la comparación
  MariaDB sin acentos y sin distinción de mayúsculas. Cuando un artículo tiene
  varias tarifas vigentes, devuelven una sola tarifa base/default; las tarifas
  de SKU siguen vinculadas a su unidad concreta.
- `prc_get_iva_zona_fecha` corrige los identificadores obsoletos del origen,
  aplica el intervalo de vigencia y asigna el indicador de encontrado.
- `prc_get_numero_menor_mil` conserva correctamente los casos especiales
  0, 1 y 100 que el `SET` final del origen sobrescribía.
- Las llamadas internas deben usar la aridad PostgreSQL completa; en
  particular, el origen llamaba dos veces a
  `sp_recalcular_pmp_sku_almacen` con dos argumentos aunque declaraba tres.
- Los movimientos guardan el coste unitario que consume el kardex; los
  recálculos actualizan por `numero_mov`, agregan el saldo compartido entre
  empresas, separan lotes, excluyen movimientos inactivos y conservan la
  caducidad. Fechas distintas para un mismo lote se rechazan.
- Los traspasos generan dos claves de movimiento de 20 caracteres, reutilizan
  la rutina de movimientos y se ejecutan atómicamente en la transacción del
  llamador.
- La regularización de inventario identifica sus movimientos por las columnas
  documentales, conserva lote/caducidad y rechaza una foto teórica que haya
  quedado obsoleta antes de aplicar.
- Las tarifas actualizan una sola vigencia base activa; al insertar antes de
  una vigencia futura cierran la nueva el día anterior para no solaparlas.
- Los recibos reparten el resto entre los plazos posteriores al anticipo y
  ajustan el último a seis decimales para que la suma sea exacta.
- `prc_crear_metadatos` traduce el nombre de la base actual al esquema
  efectivo y conserva los permisos y dependencias de la tabla existente.

Deuda heredada que exige pruebas funcionales:

- `prc_calcular_factura_netos` está incompleta en el volcado fuente: declara
  un cursor que no usa y contiene marcadores de lógica omitida. La versión
  PostgreSQL lanza una excepción antes de escribir, en vez de poner a cero los
  importes de una factura. Esto también bloquea de forma atómica la creación de
  abonos hasta recuperar y probar las reglas fiscales que faltan.
- Algunas entradas se conservan por compatibilidad aunque el origen no las
  utiliza, como `p_usuario` en la generación de vales y el recargo en la rutina
  de empresa.
- La semántica histórica del PMP requiere contraste con casos económicos
  reales. La migración corrige la columna de coste que alimenta el kardex y
  actualiza cada movimiento por su clave primaria para impedir escrituras
  cruzadas, pero conserva el recálculo histórico completo cuando el origen
  ignora `p_fecha_desde`.
- Las dos consultas pivotadas conservan un resultado dinámico mediante cursor;
  no son intercambiables con un dataset de forma fija.
- No se añaden claves foráneas que no existían en el volcado original y los
  `ORDER BY` superiores de las vistas se omiten; cada consumidor debe ordenar
  explícitamente.

El smoke test valida presencia e inventario, no la corrección económica de
estas reglas. La aceptación requiere pruebas de concurrencia, facturación,
inventarios, PMP, perfiles y ambos pivotes desde los adaptadores reales.

## Publicación en Git

El generador, los tres módulos PL/pgSQL, el bootstrap generado, el validador y
este documento forman una unidad versionable. Antes de publicar el repositorio,
revise por separado `factuzam_original.sql` y los datos incorporados al
bootstrap: un volcado real puede contener datos personales, rutas internas o
material con restricciones de distribución. Para un ejemplo público conviene
usar un volcado anonimizado y conservar los mismos casos límite en un fixture
pequeño.

Una revisión automática reproducible puede ejecutar:

```console
python src/utilnormbbdd/convert_viracash_to_postgresql.py --check
createdb --template=template0 --encoding=UTF8 viracash_pg16_ci
psql -X -v ON_ERROR_STOP=1 -d viracash_pg16_ci -f src/utilnormbbdd/viracash_original_postgresql.sql
psql -X -v ON_ERROR_STOP=1 -d viracash_pg16_ci -f src/utilnormbbdd/validate_viracash_postgresql.sql
dropdb viracash_pg16_ci
```

No es necesario confiar en un fichero generado a mano: `--check` demuestra que
corresponde al volcado y a los módulos versionados. La publicación debe hacerse
en un commit o pull request propio, sin mezclar cambios ajenos del árbol de
trabajo.
