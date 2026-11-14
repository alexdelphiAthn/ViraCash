# Arquitectura MVC de ViraCash

La separación MVC se aplica en la base compartida de los mantenimientos
y en los flujos de venta y cobro del TPV.
Los nombres de unidad, la herencia VCL y los recursos DFM conservan sus
rutas. Este documento es el punto de entrada para localizar responsabilidades.

## Responsabilidades y ubicación

| Responsabilidad | Ubicación | Contenido |
|---|---|---|
| Vista | `src/Forms`, `src/Modals`, `src/Caja/Forms`, `src/Caja/Modals` | Controles, foco, navegación visual y diálogos. |
| Controlador | `src/Lib/inLibControlador*.pas` | Decisiones de interacción y coordinación de casos de uso por contratos. |
| Modelo de dominio | `src/Lib/inLib<dominio>*.pas` | Reglas, cálculos y servicios del negocio. |
| Contratos | `src/Lib/inLib*Intf.pas` | Interfaces, estados y resultados sin componentes visuales. |
| Persistencia y adaptadores del modelo | `src/DataModules/UniData*.pas`, `src/Caja/DataModules` | UniDAC, SQL, datasets y traducción al dominio. |
| Composición | `src/Core`, `vcash.dpr` y creación local de cada pantalla | Construcción, inyección y vida de los colaboradores. |

Las unidades `inLib*Vcl`, las de presentación y algunos gestores heredados
son infraestructura visual. El prefijo `inLib` por sí solo no implica que
una unidad sea dominio puro.

## Flujo común de mantenimiento

```text
Vista: TfrmMtoGen y descendientes
   |
   | eventos y estado de las acciones
   v
Controlador: TControladorMantenimiento
   |                            |
   | IModeloMantenimiento       | TInteraccionMantenimiento
   v                            v
Modelo: adaptador datasets      Vista: permisos, diálogo y guardado
   |
   v
Datasets y data module de la pantalla
```

- [Contratos MVC](../src/Lib/inLibMantenimientoMvcIntf.pas): estados propios
  del mantenimiento, decisiones de cierre y capacidades del modelo.
- [Controlador](../src/Lib/inLibControladorMantenimiento.pas): autorización
  de alta, edición, borrado y guardado; edición y borrado; refresco en consulta;
  cierre con guardar, descartar o cancelar.
- [Adaptador del modelo](../src/DataModules/UniDataModeloMantenimiento.pas):
  traduce el estado del dataset, detecta cambios en cabecera y detalles y
  descarta las ediciones mediante las utilidades existentes.
- [Vista común](../src/Forms/inMtoGen.pas): conserva atajos, foco, controles,
  cursor de espera y los diálogos traducibles. Delega las decisiones comunes
  en el controlador y conserva las restricciones de la rejilla de detalle.

Cada formulario posee su controlador. El modelo tiene referencias prestadas
al DataSource y al módulo. El módulo se resuelve al utilizarlo, porque puede
crearse después del formulario; también se respeta el cambio de dataset del
DataSource. El controlador se libera antes que los componentes de la vista.
No existe un controlador global ni referencias desde el modelo al formulario.

El guardado al cerrar sigue invocando `btnGrabarClick(Self)`, conservando sus
overrides, validaciones, reintentos, numeración y transacción. La acción de
guardar conserva su `Sender`. Un guardado abortado que deje cambios pendientes
impide cerrar. Las excepciones se propagan. El borrado sigue pasando por
`DataSet.Delete`, con sus eventos y guardián de confirmación.

## TPV: ventas y cobros

El [mapa del TPV](../src/Caja/README.md) detalla sus subcarpetas por área,
las unidades de entrada y las garantías del flujo.

- `Caja/Lib/Controladores/inLibControladorVentaTpv`: cierre de venta,
  confirmación de cobro, factura completa, crédito y salida de la operación.
- `Caja/Lib/Contratos/inLibTpvMvcIntf`: estados y capacidades sin UI ni SQL.
- `Caja/DataModules/Modelos/UniDataModeloPreparacionVentaTpv`: adaptación de
  líneas, validación por stock y lotes y restauración de depósitos.
