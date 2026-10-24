unit Vcl.Consts;
{$WARN IMPLICIT_STRING_CAST OFF}
{$HPPEMIT LEGACYHPP}

interface

resourcestring

   SSelectADate = 'Seleccione una fecha';
   SOpenFileTitle = 'Abrir';
   SCantWriteResourceStreamError = 'No se puede escribir en un flujo de recursos de sólo lectura';
   SDuplicateReference = 'WriteObject llamado dos veces para la misma instancia';
   SClassMismatch = 'El recurso %s es de clase incorrecta';
   SInvalidTabIndex = 'Índice de tabulación fuera de límites';
   SInvalidTabPosition = 'La posición de la pestaña es incompatible con el estilo de pestaña actual';
   SInvalidTabStyle = 'Estilo de pestaña incompatible con la posición de pestaña actual';
   SInvalidBitmap = 'La imagen de mapa de bits no es válida';
   SInvalidIcon = 'La imagen del icono no es válida';
   SInvalidMetafile = 'El metaarchivo no es válido';
   SInvalidPixelFormat = 'Formato de píxel no válido';
   SInvalidImage = 'Imagen no válida';
   SBitmapEmpty = 'El mapa de bits está vacío';
   SScanLine = 'Índice de línea de escaneo fuera de rango';
   SChangeIconSize = 'No se puede cambiar el tamaño de un icono';
   SChangeWicSize = 'No se puede cambiar el tamaño de una imagen de WIC';
   SOleGraphic = 'Operación no válida en TOleGraphic';
   SUnknownExtension = 'Extensión de archivo de imagen desconocida (.%s)';
   SUnknownClipboardFormat = 'Formato de portapapeles no compatible';
   SUnknownStreamFormat = 'Formato de transmisi�n no compatible';
   SOutOfResources = 'Fuera de recursos del sistema';
   SNoCanvasHandle = 'El lienzo no permite dibujar';
   SInvalidTextFormatFlag = 'El indicador de formato de texto ''%s'' no es compatible';
   SInvalidFrameIndex = '�ndice de marco de imagen no v�lido %d: Hay %d marcos (0-%d)';
   SInvalidImageSize = 'Tama�o de imagen no v�lido';
   STooManyImages = 'Demasiadas im�genes';
   SDimsDoNotMatch = 'Las dimensiones de la imagen no coinciden con las dimensiones de la lista de imágenes';
   SInvalidImageList = 'Lista de imágenes no válida';
   SReplaceImage = 'No se puede reemplazar la imagen';
   SInsertImage = 'No se puede insertar la imagen';
   SImageIndexError = '�ndice de lista de imágenes no válido';
   SImageReadFail = 'Error al leer los datos de ImageList de la secuencia';
   SImageWriteFail = 'Error al escribir los datos de ImageList en la transmisión';
   SWindowDCError = 'Error al crear el contexto del dispositivo de ventana';
   SClientNotSet = 'Cliente de TDrag no inicializado';
   SWindowClass = 'Error al crear la clase de ventana';
   SWindowCreate = 'Error al crear la ventana';
   SCannotFocus = 'No se puede enfocar una ventana deshabilitada o invisible';
   SParentRequired = 'El control ''%s'' no tiene ventana principal';
   SControlPath = '. Ruta:'#13#10'%s';
   SParentGivenNotAParent = 'El padre proporcionado no es padre de ''%s''';
   SMDIChildNotVisible = 'No se puede ocultar un formulario secundario MDI';
   SVisibleChanged = 'No se puede cambiar lo visible en OnShow u OnHide';
   SCannotShowModal = 'No se puede hacer modal una ventana visible';
   SScrollBarRange = 'Propiedad de la barra de desplazamiento fuera de rango';
   SPropertyOutOfRange = '%s propiedad fuera de rango';
   SMenuIndexError = 'Índice de menú fuera de rango';
   SCannotSetCheckState = 'Check state can only be set when CheckBoxes is True';
   SInvalidCheckState = 'Check state incompatible with treeview''s CheckStyles';
   SMenuReinserted = 'Menú insertado dos veces';

   SMenuNotFound = 'El submenú no está en el menú';
   SNoTimers = 'No hay suficientes temporizadores disponibles';
   SNotPrinting = 'La impresora no está imprimiendo actualmente';
   SPrinting = 'Impresión en curso';
   SPrinterIndexError = 'Índice de impresora fuera de rango';
   SInvalidPrinter = 'La impresora seleccionada no es válida';
   SDeviceOnPort = '%s en %s';
   SGroupIndexTooLow = 'GroupIndex no puede ser menor que el GroupIndex de un elemento de menú anterior';
   STwoMDIForms = 'No se puede tener más de un formulario MDI por solicitud';
   SNoMDIForm = 'No se puede crear el formulario. Actualmente no hay formularios MDI activos';
   SImageCanvasNeedsBitmap = 'Sólo se puede modificar una imagen si contiene un mapa de bits';
   SControlParentSetToSelf = 'Un control no puede tenerse a sí mismo como padre';
   SControlNonMainThreadUsage = 'Control ''%s'' is used on a not main thread';
   SOKButton = 'Aceptar';
   SCancelButton = 'Cancelar';
   SYesButton = '&Sí';
   SNoButton = '&No';
   SHelpButton = '&Ayuda';
   SCloseButton = '&Cerrar';
   SIgnoreButton = '&Ignorar';
   SRetryButton = '&Reintentar';
   SAbortButton = 'Abortar';
   SAllButton = '&Todos';

   SCannotDragForm = 'No se puede arrastrar un formulario';
   SPutObjectError = 'Poner objeto en un elemento no definido';
   SCardDLLNotLoaded = 'No se pudo cargar CARDS.DLL';
   SDuplicateCardId = 'Se encontró un ID de tarjeta duplicado';

   SDdeErr = 'Un error devuelto desde DDE ($0%x)';
   SDdeConvErr = 'Error DDE - conversación no establecida ($0%x)';
   SDdeMemErr = 'Se produjo un error cuando DDE se quedó sin memoria ($0%x)';
   SDdeNoConnect = 'No se puede conectar la conversación DDE';

   SFB = 'FB';
   SFG = 'FG';
   SBG = 'BG';
   SOldTShape = 'No se puede cargar la versión anterior de TShape';
   SVMetafiles = 'Metaarchivos';
   SVEnhMetafiles = 'Metarchivos mejorados';
   SVIcons = 'Iconos';
   SVBitmaps = 'Mapas de bits';
   SVTIFFImages = 'Imágenes TIFF';
{$IF DEFINED(CLR)}
   SVJPGImages = 'Im�genes JPEG';
   SVPNGImages = 'Im�genes PNG';
   SVGIFImages = 'Im�genes GIF';
{$ENDIF}
   SGridTooLarge = 'Cuadrícula demasiado grande para su funcionamiento';
   STooManyDeleted = 'Demasiadas filas o columnas eliminadas';
   SIndexOutOfRange = '�ndice de cuadrícula fuera de rango';
