# Integración directa de ViraCash con SPFE: análisis de Fase 1

Fecha: 12-11-2026. Rama: `analisis/spfe-fase1`.
Estado: análisis entregado para revisión; no iniciar Fase 2 sin indicación.

Seguimiento 12-11-2026: a petición del usuario se ha iniciado investigación
externa para resolver dudas, planteándolas una a una. El cuerpo de la Fase 1
describe el material disponible al redactarlo; las novedades verificadas se
registran en [el material de ayuda](../../doc/spfe/help/README.md) y sus
manifiestos de descargas. Los XSD UBL 2.5 ya se han obtenido de OASIS, pero
la validación semántica SPFE completa sigue pendiente. El usuario ha confirmado
que todas las facturas, incluidas las rectificativas, se emiten en EUR.
BT-5 queda fijado a EUR; BT-6, BT-167 y BT-111 no son necesarios por
conversión de moneda en este alcance. No se inicia la Fase 2.

Decisión confirmada sobre tipos: incluir autofacturación para agricultores y
segunda mano, con soporte de 389 y 471. La respuesta confirma funcionalidad,
no determina por sí sola el régimen fiscal ni la obligación de remitir cada
operación a SPFE.

El código localizado amplía el origen del mapeo: las autofacturas se guardan
en `fza_facturas_compra.MODALIDAD_FACC = AUTOFAC`, según
`src/Lib/inLibComprasDirectas.pas` y
`src/DataModules/UniDataComprasDirectasFiscal.pas`. El proveedor es el vendedor
(`NIF_PRV_FACC`, `RAZON_SOCIAL_PRV_FACC`) y la empresa compradora es el
destinatario (`NIF_EMPRESA_FACC`, `RAZON_SOCIAL_EMPRESA_FACC`). Se requiere
un adaptador de lectura propio para estos documentos, además del de ventas;
el mapeo de la Fase 1 basado en F/L no cubre todavía todos sus campos.
`MODALIDAD_FACC = REAGP` es otra modalidad: el código actual la clasifica
con `EsFactura = False`. No se convertirá automáticamente en autofactura
389 por mencionar agricultores. Su tratamiento documental queda pendiente.
El usuario aclara que todavía no hay una empresa usando la compra de segunda
mano con autofacturación; es una posibilidad que desea ofrecer. El caso
concreto previsto de momento son pequeños pagos a modistas. No se presume
que se trate de compraventa de bienes usados ni se asigna un régimen fiscal
por la cuantía del pago. El usuario supone que son particulares que hacen
pequeños arreglos de ropa y cobran por trabajo, pero no dispone de información
confirmada. Se registra como hipótesis, no como clasificación fiscal resuelta
ni como fixture representativa de una factura B2B válida. Este caso queda
aparcado hasta disponer de datos reales; el soporte general de autofacturación
sigue incluido.

Decisión confirmada: el generador cubrirá IVA, IGIC e IPSI desde la primera
versión, aunque todavía no haya clientes usando IGIC/IPSI. Se mantienen
pendientes sus correspondencias documentadas con L3A/L3B/L3C y L4, el origen
por operación/línea y los casos de prueba; la confirmación de alcance no
aprueba tipos impositivos ni reglas fiscales por defecto.

Aclaración del origen de BT-130: `CODIGO_UNIDAD_FACLIN` se usa como código
de SKU en el código activo (`UniDataFacturasConfiguracion.pas` enlaza con
`fza_articulos_skus.CODIGO_UNIDAD_SKU`; el equivalente de compras se lee
como SKU en `UniDataFacturasCompraMovimientos.pas`). No representa por sí
solo una unidad UNECE. La revisión adicional localiza el origen físico en
`L.TIPO_CANTIDAD_ARTICULO_FACLIN`, copiado de `TIPO_CANTIDAD_ART` al asignar
el artículo (`inLibFacturasLineasEdicion.pas`). La ficha usa el catálogo
`fza_unidades_medida.CODIGO_UNIMED`, con descripción, decimales, magnitud y
factor a unidad base. Referencias: `UniDataArticulos.dfm`,
`UniDataUnidadesMedida.dfm` e `inLibUnidadesMedida.pas`.

Decisión confirmada sobre medidas: hay una tienda que vende telas por metros;
el usuario pide admitir todas las unidades, incluidos kilos y otras medidas.
El generador debe admitir el catálogo completo mediante correspondencias
UNECE 20/21 explícitas y extensibles, conservando la unidad y cantidad de la
línea emitida. No limitar el diseño a prendas o metros, ni transformar una
unidad desconocida en unidades genéricas. Falta acreditar la equivalencia
oficial de cada código interno; no se supone que CODIGO_UNIMED ya sea UNECE.
Esta decisión no autoriza a modificar catálogos ni esquema en la Fase 1.
Entorno confirmado por el usuario: RAD Delphi 13.2. Esta es la respuesta
definitiva tras su corrección de versión. El generador y las pruebas DUnitX
deben ser compatibles con ese entorno. El usuario utiliza mayormente Win64
y ocasionalmente Win32 por rapidez durante el desarrollo. Win64 será la
plataforma principal de ejecución de DUnitX; se comprobará también que el
generador y el proyecto de pruebas compilan para Win32. La ejecución completa
adicional en Win32 se decidirá si hay riesgos o diferencias por arquitectura.
Decisión confirmada sobre COMENTARIOS_FAC: son comentarios legales para el
cliente y se imprimen en la factura. Incluir el contenido no vacío como nota
BT-22 con BT-21 = REG, conforme a A1 p.5. Conservar el texto y escapar XML;
no resumirlo ni reinterpretarlo. Mantener también las menciones legales de
empresa/cliente que correspondan y comprobar duplicados sin perder contenido.
Decisión confirmada: incluir suplidos desde la primera versión, aunque
no haya clientes actuales que los utilicen. A1 p.15 los representa en BG-34,
con importe BT-179, descripción BT-180 e identificación SUPL en BT-ES-10
(aplicando el calificador L7). No hay origen localizado para importe ni
descripción: sigue pendiente diseñar su captura y persistencia separadas,
su participación en el total a pagar y las pruebas de conciliación. La
confirmación de suplidos no implica aprobar otros cargos o tasas de terceros.
Decisión confirmada: admitir facturas pagadas total o parcialmente al
emitirlas. Conservar por separado el total documental, los importes ya
pagados y el saldo pendiente a la fecha de expedición; cambios posteriores
en los efectos no deben alterar el XML emitido. El caso totalmente pagado
debe reflejar saldo pendiente cero, conforme a BT-115. Sigue pendiente
identificar la fuente de pagos y distinguir los supuestos de anticipo de
BT-113: A1 p.14 excluye de ese término los anticipos con devengo de IVA.
La confirmación de alcance no autoriza a transformar todo cobro previo
en BT-113. Los parciales locales tampoco se convertirán en comunicaciones
PAYMENT/SETTLEMENT de Anexo II, reservadas a pago/cobro completo.
Decisión confirmada: admitir generación UBL tanto de facturas nuevas como
de facturas emitidas antes de activar SPFE. No se autoriza con ello una
remisión masiva ni una conexión de red. El caso histórico requiere conservar
la identidad y los datos de la emisión original, incluidos pagos aplicables
a esa fecha; no usar automáticamente el saldo actual de los efectos.
Si un dato exigible no puede recuperarse con evidencia, la preparación queda
pendiente de completar/revisar, sin inventarlo ni modificar la factura o el
registro VERI*FACTU. La nueva instantánea SPFE se conserva para regenerar
el XML de forma estable. Las lecturas históricas serán por factura/lotes
acotados, sin barrer millones de filas durante la emisión.
La ficha de empresa permite editar FORMATO_DOCUMENTO_EMP en el código
revisado; falta cerrar la recuperación del número original y demás datos
históricos, preferiblemente desde documentos/registros ya conservados.
Decisión confirmada: admitir varias retenciones en una misma factura desde
la primera versión, aunque no haya clientes que lo necesiten actualmente.
BG-ES-4 se modelará como colección de concepto L5, base, porcentaje y cuota;
los totales existentes no permiten reconstruir varias retenciones distintas.
Se requiere detalle propio e instantánea por factura, con migración separada
a revisar en Fase 3. Mantener una retención como caso sencillo compatible.
Cada retención debe vincularse a su base y concepto; no sumar porcentajes
indiscriminadamente sobre toda la factura. La suma del detalle conciliará
con BT-ES-17 y el total de retenciones de la representación BG-34.
Esquema localizado por indicación del usuario: ViraCash_web/viracash_web.sql,
backup del 12-11-2026. Se ha leído sin ejecutar y extraído solo metadatos
de 16 tablas a doc/spfe/help/ESQUEMA_VERIFICADO_20261112.json.
Decisión confirmada: el usuario no conoce cambios históricos de formato,
pero exige contemplarlos y conservar siempre la serie y el número originales
de la factura emitida. Guardar ambos componentes y el identificador externo
exacto BT-1; no convertir números a entero ni alterar ceros o separadores.
Decisión confirmada: admitir facturación por terceros desde la primera
versión, aunque no haya clientes que la usen actualmente. Capturar y congelar
nombre/razón social y NIF del tercero, separados del vendedor y del comprador,
con tipología FacturaciónPorTercero según A1. El tercero expedidor no se
identifica automáticamente con ViraCash, su desarrollador ni el titular del
certificado de transporte; el contrato de datos debe indicar su papel. Falta
diseñar persistencia y captura de BG-ES-1 y resolver identificación LOC/VAT
según el anexo. Conservar el vendedor como emisor de la identidad documental.
Datos complementarios confirmados por el usuario: vendedor propio que hace
la venta y almacén propio del que sale la mercancía. **Ambos son opcionales**.
Orígenes candidatos: `fza_facturas_lineas.CODIGO_VENDEDOR_FACLIN`,
`fza_facturas.CODIGO_ALM_FAC` y, si aplica, almacén por línea. No son la razón
social del vendedor de BG-4 ni una referencia del comprador BT-10.
Propuesta de representación: notas adicionales BG-1/BT-22, que A1 permite
para información relevante adicional, sin código REG porque no son menciones
legales. No inventar elementos UBL propios. Incluir solo los valores presentes,
con su denominación identificada y congelada; no exigirlos ni elegir un solo
vendedor/almacén arbitrariamente si varían entre líneas. Capturar la relación
con líneas cuando corresponda, sin datos personales adicionales innecesarios.
La petición no confirma todavía referencias externas aportadas por el cliente.
Decisión confirmada: normalmente los vencimientos se generan según la forma
de pago al emitir, pero también pueden crearse o modificarse después. Se
incluyen reagrupación/conciliación tras impagos y pagos parciales. Conservar
la versión documental de condiciones/vencimientos incluida en cada XML y
separarla de las versiones de gestión posteriores. No reescribir un XML
emitido ni presumir que un cambio de efectos constituye rectificación de
factura o un mensaje admitido de actualización de vencimientos SPFE.

