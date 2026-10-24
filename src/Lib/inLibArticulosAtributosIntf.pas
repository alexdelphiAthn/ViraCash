{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosAtributosIntf                                  }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato de lectura de atributos y propiedades de artículos.              }
{******************************************************************************}
unit inLibArticulosAtributosIntf;

interface

type
  TTipoValorPropiedad = (
    tvpLista,
    tvpTextoLibre,
    tvpNumero,
    tvpBooleano
  );

  TArticuloAtributoValor = record
    IdValor: Integer;
    Valor: string;
    Descripcion: string;
    Orden: Integer;
    EsActivo: Boolean;
  end;

  TArticuloAtributo = record
    IdAtributo: string;
    NombreAtributo: string;
    OrdenAtributo: Integer;
    IdConjunto: Integer;
    NombreConjunto: string;
    Valores: TArray<TArticuloAtributoValor>;
  end;

  TArticuloPropiedad = record
    Codigo: string;
    Nombre: string;
    TipoValor: TTipoValorPropiedad;
    EsRequerido: Boolean;
    Orden: Integer;
    IdValorAsignado: Integer;
    ValorLibreAsignado: string;
    Valores: TArray<TArticuloAtributoValor>;
  end;

  IArticulosAtributosLookup = interface
    ['{C3CE163A-D2D5-4670-9E42-EE40A4432511}']
    function ObtenerAtributos(
      const ACodigoArticulo: string):
      TArray<TArticuloAtributo>;
    function ObtenerPropiedades(
      const ACodigoArticulo: string):
      TArray<TArticuloPropiedad>;
    function ObtenerAtributosDeSku(
      const ACodigoSku: string):
      TArray<TArticuloAtributoValor>;
    function ObtenerAvsEnSkus(
      const ACodigoArticulo: string;
      AOrdenAtributo: Integer):
      TArray<TArticuloAtributoValor>;
  end;

implementation

end.
