{******************************************************************************}
{                                                                              }
{  Modulo:       inLibGuiasPersistenciaIntf                                   }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos del constructor visual de guias de informes y grids.      }
{******************************************************************************}
unit inLibGuiasPersistenciaIntf;

interface

uses
  Data.DB;

type
  INavegadorGuias = interface
    ['{F19FB8CE-A245-4DAB-AB96-6BD5749F3491}']
    function DataSet: TDataSet;
  end;

  TNombresEsquemaGuias = TArray<string>;

  IRepositorioGuias = interface
    ['{D7832734-5148-49FC-A574-26E76754B390}']
    function ConsultarGuias(
      const AInforme: string): INavegadorGuias;
    function ListarTablas: TNombresEsquemaGuias;
    function ListarCamposTabla(
      const ATabla: string): TNombresEsquemaGuias;
  end;

implementation

end.
