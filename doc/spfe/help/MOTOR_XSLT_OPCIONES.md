# Motor XSLT para validación en segundo plano

Necesidad: el artefacto EN 1.3.17 suministrado requiere XSLT 2.0. El usuario
pide validación en clientes y pruebas, fuera de emisión, con dos núcleos de
servidor. No se ha instalado ni seleccionado todavía un motor definitivo.

| Opción | Evidencia oficial | Implicación de diseño |
|---|---|---|
| SaxonJ-HE | SaxonJ 13 requiere Java 17 o posterior según Getting started | Java como requisito adicional; auxiliar persistente para evitar arranque y compilación por factura |
| SaxonC-HE | Distribución nativa para Windows 64-bit y API C/C++ | Evaluar helper nativo aislado con sus librerías; comprobar redistribución, dependencias y consumo antes de elegir versión |

Propuesta a revisar: priorizar la opción nativa para no exigir instalación
Java, manteniendo un límite compartido de un trabajo activo por instalación.
Un proceso Win32 en Windows 64-bit puede usar un helper Win64 externo;
esto no equivale a cargar una DLL Win64 dentro del proceso Win32. Queda
pendiente comprobar que no se requiera Windows de 32 bits en clientes.
El ejecutable transform de SaxonC debe construirse según su documentación;
no se presupone un ejecutable final listo para redistribuir desde el ZIP.

La configuración de un trabajo no garantiza por sí sola ausencia de impacto:
medir arranque, hoja compilada, memoria y carga interactiva en dos núcleos.
Evitar procesos por factura, paralelismo interno no necesario y consultas
históricas. Capturar todos los diagnósticos y su versión; las reglas EN 2017
no son un certificado de conformidad 2026/SPFE.

Fuentes primarias consultadas:

- [Plataformas Saxonica](https://www.saxonica.com/html/products/platforms.html).
- [SaxonC, producto](https://www.saxonica.com/html/saxon-c/index.html).
- [Descargas nativas Windows 64-bit](https://www.saxonica.com/html/download/c.html).
- [SaxonJ: requisitos Java](https://www.saxonica.com/html/documentation13/about/gettingstarted/gettingstartedjava.html).
- [Uso por línea de comandos y construcción de transform](https://www.saxonica.com/html/documentation13/using-xsl/commandline/index.html).

No se han ejecutado binarios descargados, añadido dependencias a la aplicación
ni comenzado Fase 2. La versión y el empaquetado deberán verificarse al
preparar la implementación, manteniendo las licencias y avisos del proveedor.
