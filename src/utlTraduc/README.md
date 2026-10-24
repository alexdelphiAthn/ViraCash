# Editor de traducciones

`utlTraduc` es una aplicación VCL independiente para editar los idiomas del
catálogo `fza_traducciones`.

## Uso

1. Comprobar la ruta del INI de ViraCash.
2. Conectar y elegir el idioma de destino.
3. Pulsar `Sincronizar español` para importar los textos compilados.
4. Cargar todas las claves o solamente las pendientes.
5. Seleccionar una clave, editar su traducción y guardar los cambios.

El guardado se realiza en una sola transacción mediante
`INSERT ... ON DUPLICATE KEY UPDATE`. Antes de escribir se comprueba que la
traducción no esté vacía y que conserve los marcadores de `Format`.

La utilidad lee por defecto `%LOCALAPPDATA%\viracash\vcash.ini`, incluida la
contraseña cifrada `PasswordEn`. Se puede seleccionar otro INI o pasarlo como
primer parámetro de línea de comandos. No guarda credenciales ni modifica el
esquema. Requiere que `DESARROLLOS EN CURSO/traducciones.sql` ya esté aplicado.

## Catálogo central

`fza_traducciones` es el único catálogo consultado en ejecución. Contiene
los textos de formularios, los `resourcestring` propios, los de la VCL y las
claves de Developer Express. Los recursos compilados no forman un catálogo
paralelo: sólo permiten sembrar el español y conservar un respaldo si no se
puede leer la BBDD.

El registro
`src/Lib/inLibRegistroResourcestringTraducciones.pas` enlaza cada clave
`unidad.identificador` con su `resourcestring`. Incluye las unidades
`inLibMsg*` y `src/vcl37/Vcl.Consts.pas`. Se regenera mediante:

```powershell
& '.\DESARROLLOS EN CURSO\generar_registro_resourcestring.ps1'
```

La importación actualiza `es-ES` mediante `INSERT ... ON DUPLICATE KEY UPDATE`
y no modifica las unidades de origen. Las claves de Developer Express usan
el prefijo `DevExpress.` y se obtienen de `CXLOCALIZATION.res`, incluidas las
personalizaciones de la hoja de cálculo.

Las categorías y descripciones creadas en ejecución por los inspectores de
Parámetros Generales y Parámetros de Caja se registran en
`src/Lib/inLibRegistroParametrosTraducciones.pas`. El registro se regenera
desde las llamadas `RegistrarParametro` mediante:

```powershell
& '.\DESARROLLOS EN CURSO\generar_registro_parametros_traduccion.ps1'
```

Los títulos dinámicos de columnas se leen directamente de
`fza_config_campos`. Al sincronizar el español, el editor crea una entrada por
clave primaria `(TABLA_OBJETIVO_CC, OBJETIVO_CC)` con el formato
`fza_config_campos.<tabla>.<campo>.TITULO_VISUAL_CC`. El valor
`TITULO_VISUAL_CC` sigue siendo el texto español autoritativo y el respaldo
cuando no existe traducción; no hace falta recompilar para añadir o modificar
filas de configuración.

El selector de destino carga los idiomas activos de la BBDD al conectar. El
combo admite también escribir una etiqueta nueva, por ejemplo `fr-FR`, para
crear otro idioma sin modificar `utlTraduc`. `zh-CN` se ofrece siempre para
permitir crear y revisar el chino incluso cuando la BBDD todavía no contiene
ninguna traducción de ese idioma.

## Catálogo chino simplificado

El catálogo automático `zh-CN` se genera con:

```powershell
$segura = Read-Host 'Contraseña MariaDB' -AsSecureString
$env:VIRACASH_DB_PASSWORD = [Net.NetworkCredential]::new('', $segura).Password
try {
  python '.\DESARROLLOS EN CURSO\generar_traducciones_zh_cn.py' --aplicar
} finally {
  Remove-Item Env:VIRACASH_DB_PASSWORD
}
```