Hallazgo en `UniDataEfectosVenta.pas`: InsertarEfectoFusionado crea un nuevo
efecto sumando pendientes; ConciliarEfectosOrigen marca los efectos origen
CONCILIADO, pendiente cero y enlaza el destino mediante los campos
SERIE_FAC_CONCILIACION_EFV/NUMERO_FAC_CONCILIACION_EFV/NUMERO_EFV_CONCILIACION_EFV.
La validación compartida exige misma empresa y tercero, pero no una única
factura (`inLibEfectosCalculo.pas`). Por tanto **pendiente cero o CONCILIADO
no prueba cobro**: puede haberse trasladado la deuda a otro efecto. No
emitir SETTLEMENT/PAYMENT ni concluir factura pagada por ese cambio solo.

El diseño debe conservar procedencia, versiones y aplicaciones de cada pago
a facturas/efectos, incluso tras fusiones y pagos parciales, con importes
asignados y sin dobles cómputos. Reconciliar el historial completo solo para
las facturas afectadas y con acceso indexado; mantener un resumen de gestión
actualizable. Añadir a la propuesta una tabla de aplicaciones de pago (SPAP),
con referencia al movimiento, factura y efecto de origen/destino, importe,
fecha y versión. No reconstruir proporciones a partir de observaciones libres.
Decisión confirmada para cobros parciales de efectos agrupados: proponer
reparto automático por antigüedad de factura, empezando por las más antiguas,
y permitir revisar y modificar los importes antes de confirmar. Se interpreta
antigüedad por fecha de expedición original; ordenar después por serie/número
y clave estable para desempatar. El ámbito son las facturas origen del efecto
agrupado, no otras deudas del cliente. Dentro de una factura, proponer primero
sus vencimientos más antiguos sin perder la aplicación por factura.

La propuesta debe mostrar fecha/número, pendiente real y cantidad aplicada
por factura, con suma aplicada y remanente visibles. No exceder el pendiente
real de cada factura ni el importe disponible del cobro. Si falta fecha fiable,
no inventar antigüedad: señalar el caso para revisión. No aplicar un remanente
a otras facturas ni crear un saldo a favor automáticamente sin regla acordada.
Antes de confirmar, releer/verificar versiones y pendientes; si han cambiado,
recalcular y pedir una nueva revisión. La confirmación guarda aplicaciones y
resumen en una transacción local, con usuario/fecha y propuesta vs reparto
confirmado para auditoría. Cancelar la revisión no registra aplicaciones.

Las comunicaciones remotas deben basarse en pagos reales y en el estado
confirmado por rol, sin inferir impago por el mero vencimiento ni dar por
cancelado un estado remoto automáticamente. Este reparto es política de
aplicación propuesta y revisable, no una regla impuesta por el Anexo I/II.
No modifica las condiciones del XML original ni envía estados por sí solo.
Pruebas previstas: orden por antigüedad, empates estables, revisión manual,
pago parcial, factura saldada, remanente y concurrencia entre propuesta y
confirmación, incluida fusión de efectos de varias facturas.
Decisión confirmada: operaciones inmobiliarias y referencias catastrales
fuera del alcance inicial. No es una aplicación de alquileres; se incorporarán
si un cliente lo solicita más adelante. BG-32/RCAT, BT-161 de inmueble y
BT-ES-23 quedan como ampliación futura, sin captura, persistencia ni pruebas
específicas necesarias para cerrar esta primera versión. No excluir la
capacidad general de retenciones por esta decisión. No generar documentos
inmobiliarios incompletos si alguien intenta usar ese supuesto en el futuro.
Decisión confirmada: los portes se registran dentro de los conceptos de la
factura. Generarlos como líneas BG-25/InvoiceLine con cantidad, precio, importe
e impuestos del concepto registrado. No convertirlos en suplidos ni duplicarlos
como cargo de cabecera BG-21; los totales deben incluirlos una sola vez. No se
requiere captura ni persistencia adicional de portes para esta primera versión.
Otros cargos/tasas no quedan confirmados por esta respuesta.
Decisión confirmada: incluir facturas específicas de anticipo y su
regularización en la factura final desde la primera versión, aunque no haya
clientes actuales que lo usen. Conservar identidad de cada factura de anticipo,
fecha, base, impuesto/tipo/cuota, importe cobrado y cantidades ya aplicadas.
La final debe poder enlazar los anticipos que regulariza, con importe aplicado
y saldo restante, y conciliar importes para evitar aplicar dos veces un mismo
anticipo. No tratar el anticipo facturado como un suplido ni como descuento
comercial. El mecanismo XML exacto de regularización sigue pendiente de
contraste con reglas/ejemplos aplicables; no se ha fijado una fórmula fiscal
universal ni una representación UBL no documentada.

A1 excluye de BT-113 los anticipos con devengo de IVA. Se descargaron dos
páginas de la AEAT sobre devengo y obligación de facturar para documentar
esta distinción; no sustituyen la correspondencia técnica SPFE ni acreditan
por sí solas el tratamiento de IGIC/IPSI. No basta copiar el anticipo a
PrepaidAmount ni reutilizar códigos de otros perfiles UBL ajenos a L1.

En código hay IMPORTE_ANTICIPO_DEP en depósitos, porcentaje de anticipo en
formas de pago y movimientos ACUENTA/ANTICIPO, pero no se ha acreditado con
esta revisión un vínculo fiscal completo anticipo-factura final. Esas cifras
no son por sí solas una factura de anticipo ni su detalle tributario.
Falta diseñar datos de aplicación y su relación con las facturas, conservando
VERI*FACTU y las facturas originales. La política para corregir una aplicación
ya confirmada deberá preservar auditoría y documentos afectados.
Decisión confirmada: un mismo anticipo puede aplicarse parcialmente a varias
facturas finales. Conservar por aplicación la factura de anticipo, la factura
final, importes aplicados y su desglose tributario correspondiente, estado,
usuario/instante y clave de idempotencia. El saldo disponible se calcula a
partir del importe aplicable del anticipo y sus aplicaciones vigentes; no
se reduce por una propuesta todavía sin confirmar ni por un reintento doble.

Propuesta de persistencia adicional: `fza_spfe_anticipos` (SPA) para el vínculo
con la factura de anticipo y el control de versión/saldo; y
`fza_spfe_anticipos_aplicaciones` (SPAA) para los vínculos con facturas finales,
importes, estado e idempotencia. Forma parte del diseño pendiente de migración,
no es una tabla prescrita por la AEAT. Las aplicaciones de anticipo se
mantienen separadas de los cobros y suplidos para evitar deducciones dobles.

Al confirmar la factura final, bloquear/verificar el anticipo por su clave y
guardar aplicación y nuevo saldo dentro de la misma unidad de trabajo local.
No permitir aplicar más saldo del disponible. Si el saldo cambió desde la
propuesta, informar y revisar; no ajustar importes silenciosamente. Una
transacción fallida o un doble clic no debe consumir saldo adicional. Un
saldo agregado de cabecera solo podrá ser caché conciliada con el detalle,
no la única evidencia. Conservar historial de correcciones; el tratamiento
fiscal de anulación/devolución sigue necesitando documento y regla aplicable.
Pruebas previstas: un anticipo en varias finales, agotamiento exacto, exceso,
concurrencia de dos usuarios, idempotencia y rollback, sin alterar VERI*FACTU.
Decisión confirmada: impuestos especiales fuera del alcance inicial; se
incorporarán si un cliente lo necesita. No añadir ahora captura ni reglas de
cálculo para alcohol, tabaco, electricidad u otros impuestos especiales.
Esta decisión no elimina IVA/IGIC/IPSI ni los suplidos ya incluidos, ni se
extiende automáticamente a cualquier tasa o cargo de naturaleza distinta.
Los términos de L9 se conservan en el mapeo completo para documentar el
contrato, distinguiendo los supuestos aplazados de los no confirmados.

Decisión confirmada por el usuario: **la Orden publicada en el BOE es la
referencia prioritaria** frente a anexos/ejemplos técnicos AEAT discrepantes.
Registrar las diferencias, sin modificar las fuentes ni mezclar versiones
silenciosamente. La compatibilidad con el servicio en PRE se comprobará
únicamente en Fase 4, cuando el usuario lo indique. La Fase 2 usará el valor
BOE en el contrato del generador y documentará divergencias esperadas frente
a los ejemplos. Superar XSD o reproducir un ejemplo no acredita por sí solo
conformidad con la Orden ni aceptación PRE.

Se inicia el registro de diferencias en
[BOE frente a AEAT](../../doc/spfe/help/DIFERENCIAS_BOE_AEAT.md).
Falta completar la comparación íntegra de ambos anexos antes de cerrar el
contrato de generación; el mapeo base sigue trazando las filas del anexo
técnico inicial y no debe presentarse como cotejo completo con el BOE.

Decisión confirmada: una factura puede agrupar y sustituir varios tickets/
facturas simplificadas del mismo cliente, conservando sus referencias
originales e impidiendo facturar dos veces un ticket. El código actual solo
acredita sustitución de un ticket (UniDataFacturacionTicketRepositorio.pas),
con relación SUSTITUYE. BG-3 debe ser una colección de número original BT-25
y fecha BT-26, con identidad del emisor y trazabilidad de los documentos
sustituidos. Preservar importes e impuestos originales y los cobros existentes;
la conversión no debe duplicar venta, cobro ni movimiento de existencias.

La clave UQ_FACREL_FACTURA_TIPO permite un solo origen por tipo en la factura
destino. No resuelve varias referencias ni impide por sí sola que un origen
aparezca en varias facturas destino. Se requiere diseño adicional de relación
múltiple y control de sustitución por origen, a concretar en migración SQL
revisable de Fase 3. No retirar la clave existente ni alterar las lecturas de
VERI*FACTU como atajo. Revisar compatibilidad de la nueva operación agrupada
con la emisión fiscal existente, respetando la prohibición de modificar su
módulo y cadena; no se considera ya resuelto ese enganche.

Validar misma empresa emisora y mismo cliente verificado; no inferir cliente
idéntico solo porque varios tickets tengan cliente genérico. Comprobar que
cada origen es elegible y no está ya sustituido, bloquear los orígenes por
clave en orden estable y guardar factura/vínculos/consumo de orígenes en una
transacción coherente. Usar clave de idempotencia para reintentos; no reservar
un ticket de nuevo por regenerar el XML o reintentar envío SPFE. El control
debe cubrir todos los caminos de facturación de tickets, incluidos los
existentes; una tabla lateral aislada no garantiza impedir duplicados.
No liberar automáticamente el origen por rechazo técnico SPFE. Correcciones
posteriores requerirán flujo documentado que conserve historia.
Pruebas previstas: varios tickets, referencia completa de cada uno, repetido
en la misma selección, ya sustituido, cliente distinto/genérico, concurrencia,
reintentos y rollback. Generación UBL sin red desde la colección de referencias;
no implementar la nueva operación de gestión durante la Fase 1 ni la Fase 2.
Ampliación solicitada y aclarada por el usuario: **una rectificativa podrá
rectificar varias facturas del mismo cliente, pero la aplicación actual no
permite ese movimiento**. Es requisito nuevo; no se presentará como función
ya existente ni como algo que el repositorio actual pueda leer sin cambios.
Conservar identidad original de cada factura y un detalle de los importes
rectificados de cada una (base, impuesto/tipo/cuota, recargo cuando proceda,
moneda y naturaleza del ajuste), con vínculo a la rectificativa y conciliación
de totales. Diferenciar importe original del importe efectivamente rectificado.
No elegir solo la última factura relacionada ni repartir un total agregado
sin evidencia del detalle por origen.

