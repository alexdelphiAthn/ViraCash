# Material de ayuda SPFE

Consulta y descarga: 12-11-2026. Investigación autorizada por el usuario
para resolver las dudas del PLAN, sin comenzar la Fase 2.

Esta carpeta usa la ruta literal solicitada `doc/spfe/help`, en el
repositorio activo ViraCash. Las fuentes originales de la Fase 1 siguen
en `ViraCash_web/docs/spfe`; el plan sigue en `ViraCash/docs/spfe/PLAN.md`.
Los materiales auxiliares no sustituyen automáticamente el contrato técnico.

## Descargas y procedencia

`FUENTES_20261112.json` registra URL solicitada y final, fecha de consulta,
HTTP, tipo de contenido, Last-Modified, tamaño y SHA-256 de cada descarga.
Las fechas de consulta del manifiesto se guardan en UTC.

| Carpeta | Material | Uso y límites |
|---|---|---|
| `aeat/` | Anexos I/II, validaciones, factura básica, catálogo, formatos, ejemplos SOAP, WSDL/XSD e índice técnico | Las ocho descargas de documentos/paquetes coinciden byte a byte con las copias originales locales. No se encontró una versión nueva en estas URLs. WSDL descargado como documentación, sin importar ni llamar servicios. |
| `boe/` | Orden HAC/1028/2026 en PDF y HTML; RD 238/2026 en PDF original | Fuentes normativas oficiales para contrastar el contrato técnico; hay una discrepancia concreta de ProfileID que debe aclararse. |
| `oasis/` | Distribución `os-UBL-2.5/UBL-2.5.zip` completa y manifiesto oficial | Aporta los esquemas ausentes en el ZIP de la AEAT. El archivo ZIP ocupa unos 111 MB; incluye documentación, ejemplos y otros recursos además de XSD. |
| `oasis/UBL-2.5/xsd/` | Árbol XSD y catálogo extraídos de la distribución | 116 XSD canónicos y un catálogo. La extracción inicial incluyó además 108 XSD y un catálogo en endorsed/xsd, en carpeta separada. Se conservaron rutas y contenido; imports/includes del árbol canónico sin referencias remotas ni ficheros ausentes. |
| `referencia_en16931/` | README y distribución etiquetada `validation-1.3.17` de ConnectingEurope | El README declara UBL 2.1 y ausencia de reglas CIUS. Es referencia auxiliar; no se ha acreditado compatibilidad con EN 16931:2026/SPFE/UBL 2.5. No usar como validador SPFE definitivo. |
| `busquedas/` | HTML de la consulta Google `SPFE AEAT UBL 2.5 Schematron rectificativa` | Google devolvió una página que pide JavaScript, sin resultados utilizables. La búsqueda web adicional permitió localizar fuentes oficiales; este HTML no es evidencia normativa. |

Puntos de entrada oficiales:

