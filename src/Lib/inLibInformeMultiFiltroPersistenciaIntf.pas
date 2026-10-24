{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInformeMultiFiltroPersistenciaIntf                      }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de lectura de los filtros compartidos por los informes multiples. }
{******************************************************************************}
unit inLibInformeMultiFiltroPersistenciaIntf;

interface

uses
  inLibFamiliasArbol;

type
  TOrigenProveedoresInformeMultiFiltro = (
    opmfArticulos,
    opmfEfectosPago,
    opmfDocumentosProveedor);

  TOpcionInformeMultiFiltro = record
    Codigo: string;
    Nombre: string;
  end;

  TOpcionesInformeMultiFiltro = TArray<TOpcionInformeMultiFiltro>;

  // La jerarquia de familias es la misma que pinta el arbol de familias
  // de la interfaz, asi que se reutiliza su modelo.
  TFamiliaInformeMultiFiltro = TFamiliaArbol;

  TFamiliasInformeMultiFiltro = TFamiliasArbol;

  IRepositorioInformeMultiFiltro = interface
    ['{A86D1D7E-85DC-4690-952F-D89863995983}']
    function ListarAlmacenes: TOpcionesInformeMultiFiltro;
    function ListarFamilias: TFamiliasInformeMultiFiltro;
    function ListarProveedores(
      AOrigen: TOrigenProveedoresInformeMultiFiltro
    ): TOpcionesInformeMultiFiltro;
    function ListarTemporadas: TOpcionesInformeMultiFiltro;
    function ListarArticulos: TOpcionesInformeMultiFiltro;
  end;

implementation

end.