BG-3 será colección en el contrato de entrada del generador sin red. El
desglose por factura origen se conserva en el dominio y la instantánea local;
solo se transmitirá por campos y cardinalidades documentados en el BOE.
No inventar extensiones XML para adjuntar importes por origen si el contrato
solo define agregados, ni confundir importes rectificados con pagos parciales.
La representación exacta y su agregación quedan pendientes del cotejo completo
con el BOE y las reglas semánticas aplicables.

Implementar la creación/gestión de esta rectificativa requiere diseño de
relaciones múltiples, detalle económico, validaciones y migración revisable
posteriores a Fase 1. El generador de Fase 2 podrá probarla con entradas
propias tipadas, sin introducirla en la emisión real de la aplicación.
Existe un conflicto técnico a resolver antes de activar ese movimiento:
el lector VERI*FACTU actual toma una sola antecesora (ORDER BY ID_FACREL DESC
LIMIT 1) y su contrato de construcción contiene una sola referencia de
rectificación. No se modificará ese módulo ni su cadena; falta encontrar
una integración compatible con esa restricción. La aprobación del alcance
funcional no se interpreta como permiso para levantarla.
Pruebas previstas del generador: varias referencias, importes por origen,
sumas por categoría, duplicados en entrada, cliente/empresa distintos y
coherencia I/S, sin describir fixtures derivadas como ejemplos oficiales.

Siguiente duda documental: disponibilidad del modelo semántico UNE-EN
16931:2026 y su correspondencia UBL, o reglas oficiales equivalentes. Los
XSD OASIS y el ejemplo básico no cubren esas reglas; el paquete público
ConnectingEurope localizado declara UBL 2.1 y no acredita por sí solo SPFE.

Revisión de la documentación ampliada, a petición del usuario: releído
ViraCash_web/docs/spfe/README.md y comprobada la carpeta ubl-2.5. Contiene
116 XSD canónicos (101 maindoc y 15 common), todos idénticos por SHA-256 a
la distribución OASIS os-UBL-2.5 descargada. Compilan sin red los esquemas
Invoice, DocumentStatus y ApplicationResponse. El ejemplo factura.xml de
la AEAT valida contra Invoice. Resultado detallado en
[la comprobación local](../../doc/spfe/help/VERIFICACION_UBL_LOCAL_20261112.json).
Este árbol local será la referencia XSD del proyecto; no se han modificado
sus archivos ni importado WSDL. La validación XSD no cubre las reglas
semánticas ni resuelve la discrepancia de ProfileID.


Discrepancia BT-23 resuelta para el contrato por prioridad documental:
usar `urn:aeat:names:specification:ubl:schema:profile:B2B` del BOE.
El anexo técnico y el ejemplo AEAT omiten `:ubl:`; se conserva ese hecho en
el registro de diferencias. Pendiente la comprobación del servicio en PRE
en Fase 4 y el cotejo completo del resto del anexo.

## Alcance y fuentes

Conexión directa con SPFE, sin papel de plataforma privada, copias fieles ni
firma de la factura, conforme a la decisión del proyecto. La autenticación
con certificado del transporte se estudiará en Fase 4. VERI*FACTU y su cadena
de hash permanecen intactos.

La documentación está en `C:/DISCO_DURO/proyectos/ViraCash_web/docs/spfe/`,
ubicación confirmada por el usuario. Este plan se guarda en el repositorio
activo de la aplicación, `ViraCash`, en la ruta solicitada `docs/spfe/PLAN.md`.
No se han copiado ni alterado los originales.

| Referencia | Archivo en la carpeta documental | Uso |
|---|---|---|
| A1 | [A1-Proyecto-OM-FE.pdf](../../../ViraCash_web/docs/spfe/A1-Proyecto-OM-FE.pdf) | 34 páginas; campos, cardinalidades y listas L1-L10 |
| A2 | [A2-Proyecto-OM-FE.pdf](../../../ViraCash_web/docs/spfe/A2-Proyecto-OM-FE.pdf) | 15 páginas; estados y cancelaciones |
| CAT | [CatalogoServicios.pdf](../../../ViraCash_web/docs/spfe/CatalogoServicios.pdf) | Versión 0.1.3; identificación, servicios y límites |
| FES | [FormatosEntradaSalida.pdf](../../../ViraCash_web/docs/spfe/FormatosEntradaSalida.pdf) | Versión 0.1.2; SOAP, MIME, ebXML y respuesta |
| VAL | [Validaciones_Factura_Electronica.pdf](../../../ViraCash_web/docs/spfe/Validaciones_Factura_Electronica.pdf) | Versión 0.1.0; capas de validación y limitaciones |
| EJ | [factura.xml](../../../ViraCash_web/docs/spfe/factura.xml) | Ejemplo básico Invoice |
| SOAP | [SendInvoicesSOAP.zip](../../../ViraCash_web/docs/spfe/SendInvoicesSOAP.zip) | Invoice básico, sobres y respuesta DocumentStatus |
| WS | [wsdl_xsd_20261029.zip](../../../ViraCash_web/docs/spfe/wsdl_xsd_20261029.zip) | WSDL PRE y esquemas auxiliares; no importados a Delphi |

No se han consultado fuentes externas ni servicios SPFE. Los nombres de los
anexos contienen «Proyecto» y FES conserva referencias a borrador. El conjunto
no incluye el texto íntegro de la Orden HAC/1028/2026: no permite confirmar
su concordancia final ni deducir plazos de entrada en vigor. Se toma como
contrato técnico facilitado, con las dudas documentales indicadas al final.

## Código revisado y situación actual

Las rutas siguientes son relativas a la raíz de `ViraCash`:

| Código | Evidencia y consecuencia |
|---|---|
| `src/Lib/inLibFacturasConsolidacion.pas`, `Consolidar` | Coordina validación, emisión fiscal, rectificativa y movimientos dentro de `IUnidadTrabajoFacturas.Ejecutar`. La recepción interna se registra después. Hay un límite transaccional que respetar. |
| `src/verifactu/inLibEmisionFiscal.pas` | Selecciona estrategia fiscal; VERI*FACTU encola con `TVerifactuCola.EncolarFactura`. SPFE no debe sustituir esta estrategia. |
| `src/verifactu/inLibVerifactuConstruccionEnvio.pas` | Construye XML fiscal y huella SHA-256 encadenada. No reutilizar esta huella como identificador SPFE ni modificarla. |
| `src/verifactu/inLibVerifactuEnvio.pas`, `ConfigurarConsultaFactura`, `CargarOperacionFiscal` | Campos de factura, país ISO alpha-2, catálogo fiscal, certificado y formato del número; consulta de antecesoras y bases/cuotas rectificadas. Solo referencia de lectura. |
| `src/verifactu/inLibVerifactu.pas`, `ComponerNumSerieFactura` | Delega en `FormatearDocumento`; el identificador mostrado y enviado fiscalmente depende del formato de empresa. |
| `src/Lib/inLibFormatoDocumento.pas` | Formato por defecto `Serie.NroDocumento`; conserva número como texto. |
| `src/DataModules/UniDataFacturasRecalculoTotales.pas` | SELECT explícitos de cabecera y líneas con nombres normalizados; importes, descuentos, instantánea de emisor y cliente. |
| `src/DataModules/UniDataFacturasRectificativa.pas`, `src/verifactu/UniDataVerifactuColaOperaciones.pas` | Rectificativas por diferencias/sustitución; campos de tipo y relaciones `RECTIFICA`. No basar el nuevo lector exclusivamente en los campos de abono heredados. |
| `src/DataModules/UniDataFacturaeRepositorio.pas`, `src/Lib/inLibFacturae.pas` | Exportación Facturae independiente, con firma y `XML_FAC`; no es generador UBL. Usa EUR fijo, medio de pago Facturae y vencimiento igual a fecha de factura: no trasladar estos supuestos a SPFE. |
| `src/Lib/inLibFacturasEfectos.pas`, `src/DataModules/UniDataFacturasOperaciones.pas`, `src/DataModules/UniDataEfectosVenta.pas` | Efectos, vencimientos, cobros e importes parciales existentes. No equivalen automáticamente a un evento SPFE de pago/cobro completo. |
| `src/Forms/inMtoFacturasCobrosVcl.pas`, `src/Forms/inMtoFacturasCompraPagosVcl.pas` | Adaptadores de UI de cobros/pagos aprovechables como referencia de composición. |

El modelo antiguo `src/utilnormbbdd/factuzam_original.sql` queda sustituido
como referencia estructural por el esquema localizado en
`C:/DISCO_DURO/proyectos/ViraCash_web/viracash_web.sql`, indicado por el usuario.
La cabecera declara backup del 12-11-2026 a las 19:34:58. Contiene también
INSERT, que no se han ejecutado ni copiado al material de ayuda. Se han
extraído exclusivamente columnas, tipos, claves e índices de 16 tablas en
[el inventario de esquema](../../doc/spfe/help/ESQUEMA_VERIFICADO_20261112.json),
con SHA-256 del fichero fuente. No se ha modificado el SQL original.

Se confirman los nombres normalizados de factura, líneas, efectos,
consolidaciones, relaciones, unidades, medios de pago y retenciones usados
en la matriz. Esto acredita el contenido de esta copia; no verifica el
esquema de todas las instalaciones ni la integridad de los datos históricos.
Los FALTA siguen pendientes salvo corrección explícita en este seguimiento.

Hallazgos que concretan los orígenes del generador:

| Necesidad | Origen confirmado en el esquema | Límite pendiente |
|---|---|---|
| Pagos de ventas | `fza_facturas_pagos`: `FECHA_FACPAG`, `IMPORTE_FACPAG`, `TIPO_FACPAG`, clave serie/número/línea | Candidato para pagos a fecha de emisión; falta contrastar su relación con caja y efectos para no duplicar cobros |
| Pagos de compras | `fza_efectos_compra_pagos`: `FECHA_EFECPAG`, `IMPORTE_EFECPAG`, `CODIGO_FP_EFECPAG`; clave factura/efecto/pago | No equivalen automáticamente a anticipos BT-113 ni prueban clasificación fiscal |
| Vencimientos | `fza_efectos_venta.FECHA_VENCIMIENTO_EFV`, `fza_efectos_compra.FECHA_VENCIMIENTO_EFEC` y recibos | Conservar plazos reales; falta resolver la representación de varios plazos y su fecha de cabecera |
| Condición de pago | `fza_recibos.FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC` conserva descripción de origen; catálogo `DESCRIPCION_FORMA_PAGO_FP` | Comprobar que el recibo existe y corresponde a la versión de condiciones de esa factura; no sustituirlo por la ficha actual |
| Cuenta receptora | `fza_efectos_venta.IBAN_EMP_EFV`, `fza_recibos.IBAN_EMP_REC` | Distinguirlos de IBAN del cliente y comprobar el pago al que aplican |
| Documentos históricos | `fza_facturas.PDF_FAC` y metadatos; `fza_facturas_consolidaciones.REGISTRO_XML_FACCON`, `REGISTRO_XML_ORIGINAL_FACCON`, peticiones y URL QR | Candidatos de evidencia para recuperar identidad; el esquema no garantiza que estén poblados o correspondan a la emisión inicial |
| Varias retenciones | Cabeceras FAC/FACC conservan un porcentaje y un total; catálogo de empresa independiente | Falta detalle por factura: concepto, base, porcentaje y cuota |
| Suplidos | No se ha localizado detalle específico en las tablas revisadas | Captura/persistencia nueva pendiente; no inferirlos de una descripción libre |
| Unidades oficiales | Catálogo `fza_unidades_medida` sin campo de equivalencia UNECE en su definición | Añadir correspondencia separada y conservar unidad física de la línea |

