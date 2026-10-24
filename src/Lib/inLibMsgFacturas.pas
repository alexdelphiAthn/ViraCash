{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgFacturas                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de facturación, borradores, rectificación y tickets.             }
{******************************************************************************}
unit inLibMsgFacturas;

interface

function TituloColumnaProforma(const ACampo: string): string;
function EsCampoValorDocumento(const ACampo: string): Boolean;
function TextoValorDocumento(const ACampo, AValor: string): string;

resourcestring
  SProformaDesde =
    'Desde';
  SProformaHasta =
    'Hasta';
  SProformaEmpresaOrigen =
    'Empresa emisora';
  SProformaEmpresaDestino =
    'Empresa destino';
  SProformaModalidad =
    ' Modalidad ';
  SProformaModoVentas =
    'Ventas (VE): proforma interna no fiscal';
  SProformaModoTraspasos =
    'Traspasos (TA): borrador fiscal de Venta mayor';
  SProformaModoVendidos =
    'Traspasados y vendidos (TV): sólo lo vendido en destino';
  SProformaCargarVales =
    'Cargar vales';
  SProformaGenerar =
    'Generar documentos';
  SProformaRefrescar =
    'Refrescar historial';
  SProformaImprimir =
    'Imprimir selección';
  SProformaConvertir =
    'Pasar a factura normal';
  SProformaAyuda =
    'Cada operación conserva su fecha e identificador. Las ventas ' +
    'rectificadas se incorporan como ajustes posteriores; en TV el ' +
    'periodo acota las ventas de la tienda, no los traspasos.';
  SProformaEmpresaA =
    'Empresa A';
  SProformaEmpresaB =
    'Empresa B';
  SProformaAyudaVales =
    'TV factura lo vendido en destino. Cargar vales crea además ' +
    'una propuesta no fiscal: canjes de A de vales de B suman y ' +
    'los canjes de B de vales de A restan.';
  SProformaColTipo =
    'Tipo';
  SProformaColIdPeriodo =
    'Id. periodo';
  SProformaColEstadoPeriodo =
    'Estado periodo';
  SProformaColSerie =
    'Serie';
  SProformaColNumero =
    'Número';
  SProformaColFecha =
    'Fecha';
  SProformaColDesde =
    'Periodo desde';
  SProformaColHasta =
    'Periodo hasta';
  SProformaColEstado =
    'Estado';
  SProformaColOperaciones =
    'Operaciones';
  SProformaColAjustes =
    'Ajustes';
  SProformaColBase =
    'Base';
  SProformaColImpuestos =
    'Impuestos';
  SProformaColTotal =
    'Total';
  SEstadoDocumentoAbierta = 'ABIERTA';
  SEstadoDocumentoAbierto = 'ABIERTO';
  SEstadoDocumentoAplicado = 'APLICADO';
  SEstadoDocumentoBorrador = 'BORRADOR';
  SEstadoDocumentoRecibido = 'RECIBIDO';
  SEstadoDocumentoConvertido = 'CONVERTIDO';
  SEstadoDocumentoCerrado = 'CERRADO';
  SEstadoDocumentoCerrada = 'CERRADA';
  SEstadoDocumentoPendiente = 'PENDIENTE';
  SEstadoDocumentoRemesado = 'REMESADO';
  SEstadoDocumentoPagado = 'PAGADO';
  SEstadoDocumentoCobrado = 'COBRADO';
  SEstadoDocumentoConciliado = 'CONCILIADO';
  SEstadoDocumentoDevuelto = 'DEVUELTO';
  SEstadoDocumentoAnulado = 'ANULADO';
  SEstadoDocumentoEnviada = 'ENVIADA';
  SEstadoDocumentoCargada = 'CARGADA';
  SEstadoDocumentoParcial = 'PARCIAL';
  SEstadoValeRedimido = 'REDIMIDO';
  SEstadoValeCaducado = 'CADUCADO';
  SFaseFacturaSinVerifactu = 'Sin VERI*FACTU';
  SFaseFacturaVerifactuAceptada = 'VERI*FACTU aceptado';
  STipoFacturaNormal = 'NORMAL';
  STipoFacturaSimplificada = 'SIMPLIFICADA';
  STipoEfectoRecibo = 'Recibo domiciliado';
  STipoEfectoContado = 'Pago al contado';
  STipoEfectoTransferencia = 'Transferencia bancaria';
  STipoEfectoPagare = 'Pagare';
  STipoEfectoConfirming = 'Confirming';
  // FZ-ISSUE-242: recalculo de la factura creada desde albaranes.
  SErrorRecalculoFacturaDesdeAlbaran =
    'No se pudieron recalcular los importes de la factura %s/%s ' +
    'creada desde el albarán: %s';
  SBotonAvisosReferenciasFactura = '&Avisos';
  SHintAvisosReferenciasFactura =
    'Ver los datos de referencia que ya no existen';
  STituloAvisosReferenciasFactura = 'Avisos de referencias - %s / %s';
  SErrorConsultarReferenciasFactura =
    'No se pudieron comprobar las referencias de la factura: %s';
  SAvisoReferenciasFacturaAusentes =
    'Datos de referencia que ya no existen. ' +
    'Se conservan los datos de la factura:';
  SReferenciaFacturaCliente = 'Cliente';
  SReferenciaFacturaFormaPago = 'Forma de pago';
  SReferenciaFacturaAlmacen = 'Almacén';
  SReferenciaFacturaArticulo = 'Artículo';
  SReferenciaFacturaSku = 'SKU';
  SReferenciaFacturaLinea = ' (línea %s)';
  SCaptionPaisClienteBorrador = 'País del cliente';
  SErrorLecturasFacturasNoRegistradas =
    'No se ha registrado el repositorio de lecturas de facturas.';
  SErrorRepositorioFacturaeNoRegistrado =
    'No se ha registrado el repositorio de Facturae.';
  SCliToTbl = 'Cliente: %s pasado correctamente a la tabla de ' +
                     'clientes';
  SEmpToTbl = 'Empresa: %s pasada correctamente a la tabla de '+
                     'empresas';
  SErrorEnviarTicketImpresora =
    'No se pudo enviar el ticket a la impresora "%s".' + sLineBreak +
    '%s' + sLineBreak + 'Se abrirá la vista previa.';
  SInfoTicketEnviadoImpresora =
    'Ticket enviado correctamente a: %s';
  SAvisoAlbaranFacturado =
    'No se puede borrar el albarán: ya está facturado. ' +
    'Borra o deshaz primero la factura vinculada.';
  SPreguntaBorrarClienteConFacturas =
    'El cliente tiene facturas emitidas,  ¿Desea realmente borrar el ' +
    'registro?';
  SPreguntaBorrarEmpresaConFacturas =
    'La empresa tiene facturas emitidas,  ¿Desea realmente borrar el ' +
    'registro?';
  SErrorOperacionSinIvaConCuota =
    'La operación no repercute IVA (intracomunitaria, ISP o exportación), ' +
    'pero la factura tiene IVA (%s). Revise el IVA o el tipo de operación.';
  SErrorCalcularBorradorDetalle =
    'Error al calcular borrador: %s';
  SErrorCalculoBorrador =
    'Error en cálculo de borrador: %s';
  SErrorTipoIvaFactura = 'Tipo de Iva incorrecto';
  SErrorBorrarBorradorFase =
    'El borrador está en fase %s: ya se ha lanzado a Verifactu y no puede ' +
    'borrarse. Use Anular registro fiscal o emita una rectificativa.';
  SPreguntaBorrarFactura =
    '¿Borrar la factura %s / %s?' + sLineBreak +
    'Se eliminarán sus líneas, recibos/efectos y movimientos de stock.';
  SErrorBorrarBorradorEfectosCobrados =
    'El borrador tiene efectos de cobro cobrados, conciliados o remesados. ' +
    'No puede borrarse.';
  SErrorInsertarLineasCabeceraFactura =
    'No se puede insertar líneas sin grabar primero la cabecera: %s';
  SErrorBorradorSinGrabarParaLineas =
    'Debe grabar primero el borrador antes de añadir líneas';
  SErrorSerieFacturaOtraEmpresa =
    'Esta serie es usada por otra empresa. Debe cambiar la serie ';
  SErrorRazonSocialEmpresaBorrador =
    'Debe escribir la razón social de la empresa del borrador';
  SErrorSerieBorradorObligatoria =
    'Debe seleccionar una serie del borrador';
  SErrorFechaBorradorObligatoria =
    'Debe indicar la fecha del borrador.';
  SErrorNifClienteFactura =
    'El NIF/CIF/NIE del cliente no es válido: %s';
  SErrorNifEmpresaFactura =
    'El NIF/CIF/NIE de la empresa no es válido: %s';
  SErrorFechaFacturaAnteriorSerie =
    'La fecha %s es anterior al ultimo borrador de la serie (%s). La ' +
    'numeración debe seguir orden cronologico.';
  SAvisoFechaBorradorFutura =
    'Aviso: la fecha del borrador es posterior a hoy.';
  SErrorFechaFacturarTicketAnteriorMinima =
    'La fecha de la factura no puede ser anterior al %s (primer dia del ' +
    'mismo trimestre del ejercicio anterior).';
  SErrorFechaFacturarTicketFutura =
    'La fecha de la factura no puede ser posterior a hoy.';
  SErrorFechaFacturarTicketAnteriorTicket =
    'La fecha de la factura no puede ser anterior a la del ticket (%s).';
  SErrorAsignarNumeroFactura =
    'No se ha podido asignar número a la factura (serie %s). Revise el ' +
    'contador de la serie.';
  SAvisoHuecoNumeracionFactura =
    'Aviso: hay un salto en la numeración de la serie %s. La ley exige ' +
    'numeración correlativa: el número o números que falten deben cubrirse.';
  SErrorCodigoFacturaeFormaPago =
    '%s no es un código Facturae válido para el campo Código Facturae de ' +
    'Formas de Pago. Use 01..19.';
  SErrorFacturaeFaltaCampo = '- Falta %s.';
  STextoNifParteFacturae = 'NIF de %s';
  STextoRazonSocialParteFacturae = 'razón social de %s';
  STextoDireccionParteFacturae = 'direccion de %s';
  STextoCodigoPostalParteFacturae = 'código postal de %s';
  STextoPoblacionParteFacturae = 'poblacion de %s';
  STextoProvinciaParteFacturae = 'provincia de %s';
  SErrorDocumentoFiscalParteFacturae = '- %s (%s).';
  SErrorFaltaCodigoDir3Facturae =
    '- Falta el código DIR3 de %s.';
  SErrorCodigoDir3LargoFacturae =
    '- El código DIR3 de %s supera 10 caracteres.';
  STextoEmpresaEmisoraFacturae = 'empresa emisora';
  STextoClienteFacturae = 'cliente';
  STextoOficinaContableFacturae = 'la oficina contable';
  STextoOrganoGestorFacturae = 'el organo gestor';
  STextoUnidadTramitadoraFacturae = 'la unidad tramitadora';
  SErrorNombrePersonaFisicaFacturae =
    '- El cliente tiene NIF/NIE de persona física. Rellene el nombre en ' +
    'Parámetros eDoc.';
  SErrorApellidosPersonaFisicaFacturae =
    '- El cliente tiene NIF/NIE de persona física. Rellene los apellidos en ' +
    'Parámetros eDoc.';
  SErrorCodigoPagoFacturaeInvalido =
    '- El código Facturae de la forma de pago debe estar entre 01 y 19.';
  SErrorFacturaeNoExiste =
    '- No existe la factura seleccionada.';
  SErrorFacturaeTipoVentaInvalido =
    '- El eDoc solo se emite desde venta mayor NORMAL.';
  SErrorFacturaeNoConsolidada =
    '- La factura debe estar consolidada antes de emitir eDoc.';
  SErrorFacturaeFechaOficialFaltante =
    '- Falta la fecha oficial de la factura.';
  SErrorLineaFacturaeSinDescripcion =
    '- La línea %s no tiene descripción.';
  SErrorLineaFacturaeCantidadCero =
    '- La línea %s tiene cantidad cero.';
  SErrorFacturaeSinLineas = '- La factura no tiene líneas.';
  SErrorBasesFacturaeNoCuadran =
    '- La suma de bases de líneas no cuadra con cabecera.';
  SErrorTotalesFacturaeNoCuadran =
    '- Los totales de cabecera no cuadran.';
  SErrorEmitirFacturae =
    'No se puede emitir eDoc Facturae:' + sLineBreak + '%s';
  SErrorCertificadoFacturaeNoConfigurado =
    'La empresa de la factura no tiene certificado configurado para firmar ' +
    'eDoc Facturae.';
  SErrorConexionFacturaeNoDisponible =
    'No hay conexión de base de datos para emitir eDoc.';
  SErrorFicheroSalidaFacturaeNoIndicado =
    'No se ha indicado el fichero de salida eDoc.';
  SErrorPorcentajeIvaFueraRango =
    'El porcentaje de IVA debe estar entre 0 y 100';
  SErrorPrecioFacturaNegativo =
    'Los precios no pueden ser negativos';
  SErrorAbrirImpresoraTicket =
    'No se pudo abrir la impresora: %s';
  SErrorIniciarDocumentoImpresora =
    'Error al iniciar documento';
  SErrorEscribirImpresora =
    'Error al escribir en impresora';
  SErrorLimiteDemoFacturas =
    'Límite DEMO.' + sLineBreak + sLineBreak +
    'Ya se han emitido %d facturas el día %s.' + sLineBreak +
    'El límite de la copia DEMO es %d facturas al día.';
  SErrorPreviewTicketNoRegistrado =
    'No se ha registrado el previsualizador de tickets.';
  SErrorRecalcularTotalesFactura =
    'Error al recalcular totales de la factura: %s';
  SErrorFacturaWebserviceNoExiste =
    'No existe la factura %s\%s para enviarla al webservice.';
  SErrorFirmaFacturaRaizIncorrecta =
    '%s: la firma debe envolver RegistroAlta o RegistroAnulacion.';
  STextoRegistroFacturaIndice = 'registro %d';
  SFormatoEtiquetaFactura = 'Factura %s';
  SAvisoFacturaSinPeticionCompletaXml =
    'Factura %s: no incluye PeticionCompletaXml.';
  SErrorFacturaHashPeticionNoCoincide =
    'Factura %s: HashPeticionBase64 no coincide.';
  SErrorFacturaSinRegistroXmlFirmado =
    'Factura %s: falta RegistroXmlFirmado.';
  SErrorFacturaHashRegistroNoCoincide =
    'Factura %s: HashRegistroXmlBase64 no coincide.';
  SErrorFacturaGuardadaSinFirmaXml =
    'Factura %s: hay firma guardada pero el XML no firma.';
  SErrorFacturaSignatureValueNoCoincide =
    'Factura %s: SignatureValue no coincide.';
  STextoFacturacion = 'Facturacion';
  SErrorFicheroFacturacionNoExiste =
    'No existe el fichero de facturacion: %s';
  SErrorFicheroFacturacionRaizIncorrecta =
    'El fichero de facturacion no tiene la raiz esperada.';
  SErrorFicheroFacturacionVacio =
    'El fichero de facturacion no contiene registros.';
  SErrorVerificarFacturacion =
    'No se pudo verificar facturacion: %s';
  SErrorFacturaRequisitosFiscalesNoExiste =
    'No existe la factura %s\%s para validar sus requisitos fiscales.';
  SErrorColumnasFirmaFacturacionNoDisponibles =
    'Faltan columnas de firma en fza_facturas_consolidaciones. Aplique ' +
    'el script DESARROLLOS EN CURSO\verifactu_registros_firmados.sql.';
  SErrorFacturaExtranjeraSinNifIva =
    'La factura %s %s\%s a cliente extranjero requiere el NIF-IVA del ' +
    'destinatario.';
  SErrorFacturaSinNifClienteValido =
    'La factura %s %s\%s requiere un NIF de cliente válido y tiene "%s"';
  SInfoBorradorFacturaCreado =
    'Borrador creado: %s / %s';
  SErrorCrearBorradorFactura =
    'No se pudo crear el borrador.';
  SPreguntaBorrarMovimientosTicketAnulado =
    '¿Desea borrar también los movimientos de almacén asociados al ticket ' +
    '%s\%s?' + sLineBreak +
    'Se revertirá el stock de sus líneas.';
  SPreguntaMovimientosRectificativaSustitutiva =
    '¿Qué desea hacer con los movimientos de almacén de la factura ' +
    'original %s\%s?' + sLineBreak + sLineBreak +
    'Eliminar originales: se revierte su stock y se generan los ' +
    'movimientos de la nueva rectificativa.' + sLineBreak +
    'Mantener originales: se conserva el stock actual y la nueva ' +
    'rectificativa no genera movimientos adicionales.';
  SErrorFacturarTicketRequiereSimplificado =
    'Solo se crea un borrador normal desde un borrador SIMPLIFICADO ' +
    '(ticket).';
  SInfoBorradorSustitucionTicketCreado =
    'Creado el borrador %s\%s en sustitución del ticket %s\%s en modo ' +
    'fiscal %s (F3).';
  SErrorRectificarRectificativa =
    'No se puede rectificar una rectificativa.';
  // Rectificativas de venta mayor (por diferencias / por sustitución)
  SNombreTipoVerifactuR1 =
    'R1 - Error fundado en derecho y art. 80 Uno, Dos y Seis LIVA';
  SNombreTipoVerifactuR2 =
    'R2 - Art. 80 Tres LIVA (concurso de acreedores)';
  SNombreTipoVerifactuR3 =
    'R3 - Art. 80 Cuatro LIVA (crédito incobrable)';
  SNombreTipoVerifactuR4 =
    'R4 - Resto de causas';
  SNombreTipoVerifactuR5 =
    'R5 - Rectificativa de factura simplificada';
  SErrorRectificarFaseNoEmitida =
    'La factura %s\%s no está emitida fiscalmente (fase %s): no se ' +
    'puede rectificar.';
  SErrorRectificativaPendienteExistente =
    'La factura %s\%s ya tiene una rectificativa en BORRADOR: ' +
    'consolídela o bórrela antes de crear otra.';
  SErrorRectificativaSerieObligatoria =
    'Indique la serie del nuevo documento.';
  SErrorRectificativaFechaObligatoria =
    'Indique la fecha del nuevo documento.';
  SErrorRectificativaMotivoObligatorio =
    'Indique el motivo de la rectificación.';
  SErrorRectificativaTipoVerifactuInvalido =
    'El tipo VERI*FACTU "%s" no es válido para rectificar la factura ' +
    '%s\%s.';
  SInfoRectificativaCreadaEmitida =
    'Rectificativa %s\%s creada y emitida en modo fiscal %s.';
  SInfoRectificativaCreadaBorrador =
    'Rectificativa %s\%s creada en BORRADOR. Revise cabecera y líneas ' +
    'y pulse Consolidar para emitirla; la original quedará RECTIFICADA ' +
    'en ese momento.';
  SInfoDuplicadoCreadoEmitido =
    'Borrador %s\%s creado y emitido en modo fiscal %s.';
  // Subsanación del registro fiscal de venta mayor (fase SUBSANACION)
  SCaptionSubsanarRegistro = 'Subsanar registro';
  SCaptionRegistrarSubsanacion = 'Registrar subsanación';
  SErrorSubsanacionSinVerifactu =
    'En modo SIN VERIFACTU la factura se corrige directamente: no hay ' +
    'registro fiscal que subsanar.';
  SErrorSubsanacionSoloVentaMayor =
    'La subsanación del registro sólo está disponible para facturas de ' +
    'venta mayor.';
  SErrorSubsanacionYaIniciada =
    'La factura %s\%s ya está en subsanación: regístrela o cancélela.';
  SErrorSubsanacionFaseNoAdmitida =
    'La factura %s\%s está en fase %s: sólo se subsana una factura con ' +
    'registro fiscal aceptado (VERIFACTU_OK o NOVERIFACTU_OK).';
  SErrorSubsanacionRegistroNoAceptado =
    'La factura %s\%s no tiene un registro fiscal aceptado y ' +
    'encadenado (estado %s).';
  SErrorSubsanacionFacturaColaActiva =
    'La factura %s\%s tiene un envío fiscal en estado %s. Espere a que ' +
    'termine o resuélvalo antes de subsanar.';
  SErrorSubsanacionConRectificativa =
    'La factura %s\%s ya está rectificada por %s\%s: corrija la ' +
    'rectificativa o emita otra.';
  SErrorSubsanacionNoIniciada =
    'La factura %s\%s no está en subsanación.';
  SErrorSubsanacionMotivoObligatorio =
    'Indique el motivo de la subsanación.';
  SErrorSubsanacionEstructuraLineas =
    'En subsanación no se añaden ni borran líneas: sólo se corrigen ' +
    'cantidades y precios. Para otros cambios emita una rectificativa.';
  SErrorSubsanacionLineaCampoFijo =
    'En subsanación sólo se corrigen cantidades y precios de las ' +
    'líneas; el campo %s no se puede cambiar.';
  SErrorCancelarSubsanacionConCambios =
    'La factura %s\%s ya no coincide con el registro aceptado por la ' +
    'AEAT (%s).' + sLineBreak + sLineBreak +
    'No se puede cancelar la subsanación: regístrela, o deje la factura ' +
    'como estaba y vuelva a cancelar.';
  SDetalleSubsanacionImporte = 'importe %s; registrado %s';
  SDetalleSubsanacionCuota = 'cuota %s; registrada %s';
  SDetalleSubsanacionDestinatario = 'destinatario %s; registrado %s';
  SErrorFacturaSinAlmacenStock =
    'La factura %s/%s mueve stock pero la línea %s no tiene almacén ' +
    'y la cabecera tampoco. Indique el almacén en la cabecera y ' +
    'vuelva a consolidar.';
  SErrorSubsanacionCabeceraSoloCliente =
    'En subsanación sólo se corrigen los datos del cliente de la ' +
    'cabecera; el campo %s no se puede cambiar.';
  SErrorAccionFiscalEnSubsanacion =
    'La factura %s\%s está en subsanación: regístrela o cancélela ' +
    'antes de %s.';
  SPreguntaIniciarSubsanacionFactura =
    '¿Abrir la factura %s\%s para subsanar su registro fiscal?' +
    sLineBreak +
    'Podrá corregir los datos del cliente y las cantidades y precios ' +
    'de las líneas; no se añaden ni borran líneas ni cambian número, ' +
    'fecha o emisor. Al pulsar "Registrar subsanación" se enviará a la ' +
    'AEAT un registro corregido con el mismo número de factura y se ' +
    'regenerarán sus movimientos de stock.';
  SInfoSubsanacionFacturaIniciada =
    'Factura %s\%s en subsanación. Corrija los datos, grabe y pulse ' +
    '"Registrar subsanación".';
  STituloMotivoSubsanacionFactura = 'Registrar subsanación';
  SCaptionMotivoSubsanacionFactura = 'Motivo de la subsanación';
  SInfoSubsanacionFacturaEncolada =
    'Subsanación de %s\%s encolada: el hilo Verifactu enviará el ' +
    'registro corregido en el próximo ciclo.';
  SInfoSubsanacionFacturaNoVerifactu =
    'Subsanación de %s\%s registrada y firmada en NO VERI*FACTU.';
  SPreguntaCancelarSubsanacionFactura =
    '¿Cancelar la subsanación de %s\%s sin registrarla? La factura ' +
    'vuelve a su fase de registro.';
  SPreguntaCancelarSubsanacionConCambios =
    'Hay cambios grabados en %s\%s desde que se inició la ' +
    'subsanación. Si cancela, la factura quedará distinta del registro ' +
    'enviado a la AEAT; lo correcto es registrar la subsanación.' +
    sLineBreak + '¿Cancelar de todas formas?';
  SErrorOperacionSinTicket =
    'Esta operación no tiene ticket asociado.';
  SAvisoLimiteRegistrosFacturaSimplificada =
    'La selección cargaría %s registros, demasiados para mostrarlos de una ' +
    'vez.' + sLineBreak +
    'Acota los filtros (años / almacenes) y vuelve a intentarlo.';
  SErrorBorradorVentaMayorNoSeleccionado =
    'Seleccione un borrador de venta mayor.';
  SErrorGuardarAntesEmitirEdoc =
    'Guarde los cambios antes de emitir el eDoc.';
  SErrorPersonaFisicaEdocSinDatos =
    'El cliente tiene NIF/NIE de persona física.' + sLineBreak +
    'Rellene nombre y apellidos en Parámetros eDoc antes de emitir.';
  SInfoEdocEmitido =
    'eDoc emitido correctamente:' + sLineBreak + '%s';
  SPreguntaReemplazarCobros =
    'Hay %s creados, ¿desea reemplazarlos?';
  STituloMensajeAdvertencia = 'Mensaje Advertencia';
  SInfoGeneracionCobrosCancelada =
    'Generación de %s cancelada.';
  SInfoEfectosCobroGenerados =
    'Generados %d efecto(s) de cobro.';
  SAvisoEfectosCobroNoGenerados =
    'No se generaron efectos. Revisa que el borrador tenga forma de pago y ' +
    'total, y que no tenga efectos cobrados o remesados.';
  SErrorGenerarEfectosCobroSinBorrador =
    'No hay borrador activo o no se pudieron generar efectos.';
  SInfoVerifactuUrlNoDisponible =
    'Esta factura todavía no tiene la dirección de validación de '
    + 'Verifactu.';
  SAvisoSinPagosCajaFactura =
    'Este borrador no tiene pagos de caja registrados.';
  SAvisoBorradorPendienteImpresionFiscal =
    'El borrador está pendiente: use el botón Consolidar antes de ' +
    'imprimirlo en este modo fiscal.';
  SErrorGuardarFacturaAntesImprimir =
    'No se pudo guardar la factura antes de imprimir: %s';
  SErrorFacturasFiltradasVacias =
    'No hay facturas en el resultado filtrado.';
  SErrorCambiosPendientesProcesarFiltradas =
    'Guarde o cancele los cambios de la factura antes de procesar ' +
    'el resultado filtrado.';
  SErrorServicioLoteImpresionFacturas =
    'No está disponible el servicio de impresión por lotes.';
  SErrorLoteImpresionFacturas =
    'La impresión por lotes se detuvo tras enviar %d de %d facturas.' +
    sLineBreak + '%s';
  SInfoLoteImpresionFacturas =
    'Impresión por lotes finalizada.' + sLineBreak +
    'Facturas enviadas: %d.' + sLineBreak +
    'Omitidas por no estar consolidadas: %d.';
  SErrorGuardarTrabajoLote =
    'No se pudo generar trabajo_lote.txt: %s';
  SInfoTrabajoLoteGuardado =
    'Resultado guardado en:' + sLineBreak + '%s';
  SInfoEfectoMarcadoDevuelto =
    'Efecto marcado como devuelto.';
  SErrorMarcarEfectoDevuelto =
    'No se pudo marcar el efecto como devuelto.';
  SInfoEfectoMarcadoPendiente =
    'Efecto marcado como pendiente.';
  SErrorMarcarEfectoPendiente =
    'No se pudo marcar el efecto como pendiente.';
  SErrorEfectoSinImportePendiente =
    'El efecto seleccionado no tiene importe pendiente.';
  SErrorBorradorListaNoSeleccionado =
    'Seleccione un borrador en la lista.';
  SErrorBorradorNoCerradoAccionFiscal =
    'El borrador %s\%s aún no está cerrado fiscalmente: no se puede %s.';
  SPreguntaAccionFiscalBorrador =
    '¿%s fiscalmente el borrador %s\%s?';
  SErrorBorradorYaLanzadoFiscalmente =
    'El borrador %s\%s ya se lanzó fiscalmente (fase %s).';
  SErrorBorradorSinLineasLanzar =
    'El borrador no tiene líneas: no se puede lanzar.';
  SErrorBorradorNormalSinNif =
    'Un borrador NORMAL necesita el NIF del cliente para el registro ' +
    'fiscal. Complete los datos del cliente.';
  SPreguntaLanzarBorradorFiscal =
    '¿Lanzar fiscalmente el borrador %s\%s? Dejará de estar en borrador y ' +
    'de ser editable.';
  SErrorBorradorConsolidadoNoReabrible =
    'El borrador %s\%s ya está consolidado en la AEAT: no puede volver a ' +
    'borrador. Use Anular fiscal o emita una rectificativa.';
  SInfoBorradorYaEnBorrador =
    'El borrador ya está en BORRADOR.';
  SPreguntaDevolverBorrador =
    '¿Devolver a BORRADOR el documento %s\%s y anular su envío pendiente ' +
    'a la AEAT?';
  SErrorAltaAeatAceptadaNoReabrible =
    'El alta ya fue aceptada por la AEAT: no se puede volver a borrador. ' +
    'Use Anular fiscal o emita una rectificativa.';
  SErrorBorradorEnProcesoNoReabrible =
    'El hilo Verifactu está enviando este borrador ahora mismo. Espere unos ' +
    'segundos y vuelva a intentarlo.';
  SInfoBorradorReabierto =
    'Borrador %s\%s de nuevo en BORRADOR. Corrija los datos (si el error ' +
    'es de la empresa, arréglelo en Empresas y use "Dar de Alta o ' +
    'Actualizar Empresa" en la pestaña Datos Empresa Emisora para ' +
    'refrescar la copia del borrador) y pulse Consolidar para relanzarla.';
  SPreguntaGrabarFacturaVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SErrorCompletarDatosBorrador =
    'Debe completar los datos del borrador: %s';
  SErrorEmpresaProveedorFacturacionNoIndicados =
    'Indica empresa y proveedor.';
  SPreguntaFacturarTodosAlbaranesListados =
    'No has marcado albaranes (Ctrl/Mayus+clic para elegir).' + sLineBreak +
    'Crear borrador con TODOS los listados?';
  SInfoBorradoresGenerados =
    'Proceso finalizado. Borradores generados: %d.';
  SErrorClienteFacturarTicketNoExiste =
    'El cliente seleccionado no existe.';
  SErrorRazonSocialFacturarTicketObligatoria =
    'La F3 necesita la razón social del cliente.';
  SErrorDocumentoFiscalFacturarTicketNoValido =
    'El NIF/CIF/NIE del cliente no es válido: ';
  SErrorCrearBorradorFacturarTicket =
    'No se pudo crear el borrador: ticket o cliente no encontrados.';
  SErrorFechaTicketSerieNoValida =
    'No se puede grabar el ticket en la serie "%s".' + sLineBreak +
    'El último ticket de esa serie tiene fecha %s, posterior a la fecha de ' +
    'caja %s.' + sLineBreak +
    'Cambie la serie para emitir un ticket con esta fecha.';
  // R03 - Diálogos de rectificativa en consulta de operaciones
  STituloTipoRectificativa = 'Tipo de rectificativa';
  SCaptionPorDiferencias = 'Por diferencias';
  SCaptionSustitutiva = 'Sustitutiva';
  STituloMovimientosAlmacen = 'Movimientos de almacén';
  SCaptionEliminarOriginales = 'Eliminar originales';
  SCaptionMantenerOriginales = 'Mantener originales';
  // R05 - Terminología efectos/recibos y pestañas de borrador
  SCaptionTabEfectos = '&3_Efectos';
  SCaptionGenerarEfectos = 'Generar efectos';
  SCaptionImprimirEfecto = 'Imprimir &recibo';
  // FZ-ISSUE-102.14: recibo impreso de los efectos de venta mayor.
  SCaptionEfectoReciboEfectos = 'Borrador y efectos';
  SCaptionEfectosSeleccionadosReciboEfectos =
    'Imprimir los efectos seleccionados (un recibo por página)';
  SCaptionTodosEfectosReciboEfectos =
    'Imprimir todos los efectos de este borrador';
  SCaptionEfectoPendiente = '&Pendiente';
  SCaptionEfectoCobrado = '&Cobrado';
  SCaptionEfectoDevuelto = '&Devuelto';
  SCaptionColNroBorradorEfecto = 'Nro Borrador Efecto';
  SCaptionColSerieBorradorEfecto = 'Serie Borrador Efecto';
  SCaptionColEfecto = 'Efecto';
  SCaptionColTotalEfecto = 'Total efecto';
  SCaptionColEstadoEfecto = 'Estado efecto';
  SCaptionColFechaEmisionEfecto = 'Fecha emisión efecto';
  SCaptionColFechaCobroEfecto = 'Fecha cobro';
  SCaptionColReferenciaEfecto = 'Referencia';
  SCaptionTabRecibos = '&3_Recibos';
  SCaptionGenerarRecibos = 'Generar &Recibo/s';
  SCaptionImprimirRecibo = 'Imprimir &Recibo';
  SCaptionReciboEmitido = '&Emitido';
  SCaptionReciboPagado = '&Pagado';
  SCaptionReciboDevuelto = '&Devuelto';
  SCaptionColNroBorradorRecibo = 'Nro Borrador Recibo';
  SCaptionColSerieBorradorRecibo = 'Serie Borrador Recibo';
  SCaptionColNroPlazo = 'Nro Plazo';
  SCaptionColTotalRecibo = 'Total Recibo';
  SCaptionColEstadoRecibo = 'Estado Recibo';
  SCaptionColFechaExpedicionRecibo = 'Fecha Expedición Recibo';
  SCaptionColFechaPagoRecibo = 'Fecha Pago Recibo';
  SCaptionColLocalidadExpedicionRecibo = 'Localidad Expedición';
  SCaptionEfectosCobroPlural = 'efectos de cobro';
  SCaptionRecibosPlural = 'recibos';
  SCaptionTabLineasBorradorSku = '&1_Lineas de Borrador [SKU]';
  SCaptionTabLineasBorradorDesglose =
    '&1_Lineas de Borrador [Desglose]';
  SCaptionTabLineasBorradorTallasHoriz =
    '&1_Lineas de Borrador [Tallas horiz.]';
  STituloEmitirEDoc = 'Emitir eDoc';
  SCaptionFiltroFacturae =
    'Facturae firmado (*.xsig)|*.xsig|XML (*.xml)|*.xml';
  SCaptionCargandoBorradores = 'Cargando borradores...';
  SCaptionCargandoBorradoresProgreso = 'Cargando borradores: %s / %s';
  // R09 - Facturación de albaranes por fechas
  SCaptionCreandoBorradoresAlbaranes =
    'Creando borradores de %d albaranes...';
  SCaptionGeneradosBorradores = 'Generados %d borradores';
  // R10 - Informe de efectos de pago
  SCaptionGrupoFecha = ' Fecha ';
  SCaptionFechaDocumento = 'Documento';
  SCaptionFechaValor = 'Valor';
  SCaptionFechaVencimiento = 'Vencimiento';
  SCaptionGrupoSituacion = ' Situación ';
  SCaptionSituacionPagados = 'Pagados';
  SCaptionSituacionImpagados = 'Impagados';
  SCaptionSituacionPendientes = 'Pendientes';
  SCaptionSituacionTodos = 'Todos';
  SCaptionNumEfectoDesde = 'Nº efecto desde:';
  SCaptionNumEfectoHasta = 'Nº efecto hasta:';
  SCaptionMostrarSoloTotales = 'Mostrar sólo totales';
  // R11 - Selección de banco de empresa
  SCaptionCuentaEmpresaPagoEfectos =
    'Cuenta de la empresa para el PAGO (cargo) de los efectos:';
  SCaptionCuentaEmpresaCobroRecibos =
    'Cuenta de la empresa para el COBRO (ingreso) de los recibos:';
  // R15 - Exportación de factura a Excel
  SCaptionHojaFactura = 'Factura %s';
  // Fase 2 - Persistencia de operaciones de facturas tras contrato
  SErrorPersistenciaFacturasNoRegistrada =
    'La persistencia de operaciones de facturas no está registrada.';
  // FZ-ISSUE-358
  SErrorContadorRecibidaInterna =
    'No se pudo obtener número para la factura recibida (serie %s, ' +
    'empresa %s).';
  SInfoRecibidaInternaRegistrada =
    'Factura recibida registrada en la empresa %s: %s/%s.';
  SInfoRecibidaInternaYaExistia =
    'La factura recibida ya estaba registrada en la empresa %s: %s/%s.';
  SComentarioRecibidaInterna =
    'Factura interna recibida de la empresa %s (%s).';
  SCaptionBotonCuadreFacturasInternas =
    'Cuadre facturas internas';
  STituloCuadreFacturasInternas =
    'Cuadre de facturas internas';
  SCabeceraCuadreFacturasInternas =
    'Facturas internas consolidadas del %s al %s, frente a la ' +
    'factura recibida de la empresa destino.';
  SLineaCuadreFacturaInterna =
    '%s  %s/%s  %s  emitida %s  recibida %s  %s';
  STotalCuadrePareja =
    'Total %s: emitido %s, recibido %s, diferencia %s';
  SEstadoCuadreOk =
    'OK';
  SEstadoCuadreSinRecibida =
    'SIN RECIBIDA';
  SEstadoCuadreDiferencia =
    'DIFERENCIA %s';
  SInfoCuadreSinFacturasInternas =
    'No hay facturas internas consolidadas en el periodo.';
  SResumenCuadreFacturasInternas =
    '%d facturas internas; %d sin recibida o con diferencia.';
  // FZ-ISSUE-389
  SPreguntaRegistrarRecibidasPendientes =
    'Hay %d facturas internas sin factura recibida en la empresa ' +
    'destino. ¿Registrarlas ahora?';
  STituloRecibidasRegistradas =
    'Facturas recibidas registradas';
  SAvisoRecibidaInternaNoRegistrada =
    'La factura se ha consolidado, pero no se pudo registrar la ' +
    'factura recibida en la empresa destino:' + sLineBreak + '%s' +
    sLineBreak + 'Regístrala a mano o revisa el cuadre de facturas ' +
    'internas.';
