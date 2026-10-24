{******************************************************************************}
{                                                                              }
{  Modulo:       inLibStockConsultaEntradaIntf                                 }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Puertos puros de entrada por texto o codigo de barras en stock.           }
{******************************************************************************}
unit inLibStockConsultaEntradaIntf;

interface

type
  TCoincidenciaEntradaStock = record
    CodigoArticulo: string;
    CodigoSku: string;
    Descripcion: string;
    Proveedor: string;
    ReferenciaProveedor: string;
  end;
  TCoincidenciasEntradaStock = TArray<TCoincidenciaEntradaStock>;

  IRepositorioEntradaStock = interface
    ['{AF92955B-24A0-4DE4-81F6-1ADBE5C7E63B}']
    function ResolverTexto(
      const AEntrada: string): TCoincidenciasEntradaStock;
  end;

  IVistaEntradaStock = interface
    ['{F9D42E58-D01D-497C-924C-A9F9C94D0B15}']
    procedure AplicarArticulo(
      const ACodigoArticulo, ACodigoSku: string);
    procedure MostrarCoincidencias(
      const ACoincidencias: TCoincidenciasEntradaStock;
      const AEntrada: string);
    procedure MostrarTextoNoEncontrado(const AEntrada: string);
    procedure MostrarCodigoBarrasNoEncontrado(const ACodigo: string);
  end;

  IAplicacionEntradaStock = interface
    ['{8C821430-B361-4980-B42B-09972DF4C893}']
    procedure ProcesarTexto(
      const AEntrada, ACodigoArticuloActual: string;
      AMostrarError: Boolean);
    procedure ProcesarCodigoBarras(const ACodigo: string);
  end;

implementation

end.
