{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgCaja                                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes del subsistema de caja, arqueos y traspasos.                     }
{******************************************************************************}
unit inLibMsgCaja;

interface

resourcestring
  SCaptionViajeHojaRuta = 'Viaje';
  SCaptionAlbaranHojaRuta = 'Albarán de entrega';
  SErrorSeleccionViajeHojaRuta =
    'Indique la referencia del viaje y marque al menos una carga.';
  SCaptionLoteHojaRuta = 'Lote';
  SCaptionHojaRutaTransito =
    'Hoja de ruta';
  STextoAyudaHojaRuta =
    'Indique el viaje y marque sus cargas. Una hoja de ruta y un ' +
    'albarán por origen y destino.';
  SErrorHojaRutaSinCargas =
    'No hay mercancía pendiente en este almacén de tránsito.';
  SErrorHojaRutaSinTransito =
    'Seleccione un almacén de tránsito para imprimir su hoja de ruta.';
  SCaptionEntregaHojaRuta =
    'Emisor (empresa)';
  SCaptionRecibeHojaRuta =
    'Receptor (empresa)';
  SCaptionRecibidasHojaRuta =
    'Recibidas';
  SCaptionTarasHojaRuta =
    'Taras';
  SCaptionPerdidasHojaRuta =
    'Perdidas';
  SCaptionTotalHojaRuta =
    'Total unidades cargadas';
  STextoFirmaHojaRuta =
    'Firma de quien recibe: __________________________';
  STextoFechaHojaRuta =
    'Fecha de entrega: __________________________';
  SNotaHojaRutaTransito =
    'Documento de transporte, no factura. Al cambiar de empresa, la TA' +
    ' se genera al recepcionar y se factura desde Facturas proforma.';
  SNotaCotejoHojaRuta =
    'Coteje por número de carga y SKU. En Recepcionar con incidencias ' +
    'anote las unidades recibidas, deterioradas y perdidas.';
  SErrorCreditoSinAlmacenDeposito =
    'Para vender a crédito la empresa %s necesita un almacén de ' +
    'depósitos activo (Archivo > Almacenes, Uso = Depósito).';
  STituloBusquedaArticulosCaja = 'Búsqueda de Artículos en Caja';
  SEstadoArqueoCerrado = 'CERRADO';
  SEstadoSolicitudCompletadoTotal = 'COMPLETADO TOTAL';
  SEstadoSolicitudCompletadoParcial = 'COMPLETADO PARCIAL';
  SEstadoSolicitudDenegadoTotal = 'DENEGADO TOTAL';
  SEstadoSolicitudAtendidaTotal = 'ATENDIDA TOTAL';
  SEstadoSolicitudAtendidaParcial = 'ATENDIDA PARCIAL';
  SEstadoSolicitudNoAtendida = 'NO ATENDIDA';
  SEstadoSolicitudNoAplica = 'NO APLICA';
  SEstadoSolicitudCancelada = 'CANCELADA';
  SEstadoSolicitudCerrada = 'CERRADA';
  SEstadoSolicitudReposicion = 'REPOSICION';
  SEstadoSolicitudRechazada = 'RECHAZADA';
  SCaptionModoSolicitudPendiente = 'Pendiente';
  SCaptionModoSolicitudAuto = 'Auto';
  SCaptionModoSolicitudAtendida = 'Atendida';
  SCaptionModoSolicitudRechazadaParcial = 'Rechazada parcial';
  SCaptionModoSolicitudRechazadaTotal = 'Rechazada Total';
  SConceptoEntradaCambio = 'Entrada de cambio';
  SErrorCargaHistoricoSolicitudesTraspaso =
    'No se ha podido cargar el histórico de solicitudes de traspaso: ' +
    'la lista vacía no significa que no haya solicitudes.' +
    sLineBreak + sLineBreak + '%s';

  SCaptionTodosModosSolicitudTraspaso = 'Todos';
  SEditarFormatosTicket = 'Editar formatos de ticket';
  SPulsarEditarFormatosTicket = 'Pulse ... para editar';
  STituloTarifasCaja = 'Tarifas de caja (IVA incluido)';
  SAvisoTarifaCajaInexistente =
    'La tarifa "%s" no existe o está inactiva. Se aplica "%s".';
  SErrorTarifaCajaNoDisponible =
    'Configure una tarifa de caja activa con IVA incluido.';
  SErrorPrecioTarifaCajaNoDisponible =
    'El artículo "%s" no tiene precio vigente con IVA incluido ' +
    'en la tarifa "%s". Se conserva la tarifa anterior.';
  SErrorArticuloCajaSinPrecio =
    'El artículo "%s" no tiene precio vigente con IVA incluido ' +
    'en la tarifa "%s". No se puede añadir a la venta.';
  SErrorParametrosCajaSinContratoEdicion =
    'Los parámetros de caja no ofrecen el contrato de edición.';
  SErrorOperacionCajaNoEncontrada =
    'No se ha encontrado la operación en la caja especificada.';
  STituloOperacionesCajaStock = 'Operaciones de caja';
  SErrorConexionOperacionesCajaSkuNoDisponible =
    'No hay una conexión disponible para la consulta.';
  SErrorCodigoFormaPagoCajaObligatorio =
    'El Código de la Forma de Pago es obligatorio';
  SErrorDescripcionFormaPagoCajaObligatoria =
    'La Descripción de la Forma de Pago es obligatoria';
  SErrorParametrosAplicacionCajaNoConfigurados =
    'No se han configurado los parámetros de aplicación.';
  SErrorParametrosModuloCajaNoConfigurados =
    'No se han configurado los parámetros del módulo de caja.';
  SErrorContextoSesionCajaNoConfigurado =
    'No se ha configurado el contexto de sesión del módulo de caja.';
  SErrorOperacionCajaSinLineas =
    'No se puede grabar una operación sin líneas.';
  SErrorCambioIvaSoloArticuloInmaterial =
    'Seleccione una línea de artículo inmaterial para cambiar su IVA.';
  SErrorRazonSocialClienteFacturaCajaObligatoria =
    'La factura normal necesita la razón social del cliente.';
  SErrorDocumentoFiscalClienteCajaNoValido =
    'El NIF/CIF/NIE del cliente no es válido: ';
  SErrorDocumentoFiscalEmpresaCajaNoValido =
    'El NIF/CIF/NIE de la empresa no es válido: ';
  SErrorCuadreCobroParcialCaja =
    'No se pudo cuadrar tras cobro parcial.';
  SErrorFacturaRectificativaCajaSinOriginal =
    'La rectificativa no tiene factura original asociada.';
  SErrorGuardarTicketCaja =
    'No se ha podido grabar la venta: %s.' + sLineBreak +
    'La operación no se ha registrado. No se ha cobrado nada.';
  SAvisoSerieOcupadaCaja =
    'La serie %s está ocupada por otro puesto. Espere unos ' +
    'segundos y pulse Reintentar.';
  SErrorConfirmacionVentaCaja =
    'No se ha podido confirmar el resultado de la venta.' + sLineBreak +
    'Compruebe el histórico antes de volver a cobrarla.';
  SErrorCuadrarFacturaCaja =
    'Error al cuadrar la factura: %s';
  SAvisoImpresionTrasGrabarCaja =
    'La operación %s se ha grabado correctamente, pero algo falló ' +
    'después de grabarla:' + sLineBreak + '%s' + sLineBreak +
    'No vuelva a cobrarla: puede reimprimirla desde el histórico de ' +
    'operaciones de caja.';
  SAvisoImpresionDepositoCaja =
    'No se pudo imprimir el resguardo del depósito: %s';
  SAvisoImpresionTicketCaja =
    'No se pudo imprimir el ticket: %s';
  SAvisoLimpiezaLineasCaja =
    'No se pudieron quitar de la pantalla las líneas sin importe: %s';
  SAvisoPdfTicketCaja =
    'No se pudo guardar el PDF del ticket: %s';
  SErrorRedimirValeCaja =
    'No se pudo redimir el vale "%s". Filas afectadas: %d. Posibles causas: ' +
    'el vale no existe, ya fue redimido, está caducado o anulado.';
  SErrorContextoSesionTraspasoNoConfigurado =
    'No se ha configurado el contexto de sesión del módulo de traspasos.';
  SErrorSkuTraspasoIncompleto =
    'El artículo "%s" no tiene el SKU completo (elige color/talla). SKU: "%s"';
  SErrorSkuTraspasoNoDisponible =
    'El SKU "%s" del artículo "%s" no existe o está inactivo. Revisa el ' +
    'catálogo o, si procede de una solicitud, deniega la línea.';
  SErrorArticuloSkuTraspasoNoCoincide =
    'La línea del artículo "%s" no corresponde al SKU "%s" (artículo real ' +
    '"%s"). Borra la línea y vuelve a introducirlo.';
  SInfoFechaStockTraspaso = 'Disponibilidad a fecha de caja: %s';
  SErrorStockTraspasoInsuficiente =
    'No hay stock suficiente en el almacén origen (%s):' + sLineBreak + '%s';
  SErrorLineasTraspasoNoDisponibles =
    'No hay líneas que traspasar.';
  SErrorAlmacenDestinoTraspasoNoSeleccionado =
    'Selecciona el almacén destino.';
  SErrorAlmacenesTraspasoCoincidentes =
    'Origen y destino no pueden ser el mismo almacén.';
  SErrorAlmacenOrigenReposicionNoSeleccionado =
    'Selecciona el almacén origen de la reposición.';
  SErrorRangoVentasReposicionNoValido =
    'El intervalo de ventas debe tener fecha y hora válidas y el inicio ' +
    'debe ser anterior al final.';
  SErrorVentasReposicionNoCargadas =
    'Carga primero las ventas de la reposición.';
  SErrorLineasSolicitudTraspasoNoDisponibles =
    'No hay líneas que solicitar.';
  SErrorAlmacenOrigenSolicitudNoSeleccionado =
    'Selecciona el almacén al que solicitas.';
  SErrorSolicitudTraspasoMismoAlmacen =
    'No puedes solicitarte a ti mismo.';
  SErrorSolicitudTraspasoNoCargada =
    'No hay solicitud cargada que denegar.';
  SErrorLineaSolicitudTraspasoNoActualizada =
    'No se ha podido actualizar la línea "%s" de la solicitud %s/%s.';
  SErrorImpresoraTicketsCajaNoConfigurada =
    'No hay impresora de tickets configurada en parámetros ' +
    '(vgerDefPrinter); no se puede abrir el cajón.';
  SErrorContextoImpresoraCajaNoProporcionado =
    'No se ha proporcionado el contexto para la impresora de caja.';
  SErrorReferenciaPagoCajaNoIndicada =
    'Debe introducir la referencia del pago.';
  SErrorFactorCambioCajaNoValido =
    'El factor de cambio debe ser mayor que cero.';
  SErrorHashBlockchainCajaNoIndicado =
    'Debe introducir el hash de la transacción blockchain.';
  SErrorValeCajaNoSeleccionado =
    'No hay ningún vale seleccionado.';
  SErrorPinValeCajaNoIndicado =
    'Introduzca el PIN de seguridad del vale para poder canjearlo.';
  SErrorPinValeCajaIncorrecto =
    'El PIN de seguridad no es correcto.' + sLineBreak +
    'Verifique el código que aparece en el vale físico.';
  SErrorProveedorParametrosCajaNoConfigurado =
    'No se ha configurado el proveedor de edición de parámetros.';
  SErrorParametrosCajaEditablesNoConfigurados =
    'No se han configurado los parámetros de caja editables.';
  SInfoLayoutCajaGuardado =
    'Layout guardado.';
  SInfoParametrosCajaGuardados =
    'Se han guardado %d parámetros correctamente para: %s';
  SInfoParametrosCajaSinCambios =
    'No se han detectado cambios para guardar.';
  SPreguntaSalirParametrosCajaSinGuardar =
    '¿Está seguro de que desea salir sin guardar?';
  SInfoUsuariosParametrosCajaNoEncontrados =
    'No hay usuarios con parámetros guardados para este formulario.';
  STituloCambiarUsuarioParametrosCaja =
    'Cambiar usuario';
  SSolicitudCambiarUsuarioParametrosCaja =
    'Usuarios disponibles:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Introduce el nombre de usuario:';
  SErrorUsuarioParametrosCajaNoEncontrado =
    'Usuario no encontrado: %s';
  SInfoPrecargaCajaGuardada =
    'Precarga guardada.';
  SErrorAsignarUbicacionCaja =
    'Error al asignar Empresa Almacén Caja';
  STituloHoraCaja =
    'Hora de caja';
  SSolicitudHoraCaja =
    'Hora (HH:MM)';
  SErrorHoraCajaNoValida =
    'Hora no válida. Use HH:MM.';
  SErrorUbicacionCajaBuscarOperacionesNoAsignada =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'buscar operaciones.';
  SErrorUbicacionCajaArqueoNoAsignada =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'hacer arqueo.';
  SErrorUbicacionCajaTraspasoNoAsignada =
    'No hay empresa/almacén/caja asignados. Selecciona una caja antes de ' +
    'hacer traspasos.';
  SErrorRectificacionCajaNoAdmiteBorrador =
    'Una rectificación se cierra como ticket rectificativo, no como ' +
    'borrador normal.';
  SErrorClienteBorradorCajaNoAsignado =
    'Asigne un cliente a la operación para emitir borrador.';
  SErrorNifClienteBorradorCajaNoIndicado =
    'El cliente no tiene NIF: complételo en su ficha para poder emitir ' +
    'borrador normal.';
  // FZ-ISSUE-369
  SAvisoTotalCobroCambiaTipoFactura =
    'El total a cobrar pasa de %s a %s: la factura completa lleva el ' +
    'recargo de equivalencia o la retención del cliente y el ticket no.' +
    sLineBreak + 'Revise el cobro y vuelva a pulsar el botón.';
  SErrorFechaSerieEmisionCajaNoValida =
    'No se puede emitir en la serie "%s".' + sLineBreak +
    'El último ticket de esa serie tiene fecha %s, posterior a la fecha ' +
    '%s.' + sLineBreak + 'Elija otra serie para emitir con esta fecha.';
  SAvisoHuecosNumeracionSerieCaja =
    'La serie "%s" tiene huecos en la numeración: faltan %d números entre ' +
    'el %d y el %d.' + sLineBreak +
    'Recuerde que la numeración debe ser correlativa según la ley.';
  SErrorNumeroBorradorCajaNoValido =
    'El número de borrador indicado no es válido.';
  SErrorNumeroBorradorCajaExistente =
    'El número %d ya existe en la serie "%s".';
  SErrorNumeroBorradorCajaNoEsHueco =
    'El número %d no es un hueco de la serie "%s": los huecos están entre ' +
    'el %d y el %d.';
  STituloEnviarDocumentacionCaja =
    'Enviar documentación';
  SSolicitudCorreoDocumentacionCaja =
    'Correo electrónico:';
  SErrorCorreoDocumentacionCajaNoIndicado =
    'Indique una dirección de correo electrónico.';
  SErrorCreditoClienteCajaNoPermitido =
    'Operación denegada: Este cliente no tiene crédito permitido.';
  SErrorImporteCreditoCajaNoPendiente =
    'No hay importe pendiente para pasar a crédito.';
  SAvisoLimiteOperacionesCaja =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorOperacionCajaExportarNoSeleccionada =
    'No hay ninguna operación seleccionada para exportar.';
  SErrorSkuVentaCajaNoExiste =
    'El SKU "%s" no existe en fza_articulos_skus. No se puede vender.';
  SErrorSkuVentaCajaNoActivo =
    'El SKU "%s" no está activo. No se puede vender.';
  SErrorArticuloVentaCajaSinStock =
    'Artículo sin stock. Compruebe stock en almacén.';
  SErrorVendedorCajaNoAsignado =
    'Da de alta el vendedor antes de leer artículos.';
  SErrorCodigoBarrasVentaCajaNoEncontrado =
    'Código de barras no encontrado: %s';
  SErrorArticuloCajaRequiereVariacion =
    'El artículo %s tiene tallas o colores: búsquelo con Buscar (F3) ' +
    'o lea el código de barras de la prenda.';
  SErrorLineaDepositoCajaNoCancelable =
    'No se puede cancelar o eliminar una línea vinculada a un depósito.';
  SErrorArticuloVentaCajaNoEncontrado =
    'Artículo no encontrado';
  SPreguntaCancelarVentaCaja =
    'Hay líneas en la venta actual.' + sLineBreak +
    '¿Desea CANCELAR LA VENTA y salir?';
  SErrorLineaDepositoCajaNoEliminable =
    'No se puede eliminar una línea vinculada a un depósito.' + sLineBreak +
    'Cambie la cantidad a negativo si necesita revertirla.';
  SPreguntaBorrarVentaCaja =
    'Hay una venta en curso.' + sLineBreak +
    '¿Desea BORRAR LA VENTA y salir?';
  SInfoValeCajaEntregar =
    'Entregue el vale al cliente: %s';
  SErrorCorreoOperacionCajaNoEnviado =
    'La operación se ha guardado correctamente, pero no se ha podido enviar ' +
    'el correo.' + sLineBreak + '%s';
  SErrorTipoRectificativaCajaNoIndicado =
    'Debe indicar el tipo de rectificativa.';
  SErrorBorradorRectificarCajaNoEncontrado =
    'No se encontró el borrador %s\%s a rectificar.';
  SErrorClienteDepositosCajaNoSeleccionado =
    'Debe seleccionar un cliente para cargar sus depósitos.';
  SErrorValoresAtributoCajaNoDefinidos =
    'No hay valores definidos para este atributo.';
  SPreguntaEliminarOperacionCajaPendiente =
    'La Operación %d tiene artículos pendientes.' + sLineBreak +
    '¿Desea ELIMINARLA y cerrar?';
  SErrorArticuloCajaNoEncontradoDescatalogado =
    'ARTÍCULO NO ENCONTRADO O DESCATALOGADO';
  SErrorCantidadArticuloDepositoCajaNoValida =
    'En artículos de depósito solo está permitido cambiar el signo de la ' +
    'cantidad.';
  SErrorPorcentajeDtoCajaFueraDeRango =
    'El porcentaje de descuento debe estar entre 0 y 100.';
  SErrorCodigoClienteCajaNoExiste =
    'El código de cliente no existe.';
  SErrorEmpleadoCajaNoEncontrado =
    'No se encontró ningún empleado válido.';
  SErrorSolicitudesTraspasoPendientesNoEncontradas =
    'No hay solicitudes pendientes de atender.';
  SErrorCargarSolicitudTraspaso =
    'No se pudo cargar la solicitud.';
  SErrorSolicitudTraspasoCerrarNoCargada =
    'Trae primero una solicitud (F7) para cerrarla.';
  SPreguntaCerrarSolicitudTraspaso =
    '¿Cerrar la solicitud dejando las líneas sin servir como no atendidas?';
  SInfoSolicitudTraspasoCerrada =
    'Solicitud cerrada.';
  SErrorDenegarSolicitudTraspasoModoNoValido =
    'Denegar solo aplica al atender una solicitud.';
  SErrorSolicitudTraspasoDenegarNoCargada =
    'Trae primero una solicitud (F7) para denegarla.';
  STituloDenegarSolicitudTraspaso =
    'Denegar petición';
  SSolicitudMotivoRechazoTraspaso =
    'Motivo del rechazo (lo verá quien la pidió):';
  SErrorMotivoDenegacionTraspasoNoIndicado =
    'Debes indicar un motivo para denegar.';
  SInfoPeticionTraspasoDenegada =
    'Petición denegada (DENEGADO TOTAL).';
  SInfoSolicitudTraspasoEnviada =
    'Solicitud %s/%s enviada.';
  SErrorEmpleadoTraspasoNoIndicado =
    'Indica el empleado responsable del traspaso.';
  SErrorEmpleadoTraspasoNoEncontrado =
    'Empleado no encontrado: %s';
  SErrorSolicitudTraspasoAtenderNoCargada =
    'Carga primero una solicitud (botón Cargar solicitud).';
  SErrorMotivoLineasTraspasoNoIndicado =
    'Indica el motivo en las líneas que no sirves enteras (a 0 o por ' +
    'debajo de lo pedido).';
  SInfoSolicitudTraspasoAtendida =
    'Solicitud atendida. Traspaso %s grabado.';
  SPreguntaDenegarPeticionTraspasoCompleta =
    'No has marcado nada para servir. ¿Denegar toda la petición?';
  SInfoTraspasoGrabado =
    'Traspaso %s grabado correctamente.';
  // FZ-ISSUE-215: traspasos con almacén de tránsito en dos pasos.
  SErrorDestinoFinalTransitoNoValido =
    'El destino final de la carga no puede ser el almacén de tránsito ' +
    'ni el de origen.';
  SErrorCargaTransitoNoPendiente =
    'La carga ya no está pendiente de recibir en este almacén: otra caja ' +
    'la ha recibido o se ha anulado.';
  SConceptoRecepcionTransito =
    'Recepción de %s (carga %s)';
  SCaptionRecepcionarTransito =
    'Recepcionar (%d)';
  STituloCargasTransitoPendientes =
    'Cargas en tránsito pendientes de recibir en %s';
  SInfoCargasTransitoRecibidas =
    'Cargas recibidas: %d. Operaciones: %s.';
  SErrorDestinoFinalTransitoNoElegido =
    'Elija el almacén que recibirá la carga.';
  SInfoCargaTransitoGrabada =
    'Carga %s grabada: queda en %s pendiente de recibir en %s.';
  SCaptionUsarAlmacenTransito =
    'Usar almacén de tránsito';
  SHintUsarAlmacenTransito =
    'La mercancía viaja en una furgoneta o agencia hasta el almacén ' +
    'destino. Elija en el desplegable el almacén de tránsito.';
  SErrorAlmacenTransitoNoSeleccionado =
    'Elija el almacén de tránsito en el que viaja la carga o desmarque ' +
    '«Usar almacén de tránsito».';
  SCaptionRecibirCargasTransito =
    'Recibir';
  SCaptionColFechaCargaTransito =
    'Fecha de carga';
  SCaptionColOrigenCargaTransito =
    'Origen';
  SCaptionColTransitoCargaTransito =
    'Tránsito';
  SCaptionColNombreCargaTransito =
    'Nombre';
  SCaptionColDocumentoCargaTransito =
    'Documento';
  SCaptionColUnidadesCargaTransito =
    'Unidades';
  // FZ-ISSUE-256 y 257: cargas en tránsito con problemas (recepción con
  // unidades deterioradas o perdidas y desbloqueo desde el origen).
  SErrorCargaTransitoNoDesbloqueable =
    'La carga ya no está pendiente o no salió de este almacén: no se ' +
    'puede desbloquear.';
  SErrorMotivoDesbloqueoTransitoVacio =
    'Indique el motivo del desbloqueo de la carga.';
  SErrorNuevoDestinoTransitoNoValido =
    'El nuevo destino debe ser un almacén activo de uso estándar, ' +
    'distinto del origen, del tránsito y del destino actual.';
  SErrorRepartoTransitoLineasAjenas =
    'El reparto de la recepción incluye artículos que no son de la carga.';
  SErrorRepartoTransitoNoCuadra =
    '%s: se cargaron %s y entre recibidas, deterioradas y perdidas ' +
    'suman %s.';
  SErrorAlmacenTarasTransitoNoIndicado =
    'Hay unidades deterioradas: elija el almacén de taras que las recibe.';
  SErrorAlmacenTarasTransitoNoValido =
    'El almacén %s no es un almacén de taras activo de esta empresa.';
  SErrorDesbloqueoTransitoSinPermiso =
    'No tiene permiso para desbloquear cargas en tránsito.';
  SConceptoDeterioroTransito =
    'Deterioro en transporte de %s a %s (carga %s)';
  SConceptoPerdidaTransito =
    'Pérdida en transporte de %s (carga %s)';
  SConceptoDevolucionTransito =
    'Devolución de %s (carga %s)';
  SCaptionRecibirConIncidenciasTransito =
    'Con incidencias';
  STituloRepartoCargaTransito =
    'Recepción con incidencias: carga %s de %s';
  SCaptionMostrarIncidenciasReparto =
    'Mostrar incidencias';
  SEtiquetaAlmacenTarasTransito =
    'Almacén de taras para lo deteriorado:';
  SInfoSinAlmacenTarasTransito =
    'Esta empresa no tiene ningún almacén de taras activo: no se pueden ' +
    'recibir unidades deterioradas.';
  SCaptionColSkuRepartoTransito =
    'Artículo';
  SCaptionColDescripcionRepartoTransito =
    'Descripción';
  SCaptionColCargadaRepartoTransito =
    'Cargadas';
  SCaptionColRecibidaRepartoTransito =
    'Recibidas';
  SCaptionColDeterioradaRepartoTransito =
    'Deterioradas';
  SCaptionColPerdidaRepartoTransito =
    'Perdidas';
  SCaptionColMotivoRepartoTransito =
    'Motivo / observaciones';
  SPreguntaConfirmarIncidenciasTransito =
    'Se van a anotar %s unidades deterioradas y %s perdidas. ¿Continuar?';
  SInfoCargaTransitoRecibidaIncidencias =
    'Carga %s recibida. Operaciones: %s.';
  SCaptionCargasEnviadasTransito =
    'Enviadas (%d)';
  STituloCargasEnviadasTransito =
    'Cargas en tránsito enviadas desde %s';
  SInfoSinCargasEnviadasTransito =
    'No hay cargas en tránsito enviadas desde este almacén.';
  SCaptionDevolverCargaTransito =
    'Devolver al origen';
  SCaptionCambiarDestinoCargaTransito =
    'Cambiar destino';
  SCaptionPerderCargaTransito =
    'Dar por perdida';
  SCaptionColDestinoCargaTransito =
    'Destino';
  SCaptionColDiasCargaTransito =
    'Días';
  STituloMotivoDesbloqueoTransito =
    'Desbloquear la carga %s';
  SPreguntaMotivoDevolverTransito =
    'Motivo de la devolución al origen:';
  SPreguntaMotivoPerderTransito =
    'Motivo por el que se da por perdida:';
  SPreguntaMotivoCambiarDestinoTransito =
    'Motivo del cambio de destino:';
  SPreguntaConfirmarDevolverTransito =
    'La carga %s vuelve de %s a %s. ¿Continuar?';
  SPreguntaConfirmarPerderTransito =
    'La carga %s (%s unidades) se dará por perdida: sale de %s y no ' +
    'entra en ningún almacén. ¿Continuar?';
  SInfoCargaTransitoDevuelta =
    'Carga devuelta al origen. Operación %s.';
  SInfoCargaTransitoPerdida =
    'Carga dada por perdida. Operación %s.';
  SInfoCargaTransitoAnulada =
    'La carga no tenía mercancía en el tránsito: queda anulada.';
  SInfoCargaTransitoDestinoCambiado =
    'La carga %s queda pendiente de recibir en %s.';
  STituloNuevoDestinoTransito =
    'Nuevo destino de la carga';
  SEtiquetaNuevoDestinoTransito =
    'La carga %s iba a %s. Almacén que la recibirá:';
  SCaptionIncidenciasTransito =
    'Incidencias';
  STituloIncidenciasTransito =
    'Pérdidas y deterioros en transporte de %s';
  SInfoSinIncidenciasTransito =
    'No hay pérdidas ni deterioros en transporte anotados para este ' +
    'almacén.';
  SCaptionExcelIncidenciasTransito =
    'Excel';
  SCaptionReclamacionIncidenciaTransito =
    'Reclamación';
  STituloReclamacionIncidenciaTransito =
    'Reclamación al transportista';
  SPreguntaReclamacionIncidenciaTransito =
    'Referencia de la reclamación:';
  SNombreArchivoIncidenciasTransito =
    'Incidencias_transporte_%s';
  SCaptionColFechaIncidenciaTransito =
    'Fecha';
  SCaptionColTipoIncidenciaTransito =
    'Tipo';
  SCaptionColCargaIncidenciaTransito =
    'Carga';
  SCaptionColCosteIncidenciaTransito =
    'Coste';
  SCaptionColImporteIncidenciaTransito =
    'Importe';
  SCaptionColTarasIncidenciaTransito =
    'Taras';
  SCaptionColUsuarioIncidenciaTransito =
    'Usuario';
  STituloCargasTransito =
    'Cargas en tránsito';
  SCaptionFiltroTransito =
    'Tránsito:';
  SCaptionFiltroOrigen =
    'Origen:';
  SCaptionFiltroDestino =
    'Destino:';
  SCaptionFiltroEstadoCarga =
    'Estado:';
  SCaptionTodosAlmacenesFiltro =
    '(todos)';
  SCaptionRefrescarCargasTransito =
    'Refrescar';
  STextoAyudaCargasTransito =
    'Las cargas se reciben y se desbloquean desde la caja: ' +
    '«Recepcionar (n)» en el destino y «Enviadas (n)» en el origen.';
  SCaptionEstadoCargasPendientes =
    'Pendientes';
  SCaptionEstadoCargasTodas =
    'Todas';
  SCaptionEstadoCargasRecibidas =
    'Recibidas';
  SCaptionEstadoCargasConIncidencias =
    'Recibidas con incidencias';
  SCaptionEstadoCargasDevueltas =
    'Devueltas al origen';
  SCaptionEstadoCargasPerdidas =
    'Perdidas';
  SCaptionEstadoCargasAnuladas =
    'Anuladas';
  SCaptionIncidenciasTransporte =
    'Pérdidas y deterioros en transporte';
  SCaptionColNumeroCargaTransito =
    'Nº';
  SCaptionColEstadoCargaTransito =
    'Estado';
  SCaptionColOperacionCargaTransito =
    'Operación';
  SCaptionColCierreCargaTransito =
    'Documento de cierre';
  SCaptionColFechaCierreCargaTransito =
    'Fecha de cierre';
  SCaptionColCajaCierreCargaTransito =
    'Caja';
  SCaptionColDesbloqueoCargaTransito =
    'Desbloqueo';
  SCaptionColMotivoDesbloqueoCargaTransito =
    'Motivo del desbloqueo';
  SCaptionColUsuarioDesbloqueoCargaTransito =
    'Usuario del desbloqueo';
  SCaptionColDestinoInicialCargaTransito =
    'Destino inicial';
  SCaptionColIncidenciasCargaTransito =
    'Incidencias';
  SCaptionColEmpresaCargaTransito =
    'Empresa';
  SCaptionColEstadoReclamacionIncidencia =
    'Estado reclamación';
  SCaptionColReclamadoIncidenciaTransito =
    'Reclamado';
  SCaptionColIndemnizadoIncidenciaTransito =
    'Indemnizado';
  SCaptionFiltroReferenciaReclamacion =
    'Referencia:';
  SEtiquetaEstadoReclamacionTransito =
    'Estado de la reclamación:';
  SEtiquetaImporteReclamadoTransito =
    'Importe reclamado:';
  SEtiquetaImporteIndemnizadoTransito =
    'Importe indemnizado (vacío si aún no se sabe):';
  SInfoAlcanceReclamacionTransito =
    'Se anota en %d incidencias. Los importes son el total de la ' +
    'reclamación y se reparten según el coste de cada una.';
  SPreguntaReclamacionCargaCompleta =
    'La carga %s tiene %d incidencias. ' + sLineBreak +
    '¿Anotar la reclamación en todas?';
  SEstadoReclamacionPendiente =
    'Pendiente';
  SEstadoReclamacionEnviada =
    'Enviada';
  SEstadoReclamacionAceptada =
    'Aceptada';
  SEstadoReclamacionCobrada =
    'Cobrada';
  SEstadoReclamacionRechazada =
    'Rechazada';
  SErrorEstadoReclamacionTransito =
    'Elija el estado de la reclamación.';
  SErrorImporteReclamacionTransito =
    'Los importes de la reclamación no pueden ser negativos.';
  SInfoVentasReposicionNoEncontradas =
    'No hay ventas en el intervalo indicado.';
  SInfoReposicionAutoEmitida =
    'Reposición automática %s/%s emitida.';
  SErrorEmpleadoGastoCajaNoIndicado =
    'Introduzca el empleado que realiza la operación.';
  SErrorImporteGastoCajaNoValido =
    'Introduzca un importe mayor que cero.';
  STituloAvisoCaja =
    'Aviso';
  SErrorArqueoCajaNoSeleccionado =
    'Seleccione un arqueo del listado.';
  SErrorPermisoResumenArqueoCaja =
    'No tiene permiso para consultar el resumen del arqueo.';
  SAvisoArqueoCajaSoloCambioHora =
    'No tiene permiso para cambiar el día del arqueo. Puede cambiar ' +
    'la hora, dentro del %s.';
  SAvisoArqueoCajaOperacionesSinCerrar =
    'Esta caja tiene %d operaciones sin cerrar desde su último ' +
    'arqueo, del %s. El arqueo empieza a continuación de ese cierre ' +
    'para incluirlas y que el efectivo cuadre.';
  SInfoOperacionesFacturadasArqueoCajaNoEncontradas =
    'No hay operaciones facturadas en el rango seleccionado.';
  STituloTiraCaja =
    'Tira de Caja';
  SErrorVendedorArqueoCajaNoIndicado =
    'Debe indicar el número de empleado de caja del vendedor que realiza el ' +
    'cierre.';
  STituloVendedorArqueoCajaObligatorio =
    'Vendedor obligatorio';
  SErrorVendedorArqueoCajaNoValido =
    'El número de empleado indicado no existe o no está activo.';
  STituloVendedorArqueoCajaNoValido =
    'Vendedor no válido';
  SErrorArqueoCajaDuplicado =
    'Ya existe un cierre que solapa este rango y caja. No se permite doble ' +
    'cierre.';
  STituloArqueoCajaDuplicado =
    'Arqueo duplicado';
  SErrorRecuentoArqueoCajaNoDisponible =
    'No hay datos de recuento. Pulse Recalcular primero.';
  SErrorRestanteArqueoCajaNoValido =
    'Debe usted meter el recuento válido para que el restante sea válido';
  SPreguntaGrabarArqueoCaja =
    'Se va a grabar el arqueo con los importes recontados.' + sLineBreak +
    'Periodo: %s - %s' + sLineBreak +
    'Las operaciones del rango quedarán marcadas.' + sLineBreak +
    sLineBreak + '¿Desea continuar?';
  STituloConfirmarArqueoCaja =
    'Confirmar Arqueo';
  SPreguntaImprimirJustificanteCierreCaja =
    '¿Desea imprimir el justificante de cierre?';
  STituloJustificanteCierreCaja =
    'Justificante de cierre';
  // R03 - Título de operación de caja real
  STituloOperacionCajaReal = 'Operación - (Caja Real %s)';
  // R11 - Operaciones de caja por SKU
  SCaptionUnaOperacion = '1 operación';
  SCaptionNumOperaciones = '%d operaciones';
  // R12 - Formularios de caja en ejecución
  SCaptionPendienteDevolver = 'Pendiente de devolver';
  SHintSinDescuentoGlobalDeposito =
    'No se puede aplicar descuento global con líneas de depósito';
  SErrorAjusteTotalNoPermitido =
    'No está permitido ajustar el total mediante un descuento.';
  SErrorTotalCobroFueraRango =
    'El total a pagar debe estar entre 0 y %m.';
  SErrorDescuentoPrecisionLinea =
    'No se puede repartir ese importe con la cantidad de esta línea.';
  SCaptionPendienteCobro = 'Pendiente de cobro';
  SCaptionEmpresaAlmacenCaja = 'Empresa %s - Almacén %s - Caja %s';
  STituloOperacionNCajaReal = 'Operación %d - (Caja Real %s)';
  STituloTraspasosAlmacenCaja = 'Traspasos - (Almacén %s · Caja %s)';
  SCaptionVentaContado = 'VENTA CONTADO';
  SCaptionVerHistoricoCaja = 'Ver histórico';
  SCaptionOcultarHistoricoCaja = 'Ocultar histórico';
  SCaptionTotalCero = 'Total 0,00 €';
  SCaptionTotalImporte = 'Total %m';
  SCaptionRectificativaTipo = 'RECTIFICATIVA' + sLineBreak + '%s';
  STituloBusquedaEmpleadosCaja = 'Búsqueda de Empleados en Caja';
  SCaptionCargandoOperaciones = 'Cargando operaciones...';
  SCaptionCargandoOperacionesProgreso =
    'Cargando operaciones: %s / %s';
  SCaptionIrABorrador = 'Ir a borrador';
  SHintIrABorrador = 'Ir a borrador (%s)';
  SCaptionTabBorrador = 'Borrador';
  // La cotización llega ya formateada (FormatFloat, sin ceros sobrantes).
  SCaptionEquivalenciaEurDivisa = '1 EUR = %s %s';
  SCaptionEquivalenciaDivisaEur = '1 %s = %.2n EUR';
  SCaptionImporteMonedaPagoCaja = 'Importe (%s):';
  SCaptionImporteFinalEurPagoCaja = 'Importe final (EUR):';
  SErrorCotizacionNoDisponiblePagoCaja =
    'No se ha podido obtener la cotización de %s. Escríbala a mano.%s';
  SCaptionColCodigoVale = 'Código Vale';
  SCaptionColEmpresaVale = 'Empresa';
  SCaptionColAlmacenEmisorVale = 'Almacén emisor';
  SCaptionColEstadoVale = 'Estado';
  SCaptionColImporteVale = 'Importe';
  SCaptionColFechaEmisionVale = 'Fecha emisión';
  SCaptionColCaducidadVale = 'Caducidad';
  SCaptionColObservacionesVale = 'Observaciones';
  // R13 - Traspasos entre almacenes
  SCaptionModoReposiciones = 'F5 Reposiciones';
  SCaptionVentasDesdeReposicion = 'VENTAS DESDE';
  SCaptionVentasHastaReposicion = 'VENTAS HASTA';
  SCaptionCargarVentasReposicion = 'Cargar ventas';
  SCaptionColDescripcionTraspaso = 'Descripción';
  SCaptionColUdsTraspaso = 'Uds';
  SCaptionColAPedirReposicion = 'A pedir';
  SCaptionColCosteTraspaso = 'Coste';
  SCaptionColStockDestinoTraspaso = 'Stock Destino';
  SCaptionColStockOrigenTraspaso = 'Stock Origen';
  SCaptionColPedidasTraspaso = 'Pedidas';
  SCaptionColMotivoRechazoTraspaso = 'Motivo rechazo';
  SCaptionColSirvoTraspaso = 'Sirvo';
  SCaptionAlmacenOrigen = 'ALMACÉN ORIGEN';
  SCaptionAlmacenDestino = 'ALMACÉN DESTINO';
  SCaptionF12ConTicket = 'F12 Con ticket';
  SCaptionF12EnviarSolicitud = 'F12 Enviar solicitud';
  SCaptionF12ServirConTicket = 'F12 Servir con ticket';
  SCaptionF12EmitirReposicion = 'F12 Emitir reposición';
  SCaptionImporteTraspaso = 'Importe traspaso: %m';
  STituloSolicitudesPendientesAtender =
    'Solicitudes pendientes de atender';
  SCaptionColNumeroSolicitud = 'Número';
  SCaptionColSerieSolicitud = 'Serie';
  SCaptionColFechaSolicitud = 'Fecha / hora';
  SCaptionColPideAlmacen = 'Pide (almacén)';
  SCaptionColEstadoSolicitud = 'Estado';
  SCaptionColLineasSolicitud = 'Líneas';
  SCaptionAtender = 'Atender';
  SCaptionNoAtender = 'No atender';
  SCaptionImprimir = 'Imprimir';
  SCaptionEmpleadoNoEncontrado = '(no encontrado)';
  SCaptionSinStock = 'Sin stock';
  // R14 - Modales de caja: arqueo, gastos y tira
  SCaptionImporteEur = '%s EUR';
  SCaptionDesgloseEfectivo =
    'Efectivo sist. = ventas (%s) + entradas (%s) ' +
    #8722' gastos (%s) + anterior (%s)';
  STituloHistoricoArqueosCaja = 'Histórico de Arqueos · Caja %s';
  SCaptionRetirarSobranteRecuento = 'Retirar sobrante del recuento';
  SCaptionTpvRestringido = 'TPV restringido:';
  STituloTiraCajaNumero = 'Tira de Caja · Caja %s';
  SCaptionTodasLasSeries = '(todas las series)';
  SCaptionAgrupamientoPorTipoDocumento =
    'Por tipo de documento';
  SCaptionAgrupamientoPorOrdenCronologico =
    'Por orden cronológico';
  SCaptionImprimirQrNoDisponible =
    'Imprimir QR Verifactu (no disponible)';
  // R15 - Devoluciones por ticket (F4), motivo y traspaso automático
  SErrorMotivoDevolucionCajaObligatorio =
    'Indique el motivo de la devolución.';
  SErrorTicketDevolucionCajaNoEncontrado =
    'No se ha encontrado ningún ticket con esos datos.';
  SErrorTicketDevolucionCajaEsRectificativa =
    'El documento localizado es una rectificativa. ' +
    'Localice el ticket de venta original.';
  SErrorTicketDevolucionCajaDatosOperacion =
    'Indique empresa, almacén, caja y número de operación.';
  SErrorTicketDevolucionCajaDatosDocumento =
    'Indique la serie y el número del documento.';
  SErrorTicketDevolucionCajaSinSeleccion =
    'Localice primero un ticket válido.';
  SInfoTicketDevolucionCajaLocalizado =
    'Ticket %s\%s — %s — Tienda %s — Total %s €';
  SInfoVentasOrigenSkuCaja =
    'Ventas de los últimos 12 meses que contienen "%s". ' +
    'Elija el ticket de origen o cancele para devolver sin origen.';
  SErrorVentaOrigenCajaSinSeleccion =
    'Seleccione una venta de la lista o cancele.';
  SErrorDevolucionTicketOperacionEnCurso =
    'Termine o cancele la operación en curso antes de cargar ' +
    'una devolución por ticket.';
  SErrorVentaOrigenDevolucionCajaNoActualizada =
    'No se pudo actualizar la devolución del ticket %s\%s. ' +
    'Compruebe la venta original y el importe ya devuelto.';
  SErrorDevolucionCajaSinPendiente =
    'El ticket %s\%s ya está devuelto por completo: ' +
    'no queda ninguna unidad por devolver.';
  SErrorDevolucionCajaSuperaPendiente =
    'No se pueden devolver %s unidades de %s: de %s solo quedan %s ' +
    'por devolver (vendidas %s, ya devueltas %s).';
  SAvisoDevolucionTicketOtraEmpresa =
    'El ticket es de otra empresa: la devolución se grabará como ' +
    'devolución con referencia al ticket de origen, sin ' +
    'rectificativa fiscal.';
  SCaptionDevolucionTicketDe =
    '  —  DEVOLUCIÓN de %s\%s (Tienda %s)';
  // Apartados de prendas con el cliente de Varios
  STituloApartadoCaja = 'Apartar prendas';
  SNombreContactoApartadoCaja = 'Nombre de quien aparta';
  STelefonoContactoApartadoCaja = 'Teléfono';
  SErrorNombreContactoApartadoCaja =
    'Indique el nombre de quien aparta las prendas.';
  SErrorApartadoCajaSinEntrega =
    'Para apartar prendas el cliente tiene que dejar algo a cuenta: ' +
    'anote el pago y vuelva a pulsar Préstamo.';
  SPreguntaCompletarApartadoCaja =
    'El ticket %s\%s tiene %d prenda(s) apartada(s) por %s.' +
    sLineBreak + sLineBreak +
    '¿Cargar el apartado para cobrar el resto?' + sLineBreak +
    '(No = hacer una devolución del ticket)';
  SErrorApartadoCajaOtraCaja =
    'El apartado se hizo en el almacén %s, caja %s. ' +
    'Complételo desde esa caja.';
  SErrorApartadoCajaSinCuenta =
    'El cliente de Varios no tiene cuenta propia: los apartados se ' +
    'completan con F4 (Buscar ticket) y el número del ticket.';
  SCaptionApartadoTicketDe =
    '  —  APARTADO de %s\%s (%s)';
  SErrorEncolarCierreVentasWs =
    'No se pudo encolar el cierre de caja %s para su publicación web.';
  SErrorRepositorioVentasWsNoAsignado =
    'La publicación web está activa, pero no se asignó su repositorio.';
  // FZ-ISSUE-351: traspasos hechos con la app de recuento.
  SCaptionRecogerTraspasoApp =
    'Recoger traspaso app (%d)';
  SCaptionMisPeticionesMini =
    'Peticiones';
  SPreguntaRecogerTraspasoApp =
    'Traspaso hecho con la app (%d de %d):' + sLineBreak + sLineBreak +
    '  %s -> %s' + sLineBreak +
    '  Dispositivo: %s' + sLineBreak +
    '  Terminado: %s' + sLineBreak + sLineBreak +
    '¿Recogerlo ahora? (No = ver el siguiente)';
  SInfoSinTraspasosApp =
    'No hay traspasos de la app pendientes de recoger con origen en %s.';
  SErrorBuscarTraspasosApp =
    'No se pudieron consultar los traspasos de la app:' + sLineBreak + '%s';
  SErrorLeerTraspasoApp =
    'No se pudieron leer las lecturas del traspaso %d de la app:' +
    sLineBreak + '%s';
  SErrorDestinoTraspasoAppNoValido =
    'El traspaso %d de la app va al almacén %s, que no es un destino ' +
    'válido desde %s (inactivo, inexistente o el mismo).';
  SErrorTraspasoAppSinLineas =
    'El traspaso %d de la app no tiene ninguna lectura que se pueda ' +
    'traspasar.';
  SAvisoTraspasoAppDescartadas =
    'No se han cargado %d lecturas (código sin asignar, artículo ' +
    'inexistente o cantidad no positiva):';
  SInfoTraspasoAppCargado =
    'Traspaso %d de la app cargado con destino %s. Revise las líneas y ' +
    'grabe con F11 o F12.';
  SPreguntaTraspasoAppYaGrabado =
    'El traspaso %d de la app ya se grabó en la operación %s, pero el ' +
    'servidor no lo tiene como recogido.' + sLineBreak + sLineBreak +
    '¿Marcarlo ahora como recogido?';
  SErrorTraspasoAppYaGrabado =
    'El traspaso %d de la app ya se grabó en la operación %s. No se ' +
    'graba otra vez.';
  SAvisoMarcarTraspasoAppRecogido =
    'El traspaso se ha grabado, pero no se pudo marcar como recogido en ' +
    'el servidor:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Seguirá apareciendo en «Recoger traspaso app»; al elegirlo se ' +
    'reintenta el marcado sin volver a grabar.';
  SInfoTraspasoAppMarcadoRecogido =
    'Traspaso %d de la app marcado como recogido.';
  // FZ-ISSUE-352: ventas preparadas con la app (F4 ▸ Importar venta).
  SCaptionImportarVentaAppCaja = 'Importar venta de web';
  SErrorVentaAppVentaNoNueva =
    'Abre una venta nueva para importar la venta de la app.';
  SErrorVentaAppYaCargada =
    'Esta venta de la app ya está cargada en el TPV. Grábala o vacía ' +
    'las líneas para importar otra.';
  SErrorVentaAppLineasNoVacias =
    'Deja vacía la venta antes de importar una de la app.';
  SInfoVentaAppSinPendientes = 'No hay ventas de la app pendientes.';
  SErrorVentaAppSinConexion =
    'No se han podido consultar las ventas de la app. Comprueba la ' +
    'conexión a Internet y vuelve a intentarlo.' + sLineBreak +
    sLineBreak + '%s';
  SPreguntaVentaAppImportar =
    'Venta %d de %d:' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    '¿Importar esta venta?';
  SInfoVentaAppYaRecogida = 'Esta venta ya se cobró en un ticket.';
  SErrorVentaAppSinLineas = 'La venta de la app no contiene líneas.';
  SErrorVentaAppNingunaLinea =
    'No se ha podido cargar ninguna línea de la venta de la app:';
  SInfoVentaAppCargada =
    'Venta de la app cargada (%d líneas). Revisa las líneas y cobra: se ' +
    'dará por recogida al grabar el ticket; si no se graba, sigue ' +
    'pendiente.';
  SAvisoVentaAppLineasOmitidas =
    'No se han cargado estas líneas (código desconocido o artículo no ' +
    'permitido en venta):';
  SDetalleVentaAppLineaOmitida = '  %s × %s';
  SAvisoVentaAppNoRecogida =
    'El ticket se ha grabado, pero la venta de la app no se pudo marcar ' +
    'como recogida en el servidor:' + sLineBreak + '%s' + sLineBreak +
    'Se reintentará la próxima vez que se abra «Importar venta de web»; ' +
    'no se volverá a ofrecer.';
  SAvisoVentaAppNoLiberada =
    'No se pudo devolver a pendientes la venta de la app que estaba ' +
    'cargada sin grabar:' + sLineBreak + '%s' + sLineBreak +
    'Seguirá reservada para este TPV.';
  SDetalleStockLoteTraspasoInsuficiente =
    '  %s, lote %s: pides %s, hay %s';
  SCaptionHoyCalendarioCaja = 'Hoy';
  STituloMisPeticionesTraspaso = 'Mis peticiones';
  SCaptionAtajoMisPeticionesTraspaso = 'May+F7';
  SCaptionColEmpresaSeleccionCaja = 'Empresa';
  SCaptionColNombreEmpresaSeleccionCaja = 'Nombre empresa';
  SCaptionColAlmacenSeleccionCaja = 'Almacén';
  SCaptionColNombreAlmacenSeleccionCaja = 'Nombre almacén';
  SCaptionColCajaSeleccionCaja = 'Caja';
  SCaptionColNombreCajaSeleccionCaja = 'Nombre caja';
  STituloBuscarOperacionesCaja =
    'Buscar operaciones — Empresa %s / Almacén %s / Caja %s';
  STipoBilleteDesglose = 'Billete';
  STipoMonedaDesglose = 'Moneda';
  SAyudaDesgloseEfectivo =
    'Teclee en Unidades cuántos billetes y monedas de cada ' +
    'denominación hay en el cajón. Intro baja a la siguiente fila. ' +
    'Al aceptar, el total contado pasa a la fila Efectivo del ' +
    'recuento y se imprime en el justificante de cierre.';
  SPreguntaLimpiarDesglose =
    '¿Desea poner a cero todas las unidades contadas?';

  SFormatoReferenciaOperacionTiraCajaExcel = 'Op.%s';
  STodasSeriesTiraCajaExcel = 'TODAS LAS SERIES';
  SPrefijoSeriesTiraCajaExcel = 'SERIES: ';
  SFormatoTituloTiraCajaExcel = 'TIRA DE CAJA · CAJA %s';
  SFormatoPeriodoTiraCajaExcel = 'DEL %s  AL %s';
  SOrdenCronologicoTiraCajaExcel = 'ORDEN: CRONOLOGICO';
  SOrdenTipoDocumentoTiraCajaExcel = 'ORDEN: POR TIPO DE DOCUMENTO';
  SColumnaTipoTiraCajaExcel = 'Tipo';
  SColumnaFechaTiraCajaExcel = 'Fecha';
  SColumnaDocumentoTiraCajaExcel = 'Documento';
  SColumnaClienteDestinoTiraCajaExcel = 'Cliente/Destino';
  SColumnaSkuTiraCajaExcel = 'SKU';
  SColumnaDescripcionTiraCajaExcel = 'Descripción';
  SColumnaCantidadTiraCajaExcel = 'Cantidad';
  SColumnaImporteTiraCajaExcel = 'Importe';
  SColumnaCobradoTiraCajaExcel = 'Cobrado';
  SColumnaPendienteTiraCajaExcel = 'Pendiente';
  STipoVentaTiraCajaExcel = 'Venta';
  STipoTraspasoTiraCajaExcel = 'Traspaso';
  STipoIngresoTiraCajaExcel = 'Ingreso';
  STipoGastoTiraCajaExcel = 'Gasto';
  STipoCreditoDepositoTiraCajaExcel = 'Crédito (depósito)';
  STituloTraspasosTiraCajaExcel = 'TRASPASOS SALIENTES (ORIGEN)';
  STituloIngresosTiraCajaExcel = 'INGRESOS POR CAJA';
  STituloGastosTiraCajaExcel = 'GASTOS POR CAJA';
  STituloDepositosTiraCajaExcel = 'VENTAS A CREDITO (DEPOSITOS)';
  STituloVentasTiraCajaExcel = 'VENTAS FACTURADAS';
  SSubtotalTraspasosTiraCajaExcel = 'SUBTOTAL TRASPASOS (coste)';
  SSubtotalIngresosTiraCajaExcel = 'SUBTOTAL INGRESOS';
  SSubtotalGastosTiraCajaExcel = 'SUBTOTAL GASTOS';
  SSubtotalDepositosTiraCajaExcel = 'SUBTOTAL DEPOSITOS';
  SSubtotalVentasTiraCajaExcel = 'SUBTOTAL VENTAS';
  SSinOperacionesTiraCajaExcel = 'Sin operaciones';
  STituloResumenTiraCajaExcel = 'RESUMEN';
  SNombreHojaTiraCajaExcel = 'Tira de Caja';
  SFormatoNombreArchivoTiraCajaExcel = 'TiraCaja_%s';

  SInfoSinPeticionesTraspaso =
    'No hay peticiones realizadas para este almacén.';
  SCaptionArticulosPeticionTraspaso =
    'Artículos de la petición';
  SCaptionPeticionesRealizadasTraspaso =
    'Peticiones realizadas y denegadas';
  SCaptionTipoPeticionTraspaso =
    'Tipo';
  SCaptionDireccionPeticionTraspaso =
    'Dirección';
  SCaptionAlmacenSolicitadoTraspaso =
    'Solicitado a (almacén)';
  SCaptionLineasPendientesTraspaso =
    'Líneas pendientes';
  SCaptionLineaPeticionTraspaso =
    'Línea';
  SCaptionServidasPeticionTraspaso =
    'Servidas';
  SCaptionNoServidasPeticionTraspaso =
    'No servidas';
  STituloBusquedaEmpleadoTraspaso =
    'Buscar empleado';

  STituloRecuentoEfectivoCaja = 'Recuento de efectivo en Caja';

  SBotonReimprimirPeticion = 'Reimprimir';

  SCabeceraPedidoReposicionTicket = 'PED';
  SCabeceraStockReposicionTicket = 'STK';

  SInfoDeudaOtraTienda =
    'Tiene %s € pendientes en %s (empresa %s).';

implementation

end.
