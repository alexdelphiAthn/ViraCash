{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgVerificacionNif                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Textos de la verificación de NIF en la AEAT (FZ-ISSUE-131).               }
{******************************************************************************}
unit inLibMsgVerificacionNif;

interface

resourcestring
  SCaptionBotonVerificarNif = 'AEAT';
  SHintBotonVerificarNif = 'Verificar el NIF en el censo de la AEAT';
  STituloVerificacionNif = 'Verificación de NIF en la AEAT';
  SCaptionVerificacionNifEnviado = 'Enviado:';
  SCaptionVerificacionNifAeat = 'AEAT:';
  SCaptionVerificacionNifResultado = 'Resultado:';
  SCaptionUsarRazonSocialAeat = 'Usar razón social de la AEAT';
  SCaptionCerrarVerificacionNif = 'Cerrar';
  SVerificacionNifCorrecta =
    'El NIF está identificado en la AEAT y los datos coinciden.';
  SVerificacionNifNoIdentificado =
    'La AEAT no identifica este NIF con ese nombre. Revíselo antes ' +
    'de emitir facturas a este cliente.';
  SVerificacionNifRevocado =
    'El NIF está REVOCADO en la AEAT.';
  SVerificacionNifBaja =
    'El NIF figura de BAJA en la AEAT.';
  SVerificacionNifOtro =
    'Respuesta de la AEAT no habitual; revise el resultado.';
  SVerificacionNifNifDistinto =
    'La AEAT ha identificado el NIF %s, distinto del enviado (%s): ' +
    'el número casa con otro contribuyente.';
  SVerificacionNifNombreDistinto =
    'La razón social oficial no coincide con la enviada.';
  SErrorVerificacionNifVacio =
    'Indique el NIF antes de verificarlo.';
  SErrorVerificacionNifSinEmpresa =
    'No hay empresa para firmar la consulta a la AEAT.';
  SErrorVerificacionNifSinCertificado =
    'La empresa %s no tiene certificado digital configurado: es ' +
    'necesario para consultar la AEAT.';
  SErrorVerificacionNifRespuesta =
    'La AEAT no ha devuelto un resultado válido (HTTP %d). %s';
  SErrorVerificacionNifFallo =
    'No se ha podido verificar el NIF: %s';
  // Facturas intracomunitarias: NIF-IVA en VIES (ROI).
  SCaptionBotonVerificarRoi = 'ROI';
  SHintBotonVerificarRoi =
    'Verificar el NIF-IVA intracomunitario en VIES (ROI)';
  SErrorVerificacionRoiPaisNoUE =
    'El país del cliente (%s) no es de la Unión Europea: indique el ' +
    'NIF-IVA con el prefijo del país (FR, DE, IT...).';
  SVerificacionRoiValido =
    'El NIF-IVA %s está dado de alta como operador intracomunitario.';
  SVerificacionRoiDatos = 'Nombre: %s' + sLineBreak + 'Dirección: %s';
  SVerificacionRoiNoValido =
    'El NIF-IVA %s NO figura como operador intracomunitario en VIES. ' +
    'La entrega no puede facturarse exenta como intracomunitaria.';
  SVerificacionRoiNoDisponible =
    'No se ha podido consultar VIES para el NIF-IVA %s (%s). Inténtelo ' +
    'más tarde.';
  SConsolidarRoiNoValido =
    'No se consolida la factura: el NIF-IVA %s NO figura como operador ' +
    'intracomunitario en VIES. Corrija el NIF o el tipo de operación.';
  SConsolidarRoiNoDisponible =
    'No se ha podido comprobar en VIES el NIF-IVA %s (%s).' + sLineBreak +
    '¿Consolidar la factura intracomunitaria sin esa comprobación?';

implementation

end.
