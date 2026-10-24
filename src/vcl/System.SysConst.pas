{*******************************************************}
{                                                       }
{           Biblioteca de Tiempo de Ejecución Delphi    }
{                                                       }
{ Derechos de autor (c) 1995-2019 Embarcadero Technologies, Inc. }
{              Todos los derechos reservados            }
{                                                       }
{*******************************************************}

unit System.SysConst;
{$WARN IMPLICIT_STRING_CAST OFF}
{$IFDEF ANDROID}
{$define USE_LIBICU}
{$ENDIF ANDROID}


{$IFDEF LINUX}
  {$DEFINE USE_LIBICU}
{$ENDIF LINUX}

interface
{$HPPEMIT LEGACYHPP}

resourcestring
  SUnknown = '<desconocido>';
  SInvalidInteger = '''%s'' no es un valor entero válido';
  SInvalidInteger2 = '''%s'' no es un valor entero válido para el tipo %s';
  SInvalidFloat = '''%s'' no es un valor de punto flotante válido';
  SInvalidFloat2 = '''%s'' no es un valor de punto flotante válido para el tipo %s';
  SInvalidCurrency = '''%s'' no es un valor de moneda válido';
  SInvalidDate = '''%s'' no es una fecha válida';
  SInvalidTime = '''%s'' no es una hora válida';
  SInvalidDateTime = '''%s'' no es una fecha y hora válidas';
  SInvalidDateTimeFloat = '''%g'' no es una fecha y hora válidas';
  SInvalidTimeStamp = '''%d.%d'' no es un sello de tiempo válido';
  SInvalidGUID = '''%s'' no es un valor de GUID válido';
  SInvalidBoolean = '''%s'' no es un valor booleano válido';
  STimeEncodeError = 'Argumento no válido para codificar tiempo';
  SDateEncodeError = 'Argumento no válido para codificar fecha';
  SOutOfMemory = 'Memoria agotada';
  SInOutError = 'Error de E/S %d';
  SFileNotFound = 'Archivo no encontrado';
  SInvalidFilename = 'Nombre de archivo no válido' deprecated 'Usar SInvalidUnknownFilename';
  SInvalidUnknownFilename = 'Nombre de archivo no válido';
  STooManyOpenFiles = 'Demasiados archivos abiertos';
  SAccessDenied = 'Acceso denegado al archivo';
  SEndOfFile = 'Lectura más allá del final del archivo';
  SDiskFull = 'Disco lleno';
  SInvalidInput = 'Entrada numérica no válida';
  SDivByZero = 'División por cero';
  SRangeError = 'Error de comprobación de rango';
  SIntOverflow = 'Desbordamiento de entero';
  SInvalidOp = 'Operación de punto flotante no válida';
  SZeroDivide = 'División de punto flotante por cero';
  SOverflow = 'Sobreflujo de punto flotante';
  SUnderflow = 'Subflujo de punto flotante';
  SInvalidPointer = 'Operación de puntero no válida';
  SInvalidCast = 'Conversión de tipo de clase no válida';
{$IFDEF MSWINDOWS}
  SAccessViolationArg3 = 'Violación de acceso en dirección %p. %s de dirección %p';
{$ENDIF MSWINDOWS}
{$IF Defined(LINUX) or Defined(MACOS) or Defined(ANDROID)}
  SAccessViolationArg2 = 'Violación de acceso en dirección %p, accediendo a dirección %p';
{$ENDIF LINUX or MACOS or ANDROID}
  SAccessViolationNoArg = 'Violación de acceso';
  SStackOverflow = 'Desbordamiento de pila';
  SControlC = 'Se presionó Ctrl+C';
  SQuit = 'Se presionó la tecla de salida';
  SPrivilege = 'Instrucción privilegiada';
  SOperationAborted = 'Operación abortada';
  SException = 'Excepción %s en el módulo %s en %p.' + sLineBreak + '%s%s' + sLineBreak;
  SExceptTitle = 'Error de la aplicación';
{$IF Defined(LINUX) or Defined(MACOS) or Defined(ANDROID)}
  SSigactionFailed = 'Error en la llamada de sigaction';
  SOSExceptionHandlingFailed = 'Falló la inicialización del manejo de excepciones del sistema operativo';
{$ENDIF LINUX or MACOS or ANDROID}
  SInvalidFormat = 'Formato ''%s'' inválido o incompatible con el argumento';
  SArgumentMissing = 'Ningún argumento para el formato ''%s''';
  SDispatchError = 'Llamadas a métodos de variantes no soportadas';
  SReadAccess = 'Lectura';
  SWriteAccess = 'Escritura';
  SExecuteAccess = 'Ejecución';
  SInvalidAccess = 'Acceso no válido';
  SResultTooLong = 'Resultado del formato mayor a 4096 caracteres';
  SFormatTooLong = 'Cadena de formato demasiado larga';
{$IFDEF MACOS}
  SCFStringFailed = 'Error al crear CFString';
{$ENDIF MACOS}
{$IF defined(USE_LIBICU)}
  SICUError = 'Error de ICU: %d, %s';
  SICUErrorOverflow = 'Error de sobreflujo de ICU: %d, %s, Longitud necesaria=%d';
{$ENDIF defined(USE_LIBICU)}

  SVarArrayCreate = 'Error al crear una variante o matriz segura';
  SVarArrayBounds = 'Índice de variante o matriz segura fuera de límites';
  SVarArrayLocked = 'Variante o matriz segura bloqueada';
  SVarArrayWithHResult = 'Error inesperado de variante o matriz segura: %s%.8x';

  SInvalidVarCast = 'Conversión de tipo de variante no válida';
  SInvalidVarOp = 'Operación de variante no válida';
  SInvalidVarNullOp = 'Operación nula de variante no válida';
  SInvalidVarOpWithHResultWithPrefix = 'Operación de variante no válida (%s%.8x)'#10'%s';
  SVarTypeRangeCheck1 = 'Error de comprobación de rango para variante de tipo (%s)';
  SVarTypeRangeCheck2 = 'Error de comprobación de rango al convertir variante de tipo (%s) a tipo (%s)';
  SVarTypeOutOfRangeWithPrefix = 'El tipo de variante personalizada (%s%.4x) está fuera de rango';
  SVarTypeAlreadyUsedWithPrefix = 'El tipo de variante personalizada (%s%.4x) ya ha sido usado por %s';
  SVarTypeNotUsableWithPrefix = 'El tipo de variante personalizada (%s%.4x) no es utilizable';
  SVarTypeTooManyCustom = 'Se han registrado demasiados tipos de variantes personalizadas';

  // los siguientes ya no se usan
  SVarNotArray = 'La variante no es una matriz' deprecated; // no utilizado, usar SVarInvalid en su lugar
  SVarTypeUnknown = 'Tipo de variante personalizada desconocido ($%.4x)' deprecated; // ya no se usa
  SVarTypeOutOfRange = 'Tipo de variante personalizada ($%.4x) está fuera de rango' deprecated;
  SVarTypeAlreadyUsed = 'Tipo de variante personalizada ($%.4x) ya usado por %s' deprecated;
  SVarTypeNotUsable = 'Tipo de variante personalizada ($%.4x) no es utilizable' deprecated;
  SInvalidVarOpWithHResult = 'Operación de variante no válida ($%.8x)' deprecated;

  SVarTypeCouldNotConvert = 'No se pudo convertir la variante de tipo (%s) a tipo (%s)';
  SVarTypeConvertOverflow = 'Sobreflujo al convertir variante de tipo (%s) a tipo (%s)';
  SVarOverflow = 'Sobreflujo de variante';
  SVarInvalid = 'Argumento no válido';
  SVarBadType = 'Tipo de variante no válido';
  SVarNotImplemented = 'Operación no compatible';
  SVarOutOfMemory = 'Operación de variante se quedó sin memoria';
  SVarUnexpected = 'Error inesperado de variante';

  SVarDataClearRecursing = 'Recursión al realizar VarDataClear';
  SVarDataCopyRecursing = 'Recursión al realizar VarDataCopy';
  SVarDataCopyNoIndRecursing = 'Recursión al realizar VarDataCopyNoInd';
  SVarDataInitRecursing = 'Recursión al realizar VarDataInit';
  SVarDataCastToRecursing = 'Recursión al realizar VarDataCastTo';
  SVarIsEmpty = 'La variante está vacía';
  sUnknownFromType = 'No se puede convertir desde el tipo especificado';
  sUnknownToType = 'No se puede convertir al tipo especificado';
  SExternalException = 'Excepción externa %x';
  SAssertionFailed = 'La aserción falló';
  SIntfCastError = 'Interfaz no compatible';
  SSafecallException = 'Excepción en método de safecall';
  SMonitorLockException = 'Bloqueo de objeto no poseído';
  SNoMonitorSupportException = 'Función de soporte de monitoreo no inicializada';
  SAggregateException = '%d excepción (s):';
  SNotImplemented = 'Característica no implementada';
  SObjectDisposed = 'Método llamado en objeto descartado';
  SAssertError = '%s (%s, línea %d)';
  SAbstractError = 'Error abstracto';
  SModuleAccessViolation = 'Violación de acceso en dirección %p en módulo ''%s''. %s de dirección %p';
  SCannotReadPackageInfo = 'No se puede acceder a la información del paquete para el paquete ''%s''';
  sErrorLoadingPackage = 'No se puede cargar el paquete %s.'+sLineBreak+'%s';
  SInvalidPackageFile = 'Archivo de paquete no válido ''%s''';
  SInvalidPackageHandle = 'Manejo de paquete no válido';
  SDuplicatePackageUnit = 'No se puede cargar el paquete ''%s''. Contiene la unidad ''%s'', ' +
    'que también está contenida en el paquete ''%s''';
  SOSError = 'Error del sistema.  Código: %d.'+sLineBreak+'%s%s';
  SUnkOSError = 'Falló una llamada a una función del SO';
{$IFDEF MSWINDOWS}
  SWin32Error = 'Error Win32.  Código: %d.'#10'%s' deprecated 'Usar SOSError';
  SUnkWin32Error = 'Falló una función de la API de Win32' deprecated 'Usar SUnkOSError';
{$ENDIF}
  SNL = 'La aplicación no está licenciada para usar esta función';

  SShortMonthNameJan = 'Ene';
  SShortMonthNameFeb = 'Feb';
  SShortMonthNameMar = 'Mar';
  SShortMonthNameApr = 'Abr';
  SShortMonthNameMay = 'May';
  SShortMonthNameJun = 'Jun';
  SShortMonthNameJul = 'Jul';
  SShortMonthNameAug = 'Ago';
  SShortMonthNameSep = 'Sep';
  SShortMonthNameOct = 'Oct';
  SShortMonthNameNov = 'Nov';
  SShortMonthNameDec = 'Dic';

  SLongMonthNameJan = 'Enero';
  SLongMonthNameFeb = 'Febrero';
  SLongMonthNameMar = 'Marzo';
  SLongMonthNameApr = 'Abril';
  SLongMonthNameMay = 'Mayo';
  SLongMonthNameJun = 'Junio';
  SLongMonthNameJul = 'Julio';
  SLongMonthNameAug = 'Agosto';
  SLongMonthNameSep = 'Septiembre';
  SLongMonthNameOct = 'Octubre';
  SLongMonthNameNov = 'Noviembre';
  SLongMonthNameDec = 'Diciembre';

  SShortDayNameSun = 'Dom';
  SShortDayNameMon = 'Lun';
  SShortDayNameTue = 'Mar';
  SShortDayNameWed = 'Mié';
  SShortDayNameThu = 'Jue';
  SShortDayNameFri = 'Vie';
  SShortDayNameSat = 'Sáb';

  SLongDayNameSun = 'Domingo';
  SLongDayNameMon = 'Lunes';
  SLongDayNameTue = 'Martes';
  SLongDayNameWed = 'Miércoles';
  SLongDayNameThu = 'Jueves';
  SLongDayNameFri = 'Viernes';
  SLongDayNameSat = 'Sábado';

{$IFDEF POSIX}
  SEraEntries = '';
{$ENDIF}

  SCannotCreateDir = 'No se puede crear el directorio';
  SCodesetConversionError = 'Fallo en la conversión del conjunto de códigos';

  // Usado por TEncoding
  SInvalidSourceArray = 'Matriz de origen no válida';
  SInvalidDestinationArray = 'Matriz de destino no válida';
  SCharIndexOutOfBounds = 'Índice de carácter fuera de límites (%d)';
  SByteIndexOutOfBounds = 'Índice de inicio fuera de límites (%d)';
  SInvalidCharCount = 'Recuento no válido (%d)';
  SInvalidDestinationIndex = 'Índice de destino no válido (%d)';
  SInvalidCodePage = 'Página de códigos no válida';
  SInvalidEncodingName = 'Nombre de codificación no válido';
  SNoMappingForUnicodeCharacter = 'No existe asignación para el carácter Unicode en la página de códigos multi-byte objetivo';
  SInvalidStringBaseIndex = 'Índice de base de cadena no válido';
  SOperationCancelled = 'Operación Cancelada';

implementation

end.
