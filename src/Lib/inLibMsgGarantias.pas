{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgGarantias                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de las garantías y reclamaciones por número de serie               }
{    (F-LOTEC-021).                                                            }
{******************************************************************************}
unit inLibMsgGarantias;

interface

resourcestring
  STituloGarantiasReclamaciones = 'Reclamaciones de garantía';
  SCaptionFiltroEstadoGarantia = 'Estado:';
  SCaptionFiltroSerieGarantia = 'Serie / cliente:';
  SCaptionGarantiaAbiertas = 'Abiertas y en SAT';
  SCaptionGarantiaTodas = 'Todas';
  SCaptionGarantiaAbierta = 'Abierta';
  SCaptionGarantiaEnSat = 'En SAT';
  SCaptionGarantiaResuelta = 'Resuelta';
  SCaptionGarantiaRechazada = 'Rechazada';
  // FZ-ISSUE-602: resolución SUSTITUIDA y venta sin cliente en la rejilla
  // y en el resumen de la serie.
  SCaptionGarantiaSustituida = 'Sustituida';
  SClienteContadoGarantia = 'cliente de contado';
  SCaptionGarantiaRefrescar = 'Refrescar';
  SCaptionGarantiaNueva = 'Nueva';
  SCaptionGarantiaEnviarSat = 'Enviar al SAT';
  SCaptionGarantiaReparada = 'Reparada';
  SCaptionGarantiaSustituir = 'Sustituir';
  SCaptionGarantiaAbonada = 'Devolución';
  SCaptionGarantiaRechazar = 'Rechazar';
  SCaptionGarantiaExcel = 'Excel';
  SCaptionNuevaGarantia = 'Nueva garantía';
  SCaptionAbrirFichaGarantia = 'Abrir ficha';
  SCaptionCambiarEstadoGarantia = 'Cambiar estado';
  SCaptionMasOpcionesGarantia = 'Más opciones';
  SCaptionMarcarReparada = 'Marcar como reparada';
  SCaptionMarcarAbonada = 'Devolución';
  SCaptionImprimirResguardoGarantia = 'Imprimir resguardo';
  SCaptionExportarGarantiasExcel = 'Exportar a Excel';

  SCaptionColGarantiaId = 'Nº';
  SCaptionColGarantiaFecha = 'Fecha';
  SCaptionColGarantiaSerie = 'Nº de serie';
  SCaptionColGarantiaSku = 'SKU';
  SCaptionColGarantiaArticulo = 'Artículo';
  SCaptionColGarantiaCliente = 'Cliente';
  SCaptionColGarantiaVenta = 'Venta';
  SCaptionColGarantiaFechaVenta = 'Fecha venta';
  SCaptionColGarantiaFin = 'Fin garantía';
  SCaptionColGarantiaEnGarantia = 'En garantía';
  SCaptionColGarantiaEstado = 'Estado';
  SCaptionColGarantiaResolucion = 'Resolución';
  SCaptionColGarantiaSustituta = 'Serie entregada';
  SCaptionColGarantiaMotivo = 'Motivo';
  SCaptionColGarantiaObservaciones = 'Observaciones';
  SCaptionColGarantiaUsuario = 'Usuario';

  STituloNuevaReclamacion = 'Nueva reclamación';
  SPreguntaSerieReclamacion = 'Lea o escriba el número de serie:';
  SPreguntaMotivoReclamacion =
    '%s · %s' + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Motivo de la reclamación:';
  SResumenVentaGarantia = 'Vendida el %s a %s (%s). Garantía hasta %s.';
  SResumenSinVentaGarantia = 'No consta ninguna venta de esta serie.';
  SResumenSinMesesGarantia =
    'Vendida el %s a %s (%s). El artículo no tiene meses de garantía.';
  SAvisoFueraGarantia =
    'La serie %s está fuera de garantía (terminó el %s). ' +
    '¿Registrar la reclamación igualmente?';
  SAvisoReclamacionAbierta =
    'La serie %s ya tiene una reclamación abierta. ' +
    '¿Registrar otra igualmente?';
  SErrorSerieDesconocidaGarantia =
    'La serie %s no está en el catálogo de lotes y series.';
  SInfoSinReclamacion = 'Seleccione una reclamación.';
  SErrorReclamacionCerrada = 'La reclamación ya está cerrada.';
  STituloSustituirSerie = 'Sustituir por otra unidad';
  SPreguntaSerieSustituta =
    'Serie que se entrega al cliente (sale del almacén %s):';
  SErrorSinAlmacenTaras =
    'No hay ningún almacén de taras activo en la empresa para recibir ' +
    'la unidad devuelta. En Almacenes, dé de alta uno en la misma ' +
    'empresa, márquelo activo y seleccione Taras en Tipo de uso. ' +
    'Después vuelva a Sustituir.';
  SPreguntaFormatoResguardo = 'Seleccione el formato del resguardo:';
  SInfoSustitucionHecha =
    'Entregada la serie %s; la %s queda en el almacén de taras %s.';
  STituloObservacionesGarantia = 'Reclamación %s';
  SPreguntaObservacionesGarantia = 'Observaciones:';
  SNombreArchivoGarantias = 'reclamaciones_garantia_%s';
  SCaptionMesesGarantiaArticulo = 'Meses de garantía:';
  SHintMesesGarantiaArticulo =
    'Meses de garantía desde la venta de cada unidad (vacío = sin ' +
    'garantía).';

  // Ficha de la reclamación (19/10/2026): cliente, proveedor y fases.
  SCaptionGarantiaFicha = 'Ficha';
  SCaptionColGarantiaFase = 'Fase';
  SCaptionColGarantiaModelo = 'Modelo';
  SCaptionColGarantiaProveedor = 'Proveedor';
  SCaptionColGarantiaContacto = 'Contacto';
  SCaptionColGarantiaTelefono = 'Teléfono';
  SCaptionColGarantiaRma = 'RMA';
  SCaptionGrupoReclamacion = 'Reclamación';
  SCaptionGrupoClienteGarantia = 'Cliente';
  SCaptionGrupoProveedorGarantia = 'Proveedor';
  SCaptionFaseRecepcion = 'Recepción';
  SCaptionFaseEnvioFabricante = 'Envío al fabricante';
  SCaptionFaseRecepcionFabricante = 'Recepción del fabricante';
  SCaptionFaseEntregaCliente = 'Entrega al cliente';
  SCaptionMedioGarantiaTienda = 'En tienda';
  SCaptionMedioGarantiaAgencia = 'Agencia de transporte';
  SCaptionGarantiaNumero = 'Nº:';
  SCaptionGarantiaFechaReclamacion = 'Fecha:';
  SCaptionGarantiaEstadoFicha = 'Estado:';
  SCaptionGarantiaSerieFicha = 'Nº de serie:';
  SCaptionGarantiaSkuFicha = 'SKU:';
  SCaptionGarantiaArticuloFicha = 'Artículo:';
  SCaptionGarantiaModeloFicha = 'Modelo:';
  SCaptionGarantiaMotivoFicha = 'Motivo:';
  SCaptionGarantiaObservacionesFicha = 'Observaciones:';
  SCaptionGarantiaResolucionFicha = 'Resolución:';
  SCaptionGarantiaSerieEntregada = 'Serie entregada:';
  SCaptionGarantiaClienteFicha = 'Cliente:';
  SCaptionGarantiaNombreCliente = 'Nombre:';
  SCaptionGarantiaTelefonoFicha = 'Teléfono:';
  SCaptionGarantiaCorreoFicha = 'Correo:';
  SCaptionGarantiaDireccionFicha = 'Dirección:';
  SCaptionGarantiaCodigoPostalFicha = 'C.P.:';
  SCaptionGarantiaPoblacionFicha = 'Población:';
  SCaptionGarantiaProvinciaFicha = 'Provincia:';
  SCaptionGarantiaVentaFicha = 'Venta:';
  SCaptionVendedorVentaGarantia = 'Empleado';
  SCaptionGarantiaFechaVentaFicha = 'Fecha venta:';
  SCaptionGarantiaFinGarantiaFicha = 'Fin garantía:';
  SCaptionGarantiaProveedorFicha = 'Proveedor:';
  SCaptionGarantiaContactoFicha = 'Contacto:';
  SCaptionGarantiaTelefonoContacto = 'Tel. contacto:';
  SCaptionGarantiaMovilFicha = 'Móvil:';
  SCaptionGarantiaFechaRecepcion = 'Fecha recepción:';
  SCaptionGarantiaMedio = 'Medio:';
  SCaptionGarantiaAgencia = 'Agencia:';
  SCaptionGarantiaTracking = 'Nº de tracking:';
  SCaptionGarantiaFechaEnvio = 'Fecha envío:';
  SCaptionGarantiaRmaFicha = 'Nº RMA:';
  SCaptionGarantiaDireccionEnvio = 'Dirección de envío:';
  SCaptionGarantiaTrackingEnvio = 'Tracking envío:';
  SCaptionGarantiaTrackingRecepcion = 'Tracking recepción:';
  SCaptionGarantiaIncidencia = 'Incidencia en el transporte';
  SCaptionGarantiaDetalleIncidencia = 'Detalle incidencia:';
  SCaptionGarantiaReclamacionTransporte = 'Reclamación transporte:';
  SCaptionGarantiaIntervencionFabricante = 'Intervención fabricante:';
  SCaptionGarantiaFechaEntrega = 'Fecha entrega:';
  SInfoAltaGarantiaDesdeNueva =
    'Las reclamaciones se dan de alta con «Nueva», leyendo el número ' +
    'de serie.';
  SInfoGarantiaNoSeBorra =
    'Una reclamación no se borra: si no procede, se rechaza.';

  SCaptionResguardoGarantia = 'Resguardo de depósito';
  SCaptionImprimirResguardo = 'Resguardo';
  SResguardoFueraGarantia = 'Fuera de garantía o sin fecha acreditada';
  SResguardoConservar = 'Conserve este resguardo para la recogida.';
  SResguardoFirmaCliente = 'Firma del cliente:';
  SCaptionClienteVentaGarantia = 'Cliente de la venta';

  SErrorTiendaResguardo =
    'No se encuentran los datos de la tienda de esta reclamación.';

implementation

end.
