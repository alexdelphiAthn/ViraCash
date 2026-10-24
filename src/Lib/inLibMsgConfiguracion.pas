{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgConfiguracion                                         }
{    Tipo:       Librería                                                      }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de configuración, seguridad, permisos y conexiones.              }
{******************************************************************************}
unit inLibMsgConfiguracion;

interface

resourcestring
  SDegradadoBordesSin = 'Sin degradado';
  SDegradadoBordesSuave = 'Degradado suave';
  SDegradadoBordesIntenso = 'Degradado intenso';
  SErrorDecryptPassBBDD = 'Falló en la lectura y desencriptación' +
                                  ' de password de la Base de Datos.';
  SErrorDecryptPass = 'Falló en la lectura y desencriptación' +
                                  ' de password.';
  SErrorAuthPass = 'La contraseña de usuario no es correcta. ';
  SScriptSuccess = 'El script se ejecutó exitosamente.';
  SFailLoadScriptBBDD = 'No existe script de creación de BD, ' +
                               'instalación fallida';
  SCreateSuccBBDD = 'La Base de Datos se creó exitosamente';
  SErrorCreateBBDD = 'No existe una base de datos llamada %s, '  +
                            '¿desea crearla? ';
  SBBDDUpdateTo = 'La Base de Datos se actualizó a ';
  SNotExistsUpBBDDFile = 'No existe script de actualización %s,'+
                       ' instalación fallida';
  SAdviceUpdateBBDD = 'Es necesario actualizar la BBDD' +
                            ' con nuevos cambios,' + sLineBreak +
                            ' ¿desea proceder con el procedimiento' +
                            ' de actualización?';
  SNoConnBBDD = 'No hay conexión con la bbdd';
  SConnSuccBBDD = 'La conexión se estableció exitosamente.';
  SGetPassBBDD = 'Escriba password de la BBDD';
  SConnFailBBDD = 'Conexión fallida. Usuario, password, ' +
                           'host, puerto o Nombre de la BBDD no es válido.';
  SErrorSentenciaScript =
    'Ocurrió un error ejecutando la siguiente sentencia:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Detalle del error: %s' + sLineBreak + sLineBreak +
    '¿Deseas ignorar el error y continuar con el script?';
  SSolicitudPassBBDD = 'Introduzca password de la BBDD';
  SScriptEjecutado = 'El script se ejecutó exitosamente';
  SScriptNoEjecutado = 'El script no fue ejecutado';
  SErrorConexionServidorBBDD =
    'No se pudo conectar al servidor MySQL/MariaDB:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Revise la configuración pulsando "Configurar BBDD".';
  SErrorConexionSinContrasenaBBDD =
    'El perfil de conexión no tiene contraseña de base de datos.' +
    sLineBreak + sLineBreak +
    'Escríbala en "Configurar Base de Datos" y vuelva a entrar.' +
    sLineBreak + sLineBreak + 'Detalle: %s';
  SErrorEstructuraBBDD =
    '%s' + sLineBreak + sLineBreak +
    'Puede usar "Subir script" para crear/actualizar la base de datos, ' +
    'o "Recuperar copia" para restaurar un backup.';
  SErrorConexionBBDD =
    'No se pudo conectar a la base de datos "%s":' + sLineBreak + '%s';
  SErrorInicioAutomatico =
    'No se pudo completar el inicio automático:' + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'Introduzca sus credenciales manualmente.';
  SErrorGuardarPreferenciasInicioSesion =
    'El inicio de sesión es correcto, pero no se pudieron guardar todas las ' +
    'preferencias de acceso.' + sLineBreak + sLineBreak +
    'La sesión continuará.' + sLineBreak + sLineBreak + '%s';
  SErrorPrepararNuevoEquipo =
    'No se pudo restablecer la contraseña de acceso:' +
    sLineBreak + '%s';
  SErrorGuardarInicioTrasNuevoEquipo =
    'La contraseña ya se cambió, pero no se pudieron guardar todas las ' +
    'preferencias de inicio.' + sLineBreak + sLineBreak +
    'Puede continuar e iniciar sesión con la contraseña nueva.' +
    sLineBreak + sLineBreak + '%s';
  SErrorCompletarNuevoEquipoPendiente =
    'La contraseña ya se cambió, pero no se pudo retirar la marca de ' +
    'primera ejecución.' + sLineBreak + sLineBreak +
    'Puede continuar e iniciar sesión con la contraseña nueva.' +
    sLineBreak + sLineBreak + '%s';
  SErrorOrdenParametrosNuevoEquipo =
    'En el arranque de mantenimiento, el perfil INI debe ser el primer ' +
    'argumento de la aplicación.';
  SErrorGuardarContrasenaUsuario =
    'No se pudo guardar la contraseña con la protección de Windows.' +
    sLineBreak + sLineBreak +
    'Se desactivarán "Recordar contraseña" y el arranque automático.' +
    sLineBreak + sLineBreak + '%s';
  SErrorGuardarContrasenaUsuarioNoRetirada =
    'No se pudo guardar la contraseña exclusivamente con la protección de ' +
    'Windows ni retirar la credencial anterior.' + sLineBreak + sLineBreak +
    '"Recordar contraseña" seguirá marcado para no ocultar que aún puede ' +
    'haber una credencial almacenada; el arranque automático se ' +
    'desactivará.' + sLineBreak + sLineBreak + '%s' + sLineBreak + '%s';
  SErrorEliminarContrasenaUsuario =
    'No se pudo retirar la contraseña recordada.' +
    sLineBreak + sLineBreak +
    'La opción seguirá activada para no ocultar que la credencial aún ' +
    'puede estar almacenada.' + sLineBreak + sLineBreak + '%s';
  SLicenciaEstablecida =
    'Licencia establecida.' + sLineBreak + sLineBreak +
    'Código: %s' + sLineBreak +
    'NIF de empresa: %d' + sLineBreak +
    'INI: %s' + sLineBreak + sLineBreak + '%s';
  SLicenciaBaseDatos =
    'Base de datos: %s en %s:%d';
  SLicenciaNoEstablecidaSinNif =
    'No se ha establecido licencia.' + sLineBreak + sLineBreak +
    'No hay NIF de empresa configurado.' + sLineBreak +
    'Mientras no haya NIF de empresa, no se exigirá licencia.';
  SErrorEstablecerLicencia =
    'No se pudo establecer la licencia.' + sLineBreak + sLineBreak + '%s';
  SModoDemo = 'Modo DEMO: limitado a %d facturas al día.';
  SCancelacionSolicitada =
    'La cancelación ya está solicitada. Espere a que termine la sentencia ' +
    'actual.';
  SPreguntaCancelarOperacion =
    'Hay una operación en curso moviendo datos.' + sLineBreak +
    sLineBreak + '¿Desea abandonar la operación en curso?';
  SOperacionCancelada = 'Operación cancelada.';
  SCopiaSeguridadGuardada =
    'La copia se guardó exitosamente';
  SProgresoGuardandoCopiaTextoPlano =
    'Guardando copia en texto plano';
  SProgresoComprimiendoCopiaZip =
    'Comprimiendo copia en ZIP';
  SProgresoComprimiendoCifrandoCopia =
    'Comprimiendo ZIP y cifrando copia';
  SErrorCrearCopiaSeguridad =
    'No se pudo crear la copia de seguridad.' + sLineBreak + '%s';
  SErrorConexionCopiaNoDisponible =
    'No hay una conexión disponible para la copia de seguridad.';
  SErrorFormatoCreacionCopiaNoPermitido =
    'El formato elegido para la copia de seguridad no está permitido.';
  SErrorFormatoCopiaNoCompatible =
    'El formato de la copia no es compatible.';
  SErrorSintaxisComandoCopiaSeguridad =
    'Uso: vcash.exe [perfil.ini] /copiaseguridad "<ruta>.crypt".';
  SErrorSintaxisComandoImprimirFacturas =
    'Uso: vcash.exe /imprimirfacturas ' +
    '"SERIE\NUMERO, SERIE\NUMERO" ["Formato"] "C:\destino". ' +
    'Si se omite el formato o se pasa "", se usa Predeterminado.';
  SErrorSintaxisComandoRecalculosStock =
    'Uso: vcash.exe perfil.ini /recalcular_mov.';
  SAyudaComandos =
    'ViraCash - opciones de ejecución' + sLineBreak +
    sLineBreak +
    '1. Aplicación interactiva' + sLineBreak +
    '   vcash.exe [perfil.ini]' + sLineBreak +
    '   Abre ViraCash. El nombre simple del perfil .ini es opcional.' +
    sLineBreak + sLineBreak +
    '2. Copia de seguridad cifrada' + sLineBreak +
    '   %s' + sLineBreak +
    '   Genera SQL, lo comprime en ZIP y cifra el resultado con la ' +
    'contraseña de la conexión.' + sLineBreak +
    '   La plantilla admite DIASEMANA, DIAMES, MES, AÑO, {ANO} y ' +
    'CLAVE. Sobrescribe el destino.' + sLineBreak +
    '   No se admite la contraseña como argumento.' +
    sLineBreak + sLineBreak +
    '3. Impresión de facturas en PDF' + sLineBreak +
    '   %s' + sLineBreak +
    '   Acepta una o varias referencias y un formato opcional. Solicita ' +
    'una sesión autenticada.' + sLineBreak +
    sLineBreak +
    '4. Recálculo diferido de movimientos de stock' + sLineBreak +
    '   %s' + sLineBreak +
    '   Procesa la cola pendiente en lotes pequeños hasta dejarla vacía.' +
    sLineBreak + sLineBreak +
    '5. Ayuda' + sLineBreak +
    '   vcash.exe /?' + sLineBreak +
    '   vcash.exe /help' + sLineBreak +
    '   Muestra este texto en la consola y termina con código 0.' +
    sLineBreak + sLineBreak +
    'En línea de comandos, la copia siempre se genera como ZIP cifrado ' +
    '(.crypt). SQL y ZIP sin cifrar solo están disponibles desde el menú ' +
    'para administradores.';
  SErrorRutaComandoCopiaSeguridad =
    'La ruta de la copia de seguridad no es válida.';
  SErrorExtensionComandoCopiaSeguridad =
    'El destino de la copia debe tener extensión .crypt.';
  SErrorClaveComandoCopiaSeguridad =
    'La contraseña configurada para la conexión de la BBDD no es válida.';
  SErrorConexionComandoCopiaSeguridad =
    'No se pudo preparar la conexión para la copia: %s';
  SErrorInesperadoComandoCopiaSeguridad =
    'Error inesperado al preparar la copia de seguridad: %s';
  SErrorPublicarComandoCopiaSeguridad =
    'No se pudo guardar la copia en su destino: %s';
  SErrorFormatoComandoCopiaSeguridad =
    'El archivo temporal no contiene una copia cifrada válida.';
  SInfoComandoCopiaSeguridadInicio =
    'Inicio de copia de seguridad por línea de comandos.';
  SInfoComandoCopiaSeguridadParametrosValidados =
    'Parámetros de la copia validados correctamente.';
  SInfoComandoCopiaSeguridadConexion =
    'Preparando la conexión configurada para la copia.';
  SInfoComandoCopiaSeguridadConexionPreparada =
    'Conexión preparada: servidor %s; base de datos %s.';
  SInfoComandoCopiaSeguridadDestino =
    'Destino de la copia: %s';
  SInfoComandoCopiaSeguridadGeneracion =
    'Generando el SQL, comprimiéndolo en ZIP y cifrándolo.';
  SInfoComandoCopiaSeguridadPublicacion =
    'Copia cifrada generada. Publicando el archivo de destino; si ya ' +
    'existe, se reemplazará.';
  SInfoComandoCopiaSeguridadCompletado =
    'Copia de seguridad completada: %s';
  SErrorConexionComandoRecalculosStock =
    'No se pudo preparar la conexión para recalcular el stock: %s';
  SErrorEjecucionComandoRecalculosStock =
    'No se pudo procesar la cola de recálculos de stock: %s';
  SErrorColaIncompletaComandoRecalculosStock =
    'La cola no quedó vacía. Sin procesar: %d; pendientes: %d; ' +
    'procesando: %d; con error: %d.';
  SInfoInicioComandoRecalculosStock =
    'Inicio del recálculo de movimientos por línea de comandos.';
  SInfoConfiguracionComandoRecalculosStock =
    'Proceso interno: hasta %d grupos por lote, pausa %d ms, ' +
    'reserva %d s y reintento %d s.';
  SInfoConexionComandoRecalculosStock =
    'Conexión preparada: servidor %s; base de datos %s.';
  SInfoCompletadoComandoRecalculosStock =
    'Cola de recálculos procesada. Lotes ejecutados: %d.';
  SInfoProgresoComandoRecalculosStock =
    'Lote %d terminado: %d grupos recalculados y %d con error; ' +
    'quedan %d movimientos sin procesar.';
  SRestauracionCancelada =
    'Operación cancelada. La base de datos puede haber quedado ' +
    'parcialmente restaurada.';
  SErrorRestaurarCopiaSeguridad =
    'Hubo problemas al restaurar la copia.' + sLineBreak + '%s';
  SErrorContrasenaCopiaVacia =
    'La contraseña de la copia no puede estar vacía.';
  SErrorTipoRestauracionNoPermitido =
    'Los usuarios no administradores sólo pueden restaurar copias o ' +
    'scripts cifrados (*.crypt).';
  SErrorRestauracionRequiereAdministrador =
    'Sólo un administrador puede restaurar una copia desde la aplicación.';
  SErrorOperacionRestauracionEnCurso =
    'Hay otra operación en curso. Espere a que termine antes de restaurar.';
  SPreguntaConfirmarRestauracionAdministrativa =
    'Se va a restaurar la siguiente copia:' + sLineBreak + sLineBreak +
    '%s' + sLineBreak + sLineBreak +
    'La base de datos actual será reemplazada. ¿Desea continuar?';
  SErrorRelanzarViraCash =
    'No se pudo reiniciar ViraCash (código %d).' + sLineBreak +
    'Abra la aplicación de nuevo para continuar.';
  SPreguntaReemplazarFichero =
    '¿Desea reemplazar el fichero existente?';
  SCopiaSeguridadCancelada = 'La copia se canceló';
  SCargaScriptCancelada = 'Se canceló la carga del script.';
  SUsuarioNoExiste = 'El nombre de usuario no existe';
  SDescripcionParametroIdioma =
    'Idioma de la interfaz (es-ES, en-GB, ca-ES o zh-CN; ' +
    'qps-ploc para pruebas)';
  SErrorSeleccionIdiomaNoAplicado =
    'No se pudo aplicar el idioma %s:' + sLineBreak + '%s';
  SErrorProveedorEdicionParametrosNoConfigurado =
    'No se ha configurado el proveedor de edición de parámetros.';
  SErrorParametrosAplicacionEditablesNoConfigurados =
    'No se han configurado los parámetros de aplicación editables.';
  SInfoParametrosGuardados =
    'Se guardaron %d parámetros para: %s';
  SAvisoReiniciarMenusTrazabilidad =
    'Reinicie ViraCash para actualizar los menús de garantías, ' +
    'lotes y números de serie.';
  SAvisoParametrosRestringidosIgnorados =
    'Se ignoraron %d parámetros restringidos. ' +
    'Solo un usuario administrador puede cambiarlos.';
  SAvisoParametrosRestringidosNoGuardados =
    'No se guardaron %d parámetros restringidos. ' +
    'Solo un usuario administrador puede cambiarlos.';
  SInfoSinCambiosParametros =
    'No se detectaron cambios para guardar.';
  SErrorCargarParametrosAmbito =
    'No se pudieron cargar los parámetros de %s:' + sLineBreak + '%s' +
    sLineBreak + sLineBreak +
    'No se pueden modificar ni guardar hasta que se carguen ' +
    'correctamente.';
  SErrorGuardarParametrosSinCarga =
    'No se guardó nada: los parámetros de %s no se pudieron cargar. ' +
    'Vuelva a seleccionarlo en el desplegable.';
  SInfoLayoutGuardado = 'Layout guardado.';
  SPreguntaSalirSinGuardar =
    '¿Seguro que desea salir sin guardar?';
  SAvisoSinUsuariosParametrosGuardados =
    'No hay usuarios con parámetros guardados para este formulario.';
  STituloCambiarUsuario = 'Cambiar usuario';
  SSolicitudCambiarUsuario =
    'Usuarios disponibles:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Introduce el nombre de usuario:';
  SErrorUsuarioNoEncontrado = 'Usuario no encontrado: %s';
  SErrorContextoInicioSesionNoProporcionado =
    'No se ha proporcionado el contexto de inicio de sesión.';
  SErrorParametrosSinEstadoLicencia =
    'Los parámetros no admiten el estado de licencia.';
  SErrorParametrosAplicacionSinContratoEdicion =
    'Los parámetros de aplicación no ofrecen el contrato de edición.';
  SErrorServicioConexionesNoDisponible =
    'No está disponible el servicio de conexiones.';
  SCertificadoQuedaMenosUnDia = 'queda menos de 1 día';
  SCertificadoQuedaUnDia = 'queda 1 día';
  SCertificadoQuedanDias = 'quedan %d días';
  SAvisoCertificadoCaducado =
    'certificado electrónico caducado el %s.';
  SAvisoCertificadoProximoCaducar =
    'certificado electrónico caduca el %s (%s).';
  SAvisoCertificadosCaducidad =
    'Atención: hay certificados electrónicos próximos a caducar o ya ' +
    'caducados.' + sLineBreak + sLineBreak + '%s' + sLineBreak +
    'Revise la ficha de empresa y renueve el certificado.';
  SAvisoCargaPermisosRestringidos =
    'No se pudieron cargar los permisos.' + sLineBreak +
    'El acceso se ha restringido por seguridad.' + sLineBreak +
    'Revise el registro de la aplicación en:' + sLineBreak + '%s';
  SAvisoMenuSinPantallaRegistrada =
    'La opción «%s» no está disponible en esta base de datos: ' +
    'falta registrar su pantalla.' + sLineBreak +
    'Aplique los scripts de actualización pendientes o avise al ' +
    'administrador.';
  SInfoCopiaSeguridadGuardada =
    'La copia se guardó exitosamente.';
  SAvisoRestauracionCancelada =
    'Operación cancelada. La base de datos puede haber quedado ' +
    'parcialmente modificada.';
  SErrorEjecutarScript =
    'Hubo problemas al ejecutar el script.' + sLineBreak + '%s';
  SPreguntaSalirAplicacion =
    '¿Quiere salir de la aplicación ViraCash?';
  SPreguntaCopiaSeguridadAntesDDL =
    'ATENCIÓN: El script contiene sentencias DDL (modifican la estructura ' +
    'de la base de datos).' + sLineBreak +
    'En MySQL/MariaDB, estos cambios provocan un guardado automático y ' +
    'NO son reversibles en caso de error.' + sLineBreak + sLineBreak +
    '¿Deseas realizar una copia de seguridad antes de continuar?';
  SPreguntaCopiaAntesRestaurarCifrada =
    'La copia puede reemplazar datos y estructura de la base de ' +
    'datos.' + sLineBreak + sLineBreak +
    '¿Deseas realizar una copia de seguridad antes de continuar?';
  SInfoScriptCancelado =
    'Operación cancelada. El script no se ejecutará.';
  SErrorAbrirDireccion =
    'No se ha podido abrir la dirección: %s';
  SErrorBBDDDuplicado =
    'Ya existe un registro con ese valor (entrada duplicada).';
  SErrorBBDDCamposObligatorios =
    'Hay campos obligatorios sin rellenar.';
  SErrorBBDDCampoObligatorio =
    'Rellena el campo «%s»: es obligatorio para poder grabar.';
  SErrorBBDDCampoDesconocido =
    'Campo desconocido en la consulta SQL: %s';
  SErrorBBDDTablaNoExiste =
    'La tabla consultada no existe en la base de datos: %s';
  SErrorBBDDSinPermisos =
    'No tiene permisos suficientes para realizar esta acción en la base ' +
    'de datos.';
  SErrorBBDDClaveForaneaNoExiste =
    'El valor no existe en la tabla relacionada (clave foránea).';
  SErrorBBDDRegistroDependiente =
    'No se puede eliminar: existen registros que dependen de este.';
  SErrorBBDDDatoDemasiadoLargo =
    'El dato introducido es demasiado largo para el campo.';
  SErrorBBDDCredencialesIncorrectas =
    'Acceso denegado: usuario o contraseña incorrectos.';
  SErrorBBDDConexionServidor =
    'No se puede conectar al servidor MySQL. Comprueba la red y el puerto.';
  SErrorBBDDConexionPerdida =
    'La conexión con el servidor MySQL se ha perdido.';
  SErrorBBDDConexionPerdidaConsulta =
    'Se perdió la conexión durante la ejecución de la consulta.';
  SErrorBBDDTimeoutBloqueo =
    'El servidor está ocupado (Tiempo de espera de bloqueo). Inténtalo de ' +
    'nuevo.';
  SErrorBBDDDeadlock =
    'Se ha producido un bloqueo cruzado (Deadlock). Inténtalo de nuevo.';
  SErrorBBDDTablaYaExiste =
    'La tabla o vista ya existe en la base de datos %s';
  SErrorBBDDProcedimientoYaExiste =
    'El procedimiento o función ya existe en la base de datos.' +
    sLineBreak + 'Detalle del servidor: %s';
  SErrorBBDDGenerico =
    'Error en base de datos [%d]:' + sLineBreak + '%s';
  SErrorNombreUsuario =
    '%s no es un valor de registro válido para el campo usuario';
  SErrorUsuarioCoincideGrupo =
    'El usuario %s coincide con un grupo del sistema';
  // FZ-ISSUE-397: un usuario nuevo no se graba a medio dar de alta.
  SErrorUsuarioNuevoSinGrupo =
    'Elija el grupo del usuario %s antes de grabarlo.';
  SErrorUsuarioNuevoSinContrasena =
    'El usuario %s no tiene contraseña. Póngasela con ' +
    '«Cambiar Contraseña» antes de grabarlo.';
  SErrorConexionPrincipalTrabajoNoDisponible =
    'No hay conexión principal para crear una conexión de trabajo.';
  SErrorOperacionCanceladaUsuario =
    'Operación cancelada por el usuario.';
  SErrorRestauracionEstructuraIncompleta =
    'La restauración terminó, pero la estructura mínima no está completa.' +
    sLineBreak + '%s';
  SErrorNombreBBDDDestinoVacio =
    'El nombre de la BBDD de destino está vacío.';
  SErrorFicheroCopiaNoExiste =
    'No existe el fichero de copia: %s';
  SErrorDesencriptarCopia =
    'No se pudo desencriptar la copia. Revise la contraseña o seleccione ' +
    'un fichero SQL sin cifrar.';
  SErrorLimitePeticionesCripto =
    'Rate limit alcanzado (429). Espera un momento.';
  SErrorRestauracionNoFinalizada =
    'La restauración no finalizó correctamente.';
  SErrorDialogoPermisosLayoutNoRegistrado =
    'No se ha registrado el diálogo de permisos de layout.';
  SErrorNifEmpresaLicenciaNoConfigurado =
    'No hay NIF de empresa configurado.';
  SInfoLicenciaSinNifEmpresa =
    'No hay NIF de empresa; no se exige licencia.';
  SErrorLicenciaNoEncontrada =
    'No se encontró licencia de aplicación.';
  SInfoLicenciaValida =
    'Licencia de aplicación válida.';
  SErrorLicenciaNifsNoCoinciden =
    'La licencia de aplicación no coincide con los NIF de empresa ' +
    'configurados.';
  SErrorParametrosAplicacionNoProporcionados =
    'No se han proporcionado los parámetros de aplicación.';
  SErrorServicioPerfilesNoProporcionado =
    'No se ha proporcionado el servicio de perfiles de usuario.';
  SErrorCargarPerfilParametros =
    'No se pudo cargar el perfil de parámetros "%s".';
  SErrorConexionPermisosNoDisponible =
    'No hay conexión disponible para cargar los permisos.';
  SErrorConexionBbddConExcepcion =
    '%s%s Mensaje: %s';
  SErrorServicioPerfilesUsuarioNoConfigurado =
    'No se ha configurado el servicio de perfiles de usuario.';
  SPreguntaIgnorarErrorScript =
    'Ocurrió un error ejecutando el script.' + sLineBreak +
    'Detalle del error: %s' + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?';
  SErrorMetadatoSinScript =
    'No hay estructura o script disponible para este metadato.';
  SPreguntaIgnorarErrorComandoScript =
    'Ocurrió un error ejecutando %s.' + sLineBreak +
    'Detalle: %s' + sLineBreak + sLineBreak +
    '¿Desea ignorar el error y continuar con el script?';
  SErrorPermisoInsertarRegistro =
    'No tienes permiso para insertar registros en esta pantalla.';
  SErrorPermisoModificarRegistro =
    'No tienes permiso para modificar registros en esta pantalla.';
  SErrorPermisoGuardarRegistro =
    'No tienes permiso para guardar este registro.';
  SErrorPermisoBorrarRegistro =
    'No tienes permiso para borrar registros en esta pantalla.';
  SErrorPermisoAbrirPantalla =
    'No tienes permiso para abrir %s.';
  SErrorPermisoAbrirParametros =
    'No tienes permiso para abrir los parámetros del entorno.';
  SErrorPermisoGuardarParametros =
    'No tienes permiso para guardar los parámetros del entorno.';
  SErrorNodoPermisosNoSeleccionado =
    'Selecciona primero un nodo del arbol.';
  SErrorOrigenDestinoPermisosNoSeleccionados =
    'Selecciona un origen y un destino.';
  SErrorOrigenDestinoPermisosIguales =
    'El origen y el destino no pueden ser el mismo.';
  SInfoModoReemplazarPermisos =
    'Se reemplazaran todos los permisos del destino.';
  SInfoModoCombinarPermisos =
    'Se agregaran o actualizaran los permisos en el destino.';
  SInfoAlcancePermisosMenu =
    'Alcance: solo permisos de menu.';
  SInfoAlcanceTodosPermisos =
    'Alcance: todos los permisos.';
  SPreguntaCopiarPermisos =
    'Copiar permisos de "%s" a "%s"?' + sLineBreak +
    '%s' + sLineBreak + '%s';
  SInfoPermisosCopiados =
    '%d permisos copiados de "%s" a "%s".';
  SErrorContrasenasNoCoinciden =
    'Las contraseñas no coinciden';
  SErrorContrasenaUsuarioVacia =
    'La contraseña nueva no puede estar vacía.';
  SCaptionNuevaContrasenaUsuario = 'Nueva contraseña';
  SCaptionRepetirNuevaContrasenaUsuario =
    'Repita la nueva contraseña';
  SCaptionContinuarNuevaContrasena = '&Continuar';
  SInfoLogGuardado =
    'Log guardado en %s';
  SErrorPermisoAbrirCajon =
    'No tiene permiso para abrir el cajón.';
  // R01 - Diálogos de copias de seguridad y scripts
  STituloCargarScript = 'Cargar script';
  STituloGuardarCopiaSeguridad = 'Guardar copia de seguridad';
  STituloCargarCopiaSeguridad = 'Cargar copia de seguridad';
  STituloRestaurarCopiaEjecutarScript =
    'Restaurar copia o ejecutar script';
  SCaptionFiltroCopiasSqlEncriptadas =
    'Copias SQL, ZIP o encriptadas';
  SCaptionFiltroCopiasCifradas = 'Copias cifradas';
  SCaptionFiltroCopiasZip = 'Copias ZIP';
  SCaptionFiltroArchivosSql = 'Archivos SQL';
  SCaptionFiltroCopiasSqlCifradas =
    'Copias SQL, ZIP o cifradas';
  SCaptionFiltroCopiasScriptsCifrados =
    'Copias o scripts cifrados';
  SCaptionPreparandoCopiaSeguridad =
    'Preparando copia de seguridad...';
  SCaptionPreparandoRestauracion = 'Preparando restauración...';
  // R06 - Generador de procesos
  STituloAbrirScriptSql = 'Abrir Script SQL';
  SCaptionFiltroScriptsSql =
    'Scripts SQL (*.sql)|*.sql|Archivos de texto (*.txt)|*.txt|' +
    'Todos los archivos (*.*)|*.*';
  // R07 - Árbol de permisos
  SCaptionModoCombinarPermisos = 'Combinar (agregar y actualizar)';
  SCaptionModoReemplazarPermisos = 'Reemplazar todos los del destino';
  SCaptionAvisoSujetoAdministrador =
    'Aviso: este sujeto es administrador; en ejecucion tiene TODOS los ' +
    'permisos, se marque lo que se marque aquí.';
  SErrorPermisosSinProveedorMenu =
    'La pantalla de permisos requiere el proveedor de menú del ' +
    'principal (IProveedorMenuPantallas).';
  SColPermisoMenuPermisos =
    'Permiso / Menú';
  SColPermitidoPermisos =
    'Permitido';
  SColEstadoPermisos =
    'Estado';
  SColCodigoPermisos =
    'Código';
  SAccionConsultarPermisos =
    'Consultar / buscar';
  SAccionExportarExcelPermisos =
    'Exportar a Excel';
  SAccionVerPeticionPermisos =
    'Ver petición / respuesta';
  SAccionAltaPermisos =
    'Alta de registros';
  SAccionModificarPermisos =
    'Modificar registros';
  SAccionBorrarPermisos =
    'Borrar registros';
  SAccionImprimirPermisos =
    'Imprimir informes';
  SAccionActivarWebPermisos =
    'Activar/desactivar web';
  SCategoriaCajaBuscarPermisos =
    'Caja (TPV) - Buscar / Modificar';
  SCategoriaCajaPermisos =
    'Caja (TPV)';
  SCategoriaArqueoPermisos =
    'Arqueo';
  SCategoriaMenusOcultosPermisos =
    'Menús no visibles';
  SCategoriaOtrosPermisos =
    'Otros';
  SSujetoTodosPermisos =
    'Todos (valores por defecto)';
  SSujetoGrupoAdminPermisos =
    'Grupo: %s (administrador)';
  SSujetoGrupoPermisos =
    'Grupo: %s';
  SSujetoUsuarioPermisos =
    'Usuario: %s [grupo %s]';
  SOrigenDefectoPermitidoPermisos =
    'Por defecto (permitido)';
  SOrigenDefectoDenegadoPermisos =
    'Por defecto (denegado)';
  SOrigenHeredadoTodosPermisos =
    'Heredado de Todos';
  SOrigenHeredadoGrupoPermisos =
    'Heredado del grupo %s';
  SOrigenExigeConcesionPermisos =
    'Exige concesión a usuario o grupo';
  SOrigenPropioPermisos =
    'Propio';
  SEstadoPermitidoPermisos =
    'Permitido - %s';
  SEstadoDenegadoPermisos =
    'Denegado - %s';
  SEstadoResumenPermisos =
    '%d de %d permitidos';
  // R09 - Contraseña de copias de seguridad
  STituloProtegerCopiaSeguridad = 'Proteger copia de seguridad';
  SCaptionCopiaSeCifrara =
    'La copia se cifrará. Guarde esta contraseña: será necesaria ' +
    'para restaurarla.';
  STituloAbrirCopiaCifrada = 'Abrir copia cifrada';
  SCaptionIntroduzcaContrasenaCopia =
    'Introduzca la contraseña con la que se protegió la copia.';
  // R11 - Log de scripts
  STituloGuardarLogComo = 'Guardar log como...';
  SCaptionFiltroArchivosSqlTexto =
    'Archivos SQL (*.sql)|*.sql|Archivos de texto (*.txt)|*.txt|' +
    'Todos los archivos (*.*)|*.*';
  SCaptionFiltroArchivosTexto =
    'Archivos de texto (*.txt)|*.txt|Todos los archivos (*.*)|*.*';
  SErrorScriptCopiaIncompleto =
    'No se guardó la copia porque el SQL generado está incompleto.';
  SProgresoVerificandoIntegridad =
    'Verificando integridad de la copia';
  SProgresoIntegridadVerificada = 'Integridad verificada';
  SProgresoDescifrandoCopia = 'Descifrando la copia';
  SProgresoValidandoContenido = 'Validando el contenido de la copia';
  SErrorSqlCadenaTamanoMaximo =
    'El SQL supera el límite de 400 MiB para una sola cadena.';
  SErrorFicheroSqlCopiaNoExiste =
    'No existe el fichero SQL que se va a proteger.';
  SErrorEscribirCopiaCifradaIncompleta =
    'No se pudo escribir completa la copia cifrada.';
  SErrorExtraerScriptCopiaIncompleto =
    'No se pudo extraer completo el script de la copia.';
  SCaptionResultadoObjetoProcesosAuxiliaresBBDD =
    '&Resultado - %s (máximo 1000 filas)';
  SErrorServicioRestauracionNoDisponible =
    'El servicio de restauración no está disponible.';
  SErrorCopiaSqlDatosTrasMarcadorFinal =
    'La copia SQL contiene datos después de su marcador final';
  SErrorCopiaSqlComentarioEjecutableNoAdmitido =
    'La copia SQL contiene un comentario ejecutable no admitido';
  SErrorCopiaSqlMarcadorFinalAusente =
    'La copia SQL está incompleta: falta el marcador final';
  SErrorCopiaSqlSavepointsActivos =
    'La copia SQL termina con savepoints activos';
  SErrorCopiaSqlTransaccionSavepointsSinCerrar =
    'La copia SQL no cierra la transacción con savepoints';
  SAvisoBorrarCajaConOperaciones =
    'La caja %s del almacén %s tiene %d operaciones grabadas (ventas, ' +
    'cobros, arqueos...). Si la borra, esas operaciones quedarán con una ' +
    'caja que ya no existe.' + sLineBreak + sLineBreak +
    '¿Desea borrarla de todas formas?';
implementation

end.
