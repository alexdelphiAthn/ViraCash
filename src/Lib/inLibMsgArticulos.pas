{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgArticulos                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de artículos, atributos, tarifas, inventario y stock.            }
{******************************************************************************}
unit inLibMsgArticulos;

interface

resourcestring
  STituloMovimientosArticuloColor = 'Movimientos por artículo/color';
  SIrMovimientoMovimientosArticulo = 'Ir a movimiento (Ctrl+M)';
  SIrDocumentoMovimientosArticulo = 'Ir a documento (Ctrl+Mayús+A)';
  SSinDocumentoMovimientosArticulo =
    'El movimiento seleccionado no tiene un documento asociado.';
  SCajaSinClaveMovimientosArticulo =
    'El movimiento no conserva la clave completa de la operación de caja.';
  SDocumentoNoSoportadoMovimientosArticulo =
    'No hay una pantalla asociada al tipo de documento del movimiento.';
  SColorSelectorMovimientosArticulo = 'Color:';
  STodosColoresMovimientosArticulo = 'Todos los colores';
  SSinColorMovimientosArticulo = '(Sin color)';
  SAyudaPreciosMovimientosArticulo =
    'Compra: coste histórico sin IVA. Venta: precio del documento con IVA. ' +
    'Seleccione el color en el combo superior.';
  SAyudaVistaMovimientosArticulo =
    'F1: alterna tallas en horizontal / vertical.';
  SCerrarMovimientosArticulo = 'Cerrar';
  SColorMovimientosArticulo = 'Color/variación';
  STallaMovimientosArticulo = 'Talla';
  SFechaMovimientosArticulo = 'Fecha';
  SNumeroMovimientosArticulo = 'Movimiento';
  SEmpresaMovimientosArticulo = 'Empresa';
  SAlmacenMovimientosArticulo = 'Almacén';
  SNombreAlmacenMovimientosArticulo = 'Nombre almacén';
  STipoMovimientosArticulo = 'E/S';
  SUnidadesMovimientosArticulo = 'Unidades';
  SDocumentoMovimientosArticulo = 'Doc.';
  SDescripcionDocumentoMovimientosArticulo = 'Documento';
  SSerieMovimientosArticulo = 'Serie';
  SNumeroDocumentoMovimientosArticulo = 'N.º documento';
  SCajaMovimientosArticulo = 'Caja';
  SPrecioCompraMovimientos = 'Precio compra (sin IVA)';
  SPrecioVentaMovimientos = 'Precio venta (con IVA)';
  SPrecioVentaSinIvaMovimientos = 'Precio venta (sin IVA)';
  SDescuentoMovimientosArticulo = '% dto.';
  STotalCosteMovimientosArticulo = 'Importe coste';
  SLineaMovimientosArticulo = 'Línea';
  SOperacionMovimientosArticulo = 'Operación';
  SSkuMovimientosArticulo = 'SKU';
  SActivoMovimientosArticulo = 'Activo';
  SSinMovimientosArticulo = 'Sin movimientos';
  SLeyendaVentasStock = 'Ventas';
  SLeyendaRecibirStock = 'Pendiente de recibir';
  SLeyendaExistenciasStock = 'Stock';
