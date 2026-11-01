{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgListasRegalos                                         }
{    Tipo:       Librería (mensajes)                                           }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de la pantalla Lista de regalos PrestaShop (Ventas Mayor) y de     }
{    su sincronización con el módulo vcashlistaregalos de la tienda.           }
{******************************************************************************}
unit inLibMsgListasRegalos;

interface

resourcestring
  STituloListasRegalos = 'Lista de regalos PrestaShop';
  // Filtros y botones de la lista.
  SCaptionFiltroEstadoLista = 'Estado:';
  SCaptionFiltroTextoLista = 'Titulares / código:';
  SCaptionListasAbiertas = 'Abiertas';
  SCaptionListasCerradas = 'Cerradas';
  SCaptionListasAnuladas = 'Anuladas';
  SCaptionListasTodas = 'Todas';
  SCaptionListaRefrescar = 'Refrescar';
  SCaptionListaSincronizar = 'Sincronizar con PrestaShop';
  SCaptionListaCerrar = 'Cerrar lista';
  SCaptionListaAnular = 'Anular lista';
  // Estados, tipos, canales y entrega.
  SEstadoListaAbierta = 'Abierta';
  SEstadoListaCerrada = 'Cerrada';
  SEstadoListaAnulada = 'Anulada';
  STipoListaNacimiento = 'Nacimiento';
  STipoListaBautizo = 'Bautizo';
  STipoListaComunion = 'Comunión';
  STipoListaCumpleanos = 'Cumpleaños';
  STipoListaBoda = 'Boda';
  STipoListaOtra = 'Otra';
  SCanalRegaloCaja = 'Caja';
  SCanalRegaloWeb = 'Web';
  SCanalRegaloManual = 'Manual';
  SEstadoRegaloConfirmado = 'Confirmado';
  SEstadoRegaloAnulado = 'Anulado';
  SEntregaListaTienda = 'Recogida en tienda';
  SEntregaListaDomicilio = 'Envío a domicilio';
  // Columnas de la lista.
  SColListaCodigo = 'Código';
  SColListaClave = 'Clave web';
  SColListaTipo = 'Tipo';
  SColListaTitulo = 'Título';
  SColListaTitulares = 'Titulares';
  SColListaHomenajeado = 'Homenajeado';
  SColListaFechaEvento = 'Fecha del evento';
  SColListaEstado = 'Estado';
  SColListaWeb = 'Web';
  SColListaLineas = 'Artículos';
  SColListaRegalado = 'Regalado';
  SColListaVersion = 'Versión';
  // Ficha: rótulos de cabecera.
  SGrupoDatosLista = 'Lista';
  SGrupoTitularesLista = 'Titulares y web';
  SRotuloListaCodigo = 'Código:';
  SRotuloListaClave = 'Clave web:';
  SRotuloListaTipo = 'Tipo:';
  SRotuloListaTitulo = 'Título:';
  SRotuloListaHomenajeado = 'Homenajeado:';
  SRotuloListaFechaEvento = 'Fecha del evento:';
  SRotuloListaCaducidad = 'Cierre previsto:';
  SRotuloListaEstado = 'Estado:';
  SRotuloListaCliente = 'Cliente:';
  SRotuloListaTitulares = 'Titulares:';
  SRotuloListaEmail = 'Email:';
  SRotuloListaMovil = 'Móvil:';
  SRotuloListaEntrega = 'Entrega:';
  SRotuloListaBonificacion = 'Bonificación %:';
  SRotuloListaMensaje = 'Mensaje web:';
  SRotuloListaPublica = 'Publicar en la web';
  SRotuloListaBuscable = 'Aparece en el buscador';
  // Ficha: líneas y regalos.
  SPestanaLineasLista = 'Artículos';
  SPestanaRegalosLista = 'Regalos';
  SRotuloListaSku = 'SKU o código de barras:';
  SRotuloListaCantidad = 'Cantidad:';
  SCaptionListaAgregarLinea = 'Añadir';
  SCaptionListaCambiarCantidad = 'Cambiar cantidad';
  SCaptionListaEntregarRegalo = 'Marcar entregado';
  SCaptionListaAnularRegalo = 'Anular regalo';
  SColLineaSku = 'SKU';
  SColLineaDescripcion = 'Descripción';
  SColLineaDeseada = 'Desean';
  SColLineaRegalada = 'Regalados';
  SColLineaPendiente = 'Pendientes';
  SColLineaPrecio = 'Precio';
  SColLineaImprescindible = 'Imprescindible';
  SColLineaOtraVariante = 'Admite otra talla/color';
  SColLineaObservaciones = 'Observaciones';
  SColRegaloFecha = 'Fecha';
  SColRegaloCanal = 'Canal';
  SColRegaloRegalante = 'De';
  SColRegaloMensaje = 'Mensaje';
  SColRegaloImporte = 'Importe';
  SColRegaloEntregado = 'Entregado';
  SColRegaloEstado = 'Estado';
  SColRegaloPedido = 'Pedido / operación';
  // Preguntas y avisos.
  SPreguntaCantidadLinea = 'Nueva cantidad deseada (0 retira la línea):';
  SPreguntaMotivoAnulacionRegalo = 'Motivo de la anulación (devolución):';
  SConfirmarCerrarLista =
    '¿Cerrar la lista %s? Se fija lo regalado (%s) y la bonificación para ' +
    'los titulares, y la lista deja de verse en la web.';
  SConfirmarAnularLista = '¿Anular la lista %s?';
  SInfoListaCerrada =
    'Lista cerrada. Regalado: %s. Bonificación para los titulares: %s.';
  SInfoListaSinSeleccion = 'Seleccione una lista.';
  SInfoRegaloSinSeleccion = 'Seleccione un regalo.';
  SInfoLineaSinSeleccion = 'Seleccione un artículo de la lista.';
  SInfoListaGrabarAntes = 'Grabe la lista antes de añadir artículos.';
  SInfoListaSinBorrado =
    'Las listas no se borran: anúlela (sin regalos) o ciérrela.';
  SErrorListaSinTitulares = 'Indique el nombre de los titulares.';
  SErrorSkuListaNoEncontrado =
    'No hay ningún SKU activo con el código o código de barras «%s».';
  // Códigos de resultado de los procedimientos PRC_LRG_*.
  SResultadoListaSumada = 'El artículo ya estaba: se ha sumado la cantidad.';
  SResultadoListaExcedente =
    'Registrado por encima de lo pendiente (excedente).';
  SResultadoListaYaRegistrado = 'Ya estaba registrado.';
  SResultadoListaNadaQueHacer = 'No había nada que cambiar.';
  SResultadoListaNoAbierta = 'La lista no existe o no está abierta.';
  SResultadoListaLineaNoValida =
    'El artículo no existe en la lista o está retirado.';
  SResultadoListaSkuNoValido =
    'El SKU no existe, está de baja o no corresponde a la línea.';
  SResultadoListaCantidadNoValida = 'La cantidad no es válida.';
  SResultadoListaSuperaPendiente =
    'La cantidad supera lo pendiente o queda por debajo de lo ya regalado.';
  SResultadoListaEstadoNoPermite = 'El estado actual no lo permite.';
  SResultadoListaDesconocido = 'Resultado inesperado (%d).';
  // Sincronización.
  SErrorListasPrestaShopSinConfigurar =
    'Configure en Parámetros de Entorno la URL de PrestaShop ' +
    '(appPrestaShopUrl) y la clave de listas de regalos ' +
    '(appPrestaShopClaveListasRegalos).';
  SErrorListasPrestaShopRespuesta =
    'PrestaShop respondió %d en «%s»: %s';
  SErrorListasPrestaShopJson =
    'La respuesta de PrestaShop en «%s» no es un JSON válido.';
  SInfoSincronizacionListasVacia =
    'Las listas ya estaban al día en PrestaShop.';
  SInfoSincronizacionListas =
    'Sincronización terminada: %d listas publicadas, %d regalos web ' +
    'registrados y %d rechazados.';
  SSincroListaPublicada = 'Lista %s, versión %d, publicada.';
  SSincroListaIgnorada =
    'Lista %s: la tienda ya tenía una versión posterior.';
  SSincroSinProducto = 'Lista %s: sin producto en la tienda para %s.';
  SSincroRegaloRegistrado = 'Regalo web de %s para la lista %s registrado.';
  SSincroRegaloRechazado =
    'Regalo web de %s para la lista %s rechazado: %s';
  SEsperaSincronizacionListas = 'Sincronizando listas con PrestaShop...';

implementation

end.
