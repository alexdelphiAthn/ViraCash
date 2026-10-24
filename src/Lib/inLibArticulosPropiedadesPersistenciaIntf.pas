{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosPropiedadesPersistenciaIntf                    }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puertos de persistencia para las propiedades de artículos.               }
{******************************************************************************}
unit inLibArticulosPropiedadesPersistenciaIntf;

interface

type
  TDefinicionPropiedadArticulo = record
    Codigo: string;
    Nombre: string;
    TipoValor: string;
    Nivel: string;
    EsRequerido: Boolean;
    IdValor: Integer;
    ValorLibre: string;
  end;
  TOpcionPropiedadArticulo = record
    IdValor: Integer;
    Valor: string;
  end;
  TUnidadPropiedadArticulo = record
    Codigo: string;
    Nombre: string;
  end;
  TValorUnidadPropiedadArticulo = record
    CodigoUnidad: string;
    IdValor: Integer;
    ValorLibre: string;
  end;
  ILectorPropiedadesArticulo = interface
    ['{96397B4B-E2F0-416E-8927-C407C3DD83A3}']
    function ListarDisponibles: TArray<TDefinicionPropiedadArticulo>;
    function ListarAsignadas(
      const ACodigoArticulo: string
    ): TArray<TDefinicionPropiedadArticulo>;
    function ListarFamilia(
      const ACodigoFamilia: string
    ): TArray<TDefinicionPropiedadArticulo>;
    function Buscar(
      const ACodigoPropiedad: string;
      out APropiedad: TDefinicionPropiedadArticulo): Boolean;
    function ListarOpciones(
      const ACodigoPropiedad: string
    ): TArray<TOpcionPropiedadArticulo>;
    function ListarUnidades(
      const ACodigoArticulo, ANivel: string
    ): TArray<TUnidadPropiedadArticulo>;
    function ListarValoresUnidades(
      const ACodigoArticulo, ACodigoPropiedad: string
    ): TArray<TValorUnidadPropiedadArticulo>;
  end;
  IEscritorPropiedadesArticulo = interface
    ['{D49E529A-F50C-4DC1-9F7B-29E4C1640894}']
    procedure GuardarValor(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad: string;
      AIdValor: Integer;
      const AValorLibre, AUsuario: string);
    procedure EliminarPropiedad(
      const ACodigoArticulo, ACodigoPropiedad,
      AUsuario: string);
    procedure EliminarValorUnidad(
      const ACodigoArticulo, ACodigoPropiedad, ACodigoUnidad,
      AUsuario: string);
  end;
  TServiciosPropiedadesArticulo = record
    Lectura: ILectorPropiedadesArticulo;
    Escritura: IEscritorPropiedadesArticulo;
  end;

implementation

end.
