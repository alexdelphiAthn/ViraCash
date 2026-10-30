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
  SCaptionFaseReparacion = 'Reparación';
  SCaptionPestanaLiquidaciones = 'Liquidaciones';
  SCaptionPestanaTiposExternos = 'Tipos y externos';
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
  SRotuloEntregaAproximada = 'Entrega aproximada:';
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

implementation

end.
