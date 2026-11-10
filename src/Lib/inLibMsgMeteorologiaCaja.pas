{******************************************************************************}
{                                                                              }
{  Módulo: inLibMsgMeteorologiaCaja                                            }
{  Tipo: Librería                                                              }
{  Versión: 1.0.0                                                              }
{  Fecha: 12/11/2026                                                           }
{  Autor: Alejandro Laorden Hidalgo                                            }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción: Consulta y presentación del tiempo diario de la tienda.        }
{******************************************************************************}
unit inLibMsgMeteorologiaCaja;

interface

resourcestring
  SCaptionMeteoCaja = 'METEO';
  SHintConsultarMeteoCaja =
    'Consultar el tiempo de hoy en el almacén.'#13#10 +
    'Doble clic: abrir ciudad y fechas.';
  SHintTemperaturaMeteoCaja =
    'Temperatura media prevista'#13#10 +
    'Mínima prevista: %s °C'#13#10'Máxima prevista: %s °C';
  STituloHistoricoMeteoCaja = 'Meteorología de la tienda';
  SCiudadHistoricoMeteoCaja = 'Ciudad del almacén';
  SDesdeHistoricoMeteoCaja = 'Fecha inicio';
  SHastaHistoricoMeteoCaja = 'Fecha fin';
  SConsultarHistoricoMeteoCaja = 'Consultar';
  SNotaHistoricoMeteoCaja =
    'Datos: Open-Meteo · CC BY 4.0 · https://open-meteo.com/';
  SErrorRangoHistoricoMeteoCaja =
    'La fecha de inicio debe ser anterior o igual a la fecha de fin.';
  SErrorInicioHistoricoMeteoCaja =
    'El histórico empieza en 1940. Revise el año de la fecha de inicio.';
  SErrorFinPrevisionMeteoCaja =
    'La previsión alcanza hasta %s. Revise la fecha de fin.';
  SErrorConsultaMeteoCancelada = 'Consulta meteorológica cancelada.';
  SHintLluviaHistoricoMeteoCaja = 'Lluvia del día: %s l/m²';
  SFuenteHistoricoMeteoCaja = 'Histórico';
  SFuentePrevisionMeteoCaja = 'Previsión';
  SColFechaMeteoCaja = 'Fecha';
  SColCieloMeteoCaja = 'Cielo';
  SColMediaMeteoCaja = 'Media °C';
  SColMaximaMeteoCaja = 'MAX °C';
  SColMinimaMeteoCaja = 'MIN °C';
  SColNubesMeteoCaja = 'Nubes %';
  SColLluviaMeteoCaja = 'Lluvia mm';
  SHintNubesMeteoCaja = 'Nubosidad media prevista hoy: %s %%';
  SHintLluviaMeteoCaja = 'Lluvia prevista hoy: %s l/m²';
  SHintFuenteMeteoCaja =
    '%s · %s · Previsión diaria'#13#10'Dato guardado para informes.'#13#10 +
    'Datos: Open-Meteo · CC BY 4.0 · https://open-meteo.com/';
  SEstadoConsultandoMeteoCaja = 'Consultando…';
  SEstadoErrorMeteoCaja = 'Sin parte';
  SErrorCiudadMeteoCaja = 'El almacén no tiene ciudad asignada.';
  SErrorApiMeteoCaja =
    'Configure la credencial de Servicios web para consultar METEO.';
  SErrorRespuestaMeteoCaja = 'El servicio devolvió un parte no válido.';
  SErrorLocalidadMeteoCaja =
    'No se ha podido identificar una localidad única para %s (%s).';
  SErrorGuardarMeteoCaja =
    'No se ha guardado el parte meteorológico: %s';
  SErrorEsquemaMeteoCaja =
    'Falta actualizar la BBDD para guardar los partes meteorológicos.';
  STituloObservacionesCaja = 'Cuaderno de bitácora';
  SHintObservacionesCaja = 'Escribir o consultar observaciones del día';
  SCabeceraObservacionesCaja = 'Empresa %s · Almacén %s · %s';
  SGuardarObservacionesCaja = 'Guardar';
  SCancelarObservacionesCaja = 'Cancelar';
  SErrorEsquemaObservacionesCaja =
    'Falta actualizar la BBDD para guardar las observaciones del día.';
  SErrorLongitudObservacionesCaja =
    'Las observaciones no pueden superar los 4000 caracteres.';
  SErrorUbicacionObservacionesCaja =
    'Seleccione una empresa, un almacén y una fecha válidos.';

implementation

end.
