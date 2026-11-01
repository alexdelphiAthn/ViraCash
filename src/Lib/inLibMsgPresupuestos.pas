{******************************************************************************}
{                                                                              }
{                         Módulo: inLibMsgPresupuestos                         }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{             Presupuestos e impresión de documentos comerciales.              }
{******************************************************************************}
unit inLibMsgPresupuestos;

interface

resourcestring
  SErrorPresupuestoVentaNoAbierto =
    'No está abierto el presupuesto de venta.';
  SErrorPresupuestoVentaNoInicializado =
    'No está inicializado el presupuesto.';
  SErrorArticuloNoSeleccionadoBuscarSkusPresupuestoVenta =
    'Selecciona un artículo antes de buscar sus SKUs.';
  SErrorCrearSeleccionarPresupuestoAntesLineas =
    'Crea o selecciona un presupuesto antes de añadir líneas.';
  SPreguntaAbrirSeriesPresupuestoVenta =
    'No hay series de presupuestos de venta mayor (tipo PV) para la empresa ' +
    '"%s".' + sLineBreak +
    'Se dan de alta en Empresas -> Series. ¿Abrir el mantenimiento de ' +
    'Empresas ahora?';
  SPreguntaEliminarLineaPresupuestoVenta =
    '¿Está seguro de que desea eliminar esta línea?';
  SPreguntaGrabarPresupuestoVentaSinSku =
    'Las líneas %s tienen artículos con variaciones sin SKU asignado. ' +
    '¿Grabar de todas formas?';
  SAvisoAlmacenSalidaPresupuestoObligatorio =
    'Debe seleccionar el almacén de salida del presupuesto.';
  SErrorAsignarLineaPresupuesto =
    'No se pudo asignar número de línea: la cabecera %s/%s no existe en ' +
    'la base de datos.';
  SErrorCabeceraPresupuestoSinGrabar =
    'Graba la cabecera del presupuesto antes de guardar líneas.';
  SErrorContadorPresupuesto =
    'No se pudo obtener un número de presupuesto válido. Revise el ' +
    'contador PV de la serie %s y empresa %s.';
  SErrorLineaPresupuestoSinArticulo =
    'La línea del presupuesto no tiene artículo; no se puede guardar.';
  SPreguntaLineaLibrePresupuesto =
    'Artículo/SKU no encontrado: %s' + sLineBreak +
    '¿Añadirlo al presupuesto como línea libre (sin artículo del ' +
    'catálogo)?';

  STituloBuscarArticulosLineasPresupuesto =
    'Búsqueda de Artículos en Líneas de Presupuesto';
  STituloBuscarSkusPresupuesto = 'SKUs del artículo %s';
  STituloBuscarEmpresasPresupuesto = 'Búsqueda de Empresas en Presupuestos';
  STituloBuscarClientesPresupuesto = 'Búsqueda de Clientes en Presupuestos';

  // Traducciones de inventarios y documentos (D34).
  SCaptionLineaPresupuesto =
    'Línea';
  SCaptionDescripcionPresupuesto =
    'Descripción';
  SCaptionCantidadPresupuesto =
    'Cantidad';
  SCaptionPrecioSinIvaPresupuesto =
    'PVP S/IVA';
  SCaptionPrecioConIvaPresupuesto =
    'PVP C/IVA';
  SCaptionTarifaPresupuesto =
    'Tarifa';
  SCaptionImpuestosIncluidosPresupuesto =
    'Imp. incl.';
  SCaptionTotalPresupuesto =
    'Total';
  SCaptionAlmacenPresupuesto =
    'Almacén';
  SCaptionLotePresupuesto =
    'Lote';
  SCaptionCaducidadPresupuesto =
    'F. Caducidad';
  SCaptionPasarPresupuestoFactura =
    'Pasar a factura';
  SCaptionPasarPresupuestoAlbaran =
    'Pasar a albarán';
  SCaptionPasarPresupuestoPedido =
    'Pasar a pedido';
  SCaptionPasarPresupuestoDocumento =
    'Pasar a documento';
  SCaptionTipoDocumentoConversionPresupuesto =
    'Documento:';
  SErrorSinPermisoConversionPresupuesto =
    'No tiene permiso para crear pedidos, albaranes ni facturas.';
  SErrorTipoDocumentoConversionPresupuesto =
    'Seleccione el tipo de documento.';
  SCaptionEnviarPresupuestoCaja =
    'Enviar a caja';
  SErrorPresupuestoCajaNoDisponible =
    'El presupuesto ya no está abierto o tiene un documento creado. ' +
    'Actualice el presupuesto antes de enviarlo a caja.';
  SErrorPresupuestoCajaCobroCompleto =
    'El presupuesto enviado a caja requiere un cobro completo. ' +
    'Para entregas parciales, use la conversión a documento.';
  SErrorPresupuestoSinLineasCaja =
    'El presupuesto no tiene líneas que enviar a caja.';
  SInfoLineasPresupuestoVolcadasCaja =
    '%d líneas enviadas a la venta de caja.';
  SAvisoLineasPresupuestoNoVolcadasCaja =
    '%d líneas enviadas a la venta de caja; %d no se han podido ' +
    'cargar (sin SKU, artículo inexistente o descatalogado).';
  SErrorSeleccionePresupuesto =
    'Seleccione un presupuesto.';
  SErrorPresupuestoNoExiste =
    'El presupuesto ya no existe.';
  SAvisoClientePresupuestoNoExiste =
    'El cliente %s no existe. Seleccione un cliente válido antes de ' +
    'guardar el presupuesto.';
  SAvisoClientePresupuestoAlbaran =
    'El albarán necesita un cliente. Asigne al presupuesto un cliente ' +
    'existente (aunque sea el genérico de venta al contado o público) ' +
    'antes de crear el albarán.';
  SErrorSerieDestinoPresupuesto =
    'Configure una serie %s para la empresa %s en Empresas > Series.';
  SErrorDestinoPresupuestoNoCreado =
    'No se ha creado el documento de destino.';
  SErrorOperacionPendientePresupuesto =
    'Termine la operación pendiente antes de convertir.';
  SErrorConsultaPresupuestoNoDisponible =
    'Falta la consulta %s.';
  SErrorAlmacenConversionPresupuesto =
    'Seleccione el almacén del documento.';
  SErrorSerieConversionPresupuesto =
    'Seleccione la serie del documento.';
  SErrorNumeroConversionPresupuesto =
    'Indique el número del documento o marque Automático.';
  SErrorFechaConversionPresupuesto =
    'Indique la fecha del documento.';
  SErrorPresupuestoConvertidoSoloLectura =
    'El presupuesto convertido se conserva como documento de origen.';
  SErrorDocumentoImpresionNoExiste =
    'El documento que desea imprimir no existe.';

  SInformeNumeroDocumento =
    'Número: [Cabecera."SERIE"] / [Cabecera."NUMERO"]';
  SInformeFechaDocumento =
    'Fecha: [Cabecera."FECHA"]';
  SInformeValidezDocumento =
    'Válido hasta: ';
  SInformeEmisorDocumento =
    'Emisor';
  SInformeClienteDocumento =
    'Cliente';
  SInformeProveedorDocumento =
    'Proveedor';
  SInformeNifDocumento =
    'NIF: ';
  SInformeCodigoDocumento =
    'Código';
  SInformeDescripcionDocumento =
    'Descripción';
  SInformeCantidadDocumento =
    'Cantidad';
  SInformePrecioDocumento =
    'Precio';
  SInformeIvaDocumento =
    'IVA %';
  SInformeImporteDocumento =
    'Importe';
  SInformeTipoIvaDocumento =
    'Tipo';
  SInformeBaseImponibleDocumento =
    'Base imponible';
  SInformeBaseDesgloseDocumento =
    'Base';
  SInformePorcentajeIvaDocumento =
    '% IVA';
  SInformeCuotaIvaDocumento =
    'Cuota';
  SInformePorcentajeRecargoDocumento =
    '% R.E.';
  SInformeCuotaRecargoDocumento =
    'Cuota R.E.';
  SInformeTotalRecargoDocumento =
    'Total R.E.';
  SInformeIvaNormalDocumento =
    'Normal';
  SInformeIvaReducidoDocumento =
    'Reducido';
  SInformeIvaSuperreducidoDocumento =
    'Superreducido';
  SInformeIvaExentoDocumento =
    'Exento';
  SInformeTotalIvaDocumento =
    'Total IVA';
  SInformeRetencionIrpfDocumento =
    'Retención IRPF ' +
    '[FormatFloat(''0.##'', <Cabecera."PORCENTAJE_RETENCION">)] %';
  SInformeTotalLiquidoDocumento =
    'TOTAL';
  SInformeFormaPagoDescDocumento =
    'Forma de pago: [Cabecera."FORMA_PAGO_DESCRIPCION"]';
  SInformeObservacionesDocumento =
    'Observaciones';
  SInformePaginaDocumento =
    'Página [Page#] de [TotalPages#]';
  STituloImprimirDocumento =
    'Imprimir %s';
  SNombrePresupuestoVenta =
    'Presupuesto de venta';
  SNombrePedidoVenta =
    'Pedido de venta';
  SNombrePedidoCompra =
    'Pedido de compra';
  SNombreAlbaranVenta =
    'Albarán de venta';
  SNombreAlbaranCompra =
    'Albarán de compra';
  SNombreFacturaVenta =
    'Factura de venta';

implementation

end.