SLeyendaAvisosBalance =
    'Dif. fact./ventas: unidades facturadas menos salidas por venta. ' +
    'Se excluyen borradores y facturas internas de traspaso.' + sLineBreak +
    'Stock sin movimientos: existencias sin movimientos que las justifiquen. ' +
    'Las filas rojas son diferencias para revisar, no ventas adicionales.';
  SValorTarifaAplicada = 'Aplicada';
  SValorTarifaPrecioOrigen = 'Precio de origen';
  SValorTarifaPrecioCoste = 'Precio de coste';
  SValorTarifaPrecioDestinoActual = 'Precio de destino actual';
  SValorTarifaAmbos = 'Ambos';
  SValorTarifaPrecioSalida = 'Precio de salida';
  SValorTarifaPrecioFinal = 'Precio final';
  SValorTarifaCopiar = 'Copiar';
  SValorTarifaIncrementoLineal = 'Incremento lineal';
  SValorTarifaIncrementoPorcentual = 'Incremento porcentual';
  SValorTarifaPrecioFijo = 'Precio fijo';
  SValorTarifaSi = 'Sí';
  SValorTarifaNo = 'No';
  STituloImportarArticulosInventario = 'Importar inventario';
  SEmpresaImportarInventario = 'Empresa de origen:';
  SAlmacenImportarInventario = 'Almacén de origen:';
  SSerieImportarInventario = 'Serie de origen:';
  SNumeroImportarInventario = 'Número de inventario de origen:';
  SErrorClaveImportarInventario =
    'Indique empresa, almacén, serie y número del inventario de origen.';
  SErrorOrigenImportarInventario =
    'No se encuentra un único inventario con los datos indicados.';
  SErrorMismoImportarInventario =
    'El inventario de origen debe ser distinto del inventario actual.';
  SErrorSinArticulosImportarInventario =
    'El inventario de origen no tiene artículos.';
  SInfoArticulosImportadosInventario =
    'Se han importado %d líneas. Las líneas ya existentes se conservan.';
  SAvisoTallasHorizontalRecortadas =
    'Hay artículos con más tallas de las %d que caben en horizontal: ' +
    '%s.'#13#10'De cada uno se muestran las tallas con cantidades y, ' +
    'después, las primeras de su sistema. Para ver o editar el resto ' +
    'utilice la vista por SKU.';
  SAvisoTallasHorizontalArticulo = '%s (%d tallas)';
  SAvisoTallasHorizontalYMas = '%s y %d más';
  STituloFechaUltimaCompra = 'Fecha últ. compra';
  SErrorLineaAlbaranSinArticulo =
    'La línea del albarán no tiene artículo; no se puede guardar.';
  SErrorCodigoSkuCodigoBarrasObligatorio =
    'Indique el código de SKU al añadir un nuevo código de barras. Para ' +
    'crear un SKU nuevo use la pestaña SKUs.';
  SErrorCampoCodigoBarrasAusente =
    'Falta el campo CODIGO_BARRAS_CB.';
  SErrorCodigoSkuObligatorio = 'Indique el código del SKU.';
  SErrorFilaCodigoBarrasInexistente =
    'Esta fila no representa un código de barras existente. No hay nada ' +
    'que eliminar.';
  SErrorProveedorPrincipalArticulo =
    '%s ya tiene un proveedor principal asociado a este artículo.';
  SErrorNombreArticuloVacio =
    'Introduzca el nombre del artículo antes de grabar.';
  SErrorSimboloNombreArticulo =
    'El carácter «%s» no se admite en el nombre del artículo. ' +
    'Corrija el nombre antes de grabar.';
  SErrorFamiliaArticuloObligatoria =
    'Seleccione una familia para el artículo antes de grabar.';
  SErrorDescripcionArticulo =
    '%s no es un valor válido para el campo Descripción de Artículos';
  SErrorProveedorAltaArticuloInexistente =
    'El proveedor "%s" no existe. Seleccione un proveedor válido.';
  SPreguntaModeloProveedorAltaArticulo = 'Modelo del proveedor';
  SPreguntaCodigoProveedorAltaArticulo = 'Código del proveedor';
  SErrorCodigoArticuloDuplicado =
    'El código de artículo "%s" ya existe. Indique otro código.';
  // FZ-ISSUE-172: soluciones inmediatas en el alta de artículos.
  SPreguntaCodigoArticuloDuplicadoLibre =
    'El código de artículo "%s" ya existe.'#13#10#13#10 +
    'El siguiente código libre es "%s".';
  SBotonUsarCodigoArticulo = 'Usar %s';
  SBotonIndicarOtroCodigoArticulo = 'Indicar otro';
  SErrorCodigoBarrasRepetido =
    'El código de barras %s ya está asignado a %s (artículo %s: %s). ' +
    'No se puede repetir.';
  SBotonAbrirArticuloCodigoBarras = 'Abrir ese artículo';
  SBotonSeguirEditandoCodigoBarras = 'Seguir editando';
  SAvisoCodigoBarrasGs1 =
    'El código de barras %s es un código GS1: solo puede usarlo la ' +
    'empresa que lo tiene asignado. Si es el código del fabricante del ' +
    'artículo, es correcto. Si lo crea usted, ha de solicitarlo a GS1 ' +
    '(en España, GS1 Spain, prefijo 84) o usar un código interno del ' +
    'rango 20-29 (los que genera ViraCash empiezan por 21).';
  SErrorPermisoCambiarMarcaWebArticulo =
    'No tiene permiso para activar o desactivar la marca En web del ' +
    'artículo.';
  SPreguntaDesactivarArticuloPrestaShop =
    'El artículo "%s" dejará de sincronizarse con PrestaShop.' +
    sLineBreak + sLineBreak +
    '¿Desea desactivarlo también en la tienda web?' + sLineBreak +
    'Sí: se desactiva en PrestaShop y deja de mostrarse en la web.' +
    sLineBreak +
    'No: solo deja de sincronizarse; el artículo permanece como esté.' +
    sLineBreak +
    'Cancelar: no se guarda el cambio.';
  SPreguntaDesactivarTarifaSinPrecio =
    'El precio de salida pasa a 0. ¿Desea desactivar la tarifa?';
  SPreguntaActivarTarifaConPrecio =
    'El precio de salida es mayor que 0. ¿Desea activar la tarifa?';
  SErrorTarifaFechasConcurrentes =
    'No se pueden grabar dos precios para una tarifa activa en fechas ' +
    'concurrentes para el artículo/SKU %s';
  SErrorAtributoBasicoObligatorio =
    'Indica el atributo (CO para color, TAL para talla, etc.).';
  SErrorCodigoAtributoBasicoObligatorio =
    'El código del atributo básico es obligatorio.';
  SErrorNombreAtributoBasicoObligatorio =
    'El nombre del atributo básico es obligatorio.';
  SErrorValorColeccionAtributosObligatorio =
    'Escribe el valor que quieres añadir a la colección.';
  SErrorArticuloLineaDocumentoTrabajoObligatorio =
    'Indique el artículo de la línea.';
  SErrorSkuLineaDocumentoTrabajoObligatorio =
    'Indique el SKU/unidad de la línea.';
  SAvisoPropiedadFamiliaDuplicada = 'Propiedad Duplicada';
  SErrorNombreFamilia =
    '%s no es un valor válido para el campo Nombre de Familias';
  SErrorFamiliaPadreIgualHija =
    '%s no puede ser padre e hijo a la vez. Revise campo Familia Padre';
  SErrorSerieInventarioObligatoria =
    'No se puede grabar el inventario sin una serie. Selecciona una serie ' +
    'en la cabecera (campo SERIE), o configura una serie por defecto de ' +
    'tipo IN para la empresa en fza_empresas_series.';
  SErrorInventarioAlmacenTransito =
    'El almacén %s es de tránsito: solo se usa en traspasos y no se ' +
    'inventaría. Elija otro almacén.';
  SErrorContadorLineasInventarioNoInstalado =
    'No se puede reservar la línea del inventario: falta la columna ' +
    'fza_inventarios.CONTADOR_LINEAS_INV. Ejecuta el script DESARROLLOS EN ' +
    'CURSO\inventarios_contador_lineas.sql.';
  SErrorCabeceraInventarioSinGrabarParaReserva =
    'No se puede reservar la línea: graba primero la cabecera del ' +
    'inventario para tener empresa, almacén, serie y número definitivos.';
  SErrorCabeceraInventarioNoEncontrada =
    'No se ha encontrado la cabecera del inventario para reservar la ' +
    'siguiente línea.';
  SErrorActualizarContadorLineasInventario =
    'No se ha podido actualizar el contador de líneas del inventario.';
  SErrorEmpresaCabeceraInventarioObligatoria =
    'La cabecera del inventario no tiene empresa. Selecciona una empresa ' +
    'antes de añadir líneas.';
  SErrorAlmacenCabeceraInventarioObligatorio =
    'La cabecera del inventario no tiene almacén. Selecciona un almacén ' +
    'antes de añadir líneas.';
  SErrorSerieCabeceraInventarioObligatoria =
    'La cabecera del inventario no tiene serie. Vuelve a la pestaña ' +
    'Cabecera, selecciona una serie y vuelve a intentar grabar la línea.';
  SErrorNumeroCabeceraInventarioObligatorio =
    'La cabecera del inventario no tiene número. Graba primero la cabecera ' +
    'para que el sistema asigne el número.';
  SErrorAtributoLineaInventarioObligatorio =
    'La línea %s del artículo %s requiere %d atributos y el atributo nº %d ' +
    'está sin rellenar. Completa todos los selectores (Color, Talla, …) o ' +
    'elimina la línea.';
  SPreguntaCrearSkuInventario =
    'El SKU "%s" no existe en la base de datos.' + sLineBreak + sLineBreak +
    '¿Quieres crearlo automáticamente con los atributos seleccionados y ' +
    'guardar la línea?' + sLineBreak + sLineBreak +
    'Sí: se crea el SKU (fza_articulos_skus + fza_atributos_sku) y se ' +
    'graba la línea.' + sLineBreak +
    'No: no se graba. Cambia los atributos a una combinación válida o ' +
    'pulsa "- Eliminar línea".';
  SErrorSkuInventarioNoExiste =
    'SKU "%s" no existe. La línea no se ha grabado. Cambia los atributos o ' +
    'elimina la línea.';
  SErrorEliminarLineasInventarioNoAbierto =
    'No se pueden eliminar líneas: el inventario no está ABIERTO';
  SErrorAnadirLineaCabeceraInventario =
    'No se puede añadir una línea: la cabecera del inventario no se ha ' +
    'podido grabar.' + sLineBreak + '%s' + sLineBreak +
    'Completa los datos obligatorios de la cabecera y vuelve a intentarlo.';
  SErrorRecalcularInventarioNoAbierto =
    'Solo se puede recalcular un inventario en estado ABIERTO';
  SErrorAplicarInventarioNoAbierto =
    'Solo se puede aplicar un inventario en estado ABIERTO';
  SErrorAplicarInventarioSinLineas =
    'No se puede aplicar un inventario sin líneas. Añade al menos una línea ' +
    'con diferencia de cantidad o de coste antes de regularizar.';
  SErrorEliminarRegularizacionInventarioNoAplicado =
    'Solo se puede eliminar la regularización de un inventario APLICADO';
  SErrorCargarArticulosInventarioNoAbierto =
    'Solo se pueden cargar artículos en un inventario ABIERTO';
  SErrorCompletarInventarioNoAbierto =
    'Solo se puede completar un inventario ABIERTO';
  SErrorArticuloLineaInventarioObligatorio =
    'Debe indicar un artículo (la línea actual está vacía).';
  SErrorAnadirSkusInventarioNoAbierto =
    'Solo se pueden añadir SKUs en un inventario ABIERTO';
  SErrorValorAtributoSkuInventarioNoEncontrado =
    'No se encontró el valor "%s" en el atributo nº %d del artículo %s. ' +
    'No se ha podido crear el SKU %s.';
  SAvisoEdicionMovimientoAlmacen =
    'No se permite %s movimientos de almacén manualmente.' + sLineBreak +
    'Usa el proceso correspondiente (albarán, factura, traspaso, ' +
    'regularización de inventario...).';
  SErrorLineaPedidoSinArticulo =
    'La línea del pedido no tiene artículo; no se puede guardar.';
  // Ficha de familias: propiedades de las familias superiores.
  STituloPropiedadesHeredadasFamilia =
    'Heredadas de las familias superiores (se editan en su familia):';
  // %s propiedad, %s nombre, %s familia de origen, %s sufijo obligatoria.
  SLineaPropiedadHeredadaFamilia = '%s · %s (de %s)%s';
  SSufijoPropiedadHeredadaObligatoria = ' · obligatoria';
  SSinPropiedadesHeredadasFamilia = 'Ninguna.';
  SErrorNombreSesionCambioTarifaObligatorio =
    'El nombre de la sesión es obligatorio.';
  // FZ-ISSUE-786: nombre de la sesión de cambio de tarifa sin teclear;
  // %s = fecha y hora.
  SNombreSesionCambioTarifaDefecto = 'Sesión de tarifas %s';
  SErrorTarifaDestinoObligatoria =
    'La tarifa destino es obligatoria.';
  SErrorCodigoAtributoVariacionObligatorio =
    'El código del atributo es obligatorio.';
  // Eje declarado de los atributos de un tipo de variación (tercera
  // dimensión, 23/10/2026). %s = código del atributo.
  SEjeVariacionPorPosicion = 'Por posición';
  SEjeVariacionPestanas = 'Pestañas';
  SErrorEjeVariacionNoAdmitido =
    'El eje del atributo %s no es válido: elija «Por posición» o ' +
    '«Pestañas».';
  SErrorPestanasVariacionEnExtremo =
    'El atributo %s no puede ir en pestañas: es el primero o el último ' +
    'del tipo de variación. Las pestañas van en un atributo intermedio.';
  SErrorPestanasVariacionRepetidas =
    'El tipo de variación ya tiene un atributo en pestañas; el atributo ' +
    '%s no puede tenerlas también.';
  // Resolución de SKU con pestañas (fase 2). %s = artículo y dos SKU;
  // en el segundo, el SKU que se iba a crear.
  SErrorSkuAmbiguoPestanas =
    'Hay varios SKU del artículo %s para esa talla y esa fila (%s, %s...): ' +
    'falta elegir el valor del atributo que va en pestañas.';
  SErrorSkuSinValorPestana =
    'No se puede crear el SKU %s: su tipo de variación tiene un atributo ' +
    'en pestañas y falta su valor.';
  // Pestañas del eje S en las rejillas (fase 3). %s = nombre del atributo
  // en pestañas, en minúsculas (copa, tipo de rosca...).
  SPestanaEjeTodas = 'Todas';
  SAvisoElegirPestanaStock =
    'Elija una pestaña de %s: en «Todas» la celda suma varios SKU.';
  SErrorDistribuidorTallasNoRegistrado =
    'No se ha registrado el distribuidor de tallas por almacén.';
  SErrorPersistenciaTallasNoRegistrada =
    'No se ha registrado la persistencia del modo de tallas.';
  SErrorArticulosVariacionesNoRegistradas =
    'No se ha registrado la implementación de variaciones de artículos.';
  SErrorPersistenciaFotosNoRegistrada =
    'No se ha registrado la persistencia del subsistema de fotos.';
  // La libreria ya no construye repositorios: la raiz de composicion
  // (TfrmBase.CrearValidadorArticulos / CrearLookupAtributosArticulos)
  // debe rellenar la configuracion antes de crear el modo de entrada.
  SErrorValidadorArticulosNoInyectado =
    'No se ha inyectado el validador de artículos en la configuración.';
  SErrorLookupAtributosNoInyectado =
    'No se ha inyectado el lookup de atributos en la configuración.';
  SErrorInvarianteUnidadesTallas =
    'La conversión de tallas alteraría las unidades del documento (%s: ' +
    'antes %.2f, después %.2f). Se deshacen los cambios.';
  SErrorAlmacenDistribucionTallasNoDisponible =
    'Formato distribuido: se necesita un almacén por defecto y no hay ' +
    'almacenes activos definidos.';
  SErrorArticuloSkuNoEncontrado =
    'Artículo/SKU no encontrado: %s';
  SAvisoArticuloSinAtributos =
    'El artículo no tiene atributos definidos: %s';
  SErrorFactoriaTallasHorizontalObligatoria =
    'El modo de tallas horizontal requiere su factoria especifica';
  SErrorArticuloDocumentoTrabajoNoActivo =
    'No hay artículo activo para agregar.';
  SErrorArticuloDocumentoTrabajoVariosSkus =
    'El artículo tiene varios SKUs. Selecciona una unidad concreta.';
  SErrorArticuloNoExiste =
    'No existe el artículo "%s"';
  SErrorEntradaArticuloVacia = 'Entrada vacía.';
  SErrorCodigoBarrasNoEncontrado =
    'No se encontró "%s" como código de barras.';
  SErrorArticuloEntradaNoEncontrado =
    'No se encontró "%s" como artículo, SKU, código de barras ni modelo de ' +
    'proveedor.';
  SErrorSkuDeBajaTallasHorizontal =
    'El SKU "%s" está dado de baja y no se puede añadir. Si quiere ' +
    'usarlo, actívelo antes en la ficha del artículo.';
  SErrorLineasDocumentoNoEditables =
    'Las líneas de este documento no admiten cambios.';
  SAvisoArticuloRequiereSku =
    'El artículo "%s" tiene SKUs (talla/color). Indica un SKU concreto ' +
    'antes de continuar.';
  SErrorArticuloVariacionSinSkusActivos =
    'El artículo "%s" no tiene tallas/colores (SKU) activos para vender.';
  SErrorArticuloSinSkusActivos =
    'El artículo "%s" no tiene ninguna unidad (SKU) activa para vender.';
  SErrorSkuNoPerteneceArticulo =
    'El SKU "%s" no pertenece a "%s" o no está activo.';
  SErrorLineaArticuloSesionNoSeleccionada =
    'Selecciona o crea una línea de artículo primero.';
  SErrorCodigoArticuloResolverObligatorio =
    'Falta código de artículo.';
  SErrorArticuloResolverNoExiste =
    'No existe el artículo "%s".';
  SAvisoArticuloResolverRequiereSku =
    'El artículo "%s" tiene SKUs. Indica uno para obtener precio definitivo.';
  STextoArticuloInactivoSesion = ' (inactivo)';
  SErrorCodigoBarrasNoNumerico =
    'El código de barras contiene caracteres no numéricos.';
  SErrorImportarImagenCodec =
    'No se puede importar %s en este equipo: falta el codec "%s".' +
    sLineBreak + sLineBreak +
    'Instálalo gratis desde Microsoft Store y reintenta.' +
    sLineBreak + sLineBreak +
    'Alternativa: guarda la imagen en PNG o JPG y vuelve a subirla.' +
    sLineBreak + sLineBreak +
    'Error original: %s';
  SErrorGuardarFotoSinCodigoArticulo =
    'No se puede guardar foto sin código de artículo.';
  SErrorFicheroOrigenFotoNoExiste =
    'El fichero origen no existe: %s';
  SErrorDirectorioFotosNoConfigurado =
    'El parámetro appDirFotos no está configurado.';
  SErrorFotoNoRegistradaParaRotar =
    'No hay foto registrada para rotar.';
  SErrorFotoSesionSinSerie =
    'Foto de sesión: falta SERIE_SES.';
  SErrorFotoSesionSinNumero =
    'Foto de sesión: falta NUMERO_SES.';
  SErrorFotoSesionLineaInvalida =
    'Foto de sesión: LINEA debe ser > 0.';
  STextoParametroUrlFotosNube =
    '  - URL general del servicio web';
  STextoParametroTokenFotosNube =
    '  - API key / token de la instalación';
  STextoParametroReferenciaFotosNube =
    '  - Referencia global de la instalación';
  STextoParametroCarpetaFotosNube =
    '  - Carpeta de fotos (appDirFotos)';
  SErrorParametrosFotosNubeFaltantes =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + sLineBreak + '%s';
  SErrorServidorFotosNubeHttp =
    'El servidor respondió con código %d.';
  SErrorConexionServidorFotosNube =
    'No se pudo conectar con el servidor de fotos: %s';
  SErrorValoresAtributoNoDefinidos =
    'No hay valores definidos para este atributo.';
  SErrorValoresAtributoArticuloNoDefinidos =
    'El artículo %s no tiene valores para el atributo %s.';
  SErrorArticuloSinSistemaTallasPivote =
    '- Artículo SIN sistema de tallas: %s';
  SErrorSkuFueraSistemaTallasPivote =
    '- SKU %s (art %s): talla "%s" fuera del sistema asignado.';
  SPreguntaEliminarLineaTallasVenta =
    '¿Está seguro de que desea eliminar esta línea (todas sus tallas)?';
  SErrorArticuloSkuNoEncontradoSinDetalle =
    'Artículo/SKU no encontrado.';
  SPreguntaEliminarLineaSkuCantidadCero =
    'La cantidad queda a cero. ¿Borrar la línea del SKU?';
  SAvisoSistemaTallasSuperaMaximo =
    'El sistema de tallas seleccionado tiene %d valores; el máximo admitido ' +
    'es %d. Elige un sistema con menos tallas o reduce el conjunto antes de ' +
    'usarlo aquí.';
  STextoParametroUrlInventarioNube =
    '  - URL general del servicio web';
  STextoParametroTokenInventarioNube =
    '  - API key / token de la instalación';
  STextoParametroReferenciaInventarioNube =
    '  - Referencia global de la instalación';
  SErrorParametrosInventarioNubeFaltantes =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + sLineBreak + '%s';
  SErrorServidorInventarioNubeHttp =
    'El servidor respondió con código %d.';
  SErrorConexionServidorInventarioNube =
    'No se pudo conectar con el servidor: %s';
  SErrorInventarioNubeSinIdRecuento =
    'El servidor no devolvió id_recuento';
  SErrorArticuloCursoSinSistemaTallas =
    'El artículo en curso no tiene sistema de tallas asignado.';
  SErrorAltaSeleccionarArticuloConTallas =
    'En alta, selecciona primero un artículo con sistema de tallas.';
  SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SPreguntaGrabarAlbaranVentaCantidadCero =
    'Las líneas %s tienen cantidad 0: no mueven stock ni suman importe.' +
    sLineBreak + '¿Grabar el albarán igualmente?';
  SPreguntaGrabarAlbaranVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  // FZ-ISSUE-233: venta por encima del stock del almacén de la línea.
  SDetalleStockInsuficienteLinea =
    '%s: se venden %s y hay %s en el almacén %s.';
  SErrorStockInsuficienteLinea =
    'No hay stock suficiente. %s';
  SErrorProveedorNoSeleccionadoBuscarArticulos =
    'Selecciona un proveedor antes de buscar artículos.';
  SAvisoArticuloCreadoOtroProveedor =
    'Este artículo se creó con otro proveedor';
  SErrorArticuloNoSeleccionadoElegirColor =
    'Selecciona un artículo antes de elegir color.';
  SErrorArticuloSinColoresBasicosActivos =
    'El artículo "%s" no tiene colores básicos activos en sus SKUs.';
  SErrorCambiarTipoVariacionConSkus =
    'No se puede cambiar el tipo de variación: el artículo ya tiene ' +
    'SKU generados con el tipo actual.';
  SErrorArticuloSinTipoVariacion =
    'El artículo debe tener asignado un "Tipo de variación" y estar ' +
    'guardado para poder generar SKUs.';
  SErrorPrecioTarifaNoSeleccionado =
    'Selecciona primero un precio de tarifa.';
  SErrorPrecioTarifaNoGuardado =
    'Esta fila aún no tiene precio guardado en la tarifa. Pulsa primero ' +
    '"Añadir precio" para crear el registro.';
  SPreguntaCerrarPreciosSolapados =
    'Estas %d combinaciones ya tienen precio en el periodo elegido:' +
    #13#10#13#10'%s'#13#10#13#10 +
    '¿Cerrar sus precios anteriores el %s y crear los nuevos?';
  SAvisoPreciosSolapadosNoCreados =
    'No se han creado %d combinaciones porque ya tienen precio en ' +
    'el periodo elegido:'#13#10#13#10'%s'#13#10#13#10 +
    'Revisa las fechas de vigencia de esos precios y vuelve a añadirlos.';
  SAvisoRevisionArticulo = 'Revisión requerida: %s';
  SErrorGuardarPropiedadesArticulo =
    'Error al guardar propiedades: %s';
  SErrorGuardarVariacionesArticulo =
    'Error al guardar variaciones: %s';
  SPreguntaReconstruirStock =
    '¿Desea reconstruir la tabla de stock a partir de los movimientos de ' +
    'almacén? Esta operación borrará el stock actual y lo regenerará.';
  STituloReconstruirStock = 'Reconstruir Stock';
  SErrorReconstruirStock =
    'Error al reconstruir el stock: %s';
  SInfoStockReconstruido = 'Stock reconstruido.';
  SErrorArticuloNoSeleccionadoImprimirEtiquetas =
    'Seleccione primero un artículo para imprimir sus etiquetas.';
  SErrorArticuloNoSeleccionadoGenerarCodigos =
    'Seleccione o guarde un artículo antes de generar códigos de barras.';
  SErrorArticuloSinSkusActivosGenerarCodigos =
    'El artículo no tiene SKUs activos.';
  SPreguntaGenerarCodigosBarras =
    '¿Generar códigos de barras pendientes?' + sLineBreak + sLineBreak +
    'Para cada SKU activo:' + sLineBreak +
    '  · Si no tiene principal: se genera un EAN-13 interno (prefijo ' +
    '"%s").' + sLineBreak +
    '  · Si ya tiene principal, se respeta.' + sLineBreak + sLineBreak +
    'Pulse Sí para continuar.';
  SInfoGeneracionCodigosBarras =
    'Generación finalizada.' + sLineBreak +
    '- EAN-13 internos creados: %d' + sLineBreak +
    '- Filas vacías de fabricante creadas: %d' + sLineBreak +
    '- SKUs con código principal (saltados): %d' + sLineBreak +
    '- Placeholders _FAB_ obsoletos eliminados: %d';
  SErrorArticuloNoSeleccionadoVerificarCodigos =
    'Seleccione o guarde un artículo antes de verificar.';
  SErrorDetalleCodigoBarrasInvalido =
    '  %s  (SKU %s, Tipo %s, Long %d)';
  SInfoVerificacionCodigosBarrasCorrecta =
    'Verificación OK.' + sLineBreak +
    '- EAN-13 válidos: %d' + sLineBreak +
    '- EAN-8  válidos: %d' + sLineBreak +
    '- Pendientes (placeholder/vacío): %d';
  SAvisoVerificacionCodigosBarras =
    'Verificación con incidencias.' + sLineBreak +
    '- EAN-13 válidos: %d' + sLineBreak +
    '- EAN-8  válidos: %d' + sLineBreak +
    '- NO válidos: %d' + sLineBreak +
    '- Pendientes: %d' + sLineBreak +
    'Códigos no válidos:%s';
  SInfoPrecargaArticuloGuardada = 'Precarga guardada.';
  STextoAtributoBasicoSinValor = '(sin valor)';
  SPreguntaCrearAtributoBasicoSku =
    'Este SKU todavía no tiene un atributo básico asignado para este valor.' +
    sLineBreak + sLineBreak +
    'Si       -> Crear básico GLOBAL "%s"' + sLineBreak +
    '            (compartido con otros artículos que usen ese valor)' +
    sLineBreak + sLineBreak +
    'No       -> Crear básico AD-HOC "%s"' + sLineBreak +
    '            (exclusivo de este artículo)' + sLineBreak + sLineBreak +
    'Cancelar -> No crear nada por ahora.';
  STituloCrearAtributoBasico =
    'Como crear el atributo básico';
  SErrorSkuColorNoSeleccionado =
    'Seleccione un SKU con valor en el eje de fila para activar o ' +
    'desactivar los SKU que comparten ese valor.';
  STextoActivarSkusColor = 'activar';
  STextoDesactivarSkusColor = 'desactivar';
  SPreguntaCambiarActivoSkusColor =
    'Va a %s TODOS los SKU con el valor de fila "%s" ' +
    'de este artículo. ¿Continuar?';
  STextoSkusColorActivados = 'activado';
  STextoSkusColorDesactivados = 'desactivado';
  SInfoSkusColorActualizados =
    '%d SKU con el valor de fila "%s" se han %s.';
  SErrorLineaSesionAsignarFamiliaNoSeleccionada =
    'Añade una línea (o ponte sobre una) para asignarle familia.';
  SErrorContadorInventarioDocumentoTrabajo =
    'El contador de inventarios no ha devuelto número para la serie %s.';
  SInfoInventarioDocumentoTrabajoCreado =
    'Inventario %s/%s creado en almacén %s con %d líneas del documento.' +
    sLineBreak +
    'Abre Inventarios y usa "Recalcular teórico/PMP" para fijar teóricos ' +
    'y costes.';
  SInfoCambioTarifasDocumentoTrabajoCreado =
    'Sesión de cambio de tarifas %d creada en BORRADOR con los artículos ' +
    'del documento.' + sLineBreak +
    'Abre "Cambios de tarifa" para elegir tarifas, regla de cálculo y ' +
    'aplicar.';
  SErrorFilaDevolucionStockNoSeleccionada =
    'Selecciona una fila antes de devolver su stock.';
  SErrorArticuloDevolucionFilaNoSeleccionado =
    'Selecciona un artículo en la fila antes de devolver su stock.';
  SErrorStockDevolucionFilaNoDisponible =
    'No hay stock positivo para el artículo/color de la fila en el almacén ' +
    'de salida.';
  SPreguntaPrepararStockFilaDevolucion =
    'Esto sustituirá las cantidades de la fila actual por el stock positivo ' +
    'de ese artículo/color en el almacén de salida. ¿Continuar?';
  SInfoStockFilaDevolucionPreparado =
    'Se han preparado %d líneas de la fila con el stock actual.';
  SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorArticuloNoSeleccionadoBuscarSkusDevolucion =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorFotoArticuloNoActivoDescargar =
    'No hay artículo activo para descargar fotos.';
  SErrorFotoArticuloNoActivo = 'No hay artículo activo.';
  SErrorGuardarFotoArticulo =
    'No se pudo guardar la foto: %s';
  SErrorFotoSkuNoActivo =
    'No hay SKU activo. Usa "Cambiar foto del artículo".';
  SErrorNivelAtributosFotoNoSeleccionado =
    'No hay nivel de atributos seleccionado en el combo.';
  SPreguntaEliminarFotoActual = '¿Eliminar la foto actual?';
  SErrorTarifaSeleccionadaNoEncontrada =
    'No se encontró la tarifa seleccionada';
  SErrorArticuloInventarioNoExiste = 'El artículo no existe';
  SErrorLineasInventarioNoAbiertas =
    'No hay líneas de inventario abiertas.';
  SErrorLineaInventarioNoEditable =
    'No se ha podido poner la línea en edición.';
  SErrorArticuloInventarioNoEncontrado =
    'No se ha encontrado ningún artículo con ese código, SKU o código de ' +
    'barras';
  SErrorArticuloInventarioTipoSinStock =
    'El artículo %s es de tipo "%s" y no controla stock; no se puede ' +
    'inventariar.';
  SErrorArticuloInventarioAtributosSinSku =
    'El artículo %s tiene atributos. En modo SKU introduce un SKU completo ' +
    'o activa "Ver atributos en columnas".';
  SInfoLineasCsvInventarioLeidas =
    'Leídas %d líneas del CSV.';
  SErrorMigracionRecuentoInventariosNoAplicada =
    'La base de datos no tiene aplicada la migración de recuento remoto de ' +
    'inventarios. Ejecuta el script DESARROLLOS EN ' +
    'CURSO\recuento_inventarios_factuzam.sql.';
  SErrorGrabarCabeceraInventarioAutomaticamente =
    'No se ha podido grabar automáticamente la cabecera del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Completa los datos en la pestaña Cabecera y vuelve a intentar añadir ' +
    'la línea.';
  SErrorGrabarCabeceraInventarioAutomaticamenteDetalle =
    'No se ha podido grabar automáticamente la cabecera del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Completa los datos en la pestaña Cabecera y vuelve a entrar en ' +
    'Detalle.';
  SErrorGrabarLineasInventarioCambioPestana =
    'No se han podido grabar los cambios de las líneas del inventario:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Corrige la línea o pulsa Esc para descartarla antes de cambiar de ' +
    'pestaña.';
  SErrorInventarioNoAbiertoEditar =
    'El inventario no está ABIERTO. No se puede editar.';
  SPreguntaRecalcularInventario =
    'Esto recalculará las cantidades teóricas y precios medios de todas ' +
    'las líneas a partir del Kardex actual.' + sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoRecalculoInventario =
    'Recálculo completado correctamente.';
  SPreguntaAplicarInventario =
    'Esto aplicará el inventario y generará movimientos de regularización' +
    sLineBreak +
    'en el Kardex. La operación NO se podrá deshacer fácilmente.' +
    sLineBreak + sLineBreak +
    '¿Aplicar el inventario?';
  SErrorAplicarInventario =
    'No se puede aplicar el inventario:' + sLineBreak + '%s';
  SErrorAplicacionInventario =
    'Error al aplicar el inventario:' + sLineBreak + '%s';
  SErrorRefrescarInventarioAplicado =
    'El inventario se aplico, pero falló el refresco:' + sLineBreak + '%s';
  SInfoInventarioAplicado = 'Inventario aplicado correctamente.';
  SErrorInventarioNoSeleccionadoAnadirLineas =
    'No hay ningún inventario seleccionado todavía. Crea uno o selecciónalo ' +
    'en la lista antes de añadir líneas.';
  SErrorAnadirLineasInventarioEstado =
    'No se pueden añadir líneas: el inventario está en estado "%s" (solo ' +
    'se pueden editar inventarios ABIERTOS).';
  SErrorLineaInventarioNoSeleccionadaParaSkus =
    'Sitúate sobre una línea con artículo para añadir sus SKUs.';
  SErrorLineaInventarioSinArticulo =
    'La línea actual no tiene artículo asignado.';
  SErrorAnadirSkusInventario =
    'Error al añadir SKUs: %s';
  SInfoSinSkusAnadidosInventario =
    'No se ha añadido ningún SKU. El artículo %s no tiene movimientos en ' +
    'este almacén o todos sus SKUs ya están en el inventario.';
  SInfoSkusAnadidosInventario =
    'Añadidos %d SKUs del artículo %s.';
  SPreguntaEliminarLineaInventario =
    '¿Eliminar la línea seleccionada?';
  SErrorEliminarRegularizacionInventarioEstado =
    'Solo puedes eliminar la regularización de un inventario APLICADO.';
  SPreguntaEliminarRegularizacionInventario =
    'Esto BORRARÁ todos los movimientos generados por este inventario,' +
    sLineBreak +
    'devolverá el inventario al estado ABIERTO y recalculará el Kardex.' +
    sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoRegularizacionInventarioEliminada =
    'Regularización eliminada. El inventario vuelve a estar ABIERTO.';
  SCaptionEsperaRegularizandoInventario =
    'Regularizando el inventario...';
  SCaptionEsperaActualizandoInventario =
    'Actualizando los datos del inventario...';
  SCaptionEsperaCargandoLineasInventario =
    'Cargando %d líneas del inventario...';
  SCaptionEsperaEliminandoRegularizacionInventario =
    'Eliminando la regularización del inventario...';
  SErrorInventarioNoActivo = 'No hay inventario activo.';
  SErrorInventarioDebeEstarAbierto =
    'El inventario debe estar ABIERTO.';
  SErrorFamiliaInventarioNoSeleccionada =
    'Selecciona primero una familia.';
  SPreguntaCargarFamiliaInventario =
    '¿Cargar todos los SKUs de la familia "%s" al inventario?';
  SErrorProveedorInventarioNoSeleccionado =
    'Selecciona primero un proveedor.';
  SPreguntaCargarProveedorInventario =
    '¿Cargar todos los SKUs del proveedor "%s" al inventario?';
  SPreguntaCompletarInventario =
    'Esto añadirá al inventario todos los SKUs con stock que NO ' +
    sLineBreak +
    'estén ya en el inventario, con cantidad física = 0.' + sLineBreak +
    sLineBreak +
    'Útil para detectar artículos que faltó contar.' + sLineBreak +
    sLineBreak + '¿Continuar?';
  SPreguntaCargarTodoInventario =
    'Esto cargará TODOS los SKUs con stock al inventario, ' + sLineBreak +
    'con cantidad física = teórica. ¿Continuar?';
  SErrorInventarioNoSeleccionado =
    'Selecciona primero un inventario.';
  SPreguntaGuardarInventarioEnEdicion =
    'El inventario está en edición. ¿Guardar antes?';
  SPreguntaRecalcularTrasCargarBloqueInventario =
    'Se añadieron %d líneas (%d artículos distintos).' + sLineBreak +
    '¿Quieres calcular ahora las cantidades teóricas y PMP?';
  SErrorArchivoImportacionInventarioNoExiste =
    'El archivo no existe.';
  SErrorImportacionInventarioSinDatos =
    'No se encontraron datos para importar.';
  SErrorImportacionInventarioYaIniciada =
    'Ya hay una importación de inventario en curso.';
  SErrorMarcaRecuentoSinImportacion =
    'La recogida requiere una importación de inventario en curso.';
  SErrorAplicarImportacionInventario =
    'No se pudieron aplicar %d cambios de la importación del inventario.';
  STituloIncidenciasImportacionInventario =
    'Incidencias en la importación del inventario';
  STextoIncidenciasImportacionInventario =
    'No se ha importado ninguna línea. Corrige estas incidencias en el ' +
    'archivo y vuelve a intentarlo:';
  SFormatoIncidenciaCantidadImportacionInventario =
    'Fila %d | SKU: "%s" | Cantidad: "%s" | Debe ser un número válido ' +
    'mayor o igual que cero.';
  SFormatoIncidenciaPmpNuevoImportacionInventario =
    'Fila %d | SKU: "%s" | PMP nuevo: "%s" | Debe ser un número válido ' +
    'mayor o igual que cero.';
  SFormatoIncidenciaFechaRecuentoImportacionInventario =
    'Fila %d | SKU: "%s" | Fecha y hora de recuento: "%s" | Debe ser ' +
    'una fecha y hora válidas.';
  SFormatoIncidenciaCaducidadImportacionInventario =
    'Fila %d | SKU: "%s" | Caducidad: "%s" | Debe ser una fecha válida ' +
    '(dd/mm/aaaa).';
  SFormatoIncidenciaLineaImportacionInventario =
    'Línea "%s" | SKU: "%s" | No coincide con una línea del inventario ' +
    'actual.';
  SIncidenciaIdentidadExcelIncompleta =
    'Excel | Identidad incompleta | Debe incluir Empresa, Almacén, Serie y ' +
    'Número con valor. No se admiten archivos antiguos sin esa cabecera.';
  SIncidenciaIdentidadExcelContradictoria =
    'Excel | Identidad contradictoria | Hay datos de Empresa, Almacén, ' +
    'Serie o Número repetidos con valores distintos.';
  SFormatoIncidenciaInventarioExcelDistinto =
    'Excel | Inventario distinto | Archivo: Empresa "%s", Almacén "%s", ' +
    'Serie "%s", Número "%s" | Inventario abierto: Empresa "%s", ' +
    'Almacén "%s", Serie "%s", Número "%s".';
  STextoSkusNoCargadosImportacionInventario =
    'No se pudieron cargar estos SKU:';
  STituloFechaHoraRecuentoInventario =
    'Fecha y hora del recuento';
  STextoFechaHoraRecuentoInventario =
    'El Excel no incluye la fecha y hora de recuento para todas las ' +
    'líneas. Indica el instante que se aplicará solo a las líneas sin ' +
    'ese dato.';
  SErrorFechaHoraRecuentoInventarioNoIndicada =
    'Indica una fecha y hora de recuento válidas.';
  SEtiquetaFechaHoraRecuentoInventario =
    'Fecha y hora de recuento:';
  STextoAceptarFechaHoraRecuentoInventario = 'Aceptar';
  STextoCancelarFechaHoraRecuentoInventario = 'Cancelar';
  SErrorRecuentoInventarioSinInstanteSku =
    'El servidor no ha devuelto una fecha y hora válida para el SKU "%s".';
  SErrorSkuRecuentoInventarioNoExiste =
    'El SKU "%s" leído por el móvil no existe en ViraCash. No se ha ' +
    'importado el recuento.';
  SErrorRespuestaRecuentoInventarioIncoherente =
    'El servidor ha devuelto lecturas incompletas, con una fecha u hora no ' +
    'válida, o cantidades que no coinciden. No se ha importado el recuento.';
  SInfoImportacionInventario =
    '%s' + sLineBreak + '%d actualizados, %d nuevos insertados.';
  SErrorEnviarRecuentoInventarioNoAbierto =
    'Solo se puede enviar a recuento un inventario ABIERTO.';
  SPreguntaEnviarRecuentoInventario =
    'Se enviará este inventario al servidor para recontarlo con la app. ' +
    '¿Continuar?';
  SInfoInventarioEnviadoRecuento =
    'Inventario enviado a recuento (referencia %d).';
  SErrorEnviarRecuentoInventario = 'No se pudo enviar: %s';
  SErrorInventarioNoEnviadoRecuento =
    'Este inventario no se ha enviado a recuento todavía.';
  SAvisoAlmacenesRecuentoNoPublicados =
    'No se pudo publicar la lista de almacenes para la app: %s';
  SPreguntaRecogerRecuentoLibreApp =
    'Hay %d recuento(s) libre(s) terminado(s) en el móvil para el ' +
    'almacén %s. ¿Recoger en este inventario el del dispositivo "%s" ' +
    '(terminado %s)?';
  SErrorBuscarRecuentosAppPendientes =
    'No se pudieron consultar los recuentos del móvil: %s';
  SErrorRecogerRecuentoInventarioNoAbierto =
    'Solo se puede recoger sobre un inventario ABIERTO.';
  SInfoRecuentoInventarioRecogido =
    'Recuento recogido: %d lecturas, %d SKUs. Revisa las físicas y APLICA ' +
    'cuando quieras.';
  SErrorRecogerRecuentoInventario = 'No se pudo recoger: %s';
  SAvisoRecuentoInventarioNoAsignados =
    '%d lectura(s) del móvil no corresponden a ningún artículo y no se ' +
    'han importado:';
  SCaptionRevalorizarPmpInventario = 'Valorar';
  SHintRevalorizarPmpInventario =
    'Simula y prepara una apreciación o depreciación porcentual del PMP. ' +
    'Atajo: Ctrl+Mayús+R.';
  STituloRevalorizacionInventario =
    'Apreciación/depreciación del inventario';
  STextoRevalorizacionInventario =
    'Selecciona las líneas y simula el cambio antes de prepararlo. Se usa ' +
    'el PMP guardado en el inventario y se comprueba de nuevo contra el ' +
    'Kardex al confirmar. La vista previa no aplica la valoración; las ' +
    'existencias solo cambiarán al pulsar Regularizar.';
  SFormatoIdentificacionRevalorizacionInventario =
    'Inventario %s / %s / %s / %s';
  SCaptionOperacionRevalorizacionInventario = 'Operación';
  SCaptionApreciarInventario = 'Apreciar';
  SCaptionDepreciarInventario = 'Depreciar';
  SCaptionPorcentajeRevalorizacionInventario = 'Porcentaje:';
  SCaptionSimularRevalorizacionInventario = 'Simular';
  SCaptionSeleccionarTodoRevalorizacionInventario =
    'Seleccionar visibles';
  SCaptionSeleccionarNingunoRevalorizacionInventario =
    'Quitar toda la selección';
  SCaptionPrepararPmpRevalorizacionInventario = 'Preparar PMP simulados';
  SInfoSimulacionPendienteRevalorizacionInventario =
    'Pulsa Simular para actualizar la vista previa.';
  SCaptionColAplicarRevalorizacionInventario = 'Aplicar';
  SCaptionColLineaRevalorizacionInventario = 'Línea';
  SCaptionColCantidadTeoricaRevalorizacionInventario = 'Uds. anteriores';
  SCaptionColCantidadFisicaRevalorizacionInventario = 'Uds. finales';
  SCaptionColPmpAnteriorRevalorizacionInventario = 'PMP anterior';
  SCaptionColPmpSimuladoRevalorizacionInventario = 'PMP simulado';
  SCaptionColValorAnteriorRevalorizacionInventario = 'Valor anterior';
  SCaptionColValorSimuladoRevalorizacionInventario = 'Valor simulado';
  SCaptionColDiferenciaRevalorizacionInventario = 'Diferencia';
  SFormatoLineasRevalorizacionInventario = 'Líneas seleccionadas: %d';
  SCaptionTotalAnteriorRevalorizacionInventario = 'Total anterior:';
  SCaptionTotalSimuladoRevalorizacionInventario = 'Total simulado:';
  SCaptionTotalDiferenciaRevalorizacionInventario = 'Diferencia total:';
  SAvisoDiferenciasUnidadesRevalorizacionInventario =
    '%d líneas también tienen diferencias entre unidades anteriores y ' +
    'finales; la diferencia económica incluye ambos efectos.';
  SAvisoPmpCorregidosRevalorizacionInventario =
    '%d líneas ya tenían un PMP corregido manualmente; se sustituirá por ' +
    'el PMP de esta simulación.';
  SCaptionMargenMinimoRevalorizacion = 'Margen mínimo';
  SHintMargenMinimoRevalorizacion =
    'A 0 se exige el mínimo que corresponde a la antigüedad de cada ' +
    'línea (meses desde la última compra): %s.' + sLineBreak +
    'Con un valor mayor que cero, ese porcentaje manda sobre los tramos.';
  SHintMargenMinimoSinTramos =
    'Porcentaje mínimo de margen sobre el coste exigido a todas las ' +
    'líneas. A 0 no se comprueba nada.';
  SCaptionCosteYaDevaluadoRevalorizacion =
    'El coste ya está devaluado en inventario';
  SHintCosteYaDevaluadoRevalorizacion =
    'Marca esto cuando el PMP venga de una apreciación o depreciación de ' +
    'inventario: la rebaja por temporada ya está en el coste y no debe ' +
    'restarse otra vez con los tramos de antigüedad.';
  SCaptionColAntiguedadRevalorizacion = 'Antig. (meses)';
  SCaptionColMargenMinimoRevalorizacion = 'Margen mín.';
  SCaptionColPrecioVentaDestinoRevalorizacion = 'Vendido a';
  SAvisoLineasLimitadasPorVenta =
    '%d líneas se han limitado al precio sin IVA al que la tienda las ' +
    'vendió: el traspaso no puede facturarse por encima de eso.';
  // FZ-ISSUE-367
  SCaptionColAvisoVentaDestinoRevalorizacion = 'Aviso venta';
  STextoVentaACeroRevalorizacion = 'Vendida a 0 €';
  STextoVentaSinLineaRevalorizacion = 'Venta sin línea de factura';
  SAvisoLineasVentaACeroRevalorizacion =
    '%d líneas tienen unidades que la tienda vendió a 0 € (regalo o ' +
    'promoción): se facturan al precio valorado, sin tope.';
  SAvisoLineasVentaSinLineaRevalorizacion =
    '%d líneas tienen ventas sin línea de factura enlazada: no se conoce ' +
    'el precio de venta y se facturan al precio valorado, sin tope.';
  SAvisoLineasBajoMargenMinimoRevalorizacion =
    '%d líneas quedarían por debajo de su margen mínimo sobre el coste ' +
    '(%s). Las líneas que no marcas se facturan a su precio base, es ' +
    'decir, sin margen. Entre empresas vinculadas el precio debe ser el ' +
    'de mercado, y el de un mayorista para género de esa antigüedad.' +
    sLineBreak + sLineBreak +
    '¿Deseas continuar de todos modos?';
  STextoMargenMinimoUnico = '%s %% para todas las líneas';
  STextoMargenMinimoPorTramos = 'por tramos de antigüedad: %s';
  SErrorPorcentajeRevalorizacionInventario =
    'Indica un porcentaje mayor que cero. En una depreciación no puede ' +
    'superar el 100 %.';
  SErrorSeleccionRevalorizacionInventario =
    'Selecciona al menos una línea para realizar la simulación.';
  SErrorLineaRevalorizacionInventarioNoEncontrada =
    'La línea %s ya no existe en el inventario.';
  SErrorDatosRevalorizacionInventarioCambiados =
    'Los datos de la línea %s han cambiado desde la simulación. Vuelve a ' +
    'pulsar Valorar para calcularla con las cifras actuales.';
  SErrorAplicarRevalorizacionInventario =
    'No se pudo preparar la apreciación/depreciación:' + sLineBreak + '%s';
  SInfoRevalorizacionInventarioPreparada =
    'Se han preparado %d PMP nuevos con las cifras comprobadas. Revisa el ' +
    'resultado y pulsa Regularizar para trasladarlos al Kardex.';
  SCaptionBaseRevalorizacionInventario = 'Base del cálculo';
  SCaptionBasePrecioMedioRevalorizacionInventario = 'PMP';
  SCaptionBaseUltimaCompraRevalorizacionInventario = 'Última compra';
  SCaptionImprimirRevalorizacionInventario = 'Imprimir listado';
  STituloInformeRevalorizacionInventario =
    'Valoración simulada del inventario';
  SFormatoOperacionRevalorizacionInventario = '%s un %s %% sobre %s';
  SAvisoSinUltimaCompraRevalorizacionInventario =
    '%d líneas no tienen precio de última compra; en ellas se ha usado el ' +
    'PMP como base.';
  SAvisoSinPrecioBaseRevalorizacionInventario =
    '%d líneas tienen a 0 el precio base del cálculo (PMP o última ' +
    'compra): el porcentaje no puede revalorizarlas y su precio ' +
    'simulado queda en 0. Revisa su coste antes de preparar los PMP.';
  SAvisoLimiteRegistrosMovimientosAlmacen =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorArticuloNoSeleccionadoBuscarSkusPedidoVenta =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SPreguntaGrabarPedidoVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SPreguntaCrearAlbaranPedidoVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado y no ' +
    'moverán stock. ¿Crear el albarán de todas formas?';
  SErrorCodigoBarrasStockNoEncontrado =
    'Código de barras no encontrado: %s';
  SErrorEntradaStockNoEncontrada =
    'No se encontró "%s" como artículo, SKU, código de barras ni referencia ' +
    'de proveedor.';
  SErrorSkuCeldaStockNoEncontrado =
    'No se ha encontrado un SKU activo para la celda seleccionada.';
  SErrorCeldaStockVariosSkus =
    'La celda seleccionada coincide con varios SKUs. Acote color, talla o ' +
    'almacén antes de agregarla.';
  SErrorArticuloStockNoSeleccionadoOperaciones =
    'Seleccione primero un artículo.';
  SErrorCeldaTallaStockNoSeleccionada =
    'Seleccione una celda de talla.';
  SErrorColumnaTallaStockNoSeleccionada =
    'Seleccione una columna de talla.';
  SErrorFilaStockNoIdentificada =
    'No se ha podido identificar la fila seleccionada.';
  SErrorColorStockNoUnico =
    'Seleccione un único color o cambie a la vista Por colores.';
  SErrorTallaStockVariosSkus =
    'La talla seleccionada corresponde a varios SKU. Seleccione un único ' +
    'color o use la vista Por colores.';
  SErrorArticuloStockNoSeleccionadoDocumento =
    'Seleccione primero un artículo.';
  SErrorEstadoStockNoEsExistencias =
    'Cambie el estado a Existencias para agregar stock disponible.';
  SErrorCeldaStockNoSeleccionada =
    'Seleccione una celda de stock.';
  SErrorCeldaCantidadStockNoSeleccionada =
    'Seleccione una celda de cantidad.';
  SErrorFilaExistenciasStockNoSeleccionada =
    'Seleccione la fila de Existencias para agregar stock disponible.';
  SErrorColumnaStockDocumentoNoSeleccionada =
    'Seleccione una columna de talla o una columna Total sin tallas.';
  SErrorGrupoFilaStockNoLeido =
    'No se ha podido leer el grupo de la fila.';
  SErrorAlmacenStockNoUnico =
    'Seleccione un solo almacén para agregar una unidad concreta.';
  SErrorColorStockUnidadNoUnico =
    'Seleccione un solo color para agregar una unidad concreta.';
  STituloConsultaStock = 'Consulta de stock';
  // FZ-ISSUE-251: detalle de traspasos pendientes en la consulta de stock.
  STituloTraspasosPendientesStock =
    'Traspasos pendientes';
  SSinTraspasosPendientesStock =
    'No hay traspasos pendientes de %s.';
  SCabeceraTraspasosPendientesStock =
    'Traspasos pendientes de %s (tipo, documento, origen > destino, SKU, ' +
    'cantidad):';
  SLineaTraspasoPendienteStock =
    '%s %s: %s > %s, %s, %s';
  SResumenTraspasosPendientesAlmacen =
    'Almacén %s: pendiente de traspasar %s, pendiente de recibir %s.';
  STipoTraspasoPendienteSolicitud =
    'Solicitud';
  STipoTraspasoPendientePropuesta =
    'Propuesta';
  STipoTraspasoPendienteTransito =
    'En tránsito';
  SErrorArticuloStockNoSeleccionadoFotos =
    'Seleccione primero un artículo.';
  SInfoArticulosRelacionadosStockNoDisponibles =
    'No hay otros artículos con stock para este filtrado.';
  SErrorTarifaNoSeleccionada =
    'Selecciona primero una tarifa.';
  SPreguntaGuardarTarifaAntesContinuar =
    'La tarifa actual está en edición. ¿Guardar antes de continuar?';
  SErrorSesionTarifaNoSeleccionada =
    'Selecciona o crea primero una sesión.';
  SInfoLineaSesionTarifaRecalculada = '1 línea recalculada.';
  SInfoLineasSesionTarifaRecalculadas =
    '%d líneas recalculadas.';
  SErrorCalcularSesionTarifa =
    'No se pudo calcular la sesión: %s';
  SPreguntaAplicarSesionTarifa =
    'Se aplicarán a la tarifa destino los precios de la rejilla ' +
    '(%d líneas, solo las marcadas con Aplicar = S). ¿Continuar?';
  SErrorAplicarSesionTarifa =
    'No se pudo aplicar la sesión: %s';
  SInfoLineasSesionTarifaAplicadas =
    '%d líneas aplicadas.';
  SErrorAlmacenesSoloStockAddBlock =
    'Has activado "Solo con stock" pero no hay almacenes seleccionados en ' +
    'la pestaña Almacenes.';
  SErrorAlmacenesVentasAddBlock =
    'Selecciona al menos un almacén de ventas para aplicar el filtro ' +
    'de histórico de ventas.';
  SInfoArticulosYaCargadosAddBlock =
    'Todos los artículos del filtro ya están cargados. Nada que insertar.';
  SInfoArticulosAnadidosAddBlock =
    '%d artículos añadidos correctamente.';
  SErrorDestinoInventarioAddBlock =
    'No se ha recibido la clave del inventario destino.';
  SPreguntaConfirmarInventarioAddBlock =
    'Se van a añadir %d artículos al inventario %s/%s/%s/%s.' + sLineBreak +
    'Cada artículo generará una línea por cada SKU con stock>0.' + sLineBreak +
    'Las cantidades teóricas se calcularán después con "Recalcular ' +
    'teórico/PMP".' + sLineBreak + sLineBreak + '¿Continuar?';
  // FZ-ISSUE-622: confirmación sin la casilla «Sólo artículos con stock».
  SPreguntaConfirmarInventarioAddBlockTodos =
    'Se van a añadir %d artículos al inventario %s/%s/%s/%s.' + sLineBreak +
    'Cada artículo generará una línea por cada SKU, tenga o no stock.' +
    sLineBreak +
    'Las cantidades teóricas se calcularán después con "Recalcular ' +
    'teórico/PMP".' + sLineBreak + sLineBreak + '¿Continuar?';
  SInfoLineasInventarioAddBlock =
    '%d líneas añadidas al inventario.' + sLineBreak +
    'Recuerda pulsar "Recalcular teórico/PMP" para rellenar las cantidades.';
  SErrorInsertarLineasInventarioAddBlock =
    'Error al insertar líneas de inventario: ';
  SErrorTarifaDestinoAddBlockNoSeleccionada =
    'Selecciona la tarifa destino antes de previsualizar.';
  SErrorTarifaOrigenAddBlockNoSeleccionada =
    'Selecciona la tarifa origen para copiar precios.';
  SErrorTarifasAddBlockCoincidentes =
    'La tarifa origen no puede ser la misma que la tarifa destino.';
  SErrorMultiploAjusteAddBlockNoValido =
    'El multiplo del ajuste debe ser mayor que 0.';
  SPreguntaConfirmarTarifaAddBlock =
    'Se van a insertar %d artículos en la tarifa "%s". ¿Continuar?';
  SInfoArticulosTarifaAddBlockAnadidos =
    '%d artículos añadidos a la tarifa correctamente.';
  SErrorInsertarTarifaAddBlock =
    'Error al insertar: ';
  SPreguntaQuitarPropiedadArticulo =
    '¿Quitar la propiedad "%s" de este artículo?';
  SErrorArticuloNoGuardadoValoresColor =
    'Primero guarde el artículo antes de fijar valores por color.';
  SErrorArticuloNoGuardadoAnadirPropiedades =
    'Primero guarde el artículo antes de añadir propiedades.';
  SErrorPropiedadObligatoriaFamilia =
    'La propiedad "%s" es obligatoria para esta familia.';
  SErrorPrecioCosteMargenNoValido =
    'El precio de coste debe ser mayor que cero.';
  // Margen de las tarifas: sobre venta o coeficiente (FZ-ISSUE-315).
  SErrorMargenVentaNoValido =
    'El margen sobre venta debe ser mayor o igual que cero y menor ' +
    'que 100.';
  SErrorCoeficienteMargenNoValido =
    'El coeficiente debe ser mayor que cero.';
  SCaptionMargenVenta =
    'Margen s/venta %';
  SCaptionColumnaMargenVenta =
    'Margen s/venta';
  SCaptionCoeficienteMargen =
    'Coeficiente';
  SFormulaMargenVenta =
    'precio = ceil(coste ÷ (1 − margen/100) ÷ ajuste) × ajuste − menos';
  SFormulaMargenVentaIva =
    'precio = ceil(coste ÷ (1 − margen/100) × (1 + %s %% IVA) ÷ ' +
    'ajuste) × ajuste − menos';
  SFormulaCoeficienteMargen =
    'precio = ceil(coste × coeficiente ÷ ajuste) × ajuste − menos';
  SErrorAjusteMargenNoValido =
    'El ajuste no puede ser negativo.';
  SErrorGuardarCambiosMargen =
    'No se han podido guardar los cambios: ';
  SErrorProveedorPrincipalCosteNoAsignado =
    'El artículo no tiene un proveedor marcado como principal. Asigna uno ' +
    'en la pestaña Proveedores antes de guardar el coste.';
  SPreguntaConfirmarCargaSesionTarifa =
    'Se van a cargar %d artículos en la sesión. ¿Continuar?';
  SInfoArticulosCargadosSesionTarifa =
    '%d artículos cargados en la sesión.';
  SErrorCargarSesionTarifa =
    'Error al cargar la sesión: ';
  SErrorTarifaEtiquetasNoSeleccionada =
    'Seleccione una tarifa antes de imprimir.';
  SInfoLayoutEtiquetasGuardado =
    'Layout guardado.';
  SPreguntaSuperarLimiteCargaArticulos =
    'Aún se cargarán %d artículos, por encima del límite recomendado de %d.' +
    sLineBreak + 'La carga puede tardar. ¿Continuar igualmente?';
  SErrorDimensionesSkuNoDefinidas =
    'No hay dimensiones definidas para este tipo de variación.';
  SErrorValoresSkuNoSeleccionados =
    'No has marcado ningún valor para generar SKUs.';
  SErrorValoresDimensionesSkuIncompletos =
    'Debes marcar al menos un valor en cada dimensión del artículo.' +
    sLineBreak + 'Falta marcar valores en: %s';
  SErrorCodigosSkuDemasiadoLargos =
    'Estos códigos de SKU superan los %d caracteres admitidos y no se ' +
    'pueden crear:' + sLineBreak + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Acorta el nombre de alguno de sus valores.';
  SInfoSkusMarcadosYaExisten =
    'Todas las combinaciones marcadas ya existen como SKU de este ' +
    'artículo. No hay nada que generar.';
  SPreguntaGenerarSkus =
    'SKU nuevos que se van a crear: %d' + sLineBreak + sLineBreak + '%s' +
    sLineBreak + sLineBreak +
    'Combinaciones marcadas que ya existían (no se tocan): %d' +
    sLineBreak + sLineBreak + '¿Continuar?';
  STextoRestoCodigosSku =
    '... y %d más';
  SAvisoSkusCreadosParcialmente =
    'Se han creado %d de los %d SKU previstos. El resto ya existía.';
  STituloNuevoValorAtributo =
    'Nuevo valor "%s"';
  // Las preguntas de InputQuery van cortas a propósito: la VCL ensancha el
  // diálogo hasta casi el doble de su pregunta más larga.
  STituloAnadirValorDimensionSku =
    'Añadir valor a "%s"';
  SEtiquetaNombreValorSku =
    'Nombre:';
  SEtiquetaOrdenValorSku =
    'Orden:';
  SEtiquetaOrdenDeSku =
    'Orden de "%s":';
  SErrorValorNuevoSkuNoValido =
    'Indica el nombre del valor y un orden entero mayor o igual que 0 ' +
    '(10, 20, 30...).';
  SNotaOrdenGlobalValorSku =
    'ATENCIÓN: el orden %d será global y afectará a todos los artículos ' +
    'que usen este valor en el futuro.';
  SErrorDimensionSkuNoSeleccionada =
    'Selecciona arriba la dimensión (color, talla...) a la que quieres ' +
    'añadir el valor.';
  SInfoValorSkuYaListado =
    'El valor "%s" ya estaba en la lista de "%s". Se ha marcado para ' +
    'generar sus SKU.';
  SOpcionSinConjuntoSku =
    '— Sin conjunto —';
  SPreguntaAltaValorAtributo =
    '¿Dar de alta el valor "%s"?';
  SPreguntaGuardarValorSkuGlobal =
    'Va a utilizar el valor "%s".' + sLineBreak + sLineBreak +
    '¿Desea guardarlo de forma permanente en el conjunto global "%s" para ' +
    'que aparezca disponible siempre para otros artículos?' + sLineBreak +
    sLineBreak + '[SÍ] -> Añadir al conjunto global' + sLineBreak +
    '[NO] -> Usar SOLO ESTA VEZ para generar el SKU (no se guarda en el ' +
    'conjunto)';
  SPreguntaUsarValorSkuTemporal =
    'El artículo no tiene un conjunto global asignado.' + sLineBreak +
    sLineBreak + 'El valor "%s" se utilizará SOLO ESTA VEZ para generar el ' +
    'SKU de este artículo, pero no se guardará en ninguna lista de ' +
    'conjuntos.' + sLineBreak + sLineBreak + '¿Desea continuar?';
  STituloCambiarOrdenValorSku =
    'Cambiar orden del valor';
  SErrorOrdenValorSkuNoValido =
    'Por favor, introduce un número entero válido, (mayor o igual a 0).';
  SPreguntaCambiarOrdenValorSkuGlobal =
    'Este valor proviene de un sistema de colores o atributos (%s).' +
    sLineBreak + sLineBreak +
    'ATENCIÓN: Este cambio implica un cambio que puede afectar a otros ' +
    'artículos que compartan este sistema.' + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  STituloCambiarOrdenAtributoSku =
    'Cambiar orden';
  SErrorOrdenAtributoSkuNoValido =
    'Introduce un número entero mayor que 0.';
  // R02 - Textos de controles de artículos en ejecución
  STituloSeleccionTarifasArticulo =
    'Seleccione Tarifas a incorporar al artículo';
  SCaptionAnadirPropiedad = '+ Añadir propiedad';
  SCaptionTipoVariacion = 'Tipo de variación: ';
  SCaptionNombreOrden = '%s, orden %s';
  // R05 - Visor de fotos de artículo
  SCaptionControlesExpandido = '▲ Controles';
  SCaptionControlesContraido = '▼ Controles';
  SCaptionFotoDelSku = 'Foto del SKU: %s';
  SCaptionFotoHeredadaGrupo = 'Foto heredada del grupo: %s';
  SCaptionFotoHeredadaArticulo = 'Foto heredada del artículo: %s';
  SCaptionSinFotoPara = 'Sin foto para %s%s';
  // R06 - Inventarios
  SCaptionTabDetalleInventarioSku =
    '&1. Detalle del inventario [SKU]';
  SCaptionTabDetalleInventarioDesglose =
    '&1. Detalle del inventario [Desglose]';
  SCaptionAtributoN = 'Atributo %d';
  // R08 - Consulta de stock y tarifas
  SCaptionModoSimplificado = 'Simplificado';
  SCaptionModoDesglosado = 'Desglosado';
  SHintCoincidenciasPara = 'Coincidencias para %s';
  SHintArticuloAnterior = 'Artículo anterior';
  SHintArticuloSiguiente = 'Artículo siguiente';
  SCaptionFotosMismaFamilia = 'Fotos misma familia';
  SCaptionFotosMismoProveedor = 'Fotos mismo proveedor';
  SCaptionFotosMismaTemporada = 'Fotos misma temporada';
  SCaptionColoresTallas = 'Colores: %s' + sLineBreak + 'Tallas: %s';
  SCaptionColColor = 'Color';
  SCaptionColAlmacen = 'Almacén';
  SCaptionColEstado = 'Estado';
  SCaptionColTotal = 'Total';
  SCaptionSesionesCambiosTarifa = 'Sesiones cambios tarifa';
  SCaptionRedondearHaciaArriba = 'Redondear hacia arriba';
  SCaptionCargarArticulos = 'Cargar artículos';
  SCaptionCalcularLineas = 'Calcular líneas';
  SCaptionAplicarTarifa = 'Aplicar tarifa';
  SCaptionRefrescar = 'Refrescar';
  SCaptionTabLineasTarifa = 'Líneas';
  SCaptionExportarExcelSesionTarifa = 'Exportar Excel';
  SCaptionCargarExcelSesionTarifa = 'Cargar Excel';
  SFiltroExcelSesionTarifa = 'Libro de Excel (*.xlsx;*.xls)|*.xlsx;*.xls';
  SNombreArchivoSesionTarifa = 'SesionTarifa_%d.xlsx';
  SNombreHojaExcelSesionTarifa = 'Sesión tarifa';
  STituloExcelSesionTarifa = 'SESION DE CAMBIO DE TARIFA';
  SCaptionSesionExcelSesionTarifa = 'Sesión:';
  SCaptionTarifaOrigenExcelSesionTarifa = 'Tarifa origen:';
  SCaptionTarifaDestinoExcelSesionTarifa = 'Tarifa destino:';
  SCaptionEstadoExcelSesionTarifa = 'Estado:';
  SErrorHojaSesionTarifaSinArticulo =
    'No se encuentra la columna "Artículo" en las primeras filas de la hoja.';
  SErrorHojaSesionTarifaVacia =
    'La hoja no tiene líneas con artículo.';
  SIncidenciaImporteSesionTarifaExcel =
    'Fila %d, artículo %s: el valor "%s" de la columna %s no es un ' +
    'importe válido.';
  SIncidenciaAplicarSesionTarifaExcel =
    'Fila %d, artículo %s: la columna Aplicar solo admite S o N ' +
    '(valor "%s").';
  SErrorCargarExcelSesionTarifa =
    'No se ha cargado nada. Revise estos valores del Excel:' + sLineBreak +
    '%s';
  SPreguntaCargarExcelSesionTarifa =
    'Se van a cargar %d líneas del Excel en la sesión. Las celdas vacías ' +
    'no modifican la línea. ¿Continuar?';
  SInfoExcelSesionTarifaCargado =
    'Excel cargado: %d líneas nuevas y %d actualizadas.';
  SErrorSesionTarifaAplicadaNoEditable =
    'La sesión ya está aplicada; no se puede cargar un Excel en ella.';
  // FZ-ISSUE-787: el coste de una sesión aplicada es el de su aplicación.
  SErrorSesionTarifaAplicadaNoActualizarCostes =
    'La sesión ya está aplicada: sus costes quedan como se aplicaron. ' +
    'Para recalcularlos, crea una sesión nueva.';
  SErrorSesionTarifaAplicadaNoBorrarLineas =
    'La sesión ya está aplicada; no se pueden borrar sus líneas.';
  SErrorTarifasCambiosSesionAplicadaLote =
    'La sesión ya está aplicada; no se pueden cambiar sus descuentos.';
  SCaptionMarcarTodoSesionTarifa = 'Marcar todo';
  SCaptionDesmarcarTodoSesionTarifa = 'Desmarcar todo';
  SErrorSeleccionVaciaSesionTarifa =
    'Selecciona al menos una línea para realizar la operación en lote.';
  SCaptionDescuentoLoteSesionTarifa = 'Descuento en lote';
  STituloDescuentoLoteSesionTarifa = 'Descuento en lote';
  SPreguntaPorcentajeDescuentoLoteSesionTarifa =
    '% de descuento sobre la salida nueva (0 quita el descuento):';
  SErrorPorcentajeDescuentoLoteSesionTarifa =
    'Escriba un porcentaje entre 0 y 100.';
  SPreguntaDescuentoLoteSesionTarifa =
    'Se aplicará un %s %% de descuento a %d líneas. ' +
    'El precio de salida no cambia. ¿Continuar?';
  SErrorLineasSinPrecioNuevoSesionTarifa =
    'Hay %d líneas marcadas para aplicar sin precio nuevo.' + sLineBreak +
    'Pulse "Calcular líneas" o ponga el descuento antes de aplicar.';
  // R09 - Modales de artículos, bloques y filtros
  SCaptionCeroArticulos = '0 artículos';
  SCaptionNumSeleccionados = '(%d sel.)';
  SCaptionSinAlmacenesSeleccionados = 'No hay almacenes seleccionados';
  SCaptionAlmacenesSeleccionados = '%d almacén(es) seleccionados';
  SCaptionArticulosCoincidenFiltro =
    '%d artículos coinciden con el filtro';
  SCaptionInventarioDestino = 'Inventario destino: %s / %s / %s / %s';
  STituloAnadirBloqueInventario =
    'Añadir Bloque - Carga masiva en Inventario';
  STituloAnadirBloqueTarifa = 'Añadir Bloque - Carga masiva en Tarifa';
  SHintQuitarPropiedad = 'Quitar propiedad %s';
  STituloAnadirPropiedades = 'Añadir propiedades';
  SCaptionTipoValorLista = 'Lista';
  SCaptionTipoValorTextoLibre = 'Texto libre';
  SCaptionTipoValorNumero = 'Número';
  SCaptionTipoValorBooleano = 'Sí/No';
  SCaptionPorColorSku = 'Por color/SKU…';
  SCaptionPorColor = 'Por color…';
  SHintFijarPropiedadPorColorSku = 'Fijar %s por color/SKU';
  SCaptionSinColoresSkuDefinidos =
    'El artículo no tiene colores/SKU definidos aún.';
  STituloCargarArticulosSesionTarifas =
    'Cargar artículos en sesión de tarifas';
  SCaptionDistribucionKit = 'Distribución almacén / talla  -  Kit %s';
  SCaptionColKit = 'Kit %s';
  SCaptionDocumentoEtiqueta = 'Documento:';
  SCaptionCalcularNumero = 'Calcular nº';
  SCaptionSeCargaranArticulos =
    'Se cargarán %d artículos (límite %d).';
  SCaptionDemasiadosArticulosFiltro =
    'Hay demasiados artículos para cargarlos de golpe (más de %d). ' +
    'Marque temporada y/o proveedor para acotar la carga; pulse ' +
    '"Calcular nº" para ver cuántos quedarían. "Aceptar" carga la ' +
    'selección; "Cancelar" carga el filtro por defecto.';
  // R10 - Informes de balance
  SCaptionGrupoModo = ' Modo ';
  SCaptionModoEntreFechas = 'Entre fechas';
  SCaptionModoPorAcumulados = 'Por acumulados';
  SCaptionGrupoDetalle = ' Detalle ';
  // R15 - Librerías de grids y columnas
  SCaptionTipoVariacionDetalle = 'Tipo de variación: %s — %s';
  SCaptionColSkuArtColorTalla = 'SKU (Artículo/Variantes)';
  SCaptionColSku = 'SKU';
  SCaptionColArticulo = 'Artículo';
  SCaptionColArticuloSku = 'Artículo / SKU';
  SCaptionColTipoCantidad = 'Unidad';
  SCaptionColTipoFila = 'Tipo';
  SCaptionColCantidad = 'Cantidad';
  SErrorCantidadDecimalesUnidad =
    'La unidad «%s» admite como máximo %d decimales.';
  SErrorCantidadSinDecimalesUnidad =
    'La unidad «%s» no admite decimales.';
  SErrorCantidadSeparadorAmbiguo =
    'La cantidad «%s» no es válida: use un solo separador decimal ' +
    '(«,» o «.») y ningún separador de miles.';
  SAvisoTituloCantidad = 'Cantidad';
  SAvisoCantidadSeparadorRepetido =
    'Ya hay un separador decimal: use «,» o «.» una sola vez y ningún ' +
    'separador de miles.';
  SAvisoCantidadSinDecimales = 'Esta cantidad no admite decimales.';
  SAvisoCantidadDecimalesMaximos =
    'Esta cantidad admite como máximo %d decimales.';
  SCaptionColTallaN = 'Talla %d';
  SCaptionColUnidadesSinTallaje = 'Uds.';
  SCaptionColDescripcion = 'Descripción';
  SCaptionColCodigoBarras = 'Cód. barras';
  SCaptionColRefProveedor = 'Ref. prov.';
  SCaptionColStock = 'Stock';
  SCaptionSaldoStockMovimiento = 'Saldo';
  SCaptionSinArticulos = 'No hay artículos';
  // R07 - Movimientos de almacén
  SCaptionCargandoMovimientos = 'Cargando movimientos...';
  SCaptionCargandoMovimientosProgreso =
    'Cargando movimientos: %s / %s';
  STituloBuscarArticulosInventario = 'Búsqueda de Artículos';
  STituloBuscarSkusInventario = 'Búsqueda de SKUs';
  SCaptionCodigoBusquedaInventario = 'Código';
  SCaptionDescripcionBusquedaInventario = 'Descripción';
  SCaptionFamiliaBusquedaInventario = 'Familia';
  SCaptionTemporadaBusquedaInventario = 'Temporada';
  SCaptionProveedorBusquedaInventario = 'Proveedor';
  SCaptionReferenciaProveedorBusquedaInventario = 'Ref. proveedor';
  SCaptionPrecioCompraBusquedaInventario = 'P. compra';
  SCaptionPrecioVentaBusquedaInventario = 'P. venta';
  SCaptionTipoCantidadBusquedaInventario = 'Tipo cant.';
  SCaptionSkuBusquedaInventario = 'SKU';
  SCaptionArticuloBusquedaInventario = 'Artículo';
  SCaptionAtributosBusquedaInventario = 'Atributos';
  SCaptionStockBusquedaInventario = 'Stock';
  SCaptionPrecioMedioBusquedaInventario = 'PMP';

  SFiltroArchivoImportacionRecuentoInventario =
    'Excel (*.xlsx)|*.xlsx|CSV (*.csv;*.txt)|*.csv;*.txt|' +
    'Todos (*.*)|*.*';

  SNombreArchivoInventario = 'Inventario_%s_%s';
  SFiltroArchivoImportacionInventario =
    'Archivos Excel (*.xlsx;*.xls)|*.xlsx;*.xls|' +
    'Archivos CSV (*.csv;*.txt)|*.csv;*.txt|Todos|*.*';

  SCaptionExcluirArticulosYaEnInventario =
    'Excluir artículos ya en el inventario';

  SNombreArchivoSimulacionValoracion = 'Valoracion_simulada';

  SErrorResolucionValidacionInventariosNoDisponible =
    'No se proporcionó la resolución y validación de artículos de inventario.';
  SErrorAtributosInventariosNoDisponibles =
    'No se proporcionó la lectura de atributos de artículos de inventario.';
  SErrorAtributosGlobalesInventariosNoDisponibles =
    'No se proporcionaron los nombres globales de atributos de inventario.';
  SErrorColumnasSkuInventariosNoDisponibles =
    'No se proporcionaron los servicios de columnas SKU de inventario.';
  SErrorBusquedasInventariosNoDisponibles =
    'No se proporcionaron las búsquedas de inventario.';
  SErrorRecuentoRemotoInventariosNoDisponible =
    'No se proporcionó el repositorio de recuento remoto de inventario.';
  SErrorInventarioNubeNoDisponible =
    'No se proporcionó la persistencia del inventario en la nube.';
  SErrorCargaMasivaInventarioNoDisponible =
    'No se proporcionó la carga masiva de artículos de inventario.';

  // Traducciones de inventarios y documentos (D34).
  SCaptionDescripcionColumnaInventario =
    'Descripción';
  SCaptionUnidadesTeoricasInventario =
    'Uds. teóricas';
  SCaptionRecuentoInventario =
    'Recuento';
  SCaptionPmpActualInventario =
    'PMP actual';
  SCaptionPmpNuevoInventario =
    'PMP nuevo';
  SCaptionPmpManualInventario =
    'PMP manual';
  SCaptionDiferenciaUnidadesInventario =
    'Dif. uds.';
  SCaptionDiferenciaCosteInventario =
    'Dif. coste';
  SCaptionUnidadesRegularizadasInventario =
    'Uds. regul.';
  SCaptionHoraRecuentoInventario =
    'Hora recuento';
  SAvisoMovimientosPosterioresRecuentoInventario =
    'Hay movimientos posteriores al recuento. Revise la fecha y hora ' +
    'del recuento antes de regularizar el inventario.';
  // FZ-ISSUE-619: sobrantes de SKU sin precio medio en el almacén.
  SInfoCostesSobrantesPropuestosInventario =
    '%d líneas con sobrante no tenían precio medio en el almacén: se ' +
    'valoran con el coste conocido del SKU (PMP de la empresa, última ' +
    'compra o precio de coste del artículo). Puedes cambiarlo en ' +
    '«PMP nuevo».';
  SAvisoSobrantesSinCosteInventario =
    '%d líneas con sobrante siguen sin coste: el SKU no tiene PMP en la ' +
    'empresa, ni compras, ni precio de coste. Indica su «PMP nuevo» ' +
    'antes de regularizar o entrarán al almacén a coste 0.';
  SPreguntaSobrantesSinCosteInventario =
    '%d líneas con sobrante no tienen coste («PMP nuevo» 0,00): sus ' +
    'unidades entrarán al almacén a coste 0 y bajarán el valor del ' +
    'stock.' + sLineBreak + sLineBreak +
    '¿Regularizar el inventario de todos modos?';
  SHintStockTeoricoInventario =
    'Stock que el sistema cree que hay en el almacén';
  SHintRecuentoInventario =
    'Lo que realmente has contado';
  SHintPmpNuevoInventario =
    'Precio Medio que tendrá el SKU tras aplicar el inventario';
  SHintUnidadesRegularizadasInventario =
    'Solo se rellena cuando el inventario está APLICADO';
  SCaptionFechaRecuentoExcelInventario =
    'Fecha y hora recuento';
  STituloExcelInventario =
    'INVENTARIO';
  SNombreHojaExcelInventario =
    'Inventario';
  SCaptionEmpresaExcelInventario =
    'Empresa:';
  SCaptionAlmacenExcelInventario =
    'Almacén:';
  SCaptionSerieExcelInventario =
    'Serie:';
  SCaptionNumeroExcelInventario =
    'Número:';
  SCaptionFechaExcelInventario =
    'Fecha:';
  SCaptionEstadoExcelInventario =
    'Estado:';
  SCaptionDescripcionExcelInventario =
    'Descripción:';
  SCaptionLineaExcelInventario =
    'Línea';
  SCaptionArticuloExcelInventario =
    'Artículo';
  SCaptionDescripcionColExcelInventario =
    'Descripción';
  SCaptionLoteExcelInventario =
    'Lote';
  SCaptionCaducidadExcelInventario =
    'Caducidad';
  SCaptionTeoricasExcelInventario =
    'Uds. teór.';
  SCaptionFisicasExcelInventario =
    'Uds. físicas';
  SCaptionDiferenciaExcelInventario =
    'Diferencia';
  SCaptionPmpActualExcelInventario =
    'PMP actual';
  SCaptionPmpNuevoExcelInventario =
    'PMP nuevo';
  SCaptionCosteExcelInventario =
    'Dif. coste';
  SCaptionTotalesExcelInventario =
    'TOTALES';
  SErrorHojaInventarioVacia =
    'La hoja está vacía o no tiene datos.';
  SInfoLineasLeidasExcelInventario =
    'Leídas %d líneas (%d vacías ignoradas).';

  SErrorCosteTarifaNegativo =
    'El precio de coste de la tarifa no puede ser negativo.';
  SErrorProveedorTarifaInexistente =
    'El código de proveedor de la tarifa no existe.';
  SInfoTallaCualquierColorTarifa =
    '%s    Talla: %s (cualquier color)';
  // FZ-ISSUE-627: la calculadora de margen identifica las filas de talla
  // («art/*/talla») y de color («art/color»), que no son un SKU.
  // Ejemplo: «Talla 30, cualquier color (ZINF00001/*/30)».
  SInfoReglaTarifaMargen =
    '%s %s, cualquier %s (%s)';
  // FZ-ISSUE-439: lo mismo cuando la variación del artículo llama a sus
  // ejes de otra forma (SKU, eje pivote, valor, eje de fila).
  SInfoSkuEjePrecioTarifa =
    '    %s    %s: %s';
  SInfoEjeCualquierValorTarifa =
    '%s    %s: %s (cualquier %s)';
  SCaptionSeleccioneSkuEjesTarifa =
    ' 1. Seleccione el artículo, un valor de %s o de %s:';
  SRotuloValorFilaSku = 'fila';
  SCaptionActivarSkusValorEje =
    'Activar todos los SKU con este valor de %s';
  SCaptionDesactivarSkusValorEje =
    'Desactivar todos los SKU con este valor de %s';

  // Etiquetas de artículo y de documentos (FZ-ISSUE-093/098/101)
  SAvisoEtiquetasSinUnidades =
    'No hay ninguna etiqueta que imprimir con las opciones elegidas. ' +
    'Revise los almacenes marcados: en un documento filtran sus líneas ' +
    'y en la ficha del artículo, el stock.';
  SPreguntaEtiquetasSkusSinCodigoBarras =
    'Hay %d SKU sin código de barras: sus etiquetas saldrán sin él. ' +
    '¿Imprimir de todas formas?';
  // FZ-ISSUE-118
  SPreguntaEtiquetasSkusSinPrecio =
    '%d SKU no tienen precio en la tarifa %s (%s): sus etiquetas ' +
    'saldrían sin importe.' + sLineBreak + sLineBreak +
    '¿Omitir esas etiquetas e imprimir las demás? ' +
    'Si responde No, se cancela la impresión.';
  SAvisoEtiquetasNingunSkuConPrecio =
    'Ningún SKU de las etiquetas tiene precio en la tarifa %s. ' +
    'Elija otra tarifa o dé de alta los precios.';
  STituloImpresionEtiquetasBorradorCompra =
    'Impresión de Etiquetas de Borrador de Compra';

  SErrorColorBasicoEnUso =
    'No se puede borrar este color porque está en uso. ' +
    'Puede cambiar su nombre o su paleta, o desactivarlo.';
  SErrorAtributoBasicoEnUso =
    'No se puede borrar este atributo básico porque está en uso.';
  SErrorCodigoColorBasicoInmutable =
    'El código de un color guardado no se puede cambiar. ' +
    'Puede modificar su nombre o su paleta.';
  SErrorPaletaColorBasicoInvalida =
    'Elija un color con el botón de paleta o escriba un valor ' +
    'con el formato #RRGGBB.';
  SErrorSoloColoresBasicos =
    'Este mantenimiento solo admite colores básicos.';