Para autofacturas se confirma `fza_facturas_compra` y su detalle
`fza_facturas_compra_lineas`. Vendedor: campos de proveedor `*_PRV_FACC`;
comprador: campos de empresa `*_EMPRESA_FACC`. Fecha `FECHA_FACC`, identidad
interna `SERIE_FACC`/`NUMERO_FACC`, líneas con `LINEA_FACCLIN`,
`CANTIDAD_FACCLIN`, `TIPO_CANTIDAD_ARTICULO_FACCLIN`,
`DESCRIPCION_ARTICULO_FACCLIN` y `PRECIO_COMPRA_SIVA_ARTICULO_FACCLIN`.
Existen bandas impositivas, descuentos y agregados de retención en FACC.
Faltan cerrar identidad externa de cada modalidad, tratamiento de
rectificativas de compra y correspondencias fiscales; no basta cambiar
sufijos FAC por FACC para obtener un mapeo semántico completo.

## Mapeo completo del Anexo I

Leyenda: **DATO** = origen localizado en código; **ADAPTAR** = existe un
candidato pero exige transformación o decisión; **FIJO** = valor documental;
**FALTA** = no se ha localizado origen equivalente en el flujo revisado.
FALTA no afirma ausencia física en todas las instalaciones. Un campo opcional
solo puede omitirse si no concurre su condición de obligatoriedad.

Abreviaturas: `F` = `fza_facturas`; `L` = `fza_facturas_lineas`;
`C` = `fza_facturas_consolidaciones`; `E` = `fza_efectos_venta`;
`V` = `fza_verifactu_operaciones`; `P` = `fza_paises`.
Las cardinalidades son las de A1 dentro del grupo padre.
Los identificadores repetidos se desglosan por contexto, como en el anexo.

### Identificación, fechas, notas y referencias (A1, páginas 4-6)

| ID | Cardinalidad | Campo | Origen actual / tratamiento | Estado |
|---|---|---|---|---|
| BT-1 | 1..1 | Serie y número | `F.SERIE_FAC`, `F.NUMERO_FAC`; formato del documento emitido, véase código único | ADAPTAR |
| BT-ES-1 | 0..1 | Copia | `false` u omisión para original | FIJO |
| BT-2 | 1..1 | Fecha expedición | `F.FECHA_FAC`, serializar `yyyy-mm-dd` | DATO |
| BT-166 | 0..1 | Hora expedición | No equiparar automáticamente al instante de consolidación | FALTA |
| BT-3 | 1..1 | Tipo factura | `F.TIPO_FAC`, `F.TIPO_FACTURA_VERIFACTU_FAC` y relaciones; convertir a L1: 380/384/388/389/471 | ADAPTAR |
| BT-5 | 1..1 | Moneda | EUR; confirmado por el usuario para todas las facturas, incluidas rectificativas | FIJO confirmado |
| BT-6 | 0..1 | Moneda contable IVA | No se requiere moneda contable distinta: todas las facturas son EUR | NO APLICA por moneda |
| BT-167 | 0..1 | Tipo cambio IVA | No se requiere conversión: todas las facturas son EUR | NO APLICA |
| BT-7 | 0..1 | Fecha operación | `L.FECHA_ENTREGA_FACLIN` como candidato; varias fechas no determinan una fecha de cabecera | ADAPTAR |
| BT-9 | 0..1 | Vencimiento pago | `E.FECHA_VENCIMIENTO_EFV`; conservar versión documental, separada de creación/modificación y reagrupación posterior. Pendiente regla de múltiples plazos | ADAPTAR |
| BT-ES-2 | 0..1 | Fecha efectiva pago | `E.FECHA_COBRO_EFV` como candidato; exige pago previo/en fecha de emisión y coherencia con fecha operación | ADAPTAR |
| BT-10 | 0..n | Referencia comprador | No confundir con código interno de cliente | FALTA |
| BT-21 | 0..1 | Código nota | `REG` para las menciones legales; el usuario confirma ese carácter para COMENTARIOS_FAC | FIJO para notas legales |
| BT-22 | 1..1 | Texto nota | `F.TEXTO_LEGAL_EMPRESA_FAC`, `F.TEXTO_LEGAL_CLIENTE_FAC`, `F.COMENTARIOS_FAC`; comentarios legales impresos para el cliente, autorizados para incluir en XML | DATO; inclusión confirmada |
| BT-23 | 1..1 | Proceso negocio | `urn:aeat:names:specification:ubl:schema:profile:B2B`; prevalece BOE, divergencia del ejemplo documentada | FIJO según BOE |
| BT-24 | 1..1 | Especificación | `urn:cen.eu:en16931:2026#conformant#urn:aeat.es:spfe:1.0.0:extended` | FIJO |
| BT-25 | 1..1 | Número factura anterior | Número original congelado por cada referencia. Sustitución de varios tickets incluida; FACREL actual solo permite un origen por tipo/destino y requiere diseño adicional | ADAPTAR; colección requerida |
| BT-26 | 1..1 | Fecha factura anterior | `F.FECHA_FAC` de la factura origen | DATO |

### Vendedor, comprador y terceros (A1, páginas 6-11)

| ID | Cardinalidad | Campo | Origen actual / tratamiento | Estado |
|---|---|---|---|---|
| BT-27 | 1..1 | Nombre vendedor | `F.RAZON_SOCIAL_EMPRESA_FAC` | DATO |
| BT-31 | 0..1 | NIF-IVA vendedor | `F.NIF_EMPRESA_FAC`; distinguir identificación VAT válida y prefijo ES | ADAPTAR |
| BT-32 | 0..1 | NIF vendedor | `F.NIF_EMPRESA_FAC`; rama LOC con `schemeID=FC`; obligatorio si no BT-31 | ADAPTAR |
| BT-30 | 0..1 | Inscripción legal vendedor | Mismo NIF de la instantánea; obligatorio cuando se informa BT-32 | ADAPTAR |
| BT-33 | 0..1 | Información jurídica | `F.TEXTO_LEGAL_EMPRESA_FAC` candidato; no confundir cláusulas comerciales con datos jurídicos | ADAPTAR |
| BT-35 | 1..1 | Dirección vendedor | `F.DIRECCION1_EMPRESA_FAC`, `DIRECCION2_EMPRESA_FAC`; conservar detalle postal | ADAPTAR |
| BT-37 | 0..1 | Municipio vendedor | `F.POBLACION_EMPRESA_FAC`; obligatorio en España | DATO |
| BT-38 | 0..1 | CP vendedor | `F.CODIGO_POSTAL_EMPRESA_FAC`; obligatorio en España | DATO |
| BT-39 | 0..1 | Provincia vendedor | `F.PROVINCIA_EMPRESA_FAC`; obligatorio en España | DATO |
| BT-40 | 1..1 | País vendedor | `F.CODIGO_PAI_EMPRESA_FAC` → `P.COD_ALPHA2_PAI`; el código interno puede ser numérico | ADAPTAR |
| BT-42 | 0..1 | Teléfono vendedor | `F.MOVIL_EMPRESA_FAC` | DATO |
| BT-43 | 0..1 | Email vendedor | `F.EMAIL_EMPRESA_FAC` | DATO |
| BT-44 | 1..1 | Nombre comprador | `F.RAZON_SOCIAL_CLIENTE_FAC` | DATO |
| BT-47 | 0..1 | NIF comprador | `F.NIF_CLIENTE_FAC`; LOC/FC, obligatorio si no BT-48 | ADAPTAR |
| BT-48 | 0..1 | NIF-IVA comprador | `F.NIF_CLIENTE_FAC`; VAT y prefijo según A1; no anteponer ES sin identificar el caso | ADAPTAR |
| BT-50 | 1..1 | Dirección comprador | `F.DIRECCION1_CLIENTE_FAC`, `DIRECCION2_CLIENTE_FAC` | ADAPTAR |
| BT-52 | 0..1 | Municipio comprador | `F.POBLACION_CLIENTE_FAC`; obligatorio en España | DATO |
| BT-53 | 0..1 | CP comprador | `F.CODIGO_POSTAL_CLIENTE_FAC`; obligatorio en España | DATO |
| BT-54 | 0..1 | Provincia comprador | `F.PROVINCIA_CLIENTE_FAC`; obligatorio en España | DATO |
| BT-55 | 1..1 | País comprador | `F.CODIGO_PAI_CLIENTE_FAC` → `P.COD_ALPHA2_PAI` | ADAPTAR |
| BT-57 | 0..1 | Teléfono comprador | `F.MOVIL_CLIENTE_FAC` | DATO |
| BT-58 | 0..1 | Email comprador | `F.EMAIL_CLIENTE_FAC` | DATO |
| BT-ES-3 | 1..1 | Nombre tercero | Facturación por terceros incluida; falta captura e instantánea del nombre/razón social del tercero expedidor | FALTA; requerido por alcance |
| BT-ES-4 | 1..1 | NIF tercero | Facturación por terceros incluida; falta captura e instantánea de su identificación fiscal | FALTA; requerido por alcance |
| BT-ES-5 | 1..1 | Tipología tercero | `FacturaciónPorTercero` para el tercero expedidor; supuesto incluido, falta representación en datos | FIJO condicional; captura pendiente |

La dirección, nombre y NIF deben salir de la instantánea de la factura emitida,
no de una ficha de cliente/empresa modificada después. El catálogo de países
sirve para traducir códigos, no para sustituir la instantánea postal.

### Periodo, minoraciones, cargos e impuestos adicionales (A1, páginas 11-14)

