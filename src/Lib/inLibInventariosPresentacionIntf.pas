{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventariosPresentacionIntf                              }
{    Tipo:       Contrato                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Contratos puros de la presentacion de columnas de inventario. No          }
{    conoce VCL, datasets ni UniDAC: solo describe que debe pintarse.          }
{******************************************************************************}
unit inLibInventariosPresentacionIntf;

interface

const
  // El grid de lineas solo reserva cinco columnas de atributo.
  MAX_ATRIBUTOS_INVENTARIO = 5;

type
  // Estado de una columna de atributo (Talla, Color...) del grid.
  TColumnaAtributoInventario = record
    Caption: string;
    Visible: Boolean;
    Editable: Boolean;
  end;

  TPlanColumnasAtributosInventario =
    array[1..MAX_ATRIBUTOS_INVENTARIO] of TColumnaAtributoInventario;

  // Que debe hacer el grid cuando cambia el articulo padre enfocado.
  TAccionColumnasInventario = (
    aciNinguna,
    aciOcultarTodas,
    aciColumnasDelArticulo,
    aciColumnasDeLaVista,
    aciSoloModoEntrada);

  // Situacion observable del grid que decide la accion anterior.
  TSituacionColumnasInventario = record
    ContratoConstruido: Boolean;
    MostrarAtributos: Boolean;
    HayOrigenDeDatos: Boolean;
    LineasEnEdicion: Boolean;
    MismoArticuloPadre: Boolean;
    VistaAplicada: Boolean;
  end;

  // Puerto de consulta de la definicion de atributos de un articulo.
  // La implementacion real la aporta el data module de inventarios.
  IAtributosInventarioLookup = interface
    ['{6F0C1E4B-4B0E-4C6E-9C22-4D6C51F2A9E1}']
    function NombresAtributosArticulo(
      const ACodigoArticulo: string): TArray<string>;
  end;

implementation

end.