resourcestring
  SCaptionColumnaFacturaNumero =
    'Nro Línea';
  SCaptionColumnaFacturaVendedor =
    'Vendedor';
  SCaptionColumnaFacturaCodigo =
    'Código';
  SCaptionColumnaFacturaVariacion =
    'Variación';
  SCaptionColumnaFacturaCodigoFamilia =
    'Código Familia';
  SCaptionColumnaFacturaNombreFamilia =
    'Nombre Familia';
  SCaptionColumnaFacturaProveedorPrincipal =
    'Proveedor Principal';
  SCaptionColumnaFacturaCodigoProveedor =
    'Código Proveedor';
  SCaptionColumnaFacturaNombreProveedor =
    'Razón Social Proveedor';
  SCaptionColumnaFacturaCoste =
    'Precio Coste';
  SCaptionColumnaFacturaDescripcion =
    'Descripción';
  SCaptionColumnaFacturaCantidad =
    'Cantidad';
  SCaptionColumnaFacturaPrecioSalida =
    'Precio Salida';
  SCaptionColumnaFacturaPorcentajeDto =
    '% Dto';
  SCaptionColumnaFacturaImporteDto =
    'Menos Dto';
  SCaptionColumnaFacturaPrecioSinIva =
    'Precio Ud. sin IVA';
  SCaptionColumnaFacturaImpuestosIncluidos =
    'ImpIncl';
  SCaptionColumnaFacturaTipoIva =
    'Tipo de IVA';
  SCaptionColumnaFacturaPorcentajeIva =
    '% IVA';
  SCaptionColumnaFacturaPrecioConIva =
    'Precio Ud. con IVA';
  SCaptionColumnaFacturaTotalConIva =
    'Total con IVA';
  SCaptionColumnaFacturaTotalSinIva =
    'Total Sin IVA';
  SCaptionColumnaFacturaFechaEntrega =
    'Fecha Entrega';

  STipoDocumentoTrabajoGeneral = 'General';
  SDireccionDocumentoEnviada = 'Enviada';
  SDireccionDocumentoRecibida = 'Recibida';
  STipoSolicitudManual = 'Manual';
  SEstadoDocumentoCreado = 'Creado';
  SEstadoDocumentoEnviado = 'Enviado';
  SEstadoDocumentoArchivado = 'Archivado';
  SEstadoDocumentoImportado = 'Importado';

