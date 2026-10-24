# Grafo resumido de componentes

Esta es una vista humana y agrupada de las familias observadas durante el análisis Pascal. No sustituye al grafo exacto de dependencias CycloneDX ni demuestra por sí sola qué binarios se distribuyen con una versión concreta.

El grafo exacto de la instantánea de análisis está en [viracash.cdx.json](viracash.cdx.json). Contiene un nodo para cada uno de sus 2.577 componentes y declara la composición como incompleta porque todavía no se ha reconciliado con una entrega.

~~~mermaid
flowchart TD
  F["ViraCash<br/>aplicación raíz"]
  F -->|componentes inventariados| P["Código propio<br/>vcash.dpr y unidades propias de src/"]
  F -->|dependencias inventariadas| T["Componentes de terceros"]
  T --> D["Embarcadero Delphi 13<br/>RTL / VCL / Internet"]
  T --> X["DevExpress VCL"]
  T --> R["FastReport VCL"]
  T --> U["UniDAC 12.0.1.0<br/>agregado binario DCU/BPL<br/>DAC 15.0.1.0"]
  T --> J["JCL / JVCL"]
  T --> O["SynEdit, SynPDF, DCPCrypt<br/>y otras fuentes externas"]
  T --> V["Código de terceros vendorizado<br/>src/Lib3par y otras copias"]
  T --> N["Source Sans 3 3.052<br/>tipografía TrueType redistribuible<br/>empaquetada por el instalador NSIS"]
~~~

## Cómo interpretar el grafo

- Las aristas muestran agrupaciones de inventario, no enlaces exactos entre unidades Pascal.
- Pascal Analyzer resuelve tanto código del repositorio como fuentes instaladas fuera de él.
- Pascal Analyzer resuelve UniDAC desde DCU. Los BPL instalados solo se usan como evidencia de versión y huella hasta reconciliar los binarios realmente distribuidos.
- Algunas bibliotecas tienen copias vendorizadas y externas distintas. El SBOM de release debe indicar cuál se compiló realmente.
- Delphi y Pascal Analyzer usados para construir o analizar deben distinguirse de las bibliotecas que forman parte del producto.
- Source Sans 3 no es una dependencia de código sino un activo redistribuible. Se inventaría a mano con las huellas de sus cuatro caras y está marcado como `required` porque el instalador DEMO lo empaqueta y lo registra en la carpeta de fuentes de Windows. Sustituye a DejaVu Sans 2.37 desde el 14 de septiembre de 2026.

## Evolución prevista

El archivo CycloneDX saneado es la fuente canónica del grafo exacto del análisis. Este documento seguirá siendo un resumen revisable por personas. Ambos deberán regenerarse o comprobarse en cada entrega importante y reconciliarse con los binarios efectivamente distribuidos.

Última revisión: 2026-09-14.
