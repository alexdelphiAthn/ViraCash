{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgDistribucionTiendas                                   }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       21/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Mensajes de la distribución entre tiendas y de las propuestas de          }
{    traspaso.                                                                 }
{******************************************************************************}
unit inLibMsgDistribucionTiendas;

interface

resourcestring
  // --- Persistencia ---------------------------------------------------------
  SErrorDocumentoDistribucionNoExiste =
    'No existe el documento de trabajo %d.';
  SErrorPropuestaTraspasoNoExiste =
    'No existe la propuesta de traspaso %d.';
  SErrorDistribucionTiendasDesactualizada =
    'Alguna propuesta de este documento se ha confirmado mientras se ' +
    'editaba la distribución. Cierre la ventana y vuelva a abrirla para ' +
    'ver el reparto actualizado; los cambios sin guardar se perderán.';
  SErrorSkuDistribucionFueraDocumento =
    'La unidad %s ya no está en el documento de trabajo.';
  SErrorPropuestaTraspasoNoPendiente =
    'La propuesta de traspaso %d ya no está pendiente o no corresponde ' +
    'al origen %s y al destino %s.';
  SErrorPropuestaTraspasoSinCaja =
    'El almacén %s no tiene ninguna caja asignada: confirme la propuesta ' +
    'desde Traspasos de caja en ese almacén.';
  SErrorPropuestaTraspasoSinLineas =
    'La propuesta de traspaso %d no tiene unidades que traspasar.';
  // FZ-ISSUE-323: lotes y series al confirmar sin pantalla.
  SErrorPropuestaLotesInsuficientes =
    '%s (%s) no tiene existencias suficientes por lote o número de serie ' +
    'en %s: faltan %s. Regularice el stock o haga el traspaso desde ' +
    'Traspasos eligiendo los lotes.';
  SErrorPropuestaLoteCaducado =
    'El traspaso de %s (%s) desde %s se llevaría el lote caducado %s. ' +
    'Haga el traspaso desde Traspasos eligiendo los lotes.';

  // --- Ventana de distribución ---------------------------------------------
  STituloDistribucionTiendas = 'Distribución entre almacenes';
  STituloDistribucionTiendasDocumento =
    'Distribución entre almacenes - %s';
  SCaptionOrigenAutomaticoDistribucion =
    'Automático: el que más unidades tenga';
  SFormatoAlmacenDistribucion = '%s - %s';
  SCaptionColArticuloDistribucion = 'Artículo';
  SCaptionColDescripcionDistribucion = 'Descripción';
  SCaptionColColorDistribucion = 'Color';
  SCaptionColUnidadesDistribucion = 'Unidades';
  SCaptionColRepartidasDistribucion = 'Repartidas';
  SCaptionColPorRepartirDistribucion = 'Por repartir';
  SCaptionColAlmacenDistribucion = 'Almacén';
  SCaptionColNombreAlmacenDistribucion = 'Nombre';
  SCaptionColTotalDistribucion = 'Total';
  SCaptionColSinTallaDistribucion = 'Uds.';
  SCaptionColTallaDistribucion = 'Talla';
  SCaptionGuardarCerrarDistribucion = 'Guardar y cerrar (F12)';
  SCaptionCerrarDistribucion = '&Cerrar (ESC)';
  STextoFilaPorRepartirDistribucion = 'Por repartir del documento';
  SAvisoDistribucionSinUnidades =
    'El origen fijado no tiene esa talla: se han asignado %s.';
  SAvisoDistribucionSinExistencias =
    'No hay más existencias en el origen (%s; mínimo en origen %s): se ' +
    'han asignado %s.';
  SFormatoExistenciasOrigenDistribucion = '%s tiene %s y ya salen %s';
  SAvisoDistribucionRecortada =
    'Las existencias del origen ya no cubrían todo el reparto ' +
    'pendiente: se han retirado %s unidades. Revise el reparto y ' +
    'guárdelo.';
  SAvisoDistribucionNadaQueArrastrar =
    'Esa celda no tiene unidades que se puedan mover.';
  SAvisoDistribucionArrastreNoValido =
    'No se ha movido nada: compruebe el origen, su mínimo y sus ' +
    'existencias.';
  SInfoDistribucionArrastrado = '%s unidades de %s a %s.';
  SAvisoDistribucionSueloConfirmado =
    'Esa tienda ya tiene %s unidades traspasadas: no se puede bajar de ahí.';
  SAvisoDistribucionEsOrigen =
    'Ese almacén es origen de la talla: muestra lo que le queda.';
  SInfoDistribucionSinLineas =
    'El documento de trabajo no tiene unidades con talla y almacén para ' +
    'repartir.';
  SInfoDistribucionGuardada =
    'Reparto guardado: %d propuestas de traspaso pendientes.';
  SInfoRepartoAutomaticoHecho =
    'Reparto automático: %s unidades asignadas.';
  SInfoRepartoAutomaticoNada =
    'El reparto automático no ha encontrado unidades que asignar con ' +
    'esos parámetros.';
  SPreguntaGuardarDistribucion =
    'Hay cambios sin guardar en el reparto. ¿Desea guardarlos?';
  SPreguntaVaciarDistribucion =
    '¿Desea quitar todo el reparto pendiente? Lo ya confirmado se conserva.';
  SCaptionColPrioridadDistribucion = 'Prioridad';
  STextoOrigenCuadranteDistribucion = 'ORIGEN';
  SAvisoDistribucionNoRecibeTraspasos =
    'El almacén %s no recibe traspasos desde la distribución: no tiene ' +
    'número de prioridad. Asígneselo en Prioridades.';
  SAvisoDistribucionStockRefrescado =
    'Las existencias del origen han bajado: se han retirado %s unidades ' +
    'del reparto pendiente. Revíselo y guárdelo.';
  SPreguntaDistribucionSinDestinos =
    'Ningún almacén tiene número de prioridad, así que ninguno puede ' +
    'recibir traspasos desde la distribución. ¿Desea asignar ahora las ' +
    'prioridades?';

  // --- Prioridades de los almacenes ----------------------------------------
  STituloPrioridadesDistribucion = 'Prioridades de distribución';
  STextoAyudaPrioridadesDistribucion =
    'El 1 se repone primero; dos tiendas pueden compartir número. Un ' +
    'almacén sin número (o con 0) no recibe traspasos desde la ' +
    'distribución: déjelo así en el almacén central. Los almacenes de ' +
    'taras, depósito o tránsito nunca son destino y no aparecen aquí.';
  SInfoPrioridadesDistribucionSinAlmacenes =
    'No hay almacenes activos de uso estándar a los que dar prioridad.';
  SFormatoDestinoRepartoAutomatico = '%d · %s';

  // --- Propuestas -----------------------------------------------------------
  SCaptionColNumeroPropuesta = 'Propuesta';
  SCaptionColFechaPropuesta = 'Fecha';
  SCaptionColDocumentoPropuesta = 'Documento de trabajo';
  SCaptionColOrigenPropuesta = 'Origen';
  SCaptionColDestinoPropuesta = 'Destino';
  SCaptionColUnidadesPropuesta = 'Unidades';
  SCaptionColEstadoPropuesta = 'Estado';
  SCaptionColTraspasoPropuesta = 'Traspaso';
  SCaptionColOperacionPropuesta = 'Operación';
  SCaptionColMotivoPropuesta = 'Motivo';
  SCaptionColResolucionPropuesta = 'Resuelta';
  STextoEstadoPropuestaPendiente = 'Pendiente';
  STextoEstadoPropuestaTrasladada = 'Trasladado';
  STextoEstadoPropuestaTrasladadaParcial = 'Trasladado parcial';
  STextoEstadoPropuestaNoAceptada = 'No aceptado';
  SFormatoTraspasoPropuesta = '%s %s/%s';
  SInfoSeleccionarPropuesta =
    'Seleccione una propuesta de traspaso.';
  SInfoPropuestaYaNoPendiente =
    'La propuesta %d ya no está pendiente.';
  SPreguntaConfirmarPropuesta =
    'Se va a traspasar la propuesta %d: %s unidades de %s a %s. ' +
    'El traspaso mueve el stock y no se puede deshacer desde aquí. ' +
    '¿Desea continuar?';
  SPreguntaConfirmarTodasPropuestas =
    'Se van a traspasar las %d propuestas pendientes de este documento. ' +
    'Los traspasos mueven el stock y no se pueden deshacer desde aquí. ' +
    '¿Desea continuar?';
  SInfoPropuestaConfirmada =
    'Propuesta %d confirmada: traspaso %s %s/%s.';
  SInfoPropuestasConfirmadas =
    'Propuestas confirmadas: %d de %d.';
  SErrorPropuestaNoConfirmada =
    'La propuesta %d no se ha podido confirmar: %s';
  SPreguntaEliminarPropuesta =
    '¿Desea eliminar la propuesta pendiente %d?';
  STituloNoAceptarPropuesta = 'No aceptar la propuesta %d';
  SPreguntaMotivoNoAceptarPropuesta = 'Motivo';
  SInfoPropuestaNoAceptada =
    'La propuesta %d queda como no aceptada: sus unidades vuelven a ' +
    'estar por repartir.';
  SCaptionNoAceptarPropuesta = 'No aceptar';
  SCaptionCargarPropuestaEnTraspaso = 'Cargar en el traspaso';
  SCaptionSalirSeleccionPropuesta = 'Salir (ESC)';
  SInfoNoHayPropuestasPendientes =
    'No hay propuestas pendientes.';
  SInfoNoHayPropuestasPendientesOrigen =
    'No hay propuestas de traspaso pendientes con origen en %s.';
  STituloSeleccionPropuestaTraspaso =
    'Confirmar propuesta de traspaso - origen %s';
  SCaptionConfirmarPropuesta = 'Confirmar propuesta';
  SInfoPropuestaCargadaEnTraspaso =
    'Propuesta %d cargada con destino %s. Revise las unidades y grabe el ' +
    'traspaso: se le preguntará si la propuesta queda traspasada del todo ' +
    'o en parte.';
  SPreguntaEstadoPropuestaTraspasada =
    'El traspaso lleva %s de las %s unidades que faltaban de la ' +
    'propuesta %d a %s.'#13#10#13#10 +
    '¿Cómo queda la propuesta?'#13#10 +
    '- Traspasado: se da por terminada.'#13#10 +
    '- Traspasado parcial: lo que falta sigue pendiente y se podrá ' +
    'volver a cargar.';
  SCaptionPropuestaTraspasada = 'Traspasado';
  SCaptionPropuestaTraspasadaParcial = 'Traspasado parcial';
  SInfoPropuestaParcialCerrada =
    'La propuesta %d se da por trasladada con lo ya traspasado: lo que ' +
    'faltaba vuelve a estar por repartir.';

  // --- Documento de trabajo y albarán de compra -----------------------------
  STituloDocumentoDistribucionAlbaran = 'Distribución albarán %s/%s';
  SErrorAlbaranCompraSinGrabarDistribuir =
    'Grabe el albarán de compra antes de distribuirlo.';
  SErrorAlbaranCompraSinLineasDistribuir =
    'El albarán de compra no tiene líneas con artículo y cantidad que ' +
    'distribuir.';
  SCaptionDistribuirAlbaranCompra = 'Distribuir';
  SPreguntaAlbaranCompraYaDistribuido =
    'El albarán %s/%s ya tiene una distribución: el documento de trabajo ' +
    '%d. ¿Desea abrirla? Si responde No se creará otro documento de ' +
    'trabajo con las líneas del albarán.';
  STituloElegirDocumentoDistribucion =
    'Documento de trabajo que se va a distribuir';

  // --- Pantalla del historial ------------------------------------------------
  STituloHistorialDistribucionTiendas = 'Distribuir entre tiendas';
  SCaptionDocumentoDistribucion = 'Documento de trabajo';
  SCaptionDistribuirDocumento = 'Distribuir...';
  SCaptionAbrirDistribucion = 'Abrir distribución';
  SCaptionImprimirPropuesta = 'Imprimir';
  SCaptionPrioridadesDistribucion = 'Prioridades...';
  SCaptionRefrescarHistorialDistribucion = 'Refrescar';
  SCaptionColUsuarioPropuesta = 'Usuario';
  SCaptionColUsuarioResolucionPropuesta = 'Resuelta por';
  STextoAyudaHistorialDistribucion =
    'Elija un documento de trabajo y pulse Distribuir para repartirlo ' +
    'entre las tiendas. Debajo, el historial de las propuestas de ' +
    'traspaso y su estado: pendiente, trasladado o no aceptado.';
  SInfoElegirDocumentoDistribucion =
    'Elija el documento de trabajo que quiere distribuir.';
  SErrorMotivoNoAceptarObligatorio =
    'Indique el motivo por el que no se acepta la propuesta.';

  // --- Reparto automático ---------------------------------------------------
  STituloRepartoAutomatico = 'Reparto automático';
  SErrorRepartoAutomaticoSinDestinos =
    'Marque al menos una tienda para el reparto automático.';
  SCaptionCriterioOrdenAlmacen = 'En ronda, por orden de almacén';
  SCaptionCriterioMenorStock = 'Primero la tienda con menos existencias';
  SAyudaRepartoAutomatico =
    'Reparte lo recibido que queda por repartir. Se añade a lo ya ' +
    'repartido y respeta el origen fijado y el mínimo en origen.';

  // --- Informe --------------------------------------------------------------
  STituloInformePropuestaTraspaso = 'Propuesta de traspaso';
  STituloImprimirPropuestasTraspaso = 'Imprimir propuestas de traspaso';
  STextoImprimirPropuestasTraspaso =
    'Una hoja por cada origen y destino, con los artículos por color y ' +
    'sus tallas.';
  SFormatoNumeroInformePropuesta = 'Propuesta nº %d';
  SFormatoOrigenInformePropuesta = 'Origen: %s';
  SFormatoDestinoInformePropuesta = 'Destino: %s';
  SFormatoDocumentoInformePropuesta = 'Documento de trabajo %d - %s';
  SFormatoEstadoInformePropuesta = 'Estado: %s';
  SCaptionColTallasInformePropuesta = 'Tallas (talla: unidades)';
  SCaptionTotalInformePropuesta = 'Total unidades';
  SFormatoTallaInformePropuesta = '%s: %s';
  SNombreArchivoPropuestasTraspaso = 'Propuestas_traspaso_%d';

implementation

end.