implementation

uses
  inLibMsgCaja,
  System.SysUtils, inLibMsgArticulos;

function EsCampoEstadoDocumento(const ACampo: string): Boolean;
begin
  Result := SameText(ACampo, 'ESTADO_FACC') or
    SameText(ACampo, 'ESTADO_PEDC') or
    SameText(ACampo, 'ESTADO_ALBC') or
    SameText(ACampo, 'ESTADO_SES') or
    SameText(ACampo, 'ESTADO_PED') or
    SameText(ACampo, 'ESTADO_ALB') or
    SameText(ACampo, 'ESTADO_DTR') or
    SameText(ACampo, 'ESTADO') or
    SameText(ACampo, 'ESTADO_PRE') or
    SameText(ACampo, 'ESTADO_INV') or
    SameText(ACampo, 'ESTADO_EFV') or
    SameText(ACampo, 'ESTADO_EFEC') or
    SameText(ACampo, 'ESTADO_EFECTO') or
    SameText(ACampo, 'ESTADO_REMV') or
    SameText(ACampo, 'ESTADO_REMC') or
    SameText(ACampo, 'ESTADO_VL');
end;

function TituloColumnaProforma(const ACampo: string): string;
begin
  Result := ACampo;
  if ACampo = 'TIPO_DOCUMENTO' then
    Result := SProformaColTipo
  else if ACampo = 'ID_PERIODO' then
    Result := SProformaColIdPeriodo
  else if ACampo = 'ESTADO_PERIODO' then
    Result := SProformaColEstadoPeriodo
  else if ACampo = 'SERIE_DOCUMENTO' then
    Result := SProformaColSerie
  else if ACampo = 'NUMERO_DOCUMENTO' then
    Result := SProformaColNumero
  else if ACampo = 'FECHA_DOCUMENTO' then
    Result := SProformaColFecha
  else if ACampo = 'FECHA_DESDE' then
    Result := SProformaColDesde
  else if ACampo = 'FECHA_HASTA' then
    Result := SProformaColHasta
  else if ACampo = 'EMPRESA_ORIGEN' then
    Result := SProformaEmpresaOrigen
  else if ACampo = 'EMPRESA_DESTINO' then
    Result := SProformaEmpresaDestino
  else if ACampo = 'ESTADO_DOCUMENTO' then
    Result := SProformaColEstado
  else if ACampo = 'CANTIDAD_OPERACIONES' then
    Result := SProformaColOperaciones
  else if ACampo = 'CANTIDAD_AJUSTES' then
    Result := SProformaColAjustes
  else if ACampo = 'TOTAL_BASE' then
    Result := SProformaColBase
  else if ACampo = 'TOTAL_IMPUESTOS' then
    Result := SProformaColImpuestos
  else if ACampo = 'TOTAL_DOCUMENTO' then
    Result := SProformaColTotal;