| ID | Cardinalidad | Campo | Origen actual / tratamiento | Estado |
|---|---|---|---|---|
| BT-73 | 0..1 | Inicio recapitulativa | No hay periodo explícito identificado; no deducirlo del primer albarán sin regla aprobada | FALTA |
| BT-74 | 0..1 | Fin recapitulativa | Igual; la selección de albaranes no prueba por sí sola el periodo fiscal | FALTA |
| BT-92 | 1..1 | Minoración documento | `F.TOTAL_DTO_COMERCIAL_FAC`, `TOTAL_DTO_FINANCIERO_FAC`; falta reparto por categoría/tipo | ADAPTAR |
| BT-95 | 1..1 | Categoría minoración | No hay categoría UBL L4 por descuento localizada | FALTA |
| BT-96 | 0..1 | Tipo IVA minoración | Bandas de IVA de `F`; falta asignación a cada minoración | ADAPTAR |
| BT-97 | 1..1 | Razón minoración | Comercial/financiera como candidatos; confirmar textos y semántica | ADAPTAR |
| BT-99 | 1..1 | Cargo documento | No hay origen específico; los portes se registran como líneas y no se trasladan a este campo | FALTA para otros cargos; no requerido para portes |
| BT-102 | 1..1 | Categoría IVA cargo | No identificada | FALTA |
| BT-103 | 0..1 | Tipo IVA cargo | No identificado | FALTA |
| BT-104 | 1..1 | Razón cargo | No identificada | FALTA |
| BT-ES-6 | 0..1 | Base impuesto/tasa documento | No identificada | FALTA |
| BT-ES-7 | 0..1 | Tipo impuesto/tasa documento | No identificado | FALTA |
| BT-ES-8 | 1..1 | Cuota impuesto/tasa documento | No identificada; A1 exige el importe tanto en TaxTotal como en TaxSubtotal | FALTA |
| BT-ES-9 | 1..1 | Código impuesto/tasa documento | L9 sin equivalencia localizada; impuestos especiales aplazados por el usuario. Otros cargos/tasas no confirmados | FUERA para especiales; FALTA para otros supuestos |

### Totales, terceros y retenciones (A1, páginas 14-18)

| ID / contexto | Cardinalidad | Campo | Origen actual / tratamiento | Estado |
|---|---|---|---|---|
| BT-106 | 1..1 | Neto líneas | Suma acotada de `L.TOTAL_FAC_SIVA_FACLIN`; contrastar descuentos | ADAPTAR |
| BT-107 | 0..1 | Total minoraciones | `F.TOTAL_DTO_COMERCIAL_FAC` + `TOTAL_DTO_FINANCIERO_FAC`, si corresponden a BG-20 | ADAPTAR |
| BT-108 | 0..1 | Total cargos | Sin detalle de cargos identificado | FALTA |
| BT-109 | 1..1 | Total sin IVA | `F.TOTAL_BASES_FAC` candidato; contrastar con BT-106/107/108 | ADAPTAR |
| BT-110 | 1..1 | IVA total | Suma `F.TOTAL_IVAN_FAC`, `TOTAL_IVAR_FAC`, `TOTAL_IVAS_FAC`, `TOTAL_IVAE_FAC`; revisar inclusión de RE con desglose UBL | ADAPTAR |
| BT-111 | 0..1 | IVA en EUR | No se requiere importe adicional por conversión: todas las facturas son EUR | NO APLICA por moneda |
| BT-112 | 1..1 | Total con IVA | `F.TOTAL_BASES_FAC` + `TOTAL_IMPUESTOS_FAC` candidato; no descontar retención en este campo | ADAPTAR |
| BT-113 | 0..1 | Importe anticipado | Pagos previos/parciales incluidos; falta distinguir los supuestos admisibles de los anticipos con devengo excluidos por A1 | FALTA; clasificación pendiente |
| BT-114 | 0..1 | Redondeo | No hay ajuste explícito identificado; no introducir tolerancia arbitraria | FALTA |
| BT-115 | 1..1 | Total a pagar | Pagos totales/parciales al emitir confirmados. Conciliar total documental, pagos admisibles, BT-114 y BT-179; saldo cero si totalmente pagada. No copiar TOTAL_LIQUIDO_FAC sin conciliación | ADAPTAR |
| BT-179 / suplido | 1..1 | Importe a favor tercero | Suplidos incluidos en el alcance inicial; falta captura/origen del importe | FALTA; requerido por alcance |
| BT-180 / suplido | 1..1 | Descripción suplido | Suplidos incluidos en el alcance inicial; falta captura/origen de descripción | FALTA; requerido por alcance |
| BT-ES-10 | 1..1 | Código suplido | `SUPL`, si existe el concepto | FIJO condicional |
| BT-179 / impuestos tercero | 1..1 | Cuotas impuesto/tasa | No identificadas | FALTA |
| BT-180 / impuestos tercero | 1..1 | Denominación impuesto/tasa | No identificada | FALTA |
| BT-ES-11 | 1..1 | Identificación impuesto/tasa | `IEDMT` u `OTROS`, según concepto sin origen localizado | ADAPTAR |
| BT-ES-12 | 0..1 | Base impuesto/tasa tercero | No identificada | FALTA |
| BT-ES-13 | 0..1 | Tipo impuesto/tasa tercero | No identificado | FALTA |
| BT-ES-14 | 1..1 | Cuota impuesto/tasa tercero | No identificada | FALTA |
| BT-179 / minoración tercero | 1..1 | Importe minoración | No identificado | FALTA |
| BT-180 / minoración tercero | 1..1 | Descripción minoración | No identificada | FALTA |
| BT-ES-15 | 1..1 | Código minoración tercero | `MINO`, si existe el concepto | FIJO condicional |
| BT-179 / retenciones | 1..1 | Suma retenciones | `F.TOTAL_RETENCION_FAC`; representación en CollectionInvoiceLine | ADAPTAR |
| BT-180 / retenciones | 1..1 | Descripción retención | Falta texto/concepto inequívoco en factura | FALTA |
| BT-ES-16 | 1..1 | Identificación retención | `RETE` | FIJO condicional |
| BT-ES-17 | 1..1 | Suma retenciones | `F.TOTAL_RETENCION_FAC`; además en WithholdingTaxTotal | DATO |
| BT-ES-18 | 1..1 | Base retención | Motor fiscal y `F.ESIRPF_IMP_INCL_ZONA_IVA_FAC`; no usar siempre TOTAL_BASES como hace Facturae | ADAPTAR |
| BT-ES-19 | 1..1 | Cuota retención | `F.TOTAL_RETENCION_FAC`; actual factura presenta un agregado | ADAPTAR |
| BT-ES-20 | 1..1 | Porcentaje retención | `F.PORCENTAJE_RETENCION_FAC` sirve para una retención; múltiples requieren porcentaje en cada detalle | ADAPTAR; detalle requerido |
| BT-ES-21 | 1..1 | Concepto retención | Existe catálogo de empresa `fza_empresas_retenciones.CODIGO_RETENCION_EMPRET`; falta correspondencia L5 e instantánea por factura | ADAPTAR |

Los importes de SPFE deben cuadrar con los datos emitidos. No reutilizar la
tolerancia de 0,05 del validador Facturae como regla SPFE: no figura como tal
en la documentación facilitada. No convertir importes a texto con la
configuración regional del equipo ni usar recálculos históricos globales.

### Líneas y desglose tributario (A1, páginas 18-23)

| ID / contexto | Cardinalidad | Campo | Origen actual / tratamiento | Estado |
|---|---|---|---|---|
| BT-126 | 1..1 | ID línea | `L.LINEA_FACLIN`; conservar texto y unicidad dentro de factura | DATO |
| BT-129 | 1..1 | Cantidad | `L.CANTIDAD_FACLIN` | DATO |
| BT-130 | 1..1 | Unidad medida | `L.TIPO_CANTIDAD_ARTICULO_FACLIN` → `fza_unidades_medida.CODIGO_UNIMED`; falta correspondencia UNECE 20/21. Admitir todas las medidas; `CODIGO_UNIDAD_FACLIN` es SKU | ADAPTAR |
| BT-131 | 1..1 | Neto línea | `L.TOTAL_FAC_SIVA_FACLIN`; contrastar con precio, cantidad y descuentos | ADAPTAR |
| BT-136 | 1..1 | Minoración línea | `L.PRECIO_DTO_FACLIN`, `PORCENTAJE_DTO_FACLIN`, cantidad; confirmar importe neto total frente a unitario | ADAPTAR |
| BT-139 | 1..1 | Razón minoración línea | No hay razón explícita localizada | FALTA |
| BT-141 | 1..1 | Cargo línea | No identificado | FALTA |
| BT-142 | 0..1 | Base cargo línea | No identificada | FALTA |
| BT-143 | 0..1 | Porcentaje cargo línea | No identificado | FALTA |
| BT-ES-22 | 1..1 | Impuesto cargo línea | L9 sin equivalencia localizada; impuestos especiales fuera del alcance inicial. No confundir con portes ordinarios como línea | FUERA para especiales; FALTA para otros supuestos |
| BT-144 | 1..1 | Razón cargo línea | No identificada | FALTA |
| BT-146 | 1..1 | Precio neto | `L.PRECIO_VENTA_SIVA_ARTICULO_FACLIN` candidato; evitar descontar dos veces | ADAPTAR |
| BT-149 | 0..1 | Cantidad precio base | No hay denominador explícito localizado; confirmar si todos los precios son unitarios | FALTA |
| BT-151 | 1..1 | Categoría IVA línea | `L.TIPO_IVA_ARTICULO_FACLIN`, operación fiscal de F y catálogo V; falta correspondencia L4 por línea | ADAPTAR |
| BT-152 | 0..1 | Tipo IVA línea | `L.PORCENTAJE_IVA_FACLIN` | DATO |
| BT-195 | 0..1 | Exención línea | `V.OPERACION_EXENTA_VFO` candidato; códigos VERI*FACTU no equivalen a VATEX | ADAPTAR |
| BT-153 | 1..1 | Nombre artículo | `L.DESCRIPCION_ARTICULO_FACLIN` | DATO |
| BT-154 | 0..1 | Descripción ampliada | DESCRIPCION_PRINT_FACLIN no es columna física del esquema. `L.DESCRIPCION_VARIACION_FACLIN` es otro dato disponible, pendiente de adecuación semántica | ADAPTAR; origen revisado |
| BT-160 / información | 1..1 | Tipo propiedad | Calificador L8 + `INFO` | FIJO condicional |
| BT-161 / información | 1..1 | Información adicional | Sin colección de propiedades fiscales por línea localizada | FALTA |
| BT-160 / inmueble | 1..1 | Tipo propiedad | Calificador L8 + `RCAT`; inmuebles aplazados por el usuario | FUERA DE ALCANCE INICIAL |
| BT-161 / inmueble | 1..1 | Referencia catastral | Sin origen; ampliación solo si se solicita | FUERA DE ALCANCE INICIAL |
| BT-ES-23 | 1..1 | Situación inmueble | Lista L6; sin captura prevista en primera versión | FUERA DE ALCANCE INICIAL |
| BT-160 / régimen | 1..1 | Tipo propiedad | `urn:aeat:names:specification:schema:lin:REGI`, como EJ | FIJO |
| BT-161 / régimen | 1..1 | Clave régimen | `F.TIPO_OPER_VFACTU_FAC` → `V.CLAVE_REGIMEN_VFO`; candidato, verificar L3A/B/C y hasta dos claves por línea | ADAPTAR |
| BT-ES-24 | 1..1 | Impuesto nacional | Zona y operación fiscal como candidatos; falta instantánea explícita IVA/IGIC/IPSI por línea | ADAPTAR |
| BT-116 | 1..1 | Base por categoría | `F.TOTAL_BASEI_IVAN_FAC`, `TOTAL_BASEI_IVAR_FAC`, `TOTAL_BASEI_IVAS_FAC`, `TOTAL_BASEI_IVAE_FAC`; insuficiente si una banda mezcla categorías/exenciones | ADAPTAR |
| BT-117 | 1..1 | Cuota por categoría | `F.TOTAL_IVAN_FAC`, `TOTAL_IVAR_FAC`, `TOTAL_IVAS_FAC`, `TOTAL_IVAE_FAC`; RE en `TOTAL_REN_FAC`, `TOTAL_RER_FAC`, `TOTAL_RES_FAC`, `TOTAL_REE_FAC` | ADAPTAR |
| BT-118 | 1..1 | Categoría tributaria | Mapeo L4; RE requiere tratamiento propio, no sumar a IVA indiscriminadamente | ADAPTAR |
| BT-119 | 1..1 | Tipo por categoría | `F.PORCENTAJE_IVAN_FAC`, `PORCENTAJE_IVAR_FAC`, `PORCENTAJE_IVAS_FAC`, `PORCENTAJE_IVAE_FAC`; RE en `PORCENTAJE_REN_FAC`, `PORCENTAJE_RER_FAC`, `PORCENTAJE_RES_FAC`, `PORCENTAJE_REE_FAC` | ADAPTAR |
| BT-120 | 0..1 | Razón exención | Sin texto fiscal inequívoco por desglose localizado | FALTA |
| BT-121 | 0..1 | Código exención | `V.OPERACION_EXENTA_VFO` candidato; falta correspondencia VATEX-EU/VATEX-ES | ADAPTAR |

