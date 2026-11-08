# Evaluador nativo de las reglas EN 16931 disponibles

Componente Delphi aislado, todavía sin integrar en ViraCash. No genera UBL,
no instala esquema ni llama a SPFE. La autorización posterior del usuario
para obtener el código nativo se limita a este componente y sus pruebas.

La fuente ya estaba disponible: `ViraCash_web/docs/spfe/en16931-ubl-1.3.17/`.
Se ha traducido el Schematron preprocesado a un catálogo Pascal inmutable:
982 asertos, 104 contextos y 3.576 instrucciones compartidas. Conserva
identificador, gravedad, expresión original, mensaje y patrón. Su SHA-256
es `eb27995ba7bace330475a0afd54a21bb0ebb050d55774949d5e10f65ecef7b95`.

| Archivo | Responsabilidad |
|---|---|
| `inSpfeValidadorEn.pas` | API, diagnósticos y cobertura |
| `inSpfeXPathEvaluador.pas` | Ejecución del árbol de instrucciones |
| `inSpfeXPathSeleccion.pas` | Navegación por nodos y espacios de nombres |
| `inSpfeXPathTipos.pas` | Valores XPath y decimal BCD |
| `inSpfeXPathFunciones.pas` | Funciones del subconjunto utilizado |
| `inSpfeXPathOperaciones.pas` | Comparaciones y aritmética |
| `inSpfeXmlNativo.pas` | Adaptador de ADOM, Unicode y espacios de nombres |
| `inSpfeMensajes.pas` | Mensajes técnicos en resourcestring |
| `inSpfeReglasEn.pas` / `.inc` | Catálogo generado, constante y trazable |
| `LICENSE_EN16931.txt` | Licencia original EUPL-1.2 de las reglas |

Las unidades se compilan dentro del EXE, con las DCU del RTL de Delphi.
ADOM realiza el análisis XML en Pascal. No se usa MSXML, Java, Python,
Saxon, paquetes BPL ni DLL añadidas en producción. Python y SaxonC se usan
exclusivamente para extracción y contraste en desarrollo.

El adaptador retira del DOM de trabajo el elemento virtual `xml` con que
el RTL 37 representa la declaración XML. No modifica el XML original ni
los valores de la factura; la declaración no es un nodo elemento de XPath.

## Contrato y límites

```pascal
oValidador := TValidadorEnSpfe.Create;
try
  oResultado := oValidador.Validar(sXmlInmutable);
finally
  FreeAndNil(oValidador);
end;
```

Cada llamada posee su DOM, variables y evaluador. No hay estado global mutable
propio ni acceso a UI/BBDD. Debe invocarse desde el futuro trabajador en segundo
plano; esta API es síncrona y no debe llamarse en el hilo de emisión.

`EsCapaEnSuperada` exige evaluación completa y ausencia de fallos fatales o
errores técnicos. Un aviso se conserva. Un error al evaluar un aserto guarda
su identificador y marca cobertura incompleta. Un fallo de lectura, contexto
o límite de operaciones propaga excepción: el coordinador deberá conservar
el trabajo como error, nunca como validado. La comprobación de entrada rechaza
DTD y entidades declaradas, y limita el tamaño a 16.777.216 caracteres.

No es un motor general XPath 2.0/XSLT. Solo implementa el vocabulario de las
expresiones extraídas. Las divisiones del paquete son exclusivamente por 100:
se calculan mediante multiplicación decimal exacta por 0,01. No se usa
`Currency` ni coma flotante para importes; los desbordamientos son errores.
La entrada decimal está limitada a 64 cifras y escala 63, el rango de TBcd.
Las fechas admiten años 0001–9999 y zona XML; la zona implícita es UTC.
El presupuesto inicial es de diez millones de instrucciones por documento;
alcanzarlo produce error de infraestructura. No implica rechazo normativo.

Se respeta la primera regla aplicable por nodo y patrón. Los prefijos del
XML pueden variar: se comparan URI y nombre local, no el texto del prefijo.
Los IDs y mensajes oficiales permanecen en su idioma original.

