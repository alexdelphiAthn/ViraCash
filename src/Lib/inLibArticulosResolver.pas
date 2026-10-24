{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArticulosResolver                                        }
{    Tipo:       Fachada                                                       }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada temporal del contrato de resolución de artículos.                 }
{******************************************************************************}
unit inLibArticulosResolver;

interface

uses
  inLibArticulosResolverIntf;

type
  TArticuloOrigenPrecio =
    inLibArticulosResolverIntf.TArticuloOrigenPrecio;
  TArticuloPrecio =
    inLibArticulosResolverIntf.TArticuloPrecio;
  TArticuloCoste =
    inLibArticulosResolverIntf.TArticuloCoste;
  TArticuloPMP =
    inLibArticulosResolverIntf.TArticuloPMP;
  TArticuloSkuItem =
    inLibArticulosResolverIntf.TArticuloSkuItem;
  TArticuloDatos =
    inLibArticulosResolverIntf.TArticuloDatos;
  IArticulosResolver =
    inLibArticulosResolverIntf.IArticulosResolver;

function DescuentoEnVentana(
  const AFecha, ADesde, AHasta: TDateTime): Boolean;

implementation

function DescuentoEnVentana(
  const AFecha, ADesde, AHasta: TDateTime): Boolean;
begin
  Result := inLibArticulosResolverIntf.DescuentoEnVentana(
    AFecha,
    ADesde,
    AHasta);
end;

end.
