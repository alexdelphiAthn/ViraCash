{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMsgFotos                                               }
{    Tipo:       Recursos de texto                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       26/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mensajes, captions y ayudas del subsistema de fotografías.               }
{******************************************************************************}
unit inLibMsgFotos;

interface

resourcestring
  SErrorFotoNoRegistradaParaPredeterminar =
    'No hay foto registrada para marcar como predeterminada.';
  SErrorFotoSeleccionadaCambio =
    'La foto seleccionada ha cambiado; actualiza la galería e inténtalo ' +
    'de nuevo.';
  SErrorGaleriaFotosCambio =
    'La galería de fotos ha cambiado; actualízala e inténtalo de nuevo.';
  SHintMostrarControlesFoto =
    'Mostrar u ocultar controles (F11)';
  SHintBajarFotosServidor =
    'Bajar fotos del servidor';
  SHintFotoPredeterminada =
    'Establecer esta foto como predeterminada';
  SHintFotoAnterior =
    'Foto anterior';
  SHintFotoSiguiente =
    'Foto siguiente';
  SHintAnadirFoto =
    'Añadir foto';
  SHintResolucionFoto =
    'Resolución de la foto mostrada';
  SCaptionTransparenciaFoto =
    'Transparencia (%)';
  SHintTransparenciaFoto =
    'Transparencia de la ventana: 0 % opaca, hasta 90 % transparente';
  SHintCambiarFotoArticulo =
    'Elegir una foto de variación como predeterminada; si no hay, ' +
    'seleccionar un archivo';
  SHintCambiarFotoNivel =
    'Sustituir la foto predeterminada del nivel seleccionado';
  SHintCambiarFotoLinea =
    'Cambiar la foto de la línea';
  SHintQuitarFoto =
    'Eliminar definitivamente la foto visible';
  SHintRotarFotoIzquierda =
    'Rotar la foto visible a la izquierda';
  SHintRotarFotoDerecha =
    'Rotar la foto visible a la derecha';
  SHintGuardarLayoutFoto =
    'Guardar posición, tamaño, resolución y transparencia';
  SCaptionGaleriaConFotos =
    '%s — Foto %d/%d';
  SCaptionGaleriaSinFotos =
    '%s — Sin fotos';
  SCaptionFotoSesion =
    'Sesión %s/%s · línea %d · %s';
  STituloSeleccionarFotoVariacion =
    'Elegir foto predeterminada';
  SCaptionUsarFotoVariacion =
    'Usar esta foto';
  SCaptionFotoVariacion =
    '%s · Foto %d · %d/%d';
  STituloLayoutFotoArticulo =
    'Foto del artículo / SKU';
  SHintMiniaturaFotoMto =
    'Foto del artículo / SKU de la línea activa. Pulse para abrirla ' +
    '(Ctrl+F)';

implementation

end.
