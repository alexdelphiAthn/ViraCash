{******************************************************************************}
{  Módulo:       inLibMovimientosArticuloNavegacion                            }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Destinos de navegación de un movimiento de artículo.           }
{******************************************************************************}
unit inLibMovimientosArticuloNavegacion;

interface

type
  TReferenciaDocumentoMovimiento = record
    Tipo, Serie, Numero: string;
    Empresa, Almacen, Caja, Operacion: string;
  end;
  TEstadoDestinoMovimiento = (edmValido, edmSinDocumento,
    edmCajaSinClave, edmNoSoportado);
  TDestinoMovimientoArticulo = record
    Estado: TEstadoDestinoMovimiento;
    Pantalla, Clave: string;
  end;

function DestinoDocumentoMovimiento(
  const AReferencia: TReferenciaDocumentoMovimiento):
  TDestinoMovimientoArticulo;

implementation

uses
  System.SysUtils;

function PantallaDocumento(const ATipo: string): string;
begin
  Result := '';
  if ATipo = 'PE' then
    Result := 'Pedidos'
  else if ATipo = 'AV' then
    Result := 'Albaranes'
  else if ATipo = 'FC' then
    Result := 'Facturas'
  else if ATipo = 'PC' then
    Result := 'PedidosCompra'
  else if (ATipo = 'AC') or (ATipo = 'AB') or (ATipo = 'AE') then
    Result := 'AlbaranesCompra'
  else if ATipo = 'FP' then
    Result := 'FacturasCompra'
  else if ATipo = 'DC' then
    Result := 'DevolucionesCompra'
  else if ATipo = 'IN' then
    Result := 'Inventarios'
  else if ATipo = 'SE' then
    Result := 'ComprasSesiones';
end;

function EsOperacionCaja(const ATipo: string): Boolean;
begin
  Result := (ATipo = 'VE') or (ATipo = 'DV') or (ATipo = 'DE') or
    (ATipo = 'TR') or (ATipo = 'TA') or (ATipo = 'AT') or
    (ATipo = 'AL') or (ATipo = 'TP');
end;

function DestinoDocumentoMovimiento(
  const AReferencia: TReferenciaDocumentoMovimiento):
  TDestinoMovimientoArticulo;
var
  sTipo: string;
begin
  Result := Default(TDestinoMovimientoArticulo);
  Result.Estado := edmSinDocumento;
  sTipo := UpperCase(Trim(AReferencia.Tipo));
  if EsOperacionCaja(sTipo) then
  begin
    Result.Estado := edmCajaSinClave;
    if (AReferencia.Empresa <> '') and (AReferencia.Almacen <> '') and
      (AReferencia.Caja <> '') and (AReferencia.Operacion <> '') then
    begin
      Result.Estado := edmValido;
      Result.Pantalla := 'CajaOperacionesHist';
      Result.Clave := AReferencia.Empresa + ',' + AReferencia.Almacen +
        ',' + AReferencia.Caja + ',' + AReferencia.Operacion;
    end;
  end
  else if sTipo <> '' then
  begin
    Result.Pantalla := PantallaDocumento(sTipo);
    if Result.Pantalla = '' then
      Result.Estado := edmNoSoportado
    else if (AReferencia.Serie <> '') and (AReferencia.Numero <> '') then
    begin
      Result.Estado := edmValido;
      Result.Clave := AReferencia.Serie + ',' + AReferencia.Numero;
      if sTipo = 'FC' then
        Result.Clave := AReferencia.Numero + ',' + AReferencia.Serie;
    end;
  end;
end;

end.
