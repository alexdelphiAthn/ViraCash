# Expediente SBOM y preparación para el CRA

Esta carpeta reúne la evidencia y las tareas de ingeniería relacionadas con el Reglamento (UE) 2024/2847, conocido como Reglamento de Ciberresiliencia o CRA.

El contenido sirve para preparar el cumplimiento técnico. No es un dictamen jurídico, una declaración UE de conformidad ni una prueba de que ViraCash esté ya dentro del ámbito del Reglamento. Antes de afirmar cumplimiento deben determinarse formalmente la forma de distribución del producto, el papel del operador económico y su clasificación CRA.

## Contenido

- [Reglamento-UE-2024-2847-CRA-ES.pdf](Reglamento-UE-2024-2847-CRA-ES.pdf): copia oficial en español del texto publicado en el Diario Oficial de la Unión Europea.
- [viracash.cdx.json](viracash.cdx.json): inventario CycloneDX 1.7 saneado de la resolución de fuentes analizada el 25 de agosto de 2026, con el alta manual de la fuente Source Sans 3 incorporada el 14 de septiembre de 2026 (sustituye a DejaVu Sans, dada de alta el 5 de septiembre y retirada al dejar de usarla la aplicación).
- [FUENTE_OFICIAL.md](FUENTE_OFICIAL.md): procedencia, enlaces oficiales y huella de la copia local.
- [TAREAS_CRA.md](TAREAS_CRA.md): registro priorizado de tareas, responsables y evidencias.
- [GRAFO_COMPONENTES.md](GRAFO_COMPONENTES.md): vista humana de las familias de componentes observadas.
- [HISTORIAL_SBOM.md](HISTORIAL_SBOM.md): registro previsto para cada SBOM de una versión entregada.
- [SHA256SUMS.txt](SHA256SUMS.txt): huellas de los dos artefactos archivados en esta carpeta.
- [CUMPLIMIENTO_CRA.md](../CUMPLIMIENTO_CRA.md): resumen técnico en la raíz del repositorio.

## Estado del SBOM

El analizador Pascal produce un inventario CycloneDX y un grafo de dependencias de las fuentes resueltas. El proceso de normalización corrige la estructura del informe, añade una raíz ViraCash, hashes SHA-256, rutas lógicas, clasificación propia/tercero e inventarios binarios separados de UniDAC y DAC. Las rutas absolutas quedan fuera del conjunto saneado.

`viracash.cdx.json` es la instantánea estable del análisis Win64 Debug terminado el 25 de agosto de 2026 sin cambios concurrentes. Cumple el esquema oficial CycloneDX 1.7 y contiene 2.577 componentes, un nodo por componente y cero referencias colgantes. Sus 1.046 componentes propios y 1.531 de terceros reflejan resolución de fuentes, salvo el componente Source Sans 3, que es un alta manual descrita más abajo; la composición se declara expresamente incompleta. Pascal Analyzer no consultó una base de vulnerabilidades, por lo que el estado sigue siendo `UNKNOWN`.

La revisión 5 del inventario contiene a mano el componente `urn:viracash:component:adobe:source-sans-3:3.052`, la familia tipográfica Source Sans 3 (Adobe, licencia OFL 1.1) que se distribuye con el producto; sustituye a DejaVu Sans 2.37, que las revisiones 3 y 4 habían dado de alta y que la aplicación dejó de usar el 14 de septiembre de 2026. Pascal Analyzer no resuelve activos binarios que no sean unidades Pascal, así que la entrada no procede del análisis y lo declara en sus propiedades `viracash:sbom:entry-provenance` y `viracash:distribution:status`. Su ámbito es `required`: el instalador NSIS empaqueta las cuatro caras TrueType (Regular, Bold, Italic y Bold Italic), las registra en la carpeta de fuentes de Windows e instala el aviso de licencia junto a la aplicación. Al regenerar el inventario con `normalizar_sbom_pascal_analyzer.ps1` la entrada se pierde: para que sea estable, el normalizador debe inyectarla igual que inyecta los componentes agregados de Devart.

Este archivo es evidencia interna de análisis, no el SBOM definitivo del producto distribuido. Para convertirlo en evidencia de una entrega todavía hay que:

1. relacionarlo con una versión, plataforma, commit y artefacto entregable concretos;
2. reconciliar las dependencias de fuentes con el EXE, instalador y bibliotecas realmente distribuidos;
3. completar y verificar proveedor, versión, licencia e identidad de los componentes;
4. ejecutar y registrar la vigilancia de vulnerabilidades, incluidas las fuentes de proveedores comerciales;
5. conservar el SBOM y los hashes del producto dentro del expediente de la entrega.

Como este repositorio web puede terminar expuesto públicamente, nunca deben copiarse aquí los informes raw ni el directorio completo de Pascal Analyzer: `Status.txt`, `Modules.txt`, `Complexity.txt` y otros informes conservan rutas locales. El CRA exige conservar una nomenclatura legible por máquina, pero no obliga de forma general a publicar el SBOM.

## Regeneración interna

La generación parte de `eng/analizar_pascal.ps1` y `eng/normalizar_sbom_pascal_analyzer.ps1` en el repositorio hermano ViraCash. El normalizador define como exportables únicamente `SBOM.json`, `Security.txt` y `Security Coverage.txt`; los demás informes deben conservarse con acceso restringido. La automatización por versión y plataforma sigue pendiente.

Última revisión de este índice: 2026-09-14.
