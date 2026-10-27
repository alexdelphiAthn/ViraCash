{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgCompras                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de proveedores y documentos del circuito de compras.             }
{******************************************************************************}
unit inLibMsgCompras;

interface

resourcestring
  SRegistrarPagoAntesDeRecibo =
    'Registre primero el pago al proveedor o agricultor.';
  STituloRegistrarPagoEfectoFacturaCompra =
    'Efecto %d - vto %s - pendiente %.2f';

  STituloComprasDirectas = 'Compras directas a terceros';
  STratamientoAgricola = 'Tratamiento a agricultores (REAGP)';
  SAcuerdoFacturacion =
    'Existe acuerdo previo de facturación por el destinatario';
  SPorcentajeCompensacion = 'Compensación agrícola (%)';
  STotalCompensacion = 'Importe de la compensación';
  SDatosFiscales = 'Tratamiento fiscal';
  SImprimirReciboPago = 'Imprimir recibo de pago';
  SRecibosPago = '&4_Recibos de pago';
  SGenerarRecibos = 'Generar recibos';
  SRegistrarPago = 'Registrar pago';
  SRepresentacionFiscal =
    'La empresa está autorizada a remitir registros por el proveedor';
  SFechaContable = 'Fecha de registro contable (SII)';
  SCuotaDeducible = 'Cuota deducible (SII)';
  SGenerarEnviarFiscal = 'Generar / enviar registro fiscal';
  SProveedorEmisor = 'Proveedor / profesional (emisor)';
  SEmpresaDestinataria = 'Empresa destinataria';

  SSerieCompraDirectaInvalida =
    'Seleccione una serie específica de tipo FP y subtipo %s en Empresas.';
  SSerieCompraCompartida =
    'La serie %s ya pertenece a otra modalidad, empresa o proveedor. ' +
    'Configure una serie independiente.';
  SEmpresaCompraDirecta =
    'El destinatario de la compra directa debe ser la empresa local.';
  SReagpNoHabilitado = 'El tratamiento agrícola requiere appUsarReagp.';
  SAcuerdoAutofactura =
    'Confirme el acuerdo previo de facturación por el destinatario.';
  SUbicacionCasillaCompraDirecta =
    'Marque la casilla «%s» de la pestaña «%s».';
  SModalidadNumerada =
    'La modalidad, la empresa, el proveedor y la serie de una compra ' +
    'directa numerada no se pueden cambiar. Cree un documento nuevo.';
  SDatosFiscalesCompra =
    'Indique el proveedor y los datos fiscales de emisor y destinatario.';
  SProveedorNoDirecto =
    'Marque Facturación directa en la ficha del proveedor.';
  SCompensacionObligatoria =
    'Indique un porcentaje de compensación agrícola mayor que cero.';

  SAsignacionFotoArticulo = 'Artículo';
  SAsignacionFotoSku = 'SKU %s';
  SCaptionVariacionLineaSesion = 'Variación';
  SCaptionSinVariacionSesion = 'Sin variación';
  SRotuloCopaVariacionSesion = 'Copa';
  SRotuloContornoVariacionSesion = 'Contorno';
  SRotuloMedidaVariacionSesion = 'Medida';
  // FZ-ISSUE-734: otros nombres de atributo habituales.
  SRotuloSaborVariacionSesion = 'Sabor';
  SRotuloAromaVariacionSesion = 'Aroma';
  SErrorSkuSesionNoEncontrado =
    'No se encuentra el SKU de %s, color %s, talla %d. '
    + 'No se ha materializado la sesión.';
  SCaptionProximoCodigoFamilia = 'Próximo código: %s';
  SAvisoFotosSesionPendientes =
    'La sesión está grabada, pero quedan fotos por migrar: %s. ' +
    'Puede reintentarlo desde Fotos provisionales.';
  SCaptionReintentarFotosSesion =
    'Reintentar migración de fotos';
  SInfoFotosSesionMigradas =
    'Migración de fotos completada.';
  SAvisoSesionCerradaParaFotos =
    'La sesión debe estar cerrada para reintentar la migración de fotos.';
  SErrorFamiliaSesionSinContador =
    'La fórmula de código requiere el contador de la familia %s, ' +
    'pero no está activo. Introduzca un código manual o active ' +
    'el contador en la familia.';
  SComprasDejarDescripcionBlanco = 'Dejar descripción en blanco';
  SErrorSkuCompraNoActivo =
    'El SKU "%s" no está activo. No se puede comprar. Si quiere ' +
    'usarlo, actívelo antes en la ficha del artículo.';
  SErrorPersistenciaGridPivoteCompraNoRegistrada =
    'No se ha registrado la persistencia del pivote de compra.';
  SAvisoAlmacenDestinoAlbaranCompraObligatorio =
    'Debe seleccionar el almacén destino del albarán de compra.';
  SAvisoAlbaranCompraFacturado =
    'No se puede borrar el albarán de compra: ya está facturado. Borra o ' +
    'deshaz primero la factura de compra vinculada.';
  SPreguntaCancelarRecepcionCompra =
    'Este albarán ya tiene entradas de stock grabadas al confirmar ' +
    'sus líneas. Cancelar solo descarta la edición en curso; las ' +
    'existencias recibidas se conservan.' + sLineBreak +
    '¿Desea borrar el albarán y revertir sus movimientos de stock?' +
    sLineBreak + 'Sí: borrar. No: conservar. Cancelar: seguir editando.';
  SPreguntaBorrarAlbaranCompra =
    '¿Borrar el albarán de compra %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas y se revertirán los movimientos de stock.';
  SErrorContadorAlbaranCompra =
    'No se pudo obtener un número de albarán de compra válido. Revise el ' +
    'contador AB de la serie %s y empresa %s.';
  SErrorCambiarFormatoSesion =
    'No se puede cambiar el formato distribuido de una sesión ya creada. ' +
    'Crea una sesión nueva con el modo deseado.';
  SErrorCambiarProveedorSesionConFormula =
    'No se puede cambiar el proveedor porque la sesión ya tiene líneas y ' +
    'la fórmula del código usa ModeloProv o CodProv. Cree una sesión nueva ' +
    'o elimine primero sus líneas.';
  SErrorEmpresaSesionObligatoria =
    'Selecciona una empresa antes de grabar la sesión.';
  SErrorProveedorSesionObligatorio =
    'Selecciona un proveedor antes de grabar la sesión.';
  SErrorSerieSesionObligatoria =
    'Teclea una serie antes de grabar la sesión (p.ej. %s-SE-1).';
  SErrorContadorSesion =
    'No se pudo obtener el siguiente número. Revisa que exista una fila ' +
    'en fza_contadores para (TIPO_DOC=SE, EMPRESA=%s, SERIE=%s) o que el ' +
    'SP PRC_GET_NEXT_CONT_FACT_SERIE esté disponible.';
  SErrorCodigoSerieEmpresa =
    'No se pudo obtener CODIGO_SERIE_EMPSER del contador ES vía ' +
    'PRC_GET_NEXT_CONT.';
  SErrorAlmacenSalidaDevolucionCompra =
    'Debe seleccionar el almacén de salida de la devolución.';
  SAvisoDevolucionCompraFacturada =
    'No se puede borrar la devolución de compra: ya está facturada. Borra ' +
    'o deshaz primero la factura de compra vinculada.';
  SPreguntaBorrarDevolucionCompra =
    '¿Borrar la devolución de compra %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas y se revertirán los movimientos de stock.';
  SErrorCabeceraDevolucionCompraSinGrabar =
    'Graba la cabecera de la devolución antes de guardar líneas.';
  SErrorContadorDevolucionCompra =
    'No se pudo obtener un número de devolución de compra válido. Revise ' +
    'el contador DC de la serie %s y empresa %s.';
  SErrorBorrarEfectoCompraRemesado =
    'No se puede borrar el efecto: pertenece a una remesa. Quítalo desde ' +
    'Remesas de pago.';
  SErrorBorrarEfectoCompraPagado =
    'No se puede borrar el efecto: tiene pago o conciliación registrada.';
  SErrorFusionarEfectosCompraEstado =
    'Solo se pueden fusionar efectos pendientes, sin pagos, sin remesa y ' +
    'sin conciliación previa.';
  SErrorFusionarEfectosCompraOrigen =
    'Solo se pueden fusionar efectos de la misma empresa y proveedor.';
  SErrorFusionarEfectosCompraSinPendiente =
    'Los efectos seleccionados no tienen importe pendiente.';
  SErrorCerrarFacturaCompraSinLineas =
    'No se puede cerrar la factura: no tiene líneas con cantidad mayor que ' +
    '0. Añade líneas antes de cerrar.';
  // FZ-ISSUE-733: cierre y reapertura de borradores de compra.
  SErrorCerrarFacturaCompraSinRefProveedor =
    'No se puede cerrar la factura: falta la Ref. proveedor (el número ' +
    'de la factura del proveedor).';
  SCaptionCerrarFacturaCompra =
    'Cerrar borrador';
  SCaptionReabrirFacturaCompra =
    'Reabrir';
  SPreguntaCerrarFacturaCompra =
    '¿Cerrar la factura? Quedará como definitiva para pagos y libros.';
  SPreguntaReabrirFacturaCompra =
    '¿Reabrir la factura? Volverá a ser un borrador.';
  // FZ-ISSUE-168: factura del proveedor ya registrada.
  SPreguntaFacturaCompraDocExternoRepetido =
    'La factura %s del proveedor %s ya está registrada como %s/%s ' +
    'del %s.'#13#10#13#10 +
    'Sí: registrarla igualmente.'#13#10 +
    'No: abrir la factura ya registrada.'#13#10 +
    'Cancelar: seguir editando.';
  SErrorBorrarFacturaCompraEfectosPagados =
    'No se puede borrar la factura: tiene efectos pagados, remesados o ' +
    'conciliados.';
  SPreguntaBorrarFacturaCompra =
    '¿Borrar la factura de compra %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas y efectos, y se desmarcarán los albaranes ' +
    'vinculados.';
  SErrorCabeceraFacturaCompraSinGrabar =
    'Graba la cabecera de la factura antes de guardar líneas.';
  SErrorContadorFacturaCompra =
    'No se pudo obtener un número de factura de compra válido. Revise el ' +
    'contador FP de la serie %s y empresa %s.';
  SAvisoAlmacenDestinoPedidoCompraObligatorio =
    'Debe seleccionar el almacén destino del pedido de compra.';
  SPreguntaBorrarPedidoCompra =
    '¿Borrar el pedido de compra %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas y pendientes de recibir.';
  SErrorContadorPedidoCompra =
    'No se pudo obtener un número de pedido de compra válido. Revise el ' +
    'contador PC de la serie %s y empresa %s.';
  SErrorProveedorKitsNoSeleccionado =
    'Selecciona un proveedor antes de crear kits.';
  SErrorProveedorKitsSinGrabar =
    'Graba el proveedor antes de crear kits.';
  SErrorCodigoKitProveedorObligatorio =
    'El kit necesita un código (p. ej. CURVA-STD).';
  SErrorNombreKitProveedorObligatorio =
    'El kit necesita un nombre.';
  SErrorRazonSocialProveedorObligatoria =
    'Introduzca la razón social del proveedor antes de grabar.';
  SErrorNifProveedorFacturacionDirecta =
    'Introduzca el NIF del proveedor: es obligatorio con «Facturación ' +
    'directa».';
  SErrorKitProveedorNoSeleccionadoParaTallas =
    'Crea o selecciona un kit antes de añadir tallas.';
  SErrorTallaDestinoKitProveedorObligatoria =
    'La fila del kit necesita la talla destino (p. ej. 38, M).';
  SErrorKitProveedorNoSeleccionado =
    'Selecciona o crea un kit primero.';
  SErrorSistemaTallasKitProveedorObligatorio =
    'El kit no tiene sistema de tallas. Asigna uno en la columna "Sistema ' +
    'tallas" para poder generar sus tallas.';
  SErrorCodigoAutomaticoProveedor =
    'No se pudo generar el código automático del proveedor.';
  SErrorOrdenAutomaticoProveedor =
    'No se pudo generar el orden automático del proveedor.';
  SErrorPrefijoEanSesionLargo =
    'PREFIJO_EAN_SES demasiado largo: %s';
  SErrorColorBasicoMaterializacionNoExiste =
    'No existe el color básico CODIGO_ATB=%s. Créalo en Mto Atributos ' +
    'Básicos antes de materializar.';
  SErrorAlmacenSesionParaAlbaranCompra =
    'Falta CODIGO_ALM_SES en la cabecera de la sesión para generar el ' +
    'albarán de compra.';
  SErrorAlmacenSesionParaPedidoCompra =
    'Falta CODIGO_ALM_SES en la cabecera de la sesión para generar el ' +
    'pedido de compra.';
  SErrorAlmacenSesionParaPendienteRecibir =
    'Falta CODIGO_ALM_SES en la cabecera de la sesión para generar el ' +
    'pedido pendiente de recibir.';
  SAvisoSelectorConjuntoFilaNoImplementado =
    'El selector de valores del conjunto fila aún no está implementado.' +
    sLineBreak + sLineBreak +
    'Mientras tanto, en la cabecera deja vacío el campo "Conjunto fila" ' +
    'para teclear los colores libremente.';
  STituloNuevaFilaCompra = 'Nueva fila';
  SSolicitudNombreFilaCompra =
    'Nombre de la fila (color del proveedor):';
  SErrorAlbaranCompraMovimientosNoEncontrado =
    'Albarán de compra %s/%s no encontrado para generar movimientos.';
  SErrorAlbaranCompraMovimientosYaGenerados =
    'El albarán %s/%s ya tiene movimientos generados. Revierte antes de ' +
    'volver a generar.';
  SErrorAlbaranCompraSinCantidadParaMovimientos =
    'El albarán %s/%s no tiene ninguna línea o celda con cantidad > 0 para ' +
    'generar movimientos.';
  SErrorMovimientosAlbaranCompraNoRegistrados =
    'La persistencia de movimientos de albaranes de compra no está ' +
    'registrada.';
  SErrorPedidosCompraNoRegistrados =
    'La persistencia de pedidos de compra no está registrada.';
  SErrorMovimientosDevolucionCompraNoRegistrados =
    'La persistencia de movimientos de devoluciones de compra no está ' +
    'registrada.';
  SErrorDevolucionCompraMovimientosNoEncontrada =
    'Devolución de compra %s/%s no encontrada para generar movimientos.';
  SErrorDevolucionCompraMovimientosYaGenerados =
    'La devolución %s/%s ya tiene movimientos generados. Revierte antes ' +
    'de volver a generar.';
  SErrorDevolucionCompraSinCantidadParaMovimientos =
    'La devolución %s/%s no tiene ninguna línea o celda con cantidad > 0 ' +
    'para generar movimientos.';
  SErrorSesionCompraNoActiva = 'No hay sesión activa.';
  SErrorLineaSesionSinNumero =
    'La línea aún no tiene número. Graba la sesión primero.';
  SErrorSistemaTallasLineaSesionObligatorio =
    'La línea no tiene sistema de tallas. Asígnale uno en la columna ' +
    '"Sistema tallas" antes de aplicar el kit.';
  SErrorSistemaTallasTecleadoNoValido =
    'El sistema de tallas «%s» no existe o no es único. ' +
    'Escriba su código o selecciónelo en la lista.';
  SErrorKitProveedorNoExiste =
    'El kit %s no existe para el proveedor %s.';
  SErrorKitSinSistemaTallas =
    'El kit %s no tiene sistema de tallas. Asígnaselo en Proveedores, ' +
    'pestaña Compras, para poder comprobar que coincide con el de la línea.';
  SErrorTallajeKitNoCoincide =
    'El tallaje del kit no coincide con el de la línea: kit = "%s", línea ' +
    '= "%s". Cambia el sistema de tallas de la línea o elige un kit de su ' +
    'mismo tallaje.';
  SErrorGestorTallasNoInicializado =
    'Gestor de tallas no inicializado.';
  SErrorKitSinTallasDefinidas =
    'El kit %s no tiene tallas definidas. Complétalo en Proveedores, ' +
    'pestaña Compras.';
  SAvisoTallasKitSinCorrespondencia =
    'Tallas del kit sin correspondencia en el sistema de la línea (no ' +
    'aplicadas): %s';
  SErrorTallasKitSinCorrespondencia =
    'Ninguna talla del kit casa con el sistema de tallas de la línea.';
  SErrorSesionIncidenciasSinDetalle =
    'Hay incidencias sin detalle.';
  SErrorDataModuleSesionNoInicializado =
    'DataModule no inicializado.';
  SErrorSesionNoCerradaParaRevertir =
    'La sesión no está CERRADA, no hay nada que revertir.';
  STextoLineaIncidenciaSesion = 'Línea %d';
  STextoCabeceraIncidenciaSesion = 'Cabecera';
  SFormatoIncidenciaSesion = '[%s] %s: %s';
  SErrorSesionInactivaIncidencia =
    '[CABECERA] No hay sesión activa.';
  STipoIncidenciaCabecera = 'CABECERA';
  SErrorEmpresaSesionFaltante =
    'Falta CODIGO_EMP_SES (Empresa).';
  SErrorProveedorSesionFaltante =
    'Falta CODIGO_PRV_SES (Proveedor).';
  SErrorAlmacenSesionFaltante =
    'ESGENERA_ALBARAN=S pero no hay CODIGO_ALM_SES (Almacén).';
  SErrorSesionSinLineas = 'La sesión no tiene líneas.';
  STipoIncidenciaDuplicadoInterno = 'DUP_INTRA';
  SErrorCodigoDuplicadoInternoSesion =
    'Código %s repetido dentro de la sesión (primera vez en línea %d). ' +
    'Marca esta línea como REUSAR o cambia el código.';
  STipoIncidenciaDuplicado = 'DUPLICADO';
  // Habla de artículos, no de la tabla (FZ-ISSUE-740).
  SErrorCodigoDuplicadoSesion =
    'El artículo %s%s ya existe. Decida si reutilizarlo o cambiar el ' +
    'código.';
  SCaptionCodigoPropuestoEnLinea =
    'El código propuesto %s ya está utilizado en la línea %d';
  SCaptionCodigoPropuestoExistente =
    'El código propuesto pertenece a un artículo existente';
  SCaptionCodigoDejarPendiente = 'Dejar &pendiente (ESC)';
  SCaptionReusarArticuloSesion =
    'Reutilizar el mismo artículo de la otra línea';
  SErrorCodigoNuevoSesion = 'Introduzca un código distinto y no vacío.';
  SErrorReusoSinArticuloSesion =
    'No hay un artículo %s que reutilizar ni una línea que lo cree. ' +
    'Cambie el código o conserve una línea como artículo nuevo.';
  SErrorPvpIncompatibleArticuloSesion =
    'El artículo %s tiene PVP distintos para la misma talla o medida ' +
    'en la sesión (%s y %s). Iguale los PVP o asigne códigos ' +
    'distintos antes de materializar.';
  STipoIncidenciaCodigo = 'CODIGO';
  SErrorLineaSesionSinCodigo =
    'La línea no tiene CODIGO_ART_TENTATIVO_SESLIN.';
  SErrorFormulaCodigoArticuloLlaves =
    'La fórmula del código de artículo contiene llaves sin cerrar o ' +
    'mal colocadas.';
  SErrorFormulaCodigoArticuloParametro =
    'El parámetro "%s" no existe en la fórmula del código de artículo. ' +
    'Use CodFamilia, ContadorFamilia, ModeloProv o CodProv entre llaves.';
  SErrorFormulaCodigoArticuloAncho =
    'El ancho de "%s" no es válido en la fórmula del código de ' +
    'artículo. Tras los dos puntos va un número de 1 a %d, por ejemplo ' +
    '{CodProv:3}.';
  SErrorFormulaCodigoArticuloSinParametros =
    'La fórmula del código de artículo debe incluir al menos uno de estos ' +
    'parámetros entre llaves: CodFamilia, ContadorFamilia, ModeloProv, ' +
    'CodProv o CodArt.';
  SErrorFormulaCodigoArticuloDatos =
    'No están informados todos los datos que requiere la fórmula del ' +
    'código de artículo.';
  SErrorFormulaCodigoArticuloResultadoVacio =
    'La fórmula ha generado un código de artículo vacío.';
  SErrorFormulaCodigoArticuloLongitud =
    'La fórmula ha generado el código "%s" con %d caracteres. El máximo ' +
    'permitido es %d.';
  STipoIncidenciaDescripcion = 'DESCRIPCION';
  SErrorLineaSesionSinDescripcion =
    'Línea sin descripción (código %s).';
  STipoIncidenciaCantidades = 'CANTIDADES';
  SErrorLineaMatrizSinCantidades =
    'Línea MATRIZ sin cantidades por talla (código %s - %s).';
  STipoIncidenciaSistemaTallas = 'SISTEMA_TALLAS';
  SErrorLineaMatrizSinSistemaTallas =
    'Línea MATRIZ sin sistema de tallas (código %s).';
  SErrorColorCompraNoSeleccionado = 'Selecciona un color.';
  SErrorConexionResolverColorCompra =
    'No hay conexión para resolver el color.';
  SErrorColorBasicoCompraNoExiste =
    'No existe el color básico "%s".';
  SErrorResolverColorCompra =
    'No se pudo resolver el color "%s".';
  SErrorSistemaTallasSuperaMaximoPivote =
    '- Artículo %s: sistema "%s" con %d tallas (máximo %d).';
  SErrorActivarPivoteTallas =
    'No se puede activar el modo pivote por tallas:' +
    sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Se mantiene la vista plana (línea por SKU).';
  SErrorActivarTallasHorizontalesParaColor =
    'Activa las tallas en horizontal antes de elegir color.';
  SErrorLineaActivaColorNoDisponible =
    'No hay una línea activa para cambiar el color.';
  SErrorColorCompraConCantidades =
    'El color se elige antes de introducir cantidades. Crea una línea de ' +
    'color nueva para no mezclar tallas.';
  SErrorConsultaLineasCompraNoAbierta =
    'No está abierta la consulta de líneas.';
  SErrorLineaActivaColorNoEncontrada =
    'No se encontró la línea activa para cambiar el color.';
  SErrorLineaActivaCompraSinArticulo =
    'La línea activa no tiene artículo.';
  SErrorPedidoCompraSinPendientesAlmacen =
    'No hay líneas pendientes de recibir para el almacén "%s" en el pedido ' +
    '%s/%s.';
  SErrorAlmacenPedidoCompraNoSeleccionado =
    'Debes seleccionar un almacén.';
  SErrorPedidoCompraSinCantidadesRecibir =
    'No hay cantidades "A recibir" tecleadas para el almacén "%s" en el ' +
    'pedido %s/%s.';
  SErrorContadorAlbaranCompraNoDisponible =
    'No se pudo obtener un número de albarán del contador "AB".';
  SErrorCrearLineasAlbaranCompra =
    'No se pudo crear ninguna línea del albarán (líneas origen no ' +
    'encontradas o sin pendiente de recibir).';
  SInfoAlbaranCompraCreado =
    'Albarán %s/%s creado correctamente (%d líneas).';
  SErrorAlbaranCompraDestinoNoSeleccionado =
    'Debes seleccionar el albarán de destino.';
  SInfoLineasIncorporadasAlbaranCompra =
    'Líneas incorporadas al albarán %s/%s.';
  SErrorIncorporarLineasAlbaranCompra =
    'No se pudo incorporar ninguna línea (líneas origen no encontradas o ' +
    'sin pendiente de recibir).';
  SInfoLineasIncorporadasAlbaranCompraConCantidad =
    'Líneas incorporadas al albarán %s/%s (%d líneas).';
  SErrorArticuloSinSistemaTallasCompra =
    '- Artículo sin sistema de tallas: %s';
  SErrorActivarTallasHorizontalesCompra =
    'No se puede activar tallas en horizontal:' +
    sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Asigna un sistema de tallas o elimina la línea.';
  SErrorAlbaranCompraNoAbierto =
    'No está abierto el albarán de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusAlbaranCompra =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorAlbaranCompraNoInicializado =
    'No está inicializado el albarán de compra.';
  STextoAlbaranCompra = 'un albarán';
  SPreguntaAbrirSeriesAlbaranCompra =
    'No hay series de albaranes de compra (tipo AB) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorAlbaranCompraSinImpresionActivo =
    'No hay albarán de compra activo que imprimir.';
  SErrorAlbaranCompraNoActivo =
    'No hay albarán de compra activo.';
  SPreguntaGrabarAlbaranCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorAlbaranCompraNecesarioElegirEmpresa =
    'Crea o selecciona un albarán de compra antes de elegir la empresa.';
  SErrorAlbaranCompraNecesarioElegirProveedor =
    'Crea o selecciona un albarán de compra antes de elegir el proveedor.';
  SAvisoAlbaranCompraSinPedido =
    'Este albarán no procede de ningún pedido de compra.';
  SAvisoAlbaranCompraSinFactura =
    'Este albarán no tiene factura de compra creada.';
  SPreguntaEliminarLineaAlbaranCompra =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaBorrarPropiedadPlantillaCompra =
    '¿Borrar la propiedad?';
  SPreguntaBorrarKitPlantillaCompra = '¿Borrar el kit?';
  SErrorCabeceraSesionAntesLineas =
    'Crea y graba la cabecera de la sesión antes de añadir líneas.';
  SErrorSesionSinDocumentosCreados =
    'La sesión no tiene documentos creados.';
  SErrorMantenimientoTipoDocumentoNoDisponible =
    'No hay mantenimiento disponible para el tipo de documento "%s".';
  SPreguntaAbrirSeriesSesionCompra =
    'No hay series de sesiones de compra (tipo SE) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorSesionElegirProveedorNoSeleccionada =
    'Crea o selecciona una sesión antes de elegir el proveedor.';
  SErrorProveedorSesionSinKits =
    'El proveedor de la sesión no tiene kits definidos. Se crean en ' +
    'Proveedores, pestaña Compras.';
  SErrorKitProveedorDesplegableNoSeleccionado =
    'Elige un kit del proveedor en el desplegable.';
  SPreguntaBorrarLineaSesionCompra =
    '¿Borrar la línea seleccionada?';
  SErrorSesionYaMaterializada =
    'La sesión ya está cerrada. No se puede materializar dos veces.';
  // Un documento por almacén: almacenes sin serie propia (una línea por
  // almacén y documento: almacén, documento y serie que usará).
  SAvisoAlmacenesSinSeriePropia =
    'Estos almacenes no tienen serie propia y sus documentos se ' +
    'numerarán en la serie elegida:' + sLineBreak + sLineBreak + '%s' +
    sLineBreak + sLineBreak + '¿Crear los documentos igualmente?';
  SLineaAlmacenSinSeriePropia = '%s · %s: serie %s';
  SInfoDuplicadosSesionMarcadosReusar =
    'Se han detectado y marcado %d línea(s) como REUSAR de códigos ' +
    'repetidos dentro de esta sesión (variantes color/SKU del mismo ' +
    'artículo). La materialización crea el artículo una sola vez.';
  SInfoSesionMaterializadaSinDocumentos =
    'Sesión materializada (sin documentos).';
  SErrorSesionNoCerradaParaReversion =
    'La sesión no está CERRADA. Solo se pueden revertir sesiones ' +
    'materializadas.';
  SErrorReversionSesionMigracionPendiente =
    'No se puede revertir la sesión: falta aplicar la migración ' +
    '20261004_reversion_sesiones_bloqueos_v2.sql en la base de datos.';
  SErrorReversionSesionConIncidencias =
    'No se puede revertir la sesión porque sus documentos tienen ' +
    'dependencias:' + sLineBreak + '%s' + sLineBreak +
    'No se ha modificado ningún dato.';
  SIncidenciaReversionFacturaCompra =
    '- El albarán de compra %s está incluido en la factura de compra %s.';
  SIncidenciaReversionSalidaPosterior =
    '- El albarán de compra %s no puede revertirse por una venta, otra ' +
    'salida posterior o datos de stock no verificables: %s.';
  SIncidenciaReversionPedidoRecibido =
    '- El pedido de compra %s ya fue recibido o tiene un albarán ' +
    'dependiente: %s.';
  SIncidenciaReversionTipoDocumento =
    '- La sesión contiene un documento de tipo no soportado: %s %s.';
  SIncidenciaReversionDocumentoIncompleto =
    '- La sesión contiene una referencia %s incompleta (serie "%s", ' +
    'número "%s").';
  SIncidenciaReversionReferenciaSinMapa =
    '- La referencia %s %s de la cabecera no aparece en el mapa de ' +
    'documentos de la sesión.';
  SIncidenciaReversionDocumentoCompartido =
    '- El documento %s %s también está vinculado a la sesión %s.';
  SPreguntaRevertirSesionCompra =
    'Se borrarán los pedidos, albaranes y movimientos de almacén creados ' +
    'por esta sesión, que volverá a BORRADOR.' + sLineBreak + sLineBreak +
    'La operación se bloqueará si esos documentos están facturados, si ' +
    'el pedido ya fue recibido o si hay ventas u otras salidas ' +
    'posteriores de stock.' +
    sLineBreak + sLineBreak +
    'Los artículos / SKUs / códigos de barras se conservan ' +
    '(re-materializar es idempotente).' + sLineBreak + sLineBreak +
    '¿Continuar?';
  SInfoSesionRevertida = 'Sesión revertida. Estado: BORRADOR.';
  SErrorRevertirSesionCompra =
    'No se pudo revertir la sesión:' + sLineBreak + '%s';
  SErrorSesionActivaImprimirNoDisponible =
    'No hay sesión activa que imprimir.';
  SErrorSistemasTallasSesionNoDisponibles =
    'No hay sistemas de tallas activos en fza_atributos_conjuntos ' +
    '(ID_VA_AC=''TAL'').';
  SErrorCambiarSistemaTallasModeloExistente =
    'El sistema de tallas no se puede cambiar en un modelo que ya existe: ' +
    'queda fijado al del artículo. Solo puedes añadir colores o tallas ' +
    'nuevos.';
  SAvisoArticuloSesionSinTallaje =
    'El artículo %s no tiene sistema de tallas: sus unidades van en la ' +
    'columna Uds. Para repartirlas por talla, asígnale un tallaje en su ' +
    'ficha.';
  SErrorColoresBasicosSesionNoDisponibles =
    'No hay colores básicos cargados en fza_atributos_basicos para ' +
    'ID_VA=''CO''.';
  SErrorEfectosCompraFusionInsuficientes =
    'Selecciona dos o más efectos impagados.';
  SPreguntaAbrirSeriesDevolucionCompra =
    'No hay series de devoluciones a proveedor (tipo DC) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorLineaColorDevolucionNoEncontrada =
    'No se ha encontrado ninguna línea de ese color.';
  SErrorDevolucionCompraSinImpresionActiva =
    'No hay devolución de compra activa que imprimir.';
  SErrorDevolucionCompraNoActiva =
    'No hay devolución de compra activa.';
  SErrorProveedorDevolucionFilaNoSeleccionado =
    'Selecciona un proveedor antes de devolver la fila.';
  SErrorAlmacenDevolucionFilaNoSeleccionado =
    'Selecciona el almacén de salida antes de devolver el stock.';
  SErrorColorDevolucionFilaNoSeleccionado =
    'Selecciona el color de la fila antes de devolver su stock.';
  SPreguntaGrabarDevolucionCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorDevolucionCompraNoAbierta =
    'No está abierta la devolución de compra.';
  SErrorDevolucionCompraElegirEmpresaNoSeleccionada =
    'Crea o selecciona una devolución de compra antes de elegir la empresa.';
  SErrorDevolucionCompraElegirProveedorNoSeleccionada =
    'Crea o selecciona una devolución de compra antes de elegir el ' +
    'proveedor.';
  SPreguntaEliminarLineaDevolucionCompra =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaAbrirSeriesFacturaCompra =
    'No hay series de facturas de compra (tipo FP) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorProveedorNoSeleccionadoBuscarArticulosFacturaCompra =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorFacturaCompraNoAbierta =
    'No está abierta la factura de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusFacturaCompra =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorFacturaCompraSinImpresionActiva =
    'No hay factura de compra activa que imprimir.';
  SAvisoEtiquetasBorradorCompraPendientes =
    'Etiquetas de borrador de compra: pendiente (hito de informes).';
  SPreguntaGrabarFacturaCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorFacturaCompraNoInicializada =
    'No está inicializada la factura de compra.';
  SErrorFacturaCompraElegirProveedorNoSeleccionada =
    'Crea o selecciona una factura de compra antes de elegir el proveedor.';
  SInfoGeneracionEfectosPagoCancelada =
    'Generación de efectos cancelada.';
  SInfoEfectosPagoGenerados =
    'Generados %d efecto(s) de pago.';
  SAvisoEfectosPagoNoGenerados =
    'No se generaron efectos. Revisa que el borrador tenga forma de pago y ' +
    'total, y que no tenga ya efectos pagados o remesados.';
  SErrorGenerarEfectosPagoSinBorrador =
    'No hay borrador activo (o hubo un error al generar).';
  SErrorEfectoCompraNoSeleccionado =
    'Selecciona un efecto en la rejilla de la pestaña Efectos.';
  SPreguntaEliminarLineaFacturaCompra =
    '¿Está seguro de que desea eliminar esta línea?';
  SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra =
    'Selecciona un proveedor antes de buscar artículos.';
  SErrorPedidoCompraNoAbierto =
    'No está abierto el pedido de compra.';
  SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorPedidoCompraNoInicializado =
    'No está inicializado el pedido de compra.';
  STextoPedidoCompra = 'un pedido';
  SErrorExpandirRecibidosNoActivo =
    'Activa "Expandir recibidos" antes de usar este atajo.';
  SInfoTallasPendientesRecibirNoDisponibles =
    'No hay tallas pendientes de recibir en la fila activa.';
  SInfoPedidoCompraSinPendientesRecibir =
    'No hay nada pendiente de recibir en el pedido.';
  SPreguntaGrabarPedidoCompraSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorPedidoCompraNecesarioElegirEmpresa =
    'Crea o selecciona un pedido de compra antes de elegir la empresa.';
  SErrorPedidoCompraNecesarioElegirProveedor =
    'Crea o selecciona un pedido de compra antes de elegir el proveedor.';
  SErrorTallasHorizontalesNecesariasElegirColor =
    'Activa las tallas en horizontal antes de elegir color.';
  SErrorArticuloNoSeleccionadoElegirColorPedidoCompra =
    'Selecciona un artículo antes de elegir color.';
  SErrorArticuloPedidoCompraSinColoresBasicos =
    'El artículo "%s" no tiene colores básicos activos en sus SKUs.';
  SPreguntaEliminarLineaPedidoCompra =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaAbrirSeriesPedidoCompra =
    'No hay series de pedidos de compra (tipo PC) para la empresa "%s".' +
    sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorPedidoCompraNoActivo =
    'No hay pedido de compra activo.';
  SErrorPedidoCompraNoActivoCrearAlbaran =
    'No hay pedido activo del que crear albarán.';
  SErrorAlmacenLineaPedidoCompraNoExiste =
    'Línea %s: el almacén «%s» no existe. Elíjalo de la lista.';
  SErrorCrearAlbaranDesdePedidoCompra =
    'Error al crear el albarán: %s';
  SPreguntaBorrarKitProveedor =
    '¿Borrar el kit seleccionado y todas sus tallas?';
  SErrorRemesaCompraNoSeleccionada = 'Selecciona una remesa.';
  SErrorEliminarRemesaCompraConCargo =
    'No se puede eliminar una remesa con cargo realizado.';
  SPreguntaEliminarRemesaCompra =
    '¿Eliminar la remesa seleccionada? Los efectos volveran a quedar ' +
    'pendientes de remesar.';
  SInfoRemesaCompraEliminada = 'Remesa eliminada.';
  SErrorEliminarRemesaCompra =
    'No se pudo eliminar la remesa.';
  SErrorAnadirEfectosRemesaCompraConCargo =
    'No se pueden añadir efectos a una remesa con cargo realizado.';
  SErrorEfectosRemesaCompraNoCargados =
    'No hay efectos cargados.';
  SErrorEfectoRemesaCompraNoSeleccionado =
    'Selecciona un efecto de la remesa.';
  SErrorQuitarEfectosRemesaCompraConCargo =
    'No se pueden quitar efectos de una remesa con cargo realizado.';
  SPreguntaQuitarEfectoRemesaCompra =
    '¿Quitar el efecto seleccionado de la remesa?';
  SInfoEfectoRemesaCompraQuitado =
    'Efecto quitado de la remesa.';
  SErrorQuitarEfectoRemesaCompra =
    'No se pudo quitar el efecto.';
  SErrorEfectoRemesaCompraSinPendiente =
    'El efecto seleccionado no tiene importe pendiente.';
  STextoEfectoPendienteRemesaCompra =
    'Efecto %d - pendiente %.2f';
  SInfoEfectoRemesaCompraConciliado = 'Efecto conciliado.';
  SErrorConciliarEfectoRemesaCompra =
    'No se pudo conciliar el efecto.';
  SErrorRemesaCompraSinImportePendiente =
    'La remesa no tiene importe pendiente.';
  STextoRemesaCompraPendiente = 'Remesa pendiente %.2f';
  SInfoEfectosRemesaCompraConciliados =
    'Conciliados %d efecto(s).';
  SErrorConciliarRemesaCompra =
    'No se pudo conciliar la remesa.';
  SErrorBancoPagoNoSeleccionado =
    'Selecciona un banco de pago.';
  SErrorTipoDocumentoSesionNoSeleccionado =
    'Marca al menos uno: Albarán y/o Pedido.';
  SErrorAlmacenDestinoSesionNoIndicado =
    'Indica un almacén destino.';
  SErrorFacturaCompraExportarNoPreparada =
    'No hay factura de compra preparada para exportar.';
  // R02 - Pestaña de líneas de documentos de compra
  SCaptionTabLineasCompra = '&1_Líneas';
  // Conserva el espacio final: distingue el modo sin construir
  SCaptionTabLineasCompraSinConstruir = '&1_Líneas ';
  // R03 - Sesiones de compra: foto provisional y modal de modelo
  SCaptionSeleccioneLineaSesion =
    'Seleccione una línea de la sesión.';
  SCaptionLineaFotoDetalle = 'Línea %d · %s · %s';
  SCaptionLineaSinFotoProvisional =
    'Línea %d · sin foto provisional';
  SCaptionDestinoArticulo = 'artículo';
  SCaptionDestinoSku = 'SKU %s';
  SErrorLineaSesionDescargarFotosNoSeleccionada =
    'Selecciona o crea una línea antes de descargar fotos.';
  SErrorLineaSesionSinCodigoArticulo =
    'La línea activa no tiene código de artículo.';
  SErrorDescargarFotosArticulo =
    'No se pudieron descargar las fotos del artículo %s:' + sLineBreak +
    '%s';
  SInfoFotosArticuloDescargadas =
    'Descargadas %d foto(s) del artículo %s.';
  SErrorLineaSesionAsignarFotoNoSeleccionada =
    'Selecciona o crea una línea antes de asignar foto.';
  SInfoFotoLineaSesionAsignada =
    'Foto asignada a la línea %d.';
  SErrorAsignarFotoSesion = 'No se pudo asignar la foto.';
  SErrorGuardarFotoSesion = 'Error guardando foto: %s';
  SCaptionModeloCompra = 'Modelo';
  SCaptionCodigoCompra = 'Código';
  // R05 - Pestaña de líneas de documentos de compra sin acelerador
  SCaptionTabLineasDocCompra = '&1_Líneas';
  // Conserva el espacio final: distingue el modo sin construir
  SCaptionTabLineasDocCompraSinConstruir = '&1_Líneas ';
  // R07 - Pedidos de compra
  SCaptionContextoTallaPedido =
    'Talla %s    Pedido: %.0f    Recibido: %.0f';
  SCaptionAlbaranCreadoPedidoCompra =
    'Albarán creado desde el pedido %s/%s';
  // R11 - Modales de sesiones de compra y recepción
  SPreguntaDistribucionModeloRepetido =
    'El mismo modelo está en la línea %d. ¿Aplicar a esta línea su ' +
    'misma distribución de cantidades?';
  SCaptionCrearAlbaranDesdePedidoCompra =
    'Crear albarán desde pedido %s';
  SCaptionCodigoExistente = 'Código existente: %s';
  SErrorPreferenciaPrecargaNoValida =
    'La preferencia de precarga no es válida. Revise el perfil guardado.';
  SCaptionFiltrosPrecargaCompras = 'Filtros de carga...';
  SCaptionGuardarPrecargaCompras = 'Guardar precarga...';
  SDescripcionGuardarPrecargaCompras =
    'Series de precarga de la primera lista de compras';
  SInfoPrecargaComprasGuardada = 'Preferencia de precarga guardada.';
  SInfoPrecargaComprasPendiente =
    'Carga pendiente: seleccione las series que desea consultar.';
  SInfoPrecargaComprasTodas = 'Precarga: todas las series.';
  SInfoPrecargaComprasPerfil =
    'Consulta establecida en el perfil, sin precarga automática.';
  SErrorPrecargaComprasPerfilVacio =
    'La precarga guardada está incompleta. Revise el perfil de la pantalla.';
  SInfoPrecargaComprasSerie = 'Serie precargada: %s';
  SInfoPrecargaComprasVarias = 'Precarga: %d series seleccionadas.';
  SErrorPrecargaComprasEnEdicion =
    'Guarde o cancele los cambios del documento antes de cambiar ' +
    'las series de precarga.';
  STituloPrecargaCompras = '%s - seleccionar series';
  SExplicacionPrecargaCompras =
    'Elija las series que desea cargar en %s. La lista muestra primero ' +
    'las series con documentos más recientes.';
  SOrdenSeriesCompras = 'Series por fecha del último documento';
  SMarcarAnyoCompras = 'Marcar series del año:';
  SSeleccionManualCompras = 'Selección manual';
  SSeriesSinAnyoCompras = 'Sin año reconocible';
  STodasSeriesCompras = '&Todas las series (sin filtro)';
  SSerieConFechaCompras = '%s    |    Último documento: %s';
  SSerieSinCodigoCompras = '(Sin código de serie)';
  SFechaNoDisponibleCompras = 'sin fecha';
  SResultadoPendienteCompras =
    'Se comprobará la cantidad antes de cargar los documentos.';
  SBotonCalcularCompras = '&Calcular';
  SBotonNingunaCompras = '&Ninguna';
  SBotonCargarCompras = 'Ca&rgar';
  SBotonCancelarCompras = '&Cancelar';
  SSeleccionVaciaCompras =
    'Marque al menos una serie o seleccione «Todas las series». ' +
    'Una lista sin marcas no carga todos los documentos.';
  SCantidadDocumentosCompras = 'Documentos que se cargarán: %s.';
  SCantidadExcesivaCompras = 'Se cargarán más de %s documentos.';
  SPreguntaCargaExcesivaCompras =
    'La selección supera %s documentos y la carga puede tardar. ' +
    '¿Desea cargar los documentos de la selección actual?';
  SRepositorioComprasObligatorio =
    'La selección de series requiere un repositorio de precarga.';
  SErrorDocumentoPrecargaNoAdmitido =
    'La precarga por series solo admite pedidos y albaranes de compra.';
  SErrorSqlPrecargaNoAdmitido =
    'El SQL del perfil no permite identificar de forma segura la ' +
    'cabecera de compra. No se ha cambiado la consulta.';
  SErrorPrecargaDuranteEdicion =
    'Guarde o cancele el documento antes de cambiar la precarga.';
  SErrorConsultaAuxiliarActiva =
    'La consulta auxiliar de precarga debe estar cerrada.';
  SErrorSqlPrecargaModificado =
    'La consulta ha cambiado fuera de la precarga. No se ha sustituido ' +
    'el SQL del perfil.';
  STituloBuscarEmpresaFacturarAlbaranes = 'Buscar empresa';
  STituloBuscarProveedorFacturarAlbaranes = 'Buscar proveedor';
  SAlbaranCompraFacturado = '%s/%s: facturado en %s/%s.';
  SAlbaranCompraOmitido = '%s/%s: no procesado por el servidor.';
  SAlbaranCompraFallido = '%s/%s: error: %s';
  SAlbaranCompraPendiente =
    '%s/%s: pendiente; lote detenido tras el error.';
  SAdvertenciaLoteParcial =
    'La facturación se realiza por albarán. Los ya facturados se ' +
    'conservan. Revise el borrador y reintente solo los pendientes.';
  SResumenFacturacionAlbaranesCompra =
    'Facturados: %d. Omitidos: %d. Fallidos: %d. Pendientes: %d.';
  SBorradorResultadoAlbaranesCompra = 'Borrador: %s / %s.';
  // FZ-ISSUE-632: el borrador no copia el n.º de factura del proveedor.
  SAvisoNumeroProveedorBorradorAlbaranesCompra =
    'Si aún no lo tiene, indique en «Ref. proveedor» del borrador el ' +
    'n.º de factura del proveedor antes de cerrarlo: es obligatorio en ' +
    'el libro de IVA soportado.';
  // Rótulos de la variación «Tallas y colores» en sesiones de compra; con
  // otro tipo de variación los sustituyen los nombres de sus atributos
  // (FZ-ISSUE-420).
  SRotuloEjeFilaVariacionSesion = 'Color';
  SRotuloEjePivoteVariacionSesion = 'Talla';
  SRotuloSistemaPivoteVariacionSesion = 'Sistema tallas';
  SRotuloOtroValorFilaVariacionSesion = 'Otro %s';
  SErrorVariacionSesionObligatoria =
    'Hay varios tipos de variación: elige el de la sesión en Datos ' +
    'cabecera antes de grabarla.';
  SErrorVariacionSesionMaterializar =
    'La sesión %s/%s no tiene tipo de variación. Elígelo en Datos ' +
    'cabecera antes de crear los artículos.';
  // Títulos de los modales de incidencias y error al materializar una
  // sesión de compra (FZ-ISSUE-727).
  STituloIncidenciasMaterializacionSesionCompra =
    'Hay incidencias que impiden materializar la sesión:';
  STituloErrorMaterializacionSesionCompra =
    'No se pudo materializar la sesión:';
  SAvisoLineasSesionOtraVariacion =
    'La sesión tiene %d línea(s) con colecciones del tipo de variación ' +
    'anterior. Revisa su «%s».';
  SCaptionPaginaPedidoOriginal = 'Página %d de %d · %.0f%%';
  SCaptionSinPaginasPedidoOriginal = 'Sin páginas TIFF importadas';
  SCaptionColumnaPedidoARecibir = 'A recibir';
  SCaptionColumnaPedidoRecibida = 'Recibida';
  SCaptionColumnaPedidoModeloProveedor = 'Modelo prov.';
  SCaptionColumnaPedidoPrecioCompra = 'Precio compra';
  SCaptionColumnaPedidoPorcentajeIva = '% IVA';
  SCaptionLineasPedidoCompra = 'Líneas';
  SCaptionColumnaCompraTotalUnidades = 'Total uds.';
  STituloEmpresasLibrosIva = 'Empresas';
  STituloLibrosLibrosIva = 'Libros';
  SCaptionEjercicioLibrosIva = 'Ejercicio';
  SCaptionPeriodoLibrosIva = 'Periodo (trimestre o mes)';
  SEtiquetaPeriodoLibrosIva = 'Periodo';
  SFormatoPeriodoLibrosIva = '%d - %s';
  SFormatoNombreArchivoLibrosIva = 'Libros_IVA_%d_%s_%s';
  // FZ-ISSUE-632: aviso no bloqueante del libro de IVA soportado.
  SAvisoSinNumeroProveedorLibrosIva =
    'Hay %d factura(s) de compra en el libro de IVA soportado sin ' +
    'n.º de factura del proveedor, dato obligatorio del libro registro. ' +
    'Indíquelo en «Ref. proveedor» de cada factura:';
  SLineaSinNumeroProveedorLibrosIva = '%s  %s/%s  %s  %s';
  SRestoSinNumeroProveedorLibrosIva = '... y %d más.';
  // FZ-ISSUE-733: borradores sin cerrar que entran en el libro.
  SAvisoFacturasAbiertasLibrosIva =
    'Hay %d factura(s) de compra ABIERTAS (borradores sin cerrar) en el ' +
    'libro de IVA soportado. Entran en el libro igualmente; revíselas y ' +
    'ciérrelas con «Cerrar borrador»:';
  // Listado de documentos proveedor (FZ-ISSUE-609): los textos de la
  // ventana de filtros y los nombres de tipo que viaja en la consulta.
  STituloTiposDocumentoInformeProveedor = 'Tipos doc.';
  STituloSeriesDocumentoInformeProveedor = 'Series doc.';
  SCaptionPedidosInformeProveedor = 'Pedidos';
  SCaptionAlbaranesInformeProveedor = 'Albaranes';
  SCaptionFacturasInformeProveedor = 'Facturas';
  SCaptionDevolucionesInformeProveedor = 'Devoluciones';
  STotalComprasNetasInformeProveedor =
    'COMPRAS NETAS (facturas + albaranes y devoluciones sin facturar)';
  SNombreTipoPedidoInformeProveedor = 'Pedido';
  SNombreTipoAlbaranInformeProveedor = 'Albarán';
  SNombreTipoFacturaInformeProveedor = 'Factura';
  SNombreTipoDevolucionInformeProveedor = 'Devolución';
  // FZ-ISSUE-638: coste y PVP por talla en las sesiones de compra.
  SEtiquetaFilaGeneralPreciosTalla = 'general';
  SFilaResumenPreciosTalla = '%s %s (coste %s)';
  STituloPreciosTallaSesion = 'Coste y PVP por talla - línea %d';
  SColumnaColorPreciosTalla = 'Color';
  SColumnaTallaPreciosTalla = 'Talla';
  SColumnaCostePreciosTalla = 'Coste';
  SColumnaPvpPreciosTalla = 'PVP';
  SInfoPreciosTallaHereda =
    'Coste de la línea: %s. PVP de la línea: %s. Las tallas que ' +
    'conserven el precio de la línea, o se dejen vacías, lo heredan.';
  SInfoPreciosTallaCoeficiente =
    'Al teclear el coste se propone el PVP con el coeficiente %s %% ' +
    'de la sesión.';
  SErrorPreciosTallaSinCeldas =
    'La línea no tiene tallas. Introduzca antes las cantidades.';
  SErrorPreciosTallaNegativo =
    'El precio de %s talla %s no puede ser negativo.';
  STituloConfirmarPreciosTarifa = 'Precios de tarifa de la sesión';
  SCabeceraConfirmarPreciosTarifa =
    'Al materializar se grabarán estas filas en la tarifa %s:';
  SAvisoArticulosConTarifaVigente =
    'Ya tienen precio en la tarifa: %s. ¿Qué hacer con su precio?';
  SOpcionTarifaModificarVigente = 'Modificar las filas vigentes';
  SOpcionTarifaNuevaDesde = 'Crear una tarifa nueva vigente desde:';
  SErrorFechaTarifaNueva =
    'Indique la fecha desde la que estará vigente la tarifa nueva.';

