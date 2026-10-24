{******************************************************************************}
{                                                                              }
{                      Módulo: inLibMsgOpcionesDocumento                       }
{                                Versión: 1.0.0                                }
{                              Fecha: 28/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{        Textos del diálogo común de opciones al crear un documento.           }
{******************************************************************************}
unit inLibMsgOpcionesDocumento;

interface

resourcestring
  SInfoResultadoDocumentoCreado = 'Se ha creado el siguiente documento.';
  SCaptionIrDocumentoCreado = '&Ir al documento (F12)';
  SCaptionCerrarDocumentoCreado = '&Cerrar (Esc)';
  SNombreFacturaCreada = 'Factura de venta';
  SNombrePedidoCompraCreado = 'Pedido de compra';
  SNombreDevolucionCompraCreada = 'Devolución de compra';
  SNombreInventarioCreado = 'Inventario';
  SCaptionConsolidarAlCrearOpcionesDocumento =
    'Consolidar al crear';
  SCaptionConsolidarEnviarOpcionesDocumento =
    'Consolidar y enviar a VeriFactu';
  SCaptionConsolidarEnviarSiiOpcionesDocumento =
    'Consolidar y enviar al SII';
  SAvisoConsolidarBorradorCreadoOpcionesDocumento =
    'El borrador %s / %s se ha creado, pero no se ha podido iniciar ' +
    'su consolidación. Ábralo en Facturas para revisarlo y consolidarlo.';
  SCaptionOpcionesDocumento =
    'Crear documento';
  SCaptionEmpresaOpcionesDocumento =
    'Empresa:';
  SCaptionAlmacenOpcionesDocumento =
    'Almacén:';
  SCaptionTipoOpcionesDocumento =
    'Documento:';
  SCaptionSerieOpcionesDocumento =
    'Serie:';
  SCaptionNumeroOpcionesDocumento =
    'Número:';
  SCaptionNumeroAutomaticoOpcionesDocumento =
    'Automático';
  SCaptionFechaOpcionesDocumento =
    'Fecha:';
  SCaptionHoraOpcionesDocumento =
    'Hora:';
  SCaptionFormaPagoOpcionesDocumento =
    'Forma de pago:';
  SCaptionMueveStockOpcionesDocumento =
    'Genera movimientos de stock';
  SCaptionAceptarOpcionesDocumento =
    '&Aceptar (F12)';
  SCaptionCancelarOpcionesDocumento =
    '&Cancelar (ESC)';
  SErrorEmpresaOpcionesDocumento =
    'Seleccione la empresa del documento.';
  SErrorAlmacenOpcionesDocumento =
    'Seleccione el almacén del documento.';
  SErrorTipoOpcionesDocumento =
    'Seleccione el tipo de documento.';
  SErrorSerieOpcionesDocumento =
    'Seleccione la serie del documento.';
  SErrorNumeroOpcionesDocumento =
    'Indique el número del documento o marque Automático.';
  SErrorFechaOpcionesDocumento =
    'Indique la fecha del documento.';
  SErrorFormaPagoOpcionesDocumento =
    'Seleccione la forma de pago del documento.';
  SErrorCampoObligatorioOpcionesDocumento =
    'Complete el campo «%s».';
  STituloBorradorFacturaCompraOpcionesDocumento =
    'Crear borrador de factura de compra';
  SNombreFacturaCompraOpcionesDocumento =
    'Factura de compra (borrador)';
  SNombreFacturaVentaOpcionesDocumento =
    'Factura de venta (borrador)';
  STituloFacturasTraspasoOpcionesDocumento =
    'Facturas de los traspasos';
  STituloConvertirProformaValesOpcionesDocumento =
    'Pasar la propuesta de vales a factura';
  STituloAbonoDuplicadoOpcionesDocumento =
    'Abonar o duplicar la factura';
  SNombreAbonoOpcionesDocumento =
    'Borrador de abono (rectificativa)';
  SNombreDuplicadoOpcionesDocumento =
    'Borrador duplicado';
  SAvisoFacturaOrigenOpcionesDocumento =
    'Factura de origen: %s / %s.';
  SInfoBorradorCreadoOpcionesDocumento =
    'Borrador creado: %s / %s.';
  STituloRectificarDuplicarOpcionesDocumento =
    'Rectificar o duplicar la factura';
  SNombreRectificativaDiferenciasOpcionesDocumento =
    'Rectificativa por diferencias (abono)';
  SNombreRectificativaSustitucionOpcionesDocumento =
    'Rectificativa por sustitución';
  SCaptionTipoVerifactuRectificativaOpcionesDocumento =
    'Tipo VERI*FACTU:';
  SCaptionMotivoRectificativaOpcionesDocumento =
    'Motivo:';
  SCaptionMovimientosRectificativaOpcionesDocumento =
    'Movimientos (sustitución):';
  SElementoMovimientosMantenerOpcionesDocumento =
    'Mantener los de la factura original';
  SElementoMovimientosReemplazarOpcionesDocumento =
    'Retirar los de la original y generar los de la rectificativa';
  SCaptionEmitirAlCrearOpcionesDocumento =
    'Emitir fiscalmente al crear (sin revisar el borrador)';
  SCaptionEmitirR4OpcionesDocumento =
    'Emitir rectificativa R4 (el error está en la factura)';
  SNombreRectificativaR4OpcionesDocumento =
    'Rectificativa R4';
  SAvisoIncidenciaVerifactuOpcionesDocumento =
    'Factura %s. Incidencia de la AEAT: %s. Destinatario actual: %s.';
  STituloAlbaranPedidoOpcionesDocumento =
    'Crear albarán del pedido';
  SNombreAlbaranVentaOpcionesDocumento =
    'Albarán de venta';
  SAvisoDocumentoOrigenOpcionesDocumento =
    'Documento de origen: %s / %s.';
  SCaptionAnadirADocumentoOpcionesDocumento =
    'Añadir a:';
  SElementoDocumentoExistenteOpcionesDocumento =
    '%s / %s  (%s, %s)';
  STituloAlbaranPedidoCompraOpcionesDocumento =
    'Crear albarán desde pedido de compra';
  SNombreAlbaranCompraOpcionesDocumento =
    'Albarán de compra';
  SCaptionReferenciaProveedorOpcionesDocumento =
    'Ref. proveedor:';
  SCaptionTemporadaOpcionesDocumento =
    'Temporada:';
  STituloSesionCompraOpcionesDocumento =
    'Crear artículos y albarán / pedido';
  SNombrePedidoCompraOpcionesDocumento =
    'Pedido de compra';
  SCaptionTarifaOpcionesDocumento =
    'Tarifa de venta:';
  SCaptionUnDocumentoPorAlmacenOpcionesDocumento =
    'Un documento por almacén';
  STituloFacturarTicketOpcionesDocumento =
    'Crear factura normal del ticket';
  SAvisoFacturarTicketOpcionesDocumento =
    'Factura normal en sustitución del ticket %s.';
  SCaptionClienteOpcionesDocumento =
    'Cliente:';
  STituloFacturaCajaOpcionesDocumento =
    'Factura completa: serie y fecha';
  STituloFacturaAlbaranOpcionesDocumento =
    'Crear borrador de factura';
  STituloFacturasAlbaranesOpcionesDocumento =
    'Facturas de los albaranes';

implementation

end.
