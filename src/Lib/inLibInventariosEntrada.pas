{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventariosEntrada                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Decisiones y escritura de la entrada de artículos y SKU en inventarios.  }
{******************************************************************************}
unit inLibInventariosEntrada;

interface

uses
  inLibTrazabilidad;

type
  TDecisionEntradaInventario = record
    CodigoUnidad: string;
    CargarStock: Boolean;
    RellenarAtributos: Boolean;
  end;

function ResolverEntradaInventario(
  const ACodigoArticulo, ACodigoSku: string;
  ANumeroAtributos: Integer): TDecisionEntradaInventario;

// FZ-ISSUE-341: lote de la línea a partir de la propia lectura (IMEI o
// código por unidad, GS1 con IA 10 / 21). Vacío si el modo efectivo del
// artículo no lleva lote; en SERIE manda la serie, si no, el lote.
function LoteLecturaInventario(
  AModoEfectivo: TModoTrazabilidad;
  const ALote, ASerie: string): string;
implementation

function ResolverEntradaInventario(
  const ACodigoArticulo, ACodigoSku: string;
  ANumeroAtributos: Integer): TDecisionEntradaInventario;
begin
  Result.CodigoUnidad := ACodigoArticulo;
  Result.CargarStock := ANumeroAtributos = 0;
  Result.RellenarAtributos := False;
  if ACodigoSku <> '' then
  begin
    Result.CodigoUnidad := ACodigoSku;
    Result.CargarStock := True;
    Result.RellenarAtributos := True;
  end;
end;

function LoteLecturaInventario(
  AModoEfectivo: TModoTrazabilidad;
  const ALote, ASerie: string): string;
begin
  Result := '';
  if RequiereLote(AModoEfectivo) then
  begin
    if AModoEfectivo = mtSerie then
      Result := NormalizarLote(ASerie);
    if Result = '' then
      Result := NormalizarLote(ALote);
  end;
end;

end.
