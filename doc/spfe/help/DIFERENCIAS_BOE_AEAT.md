# Diferencias entre la Orden del BOE y el material técnico AEAT

Criterio acordado por el usuario: prevalece la Orden publicada en el BOE.
Las diferencias de interfaz se comprobarán en PRE en Fase 4, solo cuando
el usuario lo indique. No se han importado WSDL ni realizado llamadas SPFE.

## BT-23: tipo de proceso de negocio / ProfileID

| Fuente verificada | Localización | Valor |
|---|---|---|
| Orden HAC/1028/2026, copia BOE | boe/Orden_HAC_1028_2026.pdf, p.13, Anexo I, BT-23 | urn:aeat:names:specification:ubl:schema:profile:B2B |
| Anexo técnico AEAT | ViraCash_web/docs/spfe/A1-Proyecto-OM-FE.pdf, p.6, BT-23 | urn:aeat:names:specification:schema:profile:B2B |
| Ejemplo básico AEAT | ViraCash_web/docs/spfe/factura.xml, cbc:ProfileID | urn:aeat:names:specification:schema:profile:B2B |

El segmento :ubl: aparece en el BOE y no en esas dos fuentes técnicas.
Decisión de implementación para Fase 2: usar el valor del BOE. No modificar
las fixtures oficiales; las pruebas deben declarar y comprobar la diferencia
esperada al comparar el generador con el ejemplo AEAT.

La prueba XSD del ejemplo no resuelve esta discrepancia semántica. Tampoco
se da por probado qué valor aceptará PRE. No habrá reintentos automáticos
cambiando el ProfileID ni modificación silenciosa del contrato.

Fuentes originales consultadas:

- [Orden en el BOE](https://www.boe.es/eli/es/o/2026/10/02/hac1028).
- [Información técnica AEAT](https://sede.agenciatributaria.gob.es/Sede/iva/factura-electronica/informacion-tecnica.html).

## Revisión pendiente

Este es un registro iniciado, no un inventario exhaustivo de diferencias.
Falta cotejar todos los campos, cardinalidades, reglas y listas del Anexo I
y del Anexo II. La matriz inicial del PLAN trazaba el anexo técnico AEAT;
no debe confundirse con una verificación completa contra la Orden del BOE.
