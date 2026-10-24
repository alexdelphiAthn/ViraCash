{******************************************************************************}
{                                                                              }
{  Modulo:       inLibBusquedaDatosPersistenciaIntf                           }
{    Tipo:       Contrato de persistencia                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       ViraCash                                                      }
{                                                                              }
{  Descripcion:                                                                }
{    Puerto de datos de la busqueda avanzada de articulos y SKU.               }
{******************************************************************************}
unit inLibBusquedaDatosPersistenciaIntf;

interface

uses
  Data.DB, inLibFamiliasArbol;

const
  CAMPO_TODOS = 0;
  CAMPO_ARTICULO = 1;
  CAMPO_SKU = 2;
  CAMPO_DESCRIPCION = 3;
  CAMPO_TALLA = 4;
  CAMPO_COLOR = 5;
  CAMPO_CODIGO_BARRAS = 6;
  CAMPO_FAMILIA = 7;
  CAMPO_PROVEEDOR = 8;
  CAMPO_REF_PROVEEDOR = 9;
  CAMPO_TEMPORADA = 10;
  CAMPO_ALMACEN = 11;
  CAMPO_PROPIEDADES = 12;
  CAMPO_COLOR_BASICO = 13;
  CAMPO_PROXIMIDAD_COLOR = 14;

type
  TOpcionBusquedaDatos = record
    Codigo: string;
    Nombre: string;
  end;

  TOpcionesBusquedaDatos = TArray<TOpcionBusquedaDatos>;
  TCadenasBusquedaDatos = TArray<string>;

  TCriteriosBusquedaDatos = record
    Campo: Integer;
    Coincidencia: Integer;
    Estado: Integer;
    Stock: Integer;
    Limite: Integer;
    DistinguirMayusculas: Boolean;
    Valor: string;
    // Lista CSV de codigos de familia elegidos en el arbol de familias;
    // vacia = todas (misma convencion que los filtros de los informes).
    Familias: string;
    Proveedor: string;
    Temporada: string;
    Almacen: string;
    Rojo: Integer;
    Verde: Integer;
    Azul: Integer;
  end;

  IResultadoBusquedaDatos = interface
    ['{DA69D395-BC80-426C-B9DA-83D14062A053}']
    function DataSet: TDataSet;
  end;

  IRepositorioBusquedaDatos = interface
    ['{4B8BEED3-A565-4CD9-933C-DB3A218D4488}']
    // Familias activas con su padre, para pintarlas como arbol.
    function ListarFamiliasArbol: TFamiliasArbol;
    function ConsultarProveedores: IResultadoBusquedaDatos;
    function ListarTemporadas: TOpcionesBusquedaDatos;
    function ListarColoresPaleta: TCadenasBusquedaDatos;
    function BuscarHexColor(
      const AValor: string): string;
    function PrepararBusqueda(
      const ACriterios: TCriteriosBusquedaDatos
    ): IResultadoBusquedaDatos;
  end;

implementation

end.
