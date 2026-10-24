# Tareas de preparación para el CRA

Estados permitidos: PENDIENTE, EN PROGRESO, BLOQUEADA, VERIFICACIÓN o COMPLETADA. Una tarea solo se marca COMPLETADA cuando su evidencia esté revisada y ligada a una versión del producto.

| ID | Prioridad | Base CRA | Tarea | Estado | Evidencia o salida esperada | Responsable | Fecha objetivo |
|---|---|---|---|---|---|---|---|
| CRA-001 | P0 | Arts. 2-8, anexos III-IV y Reglamento de Ejecución (UE) 2025/2392 | Determinar si ViraCash se introduce en el mercado de la UE, el operador económico responsable y la clasificación del producto. | PENDIENTE | Informe jurídico-técnico aprobado. | Por asignar | Antes de cualquier declaración de conformidad |
| CRA-002 | P0 | Art. 14 y art. 71.2 | Crear el procedimiento de notificación de vulnerabilidades explotadas activamente e incidentes graves, con responsables, reloj, contactos, plantillas y simulacro. | PENDIENTE | Procedimiento y acta de simulacro. | Por asignar | 2026-09-11 |
| CRA-003 | P0 | Anexo I, parte II | Publicar un canal de seguridad y un proceso de recepción, triaje, corrección y divulgación coordinada. | PENDIENTE | SECURITY.md, SLA interno y registro de casos. | Por asignar | 2026-09-11 |
| SBOM-001 | P1 | Anexo I, parte II.1 | Generar el inventario CycloneDX interno desde Pascal Analyzer y validar referencias, hashes y raíz. | VERIFICACIÓN | `viracash.cdx.json`: CycloneDX 1.7 válido, 2.577 componentes/nodos y cero referencias colgantes; falta ligarlo a una entrega. | Desarrollo | Próxima entrega |
| SBOM-002 | P1 | Anexo I, parte II.1 | Crear un exportador saneado sin rutas locales ni datos del entorno. | VERIFICACIÓN | Normalizador probado en PowerShell 7 y 5.1; conjunto exportable sin rutas locales archivado con SHA-256. | Desarrollo | Próxima entrega |
| SBOM-003 | P1 | Anexo I, parte II.1 | Generar un SBOM por versión y plataforma, ligado a commit, EXE o instalador y sus hashes. | PENDIENTE | SBOM Win32/Win64 y manifiesto de artefactos por release. | Desarrollo / Release | Próxima entrega |
| SBOM-004 | P1 | Anexo I, parte II | Completar proveedor, versión, licencia y evidencia de Delphi, DevExpress, FastReport, UniDAC/DAC, JCL, JVCL, SynEdit, Source Sans 3 y demás terceros. | EN PROGRESO | Catálogo curado y trazable de terceros. Source Sans 3 3.052 ya lleva proveedor, versión, licencia, copyright y huellas por cara. | Desarrollo | Próxima entrega |
| VULN-001 | P1 | Anexo I, parte II | Implantar vigilancia de avisos y vulnerabilidades, incluida la revisión manual de proveedores comerciales. | PENDIENTE | Fuentes monitorizadas, fecha de base, cobertura y resultados. | Seguridad / Desarrollo | Antes de declarar cumplimiento |
| VULN-002 | P1 | Anexo I, parte II | Registrar análisis, decisiones y, cuando proceda, VEX para cada versión. | PENDIENTE | Registro vulnerabilidad-componente-versión-corrección. | Seguridad / Desarrollo | Cada entrega |
| RISK-001 | P1 | Art. 13 y anexo I | Crear y versionar una evaluación de riesgos de ciberseguridad de ViraCash. | PENDIENTE | Activos, superficies, amenazas, controles, riesgo residual y aprobación. | Por asignar | Antes de declarar cumplimiento |
| UPDATE-001 | P1 | Anexo I, partes I-II | Reforzar el actualizador con firma de fabricante o manifiesto firmado y protección contra retroceso. | PENDIENTE | Diseño, implementación y pruebas automatizadas. | Desarrollo | Antes de declarar cumplimiento |
| SUPPORT-001 | P1 | Art. 13.8-10 y 13.19; anexos II.7 y VII.4 | Definir período de soporte, versiones mantenidas, fin de soporte y política de actualizaciones de seguridad. | PENDIENTE | Política publicada y trazabilidad de versiones. | Producto / Dirección | Antes de comercialización aplicable |
| DOC-001 | P2 | Anexos II y VII | Preparar instrucciones para el usuario y expediente técnico de ciberseguridad. | PENDIENTE | Documentación de instalación segura, configuración, actualización, retirada y evidencias técnicas. | Producto / Desarrollo | Antes de evaluación de conformidad |
| CI-001 | P2 | Evidencia de proceso | Integrar generación, saneamiento y validación del SBOM en la canalización de calidad. | PENDIENTE | Trabajo CI reproducible con archivo de resultados. | Desarrollo | Tras SBOM-002 y SBOM-003 |
| SBOM-005 | P1 | Anexo I, parte II.1 | Hacer que `normalizar_sbom_pascal_analyzer.ps1` inyecte los activos redistribuibles que no son unidades Pascal, empezando por Source Sans 3, para que no se pierdan al regenerar. | PENDIENTE | Normalizador que reproduce el componente y su digesto agregado sin intervención manual. | Desarrollo | Antes de SBOM-003 |

## Criterios mínimos para cerrar el bloque SBOM

- El JSON cumple el esquema CycloneDX seleccionado.
- Existe una raíz única para ViraCash y no hay referencias colgantes.
- No hay rutas absolutas, credenciales ni datos de la máquina de construcción.
- Cada archivo entregable y SBOM están ligados mediante SHA-256.
- Se identifica la versión, plataforma, commit y fecha de la entrega.
- Las dependencias de primer nivel están completas y las transitivas conocidas se registran cuando sea posible.
- La cobertura del análisis de vulnerabilidades se declara expresamente; cero coincidencias no se presenta como ausencia demostrada de vulnerabilidades.
- Se conserva el historial durante el período exigible y se controla quién puede acceder al inventario interno.

Última revisión: 2026-09-14.
