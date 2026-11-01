{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgReparaciones                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de las reparaciones dentro de la gestión de garantías.             }
{******************************************************************************}
unit inLibMsgReparaciones;

interface

resourcestring
  SClaseServicio = 'Clase de servicio';
  SClaseTaller = 'Taller / reparación';
  SClaseAltura = 'Arreglo de altura';
  SClaseInstalacion = 'Instalación';
  SMedidasCita = 'Medidas e instalación';
  SAlturaMedida = 'Altura medida en casa (cm):';
  SLargoFinal = 'Largo final de la cortina (cm):';
  SAcabadoCortina = 'Instrucciones de acabado:';
  SDireccionInstalacion = 'Dirección de instalación:';
  SCitaInstalacion = 'Fecha y hora de la cita:';
  SErrorMedidasCortina = 'Indique medidas mayores que cero y las ' +
    'instrucciones de acabado.';
  SErrorCitaInstalacion = 'Indique la dirección y la fecha y hora de la cita.';
  SErrorClaseServicio = 'Seleccione una clase de servicio válida.';
  SErrorDetalleCortina = 'Aplique la actualización ' +
    '20261031_cortinas_medidas_instalacion.sql.';
  SOrdenTrabajoReferencia = 'Orden de trabajo %d';
  STrabajoSolicitado = 'Trabajo solicitado';
  SOrdenInstalacion = 'Orden de instalación';
  SOrdenAltura = 'Orden de taller · arreglo de altura';
  SDetalleUnidad = 'Servicio, unidad %d';
  SInstalacionAviso = 'Servicio a domicilio. Conserve esta orden para la cita.';
  SMedidasSeccion = 'Medidas y acabado';
  SInstalacionSeccion = 'Instalación y cita';
  SPrendaSeleccionar = 'Seleccione la prenda para %s (unidad %d)';
  SPrendaElegir = 'Artículo de esta venta al que se aplica el servicio';
  SPrendaSinSeleccion = 'Seleccione qué prenda se va a reparar.';
  SPrendaFueraVenta = 'Prenda aportada por el cliente (fuera de esta venta)';
  SPrendaDescripcionCliente =
    'Describa la prenda recibida (tipo, color, marca y detalles):';
  SPrendaDescripcionObligatoria =
    'Indique una descripción de la prenda de hasta 200 caracteres.';
  SPrendaAlmacenFalta = 'Configure un almacén activo de tipo TALLER ' +
    'en esta empresa, asociado a la tienda.';
  SPrendaEsquemaFalta = 'Aplique la actualización ' +
    '20261031_reparaciones_prendas_taller.sql para gestionar las prendas.';
  SPrendaVentaInvalida = 'La prenda seleccionada no corresponde a una ' +
    'unidad vendida en este ticket.';
  SPrendaEntregada = 'La prenda ya se ha entregado al cliente.';
  STituloContactoReparacion = 'Datos del cliente para la reparación';
  SNombreContactoReparacion = 'Nombre del cliente:';
  STelefonoContactoReparacion = 'Teléfono:';
  SCorreoContactoReparacion = 'Correo electrónico (opcional):';
  SErrorContactoReparacion = 'Indique el nombre y el teléfono del cliente.';
  SErrorCorreoContactoReparacion = 'Revise el correo electrónico.';
  SErrorEsquemaArticuloReparacion =
    'Falta actualizar la base de datos para crear artículos como ' +
    'servicio de reparación. Aplique la actualización ' +
    '20261031_articulos_reparacion_tpv.sql y vuelva a intentarlo.';
  SErrorTicketOrdenReparacion =
    'No se encuentra el ticket para crear la orden de reparación.';
  SClienteMostradorReparacion = 'Cliente de mostrador';
  SModalidadReparacionCobrada = 'La reparación está cobrada. Revise el ' +
    'cobro antes de cambiar la modalidad.';
  SModalidadReparacionConImporte = 'Para pasar a garantía o cortesía, ' +
    'deje a cero los importes al cliente en Trabajos.';
  // Modalidades, fases, cobro, origen, ejecutor y liquidación.
  SModalidadGarantia = 'Garantía';
  SModalidadPago = 'Pago del cliente';
  SModalidadCortesia = 'Cortesía';
  SFaseReparacionRecibido = 'Recibido';
  SFaseReparacionPresupuesto = 'Presupuesto pendiente';
  SFaseReparacionRechazado = 'Presupuesto rechazado';
  SFaseReparacionEnReparacion = 'En reparación';
  SFaseReparacionReparado = 'Listo para recoger';
  SFaseReparacionEntregado = 'Entregado';
  SFaseReparacionAnulado = 'Anulado';
  SCobroReparacionCompra = 'Al comprar';
  SCobroReparacionRecogida = 'Al recoger';
  SCobroReparacionGratis = 'Gratis';
  SOrigenReparacionVendido = 'Vendido en la tienda';
  SOrigenReparacionCliente = 'Traído por el cliente';
  SOrigenReparacionTienda = 'De la tienda';
  SEjecutorReparacionOperario = 'Operario';
  SEjecutorReparacionExterno = 'Empresa externa';
  SModoLiquidacionPeriodica = 'Periódica';
  SModoLiquidacionLinea = 'Por línea';
  // Validación del alta y de las líneas.
  SErrorTiendaReparacion = 'Falta la tienda que recibe el objeto.';
  SErrorTrabajoReparacion = 'Indique el trabajo o la avería.';
  SErrorClienteReparacion =
    'Indique el cliente: su código, su nombre o un teléfono de contacto.';
  SErrorFechaPrevistaReparacion =
    'La fecha prevista de entrega no puede ser anterior a la de recepción.';
  SErrorOrigenReparacion = 'Indique de dónde es el objeto.';
  SErrorSkuReparacionTienda =
    'Un objeto de la tienda necesita su SKU para controlar el stock.';
  SErrorObjetoReparacion =
    'Indique el SKU, el número de serie o una descripción del objeto.';
  SErrorModalidadReparacion = 'Elija garantía, pago del cliente o cortesía.';
  SErrorModoCobroReparacion = 'Elija cuándo se cobra al cliente.';
  SErrorImporteReparacion =
    'Las cantidades y los importes no pueden ser negativos.';
  SErrorCobroSinPagoReparacion =
    'En garantía o cortesía el cliente no paga: cobro gratis y precio 0.';
  SErrorEjecutorReparacion =
    'La mano de obra la hace un operario o una empresa externa, no los ' +
    'dos; el material no lleva ejecutor.';
  SErrorSinReparacion = 'La línea no pertenece a ninguna reparación.';
  SErrorDescripcionLineaReparacion = 'Indique la descripción de la línea.';
  SErrorSkuMaterialReparacion = 'Una línea de material necesita su SKU.';
  SErrorTipoLineaReparacion = 'La línea es de mano de obra o de material.';
  // Situación del expediente o de la línea (%d = número).
  SErrorReparacionNoExiste = 'No existe la reparación %d.';
  SErrorReparacionCerrada =
    'La reparación %d ya está entregada, cerrada o anulada.';
  SErrorLineaNoEditableReparacion =
    'La línea %d no se puede cambiar: está empezada, liquidada o su ' +
    'reparación está cerrada.';
  SErrorEmpezarLineaReparacion =
    'La línea %d no se puede empezar: ya está empezada, no es mano de ' +
    'obra o falta la aceptación del presupuesto.';
  SErrorTerminarLineaReparacion =
    'La línea %d no se puede terminar: ya está terminada, no es mano de ' +
    'obra o falta la aceptación del presupuesto.';
  SErrorDevolverLineaReparacion =
    'La línea %d no se puede devolver: no es de una empresa externa o no ' +
    'está terminada.';
  SErrorPresupuestarReparacion =
    'La reparación %d no admite presupuesto: no la paga el cliente, el ' +
    'presupuesto ya está aceptado o está cerrada.';
  SErrorResponderPresupuesto =
    'La reparación %d no tiene un presupuesto pendiente de respuesta.';
  SErrorSkuMaterialNoExiste =
    'No existe el SKU %s. El material tiene que ser un SKU dado de alta.';
  SErrorTicketCobroNoExiste =
    'No existe el ticket o factura %s/%s del cobro. Revise la serie y el ' +
    'número.';
  SErrorEntregarReparacion =
    'La reparación %d no se puede entregar: no está reparada ni tiene el ' +
    'presupuesto rechazado.';
  SErrorAnularReparacion =
    'La reparación %d no se puede anular: está entregada, anulada o tiene ' +
    'líneas liquidadas.';
  SMotivoAnulacionReparacion = 'Anulada: %s';
  // Liquidaciones.
  SErrorSentidoLiquidacion =
    'Una liquidación es un pago a un externo o un cargo al fabricante.';
  SErrorDocumentoLiquidacion =
    'No hay un documento válido de ese tipo, serie y número para el ' +
    'proveedor y la empresa de la liquidación %d.';
  SErrorAbonoLiquidacion =
    'La liquidación %d no es un cargo pendiente de abono.';
  // Pantalla «Reparaciones y garantías» (30/10/2026).
  STituloReparacionesGarantias = 'Reparaciones y garantías';
  STituloAltaReparacion = 'Reparación o arreglo';
  STituloLineaReparacion = 'Línea de la reparación';
  STituloResguardoDeposito = 'Resguardo de depósito';
  STituloEntregarReparacion = 'Entregar al cliente';
  STituloAnularReparacion = 'Anular la reparación';
  STituloDevolverLinea = 'Devolver al externo';
  STituloPresupuesto = 'Presupuesto';
  STituloLiquidar = 'Liquidación';
  STituloDocumentoLiquidacion = 'Documento de la liquidación';
  STituloHojaEntregaExterno = 'Hoja de entrega al externo';
  STituloHojaLiquidacionPago = 'Liquidación de trabajos';
  STituloHojaCargoFabricante = 'Cargo al fabricante';
  SCaptionFiltroModalidad = 'Modalidad:';
  SCaptionModalidadesTodas = 'Todas';
  SCaptionNuevaReparacion = 'Nueva reparación';
  SCaptionEntregarReparacion = 'Entregar al cliente';
  SCaptionAnularReparacion = 'Anular reparación';
  SErrorDevolucionArregloSinVenta =
    'No se ha localizado la línea de venta de este arreglo.';
  SErrorDevolucionArregloSinLineas =
    'No hay líneas de este arreglo pendientes de devolver.';
  SCaptionFaseReparacion = 'Reparación';
  SRecepcionObjeto = 'Objeto recibido:';
  SRecepcionCopiaCliente = 'Copia cliente';
  SRecepcionCopiaPrenda = 'Copia prenda';
  SParametrosArreglosTitulo = 'Parámetros de arreglos';
  SParametrosArreglosAyuda =
    'Fases globales del arreglo para informar al cliente. ' +
    'Esta configuración se aplica a todos los usuarios. ' +
    'Los correos se envían desde Avisar al cliente.';
  SParametrosArreglosEmpezar = 'Al empezar el primer trabajo:';
  SParametrosArreglosTerminar = 'Al terminar todos los trabajos:';
  SParametrosArreglosSinCambio = 'No cambiar fase';
  SParametrosArreglosGuardar = 'Guardar parámetros';
  SParametrosArreglosGuardados = 'Parámetros de arreglos guardados.';
  SParametrosArreglosCambioInicio = 'Inicio del primer trabajo del arreglo';
  SParametrosArreglosCambioFin = 'Todos los trabajos del arreglo terminados';
  SGrupoTrabajosArreglos = 'Trabajos';
  SGrupoExternosArreglos = 'Empresas externas';
  SIncidenciaTrabajoTitulo = 'Incidencia';
  SIncidenciaTrabajoPregunta =
    'Describa lo ocurrido con la prenda o el trabajo:';
  SIncidenciaTrabajoObligatoria =
    'Indique una incidencia de entre 1 y 500 caracteres.';
  SIncidenciaTrabajoNoEditable =
    'No se puede registrar la incidencia en este trabajo cerrado.';
  SDatosEnvioReparacion = 'Datos de envío';
  SResultadoEntregaReparacion = 'Resultado y entrega';
  SRecepcionEstadoAccesorios = 'Estado y accesorios recibidos';
  SIntervencionResultadoReparacion = 'Intervención y resultado';
  SCaptionPestanaLiquidaciones = 'Liquidaciones';
  SCaptionPestanaTiposExternos = 'Artículos de arreglos';
  SCaptionAnadirLinea = 'Añadir línea';
  SCaptionCambiarLinea = 'Cambiar';
  SCaptionBorrarLinea = 'Borrar';
  SCaptionEmpezarLinea = 'Empezar';
  SCaptionTerminarLinea = 'Terminar';
  SCaptionDevolverLinea = 'Devolver al externo';
  SCaptionHojaEntrega = 'Hoja de entrega';
  SCaptionPresupuestar = 'Presupuestar';
  SCaptionAceptarPresupuesto = 'Aceptado';
  SCaptionRechazarPresupuesto = 'Rechazado';
  SCaptionPagarExterno = 'Pagar a externo';
  SCaptionCargarFabricante = 'Cargar al fabricante';
  SCaptionEnlazarDocumento = 'Enlazar documento';
  SCaptionAnotarAbono = 'Anotar abono';
  SCaptionImprimirLiquidacion = 'Imprimir';
  SCaptionRefrescarLiquidaciones = 'Refrescar';
  SLineaManoObra = 'Mano de obra';
  SLineaMaterial = 'Material';
  SSinTipoServicio = '(sin tipo)';
  SSinEjecutor = '(sin asignar)';
  SNoEsExterno = '(no trabaja como externo)';
  // Columnas.
  SColModalidad = 'Modalidad';
  SColFaseReparacion = 'Fase reparación';
  SColObjetoReparacion = 'Objeto';
  SColEntregaAproximada = 'Entrega aprox.';
  SColImporteCliente = 'Importe cliente';
  SColImporteCoste = 'Coste';
  SColLinea = 'Línea';
  SColTipoLinea = 'Tipo';
  SColDescripcionLinea = 'Descripción';
  SColEjecutorTipo = 'Ejecutor';
  SColEjecutor = 'Operario o empresa';
  SColSkuLinea = 'SKU';
  SColCantidadLinea = 'Cantidad';
  SColInicioLinea = 'Inicio';
  SColFinLinea = 'Fin';
  SColIncidenciaLinea = 'Incidencia';
  SColPagoLinea = 'Pago';
  SColCargoLinea = 'Cargo';
  SColLiquidacion = 'Nº';
  SColSentido = 'Tipo';
  SColProveedor = 'Proveedor';
  SColRazonSocial = 'Razón social';
  SColFechaLiquidacion = 'Fecha';
  SColHastaLiquidacion = 'Hasta';
  SColLineasLiquidacion = 'Líneas';
  SColTotalLiquidacion = 'Total';
  SColTipoDocumento = 'Doc.';
  SColSerieDocumento = 'Serie';
  SColNumeroDocumento = 'Número';
  SColAbono = 'Abonado';
  SColTipoCodigo = 'Código';
  SColTipoCategoria = 'Categoría';
  SColTipoDescripcion = 'Descripción';
  SColTipoPresupuesto = 'Presupuesto';
  SColModoCobro = 'Cobro';
  SColTipoPlazo = 'Días';
  SColTipoOperario = 'Operario';
  SColTipoArticulo = 'Artículo TPV';
  SColTipoOrden = 'Orden';
  SColTipoActivo = 'Activo';
  SColFacturacionDirecta = 'Autofactura';
  SColModoLiquidacion = 'Liquidación de servicios';
  // Rótulos.
  SRotuloModalidad = 'Modalidad:';
  SRotuloTipoServicio = 'Tipo de servicio:';
  SRotuloTrabajoReparacion = 'Trabajo o avería:';
  SRotuloDetallesReparacion = 'Detalles (medidas, km):';
  SRotuloObservacionesReparacion = 'Observaciones:';
  SRotuloOrigenObjeto = 'Objeto:';
  SRotuloSkuObjeto = 'SKU:';
  SRotuloSerieObjeto = 'Nº de serie:';
  SRotuloDescripcionObjeto = 'Descripción objeto:';
  SRotuloReferenciaObjeto = 'Referencia (matrícula):';
  SRotuloSerieVentaObjeto = 'Serie ticket compra:';
  SRotuloNumeroVentaObjeto = 'Nº ticket compra:';
  SRotuloCodigoClienteReparacion = 'Código cliente:';
  SRotuloClienteReparacion = 'Cliente:';
  SRotuloTelefonoReparacion = 'Teléfono:';
  SRotuloFabricanteReparacion = 'Fabricante (garantía):';
  SRotuloEntregaAproximada = 'Entrega estimada:';
  SRotuloEjecutorReparacion = 'Lo hace:';
  SRotuloCantidadReparacion = 'Cantidad u horas:';
  SRotuloPrecioClienteReparacion = 'Precio cliente:';
  SRotuloPrecioCosteReparacion = 'Coste:';
  SRotuloPresupuestoReparacion = 'Pide presupuesto';
  SRotuloModoCobroReparacion = 'Cobro al cliente:';
  SRotuloCobradoReparacion = 'Ya cobrado';
  SRotuloSerieCobroReparacion = 'Serie ticket cobro:';
  SRotuloNumeroCobroReparacion = 'Nº ticket cobro:';
  SRotuloTipoLinea = 'Línea de:';
  SRotuloDescripcionLinea = 'Descripción:';
  SRotuloSkuMaterial = 'SKU (material):';
  SRotuloEstadoPresupuesto = 'Presupuesto:';
  SRotuloImportePresupuesto = 'Importe presupuesto:';
  SPreguntaFormatoHojaReparacion =
    'Seleccione el formato de impresión de «%s»: ';
  SRotuloObjetoResguardo = 'Objeto:';
  SRotuloDetallesResguardo = 'Detalles:';
  SRotuloProveedorHoja = 'Proveedor:';
  SRotuloFechaHoja = 'Fecha:';
  SRotuloLiquidacionHoja = 'Liquidación:';
  SRotuloTelefonoHoja = 'Teléfono:';
  // Avisos y preguntas.
  SInfoSinReparacion = 'No hay ninguna reparación seleccionada.';
  SInfoSinLinea =
    'La reparación no tiene líneas o no hay ninguna seleccionada.';
  SInfoSinLineasExternas =
    'Seleccione líneas de empresas externas para la hoja de entrega.';
  SInfoSinLiquidacion = 'No hay ninguna liquidación seleccionada.';
  SInfoNadaQueLiquidar =
    'Ese proveedor no tiene trabajos terminados pendientes de liquidar.';
  SErrorSinLineasHoja = 'No hay líneas para la hoja.';
  SErrorLiquidacionNoExiste = 'No existe la liquidación %d.';
  SErrorCodigoTipoServicio = 'El tipo de servicio necesita un código.';
  SErrorDescripcionTipoServicio =
    'El tipo de servicio necesita una descripción.';
  SErrorTipoServicioUsado =
    'Ese tipo de servicio ya se ha usado: desactívelo en lugar de borrarlo.';
  SPreguntaResguardoReparacion =
    'Reparación %d grabada. ¿Imprimir el resguardo de depósito?';
  SPreguntaTicketCobroReparacion =
    'Se cobra al recoger (%s). Cóbrelo en caja y teclee el ticket como ' +
    'SERIE/NÚMERO:';
  SPreguntaEntregarSinCobro =
    'No se ha indicado el ticket de cobro. ¿Entregar sin cobrar?';
  SPreguntaMotivoAnulacion = 'Motivo de la anulación:';
  SPreguntaBorrarLinea = '¿Borrar la línea seleccionada?';
  SPreguntaIncidenciaLinea = '¿Qué hay que corregir?';
  SPreguntaImportePresupuesto = 'Importe del presupuesto (con impuestos):';
  SPreguntaProveedorLiquidar =
    'Código del proveedor (externo o fabricante) que se liquida hasta hoy:';
  SPreguntaDocumentoLiquidacion =
    'Documento que la salda: FP SERIE/NÚMERO (compra o autofactura) o ' +
    'FA SERIE/NÚMERO (factura de venta):';
  // Resguardo y hojas.
  SResguardoSinCargo = 'Sin cargo para el cliente.';
  SResguardoPresupuesto = 'Presupuesto: %s €';
  SResguardoPagado = 'Pagado: %s €';
  SResguardoAPagar = 'Pendiente de pago: %s €';
  SRotuloNumeroDeposito = 'Nº de depósito:';
  SCaptionPestanaTrabajos = 'Trabajos';
  SHojaReparacionesLineas = 'Trabajos: %d';
  SHojaReparacionesTotal = 'Total sin impuestos: %s €';
  SHojaReparacionesFirma = 'Firma:';

  SMovimientoNuevo = 'Nuevo movimiento';
  SMovimientoContinuar = 'Añadir seguimiento';
  SMovimientoReintentar = 'Reintentar envío';
  SMovimientoHistorial = 'Seguimientos';
  SMovimientoFecha = 'Fecha y hora';
  SMovimientoOrigen = 'Origen';
  SMovimientoDestino = 'Destino';
  SMovimientoObjeto = 'Objeto o pieza';
  SMovimientoEstado = 'Resultado';
  SMovimientoAgencia = 'Agencia';
  SMovimientoTracking = 'Seguimiento / RMA';
  SMovimientoIncidencia = 'Motivo / observaciones';
  SMovimientoUsuario = 'Registrado por';
  SMovimientoAnterior = 'Movimiento anterior';
  SMovimientoEstados = 'Enviado'#13#10'Recibido'#13#10'Devuelto'#13#10 +
    'Pieza defectuosa'#13#10'Anulado';
  SMovimientoFechaInvalida = 'Indique una fecha válida, no futura.';
  SMovimientoDatosObligatorios = 'Indique origen, destino y objeto o pieza.';
  SMovimientoEstadoInvalido = 'Seleccione el resultado del movimiento.';
  SMovimientoMotivoObligatorio = 'Explique la devolución o incidencia.';
  SMovimientoTextoLargo = 'Uno de los textos supera la longitud permitida.';
  SMovimientoAnteriorInvalido = 'El movimiento pertenece a otra reparación.';
  SMovimientoSeleccionar = 'Seleccione un movimiento del historial.';
  SFotosReparacion = 'Fotos y comentarios';
  SFotosTodasFases = 'Todas las fases';
  SFotosDescargar = 'Recibir fotos y comentarios';
  SCrearArticuloServicio = 'Crear artículo como servicio';
  SArticuloServicioCreado = 'Artículo %s creado o actualizado y vinculado ' +
    'al servicio, con su proveedor y tarifa TPV.';
  SMarcaArticuloReparacion = 'Artículo como servicio de reparación';
  SErrorArticuloServicioCodigo = 'El código del servicio debe tener de 1 ' +
    'a 20 caracteres y no contener barras.';
  SErrorArticuloServicioDatos = 'Complete la descripción y revise los ' +
    'precios del servicio.';
  SErrorArticuloServicioTipo = 'El código %s ya existe y no es un ' +
    'servicio simple sin trazabilidad.';
  SErrorArticuloServicioSku = 'El SKU %s está asociado a otro artículo.';
  SErrorArticuloServicioTarifa = 'No se puede resolver la tarifa por ' +
    'defecto del TPV o el IVA vigente de la empresa.';
  SErrorArticuloServicioProveedor = 'El proveedor asignado no existe ' +
    'o está inactivo.';
  SErrorArticuloServicioTransaccion = 'El artículo debe guardarse ' +
    'dentro de la operación del servicio.';
  SErrorMarcaArticuloReparacion = 'La marca de reparación solo se ' +
    'puede asignar a un artículo de tipo SERVICIO.';
  SColImporteClienteEuros = 'Importe cliente (€)';
  STituloBuscarOperarioTipo = 'Buscar operario';
  STituloBuscarProveedorTipo = 'Buscar proveedor';
  STituloBuscarArticuloTipo = 'Buscar artículo';
  SErrorBusquedaTipoServicio = 'No está disponible el servicio de búsqueda.';
  SErrorReferenciaTipoServicio = 'Referencia de tipo de servicio inválida.';
  SFaseEntregaRegistrada = 'Entrega al cliente registrada';
  SFaseEntregado = 'Entregado';
  SFaseSituacionTrabajos = 'Situación de trabajos';
  SFasePestana = 'Fases y avisos';
  SFaseHistorialCambios = 'Cambios de fase';
  SFaseHistorialAvisos = 'Avisos al cliente';
  SFaseActual = 'Fase actual';
  SFaseGuardar = 'Guardar cambio de fase';
  SFaseAnadir = 'Añadir fase';
  SFaseNuevaDescripcion = 'Nombre de la nueva fase:';
  SFaseSeleccionar = 'Seleccione una fase.';
  SFaseUsuarioObligatorio = 'Falta el usuario del cambio de fase.';
  SFaseConflicto = 'La reparación ha cambiado. Refresque y vuelva a intentar.';
  SFaseCerrada = 'No se puede cambiar la fase de una reparación ' +
    'entregada o anulada.';
  SFaseUsarEntrega = 'Para marcar Entregado utilice Entregar al cliente.';
  SFaseNombreInvalido = 'Indique un nombre de fase de hasta 120 caracteres.';
  SFaseDuplicada = 'Ya existe una fase con ese nombre.';
  SFaseAnterior = 'Fase anterior';
  SFaseNueva = 'Nueva fase';
  SFaseObservaciones = 'Observaciones internas del cambio';
  SFaseAvisar = 'Avisar al cliente por email';
  SFaseAsuntoCorreo = 'Reparación %d: %s';
  SFaseTextoCorreo = 'Hola %s,' + #13#10 + #13#10 +
    'Le informamos del estado de su reparación nº %d.' + #13#10 +
    'Objeto: %s' + #13#10 + 'Fase: %s' + #13#10 +
    'Fecha y hora del cambio: %s' + #13#10 + #13#10 +
    'Gracias por su confianza.';
  SFaseSinHistorial = 'Seleccione un cambio de fase del historial.';
  SFaseEmailInvalido = 'Indique un email válido.';
  SFaseAsuntoInvalido = 'Indique un asunto de hasta 200 caracteres, ' +
    'sin saltos de línea.';
  SFaseTextoInvalido = 'Indique el mensaje (máximo 20.000 bytes UTF-8).';
  SFaseCorreoConfigurar = 'Configure la conexión API de ViraCash ' +
    'y la cuenta de correo de la instalación.';
  SFaseCorreoEnviado = 'El servicio de correo ha aceptado el aviso.';
  SFaseCorreoIncierto = 'No se ha podido confirmar el resultado del envío. ' +
    'Compruébelo antes de reintentar para evitar duplicados.';
  SFaseReintentarCorreo = 'El resultado del intento anterior es incierto. ' +
    '¿Desea volver a enviar el aviso?';
  SFaseAvisosHistorial = 'Historial de avisos al cliente';
  SFaseDestinatario = 'Destinatario';
  SFaseAsunto = 'Asunto';
  SFaseMensaje = 'Mensaje al cliente';
  SFaseEnviar = 'Enviar aviso';
  SFaseCorreoTransaccion = 'Termine la operación pendiente antes de enviar.';
  SFaseCorreoResultadoNoGuardado = 'No se pudo guardar el resultado ' +
    'del aviso en el historial: %s';
  SFotosEditar = 'Editar foto o nota';
  SFotosSeleccionar = 'Seleccione una foto o nota para editar.';
  SFotosNombreInvalido = 'Nombre de evidencia inválido.';
  SFotosEdicionConflicto = 'La entrada ha cambiado. Refresque y vuelva ' +
    'a abrirla antes de guardar.';
  SFotosAnadir = 'Añadir foto o nota';
  SFotosGeneral = 'General';
  SFotosFase = 'Fase';
  SFotosFecha = 'Fecha y hora';
  SFotosComentario = 'Comentario';
  SFotosArchivo = 'Foto (opcional)';
  SFotosBuscar = 'Seleccionar foto…';
  SFotosFiltro = 'Imágenes (*.jpg;*.jpeg;*.png;*.bmp)|' +
    '*.jpg;*.jpeg;*.png;*.bmp';
  SFotosIndicarFase = 'Indique la fase de la foto o anotación.';
  SFotosIndicarContenido = 'Escriba un comentario o seleccione una foto.';
  SFotosIndicarFecha = 'Indique una fecha y hora válidas.';
  SFotosArchivoInexistente = 'No se encuentra la foto seleccionada.';
  SFotosRefrescar = 'Refrescar';
  SFotosAntes = 'Antes';
  SFotosDespues = 'Después';
  SFotosInstrucciones = 'Reparación %d · Añada fotos o notas con fecha ' +
    'y hora desde aquí, o recíbalas desde la app Fotos.';
  SFotosConfigurarCarpeta = 'Configure la carpeta de fotos.';
  SFotosConflicto = 'La foto %s ya existe con otro contenido.';

