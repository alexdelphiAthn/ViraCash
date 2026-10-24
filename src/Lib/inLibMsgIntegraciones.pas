{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgIntegraciones                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de servicios externos, nube y ventas web.                        }
{******************************************************************************}
unit inLibMsgIntegraciones;

interface

resourcestring
  SErrorPendientesOtraBase =
    'Los scripts guardados pertenecen a otra base de datos o no tienen ' +
    'identificado su destino. Use Comprobar actualizaciones para ' +
    'calcular lo que necesita la base abierta.';
  SColaEsperandoPrimerCiclo = 'Cola activada. Esperando el primer ciclo.';
  SColaSinIncidencias =
    'Comprobación terminada sin incidencias en las últimas %d horas.';
  SColaIncidenciaGuardada = '%s - Registro %s: %s';
  SColaWsSinConfiguracion =
    'Falta URL, API key o referencia de instalación.';
  SColaEnviandoRegistro = 'Enviando registro %d.';
  SColaRegistroEnviado = 'Registro %d enviado correctamente.';
  SColaErrorRegistro = 'Registro %d: %s';
  SColaHaciendaNoDisponible =
    'El cliente de envío a la AEAT no está disponible.';
  SColaHaciendaAceptada = 'Registro %d aceptado por la AEAT (%s).';
  SColaHintEstado = '%s (últimas %d horas): %s';
  SColaHintUltimoEvento = 'Último evento (%s): %s';
  SColaHintIncidencia = 'Incidencia pendiente: %s';
  SColaHintAbrir = 'Doble clic para abrir la cola.';
  SColaEstadoCorrecto = 'Todo va bien';
  SColaEstadoOcupado = 'Ocupado';
  SColaEstadoIncidencia = 'Errores o incidencias';
  SColaNombreWs = 'wsWeb';
  SColaNombreHacienda = 'Hacienda (AEAT)';
  SColaNombrePrestaShop = 'PrestaShop';
  // FZ-ISSUE-310: botón «Enviar ya» de las pantallas de cola
  SConfirmarEnviarYaCola =
    'Se enviarán ahora %d filas pendientes o con error. Las filas con ' +
    'error vuelven a pendientes y las enviadas o en proceso no se ' +
    'tocan. ¿Continuar?';
  SInfoEnviarYaColaSinFilas =
    'No hay filas pendientes ni con error que enviar.';
  SErrorDivisaNoEncontrada =
    'Divisa "%s" no encontrada en el resultado';
  SErrorHttpDivisas = 'HTTP %d: %s';
  SErrorRedDivisas = 'Error de red: %s';
  SErrorJsonDivisas = 'Respuesta JSON inválida';
  SErrorPruebaPilaJcl =
    'Prueba forzada con /teststack [%s]: JCL stack trace activo';
  SErrorHttpCripto = 'HTTP %d: %s';
  SErrorRedCripto = 'Error de red: %s';
  SErrorJsonCripto = 'Respuesta JSON inválida';
  SErrorRespuestaHttpViraCashApi = 'Respuesta HTTP %d';
  SErrorViraCashApiNoConfigurada =
    'La API de ViraCash no está configurada.';
  SErrorEnvioViraCashApiCancelado =
    'Envío cancelado antes de recibir la respuesta del servidor.';
  SInfoEventoViraCashApiRecibido =
    'Evento recibido correctamente.';
  SInfoConsultaViraCashApiRealizada =
    'Consulta realizada correctamente.';
  SInfoDocumentoViraCashApiGuardado =
    'Documento guardado en %s';
  SInfoDocumentoViraCashApiDescargado =
    'Documento descargado.';
  SErrorRespuestaAjenaViraCashApi =
    'Respuesta HTTP %d no reconocida como de la API de ViraCash ' +
    '(redirección, servicio saturado o cuerpo no válido).';
  SErrorDescargaTraduccion =
    'No se pudo descargar la traducción: %s';
  SErrorPaqueteTraduccionInvalido =
    'El paquete de traducción no es válido: %s';
  SErrorConexionTraduccionNoDisponible =
    'No está disponible la conexión para instalar la traducción.';
  SErrorTraduccionTransaccionActiva =
    'No se puede instalar la traducción mientras hay una transacción activa.';
  SErrorTraduccionSinFilas =
    'El paquete no ha instalado ninguna traducción para %s.';
  SProgresoTraduccionPreparando =
    'Preparando la descarga de %s...';
  SProgresoTraduccionDescargando =
    'Descargando el paquete de traducción...';
  SProgresoTraduccionValidando =
    'Validando el manifiesto y las huellas SHA-256...';
  SProgresoTraduccionEjecutando =
    'Ejecutando %s (%d de %d)...';
  SProgresoTraduccionComprobando =
    'Comprobando el catálogo instalado...';
  SProgresoTraduccionDisponible =
    'La traducción ya está descargada y disponible.';
  SProgresoTraduccionAplicando =
    'Aplicando la traducción a la interfaz...';
  SProgresoTraduccionCompletada =
    'Traducción descargada y aplicada correctamente.';
  SErrorRespuestaFormateadorSqlVacia =
    'Respuesta vacía del servicio de formateo SQL';
  SErrorRespuestaFormateadorSqlInesperada =
    'Respuesta JSON inesperada del formateador SQL';
  SErrorEncolarVentaWebservice =
    'No se pudo encolar la venta %s\%s para el webservice.';
  SErrorVentasWsJsonNoRegistrado =
    'El serializador JSON de ventas no está registrado.';
  SErrorVentasWsColaNoRegistrada =
    'La persistencia de la cola de ventas no está registrada.';
  SErrorApiKeyInstalacionFaltante =
    'Falta la API key de la instalación.';
  SErrorDeclaracionWebserviceOtraVersion =
    'El webservice devolvió una declaración de otra versión.';
  // R10 - Importación de pedidos PrestaShop
  SCaptionConectandoPrestaShop = 'Conectando con PrestaShop...';
  SCaptionRecuperadosPedidos = 'Recuperados %d pedidos';
  SCaptionNoRecuperadosPedidos = 'No se pudieron recuperar pedidos';
  SCaptionImportandoPedido = 'Importando %s...';
  SCaptionErrorImportandoPedido = 'Error en %s: %s';
  SCaptionSinPedidosNuevosPrestaShop =
    'No hay pedidos nuevos desde la última importación';
  SErrorPrestaShopHttp = 'PrestaShop respondió HTTP %d a %s';
  // R11 - Actualizacion de la aplicacion
  SErrorActualizacionesNoConfiguradas =
    'El servicio de actualizaciones no está configurado.';
  SErrorRespuestaActualizacionNoValida =
    'El servicio de actualizaciones devolvió una respuesta no válida.';
  SErrorServidorActualizacionHttp =
    'El servidor de actualizaciones respondió HTTP %d.';
  SErrorTamanoActualizacionNoCoincide =
    'El tamaño de la descarga no coincide con el publicado.';
  SErrorHuellaActualizacionNoCoincide =
    'La huella SHA-256 de la descarga no coincide con la publicada.';
  SErrorEntradaActualizacionNoDeclarada =
    'La versión publicada no declara ese fichero.';
  SErrorEntradaZipActualizacionAusente =
    'El paquete comprimido no contiene %s.';
  SErrorZipActualizacionConVariasEntradas =
    'El paquete comprimido contiene más de un fichero.';
  SErrorArchivoActualizacionNoEjecutable =
    'El archivo descargado no es un ejecutable válido.';
  SErrorArquitecturaActualizacionNoCoincide =
    'La actualización no corresponde a la arquitectura instalada.';
  SErrorEjecutableNuevoAusente =
    'No se encuentra el ejecutable descargado: %s';
  SErrorEjecutableAnteriorAusente =
    'No se conserva ningún ejecutable anterior de %s.';
  SErrorSitioEjecutableAnteriorOcupado =
    'No se pudo apartar el ejecutable actual: los nombres conservados ' +
    'están ocupados.';
  SErrorRenombrarEjecutableActual =
    'No se pudo renombrar el ejecutable actual: %s';
  SErrorCopiarEjecutableNuevo =
    'No se pudo copiar el nuevo ejecutable: %s';
  SErrorRestaurarEjecutableAnterior =
    'No se pudo devolver a su sitio el ejecutable anterior. Se conserva ' +
    'en: %s';
  SErrorConexionActualizacionNoDisponible =
    'No hay conexión con la base de datos para aplicar los scripts.';
  SErrorComprobacionScriptsVacia =
    'No se ha descargado la comprobación de scripts aplicados.';
  SErrorScriptActualizacionAusente =
    'No se encuentra el script descargado: %s';
  SErrorScriptActualizacionVacio =
    'El script descargado está vacío: %s';
  SErrorHuellaScriptActualizacionNoCoincide =
    'La huella SHA-256 del script no coincide con la publicada.';
  SInfoConsultandoActualizaciones =
    'Consultando si hay una versión nueva...';
  SInfoDescargandoActualizacion =
    'Descargando %s...';
  SInfoDescomprimiendoActualizacion =
    'Descomprimiendo %s...';
  SInfoComprobandoScriptsAplicados =
    'Comprobando qué scripts faltan en esta base de datos...';
  SInfoSinVersionesPublicadas =
    'El servicio todavía no ha publicado ninguna versión.';
  SInfoVersionInstaladaAlDia =
    'La versión instalada (%s) ya es la última publicada.';
  SInfoVersionAlDiaSinScripts =
    'La versión instalada (%s) ya es la última publicada y esta base de ' +
    'datos tiene aplicados todos sus scripts.';
  SInfoScriptsActualizacionAplazados =
    'Quedan %d scripts sin aplicar. Se ofrecerán en el siguiente ' +
    'arranque o desde Comprobar actualizaciones.';
  SInfoScriptsActualizacionCancelados =
    'Se ha cancelado la aplicación de scripts: quedan %d sin aplicar, ' +
    'que se ofrecerán en el siguiente arranque.';
  SInfoActualizacionInstalada =
    'La versión %s queda instalada y entrará en el siguiente arranque.';
  SInfoAplicandoScriptActualizacion =
    'Aplicando %s (%d de %d)...';
  SInfoRevirtiendoScriptActualizacion =
    'Revirtiendo %s...';
  SInfoSinScriptsPendientes =
    'No hay scripts pendientes de aplicar.';
  SInfoScriptsPendientesAplicados =
    'Los scripts pendientes se han aplicado correctamente.';
  SInfoActualizacionRevertida =
    'Se ha vuelto a la versión %s.';
  SErrorScriptFaltanteNoPublicado =
    'La base necesita %s, que la versión %s no publica.';
  SErrorAplicarScriptActualizacion =
    'No se pudo aplicar %s: %s';
  SErrorRevertirScriptActualizacion =
    'No se pudo revertir %s: %s';
  SErrorSinActualizacionRevertible =
    'No hay ninguna actualización que se pueda revertir.';
  STituloComprobarActualizaciones = 'Comprobar actualizaciones';
  STituloRevertirActualizacion = 'Revertir actualización';
  SDetalleActualizacionDisponible =
    'Hay una versión nueva de ViraCash.' + sLineBreak + sLineBreak +
    'Versión instalada: %s' + sLineBreak +
    'Versión disponible: %s' + sLineBreak +
    'Publicada: %s' + sLineBreak +
    'Tamaño del programa: %s bytes' + sLineBreak +
    'Se descargarán: %s bytes' + sLineBreak +
    'Programas auxiliares: %d' + sLineBreak + sLineBreak +
    'Novedades:' + sLineBreak + '%s';
  SPreguntaInstalarActualizacionArranque =
    '¿Descargar e instalar la versión %s?' + sLineBreak + sLineBreak +
    'ViraCash se cerrará al terminar. Vuelva a abrirlo para usar la ' +
    'versión nueva y actualizar la base de datos antes de entrar.';
  SPreguntaInstalarActualizacion =
    '¿Descargar e instalar la versión %s?' + sLineBreak + sLineBreak +
    'El programa en curso seguirá funcionando; la versión nueva entrará ' +
    'la próxima vez que se abra ViraCash. El ejecutable actual se ' +
    'conserva con un guion bajo delante por si hay que volver atrás.';
  SDetalleScriptsFaltantes =
    'Esta base de datos necesita los siguientes cambios de esquema, en ' +
    'este orden:';
  SLineaScriptFaltante = '  %d  %s  (%s)';
  SPreguntaAplicarScriptsAhora =
    'Faltan %d scripts por aplicar en la base de datos.' +
    sLineBreak + sLineBreak +
    'Aplicarlos ahora puede llevar bastante tiempo y, al terminar, hay ' +
    'que salir obligatoriamente del programa y volver a abrirlo con la ' +
    'versión nueva.' + sLineBreak + sLineBreak +
    '¿Aplicarlos ahora? Si responde No quedarán guardados y se ' +
    'ofrecerán en el siguiente arranque.';
  SPreguntaAplicarScriptsAhoraMismaVersion =
    'Faltan %d scripts por aplicar en la base de datos.' +
    sLineBreak + sLineBreak +
    'No hay ninguna versión nueva del programa que instalar: es la base ' +
    'de datos la que se pone al día, y hacerlo puede llevar bastante ' +
    'tiempo.' + sLineBreak + sLineBreak +
    '¿Aplicarlos ahora? Si responde No quedarán guardados y se ' +
    'ofrecerán en el siguiente arranque.';
  STituloProcesoScriptsActualizacion =
    'Scripts de la base de datos';
  SFaseAplicandoScriptsActualizacion =
    'Aplicando los scripts que faltan en la base de datos...';
  SPreguntaModoActualizacionBBDD =
    'Faltan %d scripts por aplicar en la base de datos. Hay dos formas ' +
    'de ponerla al día:' + sLineBreak + sLineBreak +
    '- Por scripts: se aplican los que faltan, uno detrás de otro, ' +
    'respetando lo que cada uno necesita que esté antes.' + sLineBreak +
    '- Por comparación: DBComparer compara la base con el modelo de la ' +
    'versión %s y genera un único script con los cambios de tablas, ' +
    'vistas y procedimientos, en el dialecto de este servidor. Después ' +
    'se aplican los scripts que sigan faltando (los de datos).' +
    sLineBreak + sLineBreak +
    'Las dos pueden llevar bastante tiempo.%s';
  SAvisoSalirTrasScripts =
    ' Al terminar hay que salir del programa y volver a abrirlo con la ' +
    'versión nueva.';
  SBotonActualizarPorScripts = 'Por scripts';
  SBotonActualizarPorComparacion = 'Por comparación';
  SBotonActualizarMasTarde = 'Más tarde';
  SFaseDescargandoComparacion =
    'Descargando el modelo de la versión y el comparador...';
  SFaseGenerandoComparacion =
    'Comparando la base de datos con el modelo de la versión...';
  SErrorComparacionNoPublicada =
    'La versión %s no trae modelo para actualizar por comparación.';
  SErrorComparadorActualizacion =
    'DBComparer no ha podido generar el script (código %d).' +
    sLineBreak + sLineBreak + '%s';
  SErrorComparadorActualizacionNoArranca =
    'No se ha podido ejecutar el comparador %s: %s';
  SErrorConversionScriptActualizacion =
    'DBComparer no ha podido convertir el script %s al motor de la base ' +
    'de datos (código %d).' + sLineBreak + sLineBreak + '%s';
  SErrorConversionSinComparador =
    'La base de datos es %s y los scripts de la versión %s están escritos ' +
    'para MariaDB 12.13: hay que convertirlos con DBComparer, pero la ' +
    'versión no lo trae.';
  SFaseConvirtiendoScriptsActualizacion =
    'Convirtiendo los scripts a %s...';
  SAvisoMotorDistintoServidor =
    'El parámetro «Motor de la base de datos» dice %s, pero el servidor ' +
    'responde «%s», que es %s.' + sLineBreak + sLineBreak +
    'Los scripts de la actualización se convierten según ese parámetro: ' +
    'con el motor equivocado pueden fallar o dejar la base a medias.';
  SPreguntaCambiarMotorServidor =
    '¿Cambiar el parámetro a %s para todos los usuarios y seguir con la ' +
    'actualización?';
  SPreguntaMotorSoloAdministrador =
    'Solo un administrador puede cambiar el parámetro. ¿Seguir con %s de ' +
    'todas formas?';
  SAvisoMotorNoAdmitido =
    'El servidor responde «%s», que no es ninguno de los motores ' +
    'admitidos (MariaDB 12.13, MariaDB 10.14 o MySQL 8.0.41).' +
    sLineBreak + sLineBreak +
    'La actualización se hará con el parámetro «Motor de la base de ' +
    'datos», que dice %s. ¿Seguir?';
  SAvisoMotorValorPropioUsuario =
    'El parámetro se ha guardado para todos, pero su usuario o su grupo ' +
    'tiene un valor propio que manda sobre ése (%s). Revíselo en ' +
    'Parámetros. Esta actualización se hará con %s.';
  SBotonCambiarMotorBaseDatos = 'Cambiar a %s';
  SBotonSeguirConMotorBaseDatos = 'Seguir con %s';
  SBotonCancelarActualizacionMotor = 'Cancelar';
  SInfoActualizacionCanceladaMotor =
    'Actualización cancelada. Revise el parámetro «Motor de la base de ' +
    'datos» (Base de datos) antes de volver a intentarlo.';
  SDetalleScriptComparacion =
    'Script generado por comparación con el modelo de la versión %s.' +
    sLineBreak + sLineBreak + '%s' + sLineBreak + sLineBreak +
    '----------------------------------------' + sLineBreak + '%s';
  SPreguntaAplicarScriptComparacion =
    '¿Aplicar a la base de datos el script generado por comparación?';
  SPreguntaAplicarScriptComparacionConAvisos =
    'DBComparer ha dejado avisos: hay construcciones sin equivalente en ' +
    'este servidor y conviene revisarlas.' + sLineBreak + sLineBreak +
    '¿Aplicar el script igualmente?';
  SInfoComparacionNoAplicada =
    'No se ha aplicado el script de comparación. Los scripts que faltan ' +
    'siguen pendientes.';
  SAvisoTextoScriptRecortado =
    '[...] El script sigue: aquí solo se ve el principio.';
  SFaseDescargandoVersionActualizacion =
    'Descargando la versión nueva...';
  SFaseDescargandoScriptsActualizacion =
    'Descargando los scripts que faltan...';
  SInfoComprobacionScriptsCancelada =
    'Se ha cancelado la comprobación de los scripts de la base de datos. ' +
    'No se ha cambiado nada.';
  SAvisoCopiaPreviaObligatoria =
    'Antes de tocar la base de datos se hace una copia de seguridad. ' +
    'Elija dónde guardarla: es lo que permitirá revertir los cambios ' +
    'que no tengan script de reversión.';
  SErrorAnfitrionCopiaPreviaNoDisponible =
    'No está disponible el servicio de copias de seguridad.';
  SDetalleReversionActualizacion =
    'Se va a deshacer la actualización.' + sLineBreak + sLineBreak +
    'Versión instalada: %s' + sLineBreak +
    'Se volverá a: %s' + sLineBreak +
    'Aplicada el: %s' + sLineBreak +
    'Ejecutables sustituidos: %d' + sLineBreak +
    'Scripts aplicados: %d';
  SLineaScriptRevertible = '  %s  [%s]  %s';
  SLineaCopiaPreviaReversion = 'Copia previa: %s';
  SPreguntaRevertirActualizacion =
    '¿Volver a la versión %s?' + sLineBreak + sLineBreak +
    'Se revertirán los scripts que tengan reversión y se devolverá el ' +
    'ejecutable anterior a su sitio. Al terminar hay que salir del ' +
    'programa.';
  SDetalleScriptsSinRollback =
    'Estos scripts se aplicaron y no traen script de reversión, así que ' +
    'sus cambios siguen en la base de datos:';
  SPreguntaRestaurarCopiaPrevia =
    '¿Restaurar la copia de seguridad previa?' + sLineBreak + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Se perderá todo lo introducido desde que se hizo esa copia.';
  SAvisoSinCopiaPreviaParaRevertir =
    'No se conserva la copia previa, así que esos cambios no se pueden ' +
    'deshacer automáticamente.';
  SInfoProcesoActualizacionTerminado = 'Proceso terminado.';
  SErrorIntegridadEjecutableActualizado =
    'La huella SHA-256 de %s no coincide con la que publicó la versión ' +
    '%s. El archivo puede estar dañado o haber sido manipulado: ' +
    'conviene revertir la actualización o reinstalar el programa.';
  SErrorPlanSustitucionNoValido =
    'El plan de sustitución de ejecutables no es válido.';
  SErrorPlanSustitucionNoAdmisible =
    'El plan de sustitución apunta fuera de la carpeta del programa.';
  SErrorSustitucionElevadaRechazada =
    'Hace falta permiso de administrador de Windows para sustituir el ' +
    'programa, y no se ha concedido.';
  SErrorSustitucionElevadaSinRespuesta =
    'La instancia con permisos de administrador no ha devuelto el ' +
    'resultado de la sustitución.';
  SAvisoSustitucionNecesitaElevacion =
    'ViraCash está instalado en una carpeta protegida, así que Windows ' +
    'pedirá permiso de administrador para sustituir el programa.';
  SErrorInteraccionActualizacionIncompleta =
    'La pantalla de actualizacion no ha facilitado todas las respuestas ' +
    'que el proceso necesita.';
  SPreguntaAplicarScriptsPendientesArranque =
    'La última actualización dejó %d scripts pendientes de aplicar en ' +
    'la base de datos.' + sLineBreak + sLineBreak +
    'Aplicarlos puede llevar bastante tiempo y, al terminar, hay que ' +
    'salir del programa. ¿Aplicarlos ahora?';
  SAvisoElegirCopiaPreviaActualizacion =
    'ViraCash se reiniciará para restaurar la copia. Cuando lo pida, ' +
    'elija este archivo:' + sLineBreak + '%s';
  SAvisoSalirTrasActualizacion =
    'ViraCash se va a cerrar. Vuelva a abrirlo para seguir trabajando ' +
    'con la versión correcta.';
implementation

end.