end;

function EsCampoValorDocumento(const ACampo: string): Boolean;
begin
  Result := SameText(ACampo, 'TIPO_DTR') or
    SameText(ACampo, 'TIPO_TRSOL') or
    SameText(ACampo, 'DIRECCION_TRSOL') or
    SameText(ACampo, 'YA_CARGADO') or
    SameText(ACampo, 'ESTADO_TRSOL') or
    SameText(ACampo, 'ATENDIDA_TRSOL') or
    SameText(ACampo, 'MODO_PETICION_TRSOL') or
    EsCampoEstadoDocumento(ACampo) or
    SameText(ACampo, 'ESTADO_TARC') or
    SameText(ACampo, 'ESTADO_TARCLIN') or
    SameText(ACampo, 'CAMPO_ORIGEN_TARC') or
    SameText(ACampo, 'CAMPO_DESTINO_TARC') or
    SameText(ACampo, 'TIPO_APLICACION_TARC') or
    SameText(ACampo, 'ESAPLICAR_TARCLIN') or
    SameText(ACampo, 'ESCONSOLIDADA_FAC') or
    SameText(ACampo, 'FASE_FAC') or
    SameText(ACampo, 'TIPO_FAC') or
    SameText(ACampo, 'DESCRIPCION_TEFE_VIEW_EFV') or
    SameText(ACampo, 'DESCRIPCION_TEFE_VIEW_EFEC');
