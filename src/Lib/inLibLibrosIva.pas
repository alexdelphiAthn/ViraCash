{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLibrosIva                                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Dominio del listado «Libros de IVA» (FZ-ISSUE-262): nombres de los        }
{    libros y periodos de liquidación (ejercicio completo, trimestre 1T-4T     }
{    o mes). Sin dependencias de UI ni de BBDD.                                }
{******************************************************************************}
unit inLibLibrosIva;

interface

const
  // Índices de periodo: 0 = ejercicio, 1..4 = trimestres, 5..16 = meses.
  CPeriodoIvaEjercicio = 0;
  CPeriodoIvaPrimerTrimestre = 1;
  CPeriodoIvaUltimoTrimestre = 4;
  CPeriodoIvaPrimerMes = 5;
  CPeriodoIvaUltimoMes = 16;

function NombreLibroIva(const ACodigo: string): string;
function NombresPeriodosLibrosIva: TArray<string>;
procedure RangoPeriodoLibrosIva(AEjercicio, APeriodo: Integer;
  out ADesde, AHasta: TDateTime);
// Periodo que contiene la fecha: el trimestre si APorTrimestre, si no el mes.
function PeriodoDeFechaLibrosIva(AFecha: TDateTime;
  APorTrimestre: Boolean): Integer;

implementation

uses
  System.SysUtils, System.DateUtils,
  inLibInformeLibrosIvaPersistenciaIntf;

resourcestring
  SLibroIvaRepercutido = 'IVA repercutido (ventas)';
  SLibroIvaSoportado = 'IVA soportado (compras)';
  SPeriodoIvaEjercicio = 'Ejercicio completo';
  SPeriodoIvaTrimestre = '%dT - %s trimestre';
  SPeriodoIvaOrdinal1 = '1.er';
  SPeriodoIvaOrdinal2 = '2.º';
  SPeriodoIvaOrdinal3 = '3.er';
  SPeriodoIvaOrdinal4 = '4.º';
  SPeriodoIvaEnero = 'Enero';
  SPeriodoIvaFebrero = 'Febrero';
  SPeriodoIvaMarzo = 'Marzo';
  SPeriodoIvaAbril = 'Abril';
  SPeriodoIvaMayo = 'Mayo';
  SPeriodoIvaJunio = 'Junio';
  SPeriodoIvaJulio = 'Julio';
  SPeriodoIvaAgosto = 'Agosto';
  SPeriodoIvaSeptiembre = 'Septiembre';
  SPeriodoIvaOctubre = 'Octubre';
  SPeriodoIvaNoviembre = 'Noviembre';
  SPeriodoIvaDiciembre = 'Diciembre';

function NombreLibroIva(const ACodigo: string): string;
begin
  if SameText(ACodigo, CLibroIvaRepercutido) then
    Result := SLibroIvaRepercutido
  else if SameText(ACodigo, CLibroIvaSoportado) then
    Result := SLibroIvaSoportado
  else
    Result := ACodigo;
end;

function NombresPeriodosLibrosIva: TArray<string>;
begin
  Result := [
    SPeriodoIvaEjercicio,
    Format(SPeriodoIvaTrimestre, [1, SPeriodoIvaOrdinal1]),
    Format(SPeriodoIvaTrimestre, [2, SPeriodoIvaOrdinal2]),
    Format(SPeriodoIvaTrimestre, [3, SPeriodoIvaOrdinal3]),
    Format(SPeriodoIvaTrimestre, [4, SPeriodoIvaOrdinal4]),
    SPeriodoIvaEnero, SPeriodoIvaFebrero, SPeriodoIvaMarzo,
    SPeriodoIvaAbril, SPeriodoIvaMayo, SPeriodoIvaJunio,
    SPeriodoIvaJulio, SPeriodoIvaAgosto, SPeriodoIvaSeptiembre,
    SPeriodoIvaOctubre, SPeriodoIvaNoviembre, SPeriodoIvaDiciembre];
end;

procedure RangoPeriodoLibrosIva(AEjercicio, APeriodo: Integer;
  out ADesde, AHasta: TDateTime);
var
  iMesInicial: Integer;
  iMeses: Integer;
begin
  if (APeriodo >= CPeriodoIvaPrimerTrimestre) and
     (APeriodo <= CPeriodoIvaUltimoTrimestre) then
  begin
    iMesInicial := (APeriodo - CPeriodoIvaPrimerTrimestre) * 3 + 1;
    iMeses := 3;
  end
  else if (APeriodo >= CPeriodoIvaPrimerMes) and
          (APeriodo <= CPeriodoIvaUltimoMes) then
  begin
    iMesInicial := APeriodo - CPeriodoIvaPrimerMes + 1;
    iMeses := 1;
  end
  else
  begin
    iMesInicial := 1;
    iMeses := 12;
  end;
  ADesde := EncodeDate(AEjercicio, iMesInicial, 1);
  AHasta := IncDay(IncMonth(ADesde, iMeses), -1);
end;

function PeriodoDeFechaLibrosIva(AFecha: TDateTime;
  APorTrimestre: Boolean): Integer;
begin
  if APorTrimestre then
    Result := CPeriodoIvaPrimerTrimestre + (MonthOf(AFecha) - 1) div 3
  else
    Result := CPeriodoIvaPrimerMes + MonthOf(AFecha) - 1;
end;

end.
