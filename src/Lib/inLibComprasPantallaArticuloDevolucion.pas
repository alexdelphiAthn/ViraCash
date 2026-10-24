{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasPantallaArticuloDevolucion                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Resuelve un artículo de devolución sin conocer formularios ni datasets.  }
{******************************************************************************}
unit inLibComprasPantallaArticuloDevolucion;

interface

uses
  inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf,
  inLibComprasPantallaIntf,
  inLibDevolucionesCompraPersistenciaIntf;

function CrearAplicacionArticuloDevolucionCompra(
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  const ADatos: IRepositorioDatosDevolucionCompra):
  IAplicacionArticuloDevolucionCompra;

implementation

uses
  System.SysUtils, inLibMsgArticulos;

type
  TAplicacionArticuloDevolucionCompra = class(
    TInterfacedObject,
    IAplicacionArticuloDevolucionCompra)
  private
    FValidador: IArticulosValidador;
    FResolver: IArticulosResolver;
    FDatos: IRepositorioDatosDevolucionCompra;
    FUltimaClaveAvisoProveedor: string;
    function AvisoProveedorDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): string;
    function ResolverEntrada(
      const ACodigo: string): TArtResolucionEntrada;
    function CargarDatos(
      const AEntrada: TEntradaArticuloDevolucionCompra;
      const AResolucion: TArtResolucionEntrada): TArticuloDatos;
    function CrearLinea(
      const AEntrada: TEntradaArticuloDevolucionCompra;
      const ADatosArticulo: TArticuloDatos;
      AIdConjuntoPivote: Integer): TLineaArticuloDevolucionCompra;
  public
    constructor Create(
      const AValidador: IArticulosValidador;
      const AResolver: IArticulosResolver;
      const ADatos: IRepositorioDatosDevolucionCompra);
    function Ejecutar(
      const AEntrada: TEntradaArticuloDevolucionCompra):
      TResultadoArticuloDevolucionCompra;
  end;

function CrearAplicacionArticuloDevolucionCompra(
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  const ADatos: IRepositorioDatosDevolucionCompra):
  IAplicacionArticuloDevolucionCompra;
begin
  Result := TAplicacionArticuloDevolucionCompra.Create(
    AValidador,
    AResolver,
    ADatos);
end;

constructor TAplicacionArticuloDevolucionCompra.Create(
  const AValidador: IArticulosValidador;
  const AResolver: IArticulosResolver;
  const ADatos: IRepositorioDatosDevolucionCompra);
begin
  if AValidador = nil then
    raise EArgumentNilException.Create('AValidador');
  if AResolver = nil then
    raise EArgumentNilException.Create('AResolver');
  if ADatos = nil then
    raise EArgumentNilException.Create('ADatos');
  inherited Create;
  FValidador := AValidador;
  FResolver := AResolver;
  FDatos := ADatos;
end;

function TAplicacionArticuloDevolucionCompra.AvisoProveedorDistinto(
  const ACodigoArticulo, ACodigoProveedor: string): string;
var
  oProveedorDocumento: TArticuloCoste;
  oProveedorOrigen: TArticuloCoste;
  sClave: string;
begin
  Result := '';
  if (Trim(ACodigoArticulo) <> '') and
     (Trim(ACodigoProveedor) <> '') and
     (Trim(ACodigoProveedor) <> '0') then
  begin
    oProveedorDocumento := FResolver.ResolverUltimoCoste(
      ACodigoArticulo, ACodigoProveedor, '');
    if not oProveedorDocumento.Encontrado then
    begin
      oProveedorOrigen := FResolver.ResolverUltimoCoste(
        ACodigoArticulo, '', '');
      if oProveedorOrigen.Encontrado and
         (Trim(oProveedorOrigen.CodigoProveedor) <> '') and
         not SameText(oProveedorOrigen.CodigoProveedor,
           ACodigoProveedor) then
      begin
        sClave := UpperCase(Trim(ACodigoArticulo)) + '|' +
          UpperCase(Trim(ACodigoProveedor));
        if sClave <> FUltimaClaveAvisoProveedor then
        begin
          FUltimaClaveAvisoProveedor := sClave;
          Result := SAvisoArticuloCreadoOtroProveedor;
        end;
      end;
    end;
  end;
end;

function TAplicacionArticuloDevolucionCompra.ResolverEntrada(
  const ACodigo: string): TArtResolucionEntrada;
begin
  Result := Default(TArtResolucionEntrada);
  if FDatos.EsCodigoArticuloExacto(ACodigo) then
  begin
    Result.Encontrado := True;
    Result.CodigoArticulo := ACodigo;
    Result.CodigoSku := '';
  end
  else
    Result := FValidador.Resolver(ACodigo);
  if (not Result.Encontrado) and (Result.Mensaje = '') then
    Result.Mensaje := Format(
      'No se encontró el artículo "%s".',
      [ACodigo]);
