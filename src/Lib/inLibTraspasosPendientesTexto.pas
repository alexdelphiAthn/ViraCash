{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTraspasosPendientesTexto                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       05/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Detalle de lo pendiente de traspasar / de recibir (vi_traspasos_pendientes}
{    del script 766) para la consulta de stock y la ficha del articulo:        }
{    solicitudes, propuestas y cargas en transito, y el resumen del almacen    }
{    (FZ-ISSUE-251). Sin acceso a datos.                                       }
{******************************************************************************}
unit inLibTraspasosPendientesTexto;

interface

const
  // Columnas de PRC_GET_CAJA_STOCK_PIVOTADO_WITHZ (script 770) en la
  // pestana Stock de la ficha del articulo.
  CAMPO_STOCK_PTE_TRASPASAR = 'Pte. traspasar';
  CAMPO_STOCK_PTE_RECIBIR_TRASPASO = 'Pte. recibir trasp.';
  CAMPO_STOCK_DISPONIBLE = 'Disponible';
  CAMPO_STOCK_CODIGO_ALMACEN = 'CODIGO_ALM_STOCK';

type
  TTraspasoPendiente = record
    Tipo: string;          // SOLICITUD, PROPUESTA o TRANSITO
    Documento: string;
    Origen: string;
    Destino: string;
    Sku: string;
    Cantidad: Double;
  end;
  TTraspasosPendientes = TArray<TTraspasoPendiente>;

// Lo que el almacen tiene que sacar (origen) y lo que le tiene que llegar
// (destino) en la lista.
procedure TotalesTraspasosPendientesAlmacen(
  const ALista: TTraspasosPendientes; const AAlmacen: string;
  out APorSalir, APorLlegar: Double);

function NombreTipoTraspasoPendiente(const ATipo: string): string;

function EsColumnaPendienteTraspasoStock(const ACampo: string): Boolean;
function RotuloColumnaStock(const ACampo, AOriginal: string): string;

// Texto del detalle: una linea por documento y SKU y, si se indica el
// almacen, su resumen. AAmbito describe lo consultado (articulo, SKU...).
function TextoTraspasosPendientes(const ALista: TTraspasosPendientes;
  const AAmbito, AAlmacen: string): string;

implementation

uses
  System.SysUtils, inLibMsgArticulos;

procedure TotalesTraspasosPendientesAlmacen(
  const ALista: TTraspasosPendientes; const AAlmacen: string;
  out APorSalir, APorLlegar: Double);
var
  i: Integer;
begin
  APorSalir := 0;
  APorLlegar := 0;
  for i := 0 to High(ALista) do
  begin
    if SameText(ALista[i].Origen, AAlmacen) then
      APorSalir := APorSalir + ALista[i].Cantidad;
    if SameText(ALista[i].Destino, AAlmacen) then
      APorLlegar := APorLlegar + ALista[i].Cantidad;
  end;
end;

function NombreTipoTraspasoPendiente(const ATipo: string): string;
begin
  if SameText(ATipo, 'SOLICITUD') then
    Result := STipoTraspasoPendienteSolicitud
  else if SameText(ATipo, 'PROPUESTA') then
    Result := STipoTraspasoPendientePropuesta
  else if SameText(ATipo, 'TRANSITO') then
    Result := STipoTraspasoPendienteTransito
  else
    Result := ATipo;
end;

function EsColumnaPendienteTraspasoStock(const ACampo: string): Boolean;
begin
  Result := SameText(ACampo, CAMPO_STOCK_PTE_TRASPASAR) or
    SameText(ACampo, CAMPO_STOCK_PTE_RECIBIR_TRASPASO) or
    SameText(ACampo, CAMPO_STOCK_DISPONIBLE);
end;

function RotuloColumnaStock(const ACampo, AOriginal: string): string;
begin
  Result := AOriginal;
  if SameText(ACampo, 'Almacen') then Result := SCaptionColAlmacen
  else if SameText(ACampo, 'Total') then Result := SCaptionColTotal
  else if SameText(ACampo, CAMPO_STOCK_PTE_TRASPASAR) then
    Result := SCaptionStockPendienteTraspasar
  else if SameText(ACampo, CAMPO_STOCK_PTE_RECIBIR_TRASPASO) then
    Result := SCaptionStockPendienteRecibirTraspaso
  else if SameText(ACampo, CAMPO_STOCK_DISPONIBLE) then
    Result := SCaptionStockDisponible;
end;

function TextoTraspasosPendientes(const ALista: TTraspasosPendientes;
  const AAmbito, AAlmacen: string): string;
var
  i: Integer;
  oTexto: TStringBuilder;
  rPorSalir, rPorLlegar: Double;
begin
  if Length(ALista) = 0 then
    Exit(Format(SSinTraspasosPendientesStock, [AAmbito]));
  oTexto := TStringBuilder.Create;
  try
    oTexto.AppendLine(Format(SCabeceraTraspasosPendientesStock, [AAmbito]));
    oTexto.AppendLine;
    for i := 0 to High(ALista) do
      oTexto.AppendLine(Format(SLineaTraspasoPendienteStock,
        [NombreTipoTraspasoPendiente(ALista[i].Tipo), ALista[i].Documento,
         ALista[i].Origen, ALista[i].Destino, ALista[i].Sku,
         FormatFloat('#,##0.###', ALista[i].Cantidad)]));
    if AAlmacen <> '' then
    begin
      TotalesTraspasosPendientesAlmacen(ALista, AAlmacen, rPorSalir,
        rPorLlegar);
      oTexto.AppendLine;
      oTexto.Append(Format(SResumenTraspasosPendientesAlmacen,
        [AAlmacen, FormatFloat('#,##0.###', rPorSalir),
         FormatFloat('#,##0.###', rPorLlegar)]));
    end;
    Result := TrimRight(oTexto.ToString);
  finally
    oTexto.Free;
  end;
end;

end.
