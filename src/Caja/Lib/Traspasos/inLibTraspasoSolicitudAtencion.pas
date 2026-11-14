{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTraspasoSolicitudAtencion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       07/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Reglas para atender una solicitud de traspaso (FZ-ISSUE-326): qué         }
{    líneas exigen motivo y las sentencias que registran lo servido y el       }
{    estado de la solicitud. Sin VCL ni base de datos: lo prueba DUnitX y lo   }
{    ejecuta integracion_mariadb/test_traspaso_solicitud_atencion.py.         }
{******************************************************************************}
unit inLibTraspasoSolicitudAtencion;

interface

// True si al servir AServir de una línea con APendiente por servir queda
// algo sin servir (denegada entera o servida en parte): exige motivo.
function LineaSolicitudRequiereMotivo(AServir, APendiente: Double): Boolean;

// UPDATE de una línea con los parámetros :SERV, :MOT, :USU, :NUM, :SER y
// :LIN. ESATENDIDA y MOTIVO se calculan antes de sumar lo servido: MariaDB
// evalúa el SET de izquierda a derecha y, con la suma primero, contaba dos
// veces lo servido y daba por atendida una línea servida en parte.
function SqlLineaSolicitudAtendida: string;

// UPDATE del estado de la cabecera con :NUM, :SER y :USU:
//   nada servido                  -> DENEGADO TOTAL
//   todas las líneas cubiertas    -> COMPLETADO TOTAL
//   el resto (alguna corta o 0)   -> COMPLETADO PARCIAL
function SqlEstadoSolicitudAtendida: string;

implementation

const
  // Tolerancia para cantidades con decimales de la unidad (kg: 3)
  CToleranciaCantidad = 0.0005;

function LineaSolicitudRequiereMotivo(AServir, APendiente: Double): Boolean;
begin
  Result := AServir < APendiente - CToleranciaCantidad;
end;

function SqlLineaSolicitudAtendida: string;
begin
  Result :=
    'UPDATE fza_traspasos_solicitudes_lineas' +
    '   SET ESATENDIDA_TRSOLLIN =' +
    '         IF(CANTIDAD_SERVIDA_TRSOLLIN + :SERV >=' +
    '            CANTIDAD_PEDIDA_TRSOLLIN, ''S'', ''N''),' +
    '       MOTIVO_RECHAZO_TRSOLLIN =' +
    '         IF(CANTIDAD_SERVIDA_TRSOLLIN + :SERV <' +
    '            CANTIDAD_PEDIDA_TRSOLLIN, :MOT, NULL),' +
    '       CANTIDAD_SERVIDA_TRSOLLIN =' +
    '         CANTIDAD_SERVIDA_TRSOLLIN + :SERV,' +
    '       USUARIO_MODIF = :USU' +
    ' WHERE NUMERO_TRSOL_TRSOLLIN = :NUM' +
    '   AND SERIE_TRSOL_TRSOLLIN = :SER' +
    '   AND LINEA_TRSOLLIN = :LIN';
end;

function SqlEstadoSolicitudAtendida: string;
begin
  Result :=
    'UPDATE fza_traspasos_solicitudes' +
    '   SET ESTADO_TRSOL = CASE' +
    '         WHEN (SELECT COUNT(*)' +
    '                 FROM fza_traspasos_solicitudes_lineas L' +
    '                WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM' +
    '                  AND L.SERIE_TRSOL_TRSOLLIN = :SER' +
    '                  AND L.CANTIDAD_SERVIDA_TRSOLLIN > 0) = 0' +
    '           THEN ''DENEGADO TOTAL''' +
    '         WHEN (SELECT COUNT(*)' +
    '                 FROM fza_traspasos_solicitudes_lineas L' +
    '                WHERE L.NUMERO_TRSOL_TRSOLLIN = :NUM' +
    '                  AND L.SERIE_TRSOL_TRSOLLIN = :SER' +
    '                  AND L.CANTIDAD_SERVIDA_TRSOLLIN <' +
    '                      L.CANTIDAD_PEDIDA_TRSOLLIN) = 0' +
    '           THEN ''COMPLETADO TOTAL''' +
    '         ELSE ''COMPLETADO PARCIAL'' END,' +
    '       USUARIO_MODIF = :USU' +
    ' WHERE NUMERO_TRSOL = :NUM AND SERIE_TRSOL = :SER';
end;

end.