resourcestring
  STituloEnviarDocumentoCorreo =
    'Enviar %s por correo electrónico';
  SSolicitudEmailDocumento =
    'Correo electrónico:';
  SBotonConfirmarEnvioDocumento =
    'Confirmar envío';
  SBotonCancelarEnvioDocumento =
    'Cancelar';
  SErrorEmailDocumentoVacio =
    'Indique una dirección de correo electrónico.';
  SErrorEmailDocumentoInvalido =
    'La dirección de correo electrónico no es válida.';
  SAvisoPdfTemporalCorreoNoEliminado =
    'No se pudo eliminar el PDF temporal usado para el correo: %s';
  SNombreCorreoTicket =
    'ticket';
  SNombreCorreoFactura =
    'factura';
  SNombreCorreoPresupuesto =
    'presupuesto';
  SNombreCorreoPedido =
    'pedido';
  SNombreCorreoAlbaran =
    'albarán';
  SNombreCorreoPedidoCompra =
    'pedido de compra';
  SNombreCorreoAlbaranCompra =
    'albarán de compra';
  SNombreCorreoDevolucionCompra =
    'devolución de compra';
  SNombreCorreoFacturaCompra =
    'factura de compra';
  SInfoAplicacionDescuentoGuardada =
    'Aplicación del descuento guardada';
  SCaptionAplicacionDescuento =
    'Aplicación del descuento';
  SCaptionAplicarDescuento =
    'Aplicar descuento';
  SCaptionCondicionDtoTodos =
    'Todos';
  SCaptionCondicionDtoSoloSi =
    'Solo si';
  SCaptionCondicionDtoExcepto =
    'Todos excepto';
  SCaptionCondicionDtoPropiedad =
    'Propiedad';
  SCaptionCondicionDtoValores =
    'Valores';
  SAyudaCondicionDescuento =
    'Criterio conservador: si el artículo o SKU no tiene un' +
    ' valor efectivo para la propiedad seleccionada, no se ' +
    'aplica el descuento.';
  SCaptionGuardarAplicacionDto =
    'Guardar aplicación';
  SStockInfoSi =
    'Sí';
  SStockInfoNo =
    'No';
  SStockInfoTarifaDefecto =
    'Tarifa por defecto - ';
  SStockInfoProveedorPrincipal =
    'Proveedor ppal. - ';
  SStockInfoProveedor =
    'Proveedor - ';
  SStockInfoReferencia =
    ' (ref ';
  SCaptionCambioTarifaNombre =
    'Nombre';
  SCaptionCambioTarifaFecha =
    'Fecha';
  SCaptionCambioTarifaEstado =
    'Estado';
  SCaptionCambioTarifaOrigen =
    'Tarifa origen';
  SCaptionCambioTarifaDestino =
    'Tarifa destino';
  SCaptionCambioTarifaDesde =
    'Desde';
  SCaptionCambioTarifaHasta =
    'Hasta';
  SCaptionCambioCampoOrigen =
    'Origen';
  SCaptionCambioCampoDestino =
    'Destino';
  SCaptionCambioAplicar =
    'Aplicar';
  SCaptionCambioValor =
    'Valor';
  SCaptionCambioRedondeo =
    'Redondeo';
  SCaptionCambioMenos =
    'Menos';
  SCaptionCambioCodigo =
    'Código';
  SCaptionCambioAplicacion =
    'Aplicacion';
  SCaptionCambioArticulo =
    'Artículo';
  SCaptionCambioDescripcion =
    'Descripción';
  SCaptionCambioFamilia =
    'Familia';
  SCaptionCambioProveedor =
    'Proveedor';
  SCaptionCambioPrecioOrigen =
    'P. origen';
  SCaptionCambioCoste =
    'Coste';
  SCaptionCambioSalidaActual =
    'Salida actual';
  SCaptionCambioFinalActual =
    'Final actual';
  SCaptionCambioSalidaNueva =
    'Salida nueva';
  SCaptionCambioDtoNuevo =
    'Dto nuevo';
  SCaptionCambioPorcentajeDto =
    '% dto nuevo';
  SCaptionCambioFinalNuevo =
    'Final nuevo';
  SCaptionCambioMensaje =
    'Mensaje';
  SCaptionCambioIrArticulo =
    'Ir a artículo';
  SCaptionTabPruebaPrecio =
    'Prueba de precio';
  SCaptionPruebaPrecioSku =
    'SKU';
  SCaptionPruebaPrecioTarifa =
    'Tarifa';
  SCaptionPruebaPrecioFecha =
    'Fecha';
  SCaptionPruebaPrecioCalcular =
    'Calcular precio';
  SAyudaPruebaPrecio =
    'Calcula el precio como la caja, con tus parámetros de caja. ' +
    'Sin tarifa: la de un ticket sin cliente.';
  SErrorPruebaPrecioSinSku =
    'Indica un artículo, SKU o código de barras.';
  SErrorPruebaPrecioNoEncontrado =
    'No se encuentra "%s".';
  SErrorPruebaPrecioRequiereSku =
    'El artículo "%s" tiene variantes: indica el SKU completo.';
  SPruebaPrecioArticulo =
    'Artículo: %s · SKU: %s · %s';
  SPruebaPrecioTarifaTicket =
    'Tarifa del ticket: %s';
  SPruebaPrecioPeriodicaActiva =
    '%s (tarifa periódica automática vigente)';
  SPruebaPrecioTarifaAplicada =
    'Precio de la tarifa: %s';
  SPruebaPrecioRespaldo =
    '%s (respaldo: sin precio en %s)';
  // FZ-ISSUE-942: la caja descarta la tarifa pedida (ResolverTarifaVentaCaja).
  SPruebaPrecioTarifaDescartada =
    'La tarifa %s no se puede usar en caja (inactiva o sin IVA incluido): ' +
    'la caja cobra con %s.';
  SPruebaPrecioSinPrecio =
    'Sin precio válido: la caja no podría vender este artículo ese día.';
  SPruebaPrecioSalida =
    'Precio de salida: %s';
  SPruebaPrecioDescuento =
    'Descuento de la línea: %s';
  SPruebaPrecioVenta =
    'Precio de venta: %s';
  SPruebaPrecioVigencia =
    'Vigencia del precio: %s - %s';
  SPruebaPrecioSinLimite =
    'sin límite';
  SPruebaPrecioOrigenSku =
    'Precio propio del SKU';
  SPruebaPrecioOrigenArticulo =
    'Precio heredado del artículo';
  // Periodos de las sesiones de cambio de tarifa (FZ-ISSUE-944).
  SCaptionPeriodosTarifa =
    'Periodos';
  SCaptionAnadirPeriodoTarifa =
    'Añadir periodo';
  SCaptionEliminarPeriodoTarifa =
    'Eliminar periodo';
  SCaptionVerPeriodosTarifa =
    'Ver periodos';
  SCaptionOcultarPeriodosTarifa =
    'Ocultar periodos';
  SCaptionPeriodoTarifaNumero =
    'Nº';
  SCaptionPeriodoTarifaNombre =
    'Periodo';
  SAyudaPeriodosTarifa =
    'Cada periodo aplica sus precios solo entre sus fechas; fuera de ' +
    'ellas vuelve el precio anterior. Con periodos, la cabecera solo ' +
    'indica las tarifas.';
  SNombrePeriodoTarifaDefecto =
    'Etapa %d';
  SInfoPeriodoTarifaAnadido =
    'Periodo %d añadido (%s - %s). Calcula sus líneas antes de aplicar ' +
    'la sesión.';
  SPreguntaEliminarPeriodoTarifa =
    '¿Eliminar el periodo %d «%s» y sus líneas?';
  SPreguntaEliminarUltimoPeriodoTarifa =
    '¿Eliminar el periodo %d «%s»? Es el último: sus líneas vuelven a ' +
    'la sesión, que deja de ser por periodos.';
  SErrorPeriodoTarifaNoSeleccionado =
    'Selecciona un periodo.';
  SErrorPeriodoTarifaSinFechas =
    'El periodo %d necesita fecha desde y fecha hasta.';
  SErrorPeriodoTarifaFechasInvertidas =
    'En el periodo %d la fecha hasta (%s) es anterior a la fecha ' +
    'desde (%s).';
  SCaptionEliminarLineasSinStockSesion =
    'Borrar líneas sin stock';
  SPreguntaEliminarLineasSinStockSesion =
    '¿Borrar las %d líneas sin stock (0 o negativo)? Si la sesión tiene ' +
    'periodos, se quitan de todos.';
  SPreguntaEliminarUnaLineaSinStockSesion =
    '¿Borrar la línea sin stock (0 o negativo)? Si la sesión tiene ' +
    'periodos, se quita de todos.';
  SInfoSesionSinLineasSinStock =
    'No hay líneas sin stock en la sesión.';
  SErrorPeriodoTarifaSolapaPrecio =
    'El periodo %s - %s no se puede aplicar a %s en la tarifa %s: se ' +
    'solapa con otro precio con fechas (%s - %s). En una tarifa no puede ' +
    'haber dos precios vigentes el mismo día.';
  SErrorPeriodoTarifaSolapado =
    'El periodo %d (%s - %s) se solapa con el periodo %d (%s - %s): ' +
    'dos periodos de una sesión no pueden coincidir en ningún día.';

