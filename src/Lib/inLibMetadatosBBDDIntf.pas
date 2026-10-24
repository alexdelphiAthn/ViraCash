{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMetadatosBBDDIntf                                        }
{    Tipo:       Contrato                                                     }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de acceso y operaciones sobre metadatos de la BBDD.              }
{******************************************************************************}
unit inLibMetadatosBBDDIntf;

interface

type
  TTipoObjetoMetadatosBBDD = (
    tombTabla,
    tombVista,
    tombProcedimiento
  );
  ILectorMetadatosBBDD = interface
    ['{FF4D868C-0062-4A36-A7DF-6DE640A8DA86}']
    procedure Refrescar(const ABaseDatos: string);
    procedure CargarObjetos(ATipo: TTipoObjetoMetadatosBBDD);
    function CargarEstructura(
      ATipo: TTipoObjetoMetadatosBBDD;
      const ANombre: string): string;
    procedure CargarContenido(const ANombre: string);
    function GenerarLlamadaProcedimiento(
      const ANombre: string): string;
    procedure CargarEstadoTabla(const ANombre: string);
    function ObtenerPlanEjecucion(
      const ASQL: string;
      AConTiemposReales: Boolean;
      ATiempoMaximoSegundos: Integer): string;
    procedure CargarDependencias(
      ATipo: TTipoObjetoMetadatosBBDD;
      const ANombre: string);
  end;

  ICatalogoMetadatosBBDD = interface(ILectorMetadatosBBDD)
    ['{FC7B838D-A10A-4772-B0D6-C70BD1F4B12B}']
    procedure RegenerarTablas(const ATablas: TArray<string>);
    procedure RegenerarIndices(const ATablas: TArray<string>);
    procedure RegenerarVistas(const AVistas: TArray<string>);
    procedure RegenerarProcedimientos(
      const AProcedimientos: TArray<string>);
    procedure AnalizarTablas(const ATablas: TArray<string>);
    procedure ComprobarObjetos(const AObjetos: TArray<string>);
    procedure CalcularChecksum(const ATablas: TArray<string>);
    procedure VaciarTablas(const ATablas: TArray<string>);
    procedure BorrarTablas(const ATablas: TArray<string>);
    procedure EjecutarConsulta(const ASQL: string);
  end;

implementation

end.
