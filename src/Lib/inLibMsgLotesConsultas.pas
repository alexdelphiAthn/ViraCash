{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgLotesConsultas                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de las consultas de trazabilidad (F-LOTEC-018): «Lotes y           }
{    caducidades», «Buscar serie» y aviso de         }
{    caducidades al arrancar.                                                  }
{******************************************************************************}
unit inLibMsgLotesConsultas;

interface

resourcestring
  // Lotes y caducidades.
  STituloLotesCaducidades = 'Lotes y caducidades';
  SCaptionLotesAlmacen = 'Almacén:';
  SCaptionLotesTodosAlmacenes = '(todos)';
  SCaptionLotesFiltro = 'Mostrar:';
  SCaptionLotesFiltroTodo = 'Todo el stock con lote';
  SCaptionLotesFiltroCaducados = 'Solo caducados';
  SCaptionLotesFiltroProximos = 'Caducados y próximos a caducar';
  SCaptionLotesDias = 'Días:';
  SHintLotesDias =
    'Plazo para «próximos a caducar». Vacío o 0: los días de aviso de ' +
    'cada artículo o, si no tiene, los del parámetro general.';
  SCaptionLotesTipo = 'Tipo:';
  SCaptionLotesTipoTodos = 'Todos';
  SCaptionLotesTipoLotes = 'Lotes';
  SCaptionLotesTipoSeries = 'Series';
  SCaptionLotesArticulo = 'Artículo:';
  SCaptionLotesRefrescar = 'Refrescar';
  SCaptionLotesExcel = 'Excel';
  SCaptionLotesImprimir = 'Imprimir';
  SCaptionColLotesAlmacen = 'Almacén';
  SCaptionColLotesArticulo = 'Artículo';
  SCaptionColLotesDescripcion = 'Descripción';
  SCaptionColLotesFamilia = 'Familia';
  SCaptionColLotesSku = 'SKU';
  SCaptionColLotesLote = 'Lote / serie';
  SCaptionColLotesTipo = 'Tipo';
  SCaptionColLotesCaducidad = 'Caducidad';
  SCaptionColLotesDias = 'Días';
  SCaptionColLotesCaducado = 'Caducado';
  SCaptionColLotesEntrada = 'Entrada';
  SCaptionColLotesAntiguedad = 'Días desde entrada';
  SCaptionColLotesProveedor = 'Proveedor';
  SCaptionColLotesCantidad = 'Cantidad';
  SCaptionColLotesValor = 'Valor';
  SNombreArchivoLotes = 'lotes_caducidades_%s';

  // Buscar serie.
  STituloBuscarSerie = 'Buscar serie';
  SCaptionBuscarSerie = 'Nº de serie / lote:';
  SCaptionBuscarSerieBoton = 'Buscar';
  SCaptionBuscarSerieHistorico = 'Movimientos';
  SCaptionBuscarSerieReclamaciones = 'Reclamaciones de garantía';
  SInfoSerieNoEncontrada = 'No se encuentra «%s» en el catálogo de lotes ' +
    'y series.';
  SResumenSerieArticulo = '%s · %s (%s)';
  SResumenSerieEnStock = 'En stock en el almacén %s.';
  SResumenSerieSinStock = 'Sin stock: vendida, devuelta o regularizada.';
  SResumenSerieVendida = 'Vendida el %s a %s (%s).';
  SResumenSerieDevuelta = 'Devuelta por el cliente después de la venta.';
  SResumenSerieGarantiaHasta = 'Garantía hasta el %s (%s).';
  SResumenSerieEnGarantia = 'en garantía';
  SResumenSerieFueraGarantia = 'fuera de garantía';
  SResumenSerieReclamaciones = 'Reclamaciones abiertas: %d.';
  SResumenSerieSinExistencias = 'Sin existencias: no consta ninguna ' +
    'entrada.';
  // Origen de la entrada: se omite lo que no consta (alta manual).
  SResumenSerieOrigen = 'Entrada: %s del %s, proveedor %s.';
  SResumenSerieOrigenSinProveedor = 'Entrada: %s del %s.';
  SResumenSerieEntradaProveedor = 'Entrada del %s, proveedor %s.';
  SResumenSerieEntradaSinDocumento = 'Entrada del %s.';
  SResumenSerieVariosArticulos =
    'El código está en %d artículos; se muestra el primero.';
  SCaptionColHistFecha = 'Fecha';
  SCaptionColHistDocumento = 'Documento';
  SCaptionColHistAlmacen = 'Almacén';
  SCaptionColHistContra = 'Contrapartida';
  SCaptionColHistTipo = 'E/S';
  SCaptionColHistCantidad = 'Cantidad';
  SCaptionColHistCliente = 'Cliente';
  SCaptionColHistProveedor = 'Proveedor';
  SCaptionColHistSerieDoc = 'Serie';
  SCaptionColHistNumeroDoc = 'Número';
  SCaptionColHistSerieFactura = 'Serie factura sustituta';
  SCaptionColHistNumeroFactura = 'Nº factura sustituta';
  SCaptionColReclamacion = 'Nº';
  SCaptionColReclamacionEstado = 'Estado';
  SCaptionColReclamacionResolucion = 'Resolución';
  SCaptionColReclamacionSustituta = 'Serie entregada';
  SCaptionColReclamacionMotivo = 'Motivo';

  // Aviso al arrancar.
  SAvisoCaducidadesArranque =
    'Caducidades: %d lotes con stock ya caducados y %d que caducan en ' +
    'el plazo de aviso. Consulte Almacén > Lotes y caducidades.';

  // Etiquetas por lote y por unidad (F-LOTEC-022).
  SEtiquetaLote = 'Lote %s';
  // Corto: cabe en el memo de 150 px del diseño original con el lote
  // (Arial 11 px, medido con GDI; FZ-ISSUE-300).
  SEtiquetaCaducidad = ' cad. %s';
  SEtiquetaSerie = 'S/N %s';
  SCaptionBotonEtiquetaLote = 'Etiquetas';
  STituloEtiquetasLote = 'Etiquetas de %s';

  // Consulta de stock.
  SCaptionStockPorLote = 'Por lote';

implementation

end.
