# Historial de SBOM de entregas

Este registro relacionará cada SBOM con los artefactos que representa. No se considera cerrada una entrada hasta que el JSON esté saneado, validado y archivado.

| Fecha | Versión ViraCash | Plataforma | Commit | Artefacto y SHA-256 | SBOM y SHA-256 | CycloneDX | Cobertura de vulnerabilidades | Estado |
|---|---|---|---|---|---|---|---|---|
| 2026-08-25 | No fijada | Win64 Debug; análisis de fuentes | No fijado; árbol con cambios locales | No reconciliado | `viracash.cdx.json` rev. 2; `524C05045524F90BA80BBEE5CEA3278038A05AA42A5FFA30444BF1FE21C3D035` | 1.7; esquema válido | No ejecutada; estado UNKNOWN | SUSTITUIDA |
| 2026-09-05 | No fijada | Win64 Debug; análisis de fuentes más alta manual de DejaVu Sans 2.37 | No fijado; árbol con cambios locales | No reconciliado | `viracash.cdx.json` rev. 3; `B7865CA91EFEF7A8AF3D43092EA44D078267FEA2D7BDF79F881F3DF2BDC85555` | 1.7; esquema válido | No ejecutada; estado UNKNOWN | SUSTITUIDA |
| 2026-09-07 | No fijada | Win64 Debug; DejaVu Sans pasa a `required` al empaquetarla el instalador | No fijado; árbol con cambios locales | No reconciliado | `viracash.cdx.json` rev. 4; `81351E8C82E6AB847EF741D30A50074E662A789BE305FFE7710050EE8620B8B5` | 1.7; esquema válido | No ejecutada; estado UNKNOWN | SUSTITUIDA |
| 2026-09-14 | No fijada | Win64 Debug; DejaVu Sans 2.37 retirada y alta manual de Source Sans 3 3.052 como `required` | No fijado; árbol con cambios locales | No reconciliado | `viracash.cdx.json` rev. 5; `5CAC79C3B3BAC56A693929050E17F227D477E04D592D8B3865E57B0A6453327D` | 1.7; no revalidado con el esquema | No ejecutada; estado UNKNOWN | VERIFICACIÓN |

La entrada actual documenta una resolución estable de fuentes, no una entrega. Por eso puede verificar el generador y el saneamiento, pero no cierra el SBOM de release ni identifica todavía un EXE o instalador concreto.

La revisión 3 conserva el número de serie y el análisis del 25 de agosto de 2026, e incrementa `version` porque añade a mano el componente DejaVu Sans 2.37. Ese alta no procede de Pascal Analyzer y no sobrevive a una regeneración del inventario mientras el normalizador no la inyecte.

La revisión 4 pasa ese componente a `required` y describe cómo se distribuye, porque el instalador DEMO ya empaqueta las cuatro caras TrueType. Las huellas de los archivos y el digesto agregado no cambian: son los mismos binarios que se inventariaron el 5 de septiembre.

La revisión 5 retira DejaVu Sans 2.37, porque la aplicación dejó de referenciarla el 14 de septiembre de 2026, y da de alta a mano Source Sans 3 3.052 (Adobe, licencia OFL 1.1) con las huellas de las cuatro caras que empaqueta el instalador DEMO: Regular, Bold, Italic y Bold Italic. Como en las revisiones anteriores, la entrada no procede de Pascal Analyzer y no sobrevive a una regeneración mientras el normalizador no la inyecte.

## Datos que debe conservar cada entrada

- herramienta y versión del generador;
- fecha y entorno de construcción controlado;
- versión, commit y plataforma;
- hashes del EXE, instalador, bibliotecas distribuidas y SBOM;
- resultado de validación del esquema;
- componentes sin identidad o sin cobertura de vulnerabilidades;
- aprobador y ubicación del expediente interno;
- correcciones o VEX asociados.

Última revisión: 2026-09-14.
