{******************************************************************************}
{                                                                              }
{  Modulo:       inLibSeleccionFamiliaPersistenciaIntf                       }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos del selector jerarquico de familias.                      }
{******************************************************************************}
unit inLibSeleccionFamiliaPersistenciaIntf;

interface

uses
  Data.DB;

type
  IConsultaSeleccionFamilia = interface
    ['{49BAEA6F-608B-4CC7-A2E9-A7241404C7B3}']
    function DataSet: TDataSet;
    procedure AplicarFiltro(const AFiltro: string);
  end;

  IRepositorioSeleccionFamilia = interface
    ['{2BB58AB3-6136-4734-B433-C41D430C7EEF}']
    function CrearConsulta: IConsultaSeleccionFamilia;
  end;

implementation

end.