resourcestring
  // Tercera dimensión, fase 4. %s = valor de pestañas y artículo.
  SErrorPestanaLineaSinEjeVariacion =
    'La línea lleva el valor de pestañas %s, pero el tipo de variación ' +
    'del artículo %s no tiene ningún atributo en pestañas.';
  // Botones de la sesión con pestañas. %s = nombre del atributo en
  // pestañas, en minúsculas (copa, tipo de rosca...): sin suponer género
  // ni plural.
  SRotuloOtroValorPestanaSesion = 'Otro valor de %s';
  SRotuloTodosValoresPestanaSesion = 'Todos los valores de %s';
  SCaptionSesionVariosTiposVariacion =
    'Varios tipos de variación por línea';
  SCaptionSesionVariacionDefecto = 'Variación por defecto';
  // %s = nombre del atributo en pestañas.
  SAvisoSinValoresPestanaSesion =
    'No hay valores de %s para repetir la línea: dalos de alta en la ' +
    'colección del atributo.';

resourcestring
  SCaptionPropiedadesFamiliaSesion =
    '&7. Propiedades de la familia';
  SAyudaPropiedadesSesionSinLinea =
    'Seleccione una línea para editar las propiedades de su familia.';
  SAyudaPropiedadesFamiliaSesion =
    'Línea %d · %s. Las propiedades en negrita son obligatorias.';
  SErrorGuardarPropiedadesSesion =
    'No se pudieron guardar las propiedades de la sesión: %s';
  SErrorPropiedadObligatoriaSesion =
    'Línea %d: rellene la propiedad obligatoria «%s» de la familia.';

resourcestring
  SErrorPropiedadesArticuloSesionDiferentes =
    'Línea %d: las filas del mismo artículo tienen valores distintos ' +
    'para la propiedad «%s». Revise las propiedades antes de crear.';

implementation

end.
