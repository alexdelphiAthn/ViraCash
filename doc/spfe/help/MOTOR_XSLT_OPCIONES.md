# Decisión: evaluador Delphi nativo

El usuario exige Delphi nativo, sin Java ni DLL añadidas. Se descartan
SaxonJ, SaxonC y cualquier helper que distribuya esas dependencias a clientes.
No se precisa descompilar un motor: las 982 comprobaciones están publicadas
como fuente Schematron/XSLT en el paquete local oficial EN 1.3.17.

Implementación aislada en `src/Spfe/`: catálogo Pascal inmutable generado
desde el Schematron preprocesado, navegación XML con ADOM del RTL y
evaluador del subconjunto XPath que utiliza esa versión. Conserva los
identificadores, mensajes, gravedad, orden de los patrones y trazabilidad
SHA-256. Las reglas mantienen EUPL-1.2 y su licencia original adjunta.

El generador de catálogo usa Python exclusivamente en desarrollo. La
aplicación no necesita Python, Java, Saxon, MSXML ni bibliotecas adicionales.
El contraste de desarrollo ejecuta la hoja XSLT original con SaxonC/Python
en un temporal independiente, que no se distribuye con ViraCash.

No es un intérprete completo de XPath/XSLT. Los operadores y funciones
admitidos corresponden a las expresiones fuente de esta release; cualquier
cambio requiere regeneración, revisión y pruebas. Errores de evaluación no
equivalen a factura válida. La API devuelve cobertura incompleta o propaga el
error de infraestructura; distingue avisos, fallos fatales y errores técnicos.

Esto cubre únicamente la capa de referencia EN 2017+A1 / UBL 2.1. No completa
la semántica 2026, las reglas SPFE ni la validación XSD UBL 2.5. Se conservan
los diagnósticos UBL-CR-002 y UBL-CR-513, sin alterarlos para conseguir verde.

El ejecutor todavía no está integrado en ViraCash: quedan cola persistente,
coordinación de un solo trabajador por instalación, prioridades, cancelación,
recuperación e instrumentación del impacto en equipos de dos núcleos. Las
pruebas del componente no demuestran por sí solas ausencia de impacto en
la emisión. No se ha iniciado el generador UBL ni modificado VERI*FACTU.

Los resultados y la reproducción se describen en
[README del componente](../../../src/Spfe/README.md).