El generador requiere `argostranslate`, `ctranslate2` y `pymysql`, además de
los modelos locales `es -> en` y `en -> zh`. No envía los textos a servicios
externos ni guarda la contraseña. Produce el SQL idempotente
`DESARROLLOS EN CURSO/traducciones_zh_cn_d25.sql`.

Los marcadores de `Format`, las expresiones de FastReport, rutas, URL y
atajos se protegen antes de traducir. Cuando el chino necesita cambiar el
orden de los argumentos se escriben índices explícitos, por ejemplo
`%1:d ... %0:s`. `utlTraduc` valida por índice y tipo para aceptar ese orden
sin perder la seguridad de `Format`.

La traducción automática queda pendiente de revisión visual. Los cambios
manuales realizados desde `utlTraduc` se conservan en ejecuciones normales;
`--regenerar-existentes` solo debe usarse para reconstruir el catálogo.

## Traducciones descargables y copias de seguridad

Las traducciones que llegan desde el webservice se identifican mediante
`ESDESCARGADA_TRAD = 'S'`. La migración idempotente
`DESARROLLOS EN CURSO/traducciones_descargadas_d26.sql` añade esta marca.
Las copias de seguridad incluyen únicamente los idiomas descargados; el
español base y los catálogos de trabajo no se duplican en el backup.

Los catálogos existentes se exportan sin credenciales incrustadas mediante
`DESARROLLOS EN CURSO/exportar_traduccion_descarga.py`. Los paquetes
publicados actualmente son `en-GB`, `ca-ES` y `zh-CN`.

En los parámetros de ViraCash estos tres idiomas se ofrecen aunque todavía
no existan en la BBDD. Al elegir uno se abre un diálogo que informa del
avance: descarga el ZIP autenticado, valida el manifiesto, el orden, el
tamaño y la huella SHA-256 de cada SQL, ejecuta el paquete y aplica el idioma
a los formularios abiertos. Si la traducción ya estaba descargada, el mismo
diálogo la aplica sin volver a pedir el ZIP. Ante un error se conserva el
idioma anterior; el botón Guardar persiste la selección después de aplicarla.

Los rótulos de tickets térmicos viven en
`src/Lib/inLibMsgTickets.pas`. Se importan con `Sincronizar español` igual que
el resto de `resourcestring`. La propuesta catalana y su SQL idempotente se
regeneran mediante:

```powershell
& '.\DESARROLLOS EN CURSO\generar_traducciones_tickets.ps1'
```

El resultado es
`DESARROLLOS EN CURSO/traducciones_ca_es_tickets_d24.sql`. Para otro idioma,
se selecciona o escribe su etiqueta en `utlTraduc` y se completan las mismas
claves `inLibMsgTickets.*`, sin modificar los generadores de ticket.

En sentido inverso, ViraCash consulta la BBDD cuando evalúa un
`resourcestring`, carga un formulario o solicita un texto de Developer
Express. Si no hay conexión, clave o traducción activa, conserva el texto
compilado como respaldo. No se aplica ninguna traducción española de
Developer Express al margen de `fza_traducciones`.

## Informes FastReport

Las plantillas predeterminadas no están en ficheros `.fr3`: se guardan como
`TfrxReport` dentro de los DFM. Sus textos `Memo.UTF8W` se exportan con:

```powershell
& '.\DESARROLLOS EN CURSO\generar_traducciones_fastreport.ps1'
```

El resultado idempotente se guarda en
`DESARROLLOS EN CURSO/traducciones_d22_fastreport.sql`. Las claves usan
`FastReport.<unidad>.Predeterminado.<objeto>.Memo` y conservan las expresiones
`[DataSet]` del informe. Los formatos personalizados guardados como BLOB en
`fza_usuarios_perfiles` forman la subfase D22-B y no se mezclan con las
plantillas predeterminadas.

## Compilación

Abrir `utlTraduc.dproj` o compilar las configuraciones Win32/Win64 desde
Delphi. Los binarios se generan bajo `bin/<plataforma>/<configuración>`.
