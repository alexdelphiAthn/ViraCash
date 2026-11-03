{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgTickets                                               }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Literales traducibles de tickets de venta y documentos de caja.           }
{******************************************************************************}
unit inLibMsgTickets;

interface

resourcestring
  STicketFacturaRectificativaNumero =
    'FACTURA RECTIFICATIVA Nro. %s';
  STicketFacturaNumero = 'FACTURA Nro. %s';
  STicketRegaloNumero = 'TICKET REGALO Nro. %s';
  STicketFacturaSimplificadaNumero =
    'FACTURA SIMPLIFICADA Nro. %s';
  // FZ-ISSUE-200: referencia a la factura rectificada o sustituida.
  STicketRectificaA = 'RECTIFICA A: %s';
  STicketSustituyeA = 'SUSTITUYE A: %s';
  STicketFechaFacturaOriginal = 'FECHA FACTURA ORIGINAL: %s';
  STicketMotivo = 'MOTIVO: %s';
  SAvisoSinSerieRectificativaCaja =
    'No hay ninguna serie de facturas rectificativas configurada ' +
    'para esta empresa, almacén y caja (Empresas > Series, subtipo ' +
    'RECTIFICATIVA). Escriba una serie nueva en el combo de series ' +
    'o configúrela antes de cobrar.';
  STicketOperacionNumero = 'TICKET DE OPERACIÓN Nro. %s';
  STicketCifNif = 'CIF/NIF: %s';
  STicketTelefono = 'TELÉFONO: %s';
  STicketEtiquetaOperacionNumero = 'OPERACIÓN NRO.';
  STicketFormatoTienda = '%s Tda.%s-%s';
  STicketCabeceraArticulos =
    'Artículo/Sku              Cant.    Total';
  STicketBrutoVenta = 'BRUTO';
  STicketACobrar = 'A COBRAR';
  STicketSuma = 'SUMA';
  STicketDescuento = 'DESCUENTO';
  STicketSalidaDescuento = 'Salida %s; dto. %s';
  STicketValeRecogido = 'VALE RECOGIDO';
  STicketAPagar = 'A PAGAR';
  STicketCambioEfectivo = 'CAMBIO EFECTIVO';
  STicketValeEmitidoFavor = 'VALE EMITIDO A SU FAVOR';
  STicketCodigoValeEmitido = 'CÓDIGO VALE EMITIDO:';
  STicketCodigoValeEmitidoEspacio = 'CÓDIGO VALE EMITIDO: ';
  STicketPinValeEmitidoEspacio = 'PIN DEL VALE: ';
  STicketBaseImponible = 'BASE IMPONIBLE';
  STicketBaseImponibleReducida = 'BASE IMPONIBLE RED.';
  // FZ-ISSUE-335: el ticket desglosa también el superreducido y el exento.
  STicketBaseImponibleSuperreducida = 'BASE IMPONIBLE SUPERRED.';
  STicketBaseImponibleExenta = 'BASE EXENTA';
  STicketTotalIvaFormato = 'TOTAL IVA(%.0f%%)';
  // FZ-ISSUE-375: recargo de equivalencia del tramo.
  STicketTotalRecargoFormato = 'RECARGO EQ.(%s%%)';
  STicketLeAtendio = 'LE ATENDIÓ: %s';
  STicketIvaIncluido = 'IVA INCLUIDO';
  STicketGraciasVisita = 'GRACIAS POR SU VISITA';
  STicketResumenOperacion = '*** RESUMEN DE LA OPERACIÓN ***';
  STicketDepositosEntregas = 'DEPÓSITOS Y ENTREGAS';
  STicketEtiquetaCodigoCliente = 'CÓDIGO CLIENTE:';
  STicketEtiquetaFecha = 'FECHA:';
  STicketEtiquetaNumeroOperacion = 'Nº OPERACIÓN:';
  STicketValorArticulo = 'Valor Artículo: %s €';
  STicketEntregasCuenta = 'ENTREGAS A CUENTA';
  STicketCuentaArticulo = 'A cuenta: %s';
  STicketCuentaInicialArticulo = 'A cta. inicial: %s';
  STicketCuentaArticuloPendiente =
    'A cuenta para artículo pendiente';
  STicketCuentaInicial = 'A cuenta inicial';
  STicketDevolucionEconomica = 'DEVOLUCIÓN ECONÓMICA';
  STicketTotalNuevosDepositos =
    'TOTAL NUEVOS DEPÓSITOS: %s €';
  STicketTotalDepositosDevueltos =
    'TOTAL DEPÓSITOS DEVUELTOS: %s €';
  STicketAnticiposEntregadosAhora =
    'ANTICIPOS ENTREGADOS AHORA: %s €';
  STicketDevueltoOperacion =
    'DEVUELTO EN ESTA OPERACIÓN: %s €';
  STicketTotalPagadoDepositos =
    'TOTAL PAGADO (TICKET + DEPÓSITOS): %s €';
  STicketConformeCliente = 'Conforme, el cliente';
  STicketCopiaClienteApartado = '*** COPIA PARA EL CLIENTE ***';
  STicketCopiaPrendaApartado = '*** COPIA PARA LA PRENDA ***';
  STicketEtiquetaApartadoPor = 'APARTADO POR:';
  STicketEtiquetaTelefonoApartado = 'TELÉFONO:';
  STicketEtiquetaTicketApartado = 'TICKET:';
  STicketMovimientoDepositosPrestamos =
    'MOVIMIENTO DE DEPÓSITOS/PRÉSTAMOS';
  STicketDevolucionArticulos = 'DEVOLUCIÓN DE ARTÍCULOS';
  STicketEstadoCuentaDepositos =
    'ESTADO DE SU CUENTA ENTREGAS/DEPÓSITOS';
  STicketFormatoFechaLarga =
    'dddd, d "de" mmmm "de" yyyy, hh:nn';
  STicketEmpresa = 'EMPRESA:';
  STicketCliente = 'CLIENTE:';
  STicketFechaHora = 'Fecha/Hora';
  STicketTotal = 'Total';
  STicketPendiente = 'Pendiente';
  STicketRetiradoEn = '  RETIRADO EN (%s)';
  STicketEntregaInicial = '  > Entrega inicial';
  STicketACuenta = '  > A cuenta';
  STicketTotalPendientePago = 'TOTAL PDTE. DE PAGO:';
  STicketEntradaCambio = 'ENTRADA DE CAMBIO';
  STicketGastoRetiradaCaja = 'GASTO / RETIRADA DE CAJA';
  STicketFecha = 'Fecha:';
  STicketCaja = 'Caja:';
  STicketEmpleado = 'Empleado:';
  STicketOperacionAbreviada = 'Op.:';
  STicketConcepto = 'Concepto:';
  STicketImporte = 'IMPORTE:';
  STicketFirma = 'Firma:';
  STicketSolicitudTraspaso = 'SOLICITUD DE TRASPASO';
  STicketReposicionAutomatica = 'REPOSICIÓN AUTOMÁTICA';
  STicketTraspaso = 'TRASPASO';
  STicketPerdidaTransito = 'PÉRDIDA EN TRÁNSITO';
  STicketPerdidasTransito = 'PÉRDIDAS EN TRÁNSITO';
  STicketPerdidas = 'PÉRDIDAS';
  STicketOrigen = 'Origen:';
  STicketDestino = 'Destino:';
  // FZ-ISSUE-717: carga a un almacén de tránsito
  STicketDestinoFinal = 'Destino final:';
  STicketEmpresaOrigen = 'Empresa origen:';
  STicketEmpresaDestino = 'Empresa destino:';
  STicketEstado = 'Estado:';
  STicketVentasDesde = 'Ventas desde:';
  STicketVentasHasta = 'Ventas hasta:';
  STicketArticulos = 'ARTICULOS';
  STicketProveedor = 'PROVEEDOR:';
  STicketSinProveedor = 'SIN PROVEEDOR';
  STicketAPedir = '  A pedir:';
  STicketUnidadesPedidas = '  Unidades pedidas:';
  STicketUnidades = '  Unidades:';
  // FZ-ISSUE-324: líneas cuya unidad no es «unidades» (kg, l, m...)
  STicketCantidad = '  Cantidad:';
  STicketStockOrigen = '  Stock origen:';
  STicketStockDestino = '  Stock destino:';
  STicketStockOrigenTrasTraspaso =
    '  Stock origen tras traspaso:';
  STicketStockDestinoTrasTraspaso =
    '  Stock destino tras traspaso:';
  STicketOperacion = 'Operación:';
  STicketStockOrigenActual = '  Stock origen actual:';
  STicketStockDestinoActual = '  Stock destino actual:';
  STicketCif = 'CIF: %s';
  STicketPrimeraOperacion = 'Primera operación:';
  STicketUltimaOperacion = 'Última operación:';
  STicketOperaciones = 'OPERACIONES';
  STicketUnidadesVenta = 'UNIDADES VTA.';
  STicketLineasArticulos = 'LÍNEAS DE ARTÍCULOS';
  STicketBruto = '  BRUTO';
  STicketVentasNormales = '  Ventas Normales';
  STicketVentasPrestamos = '+ Ventas Préstamos';
  STicketDevoluciones = '− Devoluciones';
  STicketTotalVentas = '= TOTAL VENTAS';
  STicketCobros = 'COBROS';
  STicketValesRecogidos = '  Vales recogidos';
  STicketValesEmitidos = '+ Vales emitidos';
  STicketCobrosClientes = '+ Cobros clientes';
  STicketPendienteCobro = '− Pendiente cobro';
  STicketIngresosCaja = '= Ingresos caja';
  STicketEfectivo = 'EFECTIVO';
  STicketEfectivoIngresos = '  Eftvo. ingresos';
  STicketEfectivoEntradas = '+ Efectivo entradas';
  STicketEfectivoSalidas = '− Efectivo salidas';
  STicketEfectivoAnterior = '+ Efectivo anterior';
  STicketEfectivoCaja = '= Efectivo en caja';
  STicketOtrosIngresos = '+ Otros (tarj/...)';
  STicketSaldoRecontar = '= SALDO RECONTAR';
  STicketDevolucionesClientes = 'DEVOLUCIONES CLIENTES';
  STicketNetoArticulos = '  NETO ARTÍCULOS';
  STicketResumenNetoSeccion = 'RESUMEN NETO POR SECCIÓN';
  STicketResumenVentasTemporada =
    'RESUMEN VENTAS POR TEMPORADA';
  STicketFormatoResumenTemporada = '%-20s %s uds';
  STicketResumenVentasEmpleado =
    'RESUMEN VENTAS POR EMPLEADO';
  STicketFormatoResumenEmpleado = '%-12s  %3d ops';
  STicketResumenFormaPago = 'RESUMEN POR FORMA DE PAGO';
  STicketFormatoResumenFormaPago = '%-12s  %3d cobros';
  STicketResumenVentasSerie = 'RESUMEN VENTAS POR SERIE';
  STicketCabeceraSerie = 'SE';
  STicketCabeceraBaseImponible = 'BASE IMP';
  STicketCabeceraPorcentajeIva = '%IVA';
  STicketCabeceraCuota = 'CUOTA';
  STicketArqueoCaja = 'ARQUEO CAJA %s';
  STicketPendientesAnteriores = 'IMPORTES DEL PERIODO INDICADO';
  STicketPeriodoSeleccionado = 'PERIODO SELECCIONADO';
  STicketDesde = 'DESDE %s';
  STicketHasta = 'HASTA %s';
  STicketDuplicado = '*** DUPLICADO ***';
  STicketCierreCaja = 'CIERRE DE CAJA %s';
  STicketPeriodoCerrado = 'PERIODO CERRADO';
  STicketInicio = 'Inicio:';
  STicketFin = 'Fin:';
  STicketVentas = 'Ventas:';
  STicketCierrePor = 'Cierre por:';
  STicketVendedor = 'Vendedor:';
  STicketBilletesMonedas = 'BILLETES Y MONEDAS';
  STicketTotalContado = '  Total contado:';
  STicketEfectivoSistema = 'EFECTIVO SISTEMA';
  STicketVentasSangrado = '  Ventas:';
  STicketEntradasSangrado = '  + Entradas:';
  STicketGastosSangrado = '  - Gastos:';
  STicketAnteriorSangrado = '  + Anterior:';
  STicketTotalSangrado = '  = Total:';
  STicketRecuento = 'RECUENTO';
  STicketSistemaAbreviado = 'Sist.';
  STicketRecuentoAbreviado = 'Rec.';
  STicketDiferenciaAbreviada = 'Dif.';
  STicketTotalSistema = 'TOTAL SISTEMA:';
  STicketTotalRecontado = 'TOTAL RECONTADO:';
  STicketDiferencia = 'DIFERENCIA:';
  STicketRetirada = 'RETIRADA:';
  STicketDestinoSangrado = '  Destino:';
  STicketDejoCaja = 'DEJO EN CAJA:';
  STicketObservaciones = 'Obs: %s';
  STicketCambio = 'CAMBIO';
  STicketNumeroFactura = 'Nº Fac.: %s';
  STicketOperacionCorta = 'Op.%s';
  STicketClienteCorto = 'Cli: %s';
  STicketTotalTraspasoCoste = 'TOTAL TRASPASO (coste)';
  STicketTotalPerdidaCoste = 'TOTAL PÉRDIDA (coste)';
  STicketEntregadoCuenta = '  Entregado a cuenta';
  STicketPendienteSangrado = '  Pendiente';
  STicketRotuloTraspaso = 'TRASPASO';
  STicketRotuloIngreso = 'INGRESO';
  STicketRotuloGasto = 'GASTO';
  STicketRotuloDeposito = 'DEPOSITO';
  STicketRotuloVenta = 'VENTA';
  STicketTraspasosSalientes =
    '-TRASPASOS SALIENTES (ORIGEN)-';
  STicketIngresosPorCaja = '-INGRESOS POR CAJA-';
  STicketGastosPorCaja = '-GASTOS POR CAJA-';
  STicketVentasCreditoDepositos =
    '-VENTAS A CREDITO (DEPOSITOS)-';
  STicketVentasFacturadas = '-VENTAS FACTURADAS-';
  STicketTraspasos = 'TRASPASOS';
  STicketSubtotalCoste = 'SUBTOTAL (coste)';
  STicketIngresos = 'INGRESOS';
  STicketSubtotal = 'SUBTOTAL';
  STicketGastos = 'GASTOS';
  STicketDepositos = 'DEPOSITOS';
  STicketSubtotalVenta = 'SUBTOTAL VENTA';
  STicketSubtotalCobrado = 'SUBTOTAL COBRADO';
  STicketTotalVentasSinSigno = 'TOTAL VENTAS';
  STicketArqueoCajaHora = '-ARQUEO CAJA %s HORA %s-';
  STicketDel = 'DEL %s';
  STicketAl = 'AL  %s';
  STicketTodasSeries = 'TODAS LAS SERIES';
  STicketSeries = 'SERIES: %s';
  STicketOrdenCronologico = 'ORDEN: CRONOLOGICO';
  STicketOrdenTipoDocumento =
    'ORDEN: POR TIPO DE DOCUMENTO';
  STicketSinOperaciones = 'Sin operaciones';
  STicketResumen = '-RESUMEN-';

implementation

end.
