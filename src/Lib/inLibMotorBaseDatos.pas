{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMotorBaseDatos                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Motor y versión del servidor de la base de datos (parámetro               }
{    appMotorBaseDatos, en Base de datos): MariaDB 12.13, MariaDB 10.14 o      }
{    MySQL 8.0.41. Los scripts publicados y factuzam_original.sql están        }
{    escritos para MariaDB 12.13; con los otros dos, el actualizador los pasa  }
{    por DBComparer antes de aplicarlos y le da ese destino a la comparación.  }
{    Antes de actualizar se contrasta con lo que dice el servidor (VERSION()): }
{    si no cuadra se avisa y, si el servidor es de un motor admitido, se       }
{    propone cambiar el parámetro.                                             }
{******************************************************************************}
unit inLibMotorBaseDatos;

interface

const
  PARAMETRO_MOTOR_BASE_DATOS = 'appMotorBaseDatos';
  // Valores del parámetro, tal como se guardan y se ven en la lista.
  MOTOR_BASE_DATOS_MARIADB1213 = 'mariadb1213';
  MOTOR_BASE_DATOS_MARIADB1014 = 'mariadb1014';
  MOTOR_BASE_DATOS_MYSQL8041 = 'mysql8041';

type
  TMotorBaseDatos = (
    // El de los scripts y el modelo: no hay nada que convertir.
    mbdMariaDB1213,
    mbdMariaDB1014,
    mbdMySQL8041);

  TCoincidenciaMotorServidor = (
    // El servidor es del motor del parámetro.
    cmsCoincide,
    // Es de otro motor admitido: se puede proponer el cambio.
    cmsOtroMotor,
    // Se sabe qué es, pero no es ninguno de los admitidos.
    cmsNoAdmitido,
    // No hay versión que mirar.
    cmsDesconocido);

// Motor del texto guardado en el parámetro; vacío o desconocido = MariaDB
// 12.13, el de siempre.
function MotorBaseDatosDeTexto(const ATexto: string): TMotorBaseDatos;
function TextoMotorBaseDatos(AMotor: TMotorBaseDatos): string;
// Nombre para las personas: «MariaDB 12.13», «MySQL 8.0.41»...
function DescripcionMotorBaseDatos(AMotor: TMotorBaseDatos): string;
// Dialecto de DBComparer (--destino): mariadb12, mariadb10 o mysql841.
function DestinoComparadorMotor(AMotor: TMotorBaseDatos): string;
// True si los scripts publicados (MariaDB 12.13) hay que convertirlos
// antes de aplicarlos en este motor.
function MotorRequiereConversion(AMotor: TMotorBaseDatos): Boolean;
// Contrasta el motor del parámetro con lo que devuelve SELECT VERSION():
// «12.3.1-MariaDB», «10.11.8-MariaDB-log», «8.0.41»... Una MariaDB 11 o
// posterior cuenta como la 12.13 (misma sintaxis, como en DBComparer);
// MySQL solo el 8. Con cmsOtroMotor, AMotorServidor es el que toca.
function CompararMotorConServidor(
  AMotor: TMotorBaseDatos;
  const AVersionServidor: string;
  out AMotorServidor: TMotorBaseDatos): TCoincidenciaMotorServidor;

implementation

uses
  System.StrUtils,
  System.SysUtils;

const
  cTextosMotor: array[TMotorBaseDatos] of string = (
    MOTOR_BASE_DATOS_MARIADB1213,
    MOTOR_BASE_DATOS_MARIADB1014,
    MOTOR_BASE_DATOS_MYSQL8041);
  cDescripcionesMotor: array[TMotorBaseDatos] of string = (
    'MariaDB 12.13',
    'MariaDB 10.14',
    'MySQL 8.0.41');
  cDestinosComparador: array[TMotorBaseDatos] of string = (
    'mariadb12',
    'mariadb10',
    'mysql841');

function MotorBaseDatosDeTexto(const ATexto: string): TMotorBaseDatos;
var
  Motor: TMotorBaseDatos;
begin
  Result := mbdMariaDB1213;
  for Motor := Low(TMotorBaseDatos) to High(TMotorBaseDatos) do
  begin
    if SameText(Trim(ATexto), cTextosMotor[Motor]) then
      Result := Motor;
  end;
end;

function TextoMotorBaseDatos(AMotor: TMotorBaseDatos): string;
begin
  Result := cTextosMotor[AMotor];
end;

function DescripcionMotorBaseDatos(AMotor: TMotorBaseDatos): string;
begin
  Result := cDescripcionesMotor[AMotor];
end;

function DestinoComparadorMotor(AMotor: TMotorBaseDatos): string;
begin
  Result := cDestinosComparador[AMotor];
end;

function MotorRequiereConversion(AMotor: TMotorBaseDatos): Boolean;
begin
  Result := AMotor <> mbdMariaDB1213;
end;

function VersionPrincipal(const AVersion: string): Integer;
var
  iFin: Integer;
begin
  iFin := 1;
  while (iFin <= Length(AVersion)) and
        CharInSet(AVersion[iFin], ['0'..'9']) do
    Inc(iFin);
  Result := StrToIntDef(Copy(AVersion, 1, iFin - 1), 0);
end;

// Motor admitido que corresponde a la versión; False si no es ninguno.
function MotorDeVersion(
  const AVersion: string;
  out AMotor: TMotorBaseDatos): Boolean;
var
  iPrincipal: Integer;
begin
  AMotor := mbdMariaDB1213;
  iPrincipal := VersionPrincipal(AVersion);
  if ContainsText(AVersion, 'mariadb') then
  begin
    Result := iPrincipal >= 10;
    if iPrincipal = 10 then
      AMotor := mbdMariaDB1014;
  end
  else
  begin
    Result := iPrincipal = 8;
    AMotor := mbdMySQL8041;
  end;
end;

function CompararMotorConServidor(
  AMotor: TMotorBaseDatos;
  const AVersionServidor: string;
  out AMotorServidor: TMotorBaseDatos): TCoincidenciaMotorServidor;
var
  sVersion: string;
begin
  sVersion := Trim(AVersionServidor);
  // Hay MariaDB que se anuncian con 5.5.5- delante por compatibilidad.
  if StartsText('5.5.5-', sVersion) then
    sVersion := Copy(sVersion, Length('5.5.5-') + 1, MaxInt);
  AMotorServidor := AMotor;
  if sVersion = '' then
    Result := cmsDesconocido
  else if not MotorDeVersion(sVersion, AMotorServidor) then
  begin
    AMotorServidor := AMotor;
    Result := cmsNoAdmitido;
  end
  else if AMotorServidor = AMotor then
    Result := cmsCoincide
  else
    Result := cmsOtroMotor;
end;

end.
