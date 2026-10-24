{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventarioNubePersistenciaIntf                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contratos de persistencia del intercambio de inventarios con la nube.     }
{******************************************************************************}
unit inLibInventarioNubePersistenciaIntf;

interface

type
  TClaveInventarioNube = record
    Empresa: string;
    Almacen: string;
    Serie: string;
    Numero: string;
  end;
  TLineaInventarioNube = record
    CodigoArticulo: string;
    CodigoUnidad: string;
    Descripcion: string;
    CodigoBarras: string;
    CantidadTeorica: Double;
    EsTrazable: string;
  end;
  TEventoInventarioNube = record
    Uuid: string;
    CodigoArticulo: string;
    CodigoUnidad: string;
    CodigoBarras: string;
    Cantidad: Double;
    Lote: string;
    FechaCaducidad: string;
    InstanteRecuento: string;
    InstanteRecuentoUtc: string;
    Operario: string;
    Dispositivo: string;
    Zona: string;
  end;
  TLineasInventarioNube = TArray<TLineaInventarioNube>;
  IInventarioNubePersistencia = interface
    ['{EC318289-5F6B-4057-8BB1-AA70AAFE4CD0}']
    function ListarLineas(
      const AClave: TClaveInventarioNube): TLineasInventarioNube;
    function GuardarEventoSiNuevo(
      const AClave: TClaveInventarioNube;
      const AEvento: TEventoInventarioNube;
      const AUsuario: string): Boolean;
  end;

implementation

end.
