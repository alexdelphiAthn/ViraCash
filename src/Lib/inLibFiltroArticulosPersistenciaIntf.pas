{******************************************************************************}
{                                                                              }
{  Modulo:       inLibFiltroArticulosPersistenciaIntf                         }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de consulta de temporadas y proveedores para acotar articulos.     }
{******************************************************************************}
unit inLibFiltroArticulosPersistenciaIntf;

interface

type
  TProveedorFiltroArticulos = record
    Codigo: string;
    Nombre: string;
  end;

  TProveedoresFiltroArticulos = TArray<TProveedorFiltroArticulos>;
  TTemporadasFiltroArticulos = TArray<string>;

  IRepositorioFiltroArticulos = interface
    ['{78F33E52-434E-4DE6-A8CC-9D21B8029BDA}']
    function ListarTemporadas: TTemporadasFiltroArticulos;
    function ListarProveedores: TProveedoresFiltroArticulos;
  end;

implementation

end.