SFixedColTooBig = 'El n�mero de columnas fijas debe ser menor que el número de columnas';
   SFixedRowTooBig = 'El n�mero de filas fijas debe ser menor que el número de filas';
   SInvalidStringGridOp = 'No se pueden insertar ni eliminar filas de la cuadrícula';
   SInvalidEnumValue = 'Valor de enumeración no válido';
   SInvalidNumber = 'Valor numérico no válido';
   SOutlineIndexError = 'Índice de esquema no encontrado';
   SOutlineExpandError = 'El padre debe estar expandido';
   SInvalidCurrentItem = 'Valor no válido para el elemento actual';
   SMaskErr = 'Valor de entrada no válido';
   SMaskEditErr = 'Valor de entrada no válido. Utilice la tecla de escape para abandonar los cambios';
   SOutlineError = 'Índice de esquema no válido';
   SOutlineBadLevel = 'Asignación de nivel incorrecta';
   SOutlineSelection = 'Selección no válida';
   SOutlineFileLoad = 'Error al cargar el archivo';
   SOutlineLongLine = 'Línea demasiado larga';
   SOutlineMaxLevels = 'Se excedió la profundidad máxima del contorno';

   SMsgDlgWarning = 'Advertencia';
   SMsgDlgError = 'Error';
   SMsgDlgInformation = 'Información';
   SMsgDlgConfirm = 'Confirmar';
   SMsgDlgYes = '&Sí';
   SMsgDlgNo = '&No';
   SMsgDlgOK = 'Aceptar';
   SMsgDlgCancel = 'Cancelar';
   SMsgDlgHelp = '&Ayuda';
   SMsgDlgHelpNone = 'No hay ayuda disponible';
   SMsgDlgHelpHelp = 'Ayuda';
   SMsgDlgAbort = '&Abortar';
   SMsgDlgRetry = '&Reintentar';
   SMsgDlgIgnore = '&Ignorar';
   SMsgDlgAll = '&Todos';
   SMsgDlgNoToAll = 'N&o a todos';
   SMsgDlgYesToAll = 'Sí a &Todos';
   SMsgDlgClose = '&Cerrar';

   SmkcBkSp = 'BkSp';
   SmkcTab = 'Tab';
   SmkcEsc = 'Esc';
   SmkcEnter = 'Entrar';
   SmkcSpace = 'Espacio';
   SmkcPgUp = 'RePág';
   SmkcPgDn = 'AvPág';
   SmkcEnd = 'Fin';
   SmkcHome = 'Inicio';
   SmkcLeft = 'Izquierda';
   SmkcUp = 'Arriba';
   SmkcRight = 'Derecho';
   SmkcDown = 'Abajo';
   SmkcIns = 'Ins';
   SmkcDel = 'Eliminar';
   SmkcShift = 'Mayús+';
   SmkcCtrl = 'Ctrl+';
   SmkcAlt = 'Alt+';

   srUnknown = '(Desconocido)';
   srNone = '(Ninguno)';
   SOutOfRange = 'El valor debe estar entre %dy %d';

   SDateEncodeError = 'Argumento no válido para la codificaci�n de fecha';
   SDefaultFilter = 'Todos los archivos (*.*)|*.*';
   sAllFilter = 'Todos';
   SNoVolumeLabel = ': [ - sin etiqueta de volumen - ]';
   SInsertLineError = 'No se puede insertar una línea';

   SConfirmCreateDir = 'El directorio especificado no existe. ¿Crearlo?';
   SSelectDirCap = 'Seleccionar directorio';
   SDirNameCap = 'Directorio &Nombre:';
   SDrivesCap = 'D&rives:';
   SDirsCap = '&Directorios:';
   SFilesCap = '&Archivos: (*.*)';
   SNetworkCap = 'Ne&red...';

   SColorPrefix = 'Color' deprecated; //!! obsoleto - eliminar en 5.0
   SColorTags = 'ABCDEFGHIJKLMNOP' deprecated; //!! obsoleto - eliminar en 5.0

   SInvalidClipFmt = 'Formato de portapapeles no válido';
   SIconToClipboard = 'El portapapeles no admite iconos';
   SCannotOpenClipboard = 'No se puede abrir el portapapeles: %s';

   SDefault = 'Predeterminado';

   SInvalidMemoSize = 'El texto excede la capacidad de la nota';
   SCustomColors = 'Colores personalizados';
   SInvalidPrinterOp = 'Operación no admitida en la impresora seleccionada';
   SNoDefaultPrinter = 'No hay ninguna impresora predeterminada seleccionada actualmente';

   SIniFileWriteError = 'No se puede escribir en %s';

   SBitsIndexError = 'Índice de bits fuera de rango';

   SUntitled = '(Sin título)';

   SInvalidRegType = 'Tipo de datos no válido para ''%s''';

   SUnknownConversion = 'Extensi�n de archivo de conversión RichEdit desconocida (.%s)';
   SDuplicateMenus = 'El menú ''%s'' ya está siendo utilizado por otro formulario';

   SPictureLabel = 'Imagen:';
   SPictureDesc = ' (%dx%d)';
   SPreviewLabel = 'Vista previa';

   SCannotOpenAVI = 'No se puede abrir AVI';

   SNotOpenErr = 'No hay ningún dispositivo MCI abierto';
   SMPOpenFilter = 'Todos los archivos (*.*)|*.*|Archivos Wave (*.wav)|*.wav|Archivos MIDI (*.mid)|*.mid|Video para Windows (*.avi)|*. avi';
   SMCINil = '';
   SMCIAVIVideo = 'AVIVideo';
   SMCICDAudio = 'CDAudio';
   SMCIDAT = 'DAT';
   SMCIDigitalVideo = 'Vídeo Digital';
   SMCIMMMovie = 'MMPelícula';
   SMCIOtro = 'Otro';
   SMCIOverlay = 'Superposición';
   SMCIScanner = 'Escáner';
   SMCISequencer = 'Secuenciador';
   SMCIVCR = 'videograbadora';
   SMCIVideodisc = 'Videodisco';
   SMCIWaveAudio = 'WaveAudio';
   SMCIUnknownError = 'Código de error desconocido';

   SBoldItalicFont = 'Negrita cursiva';
   SBoldFont = 'Negrita';
   SItalicFont = 'Cursiva';
   SRegularFont = 'Regular';

   SPropertiesVerb = 'Propiedades';

   SServiceFailed = 'El servicio falló en %s: %s';
   SExecute = 'ejecutar';
   SStart = 'inicio';
   SStop = 'detener';
   SPause = 'pausa';
   SContinue = 'continuar';
   SInterrogate = 'interrogar';
   SShutdown = 'apagar';
   SCustomError = 'El servicio falló en el mensaje personalizado(%d): %s';
   SServiceInstallOK = 'Servicio instalado correctamente';
   SServiceInstallFailed = 'El servicio "%s" no se pudo instalar con el error: "%s"';
   SServiceUninstallOK = 'Servicio desinstalado exitosamente';
   SServiceUninstallFailed = 'El servicio "%s" no se pudo desinstalar con el error: "%s"';

   SDockedCtlNeedsName = 'El control acoplado debe tener un nombre';
   SDockTreeRemoveError = 'Error al eliminar el control del árbol del muelle';
   SDockZoneNotFound = ' - Zona de acoplamiento no encontrada';
   SDockZoneHasNoCtl = ' - La zona del muelle no tiene control';
   SDockZoneVersionConflict = 'Error al cargar la zona del muelle desde la transmisión. ' +
     'Esperando la versión %d, pero encontró %d.';

   SAllCommands = 'Todos los comandos';

   SDuplicateItem = 'La lista no permite duplicados ($0%x)';

   STextNotFound = 'Texto no encontrado: "%s"';
   SBrowserExecError = 'No se ha especificado ningún navegador predeterminado';

   SColorBoxCustomCaption = 'Personalizado...';

   SMultiSelectRequired = 'El modo de selección múltiple debe estar activado para esta función';

   SPromptArrayTooShort = 'La longitud de la matriz de valores debe ser >= longitud de la matriz de solicitud';
   SPromptArrayEmpty = 'La matriz de mensajes no debe estar vacía';

   SUsername = '&Nombre de usuario';
   SPassword = '&Contraseña';
   SDomain = '&Dominio';
   SLogin = 'Iniciar sesión';

   SKeyCaption = 'Clave';
   SValueCaption = 'Valor';
   SKeyConflict = 'Ya existe una clave con el nombre "%s"';
   SKeyNotFound = 'Clave "%s" no encontrada';
   SNoColumnMoving = 'goColMoving no es una opción admitida';
   SNoEqualsInKey = 'La clave no puede contener el signo igual ("=")';

   SSendError = 'Error al enviar correo';
   SAssignSubItemError = 'No se puede asignar un subelemento a una barra de acciones cuando uno de sus elementos principales ya está asignado a una barra de acciones';
   SDeleteItemWithSubItems = 'El elemento %s tiene subelementos, ¿eliminarlo de todos modos?';
   SDeleteNotAllowed = 'No tienes permiso para eliminar este elemento';
   SMoveNotAllowed = 'No se permite mover el elemento %s';
   SMoreButtons = 'Más botones';
   SErrorDownloadingURL = 'Error al descargar la URL: %s';
   SUrlMonDllMissing = 'No se puede cargar %s';
   SAllActions = '(Todas las acciones)';
   SNoCategory = '(Sin categoría)';
   SExpand = 'Expandir';
   SErrorSettingPath = 'Error al configurar la ruta: "%s"';
   SLBPutError = 'Intentando colocar elementos en un cuadro de lista de estilo virtual';
   SErrorLoadingFile = 'Error al cargar el archivo de configuración previamente guardado: %s'#13'¿Desea eliminarlo?';
   SResetUsageData = '¿Restablecer todos los datos de uso?';
   SFileRunDialogTitle = 'Ejecutar';
   SNoName = '(Sin nombre)';
   SErrorActionManagerNotAssigned = 'Primero se debe asignar el ActionManager';
   SAddRemoveButtons = '&Agregar o quitar botones';
   SResetActionToolBar = 'Restablecer barra de herramientas';
   SPersonalizar = '&Personalizar...';
   SSeparator = 'Separador';
   SCircularReferencesNotAllowed = 'No se permiten referencias circulares';
   SCannotHideActionBand = '%s no permite ocultarse';
   SErrorSettingCount = 'Error al configurar %s.Count';
   SListBoxMustBeVirtual = 'El estilo del cuadro de lista (%s) debe ser virtual para poder configurar el Conteo';
   SUnableToSaveSettings = 'No se pueden guardar las configuraciones';
   SRestoreDefaultSchedule = '¿Desea restablecer el programa de prioridades predeterminado?';
   SNoGetItemEventHandler = 'No se ha asignado ningún controlador de eventos OnGetItem';
   SInvalidColorMap = 'Mapa de colores no válido, esta ActionBand requiere ColorMaps del tipo TCustomActionBarColorMapEx';
   SDuplicateActionBarStyleName = 'Ya se ha registrado un estilo llamado %s';
   SMissingActionBarStyleName = 'No se ha registrado un estilo llamado %s';
   SStandardStyleActionBars = 'Estilo estándar';
   SXPStyleActionBars = 'Estilo XP';
   SActionBarStyleMissing = 'No hay unidad de estilo ActionBand presente en la cláusula de usos.'#13 +
     'Su aplicación debe incluir XPStyleActnCtrls, StdStyleActnCtrls o ' +
     'una unidad de estilo ActionBand de terceros en su cláusula de usos';
   sParameterCannotBeNil = 'El parámetro %s en la llamada a %s no puede ser nulo';
   SInvalidColorString = 'Cadena de color no válida';
   SInvalidColor = '"%s" Color no válido';