### Pago, QR, autorizaciones y rectificación (A1, páginas 23-26)

| ID / contexto | Cardinalidad | Campo | Origen actual / tratamiento | Estado |
|---|---|---|---|---|
| BT-20 | 0..1 | Condiciones pago | `F.FORMA_PAGO_FAC`; descripción de origen candidata en `fza_recibos.FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC`, si existe y corresponde a la emisión | ADAPTAR |
| BT-81 | 1..1 | Medio pago | Falta equivalencia UNTDID 4461; `fza_formas_pago.CODIGO_FACTURAE_FP` no es este catálogo | ADAPTAR |
| BT-84 | 1..1 | Cuenta pago | Candidatos confirmados `E.IBAN_EMP_EFV` y `fza_recibos.IBAN_EMP_REC`; elegir cuenta receptora histórica y congelarla, sin sustituir por la actual de empresa | ADAPTAR |
| BT-122 / QR | 1..1 | ID documento | `urn:aeat:names:specification:schema:QR`, calificador L10 + valor QR como EJ | FIJO condicional |
| BT-123 / QR | 0..1 | Tipo QR | `VERIFACTU` en este flujo, si corresponde | FIJO condicional |
| BT-ES-25 | 1..1 | URL QR | `C.VERIFACTU_URL_FACCON`, lectura de la URL ya emitida; no recalcular hash ni regenerar registro fiscal | DATO |
| BT-122 / autorización | 1..1 | ID documento | Calificador L10 + `AUT` | FIJO condicional |
| BT-123 / autorización | 0..1 | Descripción autorización | No identificada | FALTA |
| BT-ES-26 | 1..1 | Referencia autorización | No identificada | FALTA |
| BT-122 / tipo rectificativa | 1..1 | ID documento | Calificador L10 + `RECT:TIPO` | FIJO condicional |
| BT-123 / tipo rectificativa | 0..1 | Descripción tipo | Derivar de clasificación R1-R4 validada, sin interpretar comentarios | ADAPTAR |
| BT-ES-27 | 1..1 | Tipo R1-R4 | `F.TIPO_FACTURA_VERIFACTU_FAC` candidato; R5 no aparece en L2.A | ADAPTAR |
| BT-122 / modalidad | 1..1 | ID documento | Calificador L10 + `RECT:MODALIDAD` | FIJO condicional |
| BT-123 / modalidad | 0..1 | Descripción modalidad | Derivar de modalidad validada | ADAPTAR |
| BT-ES-28 | 1..1 | Modalidad I/S | `F.TIPO_RECTIFICATIVA_FAC`; comprobar valores efectivos, no confundir con R1-R4 | ADAPTAR |
| BT-122 / importes rectificados | 1..1 | ID documento | Calificador L10 + `RECT:IMPORTES` | FIJO condicional |
| BT-123 / importes rectificados | 1..1 | Importe rectificado | Factura origen de `fza_facturas_relaciones`: base, suma cuotas IVA y suma cuotas RE; conservar valores originales | ADAPTAR |
| BT-ES-29 | 1..1 | Naturaleza importe | `Base`, `Cuota`, `CuotaRecargo` según L2.C; hasta tres documentos justificativos | FIJO condicional |

### Grupos del Anexo I y cobertura estructural

Los grupos son contenedores, no columnas adicionales. Esta tabla incluye sus
repeticiones semánticas y conecta cada uno con el mapeo anterior.

| Grupo | Cardinalidad | Origen / cobertura |
|---|---|---|
| BG-1 notas | 0..n | Textos legales/comentarios F, clasificación pendiente |
| BG-2 control proceso | 1..1 | BT-23/24 fijos |
| BG-3 factura anterior | 0..n | Relaciones y lectura puntual de factura origen |
| BG-4 vendedor | 1..1 | Instantánea de F |
| BG-5 dirección vendedor | 1..1 | Instantánea postal de F |
| BG-6 contacto vendedor | 0..1 | F |
| BG-7 comprador | 1..1 | Instantánea de F |
| BG-8 dirección comprador | 1..1 | Instantánea postal de F |
| BG-9 contacto comprador | 0..1 | F |
| BG-ES-1 tercero | 0..n | Incluido por el usuario; FALTA captura y persistencia de terceros expedidores |
| BG-14 recapitulativa | 0..1 | FALTA periodo explícito |
| BG-20 minoraciones documento | 0..n | Descuentos F; ADAPTAR reparto |
| BG-21 cargos documento | 0..n | FALTA detalle para otros cargos; portes confirmados como líneas BG-25, sin cargo de cabecera |
| BG-ES-2 impuestos/tasas documento | 0..1 | FALTA detalle |
| BG-22 totales | 1..1 | F y líneas acotadas; ADAPTAR conciliación |
| BG-34 suplidos | 0..n | Incluido por el usuario; FALTA captura y persistencia de importe/descripción |
| BG-34 impuestos/tasas de tercero | 0..n | FALTA |
| BG-ES-3 desglose de esos impuestos | 0..n | FALTA |
| BG-34 minoraciones de tercero | 0..n | FALTA |
| BG-34 retenciones | 0..1 | F; ADAPTAR concepto y detalle |
| BG-ES-4 retención aplicada | 0..n | Múltiples retenciones incluidas por el usuario; FALTA detalle de concepto/base/porcentaje/cuota |
| BG-25 líneas | 1..n | L |
| BG-27 minoraciones línea | 0..n | L; ADAPTAR importe y motivo |
| BG-28 cargos línea | 0..n | FALTA |
| BG-29 precio | 1..1 | L; ADAPTAR semántica del neto |
| BG-30 IVA línea | 1..1 | L + operación fiscal; ADAPTAR códigos |
| BG-31 artículo | 1..1 | Instantánea de descripción en L |
| BG-32 información adicional | 0..n | FALTA colección |
| BG-32 referencia catastral | 0..1 | Fuera del alcance inicial; ampliación futura solicitada por cliente |
| BG-32 régimen | 1..2 | Catálogo V candidato; ADAPTAR por línea |
| BG-23 desglose IVA/RE | 1..n | Bandas F y detalle L; ADAPTAR categorías |
| BG-33 condiciones pago | 0..n | Forma pago y vencimientos; ADAPTAR |
| BG-16 instrucciones pago | 0..1 | Medio pago; FALTA equivalencia UBL |
| BG-17 transferencia | 0..n | Cuenta receptora pendiente de congelar |
| BG-24 QR | 0..1 | URL existente en C |
| BG-24 autorización | 0..n | FALTA |
| BG-24 tipo rectificativa | 0..1 | Tipo fiscal candidato; exigido para 384/471 |
| BG-24 modalidad rectificativa | 0..1 | Modalidad candidata; exigida para 384/471 |
| BG-24 importes rectificados | 0..3 | Origen; aplicable a sustitución en el supuesto de A1 p.26 |

### Anulación, campos sin ID BT (A1, páginas 26-27)

| Campo | Cardinalidad | Origen / tratamiento |
|---|---|---|
| ResponseCode | Valor del mensaje | `CANCELINVOICE` |
| Fecha anulación | 1..1 | FALTA evento SPFE; registrar fecha de la acción, no sustituir fecha de factura |
| Factura anulada | 1..n | Referencias por identidad documental |
| Número factura | 1..1 por referencia | BT-1 congelado |
| Fecha expedición | 1..1 por referencia | F.FECHA_FAC congelada |
| NIF vendedor | 1..1 por referencia | F.NIF_EMPRESA_FAC congelado |
| Nombre vendedor | 1..1 por referencia | F.RAZON_SOCIAL_EMPRESA_FAC congelada |

La cancelación SPFE no es una rectificativa ni una baja VERI*FACTU automática.
CAT §6.3 limita el supuesto y permite reutilizar la identidad tras cancelar.
El modelo propuesto conserva generaciones y localizadores anteriores.

## Código único: cálculo con nuestros datos

CAT §§6.3-6.6 define la identidad de negocio mediante **NIF emisor + número
serie-factura + fecha de expedición**. Es una terna, no una especificación de
hash ni un algoritmo de concatenación con separadores. El ejemplo de respuesta
SOAP devuelve sus componentes en `IssuerParty/PartyTaxScheme/CompanyID`,
`DocumentReference/ID` y `DocumentReference/IssueDate`.

Propuesta de extracción:

1. NIF: instantánea `F.NIF_EMPRESA_FAC`, validada según la rama LOC/VAT.
   No tomar el NIF actual de `fza_empresas` si ha cambiado.
2. Serie-número: `FormatearDocumento(formatoDeLaFacturaEmitida,
   F.SERIE_FAC, F.NUMERO_FAC)`. Es el mismo servicio genérico al que delega
   `ComponerNumSerieFactura`, sin llamar al módulo VERI*FACTU desde SPFE.
   No insertar `/` por defecto ni convertir el número a entero.
3. Fecha: parte de fecha de `F.FECHA_FAC`, serializada `yyyy-mm-dd`, sin
   conversión de huso horario. Nunca usar fecha del envío o del reintento.

Ejemplo ilustrativo inventado de datos, no ejemplo normativo: NIF
`B12345674`, serie `2026.A1`, número `000042`, formato
`Serie.NroDocumento`, fecha 12-11-2026 producen la terna
`(B12345674, 2026.A1.000042, 2026-11-12)`.
No se define una cadena única `B12345674/...` porque no está especificada.