resourcestring
  SCaptionBusquedaTodosCampos =
    'Todos los campos';
  SCaptionBusquedaCodigoArticulo =
    'Código de artículo';
  SCaptionBusquedaSku =
    'SKU';
  SCaptionBusquedaDescripcion =
    'Descripción';
  SCaptionBusquedaTalla =
    'Talla';
  SCaptionBusquedaColor =
    'Color';
  SCaptionBusquedaCodigoBarras =
    'Código de barras';
  SCaptionBusquedaFamilia =
    'Familia';
  SCaptionBusquedaProveedor =
    'Proveedor';
  SCaptionBusquedaReferenciaProveedor =
    'Referencia proveedor';
  SCaptionBusquedaTemporada =
    'Temporada';
  SCaptionBusquedaAlmacen =
    'Almacén';
  SCaptionBusquedaAtributosPropiedades =
    'Atributos y propiedades';
  SCaptionBusquedaColorBasico =
    'Color básico';
  SCaptionBusquedaProximidadPaleta =
    'Proximidad de paleta';
  SCaptionBusquedaContiene =
    'Contiene';
  SCaptionBusquedaEmpieza =
    'Empieza por';
  SCaptionBusquedaIgual =
    'Es igual a';
  SCaptionBusquedaTermina =
    'Termina en';
  SCaptionBusquedaNoContiene =
    'No contiene';
  SCaptionBusquedaSoloActivos =
    'Solo activos';
  SCaptionBusquedaTodos =
    'Todos';
  SCaptionBusquedaSoloInactivos =
    'Solo inactivos';
  SCaptionBusquedaCualquierStock =
    'Cualquier stock';
  SCaptionBusquedaConExistencias =
    'Con existencias';
  SCaptionBusquedaSinExistencias =
    'Sin existencias';
  SCaptionBusquedaTodosOpcionales =
    '(Todos)';
  SCaptionBusquedaArticulo =
    'Artículo';
  SCaptionBusquedaCodigoBasico =
    'Código básico';
  SCaptionBusquedaHex =
    'HEX';
  SCaptionBusquedaDistanciaRgb =
    'Distancia RGB';
  SCaptionBusquedaStock =
    'Stock';
  SCaptionBusquedaStockAlmacen =
    'Stock almacén';
  SCaptionBusquedaAlmacenes =
    'Almacenes';
  SCaptionBusquedaNombreFamilia =
    'Nombre familia';
  SCaptionBusquedaNombreProveedor =
    'Nombre proveedor';
  SCaptionBusquedaMarca =
    'Marca';
  SCaptionBusquedaMaterial =
    'Material';
  SCaptionBusquedaGenero =
    'Género';
  SCaptionBusquedaAtributos =
    'Atributos';
  SCaptionBusquedaPropiedades =
    'Propiedades';
  SCaptionBusquedaArticuloActivo =
    'Artículo activo';
  SCaptionBusquedaSkuActivo =
    'SKU activo';
  SCaptionStockExistencias =
    'Existencias';
  SCaptionStockEntradas =
    'Entradas';
  SCaptionStockSalidas =
    'Salidas';
  SCaptionStockVentas =
    'Ventas';
  SCaptionStockRegularizadas =
    'Regulariz.';
  SCaptionStockEntradaTraspaso =
    'Ent. traspaso';
  SCaptionStockSalidaTraspaso =
    'Sal. traspaso';
  SCaptionStockPendienteRecibir =
    'Pte. recibir';
  SCaptionStockPendienteServir =
    'Pte. servir';
  SCaptionStockPrestadas =
    'Prestadas';
  SCaptionStockTodosEstados =
    'Todos los estados';
  SCaptionStockEntradaCompra =
    'Ent. compra';
  SCaptionStockEntradaDeposito =
    'Ent. depósito';
  SCaptionStockSalidaDeposito =
    'Sal. depósito';
  SCaptionStockAlbaranVenta =
    'Alb. venta';
  SCaptionStockAlbaranEntrada =
    'Alb. entrada';
  SCaptionStockPendienteTraspasar =
    'Pte. traspasar';
  SCaptionStockPendienteRecibirTraspaso =
    'Pte. recibir trasp.';
  SCaptionStockDisponible =
    'Disponible';
  SCaptionStockCodigoCaja =
    'Código';
  SCaptionStockTotalCaja =
    'Stock total';
  SErrorSeleccionarFilaSkuDocumentoTrabajo =
    'Seleccione una fila de SKU de la rejilla.';
  SErrorSeleccionarSkuDocumentoTrabajo =
    'Seleccione un SKU de la rejilla.';
  SErrorIdentificarArticuloSkuDocumentoTrabajo =
    'No se ha podido identificar el artículo y el SKU.';
  SErrorSeleccionarFilaSkuValidoDocumentoTrabajo =
    'Seleccione una fila que contenga un SKU válido.';
  SCaptionTodasLasFamilias =
    '(Todas)';
  SCaptionVariasFamiliasElegidas =
    '%d familias';
  SHintElegirFamiliasArbol =
    'Pulse el botón para elegir familias en el árbol';

