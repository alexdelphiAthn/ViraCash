{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAlbaranesVentaPresentacionArticulo                      }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Resuelve con valores la entrada de artículo de un albarán de venta.       }
{******************************************************************************}
unit inLibAlbaranesVentaPresentacionArticulo;

interface

uses
  Data.DB,
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf;

type
  TEstadoArticuloAlbaranVenta = (
    eaavSinEntrada,
    eaavRechazado,
    eaavPreparado);
  TEntradaArticuloAlbaranVenta = record
    CodigoEntrada: string;
    CodigoTarifa: string;
    Fecha: TDateTime;
  end;
  TResultadoArticuloAlbaranVenta = record
    Estado: TEstadoArticuloAlbaranVenta;
    Datos: TArticuloDatos;
    Precio: TArticuloPrecio;
    CodigoTarifa: string;
    Mensaje: string;
    function Preparado: Boolean;
  end;

procedure AplicarPrecioTarifaAlbaranVenta(ALinea: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);

function ResolverArticuloAlbaranVenta(
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  const AEntrada: TEntradaArticuloAlbaranVenta):
  TResultadoArticuloAlbaranVenta;

implementation

uses
  System.SysUtils;

procedure AplicarPrecioTarifaAlbaranVenta(ALinea: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
var
  Salida, Final, Descuento, Porcentaje: Double;
  CampoMaestro, CampoComplementario: string;
begin
  CampoMaestro := 'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN';
  CampoComplementario := 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN';
  if AResultado.Precio.EsImpIncl then
  begin
    ALinea.FieldByName('ESIMP_INCL_TARIFA_ALBLIN').AsString := 'S';
    CampoMaestro := 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN';
    CampoComplementario := 'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN';
  end
  else
    ALinea.FieldByName('ESIMP_INCL_TARIFA_ALBLIN').AsString := 'N';
  Salida := 0;
  Final := 0;
  Descuento := 0;
  Porcentaje := 0;
  if not AResultado.Datos.RequiereSku then
  begin
    Salida := AResultado.Precio.PrecioSalida;
    Final := AResultado.Precio.PrecioFinal;
    Descuento := AResultado.Precio.PrecioDto;
    Porcentaje := AResultado.Precio.PorcentajeDto;
  end;
  // Las notificaciones del dataset pueden recalcular el neto. Terminar
  // por el precio maestro conserva exactamente el importe de la tarifa.
  ALinea.FieldByName('PRECIO_SALIDA_ALBLIN').AsFloat := Salida;
  ALinea.FieldByName('PORCENTAJE_DTO_ALBLIN').AsFloat := Porcentaje;
  ALinea.FieldByName('PRECIO_DTO_ALBLIN').AsFloat := Descuento;
  ALinea.FieldByName(CampoComplementario).AsFloat := 0;
  ALinea.FieldByName(CampoMaestro).AsFloat := Final;
end;

function TResultadoArticuloAlbaranVenta.Preparado: Boolean;
begin
  Result := Estado = eaavPreparado;
end;

function ResolverArticuloAlbaranVenta(
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  const AEntrada: TEntradaArticuloAlbaranVenta):
  TResultadoArticuloAlbaranVenta;
var
  Resolucion: TArtResolucionEntrada;
begin
  Result := Default(TResultadoArticuloAlbaranVenta);
  Result.Estado := eaavSinEntrada;
  Result.CodigoTarifa := AEntrada.CodigoTarifa;
  if AValidador = nil then
    raise EArgumentNilException.Create('AValidador');
  if AResolver = nil then
    raise EArgumentNilException.Create('AResolver');
  if Trim(AEntrada.CodigoEntrada) <> '' then
  begin
    Resolucion := AValidador.Resolver(AEntrada.CodigoEntrada);
    if not Resolucion.Encontrado then
    begin
      Result.Estado := eaavRechazado;
      Result.Mensaje := Resolucion.Mensaje;
    end
    else
    begin
      Result.Datos := AResolver.ResolverDatos(
        Resolucion.CodigoArticulo,
        Resolucion.CodigoSku,
        AEntrada.CodigoTarifa,
        AEntrada.Fecha);
      if not Result.Datos.Encontrado then
      begin
        Result.Estado := eaavRechazado;
        Result.Mensaje := Result.Datos.Mensaje;
      end
      else
      begin
        if Result.Datos.RequiereSku then
          Result.Precio := AResolver.ResolverPrecio(
            Result.Datos.CodigoArticulo,
            '',
            AEntrada.CodigoTarifa,
            AEntrada.Fecha)
        else
          Result.Precio := Result.Datos.PrecioPedido;
        Result.Estado := eaavPreparado;
      end;
    end;
  end;
end;

end.
