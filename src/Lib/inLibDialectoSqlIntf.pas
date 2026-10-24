{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDialectoSqlIntf                                         }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato puro para componer las diferencias sintácticas entre motores.    }
{    No conoce UniDAC, conexiones, formularios ni lógica de negocio.           }
{******************************************************************************}
unit inLibDialectoSqlIntf;

interface

uses
  inLibConexionPerfilIntf;

type
  TUnidadIntervaloSql = (
    uisSegundo,
    uisMinuto,
    uisHora,
    uisDia,
    uisSemana,
    uisMes,
    uisAnio);

  TComandoInicializacionSesionSql = record
    Texto: string;
    Obligatorio: Boolean;
  end;
  TComandosInicializacionSesionSql =
    array of TComandoInicializacionSesionSql;

  IDialectoExpresionesSql = interface
    ['{A71C1307-0FB3-47F7-A160-104C2EB45E3E}']
    function ExpresionFechaHoraActual: string;
    function ExpresionFechaActual: string;
    function ExpresionSumarFecha(
      const AFecha, AIncremento: string;
      AUnidad: TUnidadIntervaloSql): string;
    function ExpresionPosicionCadena(
      const ABuscado, ATexto: string): string;
    function ExpresionRellenarIzquierda(
      const AExpresion: string;
      ALongitud: Integer;
      const ARelleno: string): string;
    function ExpresionAgregacionTexto(
      const AExpresion, ASeparador, AOrdenPor: string;
      ADistinct: Boolean): string;
    function ExpresionIgualdadNulaSegura(
      const AIzquierda, ADerecha: string): string;
    function ExpresionEntero64(
      const AExpresion: string): string;
  end;

  IDialectoSql = interface(IDialectoExpresionesSql)
    ['{7C548065-A0A7-49D4-B717-EC30DB1816D1}']
    function GetMotor: TMotorBBDD;
    function DelimitarIdentificador(
      const AIdentificador: string): string;
    function DelimitarNombreCompuesto(
      const ANombre: string): string;
    function AplicarLimiteOrdenado(
      const ASql, AOrdenPor: string;
      ACantidad: Integer;
      ADesplazamiento: Integer = 0): string;
    function SentenciaLlamarProcedimiento(
      const ANombre, AParametros: string): string;
    function TablaConBloqueoActualizacion(
      const ATabla: string): string;
    function ClausulaBloqueoActualizacion: string;
    function ComandosInicializacionSesion:
      TComandosInicializacionSesionSql;
    property Motor: TMotorBBDD read GetMotor;
  end;

implementation

end.