//   SActionManagerNotAssigned = 'La propiedad %s ActionManager no ha sido asignada';
   SInvalidScaleImagePixelFormat = 'Bitmap PixelFormat ha de ser pf24bit ó p32bit';

   SInvalidPath = '"%s" es una ruta no válida';
   SInvalidPathCaption = 'Ruta no válida';

   SANSIEncoding = 'ANSI';
   SASCIIEncoding = 'ASCII';
   SUnicodeEncoding = 'Unicode';
   SBigEndianEncoding = 'Unicode Big Endian';
   SUTF8Encoding  = 'UTF-8';
   SUTF7Encoding  = 'UTF-7';
   SEncodingLabel = 'Codificación:';
   sCannotAddToEmpty = 'Cannot add a control to GridPanel with empty rows and columns';
   sCannotAddFixedSize = 'No se pueden agregar columnas o filas mientras el estilo de expansión sea de tamaño fijo';
   sInvalidSpan = '''%d'' no es un intervalo válido';
   sInvalidRowIndex = 'Índice de fila, %d, fuera de límites';
   sInvalidColumnIndex = 'Índice de columna, %d, fuera de límites';
   sInvalidControlItem = 'ControlItem.Control no puede configurarse como propietario de GridPanel';
   sCannotDeleteColumn = 'No se puede eliminar una columna que contiene controles';
   sCannotDeleteRow = 'No se puede eliminar una fila que contiene controles';
   sCellMember = 'Miembro';
   sCellSizeType = 'Tipo de tamaño';
   sCellValue = 'Valor';
   sCellAutoSize = 'Automático';
   sCellPercentSize = 'Porcentaje';
   sCellAbsoluteSize = 'Absoluto';
   sCellColumn = 'Columna%d';
   sCellRow = 'Fila%d';

   STrayIconRemoveError = 'No se puede eliminar el icono de notificación del shell';
   STrayIconCreateError = 'No se puede crear el icono de notificación del shell';

   SPageControlNotSet = 'Primero se debe asignar PageControl';

   SWindowsVistaRequired = '%s requiere Windows Vista o posterior';
   SXPThemesRequired = '%s requiere que los temas están habilitados';

   STaskDlgButtonCaption = 'Botón%d';
   STaskDlgRadioButtonCaption = 'RadioButón%d';
   SInvalidTaskDlgButtonCaption = 'Caption no puede estar vacío';

   SInvalidCategoryPanelParent = 'CategoryPanel debe tener un CategoryPanelGroup como padre';
   SInvalidCategoryPanelGroupChild = 'Sólo se pueden insertar CategoryPanels en un CategoryPanelGroup';

   SInvalidCanvasOperation = 'Operación de lienzo no válida';
   SNoOwner = '%s no tiene propietario';
   SRequireSameOwner = 'El origen y el destino requieren el mismo propietario';
   SDirect2DInvalidOwner = '%s no puede pertenecer a un lienzo diferente';
   SDirect2DInvalidSolidBrush = 'No es un pincel de color sólido';
   SDirect2DInvalidBrushStyle = 'Estilo de pincel no válido';

   SKeyboardLocaleInfo = 'Error al recuperar la información local';
   SKeyboardLangChange = 'Error al cambiar el idioma de entrada';

   SOlyWinControls = 'Sólo puede acoplar mediante pestañas controles basados en TWinControl';

   SNoKeyword = 'No se ha especificado ningún teclado';

   SStyleLoadError = 'No se puede cargar el estilo ''%s''';
   SStyleLoadErrors = 'No se pueden cargar estilos: %s';
   SStyleRegisterError = 'Estilo ''%s'' ya registrado';
   SStyleClassRegisterError = 'La clase de estilo ''%s'' ya está registrada';
   SStyleNotFound = 'Estilo ''%s'' no encontrado';
   SStyleClassNotFound = 'Clase de estilo ''%s'' no encontrada';
   SStyleInvalidHandle = 'Identificador de estilo no válido';
   SStyleFormatError = 'Formato de estilo no válido';
   SStyleFileDescription = 'Archivo de estilo VCL';
   SStyleHookClassRegistered = 'La clase ''%s'' ya está registrada para ''%s''';
   SStyleHookClassNotRegistered = 'La clase ''%s'' no está registrada para ''%s''';
   SStyleInvalidParameter = '%s parámetro no puede ser nulo';
   SStyleHookClassNotFound = 'No se ha registrado una clase StyleHook para %s';
   SStyleFeatureNotSupported = 'Función no admitida por este estilo';
   SStyleNotRegistered = 'El estilo ''%s'' no está registrado';
   SStyleUnregisterError = 'No se puede cancelar el registro del estilo del sistema';
   SStyleNotRegisteredNoName = 'Estilo no registrado';


   // cadenas ColorToPrettyName
   SNameBlack = 'Negro';
   SNameMaroon = 'Granate';
   SNameGreen = 'Verde';
   SNameOlive = 'Oliva';
   SNameNavy = 'Marina';
   SNamePurple = 'Púrpura';
   SNameTeal = 'Verde azulado';
   SNameGray = 'Gris';
   SNameSilver = 'Plata';
   SNameRed = 'Rojo';
   SNameLime = 'Lime';
   SNameYellow = 'Amarillo';
   SNameBlue = 'Azul';
   SNameFuchsia = 'Fucsia';
   SNameAqua = 'Agua';
   SNameWhite = 'Blanco';
   SNameMoneyGreen = 'Verde Dólar';
   SNameSkyBlue = 'Azul cielo';
   SNameCream = 'Crema';
   SNameMedGray = 'Gris medio';
   SNameActiveBorder = 'Borde activo';
   SNameActiveCaption = 'Título activo';
   SNameAppWorkSpace = 'Espacio de trabajo de la aplicación';
   SNameBackground = 'Fondo';
   SNameBtnFace = 'Face del botón';
   SNameBtnHighlight = 'Botón resaltado';
   SNameBtnShadow = 'Sombra de botón';
   SNameBtnText = 'Texto del botón';
   SNameCaptionText = 'Texto del título';
   SNameDefault = 'Predeterminado';
   SNameGradientActiveCaption = 'Subtítulo activo de degradado';
   SNameGradientInactiveCaption = 'Subtítulo inactivo de gradiente';
   SNameGrayText = 'Texto gris';
   SNameHighlight = 'Resaltar fondo';
   SNameHighlightText = 'Texto resaltado';
   SNameHotLight = 'Luz Caliente';
   SNameInactiveBorder = 'Borde inactivo';
   SNameInactiveCaption = 'Título inactivo';
   SNameInactiveCaptionText = 'Texto de título inactivo';
   SNameInfoBk = 'Antecedentes de información';
   SNameInfoText = 'Texto informativo';
   SNameMenu = 'Fondo del menú';
   SNameMenuBar = 'Barra de menú';
   SNameMenuHighlight = 'Menú resaltado';
   SNameMenuText = 'Texto del menú';
   SNameNone = 'Ninguno';
   SNameScrollBar = 'Barra de desplazamiento';
   SName3DDkShadow = 'Sombra oscura 3D';
   SName3DLight = 'Luz 3D';
   SNameWindow = 'Fondo de la ventana';
   SNameWindowFrame = 'Marco de ventana';
   SNameWindowText = 'Texto de la ventana';

   SInvalidBitmapPixelFormat = 'Formato de píxeles de mapa de bits no válido, debe ser una imagen de 32 bits';
   SJumplistsItemErrorGetpsi = 'Consultando la interfaz IPropertyStore';
   SJumplistsItemErrorInitializepropvar = 'Inicializando una propiedad variante';
   SJumplistsItemErrorSetps = 'Establecer el valor de un almacén de propiedades';
   SJumplistsItemErrorCommitps = 'Confirmando un almacén de propiedades';
   SJumplistsItemErrorSettingarguments = 'Configurar los argumentos de un elemento de la jumplist';
   SJumplistsItemErrorSettingpath = 'Configurar la ruta de un elemento de la jumplist';
   SJumplistsItemErrorSettingicon = 'Configurar la ubicación del icono de un elemento de la jumplist';
   SJumplistsItemErrorAddingtobjarr = 'Agregar un elemento a una matriz de objetos';
   SJumplistsItemErrorGettingobjarr = 'Consultando la interfaz IObjectArray';
   SJumplistsItemErrorNofriendlyname = 'La propiedad FriendlyName de un elemento no debe estar vacía';
   SJumplistsItemException = 'Excepción JumpListItem: Error %d: %s';
   SJumplistException = 'Excepción de JumpList: Error %d: %s';
   SJumplistErrorBeginlist = 'Iniciando una sesión de creación para una nueva jumplist';
   SJumplistErrorAppendrc = 'Agregando un elemento a la categoría de archivos recientes de una nueva jumplist';
   SJumplistErrorAppendfc = 'Agregando un elemento a la categoría de archivos frecuentes de una nueva jumplist';
   SJumplistErrorAddusertasks = 'Añadiendo sus tareas a una nueva jumplist';
   SJumplistErrorAddcategory = 'Agregar una categoría personalizada (''%s'') y sus elementos secundarios a una nueva jumplist';
   SJumplistErrorCommitlist = 'Commitiendo una nueva jumplist';
   SJumplistExceptionInvalidOS = 'El sistema operativo actual no admite jumplist';