end;

function TextoValorDocumento(const ACampo, AValor: string): string;
begin
  Result := AValor;
  if SameText(ACampo, 'TIPO_DTR') then
  begin
    if AValor = 'GENERAL' then Result := STipoDocumentoTrabajoGeneral;
  end
  else if SameText(ACampo, 'DIRECCION_TRSOL') then
  begin
    if SameText(AValor, 'ENVIADA') then Result := SDireccionDocumentoEnviada
    else if SameText(AValor, 'RECIBIDA') then
      Result := SDireccionDocumentoRecibida;
  end
  else if SameText(ACampo, 'ESTADO_TRSOL') or
     SameText(ACampo, 'TIPO_TRSOL') or
     SameText(ACampo, 'ATENDIDA_TRSOL') or
     SameText(ACampo, 'MODO_PETICION_TRSOL') then
  begin
    if AValor = 'COMPLETADO TOTAL' then
      Result := SEstadoSolicitudCompletadoTotal
    else if AValor = 'COMPLETADO PARCIAL' then
      Result := SEstadoSolicitudCompletadoParcial
    else if AValor = 'DENEGADO TOTAL' then
      Result := SEstadoSolicitudDenegadoTotal
    else if AValor = 'ATENDIDA TOTAL' then
      Result := SEstadoSolicitudAtendidaTotal
    else if AValor = 'ATENDIDA PARCIAL' then
      Result := SEstadoSolicitudAtendidaParcial
    else if AValor = 'NO ATENDIDA' then Result := SEstadoSolicitudNoAtendida
    else if AValor = 'NO APLICA' then Result := SEstadoSolicitudNoAplica
    else if AValor = 'PENDIENTE' then Result := SCaptionModoSolicitudPendiente
    else if AValor = 'AUTO' then Result := SCaptionModoSolicitudAuto
    else if AValor = 'MANUAL' then Result := STipoSolicitudManual
    else if AValor = 'ATENDIDA' then Result := SCaptionModoSolicitudAtendida
    else if AValor = 'RECHAZADA PARCIAL' then
      Result := SCaptionModoSolicitudRechazadaParcial
    else if AValor = 'RECHAZADA TOTAL' then
      Result := SCaptionModoSolicitudRechazadaTotal
    else if AValor = 'CANCELADA' then Result := SEstadoSolicitudCancelada
    else if AValor = 'CERRADA' then Result := SEstadoSolicitudCerrada
    else if AValor = 'REPOSICION' then Result := SEstadoSolicitudReposicion
    else if AValor = 'RECHAZADA' then Result := SEstadoSolicitudRechazada
    else if AValor = 'PARCIAL' then
      Result := SCaptionModoSolicitudRechazadaParcial;
  end
  else if SameText(ACampo, 'TIPO_FAC') then
  begin
    if AValor = 'NORMAL' then Result := STipoFacturaNormal
    else if AValor = 'SIMPLIFICADA' then Result := STipoFacturaSimplificada;
  end
  else if SameText(ACampo, 'FASE_FAC') then
  begin
    if AValor = 'BORRADOR' then Result := SEstadoDocumentoBorrador
    else if AValor = 'SIN_VERIFACTU' then
      Result := SFaseFacturaSinVerifactu
    else if AValor = 'VERIFACTU_OK' then
      Result := SFaseFacturaVerifactuAceptada;
  end
  else if SameText(ACampo, 'ESTADO_TARC') or
          SameText(ACampo, 'ESTADO_TARCLIN') then
  begin
    if AValor = 'APLICADA' then Result := SValorTarifaAplicada
    else if AValor = 'BORRADOR' then Result := SEstadoDocumentoBorrador
    else if AValor = 'PENDIENTE' then Result := SEstadoDocumentoPendiente;
  end
  else if SameText(ACampo, 'ESAPLICAR_TARCLIN') or
          SameText(ACampo, 'ESCONSOLIDADA_FAC') or
          SameText(ACampo, 'YA_CARGADO') then
  begin
    if AValor = 'S' then Result := SValorTarifaSi
    else if AValor = 'N' then Result := SValorTarifaNo;
  end
  else if SameText(ACampo, 'CAMPO_ORIGEN_TARC') then
  begin
    if AValor = 'PRECIO_ORIGEN' then Result := SValorTarifaPrecioOrigen
    else if AValor = 'PRECIO_COSTE' then Result := SValorTarifaPrecioCoste
    else if AValor = 'PRECIO_DESTINO_ACTUAL' then
      Result := SValorTarifaPrecioDestinoActual;
  end
  else if SameText(ACampo, 'CAMPO_DESTINO_TARC') then
  begin
    if AValor = 'AMBOS' then Result := SValorTarifaAmbos
    else if AValor = 'PRECIO_SALIDA' then Result := SValorTarifaPrecioSalida
    else if AValor = 'PRECIO_FINAL' then Result := SValorTarifaPrecioFinal;
  end
  else if SameText(ACampo, 'TIPO_APLICACION_TARC') then
  begin
    if AValor = 'COPIAR' then Result := SValorTarifaCopiar
    else if AValor = 'INCREMENTO_LINEAL' then
      Result := SValorTarifaIncrementoLineal
    else if AValor = 'INCREMENTO_PORCENTUAL' then
      Result := SValorTarifaIncrementoPorcentual
    else if AValor = 'PRECIO_FIJO' then Result := SValorTarifaPrecioFijo;
  end
  else if EsCampoEstadoDocumento(ACampo) then
  begin
    if AValor = 'CREADO' then Result := SEstadoDocumentoCreado
    else if AValor = 'ENVIADO' then Result := SEstadoDocumentoEnviado
    else if AValor = 'ARCHIVADO' then Result := SEstadoDocumentoArchivado
    else if AValor = 'IMPORTADO' then Result := SEstadoDocumentoImportado
    else if AValor = 'REPOSICION' then Result := SEstadoSolicitudReposicion
    else if AValor = 'SIN_VERIFACTU' then
      Result := SFaseFacturaSinVerifactu
    else if AValor = 'ABIERTA' then Result := SEstadoDocumentoAbierta
    else if AValor = 'ABIERTO' then Result := SEstadoDocumentoAbierto
    else if AValor = 'APLICADO' then
      Result := SEstadoDocumentoAplicado
    else if AValor = 'BORRADOR' then Result := SEstadoDocumentoBorrador
    else if AValor = 'RECIBIDO' then Result := SEstadoDocumentoRecibido
    else if AValor = 'CONVERTIDO' then Result := SEstadoDocumentoConvertido
    else if AValor = 'CERRADO' then Result := SEstadoDocumentoCerrado
    else if AValor = 'CERRADA' then Result := SEstadoDocumentoCerrada
    else if AValor = 'PENDIENTE' then Result := SEstadoDocumentoPendiente
    else if AValor = 'REMESADO' then Result := SEstadoDocumentoRemesado
    else if AValor = 'PAGADO' then Result := SEstadoDocumentoPagado
    else if AValor = 'COBRADO' then Result := SEstadoDocumentoCobrado
    else if AValor = 'CONCILIADO' then Result := SEstadoDocumentoConciliado
    else if AValor = 'DEVUELTO' then Result := SEstadoDocumentoDevuelto
    else if AValor = 'ANULADO' then Result := SEstadoDocumentoAnulado
    else if AValor = 'REDIMIDO' then Result := SEstadoValeRedimido
    else if AValor = 'CADUCADO' then Result := SEstadoValeCaducado
    else if AValor = 'ENVIADA' then Result := SEstadoDocumentoEnviada
    else if AValor = 'CARGADA' then Result := SEstadoDocumentoCargada
    else if AValor = 'PARCIAL' then Result := SEstadoDocumentoParcial;
  end
  else if EsCampoValorDocumento(ACampo) then
  begin
    // Solo descripciones estándar: los tipos personalizados se conservan.
    if AValor = 'Recibo domiciliado' then Result := STipoEfectoRecibo
    else if AValor = 'Pago al contado' then Result := STipoEfectoContado
    else if AValor = 'Transferencia bancaria' then
      Result := STipoEfectoTransferencia
    else if AValor = 'Pagare' then Result := STipoEfectoPagare
    else if AValor = 'Confirming' then Result := STipoEfectoConfirming;
  end;
end;

end.
