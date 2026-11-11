{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgVentas                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de clientes y documentos del circuito de ventas.                 }
{******************************************************************************}
unit inLibMsgVentas;

interface

resourcestring
  STituloDevolucionCliente = 'Registrar devolución al cliente';
  SInfoDevolucionClienteRegistrada = 'Devolución al cliente registrada.';
  SAvisoAbonoVentaNoEmitido =
    'Emita la rectificativa antes de generar su efecto de devolución.';
  STituloCoincidenciasCliente = 'Posibles clientes duplicados';
  SResumenCoincidenciasCliente =
    'Se han encontrado %d fichas con el mismo NIF o contacto.';
  SPreguntaCoincidenciasCliente =
    'Sí: guardar una ficha distinta. No: abrir una existente. ' +
    'Cancelar: volver sin guardar.';
  SIdentificacionCoincidenteCliente = 'NIF';
  SContactoCoincidenteCliente = 'Contacto compartido';
  SPreguntaMotivoCoincidenciasCliente =
    'Motivo para conservar las fichas separadas (máximo 500 caracteres):';
  SPreguntaAbrirCoincidenciaCliente =
    'Código de la ficha que desea abrir; se descartará esta edición:';
  SErrorConfirmarCoincidenciasCliente =
    'Hay coincidencias de clientes. Revise y confirme desde su ficha.';
  SErrorMotivoCoincidenciasCliente =
    'Indique un motivo de entre 1 y 500 caracteres.';
  SCaptionPropiedadesArticuloDocumento = 'Propiedades del artículo';
  STituloMovimientosVentasFacturadas =
    'Movimientos de ventas facturadas por artículos y fechas';
  SCaptionOrigenVentasInforme = 'Origen de las ventas';
  SAlcanceVentasFacturadasInforme =
    'Facturas y tickets; excluye albaranes pendientes de facturar';
  SCaptionProveedorEfectosRemesa = 'Proveedor';
  SCaptionClienteEfectosRemesa = 'Cliente';
  STextoEfectosPagadosRemesa = 'pagados';
  STextoEfectosCobradosRemesa = 'cobrados';
  STituloBuscarEmpresaEfectosRemesa = 'Buscar empresa';
  STituloCargarEfectosRemesaCobro = 'Cargar efectos en remesa de cobro';
  STituloCargarEfectosRemesaPago = 'Cargar efectos en remesa de pago';
  SCaptionCrearRemesaCobro = 'Crear nueva remesa de cobro';
  SCaptionAnyadirRemesaCobro = 'Añadir a una remesa de cobro existente';
  SCaptionRemesaCobroExistente = 'Remesa de cobro existente';
  SCaptionCrearRemesaPago = 'Crear nueva remesa de pago';
  SCaptionAnyadirRemesaPago = 'Añadir a una remesa de pago existente';
  SCaptionRemesaPagoExistente = 'Remesa de pago existente';
  SErrorPorcentajeDescuentoVenta =
    'El descuento debe estar entre 0 y 100.';
  SErrorAgruparDescuentosVenta =
    'Los documentos tienen descuentos distintos. ' +
    'Genere documentos separados para conservar sus descuentos.';
  SErrorNumeracionDocumentoDemasiadoLarga =
    'La numeración supera los 12 dígitos admitidos.';
  // FZ-ISSUE-390
  SErrorNumeracionSerieOcupada =
    'La serie %s (%s) tiene ocupados los números siguientes al ' +
    'contador. Revise el contador de la serie o use otra serie.';
  SAvisoSerieSinContadorActivo =
    'La serie %s (%s) no tiene contador activo.';
  SAvisoAdministradorActivarContador =
    'Avise a un administrador para crear o activar el contador.';
  SPreguntaActivarContadorDocumento =
    '¿Crear/activar el contador y continuar la grabación?';
  SAvisoAdministradorRevisarContador =
    'Avise a un administrador para revisar el contador.';
  SErrorTarifaClienteNoDisponible =
    'La tarifa "%s" no existe o está inactiva. Seleccione otra tarifa.';
  SCaptionAltaRapidaCliente = '&Alta rápida';
  STituloAltaRapidaCliente = 'Alta rápida de cliente';
  SCaptionGuardarAltaRapidaCliente = '&Guardar cliente';
  SCaptionRazonSocialAltaRapida = 'Razón social:';
  SCaptionNifAltaRapida = 'NIF:';
  SCaptionDireccionAltaRapida = 'Dirección:';
  SCaptionCodigoPostalAltaRapida = 'Código postal:';
  SCaptionPoblacionAltaRapida = 'Población:';
  SCaptionProvinciaAltaRapida = 'Provincia:';
  SCaptionPaisAltaRapida = 'País:';
  SCaptionComprobarNifAltaRapida = 'Comprobar NIF';
  SErrorRazonSocialAltaRapidaCliente = 'Indique la razón social del cliente.';
  SErrorNifAltaRapidaCliente = 'Indique el NIF del cliente.';
  SErrorPaisAltaRapidaCliente = 'Seleccione el país del cliente.';
  SPreguntaBorrarAlbaran =
    '¿Borrar el albarán %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas y se revertirán los movimientos de stock.';
  SAvisoAlmacenSalidaAlbaranObligatorio =
    'Debe seleccionar el almacén de salida del albarán.';
  SAvisoClienteAlbaranObligatorio =
    'Debe seleccionar un cliente antes de guardar el albarán. Si la ' +
    'venta no es a un cliente identificado, use el cliente genérico ' +
    '(venta al contado o público).';
  SAvisoClienteAlbaranNoExiste =
    'El cliente %s no existe. Seleccione un cliente válido antes de ' +
    'guardar el albarán.';
  SErrorCabeceraAlbaranSinGrabar =
    'Graba la cabecera del albarán antes de guardar líneas.';
  SErrorAsignarLineaAlbaran =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en ' +
    'la base de datos.';
  SErrorContadorAlbaran =
    'No se pudo obtener un número de albarán válido. Revise el contador ' +
    'AV de la serie %s y empresa %s.';
  SErrorRazonSocialCliente =
    '%s no es un valor válido para el campo Razón Social de Cliente';
  SErrorTipoDestinoDocumentoTrabajo =
    'El tipo de destino debe ser USUARIO o GRUPO.';
  SErrorDestinoCompartidoNoExiste =
    'El usuario o grupo indicado no existe.';
  SErrorDestinoCompartirObligatorio =
    'Indique el usuario o grupo con el que comparte.';
  SErrorCompartirDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede compartir el Documento de Trabajo.';
  SErrorCabeceraDocumentoTrabajoSinGrabar =
    'Grabe primero la cabecera del Documento de Trabajo.';
  SErrorCompartirDocumentoTrabajoConsigoMismo =
    'No es necesario compartir el documento consigo mismo.';
  SErrorBorrarDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede borrar un Documento de Trabajo.';
  SErrorCambiarPropietarioDocumentoTrabajo =
    'El propietario del Documento de Trabajo no se puede cambiar.';
  SErrorTituloDocumentoTrabajoObligatorio =
    'Indique el titulo del Documento de Trabajo.';
  SErrorEstadoDocumentoTrabajoNoValido =
    'El estado del Documento de Trabajo debe ser CREADO, ENVIADO o ' +
    'ARCHIVADO.';
  SErrorModificarDocumentoTrabajoNoPermitido =
    'Solo se pueden modificar documentos propios en estado CREADO.';
  SErrorEnviarDocumentoTrabajoNoPermitido =
    'Solo se pueden enviar documentos en estado CREADO.';
  SErrorArchivarDocumentoTrabajoNoPermitido =
    'Solo se pueden archivar documentos propios en estado CREADO o ENVIADO.';
  SErrorActualizarEstadoDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede cambiar el estado del Documento de Trabajo.';
  SErrorActualizarEstadoDocumentoTrabajo =
    'No se pudo actualizar el estado del Documento de Trabajo. ' +
    'Actualice la lista y vuelva a intentarlo.';
  SPreguntaArchivarDocumentoTrabajo =
    '¿Archivar el Documento de Trabajo seleccionado?';
  SInfoDocumentoTrabajoArchivado =
    'Documento de Trabajo archivado.';
  SErrorReabrirDocumentoTrabajoNoPermitido =
    'Solo se pueden reabrir documentos propios en estado ENVIADO o ' +
    'ARCHIVADO.';
  SPreguntaReabrirDocumentoTrabajo =
    '¿Devolver el Documento de Trabajo seleccionado al estado CREADO?' +
    #13#10 + 'Podrá modificarlo y volver a enviarlo.';
  SInfoDocumentoTrabajoReabierto =
    'Documento de Trabajo en estado CREADO: ya puede modificarlo y ' +
    'volver a enviarlo.';
  SPreguntaMarcarEnviadoDocumentoTrabajo =
    '¿Marcar como ENVIADO el Documento de Trabajo seleccionado?' +
    #13#10 + 'Quedará bloqueado para edición.';
  SInfoDocumentoTrabajoMarcadoEnviado =
    'Documento de Trabajo marcado como ENVIADO.';
  SErrorBorrarLineasDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede borrar líneas del Documento de Trabajo.';
  SErrorEditarLineasDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede editar líneas del Documento de Trabajo.';
  SErrorDejarCompartirDocumentoTrabajoSoloPropietario =
    'Solo el propietario puede dejar de compartir el Documento de Trabajo.';
  SErrorDestinoCompartidoObligatorio =
    'Indique el usuario o grupo con el que se comparte.';
  SErrorBorrarEfectoVentaRemesado =
    'No se puede borrar el efecto: pertenece a una remesa. Quítalo desde ' +
    'Remesas de cobro.';
  SErrorBorrarEfectoVentaCobrado =
    'No se puede borrar el efecto: tiene cobro o conciliación registrada.';
  SErrorFusionarEfectosVentaEstado =
    'Solo se pueden fusionar efectos pendientes, sin cobros, sin remesa y ' +
    'sin conciliación previa.';
  SErrorFusionarEfectosVentaOrigen =
    'Solo se pueden fusionar efectos de la misma empresa y cliente.';
  SErrorFusionarEfectosVentaSinPendiente =
    'Los efectos seleccionados no tienen importe pendiente.';
  SErrorOperacionIntracomunitariaClienteNoUE =
    'La operación "%s" es intracomunitaria, pero el cliente no es de la UE ' +
    '(país %s). Corrija el tipo de operación o el país del cliente.';
  SErrorOperacionExportacionClienteNoExtranjero =
    'La operación "%s" es exportación fuera de la UE, pero el cliente es ' +
    'comunitario o nacional. Corrija el tipo o el país del cliente.';
  SErrorNifIvaClienteExtranjero =
    'El cliente es extranjero (país %s) y Verifactu exige su NIF-IVA. ' +
    'Indique el NIF del cliente.';
  SErrorRazonSocialClienteBorrador =
    'Debe escribir la razón social del cliente del borrador';
  SErrorPaisClienteEmpresaBorrador =
    'Debe seleccionar un país para cliente y empresa.';
  SPedidoVentaConEntregasNoBorrable =
    'No se puede borrar el pedido de venta %s / %s: tiene entregas o ' +
    'albaranes vinculados. Revierta primero los documentos posteriores.';
  SPreguntaBorrarPedidoVenta =
    '¿Borrar el pedido de venta %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas y se descontará el pendiente de servir en ' +
    'stock.';
  SErrorCabeceraPedidoSinGrabar =
    'Graba la cabecera del pedido antes de guardar líneas.';
  SErrorAsignarLineaPedido =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en la ' +
    'base de datos.';
  SAvisoAlmacenSalidaPedidoObligatorio =
    'Debe seleccionar el almacén de salida del pedido.';
  SAvisoClientePedidoObligatorio =
    'Debe seleccionar un cliente antes de guardar el pedido.';
  SAvisoClientePedidoNoExiste =
    'El cliente %s no existe. Seleccione un cliente válido antes de guardar ' +
    'el pedido.';
  SErrorRemesaVentaNoSeleccionada = 'Selecciona una remesa.';
  SErrorRemesaVentaNoEncontrada =
    'No se encuentra la remesa de venta.';
  SErrorRemesaVentaSinEfectosPendientes =
    'La remesa no tiene efectos pendientes.';
  SErrorGuardarCodigoAcreedorSepa =
    'No se pudo guardar el código acreedor SEPA.';
  SErrorGuardarMandatoSepaCliente =
    'No se pudo guardar el mandato SEPA del cliente %s.';
  SPreguntaCrearDocumentoTrabajo =
    'Si = crear un Documento de Trabajo nuevo.' + sLineBreak +
    'No = agregar a uno abierto existente.';
  STituloAgregarDocumentoTrabajo =
    'Agregar a Documento de Trabajo';
  STituloNuevoDocumentoTrabajo =
    'Nuevo Documento de Trabajo';
  SSolicitudTituloDocumentoTrabajo = 'Titulo';
  SInfoUnidadAgregadaDocumentoTrabajo =
    'Unidad agregada al Documento de Trabajo.';
  STituloDocumentoTrabajo = 'Documento de Trabajo';
  SInfoLineaPedidoTallaNoExiste =
    'No existe línea de pedido para esa talla.';
  SErrorContextoSinIban = '%s sin IBAN.';
  SErrorContextoIbanNoValido =
    '%s con IBAN no válido: %s';
  SErrorNifEmpresaAcreedorSepaNoValido =
    'NIF de empresa no válido para acreedor SEPA: %s';
  SErrorClienteSinMandatoSepa =
    'Cliente %s sin mandato SEPA.';
  STextoBancoCobroRemesa = 'Banco de cobro de la remesa';
  SErrorConexionGenerarRemesaSepa =
    'No hay conexión para generar la remesa SEPA.';
  SErrorArchivoSalidaSepaNoIndicado =
    'Indica el archivo de salida SEPA.';
  SErrorRemesaSinFechaCobro =
    'La remesa no tiene fecha de cobro.';
  SErrorBancoCobroRemesaNoEncontrado =
    'No se encuentra el banco de cobro de la remesa.';
  SErrorBancoCobroSinCodigoAcreedorSepa =
    'El banco de cobro no tiene código acreedor SEPA.';
  SErrorCodigoAcreedorSepaNoValido =
    'Código acreedor SEPA no válido: %s';
  SErrorEfectoSinNombreCliente =
    'Efecto sin nombre de cliente.';
  STextoClienteSepa = 'Cliente %s';
  SErrorClienteSinFechaFirmaMandatoSepa =
    'Cliente %s sin fecha de firma del mandato SEPA.';
  SPreguntaAbrirSeriesAlbaranVenta =
    'No hay series de albaranes de venta mayor (tipo AV) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorAlbaranVentaNoAbierto =
    'No está abierto el albarán de venta.';
  SErrorAlbaranVentaNoInicializado =
    'No está inicializado el albarán.';
  SErrorCrearSeleccionarAlbaranAntesLineas =
    'Crea o selecciona un albarán antes de añadir líneas.';
  SPreguntaEliminarLineaAlbaranVenta =
    '¿Está seguro de que desea eliminar esta línea?';
  SErrorAlbaranVentaSinLineas =
    'El albarán no tiene líneas.';
  SAvisoSeleccionarLineasBorradorAlbaran =
    'Seleccione las líneas para crear borrador en la rejilla ' +
    '(Ctrl+click para selección múltiple).';
  SAvisoLineasAlbaranConBorrador =
    'Las líneas seleccionadas ya tienen borrador.';
  SPreguntaGenerarBorradorLineasAlbaran =
    '¿Generar borrador con %d línea(s) del albarán?';
  SPreguntaGenerarBorradorTodoAlbaran =
    '¿Crear borrador con todas las líneas pendientes del albarán?';
  SAvisoAlbaranSinPedidoVenta =
    'Este albarán no procede de ningún pedido de venta.';
  SAvisoAlbaranSinBorrador =
    'Este albarán no tiene borrador creado.';
  SInfoIbanValidado = 'IBAN Validado OK';
  SErrorEfectosVentaFusionInsuficientes =
    'Selecciona dos o más efectos imcobrados.';
  SErrorDocumentoTrabajoNoSeleccionadoListado =
    'Seleccione un Documento de Trabajo antes de sacar el listado.';
  SErrorDocumentoTrabajoSinGrabarListado =
    'Grabe el Documento de Trabajo antes de sacar el listado.';
  SErrorDocumentoTrabajoSinLineasListado =
    'El Documento de Trabajo no tiene líneas para el listado.';
  SErrorDocumentoTrabajoNoSeleccionadoCargar =
    'Seleccione un Documento de Trabajo antes de cargar.';
  SErrorCargarDocumentoTrabajoNoPropietario =
    'Solo el propietario puede cargar artículos en el documento.';
  SErrorDocumentoTrabajoSinGrabarCargar =
    'Grabe el Documento de Trabajo antes de cargar.';
  STituloCargarOrigenDocumentoTrabajo =
    'Cargar desde documento';
  SCaptionTodosTiposOrigenDocumentoTrabajo = 'Todos';
  SDescripcionTipoOrigenAlbaranVentaDocumentoTrabajo =
    'Albarán de venta';
  SDescripcionTipoOrigenAlbaranCompraDocumentoTrabajo =
    'Albarán de compra';
  SDescripcionTipoOrigenPedidoVentaDocumentoTrabajo =
    'Pedido de venta';
  SDescripcionTipoOrigenPedidoCompraDocumentoTrabajo =
    'Pedido de compra';
  SDescripcionTipoOrigenFacturaVentaDocumentoTrabajo =
    'Factura de venta';
  SDescripcionTipoOrigenFacturaCompraDocumentoTrabajo =
    'Factura de compra';
  SDescripcionTipoOrigenDevolucionCompraDocumentoTrabajo =
    'Devolución a proveedor';
  SDescripcionTipoOrigenVentaTpvDocumentoTrabajo =
    'Venta TPV';
  SDescripcionTipoOrigenTraspasoDocumentoTrabajo =
    'Traspaso';
  SDescripcionTipoOrigenPeticionTraspasoDocumentoTrabajo =
    'Petición de traspaso';
  SDescripcionTipoOrigenPropuestaTraspasoDocumentoTrabajo =
    'Propuesta de traspaso';
  SDescripcionTipoOrigenSesionCompraDocumentoTrabajo =
    'Sesión de compra';
  SDescripcionTipoOrigenInventarioDocumentoTrabajo =
    'Inventario';
  SDescripcionTipoOrigenSesionTarifasDocumentoTrabajo =
    'Sesión de cambio de tarifas';
  SDescripcionTipoOrigenPresupuestoVentaDocumentoTrabajo =
    'Presupuesto';
  SErrorServicioCargaOrigenDocumentoTrabajo =
    'No está disponible el servicio de carga desde documentos.';
  SErrorOrigenDocumentoTrabajoNoSeleccionado =
    'Seleccione un documento de origen.';
  SInfoDocumentosOrigenDocumentoTrabajoNoEncontrados =
    'No se encontraron documentos con esos filtros entre los últimos ' +
    'documentos mostrados.';
  SInfoCargaOrigenDocumentoTrabajo =
    'Se encontraron %d líneas; se añadieron %d y se omitieron %d.' +
    sLineBreak + 'Unidades añadidas: %.2f.';
  SErrorTipoDocumentoOrigenNoSoportado =
    'El tipo de documento origen "%s" no está soportado.';
  SErrorDocumentoOrigenIncompleto =
    'Indique empresa, tipo, serie y número del documento origen.';
  SErrorDocumentoOrigenNoEncontrado =
    'No existe el documento origen %s %s/%s para la empresa %s.';
  SErrorDocumentoOrigenCancelado =
    'No se puede cargar el documento origen %s %s/%s porque está ' +
    'cancelado.';
  SErrorDocumentoOrigenLineasSinSku =
    'No se puede cargar el documento origen porque hay %d líneas de ' +
    'artículo y cantidad sin un SKU compatible registrado.';
  SErrorCargaDocumentoOrigenIncompleta =
    'No se completó la carga del documento origen: se esperaban %d ' +
    'líneas y se insertaron %d.';
  SErrorEmpresaDocumentoTrabajoOrigenDistinta =
    'El documento de trabajo y el documento origen deben ser de la misma ' +
    'empresa.';
  SErrorDocumentoTrabajoNoSeleccionadoCompartir =
    'Seleccione un Documento de Trabajo antes de compartir.';
  SInfoDocumentoTrabajoCompartido = 'Documento compartido.';
  SInfoDocumentoTrabajoYaCompartido =
    'El Documento de Trabajo ya estaba compartido.';
  SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas =
    'Grabe el Documento de Trabajo antes de imprimir etiquetas.';
  SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas =
    'Seleccione un Documento de Trabajo antes de imprimir etiquetas.';
  SErrorDocumentoTrabajoNoSeleccionadoEnviar =
    'Seleccione un Documento de Trabajo antes de enviar.';
  SErrorDocumentoTrabajoSinGrabarEnviar =
    'Grabe el Documento de Trabajo antes de enviar.';
  SErrorDocumentoTrabajoSinLineasEnviar =
    'El Documento de Trabajo no tiene líneas que enviar.';
  SErrorContadorAlbaranDocumentoTrabajo =
    'El contador de albaranes no ha devuelto número para la serie %s.';
  SErrorTerceroEnvioDocumentoTrabajo =
    'Seleccione un cliente o proveedor activo antes de crear el documento.';
  SInfoAlbaranDocumentoTrabajoCreado =
    'Albarán de venta %s/%s creado ABIERTO con %d líneas.';
  STituloEnviarFacturaVentaDocumentoTrabajo =
    'Enviar a borrador de factura de venta';
  SErrorContadorFacturaVentaDocumentoTrabajo =
    'El contador de facturas de venta no ha devuelto número para la ' +
    'serie %s.';
  SInfoFacturaVentaDocumentoTrabajoCreada =
    'Factura de venta %s/%s creada en BORRADOR con %d líneas.';
  STituloEnviarPedidoCompraDocumentoTrabajo =
    'Enviar a pedido de compra';
  SErrorContadorPedidoCompraDocumentoTrabajo =
    'El contador de pedidos de compra no ha devuelto número para la ' +
    'serie %s.';
  SInfoPedidoCompraDocumentoTrabajoCreado =
    'Pedido de compra %s/%s creado ABIERTO con %d líneas.';
  STituloEnviarAlbaranCompraDocumentoTrabajo =
    'Enviar a albarán de compra';
  SErrorContadorAlbaranCompraDocumentoTrabajo =
    'El contador de albaranes de compra no ha devuelto número para la ' +
    'serie %s.';
  SInfoAlbaranCompraDocumentoTrabajoCreado =
    'Albarán de compra %s/%s creado ABIERTO con %d líneas.' + sLineBreak +
    'Aún no se ha generado la entrada de stock.' + sLineBreak +
    'Guarda el albarán para generar la entrada de stock.';
  STituloEnviarDevolucionCompraDocumentoTrabajo =
    'Enviar a devolución a proveedor';
  SErrorContadorDevolucionCompraDocumentoTrabajo =
    'El contador de devoluciones a proveedor no ha devuelto número para ' +
    'la serie %s.';
  SInfoDevolucionCompraDocumentoTrabajoCreada =
    'Devolución a proveedor %s/%s creada ABIERTA con %d líneas.' +
    sLineBreak +
    'Aún no se ha generado la salida de stock.' + sLineBreak +
    'Guarda la devolución para generar la salida de stock.';
  SErrorEmpresaDocumentoTrabajoNoExiste =
    'No existe la empresa %s del Documento de Trabajo.';
  SErrorVentaTpvNoAbiertaDocumentoTrabajo =
    'La venta TPV no está abierta.' + sLineBreak +
    'Abre Caja > Ventas y repite "Enviar a... > Venta TPV" para volcar ' +
    'los SKUs en la operación en curso.';
  SInfoLineasDocumentoTrabajoVolcadasTpv =
    '%d líneas volcadas a la venta TPV.';
  SAvisoLineasDocumentoTrabajoNoVolcadasTpv =
    '%d líneas volcadas a la venta TPV; %d no se han podido resolver ' +
    '(artículo inexistente o descatalogado).';
  SAvisoSinEfectosCobroImprimir =
    'Este borrador no tiene efectos de cobro que imprimir. Genera primero ' +
    'los efectos.';
  SPreguntaAbrirSeriesPedidoVenta =
    'No hay series de pedidos de venta mayor (tipo PE) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SErrorPedidoVentaNoAbierto =
    'No está abierto el pedido de venta.';
  SErrorClienteNoSeleccionadoPedidoVenta =
    'Debe seleccionar un cliente antes de añadir líneas.';
  SErrorClientePedidoVentaNoExiste =
    'El cliente %s no existe. Seleccione un cliente válido antes de añadir ' +
    'líneas.';
  SErrorPedidoVentaNoInicializado =
    'No está inicializado el pedido.';
  SErrorCrearSeleccionarPedidoAntesLineas =
    'Crea o selecciona un pedido antes de añadir líneas.';
  SPreguntaEliminarLineaPedidoVentaConTallas =
    '¿Está seguro de que desea eliminar esta línea (todas sus tallas)?';
  SPreguntaEliminarLineaPedidoVenta =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaMarcarLineasPendientesAlbaranar =
    'Marcar todas las líneas pendientes para albaranar?';
  SErrorPedidoVentaSinLineas = 'El pedido no tiene líneas';
  SErrorPedidoVentaSinCantidadAlbaranar =
    'No hay líneas con cantidad a albaranar para crear el albarán.';
  // FZ-ISSUE-336: lote o serie al crear el albarán desde el pedido.
  SErrorPedidoAlbaranLotesInsuficientes =
    'No se puede crear el albarán: %s (%s) no tiene existencias ' +
    'suficientes por lote o número de serie en %s (faltan %s). ' +
    'Regularice el stock o cree el albarán a mano eligiendo los lotes.';
  SErrorPedidoAlbaranLoteCaducado =
    'No se puede crear el albarán: la salida de %s (%s) desde %s se ' +
    'llevaría el lote caducado %s. Cree el albarán a mano eligiendo los ' +
    'lotes.';
  SAvisoAlbaranPedidoCreadoSinRefresco =
    'El albarán %s/%s se ha guardado, pero no se pudo actualizar ' +
    'la pantalla. Cierre y vuelva a abrir el pedido. Detalle: %s';
  SErrorAnadirAlbaranDesdePedidoVenta =
    'No se pudo añadir al albarán.';
  SErrorCrearAlbaranDesdePedidoVenta =
    'No se pudo crear el albarán.';
  SErrorBancoPagoRemesaNoAsignado =
    'Asigna primero el banco de pago de la remesa.';
  SInfoBancoPagoRemesaAsignado =
    'Banco de pago asignado.';
  SErrorAsignarBancoPagoRemesa =
    'No se pudo asignar el banco de pago.';
  STituloFechaCargoRemesa = 'Fecha de cargo';
  SSolicitudFechaCargoRemesa = 'Fecha de cargo:';
  SInfoFechaCargoRemesaActualizada =
    'Fecha de cargo actualizada.';
  SErrorActualizarFechaCargoRemesa =
    'No se pudo actualizar la fecha de cargo.';
  SErrorFechaCargoRemesaNoValida = 'Fecha no válida.';
  SErrorEliminarRemesaVentaConCobro =
    'No se puede eliminar una remesa con cobro realizado.';
  SPreguntaEliminarRemesaVenta =
    '¿Eliminar la remesa seleccionada? Los efectos volveran a quedar ' +
    'pendientes de remesar.';
  SInfoRemesaVentaEliminada = 'Remesa eliminada.';
  SErrorEliminarRemesaVenta =
    'No se pudo eliminar la remesa.';
  SErrorAnadirEfectosRemesaVentaConCobro =
    'No se pueden añadir efectos a una remesa con cobro realizado.';
  SErrorEfectosRemesaVentaNoCargados =
    'No hay efectos cargados.';
  SErrorEfectoRemesaVentaNoSeleccionado =
    'Selecciona un efecto de la remesa.';
  SErrorQuitarEfectosRemesaVentaConCobro =
    'No se pueden quitar efectos de una remesa con cobro realizado.';
  SPreguntaQuitarEfectoRemesaVenta =
    '¿Quitar el efecto seleccionado de la remesa?';
  SInfoEfectoRemesaVentaQuitado =
    'Efecto quitado de la remesa.';
  SErrorQuitarEfectoRemesaVenta =
    'No se pudo quitar el efecto.';
  SErrorBancoCobroRemesaNoAsignado =
    'Asigna primero el banco de cobro de la remesa.';
  SErrorEfectoRemesaVentaSinPendiente =
    'El efecto seleccionado no tiene importe pendiente.';
  STextoEfectoPendienteRemesaVenta =
    'Efecto %d - pendiente %.2f';
  SInfoEfectoRemesaVentaConciliado = 'Efecto conciliado.';
  SErrorConciliarEfectoRemesaVenta =
    'No se pudo conciliar el efecto.';
  SErrorRemesaVentaSinImportePendiente =
    'La remesa no tiene importe pendiente.';
  STextoRemesaVentaPendiente = 'Remesa pendiente %.2f';
  SInfoEfectosRemesaVentaConciliados =
    'Conciliados %d efecto(s).';
  SErrorConciliarRemesaVenta =
    'No se pudo conciliar la remesa.';
  SErrorBancoCobroNoSeleccionado =
    'Selecciona un banco de cobro.';
  SInfoBancoCobroRemesaAsignado =
    'Banco de cobro asignado.';
  SErrorAsignarBancoCobroRemesa =
    'No se pudo asignar el banco de cobro.';
  STituloFechaCobroRemesa = 'Fecha de cobro';
  SSolicitudFechaCobroRemesa = 'Fecha de cobro:';
  SInfoFechaCobroRemesaActualizada =
    'Fecha de cobro actualizada.';
  SErrorActualizarFechaCobroRemesa =
    'No se pudo actualizar la fecha de cobro.';
  SErrorFechaCobroRemesaNoValida = 'Fecha no válida.';
  SInfoOrdenSepaRemesaVentaGenerada =
    'Orden SEPA generada con %d cobro(s).';
  SErrorGenerarOrdenSepaRemesaVenta =
    'No se pudo generar la orden SEPA: %s';
  SErrorDestinoDocumentoTrabajoAddBlock =
    'No se ha recibido el Documento de Trabajo destino.';
  SErrorAlmacenesDocumentoTrabajoAddBlock =
    'Seleccione al menos un almacén para cargar artículos.';
  SErrorAlmacenOrigenYVentaDocumentoTrabajoAddBlock =
    'El almacén %s está marcado a la vez como origen (pestaña 4) y como ' +
    'almacén de ventas (pestaña 6).' + sLineBreak +
    'Con "Cargar artículos sin stock en almacén de ventas" no puede salir ' +
    'ningún SKU: se pide stock en origen y ninguno en ese mismo almacén.' +
    sLineBreak + sLineBreak +
    'Marque en la pestaña 6 las tiendas destino o desmarque esa casilla.';
  SPreguntaConfirmarDocumentoTrabajoAddBlock =
    'Se van a cargar %d SKU en el Documento de Trabajo "%s".' +
    sLineBreak +
    'Solo se añadirán los SKU previsualizados que mantengan la reserva ' +
    'configurada en los almacenes de origen.' + sLineBreak +
    'La cantidad a servir no superará el máximo indicado por SKU.' +
    sLineBreak +
    sLineBreak + '¿Continuar?';
  SCaptionExcluirSkuDocumentoTrabajoAddBlock =
    'Excluir SKU ya en el documento';
  SInfoLineasDocumentoTrabajoAddBlock =
    '%d líneas añadidas al Documento de Trabajo.';
  SErrorInsertarLineasDocumentoTrabajoAddBlock =
    'Error al insertar líneas del documento: ';
  SErrorEmpresaEfectosRemesaNoIndicada =
    'Indica la empresa.';
  SInfoEfectosPendientesRemesaNoEncontrados =
    'No hay efectos pendientes sin remesar para esa empresa.';
  SErrorEfectosRemesaNoSeleccionados =
    'Marca al menos un efecto (Ctrl/Mayus+clic).';
  SErrorRemesaExistenteNoSeleccionada =
    'Elige la remesa existente.';
  SInfoEfectosCargadosRemesa =
    'Cargados %d efecto(s) en la remesa %s / %s.' + sLineBreak +
    'Omitidos (ya remesados o %s): %d.';
  SErrorSerieAlbaranSesionNoIndicada =
    'Indica la serie del albarán.';
  SErrorSeriePedidoSesionNoIndicada =
    'Indica la serie del pedido.';
  SInfoAlbaranesPendientesProveedorNoEncontrados =
    'No hay albaranes pendientes de crear borrador para ese proveedor.';
  SErrorBorradorAlbaranesExistenteNoSeleccionado =
    'Elige el borrador existente al que incorporar los albaranes.';
  SInfoAlbaranesGeneradosEnBorrador =
    'Generados %d albarán(es) en el borrador %s / %s.' + sLineBreak +
    'Omitidos (ya asociados o incompatibles): %d.';
  SErrorDataModuleAlbaranesNoAsignado =
    'No hay datamodule de albaranes asignado.';
  SErrorAlbaranesNoSeleccionados =
    'No hay albaranes seleccionados.';
  SErrorClienteBorradorNoSeleccionado =
    'Seleccione el cliente del borrador.';
  SErrorDataModulePedidosNoAsignado =
    'No hay datamodule de pedidos asignado.';
  SInfoImportacionPedidosFinalizada =
    'Importación finalizada. Pedidos importados: %d. Errores: %d.';
  SErrorAlmacenPedidoNoSeleccionado =
    'Selecciona un almacén.';
  SInfoAlbaranesIncorporarNoDisponibles =
    'No hay albaranes a los que incorporar; crea uno nuevo.';
  SErrorSerieAlbaranPedidoNoIndicada =
    'Indica la serie del albarán.';
  SErrorAlmacenAlbaranNoSeleccionado =
    'Selecciona un almacén.';
  SErrorAlbaranDestinoNoSeleccionado =
    'Selecciona el albarán al que añadir las líneas.';
  SErrorCodigoAcreedorSepaNoIndicado =
    'Indica el código acreedor SEPA.';
  SErrorLongitudCodigoAcreedorSepa =
    'El código acreedor SEPA no puede superar 35 caracteres.';
  SErrorFormatoCodigoAcreedorSepaNoValido =
    'Código acreedor SEPA no válido. En España debe tener formato ESkkZZZ ' +
    'seguido del NIF.';
  SErrorSecuenciaSepaNoValida =
    'Secuencia SEPA no válida.';
  SErrorClientesSinMandatoSepa =
    'Hay clientes sin mandato SEPA.';
  SErrorMandatosSepaLongitudNoValida =
    'Hay mandatos SEPA de más de 35 caracteres.';
  SErrorClientesSinFechaFirmaMandatoSepa =
    'Hay clientes sin fecha de firma del mandato SEPA.';
  // R04 - Documentos de trabajo
  STituloImpresionEtiquetasDTR =
    'Impresion de Etiquetas de Documento de Trabajo';
  // R07 - Pedidos de venta
  SCaptionTabLineasPedidoTallas3Filas =
    '&1_Líneas [Tallas horiz. 3 filas]';
  SCaptionTabTotalesPedido = '&2_Totales';
  SCaptionTabLineasPedidoSku = '&1_Líneas [SKU]';
  SCaptionTabLineasPedidoDesglose = '&1_Líneas [Desglose]';
  SCaptionLineasAnadidasAlbaranPedido =
    'Líneas añadidas al albarán desde el pedido %s/%s';
  SCaptionAlbaranCreadoPedido =
    'Albarán creado desde el pedido %s/%s';
  // R08 - Remesas de venta
  SCaptionCrearRemesa = 'Crear remesa';
  // R09 - Modales de venta y documentos de trabajo
  SCaptionDocumentoDestino = 'Documento destino: %d - %s';
  STituloAnadirBloqueDTR = 'Añadir Bloque - Documento de Trabajo';
  SCaptionBuscandoAlbaranes = 'Buscando albaranes...';
  SCaptionAlbaranesEncontrados = 'Albaranes encontrados: %d';
  STituloBusquedaClientes = 'Búsqueda de Clientes';
  // R10 - Informes y listados de ventas
  SCaptionFiltrarInicioCompras = 'Calcular entradas desde';
  SCaptionEntradasGlobalesMovimientosVentas = 'Entradas globales';
  SCaptionSoloArticulosConVentas = 'Solo artículos con ventas';
  SCaptionArticuloAgrupacionMovimientosVentas = 'Artículo';
  SCaptionColorAgrupacionMovimientosVentas = 'Color';
  SCaptionTallaAgrupacionMovimientosVentas = 'Talla';
  SCaptionCopaAgrupacionMovimientosVentas = 'Copa';
  SCaptionSoloEmitidas = 'Solo emitidas';
  SCaptionLineasCargadas = '%d líneas cargadas';
  SCaptionPrimeraVentaVacia = 'Primera venta: -';
  SCaptionUltimaVentaVacia = 'Última venta: -';
  SCaptionPrimeraVenta = 'Primera venta: %s';
  SCaptionUltimaVenta = 'Última venta: %s';
  SCaptionSinVentas = 'No hay ventas';
  // R11 - Modales de venta: almacén y SEPA
  SCaptionCrearAlbaranDesdePedido = 'Crear albarán desde pedido %s';
  SCaptionCodigoAcreedor = 'Código acreedor';
  SCaptionSecuencia = 'Secuencia';
  SCaptionMandatosPorCliente = 'Mandatos por cliente';
  SCaptionColCodigoMandato = 'Código';
  SCaptionColClienteMandato = 'Cliente';
  SCaptionColMandato = 'Mandato';
  SCaptionColFechaFirmaMandato = 'Fecha firma';
  // Fase 2 - Calendario de ventas tras contrato
  SErrorVentasCalendarioNoRegistrado =
    'El repositorio del calendario de ventas no está registrado.';
  SCaptionConImpuestosMovimientosVentas = 'Precios con impuestos';
  STituloOrdenacionMovimientosVentas = 'Ordenación';
  SCaptionSentidoOrdenMovimientosVentas = ' Dirección ';
  SCaptionPeriodoOrdenMovimientosVentas =
    'Los criterios usan las ventas del periodo seleccionado.';
  SCaptionSeleccioneOrdenMovimientosVentas =
    'Seleccione un criterio de ordenación:';
  SHintOrdenDetalleMovimientosVentas =
    'Ordena cada agrupación por su subtotal y el detalle del último nivel. ' +
    '% vendido es venta sobre compra; % Vtas es sobre la agrupación.';
  SOrdenArticuloDescripcionMovimientosVentas = 'Artículo / descripción';
  SOrdenUnidadesEntradaMovimientosVentas = 'Unidades entrada';
  SOrdenImporteEntradaMovimientosVentas = 'Importe entrada';
  SOrdenUnidadesVentaMovimientosVentas = 'Unidades venta';
  SOrdenImporteVentaMovimientosVentas = 'Importe venta';
  SOrdenImporteCosteMovimientosVentas = 'Importe coste';
  SOrdenBeneficioMovimientosVentas = 'Beneficio';
  SOrdenPorcentajeBeneficioMovimientosVentas = '% beneficio';
  SOrdenVentaEntradaMovimientosVentas = 'Venta - entrada';
  SOrdenPorcentajeVentaEntradaMovimientosVentas = 'Venta / entrada';
  SOrdenMargen1MovimientosVentas = 'Margen 1';
  SOrdenMargen2MovimientosVentas = 'Margen 2';
  SOrdenPorcentajeVendidoMovimientosVentas = '% vendido';
  SOrdenPorcentajeVentasMovimientosVentas = '% Vtas';
  SOrdenAscendenteMovimientosVentas = 'Ascendente';
  SOrdenDescendenteMovimientosVentas = 'Descendente';
  SConfirmarAvanceContadorDocumento =
    'El número %s/%s ya existe.' + #13#10 +
    'El contador está por detrás (último usado: %s).' + #13#10 +
    '¿Avanzar el contador al siguiente libre y reintentar?';
  SConfirmarNumeroManualDocumento =
    'El número %s/%s ya existe.' + #13#10 +
    '¿Usar el siguiente libre, %s, y dejar el contador por encima?';
  SErrorNumeracionTransaccionActiva =
    'Debe revertir la grabación antes de corregir el contador.';
  SErrorContadorNumeracionNoActivo =
    'El contador ha desaparecido o está inactivo. Revise la serie ' +
    'antes de volver a guardar el documento.';
  SCaptionColumnaPedidoLinea = 'Línea';
  SCaptionColumnaPedidoDescripcion = 'Descripción';
  SCaptionColumnaPedidoPedida = 'Pedida';
  SCaptionBandaPedido = 'Pedido';
  SCaptionColumnaPedidoAAlbaranar = 'A albaranar';
  SCaptionColumnaPedidoPendiente = 'Pendiente';
  SCaptionColumnaPedidoPrecioSinIva = 'PVP S/IVA';
  SCaptionColumnaPedidoPrecioConIva = 'PVP C/IVA';
  SCaptionColumnaPedidoPrecioSalida = 'Precio salida';
  SCaptionColumnaPedidoPorcentajeDto = '% Dto.';
  SCaptionColumnaPedidoImporteDto = 'Menos dto.';
  SCaptionColumnaPedidoTarifa = 'Tarifa';
  SCaptionColumnaPedidoImpuestosIncluidos = 'Imp. incl.';
  SCaptionColumnaPedidoTotal = 'Total';
  SCaptionColumnaPedidoAlmacen = 'Almacén';
  SCaptionColumnaAlbaranLote = 'Lote';
  SCaptionColumnaAlbaranCaducidad = 'F. Caducidad';
  SCaptionColumnaAlbaranFacturada = 'Facturada';
  STituloAgrupacionesMovimientosVentasArticulo = 'Agrupaciones';
  SCaptionAlmacenAgrupacionMovimientosVentas = 'Almacén';
  SCaptionProveedorAgrupacionMovimientosVentas = 'Proveedor';
  SCaptionFamiliaAgrupacionMovimientosVentas = 'Familia';
  SCaptionTemporadaAgrupacionMovimientosVentas = 'Temporada';
  SNombreArchivoMovimientosVentasArticulos =
    'Movimientos_ventas_articulos';


implementation

end.