//   SJumplistExceptionAppID = 'El proceso actual ya tiene un ID de aplicación';

   { BeginInvoke }

   sBeginInvokeNoHandle = 'No se puede llamar a BeginInvoke en un control sin padre o identificador de ventana';

   SToggleSwitchCaptionOn = 'Activado';
   SToggleSwitchCaptionOff = 'Desactivado';
   SInvalidRelativePanelControlItem = 'ControlItem.Control no puede configurarse como propietario de RelativePanel';
   SInvalidRelativePanelSibling = 'El control no es un hermano dentro de RelativePanel';
   SInvalidRelativePanelSiblingSelf = 'El control no se puede posicionar con respecto a sí mismo';
   SRelativePanelCircularDependency = 'Error de Panel relativo: Se detectó dependencia circular. No se pudo completar el diseño';


  // --- Constantes de la sección general que faltaban ---
  SInRemoteSession = 'No se puede cambiar SingleBufferingInRemoteSessions en una sesión remota';

  // --- Corrección para SJumplistExceptionAppID (faltaba el parámetro %s) ---
  SJumplistExceptionAppID = 'El proceso actual ya tiene un ID de aplicación: %s';

  // --- Sección Vcl.WinXPanels (CardPanel) ---
  SInvalidCardPanelActiveCardIndex = 'El índice de tarjeta de CardPanel está fuera de rango';
  SInvalidCardPanelActiveCard = 'CardPanel.ActiveCard no puede ser nulo';

  // --- Sección Vcl.ControlList ---
  SGraphicControlAcceptedOnly = 'ControlList solo admite descendientes de la clase TGraphicControl';

  // --- Nota adicional: También faltaba esta en la sección de ActionBars ---
  SActionManagerNotAssigned = 'La propiedad ActionManager de %s no ha sido asignada';
  implementation

  end.


