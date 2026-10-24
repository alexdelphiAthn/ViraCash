{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgIntegridadEsquema                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes de Ayuda > Comprobar integridad: estructura de la base de        }
{    datos frente al esquema ideal de esta versión.                            }
{******************************************************************************}
unit inLibMsgIntegridadEsquema;

interface

resourcestring
  SIntegridadBotonActualizar = 'Comprobar actualizaciones';
  SIntegridadActualizacionArranque =
    'Puede pulsar Comprobar actualizaciones para actualizar antes de ' +
    'entrar. Se solicitará una copia de seguridad. Al terminar se ' +
    'volverá a comprobar la integridad de la base de datos.';
  SErrorActualizarIntegridadArranque =
    'No se pudo actualizar la base de datos durante el arranque: %s';
  SIntegridadArranqueBloqueado =
    'ViraCash no puede arrancar porque la base de datos no ha superado ' +
    'la comprobación de integridad. El menú Ayuda no está disponible ' +
    'hasta completar el arranque. Envíe este informe al administrador ' +
    'o al soporte para revisar la base de datos y vuelva a iniciar ' +
    'el programa cuando se hayan corregido las incidencias.';
  SErrorComprobarIntegridadArranque =
    'No se ha podido completar la comprobación de integridad: %s';
  STituloComprobarIntegridad = 'Comprobar integridad de la base de datos';
  SInfoComprobandoIntegridad =
    'Comprobando la estructura de la base de datos...';
  SErrorSinEsquemaIdeal =
    'Este programa no lleva el esquema ideal de la base de datos, así que ' +
    'no puede comprobar su integridad.';
  SIntegridadFirma = 'Firma digital del programa: %s';
  SIntegridadFirmaAtencion =
    'ATENCIÓN, firma digital del programa: %s Si no lo ha instalado usted ' +
    'o su distribuidor, no lo use y póngase en contacto con el soporte.';
  SIntegridadCabeceraBase = 'Base de datos: %s';
  SIntegridadCabeceraServidor = 'Servidor: %s';
  SIntegridadCabeceraUsuario = 'Usuario: %s';
  SIntegridadCabeceraModelo =
    'Esquema ideal: %s (generado el %s)';
  SIntegridadHuellaBase = 'Huella de la base:  %s';
  SIntegridadHuellaIdeal = 'Huella del modelo:  %s';
  SIntegridadResultadoIntegra =
    'La estructura de la base de datos coincide con la de esta versión.';
  SIntegridadResultadoObjetosDeMas =
    'La estructura de la base de datos coincide con la de esta versión. ' +
    'Además tiene %d objetos propios que no están en el modelo; no ' +
    'afectan al programa.';
  SIntegridadResultadoDiferencias =
    'La estructura de la base de datos NO coincide con la de esta ' +
    'versión: %d diferencias. Use Ayuda > Comprobar actualizaciones para ' +
    'ponerla al día.';
  SIntegridadResultadoDiferenciasArranque =
    'La estructura de la base de datos NO coincide con la de esta ' +
    'versión: %d diferencias. Si faltan actualizaciones, el ' +
    'administrador o el soporte debe hacer una copia de seguridad y ' +
    'actualizar la base con los scripts oficiales correspondientes ' +
    'a esta versión.';
  SIntegridadResultadoSoloCodigo =
    'Las tablas, vistas y procedimientos coinciden con los de esta ' +
    'versión, pero el código de %d procedimientos es distinto: alguno se ' +
    'ha modificado a mano o lo ha repuesto un script antiguo. Comprobar ' +
    'actualizaciones no lo detecta, porque busca scripts que falten: ' +
    'vuelva a aplicar los scripts que los definen o actualice por ' +
    'comparación.';
  SIntegridadEsquemaIdealDanado =
    'ATENCIÓN: el esquema ideal que lleva el programa no cuadra con sus ' +
    'propias huellas. El ejecutable puede estar dañado: la comprobación ' +
    'no es fiable.';
  SIntegridadCodigoNoComprobado =
    'No hay referencia del código de los procedimientos para este motor; ' +
    'se ha comprobado todo lo demás.';
  SIntegridadSinPermiso =
    'No se han podido comprobar %d elementos (definidores o código de ' +
    'procedimientos): el usuario conectado no tiene permiso para verlos.';
  SIntegridadAjustesIndices =
    'Hay índices distintos de los del modelo (ajustes propios); no ' +
    'cuentan en el resultado.';
  SIntegridadProcedimientoNoInstalado =
    'PRC_FZA_HUELLA_ESQUEMA no está instalado en la base de datos; el ' +
    'programa ha hecho la comprobación por su cuenta.';
  SIntegridadProcedimientoCoherente =
    'PRC_FZA_HUELLA_ESQUEMA da las mismas huellas que el programa.';
  SIntegridadProcedimientoOtraVersion =
    'PRC_FZA_HUELLA_ESQUEMA es de otra versión (%d); no se compara.';
  SIntegridadProcedimientoDistinto =
    'ATENCIÓN: PRC_FZA_HUELLA_ESQUEMA no da las mismas huellas que el ' +
    'programa (%s). Está alterado o desfasado, o ve objetos que el ' +
    'usuario conectado no ve.';
  SIntegridadProcedimientoError =
    'ATENCIÓN: PRC_FZA_HUELLA_ESQUEMA está instalado pero falla: %s';
  SIntegridadProcedimientoNoComparable =
    'PRC_FZA_HUELLA_ESQUEMA no se puede contrastar con este usuario: no ' +
    've todo el catálogo. Para contrastarlo, use un administrador de la ' +
    'base de datos.';
  SIntegridadDetalle = 'Detalle:';
  SIntegridadFalta = 'Falta';
  SIntegridadSobra = 'Sobra';
  SIntegridadDistinto = 'Distinto';
  SIntegridadFirmaIdeal = 'modelo';
  SIntegridadFirmaReal = 'base';
  SIntegridadMasDiferencias = '... y %d diferencias más.';
  SIntegridadApartadoEstructura = 'Tablas';
  SIntegridadApartadoVistas = 'Vistas';
  SIntegridadApartadoRutinas = 'Procedimientos';
  SIntegridadApartadoDefinidores = 'Definidores';
  SIntegridadApartadoCodigo = 'Código de procedimientos';
  SIntegridadApartadoIndices = 'Índices';

implementation

end.
