# TPV: organización y MVC

El TPV se agrupa por responsabilidad técnica y área funcional. Los prefijos
Pascal y los nombres de clase siguen siendo los mismos: cambiar una carpeta
no cambia el registro de pantallas ni los identificadores de traducción.

## Carpetas

```text
Caja/
  Forms/
    Ventas/           Operación de caja y sus adaptadores visuales
    Cobros/           Cobro, referencias de pago y selección de vales
    Arqueos/          Histórico de arqueos
    Consultas/        Históricos de operaciones, pagos y vales
    Traspasos/        Traspasos, solicitudes y distribución
    Proformas/        Facturas proforma
    Configuracion/    Menú de caja, parámetros y formatos
  Modals/
    Ventas/ Cobros/ Arqueos/ Consultas/ Traspasos/ Proformas/
  Lib/
    Controladores/    Coordinación MVC sin VCL, UniDAC ni datasets
    Contratos/        Interfaces, estados, resultados e interacciones
    Ventas/ Cobros/ Arqueos/ Consultas/ Traspasos/ Proformas/
    Configuracion/
  DataModules/
    Modelos/          Adaptadores de los contratos MVC
    Ventas/ Cobros/ Arqueos/ Consultas/ Traspasos/ Proformas/
    Configuracion/
```

Los `.pas` y `.dfm` de cada formulario o data module viven juntos. Las
librerías heredadas mantienen sus dependencias actuales; `Lib` contiene tanto
reglas como servicios del legado. `Controladores` y el nuevo contrato MVC sí
mantienen una frontera estricta sin tipos visuales ni de persistencia.

## Entradas principales

| Responsabilidad | Unidad |
|---|---|
| Coordinación de venta, cobro, factura, crédito y salida | [inLibControladorVentaTpv](Lib/Controladores/inLibControladorVentaTpv.pas) |
| Contratos y estados MVC | [inLibTpvMvcIntf](Lib/Contratos/inLibTpvMvcIntf.pas) |
| Preparación de líneas y depósitos | [UniDataModeloPreparacionVentaTpv](DataModules/Modelos/UniDataModeloPreparacionVentaTpv.pas) |
| Vista operativa de ventas | [inMtoCajaOpe](Forms/Ventas/inMtoCajaOpe.pas) |
| Vista del cobro | [inMtoCajaFaseCobro](Forms/Cobros/inMtoCajaFaseCobro.pas) |
| Adaptador del diálogo y sesión de cierre | [inMtoCajaCierreVentaVcl](Forms/Ventas/inMtoCajaCierreVentaVcl.pas) |
| Grabación, impresión y archivado | [inLibCajaCierreVenta](Lib/Ventas/inLibCajaCierreVenta.pas) |
| Unidad de trabajo | [UniDataCajaUnidadTrabajo](DataModules/Ventas/UniDataCajaUnidadTrabajo.pas) |

## Flujo y garantías

1. El controlador pide al modelo localizar atributos pendientes, apartar los
   depósitos que no se cobran y preparar las líneas con stock y lotes.
2. El adaptador visual solicita el motivo de devolución y el contacto de
   reparación cuando corresponda, calcula totales y muestra el cobro.
3. El controlador coordina la solicitud, la confirmación de arqueos de las
   rectificaciones, el guardado y la presentación del resultado.
4. Al cancelar o fallar antes de confirmar, el modelo restaura los depósitos.
   Una venta ya confirmada no se restaura por un error al mostrar el resultado.
5. La confirmación de ticket, sin ticket y regalo comparte la misma secuencia
   de validación, recálculo y autorización de emisión. La subsanación utiliza
   sus validaciones y no emite un documento nuevo.
6. La factura completa valida cliente e identificación fiscal antes de abrir
   serie y fecha. Un cambio de total deja el cobro abierto para ajustarlo.
7. Los apartados y cargos a cuenta verifican permiso, pendiente y entrega;
   piden contacto para Varios y confirman el ticket solo tras aceptar crédito.
8. La salida muestra la operación oculta antes de preguntar, conserva la venta
   si se rechaza el abandono y mantiene el circuito propio de subsanación.

La numeración, los reintentos, las transacciones, la impresión y la lógica
fiscal siguen usando sus servicios existentes. Los formularios adaptan los
controles a estos contratos y muestran los mensajes traducidos. No se han
sustituido los eventos de validación del dataset ni los servicios de dominio.

Los callbacks son síncronos y prestados: no se guardan para después de cerrar
la sesión visual. Cada sesión posee sus totales, diálogo y copia temporal de
depósitos; los datasets de la operación conservan su propietario.

## Comprobaciones

`factuzam_web/tests/mvc_tpv/ejecutar.ps1` compila Release Win32 y Win64 y
comprueba los flujos TPV con DUnitX y datasets en memoria. Incluye además las
pruebas MVC de los mantenimientos para detectar regresiones compartidas.

`factuzam_web/tests/mvc_tpv/reubicaciones.json` registra origen, destino y
SHA-256 de los 208 archivos trasladados. La migración verificó que cada
traslado conservaba exactamente sus bytes, incluidos los cambios locales.
Las rutas del proyecto y los contextos de traducción se actualizan a la nueva
ubicación. Los inventarios históricos, como el SBOM fechado, siguen siendo
instantáneas de su fecha original.
