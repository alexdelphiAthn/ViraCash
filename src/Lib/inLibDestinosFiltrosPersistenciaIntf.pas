{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDestinosFiltrosPersistenciaIntf                         }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de consulta para elegir usuarios y grupos al compartir filtros.    }
{******************************************************************************}
unit inLibDestinosFiltrosPersistenciaIntf;

interface

uses
  Data.DB;

type
  IResultadoDestinosFiltros = interface
    ['{9C7D4120-4A74-4F61-8880-C125552B84FE}']
    function DataSet: TDataSet;
  end;

  IRepositorioDestinosFiltros = interface
    ['{65EE1E1E-BEA2-436A-AE28-A94260E5444E}']
    function ConsultarUsuarios(
      const AUsuarioActual: string): IResultadoDestinosFiltros;
    function ConsultarGrupos: IResultadoDestinosFiltros;
  end;

implementation

end.