resourcestring
  SImpresoRecepcion = 'Recepción de artículo';
  SImpresoFabricante = 'Envío al fabricante';
  SImpresoEnvioCliente = 'Envío al cliente';
  SImpresoAlbaran = 'Albarán de entrega';
  SImpresoEmisor = 'Emisor / taller';
  SImpresoCliente = 'Cliente';
  SImpresoDestinatario = 'Destinatario';
  SImpresoRemitente = 'Remitente';
  SImpresoAparato = 'Identificación del artículo';
  SImpresoMotivo = 'Avería comunicada / trabajo solicitado';
  SImpresoEstadoRecepcion = 'Estado, accesorios y observaciones de recepción';
  SImpresoCondiciones = 'Modalidad y condiciones';
  SImpresoTrabajos = 'Trabajos y materiales';
  SImpresoResultado = 'Resultado de la intervención';
  SImpresoTransporte = 'Datos del envío';
  SImpresoFirmasTicket = 'Firma cliente / receptor' + #13#10#13#10 +
    'Firma taller';
  SImpresoFirmas = 'Firma cliente / receptor             Firma taller';
  SImpresoAcuseRecepcion = 'Conserve este resguardo para la recogida. ' +
    'Compruebe el artículo y los accesorios descritos al depositarlo.';
  SImpresoAcuseEntrega = 'Recibí el artículo y los accesorios descritos. ' +
    #13#10 + 'Nombre del receptor: ____________________' + #13#10 +
    'Fecha: ______________';
  SImpresoNoFactura = 'Documento de entrega. No sustituye a la factura.';
  SImpresoPrecios = 'Importes en euros, impuestos incluidos.';
  SImpresoBorrador = 'BORRADOR - entrega todavía no registrada';
  SImpresoPendiente = 'Pendiente de finalizar';
  SImpresoTotal = 'Importe de los trabajos';
  SImpresoSinTrabajos = 'Sin líneas de trabajo registradas.';
  SImpresoSinResolucion = 'Sin resultado de intervención registrado.';
  SImpresoDireccionFalta = 'Complete el nombre y la dirección del ' +
    'destinatario en la ficha antes de imprimir la etiqueta.';
  SImpresoEtiquetaLarga = 'Los datos no caben en una etiqueta de ' +
    '100 x 150 mm. Seleccione A4 o ticket para conservarlos completos.';
  SImpresoFormato = 'Formato de salida';
  SImpresoEtiqueta = 'Etiqueta 100 x 150 mm';
  SImpresoTicket = 'Ticket 80 mm';
  SImpresoEtiquetaFabricante = 'Etiqueta fabricante';
  SImpresoEtiquetaCliente = 'Etiqueta cliente';
  SImpresoReferencia = 'Reparación %d';
  SImpresoFecha = 'Fecha: %s';
  SImpresoCantidad = 'Cantidad: %s';
  SImpresoDescripcion = 'Descripción';
  SImpresoCantidadColumna = 'Cantidad';
  SImpresoImporteColumna = 'Importe';
  SImpresoCobro = 'Documento de cobro: %s';
  SImpresoPresupuesto = 'Presupuesto: %s · %s';
  SImpresoMovimiento = 'Movimiento: %d';

  // Albaranes TALLER y terceros de la orden.
  SAlbaranesOrden = 'Albaranes';
  SAlbaranesClienteTaller = 'De cliente · TALLER';
  SAlbaranesProveedorTaller = 'De proveedor · TALLER';
  SVincularAlbaranOrden = 'Vincular albarán';
  SDesvincularAlbaranOrden = 'Desvincular';
  SAbrirAlbaranOrden = 'Abrir albarán';
  SSerieNumeroAlbaranOrden = 'Serie/número del albarán:';
  SConfirmarDesvincularAlbaran = '¿Desvincular este albarán de la orden? El documento se conserva.';
  SAlbaranTallerNoValido = 'El albarán no corresponde a un almacén TALLER de la empresa y tienda de esta orden.';
  SAlbaranTerceroNoValido = 'El cliente del albarán debe ser el titular o el pagador de la orden.';
  SAlbaranFacturadoNoDesvincular = 'El albarán ya está facturado: revisa su factura antes de cambiar el vínculo.';
  STitularTrabajo = 'Cliente / titular del trabajo:';
  SPagadorTrabajo = 'Cliente de facturación / pagador:';
  SFranquiciaTrabajo = 'Franquicia del titular (IVA incluido):';
  SPagadorTrabajoNoValido = 'Indica un cliente de facturación válido y una franquicia entre cero y el total del trabajo. Con franquicia, el titular también necesita código de cliente.';
  SPagadorTrabajoBloqueado = 'La orden tiene albaranes vinculados: revisa esos documentos antes de cambiar el titular, pagador o franquicia.';
  SRepartoTrabajo = 'Titular: %s € · Pagador: %s €';

implementation

end.
