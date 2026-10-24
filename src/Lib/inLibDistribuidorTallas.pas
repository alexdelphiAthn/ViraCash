{******************************************************************************}
{                                                                              }
{  Módulo:       inLibDistribuidorTallas                                       }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contrato visual del distribuidor de tallas. La implementación se recibe  }
{    desde la raíz de composición.                                             }
{******************************************************************************}
unit inLibDistribuidorTallas;

interface

uses
  Uni;

type
  TParametrosDistribuidorTallas = record
    Conexion: TUniConnection;
    Usuario: string;
    TablaCeldas: string;
    CampoSerie: string;
    CampoNumero: string;
    CampoLinea: string;
    CampoFila: string;
    CampoAlmacen: string;
    CampoAtributoValor: string;
    CampoCantidad: string;
    Serie: string;
    Numero: string;
    Linea: Integer;
    IdConjuntoPivot: Integer;
    CodigoArticulo: string;
  end;
  IDistribuidorTallasVisual = interface
    ['{C3D26E71-0DA6-4E08-B9D3-F001911E7F20}']
    function Ejecutar(
      const AParametros: TParametrosDistribuidorTallas): Boolean;
  end;
  IProveedorDistribuidorTallasVisual = interface
    ['{5D9579B4-9E65-4CA6-9C40-92792E03F50E}']
    function GetDistribuidorTallasVisual: IDistribuidorTallasVisual;
    property DistribuidorTallasVisual: IDistribuidorTallasVisual
      read GetDistribuidorTallasVisual;
  end;

implementation

end.
