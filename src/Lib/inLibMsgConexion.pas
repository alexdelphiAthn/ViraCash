{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgConexion                                             }
{    Tipo:       Librería de mensajes                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes traducibles de perfiles, credenciales y conexiones de BBDD.     }
{******************************************************************************}
unit inLibMsgConexion;

interface

resourcestring
  SErrorMotorBBDDNoReconocido =
    'Motor de base de datos no reconocido.';
  SErrorMotorBBDDNoSoportado =
    'El motor de base de datos "%s" no está soportado.';
  SErrorModoSSLNoSoportado =
    'El modo SSL "%s" no está soportado.';
  SErrorValorPerfilNoBooleano =
    'El valor %s.%s no es booleano.';
  SErrorValorPerfilNoEntero =
    'El valor %s.%s no es un número entero.';
  SErrorRutaPerfilConexionObligatoria =
    'La ruta del perfil de conexión es obligatoria.';
  SErrorPerfilConexionNoValido =
    'El perfil de conexión no es válido: %s.';
  SErrorReferenciaCredencialObligatoria =
    'La referencia de credencial es obligatoria.';
  SErrorReferenciaCredencialAjena =
    'La referencia de credencial no pertenece a ViraCash.';
  SErrorCredencialLegadaInvalida =
    'La credencial de conexión legada no se puede descifrar.';
  SErrorLeerCredencialConexion =
    'No se pudo leer la credencial de conexión (error %d).';
  SErrorFormatoCredencialConexion =
    'La credencial de conexión almacenada no tiene un formato válido.';
  SErrorGuardarCredencialConexion =
    'No se pudo guardar la credencial de conexión (error %d).';
  SErrorEliminarCredencialConexion =
    'No se pudo eliminar la credencial de conexión (error %d).';
  SErrorEliminarCredencialLegadaIni =
    'No se pudo retirar la credencial legada del perfil de conexión.';
  SErrorGuardarCredencialIni =
    'No se pudo guardar la credencial en el perfil de conexión.';
  SValidacionMotorBBDD =
    'El motor de base de datos no es válido';
  SValidacionIdPerfilConexion =
    'El identificador del perfil es obligatorio';
  SValidacionServidorConexion =
    'El servidor es obligatorio';
  SValidacionPuertoConexion =
    'El puerto debe estar entre 1 y 65535';
  SValidacionBaseDatosConexion =
    'La base de datos es obligatoria';
  SValidacionEsquemaPostgreSQL =
    'El esquema es obligatorio para PostgreSQL';
  SValidacionEsquemaMotor =
    'El esquema es obligatorio para el motor seleccionado';
  SValidacionUsuarioConexion =
    'El usuario es obligatorio';
  SValidacionModoSSLConexion =
    'El modo SSL no es válido';
  SValidacionTimeoutConexion =
    'El timeout de conexión debe ser mayor que cero';
  SValidacionTimeoutComando =
    'El timeout de comando debe ser mayor que cero';
  SValidacionPoolMinimoNegativo =
    'El mínimo del pool no puede ser negativo';
  SValidacionPoolMaximoNegativo =
    'El máximo del pool no puede ser negativo';
  SValidacionPoolEsperaNegativa =
    'La espera del pool no puede ser negativa';
  SValidacionPoolVidaNegativa =
    'La vida de una conexión no puede ser negativa';
  SValidacionPoolVidaFueraDeRango =
    'La vida de una conexión supera el máximo admitido';
  SValidacionPoolMaximoCero =
    'El máximo del pool debe ser mayor que cero';
  SValidacionPoolMinimoMayorMaximo =
    'El mínimo del pool no puede superar al máximo';
  SValidacionPoolEsperaCero =
    'La espera del pool debe ser mayor que cero';
  SValidacionCertificadosSinSSL =
    'No se admiten certificados con SSL desactivado';
  SValidacionCertificadoCA =
    'La verificación SSL necesita un certificado de CA';
  SValidacionCertificadoCliente =
    'El certificado de cliente y su clave deben indicarse juntos';
  SDescripcionPerfilConexion =
    '%s [%s] %s:%d/%s%s; ssl=%s';
  SDescripcionEsquemaConexion =
    '; esquema=%s';
  SErrorConexionPrincipalNoAsignada =
    'La conexión principal no está asignada.';
  SErrorFabricaConexionesNoAsignada =
    'La fábrica de conexiones no está asignada.';
  SErrorFabricaSinRutaConfiguracion =
    'La fábrica de conexiones no tiene una ruta de configuración.';
  SErrorConexionNoAsignada =
    'La conexión no está asignada.';
  SErrorSSLMySQLNoSoportado =
    'El modo SSL %s no está soportado de forma segura por el adaptador ' +
    'MariaDB/MySQL actual.';
  SErrorSSLPostgreSQLVerificacionCompletaNoDisponible =
    'La verificación SSL completa de PostgreSQL requiere SecureBridge y ' +
    'no está disponible en el adaptador actual.';
  SErrorConsultaCampoDesconocido =
    'La consulta contiene un campo desconocido.';
  SErrorConsultaTablaNoExiste =
    'La tabla consultada no existe en la base de datos.';
  SErrorConsultaTablaYaExiste =
    'La tabla o vista ya existe en la base de datos.';
  SErrorConsultaProcedimientoYaExiste =
    'El procedimiento o función ya existe en la base de datos.';
  SErrorConexionServidorMotor =
    'No se puede conectar al servidor de base de datos. Compruebe la red ' +
    'y el puerto.';
  SErrorConexionPerdidaMotor =
    'La conexión con el servidor de base de datos se ha perdido.';
  SErrorConexionMotorSinDetalle =
    'Se produjo un error en la base de datos (código %d).';
  SDetalleErrorMotorBBDD =
    ' Detalle %s (%d): %s';

implementation

end.
