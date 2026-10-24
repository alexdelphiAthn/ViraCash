{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgLogon                                                }
{    Tipo:       Librería de mensajes                                          }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes traducibles del proceso de autenticación de la aplicación.      }
{******************************************************************************}
unit inLibMsgLogon;

interface

resourcestring
  SErrorBaseDatosAutenticacionNoDisponible =
    'La base de datos de autenticación no está disponible.';
  SResultadoCredencialesInvalidas =
    'Las credenciales no son válidas.';
  SResultadoAutenticacionCorrecta =
    'Autenticación correcta.';
  SErrorUsuarioNuevoEquipoNoAutorizado =
    'El usuario "%s" no existe, no está activo o no pertenece a un ' +
    'grupo administrador.';
  SErrorContrasenaNuevoEquipoNoVerificada =
    'No se pudo verificar la contraseña nueva del usuario "%s".';
  SErrorContrasenaNuevoEquipoDebeDiferirDemo =
    'La contraseña nueva debe ser distinta de la contraseña inicial de la ' +
    'demo.';
  SAvisoNuevoEquipoDemoYaPreparado =
    'La contraseña inicial de la demo ya había sido cambiada. Continúe con ' +
    'el inicio de sesión.';
  SErrorUbicacionSesionInexistente =
    'El usuario "%s" tiene asignados por defecto datos que no ' +
    'existen en esta base de datos:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'Corríjalos en Otros > Usuarios, Grupos y Perfiles > ' +
    'Usuarios (Almacén / Caja).';
  SErrorUbicacionSesionInexistenteSalir =
    'El usuario "%s" tiene asignados por defecto datos que no ' +
    'existen en esta base de datos:' + sLineBreak + '%s' + sLineBreak +
    sLineBreak + 'No tiene permiso para modificar usuarios: avise a un ' +
    'administrador. El programa se va a cerrar.';
  SUbicacionEmpresaInexistente = '- Empresa "%s"';
  SUbicacionAlmacenInexistente = '- Almacén "%s" (empresa "%s")';
  SUbicacionCajaInexistente = '- Caja "%s" (almacén "%s")';
  SCaptionProcesandoProgresoLogon = 'Procesando';
  SFormatoProgresoTotalLogon = 'Total: %s / %s (%d%%)';

implementation

end.