**Regla confirmada por el usuario:** conservar la serie y el número originales
de la factura emitida, incluso si cambia el formato de la empresa después.
Guardar separados los componentes originales y el BT-1 exacto, junto al NIF
y fecha de la identidad. La captura de nuevas emisiones debe producirse en
el límite de emisión, no aplazarse a un primer envío que pueda ocurrir tras
cambiar la configuración. Su enganche concreto se diseñará fuera del módulo
VERI*FACTU, con persistencia independiente y migración revisable.

El lector fiscal actual consulta `fza_empresas.FORMATO_DOCUMENTO_EMP`; no se
ha acreditado una instantánea del formato al emitir. Para históricos se
buscará la identidad exacta en registros XML/PDF originales conservados,
contrastando los datos y posibles subsanaciones. No basta aplicar el formato
actual a SERIE_FAC/NUMERO_FAC. Si no se puede determinar con certeza, la
preparación queda pendiente de recuperación/revisión documentada. La
primera preparación histórica solo congelará datos ya verificados; no
modificará factura, XML fiscal, QR ni cadena de hash. La ausencia de cambios
conocidos no se considera evidencia suficiente para reconstruirlos todos.
La normalización de NIF de VERI*FACTU elimina caracteres no alfanuméricos;
no trasladar automáticamente esa regla al contrato SPFE sin confirmación.

El **localizador SPFE es otro dato**: se recibe en
`DocumentReference/ReferencedDocumentInternalAddress` según SOAP. Guardarlo
literalmente, sin regenerarlo ni deducir su estructura del ejemplo
`LOCGENV1:O:...`. Tampoco confundir el ID de `DocumentStatus` con ese localizador.

La URL QR puede no estar disponible aún al consolidar, porque la emisión
fiscal dispone de cola propia. Si resulta exigible en esa factura, la
preparación UBL debe esperar al dato existente y mostrar el motivo pendiente;
no generar un QR alternativo ni cambiar el procesador fiscal para obtenerlo.
La terna y la versión de datos preparada permanecen estables durante esa espera.

## Propuesta de persistencia, pendiente de revisión

Esta sección es diseño de aplicación, no tablas prescritas por la AEAT.
No se ha generado ni ejecutado DDL. Los tipos/tamaños definitivos dependen del
DDL normalizado y de las restricciones documentales que faltan.

Se proponen tablas `fza_spfe_*`, InnoDB, sufijos propios, auditoría
`INSTANTE_ALTA`, `INSTANTE_MODIF`, `USUARIO_ALTA`, `USUARIO_MODIF`.
Booleanos `varchar(1)` S/N. Relaciones lógicas indexadas sin FK física.
Vistas `VI_`, procedimientos `PRC_`; no son necesarias funciones ni triggers
nuevos. Si se necesitaran en el futuro, se respetarían los prefijos FN_/TRG_
solicitados, resolviendo antes las restricciones locales.

| Tabla y sufijo propuesto | Contenido mínimo propuesto | Claves e índices de acceso |
|---|---|---|
| `fza_spfe_facturas` / SPF | `ID_SPF` bigint; `CODIGO_EMP_SPF`; `ROL_SPF`; origen venta/compra; serie/número internos; NIF, número externo BT-1, fecha y nombre emisor congelados; `GENERACION_SPF`; `ENTORNO_SPF`; `LOCALIZADOR_SPF`; estado técnico local, estado remoto documental y estados remotos emisor/destinatario separados; versión optimista | PK ID; único por origen/empresa/rol/serie/número/entorno/generación; índice de terna y entorno para consultas; índice empresa/rol/estado/ID para listados paginados |
| `fza_spfe_documentos` / SPD | `ID_SPD`, `ID_SPF_SPD`, versión de contrato/generador, XML UBL exacto, instantánea de formato/códigos tributarios/cuentas/condiciones que no existen en origen; generación documental | PK ID; único factura/generación documental; no indexar XML; no usar `F.XML_FAC`, reservado al flujo Facturae |
| `fza_spfe_vencimientos` / SPV | `ID_SPV`, `ID_SPF_SPV`, orden, fecha, importe y moneda; referencia lógica al efecto origen; versión de condiciones congelada | PK ID; único factura/versión/orden; índice factura/fecha; opcional empresa/fecha solo si lo exige una pantalla medida |
| `fza_spfe_eventos` / SPE | `ID_SPE`, `ID_SPF_SPE`, rol, código A2, fecha efectiva, vencimiento, recepción mercancía y factura, financiación, factura rectificada/negativa; estado local pendiente/confirmado/error; ID de evento cancelado; clave local de deduplicación | PK ID; índice factura/ID; único clave deduplicación; no inventar unicidad por fecha que impida cancelar y volver a comunicar |
| `fza_spfe_pagos` / SPP | `ID_SPP`, `ID_SPF_SPP`, clase pago/cobro, fecha, importe y moneda locales, referencia a efecto/recibo, indicador completo y evento SPE asociado; permite desgloses parciales internos | PK ID; índice factura/fecha/ID; referencia de origen única con ámbito suficiente para evitar registrar dos veces |
| `fza_spfe_rechazos` / SPR | `ID_SPR`, `ID_SPF_SPR`, `ID_SPE_SPR`, fecha, motivo tasado 01/02, observación local y referencia a cancelación | PK ID; único evento; índice factura/fecha/ID. Rechazo comercial separado de error técnico de envío |
| `fza_spfe_cola` / SPC | `ID_SPC`, factura/evento, operación, estado local, próximo intento, intentos, propietario y caducidad de reserva, ID de documento inmutable; clave de trabajo lógica | PK ID; índice estado/próximo intento/ID; único trabajo lógico; cola propia sin usar ni modificar `fza_verifactu_cola` |
| `fza_spfe_envios` / SPS | `ID_SPS`, entorno, servicio/acción, MessageId, ConversationId, RefToMessageId, inicio/fin, resultado HTTP y SOAP, resultado documental, versión de contrato, referencia al intento anterior | PK ID; único entorno/MessageId para correlación; índice fecha/ID para mantenimiento |
| `fza_spfe_envios_detalle` / SPED | `ID_SPED`, envío, factura/evento/documento, Content-ID, código/descripcion remotos por documento, localizador devuelto | PK ID; índice envío/ID y factura/ID; único envío/elemento de trabajo |
| `fza_spfe_envios_contenido` / SPSC | `ID_SPSC`, envío, clase petición/respuesta/fault, bytes exactos y tipo MIME; carga grande fuera de listados | PK ID; índice envío/clase; sin índices sobre payload |

Los nombres de columnas no enumerados en la tabla se definirán con el sufijo
de su tabla al redactar la migración. Los identificadores externos requieren
comparación exacta, sin colisiones por colación insensible a mayúsculas o
acentos; tipos, longitudes y colaciones quedan pendientes del contrato/DDL.
No imponer una longitud de localizador deducida de un único ejemplo.

La terna identifica una factura activa, pero no debe ser UNIQUE histórica
sin generación: CAT permite una nueva remisión con igual identidad tras
cancelar. La exclusión de dos generaciones activas se resolverá mediante
procedimiento/transacción y bloqueo por identidad; la migración debe detallar
el mecanismo antes de implementarlo. El estado desconocido tras timeout no
autoriza a abrir otra generación ni a mostrar aceptación.

La tabla documental no habilita a omitir campos FALTA: una vez resueltas las
dudas se decidirán columnas/tablas tipadas para los conceptos nuevos usados
por el negocio. No se propone inventar automáticamente terceros, inmuebles,
autorizaciones, monedas o impuestos que no estén documentados en la factura.

### Anexo II y estados

| Acción / rol | Datos específicos A2 | Relación con los datos actuales |
|---|---|---|
| PAYMENT / destinatario | Fecha efectiva obligatoria, vencimiento obligatorio; recepción mercancía/factura opcionales; CorrectedInvoice y NegativeAmountInvoice opcionales | Efectos de compra/pagos son candidatos de contabilidad; FALTA evento SPFE y fechas/indicadores específicos confirmados |
| CANCELPAYMENT / destinatario | Referencia de factura y emisor | Nuevo evento enlazado al pago comunicado |
| REJECTION / destinatario | Fecha rechazo y motivo obligatorio 01 comercial / 02 particular o no afecto | FALTA registro específico; no usar errores de validación como rechazo comercial |
| CANCELREJECTION / destinatario | Referencia de factura y emisor | Nuevo evento enlazado al rechazo comunicado |
| SETTLEMENT / emisor | Fecha cobro obligatoria; vencimiento, financiación y fechas recepción opcionales | `E.FECHA_COBRO_EFV` candidato; confirmar integridad del cobro y conservar soporte |
| CANCELSETTLEMENT / emisor | Referencia de factura y emisor | Nuevo evento enlazado al cobro comunicado |
| DEFAULT / emisor | Vencimiento obligatorio como EffectiveDate; fechas recepción opcionales | `E.FECHA_VENCIMIENTO_EFV` candidato; falta regla para múltiples vencimientos |
| CANCELDEFAULT / emisor | Referencia de factura y emisor | Nuevo evento enlazado al impago comunicado |

Todas las acciones llevan serie-número, fecha de expedición, NIF y nombre del
emisor (A2). El transporte puede llevar varias comunicaciones, pero CAT §6.8
limita a 100 estados del destinatario y prohíbe mezclar roles. No extrapolar
sin confirmación otros límites de lote que el documento no especifique.

PAYMENT y REJECTION son excluyentes en el rol destinatario. SETTLEMENT y
DEFAULT son excluyentes en el rol emisor. No combinar ambos roles en una sola
columna «pagada»: pueden comunicar información diferente. La cancelación
remota de un evento se registra, no borra la historia. Corregir una fecha
ya comunicada exige cancelar primero y comunicar de nuevo, según CAT.

CAT §§6.8-6.9 no admite comunicar importes parciales de pago/cobro: las
comunicaciones implican totalidad y no incluyen importe. Los parciales
permanecen en la gestión local; no emitir PAYMENT/SETTLEMENT por liquidar
solo un efecto. Para facturas recibidas falta concretar descarga/importación
y vínculo con `fza_facturas_compra`; no basta el listado de ventas para
ofrecer correctamente pago y rechazo como destinatario.

### Carga y atomicidad con un servidor de dos núcleos

La preparación debe leer una cabecera por clave, sus líneas y sus efectos;
agrupar solo esos datos en memoria. Prohibir barridos de ventas, funciones
sobre claves de búsqueda, agregaciones históricas y consultas de catálogo
INFORMATION_SCHEMA por cada emisión. Comprobar capacidades en instalación o
inicio del componente, y cachear catálogos pequeños con versión definida.

Índices confirmados en viracash_web.sql, incluyendo ALTER posteriores a CREATE:

| Lectura | Clave existente en esta copia |
|---|---|
| Cabecera de venta | PK `(NUMERO_FAC, SERIE_FAC)`; también `IDX_FACTURAS_SERIE (SERIE_FAC, NUMERO_FAC)` |
| Líneas de venta | PK `(NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, LINEA_FACLIN)`; igualdad en los dos primeros campos y orden por línea |
| Cabecera/líneas de compra | PK número/serie; detalle número/serie/línea |
| Consolidación | `UK_FACTURA (SERIE_FAC_FACCON, NUMERO_FAC_FACCON)` único |
| Relaciones | `UQ_FACREL_FACTURA_TIPO (SERIE_FAC_FACREL, NUMERO_FAC_FACREL, TIPO_RELACION_FACREL)`; `IDX_FACREL_ORIGEN` por serie/número origen |
| Efectos venta/compra | PK serie/número/efecto; índices de vencimiento aparte |
| Pagos venta | PK serie/número/línea; fecha como índice separado |
| Pagos compra | PK serie/número/efecto/pago |

No hace falta proponer otro índice serie/número para lecturas puntuales ya
cubiertas por estas claves. Los filtros de relaciones deben expresar el tipo
cuando corresponda; la clave única permite como máximo un origen por tipo
para una factura en esta copia, no una colección arbitraria de referencias.
Faltan EXPLAIN y medidas en un entorno de prueba para los SELECT definitivos;
no se han ejecutado consultas ni migraciones en una base real.

La futura integración debe registrar intención SPFE y documento estable de
forma coherente con la consolidación. Propuesta: un coordinador de aplicación
fuera de `src/verifactu`, con operación local transaccional y cola persistente;
la ubicación exacta del enganche se revisará en Fase 3. Un fallo posterior al
commit necesita reconciliación incremental con cursor, nunca marcar enviada
una factura solo por haberla consolidado. No hay llamada web en la transacción
de emisión ni en las Fases 2-3.

Procesado con un único trabajador inicialmente, lotes pequeños, reserva
temporal y liberación por caducidad; listado por clave, sin OFFSET profundo.
Los XML y cuerpos MIME se cargan al abrir detalle, no al pintar cada fila.
Guardar resultado por documento: HTTP 200 no prueba aceptación comercial ni
aceptación de cada factura. FES p.14 y SOAP distinguen código global y código
de documento. Conservar ambos sin asumir que el 406 documental sea HTTP 406.
Definir retención de payloads con el usuario antes de purgar; jamás registrar
claves privadas ni credenciales en las trazas.

## Preparación de fases siguientes, sin implementarlas

Dominio/generador nuevo bajo `src/spfe/`, con prefijo `inSpfe`: tipos,
identidad, generador UBL y validación separados. Persistencia SQL en units
`UniDataSpfe*`, conforme a la separación UniData exigida por el repositorio;
formularios/adaptadores VCL separados y controles DevExpress. Ninguna unit
de dominio debe importar formularios ni el cliente SOAP.

La migración futura se escribirá aparte, idempotente y con comprobaciones
INFORMATION_SCHEMA, en `factuzam_web/DESARROLLOS EN CURSO/`, como exigen los
AGENTS.md vigentes. No se aplicará a una BD real. Pruebas y recursos en
`factuzam_web/tests/spfe/`, no crear tests/scripts/tmp en ViraCash.

Fase 2: generador puro sin red, entrada tipada con instantánea de factura;
si falta un dato obligatorio, error explícito. XML UTF-8, namespaces UBL,
orden de elementos conforme al XSD, escape correcto, importes decimales y
fechas independientes de configuración regional. Solo Invoice, también para
rectificativas (VAL pp.5-6), tipos 384/471 y grupos RECT según A1.

Pruebas DUnitX propuestas:

- Ejemplo básico EJ y `altaFacturas.xml` de SOAP como fixtures de estructura
  y valores. Comparar XML por nombres expandidos/valores, no por prefijos o
  espacios. Contienen NIF/IBAN de ejemplo (`xxxx`, etc.); no prueban validación
  censal ni aceptación real de negocio.
- Validación XSD local, con todas sus dependencias resueltas sin red; casos
  negativos de ID obligatorio, fecha inválida y estructura incorrecta,
  expresamente citados por VAL.
- Reglas de cardinalidad, constantes y listas de A1; condiciones LOC/VAT,
  direcciones españolas, REGI, exenciones, retenciones, descuentos, RE,
  moneda, vencimientos y conciliación de totales cuando las reglas precisas
  estén disponibles.
- Rectificativas I/S, R1-R4, referencia anterior y Base/Cuota/CuotaRecargo;
  confirmar tipos de sustitución de simplificadas y emisión por destinatario.
  Las fixtures propias deberán identificarse como derivadas del anexo, no
  como ejemplos oficiales de rectificativas.
- Conservar ceros iniciales y número emitido, cambios posteriores de fichas,
  caracteres XML, distintas configuraciones regionales y casos con parciales.

**Estado actualizado de los recursos de validación:** WS sigue conteniendo
solo un LEEME bajo `PRE/xsd/ubl-2.5/`, pero su dependencia ya está resuelta
en `ViraCash_web/docs/spfe/ubl-2.5/`, con 116 XSD canónicos verificados frente
a OASIS. Invoice, DocumentStatus y ApplicationResponse compilan sin red y
el ejemplo AEAT supera validación XSD. No se ha implementado el generador ni
DUnitX: es comprobación del material de referencia durante la Fase 1.
Sigue sin acreditarse Schematron adaptado a SPFE/UBL 2.5, modelo UNE íntegro
ni catálogo exhaustivo de errores AEAT. VAL p.7 dice que las reglas específicas
se publicarán progresivamente. No se puede prometer validación semántica
completa con este material, ni inventar reglas ausentes. El servicio de
validación PRE requiere certificado, valida una factura y no debe usarse
sistemáticamente antes de cada envío (VAL p.8); queda fuera de Fase 2.

Fase 3: pantalla con estado técnico, localizador e historia; acciones según
rol y datos de A2; mantener estado local pendiente separado del confirmado.
La UI sin red registra intenciones, no respuestas ficticias.

Fase 4 únicamente cuando se indique: importación WSDL en unit aislada,
adaptador SOAP 1.2 + ebXML + adjuntos MIME, no solo SOAP XML en el body.
Reutilizar la gestión de certificados disponible mediante un adaptador, sin
cambiar VERI*FACTU. WS es solo PRE; faltan configuraciones de producción
confirmadas. CAT p.9 describe Fault SOAP 1.1 aunque el transporte se declara
SOAP 1.2: conservar esa discrepancia para aclaración, no resolverla por
suposición. FES §§5.3-5.9 siguen pendientes de publicación en la versión local.

## Dudas que debe resolver el usuario

1. ¿La copia documental suministrada es el contrato aprobado para implementar?
   Aportar concordancia con la Orden definitiva si existe; faltan reglas
   detalladas AEAT y el contenido semántico/sintáctico UNE referenciado.
2. Para pruebas sin red, incorporar a `docs/spfe/` los XSD UBL 2.5 completos,
   Schematron/reglas aplicables y catálogos externos usados (UNECE, UNTDID,
   VATEX). ¿Hay ejemplos oficiales de rectificativas? No están en esta copia.
   No los descargaré ni sustituiré por otra versión sin indicación.
3. Entorno resuelto: RAD Delphi 13.2; Win64 como principal y Win32 usado
   ocasionalmente para desarrollo. Validar DUnitX principalmente en Win64
   y mantener compilación Win32. Falta localizar el proyecto de pruebas
   estándar que deba reutilizarse.
4. Esquema localizado y leído: `ViraCash_web/viracash_web.sql`, por indicación
   del usuario. Metadatos de tablas e índices extraídos sin datos ni ejecución;
   revisados procedimientos de generación de efectos y conciliación parcial.
   Se mantienen las ubicaciones de migraciones/pruebas de los AGENTS.md
   mientras el usuario no indique otra ubicación.
5. ¿Qué facturas entran inicialmente: solo ventas nacionales B2B en EUR o
   también compras/recepción, autofacturas, sustitución de simplificadas,
   recapitulativas y operaciones especiales? Pago/rechazo requieren el rol
   destinatario; definir el alcance de recepción y su vínculo con compras.
6. Regla de numeración resuelta: conservar serie/número originales y BT-1
   exacto aunque cambie FORMATO_DOCUMENTO_EMP. Falta cerrar la recuperación
   histórica con evidencia y la representación del NIF frente a LOC/VAT.
7. Aprobar correspondencias de operación fiscal a L3/L4 y VATEX, incluidos
   RE, IGIC/IPSI y operaciones con más de un régimen. ¿Existen documentos con
   categorías mezcladas dentro de una misma banda de cabecera?
8. Confirmar tratamiento de R5, sustitución de simplificadas, facturas por
   destinatario, referencias múltiples e importes rectificados. L2.A solo
   contempla R1-R4; no convertir R5 a R4 por defecto.
9. ¿Qué vencimiento se comunica cuando hay varios efectos? ¿Dónde constan
   recepción de factura/mercancía, fecha de operación y periodo recapitulativo?
   A1/A2 remiten a normas de morosidad, pero esta copia no aporta algoritmo
   suficiente para calcular todos los casos. No fijar automáticamente 30/60 días.
10. ¿Qué registro prueba el pago/cobro completo, cómo afectan anticipos con o
    sin devengo, devoluciones, financiación, facturas negativas y posteriores
    rectificaciones? No deducir integridad de un único recibo cobrado.
11. Confirmar equivalencias de unidades UNECE y medios UNTDID 4461, cuenta
    receptora, condiciones contractuales y concepto/base de retención L5.
12. Suplidos confirmados para el alcance inicial, sin clientes actuales.
    Falta definir su captura y persistencia. ¿Se usan tasas, impuestos
    especiales, cargos de documento/línea,
    o autorizaciones? Referencias catastrales e inmuebles aplazados por
    el usuario. Terceros expedidores ya
    incluidos por el usuario; falta diseñar su captura. Para los otros casos,
    indicar el origen o aprobar su captura específica antes del generador.
    COMENTARIOS_FAC ya confirmado: comentarios legales impresos para el
    cliente; incluir en XML como notas legales.
13. Aprobar propuesta de tablas, retención del log/XML, ubicación del enganche
    transaccional y política ante indisponibilidad/fallos locales de SPFE;
    el cumplimiento fiscal existente no debe alterarse por una política implícita.
14. Para Fase 4: documentación de producción, permisos/representación,
    discrepancia Fault SOAP 1.1/1.2 y formatos aún pendientes. No iniciar
    importación ni llamadas hasta indicación expresa.

## Entrega y comprobaciones

Único archivo creado por esta tarea: `docs/spfe/PLAN.md`. Sin cambios de
código, esquema, VERI*FACTU ni hash; sin acceso a BD, sin importación WSDL,
sin llamadas SPFE, sin commit, push ni merge. Los cambios locales ajenos se
han preservado, incluidos los que aparecieron durante la revisión.

Comprobación documental: lectura de los cinco PDF, ejemplo XML y contenido
de ambos ZIP; revisión visual de la tabla fiscal de A1 p.22 y contraste de
los IDs BT/BG con la matriz. No procede compilar ni ejecutar DUnitX en esta
fase documental. La Fase 2 queda pendiente de revisión y de resolver los
datos/contratos que impiden generar y validar correctamente los casos acordados.