- [AEAT: información técnica SPFE](https://sede.agenciatributaria.gob.es/Sede/iva/factura-electronica/informacion-tecnica.html).
- [BOE: Orden HAC/1028/2026](https://www.boe.es/eli/es/o/2026/10/02/hac1028).
- [BOE: RD 238/2026](https://www.boe.es/eli/es/rd/2026/03/25/238).
- [OASIS: UBL 2.5 aprobado](https://docs.oasis-open.org/ubl/os-UBL-2.5/).
- [ConnectingEurope: versión 1.3.17](https://github.com/ConnectingEurope/eInvoicing-EN16931/releases/tag/validation-1.3.17).

## Resultado de esta ronda

1. **Esquemas UBL localizados.** El SHA-256 de `UBL-2.5.zip` coincide
   con el manifiesto publicado por OASIS. Se verificó también la integridad
   CRC del ZIP. Esto comprueba la descarga, no la conformidad del generador
   ni la aceptación de facturas SPFE. Véase `COMPROBACIONES_20261112.json`.
2. **Discrepancia BT-23 pendiente.** La Orden, Anexo I, BT-23 (PDF p.13),
   indica `urn:aeat:names:specification:ubl:schema:profile:B2B`.
   El Anexo I técnico de la AEAT (PDF p.6) y su `factura.xml` indican
   `urn:aeat:names:specification:schema:profile:B2B`.
   Cambia el segmento `:ubl:`. Se ha contrastado en las copias descargadas;
   no se ha elegido ni corregido una constante de implementación.
3. **Ejemplos de rectificativas aún no localizados.** La página específica
   de ejemplos UBL de la AEAT consultada solo enlaza el ejemplo básico.
   Los ejemplos genéricos que pueda contener OASIS no acreditan el perfil
   SPFE de rectificativas. No afirmar que no existen otras publicaciones.
4. **Validación semántica completa pendiente.** La descarga de XSD resuelve
   estructura, no reemplaza Schematron ni las reglas de negocio nacionales.
   El material ConnectingEurope descargado no acredita la adaptación
   requerida por SPFE. La documentación de validaciones AEAT descargada
   sigue siendo la misma versión de la Fase 1.
5. **Enlaces que exigen cautela.** El enlace WSDL desde la página de la Sede
   consultada llevó a una sección VERI*FACTU. Se descargó el paquete SPFE
   desde la URL específica ya documentada en el repositorio, no ese servicio.

## Preguntas, una a una

Primera pregunta resuelta por el usuario: **todas las facturas se emiten
en EUR**, incluidas las rectificativas. BT-5 queda fijo a EUR; no se requiere
conversión ni importes adicionales por moneda para BT-6, BT-167 y BT-111.
Decisión registrada en el PLAN, sin implementar todavía el generador.

Segunda pregunta resuelta: **incluir autofacturación para agricultores y
segunda mano**, con soporte de 389/471. Esto confirma el alcance funcional;
no implica que toda compra a particulares o recibo agrícola sea una factura
B2B a remitir. El código distingue modalidades AUTOFAC y REAGP en
`fza_facturas_compra.MODALIDAD_FACC`; el mapeo debe ampliarse para compras,
con proveedor como vendedor y empresa como comprador. El recibo REAGP se
clasifica separadamente (`EsFactura = False`) en el código actual.

Tercera aclaración recibida: aún no hay una empresa que use la posibilidad
de segunda mano; se desea ofrecerla. El caso concreto previsto de momento
son pequeños pagos a modistas. No se deduce que sean operaciones de bienes
usados ni se asigna clasificación fiscal por su cuantía. El usuario supone
que son particulares que hacen arreglos de ropa y cobran por trabajo, pero
advierte que carece de información confirmada. Caso hipotético aparcado: no
se considera resuelta su clasificación fiscal ni se usará como factura B2B
válida de referencia. Se mantiene el soporte general de autofacturación.

Cuarta decisión confirmada: **IVA, IGIC e IPSI desde la primera versión**,
aunque no haya clientes actuales usando IGIC/IPSI. Las correspondencias
fiscales y pruebas concretas siguen pendientes de documentación y datos.

Quinta decisión confirmada: **admitir todas las unidades de medida**,
incluidos metros, kilos y otras medidas. El usuario confirma una tienda de
telas cuya cantidad representa metros. Se utilizará el catálogo completo con
correspondencias oficiales extensibles, no un valor genérico para todo.
El origen localizado para BT-130 es TIPO_CANTIDAD_ARTICULO_FACLIN, copiado
del artículo, y el catálogo fza_unidades_medida.CODIGO_UNIMED.
CODIGO_UNIDAD_FACLIN sigue siendo SKU. Falta establecer las equivalencias
UNECE 20/21; las unidades sin equivalencia deben requerir resolución explícita.

Sexta decisión confirmada: **RAD Delphi 13.2**, según la corrección final
del usuario. Generador y DUnitX compatibles con ese entorno.

Séptima aclaración: **Win64 mayormente; Win32 ocasionalmente para desarrollo
por rapidez**. Plan de comprobación: ejecutar DUnitX principalmente en Win64
y comprobar compilación del generador y pruebas en Win32; ampliar ejecución
Win32 cuando existan diferencias o riesgos por arquitectura.

Octava decisión confirmada: **COMENTARIOS_FAC contiene comentarios legales
para el cliente que se imprimen en la factura**. Incluirlos en el XML como
BT-22, con BT-21 = REG según A1 p.5, conservando el contenido no vacío y
escapando XML. No tratarlos como notas internas ni resumirlos.

Novena decisión confirmada: **incluir suplidos desde la primera versión**,
aunque no haya clientes actuales que los usen. Mapeo A1 p.15: BG-34,
BT-179 importe, BT-180 descripción y BT-ES-10 identificación SUPL con
calificador L7. Falta diseñar captura y persistencia; no hay origen localizado
en el flujo revisado. Deben distinguirse de las ventas y conciliarse con el
total a pagar. Esta decisión no extiende por sí sola el alcance a otros cargos.

Décima decisión confirmada: **admitir facturas pagadas total o parcialmente
al emitir**. El XML conservará total, pagos aplicables y saldo a esa fecha;
saldo pendiente cero si está completamente pagada (BT-115). Queda pendiente
la fuente y clasificación: no equiparar cualquier cobro previo con BT-113,
que excluye anticipos con devengo según A1 p.14. Los parciales tampoco son
comunicaciones PAYMENT/SETTLEMENT completas del Anexo II.

Undécima decisión confirmada: **generación UBL de facturas históricas y
nuevas**, incluidas las emitidas antes de activar SPFE. No implica remisión
masiva. Recuperar identidad y datos originales, incluidos pagos a la fecha
de emisión; no reconstruirlos con fichas o saldos actuales sin evidencia.
Lo que no pueda recuperarse queda pendiente de revisión/completar, sin
alterar factura ni VERI*FACTU. Falta verificar el origen de datos históricos;
las lecturas se harán por clave o lotes acotados.

Duodécima decisión confirmada: **varias retenciones por factura**, aunque
no haya clientes actuales que lo requieran. Registrar detalle de concepto L5,
base, porcentaje y cuota (BG-ES-4), conciliado con totales. La cabecera actual
solo ofrece agregados: el detalle adicional queda pendiente de diseño y de
migración revisable, sin cambios de esquema en esta fase.

Para explicar el caso de uso se descargó el cuadro oficial de tipos de
retención de la AEAT en aeat/cuadro_tipos_retencion.html, con procedencia
en el manifiesto. Distingue, entre otros, agricultura/ganadería general (2 %)
y engorde de porcino/avicultura (1 %). Ejemplo ilustrativo, no caso real del
usuario ni autorización de agrupación: si un mismo proveedor documenta en
una factura conceptos agrupables sujetos a ambos tipos, sus bases y cuotas
necesitan desgloses separados. Esto no impone aplicar varias retenciones
a una factura ordinaria ni fija automáticamente el régimen del proveedor.

Esquema localizado por indicación del usuario: **ViraCash_web/viracash_web.sql**.
Cabecera de backup: 12-11-2026 19:34:58. Se revisó únicamente por lectura;
no se ejecutó ni modificó. Contiene datos: no se ha copiado el volcado a esta
carpeta. `ESQUEMA_VERIFICADO_20261112.json` conserva solo metadatos de 16
tablas y SHA-256 del fichero fuente, sin INSERT ni datos personales.

Se confirman claves para factura/líneas/efectos/pagos, relaciones y
consolidación, así como candidatos de pagos históricos, condiciones de pago,
IBAN receptor y PDF/XML de emisión. El PLAN incorpora las precisiones.
DESCRIPCION_PRINT_FACLIN no es columna física de este esquema; se corrigió
el mapeo. Suplidos, retenciones múltiples y equivalencias UNECE siguen
requiriendo diseño de datos adicional. No se ha supuesto que las columnas
históricas estén completas por el hecho de existir.

Decisión confirmada sobre identidad: **conservar siempre la serie y el
número originales de la factura emitida**, aunque cambie el formato de la
empresa. El usuario no conoce cambios previos, pero exige contemplarlos.
Guardar componentes e identificador externo exacto; capturar los nuevos al
emitir. Recuperar históricos desde evidencias originales y dejar pendientes
los ambiguos. No reconstruirlos automáticamente con el formato actual ni
alterar los registros fiscales existentes.

Decisión confirmada: **incluir facturación por terceros desde la primera
versión**, aunque no haya clientes actuales. BG-ES-1 requiere nombre/razón
social, identificación fiscal y tipología del tercero; falta captura y
persistencia. Diferenciar tercero expedidor, vendedor, comprador y remitente
con certificado. ViraCash no se convierte automáticamente en el tercero
por generar el XML; el vendedor conserva su papel en la identidad de factura.

Aclaración confirmada: **vendedor y almacén propios, ambos opcionales**.
Se trata del vendedor que realiza la venta y del almacén de salida de la
mercancía. Candidatos: CODIGO_VENDEDOR_FACLIN y CODIGO_ALM_FAC, con detalle
por línea cuando corresponda. Propuesta: notas adicionales BG-1/BT-22 sin
REG, separadas de las menciones legales y de BT-10. Omitir lo ausente y no
inventar una identidad única si hay varios vendedores/almacenes. La respuesta
no confirma referencias externas proporcionadas por el comprador.

Decisión confirmada: **vencimientos al emitir y también creados/modificados
después**, incluidas reagrupaciones/conciliaciones por impago y pagos parciales.
Separar versión documental del XML de gestión posterior; conservar trazabilidad
y aplicación de importes por factura. El código permite fusiones con la misma
empresa/tercero y marca los orígenes CONCILIADO con pendiente cero, trasladando
la deuda al efecto destino. Ese estado no acredita pago completo: no debe
disparar por sí solo PAYMENT/SETTLEMENT. El PLAN incorpora la necesidad de
detalle de aplicaciones y los casos de prueba de fusiones/parciales.

Decisión confirmada sobre reparto: **propuesta automática por antigüedad de
factura, revisable y modificable antes de confirmar**. Usar fecha de expedición
original y desempate estable; limitar a las facturas origen del efecto.
Mostrar y validar importe por factura, suma y remanente; verificar cambios de
pendiente antes de grabar y conservar el reparto confirmado con auditoría.
Sin aplicaciones por cancelar la revisión ni comunicaciones SPFE automáticas
por proponer el reparto. Es política de gestión, no regla fiscal del anexo.

Decisión confirmada: **inmuebles y referencias catastrales fuera de la primera
versión**. Se incorporarán si un cliente lo pide más adelante; no se añade
ahora captura, persistencia ni pruebas específicas de ese supuesto. La
capacidad general de varias retenciones permanece incluida.

Decisión confirmada: **portes como conceptos/líneas de factura**. Usar
BG-25/InvoiceLine con los importes e impuestos registrados, sin duplicarlos
como cargo BG-21 ni confundirlos con suplidos. No requieren captura ni esquema
adicional para el generador. La respuesta no confirma otros cargos o tasas.

Decisión confirmada: **facturas de anticipo y regularización en la final**
desde la primera versión, aunque no haya clientes actuales. Conservar sus
identidades y detalle tributario, vínculos e importes aplicados, evitando
dobles aplicaciones. La regularización UBL precisa queda pendiente de
contraste documental; los anticipos con devengo no se volcarán a BT-113.
Hay candidatos de tesorería/depósitos en el código, pero no se considera
acreditado todavía un vínculo fiscal completo entre anticipo y factura final.

Descargadas en aeat/ dos páginas oficiales: anticipos_devengo_iva.html y
anticipos_obligacion_facturar.html, con URL y SHA-256 en el manifiesto.
Son apoyo sobre IVA, no una regla universal para IGIC/IPSI ni especificación
del XML de regularización SPFE.

Decisión confirmada: **un anticipo puede aplicarse parcialmente a varias
facturas finales**, controlando importe aplicado y saldo disponible. Guardar
vínculos, desglose, historial y clave de idempotencia; verificar saldo por
clave al confirmar en una transacción local para impedir dobles aplicaciones
y sobreconsumo concurrente. Las propuestas sin confirmar no consumen saldo.
El PLAN incorpora tablas conceptuales SPA/SPAA y pruebas de concurrencia,
rollback y agotamiento. Sin creación de tablas ni cambios fiscales en esta fase.

Decisión confirmada: **impuestos especiales aplazados**, a incorporar solo
si un cliente lo necesita. No se excluyen por ello IVA/IGIC/IPSI ni suplidos.
La exclusión de especiales no resuelve automáticamente otros cargos o tasas.

Decisión confirmada: **la Orden del BOE prevalece** frente a documentos y
ejemplos AEAT discrepantes. Registrar diferencias sin alterar originales;
comprobar compatibilidad PRE solo en Fase 4, cuando lo indique el usuario.
ProfileID del generador: urn:aeat:names:specification:ubl:schema:profile:B2B.
Registro: DIFERENCIAS_BOE_AEAT.md. Sigue pendiente comparar íntegros los anexos.

Decisión confirmada: **una factura puede agrupar y sustituir varios tickets
del mismo cliente**, con referencias originales y bloqueo de doble facturación.
Se requiere colección BG-3, persistencia de relaciones múltiples y consumo
atómico de orígenes con idempotencia. La clave FACREL actual limita a un origen
por tipo/destino y no protege la unicidad del ticket entre distintos destinos.
No duplicar ventas, cobros ni stock, ni modificar VERI*FACTU para resolverlo.
El PLAN documenta límites del esquema, revisión del enganche fiscal y pruebas.

Ampliación confirmada: **rectificativa de varias facturas del mismo cliente**,
con referencias y detalle de importes rectificados por origen. El usuario
aclara que **hoy no existe este movimiento en ViraCash**. Es diseño nuevo,
no capacidad del repositorio actual. El contrato del generador podrá admitir
la colección, pero crear/gestionar la operación exige trabajo posterior.
Conservar el desglose local y usar en XML solo la representación documentada,
sin extensiones inventadas para importes por origen.

Pendiente importante: la emisión VERI*FACTU revisada solo lee/construye una
antecesora. Mantener el módulo y hash intactos; falta resolver compatibilidad
antes de habilitar la nueva operación real. No implica permiso para modificar
VERI*FACTU ni para comenzar Fase 2.

Nuevo paquete proporcionado y verificado:
**ViraCash_web/docs/spfe/en16931-ubl-1.3.17**, 27 archivos/5.077.180 bytes.
Todos coinciden por SHA-256 con la release fuente descargada. Includes locales
resueltos; hoja compilada XSLT 2.0 sin imports; Schematron queryBinding xslt2.
Ejemplos: 18 Invoice y 1 CreditNote, que no es tipo de remisión SPFE.
Informe: VERIFICACION_EN16931_1_3_17_LOCAL.json. No se ha ejecutado el XSLT.

La capa EN está disponible para su edición, pero **no queda acreditada la
cobertura completa de EN 2026/SPFE**. UBL-CR-002 y UBL-CR-513 ilustran
diferencias con UBL 2.5 y las retenciones SPFE. Conservar las reglas y sus
diagnósticos; separar cobertura aplicable de diferencias de versión con
trazabilidad, sin desactivar errores arbitrariamente. Motor XSLT 2.0+
pendiente de elegir; XslCompiledTransform no sirve para esa hoja.

Intentada la obtención de las normas UNE 2026: UNE responde 403. Se guardaron
solo fichas AENOR, sin texto de las normas ni compra/autenticación. Véase
ACCESO_UNE_2026.json. La página de la Comisión sobre acceso gratuito sigue
referenciando 2017 y está en revisión, de modo que no confirma descarga
gratuita anónima de ambas ediciones 2026.

Siguiente pregunta pendiente: ¿dispone el usuario de acceso de descarga
autorizado a UNE/AENOR para los dos textos de 2026?

Nueva revisión del README original y la carpeta local ubl-2.5:
**116 XSD canónicos comprobados**, idénticos a OASIS por SHA-256 (101 maindoc,
15 common). Invoice, DocumentStatus y ApplicationResponse compilan sin red;
factura.xml de la AEAT valida contra Invoice. Informe:
`VERIFICACION_UBL_LOCAL_20261112.json`. Usar la carpeta documental original
como referencia XSD. Esto resuelve disponibilidad y prueba sintáctica básica,
no conformidad semántica SPFE ni la discrepancia de ProfileID. No se ha
comenzado el generador de Fase 2.

El orden
previsto prioriza alcance de tipos/operaciones, identidad impresa, clasificación
fiscal, rectificativas, vencimientos y pagos previos, unidades/medios de pago,
y conceptos especiales realmente usados. La discrepancia documental BT-23
debe aclararse antes de fijar el contrato, sin pedir al usuario que invente
una regla de la AEAT.

Sin código generado, pruebas DUnitX, migraciones, conexiones de BD ni llamadas
a servicios SPFE. Sin commit, push ni merge.
