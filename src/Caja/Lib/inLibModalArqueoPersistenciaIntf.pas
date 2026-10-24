{******************************************************************************}
{                                                                              }
{  Modulo:       inLibModalArqueoPersistenciaIntf                             }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos de los resumenes y validaciones del modal de arqueo.      }
{******************************************************************************}
unit inLibModalArqueoPersistenciaIntf;

interface

uses
  Data.DB;

type
  TSolicitudResumenModalArqueo = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;

  IResultadoModalArqueo = interface
    ['{157BDEB8-15AB-4A93-8340-EF3E3A9BDCC9}']
    function DataSet: TDataSet;
  end;

  IRepositorioModalArqueo = interface
    ['{6BC2A5EF-7523-49E5-B4D6-FA1EB1EC3759}']
    function ConsultarResumenEmpleados(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenFormasPago(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenPropiedades(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function ConsultarResumenIva(
      const ASolicitud: TSolicitudResumenModalArqueo
    ): IResultadoModalArqueo;
    function BuscarNombreVendedor(
      const ACodigo: string): string;
    function ExisteArqueoCerrado(
      const ASolicitud: TSolicitudResumenModalArqueo): Boolean;
    // Fin del último cierre de la caja que termina dentro del rango.
    // False si no hay ninguno (FZ-ISSUE-408).
    function UltimoCierreEnRango(
      const ASolicitud: TSolicitudResumenModalArqueo;
      out AFechaHasta: TDateTime): Boolean;
    // Operaciones de la caja sin cerrar entre su último cierre anterior
    // al rango y el comienzo de este. False si no queda ninguna o si la
    // caja no tiene cierres anteriores (FZ-ISSUE-446).
    function OperacionesSinCerrarAntes(
      const ASolicitud: TSolicitudResumenModalArqueo;
      out AUltimoCierre: TDateTime;
      out AOperaciones: Integer): Boolean;
  end;

implementation

end.
