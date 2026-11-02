{******************************************************************************}
{  Módulo: inLibMsgReparacionesCircuito. Tipo: Librería                        }
{  Fecha: 01/11/2026. Autor: Alejandro Laorden Hidalgo                         }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Textos del circuito de ejecución y cobertura de órdenes.       }
{******************************************************************************}
unit inLibMsgReparacionesCircuito;

interface

resourcestring
  SCircuitoSinOrden = 'Sin orden seleccionada';
  SCircuitoDocumentoNoDisponible =
    'No se encuentra esa línea de documento para el destinatario de la ' +
    'orden. Revisa serie, número y línea.';
  SCircuitoImporteDocumento =
    'El importe supera lo disponible en esa línea del documento.';
  SCircuitoDatosDocumento =
    'Indica un destinatario válido, la serie, una fecha válida y un ' +
    'importe y cantidad mayores que cero.';
  SCircuitoEmpresaExterna = 'Proveedor externo';
  SCircuitoCampoFormato = 'Revisa el formato del campo «%s».';
  SCircuitoColTotal = 'Total';
  SCircuitoColCliente = 'Cliente';
  SCircuitoColAseguradora = 'Aseguradora';
  SCircuitoColPendiente = 'Pendiente de autorización';
  SCircuitoColHorasReales = 'Horas reales';
  SCircuitoColHorasFacturables = 'Horas facturables';
  SCircuitoColHoras = 'Horas';
  SCircuitoColConcepto = 'Concepto';
  SCircuitoColAnulada = 'Anulada';
  SCircuitoColFecha = 'Fecha';
  SCircuitoColUsuario = 'Usuario';
  SCircuitoColAccion = 'Acción';
  SCircuitoColDetalle = 'Detalle';
  SCircuitoColNumero = 'Nº';
  SCircuitoPestana = 'Modo avanzado';
  SCircuitoGrupoCondiciones = 'Condiciones y cierre';
  SCircuitoGrupoTrabajo = 'Trabajo y materiales';
  SCircuitoGrupoAlbaranes = 'Albaranes';
  SCircuitoGrupoExternos = 'Empresas externas';
  SCircuitoAcuerdo = 'Acuerdo y aceptación';
  SCircuitoConcepto = 'Condiciones del concepto';
  SCircuitoTiempo = 'Registrar tiempo';
  SCircuitoCorregirTiempo = 'Corregir sesión';
  SCircuitoPausar = 'Pausar / finalizar sesión';
  SCircuitoMaterial = 'Material empleado';
  SCircuitoCerrar = 'Cerrar trabajo técnico';
  SCircuitoCerrarEconomico = 'Verificar cierre económico';
  SCircuitoEconomicoPendiente =
    'Quedan conceptos sin documentar, facturas o cobros/pagos pendientes.';
  SCircuitoCodigoManual = 'Código manual';
  SCircuitoOrden = 'Orden: ';
  SCircuitoTodos = 'Albarán de pendientes';
  SCircuitoTipoVenta = 'Destinatario: CL cliente / AS aseguradora';
  SCircuitoSinPendientes = 'No quedan importes para ese destinatario.';
  SCircuitoTipoImputacion =
    'Tipo: CL cliente / AS aseguradora / PR proveedor / TC ticket cliente';
  SCircuitoRefrescar = 'Refrescar';
  SCircuitoAlbaran = 'Crear albarán';
  SCircuitoImputar = 'Imputar línea de albarán';
  SCircuitoLiberar = 'Liberar imputación';
  SCircuitoDocumentos = 'Importes documentados';
  SCircuitoTipoDoc = 'Destinatario: CL cliente / AS aseguradora / PR proveedor';
  SCircuitoSerieDoc = 'Serie del albarán';
  SCircuitoNumeroDoc = 'Número del albarán';
  SCircuitoLineaDoc = 'Línea del albarán';
  SCircuitoProveedor = 'Código de proveedor (solo compra)';
  SCircuitoImporteDoc = 'Importe: con IVA en venta / base sin IVA en compra';
  SCircuitoColImporteDoc = 'Importe (CL/AS/TC con IVA; PR base sin IVA)';
  SCircuitoColCodigoProveedor = 'Código de proveedor';
  SCircuitoColProveedor = 'Proveedor';
  SCircuitoCantidadDoc = 'Cantidad documentada';
  SCircuitoFechaDoc = 'Fecha del albarán';
  SCircuitoTipoIva =
    'Tipo de IVA: N normal / R reducido / S superreducido / E exento';
  SCircuitoEntrega = 'Nueva entrega a externo';
  SCircuitoRetorno = 'Recepción del externo';
  SCircuitoExternos = 'Custodia en externos';
  SCircuitoObjeto = 'Objeto o piezas entregados';
  SCircuitoEnviado = 'Cantidad enviada';
  SCircuitoRecibido = 'Cantidad recibida acumulada';
  SCircuitoIncidencia = 'Incidencia / motivo de devolución';
  SCircuitoImprimir = 'Hoja interna';
  SCircuitoResumenReparto =
    'Cliente: %s · Aseguradora: %s · Taller: %s · Pendiente: %s';
  SCircuitoDetalleHoja =
    'Horas previstas: %s; reales: %s; facturables: %s. ' +
    'Material utilizado: %s; devuelto: %s. Coste previsto: %s.';
  SCircuitoHuecoHoja =
    'Operario: __________ Inicio: __________ Fin: __________ ' +
    'Tiempo: __________' + #13#10 +
    'Piezas / material: __________________ Cantidad: ______ Unidad: ______';
  SCircuitoHistorial = 'Historial';
  SCircuitoTiempos = 'Sesiones de trabajo';
  SCircuitoMateriales = 'Material empleado';
  SCircuitoReferencia = 'Referencia del acuerdo / siniestro';
  SCircuitoAutorizacion = 'Referencia de autorización';
  SCircuitoPorcentajeMO = 'Cobertura de mano de obra (%)';
  SCircuitoPorcentajeMAT = 'Cobertura de piezas y materiales (%)';
  SCircuitoLimite = 'Límite de cobertura (vacío = sin límite)';
  SCircuitoFranquicia = 'Franquicia única de la orden';
  SCircuitoAutorizado = 'Autorizado por aseguradora (S/N)';
  SCircuitoAceptado = 'Cliente acepta su parte (S/N)';
  SCircuitoHorasPrevistas = 'Horas previstas';
  SCircuitoHorasFacturables = 'Horas facturables (vacío = precio cerrado)';
  SCircuitoPropia = 'Cobertura propia para esta línea (S/N)';
  SCircuitoPorcentaje = 'Cobertura propia (%)';
  SCircuitoTaller = 'Importe asumido por el taller';
  SCircuitoOperario = 'Código de operario';
  SCircuitoTarea = 'Tarea realizada';
  SCircuitoInicio = 'Inicio (fecha y hora)';
  SCircuitoFin = 'Fin (vacío = sesión en curso)';
  SCircuitoMotivo = 'Motivo de corrección / excepción';
  SCircuitoProcedencia = 'Procedencia: ALMACEN / COMPRA / CLIENTE / EXTERNO';
  SCircuitoAlmacen = 'Almacén del consumo';
  SCircuitoUnidad = 'Unidad: uds, m, etc.';
  SCircuitoPrevisto = 'Cantidad prevista';
  SCircuitoUtilizado = 'Cantidad utilizada acumulada';
  SCircuitoDevuelto = 'Cantidad devuelta del consumo acumulado';
  SCircuitoOrigen = 'Referencia de procedencia / albarán';
  SCircuitoSeleccionar = 'Selecciona un concepto de la orden.';
  SCircuitoSeleccionarTiempo = 'Selecciona una sesión activa de trabajo.';
  SCircuitoBooleano = 'Escribe S o N en las opciones de aceptación.';
  SCircuitoFormato = 'Revisa el formato de los importes, cantidades y fechas.';
  SCircuitoAcuerdoInvalido = 'Revisa porcentajes, límite y franquicia.';
  SCircuitoFaltaAutorizacion = 'Indica la referencia de autorización.';
  SCircuitoRepartoInvalido = 'El reparto no puede superar el concepto.';
  SCircuitoTiempoInvalido =
    'Indica operario, tarea y un intervalo de tiempo válido, ' +
    'sin fechas futuras.';
  SCircuitoMotivoCorreccion = 'Indica el motivo de la corrección.';
  SCircuitoMaterialInvalido =
    'Revisa la procedencia (ALMACEN, COMPRA, CLIENTE o EXTERNO), la unidad ' +
    'y que las cantidades no sean negativas.';
  SCircuitoDevueltoSupera =
    'La cantidad devuelta no puede superar la cantidad utilizada.';
  SCircuitoEntregaInvalida =
    'Indica proveedor y objeto; lo enviado debe ser mayor que cero y lo ' +
    'recibido no puede superarlo.';
  SCircuitoConflicto =
    'La orden ha cambiado o está cerrada. Refresca antes de continuar.';
  SCircuitoTiempoSolapado = 'El operario ya tiene tiempo en ese intervalo.';
  SCircuitoNoManoObra = 'Selecciona una línea de mano de obra.';
  SCircuitoNoMaterial = 'Selecciona una línea de material.';
  SCircuitoDocumentado =
    'Hay importes documentados. Conserva el reparto o corrige los documentos.';
  SCircuitoPendiente =
    'Termina las líneas de mano de obra y resuelve las autorizaciones, ' +
    'las sesiones de trabajo abiertas y las entregas externas.';
  SCircuitoFaltaEsquema = 'Actualiza el esquema del circuito de órdenes.';
  SCircuitoAlmacenDocumento =
    'Selecciona un almacén TALLER activo y compatible con la orden.';
  SCircuitoProveedorLinea =
    'El concepto no está asignado a ese proveedor. Indica la empresa ' +
    'externa en «Lo hace» de la línea (Ficha > Trabajos) o usa su proveedor.';
  SCircuitoSinAseguradora =
    'La orden no tiene aseguradora pagadora. Indícala en Ficha > ' +
    'Albaranes (Cliente de facturación / pagador) antes de crear el ' +
    'albarán de la aseguradora.';
  SCircuitoCobroExistente =
    'La orden tiene cobro o ticket vinculado. Revisa ese documento antes ' +
    'de emitir otro albarán de venta.';

implementation

end.