**Cobertura: EN 2017+A1 / UBL 2.1, release validation-1.3.17.**
`EsCobertura2026Completa` siempre devuelve falso. Quedan pendientes las normas
UNE 2026, la matriz de aplicabilidad SPFE, las comprobaciones propias del BOE
y la capa XSD UBL 2.5 nativa. Se conservan UBL-CR-002 y UBL-CR-513 aunque
reflejen diferencias con la versión/perfil SPFE. CreditNote se utiliza solo
para contrastar el ejemplo europeo; SPFE seguirá usando Invoice también en
rectificativas.

## Reproducción de pruebas

Las pruebas y scripts están en el repositorio auxiliar, conforme a AGENTS.md:

- `factuzam_web/scripts/extraer_reglas_spfe.py`: extracción reproducible.
- `factuzam_web/tests/spfe_nativo/PruebasEnSpfe.pas`: DUnitX.
- `factuzam_web/tests/spfe_nativo/ejecutar_pruebas.ps1`: compilación/ejecución
  Win64 y Win32 con las DCU suministradas de RTL/DUnitX; no recompila terceros.
- `factuzam_web/tests/spfe_nativo/comparar_referencia.py`: contraste de
  diagnósticos con el XSLT oficial mediante SaxonC, solo en desarrollo.

Ejecutar DUnitX desde PowerShell:

```powershell
& C:\DISCO_DURO\proyectos\factuzam_web\tests\spfe_nativo\ejecutar_pruebas.ps1
```

Para repetir el contraste, instalar `saxonche==13.1.1` únicamente en una
carpeta temporal de desarrollo y pasar al script `comparar_referencia.py`
los argumentos `--fuentes` (carpeta EN 1.3.17), `--temporal` (copias mutadas),
`--ejecutable` (ComprobarEnSpfe.exe de la plataforma), `--oraculo` (carpeta
temporal del módulo SaxonC) y `--informe` (JSON de salida). No copiar ese
motor ni sus dependencias a instalaciones cliente. Las salidas de compilación
van a `factuzam_web/tmp/spfe-nativo`; retirar esos temporales al terminar.

El contraste incluye los 19 XML oficiales y copias con cada nodo hoja vacío,
además de casos de versión, moneda y Unicode. Compara identificador, gravedad
y multiplicidad de fallos. Cuando el XSLT aborta por conversión inválida,
exige que Delphi informe evaluación incompleta; no cuenta ese caso como una
validación normativa satisfactoria. No demuestra equivalencia para cualquier
XML posible ni sustituye una revisión del evaluador.

Resultado de esta entrega: 20 tests DUnitX correctos por arquitectura y
2.263 entradas contrastadas por plataforma, sin discrepancias. En 1.656
entradas se comparan los diagnósticos; las otras 607 provocan error de
conversión en el XSLT de referencia y evaluación incompleta en Delphi.
Estas últimas no se cuentan como facturas válidas. Compilación Win64/Win32
sin advertencias ni recompilación de terceros, e importaciones limitadas a
bibliotecas de Windows. Detalle: `VERIFICACION_NATIVA_EN16931.json`.

Los informes de extracción y contraste viven en `doc/spfe/help/`. Los XML
mutados, motores y ejecutables de pruebas son temporales del repositorio
auxiliar; no forman parte de la aplicación. Las fuentes oficiales permanecen
intactas. Una actualización del paquete exige regenerar, revisar nuevos
operadores/funciones/divisores y repetir el contraste antes de aceptarla.

## Pendiente antes del despliegue

Revisión del componente, más casos de límites y facturas reales anonimizadas,
XSD/reglas SPFE, cola persistente y su migración revisable, un solo trabajador
coordinado por instalación, cancelación y recuperación tras reinicio. Medir
CPU, memoria y latencia interactiva en equipos de dos núcleos: las pruebas
aisladas no acreditan ausencia de impacto en la emisión. No se ha modificado
la aplicación, el módulo VERI*FACTU ni su cadena de hash.
