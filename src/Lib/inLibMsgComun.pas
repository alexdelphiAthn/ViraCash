{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgComun                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes compartidos por infraestructura y varios dominios.               }
{******************************************************************************}
unit inLibMsgComun;

interface

resourcestring
  SCerrarPestana = 'Cerrar pestaña';
  SDesdockarPestana = 'Desacoplar';
  SDockarPestana = 'Acoplar';
  SCerrarOtrasPestanas = 'Cerrar todas pestañas menos esta';
  SOpcionesAbiertas = 'Opciones abiertas';
  SPreguntaCerrarPantallaConCambios =
    'La pantalla «%s» tiene cambios pendientes. ¿Desea guardarlos ' +
    'antes de cerrar?' + sLineBreak + sLineBreak +
    'Sí: guardar. No: descartar. Cancelar: seguir trabajando.';
  SErrorAbrirPantallaConexion =
    'No se ha podido abrir %s: %s';
  SErrorAbrirPantallaLimiteConexiones =
    'No se ha podido abrir %s: el servidor no admite más conexiones. ' +
    'Cierre alguna pantalla o consulte al administrador.';
  SAvisoSerieOcupada =
    'La serie %s está ocupada por otro puesto.' + #13#10 +
    'Espere unos segundos y pulse Reintentar.';
  SAvisoDatosOcupados =
    'Los datos están ocupados por otro puesto.' + #13#10 +
    'Espere unos segundos y pulse Reintentar.';
  SClassRttiNotFnd = 'Clase %s no encontrada en rtti. ' +
                            'Hay un error al crear el formulario';
  SLocateNotFnd = 'El dato o datos %s no se han encontrado en %s';
  SResWinFNotFnd = '%s no encontrada en las tabla del sistema' +
                            ' fza_winforms';
  SAdvMsg = 'Mensaje Advertencia';
  SCaptionColumnaCodigoAlmacen = 'Código';
  SCaptionColumnaNombreAlmacen = 'Almacén';
  SErrorContextoSesionFormularioNoConfigurado =
    'No se ha configurado el contexto de sesión del formulario.';
  SErrorServicioAuditoriaDatosNoConfigurado =
    'No se ha configurado el servicio de auditoría de datos.';
  SAvisoSinComandosESCPOSImpresora =
    'No hay comandos ESC/POS para enviar a la impresora.';
  SErrorImprimir = 'Error al imprimir: %s';
  SAvisoSinComandosESCPOSPDF =
    'No hay comandos ESC/POS para generar el PDF.';
  SInfoPDFGuardado = 'PDF guardado en: %s';
  SInfoPNGGuardado = 'PNG guardado en: %s';
  SAvisoColacionSesion =
    'No se pudo fijar la colación de la sesión: %s';
  SAvisoTimeoutServidor =
    'No se pudo establecer el timeout del servidor: %s';
  SDetalleErrorMySQL = sLineBreak + '(MySQL %d: %s)';
  SErrorAbrirConsultaOpe =
    '[ConsultaOpe] Error abriendo %s: %s';
  SPreguntaCambioCriticoEmpresa =
    'Atención: %s una empresa puede anular la licencia del programa o ' +
    'invalidar el sistema Verifactu existente.' + sLineBreak + sLineBreak +
    'Revise que los datos fiscales, certificados y la instalación SIF ' +
    'siguen siendo correctos.' + sLineBreak + sLineBreak +
    '¿Desea continuar?';
  SErrorPorcentajeRetencionEmpresa =
    '%d no es un valor válido  para %% de Retención';
  SErrorRetencionesEmpresaConcurrentes =
    'No se pueden grabar dos porcentajes  activos en la misma fecha para ' +
    'la empresa %s';
  SErrorSerieEmpresa =
    '%s no es un valor válido  para serie por Empresa ';
  SErrorSerieUsadaOtraEmpresa =
    'La serie %s ya la usa la empresa %s. Las facturas y los demás ' +
    'documentos se identifican por serie y número, sin la empresa: cada ' +
    'empresa necesita series propias.';
  SErrorSerieTokenizadaEmpresa =
    'La serie tokenizada %s debe contener yyyy (2026), yy (26), q, mm, ' +
    'dd o una combinación de ellos, sin repetir ningún token ni mezclar ' +
    'yyyy con yy. Ejemplos: A1.yyyy, A1.yy, yyyy.Tq.A1 y yyyy.mm.dd.';
  SErrorSerieTokenizadaCalendarioNoNatural =
    'La empresa debe tener marcado "Hacer coincidir calendario natural ' +
    'con tokens" antes de usar una serie tokenizada.';
  SErrorIbanEmpresa =
    'IBAN no válido para el banco de la empresa: %s';
  SErrorRazonSocialEmpresa =
    '%s no es un valor de registro válido para el campo Razón Social de ' +
    'Empresa';
  SErrorCodigoEmpresa =
    '%s no es un valor de registro válido para el campo Código de Empresa';
  SErrorCabeceraBorradorSinGrabar =
    'No se ha grabado la cabecera del borrador';
  SErrorServicioConexionesDatosNoConfigurado =
    'No se ha configurado el servicio de conexiones de datos.';
  SErrorContextoSesionFiltrosNoConfigurado =
    'No se ha configurado el contexto de sesión.';
  SErrorDescripcionFormaPago =
    '%s no es un valor válido para el campo Descripción de Formas de Pago';
  SErrorContextoSesionModuloDatosNoConfigurado =
    'No se ha configurado el contexto de sesión del módulo de datos.';
  SErrorCodigoIva =
    '%s no es un valor de registro válido para el campo Código de IVA';
  SErrorGrupoIvaNoExiste =
    '%s no es un valor válido o no existe para grupo de IVAS';
  SErrorRangoFechasIva =
    'Error de Rango en las fechas. Error en la fecha.O se han establecido ' +
    'dos periodos activos en el mismo periodo para la zona %s';
  SErrorDescripcionGrupoIva =
    '%s no es un valor de registro válido para el campo Descripción de ' +
    'Grupos de IVA';
  SErrorCodigoGrupoIva =
    '%s no es un valor de registro válido para el campo Código de Grupos ' +
    'de IVA';
  SErrorDosGruposIvaPredeterminados =
    'No es posible marcar dos grupos de IVA como Grupo de IVA por Defecto';
  SErrorContextoSesionPerfilesNoConfigurado =
    'No se ha configurado el contexto de sesión.';
  SErrorEmpresaSinAlmacenActivo =
    'La empresa %s no tiene ningún almacén activo disponible.';
  SErrorAlmacenDepositosEmpresaNoEncontrado =
    'No se ha encontrado un almacén de depósitos (TIPO_USO_ALM = ' +
    '''DEPÓSITO'') activo para la empresa %s.';
  SErrorCodigoEanMinimo7Digitos =
    'El código debe tener al menos 7 dígitos para calcular el control.';
  SErrorCodigoEanMinimo12Digitos =
    'El código debe tener al menos 12 dígitos para calcular el control.';
  SErrorEjecutorBusquedasNoRegistrado =
    'No se ha registrado el ejecutor de búsquedas genéricas.';
  SErrorHojaCalculoNoActiva =
    'No hay hoja activa: llama a NuevaHoja antes de escribir.';
  SErrorControlHojaCalculoObligatorio =
    'NuevaHoja requiere un control TdxSpreadSheet.';
  SErrorGuardarHojaCalculoControlObligatorio =
    'Guardar requiere un control TdxSpreadSheet, no una vista suelta.';
  SErrorIbanInvalido = 'IBAN Inválido';
  SErrorPaisIbanInvalido = 'País del IBAN Inválido';
  SErrorDigitoControlIbanInvalido =
    'Dígito Control del IBAN Inválido';
  SErrorLongitudCuentaBancariaInvalida =
    'Longitud de Número de Cuenta incorrecta';
  SErrorCuentaBancariaInvalida =
    'Número de Cuenta incorrecto';
  SErrorDigitoControlCuentaBancaria =
    'DC Incorrecto, es %s y debería ser %s';
  SErrorPaisIbanInvalidoTipos =
    'País del IBAN Inválido';
  SErrorDigitoControlIbanInvalidoTipos =
    'Digito Control del IBAN Inválido';
  STextoResetearLayout = 'Resetear Layout';
  SInfoLayoutReseteado =
    'Layout reseteado.' + sLineBreak +
    'Se aplicará la próxima vez que abra el formulario.';
  SErrorAccesoFicheroLog =
    'No se puede acceder a %s. Faltan permisos.';
  SErrorCrearMutexLog = 'Error al crear mutex: %s';
  SErrorPreviewExcelNoRegistrado =
    'No se ha registrado el previsualizador de hojas de cálculo.';
  SErrorGenerarContadorAutomatico =
    'Error al generar contador automático: %s';
  SErrorNumeroCuentaInvalido =
    'Número de Cuenta Inválido';
  SErrorNifNoValido = ' NIF No Válido';
  SErrorLetraDniIncorrecta =
    'Letra DNI Incorrecta. Correcta %s';
  SErrorCrearSeleccionarDocumentoAntesLineas =
    'Crea o selecciona %s antes de añadir líneas.';
  SErrorCrearSeleccionarDocumentoAntesTallas =
    'Crea o selecciona %s antes de activar tallas.';
  SDepuracionComponenteNoTcxLabel =
    '%s is not TcxLabel';
  SDepuracionComponenteNoTcxTabSheet =
    '%s is not tcxTabSheet ';
  SDepuracionComponenteNoTcxDbCheckBox =
    '%s is not TcxDBCheckBox';
  SDepuracionComponenteNoTcxButton =
    '%s is not TcxButton';
  SDepuracionComponenteNoTcxGroupBox =
    '%s is not TcxGroupBox';
  SDepuracionComponenteNoTcxDbRadioGroup =
    '%s is not TcxDBRadioGroup';
  SDepuracionComponenteNoSpeedButton =
    '%s is not TSpeedButton';
  SDepuracionComponenteNoTcxRadioButton =
    '%s is not TcxRadioButton';
  SErrorImagenNoExiste = 'La imagen no existe';
  SErrorColorPaletaBusquedaInvalido =
    'Indique un color de paleta válido por código, nombre o HEX (#RRGGBB).';
  SErrorOperacionSinBorrador =
    'La operación seleccionada no tiene borrador.';
  SErrorBorradorNoCerradoFiscalmente =
    'El borrador %s\%s aún no está cerrado fiscalmente: no se puede anular.';
  SPreguntaAnularFiscalmenteBorrador =
    '¿Anular fiscalmente el borrador %s\%s?';
  SPreguntaRectificarBorrador =
    'Seleccione cómo rectificar el borrador %s\%s.' + sLineBreak +
    'Por diferencias carga las cantidades en negativo; sustitutiva las ' +
    'carga en positivo.';
  SErrorOperacionCorreoNoEncontrada =
    'No se ha encontrado la operación seleccionada.';
  STituloEnviarDocumentacion = 'Enviar documentación';
  SSolicitudCorreoElectronico = 'Correo electrónico:';
  SErrorCorreoElectronicoObligatorio =
    'Indique una dirección de correo electrónico.';
  SErrorEnviarCorreoOperacion =
    'No se ha podido enviar el correo.' + sLineBreak + '%s';
  SInfoEfectoConciliado = 'Efecto conciliado.';
  SErrorConciliarEfecto = 'No se pudo conciliar el efecto.';
  SErrorEfectoNoSeleccionado =
    'Selecciona un efecto en la rejilla.';
  SErrorCarteraEfectosNoAbierta =
    'No hay cartera de efectos abierta.';
  SPreguntaFusionarEfectos =
    '¿Fusionar los efectos seleccionados en un único efecto pendiente?';
  SInfoEfectosConciliados = 'Efectos conciliados en %s.';
  SErrorFusionarEfectos =
    'No se pudieron fusionar los efectos.';
  SErrorContadorSerieEmpresa =
    'No se pudo obtener el siguiente código del contador "ES" para la ' +
    'nueva serie.';
  SErrorEmpresaCrearSeriesNoSeleccionada =
    'Selecciona una empresa antes de crear sus series.';
  SInfoSeriesEmpresaCreadas =
    'Creadas %d series. Omitidas %d ya existentes.';
  SErrorEmpresaNoSeleccionada = 'No hay empresa seleccionada.';
  SInfoClienteTraspasosAlGrabar =
    'El cliente de traspasos se crea solo al grabar la empresa nueva.';
  SInfoClienteTraspasosCreado =
    'Cliente de traspasos %s enlazado a la empresa. Revise en su ficha si ' +
    'se le aplican retenciones.';
  SInfoInstalacionSifEmpresaDisponible =
    'Número de instalación SIF disponible para %s:' + sLineBreak + '%s';
  SErrorContadorAutomaticoBusqueda =
    'No se pudo obtener el contador automático.';
  SInfoRegistroBusquedaCreado =
    'Registro %s creado correctamente.';
  SErrorInsertarRegistroBusqueda =
    'Error al insertar (se ha cancelado la operación): %s';
  SInfoTextoNoEncontrado = 'Texto no encontrado.';
  STituloBusquedaGlobal = 'Búsqueda Global';
  SSolicitudTextoBusquedaGlobal =
    'Introduce el texto a buscar en todos los procesos:';
  SInfoProcesosBusquedaNoEncontrados =
    'No se encontraron procesos que contengan: %s';
  SErrorDatosCopiarNoDisponibles = 'No hay datos que copiar.';
  SPreguntaCopiarFilasPortapapeles =
    'Vas a copiar %d filas al portapapeles. ¿Continuar?';
  SErrorEjecucionProceso = 'Error en ejecución: %s';
  SErrorComandoSqlProceso = 'Error en comando SQL: %s';
  SErrorConexionTrabajoNoDisponible =
    'No está disponible la conexión de trabajo.';
  SInfoDatosGuardados = 'Datos guardados correctamente';
  SErrorGrabarDatos = 'Error al grabar: %s';
  SPreguntaGrabarCambiosPendientes =
    'Hay datos no grabados. ¿Desea grabar los cambios?';
  SPreguntaCancelarIntroduccionDatos =
    'Hay un alta sin grabar. ¿Desea cancelar la introducción de datos?';
  STituloMensajeAdvertenciaGen = 'Mensaje de Advertencia';
  SInfoCambiosGrabados = 'Cambios grabados';
  SInfoCambiosCancelados = 'Cambios revertidos/cancelados';
  SErrorConexionPrincipalNoDisponible =
    'No está disponible la conexión principal.';
  SPreguntaEliminarRegistro =
    '¿Estás seguro de que deseas eliminar este registro?';
  STituloConfirmarEliminacion = 'Confirmar eliminación';
  SPreguntaEliminarRegistroConHijos =
    'Hay %d %s vinculados a este registro.' + sLineBreak + sLineBreak +
    'No se recomienda eliminarlo: se rompera la relacion con' + sLineBreak +
    'los registros hijos.' + sLineBreak + sLineBreak +
    '¿Deseas eliminarlo de todas formas?';
  SAvisoDesactivarRegistroConHijos =
    'Hay %d %s vinculados a este registro.' + sLineBreak + sLineBreak +
    'No se recomienda eliminarlo. Te sugerimos DESACTIVARLO' + sLineBreak +
    'para conservar el histórico.';
  SAvisoDesactivarRegistroSinHijos =
    'Este registro puede DESACTIVARSE en lugar de eliminarse' + sLineBreak +
    'para conservar el histórico.';
  SDescripcionHijosGenerica = 'registros asociados';
  STextoOpcionesBorradoRegistro =
    sLineBreak + sLineBreak +
    'Sí       = Desactivar (recomendado)' + sLineBreak +
    'No       = Eliminar definitivamente' + sLineBreak +
    'Cancelar = No hacer nada';
  SErrorFiltroSinCondiciones =
    'El filtro seleccionado no tiene condiciones guardadas.';
  SErrorFiltroActualVacio =
    'No hay ningún filtro aplicado en la lista para guardar.';
  SPreguntaSobrescribirFiltro =
    'Ya existe un filtro propio con ese nombre. Desea sobrescribirlo?';
  STituloSobrescribirFiltro = 'Sobrescribir filtro';
  SInfoFiltroSobrescrito = 'Filtro sobrescrito correctamente.';
  SInfoFiltroGuardado = 'Filtro guardado correctamente.';
  SPreguntaLimpiarFiltrosAddBlock =
    'Limpiar todos los filtros?';
  SPreguntaPrevisualizarAddBlock =
    'No has previsualizado. Previsualizar ahora?';
  SPreguntaConfirmarAddBlock =
    'Se van a insertar %d artículos. ¿Continuar?';
  SErrorCertificadoNoSeleccionado =
    'Seleccione un certificado.';
  SErrorEmpleadoEntradaCambioNoIndicado =
    'Introduzca el empleado que realiza la operación.';
  SErrorImporteEntradaCambioNoValido =
    'Introduzca un importe mayor que cero.';
  STituloAvisoEntradaCambio =
    'Aviso';
  SErrorDestinoEnvioIncompleto =
    'Almacén, serie y número son obligatorios.';
  SErrorSerieBorradorNoSeleccionada =
    'Seleccione la serie del borrador.';
  SErrorFechaBorradorNoIndicada =
    'Indique la fecha del borrador.';
  SPreguntaEditarCamposExtraInforme =
    '¿Desea añadir o editar campos extra del informe provenientes de otras ' +
    'tablas o vistas externas?';
  SErrorPrivilegiosBorrarFormato =
    'No tiene privilegios suficientes para borrar el formato de %s. ' +
    'Consulte con el Administrador';
  SPreguntaBorrarFormato =
    '¿Está seguro de borrar el formato?';
  SPreguntaReemplazarInforme =
    'El informe ya existe. ¿Desea reemplazar el informe?';
  STituloAdvertenciaInforme =
    'Mensaje Advertencia';
  STituloGuardarInformeFichero =
    'Guardar informe como';
  SFiltroArchivoInformeFr3 =
    'Informe FastReport (*.fr3)|*.fr3';
  SPermisoFormatoTodos =
    'Todos';
  SErrorFiltroNoSeleccionado =
    'Seleccione un filtro de la lista.';
  SErrorFiltroSinCondicionesAplicar =
    'El filtro no tiene condiciones para aplicar.';
  SErrorFiltroSinCondicionesGuardar =
    'El filtro no tiene condiciones para guardar.';
  SInfoCambiosFiltroGuardados =
    'Cambios del filtro guardados correctamente.';
  SErrorPantallaSinFiltroAplicado =
    'La pantalla no tiene ningún filtro aplicado.';
  SPreguntaReemplazarFiltro =
    'Filtro guardado actualmente:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Se reemplazará por el filtro actual de la pantalla:' +
    sLineBreak + '%s' + sLineBreak + sLineBreak + '¿Desea continuar?';
  STituloReemplazarFiltro =
    'Reemplazar filtro';
  SInfoFiltroReemplazado =
    'Filtro reemplazado correctamente.';
  SErrorFiltroPropioDuplicado =
    'Ya existe un filtro propio con ese nombre. Indique un nombre diferente.';
  SInfoCopiaFiltroGuardada =
    'Copia del filtro guardada correctamente.';
  SPreguntaBorrarFiltro =
    '¿Borrar el filtro seleccionado?';
  STituloConfirmarBorradoFiltro =
    'Confirmar borrado';
  SInfoFiltroCompartidoGrupo =
    'Filtro compartido con tu grupo (%s).';
  SInfoFiltroCompartidoTodos =
    'Filtro compartido con todos los usuarios.';
  SErrorNombreFiltroNoIndicado =
    'Indique un nombre para el filtro.';
  SErrorCodigoGuiaNoIndicado =
    'Escribe un código para la guía.';
  SErrorTablaExternaGuiaNoSeleccionada =
    'Selecciona una tabla externa.';
  SErrorCampoMasterGuiaNoSeleccionado =
    'Selecciona el campo master.';
  SErrorCampoDetailGuiaNoSeleccionado =
    'Selecciona el campo detail (de la tabla).';
  SInfoGuiaAnadida =
    'Guía "%s" añadida: %s.%s → %s';
  SInfoGuiasEliminarNoEncontradas =
    'No hay guías para eliminar.';
  SPreguntaEliminarGuia =
    '¿Eliminar la guía "%s"?';
  SErrorImporteConciliadoNoValido =
    'El importe conciliado debe ser mayor que 0.';
  SErrorImporteConciliadoSuperaPendiente =
    'El importe no puede superar el pendiente.';
  SErrorNombreFormatoWizardNoIndicado =
    'Indique un nombre para el formato.';
  SErrorNombreFormatoWizardNoModificado =
    'Escriba un nombre nuevo para el formato.';
  SErrorDatasetMasterWizardNoSeleccionado =
    '1) Selecciona el dataset master (cabecera o detalle) en la lista de la ' +
    'izquierda.';
  SErrorCamposMasterWizardNoSeleccionados =
    '2) Marca al menos un campo del master (Master fields).';
  SErrorTablaExternaWizardNoSeleccionada =
    '3) Selecciona la tabla o vista externa que quieres ligar.';
  SErrorCamposTablaExternaWizardNoSeleccionados =
    '4) Selecciona el campo (o campos) de la tabla externa que se cruzan con ' +
    'el master. Para seleccionar varios usa Ctrl o Mayus; el orden de ' +
    'seleccion determina el pareo con los Master fields (k=1,2,...).';
  SErrorSerieDocumentoNoIndicada =
    'Introduzca la serie.';
  SErrorAlmacenSerieTokenizadaNoIndicado =
    'Seleccione el almacén de la serie tokenizada.';
  SErrorCajaSerieTokenizadaNoIndicada =
    'Seleccione la caja de la serie tokenizada.';
  SErrorFechaInicioDocumentoNoIndicada =
    'Introduzca la fecha de inicio.';
  SErrorFechaFinDocumentoNoIndicada =
    'Introduzca la fecha de fin.';
  SErrorRangoFechasDocumentoNoValido =
    'La fecha de fin no puede ser anterior al inicio.';
  SErrorFechaFiltroInformeNoValida =
    'Introduzca una fecha válida entre 01/01/1900 y 31/12/9999.';
  SInfoEmpresaSinCuentasBancarias =
    'La empresa no tiene cuentas bancarias activas. El documento se ' +
    'generará sin banco de empresa asignado.';
  // R01 - Textos de controles e indicadores en ejecución
  SCaptionCancelandoOperacion = 'Cancelando operación...';
  SCaptionPreparando = 'Preparando...';
  SCaptionEsperaConsultandoDatosInforme =
    'Consultando los datos del informe...';
  SCaptionEsperaPreparandoInforme = 'Preparando el informe...';
  SCaptionEsperaPaginaInforme = 'Página %d';
  SCaptionEsperaGenerandoHojaCalculo =
    'Generando la hoja de cálculo...';
  SCaptionEsperaSeleccionandoArticulo =
    '%s. Seleccionando artículo: %s';
  SCaptionEsperaExportandoFilas = 'Exportando fila %s de %s';
  SCaptionVersion = 'Versión %s';
  STituloGuardarExcel = 'Guardar Excel';
  SCaptionFiltroTodosArchivos = 'Todos los archivos';
  SCaptionFiltroArchivo = 'Archivo %s';
  // R02 - Búsqueda de datos y pestañas de líneas
  SCaptionLineasSku = 'Líneas [SKU]';
  SCaptionLineasTallasHoriz = 'Líneas [Tallas horiz.]';
  SCaptionLineasDesglose = 'Líneas [Desglose]';
  SCaptionAnadirDocumentoTrabajo = 'Añadir a Documento de Trabajo...';
  SCaptionSeleccioneFiltrosBuscar =
    'Seleccione los filtros y pulse Buscar';
  SCaptionColorObjetivo = 'Color objetivo';
  SCaptionColorBasico = 'Color básico';
  SCaptionTextoABuscar = 'Texto a buscar';
  SCaptionOcultarCriterios = 'Ocultar criterios';
  SCaptionMostrarCriterios = 'Mostrar criterios';
  SCaptionSkuEncontrados = '%s SKU encontrados';
  SCaptionSkuEncontradosLimite =
    '%s SKU encontrados (límite alcanzado; concrete la búsqueda)';
  SCaptionColumnaFotos = 'Fotos';
  SCaptionFiltrosCargaContraido = #9654'  Filtros de carga';
  SCaptionFiltrosCargaExpandido = #9660'  Filtros de carga';
  // R03 - Botones genéricos de diálogo
  SCaptionCancelar = 'Cancelar';
  // R06 - Estado de edición y menú de editores
  SCaptionEstadoInsertando = 'Insertando';
  SCaptionEstadoEditando = 'Editando';
  SCaptionEstadoNavegando = 'Navegando';
  SCaptionEstadoInactivo = 'Inactivo';
  SCaptionMenuDeshacer = '&Deshacer';
  SCaptionMenuRehacer = '&Rehacer';
  SCaptionMenuBorrarLinea = '&Borrar Línea';
  SCaptionMenuCortar = 'Cor&tar';
  SCaptionMenuCopiar = '&Copiar';
  SCaptionMenuPegar = '&Pegar';
  SCaptionCopiarDatos = 'Copiar datos';
  SCaptionSinDatosMostrar = '<No hay datos a mostrar>';
  SCaptionSinDatos = 'No hay datos';
  // R08 - Menú contextual de stock
  SCaptionAgregarDocumentoTrabajo =
    'Agregar a Documento de Trabajo...';
  // R09 - Botones y títulos genéricos de modales
  SCaptionAceptarF12 = '&Aceptar (F12)';
  SCaptionCancelarEsc = '&Cancelar (ESC)';
  SCaptionAceptar = 'Aceptar';
  SCaptionAplicar = 'Aplicar';
  SCaptionLimpiar = 'Limpiar';
  STituloBusquedaEmpleados = 'Búsqueda de Empleados';
  // R10 - Filtros de informes y listados
  SCaptionCondicionesFiltroCompartido =
    'Condiciones del filtro compartido. Puede editarlas y guardar ' +
    'una copia propia:';
  SCaptionCondicionesFiltroSeleccionado =
    'Condiciones del filtro seleccionado (puede editarlas):';
  SCaptionTabFechas = 'Fechas';
  SCaptionFechaInicio = 'Fecha inicio:';
  SCaptionFechaFin = 'Fecha fin:';
  SHintEscribaIntroFiltrar =
    'Escriba y pulse Intro para filtrar (sin marcar nada = todos)';
  SCaptionMarqueValoresIncluir =
    'Marque los valores a incluir. Si no marca ninguno, salen todos.';
  SCaptionMarqueAgrupacion =
    'Marque por qué agrupar y ordene los niveles con ' +
    'Subir/Bajar (el primero es el grupo más externo). ' +
    'Máximo 3 niveles. Sin marcar = sin agrupar.';
  SCaptionSubir = 'Subir';
  SCaptionBajar = 'Bajar';
  SCaptionNivelFamilia = 'Nivel familia:';
  SHintNivelFamilia =
    'Al agrupar por familia: 0 = familia del artículo; ' +
    '1 = familia raíz; 2, 3... niveles intermedios.';
  SCaptionTabFamilias = 'Familias';
  SCaptionDobleClicMarcaFamilia =
    'Un clic o barra espaciadora marca/desmarca. Marcar una ' +
    'familia incluye sus subfamilias. Sin marcar = todas.';
  SHintBuscarFamilia = 'Escriba para buscar una familia';
  SCaptionExportarExcel = 'Exportar Excel';
  SCaptionSalir = 'Salir';
  SCaptionDesde = 'Desde';
  SCaptionHasta = 'Hasta';
  SCaptionFamilia = 'Familia';
  SCaptionProveedor = 'Proveedor';
  SCaptionTemporada = 'Temporada';
  SCaptionBuscar = 'Buscar';
  // R11 - Wizard de guías
  SCaptionGuiasLigadasFormato =
    'Guías ligadas al formato "%s"  (''%s'')';
  // R15 - Librerías de interfaz genérica
  SCaptionTabModoDesglose = '%s [Desglose]';
  SCaptionTabModoSku = '%s [SKU]';
  SCaptionTabModoTallasHorizBandas = '%s [Tallas horiz. bandas]';
  SCaptionTabModoTallasHoriz = '%s [Tallas horiz.]';
  STituloGuardarListadoExcel = 'Guardar listado a Excel';
  STituloErrorProducido = 'Se ha producido un error';
  SCaptionDetalleErrorCabecera =
    'Detalle completo del error. Puedes enviarlo directamente al ' +
    'desarrollador o copiarlo al portapapeles.';
  SCaptionCerrar = 'Cerrar';
  SCaptionSalirAplicacion = 'Salir de la aplicación';
  SCaptionCopiarPortapapeles = 'Copiar al portapapeles';
  SCaptionEnviarDesarrollador = 'Enviar error al soporte';
  SCaptionActivarLogCompleto = 'Activar LOG completo';
  SCaptionEnviarCopiaSeguridadError =
    'Enviar copia de seguridad protegida (ZIP)';
  STituloContrasenaCopiaError = 'Proteger copia de seguridad';
  SInfoContrasenaCopiaError =
    'La copia se cifrará y comprimirá. Guarde esta contraseña: deberá ' +
    'enviarla por correo al desarrollador.';
  SCaptionContrasenaCopiaError = 'Contraseña';
  SCaptionRepetirContrasenaCopiaError = 'Repita la contraseña';
  SErrorContrasenaCopiaErrorVacia =
    'La contraseña de la copia no puede estar vacía.';
  SErrorContrasenasCopiaErrorNoCoinciden =
    'Las contraseñas no coinciden.';
  SCaptionEmailContactoError = 'Email de contacto:';
  SCaptionTelefonoContactoError = 'Teléfono de contacto:';
  SCaptionDescripcionError = '¿Qué estaba haciendo cuando ocurrió?';
  SInfoEvidenciasError =
    'Se adjuntarán el detalle técnico, el pantallazo de ViraCash y el ' +
    'tramo reciente del LOG.';
  SInfoEvidenciasCopiaError =
    'Se adjuntarán el detalle técnico, el pantallazo de ViraCash y una ' +
    'copia de seguridad protegida.';
  SInfoCopiaSeguridadError =
    'Al enviar se solicitará la contraseña y se creará el ZIP. La ' +
    'operación puede tardar varios minutos.';
  SInfoPreparandoCopiaSeguridadError =
    'Preparando la copia de seguridad protegida...';
  SErrorPrepararCopiaSeguridadError =
    'No se pudo preparar la copia de seguridad.' + sLineBreak + '%s';
  SAvisoLogErrorIncompleto =
    'Aviso: no están activas las tres trazas del LOG (SQL, rendimiento ' +
    'y avanzada). Puede enviar el error, pero diagnosticarlo será más ' +
    'costoso.';
  SPreguntaActivarLogCompleto =
    '¿Desea activar ahora las trazas SQL, rendimiento y avanzada? ' +
    'Después cierre este aviso y repita la operación que produjo el ' +
    'error.';
  SInfoLogActivadoRepetir =
    'LOG completo activado para esta sesión. Cierre este aviso y repita ' +
    'la operación que produjo el error.';
  SInfoLogErrorCompleto =
    'Las trazas SQL, rendimiento y avanzada están activas.';
  SErrorContactoEnvioErrorNoValido =
    'Indique un email válido y un teléfono de contacto válido.';
  SErrorNoSePudoEnviarError =
    'No se pudo enviar el error al desarrollador.';
  SErrorRespuestaEnvioError =
    'El servicio de errores respondió con HTTP %d.';
  SInfoErrorEnviado =
    'Error enviado correctamente. Referencia: %s';
  SInfoSeguimientoError =
    'Puede consultar la comunicación en: %s';
  SInfoEnviarContrasenaCopiaError =
    'La contraseña no se ha enviado ni almacenado. Envíela usted por ' +
    'correo a info@viracash.net e indique esta referencia: %s';
  SCaptionSinFiltrosGuardados = '(Sin filtros guardados)';
  SCaptionGuardarFiltroActual = 'Guardar filtro actual...';
  SCaptionGestionarCompartirFiltros = 'Gestionar y compartir filtros...';
  SCaptionGuiaTabla = 'Guía: %s';
  SCaptionRenombrarColumna = 'Renombrar columna...';
  SCaptionNuevaGuia = 'Nueva guía...';
  STituloRenombrarColumnas = 'Renombrar columnas';
  SCaptionCargandoDatosEspere = 'Cargando datos, espera por favor...';
  STituloSeleccionarColumnas = 'Seleccionar columnas a incorporar';
  SErrorRestaurarListaEnEdicion =
    'Guarde o cancele los cambios antes de volver a la lista.';
  SCaptionAyudaWebAtras = 'Atrás';
  SCaptionAyudaWebAdelante = 'Adelante';
  SCaptionAyudaWebRecargar = 'Recargar';
  SInfoAyudaWebCargando = 'Abriendo ayuda...';
  SErrorAyudaWebIniciar =
    'No se ha podido iniciar el visor web (código %s).' + sLineBreak +
    'Compruebe que Microsoft Edge WebView2 Runtime está instalado y que ' +
    'ViraCash puede escribir en la carpeta temporal del usuario.' +
    sLineBreak +
    'Después pulse Recargar o contacte con su administrador.';
  SAvisoFirmaEjecutable =
    'Este ejecutable de ViraCash no lleva la firma digital de Alejandro ' +
    'Laorden Hidalgo (certificado de validación extendida).' +
    sLineBreak + sLineBreak + '%s' + sLineBreak + sLineBreak +
    'Si no lo ha instalado usted o su distribuidor, no lo use y póngase ' +
    'en contacto con el soporte.';
  SFirmaEjecutableSinFirma = 'El fichero %s no está firmado.';
  SFirmaEjecutableNoValida =
    'La firma de %s no es válida (código %s): el fichero puede haber sido ' +
    'modificado después de firmarlo.';
  SFirmaEjecutableOtroTitular = 'El fichero %s está firmado por «%s».';
  SFirmaEjecutableNoEV =
    'El fichero %s está firmado por «%s», pero con un certificado que no ' +
    'es de validación extendida.';
  SFirmaEjecutableNoComprobada =
    'No se ha podido comprobar la firma de %s: %s';
  SFirmaEjecutableCorrecta =
    'El fichero %s está firmado por «%s» con un certificado de validación ' +
    'extendida y no se ha modificado desde que se firmó.';
  SFirmaEjecutableDesarrollo =
    'El fichero %s no está firmado: es una compilación de desarrollo.';
  SPreguntaTotalMaximoLinea =
    'El total de la línea (%s) supera el máximo por línea de la ' +
    'empresa (%s).' + #13#10 + '¿Es correcto?';
  SErrorConfirmacionTotalLineaNoConfigurada =
    'No se ha configurado la confirmación del total máximo por línea.';
  SCasillaEnviarDocumentoEmail = 'Enviar por email';
  SParametroAplicacionCorreoFaltante =
    '  - Parámetros de la aplicación';
  SUrlServicioWebCorreoFaltante =
    '  - URL general del servicio web';
  SApiKeyInstalacionCorreoFaltante =
    '  - API key / token de la instalación';
  SReferenciaInstalacionCorreoFaltante =
    '  - Referencia global de la instalación';
  SErrorParametrosCorreoNoConfigurados =
    'Configura primero estos parámetros (Parámetros de la aplicación -> ' +
    'Servicios web):' + #13#10 + '%s';
  SAccionBorrarEmpresa = 'borrar';
  SAccionEditarEmpresa = 'editar';
  SAccionCrearEmpresa = 'crear';
  SCaptionFamiliaFiltroInforme = 'Familia';
  SCaptionIncluirFiltroInforme = 'Incluir';
  SCaptionCodigoFiltroInforme = 'Código';
  SCaptionAlmacenesFiltroInforme = 'Almacenes';
  SCaptionProveedoresFiltroInforme = 'Proveedores';
  SCaptionTemporadasFiltroInforme = 'Temporadas';
  SCaptionArticulosFiltroInforme = 'Artículos';
  SAvisoProcesoGeneradorLanzado = '-- Proceso %d lanzado.';
  // Botones sobre las rejillas de detalle (inLibBotonesDetalle).
  SBotonAnadirDetalle = 'Añadir';
  SBotonBorrarDetalle = 'Borrar';
  SHintAnadirDetalle = 'Añadir una línea';
  SHintBorrarDetalle = 'Borrar la línea seleccionada';


implementation

end.
