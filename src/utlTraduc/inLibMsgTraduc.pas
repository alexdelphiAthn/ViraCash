{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgTraduc                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Textos visibles del editor independiente de traducciones.                 }
{******************************************************************************}
unit inLibMsgTraduc;

interface

resourcestring
  STituloEditorTraducciones =
    'Editor de traducciones de ViraCash';
  SEstadoDesconectado =
    'Sin conexión.';
  SAvisoIniViraCashNoIndicado =
    'Indique el fichero INI de ViraCash.';
  SErrorIniViraCashNoExiste =
    'No existe el INI de ViraCash:' + sLineBreak + '%s';
  SErrorClaveIniViraCash =
    'No se pudo descifrar PasswordEn del INI de ViraCash.';
  SErrorMotorConexionEditorNoSoportado =
    'El editor de traducciones todavía solo admite conexiones MariaDB.';
  SErrorConexion =
    'No se pudo conectar con ViraCash:' + sLineBreak + '%s';
  SInfoConexionCorrecta =
    'Conectado a %s en %s:%d.';
  SErrorTablaTraduccionesNoExiste =
    'La tabla fza_traducciones no existe en la base de datos seleccionada.';
  SAvisoConectarPrimero =
    'Conecte primero con la base de datos de ViraCash.';
  SAvisoIdiomaDestinoNoIndicado =
    'Indique un idioma de destino.';
  SAvisoIdiomaDestinoIgualOrigen =
    'El idioma de destino debe ser distinto de es-ES.';
  SErrorCargarTraducciones =
    'No se pudieron cargar las traducciones:' + sLineBreak + '%s';
  SInfoTraduccionesCargadas =
    '%d textos cargados para %s.';
  SAvisoSinCambiosTraducciones =
    'No hay traducciones modificadas para guardar.';
  SErrorTraduccionVacia =
    'La traducción de la clave "%s" está vacía.';
  SErrorMarcadoresDistintos =
    'La traducción de "%s" no conserva los marcadores de formato.';
  SPreguntaTraduccionesIguales =
    'Hay %d traducciones iguales al texto español.' + sLineBreak +
    '¿Desea guardarlas de todos modos?';
  SErrorGuardarTraducciones =
    'No se pudieron guardar las traducciones:' + sLineBreak + '%s';
  SInfoTraduccionesGuardadas =
    '%d traducciones guardadas.';
  SPreguntaImportarCatalogo =
    'Se sincronizarán en español los resourcestring propios y de VCL, ' +
    'los parámetros dinámicos, los títulos de fza_config_campos, las ' +
    'traducciones de DevExpress y sus personalizaciones. ' +
    '¿Desea continuar?';
  SInfoCatalogoImportado =
    '%d traducciones españolas sincronizadas.';
  SErrorImportarCatalogo =
    'No se pudo sincronizar el catálogo español:' +
    sLineBreak + '%s';

implementation

end.