end;

function TAplicacionArticuloDevolucionCompra.CargarDatos(
  const AEntrada: TEntradaArticuloDevolucionCompra;
  const AResolucion: TArtResolucionEntrada): TArticuloDatos;
begin
  Result := FResolver.ResolverDatos(
    AResolucion.CodigoArticulo,
    AResolucion.CodigoSku,
    '',
    AEntrada.Fecha,
    AEntrada.CodigoAlmacen,
    AEntrada.CodigoProveedor);
  if Result.Encontrado and Result.RequiereSku then
    Result.UltimoCoste := FResolver.ResolverUltimoCoste(
      Result.CodigoArticulo,
      AEntrada.CodigoProveedor,
      '');
end;

function TAplicacionArticuloDevolucionCompra.CrearLinea(
  const AEntrada: TEntradaArticuloDevolucionCompra;
  const ADatosArticulo: TArticuloDatos;
  AIdConjuntoPivote: Integer): TLineaArticuloDevolucionCompra;
begin
  Result := Default(TLineaArticuloDevolucionCompra);
  Result.CodigoArticulo := ADatosArticulo.CodigoArticulo;
  Result.CodigoSku := ADatosArticulo.CodigoSku;
  Result.ReferenciaProveedor := FDatos.ModeloProveedorArticulo(
    ADatosArticulo.CodigoArticulo,
    AEntrada.CodigoProveedor);
  if Result.ReferenciaProveedor = '' then
    Result.ReferenciaProveedor := ADatosArticulo.UltimoCoste.RefProveedor;
  Result.CodigoFamilia := ADatosArticulo.CodigoFamilia;
  Result.DescripcionArticulo := ADatosArticulo.DescripcionArticulo;
  Result.TipoCantidad := ADatosArticulo.TipoCantidad;
  Result.TipoIva := ADatosArticulo.TipoIVA;
  Result.CodigoAlmacen := AEntrada.CodigoAlmacen;
  Result.AsignarAlmacen := AEntrada.CodigoAlmacen <> '';
  Result.IdConjuntoPivote := AIdConjuntoPivote;
  Result.Cantidad := AEntrada.CantidadActual;
  if ADatosArticulo.RequiereSku and (AIdConjuntoPivote > 0) then
  begin
    Result.Cantidad := 0;
    Result.TotalUnidades := 0;
    Result.AsignarCantidad := True;
    Result.AsignarTotalUnidades := True;
  end
  else
  begin
    if Result.Cantidad = 0 then
    begin
      Result.Cantidad := 1;
      Result.AsignarCantidad := True;
    end;
    if ADatosArticulo.CodigoSku <> '' then
    begin
      Result.TotalUnidades := Result.Cantidad;
      Result.AsignarTotalUnidades := True;
    end;
  end;
  Result.PrecioCompra := ADatosArticulo.UltimoCoste.PrecioUltCompra;
  Result.Total := Result.Cantidad * Result.PrecioCompra;
end;

function TAplicacionArticuloDevolucionCompra.Ejecutar(
  const AEntrada: TEntradaArticuloDevolucionCompra):
  TResultadoArticuloDevolucionCompra;
var
  oDatosArticulo: TArticuloDatos;
  oResolucion: TArtResolucionEntrada;
  sCodigo: string;
  iIdConjuntoPivote: Integer;
begin
  Result := Default(TResultadoArticuloDevolucionCompra);
  sCodigo := Trim(AEntrada.CodigoIntroducido);
  if sCodigo <> '' then
  begin
    if (Trim(AEntrada.CodigoProveedor) = '') or
       (Trim(AEntrada.CodigoProveedor) = '0') then
      Result.Mensaje := SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion
    else
    begin
      oResolucion := ResolverEntrada(sCodigo);
      if oResolucion.Encontrado then
      begin
        oDatosArticulo := CargarDatos(AEntrada, oResolucion);
        if oDatosArticulo.Encontrado then
        begin
          iIdConjuntoPivote := FDatos.ResolverConjuntoPivotArticulo(
            oDatosArticulo.CodigoArticulo);
          Result.Linea := CrearLinea(
            AEntrada,
            oDatosArticulo,
            iIdConjuntoPivote);
          Result.Aplicado := True;
          Result.RequiereSku := oDatosArticulo.RequiereSku and
            (oDatosArticulo.CodigoSku = '');
          Result.PrepararColor := oDatosArticulo.RequiereSku and
            (iIdConjuntoPivote > 0);
          Result.Mensaje := AvisoProveedorDistinto(
            oDatosArticulo.CodigoArticulo,
            AEntrada.CodigoProveedor);
        end
        else
          Result.Mensaje := oDatosArticulo.Mensaje;
      end
      else
        Result.Mensaje := oResolucion.Mensaje;
    end;
  end;
end;

end.