- `Caja/Forms/Ventas/inMtoCajaCierreVentaVcl`: adaptación del diálogo y del
  servicio de grabación, manteniendo los reintentos y las rectificaciones.
- `Caja/Forms/Cobros/inMtoCajaFaseCobro`: controles, editores y mensajes de
  cobro. Los botones delegan la coordinación en el controlador.

## Localizar un cambio por dominio

| Funcionalidad | Vista | Modelo y persistencia |
|---|---|---|
| Artículos | `inMtoArticulos` | `inLibArticulos*`, `UniDataArticulos*` |
| Ventas y documentos | `inMtoFacturas`, `inMtoDocumento` | `inLibDocumento*`, `UniDataFacturas*` |
| Compras por sesiones | `inMtoComprasSesiones*` | `inLibComprasSesiones*`, `UniDataComprasSesiones*` |
| Reparaciones | `inMtoReparaciones*` | `inLibReparaciones*`, `UniDataReparaciones*` |
| Caja | `src/Caja/Forms` y `src/Caja/Modals` | `src/Caja/Lib` y `src/Caja/DataModules` |
| Inicio e inyección | `src/Core/inMto*InyeccionRaiz` | Construcción de servicios para las pantallas. |

Para localizar una familia se puede buscar por el término del dominio:
`rg --files src -g '*ComprasSesiones*.pas'`.

## Cómo extenderlo

1. Una vista recoge entrada y representa resultados. El foco, la selección
   visual y el texto de los diálogos pertenecen a la vista.
2. La coordinación de una operación pertenece a un controlador del dominio.
   Se reutiliza el controlador común cuando la política es la misma.
3. Los controladores reciben contratos y valores. No importan `inMto*`,
   `UniData*`, VCL, DevExpress ni `Data.DB`; tampoco construyen repositorios.
4. Las reglas del negocio pertenecen al modelo; el SQL y los nombres físicos
   de columnas permanecen en `UniData*`.
5. Añadir una unidad solo cuando tenga una responsabilidad propia. Las
   variantes que comparten el mismo proceso usan configuración o estrategias.
6. Toda extracción de comportamiento se acompaña de pruebas sin BBDD real.

## Alcance de la migración

El controlador común se utiliza en los mantenimientos derivados de
`TfrmMtoGen`. El TPV tiene un controlador propio para venta, cobro, factura,
crédito y salida; no hereda artificialmente del controlador de mantenimiento.
El guardado transaccional, los filtros, la impresión y otras coordinaciones
del legado conservan sus colaboradores. La edición detallada de artículos,
el escáner, los arqueos y los traspasos mantienen sus servicios actuales,
organizados en las nuevas subcarpetas.

La separación permite extraerlos por caso de uso, preservando los contratos
públicos de los formularios. El objetivo es tener responsabilidades visibles
con menos acoplamiento, sin imponer tres unidades nuevas a cada pantalla.

## Verificación

Pruebas DUnitX en el repositorio auxiliar:
`factuzam_web/tests/mvc_viracash/ejecutar.ps1`.

El script compila la aplicación Release en Win32 y Win64 en su carpeta
`build`, y ejecuta 29 pruebas en cada plataforma. Incluyen permisos, estados,
las tres decisiones de cierre, guardado incompleto y excepciones; el adaptador
se prueba con datasets en memoria, detalles tardíos, reasignación del dataset,
cancelación y validación de borrado. No conecta a una base de datos.

Las pruebas no sustituyen una comprobación visual de cada pantalla ni las
baterías de integración de los procesos fiscales y de caja.

La batería `factuzam_web/tests/mvc_tpv/ejecutar.ps1` añade las comprobaciones
específicas del TPV y ejecuta también las anteriores de mantenimientos. Cubre
el orden de los pasos, rechazos, cancelaciones, errores antes y después de
grabar, factura completa, crédito y restauración de depósitos en memoria.
