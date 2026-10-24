{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgProcesosAuxiliaresBBDD                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de Operaciones auxiliares de tablas, vistas y procedimientos       }
{    almacenados (FZ-ISSUE-566).                                               }
{******************************************************************************}
unit inLibMsgProcesosAuxiliaresBBDD;

interface

resourcestring
  SCaptionProcesosAuxiliaresBBDD =
    'Operaciones auxiliares tablas, vistas y procedimientos almacenados';
  SCaptionTipoObjetoProcesosAuxiliaresBBDD =
    'Tipo de objeto de base de datos';
  SCaptionTablasProcesosAuxiliaresBBDD = '&Tablas';
  SCaptionVistasProcesosAuxiliaresBBDD = '&Vistas';
  SCaptionProcedimientosProcesosAuxiliaresBBDD =
    '&Procedimientos almacenados';
  SCaptionObjetosDisponiblesProcesosAuxiliaresBBDD =
    'Objetos disponibles';
  SCaptionBuscarObjetosProcesosAuxiliaresBBDD = '&Buscar por nombre:';
  SAyudaBuscarObjetosProcesosAuxiliaresBBDD =
    'Busque por cualquier parte del nombre; por ejemplo, fac.';
  SAyudaSeleccionProcesosAuxiliaresBBDD =
    'Use Ctrl o Mayús para seleccionar varios objetos.';
  SCaptionMetadatosSqlProcesosAuxiliaresBBDD = '&Metadatos SQL';
  SCaptionMetadatosSqlObjetoProcesosAuxiliaresBBDD =
    '&Metadatos SQL - %s';
  SCaptionResultadoProcesosAuxiliaresBBDD = '&Resultado';
  SCaptionExportarExcelProcesosAuxiliaresBBDD = 'Exportar a E&xcel';
  SCaptionPlanEjecucionProcesosAuxiliaresBBDD = '&Plan de ejecución';
  SCaptionPlanEjecucionObjetoProcesosAuxiliaresBBDD =
    '&Plan de ejecución - %s';
  SCaptionPlanConsultasObjetoProcesosAuxiliaresBBDD =
    '&Plan de consultas de %s';
  SAyudaPlanProcesosAuxiliaresBBDD =
    'Revise la SELECT que se analizará. El plan estimado no ejecuta la ' +
    'consulta; Medir ejecución sí la ejecuta y muestra tiempos reales.';
  SCaptionPlanEstimadoProcesosAuxiliaresBBDD = 'Plan &estimado';
  SCaptionMedirEjecucionProcesosAuxiliaresBBDD =
    '&Medir ejecución (ms)';
  SCaptionPlanExplicadoProcesosAuxiliaresBBDD = 'Plan &explicado';
  SCaptionJsonOriginalProcesosAuxiliaresBBDD = '&JSON original';
  SCaptionNodoPlanProcesosAuxiliaresBBDD = 'Nodo / operación';
  SCaptionEnlacePlanProcesosAuxiliaresBBDD = 'Enlace desde el padre';
  SCaptionFilasEstimadasPlanProcesosAuxiliaresBBDD = 'Filas estimadas';
  SCaptionFilasRealesPlanProcesosAuxiliaresBBDD = 'Filas reales/bucle';
  SCaptionAccesoPlanProcesosAuxiliaresBBDD = 'Acceso / índice';
  SCaptionExplicacionPlanProcesosAuxiliaresBBDD = 'Qué hace el nodo';
  SCaptionOperacionesCompatiblesProcesosAuxiliaresBBDD =
    'Operaciones compatibles';
  SCaptionEjecutarOperacionProcesosAuxiliaresBBDD =
    'Ejecutar operación';
  SCaptionCopiarSqlProcesosAuxiliaresBBDD = '&Copiar SQL';
  SCaptionCerrarProcesosAuxiliaresBBDD = '&Cerrar';
  SResumenObjetosAdicionalesProcesosAuxiliaresBBDD = ' y %d más';
  SAccionVerMetadatosProcesosAuxiliaresBBDD = 'Ver metadatos';
  SAccionBloquearEdicionProcesosAuxiliaresBBDD =
    'Bloquear edición de tabla';
  SAccionEditarDatosProcesosAuxiliaresBBDD = 'Editar datos de tabla';
  SAccionVerEstadoProcesosAuxiliaresBBDD = 'Ver estado y tamaño';
  SAccionVerDependenciasProcesosAuxiliaresBBDD = 'Ver dependencias';
  SAccionAnalizarEstadisticasProcesosAuxiliaresBBDD =
    'Analizar estadísticas';
  SAccionComprobarIntegridadProcesosAuxiliaresBBDD =
    'Comprobar integridad';
  SAccionRegenerarTablaProcesosAuxiliaresBBDD = 'Regenerar tabla';
  SAccionRegenerarIndicesProcesosAuxiliaresBBDD = 'Regenerar índices';
  SAccionExportarDdlProcesosAuxiliaresBBDD =
    'Exportar DDL seleccionado';
  SAccionCalcularChecksumProcesosAuxiliaresBBDD = 'Calcular checksum';
  SAccionVaciarTablaProcesosAuxiliaresBBDD = 'Vaciar tabla';
  SAccionBorrarTablaProcesosAuxiliaresBBDD = 'Borrar tabla';
  SAccionVerDatosVistaProcesosAuxiliaresBBDD =
    'Ver datos / ejecutar vista';
  SAccionVerPlanProcesosAuxiliaresBBDD = 'Ver plan de ejecución';
  SAccionRegenerarVistaProcesosAuxiliaresBBDD = 'Regenerar vista';
  SAccionEjecutarProcedimientoProcesosAuxiliaresBBDD =
    'Ejecutar procedimiento';
  SAccionRegenerarProcedimientoProcesosAuxiliaresBBDD =
    'Regenerar procedimiento';
  SAccionRefrescarMetadatosProcesosAuxiliaresBBDD =
    'Refrescar metadatos';
  SCaptionProcedimientoPlanProcesosAuxiliaresBBDD =
    'Procedimiento almacenado';
  SCaptionSinEjecutarCallProcesosAuxiliaresBBDD = 'Sin ejecutar CALL';
  SAyudaPlanVistaProcesosAuxiliaresBBDD =
    'Revise la SELECT que usa la vista. El plan estimado no ejecuta la ' +
    'consulta. Medir ejecución sí la ejecuta, descarta las filas y ' +
    'muestra milisegundos inclusivos por nodo.';
  SAyudaPlanProcedimientoProcesosAuxiliaresBBDD =
    'MariaDB no admite EXPLAIN CALL. Se muestra una SELECT interna que ' +
    'puede editar: sustituya parámetros y variables locales por valores ' +
    'reales. Nunca se ejecutará el procedimiento completo desde aquí.';
  SAvisoSinSelectProcedimientoProcesosAuxiliaresBBDD =
    'No se ha encontrado una SELECT interna aislable. Pegue en el ' +
    'editor una SELECT concreta del procedimiento para analizarla.';
  SAvisoRevisarSelectProcedimientoProcesosAuxiliaresBBDD =
    'Revise la SELECT extraída y sustituya sus parámetros o variables ' +
    'locales antes de obtener el plan.';
  SErrorIndicarSelectPlanProcesosAuxiliaresBBDD =
    'Indique una sentencia SELECT para obtener su plan.';
  SEnlaceInicioPlanProcesosAuxiliaresBBDD = 'Inicio del plan';
  SEnlacePadreNodoPlanProcesosAuxiliaresBBDD = 'Padre → nodo';
  SEnlaceTiempoPlanProcesosAuxiliaresBBDD = ' · %s ms inclusivos';
  SEnlacePorcentajePlanProcesosAuxiliaresBBDD = ' · %s%% del total';
  SEnlaceEstimadoPlanProcesosAuxiliaresBBDD =
    ' · estimado, sin ms reales';
  SEnlaceSinTiempoPlanProcesosAuxiliaresBBDD =
    ' · sin tiempo informado';
  SEnlaceBuclesPlanProcesosAuxiliaresBBDD = ' · %s bucles';
  SAccesoIndicePlanProcesosAuxiliaresBBDD = 'índice %s';
  SAyudaPlanMedidoProcesosAuxiliaresBBDD =
    'Plan medido: los milisegundos de cada enlace son inclusivos; ' +
    'contienen el trabajo de sus nodos descendientes. MariaDB ha ' +
    'ejecutado la SELECT y ha descartado sus filas.';
  SAyudaPlanEstimadoProcesosAuxiliaresBBDD =
    'Plan estimado: muestra el recorrido previsto, sin ejecutar la ' +
    'SELECT. Pulse Medir ejecución para obtener milisegundos reales.';
  SErrorObtenerPlanProcesosAuxiliaresBBDD =
    'No se ha podido obtener el plan de ejecución:%s%s';
  SCaptionDdlSeleccionadoProcesosAuxiliaresBBDD = '&DDL seleccionado';
  SFiltroScriptSqlProcesosAuxiliaresBBDD = 'Script SQL (*.sql)|*.sql';
  SConfirmarRegenerarProcedimientosProcesosAuxiliaresBBDD =
    'Se regenerarán estos procedimientos: %s.';
  SAdvertenciaRegenerarProcedimientosProcesosAuxiliaresBBDD =
    'Se volverá a aplicar la definición actual de cada procedimiento.';
  SInfoProcedimientosRegeneradosProcesosAuxiliaresBBDD =
    'Procedimientos regenerados correctamente.';
  SConfirmarAnalizarTablasProcesosAuxiliaresBBDD =
    'Se analizarán estas tablas: %s.';
  SAdvertenciaAnalizarTablasProcesosAuxiliaresBBDD =
    'La operación puede tardar en tablas grandes.';
  STituloAnalisisEstadisticasProcesosAuxiliaresBBDD =
    'análisis de estadísticas';
  SConfirmarComprobarObjetosProcesosAuxiliaresBBDD =
    'Se comprobarán estos objetos: %s.';
  SAdvertenciaComprobarObjetosProcesosAuxiliaresBBDD =
    'La comprobación puede bloquear objetos mientras se ejecuta.';
  STituloComprobacionIntegridadProcesosAuxiliaresBBDD =
    'comprobación de integridad';
  STituloEstadoObjetoProcesosAuxiliaresBBDD = 'estado de %s';
  STituloDependenciasObjetoProcesosAuxiliaresBBDD = 'dependencias de %s';
  SConfirmarCalcularChecksumProcesosAuxiliaresBBDD =
    'Se calculará el checksum de: %s.';
  SAdvertenciaCalcularChecksumProcesosAuxiliaresBBDD =
    'Puede requerir leer por completo las tablas seleccionadas.';
  STituloChecksumProcesosAuxiliaresBBDD = 'checksum';
  SConfirmarRegenerarVistasProcesosAuxiliaresBBDD =
    'Se regenerarán estas vistas: %s.';
  SAdvertenciaRegenerarVistasProcesosAuxiliaresBBDD =
    'Se volverá a aplicar la definición actual de cada vista.';
  SInfoVistasRegeneradasProcesosAuxiliaresBBDD =
    'Vistas regeneradas correctamente.';
  SErrorServicioCopiaProcesosAuxiliaresBBDD =
    'No está disponible el servicio de copia de seguridad.';
  SAvisoCopiaPreviaProcesosAuxiliaresBBDD =
    'Antes de continuar se solicitará una copia de seguridad completa.';
  SConfirmarContinuarProcesosAuxiliaresBBDD = '¿Desea continuar?';
  SConfirmarRegenerarTablasProcesosAuxiliaresBBDD =
    'Se regenerarán estas tablas: %s.';
  SConfirmarRegenerarIndicesProcesosAuxiliaresBBDD =
    'Se regenerarán los índices de estas tablas: %s.';
  SAdvertenciaBloqueoTablasProcesosAuxiliaresBBDD =
    'La operación puede bloquear las tablas y tardar varios minutos.';
  SConfirmarVaciarTablasProcesosAuxiliaresBBDD =
    'Se vaciarán estas tablas: %s.';
  SAdvertenciaVaciarTablasProcesosAuxiliaresBBDD =
    'Se eliminarán todos sus registros y no se puede deshacer.';
  SConfirmarBorrarTablasProcesosAuxiliaresBBDD =
    'Se borrarán estas tablas: %s.';
  SAdvertenciaBorrarTablasProcesosAuxiliaresBBDD =
    'Se eliminarán las tablas, sus datos y su estructura.';
  SInfoOperacionFinalizadaProcesosAuxiliaresBBDD =
    'Operación finalizada correctamente.';
  STituloEjecutarProcedimientoProcesosAuxiliaresBBDD =
    'Ejecutar procedimiento almacenado';
  SPromptEjecutarProcedimientoProcesosAuxiliaresBBDD =
    'Revise la llamada e indique los valores de los parámetros:';
  SNombreArchivoExcelProcesosAuxiliaresBBDD =
    'Procesos_auxiliares_BBDD';
  SConfirmarPlanMedidoProcesosAuxiliaresBBDD =
    'Para medir tiempos reales, MariaDB ejecutará la SELECT y ' +
    'descartará sus filas.%s%sRevísela con cuidado: una SELECT puede ' +
    'invocar funciones almacenadas con efectos laterales.%s%sLa ' +
    'ejecución se limitará a %d segundos. ¿Desea continuar?';

implementation

end.