resourcestring
  SInfoSkuTallaPrecioTarifa = '    %s    Talla: %s';

resourcestring
  SCaptionListadoVentasFecha =
    'Fecha';
  SCaptionListadoVentasDocumento =
    'Documento';
  SCaptionListadoVentasTipo =
    'Tipo';
  SCaptionEliminarLineasSesion = 'Borrar línea';
  SCaptionEliminarSesionCompleta = 'Eliminar la sesión completa';
  SPreguntaEliminarSesionCompleta =
    '¿Eliminar la sesión %s completa y todas sus líneas? ' +
    'Los precios ya aplicados en las tarifas no se borrarán.';
  SPreguntaEliminarUnaLineaSesion =
    '¿Eliminar 1 línea de esta sesión? La sesión y los precios de ' +
    'las tarifas se conservarán.';
  SPreguntaEliminarLineasSesion =
    '¿Eliminar %d líneas de esta sesión? La sesión y los precios de ' +
    'las tarifas se conservarán.';
  SCaptionActualizarCostesSesion = 'Actualizar costes';
  SPreguntaActualizarCostesSesion =
    '¿Actualizar los costes de las líneas seleccionadas con el coste ' +
    'actual de su talla? Se sustituirán los costes escritos en la sesión.';
  SCaptionInstanteAltaServidor = 'Instante alta (servidor)';
  SCaptionInstanteModificacionServidor = 'Modificación (servidor)';
  SAyudaInstantesServidor =
    'Hora de la sesión del servidor, igual que los demás mantenimientos. ' +
    'Una consulta en otra zona horaria puede mostrar otra hora ' +
    'para el mismo instante.';
  SCaptionListadoVentasFaseDocumento = 'Fase del documento';
  STituloVentasFacturadas =
    'Ventas facturadas (sin albaranes pendientes de facturar)';
  SPreguntaDescuentoUnaLineaSesionTarifa =
    '¿Aplicar un descuento del %s %% a 1 línea?';
  SCaptionListadoVentasFase =
    'Fase';
  SCaptionListadoVentasEmitida =
    'Emitida';
  SCaptionListadoVentasAlmacen =
    'Almacén';
  SCaptionListadoVentasCliente =
    'Cliente';
  SCaptionListadoVentasRazonCliente =
    'Razón social cliente';
  SCaptionListadoVentasCodigoVendedor =
    'Cod. vend.';
  SCaptionListadoVentasVendedor =
    'Vendedor';
  SCaptionListadoVentasLinea =
    'Línea';
  SCaptionListadoVentasArticulo =
    'Artículo';
  SCaptionListadoVentasSku =
    'SKU';
  SCaptionListadoVentasDescripcion =
    'Descripción';
  SCaptionListadoVentasVariacion =
    'Variacion';
  SCaptionListadoVentasModelo =
    'Modelo';
  SCaptionListadoVentasCodigoFamilia =
    'Cod. familia';
  SCaptionListadoVentasFamilia =
    'Familia';
  SCaptionListadoVentasCodigoProveedor =
    'Cod. prov.';
  SCaptionListadoVentasProveedor =
    'Proveedor';
  SCaptionListadoVentasTemporada =
    'Temporada';
  SCaptionListadoVentasCantidad =
    'Cantidad';
  SCaptionListadoVentasPrecioSalida =
    'Precio salida';
  SCaptionListadoVentasDescuento =
    'Dto. %';
  SCaptionListadoVentasPvpSinIva =
    'PVP s/IVA';
  SCaptionListadoVentasPvpConIva =
    'PVP c/IVA';
  SCaptionListadoVentasTotalSinIva =
    'Total s/IVA';
  SCaptionListadoVentasTotalConIva =
    'Total c/IVA';
  SItemTodosFiltrosListadoVentas =
    '(Todos)';

  SCaptionFilaBalance = 'Variante';
  SNombreArchivoBalanceAlmacenTallas = 'Balance_almacen_tallas';
  SCaptionBandasBalanceTallas = 'Bandas';
  SCaptionAgrupacionesBalanceTallas = 'Agrupaciones';
  SCaptionAlmacenBalanceTallas = 'Almacén';
  SCaptionProveedorBalanceTallas = 'Proveedor';
  SCaptionFamiliaBalanceTallas = 'Familia';
  SCaptionTemporadaBalanceTallas = 'Temporada';
  SCaptionEntradasBalanceTallas = 'Entradas';
  SCaptionVentasBalanceTallas = 'Ventas';
  SCaptionExistenciasFinalesBalanceTallas = 'Existencias finales';
  SCaptionExistenciasInicialesBalanceTallas = 'Existencias iniciales';
  SCaptionEntradaCompraBalanceTallas = 'Ent. compra';
  SCaptionAlbaranEntradaBalanceTallas = 'Alb. entrada';
  SCaptionTraspasosBalanceTallas = 'Traspasos (neto)';
  SCaptionDepositosBalanceTallas = 'Depósitos (neto)';
  SCaptionRegularizacionesBalanceTallas = 'Regulariz.';
  SCaptionDevolucionProveedorBalanceTallas = 'Dev. proveedor';
  SCaptionOtrosMovimientosBalanceTallas = 'Otros movim.';
  SCaptionAlbaranVentaBalanceTallas = 'Alb. venta';

  SNombreArchivoBalanceAlmacenSinTallas =
    'Balance_almacen_sin_tallas';
  SCaptionBandasBalanceSinTallas = 'Bandas';
  SCaptionAgrupacionesBalanceSinTallas = 'Agrupaciones';
  SCaptionAlmacenBalanceSinTallas = 'Almacén';
  SCaptionProveedorBalanceSinTallas = 'Proveedor';
  SCaptionFamiliaBalanceSinTallas = 'Familia';
  SCaptionTemporadaBalanceSinTallas = 'Temporada';
  SCaptionEntradasBalanceSinTallas = 'Entradas';
  SCaptionVentasBalanceSinTallas = 'Ventas';
  SCaptionExistenciasFinalesBalanceSinTallas = 'Existencias finales';
  SCaptionExistenciasInicialesBalanceSinTallas = 'Existencias iniciales';
  SCaptionEntradaCompraBalanceSinTallas = 'Ent. compra';
  SCaptionAlbaranEntradaBalanceSinTallas = 'Alb. entrada';
  SCaptionTraspasosBalanceSinTallas = 'Traspasos (neto)';
  SCaptionDepositosBalanceSinTallas = 'Depósitos (neto)';
  SCaptionRegularizacionesBalanceSinTallas = 'Regulariz.';
  SCaptionDevolucionProveedorBalanceSinTallas = 'Dev. proveedor';
  SCaptionOtrosMovimientosBalanceSinTallas = 'Otros movim.';
  SCaptionAlbaranVentaBalanceSinTallas = 'Alb. venta';

resourcestring
  SCaptionEditarDescuentoArticuloTarifa = 'Editar % descuento';

resourcestring
  // FZ-ISSUE-658: cabecera de la persiana plegada con los filtros de carga
  // que no son los de por defecto. Partes unidas con ' · '.
  SCaptionFiltrosCargaArticulosActivos = '%s (%s)';
  SResumenFiltroArticulosTodos = 'activos e inactivos';
  SResumenFiltroArticulosInactivos = 'solo inactivos';
  SResumenFiltroArticulosConStock = 'solo con stock';
  // %s = nombre de la temporada.
  SResumenFiltroArticulosTemporada = 'temporada %s';
  // %d = número de temporadas (2 o más).
  SResumenFiltroArticulosTemporadas = '%d temporadas';
  SResumenFiltroArticulosProveedores = 'proveedores: %d';
  SResumenFiltroArticulosFamilias = 'familias: %d';

implementation

end.
