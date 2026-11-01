{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgTrazabilidad                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de la trazabilidad por lote y serie (F-LOTEC):          }
{    repositorio de lotes, elección de lote y alta de series.                  }
{******************************************************************************}
unit inLibMsgTrazabilidad;

interface

resourcestring
  SErrorRepartoLotesCaja =
    'Seleccione «Elegir lote» para repartir las unidades ' +
    'entre los lotes disponibles.';
  SCaptionSesionLotes = '&6. Lotes / Series por destino';
  SCaptionSesionArticuloPorLotes = 'Artículo nuevo por lotes';
  SCaptionSesionOtroLote = 'Otro lote (copiar línea)';
  SCaptionSesionLineaLotes = 'Línea %d · %s · %s';
  SCaptionSesionAlmacen = 'Almacén de destino';
  SCaptionSesionTalla = 'Talla / variante';
  SCaptionSesionFila = 'Fila';
  SCaptionSesionSeries = 'Series (una por línea)';
  SHintSesionLotes =
    'Asigne la familia y las cantidades. Rellene la trazabilidad de cada ' +
    'talla y almacén de destino; una serie por unidad. Para varios lotes, ' +
    'use «Otro lote» y ajuste las cantidades de cada línea.';
  SErrorSesionFaltaLote = 'Indique el lote de %s en el almacén %s.';
  SErrorSesionLoteLargo = 'El lote de %s es demasiado largo.';
  SErrorSesionFaltaCaducidad =
    'Indique la caducidad de %s en el almacén %s.';
  SErrorSesionSeriesCantidad =
    'Indique una serie válida y distinta por unidad de %s en el almacén %s.';
  SErrorSesionSerieRepetida =
    'La serie %s se repite en la sesión o entre almacenes de destino.';

  // Alta de artículos: la familia es la única fuente (FZ-ISSUE-304).
  SCaptionTrazabilidadFamilia = 'Trazabilidad de los artículos nuevos:';
  SCaptionFamiliaLote = 'Lote obligatorio';
  SCaptionFamiliaLoteCaducidad = 'Lote y caducidad obligatorios';
  SCaptionFamiliaSerie = 'Número de serie obligatorio';
  SErrorTrazabilidadFamiliaInvalida =
    'El modo de trazabilidad de la familia «%s» no es válido.';
  SErrorAltaTrazabilidadNoCoincideFamilia =
    'La trazabilidad del artículo debe coincidir con la familia «%s». ' +
    'Seleccione una familia compatible o use su modo y caducidad.';

  SErrorResultadoProcedimientoLotes =
    'El procedimiento %s ha devuelto un resultado desconocido: «%s». ' +
    'Compruebe que la base de datos está actualizada.';

  // Elegir lote o serie para una salida.
  STituloSeleccionLote = 'Elegir lote';
  STituloSeleccionSerie = 'Elegir números de serie';
  SCaptionColumnaLote = 'Lote';
  SCaptionColumnaSerie = 'Nº de serie';
  SCaptionColumnaCaducidad = 'Caducidad';
  SCaptionColumnaDiasCaducidad = 'Días';
  SCaptionColumnaEntrada = 'Entrada';
  SCaptionColumnaStockLote = 'Stock';
  SCaptionColumnaCantidadLote = 'Cantidad';
  SCaptionColumnaElegirSerie = 'Elegir';
  SCaptionSinLote = '(sin lote)';
  SCabeceraSeleccionLote = '%s  %s · Almacén %s · Pide %s';
  SPieSeleccionLote = 'Elegido: %s de %s';
  SCaptionLeerSerieSeleccion = 'Leer serie:';
  SAvisoSinExistenciasLote =
    'No hay existencias de este artículo en el almacén %s.';
  SErrorCantidadLoteNegativa =
    'La cantidad del lote %s no puede ser negativa.';
  SErrorCantidadLoteSuperaStock =
    'La cantidad del lote %s (%s) supera su stock (%s).';
  SErrorSeleccionLoteVacia = 'Indique la cantidad de algún lote.';
  SErrorSeleccionSerieVacia = 'Marque o lea alguna serie.';
  SAvisoLotesCaducadosSeleccion =
    'Hay lotes caducados en la selección (%s). Pulse Aceptar otra vez ' +
    'para usarlos igualmente.';
  SErrorSerieNoEnAlmacen = 'La serie %s no está en el almacén %s.';

  // Alta de series en una entrada de compra.
  STituloAltaSeries = 'Números de serie de la entrada';
  SCabeceraAltaSeries = '%s  %s';
  SIndicacionAltaSeries =
    'Lea con la pistola o pegue una serie por línea.';
  SContadorAltaSeries = 'Leídas: %d de %d';
  SContadorAltaSeriesLibre = 'Leídas: %d';
  SCaptionImprimirEtiquetasSeries =
    'Imprimir una etiqueta por unidad al aceptar';
  SErrorAltaSeriesVacia = 'No se ha leído ninguna serie.';
  SErrorAltaSeriesCantidad =
    'Se han leído %d series y la línea tiene %d unidades.';
  SErrorAltaSeriesDuplicadas = 'Series repetidas en la lista: %s.';
  SErrorAltaSeriesInvalidas =
    'Series no válidas (más de %d caracteres o caracteres que no se ' +
    'pueden imprimir en el código de barras): %s.';
  SErrorAltaSeriesEnDocumento =
    'Series ya usadas en otra línea del documento: %s.';
  SErrorAltaSeriesOtroArticulo =
    'La serie %s ya existe en el artículo %s.';
  SErrorAltaSeriesEnStock =
    'La serie %s ya está en stock en el almacén %s.';

  // Ficha de artículo (F-LOTEC-011).
  SCaptionGrupoTrazabilidad = 'Trazabilidad';
  SCaptionModoNinguna = 'Sin trazabilidad';
  SCaptionModoLote = 'Lote y caducidad';
  SCaptionModoSerie = 'Número de serie';
  SCaptionCaducidadObligatoria = 'Exigir fecha de caducidad';
  SCaptionDiasAvisoCaducidad = 'Días de aviso de caducidad:';
  SHintDiasAvisoCaducidad =
    'Vacío: los días del parámetro general de caducidades.';
  SErrorCambioModoConStockLote =
    'El artículo %s tiene existencias por lote o serie: no se puede ' +
    'pasar de «%s» a «%s». Regularice antes ese stock.';
  SCaptionColumnaLoteSerie = 'Lote / Serie';
  SCaptionPestanaLotesSeries = 'Lotes / Series';
  SCaptionColumnaSku = 'SKU';
  SCaptionColumnaAlmacen = 'Almacén';
  SCaptionColumnaEstadoLote = 'Estado';
  SEstadoLoteConExistencias = 'Con existencias';
  SEstadoLoteSinExistencias = 'Sin existencias';
  SEstadoLoteInactivo = 'Inactivo';
  SCaptionBotonHistoricoLote = '&Histórico';
  SCaptionBotonAltaManualLote = '&Alta manual';
  SAvisoArticuloSinTrazabilidad =
    'El artículo no lleva lote ni serie.';
  SAvisoElijaLoteHistorico = 'Elija un lote o serie de la lista.';
  STituloAltaManualLote = 'Alta manual de lote';
  SPreguntaSkuAltaManual = 'SKU:';
  SPreguntaLoteAltaManual = 'Lote:';
  SPreguntaCaducidadAltaManual = 'Caducidad (dd/mm/aaaa):';
  SErrorSkuNoEsDelArticulo = 'El SKU %s no es de este artículo.';
  SErrorCaducidadAltaManual = 'La fecha de caducidad «%s» no es válida.';
  SErrorCaducidadObligatoriaAltaManual =
    'Este artículo exige fecha de caducidad: indíquela.';
  SPreguntaCaducidadObligatoriaAltaManual =
    'Caducidad (dd/mm/aaaa, obligatoria):';
  SErrorLoteVacioAltaManual = 'Indique el lote.';
  SErrorSerieOtroArticuloAltaManual =
    'La serie %s ya existe en otro artículo.';
  SErrorSerieEnStockAltaManual = 'La serie %s ya está en stock.';
  SResumenAltaManualLotes = 'Altas: %d. Ya existían: %d.';

  // Líneas de documentos (F-LOTEC-013 y siguientes).
  SErrorLineaFaltaLote = 'Indique el lote o la serie de %s.';
  SErrorLineaLoteSobrante = '%s no lleva lote: quite «%s».';
  SErrorLoteCaducidadContradictoria =
    'El lote %s ya caduca el %s. Corrija la caducidad o indique otro lote.';
  SErrorLineaFaltaCaducidad =
    'Indique la fecha de caducidad del lote %s de %s.';
  SErrorLineaCantidadSerie =
    '%s lleva número de serie: cada línea es una sola unidad.';

  SAvisoAlbaranSesionLineasSinLote =
    'El albarán %s/%s tiene %d líneas de artículos con lote o serie sin ' +
    'indicar: ábralo y complételas (hasta entonces su stock va sin lote).';

  // Histórico de un lote o serie.
  STituloHistoricoLote = 'Histórico de %s';
  SCaptionColumnaFechaMov = 'Fecha';
  SCaptionColumnaDocumentoMov = 'Documento';
  SCaptionColumnaTipoMov = 'Tipo';
  SCaptionColumnaCantidadMov = 'Cantidad';
  SCaptionColumnaTerceroMov = 'Cliente / proveedor';
  SCaptionBotonCerrarHistorico = '&Cerrar (ESC)';
  SAvisoHistoricoVacio = 'Sin movimientos de este lote o serie.';

  // Lectura de un artículo trazable (lector, caja).
  SErrorSerieRepetidaDocumento =
    'La serie %s ya está en otra línea del documento.';
  // FZ-ISSUE-327
  SConfirmarMenosUnidadesLoteLinea =
    'Has elegido %s de %s unidades de %s. La línea se quedará con %0:s ' +
    'unidades. ¿Continuar?';
  SErrorLoteLeidoInexistente =
    'El lote %s no existe para %s.';
  SErrorLoteLeidoDemasiadoLargo =
    'El lote o serie leído (%s) tiene más de %d caracteres.';
  SAvisoLoteSinStockSuficiente =
    'El lote %s no tiene existencias suficientes en el almacén (quedan %s).';
  SAvisoLoteLeidoCaducado = 'El lote %s está caducado (%s).';
  SAvisoLoteSinCaducidad =
    'El lote %s no trae fecha de caducidad: indíquela en la línea.';

  // Envío de un documento de trabajo (F-LOTEC-016).
  SErrorEnvioLineasSinLote =
    'No se puede enviar: estas líneas no tienen el lote, la serie o la ' +
    'caducidad que piden sus artículos.';
  SErrorLineaNumeroLote = 'Línea %s: %s';
  SErrorLineaCaducidadFueraDeRango =
    'La fecha de caducidad del lote %s de %s no es válida: tiene que ' +
    'estar entre 2000 y 2199.';
  SErrorMasLineasSinLote = '... y %d líneas más.';

  // Recepción de un pedido de compra (FZ-ISSUE-434).
  SErrorRecepcionPedidoLineasSinLote =
    'No se puede dar entrada a la mercancía: estas líneas del pedido no ' +
    'tienen el lote, la serie o la caducidad que piden sus artículos.';
  STituloLoteRecepcionPedido = 'Lote de %s (%s)';
  SPreguntaLoteRecepcionPedido = 'Lote:';

  // Descripción impresa de la línea de factura (F-LOTEC-016).
  SEtiquetaImpresionLote = 'Lote:';
  SEtiquetaImpresionSerie = 'N.º de serie:';
  SEtiquetaImpresionCaducidad = 'Cad.:';

implementation

end.
